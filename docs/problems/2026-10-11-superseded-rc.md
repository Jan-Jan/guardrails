# Problem report — a superseded risk control reports UNIMPLEMENTED-CONTROL

Reported by a class B adopter upgrading from 17a0d58 to 1967dc8. `affects:`
names files, because guardrails keeps no REQ/SDD/LLR ledger of its own.

**PR-x63ejd**: After the out-of-force change (dd411a1), an RC superseded by a reciprocal pair, whose implementing REQ was superseded with it, reports `UNIMPLEMENTED-CONTROL`: D3 stops the out-of-force REQ's `implements:` crediting the RC, but D1 defines out of force for REQ and LLR only, so the superseded RC still owes an in-force REQ, and the project can turn green only by claiming behavior the software deliberately does not have or by deleting the supersession record.
affects: scripts/check-trace.sh (UNIMPLEMENTED-CONTROL, UNMITIGATED-HAZARD, oof_scan), docs/plans/2026-10-08-out-of-force-items.md (D1, D3), skills/ratchet/references/upgrade-notes.md (Out-of-force items), skills/grill-requirements/references/supersession.md.
opened: 2026-10-11
status: resolved
Root cause: `oof_scan` opened blocks on REQ and LLR only and read the SRS and
SAD alone, so an RC's reciprocal supersession pair was never read, while D3
dropped the out-of-force REQ's credit. Fixed by
docs/plans/2026-10-11-superseded-risk-controls.md: an RC superseded by a
reciprocal pair with another RC is out of force, owes no `implements:`, and
its `mitigates:` mitigates nothing. Reproduced by `check-trace: a superseded
RC owes no implementing requirement` (tests/check-trace.bats), watched failing
first on UNIMPLEMENTED-CONTROL RC-46yapu.

**PR-ad4vmm**: `tests/check-signing.bats` fails "the verifier's reason is reported once, under its verdict" on every run on a host whose `~/.gitconfig` sets `gpg.ssh.allowedSignersFile`, because the test fixtures read the user's global and system git config, so a setting the test unsets in the fixture repository falls back to the user's own.
affects: tests/helpers.bash (make_fixture_repo, setup_ssh_signing), tests/check-signing.bats.
opened: 2026-10-11
status: resolved
Root cause: the bats helpers left git reading the global and system config, so
`git config --get` in a fixture fell back to `~/.gitconfig` once a test unset
the fixture's own setting. Fixed by tests/helpers.bash, which exports
`GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_SYSTEM=/dev/null` and
`GIT_CONFIG_NOSYSTEM=1` for every test (git 2.32 or later). Reproduced by
`check-signing: a fixture reads no global or system git config`
(tests/check-signing.bats), watched failing first on the scratch global
config's trust root; on the test-guidelines review it was moved to the
script seam as `check-trace: the host's global or system git config does
not change the verdict` (tests/check-trace.bats), reddened by removing the
export from tests/helpers.bash. Local `main` resolved the same symptom for
`tests/check-signing.bats` alone as PR-gw6wts (cfa82e1); this fix extends the
isolation to every test file. The intermittent "a verifier that cannot run is not
called a forgery" has a separate cause this does not fix: under load the
stub verifier exits before git writes to it, `git log` dies of SIGPIPE
(exit 141, 84 of 300 calls with every CPU busy), and the empty `%G?` falls to
WARN-UNVERIFIED; recorded as PR-nhf8cy.

**PR-nhf8cy**: `check-signing.sh` gives a timing-dependent verdict on a signed commit whose verifier cannot run: when `git log --format=%G?` dies (a verifier that exits without reading its input makes git exit 141 on SIGPIPE under load, 84 of 300 calls with every CPU busy), the empty `%G?` falls to the `*)` branch and prints WARN-UNVERIFIED with exit 0, where the same commit on an idle machine reads `B` and exits 1; `check-signing: a verifier that cannot run is not called a forgery` fails intermittently on it.
affects: scripts/check-signing.sh (check_commits), tests/check-signing.bats (break_the_verifier stub).
opened: 2026-10-11
status: resolved
Duplicate of PR-8zcc72, recorded and fixed on local `main` by cfa82e1
(`docs/problems/2026-10-11-linux-suite.md`) while this change was open: a
failed `git log` on a signed commit is UNVERIFIED in both modes, and the test
stub reads its payload. This change merged that fix from local `main` and
withdrew its own script change and tests for the same defect in its favor;
the reproduction is `check-signing: a verdict git could not compute fails
without --strict`.

**PR-qm5gfy**: `check-signing.sh` decides whether a commit carries a signature by matching `^gpgsig` against the whole commit object, message included, so an unsigned commit whose message has a line starting with `gpgsig` is read as signed: with `%G?` = `N` the default mode prints WARN-UNVERIFIED and exits 0 instead of UNSIGNED.
affects: scripts/check-signing.sh (check_commits: the `*)` branch, and the `failed` branch added for PR-8zcc72).
opened: 2026-10-11
status: resolved
Root cause: both places in `check_commits` that ask whether a commit carries a
signature ran `grep '^gpgsig'` over the whole `git cat-file commit` output,
whose message follows the header after the first empty line. Fixed by
scripts/check-signing.sh: one function, `carries_signature`, reads the header
only (`sed '/^$/q'`) and serves both the `failed` condition and the `*)`
branch; `gpgsig-sha256` still counts. Reproduced by `check-signing: a gpgsig
line in the message does not make a commit signed` (tests/check-signing.bats),
watched failing first on WARN-UNVERIFIED with exit 0. The lost-letter half has
no reproduction: git calls no verifier for an unsigned commit, so `git log`
cannot die there, and the `failed` branch is reached only through a seam this
change does not invent; the shared function covers it.
