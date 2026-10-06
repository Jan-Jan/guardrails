# Verification — readme-orientation (2026-10-06)

branch: readme-orientation
reviewer: round 1, a fresh subagent with the diff, the plan, the agent-first proposal's D1 and D4, AGENTS.md and the review checklist, and no implementation narrative
verdict: round 1 ACCEPT with every finding low or record, which under the low-severity rule (ruled by the user 2026-10-04) is the last round. finding-1 to finding-4 are fixed in `7bb6ce8`; finding-5 is a record finding with nothing to fix
reproduced: not applicable — no defect is claimed. The change moves rules out of `README.md`; the reviewer checked each old README section against its owner in the tree, and the gate rows below compare the ledger checks on `main` and on the change.

Change: `README.md` becomes orientation-only (agent-first proposal D1, change 4
of D3). Its rules move once to their owners: the script header comments, the
skills' reference files and the ledger templates. Documentation, comments and
tests only; no executable script line changes. Branched from local `main` at
`be4335a` on 2026-10-06; base merged from local `main` at `be4335a`, per
AGENTS.md non-negotiable 5 (no-op: `main` did not move during the change).
Plan: `docs/plans/2026-10-06-readme-orientation.md`.

## The gate

Measured on: `7bb6ce8` — tree `080738eac440351e98e557bc792c8937e3d184eb`,
clean worktree, with local `main` at `be4335a` an ancestor and unchanged from
the start to the end of the run. Step 3 renamed nothing: the change has no
draft ledger file.

Guardrails has no `.guardrails/config.yaml`. `check-ids.sh` and
`check-trace.sh` were run against scratch copies of `main` at `be4335a` and of
the change at `7bb6ce8`, built by the recipe in
`docs/verification/2026-10-03-accept-2scmvn.md`. The criterion is no finding
on the change that `main` lacks.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..1074`: 1074 ok, 0 not ok, 0 skipped, no `bats warning:` line, exit 0; finished 21:01 CEST on 2026-10-06; 1074 results, so plan and results agree |
| `sh tests/evidence.sh main` | exit 0: 1074 tests, as on `main`; 0 new or renamed since `main`, so none goes red and none cannot |
| `check-ids.sh` | exit 1 on `main` (79 lines) and on the change (78 lines); the sorted `diff` drops one line, a `DRAFT-ID` on the old `README.md:278`, which quoted `REQ-DRAFT-x-1` in prose. Nothing is added |
| `check-trace.sh` | exit 1 on `main` and on the change, 152 lines each, sorted `diff` empty |
| `tests/skills.bats`, `tests/portability.bats` | the T1 implementer's run on `c6022b9`: 101 and 13 ok, 0 not ok; `tests/mutations.bats` 7 ok; the reviewer's run of the first two on `a1b3790`: 114 ok, 0 not ok |
| `check-review.sh` | run on the commit that adds this record (merge-change step 6c); its result is reported with the hand-over |
| Coverage | not configured; the toolkit is unclassified |
| Working tree | clean before and after the run |

The reviewer ran `skills.bats` and `portability.bats`, not the whole suite;
the gate above is substituted for the rest. This record is committed after the
gate and changes no file the suite reads.

## Red → green

No problem item is resolved, and no test is added. Two tests change, each
keeping its `verifies:` line (proposal D4):

| Item | Test | Change |
| --- | --- | --- |
| PR-58zsvf | `merge-step-3-reports-rewrites` | the `DANGLING-FILE`, `reported as left` and `root-relative` pins move from `README.md` to the `scripts/finalize-docs.sh` header, which states each (lines 9, 19 and 22) |
| PR-n274s7 | `assesses-is-the-remedy` | `README.md` leaves the list of places that tell an author how to assess; the templates and both skills stay pinned |

## What was built

`README.md` went from 4,644 words to 746. It keeps the introduction, Install,
the workflow diagram with the three rules, one line per check script, and a
list of where the rules live. Rules the old README alone stated were written
into their owners first: the headers of `check-review.sh`, `check-signing.sh`,
`finalize-docs.sh`, `find-items.sh` and `new-id.sh`, a comment in `lib.sh`, and
`skills/check-traceability/references/config.md`, which gains a section on
where a ledger must not live. The plan's Progress table maps each removed
paragraph or table row to its owner. Narration of past behaviour was deleted,
as was one passage that no longer matched the code (`gr_def_re_loose`).

## Review

Round 1. The reviewer grepped each old README section's owner and read the code
behind it, confirmed the `scripts/` diff is comments only, and ran
`skills.bats` and `portability.bats` (`1..114`, 114 ok).

**finding-1**: requirement, low — README.md:94-95 says "Each rule is stated once, in one of these places". That is false in the tree: the token alphabet is stated in all four ledger templates, and the scan-exclusion caveat in both `scripts/lib.sh` and `references/config.md`. Plan D7 concedes that some rules appear on two surfaces.
disposition: fixed in `7bb6ce8`: "Each rule is stated by its owner, in one of these places".

**finding-2**: code, low — The new comment at scripts/finalize-docs.sh:20-21 says two drafts that would get the same dated name on the same day get `-2`. The code (line 291, `while [ -e "$target" ] || ...`) also suffixes when the dated name already exists on disk, which the old README's "same-day collisions get `-2`" covered.
disposition: fixed in `7bb6ce8`: "A draft whose dated name is already taken, on disk or by another draft in this run, gets a -2 suffix".

**finding-3**: requirement, low — The Progress row for config entries claims `already stated`, but `references/config.md` never said that a `doc_*` value is a plain path and not a pathspec, which the old README did. A glob in a `doc_*` value still fails loudly, so there is no false green.
disposition: fixed in `7bb6ce8`: config.md states it in the pathspec row, and the Progress row records it as moved after this finding.

**finding-4**: requirement, low — The new config.md section points to the scan-pathspec matrix but drops the old README's caveat that the matrix was measured before IDs became tokens, so its minting rows describe a step that no longer exists. That is reading guidance, not history.
disposition: fixed in `7bb6ce8`: config.md keeps the caveat in one sentence.

**finding-5**: record — The other Progress rows marked `already stated` check out against their owners, and every moved row matches the script's behaviour apart from finding-2.
disposition: recorded; nothing to fix.

No `code` or `requirement` finding above low: no further reviewer was
dispatched.

## Gaps

- The check that each rule survived is a reviewer's reading, not a test. A rule
  lost between the old README and its owner would leave every test green.
- `skills/check-traceability/references/config.md` cites the scan-pathspec
  matrix in the guardrails repository; a target project does not have that file.
- `check-ids`, `check-trace`, `check-review` and `finalize-docs` are not
  self-hosted (no `.guardrails/config.yaml`); the ledger rows above come from
  scratch copies.
