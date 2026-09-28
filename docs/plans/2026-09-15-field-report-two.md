# The Second Class B Field Report — Implementation Plan

**Goal:** Resolve five of the problems recorded in
`docs/problems/2026-09-15-field-report-two.md` — a per-change record
required to state whole-ledger totals, a merge sequence that re-measures a tree
it already measured, a filename that states a merge date nobody knew, a rewrite
pass silent about what it cannot reach, and a review round with no scope boundary
and no stopping rule — leaving `PR-9xxz3b` open for its own change.

**T1 was built, reviewed twice and withdrawn on 2026-09-16.** Its section is kept
below as written, because the two review rounds against it are `PR-8ucezf`'s
evidence and a plan that quietly loses a task hides why. Read it with the
"Why T1 was withdrawn" section that follows it.

**Implements:** no minted REQ/RC/SDD IDs — guardrails does not self-host its own
gates (`2026-08-22-ratchet-gap-analysis.md`). The binding contract is five
problem items: `PR-9zvb36` and `PR-xec7dd` (T2), `PR-hkc376`, `PR-dkm5tq`,
`PR-3s74u3` and `PR-xec7dd`'s documentation half (T3). `PR-8ucezf` (T1) is
**open**, not delivered. Each task's
tests contain `verifies:` naming its item, and each item's `status:` goes to
`resolved` only when its task is green.

**Safety class:** n/a — guardrails is a development tool; the projects it gates
are class A–C. The bats suite is the evidence.

**Verification:** the baseline was the full suite green at `d8502d1`. The base
then moved four times mid-change — to `3714f08` when `clanker-adoption` merged
first, to `8d78cd4` when `close-scan-scope` did, then to `650f090` and to
`47a8b1d` — and every gate figure in the record is derived against the last of
those, not against any earlier commit.

**A task runs its own bats files and `tests/portability.bats`, never the whole
suite.** `sh tests/run-tests.sh` takes 25+ minutes and a dispatched subagent that
is silent that long is terminated by a no-progress watchdog with its work still
uncommitted (`2026-09-10-field-report-fixes.md` records the task it killed). The
full suite runs **once**, in the change worktree, after every task branch has
merged. `portability.bats` is per-task and mandatory for T1 and T2, which touch
`scripts/`: it enforces the leading-`(` case-pattern rule and the
no-literal-newline-to-`awk -v` rule under a stub awk.

**A task commits as soon as it has anything working.** Uncommitted work in a task
worktree is unprotected, and the watchdog does not ask first.

## The register every new sentence is written in

`clanker-adoption` was open on this repository when this plan was written, and
added `tests/skills.bats: "clanker: no skill body contains the replaced
vocabulary"`, a scan over `skills/*/SKILL.md`. Its word list:

    contain|contains|contained|containing  merge|is merged|was delivered|merging
    contains|contained|containing  remain|remains|remained|remaining
    states|stated|stating  reject|rejects|rejected|rejecting|rejection
    was run  critical

That change merged first, as `3714f08`, so this repository's suite **does** now
enforce it and it reads this change's prose — which passes, because every
sentence added under `skills/` was written without those forms from the first
draft rather than swept afterwards.

**And `close-scan-scope` then widened it again**, as `8d78cd4`: the scan now
reads `skills AGENTS.md README.md templates install.sh scripts tests
docs/problems docs/risk docs/adr`, which is every file the rules bind. This
change's ledger and tests had never been scanned and five violations surfaced at
once — including a test name this change had introduced, which had to be renamed
and chased through three documents. `docs/plans/` and `docs/verification/` are
permanently out of scope there, because they are merged evidence and editing a
record to match a later tree falsifies what it proved. **The
rule binds more than the scan does.** AGENTS.md applies it to "everything
written: messages to the user, documentation, strings in code, identifiers, and
commit messages", and before `8d78cd4` the scan read `skills/*/SKILL.md`
alone. Since `8d78cd4` it reads script comments and the ledger too, so the only
files bound by the rule and reported by nothing are the plan and the record —
which that change put permanently out of scope, because they are merged evidence.
Check those two by hand; the rest the suite now checks.
Whichever change merges second, the other's prose is then in the register the
scan expects, and no third sweep is needed. This costs nothing at writing time
and is not optional.

## Why `PR-9xxz3b` is not in this change

