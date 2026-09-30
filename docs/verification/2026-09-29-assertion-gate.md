# Verification — assertion-gate (2026-09-29)

branch: assertion-gate
reviewer: five independent subagents, one per round, each dispatched at
`merge-change` step 6a with the diff, the plan and the item, and no account of
how the change was built. Each executed the suite in its own task worktree and
re-measured every figure rather than accepting one. Round 4 was told that its
answer to the first question would decide whether the change merged or was
abandoned, so that it would search harder rather than assume a verdict. Round 5
reviewed the cut tree and executed the suite there to completion, so the gate
table's first row is confirmed by a second party rather than resting on this
change's own summary, which step 6a would have permitted for a
documentation-only diff.
verdict: five rounds raised forty-one findings. The first four rejected the
change. Six spellings that are inert under bats were accepted by the rule in
turn, and each repair closed the spelling it was shown rather than the class
behind it. On round 4's sixth, the maintainer's standing ruling took effect and
the gate was cut from this change. Round 5, against the cut tree, raised no
`code` and no `requirement` finding and is the last round: it confirmed the
removal surgical by tree and per-blob identity, re-measured 749 of 749 exit 0
from its own run, and raised nine record findings,
all corrected, one of which — the sixth spelling transcribed with one backslash
instead of two — would have told a third attempt that the cut was mistaken.
What merges is the record of what the attempt established and what it did not,
and `PR-x4nb48` is open again.
reproduced: yes, and the reproductions are the evidence this change keeps. Six
spellings were each measured inert under the vendored bats before repair, by
running them as a test body and watching bats report `ok` where the canonical
guard reports `not ok`. The scan's reading of the corpus was measured on four
trees: an unguarded assertion inserted at each of the 12,020 lines of the 13
corpus files was reported at every one, and a guard stripped from each of the
620 single-line bracket assertions was reported every time.

Change: a gate to reject an unguarded `[[ ]]` or `(( ))` assertion in a bats
test body was built and cut. What merges is this record, the plan, and
`PR-x4nb48` returned to `open` with four rounds of evidence. No `.bats` file
differs from the base, and no file under `tests/` is added or removed.
Branched from `main` at `70cd996`; base `ff6bb34` merged in at step 1.
Plan: `docs/plans/2026-09-29-assertion-gate.md`.

## Read this first: most of this record describes code that is not here

This change built a gate and cut it. **Every section below except "The gate"
describes a scan, three tests and two fixtures that are absent from the merge
candidate**, and many of them are written in the present tense, because they
were written while that code was in the tree. `tests/assertion-guard.awk` and
`tests/fixtures/assertion-guard/` do not exist at HEAD, no `.bats` file differs
from the base, and the three tests named in "Red → green" are not in the suite.

Read every figure outside "The gate" as a measurement of the attempt, on a tree
named beside it, and not as a description of what merges. "Why the gate is not
here" states what the attempt established and why it was stopped.

## The gate

Measured on: `66c2f5f` — `git rev-parse HEAD` — tree `6885db7`, from
`git rev-parse HEAD^{tree}` on a clean worktree that was clean before, during
and after the run. `merge-change` step 3 renamed nothing. The commits after it
touch `docs/verification/` alone — this paragraph, the rows below, and one
wording repair — and no test reads that directory: `tests/skills.bats` names it
out of the writing scan's scope by its complement, and nothing else opens it.
So the suite row below describes the tree that merges, and that is checkable
rather than assumed: `git diff --name-only 66c2f5f..HEAD` names one file.

The diff is documentation alone. `git diff --name-only main..assertion-gate`
names three files, all under `docs/`, and `git rev-parse HEAD:tests` equals
`git rev-parse ff6bb34:tests` — the gate this change built was removed, and
every `.bats` file is the base's.

This repository does not self-host its own gates: the tree has no
`.guardrails/config.yaml`. The two check scripts were run against a scratch copy
with a synthesized config, built with `git archive` rather than a copy of the
worktree, and the same was done at the merged base `ff6bb34`. The synthesized
config is `templates/config.yaml` with its comments and blank lines removed and
its one `strict_paths` entry changed from `src` to `scripts`, plus placeholder
`docs/requirements`, `docs/risk` and `docs/architecture` directories, each
containing one `.md` file, and a one-line `docs/architecture/soup.md`. The copy
is then `git init`ed and committed. Every one of those steps is needed: without
the commit both scripts exit 2 at `not inside a git repository`; without
`soup.md` `check-trace.sh` exits 2 at `doc_soup … does not exist`; and with the
three directories present but empty it exits 2 at `doc_srs is configured as
directory 'docs/requirements', which contains no *.md files`. In each case it
reads nothing. `id_prefixes` is `REQ HAZ RC SDD LLR PR`. "The base"
means the merged base `ff6bb34`, not the branch point `70cd996`, against which
three extra `UNRESOLVED-PR` verdicts appear and these rows do not reproduce.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | 749 of 749, 0 failures, exit 0, on a worktree that was clean before, during and after the run. Round 5 executed it independently in its own worktree to the same figure. The TAP plan is `1..749`; there is no `X tests, Y failures` line, because the runner passes no formatter and bats emits raw TAP with no tty. Three fewer than the revision that contained the gate, which is the three tests it added |
| `check-ids.sh` | exit 1 at the base and at the change alike, 67 verdict lines both sides, output byte-identical |
| `check-trace.sh` | exit 1 at the base and at the change alike, output byte-identical. This change adds and removes no ID: `PR-x4nb48` was open at the base and is open at the change |
| Coverage, against the class target | not measured; this change adds no requirement and no production code |
| Working tree | clean at the commit above |

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| `PR-x4nb48` | `every bracket assertion in a bats test is guarded` | yes, twice. An unguarded `[[ "$output" == B ]]` added at `tests/lib.bats:54` was reported by file, line and reason. Separately, crediting `judged_lines` only outside lines 240 to 330 failed the accounting assertion with "the scan classified 797 physical lines, grep counted 807" while the finding assertion still passed — the control fails on the count, not on the findings. Re-measured after round 2's repairs, a path returning before the rule is applied fails the same assertion with "the scan classified 792 physical lines, grep counted 802" |
| `PR-x4nb48` | `the assertion scan reports every defective spelling` | yes. Removing the `UNBALANCED` report from the scan failed it with "expected UNBALANCED at line 43, matched 0 lines" |
| `PR-x4nb48` | `the assertion scan reports no live spelling` | yes. Making the bare-guard pattern unmatchable failed it with "the scan reported a live spelling: …live.txt:12: UNGUARDED: [[ "$output" == *x* ]] \|\| false" |

