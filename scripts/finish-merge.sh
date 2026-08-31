#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# finish-merge.sh <change-branch>
#
# The guarded tail of the signed merge command (merge-change step 7):
#
#   git commit -S -F <msgfile> && sh .guardrails/scripts/finish-merge.sh <branch>
#
# The user runs the compound. Its first half is a plain `git commit -S` they can
# read, because that is the step their hardware key answers for and it must not
# be hidden behind a wrapper. Its second half is this script, because an `&&`
# chain cannot guard anything, and what follows is `git branch -D` on a branch
# git does not consider merged — a squash leaves no merge base, so `-d` would
# refuse and `-D` is the only spelling available. Nothing in a chain stands
# between a subtly incomplete squash and unrecoverable work; this does.
#
# Three guards, all proved before anything is removed:
#
#   1. check-signing.sh --strict passes on HEAD. Always --strict: the default
#      mode passes a signature it cannot verify, and cleaning up on that is a
#      gate answering a question nobody asked.
#   2. `git diff --quiet HEAD <branch>` — merge-change step 1 already merged the
#      base branch into the change branch, so a correct squash leaves the two
#      trees identical. A difference is work the squash did not capture.
#   3. `git worktree remove` WITHOUT --force — git's own refusal of a dirty
#      worktree is the guard.
#
# A failing guard exits non-zero having removed nothing and deleted nothing. The
# signed commit always survives; only cleanup is refused, which is a safe thing
# to refuse. The fix is to run this script again ON ITS OWN — re-running the
# whole compound cannot double-commit (the squash is no longer staged, so
# `git commit` fails and `&&` short-circuits), but it wastes a key touch.
#
# There is no --force and no way to skip a guard. That is the entire point.
#
# Exit codes: 0 cleaned up, 1 a guard refused, 2 usage/environment error.
set -u

gr_script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || exit 2
. "$gr_script_dir/lib.sh"
# NOT `cd "$(gr_root)" || exit 2`: gr_root's gr_die exits only the command
# substitution, and under dash `cd ""` returns 0 and stays put. The status has
# to be taken from the substitution.
gr_repo_root=$(gr_root) || exit 2
cd "$gr_repo_root" || exit 2

# A guard refused. Exit 1, not 2: the environment is fine and the signed commit
# is already on the base branch — what is refused is only the cleanup.
gr_refuse() {
    printf '%s\n' "guardrails: $*" >&2
    exit 1
}

# Exactly one argument, the change branch — no more, no fewer, and no flags.
# There is deliberately no --force: every guard below is the point of the
# script, and an escape hatch is the one thing that would make it pointless.
#
# A SECOND branch name is not a harmless extra. Letting the last one win acts
# on one change and leaves the other's worktree and branch behind, with no
# error anywhere to notice.
branch=""
while [ $# -gt 0 ]; do
    case "$1" in
        -*) gr_die "unknown argument: $1
  usage: finish-merge.sh <change-branch>" ;;
        *)
            [ -z "$branch" ] || gr_die "only one change branch allowed
  usage: finish-merge.sh <change-branch>"
            branch="$1"
            ;;
    esac
    shift
done
[ -n "$branch" ] || gr_die "no change branch named
  usage: finish-merge.sh <change-branch>"

# Where this may run. HEAD must BE the squash commit the guards are about to
# inspect, and in a linked worktree HEAD is the change branch's tip instead —
# guard 1 would then verify the wrong commit and could pass on it. The primary
# checkout is the one whose git dir IS the common git dir.
if [ "$(git rev-parse --git-dir)" != "$(git rev-parse --git-common-dir)" ]; then
    gr_die \
"this is a linked worktree, and HEAD here is not the squash commit.
  Run this from the primary checkout, on the base branch, after the signed
  squash has landed there."
fi

