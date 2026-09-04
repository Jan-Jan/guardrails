load helpers

@test "check-units: no-manifest-changes-nothing — a single-unit repo exits 0 stating what it proved" {
    make_fixture_repo
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"no units.yaml — single-unit repository; no unit configs found astray"* ]]
}

@test "check-units: one non-root config without a manifest still passes (the GR_CONFIG layout)" {
    make_fixture_repo
    mkdir -p proj/.guardrails
    cp .guardrails/config.yaml proj/.guardrails/config.yaml
    commit_all one-sub
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 0 ]
}

@test "check-units: stray-unit-configs-without-manifest-are-exit-2" {
    make_fixture_repo
    for d in pkg/a pkg/b; do
        mkdir -p "$d/.guardrails"
        cp .guardrails/config.yaml "$d/.guardrails/config.yaml"
    done
    commit_all strays
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"unit-shaped configs"* ]] || false
    [[ "$output" == *"units.yaml"* ]]
}

@test "check-units: near-miss-manifest-name-is-exit-2 — the class, not one member" {
    make_fixture_repo
    for name in units.yml unit.yaml UNITS.YAML Units.yaml; do
        printf 'units:\n  - pkg/a\n' > ".guardrails/$name"
        run sh .guardrails/scripts/check-units.sh
        [ "$status" -eq 2 ]
        [[ "$output" == *"did you mean .guardrails/units.yaml"* ]] || false
        rm ".guardrails/$name"
    done
}

@test "check-units: near-miss-without-manifest-content-passes — both directions" {
    make_fixture_repo
    printf 'concurrency: 4\n' > .guardrails/units.yml          # near-miss name, foreign content
    printf 'units:\n  - metric\n' > units.yml                   # manifest shape, repo root
    commit_all lookalikes
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 0 ]
}

@test "check-units: the units fixture passes default mode and reports its denominator" {
    make_units_fixture
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"units: 2, disclaimed 2"* ]]
}

@test "check-units: manifest shape errors surface here at exit 2" {
    make_units_fixture
    printf 'unitz:\n  - x\n' >> .guardrails/units.yaml
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 2 ]
}

@test "check-units: unclaimed-path-convicts" {
    make_units_fixture
    mkdir -p tools && printf 'x\n' > tools/build.sh
    commit_all tools
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNCLAIMED-PATH tools/build.sh"* ]]
}

@test "check-units: root-files-implicitly-disclaimed — root files and the manifest's own home pass" {
    make_units_fixture
    printf 'root\n' > CONTRIBUTING.md
    commit_all rootfile
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 0 ]          # README.md, CONTRIBUTING.md, .guardrails/** all implicit
}

@test "check-units: disclaimed-draft-convicts-at-repo-level" {
    make_units_fixture
    printf '# parked draft\nREQ-DRAFT-old-change-1\n' > legacy/DRAFT-old-change-notes.md
    commit_all parked
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DISCLAIMED-DRAFT"* ]] || false
    [[ "$output" == *"legacy/DRAFT-old-change-notes.md"* ]]
}

@test "check-units: disclaimed-prose-is-not-malformed — definition-shaped legacy prose convicts nothing" {
    make_units_fixture
    printf '**REQ-abcdef**: legacy prose with no digit.\n' >> legacy/notes.md
    commit_all legacy-prose
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 0 ]
}

@test "check-units: class-floor-convicts — provider below its consumer's class" {
    make_units_fixture
    sed -i.bak 's/^safety_class: B$/safety_class: A/' platform/hal/.guardrails/config.yaml
    sed -i.bak 's/^safety_class: B$/safety_class: C/' apps/pump/.guardrails/config.yaml
    rm -f platform/hal/.guardrails/config.yaml.bak apps/pump/.guardrails/config.yaml.bak
    commit_all classes
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISCLASSED-DEPENDENCY platform/hal"* ]] || false
    [[ "$output" == *"apps/pump"* ]]
}

@test "check-units: a declared, resolving segregation covers the edge" {
    make_units_fixture
    sed -i.bak 's/^safety_class: B$/safety_class: A/' platform/hal/.guardrails/config.yaml
    rm -f platform/hal/.guardrails/config.yaml.bak
    printf 'segregated_from:\n  - platform/hal (RC-p4q7t3)\n' >> apps/pump/.guardrails/config.yaml
    commit_all segregated
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 0 ]
}

