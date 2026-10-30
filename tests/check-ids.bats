load helpers

setup() {
    make_fixture_repo
    cat > docs/requirements/0001-01-01-base.md <<'EOF'
# SRS

**REQ-001**: The system shall exist.
EOF
    commit_all "srs with REQ-001"
}

@test "check-ids: clean repo passes" {
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "check-ids: draft ID fails with DRAFT-ID" {
    printf '\n**REQ-DRAFT-mybranch-1**: a draft item.\n' >> docs/requirements/0001-01-01-base.md
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-ID"* ]] || { echo "$output"; false; }
}

@test "check-ids: an LLR draft token fails" {
    printf '**LLR-DRAFT-mybranch-1**: draft low-level req.\n' > docs/architecture/0001-01-01-base.md
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-ID"* ]] || { echo "$output"; false; }
    [[ "$output" == *"LLR-DRAFT-mybranch-1"* ]] || { echo "$output"; false; }
}

@test "check-ids: a PR draft token fails" {
    printf '**PR-DRAFT-mybranch-1**: draft problem. status: open\n' > docs/problems/0001-01-01-base.md
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"PR-DRAFT-mybranch-1"* ]] || { echo "$output"; false; }
}

@test "check-ids: draft-named file fails with DRAFT-FILE" {
    printf '# placeholder\n' > docs/requirements/DRAFT-mybranch-dose.md
    git add docs/requirements/DRAFT-mybranch-dose.md
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-FILE docs/requirements/DRAFT-mybranch-dose.md"* ]] || { echo "$output"; false; }
}

@test "check-ids: a file listing that fails is an error, not a tree with no draft-named ledger file" {
    # verifies: REQ-beb6gm, REQ-knb3qu
    # A git that fails `ls-files` lists nothing, and nothing listed is what a
    # tree with no draft-named ledger file looks like. The draft name below
    # proves the run would otherwise have failed DRAFT-FILE.
    printf '# placeholder\n' > docs/requirements/DRAFT-mybranch-dose.md
    commit_all draftfile
    failing_git_directory=$(make_git_failing_on '*" ls-files "*')
    PATH="$failing_git_directory:$PATH" run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 2 ] || { echo "failed listing read as a clean tree: $status $output"; false; }
    [[ "$output" == *"git ls-files exit 128"* ]] || { echo "$output"; false; }
}

@test "check-ids: duplicate LLR definitions fail with DUPLICATE-ID" {
    printf '**LLR-001**: clamp dose. satisfies: REQ-001\n' > docs/architecture/0001-01-01-base.md
    printf '**LLR-001**: duplicate.\n' > src/extra.md
    commit_all llr-dup
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID LLR-001"* ]] || { echo "$output"; false; }
}

@test "check-ids: duplicate in-tree definitions fail with DUPLICATE-ID" {
    printf '**REQ-001**: duplicate definition.\n' > src/extra.md
    commit_all dup
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID REQ-001"* ]] || { echo "$output"; false; }
}

@test "check-ids: an ID prefix that is not a bare identifier is an error" {
    # Before validation this printed "grep: Unmatched ( or \(" and exited 0 —
    # an invalid pattern matches nothing, which looks exactly like a clean tree.
    sed -i.bak 's/^id_prefixes:.*/id_prefixes: REQ HAZ RC SDD LLR PR[/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf '\n**REQ-DRAFT-b-1**: draft requirement.\n' >> docs/requirements/0001-01-01-base.md
    commit_all metachar
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"bare identifier"* ]] || { echo "$output"; false; }
    # and only that: gr_prefix_re must propagate the die rather than returning
    # an empty string that trips the unrelated "not configured" fallback
    [[ "$output" != *"not configured"* ]] || { echo "$output"; false; }
}

