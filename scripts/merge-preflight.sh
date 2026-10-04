#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# merge-preflight.sh [--before-review] [--local-base] <change-branch>
#
# The mechanical checks of merge-change steps 4 and 6c, in one command, run
# from the change worktree. Seven checks, in this order, stopping at the first
# failure:
#
#   CLEAN-TREE       `git status --porcelain` is empty.
#   BASE-MERGED      the base branch is an ancestor of HEAD, and so is
#                    origin/<base> where that ref exists. Under --local-base
#                    origin/<base> is not read, for a project that puts the
#                    remote out of scope (merge-change step 1), and the check
#                    prints `preflight: BASE-MERGED ok (local base only)`. This
#                    script never fetches; merging the base in is merge-change
#                    step 1.
#   IDS              check-ids.sh, with no --allow-draft-files.
#   TRACE            check-trace.sh.
#   UNITS            only when .guardrails/units.yaml exists, and then in place
#                    of IDS and TRACE: check-units.sh once, then check-ids.sh
#                    and check-trace.sh with GR_CONFIG=<unit>/.guardrails/
#                    config.yaml for every unit `check-units.sh --impact
#                    "refs/heads/<base>..HEAD"` prints, dependents included
#                    (skills/merge-change/references/multi-unit.md).
#   REVIEW           check-review.sh. Skipped under --before-review, which is
#                    the step 4 run: the record is written at step 6b.
#   NESTED-WORKTREE  finish-merge.sh --check <change-branch>. Its verdict "no
#                    worktree is registered for" exits 0 there and is a failure
#                    here: this script runs in the change worktree, where one is
#                    always registered, so that verdict means the wrong branch
#                    was named.
#
# A passing check prints `preflight: <CHECK> ok`; a check that does not apply
# prints `preflight: <CHECK> skipped (<reason>)`. The failing check prints the
# output of the tool it called, then one line
#
#   fix <CHECK>: <remedy>
#
# and the script exits. Nothing after the failing check runs or prints. A
# passing IDS, TRACE or UNITS check prints its tool's warnings and `fix` lines
# before its `ok` line, so an open problem report is not hidden by a pass. The
# summary block, from check-trace.sh's `checked:` line or check-units.sh's
# `units:` line to the end, is left out.
#
# Exit codes: 0 every check passed, 1 a check failed, 2 usage or environment
# error — run from the primary checkout, with a detached primary checkout, on
# the base branch, with a branch that is not the current branch, when a git
# call fails where its result is read, or when a tool the checks run exits 2.
set -u

gr_script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || exit 2
. "$gr_script_dir/lib.sh"
# NOT `cd "$(gr_root)" || exit 2`: gr_root's gr_die exits only the command
# substitution, and under dash `cd ""` returns 0 and stays put.
gr_repo_root=$(gr_root) || exit 2
cd "$gr_repo_root" || exit 2