It asks `check-trace.sh` to separate change-scoped gates from ledger-scoped
limits. The mechanism — a `--scope=change|ledger` filter — is sound; the
reporter's preferred delivery is not, in two ways, and both belong to a change
that can argue them on their own evidence.

`tests/check-trace.bats` asserts exit status 1 in 143 places, and so does every
adopter's CI line, so a new exit code for ledger-scoped violations is a breaking
change to the one contract every downstream project reads. And moving
`PROBLEM-BACKLOG` and `STALE-PROBLEM` out of `merge-change` removes the only
thing in this toolkit that forces triage: there is no scheduler here, and a
ledger review that happens on demand happens when someone remembers it. What
this change does instead is state the disposition path at the point the gate
reddens — including `status: accepted`, which reached `main` in `d8502d1`, after
the reporter's baseline, and is the answer their report does not know about.

## T1 — `FOREIGN-DRAFT` — WITHDRAWN, kept for its evidence

**Files touched:** `scripts/check-ids.sh`, `tests/check-ids.bats`
**Parallel:** yes — disjoint from T2 and T3
**Item:** `PR-8ucezf`

### The defect

`check-ids.sh`'s `DRAFT-FILE` scan reads the whole tree
(`git ls-files --cached --others --exclude-standard -- .`). A draft ledger file
leaked by any merged change therefore fails step 4 for every subsequent change,
and the verdict names no other change, so the session that meets it has no way to
tell its own defect from a repair it inherited.

### The discriminator

`finalize-docs.sh` already computes it:

```sh
branch=$(git branch --show-current 2>/dev/null | tr -c 'A-Za-z0-9\n' '-')
```

A draft file whose basename opens with `DRAFT-<branch>-` belongs to the branch
under merge; any other draft file belongs to another change. On a detached HEAD
`branch` is empty, the question cannot be answered, and every draft file is
reported as `DRAFT-FILE` — which is today's behavior and today's exit status.

### Steps

1. Write the tests below in `tests/check-ids.bats` and watch each one fail
   against the unedited script. Record the observed failure text for the record's
   red → green table. **Three of the six cannot redden that way** — the ones
   asserting that the new verdict does *not* fire (this branch's own draft, a
   detached HEAD, the suppression flag) pass against a script that never prints
   `FOREIGN-DRAFT`, and passing proves nothing about them. Redden those against a
   deliberately over-broad variant of the classifier instead, applied and
   reverted before the real code, and record in the table that this is what was
   done.
2. In `scripts/check-ids.sh`, inside the `if [ "$allow_draft_files" -eq 0 ]`
   block, classify each hit before printing it. Keep one `git ls-files`
   invocation; classify its output. The exit status is unchanged: either verdict
   sets `fail=1`.
3. A `FOREIGN-DRAFT` line names the commit that introduced the file, from
   `git log -1 --format='%h %s' -- "$f"`. An untracked file has no such commit
   and is named `untracked`. A `case` pattern in the classification opens with
   `(`, per AGENTS.md.
4. The message shape, one line per file:

   ```
   FOREIGN-DRAFT docs/problems/DRAFT-other-change-slug.md (another change's draft, introduced by 4deb0248 fix: the settings nav)
   FOREIGN-DRAFT docs/problems/DRAFT-other-change-slug.md (another change's draft, untracked)
   ```

5. Extend the script's header comment block with `FOREIGN-DRAFT`, stating that
   the exit status is the same and that the repair belongs to a change of its
   own.
6. Run `tests/.bats-core/bin/bats tests/check-ids.bats tests/portability.bats`.

### Tests

Each contains `# verifies: PR-8ucezf`.

* `check-ids: a draft ledger file from another branch is FOREIGN-DRAFT` — a
  fixture repository on branch `mine` with `docs/problems/DRAFT-theirs-slug.md`
  committed; the run exits 1 and the line opens `FOREIGN-DRAFT`.
* `check-ids: a FOREIGN-DRAFT line names the commit that introduced the file` —
  the same fixture; the line contains the short hash of that commit.
* `check-ids: an untracked foreign draft is named as untracked` — the same
  fixture with the file never committed; the line contains `untracked` and no
  hash.
* `check-ids: the merging branch's own draft is still DRAFT-FILE` — on branch
  `mine` with `docs/problems/DRAFT-mine-slug.md`; the line opens `DRAFT-FILE` and
  the output contains no `FOREIGN-DRAFT`.
* `check-ids: a detached HEAD reports every draft as DRAFT-FILE` — the question
  cannot be answered, so the answer is the conservative one.
