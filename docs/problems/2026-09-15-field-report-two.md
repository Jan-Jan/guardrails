# Problem reports — the second field report from a class B adopter

Seven of the nine items here come from the second field report, which arrived
on 2026-09-13 from the same downstream SvelteKit project, IEC 62304 class B, measured that day against its
`dev` branch at `b574fac2` with a vendored copy of 0.5.1. Recorded here before
anything was touched. Every figure the report gives is given with the command
that produces it, and the report asks for none of them to be durable — which is
the practice `PR-hkc376` below asks this toolkit to stop obstructing.

The report makes six requests. **Five of the six are resolved here; request 2 is
not.** That request had two halves and this ledger gives each an item —
`PR-8ucezf` for the foreign-draft verdict and `PR-9xxz3b` for the gate-scope
split — and both are open. `PR-8ucezf`'s fix was built, reviewed twice and
withdrawn on 2026-09-16, when the second round showed it contradicted this
change's own reasoning about the same discriminator. `PR-9xxz3b` was recorded
open from the start, because the delivery its request names is a breaking change
to the one contract every adopter reads.

Counting items rather than requests, this ledger contains **nine: five resolved
and four open.** Seven come from the six requests, request 2 contributing two;
the eighth, `PR-umtm9b`, was raised by this change's first review round, and the
ninth, `PR-kc2pzm`, by its fifth — the half of request 6 that five rounds of
review could not state correctly, recorded with all five attempts.

**What is different about this report.** The first one, answered in `d8502d1`,
named defects in scripts. This one names defects in **what the process requires
an author to write down**, and its evidence is the review rounds those
requirements cost rather than a failing command. Four of the six are pure
deletions or restatements of required content. That is the cheapest kind of fix
and the hardest kind to notice is needed.

**Three items are not from the report.** The unconditional commit in `merge-change`
step 3 was found while assessing §3 and is recorded inside `PR-dkm5tq`, where it
belongs: it is the same re-entrancy defect, one step earlier. `PR-umtm9b` was
found by this change's own independent review, in the item this change wrote —
`finalize-docs.sh` adopts another change's draft, which is the mechanism behind
the symptom `PR-8ucezf` was written to address and read at the wrong script. It
is recorded open, with both candidate fixes and the reason neither was taken
during a fix round. `PR-kc2pzm` was raised by round 5, and is the part of request
6 this change could not deliver: five formulations of one boundary rule, five
rejections, recorded so a later change starts from the failures rather than from
the ask.

The four open items are `PR-8ucezf` (the foreign-draft verdict, withdrawn with
its two rounds of evidence kept), `PR-9xxz3b` (the gate-scope split),
`PR-umtm9b` (the same foreign-draft problem in the other script) and
`PR-kc2pzm` (bounding what a `record` finding costs). The two
foreign-draft items are
deliberately left as a pair: they are two defects in two scripts that need one
discriminator, and separating them is what let this change ship a rule in one
while arguing against it in the other.

