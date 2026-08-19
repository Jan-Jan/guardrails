# Config Schema Validation Implementation Plan

**Goal:** A config key that is missing, misspelled, or written in a shape the
config reader cannot see must be an error, not silently "this project does not
use that document".

**Implements:** no REQ/RC/SDD IDs — this repository has no `.guardrails/`
config and therefore no SRS of its own to trace to. That is a real
self-conformance gap, recorded at the end of this plan, not something this
change fixes.

**Safety class:** n/a for the same reason. The projects this toolkit gates are
class A–C; guardrails itself is a development tool.

**Verification:** `tests/run-tests.sh` (112 tests green at `fc80d68`, the
baseline for this change), plus a read-only corpus regression against a clean
clone of `sightings-app`.

---

## Why this is its own change

Change A (`fc80d68`) fixed four false-green defects and shipped with two known
gaps stated openly in `README.md`, `skills/check-traceability/SKILL.md` and
`scripts/check-trace.sh`'s header. **This change closes the first of them.**

The gap, reproduced on change A's own scripts:

```
# doc_rmf: mistyped as doc_rmff:, with an unmitigated HAZ-002 in the tree
checked: REQ 1, HAZ 2, RC 1, SDD 1, LLR 1, PR 0
sources: srs 2, rmf 0, sad 3, soup 1, problems 1; strict 1, tests 1
exit=0
```

It is not only about documents. `test_path:` for `test_paths:` disables
`MISSING-TEST` entirely; `strict_path:` drops half of `DANGLING-REF`; a config
carrying none of these keys runs every gate off and still exits 0.

This is a **migration event**: every existing guardrails project's config is
now validated, and several shapes the old scripts accepted in silence become
exit 2. That is why it is not bundled with a bugfix — it needs its own upgrade
path, and an operator must be able to read what changed for them in one place.

## What is deliberately NOT in this change

`MISPLACED-ITEM` — the rule that an item must be defined in the document
configured for its prefix. That is change C, it is a new traceability rule
rather than a config defect, and it needs a requirement written for it first.
Change A's second known gap stays open until then, and this change must **not**
quietly narrow the wording that records it.

---

## Task 1 — value lexing: CRLF and inline comments

**Trace IDs:** none (see header).

A config saved with CRLF endings puts an invisible `\r` inside every value, so
`doc_rmf: docs/risk` resolves to `docs/risk\r` and dies naming a path that
looks perfectly valid. `templates/config.yaml` tells operators to comment keys
out, which invites `doc_rmf: docs/risk  # the RMF`.

### 1.1 Failing tests

Append to `tests/check-trace.bats`:

```bash
@test "check-trace: a trailing comment on a scalar value is not part of the value" {
    sed -i.bak 's|^doc_rmf: docs/risk$|doc_rmf: docs/risk  # the RMF|' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"rmf 2"* ]]
}

@test "check-trace: a config with CRLF line endings still parses" {
    sed -i.bak 's/$/\r/' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]
}
```

Expected before implementation: both fail — the first with exit 2
(`'docs/risk  # the RMF', which does not exist`), the second with exit 2
(`id_prefixes entry is not a bare identifier: PR`, the `\r` invisible).

### 1.2 Implementation

In `scripts/lib.sh`, above `cfg_get`:

```sh
# Value cleanup shared by cfg_get and cfg_list: drop a trailing CR (a config
# saved with CRLF endings otherwise puts an invisible \r inside every value,
# and the resulting error message accuses a path or prefix that looks perfectly
# valid), drop a trailing ` # comment`, then drop trailing blanks.
#
# The ` # comment` strip requires whitespace before the `#`, so `path#anchor`
# and `sh -c 'echo "#done"'` survive. It cannot be escaped: a value whose own
# whitespace-delimited token starts with `#` is truncated silently. That is
# recorded in templates/config.yaml rather than worked around.
GR_AWK_CLEAN_VALUE='
function gr_clean(v) {
    sub(/\r$/, "", v)
    sub(/[ \t]+#.*$/, "", v)
    sub(/[ \t]+$/, "", v)
    return v
}
'
```

Then thread it through both readers — `cfg_get` gains
`awk -v k="$1" "$GR_AWK_CLEAN_VALUE"'...'` and prints `gr_clean($0)`; `cfg_list`
the same for its `- item` branch. Full bodies:

```sh
cfg_get() {
    [ -f "$GR_CONFIG" ] || gr_die "config not found: $GR_CONFIG"
    awk -v k="$1" "$GR_AWK_CLEAN_VALUE"'
        index($0, k ":") == 1 { sub(/^[^:]*:[ \t]*/, ""); print gr_clean($0); exit }
    ' "$GR_CONFIG"
}

cfg_list() {
    [ -f "$GR_CONFIG" ] || gr_die "config not found: $GR_CONFIG"
    awk -v k="$1" "$GR_AWK_CLEAN_VALUE"'
        !inlist && index($0, k ":") == 1 { inlist = 1; next }
        inlist && /^[^ \t]/ { exit }
        inlist && /^[ \t]*-[ \t]/ { sub(/^[ \t]*-[ \t]*/, ""); print gr_clean($0) }
    ' "$GR_CONFIG"
}
```

### 1.3 Verify

`sh tests/run-tests.sh` → 114 ok. Mutation: replace `gr_clean`'s body with
`return v` → the two new tests go red, nothing else moves.

---

## Task 2 — reject a config the reader cannot see

**Trace IDs:** none.

`cfg_get`/`cfg_list` match `identifier:` at column one. Any other shape —
`strict-paths:`, ` strict_paths:`, `strict_paths :`, a column-0 `- item`, a
UTF-8 BOM before the first key — is invisible to them, so the list reads empty
and its gate quietly does nothing.

### 2.1 Failing tests

Append to `tests/check-trace.bats`:

```bash
@test "check-trace: a key with a hyphen instead of an underscore is an error" {
    sed -i.bak 's/^strict_paths:/strict-paths:/' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"strict-paths"* ]]
}

@test "check-trace: an indented top-level key is an error" {
    sed -i.bak 's/^strict_paths:/ strict_paths:/' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"strict_paths"* ]]
}

@test "check-trace: a space before the colon is an error" {
    sed -i.bak 's/^strict_paths:/strict_paths :/' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"strict_paths"* ]]
}

@test "check-trace: a config saved with a UTF-8 BOM is rejected, not half-read" {
    printf '\xef\xbb\xbf' > .guardrails/config.new
    cat .guardrails/config.yaml >> .guardrails/config.new
    mv .guardrails/config.new .guardrails/config.yaml
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"BOM"* ]]
}

