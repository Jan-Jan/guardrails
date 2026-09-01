# Task worktrees are nested inside the change worktree

Resolves **PR-n57ayn**
(`docs/problems/2026-09-01-task-worktree-fallback.md`).

## Root cause

`worktree-discipline` step 1 tells a dispatched subagent to put its task
worktree "in whichever directory this project already uses for worktrees",
and then presents the two usual locations as equivalent — differing only in
whether they need a gitignore entry, which reads as a point in the harness
location's favour ("no ignore entry is needed"). Convention is the wrong
selector. The property that decides whether a task worktree is usable is
**containment**: a harness that isolates a subagent pins it to a subtree, and
only a worktree nested inside the change worktree is inside that pin.

Measured 2026-08-31 from a dispatched subagent (probe, this change):

| location | `git worktree add` | `git -C` | Write tool | `EnterWorktree({path})` | commit | `tests/run-tests.sh` |
|---|---|---|---|---|---|---|
| `.worktrees/<branch>-t<N>` inside the change worktree | ok | ok | ok | ok | ok | ok |
| `.claude/worktrees/<branch>-t<N>` beside it | ok | refused | refused | "success", then unusable | unreachable | unreachable |

The refusal is `a worktree-isolated session's git operations must target its
own worktree`. Nothing about task worktrees is broken; the rule names the
wrong directory, and this repository's own convention (`.claude/worktrees/`)
is the one that does not work.

Three things delayed the failure past the point of no return: creation
succeeds in both locations; a plain shell redirect to an outside path is not
blocked even though the Write tool is, so a file appears to be written; and
`EnterWorktree` with an out-of-pin path reports success and then refuses every
subsequent Bash call, including `pwd`, with no shell-level recovery — the only
way back is to re-enter the change worktree's own path.

## Decisions

- **D1.** State the rule as containment, not convention. The task worktree is
  nested inside the change worktree, at `.worktrees/<change-branch>-t<N>`.
  The harness location is for change worktrees only.
- **D2.** The dispatcher names the path in the dispatch prompt rather than
  leaving the subagent to choose it. A subagent cannot discover its pin before
  it violates it.
- **D3.** Record the two false-success traps (shell redirect, `EnterWorktree`)
  as red flags, with the recovery. They are why this cost a whole change to
  find.
- **D4.** `.gitignore` gains `.worktrees/`. The skill already makes that entry
  the dispatcher's precondition, and this repository did not satisfy it when
  this change opened (at `b7fbd7f` the file held `.claude/worktrees/`,
  `tests/.bats-core` and `*.bak` only) — so the correct location would have
  dirtied `verify-before-merge`'s clean `git status`. `main` then added the
  same line independently at `860dce4`, and the base merge at step 1 kept both
  copies; T3 deletes the duplicate. The entry is still this change's
  precondition — it is simply no longer this change that introduces it.

## Tasks

### T1 — the rule names a nested path, and a test holds it there

**Files touched:** `skills/worktree-discipline/SKILL.md`,
`skills/develop-change/SKILL.md`, `AGENTS.md`, `.gitignore`,
`tests/skills.bats`
**Parallel:** no — single task; every file below is edited by this task alone.

Reproduction tests first, in `tests/skills.bats`, each annotated
`# verifies: PR-n57ayn`, each watched failing before the prose exists:

1. `worktree-discipline: the task worktree is nested inside the change worktree`
   greps `skills/worktree-discipline/SKILL.md` for the load-bearing phrases
   `nested inside the change worktree`, `pins that subagent to a subtree`,
   and `reports success and then refuses`.
2. `develop-change: the dispatch prompt names the nested task worktree path`
   greps `skills/develop-change/SKILL.md` for the literal
   `.worktrees/<change-branch>-t3` in the prompt template.
3. `the repository ignores the nested task-worktree directory` greps
   `.gitignore` for a whole line `.worktrees/`.

Then the edits:

- `skills/worktree-discipline/SKILL.md` step 1 — replace the "two usual
  locations" passage with the containment rule (D1) and the measurement that
  produced it. The task worktree goes at `.worktrees/<change-branch>-t<N>`,
  inside the change worktree, and that directory must be gitignored; the
  harness location is where change worktrees live and is not available to a
  dispatched subagent.
- same file, red flags — add the two false-success traps (D3) and the
  recovery.
- `skills/develop-change/SKILL.md` — the dispatch prompt template names the
  path (D2); the `worktree:` paragraph's rationale is corrected, since the
  dispatcher now states the path instead of learning it from the report. The
  report line stays, as confirmation that the subagent went where it was sent.
- `AGENTS.md` non-negotiable 1 — say the task worktree is nested.
- `.gitignore` — add `.worktrees/` (D4).

Green: `tests/run-tests.sh` reports 435 + 3 = 438 passed, 0 failed.

### T2 — two costs of nesting that the T1 run exposed

**Files touched:** `skills/develop-change/SKILL.md`,
`skills/worktree-discipline/SKILL.md`, `tests/skills.bats`
**Parallel:** no — follows T1; edits the same three files.

