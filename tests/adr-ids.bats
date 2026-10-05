load helpers

# Task T1 of docs/plans/2026-10-04-adr-ids.md: what check-ids.sh, check-trace.sh
# and new-id.sh report once ADR is a declared prefix.
#
# Every ADR ID, PR ID and draft token in this file is assembled at run time
# from a prefix variable. This repository's own gates scan tests/ for
# references, so a literal one here would be a reference to an item that the
# repository does not define.

setup() {
    make_fixture_repo
    git config tag.gpgsign false
    # The shipped config, which declares ADR in its id_prefixes line.
    cp "$BATS_TEST_DIRNAME/../templates/config.yaml" .guardrails/config.yaml
    grep -qE '^id_prefixes:.* ADR( |$)' .guardrails/config.yaml
    mkdir -p docs/adr
    printf '# SRS\n\n**REQ-001**: The system shall exist.\n' > docs/requirements/0001-01-01-base.md
    printf '# verifies: REQ-001\ntrue\n' > tests/test_a.sh
    commit_all "shipped config with ADR declared"
    adr_prefix=ADR
    adr_id="$adr_prefix-k3n8p2"
    adr_file="docs/adr/$adr_id-x.md"
}

# write_adr_item FILE ID — an ADR file that opens with the item line of D1.
write_adr_item() {
    printf '**%s**: The configuration is flat YAML.\n\nStatus: accepted\n' "$2" > "$1"
}

# write_srs_reference TEXT — the SRS item, with TEXT appended to its line.
write_srs_reference() {
    printf '# SRS\n\n**REQ-001**: The system shall exist. %s\n' "$1" \
        > docs/requirements/0001-01-01-base.md
}

# assert_check_ids_clean — check-ids.sh exits 0 with no output, with and
# without --allow-draft-files.
assert_check_ids_clean() {
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ] || { echo "check-ids.sh exit $status: $output"; return 1; }
    [ -z "$output" ] || { echo "$output"; return 1; }
    run sh .guardrails/scripts/check-ids.sh --allow-draft-files
    [ "$status" -eq 0 ] || { echo "check-ids.sh --allow-draft-files exit $status: $output"; return 1; }
    [ -z "$output" ] || { echo "$output"; return 1; }
}

@test "ADR IDs: an ADR item with no reference to it passes every check" {
    # verifies: D1, D2 (docs/plans/2026-10-04-adr-ids.md)
    write_adr_item "$adr_file" "$adr_id"
    commit_all "ADR item"
    assert_check_ids_clean
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    output_has "PR 0, ADR 1"
}

@test "ADR IDs: a reference from an SRS item and from a strict path resolves" {
    # verifies: D1, D2 (docs/plans/2026-10-04-adr-ids.md)
    write_adr_item "$adr_file" "$adr_id"
    write_srs_reference "The format is $adr_id."
    printf '/* format decided in %s */\n' "$adr_id" > src/config.c
    commit_all "references to the ADR"
    assert_check_ids_clean
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    output_lacks "DANGLING-REF"
    output_lacks "MISPLACED-ITEM"
}

@test "ADR IDs: a reference to an ADR ID defined nowhere is DANGLING-REF, as for a PR ID" {
    # verifies: D2 (docs/plans/2026-10-04-adr-ids.md)
    undefined_adr="$adr_prefix-m4q7r9"
    problem_prefix=PR
    undefined_problem="$problem_prefix-m4q7r9"
    write_srs_reference "See $undefined_adr and $undefined_problem."
    commit_all "undefined references"
    assert_check_ids_clean
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    output_has "DANGLING-REF $undefined_adr (referenced but never defined)"
    output_has "DANGLING-REF $undefined_problem (referenced but never defined)"
}

@test "ADR IDs: the same ADR ID defined in two files is DUPLICATE-ID" {
    # verifies: D2 (docs/plans/2026-10-04-adr-ids.md)
    write_adr_item "$adr_file" "$adr_id"
    write_adr_item "docs/adr/$adr_id-y.md" "$adr_id"
    commit_all "duplicate ADR"
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    output_has "DUPLICATE-ID $adr_id (defined more than once in tree)"
    run sh .guardrails/scripts/check-ids.sh --allow-draft-files
    [ "$status" -eq 1 ]
    output_has "DUPLICATE-ID $adr_id (defined more than once in tree)"
    # check-trace.sh has no duplicate rule.
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
}

