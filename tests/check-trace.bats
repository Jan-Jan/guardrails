load helpers

setup() {
    make_fixture_repo
    cat > docs/requirements/0001-01-01-base.md <<'EOF'
# SRS

**REQ-001**: The system shall limit the dose. (implements: RC-001)
EOF
    cat > docs/risk/0001-01-01-base.md <<'EOF'
# Risk Management File

**HAZ-001**: Overdose delivered to patient.

**RC-001**: Software limits dose to configured maximum. mitigates: HAZ-001
EOF
    cat > docs/architecture/0001-01-01-base.md <<'EOF'
# Software Architecture

**SDD-001**: Dose limiter module. traces: REQ-001

**LLR-001**: Clamp requested dose to the configured maximum. satisfies: REQ-001
EOF
    printf '# verifies: LLR-001\ntrue\n' > tests/test_a.sh
    commit_all good
}

@test "check-trace: fully traced fixture passes" {
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]   # summary lines only: nothing precedes checked:
}

@test "check-trace: REQ without verifying test fails" {
    printf 'true\n' > tests/test_a.sh
    commit_all no-verifies
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST REQ-001"* ]]
}

@test "check-trace: hazard without risk control fails" {
    printf '\n**HAZ-002**: Underdose.\n' >> docs/risk/0001-01-01-base.md
    commit_all haz2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNMITIGATED-HAZARD HAZ-002"* ]]
}

@test "check-trace: risk control without implementing requirement fails" {
    printf '\n**RC-002**: Alarm on underdose. mitigates: HAZ-001\n' >> docs/risk/0001-01-01-base.md
    commit_all rc2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNIMPLEMENTED-CONTROL RC-002"* ]]
}

@test "check-trace: design item without traces fails" {
    printf '\n**SDD-002**: Logging module.\n' >> docs/architecture/0001-01-01-base.md
    commit_all sdd2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNTRACED-DESIGN SDD-002"* ]]
}

@test "check-trace: REQ covered only transitively via tested LLR passes" {
    # fixture already has: test verifies LLR-001, LLR-001 satisfies REQ-001,
    # and no direct test for REQ-001
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]   # summary lines only: nothing precedes checked:
}

@test "check-trace: LLR without satisfies fails" {
    printf '\n**LLR-002**: Log every dose change.\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all llr2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
}

@test "check-trace: derived LLR mentioned in RMF is not UNSATISFIED" {
    printf '\n**LLR-002**: Debounce sensor input. satisfies: derived\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    printf '\nDerived requirements assessment: LLR-002 introduces no new hazard.\n' >> docs/risk/0001-01-01-base.md
    commit_all derived
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]   # summary lines only: nothing precedes checked:
}

@test "check-trace: LLR without verifying test fails" {
    printf '\n**LLR-002**: Log every dose change. satisfies: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    commit_all llr2-untested
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST LLR-002"* ]]
}

@test "check-trace: REQ with neither direct test nor tested LLR fails" {
    printf '\n**REQ-002**: The software shall log all doses.\n' >> docs/requirements/0001-01-01-base.md
    commit_all req2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST REQ-002"* ]]
}

@test "check-trace: derived LLR not assessed in RMF fails" {
    printf '\n**LLR-002**: Debounce sensor input. satisfies: derived\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all derived-unassessed
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNANALYZED-DERIVED LLR-002"* ]]
}

@test "check-trace: derived REQ not assessed in RMF fails" {
    printf '\n**REQ-002**: The software shall retry the bus handshake. satisfies: derived\n' >> docs/requirements/0001-01-01-base.md
    printf '# verifies: REQ-002\ntrue\n' > tests/test_c.sh
    commit_all derived-req
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNANALYZED-DERIVED REQ-002"* ]]
}

@test "check-trace: open problem report warns but passes" {
    write_pr PR-001 open "$(days_ago 5)"
    commit_all open-pr
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"UNRESOLVED-PR PR-001"* ]]
}

@test "check-trace: resolved problem report is silent" {
    printf '**PR-001**: Crash on empty dose input.\naffects: REQ-001\nstatus: resolved\n' > docs/problems/0001-01-01-base.md
    commit_all resolved-pr
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]   # summary lines only: nothing precedes checked:
}

@test "check-trace: open PR warning coexists with real failure exit 1" {
    write_pr PR-001 open "$(days_ago 5)"
    printf '\n**HAZ-002**: Underdose.\n' >> docs/risk/0001-01-01-base.md
    commit_all pr-and-haz
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNRESOLVED-PR PR-001"* ]]
    [[ "$output" == *"UNMITIGATED-HAZARD HAZ-002"* ]]
}

@test "check-trace: prose satisfies after a heading does not satisfy an LLR" {
    printf '\n**LLR-002**: Log every dose change.\n\n## Notes\n\nThis module satisfies: REQ-001 in spirit.\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all prose-satisfies
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
}

@test "check-trace: longer-ID mention in RMF does not cover a derived LLR" {
    printf '\n**LLR-002**: Debounce sensor input. satisfies: derived\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    printf '\nLLR-0020 has no hazard impact.\n' >> docs/risk/0001-01-01-base.md
    commit_all substring
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNANALYZED-DERIVED LLR-002"* ]]
}

@test "check-trace: a later item's open status does not reach the resolved item above" {
    # Was written against `**PR-DRAFT-b-1**`, from the ID scheme that minted
    # draft tokens and rewrote them at merge. That scheme is gone: IDs are now
    # random and final from the first keystroke, so a DRAFT- token is not an ID
    # at all and this fixture stopped exercising block attribution. It now uses
    # two real items, which is what the name always claimed.
    printf '**PR-001**: Crash on empty input.\naffects: REQ-001\nstatus: resolved\n\n**PR-p9r5wx**: New issue.\naffects: REQ-001\nopened: %s\nstatus: open\n' "$(days_ago 5)" > docs/problems/0001-01-01-base.md
    commit_all mixed-prs
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"UNRESOLVED-PR PR-001"* ]] || { echo "$output"; false; }
    [[ "$output" == *"UNRESOLVED-PR PR-p9r5wx"* ]] || { echo "$output"; false; }
}

@test "check-trace: dangling affects reference in problems log fails" {
    printf '**PR-001**: Crash on empty input.\naffects: REQ-999\nstatus: resolved\n' > docs/problems/0001-01-01-base.md
    commit_all dangling-pr
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-999"* ]]
}

@test "check-trace: rules work across multiple dated ledger files" {
    # new change adds a REQ in a later requirements file, implementing an RC
    # defined in a later risk file; LLR for it lives in a later sad file
    printf '**RC-002**: Alarm on stuck sensor. mitigates: HAZ-001\n' > docs/risk/2026-02-02-alarms.md
    printf '**REQ-002**: The software shall raise the stuck-sensor alarm. (implements: RC-002)\n' > docs/requirements/2026-02-02-alarms.md
    printf '**LLR-002**: Debounce then latch the alarm line. satisfies: REQ-002\n' > docs/architecture/2026-02-02-alarms.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_alarm.sh
    commit_all cross-file
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]   # summary lines only: nothing precedes checked:
}

@test "check-trace: derived assessment in any rmf-directory file counts" {
    printf '**LLR-002**: Debounce sensor input. satisfies: derived\n' > docs/architecture/2026-02-02-x.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    printf 'Derived requirements assessment: LLR-002 no hazard impact.\n' > docs/risk/2026-02-02-derived.md
    commit_all derived-cross
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]   # summary lines only: nothing precedes checked:
}

@test "check-trace: template READMEs in ledger dirs cause no false positives" {
    cp "$BATS_TEST_DIRNAME"/../templates/srs.md docs/requirements/README.md
    cp "$BATS_TEST_DIRNAME"/../templates/rmf.md docs/risk/README.md
    cp "$BATS_TEST_DIRNAME"/../templates/sad.md docs/architecture/README.md
    cp "$BATS_TEST_DIRNAME"/../templates/problems.md docs/problems/README.md
    commit_all readmes
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]   # summary lines only: nothing precedes checked:
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
}

@test "check-trace: single-file doc config still works (back-compat)" {
    # rewrite config to the old monolithic layout
    sed -i.bak \
        -e 's|^doc_srs: .*|doc_srs: docs/requirements/srs.md|' \
        -e 's|^doc_rmf: .*|doc_rmf: docs/risk/rmf.md|' \
        .guardrails/config.yaml
    rm -f .guardrails/config.yaml.bak
    mv docs/requirements/0001-01-01-base.md docs/requirements/srs.md
    mv docs/risk/0001-01-01-base.md docs/risk/rmf.md
    commit_all single-file-layout
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]   # summary lines only: nothing precedes checked:
    printf '\n**HAZ-002**: Underdose.\n' >> docs/risk/rmf.md
    commit_all haz2-single
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNMITIGATED-HAZARD HAZ-002"* ]]
}

@test "check-trace: dangling reference to undefined ID fails" {
    printf '# REQ-999 is handled here\n' > src/main.sh
    commit_all dangling
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-999"* ]]
}

@test "check-trace: a REQ in a parenthetical after the list is not coverage" {
    printf '\n**REQ-002**: second requirement.\n' >> docs/requirements/0001-01-01-base.md
    printf '# verifies: LLR-001 (was REQ-002)\ntrue\n' > tests/test_a.sh
    commit_all parenthetical
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST REQ-002"* ]]
}

@test "check-trace: comma lists, trailing commas and trailing prose all count" {
    printf '\n**REQ-002**: second.\n\n**REQ-003**: third.\n' >> docs/requirements/0001-01-01-base.md
    printf '# verifies: LLR-001, REQ-002 — the fallback path\ntrue\n' > tests/test_a.sh
    printf '# verifies: REQ-003,\ntrue\n' > tests/test_b.sh
    commit_all lists
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" != *"MISSING-TEST REQ-001"* ]]
    [[ "$output" != *"MISSING-TEST REQ-002"* ]]
    [[ "$output" != *"MISSING-TEST REQ-003"* ]]
}

@test "check-trace: a REQ in a parenthetical after satisfies: does not satisfy an LLR" {
    printf '\n**REQ-002**: second.\n' >> docs/requirements/0001-01-01-base.md
    cat > docs/architecture/0001-01-01-base.md <<'EOF'
# Software Architecture

**SDD-001**: Dose limiter module. traces: REQ-001

**LLR-001**: Clamp requested dose. satisfies: REQ-001 (superseded REQ-002)
EOF
    commit_all satisfies-parenthetical
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST REQ-002"* ]]
}

@test "check-trace: traces: with no ID list is untraced even if a REQ appears later" {
    cat > docs/architecture/0001-01-01-base.md <<'EOF'
# Software Architecture

**SDD-001**: Dose limiter module. traces: none — replaces REQ-001

**LLR-001**: Clamp requested dose. satisfies: REQ-001
EOF
    commit_all bad-traces
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNTRACED-DESIGN SDD-001"* ]]
}

@test "check-trace: a configured doc path that is absent fails loudly, never silently passes" {
    rm -rf docs/risk
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_rmf"* ]]
}

@test "check-trace: a configured test path that is absent fails loudly" {
    rm -rf tests
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"test_paths"* ]]
}

@test "check-trace: prints how many items of each prefix were checked" {
    # The whole summary line, matched exactly, with the prefixes deliberately
    # holding different counts: asserting substrings like "REQ 3" would still
    # pass if the loop reported one prefix's count under every prefix's name.
    cat >> docs/requirements/0001-01-01-base.md <<'EOF'

**REQ-002**: The system shall enforce the minimum dose. implements: RC-002

**REQ-003**: The system shall log every dose decision.
EOF
    cat >> docs/risk/0001-01-01-base.md <<'EOF'

**HAZ-002**: Underdose delivered to patient.

**RC-002**: Software enforces the configured minimum. mitigates: HAZ-002
EOF
    printf '# verifies: REQ-002 REQ-003\ntrue\n' > tests/test_b.sh
    commit_all counts
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"checked: REQ 3, HAZ 2, RC 2, SDD 1, LLR 1, PR 0"* ]]
}

@test "check-trace: reports how many source files each gate read" {
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    # docs/requirements holds the ratchet README plus the fixture ledger file
    [[ "$output" == *"sources: srs 2,"* ]]
    [[ "$output" == *"tests 1"* ]]
}

@test "check-trace: a requirements ledger with no REQ items reports REQ 0, not a silent pass" {
    rm -f docs/requirements/0001-01-01-base.md
    commit_all empty-srs
    run sh .guardrails/scripts/check-trace.sh
    # REQ-001 is still referenced from the SAD and the tests, so this run
    # legitimately fails on DANGLING-REF. The point of the test is the
    # denominator: the summary says REQ 0 instead of leaving a zero-item run
    # indistinguishable from a full one.
    [ "$status" -eq 1 ]
    [[ "$output" == *"REQ 0"* ]]
    [[ "$output" == *"sources: srs 1,"* ]]
}

# --- Config shapes that would silently disable a gate ----------------------
# Each of these produced a confident exit 0 over an unchecked hazard.

@test "check-trace: a ledger directory holding no *.md is an error, not an empty document" {
    rm -f docs/risk/*.md
    commit_all no-rmf-files
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_rmf"* ]]
    [[ "$output" == *"no *.md"* ]]
}

@test "check-trace: a configured strict path that is absent fails loudly" {
    rm -rf src
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"strict_paths"* ]]
}

@test "check-trace: an absent path containing a space is named in full" {
    sed -i.bak 's|^  - src$|  - my sources|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"my sources"* ]]
}

@test "check-trace: an ID prefix that is not a bare identifier is an error" {
    sed -i.bak 's/^id_prefixes:.*/id_prefixes: REQ HAZ RC SDD LLR PR[/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"bare identifier"* ]]
}

# --- One annotation rule, applied identically to every keyword -------------

@test "check-trace: traces: counts a REQ anywhere in its list, not only first" {
    cat >> docs/architecture/0001-01-01-base.md <<'EOF'

**SDD-002**: Dose logger. traces: SDD-001, REQ-001
EOF
    commit_all sdd2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"UNTRACED-DESIGN SDD-002"* ]]
}

@test "check-trace: a REQ named in prose after satisfies: does not satisfy an LLR" {
    cat >> docs/architecture/0001-01-01-base.md <<'EOF'

**LLR-002**: Round the dose. satisfies: none yet — use the satisfies: REQ-001 form
EOF
    printf '# verifies: LLR-001 LLR-002\ntrue\n' > tests/test_a.sh
    commit_all llr2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
}

