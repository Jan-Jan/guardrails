# ID Consistency Implementation Plan

**Goal:** Make every gate agree on what a definition line is, and make the
cross-branch duplicate gate keep the promise its own header already makes.
**Implements:** AC1–AC8 below. No SRS exists for this repository, so the
acceptance criteria *are* the requirement of record for this change.
**Safety class:** n/a — guardrails is tooling, not a medical device. Its
own analogue of class B is the mutation discipline in `tests/evidence.sh`:
every change must be shown to redden a named test.
**Verification:** `env -u SSH_AUTH_SOCK sh tests/run-tests.sh` — all green,
plus the reversal evidence recorded in `docs/verification/`.

## The two defects

Both were reproduced against `main` (`e63c1e5`) **before** any code was
written. Both are the same class: two pieces of the toolchain hold different
opinions about the same string.

### D1 — membership by space, in a newline-separated list

`check-ids.sh`'s cross-branch gate collects `added` and `removed` ID sets from
the diff, then suppresses an added ID that also appears in `removed` — this is
what lets a change relocate a definition between files. It tests membership
with `case " $removed " in *" $id "*`, but `sort -u` emits **newline**-separated
output, so only a single-element `removed` set can ever match.

Measured, in a throwaway repo:

| Change | `added` | `removed` | Result |
| --- | --- | --- | --- |
| relocate one definition | `PR-091` | `PR-091` | exit 0 — suppressed |
| relocate two definitions | `PR-090` `PR-091` | `PR-090` `PR-091` | **exit 1, both reported** |

Identical sets, opposite outcomes. The failure is a **false red** that blocks a
merge with no way forward but the hand-editing `merge-change` forbids — the
exact deadlock the comment three lines above it warns about. It is reachable by
any change that relocates two or more definitions: consolidating a ledger,
splitting one, or migrating a legacy anomaly log into `docs/problems/`.

`check-ids.sh`'s header already documents the behaviour the code fails to
deliver: *"A definition moved to another file in the same change is NOT flagged
(its old line shows as removed in the diff)."* This is a bug against stated
behaviour, not a change of mind.

`lib.sh` has carried the correct helper since change A: `gr_contains`, which
compares whole lines. `check-trace.sh` uses it. `check-ids.sh` hand-rolled its
own instead.

### D2 — one script, two definitions of "definition"

`finalize-ids.sh` anchors the scan that finds **drafts** (line 105:
`^\*\*${p}-DRAFT-…\*\*:`) and does not anchor the scan that finds **finals**
(`max_final`, lines 86 and 89). So a definition-form token anywhere on a line —
inside backticks, mid-sentence — raises the number the next change is minted
above, while `check-ids.sh` (`def_re`, anchored) and `check-trace.sh`
(`ids_defined`, anchored) both refuse to see it.

Measured: a base tree whose highest problem report is `PR-005`, plus one line of
prose reading ``The incident report noted `**PR-900**:` as the shape to avoid.``

```
check-ids.sh --allow-drafts     -> exit 0        (sees no definition)
finalize-ids.sh --dry-run       -> PR-DRAFT-feat-1 -> PR-901
```

The next real problem report is minted as `PR-901`. Nothing reports it.

`check-ids.sh:135` compounds this by telling the reader the two scans agree:
*"Same pathspec as finalize-ids.sh's max_final scan."* The pathspec does match.
The regex does not, and the sentence invites the assumption that it does.

## Acceptance criteria

- **AC1** The cross-branch duplicate gate must not report `DUPLICATE-ID` for an
  ID present in the removed set, whatever the size of that set.
- **AC2** It must still report an added ID that is *not* in the removed set.
  (AC1 must not be satisfiable by weakening the gate.)
- **AC3** A definition-form token that is not at line start must not raise the
  number `finalize-ids.sh` mints. With the D2 fixture the draft becomes
  `PR-006`.
- **AC4** All three shell gates agree, in both directions: a token at line start
  is a definition to `check-ids.sh`, `finalize-ids.sh` and `check-trace.sh`
  alike; a token that is indented or mid-line is a definition to none of them.
- **AC5** The shell-level definition regex is constructed in exactly one place
  (`lib.sh`) and used by all three scripts. A test fails if a hand-rolled copy
  reappears in `scripts/`. *(Amended after independent review: the test must
  match the definition **shape**, not one spelling of it, and must scan every
  script. Its first version passed against a copy written with different
  quoting — see the verification record, round 1, finding 1.)*
