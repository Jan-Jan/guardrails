#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# guardrails shared helpers — POSIX sh, sourced by the scripts in this directory.
# Scripts run from the target repo root. GR_CONFIG overrides the config path.
#
# Several helpers below call gr_die, which exits 2. A helper invoked inside a
# command substitution dies only in that subshell, so EVERY `x=$(gr_...)` call
# site must append `|| exit 2` — otherwise the caller sails past the error with
# an empty value, which is the exact false-green failure these checks exist to
# prevent.

GR_CONFIG="${GR_CONFIG:-.guardrails/config.yaml}"

# Every top-level key guardrails understands. A key outside this set is a typo,
# and a typo'd key is invisible: cfg_get returns nothing, the gate that reads it
# is skipped, and the run exits 0 having proved nothing.
# The ID prefixes with a traceability gate of their own. Others are allowed:
# DANGLING-REF, DUPLICATE-ID and draft finalization are all keyed on the
# configured prefix list, so an extra prefix (ADR, say) is genuinely checked,
# just not by a gate specific to it. What is rejected is a config where NONE
# of these appears — every traceability gate is then off and the run still
# exits 0.
GR_GATED_PREFIXES='REQ
HAZ
RC
SDD
LLR
PR'

# The keys whose value is a LIST of `  - item` lines. Every other known key is
# a scalar. Each key has exactly ONE form, and the distinction is enforced,
# because a key written in the other form is read by nobody:
#
#   strict_paths: src        — cfg_list finds no items, every traceability scan
#                              then walks no path, and a merge over an
#                              undefined-ID reference exits 0 with `strict 0`
#                              printed in the summary.
#   doc_soup:
#     - docs/soup.md         — cfg_get finds no value, gr_doc_files returns an
#                              empty file list at status 0, and the document is
#                              scanned by nobody.
#
# Neither shape breaks any other rule, and both look right: `id_prefixes: REQ
# HAZ RC` is a space-separated scalar two lines above, so `strict_paths: src` is
# the form an adopter reaches for.
GR_LIST_KEYS='strict_paths
test_paths
example_paths
verify_commands
coverage_command
depends_on
segregated_from'

# depends_on / segregated_from / expectation_age_days / expectation_open_max
# are the per-unit keys of the monorepo machinery. In a single-unit
# repository they are accepted and read by nothing that gates, because a
# config must stay valid when a repository grows a manifest.

GR_KNOWN_KEYS='guardrails_version
guardrails_commit
safety_class
id_prefixes
doc_srs
doc_rmf
doc_sad
doc_soup
doc_problems
strict_paths
test_paths
example_paths
verify_commands
coverage_command
problem_age_days
problem_open_max
depends_on
segregated_from
expectation_age_days
expectation_open_max
review_cite'

# The ID body vocabulary. An item ID is <PREFIX>-<body>, and a body is either
# a minted token or a legacy sequential number.
#
# A token is six characters of an alphabet that drops the pairs a reader
# confuses — 0/o and 1/l/i — with AT LEAST ONE DIGIT. The digit is not
# decoration: without it `REQ-<six letters>` matches ordinary hyphenated
# English, and a `PR-update` in a code comment becomes a DANGLING-REF against
# an item nobody ever wrote.
#
# The classes are ENUMERATED, not ranged. A range expression inside a bracket
# expression is undefined outside the POSIX locale, and these patterns run
# under whatever locale the caller has; enumeration also states which letters
# are missing instead of leaving `[a-hjkmnp-z]` to be worked out.
#
# Variables, not functions: they take no arguments and are pasted into
# patterns at a dozen sites. Assigned unconditionally, never `${X:-...}` — a
# value inherited from the environment could widen or narrow every ID scan in
# the toolkit while each one still exited 0, the same reasoning as
# GR_SCAN_EXCLUDE below.
GR_ID_LETTER='[abcdefghjkmnpqrstuvwxyz]'
GR_ID_DIGIT='[23456789]'
GR_ID_ANY='[abcdefghjkmnpqrstuvwxyz23456789]'

# "Exactly six, at least one digit" has no direct ERE spelling, so it is the
# union over the position of the FIRST digit: six branches, mutually exclusive
# by construction, nothing for a matcher to backtrack over. Written out rather
# than with {n} intervals — mawk shipped without interval expressions for most
# of its life, and this pattern is handed to awk as well as to git grep.
GR_ID_TOKEN="\
${GR_ID_DIGIT}${GR_ID_ANY}${GR_ID_ANY}${GR_ID_ANY}${GR_ID_ANY}${GR_ID_ANY}|\
${GR_ID_LETTER}${GR_ID_DIGIT}${GR_ID_ANY}${GR_ID_ANY}${GR_ID_ANY}${GR_ID_ANY}|\
${GR_ID_LETTER}${GR_ID_LETTER}${GR_ID_DIGIT}${GR_ID_ANY}${GR_ID_ANY}${GR_ID_ANY}|\
${GR_ID_LETTER}${GR_ID_LETTER}${GR_ID_LETTER}${GR_ID_DIGIT}${GR_ID_ANY}${GR_ID_ANY}|\
${GR_ID_LETTER}${GR_ID_LETTER}${GR_ID_LETTER}${GR_ID_LETTER}${GR_ID_DIGIT}${GR_ID_ANY}|\
${GR_ID_LETTER}${GR_ID_LETTER}${GR_ID_LETTER}${GR_ID_LETTER}${GR_ID_LETTER}${GR_ID_DIGIT}"

# Both forms, permanently. A project that predates tokens keeps its numbers —
# only new items are minted — so there is no flag day and no rewrite of an
# existing SRS. The two forms overlap (`234567` satisfies both) and nothing
# cares: nothing mints sequential IDs any more, so no reader has to decide
# which form a body is.
GR_ID_BODY="(${GR_ID_TOKEN}|[0-9][0-9][0-9]+)"

# What may NOT follow an ID: any alphanumeric. A token is exactly six
# characters, so `<PREFIX>-` followed by seven token characters is not a longer
# ID — it is not an ID at all — and a scan without this boundary reads its
# first six characters and credits the six-character ID they spell for a
# reference nobody wrote. Sequential IDs never had that problem: [0-9]{3,} is
# greedy, so a mistyped four-digit number harvested whole and showed up as the
# dangling reference it was.
#
# Deliberately wider than the body alphabet — `i`, `l`, `o` and the uppercase
# letters cannot appear in a token, but a reference containing one is still a
# typo rather than a boundary, and reading it as a boundary would credit the
# item it truncates to.
GR_ID_TAIL='[^0-9A-Za-z]'

# The annotation-list rule as an awk function, defined ONCE and prepended to
# every awk program that needs it. gr_id_run(line, kw) returns the space-
# separated IDs of the list immediately following the FIRST occurrence of kw on
# line; the run ends at the first character that is not an ID, comma or space,
# so `verifies: <ID> (was <older ID>)` yields the first ID alone — prose after the
# list is commentary, never coverage.
#
# One definition is the point. Three near-copies of this rule is how `traces:`
# came to demand a REQ at the head of its run while `satisfies:` scanned from
# the LAST occurrence on the line and credited a REQ mentioned in prose.
#
# GR_ID_BODY is interpolated once, here, when the library is sourced — this
# constant contains a copy of the body from then on rather than reading the
# variable at match time. That is only worth knowing when poisoning the
# variable from outside to test a call site: this one does not follow.
GR_AWK_ID_RUN='
function gr_id_run(line, kw,   p, rest, out, tok, nxt) {
    p = index(line, kw)
    if (p == 0) return ""
    rest = substr(line, p + length(kw))
    out = ""
    while (match(rest, /^[ \t,]*[A-Za-z]+-'"${GR_ID_BODY}"'/)) {
        tok = substr(rest, RSTART, RLENGTH)
        nxt = substr(rest, RSTART + RLENGTH, 1)
        rest = substr(rest, RSTART + RLENGTH)
        # An alphanumeric here means the body was cut short by the matcher, so
        # this is not the ID it appears to be. Skipping it — rather than
        # emitting the truncation — is what stops a mistyped `verifies:` from
        # crediting the item it happens to be a prefix of.
        #
        # The rest of the bad token is consumed with it. Leaving the stray
        # characters made the next `^`-anchored match fail, so ONE mistyped ID
        # discarded every ID after it in the list: a `verifies:` list of a
        # seven-character token followed by a valid ID credited neither, and
        # MISSING-TEST then named the correctly spelled item too, pointing the
        # reader at the wrong line.
        # `rest` advances either way, so the loop still terminates.
        if (nxt != "" && nxt !~ /'"${GR_ID_TAIL}"'/) {
            sub(/^[0-9A-Za-z]+/, "", rest)
            continue
        }
        sub(/^[ \t,]*/, "", tok)
        out = out (out == "" ? "" : " ") tok
    }
    return out
}
'

