# drop-plans.sh runs in a change worktree before the merge gate and leaves
# the change with no plan of its own: a plan it added is removed, a base plan
# it edited is restored, and a base plan it deleted stays deleted. Every test
# starts on a change branch off a main that already has one plan.

load helpers

setup() {
    make_fixture_repo
    mkdir -p docs/plans
    printf '# Old plan\n' > docs/plans/2025-12-01-old.md
    git add docs/plans
    git commit -qm 'old plan'
    make_change_worktree feature
}

drop() { run sh .guardrails/scripts/drop-plans.sh "$@"; }

# add_plan PATH — commit a new plan on the change branch.
add_plan() {
    printf '# New plan\n\nstep one\n' > "$1"
    git add "$1"
    git commit -qm "add $1"
}

# verifies: ADR-k3nkv3
@test "drop-plans: a plan the change added is removed in one commit" {
    add_plan docs/plans/2026-01-01-new.md
    drop --base main
    [ "$status" -eq 0 ]
    [ ! -e docs/plans/2026-01-01-new.md ]
    [ "$(git log -1 --format=%s)" = "chore: drop plans" ]
    [ -z "$(git status --porcelain)" ]
    printf '%s\n' "$output" | grep -qxF 'drop-plans: dropped docs/plans/2026-01-01-new.md'
    last=$(printf '%s\n' "$output" | tail -n 1)
    printf '%s\n' "$last" | grep -Eqx \
        'drop-plans: read a dropped plan with git show [0-9a-f]{40}\^:<path>'
    commit=$(printf '%s\n' "$last" | sed 's/.*git show \([0-9a-f]*\)^.*/\1/')
    [ "$(git show "$commit^:docs/plans/2026-01-01-new.md")" = "$(printf '# New plan\n\nstep one')" ]
}

# verifies: ADR-k3nkv3
@test "drop-plans: a base plan the change edited is restored, not deleted" {
    printf 'an edit\n' >> docs/plans/2025-12-01-old.md
    git commit -qam 'edit old plan'
    drop --base main
    [ "$status" -eq 0 ]
    [ "$(cat docs/plans/2025-12-01-old.md)" = "$(git show main:docs/plans/2025-12-01-old.md)" ]
    printf '%s\n' "$output" | grep -qxF 'drop-plans: restored docs/plans/2025-12-01-old.md'
    [ "$(git log -1 --format=%s)" = "chore: drop plans" ]
    [ -z "$(git status --porcelain)" ]
}

# verifies: ADR-k3nkv3
@test "drop-plans: a plan path with a glob character drops only that plan, not a base plan it matches" {
    printf '# A old\n' > "$REPO/docs/plans/a-old.md"
    git -C "$REPO" add docs/plans/a-old.md
    git -C "$REPO" commit -qm 'a-old plan'
    git merge -q --no-edit main
    add_plan 'docs/plans/a*.md'
    drop --base main
    [ "$status" -eq 0 ]
    git cat-file -e HEAD:docs/plans/a-old.md
    [ -e docs/plans/a-old.md ]
    if git cat-file -e 'HEAD:docs/plans/a*.md' 2>/dev/null; then false; fi
    [ -z "$(git status --porcelain)" ]
}

# verifies: ADR-k3nkv3
@test "drop-plans: a base plan the change deleted stays deleted, and nothing is committed" {
    git rm -q docs/plans/2025-12-01-old.md
    git commit -qm 'delete old plan'
    head=$(git rev-parse HEAD)
    drop --base main
    [ "$status" -eq 0 ]
    [ "$output" = "drop-plans: no plan to drop" ]
    [ "$(git rev-parse HEAD)" = "$head" ]
    [ ! -e docs/plans/2025-12-01-old.md ]
}

# verifies: ADR-k3nkv3
@test "drop-plans: a change that touches no plan commits nothing" {
    printf 'a\n' > src/a.txt
    git add src/a.txt
    git commit -qm 'add a'
    head=$(git rev-parse HEAD)
    drop --base main
    [ "$status" -eq 0 ]
    [ "$output" = "drop-plans: no plan to drop" ]
    [ "$(git rev-parse HEAD)" = "$head" ]
}

