# Problem reports — the claim that IDs are allocated against nothing

One item found by the independent review of `agent-first-skills`, round 5, in
text that predates that change. `affects:` names files, because guardrails
keeps no REQ/SDD/LLR ledger of its own. Change 3 of
`docs/plans/2026-09-28-agent-first-skills.md` rewrites most of these files.

**PR-2jr4pj**: Files across the toolkit state that an item ID is allocated against nothing, and some that two branches cannot mint the same ID by construction or can never contend for one, but `new-id.sh` discards a candidate already in the tree and a collision with another branch is possible and is detected by `DUPLICATE-ID`.
affects: scripts/check-ids.sh, the header paragraph on the base-branch gate; scripts/finalize-docs.sh, the header paragraph on IDs; AGENTS.md, non-negotiable 5; skills/ratchet/SKILL.md, the upgrade note on random IDs; skills/worktree-discipline/SKILL.md, "Mint the ID now"; templates/AGENTS-block.md; templates/problems.md; templates/srs.md; docs/problems/README.md; README.md, the paragraph on item IDs. The list is the sites found by `git grep -n 'against nothing'` outside `docs/plans` and `docs/verification` on 2026-09-29; re-run it rather than trusting a count.
opened: 2026-09-29
status: open
The `scripts/new-id.sh` header states the behaviour exactly: collisions are
detected, not prevented, with a stated probability. The other texts overstate
it. `scripts/check-ids.sh` names the collision case in the same sentence as
"vanishing", so the gate is right and the prose around it is not. The
`merge-change` reference file for `agent-first-skills` names no script, so it
points into none of these texts.
