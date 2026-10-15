# Base move round Implementation Plan

**Goal:** A base move costs one gate run and no avoidable step: step 1 stops
before gating against a base that is about to move, a round with no reviewer
skips step 4, and the last review round is unambiguous when it found nothing.
**Implements:** D1–D5 below; guardrails keeps no REQ ledger of its own. Each
test cites `verifies: D<n> (docs/plans/2026-10-14-base-move-round.md)`.
**Resolves:** none.
**Safety class:** not configured in this repository; worked as class B (normal
and abnormal cases for each changed rule)
**Verification:** `tests/run-tests.sh`, every test passing.
**Base:** local `main` at `344faa3`, per AGENTS.md non-negotiable 4. Baseline:
`main`'s tree `49244466` is the `Gate-tree:` of 344faa3, whose gate reported
`tests/run-tests.sh 1450/1450`, so the baseline was not run again.

The user asked on 2026-10-14 whether a moved base must restart `merge-change`
at step 1 and whether that can be streamlined; after bb249ca moved the gate's
proof into trailers, they approved the three remaining items.

## Investigation

- A base move is detected at step 7 (`git diff --cached --quiet <branch>`
  fails after the squash ran) and sends the sequence back to step 1. The gate
  rerun is unavoidable: the merged tree was never tested, and suites here scan
  the whole tree.
- The base moves only when the user signs. While another change's squash is
  staged in the primary checkout's index, the base is about to move, and a gate
  started now is spent on a tree step 7 will reject. Step 1 does not look.
- `merge-preflight.sh --before-review` (step 4) is the step 6c run minus
  `REVIEW` (`scripts/merge-preflight.sh` header). In a round that dispatches no
  reviewer, step 4 repeats checks 6c runs again minutes later.
- The record is committed at 6b, after the step 2 gate, so the step 7 tree
  comparison always fails unless the record was written before the last
  rerun. The skill says so only for a round "whose `code` and `requirement`
  findings are all `low`"; a round with no finding fits only by a vacuous
  reading, so an agent can learn it at step 7.
- `skills/merge-change/SKILL.md` is at exactly 2,000 words, the cap
  `tests/skills.bats` enforces. Every addition needs an equal cut.

## Decisions

- **D1: step 1 stops on a staged squash.** Before the fetch, step 1's fence
  reads the primary checkout (the first `git worktree list --porcelain`
  entry) and exits 1 when its index is not empty, naming the path. The bullet
  tells the agent to stop and tell the user: once they sign or clear it, rerun
  step 1, which merges the new base in. Cost: the agent waits on the user
  instead of gating; a gate run now would be rejected at step 7 anyway.
  It also stops, naming the cause, when the primary checkout cannot be found
  (a failed `git worktree list`) or its index cannot be read: either would
  otherwise let the check pass on the wrong index (CODE round 1 finding-6,
  round 4 finding-1).
- **D2: a round that dispatches no reviewer skips the pre-flight before the
  review** (step 2 under D5; step 4 when this decision was written). That
  covers the rerun after the last review round and the rerun after a base move
  found at step 7; step 6c runs every check it runs. The base-move round is
  stated as such: steps 2 to 4 only on a `shared:` line, as a review round
  whose rerun reaches step 5; otherwise 5 only for a new `left whole` plan;
  then 6a to 7 (independent review round 1, finding-1).
- **D3: a round with no finding is the last too.** The last-round sentence
  reads "findings, if any, are all `low`".
- **D4: the gate runs after the record.** Ruled by the user on 2026-10-14,
  after T1 was dispatched. The order becomes: merge the base, pre-flight,
  review, record, gate, confirm the tree, pre-flight with the review check,
  squash. One gate per round, always on the tree that is signed: the record no
  longer forces a second gate, and step 7's tree comparison fails only when
  something changed after the gate. The reviewer's own suite run is the only
  test before review (it already ran on the same tree as the old early gate).
  Costs: a gate failure surfaces after the review, and its fix dispatches a
  reviewer unless it touches only the record or plan; a documentation-only
  diff no longer reuses a gate summary, so its reviewer skips the suite and the
  record says so.
