# Content lints over the skills, in the spirit of portability.bats's sweep:
# a skill instruction that quietly loses a critical phrase fails here
# rather than in some target project months later.

# The scratch repositories of the tests that run a skill's snippets.
load helpers

# ratchet_step N — prints the text of skills/ratchet/SKILL.md's `### Step N:`
# section on one line, runs of spaces squeezed, so a phrase the prose wraps
# still matches.
ratchet_step() {
    local skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    section_of "$(grep -m 1 "^### Step $1:" "$skill")" "$skill" | tr '\n' ' ' | tr -s ' '
}

@test "ratchet: tool qualification states how and where the suite runs" {
    # verifies: REQ-5cg78a
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
    # verifies: REQ-9p7adb
    # The step-5 item requires capturing the suite's exit code, but a natural
    # way to run it — `run-tests.sh | tee log` — leaves $? set to tee's status,
    # and the recorded pass/fail is then the wrong command's. A reporter
    # nearly recorded a wrong result exactly this way.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'never through a pipe' "$skill"
    grep -q "the wrong command's" "$skill"
}

@test "ratchet: the setup checklist installs GNU parallel for the qualification suite" {
    # verifies: REQ-6bszfj
    checklist="$BATS_TEST_DIRNAME/../skills/ratchet/references/setup-checklist.md"
    grep -q 'GNU `parallel`' "$checklist" || { echo "no GNU parallel item"; false; }
    grep -q 'brew install parallel' "$checklist" || { echo "no macOS install line"; false; }
    grep -q 'apt install parallel' "$checklist" || { echo "no Debian install line"; false; }
}

@test "ratchet: updating the scripts also refreshes the ledger READMEs" {
    # verifies: REQ-87dcq8
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
    # verifies: ADR-3h4dky
    # verifies: ADR-k3nkv3
    # Upgrade became a third mode with no completion check: Done when asked a
    # retrofit for a gap analysis and asked an upgrade for nothing, so
    # "the scripts are copied" could count as done.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    done_when=$(awk '/^## Done when/ { inside = 1; next } /^## / { inside = 0 } inside' "$skill")
    printf '%s\n' "$done_when" | grep -q 'An upgrade copied scripts and grammar files from one guardrails version,'
    printf '%s\n' "$done_when" | grep -q 'fixed each failure, and listed each new warning in the squash message.'
    # A plan is dropped before the gate, so neither the warnings nor a
    # retrofit's gap analysis can live only in one.
    printf '%s\n' "$done_when" | tr '\n' ' ' | tr -s ' ' |
        grep -qF "A retrofit's squash message carries its gap analysis's adoption order" ||
        { echo "Done when does not keep the retrofit's adoption order"; false; }
}

@test "ratchet: upgrade step 4 fixes each failure and lists each new warning in the squash message" {
    # verifies: ADR-3h4dky
    # verifies: ADR-k3nkv3
    # Done when checks that each failure is fixed and each warning listed, so
    # the upgrade procedure has to say so. A failure cannot be listed instead:
    # the upgrade merges through merge-change, whose gate needs check-trace.sh
    # to pass.
    # Only new warnings are listed: the old ones are already in the problem
    # ledger.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    upgrade=$(awk '/^### Upgrading the scripts/ { inside = 1; next } /^##/ { inside = 0 } inside' "$skill")
    printf '%s\n' "$upgrade" | grep -q '^4\. Run `check-trace.sh`; fix each failure, and list each new warning in the$'
    # Step 5 writes the record after upgrade step 4 and retrofit step 3.2, so
    # each says the list goes in once the record exists.
    printf '%s\n' "$upgrade" | grep -q '^   squash message once Step 5 writes it\.' ||
        { echo "upgrade step 4 writes into a record Step 5 has not written"; false; }
    ! grep -q 'or list it in a plan' "$skill" \
        || { echo "SKILL.md still lets a failure be listed instead of fixed"; false; }
    ! grep -q 'each warning' "$skill" \
        || { echo "SKILL.md lists every warning, not only the new ones"; false; }
    tr '\n' ' ' < "$skill" | tr -s ' ' |
        grep -qF 'It is the change'"'"'s plan, dropped before the gate: copy its adoption order into the squash message once Step 5 writes it, as a bulleted list: a numbered line is a malformed finding.' ||
        { echo "retrofit step 2 does not keep the adoption order"; false; }
}

@test "ratchet: upgrade is a mode resting on ADR-3h4dky, and retrofit no longer inventories a re-ratchet" {
    # verifies: ADR-3h4dky
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

@test "ratchet: ADR-3h4dky and the rationale list upgrade warnings and later teeth in the squash message" {
    # verifies: ADR-k3nkv3
    # A plan never reaches the base branch, so neither the new warnings an
    # upgrade leaves nor a retrofit's later teeth can be listed in one; the
    # ADR is rewritten in place, with no amendment note.
    root="$BATS_TEST_DIRNAME/.."
    adr=$(tr '\n' ' ' < "$root/docs/adr/ADR-3h4dky-upgrade-is-its-own-mode.md" | tr -s ' ')
    rationale=$(section_of '## Upgrade is its own mode' "$root/skills/ratchet/references/rationale.md" |
        tr '\n' ' ' | tr -s ' ')
    head -n 1 "$root/docs/adr/ADR-3h4dky-upgrade-is-its-own-mode.md" |
        grep -qF 'each new warning is listed in its squash message.' ||
        { echo "the decision line still lists warnings in a plan"; false; }
    printf '%s\n' "$adr" | grep -qF "each new warning is listed in the upgrade change's squash message" ||
        { echo "the Done when list still names a plan"; false; }
    for text in "$adr" "$rationale"; do
        printf '%s\n' "$text" | grep -qF 'later teeth are listed in the squash message' ||
            { echo "later teeth still in the gap analysis: $text"; false; }
        if printf '%s\n' "$text" | grep -qiE 'listed in a plan|plan listing|plan that lists|amended'; then
            echo "still names a plan for the listing, or an amendment: $text"; false
        fi
    done
}

@test "ratchet: the upgrade order of work has the macOS pass and defines a new warning" {
    # verifies: ADR-3h4dky
    # verifies: ADR-k3nkv3
    # Moved out of SKILL.md's upgrade steps to make room for the Done when
    # entry; the order of work is what upgrade step 1 has the agent follow.
    notes="$BATS_TEST_DIRNAME/../skills/ratchet/references/upgrade-notes.md"
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    order=$(awk '/^## Order of work/ { inside = 1; next } /^## / { inside = 0 } inside' "$notes")
    if printf '%s\n' "$order" | grep -qF -e '--branch' -e 'verification record'; then
        echo "the order of work still reruns check-review over records"; false
    fi
    printf '%s\n' "$order" | grep -q '^6\. Fix each failure, and list each new warning in the squash message;'
    printf '%s\n' "$order" | grep -q 'A warning is a finding printed without'
    printf '%s\n' "$order" | grep -q 'A new warning is one the run in item 2'
    printf '%s\n' "$order" | grep -q 'failing the run: `UNRESOLVED-PR`, `ACCEPTED-PR`, and an `UNMET-EXPECTATION`'
    printf '%s\n' "$order" | grep -q 'keep its output for item 6'
    printf '%s\n' "$order" | grep -q 'an older one is already recorded in its ledger'
    ! grep -q 'If `/ratchet` was ever run on macOS' "$skill" \
        || { echo "SKILL.md still carries the macOS step"; false; }
}

@test "ratchet: the retrofit still advises splitting each monolithic ledger file, and why" {
    # verifies: REQ-4wbudv
    # The advice covers every doc_* key, not srs.md alone, and keeps its
    # reason.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'monolithic `doc_\*` file into a directory as its first dated file' "$skill"
    grep -q 'README, so changes stop conflicting' "$skill"
    grep -q 'Each `doc_\*` key accepts a file or a directory, so `srs.md` keeps' "$skill"
}

@test "ratchet: the qualification basis names a commit, not just a version" {
    # verifies: REQ-tj6xeu
    # "435 tests at 0.5.1" is nominal the moment upstream advances without a
    # version bump; a recorded commit makes the basis checkable. The skill
    # must tell the installer to record it, and the shipped config template
    # must contain the key it is recorded under.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'guardrails_commit' "$skill"
    grep -q 'guardrails_commit' "$BATS_TEST_DIRNAME/../templates/config.yaml"
}

@test "ratchet: step 0 clones the checkout before reading it, and finds it through .guardrails-source" {
    # verifies: REQ-8tt5fw
    # A suite that reads the checkout's live tree mixes two commits when one
    # is made there mid-run, and a copied skill has no checkout two levels
    # above it. Step 0 reads the path install.sh --copy records, then clones.
    step0=$(ratchet_step 0)
    printf '%s\n' "$step0" | grep -qF '.guardrails-source' \
        || { echo "step 0 does not read .guardrails-source"; false; }
    printf '%s\n' "$step0" | grep -qF 'git clone -q <checkout> <guardrails>' \
        || { echo "step 0 does not clone the checkout"; false; }
}

@test "ratchet: step 0 clones into a temporary directory outside the project, removed afterwards" {
    # verifies: REQ-8tt5fw
    # Step 5 runs the suite in the clone, never in the target
    # project. A clone made inside the project's tree would put the suite
    # there, and one left behind is a stray copy of guardrails in it.
    step0=$(ratchet_step 0)
    printf '%s\n' "$step0" | grep -qF 'a temporary directory outside the project' \
        || { echo "step 0 does not say where the clone goes"; false; }
    printf '%s\n' "$step0" | grep -qF 'removed when the ratchet is done' \
        || { echo "step 0 does not say the clone is removed"; false; }
}

@test "ratchet: the qualification log must name the recorded commit" {
    # verifies: REQ-xd8xkm
    # Only the runner's "testing commit" line says the result describes one
    # commit; the skill must have the agent look for it.
    root="$BATS_TEST_DIRNAME/.."
    grep -qF 'run-tests: testing commit' "$root/skills/ratchet/SKILL.md" \
        || { echo "the skill does not name the testing-commit line"; false; }
}

@test "ratchet: a qualification log line describes no commit only when it begins run-tests:" {
    # verifies: REQ-xd8xkm
    # The log also holds the suite's TAP lines, and test names contain
    # "run-tests:" (ok N run-tests: outside a git checkout ...). Read as "any
    # other run-tests: line", every passing log fails the check.
    root="$BATS_TEST_DIRNAME/.."
    step5=$(ratchet_step 5)
    printf '%s\n' "$step5" | grep -qF 'any other line beginning `run-tests:`' \
        || { echo "step 5 does not anchor the line at its start"; false; }
    notes=$(awk '/^## The guardrails checkout is cloned/ { inside = 1; next } /^## / { inside = 0 } inside' \
        "$root/skills/ratchet/references/upgrade-notes.md" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$notes" | grep -qF 'any other line beginning `run-tests:`' \
        || { echo "the upgrade note does not anchor the line at its start"; false; }
}

@test "ratchet: the rationale lists every line the runner says about what it tested" {
    # verifies: REQ-xd8xkm
    # tests/run-tests.sh and tests/fingerprint-tree.sh say these run-tests:
    # lines on standard error (tests/run-tests.bats tests each at its command
    # line); a list missing one is not the runner's, and a reader of the log
    # cannot place it.
    root="$BATS_TEST_DIRNAME/.."
    rationale=$(tr '\n' ' ' < "$root/skills/ratchet/references/rationale.md" | tr -s ' ')
    for line in \
        '`run-tests: testing commit <sha>`' \
        '`run-tests: the working tree differs from commit <sha>; this run tests no commit`' \
        '`run-tests: no git repository found; the commit tested is unknown`' \
        '`run-tests: HEAD names no commit; the commit tested is unknown`' \
        '`run-tests: the commit tested is unknown`' \
        '`run-tests: the working tree changed during the run; this result describes no commit`' \
        '`run-tests: git <args> failed: <message>`' \
        '`rev-parse <sha>^{tree}`'; do
        printf '%s\n' "$rationale" | grep -qF "$line" \
            || { echo "rationale.md does not list $line"; false; }
    done
}

@test "ratchet: the guardrails source is named the checkout or the clone, never the guardrails repo" {
    # verifies: REQ-rck84h
    # Step 0 names the source the checkout and the copy every step reads
    # <guardrails>, the clone. "The guardrails repo" covers both, and a
    # reader can run the suite or copy templates from the checkout.
    root="$BATS_TEST_DIRNAME/.."
    if grep -n 'guardrails repo' "$root/skills/ratchet/SKILL.md"; then
        echo "SKILL.md names the guardrails repo"; false
    fi
    rationale=$(tr '\n' ' ' < "$root/skills/ratchet/references/rationale.md" | tr -s ' ')
    if printf '%s\n' "$rationale" | grep -oE 'suite (runs )?in the guardrails repository'; then
        echo "rationale.md says the suite runs in the guardrails repository"; false
    fi
    # The upgrade copies from <guardrails> as step 2.3 does; a bare
    # scripts/*.sh reads as the project's own scripts/.
    skill=$(tr '\n' ' ' < "$root/skills/ratchet/SKILL.md" | tr -s ' ')
    printf '%s\n' "$skill" | grep -qF 'Then copy, from `<guardrails>`, `scripts/*.sh` → `.guardrails/scripts/`, keeping executable bits, and `templates/*_GUIDELINES.md` → `.guardrails/templates/`.' ||
        { echo "the upgrade's copy step does not name <guardrails> as its source"; false; }
}

@test "ratchet: the suite's exit status is captured in rc, never in zsh's read-only status" {
    # verifies: REQ-9p7adb
    # zsh's status is read-only: status=$? fails, and the suite's real exit
    # status is lost.
    root="$BATS_TEST_DIRNAME/.."
    skill="$root/skills/ratchet/SKILL.md"
    grep -qF 'rc=$?' "$skill" || { echo "the skill does not capture rc"; false; }
    if grep -qF 'status=$?' "$skill"; then echo "the skill still assigns status"; false; fi
    grep -qF 'read-only variable: status' "$root/skills/ratchet/references/rationale.md" \
        || { echo "rationale.md does not say why"; false; }
}

@test "ratchet: step 5 writes the qualification log outside the clone" {
    # verifies: REQ-bwy9nm
    # The runner fingerprints every file git does not ignore. A log written
    # inside <guardrails> (a bare ratchet.log run from the clone) dirties the
    # tree before the run and changes it during the run, so every run fails
    # with "this run tests no commit", and the log goes with the clone.
    root="$BATS_TEST_DIRNAME/.."
    step5=$(ratchet_step 5)
    target=$(printf '%s\n' "$step5" | sed -n 's/.*run-tests\.sh > \([^ `]*\) 2>&1.*/\1/p')
    [ -n "$target" ] || { echo "step 5 has no run-tests.sh > <log> 2>&1 command"; false; }
    [ "$target" != 'ratchet.log' ] || { echo "step 5 writes the log into the current directory"; false; }
    case $target in
        ('<guardrails>'*) echo "step 5 writes the log inside the clone: $target"; false ;;
        ('/'*|'<'*) ;;
        (*) echo "step 5's log path is relative to the current directory: $target"; false ;;
    esac
    printf '%s\n' "$step5" | grep -qF 'Keep the log' \
        || { echo "step 5 does not say the log is kept"; false; }
    grep -qF 'fingerprints every file git does not ignore' "$root/skills/ratchet/references/rationale.md" \
        || { echo "rationale.md does not say why the log goes outside the clone"; false; }
}

@test "ratchet: step 5 does not both run the suite exactly once and run it again" {
    # verifies: REQ-bwy9nm
    # "Run it exactly once" and "run it again" on a run that names no commit
    # contradict each other; one qualifying run per update is the rule.
    step5=$(ratchet_step 5)
    if printf '%s\n' "$step5" | grep -qF 'exactly once'; then echo "step 5 still says exactly once"; false; fi
    printf '%s\n' "$step5" | grep -qF 'one qualifying run per update' \
        || { echo "step 5 does not state one qualifying run per update"; false; }
}

@test "ratchet: the upgrade notes say the checkout is cloned and the suite names its commit" {
    # verifies: REQ-u83j4k
    notes="$BATS_TEST_DIRNAME/../skills/ratchet/references/upgrade-notes.md"
    grep -qx '## The guardrails checkout is cloned, and the suite names its commit' "$notes" \
        || { echo "no upgrade-notes section"; false; }
}

@test "worktree-discipline: the task worktree is nested inside the change worktree" {
    # verifies: REQ-y5uymy
    # A dispatched subagent is pinned to the change worktree's subtree, so a
    # task worktree anywhere else is created and then unusable. The rule is
    # containment; the false-success traps are why that failure would arrive
    # too late to undo.
    skill="$BATS_TEST_DIRNAME/../skills/worktree-discipline/SKILL.md"
    grep -q 'nested inside the change worktree' "$skill"
    grep -q 'pins that subagent to a subtree' "$skill"
    grep -q 'reports success and then rejects' "$skill"
}

@test "develop-change: the dispatch prompt names the nested task worktree path" {
    # verifies: REQ-c6kcjh
    # A subagent cannot discover its pin before it violates it, so the
    # dispatcher states the path instead of leaving the subagent to choose it.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -q '\.worktrees/<change-branch>-t3' "$skill"
}

@test "the repository ignores the nested task-worktree directory" {
    # verifies: REQ-yxcn29
    # worktree-discipline makes the ignore entry the dispatcher's
    # precondition, and an unignored task worktree would dirty
    # verify-before-merge's clean git status.
    grep -qx '\.worktrees/' "$BATS_TEST_DIRNAME/../.gitignore"
}

@test "develop-change: the dispatch prompt forbids the change branch, not the change worktree" {
    # verifies: REQ-c6kcjh
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
    # verifies: REQ-p5hrv9
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
    # verifies: REQ-e2q5g5
    # The containment rule was applied at develop-change's dispatch site only.
    # Step 4 dispatches a reviewer that creates a task worktree of its own,
    # and a reviewer left to choose the location repeats the whole failure —
    # so the path is stated here too. The reviewer has no task number, hence
    # the `-review` tag.
    #
    # Anchored by POSITION, not presence. The literal now appears three times
    # in the file — the dispatch, the removal command, and the prose around it
    # — so a bare `grep -q` for it still passed when the ONE occurrence that
    # states the rule was mutated. The dispatch's occurrence is the first in
    # the file, it is inside step 4, and it comes before the removal command
    # that repeats it; mutate it and the first occurrence becomes the removal
    # line, which is not less than itself.
    #
    # The removal command is `task-worktree.sh remove review`, which takes the
    # tag, so the dispatch is the only occurrence of the path.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    review_at=$(grep -n '^4\. \*\*Independent review\*\*' "$skill" | head -n 1 | cut -d: -f1)
    record_at=$(grep -n '^5\. \*\*Squash message\*\*' "$skill" | head -n 1 | cut -d: -f1)
    path_at=$(grep -n '\.worktrees/<change-branch>-review' "$skill" | head -n 1 | cut -d: -f1)
    # The review worktree is retired with
    # `remove review`, which merges nothing.
    remove_at=$(grep -n 'task-worktree\.sh remove review' \
        "$skill" | head -n 1 | cut -d: -f1)
    [ -n "$review_at" ]
    [ -n "$record_at" ]
    [ -n "$path_at" ]
    [ -n "$remove_at" ]
    [ "$path_at" -gt "$review_at" ]
    [ "$path_at" -lt "$record_at" ]
    [ "$path_at" -lt "$remove_at" ]
}

@test "merge-change: the review worktree is removed at the end of its own dispatch" {
    # verifies: REQ-rstp46
    # The review step ends "the sequence reruns from step 1" when findings
    # come back, so the steps after it are reached only on the last round. The
    # review worktree's path and branch are fixed, so a worktree left by one
    # round makes the next round's dispatch fail with `fatal: a branch named
    # '<change-branch>-review' already exists`. The removal therefore sits
    # where the dispatch ends, inside the review step, as worktree-discipline
    # states of every task worktree. Step 6d keeps the structural check, so a
    # skipped removal is caught before the squash rather than at
    # finish-merge.sh.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    review_at=$(grep -n '^4\. \*\*Independent review\*\*' "$skill" | head -n 1 | cut -d: -f1)
    record_at=$(grep -n '^5\. \*\*Squash message\*\*' "$skill" | head -n 1 | cut -d: -f1)
    # The review worktree is retired with
    # `remove review`, which merges nothing.
    remove_at=$(grep -n 'task-worktree\.sh remove review' \
        "$skill" | head -n 1 | cut -d: -f1)
    [ -n "$review_at" ]
    [ -n "$record_at" ]
    [ -n "$remove_at" ]
    [ "$remove_at" -gt "$review_at" ]
    [ "$remove_at" -lt "$record_at" ]
    # 6d still checks the registry structurally — the removal moved, the check
    # did not.
    d_at=$(grep -n '^6d\. ' "$skill" | head -n 1 | cut -d: -f1)
    s_at=$(grep -n '^7\. \*\*Squash onto the base branch' "$skill" | head -n 1 | cut -d: -f1)
    [ -n "$d_at" ]
    [ -n "$s_at" ]
    # The structural check is a command
    # with a verdict, `finish-merge.sh --check`, rather than a raw
    # `git worktree list` the author reads by eye. What this pin protects is
    # that 6d still checks the registry at all — not which spelling it uses.
    # The 6c pre-flight runs that check as
    # NESTED-WORKTREE, and 6d is where its failure is answered.
    sed -n "${d_at},${s_at}p" "$skill" | grep -q 'NESTED-WORKTREE'
    # worktree-discipline cross-references the removal's home, so it follows it
    # there rather than leaving the two skills to drift.
    wd="$BATS_TEST_DIRNAME/../skills/worktree-discipline/SKILL.md"
    grep -q 'the end of `merge-change` step 4' "$wd"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of its position, not an assertion.)
    run grep -q 'step 6d' "$wd"
    [ "$status" -ne 0 ]
}

@test "merge-change: every fix dispatch names the nested task worktree path" {
    # verifies: REQ-9xhvwd
    # Two dispatch statements in this file name the nested path: the sequence
    # header's fix dispatch, and the review step's dispatch of the fix for a
    # finding. A mutant replacing both with "a task worktree" must fail. Both
    # are pinned, and by position, so replacing either one is not covered by
    # the other.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    count=$(grep -c '\.worktrees/<change-branch>-<tag>' "$skill")
    [ "$count" -eq 2 ]
    one_at=$(grep -n '^1\. \*\*Merge the latest base branch' "$skill" | head -n 1 | cut -d: -f1)
    review_at=$(grep -n '^4\. \*\*Independent review\*\*' "$skill" | head -n 1 | cut -d: -f1)
    record_at=$(grep -n '^5\. \*\*Squash message\*\*' "$skill" | head -n 1 | cut -d: -f1)
    header_at=$(grep -n '\.worktrees/<change-branch>-<tag>' "$skill" | head -n 1 | cut -d: -f1)
    finding_at=$(grep -n '\.worktrees/<change-branch>-<tag>' "$skill" | tail -n 1 | cut -d: -f1)
    [ -n "$one_at" ]
    [ -n "$review_at" ]
    [ -n "$record_at" ]
    [ "$header_at" -lt "$one_at" ]
    [ "$finding_at" -gt "$review_at" ]
    [ "$finding_at" -lt "$record_at" ]
}

@test "merge-change: a review worktree left dirty by scratch has a remedy" {
    # verifies: REQ-2crnq2
    # `git worktree remove` fails on untracked files as well as modified
    # ones, and a reviewer leaves scratch behind — a log, a note. The step
    # identified the state to check and stopped there, which leaves `--force`
    # as the only obvious way out of it, and `--force` is what destroys the
    # thing the guard exists to protect.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    # The removal is `task-worktree.sh remove`.
    grep -q 'rejects untracked files as well as modified ones' "$skill"
    grep -q 'read the scratch, delete it, and run `remove` again' "$skill"
    grep -q 'the remedy step 4 gives' "$skill"
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
    # verifies: REQ-744g4c
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
    # it described; `--check` applies the containment criterion
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
    # verifies: REQ-rstp46
    # The removal was stated unconditionally ("Every round, findings or not"),
    # while the same step documents two paths on which no review worktree ever
    # exists: a human reviewer per team policy, and a class A change skipping
    # the step. Under a sequence headed "Halt on any failure", running
    # `git worktree remove` on a path that was never created is a failure. Step
    # 6d's wording is already conditioned on what this change *created*; step
    # 4's matches it.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    review_at=$(grep -n '^4\. \*\*Independent review\*\*' "$skill" | head -n 1 | cut -d: -f1)
    record_at=$(grep -n '^5\. \*\*Squash message\*\*' "$skill" | head -n 1 | cut -d: -f1)
    [ -n "$review_at" ]
    [ -n "$record_at" ]
    sed -n "${review_at},${record_at}p" "$skill" | grep -q 'every round that created one'
    sed -n "${review_at},${record_at}p" "$skill" | grep -q 'Not every round creates one'
    # The skip names when no review worktree exists, so "skip it there" has an antecedent.
    sed -n "${review_at},${record_at}p" "$skill" | grep -q 'Not every round creates one: a human reviewer uses their checkout'
    # `task-worktree.sh remove` takes a tag.
    sed -n "${review_at},${record_at}p" "$skill" | grep -q 'fails on a tag that was never started'
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of its position, not an assertion.)
    run grep -rq 'Every round, findings or not' "$(dirname "$skill")"
    [ "$status" -ne 0 ]
}

