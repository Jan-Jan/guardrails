load helpers

setup() { make_fixture_repo; }

# check-review.sh checks the squash message, the verification record
# (ADR-k3nkv3), in the grammar and at the place ADR-3hsvvq states, with
# gr_message_check. Each code that checker reports is tested in
# tests/lib.bats; the tests here prove that this script finds the message,
# hands it the change's tree, reports what it prints, refuses where there is
# no change, and resolves citations.

# --- the message and its checker --------------------------------------------

@test "check-review: a complete message passes and the summary names it" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    write_message
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    output_has "checked: message $(message_file), findings 0"
}

@test "check-review: no message file is MISSING-RECORD naming the file it read" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "MISSING-RECORD $(message_file)"
    output_has "checked: message $(message_file), findings 0"
}

@test "check-review: the message read is this worktree's, not another's" {
    # verifies: ADR-3hsvvq
    # A message written in the primary checkout answers for no change.
    write_message
    make_change_worktree my-change
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "MISSING-RECORD $(message_file)"
}

@test "check-review: --message FILE reads that file" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    write_message
    mv "$(message_file)" "$BATS_TEST_TMPDIR/elsewhere.msg"
    run sh .guardrails/scripts/check-review.sh --message "$BATS_TEST_TMPDIR/elsewhere.msg"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    output_has "checked: message $BATS_TEST_TMPDIR/elsewhere.msg, findings 0"
    run sh .guardrails/scripts/check-review.sh --message "$BATS_TEST_TMPDIR/absent.msg"
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "MISSING-RECORD $BATS_TEST_TMPDIR/absent.msg"
}

@test "check-review: --message with no value exits 2" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    write_message
    run sh .guardrails/scripts/check-review.sh --message
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    output_has "guardrails: --message needs a file"
}

@test "check-review: the message read is in the worktree's git directory, outside the tree" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    mkdir -p src/deep && : > src/deep/.gitkeep
    commit_all deep
    write_message
    cd src/deep
    run sh "$BATS_TEST_TMPDIR/wt/.guardrails/scripts/check-review.sh"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    read_from=$(printf '%s\n' "$output" | sed -n 's/^checked: message \(.*\), findings 0$/\1/p')
    [ "$read_from" -ef "$(git rev-parse --git-dir)/guardrails-squash.msg" ] || { echo "$output"; false; }
    # Never in the tree the gate measures: the message leaves the checkout clean.
    [ -z "$(git status --porcelain)" ] || { git status --porcelain; false; }
}

@test "check-review: outside a git repository exits 2" {
    # verifies: ADR-3hsvvq
    mkdir -p "$BATS_TEST_TMPDIR/nogit"
    cd "$BATS_TEST_TMPDIR/nogit"
    run env GIT_CEILING_DIRECTORIES="$BATS_TEST_TMPDIR" \
        sh "$REPO/.guardrails/scripts/check-review.sh"
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [ "$output" = "guardrails: not inside a git repository" ] || { echo "$output"; false; }
}

@test "check-review: an unreadable message file is MISSING-RECORD" {
    # verifies: ADR-3hsvvq
    # A message the checker cannot read is no record, as an absent one is.
    make_change_worktree my-change
    write_message
    chmod 000 "$(message_file)"
    if [ -r "$(message_file)" ]; then skip "this user reads a mode 000 file"; fi
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "MISSING-RECORD $(message_file)"
    output_has "checked: message $(message_file), findings 0"
}

@test "check-review: the checker's findings are reported and fail the run" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    write_message '1. code low — no disposition'
    sed -i.bak '/^reviewer:/d' "$(message_file)" && rm -f "$(message_file).bak"
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "INCOMPLETE-RECORD (no reviewer:)"
    output_has "UNDISPOSED-FINDING 1"
    output_has "checked: message $(message_file), findings 1"
}

@test "check-review: the Gate-tree is checked against the change branch's tree" {
    # verifies: ADR-3hsvvq
    # A commit after the message was written moves the tree under it.
    make_change_worktree my-change
    write_message
    printf 'more\n' > later.txt
    commit_all later
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "GATE-TREE (want one Gate-tree: $(git rev-parse 'HEAD^{tree}'), found $(git rev-parse 'HEAD~1^{tree}'))"
}

@test "check-review: a message with no Base trailer is reported as BASE and fails the run" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    write_message
    sed -i.bak '/^Base:/d' "$(message_file)" && rm -f "$(message_file).bak"
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "BASE (want one Base: trailer, found 0)"
}

