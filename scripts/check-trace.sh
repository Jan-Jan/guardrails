#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# check-trace.sh
#
# Traceability gates (exit 1 with one line per violation):
#   MISSING-TEST ID          — REQ or LLR with no `verifies:` reference in
#                              test_paths. A REQ also counts as tested when a
#                              tested LLR `satisfies:` it (transitive).
#   UNMITIGATED-HAZARD ID    — HAZ with no RC `mitigates:` line naming it
#   UNIMPLEMENTED-CONTROL ID — RC with no REQ `implements:` line naming it
#   UNTRACED-DESIGN ID       — SDD whose block has no `traces:` REQ reference
#   UNSATISFIED-LLR ID       — LLR whose block has no `satisfies:` naming a
#                              REQ and is not marked `satisfies: derived`
#   UNANALYZED-DERIVED ID    — REQ/LLR marked derived, never mentioned in RMF
#   DANGLING-REF ID          — ID referenced in docs/strict/test paths but
#                              defined nowhere
#   MISPLACED-ITEM ID        — item defined outside the document configured
#                              for its prefix
#   ORPHAN-ANNOTATION FILE:LINE — a status:/opened:/traces:/satisfies:
#                              line at column one that belongs to no item block
#   UNRESOLVED-PR ID         — problem report with status: open, with its age.
#                              WARNING only: listed for review,
#                              never fails the check on its own
#   INCOMPLETE-PROBLEM ID    — PR with no column-one status: in its block, or
#                              an OPEN one with no opened: (a keyword
#                              with an empty value counts as absent)
#   MALFORMED-STATUS ID      — status: whose value is neither open nor resolved
#   MALFORMED-DATE ID        — an open PR whose opened: is not a YYYY-MM-DD
#                              calendar date, or is more than a day ahead of
#                              today (one day is allowed for clock skew)
#   STALE-PROBLEM ID         — open longer than problem_age_days (more than)
#   PROBLEM-BACKLOG          — more open PRs than problem_open_max (more than)
#
# Each doc_* config value may be a single file or a directory of per-change
# dated *.md files (see gr_doc_files in lib.sh).
#
# Nothing here may pass vacuously. These are all environment errors (exit 2),
# never empty results:
#   * a doc_*, strict_paths or test_paths entry matching no file present in
#     the working tree;
#   * a ledger directory holding no *.md at all;
#   * an id_prefixes entry that is not a bare identifier — it is interpolated
#     into every scan pattern, and a scan that errors finds nothing;
#   * an unrecognised config key, a key that is not `identifier:` at column
#     one, a list item at column zero, or a UTF-8 BOM — each is invisible to
#     the config reader, so the gate that key configures never runs;
#   * an id_prefixes list naming none of REQ/HAZ/RC/SDD/LLR/PR, or a declared
#     prefix whose gate inputs are unconfigured, or one whose definition
#     document is unconfigured — every item of that prefix would be misplaced.
#     An extra prefix alongside those is fine — DANGLING-REF, DUPLICATE-ID and
#     ID finalization are keyed on the whole prefix list, so it is checked,
#     just not by a gate of its own.
#
# Annotation rule: for verifies:/mitigates:/implements:/satisfies:/traces:,
# only the ID list immediately following the FIRST occurrence of the keyword
# counts. The run ends at the first character that is not an ID, comma or
# space, so `verifies: REQ-001 (was REQ-042)` credits REQ-001 alone. The rule
# has exactly one definition — GR_AWK_ID_RUN in lib.sh.
#
# Every run ends with `checked:` (items found per prefix), `problems:` (open
# count, oldest open item, and both triage limits — whether or not they are
# set) and `sources:` (the document files read, then the number of configured
# path entries — one entry may be a directory or a pathspec), so a pass over
# zero cannot be mistaken for a pass over sixty-three, and a limit switched
# off cannot be mistaken for a limit met. MISPLACED-ITEM is what makes `checked:`
# trustworthy: while it is green, every item counted there sits in a document
# some gate actually opened. It covers the six gated prefixes only — an extra
# prefix has no configured document and is not placement-checked, so an item
# of one is still counted without being examined.
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

# Read beside gr_check_config, and for its reason: every other config
# invariant in this toolkit is settled BEFORE any gate runs, so that a typo is
# diagnosed as a typo rather than after a page of violations. Read at the point
# of use, a bad limit reported exit 2 with the `checked:`/`problems:`/`sources:`
# lines never printed — the evidence suppressed by the error.
age_limit=$(gr_limit problem_age_days) || exit 2
open_limit=$(gr_limit problem_open_max) || exit 2

