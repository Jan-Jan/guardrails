load helpers

# The fixture reads no global or system git config: helpers.bash points
# GIT_CONFIG_GLOBAL and GIT_CONFIG_SYSTEM at /dev/null for every suite file.
# Without that, a setting these tests deliberately leave unset is
# answered from the developer's own: with the fixture's gpg.format unset,
# --setup resolved a hardware-token key and blocked the suite waiting for a
# touch, and with gpg.ssh.allowedSignersFile unset git verified against the
# one in ~/.gitconfig.
setup() {
    make_fixture_repo
}

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
#
# The stub reads the payload git writes to it before it fails. A stub that
# exits first races git's write, and when git loses, it dies of SIGPIPE and
# the run measures the dead-git verdict instead of `B`. Only
# check-novalidate and verify are handed a payload; find-principals reads
# nothing, and a stub that read there would wait on whatever stdin it
# inherited.
break_the_verifier() {
    cat > "$BATS_TEST_TMPDIR/broken_verifier" <<'STUB'
#!/bin/sh
case " $* " in
    (*" check-novalidate "*|*" verify "*) cat > /dev/null ;;
esac
echo "stub verifier: trust store unavailable" >&2
exit 2
STUB
    chmod +x "$BATS_TEST_TMPDIR/broken_verifier"
    git config gpg.ssh.program "$BATS_TEST_TMPDIR/broken_verifier"
}

# A verifier whose failure kills git itself, so `git log --format=%G?` exits
# without printing a letter. This is the state a stub that exits without
# reading its stdin produced intermittently under load: when
# find-principals fails, git hands the signed payload to a second verifier
# call on stdin, and if that call has already exited, git dies of SIGPIPE,
# measured at exit 141. Here the kill is deterministic, and it happens on the
# first call only, so the `git verify-commit` that collects the reason still
# runs.
kill_git_from_the_verifier() {
    cat > "$BATS_TEST_TMPDIR/killing_verifier" <<STUB
#!/bin/sh
if [ ! -e "$BATS_TEST_TMPDIR/git_killed" ]; then
    : > "$BATS_TEST_TMPDIR/git_killed"
    kill -PIPE "\$PPID"
fi
echo "stub verifier: trust store unavailable" >&2
exit 2
STUB
    chmod +x "$BATS_TEST_TMPDIR/killing_verifier"
    git config gpg.ssh.program "$BATS_TEST_TMPDIR/killing_verifier"
}

@test "check-signing: unsigned commit fails with UNSIGNED" {
    run sh .guardrails/scripts/check-signing.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"UNSIGNED"* ]] || { echo "$output"; false; }
}

@test "check-signing: ssh-signed commit with allowed signers passes" {
    setup_ssh_signing
    signed_commit a
    run sh .guardrails/scripts/check-signing.sh
    [ "$status" -eq 0 ]
}

@test "check-signing: a good signature passes --strict with log.showSignature set" {
    # verifies: REQ-89mnna
    # log.showSignature makes git log print the verifier's output above the
    # %G? letter: without --no-show-signature, the value read back is that
    # output plus the letter, not G alone.
    setup_ssh_signing
    signed_commit a
    git config log.showSignature true
    run sh .guardrails/scripts/check-signing.sh --strict
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    output_lacks "UNVERIFIED"
}

@test "check-signing: with log.showSignature set, an unsigned commit and an untrusted signature still fail --strict" {
    # verifies: REQ-89mnna
    # The setting must not reach the verdict in either direction: reading the
    # letter past the verifier's output may not turn a failure into a pass.
    git config log.showSignature true
    run sh .guardrails/scripts/check-signing.sh --strict
    [ "$status" -eq 1 ] || { echo "an unsigned commit: expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"UNSIGNED"* ]] || { echo "an unsigned commit is not reported UNSIGNED: $output"; false; }
    setup_ssh_signing
    signed_commit a
    ssh-keygen -t ed25519 -N '' -f "$BATS_TEST_TMPDIR/other_key" -q
    printf 'test@example.com %s\n' "$(cut -d' ' -f1-2 < "$BATS_TEST_TMPDIR/other_key.pub")" \
        > "$BATS_TEST_TMPDIR/allowed_signers"
    run sh .guardrails/scripts/check-signing.sh --strict
    [ "$status" -eq 1 ] || { echo "an untrusted signature: expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"UNVERIFIED"* ]] || { echo "an untrusted signature is not reported UNVERIFIED: $output"; false; }
}

@test "check-signing: signed but unverifiable warns and passes" {
    setup_ssh_signing
    signed_commit a
    git config --unset gpg.ssh.allowedSignersFile
    run sh .guardrails/scripts/check-signing.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"WARN-UNVERIFIED"* ]] || { echo "$output"; false; }
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
    [[ "$output" == *"UNSIGNED"* ]] || { echo "$output"; false; }
}

