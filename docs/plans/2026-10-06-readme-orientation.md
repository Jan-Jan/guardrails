# README.md becomes orientation-only — Implementation Plan

**Goal:** `README.md` says what guardrails is, how to install it, how the
workflow runs, and where each rule lives. It states no rule of its own.
**Implements:** change 4 of the agent-first proposal
(`docs/plans/2026-09-28-agent-first-skills.md`, D1 and D3), which absorbed
churn-proposal D1. Resolves no problem item.
**Safety class:** the toolkit is unclassified; the class B rules in
`AGENTS.md` apply. Documentation, comments and tests only; no script behaviour
changes.
**Verification:** `sh tests/run-tests.sh`, dispatched to a subagent (AGENTS.md
non-negotiable 3). The verdict comes from the reported pass and fail counts.

**Base.** Branched from local `main` at `be4335a` on 2026-10-06. No other
change is open on `README.md`: the two parked worktrees (`churn-proposal`,
`parallel-session-proposals`) do not touch it on their branches' own commits.

Run single bats files with `tests/.bats-core/bin/bats <file>`, never with
`tests/run-tests.sh <file>`.

## Decisions

- **D1. What `README.md` keeps.** The opening paragraph and the regulatory
  disclaimer; `## Install`; `## The workflow` with its diagram, the three rules
  each cut to one or two sentences of what, not how, and the paragraph on
  dispatching within a change cut likewise; a `## Check scripts` table with one
  line per script, saying what it is for and pointing to the script's header;
  a short `## Where the rules live` section naming the owners below;
  `## Development`, `## Credits`, `## License`.
- **D2. What leaves, and where it goes.** Each rule in the sections below moves
  to the owner named. Where the owner already states the rule, the README's
  copy is deleted. Where it does not, the rule is written into the owner first,
  in the owner's voice, and then deleted from the README.

  | README material | Owner |
  | --- | --- |
  | ID and trace grammar table, the token alphabet, document ledgers | the ledger READMEs (`templates/srs.md`, `rmf.md`, `sad.md`, `problems.md`), `scripts/new-id.sh` header, `worktree-discipline` steps 5–6 and `references/rationale.md` |
  | Per-script detail in the Check scripts table | that script's header comment |
  | Annotation list reading, item open and close, `ORPHAN-ANNOTATION` | `check-traceability` step 5–6, `references/item-blocks.md`, `scripts/check-trace.sh` header |
  | Monorepos | `merge-change/references/multi-unit.md`, `ratchet/references/multi-unit.md`, `scripts/check-units.sh` header, `docs/plans/2026-09-03-units-architecture.md` |
  | The review artefact (presence not quality, the record found by content, `reproduced:` never judged, finding shape) | `scripts/check-review.sh` header, `merge-change/references/rationale.md` |
  | Config: unmatched entries, validation, value shapes | `check-traceability/references/config.md` |
  | Scan exclusion of `.guardrails/scripts/` | `scripts/check-trace.sh` / `lib.sh` header, `check-traceability/references/config.md` |
  | `MISPLACED-ITEM` and its caveats | `check-traceability` step 7, `scripts/check-trace.sh` header |
  | One definition form, `gr_def_re`, `GR_ID_BODY`, the two hand-written patterns | `scripts/lib.sh` / `check-ids.sh` / `check-trace.sh` comments |
  | Safety class in config | `ratchet` |

- **D3. History is not moved.** Narration of what used to be true
  (`finalize-ids.sh`, the third reader, sequential numbering, three attempts to
  summarise the scan matrix) is incident history. AGENTS.md keeps that in
  `docs/plans/` and git, so it is deleted, not moved.
- **D4. No owner grows past its ceiling.** `merge-change` and `ratchet` stand
  at 2,000 words, `worktree-discipline` at 1,997. Nothing moves into those
  three `SKILL.md` files; material for them goes to their `references/`.
- **D5. Tests move with their rules** (proposal D4).
  - `merge-step-3-reports-rewrites` (verifies `PR-58zsvf`) pins
    `DANGLING-FILE`, `reported as left` and `root-relative` in `README.md`.
    These are `finalize-docs.sh` behaviours; the pins move to that script's
    header, which states them.
  - `assesses-is-the-remedy` (verifies `PR-n274s7`) lists every place that
    tells an author how to assess. After this change `README.md` tells no
    author anything, so it leaves that list. The templates and both skills
    stay pinned.
  - The negative scans that include `README.md` (`owner:`, `merge.date`) stay:
    they hold for the cut file too.
- **D6. Comments that cite `README.md` as a rule's home are repointed**, for
  example `scripts/check-trace.sh` near the `MISPLACED-ITEM` roster.
- **D7. Out of scope.** Plan pruning, `check-review.sh --cite` and the
  design-controls section stay with `churn-proposal` (proposal D1). A rule that
  must appear on two surfaces gets a generated block in a later change.

## Tasks

