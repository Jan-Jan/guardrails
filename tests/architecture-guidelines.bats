# Content checks over the shipped architecture guidelines,
# templates/ARCHITECTURE_GUIDELINES.md
# (docs/plans/2026-10-14-architecture-guidelines.md, D1 and D4).

load helpers

template="$BATS_TEST_DIRNAME/../templates/ARCHITECTURE_GUIDELINES.md"

@test "architecture guidelines: the template's clauses, by heading and number" {
    # verifies: D4 (docs/plans/2026-10-14-architecture-guidelines.md)
    expected="## Domain | 1. **A public interface speaks the glossary.**
## Domain | 2. **A new public term enters the glossary in the same change.**
## Domain | 3. **One term, one meaning, within a unit.**
## Core and edges | 1. **Rules live in a core that performs no I/O.**
## Core and edges | 2. **I/O lives in adapters at the edge.**
## Core and edges | 3. **Dependencies point inward.**
## Core and edges | 4. **One adapter per third-party dependency.**
## Boundaries | 1. **An item is entered only through its interface.**
## Boundaries | 2. **An error crosses a boundary as the interface's own error.**
## Boundaries | 3. **One responsibility per item.**
## Constraints | 1. **A rule a tool can decide is an LLR with a test.**
## Existing code | 1. **These rules bind the structure a change writes.**"
    [ -f "$template" ] || { echo "no templates/ARCHITECTURE_GUIDELINES.md"; false; }
    actual=$(clause_list "$template")
    [ "$actual" = "$expected" ] || { echo "$actual"; false; }
}

