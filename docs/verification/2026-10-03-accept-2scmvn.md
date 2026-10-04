# Verification — flaky-tmpfile (2026-10-03)

branch: flaky-tmpfile
reviewer: four independent subagents, one per round, each dispatched at
`merge-change` step 6a with the diff, the item and the question of whether the
ruling is sound rather than whether it is well formed, and no account of how
the change was built. Each executed the suite in its own task worktree and
re-measured every static figure; rounds 2, 3 and 4 also executed
`tests/evidence.sh` end to end. Round 4 was dispatched with one additional
instruction — to check every disposition against the tree rather than read it
— because round 3 had found three that were false of it.
verdict: accepted at round 4. Four rounds raised thirty-seven findings and the
project's own gates found two more, thirty-nine in all. Rounds 1 to 3 each
rejected the change. Round 1's three `requirement` findings included the one
that mattered — the narrowing the ruling rested on was false, because
`tests/evidence.sh` reads a spurious failure as proof a defect was fixed.
Round 2 raised no `requirement` and stated that the ruling itself is sound; its
one `code` finding was that two of the five facts the new capture prints were
pinned by no test. Round 3 raised no `requirement` either, agreed the ruling is
sound, and found one `code` defect introduced by round 2's repair along with
three dispositions that claimed repairs never made. Round 4 raised no `code`
finding and no `requirement` finding: it executed both gates at `ba013fc` —
`tests/run-tests.sh` 752 of 752 with plan `1..752`, exit 0, and
`tests/evidence.sh main` exit 0, reporting 3 new tests, 0 going red and 3 that
cannot — re-derived every static figure, and broke the new code seven ways to
confirm that each of the three tests goes red when the behavior it names is broken. Its
eleven findings are all `record`; the material one is that `finding-26`'s
repair reached one of three places, leaving the overshot provenance range in
the permanent disposition and in this record's own `finding-4` entry. All
thirty-nine are dispositioned.
reproduced: no. Six full suite runs across three concurrent lanes in one
worktree were all 749 of 749, exit 0, with the TAP plan equal to the result
count. Six clean runs exclude the observed two-in-four rate at about the 98%
level and do not exclude a per-run rate near 20%, where zero failures in six
has probability 26%. That is a bound, not a proof. Twenty-four further runs of
`tests/check-ids.bats` alone were also clean and are not counted as evidence:
the item already records that configuration as non-reproducing.

Change: `PR-2scmvn` moves from `open` to `accepted` with a disposition, and the
comment in `tests/helpers.bash` that produced its misdiagnosis is corrected.
Branched from `main` at `051becc`; base merged from local `main`, per AGENTS.md
non-negotiable 5.
Plan: none. A ruling plus a comment correction is below the threshold
`plan-change` exists for; `resolve-problem` §2 and §4 are the procedure.

## The gate

Measured on: `57c0a17` — `git rev-parse HEAD` — tree `1bc9945`, from
`git rev-parse HEAD^{tree}`, by a subagent in its own task worktree, which
reported `git status --porcelain` empty before and after every run.
`merge-change` step 3 renamed nothing. Every row below was measured at that
commit. One commit follows it, and that commit writes this paragraph and the
rows below and touches no file any test reads.

The two check scripts were run against scratch copies built with `git archive`,
at the base `051becc` and at the commit above, with a synthesized
`.guardrails/`: `templates/config.yaml` with comments and blank lines removed
and its one `strict_paths` entry changed from `src` to `scripts`; `scripts/*.sh`
copied to `.guardrails/scripts/`; placeholder `docs/requirements`, `docs/risk`
and `docs/architecture` each containing one `.md`; a one-line
`docs/architecture/soup.md`; then `git init` and a commit. Each step is needed
or the script exits 2 and reads nothing.