# "Today" is the denominator of every age this gate computes, so a garbage
# value would not fail — it would make every age silently wrong. Two checks,
# because they catch different things and one message must not stand in for
# the other: the shell tests the SHAPE (and with it the `-v` value awk is
# about to be handed), and awk tests the CALENDAR.
today=$(date +%Y-%m-%d) || gr_die "date(1) failed; the age of an open problem cannot be established"
case "$today" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) gr_die "date +%Y-%m-%d produced '$today', which is not a date in YYYY-MM-DD form" ;;
esac
LC_ALL=C awk -v today="$today" "$GR_AWK_CIVIL"'BEGIN { exit(gr_date_ok(today) ? 0 : 1) }' \
    || gr_die "date +%Y-%m-%d produced '$today', which is not a calendar date"

prefixes=$(gr_prefixes) || exit 2
P=$(gr_prefix_re) || exit 2

# gr_doc_files dies on a configured-but-absent or empty path; because these run
# in a command substitution its exit only kills the subshell, so propagate it.
srs_files=$(gr_doc_files doc_srs) || exit 2
rmf_files=$(gr_doc_files doc_rmf) || exit 2
sad_files=$(gr_doc_files doc_sad) || exit 2
soup_files=$(gr_doc_files doc_soup) || exit 2
problems_files=$(gr_doc_files doc_problems) || exit 2
test_paths=$(cfg_list test_paths)
strict_paths=$(cfg_list strict_paths)

# Every list above is newline-separated, so split on newlines alone: a path or
# filename containing a space must reach git grep as one argument, and must be
# named correctly in any error about it. `prefixes` is newline-separated too,
# for the same uniformity.
IFS='
'

# Pathname expansion OFF from here on. Configured path entries are git
# pathspecs and must reach git verbatim. Left on, the shell expands them first
# against the current directory, so `strict_paths: - *.c` is replaced by
# whatever `*.c` matches in the repo ROOT and the recursive pathspec meaning is
# silently lost: a root-level main.c makes `src/foo.c` invisible while
# `sources:` still reports `strict 1`. Deleting that unrelated root file then
# changes the verdict. gr_doc_files above needs globbing to expand its `*.md`,
# so it has already run.
set -f

# A configured path that does not exist makes every gate that reads it a
# silent no-op. Fail as an environment error instead of passing vacuously.
#
# The list expansions here and at the scan sites below are deliberately
# unquoted so the newline-separated lists split into separate arguments —
# never so the shell can expand a pattern. `set -f` above guarantees it does
# not: every entry reaches git verbatim as a pathspec. An entry matching no
# file at all scans no file, and that is what must be an error.
require_paths() {
    _key="$1"
    shift
    for _d in "$@"; do
        [ -n "$_d" ] || continue
        # No `[ -e ] && continue` short-circuit: an empty directory exists but
        # holds nothing to scan, and passing it here would report `strict 1` in
        # the summary for a source that read nothing — the exact false green
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
        _cached=$(git ls-files --cached -- "$_d" 2>/dev/null | grep -c .)
        _gone=$(git ls-files --deleted -- "$_d" 2>/dev/null | grep -c .)
        _new=$(git ls-files --others --exclude-standard -- "$_d" 2>/dev/null | grep -c .)
        [ $((_cached - _gone + _new)) -gt 0 ] && continue
        gr_die "$_key entry matches no file present in the working tree: $_d"
    done
}
# shellcheck disable=SC2086
require_paths strict_paths $strict_paths
# shellcheck disable=SC2086
require_paths test_paths $test_paths

fail=0

# ids_defined PREFIX — all finalized IDs with a `**ID**:` definition site
ids_defined() {
    git grep -h --untracked -oE "$(gr_def_re "$1")" -- . \
        "$GR_SCAN_EXCLUDE" 2>/dev/null | sed 's/[*:]//g' | sort -u
}

