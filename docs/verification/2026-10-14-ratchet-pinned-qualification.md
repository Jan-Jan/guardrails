# Verification — ratchet-pinned-qualification (2026-10-14)

branch: ratchet-pinned-qualification
reviewer: independent Claude subagents with fresh context, one per round,
each in its own review worktree off the change branch, given the diff,
AGENTS.md, the plan, the claimed items and
`skills/merge-change/references/review-checklist.md`, and running the suite
themselves; conformance reviews ran in fresh contexts of their own against
`docs/TEST_GUIDELINES.md`, `docs/CODE_GUIDELINES.md` and
`docs/ARCHITECTURE_GUIDELINES.md`
verdict: converged at round 5 — no `code` or `requirement` finding above low
in that round, which makes it the last. Every round found the change does
what PR-y8ff5p, PR-783b29, PR-ww36qr and plan decisions D1–D4 need. Round 2's
medium finding, that step 5's own command made every qualification run fail,
was fixed and confirmed by following steps 0 and 5 literally; round 4's, that
nothing tested the helper's promise to leave the real index alone, was fixed
by a test that the mutation reddens. Round 5's mutations of the runner and
helper were killed but one, whose low finding is fixed.
reproduced: yes. PR-y8ff5p: before the runner change, "run-tests: a tree
changed during the run fails the run, though every test passed" and "run-tests:
a commit made during the run fails the run" both failed with status 0 passed
through `exec`, the adopter's mixed-tree run in miniature. PR-783b29: "install:
--copy records the checkout in every copied skill" failed on the unchanged
install.sh with "no .guardrails-source in analyze-risks". PR-ww36qr: measured
directly, `zsh -c 'false; status=$?; echo after'` prints
`zsh:1: read-only variable: status`, exits 1 and never prints `after`.

Change: a `/ratchet` qualification run describes exactly one commit — step 0
clones the guardrails checkout and every copy and the suite read the clone,
and `tests/run-tests.sh` names the commit it tests and fails a run whose tree
moved — while step 0 finds the checkout of an `install.sh --copy` install and
step 5 captures the exit status in `rc`. Resolves PR-y8ff5p, PR-783b29 and
PR-ww36qr; opens PR-v6mcvt and PR-92mbhq.
Plan: `docs/plans/2026-10-14-ratchet-pinned-qualification.md`.

## The gate