`check-review.sh` was run against the real worktree and the real git history
instead, because that is what it reads. Guardrails is not ratcheted onto
itself, so there is no `.guardrails/config.yaml` anywhere in this repository
and the script exits 2 without one; it was given `GR_CONFIG` pointing at a
config built by the same recipe, outside the repository, rather than one
written into the worktree, which would have left the tree dirty. Everything
else it read is this worktree: `doc_verification` is absent from that config
and falls back to `docs/verification`, and `gr_base_branch` resolved to `main`.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | 752 of 752, 0 failures, exit 0, TAP plan `1..752`, and no `bats warning:` line. The output is 753 lines, the plan plus 752 results, so plan and results agree. Three more than the base's 749, which are the three tests this change adds |
| `check-ids.sh` | exit 1 at the base and at the change alike, 73 output lines both sides, and `diff` of the two is empty. This change mints no ID |
| `check-trace.sh` | exit 1 at the base and at the change alike. The output is 125 lines at the base and 124 at the change, and `diff` reports three hunks, all this change's own effect: `PR-2scmvn`'s two lines, `UNRESOLVED-PR` and `STALE-PROBLEM`, are replaced by one `ACCEPTED-PR` line with its ruling; `PROBLEM-BACKLOG` 17 to 16; and the summary `open 17, accepted 1` to `open 16, accepted 2`. The gate is exit 1 on both sides: this ruling clears no failure, `PROBLEM-BACKLOG` is over its limit of 10 on both, and `PR-r8q9m7` and `PR-k4t9k2` remain `STALE-PROBLEM` on both |
| `sh tests/evidence.sh main` | exit 0, every guard passed. It reports 3 new tests, 0 going red and 3 that cannot — see below for why that is structural and not a defect |
| `check-review.sh --branch flaky-tmpfile` | exit 0: `records 46, for flaky-tmpfile 1, findings 39`. Provenance is not checked under `--branch`, and the line states so |
| Coverage, against the class target | not measured; this change adds no requirement and no production code |
| Working tree | clean at the commit above, before and after every run |

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| `PR-2scmvn` | `a test that did not complete prints every fact it promises` | yes, five times. Each of the five captured facts was deleted from `gr_failure_environment` in turn and this test failed for every one. Round 2 proved the earlier version of it did not: deleting the `df -i` line or the `tmpdir` line left both tests green |
| `PR-2scmvn` | `the capture reaches a real bats run's output` | yes. Deleting the `inodes` line fails this test as well as the one above, which is why that deletion fails two |
| `PR-2scmvn` | `a completed test prints nothing and releases its directory` | no, and it cannot be against the base. It pins the unchanged half of `teardown`, and goes red only against a mutation of this change itself: removing the added `return 0`, so the capture also runs on a passing test |

An earlier draft of this section stated "no test is added" and that
`tests/helpers.bash` changed by comment only. Both were true of that draft and
are false of this change: `teardown` now calls `gr_failure_environment`, which
is a behavior change to a file every `.bats` file sources, and AGENTS.md's rule
— every behavior change to a script requires a bats test — is met by the two
tests above.

The ruling's own machine-readability is checked separately, by the
`check-trace.sh` row in the gate table: an accepted item without a
`disposition:` is reported `INCOMPLETE-PROBLEM`, and the row shows the item
moving into `ACCEPTED-PR` with its ruling printed.

## What was investigated, and what it showed

`PR-2scmvn` records an intermittent failure of `tests/check-ids.bats`, on a
different test each time, with `error: unable to create temporary file: Invalid
argument` and `failed to insert into database` — git failing to write a loose
object. It attributes this to transient temp-directory pressure.

**That attribution is disproven on this platform.** It rests on a claim in
`tests/helpers.bash` that `/tmp` is a tmpfs with a fixed inode budget and that
three overlapping runs exhaust it. Measured 2026-10-01 on macOS, the host
the fault was observed on and the one AGENTS.md calls a stock box for its
default awk:

- `/tmp` is a symlink to `/private/tmp` on the APFS data volume, and `df -i`
  reports 6,381,565,320 free inodes at 0% used
- bats does not write under `/tmp` at all: `BATS_RUN_TMPDIR` is under `$TMPDIR`,
  which is `/var/folders/…/T/` on the same APFS volume
- `BATS_TEST_TMPDIR` is 71 characters, so no path-length limit is in reach