# The item-block rule as an awk fragment, defined ONCE and prepended to every
# program that needs it.
#
# An item block OPENS at a well-formed definition for the prefix the gate
# collects, and CLOSES at a markdown heading or at ANY BOLD LINE CONTAINING A
# COLON. That is the whole closing rule.
#
# It is stated as a SUBTRACTION, and that framing is the point. A rule that
# closed on every line starting `**` would end an item at an emphasised
# sentence inside its body (`**21 of 35 inverted, 14 not.**`), and everything
# after it — annotations included — would belong to no item: UNTRACED-DESIGN
# and UNSATISFIED-LLR would reject correct documents, while UNANALYZED-DERIVED
# and UNRESOLVED-PR would pass over real violations in silence. One rule, four
# gates, both failure directions.
#
# The close set is therefore every line starting `**`, MINUS the shape of an
# emphasised sentence, and nothing else. That sentence contains no colon; so
# the colon is the subtraction, and there is no other. Any narrower close
# set — definition forms, header shapes, a colon adjoining the closing
# asterisks — loses lines the wider rule closes, and each lost line leaves a
# block open on a header the reader sees. A
# line a reader takes for a header but the rule does not becomes body text, and
# its annotations are credited to the item ABOVE it: a resolved PR inherits the
# next one`s `status: open`. A wrong answer is worse than a missing one.
#
# BYTE-WISE, not a regex, and this is not stylistic. `.` in an ERE does not
# match an invalid byte sequence under gawk in a multibyte locale, so
# `^\*\*.*:` does not close on a ledger saved in latin-1 — a header like
# `**Détail**:` — under gawk in such a locale, while mawk, busybox awk and gawk
# under LC_ALL=C close it. The same tree, the same script, two verdicts, decided by the
# operator`s locale. substr and index count bytes in every awk and every
# locale, so they implement the rule the sentence above states.
#
# The residual limit, stated exactly: a bold line containing no ASCII colon does
# not close. `**Decision 7**` does not; `**Decision 7**:` does. A full-width
# colon (U+FF1A) is not an ASCII colon and does not close. Nothing
# distinguishes a colon-free bold line from an emphasised sentence such as
# `**21 of 35 inverted, 14 not.**`, so that limit is irreducible.
#
# One definition, for the same reason GR_AWK_ID_RUN and gr_def_re have one, and
# with one addition: ORPHAN-ANNOTATION is a fifth reader of this rule, and a
# backstop that disagrees with the gates it backs is not a backstop.
#
# gr_block_init takes the OPENING prefix alternation (the prefixes this gate
# collects) and GR_ID_BODY. There is no closing alternation: the close is keyed
# on no vocabulary at all, which is what makes it total. The opening pattern is
# assembled HERE, inside awk, and never handed in ready-made with -v: awk runs
# escape processing over a -v value, so a pattern containing \* arrives as a
# bare * and matches nothing at all — a gate that counts zero items and still
# exits 0. Measured on gawk 5.3.2. Both arguments contain no backslashes of
# their own, which is what lets them cross the -v boundary safely.
GR_AWK_ITEM_BLOCK='
function gr_block_init(pfx_open, body) {
    GR_BLOCK_OPEN_RE = "^\\*\\*(" pfx_open ")-" body "\\*\\*:"
}
# Does this line START a block this gate collects? The STRICT form: an item
# whose ID cannot be read is not an item, and nothing may be collected under it.
function gr_block_opens(line) { return (line ~ GR_BLOCK_OPEN_RE) }
# Does this line END whatever block is open? Any bold line containing a colon,
# and any markdown heading. See the block comment above for why this is
# substr/index rather than a regex, and why the colon is the only subtraction
# from closing on every line starting `**`.
function gr_block_closes(line) {
    if (substr(line, 1, 1) == "#") return 1
    return (substr(line, 1, 2) == "**" && index(line, ":") > 0)
}
# Leading list markers, task-list boxes and blockquote markers, stepped over.
# Used by the backstops alone —
# gr_kw_orphan_here — and by NO reader. The invariant stated at gr_kw_here
# below is what forbids a reader from calling this.
#
# Four lead forms: a bullet, `-`, `*` or `+`; an ordered marker, a run of
# digits closed by `.` or `)`; a task-list box, `[ ]` or `[x]`; and a
# blockquote marker, `>`. No reader takes a keyword after any lead
# (gr_annotation), so a lead this steps over is a line the backstop reports,
# inside a block for the ID-list keywords and outside every block for all of
# them: `- [x] satisfies: derived` on a REQ is reported, never dropped.
# Table cells, emphasis and mid-sentence mentions are not leads: no reader
# takes them and no backstop reports them.
#
# A RUN of them, not one: `- 1. status:` is a one-line nested list, and
# `- [x] status:` a task-list item. The loop terminates because every pass
# consumes at least one character.
#
# A MARKER, never bare indentation, and never a bare number. The leading [ \t]*
# admits an indented item; a line with no marker is returned unchanged,
# which is what keeps the indented item grammar in the ledger templates inert,
# and requiring the `.` or `)` is what keeps `1 status: of the bus` prose. The
# trailing [ \t]+ is required too: markdown needs whitespace after a list
# marker, so `1.status:` is not a list item and is not stepped over; a
# blockquote needs none, so `>status:` is stepped over. Inside the
# bracket expression the `-` comes first, where it is a literal and not a
# range; `*` and `+` are literal at any position in one.
function gr_kw_lead(line,   s) {
    s = line
    while (sub(/^[ \t]*(([-*+]|[0-9]+[.)]|\[[ xX]\])[ \t]+|>[ \t]*)/, "", s) > 0) { }
    return s
}
# Is KW the annotation this line contains? Column one, and only column one. THE
# READER form: every gate in this toolkit that TAKES a value tests it here.
#
# THE INVARIANT, and it is a containment and not an equality: the backstop must
# see AT LEAST what every reader sees — backstop ⊇ reader, written out as
# SUPERSET-OF so a plain-ASCII grep finds it as well. The hole
# ORPHAN-ANNOTATION was built to close is a reader taking a value from a
# position the backstop cannot see; a backstop wider than the readers closes
# that hole and opens nothing, because reporting a line no reader would have
# taken is noise at worst, never a false green.
#
# The invariant is not an equality, and THIS function is not widened to match
# the backstop. The readers are FIRST-OCCURRENCE-WINS, so widening what counts
# as an occurrence would let a QUOTED form outrank the real one: in the
# problem-report reader of check-trace.sh, a block quoting
# `- status: resolved` in its prose, above its own column-one `status: open`,
# would hand the reader the quotation, and the open item would leave the
# roll-call at exit 0. Same for `opened:` and `disposition:`.
#
# So the readers stay narrow and the backstop alone is wide. A bulleted
# annotation is never READ, and is REPORTED where it belongs to no item.
# Inside a block it is simply not the annotation the item made, and the gate
# fails loudly for the field it now lacks: INCOMPLETE-PROBLEM. Loud is the
# correct answer to an annotation written in a form no reader accepts; silent
# promotion of a quotation is not.
#
# Unanchored is worse again — it fires on any sentence containing the word —
# and column one is also what keeps the indented grammar comments in the ledger
# templates inert.
function gr_kw_here(line, kw) {
    return (index(line, kw) == 1)
}
# THE ANNOTATION RULE for an ID-list keyword (satisfies:, traces:,
# implements:, mitigates:): where KW starts an annotation on this line. It
# starts at column one, or anywhere on the definition line of a block this gate
# collects, which carries the inline form the templates ship
# (`**SDD-…**: … traces: REQ-…`). Nowhere else: not after a list marker, a
# task-list box, a blockquote or a word of prose. Returns the line from the
# keyword on, ready for gr_id_run, or "" where the line starts no annotation.
#
# Every block reader of those keywords takes its text from here, so one rule
# decides where an annotation starts, and nothing is left to enumerate: a lead
# the rule does not name is outside it. That is what lets the ORPHAN-ANNOTATION
# backstop contain the readers. Outside every block no definition line exists,
# so the reader position there is column one, which gr_kw_orphan_here covers.
function gr_annotation(line, kw,   kw_pos) {
    if (gr_kw_here(line, kw)) return line
    if (!gr_block_opens(line)) return ""
    kw_pos = index(line, kw)
    return (kw_pos > 0 ? substr(line, kw_pos) : "")
}
# Could KW be READ from this line by anything? Column one, or column one after
# a run of the leads gr_kw_lead steps over. THE BACKSTOP form, and
# deliberately wider than gr_kw_here per the invariant above. Callers are
# backstops — check_orphans and the supersession scan in check-trace.sh — and
# no reader may call it.
#
# The containment holds by construction. Outside every block no definition
# line exists, so a reader would take a keyword there only at column one
# (gr_annotation), and this sees column one. The lead width is extra: a
# bulleted orphan is reported although no reader would take it, which is
# noise at worst, never a false green. Inside a block, check_orphans reports
# an ID-list keyword this sees and gr_annotation does not take.
#
# gr_kw_here carries no list-marker rule because such a rule fires on
# `- status: resolved only in the same change that merges the fix.`, prose in
# the shipped templates/problems.md and in the twin the ratchet installs at
# docs/problems/README.md. That sentence is a hazard to THIS function for the
# same reason, so both lines give the illustrative form inline in backticks,
# which is the convention those templates already state for their own
# examples. An extended-regex grep over docs/, templates/ and
# skills/ for the WIDENED lead rule followed by a block-parsed keyword —
# ^[[:space:]]*(([-*+]|[0-9]+[.)]|\[[ xX]\])[[:space:]]+|>[[:space:]]*)+ —
# returns nothing at all. That is the sizing grep in the newest section of
# skills/ratchet/references/upgrade-notes.md, and it is gr_kw_lead written
# out, so what it prints is what this steps over.
function gr_kw_orphan_here(line, kw) {
    return (index(gr_kw_lead(line), kw) == 1)
}
# The value of an annotation: everything after the keyword, trimmed. A keyword
# with nothing after it declares nothing, and every reader here treats it as
# absent — an empty `opened:` is an omission wearing the shape of compliance.
#
# Meaningful only where gr_kw_here is true, which is why both are defined here,
# narrow for the same reason gr_kw_here is: it is the READER half of a reader
# pair, and it moves only when gr_kw_here moves. substr from length(kw) + 1
# assumes the keyword starts at byte one, so a caller that has tested
# gr_kw_orphan_here and wants a value from the wider position composes the two
# — gr_value(gr_kw_lead(line), kw) — rather than widening this.
function gr_value(line, kw,   v) {
    v = substr(line, length(kw) + 1)
    sub(/^[ \t]+/, "", v)
    sub(/[ \t]+$/, "", v)
    return v
}
# The bare ID of a definition line. Meaningful only where gr_block_opens is
# true.
function gr_block_id(line,   id) {
    id = line
    sub(/^\*\*/, "", id)
    sub(/\*\*:.*/, "", id)
    return id
}
'

# Bounded YAML front matter, as an awk fragment with ONE definition.
#
# A leading front-matter block is document metadata, not ledger prose:
# `status: draft` there is a title-page field, and a scan that reads it as an
# annotation fails a correct document. A gate that requires a field must not
# accept one from the header block either, which is the same rule read the
# other way round.
#
# TWO PASSES, and the second one is what makes the block bounded. Pass one
# finds where the front matter ENDS; pass two skips up to there. A single pass
# with a running flag has no bound, so a leading `---` that is a thematic break
# — or front matter someone half deleted — switches the scan off for the whole
# file, which is the read-matched-and-dropped-in-silence these gates exist to
# remove. With no terminator, GR_FM_END stays 0 and nothing is skipped.
#
# Only line 1 may OPEN a block; `...` closes one as well as `---`, and a
# trailing CR is tolerated so a document saved with CRLF endings is not read as
# having no front matter at all.
#
# CONSUMERS MUST REPORT FNR, NEVER NR. The file is read twice, so NR is offset
# by the whole first pass and every line number reported would name a line that
# does not exist. An early version of the orphan scan did exactly that.
#
# A BOM is in front of column one and hides it from every match here, the
# `---` delimiter included, so the caller strips it in BOTH passes.
GR_AWK_FRONT_MATTER='
function gr_fm_reset() { GR_FM_IN = 0; GR_FM_END = 0 }
function gr_fm_scan(line, n) {
    # Line 2 decides. A `---` at line 1 opens front matter only if a KEY
    # follows it immediately; `---` then a blank line is a horizontal rule at
    # the top of a document, and treating one as a header would switch the scan
    # off for everything up to the next rule: on the problem-report reader an
    # open item drops out of the roll-call at exit 0, and in the backstop every
    # annotation in the span is silently dropped.
    # YAML has no blank line between the opening delimiter and the first key,
    # so nothing legitimate is lost, and the rule can only make the scan read
    # MORE: it never suppresses a report.
    if (n == 1) { GR_FM_MAYBE = (line ~ /^---[ \t\r]*$/); return }
    if (n == 2) {
        if (GR_FM_MAYBE && line !~ /^[ \t\r]*$/) GR_FM_IN = 1
        GR_FM_MAYBE = 0
        if (!GR_FM_IN) return
    }
    if (GR_FM_IN && line ~ /^(---|\.\.\.)[ \t\r]*$/) { GR_FM_END = n; GR_FM_IN = 0 }
}
function gr_fm_skip(n) { return (n <= GR_FM_END) }
'

# Calendar dates, as an awk fragment with ONE definition.
#
# `date -d` is GNU and `date -j -f` is BSD; neither is POSIX, so no shell-level
# date arithmetic is portable. `date +%Y-%m-%d` IS POSIX, and everything after
# it is integer work done here — which runs the same on gawk, mawk and busybox
# awk, and needs no locale, no timezone database and no external process.
#
# BYTE-WISE, deliberately. The obvious shape test is a regex, and it fails
# OPEN: under gawk in a multibyte locale a bracket expression does not match
# an invalid byte sequence, so a latin-1 value passes it. substr and index count bytes in every locale.
#
# gr_date_ok sets GR_DATE_DAYS as a side effect rather than returning it,
# because the day number is legitimately negative for dates before 1970 and
# there is then no value left to mean "not a date".
GR_AWK_CIVIL='
function gr_digits(s,   i, n) {
    n = length(s)
    if (n == 0) return 0
    for (i = 1; i <= n; i++)
        if (index("0123456789", substr(s, i, 1)) == 0) return 0
    return 1
}
function gr_date_valid(y, m, d,   dim) {
    if (y < 1 || m < 1 || m > 12 || d < 1) return 0
    dim = 31
    if (m == 4 || m == 6 || m == 9 || m == 11) dim = 30
    else if (m == 2) dim = (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)) ? 29 : 28
    return (d <= dim)
}
# Days since 1970-01-01, by Howard Hinnant days_from_civil. int() truncates
# toward zero rather than flooring, which differs for negative operands — the
# year is >= 1 here (gr_date_valid rejects the rest), so it does not arise.
function gr_days_from_civil(y, m, d,   era, yoe, doy, doe) {
    if (m <= 2) y--
    era = int(y / 400)
    yoe = y - era * 400
    doy = int((153 * (m > 2 ? m - 3 : m + 9) + 2) / 5) + d - 1
    doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
    return era * 146097 + doe - 719468
}
# 1 and GR_DATE_DAYS set, or 0. Nothing else in the toolkit parses a date.
function gr_date_ok(s,   y, m, d) {
    GR_DATE_DAYS = 0
    if (length(s) != 10) return 0
    if (substr(s, 5, 1) != "-" || substr(s, 8, 1) != "-") return 0
    if (!gr_digits(substr(s, 1, 4))) return 0
    if (!gr_digits(substr(s, 6, 2))) return 0
    if (!gr_digits(substr(s, 9, 2))) return 0
    y = substr(s, 1, 4) + 0
    m = substr(s, 6, 2) + 0
    d = substr(s, 9, 2) + 0
    if (!gr_date_valid(y, m, d)) return 0
    GR_DATE_DAYS = gr_days_from_civil(y, m, d)
    return 1
}
'

# gr_die MESSAGE — diagnose and exit 2.
#
# printf, never echo. Under dash — /bin/sh on Debian and its derivatives —
# `echo` processes backslash escapes in its argument, and these messages quote
# the operator's own config back at them. A config line containing `\t` is then
# shown with a literal tab where the file has two characters, on a message whose
# whole job is to point at that line; and one containing `\c` TRUNCATES the
# message there, discarding the remedy that follows the quoted text.
gr_die() {
    printf '%s\n' "guardrails: $*" >&2
    exit 2
}

gr_root() {
    git rev-parse --show-toplevel 2>/dev/null || gr_die "not inside a git repository"
}

# gr_contains LIST ITEM — is ITEM one of the newline-separated LIST entries?
gr_contains() {
    case "
$1
" in *"
$2
"*) return 0 ;; esac
    return 1
}

