#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# check-ids.sh [--allow-drafts] [--base REF]
#
# Fails (exit 1) on:
#   DRAFT-ID      — draft IDs (<PREFIX>-DRAFT-<slug>-<n>) anywhere in the tree,
#                   unless --allow-drafts
#   DUPLICATE-ID  — a final ID defined (**ID**: ...) more than once in the tree;
#                   also an ID newly defined since the merge base that the base
#                   ref already defines. The base defaults to the branch checked
#                   out in the primary worktree (override with --base REF). A
#                   base NAMED with --base that does not resolve is an error.
#                   A base that cannot be used — undetectable on a detached
#                   HEAD, or detected but with no commits yet — prints
#                   SKIPPED-DUPLICATE-BASE and leaves that one gate unrun,
#                   because a skipped gate must never look like a passed one.
#                   A definition
#                   moved to another file in the same change is NOT flagged
#                   (its old line shows as removed in the diff), however many
#                   move at once. A definition line declares the ID at its
#                   start and no other, so naming other IDs in the same
#                   sentence is safe.
#
# Reports without failing:
#   UNANCHORED-DEF  — the definition form somewhere other than line start, with
#                   a number above the highest one actually defined — counting
#                   the base ref, as finalize-ids.sh does, whenever there is a
#                   usable one. Without one the line says so, because the
#                   ceiling it names is then only this tree's. Such a token used
#                   to raise the mint ceiling and no longer does, so the number
#                   it was reserving can now be re-minted. Almost always prose
#                   about an item rather than a claim to be one, which is why
#                   it does not fail. Candidates come from the worktree; a
#                   token that only exists on the base is not reported.
#   UNANCHORED-DEF-UNREADABLE
#                 — a file this scan must read has a newline in its path, which
#                   its framing cannot represent. No off-column definitions were
#                   judged at all in that run; nothing else about the run
#                   changes. Rename the file to get the report back.
#
# Exit codes: 0 pass, 1 violations, 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
cd "$(gr_root)" || exit 2

# This gate validated nothing about the config until now — recorded as gap 3 in
# docs/verification/2026-08-18-config-schema.md. It reads only id_prefixes, so
# the omission looked harmless; it was not. Every shape gr_check_config exists
# to refuse — a misspelled key, a key hidden behind a BOM, a declared prefix
# whose gate inputs are unconfigured — was caught by the traceability and
# finalize gates only, so a project running check-ids.sh alone got no config
# validation at all.
gr_check_config

allow_drafts=0
base_named=
base=""
while [ $# -gt 0 ]; do
    case "$1" in
        --allow-drafts) allow_drafts=1 ;;
        --base)
            shift
            base="${1:-}"
            base_named=1
            [ -n "$base" ] || gr_die "--base requires a ref"
            ;;
        *) gr_die "unknown argument: $1" ;;
    esac
    shift
done

[ -n "$base" ] || base=$(gr_base_branch)

# gr_prefix_re validates each prefix as a bare identifier and dies otherwise;
# the die happens in a subshell here, so propagate it. An unvalidated
# metacharacter would make every pattern below an invalid ERE, git grep would
# error, match nothing, and this script would report a clean tree.
P=$(gr_prefix_re) || exit 2
[ -n "$P" ] || gr_die "id_prefixes not configured"

# Deliberately NOT limited to the configured prefixes, matching the pre-flight
# in finalize-ids.sh: a draft whose prefix is absent from id_prefixes is one
# that can never be minted, which is exactly the case that must not reach the
# base branch. Two gates disagreeing about what a draft is would leave a hole
# between them.
draft_re="[A-Za-z][A-Za-z0-9]*-DRAFT-[A-Za-z0-9][A-Za-z0-9-]*-[0-9]+"
def_re=$(gr_def_re "$P")
id_re="(${P})-[0-9]{3,}"
fail=0

# --- DRAFT-ID: no draft identifiers may remain (definitions or references) ---
if [ "$allow_drafts" -eq 0 ]; then
    # Status checked, stderr not suppressed — the same rule finalize-ids.sh's
    # pre-flight applies to the same scan. A scan that errors finds nothing,
    # and "found nothing" is what a clean tree looks like.
    #
    # Defence in depth only, and honestly weak: git grep exits >1 for some
    # failures but reports others (an unreadable file, for one) on stderr while
    # still exiting 1. This catches the loud cases; the quiet ones are recorded
    # as a known gap rather than claimed as covered.
    drafts=$(git grep -In --untracked -E "$draft_re" -- . "$GR_SCAN_EXCLUDE")
    _st=$?
    [ "$_st" -le 1 ] || gr_die "scanning for draft IDs failed (git grep exit $_st)"
    if [ -n "$drafts" ]; then
        printf '%s\n' "$drafts" | sed 's/^/DRAFT-ID /'
        fail=1
    fi

    # DRAFT-FILE: no draft-named ledger files may remain either
    draft_files=$(git ls-files --cached --others --exclude-standard 2>/dev/null \
        | grep -E '(^|/)DRAFT-[^/]*$' || true)
    if [ -n "$draft_files" ]; then
        printf '%s\n' "$draft_files" | sed 's/^/DRAFT-FILE /'
        fail=1
    fi
