# How this landed: three changes

This plan records one investigation — five rounds of work and four independent
reviews — but it does **not** land as one change. The fourth reviewer judged
the accumulated work to be three units, and the maintainer agreed:

| Change | Contents | Status |
|---|---|---|
| **A — false-green fixes** (this branch) | F1 unminted-draft pre-flight, F2 the single annotation rule, F3a configured-path and empty-ledger validation, F3b the `checked:`/`sources:` summary, plus the shell-correctness defects these uncovered: `gr_die` inside pipeline subshells, a pipeline swallowing an exit status, whitespace in draft ledger names, newline-only splitting of path lists, and mint/pre-flight/rewrite scan-scope alignment | here |
| **B — config schema validation** | `gr_check_config`: closed key set, column-one key grammar, a required-gated-prefix rule, the per-prefix required-document map, and CRLF / inline-comment / BOM / `---` lexing. This changes the compatibility contract of every existing guardrails project, so it needs its own change, its own migration note and its own review | landed — `docs/plans/2026-08-18-config-schema.md` |
| **C — item placement** | The `MISPLACED-ITEM` gate: an item must be defined in the document configured for its prefix. A new user-visible traceability rule — in this project's own vocabulary a REQ, not a problem-report fix — so it needs a requirement behind it | follow-up |

**What change A knowingly ships with, because B and C are not here yet.**
Neither is an oversight; both are reproduced, understood, and deliberately
deferred:

1. A **missing or misspelled** config key still reads as "this project does not
   use that document". `doc_rmff:` instead of `doc_rmf:` leaves every hazard
   unchecked and exits 0. Change A closes the case where a key is present and
   its *path* is wrong; change B closes the case where the key itself is wrong.
   **Change B has since landed and closed this.** The paragraph is left as
   written because it records what was true of change A at the time it was
   signed; the statements in `README.md` and the `check-traceability` skill
   were updated by change B, as its Task 6 required.
2. `checked:` counts items found anywhere in the tree, so an item defined
   outside its configured document is counted without being examined —
   `**SDD-001**:` in `docs/design.md` with no `traces:` at all passes. Change C
   closes this and is what finally makes the summary a coverage claim rather
   than a population count.

Both are stated in `README.md` and the `check-traceability` skill rather than
left for a reader to discover.

## Change A: what the fifth review found, and its evidence

Change A was reviewed independently after the split. Verdict FINDINGS: three
blocking, eleven non-blocking. The blocking three were all artefacts of the
split itself or of a claim wider than the code:

| # | Finding | Fix |
|---|---|---|
| A1 | `finalize-ids.sh` carried a comment asserting config-key validation that left with change B — and the defect it named (a misspelled `doc_*` key leaving a half-finalized tree at exit 0) is live | Comment corrected to say what the code does, and a KNOWN GAP note added naming change B and the `check-ids.sh` backstop |
| A2 | The admitted "missing key" gap was written as document-only. It also disables `MISSING-TEST` wholesale (`test_path:`) and half of `DANGLING-REF` (`strict_path:`), and a config with no `doc_*` keys at all runs every gate off and exits 0 | Gap restated in full in `README.md` and the skill, with `sources:` named as the tell |
| A3 | `require_paths` short-circuited on `[ -e ]`, so an empty directory passed while three documents promised exit 2 for "an entry matching no file present in the working tree" — and `sources:` then reported `strict 1` for a source that read nothing | Short-circuit removed; every entry must match a file. The fixture gained `src/.gitkeep`, which is what `ratchet` already tells operators to do |

Two non-blocking findings were fixed rather than recorded, because both are
the change's own thesis:

- The SDD block in `check-trace.sh` had no terminator, so an unrelated
  `traces:` further down the file credited an SDD carrying none of its own.
  It now ends at the next definition line or heading, the rule
  `parse_llr_file` already used. (Care is needed here: the SDD header line
  usually carries its own `traces:`, so the header must fall through to the
  scan rather than `next` past it — the first attempt at this fix broke
  fifteen tests by getting that wrong.)
- The F1 pre-flight built its pattern from the declared prefixes, so a draft
  whose prefix was missing from `id_prefixes` — one that can never be minted —
  rode onto the base branch with both merge gates green. It now scans for any
  `<prefix>-DRAFT-<slug>-<n>` token.

The remaining non-blocking findings are recorded in the gap list below.

## Change A: the seventh review

The round-6 fixes were themselves unreviewed, so change A was reviewed again.
Verdict FINDINGS: four blocking, five non-blocking — and a convergence
judgement worth recording in full, because it changed how this record is
maintained:

> The code is converging. The verification record is oscillating. […] Every one
> of these claims is a *derived* fact maintained by hand-editing prose about a
> branch that keeps moving. Each round's fix is another hand-edit, which is why
> round 6's fix to the corpus block produced round 7's finding about the corpus
> block. […] This is structural, and more review rounds will not resolve it.

Acted on directly: **`tests/evidence.sh`** now derives the test counts, the
new-or-renamed set and the cannot-go-red list from the repository at merge
time, and the verification record pastes its output verbatim. The figures that
five separate review rounds found stale or overstated are no longer written by
hand.

| # | Finding | Fix |
|---|---|---|
| A7 | `check-ids.sh`'s widened draft pattern was a user-visible behaviour change with **zero** test coverage — reverting it left the suite fully green. AGENTS.md requires a test for every behaviour change, and the record claimed one existed | Two tests added, covering the block and `--allow-drafts` |
| A8 | The pathspec change is a **third** exit-1 upgrade impact: git's `*` crosses `/` where a shell glob does not, so `src/*.c` now reaches into subdirectories. The ratchet note promised exactly two | Upgrade note corrected to three, with the scope change explained |
| A9 | The corpus block claimed to postdate every fix; the timestamp preceded the last commit by three minutes. Worse, it claimed to cover the `set -f` fix — but the corpus config contains no glob or pathspec character at all, so that run could not exercise it | Corpus re-run after the final commit, and the claim narrowed to what it actually demonstrates |
| A10 | The plan forward-referenced a "change-A mutation list" that did not exist, so no fix in change A had a mutation citation | The list above. Round 5's citations are now marked as belonging to the combined work |

Fixed rather than recorded: the rationale comment in `check-trace.sh` still
said entries are "expanded by the shell", six lines below the `set -f` that
stopped exactly that — the same shape as round 6's finding that the correction
reached README and the skills but not the source of truth; `README.md` still
named one cause of `UNMINTED-DRAFT`; and a reflowed paragraph had been left
with an over-long line.

## Change A: mutation evidence

Every fix in change A, the mutation that reverts it, and the test that goes red
as a result. Cited by test name — test numbers depend on run order and have
been wrong in this record before. Each mutation was applied to a scratch copy
and the suite re-run; unless noted, each reddens exactly the test named and
nothing else.

