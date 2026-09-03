load helpers

setup() { make_fixture_repo; }

# Configure throwaway SSH signing for the fixture repo.
setup_ssh_signing() {
    ssh-keygen -t ed25519 -N '' -f "$BATS_TEST_TMPDIR/sign_key" -q
    git config gpg.format ssh
    git config user.signingkey "$BATS_TEST_TMPDIR/sign_key"
    printf 'test@example.com %s\n' "$(cut -d' ' -f1-2 < "$BATS_TEST_TMPDIR/sign_key.pub")" \
        > "$BATS_TEST_TMPDIR/allowed_signers"
    git config gpg.ssh.allowedSignersFile "$BATS_TEST_TMPDIR/allowed_signers"
}

signed_commit() {
    printf '%s\n' "$1" > "src/$1.txt"
    git add -A
    git -c commit.gpgsign=true commit -qS -m "signed $1"
}

# A verifier that cannot run. Not a corrupted signature: the signature is real
# and the program that would check it fails to start, which is the shape the
# maintainer's machine was in (gpg dying on an unwritable trustdb). git cannot
# tell the two apart — %G? is `B` for both — so the verifier's own words are
# the only thing that can.
break_the_verifier() {
    printf '#!/bin/sh\necho "stub verifier: trust store unavailable" >&2\nexit 2\n' \
        > "$BATS_TEST_TMPDIR/broken_verifier"
    chmod +x "$BATS_TEST_TMPDIR/broken_verifier"
    git config gpg.ssh.program "$BATS_TEST_TMPDIR/broken_verifier"
}

@test "check-signing: unsigned commit fails with UNSIGNED" {
    run sh .guardrails/scripts/check-signing.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNSIGNED"* ]]
}

@test "check-signing: ssh-signed commit with allowed signers passes" {
    setup_ssh_signing
    signed_commit a
    run sh .guardrails/scripts/check-signing.sh
    [ "$status" -eq 0 ]
}

@test "check-signing: signed but unverifiable warns and passes" {
    setup_ssh_signing
    signed_commit a
    git config --unset gpg.ssh.allowedSignersFile
    run sh .guardrails/scripts/check-signing.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"WARN-UNVERIFIED"* ]]
}

@test "check-signing: --strict fails on unverifiable signature" {
    setup_ssh_signing
    signed_commit a
    git config --unset gpg.ssh.allowedSignersFile
    run sh .guardrails/scripts/check-signing.sh --strict
    [ "$status" -eq 1 ]
}

@test "check-signing: range form checks every commit" {
    setup_ssh_signing
    git checkout -qb feature
    signed_commit a
    printf 'b\n' > src/b.txt
    git add -A
    git -c commit.gpgsign=false commit -qm "unsigned b"
    run sh .guardrails/scripts/check-signing.sh main..feature
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNSIGNED"* ]]
}

@test "check-signing: a failed verdict carries the verifier's own reason" {
    # verifies: PR-whkz8m
    # `git log --format=%G?` returns a letter and throws the verifier's output
    # away — measured, zero bytes on stderr. Before this, the script filled the
    # gap by GUESSING a cause: it appended the ssh trust-root remedy to every
    # verdict alike, including the OpenPGP commits that never read that
    # setting. The real cause was one command away the whole time.
    setup_ssh_signing
    signed_commit a
    break_the_verifier
    run sh .guardrails/scripts/check-signing.sh
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"stub verifier: trust store unavailable"* ]] \
        || { echo "the verifier's reason was discarded: $output"; false; }
}

@test "check-signing: a verifier that cannot run is not called a forgery" {
    # verifies: PR-74gcqg
    # %G? is `B` both for a signature that was checked and rejected and for a
    # verifier that never ran. Saying "bad, expired, or revoked" of the second
    # accuses the signer of something the tool did not measure.
    setup_ssh_signing
    signed_commit a
    break_the_verifier
    run sh .guardrails/scripts/check-signing.sh
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" != *"bad, expired, or revoked"* ]] \
        || { echo "still asserts a cause it did not measure: $output"; false; }
    [[ "$output" != *"UNSIGNED"* ]] \
        || { echo "a signed commit was reported UNSIGNED: $output"; false; }
    [[ "$output" == *"UNVERIFIED"* ]] || { echo "$output"; false; }
}

