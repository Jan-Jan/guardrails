# Content lints over the skills, in the spirit of portability.bats's sweep:
# a skill instruction that quietly loses a critical phrase fails here
# rather than in some target project months later.

@test "ratchet: tool qualification states how and where the suite runs" {
    # verifies: PR-ac96zf
    # The step-5 checklist item asks the installer to record the suite result
    # at install time. Without these three anchors it never stated how that
    # result is produced, and a /ratchet run in a target project was left to
    # improvise — up to and including installing bats into the target repo or
    # running the suite there.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'tests/run-tests.sh' "$skill"
    grep -q 'bats is never installed' "$skill"
    grep -q 'suite not run at install time:' "$skill"
}

@test "ratchet: tool qualification warns that a pipe discards the suite's exit status" {
    # verifies: PR-nzpp57
    # The step-5 item requires capturing the suite's exit code, but a natural
    # way to run it — `run-tests.sh | tee log` — leaves $? set to tee's status,
    # and the recorded pass/fail is then the wrong command's. A reporter
    # nearly recorded a wrong result exactly this way.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'never through a pipe' "$skill"
    grep -q "the wrong command's" "$skill"
}

@test "verification template warns that a range in a finding header opens no block" {
    # verifies: PR-geb5db
    # check-review.sh already reports a range-shaped header (finding-2..4) as
    # MALFORMED-FINDING — gr_finding_shaped is deliberately broad — but the
    # template never taught the rule, so reviewers discovered it from the
    # failure instead of from the document that shapes the record.
    template="$BATS_TEST_DIRNAME/../templates/verification.md"
    grep -q 'A range opens no block' "$template"
}

@test "ratchet: updating the scripts also refreshes the ledger READMEs" {
    # verifies: PR-uavq3f
    # The upgrade guidance replaced the scripts and the AGENTS.md managed
    # block but never the ledger READMEs, so a target project's READMEs kept
    # teaching grammar the scripts no longer read (the owner: case) — one
    # commit contained an AGENTS.md and a docs/problems/README.md contradicting
    # each other about a required field.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'Update the files that document the grammar with the scripts' "$skill"
    grep -q 'Re-copy the four ledger READMEs' "$skill"
}

@test "ratchet: the qualification basis names a commit, not just a version" {
    # verifies: PR-dcn2xc
    # "435 tests at 0.5.1" is nominal the moment upstream advances without a
    # version bump; a recorded commit makes the basis checkable. The skill
    # must tell the installer to record it, and the shipped config template
    # must contain the key it is recorded under.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'guardrails_commit' "$skill"
    grep -q 'guardrails_commit' "$BATS_TEST_DIRNAME/../templates/config.yaml"
}

@test "worktree-discipline: the task worktree is nested inside the change worktree" {
    # verifies: PR-n57ayn
    # Step 1 used to pick the task worktree's location by convention, and
    # presented the harness location beside the change worktree as an equally
    # good option. A dispatched subagent that took it was pinned to the change
    # worktree's subtree and could not use what it had just created. The rule
    # is containment; the false-success traps are why the failure arrived too
    # late to undo.
    skill="$BATS_TEST_DIRNAME/../skills/worktree-discipline/SKILL.md"
    grep -q 'nested inside the change worktree' "$skill"
    grep -q 'pins that subagent to a subtree' "$skill"
    grep -q 'reports success and then rejects' "$skill"
}

@test "develop-change: the dispatch prompt names the nested task worktree path" {
    # verifies: PR-n57ayn
    # A subagent cannot discover its pin before it violates it, so the
    # dispatcher states the path instead of leaving the subagent to choose it.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -q '\.worktrees/<change-branch>-t3' "$skill"
}

@test "the repository ignores the nested task-worktree directory" {
    # verifies: PR-n57ayn
    # worktree-discipline makes the ignore entry the dispatcher's
    # precondition, and an unignored task worktree would dirty
    # verify-before-merge's clean git status.
    grep -qx '\.worktrees/' "$BATS_TEST_DIRNAME/../.gitignore"
}

@test "develop-change: the dispatch prompt forbids the change branch, not the change worktree" {
    # verifies: PR-n57ayn
    # Under the containment rule the subagent starts pinned in the change
    # worktree and must run `git worktree add` from there, so "do not enter
    # the change worktree" is unfollowable. What is actually forbidden is
    # committing on the change branch and continuing there once the task
    # worktree exists.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of its position, not an assertion.)
    run grep -q 'do not enter the change worktree' "$skill"
    [ "$status" -ne 0 ]
    grep -q 'do not commit on <change-branch>' "$skill"
}

@test "worktree-discipline: a fresh task worktree has none of the ignored artifacts" {
    # verifies: PR-n57ayn
    # A worktree branched fresh off the change branch checks out the tree and
    # nothing else, so a vendored test runner or an installed dependency is
    # simply absent — and the runner that tries to refetch it fails on a
    # machine without network access. Copying it across is free and leaves
    # the tree clean.
    skill="$BATS_TEST_DIRNAME/../skills/worktree-discipline/SKILL.md"
    grep -q 'only tracked files' "$skill"
    grep -q 'gitignored by definition' "$skill"
}

@test "merge-change: the review dispatch names the reviewer's worktree path" {
    # verifies: PR-n57ayn
    # The containment rule was applied at develop-change's dispatch site only.
    # Step 6a dispatches a reviewer that creates a task worktree of its own,
    # and a reviewer left to choose the location repeats the whole failure —
    # so the path is stated here too. The reviewer has no task number, hence
    # the `-review` tag.
    #
    # Anchored by POSITION, not presence. The literal now appears three times
    # in the file — the dispatch, the removal command, and the prose around it
    # — so a bare `grep -q` for it still passed when the ONE occurrence that
    # states the rule was mutated. The dispatch's occurrence is the first in
    # the file, it is inside step 6a, and it comes before the removal command
    # that repeats it; mutate it and the first occurrence becomes the removal
    # line, which is not less than itself.
    #
    # Re-aimed 2026-09-29 under D4 of docs/plans/2026-09-28-agent-first-skills.md:
    # the removal command is `task-worktree.sh remove review`, which takes the
    # tag, so the dispatch is the only occurrence of the path.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    a_at=$(grep -n '^6a\. \*\*Independent review\*\*' "$skill" | head -n 1 | cut -d: -f1)
    b_at=$(grep -n '^6b\. \*\*Verification record\*\*' "$skill" | head -n 1 | cut -d: -f1)
    path_at=$(grep -n '\.worktrees/<change-branch>-review' "$skill" | head -n 1 | cut -d: -f1)
    # Re-aimed 2026-10-01 under D4: the review worktree is retired with
    # `remove review`, which merges nothing.
    remove_at=$(grep -n 'task-worktree\.sh remove review' \
        "$skill" | head -n 1 | cut -d: -f1)
    [ -n "$a_at" ]
    [ -n "$b_at" ]
    [ -n "$path_at" ]
    [ -n "$remove_at" ]
    [ "$path_at" -gt "$a_at" ]
    [ "$path_at" -lt "$b_at" ]
    [ "$path_at" -lt "$remove_at" ]
}

@test "merge-change: the review worktree is removed at the end of its own dispatch" {
    # verifies: PR-n57ayn
    # Step 6d was the only place that removed the review worktree, and step 6a
    # ends "the sequence reruns from step 1" when findings come back — so 6b,
    # 6c and 6d are reached only on the final, finding-free round. The path and
    # the branch are fixed, so every intermediate round's worktree remained and
    # the next round's dispatch failed with `fatal: a branch named
    # '<change-branch>-review' already exists`. The removal belongs where the
    # dispatch ends, inside step 6a, which is what worktree-discipline already
    # states of every task worktree. Step 6d keeps the structural check, so a
    # skipped removal is still caught before the squash rather than at
    # finish-merge.sh.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    a_at=$(grep -n '^6a\. \*\*Independent review\*\*' "$skill" | head -n 1 | cut -d: -f1)
    b_at=$(grep -n '^6b\. \*\*Verification record\*\*' "$skill" | head -n 1 | cut -d: -f1)
    # Re-aimed 2026-10-01 under D4: the review worktree is retired with
    # `remove review`, which merges nothing.
    remove_at=$(grep -n 'task-worktree\.sh remove review' \
        "$skill" | head -n 1 | cut -d: -f1)
    [ -n "$a_at" ]
    [ -n "$b_at" ]
    [ -n "$remove_at" ]
    [ "$remove_at" -gt "$a_at" ]
    [ "$remove_at" -lt "$b_at" ]
    # 6d still checks the registry structurally — the removal moved, the check
    # did not.
    d_at=$(grep -n '^6d\. ' "$skill" | head -n 1 | cut -d: -f1)
    s_at=$(grep -n '^7\. \*\*Squash onto the base branch' "$skill" | head -n 1 | cut -d: -f1)
    [ -n "$d_at" ]
    [ -n "$s_at" ]
    # Re-aimed 2026-09-10 (PR-k77dzn): the structural check is now a command
    # with a verdict, `finish-merge.sh --check`, rather than a raw
    # `git worktree list` the author reads by eye. What this pin protects is
    # that 6d still checks the registry at all — not which spelling it uses.
    # Re-aimed 2026-09-29 under D4: the 6c pre-flight runs that check as
    # NESTED-WORKTREE, and 6d is where its failure is answered.
    sed -n "${d_at},${s_at}p" "$skill" | grep -q 'NESTED-WORKTREE'
    # worktree-discipline cross-references the removal's home, so it follows it
    # there rather than leaving the two skills to drift.
    wd="$BATS_TEST_DIRNAME/../skills/worktree-discipline/SKILL.md"
    grep -q 'the end of `merge-change` step 6a' "$wd"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of its position, not an assertion.)
    run grep -q 'step 6d' "$wd"
    [ "$status" -ne 0 ]
}

