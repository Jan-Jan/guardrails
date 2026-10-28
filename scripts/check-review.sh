#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# check-review.sh [--message FILE] [--cite]
#
# The review gate: checks the squash message, which is the change's
# verification record (ADR-k3nkv3), before the hand-over at merge-change
# step 6c. FILE defaults to this worktree's message (gr_message_file in
# lib.sh). The grammar is templates/squash-message.txt; the checker is
# gr_message_check, in lib.sh, given the change branch's HEAD tree and the
# Tests: and Coverage: counts gr_message_want reads from the configuration;
# under a unit manifest, an impact set that cannot be computed is exit 2.
#
# Fails (exit 1) on what that checker reports:
#   MISSING-RECORD FILE — no message, or one of `#` lines only: no record.
#   INCOMPLETE-RECORD (no FIELD:) — reviewer:, verdict: or reproduced:
#       missing, empty or a template <placeholder> in the body: an
#       unclaimed review.
#   INCOMPLETE-RECORD (placeholder in KEY:) — a trailer other than Base:
#       and Gate-tree: still holding a template <placeholder>.
#   UNDISPOSED-FINDING N — a finding with no `[disposition]`, or one still
#       holding a template <placeholder>: unanswered.
#   MALFORMED-FINDING LINE — a line in Findings: that is neither a numbered
#       finding nor a continuation (an indented `<N>. ` line is none), or a
#       repeated number: a lost finding; or
#       a finding whose tag is not code, requirement or guideline with a
#       severity high, medium or low, or record with none, then ` — `.
#   BASE (...) — not exactly one Base: trailer, or one empty or holding a
#       template <placeholder>.
#   GATE-TREE (...) — not exactly one Gate-tree: trailer naming this tree:
#       the gate figures are for another tree.
#   TESTS (...) — Tests: trailers other in number than the verify_commands
#       entries, summed under a manifest over the units of the impact set
#       (check-units.sh --impact from the merge base); a placeholder one is
#       not counted.
#   FAILED-TESTS VALUE — a Tests: trailer not passed/total in full.
#   COVERAGE (...) — Coverage: trailers other in number than the
#       coverage_command entries, summed as TESTS sums them; a placeholder
#       one is not counted.
#   MALFORMED-MUTATION VALUE — a Mutation: trailer not in the template's form.
#   RESOLVES (...) — a PR item the change deletes from the problem ledgers
#       (gr_deleted_items over the base branch...HEAD) that no Resolves:
#       trailer names, or a Resolves: ID the change does not delete.
#   PROBLEMS (...) — a PR item the change deletes that the Problems: section
#       does not name.
#   ITEMS (...) — a REQ, LLR, SDD, HAZ or RC item the change deletes from
#       the doc_srs, doc_sad or doc_rmf ledgers that the Items: section does
#       not name.
# and, with citation checking on:
#   UNRESOLVABLE-DISPOSITION N — the disposition cites no path in the tree,
#       test name in test_paths or defined item ID, and is not
#       `no change: <reason>`: a repair nobody can check.
#   UNRESOLVABLE-MUTATION VALUE (...) — a Mutation: trailer whose path is no
#       file in the tree, or whose test no file in test_paths declares.
#
# Citation checking is on with `--cite` or `review_cite: on`. It is refused
# under a unit manifest: test paths and ID ledgers belong to units, and the
# message to the repository. A disposition is the text inside the leading
# `[...]` of its finding's line. A citation is a token or a backtick span
# naming a regular file, not a symlink, that git lists as tracked or as
# untracked and not ignored (a markdown link is read as its target, and
# punctuation, a `#anchor`, a possessive, a git `<rev>:` prefix and one `:N`
# or `:N-M` are stripped); a backtick or double-quoted span that a file
# matched by a test_paths pathspec declares as a test's name; an ID
# find-items.sh show finds; or, for a `record` finding only, `message`.
#
# This gate judges the record's form, never the review's quality: a field
# holding a placeholder reads as missing, and a Tests: figure that is not
# passed/total in full fails, but whether the review was any good is not read.
#
# Every run ends with `checked: message FILE, findings N`. A detached HEAD and
# the base branch are no change under review: exit 2.
#
# Exit codes: 0 pass, 1 violations, 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
# Taken before the cd below: $0 may be relative to the caller's directory, and
# citation checking runs find-items.sh from beside this script.
review_script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || exit 2
caller_dir=$(pwd)
# The status of gr_root is taken from the substitution: its gr_die exits only
# the subshell, and under dash `cd ""` returns 0 and stays put.
gr_repo_root=$(gr_root) || exit 2
cd "$gr_repo_root" || exit 2