The gate's figures are not in this record. This change's squash commit carries
them as trailers (`merge-change` step 7): `Gate-tree:`, the `Gate:` line and
`Base:`.

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| `PR-y8ff5p` | `run-tests: a clean checkout names the commit it tests` | failed with no `run-tests:` line on stderr |
| `PR-y8ff5p` | `run-tests: a modified checkout says the run tests no commit, and still runs` | failed with no "differs from commit" line; later its exact-path assertion failed while the stub got the unexpanded glob |
| `PR-y8ff5p` | `run-tests: an untracked file makes the working tree differ from the commit` | as above |
| `PR-y8ff5p` | `run-tests: a tree changed during the run fails the run, though every test passed` | failed: status 0 passed through `exec` |
| `PR-y8ff5p` | `run-tests: a commit made during the run fails the run` | failed: status 0 passed through `exec` |
| `PR-y8ff5p` | `run-tests: a failing suite keeps its own status when the tree also changed` | failed: no "tree changed during the run" line |
| `PR-y8ff5p` | `run-tests: outside a git checkout the commit tested is unknown` | failed with no "commit tested is unknown" line |
| `PR-y8ff5p` | `run-tests: a runner nested in another repository's tree finds no checkout of its own` | failed with no "commit tested is unknown" line |
| `PR-y8ff5p` | `run-tests: a git that fails before the run leaves the suite's own status, and the commit tested is unknown` | failed only on the missing "git add -A failed" line, with the report silenced |
| `PR-y8ff5p` | `run-tests: a git that fails after the run is reported, and fails a passing run` | as above |
| `PR-y8ff5p` | `run-tests: a tracked file that .gitignore matches leaves a clean checkout testing its commit` | failed: "the working tree differs from commit …" |
| `PR-y8ff5p` | `run-tests: an ignored untracked file leaves a clean checkout testing its commit` | passed first; red shown with `add -A --force`, then restored |
| `PR-y8ff5p` | `ratchet: step 0 clones the checkout before reading it, and finds it through .guardrails-source` | failed: "step 0 does not read .guardrails-source" |
| `PR-y8ff5p` | `ratchet: the qualification log must name the recorded commit` | failed: "the skill does not name the testing-commit line" |
| `PR-y8ff5p` | `ratchet: the upgrade notes say the checkout is cloned and the suite names its commit` | failed: "no upgrade-notes section" |
| `PR-y8ff5p` | `ratchet: step 0 clones into a temporary directory outside the project, removed afterwards` | failed before the step 0 edit |
| `PR-y8ff5p` | `ratchet: a qualification log line describes no commit only when it begins run-tests:` | failed before the step 5 and upgrade-note edits |
| `PR-y8ff5p` | `ratchet: the rationale lists every line the runner says about what it tested` | failed before the rationale edit |
| `PR-y8ff5p` | `ratchet: step 5 writes the qualification log outside the clone` | failed: "step 5 writes the log into the current directory" |
| `PR-y8ff5p` | `ratchet: step 5 does not both run the suite exactly once and run it again` | failed: "step 5 still says exactly once" |
| `PR-y8ff5p` | `run-tests: a checkout whose HEAD names no commit says so, and the commit tested is unknown` | failed: got "no git checkout found" |
| `PR-y8ff5p` | `run-tests: a git that fails reading HEAD's tree is reported, and the commit tested is unknown` | failed: the runner printed "differs" |
| `PR-y8ff5p` | `run-tests: without git on PATH the commit tested is unknown` | red with exit 1 forced at the helper's toplevel check |
| `PR-y8ff5p` | `run-tests: the checkout's own index is left as it was, staged and unstaged changes alike` | passed first; red with `GIT_INDEX_FILE` removed from the helper, then restored |
| `PR-y8ff5p` | `run-tests: a mktemp that fails is reported in its own words, and the commit tested is unknown` | passed first; red under two mutations of the mktemp line, then restored |
| `PR-y8ff5p` | `run-tests: the fingerprint helper leaves nothing in TMPDIR` | failed with the cleanup removed, once the helper's mktemp used a template under `TMPDIR` |
| `PR-783b29` | `install: --copy records the checkout in every copied skill` | failed: "no .guardrails-source in analyze-risks" |
| `PR-783b29` | `install: a linked install writes nothing into the checkout` | passed first; red shown against a first implementation that wrote the file in both modes |
| `PR-ww36qr` | `ratchet: the suite's exit status is captured in rc, never in zsh's read-only status` | failed: "the skill does not capture rc" |

## What was wrong, and what was built

An adopter's `/ratchet` upgrade ran the qualification suite in the live
guardrails checkout for 19 minutes, during which a commit landed there. The
suite read files mid-edit, reported three failures that neither commit has,
and the record named the earlier commit as qualified. Nothing in the runner
or the skill could tell. The same report found step 5's `status=$?` fails in
zsh (PR-ww36qr, already open) and that step 0 cannot find the checkout after
`install.sh --copy`.

`tests/run-tests.sh` now runs `tests/fingerprint-tree.sh` before and after
bats; the helper prints `HEAD` and a tree object of every file git tracks or
does not ignore, written from a temporary index seeded from `HEAD`. It prints on standard error `run-tests: testing commit
<sha>`, or that the working tree differs from that commit, or that the commit tested
is unknown, as when no git repository is found, and reports a git failure by the command that failed. A run whose
fingerprint changed fails with `run-tests: the working tree changed during the run`,
even when every test passed; a failing suite keeps its own status. The
suite's own full run changes nothing in the tree, which the gate confirms each
time it prints only the testing-commit line.

