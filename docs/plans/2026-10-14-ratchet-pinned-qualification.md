# Pinned ratchet qualification Implementation Plan

**Goal:** A `/ratchet` qualification run describes exactly one commit, the
skill finds the guardrails checkout after `install.sh --copy`, and step 5's
exit-status capture works in zsh.
**Implements:** none (this repository has no SRS); resolves PR-y8ff5p,
PR-783b29 and PR-ww36qr.
**Safety class:** not configured (this repository has no `.guardrails/config.yaml`).
**Verification:** `sh tests/run-tests.sh`

Context: an adopter's field report of 2026-10-14
(`docs/problems/2026-10-14-ratchet-field-report.md`). PR-ww36qr is defined in
`docs/problems/2026-10-05-zsh-status.md`.

## Decisions

**D1 — The checkout is cloned before ratchet reads it.** Step 0 runs
`git clone -q <checkout> <guardrails>`, and every later copy and the suite
read the clone. A clone holds one commit and nothing edits it. Why not the
adopter's `git archive | tar -x`: `tests/mutate.sh` runs `git ls-files` on
the repository it lives in, so `tests/mutations.bats` cannot pass in an
export that has no `.git`.

**D2 — The runner names what it tested, and fails a run the tree moved
under.** `tests/run-tests.sh` fingerprints the tree (`HEAD` plus a tree
object of every file git does not ignore, built in a temporary index) before
and after bats runs. Before: on standard error, `run-tests: testing commit
<sha>` when the tree is `HEAD`'s, `run-tests: the working tree differs from
commit <sha>; this run tests no commit` when not, and `run-tests: no git
checkout found; the commit tested is unknown` without one. After: when the
fingerprint changed, `run-tests: the tree changed during the run; this result
describes no commit`, and exit 1 if bats exited 0. A dirty tree at the start
is a warning only, because a TDD run on uncommitted work is normal; a tree
that changed during the run has a result that describes no tree. Standard
error, not stdout: the TAP stream stays as bats wrote it. The runner no longer
`exec`s bats, since it has work to do after.

As shipped (conformance rounds 3 and 4), the fingerprint is
`tests/fingerprint-tree.sh`, called by the runner, and the lines read
`run-tests: no git repository found; the commit tested is unknown`,
`run-tests: HEAD names no commit; the commit tested is unknown`,
`run-tests: the commit tested is unknown` after a git failure, and
`run-tests: the working tree changed during the run; this result describes no
commit`. `skills/ratchet/references/rationale.md` lists them all.

**D3 — `install.sh --copy` records the checkout.** Each copied skill gets
`.guardrails-source`, one line, the checkout's absolute path. Link mode writes
nothing: its target is inside the checkout, and two levels above the link
target is already the checkout. The commit is not recorded: ratchet clones
the checkout's `HEAD`, and installed-copy drift is PR-z6uaa8's subject.

**D4 — The exit status goes in `rc`.** zsh reserves `status`.

## Tasks

### T1 — the runner names its commit and fails a moved tree

**Files touched:** tests/run-tests.sh, tests/run-tests.bats
**Parallel:** yes

1. In `tests/run-tests.bats`, make `run_runner` always keep standard error
   out of `$output`: default `runner_stderr_file` to
   `$BATS_TEST_TMPDIR/runner-stderr` when the caller set none. The existing
   tests compare stdout exactly, and the runner now always writes a
   `run-tests:` line to standard error. Update the helper's comment.
2. Add a helper `make_checkout`: a git repository at
   `$BATS_TEST_TMPDIR/checkout` holding a copy of the runner at
   `tests/run-tests.sh` and a committed `README`, with `user.name`,
   `user.email` and `commit.gpgsign false` set, its commit in
   `checkout_commit`, and `git`, `mktemp` and `rm` linked into the tools
   directory with `link_tool`. Tests that use it set
   `runner="$checkout/tests/run-tests.sh"`. If the linked git fails under the
   restricted PATH, link what it needs and say so in the report.
3. Write these tests, each `# verifies: PR-y8ff5p`, and watch each fail:
   - "run-tests: a clean checkout names the commit it tests": stderr file
     contains `run-tests: testing commit $checkout_commit`; status 0.
   - "run-tests: a modified checkout says the run tests no commit, and still
     runs": modify `README` before the run; stderr names
     `the working tree differs from commit $checkout_commit`; status 0; stdout
     still lists the bats arguments.
   - "run-tests: an untracked file makes the tree differ from the commit":
     as above, with a new untracked file instead of a modification.
   - "run-tests: a tree changed during the run fails the run, though every
     test passed": a stub bats (`make_stub bats`) that appends to
     `$checkout/README` and exits 0; stderr has
     `the tree changed during the run`; status 1.
   - "run-tests: a commit made during the run fails the run": a stub bats
     that commits an empty commit (`git -C … commit -q --allow-empty`) and
     exits 0; status 1. The tree is unchanged but `HEAD` moved.
   - "run-tests: a failing suite keeps its own status when the tree also
     changed": stub bats changes the tree and exits 3; status 3.
   - "run-tests: outside a git checkout the commit tested is unknown": the
     runner copied into a directory with no `.git`, `git` linked; stderr has
     `the commit tested is unknown`; status 0.
   - "run-tests: a checkout nested in another repository is not read as that
     repository": a copy of the runner in `tests/` of a plain subdirectory of
     a committed fixture repository; stderr has `the commit tested is
     unknown`. The fingerprint must not describe the enclosing repository.