**PR-hkc376**: `merge-change` step 6b requires the verification record to state
"open PR warnings", so a per-change artifact is required to record whole-ledger
state — a census correct for as long as it takes another change to merge.
affects: skills/merge-change/SKILL.md step 6b, whose required content names the
roll-call; templates/verification.md, whose gate table has a `check-trace.sh`
row and a preamble demanding fresh figures, which reads as an instruction to
paste the census; skills/resolve-problem/SKILL.md, whose red flags do not yet
reject a backlog figure in a document.
opened: 2026-09-15
status: resolved
Measured downstream 2026-09-13: 78 of 123 verification records mention the
open-PR roll-call and 20 pin a number, 24 times, across the distinct values 17,
48, 49, 50, 52, 53, 54, 55, 56 and 57 — a sawtooth rather than a trend, because
each is a census taken at a different instant, and every one of them is now
wrong including the ones that were right when written. The cost is the review
rounds: one 12-round change spent twelve of its 61 findings on stale numbers and
concluded that "nine consecutive rounds found an error inside a correction
written for the previous round's error"; another had three count sentences
falsified by two closures that **no ID-grep could have found**, because a count
names no ID; commit `328f0cfd` is an entire change, 8 rounds and 7 rejections,
whose only purpose was correcting a finding total in an already-merged record.
The template's heading this change replaced — "Every figure derived from the
tree under test, not copied forward." — is the doctrine this item extends: a global figure measured
fresh is stale by the same mechanism, only faster.
Root cause: a required field of a per-change artifact named a property of the
whole repository, so an author following the instruction exactly produced a
sentence that another change falsified. Fixed by deletion rather than by a gate:
step 6b now requires the IDs this change resolves, accepts or opens; the gate
table's preamble rejects a repository figure outright, freshly measured or not;
step 7's commit template gains `Resolves:` and `Opens:`, which are checkable
against the diff forever; and `resolve-problem`'s red flags answer the thought
that produces the census. A check against count-shaped prose was considered and
rejected, by the reporter and here — a shape guard loses to respellings, and the
cheap fix is to stop asking for the number. Reproduced by `merge-change: the
record states the ledger delta, not the open count`, `merge-change: the commit
template states the Resolves and Opens trailers`, `verification template: a
repository figure does not belong in the gate table` and `resolve-problem: a
backlog figure in a document is a red flag` (tests/skills.bats), each watched
failing first.

**PR-8ucezf**: `check-ids.sh`'s `DRAFT-FILE` scan reads the whole tree, so a
draft ledger file leaked by any merged change fails step 4 for every subsequent
change, under a verdict that names no other change.
affects: scripts/check-ids.sh, whose scan is
`git ls-files --cached --others --exclude-standard -- .` and whose header states
the rule as "no draft-named ledger files may reach the base branch" without
distinguishing whose; skills/merge-change/SKILL.md step 4, which lists the
verdict among the things the merging change must answer for, and which now states
plainly that the verdict cannot tell the two apart.
opened: 2026-09-15
status: open
Recorded downstream in `docs/verification/2026-09-07-settings-nav-install-color.md`:
commit `4deb0248` merged with a draft problems-ledger file (their
flake-cluster-inert-isvisible-timeout item) unfinalized, "which was blocking
`check-ids.sh` for every subsequent merge". An unrelated change repaired it, and
that change's record has to explain why it contains a rename with no REQ and no
PR of its own. The report's framing of the general rule is the best test this
toolkit has been offered for a gate: *does this verdict change if an unrelated
change merges first?* Where the answer is yes, the gate measures the repository
rather than the change.

**A fix was built here, reviewed twice, and withdrawn. The two rounds are the
item's evidence and are kept rather than deleted.** A `FOREIGN-DRAFT` verdict
was added to `check-ids.sh`, discriminating on whether a draft's basename opens
`DRAFT-<current branch>-`. Round 1 found it **unreachable** in `merge-change`'s
own sequence: step 3 runs `finalize-docs.sh` first, and that script renames every
draft in the ledger directories whoever wrote it, so a foreign draft is adopted
and gone before step 4 could convict it. Round 2 found the verdict **wrong in its
own right**: a draft this change created, whose name does not embed the branch,
is reported as another change's, and step 4 then told its own author to park the
change and repair someone else's leak. Reproduced on a fixture: a draft problems-ledger file whose name is a slug with
no branch in it, committed on branch `mine`, is convicted; renaming the branch so
that the name happens to open with it makes the same file pass. (The file name is
described rather than written, because a draft file name in this ledger is read
by `DANGLING-FILE` as a reference to a file that ought to exist — the third time
this item has tripped that, and the reason it is spelled out here.)

