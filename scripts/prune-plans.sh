#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# prune-plans.sh [--dry-run] [--all] [--base <ref>]
#
# Replaces each fenced code block inside a plan's task sections with one
# pointer line, at the fence's indentation:
#   *(Code pruned at merge: <N> lines. Files touched: <value>.)*
# or, where the task has no `**Files touched:**` line,
#   *(Code pruned at merge: <N> lines.)*
# <N> counts the lines between the fence markers ("1 line" for one); <value>
# is the task's `**Files touched:**` value, quoted, since a pruned fence may be
# a reproduction command and not merged code. The value runs on over wrapped
# lines and ends at a blank line, a heading, a fence, or a line opening with a
# bold label (`**Parallel:**`, `**Trace**:`). A plan duplicates the code the
# change merges, and drifts from it; the merged code is in the squash commit,
# and the plan keeps the intent.
#
# Which plans: by default the docs/plans/*.md files this change adds or
# modifies against the merge-base of <ref> and HEAD, committed or not; a plan
# it renames counts as added.
# <ref> is --base's value, else the base branch (gr_base_branch); merge-change
# step 1 passes the ref it merged, `origin/<base>` where a remote exists, since
# local <base> may lag it. --all takes every docs/plans/*.md, for the plans
# already on a base branch.
#
# A task section opens at a heading, outside any fence, of the form
# `T<digits>` or `Task <letter?><digits>` (`### T1 —`, `## Task 2 —`,
# `### Task L1:`), and ends at the next heading of the same or a higher level.
# A fence opens at three or more backticks or tildes, at any indentation, and
# closes at a line of that character at least as long with nothing after it;
# a line inside a fence is never a heading and never opens another fence.
#
# Kept: every heading and every line outside a fence, every fence outside a
# task section, a fence with a line that opens with `red -> green` or
# `inherited:`, after optional indentation and a `-`, `*` or `+` list marker
# and `**` (merge-change step 6b copies those lines into the record), and a
# fence with no closing line. A fence that names `red -> green` only mid-line,
# such as a skill draft, is pruned. A plan that any tracked *.md file cites as
# `<basename>:<line>` or `<basename> line <line>` (a backtick may close the
# name), at or after its first pruned fence, is left whole, since pruning would
# move the cited line; a citation before that fence stays true, and a range
# `<line>-<line>` counts by its end line. Records cite
# plans, and so do plans, the plan itself included: its own cross-reference
# moves too. A basename after `/` cites the plan only when the directory
# before it is `plans`: a record often shares its plan's basename. A citation
# counts only if its line is still there after this run: one inside a fence
# this run prunes is ignored, unless its plan is left whole, which keeps its
# fences. Every plan's fences and citations are read, and this decided to a
# fixed point, before any plan is rewritten, so a second run decides the same.
#
# Prints, per plan:
#   pruned <plan>: <K> blocks, <L> lines        ("would prune" under --dry-run;
#                                               "1 block", "1 line" for one)
#   left whole <plan>: cited at <file>:<line> as <basename>:<N>
#                                               (or "<basename> line <N>")
# A plan with nothing to prune prints nothing, so a second run prunes nothing
# and prints only its left whole lines: a pointer line is not a fence.
# --dry-run writes nothing. A pruned plan is
# rewritten in place through a temporary file in its own directory; nothing is
# staged or committed.
#
# Configuration: `prune_plans` in .guardrails/config.yaml, `on` or `off`.
# Absent, or no config file at all, is `on`; `off` prints
# "prune_plans: off, nothing pruned" and exits 0; any other value is exit 2,
# since a key the reader cannot parse must not disable what it configures.
# The key is not read through gr_check_config, so a project with no config
# file runs this as an adopter does.
#
# Why merge-change step 1 and not finalize-docs.sh at step 3: pruning changes
# the tree on nearly every merge, and step 3 runs after the step 2 gate, so the
# tree-hash rule of step 6 would dispatch a second full suite run each time.
# Run after the base merge, the step 2 gate measures the pruned tree.
#
# Exit codes: 0 success, 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
# The status is taken from the substitution: gr_die inside it exits only the
# subshell (finalize-docs.sh gives the dash `cd ""` reason).
gr_repo_root=$(gr_root) || exit 2
cd "$gr_repo_root" || exit 2

