# Problem reports — ratchet tool-qualification recording

`affects:` names files rather than item IDs for the reason
`docs/problems/2026-08-27-macos-awk.md` gives: guardrails keeps no
REQ/SDD/LLR ledger of its own yet. When the ledgers arrive, these lines get
the IDs.

**PR-ac96zf**: The ratchet setup checklist requires recording the
qualification suite result at install time but never says where or how the
suite runs, so a `/ratchet` run in a target project is left to improvise —
up to and including installing bats into the target project or running the
guardrails suite there.
affects: skills/ratchet/SKILL.md step 5 (tool-qualification checklist item)
only — investigation confirmed the pieces the item leans on already conform:
tests/run-tests.sh vendors bats-core when no system bats exists,
`tests/.bats-core` is gitignored, and `guardrails_version` is a schema key
in templates/config.yaml and scripts/lib.sh.
owner: Dr. Jan-Jan van der Vyver
opened: 2026-08-30
status: resolved
The step-5 checklist item named the qualification basis and what the setup
document records, but omitted the procedure that produces the suite result —
so nothing forbade producing it in the target project or installing bats to
do so. The item now states the procedure: run `<guardrails>/tests/run-tests.sh`
exactly once upstream, record the outcome (version, commit, pass/fail), and
record `suite not run at install time: <reason>` when the run cannot complete.
Reproduced by `tests/skills.bats:ratchet: tool qualification says how and
where the suite runs`, which was red before the paragraph existed.
