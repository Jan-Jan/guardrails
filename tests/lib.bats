load helpers

setup() { make_fixture_repo; }

# A minimal valid two-unit manifest repo, built by hand: no root config.
# T3's shared fixture will be above this; these tests construct by hand so
# the validator is tested below the fixture that later depends on it.
make_manifest_repo() {
    # setup() has already run make_fixture_repo; calling it again would
    # re-init the same $REPO and fail on an empty fixture commit. Build on it.
    git rm -q .guardrails/config.yaml
    for u in platform/hal apps/pump; do
        mkdir -p "$u/.guardrails" "$u/docs/requirements" "$u/docs/risk" \
                 "$u/docs/architecture" "$u/docs/problems" "$u/src" "$u/tests"
        sed "s|docs/|$u/docs/|; s|- src|- $u/src|; s|- tests|- $u/tests|" \
            > "$u/.guardrails/config.yaml" <<'EOF'
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
        printf '# SOUP\n' > "$u/docs/architecture/soup.md"
        for d in requirements risk architecture problems; do
            printf '# ledger\n' > "$u/docs/$d/README.md"
        done
        : > "$u/src/.gitkeep"
    done
    printf 'depends_on:\n  - platform/hal\n' >> apps/pump/.guardrails/config.yaml
    cat > .guardrails/units.yaml <<'EOF'
units:
  - platform/hal
  - apps/pump
not_a_unit:
  - legacy
EOF
    mkdir -p legacy && printf 'notes\n' > legacy/notes.md
    commit_all manifest
}

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
    [[ "$output" == *"doc_rmf"* ]] || { echo "$output"; false; }
    [[ "$output" == *"docs/risk"* ]] || { echo "$output"; false; }
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

# verifies: PR-tz6gsp
@test "gr_base_branch returns git's status when git worktree list fails, and prints nothing" {
    # Before the status was taken, the failure returned 0 with no output, which
    # is the detached-primary result above, and git's error was discarded.
    git worktree add -q -b feature wt
    cd wt
    status_before=$(git status --porcelain)
    stub_directory=$(make_git_failing_on '*" worktree list "*')
    PATH="$stub_directory:$PATH" run sh -c '. .guardrails/scripts/lib.sh && gr_base_branch 2>/dev/null'
    [ "$status" -eq 128 ] || { echo "$status: $output"; false; }
    [ -z "$output" ] || { echo "printed on failure: $output"; false; }
    # git's own error is passed through, not suppressed.
    PATH="$stub_directory:$PATH" run sh -c '. .guardrails/scripts/lib.sh && gr_base_branch'
    [ "$status" -eq 128 ] || { echo "$status: $output"; false; }
    output_has "fatal: stub failure of git worktree list --porcelain"
    [ "$(git status --porcelain)" = "$status_before" ] \
        || { echo "the worktree changed"; false; }
}

@test "gr_nested_worktrees prints each worktree inside WT, indented, and no sibling" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    git worktree add -q -b outer outer
    git worktree add -q -b sibling outer-sibling
    # Spelled as git records it: $BATS_TEST_TMPDIR can be a symlinked path.
    outer_path=$(git -C outer rev-parse --show-toplevel)
    git -C outer worktree add -q -b inner "$outer_path/.worktrees/inner"
    inner_path=$(git -C outer/.worktrees/inner rev-parse --show-toplevel)
    porcelain=$(git worktree list --porcelain)
    run env wt_list="$porcelain" sh -c '. .guardrails/scripts/lib.sh && gr_nested_worktrees "$1"' _ "$outer_path"
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    [ "$output" = "    $inner_path" ] || { echo "output: $output"; echo "$porcelain"; false; }
}

