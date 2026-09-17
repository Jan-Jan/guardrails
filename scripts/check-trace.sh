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
#   UNANALYZED-DERIVED ID    — REQ/LLR marked derived that no `assesses:`
#                              line in the RMF names
#   DANGLING-REF ID          — ID referenced in docs/strict/test paths but
#                              defined nowhere
#   DANGLING-FILE FILE       — a `DRAFT-<name>.md` ledger file (name
#                              characters [A-Za-z0-9_.-]) named in a doc_*
#                              file, by path or bare name, that does not exist
#   MISPLACED-ITEM ID        — item defined outside the document configured
#                              for its prefix
#   NON-RECIPROCAL-SUPERSESSION ID — `supersedes: Y` with no `superseded-by:`
#                              naming it back on Y, or the reverse. The pair
#                              merge-change step 6a prescribes, and ONLY the
#                              pair: this is not a sweep for stale references
#                              to a superseded ID, and existence is
#                              DANGLING-REF's
#   ORPHAN-ANNOTATION FILE:LINE — a status:/opened:/disposition:/traces:/
#                              satisfies:/supersedes:/superseded-by: line at
#                              column one that belongs to no item block
#   UNRESOLVED-PR ID         — problem report with status: open, with its age.
#                              WARNING only: listed for review,
#                              never fails the check on its own
#   ACCEPTED-PR ID           — problem report with status: accepted, containing
#                              its opened: date and its disposition:. WARNING
#                              only, and exempt
#                              from STALE-PROBLEM and from problem_open_max —
#                              a decision is not a backlog — but never exempt
#                              from this roll-call
#   INCOMPLETE-PROBLEM ID    — PR with no column-one status: in its block, an
#                              OPEN one with no opened:, or an ACCEPTED one
#                              with no disposition: or no opened: (a keyword
#                              with an empty value counts as absent)
#   MALFORMED-STATUS ID      — status: whose value is not one of open,
#                              accepted or resolved
#   MALFORMED-DATE ID        — an open or accepted PR whose opened: is not a
#                              YYYY-MM-DD calendar date, or is more than a day
#                              ahead of today (one day is allowed for clock
#                              skew). An accepted item ages against no limit,
#                              but the date still records when the problem was
#                              raised, and the roll-call prints it
#   MALFORMED-SUPERSESSION ID — a column-one supersedes: or superseded-by: in
#                              an item block whose value contains no item ID,
#                              the empty value included, OR whose list contains
#                              a token in a declared prefix that is not an ID
#                              beside ones that are. Reported rather than read
#                              as no supersession — or as half of one
#   STALE-PROBLEM ID         — open longer than problem_age_days (more than)
#   PROBLEM-BACKLOG          — more open PRs than problem_open_max (more than)
#
# Scoped (multi-unit) runs add:
#   NON-EXPORTED-REF ID      — reference to an item defined in a declared
#                              dependency but not `exported: yes` there
#   UNDECLARED-DEPENDENCY ID — reference to (or expects: naming) a unit that
#                              is not in this unit's depends_on
#   UNMET-EXPECTATION        — an expects: REQ its provider has not yet
#                              answered with an exported satisfies: REQ.
#                              Advisory inside its aging budget; exit 1 past
#                              expectation_age_days, and on every run when the
#                              expectation implements a risk control
#   INCOMPLETE-EXPECTATION ID — an expects: the reader cannot use: empty
#                              value, a non-REQ carrier, or no usable opened:
#   MISEXPORTED-ITEM ID      — exported: with any value but yes, or on a
#                              non-REQ item
#   EXPECTATION-BACKLOG      — more open expectations than expectation_open_max
#
# Scoped runs engage only when .guardrails/units.yaml exists and GR_CONFIG
# names a declared unit's config (gr_unit_engage in lib.sh). With no manifest
# every path below is byte-identical to the single-unit script; with a
# manifest and no unit config the run is rejected (exit 2) rather than scoped
# by guesswork.
#
# Each doc_* config value may be a single file or a directory of per-change
# dated *.md files (see gr_doc_files in lib.sh).
#
# Nothing here may pass vacuously. These are all environment errors (exit 2),
# never empty results:
#   * a doc_*, strict_paths or test_paths entry matching no file present in
#     the working tree;
#   * a ledger directory containing no *.md at all;
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
# Annotation rule: for verifies:/mitigates:/implements:/satisfies:/traces:/assesses:,
# only the ID list immediately following the FIRST occurrence of the keyword
# counts. The run ends at the first character that is not an ID, comma or
# space, so `verifies: REQ-001 (was REQ-042)` credits REQ-001 alone. The rule
# has exactly one definition — GR_AWK_ID_RUN in lib.sh.
#
# Every run ends with `checked:` (items found per prefix), `problems:` (open
# count, accepted count, oldest open item, and both triage limits — whether or
# not they are set) and `sources:` (the document files read, then the number of configured
# path entries — one entry may be a directory or a pathspec), so a pass over
# zero cannot be mistaken for a pass over sixty-three, and a limit switched
# off cannot be mistaken for a limit met. MISPLACED-ITEM is what makes `checked:`
# trustworthy: while it is green, every item counted there is in a document
# some gate actually opened. It covers the six gated prefixes only — an extra
# prefix has no configured document and is not placement-checked, so an item
# of one is still counted without being examined.
#
# Exit codes: 0 pass, 1 violations, 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
# NOT `cd "$(gr_root)" || exit 2`: gr_root's gr_die exits only the command
# substitution, and under dash `cd ""` returns 0 and stays put — so outside a
# git repository the script continued in the caller's directory with a
# relative config path. The status has to be taken from the substitution.
gr_repo_root=$(gr_root) || exit 2
cd "$gr_repo_root" || exit 2

