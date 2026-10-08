#!/usr/bin/env bats
# scripts/prune-plans.sh: fenced code inside a plan's task sections is replaced
# by a pointer at merge (merge-change step 1).
load helpers

PLAN=docs/plans/2026-01-01-x.md

# A repository on main with one plan already merged, and a linked worktree on
# branch feature: the shape merge-change step 1 runs in, and the only shape in
# which gr_base_branch tells the base from the change branch.
setup() {
    make_fixture_repo
    mkdir -p docs/plans
    cat > docs/plans/2025-12-01-old.md <<'EOF'
# Old plan

### T1 — old task

```sh
echo old
```
EOF
    commit_all "old plan"
    make_change_worktree feature
}

prune() {
    run sh .guardrails/scripts/prune-plans.sh "$@"
}

@test "prune: a fence in a T1 section becomes a pointer naming its lines and Files touched" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    cat > "$PLAN" <<'EOF'
# Plan

## Tasks

### T1 — do it

**Files touched:** `src/a.sh`, `tests/a.bats`

1. Write the test.

```sh
echo one
echo two
```

Prose after.
EOF
    commit_all plan
    cat > expected <<'EOF'
# Plan

## Tasks

### T1 — do it

**Files touched:** `src/a.sh`, `tests/a.bats`

1. Write the test.

*(Code pruned at merge: 2 lines. Files touched: `src/a.sh`, `tests/a.bats`.)*

Prose after.
EOF
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN: 1 block, 2 lines"
    diff expected "$PLAN"
}

@test "prune: a Files touched value wrapped onto a second line is read whole" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    cat > "$PLAN" <<'EOF'
### T1 — do it

**Files touched:** `src/a.sh`,
`tests/a.bats`

```sh
echo one
```
EOF
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    grep -qxF '*(Code pruned at merge: 1 line. Files touched: `src/a.sh`, `tests/a.bats`.)*' "$PLAN" \
        || { cat "$PLAN"; false; }
}

@test "prune: a bold field directly after Files touched is not part of the paths" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    cat > "$PLAN" <<'EOF'
### T1 — do it

**Files touched:** `src/a.sh`, `tests/a.bats`
**Parallel:** no (serial, before T2)

```sh
echo one
echo two
```
EOF
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    grep -qxF '*(Code pruned at merge: 2 lines. Files touched: `src/a.sh`, `tests/a.bats`.)*' "$PLAN" \
        || { cat "$PLAN"; false; }
}

@test "prune: a wrapped Files touched value ends at a bold field on the next line" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    cat > "$PLAN" <<'EOF'
### T1 — do it

**Files touched:** `src/a.sh`,
`tests/a.bats`
**Trace**: REQ-abc123

```sh
echo one
echo two
```
EOF
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    grep -qxF '*(Code pruned at merge: 2 lines. Files touched: `src/a.sh`, `tests/a.bats`.)*' "$PLAN" \
        || { cat "$PLAN"; false; }
    if grep -q 'pruned at merge.*Trace' "$PLAN"; then cat "$PLAN"; false; fi
}

@test "prune: a Files touched value that starts on the next line has no leading space" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    cat > "$PLAN" <<'EOF'
### T1 — do it

**Files touched:**
  `src/a.sh`, `tests/a.bats`

```sh
echo one
echo two
```
EOF
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    grep -qxF '*(Code pruned at merge: 2 lines. Files touched: `src/a.sh`, `tests/a.bats`.)*' "$PLAN" \
        || { cat "$PLAN"; false; }
}

@test "prune: one line and one block are counted in the singular" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    cat > "$PLAN" <<'EOF'
### T1 — do it

**Files touched:** `src/a.sh`

```sh
echo one
```
EOF
    commit_all plan
    prune --dry-run
    [ "$status" -eq 0 ]
    [ "$output" = "would prune $PLAN: 1 block, 1 line" ]
    prune
    [ "$status" -eq 0 ]
    [ "$output" = "pruned $PLAN: 1 block, 1 line" ]
    grep -qxF '*(Code pruned at merge: 1 line. Files touched: `src/a.sh`.)*' "$PLAN" \
        || { cat "$PLAN"; false; }
}

