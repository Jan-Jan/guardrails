# Problem report — code-guidelines review gaps and a midnight flake

Recorded by change `code-guidelines` (`docs/plans/2026-10-13-code-guidelines.md`),
from its independent review, whose findings were all low, and from the
reviewer's suite run. `affects:` names files, because guardrails keeps no
REQ/SDD/LLR ledger of its own.

**PR-tqwky6**: A suite run that crosses midnight fails the `check-trace` age tests, because the fixture's `days_ago` date and `check-trace.sh`'s age are computed on different days.
affects: tests/check-trace.bats, tests/helpers.bash.
opened: 2026-10-14
status: open

Seen in the code-guidelines reviewer's run, which started on 2026-10-13 and
finished on 2026-10-14: `check-trace: an open item needs no owner:` and
`check-trace: a leftover owner: line inside an item is inert` each wrote an
item `opened:` `days_ago 2` and expected `UNRESOLVED-PR PR-001 (open 2 days)`,
and `check-trace.sh` printed `(open 3 days)`. Both passed in the reviewer's
second run and in the change's gate. Any test that compares a `days_ago` date
with an age the script computes later shares the window.

**PR-75pdcu**: No skill says what a `develop-refactor` fixer does when a Simplicity 4 (duplication) finding lands on test assertions, and removing them can leave a test whose name and `verifies:` claim it no longer checks.
affects: skills/develop-refactor/SKILL.md, templates/CODE_GUIDELINES.md.
opened: 2026-10-14
status: open

In code-guidelines, the round-3 CODE fix removed the assertions a sweep
already covered from `code guidelines: this repository's naming rules live in
its own code guidelines file` (tests/skills.bats); what was left checked
nothing about the naming rules, and `develop-refactor` says only "Never
delete, skip or loosen a test to keep the suite green". The test was given a
positive assertion back in the same change; the rule that would have
prevented it is still unwritten.

**PR-r6ypg9**: `develop-change`'s derailment rule stops the change when "review returns findings on the same task twice", which the conformance reviews' rerun-until-nothing-above-low loop meets by design.
affects: skills/develop-change/SKILL.md.
opened: 2026-10-14
status: resolved

The conformance reviews run again until a round has nothing above low, so
findings in two rounds are an expected outcome; code-guidelines' own CODE
review had findings above low in rounds 1 and 2. Read literally, the
derailment rule hands that to the user. The rule should say whether
conformance rounds count, and what bounds a conformance loop that does not
converge.

Resolved: the derailment rule counts a conformance round only through a finding that recurs after its fix was merged (D1, `docs/plans/2026-10-14-derailment-conformance.md`); test "develop-change: a conformance finding that recurs after its fix stops the loop; a new one does not" in `tests/skills.bats`.
