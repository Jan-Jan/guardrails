# Context Economy and Delegated Development Implementation Plan

**Goal:** Rewrite the guardrails skills so a change runs to completion with the
main agent's context spent on orchestration rather than on code, test output and
ledger prose — and so the agent stops for the user at three points only: the
interview, a derailment, and the merge.
**Implements:** no requirement items exist in this repository yet. Traced to the
2026-08-30 requirements interview; the eighteen rules below (R1–R18) are the
requirement set the user confirmed.
**Safety class:** the toolkit itself is unclassified; it enforces class B/C
projects. This change touches skill text only — no script behaviour changes, so
no new bats tests are required (`tests/` covers `scripts/`).
**Verification:** `sh tests/run-tests.sh` — 409 tests, green before and after.
The change is docs-only, so by R14 the reviewer may rest on that run.

---

## The requirement behind the requirements

Every rule here serves one of two ends, and where they conflict the first wins:

1. **Keep the main agent's context small.** Large context is worse context. The
   main agent should hold the plan, the trace and the decisions — not diffs,
   not test logs, not the SRS.
2. **Only ask the user when the answer is genuinely theirs.** Three sanctioned
   stops: the interview at the start, a derailment in the middle, the merge at
   the end. Everything else the agent loops on until it is fixed.

The second end is why delegation is not optional. An agent that has read the
whole SRS and every test log has no room left to keep looping, so it stops and
asks — which is the failure this change removes.

## Canonical vocabulary

The skills cross-reference each other, so these terms must be used identically
in every file this change touches:

- **change worktree** / **change branch** — the one worktree per change, branched
  off the base branch, that `merge-change` squashes onto base.
- **task worktree** / **task branch** — a worktree branched off the *change*
  branch for one plan task. The subagent commits there and stops; the
  dispatcher merges the task branch into the change branch from the change
  worktree, because git refuses to update a branch another worktree has checked
  out. It never touches the base branch.
- **dispatch report** — the bounded, fixed-shape summary a task subagent
  returns (R9).
- **gate summary** — the fixed-shape summary the verification subagent returns
  (R12).
- **supersession annotations** — the `supersedes:` / `superseded-by:` pair (R2).

## Decisions

### D1 — task worktrees, not shared ones

Parallel subagents in a single worktree collide on files and on `index.lock`,
and — the part that matters here — they destroy TDD's evidence. `develop-change`
step 2 requires watching a test fail *for the right reason*; another agent
committing underneath you makes that observation worthless, which quietly
converts the strongest gate in the toolkit into a ritual. So each task subagent
gets its own worktree off the change branch.

The base branch is unaffected: it still sees exactly one signed squash per
change, and `merge-change` still sees exactly one worktree. Task worktrees are
an implementation detail below the change, which is why the rule lives in
`worktree-discipline` as a carve-out to its "already isolated — don't nest"
step rather than as a new top-level concept.

### D2 — fan-out is gated on disjoint files, not on judgement

"These tasks look independent" is not a gate. The plan states the files each
task touches (R6), and fan-out is permitted only where those sets do not
intersect. Anything else runs serially. Concurrency is capped at five.

### D3 — implementation is delegated even when serial

One subagent for one task saves no wall-clock. It saves the main agent from
reading the code, which is the entire point. The main agent reads code only
when a decision requires it (R11).

### D4 — the raw gate log must not be readable by the documentation gates

The verification subagent writes raw output to a file, and that file must live
**outside the repository or at a gitignored path**. Two reasons, both concrete:

- `verify-before-merge` step 7 requires a clean `git status`. An untracked log
  fails the gate it was produced by.
- A test log contains test *names*, and in a guardrails project those names
  quote item IDs. A log inside `docs/` is read by `check-ids.sh` and
  `check-trace.sh`, where a line shaped like an item definition becomes a
  duplicate ID or a dangling reference. Evidence that breaks the gates is not
  evidence.

The log is therefore a working artefact scoped to the change, and it dies with
the worktree. The **verification record** (`merge-change` 6b) remains the
durable evidence: totals, per-command results, verdict.

### D5 — exit 0 is not a pass

The gate summary always carries the tail of each command's output, **including
when the command exited 0**. A zero status proves the runner ran. Several
runners this toolkit's target projects use — storybook test runners, some
integration harnesses, anything wrapped in a script that forgets `set -e` —
exit 0 with failures in the report. The verdict comes from the reported
pass/fail counts, never from the status code. This is the same defect class as
`docs/plans/2026-08-12-false-green-fixes.md`, now applied to the gate itself.

### D6 — supersession is recorded, never silent

