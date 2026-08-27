#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# check-ids.sh [--allow-draft-files]
#
# Fails (exit 1) on:
#   DRAFT-ID      — a draft ID token (<PREFIX>-DRAFT-<slug>-<n>) anywhere in the
#                   tree. Always fatal: nothing mints one any more, so nothing
#                   would ever turn it into a real ID.
#   DRAFT-FILE    — a draft-named ledger file (DRAFT-<branch>-<slug>.md).
#                   Legitimate inside a change and renamed by finalize-docs.sh
#                   at merge, so --allow-draft-files suppresses it while the
#                   change is in flight.
#   DUPLICATE-ID  — an ID defined (**ID**: ...) at more than one site in the
#                   tree. A definition line declares the ID at its start and no
#                   other, so naming further IDs in the same sentence is safe.
#   MALFORMED-ID  — a line that opens with a definition form for a declared
#                   prefix whose body is not a valid ID: **REQ-abcdef**: with no
#                   digit, or a legacy **REQ-01** too short to have ever
#                   matched. Such a line defines nothing, is referenced by
#                   nothing, and every other gate passes over it in silence.
#
# There is no gate against the base branch, and no --base. IDs are minted at
# item-creation time by new-id.sh and allocated against nothing, so two
# branches cannot mint the same one by construction; the vanishing case where
# random draws collide is caught by DUPLICATE-ID above, because merge-change
# merges the base branch into the worktree (step 1) before running this script
# (step 4). There is likewise no mint ceiling and so no UNANCHORED-DEF: a
# definition form sitting in prose reserves nothing.
#
# Exit codes: 0 pass, 1 violations, 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
# NOT `cd "$(gr_root)" || exit 2`: gr_root's gr_die exits only the command
# substitution, and under dash `cd ""` returns 0 and stays put — so outside a
# git repository the script carried on in the caller's directory with a
# relative config path. The status has to be taken from the substitution.
gr_repo_root=$(gr_root) || exit 2
cd "$gr_repo_root" || exit 2

# This gate validated nothing about the config until change B — recorded as gap
# 3 in docs/verification/2026-08-18-config-schema.md. It reads only
# id_prefixes, so the omission looked harmless; it was not. Every shape
# gr_check_config exists to refuse — a misspelled key, a key hidden behind a
# BOM, a declared prefix whose gate inputs are unconfigured — was caught by the
# traceability and finalize gates only, so a project running check-ids.sh alone
# got no config validation at all.
gr_check_config

allow_draft_files=0
while [ $# -gt 0 ]; do
    case "$1" in
        --allow-draft-files) allow_draft_files=1 ;;
        # --allow-drafts and --base are refused, not ignored. Both named a gate
        # that no longer exists, and a flag accepted in silence is a check the
        # caller believes they configured. Failing here is what makes a stale
        # CI line or an un-upgraded skill visible at the upgrade.
        *) gr_die "unknown argument: $1" ;;
    esac
    shift
done

# gr_prefix_re validates each prefix as a bare identifier and dies otherwise;
# the die happens in a subshell here, so propagate it. An unvalidated
# metacharacter would make every pattern below an invalid ERE, git grep would
# error, match nothing, and this script would report a clean tree.
P=$(gr_prefix_re) || exit 2
[ -n "$P" ] || gr_die "id_prefixes not configured"

# Deliberately NOT limited to the configured prefixes: a draft whose prefix is
# absent from id_prefixes is one nothing was ever going to mint, which is
# exactly the case that must not reach the base branch.
draft_re="[A-Za-z][A-Za-z0-9]*-DRAFT-[A-Za-z0-9][A-Za-z0-9-]*-[0-9]+"
def_re=$(gr_def_re "$P")
fail=0

