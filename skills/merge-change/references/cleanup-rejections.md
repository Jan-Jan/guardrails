# When finish-merge.sh rejects the cleanup

Read this when `finish-merge.sh` exits non-zero at `merge-change` step 7 or 8.
Every rejection exits having removed nothing and deleted nothing. The signed
commit is on the base branch either way; only the cleanup is withheld.

| Rejection | What it means | What fixes it |
|---|---|---|
| `UNVERIFIED` / `UNSIGNED` from `check-signing.sh --strict` | The new HEAD's signature did not verify. Read the reason the gate prints indented under the verdict; it is the verifier's own. A missing `gpg.ssh.allowedSignersFile` is one cause; an OpenPGP-signed commit never reads that setting. `gpg: ... can't open ... trustdb.gpg: Operation not permitted` is an environment fault, not a bad signature. | Fix what the reason names: the signers file for ssh (ratchet's signing checklist), a readable trust root for OpenPGP. Then re-run the script. |
| `git diff HEAD <branch>` is non-empty | The squash did not capture everything: an unstaged file, a partial `git add`, or a base that moved between step 1 and the squash. Deleting the branch would destroy that difference. | Run `git diff HEAD <branch>` to see what is missing. Bring it onto the base branch, or rerun the sequence from step 1, then re-run the script. |
| `a registered worktree lies inside <path>` (plural: `registered worktrees lie inside <path>`) | A task or review worktree is still registered inside the change worktree. Removing the outer one would delete the inner one's uncommitted work while git still had it registered. | For each path named: merge or abandon its branch, `git worktree remove` the path, then re-run the script. |
| `git worktree remove` rejected it | The change worktree is dirty. No `--force` is passed, so git's rejection is the guard. | Inspect the worktree, commit or discard what is there, then re-run the script. |
| A precondition error (exit 2) | Run from a linked worktree, on a detached HEAD, with no such branch, or naming the base branch itself. | Run it from the primary checkout with the base branch checked out, naming the change branch. |

Re-run the script alone:

```sh
sh .guardrails/scripts/finish-merge.sh <branch>
```

Re-running the whole compound does nothing: the squash is no longer staged,
so `git commit` fails and `&&` stops before the script runs. It also reads as
though the merge needs redoing. It does not: the merge is done, and only the
cleanup is outstanding.