@test "prune: a fence indented inside a numbered step keeps its indentation" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    cat > "$PLAN" <<'EOF'
### T1 — do it

**Files touched:** `src/a.sh`

1. Write it:

   ```sh
   echo one
   ```
EOF
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    grep -qxF '   *(Code pruned at merge: 1 line. Files touched: `src/a.sh`.)*' "$PLAN" \
        || { cat "$PLAN"; false; }
}

@test "prune: a task without Files touched gets a pointer that names only the count" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # The pointer claims no more than it knows: a pruned fence may be a
    # reproduction command, not merged code (review round 2, finding 5).
    cat > "$PLAN" <<'EOF'
### T1 — do it

```sh
echo one
```
EOF
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    grep -qxF "*(Code pruned at merge: 1 line.)*" "$PLAN" \
        || { cat "$PLAN"; false; }
}

@test "prune: Task N, Task LN and T10 headings open task sections; Tests does not" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    cat > "$PLAN" <<'EOF'
### Tests

```sh
echo tests-kept
```

### Task L1: lettered

```sh
echo task-l1
```

### T10 — tenth

```sh
echo task-ten
```

## Task 2 — second

```sh
echo task-two
```
EOF
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN: 3 blocks, 3 lines"
    ! grep -q 'task-two\|task-l1\|task-ten' "$PLAN" || { cat "$PLAN"; false; }
    grep -q 'tests-kept' "$PLAN"
    grep -qx '## Task 2 — second' "$PLAN"
    grep -qx '### Task L1: lettered' "$PLAN"
    grep -qx '### T10 — tenth' "$PLAN"
}

@test "prune: a fence outside any task section is kept" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    cat > "$PLAN" <<'EOF'
## Design

```sh
echo design-kept
```

## Task 1 — do it

```sh
echo task-code
```
EOF
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    grep -q 'design-kept' "$PLAN"
    ! grep -q 'task-code' "$PLAN" || { cat "$PLAN"; false; }
}

@test "prune: a fence opening with red -> green inside a task section is kept" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    cat > "$PLAN" <<'EOF'
### T1 — do it

```text
red -> green: test one (expected 1, got 0)
```

```sh
echo task-code
```
EOF
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN: 1 block, 1 line"
    grep -q 'red -> green: test one' "$PLAN"
    ! grep -q 'task-code' "$PLAN" || { cat "$PLAN"; false; }
}

@test "prune: a tilde fence holding a backtick fence and a heading is one block" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    cat > "$PLAN" <<'EOF'
### T1 — do it

~~~~markdown
## Steps

```sh
echo nested
```
~~~~

```sh
echo after-the-tilde-block
```
EOF
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN: 2 blocks, 6 lines"
    ! grep -q 'nested\|after-the-tilde-block\|## Steps' "$PLAN" || { cat "$PLAN"; false; }
    grep -qxF "*(Code pruned at merge: 5 lines.)*" "$PLAN"
}

@test "prune: a task section ends at the next heading of its level, not at a lower one" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    cat > "$PLAN" <<'EOF'
## Task 1 — do it

### 1.1 Failing tests

```sh
echo sub-heading-code
```

## Notes

```sh
echo notes-kept
```
EOF
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    ! grep -q 'sub-heading-code' "$PLAN" || { cat "$PLAN"; false; }
    grep -q 'notes-kept' "$PLAN"
    grep -qx '### 1.1 Failing tests' "$PLAN"
}

@test "prune: by default only the branch's plans are pruned; --all takes every plan" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN"
    output_lacks "2025-12-01-old.md"
    grep -q 'echo old' docs/plans/2025-12-01-old.md
    prune --all
    [ "$status" -eq 0 ]
    output_has "pruned docs/plans/2025-12-01-old.md: 1 block, 1 line"
    ! grep -q 'echo old' docs/plans/2025-12-01-old.md
}

@test "prune: an uncommitted edit to a merged plan makes it the branch's plan" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '\nAn edit.\n' >> docs/plans/2025-12-01-old.md
    prune
    [ "$status" -eq 0 ]
    output_has "pruned docs/plans/2025-12-01-old.md"
}

