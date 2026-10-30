# Content checks over the shipped code guidelines, templates/CODE_GUIDELINES.md,
# and this repository's docs/CODE_GUIDELINES.md.

load helpers

template="$BATS_TEST_DIRNAME/../templates/CODE_GUIDELINES.md"

# Prints the lines of the grep -rn output in $output that are not in the
# upgrade notes, which keep an old name on purpose: they tell an upgrading
# project it is gone.
hits_outside_upgrade_notes() {
    # grep -v exits 1 when it filters out every line, the passing case,
    # and `|| true` keeps the empty result. It reads a pipe, so it has no
    # file to fail to open.
    printf '%s\n' "$output" | grep -v 'skills/ratchet/references/upgrade-notes.md' || true
}

@test "code guidelines: the template's clauses, by heading and number" {
    # verifies: REQ-an7yxp
    expected="## Names | 1. **No single-character names.**
## Names | 2. **No code golf.**
## Names | 3. **Name in concrete terms.**
## Names | 4. **One name per concept across the change.**
## Simplicity | 1. **Write the smallest code that passes.**
## Simplicity | 2. **No speculative option or abstraction.**
## Simplicity | 3. **Delete dead and commented-out code.**
## Simplicity | 4. **No duplication between tasks.**
## Errors | 1. **Fail loudly.**
## Errors | 2. **No swallowed error.**
## Errors | 3. **No silent fallback.**
## Errors | 4. **An edit or substitution that matches nothing is an error.**
## Comments | 1. **A comment says why, not what.**
## Comments | 2. **No change narration.**
## Comments | 3. **Match the surrounding code's comment density.**"
    [ -f "$template" ] || { echo "no templates/CODE_GUIDELINES.md"; false; }
    actual=$(clause_list "$template")
    [ "$actual" = "$expected" ] || { echo "$actual"; false; }
}

