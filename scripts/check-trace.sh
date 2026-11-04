#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# check-trace.sh
#
# Traceability gates (exit 1 with one line per violation):
#   MISSING-TEST ID          — REQ or LLR with no `verifies:` reference in
#                              test_paths. A REQ also counts as tested when a
#                              tested LLR `satisfies:` it (transitive).
#                              Never annotate a test that does not verify the
#                              behavior. Put an LLR test at the software item's
#                              own interface.
#   UNMITIGATED-HAZARD ID    — HAZ with no `mitigates:` line naming it
#                              inside an RC's block.
#                              Instead of a new RC, record the acceptability
#                              rationale and control in the RMF.
#   UNIMPLEMENTED-CONTROL ID — RC with no `implements:` line naming it
#                              inside a REQ's block. A line in no block,
#                              under a heading or bold-colon line that closed
#                              the item, or in front matter, credits nothing.
#                              For a non-software control, note the external
#                              implementation in the RMF item. Add an
#                              implementing REQ only if software is part of it.
#   UNTRACED-DESIGN ID       — SDD whose block has no `traces:` REQ reference
#   UNSATISFIED-LLR ID       — LLR whose block has no `satisfies:` naming a
#                              REQ and is not marked `satisfies: derived`
#   UNANALYZED-DERIVED ID    — REQ/LLR marked derived that no `assesses:`
#                              line in the RMF names. Several items may share
#                              one `assesses:` line.
#   DANGLING-REF ID          — ID referenced in docs/strict/test paths but
#                              defined nowhere. Deleting a defined item is a
#                              change that needs its own review.
#   DANGLING-FILE FILE       — a `DRAFT-<name>.md` ledger file (name
#                              characters [A-Za-z0-9_.-]) named in a doc_*
#                              file, by path or bare name, that does not exist.
#                              Usual causes: a draft-named ledger file
#                              renamed to its dated name (ADR-cy7ahd) while a
#                              ledger still names the old one, or a draft in
#                              another unit.
#                              Plans and verification records are not
#                              scanned. A reference to an existing draft
#                              passes. A bare name resolves against this unit's
#                              ledger directories only; across units, write the
#                              path.
#   HISTORY-CITATION FILE:LINE — a ledger, strict_paths or test_paths line
#                              naming a dated file under docs/plans/ or
#                              docs/verification/: a plan file or
#                              docs/verification file, which leaves the base
#                              branch (ADR-k3nkv3). A bare directory or a
#                              placeholder names no file. A file inside either
#                              directory, at any depth, is not scanned.
#   MISPLACED-ITEM ID        — item defined outside the document configured
#                              for its prefix. Adding the stray file to
#                              strict_paths does not fix it. A doc_* directory
#                              resolves to its *.md files one level deep; a
#                              single-file doc_* resolves whatever its
#                              extension. Indent an illustrative ID or keep it
#                              inline. Never leave a definition form such as
#                              `**REQ-NNN**:` at the start of a line: that is
#                              MALFORMED-ID (check-ids.sh).
#   ORPHAN-ANNOTATION FILE:LINE — a status:/opened:/disposition:/traces:/
#                              satisfies:/implements:/mitigates: line at
#                              column one, or at column one after a run of
#                              list markers, task-list boxes (`[x]`) and
#                              blockquote markers (`>`), that belongs to no
#                              item block; and a traces:/satisfies:/
#                              implements:/mitigates: line after such a run
#                              INSIDE its item block, which no gate reads
#                              there (gr_annotation). Wider than every
#                              reader on purpose: a form no reader takes is
#                              still reported where it is orphaned.
#                              Three cases: before the first item in the file;
#                              under a heading with no item since; inside a
#                              block whose prefix's gate does not read the
#                              keyword, usually the wrong item. Move a
#                              separating heading before the item, or drop it.
#                              Inside a block, drop the lead and start the
#                              line at column one. Indent an illustrative
#                              line with no lead, or keep it inline in
#                              backticks. Reported per
#                              ledger: status:/opened:/disposition: in
#                              doc_problems, traces: in doc_sad, satisfies: in
#                              doc_sad and doc_srs, implements: in doc_srs
#                              on REQ blocks, mitigates: in doc_rmf on RC
#                              blocks. verifies: and assesses: are read
#                              line-wise and cannot be orphaned.
#                              supersedes:, superseded-by: and retired: are
#                              SUPERSESSION-ANNOTATION's, in a block or not.
#   SUPERSESSION-ANNOTATION FILE:LINE — a supersedes:, superseded-by: or
#                              retired: line at column one, or at column one
#                              after a list marker, in any ledger file, inside
#                              an item block or not. Every item in a ledger is
#                              in force: an item whose behavior is gone or
#                              changed is deleted, and the squash message
#                              records old → new, or the reason, under Items:
#                              (ADR-k3nkv3).
#   UNRESOLVED-PR ID         — problem report with status: open, with its age.
#                              WARNING only: listed for review,
#                              never fails the check on its own
#   ACCEPTED-PR ID           — problem report with status: accepted, containing
#                              its opened: date and its disposition:. WARNING
#                              only, and exempt
#                              from STALE-PROBLEM and from problem_open_max —
#                              a decision is not a backlog — but never exempt
#                              from this roll-call. Never set accepted to make
#                              PROBLEM-BACKLOG pass; resolve-problem §4 states
#                              the form.
#   INCOMPLETE-PROBLEM ID    — PR with no column-one status: in its block — a
#                              bulleted one is not read, and is not a status —
#                              an OPEN one with no opened:, or an ACCEPTED one
#                              with no disposition: or no opened: (a keyword
#                              with an empty value counts as absent).
#   RESOLVED-PROBLEM ID      — PR with status: resolved. A resolved problem
#                              report is deleted by the change that fixes it,
#                              and that change's squash message names it in
#                              Resolves: (ADR-k3nkv3). Fails the run; the item
#                              leaves the roll-call and counts toward nothing.
#   MALFORMED-STATUS ID      — status: whose value is not open or accepted
#   MALFORMED-DATE ID        — an open or accepted PR whose opened: is not a
#                              YYYY-MM-DD calendar date, or is more than a day
#                              ahead of today (one day is allowed for clock
#                              skew). An accepted item ages against no limit,
#                              but the date still records when the problem was
#                              raised, and the roll-call prints it. The age
#                              is computed in local time from
#                              `date +%Y-%m-%d`; tomorrow counts as 0 days old.
#   STALE-PROBLEM ID         — open longer than problem_age_days (more than).
#                              Set accepted where the item is real but its fix
#                              belongs to another change; resolve-problem
#                              requires the ruling first.
#   PROBLEM-BACKLOG          — more open PRs than problem_open_max (more than).
#                              The count includes open items with no usable
#                              opened: and excludes items whose status cannot
#                              be read.
#
# Scoped (multi-unit) runs add:
#   NON-EXPORTED-REF ID      — reference to an item defined in a declared
#                              dependency but not `exported: yes` there
#   UNDECLARED-DEPENDENCY ID — reference to (or expects: naming) a unit that
#                              is not in this unit's depends_on
#   UNMET-EXPECTATION        — an expects: REQ its provider has not yet
#                              answered with an exported satisfies: REQ.
#                              Advisory inside its aging budget; exit 1 past
#                              expectation_age_days, and on every run when the
#                              expectation implements a risk control
#   INCOMPLETE-EXPECTATION ID — an expects: the reader cannot use: empty
#                              value, a non-REQ carrier, or no usable opened:
#   MISEXPORTED-ITEM ID      — exported: with any value but yes, or on a
#                              non-REQ item
#   EXPECTATION-BACKLOG      — more open expectations than expectation_open_max
#
# Scoped runs engage only when .guardrails/units.yaml exists and GR_CONFIG
# names a declared unit's config (gr_unit_engage in lib.sh). With no manifest
# every path below is byte-identical to the single-unit script; with a
# manifest and no unit config the run is rejected (exit 2) rather than scoped
# by guesswork.
#
# Each doc_* config value may be a single file or a directory of per-change
# dated *.md files (see gr_doc_files in lib.sh).
#
# Nothing here may pass vacuously. These are all environment errors (exit 2),
# never empty results:
#   * a doc_*, strict_paths or test_paths entry matching no file present in
#     the working tree;
#   * a ledger directory containing no *.md at all;
#   * an id_prefixes entry that is not a bare identifier — it is interpolated
#     into every scan pattern, and a scan that errors finds nothing;
#   * an unrecognised config key, a key that is not `identifier:` at column
#     one, a list item at column zero, or a UTF-8 BOM — each is invisible to
#     the config reader, so the gate that key configures never runs;
#   * an id_prefixes list naming none of REQ/HAZ/RC/SDD/LLR/PR, or a declared
#     prefix whose gate inputs are unconfigured, or one whose definition
#     document is unconfigured — every item of that prefix would be misplaced.
#     An extra prefix alongside those is fine — DANGLING-REF, DUPLICATE-ID and
#     ID finalization are keyed on the whole prefix list, so it is checked,
#     just not by a gate of its own.
#
# Annotation rule: for verifies:/mitigates:/implements:/satisfies:/traces:/assesses:,
# only the ID list immediately following the FIRST occurrence of the keyword
# counts. The run ends at the first character that is not an ID, comma or
# space, so `verifies: <ID> (was <older ID>)` credits the first ID alone. The rule
# has exactly one definition — GR_AWK_ID_RUN in lib.sh. Inside an item block,
# where the keyword starts an annotation has one definition too —
# gr_annotation in lib.sh: at column one, or on the item's definition line.
#
# Every run ends with `checked:` (items found per prefix), `problems:` (open
# count, accepted count, oldest open item, and both triage limits — whether or
# not they are set) and `sources:` (the document files read, then the number of configured
# path entries — one entry may be a directory or a pathspec), so a pass over
# zero cannot be mistaken for a pass over sixty-three, and a limit switched
# off cannot be mistaken for a limit met. MISPLACED-ITEM is what makes `checked:`
# trustworthy: while it is green, every item counted there is in a document
# some gate actually opened. It covers the six gated prefixes only — an extra
# prefix has no configured document and is not placement-checked, so an item
# of one is still counted without being examined.
#
# After the violation lines and before `checked:`, one `fix <RULE>: <remedy>`
# line per rule that fired, warnings included, in the order the rules first
# fired.
# check_trace_remedy below is the remedy table; tests/remedies.bats checks that
# it has one entry per report in the roster above.
#
# Exit codes: 0 pass, 1 violations, 2 usage/environment error.
set -u

