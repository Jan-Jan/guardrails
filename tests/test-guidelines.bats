# Content checks over the shipped test guidelines, templates/TEST_GUIDELINES.md:
# the project file an agent reads in place of the seam rules develop-change
# once carried. The pins in the first five tests carried over from the
# test-seams tests in tests/skills.bats, repointed here (T2 of
# docs/plans/2026-10-08-test-guidelines.md).

load helpers

template="$BATS_TEST_DIRNAME/../templates/TEST_GUIDELINES.md"

@test "test guidelines: a test attaches only to an interface a REQ or LLR describes" {
    # verifies: D5 (docs/plans/2026-10-08-test-guidelines.md); D1, D2, D3 (docs/plans/2026-10-07-test-seams.md)
    grep -qF '**A test calls only an interface that a REQ or LLR describes.**' "$template"
    grep -qF '**A deeper interface gets a direct test only once it has an LLR**' "$template"
    grep -qF 'A journey is a REQ of its own only when it states an' "$template"
    grep -qF '1. **Unreachable.**' "$template"
    grep -qF '2. **Combinatorial.**' "$template"
    grep -qF '3. **Intrinsic.**' "$template"
    grep -qF 'Convenience is not on the list.' "$template"
    grep -qxF '   helper is covered through the interface above it. Without LLRs, the seam is' "$template"
    grep -qxF '   1. **Unreachable.** A case cannot be triggered through the REQ interface' "$template"
    grep -qxF '      without faking code the project owns. A retry policy whose third attempt' "$template"
    grep -qxF '      multiplies past what is practical to enumerate. As guidance, not a rule:' "$template"
    grep -qxF '   3. **Intrinsic.** Maths, parsing, encoding or a numerical transform whose' "$template"
    grep -qxF '      algorithm has a contract worth stating independently of its caller.' "$template"
}

@test "test guidelines: doubles fake only at the codebase boundary, each with a contract test" {
    # verifies: D5 (docs/plans/2026-10-08-test-guidelines.md); D4, D8, D9, D14 (docs/plans/2026-10-07-test-seams.md)
    grep -qF 'A service the project owns runs for real' "$template"
    grep -qF 'its failures may be injected or faked.' "$template"
    grep -qF '4. **An interaction is asserted only where it is the requirement.**' "$template"
    grep -qF '3. **Every fake has a contract test.**' "$template"
    grep -qF 'The faked successes are then setup, not evidence.' "$template"
    grep -qF -- '- **A fake**, with a contract test: a double that imitates service-specific' "$template"
    grep -qF -- '- **A fault injector**, with none: a transport- or OS-level failure, such as' "$template"
    grep -qxF '   reachable in the test environment, and are skipped where it is not. A fake' "$template"
    grep -qxF '   first sync that succeeds before the second times out, where each of those' "$template"
    grep -qxF '   successes is verified against the real service by a normal-case test in the' "$template"
    grep -qxF '   - a fake of the service, under the same contract test as any fake, so that' "$template"
    grep -qxF '   implements the adapter'"'"'s interface. A fake at the HTTP layer, intercepting' "$template"
    grep -qxF '   the network calls to a service outside the codebase, is a boundary fake' "$template"
    grep -qxF '   too, under the same contract test; the adapter above it then runs for' "$template"
    grep -qxF '   real. The clock and randomness are fakeable in the same way.' "$template"
    grep -qxF '   the adapter, never the third-party interface directly, and the fake' "$template"
    grep -qxF '   fake and against the real dependency, wherever the real dependency is' "$template"
}

@test "test guidelines: property tests repeat and pin, and a survivor never goes below the seam" {
    # verifies: D5 (docs/plans/2026-10-08-test-guidelines.md); D5, D6 (docs/plans/2026-10-07-test-seams.md)
    grep -qF 'encoding (criteria 2 and 3 above), prefer a property test: generated inputs,' "$template"
    grep -qF 'seam, or dead code: never a test below the seam.' "$template"
    grep -qF '2. **Repeatable.**' "$template"
    grep -qF '3. **Pinned.**' "$template"
    grep -qF 'A survivor never justifies a test below the seam' "$template"
    grep -qxF '   - the mutated code is dead: delete it.' "$template"
    grep -qxF '   beside it, with its `verifies:` annotation, before the fix. It then stays' "$template"
    grep -qxF '   A survivor never justifies a test below the seam unless one of the three' "$template"
    grep -qxF '   criteria above holds. Whether a project must run mutation testing, with which' "$template"
    grep -qF 'command and to what score, is decided in this section' "$template"
}

