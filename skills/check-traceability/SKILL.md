---
name: check-traceability
description: Run and interpret the guardrails traceability checker - orphaned requirements, unmitigated hazards, unimplemented controls, untraced design, dangling references. Use after documentation or code changes and always before merging.
---

# Check Traceability

**Announce at start:** "Using the check-traceability skill."

## Preconditions

- Run it after any edit to the SRS, RMF, SAD, SOUP or tests, inside
  `verify-before-merge` and `merge-change`, and in CI on every merge.
- Run every command from the repository root.

## Steps

1. **Run both checkers.**

   ```sh
   .guardrails/scripts/check-trace.sh              # traceability gates
   .guardrails/scripts/check-ids.sh --allow-draft-files  # ID sanity while developing
   ```

   At the merge, run `check-ids.sh` without `--allow-draft-files`: no ledger
   file with a draft name may reach the base branch.

2. **Read the exit status.** Exit 2 is an environment error and always fatal:
   a gate did not run. Read `references/config.md`, fix the config, and run
   again. Never work around it by removing a prefix from `id_prefixes`.

3. **Read both summary lines before believing the verdict.** Every
   `check-trace.sh` run ends with what it found and what it read:

   ```
   checked: REQ 90, HAZ 4, RC 7, SDD 20, LLR 23, PR 63, ADR 5
   sources: srs 18, rmf 6, sad 4, soup 1, problems 35; strict 5, tests 3
   ```

   *(Illustrative figures — your project's will differ.)* The document figures
   are file counts; `strict` and `tests` count configured path entries, since
   one entry may be a directory or a pathspec.

   - Exit 0 with only these two lines is clean.
   - `REQ 0` on a project that has requirements, or `rmf 0` on a project that
     has an RMF, means the checker found nothing and proved nothing. It is a
     config or layout problem, not a pass.
   - Read `sources:` as well as `checked:`. `checked:` counts items found
     anywhere in the tree; `sources:` counts the files the gate for those items
     opened. A zero in `sources:` for a document the project has means its key
     is absent from the config; read `references/config.md`.

4. **Fix each violation in the artifact, never in the checker.** Each violation
   is one line: `<RULE> <ID> (<detail>)`. A run that completes then prints one
   line per rule that fired, after the violation lines and before the summary
   lines (`check-ids.sh` prints no summary lines). A run that exits 2 part-way
   prints none:

   ```
   fix <RULE>: <what to do>
   ```

   Follow that line. Where it ends `— see the script header`, the finding has
   more than one cause, and the header of the script that printed it
   documents each rule in full: `.guardrails/scripts/check-trace.sh` for the
   traceability and problem-report rules, `.guardrails/scripts/check-ids.sh`
   for `DRAFT-ID`, `DRAFT-FILE`, `DUPLICATE-ID` and `MALFORMED-ID`.

5. **Write item bodies to the block rule.** An item block opens at its
   definition form and closes at the next markdown heading or the next bold
   line that contains an ASCII colon. `**Step 7**:`, `**Decision 7**:`,
   `**LLR-overflow:**` and `**Rationale**:` all close a block, whether or not
   they are valid items. `**21 of 35 inverted, 14 not.**` contains no colon and
   closes nothing; a full-width colon (U+FF1A) is not an ASCII colon.

   - Put an item's annotations above any bold label with a colon in its body.
     The label starts a new block, and annotations below it belong to no item.
   - Write annotations with no list marker. Inside a block, a bulleted
     annotation such as `- status: open` is a missing field: the item is
     `INCOMPLETE-PROBLEM`, the record `MISSING-RECORD`. Drop the marker. An
     annotation on the definition line is valid, as in `templates/sad.md`:
     `**SDD-…**: <software item>. traces: REQ-…`.
   - `check-ids.sh` reports `**REQ-abcdef**:` as `MALFORMED-ID`.

6. **Read `ORPHAN-ANNOTATION` as an annotation that belongs to no item.** It
   fires before the first item in a file, under a heading with no item since,
   and inside a block opened by a prefix whose gate does not read that keyword,
   such as a `traces:` line inside an `**LLR-…**` block. Move the annotation
   into the item it belongs to. Read `references/item-blocks.md` when an
   annotation in a list, quote or table is credited or reported where you did
   not expect it.

7. **Read `MISPLACED-ITEM` as an item in the wrong document.** Each of the six
   gated prefixes may be defined in one document only: `REQ` in `doc_srs`,
   `HAZ` and `RC` in `doc_rmf`, `SDD` and `LLR` in `doc_sad`, `PR` in
   `doc_problems`. While that gate is green, every item of those six in
   `checked:` is in a document some gate opened. An item of any other declared
   prefix is counted without being examined.

## Red flags

| Thought | Reality |
|---|---|
| "Exit 0, it passed" | Read `checked:` and `sources:` first. A zero there is a run that examined nothing (step 3). |
| "Exit 2 on one prefix, I'll drop it from `id_prefixes`" | Exit 2 means a gate did not run. Fix the config; removing the prefix also removes its references from `DANGLING-REF` (step 2). |
| "The checker is wrong about this item, I'll adjust the script" | Fix the artifact, never the checker (step 4). |
| "I'll bullet the annotations so the item reads better" | A bulleted annotation is not read inside a block; the field is reported missing (step 5). |
| "A bold note in the item body is harmless" | A bold line with a colon closes the block; annotations below it belong to no item (step 5). |
| "`--allow-draft-files` at the merge too" | No ledger file with a draft name may reach the base branch (step 1). |

## Done when

- Both checkers exit 0 with no violation lines.
- `checked:` and `sources:` show a non-zero figure for every document and item
  kind the project has.
- Every violation was fixed in the artifact, never in the checker. An exit 2
  was fixed in the config (step 2).

## References

- `references/config.md` — read when a run exits 2, when a `sources:` figure is
  zero, or before editing `.guardrails/config.yaml`.
- `references/item-blocks.md` — read when an annotation is credited to the
  wrong item or reported where you did not expect it, or before writing an
  annotation in a list, quote or table.
