# Close PR-crcee5 Implementation Plan

**Goal:** Record `PR-crcee5` as resolved by `47a8b1d` in the file that defines
it, and give the second, unfixed defect recorded inside it an ID of its own so
closing the first does not discard the second.
**Implements:** no REQ/RC/SDD/LLR — guardrails keeps no ledger of its own yet
(`docs/problems/2026-08-27-macos-awk.md`). The change is ledger maintenance
under `resolve-problem` §4.
**Safety class:** not configured — the repository does not self-host
`.guardrails/config.yaml`, so `check-ids.sh`, `check-trace.sh`,
`check-review.sh` and `finalize-docs.sh` all exit 2 — inapplicable, and are
reported as such rather than as passes.
**Verification:** `tests/run-tests.sh` (all bats), plus
`tests/mutate.sh docs/verification/*.mutations` as the direct evidence that the
symptom `PR-crcee5` states is now false.

## Why this is a change and not an edit

`skills/resolve-problem/SKILL.md` §4 and `docs/problems/README.md` both require
`status: resolved` only in the change that merges the fix; `merge-change` states
the rule nowhere. `47a8b1d` merged the fix and did not edit the item.
The flip therefore happens in a change that contains no fix, which is a
departure from the rule and is stated as one in the item and in the
verification record rather than left for a reader to notice.

The second defect inside `PR-crcee5` — five live mutation scripts rewrite their
target through `t` in the working directory, joined with `&&` — was recorded
without an ID on the stated expectation that the change repairing the anchors
would touch the same files. It did not. Resolving `PR-crcee5` with that
paragraph still inside it would close a defect that is open, so the paragraph
becomes an item.

## T1 — resolve PR-crcee5 in the file that defines it

**Files touched:** docs/problems/2026-09-15-class-b-report.md
**Parallel:** no (serial, T1 first — T2 references the ID minted here)

1. `status: open` -> `status: resolved` inside the `PR-crcee5` block only.
   `opened: 2026-09-10` remains: it records when the problem was raised.
2. Append the resolution: the fix commit, how the measured population of 46
   differs from the item's 38 and why (exit codes against a tree checksum), the
   29/17 disposition, and the two gates that make the second half of the
   symptom — "nothing reports it" — false.
3. Append the lateness of the flip as its own paragraph. No gate can connect a
   change to the problem it closes, so the omission at `47a8b1d` was reported
   by nobody; the record is the only place it exists.
4. Append to the second defect's paragraph that it is not resolved here, and
   name the ID T2 mints.
5. Append the resolution to the ledger header's bullet for `PR-crcee5`. Do NOT
   re-tense it: every resolved item in this ledger keeps its symptom in the
   present tense, because the symptom records what was observed. The pointer to
   `47a8b1d` is what stops the figure of 38 reading as current, and it is the
   same device the item itself uses.

Expected: `grep -c '^status: open' docs/problems/2026-09-15-class-b-report.md`
falls by one.

## T2 — mint the second defect as its own item

**Files touched:** this change's draft ledger file, renamed at merge to
docs/problems/2026-09-28-mutation-temp-file.md
**Parallel:** no (serial, after T1)

1. Mint the ID: `new-id.sh PR`. The repository has no config, so the script
   exits 2 unaided; run it with `GR_CONFIG` pointing at a minimal config
   outside the tree (`id_prefixes: PR`, `doc_problems`, `strict_paths`). The
   token is drawn against this tree, so the collision check is the real one.
2. Write the item into this change's draft file, not into the file that defines
   `PR-crcee5`: it is a new item, and new items go into the change's own draft
   file (`worktree-discipline`).
3. State the current measurement, not the 2026-09-10 one: 16 scripts contain
   the idiom, 5 of them still apply and 11 are retired and executed by nothing.
4. State what is **not** exposed: `tests/mutate.sh` applies every mutation with
   the working directory set to a scratch tree, so the gate path leaks nothing
   into the repository. Overstating the blast radius would be as wrong as
   omitting the item.

Expected: `tests/mutate.sh` is unaffected — no mutation script is edited by
this change.

## T3 — reproduce the second defect before recording it as open

**Files touched:** none in the repository (scratch only)
**Parallel:** no (serial, before T2's step 3)

Build a two-line target and a stub awk that exits 2, then run the idiom:

*(Code pruned at merge: 1 line. Files touched: none in the repository (scratch only).)*

Expected: exit 2, `t` present in the working directory, target unmodified.
That is the whole defect: the redirect creates `t` before awk runs, and `&&`
short-circuits the `mv` that would have removed it.

## Self-review

1. No ID is claimed under **Implements:**, and none is needed — the change
   implements no requirement and says so.
2. Every task states its files, and no two name the same file.
3. The one measurement this change asserts as current — that the symptom of
   `PR-crcee5` is false — is derived from a run of `tests/mutate.sh` on the
   tree under test, and recorded in the verification record's gate table.
