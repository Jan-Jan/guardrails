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

@test "find-items: list --kind given twice prints the items of both kinds" {
    run sh .guardrails/scripts/find-items.sh list --kind HAZ --kind RC
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    expected='HAZ-001 - docs/risk/0001-01-01-base.md:3 Overdose delivered to patient.
RC-001 - docs/risk/0001-01-01-base.md:5 Software limits dose to configured maximum. mitigates: HAZ-001'
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

@test "find-items: list rejects an empty --kind and an empty --status" {
    run sh .guardrails/scripts/find-items.sh list --kind ""
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"--kind takes a prefix declared in id_prefixes"* ]] || { echo "$output"; false; }
    run sh .guardrails/scripts/find-items.sh list --status ""
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"--status takes open, accepted or resolved"* ]] || { echo "$output"; false; }
}

@test "find-items: list rejects --status given twice" {
    run sh .guardrails/scripts/find-items.sh list --status open --status resolved
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"--status is given more than once"* ]] || { echo "$output"; false; }
}

@test "find-items: refs does not print a definition line that begins with a byte order mark" {
    printf '\357\273\277**PR-007**: The bom item.\nSee PR-007.\n' \
        > docs/problems/0001-01-04-bom.md
    commit_all bom
    run sh .guardrails/scripts/find-items.sh refs PR-007
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = "docs/problems/0001-01-04-bom.md:2:See PR-007." ] || { echo "$output"; false; }
}

@test "find-items: refs prints a line of a CRLF file without the carriage return" {
    printf 'See PR-001.\r\n' > docs/problems/0001-01-04-crlf.md
    commit_all crlf
    run sh .guardrails/scripts/find-items.sh refs PR-001
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = "docs/problems/0001-01-04-crlf.md:1:See PR-001." ] || { echo "$output"; false; }
}

@test "find-items: refs does not print a definition line in a file whose name contains a colon" {
    mkdir -p notes
    printf '**PR-001**: A stray definition.\n' > 'notes/a:1:b.md'
    commit_all colon
    run sh .guardrails/scripts/find-items.sh refs PR-001
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ -z "$output" ] || { echo "$output"; false; }
}

@test "find-items: list reads an item in a file that begins with a byte order mark" {
    printf '\357\273\277**PR-007**: The bom item.\nstatus: open\n' \
        > docs/problems/0001-01-04-bom.md
    commit_all bom
    run sh .guardrails/scripts/find-items.sh list --kind PR
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"PR-007 open docs/problems/0001-01-04-bom.md:1 The bom item."* ]] \
        || { echo "$output"; false; }
}

@test "find-items: show prints an item in a file that begins with a byte order mark" {
    printf '\357\273\277**PR-007**: The bom item.\nstatus: open\n' \
        > docs/problems/0001-01-04-bom.md
    commit_all bom
    run sh .guardrails/scripts/find-items.sh show PR-007
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    expected='==> docs/problems/0001-01-04-bom.md:1
**PR-007**: The bom item.
status: open'
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

@test "find-items: list reads an item in a CRLF file without the carriage return" {
    printf '**PR-007**: The crlf item.\r\nstatus: open\r\n' \
        > docs/problems/0001-01-04-crlf.md
    commit_all crlf
    run sh .guardrails/scripts/find-items.sh list --kind PR
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "${lines[4]}" = "PR-007 open docs/problems/0001-01-04-crlf.md:1 The crlf item." ] \
        || { echo "$output"; false; }
}

@test "find-items: show prints an item in a CRLF file without the carriage return" {
    printf '**PR-007**: The crlf item.\r\nstatus: open\r\n' \
        > docs/problems/0001-01-04-crlf.md
    commit_all crlf
    run sh .guardrails/scripts/find-items.sh show PR-007
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    expected='==> docs/problems/0001-01-04-crlf.md:1
**PR-007**: The crlf item.
status: open'
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

@test "find-items: list ends an item at the end of its file" {
    printf '**PR-007**: The last item of a file.\n' > docs/problems/0001-01-04-end.md
    printf 'Notes before any item.\nstatus: open\n' > docs/problems/0001-01-05-next.md
    commit_all end
    run sh .guardrails/scripts/find-items.sh list --kind PR
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"PR-007 - docs/problems/0001-01-04-end.md:1 The last item of a file."* ]] \
        || { echo "$output"; false; }
}

