# CLANKER Adoption Implementation Plan

**Goal:** Install the adopted CLANKER.md rules — the plain-language and naming
rules in the always-on block, the deslop pass at `develop-change`'s exit, check 8
in `verify-before-merge`, the architectural-root-cause escalation in
`resolve-problem` — and sweep the banned vocabulary out of the 11 skill bodies.

**Implements:** no minted REQ/RC/SDD IDs — guardrails does not self-host its own
gates (`2026-08-22-ratchet-gap-analysis.md`). The binding contract is the eight
decisions in `2026-09-14-clanker-adoption.md`; each task's tests contain
`verifies: D<n> (docs/plans/2026-09-14-clanker-adoption.md)`.

**Safety class:** n/a — guardrails is a development tool.

**Verification:** `sh tests/run-tests.sh`, all bats tests passing. Baseline
measured in this worktree at `51f01b7` on 2026-09-14, before T1:
**634 ok, 0 not ok**, TAP plan `1..634` matching the count.

## Task rules specific to this change

**Every task runs its own bats file plus `tests/portability.bats`, never the
whole suite.** `sh tests/run-tests.sh` takes 25+ minutes and a dispatched
subagent silent that long is killed by the no-progress watchdog with its work
uncommitted (`2026-09-10-field-report-fixes.md` learned this the hard way).
`run-tests.sh` also cannot run a single file — it appends the argument to its
glob — so a task runs one file with the runner directly:

```sh
tests/.bats-core/bin/bats tests/skills.bats
```

The full suite runs once, in the change worktree, after every task branch has
merged.

**A task commits as soon as it has anything working.** Uncommitted work in a
task worktree is unprotected.

**No task touches `scripts/`.** All 184 mutation scripts under
`docs/verification/*.mutations/` target `scripts/*.sh` and none reference
`skills/`, so this change cannot invalidate mutation evidence. Keep it that way:
if a task finds itself editing a script, stop and report.

## Dispatch order and the file-set argument

| | `templates/AGENTS-block.md` | `AGENTS.md` | `develop-change` | `verify-before-merge` | `resolve-problem` | `ratchet` | all 11 skills | `tests/skills.bats` |
|---|---|---|---|---|---|---|---|---|
| T1 | write | write | | | | | | write |
| T2 | | | write | | | | | write |
| T3 | | | | write | | | | write |
| T4 | | | | | write | write | | write |
| T5 | | | | | | | sweep | write |

**Every task touches `tests/skills.bats`, so every task is serial.** That file is
where skill-prose assertions live and there is no honest way to split it for this
change. The file-set rule is the gate, not a judgment about how independent the
tasks look.

T5 runs last and sweeps the prose T2–T4 added as well as the pre-existing prose.
T2–T4 write their new prose already conforming, so T5's work on them should be
nil; if it is not, that is a finding worth reporting.

---

### T1 — The always-on rules

**Files touched:** `templates/AGENTS-block.md`, `AGENTS.md`, `tests/skills.bats`
**Parallel:** no (first)
**Implements:** D1, D3, D5

**Step 1 — the failing tests.** Append to `tests/skills.bats`:

```bash
@test "clanker: the managed block bans the vocabulary by listing it" {
    # verifies: D3 (docs/plans/2026-09-14-clanker-adoption.md)
    # An abstract instruction to write plainly does not change model output —
    # the current skill prose was written under instructions of that shape.
    # The explicit list is the part that works, so the list itself is what
    # this test pins.
    block="$BATS_TEST_DIRNAME/../templates/AGENTS-block.md"
    grep -q 'Write dry, technical prose' "$block"
    grep -q 'load-bearing' "$block"
    grep -q 'no metaphor' "$block"
    grep -q 'Do not match existing style' "$block"
}

@test "clanker: the managed block names concrete naming rules" {
    # verifies: D5 (docs/plans/2026-09-14-clanker-adoption.md)
    # Naming is where the rule reaches code rather than prose. Without the
    # worked pair the instruction is abstract again.
    block="$BATS_TEST_DIRNAME/../templates/AGENTS-block.md"
    grep -q 'write_timestamp' "$block"
    grep -q 'single-character' "$block"
}

@test "clanker: this repository holds itself to the same block" {
    # verifies: D1 (docs/plans/2026-09-14-clanker-adoption.md)
    # AGENTS.md is guardrails' own copy of the rules it ships. A rule that
    # ships to adopters and does not bind this repository is a rule this
    # repository will break first.
    agents="$BATS_TEST_DIRNAME/../AGENTS.md"
    grep -q 'Write dry, technical prose' "$agents"
    grep -q 'Do not match existing style' "$agents"
}
```

Run and watch all three fail:

```sh
tests/.bats-core/bin/bats tests/skills.bats     # expect 3 not ok
```

**Step 2 — write the block.** Insert into `templates/AGENTS-block.md`, directly
before the `## Check scripts (run from repo root)` heading:

