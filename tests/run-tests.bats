# tests/run-tests.sh: what the runner hands to bats.

load helpers

# A stub bats that prints each argument it receives on its own line.
make_stub_bats() {
    stub_dir="$BATS_TEST_TMPDIR/stub-bin"
    mkdir -p "$stub_dir"
    printf '#!/bin/sh\nfor argument in "$@"; do printf "%%s\\n" "$argument"; done\n' \
        > "$stub_dir/bats"
    chmod +x "$stub_dir/bats"
}

# link_tool COMMAND: the host's own COMMAND, linked into the tools directory.
link_tool() {
    ln -s "$(command -v "$1")" "$tools_dir/$1"
}

# The run's PATH is the stub directory plus a tools directory that links only
# the commands run-tests.sh needs, sh among them, which runs
# tests/fingerprint-tree.sh. A system directory such as /usr/bin would
# also hold the host's own bats and parallel (Debian's parallel package
# installs /usr/bin/parallel), and either would change what the runner does.
# getconf and sysctl are linked only by a test that wants the host's answer.
make_tools_dir() {
    tools_dir="$BATS_TEST_TMPDIR/tools"
    mkdir -p "$tools_dir"
    link_tool dirname
    link_tool sh
}

runner="$BATS_TEST_DIRNAME/run-tests.sh"

setup() {
    make_stub_bats
    make_tools_dir
    shell_path=$(command -v sh)
    named_file="$BATS_TEST_TMPDIR/skills.bats"
    : > "$named_file"
}

# make_stub COMMAND BODY: a stub COMMAND in the stub directory that runs the
# shell line BODY.
make_stub() {
    printf '#!/bin/sh\n%s\n' "$2" > "$stub_dir/$1"
    chmod +x "$stub_dir/$1"
}

# make_gnu_parallel_stub: a stub parallel that answers --version as GNU
# parallel does.
make_gnu_parallel_stub() {
    make_stub parallel '[ "$1" = --version ] && echo "GNU parallel 20260822"; exit 0'
}

# run_runner ARGUMENT...: runs run-tests.sh with ARGUMENTs and the stub and
# tools directories as the whole PATH. RUN_TESTS_JOBS is unset unless the
# caller sets runner_jobs, which becomes its value. The runner's standard
# error goes to runner_stderr_file, $BATS_TEST_TMPDIR/runner-stderr unless the
# caller names another, and never into $output: the runner always writes a
# run-tests: line there, and $output must be the stub bats's arguments alone.
# Every test runs the runner through this, so neither the host's parallel nor
# the caller's RUN_TESTS_JOBS reaches the run.
run_runner() {
    local settings=(-u RUN_TESTS_JOBS)
    if [ -n "${runner_jobs+set}" ]; then
        settings+=("RUN_TESTS_JOBS=$runner_jobs")
    fi
    settings+=("PATH=$stub_dir:$tools_dir")
    runner_stderr_file=${runner_stderr_file:-$BATS_TEST_TMPDIR/runner-stderr}
    run sh -c 'stderr_file=$1; shift; "$@" 2>"$stderr_file"' \
        run-tests "$runner_stderr_file" \
        env "${settings[@]}" "$shell_path" "$runner" "$@"
}

# copy_runner DIRECTORY: copies the runner and tests/fingerprint-tree.sh, which
# it calls, into DIRECTORY.
copy_runner() {
    cp "$BATS_TEST_DIRNAME/run-tests.sh" "$1/run-tests.sh"
    cp "$BATS_TEST_DIRNAME/fingerprint-tree.sh" "$1/fingerprint-tree.sh"
}

# init_checkout: a git repository at $BATS_TEST_TMPDIR/checkout, with no
# commit yet, holding a copy of the runner and its fingerprint helper in
# tests/ and an empty tests/a.bats for the runner to pass on. The runner
# fingerprints the tree it lives in, so a test of that must run a copy in a
# repository it controls, not the guardrails checkout this suite runs in. git
# and the commands the fingerprint helper runs are linked into the tools
# directory, and runner is the copy.
init_checkout() {
    checkout="$BATS_TEST_TMPDIR/checkout"
    mkdir -p "$checkout/tests"
    copy_runner "$checkout/tests"
    : > "$checkout/tests/a.bats"
    git -C "$checkout" init -q
    git -C "$checkout" config user.name test
    git -C "$checkout" config user.email test@example.com
    git -C "$checkout" config commit.gpgsign false
    link_tool git
    link_tool mktemp
    link_tool rm
    link_tool cat
    runner="$checkout/tests/run-tests.sh"
}

