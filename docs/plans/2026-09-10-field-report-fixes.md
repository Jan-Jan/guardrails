# Class B Field Report Fixes — Implementation Plan

**Goal:** Resolve three of the four problems recorded in
`docs/problems/DRAFT-field-report-items-class-b-report.md` — a guard-4
preflight, an `accepted` problem status, and a supersession reciprocity check —
leaving `PR-h3wujj` open for its own change.

**Implements:** no minted REQ/RC/SDD IDs — guardrails does not self-host its own
gates (`2026-08-22-ratchet-gap-analysis.md`). The binding contract is the three
problem items: `PR-k77dzn` (T1), `PR-4fwfjp` (T2), `PR-zt5c2v` (T3). Each task's
tests carry `verifies:` naming its item, and each item's `status:` goes to
`resolved` only when its task is green.

**Safety class:** n/a — guardrails is a development tool; the projects it gates
are class A–C. The bats suite is the evidence.

**Verification:** the full suite green at `4b33693` — **634 ok, 0 not ok** — is
the baseline.

**A task runs its own bats files and `tests/portability.bats`, never the whole
suite.** Corrected after T1 was killed mid-run: `sh tests/run-tests.sh` takes
25+ minutes, and a dispatched subagent that sits silent that long is terminated
by a no-progress watchdog with its work still uncommitted. The full suite runs
**once**, in the change worktree, after every task branch has merged — which is
where `verify-before-merge` wants it anyway. `portability.bats` is per-task and
non-negotiable for any task touching `scripts/`: it enforces the leading-`(`
case-pattern rule and the no-literal-newline-to-`awk -v` rule, running every
script under a stub awk that reproduces BWK awk's failure on any platform.

**A task commits as soon as it has anything working.** Uncommitted work in a
task worktree is unprotected, and the watchdog does not ask first.

## Why `PR-h3wujj` is not in this change