dry_run=0
all_plans=0
base=
while [ $# -gt 0 ]; do
    case "$1" in
        (--dry-run) dry_run=1 ;;
        (--all) all_plans=1 ;;
        (--base) [ $# -ge 2 ] && [ -n "$2" ] || gr_die "--base takes a ref."
                 base=$2
                 shift ;;
        (*) gr_die "unknown argument: $1" ;;
    esac
    shift
done

plans_dir=docs/plans

# The key. cfg_get dies on a missing file, so the file is tested first, and a
# present-but-empty key is told from an absent one by asking the file, as
# gr_verification_dir does: an empty value is not `on`.
prune_setting=on
if [ -f "$GR_CONFIG" ] && grep -q '^prune_plans:' "$GR_CONFIG"; then
    prune_setting=$(cfg_get prune_plans) || exit 2
fi
case "$prune_setting" in
    (on) ;;
    (off) printf '%s\n' "prune_plans: off, nothing pruned"
          exit 0 ;;
    (*) gr_die "prune_plans in $GR_CONFIG is '$prune_setting'; it takes on or off." ;;
esac

# "1 block", "2 blocks".
counted() {
    if [ "$1" -eq 1 ]; then printf '%s %s' "$1" "$2"; else printf '%s %ss' "$1" "$2"; fi
}

# The plan list, one path per line.
if [ "$all_plans" -eq 1 ]; then
    plan_list=$(for plan in "$plans_dir"/*.md; do
        [ -f "$plan" ] && printf '%s\n' "$plan"
    done)
else
    if [ -z "$base" ]; then
        base=$(gr_base_branch) || gr_die \
"git worktree list failed, so the base branch cannot be read."
        [ -n "$base" ] || gr_die \
"the primary checkout is detached, so the base branch cannot be read.
  Check out the base branch there, or run with --base or --all."
    fi
    git rev-parse -q --verify "$base^{commit}" >/dev/null || gr_die \
"git cannot resolve the base ref $base to a commit."
    merge_base=$(git merge-base "$base" HEAD) || gr_die \
"no merge-base between $base and HEAD."
    # --no-renames: a plan the change renames is R, and would be filtered out.
    changed=$(git -c core.quotepath=off diff --name-only --no-renames \
        --diff-filter=AM "$merge_base" -- "$plans_dir") || gr_die \
"git diff against $merge_base failed."
    plan_list=$(printf '%s\n' "$changed" | while IFS= read -r plan; do
        case "$plan" in
            ("$plans_dir"/*/*) ;;
            ("$plans_dir"/*.md) [ -f "$plan" ] && printf '%s\n' "$plan" ;;
        esac
    done)
fi

# The prune program. mode=stats prints "<blocks> <lines> <first fence line>
# <ranges>", the ranges "<start>-<end>,..." the line numbers of each pruned
# fence, markers included;
# mode=rewrite prints the pruned file. The plan is read as the input file, so
# no value with a newline crosses -v.
PRUNE_AWK='
function fence_opens(text,   marker, run) {
    sub(/^[ \t]*/, "", text)
    marker = substr(text, 1, 1)
    if (marker != "`" && marker != "~") return 0
    run = 0
    while (substr(text, run + 1, 1) == marker) run++
    if (run < 3) return 0
    open_marker = marker
    open_length = run
    return 1
}
function fence_closes(text,   run) {
    sub(/^[ \t]*/, "", text)
    run = 0
    while (substr(text, run + 1, 1) == open_marker) run++
    if (run < open_length) return 0
    return substr(text, run + 1) ~ /^[ \t\r]*$/
}
function heading_level(text,   run, after) {
    run = 0
    while (substr(text, run + 1, 1) == "#") run++
    if (run < 1 || run > 6) return 0
    after = substr(text, run + 1, 1)
    if (after != " " && after != "\t" && after != "" && after != "\r") return 0
    return run
}
function is_task_heading(text) {
    return text ~ /^#+ (T[0-9]+|Task [A-Z]?[0-9]+)/
}
function counted(count, noun) {
    return count " " noun (count == 1 ? "" : "s")
}
function trim(text) {
    sub(/^[ \t]+/, "", text)
    sub(/[ \t\r]+$/, "", text)
    return text
}
function files_touched(start,   value, next_line) {
    value = plan[start]
    sub(/^\*\*Files touched(:\*\*|\*\*:)/, "", value)
    value = trim(value)
    # A wrapped value continues to the end of its paragraph, or to a line
    # that opens with another bold label (`**Parallel:** no`), which plans
    # write on the next line with no blank line between.
    for (next_line = start + 1; next_line <= line_count; next_line++) {
        if (trim(plan[next_line]) == "") break
        if (heading_level(plan[next_line])) break
        if (fence_opens(plan[next_line])) break
        if (plan[next_line] ~ /^[ \t]*\*\*[^*]+(:\*\*|\*\*:)/) break
        value = value " " trim(plan[next_line])
    }
    # A value that starts on the next line leaves a leading space.
    value = trim(value)
    sub(/\.$/, "", value)
    return value
}
{ plan[NR] = $0 }
END {
    line_count = NR
    in_fence = 0
    section = 0
    section_count = 0
    fence_count = 0
    for (line = 1; line <= line_count; line++) {
        text = plan[line]
        if (in_fence) {
            if (fence_closes(text)) {
                in_fence = 0
                fence_end[fence_count] = line
            } else if (text ~ /^[ \t]*([-*+][ \t]+)?(\*\*)?(red -> green|inherited:)/) {
                # An attestation line opens with `red -> green`, and the
                # line naming an inherited test with `inherited:`, after
                # optional indentation and a list or bold marker, on any line
                # of the fence (the develop-change dispatch report opens with
                # `task:`); a fence that names it only mid-line is a draft.
                fence_kept[fence_count] = 1
            }
            continue
        }
        if (fence_opens(text)) {
            in_fence = 1
            fence_count++
            fence_start[fence_count] = line
            fence_section[fence_count] = section
            continue
        }
        level = heading_level(text)
        if (level) {
            if (section && level <= section_level) section = 0
            if (!section && is_task_heading(text)) {
                section_count++
                section = section_count
                section_level = level
            }
            continue
        }
        if (section && !(section in section_paths) \
            && text ~ /^\*\*Files touched(:\*\*|\*\*:)/) {
            section_paths[section] = files_touched(line)
        }
    }
    blocks = 0
    pruned_lines = 0
    first_fence = 0
    ranges = ""
    for (fence = 1; fence <= fence_count; fence++) {
        prune_it[fence] = fence_section[fence] && !fence_kept[fence] \
            && (fence in fence_end)
        if (!prune_it[fence]) continue
        blocks++
        pruned_lines += fence_end[fence] - fence_start[fence] - 1
        if (!first_fence) first_fence = fence_start[fence]
        prune_at[fence_start[fence]] = fence
        ranges = ranges (ranges == "" ? "" : ",") fence_start[fence] "-" fence_end[fence]
    }
    if (mode == "stats") {
        print blocks, pruned_lines, first_fence, ranges
        exit
    }
    for (line = 1; line <= line_count; line++) {
        if (!(line in prune_at)) {
            print plan[line]
            continue
        }
        fence = prune_at[line]
        match(plan[line], /^[ \t]*/)
        indent = substr(plan[line], 1, RLENGTH)
        paths = section_paths[fence_section[fence]]
        if (paths != "") paths = " Files touched: " paths "."
        print indent "*(Code pruned at merge: " \
            counted(fence_end[fence] - fence_start[fence] - 1, "line") \
            "." paths ")*"
        line = fence_end[fence]
    }
}
'

# CITE_AWK reads `git grep -n` lines, "<file>:<line>:<text>", and prints, for
# each line that cites the plan at or after its first pruned fence (a range by
# its end line),
# "C<tab><plan><tab><file><tab><line><tab><file>:<line> as <citation>". The
# plan and its basename arrive through ENVIRON; the basename is matched with
# index(), so its dots are not pattern characters.
CITE_AWK='
BEGIN {
    plan = ENVIRON["GR_PRUNE_PLAN"]
    name = ENVIRON["GR_PRUNE_BASENAME"]
    floor = ENVIRON["GR_PRUNE_FLOOR"] + 0
}
{
    if (!match($0, /^[^:]*:[0-9]+:/)) next
    where = substr($0, 1, RLENGTH - 1)
    rest = substr($0, RLENGTH + 1)
    split(where, place, ":")
    while ((at = index(rest, name)) > 0) {
        before = substr(rest, 1, at - 1)
        rest = substr(rest, at + length(name))
        # A path whose directory is not plans/ names another file.
        if (before ~ /\/$/ && before !~ /(^|[^A-Za-z0-9_.-])plans\/$/) continue
        if (!match(rest, /^`?(:| line )[0-9]+(-[0-9]+)?/)) continue
        form = substr(rest, 1, RLENGTH)
        match(form, /[0-9]+(-[0-9]+)?$/)
        cited = substr(form, RSTART, RLENGTH)
        # A range counts by its end line, which moves if a pruned fence
        # comes at or before it.
        match(cited, /[0-9]+$/)
        if (substr(cited, RSTART, RLENGTH) + 0 < floor) continue
        print "C\t" plan "\t" place[1] "\t" place[2] "\t" where " as " name \
            (form ~ /line/ ? " line " : ":") cited
        next
    }
}
'

# DECIDE_AWK reads the P lines ("P<tab><plan><tab><blocks><tab><lines><tab>
# <ranges>", one per plan with a fence to prune) and the C lines above, and
# prints, per P line in order, "prune<tab><plan><tab><blocks><tab><lines>" or
# "whole<tab><plan><tab><citation>". A citation counts only if its citing line
# is still there after this run: one inside a fence this run prunes is
# ignored. Every plan starts as a prune; a plan a counted citation names is
# left whole, which keeps its fences and so may make more citations count.
# Repeated until nothing changes, so a second run decides the same, and
# prunes nothing.
DECIDE_AWK='
BEGIN { FS = "\t" }
$1 == "P" {
    plan_count++
    plan_name[plan_count] = $2
    plan_blocks[$2] = $3
    plan_lines[$2] = $4
    pruning[$2] = 1
    range_count[$2] = split($5, plan_ranges, ",")
    for (range = 1; range <= range_count[$2]; range++) {
        split(plan_ranges[range], bounds, "-")
        range_start[$2, range] = bounds[1] + 0
        range_end[$2, range] = bounds[2] + 0
    }
}
$1 == "C" {
    cite_count++
    cited_plan[cite_count] = $2
    citing_file[cite_count] = $3
    citing_line[cite_count] = $4 + 0
    citation_text[cite_count] = $5
}
function removed(cite,   file, range) {
    file = citing_file[cite]
    if (!(file in pruning) || !pruning[file]) return 0
    for (range = 1; range <= range_count[file]; range++)
        if (citing_line[cite] >= range_start[file, range] \
            && citing_line[cite] <= range_end[file, range]) return 1
    return 0
}
END {
    changed = 1
    while (changed) {
        changed = 0
        for (cite = 1; cite <= cite_count; cite++) {
            if (!pruning[cited_plan[cite]] || removed(cite)) continue
            pruning[cited_plan[cite]] = 0
            changed = 1
        }
    }
    for (cite = 1; cite <= cite_count; cite++) {
        if (pruning[cited_plan[cite]] || (cited_plan[cite] in why) \
            || removed(cite)) continue
        why[cited_plan[cite]] = citation_text[cite]
    }
    for (index_number = 1; index_number <= plan_count; index_number++) {
        plan = plan_name[index_number]
        if (pruning[plan]) print "prune\t" plan "\t" plan_blocks[plan] "\t" plan_lines[plan]
        else print "whole\t" plan "\t" why[plan]
    }
}
'

# Every plan's fences and citations are read before any plan is rewritten.
# The status is taken from the substitution, since gr_die in the loop exits
# only its subshell.
tab=$(printf '\t')
facts=$(printf '%s\n' "$plan_list" | while IFS= read -r plan; do
    [ -n "$plan" ] || continue
    stats=$(awk -v mode=stats "$PRUNE_AWK" "$plan") || gr_die "awk failed on $plan"
    set -- $stats
    [ "$1" -gt 0 ] || continue
    printf 'P\t%s\t%s\t%s\t%s\n' "$plan" "$1" "$2" "$4"

    # Every tracked *.md line that names the basename; git grep exits 1 on
    # no match, and above 1 on an error.
    plan_name=${plan##*/}
    cited_lines=$(git -c core.quotepath=off grep -n -I -F -e "$plan_name" -- '*.md')
    [ $? -le 1 ] || gr_die "git grep for $plan_name failed."
    printf '%s\n' "$cited_lines" | GR_PRUNE_PLAN=$plan GR_PRUNE_BASENAME=$plan_name \
        GR_PRUNE_FLOOR=$3 awk "$CITE_AWK" || gr_die "awk failed on the citations of $plan"
done) || exit 2
decisions=$(printf '%s\n' "$facts" | awk "$DECIDE_AWK") || gr_die "awk failed deciding which plans to prune."

# A whole line's third field is its citation; a prune line's, its block count.
printf '%s\n' "$decisions" | while IFS="$tab" read -r decision plan detail pruned_lines; do
    case "$decision" in
        (whole) printf 'left whole %s: cited at %s\n' "$plan" "$detail"
                continue ;;
        (prune) ;;
        (*) continue ;;
    esac
    blocks=$detail
    if [ "$dry_run" -eq 1 ]; then
        printf 'would prune %s: %s, %s\n' "$plan" \
            "$(counted "$blocks" block)" "$(counted "$pruned_lines" line)"
        continue
    fi
    temporary="$plan.prune-tmp.$$"
    awk -v mode=rewrite "$PRUNE_AWK" "$plan" > "$temporary" \
        || { rm -f "$temporary"; gr_die "awk failed rewriting $plan"; }
    mv "$temporary" "$plan" || { rm -f "$temporary"; gr_die "cannot replace $plan"; }
    printf 'pruned %s: %s, %s\n' "$plan" \
        "$(counted "$blocks" block)" "$(counted "$pruned_lines" line)"
done