fi

# --- DUPLICATE-ID: a final ID defined at more than one site in the tree ---
dups=$(git grep -h --untracked -oE "$def_re" -- . "$GR_SCAN_EXCLUDE" 2>/dev/null \
    | sed 's/[*:]//g' | sort | uniq -d)
for id in $dups; do
    echo "DUPLICATE-ID $id (defined more than once in tree)"
    fail=1
done

# --- DUPLICATE-ID vs base: newly defined here, already defined on REF ---
# A base the caller NAMED but that does not resolve is an error: they asked for
# this gate and would otherwise get a silent pass.
if [ -n "$base_named" ]; then
    git rev-parse --verify -q "$base" >/dev/null 2>&1 \
        || gr_die "--base is not a valid ref: $base"
fi

# A base that was DETECTED but does not resolve is not the caller's mistake and
# must not be fatal: gr_base_branch reports the branch name from the worktree
# list, which exists before its first commit, so a fresh repo would otherwise
# abort with a complaint about a --base nobody passed. Treat it exactly like an
# undetected base.
if [ -n "$base" ] && ! git rev-parse --verify -q "$base" >/dev/null 2>&1; then
    base=""
fi

# An undetected base is not an error either — a detached HEAD is what a normal
# CI checkout produces, and finalize-ids.sh is not run there. But it must not be
# silent: this gate simply does not run, and a run that skipped a gate must say
# so rather than look like a run that passed it.
if [ -z "$base" ]; then
    echo "SKIPPED-DUPLICATE-BASE (no usable base branch — pass --base REF to enable this gate)"
fi

if [ -n "$base" ]; then
    mb=$(git merge-base "$base" HEAD 2>/dev/null) || mb="$base"
    # git diff's failure must not read as "nothing was added": that is the
    # whole gate passing vacuously. Status checked, not swallowed.
    _d=$(git diff "$mb") || gr_die "cannot diff against $mb"
    # grep -o, not grep: without it these harvested every ID on a definition
    # line, not the one the line defines. An ordinary problem report reading
    # "**PR-090**: a new problem caused by REQ-001." was therefore read as
    # newly defining REQ-001 as well, and reported as a duplicate of the
    # requirement it names — a false red blocking a legitimate merge. The
    # definition form itself already ends at the colon, so matching only the
    # form leaves exactly the declared ID behind.
    added=$(printf '%s\n' "$_d" | grep -oE "$(gr_def_re "$P" '^\+')" \
        | grep -oE "$id_re" | sort -u || true)
    removed=$(printf '%s\n' "$_d" | grep -oE "$(gr_def_re "$P" '^-')" \
        | grep -oE "$id_re" | sort -u || true)
    for id in $added; do
        # gr_contains, not `case " $removed "`: $removed comes from sort -u and
        # is newline-separated, so the space-delimited form could only ever match
        # a single-element set. Relocating two definitions in one change reported
        # both as duplicates of themselves — a false red with no way forward but
        # the hand-editing merge-change forbids.
        gr_contains "$removed" "$id" && continue
        # Same pathspec as finalize-ids.sh's max_final scan. Without the
        # exclusion this gate sees a definition under .guardrails/ that
        # finalize-ids deliberately ignores, so finalize mints an ID this
        # rejects as a duplicate — two gates of one sequence disagreeing, with
        # no way forward but the hand-editing merge-change forbids.
        #
        # The pattern is NOT the same: this one carries a literal ID, so it
        # cannot come from gr_def_re. It anchors by hand and must stay in step
        # with it. An earlier version of this comment claimed the two scans
        # matched outright; the pathspecs did, the regexes did not, and the
        # sentence made the drift that caused this change harder to see. What
        # keeps them in step now is a test, not a comment: "an indented
        # definition on the base is not something to collide with".
        if git grep -qE "^\\*\\*${id}\\*\\*:" "$base" \
                -- . "$GR_SCAN_EXCLUDE" 2>/dev/null; then
            echo "DUPLICATE-ID $id (already defined on $base)"
            fail=1
        fi
    done