@test "prune: --dry-run says would prune and changes nothing" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    commit_all plan
    prune --dry-run
    [ "$status" -eq 0 ]
    output_has "would prune $PLAN: 1 block, 1 line"
    git diff --quiet
    [ -z "$(git status --porcelain)" ]
}

@test "prune: a second run prints nothing and changes nothing" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    commit_all pruned
    prune
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    [ -z "$(git status --porcelain)" ]
}

@test "prune: a record citing a line at or after the first pruned fence leaves the plan whole" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    mkdir -p docs/verification
    printf '# Record\n\nSee 2026-01-01-x.md:1 for the heading.\nThe code is at docs/plans/2026-01-01-x.md:4.\n' \
        > docs/verification/2026-01-01-rec.md
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "left whole $PLAN: cited at docs/verification/2026-01-01-rec.md:4 as 2026-01-01-x.md:4"
    output_lacks "pruned"
    grep -q 'branch-code' "$PLAN"
}

@test "prune: a citation before the first pruned fence does not stop the prune" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    mkdir -p docs/verification
    printf 'See 2026-01-01-x.md:2.\n' > docs/verification/2026-01-01-rec.md
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN"
    output_lacks "left whole"
}

@test "prune: a citation in any tracked Markdown file, not only a record, leaves the plan whole" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # A plan cites another plan's lines as evidence too
    # (docs/plans/2026-09-16-scan-scope.md cites units-implementation.md by
    # line); pruning would move them (review round 1, finding 2).
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    mkdir -p docs/notes
    printf '# Notes\n\nThe code is at docs/plans/2026-01-01-x.md:4.\n' > docs/notes/other.md
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "left whole $PLAN: cited at docs/notes/other.md:3 as 2026-01-01-x.md:4"
    grep -q 'branch-code' "$PLAN"
}

@test "prune: a citation written as <plan> line <N> leaves the plan whole" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    mkdir -p docs/verification
    printf 'See `docs/plans/2026-01-01-x.md` line 4.\n' > docs/verification/2026-01-01-rec.md
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "left whole $PLAN: cited at docs/verification/2026-01-01-rec.md:1 as 2026-01-01-x.md line 4"
}

@test "prune: a plan that cites itself after its first pruned fence is left whole" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # Its own cross-reference would move with the lines it names.
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n\nSee 2026-01-01-x.md:4.\n' > "$PLAN"
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "left whole $PLAN: cited at $PLAN:7 as 2026-01-01-x.md:4"
}

@test "prune: a citation of a same-named file in another directory does not stop the prune" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # A record often shares its plan's basename; a path that puts the
    # basename under a directory other than plans/ names that other file.
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    mkdir -p docs/verification
    printf 'See docs/verification/2026-01-01-x.md:4.\n' > docs/verification/2026-01-01-x.md
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN"
    output_lacks "left whole"
}

@test "prune: an untracked file's citation is not read" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # The scan reads tracked Markdown, as the gates do; scratch is not a
    # citation anybody else can follow.
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    commit_all plan
    printf 'See 2026-01-01-x.md:4.\n' > scratch.md
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN"
}

@test "prune: prune_plans off prints that it pruned nothing and changes nothing" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    printf 'prune_plans: off\n' >> .guardrails/config.yaml
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    [ "$output" = "prune_plans: off, nothing pruned" ]
    [ -z "$(git status --porcelain)" ]
}

@test "prune: a prune_plans value other than on or off exits 2 naming it" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    printf 'prune_plans: maybe\n' >> .guardrails/config.yaml
    commit_all plan
    prune
    [ "$status" -eq 2 ]
    output_has "prune_plans"
    output_has "maybe"
    grep -q 'branch-code' "$PLAN"
}

@test "prune: a repository with no config file prunes" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    git rm -q .guardrails/config.yaml
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN"
}

@test "prune: an unknown argument exits 2" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    prune --bogus
    [ "$status" -eq 2 ]
    output_has "unknown argument: --bogus"
}