```markdown
## Writing: prose, names and messages

Write dry, technical prose. Say what something is. This applies to everything
written: messages to the user, documentation, strings in code, identifiers,
and commit messages.

- No metaphor, no anthropomorphism, no wordplay, no balanced contrast. A file
  exists in a directory; it does not sit there. A gate rejects a commit; it
  does not refuse one.
- Active voice. Cut filler. Do not editorialize.
- Replace these words: carries -> contains, lands -> is merged, survives ->
  remains, says -> states, holds -> contains, refuses -> rejects,
  load-bearing -> critical, ran -> was run.
- Do not match existing style when it disagrees with these rules.

In code, additionally:

- No single-character names. No code golf.
- Name in concrete terms, and do not use the past participle: write
  `write_timestamp`, not `written_at`.
```

**Step 3 — mirror it into `AGENTS.md`.** The same section, inserted before the
`## Rules` heading. Guardrails is the reference implementation of its own
process, so the block it ships and the rules it follows do not diverge.

**Step 4 — green.**

```sh
tests/.bats-core/bin/bats tests/skills.bats       # expect 3 new ok, 0 not ok
tests/.bats-core/bin/bats tests/portability.bats  # unchanged
```

**Commit:** `feat: the managed block states the writing rules`

**Done 2026-09-14.** Merged as `0a81a19`. Result: 56 passed, 0 failed
(`skills.bats` 46/46, `portability.bats` 10/10).

red -> green, watched fail for the right reason before the implementation
existed:

- `clanker: the managed block bans the vocabulary by listing it`
- `clanker: the managed block names concrete naming rules`
- `clanker: this repository follows the same block`

Two deviations from this task as planned, both recorded rather than silent:

1. The plan's test greps `'no metaphor'` but its block text opens the bullet
   with `No metaphor`, so a verbatim insertion left the test red. Fixed on the
   test side with `grep -qi`, which keeps the shipped block exactly as planned
   and pins the same phrase.
2. The task named its third test `this repository holds itself to the same
   block`. `holds` is on the replace list this very task installs. The
   dispatcher renamed it to `follows` after the merge. Worth noting as evidence
   for D2: an agent writing new prose beside old prose reproduces the old
   register even while installing the rule against it, which is why the sweep
   is not forward-only.

---

### T2 — The deslop pass at `develop-change`'s exit

**Files touched:** `skills/develop-change/SKILL.md`, `tests/skills.bats`
**Parallel:** no (serial, after T1)
**Implements:** D4, D7, D8

**Step 1 — the failing tests.** Append to `tests/skills.bats`:

```bash
@test "clanker: develop-change dispatches one deslop pass over the whole diff" {
    # verifies: D4 (docs/plans/2026-09-14-clanker-adoption.md)
    # The dispatcher never reads the code and each subagent sees one task, so
    # cross-task duplication is invisible to both. This pass is the only agent
    # that sees the whole change, which is why it is a dispatch over the diff
    # and not a per-task review.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -q 'deslop pass' "$skill"
    grep -q 'main..<change-branch>' "$skill"
    grep -q 'cross-task' "$skill"
}

@test "clanker: the deslop pass is not deferred to the merge review" {
    # verifies: D4 (docs/plans/2026-09-14-clanker-adoption.md)
    # merge-change reruns from step 1 on any finding, so a naming nit raised
    # at 6a costs a full merge-sequence restart. The skill has to say why the
    # pass is here, or a later editor moves it to the review that already
    # reads the whole diff.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -q 'reruns from step 1' "$skill"
}

@test "clanker: develop-change tells a stuck task to change approach" {
    # verifies: D7 (docs/plans/2026-09-14-clanker-adoption.md)
    # The derailment rule re-dispatches on the first failure. Without this,
    # the re-dispatch repeats the approach that already failed.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -q 'change the approach' "$skill"
}
```

Run and watch all three fail.

**Step 2 — write the exit step.** In `skills/develop-change/SKILL.md`, replace
the `## Done when` section:

```markdown
## The deslop pass

When the last task branch has merged and the suite is green, dispatch **one**
subagent over the whole change diff before handing off:

```
Review main..<change-branch> under the writing and naming rules in AGENTS.md.
Report and fix, on <change-branch>: slop, unclear names, duplication between
tasks, and anything that can be simpler. Do not change behavior — the suite
must stay green. Return the report shape below.
```

It returns:

```
files changed: <paths>
fixed: <one line per fix>
left alone: <anything it judged not worth changing, with the reason>
suite: <N passed, N failed>
```

This is the only agent that sees the whole change. The dispatcher holds the
plan and the trace and never reads the code; each task subagent sees one task.
So **cross-task** duplication — two tasks adding the same helper, one concept
named differently in each — is invisible to every other party, and this pass is
the only place it can be caught.

It runs here rather than at `merge-change` 6a for three reasons. The merge
sequence **reruns from step 1** on any finding, so a variable name raised there
costs a full restart. By 6a every task branch is merged and the change is
squash-bound, so the cheap moment is gone. And 6a is an independence review —
mixing craft into it makes correctness and style one verdict, and the second
waters down the first.

## Done when

Plan tasks complete, suite green, the deslop pass run and its findings fixed —
then `check-traceability` and `verify-before-merge`.  Never claim done without
them.
```

