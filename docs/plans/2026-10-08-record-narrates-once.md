# Phase 3: a verification record does not count itself, and narrates once

**Roadmap:** `docs/plans/2026-10-06-salvage-churn-and-parallel.md`, phase 3
(D9, D10).
**Resolves, opens:** no problem items. T2 amends `PR-kc2pzm`, which stays
open. Each test cites the decision it verifies,
`verifies: D<N> (docs/plans/2026-10-06-salvage-churn-and-parallel.md)`.
**Base:** `main` at `2a59e0e`. Baseline: phase 2's gate, 1107 of 1107 on
`a34be51`; `main` differs from that tree only by
`docs/verification/2026-10-07-parallel-changes.md`.

## D10's condition, measured

D10 makes P8 and P9 wait on D7's measurement: under about five minutes for a
full suite run, `PR-kc2pzm` gains a note that a cheaper `record` lane no longer
pays for itself; otherwise P8 and P9 are added to it as candidate
formulations. `docs/verification/2026-10-07-test-runner.md` measured the
default parallel run at 650 s on a 12-CPU host (gate table, first row), and
phase 2's gate took about 1200 s. Both are over five minutes, so T2 takes the
second branch.

## Tasks

| Task | Files touched | Depends on |
|---|---|---|
| T1 — the template states the count rule and the narrate-once rule | `templates/verification.md`, `tests/skills.bats` | — |
| T2 — `PR-kc2pzm` gains P8 and P9 as candidate formulations | `docs/problems/2026-09-15-field-report-two.md`, `tests/skills.bats` | T1 |

Both touch `tests/skills.bats`, so they run in sequence.

### T1 — the template states the count rule and the narrate-once rule (D9)

**Files touched:** `templates/verification.md`, `tests/skills.bats`
**Parallel:** no

1. Add to `tests/skills.bats`, beside the other "verification template" tests,
   and watch it fail on the current tree:

   ```bash
   @test "verification template: a record does not count itself, and narrates once" {
       # verifies: D9 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
       # A count of a record's own rounds or findings, written in that record,
       # is falsified by the next commit that adds a finding block, the commit
       # that writes the count included (G1 of the churn proposal). Prose
       # rewritten each round restates earlier rounds and draws findings of its
       # own (P12 of the parallel-session proposals).
       template="$BATS_TEST_DIRNAME/../templates/verification.md"
       text=$(tr '\n' ' ' < "$template" | tr -s ' ')
       printf '%s\n' "$text" | grep -qF 'The `### Round <N>` headings and the `**finding-` blocks are the count'
       printf '%s\n' "$text" | grep -qF 'State no number of rounds, findings or dispositions in prose'
       printf '%s\n' "$text" | grep -qF 'Write this section and the Gaps once, after the final round'
       printf '%s\n' "$text" | grep -qF 'with no round-by-round account'
   }
   ```

2. In `templates/verification.md`, `## Review`: after the paragraph ending
   "`verdict:` above states that.", add:

   > Put each review round's blocks under its own `### Round <N>` heading.
   > The `### Round <N>` headings and the `**finding-` blocks are the count.
   > State no number of rounds, findings or dispositions in prose, here or
   > elsewhere in this record: the next commit that adds a finding block
   > falsifies it, the commit that writes it included.

   The heading and the block opener are shown inline in backticks, and the
   paragraph is wrapped so that no line opens with `### Round` or
   `**finding-`: a gate reads column one, as the field-grammar block says.

3. In `## What was wrong, and what was built`, replace the placeholder with:

   > <the defect, measured; then the change. A record that only states that the
   > tests pass records nothing about the defect.>
   >
   > Write this section and the Gaps once, after the final round, as the change
   > stands at merge, with no round-by-round account. The finding blocks are the
   > round history; prose rewritten each round restates them, goes stale
   > against them, and draws findings of its own.

4. Run `tests/.bats-core/bin/bats tests/skills.bats`: all green, the new test
   included. Commit unsigned.

**Done** (`27212c4`, merged `05e09d2`). tests/skills.bats 109 of 109.
red -> green: "verification template: a record does not count itself, and narrates once" — failed at its first assertion before the template edit: the flattened template had no 'The `### Round <N>` headings and the `**finding-` blocks are the count'

