# Verification — close-scan-scope (2026-09-16)

branch: close-scan-scope
reviewer: dispatched subagents, three rounds, each in its own nested task worktree off the change branch, each given the repository, the diff and the two planning documents as claims to check, and no account of how the change was made. Rounds 1 and 2 were independent sweeps of the whole change, the second reading the tree the first round's fixes produced. Round 3 was targeted: it read the tree both earlier rounds' fixes produced, with their dispositions as the claims to check.
verdict: three rounds. **Round 1** raised ten findings and all ten are fixed. **Round 2** raised nineteen and all are fixed except its finding 5. **Round 3**, a targeted review of the tree the first two rounds' fixes produced, raised six: five are fixed and one is recorded as a known limit. **One finding remains open — round 2's finding 5.** The scope guard's exclusion list is an inline copy of the four exclusions D1 names in prose, and nothing compares the two, so one line changed in each place removes a whole ledger from the scan with every test green. It is open by decision, not by oversight: a test that compares the two is a test whose own copy of that prose can be edited in the same commit, so the pin buys one more edit of distance and not closure. The argument is in Gaps.

Round 1 raised ten findings: three defects in the shipped scan, three gaps in what the scan reads or in what the sweep left behind, and four defects in this change's records. All ten are dispositioned below and all ten are fixed, in `4254ff1` and in the record commits before it.

Round 2 raised nineteen. Fixed: **1, 2 in part, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 and 19** — 1 in `892d7a7`, 2, 7, 8 and 19 in `4c3e04d`, 3, 4 and 6 in `520e1e0`, and 9 to 18 in this record and in the two planning documents. **Findings 3, 4 and 6 were recorded here as open by decision and are no longer open**: `520e1e0` bounds both exempt regions rather than only closing them, reads the section closer from one function, and compares this repository's own replace list against the shipped one. Each disposition below states the guard and the proof. **Open: 5**, stated in Gaps with what the reviewer proved, the exact edit that defeats the guard, and the argument for stopping. The residue of 2 — the bare form the word table leaves unscanned, and 23 lines the sweep reworded that no shipped rule required — is not an open finding but a measured decision, also in Gaps.

Round 3 read the tree the first two rounds' fixes produced and took their dispositions as claims to check. It raised six findings, two of them minor: a figure in this record that nobody had measured, a fifth guard of the same shape as the four listed as open that this record had failed to list at all, a comment promising an exit-status contract the code did not provide, a closer pattern written twice, a disagreement between this record and the decision record about one changed line under `scripts/`, and one known limit. Three are fixed in `520e1e0`, two in these records, and the sixth is recorded as a known limit in Gaps.

What the reviewers checked and found correct is recorded below too, because a review that reports only defects understates what it establishes.
reproduced: partly, and the parts are separated below. The gap this change closes was reproduced before the change: at `3714f08` the scan read `skills/*/SKILL.md` alone, and 674 word-bounded occurrences of the replaced vocabulary were counted in tracked files the rules bind, none reported by any gate. The scan's new reach was reproduced by deletion in T6 — `load-bearing` reintroduced at `scripts/check-units.sh:108` reddened it, naming that file and line — and the reviewer reproduced that independently in its own worktree. The stale mutation evidence this change measured was reproduced against a scratch checkout of the base revision. Four of the six per-task red site counts could NOT be reproduced from the diff by the reviewer, which the reviewer reported as such rather than as false figures; they are recorded below as attestations, not as figures a later party can recheck.

Change: the writing scan reads every tracked file the rules bind, its word table
is checked against the shipped replace list, and the tree is swept clean.
Branched from `main` at `3714f08`.
Plan: `docs/plans/2026-09-16-scan-scope-implementation.md`.
Decisions: `docs/plans/2026-09-16-scan-scope.md`, D1–D6.

## The gate

Every figure below was derived from the tree under test. Where this record's
author did not observe a figure directly, the party that observed it is named.

| Gate | Result |
| --- | --- |
| `tests/.bats-core/bin/bats tests/*.bats` | **`1..692`, 692 ok, 0 not ok** on the tree being merged. Observed by the second round's reviewer in its own worktree off the change branch, and confirmed by the dispatcher on the change branch itself. The `1..692` plan line and the zero `not ok` count are the verdict; the exit status is not. **Both observations predate `520e1e0`**, which adds no test and changes no file but `tests/skills.bats`. No party has re-run the whole suite since. What was run at this head, for the third correction, is that one file: `1..59`, 59 ok, 0 not ok |
| `@test` count, checked against the plan line | 692 on the branch, 688 at `main`. Counted again for this correction with `grep -h '^@test ' tests/*.bats \| wc -l` (692) and `git grep -h '^@test ' main -- 'tests/*.bats' \| wc -l` (688). Measured a third time at `520e1e0` with the same two commands: unchanged, because that commit adds no test |
| `scripts/check-trace.sh` | Inapplicable. Run in this worktree: exit **2**, `guardrails: file not found: .guardrails/config.yaml` |
| `scripts/check-ids.sh` | Inapplicable. Run in this worktree: exit **2**, same message |
| `scripts/check-review.sh` | Inapplicable. Run in this worktree: exit **2**, same message |
| `scripts/check-signing.sh --strict` | Exit **1**, `UNSIGNED 520e1e01e1da70e974da427bb5b9c79e0cf54844 (no signature)`, re-run at the branch tip for this third correction; it named `892d7a7` at the second and `c3ec7d6` at the first, each a different tree. Worktree commits are unsigned by design; the squash into `main` is signed by the user, and that signature is the one the gate exists to check |
| Coverage, against the class target | Inapplicable. No config, so no `coverage_command`. Class A requires none (`docs/adr/2026-08-22-safety-class.md`) |
| Working tree | Clean. `git status --porcelain` reports nothing |

**The gate row stated `1..689` and described a tree that was never merged.** It
was written in a worktree off one parent while three new tests — the word-table
key guard, the form canary and the scope guard — were being added on the
sibling parent. Neither parent was the tree the change ships: the merge at
`1357cf5` produced 692. The figure was not wrong when it was observed; it was
recorded as the gate result for a tree that did not exist yet, which is the
same defect as quoting a figure nobody measured. A gate row describes the tree
being merged, and no other.

This repository does not self-host its gates
(`docs/plans/2026-08-22-ratchet-gap-analysis.md`). The four inapplicable rows
are reported with the evidence that makes them inapplicable. A gate that cannot
run is not a gate that agreed, and none of these four rows is a pass.

## Red → green

One row per task, copied from the task records in the implementation plan. The
subagent that ran each task is the only party that observed its test fail, so
these rows are attestations. The reviewer reproduced the T6 deletion proof and
could not reproduce four of the six site counts from the diff; both facts are
recorded here rather than resolved.

