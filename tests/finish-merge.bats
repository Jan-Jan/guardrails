# The guarded tail of the signed merge command: sign, verify, then clean up.
#
# `finish-merge.sh` is the half of `git commit -S ... && sh finish-merge.sh`
# that can destroy work — `git branch -D` on a branch git does not consider
# merged, because a squash leaves no merge base. Every test here is therefore
# in one of two families: the guards pass and exactly the right two things are
# removed, or a guard fires and NOTHING is removed. There is no third outcome.

load helpers

# The command task-worktree.sh had before merge and remove replaced it. A
# variable, so the old spelling is not a literal in this file, which the check
# that no remedy names it searches.
retired_command=finish

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
# on the base branch in the primary checkout. Leaves the shell in the
# primary checkout, which is where the script must run.
#
# Pass `unsigned` to leave the squash commit unsigned — the state guard 1 is
# there to catch.
#
# The second argument is the change worktree's PATH, defaulting to the
# `$BATS_TEST_TMPDIR/wt` this helper has always produced — it makes the change
# worktree itself, rather than calling helpers.bash's `make_change_worktree`,
# because the squash on the base branch has to be built alongside it.
# Guard 4 prefix-tests that path against every registered worktree,
# so its spelling is the variable under test in the containment tests: a
# backslash in it, a space in it, a sibling directory whose name starts with
# it.
make_squashed_change() {
    CHANGE_WT=${2:-$BATS_TEST_TMPDIR/wt}
    git worktree add -q "$CHANGE_WT" -b my-change
    cd "$CHANGE_WT"
    # WORK_PATH: the file the change commits, src/work.txt unless a test
    # needs the change in another place, such as one unit of a manifest.
    mkdir -p "$(dirname "${WORK_PATH:-src/work.txt}")"
    printf 'work\n' > "${WORK_PATH:-src/work.txt}"
    # DELETE_PATH: a file the change deletes, where a test needs one.
    if [ -n "${DELETE_PATH:-}" ]; then
        git rm -q "$DELETE_PATH"
    fi
    git add -A
    git -c commit.gpgsign=false commit -qm work
    cd "$REPO"
    git merge --squash my-change >/dev/null
    # The message merge-change step 6b completes: Gate-tree: names the tree
    # the step 6a gate measured, which for a correct squash is the tree the
    # index now holds.
    _gate_tree=$(git write-tree)
    { message_body; message_trailers "$_gate_tree"; } > "$BATS_TEST_TMPDIR/squash.msg"
    if [ "${1:-signed}" = unsigned ]; then
        git -c commit.gpgsign=false commit -q -F "$BATS_TEST_TMPDIR/squash.msg"
    else
        git -c commit.gpgsign=true commit -qS -F "$BATS_TEST_TMPDIR/squash.msg"
    fi
}

# Replaces HEAD's message with stdin and signs again, keeping HEAD's tree:
# the squash a guard 5 test needs, with every other guard still passing.
resign_with_message() {
    git -c commit.gpgsign=true commit -q --amend -S -F -
}

branch_exists() { git show-ref --verify --quiet "refs/heads/$1"; }

# A guard that fires must leave the change exactly as it found it. Asserted
# after every rejection rather than only after the first, because the ordering
# rule (S7) is what makes the whole command safe to re-run.
assert_nothing_removed() {
    _wt=${1:-${CHANGE_WT:-$BATS_TEST_TMPDIR/wt}}
    [ -d "$_wt" ] || { echo "the worktree was removed anyway"; false; }
    branch_exists my-change || { echo "the branch was deleted anyway"; false; }
}

# `.worktrees/` ignored, in the BASE commit. Both halves matter. Ignored, so
# the change worktree's own `git status` stays clean with a nested worktree
# inside it — that invisibility is the whole hazard. In the base commit, so
# the squash captures it and guard 2 still sees identical trees.
ignore_worktrees_dir() {
    printf '.worktrees/\n' > "$REPO/.gitignore"
    git -C "$REPO" add .gitignore
    git -C "$REPO" -c commit.gpgsign=false commit -qm "ignore nested worktrees"
}

# A task worktree NESTED inside the change worktree, at the path
# worktree-discipline mandates: `.worktrees/<change-branch>-t<N>` inside the
# change worktree, so a harness that pins a dispatched subagent to that subtree
# can reach it.
#
#   nest_task_worktree [task-branch] [change-worktree-path]
#
# Echoes THE PATH GIT REPORTS, not the path handed to `git worktree add`. Those
# are not always the same string: git records the working tree's physical path,
# with symlinks resolved, and the script prints what `git worktree list
# --porcelain` records. On macOS `TMPDIR` is under `/var`, a symlink to
# `/private/var`, so a fixture asserting on its own spelling of
# `$BATS_TEST_TMPDIR/...` compares against a path the script will never print
# and fails on a platform AGENTS.md declares first-class. Asking git for the
# answer is the only spelling that is right on both.
nest_task_worktree() {
    _br=${1:-my-change-t1}
    _wt=${2:-${CHANGE_WT:-$BATS_TEST_TMPDIR/wt}}
    _nested="$_wt/.worktrees/$_br"
    git -C "$_wt" worktree add -q "$_nested" -b "$_br" my-change
    git -C "$_nested" worktree list --porcelain \
        | awk -v want="branch refs/heads/$_br" '
            /^worktree / { p = substr($0, 10) }
            $0 == want   { print p; exit }
        '
}