# --- Configured paths must match something that is actually there ----------

@test "check-trace: a strict path written as a glob still reaches the scan" {
    # asserting exit 0 would prove nothing — a path that is silently dropped
    # also exits 0. Put a dangling reference behind the glob and require the
    # scan to find it.
    printf '// see REQ-999\n' > src/a.c
    sed -i.bak 's|^  - src$|  - src/*.c|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    commit_all glob-path
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-999"* ]]
}

@test "check-trace: a strict path glob that matches nothing is still an error" {
    sed -i.bak 's|^  - src$|  - src/*.rs|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"src/*.rs"* ]]
}

# --- Path entries: plain paths, shell globs and git pathspecs --------------

@test "check-trace: a recursive git pathspec in test_paths is accepted" {
    # `*_test.sh` expands to nothing for the shell but matches recursively for
    # git, which is what actually scans these paths. Rejecting it hard-failed
    # a fully traced project.
    mkdir -p tests/unit
    git rm -q tests/test_a.sh
    printf '# verifies: LLR-001\ntrue\n' > tests/unit/a_test.sh
    sed -i.bak 's|^  - tests$|  - *_test.sh|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    commit_all pathspec
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]
}

@test "check-trace: a pathspec matching no file at all is still an error" {
    sed -i.bak 's|^  - tests$|  - *_nothing.sh|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"matches no file"* ]]
}

@test "check-trace: a pathspec matching a non-ASCII path is accepted" {
    # git ls-files C-quotes any path with a non-ASCII byte, a quote, a tab or
    # a newline. Testing [ -e ] on each returned name rejected a directory
    # git grep scans perfectly well; counting is immune to the quoting.
    mkdir -p 'tésts'
    git rm -q tests/test_a.sh
    printf '# verifies: LLR-001\ntrue\n' > 'tésts/a_test.sh'
    sed -i.bak 's|^  - tests$|  - *_test.sh|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    commit_all nonascii
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]
}

@test "check-trace: an unrelated later traces: does not credit an SDD block" {
    # The SDD block must end at the next definition line or heading, the same
    # rule parse_llr_file uses. Without a terminator an annotation far below
    # credited an SDD that carries none of its own.
    cat >> docs/architecture/0001-01-01-base.md <<'EOF'

**SDD-002**: Logging module, no trace of its own.

**LLR-002**: Log every dose change. satisfies: REQ-001. traces: REQ-001
EOF
    printf '# verifies: LLR-001 LLR-002\ntrue\n' > tests/test_a.sh
    commit_all sdd-block
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNTRACED-DESIGN SDD-002"* ]]
}

@test "check-trace: a configured directory that is empty matches no file" {
    # An empty directory exists but holds nothing to scan; passing it would
    # report `strict 1` for a source that read nothing.
    rm -f src/.gitkeep
    commit_all empty-src
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"strict_paths"* ]]
    [[ "$output" == *"matches no file"* ]]
}

@test "check-trace: a path entry is a git pathspec, not shell-expanded at the root" {
    # Left to the shell, `*.c` is replaced by whatever matches in the repo root
    # and the recursive meaning is lost — src/ is never scanned, while
    # `sources:` still reports strict 1. Deleting an unrelated root file then
    # changes the verdict.
    printf 'int main(void){return 0;}\n' > main.c
    printf '// see REQ-999\n' > src/foo.c
    sed -i.bak 's|^  - src$|  - *.c|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    commit_all glob-narrowing
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-999"* ]]
}

@test "check-trace: traces: on a line below the SDD header still counts" {
    # The block terminator must not swallow the header's own block: an
    # annotation on a continuation line is the shape a careless fix breaks.
    cat >> docs/architecture/0001-01-01-base.md <<'EOF'

**SDD-002**: Dose logger.
traces: REQ-001
EOF
    commit_all sdd-continuation
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"UNTRACED-DESIGN SDD-002"* ]]
}

# --- Config value lexing ----------------------------------------------------

@test "check-trace: a trailing comment on a scalar value is not part of the value" {
    sed -i.bak 's|^doc_rmf: docs/risk$|doc_rmf: docs/risk  # the RMF|' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"rmf 2"* ]]
}

@test "check-trace: a config with CRLF line endings still parses" {
    sed -i.bak 's/$/\r/' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]
}

# --- Config shapes the reader cannot see ------------------------------------

@test "check-trace: a key with a hyphen instead of an underscore is an error" {
    sed -i.bak 's/^strict_paths:/strict-paths:/' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"strict-paths"* ]]
}

@test "check-trace: an indented top-level key is an error" {
    sed -i.bak 's/^strict_paths:/ strict_paths:/' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"strict_paths"* ]]
}

@test "check-trace: a space before the colon is an error" {
    sed -i.bak 's/^strict_paths:/strict_paths :/' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"strict_paths"* ]]
}

@test "check-trace: a list item at column zero is an error" {
    # cfg_list never read these, so the list was silently empty
    sed -i.bak 's/^  - src$/- src/' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"- src"* ]]
}

@test "check-trace: a config saved with a UTF-8 BOM is rejected, not half-read" {
    printf '\xef\xbb\xbf' > .guardrails/config.new
    cat .guardrails/config.yaml >> .guardrails/config.new
    mv .guardrails/config.new .guardrails/config.yaml
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"BOM"* ]]
}

@test "check-trace: a config with a YAML document separator still parses" {
    # not `sed '1i'` — its one-line form is GNU-specific
    printf -- '---\n' > .guardrails/config.new
    cat .guardrails/config.yaml >> .guardrails/config.new
    mv .guardrails/config.new .guardrails/config.yaml
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
}

@test "check-trace: a typo'd doc key is an error, not a project without that document" {
    cat >> docs/risk/0001-01-01-base.md <<'EOF'

**HAZ-002**: Underdose delivered to patient.
EOF
    commit_all unmitigated
    # sanity: with the key spelled correctly this run fails on HAZ-002, so the
    # exit 2 below closes a hole that was really open
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNMITIGATED-HAZARD HAZ-002"* ]]

    sed -i.bak 's/^doc_rmf:/doc_rmff:/' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_rmff"* ]]
}

# --- A prefix must have gates, and those gates must have their inputs -------

@test "check-trace: a config with no gated prefix at all is an error" {
    # Not "every prefix must be gated" — an extra prefix is covered by
    # DANGLING-REF and DUPLICATE-ID and is a legitimate thing to declare. What
    # is not legitimate is a config where NO prefix has a traceability gate:
    # every gate is then off and the run still exits 0.
    sed -i.bak 's/^id_prefixes:.*/id_prefixes: TC/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"TC"* ]]
    [[ "$output" == *"no prefix with a traceability gate"* ]]
}

@test "check-trace: an extra prefix alongside the gated ones is accepted and still checked" {
    # DANGLING-REF is keyed on the configured prefix list, so an extra prefix
    # IS checked. Rejecting it told the operator to remove it, which removed
    # that coverage and turned a reported violation into exit 0.
    sed -i.bak 's/^id_prefixes:.*/id_prefixes: REQ HAZ RC SDD LLR PR ADR/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf '// see ADR-007\n' > src/main.c
    commit_all extra-prefix
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF ADR-007"* ]]
}


@test "check-trace: RC declared without doc_srs is an error, not a skipped gate" {
    # UNIMPLEMENTED-CONTROL looks for a REQ that implements each RC, so it
    # reads doc_srs — a document RC is not defined in.
    cat > .guardrails/config.yaml <<'EOF'
guardrails_version: 0.1.0
safety_class: B
id_prefixes: HAZ RC
doc_rmf: docs/risk
EOF
    commit_all haz-rc-only
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_srs"* ]]
    [[ "$output" == *"RC"* ]]
}

@test "check-trace: REQ declared with an empty test_paths is an error, not zero tests to search" {
    # A present-but-empty list, not a typo: `test_path:` is already caught as
    # an unknown key, so it would not exercise this rule at all.
    sed -i.bak 's|^  - tests$||' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"test_paths"* ]]
}

@test "check-trace: RC declared without doc_rmf is rejected, not left unplaceable" {
    # This test asserted the OPPOSITE until the placement gate landed, and the
    # reversal is a premise change rather than an oscillation. Before the gate,
    # nothing read where an RC was defined — UNIMPLEMENTED-CONTROL reads
    # doc_srs — so requiring doc_rmf would have rejected a retrofit that had
    # requirements, controls and design but no risk management file yet, while
    # telling it a gate "could never run" that demonstrably did.
    #
    # MISPLACED-ITEM now reads doc_rmf to decide whether each control is
    # defined where its gates can see it. Unconfigured, that gate is not
    # skipped: it condemns every control in the project, once each, naming a
    # key the config never set. One error before any gate runs says it better.
    cat > .guardrails/config.yaml <<'EOF'
guardrails_version: 0.1.0
safety_class: B
id_prefixes: REQ RC SDD
doc_srs: docs/requirements
doc_sad: docs/architecture
strict_paths:
  - src
test_paths:
  - tests
EOF
    printf '\n**RC-002**: an unimplemented control.\n' >> docs/requirements/0001-01-01-base.md
    commit_all rc-no-rmf
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"declares RC but doc_rmf is not configured"* ]]
    [[ "$output" == *"only document a RC may be defined in"* ]]
}

@test "check-trace: a list item orphaned by a commented-out key is an error" {
    # Absorbing it into the block above turns a production source path into a
    # test path, so a `verifies:` annotation in src/ counts as a test.
    sed -i.bak 's/^strict_paths:$/# strict_paths:/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"- src"* ]]
}

@test "check-trace: an SDD defined outside doc_sad is reported, not silently exempt" {
    # No traces: line at all. Inside doc_sad this is UNTRACED-DESIGN; outside
    # it, it was counted by `checked:` and examined by nothing.
    printf '**SDD-002**: a design item nobody reads\n' > docs/design.md
    commit_all sdd-outside
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISPLACED-ITEM SDD-002"* ]]
    [[ "$output" == *"doc_sad"* ]]
}

