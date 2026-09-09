# `assesses:` and `DANGLING-FILE` — the derived gate reads a declaration, the rename carries its references

**Goal:** `UNANALYZED-DERIVED` passes a derived item only when an `assesses:`
annotation in the RMF names it, and `finalize-docs.sh` rewrites references to
the ledger files it renames while `check-trace.sh` convicts any draft
reference in a ledger that no longer resolves.
**Implements:** no REQ/SDD items exist in this repository. This is a defect
fix; it resolves PR-n274s7 and PR-58zsvf
(docs/problems/2026-09-08-assesses-and-dangling-file.md, written as this
change's draft ledger file and renamed by hand at merge, since the scripts do
not run against this repository).
**Safety class:** the toolkit itself is unclassified; it enforces class B/C
elsewhere.
**Verification:** `sh tests/run-tests.sh` (602 ok, 0 failures on e2eac86,
measured 2026-09-08 in the change worktree before any task began).

## Where the two items came from

A downstream guardrails project reported both on 2026-09-08, with
measurements, after fixing them locally against its vendored scripts. The
report is summarised in the problem-report file above. This plan is the
upstream resolution, and it departs from the report in three places, each
decided in the requirements interview of 2026-09-08:

- **D1 — hard cut.** The stricter `UNANALYZED-DERIVED` fails an unannotated
  derived item at the first run after upgrade. No transition token, no config
  knob. The ratchet upgrade notes announce it and the remedy row says exactly
  what to add. Reason: a warning-then-fail scheme puts a third state into a
  two-state gate and leaves an upgraded project green on the exact failure the
  change exists to detect. Cost is bounded by the count of derived items
  (26 items, 11 files, about an hour, measured downstream).
- **D2 — both halves of the rename fix.** The rewrite pass lands in
  `finalize-docs.sh` AND a `DANGLING-FILE` gate lands in `check-trace.sh`.
  The report offered the gate as optional. It is not: a reference held in
  another worktree (B links to A's draft; A merges and renames; B's link
  dangles on B's branch, where A's finalize never ran) and a reference in
  another unit's ledger (finalize runs once per touched unit under its own
  config) are unreachable by any rewrite. Only a gate at the referencing
  change's merge sees them.
