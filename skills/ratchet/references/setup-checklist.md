# The human setup checklist

Read this at `ratchet` step 5: copy the checklist below, fill in the
qualification basis, then print it and save it to
`docs/plans/<YYYY-MM-DD>-ratchet-setup.md`.

- [ ] Commit signing key: `git config gpg.format ssh`,
      `git config user.signingkey <key>`, `git config commit.gpgsign true`
      (GPG works too; leave `gpg.format` unset for OpenPGP, whose default it
      is). Hardware keys require a physical touch per signature.
- [ ] Signature verification: create an allowed_signers file listing each
      committer (`<email> <key-type> <public-key>`), then
      `git config gpg.ssh.allowedSignersFile <path>`. Without it every
      signature reads as unverifiable, which `--strict` rejects.
- [ ] **Prove the chain, and only then is the ratchet done:**
      `.guardrails/scripts/check-signing.sh --setup` must exit 0. It checks
      that `user.signingkey`, `commit.gpgsign`, `user.email` and the format's
      trust root are set and readable, then makes a real signed commit in a
      throwaway repository and confirms it reads `%G?` = `G`. Exit 1 is a
      failed proof, exit 2 a usage or environment error. Each missing piece is
      reported separately; work through them in order.
- [ ] Branch protection on the base branch: no direct pushes, require signed
      commits.
- [ ] CI: run `verify_commands`, `check-ids.sh`, `check-trace.sh`, and
      `check-signing.sh --strict <base>..HEAD` on every merge, as a backstop
      for what `finish-merge.sh` already enforced on the merging machine.
      **Not `check-review.sh`**: on the base branch it exits 2. It runs from
      the change worktree at `merge-change` step 6c; in pull-request CI, name
      the branch: `check-review.sh --branch <head-branch>`.
- [ ] Decide the human review and approval policy for merges (who signs off),
      including who acts as the independent reviewer in `merge-change`
      step 6a when a human is preferred over a fresh agent.
- [ ] Install GNU `parallel` (`brew install parallel` on macOS,
      `apt install parallel` on Debian-family systems). `tests/run-tests.sh`
      then runs the qualification suite with one bats job per CPU; without
      it the suite runs serially and takes several times longer.
- [ ] **Tool qualification (DO-330-lite):** the `.guardrails/scripts/` are
      verification tools; their failure could mask errors. Qualification
      basis: the guardrails bats suite at `guardrails_version` <version> and
      `guardrails_commit` <commit>. Suite result at install time: <pass, fail,
      or `suite not run at install time: <reason>`>. Do not modify the scripts
      in this project; change them upstream where the tests are.
- [ ] **Guardrails supports your QMS but is not itself regulatory
      compliance.** Your quality manual, design controls and human sign-offs
      govern; keep your notified-body and auditor requirements authoritative.
