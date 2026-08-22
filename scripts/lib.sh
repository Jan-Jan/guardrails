#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# guardrails shared helpers — POSIX sh, sourced by the check/finalize scripts.
# Scripts run from the target repo root. GR_CONFIG overrides the config path.
#
# Several helpers below call gr_die, which exits 2. A helper invoked inside a
# command substitution dies only in that subshell, so EVERY `x=$(gr_...)` call
# site must append `|| exit 2` — otherwise the caller sails past the error with
# an empty value, which is the exact false-green failure these checks exist to
# prevent.

GR_CONFIG="${GR_CONFIG:-.guardrails/config.yaml}"

# Every top-level key guardrails understands. A key outside this set is a typo,
# and a typo'd key is invisible: cfg_get returns nothing, the gate that reads it
# is skipped, and the run exits 0 having proved nothing.
# The ID prefixes with a traceability gate of their own. Others are allowed:
# DANGLING-REF, DUPLICATE-ID and draft finalization are all keyed on the
# configured prefix list, so an extra prefix (ADR, say) is genuinely checked,
# just not by a gate specific to it. What is rejected is a config where NONE
# of these appears — every traceability gate is then off and the run still
# exits 0.
GR_GATED_PREFIXES='REQ
HAZ
RC
SDD
LLR
PR'

GR_KNOWN_KEYS='guardrails_version
safety_class
id_prefixes
doc_srs
doc_rmf
doc_sad
doc_soup
doc_problems
strict_paths
test_paths
verify_commands
coverage_command'

# The annotation-list rule as an awk function, defined ONCE and prepended to
# every awk program that needs it. gr_id_run(line, kw) returns the space-
# separated IDs of the list immediately following the FIRST occurrence of kw on
# line; the run ends at the first character that is not an ID, comma or space,
# so `verifies: REQ-001 (was REQ-042)` yields REQ-001 alone — prose after the
# list is commentary, never coverage.
#
# One definition is the point. Three near-copies of this rule is how `traces:`
# came to demand a REQ at the head of its run while `satisfies:` scanned from
# the LAST occurrence on the line and credited a REQ mentioned in prose.
GR_AWK_ID_RUN='
function gr_id_run(line, kw,   p, rest, out, tok) {
    p = index(line, kw)
    if (p == 0) return ""
    rest = substr(line, p + length(kw))
    out = ""
    while (match(rest, /^[ \t,]*[A-Za-z]+-[0-9][0-9][0-9]+/)) {
        tok = substr(rest, RSTART, RLENGTH)
        sub(/^[ \t,]*/, "", tok)
        out = out (out == "" ? "" : " ") tok
        rest = substr(rest, RSTART + RLENGTH)
    }
    return out
}
'

gr_die() {
    echo "guardrails: $*" >&2
    exit 2
}

gr_root() {
    git rev-parse --show-toplevel 2>/dev/null || gr_die "not inside a git repository"
}

# gr_contains LIST ITEM — is ITEM one of the newline-separated LIST entries?
gr_contains() {
    case "
$1
" in *"
$2
"*) return 0 ;; esac
    return 1
}

# Value cleanup shared by cfg_get and cfg_list: drop a trailing CR (a config
# saved with CRLF endings otherwise puts an invisible \r inside every value,
# and the resulting error message accuses a path or prefix that looks perfectly
# valid), drop a trailing ` # comment`, then drop trailing blanks.
#
# The comment strip requires whitespace before the `#`, so `path#anchor` and
# `sh -c 'echo "#done"'` survive. It cannot be escaped: a value whose own
# whitespace-delimited token starts with `#` is truncated silently. That is
# recorded in templates/config.yaml rather than worked around.
GR_AWK_CLEAN_VALUE='
function gr_clean(v) {
    sub(/\r$/, "", v)
    sub(/[ \t]+#.*$/, "", v)
    sub(/[ \t]+$/, "", v)
    return v
}
'

# cfg_get KEY — print the scalar value of a top-level `key: value` entry.
cfg_get() {
    [ -f "$GR_CONFIG" ] || gr_die "config not found: $GR_CONFIG"
    awk -v k="$1" "$GR_AWK_CLEAN_VALUE"'
        index($0, k ":") == 1 { sub(/^[^:]*:[ \t]*/, ""); print gr_clean($0); exit }
    ' "$GR_CONFIG"
}

# cfg_list KEY — print items of a top-level `key:` block of `  - item` lines.
cfg_list() {
    [ -f "$GR_CONFIG" ] || gr_die "config not found: $GR_CONFIG"
    awk -v k="$1" "$GR_AWK_CLEAN_VALUE"'
        !inlist && index($0, k ":") == 1 { inlist = 1; next }
        # A column-one line ends the block, comments included. Skipping them
        # instead would silently ADOPT any items below into this list — an
        # item under a commented-out key would become a member of whatever
        # block was open above it. gr_check_config rejects that shape outright
        # rather than either reader guessing at it.
        inlist && /^[^ \t]/ { exit }
        inlist && /^[ \t]*-[ \t]/ { sub(/^[ \t]*-[ \t]*/, ""); print gr_clean($0) }
    ' "$GR_CONFIG"
}

# gr_prefixes — the configured ID prefixes, one per line, validated. A prefix
# is interpolated into regular expressions, so a metacharacter here makes every
# ID scan an invalid pattern; git grep then errors, matches nothing, and an
# errored scan is indistinguishable from a clean tree. Reject it at the source.
gr_prefixes() {
    _v=$(cfg_get id_prefixes)
    [ -n "$_v" ] || gr_die "id_prefixes not configured"
    # id_prefixes is a space-separated scalar, but callers that handle path
    # lists run with IFS set to newline. Split on the default set regardless of
    # the caller's IFS, or the whole value arrives as one "prefix".
    _saved_ifs=${IFS-__gr_unset__}
    unset IFS
    _out=""
    for _one in $_v; do
        case "$_one" in
            [!A-Za-z]* | *[!A-Za-z0-9]*)
                gr_die "id_prefixes entry is not a bare identifier: $_one" ;;
        esac
        _out="${_out}${_one}
"
    done
    if [ "$_saved_ifs" = "__gr_unset__" ]; then unset IFS; else IFS=$_saved_ifs; fi
    printf '%s' "$_out"
}

