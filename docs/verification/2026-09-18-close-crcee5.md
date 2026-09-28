# Verification — close-crcee5 (2026-09-18)

branch: close-crcee5
reviewer: independent subagent reviewer, dispatched read-only against the change branch with the diff and the plan and no implementation narrative (merge-change step 6a). The diff is documentation only, so it rested on the gate summary in this record rather than re-running the suite.
verdict: substantively sound — every asserted figure reconciled when counted independently against the tree, PR-crcee5 is resolved by 47a8b1d on both halves of its symptom, PR-fxdgw5 is well-formed and unique, the new prose is clean of the banned vocabulary and names nothing that does not resolve, and the departure from the resolve-in-the-merging-change rule is disclosed rather than smoothed. Two defects raised and fixed before merge.
reproduced: yes, for the item this change opens — `PR-fxdgw5` was reproduced on 2026-09-28 with awk replaced by a stub that exits 2: the redirect creates `t`, `&&` short-circuits the `mv`, and `t` remains beside an unmodified target. For the item this change closes — `PR-crcee5` — the defect was reproduced by the change that fixed it, `47a8b1d`, and is recorded in `docs/verification/2026-09-17-restore-mutation-evidence.md`; this change contains no fix and re-reproduces nothing.

Change: `PR-crcee5` is recorded as resolved by `47a8b1d` in the file that
defines it, and the second, unfixed defect recorded inside it without an ID
becomes `PR-fxdgw5`. Branched from `main` at `47a8b1d`; the base moved to
`97add71` mid-change and was merged in before the figures above were measured.
Plan: `docs/plans/2026-09-18-close-crcee5.md`.

## The gate

Every figure derived from the tree under test, not copied forward. The four
check scripts exit 2 — inapplicable. The repository does not self-host
`.guardrails/config.yaml`, so they answer no question about this change and are
recorded as inapplicable rather than as passes.

| Gate | Result |
| --- | --- |
| `tests/run-tests.sh` | **exit 0** — `1..742`, 742 ok, 0 not ok |
| `tests/mutate.sh docs/verification/*.mutations` | **exit 0** — `167 applied, 17 retired, 0 unusable` |
| `scripts/check-ids.sh` | **exit 2 — inapplicable**, `file not found: .guardrails/config.yaml` |
| `scripts/check-trace.sh` | **exit 2 — inapplicable**, same |
| `scripts/check-review.sh` | **exit 2 — inapplicable**, same |
| `scripts/finalize-docs.sh` | **exit 2 — inapplicable**, same |
| Coverage, against the class target | not configured — no class, no coverage target |
| Working tree | clean, `git status --porcelain` empty |

Measured on: `6bb15e5` — `git rev-parse HEAD` — tree `c36593e385a7548fdf6d036108e004ff22dd4cb9`,
from `git rev-parse HEAD^{tree}` on a clean worktree. Step 3 renamed the draft
ledger file by hand, `finalize-docs.sh` being inapplicable here, so this is a
fresh dispatch rather than step 2's summary carried forward.

No figure above is copied from an earlier round. An earlier round of this
change measured `1..719` at `5ca0d6c`; the base branch then moved to `97add71`,
which added tests, so that figure describes a tree this change no longer stands
on and is not reproduced in the table. The only edit made after the run above is
this record's own — filling the rows. This file is in `docs/verification/`,
which `tests/skills.bats` names as permanently out of the writing scan's scope
and which no other test reads except through the `*.mutations` directory glob,
so editing it cannot change any figure in the table.

## Red → green

This change implements no ID and adds no test. `guardrails` keeps no
REQ/SDD/LLR ledger of its own (`docs/problems/2026-08-27-macos-awk.md`), and a
ledger status flip has no test to watch redden. The table is empty and the
reason is stated rather than the heading deleted.

| Item | Test | Watched red |
| --- | --- | --- |
| none | none | not applicable — no behavior changes in this change |

## What was wrong, and what was built

`PR-crcee5` was opened on 2026-09-10 with a two-part symptom: 38 of this
repository's 184 mutation scripts could no longer apply, and nothing reported
it. `47a8b1d` fixed both parts and did not edit the item, so the ledger
announced the problem as open at every merge after the fix was in. This change
performs the flip and nothing else.

Two things made the flip more than a one-word edit.

**The figure in the item is wrong, and the item is the wrong place to leave it
uncorrected.** 38 was read from the mutation scripts' exit codes. Eight of them
rewrite their target identically and exit 0, so reading exit codes undercounts:
measured by checksumming the tree from outside, the population is 46. The
resolution states both figures and why they differ, rather than repeating 38 as
though the repair had been scoped to it.

**A second defect was recorded inside `PR-crcee5` without an ID**, on the
stated expectation that the change repairing the anchors would touch the same
files. `47a8b1d` repaired the anchors and left that idiom alone, so the
expectation expired. Resolving `PR-crcee5` with the paragraph still inside it
would have closed a defect that is open. It is now `PR-fxdgw5`, measured again
on 2026-09-28: 16 scripts in
`docs/verification/2026-08-20-scan-pathspec.mutations` rewrite their target
through `t` in the working directory, 5 of them still applying (M03, M09, M10,
M11, M17) and 11 retired and executed by nothing.

