# The documentation review checklist

Read this at `merge-change` step 6a when the diff touches documentation, and
hand it to the reviewer with the diff. The reviewer checks each item and
raises a finding for each one that fails.

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