@test "check-trace: a REQ defined outside doc_srs is reported" {
    printf '**REQ-002**: a requirement in the wrong file\n' > docs/notes.md
    printf '# verifies: REQ-002\ntrue\n' > tests/test_b.sh
    commit_all req-outside
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISPLACED-ITEM REQ-002 (must be defined in the files doc_srs resolves to"* ]]
}

@test "check-trace: a HAZ defined outside doc_rmf is reported" {
    printf '**HAZ-002**: a hazard in the wrong file\n' > docs/notes.md
    printf '\n**RC-002**: Alarm on the hazard. mitigates: HAZ-002\n' \
        >> docs/risk/0001-01-01-base.md
    sed -i.bak 's/implements: RC-001/implements: RC-001, RC-002/' \
        docs/requirements/0001-01-01-base.md && rm -f docs/requirements/0001-01-01-base.md.bak
    commit_all haz-outside
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISPLACED-ITEM HAZ-002 (must be defined in the files doc_rmf resolves to"* ]]
}

@test "check-trace: an RC defined outside doc_rmf is reported" {
    printf '**RC-002**: a control in the wrong file. mitigates: HAZ-001\n' > docs/notes.md
    sed -i.bak 's/implements: RC-001/implements: RC-001, RC-002/' \
        docs/requirements/0001-01-01-base.md && rm -f docs/requirements/0001-01-01-base.md.bak
    commit_all rc-outside
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISPLACED-ITEM RC-002 (must be defined in the files doc_rmf resolves to"* ]]
}

@test "check-trace: an LLR defined outside doc_sad is reported" {
    # UNSATISFIED-LLR parses doc_sad only, so a misplaced LLR keeps no
    # `satisfies:` obligation. MISSING-TEST does still see it — hence the
    # `verifies:` below — which is why the message states the rule alone.
    printf '**LLR-002**: a low-level requirement in the wrong file. satisfies: REQ-001\n' \
        > docs/notes.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all llr-outside
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISPLACED-ITEM LLR-002 (must be defined in the files doc_sad resolves to"* ]]
}

@test "check-trace: a PR defined outside doc_problems is reported" {
    printf '**PR-001**: a problem report in the wrong file\n\nstatus: resolved\n' > docs/notes.md
    commit_all pr-outside
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISPLACED-ITEM PR-001 (must be defined in the files doc_problems resolves to"* ]]
}

@test "check-trace: correctly placed items are not reported as misplaced" {
    # A guard, not a RED test: it passed before the gate existed, because the
    # gate did. Its value is in the mutation runs — removing the gr_contains
    # check in check_placement turns it red while the misplacement tests stay
    # green, which is what proves it constrains over-firing.
    printf '**PR-001**: A closed problem.\n\nstatus: resolved\n' \
        > docs/problems/0001-01-01-base.md
    commit_all placed
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"MISPLACED-ITEM"* ]]
}

@test "check-trace: an item in a subdirectory of its doc directory is reported" {
    # gr_doc_files expands "$dir"/*.md — one level deep. A file one level
    # further down is not among the files doc_srs resolves to, so the gate
    # keyed on that document never parses it.
    mkdir -p docs/requirements/2026
    printf '**REQ-002**: filed a level too deep\n' > docs/requirements/2026/r.md
    printf '# verifies: REQ-002\ntrue\n' > tests/test_b.sh
    commit_all nested
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISPLACED-ITEM REQ-002 (must be defined in the files doc_srs resolves to"* ]]
}

@test "every script is executable in the index, not just runnable via sh" {
    # Not a duplicate of the tests above: those all invoke `sh <path>`, which
    # works on a file with no executable bit. Every skill and template
    # documents the bare path, and ratchet installs "keeping executable bits",
    # so a mode lost here propagates into every target project as exit 126.
    #
    # Read from the INDEX (`git ls-files -s`), not from HEAD and not from the
    # working tree. The accident this exists to catch — an `awk > tmp && mv`
    # carrying 0644 across — reaches the index at `git add`, and HEAD only one
    # commit later; a working-tree check would also pass silently on a
    # mode-ignoring filesystem. With nothing staged the index equals HEAD, so
    # this is strictly earlier, never later.
    cd "$BATS_TEST_DIRNAME/.."
    # tests/evidence.sh stages the base revision's scripts into a plain
    # directory to run this same suite against them. There is no git there to
    # ask, and a hard failure would book this test as "red against the base" —
    # evidence that the change fixed something, when the base was fine. That
    # exact miscount has now happened twice; skip rather than lie about it.
    git rev-parse --git-dir >/dev/null 2>&1 || skip "not a git checkout"
    run git ls-files -s scripts/
    [ "$status" -eq 0 ]
    seen=0
    while read -r mode _hash _stage path; do
        [ -n "$path" ] || continue
        case "$path" in (*.sh) ;; (*) continue ;; esac
        seen=$((seen + 1))
        [ "$mode" = "100755" ] || { echo "not executable in the index: $path ($mode)"; false; }
    done <<< "$output"
    # Without this the test passes having examined nothing: guardrails unpacked
    # inside some other repo answers `git rev-parse` fine and lists no
    # scripts/, so every assertion above is vacuous. That is the shape
    # require_paths and gr_doc_files exist to forbid; it must not appear here.
    [ "$seen" -gt 0 ] || { echo "no scripts/*.sh in the index — this test proved nothing"; false; }
}

@test "check-trace: an item in a non-md file inside its doc directory is reported" {
    # "Outside doc_srs" means outside what gr_doc_files resolves — its *.md
    # files one level deep — not outside the directory. A .txt sitting right
    # in the ledger is not among them either, so the message must not tell the
    # operator to move a file that is already where they would move it.
    printf '**REQ-002**: in a .txt inside the ledger directory\n' > docs/requirements/srs.txt
    printf '# verifies: REQ-002\ntrue\n' > tests/test_b.sh
    commit_all txt-ledger
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISPLACED-ITEM REQ-002 (must be defined in the files doc_srs resolves to"* ]]
}

@test "check-trace: every misplaced item is reported, not just the first" {
    printf '**REQ-002**: first stray\n\n**REQ-003**: second stray\n' > docs/notes.md
    printf '# verifies: REQ-002, REQ-003\ntrue\n' > tests/test_b.sh
    commit_all two-strays
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISPLACED-ITEM REQ-002"* ]]
    [[ "$output" == *"MISPLACED-ITEM REQ-003"* ]]
}

@test "check-trace: an indented definition defines nothing" {
    # AC4: the three shell gates must agree, in both directions. The plan
    # predicted exit 0 here; the gate is sharper than that. The indented token
    # is not a definition, so REQ stays at 1 — and REQ-002 is then a reference
    # to something nothing defines, which is DANGLING-REF. Being *reported as a
    # mention* is stronger evidence than silence that it was not read as a
    # definition.
    printf '\n  **REQ-002**: An indented line that is not a definition.\n' \
        >> docs/requirements/0001-01-01-base.md
    commit_all indented
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-002"* ]]
    [[ "$output" == *"checked: REQ 1,"* ]] || { echo "indented line was counted: $output"; false; }
}

@test "check-trace: a mid-line definition form defines nothing" {
    printf '\nProse that mentions `**REQ-002**:` without defining it.\n' \
        >> docs/requirements/0001-01-01-base.md
    commit_all midline
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-002"* ]]
    [[ "$output" == *"checked: REQ 1,"* ]] || { echo "mid-line form was counted: $output"; false; }
}

@test "check-trace: the awk block parsers agree with gr_def_re on indentation" {
    # AC6: the block parsers are awk EREs and cannot share gr_def_re's source
    # (awk has no portable {3,}), so they are pinned by test. An indented header
    # must not open a block. All FOUR are covered: an earlier version of this
    # test exercised only LLR and SDD, and unanchoring the REQ or PR parser
    # reddened nothing at all (independent review, round 2, finding 3).
    #
    # Each id is chosen so that parsing the block would produce a visible
    # verdict: the LLR would be UNSATISFIED, the SDD UNTRACED, the REQ would be
    # a derived requirement absent from the RMF (UNANALYZED-DERIVED), and the PR
    # would be an open problem report (UNRESOLVED-PR). None may appear.
    printf '\n  **LLR-002**: An indented low-level requirement.\n' \
        >> docs/architecture/0001-01-01-base.md
    printf '\n  **SDD-002**: An indented design item.\n' \
        >> docs/architecture/0001-01-01-base.md
    # Its own file, with a heading first: appended to the base SRS it would land
    # inside REQ-001's still-open block, and `satisfies: derived` would be
    # credited to REQ-001 — which is correct block behaviour, and would have
    # made this assertion pass for a reason that has nothing to do with
    # anchoring.
    printf '# More requirements\n\n  **REQ-002**: An indented requirement.\nsatisfies: derived\n' \
        > docs/requirements/0001-01-02-indented.md
    printf '\n  **PR-002**: An indented problem report.\nstatus: open\n' \
        >> docs/problems/README.md
    commit_all indented-blocks
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" != *"UNSATISFIED-LLR"* ]] || { echo "awk parsed an indented LLR: $output"; false; }
    [[ "$output" != *"UNTRACED-DESIGN"* ]] || { echo "awk parsed an indented SDD: $output"; false; }
    [[ "$output" != *"UNANALYZED-DERIVED"* ]] || { echo "awk parsed an indented REQ: $output"; false; }
    [[ "$output" != *"UNRESOLVED-PR"* ]] || { echo "awk parsed an indented PR: $output"; false; }
    [[ "$output" == *"DANGLING-REF LLR-002"* ]]
    [[ "$output" == *"DANGLING-REF SDD-002"* ]]
    [[ "$output" == *"DANGLING-REF REQ-002"* ]]
    [[ "$output" == *"DANGLING-REF PR-002"* ]]
    # The whole count line: "SDD 1" also matches "SDD 12".
    [[ "$output" == *"checked: REQ 1, HAZ 1, RC 1, SDD 1, LLR 1, PR 0"* ]] \
        || { echo "counts moved: $output"; false; }
}

@test "check-trace: an indented bold line does not close a block either" {
    # Round 3, note 3: the four parsers are spelled by eight patterns — an
    # opener and a closer each — and only the openers were pinned. Unanchoring a
    # closer reddened nothing. A closer that fires on an indented bold line ends
    # the block early, and the annotation after it is lost: here LLR-001 would
    # stop satisfying anything and be reported UNSATISFIED-LLR.
    cat > docs/architecture/0001-01-01-base.md <<'MD'
# Software Architecture

**SDD-001**: Dose limiter module.
  **note**: an indented bold line inside the block.
traces: REQ-001

**LLR-001**: Clamp requested dose to the configured maximum.
  **note**: an indented bold line inside the block, which is not a definition.
satisfies: REQ-001
MD
    # The same shape for the other three parsers, so all eight patterns — four
    # openers and four closers — are pinned rather than four of them.
    cat > docs/requirements/0001-01-02-derived.md <<'MD'
# More requirements

**REQ-002**: A derived requirement.
  **note**: an indented bold line inside the block.
satisfies: derived
MD
    cat > docs/problems/0001-01-01-open.md <<'MD'
# Problems

**PR-001**: An open problem.
  **note**: an indented bold line inside the block.
status: open
MD
    commit_all indented-inside-block
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" != *"UNSATISFIED-LLR"* ]] || { echo "an indented line closed the LLR block: $output"; false; }
    [[ "$output" != *"UNTRACED-DESIGN"* ]] || { echo "an indented line closed the SDD block: $output"; false; }
    # These two must still be REPORTED: the annotation after the indented line
    # belongs to the block, so losing it would silently drop the finding.
    [[ "$output" == *"UNANALYZED-DERIVED REQ-002"* ]] || { echo "REQ block truncated: $output"; false; }
    [[ "$output" == *"UNRESOLVED-PR PR-001"* ]] || { echo "PR block truncated: $output"; false; }
}

@test "check-trace: items in a ledger under .guardrails/ are counted, not silently zero" {
    # AC5. ids_defined carried the tree-wide exclusion while gr_doc_files, which
    # builds the file list from the config, did not. One script, two opinions
    # about which files exist: the summary read `sources: srs 2` beside
    # `checked: REQ 0`, and every REQ gate became a no-op that still exited 0.
    mkdir -p .guardrails/docs/requirements
    printf '# Requirements ledger\n' > .guardrails/docs/requirements/README.md
    git mv docs/requirements/0001-01-01-base.md \
        .guardrails/docs/requirements/0001-01-01-base.md
    sed -i.bak 's|^doc_srs: docs/requirements$|doc_srs: .guardrails/docs/requirements|' \
        .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    commit_all srs-under-guardrails

    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"checked: REQ 1,"* ]] \
        || { echo "REQ not counted: $output"; false; }
}

# --- the same gates, with minted token IDs ---------------------------------
# Every test above uses sequential IDs, and they all stay: a project that
# predates tokens keeps its numbers, and these two blocks together are what
# proves both forms are live at once.

token_fixture() {
    cat > docs/requirements/0001-01-01-base.md <<'EOF'
# SRS

**REQ-a3k9z2**: The system shall limit the dose. (implements: RC-c5t8bd)
EOF
    cat > docs/risk/0001-01-01-base.md <<'EOF'
# Risk Management File

**HAZ-h7z4mn**: Overdose delivered to patient.

**RC-c5t8bd**: Software limits dose to configured maximum. mitigates: HAZ-h7z4mn
EOF
    cat > docs/architecture/0001-01-01-base.md <<'EOF'
# Software Architecture

**SDD-d2s6fk**: Dose limiter module. traces: REQ-a3k9z2

**LLR-b4r7pq**: Clamp requested dose to the maximum. satisfies: REQ-a3k9z2
EOF
    printf '# verifies: LLR-b4r7pq\ntrue\n' > tests/test_a.sh
    commit_all tokens
}

@test "check-trace: a fully traced token fixture passes" {
    token_fixture
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == "checked: REQ 1, HAZ 1, RC 1, SDD 1, LLR 1, PR 0"* ]] \
        || { echo "$output"; false; }
}

@test "check-trace: a token REQ without a verifying test fails" {
    token_fixture
    printf 'true\n' > tests/test_a.sh
    commit_all no-verifies
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST REQ-a3k9z2"* ]] || { echo "$output"; false; }
}

@test "check-trace: a token hazard without a risk control fails" {
    token_fixture
    printf '\n**HAZ-m6n3vt**: Underdose.\n' >> docs/risk/0001-01-01-base.md
    commit_all haz2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNMITIGATED-HAZARD HAZ-m6n3vt"* ]] || { echo "$output"; false; }
}

@test "check-trace: a token control without an implementing requirement fails" {
    token_fixture
    printf '\n**RC-w8x2ky**: Alarm on underdose. mitigates: HAZ-h7z4mn\n' \
        >> docs/risk/0001-01-01-base.md
    commit_all rc2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNIMPLEMENTED-CONTROL RC-w8x2ky"* ]] || { echo "$output"; false; }
}

@test "check-trace: a token design item without traces fails" {
    token_fixture
    printf '\n**SDD-g5h2jq**: Logging module.\n' >> docs/architecture/0001-01-01-base.md
    commit_all sdd2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNTRACED-DESIGN SDD-g5h2jq"* ]] || { echo "$output"; false; }
}

@test "check-trace: a token LLR that satisfies nothing fails" {
    token_fixture
    printf '\n**LLR-t3v8sz**: A helper with no parent.\n' \
        >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-t3v8sz\ntrue\n' > tests/test_b.sh
    commit_all llr2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNSATISFIED-LLR LLR-t3v8sz"* ]] || { echo "$output"; false; }
}

@test "check-trace: a token derived LLR absent from the RMF fails" {
    token_fixture
    printf '\n**LLR-q7w4zb**: A derived helper. satisfies: derived\n' \
        >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-q7w4zb\ntrue\n' > tests/test_b.sh
    commit_all derived
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNANALYZED-DERIVED LLR-q7w4zb"* ]] || { echo "$output"; false; }
}

@test "check-trace: a derived token analysed in the RMF is accepted" {
    token_fixture
    printf '\n**LLR-q7w4zb**: A derived helper. satisfies: derived\n' \
        >> docs/architecture/0001-01-01-base.md
    printf '\nLLR-q7w4zb assessed: no new hazard.\n' >> docs/risk/0001-01-01-base.md
    printf '# verifies: LLR-q7w4zb\ntrue\n' > tests/test_b.sh
    commit_all derived-ok
    run sh .guardrails/scripts/check-trace.sh
    # The status assertion is not decoration: without it this test passed
    # against a check-trace.sh that exited 2 before running a single gate —
    # the absence it asserts is also what a script that did nothing produces.
    # Independent review, S6.
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"UNANALYZED-DERIVED"* ]] || { echo "$output"; false; }
}

@test "check-trace: a derived token is not satisfied by a longer ID that starts with it" {
    # The boundary that used to be spelled [^0-9]: with tokens, a mention of
    # LLR-q7w4zbq would otherwise be read as covering LLR-q7w4zb. Nothing else
    # in the suite distinguishes those two spellings.
    token_fixture
    printf '\n**LLR-q7w4zb**: A derived helper. satisfies: derived\n' \
        >> docs/architecture/0001-01-01-base.md
    printf '\nLLR-q7w4zbq assessed: a different item entirely.\n' \
        >> docs/risk/0001-01-01-base.md
    printf '# verifies: LLR-q7w4zb\ntrue\n' > tests/test_b.sh
    commit_all derived-prefix
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNANALYZED-DERIVED LLR-q7w4zb"* ]] || { echo "$output"; false; }
}

@test "check-trace: an undefined token reference is DANGLING-REF" {
    token_fixture
    printf '# verifies: LLR-b4r7pq REQ-n9p3ch\ntrue\n' > tests/test_a.sh
    commit_all dangling
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-n9p3ch"* ]] || { echo "$output"; false; }
}

@test "check-trace: a hyphenated English word is not read as a reference" {
    # REQ-update, PR-banner: six letters of the token alphabet and no digit.
    # Without the digit rule each becomes a DANGLING-REF against an item nobody
    # ever wrote, in ordinary source and prose. Both words are checked against
    # the alphabet on purpose — the first draft used PR-review, whose `i` the
    # alphabet excludes, so half the fixture could not have matched under any
    # relaxation of the rule and the comment claiming otherwise was wrong.
    # Independent review, S8.
    token_fixture
    printf 'a REQ-update path and a PR-banner note\n' > src/notes.txt
    commit_all english
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"DANGLING-REF"* ]] || { echo "$output"; false; }
}