@test "check-review: an unfilled template fails, its placeholders read as missing" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    cp "$BATS_TEST_DIRNAME/../templates/squash-message.txt" "$(message_file)"
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "INCOMPLETE-RECORD (no reviewer:)"
    output_has "INCOMPLETE-RECORD (no verdict:)"
    output_has "INCOMPLETE-RECORD (no reproduced:)"
    output_has "BASE (want one Base: trailer, found a placeholder)"
    output_has "GATE-TREE (want one Gate-tree: $(git rev-parse 'HEAD^{tree}'), found <tree>)"
    output_has "TESTS (want 1 Tests: trailers, one per verify_commands entry, found 0)"
}

@test "check-review: one Tests trailer is wanted per verify_commands entry in the config" {
    # verifies: ADR-3hsvvq
    printf '  - make lint\n' >> .guardrails/config.yaml
    commit_all "a second verify command"
    make_change_worktree my-change
    write_message
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "TESTS (want 2 Tests: trailers, one per verify_commands entry, found 1)"
    printf 'Tests: make lint 3/3\n' >> "$(message_file)"
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
}

@test "check-review: a config with no verify_commands entry still wants one Tests trailer" {
    # verifies: ADR-3hsvvq
    sed -i.bak -e '/^verify_commands:$/d' -e '/^  - make test$/d' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    if grep -q 'verify_commands' .guardrails/config.yaml; then cat .guardrails/config.yaml; false; fi
    commit_all "no verify command"
    make_change_worktree my-change
    write_message
    sed -i.bak '/^Tests:/d' "$(message_file)" && rm -f "$(message_file).bak"
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "TESTS (want 1 Tests: trailers, one per verify_commands entry, found 0)"
    printf 'Tests: make check 3/3\n' >> "$(message_file)"
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
}

@test "check-review: a configured coverage_command wants a Coverage trailer" {
    # verifies: ADR-3hsvvq
    printf 'coverage_command:\n  - make coverage\n' >> .guardrails/config.yaml
    commit_all "a coverage command"
    make_change_worktree my-change
    write_message
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "COVERAGE (want 1 Coverage: trailers, one per coverage_command, found 0)"
    printf 'Coverage: make coverage 91%%\n' >> "$(message_file)"
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
}

@test "check-review: a finding with no severity is reported as MALFORMED-FINDING and fails the run" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    write_message '1. [fixed: scripts/x.sh] code — no severity'
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "MALFORMED-FINDING 1. [fixed: scripts/x.sh] code — no severity"
    output_has "checked: message $(message_file), findings 1"
}

@test "check-review: a finding cut off from its Findings header by a blank line fails the run" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    write_message ''
    awk '/^reviewer:/ { print "Findings:"; print ""; print "1. code high — undisposed"; print "" }
        { print }' "$(message_file)" > "$BATS_TEST_TMPDIR/msg.new" && mv "$BATS_TEST_TMPDIR/msg.new" "$(message_file)"
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "MALFORMED-FINDING 1. code high — undisposed"
}

@test "check-review: every finding is counted, on a pass and on a failure" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    write_message '1. [fixed: scripts/x.sh] code low — first
   continued on a second line
2. [no change: misread] record — second'
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    output_has "checked: message $(message_file), findings 2"
    write_message '1. [fixed: scripts/x.sh] code low — first
2. code low — second, undisposed'
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "checked: message $(message_file), findings 2"
}

@test "check-review: a disposition in no documented form is MALFORMED-FINDING" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    write_message '1. [wontfix] code low — the first
2. [fixed: scripts/x.sh] code low — the second'
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "MALFORMED-FINDING 1. [wontfix] code low — the first"
    [ "$(printf '%s\n' "$output" | grep -c MALFORMED-FINDING)" -eq 1 ] || { echo "$output"; false; }
}

@test "check-review: # lines are guidance, not findings" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    write_message '# 1. [<disposition>] <tag> — the template example
1. [fixed: scripts/x.sh] code low — the one finding'
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    output_has "checked: message $(message_file), findings 1"
}

# --- never a vacuous pass ---------------------------------------------------

@test "check-review: run on the base branch it exits 2, never 0" {
    # verifies: ADR-3hsvvq
    write_message
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"base branch"* ]] || { echo "$output"; false; }
}

@test "check-review: a detached HEAD exits 2" {
    # verifies: ADR-3hsvvq
    write_message
    git checkout -q --detach
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    # The message is asserted, not just the status: dash exits 2 when it cannot
    # OPEN the script, so a status-only assertion here passes with no script at
    # all — a test that proves the absence of the thing it is testing.
    #
    # And the WHOLE message, not the word "detached": both guards below state
    # "detached", so a substring assertion cannot tell them apart. Mutation M04
    # deleted this guard and the suite stayed green, because a detached HEAD in
    # a single checkout also makes gr_base_branch print nothing and the SECOND
    # guard fired instead. The test named the wrong cause and passed.
    [[ "$output" == *"no change branch can be identified"* ]] \
        || { echo "wrong guard fired: $output"; false; }
}