@test "code guidelines: the template has the four headings, in order" {
    # verifies: REQ-an7yxp
    expected='# Code guidelines
## Names
## Simplicity
## Errors
## Comments'
    run grep -E '^##? ' "$template"
    [ "$status" -eq 0 ]
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

@test "code guidelines: every clause states a reason and an example" {
    # verifies: REQ-mdxb9m
    missing=$(clauses_missing_reason_or_example "$template")
    [ -z "$missing" ] || { echo "clauses with no reason or example: $missing"; false; }
}

@test "code guidelines: the template bounds abstraction, dead code, catch blocks, empty matches and narrating comments" {
    # verifies: REQ-d7px4f, REQ-brsh59, REQ-eab32v, REQ-aac3vf, REQ-ft7e5p
    flat=$(tr '\n' ' ' < "$template" | tr -s ' ')
    printf '%s\n' "$flat" | grep -qF 'without a second caller'
    printf '%s\n' "$flat" | grep -qF 'commented-out code are deleted'
    printf '%s\n' "$flat" | grep -qF 'No empty catch block'
    printf '%s\n' "$flat" | grep -qF 'unless matching nothing is a stated, expected outcome'
    printf '%s\n' "$flat" | grep -qF 'never the change that wrote it'
}

@test "code guidelines: the preface states the one-file rule and the floor rule" {
    # verifies: REQ-n45q7m
    preface=$(awk '/^## /{exit} {print}' "$template")
    printf '%s\n' "$preface" | grep -qF 'and no other guidelines file'
    printf '%s\n' "$preface" | grep -qF 'is a finding against the clause'
    preface_lines=$(printf '%s\n' "$preface" | grep -cv -e '^#' -e '^$')
    [ "$preface_lines" -le 5 ] || { echo "preface is $preface_lines lines"; false; }
}

@test "code guidelines: the template stands alone, naming no guardrails document or skill" {
    # verifies: REQ-jb83qg
    names_no_guardrails_document_or_skill "$template"
}

@test "code guidelines: the template is at most 1,400 words" {
    # verifies: REQ-h6e9bu
    words=$(wc -w < "$template" | tr -d ' ')
    [ "$words" -le 1400 ] || { echo "$words words"; false; }
}

repo_guidelines="$BATS_TEST_DIRNAME/../docs/CODE_GUIDELINES.md"

@test "code guidelines: this repository's file keeps every clause of the template" {
    # verifies: REQ-htmf2j
    [ -f "$repo_guidelines" ] || { echo "no docs/CODE_GUIDELINES.md"; false; }
    template_clauses=$(clause_list "$template")
    repo_clauses=$(clause_list "$repo_guidelines")
    [ "$repo_clauses" = "$template_clauses" ] || { echo "$repo_clauses"; false; }
    run grep -E '^##? ' "$repo_guidelines"
    [ "$output" = "$(grep -E '^##? ' "$template")" ] || { echo "$output"; false; }
}

@test "code guidelines: this repository's file stands alone, naming no guardrails document or skill" {
    # verifies: REQ-jb83qg
    [ -f "$repo_guidelines" ] || { echo "no docs/CODE_GUIDELINES.md"; false; }
    names_no_guardrails_document_or_skill "$repo_guidelines"
}

@test "code guidelines: this repository's examples are its own POSIX sh" {
    # verifies: REQ-hfq59z
    [ -f "$repo_guidelines" ] || { echo "no docs/CODE_GUIDELINES.md"; false; }
    [ -f "$template" ] || { echo "no templates/CODE_GUIDELINES.md"; false; }
    if cmp -s "$template" "$repo_guidelines"; then echo "the file is the template unchanged"; false; fi
    section_of '## Names' "$repo_guidelines" | grep -qF 'index_number'
    section_of '## Errors' "$repo_guidelines" | grep -qF 'gr_die'
    section_of '## Errors' "$repo_guidelines" | grep -qF 'sed -i.bak'
    section_of '## Comments' "$repo_guidelines" | grep -qF 'header comment'
}

@test "code guidelines: this repository's file is at most 1,600 words" {
    # verifies: REQ-9q9v3p
    words=$(wc -w < "$repo_guidelines" | tr -d ' ')
    [ "$words" -le 1600 ] || { echo "$words words"; false; }
}

@test "code guidelines: no silent fallback permits a default a requirement names" {
    # verifies: REQ-6k3j4u
    clause=$(awk '/^## Errors/ { inside = 1; next } /^## / { inside = 0 } inside' "$template" |
        tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$clause" |
        grep -qF 'A missing file, setting or value is an error unless a requirement names the default.' ||
        { echo "the Errors section does not permit a named default"; false; }
}

@test "code guidelines: every kind guidelines-file.sh knows has a shipped template" {
    # verifies: REQ-hgq5pc
    root="$BATS_TEST_DIRNAME/.."
    make_fixture_repo
    run sh .guardrails/scripts/guidelines-file.sh NO_SUCH_KIND src/a.sh
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    kinds=$(printf '%s\n' "$output" | sed -n 's/.*unknown kind: NO_SUCH_KIND (known: \(.*\))$/\1/p')
    [ -n "$kinds" ] || { echo "no known-kinds list: $output"; false; }
    for kind in $kinds; do
        [ -f "$root/templates/${kind}_GUIDELINES.md" ] || { echo "no template for $kind"; false; }
    done
}

@test "code guidelines: the old whole-diff pass is gone from the skills, templates and tests" {
    # verifies: REQ-fmnw9y
    root="$BATS_TEST_DIRNAME/.."
    old_name='des''lop'
    run grep -rniF -- "$old_name" "$root/skills" "$root/templates" "$root/tests" "$root/README.md" "$root/AGENTS.md"
    hits=$(hits_outside_upgrade_notes)
    [ -z "$hits" ] || { echo "$hits"; false; }
}

@test "code guidelines: no skill, template or AGENTS.md keeps a ## Code: names section" {
    # verifies: REQ-96x6xg
    root="$BATS_TEST_DIRNAME/.."
    run grep -rnF -- '## Code: names' "$root/skills" "$root/templates" "$root/AGENTS.md"
    hits=$(hits_outside_upgrade_notes)
    [ -z "$hits" ] || { echo "$hits"; false; }
}

@test "code guidelines: the old name of review-conformance is gone outside the upgrade notes" {
    # verifies: REQ-fmnw9y
    root="$BATS_TEST_DIRNAME/.."
    old_name='review-''guidelines'
    run grep -rnF -- "$old_name" "$root/skills" "$root/templates" "$root/tests" "$root/scripts" "$root/README.md" "$root/AGENTS.md" "$root/install.sh"
    hits=$(hits_outside_upgrade_notes)
    [ -z "$hits" ] || { echo "$hits"; false; }
}

@test "code guidelines: a comment cites an ADR, never a plan file, a docs/verification file or a problem report" {
    # verifies: ADR-k3nkv3
    for guidelines_file in "$template" "$repo_guidelines"; do
        [ -f "$guidelines_file" ] || { echo "missing: $guidelines_file"; false; }
        flat=$(section_of '## Comments' "$guidelines_file" | tr '\n' ' ' | tr -s ' ')
        for phrase in 'or cites an ADR by ID' \
            'never cites a plan file, a docs/verification file or a problem report' \
            'plans and docs/verification files leave the base branch' \
            'a problem report is deleted when it is resolved' \
            'HISTORY-CITATION' \
            'the squash message carries the history'; do
            printf '%s\n' "$flat" | grep -qF "$phrase" \
                || { echo "$guidelines_file lacks: $phrase"; false; }
        done
        if printf '%s\n' "$flat" | grep -qF "the change's records carry the history"; then
            echo "$guidelines_file still says the change's records carry the history"; false
        fi
    done
}