- **D5: renumbering keeps the busiest labels.** 1, 6c, 6d, 7 and 8 keep their
  numbers. Old 4 → 2 (pre-flight before review), 5 → 3 (rule on what it
  cannot), 6a → 4 (review), 6b → 5 (record), 2 → 6a (gate), 3 → 6b (confirm the
  tree). D2's skip now names step 2. Dated history is not rewritten: `docs/plans/`,
  `docs/verification/` and `docs/problems/` keep the numbers they were written
  with. Live files follow the new labels: the ADRs (each with an amendment
  note) and every upgrade-notes entry, under a new entry that states the
  mapping (conformance round 1). A test name states the step's role, never its
  number, so a later renumbering cannot make it stale (round 2).

## Tasks

### T1 — Step 1's staged-squash stop, step 4's skip, the empty last round

**Files touched:** skills/merge-change/SKILL.md,
skills/merge-change/references/rationale.md, tests/skills.bats
**Parallel:** no (the only task)

Load the skill at `skills/develop-tdd/SKILL.md` in the change worktree. This
repository has no `.guardrails/`; its scripts are under `scripts/`.

1. RED, in `tests/skills.bats`, three tests after
   "merge-change: step 1's fence prunes only after a clean merge, and commits
   only the plans", modelled on it (`step1` extracted with awk, the fence run
   with `sh -c "BASE=main; $fence"`, `make_fixture_repo`, `commit_all`):
   - `merge-change: step 1 stops before merging while a squash is staged in
     the primary checkout` (verifies D1). Fixture: `main` with one commit, a
     change worktree created with `git worktree add` on branch `change` with
     one commit, then a second commit on `main` and a file staged with
     `git add` in the primary checkout. Run the fence from the change
     worktree: status 1, the output names the primary checkout's path, the
     change branch's HEAD is unchanged (no merge). Then
     `git -C <primary> reset -q` and run it again: status 0, and `main`'s
     second commit is an ancestor of the change's HEAD.
   - `merge-change: a round that dispatches no reviewer skips step 4`
     (verifies D2): step 4's text (`step_of "$skill" 4`, flattened with
     `tr '\n' ' ' | tr -s ' '`) contains `Skip this step in a round that
     dispatches no reviewer: 6c runs every check it runs.`, and step 7's
     flattened text contains `rerun from step 1 as a base-move round` .
     The rationale (flattened) has a heading line
     `## Step 4: skipped when no reviewer is dispatched`.
   - `merge-change: a round with no finding is the last` (verifies D3): the
     skill contains `findings, if any,` on the line before
     `are all \`low\` is the last review round.`
   Watch each fail on the missing text or behavior, not on a helper or typo.
2. GREEN, in `skills/merge-change/SKILL.md`:
   - Step 1's fence, before the `if [ -n "$(git remote)" ]` line:

     *(Code pruned at merge: 3 lines. Files touched: skills/merge-change/SKILL.md, skills/merge-change/references/rationale.md, tests/skills.bats.)*

     and a first bullet under the fence: `A staged squash in the primary
     checkout is a **stop**: tell the user, and once they sign or clear it,
     rerun this step.`
   - Step 4 gets the sentence `Skip this step in a round that dispatches no
     reviewer: 6c runs every check it runs.`
   - Step 7's bullet "It printed other output: the base moved after step 1.
     Run `git reset --merge`, then rerun from step 1." ends instead `then
     rerun from step 1 as a base-move round: steps 1 to 3, 6a only on a
     \`shared:\` line, 6b only for a new \`left whole\` plan, then 6c to 7.`
   - 6a: `**A round whose \`code\` and \`requirement\` findings` becomes
     `**A round whose \`code\` and \`requirement\` findings, if any,` with
     the next line, `are all \`low\` is the last review round.**`, unchanged.
   - The file must stay at or under 2,000 words (`wc -w`). Cut the same
     number of words elsewhere in the skill without changing a rule: move a
     reason or an example into `references/rationale.md`, or tighten wording.
     Run the whole `tests/skills.bats` after each cut; many tests pin skill
     phrases, so a cut that breaks one is the wrong cut.
