load helpers

setup() {
    make_fixture_repo
    cat > docs/requirements/srs.md <<'EOF'
# SRS

**REQ-001**: The system shall limit the dose. (implements: RC-001)
EOF
    cat > docs/risk/rmf.md <<'EOF'
# Risk Management File

**HAZ-001**: Overdose delivered to patient.

**RC-001**: Software limits dose to configured maximum. mitigates: HAZ-001
EOF
    cat > docs/architecture/sad.md <<'EOF'
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
    [ -z "$output" ]
}

@test "check-trace: REQ without verifying test fails" {
    printf 'true\n' > tests/test_a.sh
    commit_all no-verifies
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST REQ-001"* ]]
}

@test "check-trace: hazard without risk control fails" {
    printf '\n**HAZ-002**: Underdose.\n' >> docs/risk/rmf.md
    commit_all haz2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNMITIGATED-HAZARD HAZ-002"* ]]
}

@test "check-trace: risk control without implementing requirement fails" {
    printf '\n**RC-002**: Alarm on underdose. mitigates: HAZ-001\n' >> docs/risk/rmf.md
    commit_all rc2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNIMPLEMENTED-CONTROL RC-002"* ]]
}

@test "check-trace: design item without traces fails" {
    printf '\n**SDD-002**: Logging module.\n' >> docs/architecture/sad.md
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
    [ -z "$output" ]
}

@test "check-trace: LLR without satisfies fails" {
    printf '\n**LLR-002**: Log every dose change.\n' >> docs/architecture/sad.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all llr2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
}

@test "check-trace: derived LLR mentioned in RMF is not UNSATISFIED" {
    printf '\n**LLR-002**: Debounce sensor input. satisfies: derived\n' >> docs/architecture/sad.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    printf '\nDerived requirements assessment: LLR-002 introduces no new hazard.\n' >> docs/risk/rmf.md
    commit_all derived
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "check-trace: LLR without verifying test fails" {
    printf '\n**LLR-002**: Log every dose change. satisfies: REQ-001\n' >> docs/architecture/sad.md
    commit_all llr2-untested
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST LLR-002"* ]]
}

@test "check-trace: REQ with neither direct test nor tested LLR fails" {
    printf '\n**REQ-002**: The software shall log all doses.\n' >> docs/requirements/srs.md
    commit_all req2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST REQ-002"* ]]
}

@test "check-trace: derived LLR not assessed in RMF fails" {
    printf '\n**LLR-002**: Debounce sensor input. satisfies: derived\n' >> docs/architecture/sad.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all derived-unassessed
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNANALYZED-DERIVED LLR-002"* ]]
}

@test "check-trace: derived REQ not assessed in RMF fails" {
    printf '\n**REQ-002**: The software shall retry the bus handshake. satisfies: derived\n' >> docs/requirements/srs.md
    printf '# verifies: REQ-002\ntrue\n' > tests/test_c.sh
    commit_all derived-req
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNANALYZED-DERIVED REQ-002"* ]]
}

@test "check-trace: open problem report warns but passes" {
    printf '**PR-001**: Crash on empty dose input. affects: REQ-001. status: open\n' > docs/problems/log.md
    commit_all open-pr
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"UNRESOLVED-PR PR-001"* ]]
}

@test "check-trace: resolved problem report is silent" {
    printf '**PR-001**: Crash on empty dose input. affects: REQ-001. status: resolved\n' > docs/problems/log.md
    commit_all resolved-pr
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "check-trace: open PR warning coexists with real failure exit 1" {
    printf '**PR-001**: Crash on empty dose input. affects: REQ-001. status: open\n' > docs/problems/log.md
    printf '\n**HAZ-002**: Underdose.\n' >> docs/risk/rmf.md
    commit_all pr-and-haz
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNRESOLVED-PR PR-001"* ]]
    [[ "$output" == *"UNMITIGATED-HAZARD HAZ-002"* ]]
}

@test "check-trace: prose satisfies after a heading does not satisfy an LLR" {
    printf '\n**LLR-002**: Log every dose change.\n\n## Notes\n\nThis module satisfies: REQ-001 in spirit.\n' >> docs/architecture/sad.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all prose-satisfies
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
}

@test "check-trace: longer-ID mention in RMF does not cover a derived LLR" {
    printf '\n**LLR-002**: Debounce sensor input. satisfies: derived\n' >> docs/architecture/sad.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    printf '\nLLR-0020 has no hazard impact.\n' >> docs/risk/rmf.md
    commit_all substring
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNANALYZED-DERIVED LLR-002"* ]]
}

@test "check-trace: open draft PR does not misattribute to a resolved PR" {
    printf '**PR-001**: Crash on empty input. affects: REQ-001. status: resolved\n\n**PR-DRAFT-b-1**: New issue. affects: REQ-001. status: open\n' > docs/problems/log.md
    commit_all mixed-prs
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"UNRESOLVED-PR PR-001"* ]]
}

@test "check-trace: dangling affects reference in problems log fails" {
    printf '**PR-001**: Crash on empty input. affects: REQ-999. status: resolved\n' > docs/problems/log.md
    commit_all dangling-pr
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-999"* ]]
}

@test "check-trace: dangling reference to undefined ID fails" {
    printf '# REQ-999 is handled here\n' > src/main.sh
    commit_all dangling
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-999"* ]]
}