@test "prune: --base names the ref the branch's plans are diffed against" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # merge-change step 1 merges origin/<base> where a remote exists, while
    # local <base> may lag it. Diffed against local main, a plan the remote
    # base added would count as this branch's plan (review round 1, finding 5).
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    commit_all plan
    git branch upstream main
    git checkout -q upstream
    printf '### T1 — theirs\n\n```sh\necho theirs-code\n```\n' > docs/plans/2025-12-15-theirs.md
    commit_all "their plan, merged upstream unpruned"
    git checkout -q feature
    git -c commit.gpgsign=false merge -q --no-edit upstream
    prune --base upstream --dry-run
    [ "$status" -eq 0 ]
    output_has "would prune $PLAN"
    output_lacks "2025-12-15-theirs.md"
    # Against local main, the default, their plan reads as the branch's own.
    prune --dry-run
    [ "$status" -eq 0 ]
    output_has "would prune docs/plans/2025-12-15-theirs.md"
}

@test "prune: --base without a ref, or with a ref git cannot resolve, exits 2" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    prune --base
    [ "$status" -eq 2 ]
    output_has "--base takes a ref"
    prune --base no-such-ref
    [ "$status" -eq 2 ]
    output_has "no-such-ref"
}

@test "prune: a fence closes only at a marker at least as long as its opener" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # A four-backtick fence holds a three-backtick line as content (review
    # round 1, finding 3a).
    printf '### T1 — do it\n\n````sh\necho one\n```\necho two\n````\n' > "$PLAN"
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN: 1 block, 3 lines"
    ! grep -q 'echo two\|^`' "$PLAN" || { cat "$PLAN"; false; }
}

@test "prune: a marker line with text after it does not close the fence" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # A closing fence carries nothing but spaces or tabs after its marker, so
    # "```python" inside a fence is content (review round 1, finding 3b).
    printf '### T1 — do it\n\n```sh\necho one\n```python\necho two\n```  \n' > "$PLAN"
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN: 1 block, 3 lines"
    ! grep -q 'echo two\|^`' "$PLAN" || { cat "$PLAN"; false; }
}

@test "prune: a fence with no closing line is kept" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # The dry run comes first: pruning an unclosed fence would also make the
    # rewrite loop run forever (review round 1, finding 3c).
    printf '### T1 — do it\n\n```sh\necho closed\n```\n\n```sh\necho unclosed\n' > "$PLAN"
    commit_all plan
    prune --dry-run
    [ "$status" -eq 0 ]
    [ "$output" = "would prune $PLAN: 1 block, 1 line" ] || { echo "$output"; false; }
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN: 1 block, 1 line"
    ! grep -q 'echo closed' "$PLAN"
    grep -q 'echo unclosed' "$PLAN"
}

@test "prune: only a section's first Files touched line names the paths" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # A later "**Files touched:**" in the same task, such as one inside a
    # Done note, does not replace the task's own (review round 1, finding 3d).
    printf '### T1 — do it\n\n**Files touched:** `src/first.sh`\n\n```sh\necho code\n```\n\n**Files touched:** `src/second.sh`\n' > "$PLAN"
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    grep -qxF '*(Code pruned at merge: 1 line. Files touched: `src/first.sh`.)*' "$PLAN" ||
        { cat "$PLAN"; false; }
}

@test "prune: a draft fence naming red -> green mid-line is pruned; a marked red -> green line is kept" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # An attestation line opens with `red -> green`; a draft whose text names
    # the attestations is code like any other (review round 1, finding 4: a
    # 390-line SKILL.md draft in 2026-09-28-agent-first-skills-change-1.md was
    # kept). A list or bold marker may come first.
    cat > "$PLAN" <<'PLAN_EOF'
### T1 — do it

~~~~markdown
---
name: draft
---
Copy the `red -> green` attestations into the record.
~~~~

```text

- **red -> green**: test two (expected 1, got 0)
```
PLAN_EOF
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN: 1 block, 4 lines"
    ! grep -q 'name: draft' "$PLAN" || { cat "$PLAN"; false; }
    grep -q 'test two' "$PLAN"
}

