# Problem reports — the second field report from a class B adopter

The items from the second field report, which arrived on 2026-09-13
from a downstream SvelteKit project, IEC 62304 class B, measured that day
against its `dev` branch at `b574fac2` with a vendored copy of 0.5.1.
`PR-8ucezf` (the foreign-draft verdict) and `PR-9xxz3b` (the gate-scope
split) are the two halves of the report's request 2; `PR-kc2pzm` (bounding
what a `record` finding costs) is the half of request 6 that five review
rounds could not state.

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
status: accepted
disposition: ruled on 2026-10-30 — draft names are no longer minted (ADR-cy7ahd); merge-change step 3 rules on a draft path this change did not add.
Recorded downstream in the adopter's verification record of 2026-09-07:
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

**The contradiction is what settled it.** A sibling item rejected exactly this
discriminator for `finalize-docs.sh`, on the ground that it convicts drafts whose
names contain no branch — a shape the convention permits and this repository's own
fixtures use. The change was shipping in one script the rule it argued against in
the other, and both could not stand. Round 2 stated it in those terms; the
project owner ruled on 2026-09-16 to cut the work rather than defend it.

So this item stayed **open**: what it needs is a discriminator that is right in
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

Amended 2026-10-13 by ledger-names-at-creation (ADR-cy7ahd). The script that
adopted every draft before step 4 could convict it is deleted, and nothing
creates a draft name any more, so a leftover draft name reaches the base only
through a change that skips the gate. The verdict still reads the whole tree and
names no change. The discriminator this item wants is still presence on the base
branch: a file this branch adds, `git diff --diff-filter=A <base>...HEAD`.

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
status: accepted
disposition: ruled on 2026-10-30 — every finding reruns from step 1, as merge-change step 4 states.
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

**Candidate formulations, neither adopted.** A parallel suite run measured
650 s, over the five minutes below which a cheaper `record` lane would not pay for
itself. Since this item was opened, step 6a dispatches no further reviewer
after the first round with nothing above `low`, so what a later `record`
finding still costs is the rerun from step 1, the suite included. Neither
candidate is adopted in any skill or script.

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
status: accepted
disposition: ruled on 2026-10-30 — the limits stay merge-time, the only thing that forces triage; `status: accepted` with a disposition is the route for a problem not the author's.
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

