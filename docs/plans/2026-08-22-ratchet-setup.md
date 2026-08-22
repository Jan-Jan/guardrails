# Ratchet setup checklist — guardrails

Date: 2026-08-22
Guardrails version: 0.2.0
Safety class: A (`docs/adr/2026-08-22-safety-class.md`)

Items requiring a human. The machinery install is **deferred** — see
`docs/plans/2026-08-22-ratchet-gap-analysis.md` §4 for why, and §5 for the
order. Items below marked *(after tooth 1)* cannot be completed until
`.guardrails/` exists.

## Signing

- [x] **Commit signing key** — already configured and working (hardware
      FIDO2 key `id_ecdsa_sk`; each signature needs a physical touch). 11 of the 12
      commits on the base branch are signed and verify (`%G? = G`); only the
      initial `chore: repo skeleton` predates it. Nothing to do.
- [x] **Signature verification** — already configured. `gpg.ssh.allowedSignersFile`
      points at `~/.ssh/allowed_signers`, which lists the current hardware key
      and the retired pre-rotation key bounded by `valid-before="20260820"` so
      that history signed with the lost key still verifies while the dead key
      cannot validate anything new. `check-signing.sh` verifies rather than
      warning (exit 0 on HEAD, no `WARN-UNVERIFIED`).
- [ ] **Enable `--strict` in CI.** Nothing blocks this any more — it was the
      only thing the missing signers file was holding up. See the CI section.

## Branch protection

- [ ] Protect the base branch: no direct pushes, require signed commits.
      The repo has followed this by hand across 12 commits; it is not
      currently enforced by the forge.

## CI — none exists today

- [ ] Create a pipeline. There is no `.github/` or any other CI config, so
      every check in this repo currently runs only when someone runs it. It
      should run on every merge:

      ./tests/run-tests.sh
      .guardrails/scripts/check-ids.sh                      # after tooth 1
      .guardrails/scripts/check-trace.sh                    # after tooth 1
      .guardrails/scripts/check-signing.sh --strict <base>..HEAD

      `check-signing.sh --strict` can be enabled immediately — the
      `allowed_signers` file is already in place. It does not wait for tooth 1.
- [ ] *(after tooth 1)* If `.guardrails/scripts/` is installed as a copy rather
      than a symlink, add a CI step asserting it is byte-identical to
      `scripts/`. `AGENTS.md` forbids forking script logic, and an unchecked
      copy drifts silently. See gap analysis §3.4.

## Review policy

- [ ] Decide who signs off on merges, and who acts as the independent reviewer
      in `merge-change` step 6a when a human is preferred over a fresh agent.
      This repo is currently single-committer, so the realistic answer is a
      fresh agent for routine changes — but record the decision rather than
      leaving it implicit, and note that independent review has already caught
      real defects here (see the ADR).

## Coverage

- [ ] No `coverage_command` is configured, and none is required: Class A has no
      coverage target. Recorded here deliberately, because the managed AGENTS
      block asks projects without one to say why.

## Tool qualification (DO-330-lite)

- [x] The scripts in `scripts/` are verification tools whose failure could mask
      errors in projects that use them. Qualification basis: the guardrails
      bats suite at the `guardrails_version` recorded in config.
      **Measured 2026-08-22 at version 0.2.0: 212/212 passing, 0 failures.**
      Re-record both whenever `/ratchet` updates the scripts.
- [ ] Note the self-hosting subtlety: for this repo the tool under
      qualification and the tool doing the qualifying are the same code. That
      is not circular for the suite itself — bats is the external judge — but
      it does mean `check-trace.sh` reporting a clean tree here is weaker
      evidence than it would be in a downstream project. Treat the bats suite,
      not the check run, as the qualification evidence.

## Scope reminder

- [ ] **Guardrails supports a QMS; it is not itself regulatory compliance.**
      Your quality manual, design controls and human sign-offs govern. Keep
      notified-body and auditor requirements authoritative. This applies to
      guardrails' own development too: Class A here is a statement about a
      developer tool, not a claim about any device that uses it.
