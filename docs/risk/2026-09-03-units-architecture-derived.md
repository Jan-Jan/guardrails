# Risk assessment — derived decisions from the units architecture

Assesses the three decisions the monorepo units architecture
(docs/plans/2026-09-03-units-architecture.md) marked **derived, needs
assessment**, per the handoff in
docs/verification/2026-09-03-monorepo-units-design.md.

As in docs/risk/2026-09-01-monorepo-derived-items.md: the subject is the
guardrails toolkit itself, so harm is indirect — a false green here lets a
defect ship from a downstream regulated project. Severity is rated at the
worst credible downstream consumer (a Class C device); probability is rated
for the toolkit's own failure mode. This repository is not yet self-hosted
(docs/plans/2026-08-22-ratchet-gap-analysis.md), so items carry descriptive
labels, not minted HAZ/RC tokens.

## Derived decisions assessment

### 1. Disclaimed definitions convict `DANGLING-REF` with the wrong cause

**Hazard — misdirected remediation.** A reference to an ID defined under a
`not_a_unit:` path convicts `DANGLING-REF`, exactly as a typo does. The
failure direction is safe — toward conviction — but the verdict names the
wrong cause. Hazardous situation: an engineer reads "dangling", assumes a
typo, and repairs the *reference* — re-aiming it at a plausible in-scope
item — when the truth is that the unit depends on disclaimed prose that was
never brought into compliance. Worst credible harm: a Class C consumer's
trace records the wrong provenance for a requirement, mechanically valid
and semantically false. Severity: S3. Probability: P2 without a control —
the two causes read identically, so misdiagnosis is the default — P1 with.

