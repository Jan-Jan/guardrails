# Verification — supersession-reannotation (2026-10-08)

branch: supersession-reannotation
reviewer: independent Claude subagents with fresh context, given the diff, the plan, PR-kzst5n, AGENTS.md and the review checklist only (merge-change step 6a): round 1 at `ae8e60e` (a first reviewer at that commit ended on an authentication error before reporting and raised nothing), round 2 at `6551181` and round 4 at `e8c9771` after base merges that shared files with the change, round 3 at `024fc37`
verdict: converged at round 4: D1 to D7 met, the round 4 reviewer's own suite run 1217 ok of 1217; every round 4 finding was low or a record finding and each was fixed mechanically, so no further reviewer was dispatched
reproduced: yes. `check-trace: a superseded REQ with a reciprocal pair owes no test` and `check-trace: a retired REQ owes no test` printed MISSING-TEST for the superseded and retired items on the unchanged script, which is the reporter's symptom: a superseded item still demanded a test, so a supersession forced either a re-annotated green test or a duplicate one

Change: a superseded or retired REQ or LLR is out of force and owes no test, so a supersession no longer forces a check-4 violation; resolves PR-kzst5n. Branched from `main` at `646fa1f`; base merged from local `main` at `e79b823`, per AGENTS.md non-negotiable 4.
Plan: `docs/plans/2026-10-08-out-of-force-items.md`.

## The gate

