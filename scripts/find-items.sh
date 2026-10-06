#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# find-items.sh list [--kind PREFIX]... [--status open|accepted|resolved]
# find-items.sh show ID
# find-items.sh refs ID
#
# Finds items in the ledgers, so that an agent reads one item and not a whole
# ledger file.
#
#   list  One line per item defined in the doc_* files of this config and,
#         when id_prefixes declares ADR, in the ADR files: docs/adr/ADR-*.md
#         at the repository root and, when GR_CONFIG names a unit, also
#         <unit>/docs/adr/ADR-*.md, in that order. Each line gives the ID,
#         status, file:line of the definition, and the rest of the definition
#         line. The status is the first column-one `status:` line in the item
#         block, the line check-trace.sh reads, or `-` when the block has
#         none. An ADR's `Status:` line is not a `status:` line, so an ADR's
#         status is `-` and --status keeps no ADR. --kind keeps the items of
#         one declared prefix; given more than once, it keeps the items of
#         each prefix it names. --status keeps the items with that status, and
#         is given at most once. An empty --kind or --status is a usage error.
#   show  The block of every definition of ID, each after a line
#         `==> file:line`, with a blank line between two blocks. A block ends
#         where the gates end it, by the shared GR_AWK_ITEM_BLOCK fragment in
#         lib.sh: at a heading, at the next bold line that contains a colon,
#         or at the end of the file. Blank lines at the end of a block are not
#         printed.
#   refs  Every file:line:text in the working tree, tracked or untracked and
#         not ignored, that contains ID as a whole word, except its definition
#         lines. A definition line is one that opens with **ID**:, after an
#         optional byte order mark, in any file: a definition outside the
#         ledgers is not printed either. check-ids.sh reports a second
#         definition as DUPLICATE-ID, and check-trace.sh reports an item
#         defined only outside its ledger as MISPLACED-ITEM. The carriage
#         return of a CRLF line is not printed. Binary files are skipped. It
#         searches the whole repository, not one unit. The output does not
#         follow the user git config: a non-ASCII file name is printed as
#         its bytes, with no column number and no color. git still prints a
#         file name that contains a tab, a newline, a double quote or a
#         backslash in double quotes, with C escapes.
#
# Under a unit manifest, set GR_CONFIG to the unit config, as for the check
# scripts. This script checks nothing: its exit status states whether the
# request was answered, not whether the ledgers are correct.
#
# Exit codes: 0 answered, 1 show found no definition of ID, 2 usage/environment
# error.
set -u

find_items_usage='usage: find-items.sh list [--kind PREFIX]... [--status open|accepted|resolved] | show ID | refs ID'
find_items_remedy='Run find-items.sh list to see the IDs this config defines; an ID defined in another unit needs that unit config in GR_CONFIG.'

. "$(dirname "$0")/lib.sh"
gr_repo_root=$(gr_root) || exit 2
cd "$gr_repo_root" || exit 2
gr_unit_engage
gr_check_config

