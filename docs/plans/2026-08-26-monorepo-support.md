# Monorepo support — requirements

Date: 2026-08-26
Status: **interview complete; D1–D14 decided**

Guardrails assumes one compliance unit per git repository. Every script does
`cd $(git rev-parse --show-toplevel)` and reads one `.guardrails/config.yaml`;
`safety_class` is one scalar; `doc_*` is one file or one directory one level
deep. This document records the requirements for repositories holding several
units.

The decisions below are prose with embedded `shall` examples, not REQ items:
guardrails does not yet self-host its own gates (see
`2026-08-22-ratchet-gap-analysis.md`), so `new-id.sh` cannot run here. Minting
REQs from this document will be a deliberate rewrite into single-behavior
`shall` items, not a token stamp.

## Established facts (read from the scripts, not assumed)

| Fact | Consequence |
|---|---|
| Every script `cd`s to `git rev-parse --show-toplevel` and reads `.guardrails/config.yaml`; `GR_CONFIG` overrides the path | One config per repository. A second config can be invoked but nothing knows it exists |
| `doc_*` resolves to one file, or a directory's `*.md` one level deep | A root config gives every package one shared ledger set |
| `safety_class` appears in `GR_KNOWN_KEYS` and nowhere else | No script reads the class. It is enforced by skills and humans, so per-unit classes cost nothing in gate terms |
| Item IDs are random six-character tokens with at least one digit | Cross-unit collision is negligible; per-unit ID namespaces buy nothing |
| `ids_defined` scans the whole tree (`git grep -- .`) | Every gate keyed on "is this ID defined anywhere" already sees all units |
| MISPLACED-ITEM convicts any item defined outside the `doc_*` its prefix resolves to | **Blocker for naive per-unit configs**: from unit A's config, every REQ in unit B is misplaced |
| DANGLING-REF resolves its definition set tree-wide | A cross-unit reference resolves today, silently, with no declared dependency. This is a false green |
| `verify_commands`, `strict_paths`, `problem_open_max`, `problem_age_days` are single flat lists or scalars | One test command and one problem budget for the whole repository |
| Nothing in the repo mentions monorepos | Unaddressed, not half-built |

## Decisions

### D1 — The repository may hold several independent systems

A monorepo under guardrails may contain several compliance units, each its own
IEC 62304 software system with its own safety class, requirements ledger and
release. Packages-as-software-items within one system remains supported and
needs no new machinery; this document is about the multi-unit case.

**The units are only partially independent.** One unit may consume another's
API or packages. The unit boundary, not the unit list, is the hard part.

### D2 — Units are enumerated in a root manifest

`.guardrails/units.yaml` at the repository root names each unit. Each unit
keeps an ordinary, fully valid `.guardrails/config.yaml` of its own.

```
# .guardrails/units.yaml
units:
  - packages/pump
  - packages/monitor
  - platform/hal
```

```
# packages/pump/.guardrails/config.yaml
safety_class: C
doc_srs: packages/pump/docs/requirements
strict_paths:
  - packages/pump/src
```

Rejected: **discovery by convention** (globbing for `*/.guardrails/config.yaml`).
A package that never got a config would be outside compliance while the run
exits 0, and nothing could distinguish "not a unit" from "not yet ratcheted".
That is the failure class the closed config schema exists to prevent.

Rejected: **a `units:` key in the root config**. The config schema is closed and
validated; a file valid only *without* `id_prefixes` and `doc_*` gives every
validation rule an "unless this is a manifest" branch — more places for a rule
not to run. A separate manifest gets its own small validator and leaves
`gr_check_config` untouched.

Rejected: **`GR_CONFIG` alone**. The unit list would live only in a CI file,
where nothing validates it.

A dependency cycle between declared units is exit 2 at manifest validation
(stated here where the manifest is defined; motivated in D12's implementation
note): the units would not be partially independent at all, and every gate
built on the edge direction reads ambiguously.

**Open, not yet decided:** whether every tracked path must be claimed by some
declared unit (unowned code as a failure) or whether unowned paths are
grandfathered the way untraced code is today. Deferred to its own question.

### D3 — A consumed unit is a supplied component, incorporated by reference

The provider keeps its own SRS, safety class and tests. A consumer declares the
dependency and may trace to the provider's **exported** requirements only.

