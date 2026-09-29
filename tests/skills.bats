# Content lints over the skills, in the spirit of portability.bats's sweep:
# a skill instruction that quietly loses a critical phrase fails here
# rather than in some target project months later.

# The word table the writing scan reads. Each key is a word the replace list in
# templates/AGENTS-block.md names; the rest of the line is the forms the scan
# reads for it.
#
# This function body is the one region the scan exempts in this file. The scan
# opens the region at the declaration line below and closes it at the next line
# that is exactly a closing brace, so the rest of this file is scanned. The
# paragraph on how the forms were narrowed is inside the body, because it has
# to state the forms it excludes.
gr_writing_table() {
    # The forms are narrowed by hand against this tree until every correct
    # English use stops matching, and that judgment cannot be derived from the
    # replace list. The bare `hold` is in: its one correct use in this tree is
    # the idiom `when all three hold`, which the exemption list drops by its
    # full phrasing.
    #
    # The bare `say` is out, and it is the one form deliberately left
    # unscanned. The scan matches whole words, so `grep -Eiw say` also matches
    # inside the noun `say-so`, and the parenthetical `say` meaning "for
    # example" has no entry on the shipped replace list. With `say` scanned
    # both are unwritable, and the tree was edited to fit the scan rather than
    # the scan to fit the rule: one `say-so` and four parentheticals were
    # deleted to keep this file green. `says`, `said` and `saying` stay in,
    # because `states` replaces each of them, and the imperative `say so` —
    # six uses in this tree — then needs no exemption at all.
    #
    # `run` is out and `ran` is in. `sat` is out because it is an awk variable
    # in check-trace.sh and produces seven false reports.
    cat <<'TABLE'
carries carry carries carried carrying
lands land lands landed landing
holds hold holds held holding
survives survive survives survived surviving
says says said saying
refuses refuse refuses refused refusing refusal
ran ran
load-bearing load-bearing
sits sit sits sitting
TABLE
}

gr_writing_forms() {
    gr_writing_table | cut -d' ' -f2- | tr ' ' '\n' | sort -u | paste -sd'|' -
}

gr_writing_keys() {
    gr_writing_table | cut -d' ' -f1 | sort
}

gr_writing_paths() {
    echo 'skills AGENTS.md README.md templates install.sh scripts tests docs/problems docs/risk docs/adr'
}

# The phrases the scan removes from a line before it matches, one per line:
# the path the removal is addressed to, a `|`, then the phrase. `*` addresses
# every path.
#
# Two of them quote git's own output, which is reproduced verbatim in
# skills/worktree-discipline/SKILL.md. Each removal is addressed to the paths
# that must spell the wording out — that skill, and this file, which cannot
# remove a phrase without writing it. Unaddressed, the removal was applied to
# the concatenated stream and exempted the wording in every file in scope.
#
# The rest are English idioms, dropped by full phrasing so that a second use
# of the word on the same line is still reported. Every line here is removed
# from itself, which is why the list can name the phrases in plain text.
gr_writing_exemptions() {
    cat <<'EXEMPT'
skills/worktree-discipline/SKILL.md|refusing to update checked out branch
skills/worktree-discipline/SKILL.md|refusing to fetch into branch
tests/skills.bats|refusing to update checked out branch
tests/skills.bats|refusing to fetch into branch
*|says so
*|said so
*|when all three hold
EXEMPT
}

# The exemption list compiled to one sed script. Each letter of a phrase
# becomes a bracketed pair, because the scan's grep ignores case and an
# exemption that does not would leave an upper-case use reported — which is
# how `SAID SO` in check-review.sh was rewritten into non-English to keep this
# file green. sed's own case-insensitivity flag is not POSIX.
gr_writing_exempt_script() {
    gr_writing_exemptions | awk -F'[|]' '
        function quoted(character) {
            if (index("\\.[]^$*/", character) > 0) { return "\\" character }
            return character
        }
        function literal(text,   position, out) {
            out = ""
            for (position = 1; position <= length(text); position++) {
                out = out quoted(substr(text, position, 1))
            }
            return out
        }
        function anycase(text,   position, character, lower, upper, out) {
            out = ""
            for (position = 1; position <= length(text); position++) {
                character = substr(text, position, 1)
                lower = tolower(character)
                upper = toupper(character)
                if (lower != upper) { out = out "[" lower upper "]" }
                else { out = out quoted(character) }
            }
            return out
        }
        $1 == "*" { printf "s/%s//g\n", anycase($2); next }
        { printf "/^%s:/ s/%s//g\n", literal($1), anycase($2) }
    '
}

