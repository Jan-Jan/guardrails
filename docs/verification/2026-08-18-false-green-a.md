# Verification record — change A: false-green fixes

Branch `false-green-a`, base `main` at `cb130db`.
Plan: `docs/plans/2026-08-12-false-green-fixes.md`.

## What was verified

| Check | Result |
|---|---|
| `tests/run-tests.sh` | **112 tests, 0 failures**, exit 0 |
| `check-ids.sh` | N/A — this repo has no `.guardrails/config.yaml` |
| `check-trace.sh` | N/A — same |
| `finalize-ids.sh` | N/A — no draft IDs in the tree; the only `*-DRAFT-*` strings are bats fixture literals and pattern documentation |
| Open PR warnings | None — this repo has no problems ledger |

**Environment caveat:** `tests/check-signing.bats` hangs when `SSH_AUTH_SOCK`
points at a wedged gnome-keyring agent, which `ssh-keygen -Y sign` consults
even when given `-f <keyfile>`. It reproduces outside the test suite entirely,
and `scripts/check-signing.sh` and `tests/check-signing.bats` are byte-identical
to `cb130db` (`git diff --stat cb130db..HEAD --` on both is empty). All suite
runs recorded here were taken with `SSH_AUTH_SOCK` unset. Making that fixture
hermetic is a one-line change belonging to its own commit.

## Evidence quality — derived, not asserted

Seven of ten review rounds found this section's figures stale or overstated.
They are no longer written by hand: `tests/evidence.sh` derives them from the
repository, and the block below is its verbatim output. Regenerate with
`sh tests/evidence.sh main` after the last commit that touches `scripts/` or
`tests/`, and keep the result in this document only — the plan carried a second
copy, which went stale within one round.

`tests/evidence.sh` has itself been hardened twice against the defect class it
measures, both times because a reviewer demonstrated the defect rather than
because a test caught it:

- Excluding `check-signing.bats` from the base run left its tests absent from
  the pass list and therefore booked as going red — maximum coverage reported
  for a run that never happened. It now measures only the tests it submitted.
- Requiring the base run's TAP plan to match the tests submitted proved the run
  had **started**, not that it had **finished**: bats prints `1..N` before
  executing anything, so a run killed part-way still passed the guard and
  inflated the figures. It now also requires the emitted result count to equal
  the plan, and refuses when the base checkout yields no scripts.

It still has **no automated test of its own** — both defects above were found
by review. The figures above were independently re-derived by two separate
reviewers and matched to the test name.

Derived by `tests/evidence.sh main` — do not edit by hand.

- Suite: **112 tests** (main: 65); 107 measured against `main`.
- New or renamed since `main`: **48**.
- Of those, **41** go red when run against `main`'s scripts.
- **7** cannot go red, and none is counted as evidence that a
  defect was fixed:

  - `check-ids: --allow-drafts still tolerates an undeclared-prefix draft`
  - `check-trace: a strict path written as a glob still reaches the scan`
  - `check-trace: comma lists, trailing commas and trailing prose all count`
  - `check-trace: traces: counts a REQ anywhere in its list, not only first`
  - `check-trace: traces: on a line below the SDD header still counts`
  - `finalize: same-day rename collision never overwrites an existing file`
  - `gr_doc_files on a missing key prints nothing, exit 0`

Almost every fix is mutation-tested — reverted in a scratch copy, the suite
re-run, and the reddened test named. The full list is in the plan's "Change A:
mutation evidence" section, cited by test name; test numbers depend on run
order and have been wrong in this record before.

**Three behaviours are not covered, and are not claimed to be:** the `git grep`
status checks in `finalize-ids.sh`'s pre-flight and in `check-ids.sh`'s draft
scan (neither can be provoked from a fixture — see gap 8), and
`tests/evidence.sh` itself (gap 11). One fix, the base-ref validation, is
pinned by its behaviour rather than by a single guard: either of its two checks
satisfies the test, so both must be reverted to redden it, and the plan says so.