| Item | Test | Watched red |
| --- | --- | --- |
| D4 (T1) | `clanker: the word table and the shipped replace list name the same words` | Proved in both directions. T1 removed `sits -> is in` from the shipped block and watched the test report the divergence. T6 removed `says -> states` and the test reported `not ok 54`, printing 8 shipped words against 9 table keys; reverted green |
| D1, D2, D3 (T1) | `clanker: no file in scope contains the replaced vocabulary` | 7 sites: `install.sh:9`, `skills/ratchet/SKILL.md:384`, and five in `tests/skills.bats` outside the exempt region. 12 sites swept across five files |
| D1 (T2) | the same test, pathspec widened | 133 sites across `README.md`, `templates/`, `docs/problems/` and `docs/risk/`. The plan predicted about 139; the scan reports one line per site and several lines contain two matches |
| D1 (T3) | the same test, pathspec widened | 124 sites across `scripts/lib.sh` and the five test files that read it |
| D1 (T4) | the same test, pathspec widened | 138 sites across `finish-merge` and `check-signing`, plus one mutation anchor re-cut and re-proved |
| D1 (T5) | the same test, pathspec widened | 112 sites across `check-trace` and `check-ids` |
| D1 (T6) | the same test, pathspec at the full D1 list | `not ok 55`, 75 sites, the first of them `scripts/check-review.sh:9`. The plan predicted about 77 |
| D2, D3 (T6) | the same test, proved by deletion | `load-bearing` reintroduced at `scripts/check-units.sh:108`, a file the pathspec reaches only through T6's widening. The test reported `not ok 55` naming that file and that line; reverted green. **An independent reviewer reproduced this** |
| D5 | none | D5 is a record requirement. The rename map below is its implementation, and what was checked about the map is recorded with it |
| D6 | none | D6 decides not to ship `scripts/check-writing.sh`. A decision not to build is recorded, not tested |

## What was wrong, and what was built

At `3714f08` the writing rules bound every file in this repository and the scan
that enforces them read `skills/*/SKILL.md` and nothing else. Measured at that
commit with the scan's own word list extended by the `sit` family, 674
word-bounded occurrences of the replaced vocabulary were in tracked files the
rules bind, and no gate reported one of them. The predecessor change had already
demonstrated the consequence: its second deslop pass found `lands on` and `holds
for` in `AGENTS.md` prose, outside the rule text, reported by nothing.

The word list was also disconnected from the shipped rule. The list in
`tests/skills.bats` was a hand copy of the replace list in
`templates/AGENTS-block.md`, and no check compared them, so a word added to the
rule reached no scan.

This change widens the pathspec to every tracked file except the merged records,
replaces the hand copy with a table keyed by the shipped replace list and a test
that compares the two sets in both directions, exempts one named region per
vocabulary file instead of exempting whole files, adds `sits -> is in` to the
rule, and sweeps the tree in six serial tasks. 589 sites were reported red and
swept across the six tasks, against about 629 occurrences in scope once the
three exempt regions are subtracted; the two figures measure different units.
57 `@test` names changed — 56 by the sweep and one by the scan test's widening — and
four tests are new.

## Review — round 1

One block per finding, with its disposition.

The findings in this section are round 1's; round 2's are numbered separately
in the section after it. Six of the ten — 1, 2, 3, 7, 8 and 9 — were fixed by a
concurrent task
working in `tests/` and `scripts/`, trees this record's author was restricted
from. Their dispositions state what was done and name no test or line number,
because the party that observed each fix go red and then green is the party
that records that detail. Findings 4, 5, 6 and 10 were fixed in the records, by
this record's author, and their dispositions state what was checked.

**finding-1**: both new tests pass with the scan's word forms replaced by
nonsense. The forms are inside the region the scan exempts from itself, so
corrupting the table corrupts nothing the scan then reads, and the agreement
test compares only the keys — the column the corruption does not touch. A scan
whose word list can be emptied without any test reddening is the defect this
change exists to prevent, one layer further in.
disposition: fixed in this change. The forms the scan reads are now pinned by a
test that reddens when they are corrupted, so the exempt region no longer puts
the table beyond every check. The concurrent task that made the fix records the
test and the red it observed.

**finding-2**: the pathspec is pinned by nothing. The reviewer reduced
`gr_writing_paths` to three surfaces and the suite stayed green, and added a new
tracked file outside the pathspec and the suite stayed green. D1 states that
scope is total over tracked files; nothing tested that claim.
disposition: fixed in this change. The totality D1 claims is now checked against
the tracked file list rather than asserted in prose, so a reduced pathspec and
an unscanned tracked file each redden the suite. The concurrent task records the
test.

**finding-3**: the exemption guard counts files rather than regions. It asserts
that the markdown opener occurs in exactly two files and the table opener in
exactly one, so a second exempt heading added to `AGENTS.md` passes, and
demoting the heading that closes the region in the shipped block passes while
silently widening the exemption to the rest of the file. D2 states that the
guard exists against exactly this failure and names it the failure mode with no
symptom.
disposition: fixed in this change. The guard now counts exempt regions and their
boundaries rather than the files that contain an opener, so a second opener and
an unclosed region each redden it. The concurrent task records the test.

**finding-4**: D5 is not implemented. There is no verification record for this
change and no rename map, so 57 renamed `@test` names have 30 stale citations in
merged records with no single place to resolve them.
disposition: fixed here. This record is the implementation, and the rename map
is its last section. The map's 57 rows were re-verified against the merged tree
at `892d7a7`, after the three fix commits changed `tests/skills.bats` again:
every new name occurs exactly once in `tests/*.bats`, in the file the map names
for it, and no old name occurs anywhere in `tests/*.bats`. 30 of the old names
are cited, on 48 distinct lines in 14 merged records, and no file the scan
reads cites a test that no longer exists. The arithmetic is stated with the map
and is 57 rows, not the 58 D5 first required; see finding-12 of round 2.

**finding-5**: T6 has no task record. The implementation plan's task records
stop at T5, so the task that closed the pathspec, swept the last 75 sites and
performed the deletion proof that is the point of the change was the only task
with no durable account.
disposition: fixed here. `docs/plans/2026-09-16-scan-scope-implementation.md`
now has a `### T6 — merged at 673b684` record in the same shape as T1 to T5: the
suite plan lines and `not ok` counts, the red observed before the sweep, the
files and their diffs, both deletion proofs with the `not ok` numbers they
produced, the mutation replay, and the two holes the task found.

**finding-6**: three rows of the Measurements table are wrong and the total is
not the sum of its own rows. The table was counted before `sits` joined the word
list while the record prints a command that already includes
`sit|sits|sitting`, so the record printed a command that does not produce the
figures beside it.
disposition: fixed here, and the error is recorded rather than repaired in
silence. `scripts/` 185 became 195, `tests/` 307 became 316, and the single
combined row of 81 for the three `docs/` directories became `docs/problems/` 70,
`docs/risk/` 13 and `docs/adr/` 0. The total 664 became 674, which is now the
sum of the rows. Every row was recounted at `3714f08` with the record's own
command by this record's author, and two further parties reproduced the same
figures independently. The derived figure of "about 617 edits" was recomputed:
45 of the 674 are inside the three regions D2 exempts — 10 in the rule text in
`AGENTS.md`, 10 in the rule text in the block, 25 on the `banned=` lines that
become the word table — so the sweep is about 629 occurrences. The tasks report
589 sites, which is a different unit, and the record now states that rather than
reconciling two numbers that do not measure the same thing.

