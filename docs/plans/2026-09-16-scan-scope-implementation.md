# Closing the writing scan's scope gap — Implementation Plan

**Goal:** the writing scan reads every tracked file the rules bind, its word
table is checked against the shipped replace list, and the tree is swept clean.
**Implements:** D1-D6 (`docs/plans/2026-09-16-scan-scope.md`)
**Safety class:** not configured. This repository does not self-host its gates —
there is no `.guardrails/`, so `check-trace.sh`, `check-ids.sh` and
`check-review.sh` exit 2 here and are reported as inapplicable with evidence,
never as passes.
**Verification:** `tests/run-tests.sh`

## How a task runs its test

`tests/run-tests.sh` appends its argument to the glob, so it cannot run one
file, and a full run takes about 25 minutes — long enough to kill a subagent.
Each task runs its own file directly:

```sh
tests/.bats-core/bin/bats tests/skills.bats
```

The dispatcher runs the full suite between tasks, not inside them.

**Exit 0 is not a pass.** Read the verdict from the `1..N` plan line and the
`not ok` count, never from the exit status, and never through a pipe — a pipe
reports the status of its last stage.

## Task order and why it is serial

Every task edits the pathspec in `tests/skills.bats`, so no two tasks have
disjoint file sets and none may run in parallel. T1 installs the machinery the
later tasks widen, so the order is fixed.

Each task has the same shape. Widen the pathspec, watch the scan report that
task's surface, sweep it, watch the scan pass. The red is specific to the task.

---

### T1 — The scan machinery, the shipped rule, and the vocabulary files

**Files touched:** `tests/skills.bats`, `AGENTS.md`, `templates/AGENTS-block.md`,
`install.sh`, `skills/ratchet/SKILL.md`, `scripts/check-trace.sh`,
`tests/check-trace.bats`
**Parallel:** no

`skills/ratchet/SKILL.md:384` quotes a message `check-trace.sh` prints, so the
message and its six assertions change in this task even though `scripts/` enters
the pathspec later. The alternative is a skill quoting a message that no longer
exists.

**Step 1.** Add `sits -> is in` to the replace list in `AGENTS.md` (line 85) and
in `templates/AGENTS-block.md`. Both read, after the edit:

```
- Replace these words: carries -> contains, lands -> is merged, survives ->
  remains, says -> states, holds -> contains, refuses -> rejects,
  load-bearing -> critical, ran -> was run, sits -> is in.
```

**Step 2.** In `tests/skills.bats`, delete the `banned=` assignments and the
comment block above them from the existing scan test, and add the word table
above the first `@test` in the file:

```bash
# The word table the writing scan reads. Each key is a word the replace list in
# templates/AGENTS-block.md names; the rest of the line is the forms the scan
# reads for it.
#
# The forms are narrowed by hand against this tree until every correct English
# use stops matching, and that judgment cannot be derived from the replace list.
# `hold` is out and `holds`, `held`, `holding` are in, because `when all three
# hold` is correct. `say` is out and `says`, `said`, `saying` are in, because
# `say so` is correct and occurs in six places. `run` is out and `ran` is in.
# `sat` is out because it is an awk variable in check-trace.sh and produces
# seven false reports.
#
# This function body is the one region the scan exempts in this file. The scan
# opens the region at the declaration line below and closes it at the next line
# that is exactly a closing brace, so the rest of this file is scanned.
gr_writing_table() {
    cat <<'TABLE'
carries carry carries carried carrying
lands land lands landed landing
holds holds held holding
survives survive survives survived surviving
says says said saying
refuses refuse refuses refused refusing refusal
ran ran
load-bearing load-bearing
sits sit sits sitting
TABLE
}

gr_writing_forms() {
    gr_writing_table | cut -d' ' -f2- | tr ' ' '\n' | sort -u | paste -sd'|' -
}

gr_writing_keys() {
    gr_writing_table | cut -d' ' -f1 | sort
}

gr_writing_paths() {
    echo 'skills AGENTS.md templates/AGENTS-block.md install.sh tests/skills.bats'
}
```

`gr_writing_paths` is the pathspec each later task widens. It is a function and
not a variable so that a bats test can read it without a sourcing order.

**Step 3.** Replace the existing scan test with these two. Write them, run the
file, and watch both fail before any sweep:

```bash
@test "clanker: the word table and the shipped replace list name the same words" {
    # verifies: D4 (docs/plans/2026-09-16-scan-scope.md)
    # The predecessor's list was a hand copy of the shipped rule with nothing
    # connecting the two, so a word added to the rule reached no scan. The
    # comparison is bidirectional by construction: a shipped word with no table
    # entry fails, and a table entry with no shipped word behind it fails.
    cd "$BATS_TEST_DIRNAME/.." || return 1

    shipped=$(
        awk '/^- Replace these words:/ { f = 1; line = $0; next }
             f && /^  / { line = line " " $0; next }
             f { exit }
             END { print line }' templates/AGENTS-block.md \
            | grep -Eo '[a-z-]+ ->' | sed 's/ ->$//' | sort
    )
    if [ -z "$shipped" ]; then
        echo 'no replace list was found in templates/AGENTS-block.md'
        return 1
    fi

    keys=$(gr_writing_keys)
    if [ "$shipped" != "$keys" ]; then
        printf 'the shipped replace list and the scan table disagree\nshipped:\n%s\ntable:\n%s\n' \
            "$shipped" "$keys"
        return 1
    fi
}

