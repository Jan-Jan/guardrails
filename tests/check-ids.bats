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
    [[ "$output" == *"DRAFT-ID"* ]]
}

@test "check-ids: an LLR draft token fails" {
    printf '**LLR-DRAFT-mybranch-1**: draft low-level req.\n' > docs/architecture/0001-01-01-base.md
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-ID"* ]]
    [[ "$output" == *"LLR-DRAFT-mybranch-1"* ]]
}

@test "check-ids: a PR draft token fails" {
    printf '**PR-DRAFT-mybranch-1**: draft problem. status: open\n' > docs/problems/0001-01-01-base.md
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"PR-DRAFT-mybranch-1"* ]]
}

@test "check-ids: draft-named file fails with DRAFT-FILE" {
    printf '# placeholder\n' > docs/requirements/DRAFT-mybranch-dose.md
    git add docs/requirements/DRAFT-mybranch-dose.md
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-FILE docs/requirements/DRAFT-mybranch-dose.md"* ]]
}

@test "check-ids: duplicate LLR definitions fail with DUPLICATE-ID" {
    printf '**LLR-001**: clamp dose. satisfies: REQ-001\n' > docs/architecture/0001-01-01-base.md
    printf '**LLR-001**: duplicate.\n' > src/extra.md
    commit_all llr-dup
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID LLR-001"* ]]
}

@test "check-ids: duplicate in-tree definitions fail with DUPLICATE-ID" {
    printf '**REQ-001**: duplicate definition.\n' > src/extra.md
    commit_all dup
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DUPLICATE-ID REQ-001"* ]]
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
    [[ "$output" == *"bare identifier"* ]]
    # and only that: gr_prefix_re must propagate the die rather than returning
    # an empty string that trips the unrelated "not configured" fallback
    [[ "$output" != *"not configured"* ]]
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
    [[ "$output" == *"DRAFT-ID"* ]]
    [[ "$output" == *"PR-DRAFT-b-1"* ]]
}

@test "check-ids: an ID inside the excluded tooling dir is not a duplicate" {
    # The fixture sits in .guardrails/scripts/ because that — not the whole
    # .guardrails/ tree — is what the scans exclude. A project file one level
    # up is scanned, and the test below asserts that.
    printf '**REQ-a3k9z2**: an item inside the tooling dir.\n' > .guardrails/scripts/notes.md
    printf '**REQ-a3k9z2**: the project own definition.\n' > docs/requirements/2026-01-01-x.md
    commit_all guardrails-id

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"DUPLICATE-ID"* ]] || { echo "$output"; false; }
}

