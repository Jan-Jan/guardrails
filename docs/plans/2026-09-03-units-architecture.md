# Monorepo unit machinery — architecture

Date: 2026-09-03
Status: **designed; implementation follows via plan-change**

Designs the machinery decided in `2026-08-26-monorepo-support.md` (D1–D14)
under the controls of `docs/risk/2026-09-01-monorepo-derived-items.md`, whose
eight named test obligations bind here as requirements. Items below carry
descriptive labels, not minted SDD/LLR tokens: guardrails does not yet
self-host its own gates (`2026-08-22-ratchet-gap-analysis.md`), and token
minting follows self-hosting, as it does for the plan's REQs and the risk
file's HAZ/RCs.

Three architecture decisions were put to the user 2026-09-03; all three
resolved to the recommended option. They are recorded with their rejected
alternatives in the sections below: scope home (item 2), impact set (item 6),
`new-id.sh` unit selection (item 7).

## Shape

Two layers, split by where a conviction must land:

- **The unit-scope layer lives in `lib.sh`.** When `.guardrails/units.yaml`
  exists, a script invoked with a unit's config derives that unit's scan
  scope — own paths, plus the exported items of declared dependencies as
  *foreign definitions*, plus D10's narrow reverse edge — from shared
  helpers. Convictions that name a consumer's mistake (`NON-EXPORTED-REF`,
  `UNDECLARED-DEPENDENCY`, `UNMET-EXPECTATION`) land in the consumer's own
  `check-trace.sh` run, so a standalone per-unit run — tooth one, per the
  units-not-directories ADR — is exactly as honest as the orchestrated one.
- **`check-units.sh` holds only what has no single-unit home:** manifest
  validation, `UNCLAIMED-PATH`, dependency cycles, the class floor and its
  segregation citations, and the impact set.

Rejected: **a fat `check-units.sh`** classifying all cross-unit references in
one global pass, existing scripts untouched. A unit's standalone run would
still resolve references tree-wide — the exact false green D4 exists to
remove — and `MISPLACED-ITEM` needs scope hooks in `check-trace.sh` anyway,
so the "untouched" premise does not survive contact.

Rejected: **an environment contract** (`check-units.sh` computing scopes and
injecting them via `GR_FOREIGN_FILES` etc. into per-unit invocations). A bare
per-unit run then has no unit awareness at all; per-directory use would
silently run un-scoped, which is the units-not-directories ADR's finding
restated.

## Software items

### 1. Manifest reader and validator (`lib.sh`)

One parser for `.guardrails/units.yaml`, defined once for every consumer —
`check-units.sh`, the scope resolver, `new-id.sh` — for the reason
`GR_AWK_ID_RUN` has one definition: two near-copies is how readers drift.

The manifest has its own closed key set, validated exactly as
`gr_check_config` validates the config: `units:` (required, at least one
entry) and `not_a_unit:` (optional), both **list** keys under the config
grammar (column-one key, indented `  - item` lines, set once, no BOM, no bare
CR, trailing `#` comments stripped). Any other key is exit 2.

Entry rules, each exit 2 at validation:

- an entry is a repository-relative directory path — no globs, no trailing
  slash, not `.`, not reaching outside the repository;
- a `units:` entry names an existing tracked directory holding
  `.guardrails/config.yaml`, and that config passes `gr_check_config`;
