# Problem reports — the mutation temp-file idiom

One item, given its ID here because the item that recorded it without one is
being resolved. `affects:` names files rather than item IDs for the reason
`docs/problems/2026-08-27-macos-awk.md` gives: guardrails keeps no REQ/SDD/LLR
ledger of its own yet.

**PR-fxdgw5**: Five live mutation scripts rewrite their target through a temp
file named `t` in the directory they are run from, joined with `&&`, so an awk
that fails leaves an untracked `t` in the working tree and changes nothing.
affects: docs/verification/2026-08-20-scan-pathspec.mutations/M03.sh, M09.sh,
M10.sh, M11.sh and M17.sh, the five that still apply; the same idiom is in 11
retired scripts in that directory (M12-M16, M18-M23), which nothing executes;
tests/mutate.sh, whose header states that it answers applicability alone and
not which tests a mutation kills, so re-deriving a kill table means running the
scripts outside it.
opened: 2026-09-28
status: open
First recorded without an ID on 2026-09-10 inside `PR-crcee5`, on the stated
expectation that the change repairing the anchors would touch the same files.
`opened:` is the date it entered the ledger as an item of its own, not the date
it was first observed.
That change was `47a8b1d`; it repaired the anchors and left the idiom alone, so
the expectation expired and the defect needs an ID of its own to remain
visible.

Reproduced 2026-09-28 with awk replaced by a stub that exits 2: the redirect
creates `t` before awk runs, awk fails, `&&` short-circuits, the `mv` never
runs, and `t` remains beside the target with the target unmodified. The failure
is silent in both directions — the mutation reports its own failure, and the
file it left is reported by nobody.

`tests/mutate.sh` is not exposed. It applies every mutation with the working
directory set to a scratch tree built from `git ls-files`, so a leaked `t` is
written there and is removed with the scratch tree. What remains exposed is
running a mutation script directly from the repository root, which is how the
corpus was measured on 2026-09-10 and is still the only way to re-derive which
tests a mutation kills — the runner answers applicability and stops there (D4,
`docs/plans/2026-09-17-mutation-evidence.md`). An untracked file at the root
fails `verify-before-merge`'s clean `git status` check, so reading one change's
mutation evidence can block the merge gate of a different change that happens
to be open. Observed twice on 2026-09-10 under exactly those conditions.

The fix is a temp file the script owns and removes — `mktemp` with a `trap`, or
the `sed -i.bak` form the rest of the corpus uses and `tests/portability.bats`
already enforces — applied to the five live scripts. Each rewritten script must
then be proved to still apply and still kill the tests its record claims, which
is why this is its own change and not an edit made in passing.