# Value cleanup shared by cfg_get and cfg_list: drop a trailing CR (a config
# saved with CRLF endings otherwise puts an invisible \r inside every value,
# and the resulting error message accuses a path or prefix that looks perfectly
# valid), drop a trailing ` # comment`, then drop trailing blanks.
#
# The comment strip requires whitespace before the `#`, so `path#anchor` and
# `sh -c 'echo "#done"'` remain. It cannot be escaped: a value whose own
# whitespace-delimited token starts with `#` is truncated silently. That is
# recorded in templates/config.yaml rather than worked around.
GR_AWK_CLEAN_VALUE='
function gr_clean(v) {
    sub(/\r$/, "", v)
    sub(/[ \t]+#.*$/, "", v)
    sub(/[ \t]+$/, "", v)
    return v
}
'

# A CARRIAGE RETURN IS STRIPPED BEFORE THE STRUCTURE IS JUDGED, not only out of
# the value. gr_clean handles a `\r` inside a value; that is not enough. In a
# CRLF file a BLANK line is a line containing one `\r`, which is neither a space
# nor a tab, so cfg_list's "a column-one line ends the block" test fired on it:
# every item below the first blank line in a list was read by nobody, and the
# gate that wanted them passed having examined less than it was configured to.
#
# gr_check_config normalises `\r` before validating each line, so such a file
# is pronounced valid — the validator whose purpose is to reject a config that
# would silently disable a gate is what made the byte invisible. It rejects a
# BOM outright, and CRLF was left half-supported instead.
GR_AWK_STRIP_CR='
function gr_line(s) { sub(/\r$/, "", s); return s }
'

# cfg_get KEY — print the scalar value of a top-level `key: value` entry.
#
# The post-colon blanks are stripped AFTER gr_clean, not before. Stripping them
# first takes away the whitespace gr_clean's ` #` rule needs to see, so
# `strict_paths:  # only these` yields the VALUE `# only these` — non-empty —
# and the form rule below then reads a list key as a scalar and rejects the
# config from every gate. The rule this file states is that a trailing
# ` # comment` is stripped for EVERY key; this is what makes that true of a key
# whose value is otherwise empty.
#
# No gr_line here, deliberately: a CR in a CRLF file is always at end of record,
# so it cannot reach the key match at column one, and gr_clean already strips it
# off the value. cfg_list needs it because a blank CRLF line is a record
# consisting of the CR alone, and that record is judged as structure.
# cfg_get/cfg_list read $GR_CONFIG unless handed an explicit FILE as $2. The
# second argument exists for exactly two callers — the manifest reader and the
# cross-unit helpers — so that .guardrails/units.yaml and a sibling unit's
# config are read by THE SAME parser that reads this config. Two near-copies
# of a reader is how readers drift (GR_AWK_ID_RUN's block comment).
cfg_get() {
    _cf="${2:-$GR_CONFIG}"
    [ -f "$_cf" ] || gr_die "config not found: $_cf"
    awk -v k="$1" "$GR_AWK_CLEAN_VALUE"'
        index($0, k ":") == 1 {
            sub(/^[^:]*:/, "")
            v = gr_clean($0)
            sub(/^[ \t]+/, "", v)
            print v
            exit
        }
    ' "$_cf"
}

# cfg_list KEY — print items of a top-level `key:` block of `  - item` lines.
cfg_list() {
    _cf="${2:-$GR_CONFIG}"
    [ -f "$_cf" ] || gr_die "config not found: $_cf"
    awk -v k="$1" "$GR_AWK_CLEAN_VALUE$GR_AWK_STRIP_CR"'
        { line = gr_line($0) }
        !inlist && index(line, k ":") == 1 { inlist = 1; next }
        # A column-one line ends the block, comments included. Skipping them
        # instead would silently ADOPT any items below into this list — an
        # item under a commented-out key would become a member of whatever
        # block was open above it. gr_check_config rejects that shape outright
        # rather than either reader guessing at it.
        inlist && line ~ /^[^ \t]/ { exit }
        inlist && line ~ /^[ \t]*-[ \t]/ {
            sub(/^[ \t]*-[ \t]*/, "", line)
            print gr_clean(line)
        }
    ' "$_cf"
}

# gr_prefixes — the configured ID prefixes, one per line, validated. A prefix
# is interpolated into regular expressions, so a metacharacter here makes every
# ID scan an invalid pattern; git grep then errors, matches nothing, and an
# errored scan is indistinguishable from a clean tree. Reject it at the source.
gr_prefixes() {
    _v=$(cfg_get id_prefixes)
    [ -n "$_v" ] || gr_die "id_prefixes not configured"
    # id_prefixes is a space-separated scalar, but callers that handle path
    # lists run with IFS set to newline. Split on the default set regardless of
    # the caller's IFS, or the whole value arrives as one "prefix".
    _saved_ifs=${IFS-__gr_unset__}
    unset IFS
    # `set -f` with it: word splitting drags pathname expansion along, so
    # without this an `id_prefixes` entry containing a glob character means one
    # thing in a repository whose root contains a matching name and
    # another everywhere else — the same config, two verdicts, decided by an
    # unrelated directory listing.
    case $- in (*f*) _pfx_refl=1 ;; (*) _pfx_refl=0 ;; esac
    set -f
    _out=""
    for _one in $_v; do
        case "$_one" in
            ([!A-Za-z]* | *[!A-Za-z0-9]*)
                gr_die "id_prefixes entry is not a bare identifier: $_one" ;;
        esac
        _out="${_out}${_one}
"
    done
    [ "$_pfx_refl" -eq 1 ] || set +f
    if [ "$_saved_ifs" = "__gr_unset__" ]; then unset IFS; else IFS=$_saved_ifs; fi
    printf '%s' "$_out"
}

# gr_prefix_re — ERE alternation of the configured ID prefixes: REQ|HAZ|RC|SDD
gr_prefix_re() {
    # NOT `gr_prefixes | tr …`: in a pipeline the function's exit status is the
    # last command's, so a gr_die here would be reported as success and every
    # `P=$(gr_prefix_re) || exit 2` guard at the call sites would be dead code.
    _p=$(gr_prefixes) || exit 2
    printf '%s' "$_p" | tr '\n' '|' | sed 's/|$//'
}

# GR_SCAN_EXCLUDE — the one pathspec every tree-wide scan excludes.
#
# Used as `git grep … -- . "$GR_SCAN_EXCLUDE"` at every site in check-ids.sh,
# check-trace.sh and new-id.sh. One definition because those scans must agree
# about which files exist: the mint scan and pre-flight of the old
# finalize-ids.sh disagreed with nothing, but they agreed with each other only
# by having been typed the same way fifteen times.
#
# It names `.guardrails/scripts`, NOT `.guardrails`. The exclusion exists so the
# installed scripts do not report themselves — their comments can contain a
# literal draft token and definition-form examples — and the scripts are the only
# thing under `.guardrails/` that matches any gate's pattern; config.yaml
# matches none. Excluding the whole directory would also hide the project's own
# files: with `doc_srs: .guardrails/docs/requirements`, the ledger would be
# invisible to every gate, and both check scripts would pass a tree with a
# live draft token in it.
# Narrowing cannot reach one case: a doc_* configured INSIDE this directory is
# still accepted, and checked: counts its items as zero. Whether any gate
# complains first depends on whether git tracks or ignores the ledger, and on
# whether the ledger has been renamed out of its DRAFT- name — the same is true
# of .git/, gitignored paths and symlinks leaving the repository. No check
# rejects the shape outright: it is a configuration nobody writes, and the
# check costs far more code than the narrowing.
#
# A variable, not a function like gr_def_re: this is a separate `git grep`
# argument, and a function's output would have to be word-split — which
# check-trace.sh cannot do, setting IFS to newline at top level. Assigned unconditionally, never `${GR_SCAN_EXCLUDE:-…}`: a value
# inherited from the environment could widen it to `:(exclude).` and blind
# every gate in the toolkit while each one still exited 0.
GR_SCAN_EXCLUDE=':(exclude).guardrails/scripts'

# gr_example_excludes — one `:(exclude)<entry>` pathspec per example_paths
# entry, one per line, and nothing when the key is absent. example_paths names
# the files that hold example and fixture text: an item definition, a draft
# token or a history citation quoted there is an illustration, and a gate that
# read it would convict the illustration. The pathspecs go beside
# GR_SCAN_EXCLUDE at each scan that skips those files. The caller splits the
# lines on newlines alone, with globbing off, so a path with a space or a
# glob character reaches git as the one pathspec the config wrote.
gr_example_excludes() {
    _gee_entries=$(cfg_list example_paths) || exit 2
    [ -n "$_gee_entries" ] || return 0
    printf '%s\n' "$_gee_entries" | sed 's/^/:(exclude)/'
}

# gr_require_paths KEY ENTRIES… — exit 2 for an entry that matches no file
# present in the working tree. A configured path that does not exist makes
# every gate that reads it a silent no-op, so it fails as an environment error
# instead of passing vacuously. An entry matching no file at all scans no
# file, and that is what must be an error.
gr_require_paths() {
    _grp_key="$1"
    shift
    for _grp_entry in "$@"; do
        [ -n "$_grp_entry" ] || continue
        # No `[ -e ] && continue` short-circuit: an empty directory exists but
        # contains nothing to scan, and passing it here would report `strict 1`
        # in the summary for a source that read nothing — the exact false green
        # the summary exists to expose. Every entry must match a FILE.
        #
        # The entry may be a plain path or a git pathspec: `*_test.sh`
        # matches recursively for git, and git grep — which is what actually
        # scans these — accepts it. So ask git. Only an entry matching no file
        # at all is an error. NB git's `*` crosses `/` where a shell glob does
        # not, so `src/*.c` reaches into subdirectories.
        # Counted, never parsed. git ls-files C-quotes any path with a
        # non-ASCII byte, a quote, a tab or a newline (core.quotePath), so
        # testing [ -e ] on each returned name rejects a directory like
        # `tésts/` that git grep scans perfectly well. Counting lines is
        # immune to the quoting, and a quoted embedded newline still counts
        # as the one line it is printed as.
        #
        # The match must also still be present in the working tree — git grep
        # scans the tree, so a path that is tracked but deleted on disk would
        # pass this check while scanning nothing. cached minus deleted, plus
        # untracked-but-not-ignored, is exactly "matches a file that is there".
        #
        # Each listing is taken apart from its count, so a git failure is
        # reported as one rather than read as "matches no file".
        _grp_cached=$(git ls-files --cached -- "$_grp_entry") \
            || gr_die "$_grp_key entry: git ls-files --cached failed on $_grp_entry"
        _grp_gone=$(git ls-files --deleted -- "$_grp_entry") \
            || gr_die "$_grp_key entry: git ls-files --deleted failed on $_grp_entry"
        _grp_new=$(git ls-files --others --exclude-standard -- "$_grp_entry") \
            || gr_die "$_grp_key entry: git ls-files --others failed on $_grp_entry"
        # grep -c exits 1 on a count of zero, which is an answer, not a
        # failure; the pipeline's status is grep's and is not read.
        _grp_cached=$(printf '%s' "$_grp_cached" | grep -c .)
        _grp_gone=$(printf '%s' "$_grp_gone" | grep -c .)
        _grp_new=$(printf '%s' "$_grp_new" | grep -c .)
        if [ $((_grp_cached - _grp_gone + _grp_new)) -le 0 ]; then
            gr_die "$_grp_key entry matches no file present in the working tree: $_grp_entry"
        fi
    done
}

# gr_check_examples — exit 2 for an example_paths entry that matches no file
# present in the working tree, or one that matches a file a doc_* key resolves
# to. A ledger is never example text: excluded, its items would be defined
# nowhere any gate reads. Called after gr_check_config and with pathname
# expansion on, which gr_doc_files needs for its *.md.
gr_check_examples() {
    _gce_entries=$(cfg_list example_paths) || exit 2
    [ -n "$_gce_entries" ] || return 0
    _gce_docs=""
    for _gce_key in doc_srs doc_rmf doc_sad doc_soup doc_problems; do
        _gce_files=$(gr_doc_files "$_gce_key") || exit 2
        if [ -n "$_gce_files" ]; then
            _gce_docs="${_gce_docs}${_gce_docs:+
}$_gce_files"
        fi
    done
    # Newline splitting and no globbing, restored on return as gr_prefixes
    # does: an entry is one pathspec, whatever it contains.
    _gce_saved_ifs=${IFS-__gr_unset__}
    IFS='
'
    case $- in (*f*) _gce_refl=1 ;; (*) _gce_refl=0 ;; esac
    set -f
    # shellcheck disable=SC2086
    gr_require_paths example_paths $_gce_entries
    # Each ledger file as git names it, so `docs/requirements//a.md` from a
    # doc_* value with a trailing slash compares equal to what an entry
    # matches. `:(literal)` because a ledger file name is a name, not a
    # pattern.
    # A listing that fails lists nothing, and an entry would then pass this
    # check against no ledger at all.
    _gce_ledger=""
    for _gce_doc in $_gce_docs; do
        _gce_named=$(git -c core.quotePath=false ls-files --cached --others --exclude-standard -- ":(literal)$_gce_doc") \
            || gr_die "ledger file listing failed for $_gce_doc"
        _gce_ledger="${_gce_ledger}
$_gce_named"
    done
    for _gce_entry in $_gce_entries; do
        _gce_hits=$(git -c core.quotePath=false ls-files --cached --others --exclude-standard -- "$_gce_entry") \
            || gr_die "example_paths file listing failed for $_gce_entry"
        for _gce_hit in $_gce_hits; do
            gr_contains "$_gce_ledger" "$_gce_hit" || continue
            gr_die "example_paths entry matches a ledger file: $_gce_entry matches $_gce_hit
  A ledger is never example text: listed, its items would be defined nowhere a
  gate reads. Narrow the entry to the example files."
        done
    done
    [ "$_gce_refl" -eq 1 ] || set +f
    if [ "$_gce_saved_ifs" = "__gr_unset__" ]; then unset IFS; else IFS=$_gce_saved_ifs; fi
    return 0
}

# GR_DRAFT_TOKEN_RE — a draft ID token (<PREFIX>-DRAFT-<slug>-<n>), the shape
# check-ids.sh convicts as DRAFT-ID and check-units.sh as DISCLAIMED-DRAFT.
# GR_DRAFT_FILE_RE — a draft-named file (DRAFT-… as its last path component),
# the DRAFT-FILE / DISCLAIMED-DRAFT file half of the same rule.
#
# One definition because two readers of one pattern is how DISCLAIMED-DRAFT
# would silently split from DRAFT-ID: hand-copied, the repo-level scan and the
# scoped scan drift apart one edit at a time, and a token one of them no
# longer recognises merges through the other's blind spot. Assigned
# unconditionally, like GR_SCAN_EXCLUDE above and for the same reason: an
# environment-inherited value could narrow both gates at once in silence.
GR_DRAFT_TOKEN_RE='[A-Za-z][A-Za-z0-9]*-DRAFT-[A-Za-z0-9][A-Za-z0-9-]*-[0-9]+'
GR_DRAFT_FILE_RE='(^|/)DRAFT-[^/]*$'