It is the only one of the four that goes red on ledgers already written: closing
the `traces:`/`satisfies:` asymmetry reports every indented annotation outside an
item block, and `templates/problems.md` line 44 is itself such a line — which is
what reverted the previous attempt (`lib.sh`, the note at "Extending this to list
markers was tried and reverted"). It needs the template fixed first and a ratchet
migration note, and bundling that with three additive fixes is how a change
becomes unmergeable. It stays open in the ledger.

## Dispatch order and the file-set argument

| | `finish-merge.sh` | `check-trace.sh` + bats | `merge-change` | `ratchet` | `resolve-problem` | `templates/problems.md` |
|---|---|---|---|---|---|---|
| T1 | ✎ | | ✎ | | | |
| T2 | | ✎ | | ✎ | ✎ | ✎ |
| T3 | | ✎ | ✎ | ✎ | | |

T1 ∩ T2 = ∅, so those two fan out together. T3 intersects both and runs last.

**The ledger file is touched by no task.** All three items live in the one draft
file, so a task editing its own `status:` would collide with the other two. The
dispatcher sets each `status: resolved` in the change worktree after that task's
branch merges — one writer, no collision.

---

### T1 — `finish-merge.sh --check` proves guard 4 before the key touch

**Files touched:** `scripts/finish-merge.sh`, `tests/finish-merge.bats`,
`skills/merge-change/SKILL.md`
**Parallel:** yes (with T2)
**Resolves:** `PR-k77dzn`

Guards 1 and 2 both read the squash commit, which does not exist at the point
this mode is for — `merge-change` step 6d, before the signing handoff. So
`--check` proves **guard 4 only**, and says so. The report's "prove all four
guards" is not available and the mode must not imply it.

**Step 1 — the failing tests.** Add to `tests/finish-merge.bats`:

```bash
# verifies: PR-k77dzn
@test "finish-merge: --check reports a nested worktree and removes nothing" {
    setup_signed_squash            # existing helper: base branch + change branch
    git -C "$REPO" worktree add "$WT/.worktrees/change-t1" -b change-t1 change >/dev/null 2>&1
    run sh "$SCRIPTS/finish-merge.sh" --check change
    [ "$status" -eq 1 ]
    [[ "$output" == *"lie inside"* ]]
    [[ "$output" == *".worktrees/change-t1"* ]]
    # removed nothing, deleted nothing
    run git -C "$REPO" show-ref --verify --quiet refs/heads/change
    [ "$status" -eq 0 ]
    [ -d "$WT" ]
}

# verifies: PR-k77dzn
@test "finish-merge: --check exits 0 when nothing is nested" {
    setup_signed_squash
    run sh "$SCRIPTS/finish-merge.sh" --check change
    [ "$status" -eq 0 ]
    [[ "$output" == *"nothing is registered inside"* ]]
    [ -d "$WT" ]
}

# verifies: PR-k77dzn
@test "finish-merge: --check runs from the change worktree, before any squash" {
    setup_change_branch_only       # no squash on the base branch at all
    run sh -c "cd '$WT' && sh '$SCRIPTS/finish-merge.sh' --check change"
    [ "$status" -eq 0 ]
}

# verifies: PR-k77dzn
@test "finish-merge: --check refuses the base branch" {
    setup_signed_squash
    run sh "$SCRIPTS/finish-merge.sh" --check main
    [ "$status" -eq 2 ]
}

# verifies: PR-k77dzn
@test "finish-merge: --check never removes, even with everything green" {
    setup_signed_squash
    run sh "$SCRIPTS/finish-merge.sh" --check change
    [ "$status" -eq 0 ]
    run git -C "$REPO" worktree list
    [[ "$output" == *"$WT"* ]]
}
```

The third test is the one that matters most: it proves the mode works where it is
needed — a linked worktree, no squash — which is exactly where the existing
preamble refuses to run. Read the existing helpers in `tests/finish-merge.bats`
and reuse them; add `setup_change_branch_only` only if no equivalent exists.

Run them and watch all five fail:

```
sh tests/run-tests.sh tests/finish-merge.bats
# expect: not ok — "unknown argument: --check"
```

**Step 2 — factor guard 4's scan into one function.** The nested-worktree test is
the one guard whose wrong answer loses work, so it gets one definition, not two.
Insert after `gr_refuse()`:

```sh
# gr_nested_worktrees WT — every registered worktree path lying inside WT, one
# per line, indented. Shared by --check and guard 4: the check that loses work
# if it answers wrong is not a check to write twice.
#
# Every constraint from guard 4's original site is preserved and is load-bearing
# — no awk anywhere near a PATH (`awk -v` escape-processes its value, so a `\t`
# in a worktree path once made the prefix test match nothing and the guard
# PASS); the `case` patterns open with `(` for bash 3.2 inside `$(...)`; the
# variable half is quoted and therefore literal; the trailing `/` stops a
# sibling at `<wt>-sibling` reading as nested; and the matches are PRINTED
# because a `while read` fed by a pipe runs in a subshell.
gr_nested_worktrees() {
    printf '%s\n' "$wt_list" | while IFS= read -r gr_line; do
        case "$gr_line" in
            ("worktree "*) ;;
            (*) continue ;;
        esac
        gr_path=${gr_line#worktree }
        case "$gr_path" in
            ("$1"/*) printf '    %s\n' "$gr_path" ;;
        esac
    done
}
```

Then replace the inline scan at guard 4 with `nested=$(gr_nested_worktrees "$wt")`,
keeping the comment block that argues the constraints — move it onto the function
and leave a one-line pointer at guard 4.

**Step 3 — parse the flag.** In the argument loop, before the `-*` rejection:

```sh
check_only=0
while [ $# -gt 0 ]; do
    case "$1" in
        (--check|-n) check_only=1 ;;
        (-*) gr_die "unknown argument: $1
  usage: finish-merge.sh [--check] <change-branch>" ;;
```

Update the two other `usage:` strings in the file to the same spelling.

**Step 4 — the preflight, placed immediately after the argument loop** and
before the linked-worktree refusal, because that refusal is what makes the mode
impossible where it is wanted:

```sh
if [ "$check_only" -eq 1 ]; then
    # --check proves guard 4 and NOTHING ELSE, from anywhere in the repository,
    # and removes nothing. Guards 1 and 2 both read the squash commit; at the
    # point this mode is for — merge-change step 6d, before the signing handoff
    # — that commit does not exist, so a mode claiming all four guards would
    # have to invent two verdicts. Guard 3 is `git worktree remove` itself and
    # cannot be proved without doing it.
    #
    # Exit 1 means guard 4 WOULD refuse, so the operator learns it now instead
    # of after a hardware-key touch. Exit 0 means it would not.
    base=$(gr_base_branch)
    [ -z "$base" ] || [ "$branch" != "$base" ] || gr_die \
"$branch is the base branch, not a change branch. Name the change branch."

    git show-ref --verify --quiet "refs/heads/$branch" || gr_die \
"no such branch: $branch."

    wt_list=$(git worktree list --porcelain) || gr_die \
"git worktree list failed, so the worktrees cannot be inspected."

    wt=$(printf '%s\n' "$wt_list" | awk -v want="branch refs/heads/$branch" '
        /^worktree / { path = substr($0, 10) }
        $0 == want { print path; exit }
    ') || gr_die "the worktree path for $branch could not be derived."

    if [ -z "$wt" ]; then
        echo "finish-merge --check: no worktree is registered for $branch, so guard 4 has nothing to refuse"
        exit 0
    fi

    nested=$(gr_nested_worktrees "$wt")
    if [ -n "$nested" ]; then
        printf '%s\n' "guardrails: registered worktrees lie inside $wt:" >&2
        printf '%s\n' "$nested" >&2
        printf '%s\n' \
"  Guard 4 will refuse cleanup AFTER the signed squash, which costs a key touch
  to learn. Deal with each of them now — merge or abandon the branch, then
  \`git worktree remove\` the path — and run this again." >&2
        exit 1
    fi

    echo "finish-merge --check: nothing is registered inside $wt"
    exit 0
fi
```

Note `gr_base_branch` reads the FIRST worktree in `git worktree list --porcelain`
— the primary checkout — so it answers correctly when called from a linked
worktree, which is where this mode runs. The `[ -z "$base" ] ||` guard keeps a
detached primary checkout from turning the preflight into a usage error.

**Step 5 — green, then the skill.** Re-run the file, then the full suite:

```
sh tests/run-tests.sh tests/finish-merge.bats    # expect 5 new ok, 0 not ok
sh tests/run-tests.sh tests/portability.bats     # finish-merge.sh is a script it reads
```

Then `skills/merge-change/SKILL.md` step 6d: replace the bare `git worktree list`
with the command that carries a verdict, keeping the prose about where to go back
to when it refuses:

```sh
# in the change worktree, before the squash is staged
sh .guardrails/scripts/finish-merge.sh --check <change-branch>
```

Say in that step that it proves guard 4 only, and that guards 1 and 2 cannot be
preflighted because they read the squash. Also update the step-8 paragraph that
describes the four guards to mention the preflight exists.

**Commit:** `fix: guard 4 is provable before the signing touch (PR-k77dzn)`

---

### T2 — `status: accepted` for a problem the project has ruled on

**Files touched:** `scripts/check-trace.sh`, `tests/check-trace.bats`,
`skills/resolve-problem/SKILL.md`, `skills/ratchet/SKILL.md`,
`templates/problems.md`
**Parallel:** yes (with T1)
**Resolves:** `PR-4fwfjp`

**`disposition:` is required, and that is what makes the status safe.** Without
it, `accepted` is a one-word escape from both `problem_age_days` and
`problem_open_max`, reachable by an author looking at a red `PROBLEM-BACKLOG` —
the gate would ship its own bypass. `check-review.sh` already reads this keyword
on a finding block, so it is the toolkit's existing word for "ruled on, and here
is the ruling", newly read in this scan.

Accepted items are **exempt from `STALE-PROBLEM` and from `problem_open_max`**,
and **not exempt from the roll-call**: a decision nobody is reminded of decays
back into a thing nobody remembers deciding.

**Step 1 — the failing tests.** Add to `tests/check-trace.bats`:

```bash
# verifies: PR-4fwfjp
@test "check-trace: an accepted problem with a disposition: is not stale and not counted open" {
    write_problem_item "PR-aaa111" "accepted" "opened: 2020-01-01" "disposition: ruled on 2026-09-07 — the cost exceeds the risk"
    run sh "$SCRIPTS/check-trace.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"ACCEPTED-PR PR-aaa111"* ]]
    [[ "$output" != *"STALE-PROBLEM"* ]]
    [[ "$output" == *"problems: open 0, accepted 1"* ]]
}

# verifies: PR-4fwfjp
@test "check-trace: an accepted problem with no disposition: is INCOMPLETE-PROBLEM" {
    write_problem_item "PR-aaa222" "accepted" "opened: 2026-09-01"
    run sh "$SCRIPTS/check-trace.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"INCOMPLETE-PROBLEM PR-aaa222 (accepted, no disposition:)"* ]]
}

# verifies: PR-4fwfjp
@test "check-trace: an accepted problem does not count toward problem_open_max" {
    set_limits 90 1
    write_problem_item "PR-aaa333" "open"     "opened: 2026-09-09"
    write_problem_item "PR-aaa444" "accepted" "opened: 2026-09-01" "disposition: accepted, reasons recorded"
    run sh "$SCRIPTS/check-trace.sh"
    [ "$status" -eq 0 ]
    [[ "$output" != *"PROBLEM-BACKLOG"* ]]
}

# verifies: PR-4fwfjp
@test "check-trace: an unrecognised status still names the three it accepts" {
    write_problem_item "PR-aaa555" "wontfix" "opened: 2026-09-01"
    run sh "$SCRIPTS/check-trace.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"expected open, accepted or resolved"* ]]
}

# verifies: PR-4fwfjp
@test "check-trace: an orphaned disposition: in a problem ledger is reported" {
    write_orphan_annotation "disposition: nobody's ruling"
    run sh "$SCRIPTS/check-trace.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]]
    [[ "$output" == *"disposition:"* ]]
}
```

Reuse the existing helpers in `tests/check-trace.bats` for writing ledger
fixtures and setting limits; the names above are placeholders for whatever that
file already calls them. Watch all five fail.

**Step 2 — the reader.** In the `_prs` awk, in `gr_prflush()`, replace the
status test and add the accepted branch:

```awk
                if (st != "open" && st != "accepted" && st != "resolved") {
                    printf "F 0 MALFORMED-STATUS %s (status: %s — expected open, accepted or resolved)\n", cur, st
                    return
                }
                if (st == "resolved") return

                # ACCEPTED — a problem the project investigated and ruled on.
                # Exempt from STALE-PROBLEM and from problem_open_max: neither
                # limit measures anything about a decision, and a project that
                # triages honestly should not reach the ceiling faster than one
                # that quietly drops things. NOT exempt from the roll-call.
                #
                # `disposition:` is required, and is the whole reason this
                # status is safe to add: without it `accepted` is a one-word
                # escape from both limits, and the gate ships its own bypass.
                # `opened:` stays required too — an accepted item still has a
                # date, and the roll-call reports it.
                if (st == "accepted") {
                    if (!dsp_seen || dsp == "") {
                        printf "F 0 INCOMPLETE-PROBLEM %s (accepted, no disposition:)\n", cur
                        return
                    }
                    if (!opd_seen || opd == "") {
                        printf "F 0 INCOMPLETE-PROBLEM %s (accepted, no opened:)\n", cur
                        return
                    }
                    printf "A 0 ACCEPTED-PR %s (accepted: %s)\n", cur, dsp
                    return
                }
```

Add the collector beside `status:` and `opened:`:

```awk
            cur != "" && !dsp_seen && gr_kw_here(line, "disposition:") { dsp_seen = 1; dsp = gr_value(line, "disposition:") }
```

and reset it in the block-close action, beside the others:

```awk
                st = ""; opd = ""; dsp = ""
                st_seen = 0; opd_seen = 0; dsp_seen = 0
```

`A` is a third line kind alongside `W` and `F`. It needs no aggregation changes
to be correct — `_open_n` greps `^W `, `_oldest` matches `$1 == "W"`, and the
failure test greps `^F ` — which is why the marker is a new letter rather than a
`W` with a flag.

**Step 3 — the count and the summary.** Beside `_open_n`:

```sh
_accepted_n=$(printf '%s\n' "$_prs" | grep -c '^A ' || true)
```

and the summary line becomes:

```sh
echo "problems: open $_open_n, accepted $_accepted_n, oldest $_oldest_txt; limits age ${age_limit:-none}, open ${open_limit:-none}"
```

**Step 4 — the backstop.** `disposition:` is now block-parsed in the problems
ledger, so an orphaned one must be reported for the same reason `opened:` is —
otherwise it is read, matched and dropped in silence. Add to the unconditional
`_orphans` block:

```sh
    # Block-parsed as of PR-4fwfjp, so the backstop covers it: an orphaned
    # disposition: would otherwise be credited to nothing while the accepted
    # item above it reads as undisposed.
    check_orphans 'disposition:' PR $problems_files
```

**Step 5 — green, then the documents.**

```
sh tests/run-tests.sh tests/check-trace.bats     # expect 5 new ok, 0 not ok
sh tests/run-tests.sh tests/portability.bats     # check-trace.sh is a script it reads
```

- `scripts/check-trace.sh` header: add `ACCEPTED-PR` to the report list and
  update the `MALFORMED-STATUS` line to name three values.
- `templates/problems.md`: document the third status and that `disposition:` is
  required with it. Keep every illustrative form **indented** and use `NNNNNN`,
  per that file's existing convention — a definition form at column one is
  judged wherever it sits.
- `skills/resolve-problem/SKILL.md`: a short subsection under §4 — a problem
  investigated and deliberately not fixed goes to `status: accepted` with a
  `disposition:` line carrying the ruling and its date; it stays in the
  roll-call and stops aging. State that this is the *decided* / *forgotten*
  distinction, and that `accepted` without a `disposition:` is refused.
- `skills/ratchet/SKILL.md`: an upgrade note in the existing style. This one is
  purely additive — no ledger already written uses `accepted`, so nothing goes
  red at the upgrade, and the note says exactly that.

**Commit:** `feat: a problem the project ruled on has a status (PR-4fwfjp)`

---

### T3 — supersession reciprocity

**Files touched:** `scripts/check-trace.sh`, `tests/check-trace.bats`,
`skills/merge-change/SKILL.md`, `skills/ratchet/SKILL.md`
**Parallel:** no (serial, after T1 and T2 — shares `check-trace.sh` and its bats
file with T2, and `merge-change` with T1)
**Resolves:** `PR-zt5c2v`

Reciprocity is the half a gate can prove, in one pass over annotations the parser
already collects. It is **not** a sweep for stale references to a superseded ID:
an `affects:` line may legitimately name an old ID as history, so that is a
separate question and this task does not answer it. Existence is already covered
— `DANGLING-REF` scans every `doc_*` file, so `supersedes:` naming an ID that was
never defined is reported there.

**Step 1 — the failing tests.** Add to `tests/check-trace.bats`:

```bash
# verifies: PR-zt5c2v
@test "check-trace: supersedes: with no matching superseded-by: is reported" {
    write_req_item "REQ-bbb111" "supersedes: REQ-bbb222"
    write_req_item "REQ-bbb222" ""
    run sh "$SCRIPTS/check-trace.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"NON-RECIPROCAL-SUPERSESSION REQ-bbb111"* ]]
}

# verifies: PR-zt5c2v
@test "check-trace: superseded-by: with no matching supersedes: is reported" {
    write_req_item "REQ-bbb333" ""
    write_req_item "REQ-bbb444" "superseded-by: REQ-bbb333"
    run sh "$SCRIPTS/check-trace.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"NON-RECIPROCAL-SUPERSESSION REQ-bbb444"* ]]
}

# verifies: PR-zt5c2v
@test "check-trace: a reciprocal pair is silent" {
    write_req_item "REQ-bbb555" "supersedes: REQ-bbb666"
    write_req_item "REQ-bbb666" "superseded-by: REQ-bbb555"
    run sh "$SCRIPTS/check-trace.sh"
    [[ "$output" != *"NON-RECIPROCAL-SUPERSESSION"* ]]
}

# verifies: PR-zt5c2v
@test "check-trace: supersession is read across ledgers, not only the SRS" {
    write_problem_item_ann "PR-bbb777" "supersedes: PR-bbb888"
    write_problem_item_ann "PR-bbb888" ""
    run sh "$SCRIPTS/check-trace.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"NON-RECIPROCAL-SUPERSESSION PR-bbb777"* ]]
}

# verifies: PR-zt5c2v
@test "check-trace: an orphaned supersedes: is reported" {
    write_orphan_annotation "supersedes: REQ-bbb999"
    run sh "$SCRIPTS/check-trace.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"ORPHAN-ANNOTATION"* ]]
}
```

Watch all five fail.

**Step 2 — the check.** Add a section after `DANGLING-REF`. The canonical key is
`REPLACEMENT<TAB>REPLACED` from both directions, which is what makes the two
relations comparable:

```sh
# --- NON-RECIPROCAL-SUPERSESSION: the pair merge-change already prescribes --
# merge-change step 6a prescribes `supersedes:` on the replacement and
# `superseded-by:` on the replaced item, and no script read either word: a
# half-applied supersession was found by a human reading every site that named
# the old ID, or not at all. On the change that first used the form downstream,
# six sites were half-applied and it took two review rounds to find them.
#
# Reciprocity is the half a gate can prove. This is NOT a sweep for stale
# references to a superseded ID — an `affects:` line may name an old ID as
# history — and existence is already DANGLING-REF's job.
#
# Column-one keyword via gr_kw_here, IDs via gr_id_run: the same pairing
# status:/opened: use, so the reader and the ORPHAN-ANNOTATION backstop look in
# the same place. Occurrences accumulate within a block rather than
# first-one-wins: an item may replace more than one predecessor.
# shellcheck disable=SC2086
_sup_files=$(printf '%s\n' $srs_files $rmf_files $sad_files $problems_files | sort -u)
# shellcheck disable=SC2086
_sup=$(
    LC_ALL=C awk -v body="$GR_ID_BODY" \
        "$GR_AWK_ITEM_BLOCK$GR_AWK_ID_RUN"'
        BEGIN { gr_block_init("REQ|HAZ|RC|SDD|LLR|PR", body) }
        FNR == 1 { sub(/^\357\273\277/, "") }
        { line = $0; sub(/\r$/, "", line) }
        gr_block_closes(line) {
            cur = ""
            if (gr_block_opens(line)) cur = gr_block_id(line)
        }
        cur != "" && gr_kw_here(line, "supersedes:") {
            n = split(gr_id_run(line, "supersedes:"), a, " ")
            for (i = 1; i <= n; i++) if (a[i] != "") sup[cur "\t" a[i]] = 1
        }
        cur != "" && gr_kw_here(line, "superseded-by:") {
            n = split(gr_id_run(line, "superseded-by:"), a, " ")
            for (i = 1; i <= n; i++) if (a[i] != "") by[a[i] "\t" cur] = 1
        }
        END {
            for (k in sup) if (!(k in by)) {
                split(k, p, "\t")
                printf "NON-RECIPROCAL-SUPERSESSION %s (supersedes: %s, which carries no superseded-by: %s)\n", p[1], p[2], p[1]
            }
            for (k in by) if (!(k in sup)) {
                split(k, p, "\t")
                printf "NON-RECIPROCAL-SUPERSESSION %s (superseded-by: %s, which carries no supersedes: %s)\n", p[2], p[1], p[2]
            }
        }
    ' $_sup_files | LC_ALL=C sort
) || exit 2
if [ -n "$_sup" ]; then
    printf '%s\n' "$_sup"
    fail=1
fi
```

The `| LC_ALL=C sort` is not cosmetic: `for (k in arr)` has unspecified order in
awk, so without it the report's line order varies between implementations and
between runs, and a bats test asserting whole output would be flaky on one awk
and green on another.

**Step 3 — the backstop.** Both keywords are now block-parsed, so add to the
unconditional `_orphans` block:

```sh
    check_orphans 'supersedes:'    'REQ|HAZ|RC|SDD|LLR|PR' $_sup_files
    check_orphans 'superseded-by:' 'REQ|HAZ|RC|SDD|LLR|PR' $_sup_files
```

`_sup_files` is computed above; move its assignment above the `_orphans` block so
both users see it.

**Step 4 — green, then the documents.**

```
sh tests/run-tests.sh tests/check-trace.bats     # expect 5 new ok, 0 not ok
sh tests/run-tests.sh tests/portability.bats     # check-trace.sh is a script it reads
```

- `scripts/check-trace.sh` header: add `NON-RECIPROCAL-SUPERSESSION` to the
  report list.
- `skills/merge-change/SKILL.md` step 6a: the prescription is now enforced —
  say the gate checks reciprocity, and say plainly what it does **not** check,
  so the next adopter budgets for the reference sweep by hand.
- `skills/ratchet/SKILL.md`: an upgrade note. Unlike T2's this one **can** go
  red on an existing ledger, on exactly the half-applied supersessions it exists
  to find; the note says so and says the fix is to add the missing half.

**Commit:** `feat: a half-applied supersession is a finding (PR-zt5c2v)`

---

## After the tasks

1. Dispatcher sets `status: resolved` on `PR-k77dzn`, `PR-4fwfjp` and
   `PR-zt5c2v` in `docs/problems/DRAFT-field-report-items-class-b-report.md`,
   each with its root cause and reproducing test name, per `resolve-problem` §4.
   `PR-h3wujj` stays `open`.
2. `check-traceability`, then `verify-before-merge` (full suite, dispatched),
   then `merge-change`.
3. `merge-change` step 6d now runs `finish-merge.sh --check` — T1's own output
   is part of this change's evidence.
