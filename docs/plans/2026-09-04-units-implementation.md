# Monorepo Unit Machinery Implementation Plan

**Goal:** Implement the unit machinery designed in
`2026-09-03-units-architecture.md` — manifest, scope resolver, `check-units.sh`,
scoped gates, unit-aware minting — such that a repository without
`.guardrails/units.yaml` behaves byte-for-byte as today.

**Implements:** no minted REQ/RC/SDD IDs — guardrails does not yet self-host
its own gates (`2026-08-22-ratchet-gap-analysis.md`). The binding contract is
the architecture's **test-obligations list** (41 named obligations: 8 inherited
from `docs/risk/2026-09-01-monorepo-derived-items.md`, 28 added by the
architecture, 5 added by `docs/risk/2026-09-03-units-architecture-derived.md`).
Every obligation name appears verbatim in at least one bats test title, so the
audit is mechanical (see "Obligation audit" below).

**Safety class:** n/a — guardrails is a development tool; the projects it
gates are class A–C. The bats suite is the evidence.

**Verification:** `sh tests/run-tests.sh` — the full suite green at `336cfeb` is
the baseline; every task adds tests and ends with the full suite green (the count grows task by task).

---

## Scope and its edges

In scope: `scripts/lib.sh` (manifest reader/validator, scope resolver, schema
keys), `scripts/check-trace.sh` and `scripts/check-ids.sh` under scope,
`scripts/check-units.sh` (new), `scripts/new-id.sh` unit selection,
`scripts/check-review.sh` and `scripts/finalize-docs.sh` under the engagement
rule, `templates/units.yaml` (new), `templates/config.yaml` deltas,
`tests/helpers.bash` fixtures, one new bats file per new scan family, README
rows for the new script and findings.

Outside (per the architecture's own list): skill updates (`merge-change`
consuming `--impact`, `/ratchet` writing the manifest, the D10 interview),
SOUP (no dependency changes).

## Engagement rule — the one invariant every task must preserve

If `.guardrails/units.yaml` is absent, **nothing changes**: every script runs
today's code path, and the existing 475 tests are the proof (obligation
**no-manifest-changes-nothing**). Every new behavior in `check-trace.sh`,
`check-ids.sh`, `new-id.sh`, `finalize-docs.sh` and `check-review.sh` sits
behind `gr_units_present` / `[ -n "$GR_UNIT" ]`. A task that cannot keep the
old path byte-identical is wrong, not "close enough".

## Implementation decisions taken here (within the architecture, recorded for the review)

The architecture leaves these to the implementation; each is decided once,
here, so no task re-decides it:

1. **Manifest entries may not contain whitespace** (exit 2 at validation).
   lib's list plumbing is IFS-newline-safe, but unit paths are interpolated
   into `case` patterns, git pathspecs and `expects:` values, where an
   embedded blank would make one entry read as two. Rejecting it is the same
   move `finalize-docs.sh` makes for draft file names.
