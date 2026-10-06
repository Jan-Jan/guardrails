# Verification — step-8-trusts-finish-merge (2026-10-06)

branch: step-8-trusts-finish-merge
reviewer: round 1, a fresh subagent with the diff, the plan, AGENTS.md and the review checklist, and no implementation narrative
verdict: round 1 raised six findings, all low (three requirement, three code), all fixed; under the low-severity convergence rule (ruled by the user 2026-10-04) it is the last review round
reproduced: no defect is repaired; at the user's request of 2026-10-05, merge-change step 8 stops re-verifying a signature that `finish-merge.sh` guard 1 has already verified under `--strict` in the user's shell. The redundancy was measured directly: step 8 ran `check-signing.sh --strict` on the HEAD guard 1 had just passed.

Change: merge-change step 8 reports from the step-7 message file and runs no git command; step 7 tells the user that success ends with three `finish-merge:` lines; "Done when" names `finish-merge.sh` as the verifier. Skill text and tests only; no script changes. Branched from local `main` at `17a0d58` while `churn-proposal` and `parallel-session-proposals` were open, by the user's decision of 2026-10-05 overriding AGENTS.md non-negotiable 4; neither branch touches `skills/merge-change/` or `tests/skills.bats`. Base merged from local `main` at `17a0d58` before each gate (`Already up to date`), per AGENTS.md non-negotiable 5.
Plan: `docs/plans/2026-10-05-step-8-trusts-finish-merge.md`.

## The gate

Measured on: `ee17902` — tree `3b1729ca436afecdc3328eb775dc698ef127ee85`, clean worktree. Step 3 renamed nothing: this change has no draft ledger file.

Guardrails has no `.guardrails/config.yaml`. `check-ids.sh` and
`check-trace.sh` were run against scratch copies of `main` at `17a0d58` and
of the change, built by the recipe in
`docs/verification/2026-10-03-accept-2scmvn.md`. The criterion is no finding
on the change that `main` lacks.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..1058`: 1058 ok, 0 not ok, 0 skipped, no `bats warning:` line, exit 0; 22:32:07 to 23:17:33 CEST on 2026-10-05; 1058 results, so plan and results agree. Three more than the base's 1055, which are the three tests this change adds |
| `sh tests/evidence.sh main` | exit 0: 3 tests new since `main`, all 3 go red against `main`'s scripts, 0 that cannot |
| `check-ids.sh` | exit 1 on `main` and on the change, 79 lines each, `diff` empty; this change mints no ID |
| `check-trace.sh` | exit 1 on `main` and on the change, 148 lines each, `diff` empty |
| `tests/skills.bats`, reviewer's run on `4e5bf05` | `1..96`: 96 ok, 0 not ok |
| `tests/finish-merge.bats`, reviewer's run on `4e5bf05` | `1..38`: 38 ok, 0 not ok |
| `check-review.sh` | run on the commit that adds this record (merge-change step 6c); its result is reported with the hand-over |
| Coverage | not configured; the toolkit is unclassified |
| Working tree | clean before and after every run; tree unchanged |

The diff is skill text and bats tests, with no script change. The reviewer ran
`skills.bats` and `finish-merge.bats` in its worktree, not the whole suite; the
gate above is substituted for the rest. A first gate dispatched on `4e5bf05`
was stopped before it reported, because the review fixes changed the tree; its
figures are not used. This record is committed after the gate and changes no
file the suite reads.

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| D1, D2, D3 | `merge-change: step 8 reports without re-verifying the signature` | T1 step 2, before the skill edit: `not ok` |
| D4 | `merge-change: step 7 tells the user what success looks like` | T1 step 2: `not ok` |
| D5 | `merge-change: Done when names finish-merge.sh as the verifier` | T1 step 2: `not ok` |

The review round 1 assertions were proved by mutation on a scratch copy, each
turning its test `not ok`: a backticked `git log` added to step 8; "branch,
IDs, record" cut to "branch"; the removed-what sentence deleted; "otherwise,
they paste the output" deleted; and `finish-merge.sh`'s `branch deleted`
success line deleted (`finish-merge.bats`, the signed-squash success test).

## What was wrong, and what was built

Step 8 re-ran the check guard 1 had made moments earlier on the same HEAD. A
pass added nothing; a failure was usually the agent's environment, since a
sandbox with a read-only `~/.gnupg` makes gpg read a good signature as `N`
(AGENTS.md; PR-k4t9k2). Step 8 now writes one closing line from the message
file and recommends compacting; a reported problem or a non-zero exit still
goes to `references/cleanup-rejections.md`. Step 7 tells the user what success
prints. Two existing tests pinned the old wording: one phrase was kept, and the
pin on the retired rationale sentence was re-aimed at its replacement.

## Review

**finding-1**: requirement, low — D2 says "No commit hash, no git command", but the new step 8 says only "Do not re-verify the signature". Nothing tells the agent not to run `git log` to look up the hash, and mutation M2 (add "run `git log -1 --oneline` and report the hash") passes every test. The new test's `run grep -q -e '%G?' -e 'check-signing'` covers only D1's two tokens.
disposition: fixed in `58d9dae`: step 8 says "Run no git command: `finish-merge.sh` verified the signature.", and the step 8 test forbids a backticked `git ` command; adding "Run `git log -1 --oneline` and report the hash." turns it `not ok`.

**finding-2**: code, low — Test "merge-change: step 8 reports without re-verifying the signature" claims `verifies: D1, D2, D3`, but parts of D2 and D3 are not pinned: D2's content ("branch, IDs, record") is unpinned (M14 survives). D3's PR-sa5y4k case is unpinned. No test in the tree asserts the sentence "nothing, or the worktree alone when only the branch deletion failed" (M8 survives). `cleanup-rejections.md` still covers that case, so the tree is right.
disposition: fixed in `58d9dae`: the test asserts `branch, IDs, record` and `the worktree alone when only the branch deletion`; deleting either turns it `not ok`.

**finding-3**: code, low — Test "merge-change: step 7 tells the user what success looks like" (D4) pins the "three `finish-merge:` lines" half but not the "otherwise, they paste you the output" half (M10 survives). It also counts `echo "finish-merge: ` lines in the script source rather than running the script. A move to `printf`, or a success line printed from a helper, would break the count even though the behavior is unchanged. `tests/finish-merge.bats` "removes the worktree and deletes the branch after a signed squash" never asserts those three lines either. The match holds today; the guard is brittle.
disposition: fixed in `58d9dae`: the step 7 test asserts `otherwise, they paste the output`, and `finish-merge.bats` "removes the worktree and deletes the branch after a signed squash" asserts that the run's last three output lines start `finish-merge: `; deleting the `branch deleted` echo from the script turns it `not ok`. The source count is kept beside it.