### T2 — `PR-kc2pzm` gains P8 and P9 as candidate formulations (D10)

**Files touched:** `docs/problems/2026-09-15-field-report-two.md`,
`tests/skills.bats`
**Parallel:** no (serial, after T1)

1. Add to `tests/skills.bats` and watch it fail on the current tree:

   ```bash
   @test "PR-kc2pzm carries P8 and P9 as candidates, with P9's defect" {
       # verifies: D10 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
       # A parallel suite run measured 650 s, over D10's five minutes, so the
       # cheaper record lane still pays for itself and both proposals are kept
       # on the item that owns the question, rather than lost with the branch
       # that carried them.
       ledger="$BATS_TEST_DIRNAME/../docs/problems/2026-09-15-field-report-two.md"
       item=$(awk '/^\*\*PR-kc2pzm\*\*:/ { inside = 1; print; next }
                   inside && /^\*\*[A-Z]+-[a-z0-9]+\*\*:/ { exit }
                   inside' "$ledger" | tr '\n' ' ' | tr -s ' ')
       [ -n "$item" ]
       printf '%s\n' "$item" | grep -q '^\*\*PR-kc2pzm\*\*:'
       printf '%s\n' "$item" | grep -qF 'Candidate formulations, neither adopted'
       printf '%s\n' "$item" | grep -qF '**P8, per gate, by running the gates.**'
       printf '%s\n' "$item" | grep -qF '**P9, the reviewer'"'"'s run scoped to the round'"'"'s delta.**'
       printf '%s\n' "$item" | grep -qF 'is empty under that pathspec and can still turn the suite red'
       printf '%s\n' "$item" | grep -q '^.*status: open'
   }
   ```

2. In `docs/problems/2026-09-15-field-report-two.md`, append to the body of
   `PR-kc2pzm`, after its closing paragraph ("…which is why it is an item
   rather than a sixth attempt."), and before the next item:

   > **Candidate formulations, neither adopted.** Added 2026-10-08 under D10 of
   > `docs/plans/2026-10-06-salvage-churn-and-parallel.md`: a parallel suite
   > run measured 650 s (`docs/verification/2026-10-07-test-runner.md`), over
   > the five minutes below which a cheaper `record` lane would not pay for
   > itself. Since this item was opened, step 6a dispatches no further reviewer
   > after the first round with nothing above `low`, so what a later `record`
   > finding still costs is the rerun from step 1, the suite included. Both
   > candidates come from the parallel-session proposals of 2026-09-18, which
   > never merged.
   >
   > * **P8, per gate, by running the gates.** After that converging round, a
   >   `record` disposition is checked by `check-ids.sh`, `check-trace.sh`,
   >   `check-review.sh` and `tests/skills.bats`, about a minute, with no suite
   >   run; a `code` or `requirement` finding still reruns from step 1. It
   >   answers the question the paragraph above names, per gate, and is
   >   untried.
   > * **P9, the reviewer's run scoped to the round's delta.** Step 6a lets
   >   only a documentation-only diff stand on the step 6 gate summary. P9
   >   extends that from the diff to the round's delta: when
   >   `git diff --name-only <last reviewed commit> HEAD -- scripts tests` is
   >   empty, the reviewer rests on the tree-named gate summary. Its known
   >   defect: a delta confined to `README.md`, `AGENTS.md`, `skills/` or
   >   `templates/` is empty under that pathspec and can still turn the suite
   >   red, as round 5 above showed with a `README.md`-only edit reddening
   >   `tests/skills.bats`.

   The item keeps `status: open`, and no other line of it changes.

3. Run `tests/.bats-core/bin/bats tests/skills.bats`, then
   `sh scripts/check-ids.sh` and `sh scripts/check-trace.sh` on a scratch copy
   as phase 2 did: the new test green, and no finding the base does not
   already have. Commit unsigned.

**Done** (`5d9e279`). tests/skills.bats 110 of 110.
red -> green: "PR-kc2pzm carries P8 and P9 as candidates, with P9's defect" — the extraction found the item, then failed at `grep -qF 'Candidate formulations, neither adopted'` before the ledger edit

## Self-review

1. D9 has T1's test; D10 has T2's test.
2. Each step names its exact text and its command.
3. The test names cite the decisions by the roadmap's numbering.
4. Both tasks state their files; neither is parallel.
