# task-worktree.sh: create a nested task worktree off the change branch, and
# merge it back, remove it or discard it. Every rejection is asserted to leave the task
# worktree, the task branch and the change branch exactly as they were.

load helpers

# The command task-worktree.sh had before merge and remove replaced it. A
# variable, so the old spelling is not a literal in this file, which the check
# that no remedy names it searches.
retired_command=finish

# A primary checkout on main that ignores the nested worktree directory and a
# bats-core-shaped directory, and a change worktree on my-change. Leaves the
# shell in the change worktree, which is where the script runs.
setup() {
    make_fixture_repo
    printf '.worktrees/\n.claude/\ntests/.bats-core\n*.bak\n' > .gitignore
    commit_all ignores
    make_change_worktree my-change
    CHANGE_ROOT=$(git rev-parse --show-toplevel)
    TASK_WT="$CHANGE_ROOT/.worktrees/my-change-t1"
    TW="$CHANGE_ROOT/.guardrails/scripts/task-worktree.sh"
}

branch_exists() { git show-ref --verify --quiet "refs/heads/$1"; }

# A task worktree with one commit on it, made by the script under test.
start_with_commit() {
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    printf 'task work\n' > "$TASK_WT/src/task.txt"
    git -C "$TASK_WT" add -A
    git -C "$TASK_WT" -c commit.gpgsign=false commit -qm "task work"
}

# The state a rejected merge, remove or discard must leave: the task worktree registered and
# present, the task branch present, and the change branch at the given commit.
assert_task_unchanged() {
    [ -d "$TASK_WT" ] || { echo "the task worktree was removed"; false; }
    branch_exists my-change-t1 || { echo "the task branch was deleted"; false; }
    [ "$(git -C "$CHANGE_ROOT" rev-parse my-change)" = "$1" ] \
        || { echo "the change branch moved"; false; }
}

# The `fix <RULE>: ` line of $output, into fix_text. Fails when there is none.
read_fix_line() {
    fix_text=$(printf '%s\n' "$output" | grep "^fix $1: ") \
        || { echo "no fix $1 line in: $output"; return 1; }
}

# A fix line that names a merging command fails: a merge is a decision, not a
# remedy (plan, "Decision after review round 4").
assert_names_no_merge() {
    case "$1" in
        (*"run merge"*|*"task-worktree.sh merge"*)
            echo "the fix line names a merging command: $1"; return 1 ;;
    esac
    return 0
}

# A lock file on the task branch ref: git worktree remove succeeds, then
# git branch -d and -D reject the deletion.
lock_task_branch() {
    task_branch_lock="$(git rev-parse --git-common-dir)/refs/heads/my-change-t1.lock"
    : > "$task_branch_lock"
}

# --- start --------------------------------------------------------------------

@test "task-worktree start: creates the nested worktree on a task branch off the change branch" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ -d "$TASK_WT" ] || { echo "no worktree at $TASK_WT"; false; }
    [ "$(git -C "$TASK_WT" branch --show-current)" = my-change-t1 ] \
        || { echo "task worktree is on $(git -C "$TASK_WT" branch --show-current)"; false; }
    [ "$(git rev-parse my-change-t1)" = "$(git rev-parse my-change)" ] \
        || { echo "the task branch does not start at the change branch"; false; }
    last_line=$(printf '%s\n' "$output" | tail -n 1)
    [ "$last_line" = "$TASK_WT" ] || { echo "last line: $last_line"; false; }
}

@test "task-worktree start: copies ignored entries, but not .worktrees/ or .claude/" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    mkdir -p tests/.bats-core/bin .worktrees/stray .claude/worktrees/other
    printf '#!/bin/sh\n' > tests/.bats-core/bin/bats
    printf 'stray\n' > .worktrees/stray/file
    printf 'other\n' > .claude/worktrees/other/file
    printf 'notes\n' > notes.bak
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ -f "$TASK_WT/tests/.bats-core/bin/bats" ] \
        || { echo "tests/.bats-core was not copied"; ls -la "$TASK_WT/tests"; false; }
    [ -f "$TASK_WT/notes.bak" ] || { echo "notes.bak was not copied"; false; }
    [ ! -e "$TASK_WT/.worktrees" ] || { echo ".worktrees/ was copied"; false; }
    [ ! -e "$TASK_WT/.claude" ] || { echo ".claude/ was copied"; false; }
    # Copied into place, not into a directory of the same name one level down.
    [ ! -e "$TASK_WT/tests/.bats-core/.bats-core" ] \
        || { echo "tests/.bats-core was copied into itself"; false; }
    # The copies are ignored, so the new worktree is clean.
    [ -z "$(git -C "$TASK_WT" status --porcelain)" ] \
        || { git -C "$TASK_WT" status --porcelain; false; }
}

@test "task-worktree start: rejects the primary checkout" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    cd "$REPO"
    run sh "$TW" start t1
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [ ! -e "$REPO/.worktrees/main-t1" ] || { echo "a worktree was created"; false; }
    run branch_exists main-t1
    [ "$status" -ne 0 ] || { echo "a branch was created"; false; }
}

@test "task-worktree start: rejects a detached HEAD" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    git checkout -q --detach
    run sh "$TW" start t1
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "detached"
    [ ! -e "$CHANGE_ROOT/.worktrees" ] || { echo "a worktree was created"; false; }
}

@test "task-worktree start: rejects an empty tag, a tag with a slash, and a tag with whitespace" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    for tag in "" "a/b" "a b" "a	b"; do
        run sh "$TW" start "$tag"
        [ "$status" -eq 2 ] || { echo "tag '$tag': $status: $output"; false; }
    done
    [ ! -e "$CHANGE_ROOT/.worktrees" ] || { echo "a worktree was created"; false; }
    [ "$(git for-each-ref --format='%(refname)' refs/heads/ | grep -c .)" -eq 2 ] \
        || { git for-each-ref refs/heads/; false; }
}

@test "task-worktree: start and remove reject a tag that begins with -" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # Two arguments, so the argument count accepts the call and the tag check
    # is what rejects it.
    for subcommand in start remove; do
        run sh "$TW" "$subcommand" -x
        [ "$status" -eq 2 ] || { echo "$subcommand -x: $status: $output"; false; }
        output_has "begins with '-'"
        output_has "usage: task-worktree.sh start <tag>"
    done
    [ ! -e "$CHANGE_ROOT/.worktrees" ] || { echo "a worktree was created"; false; }
    [ "$(git for-each-ref --format='%(refname)' refs/heads/ | grep -c .)" -eq 2 ] \
        || { git for-each-ref refs/heads/; false; }
}

@test "task-worktree start: copies an ignored entry whose name begins with - or contains a quote" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # cp reads a leading - as an option, and git ls-files without -z C-quotes a
    # name that contains a double quote.
    printf 'dash\n' > ./-n.bak
    printf 'quote\n' > 'q"uote.bak'
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ -f "$TASK_WT/-n.bak" ] || { echo "-n.bak was not copied: $output"; false; }
    [ -f "$TASK_WT/q\"uote.bak" ] || { echo "q\"uote.bak was not copied: $output"; false; }
}

@test "task-worktree start: skips an ignored entry whose name contains a newline, and states it" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    printf 'newline\n' > 'two
lines.bak'
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    output_has "not copied, the name contains a newline or a \\001 byte"
    last_line=$(printf '%s\n' "$output" | tail -n 1)
    [ "$last_line" = "$TASK_WT" ] || { echo "last line: $last_line"; false; }
}

@test "task-worktree start: skips an ignored entry whose name contains the byte \\001, and states it" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # tr marks a newline inside a name with \001, so a name that already
    # contains \001 cannot be told apart from one that contains a newline.
    printf 'marker\n' > "$(printf 'one\001byte.bak')"
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    output_has "not copied, the name contains a newline or a \\001 byte"
    last_line=$(printf '%s\n' "$output" | tail -n 1)
    [ "$last_line" = "$TASK_WT" ] || { echo "last line: $last_line"; false; }
}

@test "task-worktree start: a failed listing of ignored entries exits 2 and creates no worktree" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # A stub git first on PATH delegates every call to the real git except
    # the ls-files -z listing of ignored entries, which prints one entry and
    # exits 128. ls-files -u, the unmerged-entry check of CHANGE-BUSY, runs on
    # the real git.
    real_git=$(command -v git)
    stub_directory="$BATS_TEST_TMPDIR/stub-git"
    mkdir -p "$stub_directory"
    cat > "$stub_directory/git" <<STUB
#!/bin/sh
case "\$1" in
    (ls-files) [ "\$2" != -z ] || { printf 'partial.bak\\000'; exit 128; } ;;
esac
exec "$real_git" "\$@"
STUB
    chmod +x "$stub_directory/git"
    PATH="$stub_directory:$PATH" run sh "$TW" start t1
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    output_has "git ls-files failed"
    [ ! -e "$TASK_WT" ] || { echo "a worktree was created"; false; }
    if branch_exists my-change-t1; then echo "the task branch was created"; false; fi
    [ "$(git worktree list --porcelain | grep -c '^worktree ')" -eq 2 ] \
        || { git worktree list; false; }
}

@test "task-worktree start: a listing of ignored entries that fails with no output exits 2 and creates no worktree" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # The same stub as above, but ls-files prints nothing, so the only line
    # the listing gives is the failure marker.
    real_git=$(command -v git)
    stub_directory="$BATS_TEST_TMPDIR/stub-git"
    mkdir -p "$stub_directory"
    cat > "$stub_directory/git" <<STUB
#!/bin/sh
case "\$1" in
    (ls-files) [ "\$2" != -z ] || exit 128 ;;
esac
exec "$real_git" "\$@"
STUB
    chmod +x "$stub_directory/git"
    PATH="$stub_directory:$PATH" run sh "$TW" start t1
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    output_has "git ls-files failed"
    [ ! -e "$TASK_WT" ] || { echo "a worktree was created"; false; }
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch was created"; false; }
}

@test "task-worktree start: an ignored entry that cannot be copied exits 1 and names the worktree" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    [ "$(id -u)" -ne 0 ] || skip "root reads a file with mode 000"
    printf 'secret\n' > unreadable.bak
    chmod 000 unreadable.bak
    run sh "$TW" start t1
    chmod 644 unreadable.bak
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    output_has "copy failed: unreadable.bak"
    output_has "an ignored entry was not copied into it"
    [ -d "$TASK_WT" ] || { echo "the worktree was not created"; false; }
    read_fix_line TASK-COPY-FAILED
    case "$fix_text" in
        (*"cp -R -- <entry> $TASK_WT/<entry>"*"task-worktree.sh remove t1"*"start t1 again"*) ;;
        (*) echo "the remedy names no hand copy, remove and start: $fix_text"; false ;;
    esac
}

@test "task-worktree start: an ignored entry named like a failure line is copied and start exits 0" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # The failure status is not read from the progress lines, which contain
    # the entry names.
    printf 'named\n' > 'copy failed: x.bak'
    printf 'ok\n' > ok.bak
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [ -f "$TASK_WT/copy failed: x.bak" ] || { echo "copy failed: x.bak was not copied"; false; }
    [ -f "$TASK_WT/ok.bak" ] || { echo "ok.bak was not copied"; false; }
    output_lacks "an ignored entry was not copied into it"
    last_line=$(printf '%s\n' "$output" | tail -n 1)
    [ "$last_line" = "$TASK_WT" ] || { echo "last line: $last_line"; false; }
}

@test "task-worktree: rejects a missing tag, an extra argument and an unknown command" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh "$TW" start
    [ "$status" -eq 2 ] || { echo "no tag: $status: $output"; false; }
    run sh "$TW" start t1 t2
    [ "$status" -eq 2 ] || { echo "two tags: $status: $output"; false; }
    run sh "$TW" begin t1
    [ "$status" -eq 2 ] || { echo "unknown command: $status: $output"; false; }
    run sh "$TW"
    [ "$status" -eq 2 ] || { echo "no arguments: $status: $output"; false; }
    [ ! -e "$CHANGE_ROOT/.worktrees" ] || { echo "a worktree was created"; false; }
}

@test "task-worktree: outside a git repository it exits 2 at once, naming that reason only" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    outside="$BATS_TEST_TMPDIR/outside"
    mkdir -p "$outside"
    cd "$outside"
    GIT_CEILING_DIRECTORIES="$BATS_TEST_TMPDIR" run sh "$TW" start t1
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "not inside a git repository"
    output_lacks "primary checkout"
    [ -z "$(ls -A "$outside")" ] || { ls -A "$outside"; false; }
}

@test "task-worktree start: a failed git worktree add exits 1 and prints no worktree path" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # A stub git first on PATH delegates every call to the real git except
    # worktree add, which exits 128.
    real_git=$(command -v git)
    stub_directory="$BATS_TEST_TMPDIR/stub-git"
    mkdir -p "$stub_directory"
    cat > "$stub_directory/git" <<STUB
#!/bin/sh
case "\$1 \$2" in
    ("worktree add") echo "fatal: stub worktree add failure" >&2; exit 128 ;;
esac
exec "$real_git" "\$@"
STUB
    chmod +x "$stub_directory/git"
    PATH="$stub_directory:$PATH" run sh "$TW" start t1
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    output_has "git worktree add failed; nothing was created."
    read_fix_line TASK-NOT-CREATED
    case "$fix_text" in
        (*"git's error above"*"run start t1 again"*) ;;
        (*) echo "the remedy names no git error and no start: $fix_text"; false ;;
    esac
    last_line=$(printf '%s\n' "$output" | tail -n 1)
    [ "$last_line" != "$TASK_WT" ] || { echo "the worktree path was printed: $output"; false; }
    [ ! -e "$TASK_WT" ] || { echo "a worktree was created"; false; }
}

@test "task-worktree start: rejects a change worktree that does not ignore .worktrees/" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    printf '.claude/\n' > .gitignore
    commit_all "stop ignoring .worktrees"
    run sh "$TW" start t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix WORKTREES-NOT-IGNORED: "
    [ ! -e "$CHANGE_ROOT/.worktrees" ] || { echo "a worktree was created"; false; }
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "a branch was created"; false; }
}

# The TASK-EXISTS remedy: another tag first; remove for a leftover; discard
# named only after the commits are recorded as findings; a leftover directory
# with no branch removed by git worktree remove or by hand; no merging command.
assert_task_exists_remedy() {
    output_has "choose another tag"
    output_has "remove t1"
    output_has "git worktree remove $TASK_WT"
    output_has "deleted by hand after reading it"
    before_record=${output%%record*}
    case "$before_record" in
        (*discard*) echo "discard is named before record: $output"; false ;;
    esac
    output_has "discard t1"
    output_lacks "merge"
}

@test "task-worktree start: rejects a tag whose path already exists" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    mkdir -p "$TASK_WT"
    printf 'keep\n' > "$TASK_WT/keep.txt"
    run sh "$TW" start t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-EXISTS: "
    assert_task_exists_remedy
    [ -f "$TASK_WT/keep.txt" ] || { echo "the existing directory was changed"; false; }
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "a branch was created"; false; }
}

@test "task-worktree start: rejects a tag whose branch already exists" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    git branch my-change-t1
    run sh "$TW" start t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-EXISTS: "
    assert_task_exists_remedy
    [ ! -e "$TASK_WT" ] || { echo "a worktree was created"; false; }
}

