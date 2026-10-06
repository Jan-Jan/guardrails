# merge-change step 8 trusts finish-merge.sh Implementation Plan

**Goal:** after the user runs step 7's compound, the agent no longer
re-verifies the signature. `finish-merge.sh` guard 1 is the one signature
check, run in the user's shell.
**Implements:** no requirement items exist in this repository. Decisions D1-D5
below, settled with the user on 2026-10-05 in a `grill-requirements`
interview.
**Safety class:** the toolkit itself is unclassified. Documentation only.
**Verification:** `sh tests/run-tests.sh`, dispatched to a subagent (AGENTS.md
non-negotiable 3). The verdict comes from the reported pass and fail counts.
`tests/skills.bats` enforces the section order and the 2,000-word limit.

**Base.** Branched from local `main` at `17a0d58` on 2026-10-05, while
`churn-proposal` and `parallel-session-proposals` are open. The user decided
this on 2026-10-05 and overrode AGENTS.md non-negotiable 4 for this change.
Neither branch touches `skills/merge-change/` or `tests/skills.bats`.
Baseline at `17a0d58`: 1055 tests, 1055 pass, 0 fail, 0 skip.

## Why

Step 8 runs `git log -1 --format='%h %G? %s'` and
`check-signing.sh --strict` after the user reports success. Guard 1 of
`finish-merge.sh` has already run `check-signing.sh --strict` on the same
HEAD, before it removed anything (`tests/finish-merge.bats`, "an unverifiable
signature fails, because --strict is unconditional"). The second run adds no
evidence, and it is the run most likely to be wrong: a sandboxed agent's
read-only `~/.gnupg` makes gpg report `N` for a signed commit (AGENTS.md,
"Verifying an OpenPGP signature needs a writable `~/.gnupg`"; PR-k4t9k2).
PR-52rnrn already places verification in the user's shell through step 7's
compound.

## Decisions

- **D1. Step 8 does not re-verify.** It runs neither `git log` with `%G?` nor
  `check-signing.sh`. Guard 1 is the signature check.
- **D2. On the user's word of success, the agent checks nothing.** It writes
  one closing line from the step-7 message file, naming the branch, the IDs it
  implements and the verification record, and recommends compacting. No
  commit hash, no git command.
- **D3. On a reported problem or a non-zero exit, the agent investigates.**
  Step 8 keeps its `references/cleanup-rejections.md` handling, including the
  case PR-sa5y4k fixed: an exit 1 after the worktree was removed, when only
  `git branch -D` failed. The re-run instruction (`finish-merge.sh <branch>`
  alone, never the whole compound) stays.
- **D4. Step 7's hand-over states what success looks like.** Success ends with
  the three `finish-merge:` lines the script prints at exit 0; on anything
  else, the user pastes the output. The script is not changed.
- **D5. "Done when" names the script as the verifier**, so it no longer reads
  as an agent action.

Out of scope: scripts, SOUP, ADR (easy to reverse), glossary. Problem reports
consulted, none contradicted: PR-52rnrn, PR-k4t9k2, PR-sa5y4k, PR-zmzav3,
PR-mvqm4s, PR-74gcqg, PR-whkz8m.

---

### T1 — step 8 reports without re-verifying

**Files touched:** `tests/skills.bats`, `skills/merge-change/SKILL.md`,
`skills/merge-change/references/rationale.md`
**Parallel:** no (only task)

Run every command from the change worktree,
`/Users/jan-jan/Coding/guardrails/.worktrees/step-8-trusts-finish-merge`.
Each edit replaces the exact Before text with the exact After text. Each
Before must match exactly once; stop and report if it matches zero or two
times.

**Step 1 — write the failing tests.** Insert these three tests in
`tests/skills.bats` directly after the test
`@test "merge-change: step 8 maps guard 4's rejection to a remedy"` (after its
closing `}` and the blank line that follows it):

```bash
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
    printf '%s\n' "$step8" | grep -q 'Do not re-verify the signature'
    printf '%s\n' "$step8" | grep -q 'If the user reports a problem or `finish-merge.sh` exited non-zero'
    printf '%s\n' "$step8" | grep -q 'references/cleanup-rejections.md'
    printf '%s\n' "$step8" | grep -q 're-run the script alone'
    # `run` and an explicit status, not `! grep`: bash suppresses errexit for a
    # negated command.
    run grep -q -e '%G?' -e 'check-signing' <<< "$step8"
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
```

In the same file, re-aim one assertion of the existing test
`@test "merge-change: text the first rewrite lost is stated again"`. It pins
a rationale sentence that Step 6 retires, and Step 6's replacement states
the same reason (a pass adds nothing over guard 1):

Before:

```
    grep -q 'one re-read of a commit whose signature is known good' "$rationale"
```

After:

```
    grep -q 'so a pass added nothing' "$rationale"
```

The rationale file must name no script ("merge-change: the rationale file
describes no script" forbids any word ending in `.sh`); Step 6's After
complies.

**Step 2 — see them fail.** `tests/run-tests.sh` cannot run one file; call
bats directly:

```sh
tests/.bats-core/bin/bats -f 'merge-change: (step 8 reports|step 7 tells|Done when names)' tests/skills.bats
```

Expected: `1..3`, and all three `not ok`.

**Step 3 — edit `skills/merge-change/SKILL.md`, step 7.**

Before:

```
   hardware-key touch; tell them so.
```

After:

```
   hardware-key touch; tell them so. Success ends with three
   `finish-merge:` lines; otherwise, they paste you the output.
```

**Step 4 — edit `skills/merge-change/SKILL.md`, step 8.**

Before:

````
8. **Confirm, then report.** On the user's word that the command succeeded,
   confirm it:

   ```sh
   git log -1 --format='%h %G? %s'
   .guardrails/scripts/check-signing.sh --strict   # verifies the new HEAD
   ```

   Report the squash commit, the IDs it implements and the record it cites.
   Recommend compacting before the next change; if the harness offers a
   compaction step, such as `/compact`, name it so the user can run it.

   If `finish-merge.sh` exited non-zero, read `references/cleanup-rejections.md`.
````

After:

```
8. **Report.** On the user's word that the command succeeded, write one
   closing line from the message file: branch, IDs, record.
   Do not re-verify the signature; guard 1 did. Recommend compacting; if
   the harness has a compaction step (`/compact`),
   name it so the user can run it.

   If the user reports a problem or `finish-merge.sh` exited non-zero, read
   `references/cleanup-rejections.md`.
```

The line breaks matter: `tests/skills.bats` greps line by line, and
"merge-change: text the first rewrite lost is stated again" requires
`name it so the user can run it` on one line.

The paragraph after it ("The signed commit is on the base branch either
way. …") and the re-run block stay unchanged.

**Step 5 — edit `skills/merge-change/SKILL.md`, "Done when".**

Before:

```
  names the plan and the record, and `check-signing.sh --strict` verifies it.
```

After:

```
  names the plan and the record, verified by `finish-merge.sh`.
```

**Step 6 — edit `skills/merge-change/references/rationale.md`.**

Before:

```
## Step 8: `--strict`

Without `--strict`, step 8 would confirm nothing on exactly the machine where
confirmation matters.

Guard 1 made the same check under `--strict` moments earlier, in the compound.
Step 8 therefore costs
one re-read of a commit whose signature is known good, and it cannot report
success where that guard would have rejected the commit.
```

After:

```
## Step 8: no re-verification

Step 8 used to re-run the signature check under `--strict` after the user
reported success. Guard 1 makes that check moments earlier, in the
compound, in the user's shell, so a pass added nothing. A failure was usually
the agent's own environment: a sandbox with a read-only `~/.gnupg` makes gpg
read a good signature as `N`. The agent takes the user's word, and acts only
on a reported problem or a non-zero exit. Step 7 tells the user what success
prints, so a rejection does not pass for success.
```

**Step 7 — see them pass, and the skill lints with them.**

```sh
tests/.bats-core/bin/bats -f 'merge-change' tests/skills.bats
tests/.bats-core/bin/bats tests/skills.bats | tail -n 3
wc -w < skills/merge-change/SKILL.md
```

Expected: every `merge-change` test `ok`, including the three new ones; the
whole of `tests/skills.bats` has no `not ok` line; the word count is `1997`
(at most 2000).

**Step 8 — commit.**

```sh
git add tests/skills.bats skills/merge-change/SKILL.md skills/merge-change/references/rationale.md
git -c commit.gpgsign=false commit -m "feat: merge-change step 8 reports without re-verifying the signature

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

Hand-off: `develop-change` for T1, then `check-traceability`,
`verify-before-merge` and `merge-change`.