T1's own dispatch surfaced two things the new rule does not yet say. Both are
consequences of nesting, so they belong with it.

- **The dispatch template is now unfollowable as written.** It still ends
  "do not merge it, do not enter the change worktree", but under the
  containment rule the subagent *starts* pinned in the change worktree and
  must run `git worktree add` from there. The prohibition that is actually
  meant is narrower: do not commit on the change branch, and do not work in
  the change worktree once your task worktree exists.
- **A fresh task worktree holds only tracked files.** Everything gitignored is
  absent from it — a vendored test runner, installed dependencies, a build
  cache. The T1 subagent found no `tests/.bats-core` and `run-tests.sh` would
  have tried to `git clone` bats-core to replace it, which fails outright on a
  machine without network access to it. Copying the artifact in from the
  change worktree costs nothing and leaves the tree clean, because the path is
  gitignored by definition. Say so where the subagent will read it, in
  `worktree-discipline`'s task-worktree passage.

Reproduction tests in `tests/skills.bats`, annotated `# verifies: PR-n57ayn`,
each watched failing first:

4. `develop-change: the dispatch prompt forbids the change branch, not the
   change worktree` — asserts the template no longer contains
   `do not enter the change worktree`, and does contain `do not commit on
   <change-branch>`.
5. `worktree-discipline: a fresh task worktree has none of the ignored
   artifacts` — greps for `only tracked files` and `gitignored by definition`.

Green: 438 + 2 = 440 passed, 0 failed.

## Review findings and dispositions (2026-09-01, first review)

The independent review returned eight findings, ran the suite itself (440 ok,
0 not ok) and mutation-tested the five new tests (10 mutants, 9 killed). Seven
findings are accepted in full; one is accepted with a correction.

- **finding-1** — accepted. D2 was applied at one dispatch site only.
- **finding-2** — accepted with a correction. The duplicate `.gitignore` line
  and the now-vacuous test are real: `.worktrees/` appears twice, and deleting
  only the line this change added leaves the test green. But the review infers
  that the red -> green attestation "cannot be true", and that inference is
  wrong. At `b7fbd7f`, where this branch started, `.gitignore` held only
  `.claude/worktrees/`, `tests/.bats-core` and `*.bak` — the test was genuinely
  red. `main` added the same line independently at `860dce4`, and the base
  merge at step 1 kept both. The attestation was true when made; what is false
  is the present-tense prose in D4 and in the problem record, written before
  the base moved. Fix the duplicate and the prose; keep the test, which pins a
  precondition the new rule depends on and nothing else asserts.
- **finding-3** — accepted, and reproduced independently in a scratch
  repository: with a nested task worktree holding uncommitted work, the change
  worktree's `git status` is clean, `git worktree remove <change-worktree>`
  exits 0 **without** `--force`, the task worktree's uncommitted work is
  destroyed, and a `prunable` registration and an orphan task branch are left
  behind. `finish-merge.sh` guard 3 delegates to exactly that refusal, so
  nesting made guard 3 blind to a state it was written to catch. This change
  created the hazard, so this change closes it — see T4.
- **finding-4** — accepted. The table row and the red flag contradict each
  other; the plan's own table was the precise one.
- **finding-5** — accepted. `worktree-discipline` ships to other projects via
  `/ratchet`, so a location rule stated as a law about harnesses is a law
  those projects did not measure.
- **finding-6** — accepted. "Harness tool first" was deleted with nothing put
  in its place, and `<N>` is never defined.
- **finding-7** — accepted. Step 1 and step 3 disagree about `.worktrees/`.
- **finding-8** — accepted. The symptom sentence carries a diagnosis the
  resolution refutes.

### T3 — answer the review's prose findings

**Files touched:** `skills/worktree-discipline/SKILL.md`,
`skills/develop-change/SKILL.md`, `skills/merge-change/SKILL.md`,
`skills/verify-before-merge/SKILL.md`, `skills/ratchet/SKILL.md`,
`AGENTS.md`, `.gitignore`, `tests/skills.bats`,
`docs/problems/2026-09-01-task-worktree-fallback.md`
**Parallel:** no — must not run beside T4; both run the suite, and concurrent
full-suite runs wedge this machine's ssh-agent.

- f1: name `.worktrees/<change-branch>-<tag>` at every dispatch site that
  creates a task worktree — `merge-change` step 6a (reviewer),
  `verify-before-merge` and `merge-change` for the fix dispatch — not only in
  `develop-change`.
- f2: delete the duplicated `.gitignore` line; correct D4 above and the
  problem record so both state that the entry was absent when the change
  opened and arrived on the base branch independently.
- f4: the table row is the **write tool**, not "file writes"; drop
  "everything the subagent needs to do afterwards is refused there", which the
  red flag two screens later contradicts.
- f5: scope the normative claim to a harness that pins a dispatched subagent
  to a subtree, dated and named as one observation, and say what a project
  whose harness does not pin should do.