fi

# --- UNANCHORED-DEF: a definition form off column one, holding a number up ---
# Reported, never fatal. Anchoring finalize-ids.sh's max_final was the right
# fix, but it narrowed what holds the mint ceiling up: a project that had such a
# token was reserving that number without knowing, and now the number can be
# re-minted. No duplicate gate would catch that, because they all anchor too.
#
# Only tokens ABOVE the ceiling are reported, and that is the point rather than
# a nicety. Measured on a real 300-item repository first: reporting every
# off-column token gave nine lines, all ordinary prose ("Resolves **PR-006**:
# ...") and not one of them reserving anything. A line that fires on every run
# of a healthy project is a line nobody reads.
#
# The ceiling is taken over the base ref AND the worktree, because that is what
# finalize-ids.sh mints from. Over the worktree alone this gate named a ceiling
# the toolchain contradicted one command later — two gates with two ceilings,
# which is the defect class this whole change exists to end.
#
# Known limit, stated rather than papered over: candidates come from the
# worktree only. A token that exists on the base and is DELETED by this change
# stops reserving its number without a word here. Reporting it was judged wrong
# rather than merely hard — the change deleted it deliberately.
#
# One grep and one awk, deliberately. Per-file awk forks cost 12 of 18 seconds
# on a 4000-item tree, and handing awk a path as an operand made a quoted
# non-ASCII filename fatal: the scan skipped that file and still exited 0,
# which is the false green this toolkit exists to prevent. Nothing here opens a
# file by name. Not '^.+' either — git's matcher backtracks on a leading .+, at
# a cost of tens of seconds per prefix (the verification record carries the
# measurement and the corpus commit it was taken on; a bare number here could
# not be re-derived and drifted into three different values).
# The ceiling scan of the base ref reads blobs and costs more than the worktree
# scan — 1.4s to 4.4s on a 300-item project when it ran unconditionally. It is
# only ever needed to RAISE the ceiling, so a candidate that does not clear the
# cheap worktree ceiling cannot clear the combined one either. Judge against the
# worktree first; consult the base only if something survived that.
_ua_awk='
    BEGIN {
        # Every declared prefix starts at 0, so the first ever item of a prefix
        # is still reported when prose reserved a number ahead of it. Split the
        # alternation the shell already validated rather than calling back into
        # the config: one fork per candidate file was the bulk of this section.
        n = split(declared, d, "|")
        for (i = 1; i <= n; i++) if (d[i] != "") max[d[i]] = 0
        # With no usable base the ceiling covers this tree alone, while
        # finalize-ids mints from max(base, worktree) — so the line must not assert a
        # ceiling it never checked. Round 1 rejected exactly that claim; round 2
        # found it surviving on the detached-HEAD path, which is what a normal
        # CI checkout produces.
        tail = consulted \
            ? "the highest one defined, so it was reserving that number" \
            : "the highest one defined in this tree; the base ref was not " \
              "consulted, so this may be a false alarm"
        n = split(maxes, rows, "\n")
        for (i = 1; i <= n; i++) if (rows[i] != "") {
            split(rows[i], kv, "\t")
            max[kv[1]] = kv[2]
            # The ID as written, not the number: a ceiling reported as PR-86
            # names an item that does not exist under that spelling.
            top[kv[1]] = kv[3]
        }
    }
    # git grep -nz frames each hit as path\0line\0text and the caller turns the
    # NULs into newlines, so one record is three lines. Splitting path:line:text
    # on colons instead let a path containing one donate its tail to the line
    # number, which then vanished from the report while the location happened to
    # reassemble. The NUL cannot be carried in an awk -v value — execve
    # arguments are NUL-terminated — so the framing is converted, not passed.
    NR % 3 == 1 { loc = $0; next }
    NR % 3 == 2 { ln  = $0; next }
    {
        rest = $0

        # No need to skip past a real definition opening the line: it is one of
        # the definitions the ceiling is the maximum OF, so it can never exceed
        # it and can never be reported. An earlier version stripped it anyway;
        # mutation testing showed removing the strip reddened nothing, which is
        # what dead code looks like.
        while (match(rest, /\*\*[A-Za-z][A-Za-z0-9]*-[0-9][0-9][0-9]+\*\*:/)) {
            tok = substr(rest, RSTART, RLENGTH)
            rest = substr(rest, RSTART + RLENGTH)
            id = tok; sub(/^\*\*/, "", id); sub(/\*\*:$/, "", id)
            num = id; sub(/^.*-/, "", num)
            pfx = id; sub(/-[^-]*$/, "", pfx)
            if (!(pfx in max)) continue
            if (num + 0 > max[pfx] + 0)
                printf "UNANCHORED-DEF %s (%s:%s — above %s, %s)\n", \
                    id, loc, ln, (pfx in top ? top[pfx] : pfx "-none"), tail
        }
    }'

