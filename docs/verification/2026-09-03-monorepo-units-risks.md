# Verification record — monorepo-units-risks

branch: monorepo-units-risks
reviewer: one independent subagent (DO-178C independence: not the author; received only the diff, the governing documents and the handoff, no implementation narrative)
verdict: approve-with-findings — 1 IMPORTANT, 3 MINOR; all four fixed and dispositioned below
reproduced: not applicable in the defect sense — this change assesses decisions of a designed, not yet implemented machinery; every claim about existing scripts was reproduced by the reviewer against the scripts at HEAD (check-ids.sh's DUPLICATE-ID scan runs tree-wide from gr_root; lib.sh line 13 makes GR_CONFIG-overridden single-config layouts supportable today), and the one misattributed mechanism claim the reviewer caught is finding-2.

## Scope

The ISO 14971 assessment of the three derived decisions handed off by the
units architecture (docs/verification/2026-09-03-monorepo-units-design.md):
docs/risk/2026-09-03-units-architecture-derived.md (new), with matching
amendments to docs/plans/2026-09-03-units-architecture.md (one finding
token `DISCLAIMED-DRAFT`, the near-miss manifest scan, five named test
obligations, the derived-decisions list marked assessed). Documentation
only; no script or test changed.

## Base

Merged **from the local ref** `main` = `817156c` at step 1 (merge commit
`4c41572`) and again after the review fixes ("already up to date"). A
fetch is impossible in this environment (the hardware key refuses
non-interactive operations); the local `main` was ahead of the remote —
`817156c` is the close-signing-identity-prs squash the user's other
session landed and pushed during this change. The step-1 merge commit
initially failed to write under global commit.gpgsign and was concluded
with `-c commit.gpgsign=false`, as all worktree commits are.

## Test evidence

`sh tests/run-tests.sh`: **475 tests, 475 ok, exit 0**, run three times —
after the base merge (step 2), after the DRAFT→dated rename (step 6), and
definitively at `e53c3c2` after the review-finding fixes. Only this
record's own commit follows that run, touching docs/verification/ alone.

Check scripts do not run against this repository (not self-hosted — no
.guardrails/config.yaml; docs/plans/2026-08-22-ratchet-gap-analysis.md),
consistent with every prior change. Performed by hand in their stead:
DRAFT→dated rename (finalize-docs.sh needs a config); zero draft tokens
confirmed by `git grep DRAFT-monorepo-units-risks` (no matches); item IDs
none — descriptive labels only, per the not-self-hosted convention.

## Review findings and dispositions

**finding-1** (IMPORTANT): the near-miss manifest scan was written over
"root files", but the manifest lives at `.guardrails/units.yaml` — the
scan would miss the actual mistype (`.guardrails/units.yml`) and convict
exactly where third-party `units.yml` files legitimately live, wedging
such repositories at exit 2 with no remedy they control.
disposition: the scan now watches exactly the root `.guardrails/`
directory — the manifest's own home — in both the risk file and the
architecture's item 6; the repository root is deliberately unscanned and
the wrong-directory mistype (a manifest-shaped `units.yaml` at repo root)
is named accepted residual. Both obligation descriptions carry the
location; **near-miss-without-manifest-content-passes** now convicts
nothing in both directions (non-manifest content inside `.guardrails/`,
manifest-shaped content outside it).

**finding-2** (MINOR): assessment 1 grounded its "already paid for"
mechanism on a definitions index shared between DUPLICATE-ID
(check-ids.sh) and the resolver (lib.sh scope layer) — no such shared
index exists in the code or the architecture.
disposition: regrounded on item 2's classification table: to emit the
`not_a_unit:` row distinct from "nowhere" the resolver must already locate
definitions under disclaimed paths; the message names what that lookup
already found. The DUPLICATE-ID cross-script claim is gone.

**finding-3** (MINOR): the architecture's findings-vocabulary table did
not carry the near-miss exit-2 conviction; a reader of the table alone
would not implement it.
disposition: a dedicated row added — near-miss manifest name, exit 2,
check-units, risk assessment 2 (2026-09-03).

**finding-4** (MINOR): **near-miss-manifest-name-is-exit-2** as described
pinned one class member (`units.yml`); an implementation handling only the
literal name would stay green.
disposition: the obligation is worded over the class in both files — each
name in the near-miss class (`units.yml`, `unit.yaml`, case variants of
`units.yaml`), manifest-shaped, in `.guardrails/` → exit 2; the class, not
one member.

## Notes

- The reviewer verified mechanically that all five obligation names are
  spelled identically across the risk file and the architecture, that
  `DISCLAIMED-DRAFT` carries the same exit class everywhere, and that
  nothing in the change invalidates a merged decision.
- Handoff forward: `plan-change` owns the implementation; it inherits the
  architecture's obligations list *including* the five this assessment
  added, as requirements, not suggestions. No open handoff remains from
  the units design — its three derived decisions are all assessed here.
- REQ/RC/HAZ minting for these controls awaits self-hosting
  (docs/plans/2026-08-22-ratchet-gap-analysis.md).
