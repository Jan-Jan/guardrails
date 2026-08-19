#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# evidence.sh [BASE_REF] — derive the verification record's evidence block.
#
# Prints, as markdown: the suite total, how many tests are new or renamed since
# BASE_REF, how many of those go red when run against BASE_REF's scripts, and
# the name of every one that does NOT. A test that cannot go red proves no
# defect was fixed; the point of this script is that the number is DERIVED at
# merge time rather than written by hand.
#
# Every hand-maintained version of these figures in this project's history has
# been wrong at least once — stale after tests were added, counted against a
# partial run, or carried forward from a different change. Paste this output
# into the verification record verbatim, and re-run it after the last commit
# that touches scripts/ or tests/. Keep it in ONE document: two copies of a
# derived figure is the failure this script exists to end.
#
# A RENAMED test counts as new, so "new or renamed" is accurate but the figure
# is an upper bound on genuinely new coverage. A test whose name is unchanged
# but whose body was rewritten is not counted at all — undercounting, which is
# the safe direction.
#
# BASE_REF defaults to the branch checked out in the primary worktree.
# Exit codes: 0 success, 2 usage/environment error.
set -eu

dir=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$dir/.." && pwd)
cd "$root"

base="${1:-}"
if [ -z "$base" ]; then
    base=$(. "$root/scripts/lib.sh" && gr_base_branch)
fi
[ -n "$base" ] || { echo "evidence: cannot detect the base branch; pass BASE_REF" >&2; exit 2; }
git rev-parse --verify -q "$base" >/dev/null || { echo "evidence: no such ref: $base" >&2; exit 2; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT INT TERM

# The suite under BASE's scripts: current tests, base implementation.
mkdir -p "$work/base/scripts"
cp -R tests templates "$work/base/" 2>/dev/null || true
# -r so a future subdirectory under scripts/ is recursed into. Without it
# `git show base:scripts/sub` writes a tree LISTING into a file of that name,
# exits 0, and the real scripts are simply absent — every test then fails and
# the run is booked as maximum coverage.
# Modes come from the tree, not from the redirection: `git show > file` creates
# it 0644 whatever the blob's mode was, so a base whose scripts are executable
# would be staged non-executable here. A test that invokes a script BY PATH
# then fails against the base for a reason that has nothing to do with the
# base's behaviour, and gets booked as evidence that this change fixed
# something. It did not: the base was fine.
# Read from a file, not a pipe: a `while read` on the right of a `|` runs in a
# subshell, where `set -e` no longer aborts this script if a `git show` fails.
# A partial checkout would then run the suite against half a base and book the
# missing half as coverage.
git ls-tree -r "$base" scripts/ > "$work/tree.txt"
while read -r _mode _type _hash _path; do
    mkdir -p "$work/base/$(dirname "$_path")"
    git show "$base:$_path" > "$work/base/$_path"
    case "$_mode" in
        *755) chmod +x "$work/base/$_path" ;;
    esac