@test "merge-change: every fix dispatch names the nested task worktree path" {
    # verifies: PR-n57ayn
    # Two more dispatch statements in this file are normative and were
    # unasserted: the sequence header's fix dispatch, and 6a's dispatch of the
    # fix for a finding. A mutant replacing both with "a task worktree"
    # passed the suite. Both are pinned, and by position, so replacing either
    # one is not covered by the other.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    count=$(grep -c '\.worktrees/<change-branch>-<tag>' "$skill")
    [ "$count" -eq 2 ]
    one_at=$(grep -n '^1\. \*\*Merge the latest base branch' "$skill" | head -n 1 | cut -d: -f1)
    a_at=$(grep -n '^6a\. \*\*Independent review\*\*' "$skill" | head -n 1 | cut -d: -f1)
    b_at=$(grep -n '^6b\. \*\*Verification record\*\*' "$skill" | head -n 1 | cut -d: -f1)
    header_at=$(grep -n '\.worktrees/<change-branch>-<tag>' "$skill" | head -n 1 | cut -d: -f1)
    finding_at=$(grep -n '\.worktrees/<change-branch>-<tag>' "$skill" | tail -n 1 | cut -d: -f1)
    [ -n "$one_at" ]
    [ -n "$a_at" ]
    [ -n "$b_at" ]
    [ "$header_at" -lt "$one_at" ]
    [ "$finding_at" -gt "$a_at" ]
    [ "$finding_at" -lt "$b_at" ]
}

@test "merge-change: a review worktree left dirty by scratch has a remedy" {
    # verifies: PR-n57ayn
    # `git worktree remove` fails on untracked files as well as modified
    # ones, and a reviewer leaves scratch behind — a log, a note. The step
    # identified the state to check and stopped there, which leaves `--force`
    # as the only obvious way out of it, and `--force` is what destroys the
    # thing the guard exists to protect.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    # Re-aimed 2026-10-01 under D4: the removal is `task-worktree.sh remove`.
    grep -q 'rejects untracked files as well as modified ones' "$skill"
    grep -q 'read the scratch, delete it, and run `remove` again' "$skill"
    grep -q 'the remedy step 6a gives' "$skill"
    # The list of causes included "a test runner copied in because it was
    # gitignored and therefore absent" — the one entry that cannot cause the
    # rejection, and self-refuting: git does not see an ignored file, which is
    # exactly why it was absent. Reproduced directly: a worktree containing
    # only gitignored scratch has an empty `git status --porcelain` and is
    # removed with no rejection. It is also the negation of what guard 4 is for,
    # and of what worktree-discipline states correctly ("gitignored by
    # definition and so cannot dirty `git status`"), so the passage states it
    # rather than leaving the reader the older, wrong version.
    grep -q 'Nothing gitignored is among them' "$skill"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of its position, not an assertion.)
    run grep -rq 'gitignored and therefore absent' "$(dirname "$skill")"
    [ "$status" -ne 0 ]
}

@test "merge-change: step 6d's criterion is containment, not an empty registry" {
    # verifies: PR-n57ayn
    # The heading is containment-scoped — "nothing registered **inside** the
    # change worktree", which is what guard 4 objects to — but the criterion
    # sentence was absolute: "Nothing but the primary checkout and the change
    # worktree may still be registered." Run literally in this repository that
    # condemns three unrelated worktrees, two of them tooling rather than
    # changes, none of which guard 4 would ever name. The criterion is the
    # test the heading already states, and it is asserted inside step 6d
    # rather than anywhere in the file.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    d_at=$(grep -n '^6d\. ' "$skill" | head -n 1 | cut -d: -f1)
    s_at=$(grep -n '^7\. \*\*Squash onto the base branch' "$skill" | head -n 1 | cut -d: -f1)
    [ -n "$d_at" ]
    [ -n "$s_at" ]
    # The "read the list by eye" sentence went with the raw `git worktree list`
    # it described (PR-k77dzn); `--check` applies the containment criterion
    # itself. The criterion sentence below is what this pin is actually for,
    # and it stays — it is the half a command cannot state.
    sed -n "${d_at},${s_at}p" "$skill" | grep -q 'A worktree registered anywhere else is not this step'
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of its position, not an assertion.)
    run grep -rq 'Nothing but the primary checkout and the change worktree' "$(dirname "$skill")"
    [ "$status" -ne 0 ]
}

@test "merge-change: the review worktree removal is conditioned on one existing" {
    # verifies: PR-n57ayn
    # The removal was stated unconditionally ("Every round, findings or not"),
    # while the same step documents two paths on which no review worktree ever
    # exists: a human reviewer per team policy, and a class A change skipping
    # the step. Under a sequence headed "Halt on any failure", running
    # `git worktree remove` on a path that was never created is a failure. Step
    # 6d's wording is already conditioned on what this change *created*; 6a's
    # matches it.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    a_at=$(grep -n '^6a\. \*\*Independent review\*\*' "$skill" | head -n 1 | cut -d: -f1)
    b_at=$(grep -n '^6b\. \*\*Verification record\*\*' "$skill" | head -n 1 | cut -d: -f1)
    [ -n "$a_at" ]
    [ -n "$b_at" ]
    sed -n "${a_at},${b_at}p" "$skill" | grep -q 'every round that created one'
    sed -n "${a_at},${b_at}p" "$skill" | grep -q 'Not every round creates one'
    # Re-aimed 2026-10-01 under D4: `task-worktree.sh remove` takes a tag.
    sed -n "${a_at},${b_at}p" "$skill" | grep -q 'fails on a tag that was never started'
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of its position, not an assertion.)
    run grep -rq 'Every round, findings or not' "$(dirname "$skill")"
    [ "$status" -ne 0 ]
}

@test "merge-change: a fix dispatch's tag is unique, and AGENTS.md defers on tags" {
    # verifies: PR-n57ayn
    # verifies: D4 (docs/plans/2026-09-28-agent-first-skills.md)
    # `.worktrees/<change-branch>-<tag>` leaves the tag unconstrained, so the
    # rule that it must not repeat is worth keeping — but its first
    # justification was false. Two findings rounds that both use the
    # natural `fix` cannot collide at creation: a task worktree and its branch
    # are removed with their dispatch (`worktree-discipline`, step 8), so
    # round 1's `-fix` branch is gone before round 2 dispatches.
    # That is the same property step 6a rests on when it keeps the review tag
    # fixed, so the two rationales cannot both stand. The rule remains as
    # insurance against a cleanup that was missed, and the removal it insures
    # is now stated here as well, not only in `worktree-discipline` and
    # `develop-change`.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'must be unique per dispatch' "$skill"
    rationale="$(dirname "$skill")/references/rationale.md"
    grep -q 'insurance against a cleanup that was missed' "$rationale"
    grep -q 'keeps the review tag fixed at' "$rationale"
    grep -q 'remove the worktree and delete the task branch' "$skill"
    # The insurance clause is the critical half of that justification, so
    # what it insures against must not be understated. "no numbered step of
    # this sequence performs its removal" means the whole cleaning up —
    # `git worktree remove` and `git branch -d` — but the clause then called a
    # skipped cleanup met by a fresh tag "only a stale branch", which is the
    # branch-only case. A wholly skipped cleanup also leaves a registered
    # nested worktree; gitignored, it is invisible to `git status`, so step 6d
    # and guard 4 are what find it, late. The `fatal:` covers both cases
    # because git validates the new branch name before the worktree path.
    # Re-aimed 2026-10-01 under D4: `task-worktree.sh merge` does both after a
    # green report, and its `start` rejects a path or branch that already exists.
    grep -q 'task-worktree.sh merge <tag>' "$skill"
    grep -q 'the next round cannot create its worktree on that path and branch' "$rationale"
    grep -q 'skipped cleanup also leaves a nested worktree still registered' "$rationale"
    grep -q 'guard 4 rejects at step 8' "$rationale"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of its position, not an assertion.)
    run grep -rq 'collide at creation' "$(dirname "$skill")"
    [ "$status" -ne 0 ]
    run grep -rq 'it is only a stale branch' "$(dirname "$skill")"
    [ "$status" -ne 0 ]
    # AGENTS.md enumerated `<N>` as the plan task number "or the tag `review`
    # for the independent review", which has no slot for a fix dispatch's tag.
    # It then attributed the uniqueness rule to `worktree-discipline` step 1,
    # which does not state it; the rule is in `merge-change`'s sequence
    # header. AGENTS.md points at where each rule is stated instead of keeping a
    # second, shorter list that drifts.
    agents="$BATS_TEST_DIRNAME/../AGENTS.md"
    grep -q "\`merge-change\`'s sequence header" "$agents"
    run grep -q 'step 1 names them' "$agents"
    [ "$status" -ne 0 ]
    run grep -q 'the tag `review` for the independent review' "$agents"
    [ "$status" -ne 0 ]
}

@test "worktree-discipline: the location rule is scoped to a pinning harness" {
    # verifies: PR-n57ayn
    # The rule ships to other projects via /ratchet, and it rests on one dated
    # measurement of one harness. Stated as a law about harnesses in general
    # it is a law those projects never measured, so the passage names the
    # observation as an observation and tells a project how to tell whether
    # its own harness pins.
    skill="$BATS_TEST_DIRNAME/../skills/worktree-discipline/SKILL.md"
    grep -q 'Where a harness isolates a dispatched subagent' "$skill"
    grep -q 'measured once, on one harness' "$skill"
    grep -q 'does not pin its subagents' "$skill"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of its position, not an assertion.)
    run grep -q 'A harness that isolates a dispatched subagent pins' "$skill"
    [ "$status" -ne 0 ]
}

