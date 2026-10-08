# Content lints over skills/review-guidelines/SKILL.md: the reviewer that
# checks a change diff against one guidelines file. The section shape and word
# count are covered by the skill-shape tests in skills.bats.

setup() {
    skill="$BATS_TEST_DIRNAME/../skills/review-guidelines/SKILL.md"
}

@test "review-guidelines: the frontmatter names the skill" {
    # verifies: D4 (docs/plans/2026-10-08-test-guidelines.md)
    grep -qxF 'name: review-guidelines' "$skill"
}

@test "review-guidelines: a finding cites a clause, a severity and a location" {
    # verifies: D4 (docs/plans/2026-10-08-test-guidelines.md)
    # The line sits indented inside a list item; it is pinned whole once the
    # indent is stripped.
    sed 's/^ *//' "$skill" | grep -qxF '**finding-N**: guideline, <low | medium | high> — <clause cited as Heading N, quoted> — <file:line>'
}

@test "review-guidelines: the floor is listed in full" {
    # verifies: D2, D4 (docs/plans/2026-10-08-test-guidelines.md)
    grep -qF 'every test carries `verifies:`' "$skill"
    grep -qF 'every new test was watched red' "$skill"
    grep -qF 'every test fails when the behavior it `verifies:` breaks' "$skill"
    grep -qF 'class B and C: abnormal-input tests for every REQ and LLR' "$skill"
    grep -qF "class C: tests at every touched SDD item's interface" "$skill"
}

@test "review-guidelines: a clause that contradicts the floor is a finding against the clause" {
    # verifies: D2, D4 (docs/plans/2026-10-08-test-guidelines.md)
    grep -qF 'Report a clause that contradicts the floor as a finding against the clause' "$skill"
}

@test "review-guidelines: a stale reason or a reference out of the file is a finding against the clause" {
    # verifies: D5, D6 (docs/plans/2026-10-08-test-guidelines.md)
    grep -qF 'a clause whose reason no longer fits its rule' "$skill"
    grep -qF 'a clause that refers to another guidelines file or to a document the project does not contain' "$skill"
}

@test "review-guidelines: what the file does not state is a note, never a finding" {
    # verifies: D4 (docs/plans/2026-10-08-test-guidelines.md)
    grep -qF 'What the file does not state is a `note:`, never a finding' "$skill"
}

@test "review-guidelines: the report ends with a verdict line" {
    # verifies: D4 (docs/plans/2026-10-08-test-guidelines.md)
    grep -qF 'End with `verdict: <one line>`' "$skill"
}

@test "review-guidelines: the three red flags are present" {
    # verifies: D4, D6 (docs/plans/2026-10-08-test-guidelines.md)
    grep -qF "| \"This is bad but the file doesn't say so\" |" "$skill"
    grep -qF '| "The clause seems wrong here, I'"'"'ll let it go" |' "$skill"
    grep -qF '| "I'"'"'ll read the installed default for context" |' "$skill"
}
