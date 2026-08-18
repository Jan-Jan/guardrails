#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# check-ids.sh [--allow-drafts] [--base REF]
#
# Fails (exit 1) on:
#   DRAFT-ID      — draft IDs (<PREFIX>-DRAFT-<slug>-<n>) anywhere in the tree,
#                   unless --allow-drafts
#   DUPLICATE-ID  — a final ID defined (**ID**: ...) more than once in the tree;
#                   also an ID newly defined since the merge base that the base
#                   ref already defines. The base defaults to the branch checked
#                   out in the primary worktree (override with --base REF). A
#                   base NAMED with --base that does not resolve is an error.
#                   A base that cannot be used — undetectable on a detached
#                   HEAD, or detected but with no commits yet — prints
#                   SKIPPED-DUPLICATE-BASE and leaves that one gate unrun,
#                   because a skipped gate must never look like a passed one.
#                   A definition
#                   moved to another file in the same change is NOT flagged
#                   (its old line shows as removed in the diff).
#
# Exit codes: 0 pass, 1 violations, 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
cd "$(gr_root)" || exit 2

allow_drafts=0
base_named=
base=""
while [ $# -gt 0 ]; do
    case "$1" in
        --allow-drafts) allow_drafts=1 ;;
        --base)
            shift
            base="${1:-}"
            base_named=1
            [ -n "$base" ] || gr_die "--base requires a ref"
            ;;
        *) gr_die "unknown argument: $1" ;;
    esac
    shift
done

[ -n "$base" ] || base=$(gr_base_branch)

# gr_prefix_re validates each prefix as a bare identifier and dies otherwise;
# the die happens in a subshell here, so propagate it. An unvalidated
# metacharacter would make every pattern below an invalid ERE, git grep would
# error, match nothing, and this script would report a clean tree.
P=$(gr_prefix_re) || exit 2
[ -n "$P" ] || gr_die "id_prefixes not configured"

# Deliberately NOT limited to the configured prefixes, matching the pre-flight
# in finalize-ids.sh: a draft whose prefix is absent from id_prefixes is one
# that can never be minted, which is exactly the case that must not reach the
# base branch. Two gates disagreeing about what a draft is would leave a hole
# between them.
draft_re="[A-Za-z][A-Za-z0-9]*-DRAFT-[A-Za-z0-9][A-Za-z0-9-]*-[0-9]+"
def_re="^\\*\\*(${P})-[0-9]{3,}\\*\\*:"
id_re="(${P})-[0-9]{3,}"
fail=0

# --- DRAFT-ID: no draft identifiers may remain (definitions or references) ---
if [ "$allow_drafts" -eq 0 ]; then
    # Status checked, stderr not suppressed — the same rule finalize-ids.sh's
    # pre-flight applies to the same scan. A scan that errors finds nothing,
    # and "found nothing" is what a clean tree looks like.
    #
    # Defence in depth only, and honestly weak: git grep exits >1 for some
    # failures but reports others (an unreadable file, for one) on stderr while
    # still exiting 1. This catches the loud cases; the quiet ones are recorded
    # as a known gap rather than claimed as covered.
    drafts=$(git grep -In --untracked -E "$draft_re" -- . ":(exclude).guardrails")
    _st=$?
    [ "$_st" -le 1 ] || gr_die "scanning for draft IDs failed (git grep exit $_st)"
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
# A base the caller NAMED but that does not resolve is an error: they asked for
# this gate and would otherwise get a silent pass.
if [ -n "$base_named" ]; then
    git rev-parse --verify -q "$base" >/dev/null 2>&1 \
        || gr_die "--base is not a valid ref: $base"
fi

# A base that was DETECTED but does not resolve is not the caller's mistake and
# must not be fatal: gr_base_branch reports the branch name from the worktree
# list, which exists before its first commit, so a fresh repo would otherwise
# abort with a complaint about a --base nobody passed. Treat it exactly like an
# undetected base.
if [ -n "$base" ] && ! git rev-parse --verify -q "$base" >/dev/null 2>&1; then
    base=""
fi

# An undetected base is not an error either — a detached HEAD is what a normal
# CI checkout produces, and finalize-ids.sh is not run there. But it must not be
# silent: this gate simply does not run, and a run that skipped a gate must say
# so rather than look like a run that passed it.
if [ -z "$base" ]; then
    echo "SKIPPED-DUPLICATE-BASE (no usable base branch — pass --base REF to enable this gate)"
fi

if [ -n "$base" ]; then
    mb=$(git merge-base "$base" HEAD 2>/dev/null) || mb="$base"
    # git diff's failure must not read as "nothing was added": that is the
    # whole gate passing vacuously. Status checked, not swallowed.
    _d=$(git diff "$mb") || gr_die "cannot diff against $mb"
    added=$(printf '%s\n' "$_d" | grep -E "^\+\*\*(${P})-[0-9]{3,}\*\*:" \
        | grep -oE "$id_re" | sort -u || true)
    removed=$(printf '%s\n' "$_d" | grep -E "^-\*\*(${P})-[0-9]{3,}\*\*:" \
        | grep -oE "$id_re" | sort -u || true)
    for id in $added; do
        case " $removed " in *" $id "*) continue ;; esac
        # Same pathspec as finalize-ids.sh's max_final scan. Without the
        # exclusion this gate sees a definition under .guardrails/ that
        # finalize-ids deliberately ignores, so finalize mints an ID this
        # rejects as a duplicate — two gates of one sequence disagreeing, with
        # no way forward but the hand-editing merge-change forbids.
        if git grep -qE "^\\*\\*${id}\\*\\*:" "$base" \
                -- . ":(exclude).guardrails" 2>/dev/null; then
            echo "DUPLICATE-ID $id (already defined on $base)"
            fail=1
        fi
    done
fi

exit $fail
