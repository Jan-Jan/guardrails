load helpers

setup() { make_fixture_repo; }

# --- MISSING-RECORD ---------------------------------------------------------

@test "check-review: a change with no record for its branch fails" {
    make_change_worktree my-change
    write_record other other-change
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-RECORD my-change"* ]] || { echo "$output"; false; }
}

@test "check-review: a record declaring the branch passes" {
    make_change_worktree my-change
    write_record mine my-change
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "check-review: the record need not be committed" {
    # verifies: D9 (docs/plans/2026-08-23-review-artefact.md)
    # It is written at merge-change step 5 and committed with the rest of the
    # change. A gate that only saw committed files would force an extra commit
    # between writing the record and checking it.
    make_change_worktree my-change
    write_record mine my-change
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "check-review: a branch name is matched whole, not as a prefix" {
    # `branch: my-change-2` must not satisfy a check for `my-change`.
    make_change_worktree my-change
    write_record other my-change-2
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-RECORD my-change"* ]] || { echo "$output"; false; }
}

# --- never a vacuous pass ---------------------------------------------------

@test "check-review: run on the base branch it exits 2, never 0" {
    write_record mine main
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"base branch"* ]] || { echo "$output"; false; }
}

@test "check-review: a detached HEAD exits 2" {
    write_record mine my-change
    commit_all records
    git checkout -q --detach
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    # The message is asserted, not just the status: dash exits 2 when it cannot
    # OPEN the script, so a status-only assertion here passes with no script at
    # all — a test that proves the absence of the thing it is testing.
    #
    # And the WHOLE message, not the word "detached": both guards below state
    # "detached", so a substring assertion cannot tell them apart. Mutation M04
    # deleted this guard and the suite stayed green, because a detached HEAD in
    # a single checkout also makes gr_base_branch print nothing and the SECOND
    # guard fired instead. The test named the wrong cause and passed.
    [[ "$output" == *"no change branch can be identified"* ]] \
        || { echo "wrong guard fired: $output"; false; }
}

@test "check-review: a detached PRIMARY checkout exits 2" {
    # The second guard, which the test above used to be satisfied by. Here HEAD
    # names a branch perfectly well; what cannot be determined is the base, so
    # whether this IS a change cannot be decided either.
    make_change_worktree my-change
    write_record mine my-change
    commit_all records
    git -C "$REPO" checkout -q --detach
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"base branch cannot be determined"* ]] \
        || { echo "wrong guard fired: $output"; false; }
}

@test "check-review: a record that cannot be read is an error, not an empty scan" {
    # An awk that cannot open its input finds nothing, and finding nothing is
    # what a compliant record looks like. Mutation M22 dropped the status check
    # and the suite stayed green: no test made awk fail.
    make_change_worktree my-change
    write_record mine my-change
    commit_all records
    chmod 000 docs/verification/2026-01-01-mine.md
    run sh .guardrails/scripts/check-review.sh
    chmod 644 docs/verification/2026-01-01-mine.md
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"record scan failed"* ]] || { echo "$output"; false; }
}

@test "check-review: an absent doc_verification directory exits 2" {
    make_change_worktree my-change
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"docs/verification"* ]] || { echo "$output"; false; }
}

@test "check-review: a doc_verification directory with no *.md exits 2" {
    make_change_worktree my-change
    mkdir -p docs/verification
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"no verification records"* ]] || { echo "$output"; false; }
}

@test "check-review: an invalid config is rejected before any record is read" {
    make_change_worktree my-change
    write_record mine my-change
    printf 'no_such_key: x\n' >> .guardrails/config.yaml
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"unknown config key"* ]] || { echo "$output"; false; }
}

@test "check-review: an unknown argument is rejected, not ignored" {
    make_change_worktree my-change
    write_record mine my-change
    commit_all records
    run sh .guardrails/scripts/check-review.sh --allow-anything
    [ "$status" -eq 2 ]
    [[ "$output" == *"unknown argument"* ]] || { echo "$output"; false; }
}

@test "check-review: --branch names the change in a single checkout" {
    # Not every project runs merge-change from a linked worktree, and CI may
    # want to check a record for a branch that is already merged. Naming the
    # branch is the only thing this relaxes: the record must still exist.
    write_record mine some-branch
    commit_all records
    run sh .guardrails/scripts/check-review.sh --branch some-branch
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    run sh .guardrails/scripts/check-review.sh --branch other-branch
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-RECORD other-branch"* ]] || { echo "$output"; false; }
}

@test "check-review: --branch with no value is rejected" {
    write_record mine my-change
    commit_all records
    run sh .guardrails/scripts/check-review.sh --branch
    [ "$status" -eq 2 ]
    [[ "$output" == *"--branch needs"* ]] || { echo "$output"; false; }
}

# --- INCOMPLETE-RECORD ------------------------------------------------------
# `branch:` is not in this set. It is the SELECTOR — a record that does not
# declare a branch is not this change's record, and its absence is reported as
# MISSING-RECORD above. The three below are what the record must state once it
# has been found.

@test "check-review: a record with no reviewer: fails" {
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak '/^reviewer:/d' docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"INCOMPLETE-RECORD"* ]] || { echo "$output"; false; }
    [[ "$output" == *"no reviewer:"* ]] || { echo "$output"; false; }
}

@test "check-review: a record with no verdict: fails" {
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak '/^verdict:/d' docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"no verdict:"* ]] || { echo "$output"; false; }
}

@test "check-review: a record with no reproduced: fails" {
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak '/^reproduced:/d' docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"no reproduced:"* ]] || { echo "$output"; false; }
}

@test "check-review: every missing field is named, not just the first" {
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak '/^verdict:/d; /^reproduced:/d' docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [[ "$output" == *"no verdict:"* ]] || { echo "$output"; false; }
    [[ "$output" == *"no reproduced:"* ]] || { echo "$output"; false; }
}

@test "check-review: a field with no value is an omission, not compliance" {
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak 's/^reproduced:.*/reproduced:/' docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"no reproduced:"* ]] || { echo "$output"; false; }
}

@test "check-review: a field of whitespace only is an omission" {
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak 's/^reproduced:.*/reproduced:   /' docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"no reproduced:"* ]] || { echo "$output"; false; }
}