4. Replace the runner's two final `exec` lines with the D2 behaviour:

   *(Code pruned at merge: 46 lines. Files touched: tests/run-tests.sh, tests/run-tests.bats.)*

   Update the header comment to say the runner names the commit it tests.
5. Run `sh tests/run-tests.sh tests/run-tests.bats tests/portability.bats`;
   every test passes. Commit.

**Done** (1886e63; 56 passed, 0 failed). Deviations: the two chained
conditionals are `if` blocks and `fingerprint()` says why its git errors are
discarded (CODE_GUIDELINES Names 2, Errors 2).

```
red -> green: run-tests: a clean checkout names the commit it tests — failed with no run-tests: line on stderr
red -> green: run-tests: a modified checkout says the run tests no commit, and still runs — failed with no "differs from commit" line
red -> green: run-tests: an untracked file makes the tree differ from the commit — failed with no "differs from commit" line
red -> green: run-tests: a tree changed during the run fails the run, though every test passed — failed: status 0 passed through exec
red -> green: run-tests: a commit made during the run fails the run — failed: status 0 passed through exec
red -> green: run-tests: a failing suite keeps its own status when the tree also changed — failed: no "tree changed during the run" line
red -> green: run-tests: outside a git checkout the commit tested is unknown — failed with no "commit tested is unknown" line
red -> green: run-tests: a checkout nested in another repository is not read as that repository — failed with no "commit tested is unknown" line
```

### T2 — `install.sh --copy` records the checkout

**Files touched:** install.sh, tests/install.bats
**Parallel:** yes

1. Create `tests/install.bats` (`load helpers`). Each test installs into
   `CLAUDE_SKILLS_DIR=$BATS_TEST_TMPDIR/skills`, never the real one. Tests,
   each `# verifies: PR-783b29`, watched failing:
   - "install: --copy records the checkout in every copied skill": every
     `skills/<name>/` in the repository has
     `$BATS_TEST_TMPDIR/skills/<name>/.guardrails-source`, whose only line is
     the repository root (`cd "$BATS_TEST_DIRNAME/.." && pwd`).
   - "install: a linked install writes nothing into the checkout": after a
     default install, no `skills/*/.guardrails-source` exists in the
     repository, and each installed entry is a symlink.