# Prints the remedy for report $1, or returns 1 for a report with none.
check_trace_remedy() {
    case "$1" in
        (MISSING-TEST) echo 'Write a test annotated verifies: <ID> at the lowest level that exists, LLR before REQ (develop-tdd); sharpen an untestable REQ with grill-requirements.' ;;
        (UNMITIGATED-HAZARD) echo 'Run analyze-risks for the hazard and add a risk control whose mitigates: line names it.' ;;
        (UNIMPLEMENTED-CONTROL) echo 'Write a testable REQ whose implements: line names the control (grill-requirements) — see the script header.' ;;
        (UNTRACED-DESIGN) echo 'Add a traces: line naming the REQ the design item serves; where no REQ exists, delete the item or grill the requirement first.' ;;
        (UNSATISFIED-LLR) echo 'Add satisfies: <REQ> to the LLR block, or mark it satisfies: derived and assess it with analyze-risks.' ;;
        (UNANALYZED-DERIVED) echo 'Run analyze-risks and put assesses: <ID> on its own line under the RMF derived-requirements heading; a mention elsewhere does not count.' ;;
        (DANGLING-REF) echo 'Correct the typo; for a deleted item, remove the reference, or point the test at its successor and list it as inherited: <test> — from <old ID>.' ;;
        (DANGLING-FILE) echo 'Write the name the file has now: the dated name a draft-named ledger file was renamed to. Never delete the reference to pass the gate — see the script header.' ;;
        (HISTORY-CITATION) echo 'State the reason in the comment, or cite the ADR that records the trade-off; never cite a plan file or a docs/verification file (ADR-k3nkv3).' ;;
        (MISPLACED-ITEM) echo 'Move the definition into the document configured for its prefix: REQ doc_srs, HAZ and RC doc_rmf, SDD and LLR doc_sad, PR doc_problems.' ;;
        (ORPHAN-ANNOTATION) echo 'Start the line at column one, with no list marker, task-list box or quote marker, inside the item block it describes — see the script header.' ;;
        (SUPERSESSION-ANNOTATION) echo 'Delete the item marked superseded-by: or retired:, drop supersedes: from its successor, and record old → new or the reason under Items: in the squash message (ADR-k3nkv3).' ;;
        (UNRESOLVED-PR) echo 'Review the open item: fix it under resolve-problem, or leave it open knowingly.' ;;
        (ACCEPTED-PR) echo 'Check that the ruling in disposition: still stands; where it does not, set status: open or fix the item under resolve-problem.' ;;
        (INCOMPLETE-PROBLEM) echo 'Add the missing status:, opened: (YYYY-MM-DD) or disposition: at column one inside the item block, with no list marker.' ;;
        (RESOLVED-PROBLEM) echo "Delete the item; the fixing change's squash message names it in Resolves: and gives cause → fix under Problems: (ADR-k3nkv3)." ;;
        (MALFORMED-STATUS) echo 'Set status: to open, or to accepted with a disposition:.' ;;
        (MALFORMED-DATE) echo 'Write opened: as a YYYY-MM-DD calendar date no later than tomorrow; where the clock or timezone is wrong, correct that.' ;;
        (STALE-PROBLEM) echo 'Resolve the item, rule on it as status: accepted with a disposition: (resolve-problem), or raise problem_age_days deliberately.' ;;
        (PROBLEM-BACKLOG) echo 'Resolve open items or rule on them as status: accepted with a disposition: (resolve-problem), or raise problem_open_max deliberately.' ;;
        (NON-EXPORTED-REF) echo 'Reference only exported items of a dependency, or have its unit mark the item exported: yes.' ;;
        (UNDECLARED-DEPENDENCY) echo 'Add the named unit to depends_on in the config of this unit, or remove the reference.' ;;
        (UNMET-EXPECTATION) echo 'Have the provider unit export a REQ that satisfies: the expectation, or re-analyze the risk and remove the expects: line.' ;;
        (INCOMPLETE-EXPECTATION) echo 'Put expects: on a REQ, name a unit in it, and add opened: as a YYYY-MM-DD date.' ;;
        (MISEXPORTED-ITEM) echo 'Write exported: yes, and only on a REQ item.' ;;
        (EXPECTATION-BACKLOG) echo 'Close open expectations with an exported answer from the provider, or raise expectation_open_max deliberately.' ;;
        (*) return 1 ;;
    esac
}

. "$(dirname "$0")/lib.sh"
# NOT `cd "$(gr_root)" || exit 2`: gr_root's gr_die exits only the command
# substitution, and under dash `cd ""` returns 0 and stays put — so outside a
# git repository the script continued in the caller's directory with a
# relative config path. The status has to be taken from the substitution.
gr_repo_root=$(gr_root) || exit 2
cd "$gr_repo_root" || exit 2

# The engagement rule: with no manifest this is a
# no-op and everything below is exactly the single-unit script. Engaged,
# GR_UNIT names the unit whose config this run reads, and the scoped
# machinery at the bottom of this file switches on.
gr_unit_engage

gr_check_config
gr_check_examples

# Read beside gr_check_config, and for its reason: every other config
# invariant in this toolkit is settled BEFORE any gate runs, so that a typo is
# diagnosed as a typo rather than after a page of violations. Read at the point
# of use, a bad limit reported exit 2 with the `checked:`/`problems:`/`sources:`
# lines never printed — the evidence suppressed by the error.
age_limit=$(gr_limit problem_age_days) || exit 2
open_limit=$(gr_limit problem_open_max) || exit 2
exp_age_limit=""
exp_open_limit=""
if [ -n "$GR_UNIT" ]; then
    exp_age_limit=$(gr_limit expectation_age_days) || exit 2
    exp_open_limit=$(gr_limit expectation_open_max) || exit 2
fi

