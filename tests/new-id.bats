load helpers

setup() { make_fixture_repo; }

# The token pattern, anchored, as the library defines it — never spelled out
# here, or this file would pin a second opinion about what an ID is.
token_re() {
    sh -c '. .guardrails/scripts/lib.sh && printf "%s" "^REQ-($GR_ID_TOKEN)$"'
}

@test "new-id: mints one ID of the requested prefix" {
    run .guardrails/scripts/new-id.sh REQ
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 1 ]
    printf '%s\n' "${lines[0]}" | grep -qE "$(token_re)"
}

@test "new-id: mints the requested count, all distinct" {
    run .guardrails/scripts/new-id.sh REQ 20
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 20 ]
    [ "$(printf '%s\n' "${lines[@]}" | sort -u | wc -l)" -eq 20 ]
    for l in "${lines[@]}"; do
        printf '%s\n' "$l" | grep -qE "$(token_re)"
    done
}

@test "new-id: every minted token carries a digit" {
    # The digit is what keeps REQ-argued from being an ID. A generator that
    # drew from the full alphabet without the redraw would pass every other
    # test in this file: one token in six has no digit at all.
    run .guardrails/scripts/new-id.sh REQ 60
    [ "$status" -eq 0 ]
    for l in "${lines[@]}"; do
        printf '%s\n' "${l#REQ-}" | grep -q '[23456789]'
    done
}

@test "new-id: never draws an ambiguous character" {
    run .guardrails/scripts/new-id.sh REQ 60
    [ "$status" -eq 0 ]
    for l in "${lines[@]}"; do
        printf '%s\n' "${l#REQ-}" | grep -qv '[01oliOLI]'
    done
}

@test "new-id: successive runs do not repeat themselves" {
    # A generator seeded from the pid or the second would give one repo one
    # token per second, and two agents in the same second the same one.
    a=$(.guardrails/scripts/new-id.sh REQ)
    b=$(.guardrails/scripts/new-id.sh REQ)
    [ "$a" != "$b" ]
}

@test "new-id: refuses a prefix that is not declared in id_prefixes" {
    run .guardrails/scripts/new-id.sh XYZ
    [ "$status" -eq 2 ]
    [[ "$output" == *"not declared in id_prefixes"* ]]
}

@test "new-id: refuses a count that is not a positive integer" {
    for n in 0 -3 two 1x; do
        run .guardrails/scripts/new-id.sh REQ "$n"
        [ "$status" -eq 2 ]
    done
}

@test "new-id: refuses an unknown argument rather than ignoring it" {
    run .guardrails/scripts/new-id.sh REQ 2 --wat
    [ "$status" -eq 2 ]
}

@test "new-id: validates the config before minting" {
    printf 'stritc_paths:\n  - src\n' >> .guardrails/config.yaml
    run .guardrails/scripts/new-id.sh REQ
    [ "$status" -eq 2 ]
    [[ "$output" == *"unknown config key"* ]]
}

@test "new-id: never mints an ID already present in the tree" {
    # GR_ID_FORCE_TOKEN wedges the draw to one value so the collision path is
    # reachable without a 10^8 loop.
    printf '**REQ-a3k9z2**: taken\n' > docs/requirements/2026-01-01-x.md
    commit_all
    GR_ID_FORCE_TOKEN=a3k9z2 run .guardrails/scripts/new-id.sh REQ
    [ "$status" -eq 2 ]
    [[ "$output" == *"could not mint"* ]]
}

@test "new-id: sees an UNTRACKED file when checking for collisions" {
    # The file the author is editing right now is the likeliest place for the
    # ID they just minted to be. A tracked-only scan would hand it out twice.
    printf '**REQ-a3k9z2**: taken, not yet committed\n' > docs/requirements/2026-01-01-x.md
    GR_ID_FORCE_TOKEN=a3k9z2 run .guardrails/scripts/new-id.sh REQ
    [ "$status" -eq 2 ]
    [[ "$output" == *"could not mint"* ]]
}

@test "new-id: a reference, not just a definition, blocks the token" {
    printf '# verifies: REQ-a3k9z2\n' > tests/t.sh
    GR_ID_FORCE_TOKEN=a3k9z2 run .guardrails/scripts/new-id.sh REQ
    [ "$status" -eq 2 ]
}