**finding-7**: bare `hold` and `say` are unscanned, and 7 and 14 sites of them
remain in the tree. The word table excludes them deliberately, because `when all
three hold` and `say so` are correct English, but the record does not state what
that exclusion costs.
disposition: fixed in this change. The remaining sites were reviewed and the
tree no longer spells the same idiom two ways through that gap. The concurrent
task records what it edited.

**finding-8**: `says so` and `said so` were swept into non-English while `say
so` was left alone, so the tree spells one idiom two ways. The sweep applied a
word-form rule to an idiom the word table deliberately exempts in its bare form.
disposition: fixed in this change, together with finding-7; the idiom is spelled
one way. The concurrent task records the sites.

**finding-9**: the verbatim git-output exemption applies to every in-scope file,
not only the one the record names. The scan removes git's own `refusing to
update checked out branch` and `refusing to fetch into branch` from every line
it reads, so any file may quote those phrases and the record states the
exemption as belonging to one skill.
disposition: fixed in this change. The exemption's reach now matches what the
record states about it. The concurrent task records the test.

**finding-10**: D1 excludes `docs/plans/` and `docs/verification/` because
editing a merged record falsifies the evidence in it, but `docs/problems/` and
`docs/risk/` are merged records too — problem items with reproduction evidence,
and ISO 14971 hazard analyses — and this change edits twelve files under them.
The record gives no reason why the argument that protects one group does not
protect the other. Two of the edits are restatements rather than word
substitutions: `docs/problems/2026-09-02-bash32-case-parse.md:18`, where a
recorded root cause was reworded, and
`docs/problems/2026-09-15-class-b-report.md:66`.
disposition: recorded as an inconsistency, not argued away. D1 now states that
the exclusion reason does not draw the line the decision draws. It also states
the one real difference — the problem and risk ledgers are live documents that
`check-trace.sh` reads and that later changes are expected to edit, while
nothing reads or edits a plan or a verification record after its change is
merged — and states that this difference governs the ledger fields and not the
evidence prose beside them. Both restatements are quoted in D1 as the measured
cost. The twelve edited files were confirmed by diff against `main`, and both
quoted lines were confirmed against both revisions. D1 states that this change
does not settle the question and names the two ways a later change could.

## Review — round 2

The second round read the tree round 1's fixes produced and raised nineteen
findings. Eighteen are fixed, one of them only in part. One is open by
decision, finding 5, and it is stated in Gaps with the residue of the partial
one. Findings 3, 4 and 6 were recorded here as open by decision and
were closed afterwards, in `520e1e0`; their dispositions below state the guard
that closes each and the proof the dispatcher observed.

The numbering restarts per round: `finding-3` below is round 2's, not round
1's. Both sections use the toolkit's finding grammar, one `**finding-N**:`
header per finding with its own `disposition:`.

**finding-1**: the word table can be reduced to its bare keys and every check
still passes. The agreement test compares the table's keys against the shipped
replace list, and the key-among-forms test compares each row against its own
key, so a table whose every row is `carries carries`, `lands lands` and so on
is self-consistent — and the scan then reads no inflection at all. Every check
compares the table against itself, and the shipped replace list names one word
per rule, so nothing outside the table can supply the inflections.
disposition: fixed in `892d7a7`. `clanker: the scan's own grep reports every
form in the word table` now requires at least 58 form spellings — the 29
distinct forms, each in lower and upper case — before it scans the canary.
Measured here: the shipped table yields exactly 58, so the floor is at the
value it guards and a single deleted form reports. A floor is a weak pin and
the test states this in its own comment: raise it when a row is added, and
lowering it is the edit the guard exists to expose.

**finding-2**: the rule was narrowing the tree instead of reporting it. F1 had
put the bare `say` in the word table, and correct English was deleted to keep
the suite green — one `say-so` and four parenthetical uses meaning "for
example" — while the exemption chain, a hand-written case-sensitive `sed`,
could not exempt the all-capitals `SAID SO` in `scripts/check-review.sh:311`,
which had therefore been rewritten into non-English.
disposition: fixed in part, in `4c3e04d`. The bare `say` is removed from the
table and the five deleted uses are restored from the base revision:
`skills/worktree-discipline/SKILL.md` "explicit say-so", `scripts/lib.sh`
"(ADR, say)", `skills/ratchet/SKILL.md` "(no network to vendor bats-core,
say)", `templates/AGENTS-block.md:22` "`a3k9z2`, say", and
`skills/check-traceability/SKILL.md` "block, say". `SAID SO` is restored, and
the `sed` chain is replaced by `gr_writing_exemptions`, seven `path|phrase`
entries compiled into one case-insensitive `sed` script. D4 now states why the
bare `say` is the one form deliberately left unscanned. **The residue is
open**: 11 bare-`say` sites remain in scope, no gate reads them, and 23 further
lines were swept from a bare `say` to `state`-family wording that no shipped
rule required. Both are measured in Gaps.

**finding-3**: a markdown exempt region can be re-closed further down, so
arbitrary content is inside it, unscanned. The guard counts openers and
requires a closer to exist; it does not pin where the closer is, nor the region
to the rule text.
disposition: fixed in `520e1e0`, guard 4, after being recorded here as open by
decision. Both exempt regions are bounded now rather than merely closed: a
writing section longer than 35 lines, or one that reaches end of file, is
reported by name and line, so a closer moved further down is reported instead
of obeyed. The two sections are 21 lines each, measured at this head, so the
bound leaves room to edit the rule text and none to re-close a region around a
document. Proof, by the dispatcher, applied and reverted: demoting the heading
that closes the section in `templates/AGENTS-block.md` gives `not ok 58`,
`templates/AGENTS-block.md:68: writing section, 42 lines`. What a bound does
not do is read what is inside the region; that residue is in Gaps.

**finding-4**: the shell exempt region has no closer guard. The markdown
regions are checked for a closing `## ` heading; the `gr_writing_table` region
is not checked at all, so indenting its closing brace moves the close silently.
disposition: fixed in `520e1e0`, guard 4. The word-table region is bounded the
same way — longer than 45 lines, or reaching end of file, is reported — and it
is reported as well when it swallows another function declaration, which is
exactly what indenting its closing brace does. The region is 30 lines at this
head. Proof, by the dispatcher, applied and reverted: with the closing brace
indented, `not ok 58`, `tests/skills.bats:46: word table swallows
gr_writing_forms() {`.