@test "check-trace: a config with a YAML document separator still parses" {
    printf -- '---\n' > .guardrails/config.new
    cat .guardrails/config.yaml >> .guardrails/config.new
    mv .guardrails/config.new .guardrails/config.yaml
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
}
```

Expected before implementation: the first four pass with **exit 0** (the
defect); the fifth passes already and is a guard against over-rejecting.

### 2.2 Implementation

In `scripts/lib.sh`, a new `gr_check_config` containing, in order: the BOM
rejection, then the line-shape scan. Exact code:

```sh
gr_check_config() {
    [ -f "$GR_CONFIG" ] || gr_die "config not found: $GR_CONFIG"

    # A UTF-8 BOM makes the first key unreadable by every awk matcher here, so
    # it must be rejected explicitly — the alternative is a first key that
    # silently reads as absent. Detected in awk (octal escapes are POSIX)
    # rather than with `head -c`, which is not in POSIX head. LC_ALL=C so
    # substr counts bytes: in a UTF-8 locale awk counts characters and the
    # three BOM bytes are one of them.
    if [ -n "$(LC_ALL=C awk 'NR == 1 { if (substr($0, 1, 3) == "\357\273\277") print "bom"; exit }' "$GR_CONFIG" 2>/dev/null)" ]; then
        gr_die "config begins with a UTF-8 BOM: $GR_CONFIG — save it as plain UTF-8"
    fi

    # Every line must be blank, a comment, a `  - item` list entry, a `---`
    # document separator, or exactly `<key>:` at column one. Matching only
    # /^[A-Za-z_]+:/ is not enough: that is the same shape cfg_get matches, so
    # a key invisible to the reader is equally invisible to the check.
    _malformed=$(awk '
        { line = $0; sub(/\r$/, "", line) }
        line ~ /^---[ \t]*$/ { next }
        line ~ /^[ \t]*$/ { next }
        line ~ /^[ \t]*#/ { next }
        line ~ /^[ \t]+-[ \t]/ { next }
        line !~ /^[A-Za-z_][A-Za-z0-9_]*:/ { print NR }
    ' "$GR_CONFIG")
    if [ -n "$_malformed" ]; then
        _msg=""
        for _n in $_malformed; do
            _msg="${_msg}
  line ${_n}: $(sed -n "${_n}p" "$GR_CONFIG")"
        done
        gr_die "config line(s) that are neither a comment, a '  - item' list entry, nor a top-level key:${_msg}"
    fi
}
```

Call it from `scripts/check-trace.sh` immediately after `cd "$(gr_root)"`, and
from `scripts/finalize-ids.sh` at the same point (see Task 5).

### 2.3 Verify

Mutation: delete the `_malformed` block → tests 1–3 red. Delete the BOM block →
test 4 red (it falls through to the malformed-line error, whose text lacks
"BOM"). Delete the `---` exemption → test 5 red.

---

## Task 3 — closed key set

**Trace IDs:** none.

### 3.1 Failing test

Append to `tests/check-trace.bats`:

```bash
@test "check-trace: a typo'd doc key is an error, not a project without that document" {
    cat >> docs/risk/0001-01-01-base.md <<'EOF'

**HAZ-002**: Underdose delivered to patient.
EOF
    commit_all unmitigated
    # sanity: with the key spelled correctly this run fails on HAZ-002
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNMITIGATED-HAZARD HAZ-002"* ]]

    sed -i.bak 's/^doc_rmf:/doc_rmff:/' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_rmff"* ]]
}
```

The two-phase shape is deliberate: it proves the gate *does* fire on the same
tree with the key spelled correctly, so the exit 2 is closing a real hole
rather than a hypothetical one.

### 3.2 Implementation

Add to `scripts/lib.sh` beside the other constants:

```sh
# Every top-level key guardrails understands. A key outside this set is a typo,
# and a typo'd key is invisible: cfg_get returns nothing, the gate that reads it
# is skipped, and the run exits 0 having proved nothing.
GR_KNOWN_KEYS='guardrails_version
safety_class
id_prefixes
doc_srs
doc_rmf
doc_sad
doc_soup
doc_problems
strict_paths
test_paths
verify_commands
coverage_command'
```

and, at the end of `gr_check_config`:

```sh
    _unknown=""
    for _k in $(awk '/^[A-Za-z_][A-Za-z0-9_]*:/ { sub(/:.*/, ""); print }' "$GR_CONFIG"); do
        gr_contains "$GR_KNOWN_KEYS" "$_k" || _unknown="${_unknown} $_k"
    done
    [ -z "$_unknown" ] || gr_die "unknown config key(s):${_unknown}"
```

### 3.3 Verify

Mutation: delete the `_unknown` block → the new test goes red at its second
phase.

---

## Task 4 — closed prefix set and the per-prefix document map

**Trace IDs:** none.

Two holes of the same family. A config naming no prefix that has a
traceability gate leaves every such gate off. A prefix whose *gate inputs* are
unconfigured leaves that gate skipped — and the document a gate reads is not
always the one the prefix is defined in: `UNIMPLEMENTED-CONTROL` looks for a
REQ that implements each RC, so it reads `doc_srs`.

### 4.1 Failing tests

Append to `tests/check-trace.bats`:

```bash
@test "check-trace: a config with no gated prefix at all is an error" {
    sed -i.bak 's/^id_prefixes:.*/id_prefixes: REQ HAZ RC SDD LLR PR TC/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf '**TC-001**: Nonsense item nothing ever checks.\n' > docs/scratch.md
    commit_all unmanaged-prefix
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"TC"* ]]
    [[ "$output" == *"no prefix with a traceability gate"* ]]
}

