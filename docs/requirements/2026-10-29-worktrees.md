# Requirements: worktrees

**REQ-6erp29**: The software's task-worktree.sh start shall create the task worktree `.worktrees/<change-branch>-<tag>` on a new branch `<change-branch>-<tag>` off the change branch, and print its absolute path as its last line.

**REQ-r4675t**: The software's task-worktree.sh start shall copy into the task worktree every ignored entry of the change worktree except `.worktrees/` and `.claude/`, and skip, with a line stating it, an entry whose name contains a newline or the byte \001.

**REQ-szr7ta**: The software's task-worktree.sh start shall exit 1, naming the task worktree, when copying an ignored entry fails, and exit 1 printing no worktree path when creating the task worktree fails.

**REQ-jv376u**: The software's task-worktree.sh commands shall exit 2 when run in the primary checkout or on a detached HEAD.

**REQ-r4g5bz**: The software's task-worktree.sh commands shall exit 2 with the usage for an unknown command, a missing tag, an extra argument, or a tag that is empty, contains a slash or whitespace, begins with `-`, or makes the task branch an invalid ref name.

**REQ-tac8z3**: The software's task-worktree.sh start shall report WORKTREES-NOT-IGNORED, creating nothing, when the change worktree does not ignore `.worktrees/`.

**REQ-efv49s**: The software's task-worktree.sh start shall report TASK-EXISTS, creating nothing, when the tag's task path, task branch or a worktree registered at the task path already exists.

**REQ-5f7cux**: The software's task-worktree.sh merge shall merge the task branch into the change branch with `--no-ff`, unsigned, then remove the task worktree and delete the task branch.

**REQ-cfm7vy**: The software's task-worktree.sh merge, remove and discard shall report TASK-DIRTY, changing nothing, for a task worktree with an uncommitted change or an untracked file.

**REQ-fg6q6u**: The software's task-worktree.sh commands shall report TASK-NESTED, changing nothing, when a worktree is registered inside the task path, whatever is registered at the task path and whether or not its directory exists.

**REQ-9xg4th**: The software's task-worktree.sh merge shall leave a conflicting merge, or a merge a hook kept from committing, in progress in the change worktree, stating that it was not committed and naming a remedy that concludes it unsigned with no editor.

**REQ-va2bdu**: The software's task-worktree.sh merge shall report TASK-MERGE-FAILED, removing nothing, when the merge fails without a conflict.

**REQ-b9f46d**: The software's task-worktree.sh commands shall report CHANGE-BUSY, changing nothing, while a merge, cherry-pick, revert or rebase is in progress, or an unmerged index entry is present, in the change worktree.

**REQ-uf8kwg**: The software's CHANGE-BUSY remedy shall leave the operation in progress to the dispatcher, tell a dispatched subagent to stop and report, and conclude the operation with no editor.

**REQ-9aep9s**: The software's task-worktree.sh merge, remove and discard shall remove the task worktree with `git worktree remove` without `--force`, and when that is rejected report TASK-NOT-REMOVED, delete no branch, and state what was and was not removed.

**REQ-2pc6y6**: The software's task-worktree.sh commands shall report TASK-BRANCH-NOT-DELETED, naming the removed task worktree and the `git branch` command that failed, when the task branch cannot be deleted.

**REQ-mxn25d**: The software's task-worktree.sh merge, remove and discard shall report TASK-MISSING for a tag with no task branch, naming any registered worktree or directory left at the task path.

**REQ-k9fhtf**: The software's task-worktree.sh merge, remove and discard shall report TASK-NOT-REGISTERED, changing nothing, for a task directory that is not a registered worktree.

**REQ-tjrs8a**: The software's task-worktree.sh merge, remove and discard shall report TASK-NOT-NESTED, changing nothing, for a task branch checked out outside the change worktree.

**REQ-32x33h**: The software's task-worktree.sh merge, remove and discard shall report TASK-NOT-ON-BRANCH, changing nothing, for a task worktree that is not on the task branch, listing each commit on its HEAD that the change branch lacks.

**REQ-u74348**: The software's task-worktree.sh merge, remove and discard shall report TASK-LOCKED, changing nothing, for a locked task worktree.

**REQ-92ywv3**: The software's task-worktree.sh remove and discard shall retire a task worktree whose directory was deleted, and merge shall reject it with TASK-DIRECTORY-MISSING.

**REQ-9w2fvh**: The software's task-worktree.sh remove shall merge nothing, and remove the task worktree and delete the task branch only when the task branch has no commit the change branch lacks, reporting TASK-HAS-COMMITS otherwise.

**REQ-yw8mhj**: The software's task-worktree.sh discard shall merge nothing, list each commit the task branch has that the change branch lacks, then remove the task worktree and delete the task branch with `git branch -D`.

**REQ-dpzf47**: The software's finish-merge.sh shall name no merging command in a remedy for a worktree registered inside the change worktree.

**REQ-8cp936**: The software's finish-merge.sh shall remove nothing unless HEAD's signature passes `check-signing.sh --strict`.

**REQ-avq6gm**: The software's finish-merge.sh shall remove nothing while any worktree is registered inside the change worktree, naming every such worktree, whatever characters the change worktree's path contains.

**REQ-9vpzq2**: The software's finish-merge.sh shall name, for each worktree registered inside the change worktree, `task-worktree.sh remove <tag>` for one task-worktree.sh created, discard after recording for a task branch with a commit, and git commands that merge nothing for any other.

**REQ-wpm2cu**: The software's finish-merge.sh shall state whether it removed the change worktree when deleting the change branch fails.

**REQ-5g2ymu**: The software's finish-merge.sh `--check`, or `-n`, shall report from the change worktree, before the squash, each worktree registered inside it, or that none was registered to inspect, and remove nothing.