| Fix | Mutation | Test that goes red |
|---|---|---|
| F1 unminted-draft pre-flight | delete the pre-flight block | `finalize: refuses to run when a draft ID has no bold definition header`, `names the file and line of each unminted draft`, `a well-formed draft alongside a malformed one still blocks` |
| F2 one annotation rule (`traces:`) | restore the head-of-run `traces:` regex | `traces: with no ID list is untraced even if a REQ appears later` |
| F2 one annotation rule (`satisfies:`) | restore the greedy `sub(/.*satisfies:/…)` | `a REQ named in prose after satisfies: does not satisfy an LLR` |
| F2 one annotation rule (`verifies:` etc.) | `ids_matching` back to `grep -oE` on the whole line | `a REQ in a parenthetical after the list is not coverage` |
| F3a absent configured path | delete `gr_die` from `gr_doc_files` | `a configured doc path that is absent fails loudly`, `gr_doc_files dies when a configured path does not exist` |
| F3a empty ledger directory | delete the `*.md` count check | `a ledger directory holding no *.md is an error`, `gr_doc_files dies when a configured directory holds no *.md` |
| F3a path-list existence | delete both `require_paths` calls | `a configured test path that is absent fails loudly`, `a configured strict path that is absent fails loudly`, `an absent path containing a space is named in full` |
| F3b summary lines | delete the summary block | `prints how many items of each prefix were checked`, `reports how many source files each gate read` |
| F3b per-prefix attribution | report the REQ count under every prefix | `prints how many items of each prefix were checked` |
| Prefix validation | drop the bare-identifier check | `an ID prefix that is not a bare identifier is an error` (in check-trace, finalize-ids and check-ids), `gr_prefixes rejects a prefix that is not a bare identifier` |
| `gr_prefix_re` status propagation | restore the `gr_prefixes \| tr` pipeline | `check-ids: an ID prefix that is not a bare identifier is an error` |
| `gr_prefixes` IFS independence | drop the IFS save/restore | `gr_prefixes splits on spaces even when the caller set IFS to newline` |
| Rename loop out of its subshell | restore `printf … \| while` | `a rename that fails aborts instead of reporting success` |
| Whitespace in draft ledger names | delete the whitespace `case` | `a draft ledger name with whitespace fails before anything is rewritten` |
| Newline-only path splitting | remove `IFS='\n'` | `an absent path containing a space is named in full` |
| `doc_*` value validation in finalize | delete the `gr_doc_files` loop | `a doc key whose path is missing fails before anything is minted` |
| Scan-scope alignment (mint) | widen the mint scan to `-- .` | `a draft inside .guardrails is not minted against a rewrite that skips it` |
| Scan-scope alignment (`max_final`) | revert `max_final` to `-- .` | `an ID defined under .guardrails does not shift the next number` |
| Quote-safe path counting | restore the per-name `[ -e ]` loop | `a pathspec matching a non-ASCII path is accepted` |
| A3 empty-directory check | restore the `[ -e ] && continue` short-circuit | `a configured directory that is empty matches no file` |
| A3 SDD block terminator | delete the two terminator rules | `an unrelated later traces: does not credit an SDD block` |
| A3 generic draft pattern (finalize) | restore the prefix-limited `draft_re` | `a draft whose prefix is missing from id_prefixes still blocks` |
| A4 `set -f` pathspec handling | remove `set -f` | `a path entry is a git pathspec, not shell-expanded at the root` |
| A7 generic draft pattern (check-ids) | restore the prefix-limited `draft_re` | `check-ids: a draft whose prefix is missing from id_prefixes is still a draft` |
| A8 `.guardrails` exclusion in the duplicate-vs-base scan | drop the exclusion | `check-ids: an ID defined under .guardrails is not a duplicate of a minted one` |
| A9 a named base ref must resolve | revert **both** the ref validation and the `git diff` status check | `check-ids: a named base ref that does not resolve is an error` — the test pins the behaviour, which either guard alone satisfies, so both must be reverted to redden it |
| A10 an undetectable base is announced, not fatal | delete the `SKIPPED-DUPLICATE-BASE` notice | `check-ids: an undetectable base says the gate was skipped, and still passes` |

Two behaviours in change A have **no mutation available and no test**, and are
not claimed as covered: the `git grep` status checks in `finalize-ids.sh`'s
pre-flight and in `check-ids.sh`'s draft scan. Both are defence in depth
against a scan that fails loudly; neither can be provoked from a fixture,
because git grep reports several real failures on stderr while still exiting 1.
`tests/evidence.sh` has no bats test either. All three are in the verification
record's gap list, and that list — not this section — is the authority on what
is uncovered.

## Change A: the sixth review

The round-5 fixes were themselves unreviewed, so change A was reviewed once
more before signing. Verdict FINDINGS: three blocking, twelve non-blocking.

| # | Finding | Fix |
|---|---|---|
| A4 | **`strict_paths`/`test_paths` entries were shell-globbed before reaching git.** `strict_paths: - *.c` with a `main.c` at the repo root was replaced by that root match, so `src/foo.c` was never scanned — exit 0 with `sources: strict 1` — while deleting the unrelated root file made the same config exit 1. Three documents recommended the shape and one claimed the entries were "handed to `git grep` as-is" | `set -f` after the `doc_*` globs are resolved, so path entries reach git verbatim as pathspecs; docs corrected to say pathspec, and that `doc_*` values are plain paths only |
| A5 | The verification record's derived figure was stale: "32 of 37", derived before the round-5 fixes added three tests | Re-derived at the time, and later superseded entirely: the figures are now generated by `tests/evidence.sh` and live only in the verification record. Any number quoted in this historical section is the value as of that round, not the current one |
| A6 | The record's corpus-regression block was byte-identical to a pre-fix run, undated and without its command — offered as evidence for fixes it could not have exercised | Corpus re-run against the current scripts, dated, with the command recorded |

Fixed rather than recorded: the missing-key gap statement in `check-trace.sh`'s
own header still said "document" (the correction had reached `README.md` and
the skill but not the source of truth); `UNMINTED-DRAFT` named a remedy that
could not clear the block for the undeclared-prefix case it had just started
catching, and `merge-change` repeated it; `check-ids.sh` still built its draft
pattern from the declared prefixes, so the two merge gates disagreed about what
a draft is; `README.md` and two skills claimed shell globs and pathspecs work
for `doc_*`, which they do not; the SDD terminator's new exit-1 shapes were
missing from the ratchet upgrade note; and the continuation-line case — an
annotation *below* the SDD header, the exact shape a careless fix breaks — had
no test.

**Change A's evidence lives in one place only.** The test counts, the
new-or-renamed set and the list of tests that cannot go red are derived by
`tests/evidence.sh` and pasted into
`docs/verification/2026-08-18-false-green-a.md`. They are deliberately **not**
repeated here.

An earlier draft of this section carried its own copy of those figures. It went
stale when round 7 added two tests, and the signed record and this plan then
stated different numbers for the same derived fact — in the section that had
just been written to stop exactly that. Two copies of a derived figure is the
defect; deleting one is the fix.

---

The sections below are the full working record, kept whole because the reviews
build on each other. Round numbering refers to the combined work; the "What
changed" tables mark which change each fix belongs to only where it is not
obvious from the description.

---

# False-Green Fixes Implementation Plan

**Goal:** Stop the guardrails check scripts from reporting success in cases
where they did nothing, verified nothing, or checked nothing.

**Defects:** F1 `finalize-ids.sh` reports success while draft IDs remain ·
F2 `check-trace.sh` credits any ID that appears anywhere on an annotation
line · F3 checks pass vacuously when a configured path is absent, and no
check ever reports its own denominator.

**Trace note:** this repo has no `.guardrails/config.yaml` and no
SRS/RMF/problems ledgers, so there is no PR item to mint and no REQ to
implement. The `resolve-problem` substance is kept (record first — this
plan; reproduce failing-first; TDD) and the ledger step degrades to this
document. Fixing that gap is out of scope here.

