# Verification — duplicate-negations (2026-10-13)

branch: duplicate-negations
reviewer: one independent subagent, dispatched at `merge-change` step 6a with
the diff, both items and the review checklist, and no implementation
narrative; it worked in its own review worktree. The diff was
documentation-only, so it did not run the suite; the author's gate below
covers the tree.
verdict: approve, converged at round 1. Round 1's `code` finding is low and
it raised no `requirement` finding, so it was the last review round; its
findings were fixed mechanically.
reproduced: no new reproduction. `PR-7za3at` is the defect `PR-3kvpze`
describes, reproduced and fixed by `0c11d77`
(`docs/verification/2026-10-13-bare-negations.md`); this change contains no
fix of its own, only the record that the fix covers this item too.

Change: `PR-7za3at` moves from `open` to `resolved`, citing `0c11d77`, which
fixed the same defect under `PR-3kvpze` without naming this item. Branched
from `main` at `0c11d77`; base merged from local `main` at `0c11d77`, per
AGENTS.md non-negotiable 4.
Plan: none. One ledger edit is below the threshold `plan-change` exists for;
`resolve-problem` §4 is the procedure.

## The gate

Measured on: `41926b6` — tree `39ccb95ee009f6b3cd0e1b898981780db51fe70e`, on a
clean worktree, after the round 1 fixes were merged and local `main`
(`0c11d77`, unmoved) merged again. `merge-change` step 3 renamed nothing.

| Gate | Result |
| --- | --- |
| `tests/run-tests.sh` | 1..1297, 1297 passed, 0 failed, exit 0 (17:15–17:40) |
| `check-ids.sh` | identical output at the base and at the change, on scratch copies built from `templates/config.yaml` (this repository has no `.guardrails/config.yaml`) |
| `check-trace.sh` | exit 1 at the base and at the change alike, on the same scratch copies. The only difference: `PR-7za3at` leaves the roll-call (`UNRESOLVED-PR`). No verdict added |
| Coverage, against the class target | not configured |
| Working tree | clean |

## Red → green

This change implements no item and adds no test. It adds `PR-7za3at` to the
annotation of an existing test, `no test asserts through a bare negation` in
`tests/portability.bats`, which scans every `.bats` and `.bash` file in
`tests/`; its red → green lines are in `docs/plans/2026-10-13-bare-negations.md`.
The reviewer confirmed it still goes red for this item's cases: in a scratch
copy, removing the guard from the negation in `tests/finalize-docs.bats` that
the item's table names made the scan fail on that line.

## What was wrong, and what was built

`PR-7za3at` (opened 2026-09-28) and `PR-3kvpze` (opened 2026-10-08) record one
defect: bash's errexit ignores a command negated with `!`, so a negative bats
assertion on any line but a test's last checks nothing. The change that
resolved `PR-3kvpze` (`bare-negations`, `0c11d77`) searched the tree for the
pattern and fixed all of it, but did not search the problem ledger for an
earlier item describing the same defect, so `PR-7za3at` stayed open.

This change sets `PR-7za3at` to `status: resolved` with a `Resolved:` line
naming `0c11d77`, its plan, and the scan test, which now also verifies
`PR-7za3at`. One test in the item's table,
`check-traceability: MALFORMED-STATUS knows there are three values`, had been
removed by `fb0db8d` before `0c11d77`; the `Resolved:` line says so, and that
the item's body describes the tree at 2026-09-28. `resolve-problem` §4 says never
to mark a problem resolved in a change that does not contain its fix. That
rule guards against a resolution that claims a fix no tree carries. Here the
fix is on `main`, which this change branches from, so the tree under merge
does contain it; what this change lacks is only the commit that wrote it.
`accepted` would misstate the item, since it is fixed, not ruled unfixable.

## Review

### Round 1

**finding-1**: code, low — The resolution is backed only by a test annotated for the other item. `resolve-problem`'s Done-when asks for a reproducing test "annotated with the ID it violates". The only test that covers this defect is `no test asserts through a bare negation` (tests/portability.bats:548), and its annotation is `# verifies: PR-3kvpze` alone. No test in the tree names `PR-7za3at`. The gate does not require one: check-trace.sh returns early on `st == "resolved"`. Multi-ID annotations are an established form here (portability.bats:330 `verifies: PR-44z762, PR-aap8nx`; remedies.bats:231; skills.bats:1204). Making line 549 `# verifies: PR-3kvpze, PR-7za3at` would trace the resolution in the tree as well as in prose. It would no longer be a record-only diff, but that is a one-line annotation.
disposition: fixed in `77fa388`: the annotation is `# verifies: PR-3kvpze, PR-7za3at`. `tests/portability.bats` alone: 1..19, 19 passed.

**finding-2**: record — The Resolved line says 0c11d77 covered every case, and one of the table's five tests was never touched by 0c11d77. `check-traceability: MALFORMED-STATUS knows there are three values` no longer exists anywhere in tests/. It was deleted in fb0db8d, together with its two `! sed -n … | grep -q` lines. Its replacement, remedies.bats:247 `check-trace: the MALFORMED-STATUS remedy names all three values`, has no negation. The other four tests check out at HEAD (finalize-docs.bats:215; skills.bats 1055/1057; skills.bats 1413 and 1426–1432; skills.bats 1472). Every one of these is now `! … || { echo …; false; }`. The three merge-change lines were already `run …; [ "$status" -ne 0 ]` from the earlier change. At 1967dc8, the dead lines that remained from this item's table were finalize:215, skills:1055, 1408 and 1420–1422. All of them are in PR-3kvpze's nine dead, so "the same defect" and "fixed in its change" hold for everything that was left. The line should still say that the MALFORMED-STATUS test was removed by fb0db8d before 0c11d77. The item told its resolver to "narrow the table to what is actually there", and that was not done.
disposition: fixed in `77fa388`: the `Resolved:` line names `fb0db8d`'s removal and the successor test, and says `0c11d77` fixed the rest of the table. The fix dispatch confirmed the removal with `git show fb0db8d --stat` and `git grep` on both sides of it.

**finding-3**: record — The body still reads as an open item, and some of it is now false. The Resolved line sits above the body, which limits how far a reader is misled, but these sentences are untrue at HEAD: "Ten lines open with `!` and are neither the last command… nor joined to a … guard" (present tense); "No gate covers either one… a third rule" (a gate now exists, and PR-x4nb48 is no longer open); "If that change is merged first, seven remain"; "Whoever resolves this item should…" and "Whoever takes this:". PR-3kvpze's own resolution left its body alone, so this matches that precedent. A one-clause note on the Resolved line, "the body below describes the tree at 2026-09-28", would stop a reader from taking the tense as current.
disposition: fixed in `77fa388`: the `Resolved:` line ends with "The body below describes the tree at 2026-09-28, not the current tree." The body is kept as written.

## Guideline reviews

None: the diff touches no file a guidelines file governs (one problem ledger
and this record; `docs/TEST_GUIDELINES.md` governs tests).

## Gaps

- No search was made for other open items that duplicate a resolved one. This
  change closes the one duplicate found while choosing the next change.
- The item's body prose is kept as written on 2026-09-28; the `Resolved:`
  line says it describes that tree.