@test "every gr_def_re call site is still a call site, and no copy joins them" {
    cd "$BATS_TEST_DIRNAME/.."
    # Two assertions, because neither is sufficient on its own and the first
    # two attempts at this test were both false greens.
    #
    # POSITIVE — the number of gr_def_re INVOCATIONS per script. This is the one
    # that cannot be out-spelled: replace a call site with a hand-rolled regex
    # and this reddens however the replacement is written. Round 1 of review
    # defeated a spelling-based check with single quotes; round 2 defeated its
    # replacement twice, once by swapping every call site in the tree for
    # `[[:digit:]]` copies while the suite stayed 168 ok.
    #
    # SHAPE — a search for a definition form spelled out in a script. Defeatable
    # by construction, since it is a regex describing regexes; kept as defence
    # in depth for a copy ADDED without a call site being removed. Digit classes
    # are folded first so [[:digit:]] and [0123456789] cannot simply walk past.
    calls_check_ids=1
    calls_check_review=0
    calls_check_signing=0
    calls_check_trace=2
    calls_finalize_docs=0
    calls_finish_merge=0
    calls_lib=0
    calls_new_id=0

    forms_check_ids=0
    forms_check_review=0
    forms_check_signing=0
    forms_check_trace=0
    forms_finalize_docs=0
    forms_finish_merge=0
    forms_lib=0
    forms_new_id=0

    # The third pin: how many sites paste the library's ID body in directly,
    # rather than through gr_def_re. Replacing one with a hand-rolled shape
    # moves this count whichever way the replacement is spelled.
    body_check_ids=0
    body_check_review=0
    body_check_signing=0
    body_check_trace=7
    body_finalize_docs=0
    body_finish_merge=0
    body_lib=2
    body_new_id=0

    # The two shared definitions added 2026-08-22, pinned for the same reason
    # the three above are. gr_def_re_loose says which lines OPEN in definition
    # shape whatever their body, and GR_AWK_ITEM_BLOCK says where an item block
    # starts and ends. Five gates read the second one; a sixth opinion about
    # where an item ends is precisely the defect that change fixed.
    loose_check_ids=1
    loose_check_review=0
    loose_check_signing=0
    loose_check_trace=0
    loose_finalize_docs=0
    loose_finish_merge=0
    loose_lib=0
    loose_new_id=0

    block_check_ids=0
    block_check_review=1
    block_check_signing=0
    block_check_trace=5
    block_finalize_docs=0
    block_finish_merge=0
    block_lib=0
    block_new_id=0

    # GR_AWK_FRONT_MATTER, added 2026-08-23 and pinned for the reason above.
    # Two gates skip YAML front matter and they must skip the SAME bytes: one
    # reads a `status:` there as metadata and the other must not accept a
    # `reviewer:` there as a field. A third opinion about where a header block
    # ends is the same shape of defect as a third opinion about where an item
    # ends.
    fm_check_ids=0
    fm_check_review=1
    fm_check_signing=0
    fm_check_trace=1
    fm_finalize_docs=0
    fm_finish_merge=0
    fm_lib=0
    fm_new_id=0

    # GR_AWK_CIVIL, added 2026-08-24. One reader today, pinned before there is
    # a second: the toolkit has one notion of what a calendar date is and what
    # a day number is, and hand-rolled date arithmetic is famously the kind
    # that is wrong only in February.
    civil_check_ids=0
    civil_check_review=0
    civil_check_signing=0
    civil_check_trace=2
    civil_finalize_docs=0
    civil_finish_merge=0
    civil_lib=0
    civil_new_id=0

    forms() {
        # Fold the digit-class spellings together, then drop backslashes and
        # both quotes — in separate passes, because a single `tr -d` argument
        # holding a backslash has it read as an escape introducer.
        sed -e 's/\[\[:digit:\]\]/[0-9]/g' -e 's/\[0123456789\]/[0-9]/g' \
            -e 's/\[abcdefghjkmnpqrstuvwxyz[^]]*\]/[0-9]/g' "$1" \
            | tr -d "\\\\" | tr -d "\"'" \
            | grep -nE '\*\*.*-\[0-9\].*\*\*:' || true
    }

    seen=0
    for f in scripts/*.sh; do
        seen=$((seen + 1))
        key=$(basename "$f" .sh | tr '-' '_')
        eval "want_calls=\$calls_$key"
        eval "want_forms=\$forms_$key"
        eval "want_body=\$body_$key"
        eval "want_loose=\$loose_$key"
        eval "want_block=\$block_$key"
        eval "want_fm=\$fm_$key"
        eval "want_civil=\$civil_$key"
        [ -n "$want_calls" ] && [ -n "$want_forms" ] && [ -n "$want_body" ] \
            && [ -n "$want_loose" ] && [ -n "$want_block" ] && [ -n "$want_fm" ] \
            && [ -n "$want_civil" ] \
            || { echo "unpinned script (add it to this test): $f"; false; }

        got_calls=$(grep -c '\$(gr_def_re ' "$f" || true)
        [ "$got_calls" -eq "$want_calls" ] || {
            echo "$f: $got_calls gr_def_re call sites, pinned at $want_calls"
            false
        }

        got_body=$(grep -cE '\$\{?GR_ID_BODY\}?' "$f" || true)
        [ "$got_body" -eq "$want_body" ] || {
            echo "$f: $got_body GR_ID_BODY uses, pinned at $want_body"
            false
        }

        got_loose=$(grep -c '\$(gr_def_re_loose ' "$f" || true)
        [ "$got_loose" -eq "$want_loose" ] || {
            echo "$f: $got_loose gr_def_re_loose call sites, pinned at $want_loose"
            false
        }

        got_block=$(grep -c '\$GR_AWK_ITEM_BLOCK' "$f" || true)
        [ "$got_block" -eq "$want_block" ] || {
            echo "$f: $got_block GR_AWK_ITEM_BLOCK uses, pinned at $want_block"
            false
        }

        got_fm=$(grep -c '\$GR_AWK_FRONT_MATTER' "$f" || true)
        [ "$got_fm" -eq "$want_fm" ] || {
            echo "$f: $got_fm GR_AWK_FRONT_MATTER uses, pinned at $want_fm"
            false
        }

        got_civil=$(grep -c '\$GR_AWK_CIVIL' "$f" || true)
        [ "$got_civil" -eq "$want_civil" ] || {
            echo "$f: $got_civil GR_AWK_CIVIL uses, pinned at $want_civil"
            false
        }

        got_forms=$(forms "$f" | grep -c . || true)
        [ "$got_forms" -eq "$want_forms" ] || {
            echo "$f: $got_forms spelled-out definition forms, pinned at $want_forms"
            forms "$f"
            false
        }
    done
    [ "$seen" -eq 8 ] || { echo "expected 8 scripts, scanned $seen"; false; }

    # And the constructor and the body each exist exactly once, so the counts
    # above are counts of uses of something real rather than of a name nothing
    # defines.
    [ "$(grep -c '^gr_def_re() {' scripts/lib.sh)" -eq 1 ]
    [ "$(grep -c '^GR_ID_BODY=' scripts/lib.sh)" -eq 1 ]
    [ "$(grep -c '^gr_def_re_loose() {' scripts/lib.sh)" -eq 1 ]
    [ "$(grep -c "^GR_AWK_ITEM_BLOCK='" scripts/lib.sh)" -eq 1 ]
    [ "$(grep -c "^GR_AWK_FRONT_MATTER='" scripts/lib.sh)" -eq 1 ]
    [ "$(grep -c "^GR_AWK_CIVIL='" scripts/lib.sh)" -eq 1 ]
    [ "$(grep -c '^gr_limit() {' scripts/lib.sh)" -eq 1 ]
    # gr_value moved into the shared fragment when the problem-report reader
    # became its second consumer. An awk program that redefines it is a syntax
    # error rather than a silent divergence, but a copy under another NAME is
    # not, and that is what this counts.
    [ "$(grep -c 'function gr_value(' scripts/lib.sh)" -eq 1 ]
    [ "$(grep -c 'function gr_value(' scripts/check-review.sh)" -eq 0 ]
    [ "$(grep -c 'function gr_value(' scripts/check-trace.sh)" -eq 0 ]
    [ "$(grep -c '^gr_verification_dir() {' scripts/lib.sh)" -eq 1 ]
    # The emptiness rule has one definition and two readers (gr_doc_files and
    # check-review.sh); a hand-copy in either is what this counts.
    [ "$(grep -c '^gr_md_files() {' scripts/lib.sh)" -eq 1 ]
    # Two call sites in lib.sh (the definition line and gr_doc_files) and one
    # in check-review.sh. A third reader spelling the rule out by hand moves
    # neither count, which is why the poison tests exist alongside these pins.
    [ "$(grep -c 'gr_md_files ' scripts/lib.sh)" -eq 2 ]
    [ "$(grep -c 'gr_md_files ' scripts/check-review.sh)" -eq 1 ]
}

@test "every script parses as POSIX sh" {
    cd "$BATS_TEST_DIRNAME/.."
    # Twice during this change an apostrophe inside a single-quoted awk program
    # closed the quote and left a script that could not be parsed at all. Both
    # times the suite caught it — as 30-odd unrelated failures whose cause took
    # a minute to find. One named test is cheaper.
    seen=0
    for f in scripts/*.sh; do
        seen=$((seen + 1))
        sh -n "$f" || { echo "does not parse: $f"; false; }
    done
    [ "$seen" -eq 8 ] || { echo "expected 8 scripts, scanned $seen"; false; }
}

@test "poisoning gr_def_re changes every gate's verdict" {
    # The behavioural half of AC5 of change D, and the only half that has ever
    # held. Three rounds of review defeated text-based checks: a copy in another
    # quoting style, a copy spelled [[:digit:]], a copy split across lines, a
    # copy spelled [-][0-9], a call whose result is discarded on the next line,
    # and a gr_def_re redefined inside the script itself. None of those survives
    # this.
    #
    # Redefining at the END of lib.sh wins over the original by shell rules, so
    # every caller that really goes through lib.sh's constructor is poisoned.
    # A script carrying its own copy — or calling the real one and ignoring it —
    # keeps working, and that is exactly what this test then catches.
    printf '\n**PR-a3k9z2**: an item defined here.\nstatus: open\n' >> docs/problems/README.md
    printf '**PR-a3k9z2**: the same ID defined a second time.\nstatus: open\n' \
        > docs/problems/dup.md
    # check-trace refuses to run when a configured test_paths entry matches no
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
    # MALFORMED-ID gate holding its own idea of a valid ID would stay quiet.
    [[ "$output" == *"MALFORMED-ID"*"PR-a3k9z2"* ]] \
        || { echo "the malformed gate has its own copy: $output"; false; }

    run sh .guardrails/scripts/check-trace.sh
    [[ "$output" == *"checked: REQ 0, HAZ 0, RC 0, SDD 0, LLR 0, PR 0"* ]] \
        || { echo "check-trace has its own copy: $output"; false; }
}

@test "check-ids: a stock install does not report its own tooling" {
    # AC9. The exclusion narrowed in this change exists only so the installed
    # scripts — whose comments carry `REQ-DRAFT-b-1` and definition-form
    # examples — do not trip the gates they implement. That is the criterion
    # the narrowing trades against, so assert it rather than assume it.
    #
    # Green against main on arrival: it guards the narrowing, and cannot be
    # presented as evidence that the narrowing works.
    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 0 ] || { echo "tooling reports itself: $output"; false; }
    [[ "$output" != *"DRAFT-ID"* ]] || { echo "own draft token: $output"; false; }
    [[ "$output" != *"MALFORMED-ID"* ]] || { echo "own def form: $output"; false; }

    run sh .guardrails/scripts/finalize-docs.sh --dry-run
    [ "$status" -eq 0 ]
    [ -z "$output" ] || { echo "tooling looks renamable: $output"; false; }
}

@test "check-ids: a draft ID in a project file under .guardrails/ is reported" {
    # AC3. The scan pathspec excluded the whole .guardrails/ tree, so anything
    # a project kept there was invisible to every tree-wide gate. Only the
    # tooling needs excluding.
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
    # refuse was refused by two of the three gates.
    sed -i.bak 's/^strict_paths:/strict-paths:/' .guardrails/config.yaml \
        && rm -f .guardrails/config.yaml.bak
    commit_all misspelled-key

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 2 ] || { echo "accepted a broken config: $output"; false; }
}

@test "poisoning GR_SCAN_EXCLUDE changes every gate's verdict" {
    # AC8 of change E, and the lesson of change D: a lint that greps for the
    # right spelling is defeated by a different spelling. Three earlier attempts
    # at a textual guard were each bypassed — by a single-quoted copy, by a
    # comment that preserved the count, by a shadowing definition. So prove the
    # single source of truth behaviourally: move the exclusion onto src/, and
    # require every scan to follow it there. A call site still holding its own
    # literal pathspec would not move, and would fail here.
    #
    # check-ids.sh has three such sites — the draft scan, MALFORMED-ID and the
    # duplicate scan — and each has its own observable below. It had four until
    # MALFORMED-ID's two passes were collapsed into one composed scan; the
    # count here said four for a while afterwards. Independent review, S8.
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
    # holding its own literal pathspec would move at neither end.
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

# --- drafts are gone, and the flag now only covers ledger FILENAMES --------

@test "check-ids: a draft ID fails even with --allow-draft-files" {
    printf '**PR-DRAFT-x-1**: a leftover draft.\nstatus: open\n' \
        > docs/problems/z.md
    commit_all draft

    run sh .guardrails/scripts/check-ids.sh --allow-draft-files
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-ID"* ]]
}

@test "check-ids: the draft failure says what to run instead" {
    # Nothing mints a draft any more, so the message has to hand the reader
    # the replacement rather than leave them looking for a finalize step.
    #
    # The draft token is in PROSE, not in definition form. Written as
    # **PR-DRAFT-x-1**: at column one it is also a MALFORMED-ID, and this test
    # passed on that gate's message instead — mutation M24 blanked the draft
    # message and reddened nothing at all.
    printf 'A note referring to PR-DRAFT-x-1 in prose.\n' > docs/problems/z.md
    commit_all draft

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" != *"MALFORMED-ID"* ]] || { echo "wrong gate: $output"; false; }
    [[ "$output" == *"draft IDs are no longer minted"*"new-id.sh"* ]] \
        || { echo "$output"; false; }
}

@test "check-ids: --allow-draft-files tolerates a draft ledger filename" {
    printf '**PR-a3k9z2**: a real item.\nstatus: open\n' \
        > docs/problems/DRAFT-x-new.md
    commit_all draftfile

    run sh .guardrails/scripts/check-ids.sh --allow-draft-files
    [ "$status" -eq 0 ]
    [[ "$output" != *"DRAFT-FILE"* ]]
}

@test "check-ids: a draft ledger filename still fails without the flag" {
    printf '**PR-a3k9z2**: a real item.\nstatus: open\n' \
        > docs/problems/DRAFT-x-new.md
    commit_all draftfile

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"DRAFT-FILE"* ]]
}

@test "check-ids: --allow-drafts is gone, and is refused rather than ignored" {
    # A flag that silently does nothing is a gate the caller believes they
    # relaxed. Refuse it so the skills and any CI that still passes it break
    # loudly at the upgrade.
    run sh .guardrails/scripts/check-ids.sh --allow-drafts
    [ "$status" -eq 2 ]
}

@test "check-ids: --base is gone, and is refused rather than ignored" {
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
    [[ "$output" == *"DUPLICATE-ID REQ-a3k9z2"* ]]
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
    # Independent review, blocking finding 1. This scan suppressed stderr and
    # checked no status, three lines below a comment condemning exactly that,
    # and it is the only gate left that catches an ID defined twice — the
    # duplicate-vs-base half went with the sequential scheme.
    #
    # Fault injection rather than a poisoned pattern: a `git` earlier on PATH
    # that fails the one scan carrying -oE, which in this script is the
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

@test "check-ids: the MALFORMED-ID failure says what to run instead" {
    # Independent review, S13. DRAFT-ID's guidance is pinned by a test and by
    # mutation M24; MALFORMED-ID's was pinned by neither, and M42 dropped all
    # three of its guidance lines while reddening only the location assertion.
    printf '**REQ-abcdef**: a body that is not an ID.\n' \
        > docs/requirements/2026-01-01-x.md
    commit_all malformed

    run sh .guardrails/scripts/check-ids.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"the lines above open with a definition form"*"new-id.sh"* ]] \
        || { echo "$output"; false; }
}

@test "poisoning gr_def_re_loose changes the MALFORMED-ID verdict" {
    # Independent review, finding 5: narrowing gr_def_re_loose alone reddened
    # nothing, so check-ids.sh could drift back to a hand-spelled loose form
    # with the suite still green. The behavioural pin the constructor lacked.
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
    [[ "$output" == *"MALFORMED-ID"* ]]
}

@test "check-ids: a bold run containing asterisks is not a definition form" {
    printf '**REQ-a**b**: emphasis inside what is not an item header.\n' > docs/requirements/2026-01-01-x.md
    commit_all asterisk-in-body
    run sh .guardrails/scripts/check-ids.sh
    [[ "$output" != *"MALFORMED-ID"* ]]
}
