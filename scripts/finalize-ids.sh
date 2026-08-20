#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# finalize-ids.sh [--dry-run] [--base REF]
#
# Converts draft IDs (<PREFIX>-DRAFT-<slug>-<n>) into final sequential IDs.
# For each prefix, the next number is one past the highest final ID found on
# REF (default: the branch checked out in the primary worktree) or in the
# working tree. Draft definitions are numbered
# in definition order (file path, then line). Every occurrence of each draft
# token in tracked/untracked files is rewritten (longest token first, so
# ...-1 never clobbers part of ...-12). Prints one "DRAFT -> FINAL" line per
# minted ID. Idempotent: with no drafts present it prints nothing.
#
# The pre-flight scans for ANY `<prefix>-DRAFT-<slug>-<n>` token, not only the
# declared prefixes: a prefix in use but missing from id_prefixes cannot be
# minted, so it must block rather than ride onto the base branch unnoticed.
#
# Only drafts whose item header is bold at line start (**PREFIX-DRAFT-slug-n**:)
# are minted. A pre-flight refuses to rewrite or rename anything while any
# other draft token remains in the tree, so a malformed header fails here
# rather than silently reporting success. The pre-flight runs before the
# --dry-run early exit, so --dry-run reports the problem too and can exit 1.
#
# Exit codes: 0 success, 1 unminted drafts remain, 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
cd "$(gr_root)" || exit 2

dry=0
base=""
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

[ -n "$base" ] || base=$(gr_base_branch)
[ -n "$base" ] || gr_die "cannot detect the base branch (primary checkout detached?); pass --base REF"

# A typo'd doc_* key makes the rename loop below skip that ledger entirely and
# still exit 0 — the same silent no-op the pre-flight exists to prevent, in the
# same script. Validate the config before trusting any key it holds.
# gr_check_config validates a key's SPELLING, gr_doc_files below validates its
# VALUE. Both are needed: a misspelled doc_* key reads as "this project has no
# such ledger", so its DRAFT- file is never renamed while the IDs are minted
# and rewritten — the same half-finalized tree, one key-position over.
gr_check_config

# A doc_* whose VALUE points at a path that does not exist makes the rename
# loop below skip that ledger silently: the IDs are minted and rewritten, the
# DRAFT- file is left in place, and the run exits 0 over exactly the
# half-finalized tree this script must never produce. gr_doc_files validates
# the value.
for _key in doc_srs doc_rmf doc_sad doc_soup doc_problems; do
    gr_doc_files "$_key" >/dev/null || exit 2
done

# gr_prefixes validates each prefix as a bare identifier. It is interpolated
# into every pattern below; an unvalidated metacharacter would make git grep
# error out, match nothing, and leave this script reporting a clean tree.
prefixes=$(gr_prefixes) || exit 2

# The lists scanned from git are newline-separated; split on newlines alone so
# a path containing a space survives intact. Note that the `mapping` and
# `renames` records built below are space-joined "source target" pairs and are
# split with ${x%% *} regardless of IFS — which is why a draft ledger file name
# containing whitespace is rejected outright during planning, before anything
# is rewritten, rather than corrupting the rename.
IFS='
'

# max_final PREFIX [REF] — highest existing final number for PREFIX (0 if none)
#
# gr_def_re, so this scan and the draft scan above obey one rule. They did not:
# the draft scan has always anchored at line start, while this one matched the
# definition form anywhere on a line. A backticked `**PR-900**:` in prose
# therefore minted the next problem report as PR-901, and no gate reported it —
# check-ids.sh and check-trace.sh both anchor, so to them that token defines
# nothing. check-ids.sh reports UNANCHORED-DEF for exactly this shape now,
# because narrowing what counts here can only lower the ceiling.
max_final() {
    _p="$1"
    _ref="${2:-}"
    if [ -n "$_ref" ]; then
        git grep -h -oE "$(gr_def_re "$_p")" "$_ref" \
            -- . ":(exclude).guardrails" 2>/dev/null
    else
        git grep -h --untracked -oE "$(gr_def_re "$_p")" \
            -- . ":(exclude).guardrails" 2>/dev/null
    fi | awk 'BEGIN { m = 0 }
              NF { id = $0; sub(/^\*\*/, "", id); sub(/\*\*:$/, "", id)
                   # The digits after the LAST hyphen. A bare [0-9]+ harvest
                   # took every digit run on the token, so a prefix carrying a
                   # digit — R9-005 — was read as 9 and the next ID minted as
                   # R9-010, while the ceiling scan in check-ids.sh read it
                   # correctly. Two numbers for one ID is exactly the kind of
                   # disagreement this change exists to end.
                   n = id; sub(/^.*-/, "", n)
                   if (n + 0 > m) m = n + 0 }
              END { print m }'
}

