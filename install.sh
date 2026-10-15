#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# install.sh [--copy]
#
# Installs the guardrails skills into the agent's skills directory
# (default: ~/.claude/skills, override with CLAUDE_SKILLS_DIR).
# Symlinks by default so `git pull` updates them; --copy for a static copy,
# each with a .guardrails-source file naming this checkout.
# Rejects anything that is not a symlink it would replace.
set -eu

mode=link
[ "${1:-}" = "--copy" ] && mode=copy

root=$(cd "$(dirname "$0")" && pwd)
src="$root/skills"
dest="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
mkdir -p "$dest"

for skill in "$src"/*/; do
    name=$(basename "$skill")
    target="$dest/$name"
    if [ -L "$target" ]; then
        rm "$target"
    elif [ -e "$target" ]; then
        echo "SKIP  $name (exists and is not a symlink — remove it manually to replace)" >&2
        continue
    fi
    if [ "$mode" = copy ]; then
        cp -R "${skill%/}" "$target"
        # A copy has no checkout above it, so it records where it came from;
        # `ratchet` step 0 reads it (PR-783b29).
        printf '%s\n' "$root" > "$target/.guardrails-source"
        echo "COPY  $name -> $target"
    else
        ln -s "${skill%/}" "$target"
        echo "LINK  $name -> $target"
    fi
done

echo "Done. Installed guardrails skills into $dest"
