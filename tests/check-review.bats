load helpers

setup() { make_fixture_repo; }

# --- MISSING-RECORD ---------------------------------------------------------

@test "check-review: a change with no record for its branch fails" {
    make_change_worktree my-change
    write_record other other-change
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MISSING-RECORD my-change"* ]]
}

@test "check-review: a record declaring the branch passes" {
    make_change_worktree my-change
    write_record mine my-change
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "check-review: the record need not be committed" {
    # It is written at merge-change step 6b and committed with the rest of the
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
    [[ "$output" == *"MISSING-RECORD my-change"* ]]
}

# --- never a vacuous pass ---------------------------------------------------

@test "check-review: run on the base branch it exits 2, never 0" {
    write_record mine main
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"base branch"* ]]
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
    # And the WHOLE message, not the word "detached": both guards below say
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
    [[ "$output" == *"docs/verification"* ]]
}

@test "check-review: a doc_verification directory with no *.md exits 2" {
    make_change_worktree my-change
    mkdir -p docs/verification
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"no verification records"* ]]
}

@test "check-review: an invalid config is refused before any record is read" {
    make_change_worktree my-change
    write_record mine my-change
    printf 'no_such_key: x\n' >> .guardrails/config.yaml
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"unknown config key"* ]]
}

@test "check-review: an unknown argument is refused, not ignored" {
    make_change_worktree my-change
    write_record mine my-change
    commit_all records
    run sh .guardrails/scripts/check-review.sh --allow-anything
    [ "$status" -eq 2 ]
    [[ "$output" == *"unknown argument"* ]]
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
    [[ "$output" == *"MISSING-RECORD other-branch"* ]]
}

@test "check-review: --branch with no value is refused" {
    write_record mine my-change
    commit_all records
    run sh .guardrails/scripts/check-review.sh --branch
    [ "$status" -eq 2 ]
    [[ "$output" == *"--branch needs"* ]]
}

# --- INCOMPLETE-RECORD ------------------------------------------------------
# `branch:` is not in this set. It is the SELECTOR — a record that does not
# declare a branch is not this change's record, and its absence is reported as
# MISSING-RECORD above. The three below are what the record must say once it
# has been found.

@test "check-review: a record with no reviewer: fails" {
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak '/^reviewer:/d' docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"INCOMPLETE-RECORD"* ]]
    [[ "$output" == *"no reviewer:"* ]]
}

@test "check-review: a record with no verdict: fails" {
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak '/^verdict:/d' docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"no verdict:"* ]]
}

@test "check-review: a record with no reproduced: fails" {
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak '/^reproduced:/d' docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"no reproduced:"* ]]
}

@test "check-review: every missing field is named, not just the first" {
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak '/^verdict:/d; /^reproduced:/d' docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [[ "$output" == *"no verdict:"* ]]
    [[ "$output" == *"no reproduced:"* ]]
}

@test "check-review: a field with no value is an omission, not compliance" {
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak 's/^reproduced:.*/reproduced:/' docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"no reproduced:"* ]]
}

@test "check-review: a field of whitespace only is an omission" {
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak 's/^reproduced:.*/reproduced:   /' docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"no reproduced:"* ]]
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
    [[ "$output" == *"no reviewer:"* ]]
}

@test "check-review: an indented field does not satisfy the requirement" {
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak 's/^reviewer:/  reviewer:/' docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"no reviewer:"* ]]
}

@test "check-review: another change's record cannot supply this change's fields" {
    make_change_worktree my-change
    write_record mine my-change
    sed -i.bak '/^reviewer:/d' docs/verification/2026-01-01-mine.md
    write_record other other-change
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"2026-01-01-mine.md"* ]]
    [[ "$output" != *"2026-01-01-other.md"* ]]
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
    [[ "$output" == *"UNDISPOSED-FINDING"* ]]
    [[ "$output" == *"finding-1"* ]]
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
    [[ "$output" == *"UNDISPOSED-FINDING"* ]]
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
    [[ "$output" == *"finding-1"* ]]
    [[ "$output" != *"finding-2"* ]]
}

@test "check-review: a heading between a finding and its disposition detaches it" {
    make_change_worktree my-change
    write_record mine my-change
    printf '\n**finding-1**: first.\n\n## Notes\n\ndisposition: fixed.\n' \
        >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNDISPOSED-FINDING"* ]]
}

@test "check-review: a record with no findings at all passes" {
    # A review that raised nothing is legal. `verdict:` is what says so.
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
    [[ "$output" == *"MALFORMED-FINDING"* ]]
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
# carries and no other, and the record must be one this change wrote.

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

@test "check-review: the record claims the first branch it carries, not the last" {
    make_change_worktree my-change
    write_record mine my-change
    printf '\nbranch: some-other-change\n' >> docs/verification/2026-01-01-mine.md
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    run sh .guardrails/scripts/check-review.sh --branch some-other-change
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"MISSING-RECORD some-other-change"* ]]
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
    [[ "$output" == *"did not write it"* ]]
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

@test "check-review: --branch says in the summary that provenance was not checked" {
    write_record old some-branch
    commit_all records
    run sh .guardrails/scripts/check-review.sh --branch some-branch
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"provenance NOT checked (--branch)"* ]] || { echo "$output"; false; }
    make_change_worktree my-change
    write_record mine my-change
    run sh .guardrails/scripts/check-review.sh
    [[ "$output" == *"provenance checked"* ]] || { echo "$output"; false; }
    [[ "$output" != *"NOT checked"* ]]
}

@test "check-review: --branch naming the base branch is refused" {
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
    [[ "$output" == *"2026-01-01-two.md (no reproduced:)"* ]]
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
    [[ "$output" == *"checked: records 1,"* ]]
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

@test "check-review: a finding label carrying a non-UTF-8 byte is reported" {
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

# --- bytes the record may legitimately carry -------------------------------
# Review round 1, finding B6: the gate inherited check-trace.sh's BOM and CR
# handling without check-trace.sh's tests for it. Both lines survived deletion
# against the whole suite.

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

@test "check-review: an empty doc_verification value is refused, not defaulted" {
    make_change_worktree my-change
    write_record mine my-change
    printf 'doc_verification:\n' >> .guardrails/config.yaml
    commit_all records
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    # gr_check_config now refuses ANY key set to nothing, so this arrives at
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
    [[ "$output" == *"records"* ]]     # the existing checked: summary
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
    [[ "$output" == *"unknown manifest key"* ]]
}

@test "check-review: a manifest repo missing docs/verification is exit 2 naming the rule" {
    make_units_fixture
    git rm -rq docs/verification 2>/dev/null || rm -rf docs/verification
    commit_all no-vdir
    make_change_worktree units-change
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"docs/verification"* ]]
}
