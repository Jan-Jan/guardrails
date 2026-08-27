#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# check-review.sh [--branch NAME]
#
# The review artefact gate. Independent review (merge-change step 6a) is the
# highest-yield step in the sequence and was the only one with nothing behind
# it: no check that a reviewer was dispatched, that findings were answered, or
# that the record says anything at all. Reported by a class B project running
# sixty-nine verification records entirely on the honour system.
#
# Fails (exit 1) on:
#   MISSING-RECORD BRANCH — no record in doc_verification declares this change.
#   INCOMPLETE-RECORD FILE (no KEYWORD:) — the record for this change omits a
#                            required field, or carries it with no value. An
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
#   ORPHAN-DISPOSITION FILE:LINE — a `disposition:` at column one belonging to
#                            no finding block. The backstop for every shape of
#                            detached finding the rule above cannot name, and
#                            the same mechanism check-trace.sh calls
#                            ORPHAN-ANNOTATION.
#   STALE-RECORD FILE — a record declaring this branch that this change did not
#                            write or touch. A reused branch name would
#                            otherwise let the previous change's record answer
#                            for this one.
#
# This gate judges PRESENCE, NEVER QUALITY. It cannot know whether a review was
# good, or whether a reviewer was independent of the author — with agent
# reviewers the identity string is whatever the author types, and a gate keyed
# on it would be theatre. It knows whether a review is claimed, by whom, with
# what conclusion, and whether every finding it raised was answered.
#
# Exit codes: 0 pass, 1 violations, 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
# NOT `cd "$(gr_root)" || exit 2`: gr_root's gr_die exits only the command
# substitution, and under dash `cd ""` returns 0 and stays put — so outside a
# git repository the script carried on in the caller's directory with a
# relative config path. The status has to be taken from the substitution.
gr_repo_root=$(gr_root) || exit 2
cd "$gr_repo_root" || exit 2

gr_check_config

branch=""
named=0
while [ $# -gt 0 ]; do
    case "$1" in
        --branch)
            shift
            [ $# -gt 0 ] || gr_die "--branch needs a branch name"
            branch="$1"
            named=1 ;;
        *) gr_die "unknown argument: $1" ;;
    esac
    shift
done

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
# The base branch is needed either way: to refuse the base as the subject
# (below), and to decide which records this change wrote (further down).
base=$(gr_base_branch)

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

dir=$(gr_verification_dir) || exit 2

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
# record whose name carries a `*` or a `?` must not be expanded a second time
# against the working directory when the loop below splits the list.
set -f

# GR_RECORD_SCAN — read one record and print what it declares, one fact per
# line, for the shell to judge:
#
#   B <value>   the record's OWN branch claim (the first `branch:` only)
#   F <keyword>  a required field carrying a value
#   N            one finding block, disposed or not (the denominator)
#   U <line> <id>  a finding block carrying no disposition
#   M <line>     a line shaped like a finding header that opens no block
#   O <line>     a `disposition:` belonging to no finding block
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
# other route and the guard becomes load-bearing with no test to notice.
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
BEGIN { gr_block_init("finding", "[0-9]+"); gr_fm_reset() }
FNR == 1 { sub(/^\357\273\277/, "") }
FNR == NR { gr_fm_scan($0, FNR); next }
gr_fm_skip(FNR) { next }
{ line = $0; sub(/\r$/, "", line) }
# A finding is an item block in the ledger shape this toolkit uses everywhere,
# so where one starts and ends is decided by the shared rule and by nothing
# local. A bold line carrying a colon, or a heading, ends it — which is why
# `disposition:` is a plain column-one annotation and not a bold field: bold,
# it would close the very block it belongs to.
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
gr_kw_here(line, "disposition:") {
    if (gr_value(line, "disposition:") == "") next
    if (open_line) disposed = 1
    # Outside every block, this is an orphan: read, matched, and — until this
    # backstop — dropped in silence. It is where the finding went. The same
    # mechanism check-trace.sh calls ORPHAN-ANNOTATION, for the same reason.
    else printf "O %d\n", FNR
}
{
    # Default FS: the field list is newline-separated (see below).
    n = split(kws, K)
    for (i = 1; i <= n; i++) {
        if (!gr_kw_here(line, K[i])) continue
        if (gr_value(line, K[i]) == "") continue
        print "F " K[i]
        # A record claims ONE branch: the FIRST `branch:` it carries, and no
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
END { if (open_line) gr_flush() }
'

# GR_RECORD_FIELDS — the fields the record must carry, checked once it has been
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

scan_record() {
    LC_ALL=C awk -v kws="branch: $GR_RECORD_FIELDS" "$GR_RECORD_SCAN" "$1" "$1" \
        || gr_die "record scan failed on $1"
}

# Which records did THIS change write or touch?
#
# The selector is a branch NAME, and a name carries no identity: a project that
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
            "U "*)
                echo "UNDISPOSED-FINDING $f:${_l#U }"
                fail=1 ;;
            "M "*)
                echo "MALFORMED-FINDING $f:${_l#M } (shaped like a finding header, opens no finding)"
                fail=1 ;;
            "O "*)
                echo "ORPHAN-DISPOSITION $f:${_l#O } (belongs to no finding)"
                fail=1 ;;
        esac
    done
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
# pass over everything. `records` is how many the directory held, `for` how
# many of them declare this change, `findings` how many finding blocks those
# carry, and the last field says whether the records were checked against what
# this change actually wrote. A green run reporting `findings 0` is a review that raised nothing,
# which is legal and now visible; the same line over a record that was silently
# not the one you thought would read `for 0`, and that cannot happen — no
# record for the branch is MISSING-RECORD, above.
_prov="provenance checked"
[ "$provenance" -eq 1 ] || _prov="provenance NOT checked (--branch)"
echo "checked: records $_n, for $branch $_matched, findings $_findings; $_prov"

exit $fail