Measured on: `9ca6d3d` — `git rev-parse HEAD` — tree `5950f90609ab770b73f633dccc140c0b0063a6e1`, clean worktree, `main` at `e79b823`. Step 1 pruned nothing on this round and the ledger file was renamed earlier, so this is the tree that merges, apart from this record.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` (parallel) | 1..1223, 1223 ok, 0 not ok, no other output, exit 0, 1161 s |
| `check-ids.sh` (scratch copies, base and change) | exit 1 on both, as on `main`; 69 lines each; the only differences are nine existing fixture findings in `tests/check-ids.bats` moved four lines down by the re-pin comments |
| `check-trace.sh` (scratch copies, base and change, with placeholder SRS and SAD and `strict_paths: scripts`) | exit 1 on both, as on `main`. `PR-kzst5n` is counted and is not in the open roll-call: it entered resolved. The other differences are fixture IDs from the new tests in `tests/check-trace.bats`: eleven DANGLING-REF lines added, and REQ-w9hk3p moving from DANGLING-REF to MISPLACED-ITEM because a new fixture heredoc defines it at column one; the same class as the fixture lines `main` already reports |
| `prune-plans.sh --base main --dry-run` | nothing to prune, exit 0 |
| Coverage | not configured |
| Working tree | clean |

The repository has no `.guardrails/config.yaml`, so `check-ids.sh` and `check-trace.sh` ran on scratch copies built from `main` and from the change with `templates/config.yaml`; `finalize-docs.sh` could not run, and the draft ledger file was renamed by hand under its rule (`DRAFT-<branch>-<slug>` to `<date>-<slug>`); step 1 ran `sh scripts/prune-plans.sh --base main` from `scripts/`; and `merge-preflight.sh` was not run, as in `docs/verification/2026-10-08-prune-plans.md`. No plan was left whole.

## Red → green

The toolkit keeps no REQ ledger; the change implements the plan's decisions, so the items are D1 to D7. One row per test watched failing before its fix; the plan's Red -> green section carries the same lines, beside the round that produced them.

| Item | Test | Watched red |
| --- | --- | --- |
| D2 | `check-trace: a superseded REQ with a reciprocal pair owes no test` | MISSING-TEST REQ-w9hk3p printed |
| D2 | `check-trace: a superseded LLR with a reciprocal pair owes no test` | MISSING-TEST LLR-w9hk3p printed |
| D2, D5 | `check-trace: a retired REQ owes no test` | MISSING-TEST for REQ-w9hk3p and REQ-k2vt8n |
| D3 | `check-trace: a tested out-of-force LLR covers no REQ` | exit 0, no MISSING-TEST REQ-k2vt8n |
| D3 | `check-trace: an RC implemented only by an out-of-force REQ is unimplemented` | no UNIMPLEMENTED-CONTROL RC-r5jw4h |
| D4 | `check-trace: a verifies: line naming only a superseded item is reported with its file and line` | exit 0, no OUT-OF-FORCE-VERIFIES line |
| D5 | `check-trace: a retired: with no date, a bad date, a far date or no reason is malformed` | no MALFORMED-RETIREMENT, only MISSING-TEST lines |
| D5 | `check-trace: retired: beside superseded-by: in one block is malformed` | no MALFORMED-RETIREMENT |
| D5 | `check-trace: an orphaned retired: is reported` | exit 0, no ORPHAN-ANNOTATION |
| D1, D5 | `check-trace: a retired: in an SDD block retires nothing and is an orphan` | MISSING-TEST LLR-k2vt8n present, ORPHAN-ANNOTATION absent |
| D7 | `skills: no skill tells a superseded item's test to carry both IDs` | grep matched grill-requirements/SKILL.md:101 and :181, references/supersession.md:21, merge-change/references/review-checklist.md:38 |
| D1 | `check-trace: a retired: in a later ledger file's front matter retires nothing` | exit 0, no MISSING-TEST REQ-k2vt8n |
| D1 | `check-trace: a retired: opening a later ledger file belongs to no item` | ORPHAN-ANNOTATION printed but no MISSING-TEST REQ-k2vt8n |
| D1 | `check-trace: a superseded-by: in a later ledger file's front matter completes no pair` | exit 0, no NON-RECIPROCAL-SUPERSESSION |
| D3 | `check-trace: an out-of-force exported REQ meets no expectation` | the consumer printed MISSING-TEST REQ-e7x2m4 and no UNMET-EXPECTATION |
| D1 | `check-trace: an item that supersedes itself owes its test and is reported` | exit 0, no MISSING-TEST REQ-w9hk3p |
| D1 | `check-trace: two items superseding each other both owe their tests and are reported` | exit 0, no MISSING-TEST for either |
| D3 | `check-trace: a retired REQ and a gitignored requirements file do not implement a control between them` | exit 0, no UNIMPLEMENTED-CONTROL RC-r5jw4h |
| D5 | `check-trace: a retired item with a reciprocal superseded-by: stays in force` | MALFORMED-RETIREMENT printed but no MISSING-TEST REQ-w9hk3p |
| D6 | `prune: a fence holding only an inherited: line keeps its fence` | "pruned docs/plans/2026-01-01-x.md: 1 block, 1 line" |

Written after the code and reddened by a mutant instead of watched red first:
`skills: check 4 reads per ID and names an inherited test as coverage` (D6;
each statement mangled in turn, and again after the base merge moved one into
`develop-change/references/rationale.md`); the D5 retirement-form tests on the
date separator, first occurrence, the SRS/SAD dedupe and a bare separator;
`check-trace: an implements: in the architecture ledger does not keep a control implemented`
and `check-trace: an implements: in a gitignored requirements file implements nothing`
(D3); `check-trace: a valid retired: beside a one-sided superseded-by: exempts nothing`
(D5); `check-trace: an exported REQ superseded by a provider LLR meets no expectation`
(D3); `check-trace: a supersession cycle of tested items fails the run on its own`
and `check-trace: an item leading into a supersession cycle is reported with every ID sorted`
(D1). Each mutant and the failure it produced is in the plan.

Scope controls, green before the implementation and not attested:
`check-trace: a verifies: line naming a superseded item beside its successor is silent`,
`check-trace: a superseded-by: with no reciprocal supersedes: exempts nothing`,
`check-trace: a chain of supersessions ending in a tested item in force is silent`,
`check-trace: a supersession ending in a retired item is silent`,
`check-trace: an item superseded into both a terminating chain and a cycle is out of force`.