2. **Overlap is rejected in every direction** — a unit inside a unit, a unit
   inside a disclaimed path, a disclaimed path inside a unit, and a disclaimed
   path inside a disclaimed path are all exit 2. The architecture's stated
   rule names the unit-nesting cases; its stated *reason* ("one file two
   scopes, every scoped gate two verdicts") condemns all four, and the
   remaining two are the same defect with the lists swapped.
3. **A unit config may not set `doc_verification`.** The record is
   repository-level (architecture item 9); `check-review.sh` in a manifest
   repository reads the defaulted root `docs/verification` and no script ever
   reads a unit's `doc_verification` — a key read by nobody is the exact shape
   `gr_check_config` exists to refuse, so the manifest validator refuses it.
4. **Implicitly repository-level paths** for `UNCLAIMED-PATH`: tracked files
   directly at the root (D7's rule) and the root `.guardrails/` directory —
   the manifest's own home, which D7 already names implicitly ("the manifest
   itself"). Nothing else: `docs/` (root glossary, verification records) is
   disclaimed explicitly, exactly as D7's worked example does.
5. **`--impact` maps a change under root `.guardrails/`** (manifest, installed
   scripts) **to every unit, reason `touched`** — a tool or manifest change
   has every unit in its blast radius, and the safe direction is to run them.
   Root-level files map to no unit (implicitly disclaimed, same as default
   mode).
6. **Flag modes require the manifest.** `--impact`, `--exports` and `--list`
   without `.guardrails/units.yaml` are exit 2 naming the single-unit fact —
   never an empty exit-0 list, which a CI caller would read as "no units to
   run" and skip everything.
7. **`EXPECTATION-BACKLOG`** is the count-limit finding
   (`expectation_open_max` exceeded), mirroring `PROBLEM-BACKLOG` exactly; the
   age limit fails through `UNMET-EXPECTATION` itself carrying `limit N`. The
   architecture prescribes "via gr_limit … one summary line beside the
   `problems:` line it is modeled on" without naming the count token; the
   model answers it. Flag in the verification record as a vocabulary addition.
8. **An empty-valued `exported:` or `expects:` convicts** (`MISEXPORTED-ITEM`
   / `INCOMPLETE-EXPECTATION`), never "counts as absent": for these two
   annotations absent means *not exported* / *no expectation*, so an empty
   value is an omission wearing the shape of compliance — the false-green
   direction.
9. **Foreign and reverse-edge REQ IDs resolve references; own enumerations
   never include them.** `traces:`/`satisfies:` naming an exported foreign REQ
   is D3's point and stays valid; what a foreign or reverse item can never do
   is appear in `checked:`, owe or discharge MISSING-TEST, satisfy placement,
   or join the duplicate scan's *own-scope* half (the tree-wide DUPLICATE-ID
   still sees everything).
10. **Scan-failure direction:** an empty foreign/reverse set (e.g. a provider
    ledger that fails to parse dies exit 2 via command substitution `|| exit 2`
    at every call site; a filter that yields nothing) fails **toward
    conviction** — unresolved references convict — never toward a pass.

## Obligation audit

Every named obligation appears verbatim in a test title. After the last task:

```sh
for ob in expects-undeclared-unit-convicts export-removal-convicts \
  export-removal-reopens-expectation item-deletion-degrades-to-dangling \
  transitive-dependent-unaffected reverse-edge-is-exactly-expects \
  satisfies-across-wrong-edge-convicts reverse-edge-discharges-nothing \
  manifest-shape-errors-are-exit-2 cycle-is-exit-2 \
  root-config-with-manifest-is-exit-2 stray-unit-configs-without-manifest-are-exit-2 \
  scoped-run-convicts-standalone unit-paths-outside-unit-are-exit-2 \
  disclaimed-definitions-do-not-resolve expectation-met-requires-export \
  unmet-rc-linked-expectation-exits-1 expectation-aging-mirrors-problem-limits \
  missing-test-exemption-ends-when-met misexported-item-convicts \
  duplicate-id-stays-tree-wide impact-set-is-transitive unrelated-unit-skips \
  unclaimed-path-convicts root-files-implicitly-disclaimed \
  tbd-class-on-edge-is-exit-2 class-floor-convicts \
  segregation-citation-must-resolve new-id-infers-unit-from-cwd \
  new-id-outside-unit-requires-flag exports-mode-matches-resolution \
  impact-unclaimed-path-is-exit-2 expects-grammar-errors-convict \
  review-record-is-repository-level finalize-runs-per-touched-unit \
  no-manifest-changes-nothing disclaimed-definition-names-its-path \
  near-miss-manifest-name-is-exit-2 near-miss-without-manifest-content-passes \
  disclaimed-draft-convicts-at-repo-level disclaimed-prose-is-not-malformed; do
    grep -rql "@test \".*${ob}" tests/*.bats >/dev/null || echo "MISSING OBLIGATION TEST: $ob"
done
```

Expected output: nothing. (40 names listed; the 41st, the composed
`export-removal-convicts` chain, is in the list — count them: 41.)

| Obligation | Task |
|---|---|
| manifest-shape-errors-are-exit-2, cycle-is-exit-2, root-config-with-manifest-is-exit-2, unit-paths-outside-unit-are-exit-2 | T2 |
| scoped-run-convicts-standalone, disclaimed-definitions-do-not-resolve, disclaimed-definition-names-its-path, expects-undeclared-unit-convicts, expects-grammar-errors-convict, expectation-met-requires-export, unmet-rc-linked-expectation-exits-1, expectation-aging-mirrors-problem-limits, missing-test-exemption-ends-when-met, misexported-item-convicts, reverse-edge-is-exactly-expects, satisfies-across-wrong-edge-convicts, reverse-edge-discharges-nothing | T4 |
| duplicate-id-stays-tree-wide, disclaimed-prose-is-not-malformed (scoped half) | T5 |
| stray-unit-configs-without-manifest-are-exit-2, near-miss-manifest-name-is-exit-2, near-miss-without-manifest-content-passes, unclaimed-path-convicts, root-files-implicitly-disclaimed, tbd-class-on-edge-is-exit-2, class-floor-convicts, segregation-citation-must-resolve, disclaimed-draft-convicts-at-repo-level, disclaimed-prose-is-not-malformed (repo half), no-manifest-changes-nothing | T6 |
| impact-set-is-transitive, unrelated-unit-skips, impact-unclaimed-path-is-exit-2 | T7 |
| new-id-infers-unit-from-cwd, new-id-outside-unit-requires-flag | T8 |
| review-record-is-repository-level, finalize-runs-per-touched-unit | T9 |
| export-removal-convicts, export-removal-reopens-expectation, item-deletion-degrades-to-dangling, transitive-dependent-unaffected, exports-mode-matches-resolution | T11 |

---

## T1 — schema keys and file-parametrized config readers

**Files touched:** `scripts/lib.sh`, `tests/lib.bats`
**Parallel:** no (first; every later task builds on it)
**Trace:** architecture item 8 (schema deltas); groundwork for item 1's "one
parser" rule.

### 1.1 Failing tests

Append to `tests/lib.bats`:

```bash
@test "gr_check_config accepts depends_on and segregated_from as list keys" {
    cat >> .guardrails/config.yaml <<'EOF'
depends_on:
  - platform/hal
segregated_from:
  - platform/hal (RC-k3n8p2)
EOF
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 0 ]
}

@test "gr_check_config rejects depends_on written in scalar form" {
    printf 'depends_on: platform/hal\n' >> .guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 2 ]
    [[ "$output" == *"wrong form"* ]]
}

@test "gr_limit parses the expectation limits like the problem limits" {
    printf 'expectation_age_days: 90\nexpectation_open_max: 10\n' >> .guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_limit expectation_age_days && gr_limit expectation_open_max'
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "90" ]
    [ "${lines[1]}" = "10" ]
}

@test "gr_limit rejects an unparseable expectation limit" {
    printf 'expectation_age_days: ninety\n' >> .guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_limit expectation_age_days'
    [ "$status" -eq 2 ]
}

@test "cfg_get and cfg_list read an explicit second file argument" {
    printf 'units:\n  - packages/pump\n' > other.yaml
    run sh -c '. .guardrails/scripts/lib.sh && cfg_list units other.yaml && cfg_get safety_class'
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "packages/pump" ]
    [ "${lines[1]}" = "B" ]
}
```

Expected before implementation: test 1 fails exit 2 `unknown config key(s)`;
tests 3–4 pass vacuously? No — `expectation_age_days` is an unknown key, so
`gr_limit` is reached only in a valid config; they fail exit 0/blank until the
keys are known (gr_limit itself is generic and needs no change — the tests pin
that fact). Test 5 fails: `cfg_list` ignores a second argument today.

### 1.2 Implementation

In `scripts/lib.sh`:

1. `GR_LIST_KEYS` gains two lines: `depends_on` and `segregated_from`.
2. `GR_KNOWN_KEYS` gains four lines: `depends_on`, `segregated_from`,
   `expectation_age_days`, `expectation_open_max`.
3. `cfg_get` and `cfg_list` take an optional FILE as `$2`, defaulting to
   `$GR_CONFIG` — the "one parser" the manifest reader reuses. Change only the
   head of each:

```sh
cfg_get() {
    _cf="${2:-$GR_CONFIG}"
    [ -f "$_cf" ] || gr_die "config not found: $_cf"
    awk -v k="$1" "$GR_AWK_CLEAN_VALUE"'
        ...unchanged program...
    ' "$_cf"
}
```

(same shape for `cfg_list`; the awk programs are untouched). Add above them:

```sh
# cfg_get/cfg_list read $GR_CONFIG unless handed an explicit FILE as $2. The
# second argument exists for exactly two callers — the manifest reader and the
# cross-unit helpers — so that .guardrails/units.yaml and a sibling unit's
# config are read by THE SAME parser that reads this config. Two near-copies
# of a reader is how readers drift (GR_AWK_ID_RUN's block comment).
```

4. Comment beside the new `GR_KNOWN_KEYS` entries, matching the file's voice:

```sh
# depends_on / segregated_from / expectation_age_days / expectation_open_max
# are the per-unit keys of the monorepo machinery (docs/plans/
# 2026-09-03-units-architecture.md item 8). In a single-unit repository they
# are accepted and read by nothing that gates — the same status safety_class
# held before the class floor — because a config must stay valid when a
# repository grows a manifest.
```

### 1.3 Commands

```sh
sh tests/.bats-core/bin/bats tests/lib.bats     # all green
sh tests/run-tests.sh                            # full suite green
git add -A && git -c commit.gpgsign=false commit -m "feat: units schema keys; cfg readers take an explicit file"
```

### T1 — DONE (dispatch report, landed)

```
red -> green: gr_check_config accepts depends_on and segregated_from as list keys — watched fail (exit 2 "unknown config key(s): depends_on") before implementation
red -> green: gr_check_config rejects depends_on written in scalar form — watched fail (exit 2 as unknown key, not "wrong form") before implementation
red -> green: cfg_get and cfg_list read an explicit second file argument — watched fail (cfg_list ignored $2) before implementation
pins (never red, deliberate): the two gr_limit tests — gr_limit never consults GR_KNOWN_KEYS, so they characterize "gr_limit is generic and needs no change", which the plan itself states
result: 487 passed, 0 failed (baseline 482 + 5)
surprise: templates/config.yaml joined T1's file set — the pre-existing invariant "the shipped config template names only keys the reader knows" reddened when GR_KNOWN_KEYS grew; the four keys were added commented-out. T10's red test (uncommented `^expectation_age_days: 90$`) still fails, so T10 is intact.
```

---

## T2 — manifest reader and validator (`gr_check_units`)

**Files touched:** `scripts/lib.sh`, `tests/lib.bats`
**Parallel:** no (serial, after T1)
**Trace:** architecture item 1. Obligations **manifest-shape-errors-are-exit-2**,
**cycle-is-exit-2**, **root-config-with-manifest-is-exit-2**,
**unit-paths-outside-unit-are-exit-2**.

### 2.1 Structural extraction (no behavior change)

`gr_check_config`'s file-structure gates become two helpers the manifest
validator shares, so the two validators cannot drift. Extract, verbatim in
logic, parametrized only by file:

```sh
# gr_check_flat FILE — the structural rules every flat guardrails file obeys:
# readable; no BOM; no bare-CR line endings; every line blank, a comment, a
# `  - item` belonging to a key, a document separator, or `identifier:` at
# column one; no key set twice. Prints the file's top-level keys, one per
# line. Extracted from gr_check_config when the manifest arrived, because a
# second hand-copied structure gate is how the item-block defect of
# 2026-08-22 happened.
gr_check_flat() {
    _ff="$1"
    [ -f "$_ff" ] || gr_die "file not found: $_ff"
    [ -r "$_ff" ] || gr_die "cannot read $_ff — it exists but this user cannot open it."
    ...BOM/CR awk, malformed-line awk, _keys extraction, duplicate check,
    exactly the current gr_check_config bodies with $GR_CONFIG replaced by
    $_ff and each message naming $_ff...
    printf '%s\n' "$_keys"
}

# gr_check_forms FILE LISTKEYS KEY... — the per-key form/emptiness rules: a
# LIST key (member of LISTKEYS) has items and no scalar value; every other key
# the reverse; no item blank, none itself a comment. Same extraction, same
# reason.
gr_check_forms() {
    _ff="$1"; _lk="$2"; shift 2
    ...the current _empty/_wrong/_blank/_commented loop with cfg_get/cfg_list
    called as `cfg_get "$_k" "$_ff"`, gr_contains against $_lk, and the four
    gr_die messages naming $_ff...
}
```

`gr_check_config` then opens with:

```sh
gr_check_config() {
    _keys=$(gr_check_flat "$GR_CONFIG") || exit 2
    _unknown=""
    for _k in $_keys; do
        gr_contains "$GR_KNOWN_KEYS" "$_k" || _unknown="${_unknown} $_k"
    done
    [ -z "$_unknown" ] || gr_die "unknown config key(s):${_unknown}"
    # shellcheck disable=SC2086
    gr_check_forms "$GR_CONFIG" "$GR_LIST_KEYS" $_keys || exit 2
    ...the prefix and document rules, unchanged...
}
```

The extraction must be mutation-visible: the existing lib.bats tests for BOM,
CR, duplicate keys, wrong form, empty keys and commented items are the proof
it lost nothing — run them before writing any manifest code.

### 2.2 Failing tests

Append to `tests/lib.bats` (fixtures build a two-unit tree inline; T3 adds the
shared helper — these tests deliberately construct by hand so the validator is
tested below the fixture that later depends on it):

```bash
# A minimal valid two-unit manifest repo, built by hand: no root config.
make_manifest_repo() {
    make_fixture_repo
    git rm -q .guardrails/config.yaml
    for u in platform/hal apps/pump; do
        mkdir -p "$u/.guardrails" "$u/docs/requirements" "$u/docs/risk" \
                 "$u/docs/architecture" "$u/docs/problems" "$u/src" "$u/tests"
        sed "s|docs/|$u/docs/|; s|- src|- $u/src|; s|- tests|- $u/tests|" \
            > "$u/.guardrails/config.yaml" <<'EOF'
guardrails_version: 0.1.0
safety_class: B
id_prefixes: REQ HAZ RC SDD LLR PR
doc_srs: docs/requirements
doc_rmf: docs/risk
doc_sad: docs/architecture
doc_soup: docs/architecture/soup.md
doc_problems: docs/problems
strict_paths:
  - src
test_paths:
  - tests
verify_commands:
  - make test
EOF
        printf '# SOUP\n' > "$u/docs/architecture/soup.md"
        for d in requirements risk architecture problems; do
            printf '# ledger\n' > "$u/docs/$d/README.md"
        done
        : > "$u/src/.gitkeep"
    done
    printf 'depends_on:\n  - platform/hal\n' >> apps/pump/.guardrails/config.yaml
    cat > .guardrails/units.yaml <<'EOF'
units:
  - platform/hal
  - apps/pump
not_a_unit:
  - legacy
EOF
    mkdir -p legacy && printf 'notes\n' > legacy/notes.md
    commit_all manifest
}

@test "gr_check_units accepts the minimal valid manifest" {
    make_manifest_repo
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 0 ]
}

@test "lib: manifest-shape-errors-are-exit-2 — unknown key" {
    make_manifest_repo
    printf 'unitz:\n  - oops\n' >> .guardrails/units.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"unknown manifest key"* ]]
}

@test "lib: manifest-shape-errors-are-exit-2 — units in scalar form" {
    make_manifest_repo
    printf 'units: platform/hal\n' > .guardrails/units.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
}

@test "lib: manifest-shape-errors-are-exit-2 — duplicate entry across lists" {
    make_manifest_repo
    printf '  - platform/hal\n' >> .guardrails/units.yaml   # under not_a_unit:
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"more than once"* ]]
}

@test "lib: manifest-shape-errors-are-exit-2 — nested unit" {
    make_manifest_repo
    mkdir -p platform/hal/drivers/.guardrails
    cp platform/hal/.guardrails/config.yaml platform/hal/drivers/.guardrails/ 2>/dev/null || true
    printf '  - platform/hal/drivers\n' >> .guardrails/units.yaml  # appends to not_a_unit:
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"overlap"* ]]
}

@test "lib: manifest-shape-errors-are-exit-2 — missing unit config" {
    make_manifest_repo
    rm apps/pump/.guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"no .guardrails/config.yaml"* ]]
}

@test "lib: manifest-shape-errors-are-exit-2 — glob character in an entry" {
    make_manifest_repo
    printf '  - packages/*\n' >> .guardrails/units.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
}

@test "lib: manifest-shape-errors-are-exit-2 — trailing slash, dot, escape" {
    make_manifest_repo
    for bad in 'legacy2/' '.' '../elsewhere'; do
        cp .guardrails/units.yaml units.bak
        printf '  - %s\n' "$bad" >> .guardrails/units.yaml
        run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
        [ "$status" -eq 2 ]
        mv units.bak .guardrails/units.yaml
    done
}

@test "lib: manifest entry with whitespace is exit 2" {
    make_manifest_repo
    printf '  - two words\n' >> .guardrails/units.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
}

@test "lib: root-config-with-manifest-is-exit-2" {
    make_manifest_repo
    write_config     # recreates root .guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"two authorities"* ]]
}

@test "lib: cycle-is-exit-2" {
    make_manifest_repo
    printf 'depends_on:\n  - apps/pump\n' >> platform/hal/.guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"cycle"* ]]
}

@test "lib: depends_on naming an undeclared unit is exit 2" {
    make_manifest_repo
    printf 'depends_on:\n  - vendor/lib\n' >> platform/hal/.guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"undeclared"* ]]
}

@test "lib: unit-paths-outside-unit-are-exit-2" {
    make_manifest_repo
    sed -i.bak 's|^doc_srs: apps/pump/docs/requirements|doc_srs: platform/hal/docs/requirements|' \
        apps/pump/.guardrails/config.yaml && rm -f apps/pump/.guardrails/config.yaml.bak
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"outside the unit"* ]]
}

@test "lib: a unit config setting doc_verification is exit 2" {
    make_manifest_repo
    printf 'doc_verification: apps/pump/docs/verification\n' >> apps/pump/.guardrails/config.yaml
    mkdir -p apps/pump/docs/verification
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"repository-level"* ]]
}
```

(Note the `make_manifest_repo` `sed` in the heredoc pipeline: bats reads the
helper before any test runs, so define it at the top of the file, after
`load helpers`.)

### 2.3 Implementation

Append to `scripts/lib.sh`, after `gr_check_config`:

```sh
# --- The unit manifest (docs/plans/2026-09-03-units-architecture.md) ---------
#
# .guardrails/units.yaml declares a multi-unit repository. Its PRESENCE is the
# whole engagement rule: absent, every script below runs exactly the code it
# ran before the manifest existed, and the test obligation
# no-manifest-changes-nothing holds the door.
GR_UNITS='.guardrails/units.yaml'

# Both manifest keys are LIST keys; there are no scalars here.
GR_UNITS_KEYS='units
not_a_unit'

gr_units_present() { [ -f "$GR_UNITS" ]; }

# The manifest's two lists, one entry per line. Readers of the same parser the
# config uses — see cfg_get's file argument.
gr_unit_list()       { cfg_list units "$GR_UNITS"; }
gr_disclaimed_list() { cfg_list not_a_unit "$GR_UNITS"; }

# gr_check_units — refuse a manifest that would mis-scope a gate. Everything
# here is exit 2, the environment-error class: a manifest defect is a wrong
# SCOPE for every scan in the repository, which is worse than any finding.
#
# Entries are validated to contain no whitespace and no glob characters
# before any loop interpolates them into a case pattern or a pathspec, so the
# iteration below is safe under any IFS the caller set (the lists are
# newline-separated; a whitespace entry would otherwise read as two).
gr_check_units() {
    [ -f "$GR_UNITS" ] || gr_die "manifest not found: $GR_UNITS"
    _ukeys=$(gr_check_flat "$GR_UNITS") || exit 2
    _unknown=""
    for _k in $_ukeys; do
        gr_contains "$GR_UNITS_KEYS" "$_k" || _unknown="${_unknown} $_k"
    done
    [ -z "$_unknown" ] || gr_die \
"unknown manifest key(s) in $GR_UNITS:${_unknown}
  The manifest takes units: and not_a_unit: only; everything else a unit
  needs lives in that unit's own .guardrails/config.yaml."
    gr_contains "$_ukeys" units || gr_die \
"manifest has no units: list: $GR_UNITS — a manifest that declares no unit
  scopes nothing. Declare at least one, or delete the file to stay single-unit."
    # shellcheck disable=SC2086
    gr_check_forms "$GR_UNITS" "$GR_UNITS_KEYS" $_ukeys || exit 2

    # Exclusivity: two authorities over one tree is the one shape every
    # reader would have to GUESS its way out of.
    [ ! -e .guardrails/config.yaml ] || gr_die \
"root .guardrails/config.yaml alongside $GR_UNITS — two authorities over the
  same tree; every scan would have to guess which one scopes it. A multi-unit
  repository keeps its configs inside the units. Remove one of the two."

    _units=$(gr_unit_list)
    _all=$(printf '%s\n%s\n' "$_units" "$(gr_disclaimed_list)" | grep -v '^$')

    _saved_ifs=${IFS-__gr_unset__}
    IFS='
'
    case $- in (*f*) _un_f=1 ;; (*) _un_f=0 ;; esac
    set -f

    _dupe=$(printf '%s\n' "$_all" | sort | uniq -d | tr '\n' ' ')
    [ -z "$_dupe" ] || gr_die "path listed more than once in $GR_UNITS: ${_dupe}"

    for _e in $_all; do
        case "$_e" in
            (*" "* | *"	"*) gr_die "manifest entry contains whitespace: '$_e' — it would read as two entries to any space-separated consumer" ;;
            (*[\*\?\[]*)     gr_die "manifest entry carries a glob character: $_e — entries are literal directory paths, never patterns (D2 rejected discovery by convention)" ;;
            (*/)             gr_die "manifest entry has a trailing slash: $_e" ;;
            (.)              gr_die "manifest entry names the repository root: . — the root cannot be a unit" ;;
            (/*)             gr_die "manifest entry is absolute: $_e — entries are repository-relative" ;;
            (./*)            gr_die "manifest entry is not plain-relative: $_e — drop the ./" ;;
            (..|../*|*/..|*/../*) gr_die "manifest entry reaches outside the repository: $_e" ;;
        esac
    done

    # Overlap, every direction. The architecture names the unit-nesting cases;
    # the reason it gives — one file, two scopes, two verdicts — condemns a
    # disclaimed path inside a unit and a redundant nested disclaim equally,
    # so all four directions are refused with one rule.
    for _a in $_all; do
        for _b in $_all; do
            [ "$_a" = "$_b" ] && continue
            case "$_b" in ("$_a"/*) gr_die \
"manifest entries overlap: $_b is inside $_a — one file would have two scopes,
  and every scoped gate two verdicts. Claim or disclaim each subtree once." ;;
            esac
        done
    done

    for _u in $_units; do
        [ -d "$_u" ] || gr_die "units: entry is not an existing directory: $_u"
        _ucfg="$_u/.guardrails/config.yaml"
        [ -f "$_ucfg" ] || gr_die \
"units: entry has no .guardrails/config.yaml: $_u
  A unit is a directory guardrails already governs. Run /ratchet in it, or
  disclaim it under not_a_unit: until it is ratcheted."
        # The unit's config passes the SAME validator a single-unit repository
        # runs. In a subshell so GR_CONFIG here is untouched; the subshell's
        # own message has already named the defect when this dies.
        ( GR_CONFIG="$_ucfg"; gr_check_config ) || gr_die \
"unit config failed validation: $_ucfg (see above)"

        # Own scope must BE the unit (architecture item 2): two units' scans
        # are disjoint by construction, or MISPLACED-ITEM sees a sibling's
        # items and the scoped summary lies.
        [ -z "$(cfg_get doc_verification "$_ucfg")" ] || gr_die \
"unit $_u sets doc_verification — the verification record is repository-level
  (one record per change, at the root docs/verification), so a unit-level key
  would be read by nobody. Remove it."
        for _dk in doc_srs doc_rmf doc_sad doc_soup doc_problems; do
            _dv=$(cfg_get "$_dk" "$_ucfg")
            [ -n "$_dv" ] || continue
            case "$_dv" in ("$_u"/*) ;; (*) gr_die \
"unit $_u: $_dk resolves outside the unit: $_dv — a unit's documents live in
  its own subtree, or two units' scans stop being disjoint." ;;
            esac
        done
        for _pk in strict_paths test_paths; do
            for _pv in $(cfg_list "$_pk" "$_ucfg"); do
                case "$_pv" in ("$_u"/*) ;; (*) gr_die \
"unit $_u: $_pk entry outside the unit: $_pv" ;;
                esac
            done
        done

        for _d in $(cfg_list depends_on "$_ucfg"); do
            [ "$_d" != "$_u" ] || gr_die "unit $_u depends on itself"
            gr_contains "$_units" "$_d" || gr_die \
"unit $_u: depends_on names an undeclared unit: $_d
  Declare it in $GR_UNITS, or remove the edge."
        done
    done

    # Cycles: peel units whose dependencies are all peeled; a remainder is a
    # cycle. A worklist over flat lists — POSIX sh, per D12's note.
    _left="$_units"
    _progress=1
    while [ -n "$_left" ] && [ "$_progress" -eq 1 ]; do
        _progress=0
        _next=""
        for _u in $_left; do
            _blocked=0
            for _d in $(cfg_list depends_on "$_u/.guardrails/config.yaml"); do
                gr_contains "$_left" "$_d" && { _blocked=1; break; }
            done
            if [ "$_blocked" -eq 0 ]; then _progress=1
            else _next="${_next}${_u}
"
            fi
        done
        _left=$(printf '%s' "$_next")
    done
    [ -z "$_left" ] || gr_die \
"dependency cycle among units: $(printf '%s' "$_left" | tr '\n' ' ')
  Cyclic units are not partially independent at all — every gate built on the
  edge direction would read ambiguously (D12)."

    [ "$_un_f" -eq 1 ] || set +f
    if [ "$_saved_ifs" = "__gr_unset__" ]; then unset IFS; else IFS=$_saved_ifs; fi
    return 0
}
```

A disclaimed entry is deliberately NOT required to exist: a mistyped disclaim
leaves the real directory unclaimed, which `UNCLAIMED-PATH` reports loudly —
the failure is toward conviction, so no rule is needed here.

### 2.4 Commands

```sh
sh tests/.bats-core/bin/bats tests/lib.bats && sh tests/run-tests.sh
git add -A && git -c commit.gpgsign=false commit -m "feat: manifest reader and validator — every shape error is exit 2"
```

### T2 — DONE (dispatch report, landed)

```
red -> green: all 14 new tests watched fail for the right reason (exit 127,
  gr_check_units undefined) before the implementation existed — the two
  message-asserting ones (trailing-slash class, root-config) inspected
  individually
result: 501 passed, 0 failed (487 + 14; lib.bats alone 89/89)
surprise 1: the plan's make_manifest_repo called make_fixture_repo, but
  lib.bats setup() already runs it — re-init died on an empty commit; the
  helper now builds on setup's fixture (commented there), rest verbatim.
surprise 2: the extraction moves the duplicate-key check ahead of the
  unknown-key check in gr_check_flat (old gr_check_config ordered them the
  other way); no test pins the ordering, and the extraction alone was
  committed separately with all 487 baseline tests green before any manifest
  code (ceb6981).
```

---

## T3 — engagement rule, scope resolver, annotation parser, shared fixture

**Files touched:** `scripts/lib.sh`, `tests/lib.bats`, `tests/helpers.bash`
**Parallel:** no (serial, after T2)
**Trace:** architecture items 2 and 3 (the resolver and the annotation
grammar's reader). The convictions built on these land in T4–T9; this task
delivers the helpers and their direct unit tests.

### 3.1 Shared fixture (`tests/helpers.bash`)

Append:

```bash
# Writes UNIT's .guardrails/config.yaml. Extra args are depends_on entries.
write_unit_config() {
    _u="$1"; shift
    mkdir -p "$_u/.guardrails"
    {
        cat <<EOF
guardrails_version: 0.1.0
safety_class: B
id_prefixes: REQ HAZ RC SDD LLR PR
doc_srs: $_u/docs/requirements
doc_rmf: $_u/docs/risk
doc_sad: $_u/docs/architecture
doc_soup: $_u/docs/architecture/soup.md
doc_problems: $_u/docs/problems
strict_paths:
  - $_u/src
test_paths:
  - $_u/tests
verify_commands:
  - make test
expectation_age_days: 90
expectation_open_max: 10
EOF
        if [ $# -gt 0 ]; then
            echo "depends_on:"
            for _d in "$@"; do echo "  - $_d"; done
        fi
    } > "$_u/.guardrails/config.yaml"
}

# make_unit UNIT [DEPS...] — directories, config, the ratchet-shaped README
# files (a configured directory always holds at least one *.md).
make_unit() {
    _u="$1"
    mkdir -p "$_u/docs/requirements" "$_u/docs/risk" "$_u/docs/architecture" \
             "$_u/docs/problems" "$_u/src" "$_u/tests"
    write_unit_config "$@"
    printf '# SOUP Inventory\n' > "$_u/docs/architecture/soup.md"
    printf '# Requirements ledger\n' > "$_u/docs/requirements/README.md"
    printf '# Risk management file\n' > "$_u/docs/risk/README.md"
    printf '# Software architecture\n' > "$_u/docs/architecture/README.md"
    printf '# Problem reports\n' > "$_u/docs/problems/README.md"
    : > "$_u/src/.gitkeep"
}

# write_unit_items UNIT REQ HAZ RC SDD LLR — one fully traced item set, the
# per-unit copy of the base fixture's ledgers. IDs are passed in so two units
# never collide.
write_unit_items() {
    _u="$1"
    cat > "$_u/docs/requirements/0001-01-01-base.md" <<EOF
# SRS — $_u

**$2**: The software shall limit the dose. (implements: $4)
EOF
    cat > "$_u/docs/risk/0001-01-01-base.md" <<EOF
# RMF — $_u

**$3**: Overdose delivered to patient.

**$4**: Software limits dose to configured maximum. mitigates: $3
EOF
    cat > "$_u/docs/architecture/0001-01-01-base.md" <<EOF
# SAD — $_u

**$5**: Dose limiter module. traces: $2

**$6**: Clamp requested dose to the configured maximum. satisfies: $2
EOF
    printf '# verifies: %s\ntrue\n' "$6" > "$_u/tests/test_a.sh"
}

# The canonical two-unit fixture: provider platform/hal (exports REQ-h4m2p9),
# consumer apps/pump (depends_on hal, references the export from its SAD),
# a disclaimed legacy/ and docs/, root README. Green under every gate.
# Leaves the shell cd'd into $REPO.
make_units_fixture() {
    REPO="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$REPO"
    cd "$REPO"
    git init -q -b main --template=
    git config user.name test
    git config user.email test@example.com
    git config commit.gpgsign false
    mkdir -p .guardrails/scripts docs/verification legacy
    cp "$BATS_TEST_DIRNAME"/../scripts/*.sh .guardrails/scripts/ 2>/dev/null || true
    # check-review reads this directory at the REPOSITORY level in a manifest
    # repo (architecture item 9, task T9); tracked non-empty so worktrees
    # carry it and gr_md_files has its one *.md
    printf '# verification records\n' > docs/verification/README.md
    cat > .guardrails/units.yaml <<'EOF'
units:
  - platform/hal
  - apps/pump
not_a_unit:
  - legacy
  - docs
EOF
    printf '# repo-level docs\n' > docs/README.md
    printf '# migration leftovers\n' > legacy/notes.md
    printf '# monorepo fixture\n' > README.md
    make_unit platform/hal
    make_unit apps/pump platform/hal
    write_unit_items platform/hal REQ-h4m2p9 HAZ-h2b6c3 RC-h3d8f4 SDD-h5g2j7 LLR-h6k9m3
    write_unit_items apps/pump   REQ-p2m4k7 HAZ-p3v8n2 RC-p4q7t3 SDD-p5w2x8 LLR-p6r3z9
    # hal exports its interface REQ (annotation inside the block: nothing
    # closes a block but a heading or a bold-colon line)
    printf 'exported: yes\n' >> platform/hal/docs/requirements/0001-01-01-base.md
    # pump consumes the export: a reference that must resolve via the foreign
    # set, and the live wire the export-removal chain later cuts
    printf '\nThe pump consumes the HAL flow-rate contract (REQ-h4m2p9).\n' \
        >> apps/pump/docs/architecture/0001-01-01-base.md
    git add -A
    git commit -qm units-fixture
}

# Convenience: run a script scoped to one unit of the current fixture.
unit_run() {
    _s="$1"; _u="$2"; shift 2
    GR_CONFIG="$_u/.guardrails/config.yaml" run sh ".guardrails/scripts/$_s" "$@"
}
```

(`unit_run` uses bats' `run` inside a function — that works because `run` is a
shell function itself; keep the call sites as
`unit_run check-trace.sh apps/pump`.)

### 3.2 Failing tests (`tests/lib.bats`)

```bash
@test "gr_unit_engage is a no-op without a manifest" {
    run sh -c '. .guardrails/scripts/lib.sh && gr_unit_engage && printf "[%s]" "$GR_UNIT"'
    [ "$status" -eq 0 ]
    [ "$output" = "[]" ]
}

@test "gr_unit_engage refuses the default config path in a manifest repo, naming the remedy" {
    make_units_fixture
    run sh -c '. .guardrails/scripts/lib.sh && gr_unit_engage'
    [ "$status" -eq 2 ]
    [[ "$output" == *"multi-unit repository"* ]]
    [[ "$output" == *"check-units.sh"* ]]
    [[ "$output" == *"GR_CONFIG"* ]]
}

@test "gr_unit_engage refuses a GR_CONFIG that is not a declared unit's" {
    make_units_fixture
    mkdir -p vendor/thing/.guardrails
    cp apps/pump/.guardrails/config.yaml vendor/thing/.guardrails/
    GR_CONFIG=vendor/thing/.guardrails/config.yaml \
        run sh -c '. .guardrails/scripts/lib.sh && gr_unit_engage'
    [ "$status" -eq 2 ]
    [[ "$output" == *"not a declared unit"* ]]
}

@test "gr_unit_engage resolves a declared unit's config to its unit" {
    make_units_fixture
    GR_CONFIG=apps/pump/.guardrails/config.yaml \
        run sh -c '. .guardrails/scripts/lib.sh && gr_unit_engage && printf "%s" "$GR_UNIT"'
    [ "$status" -eq 0 ]
    [ "$output" = "apps/pump" ]
}

@test "gr_exported_reqs lists exactly the exported REQ IDs with their files" {
    make_units_fixture
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units && gr_exported_reqs platform/hal'
    [ "$status" -eq 0 ]
    [[ "$output" == "REQ-h4m2p9	"* ]]
    [[ "$output" != *"LLR-"* ]]
}

@test "gr_req_scan reports expects, opened and RC linkage per block" {
    make_units_fixture
    cat >> apps/pump/docs/requirements/0001-01-01-base.md <<'EOF'

**REQ-e7x2m4**: The software shall rely on platform/hal to bound slew rate. (implements: RC-p4q7t3)
expects: platform/hal
opened: 2026-09-01
EOF
    run sh -c '. .guardrails/scripts/lib.sh && gr_unit_req_scan apps/pump'
    [ "$status" -eq 0 ]
    [[ "$output" == *"REQ-e7x2m4	"*"	EXPECTS	platform/hal"* ]]
    [[ "$output" == *"REQ-e7x2m4	"*"	OPENED	2026-09-01"* ]]
    [[ "$output" == *"REQ-e7x2m4	"*"	RC	1"* ]]
}

@test "gr_consumers_of names the units whose depends_on points here" {
    make_units_fixture
    run sh -c '. .guardrails/scripts/lib.sh && gr_consumers_of platform/hal && gr_consumers_of apps/pump'
    [ "$status" -eq 0 ]
    [ "$output" = "apps/pump" ]
}

@test "gr_unit_of_path classifies unit, disclaimed and unowned paths" {
    make_units_fixture
    run sh -c '. .guardrails/scripts/lib.sh
        gr_unit_of_path apps/pump/src/x.c
        gr_unit_of_path legacy/notes.md
        gr_unit_of_path tools/x.c || echo unowned'
    [ "${lines[0]}" = "apps/pump" ]
    [ "${lines[1]}" = "not_a_unit legacy" ]
    [ "${lines[2]}" = "unowned" ]
}
```

### 3.3 Implementation (`scripts/lib.sh`, appended after `gr_check_units`)

```sh
# gr_unit_engage — the engagement rule (architecture item 2). Sets GR_UNIT to
# the running unit's path, or to "" in a single-unit repository. Every
# unit-scoped script calls this immediately after cd'ing to the root and
# BEFORE gr_check_config: engaged, the config named by GR_CONFIG is the
# unit's own, already validated once by gr_check_units — validating it again
# through the ordinary gr_check_config call that follows costs one pass and
# buys the same message a single-unit project gets.
gr_unit_engage() {
    GR_UNIT=""
    gr_units_present || return 0
    gr_check_units
    case "$GR_CONFIG" in
        (.guardrails/config.yaml) gr_die \
"this is a multi-unit repository ($GR_UNITS) — there is no root config to read.
  Run check-units.sh for the repository-level gates, or set GR_CONFIG to a
  unit's .guardrails/config.yaml for that unit's run." ;;
    esac
    for _c in $(gr_unit_list); do
        if [ "$GR_CONFIG" = "$_c/.guardrails/config.yaml" ]; then
            GR_UNIT="$_c"
            return 0
        fi
    done
    gr_die \
"GR_CONFIG is not a declared unit's config: $GR_CONFIG
  Scoping an undeclared config would invent a unit the manifest never granted.
  Declared units: $(gr_unit_list | tr '\n' ' ')"
}

# gr_req_scan FILE... — the annotation reader of architecture item 3. One
# line per fact, tab-separated: <id> <file> KIND <value>, where KIND is
#   DEF      the block exists (value -)
#   EXP      exported: (raw value — the consumer judges it)
#   EXPECTS  expects:  (raw value)
#   OPENED   opened:   (raw value)
#   RC       the block carries implements: RC-… (value 1)
#   SAT      one line per satisfies: REQ entry (value the REQ id)
# Column one only, first occurrence per keyword per block — the same rules
# the PR status reader follows, so ORPHAN-ANNOTATION sees what this sees.
# Blocks open on every gated prefix, so exported: on an LLR is ATTRIBUTED and
# convicted (MISEXPORTED-ITEM), never dropped.
gr_req_scan() {
    for _f in "$@"; do
        LC_ALL=C awk -v body="$GR_ID_BODY" -v fname="$_f" \
            "$GR_AWK_ID_RUN$GR_AWK_ITEM_BLOCK"'
            BEGIN { gr_block_init("REQ|HAZ|RC|SDD|LLR|PR", body) }
            FNR == 1 { sub(/^\357\273\277/, "") }
            { line = $0; sub(/\r$/, "", line) }
            gr_block_closes(line) {
                cur = gr_block_opens(line) ? gr_block_id(line) : ""
                exp_seen = 0; expc_seen = 0; opd_seen = 0; rc_seen = 0
                if (cur != "") printf "%s\t%s\tDEF\t-\n", cur, fname
            }
            cur == "" { next }
            !exp_seen && gr_kw_here(line, "exported:") {
                exp_seen = 1
                printf "%s\t%s\tEXP\t%s\n", cur, fname, gr_value(line, "exported:")
            }
            !expc_seen && gr_kw_here(line, "expects:") {
                expc_seen = 1
                printf "%s\t%s\tEXPECTS\t%s\n", cur, fname, gr_value(line, "expects:")
            }
            !opd_seen && gr_kw_here(line, "opened:") {
                opd_seen = 1
                printf "%s\t%s\tOPENED\t%s\n", cur, fname, gr_value(line, "opened:")
            }
            {
                run = gr_id_run(line, "implements:")
                n = split(run, a, " ")
                for (i = 1; i <= n; i++)
                    if (a[i] ~ /^RC-/ && !rc_seen) { rc_seen = 1; printf "%s\t%s\tRC\t1\n", cur, fname }
                run = gr_id_run(line, "satisfies:")
                n = split(run, a, " ")
                for (i = 1; i <= n; i++)
                    if (a[i] ~ /^REQ-/) printf "%s\t%s\tSAT\t%s\n", cur, fname, a[i]
            }
        ' "$_f" || gr_die "unit annotation scan failed on $_f"
    done
    return 0
}

# gr_unit_srs UNIT — the unit's doc_srs files, one per line. The same
# emptiness rules gr_doc_files applies, with the unit named in the error.
gr_unit_srs() {
    _uv=$(cfg_get doc_srs "$1/.guardrails/config.yaml")
    [ -n "$_uv" ] || return 0
    if [ -d "$_uv" ]; then
        gr_md_files "$_uv" "doc_srs of unit $1 is configured as directory"
    elif [ -f "$_uv" ]; then
        printf '%s\n' "$_uv"
    else
        gr_die "unit $1: doc_srs is configured as '$_uv', which does not exist"
    fi
    return 0
}

# gr_unit_req_scan UNIT — gr_req_scan over the unit's SRS. Call in a command
# substitution with `|| exit 2` like every other lib helper that can die.
gr_unit_req_scan() {
    _rs_list=$(gr_unit_srs "$1") || exit 2
    _saved_ifs=${IFS-__gr_unset__}
    IFS='
'
    case $- in (*f*) _rs_f=1 ;; (*) _rs_f=0 ;; esac
    set -f
    # shellcheck disable=SC2086
    gr_req_scan $_rs_list
    _rs_st=$?
    [ "$_rs_f" -eq 1 ] || set +f
    if [ "$_saved_ifs" = "__gr_unset__" ]; then unset IFS; else IFS=$_saved_ifs; fi
    return $_rs_st
}

# gr_exported_reqs UNIT — "REQ-id<TAB>file" for every exported REQ of UNIT.
# THE definition of the export surface: check-units.sh --exports prints it and
# the consumer's resolver reads it, so the report and the gate are one
# computation (obligation exports-mode-matches-resolution).
gr_exported_reqs() {
    _ex_scan=$(gr_unit_req_scan "$1") || exit 2
    printf '%s\n' "$_ex_scan" | awk -F'\t' \
        '$3 == "EXP" && $4 == "yes" && $1 ~ /^REQ-/ { print $1 "\t" $2 }' | sort -u
}

# gr_consumers_of UNIT — declared units whose depends_on names UNIT.
gr_consumers_of() {
    for _cu in $(gr_unit_list); do
        [ "$_cu" = "$1" ] && continue
        gr_contains "$(cfg_list depends_on "$_cu/.guardrails/config.yaml")" "$1" \
            && printf '%s\n' "$_cu"
    done
    return 0
}

# gr_unit_of_path PATH — the unit claiming PATH ("apps/pump"), or
# "not_a_unit <entry>" for a disclaimed one; status 1 for a path nobody
# claims. Whole path components (D7's rule): docs claims docs/adr/x.md and
# never docs-site/.
gr_unit_of_path() {
    for _pu in $(gr_unit_list); do
        case "$1" in ("$_pu" | "$_pu"/*) printf '%s\n' "$_pu"; return 0 ;; esac
    done
    for _pd in $(gr_disclaimed_list); do
        case "$1" in ("$_pd" | "$_pd"/*) printf 'not_a_unit %s\n' "$_pd"; return 0 ;; esac
    done
    return 1
}
```

(The `for _x in $(gr_unit_list)` splits are safe under any caller IFS:
`gr_check_units` has already refused entries containing whitespace or glob
characters, and `gr_unit_engage`/every helper here runs only after it.)

### 3.4 Commands

```sh
sh tests/.bats-core/bin/bats tests/lib.bats && sh tests/run-tests.sh
git add -A && git -c commit.gpgsign=false commit -m "feat: engagement rule, scope resolver and annotation reader in lib"
```

### T3 — DONE (dispatch report, landed)

```
red -> green: all 8 new tests watched fail for the right reason (exit 127,
  function missing; gr_unit_of_path also lines[0] mismatch) before the
  implementation existed
result: 509 passed, 0 failed (501 + 8; lib.bats alone 97/97)
surprise: make_units_fixture builds in $BATS_TEST_TMPDIR/units-repo, not
  $BATS_TEST_TMPDIR/repo — setup()'s fixture already sits there with a root
  config, which gr_check_units refuses alongside a manifest ("two
  authorities"); commented in the helper, everything else verbatim.
incidental: the splice flipped scripts/lib.sh 755->644; restored to 755 at
  the merge (lib.sh is sourced, not executed — cosmetic).
```

---

## T4 — `check-trace.sh` under scope

**Files touched:** `scripts/check-trace.sh`, `tests/check-trace.bats`
**Parallel:** yes (after T3; file set disjoint from T5–T10)
**Trace:** architecture items 2 (classification table), 3 (annotations), 4
(the scoped gates). Obligations **scoped-run-convicts-standalone**,
**disclaimed-definitions-do-not-resolve**,
**disclaimed-definition-names-its-path**, **expects-undeclared-unit-convicts**,
**expects-grammar-errors-convict**, **expectation-met-requires-export**,
**unmet-rc-linked-expectation-exits-1**,
**expectation-aging-mirrors-problem-limits**,
**missing-test-exemption-ends-when-met**, **misexported-item-convicts**,
**reverse-edge-is-exactly-expects**, **satisfies-across-wrong-edge-convicts**,
**reverse-edge-discharges-nothing**.

Everything below is inside `[ -n "$GR_UNIT" ]` (or a helper that starts with
it); the unscoped path stays byte-identical.

### 4.1 Failing tests

Append to `tests/check-trace.bats`. A shared per-test helper first (top of
file, after `load helpers`):

```bash
# An expectation REQ appended to pump's SRS.
#   add_expectation [TARGET] [OPENED] [RC-SUFFIX]
# RC-SUFFIX non-empty appends "(implements: RC-p4q7t3)" to the REQ line.
add_expectation() {
    _tgt="${1:-platform/hal}"
    _opd="${2:-$(days_ago 3)}"
    _rc=""
    [ -n "${3:-}" ] && _rc=" (implements: RC-p4q7t3)"
    cat >> apps/pump/docs/requirements/0001-01-01-base.md <<EOF

**REQ-e7x2m4**: The software shall rely on $_tgt to bound slew rate.$_rc
expects: $_tgt
opened: $_opd
EOF
}

# hal's exported answer to REQ-e7x2m4, with its own trace/test so hal stays
# green. satisfy_expectation [EXPORTED-LINE]
satisfy_expectation() {
    cat >> platform/hal/docs/requirements/0001-01-01-base.md <<EOF

**REQ-h8s3t2**: The software shall bound actuator slew rate. satisfies: REQ-e7x2m4
${1:-exported: yes}
EOF
    printf '# verifies: REQ-h8s3t2\ntrue\n' > platform/hal/tests/test_b.sh
}
```

The tests:

```bash
@test "check-trace: units fixture is green for both units, and the summary is scoped" {
    make_units_fixture
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 0 ]
    [[ "$output" == *"scope: unit apps/pump"* ]]
    [[ "$output" == *"checked: REQ 1,"* ]]      # pump's own item only
    unit_run check-trace.sh platform/hal
    [ "$status" -eq 0 ]
    [[ "$output" == *"expectations against this unit: 0 open"* ]]
}

@test "check-trace: a manifest repo without GR_CONFIG is exit 2 naming the remedy" {
    make_units_fixture
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"multi-unit repository"* ]]
}

@test "check-trace: scoped-run-convicts-standalone — a sibling-internal reference convicts with no orchestrator" {
    make_units_fixture
    printf '\nSee LLR-h6k9m3 for the clamp.\n' >> apps/pump/docs/architecture/0001-01-01-base.md
    commit_all ref
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 1 ]
    [[ "$output" == *"NON-EXPORTED-REF LLR-h6k9m3"* ]]
}

@test "check-trace: a reference into an undeclared unit convicts UNDECLARED-DEPENDENCY" {
    make_units_fixture
    printf '\nSee REQ-p2m4k7.\n' >> platform/hal/docs/architecture/0001-01-01-base.md
    commit_all ref
    unit_run check-trace.sh platform/hal
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNDECLARED-DEPENDENCY REQ-p2m4k7"* ]]
}

@test "check-trace: disclaimed-definitions-do-not-resolve, and disclaimed-definition-names-its-path" {
    make_units_fixture
    printf '**REQ-z9q3w2**: Legacy behavior, kept for reference.\n' >> legacy/notes.md
    printf '\nSee REQ-z9q3w2.\n' >> apps/pump/docs/architecture/0001-01-01-base.md
    commit_all legacy-def
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-z9q3w2"* ]]
    [[ "$output" == *"legacy/notes.md"* ]]      # the message names the file
}

@test "check-trace: a truly undefined reference stays plain DANGLING-REF" {
    make_units_fixture
    printf '\nSee REQ-zz9zz2.\n' >> apps/pump/docs/architecture/0001-01-01-base.md
    commit_all dangling
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-zz9zz2 (referenced but never defined)"* ]]
}

@test "check-trace: misexported-item-convicts — a non-yes value and a non-REQ carrier" {
    make_units_fixture
    # corrupt the REQ's own annotation (first occurrence wins, so edit in place)
    sed -i.bak 's/^exported: yes$/exported: true/' platform/hal/docs/requirements/0001-01-01-base.md
    rm -f platform/hal/docs/requirements/0001-01-01-base.md.bak
    # and put a well-formed one on a design item (appends inside the LLR block)
    printf 'exported: yes\n' >> platform/hal/docs/architecture/0001-01-01-base.md
    commit_all bad-export
    unit_run check-trace.sh platform/hal
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISEXPORTED-ITEM REQ-h4m2p9"* ]]
    [[ "$output" == *"MISEXPORTED-ITEM LLR-h6k9m3"* ]]
}

@test "check-trace: expects-undeclared-unit-convicts — and the MISSING-TEST exemption never engages" {
    make_units_fixture
    add_expectation legacy      # not in depends_on
    commit_all exp
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNDECLARED-DEPENDENCY REQ-e7x2m4"* ]]
    [[ "$output" == *"MISSING-TEST REQ-e7x2m4"* ]]
}

@test "check-trace: expects-grammar-errors-convict — empty value, no opened:, non-REQ carrier" {
    make_units_fixture
    cat >> apps/pump/docs/requirements/0001-01-01-base.md <<'EOF'

**REQ-g2h6j3**: The software shall do a thing.
expects:
EOF
    printf 'expects: platform/hal\n' >> apps/pump/docs/architecture/0001-01-01-base.md  # LLR block
    cat >> apps/pump/docs/requirements/0001-01-01-base.md <<'EOF'

**REQ-k4m7n2**: The software shall do another thing.
expects: platform/hal
EOF
    commit_all bad-expects   # REQ-k4m7n2 has no opened:
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 1 ]
    [[ "$output" == *"INCOMPLETE-EXPECTATION REQ-g2h6j3"* ]]
    [[ "$output" == *"INCOMPLETE-EXPECTATION LLR-p6r3z9"* ]]
    [[ "$output" == *"INCOMPLETE-EXPECTATION REQ-k4m7n2"* ]]
}

@test "check-trace: an unmet expectation is reported, exempt from MISSING-TEST, and exit 0 inside its budget" {
    make_units_fixture
    add_expectation
    commit_all exp
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 0 ]
    [[ "$output" == *"UNMET-EXPECTATION platform/hal: REQ-e7x2m4"* ]]
    [[ "$output" != *"MISSING-TEST REQ-e7x2m4"* ]]
    [[ "$output" == *"expectations: open 1,"* ]]
    [[ "$output" == *"limits age 90, open 10"* ]]
}

@test "check-trace: unmet-rc-linked-expectation-exits-1" {
    make_units_fixture
    add_expectation platform/hal "$(days_ago 1)" rc
    commit_all exp-rc
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNMET-EXPECTATION platform/hal: REQ-e7x2m4"* ]]
    [[ "$output" == *"risk control"* ]]
}

@test "check-trace: expectation-aging-mirrors-problem-limits — past the age limit fails, unset limit prints none, unparseable is exit 2" {
    make_units_fixture
    add_expectation platform/hal "$(days_ago 120)"
    commit_all exp-old
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 1 ]
    [[ "$output" == *"limit 90"* ]]
    del_first_line 'expectation_age_days: 90' apps/pump/.guardrails/config.yaml
    commit_all no-age-limit
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 0 ]
    [[ "$output" == *"limits age none, open 10"* ]]
    sed -i.bak 's/^expectation_open_max: 10$/expectation_open_max: many/' apps/pump/.guardrails/config.yaml
    rm -f apps/pump/.guardrails/config.yaml.bak
    commit_all bad-limit
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 2 ]
}

@test "check-trace: the expectation backlog limit fails like PROBLEM-BACKLOG" {
    make_units_fixture
    sed -i.bak 's/^expectation_open_max: 10$/expectation_open_max: 0/' apps/pump/.guardrails/config.yaml
    rm -f apps/pump/.guardrails/config.yaml.bak
    add_expectation
    commit_all exp
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 1 ]
    [[ "$output" == *"EXPECTATION-BACKLOG (1 open expectation"* ]]
}

@test "check-trace: expectation-met-requires-export — satisfied by a non-exported REQ stays unmet" {
    make_units_fixture
    add_expectation
    satisfy_expectation "not-exported: placeholder"   # any non-exported line
    commit_all half-met
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 0 ]
    [[ "$output" == *"UNMET-EXPECTATION platform/hal: REQ-e7x2m4"* ]]
}

@test "check-trace: missing-test-exemption-ends-when-met" {
    make_units_fixture
    add_expectation
    satisfy_expectation
    commit_all met
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 1 ]
    [[ "$output" != *"UNMET-EXPECTATION"* ]]
    [[ "$output" == *"MISSING-TEST REQ-e7x2m4"* ]]
    printf '# verifies: REQ-e7x2m4\ntrue\n' > apps/pump/tests/test_e.sh
    commit_all met-tested
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 0 ]
}

@test "check-trace: reverse-edge-is-exactly-expects — the provider resolves the expectation and nothing else" {
    make_units_fixture
    add_expectation
    satisfy_expectation
    commit_all met
    unit_run check-trace.sh platform/hal
    [ "$status" -eq 0 ]      # satisfies: REQ-e7x2m4 resolves via the reverse edge
    [[ "$output" == *"expectations against this unit: 0 open"* ]]
}

@test "check-trace: satisfies-across-wrong-edge-convicts" {
    make_units_fixture
    make_unit svc/util
    write_unit_items svc/util REQ-u2v6w3 HAZ-u3x8y2 RC-u4z7a3 SDD-u5b2c8 LLR-u6d3e9
    cat > .guardrails/units.yaml <<'EOF'
units:
  - platform/hal
  - apps/pump
  - svc/util
not_a_unit:
  - legacy
  - docs
EOF
    printf '  - svc/util\n' >> apps/pump/.guardrails/config.yaml   # extends depends_on
    add_expectation svc/util
    satisfy_expectation      # hal answers an expectation aimed at svc/util
    commit_all wrong-edge
    unit_run check-trace.sh platform/hal
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNDECLARED-DEPENDENCY REQ-e7x2m4"* ]]
}

@test "check-trace: reverse-edge-discharges-nothing — the consumer's item joins no provider enumeration" {
    make_units_fixture
    add_expectation
    commit_all exp
    unit_run check-trace.sh platform/hal
    [ "$status" -eq 0 ]
    [[ "$output" == *"checked: REQ 1,"* ]]     # hal's own REQ only, never REQ-e7x2m4
    [[ "$output" == *"expectations against this unit: 1 open"* ]]
    # and it cannot absorb a provider test: a hal test verifying only the
    # consumer's item leaves hal's own REQ uncovered
    printf '# verifies: REQ-e7x2m4\ntrue\n' > platform/hal/tests/test_a.sh
    commit_all swap-test
    unit_run check-trace.sh platform/hal
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST"* ]]
}
```

Expected before implementation: the first test fails at
`checked:`-with-`scope:` (no engagement exists), most others fail exit 2
(`GR_CONFIG`-with-manifest is unknown territory) or report nothing.

### 4.2 Implementation

All edits to `scripts/check-trace.sh`.

**(a) Engagement.** After `cd "$gr_repo_root" || exit 2`, before
`gr_check_config`:

```sh
# The engagement rule (architecture item 2): with no manifest this is a
# no-op and everything below is exactly the single-unit script. Engaged,
# GR_UNIT names the unit whose config this run reads, and the scoped
# machinery at the bottom of this file switches on.
gr_unit_engage
```

**(b) Expectation limits**, next to the problem limits:

```sh
exp_age_limit=""
exp_open_limit=""
if [ -n "$GR_UNIT" ]; then
    exp_age_limit=$(gr_limit expectation_age_days) || exit 2
    exp_open_limit=$(gr_limit expectation_open_max) || exit 2
fi
```

**(c) Scoped definition scans.** `ids_defined` and the DANGLING-REF `defined`
set are the two places the whole tree leaks into a scoped run:

```sh
# ids_defined PREFIX — all finalized IDs with a `**ID**:` definition site.
# Scoped, the site must lie inside the unit: sibling items are not this run's
# items (they neither owe MISSING-TEST here nor discharge anything —
# obligation reverse-edge-discharges-nothing generalizes to every foreign
# definition), and MISPLACED-ITEM must never see them at all.
ids_defined() {
    if [ -n "$GR_UNIT" ]; then
        git grep -h --untracked -oE "$(gr_def_re "$1")" -- "$GR_UNIT" 2>/dev/null \
            | sed 's/[*:]//g' | sort -u
    else
        git grep -h --untracked -oE "$(gr_def_re "$1")" -- . "$GR_SCAN_EXCLUDE" 2>/dev/null \
            | sed 's/[*:]//g' | sort -u
    fi
}
```

**(d) Foreign and reverse-edge sets.** After the `require_paths` calls:

```sh
foreign=""
reverse=""
deps=""
if [ -n "$GR_UNIT" ]; then
    deps=$(cfg_list depends_on)
    for _dep in $deps; do
        _fx=$(gr_exported_reqs "$_dep") || exit 2
        foreign="$foreign
$(printf '%s\n' "$_fx" | cut -f1)"
    done
    for _con in $(gr_consumers_of "$GR_UNIT"); do
        _cs=$(gr_unit_req_scan "$_con") || exit 2
        reverse="$reverse
$(printf '%s\n' "$_cs" | awk -F'\t' -v me="$GR_UNIT" \
            '$3 == "EXPECTS" && $4 == me && $1 ~ /^REQ-/ { print $1 }')"
    done
fi
```

**(e) The four-way classification.** Replace the body of the DANGLING-REF
reporting loop:

```sh
    for id in $referenced; do
        gr_contains "$defined" "$id" && continue
        if [ -n "$GR_UNIT" ]; then
            gr_contains "$foreign" "$id" && continue
            gr_contains "$reverse" "$id" && continue
            classify_unresolved "$id"
        else
            echo "DANGLING-REF $id (referenced but never defined)"
        fi
        fail=1
    done
```

with, above the loop:

```sh
# classify_unresolved ID — the architecture's item-2 table: a scoped reference
# that resolves against nothing classifies by where its definition actually
# lives. One git grep per unresolved ID; unresolved IDs are the rare case.
# A dependency definition wins over another unit's (it names the remedy —
# export it); a disclaimed definition never outranks either.
classify_unresolved() {
    _cid="$1"
    _sites=$(git grep -l --untracked -E "^\\*\\*${_cid}\\*\\*:" -- . "$GR_SCAN_EXCLUDE" 2>/dev/null)
    _v=""
    _d=""
    for _sf in $_sites; do
        _w=$(gr_unit_of_path "$_sf") || continue
        case "$_w" in
            (not_a_unit\ *)
                if [ -z "$_v" ]; then
                    _v="DANGLING-REF"
                    _d="(defined only in $_sf, under disclaimed path ${_w#not_a_unit } — disclaimed means outside compliance; that definition is prose, not an item)"
                fi ;;
            (*)
                if gr_contains "$deps" "$_w"; then
                    _v="NON-EXPORTED-REF"
                    _d="(defined in declared dependency $_w, but not exported: yes)"
                    break
                elif [ "$_w" != "$GR_UNIT" ]; then
                    _v="UNDECLARED-DEPENDENCY"
                    _d="(defined in unit $_w, which is not in this unit's depends_on)"
                fi ;;
        esac
    done
    [ -n "$_v" ] || { _v="DANGLING-REF"; _d="(referenced but never defined)"; }
    echo "$_v $_cid $_d"
}
```

(`$_w` can also equal `$GR_UNIT` when the definition sits inside the unit but
outside every configured document — e.g. in `src/` prose. That is today's
DANGLING-REF semantics exactly: fall through to the plain verdict.)

**(f) Annotations, expectations, and the exemption.** One block, placed after
the foreign/reverse computation and BEFORE the MISSING-TEST section (the
exemption list must exist first). Full code:

```sh
# --- Unit annotations and expectations (architecture items 3 and 4) ----------
# Scoped runs only. exported:/expects:/opened: are read by gr_req_scan under
# the same column-one, first-occurrence, block-attributed rules as status:,
# and the ORPHAN-ANNOTATION backstop below is extended to match.
exempt_expect=""
exp_summary=""
if [ -n "$GR_UNIT" ]; then
    # shellcheck disable=SC2086
    own_scan=$(gr_req_scan $srs_files $rmf_files $sad_files $problems_files) || exit 2

    # MISEXPORTED-ITEM: only `exported: yes` on a REQ is an export (D8). A
    # misspelled value would read as "not exported" and strand every consumer
    # silently, so any other value — empty included — convicts, as does the
    # annotation on a non-REQ block.
    _misexp=$(printf '%s\n' "$own_scan" | awk -F'\t' '
        $3 != "EXP" { next }
        $1 !~ /^REQ-/       { printf "MISEXPORTED-ITEM %s (exported: on a non-REQ item — only requirements are exported; LLR and SDD are design data)\n", $1; next }
        $4 != "yes"         { printf "MISEXPORTED-ITEM %s (exported: %s — the only accepted value is yes; anything else reads as not exported, which strands consumers silently)\n", $1, $4 }')
    if [ -n "$_misexp" ]; then
        printf '%s\n' "$_misexp"
        fail=1
    fi

    # Expectations. Grammar first (INCOMPLETE-EXPECTATION is the one token for
    # every expectation the reader cannot read), then the computed state.
    _badexp=$(printf '%s\n' "$own_scan" | awk -F'\t' '
        $3 != "EXPECTS" { next }
        $1 !~ /^REQ-/ { printf "INCOMPLETE-EXPECTATION %s (expects: on a non-REQ item)\n", $1; next }
        $4 == ""      { printf "INCOMPLETE-EXPECTATION %s (expects: with no unit named)\n", $1 }')
    if [ -n "$_badexp" ]; then
        printf '%s\n' "$_badexp"
        fail=1
    fi

    exp_open=0
    exp_oldest=-1
    _tab=$(printf '\t')
    for _el in $(printf '%s\n' "$own_scan" \
            | awk -F'\t' '$3 == "EXPECTS" && $1 ~ /^REQ-/ && $4 != "" { print $1 "\t" $4 }'); do
        _eid=${_el%%"$_tab"*}
        _etgt=${_el#*"$_tab"}
        if ! gr_contains "$deps" "$_etgt"; then
            echo "UNDECLARED-DEPENDENCY $_eid (expects: names $_etgt, which is not in this unit's depends_on — the MISSING-TEST exemption never engages across an undeclared edge)"
            fail=1
            continue
        fi
        _eopd=$(printf '%s\n' "$own_scan" | awk -F'\t' -v i="$_eid" '$1 == i && $3 == "OPENED" { print $4; exit }')
        _eage=$(LC_ALL=C awk -v today="$today" -v opd="$_eopd" "$GR_AWK_CIVIL"'BEGIN {
            gr_date_ok(today); t = GR_DATE_DAYS
            if (!gr_date_ok(opd)) { print -1; exit }
            a = t - GR_DATE_DAYS
            if (a == -1) a = 0            # one day of clock-skew tolerance,
            print (a < 0 ? -1 : a)        # further future is refused (as PRs)
        }')
        if [ "$_eage" -lt 0 ]; then
            echo "INCOMPLETE-EXPECTATION $_eid (opened: cannot be used — '$_eopd' is absent, not a calendar date, or more than a day in the future)"
            fail=1
            continue
        fi
        # met iff the named provider defines an EXPORTED REQ carrying
        # satisfies: <this ID> — both conditions (D11; obligation
        # expectation-met-requires-export).
        _pscan=$(gr_unit_req_scan "$_etgt") || exit 2
        _met=$(printf '%s\n' "$_pscan" | awk -F'\t' -v want="$_eid" '
            $3 == "EXP" && $4 == "yes" { exp[$1] = 1 }
            $3 == "SAT" && $4 == want  { sat[$1] = 1 }
            END { for (i in sat) if (i in exp) { print "met"; exit } }')
        if [ "$_met" = "met" ]; then
            continue          # an ordinary REQ again; MISSING-TEST applies
        fi
        exempt_expect="$exempt_expect
$_eid"
        exp_open=$((exp_open + 1))
        [ "$_eage" -gt "$exp_oldest" ] && exp_oldest=$_eage
        if printf '%s\n' "$own_scan" | awk -F'\t' -v i="$_eid" '$1 == i && $3 == "RC" { found = 1 } END { exit !found }'; then
            echo "UNMET-EXPECTATION $_etgt: $_eid (open $_eage days — implements a risk control, exit 1 on every run until the provider delivers or the risk is re-analyzed)"
            fail=1
        elif [ -n "$exp_age_limit" ] && [ "$_eage" -gt "$exp_age_limit" ]; then
            echo "UNMET-EXPECTATION $_etgt: $_eid (open $_eage days, limit $exp_age_limit)"
            fail=1
        else
            echo "UNMET-EXPECTATION $_etgt: $_eid (open $_eage days)"
        fi
    done
    if [ -n "$exp_open_limit" ] && [ "$exp_open" -gt "$exp_open_limit" ]; then
        _noun="open expectations"
        [ "$exp_open" -eq 1 ] && _noun="open expectation"
        echo "EXPECTATION-BACKLOG ($exp_open $_noun, limit $exp_open_limit)"
        fail=1
    fi
    _eold_txt="n/a"
    [ "$exp_oldest" -ge 0 ] && _eold_txt="$exp_oldest days"
    exp_summary="expectations: open $exp_open, oldest $_eold_txt; limits age ${exp_age_limit:-none}, open ${exp_open_limit:-none}"
fi
```

The `for _el in $(printf …)` loop runs under the script's `IFS=<newline>`, so
each line is one word and the embedded tab survives into `${_el%%…}`.

**(g) MISSING-TEST exemption.** In the REQ half of the MISSING-TEST section,
change the loop:

```sh
    for id in $(ids_defined REQ); do
        # A valid UNMET expectation is exempt (D10): it cannot have a
        # verifying test yet and is already reported once, accurately, by
        # UNMET-EXPECTATION above. Met, it is an ordinary REQ again.
        gr_contains "$exempt_expect" "$id" && continue
        gr_contains "$covered" "$id" || { echo "MISSING-TEST $id (no direct 'verifies:' and no tested LLR satisfies it)"; fail=1; }
    done
```

This requires the annotation/expectation block (f) to be COMPUTED before the
MISSING-TEST section; place it immediately after (d) and move nothing else.
(In an unscoped run `exempt_expect` is empty and the added line is a no-op —
the byte-identical claim holds for behavior; the `gr_contains` call itself is
new code on the old path, covered by the whole existing suite.)

**(h) Provider-side advisory and the scoped summary.** Placed immediately
after the `problems:` echo and before the `sources:` echo, so a scoped run's
extra denominators sit between the two they extend:

```sh
if [ -n "$GR_UNIT" ]; then
    echo "scope: unit $GR_UNIT; foreign $(count_lines "$foreign"), reverse $(count_lines "$reverse")"
    [ -n "$exp_summary" ] && echo "$exp_summary"
    # The D10 advisory: the open expectations standing against THIS unit,
    # computed from the reverse edge and our own exports. Exit 0 — the
    # consumer's aging budget is the gate; this is the courtesy on top.
    _against=0
    for _rid in $reverse; do
        [ -n "$_rid" ] || continue
        _ans=$(printf '%s\n' "$own_scan" | awk -F'\t' -v want="$_rid" '
            $3 == "EXP" && $4 == "yes" { exp[$1] = 1 }
            $3 == "SAT" && $4 == want  { sat[$1] = 1 }
            END { for (i in sat) if (i in exp) { print "met"; exit } }')
        [ "$_ans" = "met" ] || _against=$((_against + 1))
    done
    echo "expectations against this unit: $_against open"
fi
```

(`count_lines` already exists; `foreign`/`reverse` are newline-joined with
possible leading blank lines, which `grep -c .` ignores.)

**(i) ORPHAN-ANNOTATION.** Extend the backstop, scoped only:

```sh
if [ -n "$GR_UNIT" ]; then
    # shellcheck disable=SC2086
    _ann_files=$(printf '%s\n' $srs_files $rmf_files $sad_files $problems_files | sort -u)
    _orphans2=$(
        check_orphans 'exported:' 'REQ|HAZ|RC|SDD|LLR|PR' $_ann_files
        check_orphans 'expects:'  'REQ|HAZ|RC|SDD|LLR|PR' $_ann_files
        check_orphans 'opened:'   'REQ|HAZ|RC|SDD|LLR|PR' $srs_files
    ) || exit 2
    if [ -n "$_orphans2" ]; then
        printf '%s\n' "$_orphans2"
        fail=1
    fi
fi
```

The popen alternation matches gr_req_scan's opening set exactly — reader and
backstop look in the same place, the rule `status:` already follows.
(`opened:` over `$problems_files` is already covered by the existing call; the
new call covers the SRS, where expectation blocks now carry it.)

**(j) Header documentation.** Extend the script's header comment with the new
findings (`NON-EXPORTED-REF`, `UNDECLARED-DEPENDENCY`, `UNMET-EXPECTATION`,
`INCOMPLETE-EXPECTATION`, `MISEXPORTED-ITEM`, `EXPECTATION-BACKLOG`) and one
paragraph: scoped runs engage only when `.guardrails/units.yaml` exists and
`GR_CONFIG` names a declared unit's config.

### 4.3 Commands

```sh
sh tests/.bats-core/bin/bats tests/check-trace.bats && sh tests/run-tests.sh
git add -A && git -c commit.gpgsign=false commit -m "feat: check-trace under scope — four-way classification, expectations, exports"
```

### T4 — DONE (dispatch report, landed)

```
red -> green: 15 of 18 watched fail in bats for the right reason (red state
  is commit dabb3fb on the task branch). Exceptions, each verified honestly:
  two were spuriously green at red under macOS bash 3.2 (see finding below)
  and had their discriminating assertions watched evaluating false via
  in-place probes before implementation; one is a preservation test, green
  by design. At green all 18 also pass in an assertion-armed shadow copy
  (every [[ ]] given || false — 33 assertions armed).
result: check-trace.bats 212/212; full suite 526/527, the 1 being the
  census pin (check-trace.sh gr_def_re 2->3; after that bump the same test
  will report GR_AWK_CIVIL 2->3) — left for fan-in as adjudicated.
plan defects fixed in check-trace.sh: (1) blocks (d)/(f) ran under set -f
  but gr_exported_reqs -> gr_md_files needs the *.md glob — every scoped
  run with a dependency died exit 2; bracketed set +f/set -f (manifest
  validation already refuses glob characters in entries). (2) the met-check
  awk used `exp` as an array name — BWK awk rejects its builtin's name:
  syntax error, every expectation reads unmet; renamed expd (both sites).
SUITE-WIDE FINDING (pre-existing, outside T4's file set, for the record and
  a future problem report): bats runs under macOS system bash 3.2.57, where
  errexit does not fire on a failing bare [[ ]] mid-function — only a
  test's last command decides the verdict. Mid-test assertions in existing
  tests are silently unenforced on macOS; on Linux bash they work. Suite
  convention `[[ … ]] || false` would close it.
```

---

## T5 — `check-ids.sh` under scope

**Files touched:** `scripts/check-ids.sh`, `tests/check-ids.bats`
**Parallel:** yes (after T3; disjoint from T4, T6–T10)
**Trace:** architecture item 5. Obligations **duplicate-id-stays-tree-wide**,
**disclaimed-prose-is-not-malformed** (the scoped half — no unit run scans a
disclaimed path; T6 owns the repo-level half).

### 5.1 Failing tests (`tests/check-ids.bats`)

```bash
@test "check-ids: a manifest repo without GR_CONFIG is exit 2 naming the remedy" {
    make_units_fixture
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"multi-unit repository"* ]]
}

@test "check-ids: a sibling's draft file and draft token are not this unit's finding" {
    make_units_fixture
    printf '# draft\nREQ-DRAFT-other-change-1\n' > platform/hal/docs/requirements/DRAFT-other-change-notes.md
    commit_all sibling-draft
    unit_run check-ids.sh apps/pump
    [ "$status" -eq 0 ]
    unit_run check-ids.sh platform/hal
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-ID"* ]]
    [[ "$output" == *"DRAFT-FILE"* ]]
}

@test "check-ids: disclaimed-prose-is-not-malformed — a scoped run never reads a disclaimed path" {
    make_units_fixture
    printf '**REQ-abcdef**: legacy prose in definition shape.\n' >> legacy/notes.md
    commit_all legacy-prose
    unit_run check-ids.sh apps/pump
    [ "$status" -eq 0 ]
}

@test "check-ids: duplicate-id-stays-tree-wide — a cross-unit duplicate convicts from either unit" {
    make_units_fixture
    printf '\n**REQ-h4m2p9**: a colliding definition.\n' >> apps/pump/docs/requirements/0001-01-01-base.md
    commit_all dup
    unit_run check-ids.sh apps/pump
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID REQ-h4m2p9"* ]]
    unit_run check-ids.sh platform/hal
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID REQ-h4m2p9"* ]]
}

@test "check-ids: duplicate-id-stays-tree-wide — a duplicate under a disclaimed path still convicts" {
    make_units_fixture
    printf '**REQ-h4m2p9**: stale copy of the interface contract.\n' >> legacy/notes.md
    commit_all legacy-dup
    unit_run check-ids.sh platform/hal
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID REQ-h4m2p9"* ]]
}
```

### 5.2 Implementation (`scripts/check-ids.sh`)

After the `cd`, before `gr_check_config`: `gr_unit_engage` (same comment as
T4a). Then scope the three own-scope scans and leave the fourth alone:

- **DRAFT-ID scan**: pathspec becomes
  `if [ -n "$GR_UNIT" ]; then … -- "$GR_UNIT"; else … -- . "$GR_SCAN_EXCLUDE"; fi`
  — structure it as a variable-free `if/else` around the one `git grep`
  (a pathspec pair cannot live in one quoted variable). Comment:

  ```sh
  # Scoped, drafts narrow to the unit: a sibling's drafts are the sibling's
  # change in flight, and convicting them here would make any unit's merge
  # block on every other unit's work in progress (architecture item 5). A
  # disclaimed path is then scanned by NO unit run — check-units.sh convicts
  # DISCLAIMED-DRAFT there at the repository level instead.
  ```

- **DRAFT-FILE scan**: `git ls-files --cached --others --exclude-standard`
  gains `-- "$GR_UNIT"` when scoped.

- **MALFORMED-ID scan**: same `if/else` pathspec split. Comment:

  ```sh
  # MALFORMED-ID deliberately narrows too, and deliberately NOWHERE covers a
  # disclaimed path (risk assessment 3, 2026-09-03): legacy prose in
  # definition shape would convict line by line and drive pattern-widening —
  # the exact pressure the assessment names. The narrowness is gated:
  # disclaimed-prose-is-not-malformed.
  ```

- **DUPLICATE-ID scan**: pathspec UNCHANGED (`-- . "$GR_SCAN_EXCLUDE"`), with:

  ```sh
  # DUPLICATE-ID stays TREE-WIDE under scope (architecture item 5): IDs are
  # one global namespace, and a cross-unit duplicate must convict somewhere
  # even when neither unit depends on the other. This is the only gate that
  # sees it, the scan is read-only over definitions, and no false green rides
  # on it — a disclaimed path included.
  ```

Header comment gains one engagement paragraph (same wording as T4j).

### 5.3 Commands

```sh
sh tests/.bats-core/bin/bats tests/check-ids.bats && sh tests/run-tests.sh
git add -A && git -c commit.gpgsign=false commit -m "feat: check-ids under scope — drafts narrow, duplicates stay tree-wide"
```

### T5 — DONE (dispatch report, landed)

```
red -> green: 3 of 5 new tests watched fail for the right reason (wrong exit-2
  cause / sibling draft convicted / disclaimed prose convicted) before the
  implementation existed
pins (green on arrival, both validated by sabotage — scoping the DUPLICATE-ID
  pathspec flipped them red, restore green): the two
  duplicate-id-stays-tree-wide tests
result: 514/514 full suite on the branch (check-ids.bats 44/44)
finding: the change branch was RED on check-ids test 11 after T3 merged —
  T3's gr_req_scan/gr_unit_srs added a third GR_ID_BODY use, a first
  GR_AWK_ITEM_BLOCK use and a third gr_md_files call in lib.sh, all pinned;
  T3's reported green full suite evidently raced its final edits. T5 owned
  check-ids.bats and updated the three pins with comments naming gr_req_scan;
  the uses are all in the plan's T3 code — intended (confirmed by the
  dispatcher). T5 also hoisted check-ids.sh's loose pattern into one
  def_re_loose variable so its call-site pin stays 1, and used
  `-- "${GR_UNIT:-.}"` for DRAFT-FILE (single pathspec, no if/else).
  The seen-eq-8 script censuses stay for fan-in.
```

---

## T6 — `check-units.sh`: default mode and the no-manifest scans

**Files touched:** `scripts/check-units.sh` (new), `tests/check-units.bats` (new)
**Parallel:** yes (after T3; disjoint from T4, T5, T8, T9, T10)
**Trace:** architecture items 1 (stray-configs scan) and 6 (default mode).
Obligations **stray-unit-configs-without-manifest-are-exit-2**,
**near-miss-manifest-name-is-exit-2**,
**near-miss-without-manifest-content-passes**, **unclaimed-path-convicts**,
**root-files-implicitly-disclaimed**, **tbd-class-on-edge-is-exit-2**,
**class-floor-convicts**, **segregation-citation-must-resolve**,
**disclaimed-draft-convicts-at-repo-level**, **disclaimed-prose-is-not-malformed**
(repo half), **no-manifest-changes-nothing**.

### 6.1 Failing tests (`tests/check-units.bats`, new file)

```bash
load helpers

@test "check-units: no-manifest-changes-nothing — a single-unit repo exits 0 stating what it proved" {
    make_fixture_repo
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"no units.yaml — single-unit repository; no unit configs found astray"* ]]
}

@test "check-units: one non-root config without a manifest still passes (the GR_CONFIG layout)" {
    make_fixture_repo
    mkdir -p proj/.guardrails
    cp .guardrails/config.yaml proj/.guardrails/config.yaml
    commit_all one-sub
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 0 ]
}

@test "check-units: stray-unit-configs-without-manifest-are-exit-2" {
    make_fixture_repo
    for d in pkg/a pkg/b; do
        mkdir -p "$d/.guardrails"
        cp .guardrails/config.yaml "$d/.guardrails/config.yaml"
    done
    commit_all strays
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"unit-shaped configs"* ]]
    [[ "$output" == *"units.yaml"* ]]
}

@test "check-units: near-miss-manifest-name-is-exit-2 — the class, not one member" {
    make_fixture_repo
    for name in units.yml unit.yaml UNITS.YAML Units.yaml; do
        printf 'units:\n  - pkg/a\n' > ".guardrails/$name"
        run sh .guardrails/scripts/check-units.sh
        [ "$status" -eq 2 ]
        [[ "$output" == *"did you mean .guardrails/units.yaml"* ]]
        rm ".guardrails/$name"
    done
}

@test "check-units: near-miss-without-manifest-content-passes — both directions" {
    make_fixture_repo
    printf 'concurrency: 4\n' > .guardrails/units.yml          # near-miss name, foreign content
    printf 'units:\n  - metric\n' > units.yml                   # manifest shape, repo root
    commit_all lookalikes
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 0 ]
}

@test "check-units: the units fixture passes default mode and reports its denominator" {
    make_units_fixture
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"units: 2, disclaimed 2"* ]]
}

@test "check-units: manifest shape errors surface here at exit 2" {
    make_units_fixture
    printf 'unitz:\n  - x\n' >> .guardrails/units.yaml
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 2 ]
}

@test "check-units: unclaimed-path-convicts" {
    make_units_fixture
    mkdir -p tools && printf 'x\n' > tools/build.sh
    commit_all tools
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNCLAIMED-PATH tools/build.sh"* ]]
}

@test "check-units: root-files-implicitly-disclaimed — root files and the manifest's own home pass" {
    make_units_fixture
    printf 'root\n' > CONTRIBUTING.md
    commit_all rootfile
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 0 ]          # README.md, CONTRIBUTING.md, .guardrails/** all implicit
}

@test "check-units: disclaimed-draft-convicts-at-repo-level" {
    make_units_fixture
    printf '# parked draft\nREQ-DRAFT-old-change-1\n' > legacy/DRAFT-old-change-notes.md
    commit_all parked
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DISCLAIMED-DRAFT"* ]]
    [[ "$output" == *"legacy/DRAFT-old-change-notes.md"* ]]
}

@test "check-units: disclaimed-prose-is-not-malformed — definition-shaped legacy prose convicts nothing" {
    make_units_fixture
    printf '**REQ-abcdef**: legacy prose with no digit.\n' >> legacy/notes.md
    commit_all legacy-prose
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 0 ]
}

@test "check-units: class-floor-convicts — provider below its consumer's class" {
    make_units_fixture
    sed -i.bak 's/^safety_class: B$/safety_class: A/' platform/hal/.guardrails/config.yaml
    sed -i.bak 's/^safety_class: B$/safety_class: C/' apps/pump/.guardrails/config.yaml
    rm -f platform/hal/.guardrails/config.yaml.bak apps/pump/.guardrails/config.yaml.bak
    commit_all classes
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISCLASSED-DEPENDENCY platform/hal"* ]]
    [[ "$output" == *"apps/pump"* ]]
}

@test "check-units: a declared, resolving segregation covers the edge" {
    make_units_fixture
    sed -i.bak 's/^safety_class: B$/safety_class: A/' platform/hal/.guardrails/config.yaml
    rm -f platform/hal/.guardrails/config.yaml.bak
    printf 'segregated_from:\n  - platform/hal (RC-p4q7t3)\n' >> apps/pump/.guardrails/config.yaml
    commit_all segregated
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 0 ]
}

@test "check-units: segregation-citation-must-resolve — dangling RC, missing ADR, alien shape" {
    make_units_fixture
    for cite in 'platform/hal (RC-zz9zz2)' 'platform/hal (adr: docs/adr/none.md)' 'platform/hal because we said so'; do
        cp apps/pump/.guardrails/config.yaml pump-cfg.bak
        printf 'segregated_from:\n  - %s\n' "$cite" >> apps/pump/.guardrails/config.yaml
        run sh .guardrails/scripts/check-units.sh
        [ "$status" -eq 1 ]
        [[ "$output" == *"INCOMPLETE-SEGREGATION"* ]]
        mv pump-cfg.bak apps/pump/.guardrails/config.yaml
    done
}

@test "check-units: a segregation entry naming a non-dependency is INCOMPLETE-SEGREGATION" {
    make_units_fixture
    printf 'segregated_from:\n  - apps/pump (RC-h3d8f4)\n' >> platform/hal/.guardrails/config.yaml
    commit_all wrong-way
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"INCOMPLETE-SEGREGATION"* ]]
}

@test "check-units: tbd-class-on-edge-is-exit-2" {
    make_units_fixture
    sed -i.bak 's/^safety_class: B$/safety_class: TBD/' platform/hal/.guardrails/config.yaml
    rm -f platform/hal/.guardrails/config.yaml.bak
    commit_all tbd
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"TBD"* ]]
}

@test "check-units: a TBD class on a unit with no dependency edge passes (tooth one)" {
    make_units_fixture
    make_unit svc/standalone
    write_unit_items svc/standalone REQ-s2t6u3 HAZ-s3v8w2 RC-s4x7y3 SDD-s5z2a8 LLR-s6b3c9
    sed -i.bak 's/^safety_class: B$/safety_class: TBD/' svc/standalone/.guardrails/config.yaml
    rm -f svc/standalone/.guardrails/config.yaml.bak
    cat > .guardrails/units.yaml <<'EOF'
units:
  - platform/hal
  - apps/pump
  - svc/standalone
not_a_unit:
  - legacy
  - docs
EOF
    commit_all standalone
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 0 ]
}
```

### 6.2 Implementation — `scripts/check-units.sh`, complete

The listing below is the FINAL script, flag modes included, so names and
shapes are pinned once. T6 lands it with the three flag-mode case arms
replaced by a single `gr_die "check-units.sh: $mode mode lands with the
impact task"` — T7 writes the failing tests for those modes first and then
fills the arms in exactly as printed here. Default mode and the no-manifest
branch are T6's tested deliverable.

```sh
#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# check-units.sh [--impact RANGE | --exports UNIT | --list]
#
# The repository-level entry point of the unit machinery
# (docs/plans/2026-09-03-units-architecture.md item 6). Default mode, exit 1
# findings after exit-2 validation:
#   UNCLAIMED-PATH PATH      — a tracked path claimed by no unit, not
#                              disclaimed, not a root-level file, not under
#                              the root .guardrails/ (D7)
#   MISCLASSED-DEPENDENCY U  — provider U's class below the ceiling of its
#                              consumers' classes, with no covering
#                              segregation (D5)
#   INCOMPLETE-SEGREGATION   — a segregated_from: entry that names a
#                              non-dependency, cites a control nobody defined,
#                              an ADR file that is absent, or nothing at all
#   DISCLAIMED-DRAFT         — a draft token or DRAFT-named file under a
#                              not_a_unit: path (risk assessment 3,
#                              2026-09-03): draft work has no legitimate home
#                              in a disclaimed directory, and no unit's scoped
#                              run scans one, so the conviction lives here —
#                              blocking every unit's merge is the point.
#                              MALFORMED-ID is deliberately NOT scanned on
#                              disclaimed paths: legacy prose in definition
#                              shape would convict line by line and drive
#                              pattern-widening (disclaimed-prose-is-not-
#                              malformed).
#
# Without a manifest, default mode exits 0 — AFTER refusing (exit 2) the two
# shapes that make "single-unit repository" a false reading: two or more
# unit-shaped configs with no manifest (a unit outside compliance at exit 0),
# and a near-miss manifest name in .guardrails/ with manifest-shaped content
# (a mistyped units.yaml silently reverting the repo to single-unit mode; risk
# assessment 2, 2026-09-03). The repository root is deliberately not scanned
# for near-misses — that is where another tool's units.yml legitimately lives.
#
# --impact RANGE: the units a change must run — touched units plus transitive
#   dependents (D6+D12), one per line as "<unit>\t<touched|dependent>". A
#   changed path claimed by nobody is exit 2 HERE (a partial impact set would
#   read as complete to merge-change); the finding to fix is default mode's
#   UNCLAIMED-PATH. A change under the root .guardrails/ maps to EVERY unit.
# --exports UNIT: the unit's export surface, "<REQ-id>\t<file>" per line —
#   the same computation (gr_exported_reqs) a consumer's verdicts resolve
#   against, so the report cannot lie about the gate.
# --list: the declared units, one per line (base-branch CI runs the union).
# All three flag modes REQUIRE the manifest: an empty exit-0 list would read
# as "no units to run" to a CI caller, which is a skipped suite wearing a
# green light.
#
# Exit codes: 0 pass, 1 findings (default mode), 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
# NOT `cd "$(gr_root)" || exit 2`: gr_root's gr_die exits only the command
# substitution, and under dash `cd ""` returns 0 and stays put.
gr_repo_root=$(gr_root) || exit 2
cd "$gr_repo_root" || exit 2

mode=default
arg=""
case "${1:-}" in
    ('') ;;
    (--impact)  mode=impact;  arg="${2:-}"; [ -n "$arg" ] || gr_die "usage: check-units.sh --impact RANGE"; [ $# -le 2 ] || gr_die "unknown argument: $3" ;;
    (--exports) mode=exports; arg="${2:-}"; [ -n "$arg" ] || gr_die "usage: check-units.sh --exports UNIT";  [ $# -le 2 ] || gr_die "unknown argument: $3" ;;
    (--list)    mode=list; [ $# -le 1 ] || gr_die "unknown argument: $2" ;;
    (*) gr_die "unknown argument: $1" ;;
esac

# Path lists are newline-separated throughout; entries reach git verbatim.
IFS='
'
set -f

if ! gr_units_present; then
    [ "$mode" = default ] || gr_die \
"no $GR_UNITS — single-unit repository; --impact, --exports and --list need a
  manifest. An empty answer here would read as 'no units to run', which is a
  skipped suite wearing a green light."

    # Two or more unit-shaped configs with no manifest: D2's rejected-glob
    # situation observed in the wild. The second config is invisible to every
    # script today — a unit outside compliance at exit 0. ONE non-root config
    # stays legal: it is the documented GR_CONFIG project-in-subdirectory
    # layout (risk assessment 2 verified the threshold).
    strays=$(git ls-files --cached --others --exclude-standard -- '*/.guardrails/config.yaml' 2>/dev/null)
    n_strays=$(printf '%s' "$strays" | grep -c .) || true
    if [ "$n_strays" -ge 2 ]; then
        gr_die \
"$n_strays unit-shaped configs with no manifest:
$(printf '%s\n' "$strays" | sed 's/^/  /')
  Each is invisible to every script here — a unit outside compliance while
  the run exits 0. Declare them in $GR_UNITS, or remove all but one."
    fi

    # The near-miss scan (risk assessment 2, 2026-09-03): only the manifest's
    # own directory, only the near-miss name class, only manifest-shaped
    # content. All three narrowings are load-bearing — see the assessment for
    # what each one leaves as accepted residual.
    for f in .guardrails/*; do
        [ -f "$f" ] || continue
        base=${f##*/}
        low=$(printf '%s' "$base" | tr 'A-Z' 'a-z')
        case "$low" in
            (units.yaml|units.yml|unit.yaml|unit.yml) ;;
            (*) continue ;;
        esac
        [ "$base" = "units.yaml" ] && continue
        if LC_ALL=C awk '
                FNR == 1 { sub(/^\357\273\277/, "") }
                /^(units|not_a_unit):/ { found = 1; exit }
                END { exit !found }' "$f"; then
            gr_die \
"found $f with manifest-shaped content — did you mean .guardrails/units.yaml?
  Nothing reads this file, so the repository would run in single-unit mode
  with every scope gate off while it looks configured."
        fi
    done

    echo "no units.yaml — single-unit repository; no unit configs found astray"
    exit 0
fi

# Manifest present: validate it and every unit config first — a manifest
# defect is a wrong scope for every scan, worse than any finding below.
gr_check_units

units=$(gr_unit_list)
disclaimed=$(gr_disclaimed_list)

# unit_class UNIT — safety_class, validated: A, B or C prints its rank; TBD
# and anything else dies, but ONLY when the caller is computing an edge (D5:
# a floor computed from a placeholder is a gate disabling itself). Standalone
# units keep TBD legally — tooth one.
class_rank() {
    case "$1" in
        (A) echo 1 ;;
        (B) echo 2 ;;
        (C) echo 3 ;;
        (*) return 1 ;;
    esac
}

# deps_of UNIT — its depends_on list.
deps_of() { cfg_list depends_on "$1/.guardrails/config.yaml"; }

case "$mode" in
(list)
    printf '%s\n' "$units"
    exit 0
    ;;
(exports)
    gr_contains "$units" "$arg" || gr_die \
"--exports: not a declared unit: $arg
  Declared units: $(printf '%s' "$units" | tr '\n' ' ')"
    gr_exported_reqs "$arg"
    exit 0
    ;;
(impact)
    changed=$(git diff --name-only "$arg" -- 2>&1) || gr_die "git diff failed for '$arg': $changed"
    touched=""
    for p in $changed; do
        case "$p" in
            (*/*) ;;
            (*) continue ;;                    # root-level file: implicitly disclaimed
        esac
        case "$p" in
            (.guardrails/*)
                # The manifest or the installed scripts changed: every unit's
                # gates ran under the old tool, so every unit is in the blast
                # radius. The safe direction is to run them all.
                touched="$units"
                continue ;;
        esac
        w=$(gr_unit_of_path "$p") || gr_die \
"--impact: changed path claimed by no unit and not disclaimed: $p
  The impact set cannot be computed over an unowned path — a partial list
  would read as complete to merge-change. Fix default mode's UNCLAIMED-PATH
  first (claim the path in a unit, or disclaim it in $GR_UNITS)."
        case "$w" in
            (not_a_unit\ *) continue ;;
            (*) gr_contains "$touched" "$w" || touched="${touched}${touched:+
}$w" ;;
        esac
    done
    # Transitive closure over reverse depends_on (D12): a unit whose
    # dependency chain reaches a touched unit ships that unit's changed
    # object code, whatever the intermediate contracts say.
    impact="$touched"
    grew=1
    while [ "$grew" -eq 1 ]; do
        grew=0
        for u in $units; do
            gr_contains "$impact" "$u" && continue
            for d in $(deps_of "$u"); do
                if gr_contains "$impact" "$d"; then
                    impact="${impact}${impact:+
}$u"
                    grew=1
                    break
                fi
            done
        done
    done
    for u in $units; do          # manifest order, stable output
        if gr_contains "$touched" "$u"; then
            printf '%s\ttouched\n' "$u"
        elif gr_contains "$impact" "$u"; then
            printf '%s\tdependent\n' "$u"
        fi
    done
    exit 0
    ;;
esac

# --- default mode findings ---------------------------------------------------
fail=0

# UNCLAIMED-PATH (D7): every tracked path is claimed by a unit, disclaimed,
# a root-level file, or under the root .guardrails/ (the manifest's own home
# — D7 names "the manifest itself" implicitly disclaimed, and the installed
# scripts live beside it). Everything else is the distinction D2's rejected
# glob could not make: "not yet ratcheted", loudly.
unclaimed=$(git ls-files --cached --others --exclude-standard 2>/dev/null | {
    while IFS= read -r p; do
        case "$p" in
            (*/*) ;;
            (*) continue ;;
        esac
        case "$p" in (.guardrails/*) continue ;; esac
        gr_unit_of_path "$p" >/dev/null || printf '%s\n' "$p"
    done
})
if [ -n "$unclaimed" ]; then
    printf '%s\n' "$unclaimed" | sed 's/^/UNCLAIMED-PATH /'
    echo "guardrails: every tracked path is claimed by a unit or disclaimed under" >&2
    echo "not_a_unit: in $GR_UNITS — an unclaimed path is code outside compliance" >&2
    echo "that nothing would ever scan." >&2
    fail=1
fi

# DISCLAIMED-DRAFT (risk assessment 3, 2026-09-03): draft tokens and
# DRAFT-named files under disclaimed paths. No unit run scans these paths, so
# the conviction lives at the repository level, where it blocks every merge.
draft_re="[A-Za-z][A-Za-z0-9]*-DRAFT-[A-Za-z0-9][A-Za-z0-9-]*-[0-9]+"
for d in $disclaimed; do
    [ -e "$d" ] || continue
    hits=$(git grep -In --untracked -E "$draft_re" -- "$d" 2>/dev/null)
    _st=$?
    [ "$_st" -le 1 ] || gr_die "DISCLAIMED-DRAFT token scan failed on $d (git grep exit $_st)"
    if [ -n "$hits" ]; then
        printf '%s\n' "$hits" | sed 's/^/DISCLAIMED-DRAFT /'
        fail=1
    fi
    dfiles=$(git ls-files --cached --others --exclude-standard -- "$d" 2>/dev/null \
        | grep -E '(^|/)DRAFT-[^/]*$' || true)
    if [ -n "$dfiles" ]; then
        printf '%s\n' "$dfiles" | sed 's/^/DISCLAIMED-DRAFT /'
        fail=1
    fi
done

# The class floor (D5) and its escape. Per consumer edge: the provider's
# class must reach the consumer's, or the consumer declares segregation whose
# citation resolves.
for c in $units; do
    c_cfg="$c/.guardrails/config.yaml"
    seg=$(cfg_list segregated_from "$c_cfg")

    # INCOMPLETE-SEGREGATION: judge every entry, whether or not the floor
    # currently needs it — a dangling citation is the classic false-green
    # shape, and it must not wait for the class change that exposes it.
    for s in $seg; do
        s_path=${s%% (*}
        if [ "$s_path" = "$s" ]; then
            echo "INCOMPLETE-SEGREGATION $c: '$s' (no parenthesised citation — name the RC or ADR that argues the segregation)"
            fail=1
            continue
        fi
        s_cite=${s#* (}
        s_cite=${s_cite%)}
        if ! gr_contains "$(deps_of "$c")" "$s_path"; then
            echo "INCOMPLETE-SEGREGATION $c: '$s' ($s_path is not a declared dependency of $c)"
            fail=1
            continue
        fi
        case "$s_cite" in
            (RC-*)
                git grep -q --untracked -E "^\\*\\*${s_cite}\\*\\*:" -- . "$GR_SCAN_EXCLUDE" 2>/dev/null || {
                    echo "INCOMPLETE-SEGREGATION $c: '$s' (cited control $s_cite is defined nowhere)"
                    fail=1
                } ;;
            (adr:*)
                s_adr=${s_cite#adr:}
                s_adr=${s_adr# }
                [ -f "$s_adr" ] || {
                    echo "INCOMPLETE-SEGREGATION $c: '$s' (cited ADR file does not exist: $s_adr)"
                    fail=1
                } ;;
            (*)
                echo "INCOMPLETE-SEGREGATION $c: '$s' (citation is neither (RC-…) nor (adr: path))"
                fail=1 ;;
        esac
    done

    c_class=$(cfg_get safety_class "$c_cfg")
    for p in $(deps_of "$c"); do
        p_class=$(cfg_get safety_class "$p/.guardrails/config.yaml")
        # TBD on either end of an EDGE is exit 2 (D5): the interview never
        # happened, and a floor computed from a placeholder is a gate
        # disabling itself. A standalone unit keeps TBD legally.
        for end in "$c:$c_class" "$p:$p_class"; do
            case "${end#*:}" in
                (A|B|C) ;;
                (*) gr_die \
"safety_class is '${end#*:}' on unit ${end%%:*}, which sits on a dependency
  edge ($c -> $p). The class floor cannot be computed from a placeholder —
  run the ratchet safety-class interview for that unit first." ;;
            esac
        done
        cr=$(class_rank "$c_class")
        pr=$(class_rank "$p_class")
        if [ "$pr" -lt "$cr" ]; then
            covered=0
            for s in $seg; do
                s_path=${s%% (*}
                [ "$s_path" = "$p" ] && { covered=1; break; }
            done
            # A covering entry that does not RESOLVE was already reported
            # INCOMPLETE-SEGREGATION above; it still suppresses the floor
            # finding here so one defect is reported as one defect, under
            # the diagnosis that names the remedy.
            if [ "$covered" -eq 0 ]; then
                echo "MISCLASSED-DEPENDENCY $p (class $p_class) below consumer $c (class $c_class) — raise the provider's class, or declare segregation in the consumer's segregated_from: naming the RC or ADR that argues it (IEC 62304 5.3.5)"
                fail=1
            fi
        fi
    done
done

echo "units: $(printf '%s' "$units" | grep -c .), disclaimed $(printf '%s' "$disclaimed" | grep -c .); tracked paths $(git ls-files --cached --others --exclude-standard | grep -c .)"

exit $fail
```

Two notes for the implementer:

- The `while IFS= read -r` in the UNCLAIMED-PATH scan runs in a subshell of a
  pipeline; it only ACCUMULATES (no `fail=` inside), so nothing is lost —
  the aggregation happens outside, on the captured variable.
- `case "$p" in (*/*)` skipping root files IS obligation
  **root-files-implicitly-disclaimed**; do not "tighten" it to a whitelist.

### 6.3 Commands

```sh
sh tests/.bats-core/bin/bats tests/check-units.bats && sh tests/run-tests.sh
git add -A && git -c commit.gpgsign=false commit -m "feat: check-units — manifest gate, claim map, class floor, disclaimed drafts"
```

### T6 — DONE (dispatch report, landed)

```
red -> green: all 17 tests watched fail for the right reason (exit 127,
  script not found) before the implementation existed;
  near-miss-manifest-name-is-exit-2 watched fail a SECOND time against the
  plan's verbatim listing (both defects below), then green after the fixes
result: 17/17 targeted; full suite green except 3 pinned-count censuses
  adjudicated expected-red-at-fan-in (bumped by the dispatcher when the
  ninth script lands in the change worktree): check-ids.bats census
  ("unpinned script: scripts/check-units.sh"), check-ids.bats POSIX-parse
  count (8->9), lib.bats gr_root count (7->8; the new script PASSED the
  per-script exit-2 assertion — only the count pin failed)
plan-listing defects caught red, fixed in check-units.sh with comments:
  (1) the near-miss scan's `for f in .guardrails/*` glob ran under the
  script's own `set -f` — silently dead; bracketed set +f/set -f.
  (2) APFS case-insensitivity: `[ -f .guardrails/units.yaml ]` matches
  UNITS.YAML, routing a near-miss NAME into gr_check_units with the wrong
  diagnosis; presence in check-units.sh now means the exact byte-name
  appears in the directory listing. lib.sh's gr_units_present untouched
  (other tasks' file) — RESIDUAL for the independent review: on a
  case-insensitive filesystem the scoped scripts' engagement rule may
  engage off a case-variant manifest name.
```

---

## T7 — `check-units.sh`: `--impact`, `--exports`, `--list`

**Files touched:** `scripts/check-units.sh`, `tests/check-units.bats`
**Parallel:** no (serial, after T6 — same files)
**Trace:** architecture item 6 (the three modes). Obligations
**impact-set-is-transitive**, **unrelated-unit-skips**,
**impact-unclaimed-path-is-exit-2**.

### 7.1 Failing tests (`tests/check-units.bats`)

A three-tier fixture for transitivity, built on the standard one:

```bash
# hal <- pump <- monitor, plus svc/standalone with no edges.
add_third_tier() {
    make_unit apps/monitor apps/pump
    write_unit_items apps/monitor REQ-m2n6p3 HAZ-m3q8r2 RC-m4s7t3 SDD-m5u2v8 LLR-m6w3x9
    make_unit svc/standalone
    write_unit_items svc/standalone REQ-s2t6u3 HAZ-s3v8w2 RC-s4x7y3 SDD-s5z2a8 LLR-s6b3c9
    cat > .guardrails/units.yaml <<'EOF'
units:
  - platform/hal
  - apps/pump
  - apps/monitor
  - svc/standalone
not_a_unit:
  - legacy
  - docs
EOF
    commit_all third-tier
}

@test "check-units: --list prints the declared units, one per line" {
    make_units_fixture
    run sh .guardrails/scripts/check-units.sh --list
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "platform/hal" ]
    [ "${lines[1]}" = "apps/pump" ]
}

@test "check-units: flag modes without a manifest are exit 2, never an empty list" {
    make_fixture_repo
    for m in --list "--exports x" "--impact HEAD~1..HEAD"; do
        # shellcheck disable=SC2086
        run sh .guardrails/scripts/check-units.sh $m
        [ "$status" -eq 2 ]
        [[ "$output" == *"single-unit repository"* ]]
    done
}

@test "check-units: --exports lists the export surface with its defining files" {
    make_units_fixture
    run sh .guardrails/scripts/check-units.sh --exports platform/hal
    [ "$status" -eq 0 ]
    [[ "$output" == "REQ-h4m2p9	platform/hal/docs/requirements/0001-01-01-base.md" ]]
    run sh .guardrails/scripts/check-units.sh --exports apps/pump
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    run sh .guardrails/scripts/check-units.sh --exports no/such
    [ "$status" -eq 2 ]
}

@test "check-units: impact-set-is-transitive — a hal change reaches monitor through pump" {
    make_units_fixture
    add_third_tier
    printf 'x\n' > platform/hal/src/new.c
    commit_all hal-change
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [ "$status" -eq 0 ]
    [[ "$output" == *"platform/hal	touched"* ]]
    [[ "$output" == *"apps/pump	dependent"* ]]
    [[ "$output" == *"apps/monitor	dependent"* ]]
}

@test "check-units: unrelated-unit-skips — the standalone unit never appears" {
    make_units_fixture
    add_third_tier
    printf 'x\n' > platform/hal/src/new.c
    commit_all hal-change
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [ "$status" -eq 0 ]
    [[ "$output" != *"svc/standalone"* ]]
}

@test "check-units: --impact — a touched unit is reported touched, not dependent" {
    make_units_fixture
    printf 'x\n' > apps/pump/src/new.c
    printf 'y\n' > platform/hal/src/new.c
    commit_all both
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [[ "$output" == *"apps/pump	touched"* ]]
    [[ "$output" == *"platform/hal	touched"* ]]
}

@test "check-units: --impact — disclaimed and root-level changes map to no unit" {
    make_units_fixture
    printf 'z\n' >> legacy/notes.md
    printf 'r\n' >> README.md
    commit_all outside
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "check-units: --impact — a repository-level .guardrails change maps to every unit" {
    make_units_fixture
    printf '# comment\n' >> .guardrails/units.yaml
    commit_all manifest-touch
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [ "$status" -eq 0 ]
    [[ "$output" == *"platform/hal	touched"* ]]
    [[ "$output" == *"apps/pump	touched"* ]]
}

@test "check-units: impact-unclaimed-path-is-exit-2" {
    make_units_fixture
    mkdir -p tools && printf 'x\n' > tools/build.sh
    commit_all tools
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [ "$status" -eq 2 ]
    [[ "$output" == *"UNCLAIMED-PATH"* ]]
}

@test "check-units: --impact on a bad range is exit 2, never an empty set" {
    make_units_fixture
    run sh .guardrails/scripts/check-units.sh --impact 'no..such..range'
    [ "$status" -eq 2 ]
}
```

### 7.2 Implementation

Replace the T6 stub arms with the `list`/`exports`/`impact` case arms exactly
as printed in the T6 listing.

### 7.3 Commands

```sh
sh tests/.bats-core/bin/bats tests/check-units.bats && sh tests/run-tests.sh
git add -A && git -c commit.gpgsign=false commit -m "feat: check-units --impact/--exports/--list — the mechanical impact set"
```

### T7 — DONE (dispatch report, landed)

```
red -> green: 8 of 10 watched fail against T6's stub for the right reason;
  --exports failed a SECOND time against the plan's verbatim arm (set -f
  defect, third of T4/T6's class) and went green after the fix. The two
  that could not be red against a stub that also exits 2: the no-manifest
  refusal (landed with T6; probed — right message) and the bad-range test
  (probed post-green: "git diff failed ... bad revision").
result: check-units.bats 27/27; full suite 572/572 (census pins hold —
  zero pattern uses added; lib helpers only).
fix in check-units.sh: exports arm bracketed set +f/set -f — gr_exported_reqs
  reaches gr_md_files' *.md glob via gr_unit_srs, dead under global noglob.
convention: new tests carry `|| false` on mid-test [[ ]] (bash-3.2 finding).
```

---

## T8 — `new-id.sh` unit selection

**Files touched:** `scripts/new-id.sh`, `tests/new-id.bats`
**Parallel:** yes (after T3; disjoint from T4–T7, T9, T10)
**Trace:** architecture item 7. Obligations **new-id-infers-unit-from-cwd**,
**new-id-outside-unit-requires-flag**.

### 8.1 Failing tests (`tests/new-id.bats`)

```bash
@test "new-id: new-id-infers-unit-from-cwd — minting inside a unit needs no ceremony" {
    make_units_fixture
    cd apps/pump/src
    run sh ../../../.guardrails/scripts/new-id.sh REQ
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^REQ-[abcdefghjkmnpqrstuvwxyz23456789]{6}$ ]]
}

@test "new-id: new-id-outside-unit-requires-flag — at the root it refuses and lists the units" {
    make_units_fixture
    run sh .guardrails/scripts/new-id.sh REQ
    [ "$status" -eq 2 ]
    [[ "$output" == *"platform/hal"* ]]
    [[ "$output" == *"apps/pump"* ]]
    [[ "$output" == *"--unit"* ]]
}

@test "new-id: --unit selects explicitly, from anywhere" {
    make_units_fixture
    run sh .guardrails/scripts/new-id.sh --unit platform/hal REQ
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^REQ- ]]
    run sh .guardrails/scripts/new-id.sh --unit no/such REQ
    [ "$status" -eq 2 ]
}

@test "new-id: --unit disagreeing with an explicit GR_CONFIG is exit 2, never a guess" {
    make_units_fixture
    GR_CONFIG=apps/pump/.guardrails/config.yaml \
        run sh .guardrails/scripts/new-id.sh --unit platform/hal REQ
    [ "$status" -eq 2 ]
    [[ "$output" == *"disagree"* ]]
}

@test "new-id: an explicit unit GR_CONFIG alone still works (the engagement rule)" {
    make_units_fixture
    GR_CONFIG=apps/pump/.guardrails/config.yaml run sh .guardrails/scripts/new-id.sh REQ
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^REQ- ]]
}

@test "new-id: the mint collision scan stays tree-wide under scope" {
    make_units_fixture
    # wedge the draw to an ID defined in the OTHER unit: the scan must see it
    run sh -c 'cd apps/pump && GR_ID_FORCE_TOKEN=h4m2p9 sh ../../.guardrails/scripts/new-id.sh REQ'
    [ "$status" -eq 2 ]
    [[ "$output" == *"100 attempts"* ]]
}
```

### 8.2 Implementation (`scripts/new-id.sh`)

**(a)** Before sourcing lib.sh, capture what only this moment can see:

```sh
# Captured BEFORE lib.sh runs: lib fills GR_CONFIG's default in, after which
# "the caller set it" and "nobody set it" read identically — and the unit
# inference below must never override an explicit choice.
gr_config_env="${GR_CONFIG:-}"
# The caller's directory, captured before the cd to the repository root: it is
# the unit-selection signal (architecture item 7) and exists nowhere else.
caller_pwd=$(pwd -P)
```

**(b)** Argument parsing grows the flag (before the existing `prefix=` line):

```sh
unit_arg=""
if [ "${1:-}" = "--unit" ]; then
    unit_arg="${2:-}"
    [ -n "$unit_arg" ] || gr_die "usage: new-id.sh [--unit PATH] PREFIX [COUNT]"
    shift 2
fi
```

**(c)** Unit selection, after the `cd` and INSTEAD of the bare
`gr_check_config` (which moves below it):

```sh
# Unit selection (architecture item 7). In a manifest repository an ID must
# be minted against SOME unit's config — the gates that will ever check the
# item are that unit's. Inside a unit, the caller's cwd says which; --unit
# says it explicitly; nothing else is inferred, because a wrong guess mints
# an ID whose gates are another unit's.
if gr_units_present; then
    gr_check_units
    unit=""
    if [ -n "$unit_arg" ]; then
        gr_contains "$(gr_unit_list)" "$unit_arg" || gr_die \
"--unit does not name a declared unit: $unit_arg
  Declared units: $(gr_unit_list | tr '\n' ' ')"
        if [ -n "$gr_config_env" ] && [ "$gr_config_env" != "$unit_arg/.guardrails/config.yaml" ]; then
            gr_die \
"--unit $unit_arg and GR_CONFIG=$gr_config_env disagree — refusing to guess
  which one you meant. Drop one of the two."
        fi
        unit="$unit_arg"
    elif [ -n "$gr_config_env" ]; then
        gr_unit_engage          # validates GR_CONFIG names a declared unit
        unit="$GR_UNIT"
    else
        rel="${caller_pwd#"$gr_repo_root"}"
        rel="${rel#/}"
        for u in $(gr_unit_list); do
            case "$rel" in ("$u" | "$u"/*) unit="$u"; break ;; esac
        done
        [ -n "$unit" ] || gr_die \
"not inside any declared unit, and no --unit given — a wrong guess would mint
  an ID whose gates are another unit's. Run from inside a unit, or select one:
  new-id.sh --unit <path> PREFIX. Declared units: $(gr_unit_list | tr '\n' ' ')"
    fi
    GR_CONFIG="$unit/.guardrails/config.yaml"
elif [ -n "$unit_arg" ]; then
    gr_die "--unit given but there is no $GR_UNITS — this is a single-unit repository"
fi

gr_check_config
```

The collision scan later in the script keeps its `-- . "$GR_SCAN_EXCLUDE"`
pathspec untouched, with one added comment line: tree-wide even under scope —
IDs are one global namespace (architecture item 5's DUPLICATE-ID reasoning
applies at mint time identically).

### 8.3 Commands

```sh
sh tests/.bats-core/bin/bats tests/new-id.bats && sh tests/run-tests.sh
git add -A && git -c commit.gpgsign=false commit -m "feat: new-id selects its unit — cwd containment, --unit, never a guess"
```

### T8 — DONE (dispatch report, landed)

```
red -> green: 5 of 6 new tests watched fail for the right reason (missing
  root config / no --unit guidance / no "disagree" message / collision test
  died before the scan) before the implementation existed
pin (green before implementation, kept as regression guard): "an explicit
  unit GR_CONFIG alone still works" — explicit GR_CONFIG already routed
  through gr_check_config
result: 515 passed, 0 failed on the task branch (new-id.bats 27/27); all 21
  pre-existing new-id tests byte-identical green; collision-scan pathspec
  untouched
surprises: none beyond the pin
```

---

## T9 — `check-review.sh` and `finalize-docs.sh` under the engagement rule

**Files touched:** `scripts/check-review.sh`, `scripts/finalize-docs.sh`,
`tests/check-review.bats`, `tests/finalize-docs.bats`
**Parallel:** yes (after T3; disjoint from T4–T8, T10)
**Trace:** architecture item 9. Obligations
**review-record-is-repository-level**, **finalize-runs-per-touched-unit**.

### 9.1 Failing tests

`tests/check-review.bats`:

```bash
@test "check-review: review-record-is-repository-level — no unit config, manifest validated, root records read" {
    make_units_fixture
    make_change_worktree units-change
    write_record rec units-change
    commit_all record
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"records"* ]]     # the existing checked: summary
}

@test "check-review: a manifest repo with a broken manifest is exit 2 here too" {
    make_units_fixture
    printf 'unitz:\n  - x\n' >> .guardrails/units.yaml
    make_change_worktree units-change
    write_record rec units-change
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
}

@test "check-review: a manifest repo missing docs/verification is exit 2 naming the rule" {
    make_units_fixture
    git rm -rq docs/verification 2>/dev/null || rm -rf docs/verification
    commit_all no-vdir
    make_change_worktree units-change
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"docs/verification"* ]]
}
```

`tests/finalize-docs.bats`:

```bash
@test "finalize-docs: finalize-runs-per-touched-unit — GR_CONFIG scopes the rename to one unit" {
    make_units_fixture
    printf '# pump draft\n' > apps/pump/docs/requirements/DRAFT-my-change-notes.md
    printf '# hal draft\n' > platform/hal/docs/requirements/DRAFT-my-change-notes.md
    commit_all drafts
    GR_CONFIG=apps/pump/.guardrails/config.yaml run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ]
    [ ! -e apps/pump/docs/requirements/DRAFT-my-change-notes.md ]
    [ -e platform/hal/docs/requirements/DRAFT-my-change-notes.md ]
}

@test "finalize-docs: a manifest repo without GR_CONFIG is exit 2 naming the remedy" {
    make_units_fixture
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"multi-unit repository"* ]]
}
```

### 9.2 Implementation

`scripts/check-review.sh` — replace the bare `gr_check_config` and the
`dir=$(gr_verification_dir) || exit 2` pair:

```sh
# The review artefact is REPOSITORY-LEVEL (architecture item 9): one change,
# one signed squash, one record, whatever units the change touched. In a
# manifest repository there is no root config to validate — the manifest's
# exclusivity rule removed it — so the manifest itself is validated in its
# place, and the records live at the defaulted root location. Everything
# branch-shaped below is untouched.
if gr_units_present; then
    gr_check_units
    dir=docs/verification
    [ -d "$dir" ] || gr_die \
"docs/verification does not exist — in a multi-unit repository the
  verification records live at the repository root (one record per change;
  the record's subject is the change, not a unit). Create the directory."
else
    gr_check_config
    dir=$(gr_verification_dir) || exit 2
fi
```

`scripts/finalize-docs.sh` — one line after the `cd`, before
`gr_check_config`:

```sh
# Unit-scoped by nature: this renames drafts inside ONE config's doc_*
# directories. merge-change runs it once per touched unit of the impact set,
# GR_CONFIG pointing at each (architecture item 9) — so in a manifest
# repository a bare invocation must refuse rather than rename nothing and
# report success.
gr_unit_engage
```

(Everything else already follows: `cfg_get` reads the unit's config, whose
paths T2 pinned inside the unit.)

### 9.3 Commands

```sh
sh tests/.bats-core/bin/bats tests/check-review.bats tests/finalize-docs.bats
sh tests/run-tests.sh
git add -A && git -c commit.gpgsign=false commit -m "feat: repo-level review record and per-unit finalize under the manifest"
```

### T9 — DONE (dispatch report, landed)

```
red -> green: 4 of 5 new tests watched fail for the right reason before the
  implementation existed (config-not-found instead of the manifest path /
  remedy never named)
pin (never red): finalize-runs-per-touched-unit — cfg_get already reads
  GR_CONFIG, so the scoping pre-existed; the test pins that gr_unit_engage
  does not break a correctly scoped run
result: targeted 76/76; full suite 514/514, census rows unchanged
plan defects found and fixed in the pinned test code (both in T9's own
  files): the broken-manifest test never committed its unitz: edit (worktree
  checked out clean HEAD), and it asserted only exit 2 — already true
  pre-implementation via config-not-found; strengthened to require
  "unknown manifest key" so RED was observable.
```

---

## T10 — templates

**Files touched:** `templates/units.yaml` (new), `templates/config.yaml`,
`tests/lib.bats`
**Parallel:** yes (after T1; disjoint from every other task)
**Trace:** architecture item 8.

### 10.1 Failing tests (`tests/lib.bats`)

```bash
@test "templates: config template ships the expectation limits set" {
    grep -q '^expectation_age_days: 90$' "$BATS_TEST_DIRNAME/../templates/config.yaml"
    grep -q '^expectation_open_max: 10$' "$BATS_TEST_DIRNAME/../templates/config.yaml"
}

@test "templates: units.yaml template is inert — comments only, no live keys" {
    run grep -cE '^(units|not_a_unit):' "$BATS_TEST_DIRNAME/../templates/units.yaml"
    [ "$output" = "0" ]
}
```

(The second test is what keeps `/ratchet`'s copy-then-edit flow from shipping
a manifest that validates against directories that do not exist.)

### 10.2 Implementation

`templates/config.yaml` — append after the problem limits block:

```yaml
# Expectation triage limits (multi-unit repositories; docs/plans/
# 2026-09-03-units-architecture.md). An expectation is a consumer REQ carrying
# `expects: <unit>` — work owed by a declared dependency. Non-RC-linked ones
# age against these, exactly as problem reports age against the limits above;
# an expectation that implements a risk control fails every run regardless.
#
# Shipped SET for the reason the problem limits are: an enforcement mechanism
# that defaults to off does not answer the finding it exists for. Ninety, not
# thirty: an expectation is another team's backlog, and a budget teams cannot
# meet teaches them not to record expectations. The values are policy; one
# line changes either; every scoped run prints them, set or not.
expectation_age_days: 90
expectation_open_max: 10

# Multi-unit keys, meaningful only when .guardrails/units.yaml exists —
# see templates/units.yaml. Both are LIST keys.
# depends_on:
#   - platform/hal
# segregated_from:
#   - platform/hal (RC-k3n8p2)
```

`templates/units.yaml` — new file, in the config template's voice:

```yaml
# guardrails unit manifest — .guardrails/units.yaml at the repository root.
# Its PRESENCE switches the repository to multi-unit mode; delete it and
# every script behaves exactly as a single-unit repository. Written by
# /ratchet; validated before any gate runs (same flat grammar as
# config.yaml: `key:` at column one, two-space `- item` lists, LF/CRLF, no
# BOM, every key set once).
#
# Exactly two keys, both lists:
#
#   * `units:` (required, at least one entry) — each entry a repository-
#     relative directory holding its own valid .guardrails/config.yaml. A
#     unit is one IEC 62304 software system: its own class, ledgers, tests.
#   * `not_a_unit:` (optional) — directories deliberately OUTSIDE compliance.
#     This list is what distinguishes "not yet ratcheted" (loud:
#     UNCLAIMED-PATH) from "deliberately outside" (recorded here, reviewable).
#     Draft tokens and DRAFT-named files under these paths still convict
#     (DISCLAIMED-DRAFT): parked work is not disclaimed work.
#
# Entry rules, each refused at exit 2: literal directory paths only (no
# globs, no trailing slash, never `.` or anything leaving the repository, no
# whitespace); no path listed twice; no entry nested inside another — one
# file, one scope. Matching is by whole path components: `docs` claims
# docs/adr/x.md and never docs-site/. Files directly at the repository root,
# and this directory itself, are implicitly outside every unit.
#
# With a manifest present there is NO root .guardrails/config.yaml — two
# authorities over one tree is refused. Each unit's own config carries its
# class, its documents (all inside the unit's subtree), its depends_on: and
# — where a lower-class provider is argued safe — its segregated_from:.
#
# units:
#   - platform/hal
#   - packages/pump
# not_a_unit:
#   - docs
#   - tools
#   - packages/legacy-ui   # migrating, 2026-Q4
```

### 10.3 Commands

```sh
sh tests/.bats-core/bin/bats tests/lib.bats && sh tests/run-tests.sh
git add -A && git -c commit.gpgsign=false commit -m "feat: units manifest template; expectation limits ship set"
```

### T10 — DONE (dispatch report, landed)

```
red -> green: both tests watched fail for the right reason (limits only as
  T1's commented stub / units.yaml template absent) before implementation
result: 516 passed, 1 failed — the failure is the pre-existing lib.sh census
  pin (GR_ID_BODY 2->3 from T3's gr_req_scan), independently found and
  reported; T5 had already fixed those pins on the change branch, so the
  merge resolves it. Independent confirmation of T5's finding.
```

---

## T11 — the composed chains, end to end

**Files touched:** `tests/units-chain.bats` (new)
**Parallel:** no (serial, last of the code tasks — it exercises T4, T6, T7
and T8 together)
**Trace:** the D8 composed-chain obligations, tested *through `--impact`*, end
to end, never link by link (risk file assessment 2): **export-removal-convicts**,
**export-removal-reopens-expectation**, **item-deletion-degrades-to-dangling**,
**transitive-dependent-unaffected**, **exports-mode-matches-resolution**.

These are pure test deliverables — every mechanism exists by now. A test that
needs new implementation code here means an earlier task under-delivered; fix
it THERE and rerun that task's cycle.

### 11.1 Tests (`tests/units-chain.bats`, new file, complete)

```bash
load helpers

# Every chain starts from the same wire: pump's SAD references hal's exported
# REQ-h4m2p9 (make_units_fixture strings it).

@test "chain: export-removal-convicts — provider unexports, impact set names the consumer, consumer's run blocks" {
    make_units_fixture
    sed -i.bak '/^exported: yes$/d' platform/hal/docs/requirements/0001-01-01-base.md
    rm -f platform/hal/docs/requirements/0001-01-01-base.md.bak
    commit_all unexport
    # link 1: the change maps to hal, and pump rides the reverse depends_on
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [ "$status" -eq 0 ]
    [[ "$output" == *"platform/hal	touched"* ]]
    [[ "$output" == *"apps/pump	dependent"* ]]
    # link 2: the dependent's own run convicts — so the provider's merge,
    # which runs the impact set, blocks
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 1 ]
    [[ "$output" == *"NON-EXPORTED-REF REQ-h4m2p9"* ]]
}

@test "chain: export-removal-reopens-expectation — a met expectation recomputes to unmet, nothing stored goes stale" {
    make_units_fixture
    cat >> apps/pump/docs/requirements/0001-01-01-base.md <<EOF

**REQ-e7x2m4**: The software shall rely on platform/hal to bound slew rate.
expects: platform/hal
opened: $(days_ago 3)
EOF
    cat >> platform/hal/docs/requirements/0001-01-01-base.md <<'EOF'

**REQ-h8s3t2**: The software shall bound actuator slew rate. satisfies: REQ-e7x2m4
exported: yes
EOF
    printf '# verifies: REQ-h8s3t2\ntrue\n' > platform/hal/tests/test_b.sh
    printf '# verifies: REQ-e7x2m4\ntrue\n' > apps/pump/tests/test_e.sh
    commit_all met
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 0 ]
    [[ "$output" != *"UNMET-EXPECTATION"* ]]
    # the provider withdraws the export that carried the satisfies: — delete
    # the LAST exported: line (REQ-h8s3t2's; REQ-h4m2p9's is the first). awk,
    # not sed: the GNU and BSD spellings of a block-relative address disagree.
    awk 'NR==FNR { if ($0=="exported: yes") last=FNR; next }
         FNR!=last { print }' \
        platform/hal/docs/requirements/0001-01-01-base.md \
        platform/hal/docs/requirements/0001-01-01-base.md > h.tmp
    mv h.tmp platform/hal/docs/requirements/0001-01-01-base.md
    commit_all unexport
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [[ "$output" == *"apps/pump	dependent"* ]]
    unit_run check-trace.sh apps/pump
    [[ "$output" == *"UNMET-EXPECTATION platform/hal: REQ-e7x2m4"* ]]
}

@test "chain: item-deletion-degrades-to-dangling" {
    make_units_fixture
    # delete the exported item outright (both its lines)
    grep -v -e 'REQ-h4m2p9' -e '^exported: yes$' \
        platform/hal/docs/requirements/0001-01-01-base.md > h.tmp
    mv h.tmp platform/hal/docs/requirements/0001-01-01-base.md
    printf '\n**REQ-h7v3w2**: The software shall limit the dose. (implements: RC-h3d8f4)\n' \
        >> platform/hal/docs/requirements/0001-01-01-base.md
    sed -i.bak 's/verifies: LLR-h6k9m3/verifies: LLR-h6k9m3 REQ-h7v3w2/' platform/hal/tests/test_a.sh
    sed -i.bak 's/satisfies: REQ-h4m2p9/satisfies: REQ-h7v3w2/; s/traces: REQ-h4m2p9/traces: REQ-h7v3w2/' \
        platform/hal/docs/architecture/0001-01-01-base.md
    rm -f platform/hal/tests/test_a.sh.bak platform/hal/docs/architecture/0001-01-01-base.md.bak
    commit_all delete-item
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [[ "$output" == *"apps/pump	dependent"* ]]
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-h4m2p9 (referenced but never defined)"* ]]
}

@test "chain: transitive-dependent-unaffected — in the set, green when it never referenced the item" {
    make_units_fixture
    make_unit apps/monitor apps/pump
    write_unit_items apps/monitor REQ-m2n6p3 HAZ-m3q8r2 RC-m4s7t3 SDD-m5u2v8 LLR-m6w3x9
    cat > .guardrails/units.yaml <<'EOF'
units:
  - platform/hal
  - apps/pump
  - apps/monitor
not_a_unit:
  - legacy
  - docs
EOF
    commit_all monitor
    sed -i.bak '/^exported: yes$/d' platform/hal/docs/requirements/0001-01-01-base.md
    rm -f platform/hal/docs/requirements/0001-01-01-base.md.bak
    commit_all unexport
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [[ "$output" == *"apps/monitor	dependent"* ]]      # it RUNS (D12: binaries)
    unit_run check-trace.sh apps/monitor
    [ "$status" -eq 0 ]                                  # and passes: no reference
    # one that references the provider directly was never quiet about it:
    printf '\nSee REQ-h4m2p9.\n' >> apps/monitor/docs/architecture/0001-01-01-base.md
    commit_all direct-ref
    unit_run check-trace.sh apps/monitor
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNDECLARED-DEPENDENCY REQ-h4m2p9"* ]]
}

@test "chain: exports-mode-matches-resolution — the listing and the verdicts are one computation" {
    make_units_fixture
    run sh .guardrails/scripts/check-units.sh --exports platform/hal
    listed="$output"
    # every listed ID resolves from the consumer (the fixture references
    # REQ-h4m2p9 already, and the run is green)
    [[ "$listed" == *"REQ-h4m2p9"* ]]
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 0 ]
    # an ID the mode omits convicts when referenced
    [[ "$listed" != *"LLR-h6k9m3"* ]]
    printf '\nSee LLR-h6k9m3.\n' >> apps/pump/docs/architecture/0001-01-01-base.md
    commit_all internal-ref
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 1 ]
    [[ "$output" == *"NON-EXPORTED-REF LLR-h6k9m3"* ]]
}
```

(The `export-removal-reopens-expectation` sed has a GNU/BSD fork; if it proves
brittle in the red run, replace both branches with the awk form
unconditionally — the awk branch is portable on its own.)

### 11.2 Commands

```sh
sh tests/.bats-core/bin/bats tests/units-chain.bats && sh tests/run-tests.sh
git add -A && git -c commit.gpgsign=false commit -m "test: the export-removal chain holds end to end, through --impact"
```

### T11 — DONE (dispatch report, landed)

```
All five chains green on arrival (the inverted discipline for composed
tests over delivered mechanisms), each validated by sabotage — the named
mechanism broken, the test watched red at exactly its guarded assertion,
restore watched green:
  export-removal-convicts — dropped gr_exported_reqs' EXP/yes filter
  export-removal-reopens-expectation — dropped the `in expd` half of met
  item-deletion-degrades-to-dangling — classify_unresolved -> continue
  transitive-dependent-unaffected — impact closure scoped to one hop
  exports-mode-matches-resolution — emptied the NON-EXPORTED-REF branch
result: 577/577 full suite (chain file 5/5)
note for future editors: the expectation-met awk condition appears TWICE in
check-trace.sh (met check and provider-side advisory) — a sabotage probe
matched both; edits to one must reach the other.
```

---

## T12 — README and the obligation audit

**Files touched:** `README.md`
**Parallel:** no (serial, after T11 — it documents what exists)

1. Add one row to the script table:

   | `check-units.sh [--impact RANGE \| --exports UNIT \| --list]` | the multi-unit repository's entry point: validates `.guardrails/units.yaml` and every unit config; `UNCLAIMED-PATH`, `MISCLASSED-DEPENDENCY`/`INCOMPLETE-SEGREGATION` (the IEC 62304 5.3.5 class floor and its recorded escape), `DISCLAIMED-DRAFT`; without a manifest it proves the single-unit reading (two unit-shaped configs, or a near-missed manifest name in `.guardrails/`, are exit 2). `--impact` computes the units a change must run (touched + transitive dependents); `--exports` prints a unit's export surface from the same computation the consumer's verdicts resolve against; `--list` enumerates units |

2. A short section "Monorepos" after the script table: the manifest is
   opt-in; no manifest, nothing changes; a unit's run is scoped
   (`GR_CONFIG=<unit>/.guardrails/config.yaml`), sees its dependencies'
   exported REQs as foreign definitions, and convicts
   `NON-EXPORTED-REF`/`UNDECLARED-DEPENDENCY`/`UNMET-EXPECTATION` in its own
   standalone run. Point at `docs/plans/2026-09-03-units-architecture.md`.

3. Run the **obligation audit** from the top of this plan; it must print
   nothing.

```sh
sh tests/run-tests.sh
git add -A && git -c commit.gpgsign=false commit -m "docs: README covers check-units and the monorepo mode"
```

### T12 — DONE (dispatch report, landed)

```
audit outcome: EMPTY — the 41-name obligation loop printed nothing (exit 0);
  every named obligation appears verbatim in a bats test title.
result: 577/577 full suite; skills.bats 26/26 against the edited README.
placement note: the Monorepos section landed as `### Monorepos` inside
  "## Check scripts" (after the table's trailing prose, before "### The
  review artefact") — a heading directly after the table would have
  swallowed the annotation-rule prose that belongs to it.
```

**All twelve tasks are DONE and merged. 577 tests, 0 failures; the
obligation audit prints nothing.**

### Independent review (merge-change 6a) and the fix round

The gate ran green (577/577, log in the session scratchpad), the independent
review returned **approve-with-findings** — 3 IMPORTANT, 3 MINOR — and one
fix dispatch (branch units-implementation-fix1, six commits, merged) closed
all six. Dispositions live in the verification record. Fix-round evidence:

```
finding-1 root/.guardrails DISCLAIMED-DRAFT gap — 3 tests watched red
  (exit 0 today) before the scan grew the implicitly-disclaimed surface
finding-2 32 inert mid-test [[ ]] armed with || false — swallow proven by
  inversion before arming on 3 named assertions, all fail armed
finding-3 byte-exact manifest presence moved into gr_units_present — the
  UNITS.YAML probe and the scoped-run-stays-single-unit test both red first
finding-4 GR_DRAFT_TOKEN_RE/GR_DRAFT_FILE_RE single definition — refactor
  under green, 71/71 draft-owning tests unchanged
finding-5 disclaimed-only RC citation → INCOMPLETE-SEGREGATION, red first;
  unit-RMF twin green
finding-6 four green-on-arrival abnormal tests, each sabotage-validated
result: 588 passed, 0 failed
```

---

## Task graph

```
T1 ── T2 ── T3 ──┬─ T4 (check-trace) ──────┐
                 ├─ T5 (check-ids)          │
                 ├─ T6 ── T7 (check-units)  ├── T11 (chains) ── T12 (README)
                 ├─ T8 (new-id)             │
                 └─ T9 (review/finalize) ───┘
T1 ─────────────── T10 (templates)          (T10 joins before T12)
```

T4, T5, T6+T7, T8, T9, T10 have pairwise-disjoint file sets and may run as
parallel worktree-internal strands; `tests/helpers.bash` is written by T3
alone, before the fan-out.

## Self-review (performed before handing off)

1. Every obligation in the registry table has a task, and every task's tests
   carry the obligation names verbatim — the audit loop at the top checks it
   mechanically.
2. Names used across tasks are consistent: `GR_UNITS`, `GR_UNIT`,
   `gr_units_present`, `gr_check_units`, `gr_unit_engage`, `gr_unit_list`,
   `gr_disclaimed_list`, `gr_req_scan`, `gr_unit_req_scan`, `gr_unit_srs`,
   `gr_exported_reqs`, `gr_consumers_of`, `gr_unit_of_path`,
   `gr_check_flat`, `gr_check_forms`; fixture helpers `make_units_fixture`,
   `make_unit`, `write_unit_config`, `write_unit_items`, `unit_run`,
   `add_expectation`, `satisfy_expectation`, `add_third_tier`.
3. No two tasks marked parallel touch the same file (T6/T7 share files and
   are serial; T11/T12 serial).
4. Every new conviction token in the architecture's vocabulary table has an
   implementing task: UNCLAIMED-PATH, MISCLASSED-DEPENDENCY,
   INCOMPLETE-SEGREGATION (T6); NON-EXPORTED-REF, UNDECLARED-DEPENDENCY,
   UNMET-EXPECTATION, INCOMPLETE-EXPECTATION, MISEXPORTED-ITEM (T4);
   DISCLAIMED-DRAFT, near-miss exit 2 (T6); manifest/config shape errors
   (T2). Plus EXPECTATION-BACKLOG (implementation decision 7).
5. The engagement rule is asserted red-green in every scoped script's task
   (T4, T5, T8, T9) and the unscoped path is pinned by
   no-manifest-changes-nothing (T6) plus the whole pre-existing suite.

## Execution

`develop-change` task by task in THIS worktree (`units-implementation`),
strictly red before green within each task; then `check-traceability`,
`verify-before-merge`, `merge-change`. The verification record must name:
implementation decisions 1–10 above (especially 7, the EXPECTATION-BACKLOG
token) for the reviewer's judgment, and the obligation audit output.