@test "gr_doc_files dies when a configured directory contains no *.md" {
    rm -f docs/risk/*.md
    run sh -c '. .guardrails/scripts/lib.sh && gr_doc_files doc_rmf'
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_rmf"* ]] || { echo "$output"; false; }
    [[ "$output" == *"no *.md"* ]] || { echo "$output"; false; }
}

@test "gr_prefixes rejects a prefix that is not a bare identifier" {
    sed -i.bak 's/^id_prefixes:.*/id_prefixes: REQ PR[/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    run sh -c '. .guardrails/scripts/lib.sh && gr_prefixes'
    [ "$status" -eq 2 ]
    [[ "$output" == *"bare identifier"* ]] || { echo "$output"; false; }
}

@test "gr_prefixes splits on spaces even when the caller set IFS to newline" {
    run sh -c '. .guardrails/scripts/lib.sh
IFS="
"
gr_prefixes | tr "\n" " "'
    [ "$status" -eq 0 ]
    [[ "$output" == "REQ HAZ RC SDD LLR PR "* ]] || { echo "$output"; false; }
}


@test "gr_check_config accepts the shipped config shape" {
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "gr_check_config accepts a guardrails_commit key" {
    # verifies: PR-dcn2xc
    # The qualification basis is "the suite at the version recorded in
    # config", but a version string moves — upstream can advance mid-change
    # while still reading the same number. The commit is what makes the basis
    # checkable, and the schema is closed, so until the key is known a target
    # project literally cannot record it: exit 2, unknown config key.
    printf 'guardrails_commit: f64be47\n' >> .guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "gr_check_config rejects a declared prefix whose document is unconfigured" {
    sed -i.bak '/^doc_sad:/d' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_sad"* ]] || { echo "$output"; false; }
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
    [[ "$output" == *"- src"* ]] || { echo "$output"; false; }
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
    [[ "$output" == *"- lib"* ]] || { echo "$output"; false; }
}

@test "gr_check_config accepts a document end marker" {
    cat > .guardrails/config.yaml <<'EOF'
id_prefixes: REQ
doc_srs: docs/requirements
strict_paths:
  - src
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
    # The whole reason a token must contain a digit: six letters of the
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

# --- doc_verification and gr_verification_dir -------------------------------
# The one doc_* key with a DEFAULT. Every test below exists because the default
# is the shape that could hide a gate: a key nobody sets, resolving to a path
# nobody checked.

@test "gr_verification_dir defaults to docs/verification" {
    mkdir -p docs/verification
    run sh -c '. .guardrails/scripts/lib.sh && gr_verification_dir'
    [ "$status" -eq 0 ]
    [ "$output" = "docs/verification" ]
}

@test "gr_verification_dir honours a configured doc_verification" {
    mkdir -p docs/evidence
    printf 'doc_verification: docs/evidence\n' >> .guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_verification_dir'
    [ "$status" -eq 0 ]
    [ "$output" = "docs/evidence" ]
}

@test "gr_verification_dir dies when the directory is absent" {
    # The default resolving to nothing must be fatal, not empty. A project that
    # keeps its records elsewhere and never set the key would otherwise get a
    # green review gate over a directory that does not exist.
    run sh -c '. .guardrails/scripts/lib.sh && gr_verification_dir'
    [ "$status" -eq 2 ]
    [[ "$output" == *"docs/verification"* ]] || { echo "$output"; false; }
}

@test "gr_verification_dir dies when a configured directory is absent" {
    printf 'doc_verification: docs/nowhere\n' >> .guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_verification_dir'
    [ "$status" -eq 2 ]
    [[ "$output" == *"docs/nowhere"* ]] || { echo "$output"; false; }
}

@test "doc_verification is a known config key" {
    mkdir -p docs/verification
    printf '# rec\n' > docs/verification/2026-01-01-x.md
    printf 'true\n' > tests/test_a.sh
    printf 'doc_verification: docs/verification\n' >> .guardrails/config.yaml
    commit_all doc-verification-key
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" != *"unknown config key"* ]] || { echo "$output"; false; }
    # And positively: a negative assertion alone is satisfied by a script that
    # is not there, which is the class this suite has now produced five times.
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"checked:"* ]] || { echo "$output"; false; }
}

@test "the shipped config template names only keys the reader knows" {
    # A key in the template that GR_KNOWN_KEYS does not list makes every
    # freshly ratcheted project exit 2 on its first gate run; a key in
    # GR_KNOWN_KEYS that the template never mentions is a gate nobody
    # discovers. Neither is visible from either file alone. Commented-out
    # keys count as documented, not as configured, so only column-one keys
    # are checked here.
    cp "$BATS_TEST_DIRNAME/../templates/config.yaml" .guardrails/config.yaml
    known=$(sh -c '. .guardrails/scripts/lib.sh && printf "%s\n" "$GR_KNOWN_KEYS"')
    used=$(grep -oE '^[A-Za-z_][A-Za-z0-9_]*:' .guardrails/config.yaml | tr -d ':')
    [ -n "$used" ] || { echo "no keys found in the template"; false; }
    for k in $used; do
        printf '%s\n' "$known" | grep -qx "$k" \
            || { echo "template sets '$k', which GR_KNOWN_KEYS does not list"; false; }
    done
    # And every known key is at least mentioned, set or commented out.
    for k in $known; do
        grep -q "^# *$k:\|^$k:" .guardrails/config.yaml \
            || { echo "GR_KNOWN_KEYS has '$k', which the template never mentions"; false; }
    done
}

@test "the shipped config template is accepted by gr_check_config" {
    # The template is what /ratchet copies in. If it does not pass the schema
    # check, every new project's first gate run is exit 2.
    cp "$BATS_TEST_DIRNAME/../templates/config.yaml" .guardrails/config.yaml
    sed -i.bak 's/^safety_class: TBD/safety_class: B/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config && echo accepted'
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *accepted* ]] || { echo "$output"; false; }
}

@test "gr_limit reads a whole number, rejects anything else, and is empty when unset" {
    run sh -c '. .guardrails/scripts/lib.sh && gr_limit problem_age_days && echo "[$?]"'
    [ "$status" -eq 0 ]
    [ "$output" = "[0]" ] || { echo "unset limit was not empty: $output"; false; }

    printf 'problem_open_max: 7\n' >> .guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_limit problem_open_max'
    [ "$status" -eq 0 ]
    [ "$output" = "7" ]

    printf 'problem_age_days:\n' >> .guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_limit problem_age_days'
    [ "$status" -eq 2 ] || { echo "empty value accepted: $status $output"; false; }
    [[ "$output" == *"empty value"* ]] || { echo "$output"; false; }
}

@test "gr_check_config rejects a key set to nothing, whichever key it is" {
    # verifies: PR-8uggn4
    # One `#` in front of one strict_paths item read as an empty list, every
    # traceability scan then walked no paths, and a merge over an undefined-ID
    # reference went from exit 1 to exit 0. The rule had been arriving one key
    # at a time — doc_verification, the two problem limits, verify_commands —
    # and every key it had not reached was a gate a single `#` could switch
    # off. So: every key, scalar and list alike.
    printf '// implements: REQ-zzz9zz\n' > src/main.c
    printf 'true\n' > tests/test_a.sh
    sed -i.bak 's|^  - src$|#  - src|' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    commit_all commented-strict-paths
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [[ "$output" == *"set to nothing"* ]] || { echo "$output"; false; }
    [[ "$output" == *strict_paths* ]] || { echo "$output"; false; }

    # Positive control: restored, the same tree is a genuine failure rather
    # than a pass — which is what the commented-out key was hiding.
    sed -i.bak 's|^#  - src$|  - src|' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    commit_all restored
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    [[ "$output" == *"DANGLING-REF"* ]] || { echo "$output"; false; }

    # And now the half this test named and never reached. gr_check_forms
    # branches on whether the key is in GR_LIST_KEYS: strict_paths above takes
    # the cfg_list arm, and until PR-8uggn4 nothing in this file took the
    # cfg_get arm beside it, so "scalar and list alike" was a claim about one
    # arm. doc_problems is a scalar, and emptying it must be rejected the same
    # way. Measured: with the scalar arm deleted (config-schema M90) this file
    # killed the mutation 0 times and check-review.bats killed it.
    sed -i.bak 's|^doc_problems: .*$|doc_problems:|' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    commit_all emptied-scalar-key
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [[ "$output" == *"set to nothing"* ]] || { echo "$output"; false; }
    [[ "$output" == *doc_problems* ]] || { echo "$output"; false; }

    # The scalar arm gets the same positive control as the list arm: restored,
    # the tree returns to its genuine failure, so it was the empty value that
    # produced exit 2 and not the edit's collateral.
    sed -i.bak 's|^doc_problems:$|doc_problems: docs/problems|' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    commit_all restored-scalar-key
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    [[ "$output" == *"DANGLING-REF"* ]] || { echo "$output"; false; }
}