gr_usage="usage: merge-preflight.sh [--before-review] [--local-base] <change-branch>"
branch=""
before_review=0
local_base=0
while [ $# -gt 0 ]; do
    case "$1" in
        (--before-review) before_review=1 ;;
        (--local-base) local_base=1 ;;
        (-*) gr_die "unknown argument: $1
  $gr_usage" ;;
        (*)
            [ -z "$branch" ] || gr_die "only one change branch allowed
  $gr_usage"
            branch="$1"
            ;;
    esac
    shift
done
[ -n "$branch" ] || gr_die "no change branch named
  $gr_usage"

# The primary checkout is the one whose git dir IS the common git dir. The
# checks below read the change worktree's tree and HEAD, and in the primary
# checkout those are the base branch's. Each is read with its status taken: an
# empty git dir differs from the common git dir, so a git failure would read
# as "not the primary checkout".
git_dir=$(git rev-parse --git-dir) || gr_die \
"git rev-parse --git-dir failed, so whether this is the primary checkout cannot be read."
git_common_dir=$(git rev-parse --git-common-dir) || gr_die \
"git rev-parse --git-common-dir failed, so whether this is the primary checkout cannot be read."
if [ "$git_dir" = "$git_common_dir" ]; then
    gr_die \
"this is the primary checkout. Run this from the change worktree of $branch."
fi

base=$(gr_base_branch) || gr_die \
"git worktree list failed, so the base branch cannot be read."
[ -n "$base" ] || gr_die \
"the base branch cannot be determined (the primary checkout is detached).
  Check out the base branch in the primary checkout and run this again."
[ "$branch" != "$base" ] || gr_die \
"$branch is the base branch, not a change branch. Name the change branch."

# Read with its status taken: git branch --show-current exits 0 with no output
# on a detached HEAD, so a git failure is not read as a detached HEAD.
current=$(git branch --show-current) || gr_die \
"git branch --show-current failed, so the current branch cannot be read."
[ "$current" = "$branch" ] || gr_die \
"$branch is not the current branch (HEAD is on '${current:-a detached HEAD}').
  Run this from the change worktree of $branch."

# gr_pass CHECK / gr_skip CHECK REASON — the one line a check prints when it
# does not fail.
gr_pass() { printf 'preflight: %s ok\n' "$1"; }
gr_skip() { printf 'preflight: %s skipped (%s)\n' "$1" "$2"; }

# gr_fail CHECK STATUS OUTPUT REMEDY — print the tool's output and the fix
# line, then exit: 2 when the tool reported an environment error, else 1.
gr_fail() {
    [ -z "$3" ] || printf '%s\n' "$3"
    printf 'fix %s: %s\n' "$1" "$4"
    [ "$2" -eq 2 ] && exit 2
    exit 1
}

# gr_warnings [HEADER] — print the lines of $gr_output before its summary
# block: the warnings and their `fix` lines. The block opens at `checked:`
# (check-trace.sh) or `units:` (check-units.sh), and every line after the
# opening one is summary too, including the unit-scoped lines of a GR_UNIT run.
# HEADER, when given, goes first, and only when there is something to print.
gr_warnings() {
    gr_lines=$(printf '%s\n' "$gr_output" | awk '/^(checked|units): / { exit } { print }') \
        || gr_fail "$gr_check" 2 "the output of the check could not be read." \
"run the tool the check names and resolve its error."
    [ -n "$gr_lines" ] || return 0
    [ $# -eq 0 ] || printf '%s\n' "$1"
    printf '%s\n' "$gr_lines"
}

# gr_run_tool CHECK REMEDY COMMAND... — run a sibling script, pass on exit 0,
# fail on anything else with the script's own output.
gr_run_tool() {
    gr_check=$1
    gr_remedy=$2
    shift 2
    gr_output=$("$@" 2>&1)
    gr_status=$?
    [ "$gr_status" -eq 0 ] || gr_fail "$gr_check" "$gr_status" "$gr_output" "$gr_remedy"
}

# 1. CLEAN-TREE
gr_output=$(git status --porcelain 2>&1) || gr_fail CLEAN-TREE 2 "$gr_output" \
"git status failed; run it in this worktree and resolve its error."
[ -z "$gr_output" ] || gr_fail CLEAN-TREE 1 "$gr_output" \
"commit or remove every path listed above, then run the pre-flight again."
gr_pass CLEAN-TREE

# 2. BASE-MERGED — local base first, then origin/<base> where it exists and
# --local-base was not given. git rev-parse -q --verify exits 1 for an absent
# ref, and git merge-base --is-ancestor exits 1 for a ref that is not an
# ancestor; any other status is a failure, and is not read as either state.
# Each ref is passed to git by its full name, so a tag named like the base
# branch is not read in its place (finding-91); the messages name it short.
for gr_ref in "refs/heads/$base" "refs/remotes/origin/$base"; do
    gr_ref_name=${gr_ref#refs/heads/}
    gr_ref_name=${gr_ref_name#refs/remotes/}
    if [ "$gr_ref" = "refs/remotes/origin/$base" ]; then
        [ "$local_base" -eq 0 ] || continue
        git rev-parse --verify --quiet "refs/remotes/origin/$base" >/dev/null
        gr_status=$?
        case "$gr_status" in
            (0) ;;
            (1) continue ;;
            (*) gr_fail BASE-MERGED 2 \
"git rev-parse --verify refs/remotes/origin/$base failed, so whether origin/$base exists cannot be read." \
"run git rev-parse --verify refs/remotes/origin/$base in this worktree and resolve its error." ;;
        esac
    fi
    git merge-base --is-ancestor "$gr_ref" HEAD
    gr_status=$?
    case "$gr_status" in
        (0) ;;
        (1) gr_fail BASE-MERGED 1 \
"$gr_ref_name is not an ancestor of HEAD." \
"merge the base branch into $branch as merge-change step 1 states, then run the pre-flight again." ;;
        (*) gr_fail BASE-MERGED 2 \
"git merge-base --is-ancestor $gr_ref HEAD failed, so whether $gr_ref_name is an ancestor of HEAD cannot be read." \
"run git merge-base --is-ancestor $gr_ref HEAD in this worktree and resolve its error." ;;
    esac
done
if [ "$local_base" -eq 1 ]; then
    echo "preflight: BASE-MERGED ok (local base only)"
else
    gr_pass BASE-MERGED
fi

gr_ids_remedy="fix each check-ids.sh finding above; its script header documents every rule."
gr_trace_remedy="fix each check-trace.sh finding above; its script header documents every rule."

if gr_units_present; then
    gr_skip IDS "run per unit under UNITS"
    gr_skip TRACE "run per unit under UNITS"

    # 5. UNITS — the repository-level gates, then both gates per unit of the
    # impact set.
    gr_run_tool UNITS "fix each check-units.sh finding above; its script header documents every rule." \
        sh "$gr_script_dir/check-units.sh"
    gr_warnings
    gr_run_tool UNITS "fix the unclaimed path check-units.sh names above, then run the pre-flight again." \
        sh "$gr_script_dir/check-units.sh" --impact "refs/heads/$base..HEAD"
    gr_impact=$gr_output
    # A failed awk leaves the list empty, and an empty list gates no unit and
    # passes. The status is taken from the substitution so that it fails.
    gr_units=$(printf '%s\n' "$gr_impact" | awk -F '\t' 'NF { print $1 }') \
        || gr_fail UNITS 2 "the unit column of the impact set could not be read." \
"run check-units.sh --impact refs/heads/$base..HEAD and resolve its error."
    for gr_unit in $gr_units; do
        gr_config="$gr_unit/.guardrails/config.yaml"
        gr_output=$(GR_CONFIG="$gr_config" sh "$gr_script_dir/check-ids.sh" 2>&1)
        gr_status=$?
        [ "$gr_status" -eq 0 ] || gr_fail UNITS "$gr_status" "unit $gr_unit: check-ids.sh
$gr_output" "in unit $gr_unit, $gr_ids_remedy"
        gr_warnings "unit $gr_unit: check-ids.sh"
        gr_output=$(GR_CONFIG="$gr_config" sh "$gr_script_dir/check-trace.sh" 2>&1)
        gr_status=$?
        [ "$gr_status" -eq 0 ] || gr_fail UNITS "$gr_status" "unit $gr_unit: check-trace.sh
$gr_output" "in unit $gr_unit, $gr_trace_remedy"
        gr_warnings "unit $gr_unit: check-trace.sh"
    done
    gr_pass UNITS
else
    # 3. IDS and 4. TRACE
    gr_run_tool IDS "$gr_ids_remedy" sh "$gr_script_dir/check-ids.sh"
    gr_warnings
    gr_pass IDS
    gr_run_tool TRACE "$gr_trace_remedy" sh "$gr_script_dir/check-trace.sh"
    gr_warnings
    gr_pass TRACE
    gr_skip UNITS "no .guardrails/units.yaml"
fi

# 6. REVIEW
if [ "$before_review" -eq 1 ]; then
    gr_skip REVIEW "--before-review"
else
    gr_run_tool REVIEW \
"write or complete the verification record for $branch as merge-change step 6b states." \
        sh "$gr_script_dir/check-review.sh"
    gr_pass REVIEW
fi

# 7. NESTED-WORKTREE
gr_run_tool NESTED-WORKTREE \
"for each worktree listed above, run in this worktree task-worktree.sh remove <tag> for .worktrees/$branch-<tag>, the review worktree included. If remove rejects on commits, those commits were never gated or reviewed: record each one as a finding and run task-worktree.sh discard <tag>, or, to keep the work, return to develop-change and rerun merge-change from step 1. For a worktree task-worktree.sh did not create, record the commits its branch has, then run git worktree remove <path> (no --force) and git branch -D <branch>. Then run the pre-flight again." \
    sh "$gr_script_dir/finish-merge.sh" --check "$branch"
case "$gr_output" in
    (*"no worktree is registered for"*)
        gr_fail NESTED-WORKTREE 1 "$gr_output" \
"you named the wrong branch; name the branch checked out in this worktree." ;;
esac
gr_pass NESTED-WORKTREE
exit 0