# The scan itself. The files to scan are the arguments; the sites it reports
# come back on stdout as `path:line:text`, and the exit status is grep's, so a
# caller can tell no match (1) from a scan that did not run (2).
#
# Every test that asserts anything about the scan calls this one function, so
# the exempt regions, the exemption list and the grep flags are on one path.
# Built separately, a canary proves only itself: dropping `-i` here or adding
# a word to the exemption list left every test green over a scan that had
# stopped reporting that word.
# The pattern that closes a writing-section exemption, named once. The scan
# and the guard that reports an exemption reaching end of file both read it
# here. Kept apart, the guard matched its own copy rather than the scan's, and
# a one-character edit to the scan widened the exemption to end of file with
# the guard still green.
gr_writing_section_closer() {
    echo '^## '
}

gr_writing_scan() {
    gr_scan_banned=$(gr_writing_forms)
    gr_scan_script=$(gr_writing_exempt_script)
    gr_scan_closer=$(gr_writing_section_closer)

    # A sed script that cannot compile makes the whole pipeline produce nothing,
    # and grep then exits 1 — indistinguishable from a clean tree. Compile it
    # once against no input and fail loudly instead.
    if ! printf '' | sed -e "$gr_scan_script" >/dev/null 2>&1; then
        echo 'the exemption list does not compile to a usable sed script' >&2
        return 2
    fi

    for gr_scan_file in "$@"; do
        awk -v file="$gr_scan_file" -v closer="$gr_scan_closer" '
            /^## Writing: prose, names and messages$/ { section = 1; next }
            section && $0 ~ closer { section = 0 }
            /^gr_writing_table\(\) \{$/ { table = 1; next }
            table && /^\}$/ { table = 0; next }
            section || table { next }
            { print file ":" NR ":" $0 }
        ' "$gr_scan_file"
    done \
        | sed -e "$gr_scan_script" \
        | grep -Eiw "$gr_scan_banned"
}

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
    grep -q 'prose carriers' "$skill"
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
    # Re-aimed 2026-09-10 (PR-k77dzn): the structural check is now a command
    # with a verdict, `finish-merge.sh --check`, rather than a raw
    # `git worktree list` the author reads by eye. What this pin protects is
    # that 6d still checks the registry at all — not which spelling it uses.
    sed -n "${d_at},${s_at}p" "$skill" | grep -q 'finish-merge.sh --check'
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
    grep -q 'fails on untracked files as well as modified ones' "$skill"
    grep -q 'read the scratch, delete it, and remove the worktree again' "$skill"
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
    sed -n "${a_at},${b_at}p" "$skill" | grep -q 'fails on a path that was never created'
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
    # are removed with their dispatch (`worktree-discipline`, "Inside the
    # worktree"), so round 1's `-fix` branch is gone before round 2 dispatches.
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
    grep -q '`git worktree remove` and then `git branch -d`' "$skill"
    grep -q 'git validates the new branch name' "$rationale"
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
    grep -q 'one harness, measured once' "$skill"
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
    remove_at=$(grep -n 'git worktree remove \.worktrees/<change-branch>-review' \
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
    grep -q 'Both worktree entries earn their place' "$skill"
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
    grep -q 'a tooth ordering, not a package' "$skill"
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
    grep -q 'assesses:' "$root/skills/check-traceability/SKILL.md"
    grep -q 'assesses:' "$root/skills/analyze-risks/SKILL.md"
    grep -q 'assesses:' "$root/skills/grill-requirements/SKILL.md"
    grep -q 'assesses:' "$root/templates/rmf.md"
    grep -q 'assesses:' "$root/templates/srs.md"
    grep -q 'assesses:' "$root/templates/sad.md"
    grep -q 'assesses:' "$root/templates/AGENTS-block.md"
    grep -q 'assesses:' "$root/README.md"
    ! grep -q 'never mentioned in the RMF' "$root/skills/check-traceability/SKILL.md"
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
    grep -q 'DANGLING-FILE' "$BATS_TEST_DIRNAME/../skills/check-traceability/SKILL.md"
    grep -q 'DANGLING-FILE' "$BATS_TEST_DIRNAME/../README.md"
    grep -q 'reported as left' "$BATS_TEST_DIRNAME/../README.md"
    grep -q 'root-relative' "$BATS_TEST_DIRNAME/../README.md"
    grep -q 'root-relative' "$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'relative link' "$BATS_TEST_DIRNAME/../skills/check-traceability/SKILL.md"
}

