load helpers

setup() {
    make_fixture_repo
    cat > docs/requirements/0001-01-01-base.md <<'EOF'
# SRS

**REQ-001**: The system shall exist.
EOF
    commit_all "srs with REQ-001"
    git checkout -qb feature
}

@test "finalize: mints next sequential ID and rewrites references" {
    printf '\n**REQ-DRAFT-b-1**: draft requirement.\n' >> docs/requirements/0001-01-01-base.md
    printf '# verifies: REQ-DRAFT-b-1\ntrue\n' > tests/test_x.sh
    commit_all draft
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 0 ]
    [[ "$output" == *"REQ-DRAFT-b-1 -> REQ-002"* ]]
    grep -q '^\*\*REQ-002\*\*: draft requirement.' docs/requirements/0001-01-01-base.md
    grep -q '# verifies: REQ-002' tests/test_x.sh
    ! grep -rq 'DRAFT' docs tests src
}

@test "finalize: --dry-run prints mapping and changes nothing" {
    printf '\n**REQ-DRAFT-b-1**: draft requirement.\n' >> docs/requirements/0001-01-01-base.md
    commit_all draft
    run sh .guardrails/scripts/finalize-ids.sh --dry-run --base main
    [ "$status" -eq 0 ]
    [[ "$output" == *"REQ-DRAFT-b-1 -> REQ-002"* ]]
    git diff --quiet
}

@test "finalize: overlapping draft tokens (-1 and -12) rewritten correctly" {
    printf '\n**REQ-DRAFT-b-1**: first.\n**REQ-DRAFT-b-12**: second.\n' >> docs/requirements/0001-01-01-base.md
    printf '# verifies: REQ-DRAFT-b-1\n# verifies: REQ-DRAFT-b-12\n' > tests/test_y.sh
    commit_all drafts
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 0 ]
    grep -q '^\*\*REQ-002\*\*: first.' docs/requirements/0001-01-01-base.md
    grep -q '^\*\*REQ-003\*\*: second.' docs/requirements/0001-01-01-base.md
    grep -q '# verifies: REQ-002' tests/test_y.sh
    grep -q '# verifies: REQ-003' tests/test_y.sh
    ! grep -rq 'DRAFT' docs tests src
}

@test "finalize: prefixes are numbered independently" {
    printf '\n**REQ-DRAFT-b-1**: new req.\n' >> docs/requirements/0001-01-01-base.md
    printf '**HAZ-DRAFT-b-1**: new hazard.\n' > docs/risk/0001-01-01-base.md
    commit_all drafts
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 0 ]
    [[ "$output" == *"REQ-DRAFT-b-1 -> REQ-002"* ]]
    [[ "$output" == *"HAZ-DRAFT-b-1 -> HAZ-001"* ]]
}

@test "finalize: LLR and PR prefixes finalize independently" {
    printf '**LLR-DRAFT-b-1**: clamp dose. satisfies: REQ-001\n' > docs/architecture/0001-01-01-base.md
    printf '**PR-DRAFT-b-1**: crash on empty input. affects: REQ-001. status: open\n' > docs/problems/0001-01-01-base.md
    commit_all drafts
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 0 ]
    [[ "$output" == *"LLR-DRAFT-b-1 -> LLR-001"* ]]
    [[ "$output" == *"PR-DRAFT-b-1 -> PR-001"* ]]
    grep -q '^\*\*LLR-001\*\*:' docs/architecture/0001-01-01-base.md
    grep -q '^\*\*PR-001\*\*:' docs/problems/0001-01-01-base.md
}

@test "finalize: renames draft doc file to merge-dated name" {
    printf '**REQ-DRAFT-b-1**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    commit_all draft-file
    today=$(date +%Y-%m-%d)
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRAFT-feature-dose-limits.md -> ${today}-dose-limits.md"* ]]
    [ -f "docs/requirements/${today}-dose-limits.md" ]
    [ ! -f docs/requirements/DRAFT-feature-dose-limits.md ]
    grep -q '^\*\*REQ-002\*\*:' "docs/requirements/${today}-dose-limits.md"
}

@test "finalize: --dry-run does not rename draft doc files" {
    printf '**REQ-DRAFT-b-1**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    commit_all draft-file
    run sh .guardrails/scripts/finalize-ids.sh --dry-run --base main
    [ "$status" -eq 0 ]
    [ -f docs/requirements/DRAFT-feature-dose-limits.md ]
    git diff --quiet
}

@test "finalize: dated-name collision gets a numeric suffix" {
    today=$(date +%Y-%m-%d)
    printf '# existing change merged earlier today\n' > "docs/requirements/${today}-dose-limits.md"
    printf '**REQ-DRAFT-b-1**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    commit_all collision
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 0 ]
    [ -f "docs/requirements/${today}-dose-limits-2.md" ]
    [ ! -f docs/requirements/DRAFT-feature-dose-limits.md ]
}

@test "finalize: same-run rename collisions get distinct names, no data loss" {
    printf '# content-a\n' > docs/requirements/DRAFT-foo.md
    printf '# content-b\n' > docs/requirements/DRAFT-feature-foo.md
    commit_all two-drafts
    today=$(date +%Y-%m-%d)
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 0 ]
    [ -f "docs/requirements/${today}-foo.md" ]
    [ -f "docs/requirements/${today}-foo-2.md" ]
    grep -rq 'content-a' docs/requirements
    grep -rq 'content-b' docs/requirements
}

@test "finalize: idempotent second run does nothing" {
    printf '\n**REQ-DRAFT-b-1**: draft requirement.\n' >> docs/requirements/0001-01-01-base.md
    commit_all draft
    sh .guardrails/scripts/finalize-ids.sh --base main
    commit_all finalized
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    git diff --quiet
}
