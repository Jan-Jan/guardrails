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

```bash
#!/usr/bin/env bats
# find-items.sh: list, show and refs over the configured ledgers.

load helpers

setup() {
    make_fixture_repo
    cat > docs/requirements/0001-01-01-base.md <<'EOF'
# SRS

**REQ-001**: The system shall limit the dose.

**REQ-a3k9z2**: The system shall log the dose.
EOF
    cat > docs/risk/0001-01-01-base.md <<'EOF'
# Risk Management File

**HAZ-001**: Overdose delivered to patient.

**RC-001**: Software limits dose to configured maximum. mitigates: HAZ-001
EOF
    cat > docs/problems/0001-01-01-base.md <<'EOF'
# Problems

**PR-001**: The dose display rounds down.
opened: 2026-01-02
status: open

**PR-002**: The log omits the unit.
status: resolved
Fixed by clamping. Reproduced by tests/test_a.sh.


## Later

**PR-003**: The alarm is silent.
opened: 2026-01-03
status: accepted
disposition: ruled on 2026-01-04, the hardware alarm covers it

**PR-004**: The unit label is truncated.
opened: 2026-01-05
EOF
    commit_all "ledgers for find-items"
}

@test "find-items: list prints every item of a kind with its status and definition line" {
    run sh .guardrails/scripts/find-items.sh list --kind PR
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    expected='PR-001 open docs/problems/0001-01-01-base.md:3 The dose display rounds down.
PR-002 resolved docs/problems/0001-01-01-base.md:7 The log omits the unit.
PR-003 accepted docs/problems/0001-01-01-base.md:14 The alarm is silent.
PR-004 - docs/problems/0001-01-01-base.md:19 The unit label is truncated.'
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

@test "find-items: list without --kind prints the items of every prefix" {
    run sh .guardrails/scripts/find-items.sh list
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"REQ-a3k9z2 - docs/requirements/0001-01-01-base.md:5 The system shall log the dose."* ]] \
        || { echo "$output"; false; }
    [[ "$output" == *"RC-001 - docs/risk/0001-01-01-base.md:5 Software limits dose to configured maximum. mitigates: HAZ-001"* ]] \
        || { echo "$output"; false; }
    [[ "$output" == *"PR-003 accepted docs/problems/0001-01-01-base.md:14 The alarm is silent."* ]] \
        || { echo "$output"; false; }
}

@test "find-items: list --status keeps the items with that status" {
    run sh .guardrails/scripts/find-items.sh list --status open
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = "PR-001 open docs/problems/0001-01-01-base.md:3 The dose display rounds down." ] \
        || { echo "$output"; false; }
}

@test "find-items: a status line after the block has ended is not the item's status" {
    cat > docs/problems/0001-01-02-late.md <<'EOF'
**PR-005**: The beep is quiet.

## Notes

status: open
EOF
    commit_all late
    run sh .guardrails/scripts/find-items.sh list --kind PR
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"PR-005 - docs/problems/0001-01-02-late.md:1 The beep is quiet."* ]] \
        || { echo "$output"; false; }
}

@test "find-items: list reads the first status line of an item" {
    cat > docs/problems/0001-01-03-twice.md <<'EOF'
**PR-006**: The pump restarts.
status: open
status: resolved
EOF
    commit_all twice
    run sh .guardrails/scripts/find-items.sh list --kind PR
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"PR-006 open docs/problems/0001-01-03-twice.md:1 The pump restarts."* ]] \
        || { echo "$output"; false; }
}

@test "find-items: list prints an item once when doc_soup is inside the doc_sad directory" {
    printf '# SOUP\n\n**SDD-001**: Dose limiter module.\n' > docs/architecture/soup.md
    commit_all soup
    run sh .guardrails/scripts/find-items.sh list --kind SDD
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = "SDD-001 - docs/architecture/soup.md:3 Dose limiter module." ] \
        || { echo "$output"; false; }
}

@test "find-items: list rejects a kind that id_prefixes does not declare" {
    run sh .guardrails/scripts/find-items.sh list --kind ADR
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"--kind takes a prefix declared in id_prefixes"* ]] \
        || { echo "$output"; false; }
}

@test "find-items: list rejects a status that is not open, accepted or resolved" {
    run sh .guardrails/scripts/find-items.sh list --status closed
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"--status takes open, accepted or resolved"* ]] \
        || { echo "$output"; false; }
}

@test "find-items: show prints the block and ends it at the heading" {
    run sh .guardrails/scripts/find-items.sh show PR-002
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    expected='==> docs/problems/0001-01-01-base.md:7
**PR-002**: The log omits the unit.
status: resolved
Fixed by clamping. Reproduced by tests/test_a.sh.'
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

@test "find-items: show ends the block at the next definition" {
    run sh .guardrails/scripts/find-items.sh show PR-003
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    expected='==> docs/problems/0001-01-01-base.md:14
**PR-003**: The alarm is silent.
opened: 2026-01-03
status: accepted
disposition: ruled on 2026-01-04, the hardware alarm covers it'
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

@test "find-items: show prints every definition of a duplicated ID" {
    # Also the only test that detects a printed trailing blank line: bats
    # removes trailing newlines from $output, so a blank line at the end of a
    # block is visible only when a second block follows it.
    printf '**PR-001**: The same ID defined a second time.\nstatus: open\n' \
        > docs/problems/0001-01-02-dup.md
    commit_all dup
    run sh .guardrails/scripts/find-items.sh show PR-001
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    expected='==> docs/problems/0001-01-01-base.md:3
**PR-001**: The dose display rounds down.
opened: 2026-01-02
status: open

==> docs/problems/0001-01-02-dup.md:1
**PR-001**: The same ID defined a second time.
status: open'
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

@test "find-items: show reports NOT-FOUND with a fix line and exits 1" {
    run sh .guardrails/scripts/find-items.sh show PR-a3k9z2
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [ "${lines[0]}" = "NOT-FOUND PR-a3k9z2" ] || { echo "$output"; false; }
    [[ "${lines[1]}" == "fix NOT-FOUND: "* ]] || { echo "$output"; false; }
}

@test "find-items: show rejects an argument that is not an item ID" {
    run sh .guardrails/scripts/find-items.sh show PR-
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"not an item ID under id_prefixes"* ]] || { echo "$output"; false; }
    run sh .guardrails/scripts/find-items.sh show ADR-001
    [ "$status" -eq 2 ] || { echo "$output"; false; }
}

@test "find-items: refs lists every mention outside the definition, tracked and untracked" {
    mkdir -p docs/plans tests
    printf 'Fixes PR-001.\nUnrelated: PR-0012.\n' > docs/plans/2026-01-01-fix.md
    commit_all plan
    printf '# verifies: PR-001\ntrue\n' > tests/test_untracked.sh
    run sh .guardrails/scripts/find-items.sh refs PR-001
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"docs/plans/2026-01-01-fix.md:1:Fixes PR-001."* ]] \
        || { echo "$output"; false; }
    [[ "$output" == *"tests/test_untracked.sh:1:# verifies: PR-001"* ]] \
        || { echo "$output"; false; }
    [[ "$output" != *"PR-0012"* ]] || { echo "$output"; false; }
    [[ "$output" != *"**PR-001**:"* ]] || { echo "$output"; false; }
}

@test "find-items: refs prints nothing and exits 0 for an ID that only its definition names" {
    run sh .guardrails/scripts/find-items.sh refs PR-004
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ -z "$output" ] || { echo "$output"; false; }
}

@test "find-items: no subcommand is a usage error" {
    run sh .guardrails/scripts/find-items.sh
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"usage: find-items.sh"* ]] || { echo "$output"; false; }
}

@test "find-items: an argument that contains a newline is a usage error" {
    run sh .guardrails/scripts/find-items.sh list --kind "PR
REQ"
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"an argument contains a newline"* ]] || { echo "$output"; false; }
}
```