@test "find-items: show ends a block at the end of its file" {
    printf '**PR-007**: The last item of a file.\n' > docs/problems/0001-01-04-end.md
    printf 'Notes before any item.\nstatus: open\n' > docs/problems/0001-01-05-next.md
    commit_all end
    run sh .guardrails/scripts/find-items.sh show PR-007
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    expected='==> docs/problems/0001-01-04-end.md:1
**PR-007**: The last item of a file.'
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

@test "find-items: list reads a ledger file whose path contains a space" {
    printf '**PR-007**: The spaced item.\n' > 'docs/problems/0001-01-04 two words.md'
    commit_all space
    run sh .guardrails/scripts/find-items.sh list --kind PR
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"PR-007 - docs/problems/0001-01-04 two words.md:1 The spaced item."* ]] \
        || { echo "$output"; false; }
}

@test "find-items: list reads a ledger file whose name contains a glob character once" {
    printf '**PR-007**: The star item.\n' > 'docs/problems/0001-01-04-a*.md'
    printf '**PR-008**: The plain item.\n' > docs/problems/0001-01-04-ab.md
    commit_all glob
    run sh .guardrails/scripts/find-items.sh list --kind PR
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    plain_count=$(printf '%s\n' "$output" | grep -c '^PR-008 ')
    [ "$plain_count" -eq 1 ] || { echo "$output"; false; }
}

@test "find-items: list in a multi-unit repository reads the unit that GR_CONFIG names" {
    make_units_fixture
    unit_run find-items.sh apps/pump list --kind REQ
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = "REQ-p2m4k7 - apps/pump/docs/requirements/0001-01-01-base.md:3 The software shall limit the dose. (implements: RC-p4q7t3)" ] \
        || { echo "$output"; false; }
}

@test "find-items: a multi-unit repository without a unit config in GR_CONFIG is an environment error" {
    make_units_fixture
    run sh .guardrails/scripts/find-items.sh list
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"this is a multi-unit repository"* ]] || { echo "$output"; false; }
}

@test "find-items: refs rejects an argument that is not an item ID" {
    run sh .guardrails/scripts/find-items.sh refs dose
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"not an item ID under id_prefixes"* ]] || { echo "$output"; false; }
}

@test "find-items: refs skips a binary file" {
    printf 'PR-001\000binary\n' > src/blob.bin
    commit_all binary
    run sh .guardrails/scripts/find-items.sh refs PR-001
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"blob.bin"* ]] || { echo "$output"; false; }
}

@test "find-items: refs reports a git grep failure as an environment error" {
    # git grep exits 128 when grep.threads is below zero (measured with git
    # 2.55), and no other git command in the script reads that key.
    git config grep.threads -1
    run sh .guardrails/scripts/find-items.sh refs PR-001
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"git grep exited"* ]] || { echo "$output"; false; }
}

@test "find-items: an unknown subcommand is a usage error" {
    run sh .guardrails/scripts/find-items.sh find PR-001
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"usage: find-items.sh"* ]] || { echo "$output"; false; }
}

@test "find-items: show and refs reject a second argument" {
    run sh .guardrails/scripts/find-items.sh show PR-001 PR-002
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"usage: find-items.sh"* ]] || { echo "$output"; false; }
    run sh .guardrails/scripts/find-items.sh refs PR-001 PR-002
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"usage: find-items.sh"* ]] || { echo "$output"; false; }
}

@test "find-items: list rejects an unknown argument" {
    run sh .guardrails/scripts/find-items.sh list --open
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"unknown argument: --open"* ]] || { echo "$output"; false; }
}

@test "find-items: list rejects --kind without a value" {
    run sh .guardrails/scripts/find-items.sh list --kind
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"usage: find-items.sh"* ]] || { echo "$output"; false; }
}

@test "find-items: list rejects --status without a value" {
    run sh .guardrails/scripts/find-items.sh list --status
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"usage: find-items.sh"* ]] || { echo "$output"; false; }
}

@test "find-items: refs does not print a line in an ignored file" {
    printf 'ignored.md\n' > .gitignore
    commit_all ignore
    printf 'See PR-001.\n' > ignored.md
    printf 'See PR-001.\n' > noted.md
    run sh .guardrails/scripts/find-items.sh refs PR-001
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = "noted.md:1:See PR-001." ] || { echo "$output"; false; }
}

@test "find-items: refs prints a non-ASCII file name unquoted" {
    git config core.quotePath true
    accented_name=$(printf 'docs/dos\303\251.md')
    printf 'See PR-001.\n' > "$accented_name"
    commit_all accented
    run sh .guardrails/scripts/find-items.sh refs PR-001
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = "$accented_name:1:See PR-001." ] || { echo "$output"; false; }
}

@test "find-items: refs prints no column number when grep.column is set" {
    git config grep.column true
    printf 'See PR-001.\n' > noted.md
    run sh .guardrails/scripts/find-items.sh refs PR-001
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = "noted.md:1:See PR-001." ] || { echo "$output"; false; }
}

