# The review severities and the documentation checklist

Read this at `merge-change` step 6a, and hand it to the reviewer with the diff
every round. The severities apply to every review; the checklist applies when
the diff touches documentation.

## Severities

Every `code` and `requirement` finding states one severity after its tag:
`**finding-N**: code, medium — <text>`. A `record` finding states none.

- `high`: loses or silently discards work, makes a gate pass that should fail,
  or is a remedy that does damage when followed, in a state reached in normal
  use.
- `medium`: a wrong exit, message or remedy in normal use that misleads but
  loses nothing, or a stated requirement that is not met.
- `low`: needs a rare or contrived state, or the error printed alongside names
  the true cause, or a documentation gap where the tree is right.

A round whose `code` and `requirement` findings are all `low` is the last
review round (`merge-change` step 6a).

## The documentation checklist

The reviewer checks each item and raises a finding for each one that fails.

- New items are in this change's draft ledger file, and no definition moved
  to another file.
- IDs are minted tokens. An amendment edits the defining file in place.
- Item form: `**<ID>**: The software shall <single, testable behavior>`.
- `satisfies:` / `implements:` references resolve; derived items are marked.
- Terms match `docs/CONTEXT.md`.
- Anything removed or reworded is superseded, not deleted: the old item
  keeps its place and gains `superseded-by: <new ID>`, and the new item
  contains `supersedes: <old ID>`. A requirement that disappeared is a
  finding.
- The test that verified the superseded item names both IDs:
  `verifies: <old ID>, <new ID>`. `superseded-by:` exempts nothing from
  `MISSING-TEST`, so the dual annotation keeps it clean for both.
- Every other site that names the superseded ID. The trace gate enforces the
  supersession pair (`NON-RECIPROCAL-SUPERSESSION`, `MALFORMED-SUPERSESSION`)
  and only the pair. An `affects:`, `traces:` or table row may name an old ID
  as history, so that sweep stays a review job.