Nothing this suite does approaches a six-billion-inode budget, and the teardown
that bounds the occupancy is byte-identical from `590867a` (2026-08-27)
to the base `051becc`; this change is what ends the range, by adding the
`gr_failure_environment` call. Two earlier drafts got this wrong in
different ways:
`bd41d7a` is dated 2026-09-02 and is not the tree current on 2026-09-01, and
the repair then claimed `tests/helpers.bash` does not change across the range,
which is false — `git diff --stat 708b8c0 051becc -- tests/helpers.bash` is 163
insertions and 38 deletions. What is byte-identical is the `teardown()`
function alone, measured by hashing its body at each commit. The mitigation for
the named cause was active when the failure occurred; the two claims that it
was are both superseded by this one.

**It did not reproduce.** Two attempts, both at higher load than the original
observation, which was two red runs among four:

| attempt | runs | result |
|---|---|---|
| `tests/check-ids.bats`, three concurrent lanes | 24 | all clean |
| `sh tests/run-tests.sh`, three concurrent lanes, back to back | 6 | 749 of 749, exit 0, plan equal to count, every run |

The second is the condition the item describes — a run "started immediately
behind another full suite in the same worktree" — at three concurrent lanes
rather than one, and it occupied about 4.8 hours of contention. An earlier
draft called that "roughly four times its load"; the figure was never derived
and is withdrawn. Three lanes is three.

**Two further leads were closed.** A read-only object directory reproduces
`failed to insert into database` but not `Invalid argument`, so the second line
is a generic follow-on and the first is what identifies the cause. And
`tests/check-ids.bats` creates no filename containing a non-ASCII byte or an
escape sequence, so an APFS rejection of an invalid name does not explain why
the failures clustered there.

**The item's conclusion was narrowed, wrongly, and the narrowing is withdrawn.**
The item states that a suite green on two of four runs "makes every `0 failures`
in this repository's verification records a probabilistic claim". An earlier
draft of this record answered that a fault of this class makes a run falsely RED
rather than falsely green, so it costs a run and not the integrity of a verdict.
An independent reviewer refuted that, and it is wrong.

Half of it is true: bats aborts a test body on a mid-body failure, and detects a
short-counted plan on its own — reproducible directly, a file whose TAP plan
declares three tests and which emits two gives `bats warning: Executed 2 instead
of expected 3 tests` and exit 1. An earlier draft cited a 740-of-742 observation
from another change instead; that figure describes a worktree whose base had not
been merged, which the draft did not state, so it was not checkable as cited.

The other half inverts. `tests/evidence.sh` computes its red figure as
`red = new - green`, where `green` is the new tests appearing in the PASS list
(`:142-152`). A test that fails for an environmental reason is therefore absent
from the pass list, counted into `red`, and reported as a test that goes red
against the base — which is the figure ten merged records quote as evidence a
defect was fixed. It also drops off the `green` list, the one a reader uses to
catch tests that prove nothing. All five of that script's guards — scripts
checked out from the base, a TAP plan emitted at all, plan against submitted,
results against plan, and names against measured — were built against truncated
runs, and every one of them is satisfied by a run that completes with a
spurious failure in it. A mutation kill table inverts the same way, which the corrected comment
in `tests/helpers.bash` states eight lines from where the earlier draft denied
it.

So the item's original conclusion is closer to right than the narrowing allowed,
and this change answers it rather than disputing it: `tests/helpers.bash`
now prints the failed test's environment, so a recurrence is identifiable in
the run that contains it instead of depending on who reads the log.

### What `tests/evidence.sh` reports for this change

Measured, exit 0: three new tests, zero going red against `main`, and all three
listed as tests that cannot go red. That is structural rather than a defect: `evidence.sh`
substitutes `scripts/` from the base and copies `tests/` from the working tree,
so a change whose production code is `tests/helpers.bash` is invisible to it
and its red figure is necessarily zero. The red → green rows above are the
evidence instead, obtained by deleting each captured fact in turn and watching
a test fail for each.

A record that spends a section on that script's red figure has to say what the
script reports about itself, which an earlier draft did not.

## Review

Rounds 1 to 4 are recorded in order, with two defects the author found between
rounds 2 and 3. A round raising no `code` and no `requirement` finding is the
last; rounds 1 to 3 each raised at least one, and round 4 raised neither.


Round 1. One reviewer, dispatched with the diff, the item and the question of
whether the ruling is sound rather than whether it is well formed. It executed
the suite itself (749 of 749 at the tree it measured), re-measured every static
figure, and raised eight findings. Three are `requirement`.

