#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# check-signing.sh [--strict] [REV_RANGE]
#
# Verifies commit signatures. Default scope: HEAD only; pass a rev range
# (e.g. main..feature) to check every commit in it.
#
#   pass            — signature verifies against trusted signers (%G? = G)
#   WARN-UNVERIFIED — signature present but untrusted/unverifiable (%G? = U
#                     or E, e.g. no gpg.ssh.allowedSignersFile); passes
#                     unless --strict
#   UNVERIFIED      — same, under --strict: fails
#   UNSIGNED        — no signature, or a bad signature: fails
#
# Exit codes: 0 pass, 1 violations, 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
cd "$(gr_root)" || exit 2

strict=0
range=""
while [ $# -gt 0 ]; do
    case "$1" in
        --strict) strict=1 ;;
        -*) gr_die "unknown argument: $1" ;;
        *)
            [ -z "$range" ] || gr_die "only one rev range allowed"
            range="$1"
            ;;
    esac
    shift
done

if [ -n "$range" ]; then
    commits=$(git rev-list "$range") || gr_die "bad rev range: $range"
else
    commits=$(git rev-list -1 HEAD) || gr_die "no commits"
fi

fail=0
for c in $commits; do
    gstat=$(git log -1 --format='%G?' "$c")
    case "$gstat" in
        G) ;;
        U|E)
            if [ "$strict" -eq 1 ]; then
                echo "UNVERIFIED $c (signature present but untrusted/unverifiable)"
                fail=1
            else
                echo "WARN-UNVERIFIED $c (signature present but untrusted/unverifiable; configure gpg.ssh.allowedSignersFile or keyring to verify)"
            fi
            ;;
        B|X|Y|R)
            echo "UNSIGNED $c (bad, expired, or revoked signature)"
            fail=1
            ;;
        *)
            if git cat-file commit "$c" | grep -q '^gpgsig'; then
                if [ "$strict" -eq 1 ]; then
                    echo "UNVERIFIED $c (signature present but not verifiable)"
                    fail=1
                else
                    echo "WARN-UNVERIFIED $c (signature present but not verifiable; configure gpg.ssh.allowedSignersFile or keyring to verify)"
                fi
            else
                echo "UNSIGNED $c (no signature)"
                fail=1
            fi
            ;;
    esac
done

exit $fail
