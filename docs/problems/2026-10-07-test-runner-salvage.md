# Problem report — the test runner, and two findings the roadmap keeps as items

Recorded by phase 1 of the 2026-10-06 salvage roadmap. `affects:`
names files.

**PR-sc5qy5**: No gate distinguishes a sentence about an unmerged branch from a sentence about the tree under merge, so a document can state another worktree's state as a fact about this one and every check passes.
affects: scripts/check-trace.sh, and every document under `strict_paths` that names a branch.
opened: 2026-10-06
status: accepted
disposition: ruled on 2026-10-30 — plans and records no longer reach the base; a claim about another branch is the reviewer's to catch.

Review rounds miss such a sentence round after round, even when the
reviewers are told to hunt for it. A candidate check: a
backtick-quoted token that matches a local branch not merged into the base
branch, excluding the branch under merge and the base itself, is reported as a
warning with its file and line. A deleted branch falls silent on its own. It
catches a named branch only; a claim wrong by omission stays with the
reviewer.

**PR-555dk4**: `analyze-risks` gives no guidance on how to design a risk control so that a test can show it works, so each change derives control design afresh.
affects: skills/analyze-risks/SKILL.md, and the risk controls written under it.
opened: 2026-10-06
status: accepted
disposition: ruled on 2026-10-30 — each RC must become a testable REQ (analyze-risks); no control-design method is prescribed.

A candidate is a `design-controls` section stating four laws of control
design and the rule that each control ships with the mutation that defeats its
predecessor. No skill states any of the four laws, and only one of them has
been argued, for one case. The candidate's other two parts, a kill line per test in the dispatch report and a `killed:` column in
the verification record, would mostly restate what a squash message's
`Mutation:` trailers and `red -> green:` lines already state.