A new requirement may supersede an old one; that is normal. The failure is not
noticing. So the detection sits in `grill-requirements`, during the interview,
where the user is present to decide — and the old item is never deleted. It
stays in the file that defines it, annotated `superseded-by:`. Every existing
mechanism then keeps working: `check-trace.sh` still resolves references to it,
tests annotated `verifies:` against it do not orphan, and the ledger still reads
as a history. The reviewer's job reduces to confirming the annotations exist,
which is mechanical.

Skill-level only for now. A `check-trace.sh` rule that fails on changed item
text needs a baseline to diff against, which the scripts do not have; that is a
separate change with its own bats tests.

## The rule set

Each rule states the file it lands in. Rules are numbered for the review and
the verification record, not for the ledger — this repository has no SRS.

### `skills/grill-requirements/SKILL.md`

- **R1 — overlap probe.** Before writing a new REQ, dispatch a subagent to
  search the requirements ledger for items covering the same behavior. It
  returns IDs, one-line summaries and `file:line` — nothing else; the ledger
  must not enter the main context. Overlap, ambiguity or contradiction is put
  to the user and resolved with them.
- **R2 — supersession.** Superseding an existing requirement is legitimate and
  is recorded, not performed by deletion: the superseded item keeps its place in
  the file that defines it and gains `superseded-by: <new ID>`; the new item
  carries `supersedes: <old ID>`.
