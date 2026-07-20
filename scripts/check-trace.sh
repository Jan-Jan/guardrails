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
#   UNRESOLVED-PR ID         — problem report with status: open. WARNING
#                              only: listed for review, never fails the check
#
# Each doc_* config value may be a single file or a directory of per-change
# dated *.md files (see gr_doc_files in lib.sh).
#
# Exit codes: 0 pass, 1 violations, 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
cd "$(gr_root)" || exit 2

P=$(gr_prefix_re)
[ -n "$P" ] || gr_die "id_prefixes not configured"

srs_files=$(gr_doc_files doc_srs)
rmf_files=$(gr_doc_files doc_rmf)
sad_files=$(gr_doc_files doc_sad)
soup_files=$(gr_doc_files doc_soup)
problems_files=$(gr_doc_files doc_problems)
test_paths=$(cfg_list test_paths)
strict_paths=$(cfg_list strict_paths)
fail=0

# ids_defined PREFIX — all finalized IDs with a `**ID**:` definition site
ids_defined() {
    git grep -h --untracked -oE "^\\*\\*${1}-[0-9]{3,}\\*\\*:" -- . \
        ":(exclude).guardrails" 2>/dev/null | sed 's/[*:]//g' | sort -u
}

# ids_matching PATTERN PREFIX PATHS… — IDs of PREFIX on lines matching PATTERN
ids_matching() {
    _pat="$1"
    _pfx="$2"
    shift 2
    [ $# -gt 0 ] || return 0
    git grep -h --untracked -E "$_pat" -- "$@" 2>/dev/null \
        | grep -oE "${_pfx}-[0-9]{3,}" | sort -u
}

contains() {
    case "
$1
" in *"
$2
"*) return 0 ;; esac
    return 1
}

# --- LLR block parse: "<id> <REQ,REQ|derived|->" per LLR in the SAD files ---
# Blocks end at any other definition line or markdown heading, so prose can
# never satisfy an LLR. Parsed per file; blocks cannot span files.
parse_llr_file() {
    awk '
        function flush() {
            if (cur != "") {
                if (der) print cur " derived"
                else if (sat != "") print cur " " sat
                else print cur " -"
            }
        }
        /^\*\*LLR-[0-9][0-9][0-9]+\*\*:/ {
            flush()
            cur = $0; sub(/^\*\*/, "", cur); sub(/\*\*:.*/, "", cur)
            sat = ""; der = 0; inblock = 1
        }
        /^\*\*/ && $0 !~ /^\*\*LLR-[0-9][0-9][0-9]+\*\*:/ {
            if (cur != "") { flush(); cur = ""; inblock = 0 }
        }
        /^#/ { if (cur != "") { flush(); cur = ""; inblock = 0 } }
        inblock {
            if ($0 ~ /satisfies:[ \t]*derived/) der = 1
            else if ($0 ~ /satisfies:/) {
                line = $0
                sub(/.*satisfies:/, "", line)
                n = split(line, a, /[^A-Za-z0-9-]+/)
                for (i = 1; i <= n; i++)
                    if (a[i] ~ /^REQ-[0-9][0-9][0-9]+$/)
                        sat = sat (sat == "" ? "" : ",") a[i]
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

# --- MISSING-TEST: every REQ and LLR needs a verifies: reference ------------
if [ -n "$test_paths" ]; then
    # shellcheck disable=SC2086
    verified_llr=$(ids_matching 'verifies:' LLR $test_paths)
    for id in $(ids_defined LLR); do
        contains "$verified_llr" "$id" || { echo "MISSING-TEST $id (no 'verifies:' reference in test paths)"; fail=1; }
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
        contains "$covered" "$id" || { echo "MISSING-TEST $id (no direct 'verifies:' and no tested LLR satisfies it)"; fail=1; }
    done
fi

# --- UNMITIGATED-HAZARD: every HAZ needs an RC that mitigates it ------------
if [ -n "$rmf_files" ]; then
    # shellcheck disable=SC2086
    mitigated=$(ids_matching 'mitigates:' HAZ $rmf_files)
    for id in $(ids_defined HAZ); do
        contains "$mitigated" "$id" || { echo "UNMITIGATED-HAZARD $id (no risk control 'mitigates:' it)"; fail=1; }
    done
fi

# --- UNIMPLEMENTED-CONTROL: every RC needs a REQ that implements it ---------
if [ -n "$srs_files" ]; then
    # shellcheck disable=SC2086
    implemented=$(ids_matching 'implements:' RC $srs_files)
    for id in $(ids_defined RC); do
        contains "$implemented" "$id" || { echo "UNIMPLEMENTED-CONTROL $id (no requirement 'implements:' it)"; fail=1; }
    done
fi

# --- UNTRACED-DESIGN: every SDD block needs `traces:` naming a REQ ----------
for f in $sad_files; do
    untraced=$(awk '
        /^\*\*SDD-[0-9][0-9][0-9]+\*\*:/ {
            if (cur != "" && !ok) print cur
            cur = $0
            sub(/^\*\*/, "", cur); sub(/\*\*:.*/, "", cur)
            ok = 0
        }
        cur != "" && /traces:.*REQ-[0-9][0-9][0-9]/ { ok = 1 }
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
$(awk '
        /^\*\*REQ-[0-9][0-9][0-9]+\*\*:/ {
            cur = $0; sub(/^\*\*/, "", cur); sub(/\*\*:.*/, "", cur)
        }
        /^\*\*/ && $0 !~ /^\*\*REQ-[0-9][0-9][0-9]+\*\*:/ { cur = "" }
        /^#/ { cur = "" }
        cur != "" && /satisfies:[ \t]*derived/ { print cur; cur = "" }
    ' "$f")"
done
for id in $derived_ids; do
    # word-ish match: the ID must not be a prefix of a longer ID in the RMF
    # shellcheck disable=SC2086
    if [ -n "$rmf_files" ] && git grep -qE --untracked -- "${id}([^0-9]|\$)" $rmf_files 2>/dev/null; then
        :
    else
        echo "UNANALYZED-DERIVED $id (derived item not assessed in the RMF)"
        fail=1
    fi
done

# --- DANGLING-REF: every referenced ID must be defined somewhere ------------
scope=""
for f in $srs_files $rmf_files $sad_files $soup_files $problems_files; do
    [ -f "$f" ] && scope="$scope $f"
done
for d in $strict_paths $test_paths; do
    [ -e "$d" ] && scope="$scope $d"
done
if [ -n "$scope" ]; then
    # shellcheck disable=SC2086
    referenced=$(git grep -h --untracked -oE "(${P})-[0-9]{3,}" -- $scope 2>/dev/null | sort -u)
    defined=""
    for pfx in $(cfg_get id_prefixes); do
        defined="$defined
$(ids_defined "$pfx")"
    done
    for id in $referenced; do
        contains "$defined" "$id" || { echo "DANGLING-REF $id (referenced but never defined)"; fail=1; }
    done
fi

# --- UNRESOLVED-PR: open problem reports are listed for review, but this ----
# --- is a WARNING — it never sets fail (DO-178C-style known-problem review) --
for f in $problems_files; do
    awk '
        function flush() { if (cur != "" && open) print cur }
        /^\*\*PR-[0-9][0-9][0-9]+\*\*:/ {
            flush()
            cur = $0; sub(/^\*\*/, "", cur); sub(/\*\*:.*/, "", cur)
            open = 0
        }
        /^\*\*/ && $0 !~ /^\*\*PR-[0-9][0-9][0-9]+\*\*:/ { flush(); cur = "" }
        /^#/ { flush(); cur = "" }
        cur != "" && /status:[ \t]*open/ { open = 1 }
        END { flush() }
    ' "$f" | while IFS= read -r id; do
        [ -n "$id" ] && echo "UNRESOLVED-PR $id (open problem report — review before release)"
    done
done

exit $fail