# A value that contains a literal newline must not reach awk -v, because BWK
# awk exits 2 before the program runs, and grep -x reads it as two patterns.
for find_items_arg in "$@"; do
    case $find_items_arg in
        (*'
'*) gr_die "an argument contains a newline" ;;
    esac
done

[ $# -gt 0 ] || gr_die "$find_items_usage"
subcommand=$1
shift

prefix_re=$(gr_prefix_re) || exit 2

# check_item_id ID: exit 2 unless ID has the shape of an ID under a declared
# prefix.
check_item_id() {
    printf '%s\n' "$1" | grep -Eq "^(${prefix_re})-${GR_ID_BODY}\$" \
        || gr_die "not an item ID under id_prefixes ($prefix_re): $1"
}

# want_kinds is the declared prefixes that --kind names, joined with "|" as
# an awk alternation. Empty means every declared prefix.
want_kinds=""
want_status=""
item_id=""
case $subcommand in
    (list)
        while [ $# -gt 0 ]; do
            case $1 in
                (--kind)
                    [ $# -ge 2 ] || gr_die "$find_items_usage"
                    gr_prefixes | grep -Fqx -e "$2" \
                        || gr_die "--kind takes a prefix declared in id_prefixes ($prefix_re), not: '$2'"
                    want_kinds=${want_kinds:+$want_kinds|}$2
                    shift
                    ;;
                (--status)
                    [ $# -ge 2 ] || gr_die "$find_items_usage"
                    [ -z "$want_status" ] || gr_die "--status is given more than once"
                    case $2 in
                        (open|accepted|resolved) want_status=$2 ;;
                        (*) gr_die "--status takes open, accepted or resolved, not: '$2'" ;;
                    esac
                    shift
                    ;;
                (*) gr_die "unknown argument: $1" ;;
            esac
            shift
        done
        ;;
    (show|refs)
        [ $# -eq 1 ] || gr_die "$find_items_usage"
        item_id=$1
        check_item_id "$item_id"
        ;;
    (*) gr_die "$find_items_usage" ;;
esac

if [ "$subcommand" = refs ]; then
    # git grep excludes the definition lines, not a reader of its output: a
    # file name can contain ":5:", so the file:line: prefix of an output line
    # cannot be split off. A definition line opens with **ID**:, after an
    # optional byte order mark; the trailing .* extends the match to the end
    # of the line, as -w requires. check_item_id admits only letters, digits
    # and "-" in an ID, so the ID is a literal in the pattern.
    #
    # The -c options fix the output form against the user git config:
    # core.quotePath=false prints a non-ASCII file name as its bytes,
    # grep.column=false prints no column number, and color.grep=never prints
    # no color escapes, which color.ui=always would otherwise add. The other
    # grep.* keys do not change this output: -n and -E are given on the
    # command line, grep.fullName changes nothing at the repository root, and
    # grep.fallbackToNoIndex applies only outside a repository.
    byte_order_mark=$(printf '\357\273\277')
    definition_re="^(${byte_order_mark})?[*][*]${item_id}[*][*]:.*"
    refs_status=0
    refs_lines=$(LC_ALL=C git -c core.quotePath=false -c grep.column=false -c color.grep=never \
        grep -n -w -I -E --untracked -e "$item_id" --and --not -e "$definition_re") || refs_status=$?
    case $refs_status in
        (0) ;;
        (1) exit 0 ;;
        (*) gr_die "git grep exited $refs_status searching for $item_id" ;;
    esac
    printf '%s\n' "$refs_lines" | LC_ALL=C awk '{ sub(/\r$/, ""); print }' \
        || gr_die "awk failed reading the git grep output"
    exit 0
fi

ledger_files=""
for doc_key in doc_srs doc_rmf doc_sad doc_soup doc_problems; do
    key_files=$(gr_doc_files "$doc_key") || exit 2
    [ -z "$key_files" ] || ledger_files="$ledger_files$key_files
"
done
# add_adr_files DIRECTORY: appends the ADR-*.md files in DIRECTORY to
# ledger_files. DIRECTORY is quoted, so a blank or a glob character in it is
# literal. An unmatched pattern stays literal and a directory can match, so
# each path is tested to be a regular file.
add_adr_files() {
    for adr_file in "$1"/ADR-*.md; do
        [ -f "$adr_file" ] || continue
        ledger_files="$ledger_files$adr_file
"
    done
}
# The ADR files are read only when id_prefixes declares ADR. No config key
# names their directory, so the paths are fixed where check-units.sh resolves
# an ADR citation: the root docs/adr/, then the unit's. GR_UNIT, set by
# gr_unit_engage, is the unit's root-relative path, or empty without units.
case "|$prefix_re|" in
    (*'|ADR|'*)
        add_adr_files docs/adr
        [ -z "${GR_UNIT:-}" ] || add_adr_files "$GR_UNIT/docs/adr"
        ;;
esac
# doc_soup is commonly a file inside the doc_sad directory, which gr_doc_files
# resolves to its *.md files, so the same file can be listed twice. Read it
# once, or every item in it is printed twice. The dedupe compares strings, so
# each path is first normalised: repeated "/" become one, and leading "./" are
# removed. A doc_sad of docs/architecture/ yields docs/architecture//soup.md,
# and one of ./docs/architecture yields ./docs/architecture/soup.md. The
# resulting file paths are normalised, not the config values, so that the
# config is read by gr_doc_files alone, and every file:line that list and show
# print states the path in one form.
ledger_files=$(printf '%s' "$ledger_files" | awk '
NF {
    gsub(/\/\/+/, "/")
    while (sub(/^\.\//, "")) {}
    if (!file_count[$0]++) print
}')
# gr_check_config rejects a config whose id_prefixes names no gated prefix,
# and each gated prefix requires a doc_* key, so no test reaches this line.
[ -n "$ledger_files" ] || gr_die "no doc_* key is set in $GR_CONFIG, so there is no ledger to read"

# Split the file list on newlines alone, so that a path with a space is one
# argument, and turn pathname expansion off so that a path is not expanded a
# second time.
IFS='
'
set -f
set -- $ledger_files

if [ "$subcommand" = list ]; then
    list_prefix_re=${want_kinds:-$prefix_re}
    LC_ALL=C awk -v body="$GR_ID_BODY" -v prefixes="$list_prefix_re" -v want_status="$want_status" "$GR_AWK_ITEM_BLOCK"'
function list_flush() {
    if (cur != "" && (want_status == "" || status_value == want_status))
        printf "%s %s %s:%d %s\n", cur, (status_value == "" ? "-" : status_value), def_file, def_line, title
    cur = ""
}
BEGIN { gr_block_init(prefixes, body) }
FNR == 1 { list_flush(); sub(/^\357\273\277/, "") }
{ line = $0; sub(/\r$/, "", line) }
gr_block_closes(line) {
    list_flush()
    status_value = ""
    has_status = 0
    if (gr_block_opens(line)) {
        cur = gr_block_id(line)
        def_file = FILENAME
        def_line = FNR
        title = line
        sub(/^\*\*[^*]*\*\*:[ \t]*/, "", title)
    }
    next
}
cur != "" && !has_status && gr_kw_here(line, "status:") { has_status = 1; status_value = gr_value(line, "status:") }
END { list_flush() }
' "$@" || gr_die "awk failed reading the ledgers"
    exit 0
fi

show_status=0
LC_ALL=C awk -v body="$GR_ID_BODY" -v prefixes="$prefix_re" -v want_id="$item_id" "$GR_AWK_ITEM_BLOCK"'
BEGIN { gr_block_init(prefixes, body) }
FNR == 1 { printing = 0; blank_run = ""; sub(/^\357\273\277/, "") }
{ line = $0; sub(/\r$/, "", line) }
gr_block_closes(line) {
    printing = 0
    blank_run = ""
    if (gr_block_opens(line) && gr_block_id(line) == want_id) {
        if (found_count > 0) print ""
        found_count++
        printing = 1
        printf "==> %s:%d\n", FILENAME, FNR
        print line
    }
    next
}
printing && line ~ /^[ \t]*$/ { blank_run = blank_run line "\n"; next }
printing { printf "%s", blank_run; blank_run = ""; print line }
END { exit (found_count > 0 ? 0 : 1) }
' "$@" || show_status=$?
case $show_status in
    (0) exit 0 ;;
    (1)
        printf 'NOT-FOUND %s\n' "$item_id"
        printf 'fix NOT-FOUND: %s\n' "$find_items_remedy"
        exit 1
        ;;
    (*) gr_die "awk failed reading the ledgers (exit $show_status)" ;;
esac