# verifies: ADR-k3nkv3
@test "drop-plans: the commit takes only the plans, and leaves other work as it was" {
    printf 'b\n' > src/b.txt
    git add src/b.txt
    git commit -qm 'add b'
    add_plan docs/plans/2026-01-01-new.md
    # Staged after the last commit, so only drop's own commit could take it.
    printf 'a\n' > src/a.txt
    git add src/a.txt
    printf 'b changed\n' > src/b.txt
    drop --base main
    [ "$status" -eq 0 ]
    [ "$(git show --name-only --format= HEAD)" = "docs/plans/2026-01-01-new.md" ]
    if git cat-file -e HEAD:src/a.txt 2>/dev/null; then
        echo "the staged src/a.txt was committed"; false
    fi
    [ "$(git status --porcelain)" = "$(printf 'A  src/a.txt\n M src/b.txt')" ]
}

# verifies: ADR-k3nkv3
@test "drop-plans: refuses a missing, empty or unknown argument with status 2" {
    add_plan docs/plans/2026-01-01-new.md
    head=$(git rev-parse HEAD)
    drop
    [ "$status" -eq 2 ]
    printf '%s\n' "$output" | grep -qF 'no base ref named'
    drop --base
    [ "$status" -eq 2 ]
    printf '%s\n' "$output" | grep -qF -e '--base takes a ref'
    drop --base main --verbose
    [ "$status" -eq 2 ]
    printf '%s\n' "$output" | grep -qF 'unknown argument: --verbose'
    [ "$(git rev-parse HEAD)" = "$head" ]
    [ -e docs/plans/2026-01-01-new.md ]
}

# verifies: ADR-k3nkv3
@test "drop-plans: refuses a ref that does not resolve with status 2" {
    add_plan docs/plans/2026-01-01-new.md
    head=$(git rev-parse HEAD)
    drop --base nosuchref
    [ "$status" -eq 2 ]
    printf '%s\n' "$output" | grep -qF -e 'cannot resolve the base ref nosuchref'
    [ "$(git rev-parse HEAD)" = "$head" ]
    [ -e docs/plans/2026-01-01-new.md ]
}

# verifies: ADR-k3nkv3
@test "drop-plans: refuses a base that is not an ancestor of HEAD with status 2" {
    add_plan docs/plans/2026-01-01-new.md
    head=$(git rev-parse HEAD)
    git -C "$REPO" branch throwaway main
    git -C "$REPO" worktree add -q "$BATS_TEST_TMPDIR/throwaway" throwaway
    printf 'x\n' > "$BATS_TEST_TMPDIR/throwaway/x.txt"
    git -C "$BATS_TEST_TMPDIR/throwaway" add x.txt
    git -C "$BATS_TEST_TMPDIR/throwaway" commit -qm x
    drop --base throwaway
    [ "$status" -eq 2 ]
    printf '%s\n' "$output" | grep -qF \
        'throwaway is not an ancestor of HEAD. The base moved: merge it again by rerunning from merge-change step 1.'
    [ "$(git rev-parse HEAD)" = "$head" ]
    [ -e docs/plans/2026-01-01-new.md ]
}

# verifies: ADR-k3nkv3
@test "drop-plans: refuses to run on the base branch with status 2" {
    cd "$REPO"
    head=$(git rev-parse HEAD)
    drop --base main
    [ "$status" -eq 2 ]
    printf '%s\n' "$output" | grep -qF 'main is the base branch'
    [ "$(git rev-parse HEAD)" = "$head" ]
    [ -e docs/plans/2025-12-01-old.md ]
}

# verifies: ADR-k3nkv3
@test "drop-plans: refuses to run on a detached HEAD with status 2" {
    add_plan docs/plans/2026-01-01-new.md
    git checkout -q --detach
    head=$(git rev-parse HEAD)
    drop --base main
    [ "$status" -eq 2 ]
    printf '%s\n' "$output" | grep -qF 'HEAD is detached'
    [ "$(git rev-parse HEAD)" = "$head" ]
    [ -e docs/plans/2026-01-01-new.md ]
}