@test "ADR IDs: a sequential header in a dated file is a valid ID to every check" {
    # verifies: D2 (docs/plans/2026-10-04-adr-ids.md)
    # The measurement for the upgrade note: GR_ID_BODY accepts three or more
    # digits, so a sequential header of four digits is an item, and a
    # reference to it resolves.
    legacy_id="${adr_prefix}-0007"
    write_adr_item docs/adr/2026-08-22-legacy.md "$legacy_id"
    write_srs_reference "See $legacy_id."
    commit_all "sequential ADR header"
    assert_check_ids_clean
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    output_has "PR 0, ADR 1"
}

@test "ADR IDs: a header with a two-digit number is MALFORMED-ID" {
    # verifies: D2 (docs/plans/2026-10-04-adr-ids.md)
    # The upgrade-note row for a header of fewer than three digits.
    short_id="${adr_prefix}-07"
    write_adr_item docs/adr/2026-08-22-short.md "$short_id"
    commit_all "two-digit ADR header"
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    output_has "MALFORMED-ID docs/adr/2026-08-22-short.md:1:**$short_id**:"
    run sh .guardrails/scripts/check-ids.sh --allow-draft-files
    [ "$status" -eq 1 ]
    output_has "MALFORMED-ID docs/adr/2026-08-22-short.md:1:**$short_id**:"
}

@test "ADR IDs: a reference with a two-digit number is reported by no check" {
    # verifies: D2 (docs/plans/2026-10-04-adr-ids.md)
    # The upgrade-note row for a reference of fewer than three digits: the
    # reference pattern does not match it, so it is neither resolved nor
    # DANGLING-REF.
    short_id="${adr_prefix}-07"
    write_srs_reference "See $short_id."
    commit_all "two-digit ADR reference"
    assert_check_ids_clean
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    output_lacks "$short_id"
    output_has "PR 0, ADR 0"
}

@test "ADR IDs: a dated ADR file with a heading and no item line passes every check" {
    # verifies: D2 (docs/plans/2026-10-04-adr-ids.md)
    # The form of the ADRs in this repository before T3.
    printf '# ADR: the configuration is flat YAML\n\nDate: 2026-08-22\nStatus: accepted\n' \
        > docs/adr/2026-08-22-flat-config.md
    commit_all "dated ADR without an item line"
    assert_check_ids_clean
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    output_has "PR 0, ADR 0"
}

@test "ADR IDs: an ADR draft token is DRAFT-ID, with and without --allow-draft-files" {
    # verifies: D2 (docs/plans/2026-10-04-adr-ids.md)
    draft_marker=DRAFT
    draft_token="$adr_prefix-$draft_marker-x-1"
    write_adr_item docs/adr/draft.md "$draft_token"
    commit_all "ADR draft token"
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    output_has "DRAFT-ID docs/adr/draft.md:1:**$draft_token**:"
    run sh .guardrails/scripts/check-ids.sh --allow-draft-files
    [ "$status" -eq 1 ]
    output_has "DRAFT-ID docs/adr/draft.md:1:**$draft_token**:"
}

@test "ADR IDs: new-id.sh ADR prints one ADR ID" {
    # verifies: D1, D2 (docs/plans/2026-10-04-adr-ids.md)
    token_re=$(sh -c '. .guardrails/scripts/lib.sh && printf "%s" "$GR_ID_TOKEN"')
    [ -n "$token_re" ]
    run sh .guardrails/scripts/new-id.sh ADR
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    [ "$(printf '%s\n' "$output" | wc -l)" -eq 1 ] || { echo "$output"; return 1; }
    printf '%s\n' "$output" | grep -qE "^ADR-($token_re)\$" || { echo "$output"; return 1; }
}

@test "ADR IDs: new-id.sh ADR exits 2 when ADR is not declared" {
    # verifies: D2 (docs/plans/2026-10-04-adr-ids.md)
    sed -i.bak -E 's/^(id_prefixes:.*) ADR( |$)/\1\2/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    run grep -qE '^id_prefixes:.* ADR( |$)' .guardrails/config.yaml
    [ "$status" -ne 0 ]
    commit_all "ADR not declared"
    run sh .guardrails/scripts/new-id.sh ADR
    [ "$status" -eq 2 ]
    output_has "ADR is not declared in id_prefixes"
}