@test "check-signing: a failed verdict contains the verifier's own reason" {
    # verifies: REQ-3dxnhf
    # `git log --format=%G?` returns a letter and throws the verifier's output
    # away — zero bytes on stderr. A guessed cause, such as the ssh trust-root
    # remedy appended to every verdict alike, would be wrong for the OpenPGP
    # commits that never read that setting; the real cause is one command away.
    setup_ssh_signing
    signed_commit a
    break_the_verifier
    run sh .guardrails/scripts/check-signing.sh
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"stub verifier: trust store unavailable"* ]] \
        || { echo "the verifier's reason was discarded: $output"; false; }
}

@test "check-signing: a verifier that cannot run is not called a forgery" {
    # verifies: REQ-ftg567
    # %G? is `B` both for a signature that was checked and rejected and for a
    # verifier that was never run. Stating "bad, expired, or revoked" of the
    # second accuses the signer of something the tool did not measure.
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
    # A pin on the verdict: without --strict, a signature the verifier
    # rejected still fails, and fails with no `WARN-` prefix, whatever words
    # the report uses for the cause. It carries no `verifies:` line because no
    # requirement states that verdict: REQ-ftg567 governs the wording, which
    # the test above verifies, and REQ-69eacq covers a verdict git could not
    # compute, not one it computed as rejected.
    setup_ssh_signing
    signed_commit a
    break_the_verifier
    run sh .guardrails/scripts/check-signing.sh
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" != *"WARN-"* ]] || { echo "tolerated a rejection: $output"; false; }
}

@test "check-signing: a verdict git could not compute fails without --strict" {
    # verifies: REQ-69eacq
    # `git log --format=%G?` that dies prints no letter at all. The script read
    # the empty answer as "signature present but did not verify" and, without
    # --strict, passed it as WARN-UNVERIFIED: a commit nobody verified,
    # tolerated in the mode where a verifier that cannot run (`B`) already
    # fails.
    setup_ssh_signing
    signed_commit a
    kill_git_from_the_verifier
    run sh .guardrails/scripts/check-signing.sh
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" != *"WARN-"* ]] || { echo "tolerated a missing verdict: $output"; false; }
    [[ "$output" == *"UNVERIFIED"* ]] || { echo "$output"; false; }
    [[ "$output" == *"stub verifier: trust store unavailable"* ]] \
        || { echo "the verifier's reason was discarded: $output"; false; }
}

@test "check-signing: a verdict git could not compute fails under --strict" {
    # verifies: REQ-69eacq
    setup_ssh_signing
    signed_commit a
    kill_git_from_the_verifier
    run sh .guardrails/scripts/check-signing.sh --strict
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"UNVERIFIED"*"git could not compute a verdict"* ]] \
        || { echo "$output"; false; }
}

@test "check-signing: a verdict git could not compute with an unreadable trust root exits 2" {
    # verifies: REQ-69eacq, REQ-d6vwa2
    # The header promises exit 2 in every mode for a trust root that exists
    # but cannot be read. A dead `git log` reaches that guard through its own
    # branch, not `*)`, and that branch must keep the promise.
    [ "$(id -u)" -ne 0 ] || skip "permission bits do not bind root"
    setup_ssh_signing
    signed_commit a
    kill_git_from_the_verifier
    chmod 000 "$BATS_TEST_TMPDIR/allowed_signers"
    run sh .guardrails/scripts/check-signing.sh
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    [[ "$output" == *"--setup"* ]] || { echo "$output"; false; }
}

