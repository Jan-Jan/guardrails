# Content lints over skills/develop-refactor/SKILL.md: the fixer of one CODE
# or ARCHITECTURE conformance review's findings
# (docs/plans/2026-10-13-code-guidelines.md, D1 and D4;
# docs/plans/2026-10-14-architecture-guidelines.md, D3 and D6). The section
# shape and word count are covered by the skill-shape tests in skills.bats.

load helpers

setup() {
    skill="$BATS_TEST_DIRNAME/../skills/develop-refactor/SKILL.md"
}

@test "develop-refactor: the skill is named, and fixes one CODE or ARCHITECTURE review's findings" {
    # verifies: D1, D4 (docs/plans/2026-10-13-code-guidelines.md); D3 (docs/plans/2026-10-14-architecture-guidelines.md)
    grep -qxF 'name: develop-refactor' "$skill"
    grep -E '^description:' "$skill" | grep -qF 'Load it only when develop-change dispatched you to fix CODE or ARCHITECTURE findings.'
    preconditions=$(section_of '## Preconditions' "$skill" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$preconditions" | grep -qF 'with the findings of one `review-conformance` review against a code or architecture guidelines file'
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
    printf '%s\n' "$flat" | grep -qF 'Do not change behavior: the tests you run must stay green.'
    printf '%s\n' "$flat" | grep -qF 'Never delete, skip or loosen a test to keep those tests green.'
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

@test "develop-refactor: a finding that needs a design change comes back not fixed" {
    # verifies: D3 (docs/plans/2026-10-14-architecture-guidelines.md)
    flat=$(tr '\n' ' ' < "$skill" | tr -s ' ')
    printf '%s\n' "$flat" | grep -qF 'a finding that needs an SDD or LLR item changed, or a different structure: you do not edit design items'
    grep -qF '| "The finding needs a design item reworded; I'"'"'ll edit it" |' "$skill"
}

@test "develop-refactor: the floor names the architecture items" {
    # verifies: D3, D6 (docs/plans/2026-10-14-architecture-guidelines.md)
    states_architecture_floor "$skill"
}

@test "develop-refactor: a fix runs the tests that verify what it changes" {
    # verifies: D3 (docs/plans/2026-10-15-test-selection-guideline.md)
    notes="$BATS_TEST_DIRNAME/../skills/ratchet/references/upgrade-notes.md"
    step=$(step_of "$skill" 3 | tr '\n' ' ' | tr -s ' ')
    printf '%s' "$step" | grep -qF 'tests the fix touches: those that verify what it changes' ||
        { echo "step 3 does not scope the run"; false; }
    printf '%s' "$step" | grep -qF 'cannot select' ||
        { echo "step 3 has no fallback for a runner that cannot select"; false; }
    if printf '%s' "$step" | grep -qF 'verify_commands` after each fix'; then
        echo "step 3 still runs the whole suite per fix"; false
    fi
    grep -qF '## Test runs' "$notes" ||
        { echo "no upgrade note names the Test runs section"; false; }
    done_when=$(section_of '## Done when' "$skill" | tr '\n' ' ' | tr -s ' ')
    if printf '%s' "$done_when" | grep -qF 'The suite is green'; then
        echo "Done when still implies the whole suite"; false
    fi
    printf '%s' "$done_when" | grep -qF 'Those tests are green' ||
        { echo "Done when does not state the run tests are green"; false; }
}