## Corpus regression

Run **2026-08-18T18:04:12Z**, after the last commit that touches `scripts/` or
`tests/` (`ae94883`, 2026-08-18T18:02:49Z). A record committed to the branch it
describes can never name itself as post-final-commit, so this is deliberately
scoped to the commits that can change the result. Against `sightings-app` at
`a22d33c6`. Run against a **clean clone**, not the project's own working tree:
that project is under active development in another session — its tree held
uncommitted work at one point during this one, and its HEAD moved twice — so
only a clone gives a reproducible baseline, and nothing here touched the
project itself.
Its item counts are the `checked:` line of the output below — stated once, in
the machine output, not restated in prose.

```sh
cd <sightings-app>
sh .guardrails/scripts/check-trace.sh > base.out 2>&1   # its installed v0.1.0
sh <change-A>/scripts/check-trace.sh  > new.out  2>&1
diff base.out new.out
sh <change-A>/scripts/check-ids.sh
```

```
baseline exit=0 / change A exit=0
diff: 8a9,10
> checked: REQ 101, HAZ 4, RC 10, SDD 26, LLR 33, PR 69
> sources: srs 19, rmf 7, sad 5, soup 1, problems 36; strict 5, tests 3
```

`check-ids.sh` also exits 0 on that clone, but its duplicate-vs-base half
examined nothing — a fresh clone is either detached (printing
`SKIPPED-DUPLICATE-BASE`) or on a branch that is its own base. That half of the
gate is exercised by the bats suite, not by this run.

**What this run does and does not demonstrate.** It demonstrates that the
annotation-list rule, the SDD block terminator, the path and ledger existence
checks and the summary lines change no verdict over that project's items and
ledgers — the counts are in the `checked:` line of the block above, and are
deliberately not restated here. It does **not** exercise the pathspec change: that project's
`strict_paths` and `test_paths` are eight plain directory names with no glob or
pathspec character among them, so `set -f` cannot alter its result. The
pathspec fix is covered by its bats test and its mutation, not by this corpus.

## Independent review (DO-178C independence: verifier ≠ author)

Ten review rounds, each a fresh subagent given only the diff, the plan, and
the previous round's findings — no implementation narrative, no chat history.
Every round returned findings; none passed clean.

| Round | Scope | Verdict | Blocking |
|---|---|---|---|
| 1 | Combined work, round 1 | FINDINGS | 3 |
| 2 | Combined work, round 2 | FINDINGS | 2 |
| 3 | Combined work, round 3 | FINDINGS | 2 |
| 4 | Combined work, round 4 | FINDINGS | 2, plus a scope judgement |
| 5 | Change A after the split | FINDINGS | 3 |
| 6 | Change A, incl. the unreviewed round-5 fixes | FINDINGS | 3 |
| 7 | Change A, incl. the unreviewed round-6 fixes | FINDINGS | 4, plus a convergence judgement |
| 8 | Change A, incl. the unreviewed round-7 fixes | FINDINGS | 2 — both outside `scripts/`; "the code has converged" |
| 9 | Change A, incl. the unreviewed round-8 fixes | FINDINGS | 2 — both outside `scripts/`; "the scripts have converged" |
| 10 | Change A, incl. the unreviewed round-9 fixes | FINDINGS | 2 — both inside the round-9 delta |
| 11 | Change A, incl. the unreviewed round-10 fixes | FINDINGS | 1 — inside the round-10 delta |

Every blocking finding was independently reproduced before being fixed. Round
4's scope judgement — that the work had become three units — was accepted by
the maintainer; this is slice A, and changes B (config schema validation) and
C (item placement) are outstanding and will each be reviewed before signing.

Round 7's convergence judgement was that the code was converging while this
record was oscillating, because its derived figures were maintained by hand.
That is what `tests/evidence.sh` was written for.

