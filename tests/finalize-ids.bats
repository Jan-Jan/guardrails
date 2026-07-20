load helpers

setup() {
    make_fixture_repo
    cat > docs/requirements/srs.md <<'EOF'
# SRS

**REQ-001**: The system shall exist.
EOF
    commit_all "srs with REQ-001"
    git checkout -qb feature
}

@test "finalize: mints next sequential ID and rewrites references" {
    printf '\n**REQ-DRAFT-b-1**: draft requirement.\n' >> docs/requirements/srs.md
    printf '# verifies: REQ-DRAFT-b-1\ntrue\n' > tests/test_x.sh
    commit_all draft
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 0 ]
    [[ "$output" == *"REQ-DRAFT-b-1 -> REQ-002"* ]]
    grep -q '^\*\*REQ-002\*\*: draft requirement.' docs/requirements/srs.md
    grep -q '# verifies: REQ-002' tests/test_x.sh
    ! grep -rq 'DRAFT' docs tests src
}

@test "finalize: --dry-run prints mapping and changes nothing" {
    printf '\n**REQ-DRAFT-b-1**: draft requirement.\n' >> docs/requirements/srs.md
    commit_all draft
    run sh .guardrails/scripts/finalize-ids.sh --dry-run --base main
    [ "$status" -eq 0 ]
    [[ "$output" == *"REQ-DRAFT-b-1 -> REQ-002"* ]]
    git diff --quiet
}

@test "finalize: overlapping draft tokens (-1 and -12) rewritten correctly" {
    printf '\n**REQ-DRAFT-b-1**: first.\n**REQ-DRAFT-b-12**: second.\n' >> docs/requirements/srs.md
    printf '# verifies: REQ-DRAFT-b-1\n# verifies: REQ-DRAFT-b-12\n' > tests/test_y.sh
    commit_all drafts
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 0 ]
    grep -q '^\*\*REQ-002\*\*: first.' docs/requirements/srs.md
    grep -q '^\*\*REQ-003\*\*: second.' docs/requirements/srs.md
    grep -q '# verifies: REQ-002' tests/test_y.sh
    grep -q '# verifies: REQ-003' tests/test_y.sh
    ! grep -rq 'DRAFT' docs tests src
}

@test "finalize: prefixes are numbered independently" {
    printf '\n**REQ-DRAFT-b-1**: new req.\n' >> docs/requirements/srs.md
    printf '**HAZ-DRAFT-b-1**: new hazard.\n' > docs/risk/rmf.md
    commit_all drafts
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 0 ]
    [[ "$output" == *"REQ-DRAFT-b-1 -> REQ-002"* ]]
    [[ "$output" == *"HAZ-DRAFT-b-1 -> HAZ-001"* ]]
}

@test "finalize: idempotent second run does nothing" {
    printf '\n**REQ-DRAFT-b-1**: draft requirement.\n' >> docs/requirements/srs.md
    commit_all draft
    sh .guardrails/scripts/finalize-ids.sh --base main
    commit_all finalized
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    git diff --quiet
}
