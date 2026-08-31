#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# guardrails shared helpers — POSIX sh, sourced by the check/finalize scripts.
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
verify_commands
coverage_command'

GR_KNOWN_KEYS='guardrails_version
safety_class
id_prefixes
doc_srs
doc_rmf
doc_sad
doc_soup
doc_problems
doc_verification
strict_paths
test_paths
verify_commands
coverage_command
problem_age_days
problem_open_max'

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
# characters, so REQ-a3k9z2x is not a longer ID — it is not an ID at all — and
# a scan without this boundary reads its first six characters and credits
# REQ-a3k9z2 for a reference nobody wrote. Sequential IDs never had that
# problem: [0-9]{3,} is greedy, so REQ-0012 harvested whole and showed up as
# the dangling reference it was.
#
# Deliberately wider than the body alphabet — `i`, `l`, `o` and the uppercase
# letters cannot appear in a token, but a reference carrying one is still a
# typo rather than a boundary, and reading it as a boundary would credit the
# item it truncates to.
GR_ID_TAIL='[^0-9A-Za-z]'

# The annotation-list rule as an awk function, defined ONCE and prepended to
# every awk program that needs it. gr_id_run(line, kw) returns the space-
# separated IDs of the list immediately following the FIRST occurrence of kw on
# line; the run ends at the first character that is not an ID, comma or space,
# so `verifies: REQ-001 (was REQ-042)` yields REQ-001 alone — prose after the
# list is commentary, never coverage.
#
# One definition is the point. Three near-copies of this rule is how `traces:`
# came to demand a REQ at the head of its run while `satisfies:` scanned from
# the LAST occurrence on the line and credited a REQ mentioned in prose.
#
# GR_ID_BODY is interpolated once, here, when the library is sourced — this
# constant carries a copy of the body from then on rather than reading the
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
        # discarded every ID after it in the list: `verifies: REQ-a3k9z2x,
        # REQ-b4m8p3` credited neither, and MISSING-TEST then named the
        # correctly spelled item too, pointing the reader at the wrong line.
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
# collects, and CLOSES at a markdown heading or at ANY BOLD LINE CARRYING A
# COLON. That is the whole closing rule.
#
# It is stated as a SUBTRACTION, and that framing is the point. Until
# 2026-08-22 the rule closed on every line starting `**`. An emphasised
# sentence inside an item body (`**21 of 35 inverted, 14 not.**`) therefore
# ended the item there, and everything after it — annotations included —
# belonged to no item: UNTRACED-DESIGN and UNSATISFIED-LLR then rejected
# correct documents, while UNANALYZED-DERIVED and UNRESOLVED-PR passed over
# real violations in silence. One rule, four gates, both failure directions.
#
# The close set must therefore be everything that rule closed, MINUS the shape
# that caused the defect, and nothing else. The defect line carries no colon;
# so the colon is the subtraction, and there is no other. Three review rounds
# were spent narrowing instead — to definition forms, then to header shapes,
# then to a colon adjoining the closing asterisks — and each narrowing lost
# lines the old rule closed, which is a regression however small the loss. A
# line a reader takes for a header but the rule does not becomes body text, and
# its annotations are credited to the item ABOVE it: a resolved PR inherits the
# next one`s `status: open`. That is a wrong answer, where the original defect
# gave a missing one.
#
# BYTE-WISE, not a regex, and this is not stylistic. `.` in an ERE does not
# match an invalid byte sequence under gawk in a multibyte locale, so
# `^\*\*.*:` silently stopped closing on a ledger saved in latin-1 — a header
# like `**Détail**:` — while mawk, busybox awk and gawk under LC_ALL=C all
# closed it. The same tree, the same script, two verdicts, decided by the
# operator`s locale. substr and index count bytes in every awk and every
# locale, and they say what the sentence above says.
#
# The residual limit, stated exactly: a bold line carrying no ASCII colon does
# not close. `**Decision 7**` does not; `**Decision 7**:` does. A full-width
# colon (U+FF1A) is not an ASCII colon and does not close. Nothing
# distinguishes a colon-free bold line from the sentence in the original
# report, so that one is irreducible.
#
# One definition, for the same reason GR_AWK_ID_RUN and gr_def_re have one, and
# with one addition: ORPHAN-ANNOTATION is a fifth reader of this rule, and a
# backstop that disagrees with the gates it backs is not a backstop.
#
# gr_block_init takes the OPENING prefix alternation (the prefixes this gate
# collects) and GR_ID_BODY. There is no closing alternation: the close is keyed
# on no vocabulary at all, which is what makes it total. The opening pattern is
# assembled HERE, inside awk, and never handed in ready-made with -v: awk runs
# escape processing over a -v value, so a pattern carrying \* arrives as a bare
# * and matches nothing at all — a gate that counts zero items and still exits
# 0. Measured on gawk 5.3.2. Both arguments carry no backslashes of their own,
# which is what lets them cross the -v boundary safely.
GR_AWK_ITEM_BLOCK='
function gr_block_init(pfx_open, body) {
    GR_BLOCK_OPEN_RE = "^\\*\\*(" pfx_open ")-" body "\\*\\*:"
}
# Does this line START a block this gate collects? The STRICT form: an item
# whose ID cannot be read is not an item, and nothing may be collected under it.
function gr_block_opens(line) { return (line ~ GR_BLOCK_OPEN_RE) }
# Does this line END whatever block is open? Any bold line carrying a colon,
# and any markdown heading. See the block comment above for why this is
# substr/index rather than a regex, and why the colon is the only subtraction
# from the pre-2026-08-22 rule.
function gr_block_closes(line) {
    if (substr(line, 1, 1) == "#") return 1
    return (substr(line, 1, 2) == "**" && index(line, ":") > 0)
}
# Is KW the annotation this line carries? Column one, and only column one.
#
# A KNOWN ASYMMETRY, now HALF closed. The rule is that a reader must not take
# a value from a position this backstop cannot see, because then an annotation
# belonging to no item is read, matched and dropped in silence.
#
#   * `status:`, `opened:` — CLOSED, 2026-08-25. The problem-report
#     reader in check-trace.sh goes through this function, so reader and
#     backstop look in the same place, and a `- status: open` bullet is
#     reported INCOMPLETE-PROBLEM rather than passing silently.
#   * `traces:` and `satisfies:` — STILL OPEN. They are read by gr_id_run,
#     which finds its keyword ANYWHERE on the line, so `- satisfies: REQ-001`
#     counts inside a block while the same line outside every block is not
#     reported here at all: exit 0 with a derived item never checked against
#     the RMF. The block rule above makes it rare, not impossible. Closing it
#     changes what every SAD and SRS ledger already written may look like,
#     which is why it is stated rather than folded in. See
#     skills/check-traceability/SKILL.md.
#
# Extending this to list markers was tried and reverted: it fired on
# `- status: resolved only in the same change that merges the fix.` in the
# shipped templates/problems.md, which is prose in a README. Rewording a correct
# document to satisfy a scan is the failure mode this whole change exists to
# remove, so the narrower rule stays and the gap is stated. Unanchored is worse
# again — it fires on any sentence containing the word. Column one is also what
# keeps the indented grammar comments in the ledger templates inert.
#
# The route out, if this is revisited: the templates already tell authors to
# keep illustrative forms inline in backticks, and applying that convention to
# the one offending line would close the hole. That is a change to the
# templates and to every ledger already written against them, which is why it
# is not folded in here.
function gr_kw_here(line, kw) {
    return (index(line, kw) == 1)
}
# The value of an annotation: everything after the keyword, trimmed. A keyword
# with nothing after it declares nothing, and every reader here treats it as
# absent — an empty `opened:` is an omission wearing the shape of compliance.
#
# Meaningful only where gr_kw_here holds, which is why both live here: a reader
# that takes a value from a keyword the ORPHAN-ANNOTATION backstop cannot see
# reopens the hole that backstop was built to close. That is not hypothetical
# — it is exactly how the PR `status:` reader drifted (see check-trace.sh).
function gr_value(line, kw,   v) {
    v = substr(line, length(kw) + 1)
    sub(/^[ \t]+/, "", v)
    sub(/[ \t]+$/, "", v)
    return v
}
# The bare ID of a definition line. Meaningful only where gr_block_opens holds.
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
# A BOM sits in front of column one and hides it from every match here, the
# `---` delimiter included, so the caller strips it in BOTH passes.
GR_AWK_FRONT_MATTER='
function gr_fm_reset() { GR_FM_IN = 0; GR_FM_END = 0 }
function gr_fm_scan(line, n) {
    # Line 2 decides. A `---` at line 1 opens front matter only if a KEY
    # follows it immediately; `---` then a blank line is a horizontal rule at
    # the top of a document, and treating one as a header switched the scan off
    # for everything up to the next rule. The independent review of 2026-08-25
    # reproduced that on the problem-report reader — an open item 236 days old
    # absent from the roll-call at exit 0 — and this is the same defect in the
    # backstop, where it silently drops every annotation in the span instead.
    # YAML has no blank line between the opening delimiter and the first key,
    # so nothing legitimate is lost, and the rule can only make the scan read
    # MORE than before: no report that used to fire stops firing.
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
# BYTE-WISE, deliberately. The obvious shape test is a regex, and the previous
# change measured what that costs: under gawk in a multibyte locale a bracket
# expression does not match an invalid byte sequence, so a latin-1 value made
# the check fail OPEN. substr and index count bytes in every locale.
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
# `sh -c 'echo "#done"'` survive. It cannot be escaped: a value whose own
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
# is pronounced valid — the validator whose purpose is to refuse a config that
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
# and the form rule below then reads a list key as a scalar and refuses the
# config from every gate. The rule this file states is that a trailing
# ` # comment` is stripped for EVERY key; this is what makes that true of a key
# whose value is otherwise empty.
#
# No gr_line here, deliberately: a CR in a CRLF file is always at end of record,
# so it cannot reach the key match at column one, and gr_clean already strips it
# off the value. cfg_list needs it because a blank CRLF line is a record
# consisting of the CR alone, and that record is judged as structure.
cfg_get() {
    [ -f "$GR_CONFIG" ] || gr_die "config not found: $GR_CONFIG"
    awk -v k="$1" "$GR_AWK_CLEAN_VALUE"'
        index($0, k ":") == 1 {
            sub(/^[^:]*:/, "")
            v = gr_clean($0)
            sub(/^[ \t]+/, "", v)
            print v
            exit
        }
    ' "$GR_CONFIG"
}

# cfg_list KEY — print items of a top-level `key:` block of `  - item` lines.
cfg_list() {
    [ -f "$GR_CONFIG" ] || gr_die "config not found: $GR_CONFIG"
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
    ' "$GR_CONFIG"
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
    # thing in a repository whose root happens to hold a matching name and
    # another everywhere else — the same config, two verdicts, decided by an
    # unrelated directory listing.
    case $- in *f*) _pfx_refl=1 ;; *) _pfx_refl=0 ;; esac
    set -f
    _out=""
    for _one in $_v; do
        case "$_one" in
            [!A-Za-z]* | *[!A-Za-z0-9]*)
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
# installed scripts do not report themselves — their comments carry a literal
# `REQ-DRAFT-b-1` and definition-form examples — and the scripts are the only
# thing under `.guardrails/` that matches any gate's pattern; config.yaml
# matches none. Excluding the whole directory also hid the project's own files:
# with `doc_srs: .guardrails/docs/requirements`, the finalize step renamed the
# draft ledger to its merge-date name, minted nothing, and exited 0, and both
# check scripts then passed a tree with a live `REQ-DRAFT-x-1` in it.
# Narrowing cannot reach one case: a doc_* configured INSIDE this directory is
# still accepted, and checked: counts its items as zero. Whether any gate
# complains first depends on whether git tracks or ignores the ledger, and on
# whether the ledger has been renamed out of its DRAFT- name — the same is true
# of .git/, gitignored paths and symlinks leaving the repository. The measured
# matrix is in docs/verification/2026-08-20-scan-pathspec.md. A check that refused the shape
# outright was attempted and cut; see the same record.
#
# A variable, not a function like gr_def_re: this is a separate `git grep`
# argument, and a function's output would have to be word-split — which
# check-trace.sh cannot do, setting IFS to newline at top level. Assigned unconditionally, never `${GR_SCAN_EXCLUDE:-…}`: a value
# inherited from the environment could widen it to `:(exclude).` and blind
# every gate in the toolkit while each one still exited 0.
GR_SCAN_EXCLUDE=':(exclude).guardrails/scripts'

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
# `git diff` output, where a definition sits at line start behind a + or -, and
# the empty string to match the token anywhere on a line. Do NOT express that
# last case as '^.+': git's matcher backtracks on a leading .+ and costs tens
# of seconds per prefix on a few hundred documents, against tenths of a second
# for the unanchored form. The verification record carries the measurement and
# the corpus commit it was taken on; a bare number here could not be re-derived
# and drifted into three different values.
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
# header-shaped ones, and that distinction is the whole of the 2026-08-23
# amendment: `**ADR-0007**:` is a header this pattern does not match.
#
# ONE consumer: the MALFORMED-ID scan in check-ids.sh, which spelled the
# pattern out by hand until 2026-08-23. There such a line is a document defect
# — the item it announces is invisible to every gate — and it is reported at
# exit 1.
#
# check-trace.sh does NOT use it, though two earlier designs did. A pre-flight
# refusing such trees outright was written and cut, and the block rule closes
# on a header SHAPE, which is broader and keyed on no vocabulary. Kept as a
# constructor rather than folded back inline because MALFORMED-ID is the
# complement of gr_def_re over one anchor, and the two belong next to each
# other where that is visible.
gr_def_re_loose() {
    printf '%s' "${2-^}\\*\\*(${1})-[^*]*\\*\\*:"
}

