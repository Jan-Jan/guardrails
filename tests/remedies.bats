load helpers

# D8 (docs/plans/2026-09-28-agent-first-skills.md): after its violation lines,
# and before any checked:, problems: or sources: line, a check script prints
# one `fix <RULE>: <remedy>` line per distinct rule that fired, in the order
# the rules first fired. The violation lines keep their documented form.
#
# Assertions use `run` and `[ ]` followed by `|| { ...; false; }`: a bare
# `[[ ]]` or `!` mid-test is skipped by errexit under bash 3.2, so it would
# assert nothing on macOS.

setup() {
    make_fixture_repo
    write_traced_docs
    commit_all good
}

# Two untested REQs (MISSING-TEST twice) and one reference to an ID defined
# nowhere (DANGLING-REF once).
two_rules_fixture() {
    cat >> docs/requirements/0001-01-01-base.md <<'MD'

**REQ-002**: The system shall log the dose.

**REQ-003**: The system shall alarm on overdose.
MD
    printf '**PR-001**: Crash on empty input.\naffects: REQ-999\nstatus: resolved\n' \
        > docs/problems/0001-01-01-base.md
    commit_all two-rules
}

# Prints the 1-based line number of the first output line matching the ERE $1,
# or 0 when none does.
line_of() {
    printf '%s\n' "$output" | awk -v pattern="$1" '$0 ~ pattern { print NR; found = 1; exit } END { if (!found) print 0 }'
}

# Prints the 1-based line number of the last output line matching the ERE $1.
last_line_of() {
    printf '%s\n' "$output" | awk -v pattern="$1" '$0 ~ pattern { last = NR } END { print last + 0 }'
}

fix_count() {
    printf '%s\n' "$output" | grep -c '^fix ' || true
}

# Every remedy is at most 200 characters (the shared form in
# docs/plans/2026-09-29-agent-first-skills-change-2.md).
remedies_within_limit() {
    printf '%s\n' "$output" | awk '/^fix / { sub(/^fix [A-Z0-9-]+: /, ""); if (length($0) > 200) { print "too long: " $0; bad = 1 } } END { exit bad }'
}

@test "check-trace: one fix line per rule that fired, after the violations" {
    # verifies: D8 (docs/plans/2026-09-28-agent-first-skills.md)
    two_rules_fixture
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [ "$(printf '%s\n' "$output" | grep -c '^MISSING-TEST ')" -eq 2 ] || { echo "$output"; false; }
    [ "$(fix_count)" -eq 2 ] || { echo "$output"; false; }
    missing_fix=$(line_of '^fix MISSING-TEST: ')
    dangling_fix=$(line_of '^fix DANGLING-REF: ')
    last_violation=$(last_line_of '^(MISSING-TEST|DANGLING-REF) ')
    checked=$(line_of '^checked: ')
    [ "$missing_fix" -gt 0 ] || { echo "$output"; false; }
    [ "$dangling_fix" -gt "$missing_fix" ] || { echo "$output"; false; }
    [ "$missing_fix" -gt "$last_violation" ] || { echo "$output"; false; }
    [ "$checked" -gt "$dangling_fix" ] || { echo "$output"; false; }
    remedies_within_limit || { echo "$output"; false; }
}

@test "check-trace: a clean run prints no fix line" {
    # verifies: D8 (docs/plans/2026-09-28-agent-first-skills.md)
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$(fix_count)" -eq 0 ] || { echo "$output"; false; }
}

@test "check-trace: violation lines are unchanged" {
    # verifies: D8 (docs/plans/2026-09-28-agent-first-skills.md)
    # The documented text of each line, as the script printed it before D8.
    # Anything that greps or counts violation lines depends on it.
    two_rules_fixture
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -qxF "MISSING-TEST REQ-002 (no direct 'verifies:' and no tested LLR satisfies it)" \
        || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -qxF "MISSING-TEST REQ-003 (no direct 'verifies:' and no tested LLR satisfies it)" \
        || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -qxF "DANGLING-REF REQ-999 (referenced but never defined)" \
        || { echo "$output"; false; }
}