Seven corrections the reviews forced on this record and its plan, each the
change's own thesis turned on its evidence:

1. Round 2 claimed "every new test mutation-tested". Not true at the time.
2. Round 3's mutation table used numbers from an undocumented partial run, so
   one number meant two different tests in the same section.
3. Rounds 3 and 4 asserted how many tests could not go red rather than
   deriving it.
4. Round 6 found the derived figure stale again, and the corpus block
   reproduced byte-for-byte from a pre-fix run with no date or command.
5. Round 7 found the corpus timestamp preceded the last commit, and the claim
   that the run covered the pathspec fix was false.
6. Round 9 found the mutation-coverage claim overstated: a behaviour with no
   test at all was implicitly counted as covered.
7. Round 10 found the plan's mutation section contradicting itself — a
   corrected paragraph had been added and the false one left in place — and
   this very count stale at "five of nine".

Round 8 reported that the code has converged: the suite is green, the corpus
produces a zero-verdict diff, and an independent re-derivation of the evidence
figures matched to the test name. Both of its blocking findings were in the
evidence apparatus, not the scripts.

Round 9 reported that the scripts have converged: its two blocking findings
were again outside `scripts/` — one in `tests/evidence.sh`, one in this
record's own claims — and it re-derived the evidence figures independently and
matched them.

Round 10 found both of its blocking findings inside the round-9 delta: an
undetectable base branch had been made fatal, which breaks the detached-HEAD
checkout an ordinary CI job produces, and the plan's mutation section had been
left contradicting itself. Neither was in the change's original scope; both
were introduced by fixing earlier findings.

Round 11 was asked to count, across rounds 7-11, how many blocking findings lay
in the change's original scope versus in material added to satisfy earlier
reviews. Its answer: **eleven blocking findings across five rounds, none of
them in the deliverable.** The last blocking finding inside the original scope
was round 6's `set -f` pathspec defect. Its recommendation was to stop
reviewing, close its one blocking finding, record the rest, and land the
change — with the note that `tests/evidence.sh` lives in `tests/`, is never
copied into a target project by `ratchet`, and so cannot produce a false green
in anyone's repository; its blast radius is this record's figures.

**The round-11 fixes are themselves unreviewed** — the same status each previous
round's fixes had when the next was called. They are: ref validation scoped to a base the caller
NAMED, so a detected base with no commits is skipped rather than fatal, with a
test; `SKIPPED-DUPLICATE-BASE` documented in the README, the
`check-traceability` skill and `merge-change` step 4; `tests/evidence.sh`
applying its `# skip` strip to the pass list as well as the identity check; and
the gap-list corrections above.

The round-10 fixes, now reviewed, were: an undetectable base branch prints
`SKIPPED-DUPLICATE-BASE` and continues instead of exiting 2, with a test, so a
detached-HEAD CI checkout works while a skipped gate still announces itself;
`tests/evidence.sh` comparing the emitted test names against the submitted
ones, not merely their count, and pruning the vendored bats-core from its file
enumeration; and the corrections to this record and the plan listed above.

## Known gaps shipped with this change

Recorded here because a green run must state what it did not check.

**Closed only by follow-up changes:**

1. A missing or misspelled config **key** reads as "this project does not use
   that". `doc_rmff:` disables the hazard gates, `test_path:` disables
   `MISSING-TEST`, `strict_path:` drops half of `DANGLING-REF`, a present but
   empty `test_paths:` list does the same, and a config with none of these keys
   runs every gate off — each exiting 0. `sources:` is the tell. Change B.
   `finalize-ids.sh` shares the blind spot; `check-ids.sh` catches that case
   one merge step later.
2. `checked:` counts items found anywhere in the tree, not items examined. An
   item defined outside its configured document is counted and read by no gate.
   Change C.

**Live in change A, judged acceptable and left recorded:**

