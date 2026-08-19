# Verification Record — the item-placement gate

**Change:** `MISPLACED-ITEM` — an item defined outside the document configured
for its prefix is reported and fails the check.
**Plan:** `docs/plans/2026-08-19-item-placement.md`
**Base:** `main` at `6c6a705` (change B, signed).
**Suite:** `env -u SSH_AUTH_SOCK sh tests/run-tests.sh` — **146 ok, 0 not ok**.
**Independent review:** three rounds, each reviewing the previous round's
fixes. 3 blocking + 10 non-blocking in total, all addressed below in "What the
review found". Every round but the last found a defect introduced by the
round before it.

## What was wrong

Change A recorded this gap in three documents and deliberately left it open:

> `checked:` counts items found anywhere in the tree, not items examined. An
> item defined outside the document configured for its prefix is counted here
> and read by no gate.

Reproduced before any code was written, on the standard fixture:

```
$ printf '**SDD-002**: a design item nobody reads\n' > docs/design.md
$ sh .guardrails/scripts/check-trace.sh
checked: REQ 1, HAZ 1, RC 1, SDD 2, LLR 1, PR 0
sources: srs 2, rmf 2, sad 3, soup 1, problems 1; strict 1, tests 1
$ echo $?
0
```

`SDD 2` — two design items counted, exit 0, and `SDD-002` carries no `traces:`
line at all. `UNTRACED-DESIGN` only reads the files `doc_sad` resolves to, so
moving that identical file into `doc_sad` turns the run red without changing a
character of its content. The verdict depended on where a file sat, and nothing
said so.

## Evidence

Derived by `tests/evidence.sh main` — do not edit by hand.

- Suite: **146 tests** (main: 135); 141 measured against `main`.
- New or renamed since `main`: **12**.
- Of those, **10** go red when run against `main`'s scripts.
- **2** cannot go red, and neither is counted as evidence that a defect was
  fixed:

  - `check-trace: correctly placed items are not reported as misplaced`
  - `every script is executable in the index, not just runnable via sh`

Both are guards, not RED tests, and both say so in their own bodies.

The first guards against over-firing. It passed before the gate existed
because the gate did. It is **not** uniquely pinned by any mutation: the one
that reddens it (`gr_contains` → `false`) reddens 19 others as well, and no
mutation reddens it alone. It is redundancy, kept because it states the
intent directly; the earlier draft of this record claimed mutation
"established its value", which overstated what the mutation shows.

The second guards a regression this change itself introduced and fixed — see
review finding 1. It cannot go red against `main` because `main` was correct,
which is the honest classification: it is a regression guard, not evidence of
a defect fixed relative to the base.

**This figure read 11 red / 1 that cannot in two earlier drafts, and was wrong
both times — the same way, for two different reasons.** Both were the mode
test failing against `main` for a reason that had nothing to do with `main`'s
behaviour, and being booked as evidence this change fixed something. It did
not; `main` was fine.

1. `tests/evidence.sh` staged the base scripts with
   `git show "$base:$f" > file`, which creates the file 0644 whatever the
   blob's mode. It now applies the mode from `git ls-tree`.
2. After the test was rewritten to assert against `git ls-tree -r HEAD`, it
   failed in the base run because `evidence.sh` stages into a plain temporary
   directory with no git in it at all. It now skips there.

Recording this because the pattern is the point: a test that fails in the
measurement harness for harness reasons inflates exactly the number a reader
uses to judge the change, and it does so silently. Both fixes make the figure
smaller.

## Mutation testing

Every mutation applied to a scratch copy, whole suite re-run, reddened tests
cited by name. A mutation that applied cleanly but reddened nothing would mean
the test does not constrain the code; none did.