The exposure of that second defect is narrower than it was on 2026-09-10 and
the item states so. `tests/mutate.sh` applies every mutation with the working
directory set to a scratch tree built from `git ls-files`, so the gate path
writes nothing into the repository. What remains exposed is running a mutation
script by hand from the repository root, which is still the only way to derive
which tests a mutation kills.

**The flip is late, and the record states it rather than smoothing it over.**
`skills/resolve-problem/SKILL.md` §4 and `docs/problems/README.md` both require
`status: resolved` only in the change that merges the fix. This change contains
no fix. The departure is
recorded in the item itself, in the plan, and here, because no gate can connect
a change to the problem it closes — the link exists only in prose, which is
exactly why the omission at `47a8b1d` was reported by nobody. `status:
accepted` was rejected as a substitute: it is for a problem investigated and
deliberately not fixed, and this one was fixed.

## Review

**finding-1**: record — the doctrine citation does not resolve. The item and the plan both state that "`resolve-problem` §4 and `merge-change` both require `status: resolved` in the change that merges the fix". `merge-change` states no such requirement — `grep -n -i 'resolve' skills/merge-change/SKILL.md` returns only "Resolve conflicts" and "references resolve". The rule exists in exactly two places, `skills/resolve-problem/SKILL.md:85-90` and `docs/problems/README.md:86`. The paragraph whose purpose is to name the rule it departs from mis-names half its authority, and the error is in the permanent ledger file, not only in the plan.
disposition: Accepted and corrected. Verified independently — the two greps return what the reviewer reports, and `merge-change` contains the rule nowhere. Both the ledger item and the plan now cite `skills/resolve-problem/SKILL.md` §4, quoting its sentence, and `docs/problems/README.md`, and state that `merge-change` does not contain the rule. The citation in this record is corrected to the same pair. Reddens without the fix in the only way a prose citation can: the grep the reviewer named returns nothing for the claim. Re-checked after the base moved to `97add71`, which rewrote `skills/merge-change/SKILL.md` by 192 lines: the same grep still returns nothing, so the correction holds against the new base rather than only against the one the review read.

**finding-2**: record — the item's own defining symptom sentence still asserts the superseded figure in the present tense — "38 of this repository's 184 mutation scripts can no longer apply, so a fifth of its mutation evidence is unreproducible and nothing reports it" — while the change rewrote the ledger header's bullet to the past tense for precisely that reason, and this record's Gaps section disclosed only the `affects:` line. Tensing the header bullet and not the item, then disclosing only the third of the three, is not consistent.
disposition: Accepted, and resolved in the other direction. Surveyed the ledger before choosing: every resolved item in `docs/problems/` keeps its symptom sentence in the present tense — `PR-aap8nx` "Sixteen `sed -i` calls ... are in the mutation", `PR-52rnrn` "No commit signature ... can be verified", `PR-hcqjk6` "59 of the 184 mutation scripts contain no self-guard". The symptom records what was observed and is not re-tensed on resolution, so the header bullet was the inconsistency, not the item. The bullet is restored to its original present tense and keeps only the appended pointer to `47a8b1d`, which is the same device the item itself uses. Gap 4 below is rewritten to disclose all three carriers of the superseded figure and the convention that keeps them as written.

Both findings are tagged `record`, and the round therefore raised no `code`
and no `requirement` finding. By the convergence rule at `merge-change`
step 6a — which arrived on the base branch at `97add71`, after this review was
dispatched — that makes it the last review round: the findings are answered in
the artefacts they are about, the sequence reruns from step 1 for the moved
base, and no further reviewer is dispatched. The rerun ends at 6b.

## Gaps

1. **This change proves nothing about the fix.** The evidence that `PR-crcee5`
   is resolved was produced by `47a8b1d` and is recorded in
   `docs/verification/2026-09-17-restore-mutation-evidence.md`. What this
   change measures is one gate re-run on today's tree, `tests/mutate.sh` at
   exit 0, which shows the symptom is false now and not that the fix is
   complete.
2. **`PR-fxdgw5` is recorded, not fixed.** The five live scripts still rewrite
   their target through `t`. Fixing them means rewriting each and re-proving it
   still applies and still kills the tests its record claims, which is its own
   change.
3. **The mechanism that produced this change is not closed.** A change can fix
   a problem and leave its item open, and nothing reports it. No item is
   opened for that, because it is not a defect in any script — there is no
   machine-checkable link between a change and the problem it closes. It is a
   gap in the process, stated here and nowhere enforced.
4. **The superseded figure of 38 is in three places in `PR-crcee5` and is left
   in all three**: the symptom sentence, the `affects:` line with its five
   numerators, and the ledger header's bullet. That is the convention every
   resolved item in this ledger follows — the symptom records what was
   observed, and re-tensing or re-measuring it would falsify the observation.
   What stops the figure reading as current is the resolution paragraph, which
   states 46 and why the two differ, and the pointer appended to the header
   bullet. A reader who stops before either gets the superseded number. The
   convention is not enforced by anything; it is a reading habit.
5. **The problem reports `47a8b1d` opened and left open are untouched here** —
   `PR-tenhv4` (inert `[[ ]]` assertions under bash 3.2), `PR-8uggn4` and
   `PR-2c2k3p`. No count is stated: the reader's own `check-trace.sh` run
   measures the backlog, and a number written here measures a tree that no
   longer exists.
