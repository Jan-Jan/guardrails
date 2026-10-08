# find-items.sh Implementation Plan

**Goal:** Add `scripts/find-items.sh`, a script that lists, shows and finds
references to ledger items. An agent then reads one item instead of a whole
ledger file, and the skills that currently read ledgers whole run it instead.
**Implements:** no requirement items exist in this repository. Traced to the
2026-10-03 discussion with the user. Decision: a lookup script over the
existing per-change ledgers. Moving to one file per item, an index file per
kind, and `open/` and `closed/` directories for problem reports was considered
and rejected. Reasons: the index needs no restructure; a hand-kept index
drifts and conflicts between parallel changes; a directory status duplicates
the `status:` field and has no place for `accepted`.
**Safety class:** the toolkit itself is unclassified; it enforces class B/C
projects. `find-items.sh` gates nothing, so it is outside the tool
qualification list in `skills/ratchet/SKILL.md`.
**Verification:** `sh tests/run-tests.sh`, dispatched to a subagent
(AGENTS.md non-negotiable 3); the verdict comes from the reported pass/fail
counts. Mutation evidence for the new script, `tests/mutate.sh`, is in T4.

**Base.** Branched from local `main` at `fd9a867` on 2026-10-04, while
`agent-first-scripts` is unsigned. The user decided this on 2026-10-04 and
overrode AGENTS.md non-negotiable 4 for this change. Every pinned count below
was measured on `fd9a867`, where `scripts/` contains 9 files. When
`agent-first-scripts` is merged to `main` first, its two new scripts conflict
with this change in `tests/check-ids.bats`, `tests/lib.bats`, `README.md` and
`templates/AGENTS-block.md`. Each pin then takes the count on the merged base
plus one, and the pin test prints that count when it fails.

---

## Interface

```
find-items.sh list [--kind PREFIX] [--status open|accepted|resolved]
find-items.sh show ID
find-items.sh refs ID
```

- `list` prints one line per item defined in the configured `doc_*` files:
  `<ID> <status> <file>:<line> <rest of the definition line>`. The status is
  the first column-one `status:` line in the block, the same line
  `check-trace.sh` reads, or `-` when the block has none.
- `show` prints the block of every definition of the ID. Each block follows a
  `==> file:line` line, and two blocks are separated by one blank line. A block
  ends where the gates end it (`GR_AWK_ITEM_BLOCK`): at a heading, at the next
  bold line that contains a colon, or at the end of the file. Blank lines at
  the end of a block are not printed.
- `refs` prints `file:line:text` for every line in the working tree (tracked or
  untracked, not ignored, not binary) that contains the ID as a whole word,
  except the ID's definition lines. It searches the whole repository, not one
  unit.
- Exit codes: 0 answered; 1 `show` found no definition, printed as
  `NOT-FOUND <ID>` followed by a `fix NOT-FOUND:` line; 2 usage or environment
  error. `list` with no matching items and `refs` with no references exit 0
  with no output.
- Under a unit manifest, `GR_CONFIG` names the unit config, as it does for
  the check scripts.

## Scope

Not in this change:
- A `superseded` status for items with a `superseded-by:` line.
- Changes to `skills/ratchet/SKILL.md`. Its copy step uses the glob
  `scripts/*.sh`, so the new script is copied without an edit. Its CI and
  tool-qualification lists name gates, and this script is not a gate.

## Tasks

| Task | Files | Parallel |
|---|---|---|
| T1 | script, its tests, the three tests that enumerate scripts | no (first) |
| T2 | `templates/AGENTS-block.md`, `README.md` | yes, with T3 and T4, after T1 |
| T3 | three skills | yes, with T2 and T4, after T1 |
| T4 | mutation scripts, verification record | yes, with T2 and T3, after T1 |

---

### T1 — find-items.sh and its tests

**Files touched:** `scripts/find-items.sh`, `tests/find-items.bats`,
`tests/check-ids.bats`, `tests/lib.bats`, `tests/portability.bats`
**Parallel:** no (serial, first)

The three enumeration tests are in this task because adding any file to
`scripts/` turns them red. Splitting them out would leave the suite red
between two tasks.

