load helpers

# Every chain starts from the same wire: pump's SAD references hal's exported
# REQ-h4m2p9 (make_units_fixture strings it).

@test "chain: export-removal-convicts — provider unexports, impact set names the consumer, consumer's run blocks" {
    make_units_fixture
    sed -i.bak '/^exported: yes$/d' platform/hal/docs/requirements/0001-01-01-base.md
    rm -f platform/hal/docs/requirements/0001-01-01-base.md.bak
    commit_all unexport
    # link 1: the change maps to hal, and pump rides the reverse depends_on
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [ "$status" -eq 0 ]
    [[ "$output" == *"platform/hal	touched"* ]] || false
    [[ "$output" == *"apps/pump	dependent"* ]] || false
    # link 2: the dependent's own run convicts — so the provider's merge,
    # which runs the impact set, blocks
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 1 ]
    [[ "$output" == *"NON-EXPORTED-REF REQ-h4m2p9"* ]]
}

@test "chain: export-removal-reopens-expectation — a met expectation recomputes to unmet, nothing stored goes stale" {
    make_units_fixture
    cat >> apps/pump/docs/requirements/0001-01-01-base.md <<EOF

**REQ-e7x2m4**: The software shall rely on platform/hal to bound slew rate.
expects: platform/hal
opened: $(days_ago 3)
EOF
    cat >> platform/hal/docs/requirements/0001-01-01-base.md <<'EOF'

**REQ-h8s3t2**: The software shall bound actuator slew rate. satisfies: REQ-e7x2m4
exported: yes
EOF
    printf '# verifies: REQ-h8s3t2\ntrue\n' > platform/hal/tests/test_b.sh
    printf '# verifies: REQ-e7x2m4\ntrue\n' > apps/pump/tests/test_e.sh
    commit_all met
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 0 ]
    [[ "$output" != *"UNMET-EXPECTATION"* ]] || false
    # the provider withdraws the export that carried the satisfies: — delete
    # the LAST exported: line (REQ-h8s3t2's; REQ-h4m2p9's is the first). awk,
    # not sed: the GNU and BSD spellings of a block-relative address disagree.
    awk 'NR==FNR { if ($0=="exported: yes") last=FNR; next }
         FNR!=last { print }' \
        platform/hal/docs/requirements/0001-01-01-base.md \
        platform/hal/docs/requirements/0001-01-01-base.md > h.tmp
    mv h.tmp platform/hal/docs/requirements/0001-01-01-base.md
    commit_all unexport
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [[ "$output" == *"apps/pump	dependent"* ]] || false
    unit_run check-trace.sh apps/pump
    [[ "$output" == *"UNMET-EXPECTATION platform/hal: REQ-e7x2m4"* ]]
}

@test "chain: item-deletion-degrades-to-dangling" {
    make_units_fixture
    # delete the exported item outright (both its lines)
    grep -v -e 'REQ-h4m2p9' -e '^exported: yes$' \
        platform/hal/docs/requirements/0001-01-01-base.md > h.tmp
    mv h.tmp platform/hal/docs/requirements/0001-01-01-base.md
    printf '\n**REQ-h7v3w2**: The software shall limit the dose. (implements: RC-h3d8f4)\n' \
        >> platform/hal/docs/requirements/0001-01-01-base.md
    sed -i.bak 's/verifies: LLR-h6k9m3/verifies: LLR-h6k9m3 REQ-h7v3w2/' platform/hal/tests/test_a.sh
    sed -i.bak 's/satisfies: REQ-h4m2p9/satisfies: REQ-h7v3w2/; s/traces: REQ-h4m2p9/traces: REQ-h7v3w2/' \
        platform/hal/docs/architecture/0001-01-01-base.md
    rm -f platform/hal/tests/test_a.sh.bak platform/hal/docs/architecture/0001-01-01-base.md.bak
    commit_all delete-item
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [[ "$output" == *"apps/pump	dependent"* ]] || false
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 1 ]
    [[ "$output" == *"DANGLING-REF REQ-h4m2p9 (referenced but never defined)"* ]]
}

@test "chain: transitive-dependent-unaffected — in the set, green when it never referenced the item" {
    make_units_fixture
    make_unit apps/monitor apps/pump
    write_unit_items apps/monitor REQ-m2n6p3 HAZ-m3q8r2 RC-m4s7t3 SDD-m5u2v8 LLR-m6w3x9
    cat > .guardrails/units.yaml <<'EOF'
units:
  - platform/hal
  - apps/pump
  - apps/monitor
not_a_unit:
  - legacy
  - docs
EOF
    commit_all monitor
    sed -i.bak '/^exported: yes$/d' platform/hal/docs/requirements/0001-01-01-base.md
    rm -f platform/hal/docs/requirements/0001-01-01-base.md.bak
    commit_all unexport
    run sh .guardrails/scripts/check-units.sh --impact HEAD~1..HEAD
    [[ "$output" == *"apps/monitor	dependent"* ]] || false   # it RUNS (D12: binaries)
    unit_run check-trace.sh apps/monitor
    [ "$status" -eq 0 ]                                  # and passes: no reference
    # one that references the provider directly was never quiet about it:
    printf '\nSee REQ-h4m2p9.\n' >> apps/monitor/docs/architecture/0001-01-01-base.md
    commit_all direct-ref
    unit_run check-trace.sh apps/monitor
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNDECLARED-DEPENDENCY REQ-h4m2p9"* ]]
}

@test "chain: exports-mode-matches-resolution — the listing and the verdicts are one computation" {
    make_units_fixture
    run sh .guardrails/scripts/check-units.sh --exports platform/hal
    listed="$output"
    # every listed ID resolves from the consumer (the fixture references
    # REQ-h4m2p9 already, and the run is green)
    [[ "$listed" == *"REQ-h4m2p9"* ]] || false
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 0 ]
    # an ID the mode omits convicts when referenced
    [[ "$listed" != *"LLR-h6k9m3"* ]] || false
    printf '\nSee LLR-h6k9m3.\n' >> apps/pump/docs/architecture/0001-01-01-base.md
    commit_all internal-ref
    unit_run check-trace.sh apps/pump
    [ "$status" -eq 1 ]
    [[ "$output" == *"NON-EXPORTED-REF LLR-h6k9m3"* ]]
}