@test "check-review: reproduced: no passes — the value is never judged" {
    # The field exists to make silence visible, not to force a yes. A change
    # whose end-to-end failure never reproduced must be able to say so.
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak 's/^reproduced:.*/reproduced: no — the root cause was measured directly/' \
        docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "check-review: a field in YAML front matter does not satisfy the requirement" {
    # A header key is a title-page field, not a claim about the review. Without
    # the front-matter skip this record would pass on metadata alone.
    make_change_worktree my-change
    mkdir -p docs/verification
    printf -- '---\nreviewer: nobody\nverdict: fine\nreproduced: yes\n---\n\nbranch: my-change\n' \
        > docs/verification/2026-01-01-fm.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"no reviewer:"* ]] || { echo "$output"; false; }
}

@test "check-review: an indented field does not satisfy the requirement" {
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak 's/^reviewer:/  reviewer:/' docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"no reviewer:"* ]] || { echo "$output"; false; }
}

@test "check-review: another change's record cannot supply this change's fields" {
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak '/^reviewer:/d' docs/verification/2026-01-01-mine.md
    write_record other other-change
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"2026-01-01-mine.md"* ]] || { echo "$output"; false; }
    [[ "$output" != *"2026-01-01-other.md"* ]] || { echo "$output"; false; }
}

@test "check-review: a record for another change is not schema-checked at all" {
    # Legacy records predate the schema. Failing all of them at once is how a
    # gate gets switched off, so only the record for the change under merge is
    # checked. This is a stated limit, not an oversight.
    make_change_worktree my-change
    write_record mine my-change
    printf '# ancient\n\nnothing structured here at all\n' \
        > docs/verification/2020-01-01-legacy.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# --- UNDISPOSED-FINDING -----------------------------------------------------
# "A verdict per finding". A finding is an item block in the toolkit's own
# ledger shape, so GR_AWK_ITEM_BLOCK decides where it starts and ends and no
# new boundary rule exists here. The failure this catches is the one the report
# named: "repeatedly — my fix to a previous round's finding being half-applied".

@test "check-review: a finding with no disposition fails" {
    make_change_worktree my-change
    write_record mine my-change
    printf '\n**finding-1**: the close rule reinstates the defect.\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNDISPOSED-FINDING"* ]] || { echo "$output"; false; }
    [[ "$output" == *"finding-1"* ]] || { echo "$output"; false; }
}

@test "check-review: a finding with a disposition passes" {
    make_change_worktree my-change
    write_record mine my-change
    printf '\n**finding-1**: the close rule reinstates the defect.\ndisposition: fixed in c0ffee1; the test reddens without it.\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "check-review: a finding whose disposition is blank fails" {
    make_change_worktree my-change
    write_record mine my-change
    printf '\n**finding-1**: the close rule reinstates the defect.\ndisposition:\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNDISPOSED-FINDING"* ]] || { echo "$output"; false; }
}

@test "check-review: the reported line is the finding, not the record" {
    make_change_worktree my-change
    write_record mine my-change
    printf '\n**finding-1**: the close rule reinstates the defect.\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    _n=$(grep -n '^\*\*finding-1\*\*:' docs/verification/2026-01-01-mine.md | cut -d: -f1)
    [[ "$output" == *":${_n} finding-1"* ]] || { echo "want line $_n, got: $output"; false; }
}

@test "check-review: a disposition after the next finding belongs to that one" {
    # The block-boundary test. It reddens if the finding scan uses anything
    # other than the shared item-block rule.
    make_change_worktree my-change
    write_record mine my-change
    printf '\n**finding-1**: first.\n\n**finding-2**: second.\ndisposition: fixed.\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"finding-1"* ]] || { echo "$output"; false; }
    [[ "$output" != *"finding-2"* ]] || { echo "$output"; false; }
}

@test "check-review: a heading between a finding and its disposition detaches it" {
    make_change_worktree my-change
    write_record mine my-change
    printf '\n**finding-1**: first.\n\n## Notes\n\ndisposition: fixed.\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNDISPOSED-FINDING"* ]] || { echo "$output"; false; }
}

@test "check-review: a record with no findings at all passes" {
    # A review that raised nothing is legal, and `verdict:` states that.
    make_change_worktree my-change
    write_record mine my-change
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "check-review: findings in another change's record are not checked" {
    make_change_worktree my-change
    write_record mine my-change
    write_record other other-change
    printf '\n**finding-1**: undisposed, in someone else s record.\n' \
        >> docs/verification/2026-01-01-other.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "check-review: a malformed finding label is reported, never passed over" {
    # `**finding-2b**:` opens no block, so its disposition is credited to
    # nothing and the finding is invisible — a false green of exactly the shape
    # MALFORMED-ID exists to remove. It is reported instead.
    make_change_worktree my-change
    write_record mine my-change
    printf '\n**finding-2b**: mislabelled.\ndisposition: fixed.\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MALFORMED-FINDING"* ]] || { echo "$output"; false; }
}

@test "check-review: a finding inside front matter is not a finding" {
    make_change_worktree my-change
    write_record mine my-change
    printf -- '---\n**finding-1**: metadata, not a finding.\n---\n' \
        > "$BATS_TEST_TMPDIR/gr-fm-head"
    cat docs/verification/2026-01-01-mine.md >> "$BATS_TEST_TMPDIR/gr-fm-head"
    mv "$BATS_TEST_TMPDIR/gr-fm-head" docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# --- the denominator --------------------------------------------------------

@test "check-review: every run reports what it read" {
    make_change_worktree my-change
    write_record mine my-change
    write_record other other-change
    printf '\n**finding-1**: first.\ndisposition: fixed.\n\n**finding-2**: second.\ndisposition: fixed.\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"checked: records 2, for my-change 1, findings 2"* ]] \
        || { echo "$output"; false; }
}

@test "check-review: the denominator is printed on failure too" {
    make_change_worktree my-change
    write_record mine my-change
    printf '\n**finding-1**: first.\n' >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"checked: records 1, for my-change 1, findings 1"* ]] \
        || { echo "$output"; false; }
}

# --- the shared rules are shared, proved behaviourally ----------------------
# A textual pin cannot tell a shared fragment from a copy of one. Make the
# library definition inert and require this gate to change its answer.

@test "poisoning GR_AWK_ITEM_BLOCK changes check-review's verdict" {
    make_change_worktree my-change
    write_record mine my-change
    printf '\n**finding-1**: undisposed.\n' >> docs/verification/2026-01-01-mine.md
    commit_all records

    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "baseline wrong: $output"; false; }
    [[ "$output" == *"UNDISPOSED-FINDING"* ]] \
        || { echo "baseline wrong: $output"; false; }

    cat >> .guardrails/scripts/lib.sh <<'POISON'

GR_AWK_ITEM_BLOCK='
function gr_block_init(pfx_open, body) { }
function gr_block_opens(line) { return 0 }
function gr_block_opens_loose(line) { return 0 }
function gr_block_closes(line) { return 0 }
function gr_block_id(line) { return "ZZ-NO-SUCH-ITEM-ZZ" }
function gr_kw_here(line, kw) { return 1 }
function gr_kw_lead(line) { return line }
function gr_kw_orphan_here(line, kw) { return 1 }
function gr_value(line, kw,   v) {
    v = substr(line, length(kw) + 1)
    sub(/^[ \t]+/, "", v)
    sub(/[ \t]+$/, "", v)
    return v
}
'
POISON

    run sh .guardrails/scripts/check-review.sh
    [[ "$output" != *"UNDISPOSED-FINDING"* ]] \
        || { echo "the finding scan kept its own block rule: $output"; false; }
    # Positively, too. A negative assertion alone is satisfied by a gate that
    # is not there: delete the script and it also prints no UNDISPOSED-FINDING.
    # Its sibling below got this right and this one did not; they were written
    # together.
    [[ "$output" == *"checked: records"* ]] \
        || { echo "the gate did not run at all: $output"; false; }
}

@test "poisoning GR_AWK_FRONT_MATTER changes check-review's verdict" {
    make_change_worktree my-change
    write_record mine my-change
    printf -- '---\n**finding-1**: metadata, not a finding.\n---\n' > "$BATS_TEST_TMPDIR/gr-fm2"
    cat docs/verification/2026-01-01-mine.md >> "$BATS_TEST_TMPDIR/gr-fm2"
    mv "$BATS_TEST_TMPDIR/gr-fm2" docs/verification/2026-01-01-mine.md
    commit_all records

    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "baseline wrong: $output"; false; }

    cat >> .guardrails/scripts/lib.sh <<'POISON'

GR_AWK_FRONT_MATTER='
function gr_fm_reset() { }
function gr_fm_scan(line, n) { }
function gr_fm_skip(n) { return 0 }
'
POISON

    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] \
        || { echo "the record scan kept its own front-matter rule: $output"; false; }
    [[ "$output" == *"UNDISPOSED-FINDING"* ]] \
        || { echo "the record scan kept its own front-matter rule: $output"; false; }
}

