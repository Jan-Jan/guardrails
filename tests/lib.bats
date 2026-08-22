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
    exp=$(sh -c '. .guardrails/scripts/lib.sh && printf "%s" "^\\*\\*(REQ|PR)-${GR_ID_BODY}\\*\\*:"')
    [ "$output" = "$exp" ]
}

@test "gr_def_re takes a POSITION, used here to scan diff output" {
    run sh -c '. .guardrails/scripts/lib.sh && gr_def_re "PR" "^\\+"'
    [ "$status" -eq 0 ]
    exp=$(sh -c '. .guardrails/scripts/lib.sh && printf "%s" "^\\+\\*\\*(PR)-${GR_ID_BODY}\\*\\*:"')
    [ "$output" = "$exp" ]
}

@test "gr_def_re with an empty POSITION matches the form anywhere on a line" {
    # ${2-^}, not ${2:-^}: an empty POSITION is a caller asking for "anywhere",
    # and the colon form would silently re-anchor it. Nothing but this test
    # pins that distinction at the constructor.
    run sh -c '. .guardrails/scripts/lib.sh && gr_def_re "PR" ""'
    [ "$status" -eq 0 ]
    exp=$(sh -c '. .guardrails/scripts/lib.sh && printf "%s" "\\*\\*(PR)-${GR_ID_BODY}\\*\\*:"')
    [ "$output" = "$exp" ]
}


# --- the ID vocabulary: token form, legacy form, and the digit rule ---------

@test "gr_def_re matches a minted token definition" {
    run sh -c '. .guardrails/scripts/lib.sh && printf "%s\n" "**REQ-a3k9z2**: a thing" | grep -qE "$(gr_def_re REQ)"'
    [ "$status" -eq 0 ]
}

@test "gr_def_re still matches a legacy sequential definition" {
    run sh -c '. .guardrails/scripts/lib.sh && printf "%s\n" "**REQ-014**: a thing" | grep -qE "$(gr_def_re REQ)"'
    [ "$status" -eq 0 ]
}

@test "gr_def_re rejects an all-letter body — REQ-argued is prose, not an ID" {
    # The whole reason a token must carry a digit: six letters of the
    # unambiguous alphabet is also an ordinary English word.
    run sh -c '. .guardrails/scripts/lib.sh && printf "%s\n" "**REQ-argued**: a thing" | grep -qE "$(gr_def_re REQ)"'
    [ "$status" -eq 1 ]
}

@test "gr_def_re rejects the ambiguous characters 0 o 1 l i" {
    for body in a3k9zo a3k9zl a3k9zi a3k9z0 a3k9z1 a3k9zO a3k9zI; do
        run sh -c '. .guardrails/scripts/lib.sh && printf "%s\n" "**REQ-'"$body"'**: x" | grep -qE "$(gr_def_re REQ)"'
        [ "$status" -eq 1 ]
    done
}

@test "gr_def_re rejects a token body of the wrong length" {
    for body in a3k9z a3k9z2x; do
        run sh -c '. .guardrails/scripts/lib.sh && printf "%s\n" "**REQ-'"$body"'**: x" | grep -qE "$(gr_def_re REQ)"'
        [ "$status" -eq 1 ]
    done
}

@test "gr_def_re accepts a digit in every one of the six positions" {
    # The token pattern is a union over the position of the first digit. A
    # branch dropped from that union would make one sixth of the token space
    # unmatchable, and the IDs it produced would be invisible to every gate.
    for body in 2bcdef a2cdef ab2def abc2ef abcd2f abcde2; do
        run sh -c '. .guardrails/scripts/lib.sh && printf "%s\n" "**REQ-'"$body"'**: x" | grep -qE "$(gr_def_re REQ)"'
        [ "$status" -eq 0 ]
    done
}

@test "gr_id_run harvests both ID forms from an annotation list" {
    run sh -c '. .guardrails/scripts/lib.sh && printf "%s\n" "# verifies: REQ-a3k9z2, REQ-014" | gr_id_run "verifies:"'
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "REQ-a3k9z2" ]
    [ "${lines[1]}" = "REQ-014" ]
}

@test "gr_id_run does not harvest a hyphenated English word after an ID" {
    # update-server has a six-character all-letter tail. Without the digit
    # rule the annotation run would swallow it and report it dangling.
    run sh -c '. .guardrails/scripts/lib.sh && printf "%s\n" "# verifies: REQ-a3k9z2 update-server" | gr_id_run "verifies:"'
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 1 ]
    [ "${lines[0]}" = "REQ-a3k9z2" ]
}

@test "gr_id_run does not credit a reference one character too long" {
    # A token is exactly six characters, so REQ-a3k9z2x is not an ID at all.
    # Harvested without a boundary, the run matched its first six characters
    # and reported REQ-a3k9z2 — crediting a real item for a reference nobody
    # wrote. Sequential IDs never had this: [0-9]{3,} is greedy, so REQ-0012
    # harvested whole and showed up as the dangling reference it was.
    run sh -c '. .guardrails/scripts/lib.sh && printf "%s\n" "# verifies: REQ-a3k9z2x" | gr_id_run "verifies:"'
    [ "$status" -eq 0 ]
    [ -z "$output" ] || { echo "harvested: $output"; false; }
}

@test "gr_id_run still harvests an ID followed by punctuation" {
    run sh -c '. .guardrails/scripts/lib.sh && printf "%s\n" "# verifies: REQ-a3k9z2." | gr_id_run "verifies:"'
    [ "$output" = "REQ-a3k9z2" ]
}

@test "gr_id_run does not credit a legacy reference one digit too long" {
    # The greedy legacy branch already handled this; the test is here so that
    # tightening the token boundary cannot quietly loosen the other form.
    run sh -c '. .guardrails/scripts/lib.sh && printf "%s\n" "# verifies: REQ-0012" | gr_id_run "verifies:"'
    [ "$output" = "REQ-0012" ]
}

@test "gr_id_run does not credit a reference followed by an excluded letter" {
    # The boundary is every alphanumeric, not just the body alphabet. `i` can
    # never appear inside a token, but REQ-a3k9z2i is still a typo rather than
    # REQ-a3k9z2 followed by a separator, and reading it as the latter credits
    # a real item for a reference nobody wrote.
    run sh -c '. .guardrails/scripts/lib.sh && printf "%s\n" "# verifies: REQ-a3k9z2i" | gr_id_run "verifies:"'
    [ -z "$output" ] || { echo "harvested: $output"; false; }
}

@test "gr_id_run keeps reading the list after a mistyped ID" {
    # Independent review, S3. The skip left the stray characters in place, so
    # the next ^-anchored match failed and one bad ID discarded every ID after
    # it. The direction was safe — lost coverage reddens — but MISSING-TEST
    # then also named the correctly spelled item, pointing at the wrong line.
    run sh -c '. .guardrails/scripts/lib.sh && printf "%s\n" "# verifies: REQ-a3k9z2x, REQ-b4m8p3" | gr_id_run "verifies:"'
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 1 ] || { echo "harvested: $output"; false; }
    [ "${lines[0]}" = "REQ-b4m8p3" ] || { echo "harvested: $output"; false; }
}

@test "gr_id_run keeps reading after a mistyped ID with an excluded letter too" {
    run sh -c '. .guardrails/scripts/lib.sh && printf "%s\n" "# verifies: REQ-a3k9z2i, REQ-b4m8p3" | gr_id_run "verifies:"'
    [ "${#lines[@]}" -eq 1 ]
    [ "${lines[0]}" = "REQ-b4m8p3" ]
}