- f6: restore "harness tool first" and state how the subagent gets *inside*
  what it created; define `<N>`, including the review worktree, which has no
  task number (`.worktrees/<change-branch>-review` is already the convention
  in this repository's history).
- f7: reconcile step 1 with step 3's fallback, and with `ratchet`.
- f8: the symptom sentence states the observable symptom only; the diagnosis
  stays in the resolution, where it is corrected.

Tests, `# verifies: PR-n57ayn`, each watched red first, using
`run grep` + explicit status for every negative assertion (bash suppresses
errexit for a negated command, so a bare `! grep` anywhere but the test's
final line passes on whatever it found):
6. `merge-change: the review dispatch names the reviewer's worktree path`
7. `worktree-discipline: the location rule is scoped to a pinning harness`
8. `worktree-discipline: the task worktree passage says how to get inside`
9. `the repository ignores the nested task-worktree directory exactly once`

Green: 440 + 4 = 444 passed, 0 failed.

### T4 — guard 3 sees nested worktrees again

**Files touched:** `scripts/finish-merge.sh`, `tests/finish-merge.bats`,
`README.md`
**Parallel:** no — follows T3.

`finish-merge.sh` gains a guard, before it removes anything, that refuses when
any registered worktree lies inside the change worktree being removed. Same
contract as the existing three: no escape hatch, refuse with exit 1, leave the
signed commit and the branch intact. POSIX sh, no new dependencies.

Reproduction test first, watched failing: a nested task worktree holding
uncommitted work must make `finish-merge.sh` refuse, naming the nested path —
and the pre-guard script must be shown destroying that work, which is what
makes the test worth having.

Green: 444 + 2 = 446 passed, 0 failed.

## Review findings and dispositions (2026-09-01, second review)

Eleven findings; the suite re-run twice in the reviewer's own nested worktree
(446 ok, 0 not ok both times); 24 mutants tried, 24 killed — six against
guard 4 and eighteen against the eleven annotated prose tests, none of which
survived deletion of its subject. Ten findings accepted, one noted as process
order rather than a defect.

- **finding-1** — accepted. The two new `finish-merge.bats` tests compare
  against a path built from `$BATS_TEST_TMPDIR`, while the script prints what
  `git worktree list --porcelain` records, and git resolves symlinks. On macOS
  `TMPDIR` sits under `/var` -> `/private/var`, so the spellings differ and
  both tests go red on a platform AGENTS.md declares first-class.
- **finding-2** — accepted, and reproduced: `awk -v` performs escape
  processing on the assigned value, so `wt\top/` reaches the program as
  `wt<TAB>op/`. A change-worktree path containing a backslash makes the prefix
  test never match, `$nested` comes back empty, and guard 4 **fails open** —
  destroying the work it exists to protect, silently. The existing comment
  reasons only about literal newlines. This is the one guard whose failure
  loses work rather than withholding cleanup, so it gets a design that has no
  escape layer at all: a POSIX `while read` loop with a `case` prefix test,
  no `awk -v`.
- **finding-3** — accepted. `merge-change` step 7 still says the script
  "proves three things", and step 8's refusal table — the one place that maps
  a refusal to a remedy — has no row for guard 4.
- **finding-4** — accepted, and the most serious. Step 6a now dispatches every
  reviewer into `.worktrees/<change-branch>-review`, nested inside the change
  worktree, and no step in `merge-change` removes it. Guard 4 would therefore
  refuse on the documented happy path of **every** change. This change turned
  a harmless leftover into a hard block without adding the step that clears
  it; the sequence gets that step.
- **finding-5** — accepted. The "take the worktree's path from the dispatch
  report rather than rebuilding it" passage still argues from the two
  locations step 1 retired.
- **finding-6** — accepted. `affects:` names four files and the change touches
  ten; the resolution accounts for nine tests where eleven carry the ID, and
  never mentions the `finish-merge.sh` guard — the only code in the diff.
- **finding-7** — accepted. f1 is delivered at two of three dispatch sites;
  `merge-change` step 6c names no path, and nothing pins
  `verify-before-merge`'s text, so deleting it leaves the suite green.
- **finding-8** — accepted. Guard 4 prints the first nested worktree and
  exits, so a five-way fan-out is refused five times, each round paying a full
  `check-signing.sh --strict`. It reports all of them instead. The reviewer
  verified by direct probe that spaces in paths and a prefix-sharing sibling
  behave correctly; no test holds either, and the new loop must keep both.
- **finding-9** — accepted. The new step 6a paragraph orphans the sentence
  after it, which now reads as attaching to the reviewer's worktree.
- **finding-10** — accepted. "Prove you are inside — `pwd` and `git status` in
  the target" is unfollowable on the branch that just told the agent to stay
  put; `git -C <path> status` is the check that works there. The passage also
  never says how to enumerate the ignored artifacts to copy —
  `git status --ignored` in the change worktree.
- **finding-11** — (a) is process order, not a defect: the verification record
  is written at step 6b, after the review it records. (b), (c) and (d)
  accepted: pin the `ratchet` and `AGENTS.md` normative additions with tests,
  restore the `Green:` lines on T3/T4, rewrap `AGENTS.md:15`.

Also adopted from the review's control experiment: the comment "a bare
`! grep` never fails the test" is over-general — the status is swallowed only
when the negation is not the test's final command. The comment says that
instead.

### T5 — guard 4 cannot fail open, and reports every nested worktree

**Files touched:** `scripts/finish-merge.sh`, `tests/finish-merge.bats`
**Parallel:** no — must not run beside T6; both run the suite, and concurrent
runs wedge this machine's ssh-agent.

- f2: replace the `awk -v` prefix test with a POSIX `while read` loop and a
  `case` prefix match, so no value is escape-processed on its way in. Check
  the status of any command substitution that remains.
- f8: collect every nested worktree, not the first; word the refusal for one
  or many.
- f1: the fixture compares against the path git reports. Resolve the fixture's
  own path the way git does before asserting on it.
- New tests, each watched red: a backslash-bearing change-worktree path must
  still be refused (this is the fail-open, and it must be seen failing open
  before the fix); two nested worktrees must both be named; a
  prefix-sharing sibling (`<wt>-sibling`) must NOT be treated as nested; a
  path containing spaces must still be refused.

Green: 446 + 4 = 450 passed, 0 failed.

### T6 — the process no longer blocks on its own guard

**Files touched:** `skills/merge-change/SKILL.md`,
`skills/worktree-discipline/SKILL.md`,
`AGENTS.md`, `tests/skills.bats`,
`docs/problems/2026-09-01-task-worktree-fallback.md`,
`docs/plans/2026-09-01-task-worktree-containment.md`
**Parallel:** no — follows T5.

f3, f4, f5, f6, f7, f9, f10, f11b/c/d as dispositioned above. The removal step
for the review worktree (f4) is the one that must not be got wrong: it belongs
in `merge-change`'s sequence, before the squash is staged, and it is pinned by
a test.

Green: 450 + 5 = 455 passed, 0 failed.

## Review findings and dispositions (2026-09-01, third review)

Seven findings; suite re-run in the reviewer's own nested worktree (455 ok, 0
not ok); 21 mutants against the real script and suite, 18 killed, plus 24
adversarial cases against guard 4's loop under both `bash` and `dash`. All
seven accepted.