**Step 3 — the derailment pivot.** In the "Derailment" section, after the two
bullets naming the twice-stuck thresholds, add:

```markdown
Below that threshold, keep looping and re-dispatch — but **change the approach**
rather than repeating it. A re-dispatch that restates the same task the same way
produces the same failure, and spends a second agent to learn nothing.
```

**Step 4 — green.**

```sh
tests/.bats-core/bin/bats tests/skills.bats       # expect 3 new ok, 0 not ok
```

**Commit:** `feat: develop-change ends with one deslop pass over the diff`

**Done 2026-09-14.** Merged as `a73b1a2`. Result: 59 passed, 0 failed
(`skills.bats` 49/49, `portability.bats` 10/10).

red -> green, watched fail for the right reason before the implementation
existed:

- `clanker: develop-change dispatches one deslop pass over the whole diff`
- `clanker: the deslop pass is not deferred to the merge review`
- `clanker: develop-change tells a stuck task to change approach`

Three deviations, the first two in text this plan supplied:

1. The derailment paragraph this plan gives opens with a sentence the existing
   paragraph already contained three lines above. The task cut the clause from
   the existing paragraph and placed the new one after it, so the meaning is
   kept and the duplication is not. No other existing prose changed.
2. The replacement text this plan gives for `## Done when` contained the
   vocabulary the change installs: `holds the plan and the trace`, and metaphor
   in `the cheap moment is gone` and `waters down the first`. The task inserted
   it verbatim as instructed and reported it. The dispatcher rewrote those three
   spots after the merge.
3. The dispatch prompt gained a location and a prohibition this plan does not
   specify — `Work in the change worktree at <path>, on <change-branch>. Do NOT
   create a task worktree — this pass fixes on the change branch directly`, and
   the paragraph that states why. It arrived in `ffb88c6`, after this task
   merged, and no decision stated it until the independent review reported it
   as unmarked scope. It is now D8, with a test that pins both halves.

Deviation 2 is the second instance of the effect T1 recorded, and it is the
stronger one: the offending prose was written by the dispatcher, in the plan,
while specifying the rule. `holds the plan and the trace` also already existed
in the skill body being edited. An agent writing beside existing prose
reproduces its register whatever the instruction states, which is what D2 rests
on.

---

### T3 — `verify-before-merge` check 8

**Files touched:** `skills/verify-before-merge/SKILL.md`, `tests/skills.bats`
**Parallel:** no (serial, after T2)
**Implements:** D6

**Step 1 — the failing test.** Append to `tests/skills.bats`:

```bash
@test "clanker: the gate checks the deslop pass ran" {
    # verifies: D6 (docs/plans/2026-09-14-clanker-adoption.md)
    # In a suite where every other step is mechanically checked, an
    # unenforced step is the one that stops running. This is the cheap
    # enforcement: a gate that already exists, asking one more question.
    skill="$BATS_TEST_DIRNAME/../skills/verify-before-merge/SKILL.md"
    grep -q 'deslop pass ran' "$skill"
    grep -q 'findings were fixed' "$skill"
}
```

**Step 2 — write check 8.** In `skills/verify-before-merge/SKILL.md`, after
check 7 (`git status` — no uncommitted work, no stray files) and before the
`check-review.sh is deliberately NOT in this list` paragraph:

```markdown
8. **The deslop pass ran** and its findings were fixed (`develop-change`). The
   subagent cannot answer this from the tree — a deslopped diff and a diff
   nobody reviewed look identical. The dispatcher answers it from the pass's
   report, the way check 4 is answered from the dispatch reports.
```

**Step 3 — green.**

```sh
tests/.bats-core/bin/bats tests/skills.bats       # expect 1 new ok, 0 not ok
```

**Commit:** `feat: the gate checks that the deslop pass was run`

**Done 2026-09-14.** Merged as `62aea62`. Result: 60 passed, 0 failed
(`skills.bats` 50/50, `portability.bats` 10/10).

red -> green, watched fail for the right reason before the implementation
existed:

- `clanker: the gate checks that the deslop pass was run`

The task renamed its test and its commit from the plan's `the deslop pass ran`,
because `ran` is on the replace list this change installs. The plan was wrong
and the task was right to deviate; it reported the deviation rather than making
it silently.

**The structural finding.** Adding check 8 made two passages in
`skills/verify-before-merge/SKILL.md` under-count the gate: the gate-summary
shape, which promises an answer for every check the subagent owns and lists
checks 1-7, and the sentence `Two checks have a half the subagent cannot
answer`. Check 8 is not split at all — it is wholly the dispatcher's. The
dispatcher added a paragraph after that sentence stating that, and stating why
check 8 produces no gate-summary line.

This is the finding a per-file review would not have produced. The task was
told to add a numbered item; noticing that the addition falsified two
paragraphs elsewhere in the same file required reading the file as a whole.

**Prose repaired by the dispatcher after the merge.** The plan's own check-8
text used `ran` and the passive `its findings were fixed`, and both were pinned
by `grep -q` strings, so prose and test moved together:

