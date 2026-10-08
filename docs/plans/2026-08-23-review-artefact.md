# Review-Artefact Gate — Implementation Plan

**Goal:** make the independent review and the verification record checkable
artefacts instead of honour-system prose, and give the record a schema with a
field for what was *not* established.
**Implements:** no requirement items exist in this repository yet (tooth 3).
Addresses findings 04 and 09b of *Where the Gates Leak* (2026-08-20, addendum
2026-08-21).
**Safety class:** B (`docs/adr/2026-08-22-safety-class.md`).
**Verification:** `tests/run-tests.sh` — every bats test green; `sh -n` on
every script; the new gate run against this repository's own records.

---

## The reported defect

> Step 6a is the highest-yield step in the sequence. […] Nothing verifies that
> this step happened. There is no check that a reviewer was dispatched, that
> findings were addressed, or that the verdict recorded in the verification
> record corresponds to anything. Sixty-nine verification records exist on this
> repo, entirely on the honour system.

and

> The verification record captures test totals, gate results, and a verdict. On
> one change the honest position was: root cause measured directly, but the
> end-to-end failure never reproduced. That belongs in the record's schema.

Two failures, one artefact:

| Failure | Observed | Detectable how |
| --- | --- | --- |
| Review never dispatched | asserted in the report | no record, or no `reviewer:` |
| Findings half-applied | *"repeatedly — my fix to a previous round's finding being half-applied"* | a finding with no disposition |
| Doubt undisclosed | *"it appeared only because I chose to write a paragraph"* | no `reproduced:` |

The gate judges **presence, not quality**. It cannot know whether a review was
good. It can know whether one is claimed, by whom, with what conclusion, and
whether every finding it raised was answered.

## What is deliberately NOT built

Recorded here so the next reader does not mistake omission for oversight.

* **No check that the reviewer is independent of the author.** With agent
  reviewers the identity string is whatever the author types. A gate keyed on
  it would be theatre.
* **No validation of records for other changes.** A project adopting this gate
  has a ledger of records written before the schema existed; failing all of
  them at once is how a gate gets switched off. Only the record for the change
  under merge is checked. Legacy records are grandfathered, and this is a
  stated gap, not a claim of coverage.
* **No judgement of the `reproduced:` VALUE.** `reproduced: no` passes. The
  field exists to make silence visible, not to force a yes.

## Design decisions

### D1 — a separate script, not a gate inside `check-trace.sh`

`check-trace.sh` answers "does every item trace". This answers "does this
change have a review artefact". They also run at different points: the trace
gates run at merge-change step 5, before the record exists; this one can only
run after step 6b has written it.

New file: `scripts/check-review.sh`.

### D2 — the record is found by CONTENT, not by filename

merge-change prescribes `docs/verification/<date>-<branch>.md`, and this
repository does not follow it: change 1's branch was `trace-item-blocks` and
its record is `2026-08-23-item-blocks.md`. A gate keyed on the filename would
have failed a correct record. The record therefore declares its own branch:

```
branch: review-artefact
```

and the gate looks for a record declaring the branch that is checked out. This
also survives the rename `finalize-docs.sh` would apply if verification records
ever join the ledger convention.

### D3 — fields are plain annotations at column one

The toolkit has exactly one annotation form — `status:`, `traces:`,
`satisfies:`, `verifies:`, `mitigates:`, `implements:` at column one. The
record's fields use it too, rather than inventing `**reproduced:**`. One shape
across the toolkit, and `gr_kw_here` from `GR_AWK_ITEM_BLOCK` already
implements it.

A bold `**reproduced:**` would additionally CLOSE any open item block, which is
wrong inside a findings section.

### D4 — a finding is an item block; its disposition is an annotation in it

```markdown
**finding-1**: the close rule reinstates the defect on colon-free lines
disposition: fixed in c0ffee1 — test "the close rule fires on a bold sentence"
             reddens without it
```

This is the ledger item shape, so `GR_AWK_ITEM_BLOCK` decides where a finding
starts and ends with no new rule at all: `gr_block_init("finding", "[0-9]+")`
builds the opener `^\*\*(finding)-[0-9]+\*\*:`. "A verdict per finding" is then
a block containing an annotation — the same question `UNRESOLVED-PR` asks of a
problem report.

### D5 — the four required fields

| Field | Catches |
| --- | --- |
| `branch:` | the record belongs to no identifiable change |
| `reviewer:` | the review was never dispatched |
| `verdict:` | a review with no findings leaves no trace that it concluded |
| `reproduced:` | finding 09b — doubt disclosed only when the author chooses to |

Each must carry a **non-blank value**. `reproduced:` on its own line is an
omission wearing the shape of compliance, and is reported as one.