# --- the selector must identify the change, not merely mention it -----------
# Review round 1, finding B1. The gate reported a PASS for a change with no
# record at all, because a record for a different change quoted `branch:` in a
# fenced block. Two independent answers: a record claims the FIRST branch it
# contains and no other, and the record must be one this change wrote.

@test "check-review: a branch: inside a fenced code block does not select the record" {
    make_change_worktree my-change
    write_record other other-change
    cat >> docs/verification/2026-01-01-other.md <<'REC'

A finding asked what a record looks like. Answer:

```markdown
branch: my-change
reviewer: whoever
verdict: whatever
reproduced: no
```
REC
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"MISSING-RECORD my-change"* ]] || { echo "$output"; false; }
}

@test "check-review: the record claims the first branch it contains, not the last" {
    make_change_worktree my-change
    write_record mine my-change
    printf '\nbranch: some-other-change\n' >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    run sh .guardrails/scripts/check-review.sh --branch some-other-change
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"MISSING-RECORD some-other-change"* ]] || { echo "$output"; false; }
}

@test "check-review: a record this change did not write is reported, not accepted" {
    # Branch-name reuse. `fix-ci` merged last month, `fix-ci` again today: the
    # old record declares the name and would answer for a review that never
    # happened.
    write_record old my-change
    commit_all "last time round"
    make_change_worktree my-change
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"STALE-RECORD"* ]] || { echo "$output"; false; }
    [[ "$output" == *"did not write it"* ]] || { echo "$output"; false; }
}

@test "check-review: a record modified by this change counts as written by it" {
    write_record mine my-change
    commit_all "last time round"
    make_change_worktree my-change
    printf '\nAmended in this change.\n' >> docs/verification/2026-01-01-mine.md
    commit_all amend
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "check-review: --branch states in the summary that provenance was not checked" {
    write_record old some-branch
    commit_all records
    run sh .guardrails/scripts/check-review.sh --branch some-branch
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"provenance NOT checked (--branch)"* ]] || { echo "$output"; false; }
    make_change_worktree my-change
    write_record mine my-change
    run sh .guardrails/scripts/check-review.sh
    [[ "$output" == *"provenance checked"* ]] || { echo "$output"; false; }
    [[ "$output" != *"NOT checked"* ]] || { echo "$output"; false; }
}

@test "check-review: --branch naming the base branch is rejected" {
    # D6 applies whether the branch was detected or named: the base branch is
    # not a change under review, and answering about it would be a green tick
    # on a question nobody asked.
    write_record mine main
    commit_all records
    run sh .guardrails/scripts/check-review.sh --branch main
    [ "$status" -eq 2 ]
    [[ "$output" == *"names the base branch"* ]] || { echo "$output"; false; }
}

@test "check-review: two records declaring the same branch are both checked" {
    make_change_worktree my-change
    write_record one my-change
    write_record two my-change
    sed -i.bak '/^reproduced:/d' docs/verification/2026-01-01-two.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"checked: records 2, for my-change 2"* ]] || { echo "$output"; false; }
    [[ "$output" == *"2026-01-01-two.md (no reproduced:)"* ]] || { echo "$output"; false; }
}

@test "check-review: a record in a subdirectory of doc_verification is not read" {
    # The one-level limit gr_doc_files has always had, pinned here rather than
    # discovered by a project that nests its records by year. It is loud, not
    # silent: with no record at the top level the gate reports MISSING-RECORD.
    make_change_worktree my-change
    write_record top other-change
    mkdir -p docs/verification/2026
    write_record nested my-change
    mv docs/verification/2026-01-01-nested.md docs/verification/2026/
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-RECORD my-change"* ]] || { echo "$output"; false; }
    [[ "$output" == *"checked: records 1,"* ]] || { echo "$output"; false; }
}

