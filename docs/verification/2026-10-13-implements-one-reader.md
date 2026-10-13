# Verification — implements-one-reader (2026-10-13)

branch: implements-one-reader
reviewer: independent Claude subagents with fresh context, given the diff, the plan, the problem items, AGENTS.md and the review checklist only (merge-change step 6a): round 1 at `649912b` (whole change), round 2 at `b8250c3` (the round 1 fixes), round 3 at `f6f6a98` (whole change again, after the base merge from `1967dc8` shared `skills/ratchet/references/upgrade-notes.md`, `tests/check-ids.bats` and `tests/lib.bats`)
verdict: converged at round 3: D1 to D5 met; no round raised a code or requirement finding above low, and every round 3 finding was fixed mechanically, so no further reviewer was dispatched
reproduced: yes. Before any code changed, probes on `dd411a1` showed a control implemented by an `implements:` line belonging to no REQ (before the first item, under a heading after the last, in mid-sentence prose) and a hazard mitigated by `mitigates:` prose belonging to no RC, each at exit 0 with nothing reported; and, under a unit manifest, an `implements:` after a heading or bold-colon line inside an expecting REQ dropped its unmet expectation from exit 1 to a warning. The plan's table records each probe

Change: `implements:` and `mitigates:` credit a control or hazard only from a line inside the claiming item's block, each read once; resolves PR-44ww7q and PR-z7w5bf, and records PR-8um9a9 open. Branched from `main` at `dd411a1`; base merged from local `main` at `1967dc8`, per AGENTS.md non-negotiable 4.
Plan: `docs/plans/2026-10-08-block-attributed-credits.md`.

## The gate

Measured on: `fe2d439` — `git rev-parse HEAD` — tree `9af06a7a835c7c1cb3586517a76217a1f0a88ba9`, clean worktree, `main` at `1967dc8`. Step 3 renamed the draft ledger file before this gate, so this is the tree that merges, apart from this record.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` (parallel) | 1..1296, 1296 ok, 0 not ok, 0 skipped, no other output, exit 0, 1982 s |
| `check-ids.sh` (scratch copies, base and change) | exit 1 on both, as on `main`; 69 lines each, identical once line numbers are stripped (the fixture findings in `tests/check-ids.bats` move down with the re-pin comments) |
| `check-trace.sh` (scratch copies, base and change, with placeholder SRS and SOUP and `strict_paths: scripts`) | exit 1 on both, as on `main`. `PR-44ww7q` leaves the open roll-call (resolved), `PR-z7w5bf` enters resolved, `PR-8um9a9` enters open. The other differences are two DANGLING-REF lines (HAZ-003, RC-003) from fixture IDs in the new tests in `tests/check-trace.bats`, the class of fixture line `main` already reports |
| `prune-plans.sh --base main --dry-run` | nothing to prune, exit 0 |
| Coverage | not configured |
| Working tree | clean |

The gate subagent's own base-and-change comparison built both copies from `main`, so the two rows above were re-measured by the author on fresh `git archive` copies of `main` and `fe2d439`; the suite figures are the subagent's, run in the change worktree. The repository has no `.guardrails/config.yaml`, so `check-ids.sh` and `check-trace.sh` ran on scratch copies built from `main` and from the change with `templates/config.yaml`; `finalize-docs.sh` could not run, and the draft ledger file was renamed by hand under its rule (`DRAFT-<branch>-<slug>` to `<date>-<slug>`); and `merge-preflight.sh` was not run, as in `docs/verification/2026-10-08-supersession-reannotation.md`. No plan was left whole.

## Red → green

The toolkit keeps no REQ ledger; the change implements the plan's decisions, so the items are D1 to D5. One row per test watched failing before its fix.

| Item | Test | Watched red |
| --- | --- | --- |
| D1, D3 | `check-trace: an implements: before the first item of the SRS credits nothing and is reported` | exit 0, nothing reported |
| D1, D3 | `check-trace: an implements: under a heading after the last REQ credits nothing and is reported` | exit 0, nothing reported |
| D1, D3 | `check-trace: an implements: mid-sentence in SRS prose credits nothing and is not an orphan` | exit 0, nothing reported |
| D1, D3 | `check-trace: an implements: under a sub-heading inside a REQ credits nothing and is reported` | exit 0, nothing reported |
| D1 | `check-trace: a mitigates: in RMF prose with no RC mitigates nothing` | exit 0, nothing reported |
| D1, D3 | `check-trace: a column-one mitigates: under a heading after the last RC mitigates nothing and is reported` | exit 0, nothing reported |
| D2, D3 | `check-trace: an expecting REQ's implements: after a bold-colon line is reported and claims no risk control` | exit 0, only `UNMET-EXPECTATION platform/hal: REQ-e7x2m4 (open 3 days)` |
| D3 | `check-trace: an implements: key line in front matter credits nothing and is not an orphan` (renamed at round 3) | exit 0 |
| D3 | `check-trace: a definition line in front matter opens no block and credits nothing` | exit 0, RC-002 credited |

