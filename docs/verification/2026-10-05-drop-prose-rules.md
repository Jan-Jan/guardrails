# Verification — drop-prose-rules (2026-10-05)

One record per change, written at `merge-change` step 6b and checked at step 6c
by `.guardrails/scripts/check-review.sh`. The squash commit references it on
its `Verified:` line, so this file is the evidence that travels with the change.

branch: drop-prose-rules
reviewer: independent subagent (Claude Opus 5.5), dispatched with the diff, the decision record, the plan, AGENTS.md and `skills/merge-change/references/review-checklist.md`, and no implementation narrative
verdict: All findings low; the change does what D1-D7 state, and the four re-anchored or new tests fail when the text they pin breaks. Last review round under the severity rule.
reproduced: not applicable — this change removes rules and a scan; it repairs no defect. The tests' ability to fail was measured instead (Red → green, and the reviewer's probes below).

Change: the prose rules and the vocabulary scan are removed; the code naming
rules remain as `## Code: names`, and the deslop pass and check 8 remain.
Branched from `main` at `089f4b4`; base merged from local `main` at `089f4b4`,
per AGENTS.md non-negotiable 5.
Plan: `docs/plans/2026-10-05-drop-prose-rules-implementation.md`; decisions in
`docs/plans/2026-10-05-drop-prose-rules.md`.

Opened while `adr-ids` was open, against AGENTS.md non-negotiable 4, by the
maintainer's decision of 2026-10-05; the decision record's "Sequencing" section
states the measured overlap (none on the edited lines).

## The gate

Every figure below is measured on one tree, and the table names it, so a later
reader can re-measure the same tree instead of guessing which round produced
these numbers. **No figure here is copied forward from an earlier round.**

Measured on: `6a9b1d4` — `git rev-parse HEAD` — tree `9e00c4e6f9aa15ef6215c15f66dab6a0660bf151`, from
`git rev-parse HEAD^{tree}` on a clean worktree. Step 3 renamed nothing (the
change has no draft ledger files), so this is the tree step 2 measured.

The suite was run by the dispatcher as a background job writing only a summary,
not by a gate subagent: a dispatched subagent's command limit (600 s) is below
the suite's run time (about 50 minutes).

| Gate | Result |
| --- | --- |
| `tests/run-tests.sh` | exit 0 — `1..1027`, 1027 ok, 0 not ok |
| Base, `tests/run-tests.sh` at `089f4b4` (tree `a650c5e66e3a508f30c900e112b35d5a107f7a3c`) | exit 0 — `1..1032`, 1032 ok, 0 not ok |
| `check-ids`, `check-trace`, `check-review`, `finalize-docs` | exit 2 each — inapplicable, no `.guardrails/config.yaml` |
| `merge-preflight.sh --before-review --local-base` | CLEAN-TREE ok, BASE-MERGED ok (local base only); exit 2 at IDS — no `.guardrails/config.yaml` |
| Coverage, against the class target | not configured |
| Working tree | clean before and after the suite run; tree unchanged by it |

The plan count is five below the base's: six tests removed (D4), one added (D3).

## Red → green

guardrails keeps no ledger, so the rows name decisions, not item IDs.

| Item | Test | Watched red |
| --- | --- | --- |
| D2 | `clanker: the managed block names concrete naming rules` | red before the text change (T1 step A, `## Code: names` absent); after finding-1, red when "Name in concrete terms." was deleted, when "No code golf." was removed, and when the past-participle line was appended |
| D1, D2 | `clanker: this repository follows the same block` | red before the text change (T1 step A) |
| D6 | `clanker: ratchet reports a managed block with no code section` | red before the text change (T1 step A) |
| D3 | `clanker: the deslop pass reviews against the code rules` | red before the text change (T1 step A) |

T1 step A run of `tests/skills.bats`: `1..87`, 83 ok, 4 not ok — exactly these
four. Step B: `1..87`, 87 ok.

## What was wrong, and what was built

The managed block shipped to every adopting project, and this repository's
AGENTS.md, contained rules that steer an agent's word choice: a preamble
binding "everything written", four prose bullets (no metaphor; active voice;
a replace-these-words list; do not match existing style) and a past-participle
naming rule. A scan in `tests/skills.bats` (eight `gr_writing_*` helpers, six
tests) failed the suite on the listed words in every tracked file outside the
merged records. The maintainer judged word choice outside guardrails' core.

Built: both AGENTS files carry `## Code: names` with two rules (no
single-character names, no code golf; name in concrete terms). The scan and its
helpers are deleted. The deslop prompt names "the code rules in AGENTS.md";
check 8 is unchanged. The ratchet gap bullet names the new heading, and
`skills/ratchet/references/upgrade-notes.md` replaces the old announcement with
one stating what was removed, including the past-participle rule.

## Review

Round 1. The reviewer ran `tests/skills.bats` (`1..87`, 87 ok) and
`tests/portability.bats` (`1..13`, 13 ok) in its own worktree instead of the
full suite, which exceeds its command limit; the full suite is the gate above.
Its mutation probes: each of the four tests went red when the text it pins was
restored to the old wording, and the two `!` absence checks went red when the
old text was appended beside the new.

**finding-1**: requirement, low — D2 has two halves: it keeps "No code golf" and "Name in concrete terms", and it removes the past-participle / `write_timestamp` rule. No test pins either half. tests/skills.bats:734-741 and :743-756 assert only `^## Code: names$` and `single-character`. The tree is correct (AGENTS.md:53-56, templates/AGENTS-block.md:68-71), but deleting "Name in concrete terms" or putting the `write_timestamp` line back would leave the suite green. The `# verifies: D2` annotation claims more than the assertions check.
disposition: fixed in c61f3cc. `clanker: the managed block names concrete naming rules` now asserts `No code golf` and `Name in concrete terms`, and a guarded absence check for `past participle|write_timestamp`; each assertion was watched red under its mutation (Red → green).

**finding-2**: requirement, low — skills/ratchet/references/upgrade-notes.md:296-304 announces that the prose rules are removed and lists the code rules that remain. It does not state that the past-participle naming rule is also removed (D2). An adopter who relied on that rule is not told it is gone. D6 does not require the statement, so this is a documentation gap where the tree is right.
disposition: fixed in c61f3cc: the note states that the past-participle rule is removed with the prose rules. No test pins the new sentence, although one upgrade note is pinned (`upgrade-notes-announce-the-hard-cut`); stated under Gaps.

Both findings low: no further reviewer was dispatched, and the rerun from step 1
ends at 6b.

## Gaps

- The rule against prose words in this repository's own files is gone, so new
  prose may reintroduce the replaced words; that is the decision, not a defect.
- Nothing checks that the two AGENTS files' `## Code: names` sections stay
  identical; the tests pin the same phrases in the block and the heading plus
  one phrase in AGENTS.md.
- No test pins the upgrade note's statements (finding-2's sentence
  included); deleting the note leaves the suite green.
- `check-ids`, `check-trace`, `check-review` and `finalize-docs` are
  inapplicable here (no `.guardrails/config.yaml`), so this record's grammar is
  not machine-checked.