**The contradiction is what settled it.** `PR-umtm9b` below rejects exactly this
discriminator for `finalize-docs.sh`, on the ground that it convicts drafts whose
names contain no branch — a shape the convention permits and this repository's own
fixtures use. The change was shipping in one script the rule it argued against in
the other, and both could not stand. Round 2 stated it in those terms; the
project owner ruled on 2026-09-16 to cut the work rather than defend it.

So this item is **open**, and what it needs is a discriminator that is right in
both scripts. Presence on the base branch is the candidate: a draft this change
did not create is one that already exists in the base, which depends on no naming
convention and matches the reported case exactly. It costs a base-branch
dependency neither script has today, which is why it belongs to a change that can
argue it rather than to a fix round. Until then `merge-change` step 4 states the
limitation in prose: `DRAFT-FILE` does not say whose draft it is, the reader
judges by the path, and the obvious mechanical test is unsafe.

Reverted with it: six tests in `tests/check-ids.bats`, the classifier in
`scripts/check-ids.sh`, three tests in `tests/skills.bats`, and the
`check-traceability` verdict row. `scripts/check-ids.sh` and
`tests/check-ids.bats` are byte-identical to the base — to `3714f08` when the
revert was made, and to the current base now, since later changes rewrote both
files
and this change took their versions whole.

**PR-dkm5tq**: `merge-change` dispatches the verification suite at step 2 and
again at step 6 on every findings round, and after the first round the two runs
are the same run over the same tree — step 3 renames nothing once the drafts are
dated, and steps 4 and 5 are read-only.
affects: skills/merge-change/SKILL.md steps 1, 2, 3 and 6, and its red flag
"Skip re-verification, the rename touched no code", which answers the question
with the author's judgment rather than with a measurement;
templates/verification.md, whose gate table states which tree its figures
describe only by convention — `docs/verification/2026-09-10-field-report-items.md`
names `798790d` and explains why, so the practice is already ahead of the schema.
opened: 2026-09-15
status: resolved
Measured downstream: at 12 rounds, with a reviewer independently re-running the
suite each round on top, this is the single largest consumer of wall-clock in a
change. One of their records deviates from the skill and documents the
deviation, because the author could see the two runs were the same run.

A second defect in the same step, found while assessing the report and not in
it: step 3's
`git add -A && git -c commit.gpgsign=false commit -m "chore: finalize ledger files"`
is unconditional, so on a round where `finalize-docs.sh` renamed nothing
`git commit` exits 1 with nothing to commit — a halt for no defect, in a
sequence whose first instruction is to halt on any failure.
Root cause: the evidence was keyed to a round rather than to a tree, so the only
way to know whether a re-run was needed was the author's memory of what the
round touched. Fixed by making the tree the key: step 2 records
`git rev-parse HEAD^{tree}` beside its gate summary, step 6 dispatches again
only where step 3 renamed something or the hash moved, the record names the tree
its figures describe, and step 1 states that an already-merged base leaves that
hash where it was. Step 3's commit is now conditional
(`git diff --cached --quiet || git commit …`), which removes the spurious halt.
The red flag that answered this with judgment now answers it with the hash.
Reproduced by `merge-change: step 6 stands on step 2 where the tree is
unchanged`, `merge-change: step 2 records the tree its gate summary describes`,
`merge-change: step 3 commits only when it renamed something` and `verification
template: the gate table names the tree the figures describe`
(tests/skills.bats), each watched failing first. The first version of this fix
was incomplete and the independent read of it caught that: step 6 compared
against a hash step 2 never recorded, so the rule was unusable on its first
pass.

