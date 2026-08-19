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

@test "finalize: default base is the primary checkout's branch, not main" {
    git checkout -q main
    git branch -m main trunk
    git worktree add -q -b wt-change wt
    # trunk advances past the worktree's fork point
    printf '\n**REQ-002**: added on trunk after fork.\n' >> docs/requirements/0001-01-01-base.md
    commit_all trunk-advance
    cd wt
    printf '\n**REQ-DRAFT-b-1**: draft in worktree.\n' >> docs/requirements/0001-01-01-base.md
    commit_all draft
    run sh .guardrails/scripts/finalize-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"REQ-DRAFT-b-1 -> REQ-003"* ]]
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

@test "finalize: refuses to run when a draft ID has no bold definition header" {
    printf 'PR-DRAFT-b-1: crash on empty input. affects: REQ-001. status: open\n' \
        > docs/problems/DRAFT-b-notes.md
    commit_all draft
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNMINTED-DRAFT"* ]]
    [[ "$output" == *"PR-DRAFT-b-1"* ]]
    # nothing was rewritten and the ledger file was NOT renamed
    git diff --quiet
    [ -f docs/problems/DRAFT-b-notes.md ]
}

@test "finalize: names the file and line of each unminted draft" {
    printf '# verifies: REQ-DRAFT-b-9\ntrue\n' > tests/test_orphan.sh
    commit_all orphan
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 1 ]
    [[ "$output" == *"tests/test_orphan.sh:1"* ]]
}

@test "finalize: a well-formed draft alongside a malformed one still blocks" {
    printf '\n**REQ-DRAFT-b-1**: good draft.\n' >> docs/requirements/0001-01-01-base.md
    printf 'PR-DRAFT-b-2: bad header.\n' > docs/problems/DRAFT-b-notes.md
    commit_all mixed
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 1 ]
    grep -q 'REQ-DRAFT-b-1' docs/requirements/0001-01-01-base.md
}

@test "finalize: --dry-run reports an unminted draft and exits 1" {
    # The pre-flight deliberately runs above the --dry-run early exit: a
    # preview whose whole job is to show what the real run will do must not
    # hide the reason the real run will refuse.
    printf 'REQ-DRAFT-b-1: plain header, never mintable\n' > docs/requirements/DRAFT-b-notes.md
    commit_all bad-draft
    run sh .guardrails/scripts/finalize-ids.sh --dry-run --base main
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNMINTED-DRAFT"* ]]
    [ -f docs/requirements/DRAFT-b-notes.md ]
}

@test "finalize: an ID prefix that is not a bare identifier is an error" {
    # A metacharacter here makes every scan pattern an invalid ERE; git grep
    # then errors and matches nothing, which looks exactly like a clean tree.
    sed -i.bak 's/^id_prefixes:.*/id_prefixes: REQ PR[/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf 'PR-DRAFT-b-1: plain header, never mintable\n' > docs/problems/DRAFT-b-notes.md
    commit_all metachar
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 2 ]
    [[ "$output" == *"bare identifier"* ]]
    # nothing renamed, nothing rewritten
    [ -f docs/problems/DRAFT-b-notes.md ]
    grep -q 'PR-DRAFT-b-1' docs/problems/DRAFT-b-notes.md
}

@test "finalize: a rename that fails aborts instead of reporting success" {
    # The rename loop must not run in a pipeline subshell: gr_die there would
    # exit only the subshell and the script would carry on to exit 0, claiming
    # success after refusing to do the rename. Two doc keys pointing at the
    # same directory plan the same source file twice, so the second rename has
    # nothing left to move.
    sed -i.bak 's|^doc_rmf:.*|doc_rmf: docs/requirements|' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf '**REQ-DRAFT-b-1**: draft requirement.\n' > docs/requirements/DRAFT-feature-notes.md
    printf '# verifies: REQ-DRAFT-b-1\ntrue\n' > tests/test_x.sh
    commit_all dup-key
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 2 ]
    [[ "$output" == *"rename"* ]]
}

@test "finalize: same-day rename collision never overwrites an existing file" {
    today=$(date +%Y-%m-%d)
    printf '**REQ-DRAFT-b-1**: draft requirement.\n' > docs/requirements/DRAFT-feature-notes.md
    printf 'placeholder\n' > "docs/requirements/${today}-notes.md"
    printf '# verifies: REQ-DRAFT-b-1\ntrue\n' > tests/test_x.sh
    commit_all collision
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 0 ]
    grep -q '^placeholder$' "docs/requirements/${today}-notes.md"
    [ -f "docs/requirements/${today}-notes-2.md" ]
}

