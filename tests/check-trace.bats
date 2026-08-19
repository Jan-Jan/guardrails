load helpers

setup() {
    make_fixture_repo
    cat > docs/requirements/0001-01-01-base.md <<'EOF'
# SRS

**REQ-001**: The system shall limit the dose. (implements: RC-001)
EOF
    cat > docs/risk/0001-01-01-base.md <<'EOF'
# Risk Management File

**HAZ-001**: Overdose delivered to patient.

**RC-001**: Software limits dose to configured maximum. mitigates: HAZ-001
EOF
    cat > docs/architecture/0001-01-01-base.md <<'EOF'
# Software Architecture

**SDD-001**: Dose limiter module. traces: REQ-001

**LLR-001**: Clamp requested dose to the configured maximum. satisfies: REQ-001
EOF
    printf '# verifies: LLR-001\ntrue\n' > tests/test_a.sh
    commit_all good
}

@test "check-trace: fully traced fixture passes" {
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]   # only the summary line: no violations
}

@test "check-trace: REQ without verifying test fails" {
    printf 'true\n' > tests/test_a.sh
    commit_all no-verifies
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST REQ-001"* ]]
}

@test "check-trace: hazard without risk control fails" {
    printf '\n**HAZ-002**: Underdose.\n' >> docs/risk/0001-01-01-base.md
    commit_all haz2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNMITIGATED-HAZARD HAZ-002"* ]]
}

@test "check-trace: risk control without implementing requirement fails" {
    printf '\n**RC-002**: Alarm on underdose. mitigates: HAZ-001\n' >> docs/risk/0001-01-01-base.md
    commit_all rc2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNIMPLEMENTED-CONTROL RC-002"* ]]
}

@test "check-trace: design item without traces fails" {
    printf '\n**SDD-002**: Logging module.\n' >> docs/architecture/0001-01-01-base.md
    commit_all sdd2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNTRACED-DESIGN SDD-002"* ]]
}

@test "check-trace: REQ covered only transitively via tested LLR passes" {
    # fixture already has: test verifies LLR-001, LLR-001 satisfies REQ-001,
    # and no direct test for REQ-001
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]   # only the summary line: no violations
}

@test "check-trace: LLR without satisfies fails" {
    printf '\n**LLR-002**: Log every dose change.\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all llr2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
}

@test "check-trace: derived LLR mentioned in RMF is not UNSATISFIED" {
    printf '\n**LLR-002**: Debounce sensor input. satisfies: derived\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    printf '\nDerived requirements assessment: LLR-002 introduces no new hazard.\n' >> docs/risk/0001-01-01-base.md
    commit_all derived
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]   # only the summary line: no violations
}

@test "check-trace: LLR without verifying test fails" {
    printf '\n**LLR-002**: Log every dose change. satisfies: REQ-001\n' >> docs/architecture/0001-01-01-base.md
    commit_all llr2-untested
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST LLR-002"* ]]
}

@test "check-trace: REQ with neither direct test nor tested LLR fails" {
    printf '\n**REQ-002**: The software shall log all doses.\n' >> docs/requirements/0001-01-01-base.md
    commit_all req2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST REQ-002"* ]]
}

@test "check-trace: derived LLR not assessed in RMF fails" {
    printf '\n**LLR-002**: Debounce sensor input. satisfies: derived\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all derived-unassessed
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNANALYZED-DERIVED LLR-002"* ]]
}

@test "check-trace: derived REQ not assessed in RMF fails" {
    printf '\n**REQ-002**: The software shall retry the bus handshake. satisfies: derived\n' >> docs/requirements/0001-01-01-base.md
    printf '# verifies: REQ-002\ntrue\n' > tests/test_c.sh
    commit_all derived-req
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNANALYZED-DERIVED REQ-002"* ]]
}

@test "check-trace: open problem report warns but passes" {
    printf '**PR-001**: Crash on empty dose input. affects: REQ-001. status: open\n' > docs/problems/0001-01-01-base.md
    commit_all open-pr
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"UNRESOLVED-PR PR-001"* ]]
}

