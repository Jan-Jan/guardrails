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