```
# packages/pump/.guardrails/config.yaml
safety_class: C
depends_on:
  - platform/hal

# platform/hal/.guardrails/config.yaml
safety_class: C          # floor raised by its Class C consumer
exports:
  - platform/hal/docs/requirements/interface.md
```

`satisfies: REQ-h4m2p9` in pump's SRS is valid when `REQ-h4m2p9` is defined in
an exported file of a declared dependency. `satisfies: LLR-h9x3k1`, naming a
hal internal, is not.

Rejected: **SOUP** (`doc_soup` already exists, so this ships today with zero new
machinery). It treats a component built and tested in this repository as
off-the-shelf, discards the provider's requirement and test evidence, and no
gate would notice a Class A library beneath a Class C device.

Rejected: **a software item of every consumer**. Class propagation falls out for
free, but the provider gets no independent identity or release — contradicting
D1 — and shared code is documented once per consumer.

Rejected: **one root SRS, units partitioning `strict_paths` only**. Cross-unit
references are trivially valid, but the safety class cannot then differ per
unit, so the highest class in the repository governs all of its code.

### D4 — A unit's scans see its own paths plus its dependencies' exports

Scope for every tree-wide scan in a unit's run is that unit's own `doc_*`,
`strict_paths` and `test_paths`, **plus** the exported files of each declared
dependency. Items in those exported files are **foreign**: enumerated, so
references to them resolve, but exempt from this unit's placement and trace
gates. Foreign definitions are a new concept in the toolkit and the reason this
option costs more than the alternatives.

It buys three accurate findings where there is one blunt one:

| Reference from pump | Verdict |
|---|---|
| `REQ-h4m2p9` — exported by declared dependency `platform/hal` | passes |
| `LLR-h9x3k1` — defined in `platform/hal`, not exported | `NON-EXPORTED-REF` |
| `REQ-m0n1t2` — defined in `packages/monitor`, not a declared dependency | `UNDECLARED-DEPENDENCY` |
| `REQ-zzz9zz` — defined nowhere | `DANGLING-REF` |

Rejected: **own subtree only** (one `unit_root:` key, simplest possible change).
Every legitimate cross-unit reference becomes `DANGLING-REF`, indistinguishable
from a typo, so teams would switch the gate off — worse than not shipping the
feature.

Rejected: **whole tree with a manifest-aware MISPLACED-ITEM** (smallest diff, no
new scope concept). A unit's trace obligations could then be discharged by files
it does not own, and nothing would distinguish an exported item from an
internal one, so a provider could not refactor without silently breaking a
consumer.

Rejected: **whole tree unchanged**. `exports:` would be prose no gate reads.

### D5 — The class floor is enforced; declared segregation is the only escape

A provider unit whose class is below the highest class among its consumers is
exit 1 (`MISCLASSED-DEPENDENCY`), unless the **consumer** declares segregation
naming the risk control or ADR that argues it:

```
# packages/pump/.guardrails/config.yaml
segregated_from:
  - platform/hal (RC-k3n8p2)
```

This matches IEC 62304 §5.3.5, which permits a software item to carry a lower
class than the system containing it *when segregation is demonstrated*, without
letting the mismatch pass in silence. The parenthesised token is load-bearing,
not commentary: the manifest validator (D2) must verify the entry names a
declared dependency of this unit AND that the RC or ADR it cites exists —
`(RC-…)` resolving like any reference (a dangling one is the classic
false-green shape), `(adr: docs/adr/….md)` naming a file that is present.
An entry with neither is INCOMPLETE-SEGREGATION, exit 1. The escape is per-edge and auditable, and
follows the toolkit's existing pattern: the gate stays on and the exception is a
recorded decision.

Rejected: **an absolute floor**. Simplest and unarguable, but it pushes Class C
rigor onto a logging library, and the rational response is to fork that library
out of the monorepo — which loses the evidence altogether.

Rejected: **advisory only**. A warning nobody must act on becomes something to
scroll past. That is the finding that made `problem_age_days` and
`problem_open_max` ship enabled rather than commented out.

Rejected: **not checked**.

Two consequences worth stating:

- **This is the first script to read `safety_class`.** It appears in
  `GR_KNOWN_KEYS` and nowhere else today, so the key has never been load
  bearing. From here it is.
- **`safety_class: TBD` on either end of a dependency edge must be exit 2**, not
  a passing comparison. The sentinel means the interview never happened, and a
  floor computed from it would be a gate disabling itself on a placeholder.