# --- a finding must not be able to vanish ----------------------------------
# Review round 1, finding B2. MALFORMED-FINDING named one shape of unreadable
# header; the neighbouring shapes were still read, matched and dropped, and a
# detached disposition was credited to the finding above.

@test "check-review: a finding header with no colon does not lend its disposition upward" {
    make_change_worktree my-change
    write_record mine my-change
    printf '\n**finding-1**: first, genuinely undisposed\n**finding-2** second, colon forgotten\ndisposition: fixed the second one\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"MALFORMED-FINDING"* ]] || { echo "$output"; false; }
}

@test "check-review: a capitalised finding header loses the finding, and is reported" {
    make_change_worktree my-change
    write_record mine my-change
    printf '\n**Finding-2**: mislabelled.\ndisposition: fixed.\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"ORPHAN-DISPOSITION"* ]] || { echo "$output"; false; }
}

@test "check-review: an indented finding header is reported" {
    make_change_worktree my-change
    write_record mine my-change
    printf '\n  **finding-2**: indented, so it opens nothing.\ndisposition: fixed.\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"MALFORMED-FINDING"* ]] || { echo "$output"; false; }
}

@test "check-review: a finding header with a space instead of a hyphen is reported" {
    make_change_worktree my-change
    write_record mine my-change
    printf '\n**finding 2**: mislabelled.\ndisposition: fixed.\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"MALFORMED-FINDING"* ]] || { echo "$output"; false; }
}

@test "check-review: a disposition belonging to no finding is reported" {
    make_change_worktree my-change
    write_record mine my-change
    printf '\ndisposition: fixed something, but what?\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"ORPHAN-DISPOSITION"* ]] || { echo "$output"; false; }
}

@test "check-review: a bulleted disposition belonging to no finding is reported" {
    # verifies: PR-h3wujj
    # ORPHAN-DISPOSITION is one of exactly two places that took the WIDE
    # predicate, and nothing pinned it here. The gate header read "at column
    # one" while the code stepped over a list marker, so the only statement of
    # this behaviour was a wrong one. The heading closes every finding block,
    # which is what makes the bullet below it an orphan under any rule.
    make_change_worktree my-change
    write_record mine my-change
    printf '\n## Notes\n- disposition: this bullet belongs to no finding block at all\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"ORPHAN-DISPOSITION"* ]] || { echo "$output"; false; }
}

@test "check-review: an ordered-list disposition belonging to no finding is reported" {
    # verifies: PR-h3wujj
    # Round-2 review, finding 15, at the second consumer of the widened
    # backstop. The bullet form above was reported and this one was not, for no
    # reason a reader of a record could name.
    make_change_worktree my-change
    write_record mine my-change
    printf '\n## Notes\n1. disposition: this item belongs to no finding block at all\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"ORPHAN-DISPOSITION"* ]] || { echo "$output"; false; }
}

@test "check-review: an empty ordered-list disposition is not reported as an orphan" {
    # verifies: PR-h3wujj
    # The emptiness guard on the wide path, at the widened marker. It composes
    # gr_value(gr_kw_lead(line), kw) precisely so a marked-up line yields the
    # empty string rather than a fragment of the keyword; widen the stripper
    # and that composition must keep up, or an empty `1. disposition:` starts
    # being reported as an orphan disposition that disposes of nothing.
    make_change_worktree my-change
    write_record mine my-change
    printf '\n## Notes\n1. disposition:\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"ORPHAN-DISPOSITION"* ]] || { echo "$output"; false; }
}

@test "check-review: an ordinary bold header beginning with finding is left alone" {
    # `**findings**: three` is a heading, not a mislabelled finding. A letter
    # after `finding` ends the match, the same tail rule GR_ID_TAIL applies.
    make_change_worktree my-change
    write_record mine my-change
    printf '\n**findings**: three, all disposed elsewhere.\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "check-review: a finding label containing a non-UTF-8 byte is reported" {
    # Review round 1, finding B3. The first version asked a regex with a
    # negated bracket expression, and gawk in a multibyte locale does not match
    # an invalid byte sequence with one — so a latin-1 label failed OPEN at
    # exit 0, decided by the operator locale. Run under a UTF-8 locale on
    # purpose: under LC_ALL=C every awk agrees and the defect is invisible.
    make_change_worktree my-change
    write_record mine my-change
    printf '\n**finding-\351**: latin-1 label.\ndisposition: fixed.\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    LC_ALL=en_US.UTF-8 run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"MALFORMED-FINDING"* ]] || { echo "$output"; false; }
}

# --- bytes the record may legitimately contain -------------------------------
# Review round 1, finding B6: the gate inherited check-trace.sh's BOM and CR
# handling without check-trace.sh's tests for it. Deleting either line
# reddened no test in the whole suite.

@test "check-review: a record saved with CRLF line endings satisfies the gate" {
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak 's/$/\r/' docs/verification/2026-01-01-mine.md
    rm -f docs/verification/2026-01-01-mine.md.bak
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "check-review: a record beginning with a UTF-8 BOM is still read" {
    make_change_worktree my-change
    write_record mine my-change
    printf '\357\273\277' > docs/verification/bom.tmp
    cat docs/verification/2026-01-01-mine.md >> docs/verification/bom.tmp
    mv docs/verification/bom.tmp docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"for my-change 1"* ]] || { echo "$output"; false; }
}

@test "check-review: a BOM does not defeat the front-matter skip" {
    make_change_worktree my-change
    write_record mine my-change
    printf '\357\273\277---\nreviewer: metadata, not a field\n---\n' > docs/verification/bom.tmp
    cat docs/verification/2026-01-01-mine.md >> docs/verification/bom.tmp
    mv docs/verification/bom.tmp docs/verification/2026-01-01-mine.md
    sed -i.bak '/^reviewer: an independent/d' docs/verification/2026-01-01-mine.md
    rm -f docs/verification/2026-01-01-mine.md.bak
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"no reviewer:"* ]] || { echo "$output"; false; }
}

@test "check-review: an empty doc_verification value is rejected, not defaulted" {
    make_change_worktree my-change
    write_record mine my-change
    printf 'doc_verification:\n' >> .guardrails/config.yaml
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    # gr_check_config now rejects ANY key set to nothing, so this arrives at
    # the general diagnosis rather than gr_verification_dir's own — which
    # lib.bats still exercises directly, since a library function has to be
    # safe when called without the validator in front of it.
    [[ "$output" == *"set to nothing"* ]] || { echo "$output"; false; }
    [[ "$output" == *doc_verification* ]] || { echo "$output"; false; }
}

