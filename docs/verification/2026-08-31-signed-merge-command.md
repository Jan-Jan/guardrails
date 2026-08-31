# Verification — the signed merge is one command the user runs, and its tail is guarded

branch: worktree-signed-merge-command
reviewer: one independent subagent review, dispatched fresh with the diff, the plan and repository access, no implementation narrative and no chat history
verdict: accept — no blocking findings; the guards held under every adversarial case the reviewer constructed, and its own mutation sweep killed 10 of 13 mutants with the 3 survivors explained as defense-in-depth. Seven non-blocking findings, all dispositioned; the two substantive ones were fixed before merge
reproduced: yes, for the defect this change is built around, and by three
parties independently. `git merge` honors `commit.gpgsign`: without
`-c commit.gpgsign=false` it blocks on the key or dies with
`fatal: failed to write commit object`, leaving `MERGE_HEAD` and a staged
half-merge. It was predicted by the previous change's fourth review, reproduced
in scratch repositories by two agents there — and then **it happened for real in
this change**, at step 1, when merging the moved base branch into this worktree:
the command hung for two minutes and had to be completed with the flag. The
prediction and the live occurrence are one change apart.

## What this change is

`merge-change` no longer runs the signed squash itself. The agent stages the
squash and hands the user one command:

```sh
git commit -S -F /tmp/merge-<branch>.msg && sh .guardrails/scripts/finish-merge.sh <branch>
```

The half needing the hardware key stays a plain, readable `git commit -S`. The
half that force-deletes a branch is `finish-merge.sh` (new), which proves three
things before it removes anything: the signature verifies under `--strict`,
`git diff --quiet HEAD <branch>` shows the squash captured everything the change
branch held, and `git worktree remove` without `--force` gets git's own refusal
of a dirty worktree. No escape hatch on any of them.

`check-signing.sh` gains `--setup`, which proves a project can produce a
verifiable signature rather than inspecting that it is configured to, and
`ratchet` now refuses to complete until it passes.

## Measurement

- Suite: **435 tests, 0 failures, 0 skips**, TAP plan `1..435`, counts read from
  the TAP stream and not the exit status. Baseline at the merged base
  (`55b5784`) was 410; this change adds 12 (`finish-merge.bats`) and 13
  (`check-signing.bats`).
- Run independently by the reviewer as well, same counts, because the change
  touches `scripts/` and the reviewer does not rest on handed-over evidence.
- **The agent bypass was used**: `SSH_AUTH_SOCK= sh tests/run-tests.sh
  </dev/null`. `ssh-keygen -Y sign` consults the ssh-agent before the key file,
  and this machine's agent wedges intermittently — it wedged during the previous
  change and hung two suites at the first signing test. Nothing was skipped or
  relaxed; all 435 ran.
- **The base branch moved mid-change**, to `55b5784`, while T1–T4 were in
  flight. Merged in per step 1. It brought `tests/skills.bats`, a content lint
  over `skills/`, and a `ratchet` edit adjacent to this change's — both merged
  clean, and the lint passes against the rewritten `ratchet`.
- **The base was merged from a local ref.** `git fetch origin` still fails with
  `Bad owner or permissions on /etc/ssh/ssh_config.d/20-systemd-ssh-proxy.conf`,
  and the user confirmed the remote is not a concern here. Named for the next
  reader, per step 1: the base merged was **`55b5784`**.

## Red → green

Every behavior in `scripts/` here has a test that was watched failing first.
The attestations came back on the dispatch reports; what makes them worth
reading is *how* the pre-guard script failed, because each failure is the exact
false green the guard exists to refuse:

| Item | Test | Watched red |
| --- | --- | --- |
| guard 1 | an unsigned HEAD fails with the worktree and branch intact | exited 0 and cleaned up an unsigned merge |
| guard 1 | an unverifiable signature fails, because `--strict` is unconditional | WARN-UNVERIFIED passed and cleanup proceeded |
| guard 2 | a change branch holding work the squash missed fails | exited 0, deleting a commit the squash never captured |
| guard 3 | a dirty worktree fails with the branch intact | git refused both operations yet the script exited 0 claiming both were done |
| S8 | with no worktree registered the branch is still deleted | `git worktree remove ""` errored, branch left undeletable |
| S3 | refuses to run from a linked worktree | verified the change branch's tip instead of the squash |
| S3 | refuses when the primary checkout is not on a base branch | detached HEAD sailed through, exit 0 |
| S3 | takes exactly one argument | with two names the last silently won and the wrong branch was deleted |
| S1 | happy path: worktree removed, branch deleted | the script did not exist |
| portability | derives the worktree path under an awk that refuses a newline in `-v` | calibrated by inserting a literal newline into the `awk -v` value, reproducing the predicted empty path, then reverted |
| S10 | `--setup` proves a fully configured project, names each missing piece, cleans up its throwaway repository | mode did not exist |

## Rigor

One independent review rather than the previous change's five: this change is
smaller, has real tests behind it, and the reviewer verified by construction
rather than by reading — building scratch repositories for each adversarial
case and mutation-testing the guards. Its mutation sweep (13 mutants, 10 killed)
is the evidence that the tests bite, and it is what found finding-2 below.