2. In `install.sh`, set `repo=$(cd "$(dirname "$0")" && pwd)` and
   `src="$repo/skills"`; after the `cp -R`, write
   `printf '%s\n' "$repo" > "$target/.guardrails-source"`, with a comment:
   a copy has no checkout above it, so it records where it came from, and
   `ratchet` step 0 reads it (PR-783b29). Mention the file in the header
   comment's `--copy` line.
3. Run `sh tests/run-tests.sh tests/install.bats tests/portability.bats`;
   every test passes. Commit.

**Done** (f5189de; 24 passed, 0 failed). The link-mode test guards behaviour
the old script already had, so it passed first; its red was shown against a
wrong first implementation that wrote the file in both modes, which was then
discarded.

```
red -> green: install: --copy records the checkout in every copied skill — failed on the unchanged install.sh with "no .guardrails-source in analyze-risks"
red -> green: install: a linked install writes nothing into the checkout — failed against a first implementation writing the file in both modes ("the linked install wrote skills/analyze-risks/.guardrails-source"); passes on the copy-only implementation
```

### T3 — ratchet reads the source file, clones, and captures `rc`

**Files touched:** skills/ratchet/SKILL.md, skills/ratchet/references/rationale.md,
skills/ratchet/references/upgrade-notes.md, tests/skills.bats,
docs/problems/2026-10-14-ratchet-field-report.md,
docs/problems/2026-10-05-zsh-status.md
**Parallel:** no (serial, after T1 and T2)

1. Tests in `tests/skills.bats`, beside the other `ratchet:` tests, watched
   failing:
   - "ratchet: step 0 clones the checkout before reading it, and finds it
     through .guardrails-source" (`# verifies: PR-y8ff5p, PR-783b29`): step 0
     contains `.guardrails-source` and `git clone -q <checkout> <guardrails>`,
     and `install.sh` writes `.guardrails-source`.
   - "ratchet: the qualification log must name the recorded commit"
     (`# verifies: PR-y8ff5p`): the skill contains
     `run-tests: testing commit`, and `tests/run-tests.sh` prints it.
   - "ratchet: the suite's exit status is captured in rc, never in zsh's
     read-only status" (`# verifies: PR-ww36qr`): the skill contains
     `rc=$?` and not `status=$?`; `rationale.md` contains
     `read-only variable: status`.
   - "ratchet: the upgrade notes say the checkout is cloned and the suite
     names its commit" (`# verifies: PR-y8ff5p`): the heading below exists in
     `upgrade-notes.md`.
2. `SKILL.md` step 0: replace its body with

   *(Code pruned at merge: 5 lines. Files touched: skills/ratchet/SKILL.md, skills/ratchet/references/rationale.md, skills/ratchet/references/upgrade-notes.md, tests/skills.bats, docs/problems/2026-10-14-ratchet-field-report.md, docs/problems/2026-10-05-zsh-status.md.)*
3. `SKILL.md` step 5: cut "it vendors bats-core into its own gitignored
   `tests/.bats-core/` when no system bats exists. Never add bats to the
   target project." (the first is in rationale.md now; the second repeats the
   bold heading), and replace the exit-status paragraph with

   *(Code pruned at merge: 6 lines. Files touched: skills/ratchet/SKILL.md, skills/ratchet/references/rationale.md, skills/ratchet/references/upgrade-notes.md, tests/skills.bats, docs/problems/2026-10-14-ratchet-field-report.md, docs/problems/2026-10-05-zsh-status.md.)*

   Measured on a scratch copy: 1997 words.
4. `rationale.md`: add two sections. "The guardrails checkout is cloned
   before anything is read from it": a ~20-minute suite reads the tree it
   lives in, so a commit made there mid-run mixed two commits in one log and
   recorded the first as qualified; a clone holds one commit; uncommitted
   edits are not in it, by design; the four `run-tests:` lines and that only
   `testing commit` qualifies a commit; the runner downloads bats-core when
   neither system bats nor `tests/.bats-core/` exists, and the clone has no
   `tests/.bats-core/`, so copy the checkout's in to skip the download;
   why `archive` is not enough (D1); and why a copied skill needs
   `.guardrails-source` while a symlinked one does not. "The exit status goes
   in `rc`": zsh's `status` is read-only, `status=$?` fails with
   `read-only variable: status`, `rc` is special in no common shell, and a
   pipe into `tee` leaves `$?` as tee's.