# ids_defined_in PREFIX FILES… — definitions of PREFIX inside the given files.
# The empty-args guard is defence in depth, not a reachable branch: every
# caller below passes a doc file list that gr_check_config's rule 2 and
# gr_doc_files between them guarantee is non-empty. It is here because the
# failure mode if a future caller does pass nothing is silent — `git grep -- `
# with no pathspec scans the whole repository, so every item would look
# correctly placed and the gate would report nothing at all.
ids_defined_in() {
    _p="$1"
    shift
    [ $# -gt 0 ] || return 0
    git grep -h --untracked -oE "$(gr_def_re "$_p")" -- "$@" 2>/dev/null \
        | sed 's/[*:]//g' | sort -u
}

# ids_matching KEYWORD PREFIX PATHS… — IDs of PREFIX in the ID list that
# immediately follows KEYWORD (see the annotation rule above).
ids_matching() {
    _kw="$1"
    _pfx="$2"
    shift 2
    [ $# -gt 0 ] || return 0
    git grep -hI --untracked -F "$_kw" -- "$@" 2>/dev/null \
        | gr_id_run "$_kw" \
        | grep -xE "${_pfx}-${GR_ID_BODY}" | sort -u
}

# --- LLR block parse: "<id> <REQ,REQ|derived|->" per LLR in the SAD files ---
# Blocks end at the next header-shaped line or markdown heading (see
# GR_AWK_ITEM_BLOCK in lib.sh), so prose can never satisfy an LLR. Parsed per file; blocks cannot span files.
parse_llr_file() {
    LC_ALL=C awk -v body="$GR_ID_BODY" "$GR_AWK_ID_RUN$GR_AWK_ITEM_BLOCK"'
        BEGIN { gr_block_init("LLR", body) }
        function flush() {
            if (cur != "") {
                if (der) print cur " derived"
                else if (sat != "") print cur " " sat
                else print cur " -"
            }
        }
        # ONE rule for both boundaries. Every definition form closes the open
        # block, and one of this gate own prefix opens a new one in the same
        # breath — which is why the ternary rather than two rules that would
        # have to agree about their order.
        #
        # Deliberately no `next`: an LLR header usually carries its own
        # `satisfies:` annotation, so the line must still reach the collector.
        gr_block_closes($0) {
            flush()
            cur = gr_block_opens($0) ? gr_block_id($0) : ""
            sat = ""; der = 0
        }
        cur != "" {
            if ($0 ~ /satisfies:[ \t]*derived/) der = 1
            else {
                run = gr_id_run($0, "satisfies:")
                n = split(run, a, " ")
                for (i = 1; i <= n; i++)
                    if (a[i] ~ /^REQ-/) sat = sat (sat == "" ? "" : ",") a[i]
            }
        }
        END { flush() }
    ' "$1"
}

llr_info=""
for f in $sad_files; do
    llr_info="$llr_info
$(parse_llr_file "$f")"
done

# --- MISPLACED-ITEM: an item must be defined inside its own document -------
# The message states the RULE and nothing else, deliberately. Two attempts at
# stating the consequence were both disproved by the same run that printed
# them, and the honest version has too many exceptions for one line:
#
#   * the item is still ENUMERATED — ids_defined scans the whole tree, so
#     MISSING-TEST, UNMITIGATED-HAZARD and UNIMPLEMENTED-CONTROL fire on a
#     misplaced item exactly as on a placed one;
#   * its own block is not PARSED by the gate that would convict it on those
#     annotations: UNTRACED-DESIGN, UNSATISFIED-LLR, UNRESOLVED-PR and the
#     derived-assessment scan read only the configured document, so a
#     misplaced SDD keeps no `traces:` obligation and a misplaced PR can never
#     be reported open;
#   * but DANGLING-REF scans every doc_* file plus strict_paths and
#     test_paths, so an item misfiled into ANOTHER ledger still has its
#     reference IDs read — by that gate, not by its own;
#   * and a HAZ block carries no annotation of its own that a gate parses, but
#     moving it out of the RMF still blinds one: UNANALYZED-DERIVED is a
#     free-text grep over $rmf_files, so a derived item assessed inside a HAZ
#     block stops being assessed when that block leaves. It fails RED, so no
#     false green — but the loss is real.
#
# What is true for all six is the rule itself: an item belongs in the files
# its key resolves to. The exceptions above are stated where there is room for
# them — skills/check-traceability/SKILL.md and README.md.
# `**SDD-001**:` in docs/design.md passed with no `traces:` at all, and moving
# that same file into doc_sad turned the run red without changing a character
# of it.
#
# "Outside" means outside what gr_doc_files RESOLVES: for a directory, its
# *.md files one level deep; for a scalar, that one file whatever its
# extension. A `.txt` sitting in a configured DIRECTORY, or a `.md` one level
# further down, is outside it — hence the message naming the files the key
# resolves to rather than the key's value, and not naming *.md, which is
# wrong for a single-file doc_* config.
#
# This gate is what makes the summary trustworthy: while it is green, every
# item counted in `checked:` sits in a document some gate actually opened.
check_placement() {
    _pfx="$1"
    _key="$2"
    shift 2
    # No `[ $# -gt 0 ] || return 0` guard here, and deliberately so. The arms
    # below cannot pass an empty list — rule 2 requires the key, gr_doc_files
    # then yields at least one file or dies — so this is about which way to
    # fail if that ever stops being true. With no files the correct verdict is
    # "every item of this prefix is read by nothing", which is what an empty
    # _inside produces. Skipping instead would be the silent exemption this
    # gate exists to remove.
    _inside=$(ids_defined_in "$_pfx" "$@")
    for _id in $(ids_defined "$_pfx"); do
        gr_contains "$_inside" "$_id" || {
            echo "MISPLACED-ITEM $_id (must be defined in the files $_key resolves to)"
            fail=1
        }
    done
}
for _pfx in $prefixes; do
    case "$_pfx" in
        # shellcheck disable=SC2086
        REQ) check_placement REQ doc_srs $srs_files ;;
        # shellcheck disable=SC2086
        HAZ|RC) check_placement "$_pfx" doc_rmf $rmf_files ;;
        # shellcheck disable=SC2086
        SDD|LLR) check_placement "$_pfx" doc_sad $sad_files ;;
        # shellcheck disable=SC2086
        PR) check_placement PR doc_problems $problems_files ;;
    esac