**Safety class:** n/a (this repo is the tooling, not a medical device).

**Verification:** `sh tests/run-tests.sh` — 65/65 at baseline (`cb130db`),
must stay green plus the new cases.

---

## Why these three

All three share one shape: **a green result that carries no information.**

| | Observed | Consequence |
|---|---|---|
| F1 | `finalize-ids.sh` mints only drafts whose item header is bold at line start (`finalize-ids.sh:60`). A plain `PR-DRAFT-b-1:` header is skipped; the script still renames the ledger files and exits 0. | Hit on sightings-app 2026-08-12 (PR-058/059). Caught only later, by `check-ids.sh`, at the merge gate. |
| F2 | `ids_matching` greps a line containing `verifies:` and takes any matching ID *anywhere on it* (`check-trace.sh:54`). Same hole in `satisfies:` (`:90`) and `traces:` (`:159`). | `verifies: REQ-001 (was REQ-042)` credits REQ-042 with coverage it does not have. A parenthetical can mask a deleted test. |
| F3 | `gr_doc_files` yields nothing for a configured-but-absent path (`lib.sh:57`), so whole gate families silently do not run; no check prints how many items it examined. | A typo in `doc_rmf` turns every hazard gate into a no-op and the script exits 0. "Green over 0 items" is indistinguishable from "green over 63". |

---

## Task 1 — F1: refuse to finalize when a draft would be left behind

**File:** `scripts/finalize-ids.sh`

The gate is a **pre-flight**: it runs after the mapping is computed and
before anything is rewritten or renamed. A half-finalized tree is worse than
an untouched one — the operator's fix is to add the missing `**` markers,
which is easier on a tree nothing has touched.

### 1.1 Failing tests first

Append to `tests/finalize-ids.bats`:

```bash
@test "finalize: refuses to run when a draft ID has no bold definition header" {
    printf 'PR-DRAFT-b-1: crash on empty input. affects: REQ-001. status: open\n' \
        > docs/problems/DRAFT-b-notes.md
    commit_all draft
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNMINTED-DRAFT"* ]]
    [[ "$output" == *"PR-DRAFT-b-1"* ]]
    # nothing was rewritten and the ledger file was NOT renamed
    git diff --quiet
    [ -f docs/problems/DRAFT-b-notes.md ]
}

@test "finalize: names the file and line of each unminted draft" {
    printf '# verifies: REQ-DRAFT-b-9\ntrue\n' > tests/test_orphan.sh
    commit_all orphan
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 1 ]
    [[ "$output" == *"tests/test_orphan.sh:1"* ]]
}

@test "finalize: a well-formed draft alongside a malformed one still blocks" {
    printf '\n**REQ-DRAFT-b-1**: good draft.\n' >> docs/requirements/0001-01-01-base.md
    printf 'PR-DRAFT-b-2: bad header.\n' > docs/problems/DRAFT-b-notes.md
    commit_all mixed
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 1 ]
    grep -q 'REQ-DRAFT-b-1' docs/requirements/0001-01-01-base.md
}
```

Run: `sh tests/run-tests.sh tests/finalize-ids.bats` — expect 3 failures
(status 0, no `UNMINTED-DRAFT` in output).

### 1.2 Implementation

Insert after the prefix loop that builds `$mapping` (currently ends line 71),
before the draft-doc-file rename block:

```sh
# --- Pre-flight: every draft token in the tree must have been minted -------
# Only drafts with a bold `**PREFIX-DRAFT-slug-n**:` header at line start are
# minted above. Without this gate a plain `PREFIX-DRAFT-slug-n:` header is
# skipped, the ledger files are renamed anyway, and the script exits 0 —
# a silent no-op reported as success.
gr_contains() {
    case "
$1
" in *"
$2
"*) return 0 ;; esac
    return 1
}

P=$(gr_prefix_re)
draft_re="(${P})-DRAFT-[A-Za-z0-9][A-Za-z0-9-]*-[0-9]+"
mapped=$(printf '%s' "$mapping" | cut -d' ' -f1 | sort -u)
unminted=""
for t in $(git grep -hoI --untracked -E "$draft_re" \
        -- . ":(exclude).guardrails" 2>/dev/null | sort -u); do
    gr_contains "$mapped" "$t" || unminted="${unminted}${t}
"
done

if [ -n "$unminted" ]; then
    printf '%s' "$unminted" | while IFS= read -r t; do
        [ -n "$t" ] || continue
        git grep -InI --untracked -F "$t" -- . ":(exclude).guardrails" 2>/dev/null \
            | sed 's/^/UNMINTED-DRAFT /'
    done
    echo "guardrails: the draft IDs above were never minted — each needs a bold" >&2
    echo "definition header at line start (**PREFIX-DRAFT-slug-n**:). Nothing was" >&2
    echo "rewritten or renamed." >&2
    exit 1
fi
```

Update the script header comment: add `1 unminted drafts remain` to the exit
codes, and state the pre-flight in the description.

Run the suite: 3 new tests green, existing finalize tests unchanged.

### 1.3 Commit

`git -c commit.gpgsign=false commit -am "fix: finalize-ids refuses to run when a draft would be left behind"`

---

## Task 2 — F2: an ID counts only inside the list that follows the keyword

**File:** `scripts/check-trace.sh`

One defect class, five keywords: `verifies:`, `mitigates:`, `implements:`
(all via `ids_matching`), `satisfies:` (in `parse_llr_file`), and `traces:`
(in the SDD block scan). The rule everywhere becomes: **only the leading run
of `ID[, ]ID…` immediately after the keyword counts.** Prose, an em-dash
clause, a parenthetical, or a trailing comment terminator ends the list.

Calibrated against the sightings-app corpus (407 `verifies:` lines): real
annotations are `verifies: LLR-001`, `verifies: PR-007, REQ-010, REQ-012`,
`verifies: PR-008,`, `verifies: REQ-021 (risk R-11) — the fallback`,
`verifies: REQ-085, REQ-090 */`. The run-consuming parser accepts every one
of those unchanged and stops before the parenthetical and the prose.

### 2.1 Failing tests first

Append to `tests/check-trace.bats`:

```bash
@test "trace: a REQ in a parenthetical after the list is not coverage" {
    printf '\n**REQ-002**: second requirement.\n' >> docs/requirements/0001-01-01-base.md
    printf '# verifies: REQ-001 (was REQ-002)\ntrue\n' > tests/test_a.sh
    commit_all parenthetical
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST REQ-002"* ]]
}

@test "trace: comma-separated lists, trailing commas and trailing prose all count" {
    printf '\n**REQ-002**: second.\n**REQ-003**: third.\n' >> docs/requirements/0001-01-01-base.md
    printf '# verifies: REQ-001, REQ-002 — the fallback path\n' > tests/test_a.sh
    printf '# verifies: REQ-003,\n' > tests/test_b.sh
    commit_all lists
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" != *"MISSING-TEST REQ-001"* ]]
    [[ "$output" != *"MISSING-TEST REQ-002"* ]]
    [[ "$output" != *"MISSING-TEST REQ-003"* ]]
}

@test "trace: a REQ in a parenthetical after satisfies: does not satisfy an LLR" {
    printf '\n**REQ-002**: second.\n' >> docs/requirements/0001-01-01-base.md
    printf '**LLR-001**: clamp. satisfies: REQ-001 (superseded REQ-002)\n' \
        > docs/architecture/0001-01-01-llr.md
    printf '# verifies: LLR-001\n' > tests/test_a.sh
    commit_all satisfies
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST REQ-002"* ]]
}

@test "trace: traces: with no ID list is untraced even if a REQ appears later" {
    printf '**SDD-001**: module. traces: none — replaces REQ-001\n' \
        > docs/architecture/0001-01-01-sdd.md
    commit_all traces
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNTRACED-DESIGN SDD-001"* ]]
}
```