@test "worktree-discipline: the task worktree passage states how to get inside" {
    # verifies: PR-n57ayn
    # Creating the worktree is half the step. "Harness tool first" was deleted
    # with nothing put in its place, and `<N>` was never defined — so the
    # passage now walks create -> get inside, and states what `<N>` is,
    # including the review worktree that has no task number. The proof of
    # arrival has to work on both branches of "harness tool first": an agent
    # told to remain where it is and drive by path can run neither `pwd` nor a
    # bare `git status` in the target. And the artifacts to copy in are
    # identified by a command, not left to be guessed at.
    skill="$BATS_TEST_DIRNAME/../skills/worktree-discipline/SKILL.md"
    grep -q 'harness tool first' "$skill"
    grep -q '`<N>` is the plan task number' "$skill"
    grep -q '\.worktrees/<change-branch>-review' "$skill"
    grep -q 'git -C .worktrees/<change-branch>-t<N> status' "$skill"
    grep -q 'git status --ignored' "$skill"
    # The red flag that states the same thing two screens later has to agree, or
    # the retired framing remains in the one place an agent reads when it is
    # already unsure where it is.
    grep -q 'Prove the location with `git -C <path> status`' "$skill"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of its position, not an assertion.)
    #
    # Broadened from '`pwd` and `git status` in the target': that spelling was
    # only one of two the file contained, and the red flag's shorter one went
    # on stating exactly what this assertion exists to forbid.
    run grep -q '`git status` in the target' "$skill"
    [ "$status" -ne 0 ]
}

@test "the repository ignores the nested task-worktree directory exactly once" {
    # verifies: PR-n57ayn
    # This change added `.worktrees/` while the base branch added the same
    # line independently, and the base merge kept both. A duplicate makes the
    # preceding test vacuous: delete either line and it still passes.
    count=$(grep -cx '\.worktrees/' "$BATS_TEST_DIRNAME/../.gitignore")
    [ "$count" -eq 1 ]
}

@test "merge-change: the sequence removes the review worktree before the squash" {
    # verifies: PR-n57ayn
    # Step 6a now dispatches every reviewer into a worktree nested inside the
    # change worktree, and finish-merge.sh guard 4 will not remove a change
    # worktree that has a worktree registered inside it. Nothing in the
    # sequence removed the review worktree, so the documented happy path of
    # every change would reach step 7 and be rejected. The removal must come
    # before the squash is staged, so the ordering is asserted and not merely
    # the presence of the command.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    # Re-aimed 2026-10-01 under D4: the review worktree is retired with
    # `remove review`, which merges nothing.
    remove_at=$(grep -n 'task-worktree\.sh remove review' \
        "$skill" | head -n 1 | cut -d: -f1)
    squash_at=$(grep -n 'git merge --squash <branch>' "$skill" | head -n 1 | cut -d: -f1)
    [ -n "$remove_at" ]
    [ -n "$squash_at" ]
    [ "$remove_at" -lt "$squash_at" ]
    # Where inside the sequence the removal goes is the sibling test's subject
    # ("is removed at the end of its own dispatch"), including the
    # cross-reference from worktree-discipline. This one asserts only the
    # ordering against the squash, which is what finish-merge.sh's guard 4
    # makes critical.
    wd="$BATS_TEST_DIRNAME/../skills/worktree-discipline/SKILL.md"
    # The same bullet used to argue for taking the path from the dispatch
    # report "rather than rebuilding it", because `.worktrees/` is relative to
    # the change worktree while a harness location is not. Step 1 retired that
    # framing: there is one location now, and the dispatcher names it.
    grep -q 'the one the dispatcher named' "$wd"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of its position, not an assertion.)
    run grep -q 'rather than rebuilding it' "$wd"
    [ "$status" -ne 0 ]
}

@test "merge-change: step 8 maps guard 4's rejection to a remedy" {
    # verifies: PR-n57ayn
    # verifies: D4 (docs/plans/2026-09-28-agent-first-skills.md)
    # Step 7 counts the guards finish-merge.sh proves and step 8's table is the
    # one place that maps a rejection to a remedy. Guard 4 was added without
    # either being updated, leaving the rejection an operator is now most likely
    # to meet unexplained in both. The row quotes what the script prints.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'proves four things' "$skill"
    grep -q 'a registered worktree lies inside' \
        "$(dirname "$skill")/references/cleanup-rejections.md"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of its position, not an assertion.)
    run grep -rq 'proves three things' "$(dirname "$skill")"
    [ "$status" -ne 0 ]
}

@test "verify-before-merge: the fix dispatch names the nested task worktree path" {
    # verifies: PR-n57ayn
    # Three skills dispatch a fix into a task worktree of its own, and this is
    # the third site. Its path text was normative and unasserted: deleting it
    # left the suite green. Written as a characterization pin — green when
    # added, red the moment the phrase goes.
    skill="$BATS_TEST_DIRNAME/../skills/verify-before-merge/SKILL.md"
    grep -q '\.worktrees/<change-branch>-<tag>' "$skill"
    grep -q 'nested inside the change worktree' "$skill"
}

@test "ratchet: both worktree directories are gitignored, and why each is" {
    # verifies: PR-n57ayn
    # /ratchet is how the containment rule reaches other projects, and the
    # ignore entry is the dispatcher's precondition for it: without
    # `.worktrees/` the nested task worktree dirties verify-before-merge's
    # clean git status. The paragraph was normative and unasserted.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -qx '   \.worktrees/' "$skill"
    grep -qx '   \.claude/worktrees/' "$skill"
    grep -q 'Add both worktree entries even where the project has only ever used' "$skill"
    grep -q 'every task worktree, which is nested inside the change worktree' "$skill"
}

@test "AGENTS.md: non-negotiable 1 nests the task worktree and names its path" {
    # verifies: PR-n57ayn
    # This repository develops under its own rules, so non-negotiable 1 is
    # where an agent reads the containment rule first. It was rewritten for
    # this change and no test asserted it.
    agents="$BATS_TEST_DIRNAME/../AGENTS.md"
    grep -q 'nested inside the change worktree' "$agents"
    grep -q '\.worktrees/<change-branch>-t<N>' "$agents"
    grep -q 'names that path in the dispatch prompt' "$agents"
    grep -q "pinned to the change worktree's subtree" "$agents"
    # Both path forms are spelled out, because "a dispatch without one taking a
    # tag instead" parses as substituting the tag inside `-t<N>` — giving
    # `.worktrees/<change-branch>-treview`, not the `-review` that
    # `merge-change` step 6a names and that every review worktree here has
    # used. `worktree-discipline` disambiguates with a concrete path; AGENTS.md
    # had none, so it names the second form instead of describing it.
    grep -q '\.worktrees/<change-branch>-<tag>' "$agents"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of its position, not an assertion.)
    run grep -q 'a dispatch without one taking a tag instead' "$agents"
    [ "$status" -ne 0 ]
}

@test "AGENTS.md: non-negotiable 5 states the rule and points to its ADR" {
    # verifies: D10 (docs/plans/2026-09-28-agent-first-skills.md)
    agents="$BATS_TEST_DIRNAME/../AGENTS.md"
    adr="$BATS_TEST_DIRNAME/../docs/adr/ADR-y8jmes-local-main-is-the-base.md"
    grep -q 'Never consult `origin`' "$agents"
    grep -q 'docs/adr/ADR-y8jmes-local-main-is-the-base.md' "$agents"
    grep -q 'GR_ID_ANY' "$adr"
    run grep -q 'GR_ID_ANY' "$agents"
    [ "$status" -ne 0 ]
}

@test "problem grammar prose: no shipped file still contains owner:" {
    # verifies: PR-dudg35
    # owner: was dropped from the problem-item grammar; any shipped prose
    # (templates, skills, READMEs) still requiring or documenting it would
    # reintroduce the field the scripts no longer read. The dated ledger
    # files and this test are deliberately out of scope: leftover owner:
    # lines in ledgers are inert, and this file names the literal to grep.
    root="$BATS_TEST_DIRNAME/.."
    run grep -n 'owner:' \
        "$root/templates/problems.md" \
        "$root/templates/AGENTS-block.md" \
        "$root/skills/resolve-problem/SKILL.md" \
        "$root/skills/check-traceability/SKILL.md" \
        "$root/skills/ratchet/SKILL.md" \
        "$root/README.md" \
        "$root/docs/problems/README.md"
    [ "$status" -ne 0 ]
    [ -z "$output" ]
}

@test "ratchet-asks-one-system-or-many: mode detection includes the units question" {
    # verifies: D9 (docs/plans/2026-08-26-monorepo-support.md)
    # Without this question a twelve-package repository gets a root config and
    # every gate silently reads one unit's facts as the whole tree's.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'one system in many packages, or many systems' "$skill"
    grep -q 'a single-unit project gets no manifest' "$skill"
}

@test "ratchet-units-interview-writes-facts-not-rules: the D9 line is stated in the skill" {
    # verifies: D9
    # The interview writes units:, not_a_unit:, depends_on:, segregated_from:,
    # safety_class — and must STATE it does not ask about the rules, or the next
    # editor adds the enforcement knob D9 rejects by name.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'declares the facts; the rules are not configurable' "$skill"
    grep -q 'not_a_unit:' "$skill"
    grep -q 'segregated_from:' "$skill"
    grep -q 'whether the class floor applies' "$skill"
}

@test "ratchet-manifest-repo-has-no-root-config: scaffold branches on the manifest" {
    # verifies: D2/D9; exclusivity implemented in gr_check_units (0a35669)
    # Copying templates/config.yaml to the root of a manifest repository is
    # exit 2 at the next gate — the scaffold step must state which file goes
    # where in each mode, or ratchet scaffolds a rejected shape.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'templates/units.yaml' "$skill"
    grep -q 'no root .guardrails/config.yaml' "$skill"
    grep -q '<unit>/.guardrails/config.yaml' "$skill"
}