Guard 4's rewrite survived the attack it was given: backslashes, spaces, tabs,
non-ASCII, trailing space, leading dash, CR, deep nesting, and — the one that
would have failed *open* — glob metacharacters `*`, `?` and `[bc]` in the
change worktree's path, which match a real nested worktree and not a decoy,
because the `case` pattern's variable half is quoted and therefore literal.
One mutant survived, `IFS=` dropped from `while IFS= read -r`; the reviewer
could construct no fail-open from it, since trailing-whitespace stripping can
only shorten a path's tail and never break a prefix, and recorded it as tried
and survived rather than as a finding. That judgement is accepted.

- **finding-1** — accepted, and blocking. Step 6d is unreachable on exactly
  the rounds that need it. Step 6a ends "the sequence reruns from step 1" when
  findings come back, so 6b, 6c and 6d are skipped; 6d is reached only on the
  final, finding-free round. The review worktree's path and branch are now
  *fixed*, so every intermediate round's worktree survives and the next
  round's 6a dispatch collides — demonstrated by executing 6a's own command:
  `fatal: a branch named 'worktree-task-worktree-fallback-review' already
  exists`. This change's own history is the case that hits it: three review
  rounds, each worktree removed by hand because the skill does not say to.
  Same shape as the second round's finding-4 — a hard block added without the
  step that clears it — one stage further along. **The removal belongs at the
  end of 6a**, where the dispatch ends, which is what `worktree-discipline`
  already says of every task worktree: it dies with its dispatch, at the
  dispatcher's hand. Step 6d keeps the structural check that nothing is
  registered inside the change worktree, so a skipped removal is still caught
  before the squash.
- **finding-2** — accepted. `merge-change: the review dispatch names the
  reviewer's worktree path` greps an unanchored literal, and step 6d added two
  more occurrences of it, so mutating the step 6a occurrence survives the
  suite. The test the second round asked for was made vacuous by the second
  round's own other fix. Anchor it the way its sibling anchors — by position,
  not by presence.
- **finding-3** — accepted. `merge-change`'s two other dispatch-path
  statements (the sequence header's fix dispatch, and 6a's findings fix) are
  normative and unasserted; a mutant replacing both survived.
- **finding-4** — accepted. The two command-substitution status checks added
  to `finish-merge.sh` are behavior changes with no bats test, against
  AGENTS.md. They are not decorative: without the first, a failing
  `git worktree list` leaves `$wt` empty, guard 4 and the removal are both
  skipped, and `git branch -D` runs anyway. `tests/portability.bats`'s stub
  machinery already provides the way to exercise this.
- **finding-5** — accepted. The red-flag row "Prove the location with
  `git status` in the target" still carries the framing the second round's
  finding-10 retired, and the negative assertion pins only the other spelling.
- **finding-6** — accepted. Step 6d names the state to check without a remedy
  for a review worktree left dirty by untracked scratch.