@test "test guidelines: a UI's interface is what the user perceives, and a markup snapshot verifies nothing" {
    # verifies: D5 (docs/plans/2026-10-08-test-guidelines.md); D7 (docs/plans/2026-10-07-test-seams.md)
    grep -qF 'A markup snapshot carries no `verifies:` annotation.' "$template"
    grep -qF 'The REQ interface of a UI is what the user perceives and does' "$template"
    grep -qF '. **A markup snapshot carries no `verifies:` annotation.**' "$template"
    grep -qF '. **Keep the UI layer thin.**' "$template"
    grep -qF 'text, not by test identifier or class name.' "$template"
    grep -qF 'Visual regression verifies a REQ only where the REQ is about appearance' "$template"
    grep -qF 'A service the project owns runs for real on the normal path' "$template"
    grep -qxF '     A service the project owns runs for real on the normal path' "$template"
    grep -qxF '   - Fake only what is outside the codebase, plus the clock and randomness. A' "$template"
    grep -qxF '     fake at the HTTP layer, by network interception, is a boundary fake under' "$template"
    grep -qxF '     the same contract test as any fake.' "$template"
    grep -qF '. **Enumerate the states.**' "$template"
    grep -qxF '   List the states each screen can be in and test each: loading, empty, error,' "$template"
    grep -qF '. **What only a real browser shows.**' "$template"
    grep -qxF '   Keep a small suite in a real browser for what a simulated DOM cannot do: the' "$template"
    grep -qxF '   application sends to the outside world. Components, props, hooks, store shape' "$template"
    grep -qxF '   and CSS classes are implementation: a test that names them breaks on a' "$template"
}

@test "test guidelines: the rules bind new and edited tests, not the existing suite" {
    # verifies: D5 (docs/plans/2026-10-08-test-guidelines.md); D10 (docs/plans/2026-10-07-test-seams.md)
    grep -qF 'These rules bind the tests a change writes or edits.' "$template"
    grep -qF 'No change rewrites a suite wholesale' "$template"
    grep -qxF '   moves it to the seam instead of repairing it in place: such a test usually' "$template"
    grep -qxF '   breaks the rules and still passes is left alone, since deleting it without a' "$template"
}