@test "finalize: a draft ledger name with whitespace fails before anything is rewritten" {
    # The rename records are space-joined pairs, so such a name would be split
    # at the wrong point and fail AFTER the ID rewrite pass, leaving a
    # half-finalized tree. Refuse during planning instead.
    printf '**REQ-DRAFT-b-1**: draft requirement.\n' > 'docs/requirements/DRAFT-my notes.md'
    printf '# verifies: REQ-DRAFT-b-1\ntrue\n' > tests/test_x.sh
    commit_all spacey
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 2 ]
    [[ "$output" == *"whitespace"* ]]
    git diff --quiet
    grep -q 'REQ-DRAFT-b-1' 'docs/requirements/DRAFT-my notes.md'
}

@test "finalize: a draft inside .guardrails is not minted against a rewrite that skips it" {
    # The mint scan must use the same pathspec as the rewrite. A wider mint
    # scan burned an ID for a draft it then never rewrote, and exited 0.
    printf '**REQ-DRAFT-b-1**: draft inside the guardrails dir.\n' > .guardrails/notes.md
    printf '\n**REQ-DRAFT-b-2**: a real draft requirement.\n' >> docs/requirements/0001-01-01-base.md
    printf '# verifies: REQ-DRAFT-b-2\ntrue\n' > tests/test_x.sh
    commit_all guardrails-draft
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 0 ]
    [[ "$output" == *"REQ-DRAFT-b-2 -> REQ-002"* ]]
    [[ "$output" != *"REQ-DRAFT-b-1"* ]]
    grep -q 'REQ-DRAFT-b-1' .guardrails/notes.md
}

@test "finalize: a doc key whose path is missing fails before anything is minted" {
    # gr_doc_files validates a doc_* key's VALUE. Without it the IDs were
    # minted and rewritten, the DRAFT- file was left in place, and the run
    # exited 0 over a half-finalized tree. (Validating the KEY itself is a
    # separate change — see the plan's "How this landed" section.)
    sed -i.bak 's|^doc_problems: docs/problems$|doc_problems: docs/problemz|' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf '**PR-DRAFT-b-1**: a problem. status: open\n' > docs/problems/DRAFT-feature-notes.md
    printf '# verifies: PR-DRAFT-b-1\ntrue\n' > tests/test_x.sh
    commit_all missing-doc-path
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 2 ]
    [[ "$output" == *"docs/problemz"* ]]
    git diff --quiet
    grep -q 'PR-DRAFT-b-1' docs/problems/DRAFT-feature-notes.md
}

@test "finalize: an ID defined under .guardrails does not shift the next number" {
    # max_final must scan the same paths as the mint and rewrite scans, or the
    # sequence jumps with no visible cause.
    printf '**REQ-050**: an item inside the guardrails dir.\n' > .guardrails/notes.md
    printf '\n**REQ-DRAFT-b-1**: draft requirement.\n' >> docs/requirements/0001-01-01-base.md
    printf '# verifies: REQ-DRAFT-b-1\ntrue\n' > tests/test_x.sh
    commit_all guardrails-final-id
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 0 ]
    [[ "$output" == *"REQ-DRAFT-b-1 -> REQ-002"* ]]
}

@test "finalize: a draft whose prefix is missing from id_prefixes still blocks" {
    # Such a draft can never be minted, so it must not ride onto the base
    # branch unnoticed. The pre-flight scans for any <prefix>-DRAFT- token.
    sed -i.bak 's/^id_prefixes:.*/id_prefixes: REQ HAZ RC SDD LLR/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf '**PR-DRAFT-b-1**: a problem. status: open\n' > docs/problems/DRAFT-feature-notes.md
    commit_all undeclared-prefix
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNMINTED-DRAFT"* ]]
    [ -f docs/problems/DRAFT-feature-notes.md ]
}

@test "finalize: a typo'd doc key is an error, not a ledger it quietly skips" {
    # gr_check_config validates a key's SPELLING; gr_doc_files validates its
    # VALUE. Without the first, the misspelled key read as "no problem ledger",
    # so its DRAFT- file was never renamed while the IDs were minted and
    # rewritten — exit 0 over a half-finalized tree.
    sed -i.bak 's/^doc_problems:/doc_problemss:/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf '**PR-DRAFT-b-1**: a problem. status: open\n' > docs/problems/DRAFT-feature-notes.md
    commit_all typo-key
    run sh .guardrails/scripts/finalize-ids.sh --base main
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_problemss"* ]]
    [ -f docs/problems/DRAFT-feature-notes.md ]
}
