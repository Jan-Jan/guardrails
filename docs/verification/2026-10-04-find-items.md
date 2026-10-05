# Verification — find-items (2026-10-04)

branch: find-items
reviewer: two independent subagents, one per round, each dispatched at
`merge-change` step 6a in a nested review worktree with the diff, the plan, the
AGENTS.md rules and the record as it stood, and no account of how the change
was built. Each probed abnormal inputs by hand and executed the full suite in
its own worktree. The round 2 reviewer was also given round 1's findings and
rulings, and was told to check each fix against the tree rather than read the
ruling.
verdict: accepted after round 2. Round 1, at `5ba1e9c`, found that the script
does what the Interface states on every input tried and raised eight findings,
five of them `code`: nine untested guards, a repeated `--kind` that replaced
the first, `refs` printing a byte-order-mark definition line and carriage
returns, a `:` in a file name defeating the definition check, and two names in
past-participle form. Round 2, at `07cd750`, confirmed all eight fixes in the
tree and raised five findings, all low severity. By the user's ruling of
2026-10-04, a round whose findings are all low severity is the last review
round, so round 2's findings were fixed without a round 3. All thirteen
findings are dispositioned below.
reproduced: not applicable — this change fixes no defect. It adds a script,
its tests, documentation entries and three skill edits, and records one
problem it found, `PR-9aaart`, without fixing it.

Change: `scripts/find-items.sh` lists, shows and finds references to ledger
items, so that an agent reads one item instead of a whole ledger file;
`tests/find-items.bats` (47 tests) and thirty mutations cover it; README.md and
`templates/AGENTS-block.md` list it; `skills/grill-requirements`,
`skills/design-architecture` and `skills/resolve-problem` use it instead of
reading ledgers whole. Plan: `docs/plans/2026-10-04-find-items.md`.

Base: merged from local `main` at `e884775`, per AGENTS.md non-negotiable 5.
`origin` was not consulted. The change was opened on `fd9a867` while
`agent-first-scripts` was unsigned, by the user's decision of 2026-10-04 to
override non-negotiable 4 for this change. `fb0db8d` (`agent-first-scripts`) was
merged in at `07cd750`, with conflicts only in the script-count pins of
`tests/check-ids.bats` (12) and `tests/lib.bats` (11). `e884775` (change 3 of
the agent-first skills, which rewrites every skill) was merged in at `9d8736c`,
after review round 2. It conflicted with this change's edits to
`skills/design-architecture/SKILL.md`, `skills/grill-requirements/SKILL.md` and
`skills/resolve-problem/SKILL.md`. Each file was taken from `main`, and the
find-items instructions were applied again to the matching places: step 1 of
`design-architecture`, the Overlap and Architecture probes of
`grill-requirements`, and step 1 of `resolve-problem`, each replacement matching
once. No independent reviewer read that resolution: round 2 was the last review
round.

Problem-ledger delta: opens `PR-9aaart`. Resolves and accepts nothing.