@test "check-ids: a draft whose prefix is missing from id_prefixes is still a draft" {
    # check-ids must recognise a draft token whatever its prefix. When it
    # looked only for the declared prefixes, the old finalize gate blocked on a
    # draft
    # this gate waved through — a hole between two gates of the same sequence.
    sed -i.bak 's/^id_prefixes:.*/id_prefixes: REQ HAZ RC SDD LLR/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    printf '\n**PR-DRAFT-b-1**: a problem. status: open\n' >> docs/problems/README.md
    commit_all undeclared-prefix-draft
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-ID"* ]] || { echo "$output"; false; }
    [[ "$output" == *"PR-DRAFT-b-1"* ]] || { echo "$output"; false; }
}

@test "check-ids: an ID inside the excluded tooling dir is not a duplicate" {
    # The fixture is in .guardrails/scripts/ because that — not the whole
    # .guardrails/ tree — is what the scans exclude. A project file one level
    # up is scanned, and the test below asserts that.
    printf '**REQ-a3k9z2**: an item inside the tooling dir.\n' > .guardrails/scripts/notes.md
    printf '**REQ-a3k9z2**: the project own definition.\n' > docs/requirements/2026-01-01-x.md
    commit_all guardrails-id

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"DUPLICATE-ID"* ]] || { echo "$output"; false; }
}