@test "ratchet-tooth-one-is-manifest-and-disclaimers: adoption order is stated" {
    # verifies: D9 (tooth ordering, confirmed 2026-08-31)
    # Without the ordering, adoption on a large repo reads as all-or-nothing
    # and the honest first tooth (manifest + disclaimers, no edges) is missed.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'Adopt in order, one step at a time' "$skill"
    grep -q 'empty `depends_on:` is a freestanding guardrails project' "$skill"
}

@test "ratchet-per-unit-class-interview: step 4 repeats per unit" {
    # verifies: D5/D9 — the per-unit class is the input to the class floor,
    # and the interview most likely to be skipped.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'repeat this interview per unit' "$skill"
    grep -q "record each class in that unit's config" "$skill"
}

@test "merge-consumes-impact-mechanically: the skill names the mode and forbids hand-picking" {
    # verifies: D6/D12; --impact semantics quoted from scripts/check-units.sh
    # verifies: D4 (docs/plans/2026-09-28-agent-first-skills.md)
    # The composed-chain obligations test the chain THROUGH this mode; a
    # hand-judged unit list is the false green the mode exists to prevent.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/references/multi-unit.md"
    grep -q 'check-units.sh --impact' "$skill"
    grep -q 'never hand-pick the unit list' "$skill"
    grep -q 'maps a change under the root `.guardrails/` to every unit' "$skill"
}

@test "merge-runs-impact-set-gates: per-unit runs are spelled out" {
    # verifies: D6 — gates and verify_commands of every unit in the impact
    # set, plus the repository-level check-units.sh run.
    # verifies: D4 (docs/plans/2026-09-28-agent-first-skills.md)
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/references/multi-unit.md"
    grep -q 'GR_CONFIG=<unit>/.guardrails/config.yaml' "$skill"
    grep -q 'every unit in the impact set' "$skill"
    grep -q 'check-units.sh` with no flag' "$skill"
}

@test "merge-finalizes-touched-units-only: the finalize loop is scoped" {
    # verifies: architecture item 6 — finalize-docs.sh is unit-scoped; drafts
    # are in touched units by the paths-inside-the-unit rule, so dependents
    # have nothing to rename.
    # verifies: D4 (docs/plans/2026-09-28-agent-first-skills.md)
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/references/multi-unit.md"
    grep -q 'once per touched unit' "$skill"
}

@test "merge-record-names-units: the verification record contains the impact set" {
    # verifies: D6 — one record per change; the record names the units.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/references/multi-unit.md"
    grep -q 'units touched, and the impact set' "$skill"
    grep -q 'the record also names the units touched' "$skill"
}

@test "grill-dependency-assessment-interview: the provider's artefacts are consulted by name" {
    # verifies: D10 — adopted as skill guidance, rejected as mechanism; the
    # consultation list is the decision's own: exports, RMF, ADRs, open
    # problem reports, SOUP.
    skill="$BATS_TEST_DIRNAME/../skills/grill-requirements/SKILL.md"
    grep -q 'check-units.sh --exports' "$skill"
    grep -q 'does its risk analysis consider this use' "$skill"
    grep -q 'open problem reports' "$skill"
    grep -q 'transitively its SOUP' "$skill"
}

@test "grill-gap-becomes-expectation: expects: grammar with the met condition" {
    # verifies: D10/D11 — the gap is a requirement; met = provider's exported
    # REQ with satisfies:.
    skill="$BATS_TEST_DIRNAME/../skills/grill-requirements/SKILL.md"
    grep -q 'expects: <unit>' "$skill"
    grep -q 'UNMET-EXPECTATION' "$skill"
    grep -q 'exported REQ with `satisfies:' "$skill"
    grep -q 'opened: YYYY-MM-DD' "$skill"
    grep -q 'INCOMPLETE-EXPECTATION' "$skill"
}

@test "grill-glossary-escalates-interface-terms: unit default, root escalation, conflict rule" {
    # verifies: D13 — a skill rule for the interviews, not a check.
    skill="$BATS_TEST_DIRNAME/../skills/grill-requirements/SKILL.md"
    grep -q 'the root glossary owns interface terms' "$skill"
    grep -q 'the moment it appears in an exported REQ or an `expects:` item' "$skill"
    grep -q 'Two units disagreeing internally is not a conflict' "$skill"
}

@test "design-depends-on-is-a-decision: the design skill routes the edge through the assessment" {
    # verifies: D10 — the consultation belongs to grill-requirements AND
    # design-architecture; a dependency drawn on the diagram without the
    # interview is an unassessed supplier.
    skill="$BATS_TEST_DIRNAME/../skills/design-architecture/SKILL.md"
    grep -q 'Declaring a dependency' "$skill"
    grep -q 'an unassessed supplier' "$skill"
}

@test "design-segregation-cites-a-control: segregated_from: names its mechanism" {
    # verifies: D5 + architecture — check-units.sh convicts an uncited entry
    # (INCOMPLETE-SEGREGATION) and an uncovered class gap
    # (MISCLASSED-DEPENDENCY); the skill must state where the citation lives.
    skill="$BATS_TEST_DIRNAME/../skills/design-architecture/SKILL.md"
    grep -q 'segregated_from:' "$skill"
    grep -q 'INCOMPLETE-SEGREGATION' "$skill"
    grep -q 'MISCLASSED-DEPENDENCY' "$skill"
}

@test "assesses-is-the-remedy: every place that tells an author how to assess names the annotation" {
    # verifies: PR-n274s7 — D1: hard cut, so the remedy must be stated where
    # the author reads, not only in the gate's message.
    root="$BATS_TEST_DIRNAME/.."
    grep -q 'assesses:' "$root/skills/analyze-risks/SKILL.md"
    grep -q 'assesses:' "$root/skills/grill-requirements/SKILL.md"
    grep -q 'assesses:' "$root/templates/rmf.md"
    grep -q 'assesses:' "$root/templates/srs.md"
    grep -q 'assesses:' "$root/templates/sad.md"
    grep -q 'assesses:' "$root/templates/AGENTS-block.md"
    grep -q 'assesses:' "$root/README.md"
    ! grep -q 'RMF never mentions' "$root/skills/analyze-risks/SKILL.md"
    ! grep -q 'the RMF must mention it' "$root/skills/grill-requirements/SKILL.md"
}

@test "upgrade-notes-announce-the-hard-cut: ratchet states derived assessments go red at upgrade" {
    # verifies: PR-n274s7 — D1
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'Derived assessments are now declared' "$skill"
    grep -q 'DANGLING-FILE' "$skill"
}

@test "merge-step-3-reports-rewrites: merge-change expects finalize to print what it rewrote" {
    # verifies: PR-58zsvf — D2
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'rewrote' "$skill"
    grep -q 'DANGLING-FILE' "$BATS_TEST_DIRNAME/../README.md"
    grep -q 'reported as left' "$BATS_TEST_DIRNAME/../README.md"
    grep -q 'root-relative' "$BATS_TEST_DIRNAME/../README.md"
    grep -q 'root-relative' "$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'relative link' "$skill"
}

@test "clanker: the managed block names concrete naming rules" {
    # verifies: D2 (docs/plans/2026-10-05-drop-prose-rules.md)
    # The section is code-only, under its own heading, and contains the
    # naming rules. The past-participle rule is removed.
    block="$BATS_TEST_DIRNAME/../templates/AGENTS-block.md"
    grep -q '^## Code: names$' "$block"
    grep -q 'single-character' "$block"
    grep -q 'No code golf' "$block"
    grep -q 'Name in concrete terms' "$block"
    ! grep -qE 'past participle|write_timestamp' "$block" \
        || { echo "the block still contains the past-participle rule"; false; }
}

@test "clanker: this repository follows the same block" {
    # verifies: D1, D2 (docs/plans/2026-10-05-drop-prose-rules.md)
    # AGENTS.md is guardrails' own copy of the rules it ships. A rule that
    # ships to adopters and does not bind this repository is a rule this
    # repository will break first. The prose section is removed from both.
    agents="$BATS_TEST_DIRNAME/../AGENTS.md"
    block="$BATS_TEST_DIRNAME/../templates/AGENTS-block.md"
    grep -q '^## Code: names$' "$agents"
    grep -q 'single-character' "$agents"
    ! grep -q '^## Writing: prose, names and messages$' "$agents" \
        || { echo "AGENTS.md still contains the prose section"; false; }
    ! grep -q '^## Writing: prose, names and messages$' "$block" \
        || { echo "the block still contains the prose section"; false; }
}

@test "clanker: develop-change dispatches one deslop pass over the whole diff" {
    # verifies: D4 (docs/plans/2026-09-14-clanker-adoption.md)
    # The dispatcher never reads the code and each subagent sees one task, so
    # cross-task duplication is invisible to both. This pass is the only agent
    # that sees the whole change, which is why it is a dispatch over the diff
    # and not a per-task review.
    #
    # Three dots, pinned literally. `main...<branch>` is the diff since the two
    # diverged — what this change did — while `main..<branch>` also reports
    # whatever the base branch gained meanwhile, which is not this change's
    # work to deslop. A two-dot range grows as main advances and the pass ends
    # up reviewing other people's commits.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -q 'deslop pass' "$skill"
    grep -qF 'main...<change-branch>' "$skill"
    grep -q 'cross-task' "$skill"
}

@test "clanker: the deslop pass is not deferred to the merge review" {
    # verifies: D4 (docs/plans/2026-09-14-clanker-adoption.md)
    # merge-change reruns from step 1 on any finding, so a naming nit raised
    # at 6a costs a full merge-sequence restart. The skill has to state why the
    # pass is here, or a later editor moves it to the review that already
    # reads the whole diff.
    #
    # Anchored on the bold markers, not the bare phrase: the same words appear
    # in the dispatch-report section, split across a line break, so a bare
    # 'reruns from step 1' is unique only by accident of wrapping. Reflow that
    # paragraph and the bare form would match it while this passage was gone.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -qF '**reruns from step 1**' "$skill"
}

