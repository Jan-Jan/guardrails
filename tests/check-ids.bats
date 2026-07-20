load helpers

setup() {
    make_fixture_repo
    cat > docs/requirements/srs.md <<'EOF'
# SRS

**REQ-001**: The system shall exist.
EOF
    commit_all "srs with REQ-001"
}

@test "check-ids: clean repo passes" {
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "check-ids: draft ID fails with DRAFT-ID" {
    printf '\n**REQ-DRAFT-mybranch-1**: a draft item.\n' >> docs/requirements/srs.md
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-ID"* ]]
}

@test "check-ids: --allow-drafts tolerates drafts" {
    printf '\n**REQ-DRAFT-mybranch-1**: a draft item.\n' >> docs/requirements/srs.md
    run sh .guardrails/scripts/check-ids.sh --allow-drafts
    [ "$status" -eq 0 ]
}

@test "check-ids: duplicate in-tree definitions fail with DUPLICATE-ID" {
    printf '**REQ-001**: duplicate definition.\n' > src/extra.md
    commit_all dup
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID REQ-001"* ]]
}

@test "check-ids: --base catches same ID minted on both branches" {
    git checkout -qb feature
    git checkout -q main
    printf '\n**REQ-002**: main branch requirement.\n' >> docs/requirements/srs.md
    commit_all main-req2
    git checkout -q feature
    printf '\n**REQ-002**: feature branch requirement.\n' >> docs/requirements/srs.md
    commit_all feature-req2
    run sh .guardrails/scripts/check-ids.sh --base main
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID REQ-002"* ]]
}

@test "check-ids: editing an inherited requirement is not flagged by --base" {
    git checkout -qb feature2
    sed -i.bak 's/shall exist/shall really exist/' docs/requirements/srs.md
    rm -f docs/requirements/srs.md.bak
    commit_all edit
    run sh .guardrails/scripts/check-ids.sh --base main
    [ "$status" -eq 0 ]
}
