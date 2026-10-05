# Problem report — `ratchet` captures the suite's exit status in zsh's read-only `status`

Found by `ratchet-self-host` in its first gate run, on 2026-10-05, in a zsh
shell. `affects:` names files, because guardrails keeps no REQ/SDD/LLR ledger
of its own. This change records the item and does not fix the skill.

**PR-ww36qr**: `ratchet` step 5 tells the agent to run `tests/run-tests.sh > ratchet.log 2>&1; status=$?`, and in zsh the assignment to the read-only special parameter `status` fails, so the suite's exit status is never recorded.
affects: skills/ratchet/SKILL.md, step 5 (Human setup checklist), the tool-qualification paragraph.
opened: 2026-10-05
status: open
`skills/ratchet/SKILL.md` line 233 reads
`tests/run-tests.sh > ratchet.log 2>&1; status=$?` and directs the agent to
"read `$status` first". In zsh, `status` is a read-only special parameter that
mirrors `$?`. `zsh -c 'true; status=$?'` prints
`zsh:1: read-only variable: status` and exits 1. In a non-interactive zsh the
error aborts the script. In an interactive zsh the next command reads
`$status` as 1, the status of the failed assignment, whatever the suite
returned: after `true; status=$?`, `echo $status` prints `1`. A passing suite
then reads as failed, and the suite's real status is lost either way. The
2026-10-05 gate of `ratchet-self-host` counted its result from the TAP lines
instead. The skill's instruction needs a variable name that is not special in
any common shell, such as `suite_status`.