@test "clanker: no file in scope contains the replaced vocabulary" {
    # verifies: D1, D2, D3 (docs/plans/2026-09-16-scan-scope.md)
    # Scope is every tracked file the rules bind. docs/plans and
    # docs/verification are out permanently: they are merged evidence, and
    # editing a record to match a later tree falsifies what it proved.
    cd "$BATS_TEST_DIRNAME/.." || return 1
    banned=$(gr_writing_forms)

    # A pathspec that matches nothing makes an empty scan indistinguishable
    # from a clean tree. Check each element rather than counting files, so a
    # path that moves is reported by name.
    for p in $(gr_writing_paths); do
        if ! git ls-files -- "$p" | grep -q .; then
            printf 'pathspec element %s matched no tracked file\n' "$p"
            return 1
        fi
    done

    # D2 exempts one named region per file, and an exemption that matches more
    # than it should is the failure with no symptom. Pin the count.
    md=$(git grep -lE '^## Writing: prose, names and messages$' -- $(gr_writing_paths) | wc -l | tr -d '[:space:]')
    if [ "$md" -ne 2 ]; then
        printf 'the writing-section opener was found in %s files, expected 2\n' "$md"
        return 1
    fi
    tbl=$(git grep -lE '^gr_writing_table\(\) \{$' -- $(gr_writing_paths) | wc -l | tr -d '[:space:]')
    if [ "$tbl" -ne 1 ]; then
        printf 'the word-table opener was found in %s files, expected 1\n' "$tbl"
        return 1
    fi

    # One exemption remains: git's own wording, quoted in worktree-discipline.
    # It is removed by its full phrasing, so a second use of the word on the
    # same line is still reported.
    found=$(
        git ls-files -- $(gr_writing_paths) | while IFS= read -r f; do
            awk -v F="$f" '
                /^## Writing: prose, names and messages$/ { sec = 1; next }
                sec && /^## / { sec = 0 }
                /^gr_writing_table\(\) \{$/ { tab = 1; next }
                tab && /^\}$/ { tab = 0; next }
                sec || tab { next }
                { print F ":" NR ":" $0 }
            ' "$f"
        done \
            | sed -e 's/refusing to update checked out branch//g' \
                  -e 's/refusing to fetch into branch//g' \
            | grep -Eiw "$banned"
    ) || true

    if [ -n "$found" ]; then
        printf 'replaced vocabulary in files the rules bind:\n%s\n' "$found"
        return 1
    fi
}
```

**Expected red:** `not ok` on the scan test, listing `install.sh:9`,
`skills/ratchet/SKILL.md:384`, and the sites in `tests/skills.bats` outside the
table. The agreement test passes once step 1 and step 2 agree, and fails if
either was done without the other — do step 1 and step 2, run the file, and
record which of the two tests reddened and why.

**Step 4.** Sweep. `install.sh:9` becomes `Rejects anything that is not a
symlink it would replace.` In `scripts/check-trace.sh:1302` and `:1306`,
`which carries no` becomes `which contains no`; update the six assertions in
`tests/check-trace.bats` (lines 2136, 2150, 2176, 2212, 2457, 2459) and the
quotation in `skills/ratchet/SKILL.md:384` to match. Sweep the remaining sites
`tests/skills.bats` reports in its own non-exempt lines.

**Step 5.** Green: `tests/.bats-core/bin/bats tests/skills.bats` and
`tests/.bats-core/bin/bats tests/check-trace.bats`, both with zero `not ok`.

---

### T2 — README, templates and the writing documents

**Files touched:** `tests/skills.bats` (pathspec only), `README.md`,
`templates/verification.md`, `templates/config.yaml`, `templates/units.yaml`,
`templates/rmf.md`, `templates/srs.md`, `templates/sad.md`,
`templates/problems.md`, `docs/problems/*.md`, `docs/risk/*.md`
**Parallel:** no (serial, after T1)

**Step 1.** `gr_writing_paths` gains `README.md templates docs/problems
docs/risk docs/adr`.

**Step 2.** Run the file. Expected red: about 139 sites.

**Step 3.** Sweep. Every edit is prose. `docs/adr/` has no matches and is named
in the pathspec so the scope is stated rather than implied.

**Step 4.** Green on `tests/skills.bats`.

---

### T3 — lib.sh and the tests that read it

**Files touched:** `tests/skills.bats` (pathspec only), `scripts/lib.sh`,
`tests/lib.bats`, `tests/portability.bats`, `tests/helpers.bash`,
`tests/evidence.sh`
**Parallel:** no (serial, after T2)

**Step 1.** `gr_writing_paths` gains `scripts/lib.sh tests/lib.bats
tests/portability.bats tests/helpers.bash tests/evidence.sh`.

**Step 2.** Run the file. Expected red: about 125 sites.

**Step 3.** Sweep. Where a printed message changes, the assertion that reads it
changes in this task — both files are in this set. Before editing any line in
`scripts/lib.sh`, check it against the mutation anchors:

```sh
grep -rn 'lib\.sh' docs/verification/*.mutations/M*.sh | head -40
```

An anchor quotes script lines verbatim, so an edited line invalidates the
mutation evidence it produced. The measurement in the decision record found one
anchor in 184 containing a word on the list, and it targets `check-signing.sh`
(T4), not `lib.sh` — confirm that before sweeping rather than assuming it.

**Step 4.** Green on `tests/skills.bats`, `tests/lib.bats`,
`tests/portability.bats`.

---

### T4 — finish-merge, check-signing, and the one mutation anchor

**Files touched:** `tests/skills.bats` (pathspec only), `scripts/finish-merge.sh`,
`tests/finish-merge.bats`, `scripts/check-signing.sh`,
`tests/check-signing.bats`,
`docs/verification/2026-08-27-config-schema.mutations/M81.sh`
**Parallel:** no (serial, after T3)

**Step 1.** `gr_writing_paths` gains `scripts/finish-merge.sh
tests/finish-merge.bats scripts/check-signing.sh tests/check-signing.bats`.

**Step 2.** Run the file. Expected red: about 148 sites.

**Step 3.** Sweep. `scripts/check-signing.sh` contains the comment block
`M81.sh` anchors, and the anchor contains `carried`:

```
# git repository the script carried on in the caller's directory with a
```

`M81.sh` asserts `s.count(old) == 1`, so a stale anchor fails rather than
mutating nothing. Re-cut the anchor to the swept wording and re-prove the
mutation:

```sh
sh docs/verification/2026-08-27-config-schema.mutations/M81.sh
tests/.bats-core/bin/bats tests/check-signing.bats    # must report not ok
git checkout scripts/check-signing.sh
```

Report the `not ok` count the mutated tree produced. A mutation that leaves the
suite green is a hole in the tests, not a successful step.

**Step 4.** Green on `tests/skills.bats`, `tests/finish-merge.bats`,
`tests/check-signing.bats`.

---

### T5 — check-trace and check-ids

**Files touched:** `tests/skills.bats` (pathspec only), `scripts/check-trace.sh`,
`tests/check-trace.bats`, `scripts/check-ids.sh`, `tests/check-ids.bats`
**Parallel:** no (serial, after T4)

**Step 1.** `gr_writing_paths` gains `scripts/check-trace.sh
tests/check-trace.bats scripts/check-ids.sh tests/check-ids.bats`.

**Step 2.** Run the file. Expected red: about 116 sites — T1 swept eight of this
set already.

**Step 3.** Sweep. `scripts/check-trace.sh` contains `sat` as an awk variable in
four places; D3 excludes the past tense, so the scan does not report them and
they are not renamed.

**Step 4.** Green on `tests/skills.bats`, `tests/check-trace.bats`,
`tests/check-ids.bats`.

---

### T6 — The remaining scripts and tests, and the pathspec closes

**Files touched:** `tests/skills.bats` (pathspec only), `scripts/check-review.sh`,
`tests/check-review.bats`, `scripts/new-id.sh`, `tests/new-id.bats`,
`scripts/finalize-docs.sh`, `tests/finalize-docs.bats`, `scripts/check-units.sh`,
`tests/check-units.bats`, `tests/units-chain.bats`
**Parallel:** no (serial, after T5)

**Step 1.** `gr_writing_paths` becomes the full D1 list, with `scripts` and
`tests` replacing every per-file element added since T3:

```bash
gr_writing_paths() {
    echo 'skills AGENTS.md README.md templates install.sh scripts tests docs/problems docs/risk docs/adr'
}
```

**Step 2.** Run the file. Expected red: about 77 sites.

**Step 3.** Sweep.

**Step 4.** Green on `tests/skills.bats` and on every bats file this task
touched.

**Step 5.** Prove the scan by deletion, and report the result. Re-introduce one
swept word in a file the pathspec covers only through the T6 widening — for
example a comment in `scripts/check-units.sh` — run `tests/skills.bats`, confirm
`not ok` naming that file and line, and revert. A scan that stays green when the
vocabulary returns is the failure this change prevents, and the predecessor
change shipped that defect once.

---

## After the tasks

**The rename map.** Collect the `@test` names this change renamed, for D5:

```sh
git diff main...close-scan-scope -- 'tests/*.bats' \
    | grep -E '^[-+]@test' | sort
```

The map goes in `docs/verification/2026-09-16-close-scan-scope.md` as a table of
old name to new name. This change does not edit the merged records that cite the
old names.

**The deslop pass.** `develop-change`'s exit dispatches one subagent over
`main...close-scan-scope`. It applies the writing rules to the diff, including
the parts the scan cannot read — metaphor, voice, filler — the part D3 states
the scan does not cover.

**Gates.** `check-trace.sh`, `check-ids.sh` and `check-review.sh` exit 2 in this
repository because there is no `.guardrails/`. Report each as inapplicable with
its exit status as evidence, never as a pass, and never read an exit status
through a pipe.

## Self-review

1. Every decision in **Implements:** has a task whose test verifies it: D1, D2
   and D3 by the scan test (T1, widened T2-T6); D4 by the agreement test (T1);
   D5 by the rename map; D6 by the absence of a shipped script, recorded rather
   than tested.
2. Every task states the code, the commands and the expected red.
3. `gr_writing_table`, `gr_writing_forms`, `gr_writing_keys` and
   `gr_writing_paths` are used with the same signatures in every task.
4. Every task has **Files touched:** and **Parallel:**. No task is marked
   parallel, because every one edits `tests/skills.bats`.

## Verified before dispatch

Three mechanisms in this plan were run against the tree at `3714f08` rather than
written from memory:

- The replace-list parse returns exactly `carries holds lands load-bearing ran
  refuses says survives` from `templates/AGENTS-block.md`, so the continuation
  rule reads the wrapped bullet correctly. `sits` joins it after T1 step 1.
- The exemption awk drops lines 73 to 93 of `AGENTS.md` and resumes at `##
  Rules` on line 94.
- `git grep -lx` does not exist — `-x` belongs to grep(1), not to git grep,
  which exits 129 with `unknown switch`. The anchored `-E '^...$'` form above
  was run instead, and it reports 2 files for the markdown opener and 0 for the
  table opener, which becomes 1 after T1.

## Standing note for T2 to T6, from T1

**An assertion that quotes a swept word as a literal is not prose.** T1 found
`grep -q 'load-bearing' "$block"` in a predecessor test: the word is the thing
being tested, so substituting it destroys the test and leaving it reddens the
scan. Neither option is a sweep. Decide case by case, by asking whether anything
still pins the fact that literal pins after the change. In T1's case something
does — the D4 agreement test — and the dispatcher confirmed that by deleting
`load-bearing -> critical` from the shipped block and observing
`not ok 1` before restoring the tree.

Report every such site in the deviations field rather than deciding it silently.

## Task records

### T1 — merged at `4ec1cde`

`tests/skills.bats` `1..56`, 56 ok, 0 not ok. `tests/check-trace.bats` `1..260`,
260 ok, 0 not ok. Twelve sites swept across five files.

Red observed before the sweep: the scan test reported seven sites —
`install.sh:9`, `skills/ratchet/SKILL.md:384`, and five in `tests/skills.bats`.
The agreement test passed, as the plan predicted, and its other direction was
proved separately by removing `sits -> is in` from the block.

Two deviations, both correcting this plan:

1. The plan put the word table's explanatory paragraph **above**
   `gr_writing_table() {`, but D2's exemption opens **at** that line, so the
   paragraph naming `holds`, `says` and `ran` was scanned and could not go
   green. T1 moved it inside the function body. Any later text explaining the
   vocabulary belongs inside that region.
2. `grep -q 'load-bearing' "$block"` became `grep -q 'Replace these words'`.
   See the standing note above.

No mutation anchor quotes `which carries no` or `NON-RECIPROCAL-SUPERSESSION`;
this was checked across all 184 `M*.sh` before `check-trace.sh` was edited.

## Binding test names for T3 and T4, from T2

T2 swept five citations in `docs/problems/` to the wording T3 and T4 will
produce. The citations name the test that reproduced each problem item, so the
rename and the citation must agree exactly or the merged tree contains a
reference to a test that does not exist. Use these names verbatim:

**T3 — `tests/portability.bats`**

| Line | Name after the sweep |
|---|---|
| 48 | `check-review: runs under an awk that rejects a newline in -v` |
| 91 | `every check script runs clean under an awk that rejects a newline in -v` |

**T4 — `tests/check-signing.bats`**

| Line | Name after the sweep |
|---|---|
| 75 | `check-signing: a failed verdict contains the verifier's own reason` |
| 153 | `check-signing: an untrusted signature contains the verifier's reason too` |

**T4 — `tests/finish-merge.bats`**

| Line | Name after the sweep |
|---|---|
| 614 | `finish-merge: --check rejects the base branch` |

One citation was already stale before this change: T1 renamed
`ratchet: tool qualification says how and where the suite runs` to `states how
and where the suite runs`, and `docs/problems/2026-08-30-tool-qualification.md`
still cited the old name. T2's sweep restored the reference rather than breaking
it.

**Before the merge, check every citation resolves.** The sweep renames 58 tests
and the documents that cite them are swept independently, so a mismatch is
possible in either direction. Extract every quoted `@test` name from
`docs/problems/`, `docs/risk/`, `docs/adr/` and `README.md` and confirm each
one occurs in `tests/*.bats`.

### T2 — merged at `40b5216`

`tests/skills.bats` `1..56`, 56 ok, 0 not ok, verified by the dispatcher after
the merge. 133 sites swept across 20 files. The plan predicted about 139: the
scan reports one line per site and several lines contain two matches, so the
figures measure different things.

Six sites took the nearest true dry word where the listed replacement does not
fit the grammar — `rules carry the whole system` became `define`, `the chain
holds by design` became `is correct by design`. Each is a substitution, not a
rewrite.

`docs/adr/` has no matches, as predicted, and stays in the pathspec so the
scope is stated rather than implied.

### T3 — merged at `8d063ef`

`tests/skills.bats` `1..56`, `tests/lib.bats` `1..101`, `tests/portability.bats`
`1..10`, all 0 not ok. 124 sites swept across five files. Sixteen `@test` names
renamed, none of them cited outside `docs/verification/`.

Both pinned names from T2 were produced exactly, checked by the dispatcher with
`grep -cFx` at the named line numbers.

**A sixth pinned name, for T4.** `tests/portability.bats:106` now cites a test
in `tests/finish-merge.bats`. T4 must rename line 379 to exactly:

`finish-merge: derives the worktree path under an awk that rejects a newline in -v`

**Mutation evidence was checked in both directions, not assumed.** T3 replayed
all 47 mutation scripts that write `scripts/lib.sh` against the swept tree and
against the base revision, and the results are identical: 34 apply before and
after, and the same 13 fail with `mutation did not apply: 0 matches` in both.
This sweep broke no mutation anchor.

**Thirteen `lib.sh` mutation anchors were already stale at `3714f08`.** The
dispatcher verified this independently: it made a scratch checkout of the base
revision with `git archive` and replayed four of the thirteen there, and all
four failed on their anchor assertion while the control `M81` applied with
status 0. The mutation evidence those thirteen produced is no longer
reproducible from the records that cite it.

This is a pre-existing defect in merged evidence. It is not caused by this
change, this change does not widen it, and fixing it means re-cutting thirteen
anchors and re-proving each — its own change, with its own record. This record
states it so that a later change does not have to rediscover it.

### T4 — merged at `f8147a4`

`tests/skills.bats` `1..56`, `tests/check-signing.bats` `1..31`,
`tests/finish-merge.bats` `1..30`, `tests/lib.bats` `1..101`,
`tests/portability.bats` `1..10`, all 0 not ok. 138 sites swept, 16 `@test`
names renamed.

All four pinned names were produced exactly and re-checked by the dispatcher
with `grep -cFx` across `tests/*.bats`: one match each.

**This plan was wrong about M81's killing test.** Step 3 states the mutated tree
must report `not ok` from `tests/check-signing.bats`. It does not, and it did
not at the base revision either: `check-signing.bats` reports `1..31`, 0 not ok
with the mutation applied. M81 is killed by `tests/lib.bats` test 60, `every
script stops outside a git repository, at gr_root`. The dispatcher re-proved
this after the merge: the re-cut anchor applies at exit 0, `tests/lib.bats`
reports `1..101` with exactly 1 not ok, and that one is test 60.

The anchor was re-cut from `the script carried on in the caller's directory` to
`the script continued in the caller's directory`. Mutation evidence is intact.

**No mutation script writes `scripts/finish-merge.sh`.** The 184 scripts target
three files only: 40 `lib.sh`, 38 `check-trace.sh`, 1 `check-signing.sh`.

**`tests/check-signing.bats` has no mutation evidence of its own.** Its 31 tests
kill nothing in `scripts/check-signing.sh`, because the only mutation aimed at
that script is killed elsewhere. Not caused by this change and not acted on
here.

**Two more stale citations for the rename map**, both in merged records D1
leaves alone: `docs/verification/2026-09-01-task-worktree-containment.md:61` and
`docs/verification/2026-09-10-field-report-items.md:141`.

**Commit before proving a mutation.** Step 3's `git checkout <script>` discards
an uncommitted sweep of that file. T4 lost its sweep once this way and reapplied
it.

### T5 — merged at `31d2359`

`tests/skills.bats` `1..56`, `tests/check-ids.bats` `1..44`,
`tests/check-trace.bats` `1..260`, all 0 not ok. 112 sites swept, ten `@test`
names renamed, `sat` left alone as D3 requires. No literal assertion was found:
no message either script prints contains a swept word, so no assertion changed.

**T4's mutation census is wrong, and this plan repeated it.** T4 counted only
the `p = 'scripts/...'` form and concluded the 184 scripts target three files.
T5 counted every write form, and the dispatcher confirmed the count
independently by extracting every `scripts/*.sh` path from all 184:

| Script | Mutations that write it |
|---|---|
| `lib.sh` | 57 |
| `check-trace.sh` | 48 |
| `check-review.sh` | 28 |
| `check-ids.sh` | 24 |
| `new-id.sh` | 17 |
| `finalize-docs.sh` | 6 |
| `finalize-ids.sh` | 6 |
| `check-signing.sh` | 1 |
| `finish-merge.sh` | 0 |

T4's one correct conclusion is the last row: nothing mutation-tests
`scripts/finish-merge.sh`.

**`scripts/finalize-ids.sh` does not exist.** It was removed at `c672c9f`, and
six mutation scripts in `2026-08-20-scan-pathspec.mutations` still write to it.
Those six cannot be re-proved against this tree at all.

**Stale mutation evidence, measured so far.** T3 found 13 stale anchors in
`lib.sh`. T5 replayed all 72 scripts that write `check-trace.sh` or
`check-ids.sh` against the unswept tree and found 15 more already stale, then
replayed the same 72 against the swept tree and got a byte-identical result
file, failure reasons included. The dispatcher's six add to that. **At least 34
of 184 mutation scripts no longer reproduce the evidence recorded for them**,
and `check-review.sh` (28) and `new-id.sh` (17) are not yet measured.

None of this is caused by this change, and no replay differs before and after
any sweep in it. It is its own change.

### T6 — merged at `673b684`

`tests/skills.bats` `1..56`, `tests/check-review.bats` `1..61`,
`tests/new-id.bats` `1..28`, `tests/finalize-docs.bats` `1..31`,
`tests/check-units.bats` `1..32`, `tests/units-chain.bats` `1..5`,
`tests/portability.bats` `1..10`, all 0 not ok. 75 sites swept, 15 `@test` names
renamed. The pathspec became the full D1 list in this task, so `scripts` and
`tests` replaced every per-file element T3 to T5 had added, and it is not
widened again.

Red observed before the sweep: `not ok 55 clanker: no file in scope contains the
replaced vocabulary`, reporting 75 sites, the first of them
`scripts/check-review.sh:9`. The plan predicted about 77.

Files touched, with the diff against the preceding commit:
`tests/skills.bats` (pathspec only), `scripts/check-review.sh` +17/-17,
`tests/check-review.bats` +14/-14, `scripts/new-id.sh` +12/-12,
`tests/new-id.bats` +10/-10, `scripts/finalize-docs.sh` +10/-10,
`tests/finalize-docs.bats` +6/-6, `scripts/check-units.sh` +6/-6,
`tests/check-units.bats` +2/-2, `tests/units-chain.bats` +1/-1. Every changed
line is prose, a comment, a printed message or a test name, and every changed
message's assertion changed in this task.

**The scan was proved by deletion, and that proof is the point of this change.**
`load-bearing` was reintroduced at `scripts/check-units.sh:108` — a file the
pathspec reaches only through this task's widening — and `tests/skills.bats`
reported `not ok 55` naming that file and that line. Reverted, the file is
green. An independent reviewer reproduced this proof.

The agreement test was proved the same way and separately. `says -> states` was
removed from the shipped replace list, and the file reported `not ok 54 clanker:
the word table and the shipped replace list name the same words`, printing 8
shipped words against 9 table keys. Reverted, the file is green.

**Mutation evidence.** T5's census gives 28 mutation scripts writing
`check-review.sh`, 17 writing `new-id.sh` and 6 writing `finalize-docs.sh` — 51,
the naive count of every `scripts/*.sh` mention. 48 of those 51 write one of the
three; the other three name a path without writing it. This task replayed all
51 rather than the 48, before the sweep and after it. 47 applied. Four were
already stale before this task edited anything:
`2026-08-22-id-tokens.mutations/M09.sh`, `M16.sh`,
`2026-08-22-id-tokens.mutations/M39.sh`, which writes `finalize-docs.sh`, and
`2026-08-23-review-artefact.mutations/M03.sh`. The replay after the sweep is
byte-identical to the replay before it, failure reasons included, so this sweep
broke no anchor and repaired none.

Those four raise the measured total of stale mutation evidence to at least 38 of
184: 13 in `lib.sh` (T3), 15 across `check-trace.sh` and `check-ids.sh` (T5),
six writing `scripts/finalize-ids.sh`, which was removed at `c672c9f`, and these
four. None of it is caused by this change.

**`scripts/check-units.sh` has no mutation coverage at all.** No `M*.sh` writes
it, so nothing measures whether `tests/check-units.bats` would report a defect
in it. This is the third such hole the change found — `scripts/finish-merge.sh`
has no mutation writing it (T4) and `tests/check-signing.bats` kills nothing
(T4). Not caused by this change and not acted on here.

## Fix-round records

The six tasks above built the change. Four further commits fixed what three
review rounds found, and the second round's finding-10 was that they had no
records. They are recorded here in the same shape as T1 to T6, with
the same rule: a figure this record's author measured is stated as measured,
and a figure observed by another party is attributed to that party.

`@test` counts, measured with `git grep -h '^@test ' <rev> -- 'tests/*.bats' |
wc -l`: 688 at `main`, 689 at `673b684`, 689 at `c3ec7d6`, 692 at `4254ff1`,
692 at the merge `1357cf5`, 692 at `892d7a7`, and 692 at `520e1e0`. The three
tests F1 adds are the whole difference between 689 and 692, F4 adds none, and
the gate row in the verification record states 692 for that reason.

### F1 — merged at `4254ff1`

Fixed review round 1's findings 1, 2, 3, 7, 8 and 9. 24 files, +163/-60;
`tests/skills.bats` alone is +145/-14 of that, and the other 23 files are
+39/-39, every one a substitution.

Three tests added to `tests/skills.bats`, taking it from 56 to 59 and the suite
from 689 to 692:

- `clanker: every word-table key is among the forms the scan reads for it` —
  a key whose own spelling is missing from its form list means the scan does
  not read the word the shipped rule names (finding-1).
- `clanker: the scan's own grep reports every form in the word table` — the
  form canary. Each form is written into a file twice, lower case and upper
  case, and the scan must report every one; the upper-case half is what pins
  `grep -Eiw` against `grep -Ew` (finding-1).
- `clanker: every tracked file is in the scan's scope or named out of it` —
  the complement of the pathspec over `git ls-files` must be exactly
  `docs/plans/`, `docs/verification/`, `LICENSE` and `.gitignore`. D1 claimed
  totality and nothing checked it; the reviewer had cut the pathspec to three
  elements and added an unscanned tracked file, both with the suite green
  (finding-2).

The exemption guard was changed from counting files to counting openers, and a
closer check was added for the markdown regions (finding-3).

The word table gained the bare `hold` and the bare `say`, and the sweep of
those two forms is the +39/-39 across 23 files. Four idiom casualties of the
earlier sweep were restored in the same commit, with an exemption behind each:
`the skill now states so` back to `says so`, `because we stated so` back to
`said so`, `it scanned nothing and stated so` back to `said so`, and the test
name `gr_check_config states so when it cannot read the config at all, before
any scan` back to `says so` — which is why the rename map has 57 rows and not
58 (findings 7 and 8).

**Attestation, not measurement.** The subagent that made these fixes is the
only party that watched each new test fail before its fix; this record's author
did not, and no red count from that task reached this plan. What is measured
here is the tree: the three tests exist, the suite is 692, and the dispatcher's
attacks below redden them on demand.

### F2 — merged at `4c3e04d`

Fixed review round 2's findings 7, 8 and 19, and most of finding 2. 7 files,
+162/-59; `tests/skills.bats` is +156/-53 and the other six files are +6/-6.

Four things, and the last is the one that matters:

1. `SAID SO` is restored at `scripts/check-review.sh:311`. F1's exemption chain
   was a hand-written case-sensitive `sed`, so the all-capitals form of an
   exempt idiom could not be exempted and had been rewritten into non-English
   to keep the file green. The chain is replaced by `gr_writing_exemptions`,
   seven `path|phrase` entries compiled by `awk` into one `sed` script with
   every letter written as a bracket pair, because `sed`'s own `I` flag is not
   POSIX.
2. The bare `say` is removed from the word table, and five correct English uses
   that F1's sweep had deleted are restored from the base revision:
   `skills/worktree-discipline/SKILL.md` "explicit say-so", `scripts/lib.sh`
   "(ADR, say)", `skills/ratchet/SKILL.md` "(no network to vendor bats-core,
   say)", `templates/AGENTS-block.md:22` "`a3k9z2`, say", and
   `skills/check-traceability/SKILL.md` "block, say". D4 now states why the
   bare `say` is the one form deliberately left unscanned.
3. The scan is factored into `gr_writing_scan`, and both the canary and the
   scan test call it. Before this, the canary had a `grep` of its own, so
   it proved only itself: dropping `-i` from the scan, or exempting a whole
   word, left every test green over a scan that had stopped reporting.
4. The canary names the forms it could not read, using `comm` against the form
   list rather than a count, and branches separately on a `grep` that exits 2
   without running. A bare count named no form at all when the alternation was
   invalid.

### F3 — merged at `892d7a7`

Fixed review round 2's finding 1. One file, `tests/skills.bats`, +12/-0.

A floor in the form canary: the word table must name at least 58 form
spellings before the canary scans anything. Every other check compares the
table against itself — the agreement test compares its keys to the shipped
replace list, the key-among-forms test compares each row to its own key — so a
table reduced to `carries carries`, `lands lands` and so on is self-consistent,
and the scan then reads no inflection at all with every test green. The shipped
replace list names one word per rule and cannot supply inflections, so no
external source can pin them and a floor is what remains.

Measured here: the table yields 29 distinct forms, 58 spellings with the
upper-case half, so the floor is set at the value it guards and one deleted
form reports. The test states in its own comment that the floor is raised when
a row is added and that lowering it is the edit the guard exists to expose.

### F4 — merged at `520e1e0`

Fixed review round 2's findings 3, 4 and 6, and round 3's findings 2, 3 and 4.
One file, `tests/skills.bats`, +86/-4. No test is added or removed: the file is
still `1..59` and the suite is still 692.

Five guards, each aimed at a place where the scan's own configuration could be
edited with the suite green:

1. **The exemption list has a fixed size.** `gr_writing_exemptions` must
   contain exactly seven entries. One added entry removes a phrase from every
   line the scan reads, anywhere in scope, and no other check reports the
   addition: the form canary feeds the scan one form per line and every
   exemption is a phrase. Pinning the count makes an eighth entry an edit in
   two places, which appears in the diff as a changed expectation (round 3's
   finding-2).
2. **The compiled exemption script is validated before the scan reads a
   file.** An entry with an empty phrase compiles to a substitution with an
   empty pattern; BSD sed exits 1 on it, grep then reads an empty stream and
   exits 1 as well, and a scan that never ran is indistinguishable from a clean
   tree. `gr_writing_scan` compiles the script against no input and returns 2
   if that fails, which is the exit-status contract its own comment already
   stated and the scan test already branched on (round 3's finding-3).
3. **The section closer is named once.** `gr_writing_section_closer` is read by
   the scan and by the guard that reports an unclosed region. Kept apart, the
   guard matched its own copy, so a one-character edit to the scan's copy
   widened the exemption to end of file with the guard green (round 3's
   finding-4).
4. **Both exempt regions are bounded, not merely closed.** A writing section
   longer than 35 lines, a word table longer than 45, or either reaching end of
   file, is reported by name and line; the word-table region is reported as
   well when it swallows another function declaration, which is what indenting
   its closing brace does. A region that closes somewhere was not enough: the
   closer could be moved down over an arbitrary span. The regions are 21, 21
   and 30 lines today, so each bound leaves room to edit the rule text and none
   to re-close a region around a document (round 2's findings 3 and 4).
5. **The two statements of the rule are compared.** The agreement test parses
   the replace list out of `AGENTS.md` as well as out of
   `templates/AGENTS-block.md` and requires them to name the same words. They
   are one rule stated twice, and a word added to either alone would leave
   adopters and this tree following different lists (round 2's finding 6).

**Proved by breaking each one.** The dispatcher applied each attack, ran
`tests/skills.bats`, observed the result and reverted the attack:

| Attack | Result |
| --- | --- |
| Add an eighth exemption entry, with a line matching it planted in the tree | `not ok 58`. The same pair of edits produced no `not ok` at all before guard 1, with all 59 tests green |
| Give an exemption an empty phrase | `not ok 58` |
| Change the scan's copy of the section closer | `not ok 58`, `a writing-section exemption reaches end of file` |
| Demote the heading that closes the shipped block's writing section | `not ok 58`, `templates/AGENTS-block.md:68: writing section, 42 lines` |
| Indent the word table's closing brace | `not ok 58`, `tests/skills.bats:46: word table swallows gr_writing_forms() {` |
| Add a word to `AGENTS.md`'s replace list alone | `not ok 54`, `AGENTS.md and the shipped block name different words` |

Test 54 is the agreement test and test 58 is the scan test, which is where four
of the five guards run. Confirmed by this record's author at this head by
running the file alone: `1..59`, 59 ok, 0 not ok, so the two numbers above name
the tests they are said to name.

**What these guards do not do.** A bounded region is still exempt for whatever
is written inside the bound, and the scope guard's exclusion list is still an
inline copy of D1's prose with nothing comparing the two. Both are in the
verification record's Gaps, the second as the one finding left open.

### The dispatcher's attacks on F1 to F3, run on the merged tree

F1 to F3 were proved after the merge, by the dispatcher, on the tree that
ships. F4's own attacks are in its record above. Each attack was applied, the suite was run, and the attack was
reverted:

| Attack | Result |
| --- | --- |
| Drop `-i` from the scan's `grep` | `not ok 56`, the form canary |
| Add a global exemption for one word | `not ok 56`, the form canary |
| Delete the word table's rows | two tests redden |
| Reduce every table row to its bare key | `not ok 56`, the form canary |
| Restore `SAID SO` with a case-sensitive exemption | the scan test reddens |

**The first attempt at the `-i` attack was a no-op and proved nothing.** It
edited a line that does not exist, the suite stayed green, and a green suite
under an attack reads exactly like a guard that works. The attack counted only
once it was aimed at the real invocation inside `gr_writing_scan`, and then it
reddened the canary immediately. That is the lesson worth keeping from this
round: an attack that never reaches the code path is indistinguishable from a
guard that works, so an attack is evidence only once the edit it makes is
confirmed to be in the path under test. It is the same defect as F2's item 3,
one level out: there, a canary beside the scan proved only itself; here, an
attack beside the scan disproved nothing.