# A worktree registered at $1, as `git worktree list` records it.
is_registered() {
    git worktree list --porcelain | grep -qxF "worktree $1"
}

# Commits a submodule into the task worktree. `git status` there stays clean,
# and `git worktree remove` without --force rejects a worktree that contains a
# submodule, so this is a state in which a --force removes what the script
# must not.
add_submodule_to_task() {
    git init -q "$BATS_TEST_TMPDIR/sub"
    git -C "$BATS_TEST_TMPDIR/sub" -c user.name=sub -c user.email=sub@example.com \
        -c commit.gpgsign=false commit -q --allow-empty -m sub
    git -C "$TASK_WT" -c protocol.file.allow=always submodule add -q \
        "$BATS_TEST_TMPDIR/sub" sm
    git -C "$TASK_WT" -c commit.gpgsign=false commit -qm "submodule"
}

# Asserts the TASK-NOT-REMOVED fix line of a merge whose worktree removal git
# rejected, then follows it: clears the submodule add_submodule_to_task made,
# which is what git rejected, and runs remove, which retires the worktree and
# the branch.
assert_not_removed_remedy_retires_task() {
    output_has "fix TASK-NOT-REMOVED: "
    output_has "the merge is done and my-change-t1 is in my-change"
    output_has "$TASK_WT remains"
    output_has "task-worktree.sh remove t1 retires it"
    output_lacks "task-worktree.sh merge"
    output_lacks "run merge"
    git -C "$TASK_WT" submodule deinit -q -f sm
    rm -rf "$(git -C "$TASK_WT" rev-parse --absolute-git-dir)/modules"
    run sh "$TW" remove t1
    [ "$status" -eq 0 ] || { echo "remove after the remedy: $status: $output"; false; }
    run is_registered "$TASK_WT"
    [ "$status" -ne 0 ] || { echo "the task worktree is still registered"; false; }
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
}

# A worktree on branch my-change-other, registered OUTSIDE the change worktree,
# with one commit the change branch lacks.
make_sibling() {
    SIBLING="$BATS_TEST_TMPDIR/sibling"
    git worktree add -q "$SIBLING" -b my-change-other my-change
    # Spelled as git records it: $BATS_TEST_TMPDIR can be a symlinked path.
    SIBLING=$(git -C "$SIBLING" rev-parse --show-toplevel)
    printf 'sibling work\n' > "$SIBLING/sibling.txt"
    git -C "$SIBLING" add -A
    git -C "$SIBLING" -c commit.gpgsign=false commit -qm "sibling work"
}

# --- merge --------------------------------------------------------------------

@test "task-worktree merge: merges the task branch, removes the worktree, deletes the branch" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    task_tip=$(git rev-parse my-change-t1)
    run sh "$TW" merge t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ ! -e "$TASK_WT" ] || { echo "the task worktree remains"; false; }
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
    # --no-ff: a merge commit whose second parent is the task branch's tip.
    [ "$(git rev-parse HEAD^2)" = "$task_tip" ] \
        || { echo "HEAD is not a merge of the task branch"; git log --oneline -3; false; }
    [ -f src/task.txt ] || { echo "the task's work is not in the change worktree"; false; }
    run git worktree list --porcelain
    output_lacks "$TASK_WT"
}

@test "task-worktree merge: rejects a task worktree with an uncommitted change and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    printf 'edited\n' > "$TASK_WT/src/task.txt"
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-DIRTY: "
    # The uncommitted change is not in the dispatch report, so the remedy
    # returns the task to its subagent and names no merging command.
    output_has "the changes in $TASK_WT are not covered by its dispatch report"
    output_has "the task goes back to its subagent (develop-change)"
    output_lacks "run merge"
    output_lacks "task-worktree.sh merge"
    assert_task_unchanged "$change_head"
    [ "$(cat "$TASK_WT/src/task.txt")" = edited ] || { echo "the edit was lost"; false; }
}

@test "task-worktree merge: rejects a task worktree with an untracked file and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    printf 'new\n' > "$TASK_WT/src/untracked.txt"
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-DIRTY: "
    assert_task_unchanged "$change_head"
    [ -f "$TASK_WT/src/untracked.txt" ] || { echo "the untracked file was lost"; false; }
}

@test "task-worktree merge: rejects a task worktree with a worktree registered inside it" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    git -C "$TASK_WT" worktree add -q "$TASK_WT/.worktrees/inner" -b inner
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-NESTED: "
    output_has "$TASK_WT/.worktrees/inner"
    # The remedy for the inner worktree merges nothing.
    output_has "task-worktree.sh remove <tag> from $TASK_WT"
    output_has "task-worktree.sh discard <tag>"
    output_lacks "task-worktree.sh merge"
    assert_task_unchanged "$change_head"
    [ -d "$TASK_WT/.worktrees/inner" ] || { echo "the inner worktree was removed"; false; }
}

@test "task-worktree merge: the TASK-NESTED fix line returns the task to its subagent and names no merge" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    git -C "$TASK_WT" worktree add -q .worktrees/inner -b inner
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-NESTED: "
    output_has "the task goes back to its subagent (develop-change)"
    output_lacks "run merge"
    output_lacks "task-worktree.sh merge"
    assert_task_unchanged "$change_head"
}

@test "task-worktree merge: the TASK-NESTED fix line covers a worktree task-worktree.sh did not create" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    # No my-change-t1-<tag> branch exists for this worktree, so remove <tag>
    # alone would stop at TASK-MISSING.
    git -C "$TASK_WT" worktree add -q .worktrees/inner -b inner
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-NESTED: "
    output_has "for a path .worktrees/my-change-t1-<tag>, run task-worktree.sh remove <tag> from $TASK_WT"
    output_has "for a worktree task-worktree.sh did not create, record the commits its branch has"
    output_has "git worktree remove <path> (no --force)"
    output_has "git branch -D <branch>"
    assert_task_unchanged "$change_head"
    [ -d "$TASK_WT/.worktrees/inner" ] || { echo "the inner worktree was removed"; false; }
}

@test "task-worktree merge: a conflict leaves the merge in progress, and the remedy concludes it unsigned" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    printf 'change side\n' > src/task.txt
    commit_all "conflicting work on the change branch"
    change_head=$(git rev-parse my-change)
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-CONFLICT: "
    output_has "git -c commit.gpgsign=false commit --no-edit"
    output_has "run remove t1"
    assert_task_unchanged "$change_head"
    git rev-parse -q --verify MERGE_HEAD >/dev/null \
        || { echo "the merge is not left in progress"; false; }
    # The remedy as the fix line states it: resolve, conclude unsigned, remove.
    printf 'resolved\n' > src/task.txt
    git add src/task.txt
    git -c commit.gpgsign=false commit -q --no-edit
    run sh "$TW" remove t1
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    [ ! -e "$TASK_WT" ] || { echo "the task worktree remains"; false; }
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
}

# A task worktree on my-change-<tag> with one commit that writes $2 to the file
# $3, made by the script under test.
start_tag_with_commit() {
    run sh "$TW" start "$1"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    printf '%s\n' "$2" > "$CHANGE_ROOT/.worktrees/my-change-$1/$3"
    git -C "$CHANGE_ROOT/.worktrees/my-change-$1" add -A
    git -C "$CHANGE_ROOT/.worktrees/my-change-$1" -c commit.gpgsign=false commit -qm "task $1 work"
}

@test "task-worktree merge: a merge left in progress by an earlier task is CHANGE-BUSY, not this task's conflict, and nothing changes" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_tag_with_commit t2 "t2 side" src/shared.txt
    start_tag_with_commit t3 "t3 work" src/t3.txt
    printf 'change side\n' > src/shared.txt
    commit_all "conflicting work on the change branch"
    run sh "$TW" merge t2
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-CONFLICT: "
    change_head=$(git rev-parse my-change)
    t3_tip=$(git rev-parse my-change-t3)
    run sh "$TW" merge t3
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    read_fix_line CHANGE-BUSY
    case "$fix_text" in
        (*"a merge of my-change-t2 is in progress"*) ;;
        (*) echo "the fix line does not name the merge in progress: $fix_text"; false ;;
    esac
    case "$fix_text" in
        (*"git -c commit.gpgsign=false commit --no-edit)"*"git merge --abort"*"repeat the dispatcher's step for this task (develop-change)"*) ;;
        (*) echo "the remedy does not conclude or abort, then repeat the step: $fix_text"; false ;;
    esac
    assert_names_no_merge "$fix_text"
    output_lacks "TASK-CONFLICT"
    [ -d "$CHANGE_ROOT/.worktrees/my-change-t3" ] || { echo "the t3 worktree was removed"; false; }
    [ "$(git rev-parse my-change-t3)" = "$t3_tip" ] || { echo "the t3 branch moved or was deleted"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] || { echo "the change branch moved"; false; }
    [ "$(git rev-parse MERGE_HEAD)" = "$(git rev-parse my-change-t2)" ] \
        || { echo "the t2 merge is no longer in progress"; false; }
    # The remedy as the fix line states it: conclude the t2 merge, then merge t3.
    printf 'resolved\n' > src/shared.txt
    git add src/shared.txt
    git -c commit.gpgsign=false commit -q --no-edit
    run sh "$TW" merge t3
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    output_has "merged: my-change-t3"
    [ ! -e "$CHANGE_ROOT/.worktrees/my-change-t3" ] || { echo "the t3 worktree remains"; false; }
}

@test "task-worktree merge: a cherry-pick conflict left in the change worktree is CHANGE-BUSY, and nothing changes" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    printf 'base\n' > src/shared.txt
    commit_all "a file both sides change"
    git branch picked
    start_with_commit
    git checkout -q picked
    printf 'picked side\n' > src/shared.txt
    commit_all "the commit to pick"
    git checkout -q my-change
    printf 'change side\n' > src/shared.txt
    commit_all "conflicting work on the change branch"
    run git -c commit.gpgsign=false cherry-pick picked
    [ "$status" -ne 0 ] || { echo "the cherry-pick did not conflict: $output"; false; }
    change_head=$(git rev-parse my-change)
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    read_fix_line CHANGE-BUSY
    case "$fix_text" in
        (*"a cherry-pick is in progress"*"git cherry-pick --abort"*) ;;
        (*) echo "the fix line does not name the cherry-pick and its abort: $fix_text"; false ;;
    esac
    assert_names_no_merge "$fix_text"
    output_lacks "TASK-CONFLICT"
    assert_task_unchanged "$change_head"
    git rev-parse -q --verify CHERRY_PICK_HEAD >/dev/null \
        || { echo "the cherry-pick is no longer in progress"; false; }
}

# A task worktree t1 with one commit, then a rebase of the change branch that
# stopped on a conflict in the change worktree, which detaches its HEAD. Sets
# change_head to the change branch tip and task_tip to the task branch tip.
stop_rebase_on_conflict() {
    printf 'base\n' > src/shared.txt
    commit_all "a file both sides change"
    start_with_commit
    git branch rebase-onto
    git checkout -q rebase-onto
    printf 'onto side\n' > src/shared.txt
    git add -A
    git -c commit.gpgsign=false commit -qm "the commit to rebase onto"
    git checkout -q my-change
    printf 'change side\n' > src/shared.txt
    git add -A
    git -c commit.gpgsign=false commit -qm "conflicting work on the change branch"
    run git -c commit.gpgsign=false rebase rebase-onto
    [ "$status" -ne 0 ] || { echo "the rebase did not conflict: $output"; false; }
    [ -d "$(git rev-parse --git-path rebase-merge)" ] \
        || { echo "no rebase is in progress"; false; }
    change_head=$(git rev-parse my-change)
    task_tip=$(git rev-parse my-change-t1)
}

# $1 is the command and $2 the tag. The run exits 1 with the rebase CHANGE-BUSY
# line, and the task worktree, both branches and the rebase are as they were.
assert_rejects_rebase() {
    run sh "$TW" "$1" "$2"
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    read_fix_line CHANGE-BUSY
    case "$fix_text" in
        (*"a rebase is in progress in $CHANGE_ROOT"*"git -c commit.gpgsign=false -c core.editor=true rebase --continue"*"git rebase --abort"*) ;;
        (*) echo "the fix line does not name the rebase, its conclusion and its abort: $fix_text"; false ;;
    esac
    assert_names_no_merge "$fix_text"
    assert_task_unchanged "$change_head"
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] || { echo "the task branch moved"; false; }
    [ -d "$(git rev-parse --git-path rebase-merge)" ] \
        || { echo "the rebase is no longer in progress"; false; }
    [ ! -e "$CHANGE_ROOT/.worktrees/my-change-t2" ] || { echo "a t2 worktree was created"; false; }
    run branch_exists my-change-t2
    [ "$status" -ne 0 ] || { echo "a t2 branch was created"; false; }
}

@test "task-worktree merge: a rebase stopped on a conflict in the change worktree is CHANGE-BUSY, and nothing changes" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    stop_rebase_on_conflict
    assert_rejects_rebase merge t1
    case "$fix_text" in
        (*"then repeat the dispatcher's step for this task (develop-change)"*) ;;
        (*) echo "the remedy does not repeat the dispatcher's step: $fix_text"; false ;;
    esac
    assert_remedy_names_no_subagent
}

# The CHANGE-BUSY remedy under start, in $fix_text: the operation in progress
# belongs to the dispatcher of the change worktree, which concludes or aborts
# it, a dispatched subagent stops and reports the line without acting on it,
# and start is run again (finding-92).
assert_start_remedy_is_the_dispatchers() {
    case "$fix_text" in
        (*"The operation belongs to the dispatcher of the change worktree"*) ;;
        (*) echo "the remedy does not name the dispatcher as the owner: $fix_text"; return 1 ;;
    esac
    case "$fix_text" in
        (*"a dispatched subagent stops and reports this line without acting on it"*) ;;
        (*) echo "the remedy does not tell a subagent to stop and report: $fix_text"; return 1 ;;
    esac
    case "$fix_text" in
        (*"the dispatcher concludes it ("*") or aborts it ("*"); then run start $1 again."*) ;;
        (*) echo "the remedy does not leave the conclusion and the abort to the dispatcher: $fix_text"; return 1 ;;
    esac
    return 0
}

# The CHANGE-BUSY remedy in $fix_text is addressed to the agent that runs the command,
# which for merge, remove and discard is the dispatcher itself.
assert_remedy_names_no_subagent() {
    case "$fix_text" in
        (*subagent*) echo "the remedy names a subagent: $fix_text"; return 1 ;;
    esac
    return 0
}

@test "task-worktree start: a rebase stopped on a conflict in the change worktree is CHANGE-BUSY, and nothing is created" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    stop_rebase_on_conflict
    assert_rejects_rebase start t2
    case "$fix_text" in
        (*"then run start t2 again"*) ;;
        (*) echo "the remedy does not run start again: $fix_text"; false ;;
    esac
}

@test "task-worktree start: the CHANGE-BUSY remedy for a rebase leaves it to the dispatcher, and a dispatched subagent stops and reports" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # Before finding-92, the remedy told the agent that runs start, a dispatched
    # subagent under develop-change, to abort the dispatcher's rebase.
    stop_rebase_on_conflict
    assert_rejects_rebase start t2
    assert_start_remedy_is_the_dispatchers t2
}

