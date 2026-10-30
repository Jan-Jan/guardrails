# Problem report — an adopter's guidelines-tailoring field report

Reported by an adopter on 2026-10-14, from an upgrade of a class B SvelteKit
PWA from `d015a48` to `344faa3` and the tailoring of its three guidelines
files. `affects:` names files.

The report's third point, that `ratchet` step 0 finds no checkout above a
copied skill, was fixed by `52100a8` after the adopter's
`344faa3`; what it leaves, a stale `.guardrails-source` and the fallback two
levels up, is PR-92mbhq, still open. Its note that a refresh of copied skills
missed the four new ones, and that nothing reports a skill naming one that is
not installed, is read here as installed-copy drift, PR-z6uaa8, taking its
drift to cover which skills are installed as well as their content. Neither is
recorded again here.

**PR-pk3xy5**: Existing suites 1 says correcting a citation alone does not edit a test, which also covers repointing a test's `# verifies:` comment to a successor ID, so a test inherited as evidence for a new item escapes the Seams and Doubles clauses.
affects: templates/TEST_GUIDELINES.md (Existing suites 1); docs/TEST_GUIDELINES.md (Existing suites 1).
opened: 2026-10-15
status: open

The review checklist reviews an inherited test as an edited test, but applies
only the floor to it. A sentence such as "a change to a test's `verifies:`
edits it" would close it; the template is at its word cap, so the sentence
needs a cut elsewhere and its own review.
