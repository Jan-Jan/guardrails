# Verification — inert assertions (2026-09-28)

branch: audit-inert-assertions
reviewer: five agent reviewers, dispatched separately in five rounds, each given the diff, the plan and the ledger items, and no implementation narrative
verdict: five rounds raised fifty-four findings — nine, six, fourteen, seventeen and eight. Round 4 demonstrated a blind spot live in the tree and a defect rate that was not converging, and on that evidence the gate this change had built was cut from it and recorded as `PR-x4nb48`. Round 5 raised no `code` finding: it re-measured every figure, confirmed the removal surgical by blob identity, and found eight record defects, all corrected. What remains is the repair, in which no round found a defect
reproduced: yes — the mechanism directly on this machine's `/bin/bash` 3.2.57, and its consequence on the real suite through mutation M39

Change: every `[[ ]]` and `(( ))` assertion in the bats suite is guarded by a
command that fails. Resolves `PR-tenhv4` and `PR-8uggn4`. Opens `PR-7za3at`,
the same defect in a negated command, and `PR-x4nb48`, the gate that would
reject the unguarded spellings, which was built here and cut — see "Why the
gate is not here" below. Branched from `main` at `97add71`; `be60c4e` and
`fc88138` were merged in later, at `20353fd` and `d296ffa`, from local `main`
per AGENTS.md non-negotiable 5, so `origin` was out of scope by policy rather
than skipped by accident.
Plan: `docs/plans/2026-09-28-inert-assertions.md`.

## The gate

Measured on: `29cf6d2` — `git rev-parse HEAD` — tree `675796b`, from
`git rev-parse HEAD^{tree}` on a clean worktree. `merge-change` step 3 renamed
nothing, so this is the tree step 2 measured. The only commit after it is the
one that writes this paragraph and the rows below into this file; nothing that
any row measures is in that commit. Both the base and the change were probed on
the same day, so the ages in the roll-call are comparable.

This repository does not self-host its own gates: the tree has no
`.guardrails/config.yaml`. The two check scripts were run against a scratch
copy with a synthesized config, and the same was done at the base commit,
so each row states the delta this change makes rather than a census of a
repository this change does not otherwise modify.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | 742 of 742, 0 failures, exit 0. One fewer than the previous revision, which is the gate test this change no longer adds |
| `check-ids.sh` | verdict counts identical to the base. Three `DRAFT-ID` lines differ in quoted text only — same file, same line, same verdict |
| `check-trace.sh` | exit 1 at the base and at the change alike, unchanged by it: the synthesized probe config produces `DANGLING-REF` against documents this change does not touch. Of this change's own IDs, `PR-tenhv4` and `PR-8uggn4` left the roll-call and `PR-7za3at` and `PR-x4nb48` entered it. No other verdict added or removed, and no new `DANGLING-REF` or `DANGLING-FILE` |
| Coverage, against the class target | not measured; this change adds no requirement and no production code |
| Working tree | clean at the commit above |

The suite figure was measured by running `sh tests/run-tests.sh`, not a bats
binary from elsewhere. That distinction is critical here and is why round
2's first finding existed: the documented command clones bats-core into
`tests/.bats-core` when no system bats is present, which is the case on this
machine, and the gate then reads 200 more `.bats` files.

## Red → green

This change implements no REQ and no LLR. It resolves two problem items, and
each reproduction was watched failing before its repair existed.

| Item | Test | Watched red |
| --- | --- | --- |
| `PR-tenhv4` | `tests/finalize-docs.bats` "finalize: a draft ledger name with whitespace fails before anything is rewritten" | yes — with mutation M39 applied it reports `ok` unguarded and `not ok` guarded |
| `PR-8uggn4` | `tests/lib.bats` "gr_check_config rejects a key set to nothing, whichever key it is" | yes — with mutation M90 applied that file reports 0 failures before the scalar case and 1 after |

## What was wrong, and what was built

bash 3.2 — macOS `/bin/bash`, and the shell bats runs test bodies with — does
not apply `errexit` to the status of a `[[ ... ]]` or `(( ... ))` compound
command. bats takes a test's verdict from the exit status of its body's last
command, so such an assertion anywhere else was evaluated and its result
discarded. Measured at `3.2.57`: `[[ a == b ]]` and `(( 1 == 2 ))` reach the
next line under `set -eE`; `[ a = b ]`, `let "x = 0"`, `v=$(false)` and a
failing `grep` stop it.