## What was wrong, and what was built

`PR-tenhv4` guarded 301 assertions so that a `[[ ]]` whose position in a test
body was the only reason it could fail would fail wherever it is written. It
delivered no gate, so a later edit could drop a guard or add an unguarded
assertion with nothing reporting it.

A gate was written during that change and cut from it. `PR-x4nb48` records why:
six revisions of a line-based awk scan repaired sixteen defective or over-broad
readings, round 4 found eight more, and the tree contained a blind spot in
which an unguarded assertion anywhere in roughly lines 240 to 330 of
`tests/check-ids.bats` was reported by nothing while the scan exited 0. Each of
the sixteen was in one of five hand-written approximations of shell lexing — a
quote masker, a brace-depth counter, a command-position test, a guard-segment
reader and a heredoc recogniser.

This change removes all five. The rule is applied to a whole logical line's
shape rather than to a command's position:

- a logical line is physical lines joined while the line ends in a backslash,
  which is the only state the scan keeps, and it is recomputed from each
  physical line's own last character
- a logical line whose first physical line opens with `#` is a comment, and a
  backslash at the end of that line does not continue it, because a shell
  comment ends at the end of its physical line
- the literals `$((` and `[[:` are removed from a copy of the line before it is
  examined, which are string removals rather than lexical rules
- what remains must have exactly one opener, exactly one matching closer, `||`
  directly after that closer, and an ending of `|| false` or `; false; }`

The rule reports live spellings as well as inert ones. A `[[ ]]` written as a
test body's last command can fail where it is written and is still reported.
`PR-x4nb48` states the reason to prefer that: a rule whose false positives are
visible is preferred here to a rule that reads shell more precisely and can
report nothing.

### The corpus, measured at `70cd996`

| | count |
|---|---|
| physical lines containing `[[` or `((` | 775 |
| logical lines judged | 755 |
| exempt, first non-blank character `#` | 6 |
| exempt, `$((` or `[[:` only | 14 |
| judged lines with exactly one opener and one closer | 755 of 755 |
| judged lines already matching the rule | 741 |
| judged lines failing only on a trailing comment | 14 |

Every one of the 775 is in exactly one row. No line in the corpus failed the
rule for any reason but a comment after the guard, and task T1 moved those 14
comments to the line above. Accepting a trailing comment would require reading
a `#` as shell, and a comment whose own text ends in `|| false` would satisfy
the guard check while the assertion it follows is inert.

### The blind-spot measurement

An unguarded assertion was inserted at every line of every corpus file in turn,
and the scan's finding count compared against the same file without it. Measured
on the gate trees, not on the merge candidate: twelve of the thirteen files at
`83ab159` and `tests/portability.bats` at `7b29d9b`, after it gained two
comment lines. 12,020 insertion points, 13 files, none silent. The per-file
line counts below are those trees' and are larger than the merge candidate's,
which contains neither the three gate tests nor the fourteen comment moves —
`tests/portability.bats` is 636 lines there and 425 here.
No such sweep was run on the merge candidate, and none could be: the scan it
measures is not in that tree. Three earlier revisions of this paragraph asserted
a tree identity that was false when written, twice caught by review and once by
the author; the identity claims are removed rather than restated, and the trees
are named instead.

| file | lines | silent |
|---|---|---|
| `tests/check-ids.bats` | 818 | 0 |
| `tests/check-review.bats` | 899 | 0 |
| `tests/check-signing.bats` | 498 | 0 |
| `tests/check-trace.bats` | 3822 | 0 |
| `tests/check-units.bats` | 352 | 0 |
| `tests/finalize-docs.bats` | 559 | 0 |
| `tests/finish-merge.bats` | 746 | 0 |
| `tests/lib.bats` | 1334 | 0 |
| `tests/mutations.bats` | 156 | 0 |
| `tests/new-id.bats` | 271 | 0 |
| `tests/portability.bats` | 636 | 0 |
| `tests/skills.bats` | 1806 | 0 |
| `tests/units-chain.bats` | 123 | 0 |

The gate this change replaces was measured the same way at eight sampled lines
of one file and was silent at four of them.

### The other regression mode

Inserting an assertion is one way the guards can be undone; deleting a guard
from an assertion that has one is the other, and it is the way `650f090`
undid two of them during the change that first recorded the defect. The guard
was stripped from each single-line bracket assertion in turn — 620 of the 771
judged logical lines, the other 151 being continuations whose
guard is on the following physical line and which the insertion sweep above
already covers — and the scan's finding count compared against the same file
with the guard in place:

| file | bracket guards | silent |
|---|---|---|
| `tests/check-ids.bats` | 46 | 0 |
| `tests/check-review.bats` | 61 | 0 |
| `tests/check-signing.bats` | 25 | 0 |
| `tests/check-trace.bats` | 310 | 0 |
| `tests/check-units.bats` | 30 | 0 |
| `tests/finalize-docs.bats` | 22 | 0 |
| `tests/finish-merge.bats` | 6 | 0 |
| `tests/lib.bats` | 71 | 0 |
| `tests/mutations.bats` | 10 | 0 |
| `tests/new-id.bats` | 21 | 0 |
| `tests/portability.bats` | 5 | 0 |
| `tests/units-chain.bats` | 13 | 0 |

Every one is reported.

### What each deliberate break is detected by

The scan was broken six ways and run over the real corpus, where clean it
reports `files=13 physical=802 judged=771 comment=6 token=25 findings=0`:

| deliberate break | detected by |
|---|---|
| a bucket credited only outside one line range | `physical` 757, not 802 |
| a counter reset before classification | `physical` 6, not 802 |
| one file never read | `files` 12 and `physical` 739 |
| a continuation that never terminates | `comment` 0 and `token` 0, not 6 and 25, and 13 `UNTERMINATED-CONTINUATION` reports |
| a path that returns before the rule is applied | `physical` 792 and `judged` 761 |
| a continuation that sticks at `check-ids.bats:236` and releases at `:340` | the rule itself: an unguarded assertion at `:250`, `:300` and `:320` is still reported |