@test "check-review: a detached PRIMARY checkout exits 2" {
    # verifies: ADR-3hsvvq
    # The second guard, which a single detached checkout also reaches. Here
    # HEAD names a branch perfectly well; what cannot be determined is the
    # base, so whether this IS a change cannot be decided either.
    make_change_worktree my-change
    write_message
    git -C "$REPO" checkout -q --detach
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"base branch cannot be determined"* ]] \
        || { echo "wrong guard fired: $output"; false; }
}

@test "check-review: an invalid config is rejected before the message is read" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    printf 'no_such_key: x\n' >> .guardrails/config.yaml
    commit_all config
    write_message
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"unknown config key"* ]] || { echo "$output"; false; }
}

@test "check-review: an unknown argument is rejected, not ignored" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    write_message
    run sh .guardrails/scripts/check-review.sh --allow-anything
    [ "$status" -eq 2 ]
    [[ "$output" == *"unknown argument"* ]] || { echo "$output"; false; }
}

@test "check-review: --branch is gone: a message belongs to its worktree" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    write_message
    run sh .guardrails/scripts/check-review.sh --branch my-change
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    output_has "guardrails: unknown argument: --branch"
}

# --- the unit manifest: the review record is repository-level ---------------

# commit_unit_change UNIT — commit one file under UNIT on the change branch,
# so UNIT is touched and check-units.sh --impact puts it in the impact set.
commit_unit_change() {
    printf 'work\n' > "$1/src/work.txt"
    git add "$1/src/work.txt"
    git -c commit.gpgsign=false commit -qm "work in $1"
}

@test "check-review: in a manifest repository the manifest is validated and the message read" {
    # verifies: ADR-3hsvvq
    make_units_fixture
    make_change_worktree units-change
    # hal is touched and pump depends on it: both units are in the impact
    # set, and write_message writes one Tests: for each.
    commit_unit_change platform/hal
    write_message
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    output_has "checked: message $(message_file), findings 0"
}

@test "check-review: under a unit manifest one Tests trailer is wanted per verify_commands entry of each unit in the impact set" {
    # verifies: ADR-3hsvvq
    make_units_fixture
    # depends_on follows verify_commands in a unit's config.
    awk '{ print } /^  - make test$/ { print "  - make lint" }' apps/pump/.guardrails/config.yaml \
        > pump.yaml && mv pump.yaml apps/pump/.guardrails/config.yaml
    commit_all "a second verify command in one unit"
    make_change_worktree units-change
    # hal touched, pump its dependent: the impact set is both units.
    commit_unit_change platform/hal
    write_message
    sed -i.bak '/^Tests:/d' "$(message_file)" && rm -f "$(message_file).bak"
    printf 'Tests: platform/hal: make test 4/4\nTests: apps/pump: make test 5/5\n' >> "$(message_file)"
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "TESTS (want 3 Tests: trailers, one per verify_commands entry, found 2)"
    printf 'Tests: apps/pump: make lint 1/1\n' >> "$(message_file)"
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
}

@test "check-review: under a unit manifest no Tests trailer is owed for a unit outside the impact set" {
    # verifies: ADR-3hsvvq
    make_units_fixture
    awk '{ print } /^  - make test$/ { print "  - make lint" }' apps/pump/.guardrails/config.yaml \
        > pump.yaml && mv pump.yaml apps/pump/.guardrails/config.yaml
    commit_all "a second verify command in one unit"
    make_change_worktree units-change
    # pump touched, and nothing depends on it: the impact set is pump alone,
    # smaller than the manifest.
    commit_unit_change apps/pump
    write_message
    sed -i.bak '/^Tests:/d' "$(message_file)" && rm -f "$(message_file).bak"
    printf 'Tests: apps/pump: make test 5/5\nTests: apps/pump: make lint 1/1\n' >> "$(message_file)"
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    printf 'Tests: platform/hal: make test 4/4\n' >> "$(message_file)"
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "TESTS (want 2 Tests: trailers, one per verify_commands entry, found 3)"
}