5. `upgrade-notes.md`: append "## The guardrails checkout is cloned, and the
   suite names its commit": step 0 clones the checkout and the copies and the
   suite read the clone; `run-tests.sh` prints `run-tests: testing commit
   <sha>` on standard error and fails a run the tree changed under; record
   that commit; an `install.sh --copy` install made before this has no
   `.guardrails-source`, so re-run `install.sh --copy`; step 5 captures the
   status in `rc`. No gate changes.
6. Ledger: set `status: resolved` and add one resolution line, under each of
   PR-y8ff5p and PR-783b29 in `docs/problems/2026-10-14-ratchet-field-report.md`,
   and under PR-ww36qr in `docs/problems/2026-10-05-zsh-status.md`, citing the
   reproducing test names from T1, T2 and step 1. Keep `opened:`.
7. Run `sh tests/run-tests.sh tests/skills.bats`; every test passes, including
   the 2,000-word cap. Commit.

**Done** (34acb0b; skills.bats 145 passed, 0 failed; SKILL.md 2000 words).
Deviation: "Never add bats to the target project." is kept, because
`tests/tailor-guidelines.bats` requires it; step 0's parenthetical and step
5's last sentence were shortened instead.

```
red -> green: ratchet: step 0 clones the checkout before reading it, and finds it through .guardrails-source — failed with "step 0 does not read .guardrails-source"
red -> green: ratchet: the qualification log must name the recorded commit — failed with "the skill does not name the testing-commit line"
red -> green: ratchet: the suite's exit status is captured in rc, never in zsh's read-only status — failed with "the skill does not capture rc"
red -> green: ratchet: the upgrade notes say the checkout is cloned and the suite names its commit — failed with "no upgrade-notes section"
```

## Conformance reviews

### Round 1 — TEST (docs/TEST_GUIDELINES.md)

- finding-1 (medium, Seams 1): tests/skills.bats:155 greps `install.sh`'s
  source for `.guardrails-source`, which its header comment also matches, so
  it pins nothing; the behaviour is tested at the command line in
  `tests/install.bats`. Disposition: fix, drop the grep.
- finding-2 (medium, Seams 1): tests/skills.bats:166 greps the runner's source
  for `run-tests: testing commit`; the printed line is tested in
  `tests/run-tests.bats`. Disposition: fix, drop the grep.
- note: the "still runs" tests match the unexpanded `*.bats` glob, because the
  fixture has no `.bats` file. Disposition: fix, give the fixture one.

### Round 1 — CODE (docs/CODE_GUIDELINES.md)

- finding-1 (medium, Names 4): the checkout's top directory is `repo`
  (install.sh), `repo_root` (tests/install.bats) and `root` elsewhere.
  Disposition: fix, `root` throughout.
- finding-2 (low, Errors 1/2): `fingerprint()` discards git's error, so a git
  failure reads as "no checkout" or "tree changed". Disposition: fix, report it.
- finding-3 (low, Names 2): `fingerprint_tree=$(…) || fingerprint_tree=''`
  chains in place of an `if`. Disposition: fix.
- finding-4 (low, Names 3): `before` and `checked` do not say what they hold.
  Disposition: fix.

TEST round 1 fixed (41774ee; 201 passed, 0 failed): both source greps
removed; the fixture commits `tests/a.bats` and the two "still runs" tests
assert the stub received exactly that path.

```
red -> green: run-tests: a modified checkout says the run tests no commit, and still runs — the exact-path assertion failed while the stub got the unexpanded glob
red -> green: run-tests: an untracked file makes the tree differ from the commit — the same failure, then passed
```