Error-path tests, carrying no `verifies:` line:
`check-trace: an unreadable architecture ledger fails the out-of-force scan`,
`check-trace: an unreadable risk ledger fails the orphan scan`,
`check-trace: a provider whose doc_srs does not exist fails the consumer's run`,
`check-trace: a provider whose doc_sad does not exist fails the consumer's run`,
and `check-trace: a config with no requirements or architecture ledger runs the out-of-force scan on nothing`,
the last watched red (exit 2, `fatal: no path specified`) before its fix.

The re-pins in `every gr_def_re call site is still a call site, and no copy joins them`
(`GR_ID_BODY` 9, `GR_AWK_ITEM_BLOCK` 7, `GR_AWK_CIVIL` 4) went red at each pin
in turn before the re-pin.

No test was inherited.

## What was wrong, and what was built

A class C adopter reported that two rules contradicted each other (PR-kzst5n).
`grill-requirements` told the author to add a superseding item's ID to the
test that verified the superseded one, because `MISSING-TEST` still demanded a
test for the superseded item. `verify-before-merge` check 4 fails a
`verifies:` test with no red-first attestation and forbids re-annotating a
test that was green from the start. So a meaning-changing supersession could
satisfy one rule only by breaking the other, or by writing a duplicate test to
carry an ID. The dual-ID rule rested on "no gate has to change", written
before PR-zt5c2v made the supersession pair checked. A retirement had no
recorded form.

The maintainer ruled that a superseded requirement should have no test.
`check-trace.sh` now block-parses the SRS and SAD, per file, for out-of-force
REQ and LLR items: retired with `retired: YYYY-MM-DD — <reason>`, or
superseded through a reciprocal pair whose chain ends in an item in force or
validly retired. A self-supersession or a cycle exempts nothing and is
`MALFORMED-SUPERSESSION`; a `retired:` beside `superseded-by:`, or a malformed
one, exempts nothing and is `MALFORMED-RETIREMENT`; an orphaned `retired:` in
the SRS or SAD is `ORPHAN-ANNOTATION`. An out-of-force item owes no test (D2)
and discharges nothing: a tested out-of-force LLR covers no REQ, an
`implements:` in an out-of-force REQ implements no control, and an
out-of-force exported REQ meets no other unit's `expects:` (D3). The block
pass reads the files `git grep` reads, so the two `implements:` readers
cannot each credit a control through a different line. A `verifies:` line
naming only out-of-force items fails as `OUT-OF-FORCE-VERIFIES` (D4). Check 4
reads per ID, and a pre-existing test of a predecessor pointed at its
successor is listed as `inherited:`, coverage and not red-first evidence
(D6); `prune-plans.sh` keeps a plan fence holding such a line, and
ADR-bh4xgr says so. The skills, the review checklist, the verification
template and the upgrade notes state the one rule, and the dual-ID
instruction is gone (D7).

The supersession scan also ends an item block at a file boundary now, so a
`superseded-by:` at the top of a later ledger file no longer answers for the
last item of the file before it; adopters can see NON-RECIPROCAL-SUPERSESSION
where that carry-over hid one.

## Review

### Round 1

**finding-1**: requirement, low — `skills/grill-requirements/references/supersession.md:15-16` and `skills/ratchet/references/upgrade-notes.md:287-288` define an out-of-force item as one whose block contains a column-one `superseded-by:` naming at least one item ID, or a column-one `retired:`. The script exempts only on a reciprocal pair and only on a well-formed `retired:`; `supersession.md` contradicts itself, and `upgrade-notes.md` never corrects it.
disposition: both texts state the reciprocal pair and the well-formed `retired:`, and that a one-sided `superseded-by:` or a malformed `retired:` exempts nothing (dd0316e). A wording fix; no test reddens without it.