done

# --- MISSING-TEST: every REQ and LLR needs a verifies: reference ------------
if [ -n "$test_paths" ]; then
    # shellcheck disable=SC2086
    verified_llr=$(ids_matching 'verifies:' LLR $test_paths)
    for id in $(ids_defined LLR); do
        gr_contains "$verified_llr" "$id" || { echo "MISSING-TEST $id (no 'verifies:' reference in test paths)"; fail=1; }
    done

    # REQ coverage: direct verifies:, plus satisfies: lists of tested LLRs
    # shellcheck disable=SC2086
    covered=$(ids_matching 'verifies:' REQ $test_paths)
    for llr in $verified_llr; do
        sats=$(printf '%s\n' "$llr_info" \
            | awk -v l="$llr" '$1 == l && $2 != "-" && $2 != "derived" { print $2 }' \
            | tr ',' '\n')
        covered="$covered
$sats"
    done
    for id in $(ids_defined REQ); do
        gr_contains "$covered" "$id" || { echo "MISSING-TEST $id (no direct 'verifies:' and no tested LLR satisfies it)"; fail=1; }
    done
fi

# --- UNMITIGATED-HAZARD: every HAZ needs an RC that mitigates it ------------
if [ -n "$rmf_files" ]; then
    # shellcheck disable=SC2086
    mitigated=$(ids_matching 'mitigates:' HAZ $rmf_files)
    for id in $(ids_defined HAZ); do
        gr_contains "$mitigated" "$id" || { echo "UNMITIGATED-HAZARD $id (no risk control 'mitigates:' it)"; fail=1; }
    done
fi

# --- UNIMPLEMENTED-CONTROL: every RC needs a REQ that implements it ---------
if [ -n "$srs_files" ]; then
    # shellcheck disable=SC2086
    implemented=$(ids_matching 'implements:' RC $srs_files)
    for id in $(ids_defined RC); do
        gr_contains "$implemented" "$id" || { echo "UNIMPLEMENTED-CONTROL $id (no requirement 'implements:' it)"; fail=1; }
    done
fi

