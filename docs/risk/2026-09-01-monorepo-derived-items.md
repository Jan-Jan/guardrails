# Risk assessment — derived items from monorepo support (D1–D14)

Assesses the three items the monorepo requirements change
(docs/plans/2026-08-26-monorepo-support.md) marked **derived, needs
assessment**, per the handoff in
docs/verification/2026-09-01-monorepo-requirements.md.

The subject is the guardrails toolkit itself, so harm is indirect: a false
green here lets a defect ship from a downstream regulated project. Severity
below is rated at the worst credible downstream consumer (a Class C device);
probability is rated for the toolkit's own failure mode. This repository is
not yet self-hosted (docs/plans/2026-08-22-ratchet-gap-analysis.md), so items
carry descriptive labels, not minted HAZ/RC tokens — token minting follows
self-hosting, as it does for the plan's requirements.

## Derived requirements assessment

### 1. D10's MISSING-TEST exemption for unmet expectation REQs

**Hazard — unbounded silent untested requirement.** An unmet, non-RC-linked
expectation REQ is the one class of REQ with neither a test nor a conviction.
Its designed bound is the aging budget — and `expectation_age_days` /
`expectation_open_max` were modeled on the problem limits, which are
*optional*. Hazardous situation: a team tags a REQ `expects: <unit>`, the
limits are unset, and the item sits indefinitely as one printed line per run —
the same scroll-past decay `UNRESOLVED-PR` suffered before the problem limits
were shipped set. Worst credible harm: a Class C consumer ships behavior that
silently depends on provider work nobody is tracking. Severity: S3.
Probability: P2 (each limit is one comment away from off).

A second face of the same hazard: `expects:` naming a unit that is not a
declared dependency. Were that annotation accepted silently, it would exempt
*any* REQ from MISSING-TEST — a free dodge.

**Controls (decision, recorded in the plan as amendments to D10/D11):**

- `expectation_age_days` and `expectation_open_max` are **shipped set** in the
  per-unit config template, for the reason the problem limits are: an
  enforcement mechanism that defaults to off does not answer the finding it
  exists for. Removing a limit remains policy a project may choose — visibly,
  by editing its config.
- An `expects:` naming a unit absent from the unit's `depends_on:` convicts
  `UNDECLARED-DEPENDENCY` — it is exactly a reference across an undeclared
  edge — and the exemption never engages. The annotation therefore cannot
  widen the exempt class beyond declared dependency edges. Named test
  obligation on `check-units.sh`: **expects-undeclared-unit-convicts** (a REQ
  carrying `expects: <unit>` with `<unit>` not in `depends_on:` convicts and
  is NOT exempt from MISSING-TEST).

**Residual risk:** a project that deliberately unsets both limits re-opens the
window, with the printed line as the only mitigation — acceptable, because the
same is true of the problem limits and the choice is explicit in a validated
config, not a default. The exemption's other boundary is already mechanical:
the moment the expectation is met, MISSING-TEST applies normally.

### 2. D8's export-removal scenario

**Hazard — a provider strands its consumers silently.** Removing an item's
`exported: yes` while consumers still trace to it must convict; the plan
believed it covered but had not verified the chain. Traced here, the chain
holds by design at every link — the hazard is that `check-units.sh` gets
built link by link and the *composed* chain is never tested: each scan
correct in isolation, the removal still sailing through. Severity: S3
(a consumer's traceability quietly voids). Probability: P2 without a binding
test, P1 with one.

**Control — the chain links are named test obligations**, binding on
`check-units.sh`'s bats suite (`design-architecture` inherits them as
requirements, not suggestions):

- **export-removal-convicts**: provider removes `exported: yes` from an item
  a consumer traces to → the provider change's impact set (D6+D12) includes
  the consumer → the consumer's run convicts `NON-EXPORTED-REF` → the
  provider's merge blocks. The composed end-to-end scenario, not just links.
- **export-removal-reopens-expectation**: the removed export carried
  `satisfies:` for a consumer expectation → the expectation recomputes to
  unmet (D11 keeps no `status:` to go stale); if RC-linked, exit 1 on the
  consumer's next run.
- **item-deletion-degrades-to-dangling**: deleting the exported item outright
  → `DANGLING-REF` on the consumer's run, same impact set.
- **transitive-dependent-unaffected**: a dependent-of-a-dependent that never
  referenced the item passes; one that referenced it directly was already
  `UNDECLARED-DEPENDENCY` (D4 scope is direct edges only).

**Residual risk:** the chain fires at merge time via the impact set; a
provider change integrated without `merge-change` bypasses it. Accepted: that
is the toolkit's universal trust boundary (the base branch moves only by
signed squash), not exposure D8 adds.

### 3. D4's reverse-visibility exception (the D10 crack)

**Hazard — the narrow edge widens in implementation.** The design grants a
provider's scans exactly the `expects:` items of units that declare it as a
dependency — those items, nothing else. Built any wider ("the provider sees
the consumer's SRS"), the false-green class opens: a provider `satisfies:`
resolving against arbitrary consumer internals, provider trace obligations
discharged by files the provider does not own. The design is safe precisely
as narrow as written; every unit of width beyond it is exposure.
Severity: S3. Probability: P2 ungated, P1 with the obligations below.

**Control — the narrowness is itself gated**, as named test obligations on
`check-units.sh`:

- **reverse-edge-is-exactly-expects**: a provider reference to any consumer
  item that is *not* an `expects:` item naming this provider convicts
  `UNDECLARED-DEPENDENCY`, exactly as it would without the crack.
- **satisfies-across-wrong-edge-convicts**: a `satisfies:` aimed at an
  expectation whose `expects:` names a different unit convicts.
- **reverse-edge-discharges-nothing**: no provider trace gate (placement,
  MISSING-TEST, duplicate scope) is satisfiable by consumer files; the
  reverse edge resolves references only.

**Safe-direction properties, verified against the merged decisions:**
satisfying an expectation with a non-exported REQ leaves it unmet — met
requires `exported: yes` *and* `satisfies:` — so the mistake fails toward
conviction, not past it. The reverse edge is not a `depends_on:` edge, so
D2's cycle detection is unaffected.

**Residual risk:** the provider-side open-expectations list is advisory
(exit 0) and can decay to scroll-past. Accepted: D11 deliberately places
enforcement on the consumer — the party at risk — whose aging budget is
shipped set (assessment 1). The prompt is a courtesy on top of a gate, not
the gate.

## Disposition of the handoff

All three derived items are assessed: none invalidates a merged decision;
each yields controls that are template policy (assessment 1's shipped-set
limits) or gate rules pinned by named test obligations binding on
`check-units.sh` (assessment 1's `UNDECLARED-DEPENDENCY` conviction for a
stray `expects:`, and all of assessments 2 and 3), which
`design-architecture` inherits. REQ minting for these controls awaits
self-hosting (docs/plans/2026-08-22-ratchet-gap-analysis.md), as it does for
the plan's own requirements.
