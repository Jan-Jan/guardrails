# Skills find items with find-items.sh: plan-change, analyze-risks, merge-change

**Goal:** Three more skills read a ledger item with `find-items.sh` instead of
reading a ledger file whole.
**Implements:** no requirement items exist in this repository. Follows the
2026-10-03 decision recorded in `docs/plans/2026-10-04-find-items.md`, which
changed three skills. The user asked for these three on 2026-10-05.
**Safety class:** the toolkit itself is unclassified. Documentation only.
**Verification:** `sh tests/run-tests.sh`, dispatched to a subagent (AGENTS.md
non-negotiable 3). The verdict comes from the reported pass and fail counts.
`tests/skills.bats` enforces the section order and the 2,000-word limit.

**Base.** Branched from local `main` at `407ffe7` on 2026-10-05, while
`ratchet-self-host` is open. The user decided this on 2026-10-05 and overrode
AGENTS.md non-negotiable 4 for this change. The two changes touch no common
file.

The wording follows the three skills changed by `089f4b4`:
`design-architecture` step 1 and `resolve-problem` "Record before".

---

### T1 — three skills use find-items.sh

**Files touched:** `skills/plan-change/SKILL.md`,
`skills/analyze-risks/SKILL.md`, `skills/merge-change/SKILL.md`
**Parallel:** no (only task)

Each edit replaces the exact Before text with the exact After text. Each
Before must match exactly once; stop and report if it matches zero or two
times. Keep the line wrapping at 79 columns, as in the surrounding text.

**Step 1.** `skills/plan-change/SKILL.md`, section "## Preconditions".

Before:

*(Code pruned at merge: 2 lines. Files touched: `skills/plan-change/SKILL.md`, `skills/analyze-risks/SKILL.md`, `skills/merge-change/SKILL.md`.)*

After:

*(Code pruned at merge: 6 lines. Files touched: `skills/plan-change/SKILL.md`, `skills/analyze-risks/SKILL.md`, `skills/merge-change/SKILL.md`.)*

**Step 2.** `skills/analyze-risks/SKILL.md`, section "## Preconditions".

Before:

*(Code pruned at merge: 2 lines. Files touched: `skills/plan-change/SKILL.md`, `skills/analyze-risks/SKILL.md`, `skills/merge-change/SKILL.md`.)*

After:

*(Code pruned at merge: 7 lines. Files touched: `skills/plan-change/SKILL.md`, `skills/analyze-risks/SKILL.md`, `skills/merge-change/SKILL.md`.)*

**Step 3.** `skills/analyze-risks/SKILL.md`, "Derived-requirements intake",
item 1.

Before:

*(Code pruned at merge: 2 lines. Files touched: `skills/plan-change/SKILL.md`, `skills/analyze-risks/SKILL.md`, `skills/merge-change/SKILL.md`.)*

After:

*(Code pruned at merge: 3 lines. Files touched: `skills/plan-change/SKILL.md`, `skills/analyze-risks/SKILL.md`, `skills/merge-change/SKILL.md`.)*

**Step 4.** `skills/merge-change/SKILL.md`, step 6a. The file is at 1,999
words before this step, and the limit is 2,000. This edit is a net one word
longer, to 2,000.

Before:

*(Code pruned at merge: 3 lines. Files touched: `skills/plan-change/SKILL.md`, `skills/analyze-risks/SKILL.md`, `skills/merge-change/SKILL.md`.)*

After:

*(Code pruned at merge: 3 lines. Files touched: `skills/plan-change/SKILL.md`, `skills/analyze-risks/SKILL.md`, `skills/merge-change/SKILL.md`.)*

**Step 5.** Word counts. Run
`wc -w skills/plan-change/SKILL.md skills/analyze-risks/SKILL.md skills/merge-change/SKILL.md`.
Expected: `merge-change` 2000. Each file at most 2,000.

**Step 6.** Run `tests/.bats-core/bin/bats tests/skills.bats` (never
`run-tests.sh` with an argument). Expected: every test ok. There is no red
step: the change is documentation only.

**Step 7.** Commit on the task branch, unsigned:
`docs: plan-change, analyze-risks and merge-change read ledger items with find-items.sh`.

## Progress

| task | state | commit | evidence |
|---|---|---|---|
| T1 | merged | 336b4c3 | documentation only, no red step. Each Before matched once. `wc -w`: plan-change 560, analyze-risks 863, merge-change 2000. `skills.bats` 93 of 93 ok |

Deslop pass, `1689b5a`: `merge-change` step 6a spells the script as
`.guardrails/scripts/find-items.sh` on its first mention, as the other skills
do; the word count is unchanged at 2,000. Considered and kept: the absolute
"not by reading the ledger files whole" in `plan-change`, which
`grill-requirements` also uses, and the terse "`show` of each claimed ID",
because `merge-change` is at the word limit. `skills.bats` 93 of 93 ok.

Review round 1 at `5d8c505`: three low requirement findings and one record
finding. Under the low-severity rule (ruled 2026-10-04) there is no round 2.
Fixes, `3a4c15e`: `merge-change` 6a hands over each ID the change claims or
amends, and restores "where team policy requires one"; `plan-change` reads
each item the plan cites, LLRs included. Six words were cut inside 6a to stay
at 2,000: "also", "with it", "own" twice, and "onto" once. The plan's step 4
states the word change as net (`c8732c1`). The tree supersedes the step 1 and
step 4 After texts.
