# Verification — lean-records (2026-10-23)

branch: lean-records
reviewer: one independent subagent, dispatched at `merge-change` step 4 with
the diff, the plan and the review checklist, and no implementation narrative;
the diff is documentation only, so it ran no tests.
verdict: approve. One round; no `code` or `requirement` finding above low, so
no further reviewer was dispatched. Every finding was fixed.
reproduced: not applicable — the change records a decision, not a defect.

Change: ADR-k3nkv3 records that the code and the signed squash messages are
the record, and the plan records the decisions D1–D16 behind it.
Plan: `docs/plans/2026-10-23-lean-records.md`.

## The gate

The figures are in the squash commit's trailers. This repository has no
`.guardrails/config.yaml`, so `merge-preflight.sh` stops at its config read;
`check-ids.sh` and `check-trace.sh` were run instead on scratch copies of
`main` and of the change, each with `templates/config.yaml`, `scripts` as its
strict path and stub SRS, SAD and SOUP files. Their output is identical at
both but for the ADR count, 13 to 14: the change adds no ID or trace finding.

## Red → green

No script, skill or test changes, so the change has no `red -> green:` line.

## Findings

1. fixed — record: the ADR's 70% figure named plans, verification and
   problems only (51%); it now names the whole history set the plan measures.
2. fixed — record: the plan gave 324k words of scripts and tests; tracked
   files measure 235k.
3. fixed — requirement, low: the ADR amended ADR-f6ytg7 (record file,
   `Gate:` trailer) without naming it; its Consequences now name it.
4. fixed — requirement, low: "Supersedes ADR-bh4xgr" stated a future state as
   present; it now supersedes once plans stop reaching the base branch, and
   both ADRs stay in force until then.
5. fixed — record: the ADR misstated D4 (`.mutations/` scripts are dropped,
   their evidence carried as trailers) and omitted D5's regression-test rule
   and D7's ADR form; all three are now stated.
6. fixed — requirement, low: neither file named AGENTS.md, whose rules put
   plans and incident history in `docs/plans/`; D9 now includes it.
7. fixed — record: the item line covered two of six bullets; it now states
   the whole decision. The six bullets are one decision about where the
   record lives.