Five of the six are detected by the counts. The sixth is not, and what covers
it is a property of the rule rather than a control around it.

**A merged line is still reported.** The rule judges a whole logical line's
shape, so a merged line inherits the defect: two openers is
`MULTIPLE-COMPOUND`, and a tail that is no longer a guard is `UNGUARDED`. The
only line that can be merged after an unguarded assertion without producing a
finding is one beginning `||`, which is a guard. Measured with that break in
place: an unguarded assertion inserted at `:250`, `:300` and `:320` is reported
at every one.

The cut gate had no such property, because it judged command position, and a
merged line loses the markers that test reads. That difference, rather than the
accounting, is the reason this rule is the safer one.

The fourth row changed between rounds. Until round 2's repair the accounting
did not detect it: the end-of-file recovery credited the buffered lines, so the
sum still reached the grep total, and only the `UNTERMINATED-CONTINUATION`
report failed the gate. Crediting each bucket at the verdict rather than on
entry made the bucket counts collapse as well, so that break is now caught two
ways.

### Whether the guard rule is closed

Five inert spellings were accepted and repaired across three rounds, each
repair closing the spellings it named rather than the class. The current rule is the first written as a claim that can be falsified rather than as a list:

> `;`, `&` and `|` are the only characters that can put another command before
> `false` on one physical line of a brace guard. A `$( )`, a backquote or a
> process substitution cannot, because each runs in a subshell.

Both halves were measured. Under the vendored bats, with `run true` and an
assertion against `-eq 99`, these four are inert and every one is reported:

    || { echo "$output" && return; false; }
    || { echo "$output" || return 0; false; }
    || { echo "$output" && continue; false; }
    || { echo "$output" && break; false; }

The `>&` redirection is admitted as the one exception to the `&` restriction,
and it opens nothing: `|| { echo x >&2 && return; false; }` and
`|| { printf '%s' x >&2 && break; false; }` are both inert and both reported,
as is `|| { echo a; echo b && return; false; }`, where only the second command
is chained.

These three are live — each fails the test as written — and each is accepted:

    || { echo x $(return 1); false; }
    || { echo x `return 1`; false; }
    || { echo x <(true); false; }

The rule's cost is the mirror of its restriction: a diagnostic whose own text
names `&&`, `||` or `;` is reported, because separating a quoted operator from
a real one needs the quoting read. `|| { echo "a;b"; false; }` is live and is
reported. That cost is in `Gaps`.

What no round has established is that the list of three characters is
complete. It is an argument about shell rather than a measurement, and the
measurement behind it is one shell on one machine.

### Where the scan is in

`tests/assertion-guard.awk` is not a `.bats` file, so the corpus never contains
it. The fixtures are `tests/fixtures/assertion-guard/defective.txt` and
`live.txt`, `.txt` for the same reason and with no `-prune` exemption that
would exclude a real test file. The cut gate's awk source and its 24 control spellings were inside
`tests/portability.bats`, which that gate scanned: 63 of the 308 lines in its
own corpus measurement were its own text, which is the correction recorded as `finding-51`
of `docs/verification/2026-09-28-inert-assertions.md`, the FIRST attempt's
record. Findings cited without a file belong to this record.

## Why the gate is not here

This change built a gate and removed it before merge, on the maintainer's
standing ruling: one more review round after round 3, and a cut rather than a
fifth repair if a sixth inert spelling appeared. Round 4 found one.

The sequence is the finding. Six spellings that bats reports `ok` for, where the
canonical guard reports `not ok`, were accepted by the rule in turn, and each
repair closed the spelling it was shown and not the class behind it. The last
two are the clearest statement of why:

    || { echo "$output" \; false; }            round 3 — the escape stops `;`
                                                separating, so `false` is an
                                                argument to `echo`
    || { echo "$output" \\; return 0; false; }   round 4 — the escaped backslash
                                                makes `;` a separator again,
                                                which round 3's repair blanks

A rule that reads one level of escaping fails on two. Deciding which `;`
separates commands needs the quoting and escaping read, and that lexing is what
cut the first gate.

**What the attempt did establish is that reading the corpus is not the hard
part.** Across four trees and four reviewers the scan never once failed to
report an inserted assertion or a deleted guard: 12,020 insertion points and
620 guard deletions at the last measurement, none silent, with an argument from
round 3 for why it cannot be otherwise. Every defect was in the verdict — does
this guard fail? — rather than in the reading. That is the opposite of the
first gate, whose failures were all in its reading and therefore silent. A
wrong verdict on a line the scan demonstrably read is a false negative someone
can go looking for, and four rounds of looking is what produced the table in
`PR-x4nb48`.

The sections below are kept as the record of what was measured. **They describe
a gate that is not in this tree**: every `.bats` file at HEAD is byte-identical
to the base, and `tests/assertion-guard.awk` and `tests/fixtures/assertion-guard/`
are absent. Read the figures as measurements of the attempt, not of the merge
candidate.

## Review

Round 1. The reviewer's own suite run gave 745 of 745, exit 0. It
reproduced every measured figure independently, and raised nine findings. Two
are defects that let an unguarded assertion pass the gate.

**finding-1**: code — the accounting did not detect a classification path that
credits the wrong bucket, which is the blind-spot class `PR-x4nb48` records.
Crediting one line range of `tests/check-trace.bats` to the `token` bucket
instead of `judged` left `files` at 13 and `physical` equal to the independent
`grep -c` sum, because the lines were credited somewhere rather than dropped.
An unguarded assertion inserted in that range was then reported by nothing and
all three tests passed. The only control on judgement was `judged > 0`, which
one line of 768 satisfies.
disposition: each bucket is now pinned to its own independent count rather than
only their sum. `comment`, `token` and `judged` are each computed in the test
from per-physical-line greps with no state — the comment bucket from
`^[[:space:]]*#`, the token bucket by removing the two literals and asking what
remains — and all four numbers reproduce the scan exactly. Reproducing the
reviewer's break now gives `judged=750 token=37` against 768 and 19, and the
test fails naming both pairs.

