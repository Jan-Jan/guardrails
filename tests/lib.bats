load helpers

setup() { make_fixture_repo; }

@test "cfg_get returns scalar value" {
    run sh -c '. .guardrails/scripts/lib.sh && cfg_get safety_class'
    [ "$status" -eq 0 ]
    [ "$output" = "B" ]
}

@test "cfg_get returns doc path" {
    run sh -c '. .guardrails/scripts/lib.sh && cfg_get doc_srs'
    [ "$status" -eq 0 ]
    [ "$output" = "docs/requirements" ]
}

@test "cfg_get on missing key prints nothing and exits 0" {
    run sh -c '. .guardrails/scripts/lib.sh && cfg_get no_such_key'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "cfg_list returns list items" {
    run sh -c '. .guardrails/scripts/lib.sh && cfg_list strict_paths'
    [ "$status" -eq 0 ]
    [ "$output" = "src" ]
}

@test "cfg_list preserves spaces inside items" {
    run sh -c '. .guardrails/scripts/lib.sh && cfg_list verify_commands'
    [ "$status" -eq 0 ]
    [ "$output" = "make test" ]
}

@test "cfg_list stops at the next top-level key" {
    run sh -c '. .guardrails/scripts/lib.sh && cfg_list strict_paths | wc -l'
    [ "$output" -eq 1 ]
}

@test "gr_doc_files lists dated files for a directory value" {
    printf 'x\n' > docs/requirements/0001-01-01-base.md
    printf 'y\n' > docs/requirements/0002-02-02-later.md
    run sh -c '. .guardrails/scripts/lib.sh && gr_doc_files doc_srs'
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "docs/requirements/0001-01-01-base.md" ]
    [ "${lines[1]}" = "docs/requirements/0002-02-02-later.md" ]
}

@test "gr_doc_files passes a plain file value through" {
    printf '| |\n' > docs/architecture/soup.md
    run sh -c '. .guardrails/scripts/lib.sh && gr_doc_files doc_soup'
    [ "$status" -eq 0 ]
    [ "$output" = "docs/architecture/soup.md" ]
}