CODE round 1 fixed (f4a163e, 9687bc2; 58 passed, 0 failed): `root`
throughout; `fingerprint_git` reports `run-tests: git <args> failed:
<message>` and keeps each outcome; one `if` in `fingerprint()`;
`fingerprint_before` and `fingerprint_taken`. The error report is new
observable output, so its test is dispatched as `git-fail`.

git-fail done (5ba6356; 59 passed, 0 failed). Red shown by silencing the
error line in `fingerprint_git`, then restoring it unchanged.

```
red -> green: run-tests: a git that fails before the run is reported, and the commit tested is unknown — failed only on the missing "git add -A failed" line
red -> green: run-tests: a git that fails before the run leaves the suite's own status — failed only on the missing error line
red -> green: run-tests: a git that fails after the run is reported, and fails a passing run — failed only on the missing error line
```

### Round 2 — TEST (docs/TEST_GUIDELINES.md)

Nothing above low; the last TEST round.

- finding-1 (low, Seams 1): the upgrade-notes test verifies PR-y8ff5p, whose
  report states no upgrade note. Disposition: not fixed, low; the behaviour is
  covered by the other PR-y8ff5p tests.

### Round 2 — CODE (docs/CODE_GUIDELINES.md)

Nothing above low; the last CODE round.

- finding-1 (low, Errors 1): after a git failure in `fingerprint`, or with an
  unborn HEAD, the next line still says "no git checkout found". Disposition:
  not fixed, low; the git failure is reported on the line before it.
- finding-2 (low, Errors 2): `rev-parse --show-toplevel 2>/dev/null` also
  hides a `safe.directory` refusal. Disposition: not fixed, low.
- finding-3 (low, Errors 2): `fingerprint` drops the status of
  `rev-parse HEAD`. Disposition: not fixed, low; the run still fails.
- finding-4 (low, Names 2): `make_failing_git_stub` builds its script in one
  `printf`. Disposition: not fixed, low.

## Independent review

### Round 1 (merge-change 6a, at 253120e)

Gate in the reviewer's worktree: 1442 passed, 0 failed, one `run-tests:` line,
`testing commit 253120e…`. Every claim met. After the review, step 1 merged
`main` at 344faa3 (architecture-guidelines), which edited
`skills/ratchet/SKILL.md`, `upgrade-notes.md` and `tests/skills.bats` too, so
6a reviews the whole change again. The merge left SKILL.md at 2001 words.

- finding-1 (code, low): the fingerprint's fresh index skips a tracked file
  that is also ignored, so a clean checkout holding one always "differs".
  Disposition: fix, seed the index from HEAD (`fix-fp`).
- finding-2 (requirement, low): TAP test names contain `run-tests:`, so
  "any other `run-tests:` line" matches them; rationale's list omits the
  git-failure line. Disposition: fix, "a line beginning" (`fix-docs`).
- finding-3 (requirement, low): step 0 does not say where the clone goes or
  that it is removed. Disposition: fix (`fix-docs`).
- finding-4 (record): T3 step 5 planned "re-run `install.sh --copy`"; the
  note ships "delete the copied skill directories first", because install.sh
  skips an existing directory. Disposition: the shipped note is right; this
  line records the deviation.

fix-fp done (1b759e3; 61 passed, 0 failed): the temporary index is seeded
from HEAD before `add -A`.

```
red -> green: run-tests: a clean checkout with a tracked ignored file names the commit it tests — failed: "the working tree differs from commit …"
red -> green: run-tests: an ignored untracked file leaves a clean checkout naming its commit — passed first (add -A skips ignored files); red shown with `add -A --force`, then restored
```

fix-docs done (5a9c2ed, 150f0fe; skills.bats 156 passed, 0 failed; SKILL.md
1999 words): "a line beginning `run-tests:`" in step 5 and the upgrade note;
the git-failure line in rationale.md; step 0 clones into a temporary directory
outside the project, removed when the ratchet is done. Four phrases cut to fit
the cap, none asserted by a test. A source grep of run-tests.sh in the new
rationale test was dropped before the merge (TEST round 1, Seams 1).