`ratchet` step 0 reads the checkout from `.guardrails-source`, which
`install.sh --copy` now writes into each copied skill, else from two levels
above the SKILL.md, and clones it to `<tmp>/guardrails` in a temporary
directory outside the project. Every copy and the suite read the clone. Step 5
writes the log to `<tmp>/ratchet.log`, outside the clone the runner
fingerprints, captures the status in `rc`, and requires the log to carry the
testing-commit line, a run with any other line beginning `run-tests:` being
run again. `references/rationale.md` and `references/upgrade-notes.md` carry
the reasons and the upgrade steps; SKILL.md stays within 2,000 words.

## Review

Round 1 reviewed the change at the first `review dispatched` commit. Step 1
then merged local `main`, whose architecture-guidelines change also edited
`skills/ratchet/SKILL.md`, `skills/ratchet/references/upgrade-notes.md` and
`tests/skills.bats` (the `shared:` files), so round 2 reviewed the whole
change again.

### Round 1

**finding-1**: code, low — the fingerprint's fresh temporary index skips a
tracked file that is also ignored, so a clean checkout holding one always
reports that the working tree differs, and no run would qualify.
disposition: the index is seeded from `HEAD` before `add -A`, now in
`tests/fingerprint-tree.sh`; reddened by "run-tests: a tracked file that .gitignore matches leaves a clean checkout testing its commit".

**finding-2**: requirement, low — TAP test names contain `run-tests:`, so
step 5's "any other `run-tests:` line" matches them; the rationale's list
omitted the git-failure line.
disposition: step 5 and the upgrade note say a line beginning `run-tests:`,
and `skills/ratchet/references/rationale.md` lists the git-failure line;
pinned by "ratchet: a qualification log line describes no commit only when it
begins run-tests:" and "ratchet: the rationale lists every line the runner
says about what it tested".

**finding-3**: requirement, low — step 0 did not say where the clone goes or
that it is removed, so nothing stopped a clone inside the target project.
disposition: step 0 in `skills/ratchet/SKILL.md` clones into a temporary
directory outside the project, removed when the ratchet is done; pinned by
"ratchet: step 0 clones into a temporary directory outside the project,
removed afterwards".

**finding-4**: record — the plan's T3 said the upgrade note tells an old
`--copy` install to re-run `install.sh --copy`; the shipped note says to
delete the copied directories first, which is right, since install.sh skips
an existing directory.
disposition: the deviation is recorded beside the round 1 findings in
`docs/plans/2026-10-14-ratchet-pinned-qualification.md`.

### Round 2

**finding-1**: requirement, medium — step 5's command,
`tests/run-tests.sh > ratchet.log 2>&1`, run from inside the clone, writes an
untracked log into the tree the runner fingerprints, so every run reports that
the tree differs and changed during the run, and "run it again" fails the
same way; the log is also deleted with the clone.
disposition: step 5 writes the log to `<tmp>/ratchet.log`, outside the clone,
and keeps it, in `skills/ratchet/SKILL.md`; reddened by "ratchet: step 5
writes the qualification log outside the clone". Round 3 ran steps 0 and 5
literally and got the testing-commit line with rc 0.

**finding-2**: requirement, low — step 5 said to run the suite "exactly once"
and, six lines later, to run it again.
disposition: step 5 now records one qualifying run per update; reddened by
"ratchet: step 5 does not both run the suite exactly once and run it again".

### Round 3

**finding-1**: requirement, low — the log is kept at `<tmp>/ratchet.log`,
inside the temporary directory the operating system may purge, and nothing
says where it should live durably.
disposition: recorded as PR-v6mcvt; where an adopter's repository should keep
the log is a decision, not a mechanical fix.

**finding-2**: requirement, low — step 0 says nothing for a
`.guardrails-source` naming a directory that moved, and its fallback is wrong
for a copy.
disposition: recorded as PR-92mbhq.

**finding-3**: record — the reviewer's own full run exited 1 on one timeout,
`new-id: a FIFO is rejected rather than read`, under four concurrent suites; it
passes alone, and this change touches neither the test nor the script.
disposition: no change — the gate of this tree ran in the change worktree, and
its figures are the squash commit's trailers; the timeout is noted under Gaps
in `docs/verification/2026-10-14-ratchet-pinned-qualification.md`.