# An unsigned commit whose message has a line starting with `gpgsig`. The
# signature header lives above the first empty line of the commit object; a
# message line below it is not one.
unsigned_commit_mentioning_gpgsig() {
    printf 'g\n' > src/g.txt
    git add -A
    git -c commit.gpgsign=false commit -q -m "explain the header" \
        -m "gpgsig is the header git uses"
}

@test "check-signing: a gpgsig line in the message does not make a commit signed" {
    # verifies: REQ-ngmbw6
    # `^gpgsig` was matched against the whole commit object, message included,
    # so this unsigned commit read as signed: WARN-UNVERIFIED with exit 0.
    unsigned_commit_mentioning_gpgsig
    run sh .guardrails/scripts/check-signing.sh
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    output_lacks "WARN-UNVERIFIED"
    output_has "UNSIGNED"
}

@test "check-signing: a test does not read the developer's global git config" {
    # verifies: REQ-2d5tsw
    # The reported-once test below unsets the fixture's trust root and failed
    # on a machine whose ~/.gitconfig names one, because git answered with
    # that file instead. Here the developer's config is planted in a HOME of
    # the test's own, so the leak is reproduced on every machine rather than
    # only on one configured that way.
    setup_ssh_signing
    signed_commit a
    git config --unset gpg.ssh.allowedSignersFile
    mkdir "$BATS_TEST_TMPDIR/home"
    printf '[gpg "ssh"]\n\tallowedSignersFile = %s\n' "$BATS_TEST_TMPDIR/allowed_signers" \
        > "$BATS_TEST_TMPDIR/home/.gitconfig"
    run env HOME="$BATS_TEST_TMPDIR/home" XDG_CONFIG_HOME= \
        sh .guardrails/scripts/check-signing.sh --strict
    [ "$status" -eq 1 ] \
        || { echo "verified against the planted global trust root: $output"; false; }
    [[ "$output" == *"allowedSignersFile"* ]] \
        || { echo "the fixture's unset trust root was answered from elsewhere: $output"; false; }
}

@test "check-signing: the verifier's reason is reported once, under its verdict" {
    # verifies: REQ-3dxnhf
    # `git log --format=%G?` leaks git's OWN diagnostic to stderr for an ssh
    # signature and leaks nothing for an OpenPGP one. Unindented and printed
    # before the verdict, that copy reads as a separate failure — and it
    # appears for only one of the two formats. The reason belongs under the verdict it explains,
    # once, put there by this script.
    setup_ssh_signing
    signed_commit a
    git config --unset gpg.ssh.allowedSignersFile
    run sh .guardrails/scripts/check-signing.sh
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [[ "$output" == *"allowedSignersFile"* ]] \
        || { echo "the reason went missing entirely: $output"; false; }
    # "once" is half the claim in the name, and two indented copies pass every
    # other assertion in this test unchanged. Counted, not eyeballed.
    n=$(printf '%s\n' "$output" | grep -c 'allowedSignersFile')
    [ "$n" -eq 1 ] || { echo "the reason appeared $n times, not once: $output"; false; }
    if printf '%s\n' "$output" | grep -q '^error:'; then
        echo "git's own diagnostic leaked, unindented, above the verdict: $output"
        false
    fi
}