@test "clanker: the managed block bans the vocabulary by listing it" {
    # verifies: D3 (docs/plans/2026-09-14-clanker-adoption.md)
    # An abstract instruction to write plainly does not change model output —
    # the current skill prose was written under instructions of that shape.
    # The explicit list is the part that works, so the list itself is what
    # this test pins.
    # The replace list's membership is pinned by the agreement test below,
    # which compares every word the block names against the scan's word table.
    # Naming one of those words here as well would put the vocabulary in this
    # file outside the one region the scan exempts.
    block="$BATS_TEST_DIRNAME/../templates/AGENTS-block.md"
    grep -q 'Write dry, technical prose' "$block"
    grep -q 'Replace these words' "$block"
    grep -qi 'no metaphor' "$block"
    grep -q 'Do not match existing style' "$block"
}

@test "clanker: the managed block names concrete naming rules" {
    # verifies: D5 (docs/plans/2026-09-14-clanker-adoption.md)
    # Naming is where the rule reaches code rather than prose. Without the
    # worked pair the instruction is abstract again.
    block="$BATS_TEST_DIRNAME/../templates/AGENTS-block.md"
    grep -q 'write_timestamp' "$block"
    grep -q 'single-character' "$block"
}

@test "clanker: this repository follows the same block" {
    # verifies: D1 (docs/plans/2026-09-14-clanker-adoption.md)
    # AGENTS.md is guardrails' own copy of the rules it ships. A rule that
    # ships to adopters and does not bind this repository is a rule this
    # repository will break first.
    agents="$BATS_TEST_DIRNAME/../AGENTS.md"
    grep -q 'Write dry, technical prose' "$agents"
    grep -q 'Do not match existing style' "$agents"
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

@test "clanker: ratchet reports a managed block with no writing rules" {
    # verifies: D1 (docs/plans/2026-09-14-clanker-adoption.md)
    # A project ratcheted before this change has a block without the writing
    # section. No other check reports it.
    # Anchored on the inventory bullet itself, not on the phrase 'writing
    # rules': that phrase also appears in the upgrade announcement, so the
    # earlier anchor stayed green with the whole bullet deleted.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'A managed block with no `## Writing: prose, names and messages` section' "$skill"
    grep -q 'Record it in the gap analysis' "$skill"
}

@test "clanker: the word table and the shipped replace list name the same words" {
    # verifies: D4 (docs/plans/2026-09-16-scan-scope.md)
    # The predecessor's list was a hand copy of the shipped rule with nothing
    # connecting the two, so a word added to the rule reached no scan. The
    # comparison is bidirectional by construction: a shipped word with no table
    # entry fails, and a table entry with no shipped word behind it fails.
    cd "$BATS_TEST_DIRNAME/.." || return 1

    shipped=$(
        awk '/^- Replace these words:/ { f = 1; line = $0; next }
             f && /^  / { line = line " " $0; next }
             f { exit }
             END { print line }' templates/AGENTS-block.md \
            | grep -Eo '[a-z-]+ ->' | sed 's/ ->$//' | sort
    )
    if [ -z "$shipped" ]; then
        echo 'no replace list was found in templates/AGENTS-block.md'
        return 1
    fi

    keys=$(gr_writing_keys)
    if [ "$shipped" != "$keys" ]; then
        printf 'the shipped replace list and the scan table disagree\nshipped:\n%s\ntable:\n%s\n' \
            "$shipped" "$keys"
        return 1
    fi

    # This repository states the same rule in its own AGENTS.md, and only the
    # shipped block was parsed above. The two are one rule stated twice, so a
    # word added to either and not the other is a divergence no other check
    # reads: adopters and this tree would then follow different lists.
    local_list=$(
        awk '/^- Replace these words:/ { f = 1; line = $0; next }
             f && /^  / { line = line " " $0; next }
             f { exit }
             END { print line }' AGENTS.md \
            | grep -Eo '[a-z-]+ ->' | sed 's/ ->$//' | sort
    )
    if [ "$local_list" != "$shipped" ]; then
        printf 'AGENTS.md and the shipped block name different words\nAGENTS.md:\n%s\nblock:\n%s\n' \
            "$local_list" "$shipped"
        return 1
    fi
}

@test "clanker: every word-table key is among the forms the scan reads for it" {
    # verifies: D4 (docs/plans/2026-09-16-scan-scope.md)
    # The form columns are inside the one region the scan exempts from itself,
    # and the agreement test above compares column 1 only. A review replaced
    # every form column with a word that occurs nowhere in this tree, planted
    # the replaced vocabulary in a script, and both tests stayed green over a
    # scan that read for nothing. The key is the word the shipped rule replaces,
    # so it is one of its own forms, and requiring that pins each row to its
    # own subject.
    cd "$BATS_TEST_DIRNAME/.." || return 1
    bad=$(
        gr_writing_table | while read -r key forms; do
            case " $forms " in
                (*" $key "*) ;;
                (*) printf '%s -> %s\n' "$key" "$forms" ;;
            esac
        done
    )
    if [ -n "$bad" ]; then
        printf 'word-table rows whose key is not among their own forms:\n%s\n' "$bad"
        return 1
    fi
}

@test "clanker: the scan's own grep reports every form in the word table" {
    # verifies: D4 (docs/plans/2026-09-16-scan-scope.md)
    # The scan is one `grep -Eiw` over an alternation built from the forms,
    # behind the sed that applies the exemption list. A form the alternation
    # cannot match — a stray space, a regex metacharacter, an empty column —
    # or a form a new exemption removes narrows the scan below what the table
    # states, and nothing else reports it.
    #
    # This calls gr_writing_scan, the same function the scan test below calls,
    # so the grep flags and the exemption list are on this path too. A canary
    # with a grep of its own proved only itself: dropping `-i` from the scan,
    # or exempting a word outright, left every test green.
    #
    # Each form goes in twice, lower case and upper case, because the rules
    # bind a word at the start of a sentence and in a shouted comment as much
    # as mid-line. Without the upper-case half, `grep -Eiw` could become
    # `grep -Ew` with every test still green.
    #
    # The canary is scanned by a relative name from its own directory, so the
    # reported `path:line:text` splits on a colon whatever the temporary
    # directory is named.
    cd "$BATS_TEST_TMPDIR" || return 1
    gr_writing_table | cut -d' ' -f2- | tr ' ' '\n' | LC_ALL=C sort -u > writing-lower
    tr '[:lower:]' '[:upper:]' < writing-lower > writing-upper
    cat writing-lower writing-upper | LC_ALL=C sort -u > writing-forms
    want=$(wc -l < writing-forms | tr -d '[:space:]')
    if [ "$want" -eq 0 ]; then
        echo 'the word table names no forms at all, so the scan reads for nothing'
        return 1
    fi

    # A floor on the number of form spellings, against the table being reduced
    # to its keys. Every other check here compares the table against itself, so
    # a table whose every row repeats its key is self-consistent, and the scan
    # then reads no inflection at all while every test stays green. The shipped
    # replace list names one word per rule and cannot supply the inflections, so
    # no external source pins them, and a floor is what remains. Raise it when a
    # row is added; lowering it is the edit this guard exists to expose.
    if [ "$want" -lt 58 ]; then
        printf 'the word table names %s form spellings, expected at least 58\n' "$want"
        return 1
    fi

    scan_status=0
    reported=$(gr_writing_scan writing-forms) || scan_status=$?
    if [ "$scan_status" -gt 1 ]; then
        printf 'the scan exited %s over the form canary without running; its alternation is:\n%s\n' \
            "$scan_status" "$(gr_writing_forms)"
        return 1
    fi

    # comm, not a count: an exit status of 2 and a clean match both yield no
    # output, and a bare count named no form at all when the alternation was
    # invalid.
    printf '%s\n' "$reported" | cut -d: -f3- | LC_ALL=C sort -u > writing-reported
    unread=$(LC_ALL=C comm -23 writing-forms writing-reported)
    if [ -n "$unread" ]; then
        printf 'the scan does not read %s of the %s form spellings in the word table:\n%s\n' \
            "$(printf '%s\n' "$unread" | wc -l | tr -d '[:space:]')" "$want" "$unread"
        return 1
    fi
}

@test "clanker: every tracked file is in the scan's scope or named out of it" {
    # verifies: D1 (docs/plans/2026-09-16-scan-scope.md)
    # D1 states that the in-scope pathspec and the out-of-scope list together
    # name every tracked path, and nothing checked it. A review cut the
    # pathspec to three elements and added a tracked file outside it, and the
    # scan stayed green over a fraction of the tree both times. Pin the scope
    # by its complement: what the pathspec does not match must be exactly the
    # merged records, LICENSE and .gitignore.
    cd "$BATS_TEST_DIRNAME/.." || return 1
    unaccounted=$(
        comm -23 \
            <(git ls-files | LC_ALL=C sort) \
            <(git ls-files -- $(gr_writing_paths) | LC_ALL=C sort) \
            | grep -Ev '^(docs/plans/|docs/verification/|LICENSE$|\.gitignore$)'
    ) || true
    if [ -n "$unaccounted" ]; then
        printf 'tracked files in neither the scan pathspec nor the out-of-scope list:\n%s\n' \
            "$unaccounted"
        return 1
    fi
}

@test "clanker: no file in scope contains the replaced vocabulary" {
    # verifies: D1, D2, D3 (docs/plans/2026-09-16-scan-scope.md)
    # Scope is every tracked file the rules bind. docs/plans and
    # docs/verification are out permanently: they are merged evidence, and
    # editing a record to match a later tree falsifies what it proved.
    cd "$BATS_TEST_DIRNAME/.." || return 1

    # A pathspec that matches nothing makes an empty scan indistinguishable
    # from a clean tree. Check each element rather than counting files, so a
    # path that moves is reported by name.
    for p in $(gr_writing_paths); do
        if ! git ls-files -- "$p" | grep -q .; then
            printf 'pathspec element %s matched no tracked file\n' "$p"
            return 1
        fi
    done

    # D2 exempts one named region per file, and an exemption that matches more
    # than it should is the failure with no symptom. Count openers, not files:
    # a second `## Writing: prose, names and messages` heading appended to
    # AGENTS.md opens a second exempt region and leaves the file count at 2.
    md=$(git grep -cE '^## Writing: prose, names and messages$' -- $(gr_writing_paths) \
        | cut -d: -f2- | awk '{ n += $1 } END { print n + 0 }')
    if [ "$md" -ne 2 ]; then
        printf 'the writing-section opener occurs %s times, expected 2\n' "$md"
        return 1
    fi
    tbl=$(git grep -cE '^gr_writing_table\(\) \{$' -- $(gr_writing_paths) \
        | cut -d: -f2- | awk '{ n += $1 } END { print n + 0 }')
    if [ "$tbl" -ne 1 ]; then
        printf 'the word-table opener occurs %s times, expected 1\n' "$tbl"
        return 1
    fi

    # The markdown region closes at the next `## ` heading, so demoting that
    # heading one level runs the exemption to end of file and the rest of the
    # document goes unscanned. Require every opener to have a closer.
    # The exemption list removes a phrase before the scan reads the line, so a
    # phrase added here is a banned use the scan stops reporting, anywhere in
    # scope. The canary cannot see it: it feeds one form per line and every
    # exemption is a phrase. Pin the count, so adding one is an edit in two
    # places and shows up in the diff as a changed expectation.
    exempt_count=$(gr_writing_exemptions | grep -c '|')
    if [ "$exempt_count" -ne 7 ]; then
        printf 'the scan has %s exemptions, expected 7\n' "$exempt_count"
        return 1
    fi

    unclosed=$(
        git grep -lE '^## Writing: prose, names and messages$' -- $(gr_writing_paths) \
            | while IFS= read -r f; do
                awk -v F="$f" -v closer="$(gr_writing_section_closer)" '
                    /^## Writing: prose, names and messages$/ { open = NR; next }
                    open && $0 ~ closer { open = 0 }
                    END { if (open) print F ":" open }
                ' "$f"
            done
    )
    if [ -n "$unclosed" ]; then
        printf 'a writing-section exemption reaches end of file, opened at:\n%s\n' \
            "$unclosed"
        return 1
    fi

    # Both exempt regions are bounded, not merely closed. A region that closes
    # somewhere is not enough: indent the word table's closing brace and the
    # region runs on to the next one, taking every line between out of the scan
    # while the file still parses and every test stays green. Demote the heading
    # that closes a writing section and it does the same. The lengths are 30 and
    # 21 lines today; the bounds are those plus a little room to edit the text.
    oversize=$(
        {
            git grep -lE '^gr_writing_table\(\) \{$' -- $(gr_writing_paths) \
                | while IFS= read -r f; do
                    awk -v F="$f" '
                        /^gr_writing_table\(\) \{$/ { open = NR; next }
                        open && /^[A-Za-z_][A-Za-z0-9_]*\(\) \{$/ {
                            print F ":" NR ": word table swallows " $0
                        }
                        open && /^\}$/ { if (NR - open > 45) print F ":" open ": word table, " NR - open " lines"; open = 0 }
                        END { if (open) print F ":" open ": word table, reaches end of file" }
                    ' "$f"
                done
            git grep -lE '^## Writing: prose, names and messages$' -- $(gr_writing_paths) \
                | while IFS= read -r f; do
                    awk -v F="$f" -v closer="$(gr_writing_section_closer)" '
                        /^## Writing: prose, names and messages$/ { open = NR; next }
                        open && $0 ~ closer { if (NR - open > 35) print F ":" open ": writing section, " NR - open " lines"; open = 0 }
                        END { if (open) print F ":" open ": writing section, reaches end of file" }
                    ' "$f"
                done
        }
    )
    if [ -n "$oversize" ]; then
        printf 'an exempt region is longer than its bound or never closes:\n%s\n' \
            "$oversize"
        return 1
    fi

    # The scan is gr_writing_scan, which the form canary above also calls, so
    # a change to its flags, its exempt regions or its exemption list is
    # reported by one of the two.
    scan_status=0
    found=$(gr_writing_scan $(git ls-files -- $(gr_writing_paths))) || scan_status=$?
    if [ "$scan_status" -gt 1 ]; then
        printf 'the scan exited %s over the tree without running\n' "$scan_status"
        return 1
    fi

    if [ -n "$found" ]; then
        printf 'replaced vocabulary in files the rules bind:\n%s\n' "$found"
        return 1
    fi
}

@test "develop-change: the loop greps the mutation anchors for a changed line" {
    # verifies: PR-dr7k7k
    # Was annotated PR-4fwfjp, which is the `status: accepted` item and states
    # nothing about mutation anchors: this test asserts an obligation that
    # belonged to no item at all until PR-dr7k7k was written for it.
    # A mutation script embeds a line of the script it mutates as a literal
    # `old = '''…'''` and asserts one match, so a change that edits a quoted
    # line leaves a mutation that cannot apply. No gate catches it —
    # portability.bats reads that directory only for `sed -i` spellings — so
    # the obligation lives in the TDD loop or nowhere.
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
}

@test "merge-change: a round with no code or requirement finding is the last" {
    # verifies: PR-3s74u3
    # 27 review rounds across three changes, the majority of the later ones
    # correcting prose with prose. One clean round, not two.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'is the last review' "$skill"
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

@test "check-traceability: the problem limits state the accepted ruling too" {
    # verifies: PR-9xxz3b, PR-4fwfjp
    # STALE-PROBLEM and PROBLEM-BACKLOG offered the reporter's two choices —
    # fix someone else's problem report under merge pressure, or raise a limit.
    # The third answer reached main in d8502d1 and was stated only in
    # resolve-problem and templates/problems.md, never at the gate that reddens.
    skill="$BATS_TEST_DIRNAME/../skills/check-traceability/SKILL.md"
    stale=$(grep -n 'STALE-PROBLEM PR' "$skill" | cut -d: -f1)
    backlog=$(grep -n 'PROBLEM-BACKLOG (n open' "$skill" | cut -d: -f1)
    sed -n "${stale}p" "$skill" | grep -q 'status: accepted'
    sed -n "${backlog}p" "$skill" | grep -q 'status: accepted'
    # exempt from both limits, never exempt from the roll-call
    sed -n "${stale}p" "$skill" | grep -q 'roll-call'
}

@test "check-traceability: MALFORMED-STATUS knows there are three values" {
    # verifies: PR-4fwfjp
    # d8502d1 added `accepted` as a third status and left this row behind, so
    # the table listed wontfix and accepted alike as errors and told the author
    # to pick one of two.
    skill="$BATS_TEST_DIRNAME/../skills/check-traceability/SKILL.md"
    row=$(grep -n 'MALFORMED-STATUS PR' "$skill" | cut -d: -f1)
    sed -n "${row}p" "$skill" | grep -q 'accepted'
    ! sed -n "${row}p" "$skill" | grep -q 'neither .open. nor .resolved.'
    ! sed -n "${row}p" "$skill" | grep -q 'Pick one of the two'
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
    grep -q '^\*\*finding-1\*\*: <code | requirement | record>' "$template"
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

@test "check-traceability: every report a single-unit check-trace.sh run prints has a catalogue row" {
    # verifies: PR-6d2jvt
    # The skill's "Fixing each rule" table is the only place an author is told
    # what a gate finding means and what to do about it, and nothing tied it
    # to the script. d8502d1 added three reports and changed a fourth's
    # accepted values, updating two other skills and the templates but not the
    # catalogue: ACCEPTED-PR, MALFORMED-SUPERSESSION and
    # NON-RECIPROCAL-SUPERSESSION had no row at all, so an author with a red
    # gate had nowhere to look the finding up.
    #
    # EXTRACTION, both sides derived from the files rather than listed here —
    # a list in this test would be a third copy of the catalogue and would rot
    # the same way:
    #   * the script side is its own roster, the `#   TOKEN ...` lines of the
    #     header block, up to the `# Scoped (multi-unit) runs add:` heading
    #     that the script itself uses to separate the reports a default run
    #     prints from the ones only a scoped run adds. The catalogue documents
    #     the default run, so the scan stops there; the heading is asserted to
    #     exist, so renaming it fails here rather than silently changing this
    #     test's scope. The six scoped reports are documented in neither this
    #     skill nor any other, which is a wider gap and wants its own item.
    #   * the skill side is the first cell of each catalogue row, `| \`TOKEN`.
    #     Prose mentions are deliberately NOT counted: most rows name other
    #     reports in passing, so counting a mention would let a report read as
    #     documented on the strength of a sentence about something else —
    #     the exact hole this test exists to close.
    # The second scan below keeps the roster itself honest: a report printed
    # by the script but absent from the header would otherwise be invisible to
    # the first comparison.
    root="$BATS_TEST_DIRNAME/.."
    script="$root/scripts/check-trace.sh"
    skill="$root/skills/check-traceability/SKILL.md"

    grep -q '^# Scoped (multi-unit) runs add:' "$script"

    emitted=$(
        awk '/^# Scoped \(multi-unit\) runs add:/ { exit }
             /^#   [A-Z]/ { print $2 }' "$script" \
            | grep -E '^[A-Z][A-Z0-9]*(-[A-Z0-9]+)+$' | sort -u
    )
    documented=$(
        grep -oE '^\| `[A-Z][A-Z0-9]*(-[A-Z0-9]+)+' "$skill" \
            | sed 's/^| `//' | sort -u
    )

    # An empty set on either side makes the comparison below succeed having
    # compared nothing, which is the vacuous green this test must not report.
    # Floors, not exact counts: adding a report must not have to edit them.
    n_emitted=$(printf '%s\n' "$emitted" | grep -c . || true)
    n_documented=$(printf '%s\n' "$documented" | grep -c . || true)
    if [ "$n_emitted" -lt 15 ] || [ "$n_documented" -lt 15 ]; then
        printf 'extraction read %s script reports and %s catalogue rows, expected at least 15 of each\n' \
            "$n_emitted" "$n_documented"
        return 1
    fi

    missing=""
    for _r in $emitted; do
        printf '%s\n' "$documented" | grep -qx "$_r" || missing="$missing $_r"
    done
    if [ -n "$missing" ]; then
        printf 'reports check-trace.sh prints with no row in skills/check-traceability/SKILL.md:%s\n' "$missing"
        return 1
    fi

    # Every report the script actually prints must appear in its own header
    # roster, or the roster the comparison above trusts could drift away from
    # the script while staying green. The grading letter and age some lines
    # print before the token (`F 0 `, `W %d `) are stepped over.
    sites=$(
        grep -oE '(echo|printf) "([A-Z] (-?[0-9]+|%d) )?[A-Z][A-Z0-9]*(-[A-Z0-9]+)+' "$script" \
            | sed -E 's/^(echo|printf) "([A-Z] (-?[0-9]+|%d) )?//' | sort -u
    )
    roster=$(
        grep -E '^#   [A-Z][A-Z0-9]*(-[A-Z0-9]+)+ ' "$script" | awk '{ print $2 }' | sort -u
    )
    n_sites=$(printf '%s\n' "$sites" | grep -c . || true)
    if [ "$n_sites" -lt 18 ]; then
        printf 'the emission scan found %s report sites, expected at least 18\n' "$n_sites"
        return 1
    fi
    undeclared=""
    for _r in $sites; do
        printf '%s\n' "$roster" | grep -qx "$_r" || undeclared="$undeclared $_r"
    done
    if [ -n "$undeclared" ]; then
        printf 'reports check-trace.sh prints that its own header does not list:%s\n' "$undeclared"
        return 1
    fi
}

# The skill shape (docs/plans/2026-09-28-agent-first-skills.md, D5 and D9).
#
# Skills not yet rewritten into the D9 section order. D3 change 3 empties
# this list; a name stays on it only while that skill is out of order.
gr_shape_exempt_skills() {
    echo 'analyze-risks check-traceability design-architecture develop-change grill-requirements plan-change ratchet resolve-problem verify-before-merge worktree-discipline'
}

# Skills over the D5 ceiling. Each name is removed by the change that brings
# that skill under 2,000 words; a name stays only while the skill is over.
gr_ceiling_exempt_skills() {
    echo 'check-traceability develop-change merge-change ratchet worktree-discipline'
}

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

@test "skill shape: every SKILL.md has the D9 sections in order" {
    # verifies: D9 (docs/plans/2026-09-28-agent-first-skills.md)
    # A fixed order lets an agent find the step it needs without reading the
    # whole file. Exempt skills are the ones D3 change 3 has not rewritten.
    cd "$BATS_TEST_DIRNAME/.." || return 1
    failures=""
    for skill_file in skills/*/SKILL.md; do
        skill_name=$(basename "$(dirname "$skill_file")")
        case " $(gr_shape_exempt_skills) " in
            (*" $skill_name "*) continue ;;
        esac
        if ! gr_skill_has_d9_order "$skill_file"; then
            failures="$failures $skill_name:[$(gr_skill_headings "$skill_file")]"
        fi
    done
    if [ -n "$failures" ]; then
        echo "skills out of the D9 section order:$failures"
        return 1
    fi
}

@test "skill shape: every shape exemption names a skill still out of order" {
    # verifies: D9 (docs/plans/2026-09-28-agent-first-skills.md)
    # An exemption that outlives its reason hides the next regression.
    cd "$BATS_TEST_DIRNAME/.." || return 1
    stale=""
    for skill_name in $(gr_shape_exempt_skills); do
        skill_file="skills/$skill_name/SKILL.md"
        if [ ! -f "$skill_file" ]; then
            stale="$stale $skill_name:missing"
        elif gr_skill_has_d9_order "$skill_file"; then
            stale="$stale $skill_name:in-order"
        fi
    done
    if [ -n "$stale" ]; then
        echo "remove from gr_shape_exempt_skills:$stale"
        return 1
    fi
}

@test "skill shape: every SKILL.md is at most 2,000 words" {
    # verifies: D5 (docs/plans/2026-09-28-agent-first-skills.md)
    # A ceiling nobody checks is how the skills reached their size.
    cd "$BATS_TEST_DIRNAME/.." || return 1
    failures=""
    for skill_file in skills/*/SKILL.md; do
        skill_name=$(basename "$(dirname "$skill_file")")
        case " $(gr_ceiling_exempt_skills) " in
            (*" $skill_name "*) continue ;;
        esac
        word_count=$(gr_skill_words "$skill_file")
        if [ "$word_count" -gt 2000 ]; then
            failures="$failures $skill_name:$word_count"
        fi
    done
    if [ -n "$failures" ]; then
        echo "skills over 2,000 words:$failures"
        return 1
    fi
}

@test "skill shape: every ceiling exemption names a skill still over it" {
    # verifies: D5 (docs/plans/2026-09-28-agent-first-skills.md)
    cd "$BATS_TEST_DIRNAME/.." || return 1
    stale=""
    for skill_name in $(gr_ceiling_exempt_skills); do
        skill_file="skills/$skill_name/SKILL.md"
        if [ ! -f "$skill_file" ]; then
            stale="$stale $skill_name:missing"
        elif [ "$(gr_skill_words "$skill_file")" -le 2000 ]; then
            stale="$stale $skill_name:$(gr_skill_words "$skill_file")"
        fi
    done
    if [ -n "$stale" ]; then
        echo "remove from gr_ceiling_exempt_skills:$stale"
        return 1
    fi
}

@test "skill shape: the References section lists exactly the reference files" {
    # verifies: D6, D9 (docs/plans/2026-09-28-agent-first-skills.md)
    # A reference file no SKILL.md names is never read; a named one that does
    # not exist is a dead instruction. A file is listed only by an entry line,
    # one opening with "- `references/"; a name on a continuation line or in
    # prose does not list it (review round 6, finding 35).
    cd "$BATS_TEST_DIRNAME/.." || return 1
    failures=""
    for skill_dir in skills/*/; do
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
            failures="$failures $skill_name:[listed: $(echo $names_in_section)][present: $(echo $files_on_disk)]"
        fi
        # D9: the section is omitted when the skill has no reference file.
        # A trailing space after the heading is still the heading.
        if [ -z "$files_on_disk" ] && grep -qE '^## References[[:space:]]*$' "${skill_dir}SKILL.md"; then
            failures="$failures $skill_name:[a References heading and no reference file]"
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
            failures="$failures $skill_name:[entry without a file and a read-when condition: $malformed_entries]"
        fi
    done
    if [ -n "$failures" ]; then
        echo "References section and references/ disagree:$failures"
        return 1
    fi
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
    grep -q 'contains all four fields with values' "$skill"
    grep -q 'INCOMPLETE-RECORD' "$skill"
    grep -q 'With no worktree registered for the branch' "$skill"
    grep -q 'leave or remove it with the harness tool' "$skill"
    grep -q 'exempts nothing from' "$skill"
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
