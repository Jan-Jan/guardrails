#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# check-trace.sh
#
# Traceability gates (exit 1 with one line per violation):
#   MISSING-TEST ID          — REQ with no `verifies:` reference in test_paths
#   UNMITIGATED-HAZARD ID    — HAZ with no RC `mitigates:` line naming it
#   UNIMPLEMENTED-CONTROL ID — RC with no REQ `implements:` line naming it
#   UNTRACED-DESIGN ID       — SDD whose block has no `traces:` REQ reference
#   DANGLING-REF ID          — ID referenced in docs/strict/test paths but
#                              defined nowhere
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

# --- MISSING-TEST: every REQ needs a verifies: reference in test_paths ------
if [ -n "$test_paths" ]; then
    # shellcheck disable=SC2086
    verified=$(ids_matching 'verifies:' REQ $test_paths)
    for id in $(ids_defined REQ); do
        contains "$verified" "$id" || { echo "MISSING-TEST $id (no 'verifies:' reference in test paths)"; fail=1; }
    done
fi

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
for f in "$srs" "$rmf" "$sad" "$soup"; do
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

exit $fail