@test "check-trace: resolved problem report is silent" {
    printf '**PR-001**: Crash on empty dose input. affects: REQ-001. status: resolved\n' > docs/problems/0001-01-01-base.md
    commit_all resolved-pr
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]   # only the summary line: no violations
}

@test "check-trace: open PR warning coexists with real failure exit 1" {
    printf '**PR-001**: Crash on empty dose input. affects: REQ-001. status: open\n' > docs/problems/0001-01-01-base.md
    printf '\n**HAZ-002**: Underdose.\n' >> docs/risk/0001-01-01-base.md
    commit_all pr-and-haz
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNRESOLVED-PR PR-001"* ]]
    [[ "$output" == *"UNMITIGATED-HAZARD HAZ-002"* ]]
}

@test "check-trace: prose satisfies after a heading does not satisfy an LLR" {
    printf '\n**LLR-002**: Log every dose change.\n\n## Notes\n\nThis module satisfies: REQ-001 in spirit.\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    commit_all prose-satisfies
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
}

@test "check-trace: longer-ID mention in RMF does not cover a derived LLR" {
    printf '\n**LLR-002**: Debounce sensor input. satisfies: derived\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    printf '\nLLR-0020 has no hazard impact.\n' >> docs/risk/0001-01-01-base.md
    commit_all substring
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNANALYZED-DERIVED LLR-002"* ]]
}

@test "check-trace: open draft PR does not misattribute to a resolved PR" {
    printf '**PR-001**: Crash on empty input. affects: REQ-001. status: resolved\n\n**PR-DRAFT-b-1**: New issue. affects: REQ-001. status: open\n' > docs/problems/0001-01-01-base.md
    commit_all mixed-prs
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"UNRESOLVED-PR PR-001"* ]]
}

@test "check-trace: dangling affects reference in problems log fails" {
    printf '**PR-001**: Crash on empty input. affects: REQ-999. status: resolved\n' > docs/problems/0001-01-01-base.md
    commit_all dangling-pr
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-999"* ]]
}

@test "check-trace: rules work across multiple dated ledger files" {
    # new change adds a REQ in a later requirements file, implementing an RC
    # defined in a later risk file; LLR for it lives in a later sad file
    printf '**RC-002**: Alarm on stuck sensor. mitigates: HAZ-001\n' > docs/risk/2026-02-02-alarms.md
    printf '**REQ-002**: The software shall raise the stuck-sensor alarm. (implements: RC-002)\n' > docs/requirements/2026-02-02-alarms.md
    printf '**LLR-002**: Debounce then latch the alarm line. satisfies: REQ-002\n' > docs/architecture/2026-02-02-alarms.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_alarm.sh
    commit_all cross-file
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]   # only the summary line: no violations
}

@test "check-trace: derived assessment in any rmf-directory file counts" {
    printf '**LLR-002**: Debounce sensor input. satisfies: derived\n' > docs/architecture/2026-02-02-x.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    printf 'Derived requirements assessment: LLR-002 no hazard impact.\n' > docs/risk/2026-02-02-derived.md
    commit_all derived-cross
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]   # only the summary line: no violations
}

@test "check-trace: template READMEs in ledger dirs cause no false positives" {
    cp "$BATS_TEST_DIRNAME"/../templates/srs.md docs/requirements/README.md
    cp "$BATS_TEST_DIRNAME"/../templates/rmf.md docs/risk/README.md
    cp "$BATS_TEST_DIRNAME"/../templates/sad.md docs/architecture/README.md
    cp "$BATS_TEST_DIRNAME"/../templates/problems.md docs/problems/README.md
    commit_all readmes
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]   # only the summary line: no violations
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
}

