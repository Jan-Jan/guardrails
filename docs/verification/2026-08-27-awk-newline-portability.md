# Verification — awk-newline-portability (2026-08-27)

branch: awk-newline-portability
reviewer: an independent subagent, dispatched at step 6a with only the diff, the problem ledger and the field report — no implementation narrative and no chat history
verdict: accepted after disposition. Eleven findings, none disputing the fixes themselves: the reviewer confirmed all four problem reports fixed with correct root causes, each by reverting the hunk and watching the named test redden. Ten findings were fixed in this change; one is recorded open as PR-aap8nx.
reproduced: yes. The reported symptom was reproduced verbatim on this machine before anything was changed — `awk -v kws='a:<newline>b:' 'BEGIN{print kws}' /dev/null` exits 2 with `awk: newline in string`, and the real `check-review.sh` on a fixture worktree printed the reporter's exact two-line failure and exit 2. The end-to-end fix was then confirmed against the real `/usr/bin/awk`: a complete record exits 0, and dropping `verdict:` gives exactly one `INCOMPLETE-RECORD ... (no verdict:)` at exit 1.

Change: four macOS/BSD portability defects, one in a shipped script and three in the test suite, plus the instruments that make the two classes reproducible on any platform. Branched from `main` at `e6e8acc`; `main` moved to `590867a` mid-change and was merged in at step 1.
Plan: none — this is a problem resolution, `docs/problems/2026-08-27-macos-awk.md`.

## Provenance of the base merge

`git fetch origin` failed in this environment (`Permission denied (publickey)`;
`ssh-add -l` reports no identities), so step 1 merged the **local** `main` ref
at `590867a`, not `origin/main`. Named here because step 4's duplicate scan is
only as complete as what step 1 merged in: any ID defined on the remote and not
in this clone was not compared against.

## The gate

Every figure derived from the tree under test, not carried forward.

| Gate | Result |
| --- | --- |
| `./tests/run-tests.sh` | 409 tests, 409 ok, 0 failures, exit 0 |
| `check-ids.sh` | exit 1 — byte-identical to `main`'s own output (`diff` empty). 44 `DRAFT-ID`, 1 `DUPLICATE-ID`, all pre-existing fixture and historical-prose residue; 0 `DRAFT-FILE`, 0 `MALFORMED-ID` |
| `check-trace.sh` | exit 1 — 1 `MISPLACED-ITEM`, 5 `DANGLING-REF`, same residue; plus `UNRESOLVED-PR PR-aap8nx`, which is a warning and is deliberate. `problems: open 1`, no `INCOMPLETE-PROBLEM`, no `MALFORMED-STATUS`, no `MALFORMED-DATE` |
| Coverage, against the class target | Not applicable — class A (`docs/adr/2026-08-22-safety-class.md`) |
| Working tree | clean |

Both check scripts were run under a synthesized `GR_CONFIG` declaring `PR` and
`doc_problems`, because this repository still has no `.guardrails/` of its own.
That is the blocker measured in `docs/plans/2026-08-22-ratchet-gap-analysis.md`
and it is unchanged by this change. Neither run is a gate this repository
passes; what they establish is narrower and is stated as such in Gaps.

Derived by `tests/evidence.sh main`:

- Suite: **409 tests** (main: 400); 404 measured against `main`.
- New or renamed since `main`: **9**.
- Of those, **3** go red when run against `main`'s scripts.
- **6** cannot go red: the three strict-awk calibrations, the BSD-date
  calibration, the `days_ago` test and the `sed` lint. None is counted as
  evidence that a defect was fixed. Six is expected rather than a shortfall:
  `evidence.sh` rolls back `scripts/` only, so no test-only fix — PR-yd2sft,
  PR-44z762, PR-mu8ybm — can ever be measured by it, and the calibrations
  exercise the instruments rather than the toolkit.

## What was wrong, and what was built

`check-review.sh` interpolated `GR_RECORD_FIELDS`, which carries two literal
newlines, straight into `awk -v kws=`. BWK awk — `awk version 20200816`, the
`/usr/bin/awk` that ships with macOS and the only awk on a stock box — refuses
a literal newline in a `-v` assignment and exits 2 before the program runs.
gawk, mawk and busybox awk all accept it, and every measurement recorded in
this toolkit's comments was taken on one of those three. The consequence was
worse than a false pass and less visible: on macOS the gate never read a
record at all, and exit 2 reads as a setup error, so the natural response was
to go looking in the project's own configuration.

awk now reads `GR_RECORD_KWS`, the same list flattened to spaces and computed
once. `GR_RECORD_FIELDS` stays newline-separated: `IFS` is a newline for the
whole script, so flattening it at the definition would collapse
`for _kw in $GR_RECORD_FIELDS` to a single word and report `INCOMPLETE-RECORD`
against every record in the repository — a false failure replacing a setup
error, which is the trap the field report warned about and which the review
verified is avoided.

Three more defects of the same shape were found while reproducing that one:
`days_ago` spelled the sign twice for BSD `date`; one `sed -i` in
`tests/lib.bats` omitted its backup suffix; and nine more arrived on the base
branch with `590867a`, three of which use GNU-only sed addresses that no
suffix would have saved.

What generalises is the instruments. `make_strict_awk` is a stub awk that
reproduces BWK's `-v` strictness — and its operand-assignment strictness — on
any platform, so a Linux developer sees what a macOS user sees; every script
that reaches awk is swept under it. `make_bsd_date` is the same instrument for
`date`. Both are calibrated in both directions before use, because an
instrument that never fires reports a clean bill of health for a broken tree.
`AGENTS.md` now names the four supported awk implementations and states both
rules; `skills/ratchet/SKILL.md` tells operators that step 6c has never
executed on macOS and that the remedy is re-running the gate over existing
records, not assuming they were fine.