@test "new-id: a token taken under one prefix is free under another" {
    printf '**REQ-a3k9z2**: taken\n' > docs/requirements/2026-01-01-x.md
    GR_ID_FORCE_TOKEN=a3k9z2 run .guardrails/scripts/new-id.sh HAZ
    [ "$status" -eq 0 ]
    [ "$output" = "HAZ-a3k9z2" ]
}

@test "new-id: does not hand out the same token twice within one run" {
    GR_ID_FORCE_TOKEN=a3k9z2 run .guardrails/scripts/new-id.sh REQ 2
    [ "$status" -eq 2 ]
}

@test "new-id: refuses to invent an ID when there is no entropy source" {
    # The tempting fallback — $$ and the clock — is a predictable generator
    # wearing a random one's clothes, and two agents starting together would
    # collide by construction. Fail instead.
    GR_ID_URANDOM=/nonexistent run .guardrails/scripts/new-id.sh REQ
    [ "$status" -eq 2 ]
    # The [ -r ] message specifically, not just the word "entropy". Both refusal
    # paths in this script mention entropy, so the loose assertion left the
    # guard undetectable: deleting it and letting the draw fail instead still
    # exits 2 with a message that matches. Mutation M13 reddened nothing.
    [[ "$output" == *"no entropy source at /nonexistent"* ]] || { echo "$output"; false; }
}

@test "new-id: an ID it mints is one check-ids accepts as a definition" {
    id=$(.guardrails/scripts/new-id.sh REQ)
    printf '**%s**: a real requirement\n' "$id" > docs/requirements/2026-01-01-x.md
    printf '# verifies: %s\n' "$id" > tests/t.sh
    commit_all
    run .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"MALFORMED-ID"* ]]
}

@test "new-id: the collision scan follows GR_SCAN_EXCLUDE" {
    # The one call site in this script, and nothing else in the suite
    # distinguishes it from a hand-typed pathspec: mutation M36 gave it its own
    # literal and reddened nothing. Move the exclusion instead, and require the
    # scan to follow — a token that is invisible while the tooling directory is
    # excluded must be seen once it is not.
    printf '**REQ-a3k9z2**: an item inside the excluded tooling dir.\n' \
        > .guardrails/scripts/notes.md
    commit_all tooling-id

    GR_ID_FORCE_TOKEN=a3k9z2 run .guardrails/scripts/new-id.sh REQ
    [ "$status" -eq 0 ] || { echo "the excluded dir was scanned: $output"; false; }
    [ "$output" = "REQ-a3k9z2" ]

    printf "\nGR_SCAN_EXCLUDE=':(exclude)src'\n" >> .guardrails/scripts/lib.sh

    GR_ID_FORCE_TOKEN=a3k9z2 run .guardrails/scripts/new-id.sh REQ
    [ "$status" -eq 2 ] || { echo "the scan kept its own pathspec: $output"; false; }
}

@test "new-id: an entropy source that yields nothing fails instead of hanging" {
    # Independent review, S1. /dev/zero is READABLE, so the [ -r ] guard passes,
    # and `tr < src | dd count=6` waited forever for six usable bytes that
    # never came. The bounded read fixes the sources that RETURN without
    # yielding anything usable; a source that blocks instead is a separate
    # case — a FIFO is refused outright (below), and a starved /dev/random
    # still waits, which is recorded as a gap rather than claimed fixed.
    run timeout 30 env GR_ID_URANDOM=/dev/zero .guardrails/scripts/new-id.sh REQ
    [ "$status" -ne 124 ] || { echo "new-id.sh hung"; false; }
    [ "$status" -eq 2 ]
    [[ "$output" == *"no usable randomness"* ]] || { echo "$output"; false; }
}

@test "new-id: the give-up message distinguishes no randomness from no free token" {
    # Independent review, S2. Both cases are "100 attempts" from inside the
    # loop, and the message asserted the second for either.
    run timeout 30 env GR_ID_URANDOM=/dev/null .guardrails/scripts/new-id.sh REQ
    [ "$status" -eq 2 ]
    [[ "$output" == *"no usable randomness"* ]] || { echo "$output"; false; }
    [[ "$output" != *"already present in the tree"* ]] || { echo "$output"; false; }

    printf '**REQ-a3k9z2**: taken\n' > docs/requirements/2026-01-01-x.md
    GR_ID_FORCE_TOKEN=a3k9z2 run .guardrails/scripts/new-id.sh REQ
    [ "$status" -eq 2 ]
    [[ "$output" == *"already present in the tree"* ]] || { echo "$output"; false; }
    [[ "$output" != *"no usable randomness"* ]] || { echo "$output"; false; }
}

