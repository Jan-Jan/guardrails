# Problem report — an adopter's guidelines-tailoring field report

Reported by an adopter on 2026-10-14, from an upgrade of a class B SvelteKit
PWA from `d015a48` to `344faa3` and the tailoring of its three guidelines
files. `affects:` names files, because guardrails keeps no REQ/SDD/LLR ledger
of its own.

The report's third point, that `ratchet` step 0 finds no checkout above a
copied skill, is PR-783b29, resolved by `52100a8` after the adopter's
`344faa3`; what it leaves, a stale `.guardrails-source` and the fallback two
levels up, is PR-92mbhq, still open. Its note that a refresh of copied skills
missed the four new ones, and that nothing reports a skill naming one that is
not installed, is read here as installed-copy drift, PR-z6uaa8, taking its
drift to cover which skills are installed as well as their content. Neither is
recorded again here.

**PR-kqesz5**: `templates/TEST_GUIDELINES.md` UI 6, "A markup snapshot carries no `verifies:` annotation", contradicts the floor item "every test carries `verifies:`" that `tailor-guidelines` step 5 and `review-conformance` step 3 list, so `review-conformance` reports the shipped default as a finding against itself.
affects: templates/TEST_GUIDELINES.md (UI 6); skills/tailor-guidelines/SKILL.md (step 5); skills/review-conformance/SKILL.md (step 3); no test runs the floor against the shipped templates.
opened: 2026-10-15
status: resolved
Resolved: UI 6 described a test without `verifies:`, the one shape the floor forbids; it now forbids a markup snapshot test (`templates/TEST_GUIDELINES.md` UI 6), and "guidelines: no guidelines file exempts a test from verifies: or from being watched red" in `tests/test-guidelines.bats` scans every shipped and repository guidelines file for that exemption; the clause is pinned by "test guidelines: a UI's interface is what the user perceives, and a markup snapshot verifies nothing".

The clause came in with test-seams (`docs/plans/2026-10-07-test-seams.md`,
decision point 3), to keep a snapshot from posing as evidence; it did so by
describing a test without the annotation, the one shape the floor forbids.
The adopter's review raised it at medium.

**PR-9n87ec**: `templates/TEST_GUIDELINES.md` Existing suites 1 binds "the tests a change writes or edits" without saying what edits a test, so a reviewer reads a comment-only edit as editing the test and requires its doubles replaced, and its remedy, "moves it to the seam", fits only a Seams breach, not a Doubles one.
affects: templates/TEST_GUIDELINES.md (Existing suites 1); docs/TEST_GUIDELINES.md (Existing suites 1, the same clause); templates/ARCHITECTURE_GUIDELINES.md and docs/ARCHITECTURE_GUIDELINES.md (Existing code 1, "where a change edits it").
opened: 2026-10-15
status: resolved
Resolved: the existing-code clauses never said what edits a test or code; Existing suites 1 (both TEST files) now binds the tests whose setup, doubles, calls or assertions a change edits, says a comment or citation fix edits none, keeps the floor on every test and names a remedy per breach, and Existing code 1 (both ARCHITECTURE files) says the same of code. Reproduced by "test guidelines: the rules bind new tests and tests whose code a change edits, and the floor binds every test" in `tests/test-guidelines.bats` and "architecture guidelines: correcting a comment or a citation does not edit code" in `tests/architecture-guidelines.bats`.

The adopter's change repointed a stale citation in the comment above an
existing mock in three test files; its review rounds required the mocks
replaced, at medium. The adopter's owner ruled that a test is edited when its
code changes, not its comments. A reviewer also read "they spare the existing
suite" as sparing the floor items the file restates. The report names
`templates/CODE_GUIDELINES.md` too; it has no existing-code clause.

One item the independent review of this change raised at low severity,
recorded and not fixed, because its fix is a new rule.

**PR-pk3xy5**: Existing suites 1 says correcting a citation alone does not edit a test, which also covers repointing a test's `# verifies:` comment to a successor ID, so a test inherited as evidence for a new item escapes the Seams and Doubles clauses.
affects: templates/TEST_GUIDELINES.md (Existing suites 1); docs/TEST_GUIDELINES.md (Existing suites 1).
opened: 2026-10-15
status: open

The review checklist reviews an inherited test as an edited test, but applies
only the floor to it. A sentence such as "a change to a test's `verifies:`
edits it" would close it; the template is at its word cap, so the sentence
needs a cut elsewhere and its own review.
