# Block-attributed credits Implementation Plan

**Goal:** `implements:` and `mitigates:` credit an item only from a line inside the block of the item that makes the claim, read once, so a control or hazard is never counted as covered by a line that belongs to no REQ or RC, and the unit-mode expectation severity reads the same answer as UNIMPLEMENTED-CONTROL.
**Implements:** none. No item is claimed or amended: the toolkit keeps no REQ ledger of its own. Delivers D1 to D5 below; resolves PR-44ww7q and PR-z7w5bf.
**Safety class:** unclassified (the toolkit has no `.guardrails/config.yaml`).
**Verification:** `sh tests/run-tests.sh`; `check-ids.sh` and `check-trace.sh` against scratch copies of `main` and of the change, criterion no finding that `main` lacks.

PR-44ww7q asked for a measurement before a fix: whether an `implements:`
outside a block is counted by one reader and not the other, and which answer
is right. Measured 2026-10-08 on BWK awk at dd411a1, with probes kept out of
the tree:

| Probe | Where the `implements:` / `mitigates:` line sits | Exit | Reported |
|---|---|---|---|
| M1 | unit: column one in an expecting REQ's block | 1 | UNMET-EXPECTATION, "implements a risk control" |
| M2 | unit: after a `### Rationale` heading under that REQ | 0 | UNMET-EXPECTATION as a warning |
| M3 | unit: after a `**Note:**` line under that REQ | 0 | UNMET-EXPECTATION as a warning |
| S1 | single: before the first item of the SRS | 0 | nothing; RC-002 implemented by no REQ |
| S2 | single: under a heading after the last REQ | 0 | nothing |
| S3 | single: mid-sentence prose under a heading | 0 | nothing |
| R1 | single: `mitigates: HAZ-002` in RMF prose, no RC | 0 | nothing; HAZ-002 mitigated by no RC |

The item said the consequence "is not a false green in the default
configuration". S1 to S3 and R1 refute that: the line-wise reader is the
false green, in every configuration. The block reader is the right answer,
which is the rule every other ledger annotation already follows (`status:`,
`satisfies:`, `traces:`, `retired:`), and which D3 of the out-of-force change
already applied to `implements:` inside an out-of-force block.

Ruled 2026-10-08 by the maintainer, on being told that D4 turns some
passing trees red: "I prefer a stricter fix".

## Decisions

**D1. A credit belongs to the block it is written in.** `implements: RC-…`
credits the RC only on a line inside a REQ block in `doc_srs`; `mitigates:
HAZ-…` credits the HAZ only on a line inside an RC block in `doc_rmf`. The
keyword may sit anywhere on that line (the inline `(implements: RC-…)` on the
definition line is the shipped form). A line in no block credits nothing,
wherever the keyword sits on it. Blocks open and close by
`GR_AWK_ITEM_BLOCK`, unchanged; a block cannot span files.