# --- The unit manifest (T9): the review record is repository-level ----------

@test "check-review: review-record-is-repository-level — no unit config, manifest validated, root records read" {
    make_units_fixture
    make_change_worktree units-change
    write_record rec units-change
    commit_all record
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"records"* ]] || { echo "$output"; false; }     # the existing checked: summary
}

@test "check-review: a manifest repo with a broken manifest is exit 2 here too" {
    make_units_fixture
    printf 'unitz:\n  - x\n' >> .guardrails/units.yaml
    # Committed, or the change worktree below would check out the CLEAN
    # manifest from HEAD and this test would exercise nothing.
    commit_all broken-manifest
    make_change_worktree units-change
    write_record rec units-change
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    # The exit 2 must come from the manifest validator, not from the absent
    # root config: pre-manifest, "config not found" also exited 2 here, and
    # that green would have proven nothing.
    [[ "$output" == *"unknown manifest key"* ]] || { echo "$output"; false; }
}

@test "check-review: a manifest repo missing docs/verification is exit 2 naming the rule" {
    make_units_fixture
    git rm -rq docs/verification 2>/dev/null || rm -rf docs/verification
    commit_all no-vdir
    make_change_worktree units-change
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"docs/verification"* ]] || { echo "$output"; false; }
}

@test "check-review: a quoted bulleted branch: does not claim the record" {
    # verifies: PR-h3wujj
    # The mirror regression of the one in check-trace.bats, and the sharper of
    # the two: the record SELECTOR is first-occurrence-wins for the reason
    # given at `A record claims ONE branch` in check-review.sh — a record that
    # quotes another one's `branch:` must not become the record FOR that
    # branch, which would report a pass over a review of it. A reader
    # that steps over a list marker makes the quotation the claim, so this
    # record, which declares `branch: other-change`, would report a pass over
    # a review of my-change that never happened.
    #
    # BOTH HALVES ARE ASSERTED, and the second is the one with teeth. Round-2
    # review, finding 14: MISSING-RECORD my-change alone passes for the wrong
    # reason under half the mutation. Widen gr_kw_here and leave gr_value at
    # column one, and `gr_value("- branch: my-change", "branch:")` slices from
    # byte eight and returns the fragment `h: my-change`, which never equals
    # my-change — so MISSING-RECORD still fires, by an accident of byte offset
    # rather than by the rule under test. The composition lib.sh advertises for
    # the wide position, gr_value(gr_kw_lead(line), kw), returns my-change and
    # restores the regression with that assertion still green.
    #
    # What no byte offset can fake: first-occurrence-wins means the quotation,
    # once taken, is the ONLY claim the record makes. So ask the record for the
    # branch it really declares. Under the narrow readers it answers for
    # other-change; under either widening it has spent its one claim on the
    # quotation and answers for nothing.
    make_change_worktree my-change
    mkdir -p docs/verification
    cat > docs/verification/2026-01-01-other.md <<'EOF'
# Verification — other

The record this one replaces opened with:

- branch: my-change

branch: other-change
reviewer: an independent subagent
verdict: accepted, no findings outstanding
reproduced: yes, against the shipped scripts, before any change
EOF
    commit_all quoted-bullet-branch
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"MISSING-RECORD my-change"* ]] || { echo "$output"; false; }
    [[ "$output" == *"for my-change 0"* ]] || { echo "$output"; false; }

    # The claim the record DOES make, asked for by name. --branch skips the
    # provenance test and nothing else, so this is the selector alone.
    run sh .guardrails/scripts/check-review.sh --branch other-change
    [ "$status" -eq 0 ] || { echo "the record no longer claims its own branch: $output"; false; }
    [[ "$output" == *"for other-change 1"* ]] || { echo "$output"; false; }
}

# --- a git step whose failure would read as a state -------------------------

