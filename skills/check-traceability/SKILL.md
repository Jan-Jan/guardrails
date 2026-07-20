---
name: check-traceability
description: Run and interpret the guardrails traceability checker - orphaned requirements, unmitigated hazards, unimplemented controls, untraced design, dangling references. Use after documentation or code changes and always before merging.
---

# Check Traceability

**Announce at start:** "Using the check-traceability skill."

```sh
.guardrails/scripts/check-trace.sh              # traceability gates
.guardrails/scripts/check-ids.sh --allow-drafts # ID sanity while developing
```

Run from the repo root. Exit 0 with no output = clean. Each violation is one
line: `<RULE> <ID> (<detail>)`. Fix the artifact, never the checker.

## Fixing each rule

| Rule | Meaning | Fix |
|---|---|---|
| `MISSING-TEST REQ-…` | No direct `verifies:` test AND no tested LLR `satisfies:` it | Write the test (`develop-change`) at the lowest level that exists — LLR where there is one, else the REQ. If the REQ is untestable as written, sharpen it via `grill-requirements`. Never annotate a test that doesn't actually verify the behavior. |
| `MISSING-TEST LLR-…` | No test carries `verifies:` for this low-level requirement | Write the unit test at the software item's own interface (`develop-change`). |
| `UNSATISFIED-LLR LLR-…` | LLR has no `satisfies:` naming a REQ and isn't marked derived | Add the parent REQ trace, or mark `satisfies: derived` and get it assessed via `analyze-risks`. |
| `UNANALYZED-DERIVED <ID>` | Derived REQ/LLR never mentioned in the RMF | Run `analyze-risks`: assess hazard impact and record it (naming the ID) in the RMF's derived-requirements section. |
| `UNMITIGATED-HAZARD HAZ-…` | No risk control `mitigates:` this hazard | Run `analyze-risks` for this hazard; add the RC (or record the acceptability rationale and control in the RMF). |
| `UNIMPLEMENTED-CONTROL RC-…` | No requirement `implements:` this control | Grill the control into a testable REQ (`grill-requirements`); for non-software controls, note the external implementation in the RMF item and add the implementing REQ only if software plays a part. |
| `UNTRACED-DESIGN SDD-…` | Design item has no `traces:` to a REQ | Add the trace if the requirement exists; if none does, the item is speculative — delete it or grill the requirement into existence first. |
| `DANGLING-REF <ID>` | ID referenced but defined nowhere | Typo → fix the reference. Deleted item → remove or update every reference (deleting a defined item is a change requiring its own review). |
| `UNRESOLVED-PR PR-…` | Open problem report (**warning — never fails**) | Review it: still valid? Fix via `resolve-problem`, or leave open knowingly — the point is that every merge sees the list. |
| `DRAFT-ID …` / `DUPLICATE-ID …` (check-ids) | Drafts remaining / an ID defined twice | Drafts are fine mid-development (use `--allow-drafts`); at merge they're finalized by `merge-change`. Duplicates: keep one definition, re-mint the other as a fresh draft. |

## When to run

- After any edit to SRS/RMF/SAD/SOUP or to tests.
- Always inside `verify-before-merge` and `merge-change` (without
  `--allow-drafts` there — no drafts may reach main).
- In CI on every merge.