# A `git` on PATH that fails one `git worktree list` and passes everything else
# straight through, in the shape portability.bats' `make_strict_awk` uses: the
# real binary's path is baked in, so the stub cannot find itself once PATH has
# changed, and every other call is the genuine git — the script therefore
# reaches the failure with every earlier guard actually passed.
#
# WHICH call fails has to be chosen by COUNT, because there is nothing else to
# choose by: `gr_base_branch` (lib.sh) and finish-merge.sh both spell it
# `git worktree list --porcelain`, with identical arguments. gr_base_branch runs
# first and is the only other caller in this script's path — check-signing.sh
# has none — so the second call is the one under test. If that ever stops being
# true the tests below go RED rather than quietly passing on the wrong
# rejection:
# each asserts the exact message of the guard it covers, and gr_base_branch's
# failure produces a different one.
make_failing_worktree_list() {
    _real=$(command -v git)
    _bin="$BATS_TEST_TMPDIR/failing-git"
    case "$_real" in
        ("$_bin"/*) echo "make_failing_worktree_list called with the stub already on PATH" >&2
                   return 1 ;;
    esac
    mkdir -p "$_bin"
    printf '#!/bin/sh\nREAL=%s\nCOUNT=%s\nSKIP=%s\n' \
        "$_real" "$_bin/count" "${1:-1}" > "$_bin/git"
    cat >> "$_bin/git" <<'STUB'
if [ "${1:-}" = worktree ] && [ "${2:-}" = list ]; then
    n=0
    [ -f "$COUNT" ] && n=$(cat "$COUNT")
    n=$((n + 1))
    printf '%s\n' "$n" > "$COUNT"
    if [ "$n" -gt "$SKIP" ]; then
        echo "fatal: cannot read the worktree registry" >&2
        exit 128
    fi
fi
exec "$REAL" "$@"
STUB
    chmod +x "$_bin/git"
    echo "$_bin"
}

# An `awk` on PATH that fails exactly the derivation in finish-merge.sh and
# passes everything else through. No counting is needed here: that awk is the
# only one in the script's path invoked with a `want=` assignment, so the stub
# picks its target out of the argument list instead of out of a tally.
make_failing_awk() {
    _real=$(command -v awk)
    _bin="$BATS_TEST_TMPDIR/failing-awk"
    case "$_real" in
        ("$_bin"/*) echo "make_failing_awk called with the stub already on PATH" >&2
                   return 1 ;;
    esac
    mkdir -p "$_bin"
    printf '#!/bin/sh\nREAL=%s\n' "$_real" > "$_bin/awk"
    cat >> "$_bin/awk" <<'STUB'
for a in "$@"; do
    case "$a" in
        (want=*|-vwant=*)
            echo "awk: the derivation failed" >&2
            exit 2 ;;
    esac
done
exec "$REAL" "$@"
STUB
    chmod +x "$_bin/awk"
    echo "$_bin"
}

@test "finish-merge: a failing git worktree list rejects instead of deleting the branch" {
    # verifies: PR-n57ayn
    # The registry is read ONCE and its status taken on its own line, because
    # guard 4 and the removal both read it and neither may confuse "git failed"
    # with "nothing registered". Without that check `$wt_list` is empty, `$wt`
    # comes back empty with it, guard 4 and the removal are BOTH skipped as
    # "no worktree was registered" — and `git branch -D` still runs, on a
    # branch whose worktree is untouched on disk and may have work nested
    # inside it.
    #
    # This test was written after the check, as test debt the third review
    # found: green on arrival, and mutation-checked on its own by deleting the
    # `|| gr_die`. What the mutant showed is worth recording, because it
    # decides what this test may assert: with the check gone the script runs on
    # to `git branch -D`, and GIT rejects it — "cannot delete branch used by
    # worktree" — so the branch remains by accident, not by any guard. An
    # assertion on the branch alone would therefore have passed the mutant.
    # The rejection's IDENTITY is what kills it, and it is asserted below.
    setup_ssh_signing
    make_squashed_change
    bin=$(make_failing_worktree_list)
    PATH="$bin:$PATH" run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -ne 0 ] || { echo "expected a rejection, got 0: $output"; false; }
    [[ "$output" == *"git worktree list failed"* ]] \
        || { echo "expected the registry rejection, got: $output"; false; }
    assert_nothing_removed
}

# verifies: PR-tz6gsp
@test "finish-merge: a failed git worktree list in gr_base_branch exits 2, is not read as a detached checkout" {
    # Every git worktree list fails here, the FIRST one included, which is
    # gr_base_branch's. Before gr_base_branch took the status, that failure
    # printed nothing and the script exited 2 with "this checkout is detached"
    # and the remedy to check out the base branch.
    setup_ssh_signing
    make_squashed_change
    head_before=$(git rev-parse HEAD)
    stub_directory=$(make_git_failing_on '*" worktree list "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "git worktree list failed, so the base branch cannot be read."
    output_lacks "detached"
    assert_nothing_removed
    [ "$(git rev-parse HEAD)" = "$head_before" ] || { echo "HEAD moved"; false; }
}

@test "finish-merge: a failing awk rejects instead of deleting the branch" {
    # verifies: PR-n57ayn
    # The worktree path is derived through awk, and an awk that dies leaves the
    # substitution empty — indistinguishable, without the status check, from a
    # branch whose worktree the harness already removed. The script would then
    # report "no worktree was registered", skip guard 4 and the removal, and
    # delete the branch anyway, with the real worktree still on disk.
    #
    # Same provenance as the test above: written after the check it covers,
    # green on arrival, mutation-checked on its own by deleting the `|| gr_die`
    # — and killed the same way, by the rejection's identity rather than by the
    # branch's survival, which git's own "used by worktree" rejection supplies
    # here whatever this script does.
    setup_ssh_signing
    make_squashed_change
    bin=$(make_failing_awk)
    PATH="$bin:$PATH" run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -ne 0 ] || { echo "expected a rejection, got 0: $output"; false; }
    [[ "$output" == *"could not be derived"* ]] \
        || { echo "expected the derivation rejection, got: $output"; false; }
    assert_nothing_removed
}

@test "finish-merge: removes the worktree and deletes the branch after a signed squash" {
    # verifies: ADR-f6ytg7
    setup_ssh_signing
    make_squashed_change
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    # merge-change step 7 tells the user that success ends with these lines.
    [ "$(printf '%s\n' "$output" | tail -n 3 | grep -c '^finish-merge: ')" -eq 3 ] \
        || { echo "$output"; false; }
    [ ! -d "$BATS_TEST_TMPDIR/wt" ] || { echo "worktree still on disk"; false; }
    ! branch_exists my-change || { echo "branch still exists"; false; }
}

@test "finish-merge: an unsigned HEAD fails with the worktree and branch intact" {
    # verifies: PR-52rnrn
    setup_ssh_signing
    make_squashed_change unsigned
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"UNSIGNED"* ]] || { echo "$output"; false; }
    assert_nothing_removed
}

@test "finish-merge: an unverifiable signature fails, because --strict is unconditional" {
    # verifies: PR-52rnrn
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

@test "finish-merge: a change branch containing work the squash missed fails" {
    # merge-change step 1 has already merged the base branch into the change
    # branch, so a correct squash leaves the two trees IDENTICAL. A difference
    # means something is missing — an unstaged file, a partial `git add`, a
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
    # rejects a worktree containing modified or untracked files, and that
    # rejection is the guard. What this test pins is that the rejection stops the
    # script —
    # the branch must not be deleted after a removal that did not happen.
    setup_ssh_signing
    make_squashed_change
    printf 'uncommitted\n' > "$BATS_TEST_TMPDIR/wt/src/scratch.txt"
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    # Assert guard 3's OWN rejection, not merely a non-zero exit. Swallow the
    # `|| gr_refuse` after `git worktree remove` and the script still exits 1 —
    # but for the wrong reason, because git then rejects deleting a branch
    # that is still checked out, and it reports that in a different message. Exit
    # status alone cannot tell the guard from the accident.
    [[ "$output" == *"git rejected the removal of the worktree"* ]] \
        || { echo "expected guard 3's rejection, got: $output"; false; }
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
    ! branch_exists my-change || { echo "branch still exists"; false; }
}

# Makes `git branch -D my-change` fail and leaves every earlier step alone: a
# `<ref>.lock` file is how git marks a ref as being updated, and a deletion
# that cannot take the lock exits non-zero without touching the ref. Nothing
# else in the script's path writes that ref, so the guards and the removal run
# as they do on a real merge.
lock_change_branch_ref() {
    _common=$(git -C "$REPO" rev-parse --path-format=absolute --git-common-dir)
    : > "$_common/refs/heads/my-change.lock"
}

@test "finish-merge: a failed branch deletion after a removal reports the worktree removed" {
    # verifies: PR-sa5y4k
    # The one exit 1 that follows a destructive act. The worktree is gone by
    # then, so the message has to state that it is, or the operator reads the
    # rejection as "nothing was removed" and looks for a worktree that no
    # longer exists.
    setup_ssh_signing
    make_squashed_change
    lock_change_branch_ref
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    case "$output" in
        (*"the worktree was removed but my-change could not be deleted"*) ;;
        (*) echo "expected the removal to be reported, got: $output"; false ;;
    esac
    [ ! -d "$CHANGE_WT" ] || { echo "worktree still on disk"; false; }
    branch_exists my-change || { echo "the branch was deleted anyway"; false; }
}

@test "finish-merge: a failed branch deletion with no worktree registered does not claim a removal" {
    # verifies: PR-sa5y4k
    # With no worktree registered the script removes nothing, so a message that
    # states a worktree was removed is false on this path.
    setup_ssh_signing
    make_squashed_change
    git worktree remove "$CHANGE_WT"
    lock_change_branch_ref
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    case "$output" in
        (*"the worktree was removed"*)
            echo "claimed a removal that did not happen: $output"; false ;;
    esac
    case "$output" in
        (*"no worktree was removed"*"my-change could not be deleted"*) ;;
        (*) echo "expected the no-removal message, got: $output"; false ;;
    esac
    branch_exists my-change || { echo "the branch was deleted anyway"; false; }
}

@test "finish-merge: rejects a run from a linked worktree" {
    # HEAD must be the squash commit this script is verifying. In a linked
    # worktree HEAD is the CHANGE branch's tip, so guard 1 would check the
    # wrong commit — and, worse, could pass on it. Reject before any guard
    # runs rather than let a guard answer about the wrong HEAD.
    setup_ssh_signing
    make_squashed_change
    cd "$BATS_TEST_TMPDIR/wt"
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    cd "$REPO"
    assert_nothing_removed
}

@test "finish-merge: rejects a primary checkout that is not on a base branch" {
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

@test "finish-merge: rejects a branch that does not exist" {
    # A typo'd branch name must not read as "nothing left to clean up, all
    # guards vacuously satisfied" — guard 2 in particular would then be
    # comparing HEAD against a ref that is not there.
    setup_ssh_signing
    make_squashed_change
    run sh .guardrails/scripts/finish-merge.sh my-chagne
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    assert_nothing_removed
}

@test "finish-merge: rejects the base branch as the change branch" {
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

@test "finish-merge: derives the worktree path under an awk that rejects a newline in -v" {
    # This script reaches an awk gate, and portability.bats' sweep is a fixed
    # list that does not include it — so the defect class it guards (a value
    # containing a literal newline reaching `awk -v`) is swept here instead.
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

@test "finish-merge: a worktree nested inside the change worktree fails with everything intact" {
    # verifies: PR-n57ayn
    # Guard 3 delegates to `git worktree remove` without --force, and that
    # rejection does not detect a NESTED worktree: `.worktrees/` is gitignored,
    # so the change worktree's own `git status` is clean, and git removes the
    # outer worktree — files and all — at exit 0. Measured before this guard
    # existed, in a scratch repository and in this fixture alike: the nested
    # worktree's uncommitted work was deleted, its registration left `prunable`,
    # and its task branch orphaned. Nesting is what worktree-discipline now
    # mandates, so this change created the hazard and this guard closes it.
    setup_ssh_signing
    ignore_worktrees_dir
    make_squashed_change
    nested=$(nest_task_worktree)
    printf 'uncommitted\n' > "$nested/NEW.txt"
    printf 'modified\n' > "$nested/src/work.txt"

    # The invisibility this guard exists for: the state below is what makes
    # guard 3 pass over it.
    [ -z "$(git -C "$BATS_TEST_TMPDIR/wt" status --short)" ] \
        || { echo "the fixture is not the hazard: the change worktree is dirty"; false; }

    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    # Assert this guard's OWN rejection, and the offending path in it, not
    # merely a non-zero exit: the next thing the user does is go and look at that
    # worktree, so the message has to name which one. A test pinning the exit
    # code alone stays green when the guard it claims to cover is deleted.
    [[ "$output" == *"a registered worktree lies inside"* ]] \
        || { echo "expected the nesting rejection, got: $output"; false; }
    [[ "$output" == *"$nested"* ]] \
        || { echo "the rejection did not name the nested worktree: $output"; false; }

    [ -f "$nested/NEW.txt" ] \
        || { echo "the nested worktree's uncommitted work was destroyed"; false; }
    assert_nothing_removed
    branch_exists my-change-t1 || { echo "the task branch was orphaned"; false; }
}

@test "finish-merge: a nested worktree is rejected even when it contains nothing uncommitted" {
    # verifies: PR-n57ayn
    # The guard is CONTAINMENT, not dirtiness. A clean nested worktree is
    # destroyed just as silently — its directory deleted under a registration
    # git then calls `prunable`, its branch left with no worktree — and a guard
    # that only fired on a dirty one would pass the test above while leaving
    # that state reachable.
    setup_ssh_signing
    ignore_worktrees_dir
    make_squashed_change
    nested=$(nest_task_worktree)

    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"a registered worktree lies inside"* ]] \
        || { echo "expected the nesting rejection, got: $output"; false; }
    [[ "$output" == *"$nested"* ]] \
        || { echo "the rejection did not name the nested worktree: $output"; false; }
    assert_nothing_removed
}

@test "finish-merge: a backslash in the change worktree's path does not defeat the guard" {
    # verifies: PR-n57ayn
    # `awk -v k=v` ESCAPE-PROCESSES the value before the program sees it, so a
    # change worktree at `.../w\top` reached guard 4's prefix test spelled
    # `.../w<TAB>op/`. Nothing then matched, `$nested` came back empty, and the
    # guard PASSED — after which guard 3 removed the change worktree with the
    # nested one inside it, uncommitted work and all, at exit 0. Every other
    # rejection in this script fails closed and merely withholds cleanup; this
    # one lost work, silently, which is why the prefix test has no escape layer
    # at all any more.
    setup_ssh_signing
    ignore_worktrees_dir
    make_squashed_change signed "$BATS_TEST_TMPDIR"'/w\top'
    nested=$(nest_task_worktree)
    printf 'uncommitted\n' > "$nested/NEW.txt"

    run sh .guardrails/scripts/finish-merge.sh my-change
    [ -f "$nested/NEW.txt" ] \
        || { echo "the nested worktree's uncommitted work was destroyed"; false; }
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"lies inside"* ]] \
        || { echo "expected the nesting rejection, got: $output"; false; }
    [[ "$output" == *"$nested"* ]] \
        || { echo "the rejection did not name the nested worktree: $output"; false; }
    assert_nothing_removed
}

@test "finish-merge: every nested worktree is named, not just the first" {
    # verifies: PR-n57ayn
    # A five-way fan-out leaves five task worktrees. Reporting one and exiting
    # makes the operator run the script five times to learn what one run
    # already knew. Each re-run verifies the signature and uses no private key,
    # so the cost is the runs, not key touches. The rejection lists all of
    # them, and changes number when it does.
    setup_ssh_signing
    ignore_worktrees_dir
    make_squashed_change
    first=$(nest_task_worktree my-change-t1)
    second=$(nest_task_worktree my-change-t2)

    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"$first"* ]] \
        || { echo "the rejection did not name $first: $output"; false; }
    [[ "$output" == *"$second"* ]] \
        || { echo "the rejection did not name $second: $output"; false; }
    [[ "$output" == *"registered worktrees lie inside"* ]] \
        || { echo "expected the plural rejection, got: $output"; false; }
    assert_nothing_removed
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "finish-merge: guard 4's rejection names the task-worktree.sh remedy, as --check does" {
    # The change worktree is still in place when guard 4 rejects after the
    # squash, so the task-worktree.sh commands still apply from it. Every
    # nested worktree gets `remove <tag>` there, which merges nothing: no
    # remedy names a merging command.
    setup_ssh_signing
    ignore_worktrees_dir
    make_squashed_change
    nest_task_worktree my-change-review >/dev/null

    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    output_has "a registered worktree lies inside"
    output_has "the review worktree included"
    output_has "task-worktree.sh remove <tag>"
    output_has "task-worktree.sh discard <tag>"
    output_has "git worktree remove <path>"
    output_has "git branch -D <branch>"
    output_lacks "task-worktree.sh merge"
    output_lacks "task-worktree.sh $retired_command"
    output_lacks "merge or abandon"
    assert_nothing_removed
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "finish-merge: guard 4 after the squash names remove and discard for a task branch with a commit" {
    # A commit on a task branch after the squash is not in the squash, and it
    # was never gated or reviewed. `remove <tag>` rejects the branch, and the
    # remedy names discard after recording, or a new change to keep the work.
    # It never names a merge.
    setup_ssh_signing
    ignore_worktrees_dir
    make_squashed_change
    nested=$(nest_task_worktree my-change-t1)
    printf 'late work\n' > "$nested/late.txt"
    git -C "$nested" add -A
    git -C "$nested" -c commit.gpgsign=false commit -qm "late work"

    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    output_has "$nested"
    output_has "task-worktree.sh remove <tag>"
    output_has "If remove rejects on commits, those commits are not in the squash"
    output_has "never gated or reviewed"
    output_has "task-worktree.sh discard <tag>"
    # The squash is already on the base branch, so a rerun of this change's
    # merge-change cannot bring the work in; it becomes a new change.
    output_has "copy its branch first"
    output_has "open a new change for it"
    output_lacks "rerun merge-change from step 1"
    output_lacks "task-worktree.sh merge"
    output_lacks "task-worktree.sh $retired_command"
    assert_nothing_removed
    branch_exists my-change-t1 || { echo "the task branch was deleted"; false; }
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "finish-merge: guard 4 after the squash names the plain git commands for a worktree task-worktree.sh did not create" {
    # A nested worktree whose path is not .worktrees/<change-branch>-<tag> was
    # not created by task-worktree.sh, so no task-worktree.sh command reaches
    # it. The remedy names the git commands that merge nothing: record the
    # commits, remove the worktree without --force, delete the branch.
    setup_ssh_signing
    ignore_worktrees_dir
    make_squashed_change
    git -C "$CHANGE_WT" worktree add -q "$CHANGE_WT/.worktrees/scratch" -b scratch my-change

    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    output_has "/.worktrees/scratch"
    output_has "a worktree task-worktree.sh did not create: record the commits its branch has"
    output_has "git worktree remove <path>"
    output_has "git branch -D <branch>"
    output_lacks "merge or abandon"
    output_lacks "task-worktree.sh merge"
    assert_nothing_removed
    branch_exists scratch || { echo "the scratch branch was deleted"; false; }
}

@test "finish-merge: a sibling whose path merely starts with the change worktree's is not nested" {
    # verifies: PR-n57ayn
    # `<wt>-sibling` starts with `<wt>` and is NOT inside it. A prefix test
    # written without the separator would call it nested and reject every
    # cleanup that had one lying beside it — guard 4 failing CLOSED, on a state
    # with nothing wrong in it. The trailing `/` is the whole difference, and
    # nothing else in this file keeps it there.
    setup_ssh_signing
    ignore_worktrees_dir
    make_squashed_change
    git worktree add -q "$CHANGE_WT-sibling" -b a-sibling main

    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [[ "$output" != *"lies inside"* && "$output" != *"lie inside"* ]] \
        || { echo "the sibling was mistaken for a nested worktree: $output"; false; }
    [ ! -d "$CHANGE_WT" ] || { echo "worktree still on disk"; false; }
    [ -d "$CHANGE_WT-sibling" ] || { echo "the sibling worktree was removed"; false; }
    ! branch_exists my-change || { echo "branch still exists"; false; }
}

@test "finish-merge: a space in the change worktree's path does not defeat the guard" {
    # verifies: PR-n57ayn
    # The prefix test walks git's porcelain output line by line, and a path
    # with a space in it comes through that walk intact only if the line is read as
    # one value. Field-splitting anywhere on the route truncates the path at
    # its first space, nothing matches the truncated prefix, and the guard
    # fails open exactly as the backslash made it.
    setup_ssh_signing
    ignore_worktrees_dir
    make_squashed_change signed "$BATS_TEST_TMPDIR/my change wt"
    nested=$(nest_task_worktree)
    printf 'uncommitted\n' > "$nested/NEW.txt"

    run sh .guardrails/scripts/finish-merge.sh my-change
    # The lost work is asserted BEFORE the exit status, in both fail-open
    # tests: watched against the `awk -v` version, this is the line that goes
    # red, and it names the harm instead of a number.
    [ -f "$nested/NEW.txt" ] \
        || { echo "the nested worktree's uncommitted work was destroyed"; false; }
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"lies inside"* ]] \
        || { echo "expected the nesting rejection, got: $output"; false; }
    [[ "$output" == *"$nested"* ]] \
        || { echo "the rejection did not name the nested worktree: $output"; false; }
    assert_nothing_removed
}

# --- Guard 5: the signed message is the record, and certifies its own tree ---
#
# Guard 5 runs the squash message check on HEAD's message with HEAD's tree:
# the review fields, the findings, the Tests: and Mutation: trailers, and
# exactly one Gate-tree: naming HEAD's own tree. Each refusal removes nothing.

# The refusal every guard 5 test expects: exit 1, the finding named, and the
# change left exactly as it was.
assert_guard5_refused() {
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    output_has "$1"
    assert_nothing_removed
}

# verifies: ADR-f6ytg7
@test "finish-merge: a squash whose message has no Gate-tree trailer is refused with everything intact" {
    setup_ssh_signing
    make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    { message_body; message_trailers "$head_tree" | grep -v '^Gate-tree:'; } | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "GATE-TREE (want one Gate-tree: $head_tree, found none)"
}

# verifies: ADR-f6ytg7
@test "finish-merge: a Gate-tree trailer with no value is refused" {
    setup_ssh_signing
    make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    { message_body; message_trailers ''; } | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "GATE-TREE (want one Gate-tree: $head_tree, found"
    output_lacks "found none"
}

# verifies: ADR-f6ytg7
@test "finish-merge: a Gate-tree line outside the message's last paragraph is not read" {
    # git reads trailers only in the last paragraph. A Tests: line after a
    # blank line is that paragraph, and the Gate-tree line above it is then
    # body text, as git interpret-trailers --parse shows.
    setup_ssh_signing
    make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    { message_body; printf 'Gate-tree: %s\n\n' "$head_tree"
      message_trailers "$head_tree" | grep -v '^Gate-tree:'; } | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "GATE-TREE (want one Gate-tree: $head_tree, found none)"
    output_has "last paragraph"
}

# verifies: ADR-f6ytg7
@test "finish-merge: two Gate-tree trailers are refused, even when both name HEAD's tree" {
    setup_ssh_signing
    make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    { message_body; message_trailers "$head_tree"; printf 'Gate-tree: %s\n' "$head_tree"; } \
        | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "found $head_tree $head_tree)"
}

# verifies: ADR-f6ytg7
@test "finish-merge: an empty Gate-tree trailer after one naming HEAD's tree is a second trailer, and refused" {
    setup_ssh_signing
    make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    { message_body; message_trailers "$head_tree"; printf 'Gate-tree:\n'; } | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "GATE-TREE (want one Gate-tree: $head_tree, found $head_tree )"
}

# verifies: ADR-f6ytg7
@test "finish-merge: an empty Gate-tree trailer before one naming HEAD's tree is a second trailer, and refused" {
    setup_ssh_signing
    make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    { message_body; printf 'Gate-tree:\n'; message_trailers "$head_tree"; } | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "GATE-TREE (want one Gate-tree: $head_tree, found  $head_tree)"
}

# verifies: ADR-f6ytg7
@test "finish-merge: one Gate-tree trailer folded onto a second line is read as one value, and refused as another tree" {
    # A continuation line opens with whitespace and belongs to the trailer
    # above it, so the continuation is part of the one value, not a second
    # trailer; one trailer whose value is not HEAD's tree is a mismatch.
    setup_ssh_signing
    make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    { message_body
      message_trailers "$head_tree" | awk '{ print } /^Gate-tree:/ { print "  continued" }'; } \
        | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "GATE-TREE (want one Gate-tree: $head_tree, found $head_tree continued)"
}

# verifies: ADR-f6ytg7
@test "finish-merge: guard 5 removes the message file it checked, whether it passes or refuses" {
    # The file is the script's own scratch copy of HEAD's message, in the
    # primary checkout's git directory; neither verdict may leave it there.
    setup_ssh_signing
    make_squashed_change
    signed_message=$(git rev-parse --git-path guardrails-signed.msg)
    head_tree=$(git rev-parse 'HEAD^{tree}')
    { message_body; message_trailers "$head_tree" | grep -v '^Gate-tree:'; } | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "GATE-TREE"
    [ ! -e "$signed_message" ] || { echo "a refusing guard 5 left $signed_message"; false; }
    { message_body; message_trailers "$head_tree"; } | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [ ! -e "$signed_message" ] || { echo "a passing guard 5 left $signed_message"; false; }
}

# verifies: ADR-3hsvvq
@test "finish-merge: under a unit manifest guard 5 owes Tests trailers for the squash's impact set only" {
    # The squash touches apps/pump alone, and nothing depends on it, so the
    # impact set of HEAD^..HEAD is pump: one Tests: trailer, not one per unit
    # of the manifest.
    make_units_fixture
    setup_ssh_signing
    WORK_PATH=apps/pump/src/work.txt make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    { message_body; message_trailers "$head_tree" 'HEAD^..HEAD'
      printf 'Tests: platform/hal: make test 12/12\n'; } | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "TESTS (want 1 Tests: trailers, one per verify_commands entry, found 2)"
    { message_body; message_trailers "$head_tree" 'HEAD^..HEAD'; } | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
}

# verifies: ADR-3hsvvq
@test "finish-merge: under a unit manifest a squash whose impact set cannot be computed exits 2 with everything intact" {
    make_units_fixture
    setup_ssh_signing
    # tools/ is claimed by no unit: check-units.sh --impact exits 2 on it.
    WORK_PATH=tools/work.txt make_squashed_change
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    output_has "claimed by no unit"
    assert_nothing_removed
}

# verifies: ADR-f6ytg7
@test "finish-merge: a git log that cannot read HEAD's message exits 2 with everything intact" {
    # Only the guard's git log fails; every other git call is the real one, so
    # guards 1 and 2 pass and the failure is guard 5's.
    setup_ssh_signing
    make_squashed_change
    stub_directory=$(make_git_failing_on '*" --format=%B HEAD "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    output_has "git log failed, so HEAD's message cannot be read"
    assert_nothing_removed
}

# verifies: ADR-f6ytg7
@test "finish-merge: a git interpret-trailers that cannot parse HEAD's message exits 2 with everything intact" {
    setup_ssh_signing
    make_squashed_change
    stub_directory=$(make_git_failing_on '*" interpret-trailers "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    output_has "git interpret-trailers could not read"
    output_has "Nothing was removed"
    assert_nothing_removed
}

# verifies: ADR-f6ytg7
@test "finish-merge: a git rev-parse that cannot name the signed message's path exits 2 with everything intact" {
    setup_ssh_signing
    make_squashed_change
    stub_directory=$(make_git_failing_on '*" rev-parse --git-path guardrails-signed.msg "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    output_has "git rev-parse failed, so HEAD's message has nowhere to be read from"
    assert_nothing_removed
}

# verifies: ADR-f6ytg7
@test "finish-merge: a git rev-parse that cannot read HEAD's tree exits 2 with everything intact" {
    # The guard's rev-parse is the script's only one that names HEAD^{tree}.
    setup_ssh_signing
    make_squashed_change
    stub_directory=$(make_git_failing_on '*" rev-parse HEAD^{tree} "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    output_has "git rev-parse failed, so HEAD's tree cannot be read"
    assert_nothing_removed
}

# verifies: ADR-f6ytg7
@test "finish-merge: a Gate-tree trailer naming another tree is refused, naming both trees" {
    setup_ssh_signing
    make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    parent_tree=$(git rev-parse 'HEAD~1^{tree}')
    { message_body; message_trailers "$parent_tree"; } | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "GATE-TREE (want one Gate-tree: $head_tree, found $parent_tree)"
    output_has "gate HEAD's tree"
}

@test "finish-merge: a record committed after the gate leaves a squash its Gate-tree does not name" {
    # verifies: PR-k4y59t
    # The defect's sequence: the gate measures the change branch, the record
    # is committed after it, and the squash carries the tree the gate
    # measured. The signed commit then holds a tree no gate saw.
    setup_ssh_signing
    CHANGE_WT="$BATS_TEST_TMPDIR/wt"
    git worktree add -q "$CHANGE_WT" -b my-change
    printf 'work\n' > "$CHANGE_WT/src/work.txt"
    git -C "$CHANGE_WT" add -A
    git -C "$CHANGE_WT" -c commit.gpgsign=false commit -qm work
    gate_tree=$(git -C "$CHANGE_WT" rev-parse 'HEAD^{tree}')
    mkdir -p "$CHANGE_WT/docs/verification"
    printf 'branch: my-change\n' > "$CHANGE_WT/docs/verification/record.md"
    git -C "$CHANGE_WT" add -A
    git -C "$CHANGE_WT" -c commit.gpgsign=false commit -qm "the record, after the gate"
    git merge --squash my-change >/dev/null
    { message_body; message_trailers "$gate_tree"; } | git -c commit.gpgsign=true commit -qS -F -
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 1 ] || { echo "cleaned up after a squash its gate never measured: $output"; false; }
    output_has "found $gate_tree)"
    assert_nothing_removed
}

@test "finish-merge: guard 5 reads the message when log.showSignature is set" {
    # verifies: ADR-f6ytg7, PR-nyw3ww
    # With log.showSignature, git log prints the verifier's output above the
    # formatted message, which would read as body text before the subject.
    setup_ssh_signing
    make_squashed_change
    git config log.showSignature true
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    if branch_exists my-change; then echo "branch still exists"; false; fi
}

# verifies: ADR-k3nkv3
@test "finish-merge: the squash message template, filled in, passes guard 5" {
    # The template merge-change step 5 copies, its placeholders filled and
    # committed with --cleanup=strip, as the step 7 hand-over commits it.
    template="$BATS_TEST_DIRNAME/../templates/squash-message.txt"
    grep -q '^Gate-tree: <tree>$' "$template" \
        || { echo "no Gate-tree line in the template"; false; }
    grep -q '^Tests: <command> <passed>/<total>$' "$template" \
        || { echo "no Tests line in the template"; false; }
    setup_ssh_signing
    make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    # A finding's disposition, tag and severity are filled with ones the
    # grammar takes. The fixture configures no coverage_command, so the
    # Coverage: line goes, as the template says where none is; and the squash
    # deletes no PR item, so the Resolves: line goes, as the template says.
    sed -e "s/^Gate-tree: <tree>\$/Gate-tree: $head_tree/" -e '/^Coverage:/d' -e '/^Resolves:/d' \
        -e 's/^1\. \[<disposition>\] <tag>\[ <severity>\]/1. [no change: <reason>] code low/' \
        -e 's|<passed>/<total>|5/5|' -e 's/:<line> /:1 /' -e 's/<[^>]*>/x/g' "$template" \
        | git -c commit.gpgsign=true -c core.commentChar='#' commit -q --amend -S --cleanup=strip -F -
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 0 ] || { echo "the template's message failed: $output"; false; }
}

# verifies: ADR-f6ytg7, ADR-3hsvvq
@test "finish-merge: a signed message with no reviewer: is refused, naming the amend that fixes it" {
    setup_ssh_signing
    make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    { message_body | grep -v '^reviewer:'; message_trailers "$head_tree"; } | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "INCOMPLETE-RECORD (no reviewer:)"
    output_has "already on the base branch"
    output_has "references/cleanup-rejections.md"
    # A core.commentChar other than # would keep the template's guidance.
    output_has "git -c core.commentChar='#' commit --amend -S --cleanup=strip -F <that file>"
}

# verifies: ADR-f6ytg7, ADR-3hsvvq
@test "finish-merge: every finding in the signed message is named, not just the first" {
    setup_ssh_signing
    make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    { message_body | grep -v '^verdict:'; message_trailers "$head_tree" | grep -v '^Tests:'; } \
        | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "INCOMPLETE-RECORD (no verdict:)"
    output_has "TESTS (want 1 Tests: trailers, one per verify_commands entry, found 0)"
}

# verifies: ADR-f6ytg7, ADR-3hsvvq
@test "finish-merge: an empty signed message is refused" {
    setup_ssh_signing
    make_squashed_change
    git -c commit.gpgsign=true commit -q --amend -S --allow-empty-message -m ''
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "MISSING-RECORD"
}

# verifies: ADR-f6ytg7, ADR-3hsvvq
@test "finish-merge: a finding with no disposition in the signed message is refused" {
    setup_ssh_signing
    make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    { message_body '1. code low — a name is unclear'; message_trailers "$head_tree"; } \
        | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "UNDISPOSED-FINDING 1"
}

# verifies: ADR-f6ytg7, ADR-3hsvvq
@test "finish-merge: a malformed line among the signed message's findings is refused" {
    setup_ssh_signing
    make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    { message_body '1. [no change: by design] code low — x
stray line'; message_trailers "$head_tree"; } | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "MALFORMED-FINDING stray line"
}

# verifies: ADR-f6ytg7, ADR-3hsvvq
@test "finish-merge: a Tests: trailer with a failure in it is refused" {
    setup_ssh_signing
    make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    { message_body; message_trailers "$head_tree" | sed 's|12/12$|11/12|'; } | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "FAILED-TESTS sh tests/run-tests.sh 11/12"
}

@test "finish-merge: guard 5 wants one Tests: trailer per verify_commands entry in HEAD's config" {
    # verifies: ADR-3hsvvq
    printf '  - make lint\n' >> .guardrails/config.yaml
    git add .guardrails/config.yaml
    git -c commit.gpgsign=false commit -qm "a second verify command"
    setup_ssh_signing
    make_squashed_change
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "TESTS (want 2 Tests: trailers, one per verify_commands entry, found 1)"
}

@test "finish-merge: guard 5 in a repository with no configuration wants one Tests: trailer" {
    # verifies: ADR-3hsvvq
    # A repository without .guardrails/config.yaml owes one Tests: and no
    # Coverage:, so guard 5 passes the fixture's one Tests: trailer.
    git rm -q .guardrails/config.yaml
    git -c commit.gpgsign=false commit -qm "no configuration"
    setup_ssh_signing
    make_squashed_change
    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    if branch_exists my-change; then echo "branch still exists"; false; fi
}

@test "finish-merge: guard 5 in a repository with no configuration refuses a message with no Tests: trailer" {
    # verifies: ADR-3hsvvq
    git rm -q .guardrails/config.yaml
    git -c commit.gpgsign=false commit -qm "no configuration"
    setup_ssh_signing
    make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    { message_body; message_trailers "$head_tree" | grep -v '^Tests:'; } | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "TESTS (want 1 Tests: trailers, one per verify_commands entry, found 0)"
}

@test "finish-merge: guard 5 reads a placeholder Base: as missing" {
    # verifies: ADR-3hsvvq
    setup_ssh_signing
    make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    { message_body; message_trailers "$head_tree" | sed 's/^Base: .*/Base: <base ref> at <commit>/'; } \
        | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "BASE (want one Base: trailer, found a placeholder)"
}

@test "finish-merge: guard 5 refuses a squash whose Resolves: omits a deleted PR" {
    # verifies: ADR-3hsvvq
    # The range is the squash, HEAD^..HEAD: the problem report it deletes is
    # owed in Resolves:, and the message make_squashed_change signs names none.
    printf '**PR-abc234**: a problem\nstatus: open\n' > docs/problems/open.md
    git add docs/problems/open.md
    git -c commit.gpgsign=false commit -qm "a problem"
    setup_ssh_signing
    DELETE_PATH=docs/problems/open.md make_squashed_change
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "RESOLVES (deleted PR-abc234, not named in Resolves:)"
}

@test "finish-merge: guard 5 refuses a squash whose Items: omits a deleted REQ" {
    # verifies: ADR-3hsvvq
    # The squash deletes a requirement, and the message make_squashed_change
    # signs has no Items: section.
    printf '**REQ-abc234**: a requirement\n' > docs/requirements/srs.md
    git add docs/requirements/srs.md
    git -c commit.gpgsign=false commit -qm "a requirement"
    setup_ssh_signing
    DELETE_PATH=docs/requirements/srs.md make_squashed_change
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "ITEMS (deleted REQ-abc234, not named under Items:)"
}

@test "finish-merge: a failing git diff of the problem ledgers exits 2 with nothing removed" {
    # verifies: ADR-3hsvvq
    # A fault injector at the git boundary: the one diff that reads the
    # problem reports the squash deletes fails, every other git call is real.
    setup_ssh_signing
    make_squashed_change
    stub_directory=$(make_git_failing_on '*" --unified=0 --no-renames "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    output_has "fatal: stub failure of git diff --no-color"
    output_has "the items the squash deletes cannot be read"
    output_has "Nothing was removed and"
    assert_nothing_removed
}

# verifies: ADR-f6ytg7, ADR-3hsvvq
@test "finish-merge: a Mutation: trailer not in the documented form is refused" {
    setup_ssh_signing
    make_squashed_change
    head_tree=$(git rev-parse 'HEAD^{tree}')
    { message_body; message_trailers "$head_tree"; printf 'Mutation: killed some mutants\n'; } \
        | resign_with_message
    run sh .guardrails/scripts/finish-merge.sh my-change
    assert_guard5_refused "MALFORMED-MUTATION killed some mutants"
}

# --- --check: guard 4 proved before the signing touch ------------------------
#
# Guard 4 is fully knowable before the squash commit exists, but every guard in
# this script was run only as the chained tail of the signed commit — so a
# rejection
# was discovered AFTER the hardware-key touch merge-change step 7 hands to the
# user. `--check` proves guard 4 and nothing else: guards 1, 2 and 5 read the
# squash commit, which does not exist at the point this mode is for, and guard
# 3 is `git worktree remove` itself and cannot be proved without doing it.

# verifies: PR-k77dzn
@test "finish-merge: --check reports a nested worktree and removes nothing" {
    setup_ssh_signing
    ignore_worktrees_dir
    make_squashed_change
    nested=$(nest_task_worktree)
    printf 'uncommitted\n' > "$nested/NEW.txt"

    run sh .guardrails/scripts/finish-merge.sh --check my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"a registered worktree lies inside"* ]] \
        || { echo "expected the SINGULAR nesting verdict, got: $output"; false; }
    [[ "$output" == *"$nested"* ]] \
        || { echo "the verdict did not name the nested worktree: $output"; false; }

    # Removed nothing, deleted nothing — the mode is a question, not an act.
    [ -f "$nested/NEW.txt" ] \
        || { echo "the nested worktree's work was destroyed by a CHECK"; false; }
    assert_nothing_removed
    branch_exists my-change-t1 || { echo "the task branch was deleted"; false; }
}

# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
@test "finish-merge: --check names the task-worktree.sh remedy for each kind of nested worktree" {
    # Before the squash, every nested worktree is retired with `remove <tag>`,
    # the review worktree included, and a branch remove rejects is discarded
    # after recording, or kept by returning to develop-change. A worktree that
    # task-worktree.sh did not create gets the git commands. No remedy names
    # a merging command.
    setup_ssh_signing
    ignore_worktrees_dir
    make_squashed_change
    nest_task_worktree my-change-review >/dev/null

    run sh .guardrails/scripts/finish-merge.sh --check my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    output_has "the review worktree included"
    output_has "task-worktree.sh remove <tag>"
    output_has "If remove rejects on commits, those commits were never gated or reviewed"
    output_has "task-worktree.sh discard <tag>"
    output_has "return to develop-change"
    output_has "rerun merge-change from step 1"
    output_has "git worktree remove <path>"
    output_has "git branch -D <branch>"
    output_lacks "task-worktree.sh merge"
    output_lacks "task-worktree.sh $retired_command"
    output_lacks "not in the squash"
    assert_nothing_removed
}

# verifies: PR-k77dzn
@test "finish-merge: --check exits 0 when nothing is nested" {
    setup_ssh_signing
    ignore_worktrees_dir
    make_squashed_change

    run sh .guardrails/scripts/finish-merge.sh --check my-change
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [[ "$output" == *"nothing is registered inside"* ]] \
        || { echo "expected the clean verdict, got: $output"; false; }
    assert_nothing_removed
}