| Mutation | Tests reddened |
|---|---|
| `ids_defined_in` scans `.` instead of `-- "$@"` | **9**: the six per-prefix misplacement tests, plus subdirectory, non-`.md` and every-item. `correctly placed items are not reported as misplaced` stays green — the correct signature for "the gate stopped firing". |
| `gr_contains "$_inside" "$_id"` replaced by `false` | **20**, including `check-trace: correctly placed items are not reported as misplaced` and `check-trace: fully traced fixture passes`. The correct signature for "the gate fires on everything". |
| Rule 2's `HAZ\|RC) _home="doc_rmf"` narrowed to `HAZ)` | 1: `check-trace: RC declared without doc_rmf is rejected, not left unplaceable` |
| `PR)` dispatch arm deleted | 1: `check-trace: a PR defined outside doc_problems is reported` |
| `REQ)` dispatch arm deleted | **4**: `a REQ defined outside doc_srs is reported`, `an item in a subdirectory of its doc directory is reported`, `an item in a non-md file inside its doc directory is reported`, `every misplaced item is reported, not just the first` |
| `SDD\|LLR)` narrowed to `SDD)` | 1: `check-trace: an LLR defined outside doc_sad is reported` |
| `break` after `fail=1` in `check_placement` | 1: `check-trace: every misplaced item is reported, not just the first` |
| `gr_doc_files` glob `*.md` → `*` | 1: `check-trace: an item in a non-md file inside its doc directory is reported` |

**Every row above was re-derived after the second review round; do not trust a
row that was not.** Two were stale when the reviewer checked them — the first
read 7 and the fifth read 2, because three tests were added after the table
was written and never folded in. That is the staleness `tests/evidence.sh`
exists to prevent, in the one document whose subject is honesty about
evidence. The counts here come from running all eight mutations in one pass
against the current tree.

`every script is executable in the index, not just runnable via sh` has no
mutation row, and the reason given here in an earlier draft was wrong. It
claimed a scratch copy shares this worktree's gitdir; it does not — a copy of
a worktree is not a repository at all, so the test `# skip`s there. That is
why no mutation of the tree under test can redden it. It is demonstrated
directly instead, on separate throwaway repos — see review finding 1.

The `break` and `*.md` → `*` rows were added after the first review round;
before their tests existed each reddened nothing, so AC6 and the resolution
rule were asserted and constrained by nothing.

The `SDD|LLR` → `SDD` mutation exists because the LLR test was written **after**
its implementation — task 1's arm was `SDD|LLR`, so the LLR test in task 2 passed
the moment it was written. That is a TDD deviation and is recorded rather than
smoothed over; the mutation is what establishes the test bites.

## Corpus regression

Clean clone of `sightings-app` at `4909a1ab` — never the user's working tree,
which was confirmed at 0 dirty files before and after. Re-run at that exact
commit after the review corrections. The reviewer independently ran the same
comparison at the corpus's newer HEAD `0a582f9d` (270 items) and got the same
result, so the conclusion holds at both commits.

`check-trace.sh` and `check-ids.sh` run from merged `main` and from this
branch, both with the corpus's own config: **byte-identical output**, exit 0
from all four runs.

```
checked: REQ 101, HAZ 4, RC 10, SDD 26, LLR 33, PR 70
sources: srs 19, rmf 8, sad 5, soup 1, problems 37; strict 5, tests 3
```

**244 items across the six gated prefixes, zero misplaced.** That was measured
before the plan was written and is why this gate lands as a hard failure with
no compatibility flag and no grace period: on a project already keeping its
items in the configured ledgers it reports nothing, so its cost falls only on a
project that has the defect.

## The one reversal, and why it is not an oscillation

Change B's round 1 rejected `RC) _need="doc_rmf doc_srs"` on the ground that no
RC gate read `doc_rmf`, and added a test — `check-trace: RC without doc_rmf
still runs its gate, and is not rejected` — pinning that. That was correct at
the time: `UNIMPLEMENTED-CONTROL` reads `doc_srs`, and nothing looked at where a
control was *defined*.

This change makes an RC gate read `doc_rmf`, so the premise is gone. The test
was rewritten rather than deleted, keeping its subject and recording the
reversal in its own body. Observed behaviour without the config rule:

```
MISPLACED-ITEM RC-001 (must be defined in the files doc_rmf resolves to)
checked: REQ 1, RC 1, SDD 1, LLR 1, PR 0
sources: srs 2, rmf 0, sad 3, soup 1, problems 1; strict 1, tests 1
```

(Regenerated after the message rewording, from a build with rule 2 removed —
`rmf 0` is the tell.) It names a key the project never configured, once per
control. `gr_check_config` now says it once, at exit 2,
before any gate runs.

`gr_check_config` was restructured into two explicitly separate rules rather
than one map with a changed entry, because they answer different questions:

- **Rule 1, gate inputs** — documents whose absence would *silently skip* a
  gate. Unchanged. `RC` still needs `doc_srs`.
