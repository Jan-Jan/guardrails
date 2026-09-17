# Verification — close-kw-asymmetry (2026-09-16)

branch: close-kw-asymmetry
reviewer: independent subagent reviewers, one per round, each dispatched fresh at `merge-change` step 6a into `.worktrees/close-kw-asymmetry-review` with the diff, the plan, the record and the problem items, and with no implementation narrative and no chat history. Four rounds. Each ran the suite itself in its own worktree and reported the counts it measured rather than counts it was handed.
verdict: REJECT on all four rounds — 12, 10, 7 and 10 findings. No round after round 2 found a defect in executable code; every later finding was in prose, and most were in this record. The findings are summarised by what they changed under Review rather than transcribed, for the reason the single finding there states. Round 4's verdict stands: it confirmed the code and rejected the prose, and the two documents it named — `scripts/lib.sh` and `skills/ratchet/SKILL.md` — were corrected after it reported. Nothing re-reviewed those corrections, which is stated in Gaps rather than left to be inferred.
reproduced: Yes, before any code was written, in a probe tree built outside the repository. Four fixtures: the column-one annotation outside every block reported `ORPHAN-ANNOTATION`; the same line with a list marker was silent; an LLR with no `satisfies:` reported `UNSATISFIED-LLR`; the same LLR with a bulleted `satisfies:` inside its block was silent, the bullet credited. The last two are the pair that matters — the reader accepted a form the backstop could not see. The fixture needed an explicit `## Notes` heading, because a bare paragraph does not close an item block and a first attempt therefore measured nothing.

Change: the ORPHAN-ANNOTATION backstop learns two list-marker forms while every
reader stays at column one — a PARTIAL fix for `PR-h3wujj`, which stays OPEN
because three review rounds each found a list form the round before had called
closed, the third (`- [x] satisfies:`) unfixed here; and the report catalogue in
`skills/check-traceability` regains three rows its script has printed since
`d8502d1`, closing `PR-6d2jvt`. Branched from `main` at `d8502d1`; `main`
advanced to `3714f08` mid-change and was merged in at `7026812`.
Plan: `docs/plans/2026-09-15-close-kw-asymmetry.md`.

**Base merged from local `main` at `3714f08`, per AGENTS.md non-negotiable 5.**
The remote was out of scope by policy, not skipped by accident.