**finding-5**: the scope guard's exclusion list is inline and unpinned. The
test contains its own literal copy of the four exclusions D1 names in prose,
and
nothing compares the two.
disposition: open by decision. Stated in full in Gaps, with the one-line edit
in each of two places that removes a whole ledger from the scan with both tests
green.

**finding-6**: `AGENTS.md` is never compared against the block shipped to
adopters. The agreement test parses the replace list out of
`templates/AGENTS-block.md` alone, so the rule that binds this repository can
diverge from the rule that is checked.
disposition: fixed in `520e1e0`, guard 5. The agreement test parses the replace
list out of `AGENTS.md` as well as out of `templates/AGENTS-block.md` and
requires the two to name the same words, so the rule that binds this repository
can no longer diverge from the rule that is checked. Proof, by the dispatcher,
applied and reverted: a word added to `AGENTS.md` alone gives `not ok 54`,
`AGENTS.md and the shipped block name different words`. That the two lists name
the same nine words is now a checked property rather than a fact about today;
measured again here, they do.

**finding-7**: part of the same defect as finding-2 — the sweep applied a
word-form rule to idioms the table exempts, and the exemption mechanism could
not express the exemption that would have prevented it. The reviewer's text for
7, 8 and 19 was not available to this record's author separately from the fix
commit that names all three.
disposition: fixed in `4c3e04d`, with finding-2. The exemption list is data,
compiled case-insensitively, so an idiom is exempted rather than reworded.

**finding-8**: part of the same defect as finding-2, on the shipped file rather
than the scan: a correct English construction in `scripts/check-review.sh` had
been edited to suit the scan.
disposition: fixed in `4c3e04d`, with finding-2. `SAID SO` is restored at
`scripts/check-review.sh:311` and matches `main` byte for byte.

**finding-9**: the gate row states `1..689`, 689 ok "three times", and
describes a tree that was never merged. The record was written on one parent
while three new tests were added on the sibling parent; the merge produced 692.
The record also states 320 tracked files.
disposition: fixed here. The gate row states `1..692`, 692 ok, 0 not ok on the
tree being merged, and names who observed it: the second round's reviewer in
its own worktree, confirmed by the dispatcher on the change branch. The tracked
file count is 321 on the branch, from `git ls-files | wc -l`. **This
disposition's own correction of the file count was defective and is corrected
again**: it replaced 320 with 321 and stated 321 at `main` in the same breath,
which no command produces either. `main` has 318, and the change adds three
files. Round 3 raised that as its finding-1; the measured figures, both
commands and the account of how an unmeasured figure entered the repair of an
unmeasured figure are in What the review checked and found correct.

**finding-10**: the fix rounds have no task records. The implementation plan's
records stop at T6 and three later commits have none.
disposition: fixed here. `docs/plans/2026-09-16-scan-scope-implementation.md`
now records F1 (`4254ff1`), F2 (`4c3e04d`) and F3 (`892d7a7`) in the same shape
as T1 to T6, with the dispatcher's five post-merge attacks and the one attack
that reached nothing and therefore proved nothing. F4 (`520e1e0`) is recorded
there in the same shape, with the six attacks that prove its five guards.

**finding-11**: the `verdict:` field still reads `do not merge.` for one round.
disposition: fixed here. It states both rounds and names every round-2 finding
as fixed or open.

**finding-12**: D5 and the Cost section require a 58-row rename map and the map
has 57 rows. 58 double-counts `gr_check_config says so when it cannot read the
config at all, before any scan`, which was swept and then restored.
disposition: fixed here, in both places. 56 vocabulary renames plus the one
scope-driven rename is 57, which is what the table has; counted directly, 57
rows, 30 of them cited.

**finding-13**: D2 still prescribes the mechanism round 1 rejected — the
markdown opener in exactly two files and the table opener in one. The
implementation counts occurrences, because counting files does not report a
second exempt region in the same file.
disposition: fixed here. D2 describes the occurrence count that shipped and the
closer check beside it, and states why the file count was inadequate.