@test "clanker: the deslop dispatch prohibits a task worktree" {
    # verifies: D8 (docs/plans/2026-09-14-clanker-adoption.md)
    # Every other dispatch in these skills names a nested task worktree, so a
    # subagent given no location follows that pattern and leaves its fixes on a
    # task branch — for the one pass whose purpose is to edit the change branch
    # in place. Both halves are pinned: the prompt line that gives the location
    # and the paragraph that states why no task worktree is created.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -qF 'Work in the change worktree at <path>, on <change-branch>. Do NOT create a task' "$skill"
    grep -q 'this pass fixes on the change branch directly' "$skill"
    grep -qF '**This is the one dispatch that does not get its own task worktree**' "$skill"
}

@test "clanker: develop-change tells a stuck task to change approach" {
    # verifies: D7 (docs/plans/2026-09-14-clanker-adoption.md)
    # The derailment rule re-dispatches on the first failure. Without this,
    # the re-dispatch repeats the approach that already failed.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -q 'change the approach' "$skill"
}

@test "clanker: the gate checks that the deslop pass was run" {
    # verifies: D6 (docs/plans/2026-09-14-clanker-adoption.md)
    # In a suite where every other step is mechanically checked, an
    # unenforced step is the one that stops running. The enforcement is
    # cheap: an existing gate with one more check in it.
    skill="$BATS_TEST_DIRNAME/../skills/verify-before-merge/SKILL.md"
    grep -q 'deslop pass was run' "$skill"
    grep -q 'dispatcher fixed its findings' "$skill"
}

@test "clanker: a bug caused by the design escalates to design-architecture" {
    # verifies: D1 (docs/plans/2026-09-14-clanker-adoption.md)
    # The escalation list already covers a missing requirement, a missed
    # hazard and a wrong spec. A bug that is a consequence of the
    # architecture had nowhere to go, so it was fixed where it surfaced and
    # the class of bug stayed open.
    skill="$BATS_TEST_DIRNAME/../skills/resolve-problem/SKILL.md"
    grep -q 'consequence of the design' "$skill"
    grep -q 'design-architecture' "$skill"
}

@test "clanker: ratchet reports a managed block with no code section" {
    # verifies: D6 (docs/plans/2026-10-05-drop-prose-rules.md)
    # A project ratcheted before the `## Code: names` heading existed has a
    # block without it. No other check reports it.
    # Anchored on the inventory bullet itself, not on a phrase the upgrade
    # announcement also contains, so deleting the bullet turns this red.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'A managed block with no `## Code: names` section' "$skill"
    grep -q 'Record it in the gap analysis' "$skill"
}

@test "clanker: the deslop pass reviews against the code rules" {
    # verifies: D3 (docs/plans/2026-10-05-drop-prose-rules.md)
    # The prose rules are removed, so the dispatch prompt names the section
    # that remains rather than one that no longer exists.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -q 'the code rules in AGENTS.md' "$skill"
    ! grep -q 'writing and naming rules' "$skill"
}

@test "develop-change: the loop greps the mutation anchors for a changed line" {
    # verifies: PR-dr7k7k
    # Was annotated PR-4fwfjp, which is the `status: accepted` item and states
    # nothing about mutation anchors: this test asserts an obligation that
    # belonged to no item at all until PR-dr7k7k was written for it.
    # A mutation script embeds a line of the script it mutates as a literal
    # `old = '''…'''` and asserts one match, so a change that edits a quoted
    # line leaves a mutation that cannot apply. tests/mutations.bats reports
    # such a mutation, but only when the full suite is run, after the edit is
    # complete; the grep in the TDD loop finds the hit while the edit is in
    # progress.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -q 'mutations' "$skill"
    # Re-cutting is the prescribed answer, and re-cutting without re-proving is
    # the failure it invites: an anchor can match again and kill nothing.
    grep -q 'kills tests' "$skill"
}

@test "merge-change: the record states the ledger delta, not the open count" {
    # verifies: PR-hkc376
    # Step 6b required "open PR warnings" — a census of the whole ledger at one
    # instant, in a per-change artifact read long afterwards. 78 of 123 records
    # mention the roll-call and 20 pin a number; one merged change existed only
    # to correct a count in an already-merged record.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'resolves, accepts or opens' "$skill"
    ! grep -rq 'open PR warnings' "$(dirname "$skill")"
}

@test "merge-change: the commit template states the Resolves and Opens trailers" {
    # verifies: PR-hkc376
    # Deltas are checkable against the diff forever; no script parses the
    # message, so the trailers cost nothing.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -qF 'Resolves: <PR IDs this change closes>' "$skill"
    grep -qF 'Opens: <PR IDs this change raises>' "$skill"
}

@test "verification template: a repository figure does not belong in the gate table" {
    # verifies: PR-hkc376
    # Measuring the open count fresh does not make it a fact about this change.
    template="$BATS_TEST_DIRNAME/../templates/verification.md"
    grep -q 'describes the repository rather than this change' "$template"
}

@test "resolve-problem: a backlog figure in a document is a red flag" {
    # verifies: PR-hkc376
    skill="$BATS_TEST_DIRNAME/../skills/resolve-problem/SKILL.md"
    grep -q 'State the backlog size' "$skill"
    grep -q 'Name the IDs that moved' "$skill"
}

@test "verification template: the gate table names the tree the figures describe" {
    # verifies: PR-dkm5tq
    # Gate evidence is keyed to a tree or it is keyed to nothing; the practice
    # was already ahead of the template.
    template="$BATS_TEST_DIRNAME/../templates/verification.md"
    grep -q 'Measured on:' "$template"
    grep -qF 'rev-parse HEAD^{tree}' "$template"
    # Naming the tree does not imply the older rule, and the older rule is the
    # one 2026-09-10-field-report-items.md finding-21 turned on: a figure
    # reproduced from an earlier round describes whichever tree that round
    # measured, whatever the name above the table claims.
    grep -q 'copied forward from an earlier round' "$template"
}

@test "merge-change: step 6 stands on step 2 where the tree is unchanged" {
    # verifies: PR-dkm5tq
    # Steps 4 and 5 are read-only and step 3 renames nothing on a second
    # findings round, so the second dispatch measures the tree the first one
    # already measured.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'the step 2 summary stands' "$skill"
    grep -qF 'rev-parse HEAD^{tree}' "$skill"
}

@test "merge-change: step 3 commits only when it renamed something" {
    # verifies: PR-dkm5tq
    # The unconditional commit exits 1 with nothing to commit on a round where
    # the drafts are already dated — a halt for no defect, in a sequence that
    # stops at any failure.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'only where there were renames' "$skill"
    grep -qF 'git diff --cached --quiet ||' "$skill"
}

@test "merge-change: the reviewer tags every finding" {
    # verifies: PR-3s74u3
    # check-review.sh block-parses the header and ignores the value, so the tag
    # adds no script and no new malformed case.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'Every finding opens with its tag' "$skill"
    grep -qF '`code`, `requirement` or `record`' "$skill"
    grep -qF '`high`, `medium` or `low`' "$skill"
}

@test "merge-change: a round with nothing above low severity is the last" {
    # verifies: PR-3s74u3
    # Ruling of 2026-10-04 (docs/plans/2026-09-29-agent-first-skills-change-2.md):
    # rounds 16 to 21 of agent-first-scripts each raised one to four low
    # findings, so a clean-round rule did not converge.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    checklist="$BATS_TEST_DIRNAME/../skills/merge-change/references/review-checklist.md"
    grep -q 'are all `low` is the last review' "$skill"
    grep -qF '`high`' "$checklist"
    grep -qF '`medium`' "$checklist"
    grep -qF '`low`' "$checklist"
    run grep -q 'A round raising no `code` and no `requirement` finding is the last' "$skill"
    [ "$status" -ne 0 ]
}