done < "$work/tree.txt"
_have=$(ls "$work/base/scripts"/*.sh 2>/dev/null | grep -c . || true)
[ "${_have:-0}" -gt 0 ] || { echo "evidence: no scripts checked out from $base" >&2; exit 2; }

# The suite's own .bats files. -prune keeps the vendored bats-core out: it
# ships its own fixtures, including names with spaces and tabs in them.
gr_bats_files() {
    find tests -name .bats-core -prune -o -name '*.bats' -print | sort
}

names_of() { grep -h '^@test' "$@" 2>/dev/null | sed 's/^@test "//; s/" {$//' | sort; }

names_of $(gr_bats_files) > "$work/cur.txt"
for f in $(git ls-tree -r --name-only "$base" tests/ | grep '\.bats$'); do
    git show "$base:$f"
done | grep -h '^@test' | sed 's/^@test "//; s/" {$//' | sort > "$work/base.txt"
comm -23 "$work/cur.txt" "$work/base.txt" > "$work/new.txt"

# check-signing.bats is excluded from the base run: it adds no tests here and
# its ssh-keygen fixture stalls when SSH_AUTH_SOCK points at a wedged agent.
bats=$(command -v bats || echo "$dir/.bats-core/bin/bats")
[ -x "$bats" ] || { echo "evidence: bats not found; run tests/run-tests.sh once to vendor it" >&2; exit 2; }
_files=$(gr_bats_files | grep -v check-signing)
_want=$(grep -hc '^@test' $_files | awk '{ s += $1 } END { print s + 0 }')

# `|| true` because the base run is EXPECTED to fail tests — that is the
# measurement. But a run that never happened also "fails", and every new test
# would then be absent from the pass list and booked as going red: maximum
# coverage reported for a run that did not occur. Require the TAP plan to
# match the number of tests submitted, so a run that did not happen is an
# error rather than flattering evidence.
( cd "$work/base" && SSH_AUTH_SOCK= "$bats" $_files ) > "$work/run.txt" 2>&1 || true
_plan=$(sed -n 's/^1\.\.\([0-9][0-9]*\)$/\1/p' "$work/run.txt" | head -n 1)
[ -n "$_plan" ] || {
    echo "evidence: the base run produced no TAP plan — it did not run" >&2
    sed -n '1,5p' "$work/run.txt" >&2
    exit 2
}
[ "$_plan" -eq "$_want" ] || {
    echo "evidence: base run planned $_plan tests, expected $_want" >&2
    exit 2
}

# The plan line proves the run STARTED; bats prints it before executing a
# single test. Count the result lines to prove it FINISHED. Without this a run
# killed part-way — OOM, a CI timeout, an impatient operator — leaves its
# unrun tests absent from the pass list, where they are booked as going red:
# the figures improve and nothing says the run was truncated.
_ran=$(grep -Ec '^(ok|not ok) ' "$work/run.txt" || true)
[ "${_ran:-0}" -eq "$_plan" ] || {
    echo "evidence: base run planned $_plan tests but emitted ${_ran:-0} results — it did not finish" >&2
    exit 2
}

# Counting results proves the run finished; it does not prove it ran THESE
# tests. Compare the emitted names against the submitted ones, or a run that
# emitted the right number of lines for the wrong tests — or a `# skip`
# suffix on a name — silently books those tests as going red.
sed -n 's/^ok [0-9][0-9]* //p; s/^not ok [0-9][0-9]* //p' "$work/run.txt" \
    | sed 's/ # skip.*$//' | sort > "$work/ran.txt"
grep -h '^@test' $_files | sed 's/^@test "//; s/" {$//' | sort > "$work/measured.txt"
if ! cmp -s "$work/ran.txt" "$work/measured.txt"; then
    echo "evidence: the base run did not report the tests it was given" >&2
    comm -3 "$work/measured.txt" "$work/ran.txt" | sed 's/^/  /' >&2
    exit 2
fi

# Any test NOT submitted to the base run cannot be measured, so it must not be
# counted either way. check-signing.bats is excluded above (its ssh-keygen
# fixture stalls on a wedged agent), so drop its tests from the population.
comm -12 "$work/new.txt" "$work/measured.txt" > "$work/new-measured.txt"
mv "$work/new-measured.txt" "$work/new.txt"

# The same ` # skip` strip as the identity check above. Without it a skipped
# test's pass-list entry never matches, so it drops out of the cannot-go-red
# list and is booked as evidence that a defect was fixed.
grep '^ok ' "$work/run.txt" | sed 's/^ok [0-9]* //; s/ # skip.*$//' | sort > "$work/pass.txt"
comm -12 "$work/new.txt" "$work/pass.txt" > "$work/green.txt"

# `|| true` on every count: grep -c exits 1 on an empty file, and under set -e
# that aborts — so without it the BEST possible outcome, zero tests unable to
# go red, is the one case this script cannot report.
total=$(grep -c . "$work/cur.txt" || true)
new=$(grep -c . "$work/new.txt" || true)
green=$(grep -c . "$work/green.txt" || true)
base_total=$(grep -c . "$work/base.txt" || true)
red=$((new - green))

echo "Derived by \`tests/evidence.sh $base\` — do not edit by hand."
echo
echo "- Suite: **${total} tests** (${base}: ${base_total}); ${_want} measured against \`${base}\`."
echo "- New or renamed since \`${base}\`: **${new}**."
echo "- Of those, **${red}** go red when run against \`${base}\`'s scripts."
echo "- **${green}** cannot go red, and none is counted as evidence that a"
echo "  defect was fixed:"
echo
if [ "$green" -eq 0 ]; then
    echo "  *(none)*"
else
    sed 's/^/  - `/; s/$/`/' "$work/green.txt"
fi