# verifies: PR-k77dzn
@test "finish-merge: --check runs from the change worktree, before any squash" {
    # The test that matters most. This mode is for merge-change step 6c — in
    # the change worktree, before the squash is staged — which is exactly the
    # state the linked-worktree rejection and guards 1 and 2 make impossible.
    # `gr_base_branch` reads the FIRST worktree in the porcelain listing, the
    # primary checkout, so it still answers correctly from in here.
    make_change_worktree
    run sh .guardrails/scripts/finish-merge.sh --check my-change
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [[ "$output" == *"nothing is registered inside"* ]] \
        || { echo "expected the clean verdict, got: $output"; false; }
}

# verifies: PR-k77dzn
@test "finish-merge: --check rejects the base branch" {
    # A usage error, not a verdict: naming the base branch here would report on
    # the primary checkout and read as a green light for a cleanup that would
    # delete the base branch.
    setup_ssh_signing
    make_squashed_change
    run sh .guardrails/scripts/finish-merge.sh --check main
    [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
    # The exit code alone is satisfied by "unknown argument: --check", so the
    # rejection this test claims to cover is named as well.
    [[ "$output" == *"is the base branch"* ]] \
        || { echo "expected the base-branch rejection, got: $output"; false; }
    assert_nothing_removed
}

# verifies: PR-k77dzn
@test "finish-merge: --check never removes, even with everything green" {
    # Everything the real run needs is in place — signed squash, clean
    # worktree, nothing nested — and the check still removes nothing. A mode
    # that cleaned up on a green answer would be the script, not a preflight.
    setup_ssh_signing
    make_squashed_change
    run sh .guardrails/scripts/finish-merge.sh --check my-change
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    run git worktree list
    [[ "$output" == *"$CHANGE_WT"* ]] \
        || { echo "the change worktree was unregistered by a check: $output"; false; }
    assert_nothing_removed
}

# verifies: PR-k77dzn
# The preflight's value is telling the operator what step 8 would state, so it
# must not state it in a different number. Guard 4 switches singular/plural on an
# embedded newline; this proves --check switches with it. The singular
# direction is asserted by the nested-worktree test above.
@test "finish-merge: --check reports two nested worktrees in the plural, naming both" {
    setup_ssh_signing
    ignore_worktrees_dir
    make_squashed_change
    first=$(nest_task_worktree my-change-t1)
    second=$(nest_task_worktree my-change-t2)

    run sh .guardrails/scripts/finish-merge.sh --check my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"registered worktrees lie inside"* ]] \
        || { echo "expected the PLURAL nesting verdict, got: $output"; false; }
    [[ "$output" == *"$first"* ]] \
        || { echo "the verdict did not name the first worktree: $output"; false; }
    [[ "$output" == *"$second"* ]] \
        || { echo "the verdict did not name the second worktree: $output"; false; }
}