@test "check-units: segregation-citation-must-resolve — dangling RC, missing ADR, alien shape" {
    make_units_fixture
    for cite in 'platform/hal (RC-zz9zz2)' 'platform/hal (adr: docs/adr/none.md)' 'platform/hal because we said so'; do
        cp apps/pump/.guardrails/config.yaml pump-cfg.bak
        printf 'segregated_from:\n  - %s\n' "$cite" >> apps/pump/.guardrails/config.yaml
        run sh .guardrails/scripts/check-units.sh
        [ "$status" -eq 1 ]
        [[ "$output" == *"INCOMPLETE-SEGREGATION"* ]] || false
        mv pump-cfg.bak apps/pump/.guardrails/config.yaml
    done
}

@test "check-units: a segregation entry naming a non-dependency is INCOMPLETE-SEGREGATION" {
    make_units_fixture
    printf 'segregated_from:\n  - apps/pump (RC-h3d8f4)\n' >> platform/hal/.guardrails/config.yaml
    commit_all wrong-way
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"INCOMPLETE-SEGREGATION"* ]]
}

@test "check-units: tbd-class-on-edge-is-exit-2" {
    make_units_fixture
    sed -i.bak 's/^safety_class: B$/safety_class: TBD/' platform/hal/.guardrails/config.yaml
    rm -f platform/hal/.guardrails/config.yaml.bak
    commit_all tbd
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"TBD"* ]]
}

@test "check-units: a TBD class on a unit with no dependency edge passes (tooth one)" {
    make_units_fixture
    make_unit svc/standalone
    write_unit_items svc/standalone REQ-s2t6u3 HAZ-s3v8w2 RC-s4x7y3 SDD-s5z2a8 LLR-s6b3c9
    sed -i.bak 's/^safety_class: B$/safety_class: TBD/' svc/standalone/.guardrails/config.yaml
    rm -f svc/standalone/.guardrails/config.yaml.bak
    cat > .guardrails/units.yaml <<'EOF'
units:
  - platform/hal
  - apps/pump
  - svc/standalone
not_a_unit:
  - legacy
  - docs
EOF
    commit_all standalone
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 0 ]
}

# --- T7: flag modes -----------------------------------------------------------
# hal <- pump <- monitor, plus svc/standalone with no edges.
add_third_tier() {
    make_unit apps/monitor apps/pump
    write_unit_items apps/monitor REQ-m2n6p3 HAZ-m3q8r2 RC-m4s7t3 SDD-m5u2v8 LLR-m6w3x9
    make_unit svc/standalone
    write_unit_items svc/standalone REQ-s2t6u3 HAZ-s3v8w2 RC-s4x7y3 SDD-s5z2a8 LLR-s6b3c9
    cat > .guardrails/units.yaml <<'EOF'
units:
  - platform/hal
  - apps/pump
  - apps/monitor
  - svc/standalone
not_a_unit:
  - legacy
  - docs
EOF
    commit_all third-tier
}

@test "check-units: --list prints the declared units, one per line" {
    make_units_fixture
    run sh .guardrails/scripts/check-units.sh --list
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "platform/hal" ]
    [ "${lines[1]}" = "apps/pump" ]
}

@test "check-units: flag modes without a manifest are exit 2, never an empty list" {
    make_fixture_repo
    for m in --list "--exports x" "--impact HEAD~1..HEAD"; do
        # shellcheck disable=SC2086
        run sh .guardrails/scripts/check-units.sh $m
        [ "$status" -eq 2 ]
        [[ "$output" == *"single-unit repository"* ]] || false
    done
}

@test "check-units: --exports lists the export surface with its defining files" {
    make_units_fixture
    run sh .guardrails/scripts/check-units.sh --exports platform/hal
    [ "$status" -eq 0 ]
    [[ "$output" == "REQ-h4m2p9	platform/hal/docs/requirements/0001-01-01-base.md" ]] || false
    run sh .guardrails/scripts/check-units.sh --exports apps/pump
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    run sh .guardrails/scripts/check-units.sh --exports no/such
    [ "$status" -eq 2 ]
}

@test "check-units: impact-set-is-transitive — a hal change reaches monitor through pump" {
    make_units_fixture
    add_third_tier
    printf 'x\n' > platform/hal/src/new.c
    commit_all hal-change
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [ "$status" -eq 0 ]
    [[ "$output" == *"platform/hal	touched"* ]] || false
    [[ "$output" == *"apps/pump	dependent"* ]] || false
    [[ "$output" == *"apps/monitor	dependent"* ]]
}

@test "check-units: unrelated-unit-skips — the standalone unit never appears" {
    make_units_fixture
    add_third_tier
    printf 'x\n' > platform/hal/src/new.c
    commit_all hal-change
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [ "$status" -eq 0 ]
    [[ "$output" != *"svc/standalone"* ]]
}