# verifies: ADR-k3nkv3
@test "drop-plans: refuses a plan path git quotes with status 2, before anything changes" {
    add_plan docs/plans/2026-01-01-new.md
    add_plan 'docs/plans/2026-01-02-a"b.md'
    head=$(git rev-parse HEAD)
    drop --base main
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    printf '%s\n' "$output" | grep -qF 'git quotes the plan path "docs/plans/2026-01-02-a\"b.md"' \
        || { echo "$output"; false; }
    [ "$(git rev-parse HEAD)" = "$head" ]
    [ -e docs/plans/2026-01-01-new.md ]
    [ -e 'docs/plans/2026-01-02-a"b.md' ]
    [ -z "$(git status --porcelain)" ] || { git status --porcelain; false; }
}

# verifies: ADR-k3nkv3
@test "drop-plans: refuses a plan git reports with a status other than A, M or D, before anything changes" {
    add_plan docs/plans/2026-01-01-new.md
    rm docs/plans/2025-12-01-old.md
    ln -s ../../README.md docs/plans/2025-12-01-old.md
    git add -A docs/plans
    git commit -qm 'replace the old plan with a symlink'
    head=$(git rev-parse HEAD)
    drop --base main
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    printf '%s\n' "$output" | grep -qF 'status T for the plan path docs/plans/2025-12-01-old.md' \
        || { echo "$output"; false; }
    [ "$(git rev-parse HEAD)" = "$head" ]
    [ -e docs/plans/2026-01-01-new.md ]
    [ -L docs/plans/2025-12-01-old.md ]
    [ -z "$(git status --porcelain)" ] || { git status --porcelain; false; }
}

# verifies: ADR-k3nkv3
@test "drop-plans: a failed git diff of the plans exits 2, is not read as no plan to drop" {
    add_plan docs/plans/2026-01-01-new.md
    head=$(git rev-parse HEAD)
    stub_directory=$(make_git_failing_on '*" diff --name-status "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/drop-plans.sh --base main
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    printf '%s\n' "$output" | grep -qF 'git diff main HEAD -- docs/plans failed' \
        || { echo "$output"; false; }
    if printf '%s\n' "$output" | grep -qF 'no plan to drop'; then false; fi
    [ "$(git rev-parse HEAD)" = "$head" ]
    [ -e docs/plans/2026-01-01-new.md ]
}

# verifies: ADR-k3nkv3
@test "drop-plans: refuses an added plan with an unstaged edit with status 2, before anything changes" {
    # git rm fails on a modified file; checked first, the earlier plan is not
    # removed with no commit to take it.
    add_plan docs/plans/2026-01-01-new.md
    add_plan docs/plans/2026-01-02-edited.md
    printf 'uncommitted\n' >> docs/plans/2026-01-02-edited.md
    head=$(git rev-parse HEAD)
    drop --base main
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    printf '%s\n' "$output" | grep -qF 'docs/plans/2026-01-02-edited.md has uncommitted changes' \
        || { echo "$output"; false; }
    [ "$(git rev-parse HEAD)" = "$head" ]
    [ -e docs/plans/2026-01-01-new.md ]
    grep -qx uncommitted docs/plans/2026-01-02-edited.md
    [ "$(git status --porcelain)" = ' M docs/plans/2026-01-02-edited.md' ] || { git status --porcelain; false; }
}

# verifies: ADR-k3nkv3
@test "drop-plans: refuses an edited base plan with an unstaged edit with status 2, and keeps the edit" {
    # git checkout <ref> -- <path> would overwrite the edit without a word.
    printf 'an edit\n' >> docs/plans/2025-12-01-old.md
    git commit -qam 'edit old plan'
    printf 'uncommitted\n' >> docs/plans/2025-12-01-old.md
    head=$(git rev-parse HEAD)
    drop --base main
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    printf '%s\n' "$output" | grep -qF 'docs/plans/2025-12-01-old.md has uncommitted changes' \
        || { echo "$output"; false; }
    [ "$(git rev-parse HEAD)" = "$head" ]
    grep -qx uncommitted docs/plans/2025-12-01-old.md
    [ "$(git status --porcelain)" = ' M docs/plans/2025-12-01-old.md' ] || { git status --porcelain; false; }
}