@test "task-worktree remove: a rebase stopped on a conflict in the change worktree is CHANGE-BUSY, and nothing changes" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    stop_rebase_on_conflict
    assert_rejects_rebase remove t1
    case "$fix_text" in
        (*"then run remove t1 again"*) ;;
        (*) echo "the remedy does not run remove again: $fix_text"; false ;;
    esac
}

# The reviewer's sequence (finding-71): merge t2 stops at TASK-CONFLICT, and
# the merge is not concluded. Sets change_head and t2_tip.
stop_t2_merge_on_conflict() {
    start_tag_with_commit t2 "t2 side" src/shared.txt
    printf 'change side\n' > src/shared.txt
    commit_all "conflicting work on the change branch"
    run sh "$TW" merge t2
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-CONFLICT: "
    change_head=$(git rev-parse my-change)
    t2_tip=$(git rev-parse my-change-t2)
}

# $1 is the command. The run exits 1 with CHANGE-BUSY naming the merge of
# my-change-t2, its remedy names no discard and no merge, and the t2 branch,
# the t2 worktree, the change branch and MERGE_HEAD are as they were.
assert_rejects_t2_merge_in_progress() {
    run sh "$TW" "$1" t2
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    read_fix_line CHANGE-BUSY
    case "$fix_text" in
        (*"the merge of my-change-t2, this task's branch, is in progress"*) ;;
        (*) echo "the fix line does not name the merge of this task: $fix_text"; false ;;
    esac
    case "$fix_text" in
        (*"git -c commit.gpgsign=false commit --no-edit), then run remove t2; or abort it (git merge --abort), then repeat the dispatcher's step for this task (develop-change)"*) ;;
        (*) echo "the remedy does not conclude then remove, or abort then repeat the step: $fix_text"; false ;;
    esac
    case "$fix_text" in
        (*discard*) echo "the remedy names discard: $fix_text"; false ;;
    esac
    assert_names_no_merge "$fix_text"
    output_lacks "TASK-HAS-COMMITS"
    output_lacks "worktree removed"
    output_lacks "branch deleted"
    [ -d "$CHANGE_ROOT/.worktrees/my-change-t2" ] || { echo "the t2 worktree was removed"; false; }
    [ "$(git rev-parse -q --verify my-change-t2)" = "$t2_tip" ] \
        || { echo "the t2 branch moved or was deleted"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] || { echo "the change branch moved"; false; }
    [ "$(git rev-parse -q --verify MERGE_HEAD)" = "$t2_tip" ] \
        || { echo "the t2 merge is no longer in progress"; false; }
}

@test "task-worktree remove: the merge of this task left in progress is CHANGE-BUSY, not TASK-HAS-COMMITS, and nothing changes" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    stop_t2_merge_on_conflict
    assert_rejects_t2_merge_in_progress remove
    # The remedy as the fix line states it: conclude the merge, then remove.
    printf 'resolved\n' > src/shared.txt
    git add src/shared.txt
    git -c commit.gpgsign=false commit -q --no-edit
    run sh "$TW" remove t2
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    [ ! -e "$CHANGE_ROOT/.worktrees/my-change-t2" ] || { echo "the t2 worktree remains"; false; }
}

@test "task-worktree discard: the merge of this task left in progress is CHANGE-BUSY, and nothing is deleted" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    stop_t2_merge_on_conflict
    assert_rejects_t2_merge_in_progress discard
    output_lacks "discarding the commits"
    assert_remedy_names_no_subagent
}

# A file both the change branch and a side commit change, and the task
# worktree t1 with one commit. Leaves the shell on my-change, and sets
# side_commit to a commit on no branch that conflicts with the change branch
# tip.
make_side_conflict() {
    printf 'base\n' > src/shared.txt
    commit_all "a file both sides change"
    start_with_commit
    git checkout -q --detach
    printf 'side\n' > src/shared.txt
    git add -A
    git -c commit.gpgsign=false commit -qm "the side commit"
    side_commit=$(git rev-parse HEAD)
    git checkout -q my-change
    printf 'change side\n' > src/shared.txt
    git add -A
    git -c commit.gpgsign=false commit -qm "conflicting work on the change branch"
}

@test "task-worktree merge: a revert conflict left in the change worktree is CHANGE-BUSY, and nothing changes" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    printf 'base\n' > src/shared.txt
    commit_all "a file both sides change"
    printf 'reverted side\n' > src/shared.txt
    commit_all "the commit to revert"
    git tag to-revert
    start_with_commit
    printf 'change side\n' > src/shared.txt
    commit_all "conflicting work on the change branch"
    run git -c commit.gpgsign=false revert --no-edit to-revert
    [ "$status" -ne 0 ] || { echo "the revert did not conflict: $output"; false; }
    change_head=$(git rev-parse my-change)
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    read_fix_line CHANGE-BUSY
    case "$fix_text" in
        (*"a revert is in progress"*"git revert --abort"*) ;;
        (*) echo "the fix line does not name the revert and its abort: $fix_text"; false ;;
    esac
    assert_names_no_merge "$fix_text"
    output_lacks "TASK-CONFLICT"
    assert_task_unchanged "$change_head"
    [ -e "$(git rev-parse --git-path REVERT_HEAD)" ] \
        || { echo "the revert is no longer in progress"; false; }
}

@test "task-worktree remove: unmerged entries from a stash pop in the change worktree are CHANGE-BUSY, and nothing changes" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    printf 'base\n' > src/shared.txt
    commit_all "a file both sides change"
    start_with_commit
    printf 'stashed side\n' > src/shared.txt
    git -c commit.gpgsign=false stash push -q -m fixture-stash
    printf 'change side\n' > src/shared.txt
    git add -A
    git -c commit.gpgsign=false commit -qm "conflicting work on the change branch"
    run git -c commit.gpgsign=false stash pop
    [ "$status" -ne 0 ] || { echo "the stash pop did not conflict: $output"; false; }
    [ -n "$(git ls-files -u)" ] || { echo "no index entry is unmerged"; false; }
    run git rev-parse -q --verify MERGE_HEAD
    [ "$status" -ne 0 ] || { echo "the stash pop left MERGE_HEAD"; false; }
    change_head=$(git rev-parse my-change)
    run sh "$TW" remove t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    read_fix_line CHANGE-BUSY
    case "$fix_text" in
        (*"a conflict resolution (the index has unmerged entries) is in progress"*"git add each resolved path, then git -c commit.gpgsign=false commit -m <message>)"*"git checkout HEAD -- <path> for each unmerged path"*"then run remove t1 again"*) ;;
        (*) echo "the fix line does not name the unmerged entries, their conclusion and their abort: $fix_text"; false ;;
    esac
    assert_names_no_merge "$fix_text"
    output_lacks "TASK-HAS-COMMITS"
    assert_task_unchanged "$change_head"
    [ -n "$(git ls-files -u)" ] || { echo "the unmerged entries are gone"; false; }
}

@test "task-worktree discard: a rebase --apply stopped on a conflict in the change worktree is CHANGE-BUSY, and nothing changes" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    make_side_conflict
    change_head=$(git rev-parse my-change)
    task_tip=$(git rev-parse my-change-t1)
    run git -c commit.gpgsign=false rebase --apply "$side_commit"
    [ "$status" -ne 0 ] || { echo "the rebase did not conflict: $output"; false; }
    [ -d "$(git rev-parse --git-path rebase-apply)" ] \
        || { echo "no rebase --apply is in progress"; false; }
    run sh "$TW" discard t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    read_fix_line CHANGE-BUSY
    case "$fix_text" in
        (*"a rebase is in progress in $CHANGE_ROOT"*"git rebase --abort"*"then run discard t1 again"*) ;;
        (*) echo "the fix line does not name the rebase and its abort: $fix_text"; false ;;
    esac
    assert_names_no_merge "$fix_text"
    output_lacks "discarding the commits"
    assert_task_unchanged "$change_head"
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] || { echo "the task branch moved"; false; }
    [ -d "$(git rev-parse --git-path rebase-apply)" ] \
        || { echo "the rebase is no longer in progress"; false; }
}

@test "task-worktree start: a merge of a commit no branch names, left in progress, is CHANGE-BUSY naming its short SHA, and nothing is created" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    make_side_conflict
    change_head=$(git rev-parse my-change)
    run git -c commit.gpgsign=false merge --no-edit "$side_commit"
    [ "$status" -ne 0 ] || { echo "the merge did not conflict: $output"; false; }
    [ -z "$(git for-each-ref --points-at="$side_commit" refs/heads/)" ] \
        || { echo "a branch points at the side commit"; false; }
    side_short=$(git rev-parse --short "$side_commit")
    run sh "$TW" start t2
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    read_fix_line CHANGE-BUSY
    case "$fix_text" in
        (*"a merge of $side_short is in progress"*"git merge --abort"*"then run start t2 again"*) ;;
        (*) echo "the fix line does not name the merge by its short SHA: $fix_text"; false ;;
    esac
    assert_names_no_merge "$fix_text"
    assert_task_unchanged "$change_head"
    [ ! -e "$CHANGE_ROOT/.worktrees/my-change-t2" ] || { echo "a t2 worktree was created"; false; }
    run branch_exists my-change-t2
    [ "$status" -ne 0 ] || { echo "a t2 branch was created"; false; }
    [ "$(git rev-parse -q --verify MERGE_HEAD)" = "$side_commit" ] \
        || { echo "the merge is no longer in progress"; false; }
}

@test "task-worktree start: the CHANGE-BUSY remedy for a merge leaves it to the dispatcher, and a dispatched subagent stops and reports" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # Before finding-92, the remedy told the agent that runs start, a dispatched
    # subagent under develop-change, to run git merge --abort on the
    # dispatcher's merge.
    make_side_conflict
    run git -c commit.gpgsign=false merge --no-edit "$side_commit"
    [ "$status" -ne 0 ] || { echo "the merge did not conflict: $output"; false; }
    run sh "$TW" start t2
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    read_fix_line CHANGE-BUSY
    assert_start_remedy_is_the_dispatchers t2
    case "$fix_text" in
        (*"(git merge --abort)"*) ;;
        (*) echo "the remedy does not name the abort: $fix_text"; false ;;
    esac
    assert_names_no_merge "$fix_text"
    [ "$(git rev-parse -q --verify MERGE_HEAD)" = "$side_commit" ] \
        || { echo "the merge is no longer in progress"; false; }
}

@test "task-worktree start: the merge of the task named left in progress is CHANGE-BUSY, left to the dispatcher" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    stop_t2_merge_on_conflict
    run sh "$TW" start t2
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    read_fix_line CHANGE-BUSY
    case "$fix_text" in
        (*"the merge of my-change-t2, this task's branch, is in progress"*) ;;
        (*) echo "the fix line does not name the merge of this task: $fix_text"; false ;;
    esac
    assert_start_remedy_is_the_dispatchers t2
    case "$fix_text" in
        (*"git -c commit.gpgsign=false commit --no-edit, then run remove t2"*) ;;
        (*) echo "the remedy does not conclude then remove: $fix_text"; false ;;
    esac
    assert_names_no_merge "$fix_text"
    [ "$(git rev-parse -q --verify MERGE_HEAD)" = "$t2_tip" ] \
        || { echo "the t2 merge is no longer in progress"; false; }
}

@test "task-worktree merge: a merge that fails without a conflict exits 1 and removes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    printf 'base\n' > src/shared.txt
    commit_all "a file the task branch changes"
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    printf 'task side\n' > "$TASK_WT/src/shared.txt"
    git -C "$TASK_WT" add -A
    git -C "$TASK_WT" -c commit.gpgsign=false commit -qm "task work"
    change_head=$(git rev-parse my-change)
    # An uncommitted edit to that file in the change worktree: git rejects the
    # merge before it starts, and no index entry is left unmerged.
    printf 'local edit\n' > src/shared.txt
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "would be overwritten by merge"
    output_has "git merge of my-change-t1 failed; nothing was removed."
    read_fix_line TASK-MERGE-FAILED
    case "$fix_text" in
        (*"repeat the dispatcher's step for this task (develop-change)"*) ;;
        (*) echo "the remedy does not return to the dispatcher's step: $fix_text"; false ;;
    esac
    assert_names_no_merge "$fix_text"
    output_lacks "TASK-CONFLICT"
    output_lacks "worktree removed"
    output_lacks "branch deleted"
    assert_task_unchanged "$change_head"
    [ "$(cat src/shared.txt)" = "local edit" ] || { echo "the local edit was changed"; false; }
}

# A hook named $1 in a hooks directory the change worktree's repository uses,
# which exits 1: git merge completes the merge in the index and working tree,
# then the hook rejects the merge commit, and the merge is left in progress
# with no unmerged entry (finding-79).
reject_merge_commit_with_hook() {
    hooks_dir="$BATS_TEST_TMPDIR/hooks"
    mkdir -p "$hooks_dir"
    printf '#!/bin/sh\necho "the %s hook rejects this commit" >&2\nexit 1\n' "$1" > "$hooks_dir/$1"
    chmod +x "$hooks_dir/$1"
    git config core.hooksPath "$hooks_dir"
}

# merge t1 with the merge commit rejected by the hook $1: the merge of this
# task is in progress and not committed, and the fix line states that, not
# TASK-MERGE-FAILED's "nothing was merged". The remedy as the fix line states
# it then concludes the merge and remove retires the task.
assert_merge_left_in_progress_by_hook() {
    start_with_commit
    change_head=$(git rev-parse my-change)
    task_tip=$(git rev-parse my-change-t1)
    reject_merge_commit_with_hook "$1"
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    read_fix_line CHANGE-BUSY
    case "$fix_text" in
        (*"the merge of my-change-t1, this task's branch, is in progress in the change worktree $CHANGE_ROOT and was not committed"*) ;;
        (*) echo "the fix line does not state the merge is in progress and not committed: $fix_text"; false ;;
    esac
    case "$fix_text" in
        (*"git -c commit.gpgsign=false commit --no-edit), then run remove t1"*) ;;
        (*) echo "the remedy does not conclude the merge and then remove: $fix_text"; false ;;
    esac
    case "$fix_text" in
        (*"(git merge --abort), then repeat the dispatcher's step for this task (develop-change)"*) ;;
        (*) echo "the remedy does not abort and return to the dispatcher's step: $fix_text"; false ;;
    esac
    case "$fix_text" in
        (*discard*) echo "the remedy names discard: $fix_text"; false ;;
    esac
    assert_names_no_merge "$fix_text"
    output_lacks "nothing was merged"
    output_lacks "TASK-MERGE-FAILED"
    output_lacks "TASK-CONFLICT"
    output_lacks "worktree removed"
    output_lacks "branch deleted"
    assert_task_unchanged "$change_head"
    [ "$(git rev-parse -q --verify MERGE_HEAD)" = "$task_tip" ] \
        || { echo "the merge of t1 is not left in progress"; false; }
    [ -z "$(git ls-files -u)" ] || { echo "the merge left unmerged entries"; false; }
    # The remedy as the fix line states it: clear the cause, conclude, remove.
    git config --unset core.hooksPath
    git -c commit.gpgsign=false commit -q --no-edit
    run sh "$TW" remove t1
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    [ ! -e "$TASK_WT" ] || { echo "the task worktree remains"; false; }
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
}

@test "task-worktree merge: a merge commit a commit-msg hook rejects leaves this task's merge in progress, and the fix line states it was not committed" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_merge_left_in_progress_by_hook commit-msg
}

