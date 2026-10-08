# Agent-first skills, change 3: the remaining skills in the D9 shape

**Goal:** Rewrite the ten skills not yet in the D9 shape into it, each at most
2,000 words, remove both exemption lists from `tests/skills.bats`, rewrite this
repository's `AGENTS.md`, and make the low-severity stop the default review
convergence rule in `merge-change`.
**Implements:** D3 item 3, D5, D6, D9 and D10 of
`docs/plans/2026-09-28-agent-first-skills.md`, and the maintainer's ruling of
2026-10-04 recorded in `docs/plans/2026-09-29-agent-first-skills-change-2.md`,
section "Decision after review round 20: the review ends at low severity",
which amends the convergence rule `PR-3s74u3` introduced. No REQ items exist in
this repository.
**Safety class:** the toolkit is unclassified; the class B rules in `AGENTS.md`
apply. No script changes. Skill text, one template, `AGENTS.md`, one new ADR
and `tests/skills.bats` change.
**Verification:** `sh tests/run-tests.sh` — every test passes. `check-ids.sh`
and `check-trace.sh` under `scratchpad/gate/gr-config.yaml` report nothing that
a clone of `main` does not also report.

The managed block `templates/AGENTS-block.md` is not edited (D10).

Run single bats files with `tests/.bats-core/bin/bats <file>`, never with
`tests/run-tests.sh <file>`. A fresh task worktree lacks the gitignored
`tests/.bats-core`; `task-worktree.sh start` copies it.

## The target shape (D9, D5, D6)

After the frontmatter and the announce line, the `##` headings are, in order:
`Preconditions`, `Steps`, `Red flags`, `Done when`, and `References` where the
skill has reference files. `skills/merge-change/SKILL.md` is the worked example
of the shape; read it before starting.

- `SKILL.md` contains what an agent acts on in the normal path, as imperatives,
  with one clause of reason only where the reason changes what the agent does.
- Reasons, worked examples and material that applies only under a condition go
  to `skills/<name>/references/<topic>.md`. Each file opens with one sentence
  stating when to read it. The `References` section lists each file on an entry
  line of the form ``- `references/<topic>.md` — read when <condition>.``
- Incident history, review-round history and dated measurements are deleted
  (D6). The plans, ADRs and git history already contain them.
- In an interview skill, `Steps` contains the interview rules.
- Numbered steps that another file cites keep their number and their topic:
  `worktree-discipline` step 1 (where the task worktree goes) and step 4 (the
  baseline), and `ratchet` steps 0 to 5 with step 1b.
- The writing rules of `AGENTS.md` apply to every line written, including the
  replace list; `tests/skills.bats` scans for it.

## Pinned text stays in place (D4)

T1 to T10 do not edit `tests/skills.bats`. Every pattern a test in that file
asserts against a skill's `SKILL.md` must still match that file after the
rewrite, and every pattern a test asserts must not match must still not match.
Find them before editing with `grep -n 'skills/<name>' tests/skills.bats` and
read each test that names the file. A pinned phrase that is rationale only stays
in `SKILL.md` in this change; the task report lists it. If the pinned phrases
alone keep a skill over 2,000 words, the task stops and reports.

**Accepted intermediate failure.** Until T13, `tests/skills.bats` on the change
branch fails "every shape exemption names a skill still out of order" and
"every ceiling exemption names a skill still over it" for each rewritten skill.
Each of T1 to T10 is accepted when `tests/.bats-core/bin/bats tests/skills.bats`
fails those two tests only, naming only its own skill, and passes every other
test.

The two shape checks for one skill, run from the task worktree:

```sh
awk '/^```/ { fenced = !fenced; next } !fenced && /^## / { sub(/^## /, ""); printf "%s|", $0 } END { print "" }' skills/<name>/SKILL.md
wc -w < skills/<name>/SKILL.md
```

Expected: `Preconditions|Steps|Red flags|Done when|References|` (or without
`References|`), and a count of at most 2000.

---

### T1 to T10 — one skill each into the D9 shape

| Task | Skill | Words on `main` |
|---|---|---|
| T1 | `analyze-risks` | 597 |
| T2 | `check-traceability` | 2490 |
| T3 | `design-architecture` | 588 |
| T4 | `develop-change` | 2121 |
| T5 | `grill-requirements` | 1452 |
| T6 | `plan-change` | 415 |
| T7 | `ratchet` | 7759 |
| T8 | `resolve-problem` | 1188 |
| T9 | `verify-before-merge` | 1416 |
| T10 | `worktree-discipline` | 2740 |

**Files touched:** `skills/<name>/SKILL.md`, and new files in
`skills/<name>/references/`, a directory no other task touches.
**Parallel:** yes, with each other and with T11.

**verifies:** no new test. The existing tests `skill shape: every SKILL.md has
the D9 sections in order` and `skill shape: every SKILL.md is at most 2,000
words` (`verifies: D9`, `verifies: D5`) cover the shape once T13 removes the
exemptions, and `skill shape: the References section lists exactly the
reference files` (`verifies: D6, D9`) covers the reference entries now.

Steps:

1. Read `skills/merge-change/SKILL.md` and this plan's target shape.
2. List the pinned patterns: `grep -n 'skills/<name>' tests/skills.bats`, then
   each test that reads the file.
3. Rewrite. Move reasons, examples and conditional material to reference files;
   delete history. Keep every normal-path instruction: a rule dropped silently
   is a defect, so for each paragraph removed, state in the report whether it
   moved (to which file) or was deleted as history.
4. Run the two shape checks above, and `tests/.bats-core/bin/bats
   tests/skills.bats`. Expected: the accepted intermediate failure only.
5. Commit unsigned: `git -c commit.gpgsign=false commit`.

### T11 — the review ends at low severity (the 2026-10-04 ruling)

**Files touched:** `skills/merge-change/SKILL.md`,
`skills/merge-change/references/review-checklist.md`,
`skills/merge-change/references/rationale.md`, `templates/verification.md`,
`tests/skills.bats`.
**Parallel:** yes with T1 to T10; serial before T12 and T13.

The rule, as the skill states it after this task:

- Every `code` and `requirement` finding states a severity after its tag:
  `**finding-N**: code, medium — <text>`. A `record` finding states none.
- `high`: loses or silently discards work, makes a gate pass that should fail,
  or is a remedy that does damage when followed, in a state reached in normal
  use.
- `medium`: a wrong exit, message or remedy in normal use that misleads but
  loses nothing, or a stated requirement that is not met.
- `low`: needs a rare or contrived state, or the error printed alongside names
  the true cause, or a documentation gap where the tree is right.
- A round whose `code` and `requirement` findings are all `low` is the last
  review round. On it, fix each low finding whose fix is mechanical, and record
  each other one as an open problem item. The rerun from step 1 ends at 6b, as
  before.

The severity definitions go to `references/review-checklist.md` (the reviewer
reads it) and the reason to `references/rationale.md`; step 6a states the rule
and names the file. `merge-change/SKILL.md` stays at or under 2,000 words.

Tests, written first and seen to fail (`verifies: PR-3s74u3`):

*(Code pruned at merge: 14 lines. Files touched: `skills/merge-change/SKILL.md`, `skills/merge-change/references/review-checklist.md`, `skills/merge-change/references/rationale.md`, `templates/verification.md`, `tests/skills.bats`.)*

The test `merge-change: a round with no code or requirement finding is the
last` is replaced by the one above in the same commit. The test `verification
template opens every finding with its tag` gains the assertion
`grep -q '^\*\*finding-1\*\*: <code | requirement | record>, <high | medium | low>' "$template"`
in place of its first `grep`, and the template's `finding-1` line and field
grammar are updated to match. `merge-change: the reviewer tags every finding`
gains `grep -qF '`high`, `medium` or `low`' "$skill"`.

Commit unsigned.

### T12 — this repository's AGENTS.md (D10)

**Files touched:** `AGENTS.md`, `docs/adr/2026-10-04-local-main-is-the-base.md`,
`tests/skills.bats`.
**Parallel:** no (serial, after T10 and T11).

- `AGENTS.md` keeps every rule it states, as imperatives, in the order:
  non-negotiables, writing rules, rules. It loads on every session, so a reason
  stays only where it changes what an agent does.
- The argument behind non-negotiable 5 (the ID scheme, the residual collision
  risk, why it does not generalise) moves to the new ADR, in the form of the
  existing files in `docs/adr/`. Non-negotiable 5 keeps the rule, the override
  of `merge-change` step 1's fetch, the sentence the verification record
  states, and a pointer to the ADR.
- The awk, `date`, `case` and GnuPG rules keep their measured facts (the error
  text, the platforms) and lose the narrative.
- The replace list stays word for word: `clanker: the word table and the
  shipped replace list name the same words` compares it with the shipped block.
- D4: `AGENTS.md: non-negotiable 1 nests the task worktree and names its path`
  and `merge-change: a fix dispatch's tag is unique, and AGENTS.md defers on
  tags` keep passing; where the rewrite changes a pinned phrase, the test is
  updated in the same commit to the new wording, with the same `verifies:`
  line.

Test, written first and seen to fail (`verifies: D10`):

*(Code pruned at merge: 10 lines. Files touched: `AGENTS.md`, `docs/adr/2026-10-04-local-main-is-the-base.md`, `tests/skills.bats`.)*

Commit unsigned.

### T13 — no skill is exempt from the shape

**Files touched:** `tests/skills.bats`.
**Parallel:** no (serial, after T1 to T12).

D5: change 3 leaves the exemption lists empty. With no skill exempt, the lists
and the two tests that check them for stale names are deleted:
`gr_shape_exempt_skills`, `gr_ceiling_exempt_skills`, "every shape exemption
names a skill still out of order" and "every ceiling exemption names a skill
still over it". The two shape tests lose their `case` skip and the comment
naming exempt skills. Expected after the edit: `tests/skills.bats` passes in
full, with two tests fewer than before.

Commit unsigned.

### Deslop and merge

`develop-change`'s deslop pass runs once over the whole diff after T13, then
`merge-change`.

## Dispatch log

Each of T1 to T10 reports `red -> green: none: no new test (plan T1 to T10)`.

- T2 done (2b0831a): `check-traceability` 987 words; references `config.md`, `item-blocks.md`.
- T4 done (ea2745d): `develop-change` 1595 words; references `rationale.md`, `mutation-anchors.md`. Step 6 no longer claims nothing in the suite catches a dead anchor (`tests/mutations.bats` does).
- T10 done (eb1237d): `worktree-discipline` 1954 words; references `rationale.md`, `harness-pin-test.md`. The dated measurement table is deleted (D6).
- T11 done (a55a62c): step 6a ends the review on a round whose `code` and `requirement` findings are all `low`; severities defined in `references/review-checklist.md`, which step 6a now hands over every round. `merge-change` 1999 words. red -> green: "merge-change: a round with nothing above low severity is the last", "merge-change: the reviewer tags every finding", "verification template opens every finding with its tag" — each watched fail before the edit.
- T9 done (148874e): `verify-before-merge` 1238 words; reference `rationale.md`. Checks 1 to 8 keep their numbers.
- T1 done (ff773c2): `analyze-risks` 796 words (597 before; the Red flags and Done when sections are new); no reference file.
- T8 done (2bdc27f): `resolve-problem` 1053 words; reference `rationale.md`. Sections 1 to 4 keep their numbers, which `ratchet` and `check-trace.sh` cite as §4.
- T5 done (b7f508a): `grill-requirements` 1406 words; references `supersession.md`, `rationale.md`. The multi-unit dependency subsection stays in `SKILL.md` because tests pin it.
- T7 done (5538cf0): `ratchet` 1935 words (7759 before); references `upgrade-notes.md`, `rationale.md`, `setup-checklist.md`, `multi-unit.md`. Upgrade mode is the unnumbered subsection "Upgrading the scripts in an existing project", so steps 0 to 5 and 1b keep their numbers.
- T3 done (356ac50): `design-architecture` 753 words (588 before; the Red flags section is new); no reference file. Steps renumbered 1 to 7; nothing cites them.
- T6 done (1fdd950): `plan-change` 518 words (415 before; Red flags and Done when are new); no reference file.
- T12 done (ef1cfb6): `AGENTS.md` rewritten; the argument behind non-negotiable 5 is in `docs/adr/2026-10-04-local-main-is-the-base.md`; the dated GnuPG measurement is deleted (it is in `docs/plans/2026-09-01-verifier-reason.md`). red -> green: "AGENTS.md: non-negotiable 5 states the rule and points to its ADR" — watched fail at the ADR-pointer grep before the rewrite.
- T13 done (ad58c70): both exemption lists and their two staleness tests deleted. red -> green: "skill shape: every SKILL.md has the D9 sections in order" — fails naming analyze-risks with a renamed `## Red flags` heading, which the exemption had skipped; "skill shape: every SKILL.md is at most 2,000 words" — fails naming ratchet padded to 2035 words. Both reverted.
- Deslop pass done (f4e5c62, 01b847e): every item below fixed; cross-skill citations checked by grep; one dispatch-mechanism phrase across skills; three Red flags or Done when rows that had no rule in Steps now have one (verify-before-merge check 8, worktree-discipline recovery, resolve-problem open count). Left for the maintainer: `grill-requirements` ships the ADR name form `docs/adr/NNNN-slug.md`, unchanged from `main`, which differs from this repository's dated ADR names.