* `check-ids: --allow-draft-files suppresses FOREIGN-DRAFT too` — exit 0, no
  output from either verdict.

## Why T1 was withdrawn

Two independent review rounds, and the second one settled it.

**Round 1 — unreachable.** `merge-change` step 3 runs `finalize-docs.sh` before
step 4 runs `check-ids.sh`, and that script's planning loop renames every
`DRAFT-*.md` in the ledger directories whoever wrote it. A foreign draft in a
ledger directory is therefore adopted and gone before the new verdict could
convict it. Recorded as `PR-umtm9b`.

**Round 2 — wrong in its own right.** The discriminator convicts a draft *this*
change created when its name does not embed the branch. Reproduced: on branch
`mine`, `docs/problems/DRAFT-loose-notes.md` reports as another change's draft;
rename the branch to `loose` and the same file passes. Step 4 then told the
author to park their own change and repair someone else's leak.

**The contradiction is what decided it.** This plan's own `PR-umtm9b` rejects
exactly this discriminator for `finalize-docs.sh`, because it convicts drafts
whose names contain no branch — a shape the convention permits and this
repository's own fixtures use. The change was shipping in one script the rule it
argued against in the other. Both could not stand, and defending the weaker half
during a fix round is how a change talks itself into a bad rule.

**What was reverted:** `scripts/check-ids.sh` and `tests/check-ids.bats` to the
base — to `3714f08` when the revert was made, and to the current base now,
since later changes rewrote both files and this change took their versions
whole; three tests in `tests/skills.bats`; the
`check-traceability` verdict row; the `FOREIGN-DRAFT` paragraphs in
`merge-change` steps 3 and 4. What replaced the last of those is prose: step 4
states that `DRAFT-FILE` does not say whose draft it is, and that the obvious
mechanical test is unsafe.

**A second lesson, about dispatch rather than about drafts.** T1's fix was
halted after round 1, and the parallel documentation task was not told. It
continued writing step 3 and the `check-traceability` row as though the
`finalize-docs.sh` half had shipped, and a new test pinned those sentences — so
the suite defended a claim about behavior that did not exist. Round 2 found it.
When a task is cancelled, every task that documents it is part of the
cancellation.

## T2 — the finalize date, and a report of what the rewrite could not reach

**Files touched:** `scripts/finalize-docs.sh`, `scripts/lib.sh`,
`tests/finalize-docs.bats`
**Parallel:** yes — disjoint from T1 and T3
**Items:** `PR-9zvb36`, `PR-xec7dd` (the script half)

### 2a. The date is the finalize date (`PR-xec7dd`)

`today=$(date +%Y-%m-%d)` runs when the script runs, which is `merge-change`
step 3, and the script is a silent no-op on an already-dated tree. A change whose
findings round crosses midnight therefore takes the date of its first finalize
attempt and nothing re-dates it. Downstream: 49 of 193 dated ledger files, the
largest gap 6 days.

No behavior changes. The claim does. Edit the header of
`scripts/finalize-docs.sh`:

* the rename line becomes
  `docs/<area>/DRAFT-<branch>-<slug>.md -> docs/<area>/<finalize-date>-<slug>.md`;
* the sentence "the merge date cannot be known until the merge" becomes a
  statement of what the date is: the date the draft name was retired, which is
  within a few days of the merge and is not re-derived afterwards. The filename
  is a handle; the merge date is in git.

The same edit to the comment at `scripts/lib.sh:586`, which states the same
claim about the same rename.

### 2b. The references the rewrite pass cannot reach (`PR-9zvb36`)

The rewrite scope is the ledger directories and the SOUP file, deliberately —
`docs/plans/` and `docs/verification/` narrate the rename, and rewriting a true
sentence about history makes it false. That reasoning is sound and this task does
not widen the scope. The consequence it leaves is that `check-trace.sh`'s
`DANGLING-FILE` reads **the same scope**, so a `DRAFT-` link in a plan is
reported by nothing at all. Downstream: a review round spent on four dead links
in one plan.

After the rewrite pass, scan the whole tree for each old basename, subtract the
files the pass rewrote, and print one line per remaining hit:

```
unrewritten docs/plans/2026-09-04-fetch-names-flake.md:12: DRAFT-fetch-names-flake-shared-tmp-paths.md
  (outside the rewrite scope — a narration to leave, or a link to repair by hand)
```