| was | is |
|---|---|
| `**The deslop pass ran**` | `**The deslop pass was run**` |
| `and its findings were fixed` | `and the dispatcher fixed its findings` |
| `a deslopped diff and a diff nobody reviewed look identical` | `the tree records no difference between a diff the pass reviewed and a diff nobody reviewed` |

Third instance of the D2 effect, and the plan is now its most frequent source.

---

### T4 — The architectural root cause, and the ratchet note

**Files touched:** `skills/resolve-problem/SKILL.md`, `skills/ratchet/SKILL.md`,
`tests/skills.bats`
**Parallel:** no (serial, after T3)
**Implements:** D1 (placement), and the root-cause rule

**Step 1 — the failing tests.** Append to `tests/skills.bats`:

```bash
@test "clanker: a bug caused by the design escalates to design-architecture" {
    # verifies: D1 (docs/plans/2026-09-14-clanker-adoption.md)
    # The escalation list already covers a missing requirement, a missed
    # hazard and a wrong spec. A bug that is a consequence of the
    # architecture had nowhere to go, so it was fixed where it surfaced and
    # the class of bug stayed open.
    skill="$BATS_TEST_DIRNAME/../skills/resolve-problem/SKILL.md"
    grep -q 'consequence of the design' "$skill"
    grep -q 'design-architecture' "$skill"
}

@test "clanker: ratchet reports a managed block with no writing rules" {
    # verifies: D1 (docs/plans/2026-09-14-clanker-adoption.md)
    # A project ratcheted before this change has a block without the writing
    # section. Nothing else would ever tell it.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'writing rules' "$skill"
}
```

**Step 2 — the fourth escalation.** In `skills/resolve-problem/SKILL.md`, add to
the escalation list in section 2:

```markdown
- **The bug is a consequence of the design, not of this line** → the fix that
  closes only this occurrence leaves the class open. Ask whether a change to
  the structure would prevent the class, and if so run `design-architecture`
  before fixing. When the answer is unclear, put it to the user.
```

**Step 3 — the ratchet note.** In `skills/ratchet/SKILL.md` step 3's gap
analysis, add a detection line: a managed block with no `## Writing: prose,
names and messages` section is a gap, and the remedy is to re-run the block
install. This cannot go red on an existing ledger — it adds a section and
changes no gate.

**Step 4 — green.**

```sh
tests/.bats-core/bin/bats tests/skills.bats       # expect 2 new ok, 0 not ok
```

**Commit:** `feat: a bug caused by the design escalates to the architecture`

**Done 2026-09-14.** Merged as `961fbc5`. Result: 62 passed, 0 failed
(`skills.bats` 52/52, `portability.bats` 10/10).

red -> green, watched fail for the right reason before the implementation
existed:

- `clanker: a bug caused by the design escalates to design-architecture`
- `clanker: ratchet reports a managed block with no writing rules`

**First task needing no prose repair.** The plan's escalation text contained no
word from the replace list and was already active voice, so it shipped verbatim.

**Three staleness findings, all fixed by the dispatcher after the merge:**

1. `skills/ratchet/SKILL.md`, the paragraph beginning `Updating the scripts
   updates the grammar's prose carriers too.` Its premise was that the managed
   block teaches the grammar the scripts enforce. After T1 the block also
   contains writing rules, which no script enforces. The paragraph now states
   that a stale block costs two different things.
2. `skills/ratchet/SKILL.md`, the upgrade announcement list. This change adds a
   section to the shipped block and had no upgrade note, so an upgrading
   project would receive the rules only by chance. Added
   `**The managed block now states writing rules, and no gate enforces them.**`,
   which also states that nothing goes red and that existing prose is not swept.
3. `skills/design-architecture/SKILL.md` frontmatter. Its description read `Use
   after requirements exist and before planning implementation of structural
   changes`, which excludes the entry point T4 created — arriving from a problem
   report, mid-investigation. The description is what routes a model to a skill,
   so the escalation would have named a skill whose own trigger text argued
   against entering it. Extended with `or when a problem report's root cause
   turns out to be the design itself`.

**Two observations left unfixed, deliberately, as out of scope:**

- `README.md`'s workflow diagram draws `resolve-problem --> develop-change` and
  none of the escalation edges. It already under-drew two (`grill-requirements`,
  `analyze-risks`); this change makes it three. The defect predates this change
  and fixing the diagram is not CLANKER adoption.