For the deslop pass: `skills/develop-change/references/rationale.md` cites `worktree-discipline`, "The artifacts are the memory", which is now step 9 of that skill, not a section; cite step 9.

For the deslop pass: T5 reworded `when all three hold`, the one use of the writing-scan exemption of that phrase in `tests/skills.bats`. The exemption now matches nothing in scope; delete it and its comment, and set the pinned exemption count from 7 to 6.

For the deslop pass: `ratchet` keeps rationale-only and metaphorical phrases because tests pin them: "Both worktree entries earn their place", "a tooth ordering, not a package", the "D9 (docs/plans/2026-08-26-monorepo-support.md)" plan label, and "prose carriers". Reword each, or move it to `references/rationale.md`, and update its test to the new wording and file with the same `verifies:` line (D4). `scripts/lib.sh` line 382 names the sizing grep as "the pattern skills/ratchet hands adopters"; it is now in `skills/ratchet/references/upgrade-notes.md`.

For the deslop pass: `tests/helpers.bash` line 18 quotes AGENTS.md as calling "a stock box" its default awk; AGENTS.md now states "the default `/usr/bin/awk` on stock macOS".

For the deslop pass: `skills/ratchet/references/upgrade-notes.md` line 137 uses the replaced word "ran" ("never ran"), which fails "clanker: no file in scope contains the replaced vocabulary". Fix it first.
