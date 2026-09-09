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

# --- The rewrite pass: references to renamed drafts (PR-58zsvf) --------------

@test "finalize: a path reference to a renamed draft is rewritten in another ledger" {
    # verifies: PR-58zsvf
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    printf '\nHazards for this change: docs/requirements/DRAFT-feature-dose-limits.md.\n' >> docs/risk/README.md
    commit_all draft-and-ref
    today=$(date +%Y-%m-%d)
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q "docs/requirements/${today}-dose-limits.md" docs/risk/README.md
    ! grep -q 'DRAFT-feature-dose-limits' docs/risk/README.md
    [[ "$output" == *"rewrote docs/risk/README.md: docs/requirements/DRAFT-feature-dose-limits.md -> docs/requirements/${today}-dose-limits.md"* ]] \
        || { echo "$output"; false; }
}

@test "finalize: a bare basename reference is rewritten" {
    # verifies: PR-58zsvf
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    printf '\nSee DRAFT-feature-dose-limits.md.\n' >> docs/architecture/soup.md
    commit_all draft-and-bare-ref
    today=$(date +%Y-%m-%d)
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q "See ${today}-dose-limits.md\." docs/architecture/soup.md
    [[ "$output" == *"rewrote docs/architecture/soup.md: DRAFT-feature-dose-limits.md -> ${today}-dose-limits.md"* ]] \
        || { echo "$output"; false; }
}

@test "finalize: a draft referencing its sibling draft is rewritten after both are renamed" {
    # verifies: PR-58zsvf — the rewrite runs over the renamed files, so a
    # reference inside a draft to another draft of the same change resolves.
    printf '**REQ-a3k9z2**: draft requirement. See docs/risk/DRAFT-feature-dose-limits.md.\n' \
        > docs/requirements/DRAFT-feature-dose-limits.md
    printf '**HAZ-h7z4mn**: overdose.\n' > docs/risk/DRAFT-feature-dose-limits.md
    commit_all sibling-drafts
    today=$(date +%Y-%m-%d)
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q "See docs/risk/${today}-dose-limits.md\." "docs/requirements/${today}-dose-limits.md"
}

@test "finalize: --dry-run prints the rewrites it would make and writes nothing" {
    # verifies: PR-58zsvf
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    printf '\nSee DRAFT-feature-dose-limits.md.\n' >> docs/risk/README.md
    commit_all draft-dry
    today=$(date +%Y-%m-%d)
    run sh .guardrails/scripts/finalize-docs.sh --dry-run
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"would rewrite docs/risk/README.md: DRAFT-feature-dose-limits.md -> ${today}-dose-limits.md"* ]] \
        || { echo "$output"; false; }
    git diff --quiet
    [ -f docs/requirements/DRAFT-feature-dose-limits.md ]
}

@test "finalize: a reference to another change's draft is left alone" {
    # verifies: PR-58zsvf — a draft not in this tree belongs to a change still
    # in flight elsewhere; its name is not this run's to change.
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    printf '\nPending: DRAFT-other-alarms.md.\n' >> docs/risk/README.md
    commit_all draft-other
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q 'Pending: DRAFT-other-alarms.md.' docs/risk/README.md
}

@test "finalize: a plan narrating the rename is left exactly as written" {
    # verifies: PR-58zsvf — D3: a sentence about history has to stay true;
    # only a reference inside a ledger has to resolve.
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    mkdir -p docs/plans
    printf 'Created as DRAFT-feature-dose-limits.md; finalize renames it at merge.\n' > docs/plans/2026-01-01-x.md
    commit_all draft-plan
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q 'Created as DRAFT-feature-dose-limits.md; finalize renames it at merge.' docs/plans/2026-01-01-x.md
    [[ "$output" != *"docs/plans"* ]] || { echo "$output"; false; }
}