@test "find-items: refs prints no color escapes when color.grep is always" {
    git config color.grep always
    printf 'See PR-001.\r\n' > noted.md
    run sh .guardrails/scripts/find-items.sh refs PR-001
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = "noted.md:1:See PR-001." ] || { echo "$output"; false; }
}

@test "find-items: list prints an item once when doc_sad ends with a slash" {
    printf '# SOUP\n\n**SDD-001**: Dose limiter module.\n' > docs/architecture/soup.md
    sed -i.bak 's|^doc_sad: docs/architecture$|doc_sad: docs/architecture/|' .guardrails/config.yaml
    rm -f .guardrails/config.yaml.bak
    grep -qx 'doc_sad: docs/architecture/' .guardrails/config.yaml || { cat .guardrails/config.yaml; false; }
    commit_all soup
    run sh .guardrails/scripts/find-items.sh list --kind SDD
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = "SDD-001 - docs/architecture/soup.md:3 Dose limiter module." ] \
        || { echo "$output"; false; }
}

@test "find-items: list prints an item once when doc_sad begins with ./" {
    printf '# SOUP\n\n**SDD-001**: Dose limiter module.\n' > docs/architecture/soup.md
    sed -i.bak 's|^doc_sad: docs/architecture$|doc_sad: ./docs/architecture|' .guardrails/config.yaml
    rm -f .guardrails/config.yaml.bak
    grep -qx 'doc_sad: ./docs/architecture' .guardrails/config.yaml || { cat .guardrails/config.yaml; false; }
    commit_all soup
    run sh .guardrails/scripts/find-items.sh list --kind SDD
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = "SDD-001 - docs/architecture/soup.md:3 Dose limiter module." ] \
        || { echo "$output"; false; }
}

# declare_adr_prefix CONFIG: adds ADR to the id_prefixes line of CONFIG, which
# the fixtures do not declare.
declare_adr_prefix() {
    sed -i.bak 's|^id_prefixes: REQ HAZ RC SDD LLR PR$|id_prefixes: REQ HAZ RC SDD LLR PR ADR|' "$1"
    rm -f "$1.bak"
    grep -qx 'id_prefixes: REQ HAZ RC SDD LLR PR ADR' "$1" || { cat "$1"; false; }
}

# run_find_items_stderr_to FILE ARGUMENT...: runs find-items.sh with ARGUMENTs
# under bats `run`, with its standard error written to FILE and kept out of
# $output. It needs no `run --separate-stderr`, which older bats lacks.
run_find_items_stderr_to() {
    stderr_file=$1
    shift
    run sh -c 'stderr_file=$1; shift; sh .guardrails/scripts/find-items.sh "$@" 2>"$stderr_file"' \
        find-items "$stderr_file" "$@"
}

# write_adr_fixture: an ADR file in docs/adr, and a README there with an item
# line that is not an ADR file.
write_adr_fixture() {
    declare_adr_prefix .guardrails/config.yaml
    mkdir -p docs/adr
    cat > docs/adr/ADR-x7k2m9-dose-limit-source.md <<'ADR'
**ADR-x7k2m9**: The dose limit is read from the pump configuration.

Date: 2026-01-02
Status: accepted

## Context

The limit differs per pump model.
ADR
    printf '# Decisions\n\n**ADR-q3w8e4**: An item line outside an ADR file.\n' > docs/adr/README.md
    commit_all adrs
}

# verifies: PR-ka8w9m
@test "find-items: list --kind ADR prints an ADR defined in docs/adr" {
    write_adr_fixture
    run sh .guardrails/scripts/find-items.sh list --kind ADR
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = "ADR-x7k2m9 - docs/adr/ADR-x7k2m9-dose-limit-source.md:1 The dose limit is read from the pump configuration." ] \
        || { echo "$output"; false; }
}

# verifies: PR-ka8w9m
@test "find-items: show prints an ADR block and ends it at the heading" {
    write_adr_fixture
    run sh .guardrails/scripts/find-items.sh show ADR-x7k2m9
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "${lines[0]}" = "==> docs/adr/ADR-x7k2m9-dose-limit-source.md:1" ] || { echo "$output"; false; }
    [[ "$output" == *"Status: accepted"* ]] || { echo "$output"; false; }
    [[ "$output" != *"## Context"* ]] || { echo "$output"; false; }
}

# verifies: PR-ka8w9m
@test "find-items: show does not read an item line in a docs/adr file that is not named ADR-*.md" {
    write_adr_fixture
    run sh .guardrails/scripts/find-items.sh show ADR-q3w8e4
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [ "${lines[0]}" = "NOT-FOUND ADR-q3w8e4" ] || { echo "$output"; false; }
}