- `skills/resolve-problem/SKILL.md`'s red-flags table has no row for `fix it
  where it surfaced, the class can wait`. None of the other three escalations
  has a row either, so this is a suggestion about the table's coverage, not a
  defect this change introduced.

---

### T5 — The vocabulary sweep

**Files touched:** all 11 `skills/*/SKILL.md`, `tests/skills.bats`
**Parallel:** no (serial, last)
**Implements:** D2

**Measured at `51f01b7`:** 2,337 lines across the 11 skill bodies, **127**
instances of the banned vocabulary in them, **4** pinned `grep -q` strings in
`tests/skills.bats` that contain a word from the shipped replace list, and **6**
`@test` names that contain one.

This plan first stated about 200 instances, 8 pinned strings and 15 test names.
The 200 is corrected under **The count** below. The 8 came from a
word list wider than the rule — it added `named`, `given` and `sits`, none of
which `AGENTS.md` bans — and exactly four of the eight strings tabulated below
match only on `names` or `named`. That is the same defect the D2-fix record
diagnoses as the origin of T5's `named` -> `stated` substitutions. The 15
reproduces under no list this change uses: the wider list gives 5 test names at
`51f01b7` and the shipped list gives 6. Round 2's finding 5 recounted both.

**Step 1 — the pinned strings move in lockstep.** These 8 assertions quote skill
prose that this task rewrites, so each is edited in the same commit as the line
it quotes. Editing one without the other turns a passing test into a false green
or a spurious red:

| `tests/skills.bats` | quoted phrase |
|---|---|
| line 73 | `reports success and then refuses` |
| line 223 | `refuses on untracked files as well as modified ones` |
| line 323 | `guard 4 refuses at step 8` |
| line 340 | `step 1 names them` |
| line 431 | `the one the dispatcher named` |
| line 489 | `names that path in the dispatch prompt` |
| line 606 | `the record also names the units touched` |
| line 626 | `exported REQ carrying \`satisfies:\`` |

Line numbers are as of `51f01b7` and will have moved once T1–T4 appended their
tests; find each by its phrase, not by its line.

**Step 2 — sweep, one skill at a time, committing after each.** For each of the
11 `skills/*/SKILL.md`, apply the substitutions from the managed block, then
read the file and fix what a substitution cannot: metaphor, anthropomorphism,
passive voice, and sentences that narrate.

**Do not change what a sentence claims.** This prose records decisions that were
expensive to reach — the containment argument in `worktree-discipline`, the
signing diagnosis in `AGENTS.md`. Rewrite the register, keep the content. A
sentence you cannot rewrite without losing a claim is a sentence to leave alone
and report.

**Step 3 — test names.** Rewrite the 6 `@test` names that contain a banned
word, and the 3 more whose wording is metaphor or anthropomorphism. They keep
sentence form — a test description documents behavior and a
sentence is the right shape for that (D5) — and lose the anthropomorphism:
`the review worktree dies at the end of its own dispatch` becomes
`the review worktree is removed at the end of its own dispatch`.

**Step 3b — the comments in `tests/skills.bats`.** The file is already open for
steps 1 and 3, and it contains the banned vocabulary in its comments too,
including line 2 — the sentence that introduces the whole file and currently
reads `a skill instruction that quietly loses its load-bearing phrase`. Sweep
the comments with the test names. The `# verifies:` annotations are IDs and are
never reworded.

**Step 4 — green.**

```sh
tests/.bats-core/bin/bats tests/skills.bats       # expect 0 not ok
tests/.bats-core/bin/bats tests/portability.bats  # expect 0 not ok
```

**Step 5 — verify the sweep.** Re-run the count that measured it:

```sh
for w in carry carries carrying land lands landed holds held holding \
         survives survive sits sit says named given ran load-bearing \
         refuses refuse; do
    n=$(grep -riow "$w" skills/*/SKILL.md | wc -l | tr -d ' ')
    [ "$n" -gt 0 ] && printf '%-14s %s\n' "$w" "$n"
done
```

Expect no output. A word that legitimately remains — a quoted git error message
such as `refusing to update checked out branch` — is reported in the dispatch
report's `surprises:` line rather than forced.

**Commit:** `refactor: the skills lose the banned vocabulary`

**Done 2026-09-14.** Merged as `f875970`, 12 commits, one per file. Result:
62 passed, 0 failed (`skills.bats` 52/52, `portability.bats` 10/10).

This task adds no test and changes no behavior. What proves it broke nothing:
`skills.bats` was run after each of the 12 commits and stayed at 52 ok, 0 not
ok, and every pinned string moved in the same commit as the prose it quotes.

**The count.** Measured over the 11 skill bodies with the `banned=` word list
the D2 scan test uses: **127** word-bounded occurrences at `51f01b7`, the commit
this change was cut from, and **20** still in the tree at `f875970`, this task's
merge. The bare replace list from `AGENTS.md`, without the three inflections the
scan adds, gives 125 and 20.

```sh
git grep -Eiohw "$banned" 51f01b7 -- 'skills/*/SKILL.md' | wc -l    # 127
git grep -Eiohw "$banned" f875970 -- 'skills/*/SKILL.md' | wc -l    # 20
```

This record first stated "About 200 instances before, **2** after". Both
figures were wrong. The 200 was an estimate under a word list wider than the
rule. The 2 counted the quoted git error `fatal: a branch named
'<change-branch>-fix' already exists` at `skills/merge-change/SKILL.md:74` and
`:244`, which contains no word from the shipped replace list at all — `named`
is not on it, as the D2-fix record states — so the residue was never those two.
The step 5 loop matched base forms only and reported a clean tree over the 20
that remained. The first deslop pass found them; **Check 8, answered by the
dispatcher**, at the end of this document, states the breakdown and what else
that pass found.

