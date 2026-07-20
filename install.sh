#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# install.sh [--copy]
#
# Installs the guardrails skills into the agent's skills directory
# (default: ~/.claude/skills, override with CLAUDE_SKILLS_DIR).
# Symlinks by default so `git pull` updates them; --copy for a static copy.
# Refuses to clobber anything that isn't a symlink it would replace.
set -eu

mode=link
[ "${1:-}" = "--copy" ] && mode=copy

src=$(cd "$(dirname "$0")/skills" && pwd)
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
        echo "COPY  $name -> $target"
    else
        ln -s "${skill%/}" "$target"
        echo "LINK  $name -> $target"
    fi
done

echo "Done. Installed guardrails skills into $dest"