@test "task-worktree merge: a merge commit a pre-merge-commit hook rejects leaves this task's merge in progress, and the fix line states it was not committed" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_merge_left_in_progress_by_hook pre-merge-commit
}

@test "task-worktree merge: a task branch with no commits is removed the same way" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh "$TW" start t2
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    change_head=$(git rev-parse my-change)
    run sh "$TW" merge t2
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    output_has "Already up to date"
    [ ! -e "$CHANGE_ROOT/.worktrees/my-change-t2" ] \
        || { echo "the task worktree remains"; false; }
    run branch_exists my-change-t2
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] \
        || { echo "an empty merge moved the change branch"; false; }
}

@test "task-worktree: a second start with the same tag after merge succeeds" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    run sh "$TW" merge t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ -d "$TASK_WT" ] || { echo "no worktree at $TASK_WT"; false; }
    [ "$(git rev-parse my-change-t1)" = "$(git rev-parse my-change)" ] \
        || { echo "the new task branch does not start at the change branch"; false; }
}

@test "task-worktree merge: a rejected worktree removal names what was and was not removed" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    add_submodule_to_task
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "merged: my-change-t1"
    output_has "not removed: $TASK_WT"
    output_has "not deleted: my-change-t1"
    [ -d "$TASK_WT" ] || { echo "the task worktree was removed"; false; }
    is_registered "$TASK_WT" || { echo "the task worktree is not registered"; false; }
    branch_exists my-change-t1 || { echo "the task branch was deleted"; false; }
    assert_not_removed_remedy_retires_task
}

@test "task-worktree merge: a rejected worktree removal stops before the branch deletion" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    add_submodule_to_task
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "not removed: $TASK_WT"
    output_lacks "worktree removed:"
    output_lacks "branch deleted:"
    branch_exists my-change-t1 || { echo "the task branch was deleted"; false; }
    assert_not_removed_remedy_retires_task
}

@test "task-worktree merge: removes without --force, so a worktree git will not remove remains" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    add_submodule_to_task
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "not removed: $TASK_WT"
    [ -d "$TASK_WT" ] || { echo "the task worktree was removed"; false; }
    is_registered "$TASK_WT" || { echo "the task worktree is not registered"; false; }
    branch_exists my-change-t1 || { echo "the task branch was deleted"; false; }
}

@test "task-worktree merge: a rejected branch deletion names the removed worktree" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    lock_task_branch
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "worktree removed: $TASK_WT"
    output_has "not deleted: my-change-t1"
    [ ! -e "$TASK_WT" ] || { echo "the task worktree remains"; false; }
    branch_exists my-change-t1 || { echo "the task branch was deleted"; false; }
    read_fix_line TASK-BRANCH-NOT-DELETED
    case "$fix_text" in
        (*"git branch -d my-change-t1"*) ;;
        (*) echo "the remedy names no git branch -d: $fix_text"; false ;;
    esac
    assert_names_no_merge "$fix_text"
    # With the lock gone, the remedy as the fix line states it deletes the branch.
    rm -f "$task_branch_lock"
    git branch -d my-change-t1
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
}

@test "task-worktree remove: a rejected branch deletion prints TASK-BRANCH-NOT-DELETED with git branch -d" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    lock_task_branch
    run sh "$TW" remove t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "worktree removed: $TASK_WT"
    output_has "not deleted: my-change-t1"
    branch_exists my-change-t1 || { echo "the task branch was deleted"; false; }
    read_fix_line TASK-BRANCH-NOT-DELETED
    case "$fix_text" in
        (*"git branch -d my-change-t1"*) ;;
        (*) echo "the remedy names no git branch -d: $fix_text"; false ;;
    esac
    assert_names_no_merge "$fix_text"
    rm -f "$task_branch_lock"
    git branch -d my-change-t1
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
}

@test "task-worktree discard: a rejected branch deletion prints TASK-BRANCH-NOT-DELETED with git branch -D" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    lock_task_branch
    run sh "$TW" discard t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "task work"
    output_has "worktree removed: $TASK_WT"
    output_has "not deleted: my-change-t1"
    branch_exists my-change-t1 || { echo "the task branch was deleted"; false; }
    read_fix_line TASK-BRANCH-NOT-DELETED
    case "$fix_text" in
        (*"recorded as a finding"*"git branch -D my-change-t1"*) ;;
        (*) echo "the remedy names no finding before git branch -D: $fix_text"; false ;;
    esac
    assert_names_no_merge "$fix_text"
    rm -f "$task_branch_lock"
    git branch -D my-change-t1
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
}

@test "task-worktree merge: rejects a tag with no task branch" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    change_head=$(git rev-parse my-change)
    run sh "$TW" merge t9
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-MISSING: "
    [ "$(git rev-parse my-change)" = "$change_head" ] || { echo "the change branch moved"; false; }
}

@test "task-worktree merge: rejects the primary checkout" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    cd "$REPO"
    run sh "$TW" merge t1
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    assert_task_unchanged "$change_head"
}

@test "task-worktree merge: merges unsigned when commit.gpgsign is true and signing fails" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    # Any signing attempt runs this stub, which fails, so the fixture never
    # reaches a real key.
    printf '#!/bin/sh\nexit 1\n' > "$BATS_TEST_TMPDIR/gpg-fails"
    chmod +x "$BATS_TEST_TMPDIR/gpg-fails"
    git config gpg.program "$BATS_TEST_TMPDIR/gpg-fails"
    git config commit.gpgsign true
    task_tip=$(git rev-parse my-change-t1)
    run sh "$TW" merge t1
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    [ "$(git rev-parse HEAD^2)" = "$task_tip" ] \
        || { echo "HEAD is not a merge of the task branch"; git log --oneline -3; false; }
    run git log -1 --format=%G? HEAD
    [ "$output" = N ] || { echo "the merge commit signature status is $output"; false; }
}

@test "task-worktree: finish and --no-merge are usage errors" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    for args in "$retired_command t1" "$retired_command --no-merge t1" "remove --no-merge t1" "merge --no-merge t1"; do
        # $args is split on purpose: it is two or three arguments.
        run sh "$TW" $args
        [ "$status" -eq 2 ] || { echo "$args: $status: $output"; false; }
    done
    assert_task_unchanged "$change_head"
    git rev-parse -q --verify MERGE_HEAD >/dev/null \
        && { echo "a merge was started"; false; }
    true
}

# --- remove -------------------------------------------------------------------

@test "task-worktree remove: a task branch with no commits is removed and the change branch does not move" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh "$TW" start review
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    change_head=$(git rev-parse my-change)
    run sh "$TW" remove review
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    output_lacks "merged: "
    [ ! -e "$CHANGE_ROOT/.worktrees/my-change-review" ] \
        || { echo "the review worktree remains"; false; }
    run branch_exists my-change-review
    [ "$status" -ne 0 ] || { echo "the review branch remains"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] \
        || { echo "the change branch moved"; false; }
}

@test "task-worktree remove: rejects a task branch with a commit and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    task_tip=$(git rev-parse my-change-t1)
    run sh "$TW" remove t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-HAS-COMMITS: "
    output_has "never gated or reviewed"
    output_has "task-worktree.sh discard t1"
    output_lacks "task-worktree.sh merge"
    assert_task_unchanged "$change_head"
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] \
        || { echo "the task branch moved"; false; }
    git rev-parse -q --verify MERGE_HEAD >/dev/null \
        && { echo "a merge was started"; false; }
    true
}

@test "task-worktree remove: the TASK-DIRTY fix line names remove" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh "$TW" start review
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    printf 'scratch\n' > "$CHANGE_ROOT/.worktrees/my-change-review/scratch.txt"
    run sh "$TW" remove review
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-DIRTY: "
    output_has "run remove review again"
    [ -f "$CHANGE_ROOT/.worktrees/my-change-review/scratch.txt" ] \
        || { echo "the untracked file was lost"; false; }
    branch_exists my-change-review || { echo "the review branch was deleted"; false; }
}

@test "task-worktree remove: removes without --force, so a worktree git will not remove remains" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    add_submodule_to_task
    # The task branch is merged, so remove gets past its commit check and
    # reaches the removal.
    git -c commit.gpgsign=false merge -q --no-ff --no-edit my-change-t1
    run sh "$TW" remove t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "not removed: $TASK_WT"
    [ -d "$TASK_WT" ] || { echo "the task worktree was removed"; false; }
    is_registered "$TASK_WT" || { echo "the task worktree is not registered"; false; }
    branch_exists my-change-t1 || { echo "the task branch was deleted"; false; }
}

@test "task-worktree remove: rejects a missing tag and an extra argument" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh "$TW" start review
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    change_head=$(git rev-parse my-change)
    run sh "$TW" remove
    [ "$status" -eq 2 ] || { echo "no tag: $status: $output"; false; }
    output_has "remove <tag>"
    run sh "$TW" remove review extra
    [ "$status" -eq 2 ] || { echo "extra argument: $status: $output"; false; }
    [ -d "$CHANGE_ROOT/.worktrees/my-change-review" ] \
        || { echo "the review worktree was removed"; false; }
    branch_exists my-change-review || { echo "the review branch was deleted"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] \
        || { echo "the change branch moved"; false; }
}

# --- a branch checked out outside the change worktree ------------------------

@test "task-worktree: merge, remove and discard reject a task branch checked out outside the change worktree" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    make_sibling
    change_head=$(git rev-parse my-change)
    sibling_tip=$(git rev-parse my-change-other)
    for command in discard remove merge; do
        run sh "$TW" "$command" other
        [ "$status" -eq 1 ] || { echo "$command: $status: $output"; false; }
        output_has "fix TASK-NOT-NESTED: "
        output_has "$SIBLING"
        [ -f "$SIBLING/sibling.txt" ] || { echo "$command: the sibling was removed"; false; }
        is_registered "$SIBLING" || { echo "$command: the sibling is not registered"; false; }
        [ "$(git rev-parse my-change-other)" = "$sibling_tip" ] \
            || { echo "$command: the sibling branch or its commit is gone"; false; }
        [ "$(git rev-parse my-change)" = "$change_head" ] \
            || { echo "$command: the change branch moved"; false; }
    done
}

# --- a task worktree that is not on the task branch ---------------------------

# Starts t1 with a commit, detaches the task worktree's HEAD, and adds an
# untracked file, then runs $1 and asserts that it rejects with
# TASK-NOT-ON-BRANCH and changes nothing. A worktree nested inside a detached
# task worktree is TASK-NESTED, which runs first; the tests under "a worktree
# nested inside the task path" cover it.
assert_rejects_off_branch() {
    start_with_commit
    task_tip=$(git rev-parse my-change-t1)
    git -C "$TASK_WT" checkout -q --detach
    printf 'untracked\n' > "$TASK_WT/untracked.txt"
    change_head=$(git rev-parse my-change)
    run sh "$TW" "$1" t1
    [ "$status" -eq 1 ] || { echo "$1: $status: $output"; false; }
    output_has "fix TASK-NOT-ON-BRANCH: "
    output_has "git -C $TASK_WT checkout my-change-t1"
    # Under merge the line names no merging command (the round 4 ruling): the
    # task goes back to its subagent. Under remove and discard it names the
    # command that was run.
    case "$1" in
        (merge)
            output_has "the task goes back to its subagent (develop-change)"
            output_lacks "run merge"
            output_lacks "task-worktree.sh merge" ;;
        (*) output_has "then run $1 t1 again" ;;
    esac
    assert_task_unchanged "$change_head"
    is_registered "$TASK_WT" || { echo "the task worktree is not registered"; false; }
    [ -f "$TASK_WT/untracked.txt" ] || { echo "the untracked file was removed"; false; }
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] \
        || { echo "the task branch moved"; false; }
}

@test "task-worktree merge: rejects a task worktree that is not on the task branch and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_off_branch merge
}

@test "task-worktree remove: rejects a task worktree that is not on the task branch and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_off_branch remove
}

@test "task-worktree discard: rejects a task worktree that is not on the task branch and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_off_branch discard
}

# Starts t1 with a commit, detaches the task worktree's HEAD and commits on it,
# then runs $1 and asserts that it rejects with TASK-NOT-ON-BRANCH, lists the
# detached commit, tells the reader to record it, and changes nothing: the
# detached commit is still the worktree's HEAD.
assert_rejects_off_branch_with_commit() {
    start_with_commit
    task_tip=$(git rev-parse my-change-t1)
    git -C "$TASK_WT" checkout -q --detach
    printf 'detached work\n' > "$TASK_WT/src/detached.txt"
    git -C "$TASK_WT" add -A
    git -C "$TASK_WT" -c commit.gpgsign=false commit -qm "detached work"
    detached_head=$(git -C "$TASK_WT" rev-parse HEAD)
    detached_commit=$(git -C "$TASK_WT" log -1 --format='%h %s' HEAD)
    change_head=$(git rev-parse my-change)
    run sh "$TW" "$1" t1
    [ "$status" -eq 1 ] || { echo "$1: $status: $output"; false; }
    output_has "$detached_commit"
    output_has "fix TASK-NOT-ON-BRANCH: "
    output_has "record each one as a finding"
    case "$1" in
        (merge)
            output_has "the task goes back to its subagent (develop-change)"
            # The merge line, not the generic one: it names no checkout.
            output_lacks "checkout"
            output_lacks "run merge"
            output_lacks "task-worktree.sh merge" ;;
        (*) output_has "then run $1 t1 again" ;;
    esac
    assert_task_unchanged "$change_head"
    is_registered "$TASK_WT" || { echo "the task worktree is not registered"; false; }
    [ "$(git -C "$TASK_WT" rev-parse HEAD)" = "$detached_head" ] \
        || { echo "the detached commit is no longer the worktree's HEAD"; false; }
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] \
        || { echo "the task branch moved"; false; }
}

@test "task-worktree merge: lists a commit on a detached task worktree HEAD and names record, not merge" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_off_branch_with_commit merge
}

@test "task-worktree remove: lists a commit on a detached task worktree HEAD and names record" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_off_branch_with_commit remove
}

@test "task-worktree discard: lists a commit on a detached task worktree HEAD and names record" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_off_branch_with_commit discard
}

# --- discard ------------------------------------------------------------------

@test "task-worktree discard: lists the commits, removes the worktree and the branch, and the change branch does not move" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    task_commit=$(git log -1 --format='%h %s' my-change-t1)
    run sh "$TW" discard t1
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    output_has "$task_commit"
    [ ! -e "$TASK_WT" ] || { echo "the task worktree remains"; false; }
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] \
        || { echo "the change branch moved"; false; }
    [ ! -e src/task.txt ] || { echo "the task's work is in the change worktree"; false; }
}

@test "task-worktree discard: rejects a task worktree with an uncommitted change and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    task_tip=$(git rev-parse my-change-t1)
    printf 'edited\n' > "$TASK_WT/src/task.txt"
    run sh "$TW" discard t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-DIRTY: "
    output_has "run discard t1 again"
    assert_task_unchanged "$change_head"
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] \
        || { echo "the task branch moved"; false; }
    [ "$(cat "$TASK_WT/src/task.txt")" = edited ] || { echo "the edit was lost"; false; }
}