# verifies: PR-ka8w9m
@test "find-items: list in a multi-unit repository reads the root ADRs and those of the unit that GR_CONFIG names" {
    make_units_fixture
    declare_adr_prefix apps/pump/.guardrails/config.yaml
    mkdir -p apps/pump/docs/adr platform/hal/docs/adr docs/adr
    printf '**ADR-p8w3n5**: The pump reads its limit from its own config.\n' \
        > apps/pump/docs/adr/ADR-p8w3n5-pump-limit.md
    printf '**ADR-h7c4t6**: The HAL owns the flow-rate contract.\n' \
        > platform/hal/docs/adr/ADR-h7c4t6-hal-contract.md
    printf '**ADR-r9e5u2**: The repository has two units.\n' \
        > docs/adr/ADR-r9e5u2-two-units.md
    commit_all unit-adrs
    unit_run find-items.sh apps/pump list --kind ADR
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    # The root docs/adr/ is read before the unit's, as check-units.sh tries
    # them; the platform/hal ADR is another unit's and is not read.
    expected='ADR-r9e5u2 - docs/adr/ADR-r9e5u2-two-units.md:1 The repository has two units.
ADR-p8w3n5 - apps/pump/docs/adr/ADR-p8w3n5-pump-limit.md:1 The pump reads its limit from its own config.'
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

# verifies: PR-ka8w9m
@test "find-items: the ADR files are not read when id_prefixes does not declare ADR" {
    mkdir -p docs/adr
    printf '**REQ-002**: A requirement line inside an ADR file.\n' \
        > docs/adr/ADR-p8w3n5-x.md
    commit_all undeclared-adr
    run sh .guardrails/scripts/find-items.sh list
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"REQ-002"* ]] || { echo "$output"; false; }
    run sh .guardrails/scripts/find-items.sh show REQ-002
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [ "${lines[0]}" = "NOT-FOUND REQ-002" ] || { echo "$output"; false; }
}

# verifies: PR-ka8w9m
@test "find-items: a directory whose name matches docs/adr/ADR-*.md is not read" {
    write_adr_fixture
    mkdir docs/adr/ADR-x7k2m9-dir.md
    run_find_items_stderr_to "$BATS_TEST_TMPDIR/stderr" list --kind ADR
    [ "$status" -eq 0 ] || { echo "$output"; cat "$BATS_TEST_TMPDIR/stderr"; false; }
    [ "$output" = "ADR-x7k2m9 - docs/adr/ADR-x7k2m9-dose-limit-source.md:1 The dose limit is read from the pump configuration." ] \
        || { echo "$output"; false; }
    [ ! -s "$BATS_TEST_TMPDIR/stderr" ] || { cat "$BATS_TEST_TMPDIR/stderr"; false; }
}

# verifies: PR-ka8w9m
@test "find-items: list with ADR declared and no docs/adr directory prints the other items and no error" {
    # templates/config.yaml declares ADR, and a new project has no docs/adr.
    declare_adr_prefix .guardrails/config.yaml
    commit_all declare-adr
    [ ! -e docs/adr ]
    run_find_items_stderr_to "$BATS_TEST_TMPDIR/stderr" list
    [ "$status" -eq 0 ] || { echo "$output"; cat "$BATS_TEST_TMPDIR/stderr"; false; }
    expected='REQ-001 - docs/requirements/0001-01-01-base.md:3 The system shall limit the dose.
REQ-a3k9z2 - docs/requirements/0001-01-01-base.md:5 The system shall log the dose.
HAZ-001 - docs/risk/0001-01-01-base.md:3 Overdose delivered to patient.
RC-001 - docs/risk/0001-01-01-base.md:5 Software limits dose to configured maximum. mitigates: HAZ-001
PR-001 open docs/problems/0001-01-01-base.md:3 The dose display rounds down.
PR-002 resolved docs/problems/0001-01-01-base.md:7 The log omits the unit.
PR-003 accepted docs/problems/0001-01-01-base.md:14 The alarm is silent.
PR-004 - docs/problems/0001-01-01-base.md:19 The unit label is truncated.'
    [ "$output" = "$expected" ] || { echo "$output"; false; }
    [ ! -s "$BATS_TEST_TMPDIR/stderr" ] || { cat "$BATS_TEST_TMPDIR/stderr"; false; }
}

