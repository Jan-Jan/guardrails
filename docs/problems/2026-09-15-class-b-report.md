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
  directories showed how many were already dead.
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
change is what fired the previous attempt at this rule and reverted it.
opened: 2026-09-10
status: open
The field vote is to close it, and the argument is the toolkit's own: the block
rule makes the hole rare rather than impossible, and rare is the property that
produces a false green nobody is looking for. Closing it needs the offending
template line moved inline into backticks first, then a ratchet upgrade note of
the kind skills/ratchet already contains for a tightening — not the report's
warn-now-fail-later release, which is a gate that reports and proves nothing.

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
status: open
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