### Round 4

Round 4 reviewed the whole change again after the conformance reviews split
the fingerprint into `tests/fingerprint-tree.sh`.

**finding-1**: code, medium — no test pins the helper's promise that the
repository's own index is left as it was; with `GIT_INDEX_FILE` removed from
`fingerprint_git` every runner test passed, while the helper discarded staged
work and staged the whole tree.
disposition: reddened, under exactly that mutation, by "run-tests: the
checkout's own index is left as it was, staged and unstaged changes alike";
the helper's code was already right.

**finding-2**: code, low — the helper's mktemp-failure path has no test.
disposition: reddened by two mutations of the helper's mktemp line, by
"run-tests: a mktemp that fails is reported in its own words, and the commit
tested is unknown".

**finding-3**: code, low — `tests/fingerprint-tree.sh` was committed without
its executable bit, unlike the other `tests/*.sh`.
disposition: `tests/fingerprint-tree.sh` is mode 100755.

**finding-4**: record — plan D2 quoted the runner's messages as first
written, not as shipped.
disposition: D2 in `docs/plans/2026-10-14-ratchet-pinned-qualification.md`
carries a note naming the shipped wording.

**finding-5**: record — this record described the no-checkout message as
first written, listed one test twice, and cited a test by its former name.
disposition: corrected in
`docs/verification/2026-10-14-ratchet-pinned-qualification.md`.

**finding-6**: record — round 1's finding-1 disposition placed the
HEAD-seeded index in the runner, and the verdict named round 3 as the last.
disposition: corrected in
`docs/verification/2026-10-14-ratchet-pinned-qualification.md`.

### Round 5

**finding-1**: code, low — the helper's removal of its temporary directory is
seen by no test, and an interrupted run leaves the directory behind.
disposition: `tests/fingerprint-tree.sh` makes its directory from an
explicit template under `TMPDIR`, since BSD `mktemp -d` ignores `TMPDIR`, and
removes it from an EXIT, INT and TERM trap; reddened by "run-tests: the
fingerprint helper leaves nothing in TMPDIR".

**finding-2**: requirement, low — the upgrade's copy step does not name
`<guardrails>` as its source, as step 2 does.
disposition: the upgrade's copy step in `skills/ratchet/SKILL.md` copies
"from `<guardrails>`"; pinned by "ratchet: the guardrails source is named the
checkout or the clone, never the guardrails repo".

**finding-3**: record — four CODE dispositions cited `tests/run-tests.sh` for
code now in the helper.
disposition: each names `tests/fingerprint-tree.sh` in
`docs/verification/2026-10-14-ratchet-pinned-qualification.md`.

**finding-4**: record — the `Governs:` list omitted `tests/fingerprint-tree.sh`.
disposition: added in
`docs/verification/2026-10-14-ratchet-pinned-qualification.md`.

## Guideline reviews

### docs/TEST_GUIDELINES.md

Governs: docs/plans/2026-10-14-ratchet-pinned-qualification.md
docs/problems/2026-10-05-zsh-status.md
docs/problems/2026-10-14-ratchet-field-report.md install.sh
skills/ratchet/SKILL.md skills/ratchet/references/rationale.md
skills/ratchet/references/upgrade-notes.md tests/install.bats
tests/run-tests.bats tests/run-tests.sh tests/fingerprint-tree.sh
tests/skills.bats (`tests/fingerprint-tree.sh` from round 3 on)

### Round 1

**finding-1**: guideline, medium — Seams 1, "In this repository the interface
is a script's command line." — tests/skills.bats (the step 0 test)
The test grepped `install.sh`'s source for `.guardrails-source`, which its
header comment also matches, so it pinned nothing.
disposition: the grep is removed; the behaviour is pinned at the command line
by "install: --copy records the checkout in every copied skill".

**finding-2**: guideline, medium — Seams 1, "In this repository the interface
is a script's command line." — tests/skills.bats (the qualification-log test)
The test grepped the runner's source for `run-tests: testing commit`.
disposition: the grep is removed; the printed line is pinned by "run-tests: a
clean checkout names the commit it tests".