**Step 2 — run them and see them fail.**

```
tests/.bats-core/bin/bats tests/find-items.bats
```

Expected: `17 tests, 17 failures`. Each test fails at its first status
assertion with status 127, because `.guardrails/scripts/find-items.sh` does
not exist. A test that passes here asserts nothing; stop and report it.

**Step 3 — write the script.** Create `scripts/find-items.sh` with this
content, then `chmod 755 scripts/find-items.sh`. `tests/check-trace.bats`
requires index mode 100755 for every tracked `*.sh`.

```sh
#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# find-items.sh list [--kind PREFIX] [--status open|accepted|resolved]
# find-items.sh show ID
# find-items.sh refs ID
#
# Finds items in the ledgers, so that an agent reads one item and not a whole
# ledger file.
#
#   list  One line per item defined in the doc_* files of this config:
#         ID, status, file:line of the definition, and the rest of the
#         definition line. The status is the first column-one `status:` line in
#         the item block, the line check-trace.sh reads, or `-` when the block
#         has none. --kind keeps the items of one declared prefix. --status
#         keeps the items with that status.
#   show  The block of every definition of ID, each after a line
#         `==> file:line`, with a blank line between two blocks. A block ends
#         where the gates end it, by the shared GR_AWK_ITEM_BLOCK fragment in
#         lib.sh: at a heading, at the next bold line that contains a colon,
#         or at the end of the file. Blank lines at the end of a block are not
#         printed.
#   refs  Every file:line:text in the working tree, tracked or untracked and
#         not ignored, that contains ID as a whole word, except its definition
#         lines. Binary files are skipped. It searches the whole repository,
#         not one unit.
#
# Under a unit manifest, set GR_CONFIG to the unit config, as for the check
# scripts. This script reports and checks nothing: its exit status states
# whether the request was answered, not whether the ledgers are correct.
#
# Exit codes: 0 answered, 1 show found no definition of ID, 2 usage/environment
# error.
set -u

find_items_usage='usage: find-items.sh list [--kind PREFIX] [--status open|accepted|resolved] | show ID | refs ID'
find_items_remedy='Run find-items.sh list to see the IDs this config defines; an ID defined in another unit needs that unit config in GR_CONFIG.'

. "$(dirname "$0")/lib.sh"
gr_repo_root=$(gr_root) || exit 2
cd "$gr_repo_root" || exit 2
gr_unit_engage
gr_check_config

# A value that contains a literal newline must not reach awk -v, because BWK
# awk exits 2 before the program runs, and grep -x reads it as two patterns.
for find_items_arg in "$@"; do
    case $find_items_arg in
        (*'
'*) gr_die "an argument contains a newline" ;;
    esac
done

[ $# -gt 0 ] || gr_die "$find_items_usage"
subcommand=$1
shift

prefix_re=$(gr_prefix_re) || exit 2

# check_item_id ID: exit 2 unless ID has the shape of an ID under a declared
# prefix.
check_item_id() {
    printf '%s\n' "$1" | grep -Eq "^(${prefix_re})-${GR_ID_BODY}\$" \
        || gr_die "not an item ID under id_prefixes ($prefix_re): $1"
}

want_kind=""
want_status=""
item_id=""
case $subcommand in
    (list)
        while [ $# -gt 0 ]; do
            case $1 in
                (--kind)
                    [ $# -ge 2 ] || gr_die "$find_items_usage"
                    want_kind=$2
                    shift
                    ;;
                (--status)
                    [ $# -ge 2 ] || gr_die "$find_items_usage"
                    want_status=$2
                    shift
                    ;;
                (*) gr_die "unknown argument: $1" ;;
            esac
            shift
        done
        case $want_status in
            (''|open|accepted|resolved) ;;
            (*) gr_die "--status takes open, accepted or resolved, not: $want_status" ;;
        esac
        if [ -n "$want_kind" ]; then
            gr_prefixes | grep -Fqx -e "$want_kind" \
                || gr_die "--kind takes a prefix declared in id_prefixes ($prefix_re), not: $want_kind"
        fi
        ;;
    (show|refs)
        [ $# -eq 1 ] || gr_die "$find_items_usage"
        item_id=$1
        check_item_id "$item_id"
        ;;
    (*) gr_die "$find_items_usage" ;;
esac

if [ "$subcommand" = refs ]; then
    refs_status=0
    refs_lines=$(git grep -n -w -F -I --untracked -e "$item_id") || refs_status=$?
    case $refs_status in
        (0) ;;
        (1) exit 0 ;;
        (*) gr_die "git grep exited $refs_status searching for $item_id" ;;
    esac
    printf '%s\n' "$refs_lines" | LC_ALL=C awk -v definition="**$item_id**:" '
{ text = $0; sub(/^[^:]*:[0-9]+:/, "", text) }
index(text, definition) != 1 { print }
' || gr_die "awk failed reading the git grep output"
    exit 0
fi

ledger_files=""
for doc_key in doc_srs doc_rmf doc_sad doc_soup doc_problems; do
    key_files=$(gr_doc_files "$doc_key") || exit 2
    [ -z "$key_files" ] || ledger_files="$ledger_files$key_files
"
done
# doc_soup is commonly a file inside the doc_sad directory, which gr_doc_files
# resolves to its *.md files, so the same file can be listed twice. Read it
# once, or every item in it is printed twice.
ledger_files=$(printf '%s' "$ledger_files" | awk 'NF && !seen[$0]++')
[ -n "$ledger_files" ] || gr_die "no doc_* key is set in $GR_CONFIG, so there is no ledger to read"

# Split the file list on newlines alone, so that a path with a space is one
# argument, and turn pathname expansion off so that a path is not expanded a
# second time.
IFS='
'
set -f
set -- $ledger_files

if [ "$subcommand" = list ]; then
    list_prefix_re=${want_kind:-$prefix_re}
    LC_ALL=C awk -v body="$GR_ID_BODY" -v prefixes="$list_prefix_re" -v want_status="$want_status" "$GR_AWK_ITEM_BLOCK"'
function list_flush() {
    if (cur != "" && (want_status == "" || status_value == want_status))
        printf "%s %s %s:%d %s\n", cur, (status_value == "" ? "-" : status_value), def_file, def_line, title
    cur = ""
}
BEGIN { gr_block_init(prefixes, body) }
FNR == 1 { list_flush(); sub(/^\357\273\277/, "") }
{ line = $0; sub(/\r$/, "", line) }
gr_block_closes(line) {
    list_flush()
    status_value = ""
    status_seen = 0
    if (gr_block_opens(line)) {
        cur = gr_block_id(line)
        def_file = FILENAME
        def_line = FNR
        title = line
        sub(/^\*\*[^*]*\*\*:[ \t]*/, "", title)
    }
    next
}
cur != "" && !status_seen && gr_kw_here(line, "status:") { status_seen = 1; status_value = gr_value(line, "status:") }
END { list_flush() }
' "$@" || gr_die "awk failed reading the ledgers"
    exit 0
fi

show_status=0
LC_ALL=C awk -v body="$GR_ID_BODY" -v prefixes="$prefix_re" -v want_id="$item_id" "$GR_AWK_ITEM_BLOCK"'
BEGIN { gr_block_init(prefixes, body) }
FNR == 1 { printing = 0; blank_run = ""; sub(/^\357\273\277/, "") }
{ line = $0; sub(/\r$/, "", line) }
gr_block_closes(line) {
    printing = 0
    blank_run = ""
    if (gr_block_opens(line) && gr_block_id(line) == want_id) {
        if (found_count > 0) print ""
        found_count++
        printing = 1
        printf "==> %s:%d\n", FILENAME, FNR
        print line
    }
    next
}
printing && line ~ /^[ \t]*$/ { blank_run = blank_run line "\n"; next }
printing { printf "%s", blank_run; blank_run = ""; print line }
END { exit (found_count > 0 ? 0 : 1) }
' "$@" || show_status=$?
case $show_status in
    (0) exit 0 ;;
    (1)
        printf 'NOT-FOUND %s\n' "$item_id"
        printf 'fix NOT-FOUND: %s\n' "$find_items_remedy"
        exit 1
        ;;
    (*) gr_die "awk failed reading the ledgers (exit $show_status)" ;;
esac
```