@test "check-trace: every report in the roster has a remedy" {
    # verifies: D8 (docs/plans/2026-09-28-agent-first-skills.md)
    # The roster is the `#   TOKEN` lines of the script header, default and
    # scoped reports both — the extraction tests/skills.bats uses, without its
    # stop at the scoped heading. A remedy entry is a case pattern `(TOKEN)`
    # at the start of a line. Exactly one each: a second entry would never be
    # reached, and a missing one prints no fix line for that rule.
    script="$BATS_TEST_DIRNAME/../scripts/check-trace.sh"
    roster=$(
        awk '!/^#/ { exit } /^#   [A-Z]/ { print $2 }' "$script" \
            | grep -E '^[A-Z][A-Z0-9]*(-[A-Z0-9]+)+$' | sort -u
    )
    n_roster=$(printf '%s\n' "$roster" | grep -c . || true)
    [ "$n_roster" -ge 15 ] || { echo "the roster extraction read $n_roster reports, expected at least 15"; false; }
    wrong=""
    for token in $roster; do
        entries=$(grep -cE "^[[:space:]]*\($token\) " "$script" || true)
        [ "$entries" -eq 1 ] || wrong="$wrong $token:$entries"
    done
    [ -z "$wrong" ] || { echo "reports without exactly one remedy entry:$wrong"; false; }
}

@test "check-trace: a warning-only run prints its fix lines and exits 0" {
    # verifies: D8 (docs/plans/2026-09-28-agent-first-skills.md)
    write_pr PR-001 open "$(days_ago 5)"
    commit_all open-pr
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$(fix_count)" -eq 1 ] || { echo "$output"; false; }
    [ "$(line_of '^fix UNRESOLVED-PR: ')" -gt "$(line_of '^UNRESOLVED-PR PR-001 ')" ] || { echo "$output"; false; }
    [ "$(line_of '^checked: ')" -gt "$(line_of '^fix UNRESOLVED-PR: ')" ] || { echo "$output"; false; }
}

@test "check-ids: one fix line per rule that fired" {
    # verifies: D8 (docs/plans/2026-09-28-agent-first-skills.md)
    cat >> docs/requirements/0001-01-01-base.md <<'MD'

**REQ-abcdef**: a body that is not an ID.
MD
    printf '# Duplicate\n\n**REQ-001**: The system shall exist twice.\n' \
        > docs/requirements/0001-01-02-dup.md
    commit_all two-rules
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [ "$(fix_count)" -eq 2 ] || { echo "$output"; false; }
    malformed_fix=$(line_of '^fix MALFORMED-ID: ')
    duplicate_fix=$(line_of '^fix DUPLICATE-ID: ')
    last_violation=$(last_line_of '^(MALFORMED-ID|DUPLICATE-ID) ')
    [ "$malformed_fix" -gt "$last_violation" ] || { echo "$output"; false; }
    [ "$duplicate_fix" -gt "$malformed_fix" ] || { echo "$output"; false; }
    remedies_within_limit || { echo "$output"; false; }
}

@test "check-ids: the remedy for a draft ID names new-id.sh" {
    # verifies: D8 (docs/plans/2026-09-28-agent-first-skills.md)
    # The token is built at run time: the literal in this file would be a
    # DRAFT-ID finding against the repository's own tree.
    draft=DRAFT
    printf 'A note referring to PR-%s-x-1 in prose.\n' "$draft" > docs/problems/z.md
    commit_all draft
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -q '^fix DRAFT-ID: .*new-id\.sh' || { echo "$output"; false; }
}

@test "check-ids: --allow-draft-files prints no fix line for a draft file" {
    # verifies: D8 (docs/plans/2026-09-28-agent-first-skills.md)
    printf '**PR-a3k9z2**: a real item.\nstatus: open\n' > docs/problems/DRAFT-x-new.md
    commit_all draftfile
    run sh .guardrails/scripts/check-ids.sh --allow-draft-files
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$(fix_count)" -eq 0 ] || { echo "$output"; false; }
    # The same tree without the flag does print one, so the zero above is the
    # flag's doing and not a fixture that fires nothing.
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -q '^fix DRAFT-FILE: ' || { echo "$output"; false; }
}