# gr_base_branch — the branch checked out in the primary (non-worktree)
# checkout, which is what a change merges into. Prints nothing if the
# primary checkout is detached; never falls back to a linked worktree's
# branch.
gr_base_branch() {
    git worktree list --porcelain 2>/dev/null | awk '
        /^worktree / { n++ }
        n > 1 { exit }
        sub(/^branch refs\/heads\//, "") { print; exit }
    '
}

# gr_doc_files KEY — resolve a doc_* config value to a file list, one per
# line. A directory yields its *.md files (sorted); a file yields itself; a
# missing KEY yields nothing (the project does not use that document).
#
# Two cases are ERRORS, not empty lists: a key configured to a path that does
# not exist, and a directory holding no *.md at all. Silently yielding nothing
# there turns whole gate families into no-ops that still exit 0.
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
# directory holding none is an ERROR, never an empty list, for the reason
# gr_doc_files gives: a gate reading nothing is indistinguishable from a gate
# finding nothing wrong. LABEL names the caller in that error.
#
# Extracted so that gr_doc_files and gr_verification_dir cannot drift. They
# could not share gr_doc_files itself — that one is keyed on a config key and
# yields nothing for an unset one, which is exactly the shape the verification
# directory must not have — so the EMPTINESS RULE is what is shared instead.
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

# gr_verification_dir — the directory holding verification records.
#
# The ONE doc_* key with a default, and the exception needs its reason stated.
# ratchet creates docs/verification/ on every project it sets up, and this key
# arrived long after those projects were configured; requiring it would fail
# every config already written, at a gate whose whole purpose is to be adopted.
#
# The default cannot produce a false green, and that is the only reason it is
# allowed. A project that keeps its records somewhere else leaves
# docs/verification/ absent, and an absent directory is fatal here — never an
# empty file list. The distinction is the same one gr_doc_files draws, for the
# same reason: a gate reading nothing is indistinguishable from a gate finding
# nothing wrong.
gr_verification_dir() {
    _v=$(cfg_get doc_verification)
    # PRESENT-BUT-EMPTY is not ABSENT. cfg_get cannot tell them apart, and the
    # default below would silently adopt a key whose value the reader could not
    # see — the one shape gr_check_config exists to reject, arriving through the
    # one key with a fallback. Ask the file directly.
    if [ -z "$_v" ] && grep -q '^doc_verification:' "$GR_CONFIG" 2>/dev/null; then
        gr_die \
"doc_verification is set to an empty value in $GR_CONFIG.
  Give it the directory that holds the verification records, or remove the key
  to use the default (docs/verification)."
    fi
    [ -n "$_v" ] || _v=docs/verification
    [ -d "$_v" ] || gr_die \
"doc_verification resolves to '$_v', which is not a directory.
  Verification records live there. Create it, or set doc_verification in
  $GR_CONFIG to the directory that holds them."
    printf '%s\n' "$_v"
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
        # Same reasoning, and the same remedy, as gr_verification_dir.
        if grep -q "^$1:" "$GR_CONFIG" 2>/dev/null; then
            gr_die \
"$1 is set to an empty value in $GR_CONFIG.
  Give it a whole number, or remove the key to apply no limit."
        fi
        return 0
    fi
    case "$_lv" in
        *[!0-9]*) gr_die \
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
    # no constant to be wrong about. The first version fixed nine digits, which
    # refused 1000000000 with the untrue explanation that it was too large to
    # compare. awk is the other consumer (`agelim + 0`), where a value past
    # the exact-integer range would silently become a float.
    [ "$_lv" -ge 0 ] 2>/dev/null || gr_die \
"$1 is $_lv, which this shell cannot compare as a number (in $GR_CONFIG).
  Use a limit inside the shell's integer range, or remove the key to apply
  no limit."
    printf '%s\n' "$_lv"
}