# "Today" is the denominator of every age this gate computes, so a garbage
# value would not fail — it would make every age silently wrong. Two checks,
# because they catch different things and one message must not stand in for
# the other: the shell tests the SHAPE (and with it the `-v` value awk is
# about to be handed), and awk tests the CALENDAR.
today=$(date +%Y-%m-%d) || gr_die "date(1) failed; the age of an open problem cannot be established"
case "$today" in
    ([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    (*) gr_die "date +%Y-%m-%d produced '$today', which is not a date in YYYY-MM-DD form" ;;
esac
LC_ALL=C awk -v today="$today" "$GR_AWK_CIVIL"'BEGIN { exit(gr_date_ok(today) ? 0 : 1) }' \
    || gr_die "date +%Y-%m-%d produced '$today', which is not a calendar date"

prefixes=$(gr_prefixes) || exit 2
P=$(gr_prefix_re) || exit 2

# gr_doc_files dies on a configured-but-absent or empty path; because these run
# in a command substitution its exit only kills the subshell, so propagate it.
srs_files=$(gr_doc_files doc_srs) || exit 2
rmf_files=$(gr_doc_files doc_rmf) || exit 2
sad_files=$(gr_doc_files doc_sad) || exit 2
soup_files=$(gr_doc_files doc_soup) || exit 2
problems_files=$(gr_doc_files doc_problems) || exit 2
test_paths=$(cfg_list test_paths)
strict_paths=$(cfg_list strict_paths)
# The example files: no definition, reference or citation is read from them,
# except the IDs on a line-start `verifies:` line (VERIFIES_LINE_RE).
# `example_excludes` holds one `:(exclude)` pathspec per entry, passed beside
# the scope of each scan that skips them.
example_paths=$(cfg_list example_paths) || exit 2
example_excludes=$(gr_example_excludes) || exit 2
# VERIFIES_LINE_RE — a `verifies:` keyword preceded on its line only by
# blanks and comment leaders (`#`, `/`, `-`, `;`, `*`). In an example file this
# is the one line form still read: a test file's own annotation is written so,
# a heredoc that writes a fixture's annotation copies it so, and a `printf` or
# an assertion that merely quotes the keyword does not start the line with it.
VERIFIES_LINE_RE='^[[:blank:]#/;*-]*verifies:'

# Every list above is newline-separated, so split on newlines alone: a path or
# filename containing a space must reach git grep as one argument, and must be
# named correctly in any error about it. `prefixes` is newline-separated too,
# for the same uniformity.
IFS='
'

# Pathname expansion OFF from here on. Configured path entries are git
# pathspecs and must reach git verbatim. Left on, the shell expands them first
# against the current directory, so `strict_paths: - *.c` is replaced by
# whatever `*.c` matches in the repo ROOT and the recursive pathspec meaning is
# silently lost: a root-level main.c makes `src/foo.c` invisible while
# `sources:` still reports `strict 1`. Deleting that unrelated root file then
# changes the verdict. gr_doc_files above needs globbing to expand its `*.md`,
# so it has already run.
set -f

# A configured path that does not exist makes every gate that reads it a
# silent no-op: gr_require_paths fails it as an environment error instead.
#
# The list expansions here and at the scan sites below are deliberately
# unquoted so the newline-separated lists split into separate arguments —
# never so the shell can expand a pattern. `set -f` above guarantees it does
# not: every entry reaches git verbatim as a pathspec.
# shellcheck disable=SC2086
gr_require_paths strict_paths $strict_paths
# shellcheck disable=SC2086
gr_require_paths test_paths $test_paths

# Every violation line from here to the summary goes through print_violations,
# which prints it at once and adds its rule (the first word) to fired_rules.
# The remedy lines for fired_rules are printed just before the summary. An exit
# before the summary (exit 2 from any gr_die below) leaves the violation lines
# already printed on stdout; no temporary file is written.
fired_rules=""

# print_violations TEXT — prints each line of TEXT and records the first word
# of each line in fired_rules, once, in first-fired order.
print_violations() {
    [ -n "$1" ] || return 0
    printf '%s\n' "$1"
    for _rule in $(printf '%s\n' "$1" | awk 'NF { print $1 }'); do
        gr_contains "$fired_rules" "$_rule" || fired_rules="${fired_rules}${fired_rules:+
}$_rule"
    done
}

fail=0

foreign=""
reverse=""
deps=""
if [ -n "$GR_UNIT" ]; then
    deps=$(cfg_list depends_on)
    # Pathname expansion back ON for the unit scans: gr_unit_srs (under
    # gr_exported_reqs and gr_unit_req_scan) expands the unit's doc_srs
    # directory with a *.md glob, exactly as gr_doc_files did above before
    # set -f. Nothing here can expand by accident — gr_check_units has
    # already rejected any manifest entry containing a glob character.
    set +f
    for _dep in $deps; do
        _fx=$(gr_exported_reqs "$_dep") || exit 2
        foreign="$foreign
$(printf '%s\n' "$_fx" | cut -f1)"
    done
    for _con in $(gr_consumers_of "$GR_UNIT"); do
        _cs=$(gr_unit_req_scan "$_con") || exit 2
        reverse="$reverse
$(printf '%s\n' "$_cs" | awk -F'\t' -v me="$GR_UNIT" \
            '$3 == "EXPECTS" && $4 == me && $1 ~ /^REQ-/ { print $1 }')"
    done
    set -f
fi

# unignored_files LIST — LIST's files that git does not ignore, one per line.
# THE FILES GIT GREP READS, and no others. The
# definition readers — ids_defined and its kin — read through `git grep
# --untracked`, which skips a file git ignores; a block pass that read the
# file system instead credited an ignored file's lines. Used by credit_scan
# alone: its credit passes drop the files git grep skips, and every other
# block pass reads them.
# check-ignore, not an ls-files allowlist: it names what to DROP, so a path it
# prints quoted is kept and read, as before, rather than missed. With the
# index (no --no-index), a tracked file is never ignored, as git grep searches
# it. Exit 1 is "nothing ignored". No files, no call: `git check-ignore --`
# with no path exits 128. Status 2 when git fails.
unignored_files() {
    [ -n "$1" ] || return 0
    # shellcheck disable=SC2086
    _unignored_dropped=$(git -c core.quotePath=false check-ignore -- $1)
    [ "$?" -le 1 ] || return 2
    for _unignored_file in $1; do
        gr_contains "$_unignored_dropped" "$_unignored_file" || printf '%s\n' "$_unignored_file"
    done
}
# --- Credits ----------------------------------------------------------------
# A credit belongs to the block it is written in. `implements: RC-…`
# credits the RC only on a line inside a REQ block of doc_srs, and
# `mitigates: HAZ-…` the HAZ only on a line inside an RC block of doc_rmf. The
# keyword starts its annotation where gr_annotation says, at column one or on
# the definition line — the inline `(implements: RC-…)` there is the shipped
# form — and the ID run after it is read by gr_id_run. A line in no block
# credits nothing: before the first item, after a heading or a bold-colon line
# that closed the item, or in front matter, which is skipped by
# GR_AWK_FRONT_MATTER so that not even a definition line in it opens a block.
# A block cannot span files, so the open block is dropped at each file's
# first line.
#
# ONE reader per keyword: every consumer reads these records, so no two
# gates can disagree on what a line credits. A second, line-wise reader
# would credit a line in no block, and UNIMPLEMENTED-CONTROL or
# UNMITIGATED-HAZARD would pass on a credit no item made.
#
# credit_scan KEYWORD OWNER TARGET FILES — one `<owner> <ID>` line per credit:
# an ID of prefix TARGET named by KEYWORD inside a block of prefix OWNER.
# FILES is a newline-separated list; the files git ignores are dropped
# (unignored_files, above). The awk status is the function's status. The
# caller keeps only owners ids_defined reports: an owner defined nowhere a
# gate reads (a definition behind a BOM, or only in a file `git grep -I`
# skips as binary) credits nothing. That is all the filter guards. A binary
# ledger file that redefines an owner also defined in a text file still
# credits through this pass; the plan's follow-ups record it.
credit_scan() {
    _credit_files=$(unignored_files "$4") || return 2
    [ -n "$_credit_files" ] || return 0
    # Each file is named twice, for the two front-matter passes below.
    _credit_twice=""
    for _credit_file in $_credit_files; do
        _credit_twice="${_credit_twice}${_credit_twice:+
}$_credit_file
$_credit_file"
    done
    # shellcheck disable=SC2086
    LC_ALL=C awk -v body="$GR_ID_BODY" -v kw="$1" -v owner="$2" -v target="$3-" \
        "$GR_AWK_ID_RUN$GR_AWK_ITEM_BLOCK$GR_AWK_FRONT_MATTER"'
        BEGIN { gr_block_init(owner, body) }
        # The pass count is per file: odd passes find the front matter, even
        # passes read. An empty file has no first line and so no pass, which
        # leaves the count right for the file after it.
        FNR == 1 {
            sub(/^\357\273\277/, ""); cur = ""
            file_pass = (FILENAME == pass_file) ? file_pass + 1 : 1
            pass_file = FILENAME
            if (file_pass % 2 == 1) gr_fm_reset()
        }
        # Front matter is skipped by the ONE rule, GR_AWK_FRONT_MATTER in
        # lib.sh, that check_orphans skips it by: a definition line inside it
        # opens no block, so nothing in it credits.
        file_pass % 2 == 1 { gr_fm_scan($0, FNR); next }
        gr_fm_skip(FNR) { next }
        { line = $0; sub(/\r$/, "", line) }
        # No `next`: the definition line carries the inline form.
        gr_block_closes(line) { cur = gr_block_opens(line) ? gr_block_id(line) : "" }
        cur != "" {
            annotation = gr_annotation(line, kw)
            if (annotation != "") {
                id_count = split(gr_id_run(annotation, kw), named_ids, " ")
                for (id_index = 1; id_index <= id_count; id_index++)
                    if (index(named_ids[id_index], target) == 1)
                        print cur " " named_ids[id_index]
            }
        }
    ' $_credit_twice < /dev/null
}

# `implements:` records for this run, read once: UNIMPLEMENTED-CONTROL and
# the expectation severity below both read them.
implements_records=""
if [ -n "$srs_files" ]; then
    implements_records=$(credit_scan 'implements:' REQ RC "$srs_files") \
        || gr_die "implements: scan failed"
fi

