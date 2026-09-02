# Content lints over the skills, in the spirit of portability.bats's sweep:
# a skill instruction that quietly loses its load-bearing phrase fails here
# rather than in some target project months later.

@test "ratchet: tool qualification says how and where the suite runs" {
    # verifies: PR-ac96zf
    # The step-5 checklist item asks the installer to record the suite result
    # at install time. Without these three anchors it never said how that
    # result is produced, and a /ratchet run in a target project was left to
    # improvise — up to and including installing bats into the target repo or
    # running the suite there.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'tests/run-tests.sh' "$skill"
    grep -q 'bats is never installed' "$skill"
    grep -q 'suite not run at install time:' "$skill"
}

@test "ratchet: tool qualification warns that a pipe eats the suite's exit status" {
    # verifies: PR-nzpp57
    # The step-5 item says to capture the suite's exit code, but a natural way
    # to run it — `run-tests.sh | tee log` — leaves $? holding tee's status,
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
    # commit carried an AGENTS.md and a docs/problems/README.md contradicting
    # each other about a required field.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'prose carriers' "$skill"
    grep -q 'Re-copy the four ledger READMEs' "$skill"
}

@test "ratchet: the qualification basis names a commit, not just a version" {
    # verifies: PR-dcn2xc
    # "435 tests at 0.5.1" is nominal the moment upstream advances without a
    # version bump; a recorded commit makes the basis checkable. The skill
    # must tell the installer to record it, and the shipped config template
    # must carry the key it is recorded under.
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
    grep -q 'reports success and then refuses' "$skill"
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
    # committing on the change branch and carrying on there once the task
    # worktree exists.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of where it sits, not an assertion.)
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
    # so the path is named here too. The reviewer has no task number, hence
    # the `-review` tag.
    #
    # Anchored by POSITION, not presence. The literal now appears three times
    # in the file — the dispatch, the removal command, and the prose around it
    # — so a bare `grep -q` for it survived mutating the ONE occurrence that
    # carries the rule. The dispatch's occurrence is the first in the file, it
    # sits inside step 6a, and it comes before the removal command that repeats
    # it; mutate it and the first occurrence becomes the removal line, which is
    # not less than itself.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    a_at=$(grep -n '^6a\. \*\*Independent review\*\*' "$skill" | head -n 1 | cut -d: -f1)
    b_at=$(grep -n '^6b\. \*\*Verification record\*\*' "$skill" | head -n 1 | cut -d: -f1)
    path_at=$(grep -n '\.worktrees/<change-branch>-review' "$skill" | head -n 1 | cut -d: -f1)
    remove_at=$(grep -n 'git worktree remove \.worktrees/<change-branch>-review' \
        "$skill" | head -n 1 | cut -d: -f1)
    [ -n "$a_at" ]
    [ -n "$b_at" ]
    [ -n "$path_at" ]
    [ -n "$remove_at" ]
    [ "$path_at" -gt "$a_at" ]
    [ "$path_at" -lt "$b_at" ]
    [ "$path_at" -lt "$remove_at" ]
}

@test "merge-change: the review worktree dies at the end of its own dispatch" {
    # verifies: PR-n57ayn
    # Step 6d was the only place that removed the review worktree, and step 6a
    # ends "the sequence reruns from step 1" when findings come back — so 6b,
    # 6c and 6d are reached only on the final, finding-free round. The path and
    # the branch are fixed, so every intermediate round's worktree survived and
    # the next round's dispatch died with `fatal: a branch named
    # '<change-branch>-review' already exists`. The removal belongs where the
    # dispatch ends, inside step 6a, which is what worktree-discipline already
    # says of every task worktree. Step 6d keeps the structural check, so a
    # skipped removal is still caught before the squash rather than at
    # finish-merge.sh.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    a_at=$(grep -n '^6a\. \*\*Independent review\*\*' "$skill" | head -n 1 | cut -d: -f1)
    b_at=$(grep -n '^6b\. \*\*Verification record\*\*' "$skill" | head -n 1 | cut -d: -f1)
    remove_at=$(grep -n 'git worktree remove \.worktrees/<change-branch>-review' \
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
    sed -n "${d_at},${s_at}p" "$skill" | grep -q 'git worktree list'
    # worktree-discipline cross-references the removal's home, so it follows it
    # there rather than leaving the two skills to drift.
    wd="$BATS_TEST_DIRNAME/../skills/worktree-discipline/SKILL.md"
    grep -q 'the end of `merge-change` step 6a' "$wd"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of where it sits, not an assertion.)
    run grep -q 'step 6d' "$wd"
    [ "$status" -ne 0 ]
}

