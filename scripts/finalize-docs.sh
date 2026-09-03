#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# finalize-docs.sh [--dry-run]
#
# Renames this change's draft ledger files to their merge-dated names:
#   docs/<area>/DRAFT-<branch>-<slug>.md -> docs/<area>/<merge-date>-<slug>.md
# Prints one "before -> after" line per rename. Idempotent: with no draft
# ledger files present it prints nothing.
#
# There are no IDs to finalize. An item is given its ID by new-id.sh when it is
# written, and that ID is allocated against nothing, so nothing has to be
# assigned at merge. Draft ledger FILES are a different problem and remain:
# a change writes its own file so that parallel worktrees never touch one, and
# the merge date cannot be known until the merge.
#
# This script was called finalize-ids.sh until the token scheme landed. It was
# renamed rather than left holding a name for work it no longer does.
#
# Exit codes: 0 success, 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
# NOT `cd "$(gr_root)" || exit 2`: gr_root's gr_die exits only the command
# substitution, and under dash `cd ""` returns 0 and stays put — so outside a
# git repository the script carried on in the caller's directory with a
# relative config path. The status has to be taken from the substitution.
gr_repo_root=$(gr_root) || exit 2
cd "$gr_repo_root" || exit 2

dry=0
while [ $# -gt 0 ]; do
    case "$1" in
        (--dry-run) dry=1 ;;
        (*) gr_die "unknown argument: $1" ;;
    esac
    shift
done

# A typo'd doc_* key makes the rename loop below skip that ledger entirely and
# still exit 0 — a silent no-op reported as success. gr_check_config validates
# a key's SPELLING; gr_doc_files below validates its VALUE. Both are needed: a
# misspelled doc_* key reads as "this project has no such ledger", so its
# DRAFT- file is never renamed and the run reports that it renamed everything
# there was to rename.
gr_check_config

# A doc_* whose VALUE points at a path that does not exist makes the same loop
# skip that ledger just as silently.
for _key in doc_srs doc_rmf doc_sad doc_soup doc_problems; do
    gr_doc_files "$_key" >/dev/null || exit 2
done

# The lists below are newline-separated; split on newlines alone so a path
# containing a space survives intact. The `renames` record is a space-joined
# "source target" pair split with ${x%% *} regardless of IFS — which is why a
# draft ledger file name containing whitespace is rejected outright during
# planning, before anything is renamed, rather than corrupting the rename.
IFS='
'

today=$(date +%Y-%m-%d)
branch=$(git branch --show-current 2>/dev/null | tr -c 'A-Za-z0-9\n' '-')
renames=""
for key in doc_srs doc_rmf doc_sad doc_problems; do
    dir=$(cfg_get "$key")
    [ -n "$dir" ] && [ -d "$dir" ] || continue
    for f in "$dir"/DRAFT-*.md; do
        [ -f "$f" ] || continue
        case "$f" in
            (*" "* | *"	"*)
                gr_die "draft ledger file name contains whitespace: $f" ;;
        esac
        slug=${f##*/}
        slug=${slug#DRAFT-}
        slug=${slug%.md}
        # strip the current branch's name prefix when it matches
        [ -n "$branch" ] && slug=${slug#"${branch}"-}
        # collision check covers files on disk AND targets already planned
        # in this run (two drafts can reduce to the same slug)
        target="$dir/${today}-${slug}.md"
        n=2
        while [ -e "$target" ] || printf '%s' "$renames" \
                | awk -v t="$target" '$2 == t { found = 1 } END { exit !found }'; do
            target="$dir/${today}-${slug}-${n}.md"
            n=$((n + 1))
        done
        renames="${renames}${f} ${target}
"
    done
done

[ -n "$renames" ] || exit 0

# No `set -f` around the splits below, deliberately, and this is the reason
# rather than an oversight. Word splitting does drag pathname expansion along,
# which is why check-trace.sh and check-review.sh both set it — but here every
# `renames` field is `"$f $target"` under one directory, expansion splits the
# pattern on `/`, and a draft ledger name containing whitespace is already
# rejected during planning above. No input reaches it. A `set -f` added here
# was unkillable: no mutation of it could change any output, and unkillable
# code is code nobody can show works.

for line in $renames; do
    [ -n "$line" ] || continue
    f=${line%% *}
    target=${line#* }
    echo "${f##*/} -> ${target##*/}"
done

[ "$dry" -eq 1 ] && exit 0

# Rename draft doc files (tracked via git mv; untracked via plain mv).
# Never overwrite: a pre-existing target here is a bug, not a fallback.
#
# A plain `for` loop, NOT `printf … | while`: a pipeline runs its loop body in
# a subshell, where the gr_die below would exit that subshell only and the
# script would carry on to `exit 0` — reporting success after refusing to do
# the rename.
for line in $renames; do
    [ -n "$line" ] || continue
    f=${line%% *}
    target=${line#* }
    [ ! -e "$target" ] || gr_die "rename target already exists: $target"
    git mv "$f" "$target" 2>/dev/null || mv "$f" "$target" || \
        gr_die "rename failed: $f -> $target"
done

exit 0
