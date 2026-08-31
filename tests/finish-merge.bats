# The guarded tail of the signed merge command: sign, verify, then clean up.
#
# `finish-merge.sh` is the half of `git commit -S ... && sh finish-merge.sh`
# that can destroy work — `git branch -D` on a branch git does not consider
# merged, because a squash leaves no merge base. Every test here is therefore
# in one of two families: the guards pass and exactly the right two things are
# removed, or a guard fires and NOTHING is removed. There is no third outcome.

load helpers

setup() { make_fixture_repo; }

# Throwaway SSH signing for the fixture repo, in the shape check-signing.bats
# already uses.
setup_ssh_signing() {
    ssh-keygen -t ed25519 -N '' -f "$BATS_TEST_TMPDIR/sign_key" -q
    git config gpg.format ssh
    git config user.signingkey "$BATS_TEST_TMPDIR/sign_key"
    printf 'test@example.com %s\n' "$(cut -d' ' -f1-2 < "$BATS_TEST_TMPDIR/sign_key.pub")" \
        > "$BATS_TEST_TMPDIR/allowed_signers"
    git config gpg.ssh.allowedSignersFile "$BATS_TEST_TMPDIR/allowed_signers"
}

# The state merge-change hands the script at step 7: a change branch with work
# on it, its linked worktree still registered, and a signed squash of that work
# sitting on the base branch in the primary checkout. Leaves the shell in the
# primary checkout, which is where the script must run.
#
# Pass `unsigned` to leave the squash commit unsigned — the state guard 1 is
# there to catch.
make_squashed_change() {
    make_change_worktree my-change
    printf 'work\n' > src/work.txt
    git add -A
    git -c commit.gpgsign=false commit -qm work
    cd "$REPO"
    git merge --squash my-change >/dev/null
    if [ "${1:-signed}" = unsigned ]; then
        git -c commit.gpgsign=false commit -qm "squash my-change"
    else
        git -c commit.gpgsign=true commit -qS -m "squash my-change"
    fi
}

branch_exists() { git show-ref --verify --quiet "refs/heads/$1"; }

# A guard that fires must leave the change exactly as it found it. Asserted
# after every refusal rather than only after the first, because the ordering
# rule (S7) is what makes the whole command safe to re-run.
assert_nothing_removed() {
    [ -d "$BATS_TEST_TMPDIR/wt" ] || { echo "the worktree was removed anyway"; false; }
    branch_exists my-change || { echo "the branch was deleted anyway"; false; }
}

@test "finish-merge: removes the worktree and deletes the branch after a signed squash" {
    setup_ssh_signing
    make_squashed_change
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [ ! -d "$BATS_TEST_TMPDIR/wt" ] || { echo "worktree still on disk"; false; }
    ! branch_exists my-change || { echo "branch survived"; false; }
}

@test "finish-merge: an unsigned HEAD fails with the worktree and branch intact" {
    setup_ssh_signing
    make_squashed_change unsigned
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"UNSIGNED"* ]] || { echo "$output"; false; }
    assert_nothing_removed
}

@test "finish-merge: an unverifiable signature fails, because --strict is unconditional" {
    # check-signing.sh's DEFAULT mode passes a signature it cannot verify
    # (WARN-UNVERIFIED), which is what a project with no allowed_signers file
    # gets. Cleaning up on that would answer a question nobody asked, so this
    # script always passes --strict — there is no flag and no configuration
    # that turns it off.
    setup_ssh_signing
    make_squashed_change
    git config --unset gpg.ssh.allowedSignersFile
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"UNVERIFIED"* ]] || { echo "$output"; false; }
    assert_nothing_removed
}

@test "finish-merge: a change branch holding work the squash missed fails" {
    # merge-change step 1 has already merged the base branch into the change
    # branch, so a correct squash leaves the two trees IDENTICAL. A difference
    # means something did not land — an unstaged file, a partial `git add`, a
    # base that moved — and it is exactly the difference `git branch -D` would
    # destroy.
    setup_ssh_signing
    make_squashed_change
    printf 'missed\n' > "$BATS_TEST_TMPDIR/wt/src/missed.txt"
    git -C "$BATS_TEST_TMPDIR/wt" add -A
    git -C "$BATS_TEST_TMPDIR/wt" -c commit.gpgsign=false commit -qm missed
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"squash"* ]] || { echo "$output"; false; }
    assert_nothing_removed
}