mapping=""
for p in $prefixes; do
    base_max=$(max_final "$p" "$base")
    tree_max=$(max_final "$p")
    next=$base_max
    [ "$tree_max" -gt "$next" ] && next=$tree_max

    # Same pathspec as the pre-flight and the rewrite below. A wider mint scan
    # than rewrite scan mints an ID for a draft it then never rewrites: the
    # number is burned, the draft token survives, and the run exits 0.
    drafts=$(git grep -h --untracked -oE \
        "^\\*\\*${p}-DRAFT-[A-Za-z0-9][A-Za-z0-9-]*-[0-9]+\\*\\*:" \
        -- . ":(exclude).guardrails" 2>/dev/null \
        | sed 's/[*:]//g')
    [ -n "$drafts" ] || continue

    for d in $drafts; do
        next=$((next + 1))
        final=$(printf '%s-%03d' "$p" "$next")
        mapping="${mapping}${d} ${final}
"
    done
done

# --- Pre-flight: every draft token in the tree must have been minted -------
# Only drafts with a bold `**PREFIX-DRAFT-slug-n**:` header at line start are
# minted above. Without this gate a plain `PREFIX-DRAFT-slug-n:` header is
# skipped, the ledger files are renamed anyway, and the script exits 0 — a
# silent no-op reported as success. Runs before any rewrite or rename, so a
# failure leaves the tree untouched and the fix is made on a clean tree.
# Deliberately NOT limited to the configured prefixes: a draft whose prefix is
# absent from id_prefixes is one that can never be minted, which is exactly the
# case that must not pass silently.
draft_re="[A-Za-z][A-Za-z0-9]*-DRAFT-[A-Za-z0-9][A-Za-z0-9-]*-[0-9]+"

# stderr is deliberately NOT suppressed and the status is checked: a scan that
# errors finds nothing, and "found nothing" is what a clean tree looks like.
# Swallowing the failure here would reinstate the very false green this gate
# exists to remove. git grep exits 1 for "no matches", >1 for a real failure.
# NB: no pipeline here — `$?` after `x=$(a | b)` is b's status, not a's, which
# would hide exactly the failure being checked for. Sort afterwards.
tokens=$(git grep -hoI --untracked -E "$draft_re" -- . ":(exclude).guardrails")
scan_status=$?
[ "$scan_status" -le 1 ] || gr_die "scanning for draft IDs failed (git grep exit $scan_status)"
tokens=$(printf '%s\n' "$tokens" | sort -u)

mapped=$(printf '%s' "$mapping" | cut -d' ' -f1 | sort -u)
unminted=""
for t in $tokens; do
    [ -n "$t" ] || continue
    gr_contains "$mapped" "$t" || unminted="${unminted}${t}
"
done

if [ -n "$unminted" ]; then
    for t in $unminted; do
        [ -n "$t" ] || continue
        git grep -InI --untracked -F "$t" -- . ":(exclude).guardrails" 2>/dev/null \
            | sed 's/^/UNMINTED-DRAFT /'
    done
    echo "guardrails: the draft IDs above were never minted. Either the item has" >&2
    echo "no bold definition header at line start (**PREFIX-DRAFT-slug-n**:), or" >&2
    echo "its PREFIX is missing from id_prefixes and so was never a candidate to" >&2
    echo "mint. Fix whichever applies. Nothing was rewritten or renamed." >&2
    exit 1
fi

# --- Draft doc files: DRAFT-<branch>-<slug>.md → <merge-date>-<slug>.md ----
today=$(date +%Y-%m-%d)
branch=$(git branch --show-current 2>/dev/null | tr -c 'A-Za-z0-9\n' '-')
renames=""
for key in doc_srs doc_rmf doc_sad doc_problems; do
    dir=$(cfg_get "$key")
    [ -n "$dir" ] && [ -d "$dir" ] || continue
    for f in "$dir"/DRAFT-*.md; do
        [ -f "$f" ] || continue
        # Rejected here, during planning, because the rename records are
        # space-joined pairs: a name with whitespace would be split at the
        # wrong point and the failure would land AFTER the ID rewrite pass,
        # leaving a half-finalized tree. Failing now leaves it untouched.
        case "$f" in
            *" "* | *"	"*)
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

if [ -z "$mapping" ] && [ -z "$renames" ]; then
    exit 0
fi

for line in $mapping; do
    [ -n "$line" ] || continue
    echo "${line%% *} -> ${line#* }"
done
for line in $renames; do
    [ -n "$line" ] || continue
    f=${line%% *}
    target=${line#* }
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
#
# A plain `for` loop, NOT `printf … | while`: a pipeline runs its loop body in
# a subshell, where the gr_die below would exit that subshell only and the
# script would carry on to `exit 0` — reporting success after refusing to do
# the rename. Same false-green shape as the pre-flight above.
for line in $renames; do
    [ -n "$line" ] || continue
    f=${line%% *}
    target=${line#* }
    [ ! -e "$target" ] || gr_die "rename target already exists: $target"
    git mv "$f" "$target" 2>/dev/null || mv "$f" "$target" || \
        gr_die "rename failed: $f -> $target"
done

exit 0