@test "check-trace: a token item filed in the wrong document is MISPLACED-ITEM" {
    token_fixture
    printf '\n**HAZ-m6n3vt**: A hazard filed in the SRS.\n' \
        >> docs/requirements/0001-01-01-base.md
    commit_all misplaced
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISPLACED-ITEM HAZ-m6n3vt"* ]] || { echo "$output"; false; }
}

@test "check-trace: an open token problem report is listed, without failing" {
    token_fixture
    printf '**PR-p9r5wx**: Something went wrong.\nopened: %s\nstatus: open\n' "$(days_ago 5)" \
        > docs/problems/2026-01-01-x.md
    commit_all pr
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"UNRESOLVED-PR PR-p9r5wx"* ]] || { echo "$output"; false; }
}

@test "widening GR_ID_BODY changes every gate's verdict" {
    # The vocabulary's behavioural pin, and the companion to "poisoning
    # gr_def_re". A textual count of call sites is defeated by a differently
    # spelled copy, so widen the definition instead and require every scan to
    # follow: each fixture below is invisible while a body must carry a digit
    # and visible once any alphanumeric body will do. A gate still holding its
    # own [0-9]{3,} stays quiet at both ends.
    printf '\n**REQ-abcdef**: a body with no digit.\n' >> docs/requirements/0001-01-01-base.md
    printf '\n**SDD-abcdef**: a design item with no traces.\n' \
        >> docs/architecture/0001-01-01-base.md
    printf '\n**LLR-abcdef**: a low-level item satisfying nothing.\n' \
        >> docs/architecture/0001-01-01-base.md
    printf '**PR-abcdef**: an open problem.\nstatus: open\n' \
        > docs/problems/2026-01-01-x.md
    printf 'a mention of RC-wxyzab, defined nowhere\n' > src/notes.txt
    commit_all widen-fixture

    run sh .guardrails/scripts/check-trace.sh
    # `**PR-abcdef**` is not an item at this end, so its `status: open` belongs
    # to nothing and ORPHAN-ANNOTATION says so. That is the gate working, and
    # it is why the baseline is 1 rather than 0.
    [ "$status" -eq 1 ] || { echo "baseline wrong: $output"; false; }
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]] \
        || { echo "baseline wrong: $output"; false; }
    [[ "$output" == *"checked: REQ 1, HAZ 1, RC 1, SDD 1, LLR 1, PR 0"* ]] \
        || { echo "baseline wrong: $output"; false; }

    printf "\nGR_ID_BODY='[A-Za-z0-9]+'\n" >> .guardrails/scripts/lib.sh

    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"checked: REQ 2, HAZ 1, RC 1, SDD 2, LLR 2, PR 1"* ]] \
        || { echo "ids_defined kept its own body: $output"; false; }
    [[ "$output" == *"UNTRACED-DESIGN SDD-abcdef"* ]] \
        || { echo "the SDD block parser kept its own body: $output"; false; }
    [[ "$output" == *"UNSATISFIED-LLR LLR-abcdef"* ]] \
        || { echo "the LLR block parser kept its own body: $output"; false; }
    [[ "$output" == *"UNRESOLVED-PR PR-abcdef"* ]] \
        || { echo "the problem-report parser kept its own body: $output"; false; }
    [[ "$output" == *"DANGLING-REF RC-wxyzab"* ]] \
        || { echo "the reference harvest kept its own body: $output"; false; }
    # And the other direction: once PR-abcdef IS an item, its status line is
    # attributed and the orphan disappears. A block rule holding its own body
    # would leave it orphaned at both ends.
    [[ "$output" != *"ORPHAN-ANNOTATION"* ]] \
        || { echo "the block rule kept its own body: $output"; false; }
}

@test "check-trace: a verifies: reference one character too long is not coverage" {
    # The false green the token length introduces. REQ-a3k9z2x is not an ID;
    # read as one it truncates to REQ-a3k9z2, and the requirement it names goes
    # green on a test that verifies nothing.
    token_fixture
    printf '# verifies: LLR-b4r7pqx\ntrue\n' > tests/test_a.sh
    commit_all truncated-ref
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST LLR-b4r7pq"* ]] || { echo "$output"; false; }
}

@test "check-trace: a reference one character too long is not a dangling ref either" {
    # The truncation must not be reported under a name nobody wrote. The
    # shorter ID here is deliberately UNDEFINED: with REQ-a3k9z2x, whose first
    # six characters name a defined item, the harvest resolves it silently and
    # this test could not fail either way — mutation M46 dropped the boundary
    # and reddened nothing.
    token_fixture
    printf 'a mention of REQ-n9p3chx in source\n' > src/notes.txt
    commit_all truncated-mention
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" != *"DANGLING-REF REQ-n9p3ch"* ]] || { echo "$output"; false; }
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "check-trace: a reference scan that ERRORS is not a tree without dangling refs" {
    # Independent review, blocking finding 1, second site. The harvest that
    # feeds DANGLING-REF suppressed stderr and checked no status, so a scan
    # that errored found nothing — which is exactly what a tree with no bad
    # references looks like.
    #
    # The fault keys on the boundary class, which in this script only the
    # reference harvest passes to a -oE scan.
    real_git=$(command -v git)
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cat > "$BATS_TEST_TMPDIR/bin/git" <<EOF
#!/bin/sh
if [ "\$1" = grep ]; then
    _oe=; _tail=
    for a in "\$@"; do
        [ "\$a" = -oE ] && _oe=1
        case "\$a" in (*'[^0-9A-Za-z]'*) _tail=1 ;; esac
    done
    [ -n "\$_oe" ] && [ -n "\$_tail" ] && exit 129
fi
exec $real_git "\$@"
EOF
    chmod 755 "$BATS_TEST_TMPDIR/bin/git"

    token_fixture
    printf 'a mention of REQ-zzz999 in source\n' > src/notes.txt
    commit_all dangling

    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-zzz999"* ]] || { echo "$output"; false; }

    PATH="$BATS_TEST_TMPDIR/bin:$PATH" run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ] || { echo "errored scan read as clean: $status $output"; false; }
    [[ "$output" == *"reference scan failed"* ]] || { echo "$output"; false; }
}

# --- item blocks end at the next ITEM, not at any bold line ----------------
# docs/plans/2026-08-22-item-blocks.md. One rule, written out four times, made
# two gates reject correct documents and two gates pass silently over real
# violations. The four tests below are one per gate, split by direction.

@test "check-trace: an emphasised line in a PR body does not detach status:" {
    cat > docs/problems/0001-01-01-base.md <<LEDGER
**PR-001**: Crash on empty dose input.
affects: REQ-001
opened: $(days_ago 5)
**21 of 35 inverted, 14 not.**
status: open
LEDGER
    commit_all pr-bold-body
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"UNRESOLVED-PR PR-001"* ]]
}

@test "check-trace: an emphasised line in a REQ body does not detach derived" {
    printf '\n**REQ-002**: The software shall retry the bus handshake.\n**Note.** Emphasised body sentence.\nsatisfies: derived\n' >> docs/requirements/0001-01-01-base.md
    printf '# verifies: REQ-002\ntrue\n' > tests/test_c.sh
    commit_all derived-req-bold
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNANALYZED-DERIVED REQ-002"* ]]
}

@test "check-trace: an emphasised line in an SDD body does not detach traces:" {
    printf '\n**SDD-002**: Logging module.\n**Note.** Emphasised body sentence.\ntraces: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    commit_all sdd-bold
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"UNTRACED-DESIGN SDD-002"* ]]
}

@test "check-trace: an emphasised line in an LLR body does not detach satisfies:" {
    printf '\n**LLR-002**: Debounce sensor input.\n**Note.** Emphasised body sentence.\nsatisfies: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all llr-bold
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"UNSATISFIED-LLR LLR-002"* ]]
}

# The two boundaries the rule must KEEP. Both pass before this change and must
# still pass after it: widening "any bold line" to "any definition form" must
# not widen it to "nothing at all".

@test "check-trace: another prefix's definition closes an item block" {
    printf '\n**LLR-002**: Debounce sensor input.\n**SDD-002**: Logging module. traces: REQ-001\nsatisfies: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all cross-prefix
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
}

@test "check-trace: a markdown heading closes an item block" {
    printf '\n**LLR-002**: Debounce sensor input.\n\n## Notes\nsatisfies: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all heading-closes
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
}

# --- a definition form it cannot read still closes the block above it ------
# Blocks end at a definition FORM now, not at any bold line. Were that form the
# strict one on both sides, a malformed definition (`**PR-abcdef**:`) would be
# ordinary body text: it would not close the item above it, and the annotations
# below it would be credited to THAT item. The old rule merely dropped them.
# So the closing side matches the loose form and the opening side the strict
# one — an unreadable header ends an item without starting one.

@test "check-trace: an unreadable definition form still closes the block above" {
    printf '**PR-001**: Crash on empty input.\naffects: REQ-001\nstatus: resolved\n**PR-abcdef**: Hand-typed ID with no digit.\nstatus: open\n' > docs/problems/0001-01-01-base.md
    commit_all malformed-closes
    run sh .guardrails/scripts/check-trace.sh
    # Both halves of the pair, on one fixture. The block rule stops the
    # `status: open` reaching PR-001, and ORPHAN-ANNOTATION stops it being
    # dropped in silence once it belongs to nothing. Either alone is a defect.
    [[ "$output" != *"UNRESOLVED-PR PR-001"* ]]
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]]
    [ "$status" -eq 1 ]
}

@test "check-trace: an unreadable definition form opens no block of its own" {
    printf '**PR-abcdef**: Hand-typed ID with no digit.\nstatus: open\n' > docs/problems/0001-01-01-base.md
    commit_all malformed-opens-nothing
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" != *"UNRESOLVED-PR"* ]]
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]]
    [ "$status" -eq 1 ]
}

@test "check-trace: an indented definition form is prose, and closes nothing" {
    printf '**PR-001**: Crash on empty input.\naffects: REQ-001\nopened: %s\n  **PR-abcdef**: Grammar example in a ledger README.\nstatus: open\n' "$(days_ago 5)" > docs/problems/0001-01-01-base.md
    commit_all indented-malformed
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"UNRESOLVED-PR PR-001"* ]]
}

# --- ORPHAN-ANNOTATION: an annotation belonging to no item ----------------
# Every termination rule has an outside. An annotation before the first item in
# a file, or under a heading with no item since, belongs to nothing under any
# rule — and until this gate it was discarded without a word, which is the same
# silent shape the block rule above exists to remove.

@test "check-trace: a status: line before the first item is an orphan" {
    printf 'status: open\n\n**PR-001**: Crash on empty input.\naffects: REQ-001\nstatus: resolved\n' > docs/problems/0001-01-01-base.md
    commit_all orphan-status
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]]
    [[ "$output" == *"docs/problems/0001-01-01-base.md:1"* ]]
}

@test "check-trace: a traces: line under a heading is an orphan" {
    printf '\n**SDD-002**: Logging module. traces: REQ-001\n\n## Notes\ntraces: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    commit_all orphan-traces
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]]
    [[ "$output" == *"traces:"* ]]
}

@test "check-trace: a satisfies: line before the first REQ is an orphan" {
    printf 'satisfies: derived\n\n**REQ-002**: The software shall log all doses.\n' > docs/requirements/2026-01-01-x.md
    printf '# verifies: REQ-002\ntrue\n' > tests/test_c.sh
    commit_all orphan-satisfies
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]]
}

@test "check-trace: an annotation inside its own item is not an orphan" {
    printf '**PR-001**: Crash on empty input.\naffects: REQ-001\nopened: %s\nstatus: open\n' "$(days_ago 5)" > docs/problems/0001-01-01-base.md
    commit_all attributed
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"ORPHAN-ANNOTATION"* ]]
    [[ "$output" == *"UNRESOLVED-PR PR-001"* ]]
}

@test "check-trace: an indented annotation in a grammar comment is not an orphan" {
    # The shape templates/problems.md ships: the item grammar inside an HTML
    # comment, indented. Column-one anchoring is what keeps it inert, and is
    # what makes this gate cheap enough to adopt without editing every ledger.
    printf '<!--\n  **PR-NNNNNN**: <symptom>.\n  status: open|resolved\n-->\n\n**PR-001**: Crash.\nstatus: resolved\n' > docs/problems/0001-01-01-base.md
    commit_all grammar-comment
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"ORPHAN-ANNOTATION"* ]]
}

@test "check-trace: a status: line in the requirements ledger is out of scope" {
    # Per-keyword scope: status: is block-parsed only in doc_problems. Reporting
    # it from a document no gate reads it in would be noise, and noise is what
    # trains people to read past the output.
    printf '\nstatus: open\n' >> docs/requirements/0001-01-01-base.md
    commit_all out-of-scope
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"ORPHAN-ANNOTATION"* ]]
}

@test "poisoning GR_AWK_ITEM_BLOCK changes every block gate's verdict" {
    # The behavioural pin for the shared block rule, and the companion to
    # "poisoning gr_def_re" and "widening GR_ID_BODY". A textual count of
    # interpolation sites is defeated by a copy spelled differently — that
    # happened three rounds running to the gr_def_re pin — so make the shared
    # definition inert instead and require all five consumers to go quiet.
    #
    # Reassigning at the END of lib.sh wins by shell rules, so every consumer
    # that really reads the library's fragment is poisoned. One that carries its
    # own copy of "where does an item end" keeps working, which is the failure
    # this catches. The orphan gate moves the OTHER way — with no block ever
    # open, every annotation belongs to nothing — so a fifth copy is caught by
    # its silence where the first four are caught by their noise.
    printf '**PR-001**: Crash on empty input.\nstatus: open\n' \
        > docs/problems/0001-01-01-base.md
    printf '\n**SDD-002**: Logging module.\n' >> docs/architecture/0001-01-01-base.md
    printf '\n**LLR-002**: Debounce sensor input.\n' >> docs/architecture/0001-01-01-base.md
    printf '\n**REQ-002**: The software shall retry the bus handshake.\nsatisfies: derived\n' \
        >> docs/requirements/0001-01-01-base.md
    printf '# verifies: LLR-002 REQ-002\ntrue\n' > tests/test_b.sh
    commit_all block-poison-fixture

    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "baseline wrong: $output"; false; }
    [[ "$output" == *"UNTRACED-DESIGN SDD-002"* ]] \
        || { echo "baseline wrong: $output"; false; }
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]] \
        || { echo "baseline wrong: $output"; false; }
    [[ "$output" == *"UNANALYZED-DERIVED REQ-002"* ]] \
        || { echo "baseline wrong: $output"; false; }
    [[ "$output" == *"UNRESOLVED-PR PR-001"* ]] \
        || { echo "baseline wrong: $output"; false; }
    [[ "$output" != *"ORPHAN-ANNOTATION"* ]] \
        || { echo "baseline wrong: $output"; false; }

    cat >> .guardrails/scripts/lib.sh <<'POISON'