@test "every script parses as POSIX sh" {
    # verifies: REQ-why7yf
    cd "$BATS_TEST_DIRNAME/.."
    # An apostrophe inside a single-quoted awk program closes the quote and
    # leaves a script that cannot be parsed at all. The rest of the suite
    # catches it only as dozens of unrelated failures; one named test says
    # what broke.
    seen=0
    for f in scripts/*.sh; do
        seen=$((seen + 1))
        sh -n "$f" || { echo "does not parse: $f"; false; }
    done
    [ "$seen" -eq 13 ] || { echo "expected 13 scripts, scanned $seen"; false; }
}

@test "poisoning gr_def_re changes every gate's verdict" {
    # verifies: REQ-vn6s4v
    # A behavioural check, because a text-based one is defeated by a copy in
    # another quoting style, a copy spelled [[:digit:]], a copy split across
    # lines, a copy spelled [-][0-9], a call whose result is discarded on the
    # next line, or a gr_def_re redefined inside the script itself. None of
    # those defeats this.
    #
    # Redefining at the END of lib.sh wins over the original by shell rules, so
    # every caller that really goes through lib.sh's constructor is poisoned.
    # A script containing its own copy — or calling the real one and ignoring
    # it — keeps working, and that is exactly what this test then catches.
    printf '\n**PR-a3k9z2**: an item defined here.\nstatus: open\n' >> docs/problems/README.md
    printf '**PR-a3k9z2**: the same ID defined a second time.\nstatus: open\n' \
        > docs/problems/dup.md
    # check-trace rejects the run when a configured test_paths entry matches no
    # file, so this fixture needs one before its counts can be compared.
    printf 'true\n' > tests/test_a.sh
    commit_all items

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID PR-a3k9z2"* ]] || { echo "baseline wrong: $output"; false; }
    [[ "$output" != *"MALFORMED-ID"* ]] || { echo "baseline wrong: $output"; false; }
    run sh .guardrails/scripts/check-trace.sh
    # The whole count line, not a substring: "PR 1" also matches "PR 10".
    [[ "$output" == *"checked: REQ 1, HAZ 0, RC 0, SDD 0, LLR 0, PR 1"* ]] \
        || { echo "baseline wrong: $output"; false; }

    printf '\ngr_def_re() { printf %%s "ZZ-NO-SUCH-PATTERN-ZZ"; }\n' \
        >> .guardrails/scripts/lib.sh

    run sh .guardrails/scripts/check-ids.sh
    [[ "$output" != *"DUPLICATE-ID"* ]] || { echo "check-ids has its own copy: $output"; false; }
    # And the other side of the same constructor: with nothing matching as a
    # definition, every definition-shaped line becomes a malformed one. A
    # MALFORMED-ID gate with its own idea of a valid ID would stay quiet.
    [[ "$output" == *"MALFORMED-ID"*"PR-a3k9z2"* ]] \
        || { echo "the malformed gate has its own copy: $output"; false; }

    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"checked: REQ 0, HAZ 0, RC 0, SDD 0, LLR 0, PR 0"* ]] \
        || { echo "check-trace has its own copy: $output"; false; }
}

@test "check-review owes each definition check-trace counts, and no other line" {
    # verifies: REQ-vn6s4v
    # A problem ledger with both definition forms, a token ID and a legacy
    # numeric one, and two definition-shaped lines that are prose: one
    # indented, one in backticks. check-trace counts the two definitions;
    # deleting the ledger owes exactly those two in Resolves: and Problems:.
    cat > docs/problems/open.md <<'LEDGER'
**PR-abc234**: a problem in token form
status: open

**PR-007**: a problem in legacy numeric form
status: open

  **PR-def567**: indented, so prose
`**PR-ghj789**: in backticks, so prose`
LEDGER
    # check-trace rejects the run when a configured test_paths entry matches
    # no file.
    printf 'true\n' > tests/test_a.sh
    commit_all problems
    run sh .guardrails/scripts/check-trace.sh
    # The whole count line: "PR 2" also matches "PR 20".
    printf '%s\n' "$output" \
        | grep -qx 'checked: REQ 1, HAZ 0, RC 0, SDD 0, LLR 0, PR 2' \
        || { echo "$output"; false; }

    make_change_worktree my-change
    git rm -q docs/problems/open.md
    commit_all resolve
    write_message
    run sh .guardrails/scripts/check-review.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    output_has "RESOLVES (deleted PR-007, not named in Resolves:)"
    output_has "RESOLVES (deleted PR-abc234, not named in Resolves:)"
    output_has "PROBLEMS (deleted PR-007, not named under Problems:)"
    output_has "PROBLEMS (deleted PR-abc234, not named under Problems:)"
    output_lacks "PR-def567"
    output_lacks "PR-ghj789"
}

@test "check-ids: a stock install does not report its own tooling" {
    # verifies: REQ-pxjhm4
    # The scan exclusion, which names .guardrails/scripts and nothing wider,
    # exists only so the installed scripts — whose comments contain
    # `REQ-DRAFT-b-1` and definition-form examples — do not trip the gates
    # they implement. That is the criterion the exclusion's width trades
    # against, so assert it rather than assume it.
    #
    # It passes with a wider exclusion too, so it is no evidence that the
    # exclusion is narrow.
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ] || { echo "tooling reports itself: $output"; false; }
    [[ "$output" != *"DRAFT-ID"* ]] || { echo "own draft token: $output"; false; }
    [[ "$output" != *"MALFORMED-ID"* ]] || { echo "own def form: $output"; false; }
}

@test "check-ids: a draft ID in a project file under .guardrails/ is reported" {
    # A scan pathspec that excludes the whole .guardrails/ tree hides anything
    # a project keeps there from every tree-wide gate. Only the tooling needs
    # excluding.
    mkdir -p .guardrails/docs/requirements
    cat > .guardrails/docs/requirements/DRAFT-x-srs.md <<'EOF'
# SRS

**REQ-DRAFT-x-1**: The pump shall stop on occlusion.
EOF
    commit_all "ledger under .guardrails"

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ] || { echo "draft ID invisible: $output"; false; }
    [[ "$output" == *"DRAFT-ID .guardrails/docs/requirements/DRAFT-x-srs.md"*"REQ-DRAFT-x-1"* ]] \
        || { echo "no DRAFT-ID line for it: $output"; false; }
}

@test "check-ids: a misspelled config key is an error here too" {
    # The general form of the same gap: any shape gr_check_config exists to
    # reject was rejected by two of the three gates.
    sed -i.bak 's/^strict_paths:/strict-paths:/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    commit_all misspelled-key

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 2 ] || { echo "accepted a broken config: $output"; false; }
}

@test "poisoning GR_SCAN_EXCLUDE changes every gate's verdict" {
    # A lint that greps for the right spelling is defeated by a different
    # spelling: a single-quoted copy, a comment that preserves the count, a
    # shadowing definition. So prove the single source of truth
    # behaviourally: move the exclusion onto src/, and
    # require every scan to follow it there. A call site still with its own
    # literal pathspec would not move, and would fail here.
    #
    # check-ids.sh has three such sites — the draft scan, MALFORMED-ID and the
    # duplicate scan — and each has its own observable below.
    printf '**REQ-001**: a second definition of the fixture item.\n**REQ-b4m7q3**: an item outside its ledger.\n**REQ-abcdef**: a body that is not an ID.\n**REQ-DRAFT-x-1**: a draft.\n' \
        > src/notes.md
    # check-trace.sh runs below, and this file's fixture leaves tests/ empty.
    printf '# verifies: REQ-001\ntrue\n' > tests/test_a.sh
    commit_all poison-fixture

    # Unpoisoned: every scan sees src/.
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-ID src/notes.md"* ]] || { echo "$output"; false; }
    [[ "$output" == *"MALFORMED-ID src/notes.md"* ]] || { echo "$output"; false; }
    [[ "$output" == *"DUPLICATE-ID REQ-001"* ]] || { echo "$output"; false; }
    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"checked: REQ 2,"* ]] || { echo "$output"; false; }

    printf "\nGR_SCAN_EXCLUDE=':(exclude)src'\n" >> .guardrails/scripts/lib.sh

    # The poison REPLACES the exclusion rather than adding to it — it is one
    # pathspec argument, not a list — so the move is visible from both ends:
    # src/ becomes invisible and .guardrails/scripts/ becomes visible, and the
    # tooling starts reporting the draft token in its own comments. A scan
    # with its own literal pathspec would move at neither end.
    run sh .guardrails/scripts/check-ids.sh
    [[ "$output" != *"DRAFT-ID src/notes.md"* ]] \
        || { echo "check-ids still scans src: $output"; false; }
    [[ "$output" == *"DRAFT-ID .guardrails/scripts/"* ]] \
        || { echo "check-ids did not follow the exclusion: $output"; false; }
    [[ "$output" != *"MALFORMED-ID"* ]] \
        || { echo "the malformed scan kept its own pathspec: $output"; false; }
    [[ "$output" != *"DUPLICATE-ID REQ-001"* ]] \
        || { echo "the duplicate scan kept its own pathspec: $output"; false; }

    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"checked: REQ 1,"* ]] \
        || { echo "check-trace has its own pathspec: $output"; false; }
}

@test "check-ids: a definition-shaped line with a bad body is MALFORMED-ID" {
    # Under drafts the final ID was written by a script and was always well
    # formed. Now a person types it, and **REQ-abcdef**: matches nothing in the
    # toolkit: it defines no item, no gate is keyed on it, and every check
    # passes over it in silence.
    printf '**REQ-abcdef**: six letters, no digit, so no gate ever sees this\n' \
        > docs/requirements/2026-01-01-x.md
    commit_all malformed

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MALFORMED-ID"*"REQ-abcdef"* ]] || { echo "$output"; false; }
}

@test "check-ids: a legacy short ID is MALFORMED-ID too" {
    # [0-9]{3,} passed over **REQ-01**: in silence as well. Reporting it is a
    # real finding in any project that has one, not a regression.
    printf '**REQ-01**: two digits\n' > docs/requirements/2026-01-01-x.md
    commit_all shortid

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MALFORMED-ID"*"REQ-01"* ]] || { echo "$output"; false; }
}

@test "check-ids: a minted token definition is not MALFORMED-ID" {
    printf '**REQ-a3k9z2**: a properly minted requirement\n' \
        > docs/requirements/2026-01-01-x.md
    commit_all token

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"MALFORMED-ID"* ]] || { echo "$output"; false; }
}

@test "check-ids: a legacy sequential definition is not MALFORMED-ID" {
    printf '**REQ-014**: an inherited requirement\n' \
        > docs/requirements/2026-01-01-x.md
    commit_all legacy

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"MALFORMED-ID"* ]] || { echo "$output"; false; }
}

@test "check-ids: MALFORMED-ID is anchored to the declared prefixes" {
    # **ADR-abcdef**: is not a claim to be a guardrails item at all, and
    # ordinary bold markdown must not be dragged in either.
    printf '**ADR-abcdef**: another project convention\n**Note**: plain markdown\n' \
        > docs/requirements/2026-01-01-x.md
    printf '**REQ-a3k9z2**: a real one\n' >> docs/requirements/2026-01-01-x.md
    commit_all other-prefix

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"MALFORMED-ID"* ]] || { echo "$output"; false; }
}

@test "check-ids: MALFORMED-ID does not fire on a definition form in prose" {
    # Off column one it defines nothing, exactly as a well-formed one does not.
    printf '**REQ-a3k9z2**: a real one\n\nThe form **REQ-abcdef**: mid-sentence.\n' \
        > docs/requirements/2026-01-01-x.md
    commit_all prose

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"MALFORMED-ID"* ]] || { echo "$output"; false; }
}

# --- a draft-named ledger file fails, and no flag tolerates one -----------

@test "check-ids: --allow-draft-files is gone, and is rejected rather than ignored" {
    # verifies: REQ-ta654s
    # No step creates or renames a draft-named ledger file (ADR-cy7ahd), so a
    # flag that let one pass would be a gate the caller believes they ran.
    # Rejected like --allow-drafts, so a stale CI line or an un-upgraded skill
    # breaks loudly at the upgrade.
    printf '**PR-a3k9z2**: a real item.\nstatus: open\n' > docs/problems/DRAFT-x-new.md
    commit_all draftfile
    run sh .guardrails/scripts/check-ids.sh --allow-draft-files
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    [[ "$output" == *"unknown argument: --allow-draft-files"* ]] || { echo "$output"; false; }
}

@test "check-ids: the draft failure states what to run instead" {
    # Nothing mints a draft any more, so the message has to hand the reader
    # the replacement rather than leave them looking for a finalize step.
    #
    # The draft token is in PROSE, not in definition form. Written as
    # **PR-DRAFT-x-1**: at column one it is also a MALFORMED-ID, and this test
    # would pass on that gate's message even with the draft message blanked.
    #
    # The message is the `fix DRAFT-ID:` line on stdout.
    printf 'A note referring to PR-DRAFT-x-1 in prose.\n' > docs/problems/z.md
    commit_all draft

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" != *"MALFORMED-ID"* ]] || { echo "wrong gate: $output"; false; }
    printf '%s\n' "$output" | grep -q '^fix DRAFT-ID: .*new-id\.sh' \
        || { echo "$output"; false; }
}

@test "check-ids: a draft-named ledger file fails" {
    # verifies: REQ-knb3qu
    printf '**PR-a3k9z2**: a real item.\nstatus: open\n' \
        > docs/problems/DRAFT-x-new.md
    commit_all draftfile

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-FILE"* ]] || { echo "$output"; false; }
}

@test "check-ids: a ledger file named at creation passes" {
    # verifies: REQ-knb3qu, ADR-cy7ahd
    printf '**PR-a3k9z2**: a real item.\nstatus: open\n' > docs/problems/2026-10-13-new.md
    commit_all dated
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"DRAFT-FILE"* ]] || { echo "$output"; false; }
}

@test "check-ids: --allow-drafts is gone, and is rejected rather than ignored" {
    # A flag that silently does nothing is a gate the caller believes they
    # relaxed. Reject it so the skills and any CI that still passes it break
    # loudly at the upgrade.
    run sh .guardrails/scripts/check-ids.sh --allow-drafts
    [ "$status" -eq 2 ]
}

@test "check-ids: --base is gone, and is rejected rather than ignored" {
    run sh .guardrails/scripts/check-ids.sh --base main
    [ "$status" -eq 2 ]
}

@test "check-ids: nothing is reported about a base branch any more" {
    # A detached HEAD — what an ordinary CI checkout produces — is where the
    # old gate announced that it had not run. There is no such gate now, so
    # there is nothing to announce.
    git checkout -q --detach
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"SKIPPED-DUPLICATE-BASE"* ]] || { echo "$output"; false; }
}

@test "check-ids: two definitions of the same token are DUPLICATE-ID" {
    printf '**REQ-a3k9z2**: here.\n' > docs/requirements/2026-01-01-x.md
    printf '**REQ-a3k9z2**: and here.\n' > docs/requirements/2026-01-02-y.md
    commit_all dup

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID REQ-a3k9z2"* ]] || { echo "$output"; false; }
}

@test "check-ids: MALFORMED-ID reports the lines that open one, not the lines that mention one" {
    # Measured on a real 1178-file project: one violation produced ten lines of
    # report, because the location pass searched for the malformed form
    # literally and every sentence quoting it matched. A report that names nine
    # innocent lines is a report nobody reads.
    printf '**REQ-NNNNNN**: the one real violation, at column one.\n' \
        > docs/requirements/2026-01-01-x.md
    printf 'The illustrative form `**REQ-NNNNNN**:` is written like this.\n' \
        >> docs/requirements/2026-01-01-x.md
    printf 'And discussed again here: `**REQ-NNNNNN**:` in prose.\n' \
        >> docs/requirements/2026-01-01-x.md
    commit_all one-violation

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [ "$(printf '%s\n' "$output" | grep -c '^MALFORMED-ID ')" -eq 1 ] \
        || { echo "$output"; false; }
    [[ "$output" == *"2026-01-01-x.md:1:"* ]] || { echo "$output"; false; }
}

@test "check-ids: a definition form inside a fenced code block is still judged" {
    # Deliberate, and the cost is stated in the templates and in ratchet's
    # upgrade note: no gate in this toolkit parses markdown fences. A real
    # definition inside one is a definition to DUPLICATE-ID, so a malformed one
    # inside one is malformed to this gate. Measured on a real project, this is
    # the single line the new gate reports — an illustrative form written flush
    # left inside a fence.
    printf 'Example:\n\n```\n**REQ-NNNNNN**: an illustrative form inside a fence.\n```\n' \
        > docs/requirements/2026-01-01-x.md
    commit_all fenced

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MALFORMED-ID"* ]] || { echo "$output"; false; }
}

@test "check-ids: indenting that same form is what makes it prose" {
    printf 'Example:\n\n```\n  **REQ-NNNNNN**: an illustrative form, indented.\n```\n' \
        > docs/requirements/2026-01-01-x.md
    commit_all fenced-indented

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "check-ids: a duplicate scan that ERRORS is not a clean tree" {
    # A scan that suppressed stderr and checked no status would read an error
    # as a clean tree, and it is the only gate that catches an ID defined
    # twice: no gate compares IDs against the base branch.
    #
    # Fault injection rather than a poisoned pattern: a `git` earlier on PATH
    # that fails the one scan containing -oE, which in this script is the
    # duplicate scan alone.
    real_git=$(command -v git)
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cat > "$BATS_TEST_TMPDIR/bin/git" <<EOF
#!/bin/sh
if [ "\$1" = grep ]; then
    for a in "\$@"; do [ "\$a" = -oE ] && exit 129; done
fi
exec $real_git "\$@"
EOF
    chmod 755 "$BATS_TEST_TMPDIR/bin/git"

    printf '**REQ-a3k9z2**: here.\n' > docs/requirements/2026-01-01-x.md
    printf '**REQ-a3k9z2**: and here.\n' > docs/requirements/2026-01-02-y.md
    commit_all dup

    # Unfaulted, the duplicate is found.
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID REQ-a3k9z2"* ]] || { echo "$output"; false; }

    # Faulted, it must fail loudly — never report the tree clean.
    PATH="$BATS_TEST_TMPDIR/bin:$PATH" run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 2 ] || { echo "errored scan read as a clean tree: $status $output"; false; }
    [[ "$output" == *"duplicate scan failed"* ]] || { echo "$output"; false; }
}

@test "check-ids: the MALFORMED-ID failure states what to run instead" {
    # The location assertion alone would stay green with all three guidance
    # lines dropped, so the guidance is asserted too.
    # The guidance is the `fix MALFORMED-ID:` line on stdout.
    printf '**REQ-abcdef**: a body that is not an ID.\n' \
        > docs/requirements/2026-01-01-x.md
    commit_all malformed

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    printf '%s\n' "$output" | grep -q '^fix MALFORMED-ID: .*new-id\.sh' \
        || { echo "$output"; false; }
}

@test "poisoning gr_def_re_loose changes the MALFORMED-ID verdict" {
    # Without this, narrowing gr_def_re_loose would redden nothing, so
    # check-ids.sh could drift to a hand-spelled loose form with the suite
    # still green. This pins the constructor behaviourally.
    printf '**REQ-abcdef**: hand-typed ID with no digit.\n' > docs/requirements/2026-01-01-x.md
    commit_all malformed-item
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ] || { echo "baseline wrong: $output"; false; }
    [[ "$output" == *"MALFORMED-ID"* ]] || { echo "baseline wrong: $output"; false; }

    printf '\ngr_def_re_loose() { printf %%s "ZZ-NO-SUCH-PATTERN-ZZ"; }\n' \
        >> .guardrails/scripts/lib.sh

    run sh .guardrails/scripts/check-ids.sh
    [[ "$output" != *"MALFORMED-ID"* ]] \
        || { echo "check-ids kept its own loose form: $output"; false; }
}

@test "check-ids: an empty ID body in definition form is MALFORMED-ID" {
    printf '**REQ-**: a definition form with no body at all.\n' > docs/requirements/2026-01-01-x.md
    commit_all empty-body
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"MALFORMED-ID"* ]] || { echo "$output"; false; }
}

@test "check-ids: a bold run containing asterisks is not a definition form" {
    printf '**REQ-a**b**: emphasis inside what is not an item header.\n' > docs/requirements/2026-01-01-x.md
    commit_all asterisk-in-body
    run sh .guardrails/scripts/check-ids.sh
    [[ "$output" != *"MALFORMED-ID"* ]] || { echo "$output"; false; }
}

# --- check-ids under scope --------------------------------------------------

# verifies: REQ-xs9zct
@test "check-ids: a manifest repo without GR_CONFIG is exit 2 naming the remedy" {
    make_units_fixture
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 2 ]
    [[ "$output" == *"multi-unit repository"* ]] || { echo "$output"; false; }
}

# verifies: REQ-9s5jpc
@test "check-ids: a sibling's draft file and draft token are not this unit's finding" {
    make_units_fixture
    printf '# draft\nREQ-DRAFT-other-change-1\n' > platform/hal/docs/requirements/DRAFT-other-change-notes.md
    commit_all sibling-draft
    unit_run check-ids.sh apps/pump
    [ "$status" -eq 0 ]
    unit_run check-ids.sh platform/hal
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-ID"* ]] || false
    [[ "$output" == *"DRAFT-FILE"* ]] || { echo "$output"; false; }
}

# verifies: REQ-27uhud
@test "check-ids: disclaimed-prose-is-not-malformed — a scoped run never reads a disclaimed path" {
    make_units_fixture
    printf '**REQ-abcdef**: legacy prose in definition shape.\n' >> legacy/notes.md
    commit_all legacy-prose
    unit_run check-ids.sh apps/pump
    [ "$status" -eq 0 ]
}

# verifies: REQ-scc93k
@test "check-ids: duplicate-id-stays-tree-wide — a cross-unit duplicate convicts from either unit" {
    make_units_fixture
    printf '\n**REQ-h4m2p9**: a colliding definition.\n' >> apps/pump/docs/requirements/0001-01-01-base.md
    commit_all dup
    unit_run check-ids.sh apps/pump
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID REQ-h4m2p9"* ]] || false
    unit_run check-ids.sh platform/hal
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID REQ-h4m2p9"* ]] || { echo "$output"; false; }
}

# verifies: REQ-scc93k
@test "check-ids: duplicate-id-stays-tree-wide — a duplicate under a disclaimed path still convicts" {
    make_units_fixture
    printf '**REQ-h4m2p9**: stale copy of the interface contract.\n' >> legacy/notes.md
    commit_all legacy-dup
    unit_run check-ids.sh platform/hal
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID REQ-h4m2p9"* ]] || { echo "$output"; false; }
}
