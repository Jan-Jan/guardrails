# Problem reports — cleanup claims inherited from the old merge-change

Two items found by the independent review of `agent-first-skills`, round 3,
in text that predates that change. `affects:` names files, because guardrails
keeps no REQ/SDD/LLR ledger of its own. Both are for change 2 of
`docs/plans/2026-09-28-agent-first-skills.md`, which scripts this procedure.

**PR-zmzav3**: Two comments state that re-running `finish-merge.sh` costs a hardware key touch per run, but a re-run only verifies a signature, which uses no private key.
affects: scripts/finish-merge.sh, the comment on reporting every nested worktree at once; tests/finish-merge.bats, the comment in "finish-merge: every nested worktree is named, not just the first".
opened: 2026-09-29
status: resolved
Measured for the whole compound on 2026-09-28 with git 2.55.0: with nothing
staged, `git commit -S` exits 1 without calling `gpg.program`. The script
alone calls `check-signing.sh --strict`, which verifies and does not sign.
The rule the comments support, to report every nested worktree in one run,
is still right: it saves re-runs. Only the stated cost is wrong.
Fixed by the change `agent-first-scripts`
(`docs/plans/2026-09-29-agent-first-skills-change-2.md`, task T5): both comments now state that a re-run verifies the
signature and uses no private key. The defect is in comments only, so no test
verifies it; the test whose comment was corrected asserts no cost.

**PR-sa5y4k**: `merge-change` states that a non-zero exit from `finish-merge.sh` removed nothing, but the script exits 1 after removing the worktree when `git branch -D` then fails.
affects: skills/merge-change/SKILL.md step 8; skills/merge-change/references/cleanup-rejections.md, its opening sentence and its table, which has no row for this case; scripts/finish-merge.sh, the `git branch -D` failure path, and its message on the path where no worktree was registered.
opened: 2026-09-29
status: resolved
The old skill made the same claim. The message the script prints on this
path, `the worktree was removed but <branch> could not be deleted`, is
accurate only on the path that removed a worktree. On the path where no
worktree was registered, the script prints the same message, and it is false.
Fixed by the change `agent-first-scripts`
(`docs/plans/2026-09-29-agent-first-skills-change-2.md`, task T5): the path with no worktree registered prints its own
message, which states that no worktree was removed and the branch could not be
deleted. `references/cleanup-rejections.md` has a row for the `git branch -D`
failure, and its opening sentence names the exception. The sentence in
`merge-change` step 8 is corrected in the rewrite of that skill, task T6 of
this change's plan.
