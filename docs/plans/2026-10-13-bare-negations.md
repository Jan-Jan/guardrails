# Bare negations Implementation Plan

**Goal:** Every negative assertion in the bats suite can fail its test, and a
portability check rejects a bare `!` statement that cannot.
**Implements:** none (guardrails keeps no REQ ledger of its own)
**Resolves:** PR-3kvpze
**Opens:** PR-z7jq9k
**Safety class:** not configured in this repository; worked as class B (both
normal and abnormal cases for the scan)
**Verification:** `tests/run-tests.sh`, all tests pass

## Investigation

Bash ignores errexit for a pipeline negated with `!`, so `! grep -q X f`
fails the test only where it is the test body's last command. A prototype
scan joins `\`-continued lines and skips heredoc bodies. It flags every
statement that opens with `!` and has no `|| false` or `|| {` list after it,
and finds 15 such statements at 1967dc8:

- Nine are dead because a command follows them:
  - `tests/finalize-docs.bats:215`
  - `tests/prune-plans.bats:589`
  - `tests/skills.bats:1055`, `1371`, `1408`, `1420`, `1421`, `1422` and `2357`
- Six are live, as the last line of their test:
  - `tests/prune-plans.bats:357`
  - `tests/skills.bats:1056`, `1197`, `1234`, `1423` and `1462`

The line numbers the item recorded (1400, 1412, 1414) had drifted, and
`tests/prune-plans.bats` was not in it. Each dead assertion's pattern was
checked against the tree: none matches today, so no regression was hidden.
The fix only makes them live.

## Decisions

- **D1: the rule bans every bare negation, the live ones included.** A last-line
  `! grep` works only until someone adds a line after it, and then it fails
  silently. That is exactly how 9 of the 15 died. A rule that allows the last
  line would need the scan to find the end of each test body; a rule that
  bans every bare negation needs only a line scan.
- **D2: an allowed negation ends in an `||` list whose last command fails.**
  The forms are `! cmd || { echo "<what matched>"; false; }` (the house
  style, as in `tests/prune-plans.bats`) and `if cmd; then false; fi`.
  `run ! cmd` is not used: it needs bats 1.5 and a follow-up status
  assertion.
- **D3: the check lives in `tests/portability.bats`**, beside the case-pattern
  scan whose file-gathering it copies. AGENTS.md "Rules" gains one bullet
  that names the check.

## Tasks

### T1 — scan for bare negations, and convert the fifteen

**Files touched:** tests/portability.bats, tests/skills.bats,
tests/finalize-docs.bats, tests/prune-plans.bats, AGENTS.md,
docs/problems/2026-10-08-bare-negations.md
**Parallel:** no (single task)

1. RED: in `tests/portability.bats`, after the case-pattern test, add
   `@test "no test asserts through a bare negation"` with
   `# verifies: PR-3kvpze`. It writes an awk scan to `$BATS_TEST_TMPDIR`
   that does the following:
   - Joins lines that end in `\`.
   - Skips heredoc bodies, opened by `<<TAG`, `<<'TAG'` or `<<-TAG` and
     closed by a line that is the tag after leading blanks are trimmed.
   - Prints `FILE:LINE: statement` for each statement that opens (after
     blanks) with `!` followed by a blank and does not match
     `\|\|[ \t]*(false|\{)`.

   The scan must run on BWK awk: no `-v` with newlines and no gawk
   extensions.

   Controls, written as fixtures under `$BATS_TEST_TMPDIR`, as in the case
   test. The scan must flag three bad shapes:
   - `! grep -q x f` followed by another command;
   - the same command split across lines with `\`;
   - a negated pipeline `! a | grep -q x`.

   It must pass four good shapes:
   - `! grep -q x f || { echo hit; false; }`;
   - `! grep -q x f || false`;
   - the `\`-continued form with `|| {` on the continuation line;
   - a `! grep` line inside a heredoc.

   It then scans `tests/*.bats` and `tests/*.bash` and asserts the output
   is empty. (The deslop pass, 06e7e4d, replaced the case test's
   search-path guard and partial-checkout skip with direct globs on
   `$BATS_TEST_DIRNAME`. Those globs always match, because the test file
   itself is one of them.) Lines failing it are printed under
   `bare negations (errexit ignores them):`.
2. Watch it fail on the real tree, listing the 15 statements above. The
   controls pass.
3. GREEN: convert each of the 15 to D2's form. Where the file already uses
   the diagnostic `|| { …; false; }` form, use it with a message that names
   what matched; otherwise append ` || false`. Keep each assertion's meaning
   unchanged.
4. Prove that the converted assertions bite. Temporarily add the text
   `outside the verification record` to `templates/verification.md` and run
   `tests/skills.bats`; the template test must now fail. Revert it. Do the
   same for one `prune-plans.bats` conversion: break its fixture expectation
   and watch it fail. Record both checks in `surprises:`.
5. AGENTS.md "Rules": add, after the `case` bullet, "Never write a bats
   assertion as a bare `! cmd`: bash's errexit ignores a negated command, so
   it fails the test only as the body's last line. End it in an `||` list
   that fails (`! cmd || { echo …; false; }`), or write
   `if cmd; then false; fi`. `tests/portability.bats` enforces this."
6. In `docs/problems/2026-10-08-bare-negations.md`, change `affects:` to
   `tests/skills.bats, tests/finalize-docs.bats, tests/prune-plans.bats.`,
   set `status: resolved`, and add a resolution line. 00fd551 wrote it in
   the ledger's existing `Resolved:` form; the wording first planned was
   `resolution: errexit skips a negated command; the 15 bare negations end in a failing || list, and portability.bats "no test asserts through a bare negation" rejects new ones.`
7. Run `tests/portability.bats`, `tests/skills.bats`, `tests/prune-plans.bats`
   and `tests/finalize-docs.bats` one at a time with `tests/run-tests.sh <file>`.
   All must pass.

**Done** (20a7135, merged e5a6604). Both bite probes failed as intended: the
template phrase failed the skills.bats template test, and `echo unclosed`
failed `prune: a fence with no closing line is kept`.

```
red -> green: no test asserts through a bare negation — watched fail for the right reason before the implementation existed (controls passed; the tree scan listed the 15 statements above)
```

### T2 — the scan accepts only an `||` list that fails

**Files touched:** tests/portability.bats
**Parallel:** no (serial, after T1)

The guideline review noted that the T1 scan accepts any `|| {`, so
`! grep -q x f || { echo hit; }` passes the scan and still checks nothing:
the brace group exits 0. The scan must accept a negation only where the
`||` list's last command is `false`. That means one of three forms:
- `|| false` at the end of the statement;
- a one-line brace group whose last command is `false`;
- a brace group that opens at the end of the line and spans several lines,
  read up to its closing `}`, whose last command before the `}` is `false`.

1. RED: add bad controls to `no test asserts through a bare negation`:
   `! grep -q x f || { echo hit; }`, and the multi-line form whose last line
   before the `}` is `echo hit`. Watch the test fail on them.
2. GREEN: tighten the awk scan until both are flagged. Every existing good
   control, and the real tree, must still pass. Use BWK-compatible awk only.
3. Run `tests/run-tests.sh tests/portability.bats`.

**Done** (8bbef4e). Both new bad shapes were also confirmed flagged under
BWK awk 20200816 directly, because the controls loop stops at its first miss.

```
red -> green: no test asserts through a bare negation — watched fail for the right reason ("the scan misses the unfailing-braced shape") before the scan was tightened
```

### T3 — review round 1: the scan sees every statement it should

**Files touched:** tests/portability.bats, AGENTS.md
**Parallel:** no (serial, after T2)

Review round 1 (step 6a, at ae58d34) found four things:

- **finding-1 (high).** The scan opens a heredoc on any `<<WORD`, including
  one inside a quoted string, in a comment, or in `$((x<<y))`. A heredoc
  opened that way never closes, so the rest of the file goes unscanned. The
  `cat <<-EOF` text in the test's own fixture `printf` hides lines 627 to the
  end of `tests/portability.bats`.
- **finding-2 (low).** A `!` that follows `;`, `&&`, `||`, `then`, `do`,
  `else` or `{` is ignored by errexit in the same way, and the scan does not
  look for it.
- **finding-3 (low).** Two shapes are missed:
  - a multi-line group whose closing `}` shares a line with `false;` is never
    seen to close;
  - a statement held by a trailing `\` at the end of a file is never checked.
- **finding-5 (record).** AGENTS.md's "enforces this" claim is broader than
  the scan delivers.

1. RED: add controls, each watched fail before the scan changes. Three are
   fixtures in which a bare `! grep -q x f` mid-test, after the line named,
   must still be flagged:
   - a line with `<<EOF` inside single quotes;
   - one with `<<EOF` inside double quotes;
   - a comment containing `cat <<EOF`.

   And four more:
   - a line using `$((x<<2))`, then the same bare negation, which must be
     flagged;
   - a here-string `<<<"$x"`, which opens no heredoc, then the bare
     negation, which must be flagged;
   - bad mid-line forms, each flagged: `true; ! grep -q x f`,
     `true && ! grep -q x f`, `if true; then ! grep -q x f; fi`, and
     `for i in 1; do ! grep -q x f; done`;
   - good forms, each passed:
     - `if ! grep -q x f; then false; fi`;
     - `while ! grep -q x f; do break; done`;
     - `( ! grep -q x f )`;
     - `[ ! -f f ]`;
     - `[[ ! -f f ]]`;
     - a multi-line `|| {` group closed by `echo hit; false; }`, followed
       by a bare negation, which must be flagged;
     - a file whose last line ends in `\` after `! grep -q x f`, which
       must be flagged.
2. GREEN: before looking for `<<` or `!`, the scan removes single- and
   double-quoted text, `$((…))` and an unquoted `#` comment from its working
   copy of the statement. It treats `<<<` as no heredoc. It flags a `!`
   followed by a blank when the `!` comes after `;`, `&&`, `||`, `then`,
   `do`, `else` or `{`. Such a mid-line `!` has no allowed form. A
   multi-line group closes on a line whose text ends in `}`, and its last
   command is what precedes that `}`. A statement still held at end of file
   is checked. Use BWK-compatible awk only. The real tree must stay clean.
3. AGENTS.md: state the scope, so that the bullet says a bare negation at the
   start of a statement, or after `;`, `&&`, `||`, `then`, `do`, `else` or
   `{`, is rejected.
4. Run `tests/run-tests.sh tests/portability.bats`.

**Done** (bd6fee9). The extracted old scan, run under BWK awk 20200816,
missed all ten bad controls that can fail. Two plan controls had to change:
- `$((x<<2))` could not fail against the old scan, so the control uses the
  review's `$((x<<y))`;
- `<<<"$x"` was already ignored by the old scan, so it stays as a regression
  guard and was never watched red.

As a probe, a bare negation appended at the end of `tests/portability.bats`
was flagged, then removed. The new scan leaves no file open in a heredoc or
group.

```
red -> green: no test asserts through a bare negation — watched fail for the right reason ("the scan misreports the single-quoted-heredoc shape") before the scan read only code
```

### T4 — review round 2: a file the scan cannot finish fails loudly

**Files touched:** tests/portability.bats, AGENTS.md
**Parallel:** no (serial, after T3)

Review round 2 (at 0aaa84b) found five things:

- **finding-1 (medium).** No control puts a bare `!` after a heredoc that
  closes. So a scan that never closes a heredoc passes the test, and reads
  nothing after the first heredoc in each file.
- **finding-2 (low).** Some shapes open a heredoc or group that never closes:
  - `"$(echo "a <<EOF")"`;
  - `$'it\'s <<EOF'`;
  - a multi-line single-quoted string that contains `<<EOF`;
  - `(( x << y ))`;
  - a tag such as `END-X`;
  - a group closed by `} >&2`;
  - a comment that ends in `\`.

  Some shapes are accepted that check nothing:
  - a group that contains an inner one-line group;
  - `|| echo hit || false`;
  - `true & ! cmd`;
  - a group left open at the end of the file.
- **finding-3 (low).** Removing any of these rules leaves the test green:
  - escape handling;
  - the comment-start precondition;
  - the `<<<` branch, which is dead;
  - opening a heredoc from inside a group;
  - the `FNR == 1` flush and resets;
  - the literal-`false` requirement.
- **finding-4 (record).** The plan does not record the guideline review.
- **finding-5 (record).** The AGENTS.md bullet says "an `||` list that
  fails", but the scan requires the last command to be `false`.

1. RED: add controls, each watched fail before the scan changes:
   - bad: a bare `! grep -q x f` after a closed `cat <<'EOF'` … `EOF`, and
     after a closed `<<-EOF` heredoc, each reported at its own line;
   - bad: a file that ends inside an unclosed heredoc, and one that ends
     inside an unclosed `|| {` group, each reported as unclosed, with its
     opening line;
   - bad: `! grep -q x f || true`, `! grep -q x f || { echo hit; true; }`,
     `! grep -q x f || echo hit || false`, and `true & ! grep -q x f`;
   - bad: a multi-line group that contains an inner
     `x || { echo; false; }` and ends in `echo hit`;
   - good: a group closed by `} >&2`; a heredoc tag `END-X`; `(( x << y ))`
     followed by a bare negation, which must be flagged at its line;
   - bad: a comment line ending in `\` followed by a bare negation, which
     must be flagged;
   - controls that kill each finding-3 survivor still in the scan.
2. GREEN:
   - At the start of each file and at `END`, report a heredoc or group still
     open, as `FILE:LINE: unclosed heredoc <<TAG` or
     `FILE:LINE: unclosed || { group`. This makes every
     "hides the rest of the file" case loud.
   - Read a heredoc tag up to a blank, quote or `;`.
   - Strip `((…))` as well as `$((…))`.
   - Decide continuation on the line's code, after its comment is removed.
   - Close a multi-line group when its count of `{` and `}` in code returns
     to zero; its last command is the command before that `}`.
   - Accept a negation only where its statement's code has exactly one
     `||`.
   - Add `&` to the mid-line separators.
   - Delete the dead `<<<` branch, or give it a control that kills it.
   - Keep to BWK-compatible awk; the real tree must stay clean.
3. AGENTS.md: say the list's last command must be `false`.
4. Run `tests/run-tests.sh tests/portability.bats`.

**Done** (7aeae4c). The test gained 33 controls. Each one states the scan's
whole report, and all of them run before any miss is reported. Against the old
scan, 14 controls failed.

The other 19 kill mutants and could not be watched red. Each was confirmed
against a mutant instead. Of the 45 one-rule mutants of the scan, all 45 were
killed.

Three shapes are now reported loudly as unclosed, where they were silently
dropped before:
- `"$(echo "a <<EOF")"`;
- `$'it\'s <<EOF'`;
- a multi-line single-quoted string that contains `<<EOF`.

The dead `<<<` branch is deleted. A bare negation appended at the end of each of
the 26 test files was flagged in all 26.

```
red -> green: no test asserts through a bare negation — watched fail for the right reason ("the scan misreports:", 14 controls) before the scan reported unclosed files
```

### T5 — review round 3: pin the three surviving mutants

**Files touched:** tests/portability.bats
**Parallel:** no (serial, after T4)

Review round 3, at `dc173d6`, was the last round: every finding was low. Its
finding-3 named three one-rule mutants of the scan that no control kills. The
scan is already right for each, so the fix adds controls and does not change
the scan:
- a single quote left open at the end of its line;
- two heredocs opened on one line, `cat <<A <<B`, where the first tag must be
  the one awaited;
- a multi-line `|| {` group whose last line is `echo false`, which must be
  flagged.

Findings 1 and 2 change what the scan accepts and rejects. They are not
mechanical, so they are recorded as PR-z7jq9k. Finding-4, the missing
outcome of guideline review round 2, is recorded above.

1. Add the three controls. Watch each one fail against its mutant, then pass
   against the scan.
2. Run `tests/run-tests.sh tests/portability.bats`.

**Done** (e760b6c). Three controls were added: `two-heredocs`, `open-quote`
and `block-echo-false`. Each was applied with sed to a scratch copy.

| Mutant | Change | Result before | Result after |
| --- | --- | --- | --- |
| M1 | delete the end-of-line quote close | survived | killed by `open-quote` |
| M2 | let the last heredoc tag win | survived | killed by `two-heredocs` |
| M3 | accept any `…false` as a group's last command | survived | killed by `block-echo-false` |

Each control passes against the real scan.

```
red -> green: no test asserts through a bare negation — watched fail against each of mutants M1, M2 and M3 (controls for behavior the scan already had), then pass against the scan
```

## Guideline reviews

`guidelines-file.sh TEST` names `docs/TEST_GUIDELINES.md` for every test
path in the diff. Round 1 ran after T1 and the deslop pass, at `00fd551`,
over `tests/portability.bats`, `tests/skills.bats`, `tests/prune-plans.bats`
and `tests/finalize-docs.bats`. It found nothing. Its one note became T2:
the scan accepted `|| { echo hit; }`. Round 2 ran after T4, at `dc173d6`, over the same four paths. It found
nothing and wrote four notes:
- each repaired assertion sits in a test already at its seam, so Existing
  suites 1 allows repairing it in place;
- the lint test runs no script, which Seams 1 does not address;
- a property test would be possible but is only preferred (Property tests 1);
- whether the new test was watched red is the record's to show.

## After the tasks

Deslop pass, guideline review against `docs/TEST_GUIDELINES.md`, then
`verify-before-merge` and `merge-change`.
