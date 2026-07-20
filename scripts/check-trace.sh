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
# Exit codes: 0 pass, 1 violations, 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
cd "$(gr_root)" || exit 2

P=$(gr_prefix_re)
[ -n "$P" ] || gr_die "id_prefixes not configured"

srs=$(cfg_get doc_srs)
rmf=$(cfg_get doc_rmf)
sad=$(cfg_get doc_sad)
soup=$(cfg_get doc_soup)
problems=$(cfg_get doc_problems)
test_paths=$(cfg_list test_paths)
strict_paths=$(cfg_list strict_paths)
fail=0

# ids_defined PREFIX — all finalized IDs with a `**ID**:` definition site
ids_defined() {
    git grep -h --untracked -oE "^\\*\\*${1}-[0-9]{3,}\\*\\*:" -- . \
        ":(exclude).guardrails" 2>/dev/null | sed 's/[*:]//g' | sort -u
}

# ids_on_lines REGEX FILE — IDs of PREFIX $2 appearing on lines matching $1
ids_matching() {
    _pat="$1"
    _pfx="$2"
    shift 2
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

# --- LLR block parse: "<id> <REQ,REQ|derived|->" per LLR in the SAD ---------
llr_info=""
if [ -f "$sad" ]; then
    llr_info=$(awk '
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
        # any other definition line or markdown heading ends the LLR block,
        # so prose below headings can never satisfy an LLR
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
    ' "$sad")
fi

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

# --- UNSATISFIED-LLR: every LLR satisfies a REQ or is marked derived --------
for id in $(printf '%s\n' "$llr_info" | awk '$2 == "-" { print $1 }'); do
    echo "UNSATISFIED-LLR $id (no 'satisfies:' REQ and not marked derived)"
    fail=1
done

# --- UNANALYZED-DERIVED: derived REQ/LLR must be assessed in the RMF --------
derived_ids=$(printf '%s\n' "$llr_info" | awk '$2 == "derived" { print $1 }')
if [ -f "$srs" ]; then
    derived_ids="$derived_ids
$(awk '
        /^\*\*REQ-[0-9][0-9][0-9]+\*\*:/ {
            cur = $0; sub(/^\*\*/, "", cur); sub(/\*\*:.*/, "", cur)
        }
        /^\*\*/ && $0 !~ /^\*\*REQ-[0-9][0-9][0-9]+\*\*:/ { cur = "" }
        /^#/ { cur = "" }
        cur != "" && /satisfies:[ \t]*derived/ { print cur; cur = "" }
    ' "$srs")"
fi
for id in $derived_ids; do
    # word-ish match: the ID must not be a prefix of a longer ID in the RMF
    if [ -f "$rmf" ] && git grep -qE --untracked -- "${id}([^0-9]|\$)" "$rmf" 2>/dev/null; then
        :
    else
        echo "UNANALYZED-DERIVED $id (derived item not assessed in the RMF)"
        fail=1
    fi
done

# --- UNMITIGATED-HAZARD: every HAZ needs an RC that mitigates it ------------
if [ -f "$rmf" ]; then
    mitigated=$(ids_matching 'mitigates:' HAZ "$rmf")
    for id in $(ids_defined HAZ); do
        contains "$mitigated" "$id" || { echo "UNMITIGATED-HAZARD $id (no risk control 'mitigates:' it)"; fail=1; }
    done
fi

# --- UNIMPLEMENTED-CONTROL: every RC needs a REQ that implements it ---------
if [ -f "$srs" ]; then
    implemented=$(ids_matching 'implements:' RC "$srs")
    for id in $(ids_defined RC); do
        contains "$implemented" "$id" || { echo "UNIMPLEMENTED-CONTROL $id (no requirement 'implements:' it)"; fail=1; }
    done
fi

# --- UNTRACED-DESIGN: every SDD block needs `traces:` naming a REQ ----------
if [ -f "$sad" ]; then
    untraced=$(awk '
        /^\*\*SDD-[0-9][0-9][0-9]+\*\*:/ {
            if (cur != "" && !ok) print cur
            cur = $0
            sub(/^\*\*/, "", cur); sub(/\*\*:.*/, "", cur)
            ok = 0
        }
        cur != "" && /traces:.*REQ-[0-9][0-9][0-9]/ { ok = 1 }
        END { if (cur != "" && !ok) print cur }
    ' "$sad")
    for id in $untraced; do
        echo "UNTRACED-DESIGN $id (no 'traces:' to a requirement)"
        fail=1
    done
fi

# --- DANGLING-REF: every referenced ID must be defined somewhere ------------
scope=""
for f in "$srs" "$rmf" "$sad" "$soup" "$problems"; do
    [ -n "$f" ] && [ -f "$f" ] && scope="$scope $f"
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
if [ -n "$problems" ] && [ -f "$problems" ]; then
    awk '
        function flush() { if (cur != "" && open) print cur }
        /^\*\*PR-[0-9][0-9][0-9]+\*\*:/ {
            flush()
            cur = $0; sub(/^\*\*/, "", cur); sub(/\*\*:.*/, "", cur)
            open = 0
        }
        # any other definition line (including draft PRs) or heading ends
        # the block, so a following item cannot leak status into this one
        /^\*\*/ && $0 !~ /^\*\*PR-[0-9][0-9][0-9]+\*\*:/ { flush(); cur = "" }
        /^#/ { flush(); cur = "" }
        cur != "" && /status:[ \t]*open/ { open = 1 }
        END { flush() }
    ' "$problems" | while IFS= read -r id; do
        [ -n "$id" ] && echo "UNRESOLVED-PR $id (open problem report — review before release)"
    done
fi

exit $fail