The two awk programs are single-quoted, so neither may contain an
apostrophe. "every script parses as POSIX sh" catches one that does.

**Step 4 — run the new tests and see them pass.**

```
tests/.bats-core/bin/bats tests/find-items.bats
```

Expected: `17 tests, 0 failures`.

**Step 5 — pin the script in the enumeration tests.**

`tests/check-ids.bats`, test "every gr_def_re call site is still a call site,
and no copy joins them". Add one line to each of the seven pin groups, after
the `_check_units` line of that group (the `calls_`, `forms_`, `body_`,
`loose_`, `block_`, `fm_` and `civil_` groups):

```
    calls_find_items=0
    forms_find_items=0
    body_find_items=3
    loose_find_items=0
    block_find_items=2
    fm_find_items=0
    civil_find_items=0
```

`body_find_items=3` counts these lines: the `grep -Eq` in `check_item_id` and
the two `awk -v body=` lines. `block_find_items=2` counts the two
`"$GR_AWK_ITEM_BLOCK"` lines. The header comment names `GR_AWK_ITEM_BLOCK`
without `$`, so the comment is not counted.

`tests/check-ids.bats` contains this line twice, at the end of the test above
and at the end of "every script parses as POSIX sh":

```
    [ "$seen" -eq 9 ] || { echo "expected 9 scripts, scanned $seen"; false; }
```