@test "check-signing: a rejected signature still fails without --strict" {
    # Deliberately carries NO `verifies:` annotation, and that is the finding
    # rather than an oversight. It was green on its first run, before the
    # script was touched, and could not have been otherwise: the old `B` branch
    # already failed in both modes with no `WARN-` prefix, so both assertions
    # held against it. It therefore verifies nothing about PR-74gcqg — the test
    # above does, and that one was watched failing. Annotating it anyway would
    # put a `verifies:` line behind no red->green attestation, which is the one
    # thing `develop-change`'s iron law forbids. What it IS is a pin: the
    # wording changed, the verdict must not, and the tolerant mode must not
    # start passing a signature the verifier refused.
    setup_ssh_signing
    signed_commit a
    break_the_verifier
    run sh .guardrails/scripts/check-signing.sh
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" != *"WARN-"* ]] || { echo "tolerated a refusal: $output"; false; }
}

@test "check-signing: the verifier's reason is reported once, under its verdict" {
    # verifies: PR-whkz8m
    # `git log --format=%G?` leaks git's OWN diagnostic to stderr for an ssh
    # signature and leaks nothing for an OpenPGP one. Unindented and printed
    # before the verdict, that copy reads as a separate failure — and it
    # appears for only one of the two formats, which is the asymmetry this
    # whole change removes. The reason belongs under the verdict it explains,
    # once, put there by this script.
    setup_ssh_signing
    signed_commit a
    git config --unset gpg.ssh.allowedSignersFile
    run sh .guardrails/scripts/check-signing.sh
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [[ "$output" == *"allowedSignersFile"* ]] \
        || { echo "the reason went missing entirely: $output"; false; }
    # "once" is half the claim in the name and the whole of PR-52rnrn's
    # resolution, and nothing here measured it: two indented copies passed
    # every other assertion in this test unchanged. Counted, not eyeballed.
    n=$(printf '%s\n' "$output" | grep -c 'allowedSignersFile')
    [ "$n" -eq 1 ] || { echo "the reason appeared $n times, not once: $output"; false; }
    if printf '%s\n' "$output" | grep -q '^error:'; then
        echo "git's own diagnostic leaked, unindented, above the verdict: $output"
        false
    fi
}

@test "check-signing: an untrusted signature carries the verifier's reason too" {
    # verifies: PR-whkz8m
    # The third of the three places the reason is printed, and the only one no
    # test reached. Measured, because this change exists to stop a tool
    # asserting a cause nobody read: of the other two PR-52rnrn tests, the
    # broken-verifier one lands in `B|X|Y|R` (%G? = B) and the reported-once
    # one in `*)` (%G? = N). Deleting verifier_reason from the U|E branch left
    # the whole suite green.
    #
    # A signers file that is PRESENT and READABLE — so the environment guard
    # does not fire — naming a DIFFERENT key: the signature verifies
    # cryptographically and no principal owns it. Measured 2026-09-02, that is
    # %G? = U, and git verify-commit says "No principal matched." Without the
    # reason, "signature present but did not verify" is a verdict with no cause
    # attached, and the cause here is not the one the old guessed remedy named.
    setup_ssh_signing
    signed_commit a
    ssh-keygen -t ed25519 -N '' -f "$BATS_TEST_TMPDIR/other_key" -q
    printf 'test@example.com %s\n' \
        "$(cut -d' ' -f1-2 < "$BATS_TEST_TMPDIR/other_key.pub")" \
        > "$BATS_TEST_TMPDIR/allowed_signers"
    [ "$(git log -1 --format='%G?' 2>/dev/null)" = U ] \
        || { echo "fixture no longer lands in U|E: $(git log -1 --format='%G?')"; false; }
    run sh .guardrails/scripts/check-signing.sh --strict
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"UNVERIFIED"* ]] || { echo "$output"; false; }
    # Indented, under the verdict it explains — the whole point of asking the
    # verifier rather than guessing.
    printf '%s\n' "$output" | grep -q '^    No principal matched\.$' \
        || { echo "the verifier's reason was discarded: $output"; false; }
}

@test "check-signing: --strict exits 2 when the trust root exists but cannot be read" {
    # verifies: PR-mvqm4s
    # An unverifiable signature and an environment that cannot verify any
    # signature both read %G? = U/E, and --strict reported UNVERIFIED exit 1
    # for both — "the project is wrong" — sending the operator hunting in the
    # project when the repair is in the environment. Exit 2 is the
    # environment verdict, and the message points at --setup.
    [ "$(id -u)" -ne 0 ] || skip "permission bits do not bind root"
    setup_ssh_signing
    signed_commit a
    chmod 000 "$BATS_TEST_TMPDIR/allowed_signers"
    run sh .guardrails/scripts/check-signing.sh --strict
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    [[ "$output" == *"--setup"* ]] || { echo "$output"; false; }
}