```
red -> green: ratchet: step 0 clones into a temporary directory outside the project, removed afterwards — failed before the step 0 edit
red -> green: ratchet: a qualification log line describes no commit only when it begins run-tests: — failed before the step 5 and upgrade-note edits
red -> green: ratchet: the rationale lists the runner's git-failure line — failed before the rationale edit
```

### Round 2 (merge-change 6a, at 2915b39, the whole change after main 344faa3)

Gate in the reviewer's worktree: 1472 ok, 0 not ok, rc 1, from bats-core's
own `wait: pid … is not a child of this shell` in its parallel output
forwarding, while the change worktree's gate ran at the same time; the
runner passed bats's status through. The change worktree's gate of the same
tree: 1472 passed, 0 failed, rc 0.

- finding-1 (requirement, medium): step 5's command writes `ratchet.log`
  inside the clone, an untracked file the fingerprint sees, so every run
  reads "differs" and "changed during the run" and none qualifies; the log
  is also deleted with the clone. Reproduced by the reviewer. Disposition:
  fix, the log goes outside the clone (`fix-log`).
- finding-2 (requirement, low): "exactly once" conflicts with "run it
  again". Disposition: fix (`fix-log`).

fix-log done (43a3ead; 171 passed, 0 failed; SKILL.md 2000 words): step 0
clones to `<tmp>/guardrails`; step 5 writes `<tmp>/ratchet.log`, kept as
evidence; "exactly once" became "one qualifying run per update".

```
red -> green: ratchet: step 5 writes the qualification log outside the clone — failed: "step 5 writes the log into the current directory"
red -> green: ratchet: step 5 does not both run the suite exactly once and run it again — failed: "step 5 still says exactly once"
```

## ARCHITECTURE conformance (docs/ARCHITECTURE_GUIDELINES.md, from main 344faa3)

### Round 1

