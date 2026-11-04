# Problem report — a `/ratchet` upgrade field report

Reported by an adopter on 2026-10-14, from a `/ratchet` upgrade of a six-unit
project from `35570e8` to `6a9d6eb` on macOS (zsh, GNU parallel, bats vendored).
`affects:` names files. The report's second point, that zsh's read-only `status` loses the
suite's exit status, was already recorded; the adopter's three ratchet
records all hit it.

**PR-v6mcvt**: `ratchet` step 5 keeps the qualification log at `<tmp>/ratchet.log`, inside the temporary directory step 0 creates, which the operating system may purge, so the log the setup document's suite result rests on can disappear.
affects: skills/ratchet/SKILL.md step 5; skills/ratchet/references/rationale.md; skills/ratchet/references/setup-checklist.md.
opened: 2026-10-14
status: accepted
disposition: ruled on 2026-10-30 — the qualification figure goes into the squash message; the log is not kept.
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