@test "check-ids: the DRAFT-FILE fix line names both the mid-change flag and the merge step that renames the file" {
    # verifies: D8 (docs/plans/2026-09-28-agent-first-skills.md)
    # Without the flag is how merge-preflight.sh runs it, after step 3; a line
    # that only states to leave the file gives the pre-flight no way forward.
    printf '**PR-a3k9z2**: a real item.\nstatus: open\n' > docs/problems/DRAFT-x-new.md
    commit_all draftfile
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -qxF 'fix DRAFT-FILE: Mid-change, leave it: check-ids.sh --allow-draft-files passes it. At merge, run merge-change step 3 (finalize-docs.sh), which renames it, then run this check again.' \
        || { echo "$output"; false; }
}

@test "check-trace: every report it prints has a remedy line" {
    # verifies: PR-6d2jvt
    # verifies: D8 (docs/plans/2026-09-28-agent-first-skills.md)
    # PR-6d2jvt: d8502d1 added three reports and changed a fourth's accepted
    # values, and the catalogue an author looked findings up in was not
    # updated, so a failing gate printed reports documented nowhere. The
    # catalogue is now the script's own `fix <RULE>:` output (D8), so this test
    # requires a remedy entry in check_trace_remedy for every report the script
    # prints.
    #
    # EXTRACTION, derived from the script rather than listed here — a list in
    # this test would be a third copy and would go out of date the same way:
    #   * the printed reports are every `print_violations "TOKEN` /
    #     `printf "TOKEN` site, skipping the grading letter and age some lines
    #     print before the token (`F 0 `, `W %d `);
    #   * a remedy entry is a case pattern `(TOKEN)` at the start of a line.
    # The second scan keeps the header roster honest: a report printed by the
    # script but absent from the header would otherwise be invisible to the
    # roster test above.
    script="$BATS_TEST_DIRNAME/../scripts/check-trace.sh"

    sites=$(
        grep -oE '(print_violations|printf) "([A-Z] (-?[0-9]+|%d) )?[A-Z][A-Z0-9]*(-[A-Z0-9]+)+' "$script" \
            | sed -E 's/^(print_violations|printf) "([A-Z] (-?[0-9]+|%d) )?//' | sort -u
    )
    # An empty extraction makes both comparisons succeed having compared
    # nothing. A floor, not an exact count: adding a report must not edit it.
    n_sites=$(printf '%s\n' "$sites" | grep -c . || true)
    [ "$n_sites" -ge 18 ] || { echo "the emission scan found $n_sites report sites, expected at least 18"; false; }

    unremedied=""
    for token in $sites; do
        grep -qE "^[[:space:]]*\($token\) " "$script" || unremedied="$unremedied $token"
    done
    [ -z "$unremedied" ] || { echo "reports check-trace.sh prints with no remedy entry:$unremedied"; false; }

    roster=$(
        grep -E '^#   [A-Z][A-Z0-9]*(-[A-Z0-9]+)+ ' "$script" | awk '{ print $2 }' | sort -u
    )
    undeclared=""
    for token in $sites; do
        printf '%s\n' "$roster" | grep -qx "$token" || undeclared="$undeclared $token"
    done
    [ -z "$undeclared" ] || { echo "reports check-trace.sh prints that its own header does not list:$undeclared"; false; }
}

@test "check-trace: the problem-limit remedies offer the accepted ruling" {
    # verifies: PR-9xxz3b, PR-4fwfjp
    # STALE-PROBLEM and PROBLEM-BACKLOG offered the reporter two choices: fix
    # someone else's problem report under merge pressure, or raise a limit.
    # The third answer, a ruling as status: accepted, has to be stated where
    # the gate fails. That accepted items stay in the roll-call is verified
    # by the ACCEPTED-PR tests in tests/check-trace.bats.
    printf 'problem_age_days: 30\nproblem_open_max: 1\n' >> .guardrails/config.yaml
    write_pr PR-001 open "$(days_ago 40)"
    write_pr PR-002 open "$(days_ago 40)"
    commit_all both-limits
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -q '^fix STALE-PROBLEM: .*status: accepted' || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -q '^fix PROBLEM-BACKLOG: .*status: accepted' || { echo "$output"; false; }
}