The gate needs a repository-level entry point that no current script provides —
provisionally `check-units.sh`, reading `.guardrails/units.yaml` and each unit's
config. It is the natural home for D2's manifest validation too.

### D6 — A change may span units; one record; the impact set must pass

One signed squash commit and one verification record per change, as today. The
record names the units the change touches. `merge-change` runs the gates and
`verify_commands` of every **touched** unit plus every unit that **depends on** a
touched one, and skips the rest.

```
branch: hal-flow-rate-units
units touched: platform/hal, packages/pump

impact set (computed from depends_on:)
  platform/hal      touched
  packages/pump     touched + dependent
  packages/monitor  dependent of hal

runs:  hal, pump, monitor gates + their verify_commands
skips: unrelated units
```

This keeps atomic cross-unit changes — the reason to have a monorepo — keeps one
commit per change, and derives the impact set from `depends_on:` without asking
a human to judge it.

Rejected: **one record per touched unit**. Per-unit evidence is more faithful,
but the merge is still one commit, so `check-review.sh` — which keys on the
branch — would have to locate and judge N records for one branch, and a reviewer
would sign off N times on one diff.

Rejected: **one unit per change**. The cleanest evidence trail and no impact
analysis, but a breaking interface change cannot then be atomic: the provider
merges first and consumers are knowingly inconsistent until they catch up.

Rejected: **run every unit on every change**. Unarguable, and an unrelated
unit's pre-existing red blocks all work while runtime grows with the repository.

**Derived, needs assessment:** whether the impact set is the transitive closure
of `depends_on:` or one hop only. Transitive is the safe reading — a consumer may
re-export a provider's behavior through its own interface and no scan can tell
whether it does — but it makes a change to a widely used platform unit run
nearly every unit in the repository, which is D6's rejected fourth option
arriving by the back door. Not decided here.

### D7 — Every tracked path is claimed by a unit or explicitly disclaimed

The manifest carries a `not_a_unit:` list alongside `units:`. A tracked path
matching neither is exit 1 (`UNCLAIMED-PATH`).

```
# .guardrails/units.yaml
units:
  - packages/pump
  - platform/hal
not_a_unit:
  - docs
  - tools
  - .github
  - packages/legacy-ui   # migrating, 2026-Q4
```

This makes "not yet ratcheted" distinguishable from "deliberately outside" —
the exact distinction D2's rejected glob option could not make — and the
disclaim list becomes a visible, reviewable inventory of what sits outside
compliance.

Matching semantics: `units:` and `not_a_unit:` entries are directory paths,
matched as whole leading path components (`docs` claims `docs/adr/x.md`, never
`docs-site/`). Tracked files sitting directly at the repository root
(`README.md`, `LICENSE`, `.gitignore`, the manifest itself) are implicitly
disclaimed — units are directories, and forcing every root file into the list
would bury the entries that mean something.

Rejected: **requiring a justification on each disclaim entry**. It is the
strongest guard against the list becoming where inconvenient code hides, and
worth revisiting, but it adds a parser and friction on every new `tools/`
directory.

Rejected: **grandfathering unowned paths**, consistent though it is with
tightening one tooth at a time: a new package would be silently outside
compliance until someone remembered it.

Rejected: **report-only inventory**, for the reason given in D5.

### D8 — An export is an item annotation, not a file list

**This corrects the sketch in D3.** That example wrote:

```
exports:
  - platform/hal/docs/requirements/interface.md
```

which cannot work on a ledger-layout project. New items go into *this change's*
dated file (`DRAFT-<branch>-<slug>.md`, renamed by `finalize-docs.sh`), never
into a stable hand-curated file — that convention is what stops parallel
worktrees from conflicting. An `interface.md` collecting exported requirements
would either be edited by every change that adds one, reintroducing the
conflicts the ledger exists to prevent, or hold references rather than
definitions, and a reference is not a definition to any gate here.

So an export is declared where the item is written, in the same grammar as
`satisfies:`, `traces:` and `verifies:`:

```
**REQ-h4m2p9**: The software shall reject a flow rate above 1200 mL/h.
exported: yes
```

The export surface is then whatever `check-units.sh` reports, not a file anyone
maintains. Only `REQ` items may be exported: `LLR` and `SDD` are design data,
and D4's `NON-EXPORTED-REF` exists precisely to keep a consumer off them.