It also tested the suspicion it was dispatched with — that accepting an item
already reporting `STALE-PROBLEM` turns a red gate green — and refuted it:
`check-trace.sh` is exit 1 at the base and at the change alike, two other items
remain `STALE-PROBLEM`, and `PROBLEM-BACKLOG` is still over its limit.

**finding-1**: requirement — the narrowing the ruling rested on is false.
`tests/evidence.sh` computes `red = new - green` from the PASS list, so a test
failing for an environmental reason is counted as proof a defect was fixed and
drops off the list of tests that cannot go red; ten merged records quote a
figure derived that way. All five of that script's guards were built against
truncated runs and are satisfied by a run completing with a spurious failure. A mutation kill table
inverts the same way — which this change's own corrected comment states eight
lines from an earlier draft that stated the opposite.
disposition: the narrowing is withdrawn from both the disposition and this
record, and replaced with the mechanism above. The ruling now accepts the item
with that understanding recorded, and the change adds the capture the reviewer
proposed in place of it: `tests/helpers.bash` prints five labelled facts —
`tmpdir`, `testdir`, `inodes`, `blocks` and `openfiles` — on any test that did
not complete, with three tests pinning them.

**finding-2**: requirement — the corrected comment removed an unmeasured macOS
claim and installed an unmeasured Linux one in the same register, and the
reviewer's arithmetic put the real tmpfs ceiling at roughly thirty-five
concurrent runs rather than "a few".
disposition: the Linux figure is withdrawn. The comment now states what was
measured, on which platform and on which date, and states plainly that no other
host was tested.

**finding-3**: requirement — "thirty runs" counted twenty-four runs of
`tests/check-ids.bats` alone, a configuration `PR-2scmvn` itself records as
non-reproducing.
disposition: the figure is six, and both the disposition and this record now
state what six bounds — the observed two-in-four rate excluded at about 98%, a
20% rate not excluded, zero failures in six having probability 26%.

**finding-4**: record — `bd41d7a` is dated 2026-09-02 and was cited as the tree
current on 2026-09-01.
disposition: corrected twice. The first repair named `860dce4` and claimed the
file does not change across the range, which round 2 showed false — 163
insertions and 38 deletions. The anchor is `590867a` (2026-08-27) and the scope
is the `teardown()` function, whose body hashes identically at every commit
from there to the base `051becc`, which this change ends.

**finding-5**: record — "roughly four times its load" was never derived; three
lanes is three.
disposition: withdrawn, and the correction stated.

**finding-6**: record — the 740-of-742 short-count citation describes a
worktree whose base had not been merged, which the record did not state, so it
was not checkable.
disposition: replaced with a reproduction anyone can run — a plan of three with
two results gives `bats warning: Executed 2 instead of expected 3 tests`.

**finding-7**: record — `hold` on an added line, in the file the automated scan
does not cover.
disposition: corrected, along with four more the author's own sweep found
afterwards in the same unscanned file.

**finding-8**: record — three gaps existed and were unstated: no logs and a
single witness, the weakness of "no record reports a recurrence", and the
reproduction using a 749-test suite where the failure was in a 438-test one.
disposition: all three added, and `Gaps` grew from four entries to eight.

Round 2. A second reviewer, dispatched against the repaired tree, executed the
suite (751 of 751 at the tree it measured) and `tests/evidence.sh` end to end,
and raised nine findings. One is `code`; none is `requirement`, and it stated
explicitly that the ruling itself is sound.

**finding-9**: code — two of the five facts the capture prints were pinned by
no test. Proven by deleting each: removing the `df -i` line, or the `tmpdir`
line, left both tests green. `df -i` is the fact aimed at the cause the item
names, and it could be removed in silence. A third assertion could not fail
independently, because `*"TMPDIR="*` was satisfied by the `BATS_TEST_TMPDIR=`
line another assertion already required.
disposition: every fact now prints on its own labelled line — `tmpdir`,
`testdir`, `inodes`, `blocks`, `openfiles` — and each has its own assertion.
Re-measured by deleting each in turn: all five are now caught, and `inodes`
fails two tests. `blocks` is new, because `df -i` prints inode columns only on
Linux and a shortage of bytes would otherwise be invisible there.