Informational. The exit status does not move, and the script does not judge
narration against link — that judgment is the author's and takes five seconds.
Under `--dry-run` the line opens `would leave unrewritten`.

### Steps

1. Write the tests below and watch each fail against the unedited script. **One
   of them cannot** — "a reference inside the rewrite scope is not reported as
   unrewritten" passes against the unedited script and also passes with the
   subtraction it exists to prove deleted, because a rewritten reference is gone
   from the tree either way. Give it the ambiguous bare form, the one shape where
   a scoped file still contains the old basename after the pass, and redden it by
   removing the subtraction. This plan specified a test that could not fail; the
   task that executed it found that out.
2. Add a `report_unrewritten` function beside `rewrite_refs`. It takes the old
   basename, runs `git grep -n --untracked -F -- "$_ob"` over the whole tree,
   and drops any hit whose file is in `$rewrite_scope`. Pathname expansion is off
   at that point in the script; keep it off, and split on newlines alone, as the
   surrounding code does.
3. Call it once per distinct old basename, after `run_rewrites`, in both the
   `--dry-run` path and the real path.
4. A failed scan is fatal, exactly as `scan_refs` treats its own: a scan that
   errors finds nothing, and finding nothing is what a clean tree looks like.
5. Run `tests/.bats-core/bin/bats tests/finalize-docs.bats tests/portability.bats`.

### Tests

`# verifies: PR-9zvb36` unless noted.

* `finalize-docs: a draft link in docs/plans/ is reported as unrewritten`
* `finalize-docs: a narration in a verification record is reported the same way`
  — the script does not judge which is which, and the test pins that.
* `finalize-docs: a reference inside the rewrite scope is not reported as
  unrewritten` — it was rewritten; reporting it too would be noise.
* `finalize-docs: --dry-run previews the unrewritten report` — `would leave
  unrewritten`, and the file is not modified.
* `finalize-docs: the unrewritten report does not change the exit status` —
  exit 0 with hits present.
* `finalize-docs: the header states the finalize date, not the merge date` —
  `# verifies: PR-xec7dd`; `grep -q 'finalize-date'` and no `merge-date` in the
  header.

## T3 — the skills and the templates

**Files touched:** `skills/merge-change/SKILL.md`,
`skills/resolve-problem/SKILL.md`, `skills/worktree-discipline/SKILL.md`,
`skills/grill-requirements/SKILL.md`, `skills/ratchet/SKILL.md`,
`skills/check-traceability/SKILL.md`, `templates/verification.md`,
`templates/problems.md`, `templates/srs.md`, `templates/rmf.md`,
`templates/sad.md`, `templates/AGENTS-block.md`, `README.md`,
`docs/problems/README.md`, `tests/skills.bats`

**Three of the fifteen were added by review rounds**, not planned here, and
`git log` rather than memory says which: `skills/check-traceability/SKILL.md`
and `README.md` in `752c575` (round 1), and `docs/problems/README.md` in the same
commit — each a copy of a claim this task repaired at its primary site and left
standing elsewhere. A "Files touched" list written before the first review is a
prediction; this one is what the task turned out to touch.
**Parallel:** yes — disjoint from T1 and T2
**Items:** `PR-hkc376`, `PR-dkm5tq`, `PR-3s74u3`, `PR-xec7dd` (documentation half)

T3 documents behavior T1 and T2 implement. The verdict names and message shapes
are pinned in those tasks above; T3 writes prose against them and does not edit a
script.

### 3a. The record states the delta, never the total (`PR-hkc376`)

`merge-change` step 6b requires "open PR warnings" in the verification record.
The `check-trace.sh` roll-call is a census of the ledger at an instant, so a
per-change artifact is required to record global state. Downstream: 78 of 123
records mention the roll-call and 20 pin a number, 24 times, across ten distinct
values; one 12-round change spent twelve of its findings on stale numbers; commit
`328f0cfd` is an entire change whose only purpose was correcting a count in an
already-merged record.

1. In step 6b, "open PR warnings" becomes the problem-ledger **delta this change
   makes**: the IDs it resolves, accepts or opens. Not the open count, not the
   roll-call, not the oldest item — each is a property of the ledger at an
   instant, each is falsified by any other change that merges, and a record is
   read long afterwards.
2. In step 7, the commit message template gains two trailers:

   ```
   Resolves: <PR IDs this change closes>
   Opens: <PR IDs this change raises>
   ```

   No script parses the message, so these cost nothing; they are deltas, and they
   are checkable against the diff forever. A change that closes or opens nothing
   omits the line rather than writing an empty one.