3. In `skills/merge-change/references/rationale.md`, add
   `## Step 1: a staged squash stops the round` (D1's reason and cost),
   `## Step 4: skipped when no reviewer is dispatched` (D2: the pre-flight
   before review exists to catch a broken trace before a reviewer spends a
   round on it; with no reviewer, 6c is the same checks) and one paragraph
   under the existing step 7 trailers section for D3 (the record is
   committed after the gate, so the last rerun must follow it, found or not).
   The rationale names no script: no `scripts/` path and no word ending in
   `.sh` (its own test enforces this).
4. Run `tests/run-tests.sh tests/skills.bats`; green. Commit unsigned
   (`git -c commit.gpgsign=false commit`).

**T1 done** (aed6a61, merged a3f2422). skills.bats 152/152.

red -> green: `skills.bats: merge-change: the base merge stops while a squash is staged in the primary checkout` — red: status 0, the fence merged the moved base with the primary index staged.
red -> green: `skills.bats: merge-change: a round that dispatches no reviewer skips the pre-flight before the review` — red: "step 4 does not say when it is skipped".
red -> green: `skills.bats: merge-change: a round with no finding is the last` — red: "the last-round sentence does not cover a round with no finding".

Word cuts to stay at 1,999 (for review to check that no rule changed): the
add/add reason moved to the rationale; the four reviewer questions became one
sentence; the inline finding-format example dropped (the checklist holds it);
6b's four-field list became the field names; 6a's fix-dispatch sentence
shortened; the `--force`/`-D` duplicate left Done when. The step 7
staged-squash test now pins "then rerun from step 1 as a base-move round:".

### T2 — The gate moves after the record, in merge-change

**Files touched:** skills/merge-change/SKILL.md,
skills/merge-change/references/rationale.md,
skills/merge-change/references/review-checklist.md,
skills/merge-change/references/multi-unit.md,
skills/merge-change/references/cleanup-rejections.md, tests/skills.bats
**Parallel:** yes, with T3 (disjoint files); after T1 is merged

Load `skills/develop-tdd/SKILL.md`. Apply D4 and D5.

1. RED, in `tests/skills.bats`: a test `merge-change: the gate runs after the
   record, on the tree that is signed` (verifies D4) that reads the step
   headings in order (lines matching `^[0-9]+[a-d]?\. \*\*`) and asserts the
   sequence 1, 2, 3, 4, 5, 6a, 6b, 6c, 6d, 7, 8; that 6a's text dispatches the
   verification suite and 6b's compares `HEAD^{tree}`; that step 5 (the record)
   precedes 6a; and that step 7's message template names `<step 6a tree>`.
   Update every existing test that extracts a step by number or quotes a step
   label (11 sites; `grep -n -E 'step [0-9]|6[a-d]' tests/skills.bats`) to the
   new numbers, keeping what each asserts. Watch the new test fail first.
2. GREEN, in `skills/merge-change/SKILL.md`: reorder and renumber the steps per
   D5, and rewrite each cross-reference inside the file. Specifically:
   - Step 2 (pre-flight) carries T1's skip sentence, now naming step 2's own
     skip; step 6c's "Read it as at step 4" becomes "as at step 2".
   - Step 4 (review): the documentation-only sentence becomes `A
     documentation-only diff's reviewer skips the suite; the record states it,
     and 6a's gate covers it.` A gate failure at 6a after a review: its fix
     reruns from step 1 and dispatches a reviewer, unless it touches only the
     record or the plan.
   - The last-round rule: after the fixes, rerun from step 1 with no reviewer
     (steps 2–4 skipped); "Write the record (6b) before that rerun" and "the
     rerun ends at 6b" go, since the record now precedes the gate.
   - Step 7: `Gate-tree: <step 6a tree>`, the write-tree comparison against
     the step 6a tree, and T1's base-move round restated in the new numbers:
     steps 1, 5 only for a new `left whole` plan, 4 (with 2–3) only on a
     `shared:` line, then 6a to 7.
   - Stay at or under 2,000 words; the reorder should free words (the record-
     before-rerun clause goes).
3. In the merge-change references, update step numbers to D5's, and in
   `rationale.md` add `## Step 6a: the gate runs after the record` (D4's
   reasons and costs) and retitle every `## Step N` heading to its new number.
   Rationale headings and text that only explain history keep their content.
4. Run `tests/run-tests.sh tests/skills.bats`; green. Commit unsigned.

**T2 done** (79f5572, merged 0700723). skills.bats 153/153.

red -> green: `skills.bats: merge-change: the gate runs after the record, on the tree that is signed` — red: "step labels: 1 2 3 4 5 6 6a 6b 6c 6d 7 8".

Existing test names keep their old step numbers (records cite them); only
their assertions follow D5. Left for after T3: skills.bats assertions on T3's
files (lines ~279, 284, 1227, 1452, 3009, 3019, 3023) still pin old numbers;
step 4's "The reviewer still reads the record" contradicts D4's order;
review-checklist.md's last-round sentence lacks D3's "if any". Word cuts: the
`worktree-discipline` step 1 cross-reference in the header; "Four fields the
template describes" → "Four fields"; the 6a gate-failure sentence shortened.

### T3 — Every other reference follows the new numbers

**Files touched:** AGENTS.md, README.md, templates/verification.md,
templates/AGENTS-block.md, scripts/check-review.sh, scripts/merge-preflight.sh,
scripts/prune-plans.sh, scripts/finish-merge.sh, scripts/check-trace.sh,
skills/verify-before-merge/SKILL.md,
skills/verify-before-merge/references/rationale.md,
skills/worktree-discipline/SKILL.md,
skills/worktree-discipline/references/rationale.md,
skills/develop-change/SKILL.md, skills/develop-change/references/rationale.md,
skills/plan-change/SKILL.md, skills/ratchet/references/setup-checklist.md,
skills/ratchet/references/upgrade-notes.md, tests/finish-merge.bats,
tests/prune-plans.bats, tests/check-trace.bats, tests/check-review.bats,
tests/merge-preflight.bats, tests/portability.bats
**Parallel:** yes, with T2; after T1 is merged

Load `skills/develop-tdd/SKILL.md`. Apply D5's mapping to every
`merge-change` step reference in these files, history excepted (D5). Find them
with `git grep -n -E 'step [0-9]|\b6[a-d]\b'`; a reference to another skill's
step (`develop-change step 6`, `worktree-discipline step 1`) is not a
merge-change step and stays. Where a sentence describes the old order (the
gate before the review, the record after the gate), rewrite it to D4's order.

1. Before editing a script line, grep `docs/verification/*.mutations/` for
   that line's text. A mutation that quotes it must still apply afterwards:
   prefer editing only comment and message text no mutation quotes; where one
   does, report it in the dispatch report rather than editing the mutation.
2. RED: no new behavior in scripts, so no new script test; `tests/` edits only
   follow the new numbers in names and messages the tests assert.
3. Add an entry at the top of `skills/ratchet/references/upgrade-notes.md`
   stating the renumbering map and that the gate now runs after the record;
   leave older entries as written.
4. Run `tests/run-tests.sh` on each edited `.bats` file, then
   `tests/run-tests.sh tests/mutations.bats`; green. Commit unsigned.

**T3 done** (17c3a87, merged 811e2b3). No new test (comments, messages and
labels only). Mutation anchors: no mutation quotes an edited script line;
mutations.bats 7/7. verify-before-merge now describes running inside
merge-change at 6a; the README flow, develop-change and plan-change hand-offs
follow.

### T4 — Reconcile T2 and T3

**Files touched:** tests/skills.bats, skills/merge-change/SKILL.md,
skills/merge-change/references/review-checklist.md,
skills/merge-change/references/rationale.md
**Parallel:** no

Load `skills/develop-tdd/SKILL.md`. No new behavior; each item makes the merged
tree agree with D3–D5.

1. `tests/skills.bats` assertions that quote T3's files on old numbers follow
   the new text: `the end of \`merge-change\` step 4` (worktree-discipline),
   `not at its step 4` (develop-change, two tests), `` `Gate-tree:` names the
   tree the step 6a gate measured `` (templates/verification.md), and
   `` `merge-change` step 5 copies them `` (develop-change); check the
   neighbouring absence check for `step 6d` in worktree-discipline still means
   what it meant. Test names keep their wording.
2. Step 4's "The reviewer still reads the record and raises what is wrong"
   contradicts D4 (the record follows the review). Reword it so it holds: a
   reviewer dispatched in a later round reads the record the earlier round
   wrote. Update the test that pins it to the new sentence.
3. `review-checklist.md`'s last-round sentence takes D3's "if any".
4. merge-change's description ("Use when a change has passed
   verify-before-merge") and its precondition "`verify-before-merge` passed in
   the change worktree" follow T3's verify-before-merge: the gate now runs at
   6a, so the precondition is that `develop-change` is done and its suite is
   green. Keep the description under its current length and the skill at or
   under 2,000 words.
5. Run the whole suite, `tests/run-tests.sh` (about 11 minutes); report the
   pass and fail counts. Commit unsigned.

**T4 done** (b2816aa). Whole suite 1456/1456; skills.bats 155/155.

red -> green: `skills.bats: merge-change: the review checklist's last round covers a round with no finding` — red: "the checklist's last-round sentence does not cover a round with no finding".
red -> green: `skills.bats: merge-change: it starts after develop-change, since the gate runs inside it` — red: "still requires verify-before-merge first".

Step 4 now reads "A later round's reviewer reads the record earlier rounds
wrote, and raises what is wrong"; the 6c pre-flight is the only check on the
last round's record (rationale). merge-change's precondition is "`develop-change`
is done, its suite green".

## Conformance reviews

### Round 1 — ARCHITECTURE (docs/ARCHITECTURE_GUIDELINES.md)

**finding-1**: guideline, medium — Domain 2 (a term means one thing): D5
reuses labels with new meanings (6a, 6b, 2, 4); ADR-y8jmes line 9 and
ADR-bh4xgr lines 34, 40, 43 and older upgrade-notes entries use the old ones,
and AGENTS.md now points at ADR-y8jmes's "step 4".
Disposition: fix (F2). D5 stands: renumbering reuses some label unless labels
stop being numbers. Every live file uses the new labels: the ADRs and the
older upgrade-notes entries are translated. Dated history (`docs/plans/`,
`docs/verification/`, `docs/problems/`) keeps its numbers. Test names already
on `main` keep theirs: ten dated records cite them by name, and check-review
reads cited test names.

**finding-2**: guideline, low — Boundaries 1: verify-before-merge's
description adds a second "and". Disposition: fix (F2).

### Round 1 — TEST (docs/TEST_GUIDELINES.md)

**finding-1**: guideline, medium — Seams 1: "the record is written before the
last rerun…" verifies only gate-proof-in-trailers D6, which it now
contradicts. Disposition: fix (F1), annotate base-move-round D4.
**finding-2**: guideline, medium — Seams 1: "no step renames a ledger file,
and step 3 confirms…" lacks base-move-round D5. Disposition: fix (F1).
**finding-3**: guideline, low — "check-review: the record need not be
committed" has no `verifies:`. Disposition: fix (F1).

### Round 1 — CODE (docs/CODE_GUIDELINES.md)

**finding-1** to **finding-4**: guideline, medium — Comments 2: "Re-aimed
2026-10-14 under D…" comments at tests/skills.bats:1515, 1706, 2427, 2732
narrate the change. Disposition: fix (F1).
**finding-5**: guideline, medium — Names 4: the new test "…skips step 4"
verifies step 2. Disposition: fix (F1), renamed "…skips step 2".
**finding-6**: guideline, low — Errors 2/3: step 1's `primary=` ignores a
failed `git worktree list`; an empty path reads the change worktree's index.
Disposition: fix (F1).
**finding-7**: guideline, low — Names 2: `&& … ||` chain at
tests/skills.bats:2791. Disposition: fix (F1).
Notes from all three: stale step numbers in comments and failure messages of
tests/skills.bats. Disposition: fix (F1); test names already on `main` keep
theirs (see ARCHITECTURE finding-1).

### Round 1 fixes

F2 (32fb419): ADR-y8jmes, ADR-bh4xgr, ADR-cy7ahd, ADR-f6ytg7 and the older
upgrade-notes entries use D5's labels; verify-before-merge's description
states one job. skills.bats 155/155.
F1 (1fdeb7b): every TEST and CODE finding fixed as dispositioned; the T1 test
renamed "…skips step 2" (its red -> green line above follows). Step 1 also
stops on an empty primary path (a failed listing).

red -> green: `skills.bats: merge-change: the base merge stops while a squash is staged in the primary checkout` (the no-primary-checkout case) — red: status 0, "Merge made by the 'ort' strategy" with `git worktree list` failing.

skills.bats 155/155, check-review.bats 136/136, portability.bats 22/22.
merge-change/SKILL.md is at 2,000 words.

### Round 2 — TEST

**finding-1**: guideline, low — Mutants 1: "a round that dispatches no
reviewer skips step 2" checks only the phrase "as a base-move round", not the
steps D2 lists for it. Disposition: fix (F3).
Verdict: nothing above low; TEST is done.

### Round 2 — ARCHITECTURE

**finding-1**: guideline, low — Boundaries 1: merge-change's description
states its job with "and … then". Disposition: fix (F3).
**finding-2**: guideline, low — Boundaries 1: verify-before-merge's
description. Disposition: no change; its job sentence has no "and", and the
"and" is in the "Use before …" trigger sentence, which the clause does not
govern.
Notes taken: check-traceability:12 and resolve-problem:96–97, 147 still put
verify-before-merge before merge-change (fix, F4); ADR-cy7ahd rejects
renumbering the sequence, which this change does, and three ADRs switch
labels with no note (fix, F4); rationale.md:221 "the round that does reach
step 5 dispatches no reviewer" is false under D4 (fix, F3); plan D2 and D5
wording (fixed above).
Verdict: nothing above low; ARCHITECTURE is done.

### Round 2 — CODE

**finding-1**: guideline, medium — Names 4: develop-change/SKILL.md:81–82
"`merge-change` step 6b copies them". Disposition: fix (F4).
**finding-2**: guideline, medium — Names 4: test names at
tests/skills.bats:1509, 1562, 1614, 2348, 3077 keep old step numbers.
Disposition: fix (F3). This reverses round 1's call to keep them: no script,
mutation or helper reads a test name (`grep` of `scripts/`, `tests/*.sh` and
every `*.mutations/` directory), only the prose of dated records, which keeps
the old name as history. Each is renamed by the step's role, not its number,
and "the record is written before the last rerun…" is renamed too, since its
body asserts the opposite.
**finding-3**: guideline, low — Simplicity 4: the 6b-to-6c awk range is
added twice, and lettered steps have no helper. Disposition: fix (F3);
`step_of` takes lettered labels.
**finding-4**: guideline, low — Names 2: the stub's `&& exit 128`.
Disposition: fix (F3).
**finding-5**: guideline, low — Comments 1: comments at 1706, 2744, 1516
restate the code. Disposition: fix (F3).
**finding-6**: guideline, low — Errors 1: the step-1 message calls any staged
content "a squash". Disposition: fix (F3); the message says the primary
checkout's index is not empty. A git error (exit 128) prints git's own
message above it, so it is not reworded separately.

### Round 2 fixes

F4 (0af5478): develop-change names step 5; check-traceability and
resolve-problem place verify-before-merge at merge-change step 6a; the four
ADRs carry the D5 amendment note, ADR-cy7ahd's saying why its rejected
renumbering now happens. skills.bats 155/155.
F3 (e728f69..3913327): every F3 item fixed as dispositioned. Renamed tests
(old -> new), so the red -> green lines above use the new names:
"…skips step 2" -> "…skips the pre-flight before the review";
"…and step 3 confirms the tree the summary describes" -> "…and the tree check
confirms the tree the gate summary describes"; "…step 3 stands on step 2…" ->
"…the tree check lets the gate summary stand where the tree is unchanged";
"…step 2 records the tree…" -> "…the gate step records the tree its summary
describes"; "…step 7 writes the gate's trailers…with the step 2 tree…" ->
"…the squash step writes the gate's trailers…with the gated tree…";
"…written before the last rerun…" -> "…written before the gate…";
"…and step 6b copies them" -> "…and merge-change's record copies them".
`step_of` takes lettered labels. merge-change/SKILL.md 1,987 words.

red -> green: `skills.bats: merge-change: a round that dispatches no reviewer skips the pre-flight before the review` (the base-move step list) — red on a mutated skill ("then 6b to 7."): "step 7 does not list the base-move round's steps".
red -> green: `skills.bats: merge-change: the base merge stops while a squash is staged in the primary checkout` (the index message) — red: "not the index message: a squash is staged in …".

skills.bats 155/155, portability.bats 22/22, finish-merge.bats 52/52.

### Round 3 — CODE

**finding-1**: guideline, medium — Names 3: `a_at`/`b_at` (tests/skills.bats
223–224, 252–253, 299–300, 379–380) are named for old 6a/6b and hold the
review and record lines; at 1521 `a_at` holds the gate's. Disposition: fix
(F5), named by role.
**finding-2**: guideline, medium — Comments 2: dated history comments at
tests/skills.bats:241, 701, 1351, 1691, 2018 were relabelled with step numbers
that did not exist when they happened. Disposition: fix (F5), each states the
current rule or drops the narration. Not a recurrence of round 1's notes: those
asked for current labels; the fault is that these comments narrate history at
all.
**finding-3**: guideline, low — Simplicity 4: the staged-squash test copies
the step-1 range and the `sh_fence` extractor; 2128 keeps an inline step-4
range. Disposition: fix (F5).
**finding-4**: guideline, low — Names 3: `text` at 2767. Disposition: fix (F5),
with `pre` at 2781 (note) and the test name "…at its own 6a" (note: D5 names a
step by role in a test name).

### Round 3 fixes

F5 (4ba12df): every finding fixed as dispositioned; `sh_fence` moved to
tests/helpers.bash; three more history-narrating comments rewritten. Test
renamed "…since the gate runs at its own 6a" -> "…since the gate runs inside
it" (its red -> green line above follows). skills.bats 155/155,
portability.bats 22/22, finish-merge.bats 52/52.

### Round 4 — CODE

Verdict: 5 findings, all low; CODE is done. Every conformance review has now
converged. The lows are fixed as last-round fixes (F6), with no further round:
**finding-1** (Errors 1/2: step 1 reports a git error as a non-empty index —
fix: tell exit 1 from any other status, with a test); **finding-2**
(Simplicity 2: `sh_fence` back in tests/skills.bats beside its fence helpers);
**finding-3** (Simplicity 4: the step-label loop at 1520–1524 and the 6b
heading pin duplicate the labels test — fix: keep them in the labels test
only); **finding-4** (Names 3: `two_at`/`three_at` named by role); **finding-5**
(Comments 2: drop the review-round provenance tags at tests/skills.bats:3061
and tests/prune-plans.bats:640–641). Note taken: the inline step-1 extractors
at 1530 and 2595 use `step_of`.

### Last-round fixes (F6)

1efd421: every round-4 low fixed as dispositioned. Step 1 tells a non-empty
index (exit 1) from an unreadable one (any other status). Word cut: "You
decide the fix, and dispatch it" → "Dispatch your fix" in the sequence header
(for the independent review to check that no rule was lost). skills.bats
155/155, prune-plans.bats 59/59, portability.bats 22/22.

red -> green: `skills.bats: merge-change: the base merge stops while a squash is staged in the primary checkout` (unreadable-index case) — red: "the index of …/repo is not empty" in place of the cannot-read message.

## Independent review (merge-change 6a), round 1

Reviewed commit f37a0f2. The reviewer ran `tests/run-tests.sh`: 1456/1456.

**finding-1**: requirement, medium — The base-move round runs step 5 "only for a new `left whole` plan", even when a `shared:` line sent the change to a fresh review at step 4 (skills/merge-change/SKILL.md:219-222; rationale.md:142-145); a shared:-triggered review that finds nothing leaves no trace in the record, against templates/verification.md:77-78.
Disposition: fix (fix-review-r1): a round whose step 4 ran reaches step 5 before the gate; pinned in the D2 test.
**finding-2**: code, low — scripts/check-ids.sh:28-29 says the pre-flight is step 4; it is step 2.
Disposition: fix (fix-review-r1).
**finding-3**: requirement, low — SKILL.md:130-133 (the last round reruns from step 1) and rationale.md:221-222 (a nothing-found round reaches step 5) disagree on the path.
Disposition: fix (fix-review-r1): the rationale states the skill's path.
**finding-4**: requirement, low — review-checklist.md:41-42, 53-55 ask every reviewer to check the record, which a first-round reviewer cannot see under D4.
Disposition: fix (fix-review-r1): "where the record exists", as line 80 says.
**finding-5**: requirement, low — the test "merge-change: the base merge stops while a squash is staged in the primary checkout" names a step number, against D5's test-name rule.
Disposition: fix (fix-review-r1): renamed by role.
**finding-6**: record — upgrade-notes' new entry does not announce D1's new stop.
Disposition: fix (fix-review-r1).

Evidence for check 4 (gate, round 1): two re-aimed tests had no red -> green
line. Each was run on 2026-10-15 against a scratch copy of this change with
`main`'s (344faa3) skills/merge-change/SKILL.md in place, and failed for the
behavior it verifies. This is red observed after the implementation, against
the base, not watched before it:

red -> green: `skills.bats: merge-change: no step renames a ledger file, and the tree check confirms the tree the gate summary describes` — red against main's skill: step 6b is the record there, "the step 6a summary stands" absent.
red -> green: `skills.bats: merge-change: the record is written before the gate and holds no gate figure` — red against main's skill: "the skill still orders the record before the last rerun".

### Review round 1 fixes

4164ba1: every finding fixed as dispositioned. The D1 test is renamed "the
base merge stops while a squash is staged in the primary checkout" (the
red -> green lines above follow). Word cuts (SKILL.md at 2,000): "its own
AGENTS.md" → "its AGENTS.md"; step 4 drops "; read `references/rationale.md`
before proposing it" (References already sends the reader there before
proposing a change); References drops "for your case". scripts/check-ids.sh's
edited comment is quoted by no mutation. skills.bats 157/157, check-ids.bats
45/45, portability.bats 22/22, mutations.bats 7/7.