@test "finish-merge: a dirty worktree fails with the branch intact" {
    # Guard 3 is not reimplemented here: `git worktree remove` WITHOUT --force
    # refuses a worktree carrying modified or untracked files, and that refusal
    # is the guard. What this test pins is that the refusal stops the script —
    # the branch must not be deleted after a removal that did not happen.
    setup_ssh_signing
    make_squashed_change
    printf 'uncommitted\n' > "$BATS_TEST_TMPDIR/wt/src/scratch.txt"
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    # Assert guard 3's OWN refusal, not merely a non-zero exit. Swallow the
    # `|| gr_refuse` after `git worktree remove` and the script still exits 1 —
    # but for the wrong reason, because git then refuses to delete a branch
    # that is still checked out, and it says so in a different voice. Exit
    # status alone cannot tell the guard from the accident.
    [[ "$output" == *"git refused to remove the worktree"* ]] \
        || { echo "expected guard 3's refusal, got: $output"; false; }
    assert_nothing_removed
}

@test "finish-merge: with no worktree registered the branch is still deleted" {
    # Tolerant about what is already gone, strict about what it proves. A
    # harness that removed the worktree itself must not leave the branch
    # undeletable forever.
    setup_ssh_signing
    make_squashed_change
    git worktree remove "$BATS_TEST_TMPDIR/wt"
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [[ "$output" == *"no worktree"* ]] || { echo "$output"; false; }
    ! branch_exists my-change || { echo "branch survived"; false; }
}

@test "finish-merge: refuses to run from a linked worktree" {
    # HEAD must be the squash commit this script is verifying. In a linked
    # worktree HEAD is the CHANGE branch's tip, so guard 1 would check the
    # wrong commit — and, worse, could pass on it. Refuse before any guard
    # runs rather than let a guard answer about the wrong HEAD.
    setup_ssh_signing
    make_squashed_change
    cd "$BATS_TEST_TMPDIR/wt"
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    cd "$REPO"
    assert_nothing_removed
}

@test "finish-merge: refuses when the primary checkout is not on a base branch" {
    # gr_base_branch reports whatever the PRIMARY checkout has checked out, so
    # inside the primary checkout "on some other branch" is unreachable by
    # construction — every branch there is its own base. The reachable shape of
    # "not on the base branch" is a detached HEAD, where gr_base_branch prints
    # nothing at all. An empty base compared against an empty current branch is
    # equal, so a naive comparison would sail straight through it.
    setup_ssh_signing
    make_squashed_change
    git checkout -q --detach
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    assert_nothing_removed
}

@test "finish-merge: refuses a branch that does not exist" {
    # A typo'd branch name must not read as "nothing left to clean up, all
    # guards vacuously satisfied" — guard 2 in particular would then be
    # comparing HEAD against a ref that is not there.
    setup_ssh_signing
    make_squashed_change
    run sh .guardrails/scripts/finish-merge.sh my-chagne
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    assert_nothing_removed
}

@test "finish-merge: refuses the base branch as the change branch" {
    # `git diff --quiet HEAD main` on the base branch is trivially satisfied,
    # so without this the script would sail through every guard and delete the
    # base branch.
    setup_ssh_signing
    make_squashed_change
    run sh .guardrails/scripts/finish-merge.sh main
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    branch_exists main || { echo "the base branch was deleted"; false; }
    assert_nothing_removed
}

@test "finish-merge: takes exactly one argument, the change branch" {
    # Exit 2 for usage, matching check-signing.sh's conventions. Two branch
    # names is the case that matters most: silently acting on one of them
    # leaves the other's worktree and branch behind with no error to notice.
    setup_ssh_signing
    make_squashed_change
    git branch other-change my-change

    run sh .guardrails/scripts/finish-merge.sh
    [ "$status" -eq 2 ] || { echo "no argument: expected 2, got $status: $output"; false; }

    run sh .guardrails/scripts/finish-merge.sh my-change other-change
    [ "$status" -eq 2 ] || { echo "two arguments: expected 2, got $status: $output"; false; }

    run sh .guardrails/scripts/finish-merge.sh --force my-change
    [ "$status" -eq 2 ] || { echo "unknown flag: expected 2, got $status: $output"; false; }

    assert_nothing_removed
    branch_exists other-change || { echo "other-change was deleted"; false; }
}

@test "finish-merge: derives the worktree path under an awk that refuses a newline in -v" {
    # This script reaches an awk gate, and portability.bats' sweep is a fixed
    # list that does not include it — so the defect class it guards (a value
    # carrying a literal newline reaching `awk -v`) is swept here instead.
    # macOS's BWK awk exits 2 before the program runs, which is not a wrong
    # answer a behavioural test would catch: the worktree path would come back
    # empty and the script would report "no worktree was registered" while
    # leaving a real one on disk, then delete the branch anyway.
    setup_ssh_signing
    make_squashed_change
    bin=$(make_strict_awk)
    PATH="$bin:$PATH" run sh .guardrails/scripts/finish-merge.sh my-change
    [[ "$output" != *"newline in string"* ]] || { echo "$output"; false; }
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [[ "$output" == *"worktree removed"* ]] || { echo "$output"; false; }
    [ ! -d "$BATS_TEST_TMPDIR/wt" ] || { echo "worktree still on disk"; false; }
}
