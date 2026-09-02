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
# Four guards, all proved before anything is removed:
#
#   1. check-signing.sh --strict passes on HEAD. Always --strict: the default
#      mode passes a signature it cannot verify, and cleaning up on that is a
#      gate answering a question nobody asked.
#   2. `git diff --quiet HEAD <branch>` — merge-change step 1 already merged the
#      base branch into the change branch, so a correct squash leaves the two
#      trees identical. A difference is work the squash did not capture.
#   3. `git worktree remove` WITHOUT --force — git's own refusal of a dirty
#      worktree is the guard.
#   4. No registered worktree lies INSIDE the one about to be removed. Numbered
#      last because it was added last; proved before guard 3, because guard 3's
#      removal is the destructive act it exists to prevent. Guard 3 delegates to
#      git, and git's refusal cannot see a nested worktree: task worktrees live
#      at `.worktrees/<change-branch>-t<N>` inside the change worktree, that
#      directory is gitignored, so the change worktree's `git status` is clean
#      and the removal takes the nested worktree's uncommitted work with it at
#      exit 0 — leaving a `prunable` registration and an orphan branch behind.
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

# git's own registry, read ONCE and captured with its status taken. Both the
# derivation below and guard 4 read it, and neither may confuse "git failed"
# with "nothing registered": for guard 4 those two answers differ by an entire
# worktree's uncommitted work. Inside a `$(cmd | cmd)` the status belongs to
# the LAST stage, so a failing `git worktree list` there is invisible; captured
# on its own it is not.
wt_list=$(git worktree list --porcelain) || gr_die \
"git worktree list failed, so the worktrees cannot be inspected. Nothing was
  removed and $branch was NOT deleted."

# The worktree path is DERIVED, never taken from the caller (D4). A pasted path
# is a chance to remove the wrong directory, and the branch name is already in
# the command merge-change prints. `$0` is used whole rather than a field, so a
# path containing spaces survives; a branch name can contain neither a newline
# nor a backslash (git check-ref-format forbids both), so nothing that `awk -v`
# would mangle reaches it here. Guard 4's prefix test cannot make that argument
# about a PATH, which is why it is written without awk at all.
wt=$(printf '%s\n' "$wt_list" | awk -v want="branch refs/heads/$branch" '
    /^worktree / { path = substr($0, 10) }
    $0 == want { print path; exit }
') || gr_die \
"the worktree path for $branch could not be derived. Nothing was removed and
  $branch was NOT deleted."

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
    # Guard 4 — nothing is registered INSIDE $wt. Proved here, before the
    # removal below, because that removal is what destroys it.
    #
    # Written in plain shell, with no awk, and that is the point. `awk -v k=v`
    # ESCAPE-PROCESSES the value on its way into the program: `-v inside='w\top/'`
    # arrives as `w<TAB>op/`. A change worktree whose path contained a
    # backslash therefore made the prefix test match nothing, `$nested` come
    # back empty, and this guard PASS — after which guard 3 removed the change
    # worktree and took the nested worktree's uncommitted work with it, at exit
    # 0. Every other refusal in this script fails CLOSED and merely withholds
    # cleanup; this is the one whose failure loses work, so it is built out of
    # constructs that have no escape layer to get wrong: `read -r` on whole
    # lines, `${x#...}` for the prefix strip, and a `case` pattern whose
    # variable half is quoted and therefore literal.
    #
    # The subshell is deliberate. A `while read` fed by a pipe runs in one, so
    # a variable set inside it would not survive the loop — the matches are
    # PRINTED instead, and the command substitution is how they escape. The
    # input was captured and status-checked above, so nothing here can fail
    # silently; `printf` cannot fail on a string already in memory.
    #
    # The comparison is a prefix test on the paths git RECORDS, not on anything
    # resolved afresh: both sides come out of the same `git worktree list`, so
    # they are already spelled alike whatever the platform did to symlinks. The
    # trailing `/` is load-bearing — without it a sibling at `<wt>-sibling`,
    # which is not inside anything, would be reported as nested.
    nested=$(printf '%s\n' "$wt_list" | while IFS= read -r gr_line; do
        # The leading `(` on each pattern is load-bearing, not style: this
        # case sits inside a $(...) command substitution, and bash 3.2 —
        # macOS's /bin/sh — mis-parses an unparenthesised pattern's closing
        # `)` as the substitution's own, failing the WHOLE SCRIPT at parse
        # time (`syntax error near unexpected token ';;'`), before any
        # guard runs. POSIX makes the open paren optional; that shell makes
        # it mandatory here.
        case "$gr_line" in
            ("worktree "*) ;;
            (*) continue ;;
        esac
        gr_path=${gr_line#worktree }
        case "$gr_path" in
            ("$wt"/*) printf '    %s\n' "$gr_path" ;;
        esac
    done)

    if [ -n "$nested" ]; then
        # ALL of them, not the first. A five-way fan-out leaves five task
        # worktrees, and reporting one per run costs the operator five runs of
        # `check-signing.sh --strict` — a hardware key touch apiece — to learn
        # what one run already knew. Only the sentences around the list change
        # number, and an embedded newline is what tells them apart: command
        # substitution strips TRAILING newlines, so one path arrives with none
        # at all and two or more arrive with one between them.
        gr_nl='
'
        case "$nested" in
            *"$gr_nl"*)
                gr_lead="registered worktrees lie inside $wt"
                gr_them="those worktrees' files while git still had them"
                gr_deal="Deal with each of them first" ;;
            *)
                gr_lead="a registered worktree lies inside $wt"
                gr_them="that worktree's files while git still had it"
                gr_deal="Deal with the nested worktree first" ;;
        esac
        gr_refuse \
"$gr_lead:

$nested

  Removing $wt would delete $gr_them registered — uncommitted work gone,
  registrations left prunable, branches orphaned. Guard 3 cannot see this: a
  nested worktree is invisible to the outer one's \`git status\`, so
  \`git worktree remove\` does not refuse it. Nothing was removed and $branch
  was NOT deleted. $gr_deal — merge or abandon the branch, then
  \`git worktree remove\` the path — and run this script again on its own."
    fi

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
