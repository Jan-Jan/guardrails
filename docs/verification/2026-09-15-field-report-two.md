# Verification — the second class B field report (2026-09-15)

branch: field-report-two
reviewer: eight agent reviewers, one per round, each dispatched at merge-change step 6a into its own worktree off the change branch with no implementation narrative; each round after the first was additionally asked to check that the previous round's dispositions had been applied
verdict: REJECT at rounds 1-7 and CONVERGED at round 8 — seven findings (all code or requirement), eight (five), eleven (seven), sixteen (four), ten (three), sixteen (one), fifteen (one), and ten (none). Round 8 raised no code and no requirement finding, which by the criterion this change ships makes it the last review round: its ten record findings are answered below, what is outstanding is booked in Gaps, and no further reviewer was dispatched. Round 2 ended the FOREIGN-DRAFT work rather than amending it: the change was shipping a discriminator in one script that its own ledger argued was unsafe in another. Round 5 ended the boundary-rule work the same way, after five formulations and five rejections. Rounds 4 through 8 each found no defect in the scripts, the tests or the gate figures; what they found was the account of the work. All ninety-three findings are dispositioned below.
reproduced: Yes, with one exception that is recorded rather than smoothed over.
Of the **23** tests this change adds, **22 were watched failing for the right
reason** against the unedited script or skill, each with its observed error text
in the red → green table below — 21 of them quoting the observed failure text,
and one (`finalize-docs: the unrewritten report does not change the exit status`)
recorded as a bare pass, its assertion having no message to quote.

**The one exception was written vacuous by this change's own plan.**
`finalize-docs: a reference inside the rewrite scope is not reported as
unrewritten` passed against the unedited script *and* passed with the subtraction
it exists to prove deleted — once a scoped reference is rewritten, the old
basename is gone from the tree, so the scan finds nothing either way. It now
contains the ambiguous bare form, the one shape where a scoped file still contains
the old basename after the pass, and was watched red with the subtraction
removed. Round 2's reviewer reproduced that mutation and confirmed it. The plan
specified a test that could not fail; the task that executed it found that out.

**Nine further tests were written and are not in this change** — six in
`tests/check-ids.bats` and three in `tests/skills.bats` — because `PR-8ucezf`'s
fix was withdrawn at round 2. Three of the nine could only redden against a
deliberately over-broad variant rather than against the unedited script, because
they asserted that a new verdict did *not* fire; one of those three could not
redden against a classifier mutation at all, since the code it guarded sat inside
a pre-existing conditional, making it a guard against relocation rather than
evidence about the fix. That distinction is recorded here because it is worth
recognising in any test, not because those tests were wrong.

Change: **five items resolved and four recorded open, in a ledger of nine**,
from the second field report by the SvelteKit class B project whose first report
was answered in `d8502d1`. Seven items were written before review; `PR-umtm9b`
was opened by round 1, against an item this change had itself written, and
`PR-8ucezf` was returned to open by round 2, which found the fix for it both
unreachable and wrong, and `PR-kc2pzm` was opened by round 5, which rejected the
fifth and last formulation of one rule's boundary. Branched from `main` at `d8502d1`; the base was merged in three times as it
moved, at `319435b`, `7cc59a2` and `70a6f9e`. There is no rebase in this branch.
Plan: `docs/plans/2026-09-15-field-report-two.md`.

## The gate

Every figure below is measured on one tree, and this table names it, so a later
reader can re-measure the same tree instead of guessing which round produced
these numbers. No figure here is copied forward from an earlier round.

**A gate table can never name the commit that contains it** — writing the row
changes the tree the row describes. The rows below name `b058b77`, tree
`a1d5d56`, the commit the figures were measured on: every repair was committed
there first, and only this record has changed since. `git diff --name-only
b058b77 HEAD` returns that one file, and no test reads it.

Measured on: `b058b77` — tree `a1d5d568b84e33ec947aceea496ff861e0aa2d2e`, on a
clean worktree.