GR_AWK_ITEM_BLOCK='
function gr_block_init(pfx_open, body) { }
function gr_block_opens(line) { return 0 }
function gr_block_closes(line) { return 0 }
function gr_block_id(line) { return "ZZ-NO-SUCH-ITEM-ZZ" }
function gr_kw_here(line, kw) { return 1 }
function gr_value(line, kw,   v) {
    v = substr(line, length(kw) + 1)
    sub(/^[ \t]+/, "", v)
    sub(/[ \t]+$/, "", v)
    return v
}
'
POISON

    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" != *"UNTRACED-DESIGN"* ]] \
        || { echo "the SDD parser kept its own block rule: $output"; false; }
    [[ "$output" != *"UNSATISFIED-LLR"* ]] \
        || { echo "the LLR parser kept its own block rule: $output"; false; }
    [[ "$output" != *"UNANALYZED-DERIVED"* ]] \
        || { echo "the derived scan kept its own block rule: $output"; false; }
    [[ "$output" != *"UNRESOLVED-PR"* ]] \
        || { echo "the problem parser kept its own block rule: $output"; false; }
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]] \
        || { echo "the orphan gate kept its own block rule: $output"; false; }
    # gr_kw_here is poisoned to fire on EVERY line, so a gate reading the
    # library reports lines carrying no keyword at all. A faithful stub would
    # let check-trace.sh keep a private `index($0, kw) == 1` with the suite
    # green, which is the drift the whole fragment exists to prevent.
    [[ "$output" == *"(status: belongs to no item)"* ]] \
        || { echo "the orphan gate kept its own keyword rule: $output"; false; }
    [[ "$output" == *"0001-01-01-base.md:1"* ]] \
        || { echo "the orphan gate kept its own keyword rule: $output"; false; }
}

# --- what closes a block: header SHAPE, not the loose definition form ------
# Independent review, 2026-08-23, BLOCKING 2. Closing on the loose definition
# form (`**<declared prefix>-<anything>**:`) is not enough. Three shapes that a
# reader sees as an item header do not match it, so under that rule they became
# body text and handed their annotations to the item ABOVE — a wrong answer, and
# on the first of them a red-to-green regression against the pre-change rule,
# which closed on any bold line.

@test "check-trace: a header with an undeclared prefix closes the block" {
    printf '\n**LLR-002**: Debounce sensor input.\n\n**ADR-0007**: We debounce in the driver.\nsatisfies: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all undeclared-prefix-header
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
    [ "$status" -eq 1 ]
}

@test "check-trace: a header with the colon inside the bold closes the block" {
    printf '\n**LLR-002**: Debounce sensor input.\n\n**LLR-overflow:** Not a real ID.\nsatisfies: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all colon-inside-header
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
    [ "$status" -eq 1 ]
}

@test "check-trace: a header with a non-ASCII hyphen closes the block" {
    # U+2011 NON-BREAKING HYPHEN. A copy-paste from a word processor, and
    # invisible in review.
    printf '\n**LLR-002**: Debounce sensor input.\n\n**LLR\xe2\x80\x91j3u4w2**: Underflow rule.\nsatisfies: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all nbhyphen-header
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
    [ "$status" -eq 1 ]
}

@test "check-trace: an emphasised sentence with spaces still closes nothing" {
    # The regression guard for the fix above: whitespace inside the bold is what
    # separates emphasis from a header. This is the line from the original bug.
    printf '**PR-001**: Crash on empty dose input.\nopened: %s\n**21 of 35 inverted, 14 not.**\nstatus: open\n' "$(days_ago 5)" > docs/problems/0001-01-01-base.md
    commit_all emphasis-with-spaces
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"UNRESOLVED-PR PR-001"* ]]
}

# --- the backstop must agree with the gates it backs -----------------------
# Independent review, BLOCKING 1. Each gate opens a block on ITS OWN prefix;
# the orphan gate opened on any declared prefix. That leaves three states, not
# two — inside my block, outside every block, and inside SOMEONE ELSE'S block —
# and the third was read by no gate and reported by none.

@test "check-trace: an annotation inside another prefix's block is an orphan" {
    cat > .guardrails/config.yaml <<'CFG'
guardrails_version: 0.2.0
safety_class: B
id_prefixes: REQ HAZ RC SDD LLR PR ADR
doc_srs: docs/requirements
doc_rmf: docs/risk
doc_sad: docs/architecture
doc_soup: docs/architecture/soup.md
doc_problems: docs/problems
strict_paths:
  - src
test_paths:
  - tests
verify_commands:
  - make test
CFG
    printf '\n**ADR-d6p8r5**: Rounding happens in the writer.\n\nsatisfies: derived\n' \
        >> docs/requirements/0001-01-01-base.md
    commit_all cross-prefix-orphan
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]]
    [ "$status" -eq 1 ]
}

@test "check-trace: YAML front matter is not an orphan" {
    printf -- '---\nstatus: draft\ntitle: Problem reports\n---\n\n**PR-001**: Crash.\nstatus: resolved\n' \
        > docs/problems/0001-01-01-base.md
    commit_all front-matter
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"ORPHAN-ANNOTATION"* ]]
}


# --- the close must be everything main closed that carries a colon ---------
# Review round 2. The close set was a strict SUBSET of the pre-change rule for
# every non-definition line, so every shape it missed was a regression, not a
# gap. Three more were found on the first day. The discriminator is the COLON
# adjoining the closing asterisks — the line from the original report carries
# none — and NOT whitespace, which was untested and bought nothing: deleting
# the whitespace exclusion reddened no test and left the reported defect fixed.

@test "check-trace: a bold-italic header closes the block" {
    printf '\n**LLR-002**: Debounce sensor input.\n\n***ADR-0007***: We debounce in the driver.\nsatisfies: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all bold-italic-header
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
    [ "$status" -eq 1 ]
}

@test "check-trace: a header with a space before its colon closes the block" {
    printf '\n**LLR-002**: Debounce sensor input.\n\n**ADR-0007** : We debounce in the driver.\nsatisfies: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all space-before-colon
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
    [ "$status" -eq 1 ]
}

@test "check-trace: a multi-word bold header closes the block" {
    # A header can be a phrase and emphasis can be one token, so whitespace
    # never separated them. An earlier round excluded whitespace from the bold
    # run and lost this shape.
    printf '\n**LLR-002**: Debounce sensor input.\n\n**Decision 7**: We debounce in the driver.\nsatisfies: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all multiword-header
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
    [ "$status" -eq 1 ]
}

@test "check-trace: single-asterisk emphasis closes nothing" {
    # Parity with the pre-change rule, which required two asterisks at line
    # start. Widening to one would newly reject ledgers that always passed.
    printf '**PR-001**: Crash on empty dose input.\nopened: %s\n*Note*: an italic aside.\nstatus: open\n' "$(days_ago 5)" > docs/problems/0001-01-01-base.md
    commit_all single-asterisk
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"UNRESOLVED-PR PR-001"* ]]
}

@test "check-trace: unclosed front matter does not blank the file" {
    # A leading `---` with no terminator — a thematic break, a half-deleted
    # front-matter block — switched the backstop off for the WHOLE file.
    printf -- '---\ntitle: Problem reports\n\nstatus: open\n\n## Notes\nstatus: open\n' > docs/problems/0001-01-01-base.md
    commit_all unclosed-front-matter
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]]
    [ "$status" -eq 1 ]
}

@test "check-trace: doc_srs and doc_sad on one directory is not an orphan" {
    # Overlapping doc_* paths: the LLR gate reads the satisfies: correctly, so
    # reporting the same line as an orphan is a false positive.
    cat > .guardrails/config.yaml <<'CFG'
guardrails_version: 0.2.0
safety_class: B
id_prefixes: REQ HAZ RC SDD LLR PR
doc_srs: docs/architecture
doc_rmf: docs/risk
doc_sad: docs/architecture
doc_soup: docs/architecture/soup.md
doc_problems: docs/problems
strict_paths:
  - src
test_paths:
  - tests
verify_commands:
  - make test
CFG
    cat > docs/architecture/0001-01-01-base.md <<'SAD'
# Software Architecture

**REQ-001**: The system shall limit the dose. (implements: RC-001)

**SDD-001**: Dose limiter module. traces: REQ-001

**LLR-001**: Clamp requested dose to the configured maximum.
satisfies: REQ-001
SAD
    rm -f docs/requirements/0001-01-01-base.md
    commit_all overlapping-doc-paths
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" != *"ORPHAN-ANNOTATION"* ]]
    [ "$status" -eq 0 ]
}

@test "check-trace: a mid-file thematic break is not front matter" {
    # Only line 1 may open front matter. Without that anchor a `---` rule
    # anywhere in the document starts a skip region and swallows every
    # annotation up to the next one.
    printf '# Problems\n\n---\n\nstatus: open\n\n---\n\n**PR-001**: Crash.\nstatus: resolved\n' > docs/problems/0001-01-01-base.md
    commit_all thematic-break
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]]
    [[ "$output" == *"0001-01-01-base.md:5"* ]]
    [ "$status" -eq 1 ]
}

# --- the close is EVERY bold line carrying a colon -------------------------
# Review round 3. Rounds 1-3 each hand-fitted the pattern to the shapes the
# previous round demonstrated, and each time the class stayed open. The suite
# could not tell the shipped regex from the rule it claimed to implement:
# substituting `^\*\*.*:` reddened nothing, and every difference between them
# was a regression. These fixtures are that difference, made visible.

@test "check-trace: a header with text between the bold and the colon closes" {
    printf '**PR-001**: Crash on empty dose input.\nstatus: resolved\n\n**PR-b4m8p3** (duplicate of PR-001):\nstatus: open\n' > docs/problems/0001-01-01-base.md
    commit_all trailing-text-header
    run sh .guardrails/scripts/check-trace.sh
    # It closes PR-001 and opens NOTHING: the opening form requires the colon
    # immediately after the bold, so this is not a definition. Asserting only
    # the absence of PR-001 was too weak — an opening pattern that dropped its
    # colon reported `UNRESOLVED-PR PR-b4m8p3** (duplicate of PR-001):` and
    # passed.
    [[ "$output" != *"UNRESOLVED-PR"* ]]
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]]
    [ "$status" -eq 1 ]
}

@test "check-trace: a header with nested emphasis closes the block" {
    printf '\n**LLR-002**: Debounce sensor input.\n\n**Note **bold** here**: an aside.\nsatisfies: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all nested-emphasis-header
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
}

@test "check-trace: a header with an interior colon closes the block" {
    printf '\n**LLR-002**: Debounce sensor input.\n\n**Decision: seven revisited**\nsatisfies: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all interior-colon-header
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
}

@test "check-trace: a header with a non-ASCII space before its colon closes" {
    # U+00A0 NO-BREAK SPACE. The same family as the U+2011 hyphen from round 1:
    # an ASCII-only character class is a vocabulary, and the close must not
    # depend on one.
    printf '\n**LLR-002**: Debounce sensor input.\n\n**ADR-0007**\xc2\xa0: superseded.\nsatisfies: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all nbsp-before-colon
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
}

@test "check-trace: an empty bold label with a colon closes the block" {
    printf '\n**LLR-002**: Debounce sensor input.\n\n****:\nsatisfies: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all empty-bold-header
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
}

@test "check-trace: front matter closed by ... is skipped" {
    printf -- '---\nstatus: draft\n...\n\n**PR-001**: Crash.\nstatus: resolved\n' > docs/problems/0001-01-01-base.md
    commit_all dots-terminator
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"ORPHAN-ANNOTATION"* ]]
}

@test "check-trace: CRLF front matter is skipped" {
    printf -- '---\r\nstatus: draft\r\n---\r\n\r\n**PR-001**: Crash.\r\nstatus: resolved\r\n' > docs/problems/0001-01-01-base.md
    commit_all crlf-front-matter
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"ORPHAN-ANNOTATION"* ]]
}

@test "check-trace: the status: backstop opens on PR and no other prefix" {
    # Round 1's per-keyword scoping was pinned only for satisfies:. An SDD
    # header in the problems ledger must not open a block the status: backstop
    # honours — if it did, the annotation under it would be read by nobody and
    # reported by nobody, which is the whole defect.
    printf '**SDD-e7q9s6**: Misfiled design item.\nstatus: open\n' > docs/problems/0001-01-01-base.md
    commit_all status-opens-on-pr-only
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]]
    [ "$status" -eq 1 ]
}

@test "check-trace: an overlapping doc_* reports an orphan once, not twice" {
    cat > .guardrails/config.yaml <<'CFG'
guardrails_version: 0.2.0
safety_class: B
id_prefixes: REQ HAZ RC SDD LLR PR
doc_srs: docs/architecture
doc_rmf: docs/risk
doc_sad: docs/architecture
doc_soup: docs/architecture/soup.md
doc_problems: docs/problems
strict_paths:
  - src
test_paths:
  - tests
verify_commands:
  - make test
CFG
    cat > docs/architecture/0001-01-01-base.md <<'SAD'
# Software Architecture

**REQ-001**: The system shall limit the dose. (implements: RC-001)

**SDD-001**: Dose limiter module. traces: REQ-001

**LLR-001**: Clamp requested dose. satisfies: REQ-001

## Notes

satisfies: REQ-001
SAD
    rm -f docs/requirements/0001-01-01-base.md
    commit_all overlap-single-report
    run sh .guardrails/scripts/check-trace.sh
    n=$(printf '%s\n' "$output" | grep -c 'ORPHAN-ANNOTATION')
    [ "$n" -eq 1 ] || { echo "expected 1 orphan report, got $n: $output"; false; }
}

