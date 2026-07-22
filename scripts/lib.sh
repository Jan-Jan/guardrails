#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# guardrails shared helpers — POSIX sh, sourced by the check/finalize scripts.
# Scripts run from the target repo root. GR_CONFIG overrides the config path.

GR_CONFIG="${GR_CONFIG:-.guardrails/config.yaml}"

gr_die() {
    echo "guardrails: $*" >&2
    exit 2
}

gr_root() {
    git rev-parse --show-toplevel 2>/dev/null || gr_die "not inside a git repository"
}

# cfg_get KEY — print the scalar value of a top-level `key: value` entry.
cfg_get() {
    [ -f "$GR_CONFIG" ] || gr_die "config not found: $GR_CONFIG"
    awk -v k="$1" '
        index($0, k ":") == 1 { sub(/^[^:]*:[ \t]*/, ""); print; exit }
    ' "$GR_CONFIG"
}

# cfg_list KEY — print items of a top-level `key:` block of `  - item` lines.
cfg_list() {
    [ -f "$GR_CONFIG" ] || gr_die "config not found: $GR_CONFIG"
    awk -v k="$1" '
        !inlist && index($0, k ":") == 1 { inlist = 1; next }
        inlist && /^[^ \t]/ { exit }
        inlist && /^[ \t]*-[ \t]/ { sub(/^[ \t]*-[ \t]*/, ""); print }
    ' "$GR_CONFIG"
}

# gr_prefix_re — ERE alternation of the configured ID prefixes: REQ|HAZ|RC|SDD
gr_prefix_re() {
    cfg_get id_prefixes | tr ' ' '|'
}

# gr_base_branch — the branch checked out in the primary (non-worktree)
# checkout, which is what a change merges into. Prints nothing if the
# primary checkout is detached; never falls back to a linked worktree's
# branch.
gr_base_branch() {
    git worktree list --porcelain 2>/dev/null | awk '
        /^worktree / { n++ }
        n > 1 { exit }
        sub(/^branch refs\/heads\//, "") { print; exit }
    '
}

# gr_doc_files KEY — resolve a doc_* config value to a file list, one per
# line. A directory yields its *.md files (sorted); a file yields itself;
# missing key or path yields nothing. Lets projects use either a single
# document or a per-change dated ledger directory.
gr_doc_files() {
    _v=$(cfg_get "$1")
    [ -n "$_v" ] || return 0
    if [ -d "$_v" ]; then
        for _f in "$_v"/*.md; do
            [ -f "$_f" ] && printf '%s\n' "$_f"
        done
    elif [ -f "$_v" ]; then
        printf '%s\n' "$_v"
    fi
    return 0
}
