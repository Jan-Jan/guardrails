# Verification — ledger-names-at-creation (2026-10-13)

branch: ledger-names-at-creation
reviewer: four independent Claude subagents with fresh context, one per round,
each in its own task worktree off the change branch, given the diff, AGENTS.md,
the plan and `skills/merge-change/references/review-checklist.md`, at
`f855333`, `722c42a`, `174c1cc` and `9e45db5`; conformance reviews ran in fresh
contexts of their own against `docs/TEST_GUIDELINES.md` (three rounds) and
`docs/CODE_GUIDELINES.md` (one round)
verdict: converged at round 4 — no `code` or `requirement` finding above low in
that round, which `review-checklist.md` makes the last one. Round 2 found a
real defect in a round-1 fix (GNU date read a signed count as a zone offset),
fixed and tested before round 3. Every finding is fixed or carries a
`no change` reason.
reproduced: yes. The midnight flake (PR-pc6byk) was reproduced on demand before
the fix with a `date` stub that answers one day on its first call and the next
day after: "check-trace: trailing whitespace on a field is not part of its
value" reported `UNRESOLVED-PR PR-001 (open 5 days)` for an item written four
days back, and passed under `pin_today`. The rename's costs are not a defect
to reproduce; they are stated in ADR-cy7ahd.

Change: a ledger file is named `docs/<area>/<YYYY-MM-DD>-<slug>.md` the day a
change creates it, and nothing renames it. `finalize-docs.sh` and
`merge-change`'s rename step are deleted, `DRAFT-FILE` becomes an error for the
legacy draft name whose fix line is the `git mv`, `--allow-draft-files` is
retired, and the check-trace age tests count from one pinned day. Implements
ADR-cy7ahd; resolves PR-umtm9b and PR-pc6byk; amends PR-8ucezf and PR-2jr4pj.
Plan: `docs/plans/2026-10-13-ledger-names-at-creation.md`.

Branched from `main` at `9eeb8b6`; base merged from local `main` at `fdc58a6`,
per AGENTS.md non-negotiable 4. `main` moved twice while this change was open
(`25e723f`, then `fdc58a6`) and was merged in each time. The second merge
edited files this change edits, so round 3 reviewed the whole change again.

## The gate

Measured on: `43a15ba` — `git rev-parse HEAD` — tree
`af7348b80e43af3d3ed52842b2d177aca519f930`, clean worktree before and after the
run, `main` at `fdc58a6`. The run was dispatched to a subagent; the verdict is
read from the reported pass and fail counts, not from the exit code. The
merging tree differs from the measured one by this record and by one commit
hash corrected in the plan; the suite reads neither, because it drives
fixtures rather than this repository's own documents.

