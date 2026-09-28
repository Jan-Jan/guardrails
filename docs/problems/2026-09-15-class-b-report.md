# Problem reports — four items from a class B adopter's field report, and three found fixing them

All four arrived on 2026-09-10 in a field report from a downstream SvelteKit
project, IEC 62304 class B, measured between 2026-09-04 and 2026-09-09 against
its vendored copy of `5bc6495` — eleven commits behind `main`, so the report
predates the units machinery and `DANGLING-FILE`. Recorded here before anything
was touched. The report contained eight points; these are the four that name a
defect in this toolkit. Of the rest: scanning inside fenced blocks is settled
doctrine (`check-trace.sh` at the front-matter note, `docs/problems/README.md`),
and the `MALFORMED-ID` its probe produced is that gate working as
`check-ids.sh` describes it; item-length guidance is guidance, not a defect;
an `--explain` mode is a diagnostic whose motivation is mostly a message
problem; and citation checking shipped as `DANGLING-FILE` in 51f01b7. None of
the four below is a new discovery — three are conceded in the comments of the
script or library they affect, which is the point the report's measurements
make about a stated weakness.

**Three of the seven items here did not come from the report.** They were found
while fixing the other four, and are recorded here because that is where they
were found:

* `PR-crcee5` — 38 of 184 mutation scripts can no longer apply. Found when this
  change's own edits staled five anchors and an audit of all five mutation
  directories showed how many were already dead. Resolved by `47a8b1d`, which
  measured the true population at 46 and repaired or retired every one; the
  item states how the two figures differ.
* `PR-dr7k7k` — no skill told an author to check for that, which is why the five
  happened. Found by the independent review, after the control had been written
  but before it was applied to work already merged.
* `PR-z6uaa8` — the skills an agent executes are installed copies that have
  drifted from `skills/`. Found by the user asking where a `check-trace.sh` fix
  gets reported.

The header's assessment below covers the four reported points only; these three
are assessed in their own items.

**PR-k77dzn**: Guard 4 — no registered worktree inside the one about to be
removed — is fully knowable before the squash commit exists, but
`finish-merge.sh` offers no way to prove it, so a rejection is discovered after
the signing touch that `merge-change` step 7 hands to the user.
affects: scripts/finish-merge.sh, whose four guards run only as the chained
tail of the signed commit, and whose own header already concedes the cost — a
re-run "wastes a key touch"; skills/merge-change step 6d, which gives the
author `git worktree list` but leaves the prefix test that turns that list into
a verdict to the reader.
opened: 2026-09-10
status: resolved
Guards 1 and 2 both read the squash commit and so cannot be preflighted at all;
the preflight is guard 4 alone, and the report's own "prove all four guards" is
not available. Measured downstream: five nested review worktrees on one change
and three on another in one week, because each round of the step-6a review
protocol creates the condition guard 4 rejects.
Root cause: guard 4's predicate existed only inside the removal path, which
runs as the chained tail of the signed commit, so a condition knowable minutes
earlier was first asked after the key touch. Fixed by `--check`, which proves
guard 4 alone from anywhere in the repository — including the change worktree,
which the rest of the script rejects — and removes nothing; the scan is factored
into `gr_nested_worktrees` so the one guard whose wrong answer loses work has a
single definition. `merge-change` step 6d is now that command. Reproduced by
`finish-merge: --check reports a nested worktree and removes nothing`,
`--check exits 0 when nothing is nested`, `--check runs from the change worktree,
before any squash`, `--check rejects the base branch`, `--check never removes,
even with everything green` and `--check reports two nested worktrees in the
plural, naming both` (tests/finish-merge.bats), each watched failing first.