# gr_def_re ALTERNATION [POSITION] — ERE matching an item definition
# line: a bold ID followed immediately by a colon, at line start.
#
# One constructor because two scripts must agree about the same string:
# check-ids.sh decides what is a duplicate and what is malformed, and
# check-trace.sh decides what exists at all. There was a third — the old
# finalize-ids.sh decided what number came next — and while the three
# disagreed, that one alone matched the form UNANCHORED, so a token in prose
# raised a mint ceiling neither gate could see. The ceiling is gone with
# sequential numbering; the constructor stays, because two readers of one
# string is exactly how that drift started.
#
# POSITION is spliced in front and defaults to `^`. Pass '^\+' or '^-' to scan
# `git diff` output, where a definition is at line start behind a + or -, and
# the empty string to match the token anywhere on a line. Do NOT express that
# last case as '^.+': git's matcher backtracks on a leading .+ and costs tens
# of seconds per prefix on a few hundred documents, against tenths of a second
# for the unanchored form. No figure is given for that cost: a bare number here
# could not be re-derived and drifted into three different values.
#
# Two behavioural tests hold every gate to this one form: "poisoning gr_def_re"
# (tests/check-ids.bats) and "widening GR_ID_BODY" (tests/check-trace.bats).
# A scan with its own copy of the form fails both. Never spell it out again.
gr_def_re() {
    printf '%s' "${2-^}\\*\\*(${1})-${GR_ID_BODY}\\*\\*:"
}

# gr_def_re_loose ALTERNATION [POSITION] — ERE matching a line that OPENS in
# definition form for one of the given prefixes, whatever its body: the shape
# `**PREFIX-<anything but an asterisk>**:` at line start.
#
# The complement of gr_def_re over the same anchor. A line this matches and
# gr_def_re does not is a definition form whose ID cannot be read, and there is
# no third possibility — which is what makes "loose minus strict" a total
# classification of DEFINITION-SHAPED lines. It is not a classification of
# header-shaped ones, and that distinction matters: where ADR is not declared,
# a bold four-digit ADR ID followed by a colon is a header this pattern does
# not match. Where it is declared, as in the shipped config, both this pattern
# and gr_def_re match it, and it is a valid item.
#
# ONE consumer: the MALFORMED-ID scan in check-ids.sh. There such a line is a
# document defect
# — the item it announces is invisible to every gate — and it is reported at
# exit 1.
#
# check-trace.sh does NOT use it. A check-trace.sh pre-flight that rejected a
# tree holding such a line would make check-trace.sh's soundness depend on a
# scan that belongs to check-ids.sh, and would break the drift-test fixtures
# that rely on a malformed form being inert. Its block rule closes on a header
# SHAPE instead, which is broader and keyed on no vocabulary. Kept as a
# constructor rather than folded back inline because MALFORMED-ID is the
# complement of gr_def_re over one anchor, and the two belong next to each
# other where that is visible.
gr_def_re_loose() {
    printf '%s' "${2-^}\\*\\*(${1})-[^*]*\\*\\*:"
}

