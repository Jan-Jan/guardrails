#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# tests/mutate.sh [DIR...] — apply every mutation script in a scratch copy of
# the tree and report the ones that cannot apply.
#
# A mutation script quotes a line of the script it mutates verbatim, so an
# ordinary change to that line stops the mutation applying. A suite of
# mutations that cannot apply is evidence of nothing while reading exactly like
# evidence of everything. Four such changes are recorded in
# docs/plans/2026-09-17-mutation-evidence.md; none of them was careless.
#
# The verdict does NOT come from the mutation's exit code. 59 of the 184
# scripts contain no self-guard, and eight of those rewrite their target
# identically and exit 0 — reporting success for having done nothing. The tree
# is checksummed here instead, from outside, and the script's own account of
# itself is not consulted.
#
# This runner answers one question — does the mutation still apply — and not
# the larger one of which tests kill it. Deriving the records' tables needs one
# full-suite run per mutation against the tree of the day, and would print
# today's figures under a merged record's heading. See D4.
#
# Exit codes: 0 every mutation applies or is retired, 1 at least one cannot,
# 2 the environment cannot answer the question.
set -eu

dir=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$dir/.." && pwd)
cd "$root"

# A mutation that cannot RUN is not a mutation that cannot APPLY. Without this
# guard a machine with no python3 reports 154 unusable scripts when the true
# figure is zero — the loudest possible false positive, and one that would send
# a reader to re-cut 154 correct anchors.
command -v python3 >/dev/null 2>&1 \
    || { echo "mutate: python3 is absent; 154 of the mutations need it" >&2; exit 2; }
git rev-parse --git-dir >/dev/null 2>&1 \
    || { echo "mutate: not a git repository; the scratch tree cannot be built" >&2; exit 2; }

[ "$#" -gt 0 ] || set -- docs/verification/*.mutations
# By MODE as well as by name, the rule tests/portability.bats already applies to
# this same directory: a mutation script that loses its `M` prefix or its `.sh`
# suffix is still a mutation and still contains the defect, and a name glob
# alone would not see it. Measured: with only `M*.sh` read, a broken script
# named BROKEN99.sh sat in a live directory and the runner reported
# `167 applied, 0 unusable`.
scripts=$(for d in "$@"; do
    [ -d "$d" ] || continue
    find "$d" -type f \( -name '*.sh' -o -perm -u+x \) 2>/dev/null
done | sort)

# Reach guard, the shape tests/portability.bats already uses. An empty result is
# "looked for nothing" as readily as "found nothing", and the two must not share
# an exit code — otherwise renaming the suites turns this gate off in silence.
[ -n "$scripts" ] \
    || { echo "mutate: no mutation scripts under $*; have they moved?" >&2; exit 2; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT INT TERM

# The scratch tree is the tracked WORKING tree, not HEAD: an anchor being re-cut
# must be testable before it is committed, or the repair loop cannot close.
# Untracked files are excluded, so stray scratch cannot alter a verdict.
git ls-files -z > "$work/manifest"
tar --null -T "$work/manifest" -cf "$work/pristine.tar"

tree_sum() { find . -type f -print0 | sort -z | xargs -0 cksum | cksum; }

applied=0
retired=0
unusable=''
for m in $scripts; do
    # A retirement is DECLARED in the script, never inferred from a failure.
    # Inferring it would make every newly broken anchor retire itself.
    if sed -n '1,10p' "$m" | grep -q '^# retired: '; then
        retired=$((retired + 1))
        continue
    fi
    rm -rf "$work/t"
    mkdir -p "$work/t"
    tar -xf "$work/pristine.tar" -C "$work/t"
    before=$(cd "$work/t" && tree_sum)
    # A DIR argument may be absolute — the bats fixtures are under
    # BATS_TEST_TMPDIR — and "$root/$m" would then name a path that is in no
    # filesystem, so every fixture mutation would exit 127 and the two fixture
    # arms would report a defect they never reached.
    case "$m" in (/*) target=$m ;; (*) target=$root/$m ;; esac
    err=$( (cd "$work/t" && sh "$target" 2>&1 >/dev/null) ) && st=0 || st=$?
    after=$(cd "$work/t" && tree_sum)

    if [ "$st" -ne 0 ]; then
        unusable="$unusable$m: exit $st: $(printf '%s' "$err" | tr '\n' ' ' | cut -c1-90)
"
    elif [ "$before" = "$after" ]; then
        unusable="$unusable$m: exit 0 but the tree is unchanged
"
    else
        applied=$((applied + 1))
    fi
done

printf 'mutations: %d applied, %d retired, %d unusable\n' \
    "$applied" "$retired" "$(printf '%s' "$unusable" | grep -c . || true)"
[ -z "$unusable" ] || { printf '%s' "$unusable" >&2; exit 1; }
