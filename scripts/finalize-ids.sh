#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# finalize-ids.sh [--dry-run] [--base REF]
#
# Converts draft IDs (<PREFIX>-DRAFT-<slug>-<n>) into final sequential IDs.
# For each prefix, the next number is one past the highest final ID found on
# REF (default: main) or in the working tree. Draft definitions are numbered
# in definition order (file path, then line). Every occurrence of each draft
# token in tracked/untracked files is rewritten (longest token first, so
# ...-1 never clobbers part of ...-12). Prints one "DRAFT -> FINAL" line per
# minted ID. Idempotent: with no drafts present it prints nothing.
#
# Exit codes: 0 success, 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
cd "$(gr_root)" || exit 2

dry=0
base="main"
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) dry=1 ;;
        --base)
            shift
            base="${1:-}"
            [ -n "$base" ] || gr_die "--base requires a ref"
            ;;
        *) gr_die "unknown argument: $1" ;;
    esac
    shift
done

prefixes=$(cfg_get id_prefixes)
[ -n "$prefixes" ] || gr_die "id_prefixes not configured"

# max_final PREFIX [REF] — highest existing final number for PREFIX (0 if none)
max_final() {
    _p="$1"
    _ref="${2:-}"
    if [ -n "$_ref" ]; then
        git grep -h -oE "\\*\\*${_p}-[0-9]{3,}\\*\\*:" "$_ref" -- 2>/dev/null
    else
        git grep -h --untracked -oE "\\*\\*${_p}-[0-9]{3,}\\*\\*:" -- . 2>/dev/null
    fi | grep -oE '[0-9]+' | awk 'BEGIN { m = 0 } $1 + 0 > m { m = $1 + 0 } END { print m }'
}

mapping=""
for p in $prefixes; do
    base_max=$(max_final "$p" "$base")
    tree_max=$(max_final "$p")
    next=$base_max
    [ "$tree_max" -gt "$next" ] && next=$tree_max

    drafts=$(git grep -h --untracked -oE \
        "^\\*\\*${p}-DRAFT-[A-Za-z0-9][A-Za-z0-9-]*-[0-9]+\\*\\*:" -- . 2>/dev/null \
        | sed 's/[*:]//g')
    [ -n "$drafts" ] || continue

    for d in $drafts; do
        next=$((next + 1))
        final=$(printf '%s-%03d' "$p" "$next")
        mapping="${mapping}${d} ${final}
"
    done
done

# --- Draft doc files: DRAFT-<branch>-<slug>.md → <merge-date>-<slug>.md ----
today=$(date +%Y-%m-%d)
branch=$(git branch --show-current 2>/dev/null | tr -c 'A-Za-z0-9\n' '-')
renames=""
for key in doc_srs doc_rmf doc_sad doc_problems; do
    dir=$(cfg_get "$key")
    [ -n "$dir" ] && [ -d "$dir" ] || continue
    for f in "$dir"/DRAFT-*.md; do
        [ -f "$f" ] || continue
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

if [ -z "$mapping" ] && [ -z "$renames" ]; then
    exit 0
fi

printf '%s' "$mapping" | while IFS=' ' read -r d final; do
    [ -n "$d" ] || continue
    echo "$d -> $final"
done
printf '%s' "$renames" | while IFS=' ' read -r f target; do
    [ -n "$f" ] || continue
    echo "${f##*/} -> ${target##*/}"
done

[ "$dry" -eq 1 ] && exit 0

# Rewrite longest draft token first so a token that is a prefix of another
# (REQ-DRAFT-b-1 vs REQ-DRAFT-b-12) can never corrupt the longer one.
printf '%s' "$mapping" | awk '{ print length($1), $0 }' | sort -rn | cut -d' ' -f2- \
| while IFS=' ' read -r d final; do
    [ -n "$d" ] || continue
    git grep -l --untracked -F "$d" -- . ":(exclude).guardrails" 2>/dev/null \
    | while IFS= read -r f; do
        sed -i.bak "s/${d}/${final}/g" "$f" && rm -f "${f}.bak"
    done
done

# Rename draft doc files (tracked via git mv; untracked via plain mv).
# Never overwrite: a pre-existing target here is a bug, not a fallback.
printf '%s' "$renames" | while IFS=' ' read -r f target; do
    [ -n "$f" ] || continue
    [ ! -e "$target" ] || gr_die "rename target already exists: $target"
    git mv "$f" "$target" 2>/dev/null || mv "$f" "$target"
done

exit 0
