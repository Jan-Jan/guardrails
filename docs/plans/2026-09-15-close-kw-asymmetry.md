# Close the annotation keyword asymmetry — Implementation Plan

**Goal (AS SHIPPED, corrected after four review rounds):** the
ORPHAN-ANNOTATION backstop sees a list-marker annotation that no reader may
take a value from — the invariant is CONTAINMENT, backstop ⊇ reader, never the
equality this line first stated. Two marker forms are covered, bullets and
ordered; the rest of markdown list syntax is not, and is unenumerated.
**Implements:** `PR-6d2jvt` in full. **`PR-h3wujj` is NOT implemented and stays
`status: open`** — this change narrows it and does not close it.

**Read every instruction below with those two corrections applied.** The steps
were written before either was known and are kept as written, with dated
`CORRECTED` blocks where they mislead; where a step says "route `gr_kw_here`
and `gr_value` through `gr_kw_lead`", the shipped change adds a separate
`gr_kw_orphan_here` instead, and where it says to mark `PR-h3wujj` resolved or
to write the `lib.sh` note as CLOSED, the shipped change does neither.
**Safety class:** B (this repository, per AGENTS.md)
**Verification:** `sh tests/run-tests.sh` — and that is the whole list.
Neither `check-ids.sh` nor `check-trace.sh` nor `check-review.sh` can run
against this repository at all; see the corrected paragraph below, and
`docs/verification/2026-09-16-close-kw-asymmetry.md` for the figures derived
against a synthesized config.

**CORRECTED after T1 reported, and again after the review (finding-10):**
this line first named `sh scripts/check-trace.sh`, which **cannot run in this
repository** — it exits 2 with
`guardrails: file not found: .guardrails/config.yaml`, because guardrails is
not itself a ratcheted project. The first correction exempted that script
alone and left `check-ids.sh` and `check-review.sh` standing as though they
ran. **All three exit 2, for the identical reason.** None of the three can be
a verification command here; they are exercised through `tests/*.bats`, and
the record derives its figures against a synthesized config quoted in full, as
prior records do.

## What was measured first, at d8502d1

A probe tree built outside the repository, with an explicit `## Notes` heading
so the probe line sits outside every item block (a bare paragraph does NOT
close a block, and a first attempt measured nothing because of it):

| fixture | result |
|---|---|
| `satisfies: REQ-x` at column one, outside every block | `ORPHAN-ANNOTATION docs/architecture/sad.md:8` |
| `- satisfies: REQ-x`, same position | **silent** |
| LLR block with no `satisfies:` | `UNSATISFIED-LLR` |
| LLR block with `- satisfies: REQ-x` inside it | **silent** — the bullet is credited |

The last two rows are the half that matters: the reader accepts the bullet
form, and the backstop cannot see it. That is the divergence the backstop was
built to prevent.

## The fix is to the BACKSTOP, not to the readers

