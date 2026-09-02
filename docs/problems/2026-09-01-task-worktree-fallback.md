# Problem reports — task worktrees under a harness that pins subagents

`affects:` names files rather than item IDs for the reason
`docs/problems/2026-08-27-macos-awk.md` gives: guardrails keeps no
REQ/SDD/LLR ledger of its own yet. When the ledgers arrive, these lines get
the IDs.

**PR-n57ayn**: A subagent dispatched to implement a plan task creates the task
worktree `worktree-discipline` tells it to create, at the location that rule
points to, and is then refused every git operation, every write through the
harness's own write tool and — after the worktree tool reports entering it —
every shell call against it, so the task's commits and its red -> green
attestations never reach a task branch.
affects: skills/worktree-discipline/SKILL.md (step 1 task-worktree passage,
the task-worktree removal bullet, red flags), skills/develop-change/SKILL.md
(dispatch prompt template, `worktree:` line), skills/merge-change/SKILL.md
(step 6a review dispatch and findings fix, new step 6d, steps 7 and 8),
skills/verify-before-merge/SKILL.md (fix dispatch),
skills/ratchet/SKILL.md (the gitignore step), scripts/finish-merge.sh
(guard 4), README.md (the script's guard list), AGENTS.md non-negotiable 1,
.gitignore, tests/skills.bats, tests/finish-merge.bats — no item ID exists to
name, see the note above.
opened: 2026-08-31
status: resolved
The symptom was read as "this harness blocks task worktrees — it pins a
subagent to its dispatcher's worktree, refuses every operation against any
other path, and the rule offers no fallback, so each subagent improvises one".
That reading was wrong: task worktrees work here. The rule chose their
location by project convention and offered the harness's own directory beside
the change worktree as an equally good option, where the only property that
decides usability is containment — a dispatched subagent is pinned to the
change worktree's
subtree, so a task worktree beside it is created successfully and is then
refused every git operation, every write, and every shell call after the
worktree tool claims to have entered it. This repository's convention pointed
at exactly that dead location.

`worktree-discipline` step 1 now names `.worktrees/<change-branch>-t<N>`,
carries the 2026-08-31 measurement of both locations — scoped to the one
harness it was taken on, with a probe a project can run to tell whether its
own harness pins — defines `<N>`, and says how a subagent gets inside what it
created and how it enumerates the ignored artifacts it must copy in; its
removal bullet takes the path from the dispatch prompt instead of arguing from
the two
locations step 1 retired. Every skill that dispatches into a task worktree
names that path in the prompt, since a subagent cannot discover its pin before
violating it: `develop-change`, `merge-change` (the step 6a reviewer and the
findings fix) and `verify-before-merge`. `AGENTS.md` non-negotiable 1 and
`ratchet`'s gitignore step carry the same rule, and `.gitignore` covers the
directory. That entry was absent when this change opened and arrived on `main`
independently while it was open, so what this change does there is delete the
duplicate the base merge left behind, and hold the entry with a test.

Nesting created a hazard of its own, and the only code in this change closes
it. `git worktree remove` does not refuse a change worktree that has a
worktree registered inside it — a nested worktree is invisible to the outer
one's `git status` — so the removal destroys the nested worktree's uncommitted
work at exit 0, leaving a prunable registration and an orphan branch behind.
`scripts/finish-merge.sh` gains guard 4, which proves before anything is
removed that nothing is registered inside the worktree it is about to remove,
and names every nested worktree it finds rather than the first. It is written
in plain shell with no `awk -v`, because `awk -v` escape-processes its value
and a backslash in the change worktree's path made the first version fail
open — this is the one guard whose failure loses work rather than withholding
cleanup. `merge-change` then removes the review worktree at the end of step 6a,
where the dispatch ends and where every round arrives — a round that returns
findings never reaches a later step — so the guard does not refuse the
documented happy path of every change. Step 6d removes nothing: it is the
structural check, before the squash is staged, that no worktree is still
registered inside the change worktree.

Reproduced by twenty-eight tests, twenty in `tests/skills.bats` across the
five skills, `AGENTS.md` and `.gitignore`, and eight in
`tests/finish-merge.bats` across guard 4 — including the fail-open, watched
destroying a nested worktree's work at exit 0 before the guard was rewritten.
Each was watched red before the behavior or the prose it asserts existed,
except for six: three
added for the second review's findings 7 and 11b, the two `finish-merge`
status-check tests added for the third review's finding 4, and
`merge-change: every fix dispatch names the nested task worktree path`. Those
hold prose or behavior that already existed and that nothing asserted, so they
were green when written, and each was instead shown red by deleting its subject
and then restored. Two further guard-4 cases — a prefix-sharing sibling, and a
path containing spaces — were added as regression cover for the guard's rewrite
rather than as attestations, and reported as such. Each round of independent
review is dispositioned in its own section of the change plan,
`docs/plans/2026-09-01-task-worktree-containment.md`, which names that round's
findings and what each became: accepted and fixed here, accepted as process
order rather than a defect, accepted as a note that changed nothing, or
accepted as a follow-up deliberately left to its own change. This record
carries no count of the rounds. The round that reads it is always the
uncounted one, so a tally here is stale to the very reviewer looking at it and
costs another round to correct; the plan gains one section per round and is
never stale by construction. Every fix task was itself dispatched into a
nested task worktree, so the rule was executed before it was believed.