Replace both with:

```
    [ "$seen" -eq 10 ] || { echo "expected 10 scripts, scanned $seen"; false; }
```

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

```
tests/.bats-core/bin/bats tests/find-items.bats tests/check-ids.bats tests/lib.bats tests/portability.bats
```

Expected: 0 failures. Do not pass a file argument to `tests/run-tests.sh`: it
appends the argument to its own glob and runs the whole suite.

**Step 7 — commit.**

```
git add scripts/find-items.sh tests/find-items.bats tests/check-ids.bats tests/lib.bats tests/portability.bats
git -c commit.gpgsign=false commit -m "feat: find-items.sh lists, shows and finds references to ledger items

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### T2 — the script lists name find-items.sh

**Files touched:** `templates/AGENTS-block.md`, `README.md`
**Parallel:** yes, with T3 and T4; after T1

**Step 1.** `templates/AGENTS-block.md`, section "## Check scripts (run from
repo root)". Insert after the `new-id.sh` bullet:

```markdown
- `.guardrails/scripts/find-items.sh list [--kind PREFIX] [--status open|accepted|resolved] | show ID | refs ID`
  — find an item without reading a ledger file: `list` prints one line per
  item (ID, status, `file:line`, the rest of the definition line), `show`
  prints the block of each definition of an ID, `refs` prints every line in
  the working tree that names an ID. Read a ledger file whole only when this
  does not answer the question. It checks nothing: exit 1 states only that
  `show` found no definition