@test "check-trace: a header whose label is not valid UTF-8 still closes" {
    # `.` in a regex does not match an invalid byte sequence under gawk in a
    # multibyte locale, so a latin-1 ledger — `**Détail**:` saved as cp1252 —
    # stopped closing, and the verdict depended on which awk and which locale
    # the operator had. The close is byte-wise for that reason.
    printf '\n**SDD-002**: Audit logger.\n\n**D\xe9tail**:\ntraces: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    commit_all latin1-header
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"UNTRACED-DESIGN SDD-002"* ]]
    [ "$status" -eq 1 ]
}

@test "check-trace: an H1 heading closes an item block" {
    # Every other heading fixture uses `##`, so narrowing the rule to `^##`
    # passed the whole suite.
    printf '\n**SDD-002**: Audit logger.\n\n# Appendix\ntraces: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    commit_all h1-closes
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"UNTRACED-DESIGN SDD-002"* ]]
    [ "$status" -eq 1 ]
}

@test "check-trace: a definition form mid-line opens no block" {
    printf '**PR-001**: Crash on empty dose input.\n\n# Notes\n\nsee **PR-b4m8p3**: for the duplicate\nstatus: open\n' > docs/problems/0001-01-01-base.md
    commit_all midline-def
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]]
    [[ "$output" != *"UNRESOLVED-PR"* ]]
    [ "$status" -eq 1 ]
}

@test "check-trace: an unreadable problems ledger fails the run rather than finding nothing" {
    # A scan that errors finds nothing, and finding nothing is what a clean
    # ledger looks like. check-ids.sh checks git grep's status for this reason;
    # this gate shells out to awk and must do the same.
    #
    # The problems ledger is now read TWICE — by the triage scan and then by
    # the orphan backstop — and the triage scan gets there first, so the
    # message names it. The backstop's own error path is pinned by the SAD
    # test below, on a file the triage scan never opens. Asserting only the
    # message that happens to come first would have left it uncovered.
    printf '**PR-001**: Crash.\nstatus: open\n' > docs/problems/0001-01-01-base.md
    commit_all unreadable-ledger
    chmod 000 docs/problems/0001-01-01-base.md
    run sh .guardrails/scripts/check-trace.sh
    chmod 644 docs/problems/0001-01-01-base.md
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    [[ "$output" == *"problem-report scan failed"* ]] || { echo "$output"; false; }
}

@test "check-trace: an unreadable architecture ledger fails the orphan scan" {
    # The orphan backstop's half of the pair above. doc_sad is read by
    # check_orphans and by nothing else that opens the working-tree file, so
    # this is the only fixture in which its error path is reachable.
    chmod 000 docs/architecture/0001-01-01-base.md
    run sh .guardrails/scripts/check-trace.sh
    chmod 644 docs/architecture/0001-01-01-base.md
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    [[ "$output" == *"orphan scan failed"* ]] || { echo "$output"; false; }
}

@test "check-trace: a UTF-8 BOM does not defeat the front-matter skip" {
    # lib.sh already knows a BOM makes a column-one scan miss its first line —
    # gr_check_config rejects one in config.yaml for exactly that reason. The
    # lesson had not been carried across, so a BOM turned a title-page
    # `status: draft` into a hard failure on a correct ledger.
    printf '\xef\xbb\xbf---\nstatus: draft\n---\n\n**PR-001**: Crash.\nstatus: resolved\n' > docs/problems/0001-01-01-base.md
    commit_all bom-front-matter
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"ORPHAN-ANNOTATION"* ]]
}

@test "check-trace: a definition form inside a closing line opens no block" {
    # gr_block_opens is consulted only on lines that CLOSE, so an unanchored
    # opening pattern is invisible unless the closing line also carries a
    # definition form somewhere in it. This is that line.
    printf '**PR-001**: Crash on empty dose input.\nstatus: resolved\n\n**Note**: see **PR-b4m8p3**: for the duplicate\nstatus: open\n' > docs/problems/0001-01-01-base.md
    commit_all def-inside-closing-line
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" != *"UNRESOLVED-PR"* ]]
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]]
    [ "$status" -eq 1 ]
}

@test "check-trace: the traces: backstop opens on SDD and no other prefix" {
    # The companion to the status:/PR pin. A `traces:` line inside an LLR block
    # is read by nobody — UNTRACED-DESIGN parses SDD blocks — so it must be
    # reported. This is the ORPHAN-ANNOTATION case most likely to reach a real
    # ledger, and it was pinned for status: and satisfies: but not for traces:.
    printf '\n**LLR-002**: Debounce sensor input. satisfies: REQ-001\ntraces: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all traces-opens-on-sdd-only
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]]
    [[ "$output" == *"traces:"* ]]
    [ "$status" -eq 1 ]
}

@test "poisoning GR_AWK_FRONT_MATTER changes the orphan scan's verdict" {
    # The behavioural pin for the shared front-matter rule, the companion to
    # "poisoning GR_AWK_ITEM_BLOCK". check-review.sh needs the identical rule
    # for the identical reason — a `reviewer:` key in a header block must not
    # satisfy a required field — and two copies of one rule is what the
    # 2026-08-22 change was about.
    #
    # A textual pin cannot tell a shared fragment from a copy of one, so make
    # the shared definition inert and require the consumer to change its
    # answer. Stubbed so that NOTHING is ever front matter: the `status: open`
    # in the header block below then belongs to no item and must be reported.
    # A private copy in check-trace.sh keeps skipping it, stays silent, and the
    # test reddens.
    printf -- '---\nstatus: open\ntitle: Problem reports\n---\n\n**PR-001**: Crash.\nstatus: resolved\n' \
        > docs/problems/0001-01-01-base.md
    commit_all front-matter-poison-fixture

    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "baseline wrong: $output"; false; }
    [[ "$output" != *"ORPHAN-ANNOTATION"* ]] \
        || { echo "baseline wrong: $output"; false; }

    cat >> .guardrails/scripts/lib.sh <<'POISON'

GR_AWK_FRONT_MATTER='
function gr_fm_reset() { }
function gr_fm_scan(line, n) { }
function gr_fm_skip(n) { return 0 }
'
POISON

    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]] \
        || { echo "the orphan scan kept its own front-matter rule: $output"; false; }
}

# --- Problem-report triage: practice-feedback finding 09a -------------------
# The roll-call has to be complete before it is worth pricing higher. These
# pin the reader; the limits that act on it are further down.

@test "check-trace: an item with no status: line is reported, not read as resolved" {
    # verifies: practice-feedback finding 09a (D1)
    # Measured on sightings-app: one item of 159 (PR-028) records its state in
    # prose bullets and carries no status: line. Every gate run since it was
    # written has read it as resolved.
    printf '**PR-001**: Crash on empty dose input.\naffects: REQ-001\n' \
        > docs/problems/0001-01-01-base.md
    commit_all no-status
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"INCOMPLETE-PROBLEM PR-001"* ]] || { echo "$output"; false; }
    [[ "$output" == *"status:"* ]]
}

@test "check-trace: an indented status: line no longer states an item's status" {
    # verifies: practice-feedback finding 09a (D1)
    # Column one, so that the reader and the ORPHAN-ANNOTATION backstop look in
    # the same place. Silently dropping the line would be the same false green
    # moved one step; it becomes INCOMPLETE-PROBLEM instead.
    #
    # The item is otherwise COMPLETE on purpose. The first version left out
    # opened: as well, so INCOMPLETE-PROBLEM fired whatever the
    # status rule did and the test passed without constraining it — a mutation
    # restoring the old anywhere-on-the-line reader survived it untouched.
    # Here only the status rule can decide the verdict.
    printf '**PR-001**: Crash on empty dose input.\nopened: %s\n  status: open\n' "$(days_ago 5)" \
        > docs/problems/0001-01-01-base.md
    commit_all indented-status
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"INCOMPLETE-PROBLEM PR-001 (no status: line in its block)"* ]] \
        || { echo "$output"; false; }
    [[ "$output" != *"UNRESOLVED-PR PR-001"* ]] || { echo "read the indented line: $output"; false; }
}

@test "check-trace: a status: value outside the closed set is malformed" {
    # verifies: practice-feedback finding 09a (D1)
    printf '**PR-001**: Crash.\nstatus: openish\n' > docs/problems/0001-01-01-base.md
    commit_all bad-status
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MALFORMED-STATUS PR-001"* ]] || { echo "$output"; false; }
    [[ "$output" != *"UNRESOLVED-PR PR-001"* ]] || { echo "counted as open: $output"; false; }
}

@test "check-trace: a capitalised Status: does not state an item's status" {
    # verifies: practice-feedback finding 09a (D1)
    # The old pattern matched `status:` only, so `Status: open` left the item
    # reading as resolved. It is now an omission, which is loud.
    # Complete but for the status, so that only the status rule decides — see
    # the indented-status test above for why that matters.
    printf '**PR-001**: Crash.\nopened: %s\nStatus: open\n' "$(days_ago 5)" \
        > docs/problems/0001-01-01-base.md
    commit_all capital-status
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"INCOMPLETE-PROBLEM PR-001 (no status: line in its block)"* ]] \
        || { echo "$output"; false; }
}

@test "check-trace: the first status: in a block wins" {
    # verifies: practice-feedback finding 09a (D1)
    # The GR_AWK_ID_RUN rule, applied to a scalar annotation: a later line
    # cannot reopen or close an item the first line already stated.
    printf '**PR-001**: Crash.\nstatus: resolved\nstatus: open\n' \
        > docs/problems/0001-01-01-base.md
    commit_all two-status
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [[ "$output" != *"UNRESOLVED-PR PR-001"* ]] || { echo "$output"; false; }
}

@test "check-trace: an open item needs no owner:" {
    # verifies: PR-dudg35
    # Authorship is already answered by `git blame` on the ledger line, and
    # problems are not personally owned — anyone may resolve them. `opened:`
    # and `status:` are the whole grammar for an open item.
    printf '**PR-001**: Crash.\nopened: %s\nstatus: open\n' "$(days_ago 2)" \
        > docs/problems/0001-01-01-base.md
    commit_all no-owner
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"INCOMPLETE-PROBLEM"* ]] || { echo "$output"; false; }
    [[ "$output" == *"UNRESOLVED-PR PR-001 (open 2 days)"* ]] || { echo "$output"; false; }
}

@test "check-trace: a leftover owner: line inside an item is inert" {
    # verifies: PR-dudg35
    # Backward compatibility: ledgers written under the old grammar carry
    # owner: lines, full and empty alike. Both are prose now — the run is
    # the same as if they were absent, and no output mentions them.
    printf '**PR-001**: Crash.\nowner: jvdv\nopened: %s\nstatus: open\n\n**PR-p9r5wx**: Also crash.\nowner:\nopened: %s\nstatus: open\n' "$(days_ago 2)" "$(days_ago 2)" \
        > docs/problems/0001-01-01-base.md
    commit_all leftover-owner
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"UNRESOLVED-PR PR-001 (open 2 days)"* ]] || { echo "$output"; false; }
    [[ "$output" == *"UNRESOLVED-PR PR-p9r5wx (open 2 days)"* ]] || { echo "$output"; false; }
    [[ "$output" != *"owner"* ]] || { echo "owner leaked into the output: $output"; false; }
}

@test "check-trace: an open item with no opened: is still on the roll-call" {
    # verifies: practice-feedback finding 09a (D2)
    # The item cannot be aged, but it is open, and an open item missing from
    # the roll-call is the defect this whole gate exists to remove.
    printf '**PR-001**: Crash.\nstatus: open\n' \
        > docs/problems/0001-01-01-base.md
    commit_all no-opened
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"INCOMPLETE-PROBLEM PR-001"* ]] || { echo "$output"; false; }
    [[ "$output" == *"opened:"* ]]
    [[ "$output" == *"UNRESOLVED-PR PR-001"* ]] || { echo "dropped from roll-call: $output"; false; }
}

@test "check-trace: a resolved item needs no opened:" {
    # verifies: practice-feedback finding 09a (D3), PR-dudg35
    # The backfill this change asks of an existing ledger is bounded to the
    # items that are still open.
    printf '**PR-001**: Crash.\nstatus: resolved\n' > docs/problems/0001-01-01-base.md
    commit_all resolved-bare
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
}

@test "check-trace: a complete open item passes and reports its age" {
    # verifies: practice-feedback finding 09a (D2, task 4), PR-dudg35
    write_pr PR-001 open "$(days_ago 10)"
    commit_all complete-open
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [[ "$output" == *"UNRESOLVED-PR PR-001 (open 10 days)"* ]] \
        || { echo "$output"; false; }
}

@test "check-trace: an opened: that is not a calendar date is malformed" {
    # verifies: practice-feedback finding 09a (D5)
    #
    # Each input asserts MALFORMED-DATE specifically. The first version allowed
    # `MALFORMED-DATE || INCOMPLETE-PROBLEM (no opened:)` so that the empty
    # value could share the loop — a disjunction no input could distinguish,
    # which left the empty-value rule unpinned on all eight. The independent
    # review's mutation of that rule survived the whole suite. The empty value
    # now has its own test below.
    #
    # 2026-00-10 and 2026-08-00 are here because a zero component is a
    # plausible typo and the calendar test is the only thing that rejects it:
    # a mutation dropping the `m < 1 || d < 1` half of gr_date_valid survived
    # the list without them.
    for bad in 2026-13-01 2026-02-30 2023-02-29 2026-00-10 2026-08-00 24-08-01 2026-08-1 2026-1a-01 yesterday 2026/08/01; do
        printf '**PR-001**: Crash.\nopened: %s\nstatus: open\n' "$bad" \
            > docs/problems/0001-01-01-base.md
        commit_all "bad-date"
        run sh .guardrails/scripts/check-trace.sh
        [ "$status" -eq 1 ] || { echo "accepted '$bad': $output"; false; }
        [[ "$output" == *"MALFORMED-DATE PR-001"* ]] \
            || { echo "'$bad' was not reported malformed: $output"; false; }
    done
}

@test "check-trace: an empty opened: is an omission, not a date" {
    # verifies: practice-feedback finding 09a (D2)
    # A keyword with nothing after it declares nothing. This rule had no
    # test of its own at first, and the review found it unpinned.
    printf '**PR-001**: Crash.\nopened:\nstatus: open\n' \
        > docs/problems/0001-01-01-base.md
    commit_all empty-opened
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"INCOMPLETE-PROBLEM PR-001 (open, no opened:)"* ]] || { echo "$output"; false; }
    [[ "$output" != *"MALFORMED-DATE"* ]] || { echo "reported as a bad date: $output"; false; }
}

