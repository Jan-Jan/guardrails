# Problem report — the test runner, and two findings the roadmap keeps as items

Recorded by phase 1 of the 2026-10-06 salvage roadmap. `affects:`
names files.

**PR-sc5qy5**: No gate distinguishes a sentence about an unmerged branch from a sentence about the tree under merge, so a document can state another worktree's state as a fact about this one and every check passes.
affects: scripts/check-trace.sh, and every document under `strict_paths` that names a branch.
opened: 2026-10-06
status: open

Seen in every review round of the discarded churn proposal (2026-09-18),
including after reviewers were told to hunt for it. A candidate check: a
backtick-quoted token that matches a local branch not merged into the base
branch, excluding the branch under merge and the base itself, is reported as a
warning with its file and line. A deleted branch falls silent on its own. It
catches a named branch only; a claim wrong by omission stays with the
reviewer.

**PR-555dk4**: `analyze-risks` gives no guidance on how to design a risk control so that a test can show it works, so each change derives control design afresh.
affects: skills/analyze-risks/SKILL.md, and the risk controls written under it.
opened: 2026-10-06
status: open

The discarded churn proposal proposed a `design-controls` section stating
four laws of control design and the rule that each control ships with the
mutation that defeats its predecessor. Only one of the four laws was ever
written down, argued for one case in the mutation-evidence plan. Its other two
parts, a kill line per test in the dispatch report and a `killed:` column in
the verification record, would mostly restate what a squash message's
`Mutation:` trailers and `red -> green:` lines already state.