### Round 2

**finding-1**: guideline, low — Seams 1, "a test verifies the problem report
or the plan decision that states the behavior, at the same seam" —
tests/skills.bats (the upgrade-notes test)
The test verifies PR-y8ff5p, whose report states no upgrade note.
disposition: no change — the behaviour is covered by the other PR-y8ff5p
tests, such as "run-tests: a tree changed during the run fails the run, though
every test passed"; the upgrade note is how the fix reaches an adopter.

### Round 3

**finding-1**: guideline, medium — Seams 2, "A deeper interface gets a direct
test only once a plan decision or a problem report states its contract" —
tests/fingerprint-tree.bats:62-172
The helper was tested directly, though no decision states its contract and
most of its cases are reachable through the runner.
disposition: `tests/fingerprint-tree.bats` is deleted and its reachable cases
run through the runner in `tests/run-tests.bats`, such as "run-tests: a
runner nested in another repository's tree finds no checkout of its own"; the
usage and not-a-directory cases, unreachable from the runner and stated
nowhere, have no test.

### Round 4

**finding-1**: guideline, low — Seams 1, "a test verifies the problem report
or the plan decision that states the behavior, at the same seam" —
tests/install.bats:27
"install: a linked install writes nothing into the checkout" verifies
PR-783b29, whose text covers only `--copy`.
disposition: no change — plan decision D3 in
`docs/plans/2026-10-14-ratchet-pinned-qualification.md` states that link mode
writes nothing.

### docs/CODE_GUIDELINES.md

Governs: the same paths as above.

### Round 1

**finding-1**: guideline, medium — Names 4, "A concept has one name in every
file, test and task of the change" — tests/install.bats:8, install.sh:16
The checkout's top directory was `repo`, `repo_root` and `root`.
disposition: `root` throughout `install.sh` and `tests/install.bats`.

**finding-2**: guideline, low — Errors 1/2, "An error is reported where it is
detected" — tests/run-tests.sh (fingerprint)
A git failure while fingerprinting was reported as no checkout or a changed
tree.
disposition: `fingerprint_git`, now in `tests/fingerprint-tree.sh`, reports the failing
command and git's message; pinned by "run-tests: a git that fails before the run leaves the suite's own status, and the commit tested is unknown".

**finding-3**: guideline, low — Names 2, "no chained conditional expression
standing in for an `if`" — tests/run-tests.sh (fingerprint)
disposition: one `if` in what is now `tests/fingerprint-tree.sh`.

**finding-4**: guideline, low — Names 3, "A name says what the thing is" —
tests/run-tests.sh (`before`, `checked`)
disposition: renamed `fingerprint_before` and `fingerprint_taken` in
`tests/run-tests.sh`.

### Round 2

**finding-1**: guideline, low — Errors 1 — tests/run-tests.sh (the
no-checkout line)
After a git failure, or with an unborn HEAD, the next line still says "no git
checkout found".
disposition: no change — the git failure is reported on the line before it,
by "run-tests: a git that fails before the run leaves the suite's own status, and the commit tested is unknown".

**finding-2**: guideline, low — Errors 2 — tests/run-tests.sh
(`rev-parse --show-toplevel 2>/dev/null`)
This also hides a `safe.directory` refusal.
disposition: no change — the outcome is the unknown-commit line, which no run
can qualify on; the call is now in `tests/fingerprint-tree.sh`.

**finding-3**: guideline, low — Errors 2 — tests/run-tests.sh (fingerprint)
The status of `rev-parse HEAD` is dropped.
disposition: no change — a HEAD that cannot be resolved after the run still
fails it as a changed tree; the call is now in `tests/fingerprint-tree.sh`.

**finding-4**: guideline, low — Names 2 — tests/run-tests.bats
(`make_failing_git_stub`)
The stub is built in one `printf`.
disposition: no change — the stub is correct and follows `make_stub_bats` in
`tests/run-tests.bats`.

### Round 3