Reddened by a mutant instead of watched red first:
`check-trace: a block in a gitignored ledger file credits no control and mitigates no hazard`
(D2; green against `main`, whose line-wise reader skipped ignored files
through `git grep`, and red against a `credit_scan` without
`unignored_files`); the two defined-owner tests,
`check-trace: an implements: in the block of a REQ ids_defined does not report credits nothing`
and `check-trace: a mitigates: in the block of an RC ids_defined does not report mitigates nothing`
(D2; each red only when its keyword's owner filter is removed); and, at
round 3, `check-trace: a block open at the end of one SRS file credits nothing in the next`
(D1; red with the per-file `cur = ""` reset removed),
`check-trace: front matter in one SRS file skips no lines of the next`
(D3; red with the per-file `gr_fm_reset()` removed: `UNIMPLEMENTED-CONTROL RC-002`)
and `check-trace: an expecting REQ's implements: in a gitignored requirements file claims no risk control`
(D2; red with `unignored_files` removed from `credit_scan`: the expectation
read "implements a risk control"). Each of the three round 3 mutants reddened
only its own test.

`check-trace: inline and bulleted credits inside a block still credit` (D1)
is scope control, green before and after by design.

## What was wrong, and what was built

`check-trace.sh` read `implements:` and `mitigates:` line-wise over the SRS
and the RMF, from anywhere on any line, attributed to no item. A control
counted as implemented, and a hazard as mitigated, when the keyword appeared
in a line no REQ or RC owned: before the first item, under a heading after the
last, in front matter, or in a sentence of prose. ORPHAN-ANNOTATION did not
cover either keyword, because the script ruled that line-wise keywords
"cannot be orphaned". Under a unit manifest, `gr_req_scan` read `implements:`
a second way, by block, to decide whether an unmet expectation implements a
risk control; the two readers disagreed whenever the line sat after a heading
or bold-colon line inside the REQ, and the block reader's answer turned a
blocking expectation into a warning while the line-wise reader still credited
the control. PR-44ww7q had recorded the two readers and asked for this
measurement; it had also judged the consequence unit-only and not a false
green, which the measurement refuted.

Each keyword is now read once, by `credit_scan`: a line inside a block of the
owner's prefix (REQ in `doc_srs`, RC in `doc_rmf`), the keyword anywhere on
that line, blocks reset at every file, front matter skipped by
`GR_AWK_FRONT_MATTER`, git-ignored files dropped by `unignored_files`
(factored out of `oof_scan`). A credit counts only when its owner is a defined
item and, for `implements:`, in force. UNIMPLEMENTED-CONTROL,
UNMITIGATED-HAZARD and the unit-mode expectation severity read these records;
`gr_req_scan` no longer reads `implements:`, and both `ids_matching` reads
are gone. ORPHAN-ANNOTATION covers both keywords at column one. The
templates, `check-traceability`, its item-blocks reference and the upgrade
note say where the line goes. Trees that relied on a credit outside a block go
red, which the maintainer ruled on 2026-10-08: "I prefer a stricter fix".
The three shared-fragment pins in `tests/check-ids.bats` rose by one each
(ID body, item block, front matter): `credit_scan` composes the shared
fragments rather than copying them.

## Review

### Round 1

**finding-1**: code, low — the "owner must be a defined item" filter was unpinned for both keywords: a mutant removing either survived every related test.
disposition: two tests, an `implements:` and a `mitigates:` in the block of a BOM-prefixed owner `ids_defined` does not report, each reddened by its own mutant (70cf6f0).

**finding-2**: code, low — the `credit_scan` comment claimed the defined-owner filter stops a binary ledger file crediting; a binary file redefining an owner defined in a text file still credits.
disposition: the comment states what the filter guards, and the binary case and `ids_defined`'s missing `-I` are plan follow-ups (470ad92). Not fixed in this change.

**finding-3**: code, low — `credit_scan` did not skip front matter, so a definition line in front matter opened a block and credited, against the change's own documents.
disposition: `credit_scan` skips front matter by `GR_AWK_FRONT_MATTER`; test `check-trace: a definition line in front matter opens no block and credits nothing`, watched red (470ad92). The same gap in `oof_scan` is PR-8um9a9, recorded open.

**finding-4**: code, low — the gitignored-ledger test was never red against `main`, whose line-wise reader already skipped ignored files.
disposition: no change; this record lists it among the tests reddened by a mutant, not watched red.

**finding-5**: requirement, low — `item-blocks.md` said every annotation credits only inside its owner's block; `verifies:` and `assesses:` do not.
disposition: the sentence names the block-read keywords (470ad92). A wording fix.

**finding-6**: record — PR-44ww7q's body still said the defect was unit-only and not a false green.
disposition: a sentence after its resolution line says the measurement refuted both (470ad92).

**finding-7**: requirement, low — the upgrade note's unit-manifest bullet overstated when UNIMPLEMENTED-CONTROL appears and said the severity never changes.
disposition: the bullet states both exactly, including the one case that changes (470ad92). A wording fix.

### Round 2

**finding-1**: code, low — no test pinned the per-file front-matter reset in `credit_scan`.
disposition: test `check-trace: front matter in one SRS file skips no lines of the next`, reddened by removing the reset (cd4b480).

**finding-2**: record — an unwrapped line in `item-blocks.md`.
disposition: rewrapped (285a251).

### Round 3

**finding-1**: code, low — no test pinned the per-file block reset in `credit_scan`; under a mutant without it, a mid-sentence `implements:` at the top of a later SRS file was credited to the last REQ of the file before.
disposition: test `check-trace: a block open at the end of one SRS file credits nothing in the next`, reddened by removing the reset (cd4b480).

**finding-2**: code, low — the test then named `an implements: in front matter credits nothing` stays green when the reader's front-matter skip is removed: a YAML key line opens no block.
disposition: renamed `check-trace: an implements: key line in front matter credits nothing and is not an orphan`, with a comment saying it pins the backstop's skip and naming the test that pins the reader's (cd4b480).

**finding-3**: code, low — the expectation test stays green if the severity went back to `gr_req_scan`; the two cases where D2 changes the severity (an expecting REQ in a git-ignored SRS file, or outside `doc_srs`) had no test.
disposition: test `check-trace: an expecting REQ's implements: in a gitignored requirements file claims no risk control`, reddened by removing `unignored_files` from `credit_scan` (cd4b480). The outside-`doc_srs` case is not tested: a REQ there is MISPLACED-ITEM, so that run is red either way.

**finding-4**: record — a 122-character line in the reflowed `assesses:` comment in `check-trace.sh`.
disposition: rewrapped (285a251).

**finding-5**: requirement, low — `item-blocks.md` "List markers" and a `check-traceability` red-flag row say no reader takes a bulleted annotation, while a bulleted `implements:` or `mitigates:` inside a block credits, as `satisfies:` and `traces:` already did.
disposition: both passages name the column-one fields a bullet hides, and `item-blocks.md` says the ID-list keywords credit from a bulleted line inside the block (285a251). A wording fix.

The round 3 fixes were finished by the author after the fix subagent ended on a usage limit with its tests written and uncommitted; the author applied each mutant in a scratch copy and saw each test red under its own mutant only.

## Gaps

- Measured on BWK awk (`/usr/bin/awk` 20200816) only. gawk, mawk and busybox
  awk are not installed on this machine; AGENTS.md requires all four.
- A binary ledger file that redefines an owner already defined in a text file
  still credits through `credit_scan`, and `ids_defined` prints a junk
  `MISSING-TEST Binary file … matches` line for a binary ledger file. Both are
  plan follow-ups, not problem items.
- PR-8um9a9 is open: `oof_scan` does not skip front matter, so a `retired:`
  beside a definition line in front matter exempts the item from MISSING-TEST.
- A mid-sentence `implements:` or `mitigates:` outside every block is
  reported only by the coverage gate it fails to satisfy, never located by
  file and line; the backstop reads column one.
- The round 3 changes were not reviewed by a fresh reviewer: under the
  convergence rule a round with nothing above low is the last review round.