red -> green: `skills.bats: merge-change: a round that dispatches no reviewer skips the pre-flight before the review` (the corrected base-move list) — red: "step 7 does not list the base-move round's steps".
red -> green: `skills.bats: merge-change: the review checklist asks for the record only where it exists` — red: "the checklist asks every reviewer for inherited: lines in the record".
red -> green: `skills.bats: ratchet: the upgrade notes say the base merge stops on a staged squash` — red: "the renumbering entry does not announce step 1's new stop".

## Independent review (merge-change 6a), round 2

Reviewed commit 1e2c817 (gate: 1458/1458 on tree f055a10). The reviewer ran
`tests/run-tests.sh`: 1458/1458. Verdict: D1–D5 satisfied; every finding low
or record, so this is the last review round. Every round-1 disposition holds.

**finding-1**: code, low — Two D4 rules have no test: "A 6a gate failure's fix dispatches a reviewer unless it touches only the record or plan" (skills/merge-change/SKILL.md:137-138) and "A documentation-only diff's reviewer skips the suite; the record states it, and 6a's gate covers it" (SKILL.md:115-116).
Disposition: fix (fix-review-r2): pin both in a D4 test.
**finding-2**: requirement, low — ADR-f6ytg7:69-71 still states the consequence D4 removed (a record written after the last gate costs one more gate run).
Disposition: fix (fix-review-r2).
**finding-3**: requirement, low — ADR-cy7ahd:47-49 and :93-95 describe the old order (steps keep their places; the tree check after steps 2 and 3).
Disposition: fix (fix-review-r2).
**finding-4**: requirement, low — skills/check-traceability/SKILL.md:13 "the `verify-before-merge` gate at its step 6a" reads as verify-before-merge's step.
Disposition: fix (fix-review-r2): the form resolve-problem uses.
**finding-5**: record — The plan's word-cut lists omit cuts in the diff: step 7's example path, "exactly one command, paths and branch substituted", step 8's `/compact` example, References' "and hand it over", and the removed step 6 heading. None changes a rule.
Disposition: fixed in the plan: those five cuts are listed here, and the reviewer found none changes a rule.
**finding-6**: record — D1's text states one stop; the tree has three, each tested under D1, and the upgrade note omits the missing-primary stop.
Disposition: D1 amended above; the upgrade note fixed (fix-review-r2).