@test "check-signing: --strict stays exit 1 when the trust root path is absent" {
    # verifies: PR-mvqm4s
    # Configured-but-absent is the typo case — a path the project wrote
    # wrong, so exit 1 ("the project is wrong") is the correct verdict; only
    # present-but-permission-denied is the environment's fault.
    setup_ssh_signing
    signed_commit a
    git config gpg.ssh.allowedSignersFile "$BATS_TEST_TMPDIR/absent_signers"
    run sh .guardrails/scripts/check-signing.sh --strict
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"UNVERIFIED"* ]] || { echo "$output"; false; }
}

# --- --setup ----------------------------------------------------------------
#
# A different question from the rest of this file: not "is this history
# signed" but "can this project sign at all". Every test here signs with the
# file-based key above — a hardware key would make the suite unrunnable
# unattended, and this is the one place the answer has to be reproducible.

# Cuts the fixture off from the developer's own git configuration. `git config
# --get` reads the global and system files as well as the repository's, so on
# a machine whose owner has signing set up — which is every machine this
# toolkit is developed on — a setting these tests deliberately leave unset is
# still answered, and the test measures that person's laptop instead of the
# script.
#
# Measured, not feared: with the fixture's gpg.format unset, --setup resolved
# the developer's own ECDSA-SK key and blocked the whole suite waiting for a
# touch on a hardware token, which is not something an unattended run can give.
isolate_git_config() {
    export GIT_CONFIG_GLOBAL=/dev/null
    export GIT_CONFIG_SYSTEM=/dev/null
}

# Everything --setup needs to prove a signature: the format, the key, signing
# on by default, and a trust root naming this committer. The fixture ships
# commit.gpgsign false, so it has to be turned on explicitly. The tests below
# take one piece away at a time.
setup_proved_signing() {
    isolate_git_config
    setup_ssh_signing
    git config commit.gpgsign true
}

@test "check-signing: --setup proves a fully configured project" {
    setup_proved_signing
    run sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [[ "$output" != *MISSING* ]] || { echo "$output"; false; }
}

@test "check-signing: --setup proves it without committing in the project" {
    # The proof is a real signed commit, and the only safe place for it is a
    # throwaway repository: made in the project it would dirty the very tree
    # the merge guards are about to inspect.
    setup_proved_signing
    before=$(git rev-parse HEAD)
    run sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [ "$(git rev-parse HEAD)" = "$before" ] || { echo "HEAD moved"; false; }
    [ -z "$(git status --porcelain)" ] || { git status --porcelain; false; }
}

@test "check-signing: --setup proves a project with no commits yet" {
    # ratchet runs this while adopting guardrails, which can be the first thing
    # that ever happens in a repository. A proof that needed a commit to look
    # at could not answer there at all.
    fresh="$BATS_TEST_TMPDIR/fresh"
    git init -q -b main --template= "$fresh"
    cp -R .guardrails "$fresh/"
    cd "$fresh"
    git config user.name test
    git config user.email test@example.com
    setup_proved_signing
    run sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
}

@test "check-signing: --setup leaves no throwaway repository behind" {
    # A whole git repository per proof, kept in a tmpfs with a fixed inode
    # budget, is the same failure this suite's own teardown exists to prevent
    # — and ratchet invites the operator to run --setup until it passes.
    setup_proved_signing
    export TMPDIR="$BATS_TEST_TMPDIR/tmp"
    mkdir -p "$TMPDIR"
    run sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [ -z "$(ls -A "$TMPDIR")" ] || { echo "left behind:"; ls -A "$TMPDIR"; false; }
}

@test "check-signing: --setup fails when the key cannot sign" {
    # Configuration being present says nothing about whether the key can sign.
    setup_proved_signing
    git config user.signingkey "$BATS_TEST_TMPDIR/absent_key"
    run sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"could not be signed"* ]] || { echo "$output"; false; }
}

