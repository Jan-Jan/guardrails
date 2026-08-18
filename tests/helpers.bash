# Shared bats helpers: throwaway fixture git repos with guardrails installed.

write_config() {
    cat > .guardrails/config.yaml <<'EOF'
guardrails_version: 0.1.0
safety_class: B
id_prefixes: REQ HAZ RC SDD LLR PR
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
EOF
}

# Creates $REPO: a git repo with config, doc dirs, and the guardrails scripts
# copied into .guardrails/scripts/. Leaves the shell cd'd into it.
make_fixture_repo() {
    REPO="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$REPO"
    cd "$REPO"
    git init -q -b main
    git config user.name test
    git config user.email test@example.com
    git config commit.gpgsign false
    mkdir -p .guardrails/scripts docs/requirements docs/risk docs/architecture docs/problems src tests
    cp "$BATS_TEST_DIRNAME"/../scripts/*.sh .guardrails/scripts/ 2>/dev/null || true
    write_config
    # ratchet copies a template into each of these, so a real project always
    # has them (skills/ratchet/SKILL.md step 2.3). Without them the fixture
    # would configure doc_soup at a path that does not exist and the four
    # ledger directories with no *.md in them at all — neither of which is a
    # shape a guardrails project is ever in.
    printf '# SOUP Inventory\n' > docs/architecture/soup.md
    printf '# Requirements ledger\n' > docs/requirements/README.md
    printf '# Risk management file\n' > docs/risk/README.md
    printf '# Software architecture\n' > docs/architecture/README.md
    printf '# Problem reports\n' > docs/problems/README.md
    # git does not track empty directories, and a configured path must
    # match a file that is actually there — ratchet tells operators to
    # .gitkeep any configured directory they leave empty for now.
    : > src/.gitkeep
    git add -A
    git commit -qm fixture
}

# Commits everything currently in the fixture repo working tree.
commit_all() {
    git add -A
    git commit -qm "${1:-update}"
}
