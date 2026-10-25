# Verification — plans-off-main (2026-10-24)

branch: plans-off-main
reviewer: five independent subagents at `merge-change` step 4, one per round, each given the diff, the plan and the review checklist and no implementation narrative, each in its own review worktree, each running only the test files the diff adds or edits
verdict: approve. Rounds 1–3 each raised two medium requirement or code findings, every one fixed and the sequence rerun from step 1; round 4 raised seven low findings and nothing above low, and all seven were fixed. The first step 6a gate then failed one test (finding 29); round 5 reviewed its fix, a file-mode change, and raised only this record's update, so it was the last round.
reproduced: not applicable — the change builds a decision (ADR-k3nkv3), not a defect fix. Before it, `merge-change` step 1 ran `prune-plans.sh`, and every plan reached `main`.
Implements: ADR-k3nkv3 (D2, D13)

Change: a plan lives only on its change branch: `merge-change` step 5 drops it with `drop-plans.sh` after the record, a `PLANS` pre-flight check fails a change that would merge one, and plan pruning is withdrawn.

## The gate

The figures are in the squash commit's trailers. This repository has no `.guardrails/config.yaml`, so `merge-preflight.sh` stops at its config read; `check-ids.sh` and `check-trace.sh` were run instead on scratch copies of `main` and of the change, each with `templates/config.yaml`, `scripts` as its strict path and stub SRS, SAD and SOUP files. Their findings are identical but for two `lib.sh` line numbers shifted by one.

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| ADR-k3nkv3 | every test listed below | each watched failing for the right reason before its implementation existed, as its line states |