| Gate | Result |
| --- | --- |
| `tests/run-tests.sh` (parallel) | `1..1400`, 1400 ok, 0 not ok, exit 0 |
| `tests/mutate.sh`, each `docs/verification/*.mutations` directory | 190 applied, 24 retired, 0 unusable, every directory exit 0 |
| `check-ids.sh` (scratch copies, base `fdc58a6` and change `43a15ba`) | exit 1 on both, the same violation classes |
| `check-trace.sh` (scratch copies, base and change) | exit 1 on both, the same violation classes |
| `check-review.sh --cite --branch ledger-names-at-creation` (scratch copy of this record's commit) | exit 0 — 35 findings, every citation resolved |
| Coverage | not configured |
| Working tree | clean |

This repository has no `.guardrails/config.yaml`, so `check-ids.sh` and
`check-trace.sh` ran on `git archive` copies of base and change under a config
built from `templates/config.yaml`, with placeholder SRS, SAD, RMF and SOUP
documents so every gate runs. The violation lines differ only by this change's
own work: two `DRAFT-ID` fixture lines and one `DANGLING-REF` fixture token
belonged to the deleted finalize tests, and `UNRESOLVED-PR PR-umtm9b` is gone
because this change resolves it (problems open 23 → 22).

Earlier full runs, not counted here: 1353 of 1355 at `f855333` (the `lib.bats`
script count, fixed in round 1, and the load-sensitive FIFO test listed under
Gaps), 1358 of 1358 at `722c42a`, 1399 of 1399 at `174c1cc` and 1400 of 1400
at `9e45db5`.

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| ADR-cy7ahd (D1, D2) | `ledger files: the skills and templates name a ledger file at creation, and nothing renames it` | red on `DRAFT-<branch>-<slug>` still taught in analyze-risks and others, then on `finalize-docs.sh still ships` |
| ADR-cy7ahd (D3) | `check-ids: --allow-draft-files is gone, and is rejected rather than ignored` | red: exit 0, the flag was accepted |
| ADR-cy7ahd (D3) | `check-ids: the DRAFT-FILE fix line is the git mv to a dated name` | red: the old `--allow-draft-files` / finalize-docs.sh fix line |
| ADR-cy7ahd (D3) | `merge-preflight: IDS fails on a draft-named ledger file, and its fix line renames it` | red: `expected in output: git mv it to <YYYY-MM-DD>-<slug>.md` |
| ADR-cy7ahd (D3) | `check-ids: a file listing that fails is an error, not a tree with no draft-named ledger file` | red: `failed listing read as a clean tree: 0` |
| ADR-cy7ahd (D4) | `check-trace: the DANGLING-FILE remedy and message name the file's current name` | red: `Write the dated name the draft file was merged under` |
| ADR-cy7ahd (D4) | `check-trace: a bare DANGLING-FILE name says to write the name the file has now, or the path across units` | red: `after a merge, write the dated name; across units, write the path` |
| ADR-cy7ahd (D5) | `merge-change: no step renames a ledger file, and step 3 confirms the tree the summary describes` | red: `finaliz` in the frontmatter and step 3 |
| ADR-cy7ahd (D6) | `merge-change: two changes that name a ledger file alike meet at step 1, and the documented resolution keeps both` | red: step 1 had no add/add bullet |
| ADR-cy7ahd (D7) | `ratchet: the upgrade notes say ledger files are named at creation, and how to rename a draft in flight` | red: no section |
| ADR-cy7ahd | `ADRs: the ledger-naming decision is recorded and accepted` | red: no ADR file |
| ADR-cy7ahd (D8) | `mutations: the retirement count is pinned, so one more is a visible edit` | red: `the corpus declares 18 retired mutations, expected 24` |
| PR-pc6byk | `check-trace: an age is counted from the pinned day on both sides` | red: `pin_today: command not found`, then `days_ago 1: 2026-10-12` with the stub only |
| PR-pc6byk | `pinned date stub: answers today as one YYYY-MM-DD line check-trace accepts` | red with the stub printing `%s 00:00`: `not YYYY-MM-DD: 2026-03-01 00:00` |
| PR-pc6byk | `days_ago counts back from a pinned day whose local midnight does not exist` | red before the noon anchor: `no usable date(1) for relative dates`; red with the time after the day: `gnu date: days_ago 1, -1, -2 = '2026-09-05 2026-09-05 2026-09-05'` |
| PR-pc6byk | `pinned date contract: the real date answers today the same way` | not a red-to-green test: a contract test against the real `date`, green throughout; its midnight tolerance was shown under a stub that changes day (`open 1 days`) |

Re-cut mutations: M23 applied and `check-ids.bats` failed "--allow-drafts is
gone, and is rejected rather than ignored" and "--base is gone, and is rejected
rather than ignored"; M25 applied and failed "draft-named file fails with
DRAFT-FILE", "a draft ledger filename fails" (since renamed `check-ids: a
draft-named ledger file fails`) and "a sibling's draft file and draft token are
not this unit's finding". M22, M37–M41 and M53 are retired with the flag and
the script they mutated.

## What was wrong, and what was built

A change wrote its ledger file as `DRAFT-<branch>-<slug>.md` and `merge-change`
step 3 ran `finalize-docs.sh`, which renamed it to the finalize date and
rewrote references to it across the ledger directories and the SOUP file. Once
IDs became random tokens minted at write time, the rename finalized nothing;
its own header called the filename "a handle for finding the file, not a
record of when it merged". It still cost a late commit that rewrote shared
ledger files after review, and its `-2` collision check saw only the local
disk.

ADR-cy7ahd names a ledger file the day its change creates it, as plans already
are. `scripts/finalize-docs.sh` and `tests/finalize-docs.bats` are deleted.
`check-ids.sh` keeps `DRAFT-FILE` as an error for the legacy name with a
`git mv` fix line, rejects `--allow-draft-files`, and now fails closed when its
file listing fails. `check-trace.sh`'s `DANGLING-FILE` says to write the name
the file has now. `merge-change` loses the rename step and keeps its step
numbers (D5); step 1 states how two changes that pick the same name resolve
the add/add conflict. The skills, templates, READMEs and upgrade notes name a
file at creation, and the ratchet upgrade deletes the installed script.

The age tests in `tests/check-trace.bats` read the clock in the fixture and
again inside the script, so a run crossing local midnight saw an age one day
too old. `pin_today` in `tests/helpers.bash` puts a `date` stub on `PATH`, and
`days_ago` counts from the same pinned day; GNU date is anchored at noon with
the time before the day.

## Review

### Round 1

Reviewed `f855333`, the change after `main`'s `25e723f` was merged in.

**finding-1**: code, medium — `tests/lib.bats:759` still pinned 13 scripts after `finalize-docs.sh` was deleted, so "every script stops outside a git repository, at gr_root" failed every run.
disposition: fixed — tests/lib.bats pins 12; the test is "every script stops
outside a git repository, at gr_root".

**finding-2**: code, low — `scripts/check-trace.sh:1380` justified a token rule by a `DRAFT-<branch>-<slug>.md` placeholder this change removed from every shipped README.
disposition: fixed — scripts/check-trace.sh says the READMEs carried it before
ADR-cy7ahd and an older adopter's copy may still carry it.

**finding-3**: requirement, low — `skills/merge-change/references/rationale.md:142` described the draft convention in the present tense.
disposition: fixed — skills/merge-change/references/rationale.md states it as
retired by ADR-cy7ahd.

**finding-4**: code, low — `tests/skills.bats:1419` named and commented a test as if finalize-docs.sh were current.
disposition: fixed — tests/skills.bats renames it "the skills and templates
name the creation date, not the merge date".

**finding-5**: code, low — `tests/helpers.bash:237` anchored GNU `days_ago` at local midnight, which does not exist on a day DST starts at 00:00.
disposition: fixed — tests/helpers.bash anchors at noon; the test is "days_ago
counts back from a pinned day whose local midnight does not exist".

**finding-6**: record — the plan carried no `red -> green:` lines, no guideline review findings and no evidence for the M23/M25 re-proofs.
disposition: fixed — docs/plans/2026-10-13-ledger-names-at-creation.md carries
a Done note per task and the guideline reviews.

### Round 2

Reviewed `722c42a`, the round-1 fixes.

**finding-1**: code, medium — the noon anchor `date -d "<day> 12:00 -1 days ago"` made GNU date read a signed count as a UTC offset, so `days_ago -1` returned the day before; check-trace.bats would fail on any GNU machine, and the BSD `date` on the gate machine hid it.
disposition: fixed — tests/helpers.bash writes `12:00 <day> N days ago`; the
test "days_ago counts back from a pinned day whose local midnight does not
exist" asks for counts 1, -1 and -2 under every GNU and BSD date present, and
`tests/check-trace.bats` passed 338 of 338 with gdate first on PATH.

**finding-2**: requirement, low — the midnight-less-day test cited PR-pc6byk, which did not state the noon anchor.
disposition: fixed — PR-pc6byk's resolution in
docs/problems/2026-10-13-age-tests-cross-midnight.md states the anchor and why.

**finding-3**: requirement, low — the real-date contract test cited D11 of `docs/plans/2026-10-07-test-seams.md`, which covers only the two platform stubs.
disposition: fixed — tests/portability.bats cites PR-pc6byk alone.

### Round 3

`main` moved to `fdc58a6` (code guidelines; develop-change split; the guideline
review renamed `review-conformance`) and edited files this change edits —
`README.md`, `scripts/check-trace.sh`, `scripts/prune-plans.sh`, the
grill-requirements, ratchet, resolve-problem, verify-before-merge and
worktree-discipline skills, `skills/merge-change/references/review-checklist.md`,
`templates/AGENTS-block.md`, `templates/verification.md`, `tests/helpers.bash`,
`tests/remedies.bats` and `tests/skills.bats` — so this round reviewed the whole
change at `174c1cc`. The one merge conflict was in tests/skills.bats: this
branch deleted the finalize test that `main` left beside its rewritten naming
test, and the resolution keeps `main`'s test.

**finding-1**: record — the plan recorded no `docs/CODE_GUIDELINES.md` conformance review and still named `review-guidelines` and "closing passes".
disposition: fixed — docs/plans/2026-10-13-ledger-names-at-creation.md records
the CODE review and names `review-conformance`.

**finding-2**: record — the plan's Files touched omitted `skills/merge-change/references/review-checklist.md` and `skills/worktree-discipline/references/rationale.md` (T4) and `tests/lib.bats` (T6).
disposition: fixed — docs/plans/2026-10-13-ledger-names-at-creation.md lists
them.

### Round 4

Reviewed `9e45db5`, the round-3 fixes. Nothing above low.

**finding-1**: requirement, low — "check-ids: a file listing that fails is an error, not a tree with no draft-named ledger file" cited D3, which did not state the fail-closed scan.
disposition: fixed — D3 in docs/plans/2026-10-13-ledger-names-at-creation.md
states that a failing `git ls-files` or grep exits 2.

**finding-2**: code, low — comments in `scripts/check-ids.sh:140` and `tests/skills.bats:1329` said only status 1 passes, where 0 and 1 pass.
disposition: fixed — scripts/check-ids.sh and tests/skills.bats say 0 and 1
pass and 2 or above is fatal.

**finding-3**: code, low — the test name "check-ids: a draft ledger filename fails" kept a third name for the concept.
disposition: fixed — tests/check-ids.bats names it `check-ids: a draft-named
ledger file fails`.

**finding-4**: code, low — the `DRAFT-FILE` fix line in `scripts/check-ids.sh:49` said "nothing renames a ledger file at merge any more".
disposition: fixed — scripts/check-ids.sh says "no merge step renames a ledger
file"; tests/remedies.bats pins it and D3 quotes it.

**finding-5**: record — the plan credited the skills.bats grep-status fix to `1f18d23`, which is in `fb2c2e7`.
disposition: fixed in this record and in
docs/plans/2026-10-13-ledger-names-at-creation.md.

## Guideline reviews

### docs/TEST_GUIDELINES.md

Governs: tests/

### Round 1

**finding-1**: guideline, medium — Doubles 3, "Every fake has a contract test" — tests/helpers.bash:262
disposition: fixed — tests/portability.bats runs one assertion against the
stub and the real `date`: "pinned date stub: answers today as one YYYY-MM-DD
line check-trace accepts" and "pinned date contract: the real date answers
today the same way".

**finding-2**: guideline, medium — Seams 1 and the floor, "every test carries `verifies:`" — tests/check-ids.bats:109
disposition: fixed — tests/check-ids.bats cites AC5, PR-xyu6en and AC9 on the
three edited tests.

**finding-3**: guideline, low — Existing suites 1, "a change that must edit an existing test that breaks them moves it to the seam" — tests/check-ids.bats:109
disposition: no change — a structural rule over the scripts' source has no
command-line seam; docs/plans/2026-10-08-check-review-cite.md ruled the same
test the same way.

### Round 2

**finding-1**: guideline, medium — Seams 1 with Existing suites 1 — tests/lib.bats:725
disposition: fixed — tests/lib.bats cites the fail-closed gr_root guard stated
in docs/verification/2026-08-27-config-schema.md.

**finding-2**: guideline, low — Existing suites 1 — tests/check-ids.bats:109
disposition: no change — as round 1's finding-3 (tests/check-ids.bats).

The review also noted that the real-date contract test read the clock twice
and asserted `open 0 days`; tests/portability.bats now accepts `open 1 days`
only when a third read shows the day changed.

### Round 3

**finding-1**: guideline, low — Seams 1, "a test verifies the problem report or the plan decision that states the behavior" — tests/check-ids.bats:50
disposition: fixed — D3 in docs/plans/2026-10-13-ledger-names-at-creation.md
states the fail-closed scan.

**finding-2**: guideline, low — Seams 1 — tests/remedies.bats:263
disposition: fixed — D4 in docs/plans/2026-10-13-ledger-names-at-creation.md
quotes the remedy scripts/check-trace.sh prints.

**finding-3**: guideline, low — Seams 1 — tests/lib.bats:727
disposition: no change — no problem item or surviving plan decision states the
gr_root guard; docs/verification/2026-08-27-config-schema.md is its only
statement.

### docs/CODE_GUIDELINES.md

Governs: scripts/ tests/

### Round 1

**finding-1**: guideline, low — Errors 2, "no error output sent away where the caller needs it" — scripts/check-ids.sh:137
disposition: fixed — scripts/check-ids.sh exits 2 when `git ls-files` fails;
the test is "check-ids: a file listing that fails is an error, not a tree with
no draft-named ledger file".

**finding-2**: guideline, low — Errors 2 — tests/skills.bats:1328
disposition: fixed — tests/skills.bats keeps grep's status and passes only 0
or 1.

**finding-3**: guideline, low — Errors 1, "An error is reported where it is detected" — tests/helpers.bash:280
disposition: fixed — tests/helpers.bash: `pin_today` prints what failed.

**finding-4**: guideline, low — Names 2, "no chained conditional expression standing in for an `if`" — tests/helpers.bash:253
disposition: fixed — tests/helpers.bash uses `if`.

**finding-5**: guideline, low — Comments 2, "A comment describes the code as it is, never the change that wrote it" — scripts/check-ids.sh:10
disposition: fixed — scripts/check-ids.sh states the rule.

**finding-6**: guideline, low — Comments 2 — scripts/check-trace.sh:1370
disposition: fixed — scripts/check-trace.sh.

**finding-7**: guideline, low — Comments 2 — tests/merge-preflight.bats:247
disposition: fixed — tests/merge-preflight.bats.

**finding-8**: guideline, low — Comments 2 — tests/remedies.bats:160
disposition: fixed — tests/remedies.bats.

**finding-9**: guideline, low — Comments 2 — tests/check-ids.bats:460
disposition: fixed — tests/check-ids.bats.

**finding-10**: guideline, low — Comments 2 — tests/skills.bats:1447
disposition: fixed — tests/skills.bats.

**finding-11**: guideline, low — Names 4, "A concept has one name in every file, test and task of the change" — scripts/check-trace.sh:261
disposition: fixed — scripts/check-ids.sh and scripts/check-trace.sh say
"draft-named ledger file".

## Gaps

- **`PR-8ucezf` stays open** (D3): `DRAFT-FILE` still scans the whole tree, not
  the files the branch adds. Nothing creates a draft name now, so only a legacy
  draft can trip it.
- **A target project's in-flight drafts are renamed by hand** (D7): the upgrade
  note gives the `git mv`.
- **The installed skill copies under `~/.agents/skills/` are the user's to
  refresh** after this merges (D2).
- **The GNU `date` path is not exercised by the suite on this Mac**, whose
  `/bin/date` is BSD. It was checked once with gdate first on PATH
  (`tests/check-trace.bats` 338 of 338) and by the portability test, which runs
  each GNU and BSD date present.
- **One load-sensitive test** failed under heavy contention in round 1:
  `new-id: a FIFO is rejected rather than read` times out at 20 seconds and
  reads the timeout as "blocked". It passed alone (28 of 28), and this change
  does not touch `new-id.sh`.
- **`merge-preflight.sh` was not run**: this repository configures no
  `.guardrails/`, so the pre-flight has nothing to read. The check scripts ran
  on scratch copies instead, as the gate section states.
- **The mutation corpus was run, not re-cut**, beyond M23 and M25: the counts
  are in the gate table.