@test "the skills and templates name the finalize date, not the merge date" {
    # verifies: PR-xec7dd
    # finalize-docs.sh dates a draft when it retires the draft name, which is
    # merge-change step 3 and is not re-derived afterwards: 49 of 193 dated
    # ledger files differ from the day their change reached the base branch,
    # the largest gap 6 days. The documents claimed otherwise in fourteen places.
    #
    # The scan covers docs/problems/README.md as well, which is this repository's
    # own copy of templates/problems.md: fixing the template does not fix the
    # copy, and the copy is what a reader of this ledger opens. Round 2 of the
    # review found it still stating the merge date after round 1 had repaired
    # the template and the README.
    root="$BATS_TEST_DIRNAME/.."
    ! grep -rniE 'merge.date' "$root"/skills "$root"/templates/*.md \
        "$root"/README.md "$root"/docs/problems/README.md
}

@test "merge-change: step 2 records the tree its gate summary describes" {
    # verifies: PR-dkm5tq
    # Step 6 compares the current tree against the one step 2 measured, so step
    # 2 has to have written that hash down. Without it the comparison has no
    # left-hand side and the rule is unusable on its first pass.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'Record the tree the summary describes' "$skill"
    # ...and upstream of the step 6 comparison that reads it.
    recorded=$(grep -n 'Record the tree the summary describes' "$skill" | cut -d: -f1)
    compared=$(grep -n 'the step 2 summary stands' "$skill" | cut -d: -f1)
    [ "$recorded" -lt "$compared" ]
}

@test "merge-change: step 3 tells the author to read the unrewritten lines" {
    # verifies: PR-9zvb36
    # The report's entire value is a human ruling narration against link, and
    # step 3 is the only place an author is told what to read out of
    # finalize-docs.sh. It enumerated `rewrote FILE:` and `left FILE:` only.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'unrewritten FILE' "$skill"
    grep -q 'would leave unrewritten' "$skill"
}

@test "verification template opens every finding with its tag" {
    # verifies: PR-3s74u3
    # Step 6a requires `code`, `requirement` or `record` as the first word of a
    # finding's value, and the template a reviewer copies showed an untagged
    # finding-1 — the one place the shape is demonstrated rather than described.
    template="$BATS_TEST_DIRNAME/../templates/verification.md"
    grep -q '^\*\*finding-1\*\*: <code | requirement>, <high | medium | low> —' "$template"
    # A `record` finding states no severity, and the template shows that shape
    # rather than a severity on every tag.
    grep -q '^\*\*finding-2\*\*: record — ' "$template"
    ! grep -q '^\*\*finding-[0-9]*\*\*: [^—]*record[^—]*, <high' "$template"
    # and the field grammar states what the tag is for

    # The boundary itself, and not only the tag. Three formulations of this rule
    # were rejected by three review rounds, and each time the skill was repaired
    # and the template left stating the version just disproved — a reviewer
    # copies the template, so the wrong rule is the one that reaches the field.
    # The template states what the tag is FOR — the convergence rule — and must
    # not restate a boundary rule. Five review rounds rejected five formulations
    # of one, and the change that added the tag ships none; a template that
    # reintroduces one reaches every adopter's record.
    grep -q 'convergence rule' "$template"
    ! grep -q 'outside the verification record' "$template"
    ! grep -q 'a file some gate reads' "$template"
    ! grep -q 'a file some test reads' "$template"
    ! grep -q 'anything a .verify_commands. entry opens' "$template"
}

@test "merge-change: the tag does not shorten the sequence" {
    # verifies: PR-3s74u3
    # verifies: D4 (docs/plans/2026-09-28-agent-first-skills.md)
    # The reporter asked for three things: classify findings, bound what a record
    # finding costs, and say when to stop. Five review rounds each rejected a
    # formulation of the middle one, every version resting on naming a class of
    # files no gate reads — there is none, check-ids.sh greps the whole tree. The
    # change ships the first and third and states plainly that it ships no
    # boundary, so a reader does not infer one from the tag's existence.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'Every finding still sends the sequence back to step 1' "$skill"
    grep -q 'deliberately not taken' "$skill"
    # and the tag's actual effect, which is what makes the convergence rule
    # below executable: a record-only round reruns like any other but dispatches
    # no further reviewer. Cutting the boundary rule without stating this left
    # the two rules contradicting each other for exactly the case convergence
    # is about.
    grep -q 'whether \*\*another' "$skill"
    grep -q 'no further reviewer is dispatched' "$skill"
    # The neighbouring paragraphs must not re-derive a shortened sequence from
    # the tag. Round 6 fixed the rule and left one of them stating its negation;
    # round 7 found that, because the guard then asserted only the absence of the
    # phrase "finding-free round", which a reworded sentence satisfies while
    # keeping the inference. So assert the claim that replaced it, and reject the
    # two inferences by shape rather than by one spelling.
    run grep -rq 'finding-free round' "$(dirname "$skill")"
    [ "$status" -ne 0 ]
    run grep -rq 'runs only on the last round' "$(dirname "$skill")"
    [ "$status" -ne 0 ]
    run grep -rq 'never reaches a later step\.\*\* The paragraph below sends' "$(dirname "$skill")"
    [ "$status" -ne 0 ]
    grep -q 'any finding at' "$skill"
    grep -q 'whatever the findings were tagged' "$skill"
    # and the red-flag row does not offer the saving either
    ! grep -rq 'skips the suite, not the gates' "$(dirname "$skill")"
}

@test "merge-change: the mechanical checks are the pre-flight" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # merge-preflight.sh runs the checks steps 4 and 6c used to spell out one
    # command at a time. Each step names the script, inside its own span, so a
    # step that goes back to listing the commands is reported.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    four_at=$(grep -n '^4\. ' "$skill" | head -n 1 | cut -d: -f1)
    five_at=$(grep -n '^5\. ' "$skill" | head -n 1 | cut -d: -f1)
    c_at=$(grep -n '^6c\. ' "$skill" | head -n 1 | cut -d: -f1)
    d_at=$(grep -n '^6d\. ' "$skill" | head -n 1 | cut -d: -f1)
    [ -n "$four_at" ] || { echo "no step 4"; false; }
    [ -n "$five_at" ] || { echo "no step 5"; false; }
    [ -n "$c_at" ] || { echo "no step 6c"; false; }
    [ -n "$d_at" ] || { echo "no step 6d"; false; }
    sed -n "${four_at},${five_at}p" "$skill" | grep -qF 'merge-preflight.sh --before-review' \
        || { echo "step 4 does not run merge-preflight.sh --before-review"; false; }
    sed -n "${c_at},${d_at}p" "$skill" | grep -qF 'merge-preflight.sh <' \
        || { echo "step 6c does not run merge-preflight.sh"; false; }
}

@test "develop-change: the dispatch prompt names task-worktree.sh" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # task-worktree.sh creates the task worktree and retires it. The dispatch
    # prompt tells the subagent to run `start`, and the dispatcher runs
    # `merge` after a green report, in place of the hand-written merge, remove
    # and delete.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -qF 'task-worktree.sh start t3' "$skill" \
        || { echo "the dispatch prompt does not name task-worktree.sh start"; false; }
    grep -qF 'task-worktree.sh merge' "$skill" \
        || { echo "Delegation does not name task-worktree.sh merge"; false; }
}

@test "merge-change: step 6d and the cleanup reference name remove and discard, and no remedy merges" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # A merge is the dispatcher's step after a green task report. A remedy for
    # a rejection never names one: step 6d and the cleanup reference name
    # remove, discard and the git commands that merge nothing.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    d_at=$(grep -n '^6d\. ' "$skill" | head -n 1 | cut -d: -f1)
    s_at=$(grep -n '^7\. \*\*Squash onto the base branch' "$skill" | head -n 1 | cut -d: -f1)
    [ -n "$d_at" ] || { echo "no step 6d"; false; }
    [ -n "$s_at" ] || { echo "no step 7"; false; }
    step_6d=$(sed -n "${d_at},${s_at}p" "$skill")
    # Step 6d defers to the fix line in full: all three of its cases, not
    # remove alone.
    for wanted in 'task-worktree.sh remove <tag>' '`discard <tag>` after recording' \
        'the plain git commands for a worktree `task-worktree.sh` did not create'; do
        printf '%s\n' "$step_6d" | tr '\n' ' ' | sed 's/  */ /g' | grep -qF -- "$wanted" \
            || { echo "step 6d lacks '$wanted': $step_6d"; false; }
    done
    run grep -qF 'task-worktree.sh merge' <<< "$step_6d"
    [ "$status" -ne 0 ] || { echo "step 6d names merge: $step_6d"; false; }
    reference="$(dirname "$skill")/references/cleanup-rejections.md"
    row=$(grep -F 'a registered worktree lies inside' "$reference")
    for wanted in 'task-worktree.sh remove <tag>' 'never gated or reviewed' \
        'task-worktree.sh discard <tag>' 'git worktree remove <path>' 'git branch -D <branch>'; do
        printf '%s\n' "$row" | grep -qF -- "$wanted" \
            || { echo "the nested-worktree row lacks '$wanted': $row"; false; }
    done
    # The command task-worktree.sh had before merge and remove replaced it.
    retired_command=finish
    for unwanted in 'task-worktree.sh merge' 'merge or abandon' "$retired_command <tag>"; do
        run grep -qF -- "$unwanted" <<< "$row"
        [ "$status" -ne 0 ] || { echo "the nested-worktree row names '$unwanted': $row"; false; }
    done
}

@test "check-traceability: the fix table is a pointer to the remedy lines" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # check-trace.sh and check-ids.sh print one `fix <RULE>:` line per rule
    # that fired (D8). A second copy of each remedy in the skill drifts from
    # the script, so the skill points at the output instead.
    skill="$BATS_TEST_DIRNAME/../skills/check-traceability/SKILL.md"
    run grep -q '^## Fixing each rule' "$skill"
    [ "$status" -ne 0 ] || { echo "the skill still has the Fixing each rule table"; false; }
    grep -qF 'fix <RULE>:' "$skill"
}

# The skill shape (docs/plans/2026-09-28-agent-first-skills.md, D5 and D9).

# The `## ` headings of a SKILL.md outside fenced code, joined with `|`.
gr_skill_headings() {
    awk '/^```/ { fenced = !fenced; next } !fenced && /^## / { sub(/^## /, ""); printf "%s|", $0 }' "$1"
}

# 0 when a SKILL.md has the D9 order, with or without References.
gr_skill_has_d9_order() {
    case "$(gr_skill_headings "$1")" in
        ('Preconditions|Steps|Red flags|Done when|References|') return 0 ;;
        ('Preconditions|Steps|Red flags|Done when|') return 0 ;;
        (*) return 1 ;;
    esac
}

gr_skill_words() {
    wc -w < "$1" | tr -d ' '
}

# 0 when a SKILL.md is at most 2,000 words (D5).
gr_skill_within_word_ceiling() {
    [ "$(gr_skill_words "$1")" -le 2000 ]
}