## Gates

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` at `9d8736c`, tree `4969000172689179905ae2917783ea5baad44fc0` | 1032 of 1032, 0 not ok, 0 skip, exit 0, plan `1..1032`, 22:52 to 23:31 on 2026-10-04. `git status` clean before and after. Dispatched to a subagent; one run, to its own log |
| Earlier gate runs | baseline `5c21325` on `fd9a867`: 752 of 752. `5ba1e9c`: 769 of 769; the first attempt was killed by its own 50-minute timeout at 404 of 769 with 0 not ok, and two later runs wrote one log file, whose final content is one complete ordered run. `07cd750`: 1014 of 1014. `f9606a3`: 1025 of 1025. The review rounds' own runs: 769 of 769 at `5ba1e9c`, 1014 of 1014 at `07cd750` |
| `check-ids.sh`, scratch copies of `e884775` and `9d8736c` built by the recipe of `docs/verification/2026-10-03-accept-2scmvn.md` | exit 1 at both. 72 lines at the base, 79 at the change. New lines: `DUPLICATE-ID` for `PR-002` to `PR-007` and for `REQ-a3k9z2`. The rest are line shifts in README.md and `tests/check-ids.bats` |
| `check-trace.sh`, the same copies | exit 1 at both. 134 lines at the base, 142 at the change. New lines: `MISPLACED-ITEM` for `PR-002` to `PR-007`; `DANGLING-REF PR-0012` and `DANGLING-REF PR-008` in place of `DANGLING-REF PR-002`; `UNRESOLVED-PR PR-9aaart (open 0 days)`; `PROBLEM-BACKLOG` 15 to 16 open; summary `PR 62` to `PR 69`. The same set of new lines as against `fb0db8d`. `PR-9aaart` has no other line |
| `sh tests/evidence.sh main` | exit 0 at `5ba1e9c` on the base `fd9a867`: 769 tests, 17 new or renamed, 17 go red against `main`'s scripts, 0 cannot. Exit 2 at `07cd750` and every later head, before any figure, which is `PR-9aaart`. No figure is derived for the final tree |
| `tests/mutate.sh docs/verification/2026-10-04-find-items.mutations` | exit 0, 30 applied, 0 retired, 0 unusable. Each mutant killed; see Mutation evidence |
| `check-review.sh`, from the change worktree with `GR_CONFIG` set to the scratch config outside the repository | exit 0: `records 48, for find-items 1, findings 13; provenance checked`. With `--branch find-items`: exit 0, the same counts, provenance not checked |
| Coverage, against the class target | not measured; the toolkit is unclassified |

Every new `check-ids.sh` and `check-trace.sh` line except the `PR-9aaart` lines
comes from fixture text: `tests/find-items.bats` defines items at column one in
heredocs, because that is the form the script reads, and the plan quotes that
file; `PR-0012` is the deliberately invalid ID of the `refs` whole-word test,
and `PR-008` is named in a `printf` fixture. The same class accounts for the 72
and 134 base lines. No gate runs on this repository, which has no
`.guardrails/`, and `/ratchet` copies `scripts/`, not `tests/`, into a target
project.

## Red → green

| Task or fix | Test | Red | Green |
| --- | --- | --- | --- |
| T1 `9eb89f9` | `tests/find-items.bats` 1 to 17 | 17 of 17 failed, exit 127, no script | 17 of 17 |
| T2 `7782db9`, T3 `4881057` | documentation only | none | `skills.bats` 83 of 83 |
| T4 `00e1ae1` | mutations `M01` to `M07` | each mutant killed | — |
| Round 1 fix, `e331f2b`, `f8cf13a` | `--kind` given twice; empty `--kind` and `--status`; `--status` twice; `refs` and a BOM definition, a CRLF line, a colon in a file name | each red with the behaviour absent | green |
| Round 1 fix, `a55bcb8` | tests 24 to 36, one per guard | each red under its mutation `M08` to `M19` | green |
| Round 2 fix, `7567174` | tests 37 to 42, one per guard | each red under its mutation `M20` to `M25` | green |
| Round 2 fix, `5a97e12`, `2774629` | tests 43 to 47 | red before the fix: a quoted non-ASCII name, a column number, color escapes, and soup listed twice under `docs/architecture/` and `./docs/architecture` | green |

`find-items.bats` passes under dash as `/bin/sh`: 47 of 47.

The deslop pass (`develop-change`) was run at `677893e` and committed `5ba1e9c`.
It changed prose only, and its suite run at that head was 769 of 769. Its
report was lost when the session reached a usage limit, so its list of what it
left alone is not recorded.

## Findings

**finding-1**: code — Nine guards in `scripts/find-items.sh` fail no test when removed: the BOM strip, the CR strip, the per-file reset (each in `list` and `show`), `set -f` and the newline IFS, `gr_unit_engage`, the ID check on `refs`, the `-I` binary skip, the git grep error branch, and the "no doc_* key is set" error. This contradicts self-review item 1 of the plan.
disposition: tests 24 to 36, one per guard, and mutations `M08` to `M19`, each killed by its test. The git grep error branch is reached with `git config grep.threads -1`. The "no doc_* key is set" error is unreachable, because `gr_check_config` rejects every config that would reach it; the script states that in a comment, and round 2 confirmed it.

**finding-2**: code — A second `--kind` replaces the first, so `list --kind PR --kind REQ` prints only REQ items; `--kind ""` and `--status ""` exit 0 with no filter.
disposition: `--kind` repeats and combines; an empty `--kind` or `--status`, and a second `--status`, exit 2. Tests "list --kind given twice prints the items of both kinds", "list rejects an empty --kind and an empty --status", "list rejects --status given twice" were red with the behaviour absent.

**finding-3**: requirement — `skills/grill-requirements/SKILL.md` "Probe the architecture" reads "list --kind SDD and --kind LLR", which a reader can take as one command that drops the SDD items.
disposition: the skill states `list --kind SDD --kind LLR`, which finding-2's fix makes correct.

**finding-4**: code — `refs` prints a definition line that begins with a BOM as a reference, and prints CRLF lines with the trailing carriage return.
disposition: git grep leaves out definition lines after an optional BOM, and awk strips the CR. Tests "refs does not print a definition line that begins with a byte order mark" and "refs prints a line of a CRLF file without the carriage return" were red before the fix.

**finding-5**: code — A file name that contains `:` defeats the prefix strip in `refs`, so that file's definition line is printed as a reference; and `refs` leaves out column-one definitions outside the ledgers.
disposition: the definition exclusion moved into git grep (`--and --not`), so no output line is split. Test "refs does not print a definition line in a file whose name contains a colon" was red before the fix. The second half is intended: the script header states it, and that `check-ids.sh` reports a second definition as `DUPLICATE-ID` and `check-trace.sh` an item defined only outside its ledger as `MISPLACED-ITEM`.

**finding-6**: record — The plan's T1 step 3 header text and T3 step 4 After text differ from the tree after the deslop commit `5ba1e9c`, and Progress records neither.
disposition: the plan's "After execution" section (`91fc418`) records both, and states that the tree is authoritative over the code blocks.

**finding-7**: requirement — `templates/AGENTS-block.md` describes `refs` without "whole word" and without "except its definition lines".
disposition: `b280790` adds both, and the repeatable `--kind`.

**finding-8**: code — `status_seen` and `seen[$0]` are past participles, which the AGENTS.md naming rule forbids.
disposition: renamed `has_status` and `file_count` (`0fcd9e4`). `M01` and `M02` quote the new lines and are killed by tests 6 and 5.

**finding-9**: code — Guards still unpinned after round 1: the unknown-subcommand branch, `[ $# -eq 1 ]` for `show` and `refs`, the unknown-argument branch, `[ $# -ge 2 ]` for `--kind` and `--status`, and the exclusion of ignored files by git grep. `[ -n "$2" ] &&` is redundant.
disposition: tests 37 to 42 and mutations `M20` to `M25`, each killed by its test; the `--kind` and `--status` tests also assert the usage message, because under dash an unset `$2` exits 2 without the guard. The redundant test is removed.

**finding-10**: code — `refs` prints a C-quoted path for a file name with a non-ASCII byte or a tab, because of `core.quotePath`.
disposition: git grep runs with `-c core.quotePath=false`. Test 43 sets `core.quotePath=true` and was red before the fix; `M26` is killed by it. The header states that git still quotes a file name with a tab, a newline, a double quote or a backslash.

**finding-11**: code — `refs` output follows the user's git config: `grep.column` adds a column number, and `color.grep=always` adds escapes that defeat the CR strip.
disposition: `-c grep.column=false -c color.grep=never`. Tests 44 and 45 were red before the fix; `M27` and `M28` are killed by them. The script comment states why the other `grep.*` keys do not change the output.

**finding-12**: code — The dedupe of ledger files compares path strings, so `doc_sad: docs/architecture/` or a `./` spelling lists the soup items twice.
disposition: each ledger path is normalised before the dedupe (repeated `/` collapsed, leading `./` removed). Tests 46 and 47 were red before the fix; `M29` and `M30` are killed by them.

**finding-13**: record — The plan's "After execution" section states that the record contains the findings and dispositions, which it did not, and does not record the merge of `main` at `fb0db8d` or that T1 step 5 and the Progress figures describe the tree before it.
disposition: `51669ae` corrects the sentence to state that they are written at step 6b, and records the merge, the new pin counts, review round 2 and `PR-9aaart`.

## Mutation evidence

Thirty mutations of `scripts/find-items.sh` are in
`docs/verification/2026-10-04-find-items.mutations/`. Each one quotes a line
of the script verbatim and exits 3 when its `sed` changes nothing.

`sh tests/mutate.sh docs/verification/2026-10-04-find-items.mutations` exited
0 and printed `mutations: 30 applied, 0 retired, 0 unusable`.

Each mutation was applied to a clean `scripts/find-items.sh`, then
`tests/.bats-core/bin/bats tests/find-items.bats` was run, and then the script
was restored with `git checkout --`. Measured at commit `2774629` on branch
`find-items-fix-r2`, on 2026-10-04, after review round 2; the round 1
measurement, of `M01` to `M19` against 36 tests, was at commit `b280790` on
branch `find-items-fix-r1`, and the first, of `M01` to `M07` against 17 tests,
was at commit `9eb89f9`. Every mutant gave bats exit 1.
`git status --short scripts/find-items.sh` printed nothing after the loop, and
the unmutated script passes all 47 tests in `tests/find-items.bats`.

Review round 1 renamed `status_seen` and `seen` and moved the definition
exclusion of `refs` into `git grep`, so `M01`, `M02`, `M04` and `M05` quote the
new lines. `M08` to `M19` each remove one guard that no test detected before
round 1. Review round 2 normalised the ledger paths before the dedupe and
split the `git grep` line of `refs` in two, so `M01`, `M05` and `M18` quote
the new lines. `M20` to `M25` each remove one guard that no test detected
before round 2, and `M26` to `M30` each remove one change of round 2. The
`no doc_* key is set` error has no test and no mutation:
`gr_check_config` rejects every config that would reach it.

| # | Mutation | `sed` line | Killed by (measured) |
|---|---|---|---|
| `M01` | find-items.sh: the ledger file list is no longer deduplicated | `sed -i.bak 's\|if (!file_count\[\$0\]++) print\|print\|' scripts/find-items.sh` | `not ok 6` list prints an item once when doc_soup is inside the doc_sad directory; `not ok 46` list prints an item once when doc_sad ends with a slash; `not ok 47` list prints an item once when doc_sad begins with ./ |
| `M02` | find-items.sh: the last status line wins, not the first | `sed -i.bak 's\|cur != "" && !has_status && gr_kw_here(line, "status:")\|cur != "" \&\& gr_kw_here(line, "status:")\|' scripts/find-items.sh` | `not ok 5` list reads the first status line of an item |
| `M03` | find-items.sh: trailing blank lines of a block are printed | `sed -i.bak '/^printing && line ~/d' scripts/find-items.sh` | `not ok 11` show prints every definition of a duplicated ID |
| `M04` | find-items.sh: refs prints definition lines | `sed -i.bak 's\| --and --not -e "$definition_re")\| )\|' scripts/find-items.sh` | `not ok 14` refs lists every mention outside the definition, tracked and untracked; `not ok 15` refs prints nothing and exits 0 for an ID that only its definition names; `not ok 21` refs does not print a definition line that begins with a byte order mark; `not ok 22` refs prints a line of a CRLF file without the carriage return; `not ok 23` refs does not print a definition line in a file whose name contains a colon; `not ok 42` refs does not print a line in an ignored file; `not ok 43` refs prints a non-ASCII file name unquoted; `not ok 44` refs prints no column number when grep.column is set; `not ok 45` refs prints no color escapes when color.grep is always |
| `M05` | find-items.sh: refs matches the ID inside a longer token | `sed -i.bak 's\|grep -n -w -I -E --untracked\|grep -n -I -E --untracked\|' scripts/find-items.sh` | `not ok 14` refs lists every mention outside the definition, tracked and untracked |
| `M06` | find-items.sh: show exits 0 when nothing is found | `sed -i.bak 's\|END { exit (found_count > 0 ? 0 : 1) }\|END { exit 0 }\|' scripts/find-items.sh` | `not ok 12` show reports NOT-FOUND with a fix line and exits 1 |
| `M07` | find-items.sh: a newline in an argument is not rejected | `sed -i.bak 's\|gr_die "an argument contains a newline"\|:\|' scripts/find-items.sh` | `not ok 17` an argument that contains a newline is a usage error |
| `M08` | find-items.sh: list does not remove a byte order mark | `sed -i.bak 's\|FNR == 1 { list_flush(); sub(/^\\357\\273\\277/, "") }\|FNR == 1 { list_flush() }\|' scripts/find-items.sh` | `not ok 24` list reads an item in a file that begins with a byte order mark |
| `M09` | find-items.sh: show does not remove a byte order mark | `sed -i.bak 's\|FNR == 1 { printing = 0; blank_run = ""; sub(/^\\357\\273\\277/, "") }\|FNR == 1 { printing = 0; blank_run = "" }\|' scripts/find-items.sh` | `not ok 25` show prints an item in a file that begins with a byte order mark |
| `M10` | find-items.sh: list does not remove a carriage return | `sed -i.bak '/^function list_flush() {$/,/^END { list_flush() }$/s\|^{ line = $0; sub(/\\r$/, "", line) }$\|{ line = $0 }\|' scripts/find-items.sh` | `not ok 26` list reads an item in a CRLF file without the carriage return |
| `M11` | find-items.sh: show does not remove a carriage return | `sed -i.bak '/^show_status=0$/,$s\|^{ line = $0; sub(/\\r$/, "", line) }$\|{ line = $0 }\|' scripts/find-items.sh` | `not ok 27` show prints an item in a CRLF file without the carriage return |
| `M12` | find-items.sh: list does not end an item at the end of its file | `sed -i.bak 's\|FNR == 1 { list_flush(); sub(\|FNR == 1 { sub(\|' scripts/find-items.sh` | `not ok 28` list ends an item at the end of its file |
| `M13` | find-items.sh: show does not end a block at the end of its file | `sed -i.bak 's\|FNR == 1 { printing = 0; blank_run = "";\|FNR == 1 { blank_run = "";\|' scripts/find-items.sh` | `not ok 29` show ends a block at the end of its file |
| `M14` | find-items.sh: the ledger file list is split on blanks as well as newlines | `sed -i.bak "s\|^IFS='\$\|unused_ifs='\|" scripts/find-items.sh` | `not ok 30` list reads a ledger file whose path contains a space |
| `M15` | find-items.sh: pathname expansion applies to the ledger file list | `sed -i.bak '/^set -f$/d' scripts/find-items.sh` | `not ok 31` list reads a ledger file whose name contains a glob character once |
| `M16` | find-items.sh: the unit manifest is not read | `sed -i.bak '/^gr_unit_engage$/d' scripts/find-items.sh` | `not ok 33` a multi-unit repository without a unit config in GR_CONFIG is an environment error |
| `M17` | find-items.sh: refs does not check the shape of its argument | `sed -i.bak 's#^        check_item_id "$item_id"$#        [ "$subcommand" = refs ] \|\| check_item_id "$item_id"#' scripts/find-items.sh` | `not ok 34` refs rejects an argument that is not an item ID |
| `M18` | find-items.sh: refs reads binary files | `sed -i.bak 's\|grep -n -w -I -E --untracked\|grep -n -w -E --untracked\|' scripts/find-items.sh` | `not ok 35` refs skips a binary file |
| `M19` | find-items.sh: a git grep failure in refs exits 0 | `sed -i.bak 's\|(\*) gr_die "git grep exited $refs_status searching for $item_id" ;;\|(*) exit 0 ;;\|' scripts/find-items.sh` | `not ok 36` refs reports a git grep failure as an environment error |
| `M20` | find-items.sh: an unknown subcommand is not rejected | `sed -i.bak 's\|^    (\*) gr_die "$find_items_usage" ;;$\|    (*) ;;\|' scripts/find-items.sh` | `not ok 37` an unknown subcommand is a usage error |
| `M21` | find-items.sh: show and refs accept a second argument | `sed -i.bak '/^        \[ $# -eq 1 \] \|\| gr_die "$find_items_usage"$/d' scripts/find-items.sh` | `not ok 38` show and refs reject a second argument |
| `M22` | find-items.sh: list ignores an unknown argument | `sed -i.bak 's\|(\*) gr_die "unknown argument: $1" ;;\|(*) ;;\|' scripts/find-items.sh` | `not ok 39` list rejects an unknown argument |
| `M23` | find-items.sh: list does not check that --kind has a value | `sed -i.bak '/^                (--kind)$/,/^                (--status)$/s@^                    \[ $# -ge 2 \] \|\| gr_die "$find_items_usage"$@                    :@' scripts/find-items.sh` | `not ok 40` list rejects --kind without a value |
| `M24` | find-items.sh: list does not check that --status has a value | `sed -i.bak '/^                (--status)$/,/^                (\*) gr_die/s@^                    \[ $# -ge 2 \] \|\| gr_die "$find_items_usage"$@                    :@' scripts/find-items.sh` | `not ok 41` list rejects --status without a value |
| `M25` | find-items.sh: refs reads ignored files | `sed -i.bak 's\|grep -n -w -I -E --untracked\|grep -n -w -I -E --untracked --no-exclude-standard\|' scripts/find-items.sh` | `not ok 42` refs does not print a line in an ignored file |
| `M26` | find-items.sh: refs follows core.quotePath | `sed -i.bak 's\|git -c core.quotePath=false -c grep.column=false\|git -c grep.column=false\|' scripts/find-items.sh` | `not ok 43` refs prints a non-ASCII file name unquoted |
| `M27` | find-items.sh: refs follows grep.column | `sed -i.bak 's\| -c grep.column=false -c color.grep=never \\$\| -c color.grep=never \\\|' scripts/find-items.sh` | `not ok 44` refs prints no column number when grep.column is set |
| `M28` | find-items.sh: refs follows color.grep | `sed -i.bak 's\| -c color.grep=never \\$\| \\\|' scripts/find-items.sh` | `not ok 45` refs prints no color escapes when color.grep is always |
| `M29` | find-items.sh: repeated slashes in a ledger path are not collapsed | `sed -i.bak '\#^    gsub(/\\/\\/+/, "/")$#d' scripts/find-items.sh` | `not ok 46` list prints an item once when doc_sad ends with a slash |
| `M30` | find-items.sh: a leading ./ in a ledger path is not removed | `sed -i.bak '\#^    while (sub(/^\\.\\//, "")) {}$#d' scripts/find-items.sh` | `not ok 47` list prints an item once when doc_sad begins with ./ |

In the table, `\|` is the markdown escape for `|`; the mutation files contain
`|`. Test names omit the `find-items: ` prefix that each name in
`tests/find-items.bats` begins with. `M02` to `M07` were each killed by the
tests the plan named for them, and `M04` also by the three `refs` tests that
review round 1 added. The plan names no test for `M01`. `M08` to `M19` are each
killed by the one test that review round 1 added for that guard, and by no
other test. `M20` to `M30` are each killed by the one test that review round 2
added for that guard, and by no other test; `M04` is also killed by tests 42
to 45, and `M01` by tests 46 and 47, which review round 2 added. Test 32
(list in a multi-unit repository reads the unit that GR_CONFIG names) kills no
mutation: under `M16` it passed, because a run with a unit config in GR_CONFIG
gives the same output without `gr_unit_engage`.