**finding-1**: guideline, medium — Simplicity 4, "Where two parts of one
change add the same helper, constant or check, one copy stays" —
tests/skills.bats:150, 163, 185, 246, 266
Five copies of one step-extracting awk.
disposition: one helper, `ratchet_step`, in `tests/skills.bats`.

**finding-2**: guideline, medium — Simplicity 4 — tests/run-tests.bats:113,
tests/fingerprint-tree.bats:146
The failing-git stub and the checkout fixture were written in both files.
disposition: one copy of each remains in `tests/run-tests.bats`, the other
file being deleted.

**finding-3**: guideline, low — Errors 1 — tests/run-tests.sh:139
"No git checkout found" after a git failure or an unborn HEAD.
disposition: the runner prints a line per helper exit code; reddened by
"run-tests: a checkout whose HEAD names no commit says so, and the commit
tested is unknown".

**finding-4**: guideline, low — Errors 2 — tests/run-tests.sh:133
The status of `rev-parse "$head^{tree}"` was lost in the comparison.
disposition: captured and reported; reddened by "run-tests: a git that fails
reading HEAD's tree is reported, and the commit tested is unknown".

**finding-5**: guideline, low — Comments 3 — tests/fingerprint-tree.sh:19-21
The header omitted mktemp's exit 1.
disposition: `tests/fingerprint-tree.sh`'s header states every exit code.

**finding-6**: guideline, low — Names 2 — tests/run-tests.bats:113
The stub script was built in one `printf`.
disposition: a quoted heredoc in `tests/run-tests.bats`.

**finding-7**: guideline, low — Names 4 — tests/run-tests.sh:136, 139, 147
The new lines use `run-tests:` beside the older usage errors'
`run-tests.sh:`.
disposition: no change — the usage errors exit 2 before any run, and ratchet
step 5 keys on the `run-tests:` lines a run prints; see `tests/run-tests.sh`.

### Round 4

**finding-1**: guideline, low — Simplicity 1, "no case no test exercises" —
tests/fingerprint-tree.sh:31-38
The usage and not-a-directory branches run under no test.
disposition: no change — they are unreachable from the helper's only caller
and documented in the header of `tests/fingerprint-tree.sh`.

**finding-2**: guideline, low — Errors 1 — tests/run-tests.sh:154-155
After the run, a helper exit 2 or 3 reads as a changed working tree.
disposition: no change — it needs git or HEAD to vanish mid-run, and the run
still fails; see `tests/run-tests.sh`.

**finding-3**: guideline, low — Errors 2 — tests/fingerprint-tree.sh:50-52
`rev-parse -q --verify HEAD` maps every failure to an unborn HEAD.
disposition: no change — the outcome is a run that names no commit; see
`tests/fingerprint-tree.sh`.

**finding-4**: guideline, low — Names 4 — tests/run-tests.sh:136-155
`run-tests:` beside the older `run-tests.sh:` usage errors, as round 3's
finding-7.
disposition: no change, as round 3; see `tests/run-tests.sh`.

### docs/ARCHITECTURE_GUIDELINES.md

Governs: the same paths as above. This file reached the branch when step 1
merged `main` at 344faa3, after the TEST and CODE rounds.

### Round 1

**finding-1**: guideline, medium — Boundaries 1, "A script and a skill each
have one job, stated in one sentence without "and" in the script's header
comment" — tests/run-tests.sh:5-7
The runner's header gave it a second job, certifying the tree it tested, in
a sentence joined by "and".
disposition: the header of `tests/run-tests.sh` was rewritten to state one
job, keeping the fingerprint in the runner; round 2 reported the finding
again, and the user ruled to split the fingerprint into
`tests/fingerprint-tree.sh` (round 2, finding-1).

### Round 2

**finding-1**: guideline, medium — Boundaries 1, as in round 1; Existing
code 1, "a change that would give a script a second job puts that job in a
script of its own" — tests/run-tests.sh:4-9, 133-177
The rewritten header fits the fingerprint in as a relative clause; it is
still a second job, with its own tests and reasons to change. It recurred
after its fix, so the loop stopped and the choice went to the user, who ruled
on 2026-10-14 to split it into a helper the runner calls.
disposition: `tests/fingerprint-tree.sh` prints the fingerprint and
`tests/run-tests.sh` calls it before and after bats, so every run keeps the
check; its cases are tested through the runner, such as "run-tests: a tracked
file that .gitignore matches leaves a clean checkout testing its commit"
(TEST round 3 moved them there).