@test "check-trace: RC declared without doc_srs is an error, not a skipped gate" {
    cat > .guardrails/config.yaml <<'EOF'
guardrails_version: 0.1.0
safety_class: B
id_prefixes: HAZ RC
doc_rmf: docs/risk
EOF
    commit_all haz-rc-only
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_srs"* ]]
    [[ "$output" == *"RC"* ]]
}

@test "check-trace: REQ declared with no test_paths is an error, not zero tests to search" {
    # a present-but-EMPTY list: `test_path:` is caught as an unknown key and
    # would not exercise this rule at all
    sed -i.bak 's|^  - tests$||' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"test_paths"* ]]
}
```

Append to `tests/lib.bats`:

```bash
@test "gr_check_config accepts the shipped config shape" {
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "gr_check_config rejects a declared prefix whose document is unconfigured" {
    sed -i.bak '/^doc_sad:/d' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_sad"* ]]
}
```

### 4.2 Implementation

Constant, beside `GR_KNOWN_KEYS`:

```sh
# The ID prefixes with a traceability gate of their own. Others are allowed:
# DANGLING-REF, DUPLICATE-ID and draft finalization are keyed on the whole
# configured prefix list, so an extra prefix is genuinely checked. What is
# rejected is a list naming NONE of these.
GR_GATED_PREFIXES='REQ
HAZ
RC
SDD
LLR
PR'
```

Appended to `gr_check_config`:

```sh
    _pfx=$(gr_prefixes) || exit 2

    for _p in $_pfx; do
        gr_contains "$GR_GATED_PREFIXES" "$_p" || gr_die \
"id_prefixes names no prefix with a traceability gate: $_pfx
  At least one of REQ HAZ RC SDD LLR PR must appear. Others may be declared
  alongside them — they are covered by DANGLING-REF and DUPLICATE-ID."
    done

    # Each prefix needs the documents whose absence would SILENTLY SKIP one of
    # its gates — not always the document it is defined in.
    #
    # This is deliberately NOT the full set of documents every gate reads.
    # UNANALYZED-DERIVED also reads doc_rmf and the transitive half of
    # MISSING-TEST also reads doc_sad, but both FAIL RED without their input
    # rather than passing vacuously, so requiring those keys would forbid
    # legitimate shapes — a class A project with no architecture document, say.
    # The rule is "no gate is ever silently skipped", not "every gate has every
    # input", and the comment must keep saying so: an earlier draft claimed the
    # map was complete and a reviewer proved it was not.
    for _p in $_pfx; do
        case "$_p" in
            REQ) _need="doc_srs" ;;
            HAZ) _need="doc_rmf" ;;
            RC)  _need="doc_srs" ;;
            SDD) _need="doc_sad" ;;
            LLR) _need="doc_sad" ;;
            PR)  _need="doc_problems" ;;
            *)   continue ;;
        esac
        for _k in $_need; do
            [ -n "$(cfg_get "$_k")" ] || \
                gr_die "id_prefixes declares $_p but $_k is not configured — a gate for $_p reads it, so that gate could never run"
        done
    done

    if gr_contains "$_pfx" REQ || gr_contains "$_pfx" LLR; then
        [ -n "$(cfg_list test_paths)" ] || \
            gr_die "id_prefixes declares REQ/LLR but test_paths is empty — nothing would be searched for 'verifies:'"
    fi
