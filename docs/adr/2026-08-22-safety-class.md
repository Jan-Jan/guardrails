# ADR: guardrails is IEC 62304 software safety class A

Date: 2026-08-22
Status: accepted

## Context

`/ratchet` requires a safety class before anything else scales correctly, and
the config ships `safety_class: TBD` as a sentinel precisely so the question
cannot be skipped. Guardrails is unusual among projects that would adopt it:
it is not device software, and it is not part of any device. It is a set of
POSIX sh check scripts and agent skills that run on a developer's machine and
in CI, enforcing traceability and process discipline on *other* projects —
some of which are medical devices.

The interview question is whether a failure of this software can contribute to
a hazardous situation at all.

## Decision

**Class A.**

Guardrails never executes in a medical device, never touches a patient, and
controls no hardware. It has no path by which its own failure reaches a person.
The IEC 62304 safety classification applies to software that is part of a
medical device; applying it to a developer tool is a category error, and
choosing B or C here would be theatre — it would impose coverage and LLR
obligations without naming a single hazardous situation they mitigate.

## The failure mode that does matter, and where it is handled

The real risk is not a safety class question. It is that a defect in a check
script **masks an error in a project that uses it** — a gate that silently does
not run while the build still exits 0. That risk is genuine and is this
project's central preoccupation: the git history is largely a record of finding
and closing such holes (`fix: stop the check scripts reporting success when
they checked nothing`, `feat: validate the config schema before any gate runs`,
`feat: report an item defined outside its own document`).

It is handled as **tool qualification**, not as a device safety class. This is
the DO-330-lite treatment the ratchet skill already prescribes: the check
scripts are verification tools whose failure could mask errors, and their
qualification basis is the bats suite at the recorded `guardrails_version`.
That is the correct frame, and it is strictly more demanding here than a
Class B coverage target would be, because it targets the specific failure mode
rather than a generic percentage.

Qualification basis at this decision: **guardrails 0.2.0, bats suite 212/212
passing, 0 failures** (measured 2026-08-22).

## Consequences

- Coverage gate: none required for Class A. `coverage_command` stays
  unconfigured, and the setup checklist records why.
- Robustness tests: recommended, not required. The suite already exercises
  abnormal inputs heavily (BOM, orphaned list items, FIFOs, errored scans).
- LLRs: not required per SDD item.
- Independent review: optional. The history shows it has been used anyway and
  has found real defects — see the `DUPLICATE-ID` status-checking bug noted in
  `check-ids.sh`, found by independent review. Keep the practice; it is not
  imposed by the class.
- The per-item override mechanism stays available: if any future component
  ever does run inside a device, document the higher class in the SAD next to
  its SDD item.

## Consequence this ADR does not soften

Class A lowers nothing about the false-green work. A guardrails release that
passes its own suite while a gate does not run is the failure this project
exists to prevent, and no safety class relaxes that.