- **finding-7** — accepted, cosmetic. T6's **Files touched:** names
  `verify-before-merge`, which its commit does not touch; and
  `tests/finish-merge.bats:33` describes a helper the file no longer calls.

### T7 — the review worktree dies with its dispatch

**Files touched:** `skills/merge-change/SKILL.md`,
`skills/worktree-discipline/SKILL.md`, `tests/skills.bats`,
`tests/finish-merge.bats`, `docs/plans/2026-09-01-task-worktree-containment.md`
**Parallel:** no — single task.

f1 through f7 as dispositioned. f1 is the one that must be right: removal moves
to the end of step 6a, on every round, findings or not; 6d keeps the
structural check; `worktree-discipline`'s cross-reference follows the removal
to its new home. Pin f1 by position, not presence — the same way 6d's ordering
is pinned — and fix f2's test in the same idiom while you are there.

Green: 455 + 5 = 460 passed, 0 failed.

## Red -> green attestations

`develop-change` requires these written into the plan as each dispatch report
lands. They were not, and the fourth review caught it: seven reports existed
only in the dispatcher's scrollback, which is the state
`worktree-discipline`'s "the artifacts are the memory" exists to prevent. They
are recorded here, keyed by task rather than inline, because the task blocks
were written before the reports came back. Each line is the dispatched
subagent's own attestation — it ran the loop and is the only party that saw
the test fail.

**T1** (438 passed, 0 failed)
- `worktree-discipline: the task worktree is nested inside the change worktree`
  — red: `nested inside the change worktree` was absent from the skill.
- `develop-change: the dispatch prompt names the nested task worktree path`
  — red: the prompt template named no path at all.
- `the repository ignores the nested task-worktree directory` — red:
  `.gitignore` held only `.claude/worktrees/`, `tests/.bats-core` and `*.bak`.

**T2** (440 passed, 0 failed)
- `develop-change: the dispatch prompt forbids the change branch, not the
  change worktree` — red on the removal assertion `[ "$status" -ne 0 ]`, with
  `do not enter the change worktree` still in the template. The first draft of
  this assertion was toothless (`! grep` suppresses errexit under bash); it was
  rewritten as `run grep` plus an explicit status and then observed failing.
- `worktree-discipline: a fresh task worktree has none of the ignored
  artifacts` — red on `only tracked files`; the passage did not exist.

**T3** (444 passed, 0 failed)
- `merge-change: the review dispatch names the reviewer's worktree path` — red:
  no `.worktrees/<change-branch>-review` anywhere in the skill.
- `worktree-discipline: the location rule is scoped to a pinning harness` —
  red: the rule was stated as a law about harnesses, with no scoping.
- `worktree-discipline: the task worktree passage says how to get inside` —
  red: `harness tool first` had been deleted and `<N>` was undefined.
- `the repository ignores the nested task-worktree directory exactly once` —
  red: `grep -cx` returned 2, the duplicate the base merge kept.
- The negative assertion in the scoping test was itself mutation-checked: a
  decoy line carrying the old universal phrasing was injected alongside the new
  scoped one, and the test then failed at the status assertion — so the
  negative bites and is not toothless.

**T4** (446 passed, 0 failed)
- `finish-merge: a worktree nested inside the change worktree fails with
  everything intact` — red against the pre-guard script: expected exit 1, got
  0, with `worktree removed:` and `branch deleted:` printed and the nested
  worktree's uncommitted `NEW.txt` gone from disk.
- `finish-merge: a nested worktree is refused even when it holds nothing
  uncommitted` — red for the same reason. Added beyond the plan, deliberately:
  a guard firing only on a *dirty* nested worktree would leave the clean case —
  silently deleted directory, prunable registration, orphan branch — reachable.

**T5** (450 passed, 0 failed)
- `finish-merge: a backslash in the change worktree's path does not defeat the
  guard` — red, and this is the fail-open watched failing open: the shipped
  script exited 0, printed `worktree removed: …/w<TAB>op`, and the assertion
  that reddened was `the nested worktree's uncommitted work was destroyed`.
- `finish-merge: every nested worktree is named, not just the first` — red: the
  refusal named only `my-change-t1`.
- The two T4 tests were red under a deliberately symlinked `TMPDIR` before the
  fixture was fixed, which is how the macOS failure was reproduced on Linux.
- Two further tests — a prefix-sharing sibling, and spaces in the path — were
  **green on arrival** and are regression cover for the rewrite, not
  attestations. Reported as such by the subagent rather than dressed as a
  cycle.

**T6** (455 passed, 0 failed)
- `merge-change: the sequence removes the review worktree before the squash` —
  red twice: first with no removal command anywhere in the sequence, then again
  on the `worktree-discipline` cross-reference before that bullet was
  corrected.
- `merge-change: step 8 maps guard 4's refusal to a remedy` — red: step 7 still
  said the script proves three things and the table had no guard-4 row.
- `worktree-discipline: the task worktree passage says how to get inside`
  (existing test, strengthened) — red: the passage still said `pwd` and
  `git status` in the target.
