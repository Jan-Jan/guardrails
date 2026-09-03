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
    _wt=${1:-${CHANGE_WT:-$BATS_TEST_TMPDIR/wt}}
    [ -d "$_wt" ] || { echo "the worktree was removed anyway"; false; }
    branch_exists my-change || { echo "the branch was deleted anyway"; false; }
}

# `.worktrees/` ignored, in the BASE commit. Both halves matter. Ignored, so
# the change worktree's own `git status` stays clean with a nested worktree
# sitting in it — that invisibility is the whole hazard. In the base commit, so
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
# --porcelain` records. On macOS `TMPDIR` sits under `/var`, a symlink to
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
# true the tests below go RED rather than quietly passing on the wrong refusal:
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

@test "finish-merge: a failing git worktree list refuses instead of deleting the branch" {
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
    # to `git branch -D`, and GIT refuses it — "cannot delete branch used by
    # worktree" — so the branch survives by accident, not by any guard. An
    # assertion on the branch alone would therefore have passed the mutant.
    # The refusal's IDENTITY is what kills it, and it is asserted below.
    setup_ssh_signing
    make_squashed_change
    bin=$(make_failing_worktree_list)
    PATH="$bin:$PATH" run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -ne 0 ] || { echo "expected a refusal, got 0: $output"; false; }
    [[ "$output" == *"git worktree list failed"* ]] \
        || { echo "expected the registry refusal, got: $output"; false; }
    assert_nothing_removed
}

@test "finish-merge: a failing awk refuses instead of deleting the branch" {
    # verifies: PR-n57ayn
    # The worktree path is derived through awk, and an awk that dies leaves the
    # substitution empty — indistinguishable, without the status check, from a
    # branch whose worktree the harness already removed. The script would then
    # report "no worktree was registered", skip guard 4 and the removal, and
    # delete the branch anyway, with the real worktree still on disk.
    #
    # Same provenance as the test above: written after the check it covers,
    # green on arrival, mutation-checked on its own by deleting the `|| gr_die`
    # — and killed the same way, by the refusal's identity rather than by the
    # branch's survival, which git's own "used by worktree" refusal supplies
    # here whatever this script does.
    setup_ssh_signing
    make_squashed_change
    bin=$(make_failing_awk)
    PATH="$bin:$PATH" run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -ne 0 ] || { echo "expected a refusal, got 0: $output"; false; }
    [[ "$output" == *"could not be derived"* ]] \
        || { echo "expected the derivation refusal, got: $output"; false; }
    assert_nothing_removed
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

@test "finish-merge: a worktree nested inside the change worktree fails with everything intact" {
    # verifies: PR-n57ayn
    # Guard 3 delegates to `git worktree remove` without --force, and that
    # refusal cannot see a NESTED worktree: `.worktrees/` is gitignored, so the
    # change worktree's own `git status` is clean, and git removes the outer
    # worktree — files and all — at exit 0. Measured before this guard existed,
    # in a scratch repository and in this fixture alike: the nested worktree's
    # uncommitted work was deleted, its registration left `prunable`, and its
    # task branch orphaned. Nesting is what worktree-discipline now mandates,
    # so this change created the hazard and this guard closes it.
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
    # Assert this guard's OWN refusal, and the offending path in it, not merely
    # a non-zero exit: the next thing the user does is go and look at that
    # worktree, so the message has to say which one. A test pinning the exit
    # code alone survives deletion of the guard it claims to cover.
    [[ "$output" == *"a registered worktree lies inside"* ]] \
        || { echo "expected the nesting refusal, got: $output"; false; }
    [[ "$output" == *"$nested"* ]] \
        || { echo "the refusal did not name the nested worktree: $output"; false; }

    [ -f "$nested/NEW.txt" ] \
        || { echo "the nested worktree's uncommitted work was destroyed"; false; }
    assert_nothing_removed
    branch_exists my-change-t1 || { echo "the task branch was orphaned"; false; }
}

@test "finish-merge: a nested worktree is refused even when it holds nothing uncommitted" {
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
        || { echo "expected the nesting refusal, got: $output"; false; }
    [[ "$output" == *"$nested"* ]] \
        || { echo "the refusal did not name the nested worktree: $output"; false; }
    assert_nothing_removed
}

@test "finish-merge: a backslash in the change worktree's path does not defeat the guard" {
    # verifies: PR-n57ayn
    # `awk -v k=v` ESCAPE-PROCESSES the value before the program sees it, so a
    # change worktree at `.../w\top` reached guard 4's prefix test spelled
    # `.../w<TAB>op/`. Nothing then matched, `$nested` came back empty, and the
    # guard PASSED — after which guard 3 removed the change worktree with the
    # nested one inside it, uncommitted work and all, at exit 0. Every other
    # refusal in this script fails closed and merely withholds cleanup; this
    # one lost work, silently, which is why the prefix test carries no escape
    # layer at all any more.
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
        || { echo "expected the nesting refusal, got: $output"; false; }
    [[ "$output" == *"$nested"* ]] \
        || { echo "the refusal did not name the nested worktree: $output"; false; }
    assert_nothing_removed
}

@test "finish-merge: every nested worktree is named, not just the first" {
    # verifies: PR-n57ayn
    # A five-way fan-out leaves five task worktrees. Reporting one and exiting
    # makes the operator run the script five times, and each round pays a full
    # `check-signing.sh --strict` — a hardware key touch per hidden worktree.
    # The refusal lists all of them, and changes number when it does.
    setup_ssh_signing
    ignore_worktrees_dir
    make_squashed_change
    first=$(nest_task_worktree my-change-t1)
    second=$(nest_task_worktree my-change-t2)

    run sh .guardrails/scripts/finish-merge.sh my-change
    [ "$status" -eq 1 ] || { echo "expected exit 1, got $status: $output"; false; }
    [[ "$output" == *"$first"* ]] \
        || { echo "the refusal did not name $first: $output"; false; }
    [[ "$output" == *"$second"* ]] \
        || { echo "the refusal did not name $second: $output"; false; }
    [[ "$output" == *"registered worktrees lie inside"* ]] \
        || { echo "expected the plural refusal, got: $output"; false; }
    assert_nothing_removed
}

@test "finish-merge: a sibling whose path merely starts with the change worktree's is not nested" {
    # verifies: PR-n57ayn
    # `<wt>-sibling` starts with `<wt>` and is NOT inside it. A prefix test
    # written without the separator would call it nested and refuse every
    # cleanup that had one lying beside it — guard 4 failing CLOSED, on a state
    # with nothing wrong in it. The trailing `/` is the whole difference, and
    # nothing else in this file holds it there.
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
    ! branch_exists my-change || { echo "branch survived"; false; }
}

@test "finish-merge: a space in the change worktree's path does not defeat the guard" {
    # verifies: PR-n57ayn
    # The prefix test walks git's porcelain output line by line, and a path
    # with a space in it survives that walk only if the whole line is read as
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
        || { echo "expected the nesting refusal, got: $output"; false; }
    [[ "$output" == *"$nested"* ]] \
        || { echo "the refusal did not name the nested worktree: $output"; false; }
    assert_nothing_removed
}