**Step 1 — write the failing tests.** Create `tests/find-items.bats`:

*(Code pruned at merge: 214 lines. Files touched: `scripts/find-items.sh`, `tests/find-items.bats`, `tests/check-ids.bats`, `tests/lib.bats`, `tests/portability.bats`.)*

**Step 2 — run them and see them fail.**

*(Code pruned at merge: 1 line. Files touched: `scripts/find-items.sh`, `tests/find-items.bats`, `tests/check-ids.bats`, `tests/lib.bats`, `tests/portability.bats`.)*

Expected: `17 tests, 17 failures`. Each test fails at its first status
assertion with status 127, because `.guardrails/scripts/find-items.sh` does
not exist. A test that passes here asserts nothing; stop and report it.

**Step 3 — write the script.** Create `scripts/find-items.sh` with this
content, then `chmod 755 scripts/find-items.sh`. `tests/check-trace.bats`
requires index mode 100755 for every tracked `*.sh`.

*(Code pruned at merge: 199 lines. Files touched: `scripts/find-items.sh`, `tests/find-items.bats`, `tests/check-ids.bats`, `tests/lib.bats`, `tests/portability.bats`.)*

The two awk programs are single-quoted, so neither may contain an
apostrophe. "every script parses as POSIX sh" catches one that does.

**Step 4 — run the new tests and see them pass.**

*(Code pruned at merge: 1 line. Files touched: `scripts/find-items.sh`, `tests/find-items.bats`, `tests/check-ids.bats`, `tests/lib.bats`, `tests/portability.bats`.)*

Expected: `17 tests, 0 failures`.

**Step 5 — pin the script in the enumeration tests.**

`tests/check-ids.bats`, test "every gr_def_re call site is still a call site,
and no copy joins them". Add one line to each of the seven pin groups, after
the `_check_units` line of that group (the `calls_`, `forms_`, `body_`,
`loose_`, `block_`, `fm_` and `civil_` groups):

*(Code pruned at merge: 7 lines. Files touched: `scripts/find-items.sh`, `tests/find-items.bats`, `tests/check-ids.bats`, `tests/lib.bats`, `tests/portability.bats`.)*

`body_find_items=3` counts these lines: the `grep -Eq` in `check_item_id` and
the two `awk -v body=` lines. `block_find_items=2` counts the two
`"$GR_AWK_ITEM_BLOCK"` lines. The header comment names `GR_AWK_ITEM_BLOCK`
without `$`, so the comment is not counted.

`tests/check-ids.bats` contains this line twice, at the end of the test above
and at the end of "every script parses as POSIX sh":

*(Code pruned at merge: 1 line. Files touched: `scripts/find-items.sh`, `tests/find-items.bats`, `tests/check-ids.bats`, `tests/lib.bats`, `tests/portability.bats`.)*

Replace both with:

*(Code pruned at merge: 1 line. Files touched: `scripts/find-items.sh`, `tests/find-items.bats`, `tests/check-ids.bats`, `tests/lib.bats`, `tests/portability.bats`.)*

`tests/lib.bats`, test "every script stops outside a git repository, at
gr_root": replace
`[ "$n" -eq 8 ] || { echo "expected 8 scripts, got $n"; false; }` with
`[ "$n" -eq 9 ] || { echo "expected 9 scripts, got $n"; false; }`.

`tests/portability.bats`, test "every check script runs clean under an awk that
rejects a newline in -v":
- Add `find-items.sh|list` as the last line of the here-document, after
  `new-id.sh|PR`.
- Change `[ "$swept" -eq 5 ] || { echo "swept $swept scripts, expected 5"; false; }`
  to `6`: the line occurs once and states the figure twice.
- In the `# Covered:` comment, change
  `check-ids.sh, check-trace.sh, check-review.sh, finalize-docs.sh,` /
  `# new-id.sh.` to
  `check-ids.sh, check-trace.sh, check-review.sh, finalize-docs.sh,` /
  `# new-id.sh, find-items.sh.`

**Step 6 — run the four files.**