# --- UNTRACED-DESIGN: every SDD block needs `traces:` naming a REQ ----------
for f in $sad_files; do
    untraced=$(LC_ALL=C awk -v body="$GR_ID_BODY" "$GR_AWK_ID_RUN$GR_AWK_ITEM_BLOCK"'
        BEGIN { gr_block_init("SDD", body) }
        function flush() { if (cur != "" && !ok) print cur }
        # Deliberately no `next`: the header line itself usually carries the
        # `traces:` annotation, so it must reach the scan below.
        gr_block_closes($0) {
            flush()
            cur = gr_block_opens($0) ? gr_block_id($0) : ""
            ok = 0
        }
        cur != "" {
            run = gr_id_run($0, "traces:")
            n = split(run, a, " ")
            for (i = 1; i <= n; i++) if (a[i] ~ /^REQ-/) ok = 1
        }
        END { flush() }
    ' "$f")
    for id in $untraced; do
        echo "UNTRACED-DESIGN $id (no 'traces:' to a requirement)"
        fail=1
    done
done

# --- UNSATISFIED-LLR: every LLR satisfies a REQ or is marked derived --------
for id in $(printf '%s\n' "$llr_info" | awk '$2 == "-" { print $1 }'); do
    echo "UNSATISFIED-LLR $id (no 'satisfies:' REQ and not marked derived)"
    fail=1
done

# --- UNANALYZED-DERIVED: derived REQ/LLR must be assessed in the RMF --------
derived_ids=$(printf '%s\n' "$llr_info" | awk '$2 == "derived" { print $1 }')
for f in $srs_files; do
    derived_ids="$derived_ids
$(LC_ALL=C awk -v body="$GR_ID_BODY" "$GR_AWK_ITEM_BLOCK"'
        BEGIN { gr_block_init("REQ", body) }
        gr_block_closes($0) { cur = gr_block_opens($0) ? gr_block_id($0) : "" }
        cur != "" && /satisfies:[ \t]*derived/ { print cur; cur = "" }
    ' "$f")"
done
for id in $derived_ids; do
    # word-ish match: the ID must not be a prefix of a longer ID in the RMF
    # shellcheck disable=SC2086
    if [ -n "$rmf_files" ] && git grep -qE --untracked -- "${id}(${GR_ID_TAIL}|\$)" $rmf_files 2>/dev/null; then
        :
    else
        echo "UNANALYZED-DERIVED $id (derived item not assessed in the RMF)"
        fail=1
    fi
done

# --- DANGLING-REF: every referenced ID must be defined somewhere ------------
# Newline-joined, like every other path list here, so a path with a space in
# it stays one argument to git grep.
scope=""
for f in $srs_files $rmf_files $sad_files $soup_files $problems_files \
        $strict_paths $test_paths; do
    [ -n "$f" ] && scope="${scope}${scope:+
}$f"
done
if [ -n "$scope" ]; then
    # The trailing boundary is matched and then stripped: without it a mention
    # of REQ-a3k9z2x harvests its first six characters and is reported against
    # REQ-a3k9z2 — which, being defined, is not reported at all. A token can
    # never end in a non-alphanumeric, so the strip cannot damage a real ID.
    #
    # Status checked and stderr not suppressed: this scan is the whole input to
    # DANGLING-REF, and an errored scan finds nothing, which is exactly what a
    # tree with no bad references looks like. Not a pipeline, so $? is git's.
    # shellcheck disable=SC2086
    _refs=$(git grep -h --untracked -oE "(${P})-${GR_ID_BODY}(${GR_ID_TAIL}|\$)" -- $scope)
    _st=$?
    [ "$_st" -le 1 ] || gr_die "reference scan failed (git grep exit $_st)"
    referenced=$(printf '%s\n' "$_refs" | sed "s/${GR_ID_TAIL}\$//" | sort -u)
    defined=""
    for pfx in $prefixes; do
        defined="$defined
$(ids_defined "$pfx")"
    done
    for id in $referenced; do
        gr_contains "$defined" "$id" || { echo "DANGLING-REF $id (referenced but never defined)"; fail=1; }
    done
fi

# --- Problem-report triage --------------------------------------------------
# UNRESOLVED-PR is the roll-call and stays a WARNING: the known-problem review
# it serves is a review, not a prohibition, and an item under the configured
# limits does not fail the run. What DOES fail is an item the roll-call cannot
# state truthfully, and a backlog past a limit the project set for itself.
#
# The reader was rewritten here for one reason. It used to be
#
#     cur != "" && /status:[ \t]*open/ { open = 1 }
#
# — unanchored, matched anywhere in the line, and therefore reading a `status:`
# occurrence that check_orphans below CANNOT SEE, because that backstop reports
# a keyword only at column one. ORPHAN-ANNOTATION exists to catch annotations
# belonging to no item; a reader looking where the backstop does not reopens
# the hole it closed. Worse, an item whose `status:` line the pattern missed —
# `Status: open`, `status : open`, no `status:` line at all — read as RESOLVED
# and vanished from the roll-call: an open problem no merge would ever see.
# Measured on a real ledger, one item in 159 was in exactly that state.
#
# So: column one, first occurrence in the block wins, value from a closed set.
# Anchoring alone would move the false green rather than remove it, which is
# why the missing-status: violation ships in the same change.
#
# Ages are whole days in LOCAL time, from `date +%Y-%m-%d`; the arithmetic
# itself is exact (GR_AWK_CIVIL in lib.sh). A one-day disagreement about what
# "today" is, on the other hand, is NOT immaterial in one place: `opened:`
# tomorrow would otherwise be a hard failure on a correct item. One day of
# tolerance is allowed there and clamped to age 0 — see gr_prflush. Two local
# dates differ by more than one only when the offsets differ by more than 24
# hours, which no pair of real timezones does.
#
# Each line is `W <age> <text>` or `F 0 <text>`: W is the roll-call warning and
# carries the age so the summary can report the oldest, F fails the run. The
# split is made in awk, which knows the limits, and the shell only aggregates —
# a `while read` over a pipe runs in a subshell here, where a `fail=1` would be
# lost. An age of -1 means the item is open and cannot be dated.
_prs=$(
    for f in $problems_files; do
        LC_ALL=C awk -v body="$GR_ID_BODY" -v today="$today" \
            -v agelim="$age_limit" \
            "$GR_AWK_ITEM_BLOCK$GR_AWK_CIVIL"'
            function gr_prflush(   age) {
                if (cur == "") return
                # Neither of the next two returns reaches the roll-call, so
                # neither counts toward the backlog. That is deliberate: the
                # gate does not GUESS an unstated status, it demands one. The
                # count can therefore under-report — but only on a run that is
                # already red for that very item, never on a green one.
                if (!st_seen) {
                    printf "F 0 INCOMPLETE-PROBLEM %s (no status: line in its block)\n", cur
                    return
                }
                if (st != "open" && st != "resolved") {
                    printf "F 0 MALFORMED-STATUS %s (status: %s — expected open or resolved)\n", cur, st
                    return
                }
                if (st == "resolved") return

                # OPEN. Every branch below still reaches the roll-call: an open
                # item missing from it is the defect this gate exists to remove,
                # and an item that cannot be dated is not thereby young.
                age = -1
                if (!opd_seen || opd == "")
                    printf "F 0 INCOMPLETE-PROBLEM %s (open, no opened:)\n", cur
                else if (!gr_date_ok(opd))
                    printf "F 0 MALFORMED-DATE %s (opened: %s is not a YYYY-MM-DD calendar date)\n", cur, opd
                else {
                    age = todaydays - GR_DATE_DAYS
                    # A future date yields a negative age, which compares as
                    # younger than any limit — the false-green direction, so it
                    # is rejected rather than clamped.
                    #
                    # ONE day of tolerance, though, and the day is clamped to
                    # zero. `resolve-problem` tells the author to write today,
                    # and "today" differs by a day across timezones and under
                    # ordinary clock skew: without this, an author in UTC+13
                    # blocks the merge on a correct item on the day they record
                    # it. One day cannot make a stale item look fresh against
                    # limits measured in weeks; a fortnight can, and still
                    # fails.
                    if (age == -1) age = 0
                    else if (age < 0) {
                        printf "F 0 MALFORMED-DATE %s (opened: %s is more than a day in the future)\n", cur, opd
                        age = -1
                    }
                }
                if (age < 0)
                    printf "W -1 UNRESOLVED-PR %s (open, age unrecorded)\n", cur
                else {
                    printf "W %d UNRESOLVED-PR %s (open %d days)\n", age, cur, age
                    if (agelim != "" && age > agelim + 0)
                        printf "F 0 STALE-PROBLEM %s (open %d days, limit %d)\n", cur, age, agelim + 0
                }
            }
            BEGIN {
                gr_block_init("PR", body)
                gr_date_ok(today)   # validated in the shell above
                todaydays = GR_DATE_DAYS
            }
            FNR == 1 { sub(/^\357\273\277/, "") }
            # NO front-matter skip here, and that is a decision, not an
            # omission. The first version of this scan skipped front matter
            # "so the reader and the backstop agree", and the independent
            # review reproduced what that costs: GR_AWK_FRONT_MATTER treats ANY
            # `---` on line 1 as opening a header block, so a leading
            # horizontal rule swallowed every ITEM DEFINITION up to the next
            # `---`. An open problem 236 days old vanished from the roll-call,
            # `problem_open_max` did not apply, and the run exited 0 — every
            # failure this gate exists to prevent, introduced by the gate.
            #
            # The backstop reads ANNOTATIONS, where skipping a real header
            # block is right; this scan reads DEFINITIONS, and the rule for
            # those is already settled across the toolkit — a definition form
            # at column one is judged wherever it sits, fenced block or not.
            #
            # That is not the whole story, and the rest was found by the same
            # review: the backstop could not tell a header from a horizontal
            # rule either, so a leading `---` switched IT off for the same span
            # and dropped every annotation in it. GR_AWK_FRONT_MATTER now
            # requires a key on line 2, which fixes both. One disagreement
            # survives and is fail-loud: an item definition pasted INSIDE a
            # genuine header block is read here and invisible to the backstop,
            # so its own fields are reported as orphans. A contrived document,
            # reported rather than passed, and named here so it is not
            # rediscovered as a surprise. Skipping was also unobservable in the intended direction —
            # no item block can be open before line 1 — so it removed nothing
            # and lost items. Not skipping keeps this scan in step with
            # `ids_defined`, which is what makes `checked:` and `problems:`
            # reconcilable.
            { line = $0; sub(/\r$/, "", line) }
            gr_block_closes(line) {
                gr_prflush()
                cur = ""
                st = ""; opd = ""
                st_seen = 0; opd_seen = 0
                if (gr_block_opens(line)) cur = gr_block_id(line)
            }
            # First occurrence wins, per keyword — the GR_AWK_ID_RUN rule
            # applied to a scalar annotation. A later line cannot reopen an
            # item the first line already closed.
            cur != "" && !st_seen  && gr_kw_here(line, "status:") { st_seen = 1;  st = gr_value(line, "status:") }
            cur != "" && !opd_seen && gr_kw_here(line, "opened:") { opd_seen = 1; opd = gr_value(line, "opened:") }
            END { gr_prflush() }
        ' "$f" || gr_die "problem-report scan failed on $f"
    done
) || exit 2

_open_n=$(printf '%s\n' "$_prs" | grep -c '^W ' || true)
_undatable_n=$(printf '%s\n' "$_prs" | grep -c '^W -1 ' || true)
# m starts at -1, which is also what an undatable item reports, so "no age
# known" and "the maximum age" are the same value and need no second flag. The
# first version seeded the maximum from awk's uninitialised 0 and kept a `seen`
# flag: an age of 0 is the one age that does not exceed 0, so a ledger whose
# only open item was opened TODAY reported `oldest n/a` — an item counted as
# open and absent from the age.
_oldest=$(printf '%s\n' "$_prs" | LC_ALL=C awk 'BEGIN { m = -1 } $1 == "W" && $2 + 0 > m { m = $2 + 0 } END { print m }')
if [ -n "$_prs" ]; then
    printf '%s\n' "$_prs" | cut -d' ' -f3-
    printf '%s\n' "$_prs" | grep -q '^F ' && fail=1
fi
if [ -n "$open_limit" ] && [ "$_open_n" -gt "$open_limit" ]; then
    _noun="open problem reports"
    [ "$_open_n" -eq 1 ] && _noun="open problem report"
    echo "PROBLEM-BACKLOG ($_open_n $_noun, limit $open_limit)"
    fail=1
fi

# --- ORPHAN-ANNOTATION: an annotation that belongs to no item --------------
# The backstop to the block rule, and the reason that rule can be relaxed
# safely. Blocks now end at a header shape rather than at any bold line,
# which fixes the case that was reported — but every termination rule has an
# outside, and the outside is where this defect lived. An annotation before the
# first item in a file, or under a heading with no item since, belongs to
# nothing under ANY rule. Until this gate it was read, matched, and dropped in
# silence: `status: open` on such a line left the item open in the ledger and
# absent from the known-problem review, with the run still exiting 0.
#
# Scope is per keyword, and only where that keyword is BLOCK-parsed:
# `mitigates:`, `implements:` and `verifies:` are read line-wise by
# ids_matching, never against a block, so they cannot be orphaned. Reporting
# them anyway — or reporting `status:` from the SRS, where nothing reads it —
# would be noise, and noise is what teaches people to read past the output.
#
# Column one, like every definition form here. That is what keeps the grammar
# comment shipped in templates/problems.md inert, and it is what makes this
# gate adoptable without editing every ledger that already exists.
check_orphans() {
    _kw="$1"
    _open="$2"
    shift 2
    for _f in "$@"; do
        [ -n "$_f" ] || continue
        # LC_ALL=C: defence in depth, and honestly weak — the close and the
        # keyword test are substr/index, which count bytes in every locale, and
        # the only locale-sensitive construct left is the octal-escape BOM
        # strip below. No test distinguishes this setting on gawk 5.3.2, mawk
        # or busybox awk; it is kept because the escapes are byte values and
        # some awk in some locale will read them as characters.
        LC_ALL=C awk -v body="$GR_ID_BODY" -v popen="$_open" -v kw="$_kw" -v fname="$_f" \
            "$GR_AWK_ITEM_BLOCK$GR_AWK_FRONT_MATTER"'
            # The opening prefix is the reader of THIS keyword, never every
            # declared prefix. Opening on all of them left a third state the
            # gates do not have: inside another prefix block, where the reader
            # sees nothing (it opens only on its own prefix) while the backstop
            # sees a block open. An extra prefix is a supported config and is
            # not placement-checked, so an ADR header in the SRS swallowed a
            # `satisfies: derived` with both gates silent and the run at exit 0.
            BEGIN { gr_block_init(popen, body); gr_fm_reset() }
            # A BOM sits in front of column one and hides it from every
            # match below, front-matter delimiter included. Stripped in both
            # passes; LC_ALL=C on the invocation is what makes the octal
            # escapes byte-exact, the same reasoning gr_check_config uses.
            FNR == 1 { sub(/^\357\273\277/, "") }
            # Front matter is skipped, bounded, in two passes. The rule has ONE
            # definition — GR_AWK_FRONT_MATTER in lib.sh — because
            # check-review.sh reads it too, and a second reader of a hand-copied
            # rule is how the item-block defect of 2026-08-22 happened.
            FNR == NR { gr_fm_scan($0, FNR); next }
            gr_fm_skip(FNR) { next }
            gr_block_closes($0) { inblock = gr_block_opens($0) }
            !inblock && gr_kw_here($0, kw) {
                # FNR, never NR: the file is read TWICE (see the
                # front-matter pass above), so NR is offset by the whole first
                # pass and every reported line number would be wrong.
                printf "ORPHAN-ANNOTATION %s:%d (%s belongs to no item)\n", \
                    fname, FNR, kw
            }
        ' "$_f" "$_f" || gr_die "orphan scan failed on $_f"
    done
}
# shellcheck disable=SC2086
_sat_files=$(printf '%s\n' $sad_files $srs_files | sort -u)
# shellcheck disable=SC2086
_orphans=$(
    check_orphans 'status:' PR $problems_files
    # The reader added `opened:` to the same block, so the backstop covers it
    # too: under a looser block rule an orphaned opened: is credited to the
    # item above, and an undated item then reads as dated.
    check_orphans 'opened:' PR $problems_files
    check_orphans 'traces:' SDD $sad_files
    # ONE scan over the union, opening on BOTH prefixes that read `satisfies:`.
    # Two scans over two lists reported a false positive when doc_srs and
    # doc_sad resolve to the same directory: the LLR gate read the annotation
    # correctly, while the REQ-opening scan saw the LLR header close a block
    # without opening one and called the line an orphan. Opening on a prefix
    # that is misplaced in that document costs nothing — MISPLACED-ITEM is
    # already red for it.
    check_orphans 'satisfies:' 'LLR|REQ' $_sat_files
) || exit 2
if [ -n "$_orphans" ]; then
    printf '%s\n' "$_orphans"
    fail=1
fi

# --- Summary: report the denominator ----------------------------------------
# Two numbers, because one is not enough. `checked:` counts the items found;
# `sources:` counts the files and paths each gate actually read. An item count
# alone says nothing about whether the gate for those items ran at all.
# Printed on pass and on failure alike, so every result states what it covered.
count_lines() {
    printf '%s' "$1" | grep -c . || true
}

summary=""
for pfx in $prefixes; do
    n=$(ids_defined "$pfx" | grep -c .) || true
    summary="${summary}${summary:+, }${pfx} ${n}"
done
echo "checked: $summary"
# The third summary line, and the reason an unset limit is not a silent one.
# A team that has switched a limit off reads that fact at every merge, next to
# the backlog the limit was meant to hold down.
_oldest_txt="n/a"
[ "$_oldest" -ge 0 ] && _oldest_txt="$_oldest days"
# Reported separately rather than folded into `oldest`, because it is the one
# number the age cannot represent: an item whose age is unknown is open all the
# same, and an `oldest` that quietly ignored it would read as if every open
# item had been accounted for.
#
# "no usable date", not "undated": the count includes an item whose `opened:`
# was REFUSED — malformed, or too far ahead — as well as one that has none.
# Both are open and of unknown age; only one of them is undated.
[ "$_undatable_n" -gt 0 ] && _oldest_txt="$_oldest_txt ($_undatable_n with no usable date)"
echo "problems: open $_open_n, oldest $_oldest_txt; limits age ${age_limit:-none}, open ${open_limit:-none}"
echo "sources: srs $(count_lines "$srs_files"), rmf $(count_lines "$rmf_files"), sad $(count_lines "$sad_files"), soup $(count_lines "$soup_files"), problems $(count_lines "$problems_files"); strict $(count_lines "$strict_paths"), tests $(count_lines "$test_paths")"

exit $fail