- red -> green: drop-plans: a plan the change added is removed in one commit — watched fail (script absent) before the implementation existed
- red -> green: drop-plans: a base plan the change edited is restored, not deleted — watched fail (script absent)
- red -> green: drop-plans: a base plan the change deleted stays deleted, and nothing is committed — watched fail (script absent)
- red -> green: drop-plans: a change that touches no plan commits nothing — watched fail (script absent)
- red -> green: drop-plans: the commit takes only the plans, and leaves other work as it was — watched fail (script absent)
- red -> green: drop-plans: refuses a missing, empty or unknown argument with status 2 — watched fail (script absent)
- red -> green: drop-plans: refuses a ref that does not resolve with status 2 — watched fail (script absent)
- red -> green: drop-plans: refuses a base that is not an ancestor of HEAD with status 2 — watched fail (script absent)
- red -> green: drop-plans: refuses to run on the base branch with status 2 — watched fail (script absent)
- red -> green: drop-plans: refuses to run on a detached HEAD with status 2 — watched fail (script absent)
- red -> green: merge-preflight: PLANS fails on a plan the change adds, names it and the drop — watched fail (exit 0, no PLANS line)
- red -> green: merge-preflight: PLANS fails on a base plan the change edits — watched fail (exit 0, no PLANS line)
- red -> green: merge-preflight: PLANS passes a change that deletes a base plan — watched fail (no `preflight: PLANS ok` line)
- red -> green: merge-preflight: --before-review skips PLANS with a plan added and goes on to IDS — watched fail (no skipped line)
- red -> green: merge-preflight: PLANS reads origin/<base> where it exists, and the local base under --local-base — watched fail (no `preflight: PLANS ok` line)
- red -> green: merge-preflight: a failed git diff of the plans exits 2, is not read as no plan — watched fail (no PLANS check ran; the run reached REVIEW and exited 1)
- red -> green: a withdrawn config key names its withdrawal, not an unknown key — watched fail (check-ids.sh exited 0: prune_plans was still a known key)
- red -> green: merge-change: step 1 merges the base and nothing else — watched fail (the fence still ended in the prune chain)
- red -> green: merge-change: step 5 drops the plans after the record — watched fail (step 5 did not run drop-plans.sh --base)
- red -> green: merge-change: a later round's reviewer reads the dropped plan with git show — watched fail (step 4 named no git show)
- red -> green: merge-change: the squash message names no plan — watched fail (the message block had a Plan: line)
- red -> green: merge-change: the review checklist checks the plan against the diff, and names no pruning — watched fail (the checklist still named pruning)
- red -> green: plan-change: the plan stays on the change branch — watched fail (no drop-plans.sh / merge-change step 5)
- red -> green: ratchet: the upgrade notes withdraw prune_plans — watched fail (no "Plans are dropped before the gate" section)
- red -> green: merge-change: a round that dispatches no reviewer skips the pre-flight before the review — watched fail (step 7 still had the left-whole clause)
- red -> green: merge-change: the review checklist asks for the record only where it exists — watched fail (the checklist still asked for left whole plans)
- red -> green: ADRs: the pruning decision is recorded and superseded — watched fail (Status: accepted)
- red -> green: ratchet: Done when states when an upgrade is complete — watched fail (still "in a plan")
- red -> green: ratchet: upgrade step 4 fixes each failure and lists each new warning in the verification record — watched fail (still "in a plan")
- red -> green: ratchet: the upgrade order of work has the macOS pass and defines a new warning — watched fail (still "in a plan in docs/plans/")
- red -> green: ratchet: the setup checklist is kept in the verification record — watched fail (step 5 still saved it to docs/plans/)
- red -> green: test guidelines: here an ADR or problem report states a deeper interface's contract, not an LLR — watched fail ("Seams 2 does not hang on an ADR")
- red -> green: merge-preflight: PLANS fails on a base plan the change replaces with a symlink — watched fail (exit 0, PLANS ok)
- red -> green: drop-plans: refuses a plan git reports with a status other than A, M or D, before anything changes — watched fail (exit 0, T path skipped)
- red -> green: drop-plans: refuses a plan path git quotes with status 2, before anything changes — watched fail with the refusal made a no-op
- red -> green: drop-plans: a failed git diff of the plans exits 2, is not read as no plan to drop — watched fail with `|| gr_die` replaced by `|| true`
- red -> green: test guidelines: here an ADR or problem report states a deeper interface's contract, not an LLR — watched fail ("Seams 1 does not let an existing plan-decision citation stand")
- red -> green: merge-preflight: PLANS passes a change with no plan when git warns on stderr — watched fail (the warning read as a plan path, exit 1)
- red -> green: merge-preflight: PLANS reads the local base, not origin/<base>, when origin has a plan main lacks — watched fail (PLANS ok against origin/main)
- red -> green: merge-preflight: PLANS passes a plan local main has and origin/<base> lacks — watched fail (PLANS flagged the base's plan)
- red -> green: drop-plans: refuses an added plan with an unstaged edit with status 2, before anything changes — watched fail (git rm failed partway)
- red -> green: drop-plans: refuses an edited base plan with an unstaged edit with status 2, and keeps the edit — watched fail (exit 0, the edit overwritten)
- red -> green: verify-before-merge: the gate reads the verification record, not the dropped plan — watched fail ("the gate still reads the plan")
- red -> green: skills: a fix dispatched after step 5 writes its red -> green lines into the record — watched fail
- red -> green: ratchet: the later teeth, the branch name and the signing duty survive the plan drop — watched fail ("later teeth not listed in the record")
- red -> green: merge-change: step 5 drops the plans after the record — watched fail (no `drop-plans.sh --base "$BASE"` line)
- red -> green: merge-change: a later round's reviewer reads the dropped plan with git show — watched fail (no drop-commit lookup)
- red -> green: merge-change: step 5 fills the record's Implements line from the plan's Implements value — watched fail ("the verification template has no Implements: line")
- red -> green: merge-change: a 6a fix that touches the plan dispatches a reviewer — watched fail
- red -> green: merge-change: step 1 reruns after its conflicts are resolved — watched fail
- red -> green: verify-before-merge: the gate reads the verification record, not the dropped plan — watched fail (no `Implements:` line read)
- red -> green: ratchet: the setup checklist goes in the plan, and merge-change step 5 copies it into the record — watched fail ("not kept in the plan")
- red -> green: drop-plans: the commit takes only the plans, and leaves other work as it was — watched fail with `-- "$@"` removed
- red -> green: drop-plans: refuses a base that is not an ancestor of HEAD with status 2 — watched fail against the old remedy text
- red -> green: ratchet: step 5 writes the verification record early, with the setup checklist under Tool qualification — watched fail
- red -> green: merge-change: a rerun of step 5 updates the record and reads the dropped plan by step 4's lookup — watched fail
- red -> green: merge-change: a disposition never cites the plan, which step 5 drops — watched fail
- red -> green: ratchet: ADR-3h4dky and the rationale list upgrade warnings and later teeth in the verification record — watched fail
- red -> green: merge-change: step 5 fills the record's Implements line from the plan's Implements value — watched fail (assertion changed)
- red -> green: merge-change: a 6a fix that touches the plan dispatches a reviewer — watched fail (extended to the 6a rationale)
- red -> green: merge-change: a later round's reviewer reads the dropped plan with git show — watched fail (extended to the rationale)
- red -> green: drop-plans: a plan path with a glob character drops only that plan, not a base plan it matches — watched fail (the glob deleted the base plan)
- red -> green: drop-plans: refuses a base that is not an ancestor of HEAD with status 2 — watched fail on the new remedy text (assertion changed)
- red -> green: merge-change: step 5 names the four fields 6c requires, and a template placeholder is missing — watched fail ("step 5 does not name the four fields")
- red -> green: verification template: a ratchet change's record is written at ratchet step 5 — watched fail
- red -> green: ratchet: upgrade step 4 fixes each failure and lists each new warning in the verification record — watched fail ("writes into a record Step 5 has not written"; assertions changed)
- red -> green: ratchet: the upgrade notes withdraw prune_plans — watched fail ("does not say to delete the stale prune-plans.sh"; assertion added)
- red -> green: ratchet: the upgrade notes say ledger files are named at creation, and how to rename a draft in flight — watched fail ("the upgrade does not delete finalize-docs.sh and prune-plans.sh"; assertion changed)

## What was wrong, and what was built

Every plan reached `main` and stayed there: 247k words in this repository, 366k in organisational-data-sovereignty, drifting from the code as review fixed the code and not the plan. ADR-bh4xgr pruned only the code fences.

Built:

- `scripts/drop-plans.sh --base <local base>`: removes the plans the change added and restores each base plan it edited, in one unsigned `chore: drop plans` commit naming only those paths (literal pathspecs). It refuses, before changing anything, a git-quoted path, a status other than A/M/D, a plan with uncommitted edits, a base that is not an ancestor, the base branch and a detached HEAD.
- `merge-preflight.sh` check `PLANS` (third; skipped under `--before-review`): fails on any plan the change adds, edits or retypes against `refs/heads/<base>`, reading git's stdout only.
- `prune-plans.sh` and its tests deleted; `prune_plans` is a withdrawn config key whose presence exits 2 naming the remedy.
- `merge-change`: step 1 only merges; step 4 reads a dropped plan through the `chore: drop plans` commit; step 5 writes or updates the record (now with an `Implements:` line) and then drops the plans; no `Plan:` trailer. `verify-before-merge` checks 4 and 8 read the record. A fix after step 5 writes its lines into the record.
- `ratchet`: step 5 writes the change's record early with `## Tool qualification`; upgrade warnings and a retrofit's adoption order go into the record; the upgrade deletes a stale `prune-plans.sh`. ADR-3h4dky rewritten in place to match.
- AGENTS.md, `plan-change`, `develop-change`, the templates, README and `docs/CODE_GUIDELINES.md` follow. ADR-bh4xgr is `superseded by ADR-k3nkv3`.
- Ruled by the maintainer: a test verifies a REQ, an LLR or an ADR (TEST and ARCHITECTURE guidelines); an existing plan-decision citation stands until this repository's requirements ledger replaces it. A ratchet change's record is written early.

## Guideline reviews

- TEST: 4 rounds. Round 1: 1 medium (Seams 1–3 let a test verify a plan decision; ruled REQ/LLR/ADR, fixed), 2 low (missing ADR citations, fixed; a forced rename of a source-structure pin, no change — it has no command-line seam). Round 2: 1 medium (edited tests citing plan decisions; the clause now lets an existing citation stand, fixed). Round 3: 1 medium (a citation of ADR-k3nkv3 on a call-site test the ADR does not state, removed), 1 low (the same structural pin, no change). Round 4: no findings.
- CODE: 3 rounds, all low: names (`_k`, `change`, `current`, `line`, `report`, `path`, `commit`), a one-entry list, an `a && b || c`, history comments, an unrecorded `|| true`, a silent skip of status T, untested refusals; all fixed. A note acted on: PLANS read git's stderr as plan paths, fixed.
- ARCHITECTURE: 3 rounds. Round 1: 1 low ("retired" reused for a config key; now "withdrawn"), fixed. Round 2: 1 medium (Constraints 1 said "plan decision"; ruled REQ/LLR/ADR), fixed. Round 3: 1 low (the plan said "retired"), fixed.

## Findings

1. fixed — requirement, medium (step 4 round 1): the gate read the plan after step 5 dropped it; checks 4 and 8 read the record.
2. fixed — code, medium (round 1): PLANS and the drop compared against `origin/<base>` while the squash lands on the local base; both use the local base.
3. fixed — requirement, low (round 1): a fix after step 5 had nowhere to write its `red -> green:` lines; it writes them into the record.
4. fixed — requirement, low (round 1): a second drop printed no `git show` command; step 4 names the drop-commit lookup.
5. fixed — requirement, low (round 1): ratchet pointed later teeth at the dropped gap analysis.
6. fixed — requirement, low (round 1): ratchet word-budget cuts lost the default-branch note and "must configure" signing; restored.
7. fixed — code, low (round 1): a partial `git rm` or a silent overwrite of uncommitted plan edits; refused before anything changes.
8. fixed — record (round 1): the plan's T1 note said two refusals had no test.
9. fixed — requirement, medium (round 2): the record had no `Implements:` line, making check 4 circular; added.
10. fixed — requirement, medium (round 2): the qualification checklist had no home between ratchet step 5 and merge-change step 5; superseded by finding 15.
11. fixed — requirement, low (round 2): drop-plans.sh named "the ref step 1 merged".
12. fixed — requirement, low (round 2): a 6a fix touching "the plan" was exempt from review.
13. fixed — requirement, low (round 2): step 1 lost "then rerun".
14. fixed — code, low (round 2): the drop commit's pathspec limit was untested with staged unrelated work.
15. fixed — requirement, medium (round 3): greenfield and upgrade ratchet changes write no plan; ruled by the maintainer: ratchet step 5 writes the record early, merge-change step 5 writes or updates it.
16. fixed — requirement, medium (round 3): ADR-3h4dky still put upgrade warnings in a plan; rewritten in place.
17. fixed — requirement, low (round 3): the 6a rationale still exempted a fix touching the plan.
18. fixed — requirement, low (round 3): a step 5 rerun took its inputs from the dropped plan; it updates the record and reads the plan by the lookup.
19. fixed — requirement, low (round 3): the rationale named "the git show command step 5 prints last".
20. no change — requirement, low (round 3): ADR-f6ytg7 says the record keeps "the change and plan"; the deletion change rewrites that ADR.
21. fixed — requirement, low (round 3): a disposition citing the plan fails `review_cite`; a disposition never cites the plan.
22. fixed — code, low (round 4): plan paths were read as globs; literal pathspecs.
23. fixed — code, low (round 4): the not-an-ancestor remedy now says to rerun from step 1.
24. fixed — requirement, low (round 4): step 5 names the four required fields.
25. fixed — requirement, low (round 4): a template placeholder counts as missing.
26. fixed — requirement, low (round 4): ratchet wrote into the record before Step 5 created it.
27. fixed — requirement, low (round 4): the upgrade left a stale `prune-plans.sh`.
28. fixed — requirement, low (round 4): the template said only merge-change step 5 writes the record.
29. fixed — code (step 6a gate, 1479/1480): `scripts/drop-plans.sh` was committed as mode 100644 and `tests/check-trace.bats` "every script is executable in the index, not just runnable via sh" failed; the mode is now 100755, content unchanged. The existing test went from red at the gate to green; no test was added.
30. fixed — record (round 5): this record did not cover the gate failure or round 5.

## Gaps

- `skills/verify-before-merge/SKILL.md:106` still says the record is "written at `merge-change` step 5"; change 3 (record-in-message) replaces the record.
- `skills/merge-change/SKILL.md` is at 2,000 words: change 3 must cut before it adds.