@test "check-review: under a unit manifest a base commit to another unit after the change forked owes no Tests for it" {
    # verifies: ADR-3hsvvq
    make_units_fixture
    make_change_worktree units-change
    # pump touched, nothing depends on it: the change's impact set is pump.
    commit_unit_change apps/pump
    # main moves on after the fork, in hal, a unit the change never touched
    # and its gate never ran.
    printf 'base work\n' > "$REPO/platform/hal/src/base.txt"
    git -C "$REPO" add platform/hal/src/base.txt
    git -C "$REPO" -c commit.gpgsign=false commit -qm "base work in hal"
    write_message
    sed -i.bak '/^Tests:/d' "$(message_file)" && rm -f "$(message_file).bak"
    printf 'Tests: apps/pump: make test 5/5\n' >> "$(message_file)"
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
}

@test "check-review: under a unit manifest a change already squashed onto main still owes its own units' Tests" {
    # verifies: ADR-3hsvvq
    # After a finish-merge refusal the squash is on main, and the message is
    # checked again from the change worktree: the impact set is the change's,
    # from the merge base, not the empty diff against main's tip.
    make_units_fixture
    make_change_worktree units-change
    # hal touched and pump its dependent: two Tests: owed.
    commit_unit_change platform/hal
    git -C "$REPO" merge -q --squash units-change >/dev/null
    git -C "$REPO" -c commit.gpgsign=false commit -qm "the squash"
    write_message
    sed -i.bak '/^Tests:/d' "$(message_file)" && rm -f "$(message_file).bak"
    printf 'Tests: platform/hal: make test 4/4\nTests: apps/pump: make test 5/5\n' >> "$(message_file)"
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
}

@test "check-review: under a unit manifest an impact set that cannot be computed is exit 2" {
    # verifies: ADR-3hsvvq
    make_units_fixture
    make_change_worktree units-change
    # A path no unit claims: check-units.sh --impact exits 2 on it.
    mkdir -p tools
    printf 'work\n' > tools/work.txt
    git add tools/work.txt
    git -c commit.gpgsign=false commit -qm "an unclaimed path"
    write_message
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "claimed by no unit"
}

@test "check-review: a manifest repo with a broken manifest is exit 2 here too" {
    # verifies: ADR-dy4qcm
    make_units_fixture
    printf 'unitz:\n  - x\n' >> .guardrails/units.yaml
    # Committed, or the change worktree below would check out the CLEAN
    # manifest from HEAD and this test would exercise nothing.
    commit_all broken-manifest
    make_change_worktree units-change
    write_message
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    # The exit 2 must come from the manifest validator, not from the absent
    # root config: pre-manifest, "config not found" also exited 2 here, and
    # that green would have proven nothing.
    [[ "$output" == *"unknown manifest key"* ]] || { echo "$output"; false; }
}

# verifies: C2 (docs/plans/2026-10-08-check-review-cite.md)
@test "check-review --cite: under a unit manifest exits 2 naming multi-unit repositories" {
    make_units_fixture
    make_change_worktree units-change
    write_message
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    output_has "multi-unit repositories"
}

# --- a git step whose failure would read as a state -------------------------