**Four of the plan's eight pinned strings moved; four needed no move.**
`step 1 names them` and `names that path in the dispatch prompt` quote
`AGENTS.md`, which this task's file set excludes; `the record also names the
units touched` and `the one the dispatcher named` use `names` and `named`,
neither of which is on the replace list. The plan over-counted by four. The
count is `git diff main...3a08bd1 -- tests/skills.bats`, which shows four of the
eight as removed lines and `the one the dispatcher named` as unchanged context.
This record stated five and three until the independent review recounted it.

**Left alone deliberately, each with a reason:**

- `prose carriers` in `ratchet` — pinned by a test outside the tabulated 8;
  moving it would add a ninth pinned string this task was not authorised to
  move.
- `the iron law` in `develop-change`, and the reference to it in
  `verify-before-merge` — `tests/check-signing.bats:116` also names it, and that
  file is outside this task's scope, so a rename would leave the two out of
  sync.
- `A ratchet only turns one way` and the tooth vocabulary — the skill's domain
  terms, one of them pinned as `a tooth ordering, not a package`.
- Four `# verifies:` annotation blocks whose prose tails still contain
  `sit`, `carrying`, `convicts` and `say`. Step 3b states annotations are never
  reworded.

**No sentence was abandoned for loss of claim.** The three passages this plan
flagged as expensive all rewrote cleanly, including `worktree-discipline`'s
containment argument, whose quoted git messages (`refusing to update checked
out branch`, `refusing to fetch into branch`) were kept verbatim.

**Fourth instance of the D2 effect, and the decisive one.** The sweep was not
nil on prose T2-T4 added, which this plan predicted it would be. Two spots
written during this change still contained the vocabulary: `one concept named
differently in each` in T2's deslop-pass section, which the dispatcher had
already rewritten once, and `The managed block also carries the writing rules`,
which the dispatcher wrote as T4's finding 1 — after the rules were installed
and while citing them.

## Gap in this plan's scope, closed after T5

`AGENTS.md` is not one of the 11 skill bodies, so D2's sweep excluded it. It is
also the file that now states `Do not match existing style when it disagrees
with these rules`. Measured after the T5 merge, outside the rule text it now
contains: **six** violations — `says why`, `a value carrying a`, `carries its
own sign`, `a case sits inside a`, `the refusal survives`, and `named` in the
plans-directory line. None was pinned by a test.

The dispatcher swept all six and rewrapped the three lines the longer wording
pushed past the file's width. `AGENTS.md:22` is 83 characters and was already
so before this change; it is left alone.

The scoping error is worth recording: D2 was written as "all 11 skill bodies"
when the intent was "every file this suite tells an agent to obey". A future
sweep should name files, not a count.

---

---

### D2-fix — the sweep gets the test that keeps it swept

