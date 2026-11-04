# Problem reports — an item found fixing a class B adopter's field report

`PR-z6uaa8` was found on 2026-09-15 while fixing a field report from a
downstream SvelteKit project, IEC 62304 class B, by the user asking where a
`check-trace.sh` fix gets reported.

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
status: accepted
disposition: ruled on 2026-10-30 — the install path is outside every repository and owned by other tooling; guardrails documents re-installing and does not gate it.
Measured 2026-09-15 on the machine this change was developed on:
`~/.claude/skills/<name>` symlinks to `~/.agents/skills/<name>`, which contains
real directories dated 2026-09-05 — not links into this repository. Eleven
skills compared against the change worktree: seven differ, four match. Two of
the seven (`merge-change`, `ratchet`) had already diverged from `main` before
this change, containing edits from e2eac86 and 51f01b7 that never reached the
install, so the drift is two generations deep rather than one.

AMENDED 2026-09-15, before this item was ever merged, because two of its
figures were wrong and a third was inferred rather than measured: an
unmeasured figure, in the item that records a drift nobody was measuring.

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

The user directed this amendment on 2026-09-28, while four other changes
were open. It contains no fix and claims none.

