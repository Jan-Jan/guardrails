# Assertion Gate Implementation Plan

**Goal:** reject an unguarded `[[ ]]` or `(( ))` assertion in a bats test body,
with a control that fails when the scan stops reading.
**Implements:** intended to resolve `PR-x4nb48`; it does not, and the item is
open (`docs/problems/2026-09-28-assertion-gate.md`).
This repository keeps no REQ/SDD ledger of its own, for the reason
`docs/problems/2026-08-27-macos-awk.md` gives, so the problem item is the
traced object.
**Safety class:** no `.guardrails/config.yaml` is in this repository; the class
B rules in `AGENTS.md` apply.
**Verification:** `sh tests/run-tests.sh`

## The defect

`PR-tenhv4` guarded 301 assertions so that a `[[ ]]` whose position in a test
body was the only reason it could fail would fail wherever it is written.
Nothing keeps them guarded. A later edit can drop one guard or add one
unguarded assertion, and no check reports it.

## Why the cut gate is not rewritten

`PR-x4nb48` records the evidence. Six revisions of a line-based awk scan
repaired sixteen defective or over-broad readings, round 4 found eight more,
and the tree contained a live blind spot: an unguarded assertion anywhere in
roughly lines 240 to 330 of `tests/check-ids.bats` was reported by nothing and
the scan exited 0.

Each of the sixteen was in one of five hand-written approximations of shell
lexing — a quote masker, a brace-depth counter, a command-position test, a
guard-segment reader and a heredoc recogniser. When one of those desynchronises
the scan reports nothing and exits 0. This plan removes all five and replaces
the assurance they were meant to give with an accounting check.

## This plan was not delivered

**The gate this plan specifies was built and then cut, and nothing in it merged
except this note and the record.** `PR-x4nb48` is open. Every path this document
names under `tests/` — `tests/assertion-guard.awk`,
`tests/fixtures/assertion-guard/defective.txt`, `tests/fixtures/assertion-guard/live.txt`,
the three tests in `tests/portability.bats` and the fourteen comment moves task
T1 specifies — is absent from the tree, and `tests/` is byte-identical to the
base. Read the `Implements:` line, the task list and every present-tense
sentence below as the specification the attempt started from.

Why it was cut, and what the attempt established, is in
`docs/verification/2026-09-29-assertion-gate.md` under "Why the gate is not
here". The fourteen comment moves T1 names by file and line are the one part a
third attempt can redo from this document directly.

## What this plan describes, and what was delivered

**The rule below is the one this plan specified, not the one that was built.**
Three review rounds replaced it. The delivered rule is in
`docs/verification/2026-09-29-assertion-gate.md` and in the header of
`tests/assertion-guard.awk`; the sections below are kept as the specification
the change started from, because the distance between them is the evidence.

Five spellings that this plan's rule accepts are inert and are rejected by the
delivered one: a guard that is not the last command, a guard block that cannot
fail, a guard reached after `return`, `continue`, `break` or `skip`, a guard
whose `echo` is chained to one of those by `&&`, and a guard whose separating
`;` is escaped so that `false` is an argument rather than a command. Each was
found by a reviewer or by the author after this plan was written.

Three further statements below are superseded. The break table has four rows
and asserts that the accounting misses the unterminated continuation; the
delivered scan detects it two ways, and the table in the record has six rows.
Task T3's third test is specified as asserting "no findings and a non-zero
`judged`", which is verbatim the weakness round 2 raised as this change's
`finding-12`. The fixture sizes given in T2 are twelve and nine; the fixtures
as finally built contained twenty-seven and fourteen spellings.

## The rule, as originally specified

A **logical line** is one or more physical lines joined while the line ends in
a backslash. That is the scan's only state, and it is recomputed from each
physical line's own last character rather than accumulated across a file.

A logical line is **exempt** when its first non-blank character is `#`. That
test is applied to the first physical line, before any joining, and a comment
ends the logical line: in shell a comment runs to the end of its line, and a
trailing backslash does not continue it. Joining first and testing afterwards
would apply the comment classification to a backslash-terminated comment and
the assertion below it together, which is a silent miss of the kind this change
exists to remove.

Two literal tokens are removed from a copy of the line before it is examined:
`$((`, which opens an arithmetic expansion, and `[[:`, which opens a POSIX
bracket expression. Both are string removals, not lexical rules.