Run: expect all four to fail (the greedy parser credits the parentheticals).

### 2.2 Implementation

Replace `ids_matching` (lines 48–56):

```sh
# ids_matching KEYWORD PREFIX PATHS… — IDs of PREFIX in the ID list that
# immediately follows KEYWORD. Only the leading run of `ID[, ]…` counts, so
# `verifies: REQ-001 (was REQ-042)` credits REQ-001 alone: prose after the
# list is commentary, not coverage.
ids_matching() {
    _kw="$1"
    _pfx="$2"
    shift 2
    [ $# -gt 0 ] || return 0
    git grep -hI --untracked -F "$_kw" -- "$@" 2>/dev/null \
    | gr_id_run "$_kw" \
    | grep -xE "${_pfx}-[0-9]{3,}" | sort -u
}
```

Add the shared extractor to `scripts/lib.sh` (used by `ids_matching` and by
the `satisfies:`/`traces:` parsers, so the rule is defined once):

```sh
# gr_id_run KEYWORD — filter: for each stdin line containing KEYWORD, print
# the IDs in the list that immediately follows it, one per line. The run ends
# at the first character that is not part of `ID`, a comma, or whitespace.
gr_id_run() {
    awk -v kw="$1" '
        {
            p = index($0, kw)
            if (p == 0) next
            rest = substr($0, p + length(kw))
            while (match(rest, /^[ \t,]*[A-Za-z]+-[0-9][0-9][0-9]+/)) {
                tok = substr(rest, RSTART, RLENGTH)
                sub(/^[ \t,]*/, "", tok)
                print tok
                rest = substr(rest, RSTART + RLENGTH)
            }
        }'
}
```

In `parse_llr_file`, replace the `satisfies:` split (lines 90–97) so the same
rule applies:

```awk
            else if ($0 ~ /satisfies:/) {
                rest = $0
                sub(/.*satisfies:/, "", rest)
                while (match(rest, /^[ \t,]*[A-Za-z]+-[0-9][0-9][0-9]+/)) {
                    tok = substr(rest, RSTART, RLENGTH)
                    sub(/^[ \t,]*/, "", tok)
                    if (tok ~ /^REQ-/) sat = sat (sat == "" ? "" : ",") tok
                    rest = substr(rest, RSTART + RLENGTH)
                }
            }
```

In the SDD scan, replace the `traces:` test (line 159) with one that requires
a REQ at the head of the run:

```awk
        cur != "" && /traces:[ \t,]*REQ-[0-9][0-9][0-9]/ { ok = 1 }
```

### 2.3 Regression evidence against the real corpus

Before committing, prove the tightening changes no verdict on a real project.
Run from the sightings-app checkout, with the old and new `check-trace.sh`:

```sh
cd /home/naturgewalt/Coding/yeti-guides/sightings-app
sh .guardrails/scripts/check-trace.sh > /tmp/trace-old.txt 2>&1; echo "old exit=$?"
# then with the new script copied in:
sh .guardrails/scripts/check-trace.sh > /tmp/trace-new.txt 2>&1; echo "new exit=$?"
diff /tmp/trace-old.txt /tmp/trace-new.txt
```

Expected: no difference in violations (their annotations are all list-shaped;
their parentheticals hold 1–2 digit legacy risk ids that never matched). Any
difference is a real finding and goes in the verification record, not
silently accepted. Restore sightings-app's script afterwards — this is a
read-only probe of another repo.

### 2.4 Commit

`git -c commit.gpgsign=false commit -am "fix: an ID counts only inside the list following its keyword"`

---

## Task 3 — F3a: a configured path that does not exist is an error

**Files:** `scripts/lib.sh`, `scripts/check-trace.sh`

Missing **key** stays legal (the project does not use that document).
Missing **path** for a configured key is an environment error — exit 2, the
same class as a missing config file.

### 3.1 Failing tests first

Replace the existing `lib.bats` case
`gr_doc_files on missing key or path prints nothing, exit 0` with two:

```bash
@test "gr_doc_files on a missing key prints nothing, exit 0" {
    run sh -c '. .guardrails/scripts/lib.sh && gr_doc_files doc_nonexistent'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "gr_doc_files dies when a configured path does not exist" {
    rm -rf docs/risk
    run sh -c '. .guardrails/scripts/lib.sh && gr_doc_files doc_rmf'
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_rmf"* ]]
    [[ "$output" == *"docs/risk"* ]]
}
```

And in `check-trace.bats`:

```bash
@test "trace: a configured doc path that is absent fails loudly, never silently passes" {
    rm -rf docs/risk
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_rmf"* ]]
}

@test "trace: a configured test path that is absent fails loudly" {
    rm -rf tests
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"test_paths"* ]]
}
```

### 3.2 Implementation

`gr_doc_files` gains an else branch:

```sh
    elif [ -f "$_v" ]; then
        printf '%s\n' "$_v"
    else
        gr_die "$1 is configured as '$_v', which does not exist"
    fi
```

In `check-trace.sh`, validate the list-valued paths up front, immediately
after they are read:

```sh
for _d in $strict_paths; do
    [ -e "$_d" ] || gr_die "strict_paths entry does not exist: $_d"
done
for _d in $test_paths; do
    [ -e "$_d" ] || gr_die "test_paths entry does not exist: $_d"
done
```

Then delete the now-dead `[ -e "$d" ]` guard in the DANGLING-REF scope loop
(line 204) — a path that survived validation always exists.

### 3.3 Commit

`git -c commit.gpgsign=false commit -am "fix: a configured path that does not exist is an error, not a silent skip"`

---

## Task 4 — F3b: every run reports its own denominator

**File:** `scripts/check-trace.sh`

A pass over zero items must not look like a pass over sixty-three. The
script prints one summary line at the end, on pass and on failure both.

### 4.1 Failing tests first

```bash
@test "trace: prints how many items of each prefix were checked" {
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"checked:"* ]]
    [[ "$output" == *"REQ 1"* ]]
}

@test "trace: an empty ledger reports zero rather than looking like a pass" {
    rm -f docs/requirements/*.md
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"REQ 0"* ]]
}
```

### 4.2 Implementation

Immediately before `exit $fail`:

```sh
# --- Summary: a green run over zero items must not look like a green run ---
# over sixty-three. Printed on pass and on failure alike.
summary=""
for pfx in $(cfg_get id_prefixes); do
    n=$(ids_defined "$pfx" | grep -c . || true)
    summary="${summary}${summary:+, }${pfx} ${n}"
done
echo "checked: $summary"
```

### 4.3 Commit

`git -c commit.gpgsign=false commit -am "feat: check-trace reports how many items it checked"`

---

## Task 5 — documentation the change invalidates

1. `scripts/finalize-ids.sh` header — exit code 1 and the pre-flight.
2. `scripts/check-trace.sh` header — exit code 2 for a bad configured path,
   the new summary line, and the "ID list, not ID on the line" rule.
3. `skills/merge-change/SKILL.md` step 3 — finalize-ids can now fail; a
   non-zero exit means a malformed draft header, fix and rerun from step 1.