# verifies: PR-tz6gsp
@test "check-review: a failed git worktree list exits 2, is not read as a detached primary checkout" {
    # Before gr_base_branch took the status, its failure printed nothing, and
    # the run exited 2 with "the primary checkout is detached".
    make_change_worktree my-change
    write_record mine my-change
    commit_all records
    head_before=$(git rev-parse HEAD)
    stub_directory=$(make_git_failing_on '*" worktree list "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "git worktree list failed, so the base branch cannot be read."
    output_lacks "detached"
    [ -z "$(git status --porcelain)" ] || { echo "the worktree changed"; false; }
    [ "$(git rev-parse HEAD)" = "$head_before" ] || { echo "HEAD moved"; false; }
}

# verifies: PR-tz6gsp
@test "check-review: --branch with a failed git worktree list exits 2, is not read as a detached primary checkout" {
    # --branch accepts an empty base as a detached primary checkout, so before
    # gr_base_branch took the status the run continued with no base branch.
    make_change_worktree my-change
    write_record mine my-change
    commit_all records
    head_before=$(git rev-parse HEAD)
    stub_directory=$(make_git_failing_on '*" worktree list "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/check-review.sh --branch my-change
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "git worktree list failed, so the base branch cannot be read."
    output_lacks "detached"
    [ -z "$(git status --porcelain)" ] || { echo "the worktree changed"; false; }
    [ "$(git rev-parse HEAD)" = "$head_before" ] || { echo "HEAD moved"; false; }
}

# --- --cite and review_cite: a disposition cites what it changed ------------
#
# D12 of the salvage plan: opt-in, a credited disposition must cite a path in
# the tree, a test name in test_paths or a defined item ID, or say
# `no change — <reason>`. Plan: docs/plans/2026-10-08-check-review-cite.md.

# write_review DISPOSITION_TEXT — the record mine for my-change, with a review
# section holding one finding answered by DISPOSITION_TEXT, which may run over
# several lines.
write_review() {
    write_record mine my-change
    printf '\n## Review\n\n**finding-1**: code, low — x\n%s\n' "$1" \
        >> docs/verification/2026-01-01-mine.md
}

# The line number of the first column-one `disposition:` in the record.
disposition_line() {
    grep -n '^disposition:' docs/verification/2026-01-01-mine.md | head -n 1 | cut -d: -f1
}

# A defined PR item, for find-items.sh show to find.
write_defined_pr() {
    printf '\n**PR-b7k2m4**: a defined problem\nstatus: open\n' \
        >> docs/problems/README.md
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a disposition citing an existing path passes" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'disposition: fixed in scripts/x.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a path with a line or a line range passes" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'disposition: fixed at `scripts/x.sh:12`.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "line: $output"; false; }
    write_review 'disposition: fixed at (scripts/x.sh:3-9),'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "range: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a disposition citing a path not in the tree fails" {
    make_change_worktree my-change
    write_review 'disposition: fixed in scripts/missing.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line) (cites no path in the tree, test name in test_paths or defined item ID, and is not \"no change — <reason>\")"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a bats test name in backticks resolves in test_paths" {
    make_change_worktree my-change
    mkdir -p tests && printf '@test "the test name" {\n    true\n}\n' > tests/x.bats
    write_review 'disposition: fixed; `the test name` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a backtick span no test in test_paths names fails" {
    make_change_worktree my-change
    mkdir -p tests && printf '@test "another test" {\n    true\n}\n' > tests/x.bats
    write_review 'disposition: fixed; `the test name` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line)"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a def in test_paths resolves an identifier span" {
    make_change_worktree my-change
    mkdir -p tests && printf 'def test_thing():\n    assert True\n' > tests/test_x.py
    write_review 'disposition: fixed; `test_thing` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a span a test file quotes but no test is named does not resolve" {
    make_change_worktree my-change
    mkdir -p tests && printf '@test "merges" {\n    run git merge "merge"\n}\n' > tests/x.bats
    write_review 'disposition: fixed; the `merge` path is guarded.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line)"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a bats test name resolves only as the whole @test name" {
    make_change_worktree my-change
    mkdir -p tests && printf '  @test "the test name" {\n    true\n}\n' > tests/x.bats
    write_review 'disposition: fixed; `the test name` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "whole: $output"; false; }
    write_review 'disposition: fixed; `the test` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "prefix: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a jest it() name resolves" {
    make_change_worktree my-change
    mkdir -p tests && printf "it('adds two numbers', () => {\n  expect(1 + 1).toBe(2);\n});\n" > tests/sum.test.js
    write_review 'disposition: fixed; `adds two numbers` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a def that does not begin with test is not a test name" {
    make_change_worktree my-change
    mkdir -p tests && printf 'def helper():\n    return 1\n' > tests/test_x.py
    write_review 'disposition: fixed; `helper` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line)"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a shell function in test_paths is not a test name" {
    make_change_worktree my-change
    mkdir -p tests && printf 'function helper {\n    true\n}\nother() {\n    true\n}\n' > tests/helpers.bash
    write_review 'disposition: fixed; `helper` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "function: $output"; false; }
    write_review 'disposition: fixed; `other` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "name(): $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a Rust fn resolves an identifier span" {
    make_change_worktree my-change
    mkdir -p tests && printf '#[test]\nfn adds_two() {\n    assert_eq!(2, 1 + 1);\n}\n' > tests/sum.rs
    write_review 'disposition: fixed; `adds_two` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a test name in double quotes resolves as a test name" {
    make_change_worktree my-change
    mkdir -p tests && printf '@test "the test name" {\n    true\n}\n' > tests/x.bats
    write_review 'disposition: fixed; "the test name" reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a double-quoted span no test is named fails" {
    make_change_worktree my-change
    mkdir -p tests && printf '@test "another test" {\n    true\n}\n' > tests/x.bats
    write_review 'disposition: fixed; "the test name" reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line)"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a directory is not a citation" {
    make_change_worktree my-change
    write_review 'disposition: fixed under `docs/`.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "docs/: $output"; false; }
    write_review 'disposition: fixed; leading ./ removed.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "./: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: .git is not a citation, as a file or a directory" {
    make_change_worktree my-change
    [ -f .git ]
    write_review 'disposition: fixed; it copies the `.git` file.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo ".git: $output"; false; }
    write_review 'disposition: fixed; see ./.git now.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "./.git: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a possessive path resolves" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review "disposition: fixed; \`scripts/x.sh\`'s guard now runs."
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "straight: $output"; false; }
    write_review 'disposition: fixed; scripts/x.sh’s guard now runs.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "curly: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a possessive ID in backticks resolves" {
    make_change_worktree my-change
    write_defined_pr
    write_review "disposition: recorded; it is \`PR-b7k2m4\`'s brief."
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a bare possessive ID resolves" {
    make_change_worktree my-change
    write_defined_pr
    write_review "disposition: PR-b7k2m4's resolution line now says so."
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "straight: $output"; false; }
    write_review 'disposition: PR-b7k2m4’s resolution line now says so.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "curly: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a git rev:path names its path" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'disposition: checked with `git show 650f090:scripts/x.sh`.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a defined PR ID resolves" {
    make_change_worktree my-change
    write_defined_pr
    write_review 'disposition: recorded as PR-b7k2m4.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a well-formed undefined PR ID fails" {
    make_change_worktree my-change
    write_defined_pr
    write_review 'disposition: recorded as PR-c8n3p5.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line)"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: no change — with a reason passes" {
    make_change_worktree my-change
    write_review 'disposition: no change — the reviewer misread the call site'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: no change needed. is not the escape" {
    make_change_worktree my-change
    write_review 'disposition: no change needed.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line)"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: no change — with no reason after the dash fails" {
    make_change_worktree my-change
    write_review 'disposition: no change —'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line)"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a citation on a wrapped disposition's second line counts" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'disposition: fixed, and the change is in
scripts/x.sh where the guard now runs.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a citation after a blank line does not count" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'disposition: fixed, and the change is in

scripts/x.sh where the guard now runs.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line)"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md); C1 (docs/plans/2026-10-08-check-review-cite.md)
@test "check-review: without --cite or review_cite an uncited disposition passes and no citations are counted" {
    make_change_worktree my-change
    write_review 'disposition: fixed.'
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    output_lacks "citations"
    output_has "checked: records 1, for my-change 1, findings 1; provenance checked"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md); C1 (docs/plans/2026-10-08-check-review-cite.md)
@test "check-review: review_cite: on without the flag checks citations" {
    make_change_worktree my-change
    printf 'review_cite: on\n' >> .guardrails/config.yaml
    write_review 'disposition: fixed.'
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line)"
}

