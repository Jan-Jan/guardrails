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

@test "check-ids: an ID inside the excluded tooling dir is not a duplicate of a minted one" {
    # finalize-ids ignores GR_SCAN_EXCLUDE when picking the next number, so this
    # gate must ignore it too. Otherwise finalize mints an ID that check-ids
    # rejects as already defined on the base, and the merge sequence deadlocks
    # with no permitted way forward.
    #
    # The fixture sits in .guardrails/scripts/ because that — not the whole
    # .guardrails/ tree — is what the scans exclude. A project file one level
    # up is scanned now, and the test below asserts that.
    printf '**REQ-002**: an item inside the tooling dir.\n' > .guardrails/scripts/notes.md
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
    # check-ids.sh calls gr_check_config now, so this fresh repo needs a config
    # the other two gates would already have accepted — the bare id_prefixes
    # line was only ever valid because this one gate validated nothing.
    printf 'id_prefixes: REQ HAZ RC SDD LLR PR
doc_srs: docs/requirements
doc_rmf: docs/risk
doc_sad: docs/architecture
doc_problems: docs/problems
test_paths:
  - tests
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

@test "check-ids: relocating two definitions in one change is not a duplicate" {
    # The header has always promised this: "A definition moved to another file
    # in the same change is NOT flagged". It held for one definition and broke
    # at two, because the removed set is newline-separated and membership was
    # tested with a space-delimited `case`.
    printf '**PR-090**: the first item.\nstatus: open\n' > docs/problems/z.md
    printf '**PR-091**: the second item.\nstatus: open\n' > docs/problems/a.md
    commit_all two-items
    git checkout -qb consolidate
    rm docs/problems/z.md docs/problems/a.md
    printf '\n**PR-090**: the first item.\nstatus: open\n**PR-091**: the second item.\nstatus: open\n' \
        >> docs/problems/README.md
    commit_all consolidated

    run sh .guardrails/scripts/check-ids.sh --base main
    [[ "$output" != *DUPLICATE-ID* ]] || { echo "reported a move as a duplicate: $output"; false; }
    [ "$status" -eq 0 ]
}

@test "check-ids: a real duplicate is still caught alongside a relocation" {
    # The control for the test above: suppression must apply to the IDs that
    # moved and to no others, however many are in the removed set.
    printf '**PR-090**: the first item.\nstatus: open\n' > docs/problems/z.md
    printf '**PR-091**: the second item.\nstatus: open\n' > docs/problems/a.md
    printf '**PR-092**: an item that stays put on main.\nstatus: open\n' > docs/problems/stay.md
    commit_all three-items
    git checkout -qb consolidate
    rm docs/problems/z.md docs/problems/a.md
    printf '\n**PR-090**: the first item.\nstatus: open\n**PR-091**: the second item.\nstatus: open\n' \
        >> docs/problems/README.md
    printf '\n**PR-092**: minted again over here.\nstatus: open\n' >> docs/problems/README.md
    commit_all consolidated

    run sh .guardrails/scripts/check-ids.sh --base main
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID PR-092"* ]]
    [[ "$output" != *"DUPLICATE-ID PR-090"* ]] || { echo "suppression lost PR-090: $output"; false; }
    [[ "$output" != *"DUPLICATE-ID PR-091"* ]] || { echo "suppression lost PR-091: $output"; false; }
}

@test "every gr_def_re call site is still a call site, and no copy joins them" {
    cd "$BATS_TEST_DIRNAME/.."
    # Two assertions, because neither is sufficient on its own and the first
    # two attempts at this test were both false greens.
    #
    # POSITIVE — the number of gr_def_re INVOCATIONS per script. This is the one
    # that cannot be out-spelled: replace a call site with a hand-rolled regex
    # and this reddens however the replacement is written. Round 1 of review
    # defeated a spelling-based check with single quotes; round 2 defeated its
    # replacement twice, once by swapping every call site in the tree for
    # `[[:digit:]]` copies while the suite stayed 168 ok.
    #
    # SHAPE — a search for a definition form spelled out in a script. Defeatable
    # by construction, since it is a regex describing regexes; kept as defence
    # in depth for a copy ADDED without a call site being removed. Digit classes
    # are folded first so [[:digit:]] and [0123456789] cannot simply walk past.
    calls_check_ids=8
    calls_check_signing=0
    calls_check_trace=2
    calls_finalize_ids=2
    calls_lib=0

    forms_check_ids=1
    forms_check_signing=0
    forms_check_trace=8
    forms_finalize_ids=1
    forms_lib=1

    forms() {
        # Fold the digit-class spellings together, then drop backslashes and
        # both quotes — in separate passes, because a single `tr -d` argument
        # holding a backslash has it read as an escape introducer.
        sed -e 's/\[\[:digit:\]\]/[0-9]/g' -e 's/\[0123456789\]/[0-9]/g' "$1" \
            | tr -d "\\\\" | tr -d "\"'" \
            | grep -nE '\*\*.*-\[0-9\].*\*\*:' || true
    }

    seen=0
    for f in scripts/*.sh; do
        seen=$((seen + 1))
        key=$(basename "$f" .sh | tr '-' '_')
        eval "want_calls=\$calls_$key"
        eval "want_forms=\$forms_$key"
        [ -n "$want_calls" ] && [ -n "$want_forms" ] \
            || { echo "unpinned script (add it to this test): $f"; false; }

        got_calls=$(grep -c '\$(gr_def_re ' "$f" || true)
        [ "$got_calls" -eq "$want_calls" ] || {
            echo "$f: $got_calls gr_def_re call sites, pinned at $want_calls"
            false
        }

        got_forms=$(forms "$f" | grep -c . || true)
        [ "$got_forms" -eq "$want_forms" ] || {
            echo "$f: $got_forms spelled-out definition forms, pinned at $want_forms"
            forms "$f"
            false
        }
    done
    [ "$seen" -eq 5 ] || { echo "expected 5 scripts, scanned $seen"; false; }

    # And the constructor exists exactly once, so the counts above are counts of
    # calls to something real rather than to a name nothing defines.
    [ "$(grep -c '^gr_def_re() {' scripts/lib.sh)" -eq 1 ]
}

@test "check-ids: a definition-form token off column one is reported, not failed" {
    # Anchoring max_final narrowed what holds the mint ceiling up. A project
    # that had such a token was relying on it without knowing; the number it was
    # holding can now be re-minted, and no duplicate gate would see that because
    # they all anchor. So the token is reported — and only reported, because in
    # every case observed it is prose.
    printf 'The report noted `**PR-900**:` as the shape to avoid.\n' \
        >> docs/problems/README.md
    commit_all prose

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"UNANCHORED-DEF"* ]]
    [[ "$output" == *"docs/problems/README.md"* ]]
}

@test "check-ids: an ordinary tree reports no UNANCHORED-DEF" {
    printf '\n**PR-001**: a properly defined problem.\nstatus: open\n' \
        >> docs/problems/README.md
    printf 'Prose that merely names PR-001 and stops there.\n' \
        >> docs/problems/README.md
    commit_all ordinary

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"UNANCHORED-DEF"* ]] || { echo "false positive: $output"; false; }
}

@test "check-ids: an indented definition on the base is not something to collide with" {
    # The base-side scan uses a literal ID, so it cannot go through gr_def_re.
    # It is pinned behaviourally instead: it must anchor like everything else.
    printf '\n  **REQ-002**: indented on main, so not defined at all.\n' \
        >> docs/requirements/0001-01-01-base.md
    commit_all indented-on-main
    git checkout -qb branch
    printf '\n**REQ-002**: properly defined here for the first time.\n' \
        >> docs/requirements/0001-01-01-base.md
    commit_all real-definition
    run sh .guardrails/scripts/check-ids.sh --base main
    [ "$status" -eq 0 ]
    [[ "$output" != *"DUPLICATE-ID"* ]] || { echo "collided with a non-definition: $output"; false; }
}

@test "check-ids: an off-column token below the ceiling is not reported" {
    # Measured on a real corpus before this rule existed: nine UNANCHORED-DEF
    # lines, every one of them ordinary prose ("Resolves **PR-006**: ..."), and
    # not one of them holding a number up — each was below an item that already
    # defined a higher one. The regression this report exists to catch is only
    # possible for a token ABOVE the highest real definition, so that is what it
    # reports. Anything else is noise on every run of a healthy project.
    printf '\n**PR-005**: a properly defined problem.\nstatus: open\n' \
        >> docs/problems/README.md
    printf 'Resolves **PR-003**: an older problem, named in passing.\n' \
        >> docs/problems/README.md
    commit_all below-ceiling

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"UNANCHORED-DEF"* ]] || { echo "noise: $output"; false; }
}

@test "check-ids: an indented token above the ceiling is reported with the ID as written" {
    # The awk that decides this is a hand-rolled definition form in a second
    # dialect (awk has no portable {3,}), so it is pinned by test the same way
    # check-trace.sh's block parsers are. Indented counts as off column one.
    printf '\n**PR-005**: a properly defined problem.\nstatus: open\n' \
        >> docs/problems/README.md
    printf '  **PR-900**: indented, and reserving a number nobody can see.\n' \
        >> docs/problems/README.md
    commit_all indented-above

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"UNANCHORED-DEF PR-900"* ]]
    [[ "$output" == *"above PR-005"* ]] || { echo "ceiling misspelled: $output"; false; }
}

@test "check-ids: the highest item's own definition line does not report itself" {
    # Pins the reasoning that let the leading-definition strip be deleted: an
    # anchored definition is one of the numbers the ceiling is the maximum of,
    # so it is never above it.
    printf '\n**PR-900**: the highest defined problem, at column one.\nstatus: open\n' \
        >> docs/problems/README.md
    commit_all highest

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"UNANCHORED-DEF"* ]] || { echo "reported a real definition: $output"; false; }
}

@test "check-ids: a definition line declares its own ID, not every ID on it" {
    # The gate disagreed with itself: def_re says a line defines the token at
    # its start, while the diff harvest read every ID on that line as newly
    # defined. So an ordinary problem report whose one-sentence description
    # names the requirement it affects was reported as a duplicate of that
    # requirement — and blocked the merge.
    git checkout -qb newpr
    printf '**PR-090**: a new problem caused by REQ-001.\nstatus: open\n' \
        > docs/problems/new.md
    commit_all newpr

    run sh .guardrails/scripts/check-ids.sh --base main
    [ "$status" -eq 0 ]
    [[ "$output" != *"DUPLICATE-ID REQ-001"* ]] || { echo "harvested a mention: $output"; false; }
}

@test "check-ids: the ID a definition line does declare is still caught" {
    printf '\n**PR-090**: defined on main first.\nstatus: open\n' \
        >> docs/problems/README.md
    commit_all on-main
    git checkout -qb newpr
    printf '**PR-090**: minted again over here, mentioning REQ-001 too.\nstatus: open\n' \
        > docs/problems/new.md
    commit_all collide

    run sh .guardrails/scripts/check-ids.sh --base main
    [ "$status" -eq 1 ]
    # The suffix, not just the ID: the in-tree gate also fires on this fixture,
    # and without the suffix this test passed with the base-side scan stubbed
    # out entirely (independent review, finding 5). Removing the definition
    # from main instead would make it a relocation, which is suppressed by
    # design — so the two definitions have to coexist and the message has to
    # be told apart by its wording.
    [[ "$output" == *"DUPLICATE-ID PR-090 (already defined on main)"* ]]
    [[ "$output" != *"DUPLICATE-ID REQ-001"* ]] || { echo "harvested a mention: $output"; false; }
}

@test "check-ids: the ceiling counts the base ref, as finalize-ids does" {
    # Independent review, blocking finding 2: _maxes scanned the worktree only
    # while finalize-ids.sh mints from max(base, worktree). Two gates, two
    # ceilings — the defect class this change exists to end. Here PR-950 lives
    # on main and is deleted by the branch, so the worktree ceiling is PR-005
    # and the real one is PR-950. PR-900 is below it and reserves nothing.
    printf '**PR-950**: a high-numbered item on main.\nstatus: open\n' \
        > docs/problems/high.md
    printf '**PR-005**: a low-numbered item.\nstatus: open\n' \
        > docs/problems/low.md
    commit_all main-items
    git checkout -qb branch
    rm docs/problems/high.md
    printf 'Prose reading `**PR-900**:` which reserves nothing.\n' \
        > docs/problems/prose.md
    commit_all branch-prose

    run sh .guardrails/scripts/check-ids.sh --base main
    [ "$status" -eq 0 ]
    [[ "$output" != *"UNANCHORED-DEF"* ]] || { echo "claimed a false ceiling: $output"; false; }
}

@test "check-ids: a non-ASCII filename does not silently skip the scan" {
    # Independent review, finding 4: git quotes such paths, awk was handed the
    # quoted string as an operand, and the file was never examined — a token
    # reserving a number went unreported while the gate exited 0. The exact
    # false green this toolkit exists to prevent.
    printf '\n**PR-005**: a properly defined problem.\nstatus: open\n' \
        >> docs/problems/README.md
    printf 'A note reading `**PR-902**:` in a file with an accent.\n' \
        > "docs/problems/café.md"
    commit_all accented

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"UNANCHORED-DEF PR-902"* ]] || { echo "file skipped: $output"; false; }
    # And the path is printed readably: git quotes non-ASCII paths by default,
    # and the -z framing the scan relies on happens to suppress that too. Drop
    # the -z and this assertion is what notices.
    [[ "$output" == *"docs/problems/café.md"* ]] || { echo "path unreadable: $output"; false; }
}

@test "check-ids: with no usable base the report says the base was not consulted" {
    # Round 2, finding 2: the ceiling counts the base ref only when there IS
    # one. On a detached HEAD — what a normal CI checkout produces — the report
    # fell back to the worktree ceiling and still asserted "the highest one
    # defined", the same false claim round 1 rejected. It may now be a false
    # alarm and has to say so.
    printf '**PR-950**: a high-numbered item.\nstatus: open\n' > docs/problems/high.md
    printf '**PR-005**: a low-numbered item.\nstatus: open\n' > docs/problems/low.md
    commit_all main-items
    git checkout -qb branch
    rm docs/problems/high.md
    printf 'Prose reading `**PR-900**:` which reserves nothing.\n' > docs/problems/prose.md
    commit_all branch-prose
    git checkout -q --detach

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"UNANCHORED-DEF PR-900"* ]]
    [[ "$output" == *"base ref was not consulted"* ]] || {
        echo "claimed a ceiling it did not check: $output"; false; }
}

@test "check-ids: a colon in a path does not eat the line number" {
    # Round 2, note 8: the report split git grep -n output on the first two
    # colons, so a path containing one donated its tail to the line-number
    # field. The location still reassembled by luck, with the line number gone.
    printf '\n**PR-005**: a properly defined problem.\nstatus: open\n' \
        >> docs/problems/README.md
    printf 'first line\nA note reading `**PR-902**:` on line two.\n' \
        > "docs/problems/a:b.md"
    commit_all colon-path

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"docs/problems/a:b.md:2 —"* ]] || {
        echo "location wrong: $output"; false; }
}

@test "every script parses as POSIX sh" {
    cd "$BATS_TEST_DIRNAME/.."
    # Twice during this change an apostrophe inside a single-quoted awk program
    # closed the quote and left a script that could not be parsed at all. Both
    # times the suite caught it — as 30-odd unrelated failures whose cause took
    # a minute to find. One named test is cheaper.
    seen=0
    for f in scripts/*.sh; do
        seen=$((seen + 1))
        sh -n "$f" || { echo "does not parse: $f"; false; }
    done
    [ "$seen" -eq 5 ] || { echo "expected 5 scripts, scanned $seen"; false; }
}

@test "poisoning gr_def_re changes every gate's verdict" {
    # The behavioural half of AC5, and the only half that has ever held. Three
    # rounds of review defeated text-based checks: a copy in another quoting
    # style, a copy spelled [[:digit:]], a copy split across lines, a copy
    # spelled [-][0-9], a call whose result is discarded on the next line, and a
    # gr_def_re redefined inside the script itself. None of those survives this.
    #
    # Redefining at the END of lib.sh wins over the original by shell rules, so
    # every caller that really goes through lib.sh's constructor is poisoned.
    # A script carrying its own copy — or calling the real one and ignoring it —
    # keeps working, and that is exactly what this test then catches.
    printf '\n**PR-005**: an item defined here.\nstatus: open\n' >> docs/problems/README.md
    printf '**PR-005**: the same ID defined a second time.\nstatus: open\n' \
        > docs/problems/dup.md
    printf '**PR-DRAFT-x-1**: a draft awaiting a number.\nstatus: open\n' \
        > docs/problems/DRAFT-x-new.md
    # check-trace refuses to run when a configured test_paths entry matches no
    # file, so this fixture needs one before its counts can be compared.
    printf 'true\n' > tests/test_a.sh
    commit_all items

    run sh .guardrails/scripts/check-ids.sh --allow-drafts
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID PR-005"* ]] || { echo "baseline wrong: $output"; false; }
    run sh .guardrails/scripts/check-trace.sh
    # The whole count line, not a substring: "PR 1" also matches "PR 10".
    [[ "$output" == *"checked: REQ 1, HAZ 0, RC 0, SDD 0, LLR 0, PR 1"* ]] \
        || { echo "baseline wrong: $output"; false; }
    run sh .guardrails/scripts/finalize-ids.sh --dry-run
    [[ "$output" == *"PR-DRAFT-x-1 -> PR-006"* ]] || { echo "baseline wrong: $output"; false; }

    printf '\ngr_def_re() { printf %%s "ZZ-NO-SUCH-PATTERN-ZZ"; }\n' \
        >> .guardrails/scripts/lib.sh

    run sh .guardrails/scripts/check-ids.sh --allow-drafts
    [ "$status" -eq 0 ] || { echo "check-ids still sees definitions: $output"; false; }
    [[ "$output" != *"DUPLICATE-ID"* ]] || { echo "check-ids has its own copy: $output"; false; }

    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"checked: REQ 0, HAZ 0, RC 0, SDD 0, LLR 0, PR 0"* ]] \
        || { echo "check-trace has its own copy: $output"; false; }

    run sh .guardrails/scripts/finalize-ids.sh --dry-run
    [[ "$output" == *"PR-DRAFT-x-1 -> PR-001"* ]] || {
        echo "finalize-ids has its own ceiling: $output"; false; }
}

@test "check-ids: a path with newlines is reported unreadable, not given a made-up location" {
    # Round 3, blocking finding 2. The guard checked whether the record's second
    # line was numeric, which detects a path carrying ONE newline and misses one
    # carrying three: six lines is exactly two whole records, so the framing
    # realigns and the scan cheerfully reported "(d:1 — ...)" — a location that
    # does not exist. Detect the paths themselves instead of the symptom.
    printf '\n**PR-005**: a properly defined problem.\nstatus: open\n' \
        >> docs/problems/README.md
    f=$'docs/problems/a\n1\nc\nd'
    printf 'note `**PR-902**:` here\n' > "$f"
    commit_all newline-path

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"UNANCHORED-DEF-UNREADABLE"* ]] || {
        echo "framing broke silently: $output"; false; }
    [[ "$output" != *"UNANCHORED-DEF PR-902"* ]] || {
        echo "invented a location: $output"; false; }
}

@test "check-ids: one newline in a path is caught too" {
    printf '\n**PR-005**: a properly defined problem.\nstatus: open\n' \
        >> docs/problems/README.md
    f=$'docs/problems/a\nb.md'
    printf 'note `**PR-902**:` here\n' > "$f"
    commit_all one-newline

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"UNANCHORED-DEF-UNREADABLE"* ]]
}

@test "check-ids: a stock install does not report its own tooling" {
    # AC9. The exclusion narrowed in this change exists only so the installed
    # scripts — whose comments carry `REQ-DRAFT-b-1` and definition-form
    # examples — do not trip the gates they implement. That is the criterion
    # the narrowing trades against, so assert it rather than assume it.
    #
    # Green against main on arrival: it guards the narrowing, and cannot be
    # presented as evidence that the narrowing works.
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ] || { echo "tooling reports itself: $output"; false; }
    [[ "$output" != *"DRAFT-ID"* ]] || { echo "own draft token: $output"; false; }
    [[ "$output" != *"UNANCHORED-DEF"* ]] || { echo "own def form: $output"; false; }

    run sh .guardrails/scripts/finalize-ids.sh --dry-run
    [ "$status" -eq 0 ]
    [ -z "$output" ] || { echo "tooling looks mintable: $output"; false; }
}

@test "check-ids: a draft ID in a project file under .guardrails/ is reported" {
    # AC3. The scan pathspec excluded the whole .guardrails/ tree, so anything
    # a project kept there was invisible to every tree-wide gate. Only the
    # tooling needs excluding.
    mkdir -p .guardrails/docs/requirements
    cat > .guardrails/docs/requirements/DRAFT-x-srs.md <<'EOF'
# SRS

**REQ-DRAFT-x-1**: The pump shall stop on occlusion.
EOF
    commit_all "ledger under .guardrails"

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ] || { echo "draft ID invisible: $output"; false; }
    [[ "$output" == *"DRAFT-ID .guardrails/docs/requirements/DRAFT-x-srs.md"*"REQ-DRAFT-x-1"* ]] \
        || { echo "no DRAFT-ID line for it: $output"; false; }
}

@test "check-ids: a misspelled config key is an error here too" {
    # The general form of the same gap: any shape gr_check_config exists to
    # refuse was refused by two of the three gates.
    sed -i.bak 's/^strict_paths:/strict-paths:/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    commit_all misspelled-key

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 2 ] || { echo "accepted a broken config: $output"; false; }
}

@test "poisoning GR_SCAN_EXCLUDE changes every gate's verdict" {
    # AC8, and the lesson of change D: a lint that greps for the right spelling
    # is defeated by a different spelling. Three earlier attempts at a textual
    # guard were each bypassed — by a single-quoted copy, by a comment that
    # preserved the count, by a shadowing definition. So prove the single source
    # of truth behaviourally: move the exclusion onto src/, and require all
    # three gates to follow it there. A call site still holding its own literal
    # pathspec would not move, and would fail here.
    printf '**REQ-001**: a second definition of the fixture item.\n**REQ-002**: an item outside its ledger.\n**REQ-DRAFT-x-1**: a draft.\nnote `**REQ-900**:` in prose\n' \
        > src/notes.md
    # check-trace.sh runs below, and this file's fixture leaves tests/ empty.
    printf '# verifies: REQ-001\ntrue\n' > tests/test_a.sh
    # An off-column token whose reporting turns on the CEILING rather than on
    # which files are scanned: REQ-002 is at the ceiling while src/ is visible
    # and above it once src/ is excluded. It flips the opposite way from
    # REQ-900 above, so a ceiling scan left holding its own pathspec shows up.
    printf 'note `**REQ-002**:` in prose\n' >> docs/requirements/0001-01-01-base.md
    commit_all poison-fixture

    # Unpoisoned: every gate sees src/.
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-ID src/notes.md"* ]] || { echo "$output"; false; }
    [[ "$output" == *"UNANCHORED-DEF REQ-900"* ]] || { echo "$output"; false; }
    [[ "$output" == *"DUPLICATE-ID REQ-001"* ]] || { echo "$output"; false; }
    [[ "$output" != *"UNANCHORED-DEF REQ-002"* ]] \
        || { echo "REQ-002 is at the ceiling, not above it: $output"; false; }
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"checked: REQ 2,"* ]] || { echo "$output"; false; }
    run sh .guardrails/scripts/finalize-ids.sh --dry-run
    [[ "$output" == *"REQ-DRAFT-x-1 -> REQ-003"* ]] || { echo "$output"; false; }

    printf "\nGR_SCAN_EXCLUDE=':(exclude)src'\n" >> .guardrails/scripts/lib.sh

    # The poison REPLACES the exclusion rather than adding to it — it is one
    # pathspec argument, not a list — so the move is visible from both ends:
    # src/ becomes invisible and .guardrails/scripts/ becomes visible, and the
    # tooling starts reporting the draft token in its own comments. A gate
    # holding its own literal pathspec would move at neither end.
    run sh .guardrails/scripts/check-ids.sh
    [[ "$output" != *"DRAFT-ID src/notes.md"* ]] \
        || { echo "check-ids still scans src: $output"; false; }
    [[ "$output" == *"DRAFT-ID .guardrails/scripts/"* ]] \
        || { echo "check-ids did not follow the exclusion: $output"; false; }
    # the UNANCHORED-DEF machinery is five more call sites, and nothing else
    # in the suite distinguishes them.
    [[ "$output" != *"UNANCHORED-DEF REQ-900"* ]] \
        || { echo "the unanchored-def scan kept its own pathspec: $output"; false; }
    [[ "$output" != *"DUPLICATE-ID REQ-001"* ]] \
        || { echo "the duplicate scan kept its own pathspec: $output"; false; }
    [[ "$output" == *"UNANCHORED-DEF REQ-002"* ]] \
        || { echo "the ceiling scan kept its own pathspec: $output"; false; }

    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"checked: REQ 1,"* ]] \
        || { echo "check-trace has its own pathspec: $output"; false; }

    run sh .guardrails/scripts/finalize-ids.sh --dry-run
    [[ "$output" != *"REQ-DRAFT-x-1 -> "* ]] \
        || { echo "finalize-ids still mints from src: $output"; false; }
    [[ "$output" == *"UNMINTED-DRAFT"*"REQ-DRAFT-b-1"* ]] \
        || { echo "finalize-ids did not follow the exclusion: $output"; false; }
}

@test "poisoning GR_SCAN_EXCLUDE moves the mint ceiling too" {
    # The companion to the test above, which cannot reach max_final: under that
    # poison the tooling stops being excluded, its own REQ-DRAFT-b-1 trips the
    # pre-flight, and finalize-ids never gets as far as printing a mint line.
    # Strip that token from the installed copies first, and the ceiling scans
    # become observable — they are two more call sites, one reading the base ref
    # and one the working tree.
    sed -i.bak 's/REQ-DRAFT-b-1/REQ-REDACTED-b-1/g; s/REQ-DRAFT-b-12/REQ-REDACTED-b-12/g' \
        .guardrails/scripts/lib.sh .guardrails/scripts/finalize-ids.sh
    rm -f .guardrails/scripts/*.bak
    printf '**REQ-002**: raises the ceiling.\n**REQ-DRAFT-y-1**: a draft outside the ledger.\n' \
        > src/notes.md
    printf '\n**REQ-DRAFT-x-1**: a draft.\n' >> docs/requirements/0001-01-01-base.md
    printf '# verifies: REQ-DRAFT-x-1\ntrue\n' > tests/test_a.sh
    commit_all ceiling-fixture

    run sh .guardrails/scripts/finalize-ids.sh --dry-run
    [[ "$output" == *"REQ-DRAFT-x-1 -> REQ-003"* ]] \
        || { echo "ceiling not read from src: $output"; false; }
    # the mint scan and the pre-flight are two further call sites
    [[ "$output" == *"REQ-DRAFT-y-1 -> "* ]] \
        || { echo "mint scan did not see src: $output"; false; }

    printf "\nGR_SCAN_EXCLUDE=':(exclude)src'\n" >> .guardrails/scripts/lib.sh

    run sh .guardrails/scripts/finalize-ids.sh --dry-run
    [[ "$output" == *"REQ-DRAFT-x-1 -> REQ-002"* ]] \
        || { echo "a ceiling scan kept its own pathspec: $output"; false; }
    [[ "$output" != *"REQ-DRAFT-y-1"* ]] \
        || { echo "the mint scan or pre-flight kept its own pathspec: $output"; false; }
}

@test "poisoning GR_SCAN_EXCLUDE moves the duplicate-vs-base scan too" {
    # The one remaining check-ids call site the poisoning fixture above cannot
    # reach: it scans the BASE REF for a definition of an ID this branch added,
    # so it needs a branch and a definition that exists on both sides.
    printf '**REQ-005**: defined on the base, outside its ledger.\n' > src/notes.md
    printf '# verifies: REQ-001\ntrue\n' > tests/test_a.sh
    commit_all base-has-req005
    git checkout -qb feature
    printf '**REQ-005**: minted again here.\nstatus: open\n' > docs/problems/dup.md
    commit_all branch-redefines

    run sh .guardrails/scripts/check-ids.sh --base main
    [[ "$output" == *"DUPLICATE-ID REQ-005 (already defined on main)"* ]] \
        || { echo "base scan did not see src: $output"; false; }

    printf "\nGR_SCAN_EXCLUDE=':(exclude)src'\n" >> .guardrails/scripts/lib.sh

    run sh .guardrails/scripts/check-ids.sh --base main
    [[ "$output" != *"DUPLICATE-ID REQ-005"* ]] \
        || { echo "the base scan kept its own pathspec: $output"; false; }
}
