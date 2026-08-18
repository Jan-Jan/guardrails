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

Run from the repo root. Each violation is one line: `<RULE> <ID> (<detail>)`.
Fix the artifact, never the checker.

Every run ends with two summary lines — what it found, and what it read:

```
checked: REQ 90, HAZ 4, RC 7, SDD 20, LLR 23, PR 63
sources: srs 18, rmf 6, sad 4, soup 1, problems 35; strict 5, tests 3
```

*(Illustrative figures — your project's will differ.)*

(The document figures are file counts; `strict` and `tests` count configured
path entries, since one entry may be a directory or a pathspec.)

**Read both lines before believing the verdict.** Exit 0 with only these two
lines above it is clean. `REQ 0` on a project that has requirements, or
`rmf 0` on a project that has an RMF, means the checker found nothing and
proved nothing — a config or layout problem, not a pass. `checked:` alone is
not enough: it counts items found anywhere in the tree, while `sources:`
counts the files the gate for those items actually opened.

**Two known gaps, both deliberate and both recorded in the plan.**

*`checked:` counts items found anywhere in the tree*, which is not yet proof
that a gate read them — an item defined outside its configured document is
counted here and examined by nothing. Treat a surprising count as a prompt to
check where those items are defined.

*A missing or misspelled config key reads as "this project does not use
that"*, and no gate complains. `doc_rmff:` disables every hazard gate;
`test_path:` disables `MISSING-TEST`; `strict_path:` drops half of
`DANGLING-REF`; a config carrying none of these keys runs every gate off and
still exits 0. **This is what `sources:` is for** — a zero there for a
document or path list the project does have is the symptom, and it is the
reason to read that line rather than only the exit status.

**Exit 2 is an environment error and always fatal**, because each of these
would otherwise let a gate pass without running:

| Message | Cause |
|---|---|
| `doc_rmf is configured as 'docs/risk', which does not exist` | A configured path that is absent. |
| `doc_rmf is configured as directory 'docs/risk', which contains no *.md files` | A ledger directory with nothing in it — including the case where the `*.md` files sit in a **subdirectory**, since `doc_*` directories are read one level deep only. |
| `id_prefixes entry is not a bare identifier: PR[` | A prefix is interpolated into every scan pattern; a metacharacter makes the pattern invalid, and a scan that errors finds nothing — indistinguishable from a clean tree. |
| `strict_paths entry matches no file present in the working tree: src/*.rs` | A `strict_paths`/`test_paths` entry matching nothing. These are **git pathspecs** — a plain path, or a pattern like `*_test.sh` that git matches recursively. An entry matching nothing scans nothing, and an empty directory matches no file. |

Fix the config; never work around it by removing the prefix.

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
| `SKIPPED-DUPLICATE-BASE` (check-ids) | **Not a violation.** There is no usable base branch — a detached HEAD, or one with no commits — so the "already defined on the base" half of `DUPLICATE-ID` did not run | Nothing, if you are not merging. Before a merge, pass `--base REF` so that gate runs. The line exists because a gate that did not run must not look like one that passed. |

## When to run

- After any edit to SRS/RMF/SAD/SOUP or to tests.
- Always inside `verify-before-merge` and `merge-change` (without
  `--allow-drafts` there — no drafts may reach the base branch).
- In CI on every merge.