# verifies: PR-k77dzn
@test "finish-merge: --check with no registered worktree states nothing was inspected" {
    # The third green this mode can print, and the one that proves NOTHING. A
    # branch that exists but has no worktree registered leaves guard 4 with
    # nothing to reject, which is a true statement and an exit 0 the removal
    # mode agrees with — it tolerates an already-gone worktree and still
    # deletes the branch. What the wording must not do is read like the clean
    # verdict beside it: `nothing is registered inside <path>` is a scan that
    # was run; this is a scan that never had a path to run against.
    setup_ssh_signing
    make_squashed_change
    git worktree remove "$BATS_TEST_TMPDIR/wt"

    run sh .guardrails/scripts/finish-merge.sh --check my-change
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [[ "$output" == *"nothing was inspected"* ]] \
        || { echo "the verdict did not state nothing was inspected: $output"; false; }
    [[ "$output" == *"check the branch name"* ]] \
        || { echo "the verdict did not name the likely cause: $output"; false; }
    # Not the clean verdict. That one means a scan was run and found nothing,
    # and an operator who reads this as that one takes an unproved guard 4 into
    # the key touch this mode exists to save.
    [[ "$output" != *"nothing is registered inside"* ]] \
        || { echo "an uninspected branch printed the CLEAN verdict: $output"; false; }
    branch_exists my-change || { echo "the branch was deleted by a check"; false; }
}

