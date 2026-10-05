# Dropping the prose rules — decisions

**Status:** confirmed by the maintainer, 2026-09-30 (interview) and 2026-10-05
(opened while `adr-ids` is open; see "Sequencing").

## Why

The CLANKER adoption (3714f08, 8d78cd4) shipped rules that change the words an
agent writes, and a scan that fails the suite on those words. Word choice is not
core to what guardrails' skills do, and a project that wants such rules adds
them to its own AGENTS.md. The cost is measured in the history: changes spend
commits rewording scan hits (assertion-gate's "the replaced word on two added
lines").

## Decisions

**D1 — The prose rules are removed, from the shipped block and from this
repository.** Removed from `templates/AGENTS-block.md` and `AGENTS.md`: the
preamble ("Write dry, technical prose … applies to everything written") and
all four bullets — no metaphor, anthropomorphism, wordplay or balanced
contrast; active voice, cut filler, do not editorialize; the replace-these-words
list; do not match existing style. Supersedes D2 and D3 of
`docs/plans/2026-09-14-clanker-adoption.md` and D3 of
`docs/plans/2026-09-16-scan-scope.md`.

**D2 — The code rules remain, as a code-only section, without the past
participle rule.** Kept: no single-character names, no code golf, name in
concrete terms. Removed: "do not use the past participle: write
`write_timestamp`, not `written_at`", a word-form rule like the prose rules.
The heading becomes `## Code: names` in both files. Narrows D5 of the CLANKER
record.

**D3 — The deslop pass and check 8 remain.** `develop-change`'s dispatch prompt
names "the code rules in AGENTS.md" instead of "the writing and naming rules in
AGENTS.md"; its own list (slop, unclear names, cross-task duplication, anything
simpler) is unchanged. `verify-before-merge` check 8 is unchanged. CLANKER D4,
D6, D7 and D8 stand.

**D4 — The vocabulary scan is removed, with everything that pins it.** From
`tests/skills.bats`: the `gr_writing_*` helpers and the six tests that compare
the word table, the replace list, the scan's forms and its scope, and that scan
the tree. Supersedes D1, D2, D4, D5 and D6 of
`docs/plans/2026-09-16-scan-scope.md`.

**D5 — The tests that pin kept behavior are re-anchored, not removed.** The
block's naming-rule test, the "this repository follows the same block" test and
the ratchet gap-bullet test follow the `## Code: names` heading.

**D6 — The ratchet text follows.** The gap-inventory bullet in
`skills/ratchet/SKILL.md` names the new heading. The upgrade note "Writing rules
in the managed block" in `skills/ratchet/references/upgrade-notes.md` is
replaced by a note stating the prose rules are removed, the code section
remains, nothing goes red, and a project that wants the prose rules keeps them
outside the managed markers, because a block refresh replaces everything
between them.

**D7 — The swept prose stays as it reads.** The skill bodies and the 589
replaced words are not reverted. Merged plans and verification records are not
edited; their decisions are superseded by name here.

## Sequencing

`adr-ids` was open, in review, when this change was opened, against AGENTS.md
non-negotiable 4. The maintainer chose to open it anyway (2026-10-05).
Measured at `089f4b4`: `main...adr-ids` touches `AGENTS.md`, `skills/ratchet/`
and `tests/skills.bats`, and none of the lines this change edits, so whichever
merges second has a base merge with line offsets only.

## Facts measured before opening (`089f4b4`)

- No `M*.sh` under `docs/verification/*.mutations/` targets a file this change
  edits.
- `README.md` does not describe the scan.
- Nothing outside `tests/skills.bats` names a removed helper or test.