- finding-1 (medium, Boundaries 1): the runner's header gave it a second job,
  certifying the tree, joined by "and". Disposition: ruled to keep the
  fingerprint in the runner (a gate or TDD run reading a moved tree is the
  same defect, and a wrapper would protect only the ratchet's run); header
  rewritten to one job, "Run the guardrails test suite as a measurement of one
  commit, which it names." (arch-r1, e4f16ba; 61 passed, 0 failed).

### Round 2

- finding-1 (medium, Boundaries 1): recurs at tests/run-tests.sh — the
  header's one sentence fits the fingerprint in as a relative clause; it is
  still a second job with its own tests and reasons to change. Derailment:
  put to the user, who ruled 2026-10-14 to split it into a helper,
  `tests/fingerprint-tree.sh`, that run-tests.sh calls before and after bats,
  so every run keeps the check (`split-fp`).
- finding-2 (low, Domain 2): "the guardrails repo" in step 2 and step 5 and
  "the guardrails repository" in rationale.md now mean the clone, while step 0
  uses the phrase for the checkout. Disposition: fix, `<guardrails>`
  (`arch-docs`).
- finding-3 (low, Constraints 1): rationale.md lists five `run-tests:` lines
  and only one is pinned. Disposition: fix, pin all five in the rationale
  (`arch-docs`).

arch-docs done (f1dd183; 172 passed, 0 failed; SKILL.md 1997 words): step 2
copies from `<guardrails>`, step 5's suite runs in the clone, and rationale.md
says the clone; all five `run-tests:` lines are pinned in the rationale.

```
red -> green: ratchet: the guardrails source is named the checkout or the clone, never the guardrails repo — failed on SKILL.md steps 2 and 5
red -> green: ratchet: the rationale lists every line the runner says about what it tested — passed first; red shown by deleting the no-checkout line from rationale.md, then restored
```

split-fp done (989ecbd; 67 passed, 0 failed): `tests/fingerprint-tree.sh`
(exit 0 printed, 1 git failed with the `run-tests: git … failed:` line, 2 no
checkout/no git/no HEAD or usage) and `tests/fingerprint-tree.bats`; the
fingerprint tests moved there as `fingerprint-tree: …`. Each moved or new test
was shown red by a mutation of the helper, then restored (`cmp` clean).

## Conformance round 3 (after the split)

- ARCHITECTURE: nothing found.
- TEST finding-1 (medium, Seams 2): `tests/fingerprint-tree.bats` tests the
  helper directly, but no decision states its contract and most cases are
  reachable through run-tests.sh. Disposition: fix, move the reachable cases
  to `tests/run-tests.bats` and delete `tests/fingerprint-tree.bats`
  (`r3-runner`).
- CODE finding-1 (medium, Simplicity 4): five copies of one step-extracting
  awk in `tests/skills.bats`. Disposition: fix, one helper (`r3-skills`).
- CODE finding-2 (medium, Simplicity 4): the failing-git stub and the checkout
  fixture are written in both bats files. Disposition: fixed by `r3-runner`.
- CODE finding-3 (low, Errors 1): "no git checkout found" after a git failure
  or an unborn HEAD. Disposition: fix (`r3-runner`).
- CODE finding-4 (low, Errors 2): `rev-parse "$head^{tree}"`'s status is lost
  in the comparison. Disposition: fix (`r3-runner`).
- CODE finding-5 (low, Comments 3): the helper's header omits mktemp's exit 1.
  Disposition: fix (`r3-runner`).
- CODE finding-6 (low, Names 2): the stub is one `printf`. Disposition: fix,
  a heredoc (`r3-runner`).
- CODE finding-7 (low, Names 4): `run-tests:` beside the older usage errors'
  `run-tests.sh:`. Disposition: no change — the usage errors exit 2 before any
  run, and ratchet step 5 keys on the `run-tests:` lines a run prints.

r3-skills done (c77df68; 159 passed, 0 failed): `ratchet_step N` in
`tests/skills.bats` wraps `section_of` and flattens; the five awk copies call
it. Each step's assertions shown failing by a temporary edit to SKILL.md,
restored (`cmp` clean).

r3-runner done (8426ace; 63 passed, 0 failed): `tests/fingerprint-tree.bats`
deleted, its reachable cases moved to `tests/run-tests.bats`; the usage and
not-a-directory cases dropped, unreachable from the runner and stated nowhere.
The helper exits 0 printed, 1 git or mktemp failed, 2 no checkout or no git,
3 HEAD names no commit; the runner prints a line per outcome. Each moved test
shown red by a mutation of the helper, restored (`cmp` clean).

```
red -> green: run-tests: a checkout whose HEAD names no commit says so, and the commit tested is unknown — failed: got "no git checkout found"
red -> green: run-tests: a git that fails reading HEAD's tree is reported, and the commit tested is unknown — failed: the runner printed "differs"
red -> green: run-tests: an untracked file makes the working tree differ from the commit — red under `add -A` -> `add -u`
red -> green: run-tests: a tracked file that .gitignore matches leaves a clean checkout testing its commit — red with `read-tree HEAD` removed
red -> green: run-tests: an ignored untracked file leaves a clean checkout testing its commit — red under `add -A -f`
red -> green: run-tests: a runner nested in another repository's tree finds no checkout of its own — red with the toplevel check disabled
red -> green: run-tests: without git on PATH the commit tested is unknown — red with exit 1 forced at the toplevel check
```

rationale-lines done (beb3ee4; 159 passed, 0 failed): the rationale lists
every `run-tests:` line the runner and helper print, corrected (a git failure
before the run is followed by the commit-unknown line, not the no-checkout
line), and the pinning test covers each.

```
red -> green: ratchet: the rationale lists every line the runner says about what it tested — failed: the rationale did not list "HEAD names no commit"
```

## Conformance round 4

- TEST finding-1 (low, Seams 1): "install: a linked install writes nothing
  into the checkout" verifies PR-783b29, whose text covers only `--copy`.
  Disposition: no change — plan D3 states the link-mode behaviour.
- CODE (all low): finding-1, the helper's usage and not-a-directory branches
  run under no test; finding-2, after the run a helper exit 2 or 3 reads as a
  changed tree; finding-3, `rev-parse -q --verify HEAD` maps every failure to
  an unborn HEAD; finding-4, `run-tests:` beside `run-tests.sh:` (round 3's
  finding-7). Disposition: no change — the first is documented in the
  helper's header and unreachable from its only caller; the second and third
  need git or HEAD to vanish mid-run, and the run still fails or names no
  commit; the fourth as round 3.
- ARCHITECTURE finding-1 (medium, Domain 2): "checkout" means the guardrails
  source in the ratchet prose and any git repository in the runner's
  messages. Disposition: fix, the runner and helper say "git repository"
  (`r4-terms`).
- ARCHITECTURE finding-2 (low, Domain 2): unqualified "tree" means both the
  tree object and the working tree. Disposition: fix, "working tree" in the
  runner's message and headers (`r4-terms`).

r4-terms done (4799bcd; 222 passed, 0 failed): "git repository" in the
runner's and helper's messages and headers, "working tree" or "tree object"
for each unqualified "tree". Seven updated assertions failed before the
script changes.

## Conformance round 5

- ARCHITECTURE (all low): "checkout" for the source in the ratchet prose
  against the repository's general "checkout"; `.guardrails-source` against
  step 0's "guardrails source". Disposition: no change — step 0 defines both
  where it uses them. Every conformance loop has converged.

## Independent review round 4 (at d2564ee, after the split)

Gate in the reviewer's worktree: 1477 passed, 0 failed, rc 0; the change
worktree's gate of the same tree: 1477 passed, 0 failed, rc 0.

- finding-1 (code, medium): no test pins that the helper leaves the real index
  alone. Disposition: fix (`r4-index`).
- finding-2 (code, low): the mktemp-failure path has no test. Fix (`r4-index`).
- finding-3 (code, low): the helper lacked its executable bit. Fix (`r4-index`).
- finding-4, 5, 6 (record): D2's wording, three record slips, the verdict.
  Disposition: fixed in this plan's D2 note and the record.

r4-index done (61d1e97; 65 passed, 0 failed): two characterization tests,
each passing first and shown red by the named mutation, then restored.

```
red -> green: run-tests: the checkout's own index is left as it was, staged and unstaged changes alike — passed first; red with GIT_INDEX_FILE removed from fingerprint_git
red -> green: run-tests: a mktemp that fails is reported in its own words, and the commit tested is unknown — passed first; red under `|| exit 2` and under `2>/dev/null` on the mktemp line
```

## Independent review round 5 (at aeceb00) — the last

Gate in the reviewer's worktree: 1479 passed, 0 failed, rc 0. Fifteen of
sixteen mutations of the runner and helper killed. Nothing above low.

- finding-1 (code, low): the helper's cleanup is seen by no test, and has no
  trap. Fix (`r5-lows`).
- finding-2 (requirement, low): the upgrade copy step does not name
  `<guardrails>`. Fix (`r5-lows`).
- finding-3, 4 (record): four CODE dispositions cited the runner for helper
  code; `Governs:` omitted the helper. Fixed in the record.

r5-lows done (9e7b1ae, 7c7f838, 87012b7; 238 passed, 0 failed; SKILL.md 1999
words). BSD `mktemp -d` ignores `TMPDIR`, so the helper uses an explicit
template; cleanup is an EXIT/INT/TERM trap, the idiom of `tests/mutate.sh`.

```
red -> green: run-tests: the fingerprint helper leaves nothing in TMPDIR — failed with the cleanup removed, once mktemp used a template under TMPDIR
red -> green: ratchet: the guardrails source is named the checkout or the clone, never the guardrails repo — failed on the upgrade copy step's old wording
```