# gr_check_config — refuse a config that would silently disable a gate. Every
# rejection here is a shape the config READER cannot see, which is why none of
# them could ever be reported by the gate that was meant to use the value.
gr_check_config() {
    [ -f "$GR_CONFIG" ] || gr_die "config not found: $GR_CONFIG"

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
    # be tested and a mutation removing any of them would survive the suite.
    # Unkillable code is code nobody can show works.
    [ -r "$GR_CONFIG" ] || gr_die \
"cannot read $GR_CONFIG — it exists but this user cannot open it."

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
        ' "$GR_CONFIG") || gr_die "cannot read $GR_CONFIG"
    case "$_first" in
        bom) gr_die "config begins with a UTF-8 BOM: $GR_CONFIG — save it as plain UTF-8" ;;
        cr)  gr_die \
"config has carriage returns inside a line: $GR_CONFIG
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
    ' "$GR_CONFIG")
    if [ -n "$_malformed" ]; then
        _msg=""
        for _n in $_malformed; do
            _msg="${_msg}
  line ${_n}: $(sed -n "${_n}p" "$GR_CONFIG")"
        done
        gr_die "config line(s) that are neither a comment, a top-level key, nor a '  - item' belonging to one:${_msg}"
    fi

    # Read ONCE and reused by every check below. `for _k in $(awk …)` swallows
    # awk's status entirely, which is one of the ways the unreadable-config
    # case reached three scans deep without a word.
    # No CR strip here: `sub(/:.*/, "")` removes everything after the colon,
    # the carriage return with it, and the match is unanchored at the end. The
    # same idiom in the malformed-line scan above IS load-bearing, because that
    # one judges the whole line. A copy of it here was dead code — measured
    # identical output with and without — and dead code is code nobody can show
    # works.
    _keys=$(awk '/^[A-Za-z_][A-Za-z0-9_]*:/ { sub(/:.*/, ""); print }' "$GR_CONFIG")

    _unknown=""
    for _k in $_keys; do
        gr_contains "$GR_KNOWN_KEYS" "$_k" || _unknown="${_unknown} $_k"
    done
    [ -z "$_unknown" ] || gr_die "unknown config key(s):${_unknown}"

    # DUPLICATES FIRST. Both readers take the first occurrence and stop, while
    # YAML itself takes the last, so a second block is read by nobody and the
    # file says one thing to its author and another to the tooling. The shape
    # that matters is a `verify_commands:` appended below the one already
    # there — which is what editing by appending produces: the project's real
    # suite never runs and the merge gate passes on the placeholder above it.
    #
    # Before the emptiness rule, because a key duplicated with an empty first
    # block otherwise arrives there and is reported twice under a diagnosis
    # that names neither the duplication nor the block nobody reads.
    _dup=$(printf '%s\n' "$_keys" | sort | uniq -d | tr '\n' ' ')
    [ -z "$_dup" ] || gr_die \
