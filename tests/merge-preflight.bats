# merge-preflight.sh runs merge-change's mechanical checks in a fixed order and
# stops at the first failure. Every test builds a change worktree that passes
# all of them and then breaks exactly one, so the lines printed before the
# failure, the failure's own lines and the absence of anything after it are
# all asserted.

load helpers

# The command task-worktree.sh had before merge and remove replaced it. A
# variable, so the old spelling is not a literal in this file, which the check
# that no remedy names it searches.
retired_command=finish

setup() { make_fixture_repo; }

# The seven checks, in the order the script runs them.
gr_checks="CLEAN-TREE BASE-MERGED IDS TRACE UNITS REVIEW NESTED-WORKTREE"

# A change worktree on my-change with one commit and no verification record.
# The commit adds what a project under guardrails has and the base fixture
# lacks: a file under test_paths, which check-trace.sh requires; the
# verification directory, which check-review.sh requires; and an ignored
# .worktrees/, which keeps a nested task worktree out of `git status`. Leaves
# the shell in the change worktree.
make_change_without_record() {
    make_change_worktree my-change
    mkdir -p tests
    : > tests/.gitkeep
    printf '.worktrees/\n' > .gitignore
    mkdir -p docs/verification
    printf '# Verification records\n' > docs/verification/README.md
    commit_all "change work"
}

# The same, with a verification record, so every check passes.
make_passing_change() {
    make_change_without_record
    write_record mine my-change
    commit_all "record for my-change"
}

# has_line TEXT — $output contains a line exactly equal to TEXT.
has_line() {
    printf '%s\n' "$output" | grep -qxF -- "$1" || { echo "no line '$1' in: $output"; return 1; }
}

# has_prefix TEXT — $output contains a line that begins with TEXT.
has_prefix() {
    printf '%s\n' "$output" | awk -v want="$1" 'index($0, want) == 1 { found = 1 } END { exit !found }' \
        || { echo "no line starting '$1' in: $output"; return 1; }
}

# failed_at CHECK — the checks before CHECK printed `ok` or `skipped`, CHECK
# printed its fix line, and no check after it printed anything.
failed_at() {
    seen=0
    for check in $gr_checks; do
        if [ "$check" = "$1" ]; then
            seen=1
            has_prefix "fix $check: " || return 1
            output_lacks "preflight: $check ok" || return 1
        elif [ "$seen" -eq 0 ]; then
            has_prefix "preflight: $check " || return 1
        else
            output_lacks "preflight: $check " || return 1
            output_lacks "fix $check:" || return 1
        fi
    done
}

# --- the passing run ------------------------------------------------------

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: a change that passes every check prints one line per check and exits 0" {
    make_passing_change
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    expected="preflight: CLEAN-TREE ok
preflight: BASE-MERGED ok
preflight: IDS ok
preflight: TRACE ok
preflight: UNITS skipped (no .guardrails/units.yaml)
preflight: REVIEW ok
preflight: NESTED-WORKTREE ok"
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: --before-review passes with no verification record" {
    make_change_without_record
    run sh .guardrails/scripts/merge-preflight.sh --before-review my-change
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    has_line "preflight: REVIEW skipped (--before-review)"
    has_line "preflight: NESTED-WORKTREE ok"
}

# --- one test per check ---------------------------------------------------