**Amended after review round 1.** `branch:` is listed above as a required field
and it is not one: it is the SELECTOR. The implementation is right where this
plan was wrong. A record that declares no branch is not this change's record at
all, so its absence is `MISSING-RECORD` for the change that expected it — never
`INCOMPLETE-RECORD` against a document that was answering about something else.

### D6 — running it where there is no change is an ERROR, not a pass

On the base branch there is no change under merge and therefore no record to
require. Exiting 0 there would put a green tick on a question that was never
asked — the false green this toolkit exists to remove. `check-review.sh` exits
2 when HEAD is the base branch, or when either branch cannot be determined.

It is therefore a worktree-time gate and is NOT added to the ratchet CI list,
which runs on the base branch.

### D7 — `doc_verification`, defaulting to `docs/verification`

A new config key, added to `GR_KNOWN_KEYS` so setting it is not rejected. It
defaults to `docs/verification`, which is what `ratchet` creates. The default
cannot cause a false green: a project that moved its records leaves the default
path absent, and an absent or `*.md`-free directory is exit 2, the same rule
`gr_doc_files` applies to every other document key.

### D8 — front-matter skipping becomes one definition

`check-trace.sh`'s `ORPHAN-ANNOTATION` scan already skips YAML front matter, so
that a `status:` key in a header block is not read as an annotation. This gate
needs the identical rule for the identical reason — a `reviewer:` key in front
matter must not satisfy `reviewer:` in the body. Two copies of one rule is what
change 1 was about. It is extracted to `GR_AWK_FRONT_MATTER` in `lib.sh` and
both scans consume it.

### D9 — the selector must identify the change, not merely mention it

**Added after review round 1**, which demonstrated the design above failing in
the way it was built to prevent: a change with **no verification record at all**
exited 0, because an unrelated record quoted `branch: <name>` inside a fenced
code block. The selector had no fence awareness, no uniqueness rule, and no tie
to the change — and a branch name is not an identity, so a project that reuses
`fix-ci` or `docs` would also get the previous change's record answering for
this one.

Fence parsing is not the answer: no gate in this toolkit parses fences, and
adding it to one gate would make a second rule about what column one means. Two
answers that need no new rule:

1. **A record claims the FIRST `branch:` it carries and no other.** Every later
   one is quotation. This is the rule `GR_AWK_ID_RUN` already applies to every
   annotation in the toolkit — the first occurrence of the keyword is the claim.
2. **The record must be one this change wrote** — committed on this branch since
   it diverged from the base, modified in the working tree, or not yet tracked.
   Reported as `STALE-RECORD` otherwise. Skipped under `--branch`, where HEAD is
   not known to be the named branch, and the summary line says so; a check that
   announces when it did not run is not a false green.

And one change with no code in it: `ratchet` copies `templates/verification.md`
into `.guardrails/templates/`, **not** into `docs/verification/`. Every `*.md`
directly in the records directory is read as a record, and the template carries
the field names at column one because that is the shape it teaches.

### D10 — a finding must not be able to vanish

**Added after review round 1.** `MALFORMED-FINDING` named one shape of
unreadable header. The neighbouring shapes were still read, matched and dropped:
`**finding-2**` with the colon forgotten neither opens a block nor closes one,
so the next `disposition:` was credited to the finding ABOVE it and both then
read as answered — the half-applied fix this gate exists to catch, inside the
gate. An indented header, a space instead of a hyphen, and a capitalised label
lost the finding the same way.

Two answers, and the second is what makes the first not merely another instance
fix:

1. **Name the shape, byte-wise.** A line beginning `**finding` not followed by a
   letter or digit, that opens no block, is `MALFORMED-FINDING`. Byte-wise
   because the regex it replaces failed OPEN under gawk in a multibyte locale on
   a latin-1 label — the same defect, and the same remedy, as `gr_block_closes`.
   With that, `gr_block_opens_loose` has no consumer and is removed from
   `lib.sh`.
2. **Back it with an orphan rule.** A `disposition:` at column one belonging to
   no finding block is `ORPHAN-DISPOSITION`. It is where the finding went, and
   it catches every shape the rule above cannot name — the same mechanism, and
   the same reasoning, as `ORPHAN-ANNOTATION` in `check-trace.sh`.

---

## Tasks

Each task: failing test first, watch it fail for the right reason, minimal
implementation, watch it pass, commit unsigned in the worktree.

### Task 1 — `GR_AWK_FRONT_MATTER` in `lib.sh`, consumed by `check-trace.sh`

Refactor, behaviour unchanged. The existing front-matter tests
(`check-trace.bats`: `...` terminator, CRLF, BOM, unclosed, thematic break, and
the `FNR`-not-`NR` line-number test) are the safety net; they must stay green
without edits.