# The message is repository-level: one change, one squash, whatever units it
# touched. A manifest repository has no root config; its manifest is
# validated in its place.
if gr_units_present; then
    gr_check_units
else
    gr_check_config
fi

message=""
cite_flag=0
while [ $# -gt 0 ]; do
    case "$1" in
        (--message)
            shift
            [ $# -gt 0 ] || gr_die "--message needs a file"
            message="$1" ;;
        (--cite) cite_flag=1 ;;
        (*) gr_die "unknown argument: $1" ;;
    esac
    shift
done
if [ -z "$message" ]; then
    message=$(gr_message_file) || exit 2
else
    case "$message" in
        (/*) ;;
        (*) message="$caller_dir/$message" ;;
    esac
fi

# Is citation checking on? cfg_get cannot tell an absent key from an empty
# one, so the file is asked first whether the key is there.
cite_on=0
if gr_units_present; then
    [ "$cite_flag" -eq 0 ] || gr_die \
"--cite is refused in multi-unit repositories: the review record is
  repository-level, while test paths and ID ledgers belong to units, so a
  citation has no one tree to resolve against."
else
    cite_setting=off
    if grep -q '^review_cite:' "$GR_CONFIG"; then
        cite_setting=$(cfg_get review_cite) || exit 2
    fi
    case "$cite_setting" in
        (on) cite_on=1 ;;
        (off) ;;
        (*) gr_die "review_cite in $GR_CONFIG is '$cite_setting'; it takes on or off." ;;
    esac
    [ "$cite_flag" -eq 0 ] || cite_on=1
fi

# What a citation resolves against, read only when citations are checked.
# gr_check_config has already required id_prefixes; with no test_paths no
# span is a test name.
cite_id_re=""
cite_test_paths=""
if [ "$cite_on" -eq 1 ]; then
    cite_prefix_re=$(gr_prefix_re) || exit 2
    cite_id_re="^(${cite_prefix_re})-${GR_ID_BODY}\$"
    if grep -q '^test_paths:' "$GR_CONFIG"; then
        cite_test_paths=$(cfg_list test_paths) || exit 2
    fi
fi

# Which change is under review? Where there is none, a pass would answer a
# question nobody asked, so a detached HEAD and the base branch are exit 2.
base=$(gr_base_branch) || gr_die \
"git worktree list failed, so the base branch cannot be read."
branch=$(git branch --show-current) || gr_die \
"git branch --show-current failed, so the change branch cannot be read; git's
  error is above."
[ -n "$branch" ] || gr_die \
"HEAD is detached, so no change branch can be identified.
  Check out the change branch and run this from its worktree."
[ -n "$base" ] || gr_die \
"the base branch cannot be determined (the primary checkout is detached)."
[ "$branch" != "$base" ] || gr_die \
"HEAD is the base branch ($base), so there is no change under review here.
  This gate runs in the change's worktree, at merge-change step 6c."
tree=$(git rev-parse 'HEAD^{tree}') || gr_die "cannot read the tree of HEAD"

# Under a unit manifest the trailers owed are those of the impact set from the
# merge base with the base branch (three dots), the units merge-change gates
# (check-units.sh --impact): a base commit made after the fork adds no unit,
# and a change already squashed onto the base still owes its own.
impact_units=""
if gr_units_present; then
    impact_units=$(gr_impact_units "$review_script_dir" "refs/heads/$base...HEAD") || exit 2
fi
tests_want=$(gr_message_want verify_commands "$impact_units") || exit 2
coverage_want=$(gr_message_want coverage_command "$impact_units") || exit 2
# The items the change deletes, PR items among them, from the merge base as
# above: its Resolves: and Problems: name each deleted PR, its Items: each
# other deleted item (ADR-3hsvvq).
deleted=$(gr_deleted_items "refs/heads/$base...HEAD") || gr_die \
"the items this change deletes cannot be read from the ledgers' diff over
  refs/heads/$base...HEAD; the error is above."

fail=0
gr_message_check "$message" "$tree" "$tests_want" "$coverage_want" "$deleted"
case $? in
    (0) ;;
    (1) fail=1 ;;
    (*) gr_die "the squash message check could not run on $message" ;;
esac

# CITE_SCAN — read the facts gr_message_facts (lib.sh) prints and, for each
# finding with a disposition, print one fact per line for the shell to judge:
#
#   D <N>           the finding, by its number
#   X               the disposition resolves without a lookup: it is the
#                   `no change: <reason>` escape, or a record finding citing
#                   `message`
#   C <token>       a token shaped like a path or an item ID
#   S <span>        a backtick or double-quoted span, a candidate test name
CITE_SCAN='
# Each span between paired QUOTE characters is a candidate test name: the
# backtick form and the double-quoted prose form both cite one. A backtick span
# is a path candidate too, stripped whole, so a path with a space in it can be
# cited. Quotes pair left to right, as CommonMark pairs backticks, so a span
# here is a span on the rendered page; an unpaired last quote opens nothing.
function gr_cite_spans(text, quote,   rest, open_at, close_at, span, path) {
    rest = text
    while ((open_at = index(rest, quote)) > 0) {
        rest = substr(rest, open_at + 1)
        close_at = index(rest, quote)
        if (close_at == 0) break
        span = substr(rest, 1, close_at - 1)
        if (span != "") print "S " span
        if (quote == "`") {
            path = gr_cite_strip(span)
            if (path != "" && gr_cite_path_shaped(path)) print "C " path
        }
        rest = substr(rest, close_at + 1)
    }
}
function gr_cite_strip_end(token) {
    while (token != "" && index("`\"\047)]>.,;:!?", substr(token, length(token), 1)) > 0)
        token = substr(token, 1, length(token) - 1)
    return token
}
# A markdown link keeps only its target, the text after `](`. Then quotes and
# brackets off both ends, then a `#anchor` suffix off a path candidate, then
# one possessive apostrophe-s (the straight apostrophe or the right single
# quote, U+2019) and the end set again, then a git `<rev>:` prefix of 7 to 40
# lowercase hex digits, then one `:N` or `:N-M`, then the end set once more.
# `scripts/x.sh:12`., `[the guard](scripts/x.sh#L3-L9)`, a backticked
# scripts/x.sh with a possessive after it, and `650f090:scripts/x.sh` all read
# as scripts/x.sh. No apostrophe in this comment: it sits in single quotes.
function gr_cite_strip(token,   position, length_now, rev) {
    position = index(token, "](")
    if (position > 0) token = substr(token, position + 2)
    while (token != "" && index("`\"\047([<", substr(token, 1, 1)) > 0)
        token = substr(token, 2)
    token = gr_cite_strip_end(token)
    position = index(token, "#")
    if (position > 0 && gr_cite_path_shaped(substr(token, 1, position - 1)))
        token = gr_cite_strip_end(substr(token, 1, position - 1))
    length_now = length(token)
    if (length_now > 2 && substr(token, length_now - 1) == "\047s")
        token = gr_cite_strip_end(substr(token, 1, length_now - 2))
    else if (length_now > 4 && substr(token, length_now - 3) == "\342\200\231s")
        token = gr_cite_strip_end(substr(token, 1, length_now - 4))
    position = index(token, ":")
    if (position >= 8 && position <= 41) {
        rev = substr(token, 1, position - 1)
        if (rev ~ /^[0-9a-f]+$/) token = substr(token, position + 1)
    }
    for (position = length(token); position > 0; position--)
        if (substr(token, position, 1) == ":") break
    if (position > 0 && substr(token, position + 1) ~ /^[0-9]+(-[0-9]+)?$/)
        token = substr(token, 1, position - 1)
    return gr_cite_strip_end(token)
}
# A token holding a `/` or a `.` may name a file. Whether it does is decided in
# the shell, against the files git lists, so an absolute path, a `..` path, a
# URL and anything under `.git` resolve nothing without a test here.
function gr_cite_path_shaped(token) {
    return index(token, "/") > 0 || index(token, ".") > 0
}
# Judge one disposition, byte-wise: substr and index, no negated bracket
# expression.
function gr_cite_judge(text, tag,   escape, reason, count, parts, part_at, token) {
    escape = "no change:"
    if (substr(text, 1, length(escape)) == escape) {
        reason = substr(text, length(escape) + 1)
        gsub(/[ \t]/, "", reason)
        if (reason != "") { print "X"; return }
    }
    count = split(text, parts, /[ \t]+/)
    for (part_at = 1; part_at <= count; part_at++) {
        token = gr_cite_strip(parts[part_at])
        if (token == "") continue
        if (tag == "record" && token == "message") print "X"
        if (gr_cite_path_shaped(token) || (cite_id_re != "" && token ~ cite_id_re))
            print "C " token
    }
    gr_cite_spans(text, "`")
    gr_cite_spans(text, "\"")
}
# A FINDING fact carries the tag of the finding: `record` for a record finding,
# `code`, `requirement` or `guideline` for the others.
$1 == "FINDING" { finding_number = $2; finding_tag = $3; next }
$1 == "DISPOSITION" {
    print "D " finding_number
    gr_cite_judge(substr($0, 13), finding_tag)
}
'

# cite_resolves FACT — does one C or S fact name something real? A C token
# without `/` or `.` is an ID, since the scan emits no other kind; an ID is
# resolved by find-items.sh show, whose exit 2 is this gate's exit 2.
cite_resolves() {
    case "$1" in
        ("C "*/*|"C "*.*) cite_names_file "${1#C }" ;;
        ("C "*)
            cite_find_error=$(sh "$review_script_dir/find-items.sh" show "${1#C }" 2>&1 >/dev/null)
            case $? in
                (0) return 0 ;;
                (1) return 1 ;;
            esac
            printf '%s\n' "$cite_find_error" >&2
            gr_die "find-items.sh show ${1#C } failed" ;;
        ("S "*) cite_names_test "${1#S }" ;;
        (*) return 1 ;;
    esac
}

# cite_names_file PATH — is PATH a file of this tree? Every leading `./` is
# dropped, with any slashes repeated after it, so `.//.git/HEAD` is read as
# `.git/HEAD`; a path that starts with `/` stays absolute. A slash doubled
# inside a path is kept, so `http://x.sh` never names `http:/x.sh`. It
# resolves only as a regular file that is not a symlink and that git lists as
# tracked or as untracked and not ignored; a gitignored file, an absolute
# path, a `..` path and anything under `.git` are never listed. The listing
# is read once per run, the first time it is needed.
cite_listing=""
cite_listing_read=0
cite_names_file() {
    cite_path=$1
    while :; do
        case "$cite_path" in
            (./*) cite_path=${cite_path#./} ;;
            (/*) [ "$cite_path" != "$1" ] || break
                 cite_path=${cite_path#/} ;;
            (*) break ;;
        esac
    done
    [ -f "$cite_path" ] && [ ! -h "$cite_path" ] || return 1
    if [ "$cite_listing_read" -eq 0 ]; then
        cite_listing=$(git -c core.quotePath=false ls-files --cached --others \
            --exclude-standard) || gr_die "cannot list the files git tracks"
        cite_listing_read=1
    fi
    gr_contains "$cite_listing" "$cite_path"
}

# CITE_TEST_NAME — read lines and exit 0 if one of them DECLARES the test
# named by ENVIRON["cite_span"], never a -v value: awk -v rewrites backslashes,
# and a span may hold one. A declaration is:
#   bats   `@test "<span>"` after optional indentation;
#   jest   a first call `it(`, `test(` or `describe(` whose first argument is
#          exactly the span, in single or double quotes;
#   xUnit  `def ` or `func ` before an identifier span beginning `test` or
#          `Test`, as a Go method `func (<receiver>) ` does for a testify
#          suite, and Rust `fn ` before any identifier span, as whole words.
# A line that merely quotes the span — `run git merge "merge"` — declares
# nothing, and neither does a shell helper, `name() {` or `function name`, nor
# a line whose first non-space characters are a comment marker, `#` or `//`.
CITE_TEST_NAME='
function quoted_at_start(text, span) {
    return substr(text, 1, length(span) + 2) == "\"" span "\"" ||
        substr(text, 1, length(span) + 2) == "\047" span "\047"
}
BEGIN {
    span = ENVIRON["cite_span"]
    identifier = (span ~ /^[A-Za-z_][A-Za-z0-9_]*$/)
    pattern = ""
    if (identifier) {
        pattern = "fn " span
        if (span ~ /^(test|Test)/)
            pattern = "((def|func|fn) |func \\([^)]*\\) )" span
        pattern = "(^|[^A-Za-z0-9_])" pattern "([^A-Za-z0-9_]|$)"
    }
    found = 0
}
{
    line = $0
    sub(/^[ \t]+/, "", line)
    if (substr(line, 1, 1) == "#" || substr(line, 1, 2) == "//") next
    if (substr(line, 1, 6) == "@test ") {
        rest = substr(line, 7)
        sub(/^[ \t]+/, "", rest)
        if (substr(rest, 1, length(span) + 2) == "\"" span "\"") { found = 1; exit }
    }
    open_at = index(line, "(")
    if (open_at > 0) {
        callee = substr(line, 1, open_at - 1)
        if (callee == "it" || callee == "test" || callee == "describe") {
            rest = substr(line, open_at + 1)
            sub(/^[ \t]+/, "", rest)
            if (quoted_at_start(rest, span)) { found = 1; exit }
        }
    }
    if (pattern != "" && $0 ~ pattern) { found = 1; exit }
}
END { exit !found }
'

# cite_names_test SPAN — does a file under test_paths declare a test named
# SPAN? Each entry is a git pathspec, read as check-trace.sh reads it: git grep
# --untracked, so `*_test.go` matches recursively and a gitignored tree is not
# searched. -F narrows the search to lines holding SPAN at all; CITE_TEST_NAME
# then decides whether one of them declares it. git grep exits 1 for no match
# and above 1 for a search that failed, which is not an absent test.
cite_names_test() {
    [ -n "$cite_test_paths" ] || return 1
    # shellcheck disable=SC2086
    cite_test_lines=$(LC_ALL=C git grep -hI --untracked -F -e "$1" -- $cite_test_paths)
    case $? in
        (0) ;;
        (1) return 1 ;;
        (*) gr_die "cannot search test_paths for a test name (git grep failed)" ;;
    esac
    printf '%s\n' "$cite_test_lines" \
        | cite_span=$1 LC_ALL=C awk "$CITE_TEST_NAME"
}

# Report the disposition just read if nothing it cites resolved.
cite_report() {
    [ -n "$cite_finding" ] || return 0
    if [ "$cite_resolved" -eq 0 ]; then
        echo "UNRESOLVABLE-DISPOSITION $cite_finding (cites no path in the tree, test name in test_paths or defined item ID, and is not \"no change: <reason>\")"
        fail=1
    fi
    cite_finding=""
}

findings=0
cite_count=0
if gr_message_present "$message"; then
    facts=$(gr_message_facts "$message") || exit 2
    findings=$(printf '%s\n' "$facts" | awk '$1 == "FINDING" { count++ } END { print count + 0 }') \
        || gr_die "cannot count the findings in $message"
    if [ "$cite_on" -eq 1 ]; then
        cite_facts=$(printf '%s\n' "$facts" | LC_ALL=C awk \
            -v cite_id_re="$cite_id_re" "$CITE_SCAN") \
            || gr_die "citation scan failed on $message"
        # Split on newlines alone: a span or a path may contain a space.
        IFS='
'
        set -f
        cite_finding=""
        cite_resolved=0
        for fact in $cite_facts; do
            case "$fact" in
                ("D "*)
                    cite_report
                    cite_finding=${fact#D }
                    cite_resolved=0
                    cite_count=$((cite_count + 1)) ;;
                ("X") cite_resolved=1 ;;
                ("C "*|"S "*)
                    if [ "$cite_resolved" -eq 0 ] && cite_resolves "$fact"; then
                        cite_resolved=1
                    fi ;;
            esac
        done
        cite_report

        for fact in $facts; do
            case "$fact" in
                ("MUTATION "*) mutation=${fact#MUTATION } ;;
                ("MUTATION-PATH "*)
                    if ! cite_names_file "${fact#MUTATION-PATH }"; then
                        echo "UNRESOLVABLE-MUTATION $mutation (${fact#MUTATION-PATH } is no file in the tree)"
                        fail=1
                    fi ;;
                ("MUTATION-TEST "*)
                    if ! cite_names_test "${fact#MUTATION-TEST }"; then
                        echo "UNRESOLVABLE-MUTATION $mutation (no test in test_paths is named \"${fact#MUTATION-TEST }\")"
                        fail=1
                    fi ;;
            esac
        done
    fi
fi

# The denominator, on a pass and on a failure alike: a pass over nothing
# looks exactly like a pass over everything.
summary="checked: message $message, findings $findings"
if [ "$cite_on" -eq 1 ]; then
    summary="$summary; citations checked over $cite_count dispositions"
fi
echo "$summary"

exit $fail