# origin_main_ahead — origin/main has a commit that neither main nor HEAD has.
origin_main_ahead() {
    printf 'remote\n' > "$REPO/remote.txt"
    git -C "$REPO" add remote.txt
    git -C "$REPO" commit -qm "remote work"
    git -C "$REPO" update-ref refs/remotes/origin/main HEAD
    git -C "$REPO" reset -q --hard HEAD~1
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: CLEAN-TREE fails on an untracked file and lists it" {
    make_passing_change
    printf 'stray\n' > stray.txt
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    has_line "?? stray.txt"
    failed_at CLEAN-TREE
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: CLEAN-TREE exits 2 when git status fails" {
    make_passing_change
    # A corrupt index makes git status fail; rev-parse, worktree list and
    # branch --show-current do not read the index.
    printf 'not an index\n' > "$(git rev-parse --git-dir)/index"
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    has_line "fix CLEAN-TREE: git status failed; run it in this worktree and resolve its error."
    output_lacks "preflight: CLEAN-TREE ok"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: BASE-MERGED fails when the base branch has a commit HEAD lacks" {
    make_passing_change
    printf 'later\n' > "$REPO/later.txt"
    git -C "$REPO" add later.txt
    git -C "$REPO" commit -qm "base moves on"
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    failed_at BASE-MERGED
    has_prefix "fix BASE-MERGED: merge the base branch"
    printf '%s\n' "$output" | grep -qF "merge-change step 1" || { echo "$output"; false; }
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: BASE-MERGED fails when origin/<base> has a commit HEAD lacks" {
    make_passing_change
    origin_main_ahead
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    failed_at BASE-MERGED
    printf '%s\n' "$output" | grep -qF "origin/main" || { echo "$output"; false; }
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: --local-base passes BASE-MERGED with origin/<base> ahead of HEAD, and prints that it did" {
    make_passing_change
    origin_main_ahead
    run sh .guardrails/scripts/merge-preflight.sh --local-base my-change
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    has_line "preflight: BASE-MERGED ok (local base only)"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: --local-base still fails BASE-MERGED on a local base HEAD lacks" {
    make_passing_change
    printf 'later\n' > "$REPO/later.txt"
    git -C "$REPO" add later.txt
    git -C "$REPO" commit -qm "base moves on"
    run sh .guardrails/scripts/merge-preflight.sh --local-base my-change
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    failed_at BASE-MERGED
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: --local-base fails BASE-MERGED when a tag named like the base branch is merged and the branch is not" {
    # Before finding-91, the base was passed to git as a bare name, which git
    # resolves to refs/tags/main before refs/heads/main, so the check passed.
    make_passing_change
    merged_commit=$(git -C "$REPO" rev-parse refs/heads/main)
    printf 'later\n' > "$REPO/later.txt"
    git -C "$REPO" add later.txt
    git -C "$REPO" -c commit.gpgsign=false commit -qm "base moves on"
    git -C "$REPO" -c tag.gpgsign=false tag main "$merged_commit"
    run sh .guardrails/scripts/merge-preflight.sh --local-base my-change
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    failed_at BASE-MERGED
    has_line "main is not an ancestor of HEAD."
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: --local-base combines with --before-review, in either order" {
    make_change_without_record
    origin_main_ahead
    for order in "--local-base --before-review" "--before-review --local-base"; do
        # $order is split on purpose: it is two arguments.
        run sh .guardrails/scripts/merge-preflight.sh $order my-change
        [ "$status" -eq 0 ] || { echo "$order: $output"; false; }
        has_line "preflight: BASE-MERGED ok (local base only)"
        has_line "preflight: REVIEW skipped (--before-review)"
    done
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: the usage line names --local-base" {
    make_passing_change
    run sh .guardrails/scripts/merge-preflight.sh --no-such-flag my-change
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    output_has "[--local-base]"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: BASE-MERGED passes when origin/<base> is merged" {
    make_passing_change
    git -C "$REPO" update-ref refs/remotes/origin/main main
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    has_line "preflight: BASE-MERGED ok"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: IDS fails on a draft ID and prints check-ids.sh's own output" {
    make_passing_change
    # The token is built at run time: the literal in this file would be a
    # DRAFT-ID finding against the repository's own tree.
    draft=DRAFT
    printf '\n**REQ-%s-mybranch-1**: a draft item.\n' "$draft" >> docs/requirements/README.md
    commit_all draft
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -qF "DRAFT-ID" || { echo "$output"; false; }
    failed_at IDS
    # The fix line's whole text, so a change to its wording fails here.
    has_line "fix IDS: fix each check-ids.sh finding above; its script header documents every rule."
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: IDS fails on a draft-named ledger file, because check-ids.sh runs without --allow-draft-files" {
    make_passing_change
    # The name is built at run time, as the draft ID above is.
    draft=DRAFT
    ledger_file="docs/requirements/$draft-my-change-extra.md"
    printf '# Extra requirements\n' > "$ledger_file"
    commit_all "draft-named ledger file"
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "DRAFT-FILE"
    output_has "$ledger_file"
    # The pre-flight runs after step 3, so the fix line must name the merge
    # half: a line that only states to leave the file loops on this failure.
    output_has "At merge, run merge-change step 3 (finalize-docs.sh), which renames it"
    failed_at IDS
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: TRACE fails on a requirement with no test and prints check-trace.sh's own output" {
    make_passing_change
    printf '\n**REQ-001**: The system shall exist.\n' >> docs/requirements/README.md
    commit_all "untested requirement"
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -qF "MISSING-TEST" || { echo "$output"; false; }
    failed_at TRACE
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: a passing TRACE shows the warnings check-trace.sh printed" {
    make_passing_change
    # The report affects REQ-001, so REQ-001 exists and has a test: the one
    # finding left is the open report, which is a warning.
    printf '\n**REQ-001**: The system shall exist.\n' >> docs/requirements/README.md
    printf '# verifies: REQ-001\ntrue\n' > tests/test_a.sh
    write_pr PR-001 open "$(days_ago 5)"
    commit_all "open problem report"
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    has_prefix "UNRESOLVED-PR PR-001 "
    has_prefix "fix UNRESOLVED-PR: "
    has_line "preflight: TRACE ok"
    # The warnings come after IDS and before TRACE's ok line, and the summary
    # lines of a passing run stay hidden.
    line_ids=$(printf '%s\n' "$output" | grep -nxF "preflight: IDS ok" | cut -d: -f1)
    line_warn=$(printf '%s\n' "$output" | grep -n "^UNRESOLVED-PR PR-001 " | cut -d: -f1)
    line_fix=$(printf '%s\n' "$output" | grep -n "^fix UNRESOLVED-PR: " | cut -d: -f1)
    line_ok=$(printf '%s\n' "$output" | grep -nxF "preflight: TRACE ok" | cut -d: -f1)
    [ "$line_ids" -lt "$line_warn" ] || { echo "$output"; false; }
    [ "$line_warn" -lt "$line_fix" ] || { echo "$output"; false; }
    [ "$line_fix" -lt "$line_ok" ] || { echo "$output"; false; }
    output_lacks "checked:"
    output_lacks "problems:"
    output_lacks "sources:"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: REVIEW fails with no verification record" {
    make_change_without_record
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -qF "MISSING-RECORD my-change" || { echo "$output"; false; }
    failed_at REVIEW
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: NESTED-WORKTREE fails on a worktree registered inside the change worktree" {
    make_passing_change
    git worktree add -q .worktrees/my-change-t1 -b my-change-t1 my-change
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -qF "my-change-t1" || { echo "$output"; false; }
    failed_at NESTED-WORKTREE
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: NESTED-WORKTREE names remove and discard, and no merging command" {
    # A merge is the dispatcher's decision after a green task report, never a
    # remedy. The fix line names `remove <tag>` for every nested worktree, the
    # review worktree included, discard for a branch remove rejects, and the
    # plain git commands for a worktree task-worktree.sh did not create.
    make_passing_change
    git worktree add -q .worktrees/my-change-review -b my-change-review my-change
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    failed_at NESTED-WORKTREE
    fix_line=$(printf '%s\n' "$output" | grep '^fix NESTED-WORKTREE: ')
    output="$fix_line"
    output_has "task-worktree.sh remove <tag> for .worktrees/my-change-<tag>, the review worktree included"
    output_has "those commits were never gated or reviewed"
    output_has "task-worktree.sh discard <tag>"
    output_has "return to develop-change and rerun merge-change from step 1"
    output_has "git worktree remove <path>"
    output_has "git branch -D <branch>"
    output_lacks "task-worktree.sh merge"
    output_lacks "task-worktree.sh $retired_command"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: NESTED-WORKTREE fails on the no-worktree-registered verdict" {
    # merge-preflight.sh requires the named branch to be the current one, so a
    # real finish-merge.sh always finds a registration here. The verdict is
    # produced by a stand-in that prints it and exits 0, as the real script
    # does, to prove the pre-flight reads an exit 0 with that verdict as a
    # failure.
    make_passing_change
    cat > .guardrails/scripts/finish-merge.sh <<'STUB'
#!/bin/sh
echo "finish-merge --check: no worktree is registered for $2, so nothing was inspected"
exit 0
STUB
    commit_all "stand-in finish-merge.sh"
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    failed_at NESTED-WORKTREE
    has_prefix "fix NESTED-WORKTREE: you named the wrong branch"
}