# --- DRAFT-ID: no draft identifiers may remain, under any flag --------------
# Status checked, stderr not suppressed. A scan that errors finds nothing, and
# "found nothing" is what a clean tree looks like.
#
# Defence in depth only, and honestly weak: git grep exits >1 for some failures
# but reports others (an unreadable file, for one) on stderr while still
# exiting 1. This catches the loud cases; the quiet ones are recorded as a
# known gap rather than claimed as covered.
drafts=$(git grep -In --untracked -E "$draft_re" -- . "$GR_SCAN_EXCLUDE")
_st=$?
[ "$_st" -le 1 ] || gr_die "scanning for draft IDs failed (git grep exit $_st)"
if [ -n "$drafts" ]; then
    printf '%s\n' "$drafts" | sed 's/^/DRAFT-ID /'
    echo "guardrails: draft IDs are no longer minted — an item gets its final ID" >&2
    echo "when it is written. Run .guardrails/scripts/new-id.sh <PREFIX> and replace" >&2
    echo "each token above with the ID it prints." >&2
    fail=1
fi

# --- DRAFT-FILE: no draft-named ledger files may reach the base branch ------
if [ "$allow_draft_files" -eq 0 ]; then
    draft_files=$(git ls-files --cached --others --exclude-standard 2>/dev/null \
        | grep -E '(^|/)DRAFT-[^/]*$' || true)
    if [ -n "$draft_files" ]; then
        printf '%s\n' "$draft_files" | sed 's/^/DRAFT-FILE /'
        fail=1
    fi
fi

# --- MALFORMED-ID: a definition form whose body is not an ID ----------------
# The scheme change opened this hole. While drafts existed, the final ID was
# written by finalize-ids.sh and was well formed by construction; now a person
# types it. `**REQ-abcdef**:` matches no pattern in the toolkit, so the item it
# announces is invisible to every gate while the run still exits 0 — the exact
# false green this project exists to remove.
#
# Anchored to the DECLARED prefixes so that ordinary bold markdown and another
# project's conventions (**ADR-abcdef**:) are left alone, and to column one so
# that a definition form quoted in prose is treated the same way a well-formed
# one in prose is: as prose.
#
# One scan, not two. git grep composes the two patterns on the LINE — every
# line that opens a definition form, minus every line that opens a VALID one —
# so there is nothing to frame and nothing to parse: the surviving lines are
# the violations and are printed as they come. An earlier version harvested the
# forms with -o and then searched for each one literally to find its location,
# which reported every line that MENTIONED a malformed form, not the lines that
# opened with one. Measured on a real 1178-file project: one violation, ten
# lines of report.
malformed=$(git grep -nI --untracked -E \
    -e "$(gr_def_re_loose "$P")" --and --not -e "$def_re" \
    -- . "$GR_SCAN_EXCLUDE")
_st=$?
[ "$_st" -le 1 ] || gr_die "MALFORMED-ID scan failed (git grep exit $_st)"
if [ -n "$malformed" ]; then
    printf '%s\n' "$malformed" | sed 's/^/MALFORMED-ID /'
    echo "guardrails: the lines above open with a definition form whose ID is not" >&2
    echo "valid, so no gate can see the item they announce. Give each one an ID from" >&2
    echo ".guardrails/scripts/new-id.sh <PREFIX>." >&2
    fail=1
fi

# --- DUPLICATE-ID: an ID defined at more than one site in the tree ----------
# Status checked and stderr not suppressed, the same rule the two scans above
# follow. This one did neither until independent review found it: a scan that
# errors finds nothing, and "found nothing" is what a clean tree looks like.
# NOT a pipeline — `$?` after `x=$(a | b)` is b's status, which here was always
# uniq's 0. Harvest first, check, then reduce.
#
# It matters more since this change than it did before: the duplicate-vs-base
# gate is gone, so this is the only gate left that catches an ID defined twice.
_defs=$(git grep -h --untracked -oE "$def_re" -- . "$GR_SCAN_EXCLUDE")
_st=$?
[ "$_st" -le 1 ] || gr_die "duplicate scan failed (git grep exit $_st)"
dups=$(printf '%s\n' "$_defs" | sed 's/[*:]//g' | sort | uniq -d)
for id in $dups; do
    echo "DUPLICATE-ID $id (defined more than once in tree)"
    fail=1
done

exit $fail