# gr_prefix_re — ERE alternation of the configured ID prefixes: REQ|HAZ|RC|SDD
gr_prefix_re() {
    # NOT `gr_prefixes | tr …`: in a pipeline the function's exit status is the
    # last command's, so a gr_die here would be reported as success and every
    # `P=$(gr_prefix_re) || exit 2` guard at the call sites would be dead code.
    _p=$(gr_prefixes) || exit 2
    printf '%s' "$_p" | tr '\n' '|' | sed 's/|$//'
}

# GR_SCAN_EXCLUDE — the one pathspec every tree-wide scan excludes.
#
# Used as `git grep … -- . "$GR_SCAN_EXCLUDE"` at every site in check-ids.sh,
# check-trace.sh and finalize-ids.sh. One definition because those scans must
# agree about which files exist: while finalize-ids.sh's mint scan and its own
# pre-flight disagreed with nothing, they agreed with each other only by having
# been typed the same way fifteen times.
#
# It names `.guardrails/scripts`, NOT `.guardrails`. The exclusion exists so the
# installed scripts do not report themselves — their comments carry a literal
# `REQ-DRAFT-b-1` and definition-form examples — and the scripts are the only
# thing under `.guardrails/` that matches any gate's pattern; config.yaml
# matches none. Excluding the whole directory also hid the project's own files:
# with `doc_srs: .guardrails/docs/requirements`, finalize-ids.sh renamed the
# draft ledger to its merge-date name, minted nothing, and exited 0, and both
# check scripts then passed a tree with a live `REQ-DRAFT-x-1` in it.
# Narrowing cannot reach one case: a doc_* configured INSIDE this directory is
# still accepted, and checked: counts its items as zero. Whether any gate
# complains first depends on whether git tracks or ignores the ledger, and on
# whether finalization has run — the same is true of .git/, gitignored paths
# and symlinks leaving the repository. The measured matrix is in
# docs/verification/2026-08-20-scan-pathspec.md. A check that refused the shape
# outright was attempted and cut; see the same record.
#
# A variable, not a function like gr_def_re: this is a separate `git grep`
# argument, and a function's output would have to be word-split — which
# finalize-ids.sh and check-trace.sh cannot do, both setting IFS to newline at
# top level. Assigned unconditionally, never `${GR_SCAN_EXCLUDE:-…}`: a value
# inherited from the environment could widen it to `:(exclude).` and blind
# every gate in the toolkit while each one still exited 0.
GR_SCAN_EXCLUDE=':(exclude).guardrails/scripts'

# gr_def_re ALTERNATION [POSITION] — ERE matching an item definition
# line: a bold ID followed immediately by a colon, at line start.
#
# One constructor because three scripts must agree about the same string:
# check-ids.sh decides what is a duplicate, finalize-ids.sh decides what
# number comes next, and check-trace.sh decides what exists at all. While
# they disagreed, finalize-ids.sh alone matched the form UNANCHORED, so a
# token in prose raised the mint ceiling that neither gate could see.
#
# POSITION is spliced in front and defaults to `^`. Pass '^\+' or '^-' to scan
# `git diff` output, where a definition sits at line start behind a + or -, and
# the empty string to match the token anywhere on a line. Do NOT express that
# last case as '^.+': git's matcher backtracks on a leading .+ and costs tens
# of seconds per prefix on a few hundred documents, against tenths of a second
# for the unanchored form. The verification record carries the measurement and
# the corpus commit it was taken on; a bare number here could not be re-derived
# and drifted into three different values.
gr_def_re() {
    printf '%s' "${2-^}\\*\\*(${1})-[0-9]{3,}\\*\\*:"
}

