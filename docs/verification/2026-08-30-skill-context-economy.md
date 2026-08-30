# Verification — the skills delegate the work and keep the main agent's context for the plan

branch: worktree-skill-context-economy
reviewer: five independent subagent reviews, each dispatched fresh with no conversation history — rounds 1–5
verdict: accepted after five rounds; nineteen findings raised, all dispositioned, the last round returning one non-blocking finding which was fixed
reproduced: not applicable in the defect sense — this change adds no fix to a
reported failure. What was reproduced, repeatedly and outside this repository,
are the mechanisms the new rules depend on: reviewers built scratch git repos
and confirmed the four routes by which a task subagent cannot merge its own
branch, the signing failure of an unadorned `git merge --no-ff`, that a
comma-separated `verifies: <old>, <new>` credits both IDs in `check-trace.sh`,
and that the new red → green table survives `check-review.sh` with its negative
controls still biting. Each is quoted under the finding it belongs to.

## What this change is

Eighteen rules (R1–R18, `docs/plans/2026-08-30-skill-context-economy.md`) that
move implementation, verification and review off the main agent and into
dispatched subagents, so the main agent's context holds the plan, the trace and
the decisions rather than diffs and test logs — and that reduce the points at
which the agent stops for the user to three: the interview, a derailment, and
the merge.

Six skills, both top-level documents and the verification template changed:
`grill-requirements`, `worktree-discipline`, `plan-change`, `develop-change`,
`verify-before-merge`, `merge-change`, `AGENTS.md`, `README.md`,
`templates/verification.md`. No file under `scripts/` or `tests/` was touched.

## Measurement

- Suite: **409 tests, 0 failures**, TAP plan `1..409`, counts read from the TAP
  stream rather than the exit status (`docs/plans/2026-08-12-false-green-fixes.md`
  is why, and R13 now makes it a rule).
- **The agent bypass was used, and here is why.** Mid-session the gnome-keyring
  ssh-agent wedged: `timeout 10 ssh-add -l` exited 124, and two full-suite runs
  hung indefinitely at test 99 (`check-signing: ssh-signed commit with
  allowed_signers passes`) inside `ssh-keygen -Y sign`, one of them for 22
  minutes before it was killed. `ssh-keygen -Y sign` consults the agent before
  the key file, so the final run was made with `SSH_AUTH_SOCK=` cleared, which
  sends it to the key file directly. Nothing about the five `check-signing`
  tests was skipped or relaxed — all 409 ran and passed. The wedge is an
  environment fault, recorded before this change and unrelated to it.
- A partial run of 98/409 produced by the first hang was reported by the gate
  subagent as an incomplete gate, not a pass. It is named here because the
  distinction is the whole point of R13.
- Base branch: `main` at `708b8c0`, contained in this branch (`git merge-base
  --is-ancestor` exit 0), with zero divergence from `origin/main` as last
  fetched.
- **The base was merged from a local ref**, not a freshly fetched one.
  `git fetch origin` fails in this environment with `Bad owner or permissions on
  /etc/ssh/ssh_config.d/20-systemd-ssh-proxy.conf`, exit 128 — a recorded
  environment fault. `merge-change` step 1 requires this to be stated with the
  commit named, so that a later reader knows what step 4's duplicate scan was
  compared against: **`708b8c0`**.

## Rigor

Five independent reviews rather than the one this repository's class would ask
for, because the change rewrites the process that governs every future change,
and because each round found something the previous had not. Each reviewer was
dispatched fresh, with the diff, the plan and repository access, and no
implementation narrative or chat history. Rounds 3, 4 and 5 verified their
claims by building scratch repositories outside this one rather than by reading.

Findings by round: 7, 4, 4, 3, 1. Blocking findings by round: 2, 2, 1, 1, 0.

## Red → green

Not applicable. This change adds no tests, because it touches no code: `tests/`
covers `scripts/`, and no test reads `skills/`, `AGENTS.md`, `README.md`,
`docs/plans/` or `templates/verification.md` — confirmed by grep in rounds 4 and
5. The 409 tests are the regression evidence, unchanged before and after.