# make_checkout: init_checkout, plus a README, all committed.
make_checkout() {
    init_checkout
    echo readme > "$checkout/README"
    commit_all fixture
}

# commit_all MESSAGE: commits everything in the checkout, its commit in
# checkout_commit.
commit_all() {
    git -C "$checkout" add -A
    git -C "$checkout" commit -q -m "$1"
    checkout_commit=$(git -C "$checkout" rev-parse HEAD)
}

# make_failing_git_stub PATTERN [MARKER]: a git on the stub PATH that runs the
# host's git, except that a call with an argument matching the case pattern
# PATTERN fails with "fatal: stub <argument> refused" on standard error;
# given MARKER, it fails only once the file MARKER exists.
make_failing_git_stub() {
    {
        printf '#!/bin/sh\nreal_git=%s\npattern=%s\nmarker=%s\n' \
            "'$(command -v git)'" "'$1'" "'${2:-}'"
        cat <<'EOF'
for argument in "$@"; do
    case $argument in
        ($pattern)
            if [ -z "$marker" ] || [ -e "$marker" ]; then
                echo "fatal: stub $argument refused" >&2
                exit 128
            fi
            ;;
    esac
done
exec "$real_git" "$@"
EOF
    } > "$stub_dir/git"
    chmod +x "$stub_dir/git"
}

# assert_stderr_has TEXT: the runner's standard error contains TEXT.
assert_stderr_has() {
    grep -q -F -e "$1" "$runner_stderr_file" || { cat "$runner_stderr_file"; false; }
}

# assert_stderr_lacks TEXT: the runner's standard error does not contain TEXT.
assert_stderr_lacks() {
    if grep -q -F -e "$1" "$runner_stderr_file"; then
        cat "$runner_stderr_file"
        false
    fi
}

# assert_commit_tested_unknown LINE: the runner ran the suite, said the
# commit it tests is unknown with the line LINE, and named no commit.
assert_commit_tested_unknown() {
    [ "$status" -eq 0 ] || { echo "status $status: $output"; false; }
    grep -qxF -e "$1" "$runner_stderr_file" || { cat "$runner_stderr_file"; false; }
    assert_stderr_lacks "run-tests: testing commit"
    assert_stderr_lacks "run-tests: the working tree differs"
}

# jobs_flag_count: how many lines of $output are a --jobs or -j flag.
jobs_flag_count() {
    printf '%s\n' "$output" | grep -c -e '^--jobs' -e '^-j$' || true
}

@test "run-tests: a named .bats file runs alone, without the whole suite" {
    # verifies: PR-r83mmd
    run_runner "$named_file"
    [ "$status" -eq 0 ]
    [ "$output" = "$named_file" ] || { echo "$output"; false; }
}

@test "run-tests: two named files run, and nothing else" {
    # verifies: PR-r83mmd
    first_file="$BATS_TEST_TMPDIR/a.bats"
    second_file="$BATS_TEST_TMPDIR/b.bats"
    : > "$first_file"
    : > "$second_file"
    run_runner "$first_file" "$second_file"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '%s\n%s' "$first_file" "$second_file")" ] || { echo "$output"; false; }
}