@test "check-trace: single-file doc config still works (back-compat)" {
    # rewrite config to the old monolithic layout
    sed -i.bak \
        -e 's|^doc_srs: .*|doc_srs: docs/requirements/srs.md|' \
        -e 's|^doc_rmf: .*|doc_rmf: docs/risk/rmf.md|' \
        .guardrails/config.yaml
    rm -f .guardrails/config.yaml.bak
    mv docs/requirements/0001-01-01-base.md docs/requirements/srs.md
    mv docs/risk/0001-01-01-base.md docs/risk/rmf.md
    commit_all single-file-layout
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]   # only the summary line: no violations
    printf '\n**HAZ-002**: Underdose.\n' >> docs/risk/rmf.md
    commit_all haz2-single
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNMITIGATED-HAZARD HAZ-002"* ]]
}

@test "check-trace: dangling reference to undefined ID fails" {
    printf '# REQ-999 is handled here\n' > src/main.sh
    commit_all dangling
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-999"* ]]
}

@test "check-trace: a REQ in a parenthetical after the list is not coverage" {
    printf '\n**REQ-002**: second requirement.\n' >> docs/requirements/0001-01-01-base.md
    printf '# verifies: LLR-001 (was REQ-002)\ntrue\n' > tests/test_a.sh
    commit_all parenthetical
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST REQ-002"* ]]
}

@test "check-trace: comma lists, trailing commas and trailing prose all count" {
    printf '\n**REQ-002**: second.\n\n**REQ-003**: third.\n' >> docs/requirements/0001-01-01-base.md
    printf '# verifies: LLR-001, REQ-002 — the fallback path\ntrue\n' > tests/test_a.sh
    printf '# verifies: REQ-003,\ntrue\n' > tests/test_b.sh
    commit_all lists
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" != *"MISSING-TEST REQ-001"* ]]
    [[ "$output" != *"MISSING-TEST REQ-002"* ]]
    [[ "$output" != *"MISSING-TEST REQ-003"* ]]
}

@test "check-trace: a REQ in a parenthetical after satisfies: does not satisfy an LLR" {
    printf '\n**REQ-002**: second.\n' >> docs/requirements/0001-01-01-base.md
    cat > docs/architecture/0001-01-01-base.md <<'EOF'
# Software Architecture

**SDD-001**: Dose limiter module. traces: REQ-001

**LLR-001**: Clamp requested dose. satisfies: REQ-001 (superseded REQ-002)
EOF
    commit_all satisfies-parenthetical
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-TEST REQ-002"* ]]
}

@test "check-trace: traces: with no ID list is untraced even if a REQ appears later" {
    cat > docs/architecture/0001-01-01-base.md <<'EOF'
# Software Architecture

**SDD-001**: Dose limiter module. traces: none — replaces REQ-001

**LLR-001**: Clamp requested dose. satisfies: REQ-001
EOF
    commit_all bad-traces
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNTRACED-DESIGN SDD-001"* ]]
}

@test "check-trace: a configured doc path that is absent fails loudly, never silently passes" {
    rm -rf docs/risk
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_rmf"* ]]
}

@test "check-trace: a configured test path that is absent fails loudly" {
    rm -rf tests
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"test_paths"* ]]
}

@test "check-trace: prints how many items of each prefix were checked" {
    # The whole summary line, matched exactly, with the prefixes deliberately
    # holding different counts: asserting substrings like "REQ 3" would still
    # pass if the loop reported one prefix's count under every prefix's name.
    cat >> docs/requirements/0001-01-01-base.md <<'EOF'

**REQ-002**: The system shall enforce the minimum dose. implements: RC-002

**REQ-003**: The system shall log every dose decision.
EOF
    cat >> docs/risk/0001-01-01-base.md <<'EOF'

**HAZ-002**: Underdose delivered to patient.

**RC-002**: Software enforces the configured minimum. mitigates: HAZ-002
EOF
    printf '# verifies: REQ-002 REQ-003\ntrue\n' > tests/test_b.sh
    commit_all counts
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"checked: REQ 3, HAZ 2, RC 2, SDD 1, LLR 1, PR 0"* ]]
}