@test "gr_doc_files on a missing key prints nothing, exit 0" {
    run sh -c '. .guardrails/scripts/lib.sh && gr_doc_files doc_nonexistent'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "gr_doc_files dies when a configured path does not exist" {
    rm -rf docs/risk
    run sh -c '. .guardrails/scripts/lib.sh && gr_doc_files doc_rmf'
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_rmf"* ]]
    [[ "$output" == *"docs/risk"* ]]
}

@test "gr_prefix_re builds alternation from id_prefixes" {
    run sh -c '. .guardrails/scripts/lib.sh && gr_prefix_re'
    [ "$status" -eq 0 ]
    [ "$output" = "REQ|HAZ|RC|SDD|LLR|PR" ]
}

@test "gr_base_branch prints the primary checkout's branch" {
    run sh -c '. .guardrails/scripts/lib.sh && gr_base_branch'
    [ "$status" -eq 0 ]
    [ "$output" = "main" ]
}

@test "gr_base_branch from a linked worktree prints the primary branch" {
    git branch -m main trunk
    git worktree add -q -b feature wt
    cd wt
    run sh -c '. .guardrails/scripts/lib.sh && gr_base_branch'
    [ "$status" -eq 0 ]
    [ "$output" = "trunk" ]
}

@test "gr_base_branch on detached primary prints nothing, never a linked branch" {
    git worktree add -q -b feature wt
    git checkout -q --detach
    cd wt
    run sh -c '. .guardrails/scripts/lib.sh && gr_base_branch'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "gr_doc_files dies when a configured directory holds no *.md" {
    rm -f docs/risk/*.md
    run sh -c '. .guardrails/scripts/lib.sh && gr_doc_files doc_rmf'
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_rmf"* ]]
    [[ "$output" == *"no *.md"* ]]
}

@test "gr_prefixes rejects a prefix that is not a bare identifier" {
    sed -i.bak 's/^id_prefixes:.*/id_prefixes: REQ PR[/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    run sh -c '. .guardrails/scripts/lib.sh && gr_prefixes'
    [ "$status" -eq 2 ]
    [[ "$output" == *"bare identifier"* ]]
}

@test "gr_prefixes splits on spaces even when the caller set IFS to newline" {
    run sh -c '. .guardrails/scripts/lib.sh
IFS="
"
gr_prefixes | tr "\n" " "'
    [ "$status" -eq 0 ]
    [[ "$output" == "REQ HAZ RC SDD LLR PR "* ]]
}


@test "gr_check_config accepts the shipped config shape" {
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "gr_check_config rejects a declared prefix whose document is unconfigured" {
    sed -i.bak '/^doc_sad:/d' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_sad"* ]]
}

@test "gr_check_config rejects a list item that belongs to no key" {
    # Ambiguous by construction, and dangerous either way it is resolved: if a
    # column-one comment ends the block, the items below it vanish silently; if
    # it does not, they are absorbed by the block above — so `- src` under a
    # commented-out `strict_paths:` would quietly become a test path. Neither
    # guess is safe, so the shape is an error.
    cat > .guardrails/config.yaml <<'EOF'
id_prefixes: REQ
doc_srs: docs/requirements
test_paths:
  - tests
# strict_paths:
  - src
EOF
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 2 ]
    [[ "$output" == *"- src"* ]]
}

@test "gr_check_config accepts an indented comment inside a list block" {
    # Indented, so it is plainly part of the block and nothing is ambiguous.
    cat > .guardrails/config.yaml <<'EOF'
id_prefixes: REQ
doc_srs: docs/requirements
test_paths:
  - tests
  # the rest are being retrofitted
  - src
EOF
    run sh -c '. .guardrails/scripts/lib.sh && cfg_list test_paths | tr "\n" " "'
    [ "$status" -eq 0 ]
    [ "$output" = "tests src " ]
}


@test "cfg_get keeps a # that is not a comment" {
    # The strip requires whitespace before the #. Both halves are behaviour:
    # tightening the pattern to /#.*$/ would truncate every command containing
    # one, and nothing would notice.
    cat > .guardrails/config.yaml <<'EOF'
id_prefixes: REQ
doc_srs: docs/requirements#anchor
coverage_command:
  - sh -c 'echo "#done"'
EOF
    run sh -c '. .guardrails/scripts/lib.sh && cfg_get doc_srs'
    [ "$output" = "docs/requirements#anchor" ]
    run sh -c '. .guardrails/scripts/lib.sh && cfg_list coverage_command'
    [ "$output" = "sh -c 'echo \"#done\"'" ]
}

@test "gr_check_config rejects a list item orphaned by a document separator" {
    # `---` and `...` end a block in cfg_list, so an item after one belongs to
    # no key and is silently dropped — the same shape as the comment orphan.
    cat > .guardrails/config.yaml <<'EOF'
id_prefixes: REQ
doc_srs: docs/requirements
strict_paths:
  - src
---
  - lib
EOF
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 2 ]
    [[ "$output" == *"- lib"* ]]
}

@test "gr_check_config accepts a document end marker" {
    cat > .guardrails/config.yaml <<'EOF'
id_prefixes: REQ
doc_srs: docs/requirements
test_paths:
  - tests
...
EOF
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 0 ]
}

@test "gr_def_re anchors the definition form at line start" {
    run sh -c '. .guardrails/scripts/lib.sh && gr_def_re "REQ|PR"'
    [ "$status" -eq 0 ]
    [ "$output" = '^\*\*(REQ|PR)-[0-9]{3,}\*\*:' ]
}

@test "gr_def_re takes a POSITION, used here to scan diff output" {
    run sh -c '. .guardrails/scripts/lib.sh && gr_def_re "PR" "^\\+"'
    [ "$status" -eq 0 ]
    [ "$output" = '^\+\*\*(PR)-[0-9]{3,}\*\*:' ]
}

@test "gr_def_re with an empty POSITION matches the form anywhere on a line" {
    # ${2-^}, not ${2:-^}: an empty POSITION is a caller asking for "anywhere",
    # and the colon form would silently re-anchor it. Nothing but this test
    # pins that distinction at the constructor.
    run sh -c '. .guardrails/scripts/lib.sh && gr_def_re "PR" ""'
    [ "$status" -eq 0 ]
    [ "$output" = '\*\*(PR)-[0-9]{3,}\*\*:' ]
}