**finding-2**: requirement, low — `supersession.md:73-74`, `upgrade-notes.md:309-310` and the plan's D5 say a `retired:` outside any REQ or LLR block is ORPHAN-ANNOTATION, but the backstop scans only the SRS and SAD files; a `retired:` in the RMF or the problems ledger is read by nothing and reported by nothing.
disposition: the reference files scope the wording to the SRS and SAD and say a `retired:` on an RC, HAZ or PR retires nothing and is not reported; D5 records the scope (dd0316e). A wording fix.

**finding-3**: code, low — four mutants of `scripts/check-trace.sh` survive every out-of-force test: the separator required after the `retired:` date, first occurrence wins, `implements:` read only in doc_srs, and the SRS/SAD dedupe.
disposition: four tests added (dd0316e), each reddened by its mutant; the plan names each mutant and its failure.

### Round 2

**finding-1**: code, medium — the out-of-force scan neither closes the open block at a file boundary nor skips front matter, so a `retired:` or `superseded-by:` in a later SRS or SAD file's front matter is attributed to the last item of the file before; an untested REQ goes green (main: MISSING-TEST, exit 1; change: exit 0). The supersession scan carries the same block over.
disposition: both scans reset the block at the first line of each file (7adbc75); three tests, each watched red. Front matter is not skipped: after the reset no front-matter line reaches a block, and a skip would drop a front-matter `implements:` from the block pass while the line-wise reader still counts it. The reason is in a comment beside the reset.

**finding-2**: requirement, medium — a retired or superseded exported provider REQ still meets a consumer's `expects:`; `met` never consults out-of-force state.
disposition: ruled on 2026-10-08 under D3 (an out-of-force exported REQ meets no `expects:`) and implemented with one `oof_scan` function shared by this run and the provider's ledger (2202f36); `check-trace: an out-of-force exported REQ meets no expectation` was watched red. The provider's advisory count changed to match.

**finding-3**: code, low — `develop-change` required a `red -> green:` line per test, which an inherited test cannot have, and no checklist item asked a reviewer to examine an inherited test.
disposition: `develop-change` requires one line per new test, and the review checklist reviews an `inherited:` test as an edited test that must verify its successor's behavior (c7b13a1).

**finding-4**: code, low — mutants survive on the bare-separator retirement, the retirement beside a one-sided `superseded-by:`, and the line-wise `implements:` conjunct; and the unreadable-ledger test carried `verifies: D1` while testing an error path.
disposition: three tests, each reddened by its mutant, and the conjunct's comment rewritten (c1cb36c); the error-path test's annotation replaced by a comment.

**finding-5**: record — the record named the old base, the old gate table, the round 1 reviewer commit, and a D6 test whose statements had moved.
disposition: this record is rewritten after the final round.

**finding-6**: record — Gaps listed unit-scoped runs and CRLF as probe-only, and omitted the front-matter and cross-unit cases as found.
disposition: Gaps rewritten below.

### Round 3

**finding-1**: code, high — a self-supersession, or two items superseding each other, takes the items out of force with no successor in force; untested items that main reports as MISSING-TEST pass.
disposition: ruled on 2026-10-08: a chain must end in an item in force or validly retired, and a self-pair or a cycle exempts nothing and is MALFORMED-SUPERSESSION (dcb9d48). Computed as a fixpoint in `oof_scan`, which the provider side shares. Two tests watched red, two scope controls.

**finding-2**: code, low — the provider's SAD read is untested, and a provider's missing `doc_sad` makes the consumer's run exit 2.
disposition: a test of a provider REQ superseded by a provider LLR, reddened by both surviving mutants, and an error-path test of the missing `doc_sad`, which matches a missing `doc_srs`, also exit 2 (dcb9d48).

**finding-3**: code, low — the `implements:` rule intersected per control, so a retired tracked REQ and an in-force REQ in a gitignored SRS file credited a control between them.
disposition: the block pass drops every file `git check-ignore` names, so both readers read the same files (dcb9d48); the fixture was watched red.