@test "check-trace: reports how many source files each gate read" {
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    # docs/requirements holds the ratchet README plus the fixture ledger file
    [[ "$output" == *"sources: srs 2,"* ]]
    [[ "$output" == *"tests 1"* ]]
}

@test "check-trace: a requirements ledger with no REQ items reports REQ 0, not a silent pass" {
    rm -f docs/requirements/0001-01-01-base.md
    commit_all empty-srs
    run sh .guardrails/scripts/check-trace.sh
    # REQ-001 is still referenced from the SAD and the tests, so this run
    # legitimately fails on DANGLING-REF. The point of the test is the
    # denominator: the summary says REQ 0 instead of leaving a zero-item run
    # indistinguishable from a full one.
    [ "$status" -eq 1 ]
    [[ "$output" == *"REQ 0"* ]]
    [[ "$output" == *"sources: srs 1,"* ]]
}

# --- Config shapes that would silently disable a gate ----------------------
# Each of these produced a confident exit 0 over an unchecked hazard.

@test "check-trace: a ledger directory holding no *.md is an error, not an empty document" {
    rm -f docs/risk/*.md
    commit_all no-rmf-files
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_rmf"* ]]
    [[ "$output" == *"no *.md"* ]]
}

@test "check-trace: a configured strict path that is absent fails loudly" {
    rm -rf src
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"strict_paths"* ]]
}

@test "check-trace: an absent path containing a space is named in full" {
    sed -i.bak 's|^  - src$|  - my sources|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"my sources"* ]]
}

@test "check-trace: an ID prefix that is not a bare identifier is an error" {
    sed -i.bak 's/^id_prefixes:.*/id_prefixes: REQ HAZ RC SDD LLR PR[/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"bare identifier"* ]]
}

# --- One annotation rule, applied identically to every keyword -------------

@test "check-trace: traces: counts a REQ anywhere in its list, not only first" {
    cat >> docs/architecture/0001-01-01-base.md <<'EOF'

**SDD-002**: Dose logger. traces: SDD-001, REQ-001
EOF
    commit_all sdd2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"UNTRACED-DESIGN SDD-002"* ]]
}

@test "check-trace: a REQ named in prose after satisfies: does not satisfy an LLR" {
    cat >> docs/architecture/0001-01-01-base.md <<'EOF'

**LLR-002**: Round the dose. satisfies: none yet — use the satisfies: REQ-001 form
EOF
    printf '# verifies: LLR-001 LLR-002\ntrue\n' > tests/test_a.sh
    commit_all llr2
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNSATISFIED-LLR LLR-002"* ]]
}

# --- Configured paths must match something that is actually there ----------

@test "check-trace: a strict path written as a glob still reaches the scan" {
    # asserting exit 0 would prove nothing — a path that is silently dropped
    # also exits 0. Put a dangling reference behind the glob and require the
    # scan to find it.
    printf '// see REQ-999\n' > src/a.c
    sed -i.bak 's|^  - src$|  - src/*.c|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    commit_all glob-path
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-999"* ]]
}

@test "check-trace: a strict path glob that matches nothing is still an error" {
    sed -i.bak 's|^  - src$|  - src/*.rs|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"src/*.rs"* ]]
}

# --- Path entries: plain paths, shell globs and git pathspecs --------------

@test "check-trace: a recursive git pathspec in test_paths is accepted" {
    # `*_test.sh` expands to nothing for the shell but matches recursively for
    # git, which is what actually scans these paths. Rejecting it hard-failed
    # a fully traced project.
    mkdir -p tests/unit
    git rm -q tests/test_a.sh
    printf '# verifies: LLR-001\ntrue\n' > tests/unit/a_test.sh
    sed -i.bak 's|^  - tests$|  - *_test.sh|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    commit_all pathspec
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]
}

@test "check-trace: a pathspec matching no file at all is still an error" {
    sed -i.bak 's|^  - tests$|  - *_nothing.sh|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"matches no file"* ]]
}