**PR-4fwfjp**: `check-trace.sh` admits `open` and `resolved` and nothing else,
so a problem that was investigated and deliberately accepted has no status to
record it — it keeps aging toward `STALE-PROBLEM` and keeps counting against
`problem_open_max`, and the decision lives outside the ledger entirely.
affects: scripts/check-trace.sh, whose `MALFORMED-STATUS` rule admits two
values, and whose age and open-count limits therefore bound decisions as though
they were neglect; skills/resolve-problem, which offers "resolve it or raise the
limit deliberately" as the only answers; docs/problems/2026-09-03-signing-diagnosis.md,
where PR-r8q9m7 stands open above its own sentence calling itself an accepted
gap — this ledger already contains the defect the report describes, three times
over in the same idiom, across three separate items.
opened: 2026-09-10
status: resolved
IEC 62304 6.2 treats a documented decision not to change the software as a
resolution outcome; the ledger can express only "not fixed". Measured
downstream: four items ruled on by the project owner on 2026-09-07, all still
open, going stale on 2026-11-18, 11-18, 11-19 and 11-27. An accepted status must
stay in the roll-call — one that is exempt from the limits and also silent is
how a decision decays back into a thing nobody remembers deciding.
Root cause: `gr_prflush()` admitted two status values and treated everything
else as `MALFORMED-STATUS`, so a decision had no shape to take. Fixed by a third
value, `accepted`, requiring a column-one `disposition:` — that requirement is
what makes the status safe rather than a one-word escape from both limits — and
exempt from `STALE-PROBLEM` and `problem_open_max` while still reported as
`ACCEPTED-PR` and counted in the `problems:` summary. An orphaned
`disposition:` is now a reported orphan, because the keyword became
block-parsed. Reproduced by `check-trace: an accepted problem with a
disposition: is not stale and not counted open`, `an accepted problem with no
disposition: is INCOMPLETE-PROBLEM`, `an accepted problem with no opened: is
INCOMPLETE-PROBLEM`, `an accepted problem does not count toward
problem_open_max`, `an unrecognised status still names the three it accepts` and
`an orphaned disposition: in a problem ledger is reported`
(tests/check-trace.bats), each watched failing first.

**PR-zt5c2v**: `merge-change` step 6a prescribes the `supersedes:` /
`superseded-by:` pair and the dual `verifies:` line, and no script reads either
keyword, so a half-applied supersession is caught only by a human reading every
site that named the superseded ID.
affects: scripts/check-trace.sh, which sees two unrelated items — `grep -rn
supersede scripts/` matches nothing; skills/merge-change step 6a, which
prescribes the reciprocal annotations as though a gate read them, and correctly
notes that `superseded-by:` exempts nothing, so `MISSING-TEST` already covers
the test half of the form.
opened: 2026-09-10
status: resolved
Measured downstream on that project's first use of the form: six sites half
applied — two verification rows in a risk file, a hazard-file row, and three
`affects:` lines — of which review round 2 found five and round 3 the sixth.
Reciprocity is the checkable half and would have caught five of the six in one
pass. A tree-wide sweep for stale references to a superseded ID is a second and
larger question, because an `affects:` line may legitimately name an old ID as
history.
Root cause: the form was prescribed by a skill and read by no script —
`grep -rn supersede scripts/` matched nothing. Fixed by a reciprocity scan over
the ledger directories reporting `NON-RECIPROCAL-SUPERSESSION` in both
directions, keyed on `REPLACEMENT<TAB>REPLACED` so the two relations are
comparable, plus `check_orphans` for both keywords now that they are
block-parsed. The scan runs last in the file, because placed early it became the
first reader of every ledger and answered two existing unreadable-file tests
with its own message. The sweep for stale references is deliberately NOT
implemented and the skill now says so. Reproduced by six tests in
tests/check-trace.bats, each watched failing first: the two half-supersession
reports (one per direction), the cross-ledger case, the two orphaned halves, and
the per-predecessor judgement of a two-ID list. Their full names are in that
file; they are deliberately NOT quoted here, because every one of them begins
with the keyword and a wrap that puts it at column one is read as a real
annotation — this very passage was reported as MALFORMED-SUPERSESSION by the
gate this item adds, which is the neatest possible demonstration that it works.
Two further tests —
`a reciprocal supersession pair is silent` and `an affects: line naming a
superseded ID is not a finding` — assert an absence and were green before the
gate existed; they are scope controls, not red-to-green evidence, and are
recorded as such rather than attested.

**PR-h3wujj**: `traces:` and `satisfies:` are read by `gr_id_run`, which finds
its keyword anywhere on a line, so an indented `- satisfies: <ID>` bullet
outside every item block is reported by nothing at all, and the derived item it
declares is never checked against the RMF while the run exits 0.
affects: scripts/lib.sh, which states this as STILL OPEN in the same note that
records `status:`/`opened:` as closed, and gives the route out immediately
below it; skills/check-traceability, which that note defers to;
templates/problems.md, whose one-line prose about resolving in the merging
change is what fired the previous attempt at this rule and reverted it, and
its installed twin docs/problems/README.md, which the revert note never named
and which is the same sentence in the same position.
opened: 2026-09-10
status: open
**NOT resolved, and the status is the point.** The backstop is genuinely wider
and every widening below is measured and pinned by a test watched failing. What
is withdrawn is the CLAIM OF CLOSURE. Three independent review rounds each found
a markdown list form that the round before had called closed:

| round | the item was marked | what the next round measured still live |
|---|---|---|
| 1 | resolved | the design was inverted — see the containment note below |
| 2 | resolved | ordered markers: `1. satisfies:` and `1) satisfies:` |
| 3 | resolved | task-list items: `- [x] satisfies:` |

The third is unfixed here and is reproducible today: `- [x] satisfies: REQ-x`
under a heading, outside every block, exits 0 with nothing printed; the same
line inside a block is credited, so `- [x] satisfies: derived` gives
`UNANALYZED-DERIVED`. This repository's own `docs/plans/` use `- [ ]` lists.

A fourth patch to `gr_kw_lead` would close that one form and this item would be
marked resolved a fourth time on the same evidence as the previous three: that
nobody had yet found the next form. The honest reading of three rounds is that
markdown list syntax is not a set this author can enumerate by inspection, so
the enumeration stops being a promise. What the item now claims is bounded and
checkable — bullets `-`, `*`, `+` and ordered markers `<digits>.` / `<digits>)`,
in runs, are stepped over; every other form is unenumerated and presumed live.

Closing this needs one of two things that are changes of their own: a reader
narrowed so the backstop can contain it without enumerating anything, or a
markdown-aware line classifier rather than a prefix regex. Both are larger than
this change and neither should be smuggled into a patch that adds one more
alternation.

The field vote is to close it, and the argument is the toolkit's own: the block
rule makes the hole rare rather than impossible, and rare is the property that
produces a false green nobody is looking for. Closing it needs the offending
template line moved inline into backticks first, then a ratchet upgrade note of
the kind skills/ratchet already contains for a tightening — not the report's
warn-now-fail-later release, which is a gate that reports and proves nothing.

What was built, which is a partial fix and is recorded as one. Root cause:
`gr_kw_here` tested `index(line, kw) == 1` while `gr_id_run` finds
its keyword anywhere on the line, so a list-item annotation was credited inside
a block and reported by nothing outside one. Fixed by `gr_kw_lead`, which
steps over one or more leading list markers, and by `gr_kw_orphan_here`, the
predicate built on it — `index(gr_kw_lead(line), kw) == 1`.

**Twice, because the first cut knew half of list syntax.** `gr_kw_lead` shipped
matching `-`, `*` and `+` and nothing else, and round-2 independent review
measured an ordered-list item reproducing the defect verbatim: `1. satisfies:`
and `1) satisfies:` SILENT outside every block, CREDITED inside one. A doubled
marker, `- - satisfies:`, was silent on the same reading. The rule now steps
over a RUN of markers, bullet or ordered — digits closed by `.` or `)` — so
neither the delimiter nor the nesting depth decides whether an orphan is
reported. A bare number is still not a marker: the `.` or `)` is required, or
`1 status: of the bus` would be reported as an annotation.

**The fix is to the BACKSTOP, and to the backstop ALONE.** The first attempt
routed `gr_kw_here` and `gr_value` through `gr_kw_lead` as well, widening every
reader with the backstop, and an independent review rejected that on two
demonstrated regressions. Both turn on first-occurrence-wins: a `PR` block
quoting `- status: resolved` in its prose above its own column-one
`status: open` gave the reader the quotation and left the roll-call at exit 0,
and a verification record declaring `branch: other-change` that quoted
`- branch: my-change` became the record FOR `my-change`, reporting a pass over
a review that never happened. The invariant is therefore a CONTAINMENT and not
an equality — the backstop must see at least what every reader sees — and the
readers are back at column one, `gr_value` with them. A list-item annotation is
never read, and is reported where it belongs to no item; inside a block it
leaves the field missing, which is `INCOMPLETE-PROBLEM` or `MISSING-RECORD` and
is loud.