**finding-14**: D4's table does not match the shipped table. D4 gives `holds ->
holds held holding`, excluding the bare `hold` the exemption list makes
scannable.
disposition: fixed here. The row is corrected to `holds -> hold holds held
holding`, and the reason the bare `say` is deliberately unscanned is stated
with it: `grep -Eiw say` matches inside `say-so`, and the parenthetical `say`
has no entry on the shipped replace list, so scanning it narrows the tree to
fit the scan.

**finding-15**: the decision record names two git phrases as what the scan
exempts, and the scan has seven exemptions.
disposition: fixed here. All seven are documented — four addressed git-output
removals scoped to their file and three global idioms, `says so`, `said so` and
`when all three hold` — with how they are compiled into one case-insensitive
`sed` script, and with the note that `when all three hold` is phrase-specific,
so a future correct `when both hold` would be reported.

**finding-16**: D1 states the mutation scripts are left alone and counts
twenty-seven word-bounded occurrences. 27 at `3714f08`, 26 at this head:
`docs/verification/2026-08-27-config-schema.mutations/M81.sh` had `carried`
rewritten to `continued` when its anchor was re-cut.
disposition: fixed here. The count is corrected in both revisions and the
exclusion is qualified: one mutation script was edited under it, deliberately,
and its anchor still applies. The remaining 26 occurrences are all on comment
lines, none inside an anchor string.

**finding-17**: D1 names two edits to merged problem and risk records as
restatements rather than substitutions. There are at least eight more.
disposition: fixed here. All ten are quoted in D1, each read at `main` and at
this head, including `docs/problems/2026-09-02-hardware-key-retrofit.md:122`,
where three lines of a recorded diagnosis were rewritten.

**finding-18**: D1's consequence counts only the 57 test-name renames, and nine
changed script messages are quoted stale in merged records. This record's claim
that 18 old message fragments are absent is true only for in-scope files.
disposition: fixed here, with a figure this record's author measured rather
than copied. Every message or code line removed from `scripts/`, absent from
`scripts/` at this head, matched by exact substring against every merged record
other than this change's own: **seven record lines in two files**, four in
`docs/plans/2026-09-04-units-implementation.md` and three in
`docs/plans/2026-09-10-field-report-fixes.md`, all listed in D1. The figure
reported to this author was nine, five of them in the second file; the two that
do not reproduce are a quotation of a script comment and a quotation of wording
that was already stale before `main`, and the second is recorded in D1 so it is
not counted twice. The qualifier is added to the absence claim below. **The
decision, stated and not built: the rename map does not cover messages**,
because a stale test-name citation is a dangling reference while a quoted
message is a true observation of the tree its own change merged. The reasoning
is in D1.

**finding-19**: part of the same defect as finding-2 — the form canary was
built beside the scan rather than on it, so it proved only itself. Dropping
`-i` from the scan, or exempting a whole word, left every test green.
disposition: fixed in `4c3e04d`. The scan is factored into `gr_writing_scan`
and both the canary and the scan test call it, so the grep flags, the exempt
regions and the exemption list are on one code path. The canary also names the
forms it could not read, with `comm` against the form list rather than a count,
and branches separately on a `grep` that exits without running. The dispatcher
reddened the canary with both attacks after the merge; the attacks are recorded
in the implementation plan.

## Review — round 3, targeted

A third round read the tree the first two rounds' fixes produced. It was not a
fresh sweep of the change: it took the dispositions above as claims and tried
to break each fix again. Six findings, two of them minor. Three are fixed in
`520e1e0`, two in these records, and one is recorded as a known limit.

The numbering restarts again: `finding-3` below is round 3's, not round 1's or
round 2's.

**finding-1**: the tracked-file count at `main` was never measured. This record
stated that `git ls-files | wc -l` "reports 321 on the branch and 321 at
`main`". 321 is right for the branch. `main` has 318.
disposition: fixed here, and the shape of the error is recorded with the
figure, because the shape is the point. The sentence that stated it was itself
the correction of round 2's finding-9, where the figure had been 320 — and the
correction introduced a second unmeasured figure one clause later, inside the
sentence that was repairing the first. The bullet in What the review checked
and found correct now states both counts, the command that produces each, and
the three files the change adds, which is the whole difference between them.

**finding-2**: the exemption list is a fifth guard of the same shape as the
four this record listed as open, and it was not among them. `gr_writing_exemptions`
removes a phrase from every line before the scan matches it, so one added entry
stops the scan reporting that phrase anywhere in scope, and the form canary
cannot report the addition: it feeds the scan one form per line and every
exemption is a phrase. One added entry, with a line matching it planted in the
tree, left all 59 tests green.
disposition: fixed in `520e1e0`, guard 1. The list must contain exactly seven
entries, so adding an eighth is an edit in two places and appears in the diff
as a changed expectation. Proof, by the dispatcher, applied and reverted: the
added entry and its matching plant produced no `not ok` at all before the
guard, and `not ok 58` after it. **The enumeration of open guards in this
record had been incomplete, and the guard it omitted was the newest one this
change added** — the exemption list shipped in `4c3e04d`, two commits before
the record that listed its four siblings and not it. A record that enumerates
its own weak points is worth what that enumeration is complete.

**finding-3**: `gr_writing_scan`'s comment promised an exit-status contract the
code did not provide. The comment states that the exit status is grep's, so a
caller can tell no match from a scan that did not run. An entry with an empty
phrase compiles to a substitution with an empty pattern; BSD sed exits 1 on it,
grep then reads an empty stream and exits 1 as well, and a scan that never ran
is indistinguishable from a clean tree.
disposition: fixed in `520e1e0`, guard 2. `gr_writing_scan` compiles the
exemption script against no input before it reads any file and returns 2 if the
compilation fails, which is the contract its comment already stated; the scan
test already branched on a status above 1. Proof, by the dispatcher, applied
and reverted: `not ok 58`.

**finding-4**: the pattern that closes a writing-section exemption was written
twice, once in the scan and once in the guard that reports an unclosed region.
A one-character edit to the scan's copy widens the exemption to end of file
while the guard matches its own copy and stays green.
disposition: fixed in `520e1e0`, guard 3. Both read
`gr_writing_section_closer`, so the guard reports the scan's closer rather than
its own. Proof, by the dispatcher, applied and reverted: with the closer
changed, `not ok 58`, `a writing-section exemption reaches end of file`.

**finding-5** (minor): this record and the decision record disagree about one
changed line under `scripts/`. This record stated that all 48 non-comment
changed lines under `scripts/` are printed messages or `awk printf` format
strings. One pair is an `awk` code line whose trailing comment changed, which
D1 describes correctly.
disposition: fixed here, in this record, which is the one that was wrong. The
bullet states 24 pairs, 23 of them message or format text and the twenty-fourth
the `awk` line `print (a < 0 ? -1 : a)` with a changed trailing comment. **The
no-behavior-change claim is kept**, because it is true of that pair too: the
executable text is byte-identical on both sides, and only the comment after it
differs.

**finding-6** (minor): the scan's file list is expanded unquoted. The scan test
calls `gr_writing_scan $(git ls-files -- $(gr_writing_paths))`, and neither
expansion is quoted, so a tracked path containing whitespace would reach the
scan as two arguments and neither half would name a file.
disposition: recorded as a known limit, in Gaps, not fixed. Measured at this
head with `git ls-files | grep -c '[[:space:]]'`: 0. No such path exists, so
the scan reads every file it should today.

## What the review checked and found correct

A review that reports only its findings understates what it establishes. The
reviewers verified each of these independently:

- **No behavior change.** 48 non-comment lines under `scripts/` changed, 24
  removed and 24 added — counted at this head from `git diff main HEAD --
  scripts/` with comment lines dropped — which is 24 pairs. 23 of the pairs
  differ only in printed message or `awk printf` format text. The twenty-fourth
  is the `awk` code line `print (a < 0 ? -1 : a)`, whose trailing comment
  changed; its executable text is byte-identical on both sides, so the
  no-behavior-change claim stands for it too. This record previously described
  all 48 lines as messages or formats, which D1 does not; round 3 raised the
  disagreement as its finding-5 and the two records agree now. Every changed
  message's consumers were updated in the same task, and 18 old message
  fragments were searched for and are absent — **in files the scan reads**.
  That is the whole claim, and the second round showed the qualifier matters:
  seven lines in two merged plans under `docs/plans/`, which the scan does not
  read, still quote a changed script line verbatim. They are listed in D1 with
  the decision not to map them. No consumer of any changed message is stale; no
  merged record that quotes one has been updated, by D1.
- **No stale citation in any scanned file.** Every quoted `@test` name in a file
  the scan reads resolves to a test that exists.
- **D1's totality is true today.** Every one of the **321** tracked files on
  the branch is either in the in-scope pathspec or in one of the four named
  exclusions. Measured for this correction: `git ls-files | wc -l` reports
  **321** on the branch, `git ls-tree -r --name-only main | wc -l` reports
  **318** at `main`, and `git diff --name-status main HEAD` reports 3
  additions, 48 modifications and no deletion. The three additions are this
  record and the two planning documents, and they are the whole difference
  between 318 and 321.

  **This sentence has stated an unmeasured figure twice.** It first stated 320
  tracked files, which no command produces. Round 2 raised that as its
  finding-9, and the correction replaced 320 with 321 — and then stated 321 at
  `main` in the next clause, a second figure nobody had measured, inside the
  very sentence that was repairing the first. `main` has 318 and has had 318
  for the whole of this change. Round 3 raised it as its finding-1. It is worth
  recording rather than quietly fixing, because it is the failure this entire
  change is about: a figure that reads plausibly beside a measured one gets
  written down without being run, and the second time it happened it happened
  in the repair.

  Confirmed again: the only tracked paths outside the pathspec and outside
  `docs/plans/` and `docs/verification/` are `LICENSE` and `.gitignore`. Since
  the second round this is no longer only an observation — `clanker: every
  tracked file is in the scan's scope or named out of it` asserts it, with the
  same complement.