# --- multi-unit repositories ----------------------------------------------

# make_units_change — the two-unit fixture, a change worktree on my-change
# touching platform/hal, and a record for it.
make_units_change() {
    make_units_fixture
    make_change_worktree my-change
    printf 'more\n' >> platform/hal/src/.gitkeep
    write_record mine my-change
    commit_all "hal change"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: in a multi-unit repository UNITS runs in place of IDS and TRACE" {
    make_units_change
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    expected="preflight: CLEAN-TREE ok
preflight: BASE-MERGED ok
preflight: IDS skipped (run per unit under UNITS)
preflight: TRACE skipped (run per unit under UNITS)
preflight: UNITS ok
preflight: REVIEW ok
preflight: NESTED-WORKTREE ok"
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: UNITS fails on a finding in a dependent unit of the impact set" {
    # The change touches platform/hal only; apps/pump depends on it, so the
    # impact set contains pump, and pump's own trace gate must run.
    make_units_fixture
    printf '\n**REQ-p9t4w2**: The pump shall stop.\n' >> apps/pump/docs/requirements/0001-01-01-base.md
    commit_all "untested pump requirement on the base branch"
    make_change_worktree my-change
    printf 'more\n' >> platform/hal/src/.gitkeep
    write_record mine my-change
    commit_all "hal change"
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -qF "MISSING-TEST" || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -qF "apps/pump" || { echo "$output"; false; }
    failed_at UNITS
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: UNITS reads the impact range from the base branch, not a tag named like it" {
    # The change touches apps/pump only, and hal is not a dependent of pump.
    # A hal requirement with no test is on the base branch, after the commit
    # a tag named main points at. Before finding-91 the range was main..HEAD,
    # which git resolves to the tag, so hal entered the impact set and failed.
    make_units_fixture
    tagged_commit=$(git rev-parse HEAD)
    printf '\n**REQ-h7v3c8**: The hal shall stop.\n' >> platform/hal/docs/requirements/0001-01-01-base.md
    commit_all "untested hal requirement on the base branch"
    make_change_worktree my-change
    printf 'more\n' >> apps/pump/src/.gitkeep
    write_record mine my-change
    commit_all "pump change"
    git -C "$REPO" -c tag.gpgsign=false tag main "$tagged_commit"
    run sh .guardrails/scripts/merge-preflight.sh --local-base my-change
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    output_lacks "platform/hal"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: UNITS fails on a check-ids.sh finding in a unit of the impact set" {
    make_units_change
    # A definition form whose ID has no digit: MALFORMED-ID for check-ids.sh,
    # and no item at all for check-trace.sh, so only the IDS gate of the unit
    # rejects it. Assembled at run time, so this file contains no definition
    # line.
    malformed_id=REQ-abc"def"
    printf '\n**%s**: The hal shall log.\n' "$malformed_id" \
        >> platform/hal/docs/requirements/0001-01-01-base.md
    commit_all "malformed hal requirement"
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    has_line "unit platform/hal: check-ids.sh"
    has_prefix "MALFORMED-ID "
    has_prefix "fix UNITS: in unit platform/hal, fix each check-ids.sh finding above"
    failed_at UNITS
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: a passing UNITS shows a unit's check-trace.sh warnings under that unit's header" {
    make_units_change
    # An open report against hal's traced requirement: UNRESOLVED-PR is a
    # warning, so hal's trace gate exits 0 and UNITS passes. The ID is
    # assembled at run time, so this file contains no definition line that
    # this repository's own check-trace.sh scan reads as an item.
    problem_id=PR-h7c4"n2"
    cat >> platform/hal/docs/problems/README.md <<EOF

**$problem_id**: Crash on empty dose input.
affects: REQ-h4m2p9
opened: $(days_ago 5)
status: open
EOF
    commit_all "open problem report in hal"
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    has_line "unit platform/hal: check-trace.sh"
    has_prefix "UNRESOLVED-PR $problem_id "
    has_line "preflight: UNITS ok"
    line_header=$(printf '%s\n' "$output" | grep -nxF "unit platform/hal: check-trace.sh" | cut -d: -f1)
    line_warn=$(printf '%s\n' "$output" | grep -n "^UNRESOLVED-PR $problem_id " | cut -d: -f1)
    line_ok=$(printf '%s\n' "$output" | grep -nxF "preflight: UNITS ok" | cut -d: -f1)
    [ "$line_header" -lt "$line_warn" ] || { echo "$output"; false; }
    [ "$line_warn" -lt "$line_ok" ] || { echo "$output"; false; }
    output_lacks "unit platform/hal: check-ids.sh"
    output_lacks "checked:"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: UNITS fails on a repository-level check-units.sh finding" {
    make_units_change
    mkdir -p stray
    printf 'unclaimed\n' > stray/file.txt
    commit_all "unclaimed path"
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -qF "UNCLAIMED-PATH" || { echo "$output"; false; }
    failed_at UNITS
}