**Control (decision):** the token stays `DANGLING-REF` — disclaimed means
outside compliance, and one token covers one truth class ("this reference
resolves to no item") — but when the referenced ID has a definition under a
disclaimed path, the **message names that definition and its file**. The
mechanism is already paid for by item 2's classification table: to emit
its `not_a_unit:` row at all — distinct from "nowhere" — the resolver must
already locate definitions under disclaimed paths; the message names what
that lookup already found, read-only. Named test obligation on the scoped
resolution layer: **disclaimed-definition-names-its-path** (a reference to
an ID defined only under a `not_a_unit:` path convicts `DANGLING-REF` and
the message names the disclaimed file; a plain typo's message names
nothing).

**What the control breaks:** nothing structural — it is message
enrichment over an index that already exists. If the same ID is defined
both in a unit and under a disclaimed path, the message could name the
wrong site — but that shape is `DUPLICATE-ID`, convicted tree-wide on its
own.

**Residual risk:** the control is informational; an engineer can still
ignore the message and re-aim the reference. Accepted — the failure
direction was already toward conviction, and no gate can judge whether a
repaired reference is semantically right. The message makes the correct
remediation (claim the path, or move the definition into a unit) the
obvious one; it cannot compel it.

### 2. `check-units.sh` exits 0 without a manifest

**Hazard — the cross-unit gates silently disengage.** No `units.yaml`
means single-unit repository, exit 0 — honest for the shape it names, but
a mistyped manifest (`units.yml`) produces the identical shape, and then
`UNCLAIMED-PATH`, `MISCLASSED-DEPENDENCY`, `INCOMPLETE-SEGREGATION`, the
cycle gate and the impact chain never run. Hazardous situation: a team
migrates to a monorepo, typos the manifest filename, and CI stays green
through the whole migration. Worst credible harm: a Class C consumer ships
with an undeclared dependency on an uncontrolled sibling — the exact class
of defect the machinery exists to convict. Severity: S3. Probability: P2
in the uncontrolled window, P1 with the controls below.

**Existing mitigation, verified sufficient only in part:** the
stray-configs scan (two or more unit-shaped configs without a manifest →
exit 2) catches every repo whose units are individually configured — which
a manifest repo's units must be, so the mistype window is real but narrow:
it requires the typoed manifest AND at most one unit config in the tree.
Tightening the threshold to one config was considered and **rejected**: a
single non-root config with no manifest is today's legitimate
project-in-a-subdirectory layout, and convicting it would force a manifest
onto single-unit repositories.

**Control (decision):** a near-miss manifest scan in `check-units.sh`
default mode, running exactly when no `.guardrails/units.yaml` exists and
scanning exactly the manifest's own directory — the root `.guardrails/`,
where the mistyped manifest actually lands and where no other tool's file
legitimately lives. A file there in the near-miss class (`units.yml`,
`unit.yaml`, case variants of `units.yaml`) **whose content is
manifest-shaped** — a top-level `units:` or `not_a_unit:` key — convicts
at exit 2, message "did you mean .guardrails/units.yaml". Confining the
scan to `.guardrails/` is what keeps a third party's `units.yml` from
wedging the repository — at the repository root, where such files live,
nothing is scanned; the content condition additionally spares a stray
non-manifest note inside `.guardrails/` itself. Named test obligations on
`check-units.sh`: **near-miss-manifest-name-is-exit-2** (each name in the
near-miss class, manifest-shaped, in `.guardrails/`, no
`.guardrails/units.yaml` → exit 2 — the class, not one member) and its
narrowness twin **near-miss-without-manifest-content-passes** (a
`.guardrails/units.yml` with no manifest-shaped key convicts nothing, and
a manifest-shaped `units.yml` outside `.guardrails/` convicts nothing).

**What the control breaks:** a repo carrying a *disused* manifest-shaped
`units.yml` (e.g. an abandoned migration attempt) must delete or rename it
before check-units.sh passes — loud by design; the remedy is one `git mv`.

**Residual risk:** a manifest misnamed outside the near-miss class
(`units.yaml.bak`, a manifest in a subdirectory), or misplaced outside
`.guardrails/` (a manifest-shaped `units.yaml` at the repository root —
left unscanned deliberately, because the root is where third-party files
of that name live), still passes silently with at most one unit config
present. Accepted: such a file is
indistinguishable from prose without guessing, the window closes the
moment a second unit config lands (the stray-configs scan), and the
migration path `/ratchet` will own (D9 facts interview) writes the
manifest itself rather than leaving the filename to hand-typing.

### 3. Disclaimed paths are scanned by no run

**Hazard — a gate-dodging channel for unfinished regulated work.** Scoped
draft and `MALFORMED-ID` scans cover each unit; disclaimed paths belong to
no unit, so a draft token or DRAFT-named ledger file parked under
`not_a_unit:` passes every run forever — including the base-branch union —
where today's tree-wide scans would convict it. Hazardous situation:
foreseeable misuse — a team keeps a unit's real requirements work in a
disclaimed directory to keep CI green — or plain accident: a mid-flight
DRAFT file is swept into an archive directory and never finalized, then
read by humans as merged record. Worst credible harm: a Class C consumer's
requirements exist only as an unfinalized draft that no gate will ever
age, count, or block on. Severity: S3. Probability: P2 (one `git mv` away)
without a control, P1 with.

**Control (decision):** `check-units.sh` default mode scans disclaimed
paths for **draft tokens and DRAFT-named files only**, convicting
`DISCLAIMED-DRAFT` at exit 1 — a repository-level finding, deliberately
blocking every unit's merge until the parked draft is finalized or
deleted: a disclaimed path is never a legitimate home for work in flight,
so cross-unit blocking is the point, not a cost. `MALFORMED-ID` is
deliberately **not** scanned there: disclaimed directories legitimately
hold legacy prose in definition shape, and convicting an archive line by
line drives teams to widen patterns — the failure mode the gates exist to
prevent. The narrowness is itself gated. Named test obligations on
`check-units.sh`: **disclaimed-draft-convicts-at-repo-level** (a draft
token or DRAFT-named file under a `not_a_unit:` path → `DISCLAIMED-DRAFT`,
exit 1, from the repository-level run) and
**disclaimed-prose-is-not-malformed** (a definition-shaped line with an
invalid ID under a disclaimed path convicts nothing).

**What the control breaks:** archiving genuinely historical material that
contains the literal draft token now requires scrubbing it first — a
one-time cleanup per archived file, surfaced loudly rather than silently
inherited.

**Residual risk:** malformed and legacy-ID definitions in disclaimed paths
remain unscanned — accepted, they are prose by definition, `DUPLICATE-ID`
still guards the ID namespace tree-wide, and any reference to them from a
unit convicts `DANGLING-REF` naming the disclaimed file (assessment 1).
The scan runs only where `check-units.sh` runs; a manifest repository that
never runs it has disengaged the machinery wholesale, which is assessment
2's hazard, not a new one.

## Disposition of the handoff

All three derived decisions are assessed: none invalidates a merged
decision; the architecture's classification table, engagement rule and
scan-scope choices stand as designed, each now carrying a control. The
controls add one finding token (`DISCLAIMED-DRAFT`, exit 1,
`check-units.sh`) and five named test obligations
(**disclaimed-definition-names-its-path**,
**near-miss-manifest-name-is-exit-2**,
**near-miss-without-manifest-content-passes**,
**disclaimed-draft-convicts-at-repo-level**,
**disclaimed-prose-is-not-malformed**), binding on the unit machinery's
bats suite wherever each conviction lands, alongside the architecture's
own obligations — `plan-change` inherits them as requirements, not
suggestions. The architecture document is amended in place to carry the
token, the near-miss scan, and the obligations. REQ/RC minting awaits
self-hosting (docs/plans/2026-08-22-ratchet-gap-analysis.md), as before.
