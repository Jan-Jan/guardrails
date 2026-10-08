# The review severities and the documentation and test checklists

Read this at `merge-change` step 6a, and hand it to the reviewer with the diff
every round. The severities apply to every review; the documentation
checklist applies when the diff touches documentation, and the test
checklist when it touches tests.

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
- Anything reworded or replaced is superseded, and anything dropped is
  retired, never deleted: the old item keeps its place and gains
  `superseded-by: <new ID>` (the new item contains `supersedes: <old ID>`), or
  `retired: YYYY-MM-DD — <reason>`. A requirement that disappeared is a
  finding.
- The successor has its own test with a `red -> green:` attestation. The new
  ID was not added to the old item's green test; a test pointed from the old
  item to the successor is listed as `inherited: <test name> — from <old ID>`
  in the record. An inherited test is reviewed as an edited test under the
  test checklist, and the reviewer confirms it verifies the successor's
  behavior, since it carries no red-first evidence and no gate reads
  `inherited:`.
- Every other site that names the superseded ID. The trace gate enforces the
  supersession pair (`NON-RECIPROCAL-SUPERSESSION`, `MALFORMED-SUPERSESSION`)
  and only the pair. An `affects:`, `traces:` or table row may name an old ID
  as history, so that sweep stays a review job.
- The plans `merge-change` step 1 pruned: each pointer stands where the
  task's code was, the prose of each task matches the diff, and a plan left
  whole is listed in the record. After pruning, the prose is the plan's only
  account of the code.

## The test checklist

The reviewer checks each new or edited test against the floor, which no
guidelines file changes, and raises a finding for each one that fails. The
project's guidelines file states where a test attaches and which doubles it
may use, and `review-guidelines` checked those rules before this step.
That each new test was watched red is `verify-before-merge` check 4's, from
the `red -> green:` lines.

- It carries a `verifies:` annotation naming the lowest requirement level
  that exists.
- It fails when the behavior it verifies breaks: an assertion only that a
  double was called meets this only where the call is the requirement.
- At class B and C, every REQ and LLR has abnormal-input tests as well as
  normal-case tests: bad input, boundary values, resource exhaustion,
  dependency failure.
- At class C, every SDD item the change touches is tested at its own
  interface, not only end-to-end.
- Once for the change: the plan lists a guideline review for each file
  `guidelines-file.sh TEST` prints for the diff, every finding with a
  disposition, and so does the record's `## Guideline reviews` where the
  record exists.