**finding-2**: requirement — the rule accepted an assertion whose guard is not
the last command. `[[ "$x" == y ]] || echo "$output" || false` has one opener,
one closer, `||` after the closer and an ending of `|| false`, and is inert:
the echo succeeds, so the second `||` is never reached and the list exits 0. So
is `[[ "$x" == y ]] || { echo a; } || { echo b; false; }`. Confirmed under the
vendored bats: a body of `run true` then
`[[ "$status" -eq 99 ]] || echo "x" || false` reports `ok`, while the canonical
guard reports `not ok`. Dropping the braces is the most plausible way to write
the guard wrongly, which makes this the regression the gate exists to reject.
disposition: the guard must now follow the closer immediately and reach the end
of the line. The mechanism named here — a restriction on `|` and `&` inside the
brace group — was replaced twice afterwards, by `finding-11` and then by
`finding-18`; the tree's rule is the template `finding-18` describes. Both
spellings this finding named are rejected under it and are controls. Both spellings are controls in `defective.txt`. The
corpus passes unchanged, so the tightening introduced no false positive in the
suite; its cost is that a diagnostic message containing `|` or `&` is reported,
and none is in the suite.

**finding-3**: record — `Gaps` omitted the two gaps above.
disposition: both are repaired rather than recorded, so neither is a gap. What
remains of the first is stated in `Gaps`: the bucket counts are compared per
physical line, and a logical line that spans several physical lines of
different kinds would be a visible false alarm.

**finding-4**: record — five unstated false positives, all correctly guarded
assertions: a `||` continuation onto the next line without a backslash, which
is valid shell; a trailing `;` after the guard block; spaces before the
semicolons inside it; `[[ a ]] || [[ b ]] || false`; and a `((` inside a quoted
string on a line that is not an assertion.
disposition: all five stated in `Gaps`. The first is the substantive one: the
plan defines a logical line by backslash alone and never stated that shell also
continues after `||`, `&&` and `|`.

**finding-5**: code — two classification paths were unexercised. `defective.txt`
declared four reasons but produced no `UNBALANCED` spelling, and neither fixture
contained a `(( ))` compound with a guard; the corpus contains none either.
disposition: `defective.txt` gains an `UNBALANCED` spelling and the two inert
guards from `finding-2`, taking it from 12 spellings to 15; `live.txt` gains
`(( seen == 1 )) || false` and the same with the canonical guard. All four
reasons and both accepting paths are now covered.

**finding-6**: record — the `check-ids.sh` row stated "109 verdict lines both
sides", which the reviewer could not reproduce and which the record gave no way
to reproduce, because it did not state the synthesized config.
disposition: the figure was wrong twice over. 109 counted every output line of
an earlier probe rather than verdict lines, and that probe used a config that
made `check-trace.sh` exit 2 before it read anything. Re-measured against the
stated config: 67 verdict lines of 73 output lines, at the base and at the
change alike, which is the reviewer's figure. The config is now stated above.

**finding-7**: record — the three `Watched red` cells were `PENDING`, so the
record claimed no observation for any of the three tests.
disposition: all three filled. Test 1's two reds come from task T3's dispatch
report; tests 2 and 3 had not in fact been watched red by anyone, so each was
made to fail deliberately before this row was written, and the cells quote what
was observed.

**finding-8**: record — `main` had advanced to `ff6bb34` and the branch was not
re-merged, so every corpus figure described a tree that would not be merged.
`ff6bb34` adds about 283 lines to `tests/skills.bats`, which is in the corpus.
disposition: base merged, and every figure re-measured after the repairs for
`finding-1`, `finding-2` and `finding-5`, which changed the corpus again.

**finding-9**: record — writing rules. No replaced word appears anywhere in the
diff, but metaphor and anthropomorphism remain in six places across the plan,
this record, the problem file and the scan's header, plus one balanced
contrast repeated in four files.
disposition: all rewritten.

Round 2. A second reviewer, dispatched against the repaired tree with round 1's
findings and dispositions available to it, measured its own suite run at 752 of 752, exit 0,
reproduced the sweeps and the corpus tables in full, and raised seven findings.
Three are defects, and two of those three are the same classes round 1 raised:
its repairs closed the instances named and not the class behind them.

**finding-10**: code — the bucket counters were credited when a line was
dispatched to `judge()`, not when a verdict was rendered, so a path returning
before the rule is applied credits the correct bucket and reports nothing.
Every one of the four pinned counts still reproduced the independent greps.
Measured: a `return` covering one line range of `tests/check-trace.bats` gave a
summary identical to the clean scan, and an unguarded assertion inserted in that
range left all three tests passing. With the `return` unconditional — the rule
applied to none of the 771 judged lines — the corpus test still passed. This is
round 1's `finding-1` one step further in: that repair pinned which bucket a
line is credited to and left unpinned whether the rule was applied at all.
disposition: each bucket is credited at the verdict. `judged_lines` is
incremented in each of the three terminal branches rather than on entry, so a
path that returns without rendering a verdict credits nothing and the count
falls short. That closes the shape this finding named and not the class behind
it — a path that credits the bucket itself and then returns is invisible to
every count — which round 3 raised as `finding-20` and which is in `Gaps`. Reproducing the break now gives `physical` 792 and `judged` 761
against 802 and 771, and the corpus test fails naming both. It is the fifth row
of the break table.

**finding-11**: requirement — the repaired block guard still accepted a brace
group whose `false` is unreachable. `[^|&]*` constrained the characters inside
the group, not the reachability of the `false`. Measured inert under the
vendored bats: `|| { echo "x"; return 0; false; }`, and the same with
`continue`, `break` and `skip`. The `continue` form is a plausible accident in
a loop over fixtures with the guard template's `false` left behind. The scan
header's claim that the guard must be the last command was true of the last
textual command, not the last executed one.
disposition: the brace group is now a closed set — one or more `echo` or
`printf` commands, then `false` — rather than a character restriction. That
repair was itself incomplete and is finished by `finding-17`: restricting the
commands left their arguments unrestricted, and `&&` inside an argument reaches
a control-flow command just as a `;` does. All four
spellings are rejected and are controls in `defective.txt`. The corpus passes
unchanged. Measured at the gate tree `7b29d9b`: 1,087 lines contain `|| {`, of
which 1,074 open the group with `echo`, 8 end the line at the brace, and the
remaining 5 are 2 `printf`, 2 `grep` and 1 `git`. The merge candidate has 1,070,
because the gate's own tests are gone. Of the brace guards on lines
this rule judges, all 720 open with `echo`; the five others guard `[ ]` tests
and pipelines the rule never judges. The change also
withdraws the false positives round 2 raised as `finding-16`, because `|` and
`&` inside the diagnostic are admitted again.