@test "merge-change: a fix dispatch's tag is unique, and AGENTS.md defers on tags" {
    # verifies: REQ-443ewb
    # `.worktrees/<change-branch>-<tag>` leaves the tag unconstrained, so the
    # rule that it must not repeat is worth keeping — but its first
    # justification was false. Two findings rounds that both use the
    # natural `fix` cannot collide at creation: a task worktree and its branch
    # are removed with their dispatch (`worktree-discipline`, step 8), so
    # round 1's `-fix` branch is gone before round 2 dispatches.
    # That is the same property step 4 rests on when it keeps the review tag
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
    # `task-worktree.sh merge` does both after a
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
    # verifies: REQ-y5uymy
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
    # verifies: REQ-pqymt7
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

# sh_fence — prints the body of the first ```sh fence on standard input,
# without the three-space indent a fence inside a numbered step carries.
sh_fence() {
    awk '
        /^ *```sh$/ { fenced = 1; next }
        fenced && /^ *```$/ { exit }
        fenced { sub(/^   /, ""); print }
    '
}

@test "worktree-discipline: a change opens after checking the worktrees and the claimed items" {
    # verifies: REQ-h76m4z, REQ-wn6kjg
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
    # The snippet, not the file: the prose below it quotes the same command.
    gr_last_sh_fence "$reference" '## (b) ' | grep -qF 'git diff "$BASE...$branch"'
    tr '\n' ' ' < "$reference" | grep -q 'plain `git grep`'
    # The claim check cannot see an uncommitted claim; the doc ties that to
    # the dirty count (a) prints.
    tr '\n' ' ' < "$reference" | tr -s ' ' | grep -q 'The check reads committed history only'
    tr '\n' ' ' < "$reference" | tr -s ' ' | grep -q 'with a dirty count above 0 may hold one'
}

@test "worktree-discipline: the before-opening snippets run, and the claim check reads the diff" {
    # verifies: REQ-h76m4z, REQ-wn6kjg
    # The two snippets in before-opening.md are run, not only grepped.
    # A scratch repository has a branch that claims an
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
    # A branch whose own commit removes the ID line, as a change resolving
    # the item does: its diff shows the line only as removed. Made in the
    # main checkout, so (a) lists no worktree for it.
    git checkout -q -b remover
    printf '# the item line is gone\n' > ledger.md
    git commit -qam 'resolve PR-abc123 by deleting it'
    git checkout -q main
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
    # documents.
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
    # check under sh. Each check runs as pasted
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
    # that resolved the item, deleting it, merged. A two-dot
    # `"$BASE..$branch"` diff shows the deleted line as added on every older
    # branch and reports each as a claim; the three-dot diff starts where the
    # branch left the base.
    sed -i.bak '/PR-abc123/d' ledger.md && rm ledger.md.bak
    git commit -qam 'another change resolves PR-abc123 by deleting it'

    # One line per claiming branch: the claimer adds a line naming the ID,
    # the remover removes one; the neighbour branch, whose diff carries the
    # ID line only as context, is not reported.
    # Run as pasted, with two IDs: under zsh an unsplit list matched nothing,
    # and the check printed nothing, the answer for an unclaimed item.
    for shell in $shells; do
        run "$shell" -c "BASE=main; $(cat "$scratch/claims.pasted")"
        [ "$status" -eq 0 ]
        [ "$output" = 'CLAIMED  PR-abc123  by claimer
CLAIMED  PR-abc123  by remover' ] || { echo "(b) under $shell: $output"; false; }
    done

    # Base detection failed, and the block was pasted whole: with BASE empty,
    # (a) printed `ahead 0` for every worktree, which reads as valid data, and
    # (b) printed no CLAIMED line, the answer for an unclaimed item. Each check
    # stops first and names the cause.
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
    # verifies: REQ-yxcn29
    # This change added `.worktrees/` while the base branch added the same
    # line independently, and the base merge kept both. A duplicate makes the
    # preceding test vacuous: delete either line and it still passes.
    count=$(grep -cx '\.worktrees/' "$BATS_TEST_DIRNAME/../.gitignore")
    [ "$count" -eq 1 ]
}

@test "merge-change: the sequence removes the review worktree before the squash" {
    # verifies: REQ-rstp46
    # The review step dispatches every reviewer into a worktree nested inside
    # the change worktree, and finish-merge.sh guard 4 will not remove a change
    # worktree that has a worktree registered inside it. Without a removal in
    # the sequence, the documented happy path of every change would reach
    # step 7 and be rejected. The removal must come
    # before the squash is staged, so the ordering is asserted and not merely
    # the presence of the command.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    # The review worktree is retired with
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
    # There is one task worktree location, and the dispatcher names it.
    grep -q 'the one the dispatcher named' "$wd"
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of its position, not an assertion.)
    run grep -q 'rather than rebuilding it' "$wd"
    [ "$status" -ne 0 ]
}

@test "merge-change: step 8 maps guard 4's rejection to a remedy" {
    # verifies: REQ-63smcs
    # verifies: ADR-k3nkv3
    # Step 7 counts the guards finish-merge.sh proves and step 8's table is the
    # one place that maps a rejection to a remedy. Guard 4 was added without
    # either being updated, leaving the rejection an operator is now most likely
    # to meet unexplained in both. The row quotes what the script prints.
    # Guard 5 checks the signed message (ADR-k3nkv3): its rows quote the
    # refusal, every finding code, and the amend that keeps the tree.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    rejections="$(dirname "$skill")/references/cleanup-rejections.md"
    grep -q 'proves five things' "$skill"
    grep -q 'a registered worktree lies inside' "$rejections"
    grep -qF "HEAD's message does not pass the squash message check" "$rejections" \
        || { echo "no row quotes guard 5's refusal"; false; }
    for code in MISSING-RECORD INCOMPLETE-RECORD UNDISPOSED-FINDING \
            MALFORMED-FINDING FAILED-TESTS MALFORMED-MUTATION \
            'BASE (want one Base: trailer, found' \
            'TESTS (want <n> Tests: trailers, one per verify_commands entry, found' \
            'COVERAGE (want <n> Coverage: trailers, one per coverage_command, found' \
            'GATE-TREE (want one Gate-tree: <tree>, found'; do
        grep -qF "$code" "$rejections" || { echo "no row names $code"; false; }
    done
    grep -qF "git -c core.commentChar='#' commit --amend -S --cleanup=strip -F <message file>" "$rejections" \
        || { echo "the amend does not strip the template's guidance"; false; }
    grep -qF "the squash message check could not run on HEAD's message" "$rejections" \
        || { echo "no exit-2 row for the checker"; false; }
    run grep -qF -e '%(trailers' -e '/tmp/merge-' "$rejections"
    [ "$status" -ne 0 ] || { echo "a row still names the old message form"; false; }
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command, so a bare `! grep` anywhere but the test's final line
    # passes on whatever it found. (As the final command its status does become
    # the test's — but that is a property of its position, not an assertion.)
    run grep -rq -e 'proves three things' -e 'proves four things' "$(dirname "$skill")"
    [ "$status" -ne 0 ]
}

@test "merge-change: step 8 reports without re-verifying the signature" {
    # verifies: REQ-bc52mm
    # Guard 1 of finish-merge.sh verifies the signature under --strict in the
    # user's shell before it removes anything. Step 8 re-ran the same check
    # from the agent's shell, where a read-only ~/.gnupg reads a good
    # signature as N. On success step 8 now reports from the message file;
    # it investigates only a reported problem or a non-zero exit.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    step8=$(awk '/^8\. \*\*/ { inside = 1 } /^## / { inside = 0 } inside' "$skill")
    [ -n "$step8" ]
    printf '%s\n' "$step8" | grep -q 'closing line from the message: branch and IDs'
    printf '%s\n' "$step8" | grep -q 'Run no git command: `finish-merge.sh` verified the signature'
    # What the message
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
    # verifies: REQ-2jkzcr
    # Step 8 no longer checks, so the user is the one who notices a guard's
    # rejection. Step 7 names the success output, and that output is what
    # finish-merge.sh prints at exit 0: three lines prefixed `finish-merge:`.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    script="$BATS_TEST_DIRNAME/../scripts/finish-merge.sh"
    step7=$(step_of "$skill" 7)
    [ -n "$step7" ]
    printf '%s\n' "$step7" | tr '\n' ' ' | grep -q 'Success ends with three *`finish-merge:` lines'
    printf '%s\n' "$step7" | tr '\n' ' ' | grep -q 'otherwise, they paste the output'
    [ "$(grep -c '^echo "finish-merge: ' "$script")" -eq 3 ]
}

@test "merge-change: Done when names finish-merge.sh as the verifier" {
    # verifies: REQ-bc52mm
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    done_when=$(awk '/^## Done when/ { inside = 1; next } /^## / { inside = 0 } inside' "$skill")
    printf '%s\n' "$done_when" | grep -q 'verified by `finish-merge.sh`'
    run grep -q 'check-signing' <<< "$done_when"
    [ "$status" -ne 0 ]
}

@test "verify-before-merge: the fix dispatch names the nested task worktree path" {
    # verifies: REQ-9xhvwd
    # Three skills dispatch a fix into a task worktree of its own, and this is
    # the third site. Its path text was normative and unasserted: deleting it
    # left the suite green. Written as a characterization pin — green when
    # added, red the moment the phrase goes.
    skill="$BATS_TEST_DIRNAME/../skills/verify-before-merge/SKILL.md"
    grep -q '\.worktrees/<change-branch>-<tag>' "$skill"
    grep -q 'nested inside the change worktree' "$skill"
}

@test "ratchet: both worktree directories are gitignored, and why each is" {
    # verifies: REQ-2gkx3b
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
    # verifies: REQ-tzbg6w
    # This repository develops under its own rules, so non-negotiable 1 is
    # where an agent reads the containment rule first.
    agents="$BATS_TEST_DIRNAME/../AGENTS.md"
    grep -q 'nested inside the change worktree' "$agents"
    grep -q '\.worktrees/<change-branch>-t<N>' "$agents"
    grep -q 'names that path in the dispatch prompt' "$agents"
    grep -q "pinned to the change worktree's subtree" "$agents"
    # Both path forms are spelled out, because "a dispatch without one taking a
    # tag instead" parses as substituting the tag inside `-t<N>` — giving
    # `.worktrees/<change-branch>-treview`, not the `-review` that
    # `merge-change` step 4 names and that every review worktree here has
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
    # verifies: ADR-y8jmes
    agents="$BATS_TEST_DIRNAME/../AGENTS.md"
    adr="$BATS_TEST_DIRNAME/../docs/adr/ADR-y8jmes-local-main-is-the-base.md"
    grep -q 'Never consult `origin`' "$agents"
    grep -q 'docs/adr/ADR-y8jmes-local-main-is-the-base.md' "$agents"
    grep -q 'GR_ID_ANY' "$adr"
    run grep -q 'GR_ID_ANY' "$agents"
    [ "$status" -ne 0 ]
}

@test "AGENTS.md: changes may run in parallel; the non-negotiables run 1 to 4" {
    # verifies: REQ-zy25dp
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
    # state the new one.
    run grep -n -e 'Bring a change to its signed squash before' \
        -e 'before opening the next' "$agents"
    [ "$status" -ne 0 ]
    tr '\n' ' ' < "$root/README.md" | tr -s ' ' |
        grep -q 'Changes may run in parallel, each in its own change worktree'
}

@test "problem grammar prose: no shipped file still contains owner:" {
    # verifies: REQ-tbppw8
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
    # verifies: REQ-99p7nx
    # Without this question a twelve-package repository gets a root config and
    # every gate silently reads one unit's facts as the whole tree's.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'one system in many packages, or many systems' "$skill"
    grep -q 'a single-unit project gets no manifest' "$skill"
}

@test "ratchet-units-interview-writes-facts-not-rules: the skill states the interview declares the facts and the rules are not configurable" {
    # verifies: REQ-van2eh
    # The interview writes units:, not_a_unit:, depends_on:, segregated_from:,
    # safety_class — and must STATE it does not ask about the rules, or the next
    # editor adds the enforcement knob the skill rejects by name.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'declares the facts; the rules are not configurable' "$skill"
    grep -q 'not_a_unit:' "$skill"
    grep -q 'segregated_from:' "$skill"
    grep -q 'whether the class floor applies' "$skill"
}

@test "ratchet-manifest-repo-has-no-root-config: scaffold branches on the manifest" {
    # verifies: REQ-n7s9em
    # Copying templates/config.yaml to the root of a manifest repository is
    # exit 2 at the next gate — the scaffold step must state which file goes
    # where in each mode, or ratchet scaffolds a rejected shape.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'templates/units.yaml' "$skill"
    grep -q 'no root .guardrails/config.yaml' "$skill"
    grep -q '<unit>/.guardrails/config.yaml' "$skill"
}

@test "ratchet-tooth-one-is-manifest-and-disclaimers: adoption order is stated" {
    # verifies: REQ-gt4xn2
    # Without the ordering, adoption on a large repo reads as all-or-nothing
    # and the honest first tooth (manifest + disclaimers, no edges) is missed.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'Adopt in order, one step at a time' "$skill"
    grep -q 'empty `depends_on:` is a freestanding guardrails project' "$skill"
}

@test "ratchet-per-unit-class-interview: step 4 repeats per unit" {
    # verifies: REQ-5rv47z
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'repeat this interview per unit' "$skill"
    grep -q "record each class in that unit's config" "$skill"
}

@test "merge-consumes-impact-mechanically: the skill names the mode and forbids hand-picking" {
    # verifies: REQ-7779tj
    # The composed-chain obligations test the chain THROUGH this mode; a
    # hand-judged unit list is the false green the mode exists to prevent.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/references/multi-unit.md"
    grep -q 'check-units.sh --impact' "$skill"
    grep -q 'never hand-pick the unit list' "$skill"
    grep -q 'maps a change under the root `.guardrails/` to every unit' "$skill"
}

@test "merge-runs-impact-set-gates: per-unit runs are spelled out" {
    # verifies: REQ-jnj999
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/references/multi-unit.md"
    grep -q 'GR_CONFIG=<unit>/.guardrails/config.yaml' "$skill"
    grep -q 'every unit in the impact set' "$skill"
    grep -q 'check-units.sh` with no flag' "$skill"
}

@test "merge-record-names-units: the squash message contains the impact set" {
    # verifies: REQ-qg3r38
    # verifies: ADR-k3nkv3
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/references/multi-unit.md"
    grep -q "the message's body also names the units touched and the impact" "$skill"
    grep -q 'One branch, one squash, one message' "$skill"
    grep -qF 'Tests: <unit>: <verify_commands entry> <passed>/<total>' "$skill"
}

@test "grill-dependency-assessment-interview: the provider's artefacts are consulted by name" {
    # verifies: REQ-myh9b3
    skill="$BATS_TEST_DIRNAME/../skills/grill-requirements/SKILL.md"
    grep -q 'check-units.sh --exports' "$skill"
    grep -q 'does its risk analysis consider this use' "$skill"
    grep -q 'open problem reports' "$skill"
    grep -q 'transitively its SOUP' "$skill"
}

@test "grill-gap-becomes-expectation: expects: grammar with the met condition" {
    # verifies: REQ-z3y539
    skill="$BATS_TEST_DIRNAME/../skills/grill-requirements/SKILL.md"
    grep -q 'expects: <unit>' "$skill"
    grep -q 'UNMET-EXPECTATION' "$skill"
    grep -q 'exported REQ with `satisfies:' "$skill"
    grep -q 'opened: YYYY-MM-DD' "$skill"
    grep -q 'INCOMPLETE-EXPECTATION' "$skill"
}

@test "grill-glossary-escalates-interface-terms: unit default, root escalation, conflict rule" {
    # verifies: REQ-acq9rz
    skill="$BATS_TEST_DIRNAME/../skills/grill-requirements/SKILL.md"
    grep -q 'the root glossary owns interface terms' "$skill"
    grep -q 'the moment it appears in an exported REQ or an `expects:` item' "$skill"
    grep -q 'Two units disagreeing internally is not a conflict' "$skill"
}

@test "design-depends-on-is-a-decision: the design skill routes the edge through the assessment" {
    # verifies: REQ-dw2uv8
    skill="$BATS_TEST_DIRNAME/../skills/design-architecture/SKILL.md"
    grep -q 'Declaring a dependency' "$skill"
    grep -q 'an unassessed supplier' "$skill"
}

@test "design-segregation-cites-a-control: segregated_from: names its mechanism" {
    # verifies: ADR-tr72dr
    skill="$BATS_TEST_DIRNAME/../skills/design-architecture/SKILL.md"
    grep -q 'segregated_from:' "$skill"
    grep -q 'INCOMPLETE-SEGREGATION' "$skill"
    grep -q 'MISCLASSED-DEPENDENCY' "$skill"
}

@test "assesses-is-the-remedy: every place that tells an author how to assess names the annotation" {
    # verifies: REQ-vs8xr4
    root="$BATS_TEST_DIRNAME/.."
    grep -q 'assesses:' "$root/skills/analyze-risks/SKILL.md"
    grep -q 'assesses:' "$root/skills/grill-requirements/SKILL.md"
    grep -q 'assesses:' "$root/templates/rmf.md"
    grep -q 'assesses:' "$root/templates/srs.md"
    grep -q 'assesses:' "$root/templates/sad.md"
    grep -q 'assesses:' "$root/templates/AGENTS-block.md"
    ! grep -q 'RMF never mentions' "$root/skills/analyze-risks/SKILL.md" \
        || { echo "analyze-risks still says: RMF never mentions"; false; }
    ! grep -q 'the RMF must mention it' "$root/skills/grill-requirements/SKILL.md" \
        || { echo "grill-requirements still says: the RMF must mention it"; false; }
}

@test "upgrade-notes-announce-the-hard-cut: ratchet states derived assessments go red at upgrade" {
    # verifies: REQ-44vq67
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'Derived assessments are now declared' "$skill"
    grep -q 'DANGLING-FILE' "$skill"
}

@test "code guidelines: the naming rules left the managed block for the code guidelines template" {
    # verifies: REQ-96x6xg
    # Naming is a preference no standard or gate needs, so its rules are the
    # Names clauses of the shipped code guidelines, which a project tailors;
    # a rule with two homes drifts. Neither file states a past-participle
    # rule: the Names clauses are the whole of the naming rules.
    # code-guidelines.bats pins the clauses and sweeps for ## Code: names.
    root="$BATS_TEST_DIRNAME/.."
    block="$root/templates/AGENTS-block.md"
    template="$root/templates/CODE_GUIDELINES.md"
    # A missing file makes grep exit 2, which the negative checks below read
    # as "no match", so each file's existence is asserted first.
    [ -f "$block" ] || { echo "templates/AGENTS-block.md is missing"; false; }
    [ -f "$template" ] || { echo "templates/CODE_GUIDELINES.md is missing"; false; }
    if grep -q 'single-character' "$block"; then echo "the block still states the naming rules"; false; fi
    if grep -qE 'past participle|write_timestamp' "$block" "$template"; then
        echo "the past-participle rule is back"; false
    fi
}

@test "code guidelines: this repository's naming rules live in its own code guidelines file" {
    # verifies: REQ-96x6xg
    # AGENTS.md is guardrails' own copy of the rules it ships, and the naming
    # rules it ships are code guidelines clauses, so this repository's code
    # guidelines file carries them. Neither the block nor AGENTS.md has a
    # prose section: no rule it would hold is shipped. code-guidelines.bats
    # pins the file's clauses and sweeps for ## Code: names.
    root="$BATS_TEST_DIRNAME/.."
    agents="$root/AGENTS.md"
    block="$root/templates/AGENTS-block.md"
    ! grep -q '^## Writing: prose, names and messages$' "$agents" \
        || { echo "AGENTS.md still contains the prose section"; false; }
    ! grep -q '^## Writing: prose, names and messages$' "$block" \
        || { echo "the block still contains the prose section"; false; }
    code_guidelines="$root/docs/CODE_GUIDELINES.md"
    [ -f "$code_guidelines" ] || { echo "docs/CODE_GUIDELINES.md is missing"; false; }
    grep -q '^## Names$' "$code_guidelines" \
        || { echo "docs/CODE_GUIDELINES.md has no Names section"; false; }
    [ -f "$agents" ] || { echo "AGENTS.md is missing"; false; }
    if grep -q '^## Code: names$' "$agents"; then
        echo "AGENTS.md has a Code: names section again: the naming rules have two homes"; false
    fi
}

@test "develop-change: one conformance review per guidelines file replaces the old whole-diff pass" {
    # verifies: REQ-atch44
    # Three dots, pinned literally. `main...<branch>` is the diff since the two
    # diverged — what this change did — while `main..<branch>` also reports
    # whatever the base branch gained meanwhile, which is not this change's
    # to review. A two-dot range grows as main advances and the reviews end up
    # reviewing other people's commits.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    section=$(section_of '### The conformance reviews' "$skill" | tr '\n' ' ' | tr -s ' ')
    [ -n "$section" ] || { echo "no conformance reviews section"; false; }
    printf '%s\n' "$section" | grep -qF 'sh .guardrails/scripts/guidelines-file.sh TEST \ $(git diff --name-only main...<change-branch>)'
    printf '%s\n' "$section" | grep -qF 'sh .guardrails/scripts/guidelines-file.sh CODE \ $(git diff --name-only main...<change-branch>)'
    printf '%s\n' "$section" | grep -qF 'dispatch one subagent under the `review-conformance` skill, all at once'
    if grep -qF '### The refactor pass' "$skill"; then echo "develop-change still has a refactor pass"; false; fi
}

@test "develop-change: the conformance reviews run for ARCHITECTURE too" {
    # verifies: REQ-atch44
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    section=$(section_of '### The conformance reviews' "$skill" | tr '\n' ' ' | tr -s ' ')
    [ -n "$section" ] || { echo "no conformance reviews section"; false; }
    printf '%s\n' "$section" | grep -qF 'sh .guardrails/scripts/guidelines-file.sh ARCHITECTURE \ $(git diff --name-only main...<change-branch>)' \
        || { echo "no ARCHITECTURE guidelines-file line"; false; }
    printf '%s\n' "$section" | grep -qF '`develop-refactor` for a `CODE` or `ARCHITECTURE` file'"'"'s findings' \
        || { echo "ARCHITECTURE findings not sent to develop-refactor"; false; }
    done_when=$(section_of '## Done when' "$skill" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$done_when" | grep -qF 'Each conformance review, for `TEST`, `CODE` and `ARCHITECTURE`, ran' \
        || { echo "Done when does not name the ARCHITECTURE review"; false; }
}

@test "worktree-discipline: a task subagent runs develop-tdd's selection, not verify_commands" {
    # verifies: REQ-ghqnw5
    skill="$BATS_TEST_DIRNAME/../skills/worktree-discipline/SKILL.md"
    step=$(step_of "$skill" 1 | tr '\n' ' ' | tr -s ' ')
    [ -n "$step" ] || { echo "no step 1"; false; }
    if printf '%s\n' "$step" | grep -qF "run the project's \`verify_commands\`"; then
        echo "step 1 sends a task subagent to verify_commands"; false
    fi
    printf '%s\n' "$step" | grep -qF '`develop-tdd` step 4' \
        || { echo "step 1 does not name develop-tdd step 4"; false; }
    # A develop-refactor fix dispatch also runs under step 1; its selection
    # is develop-refactor step 3.
    printf '%s\n' "$step" | grep -qF '`develop-refactor` step 3' \
        || { echo "step 1 does not name develop-refactor step 3"; false; }
    # The whole-suite baseline when a change worktree opens stays.
    baseline=$(step_of "$skill" 4 | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$baseline" | grep -qF "run the project's \`verify_commands\`" \
        || { echo "step 4 lost the baseline run"; false; }
}

@test "develop-change: the dispatcher claims no whole-suite run before the gate" {
    # verifies: REQ-r9qnm3
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    flat=$(tr '\n' ' ' < "$skill" | tr -s ' ')
    if printf '%s\n' "$flat" | grep -qF 'and the suite is green'; then
        echo "the conformance reviews wait on a whole-suite run"; false
    fi
    done_when=$(section_of '## Done when' "$skill" | tr '\n' ' ' | tr -s ' ')
    [ -n "$done_when" ] || { echo "no Done when section"; false; }
    if printf '%s\n' "$done_when" | grep -qF 'The suite is green'; then
        echo "Done when claims a whole-suite run"; false
    fi
}

@test "develop-change: an architecture finding that needs a design change is a stop" {
    # verifies: REQ-37phvm
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    # The heading names more than one stop; an architecture finding is one.
    derail=$(section_of '### Derailment and the other stops' "$skill" | tr '\n' ' ' | tr -s ' ')
    [ -n "$derail" ] || { echo "no derailment section"; false; }
    printf '%s\n' "$derail" | grep -qF 'an architecture finding `develop-refactor` returns as needing a design change' \
        || { echo "no architecture-finding stop"; false; }
    printf '%s\n' "$derail" | grep -qF '`design-architecture`' \
        || { echo "the stop does not name design-architecture"; false; }
    printf '%s\n' "$derail" | grep -qF "the alternatives are the user's" \
        || { echo "the stop does not leave the alternatives to the user"; false; }
}

@test "design-architecture: reads the architecture guidelines file, and a departure names its clause" {
    # verifies: REQ-7udzw8
    skill="$BATS_TEST_DIRNAME/../skills/design-architecture/SKILL.md"
    steps=$(section_of '## Steps' "$skill" | tr '\n' ' ' | tr -s ' ')
    [ -n "$steps" ] || { echo "no Steps section"; false; }
    printf '%s\n' "$steps" | grep -qF 'the architecture guidelines file `guidelines-file.sh ARCHITECTURE` prints for the paths the design touches, and no other guidelines file' \
        || { echo "step 1 does not read the architecture guidelines file"; false; }
    printf '%s\n' "$steps" | grep -qF 'A proposal that departs from a clause of that file names the clause, and the user decides.' \
        || { echo "a departure does not name its clause"; false; }
}

@test "design-architecture: an architecture finding stands in for the requirements, not for reading the config" {
    # verifies: REQ-y84pxw
    skill="$BATS_TEST_DIRNAME/../skills/design-architecture/SKILL.md"
    pre=$(section_of '## Preconditions' "$skill" | tr '\n' ' ' | tr -s ' ')
    [ -n "$pre" ] || { echo "no Preconditions section"; false; }
    printf '%s\n' "$pre" | grep -qF 'The requirements this design serves exist in the SRS, or `develop-change` sent you an architecture finding that needs a design change. If neither, run `grill-requirements` first.' \
        || { echo "the architecture finding is not the alternative to the requirements: $pre"; false; }
    if printf '%s\n' "$pre" | grep -qF -- '- Or `develop-change`'; then
        echo "the architecture finding is still a bullet of its own after the config bullet"; false
    fi
}

@test "design-architecture: one responsibility per item lives in the guidelines template" {
    # verifies: REQ-z4a8dg
    skill="$BATS_TEST_DIRNAME/../skills/design-architecture/SKILL.md"
    template="$BATS_TEST_DIRNAME/../templates/ARCHITECTURE_GUIDELINES.md"
    step2=$(section_of '## Steps' "$skill" | awk '/^2\. / { inside = 1 } /^3\. / { inside = 0 } inside' | tr '\n' ' ' | tr -s ' ')
    [ -n "$step2" ] || { echo "no step 2"; false; }
    if printf '%s\n' "$step2" | grep -qF 'one responsibility'; then
        echo "step 2 still states one responsibility; the rule lives in the guidelines template"; false
    fi
    grep -qF '**One responsibility per item.**' "$template" \
        || { echo "the template has no one-responsibility clause"; false; }
}

@test "merge-change: the review checklist asks for the ARCHITECTURE reviews" {
    # verifies: REQ-buf8y3
    checklist="$BATS_TEST_DIRNAME/../skills/merge-change/references/review-checklist.md"
    tr '\n' ' ' < "$checklist" | tr -s ' ' | grep -qF 'guidelines-file.sh ARCHITECTURE' \
        || { echo "the checklist does not ask for the ARCHITECTURE reviews"; false; }
}

@test "README: tailor-guidelines names the architecture guidelines file" {
    # verifies: REQ-wdx9kz
    grep -qF 'ARCHITECTURE_GUIDELINES.md' "$BATS_TEST_DIRNAME/../README.md" \
        || { echo "README does not name ARCHITECTURE_GUIDELINES.md"; false; }
}

@test "clanker: the conformance reviews are not deferred to the merge review" {
    # verifies: REQ-br59wv
    # merge-change reruns from step 1 on any finding, so a naming nit raised
    # at step 4 costs a full merge-sequence restart. The skill has to state why the
    # conformance reviews run here, or a later editor moves them to the review
    # that already reads the whole diff.
    #
    # Anchored on the bold markers, not the bare phrase: the same words appear
    # in the dispatch-report section, split across a line break, so a bare
    # 'reruns from step 1' is unique only by accident of wrapping. Reflow that
    # paragraph and the bare form would match it while this passage was gone.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -qF '**reruns from step 1**' "$skill"
    # The reviews run before merge-change, not at its step 4: with only the
    # reason pinned, the section could move them to step 4 and still pass.
    section=$(section_of '### The conformance reviews' "$skill" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$section" | grep -qF 'These reviews run here, before `merge-change`, not at its step 4'
}

@test "develop-change: a conformance reviewer changes nothing and gets no task worktree" {
    # verifies: REQ-65z467
    # Every other dispatch names a nested task worktree, so a reviewer given
    # no location follows that pattern and creates one. The prompt line and
    # the paragraph that states why are both pinned.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    tr '\n' ' ' < "$skill" | tr -s ' ' | grep -qF 'Read the change worktree at <path>; do not create a task worktree, edit, or commit.'
    grep -qF '**A reviewer changes nothing and gets no task worktree.**' "$skill"
}

@test "clanker: develop-change tells a stuck task to change approach" {
    # verifies: REQ-fdx45r
    # The derailment rule re-dispatches on the first failure. Without this,
    # the re-dispatch repeats the approach that already failed.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -q 'change the approach' "$skill"
}

@test "develop-change: a conformance finding that recurs after its fix stops the loop; a new one does not" {
    # verifies: REQ-5u9fc6
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    # The heading names more than one stop; an architecture finding is one.
    derail=$(section_of '### Derailment and the other stops' "$skill" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$derail" | grep -qF 'a conformance review reports a finding again after the fix dispatched for it was merged'
    printf '%s\n' "$derail" | grep -qF 'A conformance round with new findings is the loop working, not a repeat'
    # A place is what the earlier finding cited.
    printf '%s\n' "$derail" | grep -qF 'A place is the file and lines the earlier finding cited; the same clause at another site is a new finding, not a recurrence.'
    # Only a finding above low counts toward the third stop.
    printf '%s\n' "$derail" | grep -qF 'Only a finding above low counts: a round with nothing above low is the last, whatever recurs in it.'
    # The remedy names a recurring finding's choices.
    printf '%s\n' "$derail" | grep -qF 'for a recurring conformance finding, accept the finding, or rule against the guideline clause.'
    # The loop's own section is where a dispatcher reads when to stop it, so
    # it must point at the stop as well as the derailment list stating it.
    section=$(section_of '### The conformance reviews' "$skill" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$section" | grep -qF 'stops at the first finding that recurs (Derailment)'
    # The recurrence is the only stop, so no round cap.
    printf '%s\n' "$section" | grep -qF 'No round count bounds the loop'
}

@test "verify-before-merge: check 8 asks that each conformance review ran and was dispositioned" {
    # verifies: REQ-j78a6z
    # In a suite where every other step is mechanically checked, an
    # unenforced step is the one that stops running. The enforcement is
    # cheap: an existing gate with one more check in it.
    skill="$BATS_TEST_DIRNAME/../skills/verify-before-merge/SKILL.md"
    rationale="$BATS_TEST_DIRNAME/../skills/verify-before-merge/references/rationale.md"
    flat=$(tr '\n' ' ' < "$skill" | tr -s ' ')
    printf '%s\n' "$flat" | grep -qF '8. **Each conformance review ran** and the dispatcher fixed or dispositioned every finding (`develop-change`).'
    grep -qF 'a diff a conformance review checked' "$rationale"
}

@test "verify-before-merge: check 6 cites the robustness rule where develop-tdd states it" {
    # verifies: REQ-myp987
    skill="$BATS_TEST_DIRNAME/../skills/verify-before-merge/SKILL.md"
    tr '\n' ' ' < "$skill" | tr -s ' ' | grep -qF "per \`develop-tdd\`'s robustness rule"
}

@test "clanker: a bug caused by the design escalates to design-architecture" {
    # verifies: REQ-ef8y3r
    # The escalation list already covers a missing requirement, a missed
    # hazard and a wrong spec. A bug that is a consequence of the
    # architecture had nowhere to go, so it was fixed where it surfaced and
    # the class of bug stayed open.
    skill="$BATS_TEST_DIRNAME/../skills/resolve-problem/SKILL.md"
    grep -q 'consequence of the design' "$skill"
    grep -q 'design-architecture' "$skill"
}

@test "ratchet: the retrofit inventory no longer looks for a ## Code: names section" {
    # verifies: REQ-96x6xg
    # The managed block has no ## Code: names section, so a block without one
    # is no gap for the retrofit inventory to report.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    [ -f "$skill" ] || { echo "missing: $skill"; false; }
    if grep -qF 'Code: names' "$skill"; then echo "ratchet still names ## Code: names"; false; fi
}

@test "develop-change: a CODE finding is fixed under develop-refactor, a TEST finding under develop-tdd" {
    # verifies: REQ-hd4gfj
    # The agent that fixes does not review its fix, and the naming rules are
    # the code guidelines file's, not AGENTS.md's.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    section=$(section_of '### The conformance reviews' "$skill" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$section" | grep -qF 'Once every review has reported, dispatch the fixes'
    printf '%s\n' "$section" | grep -qF '`develop-refactor` for a `CODE` or `ARCHITECTURE` file'"'"'s findings and `develop-tdd` for a `TEST` file'"'"'s'
    printf '%s\n' "$section" | grep -qF 'under the develop-refactor skill (develop-tdd for a TEST file)'
    printf '%s\n' "$section" | grep -qF 'The agent that fixes a finding never reviews it.'
    printf '%s\n' "$section" | grep -qF 'the first round with nothing above low is the last'
    if grep -qF 'the code rules in AGENTS.md' "$skill"; then echo "develop-change still names the code rules in AGENTS.md"; false; fi
    if grep -q 'writing and naming rules' "$skill"; then echo "develop-change still names: writing and naming rules"; false; fi
}

@test "merge-change: the message states the ledger delta, not the open count" {
    # verifies: REQ-t3jwwv
    # verifies: ADR-k3nkv3
    # The squash message states what this change resolves or opens, not
    # "open PR warnings": an open count is a census of the whole ledger at
    # one instant, in a per-change artifact read long afterwards, and a pinned
    # number goes stale with the next merge.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    step_of "$skill" 5 | tr '\n' ' ' | tr -s ' ' | grep -qF '`Resolves:` and `Opens:` (omit an empty one)' \
        || { echo "step 5 does not write the delta trailers"; false; }
    ! grep -rq 'open PR warnings' "$(dirname "$skill")" \
        || { echo "merge-change still says: open PR warnings"; false; }
}

@test "merge-change: the message template states the Resolves and Opens trailers" {
    # verifies: REQ-t3jwwv
    # verifies: ADR-k3nkv3
    # Deltas are checkable against the diff forever. The trailers are in the
    # template step 5 copies, not in a block the skill restates.
    template="$BATS_TEST_DIRNAME/../templates/squash-message.txt"
    grep -qx 'Resolves: <PR IDs>' "$template"
    grep -qx 'Opens: <PR IDs>' "$template"
    run grep -qF 'Resolves: <PR IDs this change closes>' "$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    [ "$status" -ne 0 ] || { echo "the skill still restates the message template"; false; }
}

@test "verify-before-merge: a mutant used as evidence becomes a Mutation: trailer" {
    # verifies: ADR-3hsvvq
    skill_text=$(tr '\n' ' ' < "$BATS_TEST_DIRNAME/../skills/verify-before-merge/SKILL.md" | tr -s ' ')
    printf '%s\n' "$skill_text" | grep -qF 'A mutant the change uses as evidence becomes a `Mutation: <path>:<line> <mutant> — killed by "<test name>"` trailer in the message.' \
        || { echo "no shipped skill says when a Mutation: trailer is written"; false; }
}

@test "verify-before-merge: the gate summary holds what step 6b's trailers need" {
    # verifies: ADR-f6ytg7
    # verifies: ADR-k3nkv3
    root="$BATS_TEST_DIRNAME/.."
    skill_text=$(tr '\n' ' ' < "$root/skills/verify-before-merge/SKILL.md" | tr -s ' ')
    printf '%s\n' "$skill_text" | grep -qF 'Anything `merge-change` step 6b'"'"'s trailers need from the gate' \
        || { echo "verify-before-merge still feeds the gate figures to the record"; false; }
    rationale_text=$(tr '\n' ' ' < "$root/skills/verify-before-merge/references/rationale.md" | tr -s ' ')
    printf '%s\n' "$rationale_text" | grep -qF 'the squash commit'"'"'s `Tests:` and `Coverage:` trailers' \
        || { echo "the rationale does not name the trailers as the durable evidence"; false; }
    printf '%s\n' "$rationale_text" | grep -qF 'the evidence moves from the chat log to the log file and the squash commit'"'"'s trailers' \
        || { echo "the rationale still sends the gate evidence to the verification record"; false; }
    block_text=$(tr '\n' ' ' < "$root/templates/AGENTS-block.md" | tr -s ' ')
    printf '%s\n' "$block_text" | grep -qF 'carry its verification record in its message, with a `Gate-tree:` trailer naming the tree the gate measured' \
        || { echo "the AGENTS block does not require the message and trailer"; false; }
    printf '%s\n' "$block_text" | grep -qF 'check-review.sh [--message FILE] [--cite]`' \
        || { echo "the AGENTS block does not give check-review's usage"; false; }
    readme_text=$(tr '\n' ' ' < "$root/README.md" | tr -s ' ')
    printf '%s\n' "$readme_text" | grep -qF 'whose message is its verification record and whose `Gate-tree:` trailer names the tree its gate measured' \
        || { echo "the README does not state the message and trailer"; false; }
    printf '%s\n' "$readme_text" | grep -qF '`templates/squash-message.txt` states the squash message' \
        || { echo "the README does not name the message template"; false; }
    for text in "$block_text" "$readme_text"; do
        if printf '%s\n' "$text" | grep -qF -e 'verification.md' -e '--branch'; then
            echo "still names the record file or --branch: $text"; false
        fi
    done
}

@test "resolve-problem: a backlog figure in a document is a red flag" {
    # verifies: REQ-t3jwwv
    skill="$BATS_TEST_DIRNAME/../skills/resolve-problem/SKILL.md"
    grep -q 'State the backlog size' "$skill"
    grep -q 'Name the IDs that moved' "$skill"
}

@test "squash message template: the gate's figures and their tree are trailers, written at step 6b" {
    # verifies: REQ-c8hkb5
    # verifies: ADR-k3nkv3
    # Gate evidence is keyed to a tree or it is keyed to nothing.
    # The message is outside the tree, so it can name the tree the gate
    # measured; step 6b writes the trailers once the summary is confirmed for
    # that tree, so a rerun replaces them rather than staling them.
    template="$BATS_TEST_DIRNAME/../templates/squash-message.txt"
    for wanted in 'Gate-tree: <tree>' 'Tests: <command> <passed>/<total>' \
            'Coverage: <command> <figure>' 'Base: <base ref> at <commit>'; do
        grep -qxF -- "$wanted" "$template" || { echo "the template lacks: $wanted"; false; }
    done
    step6b=$(step_of "$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md" 6b | tr '\n' ' ' | tr -s ' ')
    for wanted in 'replacing an earlier round'"'"'s' '`Gate-tree:` the step 6a tree' \
            '`Tests: <verify_commands entry> <passed>/<total>` per entry, per impact-set unit' \
            '`Coverage: <coverage_command> <figure>` per configured command' \
            '`Base: <base ref> at <commit>`, the commit step 1 merged'; do
        printf '%s\n' "$step6b" | grep -qF -- "$wanted" \
            || { echo "step 6b lacks: $wanted"; false; }
    done
}

@test "ledger files: the skills and templates name a ledger file at creation, and nothing renames it" {
    # verifies: ADR-cy7ahd
    root="$BATS_TEST_DIRNAME/.."
    # The ratchet files name the old convention on purpose: they tell an
    # adopter how to retire it.
    # grep exits 1 when nothing matches, the passing case, and 2 on a path it
    # cannot read; each status is kept so that 0 and 1 pass and 2 or above
    # fails the test.
    grep_status=0
    taught=$(grep -rnE 'finalize-docs|DRAFT-<branch>-<slug>|<finalize-date>' \
            "$root"/skills "$root"/templates "$root"/README.md \
            "$root"/docs/problems/README.md) || grep_status=$?
    [ "$grep_status" -le 1 ] || { echo "the convention scan failed: grep exit $grep_status"; false; }
    grep_status=0
    hits=$(printf '%s\n' "$taught" \
        | grep -v -e '/skills/ratchet/references/upgrade-notes\.md:' \
                  -e '/skills/ratchet/SKILL\.md:') || grep_status=$?
    [ "$grep_status" -le 1 ] || { echo "filtering the ratchet files failed: grep exit $grep_status"; false; }
    [ -z "$hits" ] || { echo "the old convention is still taught: $hits"; false; }
    for skill_and_path in \
        'grill-requirements docs/requirements/<YYYY-MM-DD>-<slug>.md' \
        'analyze-risks docs/risk/<YYYY-MM-DD>-<slug>.md' \
        'design-architecture docs/architecture/<YYYY-MM-DD>-<slug>.md' \
        'resolve-problem docs/problems/<YYYY-MM-DD>-<slug>.md' \
        'worktree-discipline docs/<area>/<YYYY-MM-DD>-<slug>.md'; do
        skill_name=${skill_and_path%% *}
        ledger_path=${skill_and_path#* }
        grep -qF "\`$ledger_path\`" "$root/skills/$skill_name/SKILL.md" \
            || { echo "$skill_name does not name $ledger_path"; false; }
    done
    grep -qF '`docs/<area>/<YYYY-MM-DD>-<slug>.md`' "$root/templates/AGENTS-block.md" \
        || { echo "the managed block does not name the dated path"; false; }
    for readme in templates/srs.md templates/rmf.md templates/sad.md \
            templates/problems.md docs/problems/README.md; do
        tr '\n' ' ' < "$root/$readme" | tr -s ' ' \
            | grep -qF 'dated the day the change creates it and never renamed' \
            || { echo "$readme does not state the rule"; false; }
    done
    [ ! -e "$root/scripts/finalize-docs.sh" ] || { echo "finalize-docs.sh still ships"; false; }
    grep_status=0
    script_hits=$(grep -rln 'finalize-docs' "$root"/scripts) || grep_status=$?
    [ "$grep_status" -le 1 ] || { echo "the script scan failed: grep exit $grep_status"; false; }
    [ -z "$script_hits" ] || { echo "a script still names finalize-docs: $script_hits"; false; }
}

@test "merge-change: no step renames a ledger file, and the tree check confirms the tree the gate summary describes" {
    # verifies: ADR-cy7ahd, REQ-kqb2vp
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    if grep -qi 'finaliz' "$skill"; then
        grep -ni 'finaliz' "$skill"; false
    fi
    step_6b=$(step_of "$skill" 6b)
    printf '%s\n' "$step_6b" | grep -q 'the step 6a summary stands' || { echo "$step_6b"; false; }
    printf '%s\n' "$step_6b" | grep -qF 'git status --porcelain' || { echo "$step_6b"; false; }
}

@test "merge-change: two changes that name a ledger file alike meet at step 1, and the documented resolution keeps both" {
    # verifies: REQ-6jyypf
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    step1=$(step_of "$skill" 1 \
        | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$step1" | grep -qF 'An add/add conflict on a ledger file' || { echo "$step1"; false; }
    printf '%s\n' "$step1" | grep -qF '`git show :2:<path> > <new path>`' || { echo "$step1"; false; }
    printf '%s\n' "$step1" | grep -qF '`git checkout --theirs -- <path>`' || { echo "$step1"; false; }

    make_fixture_repo
    mkdir -p docs/problems
    git checkout -q -b change
    printf '**PR-a3k9z2**: this change.\n' > docs/problems/2026-01-02-fixes.md
    commit_all 'the change names its ledger file'
    git checkout -q main
    printf '**PR-b4m8p3**: the base.\n' > docs/problems/2026-01-02-fixes.md
    commit_all 'another change merged the same name'
    git checkout -q change

    run env GIT_MERGE_AUTOEDIT=no git merge main
    [ "$status" -ne 0 ] || { echo "the base merged cleanly: $output"; false; }
    [[ "$output" == *"CONFLICT (add/add)"*"docs/problems/2026-01-02-fixes.md"* ]] \
        || { echo "$output"; false; }

    # The resolution step 1 documents, with <path> and <new path> filled in.
    git show :2:docs/problems/2026-01-02-fixes.md > docs/problems/2026-01-02-change-fixes.md
    git checkout --theirs -- docs/problems/2026-01-02-fixes.md
    git add docs/problems/2026-01-02-fixes.md docs/problems/2026-01-02-change-fixes.md
    git -c commit.gpgsign=false commit -q --no-edit
    grep -q 'PR-b4m8p3' docs/problems/2026-01-02-fixes.md || { echo "the base's file was not kept"; false; }
    grep -q 'PR-a3k9z2' docs/problems/2026-01-02-change-fixes.md || { echo "this change's file was lost"; false; }
}

@test "merge-change: the tree check lets the gate summary stand where the tree is unchanged" {
    # verifies: REQ-kqb2vp
    # Step 6b follows the 6a gate, and every fix reruns from step 1, so a second
    # dispatch on an unchanged tree measures what the first already measured.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'the step 6a summary stands' "$skill"
    grep -qF 'rev-parse HEAD^{tree}' "$skill"
}

@test "merge-change: the reviewer tags every finding" {
    # verifies: REQ-4kyacv
    # check-review.sh block-parses the header and ignores the value, so the tag
    # adds no script and no new malformed case.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'Every finding opens with its tag' "$skill"
    grep -qF '`code`, `requirement`, `guideline` or `record`' "$skill"
    grep -qF '`high`, `medium` or `low`' "$skill"
}

@test "merge-change: a round with nothing above low severity is the last" {
    # verifies: REQ-5nb2wu
    # A clean-round rule does not converge: rounds keep raising low findings.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    checklist="$BATS_TEST_DIRNAME/../skills/merge-change/references/review-checklist.md"
    grep -q 'are all `low` is the last review' "$skill"
    grep -qF '`high`' "$checklist"
    grep -qF '`medium`' "$checklist"
    grep -qF '`low`' "$checklist"
    run grep -q 'A round raising no `code` and no `requirement` finding is the last' "$skill"
    [ "$status" -ne 0 ]
}

@test "the skills and templates name the creation date, not the merge date" {
    # verifies: ADR-cy7ahd
    # A ledger file is dated the day its change creates it (ADR-cy7ahd), and
    # nothing re-dates it at merge, so the date is not the merge date, and no
    # skill, template or README may say it is.
    #
    # The scan covers docs/problems/README.md as well, which is this repository's
    # own copy of templates/problems.md: fixing the template does not fix the
    # copy, and the copy is what a reader of this ledger opens.
    root="$BATS_TEST_DIRNAME/.."
    ! grep -rniE 'merge.date' "$root"/skills "$root"/templates/*.md \
        "$root"/README.md "$root"/docs/problems/README.md \
        || { echo "a merge date is still stated (matches above)"; false; }
}

@test "merge-change: the gate step records the tree its summary describes" {
    # verifies: REQ-kqb2vp
    # Step 6b compares the current tree against the one step 6a measured, so
    # step 6a has to have written that hash down. Without it the comparison has
    # no left-hand side and the rule is unusable on its first pass.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'Record the tree the summary describes' "$skill"
    # ...and upstream of the step 6b comparison that reads it.
    recorded=$(grep -n 'Record the tree the summary describes' "$skill" | cut -d: -f1)
    compared=$(grep -n 'the step 6a summary stands' "$skill" | cut -d: -f1)
    [ "$recorded" -lt "$compared" ]
}

@test "squash message template opens every finding with its tag" {
    # verifies: REQ-4kyacv
    # verifies: ADR-k3nkv3
    # The review step requires `code`, `requirement` or `record` as the first
    # word of a finding, and the template step 5 copies is the one place the
    # shape is demonstrated rather than described, so its finding carries the
    # tag, after the disposition.
    template="$BATS_TEST_DIRNAME/../templates/squash-message.txt"
    grep -qxF '1. [<disposition>] <tag>[ <severity>] — <text>' "$template"
    # A `record` finding states no severity.
    grep -qF 'and record (none)' "$template"
    # The template must not restate a boundary rule: what a citation may
    # name is check-review.sh's, and a rule the template restates reaches
    # every adopter.
    ! grep -q 'a file some gate reads' "$template" \
        || { echo "the template restates a boundary: a file some gate reads"; false; }
    ! grep -q 'a file some test reads' "$template" \
        || { echo "the template restates a boundary: a file some test reads"; false; }
    ! grep -q 'anything a .verify_commands. entry opens' "$template" \
        || { echo "the template restates a boundary: anything a verify_commands entry opens"; false; }
}

@test "merge-change: the tag does not shorten the sequence" {
    # verifies: REQ-quq85e
    # The skill classifies findings and says when to stop, and states plainly
    # that it bounds no record finding's cost: a bound would rest on a class of
    # files no gate reads, and there is none, since check-ids.sh greps the whole
    # tree. Stating it keeps a reader from inferring a bound from the tag.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'Every finding still sends the sequence back to step 1' "$skill"
    grep -q 'deliberately not taken' "$skill"
    # and the tag's actual effect, which is what makes the convergence rule
    # below executable: a record-only round reruns like any other but dispatches
    # no further reviewer. Without it the two rules would contradict each other
    # for exactly the case convergence is about.
    grep -q 'whether \*\*another' "$skill"
    grep -q 'no further reviewer is dispatched' "$skill"
    # The neighbouring paragraphs must not re-derive a shortened sequence from
    # the tag. The absence of the phrase "finding-free round" alone is not
    # enough: a reworded sentence satisfies it while keeping the inference.
    # So assert the claim that replaced it, and reject the
    # two inferences by shape rather than by one spelling.
    run grep -rq 'finding-free round' "$(dirname "$skill")"
    [ "$status" -ne 0 ]
    run grep -rq 'runs only on the last round' "$(dirname "$skill")"
    [ "$status" -ne 0 ]
    run grep -rq 'never reaches a later step\.\*\* The paragraph below sends' "$(dirname "$skill")"
    [ "$status" -ne 0 ]
    # The reason the review worktree is removed whatever the findings is
    # stated in the rationale.
    grep -q 'any finding at' "$(dirname "$skill")/references/rationale.md"
    grep -q 'whatever the findings were tagged' "$(dirname "$skill")/references/rationale.md"
    # and the red-flag row does not offer the saving either
    ! grep -rq 'skips the suite, not the gates' "$(dirname "$skill")" \
        || { echo "merge-change still says: skips the suite, not the gates"; false; }
}

@test "merge-change: the mechanical checks are the pre-flight" {
    # verifies: REQ-994yy6
    # merge-preflight.sh runs the pre-flight and step 6c's checks in one
    # command. Each step names the script, inside its own span, so a step that
    # goes back to listing the commands one at a time is reported.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    preflight_at=$(grep -n '^2\. ' "$skill" | head -n 1 | cut -d: -f1)
    ruling_at=$(grep -n '^3\. ' "$skill" | head -n 1 | cut -d: -f1)
    c_at=$(grep -n '^6c\. ' "$skill" | head -n 1 | cut -d: -f1)
    d_at=$(grep -n '^6d\. ' "$skill" | head -n 1 | cut -d: -f1)
    [ -n "$preflight_at" ] || { echo "no step 2"; false; }
    [ -n "$ruling_at" ] || { echo "no step 3"; false; }
    [ -n "$c_at" ] || { echo "no step 6c"; false; }
    [ -n "$d_at" ] || { echo "no step 6d"; false; }
    sed -n "${preflight_at},${ruling_at}p" "$skill" | grep -qF 'merge-preflight.sh --before-review' \
        || { echo "step 2 does not run merge-preflight.sh --before-review"; false; }
    sed -n "${c_at},${d_at}p" "$skill" | grep -qF 'merge-preflight.sh <' \
        || { echo "step 6c does not run merge-preflight.sh"; false; }
}

@test "develop-change: the dispatch prompt names task-worktree.sh" {
    # verifies: REQ-rmsk4r
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
    # verifies: REQ-b7kmx8
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
    # verifies: REQ-dmk4mf
    # check-trace.sh and check-ids.sh print one `fix <RULE>:` line per rule
    # that fired. A second copy of each remedy in the skill drifts from
    # the script, so the skill points at the output instead.
    skill="$BATS_TEST_DIRNAME/../skills/check-traceability/SKILL.md"
    run grep -q '^## Fixing each rule' "$skill"
    [ "$status" -ne 0 ] || { echo "the skill still has the Fixing each rule table"; false; }
    grep -qF 'fix <RULE>:' "$skill"
}

# The skill shape: section order, word ceiling and References.

# The `## ` headings of a SKILL.md outside fenced code, joined with `|`.
gr_skill_headings() {
    awk '/^```/ { fenced = !fenced; next } !fenced && /^## / { sub(/^## /, ""); printf "%s|", $0 }' "$1"
}

# 0 when a SKILL.md's sections are in the order AGENTS.md states, with or
# without References.
gr_skill_has_section_order() {
    case "$(gr_skill_headings "$1")" in
        ('Preconditions|Steps|Red flags|Done when|References|') return 0 ;;
        ('Preconditions|Steps|Red flags|Done when|') return 0 ;;
        (*) return 1 ;;
    esac
}

gr_skill_words() {
    wc -w < "$1" | tr -d ' '
}

# 0 when a SKILL.md is at most 2,000 words.
gr_skill_within_word_ceiling() {
    [ "$(gr_skill_words "$1")" -le 2000 ]
}

# Prints one ` <skill>:[...]` failure per References problem in the skill
# directory $1 (with a trailing slash), and nothing when there is none. A
# reference file no SKILL.md names is never read; a named one that does not
# exist is a dead instruction. A file is listed only by an entry line, one
# opening with "- `references/"; a name on a continuation line or in prose
# does not list it.
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
    # The section is omitted when the skill has no reference file.
    # A trailing space after the heading is still the heading.
    if [ -z "$files_on_disk" ] && grep -qE '^## References[[:space:]]*$' "${skill_dir}SKILL.md"; then
        printf ' %s' "$skill_name:[a References heading and no reference file]"
    fi
    # Each entry names the file and the condition for reading it.
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

@test "skill shape: every SKILL.md has Preconditions, Steps, Red flags, Done when and References in that order" {
    # verifies: REQ-h528pv
    # A fixed order lets an agent find the step it needs without reading the
    # whole file.
    cd "$BATS_TEST_DIRNAME/.." || return 1
    failures=""
    for skill_file in skills/*/SKILL.md; do
        skill_name=$(basename "$(dirname "$skill_file")")
        if ! gr_skill_has_section_order "$skill_file"; then
            failures="$failures $skill_name:[$(gr_skill_headings "$skill_file")]"
        fi
    done
    if [ -n "$failures" ]; then
        echo "skills out of the Preconditions, Steps, Red flags, Done when, References order:$failures"
        return 1
    fi
}

@test "skill shape: every SKILL.md is at most 2,000 words" {
    # verifies: REQ-x57fr8
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
    # verifies: REQ-b9nf5v
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
# the required shape, so the tests above never see a rejection; these tests write a
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
    # verifies: REQ-h528pv
    skill_dir="$BATS_TEST_TMPDIR/fixture/"
    gr_write_skill_fixture "$skill_dir" Steps Preconditions "Red flags" "Done when"
    run gr_skill_has_section_order "${skill_dir}SKILL.md"
    [ "$status" -ne 0 ]
}

@test "skill shape fixture: a missing Red flags section is rejected" {
    # verifies: REQ-h528pv
    skill_dir="$BATS_TEST_TMPDIR/fixture/"
    gr_write_skill_fixture "$skill_dir" Preconditions Steps "Done when"
    run gr_skill_has_section_order "${skill_dir}SKILL.md"
    [ "$status" -ne 0 ]
}

@test "skill shape fixture: a References heading with no reference file is rejected" {
    # verifies: REQ-b9nf5v
    skill_dir="$BATS_TEST_TMPDIR/fixture/"
    gr_write_skill_fixture "$skill_dir" Preconditions Steps "Red flags" "Done when" References
    run gr_skill_reference_failures "$skill_dir"
    [[ "$output" == *"fixture:[a References heading and no reference file]"* ]]
}

@test "skill shape fixture: a References entry that names a missing file is rejected" {
    # verifies: REQ-b9nf5v
    skill_dir="$BATS_TEST_TMPDIR/fixture/"
    gr_write_skill_fixture "$skill_dir" Preconditions Steps "Red flags" "Done when" References
    printf -- '- `references/missing.md` — read when the fixture asks for it.\n' \
        >> "${skill_dir}SKILL.md"
    run gr_skill_reference_failures "$skill_dir"
    [[ "$output" == *"fixture:[listed: references/missing.md][present: ]"* ]]
}

@test "skill shape fixture: a References entry with no read-when condition is rejected" {
    # verifies: REQ-b9nf5v
    skill_dir="$BATS_TEST_TMPDIR/fixture/"
    gr_write_skill_fixture "$skill_dir" Preconditions Steps "Red flags" "Done when" References
    mkdir -p "${skill_dir}references"
    printf 'Reference text.\n' > "${skill_dir}references/notes.md"
    printf -- '- `references/notes.md`\n' >> "${skill_dir}SKILL.md"
    run gr_skill_reference_failures "$skill_dir"
    [[ "$output" == *"fixture:[entry without a file and a read-when condition: - \`references/notes.md\`]"* ]]
}

@test "skill shape fixture: a 2,001-word SKILL.md is rejected, and 2,000 words is accepted" {
    # verifies: REQ-x57fr8
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
    # verifies: REQ-h528pv, REQ-x57fr8, REQ-b9nf5v
    skill_dir="$BATS_TEST_TMPDIR/fixture/"
    gr_write_skill_fixture "$skill_dir" Preconditions Steps "Red flags" "Done when"
    gr_skill_has_section_order "${skill_dir}SKILL.md"
    gr_skill_within_word_ceiling "${skill_dir}SKILL.md"
    run gr_skill_reference_failures "$skill_dir"
    [ -z "$output" ]
}

@test "skill shape fixture: a SKILL.md with a well-formed References section is accepted" {
    # verifies: REQ-h528pv, REQ-x57fr8, REQ-b9nf5v
    skill_dir="$BATS_TEST_TMPDIR/fixture/"
    gr_write_skill_fixture "$skill_dir" Preconditions Steps "Red flags" "Done when" References
    mkdir -p "${skill_dir}references"
    printf 'Reference text.\n' > "${skill_dir}references/notes.md"
    printf -- '- `references/notes.md` — read when the fixture asks for it,\n  and on a\n  continuation line.\n' \
        >> "${skill_dir}SKILL.md"
    gr_skill_has_section_order "${skill_dir}SKILL.md"
    gr_skill_within_word_ceiling "${skill_dir}SKILL.md"
    run gr_skill_reference_failures "$skill_dir"
    [ -z "$output" ]
}

@test "merge-change: the skill and its rationale state the round-message, hand-over, worktree and exit-2 instructions and their reasons" {
    # verifies: REQ-994yy6, REQ-e2q5g5, REQ-5nb2wu, REQ-rstp46, REQ-2crnq2, REQ-c6vc2k, REQ-t3jwwv, REQ-qg3r38, REQ-kqb2vp, REQ-c8hkb5, REQ-744g4c, REQ-su9jg5, REQ-63smcs, REQ-bc52mm, ADR-3hsvvq
    # Instructions the skill must state, each pinned by its text.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    rationale="$BATS_TEST_DIRNAME/../skills/merge-change/references/rationale.md"
    grep -q "A later round's reviewer reads the message earlier rounds wrote" "$skill"
    grep -q 'name it so the user can run it' "$skill"
    grep -q 'consider two independent' "$skill"
    # The advice applies to class C only.
    grep -q 'C a thorough review; for class C,' "$skill"
    grep -q 'With no worktree registered for the branch' "$skill"
    grep -q 'leave or remove it with the harness tool' "$skill"
    # The review checklist holds the documentation checks, and its
    # superseded-item check states the successor's own test.
    grep -q 'The successor has its own test' \
        "$BATS_TEST_DIRNAME/../skills/merge-change/references/review-checklist.md"
    # Two reasons live in the rationale to make room for instructions, and
    # the skill states where an exit 2 can come from.
    grep -q 'usage or environment error from the pre-flight or a tool it runs' "$skill"
    grep -q 'their shell has none of your variables' "$rationale"
    grep -q 'cannot be re-identified one round' "$rationale"
    # The rationale file points into no script comments (see "the rationale
    # file describes no script"), so what is asserted here is the reasons it
    # keeps.
    grep -q 'what the duplicate scan at step 2 was compared against' "$rationale"
    grep -q 'fails step 2 for every later change' "$rationale"
    grep -q 'not the counts it was handed' "$rationale"
    grep -q 'reports on a suite it could not run' "$rationale"
    grep -q 'in the software or in the account of it' "$rationale"
    grep -q 'the dispatcher is `merge-change`' "$rationale"
    grep -q 'a stop with no defect behind it' "$rationale"
    grep -q 'the property guard 4 exists for' "$rationale"
    grep -q 'never in the tree the gate measures' "$rationale"
    grep -q 'needs the current totals' "$rationale"
    grep -q 'a change with no reproduction states so' "$rationale"
    grep -q 'the units whose gates the verdict covers' "$rationale"
    grep -q 'A deleted finding and a finding that never existed read identically' "$rationale"
    grep -q 'removing the change worktree does not touch it' "$rationale"
    grep -q 'It names exactly the PR items the diff deletes' "$rationale"
    grep -q 'starts a blocking wait on the user' "$rationale"
    grep -q 'a chance to remove the wrong directory' "$rationale"
    grep -q 'so a pass would add nothing' "$rationale"
    grep -q 'only the cleanup is outstanding' "$rationale"
    # The step 1 paragraph must not state that two branches cannot collide
    # by construction.
    run grep -q 'cannot collide by construction' "$rationale"
    [ "$status" -ne 0 ]
    run grep -q 'with two independent reviewers for critical' "$skill"
    [ "$status" -ne 0 ]
}

@test "merge-change: changes may run in parallel, and the rationale says why" {
    # verifies: REQ-zy25dp
    # Nothing may bar a second change from opening, since AGENTS.md allows
    # parallel changes. The rationale must state why that is safe: step 1
    # merges the base every round, IDs are random tokens, and each change's
    # record is its own worktree's squash message (ADR-k3nkv3).
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    rationale="$BATS_TEST_DIRNAME/../skills/merge-change/references/rationale.md"
    # Prose wraps, so a phrase is matched on the file with its lines joined.
    rationale_text=$(tr '\n' ' ' < "$rationale")
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command.
    run grep -qi 'one change at a time' "$skill" "$rationale"
    [ "$status" -ne 0 ]
    # The same precondition may return in other words, such as "Only one open
    # change". The Preconditions section keeps
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
    printf '%s\n' "$rationale_text" | grep -qF "squash message in its own worktree's git directory, so no two changes share one"
}

@test "merge-change: a base merge that shares a file with the change gets a fresh review" {
    # verifies: REQ-r8rsew
    # With changes open in parallel, the base can move after the last
    # reviewer was dispatched: on the rerun after an all-low round, or after
    # step 7's base-moved remedy. The gate reruns on the merged tree, but no
    # reviewer saw the merge. When the base and the change edited the same file,
    # the whole change goes to a fresh reviewer; when the files are disjoint,
    # the gate rerun covers it. Step 1 lists the files the base edited after
    # the commit step 4 marked as reviewed that the change also edits. It compares
    # against that marker, not the last base merge, so a rerun after a failed
    # gate lists the file again. This test runs
    # step 1's fence and step 4's marker against one fixture, scenario by scenario.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    rationale="$BATS_TEST_DIRNAME/../skills/merge-change/references/rationale.md"
    step1=$(step_of "$skill" 1)
    [ -n "$step1" ]
    step1_text=$(printf '%s\n' "$step1" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$step1_text" | grep -qF 'A `shared:` line names a file this change edits that the base edited after the last reviewed commit: step 4 then reviews the whole change again, even after the last review round. Otherwise the gate rerun covers it.'
    rationale_text=$(tr '\n' ' ' < "$rationale" | tr -s ' ')
    printf '%s\n' "$rationale_text" | grep -q 'A base that moved also changes what the review saw'
    printf '%s\n' "$rationale_text" | grep -q 'any shared file sends the whole change to a fresh reviewer'
    printf '%s\n' "$rationale_text" | grep -q 'A conflict is not the test'
    printf '%s\n' "$rationale_text" | grep -q 'because the obligation must survive a rerun'
    printf '%s\n' "$rationale_text" | grep -q 'the message names the shared files and that review round'

    fence=$(printf '%s\n' "$step1" | sh_fence)
    printf '%s\n' "$fence" | grep -q 'git merge "\$base_ref"'
    review_step=$(step_of "$skill" 4)
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
    # verifies: REQ-yg9b8s
    # With one squash already staged in the primary index, a second
    # `git merge --squash` exits 0 and stacks its files onto the first when
    # the two touch different files and it fast-forwards; on a shared file git
    # refuses. The staged squash is a lock only if step 7 looks for it before
    # staging. The check is joined to the squash with `&&`: run as two lines in
    # one shell call, a non-empty index fails the check and the squash runs
    # anyway.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    rationale="$BATS_TEST_DIRNAME/../skills/merge-change/references/rationale.md"
    # Prose wraps, so a phrase is matched on the file with its lines joined.
    rationale_text=$(tr '\n' ' ' < "$rationale")
    step7=$(step_of "$skill" 7)
    [ -n "$step7" ]
    printf '%s\n' "$step7" | grep -qE '^ *git diff --cached --quiet && git merge --squash <branch>$'
    # The squash command appears only in its joined form.
    [ "$(printf '%s\n' "$step7" | grep -c 'git merge --squash <branch>')" -eq 1 ]
    # The second line compares the index with the branch after every squash,
    # not only when the index check fails: a base that moved after the last
    # step 1 makes the squash a three-way merge that exits 0 and stages a
    # tree the gate never saw.
    printf '%s\n' "$step7" | grep -qE '^ *git diff --cached --quiet <branch>$'
    squash_at=$(printf '%s\n' "$step7" | grep -n 'git merge --squash <branch>$' | cut -d: -f1)
    compare_at=$(printf '%s\n' "$step7" | grep -n '^ *git diff --cached --quiet <branch>$' | cut -d: -f1)
    [ "$compare_at" -eq $((squash_at + 1)) ]
    step7_text=$(printf '%s\n' "$step7" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$step7_text" | grep -qF "The second line exits 0 when the index holds exactly the branch's tree: go on."
    # Which case a failed comparison is follows from the first line's
    # output, not its exit status: a conflicted squash of this change also
    # exits 1. A squash that ran is cleared and
    # the sequence reruns from step 1. A squash git refused because the
    # primary checkout is dirty is not a moved base: `git reset --merge` keeps
    # the edit, and the rerun would loop.
    printf '%s\n' "$step7_text" | grep -qF 'The first line printed that files "would be overwritten": the primary checkout is dirty. Stop and tell the user.'
    printf '%s\n' "$step7_text" | grep -qF "It printed other output: the base moved after step 1. Run \`git reset --merge\`, then rerun from step 1 as a base-move round:"
    # A squash staged before is another change's or an outdated one of this
    # change: the agent stops and the user decides.
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
    # itself; it holds one because step 7 checks.
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'holds one staged squash only because step 7 checks'
    # Step 1 alone does not close the parallel-change race; step 7's tree
    # comparison does.
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'Step 1 alone does not close the gap'
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q "Step 7's tree comparison catches that base move"
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'A gate result describes the branch.s tree, and nothing else'
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'runs after every squash, not only when the index check fails'
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -qF '`git reset --merge` resets the index to HEAD'
    # A squash over a staged one stacks only when the two touch different
    # files; on a shared file git refuses, fast-forward or not.
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'touch different files and the second squash fast-forwards'
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'fast-forward or not'
    run sh -c 'printf "%s\n" "$1" | tr -s " " | grep -q "When it fast-forwards, it exits 0"' _ "$rationale_text"
    [ "$status" -ne 0 ]
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'means the primary checkout has an edit or a file in the squash.s way'
    # Two step 7s at the same instant can still race; the rationale states
    # what catches each outcome.
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'Two sessions that run step 7 at the same instant can still race'
    printf '%s\n' "$rationale_text" | tr -s ' ' | grep -q 'that session.s signing then fails with "nothing to commit"'

    # Step 7's two lines run against git, not only as prose. Each case is set up in the primary checkout of a scratch
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

@test "merge-change: the squash step compares the staged tree with the gated tree and hands over the message file" {
    # verifies: REQ-su9jg5
    # verifies: ADR-k3nkv3
    # Step 7 writes no message: step 5 wrote it and step 6b added the gate's
    # trailers. It squashes, compares the staged tree with the Gate-tree:
    # value, and hands over a commit that strips the template's guidance.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    multi="$BATS_TEST_DIRNAME/../skills/merge-change/references/multi-unit.md"
    step7=$(step_of "$skill" 7)
    [ -n "$step7" ]
    step7_text=$(printf '%s\n' "$step7" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$step7" | grep -qxF "   git -c core.commentChar='#' commit -S --cleanup=strip -F <message file> && sh .guardrails/scripts/finish-merge.sh <branch>" \
        || { echo "step 7 does not hand over the message file"; false; }
    printf '%s\n' "$step7_text" | grep -qF "filled in with step 5's path" \
        || { echo "step 7 does not name where the message file is"; false; }
    run grep -qF -e 'Co-Authored-By' -e '/tmp/merge-' -e 'Verified:' -e 'Gate: <' "$skill"
    [ "$status" -ne 0 ] || { echo "the skill still writes the old message: $output"; false; }
    rationale="$BATS_TEST_DIRNAME/../skills/merge-change/references/rationale.md"
    rationale_text=$(tr '\n' ' ' < "$rationale" | tr -s ' ')
    for wanted in '`Base:` names the commit of the base ref that step 1 merged' \
            'its ID and trace checks read the tree, and can be rerun on the tree `Gate-tree:` names'; do
        printf '%s\n' "$rationale_text" | grep -qF -- "$wanted" \
            || { echo "rationale.md lacks: $wanted"; false; }
    done
    if printf '%s\n' "$rationale_text" | grep -qF 'checks read only the tree `Gate-tree:` names'; then
        echo "rationale.md still says the pre-flight reads only the named tree"; false
    fi
    tr '\n' ' ' < "$multi" | tr -s ' ' | grep -qF 'Tests: <unit>: <verify_commands entry> <passed>/<total>' \
        || { echo "multi-unit.md does not name the per-unit Tests: line"; false; }

    # The comparison is the second sh fence of step 7, after the squash and
    # before the hand-over command.
    fence=$(printf '%s\n' "$step7" | awk '
        /^ *```sh$/ { sh_fences++; fenced = 1; next }
        fenced && /^ *```$/ { fenced = 0; next }
        fenced && sh_fences == 2 { sub(/^ +/, ""); print }
    ')
    [ "$fence" = '[ "$(git write-tree)" = <the Gate-tree: value> ]' ] \
        || { echo "the second fence of step 7 is: $fence"; false; }
    squash_at=$(printf '%s\n' "$step7" | grep -n 'git merge --squash' | cut -d: -f1)
    compare_at=$(printf '%s\n' "$step7" | grep -n 'git write-tree' | cut -d: -f1)
    handover_at=$(printf '%s\n' "$step7" | grep -n "git -c core.commentChar='#' commit -S --cleanup=strip -F" | cut -d: -f1)
    [ "$squash_at" -lt "$compare_at" ] \
        || { echo "the comparison at $compare_at precedes the squash at $squash_at"; false; }
    [ "$compare_at" -lt "$handover_at" ] \
        || { echo "the hand-over at $handover_at precedes the comparison at $compare_at"; false; }
    printf '%s\n' "$step7_text" | grep -qF 'A mismatch: run `git reset --merge`, then rerun from step 1.' \
        || { echo "step 7 gives a mismatch no remedy"; false; }

    # The comparison, run against git: a squash of the gated tree passes, and
    # a squash of a branch that gained a commit after the gate does not.
    make_fixture_repo
    git checkout -q -b feature
    printf 'feature\n' > feature.txt
    commit_all 'the change'
    gate_tree=$(git rev-parse 'HEAD^{tree}')
    git checkout -q main
    git merge -q --squash feature
    compare=$(printf '%s\n' "$fence" | sed "s/<the Gate-tree: value>/$gate_tree/")
    run sh -c "$compare"
    [ "$status" -eq 0 ] || { echo "the gated squash failed the comparison"; false; }
    git reset -q --merge
    git checkout -q feature
    printf 'late\n' > late.txt
    commit_all 'a commit after the gate'
    git checkout -q main
    git merge -q --squash feature
    run sh -c "$compare"
    [ "$status" -eq 1 ] || { echo "a squash of a tree the gate never measured passed: $status"; false; }
    git reset -q --merge
}

@test "merge-change: the message is written before the gate, and step 5 writes no gate figure" {
    # verifies: REQ-4wm324
    # verifies: ADR-k3nkv3
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    rationale="$BATS_TEST_DIRNAME/../skills/merge-change/references/rationale.md"
    # The record is step 5, before the 6a gate in every round, so no sentence
    # has to order it before the last rerun.
    if grep -qF 'before that rerun' "$skill"; then
        echo "the skill still orders the record before the last rerun"; false
    fi
    step_5=$(step_of "$skill" 5)
    [ -n "$step_5" ]
    if printf '%s\n' "$step_5" | grep -q -e 'totals' -e 'tree they describe' -e "check's result"; then
        echo "step 5 still puts gate figures in the message"; false
    fi
    grep -q '^## Step 5: the message is outside the tree$' "$rationale"
    grep -q '^## Step 7: the trailers certify the gate$' "$rationale"
    rationale_text=$(tr '\n' ' ' < "$rationale" | tr -s ' ')
    printf '%s\n' "$rationale_text" | grep -qF 'not one computed again at step 7' \
        || { echo "the rationale does not say why Gate-tree is the step 6a hash"; false; }
    printf '%s\n' "$rationale_text" | grep -qF 'The pre-flight has no trailer' \
        || { echo "the rationale does not say why the pre-flight has no trailer"; false; }
}

@test "merge-change: the rationale file describes no script" {
    # verifies: REQ-hrccx6
    # Statements about scripts drift from the scripts, and so do pointers to
    # their comments, so the rationale file keeps only the reasons behind the
    # agent's rules; a script's own comments describe the script. A path under `scripts/` or any word ending in `.sh` is a
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
    # verifies: REQ-q8shms
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
    # verifies: REQ-9sgsbg
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
# the first line of FILE is the item line that defines the same ID. Exit 1 otherwise.
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
    # verifies: REQ-2vqqvq
    failures=""
    for adr_file in "$BATS_TEST_DIRNAME"/../docs/adr/*.md; do
        adr_file_is_named_by_its_item "$adr_file" || failures="$failures $adr_file"
    done
    [ -z "$failures" ] || { echo "ADR files not named by their item ID:$failures"; return 1; }
}

# The four tests below build every ADR ID at run time from a prefix variable:
# the repository gates scan tests/ for references.

@test "ADRs: the naming check accepts a file named by the token its first line defines" {
    # verifies: REQ-2vqqvq
    adr_prefix=ADR
    adr_id="$adr_prefix-k3n8p2"
    printf '**%s**: The configuration is flat YAML.\n\nStatus: accepted\n' "$adr_id" \
        > "$BATS_TEST_TMPDIR/$adr_id-flat-config.md"
    adr_file_is_named_by_its_item "$BATS_TEST_TMPDIR/$adr_id-flat-config.md"
}

@test "ADRs: the naming check rejects a file named by an ID its item line does not define" {
    # verifies: REQ-2vqqvq
    adr_prefix=ADR
    printf '**%s**: The configuration is flat YAML.\n' "$adr_prefix-m4q7r9" \
        > "$BATS_TEST_TMPDIR/$adr_prefix-k3n8p2-flat-config.md"
    run adr_file_is_named_by_its_item "$BATS_TEST_TMPDIR/$adr_prefix-k3n8p2-flat-config.md"
    [ "$status" -eq 1 ]
}

@test "ADRs: the naming check rejects an item line that is not on line 1" {
    # verifies: REQ-2vqqvq
    adr_prefix=ADR
    adr_id="$adr_prefix-k3n8p2"
    printf '# Flat configuration\n\n**%s**: The configuration is flat YAML.\n' "$adr_id" \
        > "$BATS_TEST_TMPDIR/$adr_id-flat-config.md"
    run adr_file_is_named_by_its_item "$BATS_TEST_TMPDIR/$adr_id-flat-config.md"
    [ "$status" -eq 1 ]
}

@test "ADRs: the naming check rejects a token with no digit" {
    # verifies: REQ-2vqqvq
    adr_prefix=ADR
    adr_id="$adr_prefix-aaaaaa"
    printf '**%s**: The configuration is flat YAML.\n' "$adr_id" \
        > "$BATS_TEST_TMPDIR/$adr_id-flat-config.md"
    run adr_file_is_named_by_its_item "$BATS_TEST_TMPDIR/$adr_id-flat-config.md"
    [ "$status" -eq 1 ]
}

@test "skills: no skill tells a superseded item's test to carry both IDs" {
    # verifies: ADR-k3nkv3
    # A test of a deleted item is pointed at its successor, not given both IDs.
    root="$BATS_TEST_DIRNAME/.."
    run grep -rnE 'verifies: <old ID>, <new ID>|both IDs on the one test' "$root/skills"
    [ "$status" -ne 0 ] || { echo "$output"; false; }
}

@test "skills: check 4 reads per ID and names an inherited test as coverage" {
    # verifies: ADR-k3nkv3
    # A test of a deleted item pointed at its successor passes check 4 only
    # when it is listed as inherited, and is coverage, never red-first
    # evidence. The rule is prose in four places that must agree: the check,
    # the dispatch report form, the record template and step 5's copy.
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

    # The report form and the coverage sentence belong to the TDD loop, which
    # develop-tdd holds; tests/develop-tdd.bats pins them there.
    grep -qF 'any `inherited:` lines into the plan' "$root/skills/develop-change/SKILL.md" \
        || { echo "develop-change does not write the inherited: lines into the plan"; false; }

    # The record template is the squash message's (ADR-k3nkv3).
    record="$root/templates/squash-message.txt"
    awk '/^Red-green:$/ { inside = 1; next } inside && /^[A-Z][a-z-]*:$/ { exit } inside' "$record" \
        | grep -qx 'inherited: <copied verbatim>' \
        || { echo "the message template does not say where inherited: goes"; false; }

    step_of "$root/skills/merge-change/SKILL.md" 5 | tr '\n' ' ' | tr -s ' ' \
        | grep -qF 'the `red -> green:` and `inherited:` lines from the plan' \
        || { echo "merge-change step 5 does not copy the inherited: lines"; false; }
}

@test "merge-change: step 1 merges the base and nothing else" {
    # verifies: ADR-k3nkv3
    # Step 1 leaves plans as they are: step 5 drops them after the record.
    # The fence ends at the merge, and a plan the change added is still there,
    # unchanged, after a clean merge.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    step1=$(step_of "$skill" 1)
    fence=$(printf '%s\n' "$step1" | sh_fence)
    last=$(printf '%s\n' "$fence" | tail -n 1)
    [ "$last" = 'git merge "$base_ref"' ] || { echo "the fence does not end at the merge: $last"; false; }
    if printf '%s\n' "$step1" | grep -qF 'prune-plans.sh'; then echo "step 1 still names prune-plans.sh"; false; fi
    if printf '%s\n' "$step1" | grep -qF 'left whole'; then echo "step 1 still names a left whole plan"; false; fi

    make_fixture_repo
    make_change_worktree feature
    mkdir -p docs/plans
    printf '### T1 — do it\n\n```sh\necho task-code\n```\n' > docs/plans/2026-01-01-x.md
    commit_all 'the plan'
    printf 'base\n' > "$REPO/base.txt"
    git -C "$REPO" add base.txt
    git -C "$REPO" commit -qm 'the base moves'
    run env GIT_MERGE_AUTOEDIT=no sh -c "BASE=main; $fence"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$(git rev-parse HEAD^2)" = "$(git rev-parse main)" ] || { echo "HEAD is not the base merge"; false; }
    grep -q 'task-code' docs/plans/2026-01-01-x.md || { echo "step 1 changed the plan"; false; }
    [ -z "$(git status --porcelain)" ] || { git status --short; false; }
}

@test "merge-change: step 5 drops the plans after the message, and commits no record" {
    # verifies: ADR-k3nkv3
    # The plan is dropped after the message copies its red -> green lines and
    # before the step 6a gate measures the tree, against the local base branch
    # the step 7 squash lands on, never origin/<base>. Runs step 5's fence in
    # a change worktree that added a plan.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    rationale="$BATS_TEST_DIRNAME/../skills/merge-change/references/rationale.md"
    step5=$(step_of "$skill" 5)
    commit_at=$(printf '%s\n' "$step5" | grep -n 'Copy `.guardrails/templates/squash-message.txt` to `$msg`' | head -n 1 | cut -d: -f1)
    drop_at=$(printf '%s\n' "$step5" | grep -n '^ *sh \.guardrails/scripts/drop-plans\.sh --base "\$BASE"$' | cut -d: -f1)
    [ -n "$commit_at" ] || { echo "step 5 does not write the message from the template"; false; }
    printf '%s\n' "$step5" | tr '\n' ' ' | tr -s ' ' | grep -qF 'Nothing is committed for the message.' ||
        { echo "step 5 does not say the message is not committed"; false; }
    if printf '%s\n' "$step5" | grep -q -e 'commit it' -e 'docs/verification'; then
        echo "step 5 still commits a record file"; false
    fi
    [ -n "$drop_at" ] || { echo "step 5 does not run drop-plans.sh --base \"\$BASE\""; false; }
    printf '%s\n' "$step5" | tr '\n' ' ' | tr -s ' ' | grep -qF 'the local base branch step 7 squashes onto' ||
        { echo "step 5 does not say why it drops against the local base"; false; }
    [ "$drop_at" -gt "$commit_at" ] || { echo "the drop comes before the message"; false; }
    grep -qx '## Step 5: the plan is dropped before the gate' "$rationale" ||
        { echo "no rationale section for the drop"; false; }
    if grep -q '^## Step 1: plans are pruned' "$rationale"; then echo "the rationale still prunes"; false; fi

    nth_fence() { printf '%s\n' "$step5" | awk -v want="$1" '
        /^ *```sh$/ { n++; fenced = 1; next }
        fenced && /^ *```$/ { fenced = 0; next }
        fenced && n == want { sub(/^   /, ""); print }'; }
    make_fixture_repo
    make_change_worktree feature
    # The first fence prints the message file: absolute, in this worktree's
    # git directory, so outside the tree.
    run sh -c "$(nth_fence 1)"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = "$(cd "$(git rev-parse --git-dir)" && pwd -P)/guardrails-squash.msg" ] ||
        [ "$output" = "$(git rev-parse --absolute-git-dir)/guardrails-squash.msg" ] ||
        { echo "not the worktree's message file: $output"; false; }
    mkdir -p docs/plans
    printf '# Plan\n' > docs/plans/2026-01-01-x.md
    commit_all 'the plan'
    fence=$(nth_fence 2)
    run sh -c "BASE=main; $fence"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ ! -e docs/plans/2026-01-01-x.md ] || { echo "the plan is still there"; false; }
    [ "$(git log -1 --format=%s)" = 'chore: drop plans' ] || { echo "last commit: $(git log -1 --format=%s)"; false; }
}

@test "merge-change: a later round's reviewer reads the dropped plan with git show" {
    # verifies: ADR-k3nkv3
    # After a first round, step 5 has dropped the plan; the next reviewer still
    # gets it, from the drop commit, found by its subject: a second run of
    # step 5 prints only `drop-plans: no plan to drop`, so its output cannot
    # name the commit. Runs the lookup the skill and checklist name.
    root="$BATS_TEST_DIRNAME/.."
    lookup="git log -1 --format=%H --grep='^chore: drop plans\$'"
    step4=$(step_of "$root/skills/merge-change/SKILL.md" 4 | tr '\n' ' ' | tr -s ' ')
    checklist=$(tr '\n' ' ' < "$root/skills/merge-change/references/review-checklist.md" | tr -s ' ')
    rationale=$(section_of '## Step 5: the plan is dropped before the gate' \
        "$root/skills/merge-change/references/rationale.md" | tr '\n' ' ' | tr -s ' ')
    for text in "$step4" "$checklist" "$rationale"; do
        printf '%s\n' "$text" | grep -qF "\`git show <commit>^:<path>\`, where <commit> is \`$lookup\`" ||
            { echo "no drop-commit lookup in: $text"; false; }
        if printf '%s\n' "$text" | grep -qF 'prints as its last line'; then echo "still reads drop-plans.sh's output"; false; fi
        if printf '%s\n' "$text" | grep -qF 'printed last'; then echo "still reads drop-plans.sh's output"; false; fi
        if printf '%s\n' "$text" | grep -qF 'prints last'; then echo "still reads drop-plans.sh's output"; false; fi
    done

    make_fixture_repo
    make_change_worktree feature
    mkdir -p docs/plans
    printf '# Plan\n' > docs/plans/2026-01-01-x.md
    commit_all 'the plan'
    sh .guardrails/scripts/drop-plans.sh --base main >/dev/null
    run sh .guardrails/scripts/drop-plans.sh --base main
    [ "$output" = 'drop-plans: no plan to drop' ] || { echo "$output"; false; }
    commit=$(eval "$lookup")
    [ "$(git show "$commit^:docs/plans/2026-01-01-x.md")" = '# Plan' ]
}

@test "verify-before-merge: the gate reads the squash message, not the dropped plan" {
    # verifies: ADR-k3nkv3
    # Step 5 drops the plan before the 6a gate, so check 4's Implements IDs
    # and red -> green lines, and check 8's findings, are read from the
    # message step 5 wrote.
    root="$BATS_TEST_DIRNAME/.."
    skill=$(tr '\n' ' ' < "$root/skills/verify-before-merge/SKILL.md" | tr -s ' ')
    rationale=$(tr '\n' ' ' < "$root/skills/verify-before-merge/references/rationale.md" | tr -s ' ')
    for text in "$skill" "$rationale"; do
        if printf '%s\n' "$text" | grep -qE 'the plan states|from the plan, where'; then
            echo "the gate still reads the plan"; false
        fi
    done
    printf '%s\n' "$skill" | grep -qF "for every ID the squash message's \`Implements:\` trailer names" ||
        { echo "the Implements map does not read the message's Implements: trailer"; false; }
    printf '%s\n' "$skill" | grep -qF "every ID the squash message's \`Implements:\` trailer names has a" ||
        { echo "check 4 does not read the message's Implements: trailer"; false; }
    printf '%s\n' "$skill" | grep -qF "message's \`Red-green:\` section" ||
        { echo "check 4 does not read the message's red -> green lines"; false; }
    for text in "$skill" "$rationale"; do
        printf '%s\n' "$text" | grep -qF "from the squash message's \`guideline\` findings" ||
            { echo "check 8 does not read the message's guideline findings"; false; }
    done
}

@test "merge-change: step 5 fills the message's Implements trailer from the plan's Implements value" {
    # verifies: ADR-k3nkv3
    # Check 4 reads its Implements IDs from the message, because the plan is
    # dropped before the gate. The red -> green lines are the same dispatch
    # lines check 4 cross-matches, so the IDs come from the plan.
    root="$BATS_TEST_DIRNAME/.."
    grep -qx 'Implements: <IDs>' "$root/templates/squash-message.txt" ||
        { echo "the message template has no Implements: trailer"; false; }
    step5=$(step_of "$root/skills/merge-change/SKILL.md" 5 | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$step5" | grep -qF "\`Implements:\` (the plan's \`**Implements:**\` value; no plan: the IDs)" ||
        { echo "step 5 does not copy the plan's Implements value, or state it where there is no plan"; false; }
}

@test "merge-change: a rerun of step 5 updates the message and reads the dropped plan by step 4's lookup" {
    # verifies: ADR-k3nkv3
    # After a 6a fix's review round or a base-move round with a shared: line,
    # step 5 runs again with the plan already dropped: it updates the record
    # it wrote, and reads the plan from the drop commit.
    root="$BATS_TEST_DIRNAME/.."
    step5=$(step_of "$root/skills/merge-change/SKILL.md" 5 | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$step5" | grep -qF 'or update it where it exists' ||
        { echo "step 5 does not update an existing record"; false; }
    printf '%s\n' "$step5" | grep -qF "A rerun reads the plan by step 4's lookup. Then:" ||
        { echo "step 5 does not say how a rerun reads the dropped plan"; false; }
    step4=$(step_of "$root/skills/merge-change/SKILL.md" 4 | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$step4" | grep -qF "git log -1 --format=%H --grep='^chore: drop plans\$'" ||
        { echo "step 4 names no drop-commit lookup"; false; }
}

@test "merge-change: step 5 names the three fields 6c requires, and a template placeholder is missing" {
    # verifies: ADR-k3nkv3
    # The message has three required fields, `branch:` gone with the record
    # file; a ratchet change's message is written early, its review fields
    # still holding the template's placeholders, which check-review.sh does
    # not reject.
    root="$BATS_TEST_DIRNAME/.."
    step5=$(step_of "$root/skills/merge-change/SKILL.md" 5 | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$step5" | grep -qF '`reviewer:`, `verdict:` and `reproduced:`' ||
        { echo "step 5 does not name the three fields"; false; }
    if printf '%s\n' "$step5" | grep -qF '`branch:`'; then echo "step 5 still names branch:"; false; fi
    printf '%s\n' "$step5" | grep -qF 'fill in only what is missing (a `<…>` placeholder counts as missing)' ||
        { echo "step 5 does not count a placeholder as missing"; false; }
}

@test "squash message template: a ratchet change's message is written early, at ratchet step 5" {
    # verifies: ADR-k3nkv3
    # Ratchet step 5 writes the message early; merge-change step 5 updates it.
    header=$(awk '!/^#/ { exit } { sub(/^# */, ""); print }' "$BATS_TEST_DIRNAME/../templates/squash-message.txt" |
        tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$header" | grep -qF '`ratchet` step 5 writes it early for a ratchet change, and merge-change step 5 updates it' ||
        { echo "the template says only merge-change step 5 writes the message: $header"; false; }
}

@test "merge-change: a disposition never cites the plan, which step 5 drops" {
    # verifies: ADR-k3nkv3
    # With review_cite: on, a disposition citing the plan's path is written at
    # step 5 and the plan is dropped in the same step, so 6c reports
    # UNRESOLVABLE-DISPOSITION.
    root="$BATS_TEST_DIRNAME/.."
    section=$(section_of '## Step 5: the plan is dropped before the gate' \
        "$root/skills/merge-change/references/rationale.md" | tr '\n' ' ' | tr -s ' ')
    checklist=$(tr '\n' ' ' < "$root/skills/merge-change/references/review-checklist.md" | tr -s ' ')
    for text in "$section" "$checklist"; do
        printf '%s\n' "$text" | grep -qF 'A disposition never cites the plan, since step 5 drops it; it cites the file the fix changed.' ||
            { echo "a disposition may still cite the plan: $text"; false; }
    done
}

@test "merge-change: a 6a fix that touches the plan dispatches a reviewer" {
    # verifies: ADR-k3nkv3
    # Step 5 has dropped the plan by 6a, so a fix that edits it re-adds a plan
    # and fails 6c's PLANS check: it is not a message-only fix (ADR-k3nkv3).
    root="$BATS_TEST_DIRNAME/.."
    step4=$(step_of "$root/skills/merge-change/SKILL.md" 4 | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$step4" | grep -qF "A 6a gate failure's fix dispatches a reviewer unless it changes only the message." ||
        { echo "step 4 still exempts a fix that touches the plan"; false; }
    section=$(section_of '## Step 4: the reviewer runs the tests it judges' \
        "$root/skills/merge-change/references/rationale.md" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$section" | grep -qF 'its fix dispatches a reviewer unless it changes only the message.' ||
        { echo "the rationale still exempts a fix that touches the plan"; false; }
    section=$(section_of '## Step 6a: the gate runs after the message' \
        "$root/skills/merge-change/references/rationale.md" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$section" | grep -qF 'so it dispatches a reviewer unless it changes only the message.' ||
        { echo "the 6a rationale still exempts a fix that touches the plan"; false; }
}

@test "merge-change: step 1 reruns after its conflicts are resolved" {
    # verifies: ADR-k3nkv3
    root="$BATS_TEST_DIRNAME/.."
    step_of "$root/skills/merge-change/SKILL.md" 1 | tr '\n' ' ' | tr -s ' ' |
        grep -qF 'Resolve conflicts here, never on the base branch, then rerun.' ||
        { echo "step 1 does not rerun after a conflict"; false; }
}

@test "skills: a fix dispatched after step 5 reports its red -> green lines, which the dispatcher writes into the message" {
    # verifies: ADR-k3nkv3
    # verifies: ADR-3hsvvq
    # Once step 5 drops the plan there is no plan to write them into, and a
    # task worktree's message file is its own, discarded with it.
    root="$BATS_TEST_DIRNAME/.."
    for file in skills/develop-change/SKILL.md skills/verify-before-merge/SKILL.md; do
        text=$(tr '\n' ' ' < "$root/$file" | tr -s ' ')
        printf '%s\n' "$text" | grep -qF 'A fix dispatched after step 5 (a 6a or 6c failure' ||
            { echo "$file does not route a post-step-5 fix's lines"; false; }
        printf '%s\n' "$text" | grep -qF "a base-move round's review) returns its lines in its report;" ||
            { echo "$file does not have the fix report its lines"; false; }
        printf '%s\n' "$text" | grep -qF "into the change worktree's message" ||
            { echo "$file does not send them to the change worktree's message"; false; }
        if printf '%s\n' "$text" | grep -qF 'into the message directly'; then
            echo "$file still has the fix write the message itself"; false
        fi
    done
}

@test "ratchet: the later teeth, the branch name and the signing duty survive the plan drop" {
    # verifies: ADR-k3nkv3
    # The gap analysis is dropped before the gate, so the later teeth are
    # listed in the record; the guidance cut to fit the word limit is back.
    skill=$(tr '\n' ' ' < "$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md" | tr -s ' ')
    printf '%s\n' "$skill" | grep -qF "(separate changes, listed in the retrofit's squash message)" ||
        { echo "later teeth not listed in the record"; false; }
    printf '%s\n' "$skill" | grep -qF '(any default branch name works)' ||
        { echo "the branch name note is gone"; false; }
    printf '%s\n' "$skill" | grep -qF 'an existing project must configure commit signing before' ||
        { echo "the signing duty is weakened"; false; }
}

@test "merge-change: the squash message names no plan" {
    # verifies: ADR-k3nkv3
    # The plan never reaches the base branch, so the squash message, which is
    # the record, does not point at it.
    root="$BATS_TEST_DIRNAME/.."
    skill="$root/skills/merge-change/SKILL.md"
    template="$root/templates/squash-message.txt"
    [ -s "$template" ] || { echo "no message template"; false; }
    if grep -qi '^Plan:' "$template"; then echo "the message names a plan"; false; fi
    if grep -qF 'docs/plans' "$template"; then echo "the message names a plan's path"; false; fi
    done_when=$(awk '/^## Done when/ { inside = 1; next } /^## / { inside = 0 } inside' "$skill" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$done_when" | grep -qF 'whose message is its verification record and names its gated tree' ||
        { echo "Done when does not name the record and gated tree"; false; }
    if printf '%s\n' "$done_when" | grep -qF 'names its plan'; then echo "Done when names the plan"; false; fi
}

@test "merge-change: the base merge stops while a squash is staged in the primary checkout" {
    # verifies: REQ-3kbtyn
    # A squash staged in the primary checkout is about to move the base: a
    # gate run against the current base would be rejected at step 7. Runs
    # step 1's fence from a change worktree, with and without a staged index.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    fence=$(step_of "$skill" 1 | sh_fence)
    run_step1() { run env GIT_MERGE_AUTOEDIT=no sh -c "BASE=main; $fence"; }

    make_fixture_repo
    primary=$(git rev-parse --show-toplevel)
    git worktree add -q "$BATS_TEST_TMPDIR/change" -b change
    cd "$BATS_TEST_TMPDIR/change"
    printf 'change\n' > change.txt
    commit_all 'the change'
    before=$(git rev-parse HEAD)
    printf 'second\n' > "$primary/second.txt"
    git -C "$primary" add second.txt
    git -C "$primary" commit -qm 'second base commit'
    second=$(git -C "$primary" rev-parse HEAD)
    printf 'staged\n' > "$primary/staged.txt"
    git -C "$primary" add staged.txt

    # A staged squash: stop, name the primary checkout, merge nothing.
    run_step1
    [ "$status" -eq 1 ] || { echo "status $status: $output"; false; }
    printf '%s\n' "$output" | grep -qxF "the index of $primary is not empty" \
        || { echo "not the index message: $output"; false; }
    [ "$(git rev-parse HEAD)" = "$before" ] || { echo "the change branch moved"; false; }

    git -C "$primary" reset -q

    # A failed worktree listing names no primary checkout: stop, merge
    # nothing, rather than read the change worktree's own index.
    stub="$BATS_TEST_TMPDIR/stub"
    mkdir -p "$stub"
    printf '#!/bin/sh\nif [ "$1 $2" = "worktree list" ]; then exit 128; fi\nexec %s "$@"\n' \
        "$(command -v git)" > "$stub/git"
    chmod +x "$stub/git"
    run env PATH="$stub:$PATH" GIT_MERGE_AUTOEDIT=no sh -c "BASE=main; $fence"
    [ "$status" -eq 1 ] || { echo "status $status with no primary checkout: $output"; false; }
    printf '%s\n' "$output" | grep -qF 'no primary checkout' || { echo "no reason in: $output"; false; }
    [ "$(git rev-parse HEAD)" = "$before" ] || { echo "the change branch moved"; false; }

    # An index git cannot read is not an index that is not empty: stop, say
    # so, merge nothing.
    printf '#!/bin/sh\nif [ "$3 $4" = "diff --cached" ]; then exit 128; fi\nexec %s "$@"\n' \
        "$(command -v git)" > "$stub/git"
    run env PATH="$stub:$PATH" GIT_MERGE_AUTOEDIT=no sh -c "BASE=main; $fence"
    [ "$status" -eq 1 ] || { echo "status $status with an unreadable index: $output"; false; }
    printf '%s\n' "$output" | grep -qxF "cannot read the index of $primary" \
        || { echo "not the cannot-read message: $output"; false; }
    [ "$(git rev-parse HEAD)" = "$before" ] || { echo "the change branch moved"; false; }

    # Cleared: the fence merges the new base in.
    run_step1
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    git merge-base --is-ancestor "$second" HEAD || { echo "the base was not merged"; false; }
}

@test "merge-change: a round that dispatches no reviewer skips the pre-flight before the review" {
    # verifies: REQ-x8j3ne
    # verifies: ADR-k3nkv3
    # A base-move round reruns the message only after a review; the rationale
    # names no rerun for a plan.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    rationale="$BATS_TEST_DIRNAME/../skills/merge-change/references/rationale.md"
    step_of "$skill" 2 | tr '\n' ' ' | tr -s ' ' |
        grep -qF 'Skip this step in a round that dispatches no reviewer: 6c runs every check it runs.' ||
        { echo "step 2 does not say when it is skipped"; false; }
    step_of "$skill" 7 | tr '\n' ' ' | tr -s ' ' |
        grep -qF 'rerun from step 1 as a base-move round: steps 2 to 4 only on a `shared:` line, as a review round whose rerun reaches step 5; then 6a to 7.' ||
        { echo "step 7 does not list the base-move round's steps"; false; }
    grep -qx '## Step 2: skipped when no reviewer is dispatched' "$rationale" ||
        { echo "no rationale section for skipping step 2"; false; }
    tr '\n' ' ' < "$rationale" | tr -s ' ' |
        grep -qF 'a fresh review (steps 2 to 4) only where a `shared:` line shows the base edited a file this change edits, whose rerun writes the message at step 5;' ||
        { echo "the rationale's base-move round skips the message after a review"; false; }
    if tr '\n' ' ' < "$rationale" | tr -s ' ' | grep -qF 'left a new plan whole'; then
        echo "the rationale's base-move round still reruns the record for a plan left whole"; false
    fi
}

@test "merge-change: a round with no finding is the last" {
    # verifies: REQ-5nb2wu
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    awk '
        index($0, "are all `low` is the last review round.") && index(prev, "findings, if any,") { found = 1 }
        { prev = $0 }
        END { exit !found }
    ' "$skill" || { echo "the last-round sentence does not cover a round with no finding"; false; }
}

@test "merge-change: the reviewer runs only the tests it judges" {
    # verifies: REQ-c6vc2k
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    step_4=$(step_of "$skill" 4 | tr '\n' ' ' | tr -s ' ')
    printf '%s' "$step_4" | grep -qF '**The reviewer runs only the tests it judges**' ||
        { echo "step 4 does not scope the reviewer's run"; false; }
    printf '%s' "$step_4" | grep -qF 'each `verifies:` test of a claimed ID' ||
        { echo "step 4 does not select each verifies: test of a claimed ID"; false; }
    printf '%s' "$step_4" | grep -qF 'each test file the diff adds or edits' ||
        { echo "step 4 does not select the test files the diff adds or edits"; false; }
    printf '%s' "$step_4" | grep -qF 'the whole suite where the runner cannot select' ||
        { echo "step 4 does not run the whole suite where the runner cannot select"; false; }
    if printf '%s' "$step_4" | grep -qF 'runs the suite itself'; then
        echo "step 4 still runs the whole suite"; false
    fi
}

@test "merge-change: the step 6a gate is the round's only full run" {
    # verifies: REQ-c6vc2k
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    step_4=$(step_of "$skill" 4 | tr '\n' ' ' | tr -s ' ')
    printf '%s' "$step_4" | grep -qF "6a's gate runs the whole suite" ||
        { echo "step 4 does not name 6a's gate as the full run"; false; }
    printf '%s' "$step_4" | grep -qF "A documentation-only diff's reviewer runs no tests" ||
        { echo "step 4 lost the documentation-only case"; false; }
    # Only the cannot-select fallback and 6a's gate run the whole suite.
    whole=$(printf '%s\n' "$step_4" | grep -oF 'whole suite' | wc -l | tr -d ' ')
    [ "$whole" -eq 2 ] ||
        { echo "step 4 names $whole whole-suite runs, not the fallback and 6a's gate"; false; }
}

@test "merge-change: the rationale states what scoping the reviewer costs" {
    # verifies: REQ-c6vc2k
    rationale="$BATS_TEST_DIRNAME/../skills/merge-change/references/rationale.md"
    notes="$BATS_TEST_DIRNAME/../skills/ratchet/references/upgrade-notes.md"
    section=$(section_of '## Step 4: the reviewer runs the tests it judges' "$rationale" | tr '\n' ' ' | tr -s ' ')
    [ -n "$section" ] || { echo "no rationale section for the scoped run"; false; }
    printf '%s' "$section" | grep -qF 'The step 6a gate keeps that independence.' ||
        { echo "the rationale does not state that the 6a gate keeps the counts independent"; false; }
    printf '%s' "$section" | grep -qF 'a regression outside that selection surfaces at 6a' ||
        { echo "the rationale does not state where a regression outside the selection surfaces"; false; }
    printf '%s' "$section" | grep -qF 'A diff whose claimed IDs have `verifies:` tests is not documentation-only, and its reviewer runs them.' ||
        { echo "the rationale does not settle a skill-text diff that claims tested IDs"; false; }
    printf '%s' "$section" | grep -qF 'A documentation-only diff is one whose selection is empty.' ||
        { echo "the rationale does not define a documentation-only diff by its selection"; false; }
    gate=$(section_of '## Step 6a: the gate runs after the message' "$rationale" | tr '\n' ' ' | tr -s ' ')
    printf '%s' "$gate" | grep -qF 'the reviewer runs no tests because its selection is empty' ||
        { echo "step 6a's rationale does not give the selection as the reason"; false; }
    if printf '%s' "$gate" | grep -qF 'no gate summary to hand its reviewer'; then
        echo "step 6a's rationale still gives the old reason"; false
    fi
    if grep -qx '## Step 4: the reviewer runs the suite' "$rationale"; then
        echo "the old rationale heading is still there"; false
    fi
    grep -q '^## The reviewer runs only the tests it judges$' "$notes" ||
        { echo "no upgrade note for the scoped run"; false; }
    entry=$(awk '/^## The reviewer runs only the tests it judges$/ { inside = 1; next }
        /^## / { inside = 0 } inside' "$notes" | tr '\n' ' ' | tr -s ' ')
    printf '%s' "$entry" | grep -qF 'The step 6a gate is the one full run in a review round' ||
        { echo "the upgrade note does not say the step 6a gate is the one full run"; false; }
}

@test "merge-change: the review checklist's last round covers a round with no finding" {
    # verifies: REQ-5nb2wu
    # The checklist the reviewer is handed states the same rule as the skill.
    checklist="$BATS_TEST_DIRNAME/../skills/merge-change/references/review-checklist.md"
    checklist_text=$(tr '\n' ' ' < "$checklist" | tr -s ' ')
    printf '%s\n' "$checklist_text" | grep -qF 'A round whose `code` and `requirement` findings, if any, are all `low` is the last review round' \
        || { echo "the checklist's last-round sentence does not cover a round with no finding"; false; }
}

@test "merge-change: the review checklist asks for the message only where it exists" {
    # verifies: REQ-2bdnh6
    # verifies: ADR-k3nkv3
    # The message follows the review, so a first-round reviewer has none. The
    # checklist asks for no plan.
    checklist="$BATS_TEST_DIRNAME/../skills/merge-change/references/review-checklist.md"
    checklist_text=$(tr '\n' ' ' < "$checklist" | tr -s ' ')
    printf '%s\n' "$checklist_text" | grep -qF 'from <old ID>` in the message, where the message exists.' \
        || { echo "the checklist asks every reviewer for inherited: lines in the message"; false; }
    if printf '%s\n' "$checklist_text" | grep -qF 'left whole'; then
        echo "the checklist still asks for left whole plans"; false
    fi
}

@test "merge-change: the review checklist makes a long changed item a finding with a shorter wording" {
    # verifies: ADR-k3nkv3
    # No script measures an item's length, so the step 4 reviewer judges it.
    checklist="$BATS_TEST_DIRNAME/../skills/merge-change/references/review-checklist.md"
    docs=$(section_of '## The documentation checklist' "$checklist" | tr '\n' ' ' | tr -s ' ')
    for phrase in \
        'Each item the change adds or edits states one testable behavior and carries no rationale, history or implementation detail' \
        'its text proposes the shorter wording' \
        'No script checks an item'"'"'s length' \
        'An ADR the change adds or edits holds its context, decision and consequences only'; do
        printf '%s\n' "$docs" | grep -qF -- "$phrase" \
            || { echo "the documentation checklist lacks: $phrase"; false; }
    done
}

@test "ratchet: the upgrade notes say the base merge stops on a staged squash" {
    # verifies: REQ-584wwc
    notes="$BATS_TEST_DIRNAME/../skills/ratchet/references/upgrade-notes.md"
    entry=$(awk '/^## The merge steps are renumbered/ { on = 1; next } on && /^## / { exit } on' "$notes" | tr '\n' ' ' | tr -s ' ')
    [ -n "$entry" ] || { echo "no renumbering entry"; false; }
    printf '%s\n' "$entry" | grep -qF 'Step 1 now stops when the index of the primary checkout is not empty, or cannot be read' \
        || { echo "the renumbering entry does not announce step 1's new stop"; false; }
    printf '%s\n' "$entry" | grep -qF 'It also stops when the primary checkout cannot be found' \
        || { echo "the renumbering entry does not announce the missing-primary stop"; false; }
}

@test "merge-change: it starts after develop-change, since the gate runs inside it" {
    # verifies: REQ-ssfur7
    # The gate runs inside merge-change after the record, so neither the
    # description nor a precondition can require verify-before-merge first.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    run grep -n -e 'passed verify-before-merge' -e '`verify-before-merge` passed' "$skill"
    [ "$status" -eq 1 ] || { echo "still requires verify-before-merge first: $output"; false; }
    grep '^description: ' "$skill" | grep -qF 'develop-change' \
        || { echo "the description does not say it follows develop-change"; false; }
    preconditions=$(section_of '## Preconditions' "$skill" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$preconditions" | grep -qF '`develop-change` is done, its suite green' \
        || { echo "the precondition does not name develop-change"; false; }
}

@test "merge-change: the gate runs after the message, on the tree that is signed" {
    # verifies: REQ-4wm324
    # verifies: ADR-k3nkv3
    # The message is written before the gate, so one gate per round measures
    # the tree step 7 squashes, and 6b names that tree in the message.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    labels=$(grep -E '^[0-9]+[a-d]?\. \*\*' "$skill" | sed 's/\. .*//' | tr '\n' ' ')
    [ "$labels" = '1 2 3 4 5 6a 6b 6c 6d 7 8 ' ] || { echo "step labels: $labels"; false; }
    step_6a=$(step_of "$skill" 6a)
    printf '%s\n' "$step_6a" | grep -q '^6a\. \*\*Dispatch the verification suite\*\*' \
        || { echo "6a is not the gate: $step_6a"; false; }
    step_6b=$(step_of "$skill" 6b)
    printf '%s\n' "$step_6b" | grep -q '^6b\. \*\*Confirm the step 6a summary describes this tree\*\*' \
        || { echo "6b is not the tree check: $step_6b"; false; }
    printf '%s\n' "$step_6b" | grep -qF 'git rev-parse HEAD^{tree}' \
        || { echo "6b does not compare the tree: $step_6b"; false; }
    record_at=$(grep -n '^5\. \*\*Squash message\*\*' "$skill" | cut -d: -f1)
    gate_at=$(grep -n '^6a\. \*\*' "$skill" | cut -d: -f1)
    if [ -z "$record_at" ] || [ -z "$gate_at" ] || [ "$record_at" -ge "$gate_at" ]; then
        echo "the message ('$record_at') does not precede the gate ('$gate_at')"; false
    fi
    printf '%s\n' "$step_6b" | tr '\n' ' ' | tr -s ' ' | grep -qF '`Gate-tree:` the step 6a tree' \
        || { echo "step 6b does not write the step 6a tree into the message"; false; }
}

@test "merge-change: a late gate's costs are stated: a reviewer for its fix, and no suite for a docs-only review" {
    # verifies: REQ-4wm324
    # The gate follows the review, so its failure's fix needs a reviewer, and a
    # documentation-only diff has no earlier gate summary for its reviewer.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    step_4=$(step_of "$skill" 4 | tr '\n' ' ' | tr -s ' ')
    [ -n "$step_4" ]
    printf '%s\n' "$step_4" | grep -qF "A documentation-only diff's reviewer runs no tests; the message states it." \
        || { echo "step 4 does not say a documentation-only diff's reviewer runs no tests"; false; }
}

@test "merge-change: the review checklist checks the plan against the diff, and names no pruning" {
    # verifies: ADR-k3nkv3
    checklist="$BATS_TEST_DIRNAME/../skills/merge-change/references/review-checklist.md"
    checklist_text=$(tr '\n' ' ' < "$checklist" | tr -s ' ')
    printf '%s\n' "$checklist_text" | grep -q 'the prose of each task matches the diff' ||
        { echo "no prose check"; false; }
    if printf '%s\n' "$checklist_text" | grep -qiF 'prune'; then echo "the checklist still names pruning"; false; fi
    if printf '%s\n' "$checklist_text" | grep -qF 'left whole'; then echo "the checklist still names a left whole plan"; false; fi
}

@test "plan-change: the plan stays on the change branch" {
    # verifies: ADR-k3nkv3
    skill="$BATS_TEST_DIRNAME/../skills/plan-change/SKILL.md"
    skill_text=$(tr '\n' ' ' < "$skill" | tr -s ' ')
    printf '%s\n' "$skill_text" | grep -qF 'dropped before the gate (`drop-plans.sh`, `merge-change` step 5)' ||
        { echo "plan-change does not name drop-plans.sh and merge-change step 5"; false; }
    if grep -qF 'prune-plans.sh' "$skill"; then echo "plan-change still names prune-plans.sh"; false; fi
}

@test "ratchet: the upgrade notes withdraw prune_plans" {
    # verifies: ADR-k3nkv3
    notes="$BATS_TEST_DIRNAME/../skills/ratchet/references/upgrade-notes.md"
    grep -qx '## Plans are dropped before the gate' "$notes" ||
        { echo "no section for dropped plans"; false; }
    if grep -qF '## Plans are pruned at merge' "$notes"; then echo "the pruning section is still there"; false; fi
    section=$(awk '/^## Plans are dropped before the gate$/ { inside = 1; next }
                   inside && /^## / { exit }
                   inside' "$notes" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$section" | grep -qF '`prune_plans` is a withdrawn config key' ||
        { echo "the section does not call prune_plans withdrawn"; false; }
    printf '%s\n' "$section" | grep -qF 'delete the `prune_plans` line' ||
        { echo "the section does not say to delete prune_plans"; false; }
    printf '%s\n' "$section" | grep -qF 'delete `.guardrails/scripts/prune-plans.sh`' ||
        { echo "the section does not say to delete the stale prune-plans.sh"; false; }
    printf '%s\n' "$section" | grep -qF 'exits 2' ||
        { echo "the section does not say a config holding it exits 2"; false; }
    printf '%s\n' "$section" | grep -qF '`PLANS` check fails a change that adds or edits a plan' ||
        { echo "the section does not name the PLANS check"; false; }
}

@test "ratchet: the upgrade notes name review_cite, its default and how to opt in" {
    # verifies: REQ-7wref3
    notes="$BATS_TEST_DIRNAME/../skills/ratchet/references/upgrade-notes.md"
    grep -q '^## Dispositions cite what they changed: `review_cite`$' "$notes" ||
        { echo "no review_cite section"; false; }
    section=$(awk '/^## Dispositions cite what they changed: `review_cite`$/ { inside = 1; next }
                   inside && /^## / { exit }
                   inside' "$notes" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$section" | grep -qF '`review_cite: on`' ||
        { echo "no opt-in key"; false; }
    printf '%s\n' "$section" | grep -qF -- '--cite' ||
        { echo "no --cite flag"; false; }
    printf '%s\n' "$section" | grep -qF 'an absent `review_cite` is `off`' ||
        { echo "no default"; false; }
}

@test "squash message template: a disposition cites a path, a test name or an item ID, or says no change" {
    # verifies: ADR-3hsvvq
    # The template shows the three disposition forms; what a citation may
    # name is check-review.sh's, stated in its header.
    template="$BATS_TEST_DIRNAME/../templates/squash-message.txt"
    for form in '[fixed: <cite>, …]' '[open: <cite>]' '[no change: <reason>]'; do
        grep -qF -- "$form" "$template" || { echo "the template lacks the form $form"; false; }
    done
    header=$(sed -n '1,/^set -u/p' "$BATS_TEST_DIRNAME/../scripts/check-review.sh" | tr '\n' ' ' | tr -s ' ')
    for named in 'UNRESOLVABLE-DISPOSITION' '`no change: <reason>`' 'test_paths' 'find-items.sh show'; do
        printf '%s\n' "$header" | grep -qF -- "$named" ||
            { echo "check-review.sh's header does not name: $named"; false; }
    done
}

@test "squash message template: nothing follows the trailer paragraph, Co-Authored-By included" {
    # verifies: ADR-3hsvvq
    # git reads trailers only from the last paragraph: a line appended after a
    # blank line becomes that paragraph and hides every trailer above it.
    template="$BATS_TEST_DIRNAME/../templates/squash-message.txt"
    guidance=$(sed -n 's/^# *//p' "$template" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$guidance" | grep -qF 'No Co-Authored-By: and nothing after the trailer paragraph' ||
        { echo "the template does not forbid lines after the trailers"; false; }
}

@test "squash message template and upgrade notes: a guideline finding cites as a code finding does" {
    # verifies: REQ-x9mq37
    # verifies: ADR-k3nkv3
    # check-review.sh --cite checks a guideline finding's disposition too: the
    # template gives guideline findings the same line and dispositions as code
    # findings, and the upgrade note names `guideline` among them.
    template="$BATS_TEST_DIRNAME/../templates/squash-message.txt"
    notes="$BATS_TEST_DIRNAME/../skills/ratchet/references/upgrade-notes.md"
    tr '\n' ' ' < "$template" | tr -s ' ' | grep -qF 'Tags: code, requirement, guideline (each with a severity' ||
        { echo "the template does not give guideline findings a tag and severity"; false; }
    section=$(awk '/^## Dispositions cite what they changed: `review_cite`$/ { inside = 1; next }
                   inside && /^## / { exit }
                   inside' "$notes" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$section" | grep -qF '`code`, `requirement` or `guideline` finding' ||
        { echo "the upgrade note does not name guideline findings"; false; }
}

@test "ADRs: the ledger-naming decision is recorded and accepted" {
    # verifies: ADR-cy7ahd
    # The ID is built from a prefix variable: the gates scan tests/.
    adr_prefix=ADR
    adr_file="$BATS_TEST_DIRNAME/../docs/adr/$adr_prefix-cy7ahd-ledger-files-named-at-creation.md"
    [ -f "$adr_file" ] || { echo "no $adr_file"; false; }
    adr_file_is_named_by_its_item "$adr_file"
    grep -qx 'Status: accepted' "$adr_file"
    adr_text=$(tr '\n' ' ' < "$adr_file" | tr -s ' ')
    for wanted in '`docs/<area>/<YYYY-MM-DD>-<slug>.md`' 'finalize-docs.sh' \
            'add/add conflict' 'PR-8ucezf' '`DRAFT-FILE`' '`DANGLING-FILE`'; do
        printf '%s\n' "$adr_text" | grep -qF -- "$wanted" \
            || { echo "the ADR lacks $wanted"; false; }
    done
}

@test "ADRs: the gate-proof decision is recorded, and the base statement is the Base: trailer" {
    # verifies: ADR-f6ytg7, ADR-y8jmes
    # The IDs are built from a prefix variable: the gates scan tests/.
    adr_prefix=ADR
    root="$BATS_TEST_DIRNAME/.."
    adr_file="$root/docs/adr/$adr_prefix-f6ytg7-squash-commit-certifies-the-gate.md"
    [ -f "$adr_file" ] || { echo "no $adr_file"; false; }
    adr_file_is_named_by_its_item "$adr_file"
    grep -qx 'Status: accepted' "$adr_file"
    adr_text=$(tr '\n' ' ' < "$adr_file" | tr -s ' ')
    for wanted in '`Gate-tree:`' '`Tests:`' '`Coverage:`' '`Base:`' 'finish-merge.sh' \
            "guard 5 refuses the cleanup, removing nothing, unless the signed message passes the $adr_prefix-3hsvvq check" \
            'git write-tree' 'cannot name the commit or tree it is part of' "$adr_prefix-y8jmes"; do
        printf '%s\n' "$adr_text" | grep -qF -- "$wanted" \
            || { echo "the ADR lacks $wanted"; false; }
    done
    for unwanted in '`Gate:`' 'verification record' 'templates/verification.md' 'Amended'; do
        if printf '%s\n' "$adr_text" | grep -qF -- "$unwanted"; then
            echo "the ADR still says $unwanted"; false
        fi
    done
    printf '%s\n' "$adr_text" | grep -qF 'tree checks, `check-ids.sh` and `check-trace.sh`, can be rerun on the tree `Gate-tree:` names' \
        || { echo "the ADR does not limit the rerun to the tree checks"; false; }
    if printf '%s\n' "$adr_text" | grep -qF 'anyone can run them again on the tree'; then
        echo "the ADR still says every halting check reruns on the named tree"; false
    fi
    statement='Base: local main at <commit>, per AGENTS.md non-negotiable 4'
    base_adr="$root/docs/adr/$adr_prefix-y8jmes-local-main-is-the-base.md"
    for file in "$root/AGENTS.md" "$base_adr"; do
        tr '\n' ' ' < "$file" | tr -s ' ' | grep -qF -- "$statement" \
            || { echo "$file does not state the Base: trailer"; false; }
    done
    tr '\n' ' ' < "$base_adr" | tr -s ' ' | grep -qF "$adr_prefix-f6ytg7" \
        || { echo "the base ADR does not name the decision that placed its statement"; false; }
    tr '\n' ' ' < "$base_adr" | tr -s ' ' | grep -qF 'the `Base:` trailer is where a change names its base commit' \
        || { echo "the base ADR does not say the Base: trailer names the base commit"; false; }
    run grep -n 'State it in the verification record' "$root/AGENTS.md"
    [ "$status" -eq 1 ] || { echo "AGENTS.md still puts the base in the record: $output"; false; }
}

@test "merge-change: the forge flow after the push is an open item, not a procedure" {
    # verifies: ADR-f6ytg7
    # A forge rebase or squash merge after the push replaces the signed
    # squash; how pull requests land is undecided, so the ADR says so, the
    # ledger holds the open item, and no reference ships a recipe for it.
    # The IDs are built from prefix variables: the gates scan tests/.
    adr_prefix=ADR
    pr_prefix=PR
    root="$BATS_TEST_DIRNAME/.."
    ledger="$root/docs/problems/2026-10-14-gate-proof-in-trailers.md"
    grep -q "^\*\*$pr_prefix-m7gcuq\*\*: " "$ledger" || { echo "the ledger has no forge-flow item"; false; }
    item=$(awk -v id="**$pr_prefix-m7gcuq**: " 'index($0, id) == 1 { inside = 1 }
        inside && /^$/ { exit } inside' "$ledger")
    printf '%s\n' "$item" | grep -qx 'status: open' || { echo "the item is not open: $item"; false; }
    printf '%s\n' "$item" | grep -qF "$pr_prefix-yd4pug" || { echo "the item does not relate to the fetched-base item"; false; }
    consequences=$(section_of '## Consequences' \
        "$root/docs/adr/$adr_prefix-f6ytg7-squash-commit-certifies-the-gate.md" | tr '\n' ' ' | tr -s ' ')
    for wanted in 'How pull requests land is undecided.' 'replaces the signed squash' 'nothing in guardrails re-checks `Gate-tree:`'; do
        printf '%s\n' "$consequences" | grep -qF -- "$wanted" \
            || { echo "the ADR's Consequences lack: $wanted"; false; }
    done
    for unwanted in 'references/setup-checklist.md' 'references/cleanup-rejections.md'; do
        if printf '%s\n' "$consequences" | grep -qF -- "$unwanted"; then
            echo "the ADR's Consequences still point at a forge recipe: $unwanted"; false
        fi
    done
    rejections="$root/skills/merge-change/references/cleanup-rejections.md"
    run grep -n -i 'rebase' "$rejections"
    [ "$status" -eq 1 ] || { echo "cleanup-rejections.md still has a rebase procedure: $output"; false; }
    run grep -n 'Gate-tree' "$root/skills/ratchet/references/setup-checklist.md"
    [ "$status" -eq 1 ] || { echo "the setup checklist still has a Gate-tree CI recipe: $output"; false; }
    references=$(section_of '## References' "$root/skills/merge-change/SKILL.md" | tr '\n' ' ' | tr -s ' ')
    if printf '%s\n' "$references" | grep -qF 'rebased'; then
        echo "the References line still sends a rebase to cleanup-rejections.md"; false
    fi
}

@test "AGENTS.md: non-negotiable 2 says finish-merge.sh checks the Gate-tree trailer" {
    # verifies: ADR-f6ytg7
    agents="$BATS_TEST_DIRNAME/../AGENTS.md"
    text=$(tr '\n' ' ' < "$agents" | tr -s ' ')
    printf '%s\n' "$text" | grep -qF \
        'verifies the signature, and that the signed message passes the squash message check, its `Gate-tree:` trailer naming the commit'"'"'s own tree, before it removes anything' \
        || { echo "non-negotiable 2 does not name the message check"; false; }
    # verifies: ADR-k3nkv3
    # The record is the message: non-negotiable 4's directed merge is named
    # there, and the Base: trailer is written at merge-change step 6b.
    printf '%s\n' "$text" | grep -qF 'as the subject of a change whose squash message names whose decision it was' \
        || { echo "non-negotiable 4 still names a verification record"; false; }
    printf '%s\n' "$text" | grep -qF 'State it in the squash commit'"'"'s `Base:` trailer (`merge-change` step 6b)' \
        || { echo "non-negotiable 4 names the wrong step for Base:"; false; }
}

@test "worktree-discipline: the squash message holds the reviews, and its trailers hold what was run" {
    # verifies: ADR-3hsvvq
    # verifies: ADR-k3nkv3
    skill="$BATS_TEST_DIRNAME/../skills/worktree-discipline/SKILL.md"
    text=$(tr '\n' ' ' < "$skill" | tr -s ' ')
    printf '%s\n' "$text" | grep -qF '**the squash message** (`merge-change`) — reviews, dispositions, red -> green, gaps' \
        || { echo "the message's contents are not stated"; false; }
    printf '%s\n' "$text" | grep -qF "its trailers hold what was run and what it reported" \
        || { echo "the trailers are not named"; false; }
    run grep -n 'what was run and *$' "$skill"
    [ "$status" -eq 1 ] || { echo "the old description remains: $output"; false; }
}

# --- test guidelines ---------------------------------------------------------
# The seam and double rules are clauses of templates/TEST_GUIDELINES.md
# (tests/test-guidelines.bats pins them there). The floor and the one-file rule belong to the TDD loop,
# which develop-tdd holds, and
# tests/develop-tdd.bats pins them there; develop-change holds the dispatch.

@test "develop-change: it is the dispatcher, which no subagent loads" {
    # verifies: REQ-da5xd8
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -qxF 'name: develop-change' "$skill"
    description=$(grep '^description: ' "$skill")
    printf '%s\n' "$description" | grep -qF 'develop-tdd' || { echo "the description does not name develop-tdd"; false; }
    printf '%s\n' "$description" | grep -qF 'review-conformance' || { echo "the description does not name review-conformance"; false; }
    preconditions=$(section_of '## Preconditions' "$skill" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$preconditions" | grep -qF 'A task subagent loads `develop-tdd`, a reviewer loads `review-conformance`, and a fixer loads `develop-tdd` or `develop-refactor`, never this skill.'
}

@test "develop-change: task subagents load develop-tdd, and the loop is stated there, not here" {
    # verifies: REQ-da5xd8
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    prompt=$(awk '/^  Execute task 3 of/ { inside = 1 } inside && /^  ```$/ { inside = 0 } inside' "$skill" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$prompt" | grep -qF 'under the develop-tdd skill' || { echo "the prompt does not name develop-tdd"; false; }
    for moved in '**No production code without a failing test first.**' '### The loop, one behavior at a time' \
        '**Class rules.**' '**Bugs.**' '### Test guidelines' 'task: <ID>' 'inherited: <test name> — from <old ID>'; do
        if grep -qF -- "$moved" "$skill"; then echo "develop-change still states: $moved"; false; fi
    done
}

@test "develop-change: the task prompt names the guidelines file guidelines-file.sh TEST printed" {
    # verifies: REQ-f8xaq4
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    grep -qF 'the guidelines file `guidelines-file.sh TEST` printed for' "$skill"
}

@test "develop-change: the conformance reviews follow derailment, before merge-change" {
    # verifies: REQ-br59wv
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    headings=$(grep '^### ' "$skill")
    last_heading=$(printf '%s\n' "$headings" | tail -n 1)
    [ "$last_heading" = '### The conformance reviews' ] || { echo "last section: '$last_heading'"; false; }
    if printf '%s\n' "$headings" | grep -qxF '### The guideline reviews'; then echo "the old heading remains"; false; fi
    section=$(section_of '### The conformance reviews' "$skill")
    printf '%s\n' "$section" | grep -qF '`review-conformance`'
    printf '%s\n' "$section" | grep -qF 'into the squash message as `guideline` findings'
    printf '%s\n' "$section" | grep -qF '`merge-change`, not at its step 4'
}

@test "develop-change: guideline review findings go into the plan as they arrive, and merge-change's message copies them" {
    # verifies: REQ-e5ze3h
    # verifies: ADR-k3nkv3
    # The reviews run before merge-change, so their findings wait in the plan
    # as the red -> green lines do; step 4 reads them there, and step 5 copies them
    # into the record it writes after step 4.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    section=$(section_of '### The conformance reviews' "$skill" | tr '\n' ' ' | tr -s ' ')
    if printf '%s\n' "$section" | grep -qF 'which `merge-change` step 6b fills in'; then
        echo "still says step 6b fills in the guideline reviews"; false
    fi
    printf '%s\n' "$section" | grep -qF 'Write each finding and its disposition into the plan as it arrives, as the `red -> green:` lines are'
    printf '%s\n' "$section" | grep -qF '`merge-change` step 5 copies them into the squash message as `guideline` findings'
    merge="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    record_step=$(step_of "$merge" 5 | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$record_step" | grep -qF "the guideline reviews' findings from the plan among them, tagged \`guideline\`"
}

@test "develop-change: the dispatch prompt names the guidelines file for each of the task's paths" {
    # verifies: REQ-f8xaq4
    # A task whose paths span units has more than one governing file; the
    # prompt carries every line guidelines-file.sh printed.
    skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
    prompt=$(awk '/^  Execute task 3 of/ { inside = 1 } inside && /^  ```$/ { inside = 0 } inside' "$skill" | tr '\n' ' ' | tr -s ' ')
    [ -n "$prompt" ] || { echo "no dispatch prompt template"; false; }
    printf '%s\n' "$prompt" | grep -qF 'For each of the task'"'"'s paths, follow the guidelines file `guidelines-file.sh TEST` printed for it'
    printf '%s\n' "$prompt" | grep -qF '<file>: <paths> (one line per file it printed)'
}

@test "develop-change: the seam reference files are gone" {
    # verifies: REQ-f8rfhr
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
    # verifies: REQ-buf8y3
    # The seam and double rules are a project's preference, checked by
    # review-conformance against its own file; step 4 holds the floor alone and
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
    # The plan holds the guideline reviews when step 4 runs; step 5 copies them into
    # the record afterwards.
    printf '%s\n' "$section" | grep -qF 'the plan lists a conformance review for each file `guidelines-file.sh TEST` prints for the diff'
    printf '%s\n' "$section" | grep -qF 'and for each file `guidelines-file.sh CODE` prints for it'
    printf '%s\n' "$section" | grep -qF 'every finding with a disposition'
    # verifies: ADR-k3nkv3
    printf '%s\n' "$section" | grep -qF 'and the message holds them as `guideline` findings where the message exists'
    for removed in 'three kinds' 'markup snapshot' 'runs for real on the normal path'; do
        if grep -qF "$removed" "$checklist"; then echo "checklist still states: $removed"; false; fi
    done
}

@test "squash message template: guideline review findings are tagged apart from the review's" {
    # verifies: REQ-4kyacv
    # verifies: ADR-k3nkv3
    # The `guideline` tag keeps a preference finding apart from a compliance
    # finding in the one Findings: section, as the separate section did.
    template="$BATS_TEST_DIRNAME/../templates/squash-message.txt"
    flat=$(tr '\n' ' ' < "$template" | tr -s ' ')
    printf '%s\n' "$flat" | grep -qF 'Tags: code, requirement, guideline (each with a severity' \
        || { echo "the template does not tag guideline findings apart"; false; }
    printf '%s\n' "$flat" | grep -qF 'and record (none)' \
        || { echo "the template gives a record finding a severity"; false; }
    if grep -q '^## ' "$template"; then echo "the message template still has record sections"; false; fi
}

@test "ratchet: the upgrade notes say ledger files are named at creation, and how to rename a draft in flight" {
    # verifies: REQ-2jr68c
    # verifies: ADR-k3nkv3
    notes="$BATS_TEST_DIRNAME/../skills/ratchet/references/upgrade-notes.md"
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q '^## Ledger files are named at creation$' "$notes" || { echo "no section"; false; }
    section=$(awk '/^## Ledger files are named at creation$/ { inside = 1; next }
        /^## / { inside = 0 } inside' "$notes" | tr '\n' ' ' | tr -s ' ')
    for wanted in 'finalize-docs.sh' '`--allow-draft-files`' 'git mv' \
            'DANGLING-FILE' 'add/add conflict' '<YYYY-MM-DD>-<slug>.md'; do
        printf '%s\n' "$section" | grep -qF -- "$wanted" \
            || { echo "the section lacks $wanted"; false; }
    done
    notes_text=$(tr '\n' ' ' < "$notes" | tr -s ' ')
    printf '%s\n' "$notes_text" | grep -qF '("Ledger files are named at creation" below)' \
        || { echo "order of work does not point at the section"; false; }
    skill_text=$(tr '\n' ' ' < "$skill" | tr -s ' ')
    # prune-plans.sh is gone too: a stale copy would still prune if run.
    printf '%s\n' "$skill_text" | grep -qF 'Delete `.guardrails/scripts/finalize-ids.sh`, `finalize-docs.sh` and `prune-plans.sh` if present.' \
        || { echo "the upgrade does not delete finalize-docs.sh and prune-plans.sh"; false; }
    printf '%s\n' "$skill_text" | grep -qF '`YYYY-MM-DD-<slug>.md`, dated the day the change creates it' \
        || { echo "ratchet still describes a rename"; false; }
    if grep -q 'DRAFT-<branch>-<slug>' "$skill"; then
        echo "ratchet still names the draft convention"; false
    fi
}

@test "ratchet: the upgrade notes say the squash commit certifies the gate, and how to repair a squash without its trailer" {
    # verifies: REQ-7q6gv7
    notes="$BATS_TEST_DIRNAME/../skills/ratchet/references/upgrade-notes.md"
    grep -q '^## The squash commit certifies the gate$' "$notes" || { echo "no section"; false; }
    section=$(awk '/^## The squash commit certifies the gate$/ { inside = 1; next }
        /^## / { inside = 0 } inside' "$notes" | tr '\n' ' ' | tr -s ' ')
    for wanted in '`Gate-tree:`' '`finish-merge.sh`' 'git 2.22' 'last paragraph' \
            'git commit --amend -S' '`Measured on:`' 'log.showSignature' 'exit 1' \
            '%(trailers:key=Gate-tree,valueonly,unfold)' 'its `Gate-tree:` is the tree a gate measured' \
            'If no gate measured HEAD'"'"'s tree, dispatch the gate on it first' 'the guard 5 remedy'; do
        printf '%s\n' "$section" | grep -qF -- "$wanted" \
            || { echo "the section lacks $wanted"; false; }
    done
    if printf '%s\n' "$section" | grep -qF 'references/setup-checklist.md'; then
        echo "the section still adds a CI check for the forge flow"; false
    fi
}

@test "ratchet: step 5 writes the squash message early, with the setup checklist under Qualification:" {
    # verifies: ADR-k3nkv3
    # Greenfield and upgrade write no plan, so the filled checklist, the tool
    # qualification record, cannot wait in one. Ratchet step 5 writes the
    # change's squash message there and then; merge-change step 5 updates
    # that message and keeps what is in it.
    root="$BATS_TEST_DIRNAME/.."
    step5=$(ratchet_step 5)
    opening=$(awk '/^- \[ \]/ { exit } { print }' \
        "$root/skills/ratchet/references/setup-checklist.md" | tr '\n' ' ' | tr -s ' ')
    for passage in "$step5" "$opening"; do
        printf '%s\n' "$passage" | grep -qF 'copy `.guardrails/templates/squash-message.txt` to the path `gr_message_file` prints' \
            || { echo "does not write the message early: $passage"; false; }
        printf '%s\n' "$passage" | grep -qF 'under a `Qualification:` section in its body' \
            || { echo "the checklist has no place in the message: $passage"; false; }
        if printf '%s\n' "$passage" | grep -qF -e 'docs/verification' -e 'verification.md'; then
            echo "still writes a record file: $passage"; false
        fi
        if printf '%s\n' "$passage" | grep -qF "the change's plan"; then
            echo "still kept in the plan: $passage"; false
        fi
    done
    merge5=$(step_of "$root/skills/merge-change/SKILL.md" 5 | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$merge5" | grep -qF 'Copy `.guardrails/templates/squash-message.txt` to `$msg`, or update it where it exists: fill in only what is missing' \
        || { echo "merge-change step 5 does not update an existing message"; false; }
    if printf '%s\n' "$merge5" | grep -qF 'Tool qualification'; then
        echo "merge-change step 5 still copies the plan's tool qualification"; false
    fi
}

@test "squash message template: names the Qualification: section ratchet writes and every trailer step 6b adds" {
    # verifies: ADR-k3nkv3
    template="$BATS_TEST_DIRNAME/../templates/squash-message.txt"
    grep -qx 'Qualification:' "$template" ||
        { echo "the template has no Qualification: section"; false; }
    header=$(awk '!/^#/ { exit } { sub(/^# */, ""); print }' "$template" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$header" | grep -qF 'Step 6b adds Base:, Gate-tree:, Tests: and Coverage:' ||
        { echo "the header does not name every step 6b trailer: $header"; false; }
    merge6b=$(tr '\n' ' ' < "$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md" | tr -s ' ')
    printf '%s\n' "$merge6b" | grep -qF 'replacing an earlier round'"'"'s: `Base: <base ref> at <commit>`' ||
        { echo "merge-change step 6b no longer writes Base:"; false; }
}

# --- the record is the squash message (ADR-k3nkv3)

@test "ratchet: greenfield installs the message template and creates no docs/verification" {
    # verifies: ADR-k3nkv3
    root="$BATS_TEST_DIRNAME/.."
    # The upgrade section names the record template and key only to delete them.
    skill=$(awk '/^### Upgrading the scripts/ { skip = 1; next } /^##/ { skip = 0 } !skip' \
        "$root/skills/ratchet/SKILL.md" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$skill" | grep -qF 'Create `docs/adr/` and `docs/plans/`, and copy `templates/squash-message.txt` → `.guardrails/templates/squash-message.txt`.' ||
        { echo "greenfield does not install the message template"; false; }
    for text in "$skill" "$(cat "$root/skills/ratchet/references/rationale.md" "$root/skills/ratchet/references/multi-unit.md")"; do
        if printf '%s\n' "$text" | grep -qF -e 'docs/verification' -e 'templates/verification.md' -e 'doc_verification'; then
            echo "ratchet still writes or names a record file"; false
        fi
    done
}

@test "ratchet: the setup checklist runs check-review.sh only on the message, never with --branch" {
    # verifies: ADR-k3nkv3
    checklist=$(tr '\n' ' ' < "$BATS_TEST_DIRNAME/../skills/ratchet/references/setup-checklist.md" | tr -s ' ')
    if printf '%s\n' "$checklist" | grep -qF -- '--branch'; then
        echo "the checklist still runs check-review.sh --branch in CI"; false
    fi
    printf '%s\n' "$checklist" | grep -qF 'after signing, `finish-merge.sh` runs the same check on the signed message' ||
        { echo "the checklist does not say where the message is checked"; false; }
}

@test "ratchet: the upgrade deletes the record template and the doc_verification line, and refreshes the message template" {
    # verifies: ADR-k3nkv3
    upgrade=$(awk '/^### Upgrading the scripts/ { inside = 1; next } /^##/ { inside = 0 } inside' \
        "$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$upgrade" | grep -qF 'Delete `.guardrails/templates/verification.md` and every `doc_verification` config line.' ||
        { echo "the upgrade keeps the record template or the key: $upgrade"; false; }
    printf '%s\n' "$upgrade" | grep -qF 'Re-copy the four ledger READMEs and the squash message template' ||
        { echo "the upgrade does not refresh the message template"; false; }
}

@test "ratchet: the upgrade notes say the record is the squash message" {
    # verifies: ADR-k3nkv3
    notes="$BATS_TEST_DIRNAME/../skills/ratchet/references/upgrade-notes.md"
    grep -qx '## The record is the squash message' "$notes" || { echo "no section"; false; }
    section=$(awk '/^## The record is the squash message$/ { inside = 1; next }
        inside && /^## / { exit } inside' "$notes" | tr '\n' ' ' | tr -s ' ')
    for wanted in '`doc_verification`' 'Delete its line' '`.guardrails/templates/verification.md`' \
            '`templates/squash-message.txt`' '`check-review.sh` reads the message' \
            '`--branch` is gone' '`Tests:` replaces `Gate:`' 'gr_message_check' \
            '`docs/verification/` are left' 'lean-records' '`Mutation: <path>:<line>'; do
        printf '%s\n' "$section" | grep -qF -- "$wanted" || { echo "the section lacks $wanted"; false; }
    done
}

@test "ratchet: the upgrade notes name the refusals an adopter's message meets" {
    # verifies: ADR-3hsvvq
    notes="$BATS_TEST_DIRNAME/../skills/ratchet/references/upgrade-notes.md"
    section=$(awk '/^## The record is the squash message$/ { inside = 1; next }
        inside && /^## / { exit } inside' "$notes" | tr '\n' ' ' | tr -s ' ')
    for wanted in 'Without exactly one non-empty `Base:`, the checker reports `BASE`.' \
            '`fixed: <cite>, …`, `open: <cite>` or `no change: <reason>`' \
            'the checker reports `MALFORMED-FINDING`.' \
            'at least one `Tests:`, also with no configuration or no `verify_commands` entry' \
            'the checker reports `TESTS`.' 'the checker reports `COVERAGE`.' 'counts as missing'; do
        printf '%s\n' "$section" | grep -qF -- "$wanted" || { echo "the section lacks $wanted"; false; }
    done
}

@test "grill-requirements: a changed behavior gets a new ID and the old item is deleted" {
    # verifies: ADR-k3nkv3
    skill="$BATS_TEST_DIRNAME/../skills/grill-requirements/SKILL.md"
    section=$(awk '/^### Changing an item$/ { inside = 1; next }
        inside && /^##/ { exit } inside' "$skill" | tr '\n' ' ' | tr -s ' ')
    for wanted in '**Same behavior, reworded:** edit the item in place and keep its ID.' \
            '**Behavior changed:** mint a new ID with `new-id.sh`, write the new item and delete the old one.' \
            'records `old → new` under `Items:`' \
            '**Behavior gone:** delete the item.' \
            '`inherited: <test> — from <old ID>`' '`DANGLING-REF`' '`SUPERSESSION-ANNOTATION`'; do
        printf '%s\n' "$section" | grep -qF -- "$wanted" || { echo "the section lacks $wanted"; false; }
    done
    if grep -rnE 'superseded-by: <new ID>|supersedes: <old ID>|retired: YYYY-MM-DD' "$BATS_TEST_DIRNAME/../skills"; then
        echo "a skill still tells an author to annotate a changed item"; false
    fi
}

@test "resolve-problem: a resolved problem report is deleted by the fixing change" {
    # verifies: ADR-k3nkv3
    skill="$BATS_TEST_DIRNAME/../skills/resolve-problem/SKILL.md"
    step4=$(awk '/^### 4\./ { inside = 1; next } inside && /^##/ { exit } inside' "$skill" \
        | tr '\n' ' ' | tr -s ' ')
    for wanted in 'delete the PR item from the dated ledger file that defines it' \
            'names it in `Resolves:`' '`PR-<ID> — <cause> → <fix>` under `Problems:`' \
            'verifies the lowest-level item the defect broke, never the PR'; do
        printf '%s\n' "$step4" | grep -qF -- "$wanted" || { echo "step 4 lacks $wanted"; false; }
    done
    if grep -nF 'set `status: resolved`' "$skill"; then echo "the skill still sets status: resolved"; false; fi
}

@test "ratchet: the upgrade names the problem and supersession codes existing ledgers report" {
    # verifies: ADR-k3nkv3
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    flat=$(tr '\n' ' ' < "$skill" | tr -s ' ')
    printf '%s\n' "$flat" | grep -qF 'Existing ledgers report problem `status:`/`opened:`, `RESOLVED-PROBLEM`, `SUPERSESSION-ANNOTATION` and `DANGLING-FILE`.' \
        || { echo "the upgrade does not name what existing ledgers report"; false; }
    if grep -nF 'reciprocity' "$skill"; then echo "the upgrade still names supersession reciprocity"; false; fi
}

@test "every file that says what a regression test verifies states the one rule" {
    # verifies: ADR-k3nkv3
    root="$BATS_TEST_DIRNAME/.."
    rule="the lowest-level item the defect broke: the LLR where one exists, else the REQ (or the RC's implementing REQ)"
    step3=$(awk '/^### 3\./ { inside = 1; next } inside && /^##/ { exit } inside' \
        "$root/skills/resolve-problem/SKILL.md" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$step3" | grep -qF -- "$rule" || { echo "resolve-problem step 3 lacks the rule"; false; }
    done_when=$(section_of '## Done when' "$root/skills/resolve-problem/SKILL.md" | tr '\n' ' ' | tr -s ' ')
    printf '%s\n' "$done_when" | grep -qF -- "$rule" || { echo "resolve-problem Done when lacks the rule"; false; }
    for file in templates/problems.md templates/AGENTS-block.md templates/TEST_GUIDELINES.md \
            docs/TEST_GUIDELINES.md skills/merge-change/references/review-checklist.md \
            skills/develop-tdd/SKILL.md skills/resolve-problem/references/rationale.md \
            docs/adr/ADR-k3nkv3-code-and-signed-history-are-the-record.md; do
        flat=$(tr '\n' ' ' < "$root/$file" | tr -s ' ')
        printf '%s\n' "$flat" | grep -qF -- "$rule" || { echo "$file lacks the rule"; false; }
    done
    if grep -rnF 'the REQ the defect broke' "$root/skills" "$root/templates" "$root/docs/TEST_GUIDELINES.md" \
            "$root/docs/adr"; then
        echo "a file still states the old rule"; false
    fi
}

@test "templates: no ledger README documents supersedes:, superseded-by: or retired:" {
    # verifies: ADR-k3nkv3
    for readme in srs sad rmf problems; do
        if grep -nE 'supersedes:|superseded-by:|retired:' "$BATS_TEST_DIRNAME/../templates/$readme.md"; then
            echo "templates/$readme.md documents a supersession keyword"; false
        fi
    done
}

@test "grill-requirements: an item states one behavior, with no rationale, history or implementation detail" {
    # verifies: ADR-k3nkv3
    skill="$BATS_TEST_DIRNAME/../skills/grill-requirements/SKILL.md"
    section=$(awk '/^### Write requirements as they are settled$/ { inside = 1; next }
        inside && /^##/ { exit } inside' "$skill" | tr '\n' ' ' | tr -s ' ')
    wanted='An item states one testable behavior and nothing else: no rationale, history, example or implementation detail.'
    printf '%s\n' "$section" | grep -qF -- "$wanted" || { echo "the section lacks $wanted"; false; }
}

@test "grill-requirements: an ADR holds its context, decision and consequences, and is rewritten, not amended" {
    # verifies: ADR-k3nkv3
    skill="$BATS_TEST_DIRNAME/../skills/grill-requirements/SKILL.md"
    section=$(awk '/^### ADRs$/ { inside = 1; next }
        inside && /^##/ { exit } inside' "$skill" | tr '\n' ' ' | tr -s ' ')
    for wanted in 'then its context, the decision and its consequences, a few sentences each.' \
            'When the decision changes, rewrite the ADR in place; do not amend it with history.' \
            'A reversed decision is deleted, as any item is.'; do
        printf '%s\n' "$section" | grep -qF -- "$wanted" || { echo "the section lacks $wanted"; false; }
    done
    if printf '%s\n' "$section" | grep -qF 'one to three sentences'; then
        echo "the section still says one to three sentences"; false
    fi
}

@test "item-writing skills point at the terseness rule" {
    # verifies: ADR-k3nkv3
    root="$BATS_TEST_DIRNAME/.."
    for skill in design-architecture analyze-risks resolve-problem; do
        flat=$(tr '\n' ' ' < "$root/skills/$skill/SKILL.md" | tr -s ' ')
        printf '%s\n' "$flat" | grep -qF -- 'terse, as `grill-requirements` states under "Write requirements as they are settled"' \
            || { echo "$skill does not point at the terseness rule"; false; }
    done
    flat=$(tr '\n' ' ' < "$root/skills/resolve-problem/SKILL.md" | tr -s ' ')
    printf '%s\n' "$flat" | grep -qF -- 'A PR item states the anomaly and how it shows; its cause and fix go in the squash message.' \
        || { echo "resolve-problem does not say what a PR item holds"; false; }
}

@test "templates: every ledger README says an item is terse" {
    # verifies: ADR-k3nkv3
    for readme in srs sad rmf problems; do
        grammar=$(awk '/^<!--$/ { inside = 1; next } inside && /^-->$/ { exit } inside' \
            "$BATS_TEST_DIRNAME/../templates/$readme.md" | tr '\n' ' ' | tr -s ' ')
        printf '%s\n' "$grammar" | grep -qF -- 'An item is terse: no rationale, history or implementation detail.' \
            || { echo "templates/$readme.md does not say an item is terse"; false; }
    done
}

@test "check-traceability: one definition of a passing check-trace run, cited by the gate" {
    # verifies: REQ-6p7jz3
    # Every run prints `problems:` and may print warnings, so a definition
    # of "clean" as exit 0 with two summary lines is met by no run.
    skill="$BATS_TEST_DIRNAME/../skills/check-traceability/SKILL.md"
    gate="$BATS_TEST_DIRNAME/../skills/verify-before-merge/SKILL.md"
    step3=$(step_of "$skill" 3 | tr '\n' ' ' | tr -s ' ')
    grep -qF 'passes at exit 0 with no violation line' <<< "$step3" \
        || { echo "step 3 does not define a passing run: $step3"; false; }
    for allowed in '`checked:`' '`problems:`' '`sources:`' 'UNRESOLVED-PR' 'ACCEPTED-PR' 'fix <RULE>:'; do
        grep -qF -- "$allowed" <<< "$step3" \
            || { echo "step 3 does not allow $allowed"; false; }
    done
    grep -qE '^ *sources: .*, examples [0-9]+$' "$skill" \
        || { echo "the sources: example lacks the examples figure"; false; }
    run grep -qF 'with only these two lines' "$skill"
    [ "$status" -ne 0 ] || { echo "step 3 still defines clean as two lines"; false; }
    check2=$(grep -m 1 -A3 '^2\. `\.guardrails/scripts/check-trace\.sh`' "$gate" | tr '\n' ' ' | tr -s ' ')
    grep -qF 'check-traceability' <<< "$check2" \
        || { echo "check 2 does not cite check-traceability: $check2"; false; }
    grep -qF 'step 3' <<< "$check2" \
        || { echo "check 2 does not cite step 3: $check2"; false; }
}

@test "develop-refactor: a duplication fix leaves each test checking what it claims" {
    # verifies: REQ-8kag74
    # A duplication fix that drops a test's assertions because a sweep covers
    # them leaves a test named for a behavior it no longer checks.
    skill="$BATS_TEST_DIRNAME/../skills/develop-refactor/SKILL.md"
    step3=$(step_of "$skill" 3 | tr '\n' ' ' | tr -s ' ')
    grep -qF 'A duplication fix leaves each test asserting what its name and `verifies:` claim.' <<< "$step3" \
        || { echo "step 3 does not keep a test's assertions through a duplication fix: $step3"; false; }
}
