# Verification — architecture-guidelines (2026-10-14)

branch: architecture-guidelines
reviewer: one independent subagent, dispatched at `merge-change` step 6a with
the diff, the plan and the review checklist, and no implementation narrative;
it worked in its own review worktree and ran the full suite itself.
verdict: approve. Its `code` findings were all low, so round 1 was the last
review round; each was fixed, and its two `record` findings are answered
in the plan and under Gaps.
reproduced: not applicable — the change adds a capability, not a defect fix.
The absence was measured before it was built: at `main` (`6a9d6eb`)
`guidelines-file.sh ARCHITECTURE` exits 2 naming the known kinds `TEST CODE`,
`templates/` holds no architecture guidelines, and each new test was watched
fail on that absence.

Change: architecture preferences live in one project file,
`ARCHITECTURE_GUIDELINES.md`, which `design-architecture` reads and a third
conformance review checks; a constraint a tool can decide is an LLR with a
test.
Plan: `docs/plans/2026-10-14-architecture-guidelines.md`.

## The gate

The figures are in the squash commit's trailers (`Gate-tree:`, `Gate:`,
`Base:`). This repository has no `.guardrails/config.yaml`, so
`merge-preflight.sh` stops at its config read; `check-ids.sh` and
`check-trace.sh` were run instead on scratch copies of `main` and of the
change, each built from `templates/config.yaml` with `scripts` as its strict
path. `check-ids.sh` printed the same output at both; `check-trace.sh` printed
the same output at both and exited 1 at both, on the problem backlog this
repository carries. The change adds no ID, item or trace finding. Coverage is
not configured.

## Red → green

This repository has no SRS, so the change implements no item and the table
has no rows. Each test the change adds or edits carries
`verifies: D<n> (docs/plans/2026-10-14-architecture-guidelines.md)`; its
`red -> green:` lines are copied here from the plan.

| Item | Test | Watched red |
| --- | --- | --- |

- red -> green: develop-refactor: the skill is named, and fixes one CODE or ARCHITECTURE review's findings — watched fail on the missing description pin
- red -> green: develop-refactor: a finding that needs a design change comes back not fixed — watched fail on the missing step 4 reason
- red -> green: develop-refactor: the floor names the architecture items — watched fail ("the floor lacks: every SDD item traces to a REQ")
- red -> green: guidelines-file: an unknown kind is exit 2, naming the known kinds — watched fail on the known-kinds list ("(known: TEST CODE)")
- red -> green: guidelines-file: ARCHITECTURE picks the unit's, the root's or the installed default file, as TEST does — watched fail with "unknown kind: ARCHITECTURE"
- red -> green: guidelines-file: a missing ARCHITECTURE default is exit 2 though the TEST default is installed — watched fail ("unknown kind" instead of "no installed default")
- red -> green: architecture guidelines: the template's clauses, by heading and number — watched fail ("no templates/ARCHITECTURE_GUIDELINES.md")
- red -> green: architecture guidelines: the template has the five headings, in order — watched fail (template absent)
- red -> green: architecture guidelines: every clause states a reason and an example — watched fail (template absent)
- red -> green: architecture guidelines: the boundaries D4 names are stated — watched fail (template absent)
- red -> green: architecture guidelines: a rule a tool can decide is an LLR with a test — watched fail (template absent)
- red -> green: architecture guidelines: the preface states the one-file rule and the floor rule — watched fail (template absent)
- red -> green: architecture guidelines: the template stands alone, naming no guardrails document or skill — watched fail (template absent)
- red -> green: architecture guidelines: the template is at most 1,300 words — watched fail (template absent)
- red -> green: review-conformance: the floor is listed in full — watched fail (`grep -qF 'every SDD item traces to a REQ'`)
- red -> green: review-conformance: the old name is gone, and the description names every kind — watched fail (the docs/ARCHITECTURE_GUIDELINES.md description pin)
- red -> green: upgrade notes: architecture guidelines are a project file — watched fail ("no Architecture guidelines section")
- red -> green: tailor-guidelines: a change that contradicts the floor is rejected, and the floor is listed — watched fail on 'every SDD item traces to a REQ'
- red -> green: ratchet: the scaffold installs every guidelines default and tailors TEST, CODE and ARCHITECTURE — watched fail on the new Run `tailor-guidelines` pin
- red -> green: tailor-guidelines: the kinds are TEST, CODE and ARCHITECTURE, and CODE's and ARCHITECTURE's examples are the project's — watched fail on the Preconditions kinds pin
- red -> green: develop-change: the conformance reviews run for ARCHITECTURE too — watched fail ("no ARCHITECTURE guidelines-file line")
- red -> green: develop-change: an architecture finding that needs a design change is a stop — watched fail ("no architecture-finding stop")
- red -> green: design-architecture: reads the architecture guidelines file, and a departure names its clause — watched fail ("step 1 does not read the architecture guidelines file")
- red -> green: design-architecture: one responsibility per item lives in the guidelines template — watched fail on the first half only (step 2 still stated it); the template half was green from T1
- red -> green: merge-change: the review checklist asks for the ARCHITECTURE reviews — watched fail
- red -> green: verification template: guideline reviews name the ARCHITECTURE kind — watched fail
- red -> green: README: tailor-guidelines names the architecture guidelines file — watched fail
- red -> green: architecture guidelines: this repository's file stands alone, naming no guardrails document or skill — watched fail ("no docs/ARCHITECTURE_GUIDELINES.md")
- red -> green: architecture guidelines: every clause of this repository's file states a reason and an example — watched fail ("no docs/ARCHITECTURE_GUIDELINES.md")
- red -> green: architecture guidelines: this repository's file is at most 1,500 words — watched fail ("no docs/ARCHITECTURE_GUIDELINES.md")
- red -> green: architecture guidelines: the boundary's test fake is the interface's second implementation — watched fail ("Core and edges lacks the test fake as second implementation")