69 assertions were inert, across five files. All 69 were correct as written —
`tests/check-trace.bats` reports 266 of 266 with them live — so the defect cost
no false assertion. It is measured instead in a mutation kill the suite did not
report: id-tokens M39 deletes `finalize-docs.sh`'s whitespace guard, and
`tests/finalize-docs.bats` reported `ok` against it.

The repair covers 301 assertions, not 69. The other 232 were live only by
position, and a line appended below any of them makes it inert with nothing
reporting the change — which is how `650f090` added two to the population while
using the guarded form correctly elsewhere in the same diff. The transform is
one shape appended to one shape: stripping `|| { echo "$output"; false; }` from
each changed line reproduces the original line byte for byte, and no line was
added or lost.

`PR-8uggn4` is resolved in the same change because `tests/lib.bats` contains
three of the inert assertions, and its own note asks for one audit of that file.

## Why the gate is not here

This change built a gate to reject the unguarded spellings and removed it before
merge. The decision was the maintainer's, on round 4's evidence.

Six revisions of a line-based awk scan repaired sixteen distinct defective or
over-broad readings. The last two repairs each introduced a new defect: the
brace-group join added at `5b3b986` created a blind spot, and a control added at
`c5cdeb9` asserted a shape that is live. The blind spot was present in the tree. An unguarded assertion inserted anywhere in roughly lines 240 to
330 of `tests/check-ids.bats` was reported by nothing and the gate exited 0.
Probes at lines 100, 200, 240, 300, 320, 330, 400 and 600 were reported at 100,
200, 400 and 600 and silent at the other four. Its cause was
`tests/check-ids.bats:236`, where a backslash-escaped quote desynchronised the
scan's quote tracking, after which the brace join then consumed every line to
the end of the construct.

The count is not the reason. Every one of the sixteen was in one of five
hand-written approximations of shell lexing, and when one of them
desynchronises the scan reports nothing and exits 0. The calibration block
cannot detect that, because it proves only that the scan still matches known
defective strings, which remains true while the scan has stopped reading a
hundred lines. A gate that reports success after examining nothing gives the
suite an assurance nobody re-derives.

What remains has its own evidence, in which no round found a defect: 301
assertions guarded, byte-exact, with two mutation kills restored. The gate is
`PR-x4nb48`, with round 4's report as its brief.

## Review

Findings 1 to 29 were raised while this change still contained the gate, and
many of their dispositions describe code that left with it. They are kept as
the record of what was found and when. Where such a disposition states that
`tests/portability.bats` now contains something, read it as describing the
revision current when the finding was closed, not the merge candidate; the file
at HEAD is byte-identical to the base.

**finding-1**: code — the gate matched only a line whose whole content is
`[[ ... ]]`, so `[[ ... ]];`, `]] ;;`, `]] && true`, `]] || true` and a
multi-line assertion all passed it. A regression gate that matches only the
shapes already removed catches no future defect.
disposition: the scan was rewritten to find an assertion by command position
and to require a guard that can fail. The control block in
`tests/portability.bats` now contains 24 defective spellings, and the scan as it
stood when this finding was raised matches 8 of them.

**finding-2**: code — the gate could pass having linted zero `.bats` files:
three globs were collected into one list and only the list's emptiness was
checked, and `tests/run-tests.sh` always matched the `*.sh` glob. A test file
in a subdirectory was out of scope.
disposition: discovery is now `find`, the `.bats` count is asserted rather than
the combined list's emptiness, and the scan's own exit status is read.

**finding-3**: requirement — the plan and the gate comment stated the hole is
specific to `[[`. `(( 1 == 2 ))` has it too.
disposition: both texts corrected, and `(( ))` is now part of the rule. It
appears nowhere in the suite, so the gate exists there to keep the first one
written from being written inert.

**finding-4**: code — two false positives: a predicate function whose trailing
`[[ ]]` is its return value, and a `[[ ]]` inside a heredoc body.
disposition: only `@test` and the bats lifecycle functions are linted, and
heredoc bodies are skipped. Both are controls.

**finding-5**: record — the reproduction for `PR-8uggn4` had no `verifies:`
annotation, which `resolve-problem` requires.
disposition: `# verifies: PR-8uggn4` added at `tests/lib.bats:511`, inside the
test the item's `affects:` line names.