**finding-10**: record — "three merged records quote that figure" was wrong.
disposition: corrected twice, and the account of the second correction was
itself wrong until round 4 measured it. The first repair gave nine, from a
pattern requiring the bold immediately before "go red". That pattern missed one
record, not two: `2026-08-19-id-consistency` (19, in a gate row naming
`tests/evidence.sh main`). `2026-08-20-scan-pathspec` (8) was already among the
nine, because it states the figure twice and one of the two is bolded. The
criterion is "quotes a non-zero red figure as evidence a defect was fixed",
which is narrower than the phrasing this disposition first used. Ten, and round
4 re-derived ten independently. Both the record and the permanent disposition
state ten.

**finding-11**: record — the repair for round 1's `finding-4` replaced a wrong
date with a false claim: `tests/helpers.bash` does change across the range
cited, by 163 insertions and 38 deletions. Only `teardown()` is byte-identical.
disposition: corrected and scoped. The anchor is `590867a` (2026-08-27),
measured by hashing the function body at each commit, which is earlier than
either commit previously named. Both superseded claims are recorded in place.

**finding-12**: record — `says plainly` on an added line, introduced by the
commit after the word sweep, plus five anthropomorphisms and an unmeasured
claim that the capture's facts "cost a syscall each" — false, since `df` is a
fork and exec.
disposition: all corrected. The syscall claim is removed rather than rephrased.

**finding-13**: record — "the platform AGENTS.md names for this suite"
misattributes it. AGENTS.md names four supported awk implementations and
states only that BWK awk is the default on a stock macOS box; two of the four
are Linux. It requires macOS to work among others, and does not name it as the
platform.
disposition: reworded in all three places to state what AGENTS.md states and
what was actually measured.

**finding-14**: record — the gate section was anchored at a commit that was no
longer the tip.
disposition: re-anchored, and the paragraph now states that the only later
commit writes the record itself.

**finding-15**: record — `tests/evidence.sh` reports 0 of the new tests going
red, and the record did not say so.
disposition: a section states it and why it is structural: `evidence.sh`
substitutes `scripts/` from the base and copies `tests/` from the working
tree, so a change whose production code is `tests/helpers.bash` is invisible
to it. The script was then run end to end here, exit 0, and is a gate row.

**finding-16**: record — "every guard that script has" named three of five.
disposition: all five named. The conclusion is unchanged: all five are
satisfied by a run that completes with a spurious failure in it.

**finding-17**: record — five gaps existed and were unstated.
disposition: all five addressed, four by a `Gaps` entry and one in the capture
itself. The four stated are that the capture does not by itself discriminate
this fault, that the six reproduction runs are anchored to no commit, that
nothing proved the capture reaches a bats run, and that the disposition
misdescribed the condition the six runs were made under. The fifth — that
`df -i` prints no block usage on Linux, so a shortage of bytes would be
invisible there — was repaired rather than recorded, by adding the `blocks`
fact. This disposition read "all five added" until round 4 counted the entries
that commit wrote: four.

Two further defects were found by the project's own gates after round 2's
repairs, and are recorded here because no reviewer raised them.

**finding-18**: code — the new through-bats test built its probe with a
heredoc whose body put `@test` at column one. `tests/evidence.sh` counts tests
with `grep -c '^@test'`, so it counted that line as a fourteenth test in
`tests/portability.bats` and exited 2 at `base run planned 721 tests, expected
722`. This is the same column-one-inside-a-heredoc defect `PR-tenhv4`'s change
recorded at `tests/check-trace.bats:1739`, reproduced in a test written to
make evidence more reliable.
disposition: the probe is built with `printf`, so the token never appears at
column one in the source. The comment states why. `tests/evidence.sh` now
exits 0.

**finding-19**: code — `survive` on an added line in `tests/portability.bats`,
caught by the suite's own writing scan. The author's manual sweep missed it
because the word list used was `survives` and `survived` and not the bare
stem.
disposition: corrected. The lesson is that the manual sweep is weaker than the
scan wherever the scan reaches, and `docs/verification` is the only file here
it does not reach.