@test "check-signing: an untrusted signature contains the verifier's reason too" {
    # verifies: REQ-3dxnhf
    # The third of the three places the reason is printed, and the only one no
    # other test reaches: of the other two reason tests, the broken-verifier
    # one is in `B|X|Y|R` (%G? = B) and the reported-once one in `*)`
    # (%G? = N), so without this one, deleting verifier_reason from the U|E
    # branch would leave the whole suite green.
    #
    # A signers file that is PRESENT and READABLE — so the environment guard
    # does not fire — naming a DIFFERENT key: the signature verifies
    # cryptographically and no principal owns it. That is %G? = U, and git
    # verify-commit states "No principal matched." Without the reason,
    # "signature present but did not verify" is a verdict with no cause
    # attached.
    setup_ssh_signing
    signed_commit a
    ssh-keygen -t ed25519 -N '' -f "$BATS_TEST_TMPDIR/other_key" -q
    printf 'test@example.com %s\n' \
        "$(cut -d' ' -f1-2 < "$BATS_TEST_TMPDIR/other_key.pub")" \
        > "$BATS_TEST_TMPDIR/allowed_signers"
    [ "$(git log -1 --format='%G?' 2>/dev/null)" = U ] \
        || { echo "fixture no longer produces U|E: $(git log -1 --format='%G?')"; false; }
    run sh .guardrails/scripts/check-signing.sh --strict
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"UNVERIFIED"* ]] || { echo "$output"; false; }
    # Indented, under the verdict it explains — the whole point of asking the
    # verifier rather than guessing.
    printf '%s\n' "$output" | grep -q '^    No principal matched\.$' \
        || { echo "the verifier's reason was discarded: $output"; false; }
}

@test "check-signing: --strict exits 2 when the trust root exists but cannot be read" {
    # verifies: REQ-d6vwa2
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
    # verifies: REQ-d6vwa2
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

# Everything --setup needs to prove a signature: the format, the key, signing
# on by default, and a trust root naming this committer. The fixture ships
# commit.gpgsign false, so it has to be turned on explicitly. The tests below
# take one piece away at a time.
setup_proved_signing() {
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
    # Configuration being present states nothing about whether the key can sign.
    setup_proved_signing
    git config user.signingkey "$BATS_TEST_TMPDIR/absent_key"
    run sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"could not be signed"* ]] || { echo "$output"; false; }
}

@test "check-signing: --setup fails when the signature does not verify" {
    # The signers file lists a key that is not the one doing the signing — the
    # shape a project is in when a committer's key is rotated and the trust
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
    # verifies: REQ-ycwkd5, REQ-mf8nxj, REQ-vzja7g
    # The fixture repo has no signing configuration at all. One verdict for
    # three separate gaps is two more runs than the operator needs.
    #
    # MISSING gpg.format must NOT be reported: git documents the default for
    # gpg.format as openpgp, so a project that never sets it HAS a format and
    # signs perfectly well — this repository's own commits are openpgp-signed
    # with gpg.format unset. The two gaps that really do
    # stop this repository signing anything, the key and commit.gpgsign, are
    # still asserted, along with the exit status.
    #
    # GNUPGHOME names a keyring that does not exist: with gpg.format unset,
    # the openpgp trust-root guard reads the caller's keyring, and a ~/.gnupg
    # this process cannot use would turn the verdict into exit 2.
    run env GNUPGHOME="$BATS_TEST_TMPDIR/no-gnupg" \
        sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" != *"MISSING gpg.format"* ]] || { echo "$output"; false; }
    [[ "$output" == *"MISSING user.signingkey"* ]] || { echo "$output"; false; }
    [[ "$output" == *"MISSING commit.gpgsign"* ]] || { echo "$output"; false; }
}

@test "check-signing: --setup does not call git's default format missing" {
    # verifies: REQ-mf8nxj
    # gpg.format unset IS a configured format: git documents the default as
    # openpgp, and this repository's own commits are signed that way. Calling
    # it MISSING named a non-problem to the one operator who had none, and
    # returned before the proof — the half that would have found the real
    # fault.
    setup_ssh_signing
    git config --unset gpg.format
    git config commit.gpgsign true
    run sh .guardrails/scripts/check-signing.sh --setup
    [[ "$output" != *"MISSING gpg.format"* ]] \
        || { echo "still reports the default as missing: $output"; false; }
}

@test "check-signing: --setup passes a real format into the proof, not an empty one" {
    # verifies: REQ-mf8nxj
    # `_fmt` is written into the throwaway
    # repository, and `git config gpg.format ""` is REJECTED by git rather than
    # read as unset, so the proof dies before signing anything and --setup
    # blames a project whose configuration is fine. The two tests above assert
    # only the ABSENCE of `MISSING gpg.format`, which deleting the MISSING
    # block alone already satisfies.
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
    # the WARN-UNVERIFIED the default mode passes and the merge gate rejects.
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
    # project's commits are unverifiable for a reason that is not about keys.
    setup_proved_signing
    git config --unset user.email
    run sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"MISSING user.email"* ]] || { echo "$output"; false; }
}