### Review round 2 fixes

778080f: every fix-review-r2 finding fixed as dispositioned. skills.bats
158/158.

red -> green: `skills.bats: merge-change: a late gate's costs are stated: a reviewer for its fix, and no suite for a docs-only review` — red with either sentence removed from a working copy of the skill.
red -> green: `skills.bats: ratchet: the upgrade notes say the base merge stops on a staged squash` (the missing-primary stop) — red: "the renumbering entry does not announce the missing-primary stop".

## Independent review (merge-change 6a), round 3

The base moved to 52100a8 (ratchet-pinned-qualification) after round 2; step
1 printed `shared:` for `skills/ratchet/references/upgrade-notes.md` and
`tests/skills.bats`, so the whole change was reviewed again at 9acf9ae (gate:
1489/1489 on tree de118c8). The reviewer ran the suite: 1489/1489. Verdict:
approve; the shared files merged intact, no base-side merge-change step
citation; `record` findings only, so this is the last review round.

**finding-1**: record — the record called round 2 the last, had no round 3 block, and did not say the trace/ID comparison was repeated at the moved base.
Disposition: fixed in `docs/verification/2026-10-15-base-move-round.md`.
**finding-2**: record — D2 still gave the uncorrected base-move list.
Disposition: fixed in D2 above.