@test "gr_check_config says so when it cannot read the config at all, before any scan" {
    [ "$(id -u)" -ne 0 ] || skip "root can read a mode-000 file"
    chmod 000 .guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    chmod 644 .guardrails/config.yaml
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [[ "$output" == *"cannot read"* ]] || { echo "$output"; false; }
    # NOT a diagnosis from a later check that happened to notice something
    # missing. That is what four unchecked scans in a row produced.
    [[ "$output" != *"id_prefixes not configured"* ]] || { echo "wrong cause: $output"; false; }
    [[ "$output" == *"cannot open it"* ]] || { echo "$output"; false; }
}

@test "gr_check_config rejects a config whose lines end with bare carriage returns" {
    # A \r-only file is ONE awk record, so every scan accepts it whole and the
    # verdict arrives from an unrelated check naming a cause that is not the
    # cause — the same shape as the unreadable config above, at the one line
    # ending the CRLF handling does not cover.
    tr '\n' '\r' < .guardrails/config.yaml > "$BATS_TEST_TMPDIR/cr.yaml"
    run sh -c '. .guardrails/scripts/lib.sh
        GR_CONFIG="'"$BATS_TEST_TMPDIR"'/cr.yaml" gr_check_config'
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [[ "$output" == *"carriage returns inside a line"* ]] || { echo "$output"; false; }
    [[ "$output" != *"id_prefixes not configured"* ]] || { echo "wrong cause: $output"; false; }
}

@test "cfg_list reads a whole block in a CRLF config" {
    # A blank line in a CRLF file is a line containing one \r, which is
    # neither a space nor a tab — so the "a column-one line ends the block"
    # test fired on it and everything below the blank line was read by nobody.
    # gr_check_config normalises \r before validating, so such a file was
    # pronounced valid: the validator made the byte invisible.
    printf 'verify_commands:\r\n  - echo FIRST\r\n\r\n  - echo SECOND\r\n' \
        >> .guardrails/config.yaml
    del_first_line 'verify_commands:'
    del_first_line '  - make test'
    run sh -c '. .guardrails/scripts/lib.sh && cfg_list verify_commands'
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "${lines[0]}" = "echo FIRST" ] || { echo "$output"; false; }
    [ "${lines[1]}" = "echo SECOND" ] || { echo "second item lost: $output"; false; }
    [ "${#lines[@]}" -eq 2 ] || { echo "$output"; false; }
}

@test "cfg_get reads a scalar in a CRLF config" {
    printf 'safety_class: C\r\n' > "$BATS_TEST_TMPDIR/crlf.yaml"
    run sh -c '. .guardrails/scripts/lib.sh
        GR_CONFIG="'"$BATS_TEST_TMPDIR"'/crlf.yaml" cfg_get safety_class'
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = "C" ] || { echo "[$output]"; false; }
}

@test "a duplicated key is diagnosed as duplicated, even when its first block is empty" {
    # Both readers take the first occurrence, so a key duplicated with an empty
    # first block reaches the emptiness rule and is reported twice under a
    # diagnosis that names neither the duplication nor the block nobody reads.
    # The duplicate check has to run first. Reordering the two checks changes
    # nothing else, which is why nothing else can detect it.
    printf 'verify_commands:\nverify_commands:\n  - make test\n' >> .guardrails/config.yaml
    del_first_line 'verify_commands:'
    del_first_line '  - make test'
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [[ "$output" == *"more than once"* ]] || { echo "$output"; false; }
    [[ "$output" != *"set to nothing"* ]] || { echo "misdiagnosed as empty: $output"; false; }
}

@test "a trailing comment on a list key is a comment, not that key's value" {
    # `strict_paths:  # only these` yielded the value `# only these` because
    # the post-colon blanks were stripped before gr_clean could see the
    # whitespace its ` #` rule needs — so the form rule read a list key as a
    # scalar and rejected the config from every gate. The config file's own
    # rule states a trailing ` # comment` is stripped for EVERY key.
    printf 'true\n' > tests/test_a.sh
    sed -i.bak 's|^strict_paths:$|strict_paths:  # only these are enforced|' \
        .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    # Through a command substitution, which is how every caller reads it.
    run sh -c '. .guardrails/scripts/lib.sh
        v=$(cfg_get strict_paths); printf "[%s]" "$v"'
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = "[]" ] || { echo "value was $output, expected empty"; false; }

    commit_all commented-list-key
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    [[ "$output" != *"wrong form"* ]] || { echo "$output"; false; }
    # And the items are still read: a comment on the key line changes nothing
    # about the block under it.
    [[ "$output" == *"strict 1"* ]] || { echo "$output"; false; }
}

@test "gr_check_config rejects a list key written as a scalar" {
    # `strict_paths: src` breaks no rule the config file states — `id_prefixes:
    # REQ HAZ RC` two lines above is a space-separated scalar — and cfg_list,
    # which is what reads it, finds no items. Every traceability scan then
    # walks no path.
    printf '// traces: REQ-zzz9zz\n' > src/main.c
    printf 'true\n' > tests/test_a.sh
    python3 - <<'PY'
import re
p = '.guardrails/config.yaml'
s = open(p).read()
open(p, 'w').write(s.replace('strict_paths:\n  - src\n', 'strict_paths: src\n'))
PY
    commit_all scalar-strict-paths
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [[ "$output" == *"wrong form"* ]] || { echo "$output"; false; }
    [[ "$output" == *strict_paths* ]] || { echo "$output"; false; }
    # It must NOT read as a clean run over nothing.
    [[ "$output" != *"strict 0"* ]] || { echo "it scanned nothing and said so: $output"; false; }
}