**finding-6**: record — no verification record existed.
disposition: this file.

**finding-7**: record — six uses of vocabulary AGENTS.md replaces, plus
metaphor and balanced contrast in added prose.
disposition: all corrected. `tests/skills.bats` "clanker: no file in scope
contains the replaced vocabulary" passes, and the three violations it does not
cover — `docs/plans` is outside its scope — were corrected as well.

**finding-8**: record — the plan stated all 301 assertions are one shape.
disposition: corrected to the measured distribution: 260 `==`, 39 `!=`, 2 `=~`
at `tests/new-id.bats:222` and `:255`. The companion claim, that every one
tests `$output`, is true of all 301.

**finding-9**: record — the item stated 65, 67 and 69 for one population.
disposition: the resolution now names 65 and 67 as superseded by 69 and states
why all three differ.

**finding-10**: code — the gate's `find` descended into the vendored
`tests/.bats-core`, which `tests/run-tests.sh` creates whenever no system bats
is present. That is the case on this machine, so the first run of the mandatory
suite command in a fresh worktree would have produced 196 findings against
bats-core's own tests and fixtures, none of them this project's to repair.
disposition: `-name .bats-core -prune` added, matching the spelling
`tests/evidence.sh:72` already used and the exclusion the two sibling scans in
the same file already applied. The pipeline's exit status is now read as well,
which is a separate hardening and not, as this record first stated, a repair
for an observed awk failure — see finding-20. The
gate figure above was then measured by running `sh tests/run-tests.sh` in this
worktree, which vendored bats-core: 213 `.bats` files present, 13 linted,
743 of 743 passing.

**finding-11**: code — four further inert spellings passed: `{ [[ ]]; }`,
`cmd && [[ ]]`, `! [[ ]]`, and a `[[ ]]` in a case branch.
disposition: the scan judges an assertion wherever the shell would run it as a
command — line start, or after `{`, `!`, `&&`, `||`, `;`, or a case pattern's
`)`. A subshell `( [[ ]] )` is left alone because `errexit` does fire there.
All four are controls.

**finding-12**: code — a `<<` that is not a heredoc, such as `$(( 1<<bits ))`
or `<<` inside a quoted string, switched linting off for the rest of the body.
disposition: the heredoc operator is now recognised only with balanced quotes
or none, and only when not preceded by a word character. Two controls, each an
assertion after such a line that must still be reported.

**finding-13**: code — two false positives on correct shell: a guard written on
the line below after a trailing `||`, and an `if` condition split so its second
line begins with `[[`.
disposition: a line ending in `||` or `&&` is joined with the next before
judging, and a condition is not judged. Both are controls.

**finding-14**: record — the plan's population table stated 126 for the
continued-guard row; the figure is 135.
disposition: corrected, and the cause recorded in the plan. A `}` at column one
inside a quoted heredoc body — `tests/check-trace.bats:1739`, in awk source a
fixture writes out — ended a test for the counting scan that produced 126. The
same scan shape was then re-run heredoc-aware against the 69 and the 232, which
are unchanged, and all four rows now come from one pass and sum to 752.

**finding-15**: record — six writing-rule violations in prose added by the
repair of the earlier findings.
disposition: all corrected.

**finding-16**: code — commit `9c57e9d` put 5,343 lines of probe output on the
branch: a `.guardrails/config.yaml` and nine copies of `scripts/*.sh`. The tree
then failed `tests/skills.bats` "clanker: every tracked file is in the scan's
scope or named out of it", and the checkout was dirty.
disposition: the commit is dropped and the branch reset to `30c16d0`. Its cause
was a scratch copy made with `tar cf - .`, which in a worktree copies the `.git`
file, so a `git commit` inside the copy committed to this branch. Every other
probe in this change used `git archive`, which does not copy it.

**finding-17**: record — the gate table named `631bf6e`, three commits below the
tip, so every figure in it described a tree that was not the merge candidate.
disposition: re-measured. The table above names the tree it was measured on.

**finding-18**: record — the record stated the tree has no
`.guardrails/config.yaml`; at that tip it had one, added by `9c57e9d`.
disposition: true again once `9c57e9d` was dropped, and verified rather than
assumed.

