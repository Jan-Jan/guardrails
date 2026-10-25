#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# drop-plans.sh --base <ref>
#
# Leaves the change with no plan of its own, so no plan reaches the base
# branch (ADR-k3nkv3). Run in the change worktree after the verification
# record is committed (merge-change step 5); <ref> is the local base branch,
# and must be an ancestor of HEAD. Per path that
# `git diff --name-status --no-renames <ref> HEAD -- docs/plans` lists:
#
#   A  the change added it: removed (git rm).
#   M  the change edited a plan the base has: the base's version is restored.
#   D  the change deleted it: left deleted, since a deletion is allowed.
#
# Nothing to drop prints `drop-plans: no plan to drop` and commits nothing.
# Otherwise one unsigned commit, `chore: drop plans`, takes those paths and
# nothing else, and the script prints one line per path,
#
#   drop-plans: dropped <path>
#   drop-plans: restored <path>
#
# then, last,
#
#   drop-plans: read a dropped plan with git show <commit>^:<path>
#
# where <commit> is the full hash of that commit: a later review round reads
# the plan from there.
#
# Exit codes: 0 done, 2 usage or environment error — a missing, empty or
# unknown argument, a ref that does not resolve or is not an ancestor of HEAD,
# a detached HEAD, a run on the base branch, a git failure, a plan path git
# quotes (a tab, newline, double quote or backslash in its name), which
# cannot be read back line by line, or a plan path with a status other than
# A, M or D (a T, a plan whose type changed, such as to a symlink), or a plan
# path to be dropped or restored that has staged or unstaged changes.
set -u

. "$(dirname "$0")/lib.sh"
# The status is taken from the substitution: gr_die inside it exits only the
# subshell (under dash, `cd ""` returns 0 and stays put).
gr_repo_root=$(gr_root) || exit 2
cd "$gr_repo_root" || exit 2

gr_usage="usage: drop-plans.sh --base <ref>"
base_ref=
while [ $# -gt 0 ]; do
    case "$1" in
        (--base) if [ $# -lt 2 ] || [ -z "$2" ]; then
                     gr_die "--base takes a ref.
  $gr_usage"
                 fi
                 base_ref=$2
                 shift ;;
        (*) gr_die "unknown argument: $1
  $gr_usage" ;;
    esac
    shift
done
[ -n "$base_ref" ] || gr_die "no base ref named.
  $gr_usage"

# Read with its status taken: git branch --show-current exits 0 with no output
# on a detached HEAD, so a git failure is not read as a detached HEAD.
current_branch=$(git branch --show-current) || gr_die \
"git branch --show-current failed, so the current branch cannot be read."
[ -n "$current_branch" ] || gr_die \
"HEAD is detached. Run this from the change worktree, on the change branch."
base=$(gr_base_branch) || gr_die \
"git worktree list failed, so the base branch cannot be read."
[ "$current_branch" != "$base" ] || gr_die \
"$current_branch is the base branch. Run this from the change worktree."

git rev-parse -q --verify "$base_ref^{commit}" >/dev/null || gr_die \
"git cannot resolve the base ref $base_ref to a commit."
git merge-base --is-ancestor "$base_ref" HEAD
ancestor=$?
[ "$ancestor" -le 1 ] || gr_die "git merge-base --is-ancestor $base_ref HEAD failed."
[ "$ancestor" -eq 0 ] || gr_die \
"$base_ref is not an ancestor of HEAD. The base moved: merge it again by rerunning from merge-change step 1."

plans_dir=docs/plans
plan_diff=$(git -c core.quotepath=off diff --name-status --no-renames \
    "$base_ref" HEAD -- "$plans_dir") || gr_die \
"git diff $base_ref HEAD -- $plans_dir failed."

tab=$(printf '\t')
# Every path is checked before anything is touched, so a refusal leaves the
# tree as it was. The loop reads a here-document, not a pipe, so it runs in
# this shell and gr_die exits the script.
while IFS= read -r plan_diff_line; do
    [ -n "$plan_diff_line" ] || continue
    plan_status=${plan_diff_line%%"$tab"*}
    plan_path=${plan_diff_line#*"$tab"}
    case "$plan_path" in
        (\"*) gr_die "git quotes the plan path $plan_path; rename it without a tab, newline, double quote or backslash." ;;
    esac
    case "$plan_status" in
        (A|M|D) ;;
        (*) gr_die "git diff reports status $plan_status for the plan path $plan_path; drop-plans handles only A, M and D. Restore the path from $base_ref or delete it, commit, and run this again." ;;
    esac
    [ "$plan_status" != D ] || continue
    # git rm refuses a modified file, and git checkout overwrites one.
    GIT_LITERAL_PATHSPECS=1 git diff --quiet HEAD -- "$plan_path"
    plan_dirty=$?
    [ "$plan_dirty" -le 1 ] || gr_die "git diff HEAD -- $plan_path failed."
    [ "$plan_dirty" -eq 0 ] || gr_die \
"$plan_path has uncommitted changes. Commit or discard them, then run this again."
done <<EOF
$plan_diff
EOF

set --
drop_report=
while IFS= read -r plan_diff_line; do
    [ -n "$plan_diff_line" ] || continue
    plan_status=${plan_diff_line%%"$tab"*}
    plan_path=${plan_diff_line#*"$tab"}
    case "$plan_status" in
        (A) GIT_LITERAL_PATHSPECS=1 git rm -q -- "$plan_path" || gr_die "git rm $plan_path failed."
            drop_report="${drop_report}drop-plans: dropped $plan_path
" ;;
        (M) GIT_LITERAL_PATHSPECS=1 git checkout "$base_ref" -- "$plan_path" || gr_die \
"git checkout $base_ref -- $plan_path failed."
            drop_report="${drop_report}drop-plans: restored $plan_path
" ;;
        (D) continue ;;
    esac
    set -- "$@" "$plan_path"
done <<EOF
$plan_diff
EOF

if [ $# -eq 0 ]; then
    printf '%s\n' "drop-plans: no plan to drop"
    exit 0
fi

# The pathspec names only the paths dropped or restored, so other staged or
# unstaged work stays out of the commit. Every call that takes a plan path as a
# pathspec reads it literally: git reads a pathspec as a glob, so a plan named
# docs/plans/a*.md would also select a base plan such as docs/plans/a-old.md.
GIT_LITERAL_PATHSPECS=1 git -c commit.gpgsign=false commit -q -m "chore: drop plans" -- "$@" \
    || gr_die "git commit failed; the plans are dropped in the index but not committed."
drop_commit=$(git rev-parse HEAD) || gr_die "git rev-parse HEAD failed after the commit."

printf '%s' "$drop_report"
printf 'drop-plans: read a dropped plan with git show %s^:<path>\n' "$drop_commit"