- **AC6** `check-trace.sh`'s awk-dialect definition patterns cannot share that
  constructor (awk ERE, no `{3,}`). They are instead pinned by test to agree
  with it on the cases that distinguish them.
- **AC7** Anchoring `max_final` narrows what counts as a definition, so a
  pre-existing off-column definition that used to hold the ceiling up would
  silently stop doing so and its number could be re-minted — invisibly, since
  every duplicate gate is anchored too. `check-ids.sh` therefore reports
  `UNANCHORED-DEF` for a definition-form token that is not at line start.
  *(Amended during execution: only tokens **above the highest real definition**
  of their prefix are reported. Reporting all of them gave nine lines of pure
  prose on the first real corpus and none that reserved anything — see
  docs/verification/2026-08-19-id-consistency.md, correction 4.)*
  It **reports without failing** — the token is legitimate prose in every case
  we have seen, and `SKIPPED-DUPLICATE-BASE` is the precedent for a line that
  informs rather than blocks.
- **AC10** *(added after independent review)* The ceiling `UNANCHORED-DEF`
  judges against is the one `finalize-ids.sh` mints from — the base ref and the
  worktree — not the worktree alone.
- **AC11** *(added after independent review)* A number is the digits after the
  last hyphen of an ID, so a prefix that carries a digit is not misread.
- **AC9** *(added during execution)* A definition line declares the ID at its
  start and no other. The diff harvest read every ID on the line as newly
  defined, so a problem report naming the requirement it affects was reported as
  a duplicate of that requirement.
- **AC8** The 146 tests on `main` stay green; no gate's exit status changes for
  any tree that does not contain an off-column definition-form token.

## Tasks

Each task is one RED → verify red → GREEN → verify green → commit cycle.
Worktree commits are unsigned: `git -c commit.gpgsign=false commit`.

### Task 1 — `gr_def_re`, the single constructor (AC5)

RED, in `tests/lib.bats`:

```bash
@test "gr_def_re anchors the definition form at line start" {
    run sh -c '. "$SCRIPTS/lib.sh"; gr_def_re "REQ|PR"'
    [ "$status" -eq 0 ]
    [ "$output" = '^\*\*(REQ|PR)-[0-9]{3,}\*\*:' ]
}

@test "gr_def_re takes a line prefix for diff scanning" {
    run sh -c '. "$SCRIPTS/lib.sh"; gr_def_re "PR" "+"'
    [ "$status" -eq 0 ]
    [ "$output" = '^\+\*\*(PR)-[0-9]{3,}\*\*:' ]
}
```

GREEN, in `scripts/lib.sh`, next to `gr_prefix_re`:

```sh
# gr_def_re ALTERNATION [POSITION] — ERE matching an item definition line.
#
# One constructor because three scripts must agree: check-ids.sh decides what
# is a duplicate, finalize-ids.sh decides what number comes next, and
# check-trace.sh decides what exists at all. When they disagreed, a token in
# prose raised the mint ceiling that neither gate could see (see
# docs/plans/2026-08-19-id-consistency.md, D2).
#
# POSITION is spliced in front and defaults to `^`. Pass '^\+' or '^-' for
# `git diff` output, and the empty string to match anywhere on a line.
gr_def_re() {
    printf '%s' "${2-^}\\*\\*(${1})-[0-9]{3,}\\*\\*:"
}

*(Amended during execution: the parameter was a LINE_PREFIX spliced after a
hardcoded `^` until the unanchored candidate scan needed a way to say
"anywhere"; `${2-^}` rather than `${2:-^}` so an empty string means what it
says. Independent review, finding 9.)*
```

### Task 2 — `check-ids.sh` adopts it (AC5)

RED: the AC5 lint test, in `tests/check-ids.bats`:

```bash
@test "no script hand-rolls the definition regex — gr_def_re is the only site" {
    cd "$BATS_TEST_DIRNAME/.."
    run grep -n '\*\\\*(\?\$\?{\?' scripts/check-ids.sh scripts/finalize-ids.sh
    offenders=$(grep -ln '\\\*\\\*.*\[0-9\]{3,}\\\*\\\*:' \
        scripts/check-ids.sh scripts/finalize-ids.sh scripts/check-trace.sh || true)
    [ -z "$offenders" ] || { echo "hand-rolled definition regex in: $offenders"; false; }
}
```

