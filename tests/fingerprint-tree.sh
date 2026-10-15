#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# Print the fingerprint of the git repository at ROOT: its HEAD commit
# followed by a tree object of every file git tracks or does not ignore.
#
# Usage: sh tests/fingerprint-tree.sh ROOT
#
# The fingerprint is one line, `<HEAD commit> <tree object>` (PR-y8ff5p).
# The tree object is written from a temporary index seeded from HEAD, so a
# tracked file that .gitignore matches stays in the tree object, and the
# repository's own index is left as it was; untracked and modified files
# become loose objects in the repository. Two fingerprints of one repository
# differ when a commit or an edit came between them, and the tree object
# equals HEAD's tree object only when the working tree holds HEAD's files.
#
# Exit codes:
#   0  the fingerprint is printed on standard output.
#   1  a git command failed, and `run-tests: git <args> failed: <message>` is
#      on standard error, the prefix tests/run-tests.sh reports under; or
#      mktemp could not make the temporary directory, and its own message is
#      on standard error. Nothing is printed.
#   2  ROOT is not the top of a git repository, or git is absent; nothing
#      is printed. A repository nested inside another repository's working
#      tree, without a .git of its own, is not a repository here, so the
#      outer repository is never read as ROOT's. The wrong number of
#      arguments, or a ROOT that is not a directory, also exits 2, with the
#      reason on standard error.
#   3  ROOT is a repository whose HEAD names no commit; nothing is printed.
set -eu

if [ "$#" -ne 1 ]; then
    echo "usage: sh tests/fingerprint-tree.sh ROOT" >&2
    exit 2
fi
# cd reports a ROOT it cannot enter on standard error itself.
if ! root=$(cd "$1" && pwd -P); then
    exit 2
fi

# rev-parse's complaint outside a repository, or the shell's where git is
# absent, is the expected answer here, and exit 2 says it: its text would
# only repeat that.
if ! top=$(git -C "$root" rev-parse --show-toplevel 2>/dev/null); then
    exit 2
fi
if [ "$(cd "$top" && pwd -P)" != "$root" ]; then
    exit 2
fi
if ! head=$(git -C "$root" rev-parse -q --verify HEAD); then
    exit 3
fi

# The template names $TMPDIR itself: BSD mktemp -d without one ignores it.
fingerprint_dir=$(mktemp -d "${TMPDIR:-/tmp}/fingerprint-tree.XXXXXX") || exit 1
trap 'rm -rf "$fingerprint_dir"' EXIT INT TERM

# fingerprint_git <git arguments>: runs git in $root against the temporary
# index in $fingerprint_dir, and reports a failure on standard error.
fingerprint_git() {
    if GIT_INDEX_FILE="$fingerprint_dir/index" git -C "$root" "$@" 2>"$fingerprint_dir/error"; then
        return 0
    fi
    echo "run-tests: git $* failed: $(cat "$fingerprint_dir/error")" >&2
    return 1
}

if fingerprint_git read-tree HEAD && fingerprint_git add -A &&
    fingerprint_tree=$(fingerprint_git write-tree); then
    printf '%s %s\n' "$head" "$fingerprint_tree"
    exit 0
fi
exit 1