**PR-xec7dd**: `finalize-docs.sh` names its output `<merge-date>-<slug>.md` and
states that "the merge date cannot be known until the merge", but the date comes
from `date +%Y-%m-%d` when the script runs, at step 3, and the script is a
silent no-op on an already-dated tree — so a change whose findings round crosses
midnight is named for its first finalize attempt and nothing re-dates it.
affects: scripts/finalize-docs.sh, header and rename line; scripts/lib.sh:586,
which states the same claim about the same rename; skills/merge-change/SKILL.md
step 3, skills/worktree-discipline/SKILL.md, skills/grill-requirements/SKILL.md,
skills/ratchet/SKILL.md, templates/problems.md, templates/srs.md,
templates/rmf.md, templates/sad.md and templates/AGENTS-block.md, each of which
states "merge date" for a name that records something else; README.md at three
sites, the project's front door, and docs/problems/README.md, this repository's
own copy of templates/problems.md, which had drifted from the template — both
found by the independent review after the first draft of this item claimed ten
sites under skills/ and templates/ alone.
opened: 2026-09-15
status: resolved
Measured downstream 2026-09-13: 49 of 193 dated ledger files have a name-date
earlier than the commit that introduced them, the largest gap 6 days. The churn
is twofold — someone proposes a rename, which would break every reference that
does resolve, and a review round rules on it; one of their records spends a
paragraph reaching the ruling that a one-day deviation is not a defect. The
filename is a handle. The merge date is in git. Re-dating on every finalize pass
was considered and rejected with the reporter: it moves references for nothing.
Root cause: a claim nothing enforced and nothing could — the script cannot know
the merge date, and it never pretended to anywhere but in its own prose. Fixed
by naming the date what it is, in `finalize-docs.sh`'s header, at
`scripts/lib.sh:586`, and at the **fourteen** documentation sites that stated
"merge date" — ten under `skills/` and `templates/`, three in `README.md`, and
one in `docs/problems/README.md`, the last being this repository's own copy of
`templates/problems.md`, which fixing the template does not reach. No behavior
changed. Reproduced by `finalize-docs: the
header states the finalize date, not the merge date` (tests/finalize-docs.bats,
which greps both scripts) and `the skills and templates name the finalize date,
not the merge date` (tests/skills.bats), both watched failing first — the second
printing the offending sites at each widening of its scan: ten under `skills/`
and `templates/` when it was written, three more when round 1 extended it to
`README.md`, and one more when round 2 extended it to `docs/problems/README.md`.
The plan had claimed eight.