- red -> green: upgrade notes: architecture guidelines are a project file (D3 pin) — watched fail ("no D3 routing of architecture findings") with the sentence removed
- red -> green: architecture guidelines: every clause of this repository's file states a reason and an example (non-empty clause list) — watched fail ("docs/ARCHITECTURE_GUIDELINES.md has no clauses") on a copy cut to its preface
- red -> green: develop-change: an architecture finding that needs a design change is a stop (renamed Derailment heading) — watched fail (no derailment section) before the heading was renamed
- red -> green: design-architecture: an architecture finding stands in for the requirements, not for reading the config — watched fail on the old Preconditions
- red -> green: architecture guidelines: the boundaries D4 names are stated (environment variable in Core and edges 2) — watched fail ("Core and edges 2 omits an access")
- red -> green: architecture guidelines: a rule a tool can decide is an LLR with a test (language-neutral example) — watched fail ("the example is not language-neutral")

The T1 template tests were each watched red on the template's absence, not on
one missing sentence of an existing file. The T6 test "design-architecture:
one responsibility per item lives in the guidelines template" was watched red
on its first half only; its template half was green from T1.

## What was wrong, and what was built

The guidelines series (test, then code guidelines) left architecture as
fixed text in `design-architecture` and planned "per-unit constraints in
`units.yaml`" for it. Neither a project file nor a review of structure
existed: `guidelines-file.sh` knew `TEST` and `CODE` only.

Built, by the plan's decisions:

- D1: a structural constraint a tool can decide is an LLR on its software
  item, verified by an architecture test the project writes with its own
  tooling. No config key and no new script; this replaces the planned
  `units.yaml` constraints.
- D2, D4, D8: `templates/ARCHITECTURE_GUIDELINES.md` ships Domain, Core and
  edges, Boundaries, Constraints and Existing code clauses, each with a reason
  and an example. The boundary's test fake counts as an interface's second
  implementation, so the template agrees with the code template's
  second-caller rule. `guidelines-file.sh` knows `ARCHITECTURE`;
  `design-architecture` reads the file and names any clause a proposal departs
  from; "one responsibility per item" moved from its step 2 into the
  template. `develop-change` runs a third conformance review.
- D3: `develop-refactor` fixes an architecture finding that needs no design
  change; one that needs an SDD or LLR item changed comes back not fixed, and
  `develop-change` sends it to `design-architecture`, a stop for the user.
