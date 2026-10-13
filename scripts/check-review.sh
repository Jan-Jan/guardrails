#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# check-review.sh [--cite] [--branch NAME]
#
# The review artefact gate. Independent review (merge-change step 6a) is the
# highest-yield step in the sequence and was the only one with nothing behind
# it: no check that a reviewer was dispatched, that findings were answered, or
# that the record states anything at all. Reported by a class B project running
# sixty-nine verification records entirely on the honour system.
#
# Fails (exit 1) on:
#   MISSING-RECORD BRANCH — no record in doc_verification declares this change.
#   INCOMPLETE-RECORD FILE (no KEYWORD:) — the record for this change omits a
#                            required field, or contains it with no value. An
#                            empty `reproduced:` is an omission wearing the
#                            shape of compliance and is reported as one.
#   UNDISPOSED-FINDING FILE:LINE ID — a finding block in this change's record
#                            with no `disposition:` in it. "A verdict per
#                            finding": the failure reported was a fix to a
#                            previous round's finding being half-applied.
#   MALFORMED-FINDING FILE:LINE — a line SHAPED like a finding header whose
#                            label cannot be read: a missing colon, a missing
#                            hyphen, an unreadable body, an indented header.
#                            Such a line opens no block, so the finding is
#                            invisible and its disposition is credited to
#                            whatever block happens to be open.
#   ORPHAN-DISPOSITION FILE:LINE — a `disposition:` at column one, or at
#                            column one after one or more list markers,
#                            belonging to no finding block. The backstop for
#                            every shape of detached finding the rule above
#                            cannot name, and the same mechanism check-trace.sh
#                            calls ORPHAN-ANNOTATION — including its width:
#                            this is one of exactly two places that take the
#                            WIDE predicate, gr_kw_orphan_here, and it is wider
#                            than every reader in this file on purpose. See the
#                            note at the rule itself, and the invariant in
#                            lib.sh.
#   STALE-RECORD FILE — a record declaring this branch that this change did not
#                            write or touch. A reused branch name would
#                            otherwise let the previous change's record answer
#                            for this one.
#   UNRESOLVABLE-DISPOSITION FILE:LINE — with citation checking on, a credited
#                            disposition that cites no path in the tree, no
#                            test name in test_paths and no defined item ID,
#                            and does not read `no change — <reason>`. LINE is
#                            the `disposition:` line. A disposition that names
#                            nothing a reader can open is a claim of repair
#                            nobody can check (D12, docs/plans/
#                            2026-10-06-salvage-churn-and-parallel.md).
#
# Citation checking is opt-in: `--cite` for one run, `review_cite: on` in the
# config for every run, because an adopter cannot edit the shipped step 6c
# command. `off` or absent leaves every output as it was. It is refused under
# a unit manifest: the record is repository-level while test paths and ID
# ledgers belong to units, and resolving across them is a design of its own.
# A disposition's text runs from its line to the first blank line, block close,
# next credited disposition or end of file. A citation is a token or a backtick
# span naming a regular file, not a symlink, that git lists as tracked or as
# untracked and not ignored (a markdown link is read as its target, and
# punctuation, a `#anchor`, a possessive, a git `<rev>:` prefix and one `:N`
# or `:N-M` are stripped), other than the record being checked unless the
# finding is a `record` finding; a backtick or double-quoted span that a file
# matched by a test_paths pathspec declares as a test's name; or an ID
# find-items.sh show finds.
#
# This gate judges PRESENCE, NEVER QUALITY. It cannot know whether a review was
# good, or whether a reviewer was independent of the author — with agent
# reviewers the identity string is whatever the author types, and a gate keyed
# on it would be theatre. It knows whether a review is claimed, by whom, with
# what conclusion, and whether every finding it raised was answered.
#
# The record is found by content, not by file name. It is the record whose
# FIRST `branch:` line names this change, matched whole. It must also be one
# this change wrote: committed on this branch since it left the base, modified
# in the working tree, or not yet tracked. `--branch` skips that provenance
# check, and the summary line says so. The value of `reproduced:` is never
# judged. Only the record for the change under merge is checked, so records
# written before this schema existed are left alone. doc_verification is the
# one doc_* key with a default, docs/verification; an absent directory is
# exit 2, never an empty scan (gr_verification_dir in lib.sh).
#
# Every run ends with `checked:` (records read, records for this change,
# findings, and whether provenance was checked). Run on the base branch, or
# with --branch naming it, it exits 2, never 0: the base is not a change.
#
# Exit codes: 0 pass, 1 violations, 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
# Taken before the cd below: $0 may be relative to the caller's directory, and
# citation checking runs find-items.sh from beside this script.
review_script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || exit 2
# NOT `cd "$(gr_root)" || exit 2`: gr_root's gr_die exits only the command
# substitution, and under dash `cd ""` returns 0 and stays put — so outside a
# git repository the script continued in the caller's directory with a
# relative config path. The status has to be taken from the substitution.
gr_repo_root=$(gr_root) || exit 2
cd "$gr_repo_root" || exit 2

