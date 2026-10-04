#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# task-worktree.sh start <tag> | merge <tag> | remove <tag> | discard <tag>
#
# Creates and retires a task worktree nested inside the change worktree. Run it
# from the change worktree; the change branch is its current branch, and the
# task worktree is `.worktrees/<change-branch>-<tag>` on branch
# `<change-branch>-<tag>`, off the change branch (worktree-discipline step 1).
#
#   start <tag>   runs `git worktree add` for the task worktree, copies into it
#                 every ignored entry of the change worktree except `.worktrees/`
#                 and `.claude/` (tests/.bats-core, for example, which a fresh
#                 checkout lacks), and prints the task worktree's absolute path
#                 as its last line. An entry whose name contains a newline or
#                 the byte \001 is not copied, and a line states it.
#   merge <tag>   merges the task branch into the change branch with --no-ff,
#                 unsigned, then removes the task worktree and deletes the task
#                 branch. A task branch with no commits merges as `Already up to
#                 date` and is removed the same way. The dispatcher runs it once,
#                 after a green task report. No fix line printed by this script
#                 or any other names it: a merge is a decision, not a remedy.
#   remove <tag>  merges nothing. It removes the task worktree and deletes the
#                 task branch only when the branch has no commit the change
#                 branch lacks. A review worktree is retired this way: a commit
#                 on it is the reviewer's work, and merging it would make the
#                 reviewer an author of the change under review.
#   discard <tag> merges nothing. It prints the commits the task branch has
#                 that the change branch lacks, then removes the task worktree
#                 and deletes the task branch with `git branch -D`, commits
#                 included. A branch with commits that remove rejects is retired
#                 this way, after each commit is recorded as a finding.
#
# merge, remove and discard act only on the task worktree at
# `.worktrees/<change-branch>-<tag>` inside this change worktree. A task branch
# checked out anywhere else is rejected, so a worktree another change worktree
# or another agent created is never removed from here.
#
# The checks run in this order, and the first that rejects stops the run:
#
#   every command   CHANGE-BUSY for a rebase in progress in the change
#                   worktree, which detaches HEAD and so is checked before the
#                   detached-HEAD exit 2; then CHANGE-BUSY for a merge,
#                   cherry-pick or revert in progress there, or an unmerged
#                   index entry, before any proof; then TASK-NESTED, keyed on
#                   the task path rather than the task branch: a worktree registered
#                   inside the task path is rejected whatever is registered
#                   at the task path (a worktree on any HEAD, or nothing) and
#                   whether or not its directory exists, so no later remedy
#                   that names `git worktree remove` of the task path, a
#                   checkout in it, or deleting it by hand leaves a nested
#                   worktree behind
#   start           WORKTREES-NOT-IGNORED, then TASK-EXISTS; then the worktree
#                   creation (TASK-NOT-CREATED) and the copy of the ignored
#                   entries (TASK-COPY-FAILED)
#   merge, remove   TASK-MISSING, TASK-NOT-REGISTERED, TASK-NOT-NESTED,
#   and discard     TASK-LOCKED, TASK-NOT-ON-BRANCH, TASK-DIRTY, TASK-DIRECTORY-MISSING
#                   (merge only), TASK-HAS-COMMITS (remove only); then the
#                   merge (merge only, TASK-CONFLICT, CHANGE-BUSY for a merge
#                   left in progress without a conflict, TASK-MERGE-FAILED), the
#                   worktree removal (TASK-NOT-REMOVED) and the branch
#                   deletion (TASK-BRANCH-NOT-DELETED)
#
# merge, remove and discard change nothing until the task worktree is proved
# to be on the task branch, unlocked, clean, and to have no worktree registered
# inside it. A task worktree whose directory was deleted while git still lists
# it is retired by remove and discard without the proofs that read its files,
# because there are no files left to read; the nested proof reads registrations,
# so it still applies. merge rejects such a task worktree. The removal is
# `git worktree remove` without --force, and nothing is deleted before it
# succeeds. merge and remove delete with `git branch -d`, not -D: git's own
# rejections of a dirty worktree and an unmerged branch remain in force.
# discard deletes with -D, because discarding the unmerged commits is its
# purpose. A conflict of this merge, or a merge git did not commit (a hook
# rejected the merge commit), is left in progress in the change worktree for
# the dispatcher to conclude or abort; once it is committed, remove <tag>
# completes the removal. No command runs while a merge, cherry-pick, revert or rebase,
# or an unmerged index entry, is in the change worktree (CHANGE-BUSY), so merge
# reports TASK-CONFLICT only for a conflict of its own merge, and remove and
# discard never act on a task whose merge is in progress. A task worktree that
# is no longer registered and whose directory
# is gone is not an error: its branch is still merged (by merge) and deleted, so a
# command can be run again after a partial failure. A task path that exists
# with nothing registered there is rejected (TASK-NOT-REGISTERED), because no
# proof can read its contents.
#
# A rejected check, or a git step that fails, prints one line in the form
# `fix <RULE>: <remedy>`. Under remove and discard the remedy for a state of the
# task worktree names the command that was run; under merge, TASK-DIRTY and
# TASK-NESTED return the task to its subagent instead:
#
#   WORKTREES-NOT-IGNORED  .worktrees/ is not ignored in the change worktree
#   TASK-EXISTS            the task worktree path or task branch already
#                          exists, or a worktree is registered at the path
#   TASK-MISSING           merge, remove or discard was given a tag with no task
#                          branch. A worktree registered at the task path is
#                          listed with the commits its HEAD has that the change
#                          branch lacks, and the remedy removes its registration
#                          after each is recorded as a finding
#   TASK-NOT-REGISTERED    merge, remove or discard was given a task branch
#                          whose task path exists with no worktree registered
#                          there. Nothing is changed; the remedy deletes the
#                          directory by hand after reading it and recording
#                          anything worth keeping as a finding
#   TASK-NOT-NESTED        the task branch is checked out outside the change
#                          worktree's .worktrees/<change-branch>-<tag>
#   TASK-NOT-ON-BRANCH     a worktree is registered at the task worktree path
#                          but its HEAD is not the task branch. Commits that
#                          HEAD has and the task branch lacks are listed, and
#                          the remedy states that each is recorded as a finding
#                          first: the checkout it names would make them
#                          unreachable, and remove would then see no commits
#   TASK-LOCKED            the task worktree is locked
#   TASK-DIRECTORY-MISSING merge was given a task worktree whose directory was
#                          deleted while git still lists it
#   TASK-DIRTY             the task worktree has uncommitted or untracked files
#   TASK-NESTED            a worktree is registered inside the task path,
#                          whatever is registered at the task path and whether
#                          or not its directory exists. The remedy is followed
#                          from the task worktree when it is on the task branch
#                          and its directory exists, and from the change
#                          worktree otherwise
#   TASK-NOT-CREATED       git worktree add failed, and nothing was created
#   TASK-COPY-FAILED       the task worktree was created, but an ignored entry
#                          was not copied into it. The remedy copies it by hand,
#                          or retires the worktree with remove
#   CHANGE-BUSY            any command found a rebase, merge, cherry-pick or
#                          revert in progress in the change worktree, or an
#                          unmerged index entry. Nothing is changed; the remedy
#                          concludes or aborts it, then the dispatcher repeats
#                          its step for the task (develop-change) under merge,
#                          and runs the same command again under remove and
#                          discard. Under start, the remedy states that the
#                          operation belongs to the dispatcher of the change
#                          worktree, which concludes or aborts it, that a
#                          dispatched subagent stops and reports the line
#                          without acting on it, and that start is then run
#                          again. A merge whose MERGE_HEAD is the task
#                          branch tip is the merge of this task: the remedy
#                          concludes it and runs remove, or aborts it and
#                          repeats the dispatcher's step, and never discards.
#                          merge prints the same remedy, stating that the merge
#                          was not committed, when its own merge stops without a
#                          conflict and leaves MERGE_HEAD at the task branch tip
#                          (a hook rejected the merge commit, for example)
#   TASK-CONFLICT          the merge of the task branch conflicted, and
#                          MERGE_HEAD is the task branch tip
#   TASK-MERGE-FAILED      the merge failed and left no merge of the task
#                          branch in progress, so nothing was merged or
#                          removed. The cause is in the change worktree; once
#                          it is cleared, the dispatcher repeats its step for
#                          the task (develop-change)
#   TASK-HAS-COMMITS       remove was given a branch with commits
#   TASK-NOT-REMOVED       git rejected the removal of the task worktree. Under
#                          merge the task branch is already merged and remove
#                          retires it; under remove and discard nothing was
#                          changed, and the same command retires it once the
#                          cause is cleared (under discard, once each commit
#                          is recorded as a finding)
#   TASK-BRANCH-NOT-DELETED the task worktree was removed, or none was
#                          registered, and git rejected the branch deletion.
#                          The remedy is git branch -d under merge and remove,
#                          and git branch -D under discard once each commit
#                          listed is recorded as a finding
#
# Exit codes: 0 done, 1 a check rejected the run or git rejected a step,
# 2 usage or environment error (the primary checkout, a detached HEAD with no
# rebase in progress, a tag that is empty, begins with `-`, contains `/` or
# whitespace, or makes `<change-branch>-<tag>` a name git check-ref-format
# rejects as a branch name, or a git call that fails where its result is read).
#
# Every revision argument that names the task branch or the change branch is
# given to git as `refs/heads/<branch>`: git resolves a bare name that is also
# a tag to the tag.
set -u