**finding-19**: record — the un-pruned gate was stated to report 176 findings.
The figure is 196, at every revision of the scan.
disposition: corrected here and in `tests/portability.bats`. 176 was a figure
never measured.

**finding-20**: record — the awk failure was attributed to a fixture whose name
contains a tab. No path under `tests/` contains a tab. The fixture is
`tab in filename.bats` — the word, and two spaces — and the gate's own pipeline
handles spaces through `tr` and `xargs -0`. The failure came from an ad-hoc
probe that used a bare `xargs`.
disposition: the claim is removed from this record and from
`tests/portability.bats`. It was inferred from an error message that printed
the path truncated at its first space, which is a reading the message permits and does not support.

**finding-21**: code — the guard check read `false`, `return N` and `exit N` as
space-delimited words, so each satisfied the gate from inside a string literal.
`|| { echo "a diagnostic naming false in prose"; }` passed while guarding
nothing, contradicting this record's claim that a guard is read as a command.
disposition: the scan now blanks every quoted span, preserving offsets, before
it reads a line as shell. Two controls.

**finding-22**: code — the match from `[[` to `]]` was greedy, so on a line
with two assertions the guard belonging to the second was credited to the
first: `[[ a ]] ; [[ b ]] || { echo "$output"; false; }` passed while the first
assertion was discarded entirely.
disposition: the scan takes the first closing bracket, and reads the guard only
as far as the first `;` outside braces, so a guard after a command separator
belongs to no earlier assertion. A control.

**finding-23**: code — three false positives: `(( ))` inside a quoted string
handed to another shell, a guard delegated to a helper such as `die`, and a
function defined inside a test body whose trailing `[[ ]]` is its return value.
disposition: the first is repaired by the same quote masking as finding-21, and
is a control. The other two are not repaired and are stated in Gaps. Accepting
an arbitrary command as a guard would accept `|| true`, which is the defect.

**finding-24**: record — `tests/lib.bats` cited M90 as an id-tokens mutation. It
is `2026-08-27-config-schema.mutations/M90.sh`.
disposition: corrected in the test comment, which is the citation a later reader
follows first.

**finding-25**: record — the Gaps section omitted gaps that exist.
disposition: four added, covering the two false positives left unrepaired, the
pipeline case, and a `[[ ]]` whose own text contains `]]`.

**finding-26**: record — the item's `affects:` line still stated
`check-trace.bats (51)`, summing to the superseded 67.
disposition: corrected in place to 53, per `resolve-problem` §2, and the
resolution states that the line was corrected and why the opening sentence was
not.

**finding-27**: record — three metaphors in prose this change adds.
disposition: all three rewritten.

**finding-28**: code — a comment sentence left ungrammatical by the round-2
writing repair, at 93 columns in a file that wraps at 79.
disposition: rewritten and rewrapped.

**finding-29**: record — the base had moved to `fc88138`, so the roll-call and
open-count deltas described a base that no longer existed.
disposition: `fc88138` merged and every gate figure re-measured above.