4. `skills/check-traceability/SKILL.md` — document the summary line and
   teach reading it (`REQ 0` on a project that should have requirements is a
   finding, not a pass).
5. `README.md` — check the documented exit codes and update if stated.
6. `templates/problems.md` and the other templates already show bold
   headers; confirm no template demonstrates the plain-header form that
   Task 1 now rejects.

Commit: `git -c commit.gpgsign=false commit -am "docs: record the new exit codes, summary line and annotation rule"`

---

## Self-review

- Every defect (F1, F2, F3a, F3b) has at least one task whose tests fail
  before the change and pass after.
- Task 2 additionally carries corpus evidence from a real project, because
  bats fixtures cannot show absence of regression at scale.
- Names used across tasks are consistent: `gr_id_run` and `gr_contains` are
  each defined once, in the file that owns them.
- No placeholders.

## Execution

`develop-change` task by task, then `verify-before-merge`, then
`merge-change` (independent review at step 6a, verification record at 6b).

---

## Round 2 — after independent review

The first round passed 77/77 and was blocked at `merge-change` step 6a. The
independent reviewer (no implementation narrative, given only the diff and
this plan) returned **FINDINGS**: three BLOCKING, eight non-blocking. All
three blocking findings were reproduced here before any fix was written.

### The blocking findings

**R1 — the fix did not close its own motivating case.** §2 of this plan cites
"a typo in `doc_rmf` turns every hazard gate into a no-op and the script
exits 0". Round 1 made a *configured-but-absent path* fatal, but an absent
**key** still read as "this project has no RMF". Reproduced: `doc_rmff:`
with `HAZ-002` unmitigated → `checked: REQ 1, HAZ 2, RC 1, SDD 1, LLR 1, PR 0`,
exit 0 — byte-identical to a clean run, while the correct config on the same
tree reports `UNMITIGATED-HAZARD HAZ-002`, exit 1. `test_paths:` mistyped as
`test_path:` disabled the flagship MISSING-TEST gate the same way.

Worse, the `checked:` line *added* in round 1 made this louder rather than
quieter: it counts IDs defined anywhere in the tree, so a gate that never ran
still printed a confident denominator for its prefix.

**R2 — a ledger directory holding no `*.md` was still an empty list.**
`gr_doc_files` only died when the path was neither a file nor a directory.
Reproduced: `docs/risk/` present but empty → hazard gate skipped, exit 0.

**R3 — the F1 pre-flight went blind on a failed scan.** `git grep`'s stderr
was sent to `/dev/null` and its status ignored, so "the scan failed" and "no
drafts found" were the same outcome. Reproduced with `id_prefixes: REQ PR[`
(an invalid ERE): ledger renamed, exit 0, `PR-DRAFT-b-1` still in the tree —
exactly the failure the gate exists to prevent.

### What changed

| # | Fix | Where |
|---|---|---|
| R1a | `gr_check_config`: closed key set — an unrecognised top-level key is exit 2 | `lib.sh`, called from `check-trace.sh` |
| R1b | `gr_check_config`: every ID prefix declared in `id_prefixes` must have its document configured, and REQ/LLR require a non-empty `test_paths` | `lib.sh` |
| R1c | Second summary line, `sources:`, counting the files and paths each gate actually read — `checked:` alone counts items, not coverage | `check-trace.sh` |
| R2 | `gr_doc_files` dies on a directory with no `*.md` | `lib.sh` |
| R3a | `gr_prefixes` validates each prefix as a bare identifier — prefixes are interpolated into every scan pattern | `lib.sh` |
| R3b | The pre-flight scan no longer swallows stderr and checks `git grep`'s status (`>1` is a real failure, `1` is "no match") | `finalize-ids.sh` |
| R4 | One definition of the annotation rule, `GR_AWK_ID_RUN`, shared by the shell filter and both awk programs | `lib.sh`, `check-trace.sh` |
| R5 | `strict_paths` existence gate now has a test (AGENTS.md: every behavior change needs one) | `tests/check-trace.bats` |
| R6 | `--dry-run` can exit 1: documented and tested, since the pre-flight deliberately precedes the dry-run early exit | `finalize-ids.sh`, tests |
| R7 | Path lists split on newlines only, so an entry with a space is passed and reported intact | `check-trace.sh` |
| R8 | The rename loop left its pipeline subshell — `gr_die` there exited only the subshell and the script still reached `exit 0` | `finalize-ids.sh` |
| R9 | Summary test asserts the whole `checked:` line against deliberately unequal per-prefix counts | `tests/check-trace.bats` |
| R10 | `.gitkeep` guidance for configured-but-empty directories, since git does not track empty directories and a fresh clone would exit 2 | `skills/ratchet/SKILL.md` |

R4 fixed two live defects, not just duplication: `traces:` demanded a REQ at
the *head* of its list (`traces: SDD-002, REQ-001` was falsely reported
`UNTRACED-DESIGN`), and `satisfies:` scanned from the *last* occurrence on the
line, so `satisfies: none yet — see the satisfies: REQ-001 form` credited
REQ-001. The second is a false green of exactly the kind this change exists to
remove.

### Evidence

- Suite: 98 tests, all green (65 before this change, 77 after round 1).
- **Every new test mutation-tested.** Reverting each fix in a scratch copy
  turns the matching test red: R1a/b→51,52,53 · R2→54,92 · R3a→57,75,93 ·
  R4(traces)→58 · R4(satisfies)→59 · R5→55,56 · R6→61,74 · R7→56 · R8→76 ·
  R9→48 · R1c→49,50.
- Corpus regression on `sightings-app` (91 REQ, 65 PR, 35 problem ledgers),
  read-only: verdict identical to the installed v0.1.0 scripts, differing
  only by the two new summary lines. Its working tree stayed clean.
- The three blocking reproductions now exit 2 with a named cause.

### Known gap, recorded rather than hidden

R3b's status check has **no test**. Its only reachable trigger was an invalid
prefix regex, and R3a now rejects that upstream at config-parse time, so the
scan cannot be made to fail from a fixture. It is kept as defence in depth
against future scan failures, and is honestly untested.

---

## Round 3 — after the second independent review