# Prints one ` <skill>:[...]` failure per References problem in the skill
# directory $1 (with a trailing slash), and nothing when there is none. A
# reference file no SKILL.md names is never read; a named one that does not
# exist is a dead instruction. A file is listed only by an entry line, one
# opening with "- `references/"; a name on a continuation line or in prose
# does not list it (review round 6, finding 35).
gr_skill_reference_failures() {
    local skill_dir="$1" skill_name names_in_section files_on_disk malformed_entries
    skill_name=$(basename "$skill_dir")
    names_in_section=$(
        awk '/^## / { in_references = ($0 ~ /^## References[[:space:]]*$/) } in_references' \
            "${skill_dir}SKILL.md" \
            | grep -E '^- `references/' \
            | sed -E 's/^- `(references\/[a-z0-9-]+\.md)`.*/\1/' | LC_ALL=C sort -u
    ) || true
    files_on_disk=$(
        cd "$skill_dir" && find references -name '*.md' 2>/dev/null | LC_ALL=C sort
    ) || true
    if [ "$names_in_section" != "$files_on_disk" ]; then
        printf ' %s' "$skill_name:[listed: $(echo $names_in_section)][present: $(echo $files_on_disk)]"
    fi
    # D9: the section is omitted when the skill has no reference file.
    # A trailing space after the heading is still the heading.
    if [ -z "$files_on_disk" ] && grep -qE '^## References[[:space:]]*$' "${skill_dir}SKILL.md"; then
        printf ' %s' "$skill_name:[a References heading and no reference file]"
    fi
    # D9: each entry names the file and the condition for reading it.
    # Every non-blank line after the heading is an entry or an indented
    # continuation of one, so a prose line or a `* ` bullet is reported,
    # not skipped.
    malformed_entries=$(
        awk '/^## / { in_references = ($0 ~ /^## References[[:space:]]*$/); next }
             in_references && NF' "${skill_dir}SKILL.md" \
            | awk '/^- `references\/[a-z0-9-]+\.md` — read when / { in_entry = 1; next }
                   in_entry && /^[[:space:]]+[^[:space:]]/ { next }
                   { in_entry = 0; print }'
    ) || true
    if [ -n "$malformed_entries" ]; then
        printf ' %s' "$skill_name:[entry without a file and a read-when condition: $malformed_entries]"
    fi
}

@test "skill shape: every SKILL.md has the D9 sections in order" {
    # verifies: D9 (docs/plans/2026-09-28-agent-first-skills.md)
    # verifies: D3 item 3 (docs/plans/2026-09-28-agent-first-skills.md)
    # A fixed order lets an agent find the step it needs without reading the
    # whole file.
    cd "$BATS_TEST_DIRNAME/.." || return 1
    failures=""
    for skill_file in skills/*/SKILL.md; do
        skill_name=$(basename "$(dirname "$skill_file")")
        if ! gr_skill_has_d9_order "$skill_file"; then
            failures="$failures $skill_name:[$(gr_skill_headings "$skill_file")]"
        fi
    done
    if [ -n "$failures" ]; then
        echo "skills out of the D9 section order:$failures"
        return 1
    fi
}

@test "skill shape: every SKILL.md is at most 2,000 words" {
    # verifies: D5 (docs/plans/2026-09-28-agent-first-skills.md)
    # verifies: D3 item 3 (docs/plans/2026-09-28-agent-first-skills.md)
    # A ceiling nobody checks is how the skills reached their size.
    cd "$BATS_TEST_DIRNAME/.." || return 1
    failures=""
    for skill_file in skills/*/SKILL.md; do
        skill_name=$(basename "$(dirname "$skill_file")")
        if ! gr_skill_within_word_ceiling "$skill_file"; then
            failures="$failures $skill_name:$(gr_skill_words "$skill_file")"
        fi
    done
    if [ -n "$failures" ]; then
        echo "skills over 2,000 words:$failures"
        return 1
    fi
}