- **Rule 2, definition documents** — the one document `MISPLACED-ITEM` requires
  each item to live in. Every entry except `RC`→`doc_rmf` was already required
  by rule 1, so rule 2 rejects exactly one new shape.

Rule 2's justification is deliberately *not* "a gate would be silently
skipped", which would be false: unconfigured, the placement gate runs and
condemns everything. It is that `doc_rmf` is the only document an RC may be
defined in, so declaring RC without it configures a project where no control
can ever be correctly placed.

## What the review found

One independent round. It re-ran the suite, all six recorded mutations, four of
its own, a corpus regression and portability runs under `dash`, `busybox sh`,
`mawk` and `busybox awk`. It confirmed the gate itself is sound and rule 2
complete, and found two blocking defects anyway.

**1 — BLOCKING. The change silently dropped the executable bit** from
`scripts/check-trace.sh` and `scripts/lib.sh` (100755 → 100644). Cause: two
edits applied as `awk … > tmp && mv tmp scripts/…`, where `mv` carries the
temp file's 0644 mode across. Every skill and template documents invoking the
script *by path*, and `skills/ratchet/SKILL.md` installs "keeping executable
bits", so the 644 would have propagated into every target project as exit 126:

```
$ .guardrails/scripts/check-trace.sh; echo "EXIT=$?"
permission denied: .guardrails/scripts/check-trace.sh
EXIT=126
```

The whole suite was blind to it because every test invokes `sh <path>`, which
does not need the bit. Fixed by restoring the modes and adding a test.

The first version of that test invoked one script by path, and the second
review round showed it closed one instance of four: `chmod 644` on the other
three scripts left the suite fully green. It also depended on the filesystem
honouring the bit. It is now
`every script is executable in the index, not just runnable via sh`, which
asserts mode `100755` over `git ls-tree -r HEAD scripts/` — every script,
filesystem-independent, and against what git actually carries into other
projects. Demonstrated on a throwaway repo built from these same scripts with
`check-ids.sh` at 0644 — the file the old test could not see:

```
not executable in the index: scripts/check-ids.sh (100644)
```

Fixing the same blindness in `tests/evidence.sh` is what corrected the
evidence figures above.

**2 — BLOCKING. The gate's message stated something the same run disproved.**
It read `(defined outside <key>, so its gates never see it)`. False: `ids_defined`
scans the whole tree, so `MISSING-TEST`, `UNMITIGATED-HAZARD` and
`UNIMPLEMENTED-CONTROL` all still enumerate a misplaced item. One run printed
both lines for the same ID:

```
MISPLACED-ITEM REQ-002 (defined outside doc_srs, so its gates never see it)
MISSING-TEST REQ-002 (no direct 'verifies:' and no tested LLR satisfies it)
```

What actually goes unread is the item's own block — its `traces:`,
`satisfies:`, `implements:`, `mitigates:` and `status:` lines are parsed only
out of the configured document. The new tests themselves showed I knew this:
each had to add the annotation that would otherwise have fired a second gate.

Second half of the same finding: "outside `doc_srs`" is wrong for a `.txt`
sitting **inside** the configured directory. `gr_doc_files` resolves a
directory to its `*.md` files one level deep, so such a file is outside what
the key resolves to while being inside the directory — and the documented
remedy ("move it into that document") was already satisfied, leaving the
operator nothing to act on.

That rewording was itself wrong, and the second review round caught it — see
finding 8 below. The message now states the rule alone:
`(must be defined in the files <key> resolves to)`.
`check-trace: an item in a non-md file inside its doc directory is reported`
pins the resolution case.

**3 — non-blocking. `templates/config.yaml` still stated the pre-change RC
rule** and was untouched by this change, so a project reading its own config
header would not learn that `RC` now also needs `doc_rmf`. The template's
framing ("every rule exists because a key was invisible to the reader") does
not fit rule 2, so it got its own bullet rather than an appended clause.

**4 — non-blocking. Two comments claimed a property no configuration can
exercise.** `ids_defined_in`'s empty-args guard was described as
"load-bearing" and `check_placement`'s absent guard as a live design choice,
but rule 2 plus `gr_doc_files` make both branches unreachable — the reviewer
proved it by instrumenting both and running the whole suite with no probe hit.
Both comments now say defence in depth and explain why the arms cannot be
empty.

