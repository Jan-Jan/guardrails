#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Dr. Jan-Jan van der Vyver
# check-units.sh [--impact RANGE | --exports UNIT | --list]
#
# The repository-level entry point of the unit machinery
# (docs/plans/2026-09-03-units-architecture.md item 6). Default mode, exit 1
# findings after exit-2 validation:
#   UNCLAIMED-PATH PATH      — a tracked path claimed by no unit, not
#                              disclaimed, not a root-level file, not under
#                              the root .guardrails/ (D7)
#   MISCLASSED-DEPENDENCY U  — provider U's class below the ceiling of its
#                              consumers' classes, with no covering
#                              segregation (D5)
#   INCOMPLETE-SEGREGATION   — a segregated_from: entry that names a
#                              non-dependency, cites a control nobody defined,
#                              an ADR file that is absent, or nothing at all
#   DISCLAIMED-DRAFT         — a draft token or DRAFT-named file under a
#                              not_a_unit: path (risk assessment 3,
#                              2026-09-03): draft work has no legitimate home
#                              in a disclaimed directory, and no unit's scoped
#                              run scans one, so the conviction lives here —
#                              blocking every unit's merge is the point.
#                              MALFORMED-ID is deliberately NOT scanned on
#                              disclaimed paths: legacy prose in definition
#                              shape would convict line by line and drive
#                              pattern-widening (disclaimed-prose-is-not-
#                              malformed).
#
# Without a manifest, default mode exits 0 — AFTER refusing (exit 2) the two
# shapes that make "single-unit repository" a false reading: two or more
# unit-shaped configs with no manifest (a unit outside compliance at exit 0),
# and a near-miss manifest name in .guardrails/ with manifest-shaped content
# (a mistyped units.yaml silently reverting the repo to single-unit mode; risk
# assessment 2, 2026-09-03). The repository root is deliberately not scanned
# for near-misses — that is where another tool's units.yml legitimately lives.
#
# --impact RANGE: the units a change must run — touched units plus transitive
#   dependents (D6+D12), one per line as "<unit>\t<touched|dependent>". A
#   changed path claimed by nobody is exit 2 HERE (a partial impact set would
#   read as complete to merge-change); the finding to fix is default mode's
#   UNCLAIMED-PATH. A change under the root .guardrails/ maps to EVERY unit.
# --exports UNIT: the unit's export surface, "<REQ-id>\t<file>" per line —
#   the same computation (gr_exported_reqs) a consumer's verdicts resolve
#   against, so the report cannot lie about the gate.
# --list: the declared units, one per line (base-branch CI runs the union).
# All three flag modes REQUIRE the manifest: an empty exit-0 list would read
# as "no units to run" to a CI caller, which is a skipped suite wearing a
# green light.
#
# Exit codes: 0 pass, 1 findings (default mode), 2 usage/environment error.
set -u

. "$(dirname "$0")/lib.sh"
# NOT `cd "$(gr_root)" || exit 2`: gr_root's gr_die exits only the command
# substitution, and under dash `cd ""` returns 0 and stays put.
gr_repo_root=$(gr_root) || exit 2
cd "$gr_repo_root" || exit 2