**finding-2**: guideline, low — Domain 2, "A term means one thing in every
script, skill and template." — skills/ratchet/SKILL.md:79, 228
"The guardrails repo" meant the checkout in step 0 and the clone in steps 2
and 5.
disposition: steps 2 and 5 and `skills/ratchet/references/rationale.md` say
`<guardrails>` or the clone; pinned by "ratchet: the guardrails source is
named the checkout or the clone, never the guardrails repo".

**finding-3**: guideline, low — Constraints 1, "A structural rule that a scan
of the tree can check is a test in `tests/`" —
skills/ratchet/references/rationale.md
Only one of the five `run-tests:` lines the rationale lists was pinned.
disposition: all five are pinned by "ratchet: the rationale lists every line
the runner says about what it tested".

### Round 3

Nothing found.

### Round 4

**finding-1**: guideline, medium — Domain 2, "A term means one thing in every
script, skill and template." — skills/ratchet/references/rationale.md:136-140,
tests/run-tests.sh:127, 147, tests/fingerprint-tree.sh:4, 13, 23-28
"Checkout" meant the guardrails source in the ratchet prose and any git
repository, the clone included, in the runner's messages.
disposition: the runner and helper say "git repository", as in
`run-tests: no git repository found; the commit tested is unknown`; the
rationale list is pinned by "ratchet: the rationale lists every line the
runner says about what it tested".

**finding-2**: guideline, low — Domain 2 — tests/fingerprint-tree.sh:9-11,
tests/run-tests.sh:9, 157
Unqualified "tree" meant both the tree object and the working tree.
disposition: each use is qualified in `tests/run-tests.sh` and
`tests/fingerprint-tree.sh`, and the message reads `run-tests: the working
tree changed during the run`; asserted by "run-tests: a tree changed during
the run fails the run, though every test passed".

### Round 5

**finding-1**: guideline, low — Domain 2 — skills/ratchet/SKILL.md:21-26
Ratchet's "the checkout" is the guardrails source, while the repository
elsewhere says "checkout" for any git working tree, as "primary checkout"
does.
disposition: no change — step 0 of `skills/ratchet/SKILL.md` defines the word
where it is first used, and "the clone" names the other.

**finding-2**: guideline, low — Domain 2 — install.sh:9, 34,
skills/ratchet/SKILL.md:19
`.guardrails-source` names only the checkout, while step 0's heading "the
guardrails source" covers the checkout and its clone.
disposition: no change — step 0 states the file's role where it reads it; see
`install.sh`.

## Gaps

- The runner names the commit it tested; nothing checks that the commit a
  setup document records is that line's commit. Step 5 tells the agent to
  compare them.
- The qualification log is kept in a temporary directory (PR-v6mcvt), and a
  stale `.guardrails-source` has no remedy in step 0 (PR-92mbhq).
- A run while bats-core's parallel mode is under heavy load can exit 1 with no
  test failing (`wait: pid … is not a child of this shell`, seen in round 2's
  reviewer run), or time out a slow test (round 3's reviewer run). The runner
  passes bats's status through, as it should; such a run is not a qualifying
  run, and the record does not count it.
- An interrupted helper removes its temporary directory from its trap and
  then fails its next git call rather than exiting at once; the run still
  names no commit.
- The fingerprint writes loose blob objects for modified and untracked files
  into the repository being tested; nothing removes them before `git gc`.
- The pre-flight (`merge-preflight.sh`) stops at its IDS check: this
  repository has no `.guardrails/`. `check-ids.sh` and `check-trace.sh` were
  run on clones of `main` and of the change with a minimal config; `check-ids`
  output is identical, and `check-trace` differs only in this change's own
  items and problem file.
- Installed skill copies under `~/.agents/skills/` are the user's to refresh;
  until they are, the agent reads the old step 0 and step 5.