@test "check-trace: a pathspec matching a non-ASCII path is accepted" {
    # git ls-files C-quotes any path with a non-ASCII byte, a quote, a tab or
    # a newline. Testing [ -e ] on each returned name rejected a directory
    # git grep scans perfectly well; counting is immune to the quoting.
    mkdir -p 'tésts'
    git rm -q tests/test_a.sh
    printf '# verifies: LLR-001\ntrue\n' > 'tésts/a_test.sh'
    sed -i.bak 's|^  - tests$|  - *_test.sh|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    commit_all nonascii
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]
}

@test "check-trace: an unrelated later traces: does not credit an SDD block" {
    # The SDD block must end at the next definition line or heading, the same
    # rule parse_llr_file uses. Without a terminator an annotation far below
    # credited an SDD that carries none of its own.
    cat >> docs/architecture/0001-01-01-base.md <<'EOF'

**SDD-002**: Logging module, no trace of its own.

**LLR-002**: Log every dose change. satisfies: REQ-001. traces: REQ-001
EOF
    printf '# verifies: LLR-001 LLR-002\ntrue\n' > tests/test_a.sh
    commit_all sdd-block
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNTRACED-DESIGN SDD-002"* ]]
}

@test "check-trace: a configured directory that is empty matches no file" {
    # An empty directory exists but holds nothing to scan; passing it would
    # report `strict 1` for a source that read nothing.
    rm -f src/.gitkeep
    commit_all empty-src
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"strict_paths"* ]]
    [[ "$output" == *"matches no file"* ]]
}

@test "check-trace: a path entry is a git pathspec, not shell-expanded at the root" {
    # Left to the shell, `*.c` is replaced by whatever matches in the repo root
    # and the recursive meaning is lost — src/ is never scanned, while
    # `sources:` still reports strict 1. Deleting an unrelated root file then
    # changes the verdict.
    printf 'int main(void){return 0;}\n' > main.c
    printf '// see REQ-999\n' > src/foo.c
    sed -i.bak 's|^  - src$|  - *.c|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    commit_all glob-narrowing
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-999"* ]]
}

@test "check-trace: traces: on a line below the SDD header still counts" {
    # The block terminator must not swallow the header's own block: an
    # annotation on a continuation line is the shape a careless fix breaks.
    cat >> docs/architecture/0001-01-01-base.md <<'EOF'

**SDD-002**: Dose logger.
traces: REQ-001
EOF
    commit_all sdd-continuation
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"UNTRACED-DESIGN SDD-002"* ]]
}

# --- Config value lexing ----------------------------------------------------

@test "check-trace: a trailing comment on a scalar value is not part of the value" {
    sed -i.bak 's|^doc_rmf: docs/risk$|doc_rmf: docs/risk  # the RMF|' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"rmf 2"* ]]
}

@test "check-trace: a config with CRLF line endings still parses" {
    sed -i.bak 's/$/\r/' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "checked:"* ]]
}

# --- Config shapes the reader cannot see ------------------------------------

@test "check-trace: a key with a hyphen instead of an underscore is an error" {
    sed -i.bak 's/^strict_paths:/strict-paths:/' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"strict-paths"* ]]
}

@test "check-trace: an indented top-level key is an error" {
    sed -i.bak 's/^strict_paths:/ strict_paths:/' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"strict_paths"* ]]
}

@test "check-trace: a space before the colon is an error" {
    sed -i.bak 's/^strict_paths:/strict_paths :/' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"strict_paths"* ]]
}

@test "check-trace: a list item at column zero is an error" {
    # cfg_list never read these, so the list was silently empty
    sed -i.bak 's/^  - src$/- src/' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"- src"* ]]
}

@test "check-trace: a config saved with a UTF-8 BOM is rejected, not half-read" {
    printf '\xef\xbb\xbf' > .guardrails/config.new
    cat .guardrails/config.yaml >> .guardrails/config.new
    mv .guardrails/config.new .guardrails/config.yaml
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"BOM"* ]]
}