**Derived, needs assessment:** an item's export status can now be *removed* by
editing the dated file that defines it, which silently breaks every consumer
tracing to it. The `DANGLING-REF` gate will not catch it — the item still
exists. `NON-EXPORTED-REF` catches it only when the consumer's unit is in the
impact set, and D6 computes that from `depends_on:`, which still names the
provider, so the consumer *is* in the set. Believed covered; not verified.

## Considerations carried, not yet decided

These surfaced during the interview and are recorded so they are not
rediscovered later.

1. **Impact-set transitivity** (from D6). **Resolved by D12**: transitive.
2. **Glossary scope.** **Resolved by D13**: per-unit glossaries, root owns
   interface terms; interviews write to the unit glossary by default.
3. **Problem ledger and its limits.** Per-unit budgets come free (the limits
   are per-config). **Resolved by D14**: filed in the provider's ledger only.
4. **Repository-wide gates.** `check-signing.sh` operates on a commit range and
   is unit-agnostic — it needs no change. `check-review.sh` keys on the branch,
   which D6 preserves. Neither belongs to a unit.
5. **CI shape.** With D6's impact set, CI must compute the touched units from
   the diff. On the base branch there is no change under review, so the
   repository-level run is the union of all units — the existing note that
   `check-review.sh` is not a base-branch gate applies unchanged.
6. **`new-id.sh` needs a unit.** It calls `gr_check_config`, so minting an ID
   inside a monorepo requires knowing which unit's config to validate. Either
   it infers the unit from the cwd or it takes the unit as an argument.

## Best practices for a monorepo under guardrails

Falling out of D1–D8:

- **Draw unit boundaries at release boundaries, not at package boundaries.** A
  unit is what you ship and certify as one system. Packages inside it are
  software items in its SAD, which needs no new machinery.
- **Make the platform unit's class the highest class it serves**, or write the
  segregation argument (D5). Deciding this late is expensive: raising a unit's
  class retroactively means producing evidence for work already done.
- **Keep the export surface small.** Every exported requirement is a contract a
  consumer traces to, and D4 makes the internals genuinely unreachable — which
  is the point. A wide surface gives that up voluntarily.
- **Disclaim deliberately and revisit** (D7). A `not_a_unit:` entry for a
  package under migration should carry the date or ticket, even though D7 does
  not require it.
- **Prefer one unit per change** even though D6 permits several. The
  cross-unit change exists for breaking interface changes; using it routinely
  means the impact set is nearly the whole repository on every merge.
- **Ratchet one unit at a time.** The manifest with one unit and everything
  else disclaimed is a valid, passing configuration, and it is the honest
  first tooth on a repository of twelve packages.

### D9 — `/ratchet` declares the facts; the rules are not configurable

The user's proposal is adopted, with the line drawn where the toolkit already
draws it. `/ratchet` interviews and writes the project's **facts**:

| Asked | Written to |
|---|---|
| One system in many packages, or many systems? | mode; a single-unit project gets no manifest |
| What are the units? | `units:` in `.guardrails/units.yaml` |
| What does each unit depend on? | `depends_on:` in each unit's config |
| What is each unit's safety class? | `safety_class:` — the Step 4 interview, repeated per unit |
| What is outside compliance, and why? | `not_a_unit:` |
| Is any dependency segregated, and under which control? | `segregated_from:` in the consumer |

It does **not** ask whether the class floor applies, whether a unit may reach
into another's internals, or which units run at merge. Those are D4, D5 and D6,
and each exists because the alternative is a passing run that proves less than
a passing run elsewhere while nothing in the output says so. The config schema's
own design notes rule that out by name: *"there is no compatibility flag,
deliberately… almost every shape above was a gate that did not run, so an
opt-out would be a supported way to keep a false green."*

Rejected: **per-gate enforcement knobs** (`class_floor: enforce|warn|off`,
`cross_unit_refs: strict|permissive`, `impact_set: transitive|direct|all`). They
would fit every team's appetite and ease adoption on a large existing repo,
which is the honest case for them — and each `off` is exactly the false green
above.

Rejected: **prescribing the layout too**, which would force manifest ceremony
onto a repository that is genuinely one system split into packages.

Rejected: **keeping `/ratchet` out of it**. The per-unit safety-class interview
is the part most likely to be skipped, and it is the input to D5.

Adoption stays a ratchet, and — **confirmed 2026-08-31** — the decisions above
are a tooth ordering, not a package:

- **Tooth one, mandatory:** D2 + D4 + D7 — the manifest, per-unit configs, and
  unit-scoped scans. This is per-directory use, done safely: a unit with an
  empty `depends_on:` is a freestanding guardrails project that happens to
  share a repository. A manifest naming one unit with everything else
  disclaimed is a valid, passing configuration, and the honest first tooth on
  a repository of twelve packages.
- **Later teeth, adopted when the coupling bites:** D3 (`depends_on:` +
  exports), D5 (class floor), D6 (impact set), D10/D11 (expectations). Each
  becomes load-bearing only once a unit declares its first dependency edge —
  before that there is nothing for those gates to read, so "not yet adopted"
  is visible in the manifest rather than being a switched-off gate.

Per-directory use as a *permanently unchecked* endpoint was considered and
rejected: it is the per-gate knob of the second option in a different hat. The
difference between "tooth one, no edges declared yet" and "coupling
deliberately unchecked" is that the former is visible in the manifest.

## Schema notes (guardrails 0.5.1)

Restated against `590867a`, which closed the config schema further. The new keys
must obey the rules that commit added:

- `units:`, `not_a_unit:`, `depends_on:` and `segregated_from:` are **list**
  keys: indented `  - item` lines, nothing after the colon. Written in scalar
  form (`depends_on: platform/hal`) they are read by nobody — the shape
  `GR_LIST_KEYS` now rejects. They must be added to `GR_LIST_KEYS` and
  `GR_KNOWN_KEYS`, and `.guardrails/units.yaml` needs its own key set.
- Each is set **once**; a second block is rejected.
- `exports:` is **not** a config key — D8 makes it an item annotation.

Two facts this document rests on, re-verified against 0.5.1:

- `safety_class` still appears exactly once in `lib.sh`, in `GR_KNOWN_KEYS`.
  D5 makes it load bearing for the first time.
- `ids_defined` still scans `git grep -- .`, the whole tree. D4 is what narrows
  it.

## Alternative considered: independent per-directory use

Raised after D9: "use guardrails separately in each component directory —
start the session in the component, not the repo root." Examined against the
scripts rather than dismissed:

- **It does not run today.** Every script does `cd "$(gr_root)"` — the git
  toplevel, wherever the session started — and reads `.guardrails/config.yaml`
  there. A config inside the component is never found (exit 2). A component's
  config at the repo root works only until a sibling writes its first item,
  which then reports MISPLACED-ITEM from this config's point of view.
- **`GR_CONFIG` per unit is the best naive variant, and is wrong both ways:**
  MISPLACED-ITEM still convicts every sibling's items (`ids_defined` scans the
  whole tree), and DANGLING-REF resolves against that same whole tree, so a
  reference into a sibling's internals passes silently.
- **The minimum fix is D2 + D4.** Per-unit configs the scripts can locate,
  plus unit-scoped scans, is both the naive mode made to work and this
  proposal's first tooth. The two approaches share their foundation; they
  differ only in whether the coupling is also checked.
