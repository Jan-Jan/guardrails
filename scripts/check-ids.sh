#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# check-ids.sh [--allow-drafts] [--base REF]
#
# Fails (exit 1) on:
#   DRAFT-ID      — draft IDs (<PREFIX>-DRAFT-<slug>-<n>) anywhere in the tree,
#                   unless --allow-drafts
#   DUPLICATE-ID  — a final ID defined (**ID**: ...) more than once in the tree;
#                   with --base REF, also an ID newly defined since the merge
#                   base that REF already defines. A definition moved to another
#                   file in the same change is NOT flagged (its old line shows
#                   as removed in the diff).
#
# Exit codes: 0 pass, 1 violations, 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
cd "$(gr_root)" || exit 2

allow_drafts=0
base=""
while [ $# -gt 0 ]; do
    case "$1" in
        --allow-drafts) allow_drafts=1 ;;
        --base)
            shift
            base="${1:-}"
            [ -n "$base" ] || gr_die "--base requires a ref"
            ;;
        *) gr_die "unknown argument: $1" ;;
    esac
    shift
done

P=$(gr_prefix_re)
[ -n "$P" ] || gr_die "id_prefixes not configured"

draft_re="(${P})-DRAFT-[A-Za-z0-9][A-Za-z0-9-]*-[0-9]+"
def_re="^\\*\\*(${P})-[0-9]{3,}\\*\\*:"
id_re="(${P})-[0-9]{3,}"
fail=0

# --- DRAFT-ID: no draft identifiers may remain (definitions or references) ---
if [ "$allow_drafts" -eq 0 ]; then
    drafts=$(git grep -In --untracked -E "$draft_re" -- . ":(exclude).guardrails" 2>/dev/null || true)
    if [ -n "$drafts" ]; then
        printf '%s\n' "$drafts" | sed 's/^/DRAFT-ID /'
        fail=1
    fi

    # DRAFT-FILE: no draft-named ledger files may remain either
    draft_files=$(git ls-files --cached --others --exclude-standard 2>/dev/null \
        | grep -E '(^|/)DRAFT-[^/]*$' || true)
    if [ -n "$draft_files" ]; then
        printf '%s\n' "$draft_files" | sed 's/^/DRAFT-FILE /'
        fail=1
    fi
fi

# --- DUPLICATE-ID: a final ID defined at more than one site in the tree ---
dups=$(git grep -h --untracked -oE "$def_re" -- . ":(exclude).guardrails" 2>/dev/null \
    | sed 's/[*:]//g' | sort | uniq -d)
for id in $dups; do
    echo "DUPLICATE-ID $id (defined more than once in tree)"
    fail=1
done

# --- DUPLICATE-ID vs base: newly defined here, already defined on REF ---
if [ -n "$base" ]; then
    mb=$(git merge-base "$base" HEAD 2>/dev/null) || mb="$base"
    added=$(git diff "$mb" | grep -E "^\+\*\*(${P})-[0-9]{3,}\*\*:" \
        | grep -oE "$id_re" | sort -u || true)
    removed=$(git diff "$mb" | grep -E "^-\*\*(${P})-[0-9]{3,}\*\*:" \
        | grep -oE "$id_re" | sort -u || true)
    for id in $added; do
        case " $removed " in *" $id "*) continue ;; esac
        if git grep -qE "^\\*\\*${id}\\*\\*:" "$base" -- 2>/dev/null; then
            echo "DUPLICATE-ID $id (already defined on $base)"
            fail=1
        fi
    done
fi

exit $fail