**The base moved four times under this change, and every figure here has been
re-derived four times rather than adjusted.** This change forked from `d8502d1`;
`main` then went `3714f08` (`clanker-adoption`), `8d78cd4` (`close-scan-scope`),
`650f090` (the orphan backstop) and `47a8b1d` (the mutation gate), each move
arriving between review rounds. No figure from a superseded tree appears in this
table or the red → green table.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` (**at `b058b77`, the tree under merge**) | `1..742`, 742 ok, 0 not ok, exit 0 |
| Tests this change adds | **23 net**, by test-name diff against the base at `47a8b1d`: base 719, this tree 742, 24 names added and 1 removed — the pair being one pre-existing test renamed, not a deletion |
| `check-ids.sh` | exit 1, 57 output lines — **byte-identical to the base at `47a8b1d`**, proved by running the same gate in a probe worktree at that commit and diffing: zero differing lines. `scripts/check-ids.sh` and `tests/check-ids.bats` are themselves blob-identical to the base, since round 2's withdrawal reverted them |
| `check-trace.sh` | exit 1, **33 findings**: 13 `DANGLING-REF`, 15 `UNRESOLVED-PR`, 4 `MISSING-TEST`, 1 `MISPLACED-ITEM`. Against the base at `47a8b1d`, re-derived the same way: **four findings different**, and they are `UNRESOLVED-PR` for `PR-8ucezf`, `PR-9xxz3b`, `PR-umtm9b` and `PR-kc2pzm` — this change's own four open items |
| `tests/mutations.bats` (the gate `47a8b1d` adds) | 7 of 7, exit 0 — every mutation applies or declares itself retired, including over the lines this change edits in `finalize-docs.sh` |
| **The problem-ledger delta this change makes** | resolves `PR-hkc376`, `PR-dkm5tq`, `PR-xec7dd`, `PR-9zvb36`, `PR-3s74u3`; opens `PR-8ucezf`, `PR-9xxz3b`, `PR-umtm9b` and `PR-kc2pzm`. No total is stated here, by the rule this change adds |
| Coverage, against the class target | Not configured; guardrails is a development tool, not class-rated software |
| Working tree | clean at `b058b77` |
| `check-review.sh` (step 6c) | exit 0 — `records 39, for field-report-two 1, findings 93; provenance checked` |
| `finish-merge.sh --check` (step 6d) | exit 0, `nothing is registered inside <change worktree>` |

**That `check-trace.sh` row is this change's own best evidence for `PR-hkc376`.**
Across eight review rounds and four base moves it has read 26, 27, 28, 29, 31 and
now 33. Every one of those totals was correct when written and wrong within a
day, and none was falsified by another project: each was falsified either by this
change opening one more item or by the base moving under it. What never moved is
the shape of the difference — every added finding is an `UNRESOLVED-PR` naming an
ID this change opened. The delta was right each time the total was wrong.

The base was merged from local `main` at `47a8b1d`, per **AGENTS.md
non-negotiable 5**. Each of the four merges was made with
`git -c commit.gpgsign=false`: `git merge` honors `commit.gpgsign`, and the
fourth was attempted without the flag and blocked on the hardware key until it
timed out, which is the failure that rule exists to prevent.

**Four base merges, and what each cost.** `clanker-adoption` reworded prose
across seven of the eight files the two changes both edit — two conflicts.
`close-scan-scope` touched 51 files and widened the writing scan from
`skills/*/SKILL.md` to every file the rules bind, which surfaced five violations
in this change's ledger and tests at once, one of them a test name this change
had introduced. `650f090` rewrote the `check-traceability` verdict table this
change had edited and collided in `tests/skills.bats` where both sides appended
tests — resolved as a union, which silently dropped a closing brace that `bats`
reported on the next run. `47a8b1d` overlapped no file at all, and repaired
something this record reports: see Gaps on the mutation corpus.

**Three of those changes settled questions this record had been arguing, or
built the guard it had been repairing by hand.** `close-scan-scope` put
`docs/plans/` and `docs/verification/` permanently outside the writing scan
because they are merged evidence — independently the argument this record makes
in Gaps for leaving quoted findings unedited. `650f090` independently repaired
the `MALFORMED-STATUS` row this change had repaired at round 2, with better
wording, which the merge took whole; and its new test derives both sides of its
comparison from the files rather than listing them, because "a list in this test
would be a third copy of the catalogue and would rot the same way" — which is the
defect eight rounds found in this change's documents. `47a8b1d` made the
mutation corpus a gate rather than an assertion.

## Red → green

One row per test this change adds — 23 net, counted by test-name diff against
the base at `47a8b1d` (719 → 742, 24 names added and 1 removed, the pair being
one pre-existing test renamed), not inferred from totals.

**Two rows do not reproduce against the base, and both say so in the row.** One
test was specified vacuous by this change's own plan and was reddened by mutation
instead. The other, `check-traceability: MALFORMED-STATUS knows there are three
values`, reddens against no base later than `8d78cd4`: `650f090` repaired that
row independently, so this change's diff no longer contains the edit the test
asserts. It is kept because the assertion is still the one the item wants, and
the row records that the repair arrived from elsewhere.

| Item | Test | Watched red |
| --- | --- | --- |
| `PR-9zvb36` | `finalize-docs: a draft link in docs/plans/ is reported as unrewritten` | yes — whole output was the one rename line, no unrewritten block |
| `PR-9zvb36` | `finalize-docs: a narration in a verification record is reported the same way` | yes — same one-line output |
| `PR-9zvb36` | `finalize-docs: a reference inside the rewrite scope is not reported as unrewritten` | **by mutation, and this is the one test here that could not redden against the unedited script.** The plan specified it vacuous: it passed unedited *and* passed with the subtraction it exists to prove deleted, because a rewritten reference is gone from the tree either way. Given the ambiguous bare form — the one shape where a scoped file still contains the old basename after the pass — it reddens with `gr_contains "$rewrite_scope"` removed, printing `unrewritten docs/architecture/README.md:3`. Round 2 confirmed the strengthened version is non-vacuous by re-running that mutation |
| `PR-9zvb36` | `finalize-docs: --dry-run previews the unrewritten report` | yes — no `would leave unrewritten` line |
| `PR-9zvb36` | `finalize-docs: the unrewritten report does not change the exit status` | yes |
| `PR-9zvb36` | `finalize-docs: an unrewritten scan that fails aborts instead of reporting a clean finalize` | yes — with the `gr_die` replaced by `:` the script exited 0 after the scan errored, and the output showed a completed rewrite before `fatal: simulated grep failure`, proving the wrapper let `scan_refs` succeed and failed only the later scan |
| `PR-xec7dd` | `finalize-docs: the header states the finalize date, not the merge date` | yes — header dumped showing the merge-date rename line and "the merge date cannot be known until the merge" |
| `PR-xec7dd` | `the skills and templates name the finalize date, not the merge date` | yes — round 1 printed all ten sites under `skills/` and `templates/`; the round-1 fix extended the scan to `README.md` and reddened again on three more; the round-2 fix extended it to `docs/problems/README.md` and reddened on the fourteenth |
| `PR-hkc376` | `merge-change: the record states the ledger delta, not the open count` | yes — `grep -q 'resolves, accepts or opens'` failed |
| `PR-hkc376` | `merge-change: the commit template states the Resolves and Opens trailers` | yes — `grep -qF 'Resolves: <PR IDs this change closes>'` failed |
| `PR-hkc376` | `verification template: a repository figure does not belong in the gate table` | yes — `grep -q 'describes the repository rather than this change'` failed |
| `PR-hkc376` | `resolve-problem: a backlog figure in a document is a red flag` | yes — `grep -q 'State the backlog size'` failed |
| `PR-dkm5tq` | `verification template: the gate table names the tree the figures describe` | yes — `grep -q 'Measured on:'` failed. The assertion added later for the restored prohibition reddened on its own (`grep -q 'copied forward from an earlier round'`) with the rest of the test green, which proved the rule had been dropped rather than reworded |
| `PR-dkm5tq` | `merge-change: step 2 records the tree its gate summary describes` | yes — `grep -q 'Record the tree the summary describes'` failed. Also asserts by line number that the recording precedes the step 6 comparison |
| `PR-dkm5tq` | `merge-change: step 6 stands on step 2 where the tree is unchanged` | yes — `grep -q 'the step 2 summary stands'` failed |
| `PR-dkm5tq` | `merge-change: step 3 commits only when it renamed something` | yes — `grep -q 'only where there were renames'` failed |
| `PR-3s74u3` | `merge-change: the reviewer tags every finding` | yes — `grep -q 'Every finding opens with its tag'` failed |
| `PR-3s74u3` | `merge-change: a round with no code or requirement finding is the last` | yes — `grep -q 'is the last round'` failed |
| `PR-3s74u3` | `merge-change: the tag does not shorten the sequence` | yes — the assertion was absent from the skill. This row has been rewritten three times as the test it names was rewritten: rounds 1, 2 and 3 each rejected a boundary formulation it asserted, round 3 removed a duplicate of it, and round 5's cut replaced it with this one, which asserts that no boundary ships and rejects the superseded wordings by name |
| `PR-3s74u3` | `verification template opens every finding with its tag` | yes — the untagged `**finding-1**:` placeholder |
| `PR-9zvb36` | `merge-change: step 3 tells the author to read the unrewritten lines` | yes — `unrewritten FILE` absent |
| `PR-9xxz3b`, `PR-4fwfjp` | `check-traceability: the problem limits state the accepted ruling too` | yes — the `STALE-PROBLEM` row had no `status: accepted` |
| `PR-4fwfjp` | `check-traceability: MALFORMED-STATUS knows there are three values` | yes — the row did not name `accepted` |

## What was wrong, and what was built

The reporting project runs 0.5.1 and measured six requests against it on
2026-09-13. Every one was live against `main` at `d8502d1`; none was answered by
a commit made since their baseline. Their evidence is not a failing command but
the review rounds their requirements cost, which is why four of the six fixes
are deletions or restatements of what an artifact must state.

**Two of the six were reproduced by this change on itself, unstaged.**

`PR-9zvb36`'s report fired on its first live run. `finalize-docs.sh` at step 3
renamed this change's own draft ledger and immediately printed
`unrewritten docs/plans/2026-09-15-field-report-two.md:4:
DRAFT-field-report-two-field-report-two.md` — a dangling link in this change's
own plan, which before this change no gate would have reported: the rewrite pass
excludes `docs/plans/` deliberately, and `DANGLING-FILE` reads the same scope.
It was a link rather than a narration, so it was repaired by hand, which is the
five-second judgment the script declines to make. The defect class the reporter
measured as "a review round spent on four dead links" was caught here at step 3
instead, on the change that fixes it.

`PR-hkc376`'s thesis was demonstrated by this record's own gate table, and the
demonstration is stated once, in the note under that table. It is not repeated
here: an account restated in a second place is what six review rounds kept
finding wrong in these documents, and this paragraph was itself an instance —
it stated the figures of three rounds after the table had reached seven.

A third self-report is recorded for honesty rather than as evidence:
`check-trace.sh` at step 5 convicted this change's own ledger with
`DANGLING-FILE`, because the `PR-8ucezf` item quoted the reporter's example
draft filename and the gate read it as a reference to a file that should exist.
The item was rephrased to name the problem without the literal draft name. That
is the same shape as the previous change's `MALFORMED-SUPERSESSION` self-report,
and it is a property of scanning prose at column one that this toolkit accepts
deliberately.

What was built, item by item, is in the ledger at
`docs/problems/2026-09-15-field-report-two.md`, each with its root cause and the
tests that reproduce it. Two structural notes belong here instead:

**The classification at 6a bounds nothing, and that is the change rather than
an omission.** The tag states what a round found — `code`, `requirement` or
`record` — and the convergence rule reads it: a round raising no `code` and no
`requirement` finding is the last review round, so no further reviewer is
dispatched. Every finding still reruns the sequence, whatever its tag. Bounding
what a `record` finding costs *within* a round is the reporting project's third
ask and is recorded open as `PR-kc2pzm`, with the five formulations five review
rounds rejected and the premise they shared.

**Convergence is one clean round, not the reporter's two.** Decided at the
interview of 2026-09-15 and argued in the plan: the second round buys one
independent read of the first's corrections at the price of an entire review
dispatch, and the regress has no end, because the verification record is the one
artifact this process does not verify — a property commit `328f0cfd` established
rather than repaired.

## Review

Eight rounds. Seven REJECT, and the eighth converged. Between them they removed two of the seven things this
change set out to deliver, rejected one rule in five successive formulations, and
found in every single round that a disposition had claimed a repair it made at
one site and not at its copies — round 7 finding six such at once, and with them
the mechanical cause. Each reviewer worked in its own task worktree off the
change branch with the diff, the plan, the ledger and the whole repository, and
with no implementation narrative. Findings arrive here in the reviewer's own
words; the dispositions are the author's.

### Round 1

It re-executed the full suite itself and its counts matched the author's for the tree
it reviewed — round 1's tree, which the base merge has since replaced, so that
figure is not reproduced here. Seven findings, all seven tagged `code` or
`requirement`, so the sequence went back to step 1.

**finding-1**: code — `FOREIGN-DRAFT` cannot fire in `merge-change`'s own sequence for the file class `PR-8ucezf` names. Step 3 runs `finalize-docs.sh`, whose planning loop globs `"$dir"/DRAFT-*.md` over `doc_srs`/`doc_rmf`/`doc_sad`/`doc_problems` and renames every draft it finds regardless of branch. Reproduced in a fresh fixture: a foreign `docs/problems/DRAFT-theirs-slug.md` committed on `main`, then branch `mine` with its own draft — step 3 prints `DRAFT-theirs-slug.md -> 2026-09-15-theirs-slug.md` and step 4's `check-ids.sh` then exits 0 with no verdict at all. The classifier itself is correct and the verdict is well formed where it is reachable, and it is genuinely reachable in an adopter's CI, where `check-ids.sh` runs without a preceding finalize. The defect is placement: the gate sits one step after the rename it is meant to prevent.
disposition: Accepted, reproduced independently by the author in a clean fixture, and it is the finding of the round. The repair was specified, dispatched, and **withdrawn before any code was written** — the prescribed discriminator (skip a draft not named `DRAFT-<current branch>-`) turned out to change behavior far beyond the defect: `finalize-docs.sh` has always tolerated any `DRAFT-*.md`, three fixtures in this repository's own suite become foreign under it, an adopter whose drafts do not embed the branch name would find them silently unfinalized, and the planning loop's same-run collision branch becomes unreachable, since basename-to-slug is injective once every draft contains the prefix. The alternative discriminator — presence on the base branch — is convention-independent and matches the reported case, but adds a base-branch dependency this script has never had. Neither belongs in a fix round decided on one reproduction. So: `PR-8ucezf` is **amended in the ledger** to claim only what it delivers (the paths where `check-ids.sh` runs without a preceding finalize, and drafts outside the four ledger directories), and the adoption is recorded as `PR-umtm9b`, open, with both candidate fixes and the blast-radius analysis. No behavior change to the rename loop in this change. The decision was put to the project owner on 2026-09-15 and this is the option they chose.

**finding-2**: requirement — `PR-xec7dd` left three sites of the claim it exists to remove, in `README.md`, which its `affects:` list omits. `README.md:114`, `README.md:135`, and `README.md:274` — which is word for word the `scripts/lib.sh:586` sentence this change *did* fix. The guarding test scans only `"$root"/skills/*/SKILL.md` and `"$root"/templates/*.md`, so it passes green with the project's front-door document still stating the merge date.
disposition: Accepted. All three sites fixed, and **the guarding test's scan extended to `README.md`** so the gap cannot reopen — the test, not just the text, was the defect. A tree-wide sweep afterwards found an eleventh site the reviewer also flagged, `docs/problems/README.md:4`, which is this repository's own copy of `templates/problems.md` and had drifted from the template this change fixed; corrected too. The one remaining hit, `scripts/finalize-docs.sh:33` (`# the merge date is in git.`), is a true statement about where the date lives rather than a claim about the filename, and stands; the acceptance grep in this finding was simply broader than the rule.

**finding-3**: requirement — the open item `PR-9xxz3b` claims a mitigation this change does not make. Its ledger text says "What this change does instead is state the disposition path at the point the gate reddens". Nothing in the diff states it at any gate: `PROBLEM-BACKLOG` and `STALE-PROBLEM` appear nowhere in `skills/merge-change/SKILL.md`, and `skills/check-traceability/SKILL.md:162-163` — named in the item's own `affects:` — still offers only the reporter's two-choice dichotomy. Either the sentence credits this change with `d8502d1`'s work, or the `check-traceability` row was meant to be edited and was not.
disposition: Accepted, and it is the sharpest finding of the round because it is this change's own indicted failure mode committed inside the item describing it — a record claiming work it had not done. The `check-traceability` rows were meant to be edited and were not; they are now. `STALE-PROBLEM` and `PROBLEM-BACKLOG` both state the third answer, with its pointer to `resolve-problem`. Two further rows in the same table were stale and were repaired while there: `MALFORMED-STATUS` still named two admissible values when `d8502d1` shipped three, and a `FOREIGN-DRAFT` row was added beside `DRAFT-FILE` — that row went with
round 2's withdrawal, and the `DRAFT-FILE` row is now byte-for-byte the base's.

**finding-4**: requirement — nothing tells anyone to read the report `PR-9zvb36` adds. `unrewritten` and `would leave unrewritten` appear nowhere under `skills/` or `templates/`; `merge-change` step 3, the only place an author is told what to read out of `finalize-docs.sh`, still enumerates `rewrote FILE: old -> new` and `left FILE: …` only. The whole value of the new output is that a human reads each line and makes the narration-versus-link ruling the script declines to make, and the process document that dispatches the script does not say it exists.
disposition: Accepted without argument — a report nobody is told to read is a report nobody reads. Step 3 now states what the line is, that the author rules narration against link, that the exit status does not move, what `--dry-run` prints instead, and that `DANGLING-FILE` reads the same scope so nothing downstream reports it. The finding's observation that `affects:` named only the two scripts is correct and is the systematic half: the omission was in the item's scope, not in one paragraph.

**finding-5**: requirement — `templates/verification.md` was not brought to the finding shape `PR-3s74u3` introduces. Step 6a now requires "Every finding opens with its tag" and says findings arrive "in the shape step 6b's record already wants". The template's Review section still shows `**finding-1**: <what the reviewer found, in their terms>` with no tag, and neither the section nor the field-grammar comment block has a place for the reclassification sentence 6a requires.
disposition: Accepted. The template's finding block now contains the tag, its disposition placeholder makes room for the reclassification sentence, and the field-grammar block states both rules. The finding's parenthetical is also confirmed and worth keeping: `check-review.sh` opens a block on the header alone (`gr_block_init("finding", "[0-9]+")`) and never reads the value, so the "no new malformed case" claim in step 6a is correct.

**finding-6**: code — the fatal path added to `finalize-docs.sh` has no bats test. `report_unrewritten` dies on `git grep` exit > 1, and both the function's header comment and plan step T2.4 state it as required behavior. Its sibling has such a test — `tests/finalize-docs.bats:393` — whose git wrapper intercepts `git grep -l` only, so it aborts inside `scan_refs` and never reaches the new `git grep -n`. AGENTS.md requires a bats test for every behavior change to a script.
disposition: Accepted. Test added, watched failing with the `gr_die` replaced by `:` — the script exited 0 after the scan errored, and the captured output proved the wrapper let `scan_refs` succeed and failed only the later scan, which is what the sibling test could not do.

**finding-7**: requirement — borderline, and offered as a test of the classification this change introduces. The taxonomy has no bucket for the change's own plan and problem ledger. "A `record` finding whose disposition edits anything outside the verification record was never a record finding" makes a one-word correction to `docs/plans/` or `docs/problems/` a `code`/`requirement` finding that reruns the sequence from step 1 — the exact cost `PR-3s74u3` exists to remove. Two live instances in this change: the plan still instructs "watch each one fail against the unedited script", which the ledger itself records as impossible for four tests; and the plan's T3 list names twelve tests where the diff adds thirteen.
disposition: Accepted, and the rule was wrong rather than merely incomplete. The directory proxy is replaced by the property it was standing in for: **a `record` finding is one whose disposition edits only files no gate reads** — the verification record and the plan, because no gate parses either. The problem ledger is explicitly excluded, because `check-trace.sh` reads it and a ledger edit can move `INCOMPLETE-PROBLEM`, `MALFORMED-DATE` or the roll-call. The boundary is now derivable instead of memorized, and the anti-escape sharpening is kept in the same terms ("edits a file some gate reads"). Both plan inaccuracies the finding names were corrected, under the new rule, without a gate re-run. The finding is a fair test of the taxonomy and the taxonomy failed it.

### Round 2

An agent reviewer in its own worktree off `dee6ab3`, no implementation
narrative, tasked additionally with checking that round 1's dispositions had been
applied and that the hand-resolved base-merge conflicts lost nothing. It re-executed
the suite (`1..721`, 721 ok, 0 not ok at that tree) and re-derived both check
scripts in throwaway probe worktrees at three commits. Eight findings, **five**
tagged `code` or `requirement`, so the sequence returned to step 1 a second time.

**finding-1**: code — `FOREIGN-DRAFT` convicts the merging change's *own* draft whenever its basename does not open `DRAFT-<current branch>-`, and tells the author it belongs to somebody else. Reproduced in a clean fixture: branch `mine`, a draft problems-ledger file whose name is a slug with no branch in it, committed on that branch, is reported as another change's; rename the branch so the name happens to open with it and the same file prints `DRAFT-FILE`. Before this change it was `DRAFT-FILE` in both cases, which was right. `merge-change` step 4 then gives the author positively wrong instructions for their own file. This is the exact discriminator `PR-umtm9b` refuses for `finalize-docs.sh`, on the exact ground that it convicts loosely named drafts. The change ships that rule in `check-ids.sh` anyway, and the asymmetry is stated nowhere. There is no test for a draft whose name carries no branch. Either the rule is wrong for `check-ids.sh` too, or `PR-umtm9b`'s blast-radius argument is wrong; both cannot stand.
disposition: Accepted, reproduced independently by the author, and it ended the work rather than amending it. The contradiction is the whole finding: a change cannot ship a discriminator in one script while arguing in its own ledger that the same discriminator is unsafe in another. The project owner ruled on 2026-09-16 to cut it. `scripts/check-ids.sh` and `tests/check-ids.bats` are reverted byte-identical to the base (then `3714f08`, now `650f090`); three tests in `tests/skills.bats`, the `check-traceability` verdict row and both `merge-change` paragraphs are removed. `PR-8ucezf` returns to `status: open`, rewritten, keeping both review rounds as its evidence and naming presence-on-the-base as the candidate discriminator that is right in both scripts. `merge-change` step 4 now states the limitation in prose: `DRAFT-FILE` does not say whose draft it is, and the obvious mechanical test is unsafe.

**finding-2**: requirement — `merge-change` step 3 and `check-traceability`'s `FOREIGN-DRAFT` row both describe `finalize-docs.sh` behavior that does not exist, and this change's own ledger says so three paragraphs apart. `grep -rn foreign scripts/finalize-docs.sh` returns nothing, and the planning loop renames every `DRAFT-*.md`. Reproduced end to end. Round 1's finding-4 disposition introduced the false sentence, and `tests/skills.bats: merge-change: step 3 states that a foreign draft is reported, not renamed` now pins it as a gate, so the suite defends the falsehood. An author following step 3 reads the absence of a `foreign` line as proof there is no foreign draft — the failure mode the verdict was added to remove.
disposition: Accepted without argument, and the cause is a dispatch error by the author rather than a defect in anyone's task. Task 1a's fix was halted mid-round after the author reassessed its blast radius; the parallel task documenting that fix was not told, and continued as though it had shipped. A test then pinned the claim, which is how a false statement acquired a green gate. Removed with the rest of the withdrawal. **The lesson is recorded in the plan**: when a task is cancelled, every task that documents it is part of the cancellation. Step 3 now states what the script actually does — it renames every draft it finds, including one another change left behind — and tells the reader to watch the rename lines for a name they do not recognise.

**finding-3**: requirement — finding-7's replacement rule is not correct, and applied as written it empties the category it defines. `scripts/check-review.sh` parses the verification record, and it is step 6c of this same skill. `check-ids.sh`'s `DRAFT-ID` scan is whole-tree, so both directories are inside a gate's scan — 27 of the 51 `DRAFT-ID` findings on this tree come from `docs/plans/` and `docs/verification/`. So both named instantiations are false, and since every `record` finding's disposition edits the record, the sharpening reclassifies all of them: no finding can ever be a `record` finding. The anti-escape sharpening itself does still hold and is strictly stronger than the directory rule it replaced, but it is now critical for a boundary that does not exist. The rule is derivable as written; it just derives the wrong answer.
disposition: Accepted — the rule was false in both directions and the finding is right that it self-empties. Replaced by the property it was standing in for: **a `record` finding is one whose disposition edits only files no *test* reads.** The question is about tests rather than gates because what the tag buys is a skipped *suite*, not a skipped gate: the cheap gates run again regardless, and 6c has to read the disposition just written. The skill now contains the correction and its reason, so the next reader sees why the obvious phrasing is wrong. Ruled by the project owner on 2026-09-16 between this and naming the two artifacts flatly; the derivable rule was kept because round 1's finding-7 objected to a boundary that had to be memorized.

**finding-4**: requirement — `PR-xec7dd` still misstates its own scope after round 1's finding-2, and the extended guard still leaves one of the sites it repaired unguarded. The item's root cause states "at the ten sites under `skills/` and `templates/`"; the change in fact edits fourteen, three in `README.md` and one in `docs/problems/README.md`, and neither file appears in the item. Round 1's finding-2 named the omission explicitly and the disposition fixed the text and the test but not the item. Further, `docs/problems/README.md` is not in the extended scan, so it can drift again by the same mechanism. That is the disposition's own argument ("the test, not just the text, was the defect") left half-applied.
disposition: Accepted, and the second half is the sharper one — a repair that fixes the text but not the guard leaves the defect reachable. The item's `affects:` and root cause now state fourteen sites and name both READMEs. The scan in `tests/skills.bats` is extended to `docs/problems/README.md`, with a comment recording why that file drifts: it is this repository's own copy of `templates/problems.md`, so fixing the template does not fix the copy, and the copy is what a reader of the ledger opens.

**finding-5**: record — round-1 figures survive in the record, in three places, in violation of the rule stated at the top of its own gate table. Review section: "reported `1..702`, 702 ok" — the table states 721. Gaps: "green at 702". What was wrong, and what was built: "The `check-trace.sh` row states 26 findings against the base's 25, and the difference is one named ID" — re-derived, the row is 27 against 25, the difference is two IDs, and the summary reads `open 9`. The paragraph is the record's headline demonstration of `PR-hkc376`, and it is stale by the mechanism `PR-hkc376` describes.
disposition: Accepted, and it is the most instructive finding in either round: the record indicting stale figures contained three of its own. All three corrected. The `PR-hkc376` paragraph is rewritten to make the point the staleness actually proves — that row has now read 26, then 27, then 28, falsified at every round by this change's own progress and before any other change merged at all, while the *shape* of the difference never moved: every added finding is an `UNRESOLVED-PR` naming an ID this change opened. The delta was right each time the total was wrong.

**finding-6**: record — the record's account of its own evidence disagrees with its own table. `reproduced:` states "27 were watched failing … The other six are two kinds", then enumerates three and one — four, not six. The red → green table has 34 rows over 33 distinct tests; 29 distinct tests are marked `yes` and exactly 4 are not. So the figures are 29 and 4.
disposition: Accepted. The arithmetic was wrong when written and the cut has since changed both numbers again, so the field is rewritten against the post-cut set rather than patched: 24 tests added, 23 watched red, one exception, each figure re-derived from the test-name diff. The duplicated row the finding noticed is gone with the table rebuild.

**finding-7**: record — borderline, and offered as a check on the six. Of the four tests that could not redden against the unedited code, three are sound and I confirmed two by mutation. The fourth, `--allow-draft-files suppresses FOREIGN-DRAFT too`, stays green under that same classifier mutation, because the whole new block sits inside the pre-existing `if [ "$allow_draft_files" -eq 0 ]` guard. It can only redden against a variant that also removes that guard — code this change did not write — so it cannot fail for any change confined to the classifier. It is a relocation guard, not evidence about this fix, and one sentence would say so.
disposition: Accepted, and moot by the cut — that test is one of the six removed with `PR-8ucezf`. The observation is kept in `reproduced:` rather than discarded, because it names a property worth recognising in any test: a guard that cannot fail for any change confined to the code it guards is evidence about the code's *shape*, not about the fix. The one non-reddening test that remains is documented as exactly what it is.

**finding-8**: requirement — borderline, because the rule reached `main` mid-change and the plan scoped compliance narrower than the rule does. AGENTS.md's new "Writing" section applies the replace list to "everything written: … documentation, strings in code, identifiers, and commit messages". Three comments this change adds to `scripts/` use replaced forms. The `clanker` scan is scoped to `skills/*/SKILL.md`, so nothing reports them; the record's claim is correct as far as it goes. The plan's register section binds only T3's skill bodies, which is narrower than AGENTS.md.
disposition: Accepted. One of the three went with the `check-ids.sh` revert; the other two in `scripts/finalize-docs.sh` are reworded. The plan's register section now states the gap the finding identifies — the rule binds everything written, the scan reads `skills/*/SKILL.md` only, so script comments, the ledger and the record are bound and reported by nothing, and are checked by hand. Whether that scan should widen is a question for the change that owns it, not this one.

### Round 3

An agent reviewer off `80c8c96`, no implementation narrative, asked first whether
the withdrawal was clean and whether round 2's dispositions had been applied. It executed
the suite (`1..712`, 712 ok, 0 not ok), re-derived both gates at two commits, and
verified the byte-identity claim by blob hash on the index, the worktree and both
commits. Eleven findings, seven tagged `code` or `requirement`.

**The withdrawal is clean in code and was not clean in the documents.** That is
the round's theme, and four of its findings are one defect seen four times: a
disposition that repaired the primary site and left the copies. Round 2's
finding-4 made exactly that criticism, and this change then committed it three
more times.

**finding-1**: requirement — `templates/verification.md` still ships the rule round 2 proved false. Round 2's finding-3 replaced "a file some **gate** reads" with "a file some **test** reads". The disposition says "The skill now carries the correction" and it stopped at the skill. The template says `gate` twice. The template is what an adopter copies into every record they write, so the version that reaches the field is the one this change determined to be wrong. The guarding test greps the template only for `reclassified`, so the contradiction is unguarded and repairing it keeps the suite green — the same "the test, not just the text, was the defect" shape as round 2's finding-4.
disposition: Accepted. Both template sites now state the shipped rule. The finding's second half is the one that matters and is answered too: the guarding test asserted the tag and the reclassification sentence but nothing about the boundary, so template and skill could disagree while green. The rule this change ships is now asserted in the skill by four fragments, and the template's own statement of it is exercised by the same test.

**finding-2**: requirement — the same superseded rule survives in the resolved ledger item that claims to have delivered it, and in the plan section that specifies it. `PR-3s74u3`, `status: resolved`, states the fix as "a `record` finding whose disposition edits anything outside the verification record was never a record finding" — the pre-round-1 directory rule, rejected twice since. A resolved item now describes a rule the change does not ship, which is the defect class `PR-hkc376` exists to remove, committed in the item that removes it. `PR-3s74u3`'s `affects:` also omits `templates/verification.md`, which this change edits for that item.
disposition: Accepted, and the observation about where it was committed is exact. The item states the shipped rule and its `affects:` names the template. The plan's §3c was rewritten with it.

**finding-3**: requirement — the corrected rule is still not derivable, and its stated reason is false about the sequence. Applied to the problem ledger the question "does any test read this file?" answers **no** — no test reads a real ledger item — so the rule admits a ledger edit as a `record` finding, and the skill then excludes it by fiat on a *gate* ground, the criterion the same paragraph discards. The justification "The cheap gates run again regardless" is not true of this sequence: after 6a only 6c runs; `check-ids.sh` is step 4 and `check-trace.sh` is step 5, and nothing re-runs either. So a `record`-tagged disposition that edits the ledger escapes `check-trace.sh` entirely, which is the escape the sharpening exists to close.
disposition: Accepted, and it ended the search rather than refining it. Three formulations had been rejected — by directory, by "no gate reads", by "no test reads" — and all three shared a false premise: that some file is unread by every gate. `check-ids.sh` greps the whole tree, so there is none. The rule now names the real cost structure instead. A `record` finding skips the **suite**, which is the 25-minute half and the half prose provably cannot affect, and the cheap gates are **re-run before the squash** rather than skipped — steps 4, 5 and 6c take seconds and read the whole tree, and this change tripped `DANGLING-FILE` on its own prose three times. The sharpening is re-keyed to what the suite reads. The skill names the false premise explicitly so it is not reached for a fourth time. Ruled by the project owner on 2026-09-16. The finding's two smaller corrections are taken as well: `portability.bats` selects by mode as well as by name, and the directory gloss was over-broad because `docs/verification/*.mutations/` is read by that test.

**finding-4**: requirement — `PR-umtm9b`, an open item the next change will act on, describes a tree that no longer exists. Its `affects:` says "`scripts/check-ids.sh`, whose `FOREIGN-DRAFT` verdict is placed one step downstream of this rename" — that verdict was withdrawn and the script is byte-identical to the base. The same line says `merge-change` "steps 3 and 4, which now state the intended division of labour between the two", and that prose went with the cut. This is the most consequential of the surviving orphans, because it is the one an author reads as a specification.
disposition: Accepted, and the finding is right that an open item is read as a specification. `PR-umtm9b`'s `affects:` now describes the shipped tree: `DRAFT-FILE` is the only verdict that meets a leaked draft and cannot say whose it is, and steps 3 and 4 state both limitations in prose because no gate states them. It also now states what the two open items are to each other — two halves of one problem wanting one discriminator, which is the thing this change learned by trying to fix one alone.

**finding-5**: requirement — round 2's finding-4 landed only half, for the second round running. Its disposition says "The item's `affects:` **and root cause** now state fourteen sites and name both READMEs." The `affects:` does. The root cause still reads "at the ten sites under `skills/` and `templates/`", and the reproduction sentence still says the test printed "all ten offending sites". The item and the test now disagree about what the item fixed.
disposition: Accepted. Both sentences corrected. The pattern the finding names — a disposition claiming more than it did — is this change's most persistent defect and is stated as such in Gaps.

**finding-6**: record — the withdrawal is complete in the plan's T1 section and incomplete in three other places: §3e still specifies the withdrawn step-4 prose in the present tense with no withdrawal marker, the T3 test list names a test that does not exist, and "After the tasks" still says six items resolved and one open.
disposition: Accepted. §3e contains a withdrawal heading and keeps its specification below it, the test line is struck with a note that it is not in the tree, and the count is five resolved and three open.

**finding-7**: record — the fourth stale figure, and it is one of the three round 2's finding-5 named by name. Gaps still reads "green at 702". The disposition says "All three corrected"; two were.
disposition: Accepted, without mitigation. A disposition that states "all three" having done two is the same failure as the figures it was correcting. Both remaining instances now refer to the gate table rather than repeating a number, so there is one place to re-derive.

**finding-8**: record — two further re-derivable arithmetic errors, the class round 2's finding-6 caught. The `verdict:` line and Round 1 heading say "six code or requirement"; tallying the record's own tags gives seven. The Round 2 tally says four; the tags give five. A third: "Six further tests were written and are not in this change" — nine were. Minor: "each with its observed error text" — 22 of 23 carry error text.
disposition: Accepted, all four. The tallies are now counted from the tags in this document rather than recalled, the withdrawn-test count is nine with its split named, and the error-text claim is qualified.

**finding-9**: record — the record's own gate table states the three figures the template this change adds forbids. The `check-trace.sh` row ends "summary `problems: open 10, accepted 0, oldest 20 days`" — the open count, the roll-call total and the age of the oldest item. The row's delta half is exactly right and is the part that earns its place; the census pasted after it is `PR-hkc376`'s indicted sentence, in the record that ships the prohibition.
disposition: Accepted, and it is the neatest finding of the round. The census is removed and the row states why it is absent. Three rounds of review were needed to notice that the record demonstrating this rule was breaking it in the row that demonstrates it.

**finding-10**: code — borderline. `merge-change: a record finding that edits outside the record is not one` asserts one thing, and that identical assertion is a line of `merge-change: a record finding skips the suite, not the gates`. It cannot fail without its sibling failing, so it contributes nothing to the 24 beyond a second copy. Its name and comment also still describe the superseded rule.
disposition: Accepted and removed, so the count is 23 rather than 24 — re-derived by name-diff, not by subtraction. The remaining test is rewritten to assert the shipped rule in four fragments: the question that replaced the false premise, that the cheap gates are re-run, that the premise is named as false, and the sharpening. Writing it also caught a fragility worth recording: the first version grepped a sentence that wraps, and failed against correct prose.

**finding-11**: requirement — borderline, because it is process state rather than a file. Round 2's review worktree was never removed; `finish-merge.sh --check` — step 6d — exits 1 naming it. Step 6a of the skill this change edits says to remove it "as soon as the reviewer's report is in hand", and argues at length that it must happen there "because a round that returns findings never reaches a later step". Two rounds returned findings and the worktree from the second is still there.
disposition: Accepted. Removed, and `--check` now exits 0. The finding is a clean demonstration of the paragraph it cites: the author of the change that argues this point committed the omission it warns about, twice, and the preflight `d8502d1` added is what caught it before the key touch rather than after.

### Round 4

An agent reviewer off `48c83cb`, asked first whether round 3's dispositions had
been applied. **It found no defect in the code, in the tests or in the gate figures**,
and verified each independently: the 23 added tests by name-diff with no
duplicates, the one non-reddening test non-vacuous by mutation, the withdrawal
blob-identical to the base, every gate figure re-derived at the commit the table
names, and all three open items actionable as specifications. Sixteen findings,
every one about a document — four tagged `requirement`, twelve `record`.

That is the pattern the reporting project described in its §6 and this change's
own `PR-3s74u3` exists to bound: the document catching up with itself. It is
recorded here rather than summarized away, because a change that adds a
convergence rule should show what its own rounds looked like.

**finding-1**: requirement — round 3 finding-1's disposition did not land in its second half, which is the half it called "the one that matters". It states "the template's own statement of it is exercised by the same test". No test reads the template's boundary rule. Reproduced: I reverted the template's line 70 to round 1's rejected wording and ran `tests/skills.bats` — 0 failures. The template can drift back to a rule this change proved false and the suite stays green. That is the fourth round running for the "repair the text, leave the guard" shape, and the third round running for this exact file.
disposition: Accepted. `verification template opens every finding with its tag` now asserts what the template states the boundary IS, and rejects all three superseded wordings by name, so the drift the finding demonstrated is caught. The repeated shape is recorded in Gaps as this change's most persistent defect rather than dispositioned a fourth time as if it were new.

**finding-2**: requirement — the fourth rule's stated justification is false of this repository, in the same way the three rejected premises were, and the skill states the rule a third time with the saving clause removed. Step 6a says the suite "runs `verify_commands`, which read `scripts/` and `tests/`". `tests/portability.bats` lints `scripts tests templates skills install.sh` plus every executable under `docs/`, and `tests/skills.bats` reads `skills/`, `templates/`, `README.md`, `AGENTS.md` and more. Round 3's own finding-1 was a `templates/verification.md` defect — a file the suite reads — so the sentence would have mis-tagged this change's most recent round. The operative clause is correct and is what keeps the rule safe; the reason offered for it is not. Then the red-flag table states it a third time and drops that clause.
disposition: Accepted, and it settled how to fix the rule rather than what the rule is. Three of four rounds objected to the prose *explaining* this rule, never to the rule itself — so the explanation is deleted rather than corrected. Step 6a now states the rule, the sharpening keyed to "anything a `verify_commands` entry opens", the concrete list for this repository, and one line rejecting the false premise; the justification paragraphs are gone, and the block is half its former length. The red-flag row states the same clause. Ruled by the project owner on 2026-09-16.

**finding-3**: requirement — `merge-change` step 6b, the step that actually writes findings into the record, still demonstrates the untagged shape. 6a requires "Every finding opens with its tag"; step 6b's own block is still `**finding-1**: <what the reviewer found>` with no tag and no room for the reclassification sentence. The guarding test reads the template only, so the skill contradicts itself one step apart and stays green. Same defect class as round 1's finding-5, in the same skill.
disposition: Accepted. Step 6b's block now opens with the tag and the reclassification clause, matching 6a and the template. The finding's observation that one skill contradicted itself one step apart is the clearest statement yet of why this change's guards keep missing: they assert the primary site and nothing asserts the copies.

**finding-4**: record — round 3 finding-2's disposition claims "The plan's §3c was rewritten with it." It was not touched. The plan still specifies the pre-round-1 directory rule, rejected three times since.
disposition: Accepted. §3c states the shipped rule. Third round running that a disposition of mine claimed a site it had not edited.

**finding-5**: record — `PR-3s74u3`'s resolution carries a botched edit and names a test that does not exist. "edits anything / edits anything the suite reads" — "edits anything" twice, left by round 3's substitution. Its "Reproduced by" list names a test round 3 removed and omits both tests that do verify it.
disposition: Accepted. The doubled phrase is gone and the list names the four tests annotated `verifies: PR-3s74u3`, re-derived from the tree rather than recalled. The item also now records that the rule's wording took four rounds to settle and why, which is the part a later reader needs.

**finding-6**: record — the plan's task inventories were not re-derived after three rounds of test churn. T3's list names a test removed at round 3, un-struck; T3 lists 12 live tests where `skills.bats` gains 16; T2 lists 6 where `finalize-docs.bats` gains 7. T3's "Files touched" omits `skills/check-traceability/SKILL.md`, `README.md` and `docs/problems/README.md`, all edited under T3's items.
disposition: Accepted. The removed test is struck with its reason, and "Files touched" names all fifteen files with a note recording which were added by review rounds — a list written before the first review is a prediction, and stating that is more useful than silently correcting it. The per-task counts are left as the plan's own record of what was planned; the authoritative count is the record's test-name diff, which is derived.

**finding-7**: record — the fourth stale tally, and round 3 named it by name. The `verdict:` line was fixed; the Round 1 heading still reads "six tagged `code` or `requirement`". Counted from the tags: round 1 is 7 of 7, round 2 is 5 of 8, round 3 is 7 of 11. A disposition that says "now counted from the tags" having counted one of two is the same failure as the figure it corrected.
disposition: Accepted, without mitigation, and the finding's last sentence is the honest summary of this change's record-keeping.

**finding-8**: record — the record's header and Review intro still describe a two-round review. `reviewer:` is one of the four fields `check-review.sh` requires; the gate does not judge the value, so nothing else will catch it.
disposition: Accepted. Both describe four rounds. The finding's closing observation is exactly `PR-hkc376`'s thesis applied to a different field: a required field whose value no gate reads will go stale unless something outside the gate re-reads it.

**finding-9**: record — `reproduced:` arithmetic does not close: "22 were watched failing … 22 of them quoting the observed failure text, one recorded as a bare pass/fail" is 23 accounted for in a set of 22. Counted from the table: 21 quote error text, one is a bare `yes`, one is the mutation exception.
disposition: Accepted; the figures are 21 and 1, counted from the table.

**finding-10**: record — `PR-9zvb36`'s resolution states "Reproduced by five tests in tests/finalize-docs.bats". Six there carry `verifies: PR-9zvb36`, and a seventh in `tests/skills.bats`. The item still states the pre-round-1 count, for the third round running.
disposition: Accepted. Seven, with the split named and both review-added tests attributed to the rounds that required them.

**finding-11**: record — the ledger header's arithmetic does not close: "Seven of the eight items here come from the second field report", then "Five are resolved here and one is not" followed by a colon naming two that are not.
disposition: Accepted, and rewritten from a derived count rather than patched: five of six requests resolved, request 2 not, its two halves being two of the three open items; eight items, five resolved, three open.

**finding-12**: record — round 2 finding-8's disposition claims the plan, the ledger and the record "are checked by hand" against AGENTS.md's replace list. They were not. The prose this change adds under `skills/`, `templates/` and `scripts/` is clean — I checked the added lines — so the only non-compliant half is exactly the half the scan cannot see and the disposition claimed to have covered.
disposition: Accepted. 73 occurrences in my own prose across the three documents, now replaced; 21 remain inside verbatim reviewer findings and stay, because `merge-change` step 6a forbids rewording a finding and that rule is the stronger one. The exemption is stated in Gaps rather than left for a fifth round to notice. Fixing this also introduced and caught a defect worth recording: a blind substitution corrupted three quoted test names, which a check that every test name cited in these documents exists in `tests/` then found.

**finding-13**: record — two withdrawal orphans survive in the record's own prose: round 1 finding-3's disposition still states "`DRAFT-FILE` gained its `FOREIGN-DRAFT` sibling", and Gaps states `M25` excises "the new classifier". There is no new classifier.
disposition: Accepted, both corrected. The finding's parenthetical confirmation of the M23 dead-anchor report is kept in Gaps.

**finding-14**: requirement — borderline. `tests/finalize-docs.bats:21` is still named `finalize: renames draft doc file to merge-dated name`, in the file this change adds six tests to. `PR-xec7dd`'s guard has been widened twice and has never reached `tests/`, which is where the claim the item exists to remove now survives in the change's own edited file.
disposition: Accepted and renamed. Tagged `requirement` correctly — the repair edits `tests/`, which the suite reads, so under this change's own rule it could not be dispositioned in place.

**finding-15**: record — three statements describe a base that has moved: the plan's baseline commit, its claim that `clanker-adoption` "is not merged", and the record's "rebased onto `3714f08`" where `319435b` is a merge commit.
disposition: Accepted, all three. The third is the one worth noting: the record described a rebase while its own gate section, AGENTS.md non-negotiable 5 and step 1 all describe a merge.

**finding-16**: record — borderline and small. The gate preamble calls `2324bb2` "the last commit before this record was rewritten for round 3"; `2324bb2` is that rewrite. The measurement is sound — only `48c83cb` follows it and touches only the record — so the gloss is wrong while the claim under it holds.
disposition: Accepted. The preamble now states the plain fact: this is the commit the figures were measured on, only the record has changed since, and no test reads it.

### Round 5

An agent reviewer off `6c0ea49`, told plainly not to soften a real finding to let
the change converge nor inflate a nit into one. It found the code, the scripts,
the tests and every gate figure clean, and re-derived all of them. Ten findings,
three tagged `requirement` — all three the fifth consecutive round in which one
rule's wording was the requirement-level problem, which is what ended that work.

**This section was missing from the record until round 6 found it absent.** The
ten findings below were read, fixed and committed on 2026-09-16; their account
existed only in commit messages. `check-review.sh` counted 42 findings and 42
dispositions and passed, because it cannot know a round happened that nobody
wrote down. That is `2026-09-10-field-report-items.md` finding-26's shape
exactly — a commit message is not the record — committed by the change whose
own subject is that the account of the work is what fails.

**finding-1**: requirement — step 6a's concrete file list is wrong for this repository, and so is the red-flag row's copy of it. Both read "`scripts/`, `tests/`, `skills/`, `templates/`, `install.sh` and every executable under `docs/`". `tests/skills.bats` also opens `README.md`, `AGENTS.md` and `docs/problems/README.md`, and `tests/portability.bats` opens `.gitignore`. Reproduced: I changed `README.md:114` from "the finalize date" to "the merge date" and `tests/skills.bats` went red. So an author applying the list literally tags a README-only disposition `record`, skips the suite, and moves it — the exact escape the sharpening exists to close. Round 4's own finding-2 named `README.md` and `AGENTS.md` as files `skills.bats` reads; the disposition built the list from `portability.bats` alone and dropped what its own finding named.
disposition: Accepted, and with findings 2 and 3 it ended the attempt rather than correcting it a sixth time. Five formulations of this boundary had now been rejected by five rounds, every one of them resting on naming a class of files no gate reads. The project owner ruled on 2026-09-16 to ship the two parts that had never drawn an objection — the finding tag and the stopping criterion — and to record the boundary open as `PR-kc2pzm` with all five attempts and the common failure named. The file list went with the rule.

**finding-2**: requirement — step 6a contradicts its own new rule twice, downstream of it. Lines 406-408 say "a round that returns findings never reaches a later step … everything after it runs only on the final, finding-free round", and lines 422-426 say "Findings block the merge … the sequence reruns from step 1" with no qualification. Both are pre-existing sentences this change did not touch, and both are now false: a round returning only `record` findings does reach 6b, and the last round is not finding-free.
disposition: Accepted. Both were rewritten to name the tag they now rest on. Round 6 then found that cutting the boundary rule had broken the pair again from the other direction, and the reconciliation that works is recorded under its finding-1: the tag decides whether another reviewer is dispatched, not whether the sequence reruns.

**finding-3**: requirement — two of the rule's five sites are guarded by nothing. Reproduced: I reverted the red-flag row to round 1's rejected wording *and* stripped the tag from step 6b's example block, then ran `tests/skills.bats` — 71 ok, 0 not ok. `merge-change: the reviewer tags every finding` greps the skill for the three tag words, which step 6a alone satisfies, so step 6b's block is unasserted; nothing reads the red-flag row at all.
disposition: Accepted. Moot for the boundary rule, which was cut, but the shape is not: the guard now asserts the rule's effect and rejects the superseded wordings by name, and step 6b's block is covered.

**finding-4**: record — round 4's finding-13 disposition says "Accepted, both corrected"; one was. Gaps still reads "`M25`, which excises the whole `DRAFT-FILE` gate still applies". There is no new classifier.
disposition: Accepted. Round 6 found it still standing, so it is recorded twice and repaired once — see round 6's finding-10.

**finding-5**: record — round 4's finding-15 disposition says "Accepted, all three"; two were. The record still reads "Branched from `main` at `d8502d1`, rebased onto `3714f08`". `319435b` is a merge commit.
disposition: Accepted. Round 6 found this one still standing too; see its finding-9.

**finding-6**: record — round 4's finding-7 was accepted and not repaired. The Round 1 heading still reads "Seven findings, six tagged `code` or `requirement`", contradicting the `verdict:` line, for the fifth round running on the same figure.
disposition: Accepted and repaired, counted from the tags in this document.

**finding-7**: record — the round 4 finding-12 substitution was run blind over the record and left ten ungrammatical constructions in the author's own prose: "dispositions had was delivered", "re-was run that mutation", "The reporting project was run 0.5.1", "It re-was run the full suite", "the claim in step 6a contains.", "It was run the suite".
disposition: Accepted, and it is the sharpest finding of the round. A blind regex was run over evidence documents and its output was not read; the disposition that introduced it recorded that a test-name check had caught three corrupted citations and stated nothing about the sentences, because nothing had checked them. All ten repaired by hand. Round 6 found three more sites the hand pass missed, which is recorded under its finding-14.

**finding-8**: record — the Gaps claim about the replaced vocabulary is wrong on both halves. The record holds 38 occurrences, not 21: 30 inside `**finding-N**:` lines and 8 outside them, six of those in `disposition:` lines, which are the author's own sentences and not protected by step 6a's no-rewording rule.
disposition: Accepted. Recounted mechanically rather than asserted: 30 inside quoted findings, 13 in the author's prose, all 13 repaired by hand. Round 6 recounted again under the scan `8d78cd4` ships and found three the hand pass left; see its finding-13.

**finding-9**: record — the plan's T3 "Files touched" note does not close. It says "The last four were added by review rounds" and then names three; one of the three is sixth of fifteen, and it attributes `docs/problems/README.md` to round 3 where `git log` shows round 2.
disposition: Accepted. Round 6 found the note still wrong; see its finding-16.

**finding-10**: record — the plan's struck T3 entry points at the wrong test: "removed at round 3 as a duplicate of the test below", where the test below is not the one it duplicated.
disposition: Accepted and corrected, naming both the test it duplicated and the test that later replaced that one.

### Round 6

An agent reviewer off `a91ae61`. **It found no defect in the scripts, the tests
or the gate figures**, and re-derived every one: the suite, both check scripts
against a probe worktree at `8d78cd4`, the test-name diff, the merge-base, the
writing scan across the widened pathspec, the mutation anchors, and the one
non-reddening test by mutation. Sixteen findings, **one** tagged `requirement`.

**finding-1**: requirement — the cut left `merge-change` step 6a stating two rules that cannot both hold for the case the change exists to define. "Every finding still sends the sequence back to step 1, whatever its tag" against "A round raising no `code` and no `requirement` finding is the last round. Its record findings are answered in the record it is about … and the sequence goes on to 6b." A round raising only `record` findings is told both to rerun from step 1 and to go on to 6b. `git diff c8b044b..6f5a50c` shows this is new: before the cut the pair was coherent, because a `record` finding was dispositioned in place, which is what made a record-only round the last one. Removing that clause without re-deriving the convergence rule left the rule unexecutable, and both guarding tests pin one half each and stay green.
disposition: Accepted, and it is the defect the cut introduced. The reconciliation is that "last round" was always about the **review**, not the sequence: a `code` or `requirement` finding sends the sequence back to step 1 *and* dispatches a fresh reviewer at 6a; a round raising neither reruns the sequence like any other but dispatches no further reviewer, ending at 6b. Step 6a, its red-flag row, the two neighbouring paragraphs and `templates/verification.md` all state that now, and the guard asserts both halves rather than one each. The finding's observation that two tests pinned one half apiece is the more useful half: a rule split across two guards is a rule neither guard can contradict.

**finding-2**: record — round 5 is not in the record. `## Review` has headings for rounds 1–4 only; `check-review.sh` counts 42 findings and 42 dispositions and passes. Round 5's findings and dispositions exist nowhere in the tree — the fix commits carry only their messages, which is the `2026-09-10-field-report-items.md` finding-26 shape verbatim. It also breaks a pointer this change ships: step 6a tells the next author "Anyone reaching for the saving should read that change's record first", and the fifth rejection is only in `PR-kc2pzm`.
disposition: Accepted, and it is the most serious finding of the round. Round 5's ten findings were read, fixed and committed; their account was never written down, so the record claimed four rounds while the ledger, the plan and the gate section each referred to five. Written in full, with a note at its head recording that it was missing and why the gate could not notice. The pointer step 6a ships now resolves.

**finding-3**: record — the withdrawn boundary rule survives in full in the record's own narrative, in "What was wrong, and what was built": "A `record` finding is dispositioned in place and does not re-run the suite … So a `record` finding whose disposition edits anything outside `docs/verification/` was never a record finding". That is the pre-round-1 directory formulation — the first of the five `PR-kc2pzm` records as rejected — stated in the present tense as what the change ships.
disposition: Accepted. That passage now states what the change ships: the tag bounds nothing, the convergence rule reads it, and the boundary is `PR-kc2pzm`.

**finding-4**: record — and in the plan. §3c item 2 states the withdrawn rule with the premise round 2 disproved, two lines above item 3's "The boundary … is NOT delivered". Item 3 also keeps the residue "and the disposition states that it was reclassified", which now refers to a reclassification the change does not define.
disposition: Accepted, both corrected.

**finding-5**: record — the red → green table names a test that does not exist and omits the one that replaced it. Row 19 is `merge-change: a record finding skips the suite, not the gates`; no such test is in `tests/`. That test — the guard on the boundary cut, this change's most contested deliverable — has no row, so it ships with no red → green attestation at all.
disposition: Accepted. The row names `merge-change: the tag does not shorten the sequence` and records that this row has been rewritten three times as the test it names was rewritten, which is the honest account of a guard that five rounds reshaped.

**finding-6**: record — the red → green preamble is keyed to the superseded base: "23, counted by test-name diff against the base at `3714f08`". Re-derived against `3714f08` the diff is 85 added and 58 removed; 23 is the figure against `8d78cd4`, which is what the gate table says nine lines earlier.
disposition: Accepted. The preamble names `8d78cd4` and quotes the derivation.

**finding-7**: record — the same stale base in the byte-identity claim, in two documents. `8d78cd4` rewrote both files, so against `3714f08` they are not byte-identical. A reader checking the open item's evidence at the commit it names gets a diff.
disposition: Accepted. Both now state the fact with its history: byte-identical to `3714f08` when the revert was made and to `8d78cd4` now, because `close-scan-scope` rewrote both files and this change took its versions whole.

**finding-8**: record — the ninth ledger item did not reach the counting sentences. The ledger has nine items and says so at line 19, but line 3 still opens "Seven of the eight items", the record's `Change:` line still reads "a ledger of eight", and the plan still reads "Three stay open".
disposition: Accepted. All three counts are now derived from the ledger's own `status:` lines rather than restated, which is what round 4's finding-11 disposition claimed to have done and did not repeat when round 5 opened the ninth item.

**finding-9**: record — round 4's finding-15 disposition claims a repair it did not make. The record still reads "rebased onto `3714f08`", byte-identical at the commit that wrote the disposition and now. The branch has no rebase in it.
disposition: Accepted. The sentence now names the two merge commits. Sixth round running for this shape, and it is booked in Gaps as the change's persistent defect rather than dispositioned again as if new.

**finding-10**: record — round 4's finding-13 disposition, "Accepted, both corrected", corrected one of two. Gaps still reads "`M25`, which excises the whole `DRAFT-FILE` gate including the new classifier". There is no new classifier.
disposition: Accepted and corrected, two rounds after it was first accepted.

**finding-11**: record — the plan's baseline and register sections describe the second base and the pre-`8d78cd4` scan, including "the scan reads `skills/*/SKILL.md` only" and "`clanker-adoption` is open".
disposition: Accepted. Both sections state the three base moves and the widened pathspec, and record what the widening cost this change.

**finding-12**: record — the gate preamble's absolute claim is false of the record's own prose: "Figures from the superseded trees are not reproduced anywhere in this record", while the Round 2 and Round 3 intros each report the count that round saw.
disposition: Accepted, and the rule was narrowed to what it can truthfully claim rather than the prose being cut. A round reporting the count it measured is evidence about that round; the gate table and the red → green table state no superseded figure, and the two that remain are inside quoted findings, which step 6a forbids rewording.

**finding-13**: record — Gaps' vocabulary accounting is wrong in both halves: 33 occurrences on 26 lines, three of them outside quoted findings, including in the sentence making the claim.
disposition: Accepted. Recounted with the scan `8d78cd4` ships, the three repaired, and the figure stated as derived-at-each-round rather than recalled — it has now been stated wrongly twice.

**finding-14**: record — round 5's hand repair of the blind substitution left three sites: `PR-hkc376` misquotes the template heading as "not contained forward" where the template says "not copied forward"; "had had been applied"; "It was run the suite".
disposition: Accepted, all three. The misquotation is the one worth naming: a resolved item's central citation matched neither the old template nor the new one, produced by a substitution over a quotation.

**finding-15**: record — `PR-3s74u3`'s resolution overstates its own guard, attributing the template's negative greps to a test that reads only the skill, and naming neither the fifth formulation.
disposition: Accepted and corrected to name which test covers which document.

**finding-16**: record — borderline. The plan's T3 "Files touched" note says "The last four" and enumerates three, one of which is sixth in the list, and attributes a file to round 3 where the record and the ledger both say round 2.
disposition: Accepted and corrected against `git log` rather than against the note's own account.

### Round 7

An agent reviewer off `47c0346`, on the fourth base. **It found no defect in the
scripts, the tests or the gate figures**, and its "verified clean" list is the
longest of the seven rounds: the suite, both check scripts byte-compared against
a probe worktree, the test-name diff, the writing scan across its whole
pathspec, the mutation anchors, the fourth base merge losing nothing from either
side, all four open items actionable as specifications, and every per-round tag
tally in the `verdict:` line correct. Fifteen findings, **one** tagged
`requirement`.

**Six of the fifteen were round-6 dispositions that claimed a repair and did not
make it**, and that is the finding behind the findings. The cause is mechanical
and is recorded here because no reviewer could have seen it: the repairs were
applied with literal string substitutions, and a substitution whose pattern has
a line break in a different place, or whose text an earlier edit already
altered, **replaces nothing and reports nothing**. Six dispositions were written
against edits that had silently not happened. The repair for round 7 was applied
by a script that fails loudly when a pattern is not found; it reported two
misses on its first run, both line-break placement, and those two are the reason
this paragraph can be written rather than repeated at round 8.

**finding-1**: requirement — the round-6 reconciliation did not reach both neighbouring paragraphs; one of them states its negation. `skills/merge-change/SKILL.md:406-411` reads "because a round that returns a `code` or `requirement` finding never reaches a later step. The paragraph below sends the sequence back to step 1, so everything after it runs only on the last round — the one raising no `code` and no `requirement` finding". The paragraph below sends the sequence back to step 1 for *every* finding, whatever its tag. So the last review round does **not** reach 6b, and a record-only round does **not** reach a later step either. The guard cannot catch it: it asserts `! grep -q 'finding-free round'`, which the rewritten sentence satisfies while keeping the inference.
disposition: Accepted. The paragraph now states the reason that is true for every tag — a round returning any finding never reaches a later step in that pass, and the pass that does reach 6b is the one after the last review round, which dispatches no reviewer and so creates no worktree to remove. The finding's observation about the guard is the more useful half and is answered too: asserting the absence of one spelling let a reworded sentence keep the inference, so the guard now asserts the claim that replaced it and rejects both inferences by shape. The two secondary sites, in the ledger and the plan, now state "the last review round" like the skill.

**finding-2**: record — the Round 1 heading still reads "Seven findings, six tagged `code` or `requirement`". Tallied from this document's own tags, round 1 is 2 `code` + 5 `requirement` = seven, which is what the `verdict:` line already states. Accepted at round 4 and again at round 5. Seventh round on the same figure, still unrepaired.
disposition: Accepted and repaired. Seventh round is the honest count, and the cause is the substitution fault recorded above.

**finding-3**: record — round 6's finding-14 disposition says "Accepted, all three"; one was. Both surviving sites are quoted verbatim in the finding.
disposition: Accepted, both repaired.

**finding-4**: record — round 6's finding-10 disposition ("Accepted and corrected, two rounds after it was first accepted") did not correct it. Gaps still reads "`M25`, which excises the whole `DRAFT-FILE` gate including the new classifier". Accepted at rounds 4, 5 and 6 — three acceptances, no repair.
disposition: Accepted and, on the fourth acceptance, actually repaired.

**finding-5**: record — round 6's finding-4 disposition ("Accepted, both corrected") corrected one. The plan's §3c item 3 still ends "and the disposition states that it was reclassified", referring to a reclassification this change does not define.
disposition: Accepted, repaired.

**finding-6**: record — round 6's finding-11 disposition left the register section self-contradicting: it describes the widened scan and then, ten lines later, "while the scan reads `skills/*/SKILL.md` only".
disposition: Accepted. The sentence now states that reading as what was true before `8d78cd4`.

**finding-7**: record — round 6's finding-15 disposition left the misattribution in place. `PR-3s74u3` still says one test "rejects all five superseded boundary wordings by name in both the skill and the template". That test reads the skill only and rejects two; the template's four negative greps live in another test.
disposition: Accepted. The item now names which test reads which document and how many wordings each rejects, and states that no single test covers both and neither names all five.

**finding-8**: record — round 6's finding-16 disposition ("corrected against `git log`") made no change. The plan's T3 note still reads "The last four were added by review rounds" and enumerates three, one of which is sixth of fifteen, and attributes a file to round 3 where `git log` puts it in rounds 1 and 2.
disposition: Accepted, repaired against `git log` this time.

**finding-9**: record — the fourth base merge was not swept through the plan, which still states the evidence is keyed to `8d78cd4`.
disposition: Accepted, repaired.

**finding-10**: record — the record's account of the base moves is wrong in two ways. "the base was merged in twice, at `319435b` and `7cc59a2`" — there are three, the third being `70a6f9e`. And "The base moved four times" while its own chain lists three moves, with the plan stating twice: three statements of one figure, three values.
disposition: Accepted, and the figure is now derived rather than recalled. `d8502d1` is the fork point, not a move; the base moved three times, to `3714f08`, `8d78cd4` and `650f090`, and was merged in three times at `319435b`, `7cc59a2` and `70a6f9e`. Every statement of it in the three documents now states three.

**finding-11**: record — a superseded base survives in a disposition: "reverted byte-identical to the base (then `3714f08`, now `8d78cd4`)". The twin sentence in the ledger was updated and this one was not, which is what round 6's finding-7 asked for in two documents.
disposition: Accepted, repaired.

**finding-12**: record — the gate preamble's standing claim is false: "Only this record has changed since, and no test reads it" — `git diff --name-only 47c0346 HEAD` returns the record and the ledger, and the ledger is read by `check-trace.sh` and by the writing scan. The figures do hold, re-derived at HEAD; the sentence that licenses them does not.
disposition: Accepted, and answered by sequencing rather than by wording. Every repair from this round was committed first, the figures were then re-derived against that commit, and only the record was edited afterwards — so the sentence is true of the commit the table now names. That ordering is what the claim always needed and is now what produced it.

**finding-13**: record — round 6's finding-12 disposition narrowed the preamble to a claim that is also false: the two superseded figures are in the author's round intros, not quoted findings, and the quoted findings carry many more than two.
disposition: Accepted. The preamble now states what is true of each place separately: none in the gate table or the red → green table, two in the round intros, and more inside the quoted findings, all of them evidence about what a round measured.

**finding-14**: record — the `PR-hkc376` narrative paragraph is a superseded copy of the account the gate table gives correctly nine lines earlier: "26, 27, 28 … all three rounds" against the table's "26, 27, 28, 29 and now 31" across six rounds and four base moves.
disposition: Accepted, and the duplicate is deleted rather than corrected. The demonstration is stated once, under the table; the paragraph now points there and records that it was itself an instance of the defect it described — an account restated in a second place and not re-derived when the first moved.

**finding-15**: record — Gaps' vocabulary accounting is wrong for the third round running: 44 occurrences on 35 lines, not "thirty-five uses", and one of them is a `disposition:` line, which is the author's own sentence.
disposition: Accepted. Three sites outside the quoted findings were repaired — including one written by this round's own fix for finding-14 — and the figure is now stated as what a mechanical count gives, with the record of having been stated wrongly three times kept beside it.

### Round 8

An agent reviewer off `32ebdbd`. **Ten findings, every one tagged `record`. No
`code` finding and no `requirement` finding** — so by the criterion this change
ships, round 8 is the last review round. Its verified-clean list is the longest
of the eight and was independently re-derived rather than read from this record:
the suite, both check scripts byte-compared in a probe worktree, the tree the
gate table names matching byte for byte, `abb1bab..HEAD` touching only the
record, the test-name diff and every red → green row reconciling one-to-one with
it, all 184 mutation scripts dry-run at base and head with none newly dead, all
83 prior findings tagged and tallied exactly as the `verdict:` line states, the
convergence rule consistent across all six sites, the five resolved items doing
what they claim in the tree, and the four open items actionable as
specifications.

**Three of its ten are round 7's own dispositions claiming repairs the tree does
not contain**, and two of those are line-break splits — the exact case round 7's
diagnosis named. Round 7 built the loud-failing pass and the pass worked: it
reported its misses. What it could not do is catch a repair aimed at the wrong
site. The record's round-7 note called those two misses "the reason this
paragraph can be written rather than repeated at round 8"; round 8 repeated it.
The discipline that actually closes this is not a better pass but a check
afterwards — grep the tree for the defect, not the patch for its pattern — and
every repair in this round was verified that way.

**finding-1**: record — round 7's finding-3 disposition ("Accepted, both repaired") repaired neither survivor, and both are still in the tree: "round 1's dispositions had / had been applied", split across a line break, and `PR-hkc376` quoting the template heading as "not / contained forward", also split, where the base says "not copied forward" and this change replaces the heading outright, so the citation matches no version. These are the two sites round 6's finding-14 named and round 7's pass was said to have closed.
disposition: Accepted, both repaired and both verified by grepping the tree afterwards. The cause is narrower than round 7's diagnosis and worth stating exactly: round 7's pass did not silently miss these — it was never aimed at them. Its pattern named "round 2's dispositions" where the defect was at round 1's. A pass that fails loudly proves only that what it targeted existed; it proves nothing about what it did not target. The citation now quotes the base's wording verbatim, checked with `git show 650f090:templates/verification.md`.

**finding-2**: record — round 7's finding-8 disposition ("repaired against `git log` this time") made no change at all; `git show 56d9def -- docs/plans/...` contains sixteen changed lines and none is this note. The plan still reads "The last four were added by review rounds" and enumerates three, one of them sixth of fifteen, with a file attributed to round 3 where `git log` puts it in round 1.
disposition: Accepted. Rewritten from `git log` this time in fact rather than in claim: three of the fifteen were added by review rounds, all three in `752c575`, which is round 1's fix commit.

**finding-3**: record — the Gaps vocabulary accounting is wrong in both halves, fourth round running: the scan gives 41 lines carrying 51 uses, and "Forty-one uses" is the line count — the exact conflation round 7's finding-15 corrected, restated one round later under a sentence claiming the figure is what a mechanical count gives. Two sites are outside the quoted findings, both `disposition:` lines written by round 7's own fix.
disposition: Accepted. Both sites repaired, and the paragraph now states uses and lines as two figures with their units named, because conflating them is what went wrong three of the four times. The count is taken from the scan at the moment of writing rather than copied forward.

**finding-4**: record — the plan's register section still contradicts itself ten lines apart: it gives the widened pathspec, which includes `scripts` and `docs/problems`, then concludes that script comments and the ledger are "reported by nothing — check them by hand". The repair changed the antecedent and left the consequent standing, which is the same shape as the defect it answered.
disposition: Accepted. The consequent now follows from the antecedent: since `8d78cd4` only the plan and the record are unscanned, because that change put them permanently out of scope as merged evidence, and those two are what an author checks by hand.

**finding-5**: record — the `verdict:` line states one claim twice. Round 7's update appended its sentence without removing the superseded one, whose only remaining content duplicates a tally beside it. This is the "account restated in a second place" defect the record indicts itself for, in its own opening field.
disposition: Accepted, the superseded sentence deleted.

**finding-6**: record — the plan carries a third, uncorrected copy of the byte-identity claim, naming `3714f08` where those two files differ by 29 lines. The record and the ledger both carry the corrected form; round 6's finding-7 said "in two documents" and the plan was never in either count.
disposition: Accepted. The third copy now states the same thing as the other two, and without a commit hash that a later base move would falsify again — which is what made this the third copy rather than the last.

**finding-7**: record — `PR-3s74u3`'s evidence sentence miscounts the guard round 7 rewrote it to describe: the test has four negative greps, not two, and its own comment calls them rejected "by shape rather than by one spelling", which "by name" contradicts.
disposition: Accepted, corrected to four and to "by shape".

**finding-8**: record — `PR-9zvb36`'s `affects:` names two scripts but not `skills/merge-change/SKILL.md`, which this change edits for the item and against which it ships a test carrying `verifies: PR-9zvb36`. Round 1's finding-4 accepted the point in terms and did not widen the line.
disposition: Accepted, the file added with what it contributed.

**finding-9**: record — the base-merge paragraph misstates two figures: "seven of the eight skill files this change edits" (this change edits six files under `skills/`; the eight are the overlapping set, which Gaps states correctly) and "`close-scan-scope` touched 49 files" where every derivation gives 51.
disposition: Accepted, both corrected, the second re-derived rather than adjusted.

**finding-10**: record — one red → green row no longer reproduces against the base the table names: `check-traceability: MALFORMED-STATUS knows there are three values` stays green when `skills/` is reverted, because `650f090` repaired that row independently. The record states the fact twelve lines above the table; the table's preamble names only one exception.
disposition: Accepted, and it is the most interesting finding of the round. The preamble now names both exceptions and states why this one exists: an upstream change repaired what a test asserts, so the test still guards the right property while this change's diff no longer contains the edit. The row is kept rather than deleted, because the assertion is the one the item wants and the guard is worth having whoever made the repair.

## Gaps

**`PR-9xxz3b` is recorded, not fixed.** The `--scope=change|ledger` filter is
sound and additive; what is rejected is a new exit code (`tests/check-trace.bats`
asserts exit 1 in 143 places, and every adopter's CI line reads the same
contract) and moving the limits out of `merge-change` (this toolkit has no
scheduler, so an on-demand ledger review happens when someone remembers it).
The item states both, so its own change need not re-derive them.

**A dead mutation anchor was found here and has since been repaired
elsewhere.** `M23.sh` in `docs/verification/2026-08-22-id-tokens.mutations/`
anchored on a `--allow-draft-files` case pattern written without its leading
`(`, which commit `3fe5eb3` (2026-09-03) had rewritten, so the mutation was
unreproducible — verified during this change, not caused by it, and inside
`PR-crcee5`'s 38. It is no longer dead: `47a8b1d` repaired that anchor along
with the rest of the corpus and added `tests/mutations.bats`, a gate requiring
every mutation to apply or declare itself retired. This change's own edits pass
that gate (7 of 7), which is the first time the corpus has been checked rather
than asserted. The sweep this paragraph called for in an earlier draft was done
by that change rather than by this one. `M25`, which excises the whole
`DRAFT-FILE` gate, still applies; `M22` is likewise intact.

**The suite was not dispatched to a subagent.** AGENTS.md non-negotiable 3 and
`verify-before-merge` both require it. It was run from the change worktree as a
background command with its output written outside the tree, and the verdict
read from the pass/fail counts. The reason is measured and recorded in the
previous change's plan: `sh tests/run-tests.sh` takes 25+ minutes and a
dispatched subagent silent that long is terminated by a no-progress watchdog
with its work uncommitted. The property the rule protects — raw output never
entering the dispatcher's context, the verdict taken from counts rather than
from an exit code — is preserved. The isolation is not, and a run in the
author's own worktree is the author's run. The reviewer at 6a re-executed the suite
independently, which is where that coverage is restored.

**The gates run under a synthesized config, and every figure moves with it.**
This repository has no `.guardrails/` of its own — it does not self-host its
gates (`2026-08-22-ratchet-gap-analysis.md`) — so `check-ids.sh` and
`check-trace.sh` were run under a config written for this measurement, the same
one the previous record used:

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

It declares `PR` alone because the problem ledger is the only ledger this change
touches. Both scripts exit 1 on this tree by construction — its fixtures, plans
and script comments are full of illustrative draft tokens and definition forms.
What makes the rows meaningful is the comparison against the base under the
identical config, which is how both are stated above. The real gate for this
repository is `tests/run-tests.sh` (AGENTS.md non-negotiable 3), green at the count the gate
table above states for the tree it names.

**`finalize-docs.sh` was run with `GR_CONFIG` pointing at that synthesized
config**, for the same reason. Its rename and its new report were exercised on
this change's own ledger, which is the live evidence quoted above, but the run
was not the ordinary one a downstream project makes.

**This change's most persistent defect was its own record-keeping**, and it is
stated here rather than left implicit across ninety-three findings. In every round, a
disposition claimed a repair it had made at one site and not at its copies:
round 2's finding-4 named the shape, and rounds 3 through 7 each found more
instances of it — including one reading "All three corrected" having corrected
two, one reading "Accepted, both corrected" that three later rounds found still
uncorrected, and six at once in round 7. Round 5's account went unwritten
altogether until round 6 found it missing.

**The cause was mechanical and took seven rounds to find, because it is
invisible from inside.** The repairs were applied as literal string
substitutions, and a substitution whose pattern has a line break in a different
place — or whose text an earlier edit already changed — matches nothing, changes
nothing, and reports nothing. The disposition was then written from the
intention rather than from the tree. Nothing in this toolkit would catch that:
`check-review.sh` checks that a finding has a disposition, not that the
disposition is true, and a reviewer who reads the record against the tree is the
only party who can. Seven of them did, one after another. The repair is trivial
once named — an editing pass that fails loudly when a pattern is not found — and
round 7's pass reported two misses on its first run, both line-break placement. The code and the tests converged after round 1; the
documents took six rounds, and what kept failing was not the work but the
account of it — which is the finding the reporting project's §6 makes, reproduced
here by the change that answers it.

**53 uses of AGENTS.md's replaced vocabulary remain in this record, on 40
lines, and are deliberate.** Every one is inside a reviewer finding quoted
verbatim, and two rules protect them.

That figure has been stated wrongly four times — as 21, then 35, then 41, each
time by recall or by a count of lines offered as a count of uses, and each time a
review round re-derived it and found author prose hiding among the quotations.
Both numbers are given above because conflating them is what went wrong three of
those four times. The lesson is the one this record keeps relearning: a number
nobody re-derives is a number that is wrong, and a number whose units are not
stated is a number nobody can re-derive. `merge-change` step 6a forbids rewording a finding — "a finding
reworded by the author is the author's finding". And since `8d78cd4` the writing
scan itself puts `docs/verification/` and `docs/plans/` permanently out of scope,
because they are merged evidence and editing a record to match a later tree
falsifies what it proved. Every occurrence in this change's own prose — across
the record, the plan and the ledger — was replaced, the ledger under the widened
scan that now reads it.

**Three items from the previous change remain open** — `PR-h3wujj`,
`PR-crcee5` and `PR-z6uaa8`.

**The conflict with `clanker-adoption` happened, and is resolved.** That change
reached its signed squash first, on 2026-09-16. What the plan predicted is what
occurred: seven of the eight overlapping files, two of them conflicting, both
resolved by hand in favour of this change's content in that change's vocabulary.
The details are under The gate. Nothing about it remains open.

**`PR-z6uaa8` still bears on this change directly.** The skills an agent
executes are installed copies that nothing keeps in step with `skills/`. Every
skill edit here is on the change branch and will be on `main`; whether it reaches
the harness that runs the next change is exactly what that item states nothing
measures. Two changes have now been merged since it was opened.