# --- where it may run: exit 2 ---------------------------------------------

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: a tool that exits 2 makes the pre-flight exit 2 with the tool's output" {
    make_passing_change
    sed -i.bak 's/^strict_paths:/strict-paths:/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    commit_all "misspelled config key"
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 2 ] || { echo "check-ids.sh did not exit 2: $status: $output"; false; }
    tool_output=$output
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    printf '%s\n' "$output" | grep -qF -- "$tool_output" || { echo "$output"; false; }
    failed_at IDS
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: run from the primary checkout it exits 2" {
    run sh .guardrails/scripts/merge-preflight.sh main
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -qF "primary checkout" || { echo "$output"; false; }
    output_lacks "preflight:"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: outside a git repository it exits 2 at once, naming that reason only" {
    outside="$BATS_TEST_TMPDIR/outside"
    mkdir -p "$outside"
    cd "$outside"
    GIT_CEILING_DIRECTORIES="$BATS_TEST_TMPDIR" run sh "$REPO/.guardrails/scripts/merge-preflight.sh" my-change
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "not inside a git repository"
    output_lacks "primary checkout"
    output_lacks "preflight:"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: on the base branch it exits 2" {
    git worktree add -q --force "$BATS_TEST_TMPDIR/wt" main
    cd "$BATS_TEST_TMPDIR/wt"
    run sh .guardrails/scripts/merge-preflight.sh main
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -qF "base branch" || { echo "$output"; false; }
    output_lacks "preflight:"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: a branch that is not the current branch exits 2" {
    make_passing_change
    git branch other-change
    run sh .guardrails/scripts/merge-preflight.sh other-change
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -qF "not the current branch" || { echo "$output"; false; }
    output_lacks "preflight:"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: a detached HEAD exits 2" {
    make_passing_change
    git checkout -q --detach
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -qF "not the current branch" || { echo "$output"; false; }
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: no branch named, or an unknown flag, exits 2 with the usage line" {
    make_passing_change
    run sh .guardrails/scripts/merge-preflight.sh
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -qF "usage: merge-preflight.sh" || { echo "$output"; false; }
    run sh .guardrails/scripts/merge-preflight.sh --skip-review my-change
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -qF "usage: merge-preflight.sh" || { echo "$output"; false; }
    run sh .guardrails/scripts/merge-preflight.sh my-change other-change
    [ "$status" -eq 2 ] || { echo "$output"; false; }
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: an unknown flag is named as one, not read as a branch" {
    make_passing_change
    for args in "--skip-review" "my-change --skip-review"; do
        # $args is split on purpose: it is one or two arguments.
        run sh .guardrails/scripts/merge-preflight.sh $args
        [ "$status" -eq 2 ] || { echo "$args: $status: $output"; false; }
        output_has "unknown argument: --skip-review"
        output_lacks "preflight:"
    done
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: the change branch named twice exits 2 before any check" {
    # Both names are the current branch, so only the one-branch rule rejects
    # the call; every check would pass.
    make_passing_change
    run sh .guardrails/scripts/merge-preflight.sh my-change my-change
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "only one change branch allowed"
    output_lacks "preflight:"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: a detached primary checkout exits 2, because the base branch cannot be determined" {
    make_passing_change
    git -C "$REPO" checkout -q --detach
    run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "the base branch cannot be determined"
    output_lacks "preflight:"
}

