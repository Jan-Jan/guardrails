# Content lints over skills/develop-refactor/SKILL.md: the fixer of one CODE
# conformance review's findings (docs/plans/2026-10-13-code-guidelines.md,
# D1 and D4). The section shape and word count are covered by the
# skill-shape tests in skills.bats.

load helpers

setup() {
    skill="$BATS_TEST_DIRNAME/../skills/develop-refactor/SKILL.md"
}

@test "develop-refactor: the skill is named, and fixes one CODE review's findings" {
    # verifies: D1, D4 (docs/plans/2026-10-13-code-guidelines.md)
    grep -qxF 'name: develop-refactor' "$skill"
    preconditions=$(section_of '## Preconditions' "$skill" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$preconditions" | grep -qF 'with the findings of one `review-conformance` review against a code guidelines file'
    printf '%s\n' "$preconditions" | grep -qF 'you do not review your own fix: the next review round does'
}

@test "develop-refactor: it works in its nested task worktree and does not merge" {
    # verifies: D4 (docs/plans/2026-10-13-code-guidelines.md)
    preconditions=$(section_of '## Preconditions' "$skill" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$preconditions" | grep -qF 'Create the task worktree as the prompt says'
    printf '%s\n' "$preconditions" | grep -qF 'Do not merge it, and do not dispatch again.'
}

@test "develop-refactor: it reads the one code guidelines file and fixes what the findings state" {
    # verifies: D1, D4 (docs/plans/2026-10-13-code-guidelines.md); D6 (docs/plans/2026-10-08-test-guidelines.md)
    flat=$(tr '\n' ' ' < "$skill" | tr -s ' ')
    printf '%s\n' "$flat" | grep -qF 'Read the one file the prompt names and no other guidelines file.'
    printf '%s\n' "$flat" | grep -qF 'Fix each finding at its line, as its clause states.'
    grep -qF '| "While I'"'"'m here, I'"'"'ll tidy the rest of the file" |' "$skill"
}

@test "develop-refactor: no behavior change, and no test loosened" {
    # verifies: D1 (docs/plans/2026-10-13-code-guidelines.md)
    flat=$(tr '\n' ' ' < "$skill" | tr -s ' ')
    printf '%s\n' "$flat" | grep -qF 'Do not change behavior: the suite must stay green.'
    printf '%s\n' "$flat" | grep -qF 'Never delete, skip or loosen a test to keep the suite green.'
}

@test "develop-refactor: a finding it cannot fix is reported, with the reason" {
    # verifies: D4 (docs/plans/2026-10-13-code-guidelines.md)
    flat=$(tr '\n' ' ' < "$skill" | tr -s ' ')
    printf '%s\n' "$flat" | grep -qF 'Report a finding you cannot fix as not fixed, with the reason:'
    printf '%s\n' "$flat" | grep -qF 'is a finding against the clause'
}

@test "develop-refactor: the report's shape" {
    # verifies: D4 (docs/plans/2026-10-13-code-guidelines.md)
    report=$(section_of '### The report' "$skill")
    [ -n "$report" ] || { echo "no report section"; false; }
    for line in 'task: <tag>' 'worktree: <path to the task worktree>' 'files touched: <paths>' \
        'fixed: <finding-N — what changed, or "not fixed — <reason>">   (one per line)' \
        'result: <N passed, N failed>'; do
        printf '%s\n' "$report" | grep -qxF -- "$line" || { echo "the shape lacks: $line"; false; }
    done
}
