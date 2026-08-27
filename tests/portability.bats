# Portability of the check scripts across awk implementations.
#
# The toolkit's header comments record measurements on gawk 5.3.2, mawk and
# busybox awk. macOS's awk — BWK, "awk version 20200816", the one that ships
# with the OS and the only awk on a stock box — is not in that set, and it is
# the strictest of the four about what may appear in a `-v` assignment. Every
# test here runs the real scripts under a stub that reproduces that strictness
# on any platform, so a Linux developer sees what a macOS user sees.

load helpers

setup() { make_fixture_repo; }

# The stub is the instrument every other test in this file depends on. An
# instrument that never fires reports a clean bill of health for a broken
# tree, so it is calibrated first, in both directions.

@test "strict awk: rejects a literal newline in a -v assignment" {
    # verifies: PR-v3j4s2
    bin=$(make_strict_awk)
    run env PATH="$bin:$PATH" awk -v kws='a:
b:' 'BEGIN { print "ran" }' /dev/null
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    [[ "$output" == *"newline in string"* ]] || { echo "$output"; false; }
}

@test "strict awk: accepts the same list flattened to spaces" {
    # verifies: PR-v3j4s2
    # The fix's premise: `split()` under the default FS splits on runs of
    # space, tab and newline alike, so the flattened list is the same list.
    bin=$(make_strict_awk)
    run env PATH="$bin:$PATH" awk -v kws='a: b:' \
        'BEGIN { n = split(kws, K); print "fields:", n, K[1], K[2] }' /dev/null
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [ "$output" = "fields: 2 a: b:" ] || { echo "$output"; false; }
}

@test "strict awk: passes every other invocation through to the real awk" {
    # verifies: PR-v3j4s2
    bin=$(make_strict_awk)
    run env PATH="$bin:$PATH" awk -v k=plain 'BEGIN { print k }' /dev/null
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = plain ]
}

# --- PR-v3j4s2 --------------------------------------------------------------

@test "check-review: runs under an awk that refuses a newline in -v" {
    # verifies: PR-v3j4s2
    # `scan_record` interpolated GR_RECORD_FIELDS — two literal newlines —
    # straight into `awk -v kws=`. On macOS that is exit 2 before the program
    # runs, so the gate never read a record: merge-change step 6c could not
    # run on that platform at all. Not a false pass, but invisible on gawk,
    # where the identical call succeeds.
    make_change_worktree my-change
    write_record mine my-change
    bin=$(make_strict_awk)
    PATH="$bin:$PATH" run sh .guardrails/scripts/check-review.sh
    [[ "$output" != *"newline in string"* ]] || { echo "$output"; false; }
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
}

@test "check-review: still names every missing field under a strict awk" {
    # verifies: PR-v3j4s2
    # The regression above would also be satisfied by a scan that ran and read
    # nothing. The flattened list must still split into all four keywords, so
    # a record missing exactly one still draws exactly one INCOMPLETE-RECORD
    # naming that field — and the branch: keyword must survive the flattening
    # too, or the record would not be selected at all.
    make_change_worktree my-change
    mkdir -p docs/verification
    cat > docs/verification/2026-01-01-mine.md <<'EOF'
# Verification — mine

branch: my-change
reviewer: an independent subagent
reproduced: yes, against the shipped scripts, before any change
EOF
    bin=$(make_strict_awk)
    PATH="$bin:$PATH" run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"INCOMPLETE-RECORD docs/verification/2026-01-01-mine.md (no verdict:)"* ]] \
        || { echo "$output"; false; }
    [ "$(printf '%s\n' "$output" | grep -c INCOMPLETE-RECORD)" -eq 1 ] \
        || { echo "$output"; false; }
    [[ "$output" != *"MISSING-RECORD"* ]] || { echo "$output"; false; }
}

# --- the class, not the instance --------------------------------------------