- D6: the floor lists in `review-conformance`, `tailor-guidelines` and
  `develop-refactor` name five architecture items.
- D5, D7: `tailor-guidelines` and `ratchet` know the kind; the upgrade notes
  have a section for it; this repository tailored its own
  `docs/ARCHITECTURE_GUIDELINES.md` with the user (the plan's T7 Done note
  lists each clause kept, rewritten or dropped, and why).

`merge-change` step 1 kept `docs/plans/2026-10-14-architecture-guidelines.md`
whole (`left whole`): the plan cites its own line in a conformance finding.

## Review

The reviewer ran the full suite in its own worktree and reported 1..1449,
1449 passed, 0 failed. Its `code` findings were all low, so round 1 was the
last review round.

### Round 1

**finding-1**: code, low — `tests/tailor-guidelines.bats`, "upgrade notes: architecture guidelines are a project file", is annotated D1, D3, D7, but no pin covers D3; deleting the D3 sentence from the upgrade notes left it green.
disposition: the test pins the sentence "`develop-refactor` fixes the findings that need no design change; the rest go to `design-architecture`." (`upgrade notes: architecture guidelines are a project file`), watched red with the sentence removed.

**finding-2**: code, low — `tests/architecture-guidelines.bats`: the three D5 tests pass on a `docs/ARCHITECTURE_GUIDELINES.md` with no clauses.
disposition: `architecture guidelines: every clause of this repository's file states a reason and an example` requires a non-empty clause list, watched red on a copy cut to its preface.

**finding-3**: code, low — `skills/develop-change/SKILL.md:84`: the heading "Derailment: the one stop this skill adds" contradicts its list, which now has a stop develop-change itself routes.
disposition: the heading is "### Derailment and the other stops" (skills/develop-change/SKILL.md), and the two `section_of` calls in tests/skills.bats read it.

**finding-4**: code, low — `skills/design-architecture/SKILL.md:18-19`: the "Or `develop-change` sent you an architecture finding" bullet reads as an alternative to reading the config.
disposition: folded into the requirements bullet (skills/design-architecture/SKILL.md), pinned by `design-architecture: an architecture finding stands in for the requirements, not for reading the config`.

**finding-5**: code, low — `templates/ARCHITECTURE_GUIDELINES.md`: Core and edges 2 omits "environment variable", which Core and edges 1 keeps out of the core; Constraints 1's "an import-linter contract" is one package's vocabulary.
disposition: Core and edges 2 lists the environment variable, and the example reads "verified by an import linter's rule run in the test suite" (templates/ARCHITECTURE_GUIDELINES.md), pinned in `architecture guidelines: the boundaries D4 names are stated` and `architecture guidelines: a rule a tool can decide is an LLR with a test`.

**finding-6**: record — the plan's D6, marked "Ruled 2026-10-14", was rewritten to state the develop-refactor exception without saying who ruled the amendment.
disposition: D6 states that the dispatching agent wrote the exception as a disposition, to match the tree, and that it was not put to the user (docs/plans/2026-10-14-architecture-guidelines.md); this record lists it under Gaps, `docs/verification/2026-10-14-architecture-guidelines.md`.

**finding-7**: record — `fix-code-2` was merged after the last conformance round, and no conformance review saw it.
disposition: stated under Gaps in `docs/verification/2026-10-14-architecture-guidelines.md`; the independent review (this round) read the tree with it merged.

## Guideline reviews

Each file governs every path of the diff (`guidelines-file.sh` printed the
same path list for all three).

### docs/TEST_GUIDELINES.md

Governs: every path of the change diff.

### Round 1

No findings; verdict "0 findings (0 high, 0 medium, 0 low); none above low".

### Round 2

No findings; verdict "0 findings (0 high, 0 medium, 0 low); none above low".

### docs/CODE_GUIDELINES.md

Governs: every path of the change diff.

### Round 1

**finding-1**: guideline, medium — Names 3, "Name in concrete terms … no `data`, `info`, `item`, `value`, `result`, `manager`, `handle` or `process` alone" — tests/develop-refactor.bats:72
disposition: the loop variable is `floor_rule`, then replaced by the shared helper `states_architecture_floor` in tests/helpers.bash (round 2, finding-1).