**Files touched:** `tests/skills.bats`,
`docs/plans/2026-09-14-clanker-implementation.md`
**Parallel:** no (after the gate's first run)
**Implements:** D2

Not planned. Dispatched 2026-09-15 to close the first gate run's only finding:
T5 claimed D2 and added no test, so the sweep was a one-time edit and D2's
second sentence — the rule also binds new writing — was enforced by nothing.

**Done 2026-09-15.** Merged as `070c9d2`. Result: 63 passed, 0 failed
(`skills.bats` 53/53, `portability.bats` 10/10), counted rather than tailed.

red -> green, watched fail for the right reason before the implementation
existed:

- `clanker: no skill body contains the replaced vocabulary` — the task changed
  `contains no colon` to `carries no colon` at
  `skills/check-traceability/SKILL.md:42`, watched the test report that exact
  file, line and text, and reverted. The dispatcher then re-proved it
  independently in a different file, planting `holds` at
  `skills/ratchet/SKILL.md:10` and watching the failure name it, because a test
  that guards this change's central claim is worth failing twice on purpose.

**The word forms were narrowed against real uses, not exempted.** `hold` is out
and `holds`/`held`/`holding` are in, because `when all three hold` is correct;
`say` is out and `says`/`said` are in, because the imperative `say so` appears
six times; `run` is out and `ran` is in. The two quoted git messages are removed
by their full wording, so a second use of `refusing` on the same line is still
reported.

**The task declined one instruction, correctly.** The dispatcher told it to
exempt `fatal: a branch named '<change-branch>-fix' already exists`. That
message contains no word from the shipped replace list — `named` is not on it —
so the exemption would have matched nothing. It reported that an exemption
matching nothing is dead text, and that if `names`/`named` is to be banned,
`AGENTS.md` must say so first. This is also the origin of T5's over-application
of `named` -> `stated`: the dispatcher's step 5 verification loop scanned for
`named`, which the shipped rule never banned.

## After the tasks

1. The deslop pass over `main...clanker-adoption` (`develop-change`), which for
   this change is partly self-referential: it is the first run of the rule this
   change installs.
2. `check-traceability`, then `verify-before-merge` (full suite, dispatched),
   then `merge-change`.
3. **Before the merge gate, re-merge `main`.** If `field-report-items` reached
   its signed squash while this change was in flight, `main` has moved and the
   six shared files have conflicts. Re-run T5's step 5 count afterwards: a sweep
   measured against a tree that has since moved is not a sweep.

## Round 1 of the independent review

Six findings, every one of them in this change's own records or its own tests
rather than in shipped behavior. The fixes are `4598e90`, `841155e`, `bb1020b`,
`a2ec1c9`, `5e21e70` and `0c0b60b`, merged into the change branch as `6b01d6b`;
`d68bb95` recorded the rename consequence afterwards.

| # | Finding | Disposition |
|---|---|---|
| 1 | D5 binds test descriptions and comments, and T5's sweep stopped short of them: one `@test` name and six comments in `tests/skills.bats` still used the replace list | Fixed, `841155e`. That rename is the ninth in the table below |
| 2 | `clanker: ratchet reports a managed block with no writing rules` passed with the behavior it names deleted, because its assertion `writing rules` also matches the upgrade announcement in the same file | Fixed, `4598e90`. The test now asserts the inventory bullet's own two strings, each unique in the file |
| 3 | Unmarked scope: the deslop dispatch's task-worktree prohibition arrived in `ffb88c6` with no decision behind it | Fixed, `bb1020b`. It is now D8, and a test pins the prompt line, the reason, and the heading |
| 4 | This change's own prose broke the rule it installs: D6 stated `the deslop pass ran` while check 8 in the skill states `was run`, so the decision used a banned word and disagreed with the text it governs | Fixed, `5e21e70` |
| 5 | Four holes in the D2 scan | One fixed, `0c0b60b`: the scan suppressed grep's no-match status, which made an empty glob indistinguishable from a clean tree, so a move of the skill paths would have left the test green over no file. It now counts the files it read and requires at least 11. The other three are recorded rather than fixed, in the decision record's known-gap section, and belong to the change that closes the scope gap |
| 6 | Recorded figures did not describe the tree: the gate row stated an assertion count from a run that predates the base merge, the cost section's line counts were measured at a commit the branch had left, and T5's pinned-string split was stated as five and three where the diff shows four and four | Fixed, `a2ec1c9`. Each figure now names the commit it was measured at |

Finding 3 added the change's eleventh test. Its attestation, in the same form
as the task records above:

red -> green, watched fail for the right reason before the implementation
existed:

- `clanker: the deslop dispatch prohibits a task worktree` — the task deleted
  both halves of the prohibition from `skills/develop-change/SKILL.md` and
  watched the run report `not ok` with
  `grep -qF 'Work in the change worktree at <path>, on <change-branch>. Do NOT
  create a task' failed`. It restored both halves and the test passed.

## Nine renamed tests leave seventeen citations in archived records

D5 reaches bats test descriptions, so this change renamed nine tests. Six of
the old names used a word from the replace list; three used metaphor or
anthropomorphism, which D5 removes from a description while keeping its
sentence form. T5's step 3 renamed eight of the nine. Round 1's finding 1
renamed the ninth, which T5 had missed.

| old name | new name |
|---|---|
| `merge-change: step 8 maps guard 4's refusal to a remedy` | `... guard 4's rejection to a remedy` |
| `merge-change: the review worktree dies at the end of its own dispatch` | `... is removed at the end of its own dispatch` |
| `merge-record-names-units: the verification record carries the impact set` | `... contains the impact set` |
| `problem grammar prose: no shipped file still carries owner:` | `... still contains owner:` |
| `ratchet-units-interview-writes-facts-not-rules: the D9 line is drawn in the skill` | `... is stated in the skill` |
| `ratchet: tool qualification says how and where the suite runs` | `... states how and where the suite runs` |
| `ratchet: tool qualification warns that a pipe eats the suite's exit status` | `... discards the suite's exit status` |
| `upgrade-notes-announce-the-hard-cut: ratchet says derived assessments go red at upgrade` | `... states derived assessments go red at upgrade` |
| `worktree-discipline: the task worktree passage says how to get inside` | `... states how to get inside` |

Seventeen citations of those old names remain in nine already-merged documents:

| document | citations |
|---|---|
| `docs/plans/2026-09-01-task-worktree-containment.md` | 6 |
| `docs/verification/2026-09-01-task-worktree-containment.md` | 3 |
| `docs/plans/2026-09-04-units-skills.md` | 2 |
| `docs/plans/2026-08-30-drop-problem-owner.md` | 1 |
| `docs/plans/2026-09-08-assesses-and-dangling-file.md` | 1 |
| `docs/verification/2026-08-30-ratchet-tool-qualification.md` | 1 |
| `docs/verification/2026-08-31-drop-owner-tag.md` | 1 |
| `docs/verification/2026-09-01-monorepo-requirements.md` | 1 |
| `docs/verification/2026-09-02-retrofit-findings.md` | 1 |

Both figures are reproducible. With `d8502d1` — the base merge of `main` — as
the base and the change branch head as the head:

```sh
git grep -h '^@test' d8502d1 -- 'tests/*.bats' | sed 's/^@test "//; s/" {$//' | sort > /tmp/base.txt
git grep -h '^@test' HEAD     -- 'tests/*.bats' | sed 's/^@test "//; s/" {$//' | sort > /tmp/head.txt
comm -23 /tmp/base.txt /tmp/head.txt                      # the nine old names
comm -23 /tmp/base.txt /tmp/head.txt | while IFS= read -r name; do
    grep -rn --include='*.md' -F "$name" docs             # the seventeen citations
done
```

All seventeen are left as they are. Each records the name the test had at the
merge it describes, which is what a record is for, and editing a merged plan or
verification record to match a later tree would falsify the evidence it
contains. The cost is that a reader following any of the seventeen finds no such
test in the tree today.

This is a general consequence of D5, not a one-off: any test rename breaks
by-name citations in already-merged records, and no gate reports it.
`check-trace.sh` resolves IDs, not test names, so a test-name citation is
ordinary prose to every script in this suite.

This record stated two renames and two citation sites until round 2's finding 1
recounted them.

## The verification gate

Dispatched twice. The first run, 2026-09-15 at `29e7311`, reported the suite at
644 assertions and **one finding**: D2 claimed with no `verifies:` test. The
D2-fix above closed it. The second run, from the top at `070c9d2`, because a
partial pass does not count:

| Check | Result |
|---|---|
| 1 — `sh tests/run-tests.sh` | **687 ok, 0 not ok, 0 skipped**, TAP plan `1..687` matching the count, measured at `3a08bd1`. The pre-merge run at `070c9d2` reported **644 ok, 0 not ok, 0 skipped**, plan `1..644` |
| 2 — `check-trace.sh` | Inapplicable. Run: exits 2, `file not found: .guardrails/config.yaml` |
| 3 — `check-ids.sh --allow-draft-files` | Inapplicable. Run: exits 2, same cause |
| 4 — Implements map, subagent half | Each of D1-D8 has a `verifies:` test. None unclaimed, none unverified |
| 5 — coverage | Inapplicable. No config, so no `coverage_command` |
| 6 — robustness | Inapplicable. Safety class n/a |
| 7 — `git status` | Clean, before and after the run |

Both gate runs predate the base merge, so row 1 states the figure at
`3a08bd1` — the change branch head with `main` merged in — and keeps the
pre-merge figure beside it. The two differ by 43 assertions: 42 the base
merge brought in (`check-trace.bats` +32, `finish-merge.bats` +10) and one this
change added to `skills.bats` after the gate run. `git grep -c '^@test'
<commit> -- 'tests/*.bats'` reproduces both totals. The review round that
follows this record adds tests of its own, so the gate is run again before the
merge and the figure moves once more.

Checks 2, 3, 5 and 6 are reported as **inapplicable with the evidence that
makes them so**, never as passes. A gate that cannot run is not a gate that
agreed.

**Check 4's other half, answered by the dispatcher.** Every one of the eleven
tests in the gate's map has a `red -> green:` attestation recorded in this
document, from the dispatch report of the task that wrote it: three from T1,
three from T2, one from T3, two from T4, one from D2-fix, and one from round 1's
finding 3. T5 added no test and claimed none until D2-fix. No test in this
change was green from the start.

**Check 8, answered by the dispatcher.** The deslop pass was run **twice**, and
the findings of both were acted on.

The first run, merged as `91ebbd7`, covered the change as it stood before the
base merge. Its findings were fixed there, in `ffb88c6`, and in `29e7311` —
that last one a range-specification error its own fix introduced, caught by the
full suite rather than by the pass.

The second run, merged as `21d4b3c`, was necessary because four merges reached
the change branch after the first: the D2 scan test, the gate record, the base
merge of `main` at `d8502d1` with two conflict resolutions, and the sweep of
the vocabulary that merge brought in. Answering check 8 from the first run alone
would have been true in wording and false in substance — the pass would never
have seen half the diff it is supposed to have reviewed.

The second run earned itself, which settles the question of whether a re-run
after a base merge is ceremony:

- It found two words from the replace list in `AGENTS.md`, the file that states
  the rules, where the D2 scan does not reach (see the known gap in the
  decision record).
- It found a **contradiction between the two sweeps**: `merge-change` 6a still
  paraphrased `worktree-discipline`'s bullet in the framing the earlier sweep
  had removed from that bullet. Two passes over overlapping files at different
  times is exactly how a citation and its source drift apart, and no per-file
  review sees it.
- It found three paragraphs the sweeps had rewrapped into a two- or three-word
  orphan line, and two places where a mechanical substitution had produced
  prose that was clean by the list and wrong in sense — `No test contains
  verifies:` for an annotation, and a sentence that called a reader a defect.

The pass earned its place on its first run. It found that the sweep's own
verification loop matched base forms only, so 18 words of the `refuse` family,
1 `carried` and 1 `said` remained in the tree at the moment the dispatcher
reported the sweep complete — 20 rather than the 2 reported, and the 2 were
themselves miscounted (see **The count** in T5). This record stated 2 `carried`
and "about 23" until round 2's finding 6 recounted the residue at `f875970`.
The pass also found `carrying` twice in `templates/AGENTS-block.md`, the file
that ships the rules to adopters, which the dispatcher's own sweep of
`AGENTS.md` had missed. Neither would have been caught by any per-task review.
