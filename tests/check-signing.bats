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