@test "finalize: an ambiguous bare basename is left for the gate, the path form still rewrites" {
    # verifies: PR-58zsvf — D4: two drafts share a basename and one takes a
    # collision suffix, so the bare name maps two ways and cannot be rewritten.
    today=$(date +%Y-%m-%d)
    printf '# merged earlier today\n' > "docs/risk/${today}-notes.md"
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-notes.md
    printf '**HAZ-h7z4mn**: overdose.\n' > docs/risk/DRAFT-feature-notes.md
    printf '\nPath: docs/risk/DRAFT-feature-notes.md. Bare: DRAFT-feature-notes.md.\n' >> docs/architecture/README.md
    commit_all ambiguous
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q "Path: docs/risk/${today}-notes-2.md\." docs/architecture/README.md
    grep -q 'Bare: DRAFT-feature-notes.md\.' docs/architecture/README.md
    [[ "$output" == *"left docs/architecture/README.md: DRAFT-feature-notes.md"* ]] || { echo "$output"; false; }
}

@test "finalize: a rewrite that fails aborts instead of reporting a clean finalize" {
    # verifies: PR-58zsvf — awk's no-occurrence exit and awk failing are
    # different answers; conflating them leaves a half-rewritten ledger
    # reported as success. Runs as a non-root user: root can write anywhere.
    [ "$(id -u)" -ne 0 ] || skip "root ignores directory permissions"
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    printf '\nSee DRAFT-feature-dose-limits.md.\n' >> docs/architecture/README.md
    commit_all draft-ro
    chmod 555 docs/architecture
    run sh .guardrails/scripts/finalize-docs.sh
    chmod 755 docs/architecture
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"rewrite failed"* ]] || { echo "$output"; false; }
}

@test "finalize: the no-drafts case is still a silent no-op after the rewrite pass" {
    # verifies: PR-58zsvf
    printf '\nSee DRAFT-other-alarms.md.\n' >> docs/risk/README.md
    commit_all no-drafts-ref
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    git diff --quiet
}

@test "finalize: a path to another file that shares the draft's basename is not rewritten" {
    # verifies: PR-58zsvf — review finding 1. The bare pass must not rewrite the
    # tail of a path to a DIFFERENT file; it would manufacture a dangling
    # dated name that DANGLING-FILE cannot see.
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-x.md
    mkdir -p docs/other
    printf '# not a ledger, not renamed\n' > docs/other/DRAFT-feature-x.md
    printf '\nForeign: docs/other/DRAFT-feature-x.md. Ours: DRAFT-feature-x.md.\n' >> docs/risk/README.md
    commit_all foreign-basename
    today=$(date +%Y-%m-%d)
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q 'Foreign: docs/other/DRAFT-feature-x.md\.' docs/risk/README.md
    grep -q "Ours: ${today}-x.md\." docs/risk/README.md
    [ -f docs/other/DRAFT-feature-x.md ]
}

@test "finalize: --dry-run previews exactly the rewrites the real run makes" {
    # verifies: PR-58zsvf — review finding 2. A file holding only the path form
    # is one rewrite, not two, in both modes.
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-x.md
    printf '\nSee docs/requirements/DRAFT-feature-x.md.\n' >> docs/risk/README.md
    commit_all dry-exact
    run sh .guardrails/scripts/finalize-docs.sh --dry-run
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$(printf '%s\n' "$output" | grep -c 'would rewrite docs/risk/README.md')" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" != *"left "* ]] || { echo "$output"; false; }
    git diff --quiet
}

