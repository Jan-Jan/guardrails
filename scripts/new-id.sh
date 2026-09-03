#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# new-id.sh PREFIX [COUNT]
#
# Prints COUNT (default 1) freshly minted item IDs for PREFIX, one per line.
# The ID is minted once, when the item is written, and never recomputed — it
# is deliberately NOT a content hash, which would change under an edit and
# break every `verifies:` and `traces:` reference pointing at it.
#
# Nothing allocates these against a base branch, which is the whole point:
# two worktrees, or two GitHub PRs, mint independently and never contend.
#
# Collisions are DETECTED, not prevented. A candidate already present anywhere
# in this tree — tracked or untracked, definition or reference — is discarded
# and another drawn. A collision with an ID that exists only on another branch
# cannot be seen from here; it is caught by DUPLICATE-ID in check-ids.sh, which
# merge-change runs after it has merged the base branch into the worktree.
# At a thousand items the probability of one is under 0.1%, and the failure
# mode is a loud red rather than a wrong ID.
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

# A misspelled key, a BOM, a prefix whose gates are unconfigured: every one of
# them makes some gate skip in silence, and an ID minted into such a project is
# an ID nothing will ever check. Refuse before handing one out.
gr_check_config

prefix="${1:-}"
[ -n "$prefix" ] || gr_die "usage: new-id.sh PREFIX [COUNT]"
count="${2:-1}"
[ $# -le 2 ] || gr_die "unknown argument: $3"

# An undeclared prefix produces an ID no gate is keyed on: DANGLING-REF,
# DUPLICATE-ID and MALFORMED-ID all iterate over id_prefixes, so the item would
# be written, referenced, and never once examined.
gr_contains "$(gr_prefixes || exit 2)" "$prefix" \
    || gr_die "$prefix is not declared in id_prefixes"

case "$count" in
    (''|*[!0-9]*) gr_die "COUNT must be a positive integer: $count" ;;
esac
[ "$count" -ge 1 ] || gr_die "COUNT must be a positive integer: $count"

# The alphabet and the digit set are DERIVED from the library's classes, never
# retyped. A second spelling of the alphabet here is a second opinion about
# what an ID is, and the generator would drift from the matcher without a
# single test going red — the drawn IDs would simply stop matching.
alphabet=$(printf '%s' "$GR_ID_ANY" | tr -d '[]')
digits=$(printf '%s' "$GR_ID_DIGIT" | tr -d '[]')

urandom="${GR_ID_URANDOM:-/dev/urandom}"
# A FIFO is refused outright rather than read. The bounded read below cannot
# help there: the shell blocks in open() on a FIFO with no writer, before dd
# runs at all, and a FIFO with an idle writer blocks in read(). Neither is a
# plausible entropy source, and both hang the merge step that calls this.
[ ! -p "$urandom" ] || gr_die \
"$urandom is a FIFO — refusing to read it for randomness.
  Reading it would block until something writes, which for a merge step means
  hanging rather than failing. Point GR_ID_URANDOM at a character device or a
  regular file."
[ -r "$urandom" ] || gr_die \
"no entropy source at $urandom — refusing to mint an ID.
  The obvious fallback, the pid and the clock, is a predictable generator
  wearing a random one's clothes: two agents starting in the same second would
  draw the same token by construction. Set GR_ID_URANDOM if the device lives
  elsewhere."

# GR_ID_FORCE_TOKEN wedges the draw to one value. TEST-ONLY: it is how the
# collision and give-up paths are reached without a 10^8 loop. It is not a way
# to choose an ID — hand-picking one is what this whole scheme abolishes.
draw() {
    if [ -n "${GR_ID_FORCE_TOKEN:-}" ]; then
        printf '%s' "$GR_ID_FORCE_TOKEN"
        return 0
    fi
    # tr -dc IS the rejection sampling: bytes outside the alphabet are dropped
    # rather than folded onto it, so no symbol is more likely than another.
    #
    # A BOUNDED read, and dd first: `tr < "$urandom" | dd count=6` reads until
    # six usable bytes appear, which never happens on a source that is readable
    # but yields nothing usable — /dev/zero, /dev/null, a directory, a short
    # regular file. The [ -r ] guard above passes for all of them, and
    # new-id.sh hung forever. Reading one block instead returns on EOF or a
    # short read, and a draw of fewer than six characters is rejected by the
    # length check at the call site like any other malformed one.
    #
    # This bounds the read, NOT the wait. A source that blocks rather than
    # returning short — /dev/random on an entropy-starved host — still waits
    # here, because one dd is still one blocking read(). That is the documented
    # behaviour of such a device and not something to work around without a
    # portable timeout; it is recorded as a gap in the verification record. A
    # FIFO, the other blocking case, is refused above.
    #
    # One 4 KiB
    # block yields ~496 usable characters over the shipped 31-symbol alphabet,
    # and ~32 even over a two-symbol one, so a short draw from a real source is
    # not a case that occurs.
    #
    # dd, not `head -c` — head -c is not in POSIX head, the same reason
    # gr_check_config detects a BOM in awk instead.
    dd bs=4096 count=1 < "$urandom" 2>/dev/null | LC_ALL=C tr -dc "$alphabet" | cut -c1-6
}

minted=""
n=0
while [ "$n" -lt "$count" ]; do
    id=""
    attempt=0
    # Whether ANY draw was a well-formed token. Without it the give-up message
    # below asserted a cause it could not know: a source that yields nothing
    # usable and a tree that holds every candidate are the same "100 attempts"
    # from inside the loop, and the message named only the second.
    drew=0
    while [ "$attempt" -lt 100 ]; do
        attempt=$((attempt + 1))
        tok=$(draw)
        # Length and the digit rule, checked in the shell rather than against
        # GR_ID_TOKEN: a drawn token can only fail these two ways, and a grep
        # per attempt would be a fork per attempt.
        [ "${#tok}" -eq 6 ] || continue
        case "$tok" in
            (*["$digits"]*) ;;
            (*) continue ;;   # ~1 draw in 6 is all letters; REQ-argued is why
        esac
        drew=1
        cand="${prefix}-${tok}"
        gr_contains "$minted" "$cand" && continue
        # Status checked, stderr not suppressed: a scan that errors finds
        # nothing, and "found nothing" is exactly what a free token looks like.
        git grep -q --untracked -F -e "$cand" -- . "$GR_SCAN_EXCLUDE"
        _st=$?
        [ "$_st" -le 1 ] || gr_die "scanning for an existing $cand failed (git grep exit $_st)"
        [ "$_st" -eq 0 ] && continue
        id="$cand"
        break
    done
    if [ -z "$id" ] && [ "$drew" -eq 0 ]; then
        gr_die \
"no usable randomness came out of $urandom in 100 attempts — not one draw was a
  well-formed token. It is readable, so it is not the [ -r ] case; it is a
  source that yields nothing this generator can use. Point GR_ID_URANDOM at a
  real entropy source."
    fi
    [ -n "$id" ] || gr_die \
"could not mint a free $prefix ID in 100 attempts: every well-formed candidate
  was already present in the tree. Either it holds an implausible share of the
  token space, or GR_ID_FORCE_TOKEN is set to a token that is already taken."
    minted="${minted}${id}
"
    printf '%s\n' "$id"
    n=$((n + 1))
done

exit 0