@test "check-trace: a config with a YAML document separator still parses" {
    # not `sed '1i'` — its one-line form is GNU-specific
    printf -- '---\n' > .guardrails/config.new
    cat .guardrails/config.yaml >> .guardrails/config.new
    mv .guardrails/config.new .guardrails/config.yaml
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ]
}

@test "check-trace: a typo'd doc key is an error, not a project without that document" {
    cat >> docs/risk/0001-01-01-base.md <<'EOF'

**HAZ-002**: Underdose delivered to patient.
EOF
    commit_all unmitigated
    # sanity: with the key spelled correctly this run fails on HAZ-002, so the
    # exit 2 below closes a hole that was really open
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNMITIGATED-HAZARD HAZ-002"* ]]

    sed -i.bak 's/^doc_rmf:/doc_rmff:/' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_rmff"* ]]
}

# --- A prefix must have gates, and those gates must have their inputs -------

@test "check-trace: a config with no gated prefix at all is an error" {
    # Not "every prefix must be gated" — an extra prefix is covered by
    # DANGLING-REF and DUPLICATE-ID and is a legitimate thing to declare. What
    # is not legitimate is a config where NO prefix has a traceability gate:
    # every gate is then off and the run still exits 0.
    sed -i.bak 's/^id_prefixes:.*/id_prefixes: TC/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"TC"* ]]
    [[ "$output" == *"no prefix with a traceability gate"* ]]
}

@test "check-trace: an extra prefix alongside the gated ones is accepted and still checked" {
    # DANGLING-REF is keyed on the configured prefix list, so an extra prefix
    # IS checked. Rejecting it told the operator to remove it, which removed
    # that coverage and turned a reported violation into exit 0.
    sed -i.bak 's/^id_prefixes:.*/id_prefixes: REQ HAZ RC SDD LLR PR ADR/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf '// see ADR-007\n' > src/main.c
    commit_all extra-prefix
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF ADR-007"* ]]
}


@test "check-trace: RC declared without doc_srs is an error, not a skipped gate" {
    # UNIMPLEMENTED-CONTROL looks for a REQ that implements each RC, so it
    # reads doc_srs — a document RC is not defined in.
    cat > .guardrails/config.yaml <<'EOF'
guardrails_version: 0.1.0
safety_class: B
id_prefixes: HAZ RC
doc_rmf: docs/risk
EOF
    commit_all haz-rc-only
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"doc_srs"* ]]
    [[ "$output" == *"RC"* ]]
}

@test "check-trace: REQ declared with an empty test_paths is an error, not zero tests to search" {
    # A present-but-empty list, not a typo: `test_path:` is already caught as
    # an unknown key, so it would not exercise this rule at all.
    sed -i.bak 's|^  - tests$||' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"test_paths"* ]]
}

@test "check-trace: RC without doc_rmf still runs its gate, and is not rejected" {
    # UNIMPLEMENTED-CONTROL reads doc_srs, not doc_rmf. Requiring doc_rmf here
    # would reject a retrofit that has requirements, controls and design but no
    # risk management file yet — while telling it a gate "could never run" that
    # demonstrably does.
    cat > .guardrails/config.yaml <<'EOF'
guardrails_version: 0.1.0
safety_class: B
id_prefixes: REQ RC SDD
doc_srs: docs/requirements
doc_sad: docs/architecture
strict_paths:
  - src
test_paths:
  - tests
EOF
    printf '\n**RC-002**: an unimplemented control.\n' >> docs/requirements/0001-01-01-base.md
    commit_all rc-no-rmf
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNIMPLEMENTED-CONTROL RC-002"* ]]
}

@test "check-trace: a list item orphaned by a commented-out key is an error" {
    # Absorbing it into the block above turns a production source path into a
    # test path, so a `verifies:` annotation in src/ counts as a test.
    sed -i.bak 's/^strict_paths:$/# strict_paths:/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"- src"* ]]
}