3. `templates/verification.md`: the gate table preamble gains — a figure that
   describes the repository rather than this change does not belong in this
   table at all, not even measured fresh. The `check-trace.sh` row asks for the
   exit status plus which of this change's own IDs entered or left the roll-call.
4. `skills/resolve-problem` red flags gain the row the report drafted:

   | "State the backlog size so the reader knows where we are" | The reader's own `check-trace.sh` run knows. A number in a document measures a tree that no longer exists. Name the IDs that moved. |

5. **No gate for this.** A check that rejects count-shaped prose loses to
   respellings, which is this repository's own standing position on shape guards.
   Every step above deletes a requirement rather than policing one.

### 3b. The gate evidence is keyed to a tree (`PR-dkm5tq`)

A findings round sends the sequence to step 1, and steps 2 and 6 then dispatch
the same suite over the same tree: step 3 renames nothing once the drafts are
dated, steps 4 and 5 are read-only, and nothing else between them writes. The
practice is already ahead of the skill — `2026-09-10-field-report-items.md` names
`798790d` as the tree its rows describe. This makes that the schema, and the two
re-runs fall out of it.

1. `templates/verification.md`: the gate table gains the commit the figures were
   measured on, next to the table. The record for this very change is written
   that way.
2. `merge-change` step 6: where step 3 renamed nothing and the tree is the one
   step 2 measured, the step 2 summary stands, and the record states which tree
   it covers. `git rev-parse HEAD^{tree}` on a clean worktree is the whole test.
   Where step 3 renamed anything, dispatch as before.
3. `merge-change` step 3: the commit is conditional on a rename.
   `git add -A && git -c commit.gpgsign=false commit -m "chore: finalize ledger files"`
   is unconditional today, so on a round where nothing was renamed `git commit`
   exits 1 with nothing to commit — a halt for no defect, in a sequence that
   stops at any failure. This was found while assessing the report and is not in
   it.
4. `merge-change` step 1: a base already merged is a no-op, and the figures
   downstream of it stand. `git merge` reports `Already up to date` and the tree
   hash is unmoved, which is the same test as step 6's.
5. Amend the red flag "Skip re-verification, the rename touched no code". Its
   answer becomes the tree hash rather than the author's judgment: a rename moves
   regulated documents and the gate re-runs; a round that renamed nothing moved
   nothing, and the hash is what proves it.

### 3c. The review round is bounded (`PR-3s74u3`)

Three downstream changes, 27 review rounds, the majority of the later ones
correcting prose with prose: one 12-round change whose rounds 11–12 found no code
defect, a 7-round change whose rounds 4–7 found none, an 8-round change on a diff
with no production code at all.

1. Step 6a: the reviewer tags each finding `code`, `requirement` or `record`, as
   the first word of the finding's value —
   `**finding-3**: record — the gate table states 214 tests, the summary 218.`
   `check-review.sh` block-parses the header and ignores the value, so no script
   changes and no new malformed case.
2. The rule: a `code` or `requirement` finding sends the sequence to step 1 and
   a fresh reviewer is dispatched at 6a; a round raising neither is the last
   review round. Every finding reruns the sequence — the tag decides only
   whether another reviewer is dispatched.
3. **The boundary — that a `record` finding not re-run the gate — is NOT
   delivered.** Five formulations were written and five review rounds rejected
   them; see `PR-kc2pzm`. Step 6a states that every finding reruns whatever its
   tag, so no reader infers the saving from the tag's existence. The
   reclassification sentence that belonged to the withdrawn rule went with it. The sequence reruns from
   step 1.
4. Convergence, per the interview decision of 2026-09-15: **a round raising no
   `code` and no `requirement` finding is the last review round.** Its findings
   are answered in the record and anything outstanding is booked there as a gap.
   Not two consecutive rounds: the second buys one independent read of the last
   round's corrections at the price of a whole review dispatch, and the regress
   it guards against is infinite by construction — the verification record is
   already the artifact this process does not verify, which `328f0cfd`
   established rather than fixed.
5. The reviewer is still told to read the record. What changes is what a finding
   against it costs.

### 3d. The finalize date, in the documents (`PR-xec7dd`)