The T2 subagent died mid-task on a monthly API spend limit. Its work was already
complete and green (18 `check-signing.bats` tests) and was verified in place —
including that it had not left the script in the red state its last message
described ("writing it red first by removing the trap"): the trap is present and
its test passes. The remaining work was finished by the main agent rather than
by dispatching more subagents, given the budget signal.

## Review

**finding-1**: NON-BLOCKING — `merge-change` step 7 justified writing the commit message outside the repository with a false claim: "an untracked message file inside it would dirty the very tree the guards are about to inspect". No guard reads the primary checkout's working tree — guard 2 is a two-rev tree diff and guard 3 inspects the change worktree. Verified: with an untracked message file and a modified tracked file in the primary checkout, `finish-merge.sh` exits 0 and cleans up normally.
disposition: fixed. The practice stands, with the true reason — a stray file in the repository is one `git add -A` from being committed by the very commit it describes. The red-flag row was corrected to match, and now says plainly that no guard would catch it, which is the point.

**finding-2**: NON-BLOCKING — `tests/finish-merge.bats`'s "a dirty worktree fails with the branch intact" did not pin what its comment claimed. Mutating the script to swallow guard 3's refusal left all twelve tests green: the mutant still exits 1, but because git independently refuses to delete a branch checked out in a live worktree, and it says so in a different voice. Exit status alone could not tell the guard from the accident.
disposition: fixed. The test now asserts guard 3's own refusal text. Confirmed by re-running the reviewer's mutant: the test reddens without the guard and passes with it, and the script was restored from a byte-for-byte copy afterwards.

**finding-3**: NON-BLOCKING — `merge-change` step 8's exit-2 row listed "run while some other branch is checked out" as a reachable failure. It is not: `gr_base_branch` reports whatever the primary checkout has, so there every branch is its own base. The reachable case is a detached HEAD, which the table never named — and which the test file describes correctly.
disposition: fixed in the skill table; the plan's D5 gained the same correction, with the subtlety that made it a real hazard — an empty base compares *equal* to an empty current branch, so the comparison alone sails over a detached HEAD.

**finding-4**: NON-BLOCKING — `README.md`'s check-scripts table, the documented inventory of what `/ratchet` installs, gained no row for `finish-merge.sh`, and `check-signing.sh`'s row did not mention `--setup`. Nothing in the suite pins that table, so it would not have reddened.
disposition: fixed. Both rows written, each stating what the script proves rather than what it runs.

**finding-5**: NON-BLOCKING — `tests/portability.bats`'s strict-awk sweep comment claimed to cover "every script in `scripts/` that calls awk". `finish-merge.sh` calls awk and is absent, and the plan's constraints section asserted the sweep runs over every script including new ones.
disposition: fixed as a comment, not a sweep change, and the reason recorded there: every script in that sweep is asserted at exit 0, and `finish-merge.sh` has nothing to verify on that fixture, so it would correctly refuse and the sweep would read the refusal as a failure. Its strict-awk coverage lives in its own file instead. The comment now says where, and that a new awk-calling script belongs in one place or the other.

**finding-6**: NON-BLOCKING — `tests/finish-merge.bats` copies `setup_ssh_signing` out of `tests/check-signing.bats` rather than lifting it into `tests/helpers.bash`, leaving two copies; plan task T1 had assumed the helper was already shared. The new file also does not `isolate_git_config`, though the reviewer checked and it is safe — every setting it relies on is repo-local.
disposition: accepted, not fixed. The duplication is real but the helper it duplicates is pre-existing, and lifting it touches a third test file for no behavior change. Recorded as a follow-up tidy-up rather than done under a change whose subagent budget was already exhausted.

**finding-7**: NON-BLOCKING — the plan's D3 said `--setup` would pass the resolved signing config via `git -c`; the implementation writes the settings into the throwaway repository's own config instead, deliberately, so the existing verification loop can be reused verbatim on a plain `git log`.
disposition: the plan was amended, not the code. The implementation's choice is the better one — the reviewer said so, and reusing the verification path is what `AGENTS.md`'s no-forked-logic rule asks for.

## Open

- **The task-worktree rule merged by the previous change is not executable in
  this harness**, and this change is the evidence. All four task subagents
  created their task worktrees successfully and were then refused every
  subsequent operation against them — `git -C`, `cd`, and even a bare
  `git status` after `EnterWorktree` — because the harness pins a subagent to
  the worktree its dispatcher occupies. All four fell back to editing in the
  change worktree without committing, on a fallback improvised in the dispatch
  prompt that **`worktree-discipline` does not contain**. The rule therefore has
  no stated behavior for a harness that pins subagent cwd, and the red→green
  attestations above were observed but never committed on a task branch. Wants
  its own change: either a documented fallback, or a precondition the dispatcher
  checks before fanning out.
- **R10's second trigger remains mis-calibrated** (carried forward from
  `docs/verification/2026-08-30-skill-context-economy.md`).
- **`README.md`'s workflow diagram still labels `worktree-discipline`
  "isolate + draft IDs"**, stale since the random-token scheme mints no drafts.
  Carried forward, still out of scope.
- **`setup_ssh_signing` is duplicated across two test files** (finding-6).