**finding-4**: code, low — The ban on re-verifying matches tokens, not meaning. Mutation M3 ("Then confirm HEAD with `git verify-commit HEAD`") passes, even though it contradicts the sentence "Do not re-verify the signature" next to it. This is contrived and a reader would see the contradiction, so it is noted only.
disposition: fixed in `58d9dae` by the same backticked-`git ` assertion as finding-1, which M3 now trips. A re-verification spelled without a backticked git command is still not caught (Gaps).

**finding-5**: requirement, low — Step 8 says "guard 1 did", but `SKILL.md` never numbers the guards. Step 7 says only "`finish-merge.sh` proves four things", and the numbering lives in the script header, `rationale.md` and `cleanup-rejections.md`. An agent reading only `SKILL.md` cannot tell which check "guard 1" is. "`finish-merge.sh` did" would be self-contained.
disposition: fixed in `58d9dae`: "`finish-merge.sh` verified the signature"; the step 8 test asserts that sentence.

**finding-6**: requirement, low — Small wording changes no decision mentions: "Recommend compacting before the next change" lost "before the next change". "if the harness offers a compaction step, such as `/compact`" became "has a compaction step (`/compact`)". That presents `/compact` as the step's name rather than one example, a small loss of generality for other harnesses.
disposition: fixed in `58d9dae`: both restored. To stay within 2,000 words, "that the command succeeded" became "of success" in step 8 and "they paste you the output" became "they paste the output" in step 7; `SKILL.md` is at 2,000 words and `skills.bats` checks the ceiling.

## Gaps

- No reviewer read the round 1 fixes; under the low-severity rule there is no round 2.
- The ban on re-verifying in step 8 is a token check (`%G?`, `check-signing`, a backticked `git `); a re-verification instruction worded without those tokens passes the tests.
- `merge-change/SKILL.md` is at the 2,000-word limit; the next addition needs an equal cut or a move to `references/`.
- Step 8 now trusts the user's report. A user who reports success without reading the output leaves a rejected cleanup unnoticed; step 7's success sentence is the only mitigation.
