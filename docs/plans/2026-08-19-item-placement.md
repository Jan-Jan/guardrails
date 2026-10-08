# Item Placement Gate Implementation Plan

**Goal:** an item counted in `checked:` must sit in a document some gate reads;
one defined anywhere else is reported `MISPLACED-ITEM` and fails the check.
**Implements:** AC1–AC8 below. This repo has no `.guardrails/config.yaml` and
no SRS — a standing self-conformance gap recorded in the change A and change B
verification records — so there is no REQ ID to cite. The requirement is
written here instead, before any code, and each task names the criteria its
tests cover. Inventing a `REQ-NNN` for a project with no SRS would be a
traceability ID pointing at nothing.
**Safety class:** not configured for this repo (no config). The scripts are
the tooling that enforces class B/C elsewhere; treated as class B here by
convention: every criterion gets normal-case AND abnormal-input tests.
**Verification:** `sh tests/run-tests.sh` (all bats green), plus a clean-clone
corpus run against `sightings-app`.

## The requirement

Change A left this gap, stated in `scripts/check-trace.sh`, `README.md` and
`skills/check-traceability/SKILL.md` in these words:

> `checked:` counts items found anywhere in the tree, not items examined. An
> item defined outside the document configured for its prefix is counted here
> and read by no gate.

That is a silent exemption. `**SDD-001**:` written in `docs/design.md` — with
no `traces:` line at all — is counted by `checked:` and examined by nothing,
because `UNTRACED-DESIGN` only reads the files `doc_sad` resolves to. Moving
that identical file into `doc_sad` turns the run red without changing a
character of its content. The verdict depends on where a file sits, and
nothing says so.

**Required behaviour.** For each gated prefix, `check-trace.sh` compares the
IDs defined anywhere in the tree against the IDs defined inside the document
configured for that prefix, and reports every ID in the difference.

| Criterion | Behaviour |
|---|---|
| **AC1** | An item defined outside its configured document is reported as `MISPLACED-ITEM <ID> (defined outside <key>, so its gates never see it)` and the check exits 1. |
| **AC2** | Placement is checked for each of the six gated prefixes against its own definition document: REQ→`doc_srs`, HAZ→`doc_rmf`, RC→`doc_rmf`, SDD→`doc_sad`, LLR→`doc_sad`, PR→`doc_problems`. |
| **AC3** | An item defined inside its configured document is not reported. A project whose items are all correctly placed stays green. |
| **AC4** | A `doc_*` value that is a directory resolves one level deep (`gr_doc_files`), so an item in a subdirectory of that directory is genuinely unread by its gates and IS reported. This is the intended verdict, not a false positive. |
| **AC5** | Declaring `RC` without configuring `doc_rmf` is a config error (exit 2), because from this change on a gate for `RC` reads `doc_rmf`. |
| **AC6** | The gate reports every misplaced item, not the first, so one run lists the whole migration. |
| **AC7** | Placement covers only the six gated prefixes. An extra prefix (`ADR`) has no configured document and is not placement-checked — it keeps the `DANGLING-REF`/`DUPLICATE-ID`/finalization coverage change B established. |
| **AC8** | With the gate green, `checked:` counts items a gate read. The three copies of change A's gap statement are updated to say so. |

**Why a hard failure and not a warning.** Measured on a clean clone of the
`sightings-app` corpus at `4909a1ab`: 244 items across the six prefixes, **zero
misplaced**. The gate is a no-op on a project that was already doing this
right, so it needs no compatibility flag and no grace period. What it costs is
paid only by a project that has the defect.

## Task 1 — the gate, on the motivating case (AC1, AC6)

Trace: AC1, AC6.

### 1.1 RED

Append to `tests/check-trace.bats`:

*(Code pruned at merge: 11 lines.)*

Run: `env -u SSH_AUTH_SOCK sh tests/run-tests.sh 2>&1 | grep -n 'MISPLACED'`.
Expect `not ok` with `status` 0 — the run passes today, which is the defect.

### 1.2 GREEN

In `scripts/check-trace.sh`, after `ids_defined`, add:

*(Code pruned at merge: 10 lines.)*

and before the `MISSING-TEST` block:

*(Code pruned at merge: 23 lines.)*

Re-run: the new test is `ok`, 135 others still `ok`.

### 1.3 Commit

`git -c commit.gpgsign=false commit -am "feat: report an item defined outside its own document"`

## Task 2 — the remaining dispatch branches (AC2)

Trace: AC2. Each branch gets its own test; a `case` arm with no test is an
untested branch, and the REQ and PR arms in particular are separate code paths.

### 2.1 RED — five tests

*(Code pruned at merge: 52 lines.)*

Each must fail before 2.2 for the right reason. The LLR test is the one to
watch: `UNSATISFIED-LLR` also fires on an LLR outside `doc_sad` (the block
parse never sees its `satisfies:`), so it already exits 1 today — confirm the
RED is the missing `MISPLACED-ITEM` line, not the status.

### 2.2 GREEN

Extend the dispatch:

*(Code pruned at merge: 12 lines.)*

### 2.3 Commit

## Task 3 — no false positive, and the one-level-deep rule (AC3, AC4)

Trace: AC3, AC4.

### 3.1 The healthy-project guard (AC3)

*(Code pruned at merge: 13 lines.)*

**This test passes before the implementation exists, so it proves nothing on
its own** — it is a guard against over-firing, not a RED test. It is verified
by mutation instead, in task 7: delete the `-- "$@"` pathspec from
`ids_defined_in` (making it scan the whole tree) and this test must stay green
while task 1's goes red; delete the `gr_contains` check and this test must go
red. Both mutations are run and recorded by name.

### 3.2 RED — the subdirectory case (AC4)

*(Code pruned at merge: 13 lines.)*

This one is RED before task 2's REQ branch exists and green after; it is
listed here because it pins `gr_doc_files`' depth as intended behaviour rather
than an accident, and it would be the first thing to break if that expansion
ever changed.

### 3.3 Commit

## Task 4 — RC now needs doc_rmf (AC5)

Trace: AC5.

**This reverses a correction made during change B, and the reversal is
legitimate because the premise changed.** Change B's round 1 rejected
`RC) _need="doc_rmf doc_srs"` on the ground that *no RC gate reads `doc_rmf`* —
true at the time: `UNIMPLEMENTED-CONTROL` reads `doc_srs` for a REQ that
implements each RC, and nothing else looked at where an RC was defined. From
this change on, `check_placement RC doc_rmf` reads it. Leaving the map alone
would mean an `RC` declared with no `doc_rmf` reports *every* control as
misplaced with a message naming a key the project never configured — accurate
but useless. One config error at exit 2, before any gate runs, is the shape
change B established for exactly this.

The cost is real and stated: a retrofit that has risk controls but no risk
management file yet is now rejected. That shape has nowhere legitimate to
define its controls once placement is enforced, which is why it is rejected
rather than warned about.

### 4.1 RED

*(Code pruned at merge: 9 lines.)*

### 4.2 GREEN

In `scripts/lib.sh`, change `RC)  _need="doc_srs" ;;` to
`RC)  _need="doc_rmf doc_srs" ;;` and rewrite the comment above the map so it
no longer asserts the opposite. The existing comment says:

> UNIMPLEMENTED-CONTROL looks for a REQ that implements each RC, so RC needs
> doc_srs and NOT doc_rmf. Requiring the definition document as well would
> reject a retrofit that has controls but no risk management file yet, while
> telling it a gate could never run that demonstrably does.

Replace with:

> UNIMPLEMENTED-CONTROL looks for a REQ that implements each RC, so RC needs
> doc_srs. It also needs doc_rmf, but only since the placement gate: MISPLACED
> -ITEM reads doc_rmf to decide whether each RC is defined where its gates can
> see it. Before that gate existed this entry was doc_srs alone, and requiring
> doc_rmf then would have claimed a gate could never run that demonstrably did.

Check no other test asserted the old shape:
`grep -rn 'doc_rmf' tests/*.bats | grep -i 'RC'`.

### 4.3 Commit

## Task 5 — close change A's gap statement (AC8)

Trace: AC8. The mirror of change B's task 6: three documents carry the gap in
wording deliberately preserved across two changes, and landing this makes all
three false.

1. `scripts/check-trace.sh` header — delete the `KNOWN GAP` paragraph
   (currently lines ~39–43); add to the gate list, after `DANGLING-REF`:

   *(Code pruned at merge: 2 lines.)*

   and rewrite the `checked:`/`sources:` paragraph: it currently says
   `checked:` "is NOT yet a guarantee that a gate read them". With this gate
   green it is exactly that guarantee. New text:

   *(Code pruned at merge: 7 lines.)*

2. `README.md` — the "What this does not yet cover" paragraph naming
   `**SDD-001**: in docs/design.md`. Replace the claim with the gate.
3. `skills/check-traceability/SKILL.md` — the "One known gap, deliberate and
   recorded in the plan" section. Same treatment.

Sweep for stragglers before committing:
`grep -rn "counts items found\|counted here and read by no gate\|item-placement change" --exclude-dir=.git .`
Every hit outside `docs/plans/` and `docs/verification/` (frozen records) must
be gone.

## Task 6 — migration note (AC1, AC5)

Trace: AC1, AC5. `skills/ratchet/SKILL.md` carries change B's upgrade table;
add a row for this change:

| Shape | Was | Now |
|---|---|---|
| Item defined outside its `doc_*` document | counted in `checked:`, read by no gate, exit 0 | `MISPLACED-ITEM`, exit 1 |
| `id_prefixes` declares `RC`, no `doc_rmf` | accepted | exit 2 |

with the remedy: **move the definition into the configured document** — not
delete the item, and not add the file to `strict_paths`, which does not make a
gate read it. For an ID that appears at column one in illustrative text
(a plan, a changelog, a README example), the remedy is the opposite: stop
using a real three-digit ID there. Write `**REQ-NNN**:`, which no scan matches.