@test "prune: a fence in the dispatch report shape, red -> green on a later line, is kept" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # develop-change's dispatch report opens with `task:` and carries its
    # `red -> green:` lines further down; the dispatcher writes it into the
    # plan, and merge-change step 6b copies it from there (review round 2,
    # finding 1).
    cat > "$PLAN" <<'PLAN_EOF'
### T1 — do it

**Files touched:** `src/a.sh`

```
task: T1
worktree: .worktrees/feature-t1
files touched: src/a.sh
tests added: t1 — verifies: D11
red -> green: t1 — watched fail for the right reason
result: 1 passed, 0 failed
surprises: none
```
PLAN_EOF
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    [ -z "$output" ] || { echo "$output"; false; }
    grep -q '^red -> green: t1' "$PLAN"
}

@test "prune: a fence naming red -> green only mid-line is pruned" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # A draft that tells its reader about the attestations is code, not an
    # attestation: the rule reads the start of a line only.
    cat > "$PLAN" <<'PLAN_EOF'
### T1 — do it

```text
task: T1
Copy each red -> green: line into the record.
```
PLAN_EOF
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN: 1 block, 2 lines"
    ! grep -q 'Copy each' "$PLAN" || { cat "$PLAN"; false; }
}

@test "prune: a plan the change renames and edits is the branch's plan" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # git diff detects renames by default, and a renamed plan is R, not A or
    # M (review round 2, finding 3).
    git mv docs/plans/2025-12-01-old.md docs/plans/2026-01-02-final.md
    printf '\nAn edit.\n' >> docs/plans/2026-01-02-final.md
    commit_all "rename the plan"
    git diff --name-status main | grep -q '^R' || { git diff --name-status main; false; }
    prune --dry-run
    [ "$status" -eq 0 ]
    [ "$output" = "would prune docs/plans/2026-01-02-final.md: 1 block, 1 line" ] || { echo "$output"; false; }
}

@test "prune: a Files touched value that is not a path is quoted, not called the merged code" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # docs/plans/2026-09-18-close-crcee5.md read "The merged code is in none
    # in the repository (scratch only)" (review round 2, finding 5).
    printf '### T1 — do it\n\n**Files touched:** none in the repository (scratch only).\n\n```sh\n./fakeawk BEGIN\n```\n' > "$PLAN"
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    grep -qxF '*(Code pruned at merge: 1 line. Files touched: none in the repository (scratch only).)*' "$PLAN" ||
        { cat "$PLAN"; false; }
}

@test "prune: a citation inside a fence this run prunes does not leave its plan whole" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # The citing line is gone after the run, so it cites nothing; counting it
    # left b whole on run 1 and pruned it on run 2 (review round 2,
    # finding 2). A second run prints nothing.
    printf '### T1 — b\n\n```sh\necho b-one\necho b-two\n```\n' > docs/plans/2026-01-01-b.md
    printf '### T1 — a\n\n```sh\n# see 2026-01-01-b.md:4\necho a-code\n```\n' > docs/plans/2026-01-02-a.md
    commit_all plans
    prune --all
    [ "$status" -eq 0 ]
    output_has "pruned docs/plans/2026-01-01-b.md: 1 block, 2 lines"
    output_has "pruned docs/plans/2026-01-02-a.md: 1 block, 2 lines"
    output_lacks "left whole"
    commit_all pruned
    prune --all
    [ "$status" -eq 0 ]
    [ -z "$output" ] || { echo "$output"; false; }
}