@test "check-trace: a leap day is a calendar date and a non-leap century day is not" {
    # verifies: practice-feedback finding 09a (D5)
    # Hand-rolled date arithmetic is wrong in February or it is not wrong at all.
    printf '**PR-001**: Crash.\nopened: 2024-02-29\nstatus: open\n' \
        > docs/problems/0001-01-01-base.md
    commit_all leap-ok
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "rejected a real leap day: $output"; false; }

    # 1900 is divisible by 4 and by 100 but not by 400 — not a leap year, and
    # the century rule is the half of the calendar a naive `% 4` gets wrong.
    #
    # 1900, and not 2100, deliberately. The first version used 2100, which is
    # in the FUTURE: dropping the century rule made the date valid, the future
    # rule then reported MALFORMED-DATE anyway, and the test passed while
    # constraining nothing — a mutation removing the century rule survived it.
    # A past date leaves only the calendar rule able to reject it.
    printf '**PR-001**: Crash.\nopened: 1900-02-29\nstatus: open\n' \
        > docs/problems/0001-01-01-base.md
    commit_all leap-century
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "accepted 1900-02-29: $output"; false; }
    [[ "$output" == *"MALFORMED-DATE PR-001"* ]] || { echo "$output"; false; }
    [[ "$output" == *"not a YYYY-MM-DD calendar date"* ]] \
        || { echo "rejected for the wrong reason: $output"; false; }
}

@test "check-trace: an opened: date in the future is rejected, not treated as young" {
    # verifies: practice-feedback finding 09a (D4, amended)
    # A future date yields a negative age, which compares as younger than any
    # limit — the false-green direction, so it fails rather than clamping.
    # AMENDED by the independent review: one day of tolerance, because that is
    # the width of a timezone disagreement about "today". This test now uses
    # two days; the boundary itself is pinned by `an opened: one day ahead is
    # clock skew, further is an error`.
    printf '**PR-001**: Crash.\nopened: %s\nstatus: open\n' "$(days_ago -2)" \
        > docs/problems/0001-01-01-base.md
    commit_all future-date
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"MALFORMED-DATE PR-001"* ]] || { echo "$output"; false; }
    [[ "$output" == *"future"* ]]
}

@test "check-trace: an item opened today is zero days old, not a day either way" {
    # verifies: practice-feedback finding 09a (D4), PR-dudg35
    printf '**PR-001**: Crash.\nopened: %s\nstatus: open\n' "$(days_ago 0)" \
        > docs/problems/0001-01-01-base.md
    commit_all opened-today
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"(open 0 days)"* ]] || { echo "$output"; false; }
}

@test "check-trace: problem_age_days fails an item older than the limit" {
    # verifies: practice-feedback finding 09a (D6)
    printf 'problem_age_days: 30\n' >> .guardrails/config.yaml
    printf '**PR-001**: Crash.\nopened: %s\nstatus: open\n' "$(days_ago 31)" \
        > docs/problems/0001-01-01-base.md
    commit_all stale
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"STALE-PROBLEM PR-001 (open 31 days, limit 30)"* ]] || { echo "$output"; false; }
}

@test "check-trace: problem_age_days passes an item exactly at the limit" {
    # verifies: practice-feedback finding 09a (D6)
    # The limit is "more than", stated once here so it cannot drift.
    printf 'problem_age_days: 30\n' >> .guardrails/config.yaml
    printf '**PR-001**: Crash.\nopened: %s\nstatus: open\n' "$(days_ago 30)" \
        > docs/problems/0001-01-01-base.md
    commit_all at-limit
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"STALE-PROBLEM"* ]]
}

@test "check-trace: problem_open_max fails a backlog past the limit" {
    # verifies: practice-feedback finding 09a (D6)
    printf 'problem_open_max: 2\n' >> .guardrails/config.yaml
    write_pr PR-001 open "$(days_ago 1)"
    write_pr PR-p9r5wx open "$(days_ago 1)"
    write_pr PR-b4m8p3 open "$(days_ago 1)"
    commit_all backlog
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"PROBLEM-BACKLOG (3 open problem reports, limit 2)"* ]] || { echo "$output"; false; }
}

@test "check-trace: problem_open_max passes a backlog exactly at the limit" {
    # verifies: practice-feedback finding 09a (D6)
    printf 'problem_open_max: 2\n' >> .guardrails/config.yaml
    write_pr PR-001 open "$(days_ago 1)"
    write_pr PR-p9r5wx open "$(days_ago 1)"
    commit_all backlog-at-limit
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"PROBLEM-BACKLOG"* ]]
}

@test "check-trace: the backlog count spans every ledger file, not one at a time" {
    # verifies: practice-feedback finding 09a (D6)
    # The scan runs per file; the limit is a property of the ledger.
    printf 'problem_open_max: 1\n' >> .guardrails/config.yaml
    write_pr PR-001 open "$(days_ago 1)"
    printf '**PR-p9r5wx**: Another.\nopened: %s\nstatus: open\n' "$(days_ago 1)" \
        > docs/problems/2026-01-02-second.md
    commit_all backlog-two-files
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"PROBLEM-BACKLOG (2 open problem reports, limit 1)"* ]] || { echo "$output"; false; }
}

@test "check-trace: an unparseable limit is an environment error, not no limit" {
    # verifies: practice-feedback finding 09a (D6)
    # A limit the reader cannot see reads as "no limit" through cfg_get — a
    # gate disabling itself on a typo, which is the whole shape gr_check_config
    # exists to reject.
    for bad in thirty -1 1.5 "30 days" ""; do
        cp .guardrails/config.yaml .guardrails/config.yaml.bak
        printf 'problem_age_days: %s\n' "$bad" >> .guardrails/config.yaml
        run sh .guardrails/scripts/check-trace.sh
        cp .guardrails/config.yaml.bak .guardrails/config.yaml
        [ "$status" -eq 2 ] || { echo "accepted '$bad': status $status: $output"; false; }
    done
    rm -f .guardrails/config.yaml.bak
}

@test "check-trace: problem_age_days 0 is a limit, not an absent one" {
    # verifies: practice-feedback finding 09a (D6)
    # Zero and unset are distinguishable and must stay so: cfg_get returns the
    # empty string for both a missing key and an empty value, which is exactly
    # how a configured limit would vanish.
    printf 'problem_age_days: 0\n' >> .guardrails/config.yaml
    printf '**PR-001**: Crash.\nopened: %s\nstatus: open\n' "$(days_ago 1)" \
        > docs/problems/0001-01-01-base.md
    commit_all zero-limit
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"STALE-PROBLEM PR-001 (open 1 days, limit 0)"* ]] || { echo "$output"; false; }
}

@test "check-trace: the summary states the limits, set or not, on pass and on failure" {
    # verifies: practice-feedback finding 09a (D6)
    # An unset limit is a legitimate configuration and never a silent one.
    write_pr PR-001 open "$(days_ago 7)"
    commit_all summary-unset
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"problems: open 1, oldest 7 days; limits age none, open none"* ]] \
        || { echo "$output"; false; }

    printf 'problem_age_days: 3\nproblem_open_max: 9\n' >> .guardrails/config.yaml
    commit_all summary-set
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"problems: open 1, oldest 7 days; limits age 3, open 9"* ]] \
        || { echo "$output"; false; }
}

@test "check-trace: the summary reports no open problems as none, not as zero days" {
    # verifies: practice-feedback finding 09a (D6)
    printf '**PR-001**: Crash.\nstatus: resolved\n' > docs/problems/0001-01-01-base.md
    commit_all summary-empty
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"problems: open 0, oldest n/a;"* ]] || { echo "$output"; false; }
}

@test "check-trace: an undatable open item counts toward the backlog limit" {
    # verifies: practice-feedback finding 09a (D2, D6)
    # It is already failing for the missing field. It must not ALSO be missing
    # from the count, or a ledger could hold its backlog down by omission.
    printf 'problem_open_max: 1\n' >> .guardrails/config.yaml
    write_pr PR-001 open "$(days_ago 1)"
    printf '**PR-p9r5wx**: Undated.\nstatus: open\n' \
        > docs/problems/2026-01-02-second.md
    commit_all undatable-counts
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"PROBLEM-BACKLOG (2 open problem reports, limit 1)"* ]] || { echo "$output"; false; }
}

@test "check-trace: an owner: outside any item is inert, not an orphan" {
    # verifies: PR-dudg35
    # The backstop covers what the reader reads, and the reader no longer
    # reads owner: — a leftover line outside any item is prose, like any
    # other word the grammar does not know.
    printf 'owner: jvdv\n\n**PR-001**: Crash.\nstatus: resolved\n' \
        > docs/problems/0001-01-01-base.md
    commit_all leftover-owner-outside
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"ORPHAN-ANNOTATION"* ]] || { echo "$output"; false; }
}

@test "check-trace: an opened: belonging to no item is an orphan" {
    # verifies: practice-feedback finding 09a (D8)
    printf '# Notes\n\nopened: 2026-01-01\n\n**PR-001**: Crash.\nstatus: resolved\n' \
        > docs/problems/0001-01-01-base.md
    commit_all orphan-opened
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"(opened: belongs to no item)"* ]] || { echo "$output"; false; }
}

@test "check-trace: an opened: in another ledger is out of scope" {
    # verifies: practice-feedback finding 09a (D8), PR-dudg35
    # Per-keyword scope, as for status:. It is block-parsed only in
    # doc_problems; reporting it from the SRS, where nothing reads it,
    # would be noise, and noise is what teaches people to read past the output.
    printf '\nopened: 2026-01-01\n' >> docs/requirements/0001-01-01-base.md
    commit_all opened-in-srs
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"ORPHAN-ANNOTATION"* ]]
}

@test "check-trace: an indented opened: in a grammar comment is not an orphan" {
    # verifies: practice-feedback finding 09a (D8), PR-dudg35
    # Column one, like every definition form here — which is what keeps the
    # grammar comment shipped in templates/problems.md inert.
    printf '<!--\n  **PR-NNNNNN**: <symptom>.\n  opened: YYYY-MM-DD\n  status: open|resolved\n-->\n\n**PR-001**: Crash.\nstatus: resolved\n' \
        > docs/problems/0001-01-01-base.md
    commit_all grammar-comment
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"ORPHAN-ANNOTATION"* ]]
}

@test "check-trace: a CRLF ledger states its status like any other" {
    # verifies: practice-feedback finding 09a (D1), PR-dudg35
    # A ledger written on Windows must not read as an item with no status.
    printf '**PR-001**: Crash.\r\nopened: %s\r\nstatus: open\r\n' "$(days_ago 4)" \
        > docs/problems/0001-01-01-base.md
    commit_all crlf-item
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"UNRESOLVED-PR PR-001 (open 4 days)"* ]] || { echo "$output"; false; }
}

@test "check-trace: an indented opened: does not answer for an open item" {
    # verifies: practice-feedback finding 09a (D1, D8), PR-dudg35
    # The other half of the column-one rule. Its companion test proves an
    # indented opened: in a grammar comment is not an ORPHAN; this one proves
    # it is not a FIELD either. Only the pair rules out a grammar comment
    # answering for a real item three lines below it.
    printf '**PR-001**: Crash.\n  opened: %s\nstatus: open\n' "$(days_ago 4)" \
        > docs/problems/0001-01-01-base.md
    commit_all indented-opened
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"INCOMPLETE-PROBLEM PR-001 (open, no opened:)"* ]] || { echo "$output"; false; }
}

@test "check-trace: trailing whitespace on a field is not part of its value" {
    # verifies: practice-feedback finding 09a (D1), PR-dudg35
    # `status: open ` must be open, not a fourth state.
    printf '**PR-001**: Crash.\nopened: %s \nstatus: open \n' "$(days_ago 4)" \
        > docs/problems/0001-01-01-base.md
    commit_all trailing-space
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"UNRESOLVED-PR PR-001 (open 4 days)"* ]] || { echo "$output"; false; }
}

@test "check-trace: the backlog counts open items only" {
    # verifies: practice-feedback finding 09a (D6)
    printf 'problem_open_max: 1\n' >> .guardrails/config.yaml
    write_pr PR-001 open "$(days_ago 1)"
    printf '\n**PR-p9r5wx**: Fixed already.\nstatus: resolved\n\n**PR-b4m8p3**: Also fixed.\nstatus: resolved\n' \
        >> docs/problems/0001-01-01-base.md
    commit_all backlog-open-only
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"problems: open 1,"* ]] || { echo "$output"; false; }
}

@test "check-trace: a date(1) that does not produce a calendar date is an error" {
    # verifies: practice-feedback finding 09a (D5)
    # "Today" is the denominator of every age this gate computes. A garbage
    # value would not fail — it would make every age silently wrong, which is
    # the shape of every other defect in this file.
    write_pr PR-001 open "$(days_ago 4)"
    commit_all date-stub
    mkdir -p "$BATS_TEST_TMPDIR/fakebin"
    printf '#!/bin/sh\necho "Tue 25 Aug 2026"\n' > "$BATS_TEST_TMPDIR/fakebin/date"
    chmod +x "$BATS_TEST_TMPDIR/fakebin/date"
    PATH="$BATS_TEST_TMPDIR/fakebin:$PATH" run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    [[ "$output" == *"not a date in YYYY-MM-DD form"* ]] || { echo "$output"; false; }
}

@test "check-trace: a date(1) that is date-SHAPED but not a real date is an error" {
    # verifies: practice-feedback finding 09a (D5)
    # The shell check tests the shape and the awk guard tests the calendar.
    # Only the pair rejects 2026-13-45, and a mutation that removes just one
    # of them survives — which is why both are exercised here.
    write_pr PR-001 open "$(days_ago 4)"
    commit_all date-stub-shaped
    mkdir -p "$BATS_TEST_TMPDIR/fakebin2"
    printf '#!/bin/sh\necho 2026-13-45\n' > "$BATS_TEST_TMPDIR/fakebin2/date"
    chmod +x "$BATS_TEST_TMPDIR/fakebin2/date"
    PATH="$BATS_TEST_TMPDIR/fakebin2:$PATH" run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    # INDEPENDENT REVIEW, finding 9. The calendar guard used to live in the
    # per-file awk, so a clock problem was announced as `problem-report scan
    # failed on docs/problems/....md` — naming a ledger file for a fault in
    # date(1). Asserting only the exit code did not catch the misdirection.
    [[ "$output" == *"not a calendar date"* ]] || { echo "$output"; false; }
    [[ "$output" != *"scan failed on"* ]] \
        || { echo "a clock fault blamed on a ledger file: $output"; false; }
}