Pairing `gr_id_run` with `gr_kw_here` instead would have rejected the
documented primary form: `templates/sad.md` ships the annotation ON the
definition line, and check-trace.sh states as much at both readers. So the
residue is deliberate, and it is stated in full rather than by example, because
naming one case of it was how the ordered-list gap went unnoticed for a round:
`gr_kw_lead` steps over LIST MARKERS and nothing else, so every other position
`gr_id_run` accepts — a mid-sentence mention, a blockquote `> satisfies:`, a
table cell, a keyword wrapped in emphasis — is still credited inside a block
and still unreported outside one. Equally deliberate: bare indentation with no
marker still declares nothing, which is what keeps the ledger templates' own
grammar examples inert — it is the absence of a MARKER, never the indentation.

Reproduced by `gr_kw_orphan_here accepts a list marker before the keyword` and
`check-trace: a bullet satisfies: outside every block is an orphan`, each
watched failing first; and, for the two review findings, by `check-trace: a
quoted bulleted status: does not outrank the item's own` (the item vanished
from the roll-call, `problems: open 0`) and `check-review: a quoted bulleted
branch: does not claim the record` (exit 0 over a review of another branch),
both watched failing against the rejected widening. The full red → green table
and the scope controls are in `docs/verification/2026-09-16-close-kw-asymmetry.md`
and are deliberately NOT repeated here: this item had a competing list of
four until round 3 found it disagreeing with the record's list of six about
which tests are evidence and which are controls. One list, in the record, and
what it records is that the controls are scope controls rather than evidence,
recorded as
such. `check-trace: a bullet status: is not read as the problem status` was
inverted from the rejected design and now pins the loud rejection.

One mutation anchor died to this edit and was re-cut and re-proved:
`2026-08-25-problem-triage.mutations/M30.sh`, which quotes the whole
`gr_value` body, still kills 1 test after re-cutting, the same count its
original record gives.

**PR-crcee5**: 38 of this repository's 184 mutation scripts can no longer
apply, so a fifth of its mutation evidence is unreproducible and nothing reports
it — every `M*.sh` embeds a line of the script it mutates as a literal anchor
and asserts one match, and no gate runs any of them.
affects: docs/verification/2026-08-20-scan-pathspec.mutations (6 of 18),
2026-08-22-id-tokens.mutations (10 of 54), 2026-08-23-review-artefact.mutations
(1 of 33), 2026-08-25-problem-triage.mutations (9 of 53) and
2026-08-27-config-schema.mutations (12 of 26) — five numerators summing to the
38 this item claims, re-measured 2026-09-10 against the merged tree after the
independent review found this line still containing the superseded 41-era
breakdown; scripts/lib.sh and
scripts/check-trace.sh, whose lines most of the dead anchors quote;
tests/portability.bats, the only reader of those directories, which greps them
for `sed -i` spellings and nothing else.
opened: 2026-09-10
status: resolved
Measured 2026-09-10 by applying every `M*.sh` against a restored copy of
`scripts/` and recording which ones failed their own `s.count(old) == 1`
assertion. All 38 predate this change and are nobody's regression in particular
— they accumulated one refactor at a time, because a mutation script is evidence
that no gate re-runs.

AMENDED 2026-09-10, and the amendment is the item's own best evidence. The
first count here was 41, of which this change was reported to have caused three.
Both figures were wrong. This change broke **five** anchors — M21, M22 and M31,
found while writing it, and M03 and M38, found only by the independent review at
`merge-change` step 6a, after the change had already added the
`develop-change` step that exists to catch exactly this. All five are re-cut and
each is proved to still kill tests (M21 kills 11, M22 2, M31 2, M03 2, M38 1),
so the corpus is back to the 38 that predate the change and no worse. The 41 was
a mid-flight measurement recorded as though it were final: it was taken before
M31 was re-cut and before M03 and M38 were known to be broken at all. PR-dr7k7k
records the missing control this exposed. Two questions this does not answer, and
both belong to its own change: whether a gate should run the mutation corpus at
all (`portability.bats` already walks these directories, so the hook exists),
and whether an anchor should be a line quotation at all rather than something
addressed more stably. Re-cutting 38 anchors by hand and reproving each one
kills tests is the floor, not the fix.