# The review artefact is REPOSITORY-LEVEL (architecture item 9): one change,
# one signed squash, one record, whatever units the change touched. In a
# manifest repository there is no root config to validate — the manifest's
# exclusivity rule removed it — so the manifest itself is validated in its
# place, and the records live at the defaulted root location. Everything
# branch-shaped below is untouched.
if gr_units_present; then
    gr_check_units
    dir=docs/verification
    [ -d "$dir" ] || gr_die \
"docs/verification does not exist — in a multi-unit repository the
  verification records live at the repository root (one record per change;
  the record's subject is the change, not a unit). Create the directory."
else
    gr_check_config
    dir=$(gr_verification_dir) || exit 2
fi

branch=""
named=0
cite_flag=0
while [ $# -gt 0 ]; do
    case "$1" in
        (--branch)
            shift
            [ $# -gt 0 ] || gr_die "--branch needs a branch name"
            branch="$1"
            named=1 ;;
        (--cite) cite_flag=1 ;;
        (*) gr_die "unknown argument: $1" ;;
    esac
    shift
done

# Is citation checking on? The flag turns it on for one run and the key for
# every run. The key is read the way prune-plans.sh reads prune_plans: cfg_get
# cannot tell an absent key from an empty one, so the file is asked first.
cite_on=0
if gr_units_present; then
    [ "$cite_flag" -eq 0 ] || gr_die \
"--cite is refused in multi-unit repositories: the review record is
  repository-level, while test paths and ID ledgers belong to units, so a
  citation has no one tree to resolve against."
else
    cite_setting=off
    if grep -q '^review_cite:' "$GR_CONFIG"; then
        cite_setting=$(cfg_get review_cite) || exit 2
    fi
    case "$cite_setting" in
        (on) cite_on=1 ;;
        (off) ;;
        (*) gr_die "review_cite in $GR_CONFIG is '$cite_setting'; it takes on or off." ;;
    esac
    [ "$cite_flag" -eq 0 ] || cite_on=1
fi

# What a citation resolves against, read only when citations are checked, so
# that a run without them reads exactly what it read before. gr_check_config,
# above, has already required id_prefixes; with no test_paths no span is a
# test name.
cite_id_re=""
cite_test_paths=""
if [ "$cite_on" -eq 1 ]; then
    cite_prefix_re=$(gr_prefix_re) || exit 2
    cite_id_re="^(${cite_prefix_re})-${GR_ID_BODY}\$"
    if grep -q '^test_paths:' "$GR_CONFIG"; then
        cite_test_paths=$(cfg_list test_paths) || exit 2
    fi
fi

# Which change is under review? The branch, and it must be a change branch.
#
# Running this where there is NO change under merge would ask no question and
# report a pass — a green tick on a check that was never made, which is the
# false green this toolkit exists to remove. So the two undecidable cases are
# errors: a detached HEAD names no branch, and a HEAD equal to the base branch
# is not a change. Both are recoverable with --branch, which relaxes exactly
# one thing: WHICH change is asked about. The record must still exist.
#
# In a single checkout gr_base_branch reports whatever is checked out, so every
# branch there is its own base and --branch is the only way in. That is not a
# defect: this gate runs at merge-change step 6c, from the change's worktree.
# The base branch is needed either way: to reject the base as the subject
# (below), and to decide which records this change wrote (further down).
base=$(gr_base_branch) || gr_die \
"git worktree list failed, so the base branch cannot be read."

if [ "$named" -eq 1 ]; then
    # --branch relaxes WHICH change is asked about. It does not relax the
    # question itself: naming the base branch asks about a change that is not
    # in flight, and D6 applies to it unchanged.
    [ -z "$base" ] || [ "$branch" != "$base" ] || gr_die \
"--branch names the base branch ($base), which is not a change under review.
  Name the change branch, or run this from its worktree."
else
    branch=$(git branch --show-current 2>/dev/null)
    [ -n "$branch" ] || gr_die \
"HEAD is detached, so no change branch can be identified.
  Check out the change branch, or name it with --branch NAME."
    [ -n "$base" ] || gr_die \
"the base branch cannot be determined (the primary checkout is detached).
  Name the change with --branch NAME."
    [ "$branch" != "$base" ] || gr_die \
"HEAD is the base branch ($base), so there is no change under review here.
  This gate runs in the change's worktree, at merge-change step 6c. To check a
  record for a change that is already merged, name it with --branch NAME."
fi

# A directory with no records at all is an environment error, never an empty
# scan, and that rule has ONE definition — gr_md_files, which gr_doc_files uses
# for every other document key. A hand-copy here is how two readers of one rule
# start to disagree.
records=$(gr_md_files "$dir" \
"no verification records in — merge-change step 6b writes one per change, and
  without any this gate would pass over an empty directory and report that the
  review happened. Directory:") || exit 2
_n=$(printf '%s' "$records" | grep -c . || true)

# Split on newlines alone: a record path may contain a space.
IFS='
'

# Pathname expansion OFF from here on, the same rule check-trace.sh follows at
# its scan sites. The record list above was BUILT by a glob and is complete; a
# record whose name contains a `*` or a `?` must not be expanded a second time
# against the working directory when the loop below splits the list.
set -f

# GR_RECORD_SCAN — read one record and print what it declares, one fact per
# line, for the shell to judge:
#
#   B <value>   the record's OWN branch claim (the first `branch:` only)
#   F <keyword>  a required field with a value
#   N            one finding block, disposed or not (the denominator)
#   U <line> <id>  a finding block with no disposition
#   M <line>     a line shaped like a finding header that opens no block
#   O <line>     a `disposition:` belonging to no finding block
#
# and, only when cite_on is 1, for each credited disposition:
#
#   D <line> <tag>  the disposition, by its `disposition:` line, and the
#                first word of its finding header after `**finding-N**:`
#   X            it is the `no change — <reason>` escape
#   C <token>    a token shaped like a path or an item ID
#   S <span>     a backtick or double-quoted span, a candidate test name
#
# Front matter is skipped, in two bounded passes, because a `branch:` key in a
# YAML header is a title-page field and not a claim about the change. That rule
# has one definition in lib.sh and check-trace.sh reads the same one.
GR_RECORD_SCAN="$GR_AWK_ITEM_BLOCK$GR_AWK_FRONT_MATTER"'
# Close the open finding block: count it, and report it if nothing disposed of
# it. open_line is an FNR, never an NR — the file is read TWICE for the
# front-matter bound, so NR is offset by the whole first pass and every line
# reported would name one that does not exist.
#
# An INVARIANT this function relies on, recorded because a reviewer proved no
# test can see it: `disposed` is cleared only where a block OPENS, and never
# here. That is what makes the `open_line &&` guard on the disposition rule
# below unable to change any verdict today (mutation M15, differentially fuzzed
# over 8000 generated records with zero differences). Let a block open by any
# other route and the guard becomes critical with no test to notice.
function gr_flush() {
    print "N"
    if (!disposed) printf "U %d %s\n", open_line, open_id
    open_line = 0
}
# Is this line SHAPED like a finding header? Deliberately much broader than the
# opener, and BYTE-WISE.
#
# Broader, because every near-miss is a finding that vanishes: `**finding-2**`
# with the colon forgotten neither opens a block nor closes one, so the next
# `disposition:` is credited to the finding ABOVE it and both findings then
# read as answered. `**finding 2**:` and an indented `**finding-2**:` lose the
# finding the same way. Naming the shape is what turns each of them from a
# silent loss into a reported one.
#
# Byte-wise, and this is not stylistic: the first version asked a regex with a
# negated bracket expression, and under gawk in a multibyte locale that does
# not match an invalid byte sequence — so a latin-1 label made the check fail
# OPEN, at exit 0, decided by whichever locale the operator has. substr and
# index count
# bytes in every awk and every locale. It is the same reasoning, and the same
# defect, that made gr_block_closes byte-wise in lib.sh.
#
# The tail test is what keeps an ordinary header out: `**findings**: three` is
# a heading, not a mislabelled finding, so a letter or digit after `finding`
# ends the match. Same rule as GR_ID_TAIL.
function gr_finding_shaped(line,   s, t) {
    s = line
    sub(/^[ \t]+/, "", s)
    if (substr(s, 1, 9) != "**finding") return 0
    t = substr(s, 10, 1)
    return (t !~ /[0-9A-Za-z]/)
}
# The text of a disposition, judged once it ends. Byte-wise, for the reason
# given at gr_finding_shaped: substr and index, no negated bracket expression, and the
# em dash of the escape spelled as its UTF-8 bytes.
#
# The escape needs no test that a reason follows the dash: gr_value trims the
# space after a bare `no change —`, and a line of spaces is blank and ends the
# text unappended, so a text opening with the escape and its space always has
# a non-space after them.
function gr_cite_flush(   text, escape, count, parts, i, token) {
    cite_open = 0
    printf "D %d %s\n", cite_line, cite_tag
    text = cite_text
    escape = "no change \342\200\224 "
    if (substr(text, 1, length(escape)) == escape) { print "X"; return }
    count = split(text, parts, /[ \t]+/)
    for (i = 1; i <= count; i++) {
        token = gr_cite_strip(parts[i])
        if (token == "") continue
        if (gr_cite_path_shaped(token) || (cite_id_re != "" && token ~ cite_id_re))
            print "C " token
    }
    gr_cite_spans(text, "`")
    gr_cite_spans(text, "\"")
}
# Each span between paired QUOTE characters is a candidate test name: the
# backtick form and the double-quoted prose form both cite one. A backtick span
# is a path candidate too, stripped whole, so a path with a space in it can be
# cited. Quotes pair left to right, as CommonMark pairs backticks, so a span
# here is a span on the rendered page; an unpaired last quote opens nothing.
function gr_cite_spans(text, quote,   rest, open_at, close_at, span, path) {
    rest = text
    while ((open_at = index(rest, quote)) > 0) {
        rest = substr(rest, open_at + 1)
        close_at = index(rest, quote)
        if (close_at == 0) break
        span = substr(rest, 1, close_at - 1)
        if (span != "") print "S " span
        if (quote == "`") {
            path = gr_cite_strip(span)
            if (path != "" && gr_cite_path_shaped(path)) print "C " path
        }
        rest = substr(rest, close_at + 1)
    }
}
function gr_cite_strip_end(token) {
    while (token != "" && index("`\"\047)]>.,;:!?", substr(token, length(token), 1)) > 0)
        token = substr(token, 1, length(token) - 1)
    return token
}
# A markdown link keeps only its target, the text after `](`. Then quotes and
# brackets off both ends, then a `#anchor` suffix off a path candidate, then
# one possessive apostrophe-s (the straight apostrophe or the right single
# quote, U+2019) and the end set again, then a git `<rev>:` prefix of 7 to 40
# lowercase hex digits, then one `:N` or `:N-M`, then the end set once more.
# `scripts/x.sh:12`., `[the guard](scripts/x.sh#L3-L9)`, a backticked
# scripts/x.sh with a possessive after it, and `650f090:scripts/x.sh` all read
# as scripts/x.sh. No apostrophe in this comment: it sits in single quotes.
function gr_cite_strip(token,   position, length_now, rev) {
    position = index(token, "](")
    if (position > 0) token = substr(token, position + 2)
    while (token != "" && index("`\"\047([<", substr(token, 1, 1)) > 0)
        token = substr(token, 2)
    token = gr_cite_strip_end(token)
    position = index(token, "#")
    if (position > 0 && gr_cite_path_shaped(substr(token, 1, position - 1)))
        token = gr_cite_strip_end(substr(token, 1, position - 1))
    length_now = length(token)
    if (length_now > 2 && substr(token, length_now - 1) == "\047s")
        token = gr_cite_strip_end(substr(token, 1, length_now - 2))
    else if (length_now > 4 && substr(token, length_now - 3) == "\342\200\231s")
        token = gr_cite_strip_end(substr(token, 1, length_now - 4))
    position = index(token, ":")
    if (position >= 8 && position <= 41) {
        rev = substr(token, 1, position - 1)
        if (rev ~ /^[0-9a-f]+$/) token = substr(token, position + 1)
    }
    for (position = length(token); position > 0; position--)
        if (substr(token, position, 1) == ":") break
    if (position > 0 && substr(token, position + 1) ~ /^[0-9]+(-[0-9]+)?$/)
        token = substr(token, 1, position - 1)
    return gr_cite_strip_end(token)
}
# The first word after a finding header label, byte-wise: `record` for a
# record finding, `code,`, `requirement,` or `guideline,` for the others.
function gr_finding_tag(line,   rest, at) {
    rest = substr(line, index(line, "**:") + 3)
    sub(/^[ \t]+/, "", rest)
    at = match(rest, /[ \t]/)
    return at ? substr(rest, 1, at - 1) : rest
}
# A token holding a `/` or a `.` may name a file. Whether it does is decided in
# the shell, against the files git lists, so an absolute path, a `..` path, a
# URL and anything under `.git` resolve nothing without a test here.
function gr_cite_path_shaped(token) {
    return index(token, "/") > 0 || index(token, ".") > 0
}
BEGIN { gr_block_init("finding", "[0-9]+"); gr_fm_reset() }
FNR == 1 { sub(/^\357\273\277/, "") }
FNR == NR { gr_fm_scan($0, FNR); next }
gr_fm_skip(FNR) { next }
{ line = $0; sub(/\r$/, "", line) }
# The text of the open disposition ends at a blank line, at a line that
# closes the block, and at the next credited disposition, which is judged on its own.
cite_open && (line ~ /^[ \t]*$/ || gr_block_closes(line) || \
    (gr_kw_here(line, "disposition:") && gr_value(line, "disposition:") != "")) {
    gr_cite_flush()
}
cite_open { cite_text = cite_text " " line }
# The tag of the finding a credited disposition answers, read where it opens.
cite_on && gr_block_opens(line) { open_tag = gr_finding_tag(line) }
# A finding is an item block in the ledger shape this toolkit uses everywhere,
# so where one starts and ends is decided by the shared rule and by nothing
# local. A bold line containing a colon, or a heading, ends it — which is why
# `disposition:` is a plain annotation and not a bold field: bold, it would
# close the very block it belongs to. The READER for it is column one and
# nothing else; the backstop below it is wider, and the rule there states how.
gr_block_closes(line) {
    if (open_line) gr_flush()
    if (gr_block_opens(line)) {
        open_line = FNR; open_id = gr_block_id(line); disposed = 0
        next
    }
    open_line = 0
}
# Shaped like a finding header, but opening no block. Checked on EVERY line,
# not only inside the closes rule, because the shapes that lose a finding
# include ones that close nothing: a header with no colon, and an indented one.
!gr_block_opens(line) && gr_finding_shaped(line) {
    printf "M %d\n", FNR
}
# TWO rules in one pattern, and they are deliberately not the same width. The
# backstop test selects the line — gr_kw_orphan_here, which also admits one or
# more leading list markers, bulleted or ordered — and the READER inside it is
# gr_kw_here, column one and nothing else. lib.sh states the invariant at
# gr_kw_here: the backstop must see at least what every reader sees, never
# exactly what it sees.
#
# Splitting them is not fastidiousness. A single wide test would make a
# bulleted `- disposition: …` quoted in a finding the disposition OF that
# finding, and the same widening on `branch:` below turned a record for
# other-change into the record for my-change — a pass reported over a review
# that never happened. Narrow here, a bulleted disposition inside a block
# disposes of nothing and the finding stays UNDISPOSED, which is loud and
# correct; wide there, one outside every block is still reported.
#
# The value test goes through gr_kw_lead so it reads the same position the
# selecting test did: gr_value alone slices from byte one and would hand a
# bulleted line a fragment of the keyword, never an empty string, so an empty
# bulleted `- disposition:` would slip past the emptiness guard.
gr_kw_orphan_here(line, "disposition:") {
    if (gr_value(gr_kw_lead(line), "disposition:") == "") next
    if (open_line) { if (gr_kw_here(line, "disposition:")) disposed = 1 }
    # Outside every block, this is an orphan: read, matched, and — until this
    # backstop — dropped in silence. It is where the finding went. The same
    # mechanism check-trace.sh calls ORPHAN-ANNOTATION, for the same reason.
    else printf "O %d\n", FNR
}
# A credited disposition, the one rule above credits, opens a text to judge.
cite_on && gr_kw_here(line, "disposition:") && open_line {
    cite_open = 1; cite_line = FNR; cite_text = gr_value(line, "disposition:")
    cite_tag = open_tag
}
{
    # Default FS, which splits on runs of space, tab and newline alike. The
    # shell hands this list space-separated; see GR_RECORD_KWS for why.
    n = split(kws, K)
    for (i = 1; i <= n; i++) {
        if (!gr_kw_here(line, K[i])) continue
        if (gr_value(line, K[i]) == "") continue
        print "F " K[i]
        # A record claims ONE branch: the FIRST `branch:` it contains, and no
        # other. Every later one is quotation — an example, a fenced extract of
        # another record, a schema pasted into a review finding — and a record
        # that quotes `branch: other-change` must not become the record FOR
        # other-change, which would report a pass over a review that never
        # happened. The same rule GR_AWK_ID_RUN applies to every annotation:
        # the first occurrence of the keyword is the claim.
        if (K[i] == "branch:" && !claimed) {
            claimed = 1
            print "B " gr_value(line, K[i])
        }
    }
}
END { if (cite_open) gr_cite_flush() }
END { if (open_line) gr_flush() }
'

# GR_RECORD_FIELDS — the fields the record must contain, checked once it has been
# found. `branch:` is deliberately NOT among them: it is the SELECTOR, and a
# record that declares no branch is not this change's record at all, which is
# reported as MISSING-RECORD rather than as an incomplete one.
#
# Each of the three catches a failure that was observed, not imagined:
# `reviewer:` a review never dispatched, `verdict:` a review that concluded
# nothing (a review finding nothing must still say so, or silence is
# indistinguishable from absence), `reproduced:` doubt disclosed only when the
# author chose to write a paragraph about it.
# Newline-separated, because everything below runs with IFS set to newline so
# that a record path may contain a space.
GR_RECORD_FIELDS='reviewer:
verdict:
reproduced:'

# The same list, flattened to spaces, for the one consumer that cannot take a
# newline. Computed once: scan_record runs per record. GR_RECORD_FIELDS itself
# must STAY newline-separated — IFS is a newline for this whole script, so the
# `for _kw in $GR_RECORD_FIELDS` loop below would otherwise split a
# space-separated value into ONE word and look for a field named
# `reviewer: verdict: reproduced:`, which no record contains, reporting
# INCOMPLETE-RECORD against every record in the repository.
GR_RECORD_KWS=$(printf '%s' "branch: $GR_RECORD_FIELDS" | tr '\n' ' ')

scan_record() {
    # GR_RECORD_KWS, never GR_RECORD_FIELDS: macOS's awk (BWK, "awk version
    # 20200816" — the one that ships with the OS, and the only awk on a stock
    # box) rejects a LITERAL newline inside a -v assignment: `awk: newline in
    # string ... at source line 1`, exit 2, before the program runs. gawk,
    # mawk and busybox awk all accept it, and every measurement recorded in
    # this toolkit's comments was taken on one of those three — which is how
    # this reached a release, and why the symptom was exit 2 rather than a
    # wrong answer: the gate did not run at all.
    #
    # `kws` is read only by `split(kws, K)` under the default FS, so the
    # flattened list is the same list to awk.
    LC_ALL=C awk -v kws="$GR_RECORD_KWS" -v cite_on="$cite_on" \
        -v cite_id_re="$cite_id_re" "$GR_RECORD_SCAN" "$1" "$1" \
        || gr_die "record scan failed on $1"
}

# cite_resolves TOKEN-FACT — does one C or S fact name something real? A C
# token without `/` or `.` is an ID, since the scan emits no other kind; an ID
# is resolved by find-items.sh show, whose exit 2 is this gate's exit 2.
cite_resolves() {
    case "$1" in
        ("C "*/*|"C "*.*) cite_names_file "${1#C }" ;;
        ("C "*)
            cite_find_error=$(sh "$review_script_dir/find-items.sh" show "${1#C }" 2>&1 >/dev/null)
            case $? in
                (0) return 0 ;;
                (1) return 1 ;;
            esac
            printf '%s\n' "$cite_find_error" >&2
            gr_die "find-items.sh show ${1#C } failed" ;;
        ("S "*) cite_names_test "${1#S }" ;;
        (*) return 1 ;;
    esac
}

# cite_names_file PATH — is PATH a file of this tree? Every leading `./` is
# dropped, with any slashes repeated after it, so `.//.git/HEAD` is read as
# `.git/HEAD`; a path that starts with `/` stays absolute. A slash doubled
# inside a path is kept, so `http://x.sh` never names `http:/x.sh`. It
# resolves only as a regular file that is not a symlink, which a directory, a
# symlink out of the repository and a deleted file are not, and that git lists
# as tracked or as untracked and not ignored. The record is often untracked at
# step 6c; a gitignored file, an absolute path, a `..` path and anything under
# `.git` are never listed. The listing is read once per run, the first time it
# is needed. The record being checked is a citation for a `record` finding
# alone: a `code`, `requirement` or `guideline` finding that cites only the
# record that answers it cites nothing a reader could check the repair in.
cite_listing=""
cite_listing_read=0
cite_names_file() {
    cite_path=$1
    while :; do
        case "$cite_path" in
            (./*) cite_path=${cite_path#./} ;;
            (/*) [ "$cite_path" != "$1" ] || break
                 cite_path=${cite_path#/} ;;
            (*) break ;;
        esac
    done
    [ "$cite_tag" = record ] || [ "$cite_path" != "$cite_record" ] || return 1
    [ -f "$cite_path" ] && [ ! -h "$cite_path" ] || return 1
    if [ "$cite_listing_read" -eq 0 ]; then
        cite_listing=$(git -c core.quotePath=false ls-files --cached --others \
            --exclude-standard) || gr_die "cannot list the files git tracks"
        cite_listing_read=1
    fi
    gr_contains "$cite_listing" "$cite_path"
}

# CITE_TEST_NAME — read lines and exit 0 if one of them DECLARES the test
# named by ENVIRON["cite_span"], never a -v value: awk -v rewrites backslashes,
# and a span may hold one. A declaration is:
#   bats   `@test "<span>"` after optional indentation;
#   jest   a first call `it(`, `test(` or `describe(` whose first argument is
#          exactly the span, in single or double quotes;
#   xUnit  `def ` or `func ` before an identifier span beginning `test` or
#          `Test`, as a Go method `func (<receiver>) ` does for a testify
#          suite, and Rust `fn ` before any identifier span, as whole words.
# A line that merely quotes the span — `run git merge "merge"` — declares
# nothing, and neither does a shell helper, `name() {` or `function name`, nor
# a line whose first non-space characters are a comment marker, `#` or `//`.
CITE_TEST_NAME='
function quoted_at_start(text, span) {
    return substr(text, 1, length(span) + 2) == "\"" span "\"" ||
        substr(text, 1, length(span) + 2) == "\047" span "\047"
}
BEGIN {
    span = ENVIRON["cite_span"]
    identifier = (span ~ /^[A-Za-z_][A-Za-z0-9_]*$/)
    pattern = ""
    if (identifier) {
        pattern = "fn " span
        if (span ~ /^(test|Test)/)
            pattern = "((def|func|fn) |func \\([^)]*\\) )" span
        pattern = "(^|[^A-Za-z0-9_])" pattern "([^A-Za-z0-9_]|$)"
    }
    found = 0
}
{
    line = $0
    sub(/^[ \t]+/, "", line)
    if (substr(line, 1, 1) == "#" || substr(line, 1, 2) == "//") next
    if (substr(line, 1, 6) == "@test ") {
        rest = substr(line, 7)
        sub(/^[ \t]+/, "", rest)
        if (substr(rest, 1, length(span) + 2) == "\"" span "\"") { found = 1; exit }
    }
    open_at = index(line, "(")
    if (open_at > 0) {
        callee = substr(line, 1, open_at - 1)
        if (callee == "it" || callee == "test" || callee == "describe") {
            rest = substr(line, open_at + 1)
            sub(/^[ \t]+/, "", rest)
            if (quoted_at_start(rest, span)) { found = 1; exit }
        }
    }
    if (pattern != "" && $0 ~ pattern) { found = 1; exit }
}
END { exit !found }
'

# cite_names_test SPAN — does a file under test_paths declare a test named
# SPAN? Each entry is a git pathspec, read as check-trace.sh reads it: git grep
# --untracked, so `*_test.go` matches recursively and a gitignored tree is not
# searched. -F narrows the search to lines holding SPAN at all; CITE_TEST_NAME
# then decides whether one of them declares it. git grep exits 1 for no match
# and above 1 for a search that failed, which is not an absent test.
cite_names_test() {
    [ -n "$cite_test_paths" ] || return 1
    # shellcheck disable=SC2086
    cite_test_lines=$(LC_ALL=C git grep -hI --untracked -F -e "$1" -- $cite_test_paths)
    case $? in
        (0) ;;
        (1) return 1 ;;
        (*) gr_die "cannot search test_paths for a test name (git grep failed)" ;;
    esac
    printf '%s\n' "$cite_test_lines" \
        | cite_span=$1 LC_ALL=C awk "$CITE_TEST_NAME"
}

# Report the disposition just read if nothing it cites resolved.
cite_report() {
    [ -n "$cite_line" ] || return 0
    if [ "$cite_resolved" -eq 0 ]; then
        echo "UNRESOLVABLE-DISPOSITION $1:$cite_line (cites no path in the tree, test name in test_paths or defined item ID, and is not \"no change — <reason>\")"
        fail=1
    fi
    cite_line=""
}

# Which records did THIS change write or touch?
#
# The selector is a branch NAME, and a name contains no identity: a project that
# reuses `fix-ci` or `docs` gets the previous change's complete record
# answering for this one, at exit 0, with no record for this change anywhere.
# Git knows the difference, so ask it. Three sources, all NUL-separated so a
# path may contain anything a filename may contain:
#   * committed on this branch since it diverged from the base;
#   * modified in the working tree but not yet committed;
#   * present but not yet tracked at all — the record is written at step 6b and
#     committed with the rest of the change, so it is legitimately new here.
#
# Skipped, and SAID SO in the summary, when --branch names the change: there is
# then no reason to believe HEAD is that branch, so the diff would ask about
# the wrong tree. A check that announces when it did not run is not a false
# green; one that stays quiet is.
provenance=0
touched=""
if [ "$named" -eq 0 ]; then
    provenance=1
    touched=$( { git diff --name-only -z "$base...HEAD" -- "$dir" \
                    || gr_die "cannot diff $base...HEAD"
                 git diff --name-only -z HEAD -- "$dir" \
                    || gr_die "cannot diff the working tree"
                 git ls-files -z --others --exclude-standard -- "$dir" \
                    || gr_die "cannot list untracked files"
               } | tr '\0' '\n' )
fi

fail=0
_findings=0
_matched=0
cite_count=0
for f in $records; do
    [ -n "$f" ] || continue
    _facts=$(scan_record "$f") || exit 2
    # Whole-value equality, never a prefix or a substring match: a record for
    # `my-change-2` must not satisfy a check for `my-change`. gr_contains
    # compares whole newline-delimited entries, which is exactly that.
    gr_contains "$_facts" "B $branch" || continue
    _matched=$((_matched + 1))
    if [ "$provenance" -eq 1 ] && ! gr_contains "$touched" "$f"; then
        echo "STALE-RECORD $f (declares $branch, but this change did not write it)"
        fail=1
    fi
    _findings=$((_findings + $(printf '%s\n' "$_facts" | grep -c '^N$' || true)))
    for _kw in $GR_RECORD_FIELDS; do
        gr_contains "$_facts" "F $_kw" && continue
        echo "INCOMPLETE-RECORD $f (no $_kw)"
        fail=1
    done
    for _l in $_facts; do
        case "$_l" in
            ("U "*)
                echo "UNDISPOSED-FINDING $f:${_l#U }"
                fail=1 ;;
            ("M "*)
                echo "MALFORMED-FINDING $f:${_l#M } (shaped like a finding header, opens no finding)"
                fail=1 ;;
            ("O "*)
                echo "ORPHAN-DISPOSITION $f:${_l#O } (belongs to no finding)"
                fail=1 ;;
        esac
    done
    [ "$cite_on" -eq 1 ] || continue
    # The record's path as a citation of it would read: doc_verification may
    # be led by `./` or end in `/`, and the record listing then yields
    # `./docs/verification/x.md` or `docs/verification//x.md`. Repeated
    # slashes collapse to one, then every leading `./` is dropped, or the
    # record would not be recognised as itself.
    cite_record=$f
    while :; do
        case "$cite_record" in
            (*//*) cite_record=${cite_record%%//*}/${cite_record#*//} ;;
            (./*) cite_record=${cite_record#./} ;;
            (*) break ;;
        esac
    done
    cite_line=""
    cite_tag=""
    cite_resolved=0
    for _l in $_facts; do
        case "$_l" in
            ("D "*)
                cite_report "$f"
                cite_fact=${_l#D }
                cite_line=${cite_fact%% *}
                cite_tag=${cite_fact#* }
                cite_resolved=0
                cite_count=$((cite_count + 1)) ;;
            ("X") cite_resolved=1 ;;
            ("C "*|"S "*)
                [ "$cite_resolved" -eq 1 ] && continue
                if cite_resolves "$_l"; then cite_resolved=1; fi ;;
        esac
    done
    cite_report "$f"
done

if [ "$_matched" -eq 0 ]; then
    echo "MISSING-RECORD $branch (no verification record in $dir declares it)"
    echo "guardrails: merge-change step 6b writes docs/verification/<date>-<branch>.md" >&2
    echo "from .guardrails/templates/verification.md. The record declares the change it" >&2
    echo "covers with a 'branch: $branch' line as its FIRST such line; nothing here does." >&2
    fail=1
fi

# The denominator, printed on pass and on failure alike, for the reason
# check-trace.sh prints `checked:`: a pass over nothing looks exactly like a
# pass over everything. `records` is how many the directory contained, `for` how
# many of them declare this change, `findings` how many finding blocks those
# contain, and the last field states whether the records were checked against what
# this change actually wrote. A green run reporting `findings 0` is a review that raised nothing,
# which is legal and now visible; the same line over a record that was silently
# not the one you thought would read `for 0`, and that cannot happen — no
# record for the branch is MISSING-RECORD, above.
_prov="provenance checked"
[ "$provenance" -eq 1 ] || _prov="provenance NOT checked (--branch)"
if [ "$cite_on" -eq 1 ]; then
    _prov="$_prov; citations checked over $cite_count dispositions"
fi
echo "checked: records $_n, for $branch $_matched, findings $_findings; $_prov"

exit $fail