@test "merge-change: every fix dispatch names the nested task worktree path" {
    # verifies: PR-n57ayn
    # Two more dispatch statements in this file are normative and were
    # unasserted: the sequence header's fix dispatch, and 6a's dispatch of the
    # fix for a finding. A mutant replacing both with "a task worktree"
    # survived the suite. Both are pinned, and by position, so replacing either
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
    # `git worktree remove` refuses on untracked files as well as modified
    # ones, and a reviewer leaves scratch behind — a log, a note. The step
    # named the state to check and stopped there, which leaves `--force` as
    # the only obvious way out of it, and `--force` is what destroys the thing
    # the guard exists to protect.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'refuses on untracked files as well as modified ones' "$skill"
    grep -q 'read the scratch, delete it, and remove the worktree again' "$skill"
    grep -q 'the remedy step 6a gives' "$skill"
    # The list of causes named "a test runner copied in because it was
    # gitignored and therefore absent" — the one entry that cannot cause the
    # refusal, and self-refuting: git does not see an ignored file, which is
    # exactly why it was absent. Reproduced directly: a worktree holding only
    # gitignored scratch has an empty `git status --porcelain` and is removed
    # with no refusal. It is also the negation of what guard 4 is for, and of
    # what worktree-discipline states correctly ("gitignored by definition and
    # so cannot dirty `git status`"), so the passage says so rather than
    # leaving the reader the older, wrong version.
    grep -q 'Nothing gitignored is among them' "$skill"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of where it sits, not an assertion.)
    run grep -q 'gitignored and therefore absent' "$skill"
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
    sed -n "${d_at},${s_at}p" "$skill" | grep -q 'Read the list for paths inside the change worktree'
    sed -n "${d_at},${s_at}p" "$skill" | grep -q 'A worktree registered anywhere else is not this step'
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of where it sits, not an assertion.)
    run grep -q 'Nothing but the primary checkout and the change worktree' "$skill"
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
    sed -n "${a_at},${b_at}p" "$skill" | grep -q 'fails on a path that was never created'
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of where it sits, not an assertion.)
    run grep -q 'Every round, findings or not' "$skill"
    [ "$status" -ne 0 ]
}

@test "merge-change: a fix dispatch's tag is unique, and AGENTS.md defers on tags" {
    # verifies: PR-n57ayn
    # `.worktrees/<change-branch>-<tag>` leaves the tag unconstrained, so the
    # rule that it must not repeat is worth keeping — but its first
    # justification was false. Two findings rounds that both reach for the
    # natural `fix` cannot collide at creation: a task worktree and its branch
    # die with their dispatch (`worktree-discipline`, "Inside the worktree"),
    # so round 1's `-fix` branch is gone before round 2 dispatches. That is the
    # same property step 6a rests on when it keeps the review tag fixed, so the
    # two rationales cannot both stand. The rule survives as insurance against
    # a cleanup that was missed, and the removal it insures is now stated here
    # as well, not only in `worktree-discipline` and `develop-change`.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'must be unique per dispatch' "$skill"
    grep -q 'insurance against a cleanup that was missed' "$skill"
    grep -q 'keeps the review tag fixed at' "$skill"
    grep -q 'remove the worktree and delete the task branch' "$skill"
    # The insurance clause is the load-bearing half of that justification, so
    # what it insures against must not be understated. "no numbered step of
    # this sequence performs its removal" means the whole cleaning up —
    # `git worktree remove` and `git branch -d` — but the clause then called a
    # skipped cleanup met by a fresh tag "only a stale branch", which is the
    # branch-only case. A wholly skipped cleanup also leaves a registered
    # nested worktree; gitignored, it is invisible to `git status`, so step 6d
    # and guard 4 are what find it, late. The `fatal:` covers both cases
    # because git validates the new branch name before the worktree path.
    grep -q '`git worktree remove` and then `git branch -d`' "$skill"
    grep -q 'git validates the new branch name' "$skill"
    grep -q 'skipped cleanup also leaves a nested worktree still registered' "$skill"
    grep -q 'guard 4 refuses at step 8' "$skill"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of where it sits, not an assertion.)
    run grep -q 'collide at creation' "$skill"
    [ "$status" -ne 0 ]
    run grep -q 'it is only a stale branch' "$skill"
    [ "$status" -ne 0 ]
    # AGENTS.md enumerated `<N>` as the plan task number "or the tag `review`
    # for the independent review", which has no slot for a fix dispatch's tag.
    # It then attributed the uniqueness rule to `worktree-discipline` step 1,
    # which does not state it; the rule lives in `merge-change`'s sequence
    # header. AGENTS.md points at each rule's real home instead of keeping a
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
    grep -q 'one harness, measured once' "$skill"
    grep -q 'does not pin its subagents' "$skill"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of where it sits, not an assertion.)
    run grep -q 'A harness that isolates a dispatched subagent pins' "$skill"
    [ "$status" -ne 0 ]
}