@test "every check script runs clean under an awk that refuses a newline in -v" {
    # verifies: PR-v3j4s2
    # The defect class is "a value carrying a literal newline reaches awk -v",
    # and check-review.sh was one instance of it. Nothing stops the next one,
    # so every script that reaches an awk gate is swept here rather than only
    # the one that was reported. Each is given work to do and asserted at
    # exit 0: a script that died on its config before reaching any awk would
    # pass a message-only assertion while proving nothing.
    #
    # Covered: check-ids.sh, check-trace.sh, check-review.sh, finalize-docs.sh,
    # new-id.sh — every script in scripts/ that calls awk. check-signing.sh
    # calls none and is deliberately absent.
    cat > docs/requirements/0001-01-01-base.md <<'EOF'
# SRS

**REQ-001**: The system shall limit the dose. (implements: RC-001)
EOF
    cat > docs/risk/0001-01-01-base.md <<'EOF'
# Risk Management File

**HAZ-001**: Overdose delivered to patient.

**RC-001**: Software limits dose to configured maximum. mitigates: HAZ-001
EOF
    cat > docs/architecture/0001-01-01-base.md <<'EOF'
# Software Architecture

**SDD-001**: Dose limiter module. traces: REQ-001

**LLR-001**: Clamp requested dose to the configured maximum. satisfies: REQ-001
EOF
    printf '# verifies: LLR-001\ntrue\n' > tests/test_a.sh
    write_pr PR-002 open "$(days_ago 2)"
    commit_all traced
    make_change_worktree my-change
    write_record mine my-change
    printf '\n**REQ-a3k9z2**: The system shall log the dose. (implements: RC-001)\n' \
        > docs/requirements/DRAFT-my-change-dose-logging.md
    printf '# verifies: REQ-a3k9z2\ntrue\n' > tests/test_b.sh
    commit_all draft

    # Each script with the arguments that make it do its job on this tree:
    # check-ids must tolerate the draft filename that is still a draft, and
    # finalize-docs must not actually rename it out from under the sweep.
    bin=$(make_strict_awk)
    swept=0
    while IFS='|' read -r script arg; do
        PATH="$bin:$PATH" run sh ".guardrails/scripts/$script" ${arg:+"$arg"}
        [[ "$output" != *"newline in string"* ]] \
            || { echo "$script hit the -v newline: $output"; false; }
        [ "$status" -eq 0 ] || { echo "$script exited $status: $output"; false; }
        swept=$((swept + 1))
    done <<'EOF'
check-ids.sh|--allow-draft-files
check-trace.sh|
check-review.sh|
finalize-docs.sh|--dry-run
new-id.sh|PR
EOF
    # A loop over an empty list passes every assertion inside it. Say how many
    # scripts were actually run, so a mangled here-document is a failure and
    # not a clean sweep of nothing.
    [ "$swept" -eq 5 ] || { echo "swept $swept scripts, expected 5"; false; }
}

# --- PR-yd2sft --------------------------------------------------------------

@test "bsd date stub: refuses -d and a doubled sign in -v" {
    # verifies: PR-yd2sft
    # Calibrated like the awk stub, and for the same reason: on macOS the real
    # date already behaves this way, so an instrument that never fired would be
    # invisible here and useless on the GNU box it exists for.
    bin=$(make_bsd_date)
    run env PATH="$bin:$PATH" date -d "3 days ago" +%Y-%m-%d
    [ "$status" -ne 0 ] || { echo "-d was accepted: $output"; false; }
    run env PATH="$bin:$PATH" date -v--1d +%Y-%m-%d
    [ "$status" -ne 0 ] || { echo "-v--1d was accepted: $output"; false; }
    run env PATH="$bin:$PATH" date -v-3d +%Y-%m-%d
    [ "$status" -eq 0 ] || { echo "a valid adjustment was refused: $output"; false; }
    run env PATH="$bin:$PATH" date +%Y-%m-%d
    [ "$status" -eq 0 ] || { echo "a plain call was refused: $output"; false; }
}