Round 3. A third reviewer, dispatched against the repaired tree and told that
its first duty was to find defects in the repairs, executed the suite (752 of
752) and `tests/evidence.sh` (exit 0) end to end and raised nine findings. One
is `code`; none is `requirement`, and it agreed with round 2 that the ruling is
sound.

**finding-20**: code — the through-bats test hard-coded
`$BATS_TEST_DIRNAME/.bats-core/bin/bats`. `tests/run-tests.sh` uses a system
bats when one is on PATH and only then vendors `tests/.bats-core`, which is
gitignored, so on any host with bats installed the directory never exists and
the test fails — reporting "the capture did not reach the run output", which
names the wrong cause, in a test added to make a spurious red diagnosable.
disposition: the runner is discovered with
`command -v bats || echo "$BATS_TEST_DIRNAME/.bats-core/bin/bats"`, the idiom
`tests/evidence.sh:86` already uses, with a comment stating why.

**finding-21**: record — round 2's `finding-13` disposition claimed the
AGENTS.md misattribution was "reworded in all three places". Two of the three
still contained it.
disposition: both corrected. The cause is recorded under `finding-28`.

**finding-22**: record — round 2's `finding-12` disposition claimed the syscall
claim was "removed rather than rephrased". It was still in the tree.
disposition: removed. Same cause.

**finding-23**: record — round 2's `finding-16` disposition claimed "all five
named". Three were named, in both places.
disposition: all five named in both. Same cause.

**finding-24**: record — the capture prints five facts and "four" remained in
four places, contradicting this record's own "five lines" and "watched red five
times". `blocks` is the fact round 2's repair added, so the stale count was a
product of that repair.
disposition: all four corrected, along with "two tests pinning both halves"
where the change adds three.

**finding-25**: record — "nine merged records quote a figure derived that way"
is ten under the criterion the disposition itself states.
disposition: corrected to ten in both places, with the method and the two extra
records named. This figure has now been measured three times and been wrong
twice; the third measurement lists every file.

**finding-26**: record — the provenance range overshot its endpoint. This
change is what ends it, by adding the `gr_failure_environment` call, so
"byte-identical … through this change" is false at the endpoint.
disposition: the range now ends at the base `051becc`, and states what ends
it. Round 4 found the repair had reached one of the three places; the other
two are `finding-29`.

**finding-27**: record — the capture does not fire for 90 of the 752 tests.
`tests/mutations.bats` (7) and `tests/skills.bats` (83) contain no
`load helpers`, so no `teardown` is defined for them. That matters here
specifically: the mutation runner is the consumer the ruling's own argument
rests on.
disposition: stated in `Gaps` rather than repaired. Adding `load helpers` to
those files would also give them the directory-removing teardown, which is a
behavior change to two files this change otherwise does not touch.

**finding-28**: record — three rhetorical constructions on added lines.
disposition: all three rewritten. The cause of `finding-21`, `finding-22` and
`finding-23` is recorded here because it is one cause, not three: the edits
were applied with a replace that returns silently when its anchor does not
match, and one of them was applied to two files where the finding named three.
Every edit in this round asserts its anchor first and is verified afterwards by
searching for the text it was supposed to remove. That is the practice
`silent-substitution-false-dispositions` names, applied late.

Round 4. A fourth reviewer, dispatched against the repaired tree and told that
its first duty was to check all twenty-eight dispositions against the tree
rather than to read them, because round 3 had found three that were false of
it. It executed both gates in its own task worktree — `tests/run-tests.sh`,
plan `1..752`, 752 ok, 0 not ok, exit 0, and `tests/evidence.sh main`, exit 0,
reporting 3 new tests, 0 going red and 3 that cannot — re-derived every static
figure, and broke the new code seven ways to confirm that each of the three
tests goes red when the behavior it names is broken. It raised eleven findings. None is
`code`, none is `requirement`, and it agreed with rounds 2 and 3 that the
ruling is sound. By the rule above, it is the last round.

Twenty-five of the twenty-eight dispositions it checked are true of the tree.
The three that are not are `finding-29` to `finding-31`.