- **The scan reads every surface.** Proved by planting vocabulary in eight
  different files and watching the scan name each one.
- **T4's and T5's corrections of their predecessors were both confirmed.** T4's
  correction of this plan's claim about M81's killing test, and T5's correction
  of T4's mutation census, each reproduced.

**What round 3 re-checked and found held.** The third round's six findings are
above. What it established is as much a part of this record, because a targeted
round that reports only what it broke leaves the impression that nothing else
was tried.

- **All five fixes that were claimed in a commit rather than in a record close
  the finding they claim.** Round 2's findings 1, 2, 7, 8 and 19 were fixed in
  `892d7a7` and `4c3e04d`, and each was attacked again on this tree.
- **All six restored English uses match `main` byte for byte, at the same line
  numbers.** Re-checked for this correction by reading each line at both
  revisions: `skills/worktree-discipline/SKILL.md:264`, `scripts/lib.sh:20`,
  `skills/ratchet/SKILL.md:607`, `templates/AGENTS-block.md:22`,
  `skills/check-traceability/SKILL.md:157` and `scripts/check-review.sh:311`.
  Six of six identical.
- **Every figure in the table below was re-measured for this correction, on
  this tree, and held.**

| Figure | How it was measured | Result |
| --- | --- | --- |
| The rename map | the map's own rows counted, and the `cited` column counted | 57 rows, 30 marked cited |
| Where those citations are | each old name searched with `grep -rFn` under `docs/plans/` and `docs/verification/`, excluding this change's own three files | 30 of the 57 old names, in 14 merged records, on 48 distinct lines — 48 and not 49 because one line cites two of them |
| `@test` names | `grep -h '^@test ' tests/*.bats \| wc -l`, and the same against `main` | 692 and 688 |
| Renames, additions, deletions | the map against those two counts | 57 renamed, 4 new, none deleted |
| Form spellings against the canary's floor | `gr_writing_forms` split to one form per line and counted, doubled for the upper-case half | 29 distinct forms, 58 spellings, floor 58 |
| Exemption entries | `gr_writing_exemptions \| grep -c '\|'` | 7 |
| Vocabulary in the mutation scripts | `git grep -Eiow "$banned" <rev> -- 'docs/verification/*.mutations/M*.sh' \| wc -l` at both revisions, and the two lists differenced | 27 at `3714f08`, 26 at this head, and the one difference is `M81.sh:5`, as D1 states |
| Occurrences in scope before the change | the Measurements command in the decision record, at `3714f08`, over the D1 pathspec | 674, and every per-surface row of that table reproduced |
| Stale message quotes | the seven lines read at the line numbers D1 states | seven lines in two merged plans, each still quoting wording `scripts/` no longer produces |
| Bare-`say` sites in scope | the scan's own region filter over the pathspec, then the bare form matched | 11 sites in 11 files, the eleven named in Gaps |
| The two statements of the rule | the agreement test's own parse, run against `AGENTS.md` and against the shipped block | nine words each, the same nine |
| Exempt region lengths | the bound guard's own `awk`, run over the openers | 21 lines in `AGENTS.md`, 21 in the shipped block, 30 in `tests/skills.bats` |
| `tests/skills.bats` at this head | the file run alone under the vendored bats | `1..59`, 59 ok, 0 not ok |

## Gaps

What this change does NOT establish.

**A green scan means the scan as configured found nothing. It does not mean the
tree obeys the writing rules.** Everything below follows from that sentence,
and the second review round is what made it necessary to write down.

- **One guard stops guarding when the guard itself is edited. Open by
  decision, not by oversight.** Round 2's findings 3, 4, 5 and 6 shared one
  shape: each named a guard whose own configuration is in the same file the
  guard protects, so an edit to that configuration disables the guard with the
  suite green. Round 3 found a fifth of the same shape — the exemption list,
  which this record had failed to list among the four at all. Four of the five
  are closed in `520e1e0`: the exemption list has a fixed size, both exempt
  regions are bounded, the section closer is read from one function, and the
  two statements of the rule are compared. Each of those four dispositions, in
  the round 2 and round 3 sections, names its guard and the proof the
  dispatcher observed. **Finding 5 is the one that remains**, and the
  reviewer's run is the only observation of the suite staying green under it.

  - **finding-5 — the scope guard's exclusion list is inline and unpinned.**
    `clanker: every tracked file is in the scan's scope or named out of it`
    subtracts the pathspec from `git ls-files` and filters the remainder
    through a literal `grep -Ev '^(docs/plans/|docs/verification/|LICENSE$|\.gitignore$)'`.
    D1's prose names the same four exclusions and nothing compares the two. The
    defeating edit is one line in each place: drop `docs/risk` from
    `gr_writing_paths` and add `^docs/risk/` to that regex, and the scan stops
    reading an entire ledger. Neither test can report it — read from the test
    source here, and proved by the reviewer, where it was run.

  **Why it is left open.** The fix is a pin, and whatever pins a guard can
  itself be edited: a test that compares the exclusion list against D1's prose
  is a test whose own copy of that prose can be edited in the same commit. Each
  level buys one more edit of distance, not closure, and the regress has no
  natural stopping point inside a suite a contributor can edit. The line is
  drawn where it is because the guards that exist report the accidents — a
  renamed heading, a moved file, a pathspec that matches nothing — and what
  remains needs a deliberate, conspicuous edit to the scan's own configuration
  in the same commit as the prose it hides. A reviewer reading a diff sees that
  edit. This change chooses a reviewed diff over a deeper pin, and states the
  choice rather than implying the scan is stronger than it is. One qualifier,
  since three rounds have now moved four of these five from open to closed: the
  argument above is a reason to stop here, not evidence that a pin for this one
  is worthless. A later change that writes it is welcome to disagree.

- **An exempt region exempts whatever is written inside it.** `520e1e0` bounds
  the regions — 35 lines for a writing section, 45 for the word table, and
  neither may reach end of file — so a region can no longer be re-closed around
  a document, which is what round 2's findings 3 and 4 defeated. Nothing reads
  what is inside the bound. Reproduced at this head, on copies rather than by
  editing the tree: a sentence containing the replaced vocabulary, inserted
  before the `## Rules` heading that closes `AGENTS.md`'s writing section, is
  not reported and the scan exits 1; the same sentence appended to the end of
  the file is reported by name and line. The insertion takes that section to 22
  lines, well inside the 35-line bound. The three regions are 21, 21 and 30
  lines today, so what a bound leaves room for is a few lines of rule text.

- **The scan's file list is expanded unquoted.** Round 3's finding-6. The scan
  test calls `gr_writing_scan $(git ls-files -- $(gr_writing_paths))` and
  neither expansion is quoted, so a tracked path containing whitespace would
  reach the scan as two arguments and the scan would read neither half as the
  file it is. Measured at this head with `git ls-files | grep -c
  '[[:space:]]'`: **0**. No such path exists, so the scan reads every file it
  should. Recorded as a known limit rather than fixed: that word splitting is
  what feeds the scan a file list at all in POSIX shell, and the alternatives —
  a `while read` loop, or `xargs` — change how the scan's exit status reaches
  its caller, which the scan's stated contract and its callers both read. A
  tracked path with whitespace in it would need that change first.