@test "task-worktree discard: rejects a task worktree with a worktree registered inside it" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    git -C "$TASK_WT" worktree add -q "$TASK_WT/.worktrees/inner" -b inner
    run sh "$TW" discard t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-NESTED: "
    output_has "run discard t1 again"
    assert_task_unchanged "$change_head"
    [ -d "$TASK_WT/.worktrees/inner" ] || { echo "the inner worktree was removed"; false; }
}

@test "task-worktree discard: rejects a tag with no task branch" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    change_head=$(git rev-parse my-change)
    run sh "$TW" discard t9
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-MISSING: "
    [ "$(git rev-parse my-change)" = "$change_head" ] || { echo "the change branch moved"; false; }
}

@test "task-worktree discard: rejects a missing tag, an extra argument, and --no-merge" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    run sh "$TW" discard
    [ "$status" -eq 2 ] || { echo "no tag: $status: $output"; false; }
    output_has "discard <tag>"
    run sh "$TW" discard t1 extra
    [ "$status" -eq 2 ] || { echo "extra argument: $status: $output"; false; }
    run sh "$TW" discard --no-merge t1
    [ "$status" -eq 2 ] || { echo "discard --no-merge: $status: $output"; false; }
    assert_task_unchanged "$change_head"
}

# --- a git step that fails ----------------------------------------------------

# make_failing_git WORD — a directory to put first on PATH, with a git that
# exits 128 when one of its arguments is exactly WORD and runs the real git
# for every other call.
make_failing_git() {
    real_git=$(command -v git)
    stub_directory="$BATS_TEST_TMPDIR/failing-git"
    mkdir -p "$stub_directory"
    cat > "$stub_directory/git" <<STUB
#!/bin/sh
for argument in "\$@"; do
    if [ "\$argument" = "$1" ]; then
        echo "fatal: stub failure of git $1" >&2
        exit 128
    fi
done
exec "$real_git" "\$@"
STUB
    chmod +x "$stub_directory/git"
    printf '%s\n' "$stub_directory"
}

@test "task-worktree remove: a failed git worktree list exits 2 and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    change_head=$(git rev-parse my-change)
    stub_directory=$(make_failing_git list)
    PATH="$stub_directory:$PATH" run sh "$TW" remove t1
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "git worktree list failed"
    assert_task_unchanged "$change_head"
}

@test "task-worktree remove: a failed git status in the task worktree exits 2 and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    change_head=$(git rev-parse my-change)
    stub_directory=$(make_failing_git status)
    PATH="$stub_directory:$PATH" run sh "$TW" remove t1
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "git status failed in $TASK_WT"
    assert_task_unchanged "$change_head"
}

@test "task-worktree remove: a failed git rev-list exits 2 and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    stub_directory=$(make_failing_git rev-list)
    PATH="$stub_directory:$PATH" run sh "$TW" remove t1
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "git rev-list failed"
    assert_task_unchanged "$change_head"
}

@test "task-worktree discard: a failed git log exits 2 and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    task_tip=$(git rev-parse my-change-t1)
    stub_directory=$(make_failing_git log)
    PATH="$stub_directory:$PATH" run sh "$TW" discard t1
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "git log failed"
    assert_task_unchanged "$change_head"
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] \
        || { echo "the task branch moved"; false; }
}

# --- a git step that fails in the CHANGE-BUSY checks --------------------------

# make_git_failing_on is in helpers.bash.

# $1 is the git step the run states as failed. The run exits 2, states that
# whether an operation is in progress in the change worktree cannot be read,
# and prints no fix line.
assert_busy_unreadable() {
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "$1 failed, so whether an operation is in progress in $CHANGE_ROOT cannot be read."
    if printf '%s\n' "$output" | grep -q '^fix '; then
        echo "a fix line was printed: $output"; false
    fi
}

# $1 is the case pattern of the git step that fails. A task worktree t1 with no
# commit and nothing in progress in the change worktree: before the step was
# checked, its failure read as "nothing in progress" and remove retired t1.
assert_remove_rejects_unreadable_busy() {
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    change_head=$(git rev-parse my-change)
    stub_directory=$(make_git_failing_on "$1")
    PATH="$stub_directory:$PATH" run sh "$TW" remove t1
    assert_busy_unreadable "$2"
    output_lacks "worktree removed"
    assert_task_unchanged "$change_head"
}

@test "task-worktree remove: a failed git rev-parse --git-path rebase-merge exits 2 and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    stop_rebase_on_conflict
    stub_directory=$(make_git_failing_on '*" rev-parse --git-path rebase-merge "*')
    PATH="$stub_directory:$PATH" run sh "$TW" remove t1
    assert_busy_unreadable "git rev-parse --git-path rebase-merge"
    assert_task_unchanged "$change_head"
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] || { echo "the task branch moved"; false; }
    [ -d "$(git rev-parse --git-path rebase-merge)" ] \
        || { echo "the rebase is no longer in progress"; false; }
}

@test "task-worktree remove: a failed git rev-parse --git-path rebase-apply exits 2 and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    stop_rebase_on_conflict
    stub_directory=$(make_git_failing_on '*" rev-parse --git-path rebase-apply "*')
    PATH="$stub_directory:$PATH" run sh "$TW" remove t1
    assert_busy_unreadable "git rev-parse --git-path rebase-apply"
    assert_task_unchanged "$change_head"
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] || { echo "the task branch moved"; false; }
    [ -d "$(git rev-parse --git-path rebase-merge)" ] \
        || { echo "the rebase is no longer in progress"; false; }
}

@test "task-worktree remove: a failed git rev-parse --git-path MERGE_HEAD exits 2 and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_remove_rejects_unreadable_busy '*" rev-parse --git-path MERGE_HEAD "*' \
        "git rev-parse --git-path MERGE_HEAD"
}

@test "task-worktree remove: a failed git rev-parse --git-path CHERRY_PICK_HEAD exits 2 and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_remove_rejects_unreadable_busy '*" rev-parse --git-path CHERRY_PICK_HEAD "*' \
        "git rev-parse --git-path CHERRY_PICK_HEAD"
}

@test "task-worktree remove: a failed git rev-parse --git-path REVERT_HEAD exits 2 and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_remove_rejects_unreadable_busy '*" rev-parse --git-path REVERT_HEAD "*' \
        "git rev-parse --git-path REVERT_HEAD"
}

@test "task-worktree remove: a failed git ls-files -u before any proof exits 2 and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_remove_rejects_unreadable_busy '*" ls-files -u "*' "git ls-files -u"
}

# $1 is the case pattern of the git step that fails and $2 the step the run
# states as failed. The reviewer's sequence (finding-73): merge t2 stops at
# TASK-CONFLICT, then discard t2 runs with the read of the t2 branch tip
# failing. Before the read was checked, the merge of t2 read as another merge
# and the remedy was to abort it and run discard t2 again.
assert_discard_rejects_unreadable_task_tip() {
    stop_t2_merge_on_conflict
    stub_directory=$(make_git_failing_on "$1")
    PATH="$stub_directory:$PATH" run sh "$TW" discard t2
    assert_busy_unreadable "$2"
    output_lacks "then run discard"
    output_lacks "discarding the commits"
    [ -d "$CHANGE_ROOT/.worktrees/my-change-t2" ] || { echo "the t2 worktree was removed"; false; }
    [ "$(git rev-parse -q --verify my-change-t2)" = "$t2_tip" ] \
        || { echo "the t2 branch moved or was deleted"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] || { echo "the change branch moved"; false; }
    [ "$(git rev-parse -q --verify MERGE_HEAD)" = "$t2_tip" ] \
        || { echo "the t2 merge is no longer in progress"; false; }
}

@test "task-worktree discard: a failed read of the task branch tip with the merge of this task in progress exits 2 and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_discard_rejects_unreadable_task_tip \
        '*" rev-parse "*"--verify refs/heads/my-change-t2 "*' \
        "git rev-parse --verify refs/heads/my-change-t2"
}

@test "task-worktree discard: a failed git show-ref of the task branch with the merge of this task in progress exits 2 and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_discard_rejects_unreadable_task_tip \
        '*" show-ref --verify --quiet refs/heads/my-change-t2 "*' \
        "git show-ref --verify refs/heads/my-change-t2"
}

@test "task-worktree remove: a failed git branch --show-current exits 2, states the failure, and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    change_head=$(git rev-parse my-change)
    stub_directory=$(make_git_failing_on '*" branch --show-current "*')
    PATH="$stub_directory:$PATH" run sh "$TW" remove t1
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "git branch --show-current failed, so the change branch in $CHANGE_ROOT cannot be read."
    output_lacks "HEAD is detached"
    output_lacks "worktree removed"
    assert_task_unchanged "$change_head"
}

# $1 is the case pattern of the git step that fails and $2 the step the run
# states as failed. A merge of a commit no branch names is left in progress in
# the change worktree, and start t2 runs with that step failing.
assert_start_rejects_unreadable_merge() {
    make_side_conflict
    change_head=$(git rev-parse my-change)
    run git -c commit.gpgsign=false merge --no-edit "$side_commit"
    [ "$status" -ne 0 ] || { echo "the merge did not conflict: $output"; false; }
    stub_directory=$(make_git_failing_on "$1")
    PATH="$stub_directory:$PATH" run sh "$TW" start t2
    assert_busy_unreadable "$2"
    assert_task_unchanged "$change_head"
    [ ! -e "$CHANGE_ROOT/.worktrees/my-change-t2" ] || { echo "a t2 worktree was created"; false; }
    run branch_exists my-change-t2
    [ "$status" -ne 0 ] || { echo "a t2 branch was created"; false; }
    [ "$(git rev-parse -q --verify MERGE_HEAD)" = "$side_commit" ] \
        || { echo "the merge is no longer in progress"; false; }
}

@test "task-worktree start: a failed git rev-parse --verify MERGE_HEAD with a merge in progress exits 2 and creates nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_start_rejects_unreadable_merge '*" rev-parse -q --verify MERGE_HEAD "*' \
        "git rev-parse --verify MERGE_HEAD"
}

@test "task-worktree start: a failed git for-each-ref --points-at with a merge in progress exits 2 and creates nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_start_rejects_unreadable_merge '*" for-each-ref --points-at="*' \
        "git for-each-ref --points-at"
}

@test "task-worktree start: a failed git rev-parse --short with a merge in progress exits 2 and creates nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_start_rejects_unreadable_merge '*" rev-parse --short "*' \
        "git rev-parse --short"
}

@test "task-worktree merge: a failed git ls-files -u after a conflicting merge exits 2 and removes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # The stub fails ls-files -u only while MERGE_HEAD exists, so the check
    # before any proof passes and the check after the merge fails.
    start_tag_with_commit t2 "t2 side" src/shared.txt
    printf 'change side\n' > src/shared.txt
    commit_all "conflicting work on the change branch"
    change_head=$(git rev-parse my-change)
    t2_tip=$(git rev-parse my-change-t2)
    real_git=$(command -v git)
    stub_directory="$BATS_TEST_TMPDIR/git-failing-on"
    mkdir -p "$stub_directory"
    cat > "$stub_directory/git" <<STUB
#!/bin/sh
case " \$* " in
    (*" ls-files -u "*)
        if "$real_git" rev-parse -q --verify MERGE_HEAD >/dev/null; then
            echo "fatal: stub failure of git \$*" >&2
            exit 128
        fi ;;
esac
exec "$real_git" "\$@"
STUB
    chmod +x "$stub_directory/git"
    PATH="$stub_directory:$PATH" run sh "$TW" merge t2
    assert_busy_unreadable "git ls-files -u"
    output_lacks "merged: my-change-t2"
    [ -d "$CHANGE_ROOT/.worktrees/my-change-t2" ] || { echo "the t2 worktree was removed"; false; }
    [ "$(git rev-parse -q --verify my-change-t2)" = "$t2_tip" ] \
        || { echo "the t2 branch moved or was deleted"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] || { echo "the change branch moved"; false; }
}

# --- a git step that fails in the TASK-NOT-ON-BRANCH proof --------------------

@test "task-worktree remove: a failed git rev-list on a detached task worktree exits 2 and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    git -C "$TASK_WT" checkout -q --detach
    change_head=$(git rev-parse my-change)
    stub_directory=$(make_failing_git rev-list)
    PATH="$stub_directory:$PATH" run sh "$TW" remove t1
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "git rev-list failed"
    output_lacks "fix TASK-NOT-ON-BRANCH"
    assert_task_unchanged "$change_head"
}

@test "task-worktree remove: a failed git log on a detached task worktree with a commit exits 2 and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    git -C "$TASK_WT" checkout -q --detach
    printf 'detached work\n' > "$TASK_WT/src/detached.txt"
    git -C "$TASK_WT" add -A
    git -C "$TASK_WT" -c commit.gpgsign=false commit -qm "detached work"
    change_head=$(git rev-parse my-change)
    stub_directory=$(make_failing_git log)
    PATH="$stub_directory:$PATH" run sh "$TW" remove t1
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "git log failed"
    output_lacks "fix TASK-NOT-ON-BRANCH"
    assert_task_unchanged "$change_head"
}

# --- a task worktree whose directory was deleted ------------------------------

# Deletes the task worktree's directory. git still lists it, as prunable.
delete_task_directory() {
    rm -rf "$TASK_WT"
    run git worktree list --porcelain
    output_has "prunable"
}

# Asserts that the task worktree is no longer registered.
assert_not_registered() {
    run is_registered "$1"
    [ "$status" -ne 0 ] || { echo "$1 is still registered"; false; }
}

@test "task-worktree remove: a task worktree whose directory was deleted is retired when its branch has no commits" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    change_head=$(git rev-parse my-change)
    delete_task_directory
    run sh "$TW" remove t1
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    assert_not_registered "$TASK_WT"
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] \
        || { echo "the change branch moved"; false; }
}

@test "task-worktree remove: a task worktree whose directory was deleted is rejected when its branch has commits" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    task_tip=$(git rev-parse my-change-t1)
    task_commit=$(git log -1 --format='%h %s' my-change-t1)
    delete_task_directory
    run sh "$TW" remove t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "$task_commit"
    output_has "fix TASK-HAS-COMMITS: "
    output_has "task-worktree.sh discard t1"
    is_registered "$TASK_WT" || { echo "the task worktree is not registered"; false; }
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] \
        || { echo "the task branch moved or was deleted"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] \
        || { echo "the change branch moved"; false; }
}

@test "task-worktree discard: a task worktree whose directory was deleted is retired, and its commits are listed" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    task_commit=$(git log -1 --format='%h %s' my-change-t1)
    delete_task_directory
    run sh "$TW" discard t1
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    output_has "$task_commit"
    assert_not_registered "$TASK_WT"
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] \
        || { echo "the change branch moved"; false; }
}

@test "task-worktree merge: a task worktree whose directory was deleted is rejected, returned to its subagent, and nothing changes" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    task_tip=$(git rev-parse my-change-t1)
    delete_task_directory
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-DIRECTORY-MISSING: "
    output_has "the task goes back to its subagent (develop-change)"
    output_has "git worktree remove $TASK_WT"
    output_has "git worktree add $TASK_WT my-change-t1"
    output_lacks "run merge"
    output_lacks "task-worktree.sh merge"
    output_lacks "merged: "
    is_registered "$TASK_WT" || { echo "the task worktree is not registered"; false; }
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] \
        || { echo "the task branch moved or was deleted"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] \
        || { echo "the change branch moved"; false; }
    # The remedy restores the worktree, with the task's commit in it.
    git worktree remove "$TASK_WT"
    git worktree add -q "$TASK_WT" my-change-t1
    [ -f "$TASK_WT/src/task.txt" ] || { echo "the restored worktree lacks the task's work"; false; }
}