@test "gr_check_config rejects a scalar key written as a list" {
    # The mirror. gr_doc_files reads doc_soup with cfg_get, finds nothing, and
    # returns an empty file list at status 0 — the shape its own header calls
    # forbidden — so the document is scanned by nobody.
    printf 'true\n' > tests/test_a.sh
    python3 - <<'PY'
p = '.guardrails/config.yaml'
s = open(p).read()
open(p, 'w').write(s.replace('doc_soup: docs/architecture/soup.md\n',
                             'doc_soup:\n  - docs/architecture/soup.md\n'))
PY
    commit_all list-doc-soup
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [[ "$output" == *"wrong form"* ]] || { echo "$output"; false; }
    [[ "$output" == *doc_soup* ]] || { echo "$output"; false; }
}

@test "every script stops outside a git repository, at gr_root" {
    # `cd "$(gr_root)" || exit 2` does not fail closed under dash. The fix
    # was merged into all seven scripts and the evidence in one of them, so a
    # mutation reverting the other six was not detected by the whole suite.
    # This asks every script the same question.
    # Run under DASH specifically. `cd ""` returns 0 under dash and 1 under
    # bash, so on a bash-as-/bin/sh platform the old form exits at the `||`
    # and this test passes with the defect present — for every script. dash is
    # /bin/sh on Debian and its derivatives, which is where the defect bites.
    if command -v dash > /dev/null 2>&1; then
        shell=dash
    else
        shell=sh
    fi
    scripts=$PWD/.guardrails/scripts
    mkdir "$BATS_TEST_TMPDIR/norepo"
    cd "$BATS_TEST_TMPDIR/norepo"
    n=0
    for f in "$scripts"/*.sh; do
        [ "$(basename "$f")" != lib.sh ] || continue
        n=$((n + 1))
        run "$shell" "$f"
        [ "$status" -eq 2 ] \
            || { echo "$(basename "$f"): status $status"; echo "$output"; false; }
        # EXACTLY the one diagnosis and nothing after it. Asserting the absence
        # of "config not found" is not enough: check-signing.sh never reads the
        # config, so that string cannot appear either way and the assertion was
        # vacuous for it — it continued and printed git's own errors instead.
        [ "$output" = "guardrails: not inside a git repository" ] \
            || { echo "$(basename "$f") continued past gr_root:"; echo "$output"; false; }
    done
    # Pinned, so a script added later without the guard reddens here rather
    # than being quietly excluded from the question.
    [ "$n" -eq 11 ] || { echo "expected 11 scripts, got $n"; false; }
    [ "$shell" = dash ] || skip "no dash present: this was run under $shell and cannot discriminate"
}

@test "gr_verification_dir rejects a doc_verification set to nothing" {
    # gr_check_config's general rule shadows this branch on every production
    # path, so it is reachable only through a direct call — and without one it
    # was unkillable code, which is what this toolkit states it does not keep.
    # A library function has to be safe called on its own.
    mkdir -p docs/verification
    printf '# rec\n' > docs/verification/2026-01-01-x.md
    printf 'doc_verification:\n' >> .guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_verification_dir'
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [[ "$output" == *"empty value"* ]] || { echo "$output"; false; }
    # NOT the default. Silently falling back would adopt a key whose value the
    # reader could not see, which is the one shape the schema check exists for.
    [[ "$output" != *"docs/verification"*"docs/verification"* ]] || { echo "$output"; false; }
}

@test "gr_prefixes leaves pathname expansion as it found it" {
    run sh -c '. .guardrails/scripts/lib.sh
        set -f
        gr_prefixes > /dev/null
        case $- in (*f*) echo still-off ;; (*) echo LEAKED ;; esac
        set +f
        gr_prefixes > /dev/null
        case $- in (*f*) echo LEAKED-ON ;; (*) echo still-on ;; esac'
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "${lines[0]}" = "still-off" ] || { echo "$output"; false; }
    [ "${lines[1]}" = "still-on" ] || { echo "$output"; false; }
}

@test "gr_prefixes does not let the directory listing decide what a prefix is" {
    # Word splitting drags pathname expansion along with it. Without `set -f`
    # around the split, an id_prefixes entry containing a glob character means
    # one thing in a repository whose root contains a matching name and
    # another everywhere else: the same config, two verdicts, decided by an
    # unrelated file. Here `ADR*` would silently become the valid prefix `ADRx`.
    mkdir ADRx
    sed -i.bak 's|^id_prefixes: .*|id_prefixes: REQ HAZ RC SDD LLR PR ADR*|' \
        .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh -c '. .guardrails/scripts/lib.sh && gr_prefixes'
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [[ "$output" == *"not a bare identifier"* ]] || { echo "$output"; false; }
    [[ "$output" != *ADRx* ]] || { echo "the directory named the prefix: $output"; false; }
}

@test "gr_check_config rejects a list key that names nothing at all" {
    # Absent is the same gate-off as empty, and the emptiness message used to
    # RECOMMEND it. strict_paths is the whole of the source scan's scope: with
    # no entries a reference to an ID nobody defined is never looked for.
    printf '// implements: REQ-zzz9zz\n' > src/main.c
    printf 'true\n' > tests/test_a.sh
    python3 - <<'PY'
p = '.guardrails/config.yaml'
s = open(p).read()
open(p, 'w').write(s.replace('strict_paths:\n  - src\n', ''))
PY
    commit_all no-strict-paths
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [[ "$output" == *"strict_paths names no path"* ]] || { echo "$output"; false; }
    # The exit-0 no-scan state is what this rejects; it must not be reachable.
    [[ "$output" != *"strict 0"* ]] || { echo "it scanned nothing and passed: $output"; false; }
}

@test "gr_check_config rejects a list item with nothing after its dash" {
    # No test covered this rule at all: deleting it left the whole suite green.
    printf 'true\n' > tests/test_a.sh
    printf '  - \n' >> .guardrails/config.yaml
    python3 - <<'PY'
p = '.guardrails/config.yaml'
s = open(p).read()
# Put the blank item inside the strict_paths block rather than at the end,
# and leave a real item after it so the list is not merely empty.
s = s.replace('strict_paths:\n  - src\n', 'strict_paths:\n  - \n  - src\n')
s = s.rstrip('\n')
s = s[: s.rfind('\n  - ')] + '\n'
open(p, 'w').write(s)
PY
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [[ "$output" == *"no value after its '-'"* ]] || { echo "$output"; false; }
    [[ "$output" == *strict_paths* ]] || { echo "$output"; false; }
}

@test "gr_check_config rejects an item that is itself a comment" {
    # `  - # make test` remains the literal string `# make test`, which the
    # shell reads as a comment: the step runs nothing and reports success.
    printf 'true\n' > tests/test_a.sh
    python3 - <<'PY'
p = '.guardrails/config.yaml'
s = open(p).read()
open(p, 'w').write(s.replace('  - make test\n', '  - # make test\n'))
PY
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [[ "$output" == *"commented-out item"* ]] || { echo "$output"; false; }

    # A `#` that is not at the start of the value is a value, not a comment.
    # `^[ \t]*#` would reject this one: in a grep bracket expression `\t` is
    # the set {space, backslash, t}.
    python3 - <<'PY'
p = '.guardrails/config.yaml'
s = open(p).read()
open(p, 'w').write(s.replace('  - # make test\n', '  - t#x\n'))
PY
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config && echo accepted'
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    [[ "$output" == *accepted* ]] || { echo "$output"; false; }
}

@test "a diagnosis quotes the config back without eating its escapes" {
    # gr_die used echo, and /bin/sh here is dash, whose echo de-escapes. A
    # value containing `\c` truncates the message and discards the remedy;
    # one containing `\t` is shown with a tab the operator's file does not have.
    # The malformed-line diagnosis quotes the offending line verbatim, which is
    # the one message here that contains arbitrary operator text.
    printf 'true\n' > tests/test_a.sh
    printf 'this line is not a key \\cREMEDY-GONE\n' >> .guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [[ "$output" == *'\cREMEDY-GONE'* ]] || { echo "escape eaten: $output"; false; }

    # Explicitly under dash where one exists: bash's echo does not process
    # these escapes without xpg_echo, so on a bash-as-/bin/sh platform the
    # assertion above passes against `echo` too and proves nothing.
    if command -v dash > /dev/null 2>&1; then
        run dash -c '. .guardrails/scripts/lib.sh && gr_check_config'
        [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
        [[ "$output" == *'\cREMEDY-GONE'* ]] \
            || { echo "truncated under dash: $output"; false; }
    fi
}

@test "the carriage-return guard inspects every line, not only the first" {
    # A file whose FIRST line ends LF and whose remainder is CR-separated
    # passed a first-line-only check, and every key after the first then
    # collapsed into one record — the wrong-cause verdict the guard exists to
    # prevent.
    python3 - <<'PY'
p = '.guardrails/config.yaml'
s = open(p).read()
first, rest = s.split('\n', 1)
open(p, 'w').write(first + '\n' + rest.replace('\n', '\r'))
PY
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [[ "$output" == *"carriage returns inside a line"* ]] || { echo "$output"; false; }
    [[ "$output" != *"id_prefixes not configured"* ]] || { echo "wrong cause: $output"; false; }
}

@test "coverage_command is a list key, and the bucket is pinned" {
    # Nothing reads this key yet, so its bucket is decided by the template's
    # form alone — which means nothing would notice it being wrong. A key in
    # the wrong bucket is a false rejection for the form that works, or a false
    # green for the form that does not.
    printf 'true\n' > tests/test_a.sh
    printf 'coverage_command:\n  - make coverage\n' >> .guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config && echo accepted'
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    [[ "$output" == *accepted* ]] || { echo "$output"; false; }

    sed -i.bak 's|^coverage_command:$|coverage_command: make coverage|' \
        .guardrails/config.yaml
    sed -i.bak '/^  - make coverage$/d' .guardrails/config.yaml
    rm -f .guardrails/config.yaml.bak
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [[ "$output" == *"wrong form"* ]] || { echo "$output"; false; }
    [[ "$output" == *coverage_command* ]] || { echo "$output"; false; }
}

@test "no test file defines its own teardown, which would drop the tmpdir release" {
    # bats replaces `teardown` wholesale, so the first .bats file to define one
    # silently loses the inode protection for its whole file — and that
    # protection is what keeps a mutation battery from scoring unearned kills.
    cd "$BATS_TEST_DIRNAME"
    n=$(grep -l '^teardown()' ./*.bats 2>/dev/null | wc -l)
    [ "$n" -eq 0 ] || { grep -l '^teardown()' ./*.bats; false; }
    [ "$(grep -c '^teardown()' helpers.bash)" -eq 1 ] \
        || { echo "helpers.bash no longer defines the shared teardown"; false; }
}

# verifies: architecture item 8 — depends_on / segregated_from are per-unit
# list keys the single-unit config accepts
@test "gr_check_config accepts depends_on and segregated_from as list keys" {
    cat >> .guardrails/config.yaml <<'EOF'
depends_on:
  - platform/hal
segregated_from:
  - platform/hal (RC-k3n8p2)
EOF
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 0 ]
}

# verifies: architecture item 8 — a list key written as a scalar is rejected,
# not read as empty
@test "gr_check_config rejects depends_on written in scalar form" {
    printf 'depends_on: platform/hal\n' >> .guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_config'
    [ "$status" -eq 2 ]
    [[ "$output" == *"wrong form"* ]] || { echo "$output"; false; }
}

# verifies: architecture item 8 — expectation limits parse through the same
# gr_limit path as the problem limits
@test "gr_limit parses the expectation limits like the problem limits" {
    printf 'expectation_age_days: 90\nexpectation_open_max: 10\n' >> .guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_limit expectation_age_days && gr_limit expectation_open_max'
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "90" ]
    [ "${lines[1]}" = "10" ]
}

# verifies: architecture item 8 — an unparseable expectation limit is exit 2,
# never a silently disabled gate
@test "gr_limit rejects an unparseable expectation limit" {
    printf 'expectation_age_days: ninety\n' >> .guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_limit expectation_age_days'
    [ "$status" -eq 2 ]
}

# verifies: architecture item 1 groundwork — one parser for every config-shaped
# file: cfg_get/cfg_list read an explicit FILE argument
@test "cfg_get and cfg_list read an explicit second file argument" {
    printf 'units:\n  - packages/pump\n' > other.yaml
    run sh -c '. .guardrails/scripts/lib.sh && cfg_list units other.yaml && cfg_get safety_class'
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "packages/pump" ]
    [ "${lines[1]}" = "B" ]
}

@test "gr_check_units accepts the minimal valid manifest" {
    make_manifest_repo
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 0 ]
}

@test "lib: manifest-shape-errors-are-exit-2 — unknown key" {
    make_manifest_repo
    printf 'unitz:\n  - oops\n' >> .guardrails/units.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"unknown manifest key"* ]] || { echo "$output"; false; }
}

@test "lib: manifest-shape-errors-are-exit-2 — units in scalar form" {
    make_manifest_repo
    printf 'units: platform/hal\n' > .guardrails/units.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
}

@test "lib: manifest-shape-errors-are-exit-2 — duplicate entry across lists" {
    make_manifest_repo
    printf '  - platform/hal\n' >> .guardrails/units.yaml   # under not_a_unit:
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"more than once"* ]] || { echo "$output"; false; }
}

@test "lib: manifest-shape-errors-are-exit-2 — nested unit" {
    make_manifest_repo
    mkdir -p platform/hal/drivers/.guardrails
    cp platform/hal/.guardrails/config.yaml platform/hal/drivers/.guardrails/ 2>/dev/null || true
    printf '  - platform/hal/drivers\n' >> .guardrails/units.yaml  # appends to not_a_unit:
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"overlap"* ]] || { echo "$output"; false; }
}

@test "lib: manifest-shape-errors-are-exit-2 — missing unit config" {
    make_manifest_repo
    rm apps/pump/.guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"no .guardrails/config.yaml"* ]] || { echo "$output"; false; }
}

@test "lib: manifest-shape-errors-are-exit-2 — glob character in an entry" {
    make_manifest_repo
    printf '  - packages/*\n' >> .guardrails/units.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
}

@test "lib: manifest-shape-errors-are-exit-2 — trailing slash, dot, escape" {
    make_manifest_repo
    for bad in 'legacy2/' '.' '../elsewhere'; do
        cp .guardrails/units.yaml units.bak
        printf '  - %s\n' "$bad" >> .guardrails/units.yaml
        run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
        [ "$status" -eq 2 ]
        mv units.bak .guardrails/units.yaml
    done
}

@test "lib: manifest entry with whitespace is exit 2" {
    make_manifest_repo
    printf '  - two words\n' >> .guardrails/units.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
}

@test "lib: root-config-with-manifest-is-exit-2" {
    make_manifest_repo
    write_config     # recreates root .guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"two authorities"* ]] || { echo "$output"; false; }
}

@test "lib: cycle-is-exit-2" {
    make_manifest_repo
    printf 'depends_on:\n  - apps/pump\n' >> platform/hal/.guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"cycle"* ]] || { echo "$output"; false; }
}

@test "lib: depends_on naming an undeclared unit is exit 2" {
    make_manifest_repo
    printf 'depends_on:\n  - vendor/lib\n' >> platform/hal/.guardrails/config.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"undeclared"* ]] || { echo "$output"; false; }
}

@test "lib: unit-paths-outside-unit-are-exit-2" {
    make_manifest_repo
    sed -i.bak 's|^doc_srs: apps/pump/docs/requirements|doc_srs: platform/hal/docs/requirements|' \
        apps/pump/.guardrails/config.yaml && rm -f apps/pump/.guardrails/config.yaml.bak
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"outside the unit"* ]] || { echo "$output"; false; }
}

@test "lib: a unit config setting doc_verification is exit 2" {
    make_manifest_repo
    printf 'doc_verification: apps/pump/docs/verification\n' >> apps/pump/.guardrails/config.yaml
    mkdir -p apps/pump/docs/verification
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"repository-level"* ]] || { echo "$output"; false; }
}

# --- T3: engagement rule, scope resolver, annotation parser -----------------

# verifies: no-manifest-changes-nothing (plan obligation)
@test "gr_unit_engage is a no-op without a manifest" {
    run sh -c '. .guardrails/scripts/lib.sh && gr_unit_engage && printf "[%s]" "$GR_UNIT"'
    [ "$status" -eq 0 ]
    [ "$output" = "[]" ]
}

# verifies: engagement rule — root config rejected in a manifest repo
@test "gr_unit_engage rejects the default config path in a manifest repo, naming the remedy" {
    make_units_fixture
    run sh -c '. .guardrails/scripts/lib.sh && gr_unit_engage'
    [ "$status" -eq 2 ]
    [[ "$output" == *"multi-unit repository"* ]] || false
    [[ "$output" == *"check-units.sh"* ]] || false
    [[ "$output" == *"GR_CONFIG"* ]] || { echo "$output"; false; }
}

# verifies: engagement rule — undeclared config rejected
@test "gr_unit_engage rejects a GR_CONFIG that is not a declared unit's" {
    make_units_fixture
    mkdir -p vendor/thing/.guardrails
    cp apps/pump/.guardrails/config.yaml vendor/thing/.guardrails/
    GR_CONFIG=vendor/thing/.guardrails/config.yaml \
        run sh -c '. .guardrails/scripts/lib.sh && gr_unit_engage'
    [ "$status" -eq 2 ]
    [[ "$output" == *"not a declared unit"* ]] || { echo "$output"; false; }
}

# verifies: engagement rule — declared unit config resolves to its unit
@test "gr_unit_engage resolves a declared unit's config to its unit" {
    make_units_fixture
    GR_CONFIG=apps/pump/.guardrails/config.yaml \
        run sh -c '. .guardrails/scripts/lib.sh && gr_unit_engage && printf "%s" "$GR_UNIT"'
    [ "$status" -eq 0 ]
    [ "$output" = "apps/pump" ]
}

# verifies: exports-mode-matches-resolution (plan obligation)
@test "gr_exported_reqs lists exactly the exported REQ IDs with their files" {
    make_units_fixture
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units && gr_exported_reqs platform/hal'
    [ "$status" -eq 0 ]
    [[ "$output" == "REQ-h4m2p9	"* ]] || false
    [[ "$output" != *"LLR-"* ]] || { echo "$output"; false; }
}

# verifies: annotation grammar reader (architecture item 3)
@test "gr_req_scan reports expects, opened and RC linkage per block" {
    make_units_fixture
    cat >> apps/pump/docs/requirements/0001-01-01-base.md <<'EOF'

**REQ-e7x2m4**: The software shall rely on platform/hal to bound slew rate. (implements: RC-p4q7t3)
expects: platform/hal
opened: 2026-09-01
EOF
    run sh -c '. .guardrails/scripts/lib.sh && gr_unit_req_scan apps/pump'
    [ "$status" -eq 0 ]
    [[ "$output" == *"REQ-e7x2m4	"*"	EXPECTS	platform/hal"* ]] || false
    [[ "$output" == *"REQ-e7x2m4	"*"	OPENED	2026-09-01"* ]] || false
    [[ "$output" == *"REQ-e7x2m4	"*"	RC	1"* ]] || { echo "$output"; false; }
}

# verifies: consumer resolution over depends_on edges
@test "gr_consumers_of names the units whose depends_on points here" {
    make_units_fixture
    run sh -c '. .guardrails/scripts/lib.sh && gr_consumers_of platform/hal && gr_consumers_of apps/pump'
    [ "$status" -eq 0 ]
    [ "$output" = "apps/pump" ]
}

# verifies: path-to-unit classification (D7 whole-component rule)
@test "gr_unit_of_path classifies unit, disclaimed and unowned paths" {
    make_units_fixture
    run sh -c '. .guardrails/scripts/lib.sh
        gr_unit_of_path apps/pump/src/x.c
        gr_unit_of_path legacy/notes.md
        gr_unit_of_path tools/x.c || echo unowned'
    [ "${lines[0]}" = "apps/pump" ]
    [ "${lines[1]}" = "not_a_unit legacy" ]
    [ "${lines[2]}" = "unowned" ]
}

@test "templates: config template ships the expectation limits set" {
    grep -q '^expectation_age_days: 90$' "$BATS_TEST_DIRNAME/../templates/config.yaml"
    grep -q '^expectation_open_max: 10$' "$BATS_TEST_DIRNAME/../templates/config.yaml"
}

@test "templates: units.yaml template is inert — comments only, no live keys" {
    run grep -cE '^(units|not_a_unit):' "$BATS_TEST_DIRNAME/../templates/units.yaml"
    [ "$output" = "0" ]
}

# --- fix1 finding-3: the manifest engages on its exact byte-name only --------

# verifies: engagement rule (architecture item 2) — byte-exact manifest name
@test "lib: UNITS.YAML on a case-insensitive filesystem never engages gr_units_present" {
    # On APFS (case-insensitive by default) `[ -f .guardrails/units.yaml ]` is
    # also satisfied by UNITS.YAML — a manifest that officially does not exist
    # (check-units.sh rejects the near-miss name at exit 2). On a
    # case-SENSITIVE filesystem -f never matches the near-miss at all, so
    # "not-engaged" is the outcome on both; only the APFS half exercises the
    # byte rule.
    printf 'units:\n  - pkg/a\n' > .guardrails/UNITS.YAML
    run sh -c '. .guardrails/scripts/lib.sh && gr_units_present && echo engaged || echo not-engaged'
    [ "$status" -eq 0 ]
    [ "$output" = "not-engaged" ]
}

# verifies: manifest validation (gr_check_units) — abnormal input: absolute entry
@test "lib: manifest entry that is absolute is exit 2" {
    make_manifest_repo
    printf '  - /abs\n' >> .guardrails/units.yaml
    run sh -c '. .guardrails/scripts/lib.sh && gr_check_units'
    [ "$status" -eq 2 ]
    [[ "$output" == *"absolute"* ]] || { echo "$output"; false; }
}

# --- GR_AWK_ITEM_BLOCK: the annotation keyword predicates -------------------
# TWO predicates, and the pair is the safety property. gr_kw_here is what every
# READER tests; gr_kw_orphan_here is what the ORPHAN-ANNOTATION backstop tests,
# and it is strictly wider. The invariant is a containment — the backstop sees
# at least what every reader sees — never an equality: a reader widened to
# match the backstop lets a quoted form outrank the real one, because every
# reader here is first-occurrence-wins. These probe both predicates directly,
# below every gate that uses them: a gate test can only show the pair agreeing,
# never which of the two moved.

# One GR_AWK_ITEM_BLOCK expression, evaluated against one line. The awk program
# text is the first argument, the input line the second. Exported, because the
# probe runs in a child sh: lib.sh is POSIX sh and every other test here sources
# it the same way.
item_block_probe() {
    export _GR_PROBE_PROG="$1" _GR_PROBE_LINE="$2"
    sh -c '. .guardrails/scripts/lib.sh
           printf "%s\n" "$_GR_PROBE_LINE" |
               LC_ALL=C awk "$GR_AWK_ITEM_BLOCK$_GR_PROBE_PROG"'
}

@test "gr_kw_orphan_here accepts a list marker before the keyword" {
    # verifies: PR-h3wujj
    # The asymmetry this closes: gr_id_run finds `satisfies:` anywhere on the
    # line, so a bulleted annotation is credited inside a block while the
    # backstop could not see the same line outside one. The BACKSTOP is the
    # half that widens — it reports, it takes no value — so a form no reader
    # would read is still reported where it belongs to no item.
    run item_block_probe '{ print (gr_kw_orphan_here($0, "status:") ? "HERE" : "ABSENT") }' \
        '- status: open'
    [ "$status" -eq 0 ]
    [ "$output" = "HERE" ]
}

@test "gr_kw_here rejects a list marker before the keyword" {
    # verifies: PR-h3wujj
    # THE PROPERTY THE TWO REGRESSIONS TURNED ON, pinned so the readers cannot
    # drift onto the backstop's width again. Every scalar reader in this
    # toolkit is first-occurrence-wins, so a reader that accepted this line
    # would let a QUOTED `- status: resolved` outrank an item's own column-one
    # `status: open`, and a quoted `- branch: my-change` claim a record that
    # declares another branch. The backstop above may see more than the
    # readers; the readers may never see more than the backstop.
    run item_block_probe '{ print (gr_kw_here($0, "status:") ? "HERE" : "ABSENT") }' \
        '- status: open'
    [ "$status" -eq 0 ]
    [ "$output" = "ABSENT" ]
}

@test "gr_kw_orphan_here still rejects bare indentation" {
    # verifies: PR-h3wujj
    # SCOPE CONTROL, not a widening. A MARKER is required; indentation alone
    # changes nothing. This is what keeps the indented grammar comments in the
    # ledger templates inert, and it is the property the backstop is built
    # around rather than one it introduces.
    run item_block_probe '{ print (gr_kw_orphan_here($0, "status:") ? "HERE" : "ABSENT") }' \
        '  status: open'
    [ "$status" -eq 0 ]
    [ "$output" = "ABSENT" ]
}

@test "gr_value reads from column one, and composes for the wider position" {
    # gr_value moves with gr_kw_here and with nothing else: substr from
    # length(kw) + 1 assumes the keyword starts at byte one, so against a
    # bulleted line it returns a slice of the keyword itself — which is
    # harmless precisely because no reader tests a bulleted line true. A
    # backstop that wants a value from the wider position composes the two
    # rather than widening gr_value, and the second probe pins that route: the
    # check-review.sh orphan path uses it for its emptiness guard, where a
    # keyword fragment would otherwise never compare equal to the empty string.
    run item_block_probe '{ print "[" gr_value($0, "status:") "]" }' \
        '- status: open'
    [ "$status" -eq 0 ]
    [ "$output" = "[s: open]" ]

    run item_block_probe '{ print "[" gr_value(gr_kw_lead($0), "status:") "]" }' \
        '- status: open'
    [ "$status" -eq 0 ]
    [ "$output" = "[open]" ]
}

# --- the ORDERED-list marker: the same defect, verbatim ---------------------
# Round-2 review, finding 15. The first widening stepped over `-`, `*` and `+`
# and nothing else, so an ordered-list item reproduced PR-h3wujj exactly:
# `1. satisfies: REQ-001` outside every block was reported by nothing at all,
# while gr_id_run credited the same line inside one. A markdown list is
# bulleted OR ordered; a rule that knows only half of that closed half a hole
# and the note above it claimed the whole one.

@test "gr_kw_orphan_here accepts an ordered list marker before the keyword" {
    # verifies: PR-h3wujj
    run item_block_probe '{ print (gr_kw_orphan_here($0, "status:") ? "HERE" : "ABSENT") }' \
        '1. status: open'
    [ "$status" -eq 0 ]
    [ "$output" = "HERE" ]
}

@test "gr_kw_orphan_here accepts the paren form of an ordered marker" {
    # verifies: PR-h3wujj
    # Both delimiters markdown allows, and a multi-digit number with them: the
    # tenth item of a list is no less an item than the first.
    run item_block_probe '{ print (gr_kw_orphan_here($0, "status:") ? "HERE" : "ABSENT") }' \
        '10) status: open'
    [ "$status" -eq 0 ]
    [ "$output" = "HERE" ]
}

@test "gr_kw_orphan_here steps over a run of markers, not just one" {
    # verifies: PR-h3wujj
    # A one-line nested list. Depth is not a reason to lose an orphan, so the
    # stripper consumes a RUN of markers rather than exactly one.
    run item_block_probe '{ print (gr_kw_orphan_here($0, "status:") ? "HERE" : "ABSENT") }' \
        '- 1. status: open'
    [ "$status" -eq 0 ]
    [ "$output" = "HERE" ]
}

@test "gr_kw_here rejects an ordered list marker before the keyword" {
    # verifies: PR-h3wujj
    # SCOPE CONTROL. The widening is the BACKSTOP half and only that half. The
    # readers are first-occurrence-wins, so a reader that took this line would
    # let a quoted `1. status: resolved` outrank the column-one `status: open`
    # an item made for itself — the regression the bulleted form already
    # demonstrated twice.
    run item_block_probe '{ print (gr_kw_here($0, "status:") ? "HERE" : "ABSENT") }' \
        '1. status: open'
    [ "$status" -eq 0 ]
    [ "$output" = "ABSENT" ]
}

@test "gr_kw_orphan_here still rejects a bare number with no delimiter" {
    # verifies: PR-h3wujj
    # SCOPE CONTROL, the ordered twin of "still rejects bare indentation". A
    # MARKER is required, and a run of digits alone is not one — `1 status: of
    # the bus is open` is prose, and a rule that stepped over it would report
    # sentences.
    run item_block_probe '{ print (gr_kw_orphan_here($0, "status:") ? "HERE" : "ABSENT") }' \
        '1 status: open'
    [ "$status" -eq 0 ]
    [ "$output" = "ABSENT" ]
}
