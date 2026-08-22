---
name: check-traceability
description: Run and interpret the guardrails traceability checker - orphaned requirements, unmitigated hazards, unimplemented controls, untraced design, dangling references. Use after documentation or code changes and always before merging.
---

# Check Traceability

**Announce at start:** "Using the check-traceability skill."

```sh
.guardrails/scripts/check-trace.sh              # traceability gates
.guardrails/scripts/check-ids.sh --allow-draft-files  # ID sanity while developing
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
not enough on its own: it counts items found anywhere in the tree, while
`sources:` counts the files the gate for those items actually opened.

**`MISPLACED-ITEM` is what ties the two together.** Each of the six gated
prefixes is checked against the one document it may be defined in
(`REQ`→`doc_srs`, `HAZ`/`RC`→`doc_rmf`, `SDD`/`LLR`→`doc_sad`,
`PR`→`doc_problems`), so while that gate is green every item in `checked:`
sits in a document some gate opened. It covers those six only — an item of an
extra declared prefix is still counted without being examined.

A misspelled or misplaced config key no longer belongs on that list: the
config is validated, and the shapes below are exit 2. Three things it still
does not catch, worth knowing rather than trusting blindly:

- a **duplicate** key or list block is accepted and the later one ignored;
- `strict_paths` and `doc_soup` are required by no prefix, so omitting either
  quietly narrows what `DANGLING-REF` scans — `sources:` is the tell;
- dropping a prefix from `id_prefixes` does **not** switch its gates off —
  `MISSING-TEST` is keyed on `test_paths` and the rest on the document lists,
  so all of them keep firing. What it removes is that prefix from `checked:`
  and from `DANGLING-REF`'s scope, so references to it stop being checked
  while its other gates carry on.

`sources:` remains worth reading: a zero there for a document the project does
have means the key is absent, since a configured-but-empty ledger directory is
itself exit 2.

**Exit 2 is an environment error and always fatal**, because each of these
would otherwise let a gate pass without running:

| Message | Cause |
|---|---|
| `doc_rmf is configured as 'docs/risk', which does not exist` | A configured path that is absent. |
| `doc_rmf is configured as directory 'docs/risk', which contains no *.md files` | A ledger directory with nothing in it — including the case where the `*.md` files sit in a **subdirectory**, since `doc_*` directories are read one level deep only. |
| `id_prefixes entry is not a bare identifier: PR[` | A prefix is interpolated into every scan pattern; a metacharacter makes the pattern invalid, and a scan that errors finds nothing — indistinguishable from a clean tree. |
| `unknown config key(s): doc_rmff` | A typo'd key. Nothing reads it, so the gate it was meant to configure silently never runs. |
| `config line(s) that are neither a comment, a top-level key, nor a '  - item' belonging to one` | A key that is not `identifier:` at column one (`strict-paths:`, ` strict_paths:`, `strict_paths :`); a list item at column zero; or a list item **orphaned** from its key by a column-one comment or a `---` separator above it. An orphan is ambiguous — it either vanishes with its list or is adopted by the block above — so it is rejected rather than guessed at. Commenting a list key out means commenting its items out too. |
| `config begins with a UTF-8 BOM` | The BOM makes the first key unreadable, i.e. silently absent. |
| `id_prefixes names no prefix with a traceability gate` | At least one of REQ, HAZ, RC, SDD, LLR, PR must appear. Extra prefixes alongside them are fine — `DANGLING-REF`, `DUPLICATE-ID` and ID finalization are keyed on the whole prefix list, so they are checked, just not by a gate of their own. Without any of the six the only checks left are those, and a config that also omits the document keys runs nothing at all. |
| `id_prefixes declares RC but doc_srs is not configured` | A declared prefix needs the documents its gates READ, which is not always where it is defined: `UNIMPLEMENTED-CONTROL` looks for a REQ that implements each RC, so RC needs `doc_srs`. |
| `id_prefixes declares RC but doc_rmf is not configured` | A prefix also needs the one document it may be DEFINED in, because `MISPLACED-ITEM` reads it. A control lives in the RMF, so `RC` needs `doc_rmf` as well — unconfigured, every control in the project would be misplaced. |
| `id_prefixes declares REQ/LLR but test_paths is empty` | Nothing would be searched for `verifies:`. |
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
| `MISPLACED-ITEM <ID>` | Item defined outside the document configured for its prefix. It is still *enumerated* — `MISSING-TEST` and the rest fire on it exactly as on a placed item — but the gate that would convict it on its own annotations parses only the configured document, so a misplaced `SDD` carries no `traces:` obligation and a misplaced `PR` can never be reported open. Two caveats worth knowing: `DANGLING-REF` scans every `doc_*` file plus `strict_paths` and `test_paths`, so an item misfiled into *another* ledger still has its reference IDs read — by that gate, not by its own; and a `HAZ` block carries no annotation of its own that a gate parses, yet moving it out of the RMF still blinds `UNANALYZED-DERIVED`, which greps the RMF as free text — a derived item assessed inside a hazard's block stops being assessed when that block leaves (it fails red, so nothing passes silently) | Move the definition into that document — `REQ`→`doc_srs`, `HAZ`/`RC`→`doc_rmf`, `SDD`/`LLR`→`doc_sad`, `PR`→`doc_problems`. Adding the stray file to `strict_paths` does **not** fix it: that widens reference scanning, not the document a gate opens. A `doc_*` directory resolves to its `*.md` files **one level deep**, so a `.md` in a subdirectory of it reports — and so does a `.txt` sitting directly in it. A `doc_*` configured as a single *file* resolves to that file whatever its extension. If the ID is illustrative text rather than a real item, indent it or keep it inline — no definition scan matches a form off column one. Do **not** leave `**REQ-NNN**:` at the start of a line: no gate reads it as a definition, but `MALFORMED-ID` reads it as one that failed, which is the correct answer to a line that looks exactly like a real item. |
| `UNRESOLVED-PR PR-…` | Open problem report (**warning — never fails**) | Review it: still valid? Fix via `resolve-problem`, or leave open knowingly — the point is that every merge sees the list. |
| `DRAFT-ID …` (check-ids) | A draft ID token (`REQ-DRAFT-<branch>-<n>`) left in the tree. **Always a failure**, under every flag: nothing mints one any more, so nothing would ever turn it into a real ID | Run `.guardrails/scripts/new-id.sh <PREFIX>` and replace the token with what it prints. |
| `DRAFT-FILE …` (check-ids) | A `DRAFT-<branch>-<slug>.md` ledger file. Legitimate while the change is in flight — `--allow-draft-files` suppresses it — and renamed by `finalize-docs.sh` at merge | Nothing mid-change. At merge, run `merge-change` step 3. |
| `DUPLICATE-ID <ID>` (check-ids) | One ID defined at two sites in the tree | Keep one definition and mint a fresh ID for the other. Two random tokens colliding is possible but vanishingly unlikely; a copy-pasted item is the usual cause. |
| `MALFORMED-ID <ID>` (check-ids) | A line opening with a definition form whose body is not a valid ID — a hand-typed token with no digit, or a legacy ID too short to have ever matched. The item it announces defines nothing and no gate is keyed on it, so every other check passes over it in silence | Give the item an ID from `new-id.sh`. Never widen a pattern to accept the one that is there: the whole point of the digit and the six-character length is that ordinary prose cannot be mistaken for an ID. |

## When to run

- After any edit to SRS/RMF/SAD/SOUP or to tests.
- Always inside `verify-before-merge` and `merge-change` (without
  `--allow-draft-files` at the merge — no draft-named ledger file may reach
  the base branch).
- In CI on every merge.