**finding-12**: code — `the assertion scan reports no live spelling` had no pin
on its fixture: only `judged > 0`, which one line satisfies. Cutting `live.txt`
to a single spelling left the test passing, so a live spelling deleted from the
fixture was not reported.
disposition: the expected count is hard-coded in the test and asserted. The
first repair attempted here derived the count from the fixture with the same
greps the corpus test uses, and that was the same defect again: both sides fall
together, and the gutted fixture still passed. Measured after the
hard-coded form: the one-line fixture fails with "the fixture contains 1 judged
lines, this test expects 14".

**finding-13**: record — the `check-trace.sh` row was not reproducible from the
config the record stated. Built exactly as written, `check-trace.sh` exits 2 at
`doc_srs is configured as 'docs/requirements', which does not exist` and reads
nothing, so the row's exit-1 figure and its roll-call observation could not be
checked. This is round 1's `finding-6` surviving in the other row of the same
table.
disposition: the scratch setup is now stated in full, including the three
placeholder document directories without which the script exits before reading
anything.

**finding-14**: record — stale measured figures in four places: the header
comments of `tests/portability.bats` quoted three break results and a bucket
pair from trees that no longer existed, one of them internally inconsistent
with a figure eleven lines above it; the problem file quoted an insertion sweep
of 11,718 lines; and test 1's `Watched red` cell quoted an observation against a
version of the test that no longer exists. Round 1's `finding-8` disposition
claimed every figure had been re-measured; these had not.
disposition: all corrected against the current tree, and the sweeps re-run a
third time because the repairs for `finding-11` and `finding-12` changed the
corpus again.

**finding-15**: record — two lines added by round 1's own repair text used a
replaced word, making `finding-9`'s disposition — "No replaced word appears
anywhere in the diff" — untrue at the moment it was written.
disposition: both rewritten.

**finding-16**: record — `Gaps` omitted the false positive the `[^|&]`
restriction introduced: a correctly guarded assertion whose diagnostic contains
either character, such as `{ echo "$output" >&2; false; }`, was reported.
disposition: the restriction is withdrawn by `finding-11`'s repair, and
`finding-17` then re-introduced one in a different shape. `{ echo "$output"
>&2; false; }` is accepted and is a control in `live.txt`;
`{ echo "wanted a && b"; false; }` is reported, was removed from `live.txt`
rather than left there asserting a pass it does not get, and its cost is in
`Gaps`.

**finding-17**: code — found by the author while testing round 2's own
repair, after round 3 had been dispatched and before it reported, and recorded
here because no reviewer raised it. The brace guard admitted
`|| { echo x && return; false; }`, which is inert: the `[^;]*` restriction
constrained the diagnostic's argument against `;` and nothing else, so `&&` and
`||` could chain the `echo` to a control-flow command. Measured under the
vendored bats, all four report `ok` where the canonical guard reports
`not ok`: `&& return`, `|| return 0`, `&& continue`, `&& break`. This is the
same class as `finding-11` at a fourth distinct point, and the third time a
repair for this class has closed the spellings it named rather than the class.
disposition: the argument now admits `([^;&|]|>&)*` — no `;`, `&` or `|`
outside a `>&` redirection. The claim behind it, which is the part to
test rather than the regex: those three characters are the only ones that can
put another command before `false` on one physical line, and a `$( )` or
backquote substitution cannot, because it runs in a subshell. Measured:
`return 7` and `exit 7` inside a substitution both leave the guard exiting 1,
so parentheses and backquotes are admitted rather than excluded. All four
spellings are controls in `defective.txt`; a substitution guard and a guard
whose message names a parenthesis are controls in `live.txt`.

Round 3. A third reviewer, dispatched against the tree round 2's repairs
produced, measured its own suite run at 752 of 752, exit 0, reproduced both sweeps and every
table, and raised ten findings. One is the defect that decided the shape of the
rule.

**finding-18**: requirement — a fifth inert spelling passes:
`|| { echo "$output" \; false; }`. The invariant every repair so far had used — that `;`, `&` and `|` are the only characters that can put another command
before `false` — is true and is the wrong property. This spelling puts no
command before `false`; it stops `false` being a command. Bash reads `\;` as a
quoted argument, so the group is one `echo` with the arguments `;` and `false`,
it exits 0, and the assertion is discarded. Measured: the body reports `ok`
where the canonical guard reports `not ok`, and `bash -c 'echo MSG \; false'`
prints `MSG ; false` and exits 0. Inserted into the corpus, the gate is silent
with all four counts intact. The same finding names a second hole: `(echo|printf)`
has no word boundary, so `{ echoerr "$output"; false; }` was admitted.
disposition: the guard is no longer a predicate over what a group may contain.
It is matched as a template in which `false` is necessarily a command word:
`echo` and `printf` are whole words followed by whitespace; an argument admits
no `;`, `&` or `|` outside a `>&` redirection; and a backslash-escaped `;` is
blanked before the match, so it can never be read as the separator the template
requires. All four escape spellings and both word-prefix spellings are controls
in `defective.txt`. The corpus passes unchanged.

**finding-19**: code — `the assertion scan reports no live spelling` pinned the
fixture's size and not its contents. Deleting the `printf` guard and the `>&2`
guard and duplicating the canonical one leaves `judged=14` and all three tests
passing, and the corpus contains no `printf` guard and no `>&` redirection, so
that fixture is the only control either branch has. A scan narrowed to `echo`
alone with the `>&` exception dropped passes all three tests against a fixture
gutted that way.
disposition: the test now names five strings the fixture must contain and fails
if any is absent. Measured: deleting the `printf` guard and duplicating the
canonical one now fails with "the live fixture no longer contains printf". This
is round 2's `finding-12` at the next step in — the hard-coded count closed
"the fixture shrinks" and not "the fixture loses a spelling".

**finding-20**: record — the accounting does not detect a path that credits its
own bucket and returns, and three places stated that it does.
disposition: all three corrected to state what is true, and the gap is in
`Gaps`. Crediting at the verdict closes an exemption path that simply returns,
which is the plausible regression, and does not close a path that credits and
returns.