```

**Step 2.** `README.md`, section "## Check scripts", table. Insert a row after
the `new-id.sh` row:

```markdown
| `find-items.sh list [--kind PREFIX] [--status open\|accepted\|resolved] \| show ID \| refs ID` | finds items without reading whole ledgers. `list` prints one line per item defined in the configured `doc_*` files: ID, status (the first column-one `status:` line, or `-`), `file:line` of the definition, and the rest of the definition line; `doc_soup` inside the `doc_sad` directory is read once. `show` prints the block of each definition of an ID, ending where the gates end it. `refs` prints every line in the working tree, tracked or untracked, that names the ID as a whole word, except its definitions. It gates nothing: exit 1 means only that `show` found no definition |
```

**Step 3 — run the tests that read these files.**

```
tests/.bats-core/bin/bats tests/skills.bats
```

Expected: 0 failures.

**Step 4 — commit.**

```
git add templates/AGENTS-block.md README.md
git -c commit.gpgsign=false commit -m "docs: the script lists name find-items.sh

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

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

```markdown
- **Probe for overlap before you write.** Dispatch a subagent (your harness's
  subagent mechanism — e.g. a `Task` tool, an `/agents` command) to search the
  requirements ledger for items that already cover this behavior. It returns
  IDs, one-line summaries and `file:line` — nothing else. The ledger itself
  must not enter this conversation's context. Overlap, ambiguity or
  contradiction goes to the user and is resolved with them before the new item
  is written.
```

After:

```markdown
- **Probe for overlap before you write.** Dispatch a subagent (your harness's
  subagent mechanism — e.g. a `Task` tool, an `/agents` command) to find the
  items that already cover this behavior: it runs
  `.guardrails/scripts/find-items.sh list --kind REQ`, then
  `find-items.sh show ID` for each candidate, and does not read ledger files
  whole. It returns IDs, one-line summaries and `file:line` — nothing else.
  The ledger itself must not enter this conversation's context. Overlap,
  ambiguity or contradiction goes to the user and is resolved with them before
  the new item is written.
```