If `[[` or `((` remains in that copy, the logical line contains an assertion,
and it must match one shape:

- exactly one opener, `[[` or `((`
- exactly one closer of the matching kind, `]]` or `))`
- the closer followed by optional blanks and `||`
- the line ending in `|| false` or in `; false; }`

Anything else is reported with its file, its first physical line number and a
reason. The rule rejects live spellings as well as inert ones — a `[[ ]]` that
is a test body's last command is live and is still reported. That is
deliberate. `PR-x4nb48` states the reason: a rule whose false positives are
visible is preferred here to a rule that reads shell more precisely and can
report nothing.

### Measured against the corpus

`tests/*.bats` excluding the vendored runner, at `70cd996`:

| | count |
|---|---|
| physical lines containing `[[` or `((` | 775 |
| logical lines judged | 755 |
| exempt, first non-blank character `#` | 6 |
| exempt, `$((` or `[[:` only | 14 |
| judged lines with exactly one opener and one closer | 755 of 755 |
| judged lines already matching the rule | 741 |
| judged lines failing only on a trailing comment | 14 |

Every one of the 775 is in exactly one row. No line in the corpus fails the
rule for any reason but a comment after the guard.

## The accounting check

The cut gate's blind spot was that a buffer was never flushed, so a hundred
lines were read and never judged. Reading every line is therefore not the
property to assert; **classifying** every line is.

The scan counts, per bucket, the physical lines containing `[[` or `((` that
the bucket accounts for. A logical line contributes its own physical lines to
whichever bucket it is classified into, at the point of classification. The
counts are printed on a summary line. `tests/portability.bats` then computes
the same total independently with `grep -c` and compares.

A buffer that is never flushed contributes to no bucket, so the sum is short
and the test fails and names the shortfall. A buffer that is flushed late, by
the end-of-file recovery, still contributes, so the accounting is silent about
that case and the recovery's own report is what fails the gate.

Measured, by breaking the scan four ways and running it over the real corpus:

| deliberate break | detected by |
|---|---|
| a bucket credited only outside lines 240 to 330 | `physical` 730, not 775 |
| a counter reset before classification | `physical` 6, not 775 |
| one file never read | `files` 12, not 13, and `physical` 712 |
| a continuation that never terminates | `UNTERMINATED-CONTINUATION` |

The accounting does not detect the fourth on its own: the end-of-file flush
credits the buffered lines, so the sum still reaches 775. The report of the
unterminated continuation is what fails the gate there.

A fifth break, the precise shape of the first attempt's `finding-30` (in
`docs/verification/2026-09-28-inert-assertions.md`) — a continuation that sticks
at `tests/check-ids.bats:236` and releases at `:340` — is detected by neither,
and is covered instead by a property of the rule. **A merged line is still reported.** The rule judges a whole logical line's shape rather than a
command's position, so a merged line inherits the defect: two openers is
`MULTIPLE-COMPOUND`, and a tail that is no longer a guard is `UNGUARDED`. The
only line that can be merged after an unguarded assertion without a finding is
one beginning `||`, which is a guard. Measured: with that break in place, an
unguarded assertion inserted at `:250` and at `:300` is still reported.

The cut gate had no such property, because it judged command position, and a
merged line loses the markers that test reads.

Three further controls, each of which closes a finding raised against the cut
gate:

- the number of files the scan read must equal the number `find` produced, and
  must be greater than zero (the first attempt's `finding-2` and `finding-10`)
- the scan's own exit status is read, not just its output (the same)
- a file that ends inside a continuation is reported rather than discarded

## Where the scan is in

`tests/assertion-guard.awk`, a file the scan never examines, because the
corpus is `*.bats`. The cut gate's awk source and its 24 control spellings were
inside `tests/portability.bats`, which the gate scanned: 63 of the 308 lines in
that measurement were the gate's own text, and the first attempt's
`finding-51` is the correction that followed.

Fixtures are `tests/fixtures/assertion-guard/defective.txt` and `live.txt`, for
the same reason and with no `-prune` exemption that would exclude a real test file.

## Tasks

### T1 — remove the trailing comment from 14 assertions

**Files touched:** `tests/check-review.bats`, `tests/check-trace.bats`,
`tests/check-units.bats`, `tests/units-chain.bats`
**Parallel:** yes

14 logical lines end in a comment after a complete guard. Accepting one means
reading a `#` as shell, which is the lexing this plan removes, and a comment
whose own text ends in `|| false` would satisfy the guard check while the
assertion it follows is inert.

Move each comment to its own line above the assertion, preserving its wording
and the file's 79-column wrap. Change nothing else on those lines.

The 14, by file and first physical line:

*(Code pruned at merge: 4 lines. Files touched: `tests/check-review.bats`, `tests/check-trace.bats`, `tests/check-units.bats`, `tests/units-chain.bats`.)*

Verify with the scan from T2 once both are merged; standalone, verify that
`git diff --stat` reports 14 lines changed to 28, that
`sh tests/run-tests.sh` still passes, and that no line's text changed other
than by moving the comment.

### T2 — the scan and its fixtures

**Files touched:** `tests/assertion-guard.awk`,
`tests/fixtures/assertion-guard/defective.txt`,
`tests/fixtures/assertion-guard/live.txt`
**Parallel:** yes

Write the scan to the rule above. It reads the files named in `ARGV`, prints
one line per finding as `<file>:<line>: <reason>: <text>`, prints a final
summary line, and exits 1 when it reported a finding and 0 otherwise.

Reasons: `MULTIPLE-COMPOUND`, `UNBALANCED`, `UNGUARDED`,
`UNTERMINATED-CONTINUATION`.

Summary line, exactly:

*(Code pruned at merge: 1 line. Files touched: `tests/assertion-guard.awk`, `tests/fixtures/assertion-guard/defective.txt`, `tests/fixtures/assertion-guard/live.txt`.)*

`physical` is the number of physical lines containing `[[` or `((` that were
classified into a bucket, and `judged + comment + token` must equal it.

No value containing a newline reaches `awk -v`; the scan takes no `-v` at all.
It must run under BWK awk, which `tests/portability.bats` already exercises.

`defective.txt` contains, one per line, every spelling the scan must report,
with the expected reason in a comment above each. At minimum: a bare `[[ ]]`;
`[[ ]];`; `[[ ]] && true`; `[[ ]] || true`; `[[ ]] || { echo "$output"; }`;
`[[ ]] || { echo "false alarm"; }`; `[[ ]]   # || false`; two assertions on one
line; `(( 1 == 2 ))` bare; a bare `[[ ]]` continued across a backslash with no
guard; and a file-final continuation.

`live.txt` contains every spelling the scan must not report: the canonical
guard; a custom-message guard; `|| false`; a backslash continuation into each
of those; `seen=$((seen + 1))`; a line containing `[[:space:]]`; and a comment
line whose prose names `[[ ]]`.

### T3 — the gate

**Files touched:** `tests/portability.bats`
**Parallel:** no (serial, after T1 and T2)

Three tests.

`@test "every bracket assertion in a bats test is guarded"` runs the scan over
the real corpus, asserts no findings, asserts the exit status, asserts the file
count against `find`, and asserts `physical` against an independent `grep -c`
sum over the same file list.

`@test "the assertion scan reports every defective spelling"` runs the scan
over `defective.txt` and asserts each expected line number appears with its
expected reason, and that the finding count equals the number of spellings.

`@test "the assertion scan reports no live spelling"` runs the scan over
`live.txt` and asserts no findings and a non-zero `judged`.

Each test contains `# verifies: PR-x4nb48`.

### T4 — the record

**Files touched:** `docs/problems/2026-09-28-assertion-gate.md`,
`docs/verification/2026-09-29-assertion-gate.md`
**Parallel:** no (serial, after T3)

`PR-x4nb48` to `status: resolved` with a one-line resolution naming the root
cause and the three tests. Write the verification record.

## What this change does not do

- It does not cover a `!`-negated command. `PR-7za3at` is open for that, and
  the rule that catches a negated command is not this one.
- It does not examine `tests/helpers.bash` or the `tests/*.sh` helpers, because
  the corpus is `*.bats`. Measured at `70cd996`: `tests/helpers.bash` and
  `tests/run-tests.sh` contain no `[[` and no `((` at all, and the three
  occurrences in `tests/evidence.sh:152`, `tests/mutate.sh:77` and
  `tests/mutate.sh:99` are arithmetic expansions rather than bracket
  compounds. They are therefore clean rather than repaired, and nothing here
  would report one that gained an assertion.
- It does not defeat an author who writes a comment ending in the guard text
  on a line that also contains a real `||`. The rule rejects the accidental
  regression it exists for; it is not an adversarial control.