```

Note `_pfx=$(gr_prefixes) || exit 2`: `gr_prefixes` dies in a subshell here, so
the status must be propagated or the loop iterates over nothing.

### 4.3 Verify

Mutations: delete the managed-prefix loop → the TC test red. Change
`RC) _need="doc_srs"` to `"doc_rmf"` → the RC test red; to
`"doc_rmf doc_srs"` → the over-rejection guard red. Delete the
`test_paths` check → the `test_path:` test red.

---

## Task 5 — finalize-ids validates the config too

**Trace IDs:** none.

Change A's record, gap 1, states that `finalize-ids.sh` shares the blind spot:
a misspelled `doc_*` key makes it skip that ledger's rename while minting and
rewriting the IDs, and exit 0 over a half-finalized tree. `check-ids.sh`
catches it one step later, so the sequence holds — but the script reports
success over the state its own Task 1 rationale says must never exist.

### 5.1 Failing test

Append to `tests/finalize-ids.bats`:

```bash
@test "finalize: a typo'd doc key is an error, not a ledger it quietly skips" {
    sed -i.bak 's/^doc_problems:/doc_problemss:/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf '**PR-DRAFT-b-1**: a problem. status: open\n' > docs/problems/DRAFT-feature-notes.md
    commit_all typo-key
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_problemss"* ]]
    [ -f docs/problems/DRAFT-feature-notes.md ]
}
```

### 5.2 Implementation

In `scripts/finalize-ids.sh`, immediately above the existing `gr_doc_files`
validation loop, add `gr_check_config`. The two are complementary and the
comment must say which does what: `gr_check_config` validates a key's
**spelling**, `gr_doc_files` validates its **value**.

### 5.3 Verify

Mutation: delete the `gr_check_config` call → the new test goes red.

---

## Task 6 — close the gap statements change A opened

**Trace IDs:** none.

Change A states this gap in four places. Each must now be updated — and the
*second* gap (`checked:` counts items found, not items examined) must survive
intact, because change C has not landed.

| File | Change |
|---|---|
| `scripts/check-trace.sh` | Delete the `KNOWN GAP` block at lines 32–40; add the new exit-2 causes to the header list above it |
| `README.md` | "What this does not yet cover" drops item 1, keeps item 2; the exit-2 paragraph gains the config-shape causes |
| `skills/check-traceability/SKILL.md` | "Two known gaps" becomes one; the exit-2 table gains six rows |
| `docs/verification/2026-08-18-false-green-a.md` | **Not edited.** It is the signed record of a merged change and states what was true then. |

New rows for the skill's exit-2 table:

```markdown
| `unknown config key(s): doc_rmff` | A typo'd key. Nothing reads it, so the gate it was meant to configure silently never runs. |
| `config line(s) that are neither a comment, a '  - item' list entry, nor a top-level key` | A key that is not `identifier:` at column one — `strict-paths:`, ` strict_paths:`, `strict_paths :`. Each is invisible to the config reader. |
| `config begins with a UTF-8 BOM` | The BOM makes the first key unreadable, i.e. silently absent. |
| `id_prefixes names no prefix with a traceability gate` | At least one of REQ, HAZ, RC, SDD, LLR, PR must appear. Extra prefixes alongside them are checked by DANGLING-REF and DUPLICATE-ID. |
| `id_prefixes declares RC but doc_srs is not configured` | A gate reads a document the prefix is not defined in. |
| `id_prefixes declares REQ/LLR but test_paths is empty` | Nothing would be searched for `verifies:`. |
```

---

## Task 7 — the migration path

**Trace IDs:** none.

This is the part that makes it a separate change. `skills/ratchet/SKILL.md`
already carries an upgrade table from change A; this change adds every new
exit-2 cause to it, each with *why it was never safe*:

```markdown
> | A key that is not `identifier:` at column one (`strict-paths:`, ` strict_paths:`) | The config reader never saw it, so its list read as empty |
> | A list item at column 0 (`- src` unindented) | `cfg_list` never read those entries either |
> | An unrecognised key (`doc_rmff:`) | Nothing read it, so the gate it configured never ran |
> | An `id_prefixes` entry outside REQ/HAZ/RC/SDD/LLR/PR | No gate exists for it, so its items were counted and checked by nothing |
> | `RC` declared without `doc_srs` | `UNIMPLEMENTED-CONTROL` reads the SRS; without it the gate was skipped |
> | A config saved with a UTF-8 BOM | The BOM made the first key unreadable, i.e. silently absent |
```

`templates/config.yaml` gains a header stating the key set is closed, that a
key must be `identifier:` at column one, that a trailing ` # comment` is
stripped and cannot be escaped, that the file must be plain UTF-8, and which
prefixes `id_prefixes` may name.

