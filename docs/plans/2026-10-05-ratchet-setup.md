# Ratchet setup checklist — guardrails, second pass

Date: 2026-10-05
Guardrails version: 0.5.1, commit `35570e8`
Safety class: A (`docs/adr/ADR-q54hjw-safety-class.md`)
Gap analysis: `docs/plans/2026-10-05-ratchet-gap-analysis.md`

Supersedes `docs/plans/2026-08-22-ratchet-setup.md`, whose signing entries
describe an SSH key this repository no longer signs with. The machinery
install is still deferred (gap analysis §6, tooth 1); items marked
*(after tooth 1)* wait for `.guardrails/`.

- [ ] Commit signing key: `gpg.format openpgp`, hardware key, one touch per
      signature. Configured; the proof is the item "Prove the chain" below.
- [ ] Signature verification: OpenPGP signatures verify against the keyring.
      The 22 SSH-signed commits on `main` read `N` because
      `gpg.ssh.allowedSignersFile` is no longer configured. Restore an
      `allowed_signers` file listing the retired SSH keys, bounded by
      `valid-before`, and point `gpg.ssh.allowedSignersFile` at it.
- [ ] **Prove the chain:** run `sh scripts/check-signing.sh --setup` in a
      terminal you launched (an agent shell times out waiting for the touch,
      and its `~/.gnupg` is read-only). After tooth 1 the same check runs as
      `.guardrails/scripts/check-signing.sh --setup`. It must exit 0 before
      tooth 1 merges.
- [ ] Branch protection on `main`: no direct pushes, require signed commits.
      The user's, at the forge (AGENTS.md non-negotiable 5).
- [ ] CI: run `sh tests/run-tests.sh`, `check-ids.sh`, `check-trace.sh` and
      `check-signing.sh --strict main..HEAD` on every merge, as a backstop for
      what `finish-merge.sh` enforces on the merging machine. Not
      `check-review.sh`: on the base branch it exits 2; in pull-request CI run
      `check-review.sh --branch <head-branch>`. *(after tooth 1)*
- [ ] Review policy: single committer. The independent reviewer at
      `merge-change` step 6a is a fresh subagent with no implementation
      narrative, as every record in `docs/verification/` since 2026-07-20
      shows; a human reviewer where the user asks for one. Class A permits
      skipping step 6a; this repository does not skip it.
- [x] Coverage: no `coverage_command`. Class A has no coverage target.
- [ ] **Tool qualification (DO-330-lite):** the check scripts are verification
      tools; their failure could mask errors in projects that use them.
      Qualification basis: the guardrails bats suite at `guardrails_version`
      0.5.1 and `guardrails_commit` `35570e8`. Suite result, measured: the
      gate of this change at commit `88ac428` (tree
      `c21377f52428a81d3b38f6ef83782d442766a49a`), whose
      `scripts/` and `tests/` are identical to `35570e8`
      (`git diff --stat 35570e8 88ac428 -- scripts tests` prints nothing):
      `1..1053`, 1053 `ok`, 0 `not ok`, 0 skipped, counted from the TAP
      lines. The exit status was not captured: the skill's `status=$?` fails
      in zsh, where `status` is read-only (`PR-ww36qr`). The final gate is
      recorded in `docs/verification/2026-10-05-ratchet-self-host.md`,
      written before the squash, with the suite totals. Once tooth 1
      installs `.guardrails/scripts/` as a pinned copy (gap analysis §4), the
      installed copy is never edited; an upgrade is a change of its own that
      re-records version, commit and suite result.
- [ ] **Guardrails supports a QMS but is not itself regulatory compliance.**
      The quality manual, design controls and human sign-offs govern.
