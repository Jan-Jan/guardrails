# Shared bats helpers: throwaway fixture git repos with guardrails installed.

# Release each test's temporary directory as soon as the test passes.
#
# bats itself keeps every $BATS_TEST_TMPDIR until the whole run exits, and each
# fixture here is a real git repository — about 120 inodes, most of them under
# .git. One full-suite run therefore holds roughly sixty thousand inodes for
# its entire duration, and /tmp is a tmpfs with a fixed inode budget. Three
# overlapping runs exhaust it.
#
# That is not a tidiness problem, it is an EVIDENCE problem: past the budget a
# redirect fails with ENOSPC, bats reports `not ok … teardown_suite` and
# short-counts the plan, and a mutation runner that treats any failure as a
# kill scores a surviving mutant as dead. A run killed that way also never
# reaches bats' own cleanup, so its directory leaks and the next run starts
# closer to the wall.
#
# A FAILING test keeps its directory, because that is what you inspect; bats
# does the same on retry.
teardown() {
    if [ "${BATS_TEST_COMPLETED:-}" = 1 ] && [ -n "${BATS_TEST_TMPDIR:-}" ]; then
        rm -rf "$BATS_TEST_TMPDIR"
    fi
    return 0
}

write_config() {
    cat > .guardrails/config.yaml <<'EOF'
guardrails_version: 0.1.0
safety_class: B
id_prefixes: REQ HAZ RC SDD LLR PR
doc_srs: docs/requirements
doc_rmf: docs/risk
doc_sad: docs/architecture
doc_soup: docs/architecture/soup.md
doc_problems: docs/problems
strict_paths:
  - src
test_paths:
  - tests
verify_commands:
  - make test
EOF
}