**There is deliberately no compatibility flag.** Every shape this rejects was
a gate that did not run; an opt-out would be a supported way to keep a false
green.

---

## Task 8 — corpus regression

**Trace IDs:** none.

Run `scripts/check-trace.sh` and `scripts/check-ids.sh` from this branch
against a **clean clone** of `sightings-app` at its current HEAD, and the
project's own installed scripts against the same clone, and diff. That project
is under active development in another session — clone, never touch its tree.

Expected: identical verdicts. Its config uses eleven known keys, all
`identifier:` at column one, no BOM, and `id_prefixes: REQ HAZ RC SDD LLR PR`,
so this change must accept it unchanged. **If it does not, that is a finding
about this change, not about that project.**

---

## Corrections made during execution

Recorded here because a plan that still prescribes a defect is a trap for
whoever executes it next. Two review rounds changed what this plan specifies:

- **`id_prefixes` must name at least one *gated* prefix — not every prefix must
  be gated.** The first draft above rejected any prefix outside the six. But
  `DANGLING-REF`, `DUPLICATE-ID` and ID finalization are keyed on the whole
  prefix list, so an extra prefix such as `ADR` is genuinely checked; rejecting
  it told operators to remove it, which removed that coverage and turned a
  reported `DANGLING-REF` into exit 0. Wherever this plan still shows the
  every-prefix form, the shipped rule is the at-least-one form.
- **`RC` requires `doc_srs` only, not `doc_rmf`.** The first draft above
  required both; no RC gate reads `doc_rmf`, so that rejected a retrofit with
  controls but no risk management file, telling it a gate could never run that
  demonstrably does.
- **A comment does not make a list item safe to reinterpret.** An intermediate
  fix made `cfg_list` skip comments so a `# …` line would not truncate a list;
  that silently ADOPTED any items below into the block above, so `- src` under
  a commented-out `strict_paths:` became a test path and a `verifies:`
  annotation in production source counted as a test. The shipped behaviour
  rejects the orphan instead of guessing.
- The empty-`test_paths` test uses a present-but-empty list; the `test_path:`
  form it originally specified is caught by the closed key set and exercises
  nothing.

## Self-review

1. Every task has a failing test written before its implementation, with the
   exact assertion text, and a named mutation that reddens it.
2. No task depends on a name another task has not yet introduced:
   `gr_check_config` is created in Task 2 and appended to in Tasks 3 and 4;
   `GR_AWK_CLEAN_VALUE` in Task 1 precedes its use in `cfg_get`.
3. `Implements:` is empty and says why, rather than inventing IDs.
4. Task 6 explicitly protects change C's gap statement from being narrowed.
5. The evidence figures are **not** written into this plan — `tests/evidence.sh`
   derives them and the verification record carries them, exactly once. Change
   A's plan carried a second copy and it went stale within one round.

## Known gaps this change will ship with

Recorded now so the verification record does not have to discover them:

1. `gr_clean` strips a trailing ` # comment` silently and quoting is not
   honoured, so a `verify_commands` entry whose own token starts with `#` is
   truncated without a diagnostic.
2. `check-ids.sh` and `check-signing.sh` do not call `gr_check_config`, so a
   malformed config is caught at the traceability and finalize gates only.
3. `checked:` still counts items found rather than items examined — change C.
4. This repository still has no `.guardrails/config.yaml` of its own, so
   guardrails cannot be run against guardrails. `AGENTS.md` claims it is
   "developed under its own rules"; that claim is currently aspirational, and
   it is the reason `Implements:` above is empty.

## Execution

`develop-change` task by task, then `check-traceability` (N/A here — no
config), `verify-before-merge`, independent review, `merge-change`.
