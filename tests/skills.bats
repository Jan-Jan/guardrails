# Content lints over the skills, in the spirit of portability.bats's sweep:
# a skill instruction that quietly loses a critical phrase fails here
# rather than in some target project months later.

# The scratch repositories of the tests that run a skill's snippets.
load helpers

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

@test "ratchet: the setup checklist installs GNU parallel for the qualification suite" {
    # verifies: PR-hrx4vf
    checklist="$BATS_TEST_DIRNAME/../skills/ratchet/references/setup-checklist.md"
    grep -q 'GNU `parallel`' "$checklist" || { echo "no GNU parallel item"; false; }
    grep -q 'brew install parallel' "$checklist" || { echo "no macOS install line"; false; }
    grep -q 'apt install parallel' "$checklist" || { echo "no Debian install line"; false; }
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

@test "ratchet: Done when states when an upgrade is complete" {
    # verifies: PR-s8dcmp
    # Upgrade became a third mode with no completion check: Done when asked a
    # retrofit for a gap analysis and asked an upgrade for nothing, so
    # "the scripts are copied" could count as done.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    done_when=$(awk '/^## Done when/ { inside = 1; next } /^## / { inside = 0 } inside' "$skill")
    printf '%s\n' "$done_when" | grep -q 'An upgrade copied scripts and grammar files from one guardrails version,'
    printf '%s\n' "$done_when" | grep -q 'fixed each failure, and listed each new warning in a plan.'
}

@test "ratchet: upgrade step 4 fixes each failure and lists each new warning in a plan" {
    # verifies: PR-s8dcmp
    # Done when checks that each failure is fixed and each warning listed, so
    # the upgrade procedure has to say so. A failure cannot be listed instead:
    # the upgrade merges through merge-change, whose gate needs check-trace.sh
    # to pass (review round 1, finding-1).
    # Only new warnings are listed: the old ones are already in the problem
    # ledger (round 2, finding-5).
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    upgrade=$(awk '/^### Upgrading the scripts/ { inside = 1; next } /^##/ { inside = 0 } inside' "$skill")
    printf '%s\n' "$upgrade" | grep -q '^4\. Run `check-trace.sh`; fix each failure, and list each new warning in a plan$'
    ! grep -q 'or list it in a plan' "$skill" \
        || { echo "SKILL.md still lets a failure be listed instead of fixed"; false; }
    ! grep -q 'each warning' "$skill" \
        || { echo "SKILL.md lists every warning, not only the new ones"; false; }
}

@test "ratchet: upgrade is a mode resting on ADR-3h4dky, and retrofit no longer inventories a re-ratchet" {
    # verifies: PR-s8dcmp
    # No decision created the upgrade mode. The decision is recorded now, and
    # step 1 points to the reason. The retrofit inventory's "if re-ratcheting"
    # clause sent an installed project to the mode that it no longer belongs to.
    root="$BATS_TEST_DIRNAME/.."
    skill="$root/skills/ratchet/SKILL.md"
    adr="$root/docs/adr/ADR-3h4dky-upgrade-is-its-own-mode.md"
    grep -q 'procedure below, with no gap analysis (`references/rationale.md`)' "$skill"
    ! grep -q 're-ratcheting' "$skill" \
        || { echo "the retrofit inventory still names a re-ratchet"; false; }
    head -n 1 "$adr" | grep -q '^\*\*ADR-3h4dky\*\*: '
    grep -q 'ADR-3h4dky' "$root/skills/ratchet/references/rationale.md"
}

@test "ratchet: the upgrade order of work has the macOS pass and defines a new warning" {
    # verifies: PR-s8dcmp
    # Moved out of SKILL.md's upgrade steps to make room for the Done when
    # entry; the order of work is what upgrade step 1 has the agent follow.
    notes="$BATS_TEST_DIRNAME/../skills/ratchet/references/upgrade-notes.md"
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    order=$(awk '/^## Order of work/ { inside = 1; next } /^## / { inside = 0 } inside' "$notes")
    printf '%s\n' "$order" | grep -q 'ever run on macOS, run `check-review.sh --branch <name>`'
    printf '%s\n' "$order" | grep -q '^7\. Fix each failure, and list each new warning in a plan in `docs/plans/`;'
    printf '%s\n' "$order" | grep -q 'A warning is a finding printed without'
    printf '%s\n' "$order" | grep -q 'A new warning is one the run in item 2'
    printf '%s\n' "$order" | grep -q 'failing the run: `UNRESOLVED-PR`, `ACCEPTED-PR`, and an `UNMET-EXPECTATION`'
    printf '%s\n' "$order" | grep -q 'keep its output for item 7'
    printf '%s\n' "$order" | grep -q 'an older one is already recorded in its ledger'
    ! grep -q 'If `/ratchet` was ever run on macOS' "$skill" \
        || { echo "SKILL.md still carries the macOS step"; false; }
}

@test "ratchet: the retrofit still advises splitting each monolithic ledger file, and why" {
    # verifies: PR-s8dcmp
    # The word trim for the upgrade entry shortened this sentence to srs.md
    # alone and dropped its reason (review round 1, finding-3).
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'monolithic `doc_\*` file into a directory as its first dated file' "$skill"
    grep -q 'README, so changes stop conflicting' "$skill"
    grep -q 'Each `doc_\*` key accepts a file or a directory, so `srs.md` keeps' "$skill"
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
    # The skip names when no review worktree exists (review round 4, finding
    # 18): a cut left "skip it there" with no antecedent.
    sed -n "${a_at},${b_at}p" "$skill" | grep -q 'Not every round creates one: a human reviewer uses their checkout'
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

# Prints the last sh fence under the `## ` heading that starts with $2 in file
# $1. Each before-opening check is one sh fence under its heading; (b) sets
# item_ids on that fence's first line.
gr_last_sh_fence() {
    awk -v heading="$2" '
        /^## / { inside = (index($0, heading) == 1); next }
        inside && /^```sh$/ { fenced = 1; block = ""; next }
        inside && fenced && /^```$/ { fenced = 0; last = block; next }
        inside && fenced { block = block $0 "\n" }
        END { printf "%s", last }
    ' "$1"
}

# Prints every sh fence under the `## ` heading that starts with $2 in file
# $1, in order: the text a user pastes to run that check.
gr_all_sh_fences() {
    awk -v heading="$2" '
        /^## / { inside = (index($0, heading) == 1); next }
        inside && /^```sh$/ { fenced = 1; next }
        inside && fenced && /^```$/ { fenced = 0; next }
        inside && fenced { print }
    ' "$1"
}

@test "worktree-discipline: a change opens after checking the worktrees and the claimed items" {
    # verifies: D4 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # Changes may run in parallel, so two sessions can resolve the same item
    # unless the second looks first. Before step 2 creates the change worktree,
    # the skill has the agent list every registered worktree and ask whether an
    # unmerged branch already claims an item the new change will touch. The
    # claim check reads each branch's diff against the base branch: the ID is
    # defined on the base branch, so a plain `git grep` finds it everywhere.
    skill="$BATS_TEST_DIRNAME/../skills/worktree-discipline/SKILL.md"
    reference="$BATS_TEST_DIRNAME/../skills/worktree-discipline/references/before-opening.md"
    # Prose wraps and indents, so a phrase is matched on the step with its lines
    # joined and its runs of spaces squeezed.
    step2=$(awk '/^2\. \*\*/ { inside = 1 } /^3\. \*\*/ { inside = 0 } inside' "$skill" | tr '\n' ' ' | tr -s ' ')
    [ -n "$step2" ]
    printf '%s\n' "$step2" | grep -q 'a status line per registered worktree'
    printf '%s\n' "$step2" | grep -q 'adds or removes a line containing the ID'
    printf '%s\n' "$step2" | grep -q 'claims the item: stop and ask the user'
    # The check is an instruction to act before the worktree exists, so it
    # comes before step 2 tells the agent to create it.
    check_at=$(printf '%s\n' "$step2" | awk '{ print index($0, "status line per registered worktree") }')
    create_at=$(printf '%s\n' "$step2" | awk '{ print index($0, "Harness tool first") }')
    [ "$check_at" -gt 0 ]
    [ "$create_at" -gt 0 ]
    [ "$check_at" -lt "$create_at" ]
    grep -qE '^- `references/before-opening\.md` — read when ' "$skill"
    [ -f "$reference" ]
    grep -q 'git worktree list --porcelain' "$reference"
    # The snippet, not the file: the prose below it quotes the same command
    # (review round 2, finding 9).
    gr_last_sh_fence "$reference" '## (b) ' | grep -qF 'git diff "$BASE...$branch"'
    tr '\n' ' ' < "$reference" | grep -q 'plain `git grep`'
    # The claim check cannot see an uncommitted claim; the doc ties that to
    # the dirty count (a) prints (review round 1, finding 6).
    tr '\n' ' ' < "$reference" | tr -s ' ' | grep -q 'The check reads committed history only'
    tr '\n' ' ' < "$reference" | tr -s ' ' | grep -q 'with a dirty count above 0 may hold one'
}

@test "worktree-discipline: the before-opening snippets run, and the claim check reads the diff" {
    # verifies: D4 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # The two snippets in before-opening.md are run, not only grepped (review
    # round 1, finding 4). A scratch repository has a branch that claims an
    # item, a branch that does not, and a worktree with an uncommitted file.
    # Check (a) must print each worktree's ahead and dirty counts; check (b)
    # must name the claiming branch and not the clean one. A plain
    # `git grep "$id" "$branch"` finds the ID on every branch, because the
    # item is defined on the base branch, so it reports the clean branch too.
    reference="$BATS_TEST_DIRNAME/../skills/worktree-discipline/references/before-opening.md"
    scratch="$BATS_TEST_TMPDIR"
    gr_last_sh_fence "$reference" '## (a) ' > "$scratch/worktrees.sh"
    gr_last_sh_fence "$reference" '## (b) ' > "$scratch/claims.sh"
    grep -q 'git worktree list --porcelain' "$scratch/worktrees.sh"
    grep -q 'for-each-ref' "$scratch/claims.sh"
    # Every case pattern opens with `(` (AGENTS.md): after `case ... in` and
    # after each `;;`, the next non-blank line is a pattern or `esac`.
    unparenthesized=$(awk '
        /^[[:space:]]*(#|$)/ { next }
        armed { armed = 0; if ($0 !~ /^[[:space:]]*(\(|esac)/) print FILENAME ": " $0 }
        /(^|[[:space:]])case[[:space:]].*[[:space:]]in[[:space:]]*$/ || /;;[[:space:]]*$/ { armed = 1 }
    ' "$scratch/worktrees.sh" "$scratch/claims.sh")
    [ -z "$unparenthesized" ] || { echo "parenless case pattern: $unparenthesized"; false; }
    grep -q 'case ' "$scratch/worktrees.sh"

    repo="$scratch/repo"
    mkdir -p "$repo"
    cd "$repo"
    git init -q -b main --template=
    git config user.name test
    git config user.email test@example.com
    git config commit.gpgsign false
    printf '# PR-abc123: an item defined on the base branch\n' > ledger.md
    git add -A
    git commit -qm base
    git branch claimer
    git branch clean
    git worktree add -q "$scratch/wt-claimer" claimer
    git worktree add -q "$scratch/wt-clean" clean
    printf 'resolves: PR-abc123\n' > "$scratch/wt-claimer/plan.md"
    git -C "$scratch/wt-claimer" add -A
    git -C "$scratch/wt-claimer" commit -qm claim
    printf 'unrelated\n' > "$scratch/wt-clean/notes.md"
    git -C "$scratch/wt-clean" add -A
    git -C "$scratch/wt-clean" commit -qm notes
    printf 'uncommitted\n' > "$scratch/wt-clean/scratch.txt"
    # A branch whose only edit sits next to the ID line, not on it: its diff
    # shows the ID line as context, which is not a claim. A worktree on a
    # detached HEAD, and one whose directory is gone, so git lists it as
    # prunable. Each pins a line of the snippets that before-opening.md
    # documents (review round 3, finding 14).
    git branch neighbour
    git worktree add -q "$scratch/wt-neighbour" neighbour
    printf 'status: open\n' >> "$scratch/wt-neighbour/ledger.md"
    git -C "$scratch/wt-neighbour" commit -qam 'status line below the ID line'
    git worktree add -q --detach "$scratch/wt-detached" main
    git worktree add -q -b gone "$scratch/wt-gone"
    rm -r "$scratch/wt-gone"

    # The checks are pasted into whatever shell the caller has, with BASE set
    # but not exported by the detection line. zsh does not word-split an
    # unquoted variable, and its `path` is tied to PATH, so the doc runs each
    # check under sh (review round 4, finding 15). Each check runs as pasted
    # under sh and, where installed, under zsh.
    gr_all_sh_fences "$reference" '## (a) ' > "$scratch/worktrees.pasted"
    gr_all_sh_fences "$reference" '## (b) ' \
        | sed 's/PR-<token> REQ-<token>/PR-abc123 REQ-zzz999/' > "$scratch/claims.pasted"
    grep -q 'PR-abc123 REQ-zzz999' "$scratch/claims.pasted"
    shells=sh
    if command -v zsh >/dev/null 2>&1; then
        shells="sh zsh"
    fi

    for shell in $shells; do
        run "$shell" -c "BASE=main; $(cat "$scratch/worktrees.pasted")"
        [ "$status" -eq 0 ] || { echo "(a) under $shell: $output"; false; }
        [ "$(printf '%s\n' "$output" | grep -c .)" -eq 6 ] || { echo "(a) under $shell: $output"; false; }
        printf '%s\n' "$output" | grep -qE '^main  ahead 0  dirty 0  last [0-9-]+  '
        printf '%s\n' "$output" | grep -qE '^claimer  ahead 1  dirty 0  last [0-9-]+  .*/wt-claimer$'
        printf '%s\n' "$output" | grep -qE '^clean  ahead 1  dirty 1  last [0-9-]+  .*/wt-clean$'
        printf '%s\n' "$output" | grep -qE '^neighbour  ahead 1  dirty 0  last [0-9-]+  .*/wt-neighbour$'
        # A detached worktree prints `(detached)` for its branch; a prunable one
        # prints no counts.
        printf '%s\n' "$output" | grep -qE '^\(detached\)  ahead 0  dirty 0  last [0-9-]+  .*/wt-detached$'
        printf '%s\n' "$output" | grep -qE '^gone  prunable  .*/wt-gone$'
    done

    # The base branch moves on after the branches were cut: another change
    # that resolved the item merged. A two-dot `"$BASE..$branch"` diff shows
    # that line as removed on every older branch and reports each as a claim;
    # the three-dot diff starts where the branch left the base (review round
    # 2, finding 9).
    printf 'status: resolved\n# PR-abc123: resolved by another change\n' >> ledger.md
    git commit -qam 'another change resolves PR-abc123'

    # Exactly one line: the neighbour branch, whose diff carries the ID line
    # only as context, is not reported.
    # Run as pasted, with two IDs: under zsh an unsplit list matched nothing,
    # and the check printed nothing, the answer for an unclaimed item.
    for shell in $shells; do
        run "$shell" -c "BASE=main; $(cat "$scratch/claims.pasted")"
        [ "$status" -eq 0 ]
        [ "$output" = 'CLAIMED  PR-abc123  by claimer' ] || { echo "(b) under $shell: $output"; false; }
    done

    # Base detection failed, and the block was pasted whole: with BASE empty,
    # (a) printed `ahead 0` for every worktree, which reads as valid data, and
    # (b) printed no CLAIMED line, the answer for an unclaimed item. Each check
    # stops first and names the cause (review round 6, finding 26).
    for shell in $shells; do
        for pasted in worktrees claims; do
            run "$shell" -c "BASE=; $(cat "$scratch/$pasted.pasted")"
            [ "$status" -ne 0 ] || { echo "$pasted under $shell, BASE empty: $output"; false; }
            printf '%s\n' "$output" | grep -qF 'BASE is empty: detect the base branch first' \
                || { echo "$pasted under $shell, BASE empty: $output"; false; }
            if printf '%s\n' "$output" | grep -qE 'ahead|prunable|CLAIMED'; then
                echo "$pasted under $shell, BASE empty: $output"
                false
            fi
        done
    done
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

@test "merge-change: step 8 reports without re-verifying the signature" {
    # verifies: D1, D2, D3 (docs/plans/2026-10-05-step-8-trusts-finish-merge.md)
    # Guard 1 of finish-merge.sh verifies the signature under --strict in the
    # user's shell before it removes anything. Step 8 re-ran the same check
    # from the agent's shell, where a read-only ~/.gnupg reads a good
    # signature as N. On success step 8 now reports from the message file;
    # it investigates only a reported problem or a non-zero exit.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    step8=$(awk '/^8\. \*\*/ { inside = 1 } /^## / { inside = 0 } inside' "$skill")
    [ -n "$step8" ]
    printf '%s\n' "$step8" | grep -q 'closing line from the message file'
    printf '%s\n' "$step8" | grep -q 'Run no git command: `finish-merge.sh` verified the signature'
    printf '%s\n' "$step8" | grep -q 'branch, IDs, record'
    # Re-aimed 2026-10-07 (parallel-changes review round 4): what the message
    # states was removed moved to cleanup-rejections.md, which step 8 names.
    grep -q 'the worktree alone when only the branch deletion' \
        "$(dirname "$skill")/references/cleanup-rejections.md"
    printf '%s\n' "$step8" | grep -q 'If the user reports a problem or `finish-merge.sh` exited non-zero'
    printf '%s\n' "$step8" | grep -q 'references/cleanup-rejections.md'
    printf '%s\n' "$step8" | grep -q 're-run the script alone'
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command.
    run grep -q -e '%G?' -e 'check-signing' -e '`git ' <<< "$step8"
    [ "$status" -ne 0 ]
}

@test "merge-change: step 7 tells the user what success looks like" {
    # verifies: D4 (docs/plans/2026-10-05-step-8-trusts-finish-merge.md)
    # Step 8 no longer checks, so the user is the one who notices a guard's
    # rejection. Step 7 names the success output, and that output is what
    # finish-merge.sh prints at exit 0: three lines prefixed `finish-merge:`.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    script="$BATS_TEST_DIRNAME/../scripts/finish-merge.sh"
    step7=$(awk '/^7\. \*\*/ { inside = 1 } /^8\. \*\*/ { inside = 0 } inside' "$skill")
    [ -n "$step7" ]
    printf '%s\n' "$step7" | tr '\n' ' ' | grep -q 'Success ends with three *`finish-merge:` lines'
    printf '%s\n' "$step7" | tr '\n' ' ' | grep -q 'otherwise, they paste the output'
    [ "$(grep -c '^echo "finish-merge: ' "$script")" -eq 3 ]
}

@test "merge-change: Done when names finish-merge.sh as the verifier" {
    # verifies: D5 (docs/plans/2026-10-05-step-8-trusts-finish-merge.md)
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    done_when=$(awk '/^## Done when/ { inside = 1; next } /^## / { inside = 0 } inside' "$skill")
    printf '%s\n' "$done_when" | grep -q 'verified by `finish-merge.sh`'
    run grep -q 'check-signing' <<< "$done_when"
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

@test "AGENTS.md: non-negotiable 4 states the rule and points to its ADR" {
    # verifies: D10 (docs/plans/2026-09-28-agent-first-skills.md)
    agents="$BATS_TEST_DIRNAME/../AGENTS.md"
    adr="$BATS_TEST_DIRNAME/../docs/adr/ADR-y8jmes-local-main-is-the-base.md"
    grep -q 'Never consult `origin`' "$agents"
    grep -q 'docs/adr/ADR-y8jmes-local-main-is-the-base.md' "$agents"
    grep -q 'GR_ID_ANY' "$adr"
    run grep -q 'GR_ID_ANY' "$agents"
    [ "$status" -ne 0 ]
}

@test "AGENTS.md: changes may run in parallel; the non-negotiables run 1 to 4" {
    # verifies: D1 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    root="$BATS_TEST_DIRNAME/.."
    agents="$root/AGENTS.md"
    run grep -n -e 'Open one change at a time' -e 'never across changes' "$agents"
    [ "$status" -ne 0 ]
    numbers=$(awk '
        /^## Non-negotiables/ { inside = 1; next }
        /^## / { inside = 0 }
        inside && /^[0-9]+\. / { sub(/\..*/, ""); printf "%s ", $0 }
    ' "$agents")
    [ "$numbers" = "1 2 3 4 " ]
    run grep -rn 'non-negotiable 5' "$agents" "$root/README.md" \
        "$root/docs/adr" "$root/skills" "$root/templates"
    [ "$status" -ne 0 ]
    run grep -n 'Changes are sequential' "$root/README.md"
    [ "$status" -ne 0 ]
    # The old rule must not return in another wording, and the README must
    # state the new one (review round 1, finding 5).
    run grep -n -e 'Bring a change to its signed squash before' \
        -e 'before opening the next' "$agents"
    [ "$status" -ne 0 ]
    tr '\n' ' ' < "$root/README.md" | tr -s ' ' |
        grep -q 'Changes may run in parallel, each in its own change worktree'
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
    grep -q 'DANGLING-FILE' "$BATS_TEST_DIRNAME/../scripts/finalize-docs.sh"
    grep -q 'reported as left' "$BATS_TEST_DIRNAME/../scripts/finalize-docs.sh"
    grep -q 'root-relative' "$BATS_TEST_DIRNAME/../scripts/finalize-docs.sh"
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

@test "develop-change: the mutation-anchor rule lives in this repository's TEST_GUIDELINES.md, not develop-change" {
    # verifies: PR-dr7k7k, PR-ttg99p
    # Was annotated PR-4fwfjp, which is the `status: accepted` item and states
    # nothing about mutation anchors: this test asserts an obligation that
    # belonged to no item at all until PR-dr7k7k was written for it.
    # A mutation script embeds a line of the script it mutates as a literal
    # `old = '''…'''` and asserts one match, so a change that edits a quoted
    # line leaves a mutation that cannot apply. tests/mutations.bats reports
    # such a mutation, but only when the full suite is run, after the edit is
    # complete; the grep in the TDD loop finds the hit while the edit is in
    # progress.
    # Only this repository has docs/verification/*.mutations/, so the rule is
    # stated in its own docs/TEST_GUIDELINES.md and not in the shipped skill,
    # where an adopter's grep matched nothing (PR-ttg99p).
    guidelines="$BATS_TEST_DIRNAME/../docs/TEST_GUIDELINES.md"
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -q 'mutations' "$guidelines"
    # Re-cutting is the prescribed answer, and re-cutting without re-proving is
    # the failure it invites: an anchor can match again and kill nothing.
    grep -q 'kills tests' "$guidelines"
    if grep -q 'mutations' "$skill"; then
        echo "develop-change still states the repository-only anchor rule"
        false
    fi
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

@test "verification template: a record does not count itself, and narrates once" {
    # verifies: D9 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # A count of a record's own rounds or findings, written in that record,
    # is falsified by the next commit that adds a finding block, the commit
    # that writes the count included (G1 of the churn proposal). Prose
    # rewritten each round restates earlier rounds and draws findings of its
    # own (P12 of the parallel-session proposals).
    template="$BATS_TEST_DIRNAME/../templates/verification.md"
    text=$(tr '\n' ' ' < "$template" | tr -s ' ')
    printf '%s\n' "$text" | grep -qF 'The `### Round <N>` headings and the `**finding-` blocks are the count'
    printf '%s\n' "$text" | grep -qF 'State no number of rounds, findings or dispositions in prose'
    printf '%s\n' "$text" | grep -qF 'Write this section and the Gaps once, after the final round'
    printf '%s\n' "$text" | grep -qF 'with no round-by-round account'
    round_line=$(grep -n '^### Round 1$' "$template" | cut -d: -f1)
    finding_line=$(grep -n '^\*\*finding-1\*\*:' "$template" | cut -d: -f1)
    [ -n "$round_line" ] && [ -n "$finding_line" ] && [ "$round_line" -lt "$finding_line" ]
}

@test "PR-kc2pzm carries P8 and P9 as candidates, with P9's defect" {
    # verifies: D10 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # A parallel suite run measured 650 s, over D10's five minutes, so the
    # cheaper record lane still pays for itself and both proposals are kept
    # on the item that owns the question, rather than lost with the branch
    # that carried them.
    ledger="$BATS_TEST_DIRNAME/../docs/problems/2026-09-15-field-report-two.md"
    item=$(awk '/^\*\*PR-kc2pzm\*\*:/ { inside = 1; print; next }
                inside && /^\*\*[A-Z]+-[a-z0-9]+\*\*:/ { exit }
                inside' "$ledger" | tr '\n' ' ' | tr -s ' ')
    [ -n "$item" ]
    printf '%s\n' "$item" | grep -q '^\*\*PR-kc2pzm\*\*:'
    printf '%s\n' "$item" | grep -qF 'Candidate formulations, neither adopted'
    printf '%s\n' "$item" | grep -qF '**P8, per gate, by running the gates.**'
    printf '%s\n' "$item" | grep -qF '**P9, the reviewer'"'"'s run scoped to the round'"'"'s delta.**'
    printf '%s\n' "$item" | grep -qF 'is empty under that pathspec and can still turn the suite red'
    printf '%s\n' "$item" | grep -q '^.*status: open'
    rationale="$BATS_TEST_DIRNAME/../skills/merge-change/references/rationale.md"
    tr '\n' ' ' < "$rationale" | tr -s ' ' | grep -qF '`PR-kc2pzm` records two candidates that answer it per gate instead'
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
    # Re-aimed 2026-10-07 (parallel-changes review round 4): this reason for
    # removing the review worktree in 6a moved to the rationale.
    grep -q 'any finding at' "$(dirname "$skill")/references/rationale.md"
    grep -q 'whatever the findings were tagged' "$(dirname "$skill")/references/rationale.md"
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
    # Re-aimed 2026-10-08 (out-of-force items D7): the dual-ID rule it pinned
    # is gone; the checklist item now states the successor's own test.
    grep -q 'The successor has its own test' \
        "$BATS_TEST_DIRNAME/../skills/merge-change/references/review-checklist.md"
    # Re-aimed 2026-10-07 (parallel-changes review round 4): two reasons moved
    # to the rationale to make room for instructions.
    grep -q 'not by its filename' "$rationale"
    # Review round 4, finding 18: a cut dropped where an exit 2 can come from.
    grep -q 'usage or environment error from the pre-flight or a tool it runs' "$skill"
    grep -q 'their shell has none of your variables' "$rationale"
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
    grep -q 'so a pass added nothing' "$rationale"
    grep -q 'only the cleanup is outstanding' "$rationale"
    # Finding 23 of review round 4: the step 1 paragraph stated that two
    # branches cannot collide by construction.
    run grep -q 'cannot collide by construction' "$rationale"
    [ "$status" -ne 0 ]
    run grep -q 'with two independent reviewers for critical' "$skill"
    [ "$status" -ne 0 ]
}

@test "merge-change: changes may run in parallel, and the rationale says why" {
    # verifies: D2 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # Nothing may bar a second change from opening, since AGENTS.md allows
    # parallel changes (D1). The rationale must state why that is safe: step 1
    # merges the base every round, IDs are random tokens, and each change's
    # record is found by its branch: field.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    rationale="$BATS_TEST_DIRNAME/../skills/merge-change/references/rationale.md"
    # Prose wraps, so a phrase is matched on the file with its lines joined.
    rationale_text=$(tr '\n' ' ' < "$rationale")
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command.
    run grep -qi 'one change at a time' "$skill" "$rationale"
    [ "$status" -ne 0 ]
    # The same precondition may return in other words, such as "Only one open
    # change" (review round 2, finding 10). The Preconditions section keeps
    # its three bullets, and none of its lines pairs "change" with "open",
    # "one" or "next".
    preconditions=$(awk '/^## / { inside = ($0 == "## Preconditions"); next } inside' "$skill")
    [ "$(printf '%s\n' "$preconditions" | grep -c '^- ')" -eq 3 ]
    one_change=$(printf '%s\n' "$preconditions" | awk '{
        line = tolower($0)
        if (line ~ /change/ && line ~ /(^|[^a-z])(open|one|next)([^a-z]|$)/) print
    }')
    [ -z "$one_change" ] || { echo "precondition limits open changes: $one_change"; false; }
    grep -q '^## Changes open in parallel$' "$rationale"
    printf '%s\n' "$rationale_text" | grep -q 'reaches every other change before its gate'
    printf '%s\n' "$rationale_text" | grep -q 'two worktrees do not contend for an ID'
    printf '%s\n' "$rationale_text" | grep -q '`DUPLICATE-ID` catches the improbable collision'
    printf '%s\n' "$rationale_text" | grep -q 'the gate finds it by its `branch:` field'
}

@test "merge-change: a base merge that shares a file with the change gets a fresh review" {
    # verifies: D2 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # With changes open in parallel, the base can move after the last
    # reviewer was dispatched: on the rerun after an all-low round, or after
    # step 7's base-moved remedy. The gate reruns on the merged tree, but no
    # reviewer saw the merge (review round 4, finding 16). The maintainer
    # ruled on 2026-10-07: when the base and the change edited the same file,
    # the whole change goes to a fresh reviewer; when the files are disjoint,
    # the gate rerun covers it. Step 1 lists the files the base edited after
    # the commit 6a marked as reviewed that the change also edits. It compares
    # against that marker, not the last base merge, so a rerun after a failed
    # gate lists the file again (review round 5, finding 21). This test runs
    # step 1's fence and 6a's marker against one fixture, scenario by scenario.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    rationale="$BATS_TEST_DIRNAME/../skills/merge-change/references/rationale.md"
    template="$BATS_TEST_DIRNAME/../templates/verification.md"
    step1=$(awk '/^1\. \*\*/ { inside = 1 } /^2\. \*\*/ { inside = 0 } inside' "$skill")
    [ -n "$step1" ]
    step1_text=$(printf '%s\n' "$step1" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$step1_text" | grep -qF 'A `shared:` line names a file this change edits that the base edited after the last reviewed commit: 6a then reviews the whole change again, even after the last review round. Otherwise the gate rerun covers it.'
    rationale_text=$(tr '\n' ' ' < "$rationale" | tr -s ' ')
    printf '%s\n' "$rationale_text" | grep -q 'A base that moved also changes what the review saw'
    printf '%s\n' "$rationale_text" | grep -q 'any shared file sends the whole change to a fresh reviewer'
    printf '%s\n' "$rationale_text" | grep -q 'A conflict is not the test'
    printf '%s\n' "$rationale_text" | grep -q 'because the obligation must survive a rerun'
    tr '\n' ' ' < "$template" | tr -s ' ' | grep -q 'name the shared files and that review round'

    sh_fence() {
        awk '
            /^ *```sh$/ { fenced = 1; next }
            fenced && /^ *```$/ { exit }
            fenced { sub(/^   /, ""); print }
        '
    }
    fence=$(printf '%s\n' "$step1" | sh_fence)
    printf '%s\n' "$fence" | grep -q 'git merge "\$base_ref"'
    review_step=$(awk '/^6a\. \*\*/ { inside = 1 } /^6b\. \*\*/ { inside = 0 } inside' "$skill")
    mark=$(printf '%s\n' "$review_step" | sh_fence)
    printf '%s\n' "$mark" | grep -q -- '--allow-empty'
    # Runs step 1's fence and leaves its `shared:` lines in $shared.
    run_step1() {
        run env GIT_MERGE_AUTOEDIT=no sh -c "BASE=main; $fence"
        [ "$status" -eq 0 ] || { echo "$output"; false; }
        shared=$(printf '%s\n' "$output" | grep '^shared: ' || true)
    }
    on_main() {
        git checkout -q main
        "$@"
        git checkout -q change
    }
    edit_line() { sed -i.bak "s/^$2\$/$3/" "$1" && rm "$1.bak"; }

    make_fixture_repo
    printf '1\n2\n3\n4\n5\n6\n7\n8\n' > shared.txt
    printf '1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n' > tests.bats
    printf 'notes\n' > notes.txt
    printf 'my notes\n' > my-notes.txt
    printf '1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n' > old-name.txt
    commit_all 'files both sides will edit'
    git checkout -q -b change
    edit_line shared.txt 1 one
    edit_line tests.bats 2 two
    printf 'own notes\n' > notes.txt
    git mv old-name.txt new-name.txt
    commit_all 'the change'

    # No reviewer yet: the first review will see everything, so nothing lists.
    on_main eval 'edit_line shared.txt 8 eight && commit_all "base edits the shared file"'
    run_step1
    [ -z "$shared" ] || { echo "$shared"; false; }

    # A reviewer is dispatched; then the base edits the shared file.
    sh -c "$mark" >/dev/null
    on_main eval 'edit_line shared.txt 5 five && commit_all "base edits the shared file again"'
    run_step1
    [ "$shared" = 'shared: shared.txt' ] || { echo "$output"; false; }
    # The gate fails and a fix lands. The rerun merges nothing, and still
    # lists the file: no reviewer has seen that merge.
    printf 'fix\n' > fix.txt
    commit_all 'fix after the gate failed'
    run_step1
    [ "$shared" = 'shared: shared.txt' ] || { echo "$output"; false; }

    # A fresh reviewer sees the merged tree: nothing lists for the same base.
    sh -c "$mark" >/dev/null
    run_step1
    [ -z "$shared" ] || { echo "$shared"; false; }

    # A base move on disjoint files lists nothing.
    on_main eval 'printf "disjoint\n" > disjoint.txt && commit_all "base edits its own file"'
    run_step1
    [ -z "$shared" ] || { echo "$shared"; false; }
    [ -f disjoint.txt ]

    # The base renames a file the change edits: it lists under the old path.
    sh -c "$mark" >/dev/null
    on_main eval 'git mv tests.bats moved.bats && edit_line moved.bats 9 nine && commit_all "base renames"'
    run_step1
    [ "$shared" = 'shared: tests.bats' ] || { echo "$output"; false; }
    grep -qx two moved.bats
    grep -qx nine moved.bats

    # The change renamed a file the base then edits: the old path lists.
    sh -c "$mark" >/dev/null
    on_main eval 'edit_line old-name.txt 9 nine && commit_all "base edits a file the change renamed"'
    run_step1
    [ "$shared" = 'shared: old-name.txt' ] || { echo "$output"; false; }
    grep -qx nine new-name.txt

    # A base file whose name contains a changed file's name is not shared.
    sh -c "$mark" >/dev/null
    on_main eval 'printf "their notes\n" > my-notes.txt && commit_all "base edits my-notes.txt"'
    run_step1
    [ -z "$shared" ] || { echo "$shared"; false; }
}

@test "merge-change: step 7 checks for a staged squash before staging its own" {
    # verifies: D5 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # With one squash already staged in the primary index, a second
    # `git merge --squash` exits 0 and stacks its files onto the first when
    # the two touch different files and it fast-forwards; on a shared file git
    # refuses. The staged squash is a lock only if step 7 looks for it before
    # staging. The check is joined to the squash with `&&`: run as two lines in
    # one shell call, a non-empty index fails the check and the squash runs
    # anyway (review round 1, finding 1).
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    rationale="$BATS_TEST_DIRNAME/../skills/merge-change/references/rationale.md"
    # Prose wraps, so a phrase is matched on the file with its lines joined.
    rationale_text=$(tr '\n' ' ' < "$rationale")
    step7=$(awk '/^7\. \*\*/ { inside = 1 } /^8\. \*\*/ { inside = 0 } inside' "$skill")
    [ -n "$step7" ]
    printf '%s\n' "$step7" | grep -qE '^ *git diff --cached --quiet && git merge --squash <branch>$'
    # The squash command appears only in its joined form.
    [ "$(printf '%s\n' "$step7" | grep -c 'git merge --squash <branch>')" -eq 1 ]
    # The second line compares the index with the branch after every squash,
    # not only when the index check fails: a base that moved after the last
    # step 1 makes the squash a three-way merge that exits 0 and stages a
    # tree the gate never saw (review round 3, finding 11).
    printf '%s\n' "$step7" | grep -qE '^ *git diff --cached --quiet <branch>$'
    squash_at=$(printf '%s\n' "$step7" | grep -n 'git merge --squash <branch>$' | cut -d: -f1)
    compare_at=$(printf '%s\n' "$step7" | grep -n '^ *git diff --cached --quiet <branch>$' | cut -d: -f1)
    [ "$compare_at" -eq $((squash_at + 1)) ]
    step7_text=$(printf '%s\n' "$step7" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$step7_text" | grep -qF "The second line exits 0 when the index holds exactly the branch's tree: go on to the message."
    # Which case a failed comparison is follows from the first line's
    # output, not its exit status: a conflicted squash of this change also
    # exits 1 (review round 3, finding 13). A squash that ran is cleared and
    # the sequence reruns from step 1. A squash git refused because the
    # primary checkout is dirty is not a moved base: `git reset --merge` keeps
    # the edit, and the rerun would loop (review round 4, finding 17).
    printf '%s\n' "$step7_text" | grep -qF 'The first line printed that files "would be overwritten": the primary checkout is dirty. Stop and tell the user.'
    printf '%s\n' "$step7_text" | grep -qF "It printed other output: the base moved after step 1. Run \`git reset --merge\`, then rerun from step 1."
    # A squash staged before is another change's or an outdated one of this
    # change: the agent stops and the user decides (review round 2, findings
    # 8 and 10).
    printf '%s\n' "$step7_text" | grep -qF "It printed nothing: a squash was already staged, another change's or an outdated one of this change. Stop and tell the user; once they sign or clear it, rerun from step 1."
    run grep -q 'staged files are' "$skill" "$rationale"
    [ "$status" -ne 0 ]
    grep -q '^## Step 7: the agent stages the squash$' "$rationale"
    printf '%s\n' "$rationale_text" | grep -q 'first come, first served'
    printf '%s\n' "$rationale_text" | grep -q 'stacks its files onto the first'
    printf '%s\n' "$rationale_text" | grep -q 'would leave the index empty until the key touch'
    printf '%s\n' "$rationale_text" | grep -q 'Comparing file names cannot tell'
    printf '%s\n' "$rationale_text" | grep -qF '`git diff --cached --quiet <branch>` can'
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'when an outdated squash of this change is'
    # The parallel section must not claim the index holds one squash by
    # itself; it holds one because step 7 checks (review round 1, finding 3).
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'holds one staged squash only because step 7 checks'
    # Step 1 alone does not close the parallel-change race; step 7's tree
    # comparison does (review round 3, finding 11).
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'Step 1 alone does not close the gap'
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q "Step 7's tree comparison catches that base move"
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'A gate result describes the branch.s tree, and nothing else'
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'runs after every squash, not only when the index check fails'
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -qF '`git reset --merge` resets the index to HEAD'
    # A squash over a staged one stacks only when the two touch different
    # files; on a shared file git refuses, fast-forward or not (review round
    # 3, finding 12).
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'touch different files and the second squash fast-forwards'
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'fast-forward or not'
    run sh -c 'printf "%s\n" "$1" | tr -s " " | grep -q "When it fast-forwards, it exits 0"' _ "$rationale_text"
    [ "$status" -ne 0 ]
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'means the primary checkout has an edit or a file in the squash.s way'
    # Two step 7s at the same instant can still race; the rationale states
    # what catches each outcome (review round 4, finding 17).
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'Two sessions that run step 7 at the same instant can still race'
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'that session.s signing then fails with "nothing to commit"'

    # Step 7's two lines run against git, not only as prose (review round 4,
    # finding 19). Each case is set up in the primary checkout of a scratch
    # repository, with the change branch `feature` already merged with main.
    fence=$(printf '%s\n' "$step7" | awk '
        /^ *```sh$/ { fenced = 1; next }
        fenced && /^ *```$/ { exit }
        fenced { sub(/^ +/, ""); gsub(/<branch>/, "feature"); print }
    ')
    [ "$(printf '%s\n' "$fence" | grep -c .)" -eq 2 ]
    squash_line=$(printf '%s\n' "$fence" | sed -n 1p)
    compare_line=$(printf '%s\n' "$fence" | sed -n 2p)
    make_fixture_repo
    git checkout -q -b feature
    printf 'feature\n' > feature.txt
    commit_all 'the change'
    git checkout -q -b other main
    printf 'other\n' > other.txt
    commit_all 'another change'
    git checkout -q main

    # A clean squash: the index holds exactly the branch's tree.
    run sh -c "$squash_line"
    [ -n "$output" ]
    run sh -c "$compare_line"
    [ "$status" -eq 0 ]
    # This change's own squash, left staged when its signing failed: the
    # index check stops the first line, and the comparison exits 0.
    run sh -c "$squash_line"
    [ -z "$output" ]
    run sh -c "$compare_line"
    [ "$status" -eq 0 ]
    git reset -q --merge

    # Another change's squash is staged: the first line prints nothing and
    # the comparison exits 1.
    git merge -q --squash other
    run sh -c "$squash_line"
    [ -z "$output" ]
    run sh -c "$compare_line"
    [ "$status" -eq 1 ]
    git reset -q --merge

    # The primary checkout has an untracked file in the squash's way: git
    # refuses, says so, and the comparison exits 1.
    printf 'in the way\n' > feature.txt
    run sh -c "$squash_line"
    printf '%s\n' "$output" | grep -q 'would be overwritten'
    run sh -c "$compare_line"
    [ "$status" -eq 1 ]
    rm feature.txt

    # The base moved after the branch merged it: the squash is a three-way
    # merge that exits 0, prints git's output, and stages more than the
    # branch's tree. `git reset --merge` returns the index to HEAD.
    printf 'moved\n' > moved.txt
    commit_all 'the base moves after step 1'
    run sh -c "$squash_line"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    run sh -c "$compare_line"
    [ "$status" -eq 1 ]
    git reset -q --merge
    git diff --cached --quiet HEAD
    [ -z "$(git status --porcelain)" ]
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

@test "skills: no skill tells a superseded item's test to carry both IDs" {
    # verifies: D7 (docs/plans/2026-10-08-out-of-force-items.md)
    root="$BATS_TEST_DIRNAME/.."
    run grep -rnE 'verifies: <old ID>, <new ID>|both IDs on the one test' "$root/skills"
    [ "$status" -ne 0 ] || { echo "$output"; false; }
}

@test "skills: check 4 reads per ID and names an inherited test as coverage" {
    # verifies: D6 (docs/plans/2026-10-08-out-of-force-items.md)
    # A test of a superseded item pointed at its successor passes check 4 only
    # when it is listed as inherited, and is coverage, never red-first
    # evidence. The rule is prose in four places that must agree: the check,
    # the dispatch report form, the record template and step 6b's copy.
    root="$BATS_TEST_DIRNAME/.."
    check="$root/skills/verify-before-merge/SKILL.md"
    grep -qF 'Read it per ID. Every Implements ID needs at least one `verifies:` test' "$check" \
        || { echo "check 4 does not read per ID"; false; }
    grep -qF 'with a `red -> green:` attestation; an ID with none fails the check' "$check" \
        || { echo "check 4 does not fail an ID with no attested test"; false; }
    grep -qF 'inherited: <test name> — from <old ID>' "$check" \
        || { echo "check 4 does not name the inherited: form"; false; }
    grep -qF 'coverage, never red-first evidence' "$check" \
        || { echo "check 4 does not call an inherited test coverage"; false; }

    report="$root/skills/develop-change/SKILL.md"
    grep -qxF 'inherited: <test name> — from <old ID>' "$report" \
        || { echo "the dispatch report form has no inherited: line"; false; }
    grep -qF 'any `inherited:` lines into the plan' "$report" \
        || { echo "develop-change does not write the inherited: lines into the plan"; false; }
    # Moved to the rationale when main's test-seams change left no room in the
    # SKILL.md word budget (2026-10-08).
    grep -qF 'It is coverage, not red-first evidence' "$root/skills/develop-change/references/rationale.md" \
        || { echo "develop-change does not call an inherited test coverage"; false; }

    record="$root/templates/verification.md"
    grep -qF 'list it below the table as `inherited: <test name> — from <old ID>`' "$record" \
        || { echo "the verification template does not say where inherited: goes"; false; }
    grep -qF 'It is coverage, never a row in the table' "$record" \
        || { echo "the verification template puts an inherited test in the table"; false; }

    grep -qF 'any `inherited:` lines from the plan' "$root/skills/merge-change/SKILL.md" \
        || { echo "merge-change step 6b does not copy the inherited: lines"; false; }
}

@test "merge-change: step 1 prunes the plans after the base merge and commits what changed" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # Pruning runs after `git merge`, so the step 2 gate measures the pruned
    # tree; run inside finalize-docs.sh at step 3, it would change the tree
    # after the gate on nearly every merge, and step 6 would dispatch a second
    # suite run (the deviation from D11 in docs/plans/2026-10-08-prune-plans.md).
    # The prune and its commit are chained on the merge's success, and the
    # commit takes only docs/plans: run as separate lines, a conflicted merge
    # was concluded as "chore: prune plans" with its markers staged, and
    # `git add -u` swept every tracked edit into it (review round 1, finding 1).
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    rationale="$BATS_TEST_DIRNAME/../skills/merge-change/references/rationale.md"
    step1=$(awk '/^1\. \*\*/ { inside = 1 } /^2\. \*\*/ { inside = 0 } inside' "$skill")
    [ -n "$step1" ]
    merge_at=$(printf '%s\n' "$step1" | grep -n '^ *git merge "\$base_ref" &&$' | cut -d: -f1)
    prune_at=$(printf '%s\n' "$step1" | grep -n '^ *sh \.guardrails/scripts/prune-plans\.sh --base "\$base_ref" &&$' | cut -d: -f1)
    commit_at=$(printf '%s\n' "$step1" | grep -nF '{ git diff --quiet -- docs/plans || git -c commit.gpgsign=false commit -m "chore: prune plans" -- docs/plans; }' | cut -d: -f1)
    [ -n "$merge_at" ] || { echo "no git merge line chained with &&"; false; }
    [ -n "$prune_at" ] || { echo "no prune-plans.sh --base line chained with &&"; false; }
    [ -n "$commit_at" ] || { echo "no conditional commit of docs/plans"; false; }
    [ "$prune_at" -eq $((merge_at + 1)) ] && [ "$commit_at" -eq $((prune_at + 1)) ] ||
        { echo "not one chain: merge $merge_at, prune $prune_at, commit $commit_at"; false; }
    run grep -q 'git add -u' "$skill"
    [ "$status" -ne 0 ]
    printf '%s\n' "$step1" | tr '\n' ' ' | tr -s ' ' | grep -q 'List each `left whole` plan in the record' ||
        { echo "step 1 does not say to read the left whole lines"; false; }
    grep -q '^## Step 1: plans are pruned after the base merge$' "$rationale" ||
        { echo "no rationale section for pruning at step 1"; false; }
    tr '\n' ' ' < "$rationale" | tr -s ' ' | grep -q 'and not with the draft renames at step 3' ||
        { echo "the rationale does not say why not at step 3"; false; }
}

@test "merge-change: step 1's fence prunes only after a clean merge, and commits only the plans" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # Runs step 1's fence on a fixture: with no docs/plans, then on a
    # conflicting base, then on a clean one with an unrelated edit pending
    # (review round 1, finding 1).
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    step1=$(awk '/^1\. \*\*/ { inside = 1 } /^2\. \*\*/ { inside = 0 } inside' "$skill")
    fence=$(printf '%s\n' "$step1" | awk '
        /^ *```sh$/ { fenced = 1; next }
        fenced && /^ *```$/ { exit }
        fenced { sub(/^   /, ""); print }
    ')
    printf '%s\n' "$fence" | grep -q 'prune-plans.sh'
    run_step1() { run env GIT_MERGE_AUTOEDIT=no sh -c "BASE=main; $fence"; }
    subject() { git log -1 --format=%s; }

    make_fixture_repo
    printf 'one\n' > conflict.txt
    printf 'notes\n' > notes.txt
    commit_all 'files both sides edit'
    git checkout -q -b change
    printf 'change\n' > conflict.txt
    commit_all 'the change'

    # No docs/plans at all: the fence succeeds and commits nothing.
    run_step1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$(subject)" = 'the change' ]

    mkdir -p docs/plans
    printf '### T1 — do it\n\n```sh\necho task-code\n```\n' > docs/plans/2026-01-01-x.md
    commit_all 'the plan'
    git checkout -q main
    printf 'base\n' > conflict.txt
    commit_all 'base edits the same line'
    git checkout -q change

    # A conflicted merge: nothing is pruned or committed, and the merge stays
    # in progress for the agent to resolve.
    run_step1
    [ "$status" -ne 0 ]
    [ "$(subject)" = 'the plan' ] || { echo "committed: $(subject)"; false; }
    git rev-parse -q --verify MERGE_HEAD >/dev/null || { echo "the merge was concluded"; false; }
    [ -n "$(git diff --name-only --diff-filter=U)" ] || { echo "no unmerged path left"; false; }
    grep -q 'task-code' docs/plans/2026-01-01-x.md || { echo "pruned during a conflict"; false; }
    git merge --abort

    # A clean merge with an unrelated edit pending: the pruned plan is
    # committed and the edit is not.
    printf 'base\n' > conflict.txt
    commit_all 'take the base side'
    printf 'pending\n' > notes.txt
    run_step1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$(subject)" = 'chore: prune plans' ] || { echo "last commit: $(subject)"; false; }
    [ "$(git show --name-only --format= HEAD)" = 'docs/plans/2026-01-01-x.md' ]
    ! git show HEAD:docs/plans/2026-01-01-x.md | grep -q 'task-code'
    [ "$(git diff --name-only)" = 'notes.txt' ] || { git status --short; false; }
}

@test "merge-change: the review checklist checks a pruned plan against the diff" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    checklist="$BATS_TEST_DIRNAME/../skills/merge-change/references/review-checklist.md"
    checklist_text=$(tr '\n' ' ' < "$checklist" | tr -s ' ')
    printf '%s\n' "$checklist_text" | grep -q "each pointer stands where the task's code was" ||
        { echo "no pointer check"; false; }
    printf '%s\n' "$checklist_text" | grep -q 'the prose of each task matches the diff' ||
        { echo "no prose check"; false; }
    printf '%s\n' "$checklist_text" | grep -q 'a plan left whole is listed in the record' ||
        { echo "no left-whole check"; false; }
}

@test "plan-change: code in task steps is pruned at merge and red -> green fences are kept" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    skill_text=$(tr '\n' ' ' < "$BATS_TEST_DIRNAME/../skills/plan-change/SKILL.md" | tr -s ' ')
    printf '%s\n' "$skill_text" | grep -q 'replaced by a pointer at merge' ||
        { echo "plan-change does not say task code is pruned"; false; }
    printf '%s\n' "$skill_text" | grep -q '`prune-plans.sh`, `merge-change` step 1' ||
        { echo "plan-change does not name the script and the step"; false; }
    printf '%s\n' "$skill_text" | grep -q 'A fence with a line that opens with `red -> green` is kept' ||
        { echo "plan-change does not say red -> green fences are kept"; false; }
}

@test "ratchet: the upgrade notes name prune_plans, its default and how to opt out" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    notes="$BATS_TEST_DIRNAME/../skills/ratchet/references/upgrade-notes.md"
    grep -q '^## Plans are pruned at merge: `prune_plans`$' "$notes" ||
        { echo "no prune_plans section"; false; }
    notes_text=$(tr '\n' ' ' < "$notes" | tr -s ' ')
    printf '%s\n' "$notes_text" | grep -q 'An absent `prune_plans` is `on`' ||
        { echo "no default"; false; }
    printf '%s\n' "$notes_text" | grep -q '`prune_plans: off`' ||
        { echo "no opt-out"; false; }
    printf '%s\n' "$notes_text" | grep -q 'prune-plans.sh --all' ||
        { echo "no --all for the plans already merged"; false; }
}

@test "ADRs: the pruning decision is recorded and accepted" {
    # verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)
    # The ID is built from a prefix variable: the gates scan tests/.
    adr_prefix=ADR
    adr_file="$BATS_TEST_DIRNAME/../docs/adr/$adr_prefix-bh4xgr-plans-are-pruned-at-merge.md"
    [ -f "$adr_file" ] || { echo "no $adr_file"; false; }
    adr_file_is_named_by_its_item "$adr_file"
    grep -qx 'Status: accepted' "$adr_file"
    adr_text=$(tr '\n' ' ' < "$adr_file" | tr -s ' ')
    printf '%s\n' "$adr_text" | grep -q 'prune-plans.sh' || { echo "no script"; false; }
    printf '%s\n' "$adr_text" | grep -q '`merge-change` step 1' || { echo "no step 1"; false; }
}

# --- test guidelines (docs/plans/2026-10-08-test-guidelines.md) --------------
# The seam and double rules moved to templates/TEST_GUIDELINES.md (T2 pins
# them there); develop-change keeps the floor and reads one guidelines file.

@test "develop-change: every test fails when the behavior it verifies breaks" {
    # verifies: D2 (docs/plans/2026-10-08-test-guidelines.md)
    # The floor rule no guidelines file may override: a test that passes
    # whatever the code does is no verification evidence.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -qxF '**Every test fails when the behavior it `verifies:` breaks.**' "$skill"
    grep -qF 'An assertion only that a double was called meets this only where the' "$skill"
    grep -qxF 'call is the requirement.' "$skill"
}

@test "develop-change: before RED, guidelines-file.sh picks the one guidelines file" {
    # verifies: D8, D6 (docs/plans/2026-10-08-test-guidelines.md)
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -qF 'sh .guardrails/scripts/guidelines-file.sh TEST <the paths the task touches>' "$skill"
    grep -qF 'read no other guidelines file' "$skill"
    grep -qF 'the guidelines file `guidelines-file.sh TEST` printed for' "$skill"
}

@test "develop-change: the guideline reviews follow the deslop pass, before merge-change" {
    # verifies: D1 (docs/plans/2026-10-08-test-guidelines.md)
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    headings=$(grep '^### ' "$skill")
    following=$(printf '%s\n' "$headings" | grep -A1 -xF '### The deslop pass' | sed -n 2p)
    [ "$following" = '### The guideline reviews' ] \
        || { echo "after the deslop pass: '$following'"; false; }
    section=$(awk '/^### The guideline reviews$/ { inside = 1; next } /^##/ { inside = 0 } inside' "$skill")
    printf '%s\n' "$section" | grep -qF '`review-guidelines`'
    printf '%s\n' "$section" | grep -qF '`## Guideline reviews`'
    printf '%s\n' "$section" | grep -qF 'before `merge-change`'
}

@test "develop-change: guideline review findings go into the plan as they arrive, and step 6b copies them" {
    # verifies: D1, D9 (docs/plans/2026-10-08-test-guidelines.md)
    # The reviews run before merge-change, so their findings wait in the plan
    # as the red -> green lines do; 6a reads them there, and 6b copies them
    # into the record it writes after 6a (finding-4, review round 1).
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    section=$(awk '/^### The guideline reviews$/ { inside = 1; next } /^##/ { inside = 0 } inside' "$skill" | tr '\n' ' ' | tr -s ' ')
    if printf '%s\n' "$section" | grep -qF 'which `merge-change` step 6b fills in'; then
        echo "still says step 6b fills in the guideline reviews"; false
    fi
    printf '%s\n' "$section" | grep -qF 'Write each finding and its disposition into the plan as it arrives, as the `red -> green:` lines are'
    printf '%s\n' "$section" | grep -qF '`merge-change` step 6b copies them into the record'"'"'s `## Guideline reviews`'
    merge="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    record_step=$(awk '/^6b\. / { inside = 1 } /^6c\. / { inside = 0 } inside' "$merge" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$record_step" | grep -qF 'any `inherited:` lines from the plan, its guideline reviews (`## Guideline reviews`)'
}

@test "develop-change: a missing or broken guidelines-file.sh stops the task" {
    # verifies: D8 (docs/plans/2026-10-08-test-guidelines.md)
    # Exit 2 means the install is broken; no task proceeds on a guess at the
    # guidelines (finding-5, review round 1).
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    section=$(awk '/^### Test guidelines$/ { inside = 1; next } /^##/ { inside = 0 } inside' "$skill" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$section" | grep -qF 'If it exits 2 or is missing, stop and reinstall the guardrails scripts and templates (`ratchet`'"'"'s upgrade); never proceed without a guidelines file.'
}

@test "develop-change: the dispatch prompt names the guidelines file for each of the task's paths" {
    # verifies: D3, D8 (docs/plans/2026-10-08-test-guidelines.md)
    # A task whose paths span units has more than one governing file; the
    # prompt carries every line guidelines-file.sh printed (finding-6c,
    # review round 1).
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    prompt=$(awk '/^  Execute task 3 of/ { inside = 1 } inside && /^  ```$/ { inside = 0 } inside' "$skill" | tr '\n' ' ' | tr -s ' ')
    [ -n "$prompt" ] || { echo "no dispatch prompt template"; false; }
    printf '%s\n' "$prompt" | grep -qF 'For each of the task'"'"'s paths, follow the guidelines file `guidelines-file.sh TEST` printed for it'
    printf '%s\n' "$prompt" | grep -qF '<file>: <paths> (one line per file it printed)'
}

@test "develop-change: a clause that contradicts the skill is a finding against the clause" {
    # verifies: D2 (docs/plans/2026-10-08-test-guidelines.md)
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -qF 'is a finding against the clause' "$skill"
}

@test "develop-change: the seam reference files are gone" {
    # verifies: D5 (docs/plans/2026-10-08-test-guidelines.md)
    # Their content moved to templates/TEST_GUIDELINES.md, so each rule has
    # one home.
    skill_dir="$BATS_TEST_DIRNAME/../skills/develop-change"
    references=$(awk '/^## References/ { inside = 1; next } /^## / { inside = 0 } inside' "$skill_dir/SKILL.md")
    run sh -c 'printf "%s\n" "$1" | grep -E "test-seams\.md|ui-seams\.md"' _ "$references"
    [ "$status" -ne 0 ]
    [ ! -e "$skill_dir/references/test-seams.md" ]
    [ ! -e "$skill_dir/references/ui-seams.md" ]
}

@test "merge-change: the review checklist's test section is the floor, and checks the guideline reviews ran" {
    # verifies: D2, D9 (docs/plans/2026-10-08-test-guidelines.md)
    # The seam and double rules are a project's preference, checked by
    # review-guidelines against its own file; 6a holds the floor alone and
    # checks that each guideline review ran and was dispositioned.
    checklist="$BATS_TEST_DIRNAME/../skills/merge-change/references/review-checklist.md"
    grep -qF 'checklist applies when the diff touches documentation, and the test' "$checklist"
    grep -qxF '## The test checklist' "$checklist"
    section=$(awk '/^## The test checklist$/ { inside = 1; next } /^## / { inside = 0 } inside' "$checklist" | tr '\n' ' ' | tr -s ' ')
    [ -n "$section" ]
    # `! cmd` does not fail a bats test under errexit; fail explicitly.
    if printf '%s\n' "$section" | grep -qF 'Where a test attaches'; then echo "still cites Where a test attaches"; false; fi
    printf '%s\n' "$section" | grep -qF -- '- It carries a `verifies:` annotation naming the lowest requirement level that exists.'
    printf '%s\n' "$section" | grep -qF -- '- It fails when the behavior it verifies breaks: an assertion only that a double was called meets this only where the call is the requirement.'
    printf '%s\n' "$section" | grep -qF -- '- At class B and C, every REQ and LLR has abnormal-input tests'
    printf '%s\n' "$section" | grep -qF -- '- At class C, every SDD item the change touches is tested at its own interface'
    # The plan holds the guideline reviews when 6a runs; 6b copies them into
    # the record afterwards (finding-4, review round 1).
    printf '%s\n' "$section" | grep -qF 'the plan lists a guideline review for each file `guidelines-file.sh TEST` prints for the diff'
    printf '%s\n' "$section" | grep -qF 'every finding with a disposition'
    printf '%s\n' "$section" | grep -qF 'and so does the record'"'"'s `## Guideline reviews` where the record exists'
    for removed in 'three kinds' 'markup snapshot' 'runs for real on the normal path'; do
        if grep -qF "$removed" "$checklist"; then echo "checklist still states: $removed"; false; fi
    done
}

@test "verification template: guideline reviews have their own section" {
    # verifies: D9 (docs/plans/2026-10-08-test-guidelines.md)
    # Kept apart from ## Review so an auditor can tell a compliance finding
    # from a preference finding.
    template="$BATS_TEST_DIRNAME/../templates/verification.md"
    review_line=$(grep -n '^## Review$' "$template" | cut -d: -f1)
    guideline_line=$(grep -n '^## Guideline reviews$' "$template" | cut -d: -f1)
    gaps_line=$(grep -n '^## Gaps$' "$template" | cut -d: -f1)
    [ -n "$review_line" ]
    [ -n "$guideline_line" ]
    [ -n "$gaps_line" ]
    [ "$review_line" -lt "$guideline_line" ]
    [ "$guideline_line" -lt "$gaps_line" ]
    section=$(awk '/^## Guideline reviews$/ { inside = 1; next } /^## / { inside = 0 } inside' "$template")
    printf '%s\n' "$section" | grep -qx '### <guidelines file>'
    # `<N>`, not 1: the record-counting test pins the one `### Round 1` and
    # `**finding-1**:` of ## Review.
    printf '%s\n' "$section" | grep -qxF '### Round <N>'
    printf '%s\n' "$section" | grep -qF '**finding-<N>**: guideline, <low | medium | high> — '
    printf '%s\n' "$section" | grep -q '^disposition: '
    flat=$(printf '%s\n' "$section" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$flat" | grep -qF 'guidelines-file.sh TEST'
    printf '%s\n' "$flat" | grep -qF 'kept apart from `## Review` so compliance and preference findings stay distinguishable'
    printf '%s\n' "$flat" | grep -qF 'State no number of rounds, findings or dispositions in prose, as under `## Review`'
}