- Three tests were **green on arrival**, pinning normative prose that already
  existed and that nothing asserted (`verify-before-merge`, `ratchet`,
  `AGENTS.md`). Each was mutation-checked individually — subject deleted, that
  one test watched failing on exactly that assertion, subject restored — and
  reported as a finding rather than as a red -> green.

**T7** (460 passed, 0 failed)
- `merge-change: the review worktree dies at the end of its own dispatch` —
  red on `[ "$remove_at" -lt "$b_at" ]`: the only removal command sat inside
  step 6d, not inside 6a.
- `merge-change: a review worktree left dirty by scratch has a remedy` — red:
  the remedy prose did not exist.
- `worktree-discipline: the task worktree passage says how to get inside`
  (extended for the third round's f5) — red: the red flag still said
  `git status` in the target.
- Three tests were **green on arrival** and mutation-checked individually: the
  two `finish-merge` status-check tests (deleting each `|| gr_die` in turn,
  both mutants killed, script restored unmodified) and `merge-change: every fix
  dispatch names the nested task worktree path`. The rewritten
  `merge-change: the review dispatch names the reviewer's worktree path` was
  confirmed by re-running the exact mutant the third review reported surviving.

**T8** (463 passed, 0 failed)
- `merge-change: step 6d's criterion is containment, not an empty registry` —
  red on `Read the list for paths inside the change worktree`; the criterion
  was still the absolute sentence that condemned every unrelated worktree.
- `merge-change: the review worktree removal is conditioned on one existing` —
  red on `every round that created one`; the removal still read "Every round,
  findings or not".
- `merge-change: a fix dispatch's tag is unique, and AGENTS.md defers on tags`
  — red on `must be unique per dispatch`, then red again on the `AGENTS.md`
  assertion.
- `merge-change: a review worktree left dirty by scratch has a remedy`
  (existing test, strengthened) — red on `Nothing gitignored is among them`,
  with the false example still in the skill.
- Every negative assertion in all four was mutation-checked individually after
  the fact, because the red runs stopped at the positives: the retired
  phrasing was injected as a decoy, each test watched failing at its
  `[ "$status" -ne 0 ]`, and the file restored byte-for-byte.

**T9** (463 passed, 0 failed — no new tests; two existing tests changed with
the prose they pin)
- `merge-change: a fix dispatch's tag is unique, and AGENTS.md defers on tags`
  — red at `insurance against a cleanup that was missed`; the honest rationale
  did not exist. `must be unique per dispatch` was green on arrival, the rule
  itself being kept; `collide at creation` was inverted from a positive
  assertion to a negative one.
- `AGENTS.md: non-negotiable 1 nests the task worktree and names its path` —
  red at `.worktrees/<change-branch>-<tag>`; the second path form did not
  exist.
- Both red runs stopped at the first new positive, so every assertion they did
  not reach was mutation-checked individually against the finished prose and
  the file restored byte-for-byte each time, `git diff` confirming it: seven
  mutants, seven killed, including all four negative assertions exercised by
  reintroducing the phrase each forbids.

**T10** (463 passed, 0 failed — no new tests; one existing test gained five
assertions)
- `merge-change: a fix dispatch's tag is unique, and AGENTS.md defers on tags`
  — red before the correction existed. Each new phrase was independently
  confirmed absent from the skill first (`git worktree remove` and then
  `git branch -d`, `git validates the new branch name`, `skipped cleanup also
  leaves a nested worktree still registered`, `guard 4 refuses at step 8` — all
  at zero occurrences), and the newly forbidden `it is only a stale branch` was
  present at one, so the negative assertion was red as well.
- The record half of T10 is prose only: nothing in the suite pins the problem
  record's review-process paragraph, and after this change nothing should —
  that paragraph now points at this plan precisely so it carries no number that
  can go stale.

**This section is the home for every task's attestations, wherever the task
block itself sits.** Later review rounds append their disposition sections
below, so a new task's lines are inserted *here*, above them, rather than at
the end of the file. The fifth review caught T8's missing because the previous
round's fix had put the section above the sections that keep growing — write
the block as the report lands, before the disposition that follows it.

## Review findings and dispositions (2026-09-01, fourth review)

Seven findings — three blocking, one evidence gap, three notes. Suite re-run
twice in the reviewer's own nested worktree (460 ok, 0 not ok, identical); 40
mutants, 38 killed. The two survivors are both judged equivalent mutants and
the judgement is accepted: `while IFS= read -r` -> `while read -r` (trailing
whitespace can only shorten a path's tail, never break a prefix — the third
review reached the same conclusion independently) and `case "$gr_path" in` ->
`case $gr_path in` (POSIX performs neither field splitting nor pathname
expansion on a `case` word).

The mechanism is now confirmed sound by two consecutive rounds: the removal at
the end of 6a, guard 4, and the 25 tests all survived attack. What both rounds
found instead is that the *newest* edit carried the next defect — this time in
step 6d's criterion and in the remedy paragraph the third round asked for.

- **finding-1** — accepted, blocking. Step 6d's heading is containment-scoped
  ("nothing registered **inside** the change worktree", which is what guard 4
  objects to) but its criterion sentence is absolute: "Nothing but the primary
  checkout and the change worktree may still be registered." Run literally in
  this repository that condemns three unrelated worktrees — two of them
  tooling, not changes — none of which guard 4 would ever mention. The
  criterion becomes the containment test the heading already states.
- **finding-2** — accepted, blocking, and reproduced: a review worktree holding
  only gitignored scratch has an empty `git status --porcelain`, and
  `git worktree remove` removes it with no refusal. The remedy paragraph at
  step 6a lists "a test runner copied in because it was gitignored and
  therefore absent" as a cause of the refusal — the one example in its list
  that cannot cause it, and self-refuting on its face. Worse, it is the
  negation of the property this same change relies on twice: guard 4 exists
  *because* a gitignored nested worktree leaves `git status` clean, and
  `worktree-discipline` states the rule correctly. The remedy itself is right;
  only the example goes.
- **finding-3** — accepted, blocking. The problem record's resolution describes
  step 6d as the fix that removes the review worktree — the third round moved
  that to 6a — says twenty tests where there are 25 (17 + 8), says three tests
  were green on arrival where six were, and says two independent reviews where
  there have been four. 6b copies the attestation story from this record, so
  the green-on-arrival count is the serious half.
- **finding-4** — accepted, and it was the dispatcher's to fix, not a
  subagent's: the `red -> green:` attestations for T1-T7 existed only in
  scrollback. Written into the plan above, from the seven dispatch reports,
  before this disposition was recorded. The reviewer's context is fair — only
  one of the 21 plans in `docs/plans/` carries them, so this is repo-wide
  drift — but this change edits the two skills that mandate it.
- **finding-5** — accepted. Step 6a's removal is stated unconditionally, while
  the same step documents two paths on which no review worktree exists (a
  human reviewer, and class A skipping the step). Under a sequence headed
  "Halt on any failure", `git worktree remove` on a path that was never
  created is a failure. 6d's wording is already correctly conditioned; 6a
  follows it.
- **finding-6** — accepted. The fix-dispatch tag is unconstrained and nothing
  says to vary it between rounds, so two findings rounds that both choose the
  natural `-fix` reproduce the third round's collision one level down. Milder
  — the name is the author's, the failure is loud, and it happens at creation
  before any work — but it is the same defect and it is cheap to close.
  `AGENTS.md`'s enumeration of `<N>` also has no slot for a fix tag;
  `worktree-discipline` states it generally and is the one that is right.
- **finding-7** — accepted as recorded, no change. Two new tests are
  deliberately over-tight (an exact count of 2, and a blanket ban on the
  literal `step 6d` in `worktree-discipline`). Both kill their intended
  mutants; both will bite on unrelated edits. Recorded here so a future editor
  meets the reason rather than the failure.

### T8 — the criterion matches the guard, and the record matches the change

**Files touched:** `skills/merge-change/SKILL.md`, `AGENTS.md`,
`docs/problems/2026-09-01-task-worktree-fallback.md`,
`tests/skills.bats`
**Parallel:** no — single task.

f1, f2, f3, f5 and f6 as dispositioned. f2 is the one to get exactly right: the
remedy stays, the false example goes, and nothing in the change may end up
asserting that gitignored files can dirty `git status` — guard 4's rationale
depends on the opposite.

Green: 460 + 3 = 463 passed, 0 failed.

## Review findings and dispositions (2026-09-01, fifth review)

Four findings — two blocking, two notes. Suite green in the reviewer's own
nested worktree (463 ok, 0 not ok); 19 mutants, 17 killed, the two survivors
being the previously reported equivalent pair, re-derived independently under
both `bash` and `dash` rather than inherited.

The mechanism is now confirmed by three consecutive rounds: guard 4, the step
6a removal, the 6d criterion and all 28 tests survived attack, and every number
in the problem record was checked against the tree and holds.

- **finding-1** — accepted, blocking, and the dispatcher's own repeat of the
  fourth review's finding-4: T8's attestations were left in scrollback. Fixed
  before this disposition was written. The structural cause is worth naming —
  the attestations section sits above the disposition sections, which keep
  growing, so each new task's block must be inserted above them rather than
  appended. The section now says so.
- **finding-2** — accepted, blocking. The fix-tag uniqueness rule is justified
  by a collision this change's own discipline prevents: `worktree-discipline`
  removes a task worktree *and its branch* when the dispatch report comes back
  ("Either way the branch goes too, so nothing survives to `merge-change`"),
  so round 1's `-fix` branch is gone before round 2 dispatches. Worse, the
  justification contradicts step 6a, which keeps the `review` tag *fixed* on
  the reasoning that in-round removal makes fixedness safe. Both cannot be
  right. The rule survives as insurance against a cleanup that was missed —
  which is a real risk, since the fix worktree's removal is stated only in
  `worktree-discipline` and `develop-change`, not in `merge-change` — but it
  must say that instead of naming a collision the discipline forbids. The test
  pinning `collide at creation` changes with it.
- **finding-3** — accepted, note promoted to a fix because it is cheap and the
  text is literally wrong. `AGENTS.md` reads "`.worktrees/<change-branch>-t<N>`
  — `<N>` being the plan task number, with a dispatch without one taking a tag
  instead", which parses as substituting the tag *inside* `-t<N>`, giving
  `-treview` rather than the `-review` every other file names. Its parenthetical
  also attributes the uniqueness rule to `worktree-discipline` step 1, where it
  is not stated.
- **finding-4** — accepted as a follow-up, NOT fixed here. `merge-change` step 3
  runs `git add -A && git -c commit.gpgsign=false commit -m ...`
  unconditionally, while `finalize-docs.sh` is documented idempotent, so every
  rerun after the
  first stages nothing and exits 1 — a halt for no reason under a sequence
  headed "Halt on any failure". This is the same shape as the fourth review's
  finding-5 (an unconditional command that fails when its subject is absent),
  but step 3 is untouched by this diff and pre-dates it. It wants its own
  change, and gets a problem report rather than a widening of this one.

### T9 — the uniqueness rule says why it is really there

**Files touched:** `skills/merge-change/SKILL.md`, `AGENTS.md`,
`tests/skills.bats`
**Parallel:** no — single task.

findings 2 and 3 as dispositioned. finding-1 is already fixed and finding-4 is
deliberately out of scope.

Green: 463 passed, 0 failed — no new tests; two existing ones change with the
prose they pin.

## Review findings and dispositions (2026-09-01, sixth review)

Two findings — one blocking, one note. Suite green in the reviewer's own nested
worktree (463 ok, 0 not ok); 14 mutants against the two changed tests, 14
killed, every negative assertion exercised by re-injecting the phrase it
forbids. The reviewer independently re-checked every number in the problem
record and confirmed all but one, and re-derived T9's new justification against
`worktree-discipline` and step 6a rather than reading it.

- **finding-1** — accepted, blocking, and it exposes a defect in the record's
  design rather than only in its content. The record enumerated "four
  independent reviews returned eight, eleven, seven and seven findings"; five
  had run. But fixing the number cannot work: the round that reads the record
  is always the uncounted one, so any enumeration is stale the moment a
  reviewer looks at it, and each correction needs another round to confirm.
  The count moves out of the record entirely and points at this plan, which
  grows one disposition section per round and so is never stale by
  construction. `merge-change` 6b then carries the final review's verdict,
  which is the artefact that is supposed to hold it.
- **finding-2** — accepted, note. `merge-change`'s sequence header says a
  skipped cleanup met by a fresh tag "is only a stale branch, deletable
  whenever you notice it". The quoted `fatal:` is correct — the reviewer
  probed it, and git validates the branch name before the worktree path, so
  both a branch-only leftover and a fully skipped cleanup produce it. But
  "only a stale branch" describes the branch-only case, while the clause
  before it means the whole cleanup: a fully skipped one also leaves a
  registered nested worktree, gitignored and invisible to `git status`, which
  step 6d catches and guard 4 refuses at step 8 after a full
  `check-signing.sh --strict`. Nothing is lost, which is why it is a note —
  but this clause is the load-bearing half of the new justification and it
  understates what it is insuring against.

Round 5's finding-4 (step 3's unconditional `git add -A && commit` against an
idempotent `finalize-docs.sh`) stays out of scope and is recorded here rather
than opened as a ledger item: this change does not investigate it, and an open
`UNRESOLVED-PR` warning on every future merge should belong to the change that
does. It is the first thing to open when that change starts.

