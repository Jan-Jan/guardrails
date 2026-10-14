# Content lints over skills/develop-tdd/SKILL.md: the TDD loop a dispatched
# task subagent runs for one plan task (docs/plans/2026-10-13-code-guidelines.md,
# D1). The section shape and word count are covered by the
# skill-shape tests in skills.bats.

load helpers

setup() {
    root="$BATS_TEST_DIRNAME/.."
    skill="$root/skills/develop-tdd/SKILL.md"
}

@test "develop-tdd: the skill is named, and only a dispatched task subagent loads it" {
    # verifies: D1 (docs/plans/2026-10-13-code-guidelines.md)
    grep -qxF 'name: develop-tdd' "$skill"
    preconditions=$(section_of '## Preconditions' "$skill" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$preconditions" | grep -qF 'You were dispatched by `develop-change` with one plan task'
    printf '%s\n' "$preconditions" | grep -qF 'Do not merge it, and do not dispatch again.'
}

@test "develop-tdd: a TEST conformance finding is fixed under the loop, or reported not fixed" {
    # verifies: D1, D4 (docs/plans/2026-10-13-code-guidelines.md)
    preconditions=$(section_of '## Preconditions' "$skill" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$preconditions" | grep -qF 'or with the findings of a `TEST` conformance review to fix'
    printf '%s\n' "$preconditions" | grep -qF 'each finding is fixed under the loop below, citing the clause it names, or reported as not fixed with the reason'
    grep -qF '| "This finding is wrong; I'"'"'ll skip it quietly" |' "$skill"
}

@test "develop-tdd: no production code without a failing test first" {
    # verifies: D1 (docs/plans/2026-10-13-code-guidelines.md)
    grep -qF '**No production code without a failing test first.**' "$skill"
}

@test "develop-tdd: the loop runs RED, then GREEN, and its sixth step commits" {
    # verifies: D1 (docs/plans/2026-10-13-code-guidelines.md)
    # worktree-discipline cites "develop-tdd step 6" for the commit on the
    # task branch, so the numbering is pinned.
    loop=$(section_of '### The loop, one behavior at a time' "$skill")
    [ -n "$loop" ] || { echo "no loop section"; false; }
    printf '%s\n' "$loop" | grep -q '^1\. \*\*RED:\*\*'
    printf '%s\n' "$loop" | grep -q '^2\. \*\*Verify RED:\*\*'
    printf '%s\n' "$loop" | grep -q '^3\. \*\*GREEN:\*\*'
    printf '%s\n' "$loop" | grep -q '^6\. \*\*Commit\*\*'
}

@test "develop-tdd: the class rules and the bug rule" {
    # verifies: D1 (docs/plans/2026-10-13-code-guidelines.md)
    grep -qF '**B and C, the robustness rule:**' "$skill"
    grep -qF 'every SDD item the change touches gets tests at its own interface' "$skill"
    grep -qF 'A bug is a missing test.' "$skill"
}

@test "develop-tdd: every test fails when the behavior it verifies breaks" {
    # verifies: D1 (docs/plans/2026-10-13-code-guidelines.md); D2 (docs/plans/2026-10-08-test-guidelines.md)
    grep -qxF '**Every test fails when the behavior it `verifies:` breaks.**' "$skill"
    grep -qF 'An assertion only that a double was called meets this only where the' "$skill"
    grep -qxF 'call is the requirement.' "$skill"
}

@test "develop-tdd: before RED, guidelines-file.sh picks the one test guidelines file" {
    # verifies: D1 (docs/plans/2026-10-13-code-guidelines.md); D2, D6, D8 (docs/plans/2026-10-08-test-guidelines.md)
    grep -qF 'sh .guardrails/scripts/guidelines-file.sh TEST <the paths the task touches>' "$skill"
    section=$(section_of '### Test guidelines' "$skill" | tr '\n' ' ' | tr -s ' ')
    [ -n "$section" ] || { echo "no Test guidelines section"; false; }
    printf '%s\n' "$section" | grep -qF 'read no other guidelines file'
    printf '%s\n' "$section" | grep -qF 'If it exits 2 or is missing, stop and reinstall the guardrails scripts and templates (`ratchet`'"'"'s upgrade); never proceed without a guidelines file.'
    printf '%s\n' "$section" | grep -qF 'is a finding against the clause'
}

@test "develop-tdd: the dispatch report's shape, and an inherited test is coverage" {
    # verifies: D1 (docs/plans/2026-10-13-code-guidelines.md); D6 (docs/plans/2026-10-08-out-of-force-items.md)
    report=$(section_of '### The dispatch report' "$skill")
    [ -n "$report" ] || { echo "no dispatch report section"; false; }
    for line in 'task: <ID>' 'worktree: <path to the task worktree>' 'files touched: <paths>' \
        'inherited: <test name> — from <old ID>' 'result: <N passed, N failed>' \
        'fixed: <finding-N — what changed, or "not fixed — <reason>">   (a fix' \
        'surprises: <anything unexpected, or "none">'; do
        printf '%s\n' "$report" | grep -qxF -- "$line" || { echo "the shape lacks: $line"; false; }
    done
    printf '%s\n' "$report" | tr '\n' ' ' | tr -s ' ' | grep -qF 'It is coverage, not red-first evidence'
}

@test "develop-tdd: carries no repository-only mutation-anchor rule" {
    # verifies: D1 (docs/plans/2026-10-13-code-guidelines.md); D10 (docs/plans/2026-10-08-test-guidelines.md)
    [ -f "$skill" ] || { echo "no develop-tdd SKILL.md"; false; }
    if grep -q 'mutations' "$skill"; then
        echo "develop-tdd states the repository-only anchor rule"
        false
    fi
}

@test "develop-tdd: the subagent's red flags" {
    # verifies: D1 (docs/plans/2026-10-13-code-guidelines.md)
    grep -qF '| "I'"'"'ll keep the code I wrote as reference while I write the test" |' "$skill"
    grep -qF '| "The test passed on its first run, good" |' "$skill"
    grep -qF '| "I'"'"'ll merge my task branch when I am done" |' "$skill"
}

@test "develop-tdd: the skills that cite the TDD rules cite develop-tdd, and the README shows the split" {
    # verifies: D1, D4, D6 (docs/plans/2026-10-13-code-guidelines.md)
    # develop-tdd holds the loop, the annotation rule and the red-first rule,
    # so a citation of them names it; a citation of the dispatcher names
    # develop-change.
    grep -qF '(unsigned, `develop-tdd` step 6)' "$root/skills/worktree-discipline/SKILL.md"
    grep -qF 'per `develop-tdd`' "$root/skills/resolve-problem/SKILL.md"
    grep -qF 'written red-first (`develop-tdd`)' "$root/skills/grill-requirements/SKILL.md"
    grep -qF 'TDD[develop-tdd<br/>' "$root/README.md"
    grep -qF 'RC[review-conformance<br/>' "$root/README.md"
    grep -qF 'RF[develop-refactor<br/>' "$root/README.md"
}