gr_script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || exit 2
. "$gr_script_dir/lib.sh"
# NOT `cd "$(gr_root)" || exit 2`: under dash `cd ""` returns 0, so the status
# has to be taken from the substitution (finish-merge.sh states the same).
gr_repo_root=$(gr_root) || exit 2
cd "$gr_repo_root" || exit 2

gr_usage="usage: task-worktree.sh start <tag> | merge <tag> | remove <tag> | discard <tag>"

# A check rejected the run: print the remedy line and exit 1.
gr_fix() {
    printf 'fix %s: %s\n' "$1" "$2"
    exit 1
}

[ $# -eq 2 ] || gr_die "expected a command and a tag
  $gr_usage"
subcommand=$1
tag=$2
case "$subcommand" in
    (start|merge|remove|discard) ;;
    (*) gr_die "unknown command: $subcommand
  $gr_usage" ;;
esac
case "$tag" in
    ("") gr_die "the tag is empty
  $gr_usage" ;;
    (*/*|*[[:space:]]*) gr_die "the tag '$tag' contains a slash or whitespace
  $gr_usage" ;;
    (-*) gr_die "the tag '$tag' begins with '-'
  $gr_usage" ;;
esac
# The task branch is `<change-branch>-<tag>`. The tag contains no `/`, so it
# is part of the last component of that name, after a `-`: no rule of git
# check-ref-format applies across the `-`, and the name is valid exactly when
# `task-<tag>` is, for any valid change branch. The tag is checked here, before
# the change branch is read, so a rejected tag exits 2 for every command
# whatever state the change worktree is in. Without --branch, git
# check-ref-format exits 1 for an invalid name, so another status is a git
# failure.
git check-ref-format "refs/heads/task-$tag"
check_ref_format_status=$?
case "$check_ref_format_status" in
    (0) ;;
    (1) gr_die "the tag '$tag' makes <change-branch>-$tag, which is not a valid branch name (git help check-ref-format)
  $gr_usage" ;;
    (*) gr_die "git check-ref-format failed, so whether the tag '$tag' makes a valid branch name cannot be read." ;;
esac

# The primary checkout is the one whose git dir is the common git dir. A task
# worktree is nested inside a change worktree, never inside the primary one.
# Each is read with its status taken: an empty git dir differs from the common
# git dir, so a git failure would read as "not the primary checkout".
git_dir=$(git rev-parse --git-dir) || gr_die \
"git rev-parse --git-dir failed, so whether $gr_repo_root is the primary checkout cannot be read."
git_common_dir=$(git rev-parse --git-common-dir) || gr_die \
"git rev-parse --git-common-dir failed, so whether $gr_repo_root is the primary checkout cannot be read."
if [ "$git_dir" = "$git_common_dir" ]; then
    gr_die "this is the primary checkout. Run this from the change worktree."
fi

# Read with its status taken: git branch --show-current exits 0 with no output
# on a detached HEAD, so a git failure is not read as a detached HEAD.
change_branch=$(git branch --show-current) || gr_die \
"git branch --show-current failed, so the change branch in $gr_repo_root cannot be read."
# change_busy OPERATION CONCLUDE ABORT RETURN: print the CHANGE-BUSY line for
# OPERATION, which is in progress in the change worktree, and exit 1. CONCLUDE
# and ABORT end the operation, and RETURN is the step after them. Under start,
# the remedy assigns the operation to the dispatcher: develop-change dispatches
# a subagent that runs start, while the operation in the change worktree (a
# base merge, or a task merge stopped at TASK-CONFLICT) is the dispatcher's,
# and an abort run by the subagent would discard the dispatcher's partial
# resolution. merge, remove and discard are run by the dispatcher, so their
# remedy is addressed to the agent that runs the command.
change_busy() {
    if [ "$subcommand" = start ]; then
        gr_fix CHANGE-BUSY \
"$1, so nothing was changed. The operation belongs to the dispatcher of the change worktree: a dispatched subagent stops and reports this line without acting on it, and the dispatcher concludes it ($2) or aborts it ($3); then run start $tag again."
    fi
    gr_fix CHANGE-BUSY "$1, so nothing was changed; conclude it ($2) or abort it ($3), then $4."
}

# A rebase in progress detaches HEAD, so it is detected here, for every
# command, before the detached-HEAD exit. The paths come from git rev-parse
# --git-path, so a linked worktree's own git dir is read. Each is read with
# its status taken, so a git failure is not read as "no rebase in progress".
if [ -z "$change_branch" ]; then
    rebase_merge_path=$(git rev-parse --git-path rebase-merge) || gr_die \
"git rev-parse --git-path rebase-merge failed, so whether an operation is in progress in $gr_repo_root cannot be read."
    rebase_apply_path=$(git rev-parse --git-path rebase-apply) || gr_die \
"git rev-parse --git-path rebase-apply failed, so whether an operation is in progress in $gr_repo_root cannot be read."
    if [ -d "$rebase_merge_path" ] || [ -d "$rebase_apply_path" ]; then
        if [ "$subcommand" = merge ]; then
            rebase_return_step="repeat the dispatcher's step for this task (develop-change)"
        else
            rebase_return_step="run $subcommand $tag again"
        fi
        # core.editor=true: after a conflict, rebase --continue on the merge
        # backend opens an editor for the commit message, and with no editor
        # it exits 1 (finding-90).
        change_busy "a rebase is in progress in $gr_repo_root" \
            "resolve any conflict, then git -c commit.gpgsign=false -c core.editor=true rebase --continue" \
            "git rebase --abort" "$rebase_return_step"
    fi
fi
[ -n "$change_branch" ] || gr_die \
"HEAD is detached, so there is no change branch. Check out the change branch."

task_branch="$change_branch-$tag"
task_path="$gr_repo_root/.worktrees/$task_branch"

# A merge, cherry-pick or revert in progress in the change worktree, or an
# unmerged index entry, rejects every command before any proof or change. Under
# merge, git rejects the merge before it starts, and the unmerged entries it
# leaves would otherwise read as this merge's conflict. Under remove and
# discard, the merge in progress can be the merge of this task, stopped at
# TASK-CONFLICT: its commits are the work the task reported, so remove would
# misreport them as never gated (TASK-HAS-COMMITS) and discard would delete the
# branch MERGE_HEAD names. Under start, the new task branch would start from a
# change branch that lacks the operation being concluded. The paths come from
# git rev-parse --git-path, so a linked worktree's own git dir is read. Every
# git call here is read with its status taken, so a git failure is not read as
# "nothing in progress". MERGE_HEAD is verified only when its file exists:
# rev-parse --verify exits 1 for an absent MERGE_HEAD as well as for a failure.
if [ "$subcommand" = merge ]; then
    busy_return_step="repeat the dispatcher's step for this task (develop-change)"
else
    busy_return_step="run $subcommand $tag again"
fi
busy_operation=
busy_conclude="git -c commit.gpgsign=false commit --no-edit"
merge_head_path=$(git rev-parse --git-path MERGE_HEAD) || gr_die \
"git rev-parse --git-path MERGE_HEAD failed, so whether an operation is in progress in $gr_repo_root cannot be read."
cherry_pick_head_path=$(git rev-parse --git-path CHERRY_PICK_HEAD) || gr_die \
"git rev-parse --git-path CHERRY_PICK_HEAD failed, so whether an operation is in progress in $gr_repo_root cannot be read."
revert_head_path=$(git rev-parse --git-path REVERT_HEAD) || gr_die \
"git rev-parse --git-path REVERT_HEAD failed, so whether an operation is in progress in $gr_repo_root cannot be read."
unmerged_entries=$(git ls-files -u) || gr_die \
"git ls-files -u failed, so whether an operation is in progress in $gr_repo_root cannot be read."
merge_head=
if [ -e "$merge_head_path" ]; then
    merge_head=$(git rev-parse -q --verify MERGE_HEAD) || gr_die \
"git rev-parse --verify MERGE_HEAD failed, so whether an operation is in progress in $gr_repo_root cannot be read."
fi
if [ -n "$merge_head" ]; then
    # The task branch tip, or nothing when the branch does not exist. git
    # show-ref exits 1 for an absent branch and otherwise non-zero for a
    # failure, so a failure is not read as an absent branch, and the merge of
    # this task is not read as another merge.
    merge_task_tip=
    git show-ref --verify --quiet "refs/heads/$task_branch"
    show_ref_status=$?
    case "$show_ref_status" in
        (0)
            merge_task_tip=$(git rev-parse --verify "refs/heads/$task_branch") || gr_die \
"git rev-parse --verify refs/heads/$task_branch failed, so whether an operation is in progress in $gr_repo_root cannot be read." ;;
        (1) ;;
        (*) gr_die \
"git show-ref --verify refs/heads/$task_branch failed, so whether an operation is in progress in $gr_repo_root cannot be read." ;;
    esac
    if [ "$merge_head" = "$merge_task_tip" ]; then
        # The merge of this task: concluding it merges the reported work, and
        # remove then retires the branch. Aborting it returns the decision to
        # the dispatcher. No remedy names discard or a merging command.
        if [ "$subcommand" = start ]; then
            change_busy "the merge of $task_branch, this task's branch, is in progress in the change worktree $gr_repo_root" \
                "resolve any conflict, then git -c commit.gpgsign=false commit --no-edit, then run remove $tag" \
                "git merge --abort" ""
        fi
        gr_fix CHANGE-BUSY \
"the merge of $task_branch, this task's branch, is in progress in the change worktree $gr_repo_root, so nothing was changed; conclude it (resolve any conflict, then git -c commit.gpgsign=false commit --no-edit), then run remove $tag; or abort it (git merge --abort), then repeat the dispatcher's step for this task (develop-change)."
    fi
    merge_branch_names=$(git for-each-ref --points-at="$merge_head" \
        --format='%(refname:short)' refs/heads/) || gr_die \
"git for-each-ref --points-at failed, so whether an operation is in progress in $gr_repo_root cannot be read."
    merge_name=$(printf '%s\n' "$merge_branch_names" | sed -n 1p)
    if [ -z "$merge_name" ]; then
        merge_name=$(git rev-parse --short "$merge_head") || gr_die \
"git rev-parse --short failed, so whether an operation is in progress in $gr_repo_root cannot be read."
    fi
    busy_operation="a merge of $merge_name"
    busy_abort="git merge --abort"
elif [ -e "$cherry_pick_head_path" ]; then
    busy_operation="a cherry-pick"
    busy_abort="git cherry-pick --abort"
elif [ -e "$revert_head_path" ]; then
    busy_operation="a revert"
    busy_abort="git revert --abort"
elif [ -n "$unmerged_entries" ]; then
    busy_operation="a conflict resolution (the index has unmerged entries)"
    busy_conclude="git add each resolved path, then git -c commit.gpgsign=false commit -m <message>"
    busy_abort="git checkout HEAD -- <path> for each unmerged path"
fi
if [ -n "$busy_operation" ]; then
    change_busy "$busy_operation is in progress in the change worktree $gr_repo_root" \
        "resolve any conflict, then $busy_conclude" "$busy_abort" "$busy_return_step"
fi

# The registered path of the worktree that has $1 checked out, or nothing.
# Reads `$wt_list`, as gr_nested_worktrees does.
# Plain shell rather than awk: a path must not pass through `awk -v`, which
# escape-processes it (lib.sh, gr_nested_worktrees).
worktree_of_branch() {
    printf '%s\n' "$wt_list" | while IFS= read -r line; do
        case "$line" in
            ("worktree "*) path=${line#worktree } ;;
            ("branch refs/heads/$1") printf '%s\n' "$path"; break ;;
        esac
    done
}

# The porcelain lines git records for the worktree registered at $1, without
# its `worktree` line, or nothing when no worktree is registered there. Reads
# `$wt_list`, in plain shell for the reason worktree_of_branch states.
worktree_record() {
    path=
    printf '%s\n' "$wt_list" | while IFS= read -r line; do
        case "$line" in
            ("worktree "*) path=${line#worktree } ;;
            ("") path= ;;
            (*) [ "$path" != "$1" ] || printf '%s\n' "$line" ;;
        esac
    done
}

# Read once with its status taken, so a git failure is not read as "nothing
# registered".
wt_list=$(git worktree list --porcelain) || gr_die \
"git worktree list failed, so the worktrees cannot be inspected."
# The worktree registered at the task path, found by its path rather than by
# its branch: it can be on a detached HEAD, on another branch, or have no
# directory left. The path is compared as git records it, against $task_path,
# which is built from gr_root.
task_record=$(worktree_record "$task_path")
task_head=$(printf '%s\n' "$task_record" | sed -n 's/^HEAD //p')

# git show-ref exits 1 for an absent branch and otherwise non-zero for a
# failure, so a failure is not read as an absent branch: TASK-MISSING would
# then name the removal of a registration whose branch has commits.
git show-ref --verify --quiet "refs/heads/$task_branch"
show_ref_status=$?
case "$show_ref_status" in
    (0) task_branch_exists=yes ;;
    (1) task_branch_exists=no ;;
    (*) gr_die \
"git show-ref --verify refs/heads/$task_branch failed, so whether the task branch exists cannot be read." ;;
esac

# What follows a remedy for a state the task worktree is in. Under merge it
# names no merging command: work the dispatch report does not cover goes back
# to the task's subagent, which reports again, and the dispatcher decides
# afresh.
if [ "$subcommand" = merge ]; then
    return_step="the task goes back to its subagent (develop-change), which reports again."
else
    return_step="run $subcommand $tag again."
fi

# TASK-NESTED runs first, for every command, and is keyed on the task path,
# not on the task branch: a worktree registered inside the task path is found
# whatever is registered at the task path (a worktree on the task branch, on a
# detached HEAD or on another branch, or nothing) and whether or not its
# directory exists. Every later remedy that names git worktree remove of the
# task path, a checkout in it, or deleting it by hand would leave the nested
# registration and its branch behind. The paths are the ones git records, so a
# nested worktree is found when the task directory was deleted too.
nested=$(gr_nested_worktrees "$task_path")
if [ -n "$nested" ]; then
    printf '%s\n' "$nested"
    case "
$task_record
" in
        (*"
branch refs/heads/$task_branch
"*) task_on_branch=yes ;;
        (*) task_on_branch=no ;;
    esac
    # The same two cases, in the same words, as finish-merge.sh's
    # gr_nested_remedy, with this task branch as the containing branch.
    if [ "$task_on_branch" = yes ] && [ -d "$task_path" ]; then
        gr_fix TASK-NESTED \
"for each worktree listed above: for a path .worktrees/$task_branch-<tag>, run task-worktree.sh remove <tag> from $task_path, the task worktree that contains it, or, if remove rejects on commits, record each one as a finding and run task-worktree.sh discard <tag>; for a worktree task-worktree.sh did not create, record the commits its branch has, then run git worktree remove <path> (no --force) and git branch -D <branch>, which merge nothing. Then $return_step"
    fi
    # task-worktree.sh cannot be run from the task path: its directory is
    # missing, it is not a registered worktree, or its HEAD is not the task
    # branch, so the change branch task-worktree.sh would read there is not
    # $task_branch. git worktree remove exits 0 on a registered path whose
    # directory is missing.
    if [ -z "$task_record" ]; then
        nested_reason="is not a registered worktree"
    elif [ ! -d "$task_path" ]; then
        nested_reason="is missing"
    else
        nested_reason="is not on $task_branch, so task-worktree.sh cannot be run from it"
    fi
    if [ "$task_branch_exists" = yes ]; then
        log_base=$task_branch
    else
        log_base=$change_branch
    fi
    gr_fix TASK-NESTED \
"$task_path $nested_reason, and the worktrees listed above are registered inside it; from $gr_repo_root, for each listed path: record as a finding each commit its branch has that $log_base lacks (git log --oneline refs/heads/$log_base..refs/heads/<branch>, with <branch> from git worktree list --porcelain), then run git worktree remove <path> (no --force) and git branch -D <branch>, which merge nothing. For a path .worktrees/$task_branch-<tag>, <branch> is $task_branch-<tag>, and these steps discard its commits, as task-worktree.sh discard <tag> does. Then $return_step"
fi

# A task path with no task branch is left from an earlier dispatch. A worktree
# registered there is listed with the commits its HEAD has that the change
# branch lacks: removing the registration makes them unreachable.
leftover_step=
if [ "$task_branch_exists" = no ]; then
    if [ -n "$task_record" ]; then
        git log --oneline "refs/heads/$change_branch..$task_head" || gr_die \
"git log failed, so the commits on the HEAD of $task_path cannot be listed."
        leftover_step="record each commit listed above as a finding, then remove the registration with git worktree remove $task_path (no --force), which merges nothing"
    elif [ -e "$task_path" ]; then
        leftover_step="it is not a registered worktree; delete it by hand after reading it"
    fi
fi

if [ "$subcommand" = start ]; then
    # git check-ignore exits 1 for a path that is not ignored and otherwise
    # non-zero for a failure, so a failure is not read as "not ignored".
    git check-ignore -q .worktrees/
    check_ignore_status=$?
    case "$check_ignore_status" in
        (0) ;;
        (1) gr_fix WORKTREES-NOT-IGNORED \
"add .worktrees/ to .gitignore on the change branch and commit it, then run start again." ;;
        (*) gr_die \
"git check-ignore failed, so whether .worktrees/ is ignored in $gr_repo_root cannot be read." ;;
    esac

    if [ -e "$task_path" ] || [ -n "$task_record" ] || [ "$task_branch_exists" = yes ]; then
        gr_fix TASK-EXISTS \
"$task_path or branch $task_branch already exists; choose another tag. If either is left from an earlier dispatch, retire it with remove $tag; if remove rejects on commits, record each one as a finding, and only then run discard $tag. A worktree registered at $task_path with no branch, with or without its directory, is removed with git worktree remove $task_path once each commit listed above is recorded as a finding; a directory git worktree list does not name is deleted by hand after reading it."
    fi

    # Listed before the worktree is added, so the new worktree is not in it.
    # Listed with -z, because without it git C-quotes a name that contains a
    # double quote, a backslash, a tab or a newline, and cp is then given a
    # path that does not exist. tr turns each newline inside a name into the
    # byte \001 and each NUL terminator into a newline, so one line is one
    # name. A name that contains \001 after tr is skipped below: it contained a
    # newline or the byte \001, and the two cannot be told apart. The NUL bytes go
    # straight into tr: a shell variable cannot contain one. A failed listing
    # appends the line `/`, which git never prints as a name.
    ignored=$({ git ls-files -z --others --ignored --exclude-standard \
        --directory || printf '/\000'; } | tr '\n\000' '\001\n')
    case "$ignored" in
        ("/"|*"
/") gr_die "git ls-files failed, so the ignored entries cannot be listed." ;;
    esac
    newline_marker=$(printf '\001')

    git worktree add -q "$task_path" -b "$task_branch" "refs/heads/$change_branch" \
        || {
            echo "task-worktree: git worktree add failed; nothing was created." >&2
            gr_fix TASK-NOT-CREATED \
"read git's error above; nothing was created. Fix the cause, then run start $tag again."
        }

    # Each entry is copied to the same relative path. The trailing `/` git
    # prints on a directory is stripped first: BSD cp -R given `dir/` copies the
    # directory's contents rather than the directory.
    #
    # An entry whose target already exists is skipped. The listing can name a
    # directory and an entry inside it: a directory with no tracked file and
    # only ignored contents is listed as `tests/` and again as
    # `tests/.bats-core/`. The first copy already contains the second, and a
    # second cp -R would copy it into itself.
    #
    # `--` ends cp's options, so a name that begins with `-` is a path.
    #
    # The loop reads a here-document rather than a pipe, so it runs in this
    # shell and copy_failed is set here. The status is kept apart from the
    # printed lines, which contain entry names.
    copy_failed=no
    while IFS= read -r entry; do
        [ -n "$entry" ] || continue
        case "$entry" in
            (.worktrees/*|.claude/*) continue ;;
            (*"$newline_marker"*)
                printf 'task-worktree: not copied, the name contains a newline or a \\001 byte: %s\n' \
                    "$(printf '%s' "$entry" | tr '\001' '?')"
                continue ;;
        esac
        entry=${entry%/}
        [ ! -e "$task_path/$entry" ] || continue
        target_parent=$(dirname -- "$task_path/$entry")
        if mkdir -p "$target_parent" && cp -R -- "$entry" "$task_path/$entry"; then
            printf 'task-worktree: copied: %s\n' "$entry"
        else
            printf 'task-worktree: copy failed: %s\n' "$entry"
            copy_failed=yes
        fi
    done <<IGNORED_ENTRIES
$ignored
IGNORED_ENTRIES
    if [ "$copy_failed" = yes ]; then
        echo "task-worktree: the worktree was created at $task_path, but an ignored entry was not copied into it." >&2
        gr_fix TASK-COPY-FAILED \
"the worktree exists at $task_path; copy each entry named on a copy failed line above by hand (cp -R -- <entry> $task_path/<entry>), or retire the worktree with task-worktree.sh remove $tag and, once the cause is fixed, run start $tag again."
    fi
    printf '%s\n' "$task_path"
    exit 0
fi

# --- merge, remove and discard ------------------------------------------------

if [ "$task_branch_exists" = no ]; then
    [ -z "$leftover_step" ] || gr_fix TASK-MISSING \
"no branch $task_branch exists, and $task_path is left from an earlier dispatch: $leftover_step. Then start $tag can be run again."
    gr_fix TASK-MISSING \
"no branch $task_branch exists; check the tag, or run start $tag first."
fi

# A task path that exists while nothing is registered there is not a task
# worktree: its `.git` file was removed and the registration pruned, for
# example. Every proof below reads a registered worktree, so none would run on
# its contents, and the run would merge or delete the task branch and leave the
# directory and its uncommitted files behind.
if [ -z "$task_record" ] && [ -e "$task_path" ]; then
    gr_fix TASK-NOT-REGISTERED \
"$task_path is not a registered worktree, so its contents were never checked; record as a finding anything in it worth keeping, and delete it by hand after reading it, then $return_step"
fi

registered=$(worktree_of_branch "$task_branch")

# Only the task worktree nested in this change worktree is acted on. The same
# branch name checked out elsewhere is a worktree this change worktree did not
# create, and removing it, or deleting its branch, destroys another agent's
# work.
if [ -n "$registered" ] && [ "$registered" != "$task_path" ]; then
    gr_fix TASK-NOT-NESTED \
"$task_branch is checked out at $registered, not at $task_path; $subcommand acts only on the task worktree nested in this change worktree. Choose another tag."
fi

# A locked worktree is rejected before anything changes. git worktree remove
# rejects it too, but under merge only after the task branch is merged.
case "
$task_record" in
    (*"
locked"*)
        gr_fix TASK-LOCKED \
"$task_path is locked (git worktree list --porcelain states the reason); once nothing uses it, run git worktree unlock $task_path, then $return_step" ;;
esac

# A worktree registered at the task path but not on the task branch (a detached
# HEAD, or another branch) is not found by worktree_of_branch, so the TASK-DIRTY
# proof below would not run on it. TASK-NESTED has already run on it.
if [ -z "$registered" ] && [ -n "$task_record" ]; then
    # The HEAD is read from the registration, so a worktree whose directory
    # was deleted is listed the same way.
    if [ -d "$task_path" ]; then
        restore_step="check out $task_branch in it (git -C $task_path checkout $task_branch)"
    else
        restore_step="remove the registration of its missing directory with git worktree remove $task_path, which merges nothing"
    fi
    # Commits on that HEAD which the task branch lacks become unreachable once
    # the task branch is checked out or the registration is removed, and
    # remove then sees no commits. They are listed, and recorded first.
    off_branch=$(git rev-list "refs/heads/$task_branch..$task_head") || gr_die \
"git rev-list failed, so the commits on the HEAD of $task_path cannot be listed."
    if [ -z "$off_branch" ]; then
        gr_fix TASK-NOT-ON-BRANCH \
"$task_path is not on $task_branch; $restore_step, then $return_step"
    fi
    git log --oneline "refs/heads/$task_branch..$task_head" || gr_die \
"git log failed, so the commits on the HEAD of $task_path cannot be listed."
    if [ "$subcommand" = merge ]; then
        gr_fix TASK-NOT-ON-BRANCH \
"$task_path is not on $task_branch, and the commits listed above are on its HEAD, not on $task_branch, and were never reported; record each one as a finding before anything else, then the task goes back to its subagent (develop-change), which reports again."
    fi
    gr_fix TASK-NOT-ON-BRANCH \
"$task_path is not on $task_branch, and the commits listed above are on its HEAD, not on $task_branch, and were never reported; record each one as a finding before anything else, then $restore_step, then $return_step"
fi

if [ -n "$registered" ] && [ -d "$registered" ]; then
    status_lines=$(git -C "$registered" status --porcelain) || gr_die \
"git status failed in $registered, so it cannot be proved clean."
    if [ -n "$status_lines" ]; then
        printf '%s\n' "$status_lines"
        if [ "$subcommand" = merge ]; then
            gr_fix TASK-DIRTY \
"the changes in $registered are not covered by its dispatch report; the task goes back to its subagent (develop-change) to commit or discard them and report again."
        fi
        gr_fix TASK-DIRTY \
"commit or discard the changes in $registered, then $return_step"
    fi
fi

# A task worktree whose directory was deleted has no files to prove clean.
# remove and discard retire its registration below; merge rejects it, because
# what the directory contained beyond the commits on the task branch can no
# longer be checked against the dispatch report.
if [ -n "$registered" ] && [ ! -d "$registered" ] && [ "$subcommand" = merge ]; then
    gr_fix TASK-DIRECTORY-MISSING \
"$registered is registered on $task_branch, but its directory is missing, so what it contained beyond the commits on $task_branch cannot be checked; the task goes back to its subagent (develop-change), which restores the worktree with git worktree remove $registered and git worktree add $registered $task_branch, and reports again."
fi

case "$subcommand" in
    (remove)
        unmerged=$(git rev-list "refs/heads/$change_branch..refs/heads/$task_branch") || gr_die \
"git rev-list failed, so the commits on $task_branch cannot be listed."
        if [ -n "$unmerged" ]; then
            # The remedy asks for each listed commit to be recorded, so an
            # empty listing is not printed under it.
            git log --oneline "refs/heads/$change_branch..refs/heads/$task_branch" || gr_die \
"git log failed, so the commits on $task_branch cannot be listed."
            gr_fix TASK-HAS-COMMITS \
"$task_branch has the commits listed above, which were never gated or reviewed; record each one as a finding, then run task-worktree.sh discard $tag."
        fi ;;
    (discard)
        echo "task-worktree: discarding the commits on $task_branch that $change_branch lacks:"
        git log --oneline "refs/heads/$change_branch..refs/heads/$task_branch" || gr_die \
"git log failed, so the commits on $task_branch cannot be listed." ;;
    (merge)
        # The message is the one git writes for a bare branch name; given
        # refs/heads/<branch>, git writes the full ref name into it.
        if ! git -c commit.gpgsign=false merge --no-ff --no-edit \
            -m "Merge branch '$task_branch' into $change_branch" "refs/heads/$task_branch"; then
            # The merge of this task is in progress when MERGE_HEAD is the task
            # branch tip: with unmerged entries it conflicted, and without
            # them git merged the trees and did not commit (a commit-msg or
            # pre-merge-commit hook rejected the merge commit, for example).
            # The unmerged entries, MERGE_HEAD and the tip are read with their
            # status taken, so a git failure is not read as "no merge in
            # progress". MERGE_HEAD is verified only when its file exists, for
            # the reason stated at the CHANGE-BUSY check.
            conflict_entries=$(git ls-files -u) || gr_die \
"git ls-files -u failed, so whether an operation is in progress in $gr_repo_root cannot be read."
            conflict_merge_head=
            if [ -e "$merge_head_path" ]; then
                conflict_merge_head=$(git rev-parse -q --verify MERGE_HEAD) || gr_die \
"git rev-parse --verify MERGE_HEAD failed, so whether an operation is in progress in $gr_repo_root cannot be read."
            fi
            conflict_task_tip=$(git rev-parse --verify "refs/heads/$task_branch") || gr_die \
"git rev-parse --verify refs/heads/$task_branch failed, so whether an operation is in progress in $gr_repo_root cannot be read."
            if [ -n "$conflict_merge_head" ] && [ "$conflict_merge_head" = "$conflict_task_tip" ]; then
                if [ -n "$conflict_entries" ]; then
                    gr_fix TASK-CONFLICT \
"resolve the conflicts in $gr_repo_root, conclude the merge with git -c commit.gpgsign=false commit --no-edit, then run remove $tag."
                fi
                # The state the CHANGE-BUSY check reports for the merge of this
                # task, with the same remedy: concluding it merges the reported
                # work, and aborting it returns the decision to the dispatcher.
                echo "task-worktree: git merge of $task_branch did not commit; nothing was removed." >&2
                gr_fix CHANGE-BUSY \
"the merge of $task_branch, this task's branch, is in progress in the change worktree $gr_repo_root and was not committed, for the reason in git's output above; conclude it (clear the cause git names, such as a hook that rejected the merge commit, then git -c commit.gpgsign=false commit --no-edit), then run remove $tag; or abort it (git merge --abort), then repeat the dispatcher's step for this task (develop-change)."
            fi
            echo "task-worktree: git merge of $task_branch failed; nothing was removed." >&2
            # No merge of this task is in progress. The task report was green
            # and the cause is in the change worktree, so the remedy returns to
            # the dispatcher's step and names no merging command.
            gr_fix TASK-MERGE-FAILED \
"read git's error above; nothing was merged or removed. Clear the cause in the change worktree $gr_repo_root (for example, commit or remove the local change git names), then repeat the dispatcher's step for this task (develop-change)."
        fi
        echo "task-worktree: merged: $task_branch" ;;
esac

if [ -n "$registered" ]; then
    git worktree remove "$registered" || {
        echo "task-worktree: not removed: $registered" >&2
        echo "task-worktree: not deleted: $task_branch" >&2
        # Nothing is deleted before the removal succeeds. Under merge the task
        # branch is already merged, so remove passes once the cause git stated
        # is cleared, and the remedy names no merge.
        case "$subcommand" in
            (merge) gr_fix TASK-NOT-REMOVED \
"the merge is done and $task_branch is in $change_branch; $registered remains, because git rejected its removal for the reason in the git output above. Once that cause is cleared, task-worktree.sh remove $tag retires it: the branch is merged, so remove passes." ;;
            (remove) gr_fix TASK-NOT-REMOVED \
"git rejected the removal of $registered for the reason in the git output above, so nothing was changed: $registered remains registered and $task_branch remains. Once that cause is cleared, task-worktree.sh remove $tag retires it." ;;
            (*) gr_fix TASK-NOT-REMOVED \
"git rejected the removal of $registered for the reason in the git output above, so nothing was deleted: $registered remains registered and $task_branch remains with the commits listed above. Once each commit listed above is recorded as a finding and that cause is cleared, task-worktree.sh discard $tag retires it." ;;
        esac
    }
    echo "task-worktree: worktree removed: $registered"
else
    echo "task-worktree: no worktree is registered for $task_branch, so none was removed"
fi

if [ "$subcommand" = discard ]; then
    delete_flag=-D
else
    delete_flag=-d
fi
# git branch -d and -D take a branch name and read it as refs/heads/<name>,
# so a tag of the same name is not deleted in its place.
git branch "$delete_flag" "$task_branch" >/dev/null || {
    echo "task-worktree: not deleted: $task_branch" >&2
    # No worktree remains registered for the task branch, so only the branch
    # deletion is left, and it names no merging command.
    case "$subcommand" in
        (merge) gr_fix TASK-BRANCH-NOT-DELETED \
"no worktree remains registered for $task_branch, and it is merged into $change_branch; git rejected the branch deletion for the reason in the git output above. Once that cause is cleared, delete the branch with git branch -d $task_branch." ;;
        (remove) gr_fix TASK-BRANCH-NOT-DELETED \
"no worktree remains registered for $task_branch, and it has no commit $change_branch lacks; git rejected the branch deletion for the reason in the git output above. Once that cause is cleared, delete the branch with git branch -d $task_branch." ;;
        (*) gr_fix TASK-BRANCH-NOT-DELETED \
"no worktree remains registered for $task_branch; git rejected the branch deletion for the reason in the git output above, and the commits listed above remain on $task_branch. Once each one is recorded as a finding and that cause is cleared, delete the branch with git branch -D $task_branch." ;;
    esac
}
echo "task-worktree: branch deleted: $task_branch"
exit 0