# The base branch, and HEAD must be on it. Both halves are needed: an empty
# base (a detached primary checkout) compared against an empty current branch
# is EQUAL, so the comparison alone would pass over exactly the case where
# neither value means anything.
base=$(gr_base_branch)
[ -n "$base" ] || gr_die \
"the base branch cannot be determined (this checkout is detached).
  Check out the base branch — the one the signed squash landed on — and run
  this again."

current=$(git branch --show-current 2>/dev/null)
[ "$current" = "$base" ] || gr_die \
"HEAD is on '$current', not the base branch ($base).
  The signed squash is on the base branch, and that is the HEAD these guards
  must inspect."

# The named branch is a change branch that is really there. Neither of these is
# a guard failure — nothing has been proved or disproved about a squash — so
# both exit 2.
#
# Naming the base branch is refused because `git diff --quiet HEAD $base` on
# the base branch is trivially satisfied: every guard would pass, vacuously,
# and the base branch would be deleted.
[ "$branch" != "$base" ] || gr_die \
"$branch is the base branch, not a change branch. Name the change branch."

git show-ref --verify --quiet "refs/heads/$branch" || gr_die \
"no such branch: $branch. Nothing was removed and nothing was deleted."

# Guard 1 — HEAD carries a signature that verifies. Delegated WHOLE to the
# sibling gate rather than reimplemented: one definition of "signed", in the
# script whose job that is. --strict is unconditional, for the reason the
# header gives; the refusal below names the configuration that fixes it.
sh "$gr_script_dir/check-signing.sh" --strict || gr_refuse \
"HEAD's signature did not pass check-signing.sh --strict, so nothing was removed.
  The squash commit itself is unaffected. Fix the signature (or the signing
  configuration) and run this script again on its own."

# Guard 2 — the squash actually captured the change. merge-change step 1 has
# already merged the base branch into the change branch, so a correct squash
# leaves the base branch's tree IDENTICAL to the change branch's. A difference
# means something did not land: an unstaged file, a partial `git add`, or a
# base that moved between step 1 and the squash. This is the only check
# standing between an incomplete squash and `-D` destroying the difference.
git diff --quiet HEAD "$branch" || gr_refuse \
"HEAD and $branch differ, so the squash did not capture everything on that
  branch. Nothing was removed and $branch was NOT deleted — deleting it now
  would destroy the difference. Inspect it with:

    git diff HEAD $branch

  then redo the squash and run this script again on its own."

# The worktree path is DERIVED, never taken from the caller (D4). A pasted path
# is a chance to remove the wrong directory, and the branch name is already in
# the command merge-change prints. `$0` is used whole rather than a field, so a
# path containing spaces survives; a branch name cannot contain a newline, so
# nothing carrying one reaches `awk -v`.
wt=$(git worktree list --porcelain | awk -v want="branch refs/heads/$branch" '
    /^worktree / { path = substr($0, 10) }
    $0 == want { print path; exit }
')

# Guard 3 — the worktree holds nothing uncommitted. NOT reimplemented: this is
# `git worktree remove` without --force, and git's own refusal of a worktree
# carrying modified or untracked files is the guard. The removal is therefore
# both the last guard and the first destructive act, which is why the branch
# deletion comes strictly after it.
#
# No worktree registered for the branch is not an error: the harness may have
# removed it already. Tolerant about what is already gone, strict about what it
# proves — removal is skipped and the branch is still deleted.
if [ -n "$wt" ]; then
    git worktree remove "$wt" || gr_refuse \
"git refused to remove the worktree at $wt, so $branch was NOT deleted.
  A worktree carrying modified or untracked files is refused on purpose:
  --force is not passed, and nothing here overrides that. Deal with what is
  in it, then run this script again on its own."
    removed="worktree removed: $wt"
else
    removed="no worktree was registered for $branch, so none was removed"
fi

git branch -D "$branch" >/dev/null || gr_refuse \
"the worktree was removed but $branch could not be deleted."

echo "finish-merge: HEAD verified as a signed squash of $branch"
echo "finish-merge: $removed"
echo "finish-merge: branch deleted: $branch"
exit 0