@test "task-worktree start: a tag whose task worktree directory was deleted is TASK-EXISTS, and the remedy retires it" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    delete_task_directory
    run sh "$TW" start t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-EXISTS: "
    assert_task_exists_remedy
    is_registered "$TASK_WT" || { echo "the task worktree is not registered"; false; }
    # The remedy as the fix line states it: remove, which rejects on the
    # commit, then discard once the commit is recorded, then start again.
    run sh "$TW" remove t1
    [ "$status" -eq 1 ] || { echo "remove: $status: $output"; false; }
    output_has "fix TASK-HAS-COMMITS: "
    run sh "$TW" discard t1
    [ "$status" -eq 0 ] || { echo "discard: $status: $output"; false; }
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "start again: $status: $output"; false; }
}

# Starts t1 with a commit, detaches the task worktree's HEAD, commits on it,
# and deletes the directory, then runs $1 and asserts that it rejects with
# TASK-NOT-ON-BRANCH, lists the detached commit, names the removal of the
# registration rather than a checkout, and changes nothing.
assert_rejects_off_branch_directory_deleted() {
    start_with_commit
    task_tip=$(git rev-parse my-change-t1)
    git -C "$TASK_WT" checkout -q --detach
    printf 'detached work\n' > "$TASK_WT/src/detached.txt"
    git -C "$TASK_WT" add -A
    git -C "$TASK_WT" -c commit.gpgsign=false commit -qm "detached work"
    detached_commit=$(git -C "$TASK_WT" log -1 --format='%h %s' HEAD)
    change_head=$(git rev-parse my-change)
    delete_task_directory
    run sh "$TW" "$1" t1
    [ "$status" -eq 1 ] || { echo "$1: $status: $output"; false; }
    output_has "$detached_commit"
    output_has "fix TASK-NOT-ON-BRANCH: "
    output_has "record each one as a finding"
    output_lacks "checkout"
    case "$1" in
        (merge)
            output_has "the task goes back to its subagent (develop-change)"
            output_lacks "run merge"
            output_lacks "task-worktree.sh merge" ;;
        (*)
            output_has "git worktree remove $TASK_WT"
            output_has "then run $1 t1 again" ;;
    esac
    is_registered "$TASK_WT" || { echo "the task worktree is not registered"; false; }
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] \
        || { echo "the task branch moved or was deleted"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] \
        || { echo "the change branch moved"; false; }
}

@test "task-worktree merge: a detached task worktree whose directory was deleted lists its commit and names record, not merge" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_off_branch_directory_deleted merge
}

@test "task-worktree remove: a detached task worktree whose directory was deleted lists its commit, and the remedy retires it" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_off_branch_directory_deleted remove
    git worktree remove "$TASK_WT"
    run sh "$TW" remove t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-HAS-COMMITS: "
}

@test "task-worktree discard: a detached task worktree whose directory was deleted lists its commit, and the remedy retires it" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_off_branch_directory_deleted discard
    git worktree remove "$TASK_WT"
    run sh "$TW" discard t1
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
}

# --- a locked task worktree ---------------------------------------------------

# Starts t1 with a commit and locks the task worktree, then runs $1 and asserts
# that it rejects with TASK-LOCKED before any merge or removal.
assert_rejects_locked() {
    start_with_commit
    git worktree lock --reason "in use" "$TASK_WT"
    change_head=$(git rev-parse my-change)
    task_tip=$(git rev-parse my-change-t1)
    run sh "$TW" "$1" t1
    [ "$status" -eq 1 ] || { echo "$1: $status: $output"; false; }
    output_has "fix TASK-LOCKED: "
    output_has "git worktree unlock $TASK_WT"
    output_lacks "merged: "
    case "$1" in
        (merge)
            output_has "the task goes back to its subagent (develop-change)"
            output_lacks "run merge"
            output_lacks "task-worktree.sh merge" ;;
        (*) output_has "then run $1 t1 again" ;;
    esac
    assert_task_unchanged "$change_head"
    is_registered "$TASK_WT" || { echo "the task worktree is not registered"; false; }
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] \
        || { echo "the task branch moved"; false; }
    run git worktree list --porcelain
    output_has "locked in use"
    git rev-parse -q --verify MERGE_HEAD >/dev/null \
        && { echo "a merge was started"; false; }
    true
}

@test "task-worktree merge: rejects a locked task worktree before merging and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_locked merge
}

@test "task-worktree remove: rejects a locked task worktree and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_locked remove
}

@test "task-worktree discard: rejects a locked task worktree and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_locked discard
}

# --- a task worktree on another branch ----------------------------------------

# Starts t1 with a commit, checks out a new branch in the task worktree and
# commits on it, then runs $1 and asserts that it rejects with
# TASK-NOT-ON-BRANCH, lists the commit, and changes nothing.
assert_rejects_other_branch() {
    start_with_commit
    task_tip=$(git rev-parse my-change-t1)
    git -C "$TASK_WT" checkout -q -b my-change-side
    printf 'side work\n' > "$TASK_WT/src/side.txt"
    git -C "$TASK_WT" add -A
    git -C "$TASK_WT" -c commit.gpgsign=false commit -qm "side work"
    side_tip=$(git rev-parse my-change-side)
    side_commit=$(git log -1 --format='%h %s' my-change-side)
    change_head=$(git rev-parse my-change)
    run sh "$TW" "$1" t1
    [ "$status" -eq 1 ] || { echo "$1: $status: $output"; false; }
    output_has "$side_commit"
    output_has "fix TASK-NOT-ON-BRANCH: "
    output_has "record each one as a finding"
    case "$1" in
        (merge)
            output_has "the task goes back to its subagent (develop-change)"
            output_lacks "run merge"
            output_lacks "task-worktree.sh merge" ;;
        (*)
            output_has "git -C $TASK_WT checkout my-change-t1"
            output_has "then run $1 t1 again" ;;
    esac
    assert_task_unchanged "$change_head"
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] \
        || { echo "the task branch moved"; false; }
    [ "$(git rev-parse my-change-side)" = "$side_tip" ] \
        || { echo "the other branch moved"; false; }
    [ "$(git -C "$TASK_WT" branch --show-current)" = my-change-side ] \
        || { echo "the task worktree left the other branch"; false; }
}

@test "task-worktree merge: rejects a task worktree on another branch, lists its commit, and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_other_branch merge
}

@test "task-worktree remove: rejects a task worktree on another branch, lists its commit, and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_other_branch remove
}

@test "task-worktree discard: rejects a task worktree on another branch, lists its commit, and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_other_branch discard
}

# --- a worktree nested by task-worktree.sh ------------------------------------

# Starts t1, with a commit when $1 is with-commit, and runs start inner from
# the task worktree, which nests my-change-t1-inner inside it.
start_with_nested_task() {
    if [ "$1" = with-commit ]; then
        start_with_commit
    else
        run sh "$TW" start t1
        [ "$status" -eq 0 ] || { echo "$output"; false; }
    fi
    INNER_WT="$TASK_WT/.worktrees/my-change-t1-inner"
    run sh -c 'cd "$1" && sh "$2" start inner' sh "$TASK_WT" "$TW"
    [ "$status" -eq 0 ] || { echo "start inner: $output"; false; }
    [ -d "$INNER_WT" ] || { echo "no nested worktree at $INNER_WT"; false; }
}

# Runs the TASK-NESTED remedy for a worktree task-worktree.sh created.
remove_nested_task() {
    run sh -c 'cd "$1" && sh "$2" remove inner' sh "$TASK_WT" "$TW"
    [ "$status" -eq 0 ] || { echo "remove inner: $status: $output"; false; }
}

# Runs $1 against the task worktree with a nested task worktree and asserts
# the TASK-NESTED rejection, which names remove from the task worktree.
assert_rejects_nested_task() {
    change_head=$(git rev-parse my-change)
    task_tip=$(git rev-parse my-change-t1)
    run sh "$TW" "$1" t1
    [ "$status" -eq 1 ] || { echo "$1: $status: $output"; false; }
    output_has "fix TASK-NESTED: "
    output_has "$INNER_WT"
    output_has "run task-worktree.sh remove <tag> from $TASK_WT"
    output_lacks "task-worktree.sh merge"
    output_lacks "run merge"
    assert_task_unchanged "$change_head"
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] \
        || { echo "the task branch moved"; false; }
    is_registered "$INNER_WT" || { echo "the nested worktree is not registered"; false; }
}

@test "task-worktree merge: rejects a worktree nested by task-worktree.sh, and its remedy retires it" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_nested_task with-commit
    assert_rejects_nested_task merge
    output_has "the task goes back to its subagent (develop-change)"
    remove_nested_task
    assert_not_registered "$INNER_WT"
    run sh "$TW" merge t1
    [ "$status" -eq 0 ] || { echo "merge after the remedy: $status: $output"; false; }
}

@test "task-worktree remove: rejects a worktree nested by task-worktree.sh, and its remedy retires it" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_nested_task without-commit
    assert_rejects_nested_task remove
    output_has "Then run remove t1 again"
    remove_nested_task
    run sh "$TW" remove t1
    [ "$status" -eq 0 ] || { echo "remove after the remedy: $status: $output"; false; }
    assert_not_registered "$TASK_WT"
}

@test "task-worktree discard: rejects a worktree nested by task-worktree.sh, and its remedy retires it" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_nested_task with-commit
    assert_rejects_nested_task discard
    output_has "Then run discard t1 again"
    remove_nested_task
    run sh "$TW" discard t1
    [ "$status" -eq 0 ] || { echo "discard after the remedy: $status: $output"; false; }
    assert_not_registered "$TASK_WT"
}

@test "task-worktree remove: rejects a worktree nested by hand and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    change_head=$(git rev-parse my-change)
    git -C "$TASK_WT" worktree add -q "$TASK_WT/.worktrees/inner" -b inner
    run sh "$TW" remove t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-NESTED: "
    output_has "$TASK_WT/.worktrees/inner"
    output_has "git worktree remove <path> (no --force)"
    output_has "Then run remove t1 again"
    assert_task_unchanged "$change_head"
    is_registered "$TASK_WT/.worktrees/inner" \
        || { echo "the inner worktree is not registered"; false; }
}

# --- a deleted task directory with a worktree registered inside it ------------

# Starts t1 with a commit, nests my-change-t1-inner inside it with a commit of
# its own, and deletes the task directory, which deletes the nested directory
# with it. git still lists both worktrees.
start_nested_and_delete_task_directory() {
    start_with_nested_task with-commit
    printf 'inner work\n' > "$INNER_WT/inner.txt"
    git -C "$INNER_WT" add -A
    git -C "$INNER_WT" -c commit.gpgsign=false commit -qm "inner work"
    delete_task_directory
}

# Runs $1 against the deleted task directory and asserts the TASK-NESTED
# rejection, with a remedy that is followed from the change worktree, and that
# no registration, branch or commit changed.
assert_rejects_nested_in_missing_directory() {
    change_head=$(git rev-parse my-change)
    task_tip=$(git rev-parse my-change-t1)
    inner_tip=$(git rev-parse my-change-t1-inner)
    run sh "$TW" "$1" t1
    [ "$status" -eq 1 ] || { echo "$1: $status: $output"; false; }
    output_has "fix TASK-NESTED: "
    output_has "$INNER_WT"
    # The task path begins with $CHANGE_ROOT, so the comma is what pins the
    # change worktree, not the task path, as the place to run from.
    output_has "from $CHANGE_ROOT, for each listed path"
    output_lacks "from $TASK_WT"
    output_has "git log --oneline refs/heads/my-change-t1..refs/heads/<branch>"
    output_has "git worktree remove <path> (no --force)"
    output_has "git branch -D <branch>"
    output_has "For a path .worktrees/my-change-t1-<tag>, <branch> is my-change-t1-<tag>, and these steps discard its commits"
    output_lacks "task-worktree.sh merge"
    output_lacks "run merge"
    output_lacks "merged: "
    output_lacks "fix TASK-DIRECTORY-MISSING"
    is_registered "$TASK_WT" || { echo "the task worktree is not registered"; false; }
    is_registered "$INNER_WT" || { echo "the nested worktree is not registered"; false; }
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] \
        || { echo "the task branch moved or was deleted"; false; }
    [ "$(git rev-parse my-change-t1-inner)" = "$inner_tip" ] \
        || { echo "the nested branch moved or was deleted"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] \
        || { echo "the change branch moved"; false; }
}

# Follows the TASK-NESTED remedy for the deleted task directory, from the
# change worktree.
retire_nested_in_missing_directory() {
    run git log --oneline my-change-t1..my-change-t1-inner
    output_has "inner work"
    git worktree remove "$INNER_WT"
    git branch -D my-change-t1-inner >/dev/null
    assert_not_registered "$INNER_WT"
}

@test "task-worktree remove: a deleted task directory with a worktree registered inside it is TASK-NESTED, and the remedy retires it" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_nested_and_delete_task_directory
    assert_rejects_nested_in_missing_directory remove
    output_has "Then run remove t1 again"
    retire_nested_in_missing_directory
    # The task branch has a commit, so remove now stops on it.
    run sh "$TW" remove t1
    [ "$status" -eq 1 ] || { echo "remove after the remedy: $status: $output"; false; }
    output_has "fix TASK-HAS-COMMITS: "
}

@test "task-worktree discard: a deleted task directory with a worktree registered inside it is TASK-NESTED, and the remedy retires it" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_nested_and_delete_task_directory
    assert_rejects_nested_in_missing_directory discard
    output_has "Then run discard t1 again"
    retire_nested_in_missing_directory
    run sh "$TW" discard t1
    [ "$status" -eq 0 ] || { echo "discard after the remedy: $status: $output"; false; }
    assert_not_registered "$TASK_WT"
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
}

@test "task-worktree merge: a deleted task directory with a worktree registered inside it is TASK-NESTED, returned to its subagent" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_nested_and_delete_task_directory
    assert_rejects_nested_in_missing_directory merge
    output_has "the task goes back to its subagent (develop-change)"
    retire_nested_in_missing_directory
    # With nothing nested, the missing directory itself is rejected.
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "merge after the remedy: $status: $output"; false; }
    output_has "fix TASK-DIRECTORY-MISSING: "
}

# --- the remaining cells of the state matrix ----------------------------------

@test "task-worktree discard: a task branch with no commits is removed and the change branch does not move" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    change_head=$(git rev-parse my-change)
    run sh "$TW" discard t1
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    output_has "discarding the commits on my-change-t1"
    output_has "branch deleted: my-change-t1"
    [ ! -e "$TASK_WT" ] || { echo "the task worktree remains"; false; }
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] \
        || { echo "the change branch moved"; false; }
}

@test "task-worktree remove: rejects a task worktree with an uncommitted change, and the remedy retires it" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    change_head=$(git rev-parse my-change)
    printf 'edited\n' > "$TASK_WT/src/.gitkeep"
    run sh "$TW" remove t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-DIRTY: "
    output_has "run remove t1 again"
    assert_task_unchanged "$change_head"
    [ "$(cat "$TASK_WT/src/.gitkeep")" = edited ] || { echo "the edit was lost"; false; }
    git -C "$TASK_WT" checkout -q -- src/.gitkeep
    run sh "$TW" remove t1
    [ "$status" -eq 0 ] || { echo "remove after the remedy: $status: $output"; false; }
}