@test "check-trace: a leading --- does not hide the items beneath it" {
    # verifies: practice-feedback finding 09a (D1)
    #
    # INDEPENDENT REVIEW, BLOCKING 1, and this test is the repair of the test
    # that pinned the defect. The triage scan first shipped with a front-matter
    # skip, argued as "the reader and the backstop must read the same bytes".
    # GR_AWK_FRONT_MATTER opens on ANY `---` at line 1, so a leading horizontal
    # rule swallowed every item definition up to the next one: an open problem
    # 236 days old absent from the roll-call, problem_open_max not applied,
    # exit 0 — with `checked: PR 2` printed next to `problems: open 1` and
    # nothing reconciling them.
    #
    # The test that shipped with it asserted the ID appeared NOWHERE in the
    # output, which is true both when the header is correctly ignored and when
    # a real item is swallowed. It could not tell the two apart.
    printf -- '---\n\n# Problem reports\n\n**PR-p9r5wx**: Swallowed.\nopened: 2026-01-01\nstatus: open\n\n---\n\n**PR-001**: Another.\nopened: %s\nstatus: open\n' "$(days_ago 5)" \
        > docs/problems/0001-01-01-base.md
    commit_all leading-rule
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"UNRESOLVED-PR PR-p9r5wx"* ]] \
        || { echo "item hidden by a leading ---: $output"; false; }
    [[ "$output" == *"problems: open 2,"* ]] || { echo "$output"; false; }
}

@test "check-trace: the open count and the item count reconcile" {
    # verifies: practice-feedback finding 09a (D1)
    # The self-contradiction the blocking finding left in the output is itself
    # worth pinning: `checked:` counts the items and `problems:` counts the
    # open ones, and no reading of a ledger where every item is open can make
    # the second smaller than the first.
    printf -- '---\n\n**PR-p9r5wx**: One.\nopened: 2026-01-01\nstatus: open\n\n---\n\n**PR-001**: Two.\nopened: 2026-01-02\nstatus: open\n' \
        > docs/problems/0001-01-01-base.md
    commit_all reconcile
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"PR 2"* ]] || { echo "$output"; false; }
    [[ "$output" == *"problems: open 2,"* ]] \
        || { echo "checked: and problems: disagree: $output"; false; }
}

@test "check-trace: an age spanning February is counted exactly" {
    # verifies: practice-feedback finding 09a (D5), PR-dudg35
    # days_from_civil shifts March to the start of its year so that the leap
    # day falls at the END. Every other test in this file uses a date near
    # today, which is never in January or February, so the shift itself went
    # unexercised — a mutation that applied the March branch to every month
    # survived the whole suite. `date` is stubbed so the arithmetic, not the
    # calendar the tests happen to run on, decides the answer.
    mkdir -p "$BATS_TEST_TMPDIR/febbin"
    printf '#!/bin/sh\necho 2026-03-01\n' > "$BATS_TEST_TMPDIR/febbin/date"
    chmod +x "$BATS_TEST_TMPDIR/febbin/date"
    printf '**PR-001**: Crash.\nopened: 2026-02-01\nstatus: open\n' \
        > docs/problems/0001-01-01-base.md
    commit_all feb-age
    PATH="$BATS_TEST_TMPDIR/febbin:$PATH" run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"(open 28 days)"* ]] || { echo "2026 February: $output"; false; }

    # And the same span across a leap February is one day longer.
    printf '#!/bin/sh\necho 2024-03-01\n' > "$BATS_TEST_TMPDIR/febbin/date"
    printf '**PR-001**: Crash.\nopened: 2024-02-01\nstatus: open\n' \
        > docs/problems/0001-01-01-base.md
    commit_all feb-age-leap
    PATH="$BATS_TEST_TMPDIR/febbin:$PATH" run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"(open 29 days)"* ]] || { echo "2024 February: $output"; false; }

    # A span that crosses the year boundary, where the shift moves the year too.
    printf '#!/bin/sh\necho 2026-01-10\n' > "$BATS_TEST_TMPDIR/febbin/date"
    printf '**PR-001**: Crash.\nopened: 2025-12-31\nstatus: open\n' \
        > docs/problems/0001-01-01-base.md
    commit_all jan-age
    PATH="$BATS_TEST_TMPDIR/febbin:$PATH" run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"(open 10 days)"* ]] || { echo "year boundary: $output"; false; }
}

@test "check-trace: an item opened today is the oldest, not no age at all" {
    # verifies: practice-feedback finding 09a (D6)
    # The running maximum started at awk's uninitialised 0, so an age of 0 —
    # the only age that does not exceed it — never registered, and a ledger
    # whose sole open item was opened today reported `oldest n/a`: an open
    # item present in the count and absent from the age. Found by reading,
    # after the mutation battery had already gone green.
    printf '**PR-001**: Crash.\nopened: %s\nstatus: open\n' "$(days_ago 0)" \
        > docs/problems/0001-01-01-base.md
    commit_all oldest-today
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"problems: open 1, oldest 0 days;"* ]] || { echo "$output"; false; }
}

@test "check-trace: the first opened: in a block wins" {
    # verifies: practice-feedback finding 09a (D1), PR-dudg35
    # The review's mutation making the LAST occurrence win survived the whole
    # suite once. templates/problems.md states the rule, so it was documented
    # and unenforced — the pairing this toolkit exists to end.
    printf '**PR-001**: Crash.\nopened: %s\nopened: 1999-01-01\nstatus: open\n' "$(days_ago 6)" \
        > docs/problems/0001-01-01-base.md
    commit_all first-opened-wins
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"UNRESOLVED-PR PR-001 (open 6 days)"* ]] || { echo "$output"; false; }
}

@test "check-trace: an age spanning a century boundary is counted exactly" {
    # verifies: practice-feedback finding 09a (D5), PR-dudg35
    # days_from_civil's `- int(yoe / 100)` term. Every dated fixture lives in
    # 2024-2026, so the term was never exercised and a mutation deleting it
    # survived: 1999-01-01 to 2001-01-01 is 731 days, and 728 without it. This
    # is a different rule from the leap-CENTURY rule in gr_date_valid.
    mkdir -p "$BATS_TEST_TMPDIR/centbin"
    printf '#!/bin/sh\necho 2001-01-01\n' > "$BATS_TEST_TMPDIR/centbin/date"
    chmod +x "$BATS_TEST_TMPDIR/centbin/date"
    printf '**PR-001**: Crash.\nopened: 1999-01-01\nstatus: open\n' \
        > docs/problems/0001-01-01-base.md
    commit_all century-age
    PATH="$BATS_TEST_TMPDIR/centbin:$PATH" run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"(open 731 days)"* ]] || { echo "$output"; false; }
}

@test "check-trace: a BOM in front of the first item does not hide it" {
    # verifies: practice-feedback finding 09a (D1), PR-dudg35
    # A BOM sits in front of column one and hides it from every match. The
    # strip was carried across from check_orphans and nothing pinned it.
    #
    # It leaves a known divergence, stated rather than hidden: `ids_defined`
    # greps for an anchored definition and does NOT tolerate a BOM, so the
    # item is on the roll-call and absent from `checked:`. Both readings are
    # red — DANGLING-REF fires — and red-and-confusing beats an open problem
    # nobody sees. Making git grep BOM-tolerant is a change to every gate.
    printf '\xef\xbb\xbf**PR-001**: Crash.\nopened: %s\nstatus: open\n' "$(days_ago 6)" \
        > docs/problems/0001-01-01-base.md
    commit_all bom-item
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"UNRESOLVED-PR PR-001 (open 6 days)"* ]] \
        || { echo "BOM hid the item from the roll-call: $output"; false; }
}

@test "check-trace: an opened: one day ahead is clock skew, further is an error" {
    # verifies: practice-feedback finding 09a (D4, amended), PR-dudg35
    # INDEPENDENT REVIEW, finding 2. resolve-problem tells the author to write
    # today, and "today" differs by a day across timezones; without tolerance
    # an author in UTC+13 blocked the merge on a correct item on the day they
    # recorded it. One day cannot make a stale item look fresh against limits
    # measured in weeks.
    printf '**PR-001**: Crash.\nopened: %s\nstatus: open\n' "$(days_ago -1)" \
        > docs/problems/0001-01-01-base.md
    commit_all one-day-ahead
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "one day ahead was refused: $output"; false; }
    [[ "$output" == *"(open 0 days)"* ]] || { echo "$output"; false; }

    printf '**PR-001**: Crash.\nopened: %s\nstatus: open\n' "$(days_ago -2)" \
        > docs/problems/0001-01-01-base.md
    commit_all two-days-ahead
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "two days ahead was accepted: $output"; false; }
    [[ "$output" == *"more than a day in the future"* ]] || { echo "$output"; false; }
}

@test "check-trace: a limit too large to compare is an error, not no limit" {
    # verifies: practice-feedback finding 09a (D6)
    # INDEPENDENT REVIEW, finding 3. Digits alone passed gr_limit, then
    # `[ n -gt limit ]` failed with "Illegal number", the if took its else
    # branch, and the backlog gate was off with the run green.
    printf 'problem_open_max: 99999999999999999999\n' >> .guardrails/config.yaml
    write_pr PR-001 open "$(days_ago 1)"
    commit_all huge-limit
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    [[ "$output" == *"cannot compare as a number"* ]] || { echo "$output"; false; }
}

@test "check-trace: a bad limit is diagnosed before any gate runs" {
    # verifies: practice-feedback finding 09a (D6)
    # INDEPENDENT REVIEW, finding 5. Read at the point of use, a typo in a
    # limit was reported after a page of violations and with every summary
    # line suppressed — the evidence lost to the error.
    printf 'problem_age_days: thirty\n' >> .guardrails/config.yaml
    printf '\nSee REQ-777 for context.\n' >> docs/problems/README.md
    commit_all late-diagnosis
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"problem_age_days must be"* ]] || { echo "$output"; false; }
    [[ "$output" != *"DANGLING-REF"* ]] \
        || { echo "gates ran before the config was settled: $output"; false; }
}

@test "check-trace: the summary counts undated open items apart from the oldest" {
    # verifies: practice-feedback finding 09a (D6)
    # INDEPENDENT REVIEW, finding 10. `oldest` is the oldest DATABLE item, so
    # an undated open item was in the count and invisible in the age.
    write_pr PR-001 open "$(days_ago 3)"
    printf '\n**PR-p9r5wx**: Undated.\nstatus: open\n' \
        >> docs/problems/0001-01-01-base.md
    commit_all undated-summary
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"problems: open 2, oldest 3 days (1 with no usable date);"* ]] \
        || { echo "$output"; false; }
}

@test "check-trace: one open problem report is reported in the singular" {
    # verifies: practice-feedback finding 09a (D6)
    printf 'problem_open_max: 0\n' >> .guardrails/config.yaml
    write_pr PR-001 open "$(days_ago 1)"
    commit_all singular
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"PROBLEM-BACKLOG (1 open problem report, limit 0)"* ]] || { echo "$output"; false; }
}

@test "check-trace: a leading --- does not switch the orphan backstop off either" {
    # verifies: practice-feedback finding 09a (D8)
    #
    # INDEPENDENT REVIEW, second pass, finding N2. The blocking finding was
    # repaired in the READER by removing its front-matter skip; the BACKSTOP
    # still could not tell a header from a horizontal rule, so a leading `---`
    # silently dropped every annotation up to the next one. Pre-existing for
    # `status:`, and this change had newly extended it to `opened:` —
    # the two gates disagreeing about what `---` means, in a change whose whole
    # argument is that they must agree.
    #
    # The bound is on line 2: YAML has no blank line between the opening
    # delimiter and the first key, so `---` followed by a blank line is a rule.
    printf -- '---\n\nstatus: open\nopened: 2026-01-01\n\n---\n\n**PR-001**: Crash.\nstatus: resolved\n' \
        > docs/problems/0001-01-01-base.md
    commit_all leading-rule-backstop
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"(status: belongs to no item)"* ]] || { echo "$output"; false; }
    [[ "$output" == *"(opened: belongs to no item)"* ]] || { echo "$output"; false; }
}

@test "check-trace: real front matter is still skipped by the backstop" {
    # verifies: practice-feedback finding 09a (D8)
    # The other side of the bound above: a header block with a key on line 2
    # is still a header block, and a `status: draft` in it is a title-page
    # field, not an orphan. Without this the fix would trade one false green
    # for a false red on every document that carries front matter.
    printf -- '---\nstatus: draft\nauthor: docs team\ntitle: Problem reports\n---\n\n**PR-001**: Crash.\nstatus: resolved\n' \
        > docs/problems/0001-01-01-base.md
    commit_all real-front-matter-kept
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"ORPHAN-ANNOTATION"* ]] || { echo "$output"; false; }
}

@test "check-trace: a limit at the shell's integer range is accepted" {
    # verifies: practice-feedback finding 09a (D6)
    # INDEPENDENT REVIEW, second pass, N5. The first repair fixed nine digits
    # and refused 1000000000 with the untrue explanation that it was too large
    # to compare. Loosening that constant to eighteen digits survived the whole
    # suite, so the boundary was unpinned in both directions. The rule now asks
    # the shell, and both ends are pinned here.
    printf 'problem_open_max: 1000000000\n' >> .guardrails/config.yaml
    write_pr PR-001 open "$(days_ago 1)"
    commit_all big-but-comparable
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "a comparable limit was refused: $output"; false; }
    [[ "$output" == *"limits age none, open 1000000000"* ]] || { echo "$output"; false; }
}

@test "check-trace: an item with a refused date is counted as having no usable date" {
    # verifies: practice-feedback finding 09a (D6)
    # INDEPENDENT REVIEW, second pass, N6. The count is of items whose age is
    # unknown, which includes a date that was read and REJECTED — not only one
    # that is absent. The word had to become true of both.
    printf '**PR-001**: Crash.\nopened: 2026-13-01\nstatus: open\n' \
        > docs/problems/0001-01-01-base.md
    commit_all refused-date-counted
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"problems: open 1, oldest n/a (1 with no usable date);"* ]] \
        || { echo "$output"; false; }
}