### T10 — the record stops counting its own reviews

**Files touched:** `skills/merge-change/SKILL.md`,
`docs/problems/2026-09-01-task-worktree-fallback.md`,
`tests/skills.bats`
**Parallel:** no — single task.

findings 1 and 2 as dispositioned.

Green: 463 passed, 0 failed — no new tests expected; one existing test gains an
assertion for the corrected clause.

## Review findings and dispositions (2026-09-01, seventh review)

No findings. The reviewer ran the suite in its own nested worktree (463 ok, 0
not ok), probed the two newest passages rather than reading them — confirming
in a scratch repository that git validates a new branch name before the
worktree path, so a skipped cleanup and a branch-only leftover produce the same
`fatal:` — swept every retired phrasing and found each surviving only inside
tests as a negative assertion and inside this plan as history, and confirmed
all four disposition categories the problem record names are instantiated
here. Six confirmatory mutants, six killed.

Two items were examined and deliberately not filed as taste rather than
defect, and that judgement is accepted: the header saying guard 4 "refuses at
step 8" while step 6d says a leftover "blocks step 7's cleanup" (both true of
different aspects — where the guard fires, and where its remedy is tabulated),
and T5's task block prospectively saying all four of its tests were watched
red where the attestations section records two as green-on-arrival regression
cover. The plan's convention is that a task block is the pre-dispatch
instruction and the attestations section is the record; the deviation is stated
honestly in the record half.

verdict: nothing blocks; the change is complete, internally consistent, and the
newest prose in both the problem record and `merge-change` is accurate under
direct probe.