## Review

**finding-1**: The `guardrails_version` bump was silently lost in the base merge, so the fix would ship as `0.5.0` — the same number `main` publishes without it, leaving no way for a project to tell whether its copy contains the fix.
disposition: bumped to `0.5.1` in `templates/config.yaml`. Confirmed by measurement that the pre-merge branch carried `0.4.1` and that `git diff main HEAD -- templates/config.yaml` had become empty.

**finding-2**: Two counts in the PR-mu8ybm resolution were falsifiable and false — "seven arrived" and "seven gained the suffix, three could not" (7+3=10).
disposition: measured independently and corrected to nine arrived, six suffixed, three rewritten. `git grep -c` on `33d0de4` gives 9; the fix diff shows 6 added `sed -i.bak` and 9 removed bare forms.

**finding-3**: The `days_ago` regression test could only redden on macOS — on exactly the platform where the defect escaped it was green, so folding the BSD branch back would go unnoticed on every Linux run.
disposition: added `make_bsd_date`, a stub `date` that refuses `-d` and a doubled sign in `-v`, with its own calibration test; the `days_ago` test now runs under it. Verified red on revert with the stub in place.

**finding-4**: The `sed` lint used `git grep` and so exited 128 outside a git checkout — which is exactly the tree `tests/evidence.sh` builds, making it count as spuriously red there.
disposition: switched to `grep -r`. A partial copy now `skip`s with a stated reason; in a real checkout a missing search path is a hard failure, so a renamed directory cannot silently turn the check off. Verified both branches by running the test in a mktemp copy and in the repository.

**finding-5**: The lint's stated anti-vacuity guard rested on a false premise — `git grep` returns 1, not 128, for a pathspec naming no such directory, so the exit code never carried the meaning the comment claimed.
disposition: measured and confirmed (exit 1). Replaced with a positive control that proves the pattern still matches the defect it names, built with `printf` so the test file does not contain the spelling it hunts, plus an explicit path-existence check. Verified the lint reddens on a planted violation.

**finding-6**: The lint does not reach `docs/`, where sixteen bare `sed -i` calls sit in the mutation scripts under `docs/verification/*.mutations/`, so re-running this project's own mutation evidence dies on BSD sed — and the ledger claimed the lint "greps the whole toolkit".
disposition: the false claim was corrected to name the paths actually searched. The defect itself is recorded as PR-aap8nx and left **open** deliberately: those are prior changes' verification artefacts, not this change's code, and rewriting sixteen of them is its own change with its own review.

**finding-7**: `del_first_line` compared with `$0 == want`, which awk's strnum rules make numeric when both sides look like numbers, so a line `  10` would match `want=010` — not the "exactly equal" the helper's own comment promises.
disposition: forced string comparison with `$0 "" == want ""`.

**finding-8**: The strict-awk stub watched `-v` only. Real BWK awk rejects a bare `k=value` operand assignment identically, so a defect of the same class would pass straight through.
disposition: the stub now walks awk's options properly and checks operands after the program. Walking rather than pattern-matching is load-bearing — the program text is not an assignment however much it looks like one, and `BEGIN { n = split(kws, K) }` carries both an identifier and an `=`. Verified it intercepts a newline-carrying operand and still passes all five real scripts.

**finding-9**: Six of the new tests carried no `verifies:` annotation, including the anti-vacuity test and the one the ledger names as the class reproducer — so deleting either would break no link.
disposition: all six annotated.

**finding-10**: `make_strict_awk`'s self-exclusion was a comment rather than a guard — calling it with the stub already on PATH would bake the stub's own path into its `exec` and fork indefinitely — and that `exec` was unquoted.
disposition: both are guards now; the same guard was written into `make_bsd_date` from the start.

**finding-11**: `[[PR-44z762]]` used a wiki-link notation that appears nowhere else in the repository.
disposition: replaced with the bare ID, which is how every other cross-reference in the toolkit is written.

## Gaps

- **The check scripts were not run as gates on this repository, because it has
  no `.guardrails/`.** They were run under a synthesized `GR_CONFIG` declaring
  `PR` and `doc_problems` alone, so the REQ/HAZ/RC/SDD/LLR gates did not
  execute at all, and `DANGLING-REF` scanned only the `PR` prefix. What that
  establishes is exactly two things: this change's own ledger items are
  well-formed, and this change adds nothing to the pre-existing violation set
  — `check-ids.sh` output diffs empty against `main`. It does not establish
  that the repository is clean; it is not, and
  `docs/plans/2026-08-22-ratchet-gap-analysis.md` measures why.
- **`origin` was never contacted.** See the provenance note above.
- **PR-aap8nx is open.** Sixteen mutation scripts under `docs/verification/`
  still carry the bare `sed -i` form and still die on BSD sed.
- **The `awk` sweep covers `scripts/` only.** `tests/helpers.bash` now itself
  calls `awk -v` in `del_first_line`, and `-v` values inside the test helpers
  are not swept. The value there is a single-line literal today; nothing
  enforces that it stays one.
- **No macOS run of the mutation-testing evidence.** The `.mutations/M*.sh`
  suites belonging to earlier changes were not re-run on this platform, which
  is how PR-aap8nx would have been found by measurement rather than by review.
- **Linux was not tested directly.** Every claim about gawk/mawk/busybox
  behaviour in this change rests on the stubs and on the field report, not on
  a run against those implementations. The stubs are what make that acceptable
  — they reproduce the strict behaviour on any platform — but the converse,
  that the fixed scripts still work on a real gawk, is argued rather than
  measured here.