**This change was opened while `clanker-adoption` was still open**, against
AGENTS.md non-negotiable 4, on the user's explicit instruction of 2026-09-15
("go ahead and work, it seems `clanker-adoption` is having a hard time
converging"). The cost was not hypothetical and is recorded here rather than
in a conversation: `clanker-adoption` merged as `3714f08` while this change was
mid-flight, adding a vocabulary scan this change's prose had never been written
against and rewriting two of the three files it was editing. The base merge at
`7026812` had to resolve `skills/check-traceability/SKILL.md` **row by row** —
six rows from each side — because both sides had edited the same table for
different reasons, and taking either side whole would have silently dropped
real work. That is the race non-negotiable 4 exists to prevent, and it is the
trade the user took deliberately.

## The gate

Every figure derived from the tree under test, not carried forward.

**None of `check-trace.sh`, `check-ids.sh` or `check-review.sh` can run against
this repository**: all three exit 2 with
`guardrails: file not found: .guardrails/config.yaml`, because guardrails is
not itself a ratcheted project. An earlier draft of the plan exempted
`check-trace.sh` alone and left the other two standing as though they ran;
the review caught it (finding-10). The two script rows below are derived
against the synthesized config quoted in Gaps, which is the same config the
`2026-09-10-field-report-items` record quotes, so the figures are comparable
to that record rather than freshly invented.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` (**at `f84c72d`, the tree under merge**) | `1..712`, **712 ok, 0 not ok**, 0 skipped — counted from `^ok`/`^not ok` TAP lines, never from an exit code. Re-derived after the Review section was cut; unchanged from `248b2a1`, which is expected, because no test reads this file |
| `sh tests/run-tests.sh` (at `e0819f5`, before the second base merge) | `1..708`, 708 ok, 0 not ok — superseded |
| `sh tests/run-tests.sh` (at `9ffe60a`, before the round-2 fixes) | `1..698`, 698 ok, 0 not ok — superseded. The +10 is round 2's four ordered-marker tests, five scope-control pins and one regression pin |
| `finish-merge.sh --check close-kw-asymmetry` (step 6d, before any squash) | exit 0 at `f84c72d`. **It caught a real one first**: run before the round-4 review worktree had been removed, it exited 1 naming `.worktrees/close-kw-asymmetry-review` and refused. That is `PR-k77dzn`'s whole purpose — guard 4 answered before the signing handoff instead of after a spent key touch — demonstrated on this change rather than argued |
| `sh tests/run-tests.sh` (round-1 reviewer, independently, in its own worktree at `48d9204`) | `1..695`, **695 ok, 0 not ok** — the reviewer ran the suite itself rather than being handed counts. The 3-test difference to the 698 above is three ADDITIONS: `check-review: a quoted bulleted branch: does not claim the record`, `check-trace: a quoted bulleted status: does not outrank the item's own`, and `gr_kw_here rejects a list marker before the keyword`. Round 2 corrected this row (finding-21): it previously read "two regression tests plus one inverted test", but an inversion renames a test and adds nothing to a count. Re-derived by sorting `@test` headers at both commits — three additions, three renames, one inversion |
| `sh tests/run-tests.sh` (at `7026812`, immediately after the base merge) | `1..695`, 695 ok, 0 not ok — superseded |
| `sh tests/run-tests.sh` (baseline, at `d8502d1` before any edit) | `1..677`, 677 ok, 0 not ok — the tree this change started from |
| `check-ids.sh` (synthesized config, at `f84c72d`) | exit 1, **52 findings over 55 lines**: 51 `DRAFT-ID`, 1 `DUPLICATE-ID`, identical on `main` and so unchanged by this change. The `DRAFT-ID` lines are NOT all test fixtures: `docs/plans` 22, `tests` 21, `docs/verification` 5, `scripts` 2, `README.md` 1. Round 4 found the previous split here mis-derived — it was bucketed on a path appearing INSIDE the matched line rather than on the file the finding names, which invented a `.guardrails/docs/requirements` bucket and took one each from `tests` and `docs/verification`. A correct total is not a measured breakdown |
| `check-trace.sh` (synthesized config, at `f84c72d`) | exit 1, **27 findings**: 13 `DANGLING-REF`, 9 `UNRESOLVED-PR`, 4 `MISSING-TEST`, 1 `MISPLACED-ITEM`. `checked: PR 39`; `problems: open 9, accepted 0, oldest 21 days`. The ninth open item is `PR-h3wujj` itself, returned to the roll-call by this change rather than removed from it |
| `check-review.sh --branch close-kw-asymmetry` (synthesized config, at `f84c72d`) | exit 0, `checked: records 37, for close-kw-asymmetry 1, findings 1` — one finding after the Review section was cut, and the count is read from this file rather than asserted about it |
| Coverage, against the class target | Not configured for this repository; no coverage figure is claimed |
| Working tree | clean at `f84c72d` |
| Mutation corpus | 38 of 184 scripts fail to apply, on **both** `main` and this branch — independently re-measured by the round-1 reviewer. No anchor regression; the 38 are the standing corpus `PR-crcee5` tracks |

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| `PR-h3wujj` | `gr_kw_orphan_here accepts a list marker before the keyword` (tests/lib.bats) | Yes — the probe printed `ABSENT` for `- status: open` |
| `PR-h3wujj` | `gr_kw_here rejects a list marker before the keyword` (tests/lib.bats) | Yes — pinned after the redesign; it is the property both regressions turned on |
| `PR-h3wujj` | `check-trace: a bullet satisfies: outside every block is an orphan` | Yes — the gate printed only its summary at exit 0, no `ORPHAN-ANNOTATION` |
| `PR-h3wujj` | `check-trace: a bullet status: is not read as the problem status` | Yes — inverted after the redesign; pins `INCOMPLETE-PROBLEM PR-001`, the loud answer chosen over reading the bullet |
| `PR-h3wujj` | `check-trace: a quoted bulleted status: does not outrank the item's own` | Yes — `problems: open 0` at exit 0, the open item silently gone from the roll-call |
| `PR-h3wujj` | `check-review: a quoted bulleted branch: does not claim the record` | Yes — exit 0 with `for my-change 1`, the `other-change` record adopted as this change's |
| `PR-6d2jvt` | `check-traceability: every report a single-unit check-trace.sh run prints has a catalogue row` (tests/skills.bats) | Yes — `reports check-trace.sh prints with no row …: ACCEPTED-PR MALFORMED-SUPERSESSION NON-RECIPROCAL-SUPERSESSION` |
| `PR-h3wujj` | `gr_kw_orphan_here accepts an ordered list marker before the keyword` (tests/lib.bats) | Yes — the probe printed `ABSENT` for `1. status: open` |
| `PR-h3wujj` | `gr_kw_orphan_here accepts the paren form of an ordered marker` (tests/lib.bats) | Yes — same, for `1)` |
| `PR-h3wujj` | `gr_kw_orphan_here steps over a run of markers, not just one` (tests/lib.bats) | Yes — same, for `- 1. ` |
| `PR-h3wujj` | `check-trace: an ordered-list satisfies: outside every block is an orphan` | Yes — exit 0, summary only, no `ORPHAN-ANNOTATION` |
| `PR-h3wujj` | `check-review: an ordered-list disposition belonging to no finding is reported` | Yes — exit 0, `findings 0`, no `ORPHAN-DISPOSITION` |
| `PR-h3wujj` | `check-review: a bulleted disposition belonging to no finding is reported` | Yes — against `main`'s scripts it reports `findings 0` and no `ORPHAN-DISPOSITION`; **round 3 moved this row out of the scope-control list**, where it did not belong: it asserts a presence and it does fail on the base tree |

**ADDED after round 3 (findings 24 and 25).** The six rows above were missing.
The table was written at round 1 and never revisited, so none of round 2's
red-to-green evidence reached it while the prose beside it described that work
at length — and one genuine red-to-green test was filed as a scope control,
which round-2 finding-16 had already demonstrated it was not. The problem item
carried a THIRD, different list. **This table is now the single list**, and the
item points here rather than repeating it, because two enumerations of one set
is how they came to disagree.

**Scope controls, NOT red-to-green evidence**, listed here so they are not
mistaken for attestations — each asserts an ABSENCE, which is why none was
watched failing for the right reason: `gr_kw_orphan_here still rejects bare
indentation`, `gr_kw_orphan_here still rejects a bare number with no
delimiter`, `gr_kw_here rejects a list marker before the keyword`,
`gr_kw_here rejects an ordered list marker before the keyword`,
`gr_value reads from column one, and composes for the wider position`,
`check-trace: an indented grammar comment is still inert` and
`check-trace: an ordered-list satisfies: inside a block is still credited`.

`check-review: a bulleted disposition belonging to no finding is reported` was
in this list until round 3 and is now a red → green row above: it asserts a
presence and it does fail on the base tree, so it met neither half of the
definition this paragraph gives. `gr_kw_here rejects a list marker before the
keyword` moved the other way, out of the red → green table: round 3 measured it
GREEN against `main`, so its only red was against this change's own discarded
intermediate tree, which is an attestation about a tree nobody is merging.

**CORRECTED after round 2 (finding-18).** This paragraph previously said of the
first two that they were "green before and after" and that the round-1 reviewer
had "confirmed the labelling is honest by reverting the source and checking
these two stay green". That is false as written, and round 2 measured it:
against `main`'s scripts with this branch's tests, `gr_kw_orphan_here still
rejects bare indentation` is RED, because `gr_kw_orphan_here` does not exist on
`main`. The round-1 confirmation was performed on a test then named
`gr_kw_here still rejects bare indentation`; the redesign renamed it onto a new
function and the attestation was carried across the rename unchanged. "Scope
control" here therefore means *asserts an absence rather than a behaviour, and
was not watched failing for the right reason* — not *green against the base
tree*, which for a test naming a new function is impossible.

**Mutation anchor.** `docs/verification/2026-08-25-problem-triage.mutations/M30.sh`
quotes the whole `gr_value` body and died twice to this change — once when
`gr_value` was widened, once when the redesign reverted it. Re-cut both times,
and re-proved both times: applied, it kills exactly 1 test
(`check-trace: trailing whitespace on a field is not part of its value`), the
same count its original record gives.

## What was wrong, and what was built

`gr_kw_here` tested `index(line, kw) == 1` while `gr_id_run` finds its keyword
anywhere on the line. A bulleted `- satisfies: REQ-x` was therefore credited
inside an item block and reported by nothing outside one: exit 0 with a derived
item no gate ever checked. `lib.sh` had stated this as a KNOWN ASYMMETRY since
`47cde0b` (2026-08-23) and closed the `status:`/`opened:` half on 2026-08-25.

**The first implementation of the fix was wrong, and the independent review
caught it.** It widened `gr_kw_here` itself, on the stated principle that
"reader and backstop look in the same place". That principle is the error:
every scalar reader in the toolkit is FIRST-OCCURRENCE-WINS, so widening the
readers let a *quoted* bulleted form outrank the annotation an item actually
made. Two regressions were demonstrated, main-red and branch-green:

- a `PR` block quoting `- status: resolved` in its prose above its own
  column-one `status: open` left the roll-call entirely — `problems: open 0`,
  exit 0. That is verbatim the failure `check-trace.sh` describes as the reason
  the column-one anchor exists: "an open problem no merge would ever see";
- a verification record declaring `branch: other-change` that quoted
  `- branch: my-change` became the record FOR `my-change` at exit 0 — a pass
  over a review that never happened, which `check-review.sh` names as the
  hazard its first-wins rule exists to prevent.

**The invariant is containment, not equality: the backstop must see at least
what every reader sees, and may see more.** A reader taking a value from a
position the backstop cannot see is the hole; a backstop seeing more than the
readers is safe, because it reports and takes no value. The shipped shape is
`gr_kw_here` and `gr_value` byte-identical to `main`, a retained `gr_kw_lead`,
and a new `gr_kw_orphan_here` used by the backstops alone — `check_orphans` in
`check-trace.sh`, and the `ORPHAN-DISPOSITION` half of the `disposition:` rule
in `check-review.sh`, whose reader half stays narrow. A bulleted annotation is
consequently never read and IS reported where it belongs to no item; inside a
block it leaves the field missing, which is `INCOMPLETE-PROBLEM` or
`MISSING-RECORD`, and loud.

The second item, `PR-6d2jvt`, was found while reviewing this change's own edits:
`skills/check-traceability`'s report catalogue had no row for `ACCEPTED-PR`,
`MALFORMED-SUPERSESSION` or `NON-RECIPROCAL-SUPERSESSION`, all three shipped by
`d8502d1` the day before, and its `MALFORMED-STATUS` row told an author to
reject `accepted` — the ledger's only way to record a ruling. The gate added
with the fix derives both sides from the files rather than listing them, so the
next report added without its row is a red test.

## Review

Four independent rounds, each a fresh subagent dispatched at `merge-change`
step 6a with the diff, the plan, the record and the problem items, and with no
implementation narrative and no chat history. Each ran the suite itself in its
own worktree and reported what it measured. **All four returned REJECT**, with
39 findings between them: 12, 10, 7 and 10.

**This section deliberately does not transcribe them.** It did, for 29 of the
39, and that is the subject of the single finding below.

**What the rounds changed in executable code**, which is the part a later
reader needs:

- **Round 1** rejected the DESIGN, not the implementation. The fix had widened
  `gr_kw_here` itself, on the stated principle that reader and backstop "look
  in the same place". Every scalar reader here is FIRST-OCCURRENCE-WINS, so
  that let a *quoted* bulleted form outrank the annotation an item actually
  made. Two regressions were demonstrated main-red and branch-green: a `PR`
  block quoting `- status: resolved` above its own `status: open` left the
  roll-call at exit 0, and a record declaring `branch: other-change` that
  quoted `- branch: my-change` became the record FOR `my-change`. The answer
  is the containment invariant described above, and a regression test for each.
- **Round 2** found the ordered-marker gap: `1. satisfies:` and `1) satisfies:`
  reproduced the original defect verbatim while the item read `resolved`. It
  also found that one of the two regression tests passed by a byte-offset
  accident under the single-widening mutation. Both fixed; both tests now
  proved to redden under each mutation separately.
- **Round 3** found GFM task-list items — `- [x] satisfies:` — live, the third
  list form found after a closure claim. That is why `PR-h3wujj` is open.
- **Round 4** confirmed the code and rejected the prose: the withdrawal of the
  closure claim had not reached `scripts/lib.sh` or `skills/ratchet/SKILL.md`,
  the two documents every other artifact defers to. Both corrected.

Rounds 3 and 4 each independently re-measured the containment invariant, both
regression tests under both mutations, and the mutation corpus, and found them
sound. **No round after round 2 found a defect in executable code.**

**finding-1**: This record cannot be kept true by correction. Its Review section grew to 29 transcribed findings with 29 dispositions across three rounds, and each round found defects in the previous round's dispositions — five after round 1, three after round 2, five after round 3 — at a rate that did not fall. The defects were of one kind: a disposition states a fact about a tree that keeps moving (`grep` returns 7, then 17), or a correction fixes the instance and leaves the class (the plan's `Verification:` field, the `reviewer:` field, the scope list), or a figure re-derived to answer a finding about an invented figure is itself mis-derived (the `check-ids.sh` per-directory split was bucketed on a path inside the matched line, giving a phantom directory and two under-counted buckets, with a correct total). Nothing gates any of it: `check-review.sh` requires that a disposition EXIST and never reads one. The transcription was therefore 29 self-imposed claims about a moving tree, with no mechanism to keep them true and four rounds of evidence that the author cannot.
disposition: Accepted, and answered by removing the claims rather than by correcting them a fifth time. The 39 findings are summarised above by what they changed in executable code, which is what a later reader needs and what the branch history and the four review reports carry in full. What is kept is what is either checkable or irreducible: the gate table, whose every figure is re-derived at the commit it names; the red → green rows, which are attestations no later party can re-observe; and Gaps, which states what this change did not establish. The user took this decision on 2026-09-17 after four REJECTs, in preference to a fifth correction pass. **The honest reading is not that the review was excessive — it worked, and it found two real regressions and a live defect three times over. It is that a verification record is a set of claims, a claim is only as good as the re-derivation behind it, and 29 of them in one file outran what one author could re-derive.**

