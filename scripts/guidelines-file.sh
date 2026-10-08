#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# guidelines-file.sh KIND PATH...
#
# Prints the one guidelines file that governs each PATH
# (docs/plans/2026-10-08-test-guidelines.md D3, D8), one line per distinct
# file in the order each is first needed:
#
#   <file>: <path> <path>...
#
# the file repository-relative, the paths in argument order. For each path:
#   1. its unit's <unit>/docs/<KIND>_GUIDELINES.md, where .guardrails/units.yaml
#      exists and claims the path (a not_a_unit entry is no unit);
#   2. else the root docs/<KIND>_GUIDELINES.md;
#   3. else the installed default, <KIND>_GUIDELINES.md in the templates/
#      directory beside this script's directory (.guardrails/templates/ in an
#      adopter, templates/ in guardrails itself).
# A unit's file replaces the root's entirely; the two are never merged.
#
# A file is present only where the directory listing holds its exact name, as
# gr_units_present decides: on a case-insensitive filesystem `-f` also accepts
# test_guidelines.md, which is not the project's file.
#
# PATHs are repository-relative, as `git diff --name-only` prints them. It
# reads no config.yaml.
#
# Exit codes: 0 printed, 2 usage error (unknown KIND, no PATH, an absolute
# PATH or one containing whitespace) or a broken install (no installed
# default; checked on every run, before any path is resolved).
set -u

# The kinds this script knows, space-separated.
KNOWN_KINDS='TEST'

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P) || exit 2
. "$script_dir/lib.sh"

guidelines_die() {
    printf '%s\n' "guidelines-file: $*" >&2
    exit 2
}

# The repository root first, before the arguments, as every script does: outside
# a repository the one diagnosis is gr_root's, whatever was passed.
# NOT `cd "$(gr_root)" || exit 2` alone: gr_root's gr_die exits only the
# command substitution, and under dash `cd ""` returns 0 and stays put.
repo_root=$(gr_root) || exit 2
CDPATH= cd -- "$repo_root" || exit 2
repo_root=$(pwd -P) || exit 2

usage='usage: guidelines-file.sh KIND PATH...'
[ $# -ge 1 ] || guidelines_die "$usage"
kind=$1
shift

kind_known=0
for known_kind in $KNOWN_KINDS; do
    [ "$kind" = "$known_kind" ] && kind_known=1
done
[ "$kind_known" -eq 1 ] || guidelines_die "unknown kind: $kind (known: $KNOWN_KINDS)"
[ $# -ge 1 ] || guidelines_die "$usage"

for path in "$@"; do
    case "$path" in
        ('') guidelines_die "empty path; $usage" ;;
        (/*) guidelines_die "path is absolute, not repository-relative: $path" ;;
        (*[[:space:]]*) guidelines_die "path contains whitespace: $path" ;;
    esac
done

guidelines_name="${kind}_GUIDELINES.md"

# has_exact_file DIR NAME — DIR's listing holds NAME, byte for byte.
has_exact_file() {
    [ -f "$1/$2" ] || return 1
    ls "$1" 2>/dev/null | grep -qxF "$2"
}

templates_dir=$(CDPATH= cd -- "$script_dir/../templates" 2>/dev/null && pwd -P) || templates_dir="$script_dir/../templates"
has_exact_file "$templates_dir" "$guidelines_name" \
    || guidelines_die "no installed default: $templates_dir/$guidelines_name — reinstall guardrails"
case "$templates_dir" in
    ("$repo_root"/*) default_file="${templates_dir#"$repo_root"/}/$guidelines_name" ;;
    (*) default_file="$templates_dir/$guidelines_name" ;;
esac

units_present=0
gr_units_present && units_present=1

# governing_file PATH — the file that governs PATH.
governing_file() {
    if [ "$units_present" -eq 1 ]; then
        path_unit=$(gr_unit_of_path "$1") || path_unit=""
        case "$path_unit" in
            ('' | 'not_a_unit '*) ;;
            (*)
                if has_exact_file "$path_unit/docs" "$guidelines_name"; then
                    printf '%s\n' "$path_unit/docs/$guidelines_name"
                    return 0
                fi
                ;;
        esac
    fi
    if has_exact_file docs "$guidelines_name"; then
        printf '%s\n' "docs/$guidelines_name"
        return 0
    fi
    printf '%s\n' "$default_file"
}

# One "<file><TAB><path>" line per path, grouped by file in first-seen order.
for path in "$@"; do
    printf '%s\t%s\n' "$(governing_file "$path")" "$path"
done | awk -F'\t' '
    !($1 in paths) { order[++file_count] = $1; paths[$1] = "" }
    { paths[$1] = paths[$1] " " $2 }
    END { for (index_number = 1; index_number <= file_count; index_number++) print order[index_number] ":" paths[order[index_number]] }
'