*(Code pruned at merge: 1 line. Files touched: `scripts/find-items.sh`, `tests/find-items.bats`, `tests/check-ids.bats`, `tests/lib.bats`, `tests/portability.bats`.)*

Expected: 0 failures. Do not pass a file argument to `tests/run-tests.sh`: it
appends the argument to its own glob and runs the whole suite.

**Step 7 — commit.**

*(Code pruned at merge: 4 lines. Files touched: `scripts/find-items.sh`, `tests/find-items.bats`, `tests/check-ids.bats`, `tests/lib.bats`, `tests/portability.bats`.)*

---

### T2 — the script lists name find-items.sh

**Files touched:** `templates/AGENTS-block.md`, `README.md`
**Parallel:** yes, with T3 and T4; after T1

**Step 1.** `templates/AGENTS-block.md`, section "## Check scripts (run from
repo root)". Insert after the `new-id.sh` bullet:

*(Code pruned at merge: 7 lines. Files touched: `templates/AGENTS-block.md`, `README.md`.)*

**Step 2.** `README.md`, section "## Check scripts", table. Insert a row after
the `new-id.sh` row:

*(Code pruned at merge: 1 line. Files touched: `templates/AGENTS-block.md`, `README.md`.)*

**Step 3 — run the tests that read these files.**

*(Code pruned at merge: 1 line. Files touched: `templates/AGENTS-block.md`, `README.md`.)*

Expected: 0 failures.

**Step 4 — commit.**

*(Code pruned at merge: 4 lines. Files touched: `templates/AGENTS-block.md`, `README.md`.)*

---

### T3 — skills find items with the script instead of reading ledgers

**Files touched:** `skills/grill-requirements/SKILL.md`,
`skills/design-architecture/SKILL.md`, `skills/resolve-problem/SKILL.md`
**Parallel:** yes, with T2 and T4; after T1

Each edit replaces the text quoted under "Before" with the text under
"After". If the "Before" text does not occur exactly once, stop and report it:
an edit that matches nothing changes nothing and reports nothing.

**Step 1.** `skills/grill-requirements/SKILL.md`, the overlap probe.

Before:

*(Code pruned at merge: 7 lines. Files touched: `skills/grill-requirements/SKILL.md`, `skills/design-architecture/SKILL.md`, `skills/resolve-problem/SKILL.md`.)*

After:

*(Code pruned at merge: 9 lines. Files touched: `skills/grill-requirements/SKILL.md`, `skills/design-architecture/SKILL.md`, `skills/resolve-problem/SKILL.md`.)*

**Step 2.** `skills/grill-requirements/SKILL.md`, section "## Probe the
architecture".

Before:

*(Code pruned at merge: 3 lines. Files touched: `skills/grill-requirements/SKILL.md`, `skills/design-architecture/SKILL.md`, `skills/resolve-problem/SKILL.md`.)*

After:

*(Code pruned at merge: 5 lines. Files touched: `skills/grill-requirements/SKILL.md`, `skills/design-architecture/SKILL.md`, `skills/resolve-problem/SKILL.md`.)*

**Step 3.** `skills/design-architecture/SKILL.md`, section "## Process", step 1.

Before:

*(Code pruned at merge: 3 lines. Files touched: `skills/grill-requirements/SKILL.md`, `skills/design-architecture/SKILL.md`, `skills/resolve-problem/SKILL.md`.)*

After:

*(Code pruned at merge: 7 lines. Files touched: `skills/grill-requirements/SKILL.md`, `skills/design-architecture/SKILL.md`, `skills/resolve-problem/SKILL.md`.)*

**Step 4.** `skills/resolve-problem/SKILL.md`, section "## 1. Record before
you touch anything".

Before:

*(Code pruned at merge: 2 lines. Files touched: `skills/grill-requirements/SKILL.md`, `skills/design-architecture/SKILL.md`, `skills/resolve-problem/SKILL.md`.)*

After:

*(Code pruned at merge: 7 lines. Files touched: `skills/grill-requirements/SKILL.md`, `skills/design-architecture/SKILL.md`, `skills/resolve-problem/SKILL.md`.)*

**Step 5 — run the skill tests.** `tests/skills.bats` enforces the section
order and the 2,000-word ceiling.