# verifies: PR-k77dzn
@test "finish-merge: --check rejects a failing git worktree list, it does not report a clean tree" {
    # The preflight reads the registry itself, so it owns this false green
    # separately from the removal mode's copy of it (covered by the test near
    # the top of this file). A scan that ERRORS finds nothing, and "found
    # nothing" is exactly what a clean tree looks like: without the status
    # check `$wt_list` is empty, `$wt` comes back empty with it, and this mode
    # prints a green verdict about a change worktree it never looked at — the
    # operator then spends the key touch and meets guard 4 anyway.
    make_change_worktree
    cd "$REPO"
    bin=$(make_failing_worktree_list)
    PATH="$bin:$PATH" run sh .guardrails/scripts/finish-merge.sh --check my-change
    [ "$status" -ne 0 ] || { echo "expected a rejection, got 0: $output"; false; }
    [[ "$output" == *"git worktree list failed"* ]] \
        || { echo "expected the registry rejection, got: $output"; false; }
    assert_nothing_removed
}

# verifies: PR-tz6gsp
@test "finish-merge: --check exits 2 when gr_base_branch's git worktree list fails" {
    # Before gr_base_branch took the status, its failure printed nothing, which
    # this mode accepts as a detached primary checkout, and the run reached its
    # own git worktree list: exit 2 for the second call, not the first.
    make_change_worktree
    cd "$REPO"
    stub_directory=$(make_git_failing_on '*" worktree list "*')
    PATH="$stub_directory:$PATH" run sh .guardrails/scripts/finish-merge.sh --check my-change
    [ "$status" -eq 2 ] || { echo "$status: $output"; false; }
    output_has "git worktree list failed, so the base branch cannot be read."
    output_lacks "so the worktrees cannot be inspected"
    output_lacks "detached"
    assert_nothing_removed
}