# ceilings PATTERN_SOURCE — highest ID per prefix, as "prefix<TAB>n<TAB>id".
ceilings() {
    awk 'NF { id = $0; sub(/^\*\*/, "", id); sub(/\*\*:$/, "", id)
              n = id; sub(/^.*-/, "", n)
              p = id; sub(/-[^-]*$/, "", p)
              if (n + 0 > m[p] + 0) { m[p] = n + 0; t[p] = id } }
         END { for (p in m) printf "%s\t%d\t%s\n", p, m[p], t[p] }'
}

# candidates — every line carrying the definition form off column one, framed
# by git as path\0line\0text and converted to three lines. NOT captured into a
# variable: command substitution drops NUL bytes, which is what made the
# colon-splitting necessary in the first place. Called twice in the rare
# two-stage case rather than buffered, because a temp file here would need
# cleanup on every exit path.
# -z does two jobs here: it frames the fields with NULs, and it stops git
# quoting a non-ASCII path — so no core.quotePath override is needed, and one
# was carried here for a while doing nothing. Mutation testing found it: with
# the flag removed, nothing reddened.
candidates() {
    git grep -nIz --untracked -E "$(gr_def_re "$P" '')" \
        -- . "$GR_SCAN_EXCLUDE" 2>/dev/null | tr '\000' '\n'
}

# Probed outside a pipeline so that a git failure is a failure rather than a
# quiet "found nothing" — which is exactly what a clean tree looks like.
git grep -qI --untracked -E "$(gr_def_re "$P" '')" \
    -- . "$GR_SCAN_EXCLUDE" 2>/dev/null
_st=$?
[ "$_st" -le 1 ] || gr_die "UNANCHORED-DEF scan failed (git grep exit $_st)"

if [ "$_st" -eq 0 ]; then
    # A path containing a newline breaks the three-line framing wholesale.
    # Detected on the paths themselves rather than inside awk: the awk check
    # asked whether a record's second line was numeric, which catches a path
    # carrying ONE newline and misses one carrying three — six lines is two
    # whole records, so the framing realigns and the scan reported a location
    # that does not exist.
    #
    # Only the files this scan will actually read can break its framing, so ask
    # git for those rather than for the whole tree: -lz lists them raw and
    # NUL-separated, and every newline in that stream came from inside a name.
    _nlpaths=$(git grep -lIz --untracked -E "$(gr_def_re "$P" '')" \
        -- . "$GR_SCAN_EXCLUDE" 2>/dev/null | tr -dc '\n' | wc -c)
fi

if [ "$_st" -eq 0 ] && [ "${_nlpaths:-0}" -gt 0 ]; then
    echo "UNANCHORED-DEF-UNREADABLE (a path this scan must read contains a newline, which it cannot frame — no off-column definitions were judged)"
elif [ "$_st" -eq 0 ]; then
    _tree=$(git grep -h --untracked -oE "$(gr_def_re "$P")" \
        -- . "$GR_SCAN_EXCLUDE" 2>/dev/null)
    _st=$?
    [ "$_st" -le 1 ] || gr_die "ceiling scan failed (git grep exit $_st)"

    _hits=$(candidates \
        | awk -v maxes="$(printf '%s\n' "$_tree" | ceilings)" -v declared="$P" \
              -v consulted="$([ -n "$base" ] && echo 1 || echo 0)" "$_ua_awk")

    # The base ceiling reads blobs and costs more than the worktree scan. It can
    # only ever RAISE the ceiling, so a candidate that fails to clear the cheap
    # one cannot clear the combined one either: consult it only for survivors.
    if [ -n "$_hits" ] && [ -n "$base" ]; then
        _ref=$(git grep -h -oE "$(gr_def_re "$P")" "$base" \
            -- . "$GR_SCAN_EXCLUDE" 2>/dev/null)
        _st=$?
        [ "$_st" -le 1 ] || gr_die "ceiling scan of $base failed (git grep exit $_st)"
        _hits=$(candidates \
            | awk -v maxes="$(printf '%s\n%s\n' "$_tree" "$_ref" | ceilings)" \
                  -v declared="$P" -v consulted=1 "$_ua_awk")
    fi

    [ -z "$_hits" ] || printf '%s\n' "$_hits"
fi

exit $fail
