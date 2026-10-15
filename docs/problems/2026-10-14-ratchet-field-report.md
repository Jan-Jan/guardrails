# Problem report — a `/ratchet` upgrade field report

Reported by an adopter on 2026-10-14, from a `/ratchet` upgrade of a six-unit
project from `35570e8` to `6a9d6eb` on macOS (zsh, GNU parallel, bats vendored).
`affects:` names files, because guardrails keeps no REQ/SDD/LLR ledger of its
own. The report's second point is PR-ww36qr, already open; the adopter's three
ratchet records all hit it.

**PR-y8ff5p**: `ratchet` step 5 runs the qualification suite against the guardrails checkout's live working tree and records `git rev-parse HEAD` as the commit it qualified, so a commit made in that checkout during the run yields a result that describes no commit, and nothing reports it.
affects: skills/ratchet/SKILL.md step 5 (tool-qualification checklist item) and the copy steps that read scripts/ and templates/ from the same tree; tests/run-tests.sh.
opened: 2026-10-14
status: resolved
Resolved: the suite and the copies read the checkout's live tree; `ratchet` step 0 now clones the checkout and reads only the clone, and `tests/run-tests.sh` names on standard error the commit it tests and fails a run whose tree changed while bats ran, which step 5 requires the log to show. Reproduced by "run-tests: a clean checkout names the commit it tests", "run-tests: a tree changed during the run fails the run, though every test passed" and "run-tests: a commit made during the run fails the run" in `tests/run-tests.bats`; the skill is pinned by "ratchet: step 0 clones the checkout before reading it, and finds it through .guardrails-source" and "ratchet: the qualification log must name the recorded commit" in `tests/skills.bats`.
The adopter's run took 17:27 to 17:46; `bb249ca` was committed in the
guardrails checkout at 17:39. The suite reported 1398 ok and 3 not ok, all in
`tests/skills.bats` (1109, 1153, 1179), and all three pass on a clean
`git archive 6a9d6eb` export and on `bb249ca`. The log mixes the two trees:
1109 already carries `bb249ca`'s assertions while 1153 still carries its
`6a9d6eb` name. The recorded `guardrails_commit` was `6a9d6eb`.

**PR-783b29**: `ratchet` step 0 locates the guardrails checkout as the repository two levels above its `SKILL.md`, which after `install.sh --copy` is the skills directory's parent (such as `~/.claude`), so the agent finds no `scripts/` or `templates/` and has to search for the checkout.
affects: skills/ratchet/SKILL.md step 0; install.sh `--copy` mode, which records nothing about where a copy came from. Related to PR-z6uaa8, which records that nothing reports an installed copy's drift from its source.
opened: 2026-10-14
status: resolved
Resolved: a copied skill had no record of its checkout; `install.sh --copy` now writes the checkout's path to `.guardrails-source` in each copied skill, and `ratchet` step 0 reads it before falling back to the repository two levels up. Reproduced by "install: --copy records the checkout in every copied skill" in `tests/install.bats`; the skill is pinned by "ratchet: step 0 clones the checkout before reading it, and finds it through .guardrails-source" in `tests/skills.bats`.

Two items the independent review of this change raised at low severity,
recorded and not fixed.

**PR-v6mcvt**: `ratchet` step 5 keeps the qualification log at `<tmp>/ratchet.log`, inside the temporary directory step 0 creates, which the operating system may purge, so the log the setup document's suite result rests on can disappear.
affects: skills/ratchet/SKILL.md step 5; skills/ratchet/references/rationale.md; skills/ratchet/references/setup-checklist.md.
opened: 2026-10-14
status: open
Where the log should live durably is a decision about what an adopter's
repository stores (a TAP log of about 1,500 lines beside
`docs/plans/<date>-ratchet-setup.md`, or only its summary), and step 5 has no
words left under the 2,000-word cap to state it.

**PR-92mbhq**: `ratchet` step 0 says nothing for a `.guardrails-source` that names a directory that no longer exists or lacks `templates/` and `scripts/`, and its fallback, two levels above the SKILL.md, is wrong for a copied skill, so an agent whose checkout moved is back to searching for it.
affects: skills/ratchet/SKILL.md step 0; install.sh `--copy`.
opened: 2026-10-14
status: open
The remedy is to re-run `install.sh --copy` from the checkout's new place,
after deleting the old copies, since `install.sh` skips an existing directory.
Related to PR-z6uaa8.