**finding-21**: record — the `check-trace.sh` row was still not reproducible
from its stated setup: the scratch copy also needs `docs/architecture/soup.md`,
without which the script exits 2 and reads nothing. Third round in which this
table has failed to reproduce from its own text.
disposition: the setup now names that file and why. With it the row reproduces
exactly, which the reviewer confirmed.

**finding-22**: record — both sweep tables described a `tests/` tree that no
longer existed, and the record's own identity check between two trees was no
longer true.
disposition: both sweeps re-run at the tree the repairs produced, for the fourth
time in this change, and the identity sentence removed rather than restated.

**finding-23**: record — figures wrong against every tree in the range: the
brace-guard count was given as 1,066 in one place and 1,061 in another and
matched no tree; the live fixture's spelling count and the quoted failure text
were stale; and `finding-1`'s disposition quoted a corpus that had moved.
disposition: the brace-guard population is re-measured and stated in the terms
that matter — at the gate tree 1,087 lines contain `|| {`, and of the brace guards on lines this
rule judges, all 720 open with `echo`. The other three corrected.

**finding-24**: record — `Gaps` stated one gap the tree does not have, that
`[[ x ]] || { :; } # ; false; }` passes; it has been reported since round 2
replaced the character restriction. It omitted three that exist.
disposition: the false entry removed, and the accounting bypass and the
fixture-coverage gap added. The word-prefix hole is repaired rather than
recorded.

**finding-25**: record — three dispositions described mechanisms the tree no
longer has.
disposition: all three rewritten to name the tree's rule and to say which later
finding replaced the mechanism they first described.

**finding-26**: record — two replaced words and four metaphors on added lines,
in the third round in which this class has been raised.
disposition: all corrected.

**finding-27**: record — the plan describes a scan that no longer exists: the
rule without the command set or the argument restriction, a four-row break
table asserting something the record contradicts, a T3 specification that is
verbatim the weakness round 2 raised, and fixture sizes from the first
revision.
disposition: the plan now states the rule as built and marks its original
specification as superseded, rather than reading as a description of what was
delivered.

Round 4. A fourth reviewer, dispatched against the tree round 3's repairs
produced and told that its first answer would decide whether the change merged
or was abandoned, measured its own suite run at 752 of 752 exit 0, reproduced
every figure
in this record including the two check-script rows for the first time, and
raised five findings.

**finding-28**: requirement — a sixth inert spelling, and the same class as the
fifth. `gsub(/\\[;]/, "@@", probe)` reads a backslash as escaping the character
after it and never accounts for a backslash that is itself escaped. In
`|| { echo "$output" \\; return 0; false; }` the first backslash escapes the
second, so the `;` IS a separator and bash runs three commands — the echo,
`return 0`, then nothing. The blanking deletes that separator from the probe,
`return 0` is swallowed into the argument list, and the tail matches. Measured:
the scan reports no finding and exits 0; bats reports `ok` where the canonical
guard on the same body reports `not ok`. The same is true of its logical-line
twin, where the first physical line ends in `\\` and the shell does not
continue it although the scan does; for `skip` as well as `return`; for
`printf` as well as `echo`; on the `(( ))` branch; and for any even number of
backslashes. Planted in the corpus as a real test, all three gate tests report
`ok` with all four accounting counts intact.
disposition: the gate is cut, on the maintainer's standing ruling made after
round 3. `PR-x4nb48` is open again and contains the sequence of six spellings as
its evidence. Two sentences in the scan's header were untrue as a consequence
and are removed with it.

**finding-29**: record — `finding-18`'s disposition stated "all four escape
spellings" are controls; the fixture contained two, and `finding-18` named one.
The figure came from `finding-17`'s disposition and described no tree.
disposition: the gate is cut, and the fixtures are removed with it. Recorded here
because it is the fourth round in which a figure in this record described a
tree nobody measured, and that pattern is part of what the record is for.

**finding-30**: record — the plan states "Three literal tokens are removed"
and then names two and calls them "Both", in three consecutive lines.
disposition: corrected in the plan.

**finding-31**: record — `Gaps` omitted two things. A third accepting branch,
the `(( ))` compound with a brace guard, is exercised only by one line of
`live.txt` and is not among the five strings the test requires, so deleting it
with two continuation guards and duplicating the canonical guard leaves all
three tests green. And `|| { echo; false; }` — an `echo` with no argument — is
a live, correctly guarded assertion that the rule reports, which no stated cost
covered.
disposition: the gate is cut, so both are removed with it. The first is the same
defect as `finding-19` at one more remove: the count was pinned, then the
strings were pinned, and the branch that no string names was still unpinned.

**finding-32**: record — three anthropomorphisms on added lines, in the fourth
consecutive round in which this class has been raised. No replaced word appears
anywhere in the diff.
disposition: all three corrected. The three rounds of dispositions before this
one each stated that the class was closed.

Round 5. A fifth reviewer, dispatched against the cut tree, confirmed the
removal surgical by tree and per-blob identity, reproduced every figure this
tree still admits, and raised nine findings. **None is a `code` or a
`requirement` finding**, which by the convergence rule makes this the last
review round.

**finding-33**: record — the marker quarantining the removed gate covered only
the two sections after it, while the eight sections before it described the
gate in the present tense. A reader reaching `## Review` had read 240 lines of
present-tense description of code that is not here and met no warning.
disposition: the marker is moved above everything it warns about, immediately
after the header fields, and states which paths are absent.

**finding-34**: record — three identity claims in the blind-spot section were
false at the tip: five files differ from the swept tree rather than one, the
two named trees' `tests/` objects are not the same, and the sweep is attributed
to the commit that deleted the scan. One was the sentence `finding-22`'s
disposition recorded as removed rather than restated.
disposition: the identity claims are removed and the trees named instead. The
per-file counts are labelled as the gate trees' and the difference from the
merge candidate is stated.

**finding-35**: record — **`PR-x4nb48`'s sixth spelling was transcribed with one
backslash instead of two, and so was `finding-28`'s own entry.** With one
backslash the spelling is a LIVE guard: the reviewer measured it `not ok` under
the vendored bats. A third attempt following the item would have measured that
row, found it fails, and concluded the cut was mistaken.
disposition: corrected in both places, and the item now states the distinction
explicitly with both measurements, and warns that a shell heredoc halves the
backslashes. This was the most consequential defect of the five rounds in the
artifact that outlives them, and it was in the evidence for the decision rather
than in the decision.