@test "check-signing: --setup fails when the signature does not verify" {
    # The signers file lists a key that is not the one doing the signing — the
    # shape a project lands in when a committer's key is rotated and the trust
    # root is not. Signing succeeds; verification is what fails.
    setup_proved_signing
    ssh-keygen -t ed25519 -N '' -f "$BATS_TEST_TMPDIR/other_key" -q
    printf 'test@example.com %s\n' \
        "$(cut -d' ' -f1-2 < "$BATS_TEST_TMPDIR/other_key.pub")" \
        > "$BATS_TEST_TMPDIR/allowed_signers"
    run sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"did not verify"* ]] || { echo "$output"; false; }
}

@test "check-signing: --setup with a rev range is a usage error" {
    setup_proved_signing
    run sh .guardrails/scripts/check-signing.sh --setup main..main
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    [[ "$output" == *"rev range"* ]] || { echo "$output"; false; }
}

@test "check-signing: --setup names every missing piece of the configuration" {
    # The fixture repo has no signing configuration at all. One verdict for
    # three separate gaps is two more runs than the operator needs.
    #
    # This test used to assert MISSING gpg.format here as well. That assertion
    # was removed because it was measured wrong, not because it was
    # inconvenient: git documents the default for gpg.format as openpgp, so a
    # project that never sets it HAS a format and signs perfectly well — this
    # repository's own commits are openpgp-signed with gpg.format unset
    # (PR-mtmr7h). The assertion is inverted rather than deleted, so the
    # corrected behaviour is still gated here; and the two gaps that really do
    # stop this repository signing anything, the key and commit.gpgsign, are
    # still asserted, along with the exit status.
    isolate_git_config
    run sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" != *"MISSING gpg.format"* ]] || { echo "$output"; false; }
    [[ "$output" == *"MISSING user.signingkey"* ]] || { echo "$output"; false; }
    [[ "$output" == *"MISSING commit.gpgsign"* ]] || { echo "$output"; false; }
}

@test "check-signing: --setup does not call git's default format missing" {
    # verifies: PR-mtmr7h
    # gpg.format unset IS a configured format: git documents the default as
    # openpgp, and this repository's own commits are signed that way. Calling
    # it MISSING named a non-problem to the one operator who had none, and
    # returned before the proof — the half that would have found the real
    # fault.
    isolate_git_config
    setup_ssh_signing
    git config --unset gpg.format
    git config commit.gpgsign true
    run sh .guardrails/scripts/check-signing.sh --setup
    [[ "$output" != *"MISSING gpg.format"* ]] \
        || { echo "still reports the default as missing: $output"; false; }
}

@test "check-signing: --setup carries a real format into the proof, not an empty one" {
    # verifies: PR-mtmr7h
    # The half of the fix no test reached. `_fmt` is written into the throwaway
    # repository, and `git config gpg.format ""` is REJECTED by git rather than
    # read as unset, so the proof dies before signing anything and --setup
    # blames a project whose configuration is fine. The two tests above assert
    # only the ABSENCE of `MISSING gpg.format`, which deleting the MISSING
    # block alone already satisfies.
    isolate_git_config
    git config --unset gpg.format 2>/dev/null || true
    git config user.email t@example.com
    git config user.signingkey DEADBEEFDEADBEEF
    git config commit.gpgsign true
    run sh .guardrails/scripts/check-signing.sh --setup
    # It cannot prove anything here — no such key exists — but it must fail for
    # THAT reason, never because the format it wrote was empty.
    [[ "$output" != *"invalid value for 'gpg.format'"* ]] \
        || { echo "an empty gpg.format reached the throwaway repository: $output"; false; }
    [[ "$output" != *"bad config variable 'gpg.format'"* ]] \
        || { echo "$output"; false; }
}

@test "check-signing: --setup names commit.gpgsign alone when only it is off" {
    # A key that can sign is not a project that does sign. Everything else is
    # configured here, so exactly one piece may be named — a report that listed
    # the settings that ARE present would be noise at the moment it is read.
    isolate_git_config
    setup_ssh_signing
    run sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"MISSING commit.gpgsign"* ]] || { echo "$output"; false; }
    [[ "$output" != *"MISSING gpg.format"* ]] || { echo "$output"; false; }
    [[ "$output" != *"MISSING user.signingkey"* ]] || { echo "$output"; false; }
}

@test "check-signing: --setup names a missing ssh trust root" {
    # This is the state a project is in with no gpg.ssh.allowedSignersFile:
    # it signs perfectly well and nothing can verify what it signed, which is
    # the WARN-UNVERIFIED the default mode passes and the merge gate refuses.
    setup_proved_signing
    git config --unset gpg.ssh.allowedSignersFile
    run sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"MISSING gpg.ssh.allowedSignersFile"* ]] || { echo "$output"; false; }
}