@test "architecture guidelines: the template has the five headings, in order" {
    # verifies: D4 (docs/plans/2026-10-14-architecture-guidelines.md)
    expected='# Architecture guidelines
## Domain
## Core and edges
## Boundaries
## Constraints
## Existing code'
    run grep -E '^##? ' "$template"
    [ "$status" -eq 0 ]
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

@test "architecture guidelines: every clause states a reason and an example" {
    # verifies: D4 (docs/plans/2026-10-14-architecture-guidelines.md)
    [ -f "$template" ] || { echo "no templates/ARCHITECTURE_GUIDELINES.md"; false; }
    missing=$(clauses_missing_reason_or_example "$template")
    [ -z "$missing" ] || { echo "clauses with no reason or example: $missing"; false; }
}

@test "architecture guidelines: the boundaries D4 names are stated" {
    # verifies: D4 (docs/plans/2026-10-14-architecture-guidelines.md)
    [ -f "$template" ] || { echo "no templates/ARCHITECTURE_GUIDELINES.md"; false; }
    flat=$(tr '\n' ' ' < "$template" | tr -s ' ')
    printf '%s\n' "$flat" | grep -qF 'never a synonym it lists under `_Avoid_`'
    printf '%s\n' "$flat" | grep -qF 'Names inside an item are not bound by this clause.'
    printf '%s\n' "$flat" | grep -qF 'Two units may define a word differently.'
    printf '%s\n' "$flat" | grep -qF 'reads and writes no file, network, database, device, environment variable, clock or random source'
    # D4: the adapters hold every access the core is kept from, environment variables included.
    printf '%s\n' "$flat" | grep -qF 'Each access to a file, network, database, device, environment variable, clock or random source is in an adapter' \
        || { echo "Core and edges 2 omits an access Core and edges 1 keeps out of the core"; false; }
    printf '%s\n' "$flat" | grep -qF 'The core imports no adapter, framework or infrastructure module'
    printf '%s\n' "$flat" | grep -qF "outside the language's standard library"
    printf '%s\n' "$flat" | grep -qF 'keeps the error it received as the cause'
    printf '%s\n' "$flat" | grep -qF 'A rule that needs judgment stays a clause in this file.'
    printf '%s\n' "$flat" | grep -qF 'No change restructures a codebase wholesale for compliance.'
}

@test "architecture guidelines: the boundary's test fake is the interface's second implementation" {
    # verifies: D8 (docs/plans/2026-10-14-architecture-guidelines.md)
    [ -f "$template" ] || { echo "no templates/ARCHITECTURE_GUIDELINES.md"; false; }
    core=$(section_of '## Core and edges' "$template" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$core" | grep -qF "The test fake at the boundary counts as the interface's second implementation" ||
        { echo "Core and edges lacks the test fake as second implementation"; false; }
    printf '%s\n' "$core" | grep -qF 'the interface is the parameter the core takes, with no declared type' ||
        { echo "Core and edges lacks the duck-typed interface"; false; }
}

@test "architecture guidelines: a rule a tool can decide is an LLR with a test" {
    # verifies: D1, D4 (docs/plans/2026-10-14-architecture-guidelines.md)
    [ -f "$template" ] || { echo "no templates/ARCHITECTURE_GUIDELINES.md"; false; }
    constraints=$(section_of '## Constraints' "$template" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$constraints" | grep -qF 'is written as an LLR on the software item it binds'
    printf '%s\n' "$constraints" | grep -qF 'annotated with that LLR'
    # D4: the example names a kind of tool, not one language's package.
    printf '%s\n' "$constraints" | grep -qF "verified by an import linter's rule run in the test suite" \
        || { echo "the example is not language-neutral: $constraints"; false; }
    if printf '%s\n' "$constraints" | grep -qF 'import-linter'; then
        echo "the example still names the import-linter package"; false
    fi
}

@test "architecture guidelines: the preface states the one-file rule and the floor rule" {
    # verifies: D4 (docs/plans/2026-10-14-architecture-guidelines.md)
    [ -f "$template" ] || { echo "no templates/ARCHITECTURE_GUIDELINES.md"; false; }
    preface=$(awk '/^## /{exit} {print}' "$template")
    flat_preface=$(printf '%s\n' "$preface" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$flat_preface" | grep -qF 'and no other guidelines file'
    printf '%s\n' "$flat_preface" | grep -qF 'is a finding against the clause'
    preface_lines=$(printf '%s\n' "$preface" | grep -cv -e '^#' -e '^$')
    [ "$preface_lines" -le 6 ] || { echo "preface is $preface_lines lines"; false; }
}

@test "architecture guidelines: the template stands alone, naming no guardrails document or skill" {
    # verifies: D4 (docs/plans/2026-10-14-architecture-guidelines.md); D6 (docs/plans/2026-10-08-test-guidelines.md)
    [ -f "$template" ] || { echo "no templates/ARCHITECTURE_GUIDELINES.md"; false; }
    names_no_guardrails_document_or_skill "$template"
}

@test "architecture guidelines: the template is at most 1,300 words" {
    # verifies: D4 (docs/plans/2026-10-14-architecture-guidelines.md)
    [ -f "$template" ] || { echo "no templates/ARCHITECTURE_GUIDELINES.md"; false; }
    words=$(wc -w < "$template" | tr -d ' ')
    [ "$words" -le 1300 ] || { echo "$words words"; false; }
}

repo_guidelines="$BATS_TEST_DIRNAME/../docs/ARCHITECTURE_GUIDELINES.md"

@test "architecture guidelines: this repository's file stands alone, naming no guardrails document or skill" {
    # verifies: D5 (docs/plans/2026-10-14-architecture-guidelines.md)
    [ -f "$repo_guidelines" ] || { echo "no docs/ARCHITECTURE_GUIDELINES.md"; false; }
    names_no_guardrails_document_or_skill "$repo_guidelines"
}

@test "architecture guidelines: every clause of this repository's file states a reason and an example" {
    # verifies: D5 (docs/plans/2026-10-14-architecture-guidelines.md)
    [ -f "$repo_guidelines" ] || { echo "no docs/ARCHITECTURE_GUIDELINES.md"; false; }
    # D5: a file with no clauses would pass the reason-and-example scan vacuously.
    [ -n "$(clause_list "$repo_guidelines")" ] || { echo "docs/ARCHITECTURE_GUIDELINES.md has no clauses"; false; }
    missing=$(clauses_missing_reason_or_example "$repo_guidelines")
    [ -z "$missing" ] || { echo "clauses with no reason or example: $missing"; false; }
}

@test "architecture guidelines: this repository's file is at most 1,500 words" {
    # verifies: D5 (docs/plans/2026-10-14-architecture-guidelines.md)
    [ -f "$repo_guidelines" ] || { echo "no docs/ARCHITECTURE_GUIDELINES.md"; false; }
    words=$(wc -w < "$repo_guidelines" | tr -d ' ')
    [ "$words" -le 1500 ] || { echo "$words words"; false; }
}