GREEN: replace `def_re="^\\*\\*(${P})-[0-9]{3,}\\*\\*:"` with
`def_re=$(gr_def_re "$P")`, and the two diff greps at 129/131 with
`$(gr_def_re "$P" '\+')` and `$(gr_def_re "$P" '-')`.

### Task 3 — the membership fix (AC1, AC2)

RED, in `tests/check-ids.bats`: build a repo whose base defines `PR-090` and
`PR-091` in two files, branch that relocates both into a third, and assert
`check-ids.sh --base main` exits 0 and prints no `DUPLICATE-ID`. The control
(AC2) is a second test where the branch defines a `PR-092` the base already
defines and removes nothing: still exit 1.

GREEN, in `scripts/check-ids.sh`:

```sh
    for id in $added; do
        # gr_contains, not `case " $removed "`: $removed is newline-separated,
        # so the space-delimited form only ever matched a single-element set —
        # relocating two definitions in one change reported both as duplicates
        # of themselves.
        gr_contains "$removed" "$id" && continue
```

### Task 4 — anchor `max_final` (AC3)

RED, in `tests/finalize-ids.bats`: the D2 fixture — base defining `PR-005`,
branch adding one line of prose containing a backticked `**PR-900**:` and one
draft. Assert `finalize-ids.sh --dry-run` prints `PR-DRAFT-…-1 -> PR-006`.

GREEN: `max_final` uses `$(gr_def_re "$_p")` for both the ref and worktree
scans. Note the output is fed to `grep -oE '[0-9]+'`, which is unaffected by
the anchor; only *which lines match* changes.

### Task 5 — `UNANCHORED-DEF` (AC7)

RED, in `tests/check-ids.bats`: a tree containing ``see `**PR-900**:` here``
makes `check-ids.sh` print `UNANCHORED-DEF` naming the file, and **exit 0**.
A second test: a normal tree prints no such line.

GREEN, in `scripts/check-ids.sh`, after the duplicate gates:

```sh
# --- UNANCHORED-DEF: definition form off column one (report, do not fail) ---
# Anchoring is what the gates agree on, so such a token defines nothing and is
# almost always prose. It is reported because it USED to raise finalize-ids.sh's
# mint ceiling: a project that relied on that, knowingly or not, must see the
# ceiling move rather than discover it as a re-minted number.
loose=$(git grep -nI --untracked -E "$(gr_def_re "$P" '.+')" \
        -- . ":(exclude).guardrails" 2>/dev/null || true)
[ -z "$loose" ] || printf '%s\n' "$loose" | sed 's/^/UNANCHORED-DEF /'
```

### Task 6 — cross-script agreement (AC4, AC6)

RED, in `tests/check-trace.bats`: one fixture carrying an item indented by two
spaces and a second carrying one mid-line. Assert `check-trace.sh` does not
count either as defined (`checked:` counts unchanged), `check-ids.sh` reports no
duplicate for them, and `finalize-ids.sh --dry-run` does not raise the ceiling
above them. This is one behaviour asserted across three scripts, which is what
AC4 says and what no single script's own tests can express.

For AC6, assert the awk patterns in `check-trace.sh` reject the same two shapes
by exercising the LLR and SDD block parsers with an indented header.

### Task 7 — correct the misleading comment, and record

`check-ids.sh:135`'s "Same pathspec as finalize-ids.sh's max_final scan" becomes
a statement of what is now true — same pathspec **and** same regex, both from
`gr_def_re` — and says why that matters. Update `README.md` if it describes the
definition form. Write `docs/verification/2026-08-19-id-consistency.md` with
suite totals, the mutation table, and the reversal evidence.

## Self-review

- Every AC has a task whose test asserts it: AC1/AC2 → T3, AC3 → T4, AC4 → T6,
  AC5 → T1+T2, AC6 → T6, AC7 → T5, AC8 → the whole suite at T7.
- The one risk this change introduces is named in AC7 and mitigated in T5.
- `gr_def_re`'s signature is fixed at T1 and used unchanged by T2 and T4.