@test "finalize: an ambiguous basename is reported left once per file, and only where a bare form stands" {
    # verifies: PR-58zsvf — review finding 3.
    today=$(date +%Y-%m-%d)
    printf '# merged earlier today\n' > "docs/risk/${today}-notes.md"
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-notes.md
    printf '**HAZ-h7z4mn**: overdose.\n' > docs/risk/DRAFT-feature-notes.md
    printf '\nBoth: docs/risk/DRAFT-feature-notes.md and DRAFT-feature-notes.md.\n' >> docs/architecture/README.md
    printf '\nPath only: docs/requirements/DRAFT-feature-notes.md.\n' >> docs/architecture/soup.md
    commit_all left-once
    run sh .guardrails/scripts/finalize-docs.sh --dry-run
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"left docs/architecture/soup.md"* ]] || { echo "dry-run: $output"; false; }
    [ "$(printf '%s\n' "$output" | grep -c '^left docs/architecture/README.md:')" -eq 1 ] || { echo "dry-run: $output"; false; }
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$(printf '%s\n' "$output" | grep -c '^left docs/architecture/README.md:')" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" != *"left docs/architecture/soup.md"* ]] || { echo "$output"; false; }
    grep -q "Path only: docs/requirements/${today}-notes.md\." docs/architecture/soup.md
}

@test "finalize: two sibling drafts sharing a basename preview and rewrite the same lines once" {
    # verifies: PR-58zsvf — review finding 10.
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-x.md
    printf '**HAZ-h7z4mn**: overdose.\n' > docs/risk/DRAFT-feature-x.md
    printf '\nSee DRAFT-feature-x.md.\n' >> docs/architecture/soup.md
    commit_all siblings-preview
    run sh .guardrails/scripts/finalize-docs.sh --dry-run
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$(printf '%s\n' "$output" | grep -c 'would rewrite docs/architecture/soup.md')" -eq 1 ] || { echo "$output"; false; }
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$(printf '%s\n' "$output" | grep -c 'rewrote docs/architecture/soup.md')" -eq 1 ] || { echo "$output"; false; }
}

@test "finalize: a reference scan that fails aborts instead of reporting a clean finalize" {
    # verifies: PR-58zsvf — review finding 11. A git wrapper deletes a scope
    # file the moment the rewrite pass scans, so git grep exits 128; the
    # script must die, not read that as "no occurrences".
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-x.md
    printf '\nSee DRAFT-feature-x.md.\n' >> docs/risk/README.md
    commit_all scan-fails
    real_git=$(command -v git)
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cat > "$BATS_TEST_TMPDIR/bin/git" <<EOF
#!/bin/sh
if [ "\$1" = grep ] && [ "\$2" = -l ]; then rm -f docs/problems/README.md; fi
exec "$real_git" "\$@"
EOF
    chmod +x "$BATS_TEST_TMPDIR/bin/git"
    PATH="$BATS_TEST_TMPDIR/bin:$PATH" run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"reference scan failed"* ]] || { echo "$output"; false; }
}

@test "finalize: a glob-shaped ledger name is scanned as itself, not as what it matches" {
    # verifies: PR-58zsvf — review finding 13. Without set -f the unquoted
    # scope split expands docs/risk/[x].md to docs/risk/x.md and the rewrite
    # in [x].md is lost.
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-x.md
    printf '# a sibling the glob would match\n' > docs/risk/x.md
    printf '\nSee DRAFT-feature-x.md.\n' > 'docs/risk/[x].md'
    commit_all glob-name
    today=$(date +%Y-%m-%d)
    # Review finding 16: the first set -f (before the dry-run preview) is only
    # exercised by the preview, so the real run alone would not kill its removal.
    run sh .guardrails/scripts/finalize-docs.sh --dry-run
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"would rewrite docs/risk/[x].md: DRAFT-feature-x.md -> ${today}-x.md"* ]] || { echo "dry-run: $output"; false; }
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q "See ${today}-x.md\." 'docs/risk/[x].md'
}

@test "finalize: a token glued to a longer word is not the file's name" {
    # verifies: PR-58zsvf — review finding 14.
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-x.md
    printf '\nGlued: xDRAFT-feature-x.md and _DRAFT-feature-x.md; real: DRAFT-feature-x.md.\n' >> docs/risk/README.md
    commit_all glued
    today=$(date +%Y-%m-%d)
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q 'Glued: xDRAFT-feature-x.md and _DRAFT-feature-x.md;' docs/risk/README.md
    grep -q "real: ${today}-x.md\." docs/risk/README.md
}