**finding-36**: record — the plan merged as an unmarked description of a
delivered gate, with four references to files that do not exist and an
`Implements:` line claiming an item that is open.
disposition: a section at its head states that nothing in it was delivered,
names every absent path, and corrects the `Implements:` line.

**finding-37**: record — the `check-trace.sh` setup was made non-reproducible
again by the commit before this round: it deleted the `git init` and
placeholder-file facts an earlier round had added. Fourth consecutive round for
this row.
disposition: the setup now states every step and what each one's absence
produces, measured: no commit gives `not inside a git repository`, no
`soup.md` gives `doc_soup … does not exist`, and empty directories give
`doc_srs … contains no *.md files`.

**finding-38**: record — `1,087` was the gate tree's count and was used in two
forward-looking places that a third attempt would read.
disposition: both now give the merge candidate's 1,070 and name the gate tree
for the other figure.

**finding-39**: record — five finding citations resolved to this record's
numbering but belong to the first attempt's.
disposition: all five name that record, and this one states that an unqualified
citation belongs to it.

**finding-40**: record — five metaphors and anthropomorphisms on added lines,
although no exact replaced word appeared anywhere in the diff. Fifth
consecutive round for this class.
disposition: all corrected.

**finding-41**: record — the accounting harness the record instructs a third
attempt to reuse exists only in commits the squash makes unreachable, along
with the two fixtures' spellings accumulated over four rounds.
disposition: an appendix reproduces the counters, the independent side that
compares them, and all forty-four fixture spellings, and states that round 4's
own spelling is not among them because the gate was cut rather than repaired a
fifth time. That spelling and its logical-line twin are written out beside
them.

## Gaps

What this change does not establish. It delivers no gate, so most of what an
earlier revision listed here was removed with the code; what remains is what the
attempt failed to settle.

- **`PR-x4nb48` is not resolved, and nothing keeps the 301 guards in place.**
  That is unchanged from before this change. The item is open with four rounds
  of evidence added.
- **Whether a line-based rule can decide that a guard fails.** Four rounds produced
  six counterexamples; none of that is a proof. The argument is
  that deciding which `;` separates commands requires the quoting and escaping
  read, and each repair that read one more level failed on one more.
- **Whether the two directions `PR-x4nb48` names would work.** Neither running
  each test body under a shell that answers directly, nor enforcing one literal
  guard spelling across every `|| {` line, was tried or costed beyond the line
  count.
- **The accounting design has one hole and it was not closed.** A path that
  credits its own bucket and then returns leaves `files`, `physical` and all
  three buckets equal to independent greps while the rule is applied to
  nothing. Four other break shapes were detected. Whoever builds the third
  attempt should reuse the counters and close that one.
- **A `false()` function defined in a test file makes every guard in it
  inert**, and the canonical spelling is still accepted. Round 4 observed this.
  No one-line rule detects it.
- **Only BWK awk was measured.** `awk version 20200816` is the only
  implementation on this machine; gawk, mawk and busybox awk were not
  exercised in any round.
- **The suite figure is one run on one machine**, and bash 3.2 is the only
  shell whose errexit behaviour any round reasoned about.

## Appendix: what a third attempt would otherwise lose

The scan, its two fixtures and the three tests exist only in commits this
change's squash makes unreachable. Two parts of them are worth more than the
rule that was cut, and are reproduced here so that they survive in `main`.

### The accounting counters

Each bucket counts the PHYSICAL lines containing `[[` or `((` that it accounts
for, credited at the point a verdict is rendered. `tests/portability.bats` then
computed the same four numbers independently, with per-line `grep` and no
reference to the scan, and compared each. Four deliberate breaks were caught by
it: a bucket credited over part of the corpus only, a counter reset before
classification, a file never read, and a continuation that never terminates.
One was not, and closing it is the open problem: a path that credits its own
bucket and then returns leaves every count correct.

```awk
FNR == 1 {
    if (in_continuation) {
        report(buffer_file, buffer_line, "UNTERMINATED-CONTINUATION", buffer)
        judged_lines = judged_lines + pending
        pending = 0
        in_continuation = 0
        buffer = ""
    }
    file_count = file_count + 1
}

{
    physical = $0
    if (physical ~ /\[\[/ || physical ~ /\(\(/)
        pending = pending + 1
    if (in_continuation == 0 && physical ~ /^[ \t]*#/) {
        comment_lines = comment_lines + pending
        pending = 0
        buffer = ""
        next
    }
    continued = (physical ~ /\\$/)
    if (continued)
        sub(/\\$/, "", physical)
    if (in_continuation) {
        sub(/^[ \t]+/, " ", physical)
        buffer = buffer physical
    } else {
        buffer = physical
        buffer_file = FILENAME
        buffer_line = FNR
    }
    if (continued) {
        in_continuation = 1
        next
    }
    in_continuation = 0
    judge(buffer, buffer_file, buffer_line)
    pending = 0
    buffer = ""
}

END {
    if (in_continuation) {
        report(buffer_file, buffer_line, "UNTERMINATED-CONTINUATION", buffer)
        judged_lines = judged_lines + pending
        pending = 0
    }
    summary_format = "summary files=%d physical=%d judged=%d"
    summary_format = summary_format " comment=%d token=%d findings=%d\n"
    printf summary_format, file_count,
        judged_lines + comment_lines + token_lines,
        judged_lines, comment_lines, token_lines, findings
    if (findings > 0)
        exit 1
}
```

The independent side, from `tests/portability.bats`, over the same file list:

```sh
physical_expected=$(grep -cE '\[\[|\(\(' "$f")
comment_expected=$(grep -E '\[\[|\(\(' "$f" | grep -cE '^[[:space:]]*#')
token_expected=$(grep -E '\[\[|\(\(' "$f" | grep -vE '^[[:space:]]*#' \
    | sed 's/\$((//g; s/\[\[://g' | grep -cvE '\[\[|\(\(')
judged_expected=$((physical_expected - comment_expected - token_expected))
```

### The spellings, accumulated over four rounds

