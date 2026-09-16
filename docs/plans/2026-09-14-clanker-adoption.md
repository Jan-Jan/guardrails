# CLANKER.md adoption — design and decisions

**Goal:** Adopt the rules from [CLANKER.md](https://github.com/koute/CLANKER.md)
that improve code quality and agent behavior in guardrails projects, and record
which rules are deliberately rejected so the question is not reopened.

**Source:** `https://github.com/koute/CLANKER.md/blob/master/CLANKER.md`, 156
lines, read 2026-09-10.

**Implements:** no minted REQ/RC/SDD IDs — guardrails does not self-host its own
gates (`2026-08-22-ratchet-gap-analysis.md`). The bats suite is the evidence.

**Safety class:** n/a — guardrails is a development tool.

## What CLANKER.md is

A single rules file for coding agents. Roughly half of it is a plain-language
style guide with an explicit list of banned words; the rest covers workflow,
testing, root-cause analysis, an agent-owned `.agent` directory, and
Rust-specific conventions.

Guardrails already covers the workflow half. The style guide and the code-craft
rules are the part guardrails has nothing equivalent to, and they are the part
adopted here.

## Adopted

| Rule | Destination |
|---|---|
| Plain language: banned-word list, no metaphor, no anthropomorphism, active voice, "do not match existing style" | `templates/AGENTS-block.md`, compressed to about 12 lines |
| No single-character names, no code golf | same block |
| Concrete technical naming, no past participle (`write_timestamp`, not `written_at`) | same block |
| Deslop pass over the whole change diff | `develop-change`, at the skill's exit |
| Architectural root cause | `resolve-problem`, a fourth escalation to `design-architecture` |
| Change the approach when stuck | `develop-change` derailment rule (D7) |

## Rejected, and why

| Rule | Reason |
|---|---|
| No code comments | User decision. |
| Prefer integration tests over unit tests | User decision. Class C requires unit-level verification per software item (`develop-change`), so a blanket preference would contradict the class rules. |
| Rust-specific conventions | User decision. The suite is language-agnostic. |
| `.agent/` workspace (`STATUS.md`, `memory/`, `worklog/`, `tools/`) | User decision. Guardrails already has durable agent state: the plan, the ledgers and the verification record. A second, unversioned store competes with them. |
| Sandbox notes (sudo, uv, `/tmp`) | User decision. Environment-specific. |
| Tests must document why; a test must fail when the logic changes | Already mechanical. `tests/evidence.sh` derives at merge time how many new tests go red against the base ref and names every one that does not; `verifies: <ID>` points each test at the requirement that is its reason. Prose would restate a gate. |
| Object once to any instruction | The harness already permits raising a concern once and continuing. Guardrails already has explicit user-decision stops: a red baseline (`worktree-discipline` step 4), an accepted coverage gap (`verify-before-merge` check 5), and derailment (`develop-change`). An objection right risks turning those into debates. |
| State the Definition of Done and get approval | Every skill has a "Done when" section. |
| Never guess; ask or investigate | `grill-requirements` already separates facts, which are looked up, from decisions, which go to the user. |
| Small commits, never push | `merge-change` already governs this. |

## Decisions

**D1 — Placement is by trigger.** Rules that govern every line written go in
the managed `AGENTS.md` block, which is in context on every turn. Rules bound to
one workflow step go in the skill that owns that step.

Putting everything in the always-on block would make every project pay for all
of it on every turn. Putting everything in skill bodies would leave naming and
language unconstrained during edits made outside any skill, which is most quick
edits.

**D2 — The vocabulary sweep runs now, across all 11 skill bodies.** The rule
also binds new writing.

Measured 2026-09-10 at `51f01b7`: the skill bodies total 2,337 lines and contain
127 instances of the banned vocabulary. `load-bearing`, a word the adopted
list names, appears at `skills/worktree-discipline/SKILL.md:90` and
`skills/merge-change/SKILL.md:108`, and three times in `tests/skills.bats` —
including line 2, in the comment that introduces the whole file.

Forward-only was the alternative. It was rejected because the old register would
remain readable in context for a long time, and an agent imitates what surrounds
it — which is why CLANKER's "do not match existing style" line is adopted
alongside the list rather than instead of it.

**D3 — The rule form is a compressed list, about 12 lines.** Keep the explicit
banned-word list and three or four before/after pairs. Cut CLANKER's rationale
prose.

Abstract instructions do not change model output. The current skill prose was
written under instructions of roughly the shape "be clear and concise". A
concrete word list does change output, and it is the part worth the always-on
context cost.

**D4 — The deslop pass runs at `develop-change`'s exit, not at `merge-change`
6a.** After the last task branch merges and the suite is green, `develop-change`
dispatches one subagent to review `main...<change-branch>` for slop, naming,
duplication and simplification, and to fix what it finds on the change branch.
It returns a short report.

Three reasons 6a is too late:

1. `merge-change`'s sequence reruns from step 1 on any finding, so a variable
   name would cost a full merge-sequence restart.
2. By 6a every task branch is merged and the change is squash-bound. A fix
   costs least while the task is still open and its subagent is still
   dispatched, and at 6a neither is true.
3. 6a is a DO-178C independence review: does the code satisfy each REQ, do the
   tests verify what they claim, is there unmarked derived work. Craft criteria
   mixed into that make correctness and style one verdict, and the second
   waters down the first.

One reason the exit of `develop-change` is positively right: the skill states
that delegation costs the dispatcher its feel for drift across tasks, because
each subagent sees one task and nobody sees the shape. Cross-task slop —
two tasks duplicating a helper, the same concept named differently in each — is
invisible to any per-task review. This pass is the only agent that sees the
whole change.

A per-task self-review at REFACTOR was the alternative. It catches slop earlier
and costs nothing, but it cannot see across tasks, and self-review is the
weakest form.

**D5 — The naming rule reaches identifiers and commit subjects in full.** Bats
test descriptions keep sentence form, because a test description documents
behavior and a sentence is the correct form for that, but they drop
anthropomorphism and the banned vocabulary.

**D6 — `merge-change` 6a keeps its independence criteria only, and
`verify-before-merge` gains check 8: the deslop pass was run and its findings
were acted on.** This enforces the pass at a gate that already exists, and keeps
cosmetics from ever restarting the merge sequence.

Nothing at all was the alternative. In a suite where every other step is
mechanically checked, an unenforced step is the one that stops running.

**D7 — A re-dispatch below the derailment threshold changes the approach.**
`develop-change` re-dispatches on the first failure and stops on the second. It
does not say what the re-dispatch should do differently, so it repeats the
approach that already failed and spends a second agent to learn nothing.

**D8 — The deslop pass is the one dispatch without its own task worktree.** It
fixes on the change branch directly, so its prompt states the change worktree
path and the prohibition together.

Every other dispatch in these skills names a nested task worktree. A subagent
given no location follows that pattern, creates one, and leaves its fixes on a
task branch — for the one pass whose purpose is to edit the change branch in
place.

## Known gaps in the scan's scope, deliberately left for their own change

**The D2 scan reads `skills/*/SKILL.md` and nothing else.** Every other file in
this repository is unscanned. Two of them are excluded on purpose: `AGENTS.md`
and `templates/AGENTS-block.md` each print the replace list itself, so a scan of
either would report its own rule text on every run. Everything else is outside
the glob rather than outside the rule.

Measured at `d68bb95`, the change branch head when round 2 of the independent
review began, counting word-bounded occurrences of the `banned=` word list in
the D2 scan test:

| Surface | Occurrences | Does the rule bind it? |
|---|---|---|
| `skills/*/SKILL.md` | 3 | Yes — this is the scan's whole scope. All three are the phrases the scan exempts by their full wording: two git messages and one `check-trace.sh` message |
| `AGENTS.md` | 9 | Yes. All nine are the rule text itself; the file is otherwise clean |
| `templates/AGENTS-block.md` | 9 | Yes. Same nine lines of rule text, and otherwise clean |
| `README.md` | 30 | Yes. A shipped document |
| `templates/`, other than the block | 22 | Yes. Shipped documents |
| `scripts/*.sh` | 185 | Yes. Comments and printed messages are strings in code, and identifiers are bound by the naming rules |
| `tests/*.bats`, other than `skills.bats` | 251 | Yes. Code, and D5 reaches bats test descriptions |
| `tests/skills.bats` | 36 | Yes, and round 1's finding 1 swept the file's own names and comments. What remains is skill prose and git output quoted inside assertions, which stays verbatim |
| `install.sh` | 1 | Yes. A comment |
| `docs/problems/`, `docs/risk/`, `docs/adr/` | 81 | Yes, for what is written from here on |
| `docs/plans/`, `docs/verification/` | 1,236 | Not retroactively. These are merged records, and editing one to match a later tree falsifies the evidence it contains — the same reason the seventeen test-name citations in `2026-09-14-clanker-implementation.md` are left alone |

Each figure is reproducible with the scan test's own `banned=` list:

```sh
git grep -Eiow "$banned" d68bb95 -- <pathspec> | wc -l
```

These are the size of the unscanned surface, not defect counts. A word used
correctly counts here, and so does every word inside a quoted error message, and
the scan's three exemptions are not applied outside `skills/`. Nothing in the
table is swept in this change. Which of these surfaces to bring into the scan,
and at what cost in false reports, is work for the change that closes the scope
gap.

The gap is not theoretical. The second deslop pass found two words from the
list in `AGENTS.md` — `the signed squash lands on` and `That reasoning
holds for` — which no gate reported, in the file that states the rules. Both
are fixed here, and both files are clean as merged apart from their rule text,
but nothing prevents recurrence.

The fix for the two excluded files is to exclude each file's own
`## Writing: prose, names and messages` section by heading rather than
excluding the file by name, so the prose around the rules is scanned while the
rules themselves are not. That is about ten lines, needs its own RED proof, and
forces another full gate run, so it is its own change rather than a late
addition to this one.

Until that change is merged, the two files are covered by the deslop pass at
`develop-change`'s exit and by nothing else.

**Three more holes in the same scan, beyond its scope.** Round 1 of the
independent review named them, and all three belong to the change that fixes
the scope gap above.

1. The `banned=` list in the test is a hand copy of the replace list in
   `AGENTS.md`, and nothing connects the two. A word added to the managed block
   is not added to the scan, and no check reports the divergence.
2. `tests/skills.bats` is outside the scan's scope, so the file containing the
   scan is never scanned. The review found one `@test` name and six comments
   there using the replaced vocabulary; they are fixed by hand and stay
   unguarded.
3. The scan enforces the replace list and nothing else in the writing rules.
   `sit`, from `A file exists in a directory; it does not sit there`, is an
   example of the metaphor rule rather than an entry on the replace list, so
   the scan has no entry for it or for any other part of that rule.

A fourth hole was fixed in this round rather than deferred. The `|| true` on the
scan made an empty glob indistinguishable from a clean tree: if the skill paths
moved, the test would go green having read no file. It now counts the files the
scan read and requires at least 11.

## Cost, stated plainly

Against the three goals this change was asked to serve:

- **A cleaner code base.** The naming rules and the deslop pass do this. They
  are also the least enforceable: no script checks them, so the deslop pass is
  the only thing that will.
- **More readable code.** Most of the gain comes from dropping the register, not
  from any single rule.
- **Less work for the agent.** The smallest gain of the three. The real cost of
  these skills is their length — 2,621 lines at `3a08bd1`, `ratchet` alone 629
  and `merge-change` 540. The earlier figure, 2,337 lines with `ratchet` at 539
  and `merge-change` at 478, was correct at `51f01b7`, where this change was
  cut; the base branch grew those two files before this change touched them.
  Nothing here removes a line. That is a separate change,
  and a riskier one, because the length is mostly rationale that was expensive
  to learn.

## Constraint: the conflict with `field-report-items`

This change is based on `main` at `51f01b7`. The `field-report-items` change was
unmerged when this branch was cut, with 35 commits and 2,712 lines not on
`main`, and it edits six files this change also edits: `skills/develop-change`,
`skills/merge-change`, `skills/verify-before-merge`, `skills/ratchet`,
`skills/resolve-problem` and `tests/skills.bats`.

Re-merge `main` into this branch after that change reaches its signed squash,
and expect text conflicts in all six. The vocabulary sweep must then run again
over whatever prose the other change added — a sweep measured against a tree
that has since moved is not a sweep.

## Files to change

- `templates/AGENTS-block.md` — the new always-on section
- `AGENTS.md` — the same rules for this repository
- `skills/develop-change/SKILL.md` — the exit deslop dispatch and its report
  shape, and the derailment pivot
- `skills/verify-before-merge/SKILL.md` — check 8
- `skills/resolve-problem/SKILL.md` — the fourth escalation
- `skills/ratchet/SKILL.md` — gap analysis detects a block without the new
  section
- all 11 `skills/*/SKILL.md` — the vocabulary sweep
- `tests/skills.bats` — repair the 4 pinned assertion strings and the 6 `@test`
  names that contain banned vocabulary, and add assertions for each new rule