@test "days_ago produces a date in the future as well as one in the past" {
    # verifies: PR-yd2sft
    # `days_ago -1` is how the two clock-skew tests build tomorrow. GNU date
    # takes `-d "-1 days ago"` and answers; BSD date is handed `-v--1d` and
    # refuses, so on macOS the helper returned the empty string and both tests
    # asserted against a PR item with no `opened:` at all — failing several
    # screens away from the cause, on a message about an incomplete item.
    #
    # Run under a stub `date` that refuses `-d` and rejects a doubled sign in
    # `-v`, so this reddens on a GNU box too. Without it the test could only
    # fail on macOS — on the platform where the defect escaped, it was green,
    # which is the same blind spot make_strict_awk exists to remove for awk.
    bin=$(make_bsd_date)
    PATH="$bin:$PATH"

    # ISO dates compare correctly as strings, which is why no date arithmetic
    # is needed here to check date arithmetic.
    today=$(date +%Y-%m-%d)
    [ "$(days_ago 0)" = "$today" ] || { echo "days_ago 0 = $(days_ago 0)"; false; }
    [[ "$(days_ago 3)" < "$today" ]] || { echo "days_ago 3 = $(days_ago 3)"; false; }
    [[ "$(days_ago -1)" > "$today" ]] || { echo "days_ago -1 = $(days_ago -1)"; false; }
    [[ "$(days_ago -2)" > "$(days_ago -1)" ]] \
        || { echo "days_ago -2 = $(days_ago -2), -1 = $(days_ago -1)"; false; }
}

# --- PR-44z762 --------------------------------------------------------------

@test "no in-place sed in the repository omits its backup suffix" {
    # verifies: PR-44z762
    # `AGENTS.md` already requires `sed -i.bak` (then remove the `.bak`),
    # because GNU sed takes the suffix as an optional argument glued to the
    # flag and BSD sed takes it as a mandatory separate one — so the bare form
    # silently eats the next word as the suffix and then has no script.
    #
    # The rule was written down and never enforced, and calls in tests/lib.bats
    # drifted out of line with it, costing the shipped config template its
    # schema check on every macOS box. A rule with a test is a rule; a rule in
    # prose is a hope.
    #
    # The pattern matches the DEFECTIVE spelling only — the flag followed by
    # whitespace — so this file, which must name it to explain it, does not
    # match itself.
    root=$(cd "$BATS_TEST_DIRNAME/.." && pwd)
    pat='sed -i[[:space:]]'
    paths="scripts tests templates skills install.sh"

    # `grep -r`, not `git grep`: tests/evidence.sh runs this suite from a copy
    # in a mktemp directory with no `.git` and only part of the tree in it.
    # There `git grep` exits 128, and an exit-code assertion reads a missing
    # repository as a clean toolkit. A partial copy has nothing to lint, so say
    # so — but only a partial copy may say it, or a directory renamed in the
    # real repository would silently turn this check off.
    if git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
        for p in $paths; do
            [ -e "$root/$p" ] \
                || { echo "search path gone from the repository: $p"; false; }
        done
    else
        for p in $paths; do
            [ -e "$root/$p" ] \
                || skip "not a full checkout ($p absent); nothing to lint here"
        done
    fi

    # Positive control. A pattern that stopped matching the defect it names
    # would report a clean toolkit forever, and the exit code alone cannot tell
    # "found nothing" from "looked for nothing" — measured: `git grep` returns
    # 1, not 128, for a pathspec naming no such directory, so the exit code
    # never carried the meaning the earlier version of this test claimed.
    # Built with printf so this file does not contain the spelling it hunts.
    printf 'sed -%s %s\n' i "'s/a/b/' f" > "$BATS_TEST_TMPDIR/control.sh"
    grep -qE "$pat" "$BATS_TEST_TMPDIR/control.sh" \
        || { echo "the pattern no longer matches the defect it names"; false; }

    found=$(cd "$root" && grep -rnE --exclude-dir=.bats-core "$pat" $paths 2>/dev/null || true)
    [ -z "$found" ] || { echo "in-place sed with no suffix:"; echo "$found"; false; }
}