**PR-9zvb36**: `finalize-docs.sh`'s rewrite pass is scoped to the ledger
directories and the SOUP file, and `check-trace.sh`'s `DANGLING-FILE` reads that
same scope, so a `DRAFT-` link outside it — in a plan, in a verification record
— is reported by nothing at all.
affects: scripts/finalize-docs.sh, whose rewrite scope is correct and stays as
it is, and whose comment already states why plans and records are excluded;
scripts/check-trace.sh's `DANGLING-FILE`, which reads the doc_* files alone;
skills/merge-change/SKILL.md step 3, the only place an author is told what to
read out of the script, which listed every line it prints except this one.
opened: 2026-09-15
status: resolved
Recorded downstream in `docs/verification/2026-09-05-fetch-names-flake.md`,
finding-1: a review round spent on four dead `DRAFT-` links in one plan, repaired
by hand in commit `97d6763e` and re-verified by a second round. The exclusion is
right — those files narrate the rename, and rewriting a true sentence about
history makes it false — so the answer is a report rather than a wider scope.
The script knows both names of every file it renames, which is the same
observation that closed `PR-58zsvf`: the second pass it never made.
Root cause: the rewrite pass and the gate that catches what it misses read the
same scope, so everything outside that scope was covered by neither. Fixed by a
report rather than a wider scope: after the rewrite, each old basename is
scanned for across the whole tree, the files the pass rewrote are subtracted,
and what remains is printed as `unrewritten FILE:LINE: NAME` with the note that
it is outside the rewrite scope. Informational, exit status untouched, and the
script does not judge narration against link — that judgment is the author's and
takes five seconds. Reproduced by **seven** tests, each watched failing first:
six in tests/finalize-docs.bats — the five written for it plus the fatal-path
test round 1's review required — and `merge-change: step 3 tells the author to
read the unrewritten lines` in tests/skills.bats, which round 1 added when it
found that nothing told an author the report existed. One of them was written vacuous by this change's own plan
and had to be strengthened: a reference inside the rewrite scope is gone from
the tree once rewritten, so the test passed with the subtraction deleted. It now
uses the one shape where a scoped file still contains the old basename after the
pass, and was watched red against the subtraction removed.

**PR-3s74u3**: `merge-change` step 6a states no scope for a finding and no
criterion for a converged review, so a finding against prose is dispositioned by
writing more prose in the same round-trip as a finding against code, each
correction is new unreviewed prose, and nothing states when the rounds end.
affects: skills/merge-change/SKILL.md step 6a, whose four questions are about
code and requirements while its documentation checklist reaches much wider, and
whose "findings block the merge … the sequence reruns from step 1" stated no
stopping point at all; templates/verification.md, which is where a finding is
actually written down and so must state the tag; scripts/check-review.sh, which
needs no change, because it block-parses the finding header and never reads the
value.
opened: 2026-09-15
status: resolved
Measured downstream across three changes: 12 rounds where rounds 11–12 found no
code defect and no mutation left alive, the last five finding "predominantly
false or stale statements in this change's own records rather than defects in
it"; 7 rounds where rounds 4–7 found no code defect at all; 8 rounds and 30
findings on a change with no production code. 27 rounds, and the majority of the
later ones were the document catching up with itself. Their product owner ended
one change at round 5 with the residual booked in the record — an honest ruling,
made against a skill that implied rounds continue until clean.
Root cause: every finding cost the same — a full suite re-run and a fresh review
of the correction — whether it named a defect in the software or a misquoted
citation, and nothing stated when the rounds end.

**The report asked for three things and this change delivers two.** Fixed at
step 6a: the reviewer tags each finding `code`, `requirement` or `record` as the
first word of its value, which `check-review.sh` already ignores, so no script
changes; and **a round raising no `code` and no `requirement` finding is the
last review round**, which is the stopping criterion the reporter's product owner had to
invent ad hoc. One clean round and not the reporter's two: the second buys one
independent read of the first's corrections at the price of an entire review
dispatch, and the regress has no end — the verification record is the artifact
this process does not verify, which `328f0cfd` established rather than repaired.
Decided at the interview of 2026-09-15.

**The third ask — that a `record` finding not re-run the gate — is deliberately
not delivered, and `PR-kc2pzm` records why.** Five formulations were written and
five review rounds rejected them, each version resting on the same false premise:
that some class of files is unread by every gate. There is none, because
`check-ids.sh` greps the whole tree. Step 6a states plainly that every finding
reruns whatever its tag, so no reader infers a saving from the tag's existence.
Reproduced by three tests in tests/skills.bats, each watched failing first:
`merge-change: the reviewer tags every finding`, `merge-change: a round with no
code or requirement finding is the last`, and `merge-change: the tag does not
shorten the sequence`, which reads the skill and rejects four superseded
inferences by shape rather than by one spelling. A fourth, `verification template opens every finding with its tag`,
reads the template and rejects four. Between them neither document can drift back
to a boundary rule while the suite stays green — no single test covers both, and
neither names all five formulations.

**PR-kc2pzm**: `merge-change` step 6a's finding tag classifies a round's findings
but bounds nothing, so a `record` finding — a misquoted citation, a stale figure
— still costs a full suite re-run and a fresh independent review of the
correction, which is the cost the reporting project measured and asked to have
removed.
affects: skills/merge-change/SKILL.md step 6a, which now states that every
finding reruns the sequence whatever its tag, and states so explicitly so the
saving is not inferred; templates/verification.md, whose field-grammar block
states what the tag is for and states no boundary.
opened: 2026-09-16
status: open
The ask is the reporting project's §6.1 and it is a real one: three of their
changes spent 27 review rounds between them, the later ones correcting prose with
prose. What defeats it is stating the boundary. **Five formulations were written
for this change and each was rejected by an independent review round**, which is
the whole of this item's evidence:

* by directory — "edits nothing outside `docs/verification/`" — rejected at
  round 1 for making a one-word plan correction a full rerun;
* "edits only files no gate reads" — rejected at round 2: `check-review.sh`
  parses the record and `check-ids.sh` scans the plan, so the class was empty and
  every `record` finding reclassified itself;
* "edits only files no test reads" — rejected at round 3: no test reads the
  problem ledger, which `check-trace.sh` very much does, so the rule admitted
  exactly what it meant to exclude;
* "edits anything the suite reads", with a justification naming `scripts/` and
  `tests/` — rejected at round 4: the suite reads `skills/`, `templates/`,
  `README.md`, `AGENTS.md` and more, so the justification would have mis-tagged
  the round before it;
* the same rule with a concrete file list — rejected at round 5: the list still
  omitted `README.md`, `AGENTS.md` and `.gitignore`, demonstrated by reddening
  `tests/skills.bats` with a `README.md`-only edit.

The common failure is not phrasing. Every version tried to name a class of files
no gate reads, and in this toolkit there is none: `check-ids.sh` greps the whole
tree and `check-trace.sh` reads every `doc_*` file. A change that wants this
saving should start from a different question — not "which files are unread" but
"which gate, if any, could this disposition move", answered per gate rather than
per file, and probably answered by running the cheap gates rather than by
reasoning about them. That is more than a wording fix, which is why it is an item
rather than a sixth attempt.

**Candidate formulations, neither adopted.** Added 2026-10-08 under D10 of
`docs/plans/2026-10-06-salvage-churn-and-parallel.md`: a parallel suite
run measured 650 s (`docs/verification/2026-10-07-test-runner.md`), over
the five minutes below which a cheaper `record` lane would not pay for
itself. Since this item was opened, step 6a dispatches no further reviewer
after the first round with nothing above `low`, so what a later `record`
finding still costs is the rerun from step 1, the suite included. Both
candidates come from the parallel-session proposals of 2026-09-18, which
never merged.

* **P8, per gate, by running the gates.** After that converging round, a
  `record` disposition is checked by `check-ids.sh`, `check-trace.sh`,
  `check-review.sh` and `tests/skills.bats`, about a minute, with no suite
  run; a `code` or `requirement` finding still reruns from step 1. It
  answers the question the paragraph above names, per gate, and is
  untried.
* **P9, the reviewer's run scoped to the round's delta.** Step 6a lets
  only a documentation-only diff stand on the step 6 gate summary. P9
  extends that from the diff to the round's delta: when
  `git diff --name-only <last reviewed commit> HEAD -- scripts tests` is
  empty, the reviewer rests on the tree-named gate summary. Its known
  defect: a delta confined to `README.md`, `AGENTS.md`, `skills/` or
  `templates/` is empty under that pathspec and can still turn the suite
  red, as round 5 above showed with a `README.md`-only edit reddening
  `tests/skills.bats`.

**PR-9xxz3b**: `check-trace.sh` evaluates `PROBLEM-BACKLOG` and `STALE-PROBLEM`
— properties of the ledger and of the calendar — at merge time, against a change
that may not touch the ledger, so another session's merge or the passage of a
night reddens a gate whose repair is not the merging author's to make.
affects: scripts/check-trace.sh, whose problem limits are read once per run over
the whole ledger; skills/merge-change/SKILL.md step 5 and
skills/check-traceability/SKILL.md, which present every verdict as a property of
the change under merge.
opened: 2026-09-15
status: open
Recorded, not fixed, and the scope is stated so the next reader does not
re-derive it. The mechanism the report asks for — `check-trace.sh --scope=change`
for the gates that are properties of the diff and `--scope=ledger` for the
limits — is sound and additive. Its preferred delivery is not, in two ways.
**A new exit code is a breaking change**: `tests/check-trace.bats` asserts exit
status 1 in 143 places and every adopter's CI line reads the same contract.
**Moving the limits out of `merge-change` removes the only thing that forces
triage**: this toolkit has no scheduler, and a ledger review that happens on
demand happens when someone remembers it. What this change does instead is state
the disposition path at the point the gate reddens — including `status:
accepted`, which reached `main` in `d8502d1`, eleven commits after the
reporter's baseline, and which is the third answer their report does not know
exists: a ruling with a `disposition:`, exempt from both limits, never exempt
from the roll-call. Their dichotomy — fix someone else's problem report, or
raise a limit under merge pressure — was true at 0.5.1 and is not true now.
What remains for this item's own change: the flag itself, with the default run
unchanged.

**PR-umtm9b**: `finalize-docs.sh` renames every `DRAFT-*.md` in the four ledger
directories, whoever wrote it, so a draft ledger file left behind by another
change is silently adopted into the merging change — renamed into its diff, its
record and under its `Implements:` line, with no item of its own to explain it.
affects: scripts/finalize-docs.sh, whose planning loop globs `"$dir"/DRAFT-*.md`
and strips the branch prefix only "when it matches", and whose own header
already claims the behavior it does not have — "Renames **this change's** draft
ledger files"; scripts/check-ids.sh, whose `DRAFT-FILE` verdict is the only thing
that meets a leaked draft and cannot say whose it is; skills/merge-change/SKILL.md
steps 3 and 4, which state both limitations in prose because no gate states them
— step 3 that the script adopts every draft it finds, step 4 that the verdict
names no change. This item and `PR-8ucezf` are two halves of one problem and want
one discriminator; a fix to either alone is what this change tried and withdrew.
opened: 2026-09-15
status: open
Found by the independent review of the change that added `FOREIGN-DRAFT`
(`PR-8ucezf`), which is the item that misdiagnosed it — the symptom was read at
`check-ids.sh` when the adoption happens a step earlier. Reproduced in a clean
fixture, quoted in `PR-8ucezf`'s amendment above.

**Deliberately not fixed here, and the reason is the fix's blast radius rather
than its difficulty.** Two discriminators are available and neither is free:

* **The naming convention** — skip a draft whose basename does not open
  `DRAFT-<current branch>-`. This was specified, dispatched, and withdrawn
  before any code was written. `finalize-docs.sh` has always tolerated any
  `DRAFT-*.md` and strips the branch prefix only when it matches, so the rule
  convicts every loosely named draft: three fixtures in this repository's own
  `tests/finalize-docs.bats` become foreign under it — two whose draft names
  contain no branch at all and one units fixture whose branch does not match the
  name — and an adopter whose drafts do not embed the branch name would find
  them silently unfinalized. (Their names are not written out, for the reason
  given in `PR-8ucezf` above.) The withdrawn
  dispatch also observed that the planning loop's same-run collision branch
  becomes **unreachable** under the rule, because basename-to-slug is injective
  once every draft contains the prefix — so a test that exists would be kept
  alive only by an artificial fixture. That is a stronger argument than the
  churn: the rule changes the shape of the problem the loop solves.
* **Presence on the base branch** — a draft this change did not create is one
  that already exists in the base. Convention-independent, and exactly the
  reported case. It introduces a base-branch dependency this script has never
  had, which is not a line to add under merge pressure: `merge-change` step 1
  already argues at length about what "the base" means when a remote is in or
  out of scope, and `finalize-docs.sh` currently needs to know none of it.

Whichever is chosen, the change owes a decision on what happens to a draft that
is skipped — left for `check-ids.sh` to convict at step 4 is the intent, and
that is what makes the two scripts tell one story — and it owes the fixture work
either way. What it must not do is what this change nearly did: take the
convenient discriminator during a fix round, on the evidence of one reproduction.
