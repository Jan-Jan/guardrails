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

*(Code pruned at merge: 14 lines.)*

Expected before implementation: both fail — the first with exit 2
(`'docs/risk  # the RMF', which does not exist`), the second with exit 2
(`id_prefixes entry is not a bare identifier: PR`, the `\r` invisible).

### 1.2 Implementation

In `scripts/lib.sh`, above `cfg_get`:

*(Code pruned at merge: 17 lines.)*

Then thread it through both readers — `cfg_get` gains
`awk -v k="$1" "$GR_AWK_CLEAN_VALUE"'...'` and prints `gr_clean($0)`; `cfg_list`
the same for its `- item` branch. Full bodies:

*(Code pruned at merge: 15 lines.)*

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

*(Code pruned at merge: 37 lines.)*

Expected before implementation: the first four pass with **exit 0** (the
defect); the fifth passes already and is a guard against over-rejecting.

### 2.2 Implementation

In `scripts/lib.sh`, a new `gr_check_config` containing, in order: the BOM
rejection, then the line-shape scan. Exact code:

*(Code pruned at merge: 34 lines.)*

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

*(Code pruned at merge: 16 lines.)*

The two-phase shape is deliberate: it proves the gate *does* fire on the same
tree with the key spelled correctly, so the exit 2 is closing a real hole
rather than a hypothetical one.

### 3.2 Implementation

Add to `scripts/lib.sh` beside the other constants:

*(Code pruned at merge: 15 lines.)*

and, at the end of `gr_check_config`:

*(Code pruned at merge: 5 lines.)*

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

*(Code pruned at merge: 33 lines.)*

Append to `tests/lib.bats`:

*(Code pruned at merge: 12 lines.)*

### 4.2 Implementation

Constant, beside `GR_KNOWN_KEYS`:

*(Code pruned at merge: 10 lines.)*

Appended to `gr_check_config`:

*(Code pruned at merge: 40 lines.)*

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

*(Code pruned at merge: 10 lines.)*

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

*(Code pruned at merge: 6 lines.)*

---

## Task 7 — the migration path

**Trace IDs:** none.

This is the part that makes it a separate change. `skills/ratchet/SKILL.md`
already carries an upgrade table from change A; this change adds every new
exit-2 cause to it, each with *why it was never safe*:

*(Code pruned at merge: 6 lines.)*

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