Twenty-seven that any gate must report, each with the reason it was expected to
give. **Round 4's spelling is not among them**: it was found after this fixture
was last edited, and the gate was cut rather than repaired a fifth time, so it
was never added as a control. A third attempt needs it and its logical-line
twin, which no fixture here covers:

```
# UNGUARDED: the first backslash escapes the second, so the `;` separates and
# `return 0` leaves before `false` is reached. TWO backslashes, not one: with
# one, `false` runs and the guard is live.
[[ "$x" == y ]] || { echo "$output" \\; return 0; false; }

# UNGUARDED: the same, reached through a line the shell does not continue
# although a trailing-backslash test does.
[[ "$x" == y ]] || { echo "$output" \\
return 0; false; }
```

The twenty-seven as they stood at the cut:

```
# UNGUARDED: no guard at all.
[[ "$x" == y ]]
# UNGUARDED: a trailing semicolon is not a guard.
[[ "$x" == y ]];
# UNGUARDED: && true replaces a non-zero status with zero.
[[ "$x" == y ]] && true
# UNGUARDED: || true replaces a non-zero status with zero.
[[ "$x" == y ]] || true
# UNGUARDED: the guard block prints and then exits zero.
[[ "$x" == y ]] || { echo "$output"; }
# UNGUARDED: the word false is inside a string and is not a command.
[[ "$x" == y ]] || { echo "false alarm"; }
# UNGUARDED: the guard text is inside a comment, after the compound.
[[ "$x" == y ]]   # || false
# MULTIPLE-COMPOUND: two compounds on one line, the first one discarded.
[[ "$a" == b ]] ; [[ "$c" == d ]] || { echo "$output"; false; }
# UNGUARDED: an arithmetic compound with no guard.
(( 1 == 2 ))
# UNGUARDED: a compound continued across a backslash onto an unguarded line.
[[ "$x" == \
   y ]]
# UNGUARDED: a shell comment ends at its own physical line, so the backslash
# does not continue it and the assertion below is judged on its own.
# a note ending in a backslash \
[[ "$x" == y ]]
# UNBALANCED: the assertion's own text contains a second closer.
[[ "$output" == *"a]]b"* ]] || false
# UNGUARDED: the guard is not the last command. The echo succeeds, so the
# following || is never reached and the whole list exits zero.
[[ "$x" == y ]] || echo "$output" || false
# UNGUARDED: the first guard block cannot fail, so the second is never
# reached and the assertion is discarded.
[[ "$x" == y ]] || { echo a; } || { echo b; false; }
# UNGUARDED: return leaves the function before false is executed.
[[ "$x" == y ]] || { echo "$output"; return 0; false; }
# UNGUARDED: continue starts the next iteration before false is executed.
[[ "$x" == y ]] || { echo "$output"; continue; false; }
# UNGUARDED: break leaves the loop before false is executed.
[[ "$x" == y ]] || { echo "$output"; break; false; }
# UNGUARDED: skip ends the test as skipped before false is executed.
[[ "$x" == y ]] || { echo "$output"; skip "a reason"; false; }
# UNGUARDED: && chains the echo to a return, which leaves before false.
[[ "$x" == y ]] || { echo "$output" && return; false; }
# UNGUARDED: || chains the echo to a return the same way.
[[ "$x" == y ]] || { echo "$output" || return 0; false; }
# UNGUARDED: && chains the echo to a continue.
[[ "$x" == y ]] || { echo "$output" && continue; false; }
# UNGUARDED: && chains the echo to a break.
[[ "$x" == y ]] || { echo "$output" && break; false; }
# UNGUARDED: the backslash stops the semicolon separating, so false is an
# argument to echo and the group exits zero.
[[ "$x" == y ]] || { echo "$output" \; false; }
# UNGUARDED: the same escape after an earlier diagnostic command.
[[ "$x" == y ]] || { echo a; echo "$output" \; false; }
# UNGUARDED: a command whose name merely begins with echo.
[[ "$x" == y ]] || { echoerr "$output"; false; }
# UNGUARDED: a command whose name merely begins with printf.
[[ "$x" == y ]] || { printf_and_bail "$output"; false; }
# UNTERMINATED-CONTINUATION: the file ends while the continuation is open.
[[ "$x" == y ]] || \
```

Seventeen that no gate may report:

```
# reads it as a test.
# The canonical guard.
[[ "$output" == *x* ]] || { echo "$output"; false; }
# The canonical guard with a custom message.
[[ "$output" == *x* ]] || { echo "a custom message: $output"; false; }
# The bare guard.
[[ "$output" == *x* ]] || false
# The canonical guard reached through a backslash continuation.
[[ "$output" == *x* ]] || \
    { echo "$output"; false; }
# The custom-message guard reached through a backslash continuation.
[[ "$output" == *x* ]] || \
    { echo "a custom message: $output"; false; }
# The bare guard reached through a backslash continuation.
[[ "$output" == *x* ]] || \
    false
# A guard whose diagnostic is redirected.
[[ "$output" == *x* ]] || { echo "$output" >&2; false; }
# A guard with two diagnostic commands.
[[ "$output" == *x* ]] || { echo "context"; echo "$output"; false; }
# A guard whose diagnostic interpolates a command substitution. The
# substitution runs in a subshell, so it cannot skip the false.
[[ "$output" == *x* ]] || { echo "saw $(echo inner)"; false; }
# A guard whose diagnostic names a parenthesis.
[[ "$output" == *x* ]] || { echo "missing the leading (:"; false; }
# A guard that uses printf rather than echo.
[[ "$output" == *x* ]] || { printf '%s\n' "$output"; false; }
# An arithmetic compound with the bare guard.
(( seen == 1 )) || false
# An arithmetic compound with the canonical guard.
(( seen == 1 )) || { echo "$output"; false; }
# An arithmetic expansion, which is not a compound command.
seen=$((seen + 1))
# A POSIX bracket expression inside an awk program.
awk '/^[[:space:]]*$/ { blank_lines = blank_lines + 1 }'
# A comment whose prose names [[ ]] and (( )) and no guard.
# A comment ending in a backslash does not continue onto the guarded \
[[ "$output" == *x* ]] || { echo "$output"; false; }
# A line with no bracket compound at all.
echo "nothing to judge on this line"
```