@test "check-units: --impact — a touched unit is reported touched, not dependent" {
    make_units_fixture
    printf 'x\n' > apps/pump/src/new.c
    printf 'y\n' > platform/hal/src/new.c
    commit_all both
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [[ "$output" == *"apps/pump	touched"* ]] || false
    [[ "$output" == *"platform/hal	touched"* ]]
}

@test "check-units: --impact — disclaimed and root-level changes map to no unit" {
    make_units_fixture
    printf 'z\n' >> legacy/notes.md
    printf 'r\n' >> README.md
    commit_all outside
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "check-units: --impact — a repository-level .guardrails change maps to every unit" {
    make_units_fixture
    printf '# comment\n' >> .guardrails/units.yaml
    commit_all manifest-touch
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [ "$status" -eq 0 ]
    [[ "$output" == *"platform/hal	touched"* ]] || false
    [[ "$output" == *"apps/pump	touched"* ]]
}

@test "check-units: impact-unclaimed-path-is-exit-2" {
    make_units_fixture
    mkdir -p tools && printf 'x\n' > tools/build.sh
    commit_all tools
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [ "$status" -eq 2 ]
    [[ "$output" == *"UNCLAIMED-PATH"* ]]
}

@test "check-units: --impact on a bad range is exit 2, never an empty set" {
    make_units_fixture
    run sh .guardrails/scripts/check-units.sh --impact 'no..such..range'
    [ "$status" -eq 2 ]
}

# --- fix1 finding-1: the implicitly-disclaimed surface is draft-scanned ------
# Root-level files and the root .guardrails/ are UNCLAIMED-PATH-exempt by
# design, and no unit's scoped run scans them either — so DISCLAIMED-DRAFT
# must cover them here or a draft parked there is scanned by NO gate. The
# negative twin is the fixture-passes test above: the installed scripts under
# .guardrails/scripts/ carry draft-shaped tokens in comments and must convict
# nothing (the GR_SCAN_EXCLUDE reasoning).

@test "check-units: a root-level draft file and its token convict DISCLAIMED-DRAFT" {
    make_units_fixture
    printf '# parked at the root\nREQ-DRAFT-x-change-1\n' > DRAFT-x-notes.md
    commit_all root-draft
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DISCLAIMED-DRAFT DRAFT-x-notes.md:2:"* ]] || false
    # and the file-NAME half convicts on its own line, token or no token
    printf '%s\n' "$output" | grep -qxF "DISCLAIMED-DRAFT DRAFT-x-notes.md"
}

@test "check-units: a draft stashed under the root .guardrails/ convicts DISCLAIMED-DRAFT" {
    make_units_fixture
    printf '# stashed draft\nREQ-DRAFT-stash-change-1\n' > .guardrails/DRAFT-stash.md
    commit_all stash
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DISCLAIMED-DRAFT .guardrails/DRAFT-stash.md"* ]]
}

@test "check-units: a draft token in a tracked root-level file convicts even without a DRAFT name" {
    make_units_fixture
    printf '\ntodo: finish REQ-DRAFT-root-change-1\n' >> README.md
    commit_all root-token
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DISCLAIMED-DRAFT README.md:"* ]]
}

# --- fix1 finding-5: disclaimed definitions do not resolve a citation --------

@test "check-units: a segregation citation defined only under a disclaimed path is INCOMPLETE-SEGREGATION" {
    make_units_fixture
    printf '**RC-l3g4c9**: Legacy isolation argument, kept for reference.\n' >> legacy/notes.md
    printf 'segregated_from:\n  - platform/hal (RC-l3g4c9)\n' >> apps/pump/.guardrails/config.yaml
    commit_all disclaimed-rc
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"INCOMPLETE-SEGREGATION"* ]] || false
    [[ "$output" == *"RC-l3g4c9"* ]] || false
    [[ "$output" == *"legacy/notes.md"* ]]      # the message names the disclaimed-only definition
}

@test "check-units: the same citation defined in a unit's RMF resolves, disclaimed copy notwithstanding" {
    make_units_fixture
    printf '**RC-l3g4c9**: Legacy isolation argument, kept for reference.\n' >> legacy/notes.md
    printf '\n**RC-l3g4c9**: HAL calls are wrapped and rate-checked. mitigates: HAZ-p3v8n2\n' \
        >> apps/pump/docs/risk/0001-01-01-base.md
    printf 'segregated_from:\n  - platform/hal (RC-l3g4c9)\n' >> apps/pump/.guardrails/config.yaml
    commit_all unit-rc
    run sh .guardrails/scripts/check-units.sh
    [ "$status" -eq 0 ]
}
