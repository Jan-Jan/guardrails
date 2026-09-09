#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# finalize-docs.sh [--dry-run]
#
# Renames this change's draft ledger files to their merge-dated names:
#   docs/<area>/DRAFT-<branch>-<slug>.md -> docs/<area>/<merge-date>-<slug>.md
# Prints one "before -> after" line per rename. Then rewrites every
# root-relative path and every bare name that refers to a renamed file across
# the ledger directories and the SOUP file, printing one "rewrote FILE: old ->
# new" line each (and "would rewrite" under --dry-run). Under --dry-run a
# reference inside a draft that is itself being renamed is reported under the
# draft's own name, since the preview runs before the rename. Plans and
# verification records are never touched: they narrate the rename, and a true
# sentence about history must stay true. A bare name glued to a longer token
# or wrapped in emphasis (aDRAFT-x.md, _DRAFT-x.md_) is not rewritten either —
# it is not the file's name — and check-trace.sh reports it after the merge.
# Idempotent: with no draft ledger files present it prints nothing.
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
# A die during the rewrite pass leaves the renames done (staged for a tracked
# draft, plain-moved for an untracked one), every reference rewritten before
# the die rewritten, and the rest as they were; a re-run is the silent no-op,
# so recovery is to fix the remaining references by hand — check-trace.sh's
# DANGLING-FILE names each one.
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

# Unit-scoped by nature: this renames drafts inside ONE config's doc_*
# directories. merge-change runs it once per touched unit of the impact set,
# GR_CONFIG pointing at each (architecture item 9) — so in a manifest
# repository a bare invocation must refuse rather than rename nothing and
# report success.
gr_unit_engage

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

# rewrite_file FILE OLD NEW BARE PROBE — replace every literal occurrence of
# OLD in FILE by NEW. Exit 0 when something was (or, under --dry-run or
# PROBE=1, would be) rewritten, 3 when nothing qualifies, 2 on any failure.
# Three answers, because two of them look alike from the outside and mean
# opposite things: "nothing to do" and "could not do it".
#
# BARE=1 is the bare-basename pass: an occurrence preceded by "/" is the tail
# of a path to some OTHER file that shares the basename — a sibling unit's
# draft under the same branch name is the realistic shape — and one preceded
# by a name character is a longer token that merely ends in the name; neither
# is this rename's to change (review findings 1 and 14). Under --dry-run the
# path pass has consumed nothing, so this same rule is what keeps the preview
# equal to the real run (finding 2).
#
# Literal, via index/substr, never sed: OLD is a file name, and the `.` in
# `DRAFT-x.md` is a metacharacter that would match any character. The values
# travel through ENVIRON rather than -v: awk -v processes escape sequences in
# its value, and a file name is not an awk string literal.
rewrite_file() {
    _rf="$1"
    _write=1
    [ "$dry" -eq 1 ] && _write=0
    [ "${5:-0}" -eq 1 ] && _write=0
    if [ "$_write" -eq 1 ]; then _tmp="$_rf.gr-rewrite"; else _tmp=/dev/null; fi
    GR_OLD="$2" GR_NEW="$3" GR_BARE="${4:-0}" GR_WRITE="$_write" awk '
        BEGIN {
            old = ENVIRON["GR_OLD"]; new = ENVIRON["GR_NEW"]
            bare = (ENVIRON["GR_BARE"] == "1"); write = (ENVIRON["GR_WRITE"] == "1")
            n = 0
        }
        {
            line = $0
            out = ""
            while ((p = index(line, old)) > 0) {
                if (bare && p > 1 && substr(line, p - 1, 1) ~ /[A-Za-z0-9_.\/-]/) {
                    out = out substr(line, 1, p + length(old) - 1)
                    line = substr(line, p + length(old))
                    continue
                }
                out = out substr(line, 1, p - 1) new
                line = substr(line, p + length(old))
                n++
            }
            if (write) print out line
        }
        END { exit (n > 0) ? 0 : 3 }
    ' "$_rf" > "$_tmp"
    _st=$?
    if [ "$_write" -eq 1 ]; then
        case $_st in
            (0) mv "$_tmp" "$_rf" || return 2 ;;
            (3) rm -f "$_tmp" ;;
            (*) rm -f "$_tmp"; return 2 ;;
        esac
    fi
    case $_st in
        (0 | 3) return $_st ;;
        (*) return 2 ;;
    esac
}

# scan_refs NEEDLE — the files of the rewrite scope containing NEEDLE, one per
# line. A failed scan is fatal, not "no occurrences" (review finding 6):
# check-trace.sh treats its own reference scan the same way.
scan_refs() {
    # shellcheck disable=SC2086
    _found=$(git grep -l --untracked -F -- "$1" $rewrite_scope)
    _gst=$?
    [ "$_gst" -le 1 ] || gr_die "reference scan failed (git grep exit $_gst)"
    printf '%s\n' "$_found"
}

# rewrite_refs OLD NEW BARE — rewrite OLD to NEW in every file of the rewrite
# scope that contains it, printing one line per file. Under --dry-run it
# prints what it would do and touches nothing.
rewrite_refs() {
    _old="$1"
    _new="$2"
    _bare="${3:-0}"
    _hits=$(scan_refs "$_old") || exit 2
    for _h in $_hits; do
        [ -n "$_h" ] || continue
        rewrite_file "$_h" "$_old" "$_new" "$_bare" 0
        case $? in
            (0) if [ "$dry" -eq 1 ]; then
                    echo "would rewrite $_h: $_old -> $_new"
                else
                    echo "rewrote $_h: $_old -> $_new"
                fi ;;
            (3) ;;
            (*) gr_die "rewrite failed: $_h ($_old -> $_new)" ;;
        esac
    done
}