- **What the naive mode is genuinely better at:** nothing repo-wide to
  maintain, per-team adoption pace, one unit's red never blocks another's
  merge (under D6, a provider's change runs its consumers' suites — a
  dependent's flaky test then blocks the provider), constant gate runtime, and
  a smaller qualified-tool surface.
- **What it cannot do:** check any consequence of partial independence.
  Cross-unit references, class propagation, the atomic cross-unit change, and
  unowned paths are exactly the D3–D7 gates, and exactly where the units
  couple.
- **Polyrepo is the honest endpoint of the naive instinct** — one repo per
  component, guardrails unchanged, working today. Right when components are
  fully independent; ruled out here by the stated constraint that one service
  relies on another's API, which polyrepo answers with version skew and
  sibling-as-SOUP.

**Resolution: the proposal is adopted as a tooth ordering, not a package.**
Tooth one is D2 + D4 (manifest, per-unit configs, unit-scoped scans); a unit
with an empty `depends_on:` is the per-directory mode, done safely. D3/D5/D6
are later teeth, adopted when the coupling bites. This is the strongest ADR
candidate of the change: hard to reverse (the manifest and scan scoping shape
every config), surprising without context (the scripts LOOK like they would
work per-directory), and a real trade-off (autonomy and blast radius against
checked coupling).

### D10 — A gap in a dependency is an expectation: a consumer REQ the provider must satisfy

Raised as: when assessing a dependency's ADRs, HAZ items and other artefacts
against a consumer requirement, the assessment may conclude the dependency
does not meet it — and that verdict should prompt what must be developed in
the provider.

The gap is a requirement, so it gets requirement machinery. A consumer REQ
carries `expects: <unit>`, naming a declared dependency:

```
# pump's SRS
**REQ-p7k2m4**: The software shall rely on platform/hal to bound
actuator slew rate to ≤ N mL/h². (implements: RC-d4x8n2)
expects: platform/hal
```

The expectation is **met** when the provider defines an **exported** REQ
carrying `satisfies: REQ-p7k2m4`. Until then:

- the consumer's run reports `UNMET-EXPECTATION platform/hal: REQ-p7k2m4`;
- the provider's run lists the open expectations standing against it — the
  prompt lands on the team that owes the work, not only the team waiting.

Risk-control flow-down composes without touching existing gates: the RC is
implemented by the expectation REQ in the consumer's own SRS, so
UNIMPLEMENTED-CONTROL is unchanged; the cross-unit hop happens one level down.

**This is the first crack in D4's one-way visibility, accepted knowingly.**
The provider's acknowledgment (`satisfies: REQ-p7k2m4`) references a consumer
item, and the consumer is not in the provider's `depends_on:`. The scope rule
gains one narrow reverse edge: a provider's scans also see the `expects:`
items of units that declare it as a dependency — those items only, nothing
else of the consumer.

Rejected: **a problem report in the provider's ledger**. Reuses triage
wholesale (opened date, age, backlog limits), but a need is not an anomaly: the
provider's problem budget would fill with other teams' feature demands, and
the consumer's requirement must exist separately anyway, recording the gap
twice.

Rejected as the *mechanism*, adopted as *skill guidance*: **a dependency
assessment record per edge**. The consultation the idea names — the provider's
exports, its RMF (does its risk analysis consider my use?), its ADRs (a
recorded decision may foreclose my requirement), its open problem reports
(the known anomalies of a supplied component, in 62304 terms), and
transitively its SOUP — belongs in `grill-requirements` and
`design-architecture` as the interview to run when declaring `depends_on:`.
Its output is `expects:` items, which are what the gates then track. A
mandatory record without a driving gate is a snapshot nothing re-opens.

Rejected: **skill guidance alone** — the gap would be invisible to every run
the day after the conversation ends.

Mechanical consequence, decided here — **derived, needs assessment**
(`analyze-risks`): an **unmet** expectation REQ is exempt from MISSING-TEST.
It creates the one class of REQ that can sit in an SRS with neither a test nor
a MISSING-TEST conviction (non-RC-linked, inside its aging budget). The
exemption exists because the item cannot have a verifying test yet and is already
reported once, accurately, as UNMET-EXPECTATION; convicting it twice is noise
pointing at the wrong remedy. The moment it is met, MISSING-TEST applies
normally, and the right test is the consumer's integration test against the
provider's real behavior.

**Open — decided next:** the severity of UNMET-EXPECTATION. Always exit 1
would block every consumer merge until the provider delivers, which teaches
teams not to record expectations at all.

### D11 — Severity of an unmet expectation follows its safety relevance

An unmet expectation that `implements:` a risk control is **exit 1 on every
run of the consumer's checks** — not merge-time only, exactly as the problem
limits it is modeled on fail every `check-trace.sh` run: shipping the consumer
without its control is what D5 exists to prevent. The escapes are the honest ones — implement an interim
control locally, or re-analyze the risk (`analyze-risks`) and record why the
control can wait.

Every other unmet expectation carries an `opened: YYYY-MM-DD` and ages against
two config limits, `expectation_age_days` and `expectation_open_max`, exactly
as problem reports do: printed on every run whether set or not, exit 1 only
past the limit, a value that cannot be parsed is exit 2 rather than "no
limit". The severity rule reads an annotation the item already carries; no new
judgment is asked of anyone at check time.

Rejected: **always exit 1** — the consumer becomes hostage to the provider's
queue for merges unrelated to the gap, and the rational adaptation is to stop
recording expectations, defeating D10.

Rejected: **never exit 1** — a safety-relevant gap could sit inside the budget
while the consumer ships: an unimplemented risk control inside a passing run.

Rejected: **blocking the provider** — pressure would land where the work is
owed, but every consumer then holds a veto over the provider's unrelated
merges, for demands the provider never agreed to.

Consequences:

- `expectation_age_days` / `expectation_open_max` join the per-unit config
  schema (scalars, optional, same parse rules as the problem limits). Being
  per-unit config, each consumer sets its own tolerance.
- An expectation, unlike a problem report, needs no `status:` — its state is
  computed: met when a dependency's exported REQ satisfies it, open otherwise.
  Nothing to forget to update, nothing to triage by hand.
- The RC-linked case needs `opened:` too, not for aging but for the audit
  trail of how long the control stood unimplemented.

### D12 — The impact set is the transitive closure of dependents

Resolves the derived item left open in D6. Impact = touched units plus all
transitive dependents; unrelated subtrees skip.

The deciding fact is about builds, not contracts. The tempting one-hop
argument — each hop's green run re-certifies its exported contract for the
next hop — is sound for requirements and unsound for binaries: a transitive
consumer ships the provider's changed object code, and a green intermediate
run proves only that the intermediate's tests pass, not that the paths the
transitive consumer exercises through it are unaffected. Contract verification
insulates requirements; it does not insulate linked code.

A platform change therefore legitimately runs everything above it. That is
its actual blast radius, and the cost lands as the right incentive: keep
platform churn low, prefer one-unit changes (the best-practice list already
says so). This differs from D6's rejected run-everything option in exactly the
way that matters: propagation follows declared edges, so an unrelated subtree
never pays for it.

Rejected: **one hop, contract-sealed** — trusts the intermediate unit's test
coverage to be complete, which no coverage is.

Rejected: **transitive for code, one hop for docs-only changes**. Precise and
cheaper, but it needs a mechanical docs-only classifier that must never err
toward "docs" — a build script outside `strict_paths` would slip through
silently. Recorded as a possible later refinement, not a launch behavior;
if it comes, the classifier must fail toward "code".

Rejected: **an `impact_set:` config key** — the per-gate knob D9 rejects, by
name.

Implementation note: transitive closure over `depends_on:` is a worklist loop
over flat lists — comfortably POSIX sh. A dependency cycle between units must
be exit 2 when the manifest is validated (D2): the closure would still
terminate, but a cycle means the units are not partially independent at all,
and every gate built on the edge direction (D4 scope, D5 floor, D10 reverse
visibility) reads ambiguously.

### D13 — Per-unit glossaries; the root glossary owns interface terms

Each unit keeps its own `docs/CONTEXT.md` for internal vocabulary. The root
`docs/CONTEXT.md` defines every term that crosses an exported interface.
Interviews (`grill-requirements`, `analyze-risks`) write to the unit's
glossary by default and escalate a term to root the moment it appears in an
exported REQ or an `expects:` item.

The conflict rule keeps its teeth exactly where divergence is dangerous: a
term defined in a unit glossary AND at root with different meanings is
challenged — **a skill rule for the interviews, not a check**, for the same
reason as the exported-term rule below: "different meanings" has no mechanical
definition, and a guessing gate convicts good items. Two units disagreeing
internally is not a conflict at all —
"dose" in an infusion unit and in a reporting unit are different concepts,
legitimately.

Rejected: **one namespaced root glossary** — every unit's internal jargon in
one shared, high-traffic file, reintroducing the merge conflicts the ledger
model exists to prevent, with nothing marking which terms are interface
contracts.

Rejected: **per-unit only** — the word in an exported requirement then means
whatever each side's glossary says, which is the interface misunderstanding a
glossary exists to prevent.

Rejected: **per-unit plus a no-overlap gate** — convicts the legitimate
internal divergence too, so teams rename concepts to dodge a gate.

Not gated at launch: "a term in an exported REQ must be defined at root" is a
skill rule, not a check — a term extractor over prose is guesswork, and a
guessing gate convicts good items. Revisit only if drift is observed.

### D14 — A provider's defect is filed in the provider's ledger, whoever finds it

Resolves the carried problem-ledger question, as a consequence of D10/D11
rather than a new decision. A consumer discovering an anomaly in a dependency
files the PR item in the **provider's** `doc_problems` — the anomaly lives
where the code lives, the provider's `opened:` triage and budget age it
(authorship is git blame's answer, per `860dce4`), and D6 already permits a change to write into another unit's ledger. If
the consumer cannot wait, its own recourse is local and already specified: an
interim risk control, or an `expects:` item (D10) whose severity D11 governs.
One anomaly, one record; the consumer's ledger never carries a copy.