The scratchpad investigation proposed pairing the three bare `gr_id_run` reads
with `gr_kw_here`. **That is wrong and is not done here.** `templates/sad.md`
ships the annotation ON the definition line —
`**LLR-NNNNNN**: <behavior>. satisfies: REQ-NNNNNN` — and both readers carry a
comment saying so (`check-trace.sh:430`, `:577`: *"Deliberately no `next`: the
header line itself usually carries the annotation"*). Requiring column one of
the readers would reject the documented primary form and every SAD written
against it.

So `gr_id_run` stays as it is, and the single change is that `gr_kw_here`
learns the list-marker form. Reader and backstop then agree.

**CORRECTED after an independent review returned REJECT (2026-09-16):** that
last sentence is the error the rest of this plan builds on, and the section
heading above it is the part that was right. Widening `gr_kw_here` widens every
READER as well as the backstop, and the readers are FIRST-OCCURRENCE-WINS, so a
QUOTED bullet outranks the real annotation. Two regressions were demonstrated
against the T1/T2 tree: a `PR` block quoting `- status: resolved` in its prose
above its own column-one `status: open` left the roll-call at exit 0
(`problems: open 0`), and a verification record declaring
`branch: other-change` that quoted `- branch: my-change` became the record FOR
`my-change`, exit 0 over a review that never happened.

**The invariant is backstop-CONTAINS-reader, never backstop-EQUALS-reader.** A
reader that takes a value from a position the backstop cannot see is the hole;
a backstop that sees MORE than the readers is safe, because it reports and
takes no value. So the shipped shape is: `gr_kw_here` and `gr_value` stay at
column one exactly as they were on `main`; `gr_kw_lead` stays; a NEW predicate
`gr_kw_orphan_here` is column-one-or-after-a-list-marker and is used by the
BACKSTOPS alone — `check_orphans` in `check-trace.sh`, and the
`ORPHAN-DISPOSITION` half of the `disposition:` rule in `check-review.sh`,
whose reader half stays narrow. Read the steps below with that substitution in
mind: everywhere T1 says "route `gr_kw_here` and `gr_value` through
`gr_kw_lead`", the shipped change instead adds `gr_kw_orphan_here` beside them.
A bulleted annotation is consequently never READ and IS reported where it
belongs to no item; inside a block it leaves the field missing, which is
`INCOMPLETE-PROBLEM` or `MISSING-RECORD`, and loud.

`implements:` is NOT added to the backstop. `check-trace.sh:1023` already
rules on it: `mitigates:`, `implements:`, `verifies:` and `assesses:` are read
line-wise by `ids_matching`, never against a block, so they cannot be orphaned
and reporting them would be noise. `gr_req_scan` (lib.sh:1369) does read
`implements:` block-scoped, so the two readers of that keyword disagree about
scope — that is real, it is unit-mode only, and it is now `PR-44ww7q` rather
than a sentence in a plan.

**CORRECTED after the review (finding-8):** this paragraph named the function
`gr_unit_ann_scan` twice, at `lib.sh:1342`. No such function exists —
`grep -rn gr_unit_ann_scan scripts/` returns nothing. It is `gr_req_scan`, at
`lib.sh:1369`. The substance was right and the name was written from memory,
in the one paragraph a later reader would use to find the code.

### T1 — the widening, its two prose casualties, and the note

**Files touched:** `scripts/lib.sh`, `templates/problems.md`,
`docs/problems/README.md`, `tests/lib.bats`, `tests/check-trace.bats`
**Parallel:** no (single task; every file set below intersects)

Steps, in this order. Step 1 is first because it is the precondition the
revert note names: the widening fires on that line, and a gate that reddens
the shipped template on the day it lands is not adoptable.

1. **`templates/problems.md:73` and `docs/problems/README.md:73`** — the same
   sentence, shipped twice. The bare form

   > `- status: resolved only in the same change that merges the fix.`

   gains backticks around the illustrative annotation, so the line reads
   `- ` then the form in backticks then the rest of the sentence. The
   convention is already the templates own: illustrative forms go inline in
   backticks. `lib.sh` names `templates/problems.md` as why the earlier
   attempt was reverted and does not mention the `docs/problems/README.md`
   twin, so the revert note understated its own blast radius by half.

   These two lines are the ENTIRE measured cost in this repository. The
   measuring command is an extended-regex recursive grep over `docs/`,
   `templates/` and `skills/` for a line whose first non-blank characters are
   a list marker followed by one of the block-parsed keywords; it returns
   exactly those two lines. The same grep for the four record fields
   (`branch`, `reviewer`, `verdict`, `reproduced`) returns zero.

2. **`scripts/lib.sh`, inside `GR_AWK_ITEM_BLOCK` (lines 237-308).** Add a
   `gr_kw_lead(line)` helper that copies the line, applies
   `sub(/^[ \t]*[-*+][ \t]+/, "", s)` to it and returns the result. Route
   both `gr_kw_here` and `gr_value` through it: `gr_kw_here` tests
   `index(gr_kw_lead(line), kw) == 1`, and `gr_value` takes
   `substr(gr_kw_lead(line), length(kw) + 1)` before its existing two trims.

   **`gr_value` must move with `gr_kw_here` or the value is garbage.** It
   takes `substr(line, length(kw) + 1)`, which assumes the keyword starts at
   byte one; against a bulleted `status: open` it slices out of the middle of
   the keyword. The two already live side by side in the file for this reason,
   and the comment there says so.

   **CORRECTED after T1 reported:** this paragraph first said the garbage
   value was `pen`. It is `s: open`. The direction was right and the literal
   was invented — a figure asserted rather than measured, which is the failure
   the record of `2026-09-10-field-report-items` spent 24 of its 33 findings
   on. T1 asserted the measured value in its test rather than the plan's.

   **CORRECTED AGAIN after the review (finding-7):** the sentence above first
   said "the previous change's verification record spent twenty-four findings
   on" — two errors in one clause written to indict an invented figure. No
   record has 24 findings (the counts are 33, 23, 19, 14, 12, 12), and the
   PREVIOUS change is `2026-09-15-clanker-adoption`, which has 12. The 24 is
   the prose subset of the 33-finding record named above, which is a different
   record and a different number. Re-derived by counting `**finding-N**:`
   headers per file rather than by recalling them.

   **A marker, never bare indentation.** The `[ \t]*` before the marker
   admits a nested bullet; with no marker present nothing changes. That is
   what keeps the indented grammar comments in the ledger templates inert,
   which is the property `lib.sh` names and which step 1 does not cover.

   **No apostrophe in any comment added here.** `GR_AWK_ITEM_BLOCK` is a
   single-quoted shell string; line 208 already writes a possessive with a
   backtick for this reason.

3. **`scripts/lib.sh:254-283`** — the `A KNOWN ASYMMETRY, now HALF closed`
   note becomes closed. Keep the `status:`/`opened:` entry, rewrite the
   `traces:`/`satisfies:` entry as CLOSED with today date, and say what the
   closure does NOT cover: `gr_id_run` still takes the keyword anywhere on the
   line, so a mid-sentence mention inside a block is still credited. Delete
   the "route out" paragraph, which has been taken.

4. **Tests** (`tests/lib.bats` for the predicates, `tests/check-trace.bats`
   for the gate). Each watched failing first, against the unmodified
   `lib.sh`:

   * `gr_kw_here accepts a list marker before the keyword`
   * `gr_kw_here still rejects bare indentation`
   * `gr_value reads past a list marker` — the one that returns `pen` today
   * `check-trace: a bullet satisfies: outside every block is an orphan`
   * `check-trace: a bullet status: is read as the problem status`
   * `check-trace: an indented grammar comment is still inert`

   The last is a scope control as much as a test: it is the property step 2
   is built around, and it must be pinned rather than asserted.

   **CORRECTED 2026-09-16, with the REJECT above.** The first and third names
   move onto the new predicate — `gr_kw_orphan_here accepts a list marker
   before the keyword`, `gr_kw_orphan_here still rejects bare indentation`, and
   `gr_value reads from column one, and composes for the wider position`. The
   fifth INVERTS: `check-trace: a bullet status: is NOT read as the problem
   status`, and the item stays `INCOMPLETE-PROBLEM`. Two tests are added, one
   per review finding, each watched failing against the rejected tree:
   `check-trace: a quoted bulleted status: does not outrank the item's own` and
   `check-review: a quoted bulleted branch: does not claim the record`. One
   more is added as the scope control the regressions turned on:
   `gr_kw_here rejects a list marker before the keyword`.

5. **Mutation anchors.** Per `develop-change` step 6, grep
   `docs/verification/*.mutations/` for every changed line of `lib.sh` before
   committing, re-cut any anchor that quotes one, and prove the re-cut anchor
   still kills tests. `gr_kw_here` and `gr_value` are short, quotable lines in
   a much-quoted file; assume anchors exist until the grep says otherwise.

### T2 — the ratchet upgrade note, and every place that states the old rule

**Files touched:** `skills/ratchet/SKILL.md`,
`skills/check-traceability/SKILL.md`, `scripts/check-trace.sh`,
`templates/problems.md`, `docs/problems/README.md`
**Parallel:** no (after T1 — the note describes what T1 does)

**AMENDED after T1 reported.** The plan named one file. T1 found four more
that state the now-false rule, and was right not to touch them — they are
this task. The amendment is recorded rather than folded in silently, because
a plan that quietly grows is a plan nobody can check afterwards:

* **`skills/check-traceability/SKILL.md`** — five places. Line 71 ("Its known
  limit was that it matches a keyword only at column one"); lines 79-85, which
  say in bold **"It is not fixed for `traces:` and `satisfies:`"**; and three
  remedy columns, 156 ("no definition scan matches a form off column one" —
  about definition forms, still TRUE, leave it), 157 ("a `status:` … line at
  column one that belongs to no item" and "column-one anchoring is what keeps
  the grammar comments in the ledger templates inert") and 159 ("no column-one
  `status:`"). Line 157's closing clause is the sharpest: it now names the
  wrong mechanism for a property that still holds, since it is the ABSENCE of
  a marker that keeps a grammar comment inert, not its indentation.
* **`scripts/check-trace.sh:1028-1030`** — *"Column one, like every definition
  form here. That is what keeps the grammar comment shipped in
  templates/problems.md inert."* Both halves are now false: not column one,
  and not what keeps it inert. This is a script, so T1 step 5's mutation-anchor
  grep applies to it too.
* **`templates/problems.md:25` and `:35`**, and the `docs/problems/README.md`
  twin of each — "Both are read at COLUMN ONE" and `disposition:` "at column
  one". Still true and now incomplete; a bullet is read as well. **Line 82 is
  about DEFINITION forms, not annotations, and must not be touched** — that
  rule did not change.

A new block in the upgrade sequence, in the voice the surrounding ones use.
It must say, because these are what an adopter has to act on:

* **This DOES touch existing ledgers**, unlike the `accepted` block above it.
  An annotation written as a list item that was silently doing nothing now
  either reports `ORPHAN-ANNOTATION` (outside a block) or starts being read
  (inside one). The second is the sharper one: a problem item whose only
  `status:` was a bullet was `INCOMPLETE-PROBLEM` and is now simply read, so
  an item can change state on the day of the upgrade.
* **The migration is bounded and greppable**, with the exact grep from T1
  step 1 so an adopter can size it before upgrading.
* **The shipped `templates/problems.md` line changed too**, so a project that
  copied it into its own `docs/problems/README.md` carries the same line and
  must fix it in place.

### T4 — the report catalogue, added after the plan was written

**Files touched:** `skills/check-traceability/SKILL.md`, `tests/skills.bats`,
`docs/problems/DRAFT-close-kw-asymmetry-report-catalogue.md` (finalized to
`docs/problems/2026-09-16-report-catalogue.md`)
**Parallel:** no (after T2 — it edits the file T2 rewrites)

**ADDED 2026-09-16, after round 2 raised finding-20.** This task was dispatched
and merged (`4160ee9`, merged at `d0418a9`) while the plan named only T1-T3, and
two corrections then cited "T4" as though the section existed. It did not. The
section is written here rather than the citations removed, because the task was
real and a plan that omits a merged task is the defect finding-5 named.

`PR-6d2jvt` was found while reviewing this change's own T2 edits: the report
catalogue in `skills/check-traceability` had no row for `ACCEPTED-PR`,
`MALFORMED-SUPERSESSION` or `NON-RECIPROCAL-SUPERSESSION` — all three shipped
by `d8502d1` the day before — and its `MALFORMED-STATUS` row instructed an
author to reject `accepted`, the ledger's only way to record a ruling.

The task: write the three rows in the voice of the surrounding ones, correct the
`MALFORMED-STATUS` row to the script's three values, and add a gate that derives
BOTH sets from the files rather than listing either — a listed set is a second
copy of the thing being checked and rots the same way the catalogue did. The
test stops at the script's own `# Scoped (multi-unit) runs add:` heading rather
than carrying an exemption list, which bounds it to a default run and leaves the
six scoped reports to `PR-judqb7`.

### T3 — resolve the item and record the change

**Files touched:** `docs/problems/2026-09-15-class-b-report.md`,
`docs/verification/<date>-close-kw-asymmetry.md`
**Parallel:** no (after T1 and T2)

`PR-h3wujj` to `status: resolved` in the dated file that defines it, with root
cause and the reproducing tests named. Amend its `affects:` to record what the
investigation corrected: the readers are NOT the defect, and the
`implements:` scope divergence in `gr_unit_ann_scan` is noted as out of scope
rather than silently dropped.

The verification record carries the red-green table, the gate figures
re-derived at the tree under merge, and — required by AGENTS.md
non-negotiable 5 — the line that the base was merged from local `main`.

**It must also record that this change was opened while `clanker-adoption`
was open**, against non-negotiable 4, on the user instruction of 2026-09-15.
A deliberate exception that is not written down reads as a rule nobody
noticed.

## Self-review

**CORRECTED after the review (finding-5):** item 1 below read "`PR-h3wujj` is
the only ID implemented" after `PR-6d2jvt` had been minted, implemented,
tested and resolved on this branch — a second problem item absorbed with no
task, no amendment and a self-review that denied it, in a plan that amends
itself in writing for smaller things. T4 is the task that implemented it and
is recorded below; `PR-44ww7q` and `PR-judqb7` are minted but NOT implemented
here, and are open items rather than work.

1. Two IDs are implemented: `PR-h3wujj` (T1, the backstop widening) and
   `PR-6d2jvt` (T4, the report catalogue). Every test that verifies either
   carries a `verifies:` annotation naming it.
2. Every step names real paths, real code, and the command that measures it.
3. Two new names: `gr_kw_lead`, called by exactly two callers
   (`scripts/lib.sh` and the composed value read in `scripts/check-review.sh`),
   and `gr_kw_orphan_here`, the backstop predicate the redesign turns on, whose
   two call sites are `check_orphans` in `check-trace.sh` and the
   ORPHAN-DISPOSITION selector in `check-review.sh`.

   **CORRECTED after round 2 (finding-19):** this item read "`gr_kw_lead` is
   the one new name and is used by exactly two callers" — the caller count
   right, the rest a pre-redesign sentence left standing twelve lines below the
   paragraph introducing the second name, in the section whose job is to catch
   exactly that.
4. One task touches `lib.sh`; nothing runs in parallel, so no file set
   intersects another.