@test "check-signing: --setup names an allowed signers file it cannot read" {
    # Configured and absent is a different repair from not configured, and the
    # path is the whole of the message: it is usually a typo in it.
    setup_proved_signing
    git config gpg.ssh.allowedSignersFile "$BATS_TEST_TMPDIR/absent_signers"
    run sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"UNREADABLE gpg.ssh.allowedSignersFile"* ]] || { echo "$output"; false; }
    [[ "$output" == *"absent_signers"* ]] || { echo "$output"; false; }
}

@test "check-signing: --setup names a missing user.email" {
    # An ssh signature verifies against the committer's address. Without one
    # git guesses from the host, no signers file lists the guess, and the
    # project's commits are unverifiable for a reason nothing about keys says.
    setup_proved_signing
    git config --unset user.email
    run sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"MISSING user.email"* ]] || { echo "$output"; false; }
}

@test "check-signing: --setup exits 2 when the trust root exists but cannot be read" {
    # verifies: PR-mvqm4s
    # The same split as the --strict test above: absent stays a named
    # UNREADABLE finding at exit 1 (a typo in the path is a project error),
    # but present-and-permission-denied is the environment's fault, and exit
    # 1 would send the operator to the project's configuration.
    [ "$(id -u)" -ne 0 ] || skip "permission bits do not bind root"
    setup_proved_signing
    chmod 000 "$BATS_TEST_TMPDIR/allowed_signers"
    run sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
}

@test "check-signing: --setup exits 2 when the gpg keyring cannot be read" {
    # verifies: PR-mvqm4s
    # The openpgp trust root is the caller's keyring, not a configured file —
    # the reported case is a process that cannot read ~/.gnupg at all. That
    # is never a project setting, so it is exit 2 wherever it is found.
    [ "$(id -u)" -ne 0 ] || skip "permission bits do not bind root"
    isolate_git_config
    git config gpg.format openpgp
    git config user.signingkey ABCDEF0123456789
    git config commit.gpgsign true
    mkdir "$BATS_TEST_TMPDIR/gnupg"
    chmod 000 "$BATS_TEST_TMPDIR/gnupg"
    run env GNUPGHOME="$BATS_TEST_TMPDIR/gnupg" \
        sh .guardrails/scripts/check-signing.sh --setup
    chmod 700 "$BATS_TEST_TMPDIR/gnupg"
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
}

@test "check-signing: --setup ignores a worktree-scoped commit.gpgsign false" {
    # verifies: PR-2qdy9c
    # worktree-discipline leaves worktree commits unsigned on purpose; a
    # project that writes that down as worktree-scoped config is following
    # the discipline, not missing a setting. Read from inside the worktree,
    # the effective value is false, and --setup reported a false MISSING
    # commit.gpgsign — and a false finding beside a true one teaches the
    # operator to discount both. --setup's question is what the PROJECT
    # configures, so the worktree scope does not count.
    setup_proved_signing
    git config extensions.worktreeConfig true
    git worktree add -q "$BATS_TEST_TMPDIR/wt" -b wt-branch
    cd "$BATS_TEST_TMPDIR/wt"
    git config --worktree commit.gpgsign false
    run sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [[ "$output" != *"MISSING commit.gpgsign"* ]] || { echo "$output"; false; }
}

@test "check-signing: --setup still reports a real commit.gpgsign gap from a worktree" {
    # verifies: PR-2qdy9c
    # The scope filter must not hide a genuine gap: a shared config that
    # never set the key is MISSING wherever the check runs from.
    setup_proved_signing
    git config --unset commit.gpgsign
    git config extensions.worktreeConfig true
    git worktree add -q "$BATS_TEST_TMPDIR/wt" -b wt-branch
    cd "$BATS_TEST_TMPDIR/wt"
    run sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"MISSING commit.gpgsign"* ]] || { echo "$output"; false; }
}

@test "check-signing: --setup with --strict is a usage error" {
    # --setup implies --strict; accepting both would imply there is a lax
    # variant of it.
    setup_proved_signing
    run sh .guardrails/scripts/check-signing.sh --setup --strict
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    [[ "$output" == *"--strict"* ]] || { echo "$output"; false; }
}