### T1 — Move every README rule to its owner, cut the README, move the pins

**Files touched:** `README.md`; script header comments in `scripts/*.sh`;
`skills/*/references/*.md`; `skills/check-traceability/SKILL.md` if needed;
`templates/*.md` if needed; `tests/skills.bats`; this plan's Progress section.

1. For each paragraph and table row of `README.md` below `## The workflow`'s
   diagram, grep its owner (D2) for the rule. Record the result in a mapping
   table in the Progress section below: README material, owner file, and
   `already stated` or `moved`.
2. Write each `moved` rule into its owner. Comments in `scripts/*.sh` only;
   change no executable line. Before editing a script, grep
   `docs/verification/*mutations*` and `tests/mutations*` for the lines you
   would touch; a mutation anchor quotes script lines.
3. Cut `README.md` to D1.
4. Move the test pins (D5), and repoint comments (D6).
5. Run `tests/.bats-core/bin/bats tests/skills.bats` and
   `tests/.bats-core/bin/bats tests/portability.bats`; both pass.

## Progress

T1 done. `README.md` is 746 words (`wc -w README.md`), down from 4,644.

| README material | Owner file | Result |
| --- | --- | --- |
| Rule 1 detail: base branch is the primary checkout's, never assumed `main` | `skills/merge-change/SKILL.md` Preconditions; `scripts/lib.sh` `gr_base_branch` | already stated |
| Rule 2 detail: `finish-merge.sh` guards before removal | `scripts/finish-merge.sh` header | already stated |
| Dispatch paragraph: task worktrees, dispatcher merges, gate log outside the tree | `skills/worktree-discipline/SKILL.md` steps 1, 8; `skills/verify-before-merge/references/rationale.md`; `AGENTS.md` non-negotiables 1, 4 | already stated |
| ID grammar table, rows REQ/HAZ/RC/SDD/LLR/PR | `templates/srs.md`, `rmf.md`, `sad.md`, `problems.md` | already stated |
| ID grammar table, test-link row (lowest level, transitive REQ) | `templates/sad.md`; `scripts/check-trace.sh` header `MISSING-TEST` | already stated |
| Random tokens minted once, not a content hash | `scripts/new-id.sh` header; `skills/worktree-discipline/references/rationale.md` step 5 | already stated |
| Token alphabet and the digit rule | `scripts/lib.sh` ID body comment; the four ledger templates | already stated |
| Sequential IDs keep working | `scripts/lib.sh` `GR_ID_BODY` comment | already stated |
| Document ledgers: draft file, dated rename, edit in the defining file | the four ledger templates; `scripts/finalize-docs.sh` header | already stated |
| Same-day collisions get `-2` | `scripts/finalize-docs.sh` header | moved |
| `soup.md` single file; `doc_*` accepts a single file | `templates/sad.md`; `scripts/check-trace.sh` header | already stated |
| Check scripts row `new-id.sh`: redraw on collision | `scripts/new-id.sh` header | already stated |
| Check scripts row `new-id.sh`: undeclared prefix rejected, no entropy means no mint | `scripts/new-id.sh` header | moved |
| Check scripts row `find-items.sh` | `scripts/find-items.sh` header | already stated |
| Check scripts row `find-items.sh`: `doc_soup` inside `doc_sad` read once | `scripts/find-items.sh` header | moved |
| Check scripts row `check-ids.sh` | `scripts/check-ids.sh` header | already stated |
| Check scripts row `check-trace.sh` | `scripts/check-trace.sh` header | already stated |
| Check scripts row `check-units.sh` | `scripts/check-units.sh` header | already stated |
| Check scripts row `check-review.sh`: reports | `scripts/check-review.sh` header | already stated |
| Check scripts row `check-review.sh`: `checked:` line, exit 2 on the base branch | `scripts/check-review.sh` header | moved |
| Check scripts row `check-signing.sh`: verdicts | `scripts/check-signing.sh` header | already stated |
| Check scripts row `check-signing.sh`: `--setup` settings, throwaway-repository proof | `scripts/check-signing.sh` header | moved |
| Check scripts row `check-signing.sh`: ratchet will not complete until it passes | `skills/ratchet/SKILL.md` | already stated |
| Check scripts row `finish-merge.sh` | `scripts/finish-merge.sh` header | already stated |
| Check scripts row `finalize-docs.sh`: root-relative and bare-name rewrite, emphasis and glued names, plans left alone | `scripts/finalize-docs.sh` header | already stated |
| Check scripts row `finalize-docs.sh`: shared bare name reported as left; relative link left for `DANGLING-FILE` | `scripts/finalize-docs.sh` header | moved |
| Check scripts row `finalize-docs.sh`: was `finalize-ids.sh` | none (D3 history) | deleted |
| Check scripts row `merge-preflight.sh` | `scripts/merge-preflight.sh` header | already stated |
| Check scripts row `task-worktree.sh` | `scripts/task-worktree.sh` header | already stated |
| Annotations read as lists, one definition | `scripts/check-trace.sh` header (annotation rule) | already stated |
| Item open and close, colon rule, annotations above a bold label | `skills/check-traceability/SKILL.md` step 5; `references/item-blocks.md` | already stated |
| Close broader than open; `MALFORMED-ID`; `ORPHAN-ANNOTATION` | `references/item-blocks.md`; `scripts/check-trace.sh` header; `scripts/check-ids.sh` header | already stated |
| Monorepos: opt-in manifest, scoped runs, exported REQs, `NON-EXPORTED-REF`, `UNDECLARED-DEPENDENCY`, `UNMET-EXPECTATION` | `scripts/check-units.sh` header; `scripts/check-trace.sh` header; `skills/merge-change/references/multi-unit.md`; `docs/plans/2026-09-03-units-architecture.md` | already stated |
| Review artefact: why the gate exists; presence, never quality | `scripts/check-review.sh` header | already stated |
| Review artefact: record found by content, first `branch:` line, written by this change | `scripts/check-review.sh` header | moved |
| Review artefact: `reproduced:` value never judged | `templates/verification.md`; `scripts/check-review.sh` header | already stated (template), moved (header) |
| Review artefact: finding shape, `disposition:` not bold, `MALFORMED-FINDING`, `ORPHAN-DISPOSITION` | `templates/verification.md`; `scripts/check-review.sh` header | already stated |
| Review artefact: byte-wise test, gawk regex failure | `scripts/check-review.sh` body comment | already stated |
| Review artefact: two limits (only this change's record; `doc_verification` default) | `scripts/check-review.sh` header; `scripts/lib.sh` `gr_verification_dir` | moved (header) |
| Config: an entry matching nothing is exit 2; pathspecs; plain `doc_*` paths | `skills/check-traceability/references/config.md` | already stated, except that a `doc_*` value is not a pathspec: moved after review finding-3 |
| Config validated: misspelled key, column one, BOM, no gated prefix, unconfigured inputs | `skills/check-traceability/references/config.md` | already stated |
| Config value-shape table (seven rows) | `skills/check-traceability/references/config.md` | already stated |
| Config: CRLF read correctly; no compatibility flag; unrecognised key; every gate validates, `check-ids.sh` included | `skills/check-traceability/references/config.md` | moved |
| Config: extra prefix alongside the six | `skills/check-traceability/references/config.md`; `scripts/check-trace.sh` header | already stated |
| Scans exclude `.guardrails/scripts/` only; ledgers under `.guardrails/` read | `scripts/lib.sh` `GR_SCAN_EXCLUDE`; `skills/check-traceability/references/config.md` | already stated (lib.sh), moved (config.md) |
| Invisible locations accepted, `checked:` zero, matrix, do not configure a ledger there | `scripts/lib.sh` `GR_SCAN_EXCLUDE`; `skills/check-traceability/references/config.md` | already stated (lib.sh), moved (config.md) |
| Three attempts to summarise the matrix; measured before tokens | none (D3 history) | deleted |
| Symlink inside the repository scanned under its real path | `skills/check-traceability/references/config.md` | moved |
| `MISPLACED-ITEM`: rule, six prefixes, one level deep, `.txt` | `skills/check-traceability/SKILL.md` step 7; `scripts/check-trace.sh` header and `check_placement` comment | already stated |
| `MISPLACED-ITEM` caveats: enumeration kept, `DANGLING-REF` scope, HAZ blinds `UNANALYZED-DERIVED` | `scripts/check-trace.sh` `check_placement` comment | already stated |
| `MISPLACED-ITEM` remedy; illustrative IDs indented | `scripts/check-trace.sh` header; ledger templates | already stated |
| One definition form, `gr_def_re`, `GR_ID_BODY`, awk parsers | `scripts/lib.sh` `gr_def_re` comment; `scripts/check-trace.sh` | already stated |
| Two hand-written patterns | `scripts/lib.sh` `gr_def_re_loose`; `scripts/check-trace.sh` derived-assessment comment | deleted: both are stale (MALFORMED-ID now uses `gr_def_re_loose`; the derived search now reads `assesses:` lines) |
| Two behavioural tests (poison `gr_def_re`, widen `GR_ID_BODY`) | `scripts/lib.sh` `gr_def_re` comment | moved |
| The third reader (`finalize-ids.sh`); moved definitions under sequential IDs | none (D3 history) | deleted |
| What this does not yet cover: extra prefixes not placement-checked | `scripts/check-trace.sh` header; `skills/check-traceability/SKILL.md` step 7 | already stated |
| Safety class in config | `skills/ratchet/SKILL.md` step 4; `templates/config.yaml` | already stated |

Tests (D5): `merge-step-3-reports-rewrites` greps `scripts/finalize-docs.sh`;
`assesses-is-the-remedy` drops its `README.md` line. Comment (D6):
`scripts/check-trace.sh` `check_placement` no longer names `README.md`.
