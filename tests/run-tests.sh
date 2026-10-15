#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# Run the guardrails test suite as a measurement of one commit, which it
# names.
# It uses system bats if present, otherwise it vendors bats-core into
# tests/.bats-core (gitignored). Before bats runs, it names the commit under
# test on standard error, with a note when the working tree differs from
# that commit. A run whose working tree changed while bats ran fails: it
# compares the fingerprints tests/fingerprint-tree.sh prints before bats
# with the one it prints after.
set -eu

dir=$(cd "$(dirname "$0")" && pwd)

if command -v bats >/dev/null 2>&1; then
    BATS=bats
else
    if [ ! -x "$dir/.bats-core/bin/bats" ]; then
        echo "Vendoring bats-core v1.11.0 into tests/.bats-core ..." >&2
        git clone -q --depth 1 --branch v1.11.0 \
            https://github.com/bats-core/bats-core "$dir/.bats-core"
    fi
    BATS="$dir/.bats-core/bin/bats"
fi

# An argument ending in .bats that is an existing file, or an argument that is
# an existing directory, names what to run and replaces the glob; without one,
# every file runs. Appending the glob ran a named file twice and the whole
# suite once, and ran a named directory such as tests/ twice, since bats runs
# a directory's files itself (PR-r83mmd). An option's value can end in .bats
# too, as in --filter foo.bats, and must not drop the glob, so a name counts
# only if the file exists.
files_named=no
for argument in "$@"; do
    if [ -d "$argument" ]; then
        files_named=yes
        continue
    fi
    case $argument in
        (*.bats)
            if [ -f "$argument" ]; then
                files_named=yes
            fi ;;
    esac
done

# How many files bats runs at once (PR-hrx4vf). RUN_TESTS_JOBS=1 runs
# serially and RUN_TESTS_JOBS=<n> runs n at once; any other value is a
# mistake, and running serially in its place would hide it. Unset or empty,
# the runner uses every CPU where GNU parallel, which bats --jobs needs, is
# installed, and runs serially where it is not.
jobs_setting=${RUN_TESTS_JOBS:-}
case $jobs_setting in
    ('') ;;
    (*[!0-9]*)
        echo "run-tests.sh: RUN_TESTS_JOBS must be a positive integer, not '$jobs_setting'" >&2
        exit 2 ;;
    (?????*)
        # A sanity bound: no host has 10,000 CPUs. It also keeps the shell's
        # integer test below far from overflow, which starts at 19 digits and
        # fails with "integer expression expected" (PR-hrx4vf).
        echo "run-tests.sh: RUN_TESTS_JOBS must be at most 9999, not '$jobs_setting'" >&2
        exit 2 ;;
    (*)
        if [ "$jobs_setting" -lt 1 ]; then
            echo "run-tests.sh: RUN_TESTS_JOBS must be a positive integer, not '$jobs_setting'" >&2
            exit 2
        fi ;;
esac

# A caller who names a job count has decided it; a second --jobs would
# override theirs. bats 1.11 takes --jobs N and -j N only; it rejects --jobs=N.
caller_set_jobs=no
for argument in "$@"; do
    case $argument in
        (--jobs|-j) caller_set_jobs=yes ;;
    esac
done

# bats --jobs needs GNU parallel. moreutils installs a different program under
# the same name, and bats --jobs with it runs no test, so a parallel whose
# --version does not say GNU parallel counts as absent (PR-hrx4vf).
gnu_parallel_installed() {
    command -v parallel >/dev/null 2>&1 || return 1
    parallel_version=$(parallel --version </dev/null 2>/dev/null) || return 1
    case $parallel_version in
        (*'GNU parallel'*) return 0 ;;
    esac
    return 1
}

job_count=1
if [ "$caller_set_jobs" = no ]; then
    if [ -n "$jobs_setting" ]; then
        # An explicit count passes --jobs even without parallel: bats then
        # reports that it needs parallel, which says more than a silent
        # serial run would.
        job_count=$jobs_setting
    elif gnu_parallel_installed; then
        # getconf answers on Linux and macOS; sysctl covers a BSD without
        # _NPROCESSORS_ONLN; with neither, one CPU.
        job_count=$(getconf _NPROCESSORS_ONLN 2>/dev/null) ||
            job_count=$(sysctl -n hw.ncpu 2>/dev/null) ||
            job_count=1
        case $job_count in
            (''|*[!0-9]*) job_count=1 ;;
        esac
    fi
fi

# --jobs goes first, so the caller's own arguments keep their order after it.
if [ "$job_count" -gt 1 ]; then
    set -- --jobs "$job_count" "$@"
fi

if [ "$files_named" = no ]; then
    set -- "$@" "$dir"/*.bats
fi

# The commit this run tests (PR-y8ff5p). The tests read the files of the
# working tree they live in, so a commit or an edit made there during a run
# gives a result that describes no commit. Messages go to standard error and
# leave the TAP stream as bats wrote it.
root=$(cd "$dir/.." && pwd -P)
# A fingerprint the helper cannot take leaves the commit tested unknown
# before the run, and the line says why: exit 2 is no git repository or no
# git, exit 3 a HEAD that names no commit, and any other failure a git the
# helper reported itself. After the run, a fingerprint it cannot take reads
# as a changed working tree, which fails the run.
fingerprint_taken=no
fingerprint_status=0
fingerprint_before=$(sh "$dir/fingerprint-tree.sh" "$root") || fingerprint_status=$?
case $fingerprint_status in
    (0)
        fingerprint_taken=yes
        head=${fingerprint_before%% *}
        if ! commit_tree=$(git -C "$root" rev-parse "$head^{tree}" 2>&1); then
            echo "run-tests: git rev-parse $head^{tree} failed: $commit_tree" >&2
            echo "run-tests: the commit tested is unknown" >&2
        elif [ "${fingerprint_before#* }" = "$commit_tree" ]; then
            echo "run-tests: testing commit $head" >&2
        else
            echo "run-tests: the working tree differs from commit $head; this run tests no commit" >&2
        fi
        ;;
    (2) echo "run-tests: no git repository found; the commit tested is unknown" >&2 ;;
    (3) echo "run-tests: HEAD names no commit; the commit tested is unknown" >&2 ;;
    (*) echo "run-tests: the commit tested is unknown" >&2 ;;
esac

suite_status=0
"$BATS" "$@" || suite_status=$?

if [ "$fingerprint_taken" = yes ] &&
    [ "$(sh "$dir/fingerprint-tree.sh" "$root")" != "$fingerprint_before" ]; then
    echo "run-tests: the working tree changed during the run; this result describes no commit" >&2
    if [ "$suite_status" -eq 0 ]; then
        suite_status=1
    fi
fi
exit "$suite_status"