`grep -rn 'merge.date' skills/ templates/` reports **ten** sites outside
`scripts/` — this plan stated eight until T3's test printed all of them; the two
this plan missed are both in `skills/ratchet/SKILL.md`, at the scaffold step and
in the `opened:` backfill note. Each becomes the finalize date, with one sentence at the primary site
(`merge-change` step 3) stating what the date is and what it is not: the date the
draft name was retired, within a few days of the merge, not re-derived
afterwards. The merge date is in git.

### 3e. `FOREIGN-DRAFT`, in the skill that meets it (`PR-8ucezf`) — WITHDRAWN

Withdrawn with T1 on 2026-09-16, for the reasons under "Why T1 was withdrawn".
The step-4 prose specified below was written, reviewed, and removed; what step 4
states instead is that `DRAFT-FILE` does not say whose draft it is and that the
obvious mechanical test is unsafe. Kept in the plan because the withdrawal is
part of this change's record, and a plan that quietly drops a section hides why.
The specification as written was:

`merge-change` step 4 gains what the new verdict means: a draft ledger file left
by another change, the same exit status, and a repair that belongs to a change of
its own rather than to this one. The session that meets it is repairing someone
else's step 3.

### Tests

All in `tests/skills.bats`, each containing its `verifies:` line, each watched
failing against the unedited skill first.

* `merge-change: the record states the ledger delta, not the open count` —
  `PR-hkc376`
* `merge-change: the commit template states the Resolves and Opens trailers` —
  `PR-hkc376`
* `verification template: a repository figure does not belong in the gate table`
  — `PR-hkc376`
* `resolve-problem: a backlog figure in a document is a red flag` — `PR-hkc376`
* `verification template: the gate table names the tree the figures describe` —
  `PR-dkm5tq`
* `merge-change: step 2 records the tree its gate summary describes` —
  `PR-dkm5tq`. Added during the task, not specified here: step 6's comparison
  has no left-hand side unless step 2 records the hash, so this plan asked for a
  rule that could not be followed on its first pass.
* `merge-change: step 6 stands on step 2 where the tree is unchanged` —
  `PR-dkm5tq`
* `merge-change: step 3 commits only when it renamed something` — `PR-dkm5tq`
* `merge-change: the reviewer tags every finding` — `PR-3s74u3`
* ~~`merge-change: a record finding that edits outside the record is not one`~~ —
  `PR-3s74u3`; removed at round 3 as a duplicate of
  `merge-change: a record finding skips the suite, not the gates`, which round 5
  then replaced with `merge-change: the tag does not shorten the sequence` when
  the boundary rule was cut. Neither was in this plan's list: the tests that
  verify this item were written and rewritten by five review rounds, and the
  record's red → green table is the derived list, not this one.
* `merge-change: a round with no code or requirement finding is the last` —
  `PR-3s74u3`
* `the skills and templates name the finalize date, not the merge date` —
  `PR-xec7dd`; a scan over `skills/*/SKILL.md` and `templates/*.md` for
  `merge.date` reporting nothing.
* ~~`merge-change: step 4 states what a foreign draft means` — `PR-8ucezf`~~ —
  withdrawn with T1; this test is not in the tree

## After the tasks

1. Merge each task branch into the change branch and remove its worktree.
2. Mark the **five** delivered items `status: resolved` in the draft ledger, each
   with its root cause and the test that reproduces it. **Four stay open**:
   `PR-9xxz3b` with its scope, `PR-umtm9b` raised by round 1, `PR-8ucezf`
   returned to open by round 2 when its fix was withdrawn, and `PR-kc2pzm`
   raised by round 5 when the boundary rule was cut.
3. `sh tests/run-tests.sh` once, in the change worktree.
4. `check-traceability`, `verify-before-merge`, `merge-change`.

## The conflict this change creates, stated before it is made

`clanker-adoption` is open and edits `skills/merge-change/SKILL.md` (156 lines),
`skills/resolve-problem/SKILL.md`, `skills/verify-before-merge/SKILL.md`,
`skills/worktree-discipline/SKILL.md`, `skills/ratchet/SKILL.md`,
`skills/grill-requirements/SKILL.md`, `templates/AGENTS-block.md` and
`tests/skills.bats`. T3 touches seven of those eight. Whichever change reaches
its signed squash second merges the base again and resolves the overlap by hand;
this change was authorized to proceed on 2026-09-15 with that cost understood.
Writing T3's prose in the post-sweep register is what keeps the overlap to
textual conflict rather than a third pass over the vocabulary.