@test "task-worktree discard: rejects a task worktree with an untracked file and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse my-change)
    printf 'new\n' > "$TASK_WT/src/untracked.txt"
    run sh "$TW" discard t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-DIRTY: "
    output_has "run discard t1 again"
    assert_task_unchanged "$change_head"
    [ -f "$TASK_WT/src/untracked.txt" ] || { echo "the untracked file was lost"; false; }
}

@test "task-worktree start: a tag whose branch is checked out outside the change worktree is TASK-EXISTS and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    make_sibling
    sibling_tip=$(git rev-parse my-change-other)
    run sh "$TW" start other
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-EXISTS: "
    output_has "choose another tag"
    [ ! -e "$CHANGE_ROOT/.worktrees/my-change-other" ] \
        || { echo "a worktree was created"; false; }
    is_registered "$SIBLING" || { echo "the sibling is not registered"; false; }
    [ "$(git rev-parse my-change-other)" = "$sibling_tip" ] \
        || { echo "the sibling branch moved"; false; }
}

# --- a task path left with no task branch -------------------------------------

# Starts t1, detaches the task worktree's HEAD, commits on it, and deletes the
# task branch, so a worktree remains registered at the task path with no task
# branch. With $1 = deleted, the directory is deleted as well.
leave_worktree_without_branch() {
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    git -C "$TASK_WT" checkout -q --detach
    printf 'leftover work\n' > "$TASK_WT/src/leftover.txt"
    git -C "$TASK_WT" add -A
    git -C "$TASK_WT" -c commit.gpgsign=false commit -qm "leftover work"
    LEFTOVER_HEAD=$(git -C "$TASK_WT" rev-parse HEAD)
    LEFTOVER_COMMIT=$(git -C "$TASK_WT" log -1 --format='%h %s' HEAD)
    git branch -q -D my-change-t1
    if [ "$1" = deleted ]; then
        delete_task_directory
    fi
}

# Runs merge, remove and discard against the leftover and asserts each
# rejects with TASK-MISSING, lists the leftover commit, and names the
# removal of the registration, which merges nothing.
assert_missing_names_registered_leftover() {
    change_head=$(git rev-parse my-change)
    for command in merge remove discard; do
        run sh "$TW" "$command" t1
        [ "$status" -eq 1 ] || { echo "$command: $status: $output"; false; }
        output_has "fix TASK-MISSING: "
        output_has "$LEFTOVER_COMMIT"
        output_has "record"
        output_has "git worktree remove $TASK_WT"
        output_lacks "task-worktree.sh merge"
        output_lacks "run merge"
        is_registered "$TASK_WT" || { echo "$command: the leftover is not registered"; false; }
        [ "$(git rev-parse my-change)" = "$change_head" ] \
            || { echo "$command: the change branch moved"; false; }
    done
}

@test "task-worktree: merge, remove and discard name the registered leftover of a task path with no branch" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    leave_worktree_without_branch present
    assert_missing_names_registered_leftover
    [ "$(git -C "$TASK_WT" rev-parse HEAD)" = "$LEFTOVER_HEAD" ] \
        || { echo "the leftover HEAD moved"; false; }
    # The remedy as the fix line states it.
    git worktree remove "$TASK_WT"
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "start after the remedy: $status: $output"; false; }
}

@test "task-worktree: merge, remove and discard name the registered leftover whose directory was deleted" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    leave_worktree_without_branch deleted
    assert_missing_names_registered_leftover
    git worktree remove "$TASK_WT"
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "start after the remedy: $status: $output"; false; }
}

@test "task-worktree: merge, remove and discard name an unregistered leftover directory with no branch" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    mkdir -p "$TASK_WT"
    printf 'keep\n' > "$TASK_WT/keep.txt"
    for command in merge remove discard; do
        run sh "$TW" "$command" t1
        [ "$status" -eq 1 ] || { echo "$command: $status: $output"; false; }
        output_has "fix TASK-MISSING: "
        output_has "delete it by hand after reading it"
        output_lacks "task-worktree.sh merge"
        [ -f "$TASK_WT/keep.txt" ] || { echo "$command: the directory was changed"; false; }
    done
}

# --- a task branch whose task directory is not a registered worktree --------

# Starts t1 with a commit, leaves an untracked file in it, then removes its
# `.git` file and prunes, so the task branch exists, nothing is registered at
# the task path, and the directory and its untracked file remain.
unregister_task_directory() {
    start_with_commit
    printf 'unreported\n' > "$TASK_WT/untracked.txt"
    rm "$TASK_WT/.git"
    git worktree prune
}

# Runs $1 against t1 in the state unregister_task_directory leaves and asserts
# the TASK-NOT-REGISTERED rejection, and that the task branch, the change
# branch and the directory did not change.
assert_rejects_unregistered_task_directory() {
    unregister_task_directory
    change_head=$(git rev-parse my-change)
    task_tip=$(git rev-parse my-change-t1)
    run sh "$TW" "$1" t1
    [ "$status" -eq 1 ] || { echo "$1: $status: $output"; false; }
    read_fix_line TASK-NOT-REGISTERED
    case "$fix_text" in
        (*"$TASK_WT is not a registered worktree"*) ;;
        (*) echo "the fix line does not name the directory: $fix_text"; false ;;
    esac
    case "$fix_text" in
        (*"delete it by hand after reading it"*) ;;
        (*) echo "the fix line does not name deleting it by hand: $fix_text"; false ;;
    esac
    assert_names_no_merge "$fix_text"
    output_lacks "merged: "
    output_lacks "none was removed"
    output_lacks "branch deleted:"
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] \
        || { echo "$1: the task branch moved or was deleted"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] \
        || { echo "$1: the change branch moved"; false; }
    [ -f "$TASK_WT/untracked.txt" ] || { echo "$1: the untracked file was deleted"; false; }
    [ -f "$TASK_WT/src/task.txt" ] || { echo "$1: the directory was changed"; false; }
}

@test "task-worktree merge: a task directory that is not a registered worktree is TASK-NOT-REGISTERED, returned to its subagent, and nothing changes" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_unregistered_task_directory merge
    output_has "the task goes back to its subagent (develop-change)"
}

@test "task-worktree remove: a task directory that is not a registered worktree is TASK-NOT-REGISTERED, and nothing changes" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_unregistered_task_directory remove
    output_has "then run remove t1 again"
}

@test "task-worktree discard: a task directory that is not a registered worktree is TASK-NOT-REGISTERED, and nothing changes" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    assert_rejects_unregistered_task_directory discard
    output_has "then run discard t1 again"
    # The remedy as the fix line states it: read, record, delete by hand.
    rm -rf "$TASK_WT"
    run sh "$TW" discard t1
    [ "$status" -eq 0 ] || { echo "discard after the remedy: $status: $output"; false; }
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
}

@test "task-worktree start: a registered leftover with no branch is TASK-EXISTS, with its commit listed" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    leave_worktree_without_branch present
    run sh "$TW" start t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-EXISTS: "
    output_has "$LEFTOVER_COMMIT"
    assert_task_exists_remedy
    [ "$(git -C "$TASK_WT" rev-parse HEAD)" = "$LEFTOVER_HEAD" ] \
        || { echo "the leftover HEAD moved"; false; }
}

@test "task-worktree start: a registered leftover with no branch and no directory is TASK-EXISTS, and the remedy retires it" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    leave_worktree_without_branch deleted
    run sh "$TW" start t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-EXISTS: "
    output_has "$LEFTOVER_COMMIT"
    assert_task_exists_remedy
    is_registered "$TASK_WT" || { echo "the leftover is not registered"; false; }
    git worktree remove "$TASK_WT"
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "start after the remedy: $status: $output"; false; }
}

@test "task-worktree remove: a failed git log of a registered leftover with no branch exits 2 and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    leave_worktree_without_branch present
    change_head=$(git rev-parse my-change)
    stub_directory=$(make_failing_git log)
    PATH="$stub_directory:$PATH" run sh "$TW" remove t1
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "git log failed"
    output_lacks "fix TASK-MISSING"
    is_registered "$TASK_WT" || { echo "the leftover is not registered"; false; }
    [ "$(git -C "$TASK_WT" rev-parse HEAD)" = "$LEFTOVER_HEAD" ] \
        || { echo "the leftover HEAD moved"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] \
        || { echo "the change branch moved"; false; }
}

# --- a worktree nested inside the task path, whatever is registered there -----

# Runs each command in $2.. against t1 and asserts the TASK-NESTED rejection
# for the nested worktree at $1, with the remedy followed from the change
# worktree, because task-worktree.sh cannot be run from a task path that is
# missing, not on the task branch, or not a registered worktree. Asserts that
# no registration, branch or commit changed.
assert_nested_from_change_worktree() {
    nested_path=$1
    shift
    change_head=$(git rev-parse my-change)
    worktree_list_before=$(git worktree list --porcelain)
    branches_before=$(git for-each-ref --format='%(refname) %(objectname)' refs/heads)
    for command in "$@"; do
        run sh "$TW" "$command" t1
        [ "$status" -eq 1 ] || { echo "$command: $status: $output"; false; }
        output_has "fix TASK-NESTED: "
        output_has "$nested_path"
        # The comma pins the change worktree as the place to run from: the
        # task path begins with $CHANGE_ROOT, so "from $CHANGE_ROOT" alone
        # also matches "from $TASK_WT".
        output_has "from $CHANGE_ROOT, for each listed path"
        output_lacks "from $TASK_WT"
        output_has "git worktree remove <path> (no --force)"
        output_has "git branch -D <branch>"
        output_lacks "fix TASK-NOT-ON-BRANCH"
        output_lacks "fix TASK-MISSING"
        output_lacks "fix TASK-EXISTS"
        output_lacks "checkout"
        output_lacks "task-worktree.sh merge"
        output_lacks "run merge"
        output_lacks "merged: "
        case "$command" in
            (merge) output_has "the task goes back to its subagent (develop-change)" ;;
            (*) output_has "Then run $command t1 again" ;;
        esac
        [ "$(git worktree list --porcelain)" = "$worktree_list_before" ] \
            || { echo "$command: a registration changed"; git worktree list --porcelain; false; }
        [ "$(git for-each-ref --format='%(refname) %(objectname)' refs/heads)" = "$branches_before" ] \
            || { echo "$command: a branch changed"; false; }
        [ "$(git rev-parse my-change)" = "$change_head" ] \
            || { echo "$command: the change branch moved"; false; }
    done
}

@test "task-worktree: a detached task worktree whose directory was deleted, with a worktree nested inside it, is TASK-NESTED for merge, remove and discard" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_nested_task with-commit
    git -C "$TASK_WT" checkout -q --detach
    delete_task_directory
    assert_nested_from_change_worktree "$INNER_WT" merge remove discard
    output_has "$TASK_WT is missing"
    # The remedy, followed from the change worktree.
    git worktree remove "$INNER_WT"
    git branch -D my-change-t1-inner >/dev/null
    run sh "$TW" remove t1
    [ "$status" -eq 1 ] || { echo "remove after the remedy: $status: $output"; false; }
    output_has "fix TASK-NOT-ON-BRANCH: "
}

@test "task-worktree: a detached task worktree with a worktree nested inside it is TASK-NESTED for merge, remove and discard, before any checkout is named" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_nested_task with-commit
    git -C "$TASK_WT" checkout -q --detach
    assert_nested_from_change_worktree "$INNER_WT" merge remove discard
    output_has "$TASK_WT is not on my-change-t1"
    git worktree remove "$INNER_WT"
    git branch -D my-change-t1-inner >/dev/null
    run sh "$TW" remove t1
    [ "$status" -eq 1 ] || { echo "remove after the remedy: $status: $output"; false; }
    output_has "fix TASK-NOT-ON-BRANCH: "
}

@test "task-worktree: a task worktree on another branch with a worktree nested inside it is TASK-NESTED for merge, remove and discard" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_nested_task with-commit
    git -C "$TASK_WT" checkout -q -b other-branch
    assert_nested_from_change_worktree "$INNER_WT" merge remove discard
    output_has "$TASK_WT is not on my-change-t1"
}

@test "task-worktree: a registered leftover with no task branch and a worktree nested inside it is TASK-NESTED for start, merge, remove and discard" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_nested_task without-commit
    git -C "$TASK_WT" checkout -q --detach
    git branch -q -D my-change-t1
    assert_nested_from_change_worktree "$INNER_WT" start merge remove discard
    output_has "$TASK_WT is not on my-change-t1"
    # With no task branch, the commits are listed against the change branch.
    output_has "git log --oneline refs/heads/my-change..refs/heads/<branch>"
    git worktree remove "$INNER_WT"
    git branch -D my-change-t1-inner >/dev/null
    run sh "$TW" remove t1
    [ "$status" -eq 1 ] || { echo "remove after the remedy: $status: $output"; false; }
    output_has "fix TASK-MISSING: "
}

@test "task-worktree: an unregistered task directory with a worktree registered inside it is TASK-NESTED for start, merge, remove and discard" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    mkdir -p "$TASK_WT/.worktrees"
    git worktree add -q "$TASK_WT/.worktrees/inner" -b inner
    assert_nested_from_change_worktree "$TASK_WT/.worktrees/inner" start merge remove discard
    output_has "$TASK_WT is not a registered worktree"
    [ -d "$TASK_WT/.worktrees/inner" ] || { echo "the nested worktree was deleted"; false; }
}

# --- a worktree removal git rejects under remove and discard ------------------

# Runs $1 against t1, whose worktree contains a submodule, so git rejects its
# removal. Asserts the TASK-NOT-REMOVED fix line and that nothing changed, then
# follows the remedy: clears the submodule and runs $1 again, which retires the
# worktree and the branch.
assert_not_removed_and_retired() {
    change_head=$(git rev-parse my-change)
    task_tip=$(git rev-parse my-change-t1)
    run sh "$TW" "$1" t1
    [ "$status" -eq 1 ] || { echo "$1: $status: $output"; false; }
    output_has "not removed: $TASK_WT"
    output_has "fix TASK-NOT-REMOVED: "
    output_has "git rejected the removal of $TASK_WT"
    output_has "task-worktree.sh $1 t1 retires it"
    output_lacks "worktree removed:"
    output_lacks "branch deleted:"
    output_lacks "task-worktree.sh merge"
    output_lacks "run merge"
    case "$1" in
        (remove) output_has "nothing was changed" ;;
        (discard)
            output_has "nothing was deleted"
            output_has "each commit listed above is recorded as a finding" ;;
    esac
    [ -d "$TASK_WT" ] || { echo "the task worktree was removed"; false; }
    is_registered "$TASK_WT" || { echo "the task worktree is not registered"; false; }
    [ "$(git rev-parse my-change-t1)" = "$task_tip" ] \
        || { echo "the task branch moved or was deleted"; false; }
    [ "$(git rev-parse my-change)" = "$change_head" ] \
        || { echo "the change branch moved"; false; }
    git -C "$TASK_WT" submodule deinit -q -f sm
    rm -rf "$(git -C "$TASK_WT" rev-parse --absolute-git-dir)/modules"
    run sh "$TW" "$1" t1
    [ "$status" -eq 0 ] || { echo "$1 after the remedy: $status: $output"; false; }
    assert_not_registered "$TASK_WT"
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
}