- **The residue of finding 2: the bare `say` is unscanned, by decision, and the
  sweep of it went further than any rule required.** Measured on this tree with
  `git grep -Eiwn 'say' -- $(gr_writing_paths)`: 19 lines, of which 8 are inside
  the three exempt regions, leaving **11 bare-`say` sites in scope, in eleven
  files** — `AGENTS.md:69`, `scripts/check-review.sh:265`, `scripts/lib.sh:20`,
  `skills/check-traceability/SKILL.md:157`,
  `skills/grill-requirements/SKILL.md:150`, `skills/plan-change/SKILL.md:55`,
  `skills/ratchet/SKILL.md:607`, `skills/worktree-discipline/SKILL.md:264`,
  `templates/AGENTS-block.md:22`, `templates/verification.md:68` and
  `tests/check-review.bats:225`. Each is the imperative `say so`, the noun
  `say-so`, or the parenthetical `say` meaning "for example". No gate reads
  them, and D4 states why. Separately, **23 lines in scope had a bare `say`
  replaced with `state`-family wording** by the sweep — counted as the removed
  lines matching `grep -Eiw say` in `git diff main HEAD` over the pathspec, less
  the two inside the word table's own comment. Every one of the 23 is correct
  English and not one was forced by the shipped replace list, which names
  `says`, not `say`. They are not defects and they were not reverted; they are
  recorded because a sweep that edits what no rule requires is how a scan
  starts rewriting a tree to suit itself.

- **No gate ships to adopters.** D6 decides this. `/ratchet` installs the
  writing rules into every adopter's `AGENTS.md` and installs nothing that
  enforces them. The gap between the shipped rule and the shipped gate is
  unchanged by this change.
- **The scan enforces one example of the metaphor rule, not the rule.** D3
  states this. Detecting metaphor needs the animacy of the subject, which a line
  scan cannot read, so a green scan is not evidence that the prose follows the
  first bullet of the writing rules.
- **This record is not itself scanned.** `docs/plans/` and `docs/verification/`
  are out of scope permanently, so no gate reads this file for the vocabulary it
  is about. It was written to the rule regardless.
- **At least 38 of 184 mutation scripts no longer reproduce their recorded
  evidence, and this predates the change.** 13 write `scripts/lib.sh` (T3), 15
  write `check-trace.sh` or `check-ids.sh` (T5), 4 are in T6's replay set, and 6
  write `scripts/finalize-ids.sh`, a file removed at `c672c9f`, so those six
  cannot be replayed against this tree at all. The dispatcher verified the last
  group and confirmed four of the thirteen by replaying them against a scratch
  checkout of the base revision. No replay in this change differs before and
  after any sweep, so this change neither caused the staleness nor widened it.
  Repairing it means re-cutting the anchors and re-proving each mutation: its
  own change, with its own record.
- **Three holes in mutation coverage are recorded and not acted on.** No `M*.sh`
  writes `scripts/check-units.sh` (T6) or `scripts/finish-merge.sh` (T4), and
  the 31 tests in `tests/check-signing.bats` kill nothing in
  `scripts/check-signing.sh`, because the one mutation aimed at that script is
  killed by `tests/lib.bats` instead (T4).
- **Four of the six per-task red site counts are attestations only.** The
  reviewer could not reproduce them exactly from the diff and reported that
  rather than calling them false. The observation each records — that the scan
  reddened naming the newly reached surface, and passed after the sweep — is
  reproducible; the exact count is not.
- **Round 1's finding-10 is recorded, not settled.** The inconsistency in D1's
  exclusion reason is stated in the decision record with its measured cost,
  which round 2 raised from two edits to at least ten. Deciding it is a later
  change.

## Rename map (D5)

**The arithmetic, stated once and precisely, because it has been stated three
different ways during the change.** 57 `@test` names at `main` contained a word
on the replaced list. The sweep renamed 56 of them: the fifty-seventh,
`gr_check_config says so when it cannot read the config at all, before any
scan`, was swept and then restored when the review found that `says so` is the
idiom the rule exempts, not the inanimate-subject use it replaces.

One further name changed for a different reason: the scan test `clanker: no
skill body contains the replaced vocabulary` became `clanker: no file in scope
contains the replaced vocabulary` because its scope widened, and its old name
contains no word on the list.

That is **57 renames — 56 vocabulary-driven and one scope-driven**. Four tests
are new: the D4 agreement test, and the three the review's findings 1 and 2
required. None was deleted. `main` has 688 tests and the branch has 692.

**30 of the 57 old names are cited in 14 merged records** under `docs/plans/`
and `docs/verification/`, on 48 distinct lines. Those records are not edited
(D1), so this table is where a stale citation is resolved.