# Path-shaped references first, for every pair; bare basenames second, for
# the unambiguous pairs only; then one `left` line per FILE that still holds a
# bare form of an ambiguous name (finding 3) — a file holding only the path
# form was rewritten by the first pass and has nothing left in it.
run_rewrites() {
    for line in $renames; do
        [ -n "$line" ] || continue
        rewrite_refs "${line%% *}" "${line#* }" 0
    done
    for _pair in $bare_pairs; do
        [ -n "$_pair" ] || continue
        _ob=${_pair%% *}
        _nb=${_pair#* }
        gr_contains "$ambiguous" "$_ob" && continue
        rewrite_refs "$_ob" "$_nb" 1
    done
    for _ob in $ambiguous; do
        [ -n "$_ob" ] || continue
        _hits=$(scan_refs "$_ob") || exit 2
        for _h in $_hits; do
            [ -n "$_h" ] || continue
            rewrite_file "$_h" "$_ob" "$_ob" 1 1
            case $? in
                (0) echo "left $_h: $_ob (two renames share this name; a bare reference cannot be resolved — write the path)" ;;
                (3) ;;
                (*) gr_die "reference probe failed: $_h ($_ob)" ;;
            esac
        done
    done
}

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

# --- The rewrite pass -------------------------------------------------------
# The script knows both names of every file it renames, so leaving the
# references behind was a second pass it never made (PR-58zsvf). Downstream,
# 13 dangling links over 9 filenames grew to 25 over 16 in eighteen days, by
# construction rather than by mistake.
#
# Scope is the ledger directories and the SOUP file — the files whose
# references have to RESOLVE — and deliberately not the whole tree. Plans and
# verification records narrate the rename ("created as DRAFT-x.md, finalized
# to 2026-09-04-x.md"), and rewriting those sentences turns a true statement
# into a false one. check-trace.sh's DANGLING-FILE reads the same scope, so
# what this pass cannot reach (a reference held in another worktree, or in
# another unit's ledger) is convicted at that change's own merge.
#
# Every rewrite is printed. A rename is mechanical; a rewrite edits prose
# somebody else wrote.
rewrite_scope=""
for _key in doc_srs doc_rmf doc_sad doc_problems doc_soup; do
    _fs=$(gr_doc_files "$_key") || exit 2
    [ -n "$_fs" ] && rewrite_scope="${rewrite_scope}${rewrite_scope:+
}$_fs"
done
# A bare basename maps two ways when two drafts share it and a same-day
# collision suffixes one of them. Only the path-shaped reference can be
# rewritten then; the bare one is reported as left, and DANGLING-FILE
# convicts it if it does not resolve.
ambiguous=$(printf '%s' "$renames" | awk '
    NF == 2 {
        o = $1; sub(/.*\//, "", o)
        t = $2; sub(/.*\//, "", t)
        if (o in seen && seen[o] != t) amb[o] = 1
        seen[o] = t
    }
    END { for (o in amb) print o }')
# One `old new` basename pair per distinct old basename. Two sibling drafts
# under one branch name share a basename and map it the same way when there is
# no collision; iterating the renames would rewrite (and preview) that one
# bare name once per sibling (review finding 10).
bare_pairs=$(printf '%s' "$renames" | awk '
    NF == 2 {
        o = $1; sub(/.*\//, "", o)
        t = $2; sub(/.*\//, "", t)
        if (!(o in seen)) { seen[o] = t; print o " " t }
    }')

# Pathname expansion OFF from here on. The planning glob above is done, and
# the rewrite pass splits `$rewrite_scope` and the scan hits unquoted —
# ledger file names listed by gr_doc_files, never checked for glob
# characters. An earlier comment here argued no input reached these splits;
# the rewrite pass changed that, and a glob-shaped name that matches a sibling
# is replaced by the match, so the file it named is never scanned and its
# rewrite is lost (review finding 13; the test names a `[x].md`). The renames
# record itself is still safe for the reason it always was — whitespace is
# rejected at planning — but one line covers both.
set -f

for line in $renames; do
    [ -n "$line" ] || continue
    f=${line%% *}
    target=${line#* }
    echo "${f##*/} -> ${target##*/}"
done

# Under --dry-run the drafts are still in place and legitimately in scope, so
# the scope computed above is the right one to preview against.
[ "$dry" -eq 1 ] && run_rewrites
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

# Recompute: the renamed files are the ones most likely to hold a sibling
# reference, and they did not exist under these names a moment ago.
# gr_doc_files enumerates a ledger by glob, and pathname expansion has been
# off since the planning comment above, so it is switched on for exactly this
# enumeration and off again before the scope is split — the same bracket
# check-trace.sh puts around its own gr_doc_files calls.
set +f
rewrite_scope=""
for _key in doc_srs doc_rmf doc_sad doc_problems doc_soup; do
    _fs=$(gr_doc_files "$_key") || exit 2
    [ -n "$_fs" ] && rewrite_scope="${rewrite_scope}${rewrite_scope:+
}$_fs"
done
set -f
run_rewrites

exit 0