@test "check-signing: --setup exits 2 when the trust root exists but cannot be read" {
    # verifies: REQ-d6vwa2
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
    # verifies: REQ-d6vwa2
    # The openpgp trust root is the caller's keyring, not a configured file —
    # the reported case is a process that cannot read ~/.gnupg at all. That
    # is never a project setting, so it is exit 2 wherever it is found.
    [ "$(id -u)" -ne 0 ] || skip "permission bits do not bind root"
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

# A keyring gpg can read but not open read-write: gpg opens trustdb.gpg
# O_RDWR even to verify, so it dies before verifying anything. The gpg on
# PATH here is a fault injector: it reads its input and exits 2 with no
# output, so git computes no good verdict for a commit that is signed.
gpg_with_readonly_trustdb() {
    mkdir "$BATS_TEST_TMPDIR/gnupg"
    : > "$BATS_TEST_TMPDIR/gnupg/pubring.kbx"
    : > "$BATS_TEST_TMPDIR/gnupg/trustdb.gpg"
    chmod 444 "$BATS_TEST_TMPDIR/gnupg/trustdb.gpg"
    printf '#!/bin/sh\ncat > /dev/null\nexit 2\n' > "$BATS_TEST_TMPDIR/stub_gpg"
    chmod +x "$BATS_TEST_TMPDIR/stub_gpg"
    git config gpg.format openpgp
    git config gpg.program "$BATS_TEST_TMPDIR/stub_gpg"
    git config user.signingkey ABCDEF0123456789
}

# A commit carrying a gpgsig header, written as a commit object directly so
# that no signer runs: the header is git's commit format, not gpg output.
gpgsig_commit() {
    printf '%s\n' "$1" > "src/$1.txt"
    git add -A
    git -c commit.gpgsign=false commit -qm "signed $1"
    _signed_commit=$(git cat-file commit HEAD | awk '
        !done && /^$/ {
            print "gpgsig -----BEGIN PGP SIGNATURE-----"
            print " "
            print " c3R1Yg=="
            print " -----END PGP SIGNATURE-----"
            done = 1
        }
        { print }' | git hash-object -t commit -w --stdin)
    git update-ref HEAD "$_signed_commit"
}

@test "check-signing: a trustdb that cannot be opened read-write exits 2" {
    # verifies: REQ-ptg7rd
    [ "$(id -u)" -ne 0 ] || skip "permission bits do not bind root"
    gpg_with_readonly_trustdb
    gpgsig_commit a
    run env GNUPGHOME="$BATS_TEST_TMPDIR/gnupg" \
        sh .guardrails/scripts/check-signing.sh
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    output_has "GNUPGHOME"
    output_has "pubring.kbx"
    output_has "trustdb.gpg"
    output_lacks "UNVERIFIED"
}

@test "check-signing: --setup exits 2 when trustdb.gpg cannot be opened read-write" {
    # verifies: REQ-ptg7rd
    [ "$(id -u)" -ne 0 ] || skip "permission bits do not bind root"
    gpg_with_readonly_trustdb
    git config commit.gpgsign true
    run env GNUPGHOME="$BATS_TEST_TMPDIR/gnupg" \
        sh .guardrails/scripts/check-signing.sh --setup
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    output_has "GNUPGHOME"
    output_has "pubring.kbx"
}

@test "check-signing: a writable trustdb leaves a failed verification a project verdict" {
    # verifies: REQ-ptg7rd
    gpg_with_readonly_trustdb
    chmod 644 "$BATS_TEST_TMPDIR/gnupg/trustdb.gpg"
    gpgsig_commit a
    run env GNUPGHOME="$BATS_TEST_TMPDIR/gnupg" \
        sh .guardrails/scripts/check-signing.sh --strict
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    output_has "UNVERIFIED"
}

@test "check-signing: --setup ignores a worktree-scoped commit.gpgsign false" {
    # verifies: REQ-vzja7g
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
    # verifies: REQ-vzja7g
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