"config key(s) set more than once in $GR_CONFIG: ${_dup}
  Every reader here takes the FIRST one and stops, while YAML takes the last,
  so one of the two is read by nobody. Keep one."

    # A KEY THAT ITS OWN CONSUMER CANNOT READ, in three directions: set to
    # nothing at all, set in the form the other kind of key uses, or carrying
    # an item with nothing after its `-`.
    #
    # The rule had been arriving one key at a time — gr_verification_dir for
    # doc_verification, gr_limit for the problem limits — while every key it
    # had not reached was a gate that a single `#` could switch off. Asking the
    # question generally is not enough on its own either: a first version
    # accepted a key if EITHER reader found something, which passed
    # `strict_paths: src` (non-empty to cfg_get, empty to cfg_list, and
    # cfg_list is what reads it) straight through to a merge that exited 0
    # having walked no paths. The question has to be asked in the form that
    # key's own consumer uses.
    _empty=""
    _wrong=""
    _blank=""
    _commented=""
    for _k in $_keys; do
        if gr_contains "$GR_LIST_KEYS" "$_k"; then
            [ -z "$(cfg_get "$_k")" ] || _wrong="${_wrong} $_k"
            [ -n "$(cfg_list "$_k")" ] || _empty="${_empty} $_k"
            # An item with nothing after its `-` is dropped by every reader, so
            # the list that takes effect is shorter than the one written.
            #
            # An item that is ITSELF a comment is the neighbouring shape and
            # worse: `  - # make test` survives as the literal string
            # `# make test`, because gr_clean's comment strip needs whitespace
            # before the `#` and the dash strip has already eaten it. The list
            # is not short, it carries a command the shell reads as a comment —
            # so the step runs nothing and reports that nothing failed. Caught
            # with `^#` and not `^[ \t]*#`: inside a grep bracket expression
            # `\t` is the set {space, backslash, t}, which would refuse `t#x`.
            cfg_list "$_k" | grep -q '^$' && _blank="${_blank} $_k"
            cfg_list "$_k" | grep -q '^#' && _commented="${_commented} $_k"
        else
            [ -z "$(cfg_list "$_k")" ] || _wrong="${_wrong} $_k"
            [ -n "$(cfg_get "$_k")" ] || _empty="${_empty} $_k"
        fi
    done
    [ -z "$_commented" ] || gr_die \