The table this section would otherwise carry is itself part of this change
(R12's companion in `templates/verification.md`); the first change to use it
will be the first one that writes code under the new rules.

## Review

**finding-1**: [round 1, blocking] `verify-before-merge` check 4 became unanswerable. It asks for a `verifies:` test "that you watched fail before it passed", but the gate is now dispatched to a fresh subagent that watched nothing fail, and nothing forwarded the observation to it.
disposition: check 4 split between the two parties who can answer — the subagent reports which test carries which Implements ID, the main agent answers the attestation half from the dispatch reports — and `develop-change`'s dispatch report gained a `red -> green:` line as the channel. Round 4 then found the attestation had no durable holder; see finding-13.

**finding-2**: [round 1, blocking] `grill-requirements` claimed the supersession annotations "keep every existing mechanism working". They do not: `check-trace.sh`'s MISSING-TEST gate walks every defined item with no `superseded-by:` exemption, so a superseded item keeps demanding a test.
disposition: over-claim removed; the superseded item's test now carries both IDs (`verifies: <old>, <new>`), which satisfies MISSING-TEST for both with no script change, and superseding is distinguished from retiring. Verified empirically in round 2 against `scripts/lib.sh` `GR_AWK_ID_RUN` and again in round 3 in a scratch repo: the pair passes `check-trace.sh` at exit 0, and the negative control (only the new ID annotated) reports `MISSING-TEST <old-id>` at exit 1.

**finding-3**: [round 1] `develop-change` said escalate on repeated failure "and nowhere else", contradicting two stops deliberately kept — a red baseline (`worktree-discipline` step 4) and accepting a documented coverage gap (`verify-before-merge` check 5).
disposition: reframed. The invariant is not a count of stops but "stop only when the answer is genuinely the user's"; both other stops are named as passing the same test.

**finding-4**: [round 1] `merge-change` steps 2 and 6 still ran the suite in the agent's own context, contradicting the new rule in the same file and in `AGENTS.md`.
disposition: both steps now dispatch the gate; 6a and 6b refer to the step 6 gate summary. Each step keeps its own reason for existing.

**finding-5**: [round 1] The task-worktree example hardcoded `.worktrees/`, which this repository does not gitignore, so following it literally would fail `verify-before-merge`'s clean `git status` check.
disposition: the directory became a placeholder with the ignore requirement attached inline. Round 5 found the requirement assigned to the wrong party; see finding-19.

**finding-6**: [round 1] A review worktree had no removal rule, and "Leaving" read as forbidding task-worktree cleanup.
disposition: lifecycle stated for every dispatched worktree; "Leaving" scoped explicitly to the change worktree.

**finding-7**: [round 1] Step 6a handed the reviewer "ONLY the diff…" while requiring it to run the suite, which needs the repository; and the checklist said `CONTEXT.md` where every other skill says `docs/CONTEXT.md`.
disposition: the restriction is now what it always meant — no implementation narrative, no chat history — with repository access explicit. Path corrected.

**finding-8**: [round 2, blocking] The gate summary's fixed shape had no field for the test-to-ID mapping that check 4's subagent half requires, so that half had no channel to arrive through.
disposition: the summary gained an Implements map. The fixing agent found checks 6 and 7 were unanswerable through the old shape as well, which the reviewer had not caught; both gained fields.

**finding-9**: [round 2, blocking] The `red -> green:` attestations lived only in the conversation, which `worktree-discipline` declares non-durable and `merge-change` step 8 recommends compacting away.
disposition: given a durable home — a table in `templates/verification.md`, listed in `merge-change` 6b. Proved not to disturb the gate that reads that file: a filled record passes `check-review.sh` at exit 0 reporting the correct finding count, while the negative controls still fail (`UNDISPOSED-FINDING`, `INCOMPLETE-RECORD`). Round 4 found the gap between production and consumption; see finding-13.

**finding-10**: [round 2] `worktree-discipline` sent a verification dispatch into its own task worktree while `verify-before-merge` requires the gate to run in the change worktree — a fresh worktree is clean by construction, so the `git status` check would pass having proved nothing.
disposition: step 1 now enumerates three dispatch kinds and states that the gate runs in the change worktree, with the reason. A red-flag row was added for the vacuous-clean-status trap.

**finding-11**: [round 2] Check 4 was called "the one exception", but check 5 is split too — its other half is the user's.
disposition: preamble corrected to name both.

**finding-12**: [round 3, blocking] The task subagent was told to merge its task branch into the change branch. Git refuses: that branch is checked out in the change worktree.
disposition: the merge and the cleanup were reassigned to the dispatcher, in the change worktree, across `worktree-discipline`, `develop-change`, `AGENTS.md`, `README.md` and the plan's vocabulary. Reproduced in scratch repositories by three separate agents: `git merge <change-branch>` from the task worktree **exits 0 while leaving the change branch unmoved** — a false green in the hop that carries every task's work — `git checkout` fails with "already used by worktree", and `git push .` / `git fetch .` are refused with "refusing to update/fetch into branch … checked out at". The dispatcher's sequence was then run end to end with two disjoint task branches, clean.

**finding-13**: [round 4] The `red -> green:` attestations had no holder between the dispatch report and step 6b, which sits many steps later and re-runs from step 1 on any finding — contradicting the change's own "write state down as you go".
disposition: the dispatcher now records them in the plan beside each completed task as the report lands, so 6b copies from an artifact.

**finding-14**: [round 4] The dispatcher needs the task worktree's path to remove it, and had no channel for it; step 1's two candidate locations resolved differently (inside versus beside the change worktree).
disposition: the dispatch report gained a `worktree:` line, and step 1 distinguishes the two locations and which one needs an ignore entry.

**finding-15**: [round 3] The red → green table was claimed to be checked by step 6a, which never mentions it and runs before 6b writes it.
disposition: the false owner was removed. The table is an attestation nothing can re-observe; 6a's existing "would these tests fail if the behavior broke?" is named as the independent check on the same property.

**finding-16**: [round 3] "Fix in the worktree" predates delegation, where it meant only "not on the base branch"; under the new rules it reads as an instruction for the main agent to edit code itself.
disposition: the actor is now explicit in each place — deciding what to fix is the main agent's, writing the fix is dispatched.

**finding-17**: [round 3] The plan did not follow the plan rule it ships: its tasks carried no `**Files touched:**` / `**Parallel:**` heads.
disposition: T1–T6 reformatted to the required shape, and two counts in the plan corrected.

**finding-18**: [round 4, blocking] The dispatcher's `git merge --no-ff` omitted `-c commit.gpgsign=false`. `git merge` honors `commit.gpgsign`, which `ratchet` tells every guardrails project to set true — so it would demand a hardware-key touch per task merge, or fail leaving `MERGE_HEAD` and a dirty change worktree that then fails check 7.
disposition: flag added, with the reason stated. Reproduced twice in scratch repositories: without the flag, `error: gpg failed to sign the data` / `fatal: failed to write commit object`, exit 128, `MERGE_HEAD` present and `git status` showing a staged half-merge; with it, exit 0 and a clean tree.

**finding-19**: [round 5] The `.worktrees/` ignore entry was written as the task subagent's precondition, but resolving that path and running `add + commit` both require the change worktree, which two other rules forbid the subagent from entering — and five fanned-out subagents would race that commit.
disposition: reassigned to the dispatcher, once, before dispatching anyone, with the reason stated.

## Open

- **R10's second trigger is mis-calibrated.** "Review returns findings on the
  same task twice" fires on ordinary review convergence rather than on being
  stuck: the check-4 thread drew findings in rounds 1, 2 and 4 while converging
  normally, each time with a precise mechanical fix and nothing blocked. Noticed
  by applying the rule to this change as it was being written. Wants its own
  change.
- **`README.md`'s workflow diagram still labels `worktree-discipline` "isolate +
  draft IDs".** Stale against the random-token ID scheme, which mints no drafts.
  Predates this change; found in passing and left alone as out of scope.