- no path appears twice, in either list or across them;
- no unit is nested inside another unit or inside a `not_a_unit:` path
  (whole path components, D7's matching rule) — overlapping claims would
  give one file two scopes and every scoped gate two verdicts;
- the `depends_on:` graph over declared units is acyclic (worklist over flat
  lists, POSIX sh; motivation in D12) and every `depends_on:` entry names a
  declared unit other than its own.

Two repository shapes are exit 2 *outside* the manifest's own grammar,
because each is a false green waiting for a reader:

- **a root `.guardrails/config.yaml` alongside `units.yaml`** — two
  authorities over the same tree; every scan would have to guess which one
  scopes it;
- **two or more unit-shaped configs (`*/.guardrails/config.yaml`) with no
  manifest** — the D2 rejected-glob situation observed in the wild. The
  second config is invisible to every script today, which is a unit outside
  compliance at exit 0; detecting the shape and refusing it is what makes
  "not yet ratcheted" loud. Detected by `check-units.sh` (a tree scan is its
  job, not the library's).

### 2. Unit-scope resolver (`lib.sh`)

Answers, for one running script: *which unit am I, and what may I see?*

**Engagement rule.** If `units.yaml` is absent, nothing changes — every
script behaves exactly as today (single-unit repository). If it is present,
a **unit-scoped** script (`check-trace.sh`, `check-ids.sh`, `new-id.sh`,
`finalize-docs.sh`; the repository-level scripts are item 9) requires
`GR_CONFIG` to resolve to a declared unit's `.guardrails/config.yaml`;
the default root config path is then nonexistent by item 1's exclusivity
rule, and the resulting exit 2 message names the remedy ("this is a
multi-unit repository — run check-units.sh, or set GR_CONFIG to a unit's
config"). A `GR_CONFIG` pointing at a config that is not a declared unit's
is exit 2: scoping an undeclared config would invent a unit the manifest
never granted.

**Own scope.** The unit's directory subtree. A scoped unit's `doc_*`,
`strict_paths` and `test_paths` must resolve inside it — validated with the
config (item 1) — so two units' scans are disjoint by construction and
`MISPLACED-ITEM` never sees a sibling's items at all.

**Foreign definitions** (new concept, D4). For each `depends_on:` provider:
the IDs of REQ items in the provider's `doc_srs` whose block carries
`exported: yes`. Enumerated for reference resolution only — a foreign item
discharges no placement, trace, test or duplicate obligation of this unit
(risk obligation **reverse-edge-discharges-nothing** generalizes: no foreign
item discharges anything).

**Reverse edge** (D10, exactly as narrow as written). For each *consumer* —
a declared unit whose `depends_on:` names this unit — the IDs of REQ items
in the consumer's `doc_srs` carrying `expects: <this unit>`. Those items,
nothing else of the consumer. Risk obligations **reverse-edge-is-exactly-expects**
and **satisfies-across-wrong-edge-convicts** pin this: a provider reference
to any other consumer item classifies as if the crack did not exist, and a
`satisfies:` aimed at an expectation whose `expects:` names a different unit
falls outside the edge by the same rule — the second obligation is the first
one observed at a specific call site, and both convict `UNDECLARED-DEPENDENCY`.

**Resolution and classification.** A scoped reference resolves against: own
definitions ∪ foreign definitions ∪ reverse-edge items. One that does not
resolve classifies by where its definition actually lives (D4's table):

| Definition of the referenced ID | Verdict |
|---|---|
| own scope, or a foreign/reverse-edge item | passes |
| a declared dependency, not exported | `NON-EXPORTED-REF` |
| any other unit, exported or not | `UNDECLARED-DEPENDENCY` |
| a `not_a_unit:` path | `DANGLING-REF` — disclaimed means outside compliance; a definition there is prose, not an item; the message names the disclaimed file *(assessed 2026-09-03, control: **disclaimed-definition-names-its-path**)* |
| nowhere | `DANGLING-REF` |

### 3. Item annotations (grammar)

Read through `GR_AWK_ITEM_BLOCK` at column one inside an item block, like
`status:` and `opened:`, so the `ORPHAN-ANNOTATION` backstop sees what the
readers see:

- `exported: yes` — on a REQ block only. The only accepted value is `yes`;
  any other value, or the annotation on a non-REQ block, convicts
  `MISEXPORTED-ITEM` (D8: LLR and SDD are design data; a misspelled value
  read as "not exported" would strand consumers silently).
- `expects: <unit-path>` — on a REQ block. Naming a unit absent from this
  unit's `depends_on:` convicts `UNDECLARED-DEPENDENCY` and the D10
  MISSING-TEST exemption never engages (risk obligation
  **expects-undeclared-unit-convicts**).
- `opened: YYYY-MM-DD` — required on every expectation REQ (aging for the
  non-RC-linked, audit trail for the RC-linked, per D11). Absent or
  unparseable is `INCOMPLETE-EXPECTATION`, mirroring `INCOMPLETE-PROBLEM` —
  one token for every expectation the reader cannot read: it also covers an
  `expects:` on a non-REQ block and an `expects:` whose value is empty or
  not a path form, so no half of the expectation grammar has a silent
  failure mode.

An expectation's state is computed, never stored (D11): **met** iff the
named provider defines an exported REQ carrying `satisfies: <this ID>` —
both conditions, so satisfying with a non-exported REQ leaves it unmet,
failing toward conviction (risk file, safe-direction properties; obligation
**expectation-met-requires-export**).

### 4. `check-trace.sh` under scope

Changes engage only when the scope resolver does; an unscoped run is
byte-for-byte today's behavior.

- **`DANGLING-REF` becomes the four-way classification** of item 2. Same
  scan, three more accurate verdicts (D4's stated purchase).
- **`MISSING-TEST`**: a REQ carrying a valid `expects:` whose expectation is
  currently **unmet** is exempt (D10 — it cannot have a verifying test yet
  and is already reported once, accurately). Met, it is an ordinary REQ.
- **`UNMET-EXPECTATION <unit>: <ID>`** on the consumer's run. RC-linked
  (`implements: RC-…` on the block): exit 1 on every run (D11). Otherwise:
  ages from `opened:` against `expectation_age_days` /
  `expectation_open_max` via `gr_limit` — printed on every run set or not,
  exit 1 only past a limit, unparseable limit exit 2 — one summary line
  beside the `problems:` line it is modeled on.
- **Provider-side advisory** (D10): a scoped run also prints the open
  expectations standing against *this* unit, computed from the reverse edge
  and its own exports — `expectations against this unit: N open` — exit 0.
  The consumer's aging budget is the gate; this line is the courtesy on top
  (risk file, assessment 3 residual).
- **The summary reports its scope**: unit path, foreign and reverse-edge
  item counts. A scoped run must be visibly scoped — `checked:` totals that
  silently shrank would read as a tree that shrank.

### 5. `check-ids.sh` under scope

- **`DUPLICATE-ID` stays tree-wide.** IDs are one global namespace (the
  plan's established facts: collisions negligible, per-unit namespaces buy
  nothing), and a cross-unit duplicate must convict *somewhere* even when
  neither unit depends on the other. Tree-wide is the only scope that sees
  it, and the scan is read-only over definitions, so no false green rides on
  it.
- Draft tokens, draft-named ledger files and `MALFORMED-ID` narrow to own
  scope: a sibling's drafts are the sibling's change in flight, not this
  unit's finding — convicting them here would make any unit's merge block on
  every other unit's work in progress. A `not_a_unit:` path is then scanned
  by **no** run at all for these findings — deliberate (disclaimed means
  outside compliance, and `DUPLICATE-ID` still sees it tree-wide), but a
  coverage regression against today's tree-wide scans *(assessed
  2026-09-03: `check-units.sh` default mode convicts `DISCLAIMED-DRAFT` on
  draft tokens and DRAFT-named files under disclaimed paths, exit 1;
  `MALFORMED-ID` deliberately stays unscanned there — see item 6)*.

### 6. `check-units.sh` (new script)

The repository-level entry point (D5's provisional name confirmed). Modes:

- **default** — validate the manifest and every unit config (item 1; exit 2
  class), then the repo-level findings (exit 1 class): `UNCLAIMED-PATH`
  (D7: every tracked path claimed by a unit, disclaimed, or a root-level
  file); `MISCLASSED-DEPENDENCY` (D5: provider class below the ceiling of
  its consumers' classes) unless the consumer's `segregated_from:` covers
  that edge; `INCOMPLETE-SEGREGATION` (a `segregated_from:` entry not naming
  a declared dependency, or whose citation does not resolve — `(RC-…)` to a
  defined item, `(adr: <path>)` to an existing file). `safety_class: TBD`
  on either end of a dependency edge is exit 2 (D5: a floor computed from a
  placeholder is a gate disabling itself). Two scans added by the risk
  assessment of this design's derived decisions (amended 2026-09-03):
  `DISCLAIMED-DRAFT` (exit 1) — a draft token or DRAFT-named file under a
  `not_a_unit:` path; draft work has no legitimate home in a disclaimed
  directory, so the repository-level conviction blocking every unit's merge
  is the point. `MALFORMED-ID` is deliberately not scanned on disclaimed
  paths — legacy prose in definition shape would convict line by line and
  drive pattern-widening; the narrowness is gated
  (**disclaimed-prose-is-not-malformed**).
- **`--impact <range>`** — map the range's changed paths to units (touched),
  close transitively over reverse `depends_on:` (dependents, D12), print one
  unit per line with its reason (`touched` / `dependent`). A changed path
  claimed by no unit and not disclaimed is exit 2 pointing at
  `UNCLAIMED-PATH`; disclaimed paths map to no unit. `merge-change` consumes
  this mechanically — the D8 composed-chain obligations
  (**export-removal-convicts** and kin) test the chain *through this mode*.
- **`--exports <unit>`** — the unit's export surface: each exported REQ ID
  with its defining file. D8's "the export surface is then whatever
  `check-units.sh` reports" needs an owning mode, and this is it — the
  surface a consumer's verdicts resolve against and this listing must be
  the same computation (item 2's helpers), or the report lies about the
  gate.
- **`--list`** — the declared units, one per line, for callers that iterate
  (base-branch CI runs the union of all units; carried consideration 5).

The unclaimed-path condition appears in two exit classes on purpose: in
default mode it is the finding `UNCLAIMED-PATH` (exit 1 — a fact about the
tree, reportable alongside the other findings); in `--impact` it is exit 2,
because the mode's one job is a unit mapping the condition makes
uncomputable — reporting a partial impact set at exit 1 would hand
`merge-change` a list that reads complete. The message names the default
mode's finding as the remedy.

No manifest present: default mode exits 0 **after** the
multiple-configs-without-manifest scan (item 1) **and the near-miss
manifest scan** (amended 2026-09-03 by the risk assessment): a file in the
root `.guardrails/` — the manifest's own directory, the only place scanned —
in the near-miss class (`units.yml`, `unit.yaml`, case variants of
`units.yaml`) whose content is manifest-shaped — a top-level `units:` or
`not_a_unit:` key — is exit 2, message "did you mean
.guardrails/units.yaml". The repository root is deliberately not scanned:
that is where another tool's `units.yml` legitimately lives, so a wrong-
*directory* manifest there is accepted residual (risk assessment 2), not a
conviction. Only then exit 0, printing what it proved — `no units.yaml —
single-unit repository; no unit configs found astray`. *(The
exit-0-without-manifest shape: assessed 2026-09-03.)*

Rejected: **a separate impact script** — a second parser of the manifest
that must never drift from the first. Rejected: **skill-computed impact** —
the export-removal chain must be mechanically testable, and a skill step is
not.

### 7. `new-id.sh` unit selection

Resolves carried consideration 6. In a manifest repository the script must
validate *some* unit's config before minting; which one:

- inside a declared unit's directory (the caller's cwd before the script
  `cd`s to the root), that unit — the common case, no ceremony;
- `--unit <path>` selects explicitly; given and disagreeing with an
  explicit `GR_CONFIG`, exit 2 rather than guess;
- at the root or otherwise outside every unit with no `--unit`: exit 2
  listing the declared units. No inference beyond containment — a wrong
  guess mints an ID whose gates are another unit's.

Rejected: **argument-only** (ceremony on every mint, threaded through every
skill call site) and **`GR_CONFIG` only** (the manifest never consulted, so
minting against an undeclared config passes silently).

### 8. Schema and template deltas

- `GR_LIST_KEYS` += `depends_on`, `segregated_from`;
  `GR_KNOWN_KEYS` += `depends_on`, `segregated_from`,
  `expectation_age_days`, `expectation_open_max`. All four are per-unit
  config keys; `exports:` is **not** a key (D8 — it is the item annotation
  of item 3).
- `templates/config.yaml` ships the expectation limits **set** (risk file,
  assessment 1: an enforcement mechanism that defaults to off does not
  answer the finding): `expectation_age_days: 90`,
  `expectation_open_max: 10`. Ninety, not the problem ledger's thirty: an
  expectation is work owed by another team's backlog, and a budget teams
  cannot meet teaches them not to record expectations (D11's rejected
  always-exit-1, arriving on a delay). The values are policy; one line
  changes either; every run prints them, set or not.
- A units-aware `templates/units.yaml` with the grammar rules in comments,
  in the config template's voice.

### 9. Repository-level scripts under the engagement rule

The merged requirements (carried consideration 4) said `check-signing.sh`
and `check-review.sh` belong to no unit; the engagement rule must not
orphan them, and D6's **one verification record per change** needs a home.

- **`check-signing.sh`** — reads no config at all (verified against the
  script); operates on a commit range. Unchanged.
- **`check-review.sh`** — stays branch-keyed and repository-level. D6's
  record lives at the repository root `docs/verification/` — the record's
  subject is the change, not a unit, and that path is already the one
  `doc_*` location with a default. In a manifest repository the script
  validates the **manifest** (item 1's shared reader) in place of
  `gr_check_config` — there is no root config to validate, by item 1's
  exclusivity rule — and reads the defaulted root directory. Everything
  branch-shaped about it is untouched.
- **`finalize-docs.sh`** — unit-scoped by nature (it renames drafts inside
  one config's `doc_*` directories): `merge-change` runs it once per
  **touched** unit of the impact set, `GR_CONFIG` pointing at each. A
  cross-unit change's drafts sit in touched units by item 2's
  paths-inside-the-unit rule, so the loop over touched units renames all of
  them.

## Findings vocabulary added

| Finding | Exit | Script | Decision |
|---|---|---|---|
| `UNCLAIMED-PATH` | 1 | check-units | D7 |
| `MISCLASSED-DEPENDENCY` | 1 | check-units | D5 |
| `INCOMPLETE-SEGREGATION` | 1 | check-units | D5 |
| `NON-EXPORTED-REF` | 1 | check-trace (scoped) | D4 |
| `UNDECLARED-DEPENDENCY` | 1 | check-trace (scoped) | D4, D10 |
| `UNMET-EXPECTATION` | 1 (D11 rules) | check-trace (scoped) | D10, D11 |
| `INCOMPLETE-EXPECTATION` | 1 | check-trace (scoped) | D11 |
| `MISEXPORTED-ITEM` | 1 | check-trace (scoped) | D8 |
| `DISCLAIMED-DRAFT` | 1 | check-units | risk assessment 3 (2026-09-03) |
| near-miss manifest name | 2 | check-units | risk assessment 2 (2026-09-03) |
| manifest/config shape errors | 2 | check-units, lib | D2, D5, D12 |

## Test obligations

The eight inherited from `docs/risk/2026-09-01-monorepo-derived-items.md`
bind on the items above: **expects-undeclared-unit-convicts** (items 3, 4);
**export-removal-convicts**, **export-removal-reopens-expectation**,
**item-deletion-degrades-to-dangling**, **transitive-dependent-unaffected**
(items 2, 4, 6 — composed through `--impact`, end to end, not link by link);
**reverse-edge-is-exactly-expects**, **satisfies-across-wrong-edge-convicts**,
**reverse-edge-discharges-nothing** (item 2).

New obligations this design adds, named so the bats suite can carry them:

- **manifest-shape-errors-are-exit-2** — unknown key, scalar-form list,
  duplicate key/entry, missing unit directory or config, nested units: each
  exit 2, never a narrower scan (item 1).
- **cycle-is-exit-2** (item 1, D12's note).
- **root-config-with-manifest-is-exit-2**;
  **stray-unit-configs-without-manifest-are-exit-2** (items 1, 6).
- **scoped-run-convicts-standalone** — a consumer's bare `check-trace.sh`
  run, no orchestrator, convicts a sibling-internal reference (item 2; the
  scope-home decision's whole point).
- **unit-paths-outside-unit-are-exit-2** (item 2).
- **disclaimed-definitions-do-not-resolve** (item 2's table).
- **expectation-met-requires-export** (item 3).
- **unmet-rc-linked-expectation-exits-1**;
  **expectation-aging-mirrors-problem-limits** — printed set or not, exit 1
  past a limit, unparseable limit exit 2 (item 4).
- **missing-test-exemption-ends-when-met** (item 4).
- **misexported-item-convicts** (item 3).
- **duplicate-id-stays-tree-wide** (item 5).
- **impact-set-is-transitive**; **unrelated-unit-skips** (item 6).
- **unclaimed-path-convicts**; **root-files-implicitly-disclaimed** (item 6).
- **tbd-class-on-edge-is-exit-2**; **class-floor-convicts**;
  **segregation-citation-must-resolve** (item 6).
- **new-id-infers-unit-from-cwd**; **new-id-outside-unit-requires-flag**
  (item 7).
- **exports-mode-matches-resolution** — `--exports` and a consumer's
  verdicts are one computation: an ID the mode lists resolves, one it
  omits convicts (items 2, 6).
- **impact-unclaimed-path-is-exit-2** (item 6).
- **expects-grammar-errors-convict** — `expects:` on a non-REQ block or
  with an empty/malformed value is `INCOMPLETE-EXPECTATION`, never silence
  (item 3).
- **review-record-is-repository-level** — in a manifest repository
  `check-review.sh` runs with no unit config, validates the manifest, and
  finds the record at root `docs/verification/` (item 9).
- **finalize-runs-per-touched-unit** (item 9).
- **no-manifest-changes-nothing** — every existing test green with the
  machinery present and no `units.yaml` (item 2's engagement rule).

Added 2026-09-03 by the risk assessment of the derived decisions
(docs/risk/2026-09-03-units-architecture-derived.md):

- **disclaimed-definition-names-its-path** (item 2's table; assessment 1).
- **near-miss-manifest-name-is-exit-2** — each name in the near-miss
  class, manifest-shaped, in `.guardrails/`, no `.guardrails/units.yaml` →
  exit 2; the class, not one member;
  **near-miss-without-manifest-content-passes** — non-manifest content in
  `.guardrails/`, or manifest-shaped content outside it, convicts nothing
  (item 6; assessment 2).
- **disclaimed-draft-convicts-at-repo-level**;
  **disclaimed-prose-is-not-malformed** (item 6; assessment 3).

## Derived decisions, needing assessment (`analyze-risks`)

**Assessed 2026-09-03** (docs/risk/2026-09-03-units-architecture-derived.md): all
three carry controls, amended into items 2, 5 and 6 above; five test
obligations added to the list above. The list below stands as the record of
what was handed off.

1. **Disclaimed definitions do not resolve** (item 2). A reference to an
   item defined under `not_a_unit:` convicts `DANGLING-REF` although the
   text exists. Fails toward conviction, but the verdict names the wrong
   cause (a typo and a disclaimed definition read identically).
2. **`check-units.sh` exits 0 without a manifest** (item 6). Honest for the
   single-unit repository, but a mistyped `units.yml` is that exact shape;
   the stray-configs scan is the mitigation, and whether it is sufficient is
   a risk question, not a design one.
3. **Disclaimed paths are scanned by no run** (item 5). Today's
   `MALFORMED-ID` and draft scans are tree-wide; under scope, a draft token
   or malformed definition in a `not_a_unit:` path passes forever, even at
   the base-branch union of units. Same hazard shape as item 1 of this
   list, on the definition side rather than the resolution side.

## Outside this change

- Implementation (`plan-change` next; this document and the obligations are
  its input).
- Skill updates: `merge-change` (consume `--impact`), `/ratchet` (the D9
  facts interview writing the manifest and per-unit configs),
  `grill-requirements`/`design-architecture` (the D10 dependency-assessment
  interview, D13 glossary escalation).
- SOUP: no dependency changes; guardrails itself carries none.