# --- portability ----------------------------------------------------------

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: passes under an awk that rejects a newline in -v" {
    # This script calls awk itself (the impact set's unit column) and through
    # lib.sh, so it belongs to the strict-awk sweep that the comment on
    # "every check script runs clean under an awk that rejects a newline in -v"
    # (tests/portability.bats) describes. The multi-unit run is the one whose
    # impact set has more than one line.
    make_units_change
    bin=$(make_strict_awk)
    PATH="$bin:$PATH" run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    has_line "preflight: UNITS ok"
    has_line "preflight: NESTED-WORKTREE ok"
}

# --- fail-closed awk guards -----------------------------------------------

# make_failing_awk PROGRAM — a directory to put first on PATH, with an awk that
# exits 2 when one of its arguments is exactly PROGRAM and runs the real awk
# for every other call.
make_failing_awk() {
    real_awk=$(command -v awk)
    stub_dir="$BATS_TEST_TMPDIR/failing-awk"
    mkdir -p "$stub_dir"
    printf '%s\n' "$1" > "$stub_dir/program"
    cat > "$stub_dir/awk" <<STUB
#!/bin/sh
failing_program=\$(cat "$stub_dir/program")
for argument in "\$@"; do
    if [ "\$argument" = "\$failing_program" ]; then
        echo "awk: stub failure" >&2
        exit 2
    fi
done
exec "$real_awk" "\$@"
STUB
    chmod +x "$stub_dir/awk"
    printf '%s\n' "$stub_dir"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: an awk failure while reading a check's warnings exits 2" {
    make_passing_change
    bin=$(make_failing_awk '/^(checked|units): / { exit } { print }')
    PATH="$bin:$PATH" run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    has_line "fix IDS: run the tool the check names and resolve its error."
    output_lacks "preflight: IDS ok"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: an awk failure while reading the impact set's unit column exits 2" {
    make_units_change
    bin=$(make_failing_awk 'NF { print $1 }')
    PATH="$bin:$PATH" run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    has_line "fix UNITS: run check-units.sh --impact refs/heads/main..HEAD and resolve its error."
    output_lacks "preflight: UNITS ok"
}