| File | Old name | New name | Cited in a merged record |
|---|---|---|---|
| `check-ids.bats` | check-ids: the draft failure says what to run instead | check-ids: the draft failure states what to run instead | yes |
| `check-ids.bats` | check-ids: --allow-drafts is gone, and is refused rather than ignored | check-ids: --allow-drafts is gone, and is rejected rather than ignored | yes |
| `check-ids.bats` | check-ids: --base is gone, and is refused rather than ignored | check-ids: --base is gone, and is rejected rather than ignored | yes |
| `check-ids.bats` | check-ids: the MALFORMED-ID failure says what to run instead | check-ids: the MALFORMED-ID failure states what to run instead | yes |
| `check-review.bats` | check-review: an invalid config is refused before any record is read | check-review: an invalid config is rejected before any record is read | - |
| `check-review.bats` | check-review: an unknown argument is refused, not ignored | check-review: an unknown argument is rejected, not ignored | - |
| `check-review.bats` | check-review: --branch with no value is refused | check-review: --branch with no value is rejected | - |
| `check-review.bats` | check-review: the record claims the first branch it carries, not the last | check-review: the record claims the first branch it contains, not the last | - |
| `check-review.bats` | check-review: --branch says in the summary that provenance was not checked | check-review: --branch states in the summary that provenance was not checked | - |
| `check-review.bats` | check-review: --branch naming the base branch is refused | check-review: --branch naming the base branch is rejected | - |
| `check-review.bats` | check-review: a finding label carrying a non-UTF-8 byte is reported | check-review: a finding label containing a non-UTF-8 byte is reported | - |
| `check-review.bats` | check-review: an empty doc_verification value is refused, not defaulted | check-review: an empty doc_verification value is rejected, not defaulted | - |
| `check-signing.bats` | check-signing: a failed verdict carries the verifier's own reason | check-signing: a failed verdict contains the verifier's own reason | yes |
| `check-signing.bats` | check-signing: an untrusted signature carries the verifier's reason too | check-signing: an untrusted signature contains the verifier's reason too | yes |
| `check-signing.bats` | check-signing: --setup carries a real format into the proof, not an empty one | check-signing: --setup passes a real format into the proof, not an empty one | yes |
| `check-trace.bats` | check-trace: a ledger directory holding no *.md is an error, not an empty document | check-trace: a ledger directory containing no *.md is an error, not an empty document | - |
| `check-trace.bats` | check-trace: a supersedes: value carrying no ID is reported, not dropped | check-trace: a supersedes: value containing no ID is reported, not dropped | yes |
| `check-trace.bats` | check-trace: a superseded-by: value carrying no ID is reported too | check-trace: a superseded-by: value containing no ID is reported too | yes |
| `check-trace.bats` | check-trace: the ACCEPTED-PR roll-call line carries the date | check-trace: the ACCEPTED-PR roll-call line contains the date | yes |
| `check-trace.bats` | check-trace: an item with a refused date is counted as having no usable date | check-trace: an item with a rejected date is counted as having no usable date | - |
| `check-trace.bats` | check-trace: a bare draft name found in no ledger directory says where it looked | check-trace: a bare draft name found in no ledger directory states where it looked | yes |
| `finish-merge.bats` | finish-merge: a failing git worktree list refuses instead of deleting the branch | finish-merge: a failing git worktree list rejects instead of deleting the branch | yes |
| `finish-merge.bats` | finish-merge: a failing awk refuses instead of deleting the branch | finish-merge: a failing awk rejects instead of deleting the branch | yes |
| `finish-merge.bats` | finish-merge: a change branch holding work the squash missed fails | finish-merge: a change branch containing work the squash missed fails | - |
| `finish-merge.bats` | finish-merge: refuses to run from a linked worktree | finish-merge: rejects a run from a linked worktree | - |
| `finish-merge.bats` | finish-merge: refuses when the primary checkout is not on a base branch | finish-merge: rejects a primary checkout that is not on a base branch | - |
| `finish-merge.bats` | finish-merge: refuses a branch that does not exist | finish-merge: rejects a branch that does not exist | - |
| `finish-merge.bats` | finish-merge: refuses the base branch as the change branch | finish-merge: rejects the base branch as the change branch | - |
| `finish-merge.bats` | finish-merge: derives the worktree path under an awk that refuses a newline in -v | finish-merge: derives the worktree path under an awk that rejects a newline in -v | - |
| `finish-merge.bats` | finish-merge: a nested worktree is refused even when it holds nothing uncommitted | finish-merge: a nested worktree is rejected even when it contains nothing uncommitted | yes |
| `finish-merge.bats` | finish-merge: --check refuses the base branch | finish-merge: --check rejects the base branch | yes |
| `finish-merge.bats` | finish-merge: --check with no registered worktree says nothing was inspected | finish-merge: --check with no registered worktree states nothing was inspected | yes |
| `finish-merge.bats` | finish-merge: --check refuses a failing git worktree list, it does not report a clean tree | finish-merge: --check rejects a failing git worktree list, it does not report a clean tree | yes |
| `finish-merge.bats` | finish-merge: --check refuses a failing awk, it does not report a clean tree | finish-merge: --check rejects a failing awk, it does not report a clean tree | yes |
| `lib.bats` | gr_doc_files dies when a configured directory holds no *.md | gr_doc_files dies when a configured directory contains no *.md | yes |
| `lib.bats` | gr_limit reads a whole number, refuses anything else, and is empty when unset | gr_limit reads a whole number, rejects anything else, and is empty when unset | - |
| `lib.bats` | gr_check_config refuses a key set to nothing, whichever key it is | gr_check_config rejects a key set to nothing, whichever key it is | - |
| `lib.bats` | gr_check_config refuses a config whose lines end with bare carriage returns | gr_check_config rejects a config whose lines end with bare carriage returns | - |
| `lib.bats` | gr_check_config refuses a list key written as a scalar | gr_check_config rejects a list key written as a scalar | - |
| `lib.bats` | gr_check_config refuses a scalar key written as a list | gr_check_config rejects a scalar key written as a list | - |
| `lib.bats` | gr_verification_dir refuses a doc_verification set to nothing | gr_verification_dir rejects a doc_verification set to nothing | yes |
| `lib.bats` | gr_check_config refuses a list key that names nothing at all | gr_check_config rejects a list key that names nothing at all | - |
| `lib.bats` | gr_check_config refuses a list item with nothing after its dash | gr_check_config rejects a list item with nothing after its dash | - |
| `lib.bats` | gr_check_config refuses an item that is itself a comment | gr_check_config rejects an item that is itself a comment | - |
| `lib.bats` | gr_unit_engage refuses the default config path in a manifest repo, naming the remedy | gr_unit_engage rejects the default config path in a manifest repo, naming the remedy | yes |
| `lib.bats` | gr_unit_engage refuses a GR_CONFIG that is not a declared unit's | gr_unit_engage rejects a GR_CONFIG that is not a declared unit's | yes |
| `new-id.bats` | new-id: every minted token carries a digit | new-id: every minted token contains a digit | yes |
| `new-id.bats` | new-id: refuses a prefix that is not declared in id_prefixes | new-id: rejects a prefix that is not declared in id_prefixes | yes |
| `new-id.bats` | new-id: refuses a count that is not a positive integer | new-id: rejects a count that is not a positive integer | yes |
| `new-id.bats` | new-id: refuses an unknown argument rather than ignoring it | new-id: rejects an unknown argument rather than ignoring it | yes |
| `new-id.bats` | new-id: refuses to invent an ID when there is no entropy source | new-id: does not invent an ID when there is no entropy source | yes |
| `new-id.bats` | new-id: a FIFO is refused rather than read | new-id: a FIFO is rejected rather than read | yes |
| `new-id.bats` | new-id: new-id-outside-unit-requires-flag — at the root it refuses and lists the units | new-id: new-id-outside-unit-requires-flag — at the root it rejects the request and lists the units | yes |
| `portability.bats` | check-review: runs under an awk that refuses a newline in -v | check-review: runs under an awk that rejects a newline in -v | - |
| `portability.bats` | every check script runs clean under an awk that refuses a newline in -v | every check script runs clean under an awk that rejects a newline in -v | - |
| `portability.bats` | bsd date stub: refuses -d and a doubled sign in -v | bsd date stub: rejects -d and a doubled sign in -v | - |
| `skills.bats` | clanker: no skill body contains the replaced vocabulary | clanker: no file in scope contains the replaced vocabulary | yes |

**What was verified about this table.** Every new name occurs in `tests/*.bats`
and no old name occurs anywhere in `tests/` — checked row by row with
`grep -Fx` against the full `@test` declaration. Every old name was also
searched across the whole tracked tree outside `docs/plans/` and
`docs/verification/`: **no scanned file cites a test that no longer exists.**
The reviewer reached the same conclusion independently.