# gr_base_branch — the branch checked out in the primary (non-worktree)
# checkout, which is what a change merges into. Never falls back to a linked
# worktree's branch. Return contract:
#   status 0, the branch name   — the primary checkout is on a branch;
#   status 0, no output         — the primary checkout is detached;
#   git's non-zero status, no output — `git worktree list` failed, and git's
#                                 error is on stderr.
# A caller must take the status: an empty result with status 0 is detachment,
# and the same empty result from a git failure is not.
gr_base_branch() {
    gr_base_branch_listing=$(git worktree list --porcelain) || return
    printf '%s\n' "$gr_base_branch_listing" | awk '
        /^worktree / { n++ }
        n > 1 { exit }
        sub(/^branch refs\/heads\//, "") { print; exit }
    '
}

# gr_nested_worktrees WT — every registered worktree path inside WT, one per
# line, indented. Reads `$wt_list`, the porcelain listing captured and
# status-checked by its caller. Shared by finish-merge.sh (--check and guard 4)
# and task-worktree.sh start, merge, remove and discard: the check that loses
# work if it answers wrong is not a check to write twice.
#
# Written in plain shell, with no awk, and that is the point. `awk -v k=v`
# ESCAPE-PROCESSES the value on its way into the program: `-v inside='w\top/'`
# arrives as `w<TAB>op/`. A change worktree whose path contained a backslash
# therefore made the prefix test match nothing, the result come back empty, and
# finish-merge.sh's guard 4 PASS — after which guard 3 removed the change
# worktree and took the nested worktree's uncommitted work with it, at exit 0.
# Every other rejection in finish-merge.sh fails CLOSED and merely withholds
# cleanup; this is the one whose failure loses work, so it is built out of constructs that have no escape
# layer to get wrong: `read -r` on whole lines, `${x#...}` for the prefix
# strip, and a `case` pattern whose variable half is quoted and therefore
# literal.
#
# The leading `(` on each pattern is critical, not style: callers use this
# inside a $(...) command substitution, and bash 3.2 — macOS's /bin/sh —
# mis-parses an unparenthesised pattern's closing `)` as the substitution's
# own, failing the WHOLE SCRIPT at parse time (`syntax error near unexpected
# token ';;'`), before any guard runs. POSIX makes the open paren optional;
# that shell makes it mandatory here.
#
# The matches are PRINTED, not accumulated in a variable: a `while read` fed by
# a pipe runs in a subshell, so an assignment inside it would not remain after
# the loop, and a command substitution is how the result reaches the caller.
# `printf` cannot fail on a string already in memory.
#
# The comparison is a prefix test of WT against the paths git RECORDS, not
# against anything resolved afresh. WT is the caller's: finish-merge.sh passes a
# path read from the same `git worktree list`, so both sides are spelled alike
# whatever the platform did to symlinks; task-worktree.sh passes its task path,
# built from gr_root, so a match depends on gr_root spelling the change
# worktree as git records it. The trailing
# `/` is critical — without it a sibling at `<wt>-sibling`, which is not
# inside anything, would be reported as nested.
gr_nested_worktrees() {
    printf '%s\n' "$wt_list" | while IFS= read -r gr_line; do
        case "$gr_line" in
            ("worktree "*) ;;
            (*) continue ;;
        esac
        gr_path=${gr_line#worktree }
        case "$gr_path" in
            ("$1"/*) printf '    %s\n' "$gr_path" ;;
        esac
    done
}

# gr_doc_files KEY — resolve a doc_* config value to a file list, one per
# line. A directory yields its *.md files (sorted); a file yields itself; a
# missing KEY yields nothing (the project does not use that document).
#
# Two cases are ERRORS, not empty lists: a key configured to a path that does
# not exist, and a directory containing no *.md at all. Silently yielding
# nothing there turns whole gate families into no-ops that still exit 0.
gr_doc_files() {
    _v=$(cfg_get "$1")
    [ -n "$_v" ] || return 0
    if [ -d "$_v" ]; then
        gr_md_files "$_v" "$1 is configured as directory"
    elif [ -f "$_v" ]; then
        printf '%s\n' "$_v"
    else
        gr_die "$1 is configured as '$_v', which does not exist"
    fi
    return 0
}

# gr_md_files DIR LABEL — the *.md files directly in DIR, one per line. A
# directory containing none is an ERROR, never an empty list, for the reason
# gr_doc_files gives: a gate reading nothing is indistinguishable from a gate
# finding nothing wrong. LABEL names the caller in that error.
#
# Shared by gr_doc_files and the callers that list a directory of their own,
# so the EMPTINESS RULE cannot drift between them.
#
# One level only: a *.md in a subdirectory is not listed. That is the limit
# gr_doc_files has always had, stated here where both readers can see it.
gr_md_files() {
    _dir="$1"
    _n=0
    for _f in "$_dir"/*.md; do
        [ -f "$_f" ] || continue
        _n=$((_n + 1))
        printf '%s\n' "$_f"
    done
    [ "$_n" -gt 0 ] || gr_die "$2 '$_dir', which contains no *.md files"
    return 0
}

# gr_message_file — the absolute path of this worktree's squash message, the
# verification record (ADR-k3nkv3). It is in the worktree's own git directory:
# never in the tree the gate measures, never a `git status` change, kept
# across reruns of the merge sequence, and removed with the worktree.
gr_message_file() {
    _gm=$(git rev-parse --git-path guardrails-squash.msg) \
        || gr_die "git rev-parse could not name the squash message's path; git's error is above"
    case "$_gm" in
        (/*) ;;
        (*) _gm="$(pwd)/$_gm" ;;
    esac
    printf '%s\n' "$_gm"
}

# The body fields a squash message must give a value, space-separated.
GR_MESSAGE_FIELDS='reviewer verdict reproduced'

# gr_placeholder(field_text) — does field_text still hold a template
# placeholder: a `<`, then a lowercase letter or two uppercase ones, then no
# `<`, `>`, `@` or `:` up to a `>`, standing as a word, with a blank, a `(`,
# a `[`, a `-` or the text's edge before it and a blank, a `/`, `,`, `.`,
# `;`, `:`, `)`, a `[`, a `]` or the edge after it?
# templates/squash-message.txt's placeholders all have that shape (`<tree>`,
# `<passed>/<total>`, `<who reviewed at step 4>`, `<IDs>`, `<PR IDs>`,
# `PR-<id>`, `[<disposition>]`); an email address, a URL, `a<b and c>d` and
# `<Tab>` do not. A field, trailer or disposition holding one is missing
# (ADR-3hsvvq).
GR_AWK_PLACEHOLDER='
function gr_placeholder(field_text,   padded) {
    padded = " " field_text " "
    gsub(/\[/, " ", padded)
    gsub(/\]/, " ", padded)
    gsub(/-/, " ", padded)
    return padded ~ /[ \t(]<([a-z]|[A-Z][A-Z])[^<>@:]*>[ \t\/,.;:)]/
}
'

# gr_impact_units SCRIPT_DIR RANGE — the units of RANGE's impact set, one per
# line: the unit column of SCRIPT_DIR/check-units.sh --impact RANGE. Where it
# cannot be computed, a changed path no unit claims, check-units.sh's error
# stands on stderr and this returns 2. Run under a unit manifest only.
gr_impact_units() {
    _impact_lines=$(sh "$1/check-units.sh" --impact "$2") || return 2
    printf '%s\n' "$_impact_lines" | awk -F '\t' 'NF { print $1 }'
}

# gr_message_want KEY [UNITS] — how many trailers the squash message owes KEY,
# a list key of the config: verify_commands (Tests:) or coverage_command
# (Coverage:). One per entry, in this config, or under a unit manifest summed
# over the configs of UNITS, the change's impact set (gr_impact_units); and at
# least one Tests:, so a config with no verify_commands entry owes one. A
# repository with no manifest and no config owes one Tests: and no Coverage:
# (ADR-3hsvvq). Run from the repository root.
gr_message_want() {
    if gr_units_present; then
        _want_units=${2-}
        _want_entries=$(for _want_unit in $_want_units; do
            cfg_list "$1" "$_want_unit/.guardrails/config.yaml" || exit 2
        done) || return 2
    elif [ ! -f "$GR_CONFIG" ]; then
        _want_entries=""
    else
        _want_entries=$(cfg_list "$1") || return 2
    fi
    if [ -z "$_want_entries" ]; then
        _want_count=0
    else
        _want_count=$(printf '%s\n' "$_want_entries" | awk 'END { print NR }')
    fi
    if [ "$1" = verify_commands ] && [ "$_want_count" -lt 1 ]; then
        _want_count=1
    fi
    printf '%s\n' "$_want_count"
}

# gr_message_strip FILE — set _message_text to FILE without its `#` lines,
# which `--cleanup=strip` removes, and without a carriage return ending a
# line, so a CRLF file reads as LF. grep exits 1 when every line is one, an
# empty text; above 1 it could not read FILE, and that dies here, where a pipe
# would drop its status.
gr_message_strip() {
    _message_text=$(grep -v '^#' "$1")
    case $? in
        (0|1) ;;
        (*) gr_die "grep could not read $1" ;;
    esac
    _message_text=$(printf '%s\n' "$_message_text" | awk '{ sub(/\r$/, ""); print }')
}

# gr_message_present FILE — does FILE hold a line that is neither blank nor a
# `#` line? A message of `#` lines only is no message. An unreadable FILE is
# no message either, tested before grep reads it.
gr_message_present() {
    if [ ! -f "$1" ] || [ ! -r "$1" ]; then
        return 1
    fi
    gr_message_strip "$1"
    printf '%s\n' "$_message_text" | grep -q '[^[:space:]]'
}

# gr_message_facts FILE — read a squash message in the grammar of
# templates/squash-message.txt (ADR-3hsvvq) and print one fact per line:
#
#   FIELD NAME              a body field of GR_MESSAGE_FIELDS with a value
#                           that holds no template placeholder; every FIELD
#                           comes before every other fact
#   ITEMS WORD              a word of the Items: section, then
#   PROBLEMS WORD           a word of the Problems: section; a word is a run
#                           of letters, digits, `-` and `_`
#   FINDING N TAG           the first line of finding N, the first line with
#                           that number, and the word after its disposition
#   DISPOSITION TEXT        the text inside that finding's leading `[...]`,
#                           not blank and holding no template placeholder;
#                           absent where the finding has none
#   MALFORMED-FINDING LINE  a line in Findings: that is neither a finding nor
#                           a continuation (an indented line opening with
#                           `<N>. ` is none), or repeats a finding's number; a
#                           line outside it opening with `<N>. `, or a
#                           `Findings` header in another case, spacing or
#                           with text after its colon; or
#                           finding N's line, once, after its FINDING and
#                           DISPOSITION, where its disposition is not
#                           `fixed:`, `open:` or `no change:` then a non-blank
#                           remainder, or its tag is not `code`,
#                           `requirement` or `guideline` with a severity
#                           `high`, `medium` or `low`, or `record` with none,
#                           then ` — `
#   PLACEHOLDER KEY         a trailer other than Base: and Gate-tree:, whose
#                           own codes report one, still holding a template
#                           placeholder, before that trailer's own fact
#   BASE VALUE              a Base: trailer
#   GATE-TREE VALUE         a Gate-tree: trailer
#   TESTS VALUE             a Tests: trailer
#   COVERAGE VALUE          a Coverage: trailer
#   RESOLVES VALUE          a Resolves: trailer holding no template
#                           placeholder
#   MUTATION VALUE          a Mutation: trailer in the template's form, then
#   MUTATION-PATH PATH      the path it names, without its `:N`, and
#   MUTATION-TEST NAME      the test it names
#   MALFORMED-MUTATION VALUE  a Mutation: trailer not in that form
#
# The trailer facts come last, in trailer order. Lines opening with `#` are
# template guidance, which `--cleanup=strip` removes, so they are dropped
# first. Trailers are read by git's own parser from the last paragraph, as git
# reads them after signing: --no-divider, so a `---` line is text, not the end
# of the message; that paragraph is then not body, so a review field
# there does not count. The findings section runs from a column-one
# `Findings:` after the subject to the next blank line. The Items: and
# Problems: sections each run from their column-one header, the text after
# its colon included, to the first blank line after their content, so blank
# lines between the header and its list do not end them, or to the next
# column-one section header: `Items:`, `Problems:`, `Red-green:`, `Gaps:`,
# `Qualification:`, `Findings:` or a review field's.
#
# The message reaches awk on its standard input after the trailers and a
# sentinel line, never through `awk -v`: BWK awk rejects a newline there. awk
# runs under LC_ALL=C and spells the em dash as octal bytes, so a finding's
# dash and the Mutation: form read the same in any locale and under BWK awk.
gr_message_facts() {
    gr_message_strip "$1"
    _message_trailers=$(printf '%s\n' "$_message_text" | git interpret-trailers --parse --no-divider) \
        || gr_die "git interpret-trailers could not read $1"
    { printf '%s\n' "$_message_trailers"
      printf '%s\n' '@@guardrails-end-of-trailers@@'
      printf '%s\n' "$_message_text"; } \
        | LC_ALL=C awk -v field_names="$GR_MESSAGE_FIELDS" "$GR_AWK_PLACEHOLDER"'
    section == 0 && $0 == "@@guardrails-end-of-trailers@@" { section = 1; next }
    section == 0 {
        if ($0 != "") { trailer_count++; trailer[trailer_count] = $0 }
        next
    }
    { line_count++; line[line_count] = $0 }
    END {
        # Paragraphs: the subject is the first non-blank line, the trailer
        # paragraph the last, when git found trailers in it.
        first = 1
        while (first <= line_count && line[first] ~ /^[ \t]*$/) first++
        last = line_count
        while (last > 0 && line[last] ~ /^[ \t]*$/) last--
        last_paragraph = last
        while (last_paragraph > 1 && line[last_paragraph - 1] !~ /^[ \t]*$/)
            last_paragraph--
        body_end = (trailer_count > 0) ? last_paragraph - 1 : last

        field_count = split(field_names, field, " ")
        for (at = first + 1; at <= body_end; at++)
            for (field_at = 1; field_at <= field_count; field_at++)
                if (index(line[at], field[field_at] ":") == 1) {
                    field_value = substr(line[at], length(field[field_at]) + 2)
                    if (gr_placeholder(field_value)) continue
                    gsub(/[ \t]/, "", field_value)
                    if (field_value != "") given[field[field_at]] = 1
                }
        for (field_at = 1; field_at <= field_count; field_at++)
            if (field[field_at] in given) print "FIELD " field[field_at]

        for (field_at = 1; field_at <= field_count; field_at++)
            section_header[field[field_at]] = 1
        section_header["Items"] = 1; section_header["Problems"] = 1
        section_header["Red-green"] = 1; section_header["Gaps"] = 1
        section_header["Qualification"] = 1; section_header["Findings"] = 1
        # A blank line ends a section once it holds content: the blank lines
        # between a header and its first content line do not.
        section = ""
        for (at = first + 1; at <= body_end; at++) {
            section_text = line[at]
            if (section_text ~ /^[ \t]*$/) {
                if (section_content) section = ""
                continue
            }
            colon_at = index(section_text, ":")
            if (colon_at > 1 && (substr(section_text, 1, colon_at - 1) in section_header)) {
                section = substr(section_text, 1, colon_at - 1)
                if (section != "Items" && section != "Problems") section = ""
                section_text = substr(section_text, colon_at + 1)
                section_content = (section_text !~ /^[ \t]*$/)
            } else section_content = 1
            if (section == "") continue
            word_count = split(section_text, section_word, /[^A-Za-z0-9_-]+/)
            for (word_at = 1; word_at <= word_count; word_at++)
                if (section_word[word_at] != "")
                    print toupper(section) " " section_word[word_at]
        }

        in_findings = 0; finding_open = 0
        for (at = first + 1; at <= last; at++) {
            findings_line = line[at]
            # Outside the section, a header spelled otherwise and a line
            # opening with `<N>. ` are findings the section does not hold.
            if (!in_findings) {
                if (findings_line ~ /^Findings:[ \t]*$/) { in_findings = 1; continue }
                lowered = tolower(findings_line)
                if (lowered ~ /^findings[ \t]*:/ || lowered ~ /^findings[ \t]*$/ \
                        || findings_line ~ /^[0-9]+\. /)
                    print "MALFORMED-FINDING " findings_line
                continue
            }
            if (findings_line ~ /^[ \t]*$/) { in_findings = 0; finding_open = 0; continue }
            if (findings_line ~ /^[0-9]+\. /) {
                number = substr(findings_line, 1, index(findings_line, ".") - 1) + 0
                if (number in numbered) { print "MALFORMED-FINDING " findings_line; continue }
                numbered[number] = 1; finding_open = 1
                after_number = substr(findings_line, index(findings_line, ". ") + 2)
                close_at = index(after_number, "] ")
                disposition = ""
                tagged_text = after_number
                if (substr(after_number, 1, 1) == "[" && close_at > 0) {
                    disposition = substr(after_number, 2, close_at - 2)
                    tagged_text = substr(after_number, close_at + 2)
                }
                # The tag, its severity where it takes one, then the dash.
                tagged_word_count = split(tagged_text, tagged_word, " ")
                tag = tagged_word[1]
                dash_at = 0
                if (tag == "record") dash_at = 2
                else if ((tag == "code" || tag == "requirement" || tag == "guideline") \
                        && (tagged_word[2] == "high" || tagged_word[2] == "medium" \
                            || tagged_word[2] == "low")) dash_at = 3
                print "FINDING " number " " tag
                disposition_nonspace = disposition
                gsub(/[ \t]/, "", disposition_nonspace)
                if (gr_placeholder(disposition)) disposition_nonspace = ""
                # A disposition is `fixed:`, `open:` or `no change:`, then
                # something other than blanks.
                disposition_formed = 1
                if (disposition_nonspace != "") {
                    print "DISPOSITION " disposition
                    disposition_rest = ""
                    if (disposition ~ /^fixed:/) disposition_rest = substr(disposition, 7)
                    else if (disposition ~ /^open:/) disposition_rest = substr(disposition, 6)
                    else if (disposition ~ /^no change:/) disposition_rest = substr(disposition, 11)
                    gsub(/[ \t]/, "", disposition_rest)
                    if (disposition_rest == "") disposition_formed = 0
                }
                if (!disposition_formed || dash_at == 0 || tagged_word_count < dash_at \
                        || tagged_word[dash_at] != "\342\200\224")
                    print "MALFORMED-FINDING " findings_line
                continue
            }
            # An indented `<N>. ` line is a finding out of place, never a
            # continuation.
            if (findings_line ~ /^[ \t]/ && finding_open \
                    && findings_line !~ /^[ \t]+[0-9]+\. /) continue
            print "MALFORMED-FINDING " findings_line
        }

        marker = "\342\200\224 killed by \""
        for (at = 1; at <= trailer_count; at++) {
            colon_at = index(trailer[at], ": ")
            if (colon_at == 0) continue
            key = substr(trailer[at], 1, colon_at - 1)
            trailer_value = substr(trailer[at], colon_at + 2)
            if (key != "Base" && key != "Gate-tree" && gr_placeholder(trailer_value))
                print "PLACEHOLDER " key
            if (key == "Base") print "BASE " trailer_value
            else if (key == "Gate-tree") print "GATE-TREE " trailer_value
            else if (key == "Tests") print "TESTS " trailer_value
            else if (key == "Coverage") print "COVERAGE " trailer_value
            else if (key == "Resolves" && !gr_placeholder(trailer_value))
                print "RESOLVES " trailer_value
            else if (key == "Mutation") {
                if (trailer_value !~ /^[^ :]+:[0-9]+ .+ \342\200\224 killed by ".+"$/) {
                    print "MALFORMED-MUTATION " trailer_value
                    continue
                }
                path = substr(trailer_value, 1, index(trailer_value, " ") - 1)
                sub(/:[0-9]+$/, "", path)
                rest = trailer_value
                while ((marker_at = index(rest, marker)) > 0)
                    rest = substr(rest, marker_at + length(marker))
                print "MUTATION " trailer_value
                print "MUTATION-PATH " path
                print "MUTATION-TEST " substr(rest, 1, length(rest) - 1)
            }
        }
    }'
}

# gr_message_check FILE TREE TESTS COVERAGE DELETED — check a squash message
# against its grammar (ADR-3hsvvq), with gr_message_facts reading it: its
# Gate-tree: must name TREE, and it owes exactly TESTS Tests: and COVERAGE
# Coverage: trailers, the counts gr_message_want gives its caller. DELETED
# holds the IDs the change deletes (gr_deleted_items), empty for none. Its
# Resolves: trailers, their IDs split on commas, semicolons and blanks, name
# exactly the PR IDs in DELETED; its Problems: section names each of those PR IDs as a
# word, and its Items: section each other ID in DELETED. RESOLVES is reported
# per deleted PR no Resolves: names, then per named ID not deleted; PROBLEMS
# per deleted PR Problems: lacks; ITEMS per other deleted ID Items: lacks;
# each in ID order. DELETED is flattened to one line here, since BWK awk
# rejects a newline in `awk -v`. A review field or trailer value holding a
# template placeholder is missing. Prints one finding per line; returns 1 on
# any, 0 on none. Every argument is required: called with other than five,
# it exits 2. A FILE that is absent, unreadable or of `#`
# lines only is MISSING-RECORD, 1; it returns 2 when grep or git
# interpret-trailers fails on a FILE that passed that test.
# check-review.sh runs it on the message file before the hand-over,
# finish-merge.sh on the signed commit's message.
gr_message_check() {
    [ $# -eq 5 ] || gr_die \
"gr_message_check takes 5 arguments, FILE TREE TESTS COVERAGE DELETED, not $#."
    if ! gr_message_present "$1"; then
        printf 'MISSING-RECORD %s\n' "$1"
        return 1
    fi
    _message_facts=$(gr_message_facts "$1") || return 2
    _message_deleted=$(printf '%s\n' "$5" | tr '\n' ' ')
    printf '%s\n' "$_message_facts" | LC_ALL=C awk -v tree="$2" \
        -v tests_want="$3" -v coverage_want="$4" -v deleted="$_message_deleted" \
        -v field_names="$GR_MESSAGE_FIELDS" "$GR_AWK_PLACEHOLDER"'
    function report(finding) { print finding; reported++ }
    # Report the fields no FIELD fact gave, once, after the last FIELD.
    function settle_fields(   field_count, field, field_at) {
        if (fields_settled) return
        fields_settled = 1
        field_count = split(field_names, field, " ")
        for (field_at = 1; field_at <= field_count; field_at++)
            if (!(field[field_at] in given))
                report("INCOMPLETE-RECORD (no " field[field_at] ":)")
    }
    # Report the finding just read if no DISPOSITION followed it.
    function settle_finding() {
        if (undisposed != "") report("UNDISPOSED-FINDING " undisposed)
        undisposed = ""
    }
    # Report, in ID order, each ID of listed_ids that matching_ids lacks, as
    # prefix ID suffix.
    function report_missing(listed_ids, matching_ids, prefix, suffix,   id, ids, count, at, back, held) {
        count = 0
        for (id in listed_ids) if (!(id in matching_ids)) ids[++count] = id
        for (at = 2; at <= count; at++) {
            held = ids[at]
            for (back = at - 1; back >= 1 && ids[back] > held; back--)
                ids[back + 1] = ids[back]
            ids[back + 1] = held
        }
        for (at = 1; at <= count; at++) report(prefix ids[at] suffix)
    }
    $1 == "FIELD" { given[$2] = 1; next }
    { settle_fields() }
    $1 == "DISPOSITION" { undisposed = ""; next }
    { settle_finding() }
    $1 == "FINDING" { undisposed = $2; next }
    $1 == "ITEMS" { items_named[$2] = 1; next }
    $1 == "PROBLEMS" { problems_named[$2] = 1; next }
    $1 == "MALFORMED-FINDING" || $1 == "MALFORMED-MUTATION" { report($0); next }
    $1 == "PLACEHOLDER" { report("INCOMPLETE-RECORD (placeholder in " $2 ":)"); next }
    $1 == "BASE" {
        base_count++
        base_value = substr($0, 6)
        if (gr_placeholder(base_value)) base_placeholder = 1
        gsub(/[ \t]/, "", base_value)
        if (base_value == "") base_empty = 1
        next
    }
    $1 == "GATE-TREE" {
        gate_tree = substr($0, 11)
        gate_count++
        if (gate_tree == tree) gate_matches = 1
        gate_values = gate_values " " gate_tree
        next
    }
    # A placeholder Tests: or Coverage: is not counted; a Tests: that is
    # counted and not passed in full is FAILED-TESTS.
    $1 == "TESTS" {
        tests_value = substr($0, 7)
        if (gr_placeholder(tests_value)) next
        tests_count++
        word_count = split(tests_value, word, " ")
        passed_in_full = 0
        if (word_count > 0 && word[word_count] ~ /^[0-9]+\/[0-9]+$/) {
            split(word[word_count], tally, "/")
            if (tally[1] + 0 == tally[2] + 0 && tally[2] + 0 > 0) passed_in_full = 1
        }
        if (!passed_in_full) report("FAILED-TESTS " tests_value)
        next
    }
    $1 == "RESOLVES" {
        resolves_count = split(substr($0, 10), resolves_id, /[,; \t]+/)
        for (resolves_at = 1; resolves_at <= resolves_count; resolves_at++)
            if (resolves_id[resolves_at] != "") resolves_named[resolves_id[resolves_at]] = 1
        next
    }
    $1 == "COVERAGE" {
        coverage_value = substr($0, 10)
        if (gr_placeholder(coverage_value)) next
        gsub(/[ \t]/, "", coverage_value)
        if (coverage_value != "") coverage_count++
        next
    }
    END {
        settle_fields()
        settle_finding()
        if (base_count != 1)
            report("BASE (want one Base: trailer, found " base_count + 0 ")")
        else if (base_empty)
            report("BASE (want one Base: trailer, found empty)")
        else if (base_placeholder)
            report("BASE (want one Base: trailer, found a placeholder)")
        if (gate_count != 1 || !gate_matches)
            report("GATE-TREE (want one Gate-tree: " tree ", found" (gate_count ? gate_values : " none") ")")
        if (tests_count != tests_want + 0)
            report("TESTS (want " tests_want + 0 " Tests: trailers, one per verify_commands entry, found " tests_count + 0 ")")
        if (coverage_count != coverage_want + 0)
            report("COVERAGE (want " coverage_want + 0 " Coverage: trailers, one per coverage_command, found " coverage_count + 0 ")")
        deleted_count = split(deleted, deleted_id, " ")
        for (deleted_at = 1; deleted_at <= deleted_count; deleted_at++)
            if (index(deleted_id[deleted_at], "PR-") == 1)
                deleted_problems[deleted_id[deleted_at]] = 1
            else
                deleted_non_problems[deleted_id[deleted_at]] = 1
        report_missing(deleted_problems, resolves_named, "RESOLVES (deleted ", ", not named in Resolves:)")
        report_missing(resolves_named, deleted_problems, "RESOLVES (Resolves: names ", ", which this change does not delete)")
        report_missing(deleted_problems, problems_named, "PROBLEMS (deleted ", ", not named under Problems:)")
        report_missing(deleted_non_problems, items_named, "ITEMS (deleted ", ", not named under Items:)")
        exit (reported > 0)
    }'
}

# gr_deleted_items RANGE — the items RANGE deletes, one ID per line, sorted:
# each REQ, LLR, SDD, HAZ or RC ID whose definition line (gr_def_re) the diff
# of RANGE removes from the item ledgers, the configured doc_srs, doc_sad and
# doc_rmf, and each PR ID it removes from the problem ledgers, the configured
# doc_problems; in either case, one the diff does not add back to those
# ledgers. A ledger is the files check-trace reads (gr_doc_files): a
# directory's top-level *.md files, not its subdirectories or other files;
# a file, itself. A directory the checkout no longer has is read as a file
# path, every file below it. Under a units manifest the ledgers are each unit's; with none
# configured, or no configuration at all, there is no ledger, and nothing is
# deleted. A definition moved to another ledger file, or reworded under its
# ID, is not deleted; a definition outside the ledgers (a test fixture, a
# skill example) is never read; and over a three-dot RANGE an item added and
# deleted on the branch never appears. Returns 2 when the configuration, git,
# grep or awk fails.
#
# A resolved problem report is deleted by the change that fixes it
# (ADR-k3nkv3); that change's Resolves: and Problems: name each deleted PR,
# and its Items: each other deleted item (ADR-3hsvvq): check-review.sh passes
# refs/heads/<base>...HEAD, finish-merge.sh guard 5 HEAD^..HEAD, to
# gr_message_check.
gr_deleted_items() {
    _deleted_non_problems=$(gr_deleted_definitions "$1" 'REQ|LLR|SDD|HAZ|RC' \
        doc_srs doc_sad doc_rmf) || return 2
    _deleted_problems=$(gr_deleted_definitions "$1" PR doc_problems) || return 2
    { [ -z "$_deleted_non_problems" ] || printf '%s\n' "$_deleted_non_problems"
      [ -z "$_deleted_problems" ] || printf '%s\n' "$_deleted_problems"; } \
        | LC_ALL=C sort
}

# gr_deleted_definitions RANGE PREFIXES KEY... — for gr_deleted_items: the IDs
# of PREFIXES, an ERE alternation, whose definition line the diff of RANGE
# removes from the ledgers the config KEYs name and does not add back to
# them, one per line, unsorted. Returns 2 when the configuration, git, grep
# or awk fails.
gr_deleted_definitions() {
    _deleted_range=$1
    _deleted_prefixes=$2
    shift 2
    _deleted_ledgers=""
    for _deleted_key in "$@"; do
        if gr_units_present; then
            _deleted_units=$(gr_unit_list) || return 2
            _deleted_found=$(for _deleted_unit in $_deleted_units; do
                cfg_get "$_deleted_key" "$_deleted_unit/.guardrails/config.yaml" || exit 2
            done) || return 2
        elif [ -f "$GR_CONFIG" ]; then
            _deleted_found=$(cfg_get "$_deleted_key") || return 2
        else
            _deleted_found=""
        fi
        _deleted_ledgers="$_deleted_ledgers
$_deleted_found"
    done
    # The ledgers become git's pathspecs, one argument each, naming the files
    # check-trace reads (gr_doc_files): a directory's top-level *.md files,
    # where `*` under :(glob) does not cross a `/`, or the file itself. A
    # ledger's own glob characters are escaped, so its name is read as spelled.
    set --
    while IFS= read -r _deleted_ledger; do
        [ -n "$_deleted_ledger" ] || continue
        if [ -d "$_deleted_ledger" ]; then
            _deleted_glob=$(printf '%s\n' "${_deleted_ledger%/}" \
                | sed 's/[][*?\\]/\\&/g') || return 2
            set -- "$@" ":(glob)$_deleted_glob/*.md"
        else
            set -- "$@" ":(literal)$_deleted_ledger"
        fi
    done <<EOF
$_deleted_ledgers
EOF
    [ $# -gt 0 ] || return 0
    _deleted_diff=$(git diff --no-color --no-ext-diff \
        --no-textconv --unified=0 --no-renames "$_deleted_range" -- "$@") \
        || return 2
    # grep's 1 is no definition line, which deletes nothing.
    _deleted_lines=$(printf '%s\n' "$_deleted_diff" \
        | grep -E "$(gr_def_re "$_deleted_prefixes" '^[-+]')")
    [ $? -le 1 ] || return 2
    [ -n "$_deleted_lines" ] || return 0
    # Each line is `-**ID**:` or `+**ID**:`; the ID runs from the fourth
    # character to the next asterisk.
    printf '%s\n' "$_deleted_lines" | awk '
        { id = substr($0, 4); id = substr(id, 1, index(id, "*") - 1) }
        substr($0, 1, 1) == "+" { added[id] = 1; next }
        { removed[id] = 1 }
        END { for (id in removed) if (!(id in added)) print id }' || return 2
}

# gr_limit KEY — a triage limit from the config: a non-negative whole number,
# or EMPTY when the key is absent, meaning no limit on that dimension.
#
# Absent is a legitimate configuration and is never silent: check-trace.sh
# prints every limit, set or not, in its `problems:` summary line, so a team
# that has switched one off sees that fact at every merge.
#
# What is NOT legitimate is a limit the reader cannot parse. `thirty`, `-1`,
# `1.5` and a present-but-empty value would all read as "no limit" through
# cfg_get, which is a gate disabling itself on a typo — exit 2 instead.
gr_limit() {
    _lv=$(cfg_get "$1")
    if [ -z "$_lv" ]; then
        # PRESENT-BUT-EMPTY is not ABSENT; cfg_get cannot tell them apart.
        # Ask the file directly.
        if grep -q "^$1:" "$GR_CONFIG" 2>/dev/null; then
            gr_die \
"$1 is set to an empty value in $GR_CONFIG.
  Give it a whole number, or remove the key to apply no limit."
        fi
        return 0
    fi
    case "$_lv" in
        (*[!0-9]*) gr_die \
"$1 must be a non-negative whole number, not '$_lv' (in $GR_CONFIG).
  Remove the key to apply no limit; 0 means every item of that kind fails." ;;
    esac
    # Digits alone are not enough. A value past the shell's integer range makes
    # `[ "$n" -gt "$limit" ]` fail with "Illegal number", the `if` takes its
    # else branch, and the gate is off with the run still green — the exact
    # shape the paragraph above forbids, reached through the one path the
    # digit test lets past.
    #
    # Asked of the shell rather than guessed at as a digit width: whatever it
    # can compare HERE it can compare at the point of use, on any shell, with
    # no constant to be wrong about. A fixed nine-digit width would reject a value
    # such as 1000000000 with the untrue explanation that it was too large to
    # compare. awk is the other consumer (`agelim + 0`), where a value past
    # the exact-integer range would silently become a float.
    [ "$_lv" -ge 0 ] 2>/dev/null || gr_die \
"$1 is $_lv, which this shell cannot compare as a number (in $GR_CONFIG).
  Use a limit inside the shell's integer range, or remove the key to apply
  no limit."
    printf '%s\n' "$_lv"
}

# gr_check_flat FILE — the structural rules every flat guardrails file obeys:
# readable; no BOM; no bare-CR line endings; every line blank, a comment, a
# `  - item` belonging to a key, a document separator, or `identifier:` at
# column one; no key set twice. Prints the file's top-level keys, one per
# line. The config and the unit manifest are both checked by it, because two
# hand-copied structure gates drift apart and then read one file two ways.
gr_check_flat() {
    _ff="$1"
    [ -f "$_ff" ] || gr_die "file not found: $_ff"

    # A UTF-8 BOM makes the first key unreadable by every awk matcher here, so
    # it must be rejected explicitly — the alternative is a first key that
    # silently reads as absent. Detected in awk (octal escapes are POSIX)
    # rather than with `head -c`, which is not in POSIX head. LC_ALL=C so
    # substr counts bytes: in a UTF-8 locale awk counts characters and the
    # three BOM bytes are one of them.
    # ONE read gate, before any scan. Every scan below prints nothing when it
    # cannot open the file, so each would pass vacuously and the verdict would
    # come from an unrelated check further down naming a cause that is not the
    # cause — which is what a config with mode 000 produced.
    #
    # One gate rather than a status check on each: the checks after the first
    # would be unreachable, since the first scan already died, so they could not
    # be tested and a mutation removing any of them would not be detected by
    # the suite. Unkillable code is code nobody can show works.
    [ -r "$_ff" ] || gr_die \
"cannot read $_ff — it exists but this user cannot open it."

    # The BOM and a CLASSIC-MAC line ending are rejected together: both make
    # the file one thing to its author and another to every reader here. A
    # \r-only file is a SINGLE awk record, so the scans below accept it whole
    # and the verdict arrives from gr_prefixes naming the wrong cause. Every
    # record is inspected, not only the first: a file whose first line ends LF
    # and whose remainder is CR-separated passed a first-line-only check.
    # LC_ALL=C so substr counts bytes: in a UTF-8 locale the three BOM bytes
    # are one character.
    _first=$(LC_ALL=C awk '
        NR == 1 && substr($0, 1, 3) == "\357\273\277" { print "bom"; exit }
        index($0, "\r") > 0 && index($0, "\r") < length($0) { print "cr"; exit }
        ' "$_ff") || gr_die "cannot read $_ff"
    case "$_first" in
        (bom) gr_die "config begins with a UTF-8 BOM: $_ff — save it as plain UTF-8" ;;
        (cr)  gr_die \
"config has carriage returns inside a line: $_ff
  A file with \\r-only line endings is one single line to every reader here.
  Save it with LF or CRLF endings." ;;
    esac

    # Every line must be blank, a comment, a `  - item` list entry, a `---`
    # document separator, or exactly `<key>:` at column one. Matching only
    # /^[A-Za-z_]+:/ is not enough: that is the same shape cfg_get matches, so
    # a key invisible to the reader would be equally invisible to the check.
    #
    # `owner` tracks what the most recent column-one line was. An indented
    # `  - item` only belongs to a key; under a comment it is an orphan, and
    # an orphan is ambiguous in a way no reader can resolve safely — it either
    # vanishes with the rest of its list or is adopted by the block above,
    # which is how `- src` under a commented-out `strict_paths:` could become
    # a test path. Reject it rather than pick a side.
    _malformed=$(awk '
        { line = $0; sub(/\r$/, "", line) }
        # A separator ends a block in cfg_list too, so it must break the
        # ownership chain — otherwise an item after one is silently dropped.
        line ~ /^---[ \t]*$/ || line ~ /^\.\.\.[ \t]*$/ { owner = "separator"; next }
        line ~ /^[ \t]*$/ { next }
        line ~ /^[ \t]*#/ { if (line ~ /^#/) owner = "comment"; next }
        line ~ /^[ \t]+-[ \t]/ { if (owner != "key") print NR; next }
        line !~ /^[A-Za-z_][A-Za-z0-9_]*:/ { print NR; next }
        { owner = "key" }
    ' "$_ff")
    if [ -n "$_malformed" ]; then
        _msg=""
        for _n in $_malformed; do
            _msg="${_msg}
  line ${_n}: $(sed -n "${_n}p" "$_ff")"
        done
        gr_die "config line(s) that are neither a comment, a top-level key, nor a '  - item' belonging to one:${_msg}"
    fi

    # Read ONCE and reused by every check below. `for _k in $(awk …)` swallows
    # awk's status entirely, which is one of the ways the unreadable-config
    # case reached three scans deep without a word.
    # No CR strip here: `sub(/:.*/, "")` removes everything after the colon,
    # the carriage return with it, and the match is unanchored at the end. The
    # same idiom in the malformed-line scan above IS critical, because that
    # one judges the whole line. A copy of it here was dead code — measured
    # identical output with and without — and dead code is code nobody can show
    # works.
    _keys=$(awk '/^[A-Za-z_][A-Za-z0-9_]*:/ { sub(/:.*/, ""); print }' "$_ff")
    # DUPLICATES FIRST. Both readers take the first occurrence and stop, while
    # YAML itself takes the last, so a second block is read by nobody and the
    # file states one thing to its author and another to the tooling. The shape
    # that matters is a `verify_commands:` appended below the one already
    # there — which is what editing by appending produces: the project's real
    # suite never runs and the merge gate passes on the placeholder above it.
    #
    # Before the emptiness rule, because a key duplicated with an empty first
    # block otherwise arrives there and is reported twice under a diagnosis
    # that names neither the duplication nor the block nobody reads.
    _dup=$(printf '%s\n' "$_keys" | sort | uniq -d | tr '\n' ' ')
    [ -z "$_dup" ] || gr_die \
"config key(s) set more than once in $_ff: ${_dup}
  Every reader here takes the FIRST one and stops, while YAML takes the last,
  so one of the two is read by nobody. Keep one."

    printf '%s\n' "$_keys"
}

# gr_check_forms FILE LISTKEYS KEY... — the per-key form/emptiness rules: a
# LIST key (member of LISTKEYS) has items and no scalar value; every other key
# the reverse; no item blank, none itself a comment. Same extraction, same
# reason.
gr_check_forms() {
    _ff="$1"; _lk="$2"; shift 2
    # A KEY THAT ITS OWN CONSUMER CANNOT READ, in three directions: set to
    # nothing at all, set in the form the other kind of key uses, or containing
    # an item with nothing after its `-`.
    #
    # Every key is asked, so no key is a gate that a single `#` switches off,
    # and each is asked in the form its own consumer uses. Accepting a key
    # that EITHER reader finds would pass `strict_paths: src` (non-empty to
    # cfg_get, empty to cfg_list, and cfg_list is what reads it) through to a
    # merge that exits 0 having walked no paths.
    _empty=""
    _wrong=""
    _blank=""
    _commented=""
    for _k in "$@"; do
        if gr_contains "$_lk" "$_k"; then
            [ -z "$(cfg_get "$_k" "$_ff")" ] || _wrong="${_wrong} $_k"
            [ -n "$(cfg_list "$_k" "$_ff")" ] || _empty="${_empty} $_k"
            # An item with nothing after its `-` is dropped by every reader, so
            # the list that takes effect is shorter than the one written.
            #
            # An item that is ITSELF a comment is the neighbouring shape and
            # worse: `  - # make test` remains the literal string
            # `# make test`, because gr_clean's comment strip needs whitespace
            # before the `#` and the dash strip has already eaten it. The list
            # is not short, it contains a command the shell reads as a comment —
            # so the step runs nothing and reports that nothing failed. Caught
            # with `^#` and not `^[ \t]*#`: inside a grep bracket expression
            # `\t` is the set {space, backslash, t}, which would reject `t#x`.
            cfg_list "$_k" "$_ff" | grep -q '^$' && _blank="${_blank} $_k"
            cfg_list "$_k" "$_ff" | grep -q '^#' && _commented="${_commented} $_k"
        else
            [ -z "$(cfg_list "$_k" "$_ff")" ] || _wrong="${_wrong} $_k"
            [ -n "$(cfg_get "$_k" "$_ff")" ] || _empty="${_empty} $_k"
        fi
    done
    [ -z "$_commented" ] || gr_die \
"config key(s) with a commented-out item in $_ff:${_commented}
  A '  - # value' item is not a comment to the reader — the '#' is stripped from
  a value only when whitespace precedes it, and the dash strip has already
  removed that. It remains an item whose value begins with '#', which for a
  command key means the shell reads it as a comment: the step runs nothing and
  reports that nothing failed. Comment out the whole '  - ' line, or remove it."
    [ -z "$_blank" ] || gr_die \
"config key(s) with an item that has no value after its '-' in $_ff:${_blank}
  Every reader here drops it, so the list that takes effect is shorter than the
  one written. Give the item a value or delete the line."
    [ -z "$_wrong" ] || gr_die \
"config key(s) written in the wrong form in $_ff:${_wrong}
  A list key takes indented '  - item' lines and nothing after its colon; a
  scalar key takes a value after its colon and no items. Written the other way
  round a key is read by nobody, and the gate that wanted it passes having
  examined nothing.
  List keys: $(printf '%s' "$_lk" | tr '\n' ' ')"
    [ -z "$_empty" ] || gr_die \
"config key(s) set to nothing in $_ff:${_empty}
  Such a key reads as absent to the gate that uses it, and that gate then
  passes having examined nothing. GIVE IT A VALUE.
  Deleting the key is not the remedy: absent is the same gate-off as empty,
  and for the keys that contain a gate's whole scope — strict_paths,
  verify_commands, test_paths — deleting it is rejected separately."
}

# gr_check_config — reject a config that would silently disable a gate. Every
# rejection here is a shape the config READER cannot see, which is why none of
# them could ever be reported by the gate that was meant to use the value.
gr_check_config() {
    _keys=$(gr_check_flat "$GR_CONFIG") || exit 2

    _unknown=""
    for _config_key in $_keys; do
        # A withdrawn key fails with the reason and the remedy, not as an
        # unknown key with no hint.
        case $_config_key in
            (prune_plans) gr_die "config key prune_plans is withdrawn: a plan does not reach the base branch (drop-plans.sh, merge-change step 5). Delete its line." ;;
            (doc_verification) gr_die "config key doc_verification is withdrawn: the record is the squash message (merge-change step 5). Delete its line." ;;
        esac
        gr_contains "$GR_KNOWN_KEYS" "$_config_key" || _unknown="${_unknown} $_config_key"
    done
    [ -z "$_unknown" ] || gr_die "unknown config key(s):${_unknown}"

    # shellcheck disable=SC2086
    gr_check_forms "$GR_CONFIG" "$GR_LIST_KEYS" $_keys || exit 2

    # gr_prefixes dies in a subshell here, so the status must be propagated or
    # the loops below would iterate over nothing.
    _pfx=$(gr_prefixes) || exit 2

    _gated=""
    for _p in $_pfx; do
        gr_contains "$GR_GATED_PREFIXES" "$_p" && _gated=1
    done
    [ -n "$_gated" ] || gr_die \
"id_prefixes names no prefix with a traceability gate: $(printf '%s' "$_pfx" | tr '\n' ' ')
  At least one of REQ HAZ RC SDD LLR PR must appear. Others may be declared
  alongside them — they are covered by DANGLING-REF and DUPLICATE-ID, just not
  by a gate of their own. Without any of the six, the only checks left are
  those two, and a config that also omits the document keys would run nothing
  at all and still exit 0."

    # TWO rules, deliberately separate, because they answer different
    # questions and one of them changed when the placement gate was merged.
    #
    # Rule 1 — gate inputs: documents whose absence would SILENTLY SKIP one of
    # this prefix's gates. Not always the document the prefix is defined in:
    # UNIMPLEMENTED-CONTROL looks for a REQ that implements each RC, so RC
    # needs doc_srs.
    #
    # This is deliberately NOT the full set of documents every gate reads.
    # UNANALYZED-DERIVED also reads doc_rmf, and the transitive half of
    # MISSING-TEST also reads doc_sad, but both FAIL RED without their input
    # rather than passing vacuously — so requiring those keys would forbid
    # legitimate shapes, such as a class A project with no architecture
    # document. The rule is "no gate is ever silently skipped", not "every gate
    # has every input", and this comment must keep stating it: the map is not
    # the complete set of gate inputs, and reading it as one is wrong.
    for _p in $_pfx; do
        case "$_p" in
            (REQ) _need="doc_srs" ;;
            (HAZ) _need="doc_rmf" ;;
            (RC)  _need="doc_srs" ;;
            (SDD) _need="doc_sad" ;;
            (LLR) _need="doc_sad" ;;
            (PR)  _need="doc_problems" ;;
            (*)   continue ;;
        esac
        for _k in $_need; do
            [ -n "$(cfg_get "$_k")" ] || \
                gr_die "id_prefixes declares $_p but $_k is not configured — a gate for $_p reads it, so that gate could never run"
        done
    done

    # Rule 2 — definition documents: the one document MISPLACED-ITEM requires
    # each item of this prefix to be defined in. Unconfigured, that gate is not
    # skipped — it condemns every item of the prefix, correctly but once per
    # item, naming a key the project never set. State it once instead.
    #
    # Only RC differs from rule 1: a risk control is defined in the RMF, while
    # the gate that reads controls reads the SRS. Every other entry is already
    # required above, so this rule rejects exactly one new shape: RC declared
    # with no doc_rmf, which configures a project where no control can ever be
    # correctly placed.
    for _p in $_pfx; do
        case "$_p" in
            (REQ)    _home="doc_srs" ;;
            (HAZ|RC) _home="doc_rmf" ;;
            (SDD|LLR) _home="doc_sad" ;;
            (PR)     _home="doc_problems" ;;
            (*)      continue ;;
        esac
        [ -n "$(cfg_get "$_home")" ] || \
            gr_die "id_prefixes declares $_p but $_home is not configured — that is the only document a $_p may be defined in, so every $_p would be misplaced"
    done

    # ABSENT IS THE SAME GATE-OFF AS EMPTY: without this rule, removing the key
    # would turn the emptiness check's rejection into the exit-0 no-scan state
    # it rejects.
    #
    # `strict_paths` is the whole of DANGLING-REF's source-code scope. With no
    # entries, a reference to an ID nobody defined goes from exit 1 to exit 0
    # with `strict 0` in the summary. A project with nothing to scan does not
    # exist: point it at whatever should be under traceability, as the ledger
    # directories are on a documentation-first project.
    [ -n "$(cfg_list strict_paths)" ] || gr_die \
"strict_paths names no path in $GR_CONFIG.
  It is the entire scope of the source scan: with none, a reference to an ID
  nobody defined is never looked for and the run exits 0 having examined no
  code. Name at least one path — on a documentation-first project that is the
  ledger directories."
    # `verify_commands` has the same defect one level up — absent, the merge
    # gate runs no commands and reports that nothing failed — and is NOT
    # required here, deliberately. Nothing in this validator reads it; the script
    # that runs those commands is what should reject running none of them, and
    # requiring it from a validator that never uses it would be a rule with no
    # reader behind it.

    if gr_contains "$_pfx" REQ || gr_contains "$_pfx" LLR; then
        [ -n "$(cfg_list test_paths)" ] || \
            gr_die "id_prefixes declares REQ/LLR but test_paths is empty — nothing would be searched for 'verifies:'"
    fi
}

# --- The unit manifest -------------------------------------------------------
#
# .guardrails/units.yaml declares a multi-unit repository. Its PRESENCE is the
# whole engagement rule: absent, every script below runs exactly the code it
# used before the manifest existed, and the test obligation
# no-manifest-changes-nothing enforces that.
GR_UNITS='.guardrails/units.yaml'

# Both manifest keys are LIST keys; there are no scalars here.
GR_UNITS_KEYS='units
not_a_unit'

# Present means the exact BYTE-NAME is in the directory listing, not merely
# that `-f` succeeds: on a case-insensitive filesystem (macOS APFS by default)
# `-f .guardrails/units.yaml` is also satisfied by UNITS.YAML — a manifest
# that officially does not exist (check-units.sh rejects the near-miss name at
# exit 2), and the same tree would engage here and not on case-sensitive CI.
# One definition for every scoped script, so no two of them can disagree about
# whether the repository is multi-unit.
gr_units_present() {
    [ -f "$GR_UNITS" ] || return 1
    ls .guardrails 2>/dev/null | grep -qxF units.yaml
}

# The manifest's two lists, one entry per line. Readers of the same parser the
# config uses — see cfg_get's file argument.
gr_unit_list()       { cfg_list units "$GR_UNITS"; }
gr_disclaimed_list() { cfg_list not_a_unit "$GR_UNITS"; }

# gr_check_units — reject a manifest that would mis-scope a gate. Everything
# here is exit 2, the environment-error class: a manifest defect is a wrong
# SCOPE for every scan in the repository, which is worse than any finding.
#
# Entries are validated to contain no whitespace and no glob characters
# before any loop interpolates them into a case pattern or a pathspec, so the
# iteration below is safe under any IFS the caller set (the lists are
# newline-separated; a whitespace entry would otherwise read as two).
gr_check_units() {
    [ -f "$GR_UNITS" ] || gr_die "manifest not found: $GR_UNITS"
    _ukeys=$(gr_check_flat "$GR_UNITS") || exit 2
    _unknown=""
    for _k in $_ukeys; do
        gr_contains "$GR_UNITS_KEYS" "$_k" || _unknown="${_unknown} $_k"
    done
    [ -z "$_unknown" ] || gr_die \
"unknown manifest key(s) in $GR_UNITS:${_unknown}
  The manifest takes units: and not_a_unit: only; everything else a unit
  needs lives in that unit's own .guardrails/config.yaml."
    gr_contains "$_ukeys" units || gr_die \
"manifest has no units: list: $GR_UNITS — a manifest that declares no unit
  scopes nothing. Declare at least one, or delete the file to stay single-unit."
    # shellcheck disable=SC2086
    gr_check_forms "$GR_UNITS" "$GR_UNITS_KEYS" $_ukeys || exit 2

    # Exclusivity: two authorities over one tree is the one shape every
    # reader would have to GUESS its way out of.
    [ ! -e .guardrails/config.yaml ] || gr_die \
"root .guardrails/config.yaml alongside $GR_UNITS — two authorities over the
  same tree; every scan would have to guess which one scopes it. A multi-unit
  repository keeps its configs inside the units. Remove one of the two."

    _units=$(gr_unit_list)
    _all=$(printf '%s\n%s\n' "$_units" "$(gr_disclaimed_list)" | grep -v '^$')

    _saved_ifs=${IFS-__gr_unset__}
    IFS='
'
    case $- in (*f*) _un_f=1 ;; (*) _un_f=0 ;; esac
    set -f

    _dupe=$(printf '%s\n' "$_all" | sort | uniq -d | tr '\n' ' ')
    [ -z "$_dupe" ] || gr_die "path listed more than once in $GR_UNITS: ${_dupe}"

    for _e in $_all; do
        case "$_e" in
            (*" "* | *"	"*) gr_die "manifest entry contains whitespace: '$_e' — it would read as two entries to any space-separated consumer" ;;
            (*[\*\?\[]*)     gr_die "manifest entry contains a glob character: $_e — entries are literal directory paths, never patterns, so a unit is declared, never discovered by convention" ;;
            (*/)             gr_die "manifest entry has a trailing slash: $_e" ;;
            (.)              gr_die "manifest entry names the repository root: . — the root cannot be a unit" ;;
            (/*)             gr_die "manifest entry is absolute: $_e — entries are repository-relative" ;;
            (./*)            gr_die "manifest entry is not plain-relative: $_e — drop the ./" ;;
            (..|../*|*/..|*/../*) gr_die "manifest entry reaches outside the repository: $_e" ;;
        esac
    done

    # Overlap, every direction. The architecture names the unit-nesting cases;
    # the reason it gives — one file, two scopes, two verdicts — condemns a
    # disclaimed path inside a unit and a redundant nested disclaim equally,
    # so all four directions are rejected with one rule.
    for _a in $_all; do
        for _b in $_all; do
            [ "$_a" = "$_b" ] && continue
            case "$_b" in ("$_a"/*) gr_die \
"manifest entries overlap: $_b is inside $_a — one file would have two scopes,
  and every scoped gate two verdicts. Claim or disclaim each subtree once." ;;
            esac
        done
    done

    for _u in $_units; do
        [ -d "$_u" ] || gr_die "units: entry is not an existing directory: $_u"
        _ucfg="$_u/.guardrails/config.yaml"
        [ -f "$_ucfg" ] || gr_die \
"units: entry has no .guardrails/config.yaml: $_u
  A unit is a directory guardrails already governs. Run /ratchet in it, or
  disclaim it under not_a_unit: until it is ratcheted."
        # The unit's config passes the SAME validator a single-unit repository
        # runs. In a subshell so GR_CONFIG here is untouched; the subshell's
        # own message has already named the defect when this dies.
        ( GR_CONFIG="$_ucfg"; gr_check_config ) || gr_die \
"unit config failed validation: $_ucfg (see above)"

        # Own scope must BE the unit: two units' scans
        # are disjoint by construction, or MISPLACED-ITEM sees a sibling's
        # items and the scoped summary lies.
        for _dk in doc_srs doc_rmf doc_sad doc_soup doc_problems; do
            _dv=$(cfg_get "$_dk" "$_ucfg")
            [ -n "$_dv" ] || continue
            case "$_dv" in ("$_u"/*) ;; (*) gr_die \
"unit $_u: $_dk resolves outside the unit: $_dv — a unit's documents live in
  its own subtree, or two units' scans stop being disjoint." ;;
            esac
        done
        for _pk in strict_paths test_paths; do
            for _pv in $(cfg_list "$_pk" "$_ucfg"); do
                case "$_pv" in ("$_u"/*) ;; (*) gr_die \
"unit $_u: $_pk entry outside the unit: $_pv" ;;
                esac
            done
        done

        for _d in $(cfg_list depends_on "$_ucfg"); do
            [ "$_d" != "$_u" ] || gr_die "unit $_u depends on itself"
            gr_contains "$_units" "$_d" || gr_die \
"unit $_u: depends_on names an undeclared unit: $_d
  Declare it in $GR_UNITS, or remove the edge."
        done
    done

    # Cycles: peel units whose dependencies are all peeled; a remainder is a
    # cycle. A worklist over flat lists — POSIX sh.
    _left="$_units"
    _progress=1
    while [ -n "$_left" ] && [ "$_progress" -eq 1 ]; do
        _progress=0
        _next=""
        for _u in $_left; do
            _blocked=0
            for _d in $(cfg_list depends_on "$_u/.guardrails/config.yaml"); do
                gr_contains "$_left" "$_d" && { _blocked=1; break; }
            done
            if [ "$_blocked" -eq 0 ]; then _progress=1
            else _next="${_next}${_u}
"
            fi
        done
        _left=$(printf '%s' "$_next")
    done
    [ -z "$_left" ] || gr_die \
"dependency cycle among units: $(printf '%s' "$_left" | tr '\n' ' ')
  Cyclic units are not partially independent at all — every gate built on the
  edge direction would read ambiguously."

    [ "$_un_f" -eq 1 ] || set +f
    if [ "$_saved_ifs" = "__gr_unset__" ]; then unset IFS; else IFS=$_saved_ifs; fi
    return 0
}

# A disclaimed entry is deliberately NOT required to exist: a mistyped disclaim
# leaves the real directory unclaimed, which UNCLAIMED-PATH reports loudly —
# the failure is toward conviction, so no rule is needed here.

# gr_unit_engage — the engagement rule. Sets GR_UNIT to
# the running unit's path, or to "" in a single-unit repository. Every
# unit-scoped script calls this immediately after cd'ing to the root and
# BEFORE gr_check_config: engaged, the config named by GR_CONFIG is the
# unit's own, already validated once by gr_check_units — validating it again
# through the ordinary gr_check_config call that follows costs one pass and
# buys the same message a single-unit project gets.
gr_unit_engage() {
    GR_UNIT=""
    gr_units_present || return 0
    gr_check_units
    case "$GR_CONFIG" in
        (.guardrails/config.yaml) gr_die \
"this is a multi-unit repository ($GR_UNITS) — there is no root config to read.
  Run check-units.sh for the repository-level gates, or set GR_CONFIG to a
  unit's .guardrails/config.yaml for that unit's run." ;;
    esac
    for _c in $(gr_unit_list); do
        if [ "$GR_CONFIG" = "$_c/.guardrails/config.yaml" ]; then
            GR_UNIT="$_c"
            return 0
        fi
    done
    gr_die \
"GR_CONFIG is not a declared unit's config: $GR_CONFIG
  Scoping an undeclared config would invent a unit the manifest never granted.
  Declared units: $(gr_unit_list | tr '\n' ' ')"
}

# gr_req_scan FILE... — the item-annotation reader. One
# line per fact, tab-separated: <id> <file> KIND <value>, where KIND is
#   DEF      the block exists (value -)
#   EXP      exported: (raw value — the consumer judges it)
#   EXPECTS  expects:  (raw value)
#   OPENED   opened:   (raw value)
#   SAT      one line per satisfies: REQ entry (value the REQ id)
# `implements:` is not read here: check-trace.sh's credit_scan is its one
# reader, so the expectation severity and UNIMPLEMENTED-CONTROL agree.
# Column one only, first occurrence per keyword per block — the same rules
# the PR status reader follows, so ORPHAN-ANNOTATION sees what this sees.
# satisfies: starts where gr_annotation says, as at every block reader of it.
# Blocks open on every gated prefix, so exported: on an LLR is ATTRIBUTED and
# convicted (MISEXPORTED-ITEM), never dropped.
gr_req_scan() {
    for _f in "$@"; do
        LC_ALL=C awk -v body="$GR_ID_BODY" -v fname="$_f" \
            "$GR_AWK_ID_RUN$GR_AWK_ITEM_BLOCK"'
            BEGIN { gr_block_init("REQ|HAZ|RC|SDD|LLR|PR", body) }
            FNR == 1 { sub(/^\357\273\277/, "") }
            { line = $0; sub(/\r$/, "", line) }
            gr_block_closes(line) {
                cur = gr_block_opens(line) ? gr_block_id(line) : ""
                exp_seen = 0; expc_seen = 0; opd_seen = 0
                if (cur != "") printf "%s\t%s\tDEF\t-\n", cur, fname
            }
            cur == "" { next }
            !exp_seen && gr_kw_here(line, "exported:") {
                exp_seen = 1
                printf "%s\t%s\tEXP\t%s\n", cur, fname, gr_value(line, "exported:")
            }
            !expc_seen && gr_kw_here(line, "expects:") {
                expc_seen = 1
                printf "%s\t%s\tEXPECTS\t%s\n", cur, fname, gr_value(line, "expects:")
            }
            !opd_seen && gr_kw_here(line, "opened:") {
                opd_seen = 1
                printf "%s\t%s\tOPENED\t%s\n", cur, fname, gr_value(line, "opened:")
            }
            {
                run = gr_id_run(gr_annotation(line, "satisfies:"), "satisfies:")
                n = split(run, a, " ")
                for (i = 1; i <= n; i++)
                    if (a[i] ~ /^REQ-/) printf "%s\t%s\tSAT\t%s\n", cur, fname, a[i]
            }
        ' "$_f" || gr_die "unit annotation scan failed on $_f"
    done
    return 0
}

# gr_unit_srs UNIT — the unit's doc_srs files, one per line. The same
# emptiness rules gr_doc_files applies, with the unit named in the error.
gr_unit_srs() {
    _unit_doc_srs=$(cfg_get doc_srs "$1/.guardrails/config.yaml")
    [ -n "$_unit_doc_srs" ] || return 0
    if [ -d "$_unit_doc_srs" ]; then
        gr_md_files "$_unit_doc_srs" "doc_srs of unit $1 is configured as directory"
    elif [ -f "$_unit_doc_srs" ]; then
        printf '%s\n' "$_unit_doc_srs"
    else
        gr_die "unit $1: doc_srs is configured as '$_unit_doc_srs', which does not exist"
    fi
    return 0
}

# gr_unit_req_scan UNIT — gr_req_scan over the unit's SRS. Call in a command
# substitution with `|| exit 2` like every other lib helper that can die.
gr_unit_req_scan() {
    _rs_list=$(gr_unit_srs "$1") || exit 2
    _saved_ifs=${IFS-__gr_unset__}
    IFS='
'
    case $- in (*f*) _rs_f=1 ;; (*) _rs_f=0 ;; esac
    set -f
    # shellcheck disable=SC2086
    gr_req_scan $_rs_list
    _rs_st=$?
    [ "$_rs_f" -eq 1 ] || set +f
    if [ "$_saved_ifs" = "__gr_unset__" ]; then unset IFS; else IFS=$_saved_ifs; fi
    return $_rs_st
}

# gr_exported_reqs UNIT — "REQ-id<TAB>file" for every exported REQ of UNIT.
# THE definition of the export surface: check-units.sh --exports prints it and
# the consumer's resolver reads it, so the report and the gate are one
# computation (obligation exports-mode-matches-resolution).
gr_exported_reqs() {
    _ex_scan=$(gr_unit_req_scan "$1") || exit 2
    printf '%s\n' "$_ex_scan" | awk -F'\t' \
        '$3 == "EXP" && $4 == "yes" && $1 ~ /^REQ-/ { print $1 "\t" $2 }' | sort -u
}

# gr_consumers_of UNIT — declared units whose depends_on names UNIT.
gr_consumers_of() {
    for _cu in $(gr_unit_list); do
        [ "$_cu" = "$1" ] && continue
        gr_contains "$(cfg_list depends_on "$_cu/.guardrails/config.yaml")" "$1" \
            && printf '%s\n' "$_cu"
    done
    return 0
}

# gr_unit_of_path PATH — the unit claiming PATH ("apps/pump"), or
# "not_a_unit <entry>" for a disclaimed one; status 1 for a path nobody
# claims. Whole path components: docs claims docs/adr/x.md and
# never docs-site/.
gr_unit_of_path() {
    for _pu in $(gr_unit_list); do
        case "$1" in ("$_pu" | "$_pu"/*) printf '%s\n' "$_pu"; return 0 ;; esac
    done
    for _pd in $(gr_disclaimed_list); do
        case "$1" in ("$_pd" | "$_pd"/*) printf 'not_a_unit %s\n' "$_pd"; return 0 ;; esac
    done
    return 1
}

# gr_id_run KEYWORD — filter: for each stdin line, print the IDs of the list
# that immediately follows KEYWORD, one per line. See GR_AWK_ID_RUN above for
# the rule; this is the shell-pipeline face of the same single definition.
gr_id_run() {
    awk -v kw="$1" "$GR_AWK_ID_RUN"'
        {
            r = gr_id_run($0, kw)
            if (r == "") next
            n = split(r, a, " ")
            for (i = 1; i <= n; i++) print a[i]
        }'
}