# verifies: PR-ka8w9m
@test "find-items: list in a multi-unit repository with ADR declared and no docs/adr directory prints the unit's items and no error" {
    make_units_fixture
    declare_adr_prefix apps/pump/.guardrails/config.yaml
    commit_all declare-adr
    [ ! -e docs/adr ] && [ ! -e apps/pump/docs/adr ]
    GR_CONFIG=apps/pump/.guardrails/config.yaml \
        run_find_items_stderr_to "$BATS_TEST_TMPDIR/stderr" list
    [ "$status" -eq 0 ] || { echo "$output"; cat "$BATS_TEST_TMPDIR/stderr"; false; }
    expected='REQ-p2m4k7 - apps/pump/docs/requirements/0001-01-01-base.md:3 The software shall limit the dose. (implements: RC-p4q7t3)
HAZ-p3v8n2 - apps/pump/docs/risk/0001-01-01-base.md:3 Overdose delivered to patient.
RC-p4q7t3 - apps/pump/docs/risk/0001-01-01-base.md:5 Software limits dose to configured maximum. mitigates: HAZ-p3v8n2
SDD-p5w2x8 - apps/pump/docs/architecture/0001-01-01-base.md:3 Dose limiter module. traces: REQ-p2m4k7
LLR-p6r3z9 - apps/pump/docs/architecture/0001-01-01-base.md:5 Clamp requested dose to the configured maximum. satisfies: REQ-p2m4k7'
    [ "$output" = "$expected" ] || { echo "$output"; false; }
    [ ! -s "$BATS_TEST_TMPDIR/stderr" ] || { cat "$BATS_TEST_TMPDIR/stderr"; false; }
}

# verifies: PR-ka8w9m
@test "find-items: the ADR files are not read when id_prefixes declares a prefix that contains ADR but not ADR" {
    sed -i.bak 's|^id_prefixes: REQ HAZ RC SDD LLR PR$|id_prefixes: REQ HAZ RC SDD LLR PR XADR|' .guardrails/config.yaml
    rm -f .guardrails/config.yaml.bak
    grep -qx 'id_prefixes: REQ HAZ RC SDD LLR PR XADR' .guardrails/config.yaml || { cat .guardrails/config.yaml; false; }
    mkdir -p docs/adr
    printf '**REQ-002**: A requirement line inside an ADR file.\n' \
        > docs/adr/ADR-p8w3n5-x.md
    commit_all xadr-prefix
    run sh .guardrails/scripts/find-items.sh list --kind REQ
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"REQ-002"* ]] || { echo "$output"; false; }
    run sh .guardrails/scripts/find-items.sh show REQ-002
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [ "${lines[0]}" = "NOT-FOUND REQ-002" ] || { echo "$output"; false; }
}

# verifies: PR-ka8w9m
@test "find-items: the ADR files are not read when id_prefixes declares a prefix that begins with ADR but is not ADR" {
    sed -i.bak 's|^id_prefixes: REQ HAZ RC SDD LLR PR$|id_prefixes: REQ HAZ RC SDD LLR PR ADRX|' .guardrails/config.yaml
    rm -f .guardrails/config.yaml.bak
    grep -qx 'id_prefixes: REQ HAZ RC SDD LLR PR ADRX' .guardrails/config.yaml || { cat .guardrails/config.yaml; false; }
    mkdir -p docs/adr
    printf '**REQ-002**: A requirement line inside an ADR file.\n' \
        > docs/adr/ADR-p8w3n5-x.md
    commit_all adrx-prefix
    run sh .guardrails/scripts/find-items.sh list --kind REQ
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"REQ-002"* ]] || { echo "$output"; false; }
    run sh .guardrails/scripts/find-items.sh show REQ-002
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [ "${lines[0]}" = "NOT-FOUND REQ-002" ] || { echo "$output"; false; }
}

# verifies: PR-ka8w9m
@test "find-items: a docs/adr file named ADR-* that does not end in .md is not read" {
    write_adr_fixture
    printf '**ADR-x7k2m9**: An older copy of the decision.\n' \
        > docs/adr/ADR-x7k2m9-old.md.orig
    commit_all adr-orig
    run sh .guardrails/scripts/find-items.sh list --kind ADR
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = "ADR-x7k2m9 - docs/adr/ADR-x7k2m9-dose-limit-source.md:1 The dose limit is read from the pump configuration." ] \
        || { echo "$output"; false; }
    run sh .guardrails/scripts/find-items.sh show ADR-x7k2m9
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "${lines[0]}" = "==> docs/adr/ADR-x7k2m9-dose-limit-source.md:1" ] || { echo "$output"; false; }
    block_count=$(printf '%s\n' "$output" | grep -c '^==> ')
    [ "$block_count" -eq 1 ] || { echo "$output"; false; }
}