A second, smaller defect in the same corpus, found while measuring it and
recorded here rather than given its own ID because it is the same artefacts and
the same change will touch them: the `2026-08-20-scan-pathspec.mutations`
scripts rewrite their target through a temp file at the REPOSITORY ROOT —
`awk … > t && mv t scripts/check-ids.sh`. When the awk fails, `&&`
short-circuits, the `mv` never runs, and `t` is left in the working tree.
Observed twice while running the corpus for this change. An untracked file in
the tree fails `verify-before-merge`'s clean `git status` check, so measuring
the mutation evidence can block the merge gate of whatever change happens to be
open — and the leak is silent, because the mutation that leaked it also failed.

That second defect is **not** resolved by `47a8b1d` and is now `PR-fxdgw5`,
which defines it with a current measurement. The reason it was recorded without
an ID — the same change would touch the same artefacts — expired when that
change repaired the anchors and left the 16 scripts' rewrite idiom alone.

Resolved by `47a8b1d`. The fix is the one this item asked for and not a
re-cutting of 38 anchors: `tests/mutate.sh` applies every mutation in a scratch
tree built from `git ls-files` and checksums that tree before and after, so the
verdict does not consult the script's own account of itself. Measured that way
the population is **46**, not 38 — eight scripts rewrote their target
identically and exited 0, which is why reading exit codes undercounted. Of the
46, 29 were re-anchored and each proved to still kill tests, 16 declare
`# retired: <reason>` because the production code they mutate no longer exists,
and one (`2026-08-23-review-artefact.mutations/M15.sh`) is retired as an
equivalent mutant that never applied. Both halves of the symptom are now false:
`tests/mutate.sh` exits 0 at `167 applied, 17 retired, 0 unusable`, and
`tests/mutations.bats` fails naming any mutation that neither applies nor
declares a retirement — so `tests/portability.bats` is no longer the only reader
of those directories. The accounting, the per-commit attribution of all 46 and
the kill proofs are in
`docs/verification/2026-09-17-restore-mutation-evidence.md`.

The flip is late and the lateness is recorded rather than smoothed over.
`skills/resolve-problem/SKILL.md` §4 — "never mark a problem resolved in a
change that doesn't contain its fix" — and `docs/problems/README.md`, which
states the same rule in one line, are the two places it exists; `merge-change`
states it nowhere. `47a8b1d` merged the fix without editing this item, and
nothing reported the omission, because no gate can connect a change to the
problem it closes — the link exists only in prose. This change performs the
flip alone: it contains no fix and claims none, and its evidence is the gate
re-run recorded in its own verification record.

**PR-z6uaa8**: The skills an agent actually executes are installed copies that
nothing keeps in step with `skills/`, so seven of this repository's eleven
skills are running at a version the repo abandoned, and no gate, script or
document reports the drift.
affects: install.sh, whose `--copy` mode freezes the skills at install time and
whose symlink default exists precisely to avoid that, with nothing to detect
which mode a given install used; AGENTS.md, which makes `scripts/` the source
of truth for the check scripts and states nothing about how a skill reaches the
harness; skills/merge-change/SKILL.md, skills/ratchet/SKILL.md,
skills/develop-change/SKILL.md, skills/resolve-problem/SKILL.md,
skills/analyze-risks/SKILL.md, skills/check-traceability/SKILL.md and
skills/grill-requirements/SKILL.md, the seven measured as diverged.
opened: 2026-09-15
status: open
Measured 2026-09-15 on the machine this change was developed on:
`~/.claude/skills/<name>` symlinks to `~/.agents/skills/<name>`, which contains
real directories dated 2026-09-05 — not links into this repository. Eleven
skills compared against the change worktree: seven differ, four match. Two of
the seven (`merge-change`, `ratchet`) had already diverged from `main` before
this change, containing edits from e2eac86 and 51f01b7 that never reached the
install, so the drift is two generations deep rather than one.

AMENDED 2026-09-15, before this item was ever merged, because two of its
figures were wrong and a third was inferred rather than measured — the same
failure this change's own verification record indicts at length, committed in
the item that records a drift nobody was measuring.

* **Five skills, not two, had already diverged from `main` before this change
  started**: `analyze-risks`, `check-traceability`, `grill-requirements`,
  `merge-change` and `ratchet`. The change edits four skills
  (`develop-change`, `merge-change`, `ratchet`, `resolve-problem`), and seven
  differ in total; three of the seven were never this change's doing at all.
  The first draft stated two, which understated the standing drift by more than
  half in the one field a reader would use to size the fix.
