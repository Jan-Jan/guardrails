# Text lints over the tailor-guidelines skill and the ratchet lines that
# install and invoke it (docs/plans/2026-10-08-test-guidelines.md, T5).
# Each test pins an operative clause, not the prose around it.

setup() {
    root="$BATS_TEST_DIRNAME/.."
    tailor="$root/skills/tailor-guidelines/SKILL.md"
    ratchet="$root/skills/ratchet/SKILL.md"
    notes="$root/skills/ratchet/references/upgrade-notes.md"
}

# Prints the lines of $2 under the heading line $1 up to the next heading of
# the same or a higher level.
section_of() {
    awk -v heading="$1" '
        $0 == heading { inside = 1; level = index($0, " "); next }
        inside && /^#+ / && index($0, " ") <= level { inside = 0 }
        inside
    ' "$2"
}

@test "tailor-guidelines: the skill is named, and seeds a complete copy that names no source" {
    # verifies: D6, D7 (docs/plans/2026-10-08-test-guidelines.md)
    grep -qxF 'name: tailor-guidelines' "$tailor"
    grep -qF 'Absent, seed it as a complete copy' "$tailor"
    grep -qF 'of the root file for a unit that has one, otherwise of the installed' "$tailor"
    grep -qF 'Never write a reference to the source in the copy.' "$tailor"
}

@test "tailor-guidelines: a unit's file is its own, at the unit's path" {
    # verifies: D3, D7 (docs/plans/2026-10-08-test-guidelines.md)
    grep -qF '`<unit>/docs/<KIND>_GUIDELINES.md`' "$tailor"
    grep -qF 'replaces the root file entirely for that unit' "$tailor"
}

@test "tailor-guidelines: the interview walks one clause per message, with its reason" {
    # verifies: D7 (docs/plans/2026-10-08-test-guidelines.md)
    grep -qF 'Walk the clauses one per message' "$tailor"
    grep -qF 'keep, change or drop' "$tailor"
    grep -qF 'ask for an example in the project' "$tailor"
    grep -qF 'Drop `## UI` where the project has no user interface' "$tailor"
}

@test "tailor-guidelines: a change that contradicts the floor is rejected, and the floor is listed" {
    # verifies: D7 (docs/plans/2026-10-08-test-guidelines.md)
    grep -qF 'Reject a change that contradicts the floor' "$tailor"
    grep -qF 'every test carries `verifies:`' "$tailor"
    grep -qF 'every new test was watched red' "$tailor"
    grep -qF 'every test fails when the behavior it `verifies:` breaks' "$tailor"
    grep -qF 'class B and C: abnormal-input tests for every REQ and LLR' "$tailor"
    grep -qF "class C: tests at every touched SDD item's interface" "$tailor"
}

@test "tailor-guidelines: upgrade mode walks the template diff and never overwrites" {
    # verifies: D7, D11 (docs/plans/2026-10-08-test-guidelines.md)
    upgrade=$(section_of '### Upgrade mode' "$tailor")
    [ -n "$upgrade" ] || { echo "no Upgrade mode section"; false; }
    printf '%s\n' "$upgrade" | grep -qF 'adopt into the project file, adapt, or decline'
    printf '%s\n' "$upgrade" | grep -qF 'Never overwrite the project file.'
    grep -qF '| "The new default is better, I'"'"'ll replace the file" |' "$tailor"
}

@test "ratchet: the scaffold installs the test guidelines default and tailors it" {
    # verifies: D6, D7 (docs/plans/2026-10-08-test-guidelines.md)
    scaffold=$(section_of '### Step 2 (greenfield): Scaffold' "$ratchet")
    printf '%s\n' "$scaffold" | grep -qF '`templates/TEST_GUIDELINES.md` → `.guardrails/templates/TEST_GUIDELINES.md`'
    printf '%s\n' "$scaffold" | grep -qF 'Run `tailor-guidelines` for `TEST`'
}

@test "ratchet: an upgrade runs tailor-guidelines' upgrade mode before the template is re-copied" {
    # verifies: D7, D11 (docs/plans/2026-10-08-test-guidelines.md)
    upgrade=$(section_of '### Upgrading the scripts in an existing project' "$ratchet")
    printf '%s\n' "$upgrade" | grep -qF 'run `tailor-guidelines` in upgrade mode for each'
    printf '%s\n' "$upgrade" | grep -qF '`templates/*_GUIDELINES.md` → `.guardrails/templates/`'
}

@test "ratchet: a retrofit tailors each guidelines file as a later tooth" {
    # verifies: D7 (docs/plans/2026-10-08-test-guidelines.md)
    # The first tooth installs the default and migrates nothing; tailoring is
    # an interview of its own, so it is listed with the later teeth
    # (finding-6a, review round 1).
    retrofit=$(section_of '### Step 3 (retrofit): Gap analysis first, then tighten' "$ratchet")
    [ -n "$retrofit" ] || { echo "no retrofit section"; false; }
    later=$(printf '%s\n' "$retrofit" | awk '/^4\. \*\*Later teeth\*\*/ { inside = 1 } /^5\. / { inside = 0 } inside' | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$later" | grep -qF 'run `tailor-guidelines` for each guidelines file'
}

@test "ratchet: the T5 tightening kept the bats and multi-unit sentences" {
    # verifies: D7 (docs/plans/2026-10-08-test-guidelines.md)
    # Both were deleted to make room for the tailor-guidelines words; each is
    # a rule, not prose (finding-6b, review round 1).
    grep -qF 'Never add bats to the target project.' "$ratchet"
    retrofit=$(section_of '### Step 3 (retrofit): Gap analysis first, then tighten' "$ratchet")
    first=$(printf '%s\n' "$retrofit" | awk '/^3\. \*\*First tooth\*\*/ { inside = 1 } /^4\. / { inside = 0 } inside' | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$first" | grep -qF 'On a multi-unit repository, read `references/multi-unit.md` first.'
}

@test "upgrade notes: an upgraded project without its own file follows the installed default" {
    # verifies: D11 (docs/plans/2026-10-08-test-guidelines.md)
    section=$(section_of '## Test guidelines are a project file' "$notes")
    [ -n "$section" ] || { echo "no Test guidelines section"; false; }
    printf '%s\n' "$section" | tr '\n' ' ' | tr -s ' ' \
        | grep -qF 'with no `docs/TEST_GUIDELINES.md` follows the installed default, which states the rules `develop-change` stated before'
    printf '%s\n' "$section" | grep -qF 'tailor-guidelines'
}
