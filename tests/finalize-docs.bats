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

@test "finalize: a tree with no draft ledger files prints nothing" {
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    git diff --quiet
}

@test "finalize: renames draft doc file to merge-dated name" {
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    commit_all draft-file
    today=$(date +%Y-%m-%d)
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRAFT-feature-dose-limits.md -> ${today}-dose-limits.md"* ]]
    [ -f "docs/requirements/${today}-dose-limits.md" ]
    [ ! -f docs/requirements/DRAFT-feature-dose-limits.md ]
    grep -q '^\*\*REQ-a3k9z2\*\*:' "docs/requirements/${today}-dose-limits.md"
}

@test "finalize: --dry-run does not rename draft doc files" {
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    commit_all draft-file
    run sh .guardrails/scripts/finalize-docs.sh --dry-run
    [ "$status" -eq 0 ]
    [ -f docs/requirements/DRAFT-feature-dose-limits.md ]
    git diff --quiet
}

@test "finalize: dated-name collision gets a numeric suffix" {
    today=$(date +%Y-%m-%d)
    printf '# existing change merged earlier today\n' > "docs/requirements/${today}-dose-limits.md"
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    commit_all collision
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ]
    [ -f "docs/requirements/${today}-dose-limits-2.md" ]
    [ ! -f docs/requirements/DRAFT-feature-dose-limits.md ]
}

@test "finalize: same-run rename collisions get distinct names, no data loss" {
    printf '# content-a\n' > docs/requirements/DRAFT-foo.md
    printf '# content-b\n' > docs/requirements/DRAFT-feature-foo.md
    commit_all two-drafts
    today=$(date +%Y-%m-%d)
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ]
    [ -f "docs/requirements/${today}-foo.md" ]
    [ -f "docs/requirements/${today}-foo-2.md" ]
    grep -rq 'content-a' docs/requirements
    grep -rq 'content-b' docs/requirements
}

@test "finalize: idempotent second run does nothing" {
    printf '**REQ-a3k9z2**: a requirement.\n' > docs/requirements/DRAFT-feature-notes.md
    commit_all draft-file
    sh .guardrails/scripts/finalize-docs.sh
    commit_all renamed
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    git diff --quiet
}

@test "finalize: an ID prefix that is not a bare identifier is an error" {
    # A metacharacter here makes every scan pattern an invalid ERE; git grep
    # then errors and matches nothing, which looks exactly like a clean tree.
    sed -i.bak 's/^id_prefixes:.*/id_prefixes: REQ PR[/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf 'PR-p9r5wx: a plain header\n' > docs/problems/DRAFT-b-notes.md
    commit_all metachar
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"bare identifier"* ]]
    # nothing renamed, nothing rewritten
    [ -f docs/problems/DRAFT-b-notes.md ]
    grep -q 'PR-p9r5wx' docs/problems/DRAFT-b-notes.md
}

@test "finalize: a rename that fails aborts instead of reporting success" {
    # The rename loop must not run in a pipeline subshell: gr_die there would
    # exit only the subshell and the script would carry on to exit 0, claiming
    # success after refusing to do the rename. Two doc keys pointing at the
    # same directory plan the same source file twice, so the second rename has
    # nothing left to move.
    sed -i.bak 's|^doc_rmf:.*|doc_rmf: docs/requirements|' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-notes.md
    printf '# verifies: REQ-a3k9z2\ntrue\n' > tests/test_x.sh
    commit_all dup-key
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"rename"* ]]
}

@test "finalize: same-day rename collision never overwrites an existing file" {
    today=$(date +%Y-%m-%d)
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-notes.md
    printf 'placeholder\n' > "docs/requirements/${today}-notes.md"
    printf '# verifies: REQ-a3k9z2\ntrue\n' > tests/test_x.sh
    commit_all collision
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ]
    grep -q '^placeholder$' "docs/requirements/${today}-notes.md"
    [ -f "docs/requirements/${today}-notes-2.md" ]
}

@test "finalize: a draft ledger name with whitespace fails before anything is rewritten" {
    # The rename records are space-joined pairs, so such a name would be split
    # at the wrong point, and the failure would land partway through the rename
    # loop with some ledgers moved and some not. Refuse during planning.
    printf '**REQ-a3k9z2**: draft requirement.\n' > 'docs/requirements/DRAFT-my notes.md'
    printf '# verifies: REQ-a3k9z2\ntrue\n' > tests/test_x.sh
    commit_all spacey
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"whitespace"* ]]
    git diff --quiet
    grep -q 'REQ-a3k9z2' 'docs/requirements/DRAFT-my notes.md'
}

@test "finalize: a doc key whose path is missing fails before anything is renamed" {
    # gr_doc_files validates a doc_* key's VALUE. Without it the ledger it
    # names is skipped in silence: its DRAFT- file is left in place and the run
    # exits 0 having reported every rename there was to report.
    sed -i.bak 's|^doc_problems: docs/problems$|doc_problems: docs/problemz|' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf '**PR-p9r5wx**: a problem. status: open\n' > docs/problems/DRAFT-feature-notes.md
    printf '# verifies: PR-p9r5wx\ntrue\n' > tests/test_x.sh
    commit_all missing-doc-path
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"docs/problemz"* ]]
    git diff --quiet
    grep -q 'PR-p9r5wx' docs/problems/DRAFT-feature-notes.md
}

@test "finalize: a typo'd doc key is an error, not a ledger it quietly skips" {
    # gr_check_config validates a key's SPELLING; gr_doc_files validates its
    # VALUE. Without the first, the misspelled key reads as "this project has
    # no problem ledger", so its DRAFT- file is never renamed and the run still
    # exits 0.
    sed -i.bak 's/^doc_problems:/doc_problemss:/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf '**PR-p9r5wx**: a problem. status: open\n' > docs/problems/DRAFT-feature-notes.md
    commit_all typo-key
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_problemss"* ]]
    [ -f docs/problems/DRAFT-feature-notes.md ]
}


@test "finalize: --dry-run prints the renames it would make" {
    # Independent review, S7. Moving the --dry-run exit above the print loop
    # left all twelve tests in this file green, while the script's own header
    # promises one "before -> after" line per rename and merge-change step 3
    # says to preview with it. The print half of the deleted
    # "--dry-run prints mapping and changes nothing" had no successor.
    printf '**REQ-a3k9z2**: a requirement.\n' > docs/requirements/DRAFT-feature-notes.md
    commit_all draft-file
    today=$(date +%Y-%m-%d)

    run sh .guardrails/scripts/finalize-docs.sh --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRAFT-feature-notes.md -> ${today}-notes.md"* ]] \
        || { echo "$output"; false; }
    [ -f docs/requirements/DRAFT-feature-notes.md ]
    git diff --quiet
}

# --- The unit manifest (T9): finalize runs per touched unit ------------------

@test "finalize-docs: finalize-runs-per-touched-unit — GR_CONFIG scopes the rename to one unit" {
    make_units_fixture
    printf '# pump draft\n' > apps/pump/docs/requirements/DRAFT-my-change-notes.md
    printf '# hal draft\n' > platform/hal/docs/requirements/DRAFT-my-change-notes.md
    commit_all drafts
    GR_CONFIG=apps/pump/.guardrails/config.yaml run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ]
    [ ! -e apps/pump/docs/requirements/DRAFT-my-change-notes.md ]
    [ -e platform/hal/docs/requirements/DRAFT-my-change-notes.md ]
}

@test "finalize-docs: a manifest repo without GR_CONFIG is exit 2 naming the remedy" {
    make_units_fixture
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"multi-unit repository"* ]]
}