@test "run-tests: with no argument, every file in tests/ runs" {
    # verifies: PR-r83mmd
    run_runner
    [ "$status" -eq 0 ]
    expected=$(ls "$BATS_TEST_DIRNAME"/*.bats | wc -l | tr -d ' ')
    actual=$(printf '%s\n' "$output" | grep -c '\.bats$')
    [ "$actual" -eq "$expected" ] || { echo "expected $expected files, got $actual"; false; }
}

@test "run-tests: a named directory runs alone, without the whole suite" {
    # verifies: PR-r83mmd
    named_directory="$BATS_TEST_TMPDIR/some-tests"
    mkdir -p "$named_directory"
    run_runner "$named_directory"
    [ "$status" -eq 0 ]
    [ "$output" = "$named_directory" ] || { echo "$output"; false; }
}

@test "run-tests: an option alone still runs every file" {
    # verifies: PR-r83mmd
    run_runner --filter something
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "--filter" ]
    [ "${lines[1]}" = "something" ]
    printf '%s\n' "$output" | grep -q '/skills\.bats$' || { echo "$output"; false; }
}

@test "run-tests: an option value ending in .bats that names no file keeps the glob" {
    # verifies: PR-r83mmd
    run_runner --filter foo.bats
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "--filter" ]
    [ "${lines[1]}" = "foo.bats" ]
    printf '%s\n' "$output" | grep -q '/skills\.bats$' || { echo "$output"; false; }
}

@test "run-tests: RUN_TESTS_JOBS=1 runs serially, even with parallel installed" {
    # verifies: PR-hrx4vf
    make_gnu_parallel_stub
    runner_jobs=1 run_runner "$named_file"
    [ "$status" -eq 0 ]
    [ "$output" = "$named_file" ] || { echo "$output"; false; }
}

@test "run-tests: RUN_TESTS_JOBS=3 passes --jobs 3" {
    # verifies: PR-hrx4vf
    make_gnu_parallel_stub
    runner_jobs=3 run_runner "$named_file"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf -- '--jobs\n3\n%s' "$named_file")" ] || { echo "$output"; false; }
}

# assert_rejected VALUE: the run exited 2 with nothing on standard output and
# a message naming RUN_TESTS_JOBS and 'VALUE' on standard error.
assert_rejected() {
    [ "$status" -eq 2 ] || { echo "status $status: $output"; false; }
    [ -z "$output" ] || { echo "$output"; false; }
    grep -q "RUN_TESTS_JOBS" "$runner_stderr_file" || { cat "$runner_stderr_file"; false; }
    grep -q -e "'$1'" "$runner_stderr_file" || { cat "$runner_stderr_file"; false; }
}

@test "run-tests: RUN_TESTS_JOBS=0 exits 2 and names the variable and value" {
    # verifies: PR-hrx4vf
    runner_stderr_file="$BATS_TEST_TMPDIR/stderr"
    runner_jobs=0 run_runner "$named_file"
    assert_rejected 0
}

@test "run-tests: a non-numeric RUN_TESTS_JOBS exits 2 and names the variable and value" {
    # verifies: PR-hrx4vf
    runner_stderr_file="$BATS_TEST_TMPDIR/stderr"
    runner_jobs=abc run_runner "$named_file"
    assert_rejected abc
}

@test "run-tests: a negative RUN_TESTS_JOBS exits 2 and names the variable and value" {
    # verifies: PR-hrx4vf
    runner_stderr_file="$BATS_TEST_TMPDIR/stderr"
    runner_jobs=-2 run_runner "$named_file"
    assert_rejected -2
}

@test "run-tests: a RUN_TESTS_JOBS with trailing junk exits 2 and names the variable and value" {
    # verifies: PR-hrx4vf
    runner_stderr_file="$BATS_TEST_TMPDIR/stderr"
    runner_jobs=3x run_runner "$named_file"
    assert_rejected 3x
}

@test "run-tests: a RUN_TESTS_JOBS longer than 4 digits exits 2 and names the bound and value" {
    # verifies: PR-hrx4vf
    runner_stderr_file="$BATS_TEST_TMPDIR/stderr"
    runner_jobs=10000 run_runner "$named_file"
    assert_rejected 10000
    grep -q -e "RUN_TESTS_JOBS must be at most 9999, not '10000'" "$runner_stderr_file" ||
        { cat "$runner_stderr_file"; false; }
}

@test "run-tests: an empty RUN_TESTS_JOBS counts as unset" {
    # verifies: PR-hrx4vf
    make_gnu_parallel_stub
    link_tool getconf
    cpu_count=$(getconf _NPROCESSORS_ONLN)
    [ "$cpu_count" -gt 1 ] || skip "this host has one CPU"
    runner_jobs="" run_runner "$named_file"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf -- '--jobs\n%s\n%s' "$cpu_count" "$named_file")" ] || { echo "$output"; false; }
}

@test "run-tests: unset, with parallel installed, passes --jobs <CPU count>" {
    # verifies: PR-hrx4vf
    make_gnu_parallel_stub
    link_tool getconf
    cpu_count=$(getconf _NPROCESSORS_ONLN)
    [ "$cpu_count" -gt 1 ] || skip "this host has one CPU"
    run_runner "$named_file"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf -- '--jobs\n%s\n%s' "$cpu_count" "$named_file")" ] || { echo "$output"; false; }
}

@test "run-tests: a parallel that is not GNU parallel counts as absent, and the run is serial" {
    # verifies: PR-hrx4vf
    make_stub parallel 'echo "parallel from moreutils"; exit 0'
    make_stub getconf 'echo 4'
    run_runner "$named_file"
    [ "$status" -eq 0 ]
    [ "$output" = "$named_file" ] || { echo "$output"; false; }
}

@test "run-tests: the CPU count falls back to sysctl hw.ncpu when getconf fails" {
    # verifies: PR-hrx4vf
    make_gnu_parallel_stub
    make_stub getconf 'exit 1'
    make_stub sysctl '[ "$*" = "-n hw.ncpu" ] && echo 3'
    run_runner "$named_file"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf -- '--jobs\n3\n%s' "$named_file")" ] || { echo "$output"; false; }
}

@test "run-tests: a CPU count of 1 passes no --jobs" {
    # verifies: PR-hrx4vf
    make_gnu_parallel_stub
    make_stub getconf 'echo 1'
    run_runner "$named_file"
    [ "$status" -eq 0 ]
    [ "$output" = "$named_file" ] || { echo "$output"; false; }
}

@test "run-tests: a non-numeric CPU count counts as 1 and passes no --jobs" {
    # verifies: PR-hrx4vf
    make_gnu_parallel_stub
    make_stub getconf 'echo abc'
    run_runner "$named_file"
    [ "$status" -eq 0 ]
    [ "$output" = "$named_file" ] || { echo "$output"; false; }
}

@test "run-tests: with neither getconf nor sysctl answering, the count is 1 and no --jobs passes" {
    # verifies: PR-hrx4vf
    make_gnu_parallel_stub
    make_stub getconf 'exit 1'
    make_stub sysctl 'exit 1'
    run_runner "$named_file"
    [ "$status" -eq 0 ]
    [ "$output" = "$named_file" ] || { echo "$output"; false; }
}

@test "run-tests: a caller's own --jobs N passes through, and no second one is added" {
    # verifies: PR-hrx4vf
    make_gnu_parallel_stub
    runner_jobs=3 run_runner --jobs 5 "$named_file"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf -- '--jobs\n5\n%s' "$named_file")" ] || { echo "$output"; false; }
    [ "$(jobs_flag_count)" -eq 1 ]
}

@test "run-tests: a caller's own -j N passes through, and no second one is added" {
    # verifies: PR-hrx4vf
    make_gnu_parallel_stub
    runner_jobs=3 run_runner -j 5 "$named_file"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf -- '-j\n5\n%s' "$named_file")" ] || { echo "$output"; false; }
    [ "$(jobs_flag_count)" -eq 1 ]
}

@test "run-tests: unset, without parallel, runs serially" {
    # verifies: PR-hrx4vf
    run_runner "$named_file"
    [ "$status" -eq 0 ]
    [ "$output" = "$named_file" ] || { echo "$output"; false; }
}

@test "run-tests: --jobs goes before the caller's arguments, and the whole suite still runs" {
    # verifies: PR-hrx4vf
    make_gnu_parallel_stub
    runner_jobs=2 run_runner --filter something
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "--jobs" ]
    [ "${lines[1]}" = "2" ]
    [ "${lines[2]}" = "--filter" ]
    [ "${lines[3]}" = "something" ]
    printf '%s\n' "$output" | grep -q '/skills\.bats$' || { echo "$output"; false; }
}

@test "run-tests: an explicit RUN_TESTS_JOBS passes --jobs even without parallel" {
    # verifies: PR-hrx4vf
    runner_jobs=3 run_runner "$named_file"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf -- '--jobs\n3\n%s' "$named_file")" ] || { echo "$output"; false; }
}

@test "run-tests: a clean checkout names the commit it tests" {
    # verifies: PR-y8ff5p
    make_checkout
    run_runner
    [ "$status" -eq 0 ] || { echo "status $status: $output"; false; }
    assert_stderr_has "run-tests: testing commit $checkout_commit"
}

@test "run-tests: a modified checkout says the run tests no commit, and still runs" {
    # verifies: PR-y8ff5p
    make_checkout
    echo modified >> "$checkout/README"
    run_runner
    [ "$status" -eq 0 ] || { echo "status $status: $output"; false; }
    assert_stderr_has "run-tests: the working tree differs from commit $checkout_commit; this run tests no commit"
    printf '%s\n' "$output" | grep -qxF "$checkout/tests/a.bats" || { echo "$output"; false; }
}

@test "run-tests: a tree changed during the run fails the run, though every test passed" {
    # verifies: PR-y8ff5p
    make_checkout
    make_stub bats "echo changed >> '$checkout/README'; exit 0"
    run_runner
    [ "$status" -eq 1 ] || { echo "status $status: $output"; false; }
    assert_stderr_has "run-tests: the working tree changed during the run; this result describes no commit"
}

@test "run-tests: a commit made during the run fails the run" {
    # verifies: PR-y8ff5p
    make_checkout
    make_stub bats "git -C '$checkout' commit -q --allow-empty -m during; exit 0"
    run_runner
    [ "$status" -eq 1 ] || { echo "status $status: $output"; false; }
    [ "$(git -C "$checkout" rev-parse HEAD)" != "$checkout_commit" ] ||
        { echo "the stub bats made no commit"; false; }
    assert_stderr_has "run-tests: the working tree changed during the run; this result describes no commit"
}

@test "run-tests: a failing suite keeps its own status when the tree also changed" {
    # verifies: PR-y8ff5p
    make_checkout
    make_stub bats "echo changed >> '$checkout/README'; exit 3"
    run_runner
    [ "$status" -eq 3 ] || { echo "status $status: $output"; false; }
    assert_stderr_has "run-tests: the working tree changed during the run; this result describes no commit"
}

@test "run-tests: outside a git checkout the commit tested is unknown" {
    # verifies: PR-y8ff5p
    plain_dir="$BATS_TEST_TMPDIR/plain"
    mkdir -p "$plain_dir/tests"
    copy_runner "$plain_dir/tests"
    link_tool git
    runner="$plain_dir/tests/run-tests.sh"
    run_runner
    [ "$status" -eq 0 ] || { echo "status $status: $output"; false; }
    assert_stderr_has "run-tests: no git repository found; the commit tested is unknown"
}

@test "run-tests: a checkout whose HEAD names no commit says so, and the commit tested is unknown" {
    # verifies: PR-y8ff5p
    init_checkout
    run_runner
    assert_commit_tested_unknown "run-tests: HEAD names no commit; the commit tested is unknown"
}

@test "run-tests: a git that fails reading HEAD's tree is reported, and the commit tested is unknown" {
    # verifies: PR-y8ff5p
    make_checkout
    make_failing_git_stub '*^{tree}'
    run_runner
    assert_commit_tested_unknown "run-tests: the commit tested is unknown"
    assert_stderr_has "run-tests: git rev-parse $checkout_commit^{tree} failed: fatal: stub $checkout_commit^{tree} refused"
}

@test "run-tests: an untracked file makes the working tree differ from the commit" {
    # verifies: PR-y8ff5p
    make_checkout
    echo new > "$checkout/untracked"
    run_runner
    [ "$status" -eq 0 ] || { echo "status $status: $output"; false; }
    assert_stderr_has "run-tests: the working tree differs from commit $checkout_commit; this run tests no commit"
}

@test "run-tests: a tracked file that .gitignore matches leaves a clean checkout testing its commit" {
    # verifies: PR-y8ff5p
    make_checkout
    echo x.log > "$checkout/.gitignore"
    echo log > "$checkout/x.log"
    git -C "$checkout" add .gitignore
    git -C "$checkout" add -f x.log
    git -C "$checkout" commit -q -m "force-added ignored file"
    checkout_commit=$(git -C "$checkout" rev-parse HEAD)
    run_runner
    [ "$status" -eq 0 ] || { echo "status $status: $output"; false; }
    assert_stderr_has "run-tests: testing commit $checkout_commit"
}

@test "run-tests: an ignored untracked file leaves a clean checkout testing its commit" {
    # verifies: PR-y8ff5p
    make_checkout
    echo tests/.bats-core/ > "$checkout/.gitignore"
    commit_all "ignore bats-core"
    mkdir -p "$checkout/tests/.bats-core"
    echo copied > "$checkout/tests/.bats-core/x"
    run_runner
    [ "$status" -eq 0 ] || { echo "status $status: $output"; false; }
    assert_stderr_has "run-tests: testing commit $checkout_commit"
}

@test "run-tests: a runner nested in another repository's tree finds no checkout of its own" {
    # verifies: PR-y8ff5p
    make_checkout
    mkdir -p "$checkout/nested/tests"
    copy_runner "$checkout/nested/tests"
    commit_all nested
    runner="$checkout/nested/tests/run-tests.sh"
    run_runner
    assert_commit_tested_unknown "run-tests: no git repository found; the commit tested is unknown"
}

@test "run-tests: without git on PATH the commit tested is unknown" {
    # verifies: PR-y8ff5p
    make_checkout
    rm "$tools_dir/git"
    run_runner
    assert_commit_tested_unknown "run-tests: no git repository found; the commit tested is unknown"
}

@test "run-tests: a git that fails before the run leaves the suite's own status, and the commit tested is unknown" {
    # verifies: PR-y8ff5p
    make_checkout
    make_failing_git_stub add
    make_stub bats 'exit 3'
    run_runner
    [ "$status" -eq 3 ] || { echo "status $status: $output"; false; }
    assert_stderr_has "run-tests: git add -A failed: fatal: stub add refused"
    grep -qxF "run-tests: the commit tested is unknown" "$runner_stderr_file" ||
        { cat "$runner_stderr_file"; false; }
    assert_stderr_lacks "no git repository found"
    assert_stderr_lacks "run-tests: testing commit"
}

@test "run-tests: a git that fails after the run is reported, and fails a passing run" {
    # verifies: PR-y8ff5p
    make_checkout
    marker="$BATS_TEST_TMPDIR/bats-ran"
    make_failing_git_stub add "$marker"
    make_stub bats ": > '$marker'; exit 0"
    run_runner
    [ "$status" -eq 1 ] || { echo "status $status: $output"; false; }
    assert_stderr_has "run-tests: testing commit $checkout_commit"
    assert_stderr_has "run-tests: git add -A failed: fatal: stub add refused"
}

@test "outside_bats: the command runs without bats's libexec directory on PATH" {
    # verifies: PR-2nxadp
    case ":$PATH:" in
        (*":$BATS_LIBEXEC:"*) ;;
        (*) echo "the test's own PATH lacks $BATS_LIBEXEC: $PATH"; false ;;
    esac
    run outside_bats sh -c 'printf %s "$PATH"'
    [ "$status" -eq 0 ]
    case ":$output:" in
        (*":$BATS_LIBEXEC:"*) echo "outside_bats kept $BATS_LIBEXEC: $output"; false ;;
    esac
}

# index_state: the checkout's index as a tree object, then its status.
index_state() {
    git -C "$checkout" write-tree
    git -C "$checkout" status --porcelain
}

@test "run-tests: the checkout's own index is left as it was, staged and unstaged changes alike" {
    # verifies: PR-y8ff5p
    make_checkout
    echo other > "$checkout/other"
    commit_all other
    echo staged >> "$checkout/README"
    git -C "$checkout" add README
    echo unstaged >> "$checkout/other"
    echo new > "$checkout/untracked"
    before=$(index_state)
    run_runner
    [ "$status" -eq 0 ] || { echo "status $status: $output"; false; }
    after=$(index_state)
    [ "$after" = "$before" ] || { printf 'before:\n%s\nafter:\n%s\n' "$before" "$after"; false; }
}

@test "run-tests: a mktemp that fails is reported in its own words, and the commit tested is unknown" {
    # verifies: PR-y8ff5p
    make_checkout
    make_stub mktemp 'echo "mktemp: stub refused" >&2; exit 1'
    run_runner
    assert_commit_tested_unknown "run-tests: the commit tested is unknown"
    assert_stderr_has "mktemp: stub refused"
}

@test "run-tests: the fingerprint helper leaves nothing in TMPDIR" {
    # verifies: PR-y8ff5p
    make_checkout
    runner_tmpdir="$BATS_TEST_TMPDIR/runner-tmp"
    mkdir -p "$runner_tmpdir"
    TMPDIR="$runner_tmpdir" run_runner
    [ "$status" -eq 0 ] || { echo "status $status: $output"; false; }
    assert_stderr_has "run-tests: testing commit $checkout_commit"
    left=$(ls -A "$runner_tmpdir")
    [ -z "$left" ] || { echo "left in TMPDIR: $left"; false; }
}