# verifies: C1 (docs/plans/2026-10-08-check-review-cite.md)
@test "check-review: review_cite: off without the flag does not check citations" {
    make_change_worktree my-change
    printf 'review_cite: off\n' >> .guardrails/config.yaml
    write_review 'disposition: fixed.'
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    output_lacks "citations"
}

# verifies: C1 (docs/plans/2026-10-08-check-review-cite.md)
@test "check-review: review_cite with a value other than on or off exits 2" {
    make_change_worktree my-change
    printf 'review_cite: yes\n' >> .guardrails/config.yaml
    write_review 'disposition: fixed.'
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    output_has "review_cite"
    output_has "'yes'"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: the checked: line counts the dispositions cite-checked" {
    make_change_worktree my-change
    write_review 'disposition: no change — the reviewer misread the call site'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"; citations checked over 1 dispositions" ]] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: --cite comes before or after --branch" {
    make_change_worktree my-change
    write_review 'disposition: fixed.'
    run sh .guardrails/scripts/check-review.sh --cite --branch my-change
    [ "$status" -eq 1 ] || { echo "before: $output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION"
    run sh .guardrails/scripts/check-review.sh --branch my-change --cite
    [ "$status" -eq 1 ] || { echo "after: $output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION"
}

# verifies: C2 (docs/plans/2026-10-08-check-review-cite.md)
@test "check-review --cite: under a unit manifest exits 2 naming multi-unit repositories" {
    make_units_fixture
    make_change_worktree units-change
    write_record rec units-change
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    output_has "multi-unit repositories"
}

# --- review round 1: the guards and branches no test reached ----------------

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: an absolute path does not resolve, though the file exists" {
    make_change_worktree my-change
    abs_file="$BATS_TEST_TMPDIR/outside.txt"
    printf 'x\n' > "$abs_file"
    write_review "disposition: fixed in $abs_file."
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line)"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a path with a .. component does not resolve, though the file exists" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'disposition: fixed in scripts/../scripts/x.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "inside: $output"; false; }
    printf 'x\n' > "$BATS_TEST_TMPDIR/outside.txt"
    write_review 'disposition: fixed in ../outside.txt.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "outside: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a URL does not resolve, though a file at its path exists" {
    make_change_worktree my-change
    mkdir -p http: && printf 'x\n' > http:/x.sh
    write_review 'disposition: fixed; see http://x.sh for the guard.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line)"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: find-items.sh failing on an ID candidate exits 2, never resolves or fails it" {
    make_change_worktree my-change
    rm docs/risk/README.md
    write_review 'disposition: recorded as PR-b7k2m4.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    output_has "find-items.sh show PR-b7k2m4 failed"
    output_lacks "UNRESOLVABLE-DISPOSITION"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a test_paths search that fails exits 2, never reads as no test" {
    make_change_worktree my-change
    sed -i.bak 's|^  - tests$|  - :(bogus)tests|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    write_review 'disposition: fixed; `the test name` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    output_has "cannot search test_paths for a test name"
    output_lacks "UNRESOLVABLE-DISPOSITION"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a Go func Test resolves an identifier span" {
    make_change_worktree my-change
    mkdir -p tests && printf 'package x\n\nfunc TestThing(t *testing.T) {\n}\n' > tests/x_test.go
    write_review 'disposition: fixed; `TestThing` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a jest test() and describe() name resolves" {
    make_change_worktree my-change
    mkdir -p tests && printf 'describe("the sum", () => {\n  test(%s, () => {});\n});\n' "'adds two numbers'" > tests/sum.test.js
    write_review 'disposition: fixed; `adds two numbers` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "test(): $output"; false; }
    write_review 'disposition: fixed; `the sum` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "describe(): $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a second credited disposition in one block is judged on its own" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'disposition: fixed.
disposition: fixed in scripts/x.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line)"
    [[ "$output" == *"; citations checked over 2 dispositions" ]] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a test_paths entry is a git pathspec, as check-trace.sh reads it" {
    make_change_worktree my-change
    sed -i.bak 's|^  - tests$|  - *_test.go|' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    mkdir -p pkg && printf 'package x\n\nfunc TestThing(t *testing.T) {\n}\n' > pkg/x_test.go
    write_review 'disposition: fixed; `TestThing` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a test declared only in a gitignored file does not resolve" {
    make_change_worktree my-change
    mkdir -p tests/vendor && printf '@test "the test name" {\n    true\n}\n' > tests/vendor/x.bats
    printf 'tests/vendor/\n' > .gitignore
    write_review 'disposition: fixed; `the test name` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line)"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a symlink to a file outside the repository does not resolve" {
    make_change_worktree my-change
    printf 'x\n' > "$BATS_TEST_TMPDIR/outside.txt"
    ln -s "$BATS_TEST_TMPDIR/outside.txt" linked.txt
    write_review 'disposition: fixed; see linked.txt.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line)"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a gitignored file does not resolve" {
    make_change_worktree my-change
    mkdir -p ignored && printf 'echo\n' > ignored/x.sh
    printf 'ignored/\n' > .gitignore
    write_review 'disposition: fixed in ignored/x.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line)"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: .//.git/HEAD does not resolve where .git is a directory" {
    # The primary checkout, where .git is a directory and .git/HEAD a file.
    [ -d .git ]
    write_review 'disposition: fixed; see .//.git/HEAD now.'
    run sh .guardrails/scripts/check-review.sh --cite --branch my-change
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line)"
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: an untracked file git does not ignore resolves" {
    # A file the change adds is often untracked at merge-change step 6c.
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/new.sh
    write_review 'disposition: fixed; scripts/new.sh is added.'
    [ -n "$(git ls-files --others --exclude-standard -- scripts/new.sh)" ]
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a backtick span naming a path with a space resolves" {
    make_change_worktree my-change
    mkdir -p "dir with space" && printf 'echo\n' > "dir with space/y.sh"
    write_review 'disposition: fixed in `dir with space/y.sh`.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a path led by ./ or .// resolves to the file it names" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'disposition: fixed in ./scripts/x.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "./: $output"; false; }
    write_review 'disposition: fixed in .//scripts/x.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo ".//: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a tracked file deleted from the working tree does not resolve" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    commit_all tracked
    rm scripts/x.sh
    write_review 'disposition: fixed in scripts/x.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line)"
}

# --- review round 2: the text boundary, the record itself, citation forms ---