# Creates $REPO: a git repo with config, doc dirs, and the guardrails scripts
# copied into .guardrails/scripts/. Leaves the shell cd'd into it.
make_fixture_repo() {
    REPO="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$REPO"
    cd "$REPO"
    # --template= : no sample hooks. Fifteen files per fixture, times four
    # hundred tests, for scripts that are never run.
    git init -q -b main --template=
    git config user.name test
    git config user.email test@example.com
    git config commit.gpgsign false
    mkdir -p .guardrails/scripts docs/requirements docs/risk docs/architecture docs/problems src tests
    cp "$BATS_TEST_DIRNAME"/../scripts/*.sh .guardrails/scripts/ 2>/dev/null || true
    write_config
    # ratchet copies a template into each of these, so a real project always
    # has them (skills/ratchet/SKILL.md step 2.3). Without them the fixture
    # would configure doc_soup at a path that does not exist and the four
    # ledger directories with no *.md in them at all — neither of which is a
    # shape a guardrails project is ever in.
    printf '# SOUP Inventory\n' > docs/architecture/soup.md
    printf '# Requirements ledger\n' > docs/requirements/README.md
    printf '# Risk management file\n' > docs/risk/README.md
    printf '# Software architecture\n' > docs/architecture/README.md
    printf '# Problem reports\n' > docs/problems/README.md
    # git does not track empty directories, and a configured path must
    # match a file that is actually there — ratchet tells operators to
    # .gitkeep any configured directory they leave empty for now.
    : > src/.gitkeep
    git add -A
    git commit -qm fixture
}

# Commits everything currently in the fixture repo working tree.
commit_all() {
    git add -A
    git commit -qm "${1:-update}"
}

# Creates a linked worktree on a new branch and leaves the shell cd'd into it.
# This is the shape merge-change runs in, and the only shape in which the base
# branch and the change branch are distinguishable: in a single checkout
# gr_base_branch reports whatever is checked out, so a "change branch" there
# is its own base.
make_change_worktree() {
    git worktree add -q "$BATS_TEST_TMPDIR/wt" -b "${1:-my-change}"
    cd "$BATS_TEST_TMPDIR/wt"
}

# A verification record satisfying every required field. Callers override one
# field at a time to test its absence.
write_record() {
    mkdir -p docs/verification
    cat > "docs/verification/2026-01-01-${1:-rec}.md" <<EOF
# Verification — ${1:-rec}

branch: ${2:-my-change}
reviewer: an independent subagent
verdict: accepted, no findings outstanding
reproduced: yes, against the shipped scripts, before any change
EOF
}

# YYYY-MM-DD for N days before today. GNU date and BSD date disagree on the
# flag, and the tests must run on whichever the developer has; the scripts
# under test do their own date arithmetic in awk precisely to avoid needing
# either.
# A NEGATIVE count means the future, and the clock-skew tests need it. GNU
# date reads `-d "-1 days ago"` and answers with tomorrow; BSD date is handed
# `-v--1d`, cannot parse the doubled sign, and refuses — so the sign is folded
# into the adjustment here rather than spelled twice.
days_ago() {
    date -d "$1 days ago" +%Y-%m-%d 2>/dev/null && return 0
    case "$1" in
        (-*) _adj="+${1#-}d" ;;
        (*)  _adj="-${1}d" ;;
    esac
    date -v"$_adj" +%Y-%m-%d 2>/dev/null \
        || { echo "no usable date(1) for relative dates" >&2; return 1; }
}

# A problem-report item carrying every field the gate requires, appended to the
# problems ledger. Callers drop or corrupt one field at a time to test it.
#   write_pr [ID] [STATUS] [OPENED]
write_pr() {
    cat >> docs/problems/0001-01-01-base.md <<EOF

**${1:-PR-001}**: Crash on empty dose input.
affects: REQ-001
opened: ${3:-$(days_ago 3)}
status: ${2:-open}
EOF
}

# Creates a stub `awk` and echoes the directory to put on PATH. The stub is
# the real awk in every respect but one: it refuses a `-v` assignment whose
# value carries a LITERAL newline, exiting 2 with the message the real one
# gives, before the program runs.
#
# That is exactly what macOS's BWK awk ("awk version 20200816", the one that
# ships with the OS) does, and gawk, mawk and busybox awk all ACCEPT the same
# newline. So on a developer's Linux box the defect is invisible — and it is
# not a wrong answer that a behavioural test would catch, it is exit 2 with no
# gate having run at all. The stub is how a Linux CI reproduces it.
make_strict_awk() {
    _real=$(command -v awk)
    _bin="$BATS_TEST_TMPDIR/strict-awk"
    # Called with the stub already on PATH, `command -v awk` finds the STUB and
    # bakes its own path into the exec below — a fork bomb, not a test failure.
    # The comment used to be the only thing preventing that.
    case "$_real" in
        ("$_bin"/*) echo "make_strict_awk called with the stub already on PATH" >&2
                   return 1 ;;
    esac
    mkdir -p "$_bin"
    # Written with the real awk's path baked in: the stub must not find itself
    # on PATH, and PATH is what the caller is about to change.
    cat > "$_bin/awk" <<EOF
#!/bin/sh
# Every route a value takes into awk's variable space, because real BWK awk
# refuses a literal newline in all of them: \`-v k=v\` as two words, \`-vk=v\` as
# one, and a bare \`k=v\` OPERAND after the program. A stub watching only \`-v\`
# would pass a defect of the same class straight through.
#
# The options are walked rather than pattern-matched across the whole argument
# list, because the PROGRAM text is not an assignment however much it looks
# like one: \`BEGIN { n = split(kws, K) }\` contains both an identifier and an
# \`=\`, and it is multi-line in every script here. Only what follows the
# program can be an operand assignment.
_chk() {
    case "\$1" in
        (*'
'*)
            # The real message quotes the VALUE, not the whole assignment.
            printf 'awk: newline in string %s... at source line 1\n' "\${1#*=}" >&2
            return 2 ;;
    esac
    return 0
}
_scan() {
    while [ \$# -gt 0 ]; do
        case "\$1" in
            (--)        shift; break ;;
            (-v)        _chk "\$2" || return 2; shift 2 ;;
            (-v?*)      _chk "\${1#-v}" || return 2; shift ;;
            (-f|-F)     shift 2 ;;
            (-f?*|-F?*) shift ;;
            (-*)        shift ;;
            (*)         shift; break ;;   # the program itself
        esac
    done
    for _a in "\$@"; do                  # operands: files and var=value
        case "\$_a" in
            ([A-Za-z_]*=*) _chk "\$_a" || return 2 ;;
        esac
    done
    return 0
}
_scan "\$@" || exit 2
exec "$_real" "\$@"
EOF
    chmod +x "$_bin/awk"
    echo "$_bin"
}

# Deletes the FIRST line exactly equal to $1 from $2 (default the fixture
# config), in place. The GNU spellings for this hand sed the scripts
# `0,/re/{/re/d}` and `/re/,+1d`, and BSD sed rejects both: address 0 and the
# `+N` relative address are GNU extensions, so no backup suffix would have
# saved them. awk is the portable answer, and a whole-line comparison is what
# every caller actually wanted.
del_first_line() {
    _f=${2:-.guardrails/config.yaml}
    # `$0 "" == want ""` forces a STRING comparison. Bare `$0 == want` is
    # numeric whenever both sides look like numbers under awk's strnum rules,
    # so a line `  10` would match `want=010` — not what "exactly equal" means.
    awk -v want="$1" '!seen && $0 "" == want "" { seen = 1; next } { print }' "$_f" \
        > "$_f.tmp" && mv "$_f.tmp" "$_f"
}

# Creates a stub `date` and echoes the directory to put on PATH. The stub is
# BSD date on the one point that matters here: it refuses `-d`, and its `-v`
# adjustment carries its own sign, so `-v--1d` is an error rather than
# tomorrow. Everything else passes through to the real date.
#
# The awk class got make_strict_awk so that a GNU box sees BWK behaviour. This
# is the same instrument for the other half of the platform gap: without it the
# `days_ago` regression test can only redden on macOS — on exactly the platform
# where the defect it guards escaped, it is green.
make_bsd_date() {
    _real=$(command -v date)
    _bin="$BATS_TEST_TMPDIR/bsd-date"
    case "$_real" in
        ("$_bin"/*) echo "make_bsd_date called with the stub already on PATH" >&2
                   return 1 ;;
    esac
    # Does the real date understand GNU's `-d`? The stub has to know, because
    # ACCEPTING `-v` is not the same as being able to CARRY OUT `-v`.
    #
    # The first version validated the adjustment and then handed it to the real
    # date unchanged, which works only where the real date is already BSD —
    # that is, everywhere except the GNU box the stub exists for. There,
    # `date -v-3d` reached a date with no `-v` at all, so a VALID adjustment
    # was refused: the stub reproduced BSD's rejections and none of its
    # successes. Both tests using it failed, and the failure read as a defect
    # in `days_ago` rather than in the instrument measuring it.
    #
    # So on a GNU box the stub TRANSLATES `-v±Nd` into `-d "N days [ago]"`; on
    # a real BSD box it passes it through, because there it is already right.
    if "$_real" -d "0 days ago" +%Y-%m-%d >/dev/null 2>&1; then
        _mode=translate
    else
        _mode=passthrough
    fi
    mkdir -p "$_bin"
    {
        printf '#!/bin/sh\n'
        printf "REAL='%s'\n" "$_real"
        printf "MODE='%s'\n" "$_mode"
        cat <<'STUB'
adj=""
rest=""
for a in "$@"; do
    case "$a" in
        (-d*) echo "date: illegal option -- d" >&2; exit 1 ;;
        (-v-[0-9]*d|-v+[0-9]*d|-v[0-9]*d) adj=$a ;;
        (-v*) printf '%s: Cannot apply date adjustment\n' "${a#-v}" >&2; exit 1 ;;
        (*) rest="$rest $a" ;;
    esac
done

[ -n "$adj" ] && [ "$MODE" = translate ] || exec "$REAL" "$@"

n=${adj#-v}
n=${n%d}
case "$n" in
    (-*) spec="${n#-} days ago" ;;
    (+*) spec="${n#+} days" ;;
    (*)  spec="$n days" ;;
esac
exec "$REAL" -d "$spec" $rest
STUB
    } > "$_bin/date"
    chmod +x "$_bin/date"
    echo "$_bin"
}

# Writes UNIT's .guardrails/config.yaml. Extra args are depends_on entries.
write_unit_config() {
    _u="$1"; shift
    mkdir -p "$_u/.guardrails"
    {
        cat <<EOF
guardrails_version: 0.1.0
safety_class: B
id_prefixes: REQ HAZ RC SDD LLR PR
doc_srs: $_u/docs/requirements
doc_rmf: $_u/docs/risk
doc_sad: $_u/docs/architecture
doc_soup: $_u/docs/architecture/soup.md
doc_problems: $_u/docs/problems
strict_paths:
  - $_u/src
test_paths:
  - $_u/tests
verify_commands:
  - make test
expectation_age_days: 90
expectation_open_max: 10
EOF
        if [ $# -gt 0 ]; then
            echo "depends_on:"
            for _d in "$@"; do echo "  - $_d"; done
        fi
    } > "$_u/.guardrails/config.yaml"
}

# make_unit UNIT [DEPS...] — directories, config, the ratchet-shaped README
# files (a configured directory always holds at least one *.md).
make_unit() {
    _u="$1"
    mkdir -p "$_u/docs/requirements" "$_u/docs/risk" "$_u/docs/architecture" \
             "$_u/docs/problems" "$_u/src" "$_u/tests"
    write_unit_config "$@"
    printf '# SOUP Inventory\n' > "$_u/docs/architecture/soup.md"
    printf '# Requirements ledger\n' > "$_u/docs/requirements/README.md"
    printf '# Risk management file\n' > "$_u/docs/risk/README.md"
    printf '# Software architecture\n' > "$_u/docs/architecture/README.md"
    printf '# Problem reports\n' > "$_u/docs/problems/README.md"
    : > "$_u/src/.gitkeep"
}

# write_unit_items UNIT REQ HAZ RC SDD LLR — one fully traced item set, the
# per-unit copy of the base fixture's ledgers. IDs are passed in so two units
# never collide.
write_unit_items() {
    _u="$1"
    cat > "$_u/docs/requirements/0001-01-01-base.md" <<EOF
# SRS — $_u

**$2**: The software shall limit the dose. (implements: $4)
EOF
    cat > "$_u/docs/risk/0001-01-01-base.md" <<EOF
# RMF — $_u

**$3**: Overdose delivered to patient.

**$4**: Software limits dose to configured maximum. mitigates: $3
EOF
    cat > "$_u/docs/architecture/0001-01-01-base.md" <<EOF
# SAD — $_u

**$5**: Dose limiter module. traces: $2

**$6**: Clamp requested dose to the configured maximum. satisfies: $2
EOF
    printf '# verifies: %s\ntrue\n' "$6" > "$_u/tests/test_a.sh"
}

# The canonical two-unit fixture: provider platform/hal (exports REQ-h4m2p9),
# consumer apps/pump (depends_on hal, references the export from its SAD),
# a disclaimed legacy/ and docs/, root README. Green under every gate.
# Leaves the shell cd'd into $REPO.
#
# A DISTINCT directory from make_fixture_repo's: setup() has already built
# $BATS_TEST_TMPDIR/repo with a ROOT config, which gr_check_units refuses
# alongside a manifest, so this fixture replaces it rather than building on it.
make_units_fixture() {
    REPO="$BATS_TEST_TMPDIR/units-repo"
    mkdir -p "$REPO"
    cd "$REPO"
    git init -q -b main --template=
    git config user.name test
    git config user.email test@example.com
    git config commit.gpgsign false
    mkdir -p .guardrails/scripts docs/verification legacy
    cp "$BATS_TEST_DIRNAME"/../scripts/*.sh .guardrails/scripts/ 2>/dev/null || true
    # check-review reads this directory at the REPOSITORY level in a manifest
    # repo (architecture item 9, task T9); tracked non-empty so worktrees
    # carry it and gr_md_files has its one *.md
    printf '# verification records\n' > docs/verification/README.md
    cat > .guardrails/units.yaml <<'EOF'
units:
  - platform/hal
  - apps/pump
not_a_unit:
  - legacy
  - docs
EOF
    printf '# repo-level docs\n' > docs/README.md
    printf '# migration leftovers\n' > legacy/notes.md
    printf '# monorepo fixture\n' > README.md
    make_unit platform/hal
    make_unit apps/pump platform/hal
    write_unit_items platform/hal REQ-h4m2p9 HAZ-h2b6c3 RC-h3d8f4 SDD-h5g2j7 LLR-h6k9m3
    write_unit_items apps/pump   REQ-p2m4k7 HAZ-p3v8n2 RC-p4q7t3 SDD-p5w2x8 LLR-p6r3z9
    # hal exports its interface REQ (annotation inside the block: nothing
    # closes a block but a heading or a bold-colon line)
    printf 'exported: yes\n' >> platform/hal/docs/requirements/0001-01-01-base.md
    # pump consumes the export: a reference that must resolve via the foreign
    # set, and the live wire the export-removal chain later cuts
    printf '\nThe pump consumes the HAL flow-rate contract (REQ-h4m2p9).\n' \
        >> apps/pump/docs/architecture/0001-01-01-base.md
    git add -A
    git commit -qm units-fixture
}

# Convenience: run a script scoped to one unit of the current fixture.
unit_run() {
    _s="$1"; _u="$2"; shift 2
    GR_CONFIG="$_u/.guardrails/config.yaml" run sh ".guardrails/scripts/$_s" "$@"
}