3. `gr_doc_files` establishes that a ledger file is "present" with a filesystem
   glob, while `require_paths` asks git. A `doc_*` directory whose `*.md` files
   are gitignored is therefore counted in `sources:` and scanned by nothing.
   Pre-existing; what change A adds is the `sources:` line asserting the file
   was read.
4. A git submodule configured as a path passes the existence check and is
   counted as a source, but `git grep` scans nothing inside it.
5. A `doc_*` directory is read one level deep; `*.md` files in a subdirectory
   produce "contains no `*.md` files", which is true of that directory only.
6. `require_paths` discards `git ls-files`' exit status, so a pathspec git
   itself rejects is reported as "matches no file" — loud, but the wrong cause.
7. Ordinary prose containing `Word-DRAFT-word-N` now blocks **both**
   `finalize-ids.sh` and `check-ids.sh`, so such a project cannot merge until
   the prose is reworded or the prefix declared. The diagnostic names both
   causes; there is no escape hatch beyond `--allow-drafts`, which the merge
   sequence deliberately does not use.
8. Neither `git grep` status check — `finalize-ids.sh`'s pre-flight nor
   `check-ids.sh`'s draft scan — has a test, and neither can be provoked from a
   fixture: git grep reports several real failures on stderr while still
   exiting 1. A draft ID inside an **untracked** file the working tree cannot
   read is therefore invisible to both merge gates, which exit 0. For a
   *tracked* unreadable file `check-ids.sh` fails loudly at its `git diff`
   guard — but only when it has a usable base branch; on a detached HEAD that
   guard never runs and both gates exit 0 again. The status checks catch the
   loud failures only.
9. `ids_matching` gained `-I`, and `finalize-ids.sh` sets `IFS` to newline;
   neither has a dedicated test.
10. `check-signing.sh` exits 0 having examined nothing on an empty rev range
    (`main..main`) and prints no denominator. Untouched here; a member of the
    same defect class wanting its own change.
11. `tests/evidence.sh` has no automated test. Its dead-branch bug and its
    unrun-test inflation were both found by review, not by a test.
12. Both draft scans use `git grep -I`, so a draft token inside a file git
    treats as binary is invisible to both merge gates, and `ids_matching`'s
    `-I` means an annotation there yields a false `MISSING-TEST`.
13. `check-ids.sh`'s in-tree `DUPLICATE-ID` scan still discards its status,
    fifteen lines below the scan that now checks it. A failing scan yields an
    empty result and a silent pass.
14. `finalize-ids.sh`'s ID-rewrite pass runs in a pipeline subshell and does
    not check `sed`'s status, so a failed rewrite leaves the draft token in the
    tree and the script continues to `exit 0`. Backstopped by `check-ids.sh` at
    the next merge step.
15. The duplicate-vs-base gate also runs vacuously — silently, with no notice —
    whenever the checkout's own branch is the detected base, the ordinary
    single-worktree CI shape: the merge base resolves to `HEAD`, nothing reads
    as newly added, and the gate passes having compared nothing. Pre-existing
    at `cb130db`. `SKIPPED-DUPLICATE-BASE` announces the loud skip; this quiet
    one is not announced, and the merge sequence relies on the worktree
    discipline that stops it arising.
16. `check-trace.sh`'s own scans (`ids_defined`, `ids_matching`, the
    `DANGLING-REF` scope scan) discard `git grep`'s exit status. The `checked:`
    and `sources:` lines are the mitigation, not a guarantee.

**Upgrade impact for existing projects** — three exit-1 changes, all documented
in the ratchet skill: annotations are read as ID lists (`verifies: A and B` now
credits `A` alone); an SDD block ends at the next definition line or heading (a
`**Bold:**` aside between an SDD header and its `traces:` line now reports
`UNTRACED-DESIGN`); and path entries are git pathspecs, whose `*` crosses `/`,
so `src/*.c` now reaches into subdirectories.