*(Code pruned at merge: 1 line. Files touched: `skills/grill-requirements/SKILL.md`, `skills/design-architecture/SKILL.md`, `skills/resolve-problem/SKILL.md`.)*

Expected: 0 failures.

**Step 6 — commit.**

*(Code pruned at merge: 4 lines. Files touched: `skills/grill-requirements/SKILL.md`, `skills/design-architecture/SKILL.md`, `skills/resolve-problem/SKILL.md`.)*

---

### T4 — mutation evidence for find-items.sh

**Files touched:** `docs/verification/2026-10-04-find-items.mutations/M01.sh`,
`docs/verification/2026-10-04-find-items.mutations/M02.sh`,
`docs/verification/2026-10-04-find-items.mutations/M03.sh`,
`docs/verification/2026-10-04-find-items.mutations/M04.sh`,
`docs/verification/2026-10-04-find-items.mutations/M05.sh`,
`docs/verification/2026-10-04-find-items.mutations/M06.sh`,
`docs/verification/2026-10-04-find-items.mutations/M07.sh`,
`docs/verification/2026-10-04-find-items.md`
**Parallel:** yes, with T2 and T3; after T1

Each mutation has the form of
`docs/verification/2026-08-20-scan-pathspec.mutations/M01.sh`: a `describes:`
line, a checksum before, one `sed -i.bak`, `rm -f` of the backup, and exit 3
when the file did not change. Every `sed` anchor below quotes a line of the
script from T1 step 3 verbatim.

**Step 1 — write the seven mutations.** `M01.sh`:

*(Code pruned at merge: 7 lines. Files touched: `docs/verification/2026-10-04-find-items.mutations/M01.sh`, `docs/verification/2026-10-04-find-items.mutations/M02.sh`, `docs/verification/2026-10-04-find-items.mutations/M03.sh`, `docs/verification/2026-10-04-find-items.mutations/M04.sh`, `docs/verification/2026-10-04-find-items.mutations/M05.sh`, `docs/verification/2026-10-04-find-items.mutations/M06.sh`, `docs/verification/2026-10-04-find-items.mutations/M07.sh`, `docs/verification/2026-10-04-find-items.md`.)*

`M02.sh` to `M07.sh` are the same apart from the `describes:` line and the
`sed` line:

| File | `describes:` | `sed` line | Expected to be killed by |
|---|---|---|---|
| M02 | the last status line wins, not the first | `sed -i.bak 's\|cur != "" && !status_seen && gr_kw_here(line, "status:")\|cur != "" \&\& gr_kw_here(line, "status:")\|' scripts/find-items.sh` | list reads the first status line of an item |
| M03 | trailing blank lines of a block are printed | `sed -i.bak '/^printing && line ~/d' scripts/find-items.sh` | show prints every definition of a duplicated ID |
| M04 | refs prints definition lines | `sed -i.bak 's\|^index(text, definition) != 1 { print }\|{ print }\|' scripts/find-items.sh` | refs lists every mention outside the definition; refs prints nothing and exits 0 for an ID that only its definition names |
| M05 | refs matches the ID inside a longer token | `sed -i.bak 's\|git grep -n -w -F -I --untracked\|git grep -n -F -I --untracked\|' scripts/find-items.sh` | refs lists every mention outside the definition |
| M06 | show exits 0 when nothing is found | `sed -i.bak 's\|END { exit (found_count > 0 ? 0 : 1) }\|END { exit 0 }\|' scripts/find-items.sh` | show reports NOT-FOUND with a fix line and exits 1 |
| M07 | a newline in an argument is not rejected | `sed -i.bak 's\|gr_die "an argument contains a newline"\|:\|' scripts/find-items.sh` | an argument that contains a newline is a usage error |

In the table, `\|` is the escape a markdown table requires. In the file, write
`|`. For example, M02's line in the file is:

*(Code pruned at merge: 1 line. Files touched: `docs/verification/2026-10-04-find-items.mutations/M01.sh`, `docs/verification/2026-10-04-find-items.mutations/M02.sh`, `docs/verification/2026-10-04-find-items.mutations/M03.sh`, `docs/verification/2026-10-04-find-items.mutations/M04.sh`, `docs/verification/2026-10-04-find-items.mutations/M05.sh`, `docs/verification/2026-10-04-find-items.mutations/M06.sh`, `docs/verification/2026-10-04-find-items.mutations/M07.sh`, `docs/verification/2026-10-04-find-items.md`.)*

**Step 2 — prove each mutation applies.**

*(Code pruned at merge: 1 line. Files touched: `docs/verification/2026-10-04-find-items.mutations/M01.sh`, `docs/verification/2026-10-04-find-items.mutations/M02.sh`, `docs/verification/2026-10-04-find-items.mutations/M03.sh`, `docs/verification/2026-10-04-find-items.mutations/M04.sh`, `docs/verification/2026-10-04-find-items.mutations/M05.sh`, `docs/verification/2026-10-04-find-items.mutations/M06.sh`, `docs/verification/2026-10-04-find-items.mutations/M07.sh`, `docs/verification/2026-10-04-find-items.md`.)*

Expected: exit 0, with no mutation reported as unable to apply.

**Step 3 — prove each mutation is killed.** Run in the task worktree with a
clean `scripts/find-items.sh`:

*(Code pruned at merge: 10 lines. Files touched: `docs/verification/2026-10-04-find-items.mutations/M01.sh`, `docs/verification/2026-10-04-find-items.mutations/M02.sh`, `docs/verification/2026-10-04-find-items.mutations/M03.sh`, `docs/verification/2026-10-04-find-items.mutations/M04.sh`, `docs/verification/2026-10-04-find-items.mutations/M05.sh`, `docs/verification/2026-10-04-find-items.mutations/M06.sh`, `docs/verification/2026-10-04-find-items.mutations/M07.sh`, `docs/verification/2026-10-04-find-items.md`.)*

Expected: each `M0N: bats exit 1`. The `not ok` lines include the test named
in the table. `git status` prints nothing. If a mutation gives `bats exit 0`,
no test detects it. Stop and report it as a finding; do not change the
mutation to make it pass.

**Step 4 — write the record.** Create
`docs/verification/2026-10-04-find-items.md` with a "Mutation evidence" section.
It contains the table from step 1 with a column "Killed by (measured)" that
lists the `not ok` test names from step 3 for each mutation, and the commit
it was measured at (`git rev-parse --short HEAD`). The reviewer, verdict and
finding fields of this record are written at `merge-change` step 6, not here.

**Step 5 — commit.**

*(Code pruned at merge: 4 lines. Files touched: `docs/verification/2026-10-04-find-items.mutations/M01.sh`, `docs/verification/2026-10-04-find-items.mutations/M02.sh`, `docs/verification/2026-10-04-find-items.mutations/M03.sh`, `docs/verification/2026-10-04-find-items.mutations/M04.sh`, `docs/verification/2026-10-04-find-items.mutations/M05.sh`, `docs/verification/2026-10-04-find-items.mutations/M06.sh`, `docs/verification/2026-10-04-find-items.mutations/M07.sh`, `docs/verification/2026-10-04-find-items.md`.)*

---

## Execution

1. Change worktree `.worktrees/find-items` on branch `find-items`, from local
   `main` at `fd9a867`. This plan is committed there as
   `docs/plans/2026-10-04-find-items.md`.
2. Dispatch T1 to a subagent in `.worktrees/find-items/.worktrees/find-items-t1`.
   Merge it into the change branch.
3. Dispatch T2, T3 and T4 in parallel, in `find-items-t2`, `find-items-t3` and
   `find-items-t4`. Their file sets do not intersect. Merge each one.
4. `verify-before-merge`: dispatch `sh tests/run-tests.sh` to a subagent and
   read the pass/fail counts.
5. `merge-change`, with the base merged from local `main`, per AGENTS.md
   non-negotiable 5.

## Self-review

1. Implements: no item IDs. Every behaviour in "Interface" has a test in T1:
   the list format, the kind and status filters, block end, first status, soup
   deduplication, show block and trailing blanks, duplicate IDs, NOT-FOUND,
   malformed IDs, refs inclusion and exclusion, the usage error and the
   newline guard.