@test "prune: a citation inside the fence of a plan left whole counts" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # a is cited after its fence, so it stays whole, and the citation in its
    # fence stays where it is: b is left whole too. A second run repeats the
    # left whole lines and prunes nothing.
    printf '### T1 — b\n\n```sh\necho b-one\necho b-two\n```\n' > docs/plans/2026-01-01-b.md
    printf '### T1 — a\n\n```sh\n# see 2026-01-01-b.md:4\necho a-code\n```\n' > docs/plans/2026-01-02-a.md
    mkdir -p docs/verification
    printf 'See 2026-01-02-a.md:5.\n' > docs/verification/2026-01-02-rec.md
    commit_all plans
    prune --all
    [ "$status" -eq 0 ]
    output_has "left whole docs/plans/2026-01-02-a.md: cited at docs/verification/2026-01-02-rec.md:1 as 2026-01-02-a.md:5"
    output_has "left whole docs/plans/2026-01-01-b.md: cited at docs/plans/2026-01-02-a.md:4 as 2026-01-01-b.md:4"
    output_lacks "pruned docs/plans/2026-01-0"
    grep -q 'b-one' docs/plans/2026-01-01-b.md
    first_output=$(printf '%s\n' "$output" | grep -v 2025-12-01-old)
    commit_all pruned
    prune --all
    [ "$status" -eq 0 ]
    [ "$output" = "$first_output" ] || { echo "$output"; false; }
}

@test "prune: a citation of the first pruned fence's opening line leaves the plan whole" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # The opening line itself is replaced by the pointer (review round 2,
    # finding 4).
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    mkdir -p docs/verification
    printf 'See 2026-01-01-x.md:3.\n' > docs/verification/2026-01-01-rec.md
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "left whole $PLAN: cited at docs/verification/2026-01-01-rec.md:1 as 2026-01-01-x.md:3"
}

@test "prune: a citation between two pruned fences leaves the plan whole" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # The floor is the first pruned fence, not the last: line 7 moves when
    # the fence at line 3 is pruned (review round 2, finding 4).
    printf '### T1 — do it\n\n```sh\necho one\n```\n\nBetween.\n\n```sh\necho two\n```\n' > "$PLAN"
    mkdir -p docs/verification
    printf 'See 2026-01-01-x.md:7.\n' > docs/verification/2026-01-01-rec.md
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "left whole $PLAN: cited at docs/verification/2026-01-01-rec.md:1 as 2026-01-01-x.md:7"
}

@test "prune: a tracked file that is not Markdown does not cite a plan" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    printf 'See 2026-01-01-x.md:4.\n' > notes.txt
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN"
    output_lacks "left whole"
}

@test "prune: a plan cited twice prints one left whole line, naming the first citation" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    mkdir -p docs/verification
    printf 'See 2026-01-01-x.md:4.\n' > docs/verification/2026-01-01-a.md
    printf 'See 2026-01-01-x.md:5.\n' > docs/verification/2026-01-01-b.md
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    [ "$output" = "left whole $PLAN: cited at docs/verification/2026-01-01-a.md:1 as 2026-01-01-x.md:4" ] ||
        { echo "$output"; false; }
}

@test "prune: a plan in a subdirectory of docs/plans is not taken" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    mkdir -p docs/plans/archive
    printf '### T1 — do it\n\n```sh\necho nested-code\n```\n' > docs/plans/archive/2026-01-01-y.md
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    [ -z "$output" ] || { echo "$output"; false; }
    grep -q 'nested-code' docs/plans/archive/2026-01-01-y.md
}

@test "prune: a Files touched value ends at a heading on the next line" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '### T1 — do it\n\n**Files touched:** `src/a.sh`\n#### Steps\n\n```sh\necho one\n```\n' > "$PLAN"
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    grep -qxF '*(Code pruned at merge: 1 line. Files touched: `src/a.sh`.)*' "$PLAN" ||
        { cat "$PLAN"; false; }
}

@test "prune: a Files touched value ends at a fence on the next line" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '### T1 — do it\n\n**Files touched:** `src/a.sh`\n```sh\necho one\n```\n' > "$PLAN"
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    grep -qxF '*(Code pruned at merge: 1 line. Files touched: `src/a.sh`.)*' "$PLAN" ||
        { cat "$PLAN"; false; }
}

@test "prune: a Files touched value's trailing period is not doubled" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '### T1 — do it\n\n**Files touched:** `src/a.sh`.\n\n```sh\necho one\n```\n' > "$PLAN"
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    grep -qxF '*(Code pruned at merge: 1 line. Files touched: `src/a.sh`.)*' "$PLAN" ||
        { cat "$PLAN"; false; }
}

