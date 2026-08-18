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