Round 2 passed 98/98 and was again blocked at step 6a. The re-reviewer (given
the diff, this plan, and round 1's findings, with no implementation narrative)
returned **FINDINGS**: two BLOCKING, eight non-blocking. Both blocking findings
were reproduced here before any fix was written.

### Corrections to round 2's own claims

Round 2 asserted "**Every new test mutation-tested**". That was overstated,
and the re-review was right to check it:

- **Test 77** (`same-day rename collision never overwrites`) is green against
  the pre-change baseline `cb130db` — it is tied to no change in this diff and
  never appeared in the mutation table. It is a characterization test, kept as
  one, not evidence for any fix.
- **Tests 43 and 58** cannot go red against `cb130db`. Test 43 is an
  over-tightening guard (it bites if `gr_id_run` is made too strict); test 58
  is a regression test for a defect created *and* removed inside this change.
  Both are worth keeping; neither is evidence that a pre-existing defect was
  fixed.
- **`R6→61,74` was wrong.** Moving the pre-flight below the `--dry-run` exit
  reddens tests 72 and 74, not 61, and R6 changed no code — the pre-flight
  already sat above that exit in round 1.

Two diff items round 2 failed to declare, now declared: **`scripts/check-ids.sh`**
gained `|| exit 2` on its `gr_prefix_re` call (a real behaviour change — it
previously printed `grep: Unmatched ( or \(` and exited 0 — and it now has a
test), and **`tests/helpers.bash`** gained the ratchet README/soup files,
which changes what all tests exercise.

### The blocking findings

**R11 — `checked:` still asserted a denominator for gates that never ran.**
`ids_defined` scans the whole tree, but `UNTRACED-DESIGN`, `UNSATISFIED-LLR`
and `UNANALYZED-DERIVED` only read the configured document. Reproduced with a
valid, untouched config:

```
docs/design.md:  **SDD-001**: Dose limiter module.     <- no traces:
                 **LLR-001**: Clamp requested dose.    <- no satisfies:
$ check-trace.sh
checked: REQ 1, HAZ 1, RC 1, SDD 1, LLR 1, PR 0
exit=0
```

`git mv docs/design.md docs/architecture/sad.md`, changing not one character
of content, turns the same run into `UNTRACED-DESIGN SDD-001` +
`UNSATISFIED-LLR LLR-001`, exit 1. Two real violations, invisible, with a
summary line identical to the failing run's.

**R12 — the "closed key set" was not closed.** The key check matched only
`/^[A-Za-z_][A-Za-z0-9_]*:/`, the same shape `cfg_get` matches, so a key that
is invisible to the config reader is equally invisible to the check.
Reproduced: `strict-paths:`, ` strict_paths:` and `strict_paths :` each drop
the entire `strict_paths` half of DANGLING-REF scope and exit 0 — while
`README.md` claimed, unqualified, "Exit 2 — never a quiet exit 0 — for an
unrecognised config key".

### What changed

| # | Fix | Where |
|---|---|---|
| R11 | New `MISPLACED-ITEM` gate: an item must be defined inside the document configured for its prefix. While it is green, every item counted in `checked:` sits in a document some gate opened — which is what makes the summary trustworthy | `check-trace.sh` |
| R12 | Config validation now rejects any line that is not blank, a comment, a `  - item` list entry, or `<known key>:` at column one, naming the line number and text | `lib.sh` |
| R13 | `gr_prefix_re` no longer swallows `gr_prefixes`' exit status through a pipeline — every `|| exit 2` guard added in round 2 was dead code, and `check-ids.sh` reported a misleading second error | `lib.sh` |
| R14 | `finalize-ids.sh` validates the config: a typo'd `doc_*` key made it skip that ledger's renames and still exit 0 | `finalize-ids.sh` |
| R15 | Config values drop a trailing CR and a trailing ` # comment` — a CRLF config previously died accusing a prefix that looked perfectly valid, and `templates/config.yaml` invites inline comments | `lib.sh` |
| R16 | A draft ledger filename containing whitespace is rejected during planning. The rename records are space-joined pairs, so such a name failed *after* the ID rewrite pass, leaving a half-finalized tree | `finalize-ids.sh` |
| R17 | Removed a dead `git ls-files` branch in the path check: the shell already expands a glob entry at the call site. The test that "covered" it passed for that reason and proved nothing; it now plants a dangling reference behind the glob and requires the scan to find it | `check-trace.sh`, tests |
| R18 | `.gitkeep` guidance corrected — it satisfies `strict_paths`/`test_paths` but **not** a `doc_*` directory, which needs a real `*.md`. Added an upgrade note for existing projects, whose exit 2 on upgrade reports pre-existing gaps rather than new requirements | `skills/ratchet/SKILL.md` |
| R19 | `check-ids.sh` prefix validation now has a test (AGENTS.md) | `tests/check-ids.bats` |

### Evidence

- Suite: **112 tests, all green** (65 → 77 → 98 → 112).
- Round-3 mutations, each turning the named tests red: R11→43,44,45 ·
  R12→47,48,49 · R15→50,51 · R14→72 · R16→73 · R13→86 · path checks→30,38,39,53.
  Mutation N4 is recorded as a *failure of the test*, not of the code: removing
  the `git ls-files` branch reddened nothing, which is how R17 was found.
- Corpus regression on `sightings-app` at `b56e8aa8` (101 REQ, 4 HAZ, 10 RC,
  26 SDD, 33 LLR, 65 PR — 239 items across 35 problem ledgers), baseline and
  new scripts run back-to-back on the same tree: **output identical except the
  two summary lines**, exit 0 both times; `check-ids.sh` exit 0. No
  `MISPLACED-ITEM`, so every item there already lives in its own document, and
  the stricter config rules accept a real project's config unchanged. Its
  working tree stayed clean.

### Known gaps, recorded rather than hidden

1. R3b's `git grep` status check still has no test; R3a rejects the only
   reachable trigger upstream. Kept as defence in depth, honestly untested.
2. Tests 43, 58 and 77 cannot go red against `cb130db`, as set out above.
3. `check-trace.sh` is the only script that calls `gr_check_config` besides
   `finalize-ids.sh`; `check-ids.sh` and `check-signing.sh` do not, so a
   malformed config is caught at the traceability and finalize gates rather
   than at every entry point.

---

## Round 4 — after the third independent review

Round 3 passed 112/112 and was blocked at step 6a again. The third reviewer
returned **FINDINGS**: two BLOCKING, ten non-blocking. Both blocking findings
were reproduced here first.

### Corrections to round 3's own claims

- **The round-3 mutation table's test numbers were unreproducible.** They were
  numbered against an undocumented partial run, while the gap list immediately
  below used full-suite numbers — so "43" meant two different tests in the same
  section. Evidence that cannot be re-run from its own citation is the same
  failure this change exists to remove. **Every mutation is cited by test name
  from here on**, never by number.
- **Five tests cannot go red against `cb130db`, not three.** Round 3 admitted
  `comma lists, trailing commas and trailing prose all count`,
  `traces: counts a REQ anywhere in its list`, and
  `same-day rename collision never overwrites an existing file`. Two more:
  `items inside their own document are not misplaced` (a negative guard for a
  gate that does not exist at baseline) and, as it was then written,
  `a strict path written as a glob still reaches the scan`. The latter is now
  genuinely load-bearing — see R21.

### The blocking findings

**R20 — the prefix→document model was incomplete, so `checked:` still
asserted a denominator for gates that never ran.** Two reproductions on
configs that `gr_check_config` accepted without complaint:

- `id_prefixes: … TC` with `**TC-001**:` in a scratch file →
  `checked: … PR 0, TC 1`, **exit 0**. No document was required for `TC` and no
  gate exists for it, so the item was counted and read by nothing. With
  `id_prefixes: TC` alone, every gate including DANGLING-REF is skipped and the
  run still exits 0.
- `id_prefixes: HAZ RC` with `RC-001` and no implementing requirement anywhere
  → `checked: HAZ 1, RC 1`, **exit 0**. `UNIMPLEMENTED-CONTROL` reads
  `doc_srs` — a document RC is *not* defined in — but `doc_srs` was required
  only when `REQ` was declared. `MISPLACED-ITEM` cannot compensate: `RC-001` is
  correctly inside `doc_rmf`.

Both falsified the unqualified claim in `README.md`, `check-trace.sh` and the
`check-traceability` skill that a green run means every counted item lives in a
document some gate opened.

**R21 — a recursive git pathspec made a fully traced project exit 2.**
`test_paths: - *_test.sh` with `tests/unit/a_test.sh`: the shell cannot expand
it at the configured level, but git matches it recursively and `git grep` — the
thing that actually scans — accepts it. Baseline exit 0, round 3 **exit 2**.
Round 3 had removed that fallback as "dead code" on the strength of a test that
only ever exercised shell expansion, and then documented git-pathspec semantics
in two skills while implementing shell-glob semantics.

### What changed

| # | Fix | Where |
|---|---|---|
| R20a | `id_prefixes` may only name a prefix guardrails has gates for (REQ HAZ RC SDD LLR PR) | `lib.sh` |
| R20b | Each prefix requires the documents *its gates read*, not just the one it is defined in — `RC` now requires `doc_srs` as well as `doc_rmf` | `lib.sh` |
| R21 | Path entries accept a git pathspec again, and the match must exist in the working tree — a tracked-but-deleted path would otherwise pass the check while scanning nothing | `check-trace.sh` |
| R22 | The mint scan uses the same pathspec as the pre-flight and the rewrite. A wider mint scan burned an ID for a draft in `.guardrails/` that it then never rewrote, and exited 0 | `finalize-ids.sh` |
| R23 | A UTF-8 BOM is rejected with a named cause rather than silently making the first key unreadable; a leading `---` document separator is accepted | `lib.sh` |
| R24 | `MISPLACED-ITEM` guidance corrected: for illustrative text in a README, changelog, plan or fixture the fix is to stop writing a real three-digit ID, not to move anything. Also records that `doc_*` directories are read one level deep | `skills/check-traceability/SKILL.md` |
| R25 | `sources:` documented accurately — document figures are file counts, `strict`/`tests` are counts of configured entries | `check-trace.sh`, skill |
| R26 | `MISPLACED-ITEM`'s REQ and PR branches now have tests (round 3 covered only SDD/LLR/HAZ/RC) | `tests/check-trace.bats` |
| R27 | `templates/config.yaml` records the column-one key rule, the ` # comment` stripping and its one limitation, the no-BOM rule, and the closed prefix set | `templates/config.yaml` |

R21 also caught a hole in its own fix: the first version accepted a `test_paths`
entry that `git ls-files` matched but that no longer existed on disk. The
pre-existing test `a configured test path that is absent fails loudly` went red
and is what found it.

### Evidence

- Suite: **121 tests, all green** (65 → 77 → 98 → 112 → 121).
- Round-4 mutations, each cited by the test name it reddens:
  - remove the unmanaged-prefix check → `an ID prefix guardrails has no gates for is an error`
    (that rule and its test left with change B and were superseded there by an
    at-least-one-gated-prefix rule; this line records the combined work as it
    stood, not the shipped behaviour)
  - `RC` requires only `doc_rmf` → `RC declared without doc_srs is an error, not a skipped gate`
  - remove the pathspec fallback → `a recursive git pathspec in test_paths is accepted`
  - accept a pathspec match without checking it exists on disk → `a configured test path that is absent fails loudly`
  - widen the mint scan back to `-- .` → `a draft inside .guardrails is not minted against a rewrite that skips it`
  - remove the BOM check → `a config saved with a UTF-8 BOM is rejected, not half-read`

**These round-5 citations belong to the combined work, not to change A.** Two
of the tests they name (`a config saved with a UTF-8 BOM …`, and the
`gr_check_config` cases) left with change B and do not exist on change A's
branch. Change A's own mutation list is in the "Change A: mutation evidence"
section above; use that one when verifying change A.
- Corpus regression on `sightings-app`, baseline and new scripts back-to-back
  on the same tree (below).

### Known gaps, recorded rather than hidden

1. R3b's `git grep` status check has no test; its only reachable trigger is
   rejected upstream by prefix validation.
2. Five tests cannot go red against `cb130db`, listed above. They are
   over-tightening guards, negative guards, and characterization — kept as
   such, not counted as evidence for any fix.
3. `gr_clean` strips a trailing ` # comment` silently and quoting is not
   honoured, so a `verify_commands` entry containing a whitespace-delimited
   token starting with `#` would be truncated without a diagnostic. Recorded in
   `templates/config.yaml`; not otherwise mitigated.
4. `check-ids.sh` and `check-signing.sh` still do not call `gr_check_config`;
   a malformed config is caught at the traceability and finalize gates.
5. `gr_doc_files` reads a ledger directory one level deep, so an item in a
   subdirectory of `doc_sad` is `MISPLACED-ITEM`. Documented, not changed.

Corpus regression, round 4 — `sightings-app` at `b56e8aa8`, baseline and new
scripts run back-to-back on the same tree, read-only:

```
baseline exit=0 / new exit=0
diff: 7a8,9
> checked: REQ 101, HAZ 4, RC 10, SDD 26, LLR 33, PR 65
> sources: srs 19, rmf 7, sad 5, soup 1, problems 35; strict 5, tests 3
check-ids.sh exit=0        working tree clean
```

Identical verdict over 239 items and 35 problem ledgers; the stricter prefix,
document and path rules accept a real project's config unchanged.

---

## Round 5 — after the fourth independent review

Round 4 passed 121/121 and was blocked at step 6a. The fourth reviewer
returned **FINDINGS**: two BLOCKING, eleven non-blocking, plus a scope
judgement (below, which is a decision for the maintainer, not a defect).

Both blocking findings were introduced by round 4's own fixes.

### The blocking findings

**R28 — the restored pathspec check rejected any entry whose matches git
C-quotes.** `git ls-files` applies `core.quotePath`, so a path with a
non-ASCII byte, a quote, a tab or a newline comes back as `"t\303\251sts/…"`;
testing `[ -e ]` on that literal never matches. Reproduced: tests moved to
`tésts/a_test.sh` with `test_paths: - *_test.sh` — `git grep` scans it
perfectly, baseline exits 0, round 4 exits 2. R21's own failure shape,
reintroduced by R21's fix.

**R29 — `finalize-ids.sh` still exited 0 over a half-finalized tree.**
`gr_check_config` validates a key's *spelling*; nothing validated its
*value*. Reproduced with `doc_problems: docs/problemz` (key correct, path
moved): `PR-DRAFT-b-1 -> PR-001`, **exit 0**, the ID minted and rewritten
everywhere, and `docs/problems/DRAFT-b-notes.md` left un-renamed. R14 closed
the typo'd-key case and left the typo'd-value case, which is at least as
likely — and this is exactly the half-finalized state Task 1's rationale
argues must never be produced.

### What changed

| # | Fix | Where |
|---|---|---|
| R28 | The path check counts matches instead of parsing filenames — `cached - deleted + untracked > 0`. Immune to `core.quotePath`, and still rejects a path that is tracked but deleted on disk | `check-trace.sh` |
| R29 | `finalize-ids.sh` resolves every `doc_*` through `gr_doc_files`, which validates the value, not just the key | `finalize-ids.sh` |
| R30 | `max_final` uses the same pathspec as the mint, pre-flight and rewrite scans; an item under `.guardrails/` no longer silently shifts the next number | `finalize-ids.sh` |
| R31 | BOM detection moved from `head -c 3 \| od` (neither is POSIX `head`) into awk with octal escapes under `LC_ALL=C`, so the dependency list in `AGENTS.md`/`README.md` stays true | `lib.sh` |
| R32 | The required-document claim corrected to what it actually guarantees: *no gate is ever silently skipped*, not *every gate has every input*. `UNANALYZED-DERIVED` also reads `doc_rmf` and transitive `MISSING-TEST` also reads `doc_sad`, but both fail red without them, so requiring those keys would only forbid legitimate shapes (a class A project with no architecture document) | `lib.sh` |
| R33 | `sources:` wording corrected in `README.md` too — round 4 fixed the script and the skill and missed the README | `README.md` |
| R34 | The ratchet upgrade note became a table of every exit-2 cause an existing project can hit, including the closed prefix set, column-0 list items and the BOM, each with why it was never safe | `skills/ratchet/SKILL.md` |

### Evidence, mechanically derived

Three consecutive rounds shipped an overstated completeness claim about their
own evidence. That is the same defect this change exists to remove, turned on
the record instead of the tool, so the claim is now **derived, not asserted**:

```sh
# reproduce: run the CURRENT tests against the PRE-CHANGE scripts
mkdir baseaudit && cd baseaudit && cp -r <worktree>/tests <worktree>/templates .
mkdir scripts && for f in $(git ls-tree --name-only cb130db scripts/); do
    git show "cb130db:$f" > "$f"; done
tests/.bats-core/bin/bats tests/check-ids.bats tests/check-trace.bats \
    tests/finalize-ids.bats tests/lib.bats > baserun.txt
grep '^ok ' baserun.txt | sed 's/^ok [0-9]* //' | sort > base-pass.txt
# new-or-renamed test names, current suite minus cb130db's:
comm -23 cur-names.txt base-names.txt > new-names.txt
comm -12 new-names.txt base-pass.txt      # <- tests that cannot go red
```

Result: 124 tests now, 65 at `cb130db`, 60 new-or-renamed, **58/119 passing
against the pre-change scripts** (`check-signing.bats` excluded — it adds no
tests here and its `ssh-keygen` fixture stalls under repeated runs).

**Seven** new-or-renamed tests cannot go red against `cb130db`, not five:

| Test | Why it is kept |
|---|---|
| `comma lists, trailing commas and trailing prose all count` | Over-tightening guard: bites if `gr_id_run` is made too strict |
| `traces: counts a REQ anywhere in its list, not only first` | Regression test for a defect created *and* removed inside this change |
| `items inside their own document are not misplaced` | Negative guard for a gate that does not exist at baseline |
| `a strict path written as a glob still reaches the scan` | Characterization of behaviour unchanged since `cb130db` |
| `a config with a YAML document separator still parses` | Guard against the new line-shape validator over-rejecting |
| `same-day rename collision never overwrites an existing file` | Characterization; tied to no change here |
| `gr_doc_files on a missing key prints nothing, exit 0` | The renamed half of a pre-existing test, not a new one |

None is evidence that a pre-existing defect was fixed, and none is counted as
such.

Round-5 mutations, each cited by the test name it reddens:

- restore the per-name `[ -e ]` loop → `a pathspec matching a non-ASCII path is accepted`
- remove the `gr_doc_files` loop from finalize → `a doc key whose path is missing fails before anything is minted`
- revert `max_final` to `-- .` → `an ID defined under .guardrails does not shift the next number`
- remove the BOM check → `a config saved with a UTF-8 BOM is rejected, not half-read`

**These round-5 citations belong to the combined work, not to change A.** Two
of the tests they name (`a config saved with a UTF-8 BOM …`, and the
`gr_check_config` cases) left with change B and do not exist on change A's
branch. Change A's own mutation list is in the "Change A: mutation evidence"
section above; use that one when verifying change A.

### Known gaps, recorded rather than hidden

1. R3b's `git grep` status check has no test; its only reachable trigger is
   rejected upstream by prefix validation. The reviewer independently failed
   to construct one.
2. The seven tests above cannot go red against `cb130db`.
3. `gr_clean` strips a trailing ` # comment` silently and quoting is not
   honoured, so a `verify_commands` entry containing a whitespace-delimited
   token starting with `#` is truncated without a diagnostic. Recorded in
   `templates/config.yaml`.
4. `check-ids.sh` and `check-signing.sh` do not call `gr_check_config`, so a
   project with an unmanaged prefix passes `check-ids.sh` while
   `check-trace.sh` and `finalize-ids.sh` exit 2.
5. `gr_doc_files` reads a ledger directory one level deep; an item in a
   subdirectory of `doc_sad` is `MISPLACED-ITEM`. Documented, not changed.
6. `require_paths` discards `git ls-files`' status, so a pathspec git itself
   rejects (`:(bogus)tests`) is reported as "matches no file" — loud, but the
   wrong cause named.
7. `check-signing.sh` exits 0 having examined nothing on an empty rev range
   (`main..main`) and prints no denominator of its own. Untouched here and
   outside this change's scope; it is a live member of the same class and
   wants its own change.
8. Three behaviour changes carried no plan entry until now: `ids_matching`
   gained `-I` (annotations in git-binary files are no longer harvested),
   `finalize-ids.sh` sets `IFS` to newline, and its display loops moved out of
   pipeline subshells. None has a dedicated test.
9. **Environment, not the change:** `tests/check-signing.bats` stalls when
   `SSH_AUTH_SOCK` points at a wedged gnome-keyring agent — `ssh-keygen -Y sign`
   consults the agent even with `-f <keyfile>`, and reproduces outside the
   suite entirely. `scripts/check-signing.sh` and `tests/check-signing.bats`
   are untouched by this change (`git diff --stat main...HEAD --` on both is
   empty). Suite results below were taken with `SSH_AUTH_SOCK` unset. Making
   the fixture hermetic is a one-line change to that bats file and belongs in
   its own commit, not this one.

### Round 5 results

- Suite: **124 tests, all green** (65 → 77 → 98 → 112 → 121 → 124), with
  `SSH_AUTH_SOCK` unset per gap 9.
- Corpus regression on `sightings-app` at `b56e8aa8`, baseline and new scripts
  back-to-back on the same tree, read-only:

```
baseline exit=0 / new exit=0
diff: 7a8,9
> checked: REQ 101, HAZ 4, RC 10, SDD 26, LLR 33, PR 65
> sources: srs 19, rmf 7, sad 5, soup 1, problems 35; strict 5, tests 3
check-ids.sh exit=0        working tree clean
```

### The reviewer's scope judgement — for the maintainer to decide

The fourth reviewer's assessment, recorded verbatim in substance because it is
a decision this plan cannot make for itself:

> It is no longer one unit of work. The stated defects (F1, F2, F3a, F3b) plus
> the shell-correctness fixes that fell out of them (R8, R13, R16) are a
> coherent bugfix change of maybe 250 script lines. Bolted onto it are two
> features that are not defect fixes: a config schema validator
> (`gr_check_config`, ~75 lines, which changes the compatibility contract of
> every existing guardrails project), and `MISPLACED-ITEM`, a new user-visible
> traceability rule that in this project's own vocabulary is a REQ, not a PR
> fix.

Recommended split: keep F1/F2/F3a/F3b plus the subshell and
status-propagation fixes here; take the config schema validator out as its own
change with a migration note; take `MISPLACED-ITEM` out as its own change with
a requirement behind it.

The counter-argument, for the record: every one of those additions was written
in direct response to a reproduced false green in code this change already
touches, and each was found by a reviewer looking at this change. Splitting
means merging the earlier rounds knowing that `doc_rmff:` still disables the
hazard gate silently, which is the defect the change was opened to fix.

Both readings are defensible. This is a maintainer decision, not a technical
one, and the merge is held until it is made.