# The engagement rule (architecture item 2): with no manifest this is a
# no-op and everything below is exactly the single-unit script. Engaged,
# GR_UNIT names the unit whose config this run reads, and the scoped
# machinery at the bottom of this file switches on.
gr_unit_engage

gr_check_config

# Read beside gr_check_config, and for its reason: every other config
# invariant in this toolkit is settled BEFORE any gate runs, so that a typo is
# diagnosed as a typo rather than after a page of violations. Read at the point
# of use, a bad limit reported exit 2 with the `checked:`/`problems:`/`sources:`
# lines never printed — the evidence suppressed by the error.
age_limit=$(gr_limit problem_age_days) || exit 2
open_limit=$(gr_limit problem_open_max) || exit 2
exp_age_limit=""
exp_open_limit=""
if [ -n "$GR_UNIT" ]; then
    exp_age_limit=$(gr_limit expectation_age_days) || exit 2
    exp_open_limit=$(gr_limit expectation_open_max) || exit 2
fi

# "Today" is the denominator of every age this gate computes, so a garbage
# value would not fail — it would make every age silently wrong. Two checks,
# because they catch different things and one message must not stand in for
# the other: the shell tests the SHAPE (and with it the `-v` value awk is
# about to be handed), and awk tests the CALENDAR.
today=$(date +%Y-%m-%d) || gr_die "date(1) failed; the age of an open problem cannot be established"
case "$today" in
    ([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    (*) gr_die "date +%Y-%m-%d produced '$today', which is not a date in YYYY-MM-DD form" ;;
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

foreign=""
reverse=""
deps=""
if [ -n "$GR_UNIT" ]; then
    deps=$(cfg_list depends_on)
    # Pathname expansion back ON for the unit scans: gr_unit_srs (under
    # gr_exported_reqs and gr_unit_req_scan) expands the unit's doc_srs
    # directory with a *.md glob, exactly as gr_doc_files did above before
    # set -f. Nothing here can expand by accident — gr_check_units has
    # already rejected any manifest entry containing a glob character.
    set +f
    for _dep in $deps; do
        _fx=$(gr_exported_reqs "$_dep") || exit 2
        foreign="$foreign
$(printf '%s\n' "$_fx" | cut -f1)"
    done
    for _con in $(gr_consumers_of "$GR_UNIT"); do
        _cs=$(gr_unit_req_scan "$_con") || exit 2
        reverse="$reverse
$(printf '%s\n' "$_cs" | awk -F'\t' -v me="$GR_UNIT" \
            '$3 == "EXPECTS" && $4 == me && $1 ~ /^REQ-/ { print $1 }')"
    done
    set -f
fi

# --- Unit annotations and expectations (architecture items 3 and 4) ----------
# Scoped runs only. exported:/expects:/opened: are read by gr_req_scan under
# the same column-one, first-occurrence, block-attributed rules as status:,
# and the ORPHAN-ANNOTATION backstop below is extended to match.
exempt_expect=""
exp_summary=""
if [ -n "$GR_UNIT" ]; then
    # shellcheck disable=SC2086
    own_scan=$(gr_req_scan $srs_files $rmf_files $sad_files $problems_files) || exit 2

    # MISEXPORTED-ITEM: only `exported: yes` on a REQ is an export (D8). A
    # misspelled value would read as "not exported" and strand every consumer
    # silently, so any other value — empty included — convicts, as does the
    # annotation on a non-REQ block.
    _misexp=$(printf '%s\n' "$own_scan" | awk -F'\t' '
        $3 != "EXP" { next }
        $1 !~ /^REQ-/       { printf "MISEXPORTED-ITEM %s (exported: on a non-REQ item — only requirements are exported; LLR and SDD are design data)\n", $1; next }
        $4 != "yes"         { printf "MISEXPORTED-ITEM %s (exported: %s — the only accepted value is yes; anything else reads as not exported, which strands consumers silently)\n", $1, $4 }')
    if [ -n "$_misexp" ]; then
        printf '%s\n' "$_misexp"
        fail=1
    fi

    # Expectations. Grammar first (INCOMPLETE-EXPECTATION is the one token for
    # every expectation the reader cannot read), then the computed state.
    _badexp=$(printf '%s\n' "$own_scan" | awk -F'\t' '
        $3 != "EXPECTS" { next }
        $1 !~ /^REQ-/ { printf "INCOMPLETE-EXPECTATION %s (expects: on a non-REQ item)\n", $1; next }
        $4 == ""      { printf "INCOMPLETE-EXPECTATION %s (expects: with no unit named)\n", $1 }')
    if [ -n "$_badexp" ]; then
        printf '%s\n' "$_badexp"
        fail=1
    fi

    exp_open=0
    exp_oldest=-1
    _tab=$(printf '\t')
    for _el in $(printf '%s\n' "$own_scan" \
            | awk -F'\t' '$3 == "EXPECTS" && $1 ~ /^REQ-/ && $4 != "" { print $1 "\t" $4 }'); do
        _eid=${_el%%"$_tab"*}
        _etgt=${_el#*"$_tab"}
        if ! gr_contains "$deps" "$_etgt"; then
            echo "UNDECLARED-DEPENDENCY $_eid (expects: names $_etgt, which is not in this unit's depends_on — the MISSING-TEST exemption never engages across an undeclared edge)"
            fail=1
            continue
        fi
        _eopd=$(printf '%s\n' "$own_scan" | awk -F'\t' -v i="$_eid" '$1 == i && $3 == "OPENED" { print $4; exit }')
        _eage=$(LC_ALL=C awk -v today="$today" -v opd="$_eopd" "$GR_AWK_CIVIL"'BEGIN {
            gr_date_ok(today); t = GR_DATE_DAYS
            if (!gr_date_ok(opd)) { print -1; exit }
            a = t - GR_DATE_DAYS
            if (a == -1) a = 0            # one day of clock-skew tolerance,
            print (a < 0 ? -1 : a)        # further future is rejected (as PRs)
        }')
        if [ "$_eage" -lt 0 ]; then
            echo "INCOMPLETE-EXPECTATION $_eid (opened: cannot be used — '$_eopd' is absent, not a calendar date, or more than a day in the future)"
            fail=1
            continue
        fi
        # met iff the named provider defines an EXPORTED REQ containing
        # satisfies: <this ID> — both conditions (D11; obligation
        # expectation-met-requires-export).
        # Globbing back on for the provider scan, as at the foreign/reverse
        # computation above and for the same *.md-glob reason.
        set +f
        _pscan=$(gr_unit_req_scan "$_etgt") || exit 2
        set -f
        _met=$(printf '%s\n' "$_pscan" | awk -F'\t' -v want="$_eid" '
            $3 == "EXP" && $4 == "yes" { expd[$1] = 1 }
            $3 == "SAT" && $4 == want  { sat[$1] = 1 }
            END { for (i in sat) if (i in expd) { print "met"; exit } }')
        if [ "$_met" = "met" ]; then
            continue          # an ordinary REQ again; MISSING-TEST applies
        fi
        exempt_expect="$exempt_expect
$_eid"
        exp_open=$((exp_open + 1))
        [ "$_eage" -gt "$exp_oldest" ] && exp_oldest=$_eage
        if printf '%s\n' "$own_scan" | awk -F'\t' -v i="$_eid" '$1 == i && $3 == "RC" { found = 1 } END { exit !found }'; then
            echo "UNMET-EXPECTATION $_etgt: $_eid (open $_eage days — implements a risk control, exit 1 on every run until the provider delivers or the risk is re-analyzed)"
            fail=1
        elif [ -n "$exp_age_limit" ] && [ "$_eage" -gt "$exp_age_limit" ]; then
            echo "UNMET-EXPECTATION $_etgt: $_eid (open $_eage days, limit $exp_age_limit)"
            fail=1
        else
            echo "UNMET-EXPECTATION $_etgt: $_eid (open $_eage days)"
        fi
    done
    if [ -n "$exp_open_limit" ] && [ "$exp_open" -gt "$exp_open_limit" ]; then
        _noun="open expectations"
        [ "$exp_open" -eq 1 ] && _noun="open expectation"
        echo "EXPECTATION-BACKLOG ($exp_open $_noun, limit $exp_open_limit)"
        fail=1
    fi
    _eold_txt="n/a"
    [ "$exp_oldest" -ge 0 ] && _eold_txt="$exp_oldest days"
    exp_summary="expectations: open $exp_open, oldest $_eold_txt; limits age ${exp_age_limit:-none}, open ${exp_open_limit:-none}"
fi

# ids_defined PREFIX — all finalized IDs with a `**ID**:` definition site.
# Scoped, the site must lie inside the unit: sibling items are not this run's
# items (they neither owe MISSING-TEST here nor discharge anything —
# obligation reverse-edge-discharges-nothing generalizes to every foreign
# definition), and MISPLACED-ITEM must never see them at all.
ids_defined() {
    if [ -n "$GR_UNIT" ]; then
        git grep -h --untracked -oE "$(gr_def_re "$1")" -- "$GR_UNIT" 2>/dev/null \
            | sed 's/[*:]//g' | sort -u
    else
        git grep -h --untracked -oE "$(gr_def_re "$1")" -- . "$GR_SCAN_EXCLUDE" 2>/dev/null \
            | sed 's/[*:]//g' | sort -u
    fi
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
        # Deliberately no `next`: an LLR header usually contains its own
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
#   * and a HAZ block contains no annotation of its own that a gate parses, but
#     moving it out of the RMF still blinds one: UNANALYZED-DERIVED reads
#     `assesses:` lines over $rmf_files, so a derived item assessed inside a
#     HAZ block stops being assessed when that block leaves. It fails RED, so
#     no false green — but the loss is real.
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
# extension. A `.txt` in a configured DIRECTORY, or a `.md` one level
# further down, is outside it — hence the message naming the files the key
# resolves to rather than the key's value, and not naming *.md, which is
# wrong for a single-file doc_* config.
#
# This gate is what makes the summary trustworthy: while it is green, every
# item counted in `checked:` is in a document some gate opened.
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
        (REQ) check_placement REQ doc_srs $srs_files ;;
        # shellcheck disable=SC2086
        (HAZ|RC) check_placement "$_pfx" doc_rmf $rmf_files ;;
        # shellcheck disable=SC2086
        (SDD|LLR) check_placement "$_pfx" doc_sad $sad_files ;;
        # shellcheck disable=SC2086
        (PR) check_placement PR doc_problems $problems_files ;;
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
        # A valid UNMET expectation is exempt (D10): it cannot have a
        # verifying test yet and is already reported once, accurately, by
        # UNMET-EXPECTATION above. Met, it is an ordinary REQ again.
        gr_contains "$exempt_expect" "$id" && continue
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
        # Deliberately no `next`: the header line itself usually contains the
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
# The assessment is DECLARED, not inferred. Until 2026-09-08 this was one
# free-text `git grep` per derived ID over $rmf_files, so an ID in a
# verification table, a scope note or a parenthetical read as an assessment.
# The ID is exactly what an author produces anyway — a derived item is
# normally named in the same file's verification table — so the gate could
# not tell the failure it exists to detect from compliance. Measured on one
# downstream project: 26 derived items, 25 genuinely assessed, one credited
# on a parenthetical inside a blockquote (PR-n274s7).
#
# `assesses:` is read line-wise by ids_matching through GR_AWK_ID_RUN, like
# mitigates: and implements:. The run ends at the first character that is not
# an ID, comma or space, so an assessment of one item cannot clear a second
# it names in passing. It is NOT in the ORPHAN-ANNOTATION list: an assessment
# is prose under a heading, not an item block, and a column-one `assesses:`
# belonging to no item is the normal case.
#
# Nothing here judges the assessment. It requires the author to state which
# items a passage assesses — the standard every other annotation meets.
# shellcheck disable=SC2086
assessed="$(ids_matching 'assesses:' REQ $rmf_files)
$(ids_matching 'assesses:' LLR $rmf_files)"
for id in $derived_ids; do
    gr_contains "$assessed" "$id" && continue
    echo "UNANALYZED-DERIVED $id (no 'assesses:' line in the RMF names it)"
    fail=1
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
# classify_unresolved ID — the architecture's item-2 table: a scoped reference
# that resolves against nothing classifies by where its definition actually
# lives. One git grep per unresolved ID; unresolved IDs are the rare case.
# A dependency definition wins over another unit's (it names the remedy —
# export it); a disclaimed definition never outranks either.
classify_unresolved() {
    _cid="$1"
    _sites=$(git grep -l --untracked -E "^\\*\\*${_cid}\\*\\*:" -- . "$GR_SCAN_EXCLUDE" 2>/dev/null)
    _v=""
    _d=""
    for _sf in $_sites; do
        _w=$(gr_unit_of_path "$_sf") || continue
        case "$_w" in
            (not_a_unit\ *)
                if [ -z "$_v" ]; then
                    _v="DANGLING-REF"
                    _d="(defined only in $_sf, under disclaimed path ${_w#not_a_unit } — disclaimed means outside compliance; that definition is prose, not an item)"
                fi ;;
            (*)
                if gr_contains "$deps" "$_w"; then
                    _v="NON-EXPORTED-REF"
                    _d="(defined in declared dependency $_w, but not exported: yes)"
                    break
                elif [ "$_w" != "$GR_UNIT" ]; then
                    _v="UNDECLARED-DEPENDENCY"
                    _d="(defined in unit $_w, which is not in this unit's depends_on)"
                fi ;;
        esac
    done
    [ -n "$_v" ] || { _v="DANGLING-REF"; _d="(referenced but never defined)"; }
    echo "$_v $_cid $_d"
}
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
        gr_contains "$defined" "$id" && continue
        if [ -n "$GR_UNIT" ]; then
            gr_contains "$foreign" "$id" && continue
            gr_contains "$reverse" "$id" && continue
            classify_unresolved "$id"
        else
            echo "DANGLING-REF $id (referenced but never defined)"
        fi
        fail=1
    done
fi

# --- DANGLING-FILE: a draft ledger file named in a ledger must exist --------
# finalize-docs.sh rewrites references to the files it renames, over exactly
# these files. What it cannot reach is convicted here: a reference contained in
# another worktree when the draft's own change merged and renamed it, or a
# reference in another unit's ledger, which that unit's finalize never
# scanned. Resolve, never ban — a reference to a draft that EXISTS is the
# in-flight state of every unmerged change, and a gate on the prefix alone
# would fire on every worktree doing this correctly.
#
# Scope is the rewrite's scope and not strict_paths (D3, 2026-09-08): plans
# and verification records narrate the rename, and "created as DRAFT-x.md"
# is a true sentence that must stay true. The token must look like a real
# file name, so the grammar placeholder `DRAFT-<branch>-<slug>.md` in the
# shipped ledger READMEs matches nothing. A path-shaped reference resolves
# from the repository root and then from the referencing file's own
# directory, so the relative link a markdown renderer actually follows is not
# convicted while its target exists (review finding 4). Each arm's message
# names the places it looked rather than asserting the file exists nowhere:
# in a manifest repository a path written relative to another unit's root
# resolves against neither root, and "does not exist" would be false of it
# (findings 19 and 22). A bare basename resolves against every ledger
# directory, because a bare name is how authors cite a sibling ledger.
#
# The token class is the ledger grammar's — letters, digits, underscore, dot,
# hyphen — so a draft named outside it (a + or @ in the slug) is not looked
# for; finalize renames any DRAFT-*.md, so this is narrower than the rename,
# deliberately: widening it to any non-space character makes prose match
# (review finding 18). A bare name resolves against THIS config's ledger
# directories: in a manifest repository a bare reference to another unit's
# draft is reported even while that draft exists, because a bare name across
# units is ambiguous — the path form resolves (finding 19).
file_scope=""
for f in $srs_files $rmf_files $sad_files $soup_files $problems_files; do
    [ -n "$f" ] && file_scope="${file_scope}${file_scope:+
}$f"
done
doc_dirs=""
for _key in doc_srs doc_rmf doc_sad doc_problems; do
    _d=$(cfg_get "$_key")
    [ -n "$_d" ] && [ -d "$_d" ] && doc_dirs="${doc_dirs}${doc_dirs:+
}$_d"
done
if [ -n "$file_scope" ]; then
    # shellcheck disable=SC2086
    _drefs=$(git grep -n --untracked -oE '([A-Za-z0-9_.-]+/)*DRAFT-[A-Za-z0-9_.-]+\.md' -- $file_scope)
    _st=$?
    [ "$_st" -le 1 ] || gr_die "draft reference scan failed (git grep exit $_st)"
    for _dr in $_drefs; do
        [ -n "$_dr" ] || continue
        _dfile=${_dr%%:*}
        _drest=${_dr#*:}
        _dline=${_drest%%:*}
        _dref=${_drest#*:}
        case "$_dref" in
            (*/*)
                [ -e "$_dref" ] && continue
                case "$_dfile" in (*/*) _ddir=${_dfile%/*} ;; (*) _ddir=. ;; esac
                [ -e "$_ddir/$_dref" ] && continue
                _why="names a draft ledger file found neither at the repository root nor beside the file naming it — after a merge, write the dated name" ;;
            (*)
                _found=0
                for _d in $doc_dirs; do
                    [ -e "$_d/$_dref" ] && { _found=1; break; }
                done
                [ "$_found" -eq 1 ] && continue
                _why="names a draft ledger file found in none of this config's ledger directories — after a merge, write the dated name; across units, write the path" ;;
        esac
        echo "DANGLING-FILE $_dref ($_dfile:$_dline $_why)"
        fail=1
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
# contains the age so the summary can report the oldest, F fails the run. The
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
                if (st != "open" && st != "accepted" && st != "resolved") {
                    printf "F 0 MALFORMED-STATUS %s (status: %s — expected open, accepted or resolved)\n", cur, st
                    return
                }
                if (st == "resolved") return

                # ACCEPTED — a problem the project investigated and ruled on.
                # Exempt from STALE-PROBLEM and from problem_open_max: neither
                # limit measures anything about a decision, and a project that
                # triages honestly should not reach the ceiling faster than one
                # that quietly drops things. NOT exempt from the roll-call.
                #
                # `disposition:` is required, and is the whole reason this
                # status is safe to add: without it `accepted` is a one-word
                # escape from both limits, and the gate ships its own bypass.
                # `opened:` stays required too — an accepted item still has a
                # date, it is judged as a date, and the roll-call prints it.
                # Requiring a field no reader looks at is how `accepted` came
                # to take 2020-13-45 at exit 0 while the identical value on an
                # open item was MALFORMED-DATE.
                if (st == "accepted") {
                    if (!dsp_seen || dsp == "") {
                        printf "F 0 INCOMPLETE-PROBLEM %s (accepted, no disposition:)\n", cur
                        return
                    }
                    if (!opd_seen || opd == "") {
                        printf "F 0 INCOMPLETE-PROBLEM %s (accepted, no opened:)\n", cur
                        return
                    }
                    if (!gr_date_ok(opd)) {
                        printf "F 0 MALFORMED-DATE %s (opened: %s is not a YYYY-MM-DD calendar date)\n", cur, opd
                        return
                    }
                    # WHAT THE DATE IS FOR, here. An accepted item ages against
                    # nothing, so the argument the open branch makes — a
                    # negative age compares as younger than any limit — does
                    # not apply, and there is no age to clamp. What
                    # `opened:` records on either status is WHEN the problem
                    # was raised: the reason the field is required at all,
                    # and the reason the roll-call below prints it. A date
                    # after today falsifies that record on a ruled item exactly
                    # as on an open one, so it is rejected the same way, with
                    # the same ONE day of tolerance and for the same reason —
                    # two local dates disagree by a day, and an author in
                    # UTC+13 must not be blocked on a correct item on the day
                    # they record it. Tolerated, not clamped: no age is
                    # computed here for anything to consume.
                    if (todaydays - GR_DATE_DAYS < -1) {
                        printf "F 0 MALFORMED-DATE %s (opened: %s is more than a day in the future)\n", cur, opd
                        return
                    }
                    # Both returns above leave the roll-call, as the two
                    # INCOMPLETE-PROBLEM returns do and for the same reason: the
                    # run is already red for this very item, and a roll-call
                    # line that contains the date has no honest date to print.
                    printf "A 0 ACCEPTED-PR %s (opened: %s, accepted: %s)\n", cur, opd, dsp
                    return
                }

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
            # at column one is judged wherever it appears, fenced block or not.
            #
            # That is not the whole story, and the rest was found by the same
            # review: the backstop could not tell a header from a horizontal
            # rule either, so a leading `---` switched IT off for the same span
            # and dropped every annotation in it. GR_AWK_FRONT_MATTER now
            # requires a key on line 2, which fixes both. One disagreement
            # remains and is fail-loud: an item definition pasted INSIDE a
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
                st = ""; opd = ""; dsp = ""
                st_seen = 0; opd_seen = 0; dsp_seen = 0
                if (gr_block_opens(line)) cur = gr_block_id(line)
            }
            # First occurrence wins, per keyword — the GR_AWK_ID_RUN rule
            # applied to a scalar annotation. A later line cannot reopen an
            # item the first line already closed.
            cur != "" && !st_seen  && gr_kw_here(line, "status:") { st_seen = 1;  st = gr_value(line, "status:") }
            cur != "" && !opd_seen && gr_kw_here(line, "opened:") { opd_seen = 1; opd = gr_value(line, "opened:") }
            cur != "" && !dsp_seen && gr_kw_here(line, "disposition:") { dsp_seen = 1; dsp = gr_value(line, "disposition:") }
            END { gr_prflush() }
        ' "$f" || gr_die "problem-report scan failed on $f"
    done
) || exit 2

_open_n=$(printf '%s\n' "$_prs" | grep -c '^W ' || true)
_undatable_n=$(printf '%s\n' "$_prs" | grep -c '^W -1 ' || true)
# `A` is a third line kind beside `W` and `F`, and a new LETTER rather than a
# `W` with a flag precisely so no aggregation above changes: `_open_n` and
# `_undatable_n` grep `^W `, `_oldest` matches `$1 == "W"`, and the failure
# test greps `^F `. An accepted item is therefore exempt from
# problem_open_max and from the oldest-age figure by construction, not by a
# subtraction somebody has to remember to keep in step.
_accepted_n=$(printf '%s\n' "$_prs" | grep -c '^A ' || true)
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
# `mitigates:`, `implements:`, `verifies:` and `assesses:` are read line-wise
# by ids_matching, never against a block, so they cannot be orphaned. Reporting
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
            # A BOM is in front of column one and hides it from every
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
# The union both halves of the supersession pair are read in — by the backstop
# just below and by the NON-RECIPROCAL-SUPERSESSION scan further down. One
# assignment, because a backstop reading a different file list from the reader
# it backs is not a backstop.
# shellcheck disable=SC2086
_sup_files=$(printf '%s\n' $srs_files $rmf_files $sad_files $problems_files | sort -u)
# shellcheck disable=SC2086
_orphans=$(
    check_orphans 'status:' PR $problems_files
    # The reader added `opened:` to the same block, so the backstop covers it
    # too: under a looser block rule an orphaned opened: is credited to the
    # item above, and an undated item then reads as dated.
    check_orphans 'opened:' PR $problems_files
    # Block-parsed as of PR-4fwfjp, so the backstop covers it: an orphaned
    # disposition: would otherwise be credited to nothing while the accepted
    # item above it reads as undisposed.
    #
    # Scoped to the problems ledger, where this scan reads it. `disposition:`
    # is also the review artefact's word — check-review.sh reads it on a
    # `**finding-N**:` block and has its own ORPHAN-DISPOSITION for the same
    # hole — and those records are not $problems_files, so the two gates do
    # not report each other's files.
    check_orphans 'disposition:' PR $problems_files
    check_orphans 'traces:' SDD $sad_files
    # ONE scan over the union, opening on BOTH prefixes that read `satisfies:`.
    # Two scans over two lists reported a false positive when doc_srs and
    # doc_sad resolve to the same directory: the LLR gate read the annotation
    # correctly, while the REQ-opening scan saw the LLR header close a block
    # without opening one and called the line an orphan. Opening on a prefix
    # that is misplaced in that document costs nothing — MISPLACED-ITEM is
    # already red for it.
    check_orphans 'satisfies:' 'LLR|REQ' $_sat_files
    # Block-parsed as of PR-zt5c2v, so the backstop covers both halves: an
    # orphaned `supersedes:` would otherwise be read, matched and dropped
    # while the item it was meant for reads as never superseded — and a gate
    # whose reader looks where its backstop cannot see is how the `status:`
    # reader drifted. Opening on every prefix, because the reader above does:
    # any item may replace any other of its own kind.
    check_orphans 'supersedes:'    'REQ|HAZ|RC|SDD|LLR|PR' $_sup_files
    check_orphans 'superseded-by:' 'REQ|HAZ|RC|SDD|LLR|PR' $_sup_files
) || exit 2
if [ -n "$_orphans" ]; then
    printf '%s\n' "$_orphans"
    fail=1
fi

if [ -n "$GR_UNIT" ]; then
    # shellcheck disable=SC2086
    _ann_files=$(printf '%s\n' $srs_files $rmf_files $sad_files $problems_files | sort -u)
    _orphans2=$(
        check_orphans 'exported:' 'REQ|HAZ|RC|SDD|LLR|PR' $_ann_files
        check_orphans 'expects:'  'REQ|HAZ|RC|SDD|LLR|PR' $_ann_files
        check_orphans 'opened:'   'REQ|HAZ|RC|SDD|LLR|PR' $srs_files
    ) || exit 2
    if [ -n "$_orphans2" ]; then
        printf '%s\n' "$_orphans2"
        fail=1
    fi
fi

# --- NON-RECIPROCAL-SUPERSESSION: the pair merge-change already prescribes --
# merge-change step 6a prescribes `supersedes:` on the replacement and
# `superseded-by:` on the replaced item, and no script read either word: a
# half-applied supersession was found by a human reading every site that named
# the old ID, or not at all. On the change that first used the form downstream,
# six sites were half-applied and it took two review rounds to find them.
#
# Reciprocity is the half a gate can prove. This is NOT a sweep for stale
# references to a superseded ID — an `affects:` line may name an old ID as
# history, so that has no unambiguous verdict — and existence is already
# DANGLING-REF's job, which scans every doc_* file.
#
# Column-one keyword via gr_kw_here, IDs via gr_id_run: the same pairing
# status:/opened: use, so the reader and the ORPHAN-ANNOTATION backstop look in
# the same place. Occurrences ACCUMULATE within a block rather than
# first-one-wins — the annotation is a LIST and a second such line in the same
# block adds to it — because an item may replace more than one predecessor,
# and each predecessor is judged on its own: one applied half must not answer
# for a missing one. Downstream, five of six sites were correct.
#
# `supersedes:` is not a prefix of `superseded-by:` — they part at the ninth
# character — so neither keyword's index() test can read the other's line.
#
# The canonical key is REPLACEMENT<TAB>REPLACED, built from both directions,
# which is the whole reason the two relations are comparable at all.
#
# PLACED LAST, after the triage scan and the orphan backstop, and that is not
# arbitrary. This scan opens every file both of those open, and an unreadable
# ledger is a hard exit 2 in whichever scan reaches it first. Two tests pin
# WHICH scan names it — "an unreadable problems ledger fails the run rather
# than finding nothing" wants the triage scan's message, and "an unreadable
# architecture ledger fails the orphan scan" wants the backstop's, on the one
# file no other working-tree reader opens. Running this earlier answered both
# with `supersession scan failed` and left both error paths uncovered.
if [ -n "$_sup_files" ]; then
    # The awk status is kept, and that is why the sort is a SECOND step: a
    # `awk | sort` pipeline reports sort's status, so an awk that exited 2 —
    # which is exactly what BWK awk does when a -v value contains a newline —
    # would read as a tree with no half-applied supersession in it.
    # shellcheck disable=SC2086
    _sup_raw=$(
        LC_ALL=C awk -v body="$GR_ID_BODY" \
            "$GR_AWK_ID_RUN$GR_AWK_ITEM_BLOCK"'
            # The IDs of one annotation line, and a REPORT when it contains
            # none. Without this, `split(gr_id_run(...))` over a run with no
            # readable ID recorded no key at all: NON-RECIPROCAL-SUPERSESSION
            # could not fire on a key that does not exist, and
            # ORPHAN-ANNOTATION could not either, because that backstop sees
            # only annotations OUTSIDE an item block. `supersedes: the old
            # requirement`, a mistyped ID, or a bare `supersedes:` therefore
            # read as NO SUPERSESSION AT ALL — a half-applied supersession
            # passing green, which is the case this gate exists to remove.
            #
            # MALFORMED, not INCOMPLETE: an empty value counts as absent
            # elsewhere in this file, and absent is exactly the false green
            # here. The keyword is present and states something unreadable,
            # which is what MALFORMED-STATUS and MALFORMED-DATE also name.
            # A TOKEN THAT WAS TRYING TO BE AN ID AND FAILED — the half
            # sup_run below could not see. gr_id_run returns the IDs it can
            # read and DISCARDS the rest, so ONE good ID beside ONE mistyped
            # ID left the run non-empty and this report silent:
            # `supersedes: REQ-m7dq3v, REQ-a3k9z2x` and
            # `supersedes: REQ-m7dq3v, REQ-nope` each recorded half a
            # supersession, reported nothing, and exited 0 — the very case the
            # report was added to close, one keystroke away from the all-empty
            # case it did catch. Found by the independent field review.
            #
            # THE RULE, and it is check-ids.sh MALFORMED-ID drawn at the
            # REFERENCE instead of the definition, not a second rule invented
            # here: LOOSE MINUS STRICT over the DECLARED prefixes, walked from
            # the head of the value along the same [ \t,] separators gr_id_run
            # walks. A token in LIST POSITION that opens
            # <DECLARED-PREFIX>-<alphanumerics, POSSIBLY NONE> and is not a
            # valid ID is reported. The walk STOPS at the first position that
            # opens no such token, because that is where the list ends and
            # commentary begins.
            #
            # POSSIBLY NONE is critical, and the field review had to state
            # it twice. The loose form first demanded at least one body
            # character, which made a PREFIX TRUNCATED TO ITS HYPHEN in list
            # position invisible: `supersedes: REQ-m7dq3v, REQ-` matched
            # nothing at the second entry, so the walk simply ended, the run
            # came back non-empty and the all-empty backstop below never fired
            # either — exit 0, in total silence, on half a supersession. The
            # SAME token ALONE was reported all along, so the gate called one
            # truncation a defect and the identical truncation beside a good
            # ID nothing at all. That is finding-8 recurring inside its own
            # fix. It is also what the definition rule already does:
            # gr_def_re_loose uses [^*]* and would convict `**REQ-**:`, and a
            # rule drawn at the reference has to match the one drawn at the
            # definition. Widening to * disturbs no boundary below — every
            # guard there stops on a position that opens no DECLARED PREFIX
            # AND HYPHEN at all, which an empty body does not reach — and the
            # prefix plus hyphen is at least THREE characters — RC- and PR-
            # are the shortest of the six — so RLENGTH is never zero, the
            # walk always advances, and it terminates. Three, not four: an
            # earlier version of this comment stated four and was wrong about
            # the shortest token it has to handle, which is the kind of
            # false lower bound a maintainer would re-check against after
            # adding or shortening a prefix.
            #
            # WHAT IT DELIBERATELY DOES NOT CATCH, and must not:
            #   * prose after the list. `supersedes: REQ-m7dq3v — the original
            #     dosing requirement` stops at the dash.
            #   * a parenthetical. `verifies: REQ-001 (was REQ-042)` credits
            #     REQ-001 alone everywhere in this toolkit, and the walk stops
            #     at the parenthesis for the same reason. Reporting either
            #     would convict ledgers already correctly written, which is
            #     the pattern-widening pressure MALFORMED-ID stays narrow to
            #     reject.
            #   * an undeclared prefix. `supersedes: FOO-nope` is another
            #     vocabulary, exactly as MALFORMED-ID leaves **ADR-abcdef**:
            #     alone.
            #   * a mistyped ID that appears AFTER prose has begun, which is
            #     unreachable once the walk has stopped.
            # The residue is a prose word in list position opening with a
            # declared prefix and a hyphen, e.g. `supersedes: REQ-001,
            # RC-related work`. That is the price of the boundary and it is
            # the same one MALFORMED-ID pays.
            function sup_malformed(line, kw,   v, tok, hits) {
                v = gr_value(line, kw)
                hits = 0
                while (match(v, /^[ \t,]*(REQ|HAZ|RC|SDD|LLR|PR)-[0-9A-Za-z]*/)) {
                    tok = substr(v, RSTART, RLENGTH)
                    v = substr(v, RSTART + RLENGTH)
                    sub(/^[ \t,]*/, "", tok)
                    if (tok !~ "^(REQ|HAZ|RC|SDD|LLR|PR)-" body "$") {
                        printf "MALFORMED-SUPERSESSION %s (%s %s — not an item ID)\n", cur, kw, tok
                        hits++
                    }
                }
                return hits
            }
            function sup_run(line, kw,   run, v) {
                run = gr_id_run(line, kw)
                # THE WALK SPEAKS FIRST, and the early return is what keeps it
                # to one line. `supersedes: REQ-` now falls inside BOTH paths
                # — the walk convicts the token, and the backstop below still
                # sees an empty run — and two reports naming one annotation
                # would be a regression, not twice the coverage. The walk wins
                # because it names the token that is wrong; the backstop can
                # only echo the whole value back.
                if (sup_malformed(line, kw) > 0) return run
                if (run != "") return run
                v = gr_value(line, kw)
                printf "MALFORMED-SUPERSESSION %s (%s %s)\n", cur, kw, (v == "" ? "has no value" : v " — no item ID in it")
                return ""
            }
            BEGIN { gr_block_init("REQ|HAZ|RC|SDD|LLR|PR", body) }
            FNR == 1 { sub(/^\357\273\277/, "") }
            { line = $0; sub(/\r$/, "", line) }
            gr_block_closes(line) {
                cur = gr_block_opens(line) ? gr_block_id(line) : ""
            }
            cur != "" && gr_kw_here(line, "supersedes:") {
                n = split(sup_run(line, "supersedes:"), a, " ")
                for (i = 1; i <= n; i++) if (a[i] != "") sup[cur "\t" a[i]] = 1
            }
            cur != "" && gr_kw_here(line, "superseded-by:") {
                n = split(sup_run(line, "superseded-by:"), a, " ")
                for (i = 1; i <= n; i++) if (a[i] != "") by[a[i] "\t" cur] = 1
            }
            END {
                for (k in sup) if (!(k in by)) {
                    split(k, p, "\t")
                    printf "NON-RECIPROCAL-SUPERSESSION %s (supersedes: %s, which contains no superseded-by: %s)\n", p[1], p[2], p[1]
                }
                for (k in by) if (!(k in sup)) {
                    split(k, p, "\t")
                    printf "NON-RECIPROCAL-SUPERSESSION %s (superseded-by: %s, which contains no supersedes: %s)\n", p[2], p[1], p[2]
                }
            }
        ' $_sup_files
    ) || gr_die "supersession scan failed"
    if [ -n "$_sup_raw" ]; then
        # `for (k in arr)` has unspecified order, so without this the report's
        # line order varies between awks and between runs — green on one
        # implementation and flaky on the next. Critical, not cosmetic.
        printf '%s\n' "$_sup_raw" | LC_ALL=C sort
        fail=1
    fi
fi

# --- Summary: report the denominator ----------------------------------------
# Two numbers, because one is not enough. `checked:` counts the items found;
# `sources:` counts the files and paths each gate actually read. An item count
# alone states nothing about whether the gate for those items was run at all.
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
# the backlog the limit was meant to cap.
_oldest_txt="n/a"
[ "$_oldest" -ge 0 ] && _oldest_txt="$_oldest days"
# Reported separately rather than folded into `oldest`, because it is the one
# number the age cannot represent: an item whose age is unknown is open all the
# same, and an `oldest` that quietly ignored it would read as if every open
# item had been accounted for.
#
# "no usable date", not "undated": the count includes an item whose `opened:`
# was REJECTED — malformed, or too far ahead — as well as one that has none.
# Both are open and of unknown age; only one of them is undated.
[ "$_undatable_n" -gt 0 ] && _oldest_txt="$_oldest_txt ($_undatable_n with no usable date)"
# `accepted` is reported next to `open` rather than folded into it or left
# out: it is exempt from both limits, so a reader who cannot see the number
# cannot tell a project that ruled on twelve problems from one that has none.
echo "problems: open $_open_n, accepted $_accepted_n, oldest $_oldest_txt; limits age ${age_limit:-none}, open ${open_limit:-none}"
if [ -n "$GR_UNIT" ]; then
    echo "scope: unit $GR_UNIT; foreign $(count_lines "$foreign"), reverse $(count_lines "$reverse")"
    [ -n "$exp_summary" ] && echo "$exp_summary"
    # The D10 advisory: the open expectations standing against THIS unit,
    # computed from the reverse edge and our own exports. Exit 0 — the
    # consumer's aging budget is the gate; this is the courtesy on top.
    _against=0
    for _rid in $reverse; do
        [ -n "$_rid" ] || continue
        _ans=$(printf '%s\n' "$own_scan" | awk -F'\t' -v want="$_rid" '
            $3 == "EXP" && $4 == "yes" { expd[$1] = 1 }
            $3 == "SAT" && $4 == want  { sat[$1] = 1 }
            END { for (i in sat) if (i in expd) { print "met"; exit } }')
        [ "$_ans" = "met" ] || _against=$((_against + 1))
    done
    echo "expectations against this unit: $_against open"
fi
echo "sources: srs $(count_lines "$srs_files"), rmf $(count_lines "$rmf_files"), sad $(count_lines "$sad_files"), soup $(count_lines "$soup_files"), problems $(count_lines "$problems_files"); strict $(count_lines "$strict_paths"), tests $(count_lines "$test_paths")"

exit $fail