# verifies: PR-tz6gsp
@test "check-review: a failed git worktree list exits 2, is not read as a detached primary checkout" {
    # Before gr_base_branch took the status, its failure printed nothing, and
    # the run exited 2 with "the primary checkout is detached".
    make_change_worktree my-change
    write_message
    head_before=$(git rev-parse HEAD)
    stub_directory=$(make_git_failing_on '*" worktree list "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "git worktree list failed, so the base branch cannot be read."
    output_lacks "detached"
    [ -z "$(git status --porcelain)" ] || { echo "the worktree changed"; false; }
    [ "$(git rev-parse HEAD)" = "$head_before" ] || { echo "HEAD moved"; false; }
}

# verifies: PR-tz6gsp
@test "check-review: a failed git branch --show-current exits 2 with git's error, not as a detached HEAD" {
    make_change_worktree my-change
    write_message
    stub_directory=$(make_git_failing_on '*" branch --show-current "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "fatal: stub failure of git branch --show-current"
    output_lacks "detached"
}

# --- --cite and review_cite: a disposition cites what it changed ------------
#
# Under `--cite` or `review_cite: on`, a disposition must cite a path in the
# tree, a test name in test_paths or a defined item ID, or say
# `no change: <reason>` (ADR-3hsvvq). The disposition is the text inside the leading
# `[...]` of its finding's line (ADR-k3nkv3).

# write_review DISPOSITION_TEXT — the message, with one code finding answered
# by DISPOSITION_TEXT.
write_review() {
    write_message "1. [$1] code low — x"
}

# A defined PR item, for find-items.sh show to find.
write_defined_pr() {
    printf '\n**PR-b7k2m4**: a defined problem\nstatus: open\n' \
        >> docs/problems/README.md
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a disposition citing an existing path passes" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'fixed: scripts/x.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a path with a line or a line range passes" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'fixed: `scripts/x.sh:12`.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "line: $output"; false; }
    write_review 'fixed: (scripts/x.sh:3-9),'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "range: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a disposition citing a path not in the tree fails" {
    make_change_worktree my-change
    write_review 'fixed: scripts/missing.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1 (cites no path in the tree, test name in test_paths or defined item ID, and is not \"no change: <reason>\")"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a bats test name in backticks resolves in test_paths" {
    make_change_worktree my-change
    mkdir -p tests && printf '@test "the test name" {\n    true\n}\n' > tests/x.bats
    write_review 'fixed: `the test name` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a backtick span no test in test_paths names fails" {
    make_change_worktree my-change
    mkdir -p tests && printf '@test "another test" {\n    true\n}\n' > tests/x.bats
    write_review 'fixed: `the test name` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a def in test_paths resolves an identifier span" {
    make_change_worktree my-change
    mkdir -p tests && printf 'def test_thing():\n    assert True\n' > tests/test_x.py
    write_review 'fixed: `test_thing` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a span a test file quotes but no test is named does not resolve" {
    make_change_worktree my-change
    mkdir -p tests && printf '@test "merges" {\n    run git merge "merge"\n}\n' > tests/x.bats
    write_review 'fixed: the `merge` path is guarded.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a bats test name resolves only as the whole @test name" {
    make_change_worktree my-change
    mkdir -p tests && printf '  @test "the test name" {\n    true\n}\n' > tests/x.bats
    write_review 'fixed: `the test name` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "whole: $output"; false; }
    write_review 'fixed: `the test` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "prefix: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a jest it() name resolves" {
    make_change_worktree my-change
    mkdir -p tests && printf "it('adds two numbers', () => {\n  expect(1 + 1).toBe(2);\n});\n" > tests/sum.test.js
    write_review 'fixed: `adds two numbers` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a def that does not begin with test is not a test name" {
    make_change_worktree my-change
    mkdir -p tests && printf 'def helper():\n    return 1\n' > tests/test_x.py
    write_review 'fixed: `helper` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a shell function in test_paths is not a test name" {
    make_change_worktree my-change
    mkdir -p tests && printf 'function helper {\n    true\n}\nother() {\n    true\n}\n' > tests/helpers.bash
    write_review 'fixed: `helper` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "function: $output"; false; }
    write_review 'fixed: `other` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "name(): $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a Rust fn resolves an identifier span" {
    make_change_worktree my-change
    mkdir -p tests && printf '#[test]\nfn adds_two() {\n    assert_eq!(2, 1 + 1);\n}\n' > tests/sum.rs
    write_review 'fixed: `adds_two` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a test name in double quotes resolves as a test name" {
    make_change_worktree my-change
    mkdir -p tests && printf '@test "the test name" {\n    true\n}\n' > tests/x.bats
    write_review 'fixed: "the test name" reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a double-quoted span no test is named fails" {
    make_change_worktree my-change
    mkdir -p tests && printf '@test "another test" {\n    true\n}\n' > tests/x.bats
    write_review 'fixed: "the test name" reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a directory is not a citation" {
    make_change_worktree my-change
    write_review 'fixed: `docs/`.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "docs/: $output"; false; }
    write_review 'fixed: leading ./ removed.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "./: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: .git is not a citation, as a file or a directory" {
    make_change_worktree my-change
    [ -f .git ]
    write_review 'fixed: it copies the `.git` file.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo ".git: $output"; false; }
    write_review 'fixed: see ./.git now.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "./.git: $output"; false; }
}

@test "check-review --cite: .//.git/HEAD does not resolve where .git is a directory" {
    # verifies: ADR-3hsvvq
    # A change worktree whose top holds a .git directory with a HEAD file, its
    # git directory given by GIT_DIR, as in a primary checkout: the leading ./
    # and the doubled slash are stripped, and git lists nothing under .git.
    make_change_worktree my-change
    admin=$(git rev-parse --absolute-git-dir)
    rm .git
    mkdir .git
    printf 'ref: refs/heads/my-change\n' > .git/HEAD
    export GIT_DIR="$admin" GIT_WORK_TREE="$PWD"
    [ "$(git branch --show-current)" = my-change ]
    write_review 'fixed: see .//.git/HEAD now.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1 "
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a possessive path resolves" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review "fixed: \`scripts/x.sh\`'s guard now runs."
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "straight: $output"; false; }
    write_review 'fixed: scripts/x.sh’s guard now runs.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "curly: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a possessive ID in backticks resolves" {
    make_change_worktree my-change
    write_defined_pr
    write_review "open: it is \`PR-b7k2m4\`'s brief."
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a bare possessive ID resolves" {
    make_change_worktree my-change
    write_defined_pr
    write_review "fixed: PR-b7k2m4's resolution line now says so."
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "straight: $output"; false; }
    write_review 'fixed: PR-b7k2m4’s resolution line now says so.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "curly: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a git rev:path names its path" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'fixed: checked with `git show 650f090:scripts/x.sh`.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a defined PR ID resolves" {
    make_change_worktree my-change
    write_defined_pr
    write_review 'open: PR-b7k2m4.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a well-formed undefined PR ID fails" {
    make_change_worktree my-change
    write_defined_pr
    write_review 'open: PR-c8n3p5.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1"
}

# verifies: ADR-3hsvvq
@test "check-review --cite: no change: with a reason passes" {
    make_change_worktree my-change
    write_review 'no change: the reviewer misread the call site'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: no change needed. is not the escape" {
    make_change_worktree my-change
    write_review 'no change needed.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1"
    # verifies: ADR-3hsvvq
    output_has "MALFORMED-FINDING 1. [no change needed.] code low — x"
}

# verifies: ADR-3hsvvq
@test "check-review --cite: no change: with no reason after the colon fails" {
    make_change_worktree my-change
    write_review 'no change:'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1"
    # verifies: ADR-3hsvvq
    output_has "MALFORMED-FINDING 1. [no change:] code low — x"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md); C1 (docs/plans/2026-10-08-check-review-cite.md)
@test "check-review: review_cite: on without the flag checks citations" {
    make_change_worktree my-change
    printf 'review_cite: on\n' >> .guardrails/config.yaml
    write_review 'fixed: as asked.'
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1"
}

# verifies: C1 (docs/plans/2026-10-08-check-review-cite.md)
@test "check-review: review_cite: off without the flag does not check citations" {
    make_change_worktree my-change
    printf 'review_cite: off\n' >> .guardrails/config.yaml
    write_review 'fixed: as asked.'
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    output_lacks "citations"
}

# verifies: C1 (docs/plans/2026-10-08-check-review-cite.md)
@test "check-review: review_cite with a value other than on or off exits 2" {
    make_change_worktree my-change
    printf 'review_cite: yes\n' >> .guardrails/config.yaml
    write_review 'fixed: as asked.'
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    output_has "review_cite"
    output_has "'yes'"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: the checked: line counts the dispositions cite-checked" {
    make_change_worktree my-change
    write_review 'no change: the reviewer misread the call site'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"; citations checked over 1 dispositions" ]] || { echo "$output"; false; }
}

# --- review round 1: the guards and branches no test reached ----------------

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: an absolute path does not resolve, though the file exists" {
    make_change_worktree my-change
    abs_file="$BATS_TEST_TMPDIR/outside.txt"
    printf 'x\n' > "$abs_file"
    write_review "fixed: $abs_file."
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a path with a .. component does not resolve, though the file exists" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'fixed: scripts/../scripts/x.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "inside: $output"; false; }
    printf 'x\n' > "$BATS_TEST_TMPDIR/outside.txt"
    write_review 'fixed: ../outside.txt.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "outside: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a URL does not resolve, though a file at its path exists" {
    make_change_worktree my-change
    mkdir -p http: && printf 'x\n' > http:/x.sh
    write_review 'fixed: see http://x.sh for the guard.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: find-items.sh failing on an ID candidate exits 2, never resolves or fails it" {
    make_change_worktree my-change
    rm docs/risk/README.md
    write_review 'open: PR-b7k2m4.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    output_has "find-items.sh show PR-b7k2m4 failed"
    output_lacks "UNRESOLVABLE-DISPOSITION"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a test_paths search that fails exits 2, never reads as no test" {
    make_change_worktree my-change
    sed -i.bak 's|^  - tests$|  - :(bogus)tests|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    write_review 'fixed: `the test name` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    output_has "cannot search test_paths for a test name"
    output_lacks "UNRESOLVABLE-DISPOSITION"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a Go func Test resolves an identifier span" {
    make_change_worktree my-change
    mkdir -p tests && printf 'package x\n\nfunc TestThing(t *testing.T) {\n}\n' > tests/x_test.go
    write_review 'fixed: `TestThing` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a jest test() and describe() name resolves" {
    make_change_worktree my-change
    mkdir -p tests && printf 'describe("the sum", () => {\n  test(%s, () => {});\n});\n' "'adds two numbers'" > tests/sum.test.js
    write_review 'fixed: `adds two numbers` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "test(): $output"; false; }
    write_review 'fixed: `the sum` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "describe(): $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a test_paths entry is a git pathspec, as check-trace.sh reads it" {
    make_change_worktree my-change
    sed -i.bak 's|^  - tests$|  - *_test.go|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    mkdir -p pkg && printf 'package x\n\nfunc TestThing(t *testing.T) {\n}\n' > pkg/x_test.go
    write_review 'fixed: `TestThing` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a test declared only in a gitignored file does not resolve" {
    make_change_worktree my-change
    mkdir -p tests/vendor && printf '@test "the test name" {\n    true\n}\n' > tests/vendor/x.bats
    printf 'tests/vendor/\n' > .gitignore
    write_review 'fixed: `the test name` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a symlink to a file outside the repository does not resolve" {
    make_change_worktree my-change
    printf 'x\n' > "$BATS_TEST_TMPDIR/outside.txt"
    ln -s "$BATS_TEST_TMPDIR/outside.txt" linked.txt
    write_review 'fixed: see linked.txt.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a gitignored file does not resolve" {
    make_change_worktree my-change
    mkdir -p ignored && printf 'echo\n' > ignored/x.sh
    printf 'ignored/\n' > .gitignore
    write_review 'fixed: ignored/x.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: an untracked file git does not ignore resolves" {
    # A file the change adds is often untracked at merge-change step 6c.
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/new.sh
    write_review 'fixed: scripts/new.sh is added.'
    [ -n "$(git ls-files --others --exclude-standard -- scripts/new.sh)" ]
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a backtick span naming a path with a space resolves" {
    make_change_worktree my-change
    mkdir -p "dir with space" && printf 'echo\n' > "dir with space/y.sh"
    write_review 'fixed: `dir with space/y.sh`.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a path led by ./ or .// resolves to the file it names" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'fixed: ./scripts/x.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "./: $output"; false; }
    write_review 'fixed: .//scripts/x.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo ".//: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a tracked file deleted from the working tree does not resolve" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    commit_all tracked
    rm scripts/x.sh
    write_review 'fixed: scripts/x.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1"
}

# --- review round 2: the text boundary, the record itself, citation forms ---

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a markdown link names its target path" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'fixed: [the guard](scripts/x.sh).'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a #anchor suffix is stripped from a path" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'fixed: scripts/x.sh#L12.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "#L12: $output"; false; }
    write_review 'fixed: [the guard](scripts/x.sh#L3-L9).'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "link #L3-L9: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a commented-out declaration declares no test" {
    make_change_worktree my-change
    mkdir -p tests && printf '# def test_thing():\n#     assert True\n' > tests/test_x.py
    write_review 'fixed: `test_thing` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "#: $output"; false; }
    rm tests/test_x.py
    printf 'package x\n\n  // func TestThing(t *testing.T) {\n' > tests/x_test.go
    write_review 'fixed: `TestThing` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "//: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a Go testify suite method declares its test" {
    make_change_worktree my-change
    mkdir -p tests && printf 'package x\n\nfunc (s *SumSuite) TestThing() {\n}\n' > tests/x_test.go
    write_review 'fixed: `TestThing` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a # is kept where what precedes it is no path" {
    # The anchor is stripped from a path candidate only: notes#1.txt is a
    # file name, since `notes` names nothing.
    make_change_worktree my-change
    printf 'x\n' > 'notes#1.txt'
    write_review 'fixed: see notes#1.txt.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# --- review round 3: the guards the round-2 tests left unpinned -------------

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: an absolute path does not resolve where the same path relative to the root is a file" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'fixed: /scripts/x.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1 "
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: def test_thing_extra does not declare test_thing" {
    make_change_worktree my-change
    mkdir -p tests && printf 'def test_thing_extra():\n    assert True\n' > tests/test_x.py
    write_review 'fixed: `test_thing` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1 "
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a hex prefix shorter than 7 or longer than 40 digits is no git rev" {
    # Each prefix below is lowercase hex, so only its length keeps it from
    # being read as a <rev>: — `face` is a word that happens to be hex.
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    for prefix in abc face abcdef 0123456789abcdef0123456789abcdef012345678; do
        write_review "fixed: $prefix:scripts/x.sh."
        run sh .guardrails/scripts/check-review.sh --cite
        [ "$status" -eq 1 ] || { echo "$prefix: $output"; false; }
        output_has "UNRESOLVABLE-DISPOSITION 1 "
    done
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a test declared outside test_paths does not resolve" {
    # test_paths is `tests`; scripts/y.bats is neither ignored nor under it.
    make_change_worktree my-change
    mkdir -p scripts && printf '@test "outside name" {\n    true\n}\n' > scripts/y.bats
    write_review 'fixed: `outside name` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1 "
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: with no test_paths no span resolves as a test name" {
    # gr_check_config requires test_paths only where REQ or LLR is declared,
    # so the config drops both prefixes before it drops the key.
    make_change_worktree my-change
    sed -i.bak -e 's|^id_prefixes: .*$|id_prefixes: HAZ RC SDD PR|' \
        -e '/^test_paths:$/,/^  - tests$/d' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    ! grep -q 'test_paths' .guardrails/config.yaml || { cat .guardrails/config.yaml; false; }
    mkdir -p tests && printf '@test "the name" {\n    true\n}\n' > tests/x.bats
    write_review 'fixed: `the name` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1 "
}

# --- the disposition is the bracket on its finding's line -------------------

@test "check-review: without --cite or review_cite an uncited disposition passes and no citations are counted" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    write_review 'fixed: as asked.'
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    output_lacks "citations"
    output_has "checked: message $(message_file), findings 1"
}

@test "check-review --cite: a citation outside the brackets does not count" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_message '1. [fixed: as asked.] code low — the guard in scripts/x.sh
   is fixed in scripts/x.sh'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 1 (cites no path in the tree, test name in test_paths or defined item ID, and is not \"no change: <reason>\")"
}

@test "check-review --cite: each finding's disposition is judged on its own" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_message '1. [fixed: scripts/x.sh] code low — first
2. [fixed: as asked.] code low — second
3. [no change: the reviewer misread it] guideline low — third'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION 2 (cites no path in the tree, test name in test_paths or defined item ID, and is not \"no change: <reason>\")"
    [ "$(printf '%s\n' "$output" | grep -c UNRESOLVABLE-DISPOSITION)" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"findings 3; citations checked over 3 dispositions" ]] || { echo "$output"; false; }
}

@test "check-review --cite: a record finding may cite the message" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    write_message '1. [fixed: `message`] record — the verdict was missing'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "backticked: $output"; false; }
    write_message '1. [fixed: message] record — the verdict was missing'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "bare: $output"; false; }
}

@test "check-review --cite: a code, requirement or guideline finding citing only the message fails" {
    # verifies: ADR-3hsvvq
    # The message holds no repair a reader could check.
    make_change_worktree my-change
    for tag in 'code low' 'requirement low' 'guideline low'; do
        write_message "1. [fixed: \`message\`] $tag — x"
        run sh .guardrails/scripts/check-review.sh --cite
        [ "$status" -eq 1 ] || { echo "$tag: $output"; false; }
        output_has "UNRESOLVABLE-DISPOSITION 1 (cites no path in the tree, test name in test_paths or defined item ID, and is not \"no change: <reason>\")"
    done
}

# --- --cite and a Mutation: trailer ------------------------------------------

# write_mutation VALUE — the passing message with a `Mutation: VALUE` trailer.
write_mutation() {
    write_message
    printf 'Mutation: %s\n' "$1" >> "$(message_file)"
}

@test "check-review --cite: a Mutation trailer naming a file and a declared test passes" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    mkdir -p scripts tests
    printf 'echo\n' > scripts/x.sh
    printf '@test "the guard holds" {\n    true\n}\n' > tests/x.bats
    write_mutation 'scripts/x.sh:1 echo → true — killed by "the guard holds"'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "check-review --cite: a Mutation trailer naming no file in the tree fails" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    mkdir -p tests
    printf '@test "the guard holds" {\n    true\n}\n' > tests/x.bats
    mutation_trailer='scripts/missing.sh:1 echo → true — killed by "the guard holds"'
    write_mutation "$mutation_trailer"
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-MUTATION $mutation_trailer (scripts/missing.sh is no file in the tree)"
}

@test "check-review --cite: a Mutation trailer naming no declared test fails" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    mkdir -p scripts tests
    printf 'echo\n' > scripts/x.sh
    printf '@test "another test" {\n    true\n}\n' > tests/x.bats
    mutation_trailer='scripts/x.sh:1 echo → true — killed by "the guard holds"'
    write_mutation "$mutation_trailer"
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-MUTATION $mutation_trailer (no test in test_paths is named \"the guard holds\")"
}

@test "check-review: without --cite a Mutation trailer is checked for its form only" {
    # verifies: ADR-3hsvvq
    make_change_worktree my-change
    write_mutation 'scripts/missing.sh:1 echo → true — killed by "no such test"'
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    write_mutation 'scripts/missing.sh echo → true'
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "MALFORMED-MUTATION scripts/missing.sh echo → true"
}