- **D3 — the gate resolves over the rewrite's scope, not `strict_paths`.**
  The files where a draft reference must resolve are exactly the files the
  rewrite edits: the four ledger directories and the SOUP file. Plans and
  verification records narrate the rename ("created as `DRAFT-x.md`,
  finalized to `2026-09-04-x.md`"), which is why the rewrite is withheld
  there, and a gate over them would convict the sentences the rewrite
  deliberately left true. This repository has such a sentence today
  (docs/verification/2026-07-20-doc-ledgers.md:40). Resolve, never ban: a
  reference to a draft that EXISTS is the in-flight state of every unmerged
  change.

Two implementation constraints the report did not have:

- **D4 — an ambiguous basename is left for the gate.** Two drafts in
  different ledgers may share a basename (`docs/requirements/DRAFT-f-x.md`
  and `docs/risk/DRAFT-f-x.md` is the common shape) and diverge only when a
  same-day collision gives one of them a `-2` suffix. A path-shaped
  reference (`docs/risk/DRAFT-f-x.md`) rewrites exactly in every case. A bare
  basename rewrites only when every rename sharing that basename maps to the
  same new basename; otherwise it is reported as left, and `DANGLING-FILE`
  convicts it if it does not resolve.
- **D5 — `assesses:` is line-wise, like `mitigates:`.** It is read by
  `ids_matching` through the one-definition rule (`GR_AWK_ID_RUN`), found
  anywhere on the line, first occurrence, run ending at the first character
  that is not an ID, comma or space. It does NOT join the `ORPHAN-ANNOTATION`
  keyword list: an assessment is prose under a heading, not an item block, so
  a column-one `assesses:` belonging to no item is the normal case. It
  inherits the asymmetry lib.sh states for line-wise keywords, knowingly.

## What the change does not do

It does not judge an assessment's quality. It requires the author to declare
which derived items a passage assesses, the same standard every other
annotation here holds. The message text must not promise more.

## Tasks

Fan-out: T1 and T2 touch disjoint files and may run in parallel. T3 shares
`scripts/check-trace.sh` and `tests/check-trace.bats` with T1 and runs after
it. T4 edits documentation that names the final messages of T1–T3 and runs
after all three. T5 closes the problem reports and runs last.

### T1 — `UNANALYZED-DERIVED` reads `assesses:`

**Files touched:** scripts/check-trace.sh, tests/check-trace.bats
**Parallel:** yes (with T2)
**Trace IDs:** PR-n274s7

Step 1 — write the failing tests. Append to `tests/check-trace.bats`, before
the `poisoning GR_AWK_ITEM_BLOCK` test:

```bash
@test "check-trace: a derived REQ named only in passing in the RMF is unassessed" {
    # verifies: PR-n274s7 — the ID is what an author produces anyway; a scope
    # note naming it is a mention, not an assessment.
    printf '\n**REQ-002**: The software shall retry the bus handshake.\nsatisfies: derived\n' \
        >> docs/requirements/0001-01-01-base.md
    printf '# verifies: REQ-002\ntrue\n' > tests/test_b.sh
    printf '\n## Scope\n\nThis file covers REQ-001 and REQ-002.\n' >> docs/risk/0001-01-01-base.md
    commit_all derived-mention
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"UNANALYZED-DERIVED REQ-002"* ]] || { echo "$output"; false; }
}

@test "check-trace: a derived LLR named only in a verification-table row is unassessed" {
    # verifies: PR-n274s7
    printf '\n**LLR-002**: Debounce sensor input. satisfies: derived\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: LLR-002\ntrue\n' > tests/test_b.sh
    printf '\n| Item | Verified by |\n|---|---|\n| LLR-002 | tests/test_b.sh |\n' >> docs/risk/0001-01-01-base.md
    commit_all derived-table
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"UNANALYZED-DERIVED LLR-002"* ]] || { echo "$output"; false; }
}

@test "check-trace: an assesses: line accepts a derived REQ and a derived LLR" {
    # verifies: PR-n274s7 — the boundary from the other side: a later
    # tightening cannot pass by rejecting everything.
    printf '\n**REQ-002**: The software shall retry the bus handshake.\nsatisfies: derived\n' \
        >> docs/requirements/0001-01-01-base.md
    printf '\n**LLR-002**: Debounce sensor input. satisfies: derived\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: REQ-002, LLR-002\ntrue\n' > tests/test_b.sh
    printf '\n## Derived requirements assessment\n\nassesses: REQ-002, LLR-002\nNeither adds a hazard: the retry is bounded and the debounce is read-only.\n' \
        >> docs/risk/0001-01-01-base.md
    commit_all derived-assessed
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == "checked:"* ]] || { echo "$output"; false; }
}

@test "check-trace: an assesses: run for one item does not clear a second it mentions" {
    # verifies: PR-n274s7 — the run ends at the first character that is not
    # an ID, comma or space, so the parenthetical credits nothing.
    printf '\n**REQ-002**: The software shall retry the bus handshake.\nsatisfies: derived\n' \
        >> docs/requirements/0001-01-01-base.md
    printf '\n**LLR-002**: Debounce sensor input. satisfies: derived\n' >> docs/architecture/0001-01-01-base.md
    printf '# verifies: REQ-002, LLR-002\ntrue\n' > tests/test_b.sh
    printf '\nassesses: REQ-002 (LLR-002 is a separate concern)\n' >> docs/risk/0001-01-01-base.md
    commit_all derived-partial
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"UNANALYZED-DERIVED LLR-002"* ]] || { echo "$output"; false; }
    [[ "$output" != *"UNANALYZED-DERIVED REQ-002"* ]] || { echo "$output"; false; }
}

@test "check-trace: an assesses: line outside the RMF files counts for nothing" {
    # verifies: PR-n274s7
    printf '\n**REQ-002**: The software shall retry the bus handshake.\nsatisfies: derived\n' \
        >> docs/requirements/0001-01-01-base.md
    printf '# verifies: REQ-002\ntrue\n' > tests/test_b.sh
    printf '\nassesses: REQ-002\n' >> docs/architecture/0001-01-01-base.md
    commit_all derived-elsewhere
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"UNANALYZED-DERIVED REQ-002"* ]] || { echo "$output"; false; }
}
```

Step 2 — update the five existing fixtures that assess by bare mention. Each
is named by its test title; change only the `printf` into `docs/risk/…`:

| Test | Old RMF line | New RMF line |
|---|---|---|
| `derived LLR mentioned in RMF is not UNSATISFIED` | `Derived requirements assessment: LLR-002 introduces no new hazard.` | `assesses: LLR-002\nIntroduces no new hazard.` |
| `derived assessment in any rmf-directory file counts` | `Derived requirements assessment: LLR-002 no hazard impact.` | `assesses: LLR-002\nNo hazard impact.` |
| `a derived token analysed in the RMF is accepted` | `LLR-q7w4zb assessed: no new hazard.` | `assesses: LLR-q7w4zb\nNo new hazard.` |
| `longer-ID mention in RMF does not cover a derived LLR` | `LLR-0020 has no hazard impact.` | `assesses: LLR-0020\nNo hazard impact.` |
| `a derived token is not satisfied by a longer ID that starts with it` | `LLR-q7w4zbq assessed: a different item entirely.` | `assesses: LLR-q7w4zbq\nA different item entirely.` |

The last two stay red for the right reason only if the boundary is tested
against the new reader, which is why they gain the annotation too.

Step 3 — run and watch the five new tests fail:

```
$ tests/.bats-core/bin/bats tests/check-trace.bats -f 'assesses|unassessed'
not ok … a derived REQ named only in passing in the RMF is unassessed
not ok … a derived LLR named only in a verification-table row is unassessed
ok     … an assesses: line accepts a derived REQ and a derived LLR
not ok … an assesses: run for one item does not clear a second it mentions
not ok … an assesses: line outside the RMF files counts for nothing
```

The third passes against the old script because a mention is enough for it;
that is expected and is what the other four exist to prove.

Step 4 — replace the gate body in `scripts/check-trace.sh`. The
`derived_ids` collection stays exactly as it is; replace only the `for id in
$derived_ids` loop:

```sh
# The assessment is DECLARED, not inferred. Until 2026-09-08 this was one
# free-text `git grep` per derived ID over $rmf_files, so an ID in a
# verification table, a scope note or a parenthetical read as an assessment.
# The ID is exactly what an author produces anyway — a derived item is
# normally named in the same file's verification table — so the gate could
# not tell the failure it exists to detect from compliance. Measured on one
# downstream project: 26 derived items, 25 genuinely assessed, one credited
# on a parenthetical inside a blockquote (PR-n274s7).
#
# `assesses:` is read line-wise by ids_matching through GR_AWK_ID_RUN, like
# mitigates: and implements:. The run ends at the first character that is not
# an ID, comma or space, so an assessment of one item cannot clear a second
# it names in passing. It is NOT in the ORPHAN-ANNOTATION list: an assessment
# is prose under a heading, not an item block, and a column-one `assesses:`
# belonging to no item is the normal case.
#
# Nothing here judges the assessment. It requires the author to say which
# items a passage assesses — the standard every other annotation holds.
# shellcheck disable=SC2086
assessed="$(ids_matching 'assesses:' REQ $rmf_files)
$(ids_matching 'assesses:' LLR $rmf_files)"
for id in $derived_ids; do
    gr_contains "$assessed" "$id" && continue
    echo "UNANALYZED-DERIVED $id (no 'assesses:' line in the RMF names it)"
    fail=1
done
```

Step 5 — header comments in the same file. Line 15:

```
#   UNANALYZED-DERIVED ID    — REQ/LLR marked derived that no `assesses:`
#                              line in the RMF names
```

Line 77, the annotation rule: `for verifies:/mitigates:/implements:/satisfies:/traces:/assesses:,`.

Lines 445–448 (the MISPLACED-ITEM caveat about HAZ blocks): replace the
sentence beginning `UNANALYZED-DERIVED is a free-text grep` with
`UNANALYZED-DERIVED reads `assesses:` lines over $rmf_files, so a derived
item assessed inside a HAZ block stops being assessed when that block leaves.
It fails RED, so no false green — but the loss is real.`

Line 846 (the ORPHAN-ANNOTATION scope comment): add `assesses:` to the list
`mitigates:`, `implements:` and `verifies:` of keywords read line-wise and
therefore never orphaned.

Step 6 — run the full file, expect every test green:

```
$ tests/.bats-core/bin/bats tests/check-trace.bats
```

Commit: `git -c commit.gpgsign=false commit -am "check-trace: UNANALYZED-DERIVED reads an assesses: declaration, not a mention (PR-n274s7)"`.

**Done** — task branch 5d6d86f merged into the change branch as 34d629d on
2026-09-08. Dispatch report: check-trace.bats 220 passed, portability.bats
10 passed, 0 failed.

- red -> green: `a derived REQ named only in passing in the RMF is unassessed` — watched fail (old gate exited 0 with only the `checked:` line; the scope-note mention was credited) before the implementation existed
- red -> green: `a derived LLR named only in a verification-table row is unassessed` — watched fail (old gate exited 0; the table row was credited) before the implementation existed
- red -> green: `an assesses: run for one item does not clear a second it mentions` — watched fail (old gate exited 0; the parenthetical LLR-002 was credited) before the implementation existed
- boundary pins, green on the old script: `an assesses: line accepts a derived REQ and a derived LLR` (predicted), and `an assesses: line outside the RMF files counts for nothing` (NOT predicted — step 3 above listed it red; the old grep was already scoped to $rmf_files, so an ID only in the SAD was never credited. It pins the new reader's scope, which is the right reason to keep it)
- no other test, script, skill, template or README line pinned the old message text `derived item not assessed in the RMF`

### T2 — `finalize-docs.sh` rewrites references to the files it renames

**Files touched:** scripts/finalize-docs.sh, tests/finalize-docs.bats
**Parallel:** yes (with T1)
**Trace IDs:** PR-58zsvf

Step 1 — write the failing tests. Append to `tests/finalize-docs.bats`:

```bash
@test "finalize: a path reference to a renamed draft is rewritten in another ledger" {
    # verifies: PR-58zsvf
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    printf '\nHazards for this change: docs/requirements/DRAFT-feature-dose-limits.md.\n' >> docs/risk/README.md
    commit_all draft-and-ref
    today=$(date +%Y-%m-%d)
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q "docs/requirements/${today}-dose-limits.md" docs/risk/README.md
    ! grep -q 'DRAFT-feature-dose-limits' docs/risk/README.md
    [[ "$output" == *"rewrote docs/risk/README.md: docs/requirements/DRAFT-feature-dose-limits.md -> docs/requirements/${today}-dose-limits.md"* ]] \
        || { echo "$output"; false; }
}

@test "finalize: a bare basename reference is rewritten" {
    # verifies: PR-58zsvf
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    printf '\nSee DRAFT-feature-dose-limits.md.\n' >> docs/architecture/soup.md
    commit_all draft-and-bare-ref
    today=$(date +%Y-%m-%d)
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q "See ${today}-dose-limits.md\." docs/architecture/soup.md
    [[ "$output" == *"rewrote docs/architecture/soup.md: DRAFT-feature-dose-limits.md -> ${today}-dose-limits.md"* ]] \
        || { echo "$output"; false; }
}

@test "finalize: a draft referencing its sibling draft is rewritten after both are renamed" {
    # verifies: PR-58zsvf — the rewrite runs over the renamed files, so a
    # reference inside a draft to another draft of the same change resolves.
    printf '**REQ-a3k9z2**: draft requirement. See docs/risk/DRAFT-feature-dose-limits.md.\n' \
        > docs/requirements/DRAFT-feature-dose-limits.md
    printf '**HAZ-h7z4mn**: overdose.\n' > docs/risk/DRAFT-feature-dose-limits.md
    commit_all sibling-drafts
    today=$(date +%Y-%m-%d)
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q "See docs/risk/${today}-dose-limits.md\." "docs/requirements/${today}-dose-limits.md"
}

@test "finalize: --dry-run prints the rewrites it would make and writes nothing" {
    # verifies: PR-58zsvf
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    printf '\nSee DRAFT-feature-dose-limits.md.\n' >> docs/risk/README.md
    commit_all draft-dry
    today=$(date +%Y-%m-%d)
    run sh .guardrails/scripts/finalize-docs.sh --dry-run
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"would rewrite docs/risk/README.md: DRAFT-feature-dose-limits.md -> ${today}-dose-limits.md"* ]] \
        || { echo "$output"; false; }
    git diff --quiet
    [ -f docs/requirements/DRAFT-feature-dose-limits.md ]
}

@test "finalize: a reference to another change's draft is left alone" {
    # verifies: PR-58zsvf — a draft not in this tree belongs to a change still
    # in flight elsewhere; its name is not this run's to change.
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    printf '\nPending: DRAFT-other-alarms.md.\n' >> docs/risk/README.md
    commit_all draft-other
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q 'Pending: DRAFT-other-alarms.md.' docs/risk/README.md
}

@test "finalize: a plan narrating the rename is left exactly as written" {
    # verifies: PR-58zsvf — D3: a sentence about history has to stay true;
    # only a reference inside a ledger has to resolve.
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    mkdir -p docs/plans
    printf 'Created as DRAFT-feature-dose-limits.md; finalize renames it at merge.\n' > docs/plans/2026-01-01-x.md
    commit_all draft-plan
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q 'Created as DRAFT-feature-dose-limits.md; finalize renames it at merge.' docs/plans/2026-01-01-x.md
    [[ "$output" != *"docs/plans"* ]] || { echo "$output"; false; }
}

@test "finalize: an ambiguous bare basename is left for the gate, the path form still rewrites" {
    # verifies: PR-58zsvf — D4: two drafts share a basename and one takes a
    # collision suffix, so the bare name maps two ways and cannot be rewritten.
    today=$(date +%Y-%m-%d)
    printf '# merged earlier today\n' > "docs/risk/${today}-notes.md"
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-notes.md
    printf '**HAZ-h7z4mn**: overdose.\n' > docs/risk/DRAFT-feature-notes.md
    printf '\nPath: docs/risk/DRAFT-feature-notes.md. Bare: DRAFT-feature-notes.md.\n' >> docs/architecture/README.md
    commit_all ambiguous
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q "Path: docs/risk/${today}-notes-2.md\." docs/architecture/README.md
    grep -q 'Bare: DRAFT-feature-notes.md\.' docs/architecture/README.md
    [[ "$output" == *"left docs/architecture/README.md: DRAFT-feature-notes.md"* ]] || { echo "$output"; false; }
}

@test "finalize: a rewrite that fails aborts instead of reporting a clean finalize" {
    # verifies: PR-58zsvf — awk's no-occurrence exit and awk failing are
    # different answers; conflating them leaves a half-rewritten ledger
    # reported as success. Runs as a non-root user: root can write anywhere.
    [ "$(id -u)" -ne 0 ] || skip "root ignores directory permissions"
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-dose-limits.md
    printf '\nSee DRAFT-feature-dose-limits.md.\n' >> docs/architecture/README.md
    commit_all draft-ro
    chmod 555 docs/architecture
    run sh .guardrails/scripts/finalize-docs.sh
    chmod 755 docs/architecture
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"rewrite failed"* ]] || { echo "$output"; false; }
}

@test "finalize: the no-drafts case is still a silent no-op after the rewrite pass" {
    # verifies: PR-58zsvf
    printf '\nSee DRAFT-other-alarms.md.\n' >> docs/risk/README.md
    commit_all no-drafts-ref
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    git diff --quiet
}
```

Step 2 — watch them fail:

```
$ tests/.bats-core/bin/bats tests/finalize-docs.bats -f 'rewrit|reference|narrating|ambiguous|no-op after'
```

Expected: the first four and the ambiguous case fail (nothing is rewritten,
nothing is printed); `another change's draft`, `plan narrating` and
`no-drafts` pass on the old script, which is correct — they pin the boundary.

Step 3 — implement. In `scripts/finalize-docs.sh`:

(a) Add a helper after `gr_check_config` and the doc-key validation loop:

```sh
# rewrite_file FILE OLD NEW — replace every literal occurrence of OLD in FILE
# by NEW. Exit 0 when something was rewritten, 3 when OLD does not occur,
# 2 on any failure. Three answers, because two of them look alike from the
# outside and mean opposite things: "nothing to do" and "could not do it".
#
# Literal, via index/substr, never sed: OLD is a file name, and the `.` in
# `DRAFT-x.md` is a metacharacter that would match any character. The values
# travel through ENVIRON rather than -v: awk -v processes escape sequences in
# its value, and a file name is not an awk string literal.
rewrite_file() {
    _rf="$1"
    GR_OLD="$2" GR_NEW="$3" awk '
        BEGIN { old = ENVIRON["GR_OLD"]; new = ENVIRON["GR_NEW"]; n = 0 }
        {
            line = $0
            out = ""
            while ((p = index(line, old)) > 0) {
                out = out substr(line, 1, p - 1) new
                line = substr(line, p + length(old))
                n++
            }
            print out line
        }
        END { exit (n > 0) ? 0 : 3 }
    ' "$_rf" > "$_rf.gr-rewrite"
    _st=$?
    case $_st in
        (0) mv "$_rf.gr-rewrite" "$_rf" || return 2 ;;
        (3) rm -f "$_rf.gr-rewrite" ;;
        (*) rm -f "$_rf.gr-rewrite"; return 2 ;;
    esac
    return $_st
}

# rewrite_refs OLD NEW — rewrite OLD to NEW in every file of the rewrite
# scope that contains it, printing one line per file. In dry-run mode it
# prints what it would do and touches nothing.
rewrite_refs() {
    _old="$1"
    _new="$2"
    # shellcheck disable=SC2086
    _hits=$(git grep -l --untracked -F -- "$_old" $rewrite_scope 2>/dev/null)
    for _h in $_hits; do
        [ -n "$_h" ] || continue
        if [ "$dry" -eq 1 ]; then
            echo "would rewrite $_h: $_old -> $_new"
            continue
        fi
        rewrite_file "$_h" "$_old" "$_new"
        case $? in
            (0) echo "rewrote $_h: $_old -> $_new" ;;
            (3) ;;
            (*) gr_die "rewrite failed: $_h ($_old -> $_new)" ;;
        esac
    done
}
```

(b) After the `[ -n "$renames" ] || exit 0` line, before the print loop,
compute the scope and the ambiguity set:

```sh
# --- The rewrite pass -------------------------------------------------------
# The script knows both names of every file it renames, so leaving the
# references behind was a second pass it never made (PR-58zsvf). Downstream,
# 13 dangling links over 9 filenames grew to 25 over 16 in eighteen days, by
# construction rather than by mistake.
#
# Scope is the ledger directories and the SOUP file — the files whose
# references have to RESOLVE — and deliberately not the whole tree. Plans and
# verification records narrate the rename ("created as DRAFT-x.md, finalized
# to 2026-09-04-x.md"), and rewriting those sentences turns a true statement
# into a false one. check-trace.sh's DANGLING-FILE reads the same scope, so
# what this pass cannot reach (a reference held in another worktree, or in
# another unit's ledger) is convicted at that change's own merge.
#
# Every rewrite is printed. A rename is mechanical; a rewrite edits prose
# somebody else wrote.
rewrite_scope=""
for _key in doc_srs doc_rmf doc_sad doc_problems doc_soup; do
    _fs=$(gr_doc_files "$_key") || exit 2
    [ -n "$_fs" ] && rewrite_scope="${rewrite_scope}${rewrite_scope:+
}$_fs"
done
# A bare basename maps two ways when two drafts share it and a same-day
# collision suffixes one of them. Only the path-shaped reference can be
# rewritten then; the bare one is reported as left, and DANGLING-FILE
# convicts it if it does not resolve.
ambiguous=$(printf '%s' "$renames" | awk '
    NF == 2 {
        o = $1; sub(/.*\//, "", o)
        t = $2; sub(/.*\//, "", t)
        if (o in seen && seen[o] != t) amb[o] = 1
        seen[o] = t
    }
    END { for (o in amb) print o }')
```

Note the scope is computed BEFORE the renames when dry-running (the drafts
are still there and are legitimately in scope) and must be computed AGAIN
after the renames in the real run, because the renamed files are new paths
that `git grep` must see. That is why step (c) recomputes it.

(c) After the real rename loop (the one that `git mv`s), before `exit 0`:

```sh
# Recompute: the renamed files are the ones most likely to hold a sibling
# reference, and they did not exist under these names a moment ago.
rewrite_scope=""
for _key in doc_srs doc_rmf doc_sad doc_problems doc_soup; do
    _fs=$(gr_doc_files "$_key") || exit 2
    [ -n "$_fs" ] && rewrite_scope="${rewrite_scope}${rewrite_scope:+
}$_fs"
done
run_rewrites
```

and, after the dry-run print loop, before `[ "$dry" -eq 1 ] && exit 0`:

```sh
[ "$dry" -eq 1 ] && run_rewrites
```

with `run_rewrites` defined beside the other helpers:

```sh
# Path-shaped references first, for every pair; bare basenames second, for
# the unambiguous pairs only. The path pass consumes the path form, so the
# bare pass cannot touch it twice.
run_rewrites() {
    for line in $renames; do
        [ -n "$line" ] || continue
        rewrite_refs "${line%% *}" "${line#* }"
    done
    for line in $renames; do
        [ -n "$line" ] || continue
        _ob=${line%% *}; _ob=${_ob##*/}
        _nb=${line#* };  _nb=${_nb##*/}
        if gr_contains "$ambiguous" "$_ob"; then
            # shellcheck disable=SC2086
            for _h in $(git grep -l --untracked -F -- "$_ob" $rewrite_scope 2>/dev/null); do
                echo "left $_h: $_ob (two renames share this name; a bare reference cannot be resolved — write the path)"
            done
            continue
        fi
        rewrite_refs "$_ob" "$_nb"
    done
}
```

Careful with two things the existing script already teaches: the loops are
plain `for`, never `printf | while`, so `gr_die` exits the script; and the
`renames` record is `"source target"` split with `${x%% *}`, safe because a
whitespace-bearing draft name was rejected during planning. The `git mv`
staged the rename; the rewrite leaves the content modified in the working
tree, which `merge-change` step 3's `git add -A` picks up as it does today.

Header comment: add after the "Prints one before -> after line per rename"
sentence: `Then rewrites every reference to a renamed file across the ledger
directories and the SOUP file, printing one "rewrote FILE: old -> new" line
each (and "would rewrite" under --dry-run). Plans and verification records
are never touched: they narrate the rename, and a true sentence about history
must stay true.`

Step 4 — run the file, all green:

```
$ tests/.bats-core/bin/bats tests/finalize-docs.bats
```

Also `tests/.bats-core/bin/bats tests/portability.bats`: the new awk takes
no `-v` at all, so the strict-awk stub has nothing to refuse, and there is no
`sed -i` here.

Commit: `git -c commit.gpgsign=false commit -am "finalize-docs: rewrite references to the files it renames, print each, leave history alone (PR-58zsvf)"`.

**Done** — task branch a2ef370 merged into the change branch as 1ecc8ba on
2026-09-08. Dispatch report: finalize-docs.bats 24 passed, portability.bats
10 passed, check-ids.bats 44 passed, 0 failed.

- red -> green: `a path reference to a renamed draft is rewritten in another ledger` — watched fail (grep for the dated name in docs/risk/README.md failed; nothing rewritten) before the implementation existed
- red -> green: `a bare basename reference is rewritten` — watched fail (soup.md still held the DRAFT name) before the implementation existed
- red -> green: `a draft referencing its sibling draft is rewritten after both are renamed` — watched fail (renamed file still referenced docs/risk/DRAFT-…) before the implementation existed
- red -> green: `--dry-run prints the rewrites it would make and writes nothing` — watched fail (output held only the rename line) before the implementation existed
- red -> green: `an ambiguous bare basename is left for the gate, the path form still rewrites` — watched fail (path form not rewritten to the -2 name) before the implementation existed
- red -> green: `a rewrite that fails aborts instead of reporting a clean finalize` — watched fail (exit 0, no rewrite pass existed to abort) before the implementation existed; the plan had predicted this one green on the old script and was wrong about that, in the safe direction
- boundary pins, green on the old script as predicted: `a reference to another change's draft is left alone`, `a plan narrating the rename is left exactly as written`, `the no-drafts case is still a silent no-op after the rewrite pass`

### T3 — `DANGLING-FILE` in `check-trace.sh`

**Files touched:** scripts/check-trace.sh, tests/check-trace.bats
**Parallel:** no (serial, after T1)
**Trace IDs:** PR-58zsvf

Step 1 — failing tests, appended to `tests/check-trace.bats` after T1's:

```bash
@test "check-trace: a ledger reference to a draft file that does not exist is DANGLING-FILE" {
    # verifies: PR-58zsvf — the case finalize's rewrite cannot reach: the
    # draft was renamed by another change's merge, or lives in another unit.
    printf '\nHazards: docs/risk/DRAFT-other-alarms.md.\n' >> docs/requirements/0001-01-01-base.md
    commit_all dangling-file
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"DANGLING-FILE docs/risk/DRAFT-other-alarms.md (docs/requirements/0001-01-01-base.md:"* ]] \
        || { echo "$output"; false; }
}

@test "check-trace: a reference to a draft file that exists is the in-flight state and passes" {
    # verifies: PR-58zsvf — resolve, never ban: convicting an existing draft
    # would fire on every worktree doing this correctly.
    printf '# Draft hazards\n' > docs/risk/DRAFT-feature-alarms.md
    printf '\nHazards: docs/risk/DRAFT-feature-alarms.md, also DRAFT-feature-alarms.md.\n' \
        >> docs/requirements/0001-01-01-base.md
    commit_all in-flight
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"DANGLING-FILE"* ]] || { echo "$output"; false; }
}

@test "check-trace: a bare draft basename resolves against every ledger directory" {
    # verifies: PR-58zsvf
    printf '# Draft hazards\n' > docs/risk/DRAFT-feature-alarms.md
    printf '\nSee DRAFT-feature-alarms.md.\n' >> docs/architecture/0001-01-01-base.md
    commit_all bare-resolves
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"DANGLING-FILE"* ]] || { echo "$output"; false; }
}

@test "check-trace: a dangling draft reference outside the ledgers is prose" {
    # verifies: PR-58zsvf — D3: strict_paths and plans narrate history and
    # are not resolved; the scope is exactly the files finalize rewrites.
    printf 'Created as DRAFT-feature-x.md, finalized at merge.\n' > src/NOTES.md
    commit_all prose-ref
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"DANGLING-FILE"* ]] || { echo "$output"; false; }
}

@test "check-trace: the grammar placeholder DRAFT-<branch>-<slug>.md is not a reference" {
    # verifies: PR-58zsvf — the ledger READMEs shipped by ratchet carry it.
    printf '\nfrom your worktree DRAFT-<branch>-<slug>.md, renamed at merge\n' >> docs/risk/0001-01-01-base.md
    commit_all placeholder
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"DANGLING-FILE"* ]] || { echo "$output"; false; }
}
```

Step 2 — watch the first fail (`status 0`, no DANGLING-FILE) and the other
four pass, which pins the boundary before the gate exists.

Step 3 — implement, after the DANGLING-REF block and before the problem-report
triage:

```sh
# --- DANGLING-FILE: a draft ledger file named in a ledger must exist --------
# finalize-docs.sh rewrites references to the files it renames, over exactly
# these files. What it cannot reach is convicted here: a reference held in
# another worktree when the draft's own change merged and renamed it, or a
# reference in another unit's ledger, which that unit's finalize never
# scanned. Resolve, never ban — a reference to a draft that EXISTS is the
# in-flight state of every unmerged change, and a gate on the prefix alone
# would fire on every worktree doing this correctly.
#
# Scope is the rewrite's scope and not strict_paths (D3, 2026-09-08): plans
# and verification records narrate the rename, and "created as DRAFT-x.md"
# is a true sentence that must stay true. The token must look like a real
# file name, so the grammar placeholder `DRAFT-<branch>-<slug>.md` in the
# shipped ledger READMEs matches nothing. A path-shaped reference resolves
# from the repository root; a bare basename resolves against every ledger
# directory, because a bare name is how authors cite a sibling ledger.
file_scope=""
for f in $srs_files $rmf_files $sad_files $soup_files $problems_files; do
    [ -n "$f" ] && file_scope="${file_scope}${file_scope:+
}$f"
done
doc_dirs=""
for _key in doc_srs doc_rmf doc_sad doc_problems; do
    _d=$(cfg_get "$_key")
    [ -n "$_d" ] && [ -d "$_d" ] && doc_dirs="${doc_dirs}${doc_dirs:+
}$_d"
done
if [ -n "$file_scope" ]; then
    # shellcheck disable=SC2086
    _drefs=$(git grep -n --untracked -oE '[A-Za-z0-9_./-]*DRAFT-[A-Za-z0-9_.-]+\.md' -- $file_scope)
    _st=$?
    [ "$_st" -le 1 ] || gr_die "draft reference scan failed (git grep exit $_st)"
    for _dr in $_drefs; do
        [ -n "$_dr" ] || continue
        _dfile=${_dr%%:*}
        _drest=${_dr#*:}
        _dline=${_drest%%:*}
        _dref=${_drest#*:}
        case "$_dref" in
            (*/*) [ -e "$_dref" ] && continue ;;
            (*)
                _found=0
                for _d in $doc_dirs; do
                    [ -e "$_d/$_dref" ] && { _found=1; break; }
                done
                [ "$_found" -eq 1 ] && continue ;;
        esac
        echo "DANGLING-FILE $_dref ($_dfile:$_dline names a draft ledger file that does not exist — after a merge, write the dated name)"
        fail=1
    done
fi
```

`set -f` is on, so `$file_scope` reaches `git grep` verbatim and `$doc_dirs`
splits on newlines only. Header comment, line 16 region:

```
#   DANGLING-FILE FILE       — a `DRAFT-*.md` ledger file named in a doc_*
#                              file (path or bare name) that does not exist
```

Step 4 — the whole file green, then commit:
`git -c commit.gpgsign=false commit -am "check-trace: DANGLING-FILE resolves draft references over the rewrite's scope (PR-58zsvf)"`.

**Done** — task branch c8e07c0 merged into the change branch as 57aa107 on
2026-09-08. Dispatch report: check-trace.bats 225 passed, portability.bats
10 passed, check-units.bats 32 passed, 0 failed. No surprises; the red/green
split matched step 2 exactly.

- red -> green: `a ledger reference to a draft file that does not exist is DANGLING-FILE` — watched fail (exit 0 with only the summary lines; nothing convicted docs/risk/DRAFT-other-alarms.md) before the implementation existed
- boundary pins, green on the old script as predicted and green after: `a reference to a draft file that exists is the in-flight state and passes`, `a bare draft basename resolves against every ledger directory`, `a dangling draft reference outside the ledgers is prose`, `the grammar placeholder DRAFT-<branch>-<slug>.md is not a reference`

### T4 — documentation sweep and skill tests

**Files touched:** README.md, templates/rmf.md, templates/srs.md, templates/sad.md, templates/AGENTS-block.md, skills/analyze-risks/SKILL.md, skills/check-traceability/SKILL.md, skills/grill-requirements/SKILL.md, skills/merge-change/SKILL.md, skills/ratchet/SKILL.md, tests/skills.bats
**Parallel:** no (serial, after T1–T3)
**Trace IDs:** PR-n274s7, PR-58zsvf

Step 1 — failing skill tests, appended to `tests/skills.bats`:

```bash
@test "assesses-is-the-remedy: every place that tells an author how to assess names the annotation" {
    # verifies: PR-n274s7 — D1: hard cut, so the remedy must be stated where
    # the author reads, not only in the gate's message.
    root="$BATS_TEST_DIRNAME/.."
    grep -q 'assesses:' "$root/skills/check-traceability/SKILL.md"
    grep -q 'assesses:' "$root/skills/analyze-risks/SKILL.md"
    grep -q 'assesses:' "$root/skills/grill-requirements/SKILL.md"
    grep -q 'assesses:' "$root/templates/rmf.md"
    grep -q 'assesses:' "$root/templates/srs.md"
    grep -q 'assesses:' "$root/templates/sad.md"
    grep -q 'assesses:' "$root/templates/AGENTS-block.md"
    grep -q 'assesses:' "$root/README.md"
    ! grep -q 'never mentioned in the RMF' "$root/skills/check-traceability/SKILL.md"
    ! grep -q 'RMF never mentions' "$root/skills/analyze-risks/SKILL.md"
    ! grep -q 'the RMF must mention it' "$root/skills/grill-requirements/SKILL.md"
}

@test "upgrade-notes-announce-the-hard-cut: ratchet says derived assessments go red at upgrade" {
    # verifies: PR-n274s7 — D1
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'Derived assessments are now declared' "$skill"
    grep -q 'DANGLING-FILE' "$skill"
}

@test "merge-step-3-reports-rewrites: merge-change expects finalize to print what it rewrote" {
    # verifies: PR-58zsvf — D2
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'rewrote' "$skill"
    grep -q 'DANGLING-FILE' "$BATS_TEST_DIRNAME/../skills/check-traceability/SKILL.md"
    grep -q 'DANGLING-FILE' "$BATS_TEST_DIRNAME/../README.md"
}
```

Step 2 — the edits, each an exact replacement:

- **README.md** line 96 (LLR row): `(or `satisfies: derived` — an `assesses:` line in the RMF must then name it)`.
  Line 130 (check-trace row): `derived items assessed in RMF` → `derived items named by an `assesses:` line in the RMF; no dangling refs, and no `DANGLING-FILE` (a `DRAFT-*.md` ledger file named in a ledger that does not exist)`.
  Line 135 (finalize row): append `, then rewrites every reference to a renamed file across the ledger directories and the SOUP file and prints each; plans and verification records are left alone because they narrate the rename`.
  Line 138: `verifies:`/`mitigates:`/`implements:`/`satisfies:`/`traces:`/`assesses:`.
  Lines 314–316: replace `yet moving it out of the RMF still blinds `UNANALYZED-DERIVED`, which greps the RMF as free text.` with `yet moving it out of the RMF still blinds `UNANALYZED-DERIVED`, which reads `assesses:` lines in the RMF files alone.`
- **templates/rmf.md** lines 21–23: `- Derived REQ/LLR assessments live here too. Write the assessment under a heading and declare which items it covers on a line of its own: `assesses: REQ-…, LLR-…`. "No hazard impact because <reason>" is a valid assessment; an ID in a table or a passing sentence is not, and check-trace reports the item as UNANALYZED-DERIVED.`
- **templates/srs.md** lines 19–20: `…is marked `satisfies: derived` and must be assessed in the risk ledger, where an `assesses:` line names it.`
- **templates/sad.md** lines 22–23: same sentence for derived LLRs.
- **templates/AGENTS-block.md** lines 42–43: `…must be assessed in the risk management file, on a passage carrying `assesses: <ID>` (UNANALYZED-DERIVED otherwise).`
- **skills/analyze-risks/SKILL.md** lines 59–62: `Record the assessment in the RMF under "Derived requirements assessment", and declare the items it covers on a line of its own — `assesses: REQ-…, LLR-…`. `check-trace.sh` fails UNANALYZED-DERIVED on any derived item no `assesses:` line names; the ID appearing in a table or a sentence does not count, because that is exactly what an author produces without assessing anything. "No hazard impact because <reason>" is a valid assessment; silence is not.`
- **skills/check-traceability/SKILL.md** row 150: `| `UNANALYZED-DERIVED <ID>` | Derived REQ/LLR that no `assesses:` line in the RMF names. A mention — the ID in a verification table, a scope note, a parenthetical — is not an assessment and does not count | Run `analyze-risks`: assess hazard impact under the RMF's derived-requirements heading and put `assesses: <ID>` on its own line in that passage. Several items may share one line. |`
  Row 155: replace `which greps the RMF as free text — a derived item assessed inside a hazard's block stops being assessed when that block leaves` with `which reads `assesses:` lines in the RMF files alone — an assessment inside a hazard's block stops counting when that block leaves`.
  New row after `DANGLING-REF`: `| `DANGLING-FILE <file>` | A `DRAFT-*.md` ledger file named in a ledger (or the SOUP file) — by path or bare name — that does not exist. Usually a draft another change already merged and renamed, or a draft in another unit; `finalize-docs.sh` rewrites the references it can see, and this is the rest. Plans and verification records are not scanned: they narrate the rename | Write the merged file's dated name. Never delete the reference to satisfy the gate — the sentence points somewhere for a reason. A reference to a draft that exists is fine: that is every change in flight. |`
- **skills/grill-requirements/SKILL.md** line 75: `for assessment (an `assesses:` line in the RMF must name it; `check-trace.sh` enforces this as UNANALYZED-DERIVED).`
- **skills/merge-change/SKILL.md** step 3: after `This renames any … to `<merge-date>-<slug>.md`.` add: `It then rewrites every reference to a renamed file across the ledger directories and the SOUP file and prints one `rewrote FILE: old -> new` line each; read those lines — a rewrite edits prose somebody else wrote. A `left FILE: …` line means two drafts shared a bare name and the reference must be written as a path by hand. Plans and verification records are never rewritten.`
- **skills/ratchet/SKILL.md**: after the numbered list under `> **Problem reports are now triaged…**`, add two quoted paragraphs:

```
> **Derived assessments are now declared, and this DOES touch the existing
> ledger.** `UNANALYZED-DERIVED` no longer passes a derived REQ/LLR whose ID
> merely appears in the RMF; it requires a line carrying `assesses: <IDs>`
> in the RMF files. Every derived item goes red at the first run after the
> upgrade until the passage that assesses it carries the annotation. The cost
> is bounded by the count of derived items — one project measured 26 items
> across 11 risk files in about an hour, several assessments covering a group
> — and the gate's line names the remedy. Put `assesses:` on the assessment,
> never on a table row or a passing mention: that is the failure the change
> exists to detect, and one of those 26 was exactly that.
>
> **`finalize-docs.sh` now rewrites references to the files it renames**,
> across the ledger directories and the SOUP file, printing each rewrite, and
> `check-trace.sh` reports `DANGLING-FILE` for a `DRAFT-*.md` reference in
> those files that names no existing file. Links left dangling by earlier
> merges go red at the first run; fix each by writing the merged file's dated
> name. Plans and verification records are neither rewritten nor scanned.
```

Step 3 — `tests/.bats-core/bin/bats tests/skills.bats` green. Commit:
`git -c commit.gpgsign=false commit -am "docs: assesses: and DANGLING-FILE reach every place an author reads"`.

**Done** — task branch 8df65c5 merged into the change branch as d8bd17c on
2026-09-08. Dispatch report: skills.bats 43 passed, check-trace.bats 225
passed, 0 failed.

- red -> green: `assesses-is-the-remedy` — watched fail (`assesses:` absent from skills/check-traceability/SKILL.md) before the edits existed
- red -> green: `upgrade-notes-announce-the-hard-cut` — watched fail (`Derived assessments are now declared` absent from skills/ratchet/SKILL.md) before the edits existed
- red -> green: `merge-step-3-reports-rewrites` — watched fail (`rewrote` absent from skills/merge-change/SKILL.md) before the edits existed
- departures from the plan text, all deliberate: the README finalize row's new clause was placed after "merge-dated names" rather than after the historical `finalize-ids.sh` sentence, which would have read as if the old script did the rewriting; README.md has no line-wise keyword list in its ORPHAN-ANNOTATION paragraph, so nothing was added there, while the check-traceability row 156 gained `assesses:`; every line number in the plan had drifted and each edit was anchored on the quoted sentence

### T5 — resolve the two problem reports

**Files touched:** docs/problems/DRAFT-assesses-dangling-file-assesses-and-dangling-file.md
**Parallel:** no (serial, last)
**Trace IDs:** PR-n274s7, PR-58zsvf

Flip both items to `status: resolved` and replace each item's trailing
paragraph with a resolution line:

- PR-n274s7: `Root cause: one free-text git grep per derived ID over the RMF files, satisfied by any occurrence. Fixed by reading an `assesses:` annotation through the one-definition rule, like mitigates:, as a hard cut announced in the ratchet notes. Reproduced by `check-trace: a derived REQ named only in passing in the RMF is unassessed` and `…named only in a verification-table row is unassessed` (tests/check-trace.bats), watched failing against the old gate.`
- PR-58zsvf: `Root cause: the rename loop was the whole script; the mapping it held was discarded. Fixed twice over: finalize-docs.sh rewrites path and unambiguous bare references across the ledger directories and the SOUP file, printing each, and check-trace.sh's DANGLING-FILE resolves any draft reference left in that scope. Reproduced by `finalize: a path reference to a renamed draft is rewritten in another ledger` (tests/finalize-docs.bats) and `check-trace: a ledger reference to a draft file that does not exist is DANGLING-FILE` (tests/check-trace.bats), both watched failing first.`

Commit: `git -c commit.gpgsign=false commit -am "problems: PR-n274s7 and PR-58zsvf resolved by this change"`.

**Done** — task branch d776f24 merged into the change branch as bad3b13 on
2026-09-08. Ledger edit, no test; the task worktree's full run was 621
passed, 0 failed. The four cited test names were confirmed verbatim against
the test files before being written into the ledger.

### T6 — review round 1 fixes (findings 1–6 and 8)

**Files touched:** scripts/finalize-docs.sh, scripts/check-trace.sh, README.md, tests/finalize-docs.bats, tests/check-trace.bats, tests/skills.bats
**Parallel:** no (serial, after the round-1 review)
**Trace IDs:** PR-58zsvf

The independent review (merge-change 6a, 2026-09-08) approved with one
IMPORTANT and seven MINOR findings. Finding 7 (fenced code blocks and HTML
comments are read as live text by the gate and the rewrite alike) is accepted
without change: no gate in this toolkit parses fences, every ledger template
says so, and gate and rewrite agree, so no dangling reference is manufactured.
The rest are fixed here.

Step 1 — failing tests. Append to `tests/finalize-docs.bats`:

```bash
@test "finalize: a path to another file that shares the draft's basename is not rewritten" {
    # verifies: PR-58zsvf — review finding 1. The bare pass must not rewrite the
    # tail of a path to a DIFFERENT file; it would manufacture a dangling
    # dated name that DANGLING-FILE cannot see.
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-x.md
    mkdir -p docs/other
    printf '# not a ledger, not renamed\n' > docs/other/DRAFT-feature-x.md
    printf '\nForeign: docs/other/DRAFT-feature-x.md. Ours: DRAFT-feature-x.md.\n' >> docs/risk/README.md
    commit_all foreign-basename
    today=$(date +%Y-%m-%d)
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q 'Foreign: docs/other/DRAFT-feature-x.md\.' docs/risk/README.md
    grep -q "Ours: ${today}-x.md\." docs/risk/README.md
    [ -f docs/other/DRAFT-feature-x.md ]
}

@test "finalize: --dry-run previews exactly the rewrites the real run makes" {
    # verifies: PR-58zsvf — review finding 2. A file holding only the path form
    # is one rewrite, not two, in both modes.
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-x.md
    printf '\nSee docs/requirements/DRAFT-feature-x.md.\n' >> docs/risk/README.md
    commit_all dry-exact
    run sh .guardrails/scripts/finalize-docs.sh --dry-run
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$(printf '%s\n' "$output" | grep -c 'would rewrite docs/risk/README.md')" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" != *"left "* ]] || { echo "$output"; false; }
    git diff --quiet
}

@test "finalize: an ambiguous basename is reported left once per file, and only where a bare form stands" {
    # verifies: PR-58zsvf — review finding 3.
    today=$(date +%Y-%m-%d)
    printf '# merged earlier today\n' > "docs/risk/${today}-notes.md"
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-notes.md
    printf '**HAZ-h7z4mn**: overdose.\n' > docs/risk/DRAFT-feature-notes.md
    printf '\nBoth: docs/risk/DRAFT-feature-notes.md and DRAFT-feature-notes.md.\n' >> docs/architecture/README.md
    printf '\nPath only: docs/requirements/DRAFT-feature-notes.md.\n' >> docs/architecture/soup.md
    commit_all left-once
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$(printf '%s\n' "$output" | grep -c '^left docs/architecture/README.md:')" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" != *"left docs/architecture/soup.md"* ]] || { echo "$output"; false; }
    grep -q "Path only: docs/requirements/${today}-notes.md\." docs/architecture/soup.md
}
```

Append to `tests/check-trace.bats`:

```bash
@test "check-trace: a relative link to a draft that exists resolves from the referencing file" {
    # verifies: PR-58zsvf — review finding 4: the one link form a markdown
    # renderer follows must not be convicted while the file is there.
    printf '# Draft hazards\n' > docs/risk/DRAFT-feature-a.md
    printf '\nSee [hazards](../risk/DRAFT-feature-a.md).\n' >> docs/requirements/0001-01-01-base.md
    commit_all relative-link
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"DANGLING-FILE"* ]] || { echo "$output"; false; }
}
```

In `tests/skills.bats`, extend `merge-step-3-reports-rewrites` with one
assertion for finding 8: `grep -q 'reported as left' "$BATS_TEST_DIRNAME/../README.md"`.

Step 2 — watch all four new tests and the extended skills test fail on the
current tree (finding 1: `Foreign:` line rewritten; finding 2: two
`would rewrite` lines; finding 3: two identical `left` lines plus one for
soup.md; finding 4: `DANGLING-FILE ../risk/DRAFT-feature-a.md`; finding 8:
string absent).

Step 3 — `scripts/finalize-docs.sh`. Replace `rewrite_file`, `rewrite_refs`
and `run_rewrites` with:

```sh
# rewrite_file FILE OLD NEW BARE PROBE — replace every literal occurrence of
# OLD in FILE by NEW. Exit 0 when something was (or, under --dry-run or
# PROBE=1, would be) rewritten, 3 when nothing qualifies, 2 on any failure.
# Three answers, because two of them look alike from the outside and mean
# opposite things: "nothing to do" and "could not do it".
#
# BARE=1 is the bare-basename pass: an occurrence preceded by "/" is the tail
# of a path to some OTHER file that happens to share the basename — a sibling
# unit's draft under the same branch name is the realistic shape — and is not
# this rename's to change (review finding 1). Under --dry-run the path pass
# has consumed nothing, so this same rule is what keeps the preview equal to
# the real run (finding 2).
#
# Literal, via index/substr, never sed: OLD is a file name, and the `.` in
# `DRAFT-x.md` is a metacharacter that would match any character. The values
# travel through ENVIRON rather than -v: awk -v processes escape sequences in
# its value, and a file name is not an awk string literal.
rewrite_file() {
    _rf="$1"
    _write=1
    [ "$dry" -eq 1 ] && _write=0
    [ "${5:-0}" -eq 1 ] && _write=0
    if [ "$_write" -eq 1 ]; then _tmp="$_rf.gr-rewrite"; else _tmp=/dev/null; fi
    GR_OLD="$2" GR_NEW="$3" GR_BARE="${4:-0}" GR_WRITE="$_write" awk '
        BEGIN {
            old = ENVIRON["GR_OLD"]; new = ENVIRON["GR_NEW"]
            bare = (ENVIRON["GR_BARE"] == "1"); write = (ENVIRON["GR_WRITE"] == "1")
            n = 0
        }
        {
            line = $0
            out = ""
            while ((p = index(line, old)) > 0) {
                if (bare && p > 1 && substr(line, p - 1, 1) == "/") {
                    out = out substr(line, 1, p + length(old) - 1)
                    line = substr(line, p + length(old))
                    continue
                }
                out = out substr(line, 1, p - 1) new
                line = substr(line, p + length(old))
                n++
            }
            if (write) print out line
        }
        END { exit (n > 0) ? 0 : 3 }
    ' "$_rf" > "$_tmp"
    _st=$?
    if [ "$_write" -eq 1 ]; then
        case $_st in
            (0) mv "$_tmp" "$_rf" || return 2 ;;
            (3) rm -f "$_tmp" ;;
            (*) rm -f "$_tmp"; return 2 ;;
        esac
    fi
    case $_st in
        (0 | 3) return $_st ;;
        (*) return 2 ;;
    esac
}

# scan_refs NEEDLE — the files of the rewrite scope containing NEEDLE, one per
# line. A failed scan is fatal, not "no occurrences" (review finding 6):
# check-trace.sh treats its own reference scan the same way.
scan_refs() {
    # shellcheck disable=SC2086
    _found=$(git grep -l --untracked -F -- "$1" $rewrite_scope)
    _gst=$?
    [ "$_gst" -le 1 ] || gr_die "reference scan failed (git grep exit $_gst)"
    printf '%s\n' "$_found"
}

# rewrite_refs OLD NEW BARE — rewrite OLD to NEW in every file of the rewrite
# scope that contains it, printing one line per file. Under --dry-run it
# prints what it would do and touches nothing.
rewrite_refs() {
    _old="$1"
    _new="$2"
    _bare="${3:-0}"
    _hits=$(scan_refs "$_old") || exit 2
    for _h in $_hits; do
        [ -n "$_h" ] || continue
        rewrite_file "$_h" "$_old" "$_new" "$_bare" 0
        case $? in
            (0) if [ "$dry" -eq 1 ]; then
                    echo "would rewrite $_h: $_old -> $_new"
                else
                    echo "rewrote $_h: $_old -> $_new"
                fi ;;
            (3) ;;
            (*) gr_die "rewrite failed: $_h ($_old -> $_new)" ;;
        esac
    done
}

# Path-shaped references first, for every pair; bare basenames second, for
# the unambiguous pairs only; then one `left` line per FILE that still holds a
# bare form of an ambiguous name (finding 3) — a file holding only the path
# form was rewritten by the first pass and has nothing left in it.
run_rewrites() {
    for line in $renames; do
        [ -n "$line" ] || continue
        rewrite_refs "${line%% *}" "${line#* }" 0
    done
    for line in $renames; do
        [ -n "$line" ] || continue
        _ob=${line%% *}; _ob=${_ob##*/}
        _nb=${line#* };  _nb=${_nb##*/}
        gr_contains "$ambiguous" "$_ob" && continue
        rewrite_refs "$_ob" "$_nb" 1
    done
    for _ob in $ambiguous; do
        [ -n "$_ob" ] || continue
        _hits=$(scan_refs "$_ob") || exit 2
        for _h in $_hits; do
            [ -n "$_h" ] || continue
            rewrite_file "$_h" "$_ob" "$_ob" 1 1
            case $? in
                (0) echo "left $_h: $_ob (two renames share this name; a bare reference cannot be resolved — write the path)" ;;
                (3) ;;
                (*) gr_die "reference scan failed: $_h ($_ob)" ;;
            esac
        done
    done
}
```

Note `scan_refs` runs in a command substitution, so its `gr_die` exits the
substitution only — hence the `|| exit 2` on every call, the same pattern the
file's own header explains for `gr_root`.

Replace the paragraph beginning `# No `set -f` around the splits below` with:

```sh
# No `set -f` around the splits below, and the reason has changed since it was
# first written. The `renames` fields are still `"$f $target"` under one
# directory with whitespace rejected at planning — no input reaches those
# splits. The rewrite pass (review finding 5) adds two unquoted splits that DO
# carry input: `$rewrite_scope` and the `scan_refs` hits, ledger file names
# listed by gr_doc_files and never checked for glob characters. They are the
# names of files that exist, so a pattern among them either matches nothing —
# and a word that matches nothing is left literal — or matches a sibling
# ledger file, which is then scanned too and rewritten only if it holds the
# name. Neither outcome loses a rewrite or invents one, and a `set -f` here
# is still unkillable for that reason. Stated rather than folded in.
```

Step 4 — `scripts/check-trace.sh`, the DANGLING-FILE gate. Change the scan
pattern to `'([A-Za-z0-9_.-]+/)*DRAFT-[A-Za-z0-9_.-]+\.md'` — every path
component ends in `/`, so a glued prefix (`xDRAFT-…`) can no longer be read
as part of a path and yields the bare name instead — and change the
path-shaped arm to resolve from the referencing file's directory as well:

```sh
            (*/*)
                [ -e "$_dref" ] && continue
                case "$_dfile" in (*/*) _ddir=${_dfile%/*} ;; (*) _ddir=. ;; esac
                [ -e "$_ddir/$_dref" ] && continue ;;
```

and add to the gate's comment block: `A path-shaped reference resolves from
the repository root and then from the referencing file's own directory, so
the relative link a markdown renderer actually follows is not convicted
while its target exists (review finding 4).`

Step 5 — `README.md` line 135: replace `rewrites every reference to a
renamed file across the ledger directories and the SOUP file and prints
each` with `rewrites every path-shaped reference to a renamed file, and every
bare name that only one rename maps, across the ledger directories and the
SOUP file, printing each; a bare name two renames share is reported as left
for the author to write as a path`.

Step 6 — run tests/finalize-docs.bats, tests/check-trace.bats,
tests/skills.bats, tests/portability.bats green. Commit:
`git -c commit.gpgsign=false commit -am "review round 1: bare pass skips foreign paths, dry-run matches the real run, left once per file, relative links resolve (PR-58zsvf)"`.

**Done** — task branch 04ef93d merged into the change branch as c40e5db on
2026-09-08. Dispatch report: finalize-docs.bats 27, check-trace.bats 226,
skills.bats 43, portability.bats 10 passed, 0 failed. No surprises; the
plan's replacement code applied verbatim.

- red -> green: `a path to another file that shares the draft's basename is not rewritten` — watched fail (the `Foreign:` path was rewritten by the bare pass) before the fix existed
- red -> green: `--dry-run previews exactly the rewrites the real run makes` — watched fail (two `would rewrite` lines for one file) before the fix existed
- red -> green: `an ambiguous basename is reported left once per file, and only where a bare form stands` — watched fail (two identical `left` lines) before the fix existed
- red -> green: `a relative link to a draft that exists resolves from the referencing file` — watched fail (`DANGLING-FILE ../risk/DRAFT-feature-a.md`) before the fix existed
- red -> green: `merge-step-3-reports-rewrites`, extended assertion — watched fail (`reported as left` absent from README.md) before the edit existed

### T7 — review round 2 fixes (findings 9–15)

**Files touched:** scripts/finalize-docs.sh, scripts/check-trace.sh, README.md, skills/merge-change/SKILL.md, skills/check-traceability/SKILL.md, tests/finalize-docs.bats, tests/check-trace.bats, tests/skills.bats
**Parallel:** no (serial, after the round-2 review)
**Trace IDs:** PR-58zsvf

Round 2 (2026-09-08) confirmed findings 1–6 and 8 closed and returned seven
more: two IMPORTANT (9, 11), five MINOR. Dispositions:

- **9** — the gate accepts a relative link (`../risk/DRAFT-x.md`,
  `./DRAFT-x.md`) while the draft exists, but finalize rewrites only
  root-relative paths and bare names, so such a link becomes `DANGLING-FILE`
  at merge. Not silent: the gate names the site. Decided: document, do not
  rewrite. Resolving `..` against a referencing file's directory inside awk
  is a path normaliser, and root-relative paths are how every ledger in this
  toolkit cites a file. The three over-promising sentences say "root-relative
  path or bare name", and the remedy row names this cause.
- **10** — the bare pass iterates renames, so two sibling drafts sharing an
  unambiguous basename preview twice. Iterate the unique basenames.
- **11** — `scan_refs`'s failure guard has no test. Add one via a `git`
  wrapper on PATH that deletes a scope file when asked to `grep -l`, and a
  header sentence on what a die leaves behind.
- **12** — the per-file `left` probe is load-bearing only under `--dry-run`
  and the test never runs it that way. Add the dry-run assertion.
- **13** — the finding-5 comment's reasoning is false: a glob-shaped ledger
  name that matches a sibling is replaced by the match and its rewrite is
  lost. Add `set -f` after planning, as the sibling scripts do, with a test.
- **14** — the bare pass rewrites a glued token (`xDRAFT-x.md`), and the
  check-trace pattern change has no test. Require a non-name character (or
  line start) before a bare occurrence, and pin the pattern with a test.
- **15** — a failed probe is reported as a failed scan. Say "probe".

Step 1 — failing tests. Append to `tests/finalize-docs.bats`:

```bash
@test "finalize: two sibling drafts sharing a basename preview and rewrite the same lines once" {
    # verifies: PR-58zsvf — review finding 10.
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-x.md
    printf '**HAZ-h7z4mn**: overdose.\n' > docs/risk/DRAFT-feature-x.md
    printf '\nSee DRAFT-feature-x.md.\n' >> docs/architecture/soup.md
    commit_all siblings-preview
    run sh .guardrails/scripts/finalize-docs.sh --dry-run
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$(printf '%s\n' "$output" | grep -c 'would rewrite docs/architecture/soup.md')" -eq 1 ] || { echo "$output"; false; }
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$(printf '%s\n' "$output" | grep -c 'rewrote docs/architecture/soup.md')" -eq 1 ] || { echo "$output"; false; }
}

@test "finalize: a reference scan that fails aborts instead of reporting a clean finalize" {
    # verifies: PR-58zsvf — review finding 11. A git wrapper deletes a scope
    # file the moment the rewrite pass scans, so git grep exits 128; the
    # script must die, not read that as "no occurrences".
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-x.md
    printf '\nSee DRAFT-feature-x.md.\n' >> docs/risk/README.md
    commit_all scan-fails
    real_git=$(command -v git)
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cat > "$BATS_TEST_TMPDIR/bin/git" <<EOF
#!/bin/sh
if [ "\$1" = grep ] && [ "\$2" = -l ]; then rm -f docs/problems/README.md; fi
exec "$real_git" "\$@"
EOF
    chmod +x "$BATS_TEST_TMPDIR/bin/git"
    PATH="$BATS_TEST_TMPDIR/bin:$PATH" run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"reference scan failed"* ]] || { echo "$output"; false; }
}

@test "finalize: a glob-shaped ledger name is scanned as itself, not as what it matches" {
    # verifies: PR-58zsvf — review finding 13. Without set -f the unquoted
    # scope split expands docs/risk/[x].md to docs/risk/x.md and the rewrite
    # in [x].md is lost.
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-x.md
    printf '# a sibling the glob would match\n' > docs/risk/x.md
    printf '\nSee DRAFT-feature-x.md.\n' > 'docs/risk/[x].md'
    commit_all glob-name
    today=$(date +%Y-%m-%d)
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q "See ${today}-x.md\." 'docs/risk/[x].md'
}

@test "finalize: a token glued to a longer word is not the file's name" {
    # verifies: PR-58zsvf — review finding 14.
    printf '**REQ-a3k9z2**: draft requirement.\n' > docs/requirements/DRAFT-feature-x.md
    printf '\nGlued: xDRAFT-feature-x.md and _DRAFT-feature-x.md; real: DRAFT-feature-x.md.\n' >> docs/risk/README.md
    commit_all glued
    today=$(date +%Y-%m-%d)
    run sh .guardrails/scripts/finalize-docs.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    grep -q 'Glued: xDRAFT-feature-x.md and _DRAFT-feature-x.md;' docs/risk/README.md
    grep -q "real: ${today}-x.md\." docs/risk/README.md
}
```

Extend the finding-3 test `finalize: an ambiguous basename is reported left
once per file, and only where a bare form stands` (finding 12): before its
existing `run sh .guardrails/scripts/finalize-docs.sh`, insert

```bash
    run sh .guardrails/scripts/finalize-docs.sh --dry-run
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"left docs/architecture/soup.md"* ]] || { echo "dry-run: $output"; false; }
    [ "$(printf '%s\n' "$output" | grep -c '^left docs/architecture/README.md:')" -eq 1 ] || { echo "dry-run: $output"; false; }
```

Append to `tests/check-trace.bats`:

```bash
@test "check-trace: a glued prefix is not a path, so the bare name resolves" {
    # verifies: PR-58zsvf — review finding 14: the scan pattern requires every
    # path component to end in "/", so xDRAFT-… yields the bare name.
    printf '# Draft hazards\n' > docs/risk/DRAFT-feature-a.md
    printf '\nGlued: xDRAFT-feature-a.md.\n' >> docs/requirements/0001-01-01-base.md
    commit_all glued-prefix
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" != *"DANGLING-FILE"* ]] || { echo "$output"; false; }
}
```

Extend `merge-step-3-reports-rewrites` in `tests/skills.bats` (finding 9)
with: `grep -q 'root-relative' "$BATS_TEST_DIRNAME/../README.md"` and
`grep -q 'root-relative' "$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"`
and `grep -q 'relative link' "$BATS_TEST_DIRNAME/../skills/check-traceability/SKILL.md"`.

Step 2 — watch each fail for its reason: finding 10 → two `would rewrite`
lines; 11 → exit 0; 13 → the rewrite in `[x].md` missing; 14 (finalize) →
glued tokens rewritten; 14 (check-trace) → `DANGLING-FILE xDRAFT-feature-a.md`
(the round-1 pattern is not yet the target of this test — it should pass on
the current tree; if it does, note that under surprises, it pins the pattern
either way); 12 → the mutant is what the assertion catches, so it passes on
the current tree — expected, state it; 9 → strings absent.

Step 3 — `scripts/finalize-docs.sh`.

(a) In `rewrite_file`'s awk, replace the bare-skip condition
`if (bare && p > 1 && substr(line, p - 1, 1) == "/")` with a rule that a bare
occurrence must begin the line or follow a character that cannot be part of a
file name:

```awk
                if (bare && p > 1 && substr(line, p - 1, 1) ~ /[A-Za-z0-9_.\/-]/) {
```

and update the comment above it: `an occurrence preceded by "/" is the tail
of a path to some OTHER file that shares the basename, and one preceded by a
name character is a longer token that merely ends in the name; neither is
this rename's to change (review findings 1 and 14).`

(b) Iterate unique basenames in the bare pass (finding 10). Replace the
second loop of `run_rewrites` with:

```sh
    for _pair in $bare_pairs; do
        [ -n "$_pair" ] || continue
        _ob=${_pair%% *}
        _nb=${_pair#* }
        gr_contains "$ambiguous" "$_ob" && continue
        rewrite_refs "$_ob" "$_nb" 1
    done
```

and compute `bare_pairs` right after `ambiguous`, one `old new` basename pair
per distinct old basename:

```sh
bare_pairs=$(printf '%s' "$renames" | awk '
    NF == 2 {
        o = $1; sub(/.*\//, "", o)
        t = $2; sub(/.*\//, "", t)
        if (!(o in seen)) { seen[o] = t; print o " " t }
    }')
```

(c) Finding 15: in the ambiguous loop's `case`, change
`gr_die "reference scan failed: $_h ($_ob)"` to
`gr_die "reference probe failed: $_h ($_ob)"`.

(d) Finding 13: replace the comment paragraph beginning `# No `set -f` around
the splits below, and the reason has changed` with:

```sh
# Pathname expansion OFF from here on. The planning glob above is done, and
# the rewrite pass splits `$rewrite_scope` and the scan hits unquoted —
# ledger file names listed by gr_doc_files, never checked for glob
# characters. An earlier comment here argued no input reached these splits;
# the rewrite pass changed that, and a glob-shaped name that matches a sibling
# is replaced by the match, so the file it named is never scanned and its
# rewrite is lost (review finding 13; the test names a `[x].md`). The renames
# record itself is still safe for the reason it always was — whitespace is
# rejected at planning — but one line covers both.
set -f
```

placing `set -f` immediately after that comment, before the `for line in
$renames` print loop.

(e) Finding 9 and 11, header. Replace `Then rewrites every reference to a
renamed file across the ledger directories and the SOUP file` with `Then
rewrites every root-relative path and every bare name that refers to a
renamed file across the ledger directories and the SOUP file`, and add after
the `Exit codes:` line: `A die during the rewrite pass leaves the renames
staged and the references as they were; a re-run is the silent no-op, so
recovery is to fix the references by hand — check-trace.sh's DANGLING-FILE
names each one.`

Step 4 — `README.md` line 135: `rewrites every path-shaped reference` →
`rewrites every root-relative path reference`; and after `for the author to
write as a path` add `; a relative link (`../risk/DRAFT-x.md`) is not
carried either and is reported by `check-trace.sh` as `DANGLING-FILE` after
the merge`.

Step 5 — `skills/merge-change/SKILL.md` step 3: `It then rewrites every
reference to a renamed file` → `It then rewrites every root-relative path and
every bare name that refers to a renamed file`; after the sentence about
`left FILE: …` add: `A relative link such as `../risk/DRAFT-x.md` is not
rewritten; step 5 reports it as `DANGLING-FILE` and you write the dated name
by hand.`

Step 6 — `skills/check-traceability/SKILL.md` row 155: after `or a draft in
another unit;` insert `or a relative link (`../risk/DRAFT-x.md`), which
resolves while the draft exists but which finalize does not carry;`.

Step 7 — run tests/finalize-docs.bats, tests/check-trace.bats,
tests/skills.bats, tests/portability.bats green. Commit:
`git -c commit.gpgsign=false commit -am "review round 2: bare pass needs a word boundary, unique basenames, set -f, scan failure tested, relative links documented (PR-58zsvf)"`.

**Done** — task branch 6bdf290 merged into the change branch as 09f6aad on
2026-09-08. Dispatch report: finalize-docs.bats 31, check-trace.bats 227,
skills.bats 43, portability.bats 10 passed, 0 failed. scripts/check-trace.sh
was not touched: T7 has no code step for it, and its new test pins the
round-1 pattern as it stands.

- red -> green: `two sibling drafts sharing a basename preview and rewrite the same lines once` — watched fail (two `would rewrite docs/architecture/soup.md` lines) before the fix existed
- red -> green: `a glob-shaped ledger name is scanned as itself, not as what it matches` — watched fail (the rewrite absent from `docs/risk/[x].md`) before the fix existed
- red -> green: `a token glued to a longer word is not the file's name` — watched fail (the `Glued:` tokens were rewritten) before the fix existed
- red -> green: `merge-step-3-reports-rewrites`, extended — watched fail (`root-relative` absent from README.md) before the edits existed
- boundary pins, green on the current tree as predicted: the dry-run assertions added to `an ambiguous basename is reported left once per file…` (finding 12: the mutant is what they catch), and `check-trace: a glued prefix is not a path, so the bare name resolves` (finding 14: the round-1 pattern already yields the bare name)
- boundary pin NOT predicted: `a reference scan that fails aborts instead of reporting a clean finalize` was green on the current tree (exit 2, `reference scan failed`) because the round-1 `scan_refs` guard already existed; step 2 above said exit 0 and was wrong. It pins the guard, which is what finding 11 asked for
- plan defect fixed by the dispatch: `set -f` placed before the print loop also switched expansion off for the post-rename scope recomputation, whose `gr_doc_files` enumerates each ledger by glob, and fifteen finalize tests died with `contains no *.md files`. The recomputation loop is bracketed with `set +f` … `set -f`, the same bracket check-trace.sh uses around its own `gr_doc_files` calls, with a comment saying so

### T8 — review round 3 fixes (findings 16–21)

**Files touched:** scripts/finalize-docs.sh, scripts/check-trace.sh, README.md, skills/merge-change/SKILL.md, skills/check-traceability/SKILL.md, tests/finalize-docs.bats, tests/check-trace.bats
**Parallel:** no (serial, after the round-3 review)
**Trace IDs:** PR-58zsvf

Round 3 (2026-09-09) confirmed findings 9–15 closed or defensibly
dispositioned and returned six MINOR findings, each stated as non-blocking.
All six are fixed here; none changes behaviour except the wording of one
message. Dispositions:

- **16** — the first `set -f` (before the dry-run preview) is unkillable: the
  glob-name test runs the real path only, which the second `set -f`
  re-protects. Add a `--dry-run` assertion to that test.
- **17** — rewrite and gate disagree on a left-glued token: the bare pass
  skips `_DRAFT-x.md_` and `aDRAFT-x.md`, the gate extracts the bare name and
  convicts it after the merge. Loud, same class as finding 9. Document it in
  the three places that list the hand-fix cases; do not widen the rewrite.
- **18** — the gate's token class `[A-Za-z0-9_.-]` is narrower than what
  finalize renames, so `DRAFT-a+b.md` is a silent miss. Only for names the
  shipped grammar never produces. State the class in the header and comment.
- **19** — in a manifest repository a bare name resolves against this unit's
  ledger directories only, so a cross-unit bare reference to an existing
  draft is convicted with a message that says the file does not exist. Split
  the message: the bare arm says where it looked.
- **20** — the header overstates what a die during the rewrite leaves
  behind: references rewritten before the die stay rewritten, and "staged"
  holds for tracked drafts only. Say so.
- **21** — under `--dry-run` a reference inside a renamed draft is reported
  under the draft's own name. Inherent to previewing before the rename; one
  clause in the header.

Step 1 — tests. In `tests/finalize-docs.bats`, extend
`finalize: a glob-shaped ledger name is scanned as itself, not as what it matches`
(finding 16): before its existing real `run`, insert

```bash
    run sh .guardrails/scripts/finalize-docs.sh --dry-run
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [[ "$output" == *"would rewrite docs/risk/[x].md: DRAFT-feature-x.md -> ${today}-x.md"* ]] || { echo "dry-run: $output"; false; }
```

(`today` is already defined in that test before the real run; move its
assignment above the dry-run.) Append to `tests/check-trace.bats`:

```bash
@test "check-trace: a bare draft name found in no ledger directory says where it looked" {
    # verifies: PR-58zsvf — review finding 19: a bare name resolves against
    # THIS config's ledger directories, and the message must not claim the
    # file does not exist anywhere.
    printf '\nSee DRAFT-other-alarms.md.\n' >> docs/requirements/0001-01-01-base.md
    commit_all bare-dangling
    run sh .guardrails/scripts/check-trace.sh
    [ "$status" -eq 1 ] || { echo "$output"; false; }
    [[ "$output" == *"DANGLING-FILE DRAFT-other-alarms.md (docs/requirements/0001-01-01-base.md:"*"found in none of this config's ledger directories"* ]] || { echo "$output"; false; }
}
```

Step 2 — watch the finding-16 assertion pass on the current tree (it is the
kill for the mutant round 3 named, so green on arrival is expected; say so)
and the finding-19 test fail (the current message says `does not exist`).

Step 3 — `scripts/check-trace.sh`, DANGLING-FILE gate. Replace the single
`echo "DANGLING-FILE …"` with a message chosen per arm. Restructure the
`case` so each arm sets `_why` and falls through to one echo:

```sh
        case "$_dref" in
            (*/*)
                [ -e "$_dref" ] && continue
                case "$_dfile" in (*/*) _ddir=${_dfile%/*} ;; (*) _ddir=. ;; esac
                [ -e "$_ddir/$_dref" ] && continue
                _why="names a draft ledger file that does not exist — after a merge, write the dated name" ;;
            (*)
                _found=0
                for _d in $doc_dirs; do
                    [ -e "$_d/$_dref" ] && { _found=1; break; }
                done
                [ "$_found" -eq 1 ] && continue
                _why="names a draft ledger file found in none of this config's ledger directories — after a merge, write the dated name; across units, write the path" ;;
        esac
        echo "DANGLING-FILE $_dref ($_dfile:$_dline $_why)"
        fail=1
```

Header line for DANGLING-FILE (finding 18): `a DRAFT-<name>.md ledger file
(name characters [A-Za-z0-9_.-]) named in a doc_* file, by path or bare
name, that does not exist`. In the gate's comment block add: `The token class
is the ledger grammar's — letters, digits, underscore, dot, hyphen — so a
draft named outside it (a + or @ in the slug) is not looked for; finalize
renames any DRAFT-*.md, so this is narrower than the rename, deliberately:
widening it to any non-space character makes prose match (review finding
18). A bare name resolves against THIS config's ledger directories: in a
manifest repository a bare reference to another unit's draft is reported
even while that draft exists, because a bare name across units is ambiguous
— the path form resolves (finding 19).`

Step 4 — `scripts/finalize-docs.sh` header. Replace the sentence added for
finding 11 (`A die during the rewrite pass leaves the renames staged and the
references as they were; …`) with: `A die during the rewrite pass leaves the
renames done (staged for a tracked draft, plain-moved for an untracked one),
every reference rewritten before the die rewritten, and the rest as they
were; a re-run is the silent no-op, so recovery is to fix the remaining
references by hand — check-trace.sh's DANGLING-FILE names each one.` Add
after the `--dry-run` sentence: `Under --dry-run a reference inside a draft
that is itself being renamed is reported under the draft's own name, since
the preview runs before the rename.` (finding 21). Add after the Plans and
verification records sentence: `A bare name glued to a longer token or
wrapped in emphasis (aDRAFT-x.md, _DRAFT-x.md_) is not rewritten either — it
is not the file's name — and check-trace.sh reports it after the merge.`
(finding 17).

Step 5 — README.md line 135: after the relative-link clause add `, as is a
name glued to a longer token or wrapped in emphasis underscores`.
`skills/merge-change/SKILL.md` step 3: after the relative-link sentence add
`The same holds for a name wrapped in emphasis (`_DRAFT-x.md_`) or glued to
a longer word.` `skills/check-traceability/SKILL.md` DANGLING-FILE row: after
the relative-link cause add `or a name wrapped in emphasis or glued to a
longer word, which finalize also leaves`; and change `A reference to a draft
that exists is fine: that is every change in flight.` to `A reference to a
draft that exists is fine — that is every change in flight — with one
edge: a bare name resolves against this unit's ledger directories only, so
across units write the path.`

Step 6 — tests/finalize-docs.bats, tests/check-trace.bats, tests/skills.bats,
tests/portability.bats green. Commit:
`git -c commit.gpgsign=false commit -am "review round 3: dry-run pins the first set -f, DANGLING-FILE says where it looked, headers state the boundaries (PR-58zsvf)"`.

**Done** — task branch 304018b merged into the change branch as e81a419 on
2026-09-09. Dispatch report: check-trace.bats 228, finalize-docs.bats 31,
skills.bats 43, portability.bats 10 passed, 0 failed. The dispatch stalled
once on the long check-trace run and was resumed with its edits intact; no
work was redone.

- red -> green: `check-trace: a bare draft name found in no ledger directory says where it looked` — watched fail (exit 1 with the old `does not exist` message) before the message split existed
- boundary pin, green on arrival as predicted: the `--dry-run` assertion added to `finalize: a glob-shaped ledger name is scanned as itself…` (finding 16). The dispatch performed the mutant check: with the first `set -f` neutralised, the new assertion fails and the pre-existing real-run assertion alone does not, so the assertion kills the mutant round 3 named. Script restored
- the existing DANGLING-FILE tests match the message prefix only and stayed green through the split

### T9 — review round 4 fixes (findings 22 and 23)

**Files touched:** scripts/check-trace.sh, tests/check-trace.bats
**Parallel:** no (serial, after the round-4 review)
**Trace IDs:** PR-58zsvf

Round 4 (2026-09-09) confirmed T8 closes findings 16–21 and introduces
nothing new, and returned two MINOR findings, both stated as non-blocking
and both one line:

- **22** — the path arm's message asserts the file "does not exist" after
  probing exactly two locations, neither named, while the bare arm was split
  precisely to say where it looked. Cosmetic, and the same over-promise
  finding 19 fixed on the other arm.
- **23** — no test pins the path arm's message text: the existing assertion
  stops at the site prefix, so an edit that gave the path arm the bare arm's
  wording, or dropped `_why` from it, would keep every test green.

**No fifth review round follows this task, and that is a decision rather than
an omission.** This repository is IEC 62304 class A
(docs/adr/2026-08-22-safety-class.md), where the ADR records independent
review as *optional* and kept as practice rather than imposed. Four rounds
have run, on a change whose findings converged strictly — round 1: one
IMPORTANT and seven MINOR; round 2: two IMPORTANT and five MINOR; round 3:
six MINOR, all non-blocking; round 4: two MINOR, both non-blocking. T9's
diff is one message string and one test assertion, both named by the
reviewer with the wording to use. The gate re-runs in full; the verification
record states that these two findings were fixed after the last review saw
the tree.

Step 1 — the test first. In `tests/check-trace.bats`, extend the existing
`check-trace: a ledger reference to a draft file that does not exist is
DANGLING-FILE` assertion (finding 23) so it pins the path arm's own wording,
replacing

```bash
    [[ "$output" == *"DANGLING-FILE docs/risk/DRAFT-other-alarms.md (docs/requirements/0001-01-01-base.md:"* ]] \
        || { echo "$output"; false; }
```

with

```bash
    # The message is pinned, not just the site: the two arms were split so
    # each says where it looked (review findings 19, 22, 23), and without an
    # assertion on the text an edit that swapped the arms' wording — or
    # dropped this arm's `_why` — would keep every test green.
    [[ "$output" == *"DANGLING-FILE docs/risk/DRAFT-other-alarms.md (docs/requirements/0001-01-01-base.md:"*"found neither at the repository root nor beside the file naming it"* ]] \
        || { echo "$output"; false; }
```

Step 2 — watch it fail: the current path arm says `names a draft ledger file
that does not exist`, so the new substring is absent.

Step 3 — `scripts/check-trace.sh`, the path arm's `_why` (finding 22):

```sh
                _why="names a draft ledger file found neither at the repository root nor beside the file naming it — after a merge, write the dated name" ;;
```

In the gate's comment block, replace the sentence explaining the two-root
resolution with: `A path-shaped reference resolves from the repository root
and then from the referencing file's own directory, so the relative link a
markdown renderer actually follows is not convicted while its target exists
(review finding 4). Each arm's message names the places it looked rather
than asserting the file exists nowhere: in a manifest repository a path
written relative to another unit's root resolves against neither root, and
"does not exist" would be false of it (findings 19 and 22).`

Step 4 — run tests/check-trace.bats and tests/finalize-docs.bats green (the
message change touches no other assertion; the bare-arm test at
`a bare draft name found in no ledger directory says where it looked` pins
the other arm and must stay green). Commit:
`git -c commit.gpgsign=false commit -am "review round 4: each DANGLING-FILE arm names where it looked, and a test pins both (PR-58zsvf)"`.

**Done** — task branch c7c669d merged into the change branch as 02e77a9 on
2026-09-09. Dispatch report: check-trace.bats 228, finalize-docs.bats 31
passed, 0 failed.

- red -> green: `check-trace: a ledger reference to a draft file that does not exist is DANGLING-FILE`, assertion strengthened — watched fail (the run printed the old `names a draft ledger file that does not exist` wording, so the required substring was absent) before the `_why` change existed
- no new test: finding 23 asked for depth on an existing assertion, and that is what it got, so each arm is now pinned by its own test
- the step-3 comment replacement ended a sentence the original continued, so the following clause was recased to keep the paragraph grammatical; the old message string survives twice in this plan as the historical T3 and T8 listings, which is what a plan is for

## Self-review

1. Both PR IDs have tests that verify them: T1 (five), T2 (nine), T3 (five),
   T4 (three).
2. Every task shows the code and the command.
3. Names are consistent across tasks: `rewrite_scope`, `rewrite_file`,
   `rewrite_refs`, `run_rewrites`, `ambiguous` in T2; `file_scope`,
   `doc_dirs` in T3; message shapes `rewrote FILE: old -> new`,
   `would rewrite …`, `left FILE: …`, `DANGLING-FILE FILE (site:line …)`,
   `UNANALYZED-DERIVED ID (no 'assesses:' line in the RMF names it)` are
   quoted identically in tests, scripts and skills.
4. T1 and T2 are the only parallel pair and share no file.