**Step 2.** `skills/grill-requirements/SKILL.md`, section "## Probe the
architecture".

Before:

```markdown
Before a requirement is settled, dispatch a subagent to read the architecture
ledger (`doc_sad`) and answer three questions. It returns the answers with
`file:line` citations — not the document.
```

After:

```markdown
Before a requirement is settled, dispatch a subagent to answer three questions
from the architecture ledger (`doc_sad`). It finds the items with
`.guardrails/scripts/find-items.sh list --kind SDD` and `--kind LLR`, and
reads each candidate with `find-items.sh show ID`. It returns the answers with
`file:line` citations — not the document.
```

**Step 3.** `skills/design-architecture/SKILL.md`, section "## Process", step 1.

Before:

```markdown
1. **Read first:** the SRS (which REQs does this design serve?), the RMF
   (which controls constrain it?), CONTEXT.md (use the project's language),
   and the existing SAD.
```

After:

```markdown
1. **Read first:** the REQs this design serves, the controls (RC) that
   constrain it, CONTEXT.md (use the project's language), and the existing SAD
   items (SDD, LLR). Find items with
   `.guardrails/scripts/find-items.sh list --kind <PREFIX>`, read each one you
   need with `find-items.sh show ID`, and find where an item is already used
   with `find-items.sh refs ID`. Read a ledger file whole only when these do
   not answer the question.
```

**Step 4.** `skills/resolve-problem/SKILL.md`, section "## 1. Record before
you touch anything".

Before:

```markdown
Mint the ID first — `.guardrails/scripts/new-id.sh PR` — and write the item
with the ID it printed:
```

After:

```markdown
Check first that the problem is not already recorded:
`.guardrails/scripts/find-items.sh list --kind PR --status open` lists the
open problem reports, and `find-items.sh show ID` prints one. If an open item
describes this problem, work under its ID and do not record a second one.

Mint the ID first — `.guardrails/scripts/new-id.sh PR` — and write the item
with the ID it printed:
```

**Step 5 — run the skill tests.** `tests/skills.bats` enforces the section
order and the 2,000-word ceiling.

```
tests/.bats-core/bin/bats tests/skills.bats
```

Expected: 0 failures.

**Step 6 — commit.**

```
git add skills/grill-requirements/SKILL.md skills/design-architecture/SKILL.md skills/resolve-problem/SKILL.md
git -c commit.gpgsign=false commit -m "docs: skills find ledger items with find-items.sh instead of reading ledgers whole

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

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

```sh
#!/bin/sh
# describes: find-items.sh: the ledger file list is no longer deduplicated
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak 's|NF && !seen\[\$0\]++|NF|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
```

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

```sh
sed -i.bak 's|cur != "" && !status_seen && gr_kw_here(line, "status:")|cur != "" \&\& gr_kw_here(line, "status:")|' scripts/find-items.sh
```

**Step 2 — prove each mutation applies.**

```
sh tests/mutate.sh docs/verification/2026-10-04-find-items.mutations
```

Expected: exit 0, with no mutation reported as unable to apply.

**Step 3 — prove each mutation is killed.** Run in the task worktree with a
clean `scripts/find-items.sh`:

```
out_dir=$(mktemp -d)
for mutation in docs/verification/2026-10-04-find-items.mutations/M*.sh; do
    name=$(basename "$mutation" .sh)
    sh "$mutation" || { echo "$name did not apply"; break; }
    tests/.bats-core/bin/bats tests/find-items.bats > "$out_dir/$name.out" 2>&1
    echo "$name: bats exit $?"
    grep '^not ok' "$out_dir/$name.out"
    git checkout -- scripts/find-items.sh
done
git status --short scripts/find-items.sh
```

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

```
git add docs/verification/2026-10-04-find-items.mutations docs/verification/2026-10-04-find-items.md
git -c commit.gpgsign=false commit -m "docs: seven mutations of find-items.sh, each killed by a named test

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

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
