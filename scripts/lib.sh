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