@test "prune: the **Files touched**: label form is read" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '### T1 — do it\n\n**Files touched**: `src/a.sh`\n\n```sh\necho one\n```\n' > "$PLAN"
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    grep -qxF '*(Code pruned at merge: 1 line. Files touched: `src/a.sh`.)*' "$PLAN" ||
        { cat "$PLAN"; false; }
}

@test "prune: an indented red -> green line keeps its fence" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '### T1 — do it\n\n```text\n   red -> green: t1 (expected 1, got 0)\n```\n' > "$PLAN"
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    [ -z "$output" ] || { echo "$output"; false; }
    grep -q 'red -> green: t1' "$PLAN"
}

@test "prune: seven hashes, or a hash with no space after it, is not a heading" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # `####### T1` opens no task section, so its fence is kept; `#Notes`
    # does not end the T1 section, so the fence after it is pruned.
    printf '####### T1 — seven\n\n```sh\necho seven-kept\n```\n\n### T1 — do it\n\n```sh\necho one\n```\n#Notes\n\n```sh\necho two\n```\n' > "$PLAN"
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN: 2 blocks, 2 lines"
    grep -q 'seven-kept' "$PLAN"
    ! grep -q 'echo two' "$PLAN" || { cat "$PLAN"; false; }
}

@test "prune: a line opening with double-backtick inline code is not a fence" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # A fence opens at three markers or more; two would open one at the
    # ``x`` line and prune the prose up to the next ``` line (review round 3,
    # finding 2).
    printf '### T1 — do it\n\n``x`` is inline code.\n\nProse kept.\n\n```sh\necho one\n```\n' > "$PLAN"
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN: 1 block, 1 line"
    grep -qxF '``x`` is inline code.' "$PLAN" || { cat "$PLAN"; false; }
    grep -qxF 'Prose kept.' "$PLAN" || { cat "$PLAN"; false; }
}

@test "prune: an empty prune_plans value exits 2" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # A key that is present but empty is not absent, so it is not `on`
    # (review round 3, finding 3).
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    printf 'prune_plans:\n' >> .guardrails/config.yaml
    commit_all plan
    prune
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    output_has "prune_plans"
    grep -q 'branch-code' "$PLAN"
}

@test "prune: a Files touched value ends at an indented bold label" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # The label may follow optional indentation (review round 3, finding 3).
    printf '### T1 — do it\n\n**Files touched:** `src/a.sh`\n  **Parallel:** no\n\n```sh\necho one\n```\n' > "$PLAN"
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    grep -qxF '*(Code pruned at merge: 1 line. Files touched: `src/a.sh`.)*' "$PLAN" ||
        { cat "$PLAN"; false; }
}

@test "prune: a citation under a directory that only ends in plans does not stop the prune" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # myplans/ and old-plans/ are other directories, not plans/ (review
    # round 3, finding 3).
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    mkdir -p docs/verification
    printf 'See docs/myplans/2026-01-01-x.md:4.\nSee old-plans/2026-01-01-x.md:4.\n' \
        > docs/verification/2026-01-01-rec.md
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN"
    output_lacks "left whole"
}

@test "prune: a range citation that ends at or after the first pruned fence leaves the plan whole" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # The range starts before the fence, but its end line moves (review
    # round 3, finding 4).
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    mkdir -p docs/verification
    printf 'See 2026-01-01-x.md:1-4.\n' > docs/verification/2026-01-01-rec.md
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "left whole $PLAN: cited at docs/verification/2026-01-01-rec.md:1 as 2026-01-01-x.md:1-4"
    grep -q 'branch-code' "$PLAN"
}

@test "prune: a range citation that ends before the first pruned fence does not stop the prune" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    printf '### T1 — do it\n\n```sh\necho branch-code\n```\n' > "$PLAN"
    mkdir -p docs/verification
    printf 'See 2026-01-01-x.md:1-2.\n' > docs/verification/2026-01-01-rec.md
    commit_all plan
    prune
    [ "$status" -eq 0 ]
    output_has "pruned $PLAN"
    output_lacks "left whole"
}