## Gaps

**No gate checks a claim in prose.** Of the 39 review findings, 35 were in
prose and nothing in this repository could have caught one of them: they are
claims, and a claim is re-derived by a reader or not at all. This record is
subject to the same limit, and the Review section says what that cost.

**Every figure in this record is derived at the commit its row names, and no
gate re-derives any of them.** The rows name `f84c72d`. This file has been
edited since — a record cannot name the commit that contains it, because
writing the row changes the tree the row describes — so the standing claim is
narrower than it looks: those figures were true at `f84c72d`, and the commits
after it touch this record, the plan, the ledger, `scripts/lib.sh` comments and
`skills/ratchet/SKILL.md` prose. Of those, the suite reads `skills/` (the
writing scan) but no test reads this file. An earlier draft of this paragraph
named `9ffe60a` and asserted the later commits touched "only this record and
the ledger, which no test reads"; round 4 measured that as false on both counts
and it is not restated here.

**The last corrections in this change were not reviewed.** Round 4 confirmed
the code and rejected the prose, naming `scripts/lib.sh` and
`skills/ratchet/SKILL.md` as still publishing a closure claim the rest of the
change had withdrawn. Both were corrected after round 4 reported, and the
Review section was cut to one finding after that. **No round has reviewed
either edit.** Four rounds of history say a fifth would find something; the
decision not to run one was the user's, taken on the evidence that the
correction rate was not falling.