"config key(s) with a commented-out item in $GR_CONFIG:${_commented}
  A '  - # value' item is not a comment to the reader — the '#' is stripped from
  a value only when whitespace precedes it, and the dash strip has already
  removed that. It survives as an item whose value begins with '#', which for a
  command key means the shell reads it as a comment: the step runs nothing and
  reports that nothing failed. Comment out the whole '  - ' line, or remove it."
    [ -z "$_blank" ] || gr_die \
"config key(s) with an item that has no value after its '-' in $GR_CONFIG:${_blank}
  Every reader here drops it, so the list that takes effect is shorter than the
  one written. Give the item a value or delete the line."
    [ -z "$_wrong" ] || gr_die \
"config key(s) written in the wrong form in $GR_CONFIG:${_wrong}
  A list key takes indented '  - item' lines and nothing after its colon; a
  scalar key takes a value after its colon and no items. Written the other way
  round a key is read by nobody, and the gate that wanted it passes having
  examined nothing.
  List keys: $(printf '%s' "$GR_LIST_KEYS" | tr '\n' ' ')"
    [ -z "$_empty" ] || gr_die \
"config key(s) set to nothing in $GR_CONFIG:${_empty}
  Such a key reads as absent to the gate that uses it, and that gate then
  passes having examined nothing. GIVE IT A VALUE.
  Deleting the key is not the remedy: absent is the same gate-off as empty,
  and for the keys that carry a gate's whole scope — strict_paths,
  verify_commands, test_paths — deleting it is refused separately."

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
    # questions and one of them changed when the placement gate landed.
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
    # has every input", and this comment must keep saying so: an earlier draft
    # claimed the map was complete and a reviewer proved it was not.
    for _p in $_pfx; do
        case "$_p" in
            REQ) _need="doc_srs" ;;
            HAZ) _need="doc_rmf" ;;
            RC)  _need="doc_srs" ;;
            SDD) _need="doc_sad" ;;
            LLR) _need="doc_sad" ;;
            PR)  _need="doc_problems" ;;
            *)   continue ;;
        esac
        for _k in $_need; do
            [ -n "$(cfg_get "$_k")" ] || \
                gr_die "id_prefixes declares $_p but $_k is not configured — a gate for $_p reads it, so that gate could never run"
        done
    done

    # Rule 2 — definition documents: the one document MISPLACED-ITEM requires
    # each item of this prefix to be defined in. Unconfigured, that gate is not
    # skipped — it condemns every item of the prefix, correctly but once per
    # item, naming a key the project never set. Say it once instead.
    #
    # Only RC differs from rule 1: a risk control is defined in the RMF, while
    # the gate that reads controls reads the SRS. Every other entry is already
    # required above, so this rule rejects exactly one new shape: RC declared
    # with no doc_rmf, which configures a project where no control can ever be
    # correctly placed. Change B's map had RC needing doc_srs and NOT doc_rmf,
    # with the reason that no RC gate read doc_rmf — true until this gate
    # existed, and recorded here so the reversal reads as the premise change it
    # is rather than an oscillation.
    for _p in $_pfx; do
        case "$_p" in
            REQ)    _home="doc_srs" ;;
            HAZ|RC) _home="doc_rmf" ;;
            SDD|LLR) _home="doc_sad" ;;
            PR)     _home="doc_problems" ;;
            *)      continue ;;
        esac
        [ -n "$(cfg_get "$_home")" ] || \
            gr_die "id_prefixes declares $_p but $_home is not configured — that is the only document a $_p may be defined in, so every $_p would be misplaced"
    done

    # ABSENT IS THE SAME GATE-OFF AS EMPTY, and until this rule the emptiness
    # check above actually RECOMMENDED it: "remove the key and its items
    # entirely" turned a refusal into the exit-0 no-scan state it was refusing.
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
    # required here, deliberately. Nothing in this change reads it; the script
    # that runs those commands is what should refuse to run none of them, and
    # requiring it from a validator that never uses it would be a rule with no
    # reader behind it. Recorded rather than fixed in passing.

    if gr_contains "$_pfx" REQ || gr_contains "$_pfx" LLR; then
        [ -n "$(cfg_list test_paths)" ] || \
            gr_die "id_prefixes declares REQ/LLR but test_paths is empty — nothing would be searched for 'verifies:'"
    fi
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