## Task 7 — verify (all AC)

1. `env -u SSH_AUTH_SOCK sh tests/run-tests.sh` — all green, count recorded.
2. `sh tests/evidence.sh` — suite total, new tests, how many go red against
   the merge base, and the names that cannot.
3. Mutation runs, each in a scratch copy, each reddened test cited **by name**:
   - drop `-- "$@"` from `ids_defined_in`
   - drop the `gr_contains` check in `check_placement`
   - restore `RC) _need="doc_srs"`
   - remove the `PR)` dispatch arm
   - remove the `REQ)` dispatch arm
4. Corpus: clean clone of `sightings-app`, run this branch's `check-trace.sh`
   and `check-ids.sh` against it; compare byte-for-byte with the same run from
   merged `main`. Expected identical (measured: zero misplaced items there).
   The user's working tree is never touched.
5. Write `docs/verification/2026-08-19-item-placement.md`: figures derived from
   `tests/evidence.sh`, mutation table with test names, corpus result, and the
   gaps this change leaves open.

## Self-review

- Every criterion AC1–AC8 has a task whose tests verify it: AC1/AC6 task 1,
  AC2 task 2, AC3/AC4 task 3, AC5 task 4, AC7 covered by change B's existing
  "extra prefix is accepted and still checked" test plus the `*)` arm's
  absence from the dispatch, AC8 task 5.
- Names used across tasks are consistent: `ids_defined_in`, `check_placement`,
  `_inside`, `MISPLACED-ITEM`.
- No step says "add tests later" or "handle edge cases".

## Corrections made during execution

The plan was written before reading `tests/check-trace.bats`' preamble, and
four things in it were wrong. Recorded rather than quietly rewritten.

1. **Every test body in tasks 1–4 called `make_fixture_repo`.** That file has a
   `setup()` which already does, and which seeds a fully-traced baseline
   (`REQ-001`, `HAZ-001`/`RC-001`, `SDD-001`/`LLR-001`, a verifying test). A
   second call re-inits the same repo and `git commit` fails with "nothing to
   commit". Every test was rewritten to mutate that baseline with `-002` items
   instead. The baseline also turns out to be a better guard than the fixture
   the plan proposed: `check-trace: fully traced fixture passes` already
   asserts a correctly-placed project stays green.

2. **The plan predicted the LLR test would already exit 1 today** via
   `UNSATISFIED-LLR`. Wrong: `llr_info` is parsed only from `sad_files`, so an
   LLR outside `doc_sad` is invisible to that gate too — it was unread twice
   over. The test's comment now says so.

3. **Task 2's LLR test was not RED.** Task 1 implemented the arm as `SDD|LLR`,
   so the LLR test passed the moment it was written — a TDD deviation. It is
   kept, labelled, and backed by a dedicated mutation (`SDD|LLR` → `SDD`) in
   the verification record.

4. **Task 4 added no test; it rewrote one.** Change B's round 1 had added
   `check-trace: RC without doc_rmf still runs its gate, and is not rejected`,
   which pins the behaviour this task reverses — the suite caught it as a
   failure. Rewriting that test in place, with the reversal recorded in its
   body, is right where adding a second test asserting the opposite would have
   left the suite self-contradictory. The plan's separate task-4 test was
   written, found to duplicate it, and deleted.

   Task 4 also grew beyond "change one map entry": `gr_check_config` now states
   two separate rules (gate inputs, definition documents) because the
   justification for the new requirement is not the one the existing map
   documents. See the verification record.


## Amendments to the acceptance criteria

AC1–AC8 are this change's requirement of record — there is no SRS to hold a
REQ. So an implementation that does not satisfy one of them is a deviation
that has to be recorded here, in the requirement, not only in the verification
record. Two were amended during review.

**AC1 is amended.** It required the message
`MISPLACED-ITEM <ID> (defined outside <key>, so its gates never see it)`.
That message was rejected by the first review round and its replacement by the
second, both times because the consequence it asserted was disproved by the
same run that printed it — `MISSING-TEST` and friends still enumerate a
misplaced item, and `DANGLING-REF` still reads the annotations of one misfiled
into another ledger. AC1 now requires:

> An item defined outside its configured document is reported as
> `MISPLACED-ITEM <ID> (must be defined in the files <key> resolves to)` and
> the check exits 1. The message states the rule only. The consequences —
> which gates still see the item, which no longer parse its block, and the
> `DANGLING-REF` and `HAZ` exceptions — are stated in
> `skills/check-traceability/SKILL.md`, `README.md` and the gate's own comment
> block, where there is room to state them accurately.

**AC4 is amended.** It said an item in a subdirectory "is genuinely unread by
its gates". Same false claim. It now reads: such an item is not among the
files the key resolves to, so the gate keyed on that document never parses its
block. AC4 also now covers a `doc_*` configured as a single file, which
resolves to that file whatever its extension — the `*.md` phrasing was wrong
for that supported shape.

The verification record's findings 2, 8 and the third-round blocking finding
carry the reproductions.