# --- a git step whose failure would read as a state -----------------------

# make_git_failing_on is defined in tests/helpers.bash.

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: a failed git rev-parse --git-dir exits 2 before any check" {
    # Before the status was taken, an empty git dir differed from the common
    # git dir, and the primary-checkout check passed.
    make_passing_change
    stub_directory=$(make_git_failing_on '*" rev-parse --git-dir "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "git rev-parse --git-dir failed, so whether this is the primary checkout cannot be read."
    output_lacks "preflight:"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: a failed git rev-parse --git-common-dir exits 2 before any check" {
    make_passing_change
    stub_directory=$(make_git_failing_on '*" rev-parse --git-common-dir "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "git rev-parse --git-common-dir failed, so whether this is the primary checkout cannot be read."
    output_lacks "preflight:"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: a failed git branch --show-current exits 2, is not read as a detached HEAD, before any check" {
    make_passing_change
    stub_directory=$(make_git_failing_on '*" branch --show-current "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "git branch --show-current failed, so the current branch cannot be read."
    output_lacks "not the current branch"
    output_lacks "preflight:"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: a failed git rev-parse of origin/<base> exits 2, is not read as an absent origin/<base>" {
    # Before the status was taken, the failure read as "no origin/main", the
    # origin half of BASE-MERGED was skipped, and the run passed with
    # origin/main ahead of HEAD.
    make_passing_change
    origin_main_ahead
    stub_directory=$(make_git_failing_on '*" rev-parse --verify --quiet refs/remotes/origin/main "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    has_line "git rev-parse --verify refs/remotes/origin/main failed, so whether origin/main exists cannot be read."
    failed_at BASE-MERGED
    has_line "fix BASE-MERGED: run git rev-parse --verify refs/remotes/origin/main in this worktree and resolve its error."
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: a failed git merge-base --is-ancestor exits 2, is not read as a base HEAD lacks" {
    make_passing_change
    stub_directory=$(make_git_failing_on '*" merge-base --is-ancestor refs/heads/main HEAD "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    has_line "git merge-base --is-ancestor refs/heads/main HEAD failed, so whether main is an ancestor of HEAD cannot be read."
    failed_at BASE-MERGED
    has_line "fix BASE-MERGED: run git merge-base --is-ancestor refs/heads/main HEAD in this worktree and resolve its error."
    output_lacks "merge the base branch"
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "merge-preflight: a failed git worktree list exits 2, is not read as a detached primary checkout" {
    # Before gr_base_branch took the status, the failure printed nothing, and
    # nothing reads as a detached primary checkout: exit 2 with the remedy
    # "check out the base branch in the primary checkout".
    make_passing_change
    status_before=$(git status --porcelain)
    head_before=$(git rev-parse HEAD)
    stub_directory=$(make_git_failing_on '*" worktree list "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/merge-preflight.sh my-change
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "git worktree list failed, so the base branch cannot be read."
    output_lacks "detached"
    output_lacks "Check out the base branch"
    output_lacks "preflight:"
    [ "$(git status --porcelain)" = "$status_before" ] \
        || { echo "the worktree changed"; false; }
    [ "$(git rev-parse HEAD)" = "$head_before" ] || { echo "HEAD moved"; false; }
}