@test "check-trace: the MALFORMED-STATUS remedy names all three values" {
    # verifies: PR-4fwfjp
    # d8502d1 added accepted as a third status, and the remedy then told the
    # author to pick one of two.
    write_pr PR-001 wontfix
    commit_all wontfix
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    fix=$(printf '%s\n' "$output" | grep '^fix MALFORMED-STATUS: ')
    for value in open accepted resolved; do
        printf '%s\n' "$fix" | grep -q "$value" || { echo "$output"; false; }
    done
}

@test "check-trace: the UNANALYZED-DERIVED remedy names assesses:" {
    # verifies: PR-n274s7
    # D1 of that change was a hard cut: a mention of a derived item in the RMF
    # stopped counting, so the remedy has to name the annotation that does.
    printf '\n**REQ-002**: The software shall retry the bus handshake.\nsatisfies: derived\n' \
        >> docs/requirements/0001-01-01-base.md
    printf '# verifies: REQ-002\ntrue\n' > tests/test_b.sh
    commit_all derived
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -q '^fix UNANALYZED-DERIVED: .*assesses: ' || { echo "$output"; false; }
}

@test "check-trace: the DANGLING-FILE remedy names the dated file" {
    # verifies: PR-58zsvf
    # A reference to a draft another change already merged: the fix is the
    # dated name it was merged under, never deleting the reference.
    printf '\nHazards: docs/risk/DRAFT-other-alarms.md.\n' >> docs/requirements/0001-01-01-base.md
    commit_all dangling-file
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -q '^fix DANGLING-FILE: .*dated name' || { echo "$output"; false; }
    printf '%s\n' "$output" | grep -q '^fix DANGLING-FILE: .*never delete the reference' || { echo "$output"; false; }
}

@test "check-trace: an exit 2 after a collected violation still prints the violation" {
    # verifies: D8 (docs/plans/2026-09-28-agent-first-skills.md)
    # MISSING-TEST is collected before the reference scan, and the stand-in git
    # fails that scan, so check-trace.sh exits 2 through gr_die after it has
    # printed a violation line, and that line remains in the output.
    # The fault keys on the boundary class, which only the reference harvest
    # passes to a -oE scan (the same stand-in as check-trace.bats uses).
    real_git=$(command -v git)
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cat > "$BATS_TEST_TMPDIR/bin/git" <<EOF
#!/bin/sh
if [ "\$1" = grep ]; then
    _oe=; _tail=
    for a in "\$@"; do
        [ "\$a" = -oE ] && _oe=1
        case "\$a" in (*'[^0-9A-Za-z]'*) _tail=1 ;; esac
    done
    [ -n "\$_oe" ] && [ -n "\$_tail" ] && exit 129
fi
exec $real_git "\$@"
EOF
    chmod 755 "$BATS_TEST_TMPDIR/bin/git"
    two_rules_fixture

    PATH="$BATS_TEST_TMPDIR/bin:$PATH" run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    [ "$(line_of 'reference scan failed')" -gt 0 ] || { echo "$output"; false; }
    [ "$(line_of '^MISSING-TEST REQ-002 ')" -gt 0 ] \
        || { echo "the collected violation was not printed: $output"; false; }
}

@test "check-trace: a TMPDIR that does not exist changes neither the exit nor the fix lines" {
    # verifies: D8 (docs/plans/2026-09-28-agent-first-skills.md)
    # The violation lines and the fix lines are produced without a temporary
    # file, so a missing TMPDIR is not an exit 2.
    two_rules_fixture
    TMPDIR="$BATS_TEST_TMPDIR/no-such-directory" run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [ "$(line_of '^MISSING-TEST REQ-002 ')" -gt 0 ] || { echo "$output"; false; }
    [ "$(line_of '^fix MISSING-TEST: ')" -gt "$(last_line_of '^MISSING-TEST ')" ] \
        || { echo "$output"; false; }
    [ "$(line_of '^checked: ')" -gt "$(line_of '^fix MISSING-TEST: ')" ] \
        || { echo "$output"; false; }
}