**finding-2**: guideline, low — Simplicity 2 and Simplicity 4, "two copies of one rule drift" — tests/architecture-guidelines.bats:11 — `clauses_missing_reason_or_example` copied the inline awk of tests/code-guidelines.bats.
disposition: one copy, in tests/helpers.bash, called by tests/architecture-guidelines.bats and tests/code-guidelines.bats.

### Round 2

**finding-1**: guideline, low — Simplicity 4, "No duplication between tasks" — tests/review-conformance.bats:31-36, tests/tailor-guidelines.bats:45-50, tests/develop-refactor.bats:72-77 — the same five architecture-floor checks inline in three files.
disposition: one helper, `states_architecture_floor` in tests/helpers.bash, called by the three tests.

### docs/ARCHITECTURE_GUIDELINES.md

Governs: every path of the change diff.

### Round 1

**finding-1**: guideline, medium — Domain 2, "One term, one meaning, across the repository" — templates/ARCHITECTURE_GUIDELINES.md:102, skills/ratchet/references/upgrade-notes.md:662 — "this unit performs no I/O" uses "unit" for a software item.
disposition: both read "this item performs no I/O" (templates/ARCHITECTURE_GUIDELINES.md).

**finding-2**: guideline, low — Domain 2, "Where a second meaning is needed, it gets its own word." — templates/ARCHITECTURE_GUIDELINES.md, Boundaries 1 and 3 — a bare "item" means a software item there.
disposition: no change — each clause says "software item" at its first use, and the clause headings are pinned by `architecture guidelines: the template's clauses, by heading and number`.

**finding-3**: guideline, low — Boundaries 1, "stated in one sentence without 'and' in ... the skill's description", with Existing code 1 — skills/tailor-guidelines/SKILL.md:3
disposition: the description opens with one job, "Make one guidelines file … the project's own." (skills/tailor-guidelines/SKILL.md).

**finding-4**: guideline, low — a clause refers to a document the project does not contain — docs/ARCHITECTURE_GUIDELINES.md:26-27 — `.guardrails/units.yaml`.
disposition: the example names a units manifest in the form `templates/units.yaml` ships (docs/ARCHITECTURE_GUIDELINES.md).

### Round 2

**finding-1**: guideline, low — Domain 2 — docs/plans/2026-10-14-architecture-guidelines.md:384, :605 — the plan's copies of the text read "this unit performs no I/O".
disposition: both copies read "this item" (docs/plans/2026-10-14-architecture-guidelines.md).

**finding-2**: guideline, low — Constraints 1 — docs/ARCHITECTURE_GUIDELINES.md:32-34 — the "without 'and'" part of Boundaries 1 is scan-checkable, and no test checks it.
disposition: no change — whether a script or skill has one job is judgment, and "without 'and'" is the writing aid for it; a scan would fail existing descriptions the Existing code clause spares. Listed under Gaps.

**finding-3**: guideline, low — Constraints 1 — skills/develop-refactor/SKILL.md:36-44 — D6's "one list, in one form" does not hold for develop-refactor's floor sentence, and nothing checks the form.
disposition: D6's text states the develop-refactor exception, which predates this change (docs/plans/2026-10-14-architecture-guidelines.md); `states_architecture_floor` in tests/helpers.bash checks the five architecture items alike in all three skills.

## Gaps

- No script enforces the architecture guidelines in an adopting project; a
  constraint is enforced only where the project writes the LLR and its test
  (D1), and the rest by the conformance review.
- The `check-review.sh` gate that requires `## Guideline reviews` (the
  test-guidelines follow-up) is still not built.
- The repository's own Boundaries clause "one job per script and per skill"
  states a writing aid ("without 'and'") that no test checks; existing
  descriptions break it and are spared by the Existing code clause
  (ARCHITECTURE round 2, finding-2).
- `develop-refactor`'s floor sentence omits "every new test was watched red"
  and the double-call clause, as it did before this change (D6).
- D6's exception for `develop-refactor` was written by the dispatching agent
  as a conformance disposition, not ruled by the user (review finding-6).
- `fix-code-2` (`states_architecture_floor`) was merged after the last
  conformance round; no conformance review re-read it, only the independent
  review (review finding-7).