# write_review_tagged TAG DISPOSITION_TEXT — as write_review, with the
# finding's header reading `**finding-1**: TAG — x`.
write_review_tagged() {
    write_record mine my-change
    printf '\n## Review\n\n**finding-1**: %s — x\n%s\n' "$1" "$2" \
        >> docs/verification/2026-01-01-mine.md
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: the next finding's header, with no blank line between, ends a disposition's text" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'disposition: fixed.
**finding-2**: code, low — scripts/x.sh
disposition: fixed in scripts/x.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line) "
    [ "$(printf '%s\n' "$output" | grep -c UNRESOLVABLE-DISPOSITION)" -eq 1 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a heading, with no blank line between, ends a disposition's text" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'disposition: fixed.
## Gaps in scripts/x.sh'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line) "
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a code or requirement finding citing only the record being checked fails" {
    make_change_worktree my-change
    write_review 'disposition: fixed; this record, docs/verification/2026-01-01-mine.md, says so.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "code: $output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line) "
    write_review 'disposition: fixed; see `./docs/verification/2026-01-01-mine.md`.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "./ span: $output"; false; }
    write_review_tagged 'requirement, low' 'disposition: fixed; see docs/verification/2026-01-01-mine.md.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "requirement: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a record finding citing the record being checked resolves" {
    make_change_worktree my-change
    write_review_tagged record 'disposition: fixed in docs/verification/2026-01-01-mine.md.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a code finding citing another record in docs/verification resolves" {
    make_change_worktree my-change
    write_record other other-change
    write_review 'disposition: no fix here; docs/verification/2026-01-01-other.md made it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a markdown link names its target path" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'disposition: fixed in [the guard](scripts/x.sh).'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a #anchor suffix is stripped from a path" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'disposition: fixed at scripts/x.sh#L12.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "#L12: $output"; false; }
    write_review 'disposition: fixed at [the guard](scripts/x.sh#L3-L9).'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "link #L3-L9: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a commented-out declaration declares no test" {
    make_change_worktree my-change
    mkdir -p tests && printf '# def test_thing():\n#     assert True\n' > tests/test_x.py
    write_review 'disposition: fixed; `test_thing` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "#: $output"; false; }
    rm tests/test_x.py
    printf 'package x\n\n  // func TestThing(t *testing.T) {\n' > tests/x_test.go
    write_review 'disposition: fixed; `TestThing` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "//: $output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a Go testify suite method declares its test" {
    make_change_worktree my-change
    mkdir -p tests && printf 'package x\n\nfunc (s *SumSuite) TestThing() {\n}\n' > tests/x_test.go
    write_review 'disposition: fixed; `TestThing` covers it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a # is kept where what precedes it is no path" {
    # The anchor is stripped from a path candidate only: notes#1.txt is a
    # file name, since `notes` names nothing.
    make_change_worktree my-change
    printf 'x\n' > 'notes#1.txt'
    write_review 'disposition: fixed; see notes#1.txt.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

# --- review round 3: the guards the round-2 tests left unpinned -------------

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a guideline finding citing only the record being checked fails" {
    # The record is a citation for a `record` finding alone, so a guideline
    # finding, like a code or requirement one, must cite something else.
    make_change_worktree my-change
    write_review_tagged 'guideline, low' 'disposition: fixed; see docs/verification/2026-01-01-mine.md.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line) "
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: an absolute path does not resolve where the same path relative to the root is a file" {
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    write_review 'disposition: fixed in /scripts/x.sh.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line) "
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: with doc_verification led by ./ a code finding citing only the record fails" {
    make_change_worktree my-change
    printf 'doc_verification: ./docs/verification\n' >> .guardrails/config.yaml
    write_review 'disposition: fixed; see docs/verification/2026-01-01-mine.md.'
    run sh .guardrails/scripts/check-review.sh --cite --branch my-change
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION ./docs/verification/2026-01-01-mine.md:$(disposition_line) "
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: with doc_verification ending in / a code finding citing only the record fails" {
    make_change_worktree my-change
    printf 'doc_verification: docs/verification/\n' >> .guardrails/config.yaml
    write_review 'disposition: fixed; see docs/verification/2026-01-01-mine.md.'
    run sh .guardrails/scripts/check-review.sh --cite --branch my-change
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification//2026-01-01-mine.md:$(disposition_line) "
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: def test_thing_extra does not declare test_thing" {
    make_change_worktree my-change
    mkdir -p tests && printf 'def test_thing_extra():\n    assert True\n' > tests/test_x.py
    write_review 'disposition: fixed; `test_thing` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line) "
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a hex prefix shorter than 7 or longer than 40 digits is no git rev" {
    # Each prefix below is lowercase hex, so only its length keeps it from
    # being read as a <rev>: — `face` is a word that happens to be hex.
    make_change_worktree my-change
    mkdir -p scripts && printf 'echo\n' > scripts/x.sh
    for prefix in abc face abcdef 0123456789abcdef0123456789abcdef012345678; do
        write_review "disposition: fixed in $prefix:scripts/x.sh."
        run sh .guardrails/scripts/check-review.sh --cite
        [ "$status" -eq 1 ] || { echo "$prefix: $output"; false; }
        output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line) "
    done
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: a test declared outside test_paths does not resolve" {
    # test_paths is `tests`; scripts/y.bats is neither ignored nor under it.
    make_change_worktree my-change
    mkdir -p scripts && printf '@test "outside name" {\n    true\n}\n' > scripts/y.bats
    write_review 'disposition: fixed; `outside name` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line) "
}

# verifies: D12 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
@test "check-review --cite: with no test_paths no span resolves as a test name" {
    # gr_check_config requires test_paths only where REQ or LLR is declared,
    # so the config drops both prefixes before it drops the key.
    make_change_worktree my-change
    sed -i.bak -e 's|^id_prefixes: .*$|id_prefixes: HAZ RC SDD PR|' \
        -e '/^test_paths:$/,/^  - tests$/d' .guardrails/config.yaml && rm -f .guardrails/config.yaml.bak
    ! grep -q 'test_paths' .guardrails/config.yaml || { cat .guardrails/config.yaml; false; }
    mkdir -p tests && printf '@test "the name" {\n    true\n}\n' > tests/x.bats
    write_review 'disposition: fixed; `the name` reddens without it.'
    run sh .guardrails/scripts/check-review.sh --cite
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "UNRESOLVABLE-DISPOSITION docs/verification/2026-01-01-mine.md:$(disposition_line) "
}