**5 — non-blocking. AC6 was asserted and untested.** A `break` after `fail=1`
reddened nothing. Now covered.

**6 — non-blocking. The guard test's justification overstated the mutation
evidence.** Corrected in the Evidence section above.

**7 — non-blocking. Header residue** — a bare blank line and orphan `#` left
where the `KNOWN GAP` paragraph was deleted. Removed.

### Second round, on the fix commits alone

The delta above was not text-only — a changed user-facing message, two harness
changes and three new tests — so it went back for a focused round. One
blocking, and it was the same structural defect as finding 2.

**8 — BLOCKING. The reworded message was still disproved by its own run.** It
read `(not in the *.md files <key> resolves to, so the annotations in its
block are read by no gate)`. `DANGLING-REF` builds its scope from every
`doc_*` file plus `strict_paths` and `test_paths`, so an item misfiled into
*another ledger* — the likeliest misplacement of all — does have its
annotations read. Six "read by no gate" lines and six `DANGLING-REF`s drawn
from exactly those blocks, in one run:

```
MISPLACED-ITEM REQ-002 (not in the *.md files doc_srs resolves to, so the annotations in its block are read by no gate)
...
DANGLING-REF RC-901  (referenced but never defined)     <- from REQ-002's block
DANGLING-REF REQ-902 (referenced but never defined)     <- from SDD-002's block
```

Sharper still: a `verifies:` line inside a misplaced item's own block
suppresses `MISSING-TEST` for it. The annotation was not merely read, it
decided a gate's verdict.

The reviewer also showed the wording was wrong for a `doc_*` configured as a
single file (`*.md` is not what it resolves to — a supported shape with its own
back-compat test), and vacuous for `HAZ`, whose block carries no annotation any
gate parses either way.

**Two attempts at stating the consequence, both false in the run that printed
them.** The message now states the rule and nothing else —
`(must be defined in the files <key> resolves to)`. The consequence is true
only with three exceptions, and those are stated where there is room for them:
`skills/check-traceability/SKILL.md`, `README.md` and the gate's own comment
block, all of which now name the `DANGLING-REF` and `HAZ` caveats explicitly.

**9 — non-blocking. The by-path test closed one instance of four.** Addressed
under finding 1 above.

**10 — non-blocking. Two mutation rows were stale.** Addressed under Mutation
testing above; the whole table was re-derived.

**11 — non-blocking. `skills/ratchet/SKILL.md` still carried the purged
wording** ("counted in `checked:` and read by no gate") and omitted the
non-`.md` case that README and the skill had both gained. This is the file
that installs guardrails into target projects. Both fixed.

**12 — non-blocking. A pasted "Observed behaviour" block in this record still
showed the first message.** Regenerated from a build with rule 2 removed.

### Third round, on the second round's fixes

One blocking, nine non-blocking. The blocking one is recorded as gap 4 above:
the claim purged from the code in round 2 was still standing, present tense and
load-bearing, in this record's own gaps section.

The rest, all fixed:

**13 — the mode test read `HEAD` while its name and comment said "index".**
`git ls-tree` reads the commit; a 0644 staged with `git add` passed. The
accident it exists to catch reaches the index first, so it now reads
`git ls-files -s`. Demonstrated: with `finalize-ids.sh` chmod'd and staged,
`HEAD says: 100755` / `index says: 100644`.

**14 — the mode test could exit 0 having examined nothing.** No assertion that
the loop saw any script: guardrails unpacked inside another repo answers
`git rev-parse` fine, lists no `scripts/`, and every assertion goes vacuous.
That is precisely the shape `require_paths` and `gr_doc_files` exist to
forbid, reproduced inside the test suite whose subject is that shape. It now
counts what it examined and fails with "this test proved nothing" at zero.

**15 — the stated reason for the missing mutation row was false.** It claimed
a scratch copy shares this worktree's gitdir. It does not: a copy of a
worktree is not a repository, so the test skips there. Corrected above.

**16 — the header said "one round"** while the body carried a second. Corrected.

**17 — the HAZ caveat was false.** It said a misplaced HAZ blinds no gate.
`UNANALYZED-DERIVED` is a free-text grep over `$rmf_files`, so a derived item
assessed inside a hazard's block stops being assessed when that block leaves:

```
=== HAZ-002 block, holding LLR-003's assessment, in the RMF ===
checked: REQ 1, HAZ 2, RC 2, SDD 1, LLR 2, PR 0        EXIT=0
=== same block moved to docs/stray.md ===
MISPLACED-ITEM HAZ-002 (must be defined in the files doc_rmf resolves to)
UNANALYZED-DERIVED LLR-003 (derived item not assessed in the RMF)   EXIT=1
```

It fails red, so nothing passed silently — but the claim was wrong and is now
corrected in all three places. `README.md` also lacked the HAZ caveat the
gate's comment claimed it carried; it has it now.

**18 — `templates/config.yaml` described unreachable behaviour as current.**
Rule 2 rejects the shape before any gate runs, so the "condemns every item
once each" outcome is never observed. Reframed as the counterfactual it is —
this file is copied into every target project.

**19 — a test comment still carried the v1 model.** Two of its three siblings
were rewritten in the previous commit; this one was missed.

**20 — a symlinked ledger file reports.** Recorded as gap 6 rather than
changed: it fails red and the definition does live outside.

**21 — the plan's AC1 and AC4 still specified the rejected message.** Since
AC1–AC8 are this change's requirement of record, an implementation that does
not satisfy AC1 is a deviation in the requirement, not just in the record.
Both criteria are amended in `docs/plans/2026-08-19-item-placement.md` under
"Amendments to the acceptance criteria".

Two things the reviewers could not confirm, carried here rather than dropped:
`shellcheck` is not installed in this environment, so whether the
`# shellcheck disable=SC2086` directives before each `case` pattern actually
apply to the arms is unverified; and its corpus run used the newer HEAD
`0a582f9d` rather than the `4909a1ab` this record names — since re-run at
`4909a1ab` with the same result.

## Gaps this change leaves open

1. **Placement covers the six gated prefixes only.** An extra declared prefix
   (`ADR`) has no configured document, so its items are still counted in
   `checked:` without being examined. Stated in the script header, the README
   and the skill rather than left implicit.
2. **An ID defined both inside and outside its document is not reported.**
   `_inside` contains it, so placement is satisfied by the correctly-placed
   copy; the stray one is left to `check-ids.sh`'s `DUPLICATE-ID`. Two gates
   between them cover it, but neither says "this specific copy is unread".
3. **Illustrative IDs at column one are indistinguishable from definitions.**
   `**REQ-001**:` written as an example in a plan or changelog is a definition
   as far as every scan here is concerned, and will now be reported. The remedy
   is documented in three places (write `**REQ-NNN**:`), but it is a convention
   the tooling cannot enforce. Not triggered anywhere in the corpus.
4. **`doc_*` directories resolve to `*.md` one level deep** (`gr_doc_files`
   expands `"$dir"/*.md`); a `doc_*` configured as a single file resolves to
   that file whatever its extension. An item in a subdirectory, or in a
   non-`.md` file sitting directly in the directory, is not among the files
   the key resolves to, so the gate keyed on that document never parses its
   block — reporting it is correct. A project that organises its ledger into
   subdirectories, or keeps a `.txt` in it, will still read the message as a
   false positive. Both cases are pinned by tests so the resolution rule is a
   decision rather than an accident.

   The wording of this gap was itself the third-round blocking finding: it
   still read "genuinely unread by its gates", the exact claim rounds 1 and 2
   had already disproved, in a document that calls that wording disproved
   forty lines above. Purging a false claim from the code and leaving it in
   the record is not purging it.
5. **This repo still runs no guardrails on itself.** No `.guardrails/config.yaml`,
   no SRS, so this change has no REQ ID; its requirement is written as AC1–AC8
   in the plan instead. Carried forward unchanged from the change A and change
   B records.
6. **A symlink inside a ledger directory reports.** `gr_doc_files` globs the
   directory, so a symlink named `*.md` in it is listed in `sources:` and the
   awk gates follow it — but `git grep -- <path>` does not, so
   `ids_defined_in` never sees the definition and the item is reported. It
   fails red and the definition genuinely lives outside, so the verdict is
   defensible; no document covers symlinked ledger files either way. Found by
   the third review round.

7. **`safety_class` is not consulted by the placement gate.** Like every other
   gate here, it applies identically at class A, B and C.

## Files

See `git diff --stat main`.
