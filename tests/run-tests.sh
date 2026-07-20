#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# Run the guardrails test suite. Uses system bats if present, otherwise
# vendors bats-core into tests/.bats-core (gitignored).
set -eu

dir=$(cd "$(dirname "$0")" && pwd)

if command -v bats >/dev/null 2>&1; then
    BATS=bats
else
    if [ ! -x "$dir/.bats-core/bin/bats" ]; then
        echo "Vendoring bats-core v1.11.0 into tests/.bats-core ..." >&2
        git clone -q --depth 1 --branch v1.11.0 \
            https://github.com/bats-core/bats-core "$dir/.bats-core"
    fi
    BATS="$dir/.bats-core/bin/bats"
fi

exec "$BATS" "$@" "$dir"/*.bats