**finding-29**: record — `finding-26`'s repair reached one of three places. The
overshot provenance range remained in
`docs/problems/2026-09-03-signing-diagnosis.md`, which is the permanent
artifact, and in this record's own `finding-4` entry. Re-measured by hashing
the `teardown()` body at each commit with `git show "${c}:tests/helpers.bash"`:
identical at `590867a`, `31e2303`, `708b8c0`, `860dce4`, `3fe5eb3`, `0a35669`,
`8d78cd4` and `051becc`, and different at this change.
disposition: both corrected. This is the fourth disposition in this change to
claim a repair that was not made, and the third consecutive round to find one.

**finding-30**: record — the account of how nine became ten is wrong.
`2026-08-20-scan-pathspec` was never missed: it states the figure in two places
and one of them is bolded, so the first pattern already matched it. One record
was missed, not two. The criterion as literally written also admits a record
whose red figure is 0.
disposition: corrected, and the criterion narrowed to the one meant. The figure
ten is unchanged — round 4 re-derived it independently, naming all ten.

**finding-31**: record — `finding-17`'s disposition states "all five added".
The commit that answered round 2 added four `Gaps` entries: the section went
from 8 to 12.
disposition: corrected. Round 2's fifth gap — that `df -i` prints no block
usage on Linux — was repaired in the capture rather than recorded, by adding
the `blocks` fact. All five were addressed; four were added.

**finding-32**: record — four replaced words on added lines in this record:
"carries", "carried", "survived" and "says". `tests/` and `docs/problems/` are
clean against the same list.
disposition: all four corrected. This is the fourth consecutive round to find
replaced words in this file and only in this file, at one, six, three and four
per round. `gr_writing_paths` in `tests/skills.bats` does not list
`docs/verification`, so the only check on it is a manual sweep, which has now
been run four times and has not converged. Extending that list is a change to
the scan's scope and is not made here.

**finding-33**: record — round 3's repair for `finding-23` left a subject-verb
break: "All five of that script's guards … were built against TRUNCATED runs
and is satisfied by …", with one word in upper case where the same sentence
elsewhere in this record sets it in lower.
disposition: corrected. The five guards themselves are named correctly; round 4
checked each against `tests/evidence.sh`.

**finding-34**: record — `tests/portability.bats` still described its
`PR-2scmvn` section as "These two tests" where the section contains three.
`finding-24`'s repair corrected the record's copy of that phrase and left the
test file's.
disposition: corrected, and the sentence now names what the third test pins.

**finding-35**: record — the gate paragraph was stale after the re-anchoring.
It stated that the only commit after the anchor writes the rows below and the
Review section; that commit writes one line, and the rows were written by the
anchor commit itself.
disposition: re-measured at the tree this round produced, and the paragraph now
states what each commit after the anchor writes.

**finding-36**: record — the `Gaps` entry for the 90 uncovered tests overstates
itself. The mutation kill procedure runs the whole suite once per mutation, so
662 of the 752 do print the capture.
disposition: corrected to name what is uncovered, which is a spurious failure
inside `tests/mutations.bats` or `tests/skills.bats`.

**finding-37**: record — two gaps unstated. (a) The capture is reachable only
from the per-test `teardown`, so a run terminated between tests prints nothing,
and that is the scenario `tests/helpers.bash` describes and close to the one
the item was opened about. (b) `skip` leaves `BATS_TEST_COMPLETED` empty, so
every skipped test would run `gr_failure_environment`.
disposition: (a) is added to `Gaps` and is the more serious of the two — the
capture covers a test that fails, not a run that is terminated. (b) is refuted. bats
assigns `BATS_TEST_COMPLETED=1` inside `skip` itself
(`tests/.bats-core/lib/bats-core/test_functions.bash:465`) before it exits, so
the teardown reads 1 and takes the early return. Measured directly with a probe
containing a skipped, a passing and a failing test, logging the value from its
own `teardown`: `[1]`, `[1]` and `[UNSET]`. The reviewer's probe read the
variable inside the skipped body, which is before `skip` assigns it.

**finding-38**: record — `tests/helpers.bash` kept an unmeasured total on a
line this change rewrites: a full-suite run "occupies roughly sixty thousand
inodes for its entire duration". It was written when the suite had 400 tests
and the suite now has 752, and it describes an occupancy that the teardown
described two paragraphs below it prevents.
disposition: the total is removed rather than recalculated. The per-fixture
figure is the measured one; the comment now states what remains at any moment
and that the implied total moves with the test count.