@test "skill shape: the References section lists exactly the reference files" {
    # verifies: D6, D9 (docs/plans/2026-09-28-agent-first-skills.md)
    # The check and its reasons are in gr_skill_reference_failures.
    cd "$BATS_TEST_DIRNAME/.." || return 1
    failures=""
    for skill_dir in skills/*/; do
        failures="$failures$(gr_skill_reference_failures "$skill_dir")"
    done
    if [ -n "$failures" ]; then
        echo "References section and references/ disagree:$failures"
        return 1
    fi
}

# Fixture SKILL.md files for the shape predicates. The shipped skills are in
# the D9 shape, so the tests above never see a rejection; these tests write a
# fixture of each kind the predicates must reject, and two they must accept.

# Writes $1/SKILL.md with frontmatter and one `## ` section per remaining
# argument. Each section except References gets one line of body text; the
# caller appends References entries, since a body line there is malformed.
gr_write_skill_fixture() {
    local skill_dir="$1" heading
    shift
    mkdir -p "$skill_dir"
    {
        printf -- '---\nname: fixture\ndescription: A fixture skill.\n---\n\n# Fixture\n'
        for heading in "$@"; do
            printf '\n## %s\n\n' "$heading"
            if [ "$heading" != "References" ]; then
                printf 'One line of text.\n'
            fi
        done
    } > "$skill_dir/SKILL.md"
}

@test "skill shape fixture: sections out of order are rejected" {
    # verifies: D9 (docs/plans/2026-09-28-agent-first-skills.md)
    # verifies: D3 item 3 (docs/plans/2026-09-28-agent-first-skills.md)
    skill_dir="$BATS_TEST_TMPDIR/fixture/"
    gr_write_skill_fixture "$skill_dir" Steps Preconditions "Red flags" "Done when"
    run gr_skill_has_d9_order "${skill_dir}SKILL.md"
    [ "$status" -ne 0 ]
}

@test "skill shape fixture: a missing Red flags section is rejected" {
    # verifies: D9 (docs/plans/2026-09-28-agent-first-skills.md)
    skill_dir="$BATS_TEST_TMPDIR/fixture/"
    gr_write_skill_fixture "$skill_dir" Preconditions Steps "Done when"
    run gr_skill_has_d9_order "${skill_dir}SKILL.md"
    [ "$status" -ne 0 ]
}

@test "skill shape fixture: a References heading with no reference file is rejected" {
    # verifies: D9 (docs/plans/2026-09-28-agent-first-skills.md)
    skill_dir="$BATS_TEST_TMPDIR/fixture/"
    gr_write_skill_fixture "$skill_dir" Preconditions Steps "Red flags" "Done when" References
    run gr_skill_reference_failures "$skill_dir"
    [[ "$output" == *"fixture:[a References heading and no reference file]"* ]]
}

@test "skill shape fixture: a References entry that names a missing file is rejected" {
    # verifies: D6, D9 (docs/plans/2026-09-28-agent-first-skills.md)
    skill_dir="$BATS_TEST_TMPDIR/fixture/"
    gr_write_skill_fixture "$skill_dir" Preconditions Steps "Red flags" "Done when" References
    printf -- '- `references/missing.md` — read when the fixture asks for it.\n' \
        >> "${skill_dir}SKILL.md"
    run gr_skill_reference_failures "$skill_dir"
    [[ "$output" == *"fixture:[listed: references/missing.md][present: ]"* ]]
}

@test "skill shape fixture: a References entry with no read-when condition is rejected" {
    # verifies: D9 (docs/plans/2026-09-28-agent-first-skills.md)
    skill_dir="$BATS_TEST_TMPDIR/fixture/"
    gr_write_skill_fixture "$skill_dir" Preconditions Steps "Red flags" "Done when" References
    mkdir -p "${skill_dir}references"
    printf 'Reference text.\n' > "${skill_dir}references/notes.md"
    printf -- '- `references/notes.md`\n' >> "${skill_dir}SKILL.md"
    run gr_skill_reference_failures "$skill_dir"
    [[ "$output" == *"fixture:[entry without a file and a read-when condition: - \`references/notes.md\`]"* ]]
}

@test "skill shape fixture: a 2,001-word SKILL.md is rejected, and 2,000 words is accepted" {
    # verifies: D5 (docs/plans/2026-09-28-agent-first-skills.md)
    # verifies: D3 item 3 (docs/plans/2026-09-28-agent-first-skills.md)
    skill_dir="$BATS_TEST_TMPDIR/fixture/"
    gr_write_skill_fixture "$skill_dir" Preconditions Steps "Red flags" "Done when"
    padding_words=$((2000 - $(gr_skill_words "${skill_dir}SKILL.md")))
    printf 'word %.0s' $(seq "$padding_words") >> "${skill_dir}SKILL.md"
    [ "$(gr_skill_words "${skill_dir}SKILL.md")" -eq 2000 ]
    gr_skill_within_word_ceiling "${skill_dir}SKILL.md"
    printf 'word\n' >> "${skill_dir}SKILL.md"
    [ "$(gr_skill_words "${skill_dir}SKILL.md")" -eq 2001 ]
    run gr_skill_within_word_ceiling "${skill_dir}SKILL.md"
    [ "$status" -ne 0 ]
}

@test "skill shape fixture: a SKILL.md with no References section is accepted" {
    # verifies: D5, D9 (docs/plans/2026-09-28-agent-first-skills.md)
    skill_dir="$BATS_TEST_TMPDIR/fixture/"
    gr_write_skill_fixture "$skill_dir" Preconditions Steps "Red flags" "Done when"
    gr_skill_has_d9_order "${skill_dir}SKILL.md"
    gr_skill_within_word_ceiling "${skill_dir}SKILL.md"
    run gr_skill_reference_failures "$skill_dir"
    [ -z "$output" ]
}

@test "skill shape fixture: a SKILL.md with a well-formed References section is accepted" {
    # verifies: D5, D6, D9 (docs/plans/2026-09-28-agent-first-skills.md)
    skill_dir="$BATS_TEST_TMPDIR/fixture/"
    gr_write_skill_fixture "$skill_dir" Preconditions Steps "Red flags" "Done when" References
    mkdir -p "${skill_dir}references"
    printf 'Reference text.\n' > "${skill_dir}references/notes.md"
    printf -- '- `references/notes.md` — read when the fixture asks for it,\n  and on a\n  continuation line.\n' \
        >> "${skill_dir}SKILL.md"
    gr_skill_has_d9_order "${skill_dir}SKILL.md"
    gr_skill_within_word_ceiling "${skill_dir}SKILL.md"
    run gr_skill_reference_failures "$skill_dir"
    [ -z "$output" ]
}

@test "merge-change: text the first rewrite lost is stated again" {
    # verifies: D6 (docs/plans/2026-09-28-agent-first-skills.md)
    # Review round 1 of agent-first-skills found instructions from the old
    # skill that were neither kept nor listed as dropped history.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    rationale="$BATS_TEST_DIRNAME/../skills/merge-change/references/rationale.md"
    grep -q 'The reviewer still reads the record and raises what is' "$skill"
    grep -q 'name it so the user can run it' "$skill"
    grep -q 'consider two independent' "$skill"
    # Review round 9: the advice applies to class C only.
    grep -q 'C a thorough review; for class C,' "$skill"
    grep -q 'contains all four fields with values' "$skill"
    grep -q 'INCOMPLETE-RECORD' "$skill"
    grep -q 'With no worktree registered for the branch' "$skill"
    grep -q 'leave or remove it with the harness tool' "$skill"
    # Moved 2026-09-29 with the documentation checklist of step 6a (D4).
    grep -q 'exempts nothing from' \
        "$BATS_TEST_DIRNAME/../skills/merge-change/references/review-checklist.md"
    grep -q 'not by its filename' "$skill"
    grep -q 'their shell has none of your variables' "$skill"
    grep -q 'Two open changes race on the base branch' "$rationale"
    grep -q 'cannot be re-identified one round' "$rationale"
    grep -q 'an unconditional commit exits 1 with nothing to' "$rationale"
    grep -q 'Nothing later repeats the `unrewritten` report' "$rationale"
    # Review round 6: the rationale file no longer points into script
    # comments (see "the rationale file describes no script"), so what remains
    # to assert here is the reasons it keeps.
    grep -q 'what the duplicate scan at step 4 was compared against' "$rationale"
    grep -q 'is adopted into this change silently' "$rationale"
    grep -q 'fails step 4 for every later change' "$rationale"
    grep -q 'move files the tests may read' "$rationale"
    grep -q 'not the counts it was handed' "$rationale"
    grep -q 'reports on a suite it could not run' "$rationale"
    grep -q 'in the software or in the account of it' "$rationale"
    grep -q 'the dispatcher is `merge-change`' "$rationale"
    grep -q 'a stop with no defect behind it' "$rationale"
    grep -q 'the property guard 4 exists for' "$rationale"
    grep -q 'the squash commit contains the evidence' "$rationale"
    grep -q 'needs the current totals' "$rationale"
    grep -q 'a change with no reproduction states so' "$rationale"
    grep -q 'the units whose gates the verdict covers' "$rationale"
    grep -q 'A deleted finding and a finding that never existed read identically' "$rationale"
    grep -q 'removing the change worktree does not touch it' "$rationale"
    grep -q 'No script parses the message' "$rationale"
    grep -q 'starts a blocking wait on the user' "$rationale"
    grep -q 'a chance to remove the wrong directory' "$rationale"
    grep -q 'one re-read of a commit whose signature is known good' "$rationale"
    grep -q 'only the cleanup is outstanding' "$rationale"
    # Finding 23 of review round 4: the step 1 paragraph stated that two
    # branches cannot collide by construction.
    run grep -q 'cannot collide by construction' "$rationale"
    [ "$status" -ne 0 ]
    run grep -q 'with two independent reviewers for critical' "$skill"
    [ "$status" -ne 0 ]
}

@test "merge-change: the rationale file describes no script" {
    # verifies: D6 (docs/plans/2026-09-28-agent-first-skills.md)
    # Review rounds 3 to 6 found the rationale file's statements about scripts
    # false, and then the comments its pointers led to. It now keeps only the
    # reasons behind the agent's rules; a script's own comments describe the
    # script. A path under `scripts/` or any word ending in `.sh` is a
    # description creeping back.
    rationale="$BATS_TEST_DIRNAME/../skills/merge-change/references/rationale.md"
    [ -s "$rationale" ]
    run grep -nE 'scripts/|\.sh([^A-Za-z0-9_]|$)' "$rationale"
    if [ "$status" -ne 1 ]; then
        echo "the rationale file names a script:"
        echo "$output"
        return 1
    fi
}

@test "skill references: no blank line separates two rows of one table" {
    # verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)
    # A blank line ends a markdown table, so the rows after it render as plain
    # text.
    split_tables=$(awk '
        FNR == 1 { previous = ""; blank_after_row = 0 }
        /^\|/ && blank_after_row { print FILENAME ":" FNR }
        /^\|/ { blank_after_row = 0; previous = "row"; next }
        /^[ \t]*$/ { if (previous == "row") blank_after_row = 1; next }
        { previous = ""; blank_after_row = 0 }
    ' "$BATS_TEST_DIRNAME"/../skills/*/references/*.md)
    [ -z "$split_tables" ] || { echo "a table row follows a blank line after a row: $split_tables"; false; }
}

@test "ADRs: the skills and the shipped config mint ADR IDs" {
    # verifies: D1, D2 (docs/plans/2026-10-04-adr-ids.md)
    root="$BATS_TEST_DIRNAME/.."
    grep -qF 'new-id.sh ADR' "$root/skills/grill-requirements/SKILL.md"
    grep -qF 'docs/adr/ADR-<token>-<slug>.md' "$root/skills/grill-requirements/SKILL.md"
    grep -qF 'new-id.sh ADR' "$root/skills/design-architecture/SKILL.md"
    grep -qE '^id_prefixes:.*[[:space:]]ADR([[:space:]]|$)' "$root/templates/config.yaml"
    run grep -rqF 'NNNN-slug' "$root/skills" "$root/templates"
    [ "$status" -ne 0 ]
}

# adr_file_is_named_by_its_item FILE — exit 0 when FILE is named
# ADR-<token>-<slug>.md, the token matches GR_ID_TOKEN from scripts/lib.sh, and
# the first line of FILE is the item line that defines the same ID (D1 of
# docs/plans/2026-10-04-adr-ids.md). Exit 1 otherwise.
adr_file_is_named_by_its_item() {
    adr_token_pattern=$(sh -c '. "$1" && printf "%s" "$GR_ID_TOKEN"' sh \
        "$BATS_TEST_DIRNAME/../scripts/lib.sh")
    [ -n "$adr_token_pattern" ] || { echo "GR_ID_TOKEN is empty"; return 1; }
    adr_id=$(basename "$1" | sed -nE "s/^(ADR-($adr_token_pattern))-[^/]+\\.md\$/\\1/p")
    [ -n "$adr_id" ] || return 1
    adr_first_line=$(head -n 1 "$1")
    case "$adr_first_line" in
        ("**$adr_id**: "?*) return 0 ;;
    esac
    return 1
}

@test "ADRs: every file in docs/adr is named by the ID its item line defines" {
    # verifies: D1 (docs/plans/2026-10-04-adr-ids.md)
    failures=""
    for adr_file in "$BATS_TEST_DIRNAME"/../docs/adr/*.md; do
        adr_file_is_named_by_its_item "$adr_file" || failures="$failures $adr_file"
    done
    [ -z "$failures" ] || { echo "ADR files not named by their item ID:$failures"; return 1; }
}

# The four tests below build every ADR ID at run time from a prefix variable:
# the repository gates scan tests/ for references.

@test "ADRs: the naming check accepts a file named by the token its first line defines" {
    # verifies: D1 (docs/plans/2026-10-04-adr-ids.md)
    adr_prefix=ADR
    adr_id="$adr_prefix-k3n8p2"
    printf '**%s**: The configuration is flat YAML.\n\nStatus: accepted\n' "$adr_id" \
        > "$BATS_TEST_TMPDIR/$adr_id-flat-config.md"
    adr_file_is_named_by_its_item "$BATS_TEST_TMPDIR/$adr_id-flat-config.md"
}

@test "ADRs: the naming check rejects a file named by an ID its item line does not define" {
    # verifies: D1 (docs/plans/2026-10-04-adr-ids.md)
    adr_prefix=ADR
    printf '**%s**: The configuration is flat YAML.\n' "$adr_prefix-m4q7r9" \
        > "$BATS_TEST_TMPDIR/$adr_prefix-k3n8p2-flat-config.md"
    run adr_file_is_named_by_its_item "$BATS_TEST_TMPDIR/$adr_prefix-k3n8p2-flat-config.md"
    [ "$status" -eq 1 ]
}

@test "ADRs: the naming check rejects an item line that is not on line 1" {
    # verifies: D1 (docs/plans/2026-10-04-adr-ids.md)
    adr_prefix=ADR
    adr_id="$adr_prefix-k3n8p2"
    printf '# Flat configuration\n\n**%s**: The configuration is flat YAML.\n' "$adr_id" \
        > "$BATS_TEST_TMPDIR/$adr_id-flat-config.md"
    run adr_file_is_named_by_its_item "$BATS_TEST_TMPDIR/$adr_id-flat-config.md"
    [ "$status" -eq 1 ]
}

@test "ADRs: the naming check rejects a token with no digit" {
    # verifies: D1 (docs/plans/2026-10-04-adr-ids.md)
    adr_prefix=ADR
    adr_id="$adr_prefix-aaaaaa"
    printf '**%s**: The configuration is flat YAML.\n' "$adr_id" \
        > "$BATS_TEST_TMPDIR/$adr_id-flat-config.md"
    run adr_file_is_named_by_its_item "$BATS_TEST_TMPDIR/$adr_id-flat-config.md"
    [ "$status" -eq 1 ]
}