- **R3 — architecture probe.** A subagent probes the SAD and answers three
  questions: does an existing software item already own this behavior (then this
  is an amendment to that item's LLRs); does the requirement as worded force a
  structure the SAD forbids (segregation boundaries); does satisfying it need a
  new software item or new SOUP. On a contradiction, say so and hand off to
  `design-architecture`. **Never edit the SAD from this skill** — the REQ/LLR
  split is what keeps design decisions inside the skill that has the
  segregation and SOUP discipline. ADRs stay on the existing three-part test.

### `skills/worktree-discipline/SKILL.md`

- **R4 — task worktrees.** One change, one change worktree off the base branch.
  A task subagent creates its own task worktree off the **change branch** and
  its work returns to the change branch — never to base. This is an explicit
  carve-out in the "already isolated? don't nest another" step, which today
  tells a dispatched subagent to work in place.
- **R5 — the artefacts are the memory.** A conversation carries one change.
  Durable state lives in the plan, the ledger and the verification record; never
  in scrollback. This is what makes compacting between changes lossless.

### `skills/plan-change/SKILL.md`

- **R6 — files and parallelism per task.** Every task states the files it
  touches and whether it may run in parallel. Fan-out is permitted only across
  tasks whose file sets do not intersect; anything else is serial.

### `skills/develop-change/SKILL.md`

- **R7 — delegate by default.** Implementation goes to a subagent, even when
  there is only one task and no concurrency to gain. Do not ask the user for
  permission to dispatch. At most five concurrent subagents, disjoint files
  only (R6).
- **R8 — dispatch is a pointer.** The prompt names the task and the plan —
  "execute task N of `docs/plans/<file>` under the develop-change skill" — and
  does not restate it. `plan-change` already requires exact paths, real code and
  expected output; restating doubles the cost at both ends.
- **R9 — bounded dispatch report.** The subagent returns a fixed shape: task ID,
  files touched, tests added with their `verifies:` annotations, pass/fail
  counts, and anything surprising. No diffs, no logs. Without this rule the code
  simply arrives in the reply instead of in a read, and the delegation saves
  nothing.
- **R10 — derailment.** Escalate on repeated failure at the same point and
  nowhere else: the same task fails its red→green cycle twice, or the review
  returns findings on the same task twice. Then stop, report what is stuck and
  what was tried, and put the effort level or a different decomposition to the
  user. Below that threshold, keep looping — a single hard task is not a reason
  to stop.
- **R11 — read code only for a decision.** State the cost honestly: delegation
  raises total tokens and wall-clock, and costs the main agent its feel for
  cross-task drift. The main agent still owns the plan and the trace, and reads
  code when a decision genuinely requires it — the rule is not "never look".

### `skills/verify-before-merge/SKILL.md`

- **R12 — delegate the gate.** The gate runs in a subagent. It writes raw output
  to a file outside the repository or at a gitignored path (D4) and returns the
  gate summary: per-command pass/fail, totals, coverage figures where
  configured, and the tail of every command. The main agent quotes the summary
  and cites the log path; the durable evidence is the verification record.
- **R13 — exit 0 is not a pass.** The tail is included whether the command
  exited 0 or not, and the verdict is read from the pass/fail counts. Say why:
  a zero status proves the runner ran, not that the tests passed.

### `skills/merge-change/SKILL.md`

- **R14 — reviewer re-runs, unless docs-only.** Step 6a: for any change touching
  more than documentation, the reviewer runs the suite itself. For a docs-only
  change it may rest on the main agent's last run as evidence.
- **R15 — findings come back ready to file.** The reviewer returns findings in
  the `**finding-N**:` shape step 6b's record already wants, so they are copied
  rather than re-summarised.
- **R16 — docs checklist.** When the diff touches documentation, the reviewer
  checks: new items are in this change's draft file and no definition moved
  between files; IDs are well-formed minted tokens and amendments edit the
  defining file in place; item form holds (`**<ID>**: The software shall <single,
  testable behavior>`); `satisfies:` / `implements:` references resolve and
  derived items are marked; terms match `CONTEXT.md`; and anything removed or
  reworded carries the R2 supersession annotations.
- **R17 — compact at the boundary.** Step 8, after the signature check and
  cleanup: report the merge and recommend compacting the conversation before the
  next change, phrased harness-neutrally the way `worktree-discipline` already
  refers to worktree tools. R5 is what makes this safe.
- **R18 — changes are sequential.** One change is carried to its signed squash
  before the next is opened. Parallelism lives inside a change (R7), not across
  changes.

## Tasks

Six tasks. T1–T5 have disjoint file sets — so by D2 they may run in parallel;
T6 depends on their text and runs after them. Each is dispatched with the
canonical vocabulary and the full rule set, because the skills cross-reference
one another.

### T1 — `skills/grill-requirements/SKILL.md` (R1, R2, R3)

**Files touched:** `skills/grill-requirements/SKILL.md`
**Parallel:** yes

Add the overlap probe and supersession rules to the "Write requirements as they
crystallize" section, and the architecture probe as its own short section before
"Class awareness". Extend "Done when" so the interview is not done while an
overlap is unresolved.

### T2 — `skills/worktree-discipline/SKILL.md` (R4, R5)

**Files touched:** `skills/worktree-discipline/SKILL.md`
**Parallel:** yes

Carve out task worktrees in "Creating the worktree" step 1 and describe the
merge-back in "Inside the worktree". Add R5 as a short section. Add red-flag
rows for "I'll just have the subagents share this worktree" and "I'll remember
what task 3 did".

### T3 — `skills/plan-change/SKILL.md` (R6) and `skills/develop-change/SKILL.md` (R7–R11)

**Files touched:** `skills/plan-change/SKILL.md`, `skills/develop-change/SKILL.md`
**Parallel:** yes

R6 goes in "Task rules" and in the plan-header/self-review checklist. R7–R11
become a "Delegation" section in `develop-change`, placed after "Red — Green —
Refactor" so the TDD loop still reads as the primary content: the subagent runs
that loop, the main agent orchestrates it.

### T4 — `skills/verify-before-merge/SKILL.md` (R12, R13)

**Files touched:** `skills/verify-before-merge/SKILL.md`
**Parallel:** yes

Rewrite "The gate" preamble and the "After the gate" section so the gate is
dispatched, and add D4's reasoning and D5's false-green rule. The seven checks
themselves are unchanged — what changes is who runs them and where the output
lands.

### T5 — `skills/merge-change/SKILL.md` (R14–R18)

**Files touched:** `skills/merge-change/SKILL.md`
**Parallel:** yes

Amend step 6a (R14, R15, R16), step 8 (R17), and the preamble (R18). Add
red-flag rows.

### T6 — drift check (serial, after T1–T5)

**Files touched:** `README.md`, `AGENTS.md`
**Parallel:** no (serial, after T1–T5)

`README.md` and `AGENTS.md` describe the workflow. Read both against the merged
result and correct anything they now contradict. Runs after the others because
it depends on their text.

## Constraints on every task

- Skills are self-contained (`AGENTS.md`): no reference to superpowers or any
  external skill suite. Harness features are named neutrally with an example,
  the way `worktree-discipline` writes "e.g. `EnterWorktree`, a `/worktree`
  command".
- Match the existing voice: imperative, short lines, `**Announce at start:**`
  preserved, bullet lists over prose, red-flag tables where the file has one.
  American spelling ("behavior"), as the skills already use.
- Do not restructure a file beyond what the rules require. This is an amendment,
  not a rewrite.
- Frontmatter `name` stays; `description` changes only where a rule changes what
  the skill is for.

## Self-review before handing off

1. Every rule R1–R18 appears in exactly one file, in the section named above.
2. The canonical vocabulary is used identically across all six skills.
3. No skill instructs the agent to stop for the user outside the three
   sanctioned points.
4. `sh tests/run-tests.sh` — 409 green, unchanged.
