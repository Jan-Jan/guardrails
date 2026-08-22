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
#   UNRESOLVED-PR ID         — problem report with status: open. WARNING
#                              only: listed for review, never fails the check
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
# Every run ends with `checked:` (items found per prefix) and `sources:` (the
# document files read, then the number of configured path entries — one entry
# may be a directory or a pathspec), so a pass over zero cannot be
# mistaken for a pass over sixty-three. MISPLACED-ITEM is what makes `checked:`
# trustworthy: while it is green, every item counted there sits in a document
# some gate actually opened. It covers the six gated prefixes only — an extra
# prefix has no configured document and is not placement-checked, so an item
# of one is still counted without being examined.
#
# Exit codes: 0 pass, 1 violations, 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
cd "$(gr_root)" || exit 2

gr_check_config

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
# Blocks end at any other definition line or markdown heading, so prose can
# never satisfy an LLR. Parsed per file; blocks cannot span files.
parse_llr_file() {
    awk -v body="$GR_ID_BODY" "$GR_AWK_ID_RUN"'
        # The definition form is assembled here from the library body rather
        # than written out. It is built inside awk, not passed ready-made with
        # -v: awk runs escape processing over a -v value, so a pattern carrying
        # \* arrives as a bare * and matches nothing at all — a gate that counts
        # zero items and exits 0. Measured on gawk 5.3.2: it warns that the
        # escape sequence is treated as a plain asterisk, and the pattern
        # becomes ^**LLR-... which matches no line.
        BEGIN { defre = "^\\*\\*LLR-" body "\\*\\*:" }
        function flush() {
            if (cur != "") {
                if (der) print cur " derived"
                else if (sat != "") print cur " " sat
                else print cur " -"
            }
        }
        $0 ~ defre {
            flush()
            cur = $0; sub(/^\*\*/, "", cur); sub(/\*\*:.*/, "", cur)
            sat = ""; der = 0; inblock = 1
        }
        /^\*\*/ && $0 !~ defre {
            if (cur != "") { flush(); cur = ""; inblock = 0 }
        }
        /^#/ { if (cur != "") { flush(); cur = ""; inblock = 0 } }
        inblock {
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
    untraced=$(awk -v body="$GR_ID_BODY" "$GR_AWK_ID_RUN"'
        BEGIN { defre = "^\\*\\*SDD-" body "\\*\\*:" }
        $0 ~ defre {
            if (cur != "" && !ok) print cur
            cur = $0
            sub(/^\*\*/, "", cur); sub(/\*\*:.*/, "", cur)
            ok = 0
            # deliberately no `next`: the header line itself usually carries
            # the `traces:` annotation, so it must reach the scan below
        }
        # The block ends at any other definition line or markdown heading, the
        # same rule parse_llr_file uses. Without it an unrelated `traces:` far
        # below credited an SDD that carries none of its own.
        /^\*\*/ && $0 !~ defre {
            if (cur != "" && !ok) print cur
            cur = ""; ok = 0
        }
        /^#/ {
            if (cur != "" && !ok) print cur
            cur = ""; ok = 0
        }
        cur != "" {
            run = gr_id_run($0, "traces:")
            n = split(run, a, " ")
            for (i = 1; i <= n; i++) if (a[i] ~ /^REQ-/) ok = 1
        }
        END { if (cur != "" && !ok) print cur }
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
$(awk -v body="$GR_ID_BODY" '
        BEGIN { defre = "^\\*\\*REQ-" body "\\*\\*:" }
        $0 ~ defre {
            cur = $0; sub(/^\*\*/, "", cur); sub(/\*\*:.*/, "", cur)
        }
        /^\*\*/ && $0 !~ defre { cur = "" }
        /^#/ { cur = "" }
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

# --- UNRESOLVED-PR: open problem reports are listed for review, but this ----
# --- is a WARNING — it never sets fail (DO-178C-style known-problem review) --
for f in $problems_files; do
    awk -v body="$GR_ID_BODY" '
        BEGIN { defre = "^\\*\\*PR-" body "\\*\\*:" }
        function flush() { if (cur != "" && open) print cur }
        $0 ~ defre {
            flush()
            cur = $0; sub(/^\*\*/, "", cur); sub(/\*\*:.*/, "", cur)
            open = 0
        }
        /^\*\*/ && $0 !~ defre { flush(); cur = "" }
        /^#/ { flush(); cur = "" }
        cur != "" && /status:[ \t]*open/ { open = 1 }
        END { flush() }
    ' "$f" | while IFS= read -r id; do
        [ -n "$id" ] && echo "UNRESOLVED-PR $id (open problem report — review before release)"
    done
done

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
echo "sources: srs $(count_lines "$srs_files"), rmf $(count_lines "$rmf_files"), sad $(count_lines "$sad_files"), soup $(count_lines "$soup_files"), problems $(count_lines "$problems_files"); strict $(count_lines "$strict_paths"), tests $(count_lines "$test_paths")"

exit $fail