2. Every step contains the code, the command and the expected output.
3. Names are consistent: `find_items_usage`, `find_items_remedy`,
   `check_item_id`, `ledger_files`, `list_flush`, `status_value`,
   `status_seen`, `found_count`, `blank_run`. The M02 to M07 anchors quote
   lines from T1 step 3 verbatim.
4. File sets: T1 owns the script and four test files. T2, T3 and T4 own
   disjoint sets, and none of them touches a T1 file.

## Progress

Baseline at `5c21325` (plan commit on local `main` `fd9a867`):
`sh tests/run-tests.sh` reported 752 tests, 752 `ok`, 0 `not ok`, with a
clean `git status`.

Corrections made during execution:
- T3 step 1: the Before text ended inside a paragraph, so it matched nothing.
  The T3 subagent stopped. Before and After now extend to the end of the
  paragraph, and its last sentence is kept.
- T1 step 5: the `swept` line occurs once, and it states the figure twice. The
  step said "in both places".

| Task | Commit | red -> green |
|---|---|---|
| T1 | `9eb89f9` | `tests/find-items.bats` 17 tests, 17 failures (exit 127, no script) -> 17 tests, 0 failures. Step 6: `find-items.bats` 17/0, `check-ids.bats` 44/0, `lib.bats` 110/0, `portability.bats` 13/0 |
| T2 | `7782db9` | documentation only, no red step. `skills.bats` 83 tests, 0 failures |
| T3 | `4881057` | documentation only, no red step. Four edits, each matched once. `skills.bats` 83 tests, 0 failures |
| T4 | `00e1ae1` | `tests/mutate.sh`: 7 applied, 0 retired, 0 unusable. Each mutant: `find-items.bats` exit 1, killed by the tests listed in `docs/verification/2026-10-04-find-items.md`. `mutations.bats` 7 tests, 0 failures |

T1 to T4 merged into `find-items` as `cab0724`, `554b93d`, `0c71d47` and
`0b13e0b`.

### After execution

The code blocks above are the plan as written. The tree is authoritative where
the two differ.

- Deslop pass, `5ba1e9c`: the script header states "This script checks
  nothing" instead of "This script reports and checks nothing". In
  `skills/resolve-problem/SKILL.md` the paragraph that T3 step 4 placed before
  "Mint the ID first" is followed by a reworded paragraph, "Otherwise, in a
  worktree ...", instead of the original "In a worktree ..." paragraph. Suite at
  that head: 769 of 769.
- Independent review round 1 at `5ba1e9c` raised eight findings. The fixes are
  merged from `find-items-fix-r1` (`0fcd9e4` to `ca765c2`): `--kind` repeats and
  combines; an empty `--kind` or `--status`, and a second `--status`, exit 2;
  `refs` leaves definition lines out in git grep itself, including after a byte
  order mark and in a file whose name contains a colon, and prints no carriage
  return; `status_seen` and `seen` are renamed `has_status` and `file_count`;
  `tests/find-items.bats` has 36 tests, and the mutations are M01 to M19. The
  findings and their dispositions are written to
  `docs/verification/2026-10-04-find-items.md` at `merge-change` step 6b.
- `main` at `fb0db8d` (the `agent-first-scripts` change, which adds
  `scripts/merge-preflight.sh` and `scripts/task-worktree.sh`) is merged into the
  change as `07cd750`. The script-count pins are now 12 in
  `tests/check-ids.bats` and 11 in `tests/lib.bats`. T1 step 5 and the Progress
  table state the counts and the per-file figures of the tree before that merge.
- Independent review round 2 at `07cd750` confirmed the round-1 fixes and
  raised five low-severity findings. By the user's ruling of 2026-10-04 a round
  whose findings are all low severity is the last review round: they are fixed
  without a round 3, in `find-items-fix-r2`.
- The static gates at `07cd750` found that `tests/evidence.sh main` exits 2 on
  every branch that contains `fb0db8d`. That defect is recorded as `PR-9aaart`
  in `docs/problems/2026-10-04-evidence-escaped-test-name.md` and is not fixed
  in this change.