@test "new-id: the alphabet is derived from the library, not retyped here" {
    # Independent review, S4. The script's own comment names the hazard — "the
    # generator would drift from the matcher without a single test going red" —
    # and nothing guarded it: replacing both derivations with hand-typed but
    # IDENTICAL literals left the whole suite green. Narrow the library's
    # classes and require the generator to follow.
    printf "\nGR_ID_ANY='[a3]'\nGR_ID_DIGIT='[3]'\n" >> .guardrails/scripts/lib.sh

    run .guardrails/scripts/new-id.sh REQ 5
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    for l in "${lines[@]}"; do
        printf '%s\n' "$l" | grep -qE '^REQ-[a3]{6}$' \
            || { echo "generator kept its own alphabet: $l"; false; }
        printf '%s\n' "$l" | grep -q '3' || { echo "no digit: $l"; false; }
    done
}

@test "new-id: a FIFO is refused rather than read" {
    # The other blocking case, and the one worth refusing: the shell blocks in
    # open() on a FIFO with no writer, before dd runs at all, so no amount of
    # bounding the read helps. Confirming review pass.
    mkfifo "$BATS_TEST_TMPDIR/fifo"
    run timeout 20 env GR_ID_URANDOM="$BATS_TEST_TMPDIR/fifo" \
        .guardrails/scripts/new-id.sh REQ
    [ "$status" -ne 124 ] || { echo "new-id.sh blocked on the FIFO"; false; }
    [ "$status" -eq 2 ]
    [[ "$output" == *"is a FIFO"* ]] || { echo "$output"; false; }
}

@test "new-id: new-id-infers-unit-from-cwd — minting inside a unit needs no ceremony" {
    make_units_fixture
    cd apps/pump/src
    run sh ../../../.guardrails/scripts/new-id.sh REQ
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^REQ-[abcdefghjkmnpqrstuvwxyz23456789]{6}$ ]]
}

@test "new-id: new-id-outside-unit-requires-flag — at the root it refuses and lists the units" {
    make_units_fixture
    run sh .guardrails/scripts/new-id.sh REQ
    [ "$status" -eq 2 ]
    [[ "$output" == *"platform/hal"* ]] || false
    [[ "$output" == *"apps/pump"* ]] || false
    [[ "$output" == *"--unit"* ]]
}

@test "new-id: --unit selects explicitly, from anywhere" {
    make_units_fixture
    run sh .guardrails/scripts/new-id.sh --unit platform/hal REQ
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^REQ- ]] || false
    run sh .guardrails/scripts/new-id.sh --unit no/such REQ
    [ "$status" -eq 2 ]
}

@test "new-id: --unit disagreeing with an explicit GR_CONFIG is exit 2, never a guess" {
    make_units_fixture
    GR_CONFIG=apps/pump/.guardrails/config.yaml \
        run sh .guardrails/scripts/new-id.sh --unit platform/hal REQ
    [ "$status" -eq 2 ]
    [[ "$output" == *"disagree"* ]]
}

@test "new-id: an explicit unit GR_CONFIG alone still works (the engagement rule)" {
    make_units_fixture
    GR_CONFIG=apps/pump/.guardrails/config.yaml run sh .guardrails/scripts/new-id.sh REQ
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^REQ- ]]
}

@test "new-id: the mint collision scan stays tree-wide under scope" {
    make_units_fixture
    # wedge the draw to an ID defined in the OTHER unit: the scan must see it
    run sh -c 'cd apps/pump && GR_ID_FORCE_TOKEN=h4m2p9 sh ../../.guardrails/scripts/new-id.sh REQ'
    [ "$status" -eq 2 ]
    [[ "$output" == *"100 attempts"* ]]
}

# verifies: engagement rule — --unit is meaningless without a manifest (finding-6c)
@test "new-id: --unit in a single-unit repository is exit 2, never a silent guess" {
    run sh .guardrails/scripts/new-id.sh --unit apps/pump REQ
    [ "$status" -eq 2 ]
    [[ "$output" == *"single-unit repository"* ]]
}