**The two regressions were found by review, not by a gate, and could not have
been found by the suite as it stood.** No test existed for the ordering
property either script depends on; both now have one. That is a gap this change
closes for two keywords and not in general — every other first-occurrence-wins
reader in the toolkit is still unpinned against a quoted form appearing above a
real annotation, and no test enumerates them.

**Deliberately not done**, each stated where it belongs rather than here alone:
`gr_id_run` still finds its keyword anywhere on the line, so a mid-sentence
mention inside a block is still credited (stated in `lib.sh`); the catalogue
gate covers `check-trace.sh` alone and stops at the script's own scoped
heading (`PR-judqb7`); the same script-to-skill correspondence is unchecked for
`check-ids.sh`, `check-review.sh` and `check-units.sh`; and
`2026-08-23-review-artefact.mutations/M15.sh` was found already dead on `main`,
quoting a form that no longer exists and — unlike M30 — carrying no
`assert s.count(old) == 1`, so it fails silently as a no-op. It was deliberately
not re-cut, because the rule it mutated has been restructured and the re-cut
needs a judgement about what it should now mutate.

M15 is NOT one of the 38 that `PR-crcee5` tracks, though an earlier draft of
this record filed it there. The distinction is the whole point of both. `PR-crcee5` tracks scripts that can no longer APPLY — their
`assert s.count(old) == 1` fails loudly. M15 applies fine and exits 0 while
changing nothing, which is the *silent* failure mode the same sentence
correctly describes. Round 2 applied all 184 scripts against pristine copies of
both trees: 38 fail on `main`, 38 fail on this branch, the two sets are
byte-identical, and M15 is in neither. So it is a second, unrecorded class —
right mechanism, wrong bucket — and a reader chasing the 38 would not find it.
Neither class is fixed here.

**The config the two script rows were derived against**, quoted in full so the
figures can be re-derived. It declares `PR` alone, because the problem ledger
is the only ledger this repository has:

```yaml
guardrails_version: 0.5.1
safety_class: B
id_prefixes: PR
doc_problems: docs/problems
doc_verification: docs/verification
strict_paths:
  - scripts
test_paths:
  - tests
verify_commands:
  - sh tests/run-tests.sh
problem_age_days: 90
problem_open_max: 60
```

**The suite was not dispatched for the author's own runs.** AGENTS.md
non-negotiable 3 requires the gate to be dispatched to a subagent rather than
run by the author. The four `run-tests.sh` figures in the gate table marked as
the author's were run as detached background commands writing to a file outside
the tree, with TAP lines counted — which keeps them out of the author's context
and makes them countable, but is not the independent dispatch the rule asks
for. The round-1 reviewer's 695 IS such a run, in its own worktree, and is
recorded as a separate row for that reason.
