# Drop the prose rules Implementation Plan

**Goal:** Remove the rules that steer an agent's word choice and the scan that
enforces them; keep the code naming rules, the deslop pass and check 8
(`docs/plans/2026-10-05-drop-prose-rules.md`, D1-D7).
**Implements:** D1-D7 — guardrails keeps no ledger of its own, so the decision
record is the source.
**Safety class:** not configured — `check-ids.sh`, `check-trace.sh`,
`check-review.sh` and `finalize-docs.sh` exit 2, inapplicable.
**Verification:** `tests/run-tests.sh`. The plan count falls by five (six tests
removed, one added) against the base's count measured at the same base commit.

## T1 — tests first, then the text

**Files touched:** tests/skills.bats, templates/AGENTS-block.md, AGENTS.md,
skills/develop-change/SKILL.md, skills/ratchet/SKILL.md,
skills/ratchet/references/upgrade-notes.md
**Parallel:** no (one task; the red run between steps A and B is the evidence)

### A — tests (expected red)

1. Delete the `gr_writing_*` helpers (`gr_writing_table`, `_forms`, `_keys`,
   `_paths`, `_exemptions`, `_exempt_script`, `_section_closer`, `_scan`) and
   their comments. Keep the file's opening comment.
2. Delete these tests whole: "the managed block bans the vocabulary by listing
   it"; "the word table and the shipped replace list name the same words";
   "every word-table key is among the forms the scan reads for it"; "the scan's
   own grep reports every form in the word table"; "every tracked file is in the
   scan's scope or named out of it"; "no file in scope contains the replaced
   vocabulary".
3. "the managed block names concrete naming rules": drop the `write_timestamp`
   assertion; keep `single-character`; assert `^## Code: names$`. `# verifies:`
   D2 of the new record.
4. "this repository follows the same block": assert `^## Code: names$` and
   `single-character` in AGENTS.md, and that neither AGENTS.md nor the block
   contains `^## Writing: prose, names and messages$`. `# verifies:` D1, D2.
5. "ratchet reports a managed block with no writing rules": rename to "... with
   no code section"; anchor on 'A managed block with no `## Code: names`
   section'. `# verifies:` D6.
6. New test "clanker: the deslop pass reviews against the code rules": the
   develop-change prompt contains "the code rules in AGENTS.md" and not
   "writing and naming rules". `# verifies:` D3.
7. A `[[ ]]` not on a test's last line ends `|| { echo "…"; false; }`
   (PR-tenhv4).

Run `tests/.bats-core/bin/bats tests/skills.bats`. Expected: exactly the four
tests from steps 3-6 fail, each naming the missing text.

### B — text (expected green)

1. Both AGENTS files: replace the `## Writing: prose, names and messages`
   section, heading through its last bullet, with

   ```
   ## Code: names

   - No single-character names. No code golf.
   - Name in concrete terms.
   ```
2. develop-change prompt: "under the writing and naming rules in AGENTS.md" ->
   "under the code rules in AGENTS.md".
3. ratchet SKILL.md gap bullet: the heading becomes `## Code: names`; the rest
   of the bullet stays.
4. upgrade-notes.md: replace the "Writing rules in the managed block" section
   with "## Prose rules removed from the managed block", stating D6.
5. Every substitution is checked: one that matches nothing fails the pass.

Run `tests/.bats-core/bin/bats tests/skills.bats`. Expected: all ok.

## T2 — the deslop pass

One dispatch over `main...drop-prose-rules`, in the change worktree, no task
worktree, against the code rules.