# gr_base_branch — the branch checked out in the primary (non-worktree)
# checkout, which is what a change merges into. Prints nothing if the
# primary checkout is detached; never falls back to a linked worktree's
# branch.
gr_base_branch() {
    git worktree list --porcelain 2>/dev/null | awk '
        /^worktree / { n++ }
        n > 1 { exit }
        sub(/^branch refs\/heads\//, "") { print; exit }
    '
}

# gr_doc_files KEY — resolve a doc_* config value to a file list, one per
# line. A directory yields its *.md files (sorted); a file yields itself; a
# missing KEY yields nothing (the project does not use that document).
#
# Two cases are ERRORS, not empty lists: a key configured to a path that does
# not exist, and a directory holding no *.md at all. Silently yielding nothing
# there turns whole gate families into no-ops that still exit 0.
gr_doc_files() {
    _v=$(cfg_get "$1")
    [ -n "$_v" ] || return 0
    if [ -d "$_v" ]; then
        _n=0
        for _f in "$_v"/*.md; do
            [ -f "$_f" ] || continue
            _n=$((_n + 1))
            printf '%s\n' "$_f"
        done
        [ "$_n" -gt 0 ] || \
            gr_die "$1 is configured as directory '$_v', which contains no *.md files"
    elif [ -f "$_v" ]; then
        printf '%s\n' "$_v"
    else
        gr_die "$1 is configured as '$_v', which does not exist"
    fi
    return 0
}

# gr_check_config — refuse a config that would silently disable a gate. Every
# rejection here is a shape the config READER cannot see, which is why none of
# them could ever be reported by the gate that was meant to use the value.
gr_check_config() {
    [ -f "$GR_CONFIG" ] || gr_die "config not found: $GR_CONFIG"

    # A UTF-8 BOM makes the first key unreadable by every awk matcher here, so
    # it must be rejected explicitly — the alternative is a first key that
    # silently reads as absent. Detected in awk (octal escapes are POSIX)
    # rather than with `head -c`, which is not in POSIX head. LC_ALL=C so
    # substr counts bytes: in a UTF-8 locale awk counts characters and the
    # three BOM bytes are one of them.
    if [ -n "$(LC_ALL=C awk 'NR == 1 { if (substr($0, 1, 3) == "\357\273\277") print "bom"; exit }' "$GR_CONFIG" 2>/dev/null)" ]; then
        gr_die "config begins with a UTF-8 BOM: $GR_CONFIG — save it as plain UTF-8"
    fi

    # Every line must be blank, a comment, a `  - item` list entry, a `---`
    # document separator, or exactly `<key>:` at column one. Matching only
    # /^[A-Za-z_]+:/ is not enough: that is the same shape cfg_get matches, so
    # a key invisible to the reader would be equally invisible to the check.
    #
    # `owner` tracks what the most recent column-one line was. An indented
    # `  - item` only belongs to a key; under a comment it is an orphan, and
    # an orphan is ambiguous in a way no reader can resolve safely — it either
    # vanishes with the rest of its list or is adopted by the block above,
    # which is how `- src` under a commented-out `strict_paths:` could become
    # a test path. Reject it rather than pick a side.
    _malformed=$(awk '
        { line = $0; sub(/\r$/, "", line) }
        # A separator ends a block in cfg_list too, so it must break the
        # ownership chain — otherwise an item after one is silently dropped.
        line ~ /^---[ \t]*$/ || line ~ /^\.\.\.[ \t]*$/ { owner = "separator"; next }
        line ~ /^[ \t]*$/ { next }
        line ~ /^[ \t]*#/ { if (line ~ /^#/) owner = "comment"; next }
        line ~ /^[ \t]+-[ \t]/ { if (owner != "key") print NR; next }
        line !~ /^[A-Za-z_][A-Za-z0-9_]*:/ { print NR; next }
        { owner = "key" }
    ' "$GR_CONFIG")
    if [ -n "$_malformed" ]; then
        _msg=""
        for _n in $_malformed; do
            _msg="${_msg}
  line ${_n}: $(sed -n "${_n}p" "$GR_CONFIG")"
        done
        gr_die "config line(s) that are neither a comment, a top-level key, nor a '  - item' belonging to one:${_msg}"
    fi

    _unknown=""
    for _k in $(awk '/^[A-Za-z_][A-Za-z0-9_]*:/ { sub(/:.*/, ""); print }' "$GR_CONFIG"); do
        gr_contains "$GR_KNOWN_KEYS" "$_k" || _unknown="${_unknown} $_k"
    done
    [ -z "$_unknown" ] || gr_die "unknown config key(s):${_unknown}"

    # gr_prefixes dies in a subshell here, so the status must be propagated or
    # the loops below would iterate over nothing.
    _pfx=$(gr_prefixes) || exit 2

    _gated=""
    for _p in $_pfx; do
        gr_contains "$GR_GATED_PREFIXES" "$_p" && _gated=1
    done
    [ -n "$_gated" ] || gr_die \