**finding-39**: record — the permanent disposition stated that the six runs
were made under "the condition the observation below describes", which is
false, and only this record's `Gaps` recorded the difference. A statement known
to be false was left standing in the artifact that outlives this record.
disposition: the disposition now states the difference itself — three
concurrent lanes is a heavier condition than one run started immediately behind
another — and the `Gaps` entry is removed, because it no longer describes a
gap.


## Gaps

- **The fault is unexplained, not absent.** Six clean runs do not prove a
  seventh would be clean, and no mechanism for the observed `EINVAL` was found.
  The ruling is that the search stops, not that the fault cannot recur. What
  bounds the risk now is the capture, not the evidence.
- **The capture is untested against the real fault.** It prints five facts that
  would have identified a temp-file failure, chosen by reasoning about the
  error rather than by observing one. No fault was injected to confirm they are
  the facts that discriminate.
- **Nobody re-derived the runs.** The six full suites, the twenty-four shorter
  runs and the two closed leads were measured by the author who reports them;
  no log of them is in the tree, and the reviewer could check none of them. The
  reviewer did re-measure every static figure and executed the suite itself.
- **"No verification record reports a recurrence" is weak and is not offered as
  more.** A verification record documents the final green gate, so a red
  intermediate run that was simply re-run leaves no trace in one. The absence
  is close to guaranteed by the genre.
- **The reproduction used a different suite from the one that failed.** The
  2026-09-01 failure was in a 438-test suite; these attempts used the 749-test
  tree. That is more load, and also different fixtures and code paths. It is
  not the same experiment.
- **Only this machine was measured.** Every figure here is from one macOS host
  on APFS. Where `$TMPDIR` is a tmpfs the budget is finite and the original
  reasoning may apply; no such host was tested, and the corrected comment states
  that rather than asserting a figure for it.
- **The original conditions cannot be re-created.** The failure was observed on
  2026-09-01, against a tree in which `tests/helpers.bash` was already what it
  is today; whatever was true of that machine at that hour is not recoverable,
  so an environmental trigger specific to it cannot be ruled out or in.
- **The capture does not reach 90 of the 752 tests.** `tests/mutations.bats`
  (7) and `tests/skills.bats` (83) do not `load helpers`, so no `teardown` is
  defined for them and nothing is printed when one of their tests fails. The
  mutation kill procedure runs the whole suite once per mutation, so 662 of the
  752 do print the capture; what is uncovered is a spurious failure inside
  those two files.
- **Two other items are past `problem_age_days`.** `PR-r8q9m7` and `PR-k4t9k2`
  report `STALE-PROBLEM` against the synthesized config this repository is
  probed with, at the base and at this change alike. Both are out of scope here
  by the maintainer's instruction, to be addressed after this change is merged.
- **The capture does not by itself discriminate this fault.** Its five lines
  print identically for every failing test. What identifies a temp-file
  failure is the failing command's own stderr, which bats already printed on
  2026-09-01 and which the item quotes. `tmpdir` and `testdir` bear on the
  observed `EINVAL`, since path validity and length were the leads; `inodes`,
  `blocks` and `openfiles` address causes this change disproves and will read
  normal on the measured host. The capture makes a recurrence cheaper to
  diagnose; it does not diagnose one.
- **The six reproduction runs are anchored to no commit.** Every gate figure in
  this record names the tree it was measured on. Those runs do not: they were
  made on a 749-test tree that is not this tree and did not contain the
  capture.
- **The capture is reachable only from the per-test `teardown`.** It fires for
  a test that fails. A run terminated between tests prints nothing — which is
  the scenario the comment this change keeps still describes
  in `tests/helpers.bash`, where a redirect fails with ENOSPC and bats
  short-counts the plan. That is close to the scenario the item was opened
  about, and the capture does not reach it.
- **Nothing proves the capture reaches a bats run through the suite's own
  helpers.** The through-bats test writes its own probe file and loads
  `helpers` by absolute path, which is not how the suite's files load it.