A further defect was found by the author while probing the rewritten gate,
between the two rounds, and is recorded here because no reviewer raised it: a
guard whose `false` appeared only inside a string — `|| { echo "false alarm"; }`
— satisfied the check while guarding nothing, as did `falsely`. The check now
reads `false` as a command. Both spellings are controls. A second was found the
same way while repairing round 3: a single-line `@test "x" { ... }` had its
whole body consumed by the rule that recognises the header, so nothing in it was
judged. The form appears nowhere in the suite. It is repaired and is a
control. A third was found while attacking the gate after round 3, and is a
false positive rather than a miss: a guard whose brace group closes several
lines below — `]] \` then `|| {` then `echo`, `false`, `}` — was reported,
because only a backslash or a trailing `||` continued a line. The scan now also
continues while a brace group is open. It is a control, as are an assertion
containing an escaped quote and one containing a `;` inside a string, both of
which the quote masking already handled and neither of which had a control.

Counting the three found by the author, the gate had sixteen distinct defective
or over-broad readings repaired across six revisions before round 4 found eight
more. Every one was in the scan; none was in the 301-line transform, which has
been byte-exact and unchanged since it was first measured. That distribution is
why the gate was cut and the repair kept, and "Why the gate is not here" above
gives the reasoning.

**finding-30**: code — an unguarded assertion anywhere in roughly lines 240 to
330 of `tests/check-ids.bats` was reported by nothing. `mask()` did not honour a
backslash-escaped quote, so `tr -d "\\" | tr -d "\"'"` desynchronised it, and
the brace join then consumed every following line.
disposition: the gate is cut. Recorded as `PR-x4nb48` with this as its first
evidence.

**finding-31**: code — one line that merely resembles a heredoc operator, such
as `run bash -c 'cat >f <<END; cat f'`, armed heredoc mode for the rest of the
file, and `here` was never reset at `}`, at `@test` or at end of file.
disposition: the gate is cut. `PR-x4nb48`.

**finding-32**: code — a trailing comment naming the guard satisfied the guard
check, because `guardseg()` read comment text as shell.
disposition: the gate is cut. `PR-x4nb48`.

**finding-33**: code — `( [[ ... ]]; cmd )` is inert and was unreported: the
subshell exemption was unconditional, but errexit fires there only when the
assertion is the subshell's last command.
disposition: the gate is cut. `PR-x4nb48`.

**finding-34**: code — a single-line `@test` whose name contains `{` had its
whole body unjudged, the same failure a self-found defect was meant to close.
disposition: the gate is cut. `PR-x4nb48`.

**finding-35**: code — a control added at `c5cdeb9` asserted
`echo x | while read -r l; do [[ ... ]]; done` as defective. It is live: the
pipeline gives the loop a real command status and errexit fires.
disposition: the gate is cut. `PR-x4nb48`. The record's own Gaps had already
classified this family as a false positive, so the change contradicted itself.

**finding-36**: code — `x=$(cmd; [[ ... ]])` is live and was reported.
disposition: the gate is cut. `PR-x4nb48`.

**finding-37**: code — `<<\EOF` heredoc bodies were linted, because the
recogniser accepted `WORD`, `'WORD'` and `"WORD"` but not `\WORD`.
disposition: the gate is cut. `PR-x4nb48`.

**finding-38**: code — a heredoc body containing an indented copy of its
terminator ended the heredoc early, because the comparison stripped leading
whitespace for plain `<<WORD` as well as `<<-WORD`.
disposition: the gate is cut. `PR-x4nb48`.

**finding-39**: code — a `case` pattern that is a bracket expression at line
start was reported.
disposition: the gate is cut. `PR-x4nb48`.

**finding-40**: record — the gate table named a tree three commits below the
tip, two of whose commits changed the file the suite figure measures. Third
occurrence of this defect in this record.
disposition: re-measured at the final tree, after the gate was cut.

**finding-41**: record — the tally the ship decision rested on was stale at its
own tip: sixteen readings across six revisions, not fifteen across four.
disposition: corrected, and moved into "Why the gate is not here" where it is
the evidence rather than an aside.

**finding-42**: record — Gaps stated "No such function exists here" of a
function defined inside a test body. `tests/check-ids.bats:230` has one, it is
the `{` that opened the never-closing buffer, and the stated consequence was the
opposite of the real one.
disposition: the Gaps entry is removed with the gate. The function is named in
`PR-x4nb48` as the construct that defeated the masker.

**finding-43**: record — `PR-7za3at` stated eleven inert negated commands; the
figure is ten, and `tests/skills.bats` has nine, not ten. `tests/skills.bats:1367`
continues onto `:1368` and is its body's last command, so it is live.
disposition: the item is corrected to ten, the affected table row removed, and
the cause recorded in the item: the counting scan compared against the body's
last LINE rather than its last COMMAND, which is the error this whole audit is
about.

**finding-44**: record — "Branched from `main` at `be60c4e`" is wrong. The
branch point is `97add71`; `be60c4e` and `fc88138` were merged in later.
disposition: corrected above.

**finding-45**: record — Gaps omitted eight real gaps and did not mention the
live blind spot.
disposition: the gate is cut, so those gaps leave with it and are `PR-x4nb48`'s
brief. Gaps below now covers what this change actually does not establish.

**finding-46**: record — writing rules: anthropomorphism and balanced contrast
in one sentence, editorializing in another, a 117-column comment line, and two
unwrapped lines in the ledger.
disposition: all corrected.

**finding-47**: record — `PR-7za3at`'s reproduction demonstrated nothing.
`! grep -q zzz /etc/hosts` negates a grep that finds nothing, so the negation
returns 0 and `REACHED` printed because the command succeeded. The item also
claimed that the same command as a body's last line exits 1; it exits 0. The
defect is real but needs a pattern the file contains.
disposition: both the item and this record now use `! grep -q localhost
/etc/hosts`, which returns 1, and state why the pattern has to match. In a class
B problem report the reproduction is the warrant for the claim, and this one did
not support it.

**finding-48**: record — finding-43's disposition claimed the count was
corrected to ten; four prose statements in `PR-7za3at` still stated eleven,
including one that also gave the per-file split wrongly.
disposition: all four corrected. The sentence recording that the item first
stated eleven is kept, because it is the correction narrative. The figure had
been fixed everywhere a scan would look and left everywhere a reader reads.

**finding-49**: record — two statements in the plan asserted in the present
tense that a gate exists, contradicting T1 and "What this change does not do" in
the same file.
disposition: both rewritten.

**finding-50**: record — two statements in `PR-7za3at` told a later author that
this change ships a gate to extend. It does not.
disposition: rewritten to state that no gate covers either construct, and that
`PR-x4nb48` is open for the bracket-compound rule.

**finding-51**: record — `PR-x4nb48`'s cost figures for the alternative rule
described the tree that still contained the gate: 308 lines and 77 in
`tests/portability.bats`, of which 63 were the gate's own controls and awk
source. The fourth occurrence of the stale-tree defect in this change.
disposition: re-measured on the tree the item is recorded in: 245 lines, 135
continuations, 90 guard spellings, 14 in `tests/portability.bats`. The item now
states that the quantities overlap rather than partition, and gives the reason the
earlier figures differ.

**finding-52**: record — the `check-trace.sh` row contained the roll-call total
and the open-problem count, two of the three repository figures
`templates/verification.md` names, and gave no exit status.
disposition: the row now gives the exit status, states that it is unchanged
between base and change, and names only this change's own IDs.

**finding-53**: record — metaphor, anthropomorphism, balanced contrast and
editorializing in prose added after round 4, whose finding-46 disposition stated
"all corrected". No gate reads these paths for anything but the word list.
disposition: all rewritten, in both this record and `PR-x4nb48`.

**finding-54**: record — dispositions for findings 1 to 29 describe, in the
present tense, code that left with the gate.
disposition: a note at the head of the Review section states that those
dispositions describe the revision current when each was closed, and that
`tests/portability.bats` at HEAD is byte-identical to the base.

## Gaps

What this change does not establish:

- **Nothing keeps the 301 assertions guarded.** This change applies the guards
  and removes none of the means to undo them: a later edit can drop one, or add
  an unguarded assertion, and no gate reports it. That is exactly how `650f090`
  added two to the inert population during the change that first recorded the
  defect. `PR-x4nb48` is open for it, and this is the largest gap here.
- **A `!`-negated command has the same defect and nothing covers it.**
  `bash -c 'set -eE; ! grep -q localhost /etc/hosts; echo REACHED'` prints
  `REACHED` although the negation returns 1: POSIX suppresses `errexit` for a
  negated pipeline, so a newer bash does not repair it either. The pattern has
  to be one the file contains, or the negation succeeds and the demonstration
  shows nothing. Ten such assertions are inert in the suite today, nine in
  `tests/skills.bats` and one in `tests/finalize-docs.bats`. Recorded as
  `PR-7za3at`, not repaired here: the rule that catches a negated command is not
  the rule that catches a bracket compound, and another change was editing
  `tests/skills.bats` at the time. Found by a parallel session during review.
- **`tests/helpers.bash` and the `tests/*.sh` helpers were audited by reading
  and by scan, and contain no `[[` at all.** They are therefore clean rather
  than repaired, and nothing in this change would notice if one gained an
  assertion.
- The mutation evidence here is M39 and M90 only. No full mutation run was
  performed; `tests/mutations.bats` reports 7 of 7, which answers whether every
  mutation still applies, not which tests kill it.
- Coverage against the class target was not measured, and no requirement or
  production code was added that would change it.
- The suite figure is one run on one machine. `sh tests/run-tests.sh` was run to
  completion at the tree named above; no second machine and no other bash was
  measured, and bash 3.2 is the only shell whose errexit behaviour this change
  reasons about.