# --- Unit annotations and expectations ---------------------------------------
# Scoped runs only. exported:/expects:/opened: are read by gr_req_scan under
# the same column-one, first-occurrence, block-attributed rules as status:,
# and the ORPHAN-ANNOTATION backstop below is extended to match.
exempt_expect=""
exp_summary=""
if [ -n "$GR_UNIT" ]; then
    # shellcheck disable=SC2086
    own_scan=$(gr_req_scan $srs_files $rmf_files $sad_files $problems_files) || exit 2

    # MISEXPORTED-ITEM: only `exported: yes` on a REQ is an export. A
    # misspelled value would read as "not exported" and strand every consumer
    # silently, so any other value — empty included — convicts, as does the
    # annotation on a non-REQ block.
    _misexp=$(printf '%s\n' "$own_scan" | awk -F'\t' '
        $3 != "EXP" { next }
        $1 !~ /^REQ-/       { printf "MISEXPORTED-ITEM %s (exported: on a non-REQ item — only requirements are exported; LLR and SDD are design data)\n", $1; next }
        $4 != "yes"         { printf "MISEXPORTED-ITEM %s (exported: %s — the only accepted value is yes; anything else reads as not exported, which strands consumers silently)\n", $1, $4 }')
    if [ -n "$_misexp" ]; then
        print_violations "$_misexp"
        fail=1
    fi

    # Expectations. Grammar first (INCOMPLETE-EXPECTATION is the one token for
    # every expectation the reader cannot read), then the computed state.
    _badexp=$(printf '%s\n' "$own_scan" | awk -F'\t' '
        $3 != "EXPECTS" { next }
        $1 !~ /^REQ-/ { printf "INCOMPLETE-EXPECTATION %s (expects: on a non-REQ item)\n", $1; next }
        $4 == ""      { printf "INCOMPLETE-EXPECTATION %s (expects: with no unit named)\n", $1 }')
    if [ -n "$_badexp" ]; then
        print_violations "$_badexp"
        fail=1
    fi

    exp_open=0
    exp_oldest=-1
    _tab=$(printf '\t')
    for _el in $(printf '%s\n' "$own_scan" \
            | awk -F'\t' '$3 == "EXPECTS" && $1 ~ /^REQ-/ && $4 != "" { print $1 "\t" $4 }'); do
        _eid=${_el%%"$_tab"*}
        _etgt=${_el#*"$_tab"}
        if ! gr_contains "$deps" "$_etgt"; then
            print_violations "UNDECLARED-DEPENDENCY $_eid (expects: names $_etgt, which is not in this unit's depends_on — the MISSING-TEST exemption never engages across an undeclared edge)"
            fail=1
            continue
        fi
        _eopd=$(printf '%s\n' "$own_scan" | awk -F'\t' -v i="$_eid" '$1 == i && $3 == "OPENED" { print $4; exit }')
        _eage=$(LC_ALL=C awk -v today="$today" -v opd="$_eopd" "$GR_AWK_CIVIL"'BEGIN {
            gr_date_ok(today); t = GR_DATE_DAYS
            if (!gr_date_ok(opd)) { print -1; exit }
            a = t - GR_DATE_DAYS
            if (a == -1) a = 0            # one day of clock-skew tolerance,
            print (a < 0 ? -1 : a)        # further future is rejected (as PRs)
        }')
        if [ "$_eage" -lt 0 ]; then
            print_violations "INCOMPLETE-EXPECTATION $_eid (opened: cannot be used — '$_eopd' is absent, not a calendar date, or more than a day in the future)"
            fail=1
            continue
        fi
        # met iff the named provider defines an EXPORTED REQ containing
        # satisfies: <this ID> — both conditions.
        # Globbing back on for the provider scan, as at the foreign/reverse
        # computation above and for the same *.md-glob reason.
        set +f
        _pscan=$(gr_unit_req_scan "$_etgt") || exit 2
        set -f
        _met=$(printf '%s\n' "$_pscan" | awk -F'\t' -v want="$_eid" '
            $3 == "EXP" && $4 == "yes" { expd[$1] = 1 }
            $3 == "SAT" && $4 == want  { sat[$1] = 1 }
            END { for (req in sat) if (req in expd) { print "met"; exit } }')
        if [ "$_met" = "met" ]; then
            continue          # an ordinary REQ again; MISSING-TEST applies
        fi
        exempt_expect="$exempt_expect
$_eid"
        exp_open=$((exp_open + 1))
        [ "$_eage" -gt "$exp_oldest" ] && exp_oldest=$_eage
        # Risk-linked when the expecting REQ's own block implements a
        # control: the records UNIMPLEMENTED-CONTROL reads (credit_scan).
        if printf '%s\n' "$implements_records" | awk -v want="$_eid" '$1 == want { found = 1 } END { exit !found }'; then
            print_violations "UNMET-EXPECTATION $_etgt: $_eid (open $_eage days — implements a risk control, exit 1 on every run until the provider delivers or the risk is re-analyzed)"
            fail=1
        elif [ -n "$exp_age_limit" ] && [ "$_eage" -gt "$exp_age_limit" ]; then
            print_violations "UNMET-EXPECTATION $_etgt: $_eid (open $_eage days, limit $exp_age_limit)"
            fail=1
        else
            print_violations "UNMET-EXPECTATION $_etgt: $_eid (open $_eage days)"
        fi
    done
    if [ -n "$exp_open_limit" ] && [ "$exp_open" -gt "$exp_open_limit" ]; then
        _noun="open expectations"
        [ "$exp_open" -eq 1 ] && _noun="open expectation"
        print_violations "EXPECTATION-BACKLOG ($exp_open $_noun, limit $exp_open_limit)"
        fail=1
    fi
    _eold_txt="n/a"
    [ "$exp_oldest" -ge 0 ] && _eold_txt="$exp_oldest days"
    exp_summary="expectations: open $exp_open, oldest $_eold_txt; limits age ${exp_age_limit:-none}, open ${exp_open_limit:-none}"
fi

# ids_defined PREFIX — all finalized IDs with a `**ID**:` definition site.
# Scoped, the site must lie inside the unit: sibling items are not this run's
# items (they neither owe MISSING-TEST here nor discharge anything —
# obligation reverse-edge-discharges-nothing generalizes to every foreign
# definition), and MISPLACED-ITEM must never see them at all.
#
# Status checked and stderr not suppressed, as ids_verified does: an errored
# scan finds no definition, which reads as a tree with no items. Not a
# pipeline, so $? is git's. A caller in $(...) adds `|| exit 2`.
ids_defined() {
    if [ -n "$GR_UNIT" ]; then
        # shellcheck disable=SC2086
        _dlines=$(git grep -h --untracked -oE "$(gr_def_re "$1")" -- "$GR_UNIT" $example_excludes)
        _dst=$?
    else
        # shellcheck disable=SC2086
        _dlines=$(git grep -h --untracked -oE "$(gr_def_re "$1")" -- . "$GR_SCAN_EXCLUDE" $example_excludes)
        _dst=$?
    fi
    [ "$_dst" -le 1 ] || gr_die "$1 definition scan failed (git grep exit $_dst)"
    [ -n "$_dlines" ] || return 0
    printf '%s\n' "$_dlines" | sed 's/[*:]//g' | sort -u
}

# ids_defined_in PREFIX FILES… — definitions of PREFIX inside the given files.
# The empty-args guard is defence in depth, not a reachable branch: every
# caller below passes a doc file list that gr_check_config's rule 2 and
# gr_doc_files between them guarantee is non-empty. It is here because the
# failure mode if a future caller does pass nothing is silent — `git grep -- `
# with no pathspec scans the whole repository, so every item would look
# correctly placed and the gate would report nothing at all.
ids_defined_in() {
    _p="$1"
    shift
    [ $# -gt 0 ] || return 0
    git grep -h --untracked -oE "$(gr_def_re "$_p")" -- "$@" 2>/dev/null \
        | sed 's/[*:]//g' | sort -u
}

# ids_matching KEYWORD PREFIX PATHS… — IDs of PREFIX in the ID list that
# immediately follows KEYWORD (see the annotation rule above).
#
# Status checked and stderr not suppressed, as ids_defined does: an errored
# scan finds no annotation, which reads as an untested or unassessed item.
# Not a pipeline, so $? is git's. A caller in $(...) adds `|| exit 2`.
ids_matching() {
    _kw="$1"
    _pfx="$2"
    shift 2
    [ $# -gt 0 ] || return 0
    _mlines=$(git grep -hI --untracked -F "$_kw" -- "$@")
    _mst=$?
    [ "$_mst" -le 1 ] || gr_die "$_kw annotation scan failed (git grep exit $_mst)"
    [ -n "$_mlines" ] || return 0
    printf '%s\n' "$_mlines" \
        | gr_id_run "$_kw" \
        | grep -xE "${_pfx}-${GR_ID_BODY}" | sort -u
}

# ids_verified PREFIX — IDs of PREFIX a `verifies:` annotation in test_paths
# names. An example file's annotation counts only in the line-start form: a
# printf or an assertion quoting the keyword verifies nothing. The second scan
# reads every test file, but outside the example files its lines are a subset
# of the first scan's, so the union adds only the example files' annotations.
ids_verified() {
    # shellcheck disable=SC2086
    ids_matching 'verifies:' "$1" $test_paths $example_excludes
    [ -n "$example_excludes" ] || return 0
    # Status checked and stderr not suppressed, as the reference scan does:
    # an errored scan finds no annotation, which reads as an untested item.
    # Not a pipeline, so $? is git's.
    # shellcheck disable=SC2086
    _vlines=$(git grep -hI --untracked -E "$VERIFIES_LINE_RE" -- $test_paths)
    _st=$?
    [ "$_st" -le 1 ] || gr_die "verifies: annotation scan failed (git grep exit $_st)"
    printf '%s\n' "$_vlines" \
        | gr_id_run 'verifies:' \
        | grep -xE "${1}-${GR_ID_BODY}" | sort -u
}

# --- LLR block parse: "<id> <REQ,REQ|derived|->" per LLR in the SAD files ---
# Blocks end at the next header-shaped line or markdown heading (see
# GR_AWK_ITEM_BLOCK in lib.sh), so prose can never satisfy an LLR. Parsed per file; blocks cannot span files.
parse_llr_file() {
    LC_ALL=C awk -v body="$GR_ID_BODY" "$GR_AWK_ID_RUN$GR_AWK_ITEM_BLOCK"'
        BEGIN { gr_block_init("LLR", body) }
        function flush() {
            if (cur != "") {
                if (der) print cur " derived"
                else if (sat != "") print cur " " sat
                else print cur " -"
            }
        }
        # ONE rule for both boundaries. Every definition form closes the open
        # block, and one of this gate own prefix opens a new one in the same
        # breath — which is why the ternary rather than two rules that would
        # have to agree about their order.
        #
        # Deliberately no `next`: an LLR header usually contains its own
        # `satisfies:` annotation, so the line must still reach the collector.
        gr_block_closes($0) {
            flush()
            cur = gr_block_opens($0) ? gr_block_id($0) : ""
            sat = ""; der = 0
        }
        cur != "" {
            annotation = gr_annotation($0, "satisfies:")
            if (annotation ~ /^satisfies:[ \t]*derived/) der = 1
            else {
                run = gr_id_run(annotation, "satisfies:")
                n = split(run, a, " ")
                for (i = 1; i <= n; i++)
                    if (a[i] ~ /^REQ-/) sat = sat (sat == "" ? "" : ",") a[i]
            }
        }
        END { flush() }
    ' "$1"
}

llr_info=""
for f in $sad_files; do
    llr_info="$llr_info
$(parse_llr_file "$f")"
done

# --- MISPLACED-ITEM: an item must be defined inside its own document -------
# The message states the RULE and nothing else, deliberately. Two attempts at
# stating the consequence were both disproved by the same run that printed
# them, and the honest version has too many exceptions for one line:
#
#   * the item is still ENUMERATED — ids_defined scans the whole tree, so
#     MISSING-TEST, UNMITIGATED-HAZARD and UNIMPLEMENTED-CONTROL fire on a
#     misplaced item exactly as on a placed one;
#   * its own block is not PARSED by the gate that would convict it on those
#     annotations: UNTRACED-DESIGN, UNSATISFIED-LLR, UNRESOLVED-PR and the
#     derived-assessment scan read only the configured document, so a
#     misplaced SDD keeps no `traces:` obligation and a misplaced PR can never
#     be reported open;
#   * but DANGLING-REF scans every doc_* file plus strict_paths and
#     test_paths, so an item misfiled into ANOTHER ledger still has its
#     reference IDs read — by that gate, not by its own;
#   * and a HAZ block contains no annotation of its own that a gate parses, but
#     moving it out of the RMF still blinds one: UNANALYZED-DERIVED reads
#     `assesses:` lines over $rmf_files, so a derived item assessed inside a
#     HAZ block stops being assessed when that block leaves. It fails RED, so
#     no false green — but the loss is real.
#
# What is true for all six is the rule itself: an item belongs in the files
# its key resolves to. The exceptions above are stated here, where there is
# room for them; the MISPLACED-ITEM entry in the header roster above states the
# rule.
# `**SDD-001**:` in docs/design.md passed with no `traces:` at all, and moving
# that same file into doc_sad turned the run red without changing a character
# of it.
#
# "Outside" means outside what gr_doc_files RESOLVES: for a directory, its
# *.md files one level deep; for a scalar, that one file whatever its
# extension. A `.txt` in a configured DIRECTORY, or a `.md` one level
# further down, is outside it — hence the message naming the files the key
# resolves to rather than the key's value, and not naming *.md, which is
# wrong for a single-file doc_* config.
#
# This gate is what makes the summary trustworthy: while it is green, every
# item counted in `checked:` is in a document some gate opened.
check_placement() {
    _pfx="$1"
    _key="$2"
    shift 2
    # No `[ $# -gt 0 ] || return 0` guard here, and deliberately so. The arms
    # below cannot pass an empty list — rule 2 requires the key, gr_doc_files
    # then yields at least one file or dies — so this is about which way to
    # fail if that ever stops being true. With no files the correct verdict is
    # "every item of this prefix is read by nothing", which is what an empty
    # _inside produces. Skipping instead would be the silent exemption this
    # gate exists to remove.
    _inside=$(ids_defined_in "$_pfx" "$@")
    _defs=$(ids_defined "$_pfx") || exit 2
    for _id in $_defs; do
        gr_contains "$_inside" "$_id" || {
            print_violations "MISPLACED-ITEM $_id (must be defined in the files $_key resolves to)"
            fail=1
        }
    done
}
for _pfx in $prefixes; do
    case "$_pfx" in
        # shellcheck disable=SC2086
        (REQ) check_placement REQ doc_srs $srs_files ;;
        # shellcheck disable=SC2086
        (HAZ|RC) check_placement "$_pfx" doc_rmf $rmf_files ;;
        # shellcheck disable=SC2086
        (SDD|LLR) check_placement "$_pfx" doc_sad $sad_files ;;
        # shellcheck disable=SC2086
        (PR) check_placement PR doc_problems $problems_files ;;
    esac
done

# --- MISSING-TEST: every REQ and LLR needs a verifies: reference -----------
if [ -n "$test_paths" ]; then
    verified_llr=$(ids_verified LLR) || exit 2
    defined_llr=$(ids_defined LLR) || exit 2
    for id in $defined_llr; do
        gr_contains "$verified_llr" "$id" || { print_violations "MISSING-TEST $id (no 'verifies:' reference in test paths)"; fail=1; }
    done

    # REQ coverage: direct verifies:, plus satisfies: lists of tested LLRs.
    covered=$(ids_verified REQ) || exit 2
    for llr in $verified_llr; do
        sats=$(printf '%s\n' "$llr_info" \
            | awk -v l="$llr" '$1 == l && $2 != "-" && $2 != "derived" { print $2 }' \
            | tr ',' '\n')
        covered="$covered
$sats"
    done
    defined_req=$(ids_defined REQ) || exit 2
    for id in $defined_req; do
        # A valid UNMET expectation is exempt: it cannot have a
        # verifying test yet and is already reported once, accurately, by
        # UNMET-EXPECTATION above. Met, it is an ordinary REQ again.
        gr_contains "$exempt_expect" "$id" && continue
        gr_contains "$covered" "$id" || { print_violations "MISSING-TEST $id (no direct 'verifies:' and no tested LLR satisfies it)"; fail=1; }
    done

fi

# --- UNMITIGATED-HAZARD: every HAZ needs an RC that mitigates it ------------
# Credited by credit_scan: a `mitigates:` inside the block of an RC that
# ids_defined reports. A line in no RC block mitigates nothing.
if [ -n "$rmf_files" ]; then
    mitigates_records=$(credit_scan 'mitigates:' RC HAZ "$rmf_files") \
        || gr_die "mitigates: scan failed"
    defined_rc=$(ids_defined RC) || exit 2
    defined_rc_flat=" $(printf '%s\n' "$defined_rc" | tr '\n' ' ')"
    mitigated=$(printf '%s\n' "$mitigates_records" \
        | awk -v defined="$defined_rc_flat" \
            'NF == 2 && index(defined, " " $1 " ") > 0 { print $2 }')
    defined_haz=$(ids_defined HAZ) || exit 2
    for id in $defined_haz; do
        gr_contains "$mitigated" "$id" && continue
        { print_violations "UNMITIGATED-HAZARD $id (no risk control 'mitigates:' it)"; fail=1; }
    done
fi

# --- UNIMPLEMENTED-CONTROL: every RC needs a REQ that implements it ---------
# Credited by credit_scan: an `implements:` inside the block of a REQ that
# ids_defined reports. A line in no REQ block implements nothing.
if [ -n "$srs_files" ]; then
    defined_req=$(ids_defined REQ) || exit 2
    defined_req_flat=" $(printf '%s\n' "$defined_req" | tr '\n' ' ')"
    implemented=$(printf '%s\n' "$implements_records" \
        | awk -v defined="$defined_req_flat" \
            'NF == 2 && index(defined, " " $1 " ") > 0 { print $2 }')
    defined_rc=$(ids_defined RC) || exit 2
    for id in $defined_rc; do
        gr_contains "$implemented" "$id" && continue
        { print_violations "UNIMPLEMENTED-CONTROL $id (no requirement 'implements:' it)"; fail=1; }
    done
fi

# --- UNTRACED-DESIGN: every SDD block needs `traces:` naming a REQ ----------
for f in $sad_files; do
    untraced=$(LC_ALL=C awk -v body="$GR_ID_BODY" "$GR_AWK_ID_RUN$GR_AWK_ITEM_BLOCK"'
        BEGIN { gr_block_init("SDD", body) }
        function flush() { if (cur != "" && !ok) print cur }
        # Deliberately no `next`: the header line itself usually contains the
        # `traces:` annotation, so it must reach the scan below.
        gr_block_closes($0) {
            flush()
            cur = gr_block_opens($0) ? gr_block_id($0) : ""
            ok = 0
        }
        cur != "" {
            run = gr_id_run(gr_annotation($0, "traces:"), "traces:")
            n = split(run, a, " ")
            for (i = 1; i <= n; i++) if (a[i] ~ /^REQ-/) ok = 1
        }
        END { flush() }
    ' "$f")
    for id in $untraced; do
        print_violations "UNTRACED-DESIGN $id (no 'traces:' to a requirement)"
        fail=1
    done
done

# --- UNSATISFIED-LLR: every LLR satisfies a REQ or is marked derived --------
for id in $(printf '%s\n' "$llr_info" | awk '$2 == "-" { print $1 }'); do
    print_violations "UNSATISFIED-LLR $id (no 'satisfies:' REQ and not marked derived)"
    fail=1
done

# --- UNANALYZED-DERIVED: derived REQ/LLR must be assessed in the RMF --------
derived_ids=$(printf '%s\n' "$llr_info" | awk '$2 == "derived" { print $1 }')
for f in $srs_files; do
    derived_ids="$derived_ids
$(LC_ALL=C awk -v body="$GR_ID_BODY" "$GR_AWK_ITEM_BLOCK"'
        BEGIN { gr_block_init("REQ", body) }
        gr_block_closes($0) { cur = gr_block_opens($0) ? gr_block_id($0) : "" }
        cur != "" && gr_annotation($0, "satisfies:") ~ /^satisfies:[ \t]*derived/ { print cur; cur = "" }
    ' "$f")"
done
# The assessment is DECLARED, not inferred. A free-text search for a derived
# ID over $rmf_files would read an ID in a verification table, a scope note
# or a parenthetical as an assessment, and a derived item is normally named
# in its file's verification table, so such a gate could not tell the
# failure it exists to detect from compliance.
#
# `assesses:` is read line-wise by ids_matching through GR_AWK_ID_RUN, unlike
# mitigates: and implements:, which credit_scan reads by block. The run ends
# at the first character that is not an ID, comma or space, so an
# assessment of one item cannot clear a second it names in passing. It is
# NOT in the ORPHAN-ANNOTATION list: an assessment is prose under a heading,
# not an item block, and a column-one `assesses:` belonging to no item is the
# normal case.
#
# Nothing here judges the assessment. It requires the author to state which
# items a passage assesses — the standard every other annotation meets.
# shellcheck disable=SC2086
assessed_req=$(ids_matching 'assesses:' REQ $rmf_files) || exit 2
# shellcheck disable=SC2086
assessed_llr=$(ids_matching 'assesses:' LLR $rmf_files) || exit 2
assessed="$assessed_req
$assessed_llr"
for id in $derived_ids; do
    gr_contains "$assessed" "$id" && continue
    print_violations "UNANALYZED-DERIVED $id (no 'assesses:' line in the RMF names it)"
    fail=1
done

# --- DANGLING-REF: every referenced ID must be defined somewhere ------------
# Newline-joined, like every other path list here, so a path with a space in
# it stays one argument to git grep.
scope=""
for f in $srs_files $rmf_files $sad_files $soup_files $problems_files \
        $strict_paths $test_paths; do
    [ -n "$f" ] && scope="${scope}${scope:+
}$f"
done
# classify_unresolved ID — the architecture's item-2 table: a scoped reference
# that resolves against nothing classifies by where its definition actually
# lives. One git grep per unresolved ID; unresolved IDs are the rare case.
# A dependency definition wins over another unit's (it names the remedy —
# export it); a disclaimed definition never outranks either.
classify_unresolved() {
    _cid="$1"
    # shellcheck disable=SC2086
    _sites=$(git grep -l --untracked -E "^\\*\\*${_cid}\\*\\*:" -- . "$GR_SCAN_EXCLUDE" $example_excludes)
    _st=$?
    # Status checked, stderr kept: an errored scan finds no site, which
    # classifies the ID as DANGLING-REF rather than reporting the failure.
    [ "$_st" -le 1 ] || gr_die "definition-site scan for $_cid failed (git grep exit $_st)"
    _v=""
    _d=""
    for _sf in $_sites; do
        _w=$(gr_unit_of_path "$_sf") || continue
        case "$_w" in
            (not_a_unit\ *)
                if [ -z "$_v" ]; then
                    _v="DANGLING-REF"
                    _d="(defined only in $_sf, under disclaimed path ${_w#not_a_unit } — disclaimed means outside compliance; that definition is prose, not an item)"
                fi ;;
            (*)
                if gr_contains "$deps" "$_w"; then
                    _v="NON-EXPORTED-REF"
                    _d="(defined in declared dependency $_w, but not exported: yes)"
                    break
                elif [ "$_w" != "$GR_UNIT" ]; then
                    _v="UNDECLARED-DEPENDENCY"
                    _d="(defined in unit $_w, which is not in this unit's depends_on)"
                fi ;;
        esac
    done
    [ -n "$_v" ] || { _v="DANGLING-REF"; _d="(referenced but never defined)"; }
    print_violations "$_v $_cid $_d"
}
if [ -n "$scope" ]; then
    # The trailing boundary is matched and then stripped: without it a mention
    # of a defined ID with one character appended harvests its first six
    # characters and is reported against that ID — which, being defined, is
    # not reported at all. A token can never end in a non-alphanumeric, so the
    # strip cannot damage a real ID.
    #
    # Status checked and stderr not suppressed: this scan is the whole input to
    # DANGLING-REF, and an errored scan finds nothing, which is exactly what a
    # tree with no bad references looks like. Not a pipeline, so $? is git's.
    # shellcheck disable=SC2086
    _refs=$(git grep -h --untracked -oE "(${P})-${GR_ID_BODY}(${GR_ID_TAIL}|\$)" -- $scope $example_excludes)
    _st=$?
    [ "$_st" -le 1 ] || gr_die "reference scan failed (git grep exit $_st)"
    # An example file's references are read from its line-start `verifies:`
    # lines alone. The scan reads the whole scope, as ids_verified's does, for
    # the same reason. With -o and --and git prints the matches of both
    # patterns, so the keyword's match is dropped by the ID filter.
    if [ -n "$example_excludes" ]; then
        # shellcheck disable=SC2086
        _vrefs=$(git grep -h --untracked -oE -e "(${P})-${GR_ID_BODY}(${GR_ID_TAIL}|\$)" \
            --and -e "$VERIFIES_LINE_RE" -- $scope)
        _st=$?
        [ "$_st" -le 1 ] || gr_die "verifies: reference scan failed (git grep exit $_st)"
        # grep exits 1 on no match, which means no reference, not a failure,
        # and it cannot fail on in-memory input; its status is not read.
        _refs="$_refs
$(printf '%s\n' "$_vrefs" | grep -E "^(${P})-")"
    fi
    referenced=$(printf '%s\n' "$_refs" | sed "s/${GR_ID_TAIL}\$//" | sort -u)
    defined=""
    for pfx in $prefixes; do
        _defs=$(ids_defined "$pfx") || exit 2
        defined="$defined
$_defs"
    done
    for id in $referenced; do
        gr_contains "$defined" "$id" && continue
        if [ -n "$GR_UNIT" ]; then
            gr_contains "$foreign" "$id" && continue
            gr_contains "$reverse" "$id" && continue
            classify_unresolved "$id"
        else
            print_violations "DANGLING-REF $id (referenced but never defined)"
        fi
        fail=1
    done
fi

# --- DANGLING-FILE: a draft-named ledger file named in a ledger must exist --
# Under ADR-cy7ahd no merge step renames a ledger file. A draft-named ledger
# file carries the name from before that ADR, which DRAFT-FILE in check-ids.sh
# tells its author to `git mv` to its dated name, and that rename leaves every
# reference to the old name behind, in this tree or in another worktree: those
# are convicted here. Resolve, never ban — a reference to a draft that EXISTS
# is a change not yet renamed, and a gate on the prefix alone is DRAFT-FILE's
# job, not this one's.
#
# Scope is the doc_* files and the SOUP file, not strict_paths: a plan or a
# change record may narrate history, and "created as DRAFT-x.md" is a true
# sentence that must stay true. The token must look like a real file name, so
# the grammar placeholder `DRAFT-<branch>-<slug>.md`, which an adopter's
# ledger README may carry, matches nothing. A path-shaped reference resolves
# from the repository root and then from the referencing file's own
# directory, so the relative link a markdown renderer actually follows is not
# convicted while its target exists. Each arm's message names the places it
# looked rather than asserting the file exists nowhere:
# in a manifest repository a path written relative to another unit's root
# resolves against neither root, and "does not exist" would be false of it.
# A bare basename resolves against every ledger
# directory, because a bare name is how authors cite a sibling ledger.
#
# The token class is the ledger grammar's — letters, digits, underscore, dot,
# hyphen — so a draft named outside it (a + or @ in the slug) is not looked
# for; DRAFT-FILE convicts any DRAFT- name, so this is narrower than that gate,
# deliberately: widening it to any non-space character makes prose match.
# A bare name resolves against THIS config's ledger
# directories: in a manifest repository a bare reference to another unit's
# draft is reported even while that draft exists, because a bare name across
# units is ambiguous — the path form resolves.
file_scope=""
for f in $srs_files $rmf_files $sad_files $soup_files $problems_files; do
    [ -n "$f" ] && file_scope="${file_scope}${file_scope:+
}$f"
done
doc_dirs=""
for _key in doc_srs doc_rmf doc_sad doc_problems; do
    _d=$(cfg_get "$_key")
    [ -n "$_d" ] && [ -d "$_d" ] && doc_dirs="${doc_dirs}${doc_dirs:+
}$_d"
done
if [ -n "$file_scope" ]; then
    # shellcheck disable=SC2086
    _drefs=$(git grep -n --untracked -oE '([A-Za-z0-9_.-]+/)*DRAFT-[A-Za-z0-9_.-]+\.md' -- $file_scope)
    _st=$?
    [ "$_st" -le 1 ] || gr_die "draft reference scan failed (git grep exit $_st)"
    for _dr in $_drefs; do
        [ -n "$_dr" ] || continue
        _dfile=${_dr%%:*}
        _drest=${_dr#*:}
        _dline=${_drest%%:*}
        _dref=${_drest#*:}
        case "$_dref" in
            (*/*)
                [ -e "$_dref" ] && continue
                case "$_dfile" in (*/*) _ddir=${_dfile%/*} ;; (*) _ddir=. ;; esac
                [ -e "$_ddir/$_dref" ] && continue
                _why="names a draft-named ledger file found neither at the repository root nor beside the file naming it — write the name the file has now" ;;
            (*)
                _found=0
                for _d in $doc_dirs; do
                    [ -e "$_d/$_dref" ] && { _found=1; break; }
                done
                [ "$_found" -eq 1 ] && continue
                _why="names a draft-named ledger file found in none of this config's ledger directories — write the name the file has now; across units, write the path" ;;
        esac
        print_violations "DANGLING-FILE $_dref ($_dfile:$_dline $_why)"
        fail=1
    done
fi

# --- HISTORY-CITATION: a plan or docs/verification file is history git keeps
# The squash message is the record. The base branch keeps neither a plan file
# nor a docs/verification file (ADR-k3nkv3), so a dated one named on a line in
# DANGLING-REF's scope cites history that is gone. Only a dated name is a
# citation: a bare directory or a <date>-<slug> placeholder names no file.
# Status checked, as the reference scan's is: an errored scan finds nothing,
# which is what a tree with no citation looks like. A file inside a
# docs/plans/ or docs/verification/ directory, at any depth, is not scanned:
# it is the change's own plan, or history a later change deletes. A
# sentence's closing period is not part of the name. A docs/ directory starts
# a line, follows a /, or follows a character no path component name holds:
# xdocs/plans/ is no docs/plans/ directory. That character is matched and
# dropped from the reported name.
if [ -n "$scope" ]; then
    # shellcheck disable=SC2086
    _hrefs=$(git grep -n --untracked -oE '(^|[^A-Za-z0-9_.-])docs/(plans|verification)/[0-9]{4}-[0-9]{2}-[0-9]{2}-[A-Za-z0-9_.-]+' -- $scope \
        ':(exclude,glob)**/docs/plans/**' ':(exclude,glob)**/docs/verification/**' $example_excludes)
    _st=$?
    [ "$_st" -le 1 ] || gr_die "history citation scan failed (git grep exit $_st)"
    for _hr in $_hrefs; do
        _hfile=${_hr%%:*}
        _hrest=${_hr#*:}
        _href=${_hrest#*:}
        case $_href in
            (docs/*) ;;
            (*) _href=${_href#?} ;;
        esac
        _href=${_href%.}
        print_violations "HISTORY-CITATION $_hfile:${_hrest%%:*} ($_href)"
        fail=1
    done
fi

# --- Problem-report triage --------------------------------------------------
# UNRESOLVED-PR is the roll-call and stays a WARNING: the known-problem review
# it serves is a review, not a prohibition, and an item under the configured
# limits does not fail the run. What DOES fail is an item the roll-call cannot
# state truthfully, and a backlog past a limit the project set for itself.
#
# The reader is anchored for one reason. An unanchored one such as
#
#     cur != "" && /status:[ \t]*open/ { open = 1 }
#
# matches anywhere in the line, and therefore reads a `status:`
# occurrence that check_orphans below CANNOT SEE, because that backstop reports
# a keyword only where a keyword could be read at all. ORPHAN-ANNOTATION
# exists to catch annotations belonging to no item; a reader looking where the
# backstop does not reopens the hole it closed. Worse, an item whose `status:`
# line such a pattern misses — `Status: open`, `status : open`, no `status:`
# line at all — reads as RESOLVED and vanishes from the roll-call: an open
# problem no merge would ever see.
#
# So: gr_kw_here — column one and nothing else, first occurrence in the block
# wins, value from a closed set. Anchoring alone would move the false green
# rather than remove it, which is why the missing-status: violation goes with
# it.
#
# COLUMN ONE AND NOTHING ELSE is what the rule rests on, and the pairing with first
# occurrence is what makes it so. A reader that also accepted a leading list
# marker is rejected: a block quoting `- status: resolved` in its prose, above
# its own column-one `status: open`, would hand the reader the quotation, and
# the open item would leave this roll-call at exit 0 — the very failure the
# anchoring removes, restored by the widening. check_orphans below is
# wider, and that direction is safe: it reports, it does not read. The
# invariant, stated once in lib.sh at gr_kw_here, is backstop-contains-reader.
#
# Ages are whole days in LOCAL time, from `date +%Y-%m-%d`; the arithmetic
# itself is exact (GR_AWK_CIVIL in lib.sh). A one-day disagreement about what
# "today" is, on the other hand, is NOT immaterial in one place: `opened:`
# tomorrow would otherwise be a hard failure on a correct item. One day of
# tolerance is allowed there and clamped to age 0 — see gr_prflush. Two local
# dates differ by more than one only when the offsets differ by more than 24
# hours, which no pair of real timezones does.
#
# Each line is `W <age> <text>` or `F 0 <text>`: W is the roll-call warning and
# contains the age so the summary can report the oldest, F fails the run. The
# split is made in awk, which knows the limits, and the shell only aggregates —
# a `while read` over a pipe runs in a subshell here, where a `fail=1` would be
# lost. An age of -1 means the item is open and cannot be dated.
_prs=$(
    for f in $problems_files; do
        LC_ALL=C awk -v body="$GR_ID_BODY" -v today="$today" \
            -v agelim="$age_limit" \
            "$GR_AWK_ITEM_BLOCK$GR_AWK_CIVIL"'
            function gr_prflush(   age) {
                if (cur == "") return
                # Neither of the next two returns reaches the roll-call, so
                # neither counts toward the backlog. That is deliberate: the
                # gate does not GUESS an unstated status, it demands one. The
                # count can therefore under-report — but only on a run that is
                # already red for that very item, never on a green one.
                if (!st_seen) {
                    printf "F 0 INCOMPLETE-PROBLEM %s (no status: line in its block)\n", cur
                    return
                }
                # A resolved problem report is deleted by the change that
                # fixes it, so no item in a ledger is resolved (ADR-k3nkv3).
                # Like the two above, it leaves the roll-call and counts
                # toward nothing: the run is already red for this item.
                if (st == "resolved") {
                    printf "F 0 RESOLVED-PROBLEM %s (status: resolved — a resolved problem report is deleted)\n", cur
                    return
                }
                if (st != "open" && st != "accepted") {
                    printf "F 0 MALFORMED-STATUS %s (status: %s — expected open or accepted)\n", cur, st
                    return
                }

                # ACCEPTED — a problem the project investigated and ruled on.
                # Exempt from STALE-PROBLEM and from problem_open_max: neither
                # limit measures anything about a decision, and a project that
                # triages honestly should not reach the ceiling faster than one
                # that quietly drops things. NOT exempt from the roll-call.
                #
                # `disposition:` is required, and is the whole reason this
                # status is safe to add: without it `accepted` is a one-word
                # escape from both limits, and the gate ships its own bypass.
                # `opened:` stays required too — an accepted item still has a
                # date, it is judged as a date, and the roll-call prints it.
                # Requiring a field no reader looks at is how `accepted` came
                # to take 2020-13-45 at exit 0 while the identical value on an
                # open item was MALFORMED-DATE.
                if (st == "accepted") {
                    if (!dsp_seen || dsp == "") {
                        printf "F 0 INCOMPLETE-PROBLEM %s (accepted, no disposition:)\n", cur
                        return
                    }
                    if (!opd_seen || opd == "") {
                        printf "F 0 INCOMPLETE-PROBLEM %s (accepted, no opened:)\n", cur
                        return
                    }
                    if (!gr_date_ok(opd)) {
                        printf "F 0 MALFORMED-DATE %s (opened: %s is not a YYYY-MM-DD calendar date)\n", cur, opd
                        return
                    }
                    # WHAT THE DATE IS FOR, here. An accepted item ages against
                    # nothing, so the argument the open branch makes — a
                    # negative age compares as younger than any limit — does
                    # not apply, and there is no age to clamp. What
                    # `opened:` records on either status is WHEN the problem
                    # was raised: the reason the field is required at all,
                    # and the reason the roll-call below prints it. A date
                    # after today falsifies that record on a ruled item exactly
                    # as on an open one, so it is rejected the same way, with
                    # the same ONE day of tolerance and for the same reason —
                    # two local dates disagree by a day, and an author in
                    # UTC+13 must not be blocked on a correct item on the day
                    # they record it. Tolerated, not clamped: no age is
                    # computed here for anything to consume.
                    if (todaydays - GR_DATE_DAYS < -1) {
                        printf "F 0 MALFORMED-DATE %s (opened: %s is more than a day in the future)\n", cur, opd
                        return
                    }
                    # Both returns above leave the roll-call, as the two
                    # INCOMPLETE-PROBLEM returns do and for the same reason: the
                    # run is already red for this very item, and a roll-call
                    # line that contains the date has no honest date to print.
                    printf "A 0 ACCEPTED-PR %s (opened: %s, accepted: %s)\n", cur, opd, dsp
                    return
                }

                # OPEN. Every branch below still reaches the roll-call: an open
                # item missing from it is the defect this gate exists to remove,
                # and an item that cannot be dated is not thereby young.
                age = -1
                if (!opd_seen || opd == "")
                    printf "F 0 INCOMPLETE-PROBLEM %s (open, no opened:)\n", cur
                else if (!gr_date_ok(opd))
                    printf "F 0 MALFORMED-DATE %s (opened: %s is not a YYYY-MM-DD calendar date)\n", cur, opd
                else {
                    age = todaydays - GR_DATE_DAYS
                    # A future date yields a negative age, which compares as
                    # younger than any limit — the false-green direction, so it
                    # is rejected rather than clamped.
                    #
                    # ONE day of tolerance, though, and the day is clamped to
                    # zero. `resolve-problem` tells the author to write today,
                    # and "today" differs by a day across timezones and under
                    # ordinary clock skew: without this, an author in UTC+13
                    # blocks the merge on a correct item on the day they record
                    # it. One day cannot make a stale item look fresh against
                    # limits measured in weeks; a fortnight can, and still
                    # fails.
                    if (age == -1) age = 0
                    else if (age < 0) {
                        printf "F 0 MALFORMED-DATE %s (opened: %s is more than a day in the future)\n", cur, opd
                        age = -1
                    }
                }
                if (age < 0)
                    printf "W -1 UNRESOLVED-PR %s (open, age unrecorded)\n", cur
                else {
                    printf "W %d UNRESOLVED-PR %s (open %d days)\n", age, cur, age
                    if (agelim != "" && age > agelim + 0)
                        printf "F 0 STALE-PROBLEM %s (open %d days, limit %d)\n", cur, age, agelim + 0
                }
            }
            BEGIN {
                gr_block_init("PR", body)
                gr_date_ok(today)   # validated in the shell above
                todaydays = GR_DATE_DAYS
            }
            FNR == 1 { sub(/^\357\273\277/, "") }
            # NO front-matter skip here, and that is a decision, not an
            # omission. Skipping front matter "so the reader and the backstop
            # agree" costs this: a leading `---` taken for a header block
            # swallows every ITEM DEFINITION up to the next `---`, so an open
            # problem vanishes from the roll-call, `problem_open_max` does not
            # apply, and the run exits 0 — every failure this gate exists to
            # prevent, introduced by the gate.
            #
            # The backstop reads ANNOTATIONS, where skipping a real header
            # block is right; this scan reads DEFINITIONS, and the rule for
            # those is already settled across the toolkit — a definition form
            # at column one is judged wherever it appears, fenced block or not.
            #
            # The backstop must tell a header from a horizontal rule too, or
            # a leading `---` switches IT off for the same span and drops
            # every annotation in it. GR_AWK_FRONT_MATTER requires a key on
            # line 2 for that reason. One disagreement
            # remains and is fail-loud: an item definition pasted INSIDE a
            # genuine header block is read here and invisible to the backstop,
            # so its own fields are reported as orphans. A contrived document,
            # reported rather than passed, and named here so it is not
            # rediscovered as a surprise. Skipping was also unobservable in the intended direction —
            # no item block can be open before line 1 — so it removed nothing
            # and lost items. Not skipping keeps this scan in step with
            # `ids_defined`, which is what makes `checked:` and `problems:`
            # reconcilable.
            { line = $0; sub(/\r$/, "", line) }
            gr_block_closes(line) {
                gr_prflush()
                cur = ""
                st = ""; opd = ""; dsp = ""
                st_seen = 0; opd_seen = 0; dsp_seen = 0
                if (gr_block_opens(line)) cur = gr_block_id(line)
            }
            # First occurrence wins, per keyword — the GR_AWK_ID_RUN rule
            # applied to a scalar annotation. A later line cannot reopen an
            # item the first line already closed.
            cur != "" && !st_seen  && gr_kw_here(line, "status:") { st_seen = 1;  st = gr_value(line, "status:") }
            cur != "" && !opd_seen && gr_kw_here(line, "opened:") { opd_seen = 1; opd = gr_value(line, "opened:") }
            cur != "" && !dsp_seen && gr_kw_here(line, "disposition:") { dsp_seen = 1; dsp = gr_value(line, "disposition:") }
            END { gr_prflush() }
        ' "$f" || gr_die "problem-report scan failed on $f"
    done
) || exit 2

_open_n=$(printf '%s\n' "$_prs" | grep -c '^W ' || true)
_undatable_n=$(printf '%s\n' "$_prs" | grep -c '^W -1 ' || true)
# `A` is a third line kind beside `W` and `F`, and a new LETTER rather than a
# `W` with a flag precisely so no aggregation above changes: `_open_n` and
# `_undatable_n` grep `^W `, `_oldest` matches `$1 == "W"`, and the failure
# test greps `^F `. An accepted item is therefore exempt from
# problem_open_max and from the oldest-age figure by construction, not by a
# subtraction somebody has to remember to keep in step.
_accepted_n=$(printf '%s\n' "$_prs" | grep -c '^A ' || true)
# m starts at -1, which is also what an undatable item reports, so "no age
# known" and "the maximum age" are the same value and need no second flag.
# NOT seeded from awk's uninitialised 0: an age of 0 is the one age that does
# not exceed 0, so a ledger whose only open item was opened TODAY would report
# `oldest n/a` — an item counted as open and absent from the age.
_oldest=$(printf '%s\n' "$_prs" | LC_ALL=C awk 'BEGIN { m = -1 } $1 == "W" && $2 + 0 > m { m = $2 + 0 } END { print m }')
if [ -n "$_prs" ]; then
    print_violations "$(printf '%s\n' "$_prs" | cut -d' ' -f3-)"
    printf '%s\n' "$_prs" | grep -q '^F ' && fail=1
fi
if [ -n "$open_limit" ] && [ "$_open_n" -gt "$open_limit" ]; then
    _noun="open problem reports"
    [ "$_open_n" -eq 1 ] && _noun="open problem report"
    print_violations "PROBLEM-BACKLOG ($_open_n $_noun, limit $open_limit)"
    fail=1
fi

# --- ORPHAN-ANNOTATION: an annotation that belongs to no item --------------
# The backstop to the block rule, and the reason that rule can be relaxed
# safely. Blocks end at a header shape rather than at any bold line, but
# every termination rule has an outside. An annotation before the first item
# in a file, or under a heading with no item since, belongs to nothing under
# ANY rule. Without this gate it is read, matched, and dropped in silence:
# `status: open` on such a line leaves the item open in the ledger and absent
# from the known-problem review, with the run still exiting 0.
#
# Scope is per keyword, and only where that keyword is BLOCK-parsed:
# `verifies:` and `assesses:` are read line-wise by ids_matching, never against
# a block, so they cannot be orphaned. Reporting them anyway — or reporting
# `status:` from the SRS, where nothing reads it — would be noise, and noise
# is what teaches people to read past the output. `implements:` and
# `mitigates:` are block-parsed by credit_scan, so they are covered.
#
# Column one, or column one after a run of list markers, task-list boxes and
# blockquote markers: gr_kw_orphan_here, which is WIDER than the gr_kw_here every reader
# uses, and deliberately so. The invariant is a containment — the backstop must
# see at least what every reader sees — and never an equality. Widening the
# readers to match this instead was tried and rejected: the readers are
# first-occurrence-wins, so a wide reader lets a QUOTED `- status: resolved`
# outrank the item's own column-one `status: open`. lib.sh states both
# regressions at gr_kw_here.
#
# Wider costs nothing here. This gate REPORTS; it takes no value and decides
# no item's state, so a bulleted annotation outside every block is reported
# although no reader would take it. Inside a block, gr_annotation takes an
# ID-list keyword only at column one or on the definition line, so the same
# lead there is reported too: `- satisfies: derived` on a REQ would otherwise
# leave it out of UNANALYZED-DERIVED at exit 0.
#
# A line with NO marker is tested unchanged, and that is what keeps the
# indented item grammar shipped in templates/problems.md inert — the property
# that makes this gate adoptable without editing every ledger that already
# exists. It is the absence of a marker that keeps illustrative prose quiet,
# never its indentation.
check_orphans() {
    _kw="$1"
    _open="$2"
    shift 2
    # The ID-list keywords gr_annotation reads inside a block are also
    # reported there, where a lead hides them from it. The scalar fields are
    # not: a quoted `- status: resolved` in a problem's prose is not a field,
    # and INCOMPLETE-PROBLEM already reports one written that way.
    case "$_kw" in
        (satisfies:|traces:|implements:|mitigates:) _idlist=1 ;;
        (*) _idlist=0 ;;
    esac
    for _f in "$@"; do
        [ -n "$_f" ] || continue
        # LC_ALL=C: defence in depth, and honestly weak — the close and the
        # keyword test are substr/index, which count bytes in every locale, and
        # the only locale-sensitive construct left is the octal-escape BOM
        # strip below. No test distinguishes this setting on gawk 5.3.2, mawk
        # or busybox awk; it is kept because the escapes are byte values and
        # some awk in some locale will read them as characters.
        LC_ALL=C awk -v body="$GR_ID_BODY" -v popen="$_open" -v kw="$_kw" -v fname="$_f" \
            -v idlist="$_idlist" "$GR_AWK_ITEM_BLOCK$GR_AWK_FRONT_MATTER"'
            # The opening prefix is the reader of THIS keyword, never every
            # declared prefix. Opening on all of them left a third state the
            # gates do not have: inside another prefix block, where the reader
            # sees nothing (it opens only on its own prefix) while the backstop
            # sees a block open. An extra prefix is a supported config and is
            # not placement-checked, so an ADR header in the SRS swallowed a
            # `satisfies: derived` with both gates silent and the run at exit 0.
            BEGIN { gr_block_init(popen, body); gr_fm_reset() }
            # A BOM is in front of column one and hides it from every
            # match below, front-matter delimiter included. Stripped in both
            # passes; LC_ALL=C on the invocation is what makes the octal
            # escapes byte-exact, the same reasoning gr_check_config uses.
            FNR == 1 { sub(/^\357\273\277/, "") }
            # Front matter is skipped, bounded, in two passes. The rule has ONE
            # definition — GR_AWK_FRONT_MATTER in lib.sh — because
            # check-review.sh reads it too, and two hand-copied versions of a rule
            # drift apart and then read one file two ways.
            FNR == NR { gr_fm_scan($0, FNR); next }
            gr_fm_skip(FNR) { next }
            gr_block_closes($0) {
                inblock = gr_block_opens($0)
                cur = inblock ? substr($0, 3, index(substr($0, 3), "**") - 1) : ""
            }
            !inblock && gr_kw_orphan_here($0, kw) {
                # FNR, never NR: the file is read TWICE (see the
                # front-matter pass above), so NR is offset by the whole first
                # pass and every reported line number would be wrong.
                printf "ORPHAN-ANNOTATION %s:%d (%s belongs to no item)\n", \
                    fname, FNR, kw
            }
            # Inside the block, an ID-list keyword the backstop sees but
            # gr_annotation does not take: the item made no annotation, and
            # nothing else says so for satisfies: derived on a REQ.
            inblock && idlist && gr_kw_orphan_here($0, kw) && gr_annotation($0, kw) == "" {
                printf "ORPHAN-ANNOTATION %s:%d (%s inside %s is not at column one; no gate reads it)\n", \
                    fname, FNR, kw, cur
            }
        ' "$_f" "$_f" || gr_die "orphan scan failed on $_f"
    done
}
# shellcheck disable=SC2086
_sat_files=$(printf '%s\n' $sad_files $srs_files | sort -u)
# One list of every ledger kind, so the SUPERSESSION-ANNOTATION scan below
# reads every ledger file, and a file two ledger settings share only once:
# its findings are not reported twice.
# shellcheck disable=SC2086
_sup_files=$(printf '%s\n' $srs_files $rmf_files $sad_files $problems_files | sort -u)
# shellcheck disable=SC2086
_orphans=$(
    check_orphans 'status:' PR $problems_files
    # The reader added `opened:` to the same block, so the backstop covers it
    # too: under a looser block rule an orphaned opened: is credited to the
    # item above, and an undated item then reads as dated.
    check_orphans 'opened:' PR $problems_files
    # Block-parsed, so the backstop covers it: an orphaned
    # disposition: would otherwise be credited to nothing while the accepted
    # item above it reads as undisposed.
    #
    # Scoped to the problems ledger, the one place this scan reads it.
    check_orphans 'disposition:' PR $problems_files
    check_orphans 'traces:' SDD $sad_files
    # ONE scan over the union, opening on BOTH prefixes that read `satisfies:`.
    # Two scans over two lists reported a false positive when doc_srs and
    # doc_sad resolve to the same directory: the LLR gate read the annotation
    # correctly, while the REQ-opening scan saw the LLR header close a block
    # without opening one and called the line an orphan. Opening on a prefix
    # that is misplaced in that document costs nothing — MISPLACED-ITEM is
    # already red for it.
    check_orphans 'satisfies:' 'LLR|REQ' $_sat_files
    # credit_scan reads `implements:` on REQ blocks of doc_srs and
    # `mitigates:` on RC blocks of doc_rmf, so the backstop opens on the same
    # prefix over the same files: a stray column-one line credits nothing, and
    # this names the line to move into the item's block.
    check_orphans 'implements:' REQ $srs_files
    check_orphans 'mitigates:' RC $rmf_files
) || exit 2
if [ -n "$_orphans" ]; then
    print_violations "$_orphans"
    fail=1
fi

if [ -n "$GR_UNIT" ]; then
    # shellcheck disable=SC2086
    _ann_files=$(printf '%s\n' $srs_files $rmf_files $sad_files $problems_files | sort -u)
    _orphans2=$(
        check_orphans 'exported:' 'REQ|HAZ|RC|SDD|LLR|PR' $_ann_files
        check_orphans 'expects:'  'REQ|HAZ|RC|SDD|LLR|PR' $_ann_files
        check_orphans 'opened:'   'REQ|HAZ|RC|SDD|LLR|PR' $srs_files
    ) || exit 2
    if [ -n "$_orphans2" ]; then
        print_violations "$_orphans2"
        fail=1
    fi
fi

# --- SUPERSESSION-ANNOTATION: supersession is deletion (ADR-k3nkv3) --------
# Every item in a ledger is in force. An item whose behavior changed is
# replaced by a new item under a new ID and deleted; an item whose behavior
# is gone is deleted; the squash message records old → new, or the reason,
# under Items:. So a supersedes:, superseded-by: or retired: line states
# something no gate reads, and it is reported wherever it stands.
#
# The orphan backstop's position, gr_kw_orphan_here: column one, or column one
# after list markers. A line with no marker, indented or mid-line, is prose.
# The awk opens no block and skips nothing, front matter included: the
# finding does not depend on which item, if any, the line sits in.
#
# The awk status is kept, and that is why the lines are taken before they are
# printed: an `awk | ...` pipeline reports the last command's status, so an awk
# that exited 2 would read as a tree with no supersession annotation in it.
# The lines come out in file order, then line order: _sup_files is sorted.
if [ -n "$_sup_files" ]; then
    # shellcheck disable=SC2086
    _sup_raw=$(
        LC_ALL=C awk "$GR_AWK_ITEM_BLOCK"'
            FNR == 1 { sub(/^\357\273\277/, "") }
            {
                line = $0; sub(/\r$/, "", line)
                if (gr_kw_orphan_here(line, "supersedes:")) kw = "supersedes:"
                else if (gr_kw_orphan_here(line, "superseded-by:")) kw = "superseded-by:"
                else if (gr_kw_orphan_here(line, "retired:")) kw = "retired:"
                else next
                printf "SUPERSESSION-ANNOTATION %s:%d (%s)\n", FILENAME, FNR, kw
            }
        ' $_sup_files < /dev/null
    ) || gr_die "supersession scan failed"
    if [ -n "$_sup_raw" ]; then
        print_violations "$_sup_raw"
        fail=1
    fi
fi

# --- Summary: report the denominator ----------------------------------------
# Two numbers, because one is not enough. `checked:` counts the items found;
# `sources:` counts the files and paths each gate actually read. An item count
# alone states nothing about whether the gate for those items was run at all.
# Printed on pass and on failure alike, so every result states what it covered.
count_lines() {
    printf '%s' "$1" | grep -c . || true
}

summary=""
for pfx in $prefixes; do
    _defs=$(ids_defined "$pfx") || exit 2
    def_count=$(count_lines "$_defs")
    summary="${summary}${summary:+, }${pfx} ${def_count}"
done

# One remedy line per rule, in the order the rules first fired.
for rule in $fired_rules; do
    remedy=$(check_trace_remedy "$rule") || continue
    printf 'fix %s: %s\n' "$rule" "$remedy"
done

echo "checked: $summary"
# The third summary line, and the reason an unset limit is not a silent one.
# A team that has switched a limit off reads that fact at every merge, next to
# the backlog the limit was meant to cap.
_oldest_txt="n/a"
[ "$_oldest" -ge 0 ] && _oldest_txt="$_oldest days"
# Reported separately rather than folded into `oldest`, because it is the one
# number the age cannot represent: an item whose age is unknown is open all the
# same, and an `oldest` that quietly ignored it would read as if every open
# item had been accounted for.
#
# "no usable date", not "undated": the count includes an item whose `opened:`
# was REJECTED — malformed, or too far ahead — as well as one that has none.
# Both are open and of unknown age; only one of them is undated.
[ "$_undatable_n" -gt 0 ] && _oldest_txt="$_oldest_txt ($_undatable_n with no usable date)"
# `accepted` is reported next to `open` rather than folded into it or left
# out: it is exempt from both limits, so a reader who cannot see the number
# cannot tell a project that ruled on twelve problems from one that has none.
echo "problems: open $_open_n, accepted $_accepted_n, oldest $_oldest_txt; limits age ${age_limit:-none}, open ${open_limit:-none}"
if [ -n "$GR_UNIT" ]; then
    echo "scope: unit $GR_UNIT; foreign $(count_lines "$foreign"), reverse $(count_lines "$reverse")"
    [ -n "$exp_summary" ] && echo "$exp_summary"
    # The provider-side advisory: the open expectations standing against THIS unit,
    # computed from the reverse edge and our own exports. Exit 0 — the
    # consumer's aging budget is the gate; this is the courtesy on top.
    _against=0
    for _rid in $reverse; do
        [ -n "$_rid" ] || continue
        _ans=$(printf '%s\n' "$own_scan" | awk -F'\t' -v want="$_rid" '
            $3 == "EXP" && $4 == "yes" { expd[$1] = 1 }
            $3 == "SAT" && $4 == want  { sat[$1] = 1 }
            END { for (req in sat) if (req in expd) { print "met"; exit } }')
        [ "$_ans" = "met" ] || _against=$((_against + 1))
    done
    echo "expectations against this unit: $_against open"
fi
echo "sources: srs $(count_lines "$srs_files"), rmf $(count_lines "$rmf_files"), sad $(count_lines "$sad_files"), soup $(count_lines "$soup_files"), problems $(count_lines "$problems_files"); strict $(count_lines "$strict_paths"), tests $(count_lines "$test_paths"), examples $(count_lines "$example_paths")"

exit $fail
