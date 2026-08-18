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

@test "check-ids: an ID prefix that is not a bare identifier is an error" {
    # Before validation this printed "grep: Unmatched ( or \(" and exited 0 —
    # an invalid pattern matches nothing, which looks exactly like a clean tree.
    sed -i.bak 's/^id_prefixes:.*/id_prefixes: REQ HAZ RC SDD LLR PR[/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf '\n**REQ-DRAFT-b-1**: draft requirement.\n' >> docs/requirements/0001-01-01-base.md
    commit_all metachar
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"bare identifier"* ]]
    # and only that: gr_prefix_re must propagate the die rather than returning
    # an empty string that trips the unrelated "not configured" fallback
    [[ "$output" != *"not configured"* ]]
}

@test "check-ids: a draft whose prefix is missing from id_prefixes is still a draft" {
    # check-ids and finalize-ids must agree on what a draft is. When check-ids
    # only looked for the declared prefixes, finalize-ids blocked on a draft
    # this gate waved through — a hole between two gates of the same sequence.
    sed -i.bak 's/^id_prefixes:.*/id_prefixes: REQ HAZ RC SDD LLR/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf '\n**PR-DRAFT-b-1**: a problem. status: open\n' >> docs/problems/README.md
    commit_all undeclared-prefix-draft
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-ID"* ]]
    [[ "$output" == *"PR-DRAFT-b-1"* ]]
}

@test "check-ids: --allow-drafts still tolerates an undeclared-prefix draft" {
    sed -i.bak 's/^id_prefixes:.*/id_prefixes: REQ HAZ RC SDD LLR/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf '\n**PR-DRAFT-b-1**: a problem. status: open\n' >> docs/problems/README.md
    commit_all undeclared-prefix-draft-allowed
    run sh .guardrails/scripts/check-ids.sh --allow-drafts
    [ "$status" -eq 0 ]
}

@test "check-ids: an ID defined under .guardrails is not a duplicate of a minted one" {
    # finalize-ids ignores .guardrails when picking the next number, so this
    # gate must ignore it too. Otherwise finalize mints an ID that check-ids
    # rejects as already defined on the base, and the merge sequence deadlocks
    # with no permitted way forward.
    printf '**REQ-002**: an item inside the guardrails dir.\n' > .guardrails/notes.md
    commit_all guardrails-id
    git checkout -qb feature
    printf '\n**REQ-DRAFT-b-1**: draft requirement.\n' >> docs/requirements/0001-01-01-base.md
    printf '# verifies: REQ-DRAFT-b-1\ntrue\n' > tests/test_x.sh
    commit_all draft
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 0 ]
    [[ "$output" == *"REQ-DRAFT-b-1 -> REQ-002"* ]]
    commit_all finalized
    run sh .guardrails/scripts/check-ids.sh --base main
    [ "$status" -eq 0 ]
}

@test "check-ids: a named base ref that does not resolve is an error" {
    # The caller asked for this gate; a silent pass is not an answer.
    run sh .guardrails/scripts/check-ids.sh --base no-such-ref
    [ "$status" -eq 2 ]
    [[ "$output" == *"no-such-ref"* ]]
}

@test "check-ids: a detected base with no commits yet is skipped, not fatal" {
    # gr_base_branch reports the branch name from the worktree list, which
    # exists before its first commit. Dying there aborts on a fresh repo with
    # a complaint about a --base the caller never passed.
    cd "$BATS_TEST_TMPDIR"
    mkdir fresh && cd fresh
    git init -q -b main
    git config user.name test
    git config user.email test@example.com
    mkdir -p .guardrails/scripts
    cp "$BATS_TEST_DIRNAME"/../scripts/*.sh .guardrails/scripts/
    printf 'id_prefixes: REQ HAZ RC SDD LLR PR
' > .guardrails/config.yaml
    printf '**REQ-DRAFT-b-1**: a draft.
' > notes.md
    run sh .guardrails/scripts/check-ids.sh --allow-drafts
    [ "$status" -eq 0 ]
    [[ "$output" == *"SKIPPED-DUPLICATE-BASE"* ]]
}

@test "check-ids: an undetectable base says the gate was skipped, and still passes" {
    # A detached HEAD is what an ordinary CI checkout produces. Failing there
    # would break every such project; passing silently would hide that the
    # duplicate-vs-base gate never ran. Say so and carry on.
    git checkout -q --detach
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"SKIPPED-DUPLICATE-BASE"* ]]
}