@test "task-worktree remove: a rejected worktree removal prints TASK-NOT-REMOVED, changes nothing, and the remedy retires it" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    add_submodule_to_task
    # The submodule commit is merged into the change branch, so remove finds no
    # unmerged commit and reaches the removal.
    git -c commit.gpgsign=false merge -q --no-ff --no-edit my-change-t1
    assert_not_removed_and_retired remove
}

@test "task-worktree discard: a rejected worktree removal prints TASK-NOT-REMOVED, deletes nothing, and the remedy retires it" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    add_submodule_to_task
    assert_not_removed_and_retired discard
}

# --- a git step whose failure would read as a state ---------------------------

# $1 is the reason the run states. The run exits 2, states the reason, and
# prints no fix line.
assert_git_step_unreadable() {
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "$1"
    if printf '%s\n' "$output" | grep -q '^fix '; then
        echo "a fix line was printed: $output"; false
    fi
}

# Neither the task worktree nor the task branch exists.
assert_nothing_started() {
    [ ! -e "$TASK_WT" ] || { echo "a task worktree was created"; false; }
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "a task branch was created"; false; }
}

@test "task-worktree start: a failed git rev-parse --git-dir exits 2 and creates nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # Before the status was taken, an empty git dir differed from the common
    # git dir, and the primary-checkout check passed.
    stub_directory=$(make_git_failing_on '*" rev-parse --git-dir "*')
    PATH="$stub_directory:$PATH" run sh "$TW" start t1
    assert_git_step_unreadable \
        "git rev-parse --git-dir failed, so whether $CHANGE_ROOT is the primary checkout cannot be read."
    assert_nothing_started
}

@test "task-worktree start: a failed git rev-parse --git-common-dir exits 2 and creates nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    stub_directory=$(make_git_failing_on '*" rev-parse --git-common-dir "*')
    PATH="$stub_directory:$PATH" run sh "$TW" start t1
    assert_git_step_unreadable \
        "git rev-parse --git-common-dir failed, so whether $CHANGE_ROOT is the primary checkout cannot be read."
    assert_nothing_started
}

@test "task-worktree remove: a failed git show-ref of the task branch exits 2, is not read as an absent branch, and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # Before the status was taken, the failure read as "no task branch", and
    # the TASK-MISSING remedy removed the registration of a worktree whose
    # branch has a commit.
    start_with_commit
    change_head=$(git rev-parse my-change)
    stub_directory=$(make_git_failing_on '*" show-ref --verify --quiet refs/heads/my-change-t1 "*')
    PATH="$stub_directory:$PATH" run sh "$TW" remove t1
    assert_git_step_unreadable \
        "git show-ref --verify refs/heads/my-change-t1 failed, so whether the task branch exists cannot be read."
    output_lacks "TASK-MISSING"
    assert_task_unchanged "$change_head"
}

@test "task-worktree start: a failed git check-ignore exits 2, is not read as .worktrees/ not ignored, and creates nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    stub_directory=$(make_git_failing_on '*" check-ignore -q .worktrees/ "*')
    PATH="$stub_directory:$PATH" run sh "$TW" start t1
    assert_git_step_unreadable \
        "git check-ignore failed, so whether .worktrees/ is ignored in $CHANGE_ROOT cannot be read."
    output_lacks "WORKTREES-NOT-IGNORED"
    assert_nothing_started
}

@test "task-worktree remove: a failed git log of the commits TASK-HAS-COMMITS lists exits 2 and changes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # Before the status was taken, the fix line asked for each listed commit
    # to be recorded, and none was listed.
    start_with_commit
    change_head=$(git rev-parse my-change)
    stub_directory=$(make_git_failing_on '*" log --oneline refs/heads/my-change..refs/heads/my-change-t1 "*')
    PATH="$stub_directory:$PATH" run sh "$TW" remove t1
    assert_git_step_unreadable "git log failed, so the commits on my-change-t1 cannot be listed."
    output_lacks "TASK-HAS-COMMITS"
    assert_task_unchanged "$change_head"
}

# A task worktree t1 with a commit that conflicts with a commit on the change
# branch. Sets change_head.
start_conflicting_task() {
    start_with_commit
    printf 'change side\n' > src/task.txt
    commit_all "conflicting work on the change branch"
    change_head=$(git rev-parse my-change)
}

@test "task-worktree merge: a failed git rev-parse --verify MERGE_HEAD after a conflicting merge exits 2 and removes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # Before the status was taken, the failure read as "no merge in progress",
    # and TASK-MERGE-FAILED stated that nothing was merged.
    start_conflicting_task
    stub_directory=$(make_git_failing_on '*" rev-parse -q --verify MERGE_HEAD "*')
    PATH="$stub_directory:$PATH" run sh "$TW" merge t1
    assert_busy_unreadable "git rev-parse --verify MERGE_HEAD"
    output_lacks "TASK-MERGE-FAILED"
    assert_task_unchanged "$change_head"
}

@test "task-worktree merge: a failed git rev-parse of the task branch tip after a conflicting merge exits 2 and removes nothing" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_conflicting_task
    stub_directory=$(make_git_failing_on '*" rev-parse --verify refs/heads/my-change-t1 "*')
    PATH="$stub_directory:$PATH" run sh "$TW" merge t1
    assert_busy_unreadable "git rev-parse --verify refs/heads/my-change-t1"
    output_lacks "TASK-MERGE-FAILED"
    assert_task_unchanged "$change_head"
}

# --- a tag with the name of a task branch or the change branch ---------------

# A tag named $1 at the change branch tip: annotated when $2 is annotated,
# lightweight otherwise. git resolves a bare name that is both a branch and a
# tag to the tag (finding-87).
tag_change_tip() {
    if [ "$2" = annotated ]; then
        git -c tag.gpgsign=false tag -a -m "a tag named $1" "$1" refs/heads/my-change
    else
        git -c tag.gpgsign=false tag "$1" refs/heads/my-change
    fi
}

@test "task-worktree merge: a tag named as the task branch does not replace it, and the task commit is merged" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    task_tip=$(git rev-parse refs/heads/my-change-t1)
    tag_change_tip my-change-t1 annotated
    run sh "$TW" merge t1
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    output_lacks "Already up to date"
    output_lacks "TASK-BRANCH-NOT-DELETED"
    git merge-base --is-ancestor "$task_tip" refs/heads/my-change \
        || { echo "the task commit is not in the change branch"; false; }
    [ "$(git log -1 --format=%s refs/heads/my-change)" = "Merge branch 'my-change-t1' into my-change" ] \
        || { git log -1 --format=%s refs/heads/my-change; false; }
    [ ! -e "$TASK_WT" ] || { echo "the task worktree remains"; false; }
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
    git show-ref --verify --quiet refs/tags/my-change-t1 || { echo "the tag was deleted"; false; }
}

@test "task-worktree remove: a tag named as the task branch does not hide its commits, and remove rejects with TASK-HAS-COMMITS" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse refs/heads/my-change)
    task_tip=$(git rev-parse refs/heads/my-change-t1)
    tag_change_tip my-change-t1 lightweight
    run sh "$TW" remove t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-HAS-COMMITS: "
    output_has "task work"
    assert_task_unchanged "$change_head"
    [ "$(git rev-parse refs/heads/my-change-t1)" = "$task_tip" ] \
        || { echo "the task branch moved"; false; }
}

@test "task-worktree discard: a tag named as the task branch does not hide its commits, and discard lists them" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    task_short=$(git rev-parse --short refs/heads/my-change-t1)
    tag_change_tip my-change-t1 lightweight
    run sh "$TW" discard t1
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    output_has "discarding the commits on my-change-t1 that my-change lacks:"
    output_has "$task_short task work"
    run branch_exists my-change-t1
    [ "$status" -ne 0 ] || { echo "the task branch remains"; false; }
}

@test "task-worktree start: a tag named as the change branch does not replace it as the start point" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    git -c tag.gpgsign=false tag my-change refs/heads/main
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    [ "$(git rev-parse refs/heads/my-change-t1)" = "$(git rev-parse refs/heads/my-change)" ] \
        || { echo "the task branch does not start at the change branch"; false; }
}

@test "task-worktree remove: a tag named as the change branch does not hide the task commits" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    change_head=$(git rev-parse refs/heads/my-change)
    git -c tag.gpgsign=false tag my-change refs/heads/my-change-t1
    run sh "$TW" remove t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    output_has "fix TASK-HAS-COMMITS: "
    output_has "task work"
    [ -d "$TASK_WT" ] || { echo "the task worktree was removed"; false; }
    branch_exists my-change-t1 || { echo "the task branch was deleted"; false; }
    [ "$(git rev-parse refs/heads/my-change)" = "$change_head" ] \
        || { echo "the change branch moved"; false; }
}

@test "task-worktree remove: a tag named as the task branch does not hide the commits on a task worktree off its branch" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh "$TW" start t1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    git -C "$TASK_WT" checkout -q --detach
    printf 'detached work\n' > "$TASK_WT/src/detached.txt"
    git -C "$TASK_WT" add -A
    git -C "$TASK_WT" -c commit.gpgsign=false commit -qm "detached work"
    git -c tag.gpgsign=false tag my-change-t1 "$(git -C "$TASK_WT" rev-parse HEAD)"
    run sh "$TW" remove t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    read_fix_line TASK-NOT-ON-BRANCH
    output_has "detached work"
    case "$fix_text" in
        (*"the commits listed above are on its HEAD"*) ;;
        (*) echo "the fix line does not name the commits on its HEAD: $fix_text"; false ;;
    esac
}

@test "task-worktree remove: a tag named as the change branch does not hide the commits on a leftover task path" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    start_with_commit
    git -C "$TASK_WT" checkout -q --detach
    git branch -D -q my-change-t1
    git -c tag.gpgsign=false tag my-change "$(git -C "$TASK_WT" rev-parse HEAD)"
    run sh "$TW" remove t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    read_fix_line TASK-MISSING
    output_has "task work"
}

# --- a tag that is not a valid ref name ---------------------------------------

@test "task-worktree: every command rejects a tag that makes the task branch an invalid ref name, with exit 2 and the usage" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # Before the check, git worktree add rejected the name and TASK-NOT-CREATED
    # asked for start to be run again with the same tag (finding-88).
    for subcommand in start merge remove discard; do
        for tag in 't..x' 'x.lock' 'a~1' 'b:c' 'q?' 'a^b' 'a*' 'a[b' 'a\b' 'x.' 'a@{b'; do
            run sh "$TW" "$subcommand" "$tag"
            [ "$status" -eq 2 ] || { echo "$subcommand '$tag': $status: $output"; false; }
            output_has "is not a valid branch name"
            output_has "usage: task-worktree.sh start <tag>"
            output_lacks "fix "
        done
    done
    [ ! -e "$CHANGE_ROOT/.worktrees" ] || { echo "a worktree was created"; false; }
    [ "$(git for-each-ref --format='%(refname)' refs/heads/ | grep -c .)" -eq 2 ] \
        || { git for-each-ref refs/heads/; false; }
}

@test "task-worktree start: accepts a tag that begins with a dot, which makes a valid branch name" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh "$TW" start .t1
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
    branch_exists my-change-.t1 || { echo "no task branch"; false; }
}

# --- a remedy that concludes a merge, run with no editor ----------------------

# $1 is the command, run with sh -c as a fix line states it, with no editor
# variable, no global or system git config, a dumb terminal and no stdin: the
# environment of an agent shell with no TTY.
run_without_editor() {
    run env -u GIT_EDITOR -u VISUAL -u EDITOR TERM=dumb GIT_CONFIG_GLOBAL=/dev/null \
        GIT_CONFIG_NOSYSTEM=1 sh -c "$1" </dev/null
}

@test "task-worktree merge: the TASK-CONFLICT remedy concludes the merge with no editor, exactly as printed" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # Before --no-edit, git commit opened an editor, and with none it exited 1
    # (finding-89).
    start_conflicting_task
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    read_fix_line TASK-CONFLICT
    conclude_command=$(printf '%s\n' "$fix_text" \
        | sed -n 's/.*conclude the merge with \(git [^,]*\), then run remove t1\.$/\1/p')
    [ -n "$conclude_command" ] || { echo "no conclude command in: $fix_text"; false; }
    printf 'resolved\n' > src/task.txt
    git add src/task.txt
    run_without_editor "$conclude_command"
    [ "$status" -eq 0 ] || { echo "$conclude_command: $status: $output"; false; }
    run git rev-parse -q --verify MERGE_HEAD
    [ "$status" -ne 0 ] || { echo "the merge is still in progress"; false; }
    run sh "$TW" remove t1
    [ "$status" -eq 0 ] || { echo "$status: $output"; false; }
}

@test "task-worktree merge: the CHANGE-BUSY remedy for a rebase concludes it with no editor, exactly as printed" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # Before core.editor=true, git rebase --continue opened an editor for the
    # message of the commit that conflicted, and with none it exited 1
    # (finding-90).
    stop_rebase_on_conflict
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    read_fix_line CHANGE-BUSY
    conclude_command=$(printf '%s\n' "$fix_text" \
        | sed -n 's/.*resolve any conflict, then \(git [^)]*\)) or abort it.*/\1/p')
    [ -n "$conclude_command" ] || { echo "no conclude command in: $fix_text"; false; }
    printf 'resolved\n' > src/shared.txt
    git add src/shared.txt
    run_without_editor "$conclude_command"
    [ "$status" -eq 0 ] || { echo "$conclude_command: $status: $output"; false; }
    [ ! -d "$(git rev-parse --git-path rebase-merge)" ] \
        || { echo "the rebase is still in progress"; false; }
    [ "$(git branch --show-current)" = my-change ] \
        || { echo "HEAD is not on my-change after the rebase"; false; }
}

@test "task-worktree merge: the CHANGE-BUSY remedy for a cherry-pick concludes it with no editor, exactly as printed" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    printf 'base\n' > src/shared.txt
    commit_all "a file both sides change"
    git branch picked
    start_with_commit
    git checkout -q picked
    printf 'picked side\n' > src/shared.txt
    commit_all "the commit to pick"
    git checkout -q my-change
    printf 'change side\n' > src/shared.txt
    commit_all "conflicting work on the change branch"
    run git -c commit.gpgsign=false cherry-pick picked
    [ "$status" -ne 0 ] || { echo "the cherry-pick did not conflict: $output"; false; }
    run sh "$TW" merge t1
    [ "$status" -eq 1 ] || { echo "$status: $output"; false; }
    read_fix_line CHANGE-BUSY
    conclude_command=$(printf '%s\n' "$fix_text" \
        | sed -n 's/.*resolve any conflict, then \(git [^)]*\)) or abort it.*/\1/p')
    [ -n "$conclude_command" ] || { echo "no conclude command in: $fix_text"; false; }
    printf 'resolved\n' > src/shared.txt
    git add src/shared.txt
    run_without_editor "$conclude_command"
    [ "$status" -eq 0 ] || { echo "$conclude_command: $status: $output"; false; }
    [ ! -e "$(git rev-parse --git-path CHERRY_PICK_HEAD)" ] \
        || { echo "the cherry-pick is still in progress"; false; }
}
