# Proposal: skills written for agents

**Status:** confirmed by the maintainer, 2026-09-28. Travels on branch `agent-first-skills` with change 1 and merges in its signed squash.
**Scope:** steps 1 to 3 of the 2026-09-28 skills assessment. Step 1 moves
mechanical procedure out of skill prose into scripts, whose error output
states the remedy. Step 2 splits each skill into a short rule file and
reference files that are read only when needed. Step 3 states each rule as an
imperative, with one line of reason where the reason changes behaviour.
Structured ledger items (assessment step 4) and skill evals (step 5) are out of
scope.

## Boundaries with other open work

- **`audit-inert-assertions`.** No shared files. That change edits eleven
  `tests/*.bats` files other than `tests/skills.bats`, and one problem ledger
  file. This change edits neither. New `.bats` files written here follow the
  guard rule that change adds to `tests/portability.bats`.
- **`churn-proposal` (unmerged, parked).** See D1.

## Decisions

**D1 — this change absorbs churn-proposal D1; churn-proposal keeps D2 to D4.**
The normative rules `README.md` states move once, into the slim skills or their
reference files, and `README.md` becomes orientation-only in this change.
Plan pruning (churn D2), `check-review.sh --cite` (churn D3) and the
design-controls section with the kill line (churn D4) stay with the churn
proposal and are written into the new structure after this change merges. The
churn proposal records this split when it next merges.

**D2 — implementation runs in parallel with `audit-inert-assertions`.** This
overrides AGENTS.md non-negotiable 4 for this change only, by the maintainer's
decision of 2026-09-28. The ground is that the two file sets do not intersect.
The residual cost is that `main` moves under this change when that one merges,
which `merge-change` step 1 absorbs.

**D3 — four changes, each reaching its signed squash before the next opens.**

1. *Shape.* The target skill shape, the tests that enforce it, and its first
   application, to `merge-change`. This change applies steps 2 and 3 only:
   the procedure that step 1 will script stays in the skill's prose until the
   script exists.
2. *Scripts.* The scripts that take over mechanical procedure, with remedies in
   their output. The prose they replace is removed from `merge-change` and the
   other skills in the same change.
3. *Skills.* The shape applied to the remaining ten skills.
4. *README.* `README.md` cut to orientation-only (D1).

A single diff over all eleven skills gives a reviewer the most to reject. The
pilot tests the shape on the largest procedural skill before it is applied
to the others.

**D4 — skill-text tests are treated rule by rule.** Every problem report a
`tests/skills.bats` test verifies keeps a verifying test at every commit.

- A rule the agent acts on in the normal path stays in `SKILL.md`. Its test is
  updated to the new wording there.
- A phrase that is rationale only may move to a reference file, and its test
  moves with it.
- A rule a script takes over (D3 change 2) gets a behaviour test in that
  script's `.bats` file, with the same `verifies:` line. The grep test is
  retired in the same commit, not before.

**D5 — a SKILL.md is at most 2,000 words, and a test enforces it.** The test
lives in `tests/skills.bats` and counts with `wc -w`. Skills over the ceiling
when change 1 is merged are exempt by name: `merge-change` until change 2, and
`ratchet`, `check-traceability`, `worktree-discipline` and `develop-change`
until the change that rewrites each. Each change removes the exemptions it
earns, and change 3 leaves the list empty. A ceiling nobody checks is how the
skills reached their current size.

**D6 — removed text is sorted by whether an agent can act on it.**

- Reasons for a rule, worked examples and `ratchet`'s upgrade notes move to
  reference files in the skill's own directory. The `SKILL.md` names each
  reference file at the step where it applies. `install.sh` copies or links
  whole skill directories, so these ship with no installer change.
- Incident history and one-off measurements leave the shipped skills. Examples
  are the review-round history in `check-traceability` and the dated harness
  table in `worktree-discipline`. The toolkit's plans, ADRs and git history
  already contain them.

**D7 — change 2 scripts three procedures.**

1. *Task-worktree lifecycle.* One script creates a nested task worktree at
   `.worktrees/<change-branch>-<tag>`, checks that `.worktrees/` is gitignored,
   and copies the ignored artifacts the verify commands need. It later merges
   the task branch unsigned, then removes the worktree and deletes the branch.
2. *Remedy lines.* `check-trace.sh` and `check-ids.sh` print the fix for each
   violation they report. The fix table in `check-traceability` becomes a
   pointer to that output.
3. *Merge pre-flight.* One command runs `merge-change`'s mechanical checks and
   stops at the first failure with its remedy. The checks are the base merge,
   IDs, trace, units, the review artefact, and no worktree registered inside
   the change worktree.

The verification gate and the independent review stay in `merge-change`,
because a script cannot dispatch a subagent.

*Constraint.* Change 2 adds tests to `tests/check-trace.bats` and
`tests/check-ids.bats`, which `audit-inert-assertions` also edits. D2's ground,
that the file sets do not intersect, is true for change 1 only. Change 2 opens
after `audit-inert-assertions` reaches its signed squash.

**D8 — remedies print once per rule, after the violations.** Violation lines
keep their documented form, one line each. After them, and before the
`checked:` and `sources:` lines, the script prints one line per distinct rule
that fired, in the form `fix <RULE>: <remedy>`. Anything that greps or counts
violation lines keeps working.

**D9 — every SKILL.md has one section order, and a test checks it.** After the
frontmatter and the announce line, the `##` headings are, in order:
`Preconditions`, `Steps`, `Red flags`, `Done when`, `References`.
`References` is omitted when the skill has no reference file; each entry names
the file and the condition for reading it. In an interview skill, `Steps`
contains the interview rules. Material that applies only under a condition goes
to a reference file named with that condition. An example is the multi-unit
section of `merge-change`, read only when `.guardrails/units.yaml` exists.

**D10 — change 3 rewrites this repository's `AGENTS.md`; the shipped managed
block is unchanged.** `AGENTS.md` loads on every session here, so it has the
highest cost per word. The argument behind non-negotiable 5 moves to an ADR,
and the rule stays in `AGENTS.md` as imperatives. D4 applies to the
`tests/skills.bats` test that pins non-negotiable 1. `templates/AGENTS-block.md`
is already short, and the writing-rule tests are tuned against it.

## Acceptance, and its limit

Each of the four changes is accepted on the full suite, a verifying test for
every problem report (D4), and independent review under `merge-change`.

None of these measures agent behaviour. The suite proves that rules are
present in the text, not that an agent follows them better or worse after the
rewrite. Skill evals were step 5 of the assessment and are out of scope here.
Until they exist, a regression in agent behaviour shows up only in use.
