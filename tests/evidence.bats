#!/usr/bin/env bats
# evidence.sh reads a test name from the source the way bats reports it.
#
# The fixture .bats content is written with printf, not a heredoc: a heredoc
# puts the test keyword at column one in this file, where evidence.sh counts it
# as a test of this suite and then reports a plan mismatch.
#
# The base commit contains a test with an escaped name, so the base list is read
# with the same unescape as the current one; otherwise that test is counted as
# new. The green test's name is single-quoted, so both quote forms are read.

load helpers

setup() {
    FIXTURE="$BATS_TEST_TMPDIR/evidence-repo"
    mkdir -p "$FIXTURE/tests" "$FIXTURE/scripts" "$BATS_TEST_TMPDIR/bin"
    cd "$FIXTURE"
    git init -q -b main --template=
    git config user.name test
    git config user.email test@example.com
    git config commit.gpgsign false
    cp "$BATS_TEST_DIRNAME/evidence.sh" tests/evidence.sh
    printf '#!/bin/sh\nexit 1\n' > scripts/probe.sh
    chmod 755 scripts/probe.sh
    printf '%s\n' \
        '@test "base test" {' \
        '    true' \
        '}' \
        '@test "base \\ escaped" {' \
        '    true' \
        '}' \
        > tests/probe.bats
    git add -A
    git commit -q -m base
    BASE_HASH=$(git rev-parse HEAD)

    printf '#!/bin/sh\nexit 0\n' > scripts/probe.sh
    printf '%s\n' \
        '@test '\''green \\001 \"quoted\" \$HOME \` name'\'' {' \
        '    true' \
        '}' \
        '@test "red \\ name" {' \
        '    sh "$BATS_TEST_DIRNAME/../scripts/probe.sh"' \
        '}' \
        >> tests/probe.bats

    # outside_bats: the enclosing run's PATH holds bats' internal entry point
    # (PR-2nxadp).
    bats_path=$(outside_bats sh -c 'command -v bats' \
        || echo "$BATS_TEST_DIRNAME/.bats-core/bin/bats")
    ln -s "$bats_path" "$BATS_TEST_TMPDIR/bin/bats"
    PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

# run_evidence — evidence.sh against the base commit, which must exit 0.
run_evidence() {
    run sh tests/evidence.sh "$BASE_HASH"
    [ "$status" -eq 0 ] || { printf 'status %s\n%s\n' "$status" "$output"; return 1; }
}

# verifies: PR-9aaart
@test "evidence: a test name with a backslash escape is matched to the name bats reports" {
    run_evidence
    output_has "- New or renamed since \`$BASE_HASH\`: **2**."
    output_has "- Of those, **1** go red when run against \`$BASE_HASH\`'s scripts."
    output_has '  - `green \001 "quoted" $HOME ` name`'
}

# verifies: PR-9aaart
@test "evidence: a new test whose escaped name passes on the base is listed as unable to go red" {
    run_evidence
    output_has '**1** cannot go red'
    output_lacks '`red'
    green_list=$(printf '%s\n' "$output" | grep '^  - `')
    [ "$green_list" = '  - `green \001 "quoted" $HOME ` name`' ] \
        || { printf 'green list:\n%s\n' "$green_list"; return 1; }
}
