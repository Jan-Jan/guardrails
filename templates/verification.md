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

Every figure below is measured on one tree, and the table names it, so a later
reader can re-measure the same tree instead of guessing which round produced
these numbers. **No figure here is copied forward from an earlier round.**
Naming the tree does not soften that rule, it is what makes breaking it
visible: a number reproduced from a previous round's record describes whichever
tree that round measured, so under the name above it the table would claim a
measurement nobody made.

Measured on: `<commit>` — `git rev-parse HEAD` — tree `<tree hash>`, from
`git rev-parse HEAD^{tree}` on a clean worktree. Where `merge-change` step 3
renamed nothing, this is the tree step 2 measured and the step 2 gate summary
is what the rows below report.

A figure that describes the repository rather than this change does not belong
in this table at all, freshly measured or not: the open-problem count, the
roll-call total, the age of the oldest item. Each is true of one instant of a
ledger every other change edits, and a record outlives that instant. The
`check-trace.sh` row takes the exit status, plus which of **this change's own**
IDs entered or left the roll-call.

| Gate | Result |
| --- | --- |
| `<verify_commands entry>` | |
| `check-ids.sh` | |
| `check-trace.sh` | |
| Coverage, against the class target | |
| Working tree | |

## Red → green

One row per ID this change **Implements**, copied from the `red -> green:`
lines of the dispatch reports. The subagent running the loop is the only party
that saw the test fail, and the conversation it reported in does not outlive the
merge — so this table is where that observation becomes durable evidence.

| Item | Test | Watched red |
| --- | --- | --- |
| `<ID this change implements>` | `<the test that verifies it>` | <watched failing for the right reason before the implementation existed> |

## What was wrong, and what was built

<the defect, measured; then the change. A record that only states that the
tests pass records nothing about the defect.>

Write this section and the Gaps once, after the final round, as the change
stands at merge, with no round-by-round account. The finding blocks are the
round history; prose rewritten each round restates them, goes stale against
them, and draws findings of its own.

## Review

One block per finding the reviewer raised, in the toolkit item shape, each with
its disposition. A review that raised nothing is legal, and `verdict:` above
states that.

Put each review round's blocks under its own `### Round <N>` heading. The
`### Round <N>` headings and the `**finding-` blocks are the count. State no
number of rounds, findings or dispositions in prose, here or elsewhere in this
record: the next commit that adds a finding block falsifies it, the commit that
writes it included.

Where a `shared:` line at `merge-change` step 1 sent the change to a fresh
reviewer, name the shared files and that review round here.

### Round 1

**finding-1**: <code | requirement>, <high | medium | low> — <what the
reviewer found, in their terms>
disposition: <what changed, and the test that reddens without it; or, for a
finding recorded as an open problem item (`merge-change` step 6a), that item's
ID, `PR-…`>

**finding-2**: record — <what the reviewer found in the record; a `record`
finding states no severity>
disposition: <what changed in the record>

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
- A finding's value OPENS with its tag — `code`, `requirement` or `record`
  (`merge-change` step 6a). A `code` or `requirement` tag is followed by its
  severity, `high`, `medium` or `low`; a `record` finding states none.
  check-review.sh never reads the value, so the tag and the severity cost no
  field and add no malformed case. They exist for the convergence rule at
  `merge-change` step 6a: a round whose `code` and `requirement` findings are
  all `low` is the last REVIEW round. The tag does not shorten the sequence —
  every finding reruns from step 1, whatever its tag — it decides only whether
  another reviewer is dispatched.
- A finding is `**finding-N**:` at column one, N digits, and its `disposition:`
  is a plain annotation inside its block. A heading or any bold line containing a
  colon ends the block, which is why `disposition:` is not written in bold: it
  would close the very finding it belongs to. A label the rule cannot read is
  reported as MALFORMED-FINDING rather than passed over, because it opens no
  block and its disposition would be credited to nothing.
  A range opens no block either — a header naming `finding-2..4` is one such
  unreadable label, however many findings it means to cover. Each finding
  gets its own header, one N apiece.
- The red → green table is evidence, not a field: check-review.sh does not parse
  it, and it is shaped so that it cannot be read as one. Every row starts at
  `|`, so no cell occupies column one where a gate would read it as an
  annotation, and no cell opens or closes a finding block. It is an attestation
  — it records an observation only the task subagent made, and no later party
  can re-observe a test failing once it passes — so nothing downstream
  re-verifies what these rows state, and enforcing them would need a fifth
  required field and a change to the script. What IS independently checkable is
  the same property from the other side, and step 6a already asks it: do the
  tests verify what their `verifies:` annotations claim, and would they fail if
  the behavior broke? A test that could never have gone red is caught by that
  question whatever this table states.
- Only the record for the change under merge is checked. Records written before
  this schema existed are left alone.
- The placeholders above are in angle brackets and the illustrative forms are
  described rather than written flush left, for the reason the other templates
  give: a gate reads column one whatever the surrounding prose states, and no
  gate in this toolkit parses fenced code blocks. A list marker is no escape
  from that, and for `disposition:` it is the opposite of one. The ORPHAN
  backstop steps over leading list markers — bullets and ordered markers
  alike — so `- disposition: …` written outside every finding block is
  reported ORPHAN-DISPOSITION, while inside a block it is still not the
  finding's disposition and the finding stays UNDISPOSED-FINDING. Illustrate
  the form inline in backticks, indented with no marker, or not at all.
-->