mode=default
arg=""
case "${1:-}" in
    ('') ;;
    (--impact)  mode=impact;  arg="${2:-}"; [ -n "$arg" ] || gr_die "usage: check-units.sh --impact RANGE"; [ $# -le 2 ] || gr_die "unknown argument: $3" ;;
    (--exports) mode=exports; arg="${2:-}"; [ -n "$arg" ] || gr_die "usage: check-units.sh --exports UNIT";  [ $# -le 2 ] || gr_die "unknown argument: $3" ;;
    (--list)    mode=list; [ $# -le 1 ] || gr_die "unknown argument: $2" ;;
    (*) gr_die "unknown argument: $1" ;;
esac

# Path lists are newline-separated throughout; entries reach git verbatim.
IFS='
'
set -f

# gr_units_present is byte-exact (see lib.sh): on a case-insensitive
# filesystem a UNITS.YAML or Units.yaml is a manifest that does not exist, so
# it falls through to the near-miss scan below, which names the remedy
# (near-miss-manifest-name-is-exit-2) instead of routing the phantom into
# gr_check_units, whose diagnosis would name the wrong defect.
manifest_exact=0
if gr_units_present; then
    manifest_exact=1
fi

if [ "$manifest_exact" -eq 0 ]; then
    [ "$mode" = default ] || gr_die \
"no $GR_UNITS — single-unit repository; --impact, --exports and --list need a
  manifest. An empty answer here would read as 'no units to run', which is a
  skipped suite wearing a green light."

    # Two or more unit-shaped configs with no manifest: D2's rejected-glob
    # situation observed in the wild. The second config is invisible to every
    # script today — a unit outside compliance at exit 0. ONE non-root config
    # stays legal: it is the documented GR_CONFIG project-in-subdirectory
    # layout (risk assessment 2 verified the threshold).
    strays=$(git ls-files --cached --others --exclude-standard -- '*/.guardrails/config.yaml' 2>/dev/null)
    n_strays=$(printf '%s' "$strays" | grep -c .) || true
    if [ "$n_strays" -ge 2 ]; then
        gr_die \
"$n_strays unit-shaped configs with no manifest:
$(printf '%s\n' "$strays" | sed 's/^/  /')
  Each is invisible to every script here — a unit outside compliance while
  the run exits 0. Declare them in $GR_UNITS, or remove all but one."
    fi

    # The near-miss scan (risk assessment 2, 2026-09-03): only the manifest's
    # own directory, only the near-miss name class, only manifest-shaped
    # content. All three narrowings are load-bearing — see the assessment for
    # what each one leaves as accepted residual.
    set +f          # the script's one glob: `set -f` above would leave it
                    # a literal `.guardrails/*` and the scan silently dead
    for f in .guardrails/*; do
        [ -f "$f" ] || continue
        base=${f##*/}
        low=$(printf '%s' "$base" | tr 'A-Z' 'a-z')
        case "$low" in
            (units.yaml|units.yml|unit.yaml|unit.yml) ;;
            (*) continue ;;
        esac
        [ "$base" = "units.yaml" ] && continue
        if LC_ALL=C awk '
                FNR == 1 { sub(/^\357\273\277/, "") }
                /^(units|not_a_unit):/ { found = 1; exit }
                END { exit !found }' "$f"; then
            gr_die \
"found $f with manifest-shaped content — did you mean .guardrails/units.yaml?
  Nothing reads this file, so the repository would run in single-unit mode
  with every scope gate off while it looks configured."
        fi
    done
    set -f

    echo "no units.yaml — single-unit repository; no unit configs found astray"
    exit 0
fi

# Manifest present: validate it and every unit config first — a manifest
# defect is a wrong scope for every scan, worse than any finding below.
gr_check_units

units=$(gr_unit_list)
disclaimed=$(gr_disclaimed_list)

# unit_class UNIT — safety_class, validated: A, B or C prints its rank; TBD
# and anything else dies, but ONLY when the caller is computing an edge (D5:
# a floor computed from a placeholder is a gate disabling itself). Standalone
# units keep TBD legally — tooth one.
class_rank() {
    case "$1" in
        (A) echo 1 ;;
        (B) echo 2 ;;
        (C) echo 3 ;;
        (*) return 1 ;;
    esac
}

# deps_of UNIT — its depends_on list.
deps_of() { cfg_list depends_on "$1/.guardrails/config.yaml"; }

case "$mode" in
(list)
    printf '%s\n' "$units"
    exit 0
    ;;
(exports)
    gr_contains "$units" "$arg" || gr_die \
"--exports: not a declared unit: $arg
  Declared units: $(printf '%s' "$units" | tr '\n' ' ')"
    set +f      # gr_exported_reqs reaches gr_md_files' `"$_dir"/*.md` glob
                # (via gr_unit_srs); under the script's `set -f` that glob is
                # a literal and the emptiness rule dies on a populated SRS
                # directory. gr_unit_req_scan re-disables globbing itself,
                # bracketed, around the actual scan.
    gr_exported_reqs "$arg"
    set -f
    exit 0
    ;;
(impact)
    changed=$(git diff --name-only "$arg" -- 2>&1) || gr_die "git diff failed for '$arg': $changed"
    touched=""
    for p in $changed; do
        case "$p" in
            (*/*) ;;
            (*) continue ;;                    # root-level file: implicitly disclaimed
        esac
        case "$p" in
            (.guardrails/*)
                # The manifest or the installed scripts changed: every unit's
                # gates ran under the old tool, so every unit is in the blast
                # radius. The safe direction is to run them all.
                touched="$units"
                continue ;;
        esac
        w=$(gr_unit_of_path "$p") || gr_die \
"--impact: changed path claimed by no unit and not disclaimed: $p
  The impact set cannot be computed over an unowned path — a partial list
  would read as complete to merge-change. Fix default mode's UNCLAIMED-PATH
  first (claim the path in a unit, or disclaim it in $GR_UNITS)."
        case "$w" in
            (not_a_unit\ *) continue ;;
            (*) gr_contains "$touched" "$w" || touched="${touched}${touched:+
}$w" ;;
        esac
    done
    # Transitive closure over reverse depends_on (D12): a unit whose
    # dependency chain reaches a touched unit ships that unit's changed
    # object code, whatever the intermediate contracts say.
    impact="$touched"
    grew=1
    while [ "$grew" -eq 1 ]; do
        grew=0
        for u in $units; do
            gr_contains "$impact" "$u" && continue
            for d in $(deps_of "$u"); do
                if gr_contains "$impact" "$d"; then
                    impact="${impact}${impact:+
}$u"
                    grew=1
                    break
                fi
            done
        done
    done
    for u in $units; do          # manifest order, stable output
        if gr_contains "$touched" "$u"; then
            printf '%s\ttouched\n' "$u"
        elif gr_contains "$impact" "$u"; then
            printf '%s\tdependent\n' "$u"
        fi
    done
    exit 0
    ;;
esac

# --- default mode findings ---------------------------------------------------
fail=0

# UNCLAIMED-PATH (D7): every tracked path is claimed by a unit, disclaimed,
# a root-level file, or under the root .guardrails/ (the manifest's own home
# — D7 names "the manifest itself" implicitly disclaimed, and the installed
# scripts live beside it). Everything else is the distinction D2's rejected
# glob could not make: "not yet ratcheted", loudly.
unclaimed=$(git ls-files --cached --others --exclude-standard 2>/dev/null | {
    while IFS= read -r p; do
        case "$p" in
            (*/*) ;;
            (*) continue ;;
        esac
        case "$p" in (.guardrails/*) continue ;; esac
        gr_unit_of_path "$p" >/dev/null || printf '%s\n' "$p"
    done
})
if [ -n "$unclaimed" ]; then
    printf '%s\n' "$unclaimed" | sed 's/^/UNCLAIMED-PATH /'
    echo "guardrails: every tracked path is claimed by a unit or disclaimed under" >&2
    echo "not_a_unit: in $GR_UNITS — an unclaimed path is code outside compliance" >&2
    echo "that nothing would ever scan." >&2
    fail=1
fi

# DISCLAIMED-DRAFT (risk assessment 3, 2026-09-03): draft tokens and
# DRAFT-named files on every surface no unit run scans — the not_a_unit:
# paths, tracked root-level files, and the root .guardrails/ (all three are
# UNCLAIMED-PATH-exempt, so without this scan a draft parked there is scanned
# by NO gate). The conviction lives at the repository level, where it blocks
# every merge. .guardrails/scripts/ is carved out for the same reason
# GR_SCAN_EXCLUDE exists: the installed scripts legitimately carry
# draft-shaped tokens in their comments.

# scan_drafts PATHSPEC... — convict both draft halves under the pathspecs,
# which reach git verbatim (IFS is newline, globbing is off).
scan_drafts() {
    hits=$(git grep -In --untracked -E "$GR_DRAFT_TOKEN_RE" -- "$@" 2>/dev/null)
    _st=$?
    [ "$_st" -le 1 ] || gr_die "DISCLAIMED-DRAFT token scan failed on $* (git grep exit $_st)"
    if [ -n "$hits" ]; then
        printf '%s\n' "$hits" | sed 's/^/DISCLAIMED-DRAFT /'
        fail=1
    fi
    dfiles=$(git ls-files --cached --others --exclude-standard -- "$@" 2>/dev/null \
        | grep -E "$GR_DRAFT_FILE_RE" || true)
    if [ -n "$dfiles" ]; then
        printf '%s\n' "$dfiles" | sed 's/^/DISCLAIMED-DRAFT /'
        fail=1
    fi
}

for d in $disclaimed; do
    [ -e "$d" ] || continue
    scan_drafts "$d"
done
# The implicitly-disclaimed surface: root-level files are the ls-files
# entries with no slash (each handed to git literally, one per line), and
# the root .guardrails/ is one pathspec minus its scripts directory.
root_files=$(git ls-files --cached --others --exclude-standard 2>/dev/null | grep -v / || true)
if [ -n "$root_files" ]; then
    # shellcheck disable=SC2086
    scan_drafts $root_files
fi
scan_drafts .guardrails ':(exclude).guardrails/scripts'

# The class floor (D5) and its escape. Per consumer edge: the provider's
# class must reach the consumer's, or the consumer declares segregation whose
# citation resolves.
for c in $units; do
    c_cfg="$c/.guardrails/config.yaml"
    seg=$(cfg_list segregated_from "$c_cfg")

    # INCOMPLETE-SEGREGATION: judge every entry, whether or not the floor
    # currently needs it — a dangling citation is the classic false-green
    # shape, and it must not wait for the class change that exposes it.
    for s in $seg; do
        s_path=${s%% (*}
        if [ "$s_path" = "$s" ]; then
            echo "INCOMPLETE-SEGREGATION $c: '$s' (no parenthesised citation — name the RC or ADR that argues the segregation)"
            fail=1
            continue
        fi
        s_cite=${s#* (}
        s_cite=${s_cite%)}
        if ! gr_contains "$(deps_of "$c")" "$s_path"; then
            echo "INCOMPLETE-SEGREGATION $c: '$s' ($s_path is not a declared dependency of $c)"
            fail=1
            continue
        fi
        case "$s_cite" in
            (RC-*)
                _def_files=$(git grep -l --untracked -E "^\\*\\*${s_cite}\\*\\*:" -- . "$GR_SCAN_EXCLUDE" 2>/dev/null)
                if [ -z "$_def_files" ]; then
                    echo "INCOMPLETE-SEGREGATION $c: '$s' (cited control $s_cite is defined nowhere)"
                    fail=1
                else
                    # disclaimed-definitions-do-not-resolve holds here too: a
                    # definition living only under a not_a_unit: path is one
                    # no gate governs. Root-level and unit files both count —
                    # the RMF lives somewhere; only disclaimed paths do not.
                    _resolved=0
                    for _df in $_def_files; do
                        case "$(gr_unit_of_path "$_df" || true)" in
                            (not_a_unit\ *) ;;
                            (*) _resolved=1; break ;;
                        esac
                    done
                    if [ "$_resolved" -eq 0 ]; then
                        echo "INCOMPLETE-SEGREGATION $c: '$s' (cited control $s_cite is defined only under disclaimed path(s): $(printf '%s' "$_def_files" | tr '\n' ' '))"
                        fail=1
                    fi
                fi ;;
            (adr:*)
                s_adr=${s_cite#adr:}
                s_adr=${s_adr# }
                [ -f "$s_adr" ] || {
                    echo "INCOMPLETE-SEGREGATION $c: '$s' (cited ADR file does not exist: $s_adr)"
                    fail=1
                } ;;
            (*)
                echo "INCOMPLETE-SEGREGATION $c: '$s' (citation is neither (RC-…) nor (adr: path))"
                fail=1 ;;
        esac
    done

    c_class=$(cfg_get safety_class "$c_cfg")
    for p in $(deps_of "$c"); do
        p_class=$(cfg_get safety_class "$p/.guardrails/config.yaml")
        # TBD on either end of an EDGE is exit 2 (D5): the interview never
        # happened, and a floor computed from a placeholder is a gate
        # disabling itself. A standalone unit keeps TBD legally.
        for end in "$c:$c_class" "$p:$p_class"; do
            case "${end#*:}" in
                (A|B|C) ;;
                (*) gr_die \
"safety_class is '${end#*:}' on unit ${end%%:*}, which sits on a dependency
  edge ($c -> $p). The class floor cannot be computed from a placeholder —
  run the ratchet safety-class interview for that unit first." ;;
            esac
        done
        cr=$(class_rank "$c_class")
        pr=$(class_rank "$p_class")
        if [ "$pr" -lt "$cr" ]; then
            covered=0
            for s in $seg; do
                s_path=${s%% (*}
                [ "$s_path" = "$p" ] && { covered=1; break; }
            done
            # A covering entry that does not RESOLVE was already reported
            # INCOMPLETE-SEGREGATION above; it still suppresses the floor
            # finding here so one defect is reported as one defect, under
            # the diagnosis that names the remedy.
            if [ "$covered" -eq 0 ]; then
                echo "MISCLASSED-DEPENDENCY $p (class $p_class) below consumer $c (class $c_class) — raise the provider's class, or declare segregation in the consumer's segregated_from: naming the RC or ADR that argues it (IEC 62304 5.3.5)"
                fail=1
            fi
        fi
    done
done

echo "units: $(printf '%s' "$units" | grep -c .), disclaimed $(printf '%s' "$disclaimed" | grep -c .); tracked paths $(git ls-files --cached --others --exclude-standard | grep -c .)"

exit $fail
