# Problem reports — four items from a class B adopter's field report, and three found fixing them

`PR-h3wujj` arrived on 2026-09-10 in a field report from a downstream
SvelteKit project, IEC 62304 class B, measured between 2026-09-04 and
2026-09-09 against its vendored copy of `5bc6495`. It is conceded in the
comments of the library it affects, which is the point the report's
measurements make about a stated weakness. `PR-z6uaa8` was found while fixing
that report's other points, by the user asking where a `check-trace.sh` fix
gets reported.

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
both watched failing against the rejected widening. The other tests beside
them are scope controls rather than evidence. `check-trace: a bullet status:
is not read as the problem status` was
inverted from the rejected design and now pins the loud rejection.

A mutation of the whole `gr_value` body is killed by 1 test after this edit,
the same count as before it.

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
which is exactly the defect `finish-merge.sh --check` exists to close. A skill that states one
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

AMENDED 2026-09-28, after the user re-installed the skills and asked whether
that resolved this item. **It did not, and the measurement is how the answer
was reached rather than a judgement about it.**

**The drift is gone.** All eleven skills now match, compared by SHA-256 of each
`SKILL.md` against `~/.claude/skills/<name>/SKILL.md` at `main` = `47a8b1d`:
`analyze-risks`, `check-traceability`, `design-architecture`, `develop-change`,
`grill-requirements`, `merge-change`, `plan-change`, `ratchet`,
`resolve-problem`, `verify-before-merge`, `worktree-discipline` — eleven
compared, eleven identical, none absent. The seven this item recorded as
diverged are among them. That is a real repair and the instance this item
opened on is closed.

**The defect is not, because its second half was never about the seven.** The
symptom sentence ends "and no gate, script or document reports the drift", and
that clause is unchanged: `grep` for a drift or divergence check across
`install.sh` and every `tests/*.bats` returns nothing that compares an
installed skill to its source. The eleven match today because they were copied
today, and nothing will report it when they stop matching.

**They will stop, and the shape on disk is why.** `~/.claude/skills/<name>` is
a symlink to `../../.agents/skills/<name>`, and that target is a REAL
DIRECTORY — a copy, not a link into this repository — with an mtime of
2026-09-28 15:57 on every guardrails skill. A copy is a snapshot: the next
change that edits a skill puts the repository one generation ahead again, with
no signal.

**The mechanism question this item raised is now partly answered.** `install.sh`
has exactly two modes, and the layout is neither. Its default is
`ln -s <repo>/skills/<name> "$dest/<name>"` — a symlink INTO the repository,
which makes drift structurally impossible, and whose header states that reason:
"Symlinks by default so `git pull` updates them". Its `--copy` mode is
`cp -R "${skill%/}" "$target"`, a real directory at `$dest/<name>`. What exists
is a real directory at `~/.agents/skills/<name>` with a symlink to it from
`~/.claude/skills/<name>` — consistent with `--copy` under
`CLAUDE_SKILLS_DIR=~/.agents/skills` PLUS a second party that links the default
path at the store, and not producible by either mode alone.

**That second party is now visible, which the 2026-09-15 measurement could only
infer.** The store contains four skills this repository has never shipped —
`eli5`, `find-skills`, `solidity`, `solidity-security` — and on the same day a
`~/.claude/skills/synced/` directory appeared, containing a manifest and a
bundle (`docs`, `docx`, `pdf`, `pptx`, `xlsx`, `morning`, `skill-creator`,
`import-memory`) that is plainly not ours. **The install path is owned by
tooling outside this repository**, which settles the third of the four open
questions above in the direction the scope note already suspected: `--copy` is
not the thing to remove, because removing it would not give guardrails control
of a path it does not own.

**So the remaining work is narrower and better defined than when this was
written.** Not "make the install stay in step" — guardrails cannot, on this
evidence. A check that REPORTS divergence between `skills/` and whatever is
installed, and a decision about where such a check can run given that the
install path is outside every repository. Detecting a drift you cannot prevent
is this toolkit's own idiom: it is what `UNRESOLVED-PR`, `DANGLING-REF` and
the mutation gate all do. The first of the four questions is answered enough to
act on; the second and fourth are untouched, and the third is answered no.

This amendment was written in a change opened while `close-crcee5`,
`churn-proposal`, `field-report-two` and `parallel-session-proposals` were all
open, against AGENTS.md non-negotiable 4, on the user's instruction of
2026-09-28. It contains no fix and claims none.

