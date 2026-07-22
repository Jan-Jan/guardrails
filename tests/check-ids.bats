load helpers

setup() {
    make_fixture_repo
    cat > docs/requirements/0001-01-01-base.md <<'EOF'
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
    printf '\n**REQ-DRAFT-mybranch-1**: a draft item.\n' >> docs/requirements/0001-01-01-base.md
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-ID"* ]]
}

@test "check-ids: --allow-drafts tolerates drafts" {
    printf '\n**REQ-DRAFT-mybranch-1**: a draft item.\n' >> docs/requirements/0001-01-01-base.md
    run sh .guardrails/scripts/check-ids.sh --allow-drafts
    [ "$status" -eq 0 ]
}

@test "check-ids: LLR draft token fails without --allow-drafts" {
    printf '**LLR-DRAFT-mybranch-1**: draft low-level req.\n' > docs/architecture/0001-01-01-base.md
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-ID"* ]]
    [[ "$output" == *"LLR-DRAFT-mybranch-1"* ]]
}

@test "check-ids: PR draft token fails without --allow-drafts" {
    printf '**PR-DRAFT-mybranch-1**: draft problem. status: open\n' > docs/problems/0001-01-01-base.md
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"PR-DRAFT-mybranch-1"* ]]
}

@test "check-ids: draft-named file fails with DRAFT-FILE" {
    printf '# placeholder\n' > docs/requirements/DRAFT-mybranch-dose.md
    git add docs/requirements/DRAFT-mybranch-dose.md
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-FILE docs/requirements/DRAFT-mybranch-dose.md"* ]]
}

@test "check-ids: --allow-drafts tolerates draft-named files" {
    printf '# placeholder\n' > docs/requirements/DRAFT-mybranch-dose.md
    git add docs/requirements/DRAFT-mybranch-dose.md
    run sh .guardrails/scripts/check-ids.sh --allow-drafts
    [ "$status" -eq 0 ]
}

@test "check-ids: duplicate LLR definitions fail with DUPLICATE-ID" {
    printf '**LLR-001**: clamp dose. satisfies: REQ-001\n' > docs/architecture/0001-01-01-base.md
    printf '**LLR-001**: duplicate.\n' > src/extra.md
    commit_all llr-dup
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID LLR-001"* ]]
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
    printf '\n**REQ-002**: main branch requirement.\n' >> docs/requirements/0001-01-01-base.md
    commit_all main-req2
    git checkout -q feature
    printf '\n**REQ-002**: feature branch requirement.\n' >> docs/requirements/0001-01-01-base.md
    commit_all feature-req2
    run sh .guardrails/scripts/check-ids.sh --base main
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID REQ-002"* ]]
}

@test "check-ids: default base catches duplicate vs the primary checkout's branch" {
    git branch -m main trunk
    git worktree add -q -b wt-change wt
    printf '\n**REQ-002**: added on trunk after fork.\n' >> docs/requirements/0001-01-01-base.md
    commit_all trunk-advance
    cd wt
    printf '\n**REQ-002**: independently minted in worktree.\n' >> docs/requirements/0001-01-01-base.md
    commit_all wt-req2
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID REQ-002 (already defined on trunk)"* ]]
}

@test "check-ids: editing an inherited requirement is not flagged by --base" {
    git checkout -qb feature2
    sed -i.bak 's/shall exist/shall really exist/' docs/requirements/0001-01-01-base.md
    rm -f docs/requirements/0001-01-01-base.md.bak
    commit_all edit
    run sh .guardrails/scripts/check-ids.sh --base main
    [ "$status" -eq 0 ]
}
