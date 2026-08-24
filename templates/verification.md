# Verification — <slug> (<date>)

One record per change, written at `merge-change` step 6b and checked at step 6c
by `.guardrails/scripts/check-review.sh`. The squash commit references it on
its `Verified:` line, so this file is the evidence that travels with the change.

branch: <the change branch this record covers>
reviewer: <who performed the independent review at step 6a>
verdict: <what the review concluded>
reproduced: <was the defect reproduced before the fix, and how — or why not>

Change: <one sentence>. Branched from `<base>` at `<commit>`.
Plan: `docs/plans/<plan file>`.

## The gate

Every figure derived from the tree under test, not carried forward.

| Gate | Result |
| --- | --- |
| `<verify_commands entry>` | |
| `check-ids.sh` | |
| `check-trace.sh` | |
| Coverage, against the class target | |
| Working tree | |

## What was wrong, and what was built

<the defect, measured; then the change. A record that only says the tests pass
records that the tests pass.>

## Review

One block per finding the reviewer raised, in the toolkit item shape, each with
its disposition. A review that raised nothing is legal — `verdict:` above is
what says so.

**finding-1**: <what the reviewer found, in their terms>
disposition: <what changed, and the test that reddens without it>

## Gaps

<what this change did NOT establish. A gap stated here is a gap; a gap left out
is a claim.>

<!--
Field grammar (surfaced by .guardrails/scripts/check-review.sh):

  branch:      the selector. A record declaring no branch belongs to no change
               and is reported as MISSING-RECORD for the change that expected
               it. Whole-value equality: `branch: my-change-2` does not answer
               for `my-change`.
  reviewer:    required. Catches a review that was never dispatched. The gate
               does not judge independence — with agent reviewers the string is
               whatever the author types — so independence is the author's
               discipline and step 6a is where it is exercised.
  verdict:     required. A review that raised nothing must still say so, or
               silence is indistinguishable from absence.
  reproduced:  required, and the VALUE IS NEVER JUDGED. `reproduced: no — the
               root cause was measured directly, the end-to-end failure never
               reproduced` is a passing record. The field exists so that the
               absence of evidence is a visible omission rather than an
               optional act of honesty.

- All four are plain annotations at COLUMN ONE, the same form as `status:` and
  `verifies:` elsewhere in the toolkit. Indented, they do not count. In YAML
  front matter, they do not count either — a header key is a title-page field,
  not a claim about the review.
- A field with no value after it is an omission, not compliance.
- A finding is `**finding-N**:` at column one, N digits, and its `disposition:`
  is a plain annotation inside its block. A heading or any bold line carrying a
  colon ends the block, which is why `disposition:` is not written in bold: it
  would close the very finding it belongs to. A label the rule cannot read is
  reported as MALFORMED-FINDING rather than passed over, because it opens no
  block and its disposition would be credited to nothing.
- Only the record for the change under merge is checked. Records written before
  this schema existed are left alone.
- The placeholders above are in angle brackets and the illustrative forms are
  described rather than written flush left, for the reason the other templates
  give: a gate reads column one whatever the surrounding prose says, and no
  gate in this toolkit parses fenced code blocks.
-->