"id_prefixes names no prefix with a traceability gate: $(printf '%s' "$_pfx" | tr '\n' ' ')
  At least one of REQ HAZ RC SDD LLR PR must appear. Others may be declared
  alongside them — they are covered by DANGLING-REF and DUPLICATE-ID, just not
  by a gate of their own. Without any of the six, the only checks left are
  those two, and a config that also omits the document keys would run nothing
  at all and still exit 0."

    # TWO rules, deliberately separate, because they answer different
    # questions and one of them changed when the placement gate landed.
    #
    # Rule 1 — gate inputs: documents whose absence would SILENTLY SKIP one of
    # this prefix's gates. Not always the document the prefix is defined in:
    # UNIMPLEMENTED-CONTROL looks for a REQ that implements each RC, so RC
    # needs doc_srs.
    #
    # This is deliberately NOT the full set of documents every gate reads.
    # UNANALYZED-DERIVED also reads doc_rmf, and the transitive half of
    # MISSING-TEST also reads doc_sad, but both FAIL RED without their input
    # rather than passing vacuously — so requiring those keys would forbid
    # legitimate shapes, such as a class A project with no architecture
    # document. The rule is "no gate is ever silently skipped", not "every gate
    # has every input", and this comment must keep saying so: an earlier draft
    # claimed the map was complete and a reviewer proved it was not.
    for _p in $_pfx; do
        case "$_p" in
            REQ) _need="doc_srs" ;;
            HAZ) _need="doc_rmf" ;;
            RC)  _need="doc_srs" ;;
            SDD) _need="doc_sad" ;;
            LLR) _need="doc_sad" ;;
            PR)  _need="doc_problems" ;;
            *)   continue ;;
        esac
        for _k in $_need; do
            [ -n "$(cfg_get "$_k")" ] || \
                gr_die "id_prefixes declares $_p but $_k is not configured — a gate for $_p reads it, so that gate could never run"
        done
    done

    # Rule 2 — definition documents: the one document MISPLACED-ITEM requires
    # each item of this prefix to be defined in. Unconfigured, that gate is not
    # skipped — it condemns every item of the prefix, correctly but once per
    # item, naming a key the project never set. Say it once instead.
    #
    # Only RC differs from rule 1: a risk control is defined in the RMF, while
    # the gate that reads controls reads the SRS. Every other entry is already
    # required above, so this rule rejects exactly one new shape: RC declared
    # with no doc_rmf, which configures a project where no control can ever be
    # correctly placed. Change B's map had RC needing doc_srs and NOT doc_rmf,
    # with the reason that no RC gate read doc_rmf — true until this gate
    # existed, and recorded here so the reversal reads as the premise change it
    # is rather than an oscillation.
    for _p in $_pfx; do
        case "$_p" in
            REQ)    _home="doc_srs" ;;
            HAZ|RC) _home="doc_rmf" ;;
            SDD|LLR) _home="doc_sad" ;;
            PR)     _home="doc_problems" ;;
            *)      continue ;;
        esac
        [ -n "$(cfg_get "$_home")" ] || \
            gr_die "id_prefixes declares $_p but $_home is not configured — that is the only document a $_p may be defined in, so every $_p would be misplaced"
    done

    if gr_contains "$_pfx" REQ || gr_contains "$_pfx" LLR; then
        [ -n "$(cfg_list test_paths)" ] || \
            gr_die "id_prefixes declares REQ/LLR but test_paths is empty — nothing would be searched for 'verifies:'"
    fi
}

# gr_id_run KEYWORD — filter: for each stdin line, print the IDs of the list
# that immediately follows KEYWORD, one per line. See GR_AWK_ID_RUN above for
# the rule; this is the shell-pipeline face of the same single definition.
gr_id_run() {
    awk -v kw="$1" "$GR_AWK_ID_RUN"'
        {
            r = gr_id_run($0, kw)
            if (r == "") next
            n = split(r, a, " ")
            for (i = 1; i <= n; i++) print a[i]
        }'
}