1. **RED.** Add to `tests/lib.bats`:

   *(Code pruned at merge: 5 lines.)*

   And, in `tests/check-trace.bats`, the behavioural pin (the shape change 1
   used — a textual pin alone cannot tell a shared fragment from a private
   copy):

   *(Code pruned at merge: 2 lines.)*

   The stub redefines `gr_fm_line` so that NO line is ever treated as front
   matter; a record whose front matter carries `status: open` then reports
   ORPHAN-ANNOTATION. A private copy in `check-trace.sh` survives the poison and
   the test reddens.

2. **GREEN.** In `lib.sh`, after `GR_AWK_ITEM_BLOCK`:

   *(Code pruned at merge: 18 lines.)*

   with `gr_fm_end` accumulated by the caller in pass one. Then replace the
   inline `FNR == NR { … }` block in `check_orphans` with a call to it, keeping
   the BOM strip and the `FNR <= fmend { next }` skip exactly as they are.

3. **Verify:** `sh tests/run-tests.sh` — 260 + 2 green, and specifically the
   five existing front-matter tests unchanged.

### Task 2 — `doc_verification` and `gr_verification_dir`

1. **RED.** `tests/lib.bats`:

   *(Code pruned at merge: 8 lines.)*

2. **GREEN.** Add `doc_verification` to `GR_KNOWN_KEYS`. Add:

   *(Code pruned at merge: 13 lines.)*

   The `*.md`-emptiness check belongs to the file-listing step and reuses
   `gr_doc_files` semantics: no `*.md` at all is exit 2.

### Task 3 — `check-review.sh` and `MISSING-RECORD`

1. **RED.** `tests/check-review.bats`:

   *(Code pruned at merge: 14 lines.)*

2. **GREEN.** Write `scripts/check-review.sh`: header comment in the house
   style listing every gate and every exit-2 condition, `gr_check_config`,
   branch detection, record selection, `MISSING-RECORD`.

### Task 4 — `INCOMPLETE-RECORD`

1. **RED.** One test per required field, plus the blank-value case for each:

   *(Code pruned at merge: 2 lines.)*

   `branch:`, `reviewer:`, `verdict:`, `reproduced:` × {absent, blank} = 8
   tests, plus one that a field in YAML front matter does not satisfy the
   requirement (the D8 case).

2. **GREEN.** One awk pass per record using `GR_AWK_FRONT_MATTER` and
   `gr_kw_here`, collecting which of the four keywords appeared at column one
   with a non-blank remainder. Report each missing one on its own line:

   *(Code pruned at merge: 1 line.)*

### Task 5 — `UNDISPOSED-FINDING`

1. **RED.**

   *(Code pruned at merge: 5 lines.)*

   The third and fifth are the block-boundary tests change 1 established: they
   fail if the finding scan uses anything other than `GR_AWK_ITEM_BLOCK`.

2. **GREEN.** `gr_block_init("finding", "[0-9]+")`, collect blocks, report:

   *(Code pruned at merge: 1 line.)*

### Task 6 — `templates/verification.md`

The template the skill tells the author to copy. Carries the four fields, one
worked finding block, and — in the house style of `templates/problems.md` — a
short grammar note explaining what each field is for, with every illustrative
form kept **inline in backticks** so no line of the template is itself matched
by the gate.

### Task 7 — skills, README, config template

* `skills/merge-change/SKILL.md`: step 6b names `templates/verification.md` and
  the four required fields; a new step **6c** runs `check-review.sh`; the
  red-flag table gains *"the reviewer found nothing worth writing down" →
  "then `verdict:` says so; a record with no findings is legal, a record with
  no verdict is not."*
* `skills/verify-before-merge/SKILL.md`: unchanged — the record does not exist
  yet at that point, and saying so prevents the next reader adding it there.
* `skills/ratchet/SKILL.md`: copy `templates/verification.md`; mention
  `doc_verification`; state that `check-review.sh` is NOT a CI gate (D6).
* `templates/config.yaml`: document `doc_verification` and its default.
* `README.md`: the gate table gains the three new violations.

### Task 8 — dogfood

Write `docs/verification/2026-08-23-review-artefact.md` against the new schema,
with a `finding-N`/`disposition:` block per review-round finding, and run
`check-review.sh` on this repository. It must pass for the right reason —
confirmed by deleting the `reproduced:` line and watching it fail.

---

## Self-review

1. Every task has a test that reddens before its implementation exists.
2. The two refactor tasks (1, 2) are pinned behaviourally, not textually: a
   private copy of either shared fragment must change a verdict, per change 1's
   lesson that a textual pin cannot tell a shared rule from a copy of one.
3. Names are consistent across tasks: `MISSING-RECORD`, `INCOMPLETE-RECORD`,
   `UNDISPOSED-FINDING`; fields `branch:`, `reviewer:`, `verdict:`,
   `reproduced:`; annotation `disposition:`.
