#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# Run the guardrails test suite. Uses system bats if present, otherwise
# vendors bats-core into tests/.bats-core (gitignored).
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

if [ "$files_named" = yes ]; then
    exec "$BATS" "$@"
fi
exec "$BATS" "$@" "$dir"/*.bats