* **The drift is one generation, not two.** The installed copies of all five
  are byte-identical to `e2eac86`, whose commit time is 2026-09-05 10:11:58
  against install directories dated 2026-09-05 10:13. `e2eac86` reached the
  install; only `51f01b7` did not. The first draft's "two generations deep"
  was falsifiable from the same two files it claimed to have compared.
* **The cause is not measured, and `install.sh --copy` is a guess.** Neither of
  that script's modes produces what is on disk: the default writes a symlink at
  `~/.claude/skills/<name>` pointing INTO this repository, and `--copy` writes a
  real directory there. What exists is a symlink at `~/.claude/skills/<name>`
  pointing at `../../.agents/skills/<name>`, a real directory in a store that
  also contains skills from elsewhere (`solidity`, `find-skills`, `eli5`). That is
  consistent with `--copy` under `CLAUDE_SKILLS_DIR`, and equally consistent
  with a third-party skills manager this repository knows nothing about. The
  mechanism is therefore an open question, not a finding, and the scope note
  below is written accordingly.

Not hypothetical, and this change is the demonstration. The `merge-change` text
executed at step 6d during this very merge read `git worktree list` — the
version this change replaced — while the repository's read
`finish-merge.sh --check <branch>`. The preflight was run anyway because the author
had just built it and remembered; an agent following the instruction it was
given would have eyeballed a registry listing instead of running the gate,
which is exactly the defect PR-k77dzn exists to close. A skill that states one
thing in the repository and another in the harness is the same false green as a
gate that exits 0 having proved nothing, moved one layer up.

`install.sh` symlinks by default and documents the reason in its own header —
"Symlinks by default so `git pull` updates them" — so its default would have
prevented this. Whether `--copy` produced the layout on this machine is
unmeasured (above), and the defect does not depend on the answer: **no mode of
any tool here reports that an installed skill has stopped matching its source**,
and that is true whichever tool did the installing. The toolkit's own thesis
applies to itself. The field report this ledger answers opened by praising 0.5.1
for ending an adopter's vendored `lib.sh` divergence, and guardrails was
containing the same divergence in its own skills while reading that praise.

Deliberately recorded and not fixed. Four questions belong to its own change,
and the first is now the measurement: **what actually installed these copies**,
since the answer decides whether `install.sh` is implicated at all. Then:
whether a check should compare the installed tree against `skills/`, and where
such a check could run given that the install path is outside every repository;
whether `--copy` should remain if it turns out to be the mechanism; and whether
AGENTS.md should state a skills distribution rule the way it already states one
for `scripts/`. What would close this instance is re-installing the skills by
whatever means put them there — which is the first question above, not an
assumption to act on, and it answers none of the rest.

**PR-dr7k7k**: No skill told an author to check whether a change stales a
mutation anchor, so a change could delete a past change's mutation evidence
with nothing going red — the corpus is read by no gate, and `s.count(old) == 1`
fails only when someone next runs the script by hand.
affects: skills/develop-change/SKILL.md, whose red-green-refactor loop had no
step between REFACTOR and Commit for it; tests/portability.bats, which walks
docs/verification/*.mutations/ for `sed -i` spellings and reads nothing else in
those files; docs/verification/2026-08-25-problem-triage.mutations/M03.sh, M21.sh,
M22.sh, M31.sh and M38.sh, the five this change broke before the control existed.
opened: 2026-09-10
status: resolved
Root cause: an obligation that lived only in the reviewer's habit and in three
ad-hoc dispatch prompts, in a repository whose own thesis is that prose loses to
executed code. Demonstrated by this very change, which broke five anchors: three
were caught by hand, and M03 and M38 reached the independent review — after
the control had been written but before it was applied to work already merged.
Fixed by a mandatory step 6 in `develop-change`'s loop: grep the mutation
directories for every changed output line, re-cut what it names, and prove the
re-cut anchor still kills tests, because an anchor that matches again and kills
nothing means the tests never covered it. Reproduced by `skills.bats:
develop-change: the loop greps the mutation anchors for a changed line`, watched
failing against the unedited skill (`grep -q 'mutations' "$skill"` failed).
The step catches BOTH ways an anchor dies — an edited line, which reports zero
matches, and a duplicated one, which reports two; M31 and M38 were the second
kind, and no reading of the diff alone would have shown them.