@test "worktree-discipline: the task worktree passage says how to get inside" {
    # verifies: PR-n57ayn
    # Creating the worktree is half the step. "Harness tool first" was deleted
    # with nothing put in its place, and `<N>` was never defined — so the
    # passage now walks create -> get inside, and says what `<N>` is, including
    # the review worktree that has no task number. The proof of arrival has to
    # work on both branches of "harness tool first": an agent told to stay put
    # and drive by path can run neither `pwd` nor a bare `git status` in the
    # target. And the artifacts to copy in are named by a command, not left to
    # be guessed at.
    skill="$BATS_TEST_DIRNAME/../skills/worktree-discipline/SKILL.md"
    grep -q 'harness tool first' "$skill"
    grep -q '`<N>` is the plan task number' "$skill"
    grep -q '\.worktrees/<change-branch>-review' "$skill"
    grep -q 'git -C .worktrees/<change-branch>-t<N> status' "$skill"
    grep -q 'git status --ignored' "$skill"
    # The red flag that says the same thing two screens later has to agree, or
    # the retired framing survives in the one place an agent reads when it is
    # already unsure where it is.
    grep -q 'Prove the location with `git -C <path> status`' "$skill"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of where it sits, not an assertion.)
    #
    # Broadened from '`pwd` and `git status` in the target': that spelling was
    # only one of two the file carried, and the red flag's shorter one went on
    # saying exactly what this assertion exists to forbid.
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
    # change worktree, and finish-merge.sh guard 4 refuses to remove a change
    # worktree that has a worktree registered inside it. Nothing in the
    # sequence removed the review worktree, so the documented happy path of
    # every change would reach step 7 and be refused. The removal must come
    # before the squash is staged, so the ordering is asserted and not merely
    # the presence of the command.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    remove_at=$(grep -n 'git worktree remove \.worktrees/<change-branch>-review' \
        "$skill" | head -n 1 | cut -d: -f1)
    squash_at=$(grep -n 'git merge --squash <branch>' "$skill" | head -n 1 | cut -d: -f1)
    [ -n "$remove_at" ]
    [ -n "$squash_at" ]
    [ "$remove_at" -lt "$squash_at" ]
    # Where inside the sequence the removal sits is the sibling test's subject
    # ("dies at the end of its own dispatch"), including the cross-reference
    # from worktree-discipline. This one holds only the ordering against the
    # squash, which is what finish-merge.sh's guard 4 makes load-bearing.
    wd="$BATS_TEST_DIRNAME/../skills/worktree-discipline/SKILL.md"
    # The same bullet used to argue for taking the path from the dispatch
    # report "rather than rebuilding it", because `.worktrees/` is relative to
    # the change worktree while a harness location is not. Step 1 retired that
    # framing: there is one location now, and the dispatcher named it.
    grep -q 'the one the dispatcher named' "$wd"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of where it sits, not an assertion.)
    run grep -q 'rather than rebuilding it' "$wd"
    [ "$status" -ne 0 ]
}

@test "merge-change: step 8 maps guard 4's refusal to a remedy" {
    # verifies: PR-n57ayn
    # Step 7 counts the guards finish-merge.sh proves and step 8's table is the
    # one place that maps a refusal to a remedy. Guard 4 was added without
    # either being updated, leaving the refusal an operator is now most likely
    # to meet unexplained in both. The row quotes what the script prints.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'proves four things' "$skill"
    grep -q 'a registered worktree lies inside' "$skill"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of where it sits, not an assertion.)
    run grep -q 'proves three things' "$skill"
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
    grep -q 'Both worktree entries earn their place' "$skill"
    grep -q 'every task worktree, which is nested inside the change worktree' "$skill"
}

@test "AGENTS.md: non-negotiable 1 nests the task worktree and names its path" {
    # verifies: PR-n57ayn
    # This repository develops under its own rules, so non-negotiable 1 is
    # where an agent reads the containment rule first. It was rewritten for
    # this change and nothing held it.
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
    # the test's — but that is a property of where it sits, not an assertion.)
    run grep -q 'a dispatch without one taking a tag instead' "$agents"
    [ "$status" -ne 0 ]
}

@test "problem grammar prose: no shipped file still carries owner:" {
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
