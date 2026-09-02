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
    isolate_git_config
    run sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"MISSING gpg.format"* ]] || { echo "$output"; false; }
    [[ "$output" == *"MISSING user.signingkey"* ]] || { echo "$output"; false; }
    [[ "$output" == *"MISSING commit.gpgsign"* ]] || { echo "$output"; false; }
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
