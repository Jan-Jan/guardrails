# When finish-merge.sh rejects the cleanup

Read this when `finish-merge.sh` exits non-zero at `merge-change` step 7 or 8.
A non-zero exit removed nothing and deleted nothing, with one exception: when
guard 3 removed the worktree and `git branch -D` then failed, the worktree is
gone and the branch remains. The message states what was removed: nothing, or
the worktree alone when only the branch deletion failed. The signed commit is
on the base branch either way; only the cleanup is withheld.

| Rejection | What it means | What fixes it |
|---|---|---|
| `UNVERIFIED` / `UNSIGNED` from `check-signing.sh --strict` | The new HEAD's signature did not verify. Read the reason the gate prints indented under the verdict; it is the verifier's own. A missing `gpg.ssh.allowedSignersFile` is one cause; an OpenPGP-signed commit never reads that setting. `gpg: ... can't open ... trustdb.gpg: Operation not permitted` is an environment fault, not a bad signature. | Fix what the reason names: the signers file for ssh (ratchet's signing checklist), a readable trust root for OpenPGP. Then re-run the script. |
| `git diff HEAD <branch>` is non-empty | The squash did not capture everything: an unstaged file, a partial `git add`, or a base that moved between step 1 and the squash. Deleting the branch would destroy that difference. | Run `git diff HEAD <branch>` to see what is missing. Bring it onto the base branch, or rerun the sequence from step 1, then re-run the script. |
| `a registered worktree lies inside <path>` (plural: `registered worktrees lie inside <path>`) | A task or review worktree is still registered inside the change worktree. Removing the outer one would delete the inner one's uncommitted work while git still had it registered. | For each path named `.worktrees/<branch>-<tag>`, the review worktree included: in the change worktree, run `sh .guardrails/scripts/task-worktree.sh remove <tag>`, which merges nothing and removes it. If `remove` rejects on commits, those commits are not in the squash and were never gated or reviewed: record each one as a finding and run `task-worktree.sh discard <tag>`, or, to keep the work, copy its branch first (`git branch <new-name> <branch>`) and open a new change for it, since the squash is already on the base branch. The change worktree is still in place after the squash, so these run from it. For a worktree `task-worktree.sh` did not create, record the commits its branch has, then run `git worktree remove <path>` without `--force` and `git branch -D <branch>`, which merge nothing. Then re-run the script. |
| `git worktree remove` rejected it | The change worktree is dirty. No `--force` is passed, so git's rejection is the guard. | Inspect the worktree, commit or discard what is there, then re-run the script. |
| `the worktree was removed but <branch> could not be deleted`, or `no worktree was registered for <branch>, so no worktree was removed, and <branch> could not be deleted` | Every guard passed and `git branch -D` failed. The first form follows a removal: the worktree is gone and the branch remains. The second form removed nothing. git's own error, printed above the message, names the cause, such as a stale `.lock` file on the ref or the branch checked out in another worktree. | Fix what git's error names, then re-run the script. With no worktree registered it deletes the branch. |
| A precondition error (exit 2) | Run from a linked worktree, on a detached HEAD, with no such branch, or naming the base branch itself. | Run it from the primary checkout with the base branch checked out, naming the change branch. |
| A git or awk step failed (exit 2) | A call whose result the script reads failed: `git worktree list failed`, or the worktree path for the branch could not be derived. Nothing was removed or deleted. | Fix the cause git's error names, printed above the message, then re-run the script. |

Re-run the script alone:

```sh
sh .guardrails/scripts/finish-merge.sh <branch>
```

Re-running the whole compound does nothing: the squash is no longer staged,
so `git commit` fails and `&&` stops before the script runs. It also reads as
though the merge needs redoing. It does not: the merge is done, and only the
cleanup is outstanding.