**finding-4**: requirement, low — the D3 extension to `expects:` was stated in no adopter-facing text.
disposition: stated in `grill-requirements` (SKILL.md and `references/supersession.md`), the upgrade notes and the UNMET-EXPECTATION header entry (dcb9d48).

**finding-5**: code, low — the new awk code used single-character names.
disposition: renamed in the code this change added (dcb9d48); no mutation anchor quoted a renamed line.

**finding-6**: record — the red → green table mapped an error-path test to D1, and omitted round 2's tests.
disposition: this record is rewritten after the final round.

**finding-7**: record — Gaps called unit-scoped runs probe-only although a unit-scoped test exists.
disposition: Gaps rewritten below.

### Round 4

**finding-1**: code, low — `oof_scan` exits 2 when neither the SRS nor the SAD is configured: `git check-ignore --` runs with no paths before the empty-list guard.
disposition: the guard runs first (b08be6d); the error-path test was watched red against the previous script and passes against `main`'s.

**finding-2**: code, low — no test shows a cycle alone fails the run; the cycle tests' items are untested, so MISSING-TEST already fails them.
disposition: a cycle of tested items is a test, reddened by dropping the `fail=1` (4b672de).

**finding-3**: code, low — the cycle report's ID sort is unpinned; with two IDs the array order happened to be sorted.
disposition: a three-ID case is a test, reddened by making the sort a no-op (4b672de).

**finding-4**: requirement, low — two behaviors had no decision: a valid `retired:` beside a reciprocal `superseded-by:` was still out of force through the edge, and an item with one terminating and one cyclic successor was out of force.
disposition: ruled on 2026-10-08 and recorded in D5 and D1: the first stays in force and owes its test (fixed and watched red), the second is out of force (a scope control) (4b672de, 618d04d).

**finding-5**: code, low — a new test used a single-character name.
disposition: renamed (4b672de).

**finding-6**: code, low — `prune-plans.sh` kept a fence only for a `red -> green` line, so step 1 would prune a fence of `inherited:` lines before step 6b copies them.
disposition: a line opening with `inherited:` keeps its fence too, stated in the script header, `plan-change`, `templates/config.yaml`, the upgrade notes and ADR-bh4xgr (d19c02f, 9ca6d3d); the test was watched red.

**finding-7**: code, low — step 6b said "the verdict", losing whose.
disposition: "the reviewer's verdict" restored inside the 2,000-word limit (d19c02f).

**finding-8**: code, low — the cycle message said "no successor in force", narrower than the rule "in force or validly retired".
disposition: the message, its header entry, `supersession.md` and the upgrade notes say "in force or retired"; the exact-message assertions follow (4b672de).

**finding-9**: record — the missing-provider-SAD test carried `verifies: D3` although it tests an error path.
disposition: the annotation is replaced by an error-path comment (4b672de).

## Gaps

- Measured on BWK awk 20200816 only. gawk, mawk and busybox awk are not installed on the host that ran every dispatch, gate and review.
- The D6 rule is prose. `check-review.sh` does not read `inherited:` lines, so a test claimed as inherited is checked by the dispatcher and the reviewer, not by a gate.
- Not in the shipped suite, probed by reviewers in scratch tests and correct there: CRLF and BOM ledgers, multi-ID `verifies:` lists, an LLR superseded by a REQ.
- A `retired:` on an RC, HAZ, SDD or PR retires nothing and, outside the SRS and SAD, is not reported. An SDD has no retirement form; it owes no test, so nothing here needed one.
- `merge-change/SKILL.md` stands at 2,000 of 2,000 words; its next addition must cut something.
- A gate run at an earlier tree (`6551181`) exited 1 on a bats-internal `wait: pid … is not a child of this shell` line with every test ok; `check-trace.bats` rerun alone passed. Bats' parallel collection, not a test, produced it.
- `UNIMPLEMENTED-CONTROL` keeps the line-wise reader beside the block pass; the remaining difference between them, `git grep -I` skipping a binary file awk would read, has no test.