**D2. One reader per keyword.** Each keyword is read by one block pass, and
every consumer reads its records. For `implements:`: UNIMPLEMENTED-CONTROL
(credit from an in-force REQ, as D3 of the out-of-force change requires) and
the unit-mode UNMET-EXPECTATION severity (the expecting REQ's own block).
`gr_req_scan` stops reading `implements:` (its `RC` kind is removed). The
`ids_matching` reads of both keywords are removed. The pass reads the files
`git grep` reads: a file git ignores is dropped, by the rule `oof_scan`
already applies, factored out so both passes share it. The crediting owner
must be an item `ids_defined` reports, so an owner defined nowhere a gate
reads (behind a BOM, or only in a file `git grep -I` skips as binary)
credits nothing. A binary file that redefines an owner also defined in a
text file is not covered (see the follow-ups).

**D3. A stray column-one line is reported.** ORPHAN-ANNOTATION covers
`implements:` in `doc_srs`, opening on REQ, and `mitigates:` in `doc_rmf`,
opening on RC, under the backstop's existing column-one-after-list-markers
rule, so the author is told which line to move. Mid-line prose outside a
block is not reported (the backstop's rule is column one); it credits
nothing, and the coverage gate it would have satisfied reports. Front matter
is skipped by the backstop and by the reader, by the one rule
`GR_AWK_FRONT_MATTER`, so a front-matter line credits nothing, a definition
line included, and the coverage gate reports.

**D4. Trees that passed may go red, and the upgrade note says so.** An
`implements:` or `mitigates:` under a sub-heading or a bold-colon line inside
an item, before the first item, after a heading that closed the last one, or
in front matter no longer credits. The fix is to move the line into the
item's block. `skills/ratchet/references/upgrade-notes.md` gets the entry.

**D5. The documents say where the line goes.** `templates/srs.md`,
`templates/rmf.md`, the `check-traceability` catalogue rows for
UNIMPLEMENTED-CONTROL, UNMITIGATED-HAZARD and ORPHAN-ANNOTATION, and the
`check-trace.sh` header roster state that the line is read inside the item's
block. The orphan-scan comment in `check-trace.sh` that rules these keywords
"cannot be orphaned" is rewritten.

## Tasks

### T1 — `check-trace.sh` and `lib.sh` read each keyword once, by block

**Files touched:** `scripts/check-trace.sh`, `scripts/lib.sh`,
`tests/check-trace.bats`, `tests/lib.bats`, `tests/units-chain.bats` if a
fixture needs moving.
**Parallel:** yes, with T2 (disjoint files).

Implement D1 to D3 and the script half of D5. Factor the ignored-file filter
out of `oof_scan`; one block pass yields `<owner> <ID>` records per keyword;
`oof_scan` stops emitting `I` records. Keep awk statuses (no `awk | sort`
pipeline that hides one), never pass a newline-bearing value to `awk -v`,
open `case` patterns with `(`. Existing tests that relied on a credit outside
a block are moved into the block in the same commit, with a note in the
dispatch report naming each.

Tests, each written first and watched failing for the right reason, each
annotated `# verifies: D<n> (docs/plans/2026-10-08-block-attributed-credits.md)`:

1. `implements:` before the first item of the SRS: UNIMPLEMENTED-CONTROL and
   ORPHAN-ANNOTATION with file and line (D1, D3);
2. `implements:` under a heading after the last REQ: the same (D1, D3);
3. `implements:` in mid-sentence prose under a heading: UNIMPLEMENTED-CONTROL,
   no ORPHAN-ANNOTATION (D1, D3);
4. `implements:` under a sub-heading inside a REQ: UNIMPLEMENTED-CONTROL and
   ORPHAN-ANNOTATION (D1, D3);
5. `mitigates:` in RMF prose with no RC: UNMITIGATED-HAZARD (D1);
6. `mitigates:` at column one under a heading after the last RC:
   UNMITIGATED-HAZARD and ORPHAN-ANNOTATION (D1, D3);
7. unit mode, an expecting REQ followed by `**Note:**` and then
   `implements:`: exit 1 with ORPHAN-ANNOTATION, and the UNMET-EXPECTATION
   line does not claim a risk control (D2, D3);
8. an `implements:` in front matter credits nothing (D3);
9. a REQ in a git-ignored SRS file credits no RC, and an RC in a git-ignored
   RMF file mitigates no HAZ (D2);
10. scope control, may be green first (record it as such, not attested): the
    inline definition-line `(implements: RC-…)` and an RC's inline
    `mitigates: HAZ-…` still credit, and a bulleted `- implements:` inside a
    block still credits.

`tests/lib.bats`'s "gr_req_scan reports … RC linkage" test drops its RC
assertion, renamed to say what it now asserts.

### T2 — the documents say where the line goes

**Files touched:** `templates/srs.md`, `templates/rmf.md`,
`skills/check-traceability/SKILL.md` (or its references, whichever holds the
catalogue rows), `skills/ratchet/references/upgrade-notes.md`.
**Parallel:** yes, with T1.

D4 and the document half of D5. Keep every SKILL.md inside 2,000 words and
its section order. No test: prose only, and `tests/skills.bats` gates the
form.

## Follow-ups outside this change

- `verifies:` stays line-wise: it is read from test files, which have no
  item blocks.
- `assesses:` is not changed; the comment at its scan states why it is not an
  orphan-checked keyword, and this change does not revisit that.
- Binary ledger files (review round 1). A `doc_srs` or `doc_rmf` file that
  `git grep -I` skips as binary still credits through `credit_scan` when the
  block's owner is also defined in a text file: a binary SRS file that
  redefines REQ-001 with `implements: RC-002` credits RC-002. The
  defined-owner filter guards only an owner defined nowhere a gate reads.
  Separately, `ids_defined` runs `git grep -oE` without `-I` and prints a
  junk `MISSING-TEST Binary file … matches` line for such a file.
- Front-matter definition lines in `oof_scan` (review round 1). `oof_scan`
  does not skip front matter, so a `**REQ-…**:` line inside front matter
  opens a block, and a `retired:` under it retires that REQ: an untested REQ
  defined again below the front matter exits 0. `credit_scan` skips front
  matter; `oof_scan` should too, by `GR_AWK_FRONT_MATTER`.