# verifies: PR-k77dzn
@test "finish-merge: --check rejects a failing awk, it does not report a clean tree" {
    # The same false green through the other tool: the worktree path is
    # derived through awk, and an awk that dies leaves the substitution empty
    # — indistinguishable, without the status check, from a branch whose
    # worktree is genuinely unregistered. The mode would then print a verdict
    # about a path it never derived.
    make_change_worktree
    cd "$REPO"
    bin=$(make_failing_awk)
    PATH="$bin:$PATH" run sh .guardrails/scripts/finish-merge.sh --check my-change
    [ "$status" -ne 0 ] || { echo "expected a rejection, got 0: $output"; false; }
    [[ "$output" == *"could not be derived"* ]] \
        || { echo "expected the derivation rejection, got: $output"; false; }
    assert_nothing_removed
}

# verifies: PR-k77dzn
@test "finish-merge: -n is --check" {
    # The short spelling is documented in the header and nowhere else — not
    # even in the `usage:` strings, which spell only `[--check]` — so a test is
    # the only thing standing between it and a silent removal. Proved from
    # INSIDE the change worktree, where both ways of getting `-n` wrong are
    # exit 2 and neither can be mistaken for this: an unparsed `-n` falls to
    # the `-*` arm as `unknown argument: -n`, and a `-n` that failed to turn
    # the mode on reaches the linked-worktree rejection.
    make_change_worktree
    run sh .guardrails/scripts/finish-merge.sh -n my-change
    [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
    [[ "$output" == *"nothing is registered inside"* ]] \
        || { echo "expected the clean verdict, got: $output"; false; }
}
