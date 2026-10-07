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
# the commands run-tests.sh needs. A system directory such as /usr/bin would
# also hold the host's own bats and parallel (Debian's parallel package
# installs /usr/bin/parallel), and either would change what the runner does.
# getconf and sysctl are linked only by a test that wants the host's answer.
make_tools_dir() {
    tools_dir="$BATS_TEST_TMPDIR/tools"
    mkdir -p "$tools_dir"
    link_tool dirname
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
# caller sets runner_jobs, which becomes its value; a caller who sets
# runner_stderr_file gets the runner's standard error there, kept out of
# $output. Every test runs the runner through this, so neither the host's
# parallel nor the caller's RUN_TESTS_JOBS reaches the run.
run_runner() {
    local settings=(-u RUN_TESTS_JOBS)
    if [ -n "${runner_jobs+set}" ]; then
        settings+=("RUN_TESTS_JOBS=$runner_jobs")
    fi
    settings+=("PATH=$stub_dir:$tools_dir")
    if [ -n "${runner_stderr_file:-}" ]; then
        run sh -c 'stderr_file=$1; shift; "$@" 2>"$stderr_file"' \
            run-tests "$runner_stderr_file" \
            env "${settings[@]}" "$shell_path" "$runner" "$@"
    else
        run env "${settings[@]}" "$shell_path" "$runner" "$@"
    fi
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
