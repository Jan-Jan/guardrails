#!/usr/bin/env bats

# Every assertion below is written `... || { echo "$output"; false; }`, and the
# form is not decoration. Under bash 3.2 — the /bin/bash every macOS developer
# here invokes — errexit and the ERR trap skip a bare `[[ ... ]]`, so a failing
# `[[ ]]` that is not the final command of a test body is inert: bats reports
# the test green and never mentions it. Only the trailing `false` produces a
# status bats acts on. A test asserting four things through bare `[[ ]]` is
# therefore asserting one thing, the last, on this platform alone — precisely
# the false green these fixtures exist to detect.

setup() { root=$(cd "$BATS_TEST_DIRNAME/.." && pwd); }

@test "mutations: every committed mutation applies or declares itself retired" {
    run "$root/tests/mutate.sh"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "mutations: a mutation whose anchor no longer matches is reported" {
    # Positive control. A runner that stopped detecting the defect it names
    # would report a healthy suite forever, and an exit code alone cannot
    # distinguish "found nothing" from "looked for nothing".
    d="$BATS_TEST_TMPDIR/2026-01-01-control.mutations"
    mkdir -p "$d"
    cat > "$d/M01.sh" <<'EOS'
#!/bin/sh
# describes: a line that is in no file in this repository
python3 - <<'PY'
s = open('scripts/lib.sh').read()
old = 'this string is not in lib.sh and never was'
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
PY
EOS
    run "$root/tests/mutate.sh" "$d"
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    # The reported REASON, not the status, separates "the mutation was executed
    # and its anchor did not match" from "the mutation was never launched at
    # all". A path defect once gave every fixture mutation exit 127, and a
    # control asserting only a status and a filename stayed green throughout:
    # exit 127 satisfies both. The fixture's own assertion is what must appear.
    [[ "$output" == *"0 applied, 0 retired, 1 unusable"* ]] \
        || { echo "$output"; false; }
    [[ "$output" == *"M01.sh: exit 1: "* ]] || { echo "$output"; false; }
    [[ "$output" == *"AssertionError"* ]] || { echo "$output"; false; }
    [[ "$output" != *"exit 127"* ]] || { echo "$output"; false; }
    [[ "$output" != *"M01.sh: exit 2: "* ]] || { echo "$output"; false; }
}

@test "mutations: a mutation that exits 0 having changed nothing is reported" {
    # The eight silent failures are this shape, and no exit code describes them.
    # This is the arm that makes the tree checksum critical rather than
    # decorative, so it must fail if the checksum is ever removed.
    d="$BATS_TEST_TMPDIR/2026-01-01-silent.mutations"
    mkdir -p "$d"
    cat > "$d/M01.sh" <<'EOS'
#!/bin/sh
# describes: a replace with no assertion, rewriting the file identically
python3 - <<'PY'
s = open('scripts/lib.sh').read()
open('scripts/lib.sh', 'w').write(s.replace('not present in lib.sh', 'x'))
PY
EOS
    run "$root/tests/mutate.sh" "$d"
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    # Named verbatim. With the before/after comparison gone this mutation is
    # counted as applied and the runner reports a clean suite, so the summary
    # line is asserted beside the reason: either one going missing is the
    # checksum having been removed.
    [[ "$output" == *"M01.sh: exit 0 but the tree is unchanged"* ]] \
        || { echo "$output"; false; }
    [[ "$output" == *"0 applied, 0 retired, 1 unusable"* ]] \
        || { echo "$output"; false; }
}

@test "mutations: a retired script is counted, not executed" {
    d="$BATS_TEST_TMPDIR/2026-01-01-retired.mutations"
    mkdir -p "$d"
    cat > "$d/M01.sh" <<'EOS'
#!/bin/sh
# describes: a behaviour that no longer exists
# retired: the behaviour was removed at deadbeef
exit 77
EOS
    run "$root/tests/mutate.sh" "$d"
    # The fixture exits 77 so that executing it is visible. A retirement taken
    # from the exit code rather than from the declared `# retired:` line would
    # print an unusable line naming that status and that filename; the absence
    # of both is the evidence that the script was never launched, and that is
    # the claim in this test's name, so it is asserted ahead of the count.
    [[ "$output" != *"77"* ]] || { echo "$output"; false; }
    [[ "$output" != *"M01.sh"* ]] || { echo "$output"; false; }
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"0 applied, 1 retired, 0 unusable"* ]] \
        || { echo "$output"; false; }
}

@test "mutations: a directory containing no mutation scripts is an error, not a pass" {
    mkdir -p "$BATS_TEST_TMPDIR/empty.mutations"
    run "$root/tests/mutate.sh" "$BATS_TEST_TMPDIR/empty.mutations"
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    # Exit 2 is also how an absent python3 and a non-repository are reported,
    # and either would satisfy a status-only assertion while the reach guard
    # itself was gone. The runner's own message is asserted instead.
    [[ "$output" == *"no mutation scripts under"* ]] || { echo "$output"; false; }
    [[ "$output" == *"empty.mutations"* ]] || { echo "$output"; false; }
}

@test "mutations: the retirement count is pinned, so one more is a visible edit" {
    # A `# retired:` declaration is believed, by design: D2 makes retirement
    # declared rather than inferred, because inferring it would let every newly
    # broken anchor retire itself. The cost is that the declaration is also the
    # way to dodge the gate — break an anchor, declare it retired, and
    # tests/mutate.sh exits 0. Demonstrated: a script whose anchor matches
    # nothing and which declares itself retired reports `0 applied, 1 retired,
    # 0 unusable`.
    #
    # Nothing here can tell a true retirement reason from a false one; that is
    # a judgement about the repository's history and it belongs to review. What
    # this pin does is make the dodge visible — a new retirement is an edit in
    # two places and appears in the diff as a changed expectation, which is the
    # same treatment tests/skills.bats gives its exemption list.
    #
    # Raising this number is legitimate whenever a behaviour genuinely goes
    # away. Raise it in the commit that retires the script, never separately.
    retired=$(grep -rlE '^# retired: ' "$root"/docs/verification/*.mutations/M*.sh | wc -l | tr -d ' ')
    [ "$retired" -eq 17 ] || {
        echo "the corpus declares $retired retired mutations, expected 17"
        echo "a new retirement is deliberate — raise this number in the same commit"
        grep -rlE '^# retired: ' "$root"/docs/verification/*.mutations/M*.sh
        false
    }
}

@test "mutations: a script without the M prefix is still read" {
    # The corpus is all M*.sh today, so a name glob looks sufficient and is not.
    # tests/portability.bats scans this same directory by mode as well as by
    # name, for the reason it records: a mutation that loses its suffix is still
    # run and still contains the defect. Measured before this arm existed — a
    # broken script named BROKEN99.sh in a live directory left the runner
    # reporting `167 applied, 0 unusable`, and portability.bats green.
    d="$BATS_TEST_TMPDIR/2026-01-01-naming.mutations"
    mkdir -p "$d"
    cat > "$d/BROKEN99.sh" <<'EOS2'
#!/bin/sh
# describes: a mutation whose name does not begin with M
python3 - <<'PY'
s = open('scripts/lib.sh').read()
old = 'this string is not in lib.sh and never was'
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
PY
EOS2
    run "$root/tests/mutate.sh" "$d"
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"BROKEN99.sh"* ]] || { echo "$output"; false; }
    [[ "$output" == *"AssertionError"* ]] || { echo "$output"; false; }
}