@test "test guidelines: the template has the seven headings, in order" {
    # verifies: D5 (docs/plans/2026-10-08-test-guidelines.md)
    expected='# Test guidelines
## Seams
## Doubles
## Owned services
## Property tests
## Mutants
## UI
## Existing suites'
    run grep -E '^##? ' "$template"
    [ "$status" -eq 0 ]
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

@test "test guidelines: the preface states the one-file rule and the floor rule" {
    # verifies: D2, D6 (docs/plans/2026-10-08-test-guidelines.md)
    preface=$(awk '/^## /{exit} {print}' "$template")
    printf '%s\n' "$preface" | grep -qF 'and no other guidelines file'
    printf '%s\n' "$preface" | grep -qF 'is a finding against the clause'
    preface_lines=$(printf '%s\n' "$preface" | grep -cv -e '^#' -e '^$')
    [ "$preface_lines" -le 5 ] || { echo "preface is $preface_lines lines"; false; }
}

@test "test guidelines: the template stands alone, naming no guardrails document or skill" {
    # verifies: D6 (docs/plans/2026-10-08-test-guidelines.md)
    for forbidden in 'ADR-' 'docs/plans/' 'references/' 'SKILL.md'; do
        count=$(grep -cF -- "$forbidden" "$template" || true)
        [ "$count" -eq 0 ] || { echo "names $forbidden $count times"; false; }
    done
    for skill_dir in "$BATS_TEST_DIRNAME"/../skills/*/; do
        skill_name=$(basename "$skill_dir")
        count=$(grep -cF -- "$skill_name" "$template" || true)
        [ "$count" -eq 0 ] || { echo "names skill $skill_name $count times"; false; }
    done
}

@test "test guidelines: the UI section opens by saying when to keep it" {
    # verifies: D5 (docs/plans/2026-10-08-test-guidelines.md)
    first_ui_line=$(awk '/^## UI$/{found=1; next} found && NF {print; exit}' "$template")
    [ "$first_ui_line" = 'Keep this section only where the project has a user interface.' ] \
        || { echo "$first_ui_line"; false; }
    grep -qxF 'Keep this section only where the project has a user interface.' "$template"
}

@test "test guidelines: the template is at most 1,950 words" {
    # verifies: D5 (docs/plans/2026-10-08-test-guidelines.md)
    words=$(wc -w < "$template" | tr -d ' ')
    [ "$words" -le 1950 ] || { echo "$words words"; false; }
}

@test "test guidelines: Doubles states why a rule of no doubles at all was rejected" {
    # verifies: D5 (docs/plans/2026-10-08-test-guidelines.md)
    doubles=$(awk '/^## Doubles$/{found=1; next} /^## /{found=0} found' "$template")
    printf '%s\n' "$doubles" | grep -qxF '   A rule of no doubles at all was rejected: it makes the dependency-failure' \
        || { echo "Doubles lacks the rejected-rule reason"; false; }
    printf '%s\n' "$doubles" | grep -qxF '   and resource-exhaustion tests of the robustness rule impossible.'
}

@test "test guidelines: Owned services states their cost and leaves the provision to the project" {
    # verifies: D5 (docs/plans/2026-10-08-test-guidelines.md)
    owned=$(awk '/^## Owned services$/{found=1; next} /^## /{found=0} found' "$template")
    printf '%s\n' "$owned" | grep -qxF '3. **The cost is test infrastructure.** The owned services must run in the' \
        || { echo "Owned services lacks its cost"; false; }
    printf '%s\n' "$owned" | grep -qxF '   test environment, in containers or the equivalent. How a project provides'
    printf '%s\n' "$owned" | grep -qxF '   them is its own test-environment decision.'
}

@test "test guidelines: the real-browser clause names a progressive web app's error routes" {
    # verifies: D5 (docs/plans/2026-10-08-test-guidelines.md)
    ui=$(awk '/^## UI$/{found=1; next} /^## /{found=0} found' "$template")
    printf '%s\n' "$ui" | grep -qxF '   IndexedDB, storage quota, installation. For a progressive web app, offline' \
        || { echo "UI lacks the progressive web app sentence"; false; }
    printf '%s\n' "$ui" | grep -qxF '   is the main error route, and a full storage quota is the robustness rule'"'"'s'
    printf '%s\n' "$ui" | grep -qxF '   resource exhaustion.'
}

@test "test guidelines: deep IO and property invariants keep their full wording" {
    # verifies: D5 (docs/plans/2026-10-08-test-guidelines.md)
    grep -qxF '3. **Deep IO with complex error handling follows the same order.** An error' "$template" \
        || { echo "Seams 3 is the shortened deep-IO clause"; false; }
    grep -qxF '   the code handles (retried, turned into a fallback, translated for the' "$template"
    grep -qxF '   user) is observable at the REQ interface: trigger it through a boundary' "$template"
    grep -qxF '   fake there. Where the error handling has a contract of its own (backoff,' "$template"
    grep -qxF '   partial writes, rollback) and criterion 1 or 2 holds, the adapter becomes' "$template"
    grep -qxF '   a software item with an LLR stating that contract, tested at its own' "$template"
    grep -qxF '   interface against the real resource where possible: a temporary' "$template"
    grep -qxF '   directory, a real database file.' "$template"
    grep -qxF '   - round-trip: decoding what was encoded gives the input back;' "$template" \
        || { echo "Property tests lacks the invariant list"; false; }
    grep -qxF '   - idempotence: applying the operation twice equals applying it once;' "$template"
    grep -qxF '   - agreement with an oracle: a slow, obviously correct version of the same' "$template"
    grep -qxF '   - monotonicity or bounds.' "$template"
}

# A clause's reason may wrap across lines, so these checks read a section as
# one line with its whitespace collapsed.
section_text() {
    awk -v heading="## $1" '$0 == heading {found=1; next} /^## /{found=0} found' "$2" \
        | tr '\n' ' ' | tr -s ' '
}

@test "test guidelines: each template clause that lacked a reason states one" {
    # verifies: D5 (docs/plans/2026-10-08-test-guidelines.md)
    seams=$(section_text Seams "$template")
    case "$seams" in
        (*'Why: a handled error is behavior a user sees; only a contract of its own earns the adapter a seam.'*) ;;
        (*) echo "Seams 3 states no reason"; false ;;
    esac
    doubles=$(section_text Doubles "$template")
    case "$doubles" in
        (*'Why: below one adapter, everything the project owns runs for real, and the fake has one interface to imitate.'*) ;;
        (*) echo "Doubles 2 states no reason"; false ;;
    esac
    case "$doubles" in
        (*'Why: there the message is the behavior, so asserting it pins nothing the requirement does not state.'*) ;;
        (*) echo "Doubles 4 states no reason"; false ;;
    esac
    properties=$(section_text 'Property tests' "$template")
    case "$properties" in
        (*'Why: a generator reaches inputs no one thought to write.'*) ;;
        (*) echo "Property tests 1 states no reason"; false ;;
    esac
    ui=$(section_text UI "$template")
    case "$ui" in
        (*'Why: such a test breaks only when what the user perceives changes.'*) ;;
        (*) echo "UI 3 states no reason"; false ;;
    esac
    case "$ui" in
        (*'Why: a screen most often fails outside its loaded state.'*) ;;
        (*) echo "UI 4 states no reason"; false ;;
    esac
    case "$ui" in
        (*'Why: a simulated DOM implements none of these, so a test of them there passes against behavior no browser shows.'*) ;;
        (*) echo "UI 5 states no reason"; false ;;
    esac
    case "$ui" in
        (*'Why: a pixel comparison fails on any visual change, so it is evidence only where appearance is the requirement.'*) ;;
        (*) echo "UI 7 states no reason"; false ;;
    esac
}

# --- this repository's own file, docs/TEST_GUIDELINES.md (T7) --------------

repo_guidelines="$BATS_TEST_DIRNAME/../docs/TEST_GUIDELINES.md"

@test "test guidelines: this repository's file has the template's headings except UI" {
    # verifies: D6, D10 (docs/plans/2026-10-08-test-guidelines.md)
    # This repository has no user interface, so its file drops ## UI and
    # keeps the seven other headings in the template's order.
    expected='# Test guidelines
## Seams
## Doubles
## Owned services
## Property tests
## Mutants
## Existing suites'
    run grep -E '^##? ' "$repo_guidelines"
    [ "$status" -eq 0 ]
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

@test "test guidelines: this repository's file stands alone, naming no guardrails document or skill" {
    # verifies: D6 (docs/plans/2026-10-08-test-guidelines.md)
    [ -f "$repo_guidelines" ] || { echo "no docs/TEST_GUIDELINES.md"; false; }
    for forbidden in 'ADR-' 'docs/plans/' 'references/' 'SKILL.md'; do
        count=$(grep -cF -- "$forbidden" "$repo_guidelines" || true)
        [ "$count" -eq 0 ] || { echo "names $forbidden $count times"; false; }
    done
    for skill_dir in "$BATS_TEST_DIRNAME"/../skills/*/; do
        skill_name=$(basename "$skill_dir")
        count=$(grep -cF -- "$skill_name" "$repo_guidelines" || true)
        [ "$count" -eq 0 ] || { echo "names skill $skill_name $count times"; false; }
    done
}

@test "test guidelines: here a plan decision or problem report states a deeper interface's contract, not an LLR" {
    # verifies: D10 (docs/plans/2026-10-08-test-guidelines.md)
    # This repository keeps no LLR ledger (Seams 1), so Seams 2 and 3 cannot
    # hang a direct test on one.
    grep -qxF '2. **A deeper interface gets a direct test only once a plan decision or a' "$repo_guidelines" \
        || { echo "Seams 2 still hangs on an LLR"; false; }
    grep -qxF '   problem report states its contract.** Here that item plays the role an LLR' "$repo_guidelines"
    grep -qxF '   plays in a project with a ledger: a function in `scripts/lib.sh` gets a new' "$repo_guidelines"
    grep -qxF '   direct test only once a decision or problem item states its contract, and' "$repo_guidelines"
    grep -qxF '   tested at its own interface once a plan decision or problem report' "$repo_guidelines" \
        || { echo "Seams 3 still hangs on an LLR"; false; }
    grep -qxF '   test does not source the library to call one directly unless clause 2' "$repo_guidelines"
    llr_count=$(grep -cF -e 'once it has an LLR' -e 'with an LLR stating' "$repo_guidelines" || true)
    [ "$llr_count" -eq 0 ] || { echo "names an LLR as the permission $llr_count times"; false; }
}

@test "test guidelines: both files define the robustness rule where they first name it" {
    # verifies: D5, D6 (docs/plans/2026-10-08-test-guidelines.md)
    for guidelines in "$template" "$repo_guidelines"; do
        first_use=$(grep -nF 'robustness rule' "$guidelines" | head -n 1 | cut -d: -f1)
        definition=$(grep -nxF '   The robustness rule is that every requirement gets abnormal-input tests' "$guidelines" | cut -d: -f1)
        [ -n "$definition" ] || { echo "$guidelines does not define the robustness rule"; false; }
        [ "$definition" -eq $((first_use + 1)) ] || { echo "$guidelines defines it at $definition, first names it at $first_use"; false; }
        grep -qxF '   (bad input, boundary values, resource exhaustion, dependency failure)' "$guidelines"
        grep -qxF '   beside its normal-case tests.' "$guidelines"
    done
}

@test "test guidelines: this repository's file carries the template's added reasons" {
    # verifies: D5, D6 (docs/plans/2026-10-08-test-guidelines.md)
    seams=$(section_text Seams "$repo_guidelines")
    case "$seams" in
        (*'Why: a handled error is behavior a user sees; only a contract of its own earns the adapter a seam.'*) ;;
        (*) echo "Seams 3 states no reason"; false ;;
    esac
    doubles=$(section_text Doubles "$repo_guidelines")
    case "$doubles" in
        (*'Why: below one adapter, everything the project owns runs for real, and the fake has one interface to imitate.'*) ;;
        (*) echo "Doubles 2 states no reason"; false ;;
    esac
    case "$doubles" in
        (*'Why: there the message is the behavior, so asserting it pins nothing the requirement does not state.'*) ;;
        (*) echo "Doubles 4 states no reason"; false ;;
    esac
    properties=$(section_text 'Property tests' "$repo_guidelines")
    case "$properties" in
        (*'Why: a generator reaches inputs no one thought to write.'*) ;;
        (*) echo "Property tests 1 states no reason"; false ;;
    esac
}

@test "test guidelines: the seam and owned-service ADRs say ADR-me39p4 made them shipped defaults" {
    # verifies: D2, D3 (docs/plans/2026-10-08-test-guidelines.md)
    amendment='Amended by ADR-me39p4 (2026-10-08): this rule is the shipped default of `templates/TEST_GUIDELINES.md`, which a project may change in its own `docs/TEST_GUIDELINES.md`; it is not part of the compliance floor.'
    for adr in "$BATS_TEST_DIRNAME"/../docs/adr/ADR-8ft3hb-*.md "$BATS_TEST_DIRNAME"/../docs/adr/ADR-4xh6cf-*.md; do
        [ -f "$adr" ] || { echo "no file $adr"; false; }
        flat=$(tr '\n' ' ' < "$adr" | tr -s ' ')
        case "$flat" in
            (*"$amendment"*) ;;
            (*) echo "$adr carries no amendment note"; false ;;
        esac
    done
}
