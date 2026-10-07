# Verification — parallel-changes (2026-10-07)

branch: parallel-changes
reviewer: independent Claude subagents with fresh context, given the diff, the plans, AGENTS.md and the review checklist only (merge-change step 6a); round 1 at `c677536`, round 2 at `4daf6fd`, round 3 at `da3197e`, round 4 at `d60427f`, round 5 at `b1a52f3`, round 6 at `86017fa`
verdict: converged at round 6 — rounds 1 to 5 requested changes (round 1 finding-1 medium; round 2 finding-8 medium; round 3 finding-11 high; round 4 finding-15 high and finding-16 medium; round 5 finding-21 medium); round 6 raised two low requirement findings and one record finding, nothing above low, so it was the last round; every finding is fixed
reproduced: no problem item is resolved; the change implements roadmap decisions D1, D2, D4 and D5. The reviewers reproduced each code and requirement finding they marked as reproduced in scratch repositories, and the fix rounds watched the new assertions fail before each fix

Change: changes may run in parallel. AGENTS.md drops non-negotiable 4 ("Open one change at a time") and renumbers the base-branch rule to 4; `merge-change` drops its one-change precondition, reviews a change again when a base merge shares a file with it, and makes step 7 check for a staged squash and compare the staged tree with the branch; `worktree-discipline` step 2 checks the open worktrees and whether an unmerged branch claims the change's items before a change opens. Branched from `main` at `2d0bbba`; base merged from local `main` at `2d0bbba`, per AGENTS.md non-negotiable 4.
Plan: `docs/plans/2026-10-07-parallel-changes.md`, phase 2 of `docs/plans/2026-10-06-salvage-churn-and-parallel.md`.

## The gate

Measured on: `a34be51` — `git rev-parse HEAD` — tree `07652d1c1388ea0cde56b3685a2e1dbe889e9010`, clean worktree, `main` at `2d0bbba` at the start and end of each run. Step 3 renamed nothing, so this is the tree that merges, apart from this record.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` (parallel) | 1..1107, 1107 ok, 0 not ok, exit 0, about 1200 s (2026-10-08 00:18 to 00:38) |
| `check-ids.sh --allow-draft-files` (scratch copies, base and change) | exit 1 on both, as on `main`; sorted output diff empty |
| `check-trace.sh` (scratch copies) | exit 1 on both, as on `main`; sorted output diff empty: this change has no item IDs |
| Coverage | not configured |
| Working tree | clean |

The first full run on this tree, from 2026-10-07 23:48 to 2026-10-08 00:02, failed one test: `check-trace: trailing whitespace on a field is not part of its value` expected `UNRESOLVED-PR PR-001 (open 4 days)` and got `open 5 days`. Its fixture is dated with `days_ago 4` before midnight and checked after it. This change touches neither that test nor `scripts/`; `tests/check-trace.bats` alone then passed 266 of 266, and the full run above, which did not cross midnight, passed. The check-ids and check-trace rows are from that first gate.

Every D-test is in `tests/skills.bats`: D1 one test, D2 two, D4 two, D5 one, all passing above.

The repository has no `.guardrails/config.yaml`, so `check-ids.sh` and `check-trace.sh` ran on scratch copies built from `main` and from the change with `templates/config.yaml`, and `merge-preflight.sh` was not run; the base and change outputs are compared, as in `docs/verification/2026-10-07-test-runner.md`.

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| D1 | `AGENTS.md: changes may run in parallel; the non-negotiables run 1 to 4` | failed on the unedited tree, grep finding "Open one change at a time" in AGENTS.md (T1); after finding-5, failed with README's new sentence deleted and with the old rule appended to AGENTS.md |
| D2 | `merge-change: changes may run in parallel, and the rationale says why` | failed on the unedited skill when grep found "one change at a time" (T2); after finding-10, failed on a reworded precondition bullet |
| D2 | `merge-change: a base merge that shares a file with the change gets a fresh review` | failed on SKILL.md, rationale.md and the template as they stood before finding-16's fix; runs step 1's fence and 6a's marker in scratch repositories; after finding-21 and finding-22, failed with the overlap taken against the last base merge, with `grep -F` for `grep -Fx`, and with either `--no-renames` removed |
| D4 | `worktree-discipline: a change opens after checking the worktrees and the claimed items` | failed on the unedited tree, the phrase "a status line per registered worktree" absent (T3) |
| D4 | `worktree-discipline: the before-opening snippets run, and the claim check reads the diff` | runs both snippets in a scratch repository under `sh` and zsh; failed with the claim check replaced by `git grep` (finding-4), with a two-dot diff (finding-9), without `^[-+]`, the prunable arm or the detached reset (finding-14), and on the snippets as they stood before finding-15 under zsh, and with each snippet run on an empty `BASE` before the guard existed (finding-26) |
| D5 | `merge-change: step 7 checks for a staged squash before staging its own` | failed because step 7 had no `git diff --cached --quiet` (T2); runs step 7's two lines in scratch repositories (finding-19) and failed with `&&` replaced by `;`, with the comparison against `HEAD` instead of the branch, and with the index check dropped |

## What was wrong, and what was built

AGENTS.md non-negotiable 4 held each change to its signed squash before the
next opened. The roadmap (D1) removes it: sessions run in parallel in
practice, and the rule only stopped them from saying so. On 2026-10-06 two
sessions resolved PR-s8dcmp, and one change was discarded.

Parallel changes needed four things the sequential rule had made
unnecessary:

- **Before a change opens** (D4), `worktree-discipline` step 2 lists every
  registered worktree with its commits ahead, dirty count and last commit,
  and checks whether an unmerged local branch's diff against the base adds or
  removes a line naming an item the new change will touch. The roadmap's
  D4(b) said `git grep`; every branch contains an ID defined on the base, so
  the check reads the three-dot diff instead (finding-7). Both checks run
  under `sh` whatever the caller's shell (finding-15).
- **Step 7 is a lock** (D5): the agent checks that the primary index is empty
  before staging its squash, and compares the staged tree with the branch
  after it. A base that moved after step 1 is caught there and the squash is
  cleared with `git reset --merge` (finding-11), so no tree the gate did not
  see is handed over for signing. P1, staging the squash inside the
  handed-over command, stays rejected: it would leave the index empty until
  the key touch.
- **A base merge that shares a file with the change is reviewed again**
  (finding-16, ruled by the maintainer on 2026-10-07: the test is file
  overlap, not git conflicts). 6a marks the commit each reviewer sees with an
  empty `review dispatched` commit; step 1 prints a `shared:` line for each
  file both the base, since that commit's merge-base, and the change edited,
  and 6a then dispatches a reviewer on the whole change (finding-21). A base
  merge on disjoint files reruns the gate only.
- **`merge-change` drops the precondition** (D2), and its rationale states
  why parallel changes are safe: random IDs, the `branch:` field, the
  overlap review and step 7's comparison.

To keep both SKILL.md files within 2,000 words, reasons moved from them to
`references/rationale.md` and `references/cleanup-rejections.md`; round 6
checked that each moved item is where it went.

## Review

Each round's findings are numbered on from the previous round's. Every round
ran the suite in its own review worktree; each was green.

### Round 1

Reviewed at `c677536`, base `main` `2d0bbba`. Reviewer's suite: 1..1105, 1105 ok, 0 not ok (about 2.5 h at a load average near 30). Verdict: changes requested — one medium code finding.

**finding-1**: code, medium — The step 7 lock check in skills/merge-change/SKILL.md:226-227 is two separate lines: `git diff --cached --quiet` and then `git merge --squash <branch>`. Nothing joins them. If the agent runs the block as one shell call (the usual way), a non-empty index makes the check exit 1, and the squash runs anyway. I reproduced this in a scratch repo. Where the merge fast-forwards, the second `git merge --squash` exits 0 and stacks its files onto the first change's staged squash. The handed-over `git commit -S` would then sign both changes as one commit. So the lock only works if the agent reads the exit status by hand and stops. Fix: `git diff --cached --quiet && git merge --squash <branch>`. Step 3 already uses this form with `||` (SKILL.md:88).
disposition: step 7's index check and the squash are one line, `git diff --cached --quiet && git merge --squash <branch>`; the D5 test requires the joined line and was red on the two-line text (fix commit `9b237f9`). Finding-8 and finding-11 later added the comparison after it.

**finding-2**: requirement, low — skills/merge-change/SKILL.md:230 tells the agent that a non-empty index means "another change holds step 7". The index can also hold the agent's own leftover squash. Signing fails for lack of a key (SKILL.md:264, "stop"), the squash stays staged, and when the agent resumes step 7 it blames another change and waits for a signature that will never come. The text should say to check whether the staged files are this branch's own.
disposition: step 7 recognised the agent's own leftover squash and went on to the message; the D5 test was red with the old sentence restored (`9b237f9`). Finding-8 replaced the judgement with an exact test.

**finding-3**: requirement, low — skills/merge-change/references/rationale.md:18-19 says that at step 7 "the primary checkout's index holds only one staged squash at a time". The section the same file adds at :236-241 says the opposite: git stacks a second squash, and the index holds one only if the agent checks. Line 19 should say it holds one only because step 7 checks.
disposition: the rationale's "Changes open in parallel" says the index "holds one staged squash only because step 7 checks the index before staging its own"; the D5 test pins it and was red on the old rationale (`9b237f9`).

**finding-4**: code, low — The D4 test (tests/skills.bats:500-529) never checks the claim-check snippet itself. Its anchor `grep -qF 'git diff "$BASE...$branch"'` (:527) also matches the prose at before-opening.md:72. In a scratch copy I replaced the snippet's test (before-opening.md:57) with `if git grep -q "$id" "$branch"`, which is the very approach the doc rejects, and the test still passed. No test runs either snippet, so a broken snippet goes unnoticed. That includes its POSIX-sh and `(`-case form, because tests/portability.bats scans scripts only.
disposition: test `worktree-discipline: the before-opening snippets run, and the claim check reads the diff` runs both snippets in a scratch repository and requires the exact output; it fails with the claim check replaced by `git grep -q "$id" "$branch"`, with a paren-less case pattern, and with untracked files left out of the dirty count (`9b237f9`).

**finding-5**: code, low — The D1 test (tests/skills.bats:702-719) is titled "changes may run in parallel", but it only checks that the old wording is gone. In a scratch copy I made two edits, and the test passed after each: deleting README.md's new sentence (README.md:70-71), and appending "Bring a change to its signed squash before opening the next." to AGENTS.md.
disposition: the D1 test also requires README's sentence "Changes may run in parallel, each in its own change worktree" and the absence from AGENTS.md of "Bring a change to its signed squash before" and "before opening the next"; red after each of the reviewer's two edits (`9b237f9`).

**finding-6**: requirement, low — skills/worktree-discipline/references/before-opening.md:64-79 states one limit of the claim check: a branch whose only edit is a status line. It does not state a second one: the check reads committed history only, so a claim another session has not yet committed in its worktree goes unseen. Check (a) prints that worktree's dirty count, but the doc does not tie the two together.
disposition: `before-opening.md` states that the check reads committed history only, and that a worktree (a) lists with a dirty count above 0 may hold a claim to look at or ask about; the D4 test pins both and was red on the old text (`9b237f9`).

**finding-7**: record — The roadmap's D4(b) (docs/plans/2026-10-06-salvage-churn-and-parallel.md, D4) says to `git grep` the ID on each branch. The change uses a diff against the base instead (plan T3 step 2; before-opening.md:68-73). The deviation is justified and the plan records its reason. The roadmap's D4 text was not amended, so the verification record should name the deviation.
disposition: named here: the roadmap's D4(b) says to `git grep` the ID on each branch; the change reads each branch's three-dot diff against the base for an added or removed line naming the ID, because every branch contains an ID defined on the base. The plan's T3 step 2 records the reason; the roadmap's D4 text is left as decided.

### Round 2

Reviewed at `4daf6fd`. Reviewer's suite: 1..1106, 1106 ok, 0 not ok. Verdict: changes requested — one medium requirement finding.

**finding-8**: requirement, medium — skills/merge-change/SKILL.md:228-231 tells the agent "if the check fails and the staged files are this branch's own, a signing failed earlier: go on to the message", but gives it no test for "own". If it compares file names, it will guess wrong, because parallel changes often touch the same files (`tests/skills.bats` is in every change here). I reproduced this in a scratch repo. Branches `mine` and `other` both edit file `a`, and `other`'s squash is staged. `git diff --cached --name-only` prints `a`, so the staged squash looks like `mine`'s. `git diff --cached --quiet mine` exits 1 and `git diff --cached --quiet other` exits 0. An agent that guesses wrong hands over a commit that signs the other change's content, or its own outdated squash, under this change's message. `finish-merge.sh` guard 2 (`git diff --quiet HEAD <branch>`) notices only after the signed commit is already on the base branch. Name the exact test: `git diff --cached --quiet <branch>` exits 0 only when the staged tree is this branch's tree, because step 1 merged the base in. Put the same test in the rationale paragraph (skills/merge-change/references/rationale.md:252-254).
disposition: step 7 names the exact test, `git diff --cached --quiet <branch>`, which exits 0 only when the staged tree is the branch's; the rationale says why file names cannot tell (fix commit `cfb4035`). The table in the fix report: with `other`'s squash staged, `--quiet mine` exits 1; with `mine`'s, 0.

**finding-9**: code, low — tests/skills.bats:529 (`grep -qF 'git diff "$BASE...$branch"'`) does not protect the snippet. The same string appears in the prose of skills/worktree-discipline/references/before-opening.md:78. The run test (tests/skills.bats:536-603) never moves the base branch forward, so two dots and three dots give the same result there. Mutation: I changed the check's `"$BASE...$branch"` to `"$BASE..$branch"`. Every worktree-discipline test still passed. With two dots, once another change resolving the item has merged, every older unmerged branch shows that change's ID lines as `-` lines and is reported as `CLAIMED`. Either make the test advance `main` with a line containing the ID after the branches are cut, or grep the extracted `claims.sh` and not the whole file.
disposition: the run test commits a line naming the ID to `main` after the branches are cut, so a two-dot diff fails it, and the static check reads the extracted snippet rather than the whole file (`cfb4035`).

**finding-10**: code, low — tests/skills.bats:1726 checks that step 7 contains the condition "staged files are this branch's own" but not what to do next. Mutation: I replaced "go on to the message" with "wait for the user". The test "merge-change: step 7 checks for a staged squash before staging its own" still passed, which is the wait-on-itself case round 1 finding 2 was meant to guard. Likewise, the D2 test (tests/skills.bats:1699) only catches a reintroduced precondition that contains the exact phrase "one change at a time". A bullet worded "Only one open change" passed.
disposition: the D5 test requires the action on each outcome ("go on to the message", stop and tell the user); the D2 test requires exactly three Preconditions bullets, none naming an open, one or next change; each mutation the reviewer named is red (`cfb4035`).

### Round 3

Reviewed at `da3197e`. Reviewer's suite: 1..1106, 1106 ok, 0 not ok. Verdict: not ready — one high requirement finding.

**finding-11**: requirement, high — The parallel-change race that the removed precondition used to prevent is open between step 1 and step 7. D1 and the new rationale (skills/merge-change/references/rationale.md:8-20) say "step 1 merges the latest base every round, so a change merged meanwhile reaches every other change before its gate runs again". But if change A is signed after B's last step 1 and before B's step 7, B finds an empty index. The check passes, and `git merge --squash B` runs as a non-fast-forward three-way merge with exit 0. Step 7 (skills/merge-change/SKILL.md:223-230) then goes straight to the message and the hand-over, so a tree the gate never saw (A+B) is signed onto main. finish-merge.sh guard 2 (scripts/finish-merge.sh:23-25) rejects only after the signed commit has landed. Reproduced in $TMPDIR/rv-race: B's compound exited 0, and `git diff --cached --quiet B` exited 1 with `A a.txt` showing as the difference. Running `git diff --cached --quiet <branch>` after every squash, not only when the pre-check fails, would catch this: any result but 0 means rerun from step 1. With parallel changes now permitted, this is a normal-use state.
disposition: step 7 runs `git diff --cached --quiet <branch>` after every squash; when the squash ran and the comparison fails, the base moved after step 1, and the agent runs `git reset --merge` and reruns from step 1 (`git merge --abort` fails after a squash: "MERGE_HEAD missing"). The D5 test runs the base-moved case in a scratch repository: the squash exits 0, the comparison 1, and after the reset and a step 1 rerun, 0 (fix commit `720ab16`).

**finding-12**: code, low — The rationale's account of `git merge --squash` over a staged squash is incomplete (skills/merge-change/references/rationale.md:244-246, "When it fast-forwards, it exits 0 and stacks its files onto the first; otherwise it fails with a message naming the other change's files"). Measured: a fast-forward squash stacks only when the two changes touch different files. When both edit the same file, even different lines, the fast-forward also fails with "Your local changes to the following files would be overwritten by merge: shared.txt" and exits 1. The conclusion still holds (the check is needed), but the sentence ties failure to the non-fast-forward case alone.
disposition: the rationale states that a squash over a staged one stacks only when the two touch different files and the squash fast-forwards; a shared file, or any non-fast-forward, is refused with "would be overwritten" (`720ab16`, measured again by round 6).

**finding-13**: code, low — In step 7 the && compound exits non-zero both when the index check fails and when the squash itself fails (a conflict). skills/merge-change/SKILL.md:227-230 reads any failure as "the check fails", and the follow-up then calls the agent's own conflicted squash "another change's or an outdated one" and offers "once they sign or clear it". Measured: a conflicted own squash gives own-test exit 1. Stopping is right, but the stated cause and the "sign" remedy are wrong in that state. Git's printed conflict message names the true cause, hence low.
disposition: step 7's outcomes are read from what the first line printed: git output means the squash ran (or conflicted) and the base moved, so reset and rerun; nothing printed means a squash was already staged, so stop and tell the user (`720ab16`; the D5 test's conflict case clears with `git reset --merge`).

**finding-14**: code, low — The D4 run test (tests/skills.bats, "the before-opening snippets run, and the claim check reads the diff") does not pin some behaviour that before-opening.md documents. Mutations in a scratch copy: dropping `^[-+]` from the claim grep survives, so a context line carrying the ID next to an unrelated edit would read as a claim; dropping the `("prunable"*)` arm survives; dropping the `branch='(detached)'` reset survives; dropping `--no-merged` survives, which is harmless; breaking the ahead count is killed. The scratch repository has no prunable or detached worktree and no edit next to an ID line, though before-opening.md:41-44 states the prunable and detached output.
disposition: the run test adds a detached worktree, a prunable one, and a branch whose diff shows the ID line only as context; dropping `^[-+]`, the prunable arm or the detached reset each fails it (`720ab16`).

### Round 4

Reviewed at `d60427f`. Reviewer's suite: 1..1106, 1106 ok, 0 not ok. Verdict: not ready — one high code finding and one medium requirement finding.

**finding-15**: code, high — The claim check in `skills/worktree-discipline/references/before-opening.md:59-66` gives a silent false negative under zsh. That is the shell this repository's agent Bash tool runs in (`ZSH_VERSION=5.9`, `$SHELL=/bin/zsh`). The snippet uses `for id in $item_ids` (line 61), and zsh does not word-split an unquoted variable. So with `item_ids='PR-abc123 REQ-zzz999'` the loop runs once, greps for the literal string "PR-abc123 REQ-zzz999", prints nothing and exits 0. Line 68 reads "No output means no unmerged local branch ... claims". Reproduced in a scratch repo where branch `fix-parser` adds `resolves: PR-abc123`: `zsh -c` with both IDs printed nothing (rc=0); zsh with one ID, `/bin/sh` and `dash` with both IDs all printed `CLAIMED  PR-abc123  by fix-parser`. Snippet (a), line 19 onward, also breaks under zsh: `path=` is zsh's array tied to `PATH`, so every later `git`/`wc`/`tr` is "command not found". That failure is loud, but every line comes out as `ahead ?  dirty   last`. The doc never says to run either snippet with `sh`. The D4 test (`tests/skills.bats`, "the before-opening snippets run…") runs them only under `sh`, so it cannot catch this. D4(b), the check that would have stopped the 2026-10-06 duplicate PR-s8dcmp, passes in normal use whenever a change claims two or more IDs.
disposition: each check runs as `BASE="$BASE" sh <<'EOF' … EOF`, (b) with `item_ids` on that first line, and (a)'s variable is `worktree_path`; the run test pastes the fences as a user would and runs them under `sh` and zsh, and was red under zsh on the old text, (a) printing "command not found" and (b) nothing (fix commit `579e678`).

**finding-16**: requirement, medium — Under parallel changes, a base merge at step 1 that happens after the last reviewer was dispatched is signed without any review. `skills/merge-change/SKILL.md:154-156` makes an all-`low` round the last review round: "rerun from step 1 — but no further reviewer is dispatched". Step 7's base-moved remedy (`SKILL.md:229-230`, "rerun from step 1") also gets no reviewer. If another change was signed in between, that rerun's step 1 merges it in and resolves any conflicts. The gate reruns, because the tree hash changed, but no reviewer sees the conflict resolution. Before D1 the base did not move mid-change by rule, so this path did not arise. The rationale's new section (`skills/merge-change/references/rationale.md`, "## Changes open in parallel") claims the merge reaches the other change "before its gate" and stays silent on review. Either a step-1 merge that resolved conflicts after the last review should dispatch a reviewer again, or the rationale should state that this is accepted.
disposition: ruled by the maintainer on 2026-10-07: the test is file overlap, not git conflicts; a base merge that shares a file with the change reruns the whole process, a fresh reviewer included, and one on disjoint files reruns the gate only. Step 1 prints a `shared:` line per file both sides edited, 6a then reviews the whole change even after the last round, the rationale states why, and `templates/verification.md` asks the record to name the shared files and the round. Test `merge-change: a base merge that shares a file with the change gets a fresh review` runs the fence on a shared and a disjoint base edit; red on SKILL.md, rationale.md or the template as they were (`579e678`). Finding-21 later changed what step 1 compares against.

**finding-17**: code, low — Step 7's outcome rule misdiagnoses a dirty primary checkout. Line 1 prints git's output whenever the squash is refused, not only when the base moved. In scratch repos, an unstaged edit to a file the squash touches gave "error: Your local changes to the following files would be overwritten by merge". An untracked file in the way gave "untracked working tree files would be overwritten". In both cases line 2 exited 1, and `SKILL.md:229-230` reads that as "the base moved after step 1. Run `git reset --merge`, then rerun from step 1". `git reset --merge` exited 0 and kept the edit, so the rerun hit the same refusal and would loop. Nothing is lost, and git's message names the true cause. The same rule also covers a squash another session stages between this session's index check and its merge: `git reset --merge` then clears that other session's squash. That race needs simultaneous step 7s.
disposition: step 7 gains the outcome "git printed that files would be overwritten: the primary checkout is dirty; stop and tell the user", and the rationale states the simultaneous race, measured in a scratch repository (`579e678`); the race is in Gaps.

**finding-18**: requirement, low — One cut from merge-change SKILL.md dropped part of an instruction. At 2d0bbba (line 175) it read "Not every round creates one: a human reviewer uses their checkout. `remove` fails on a tag that was never started, so skip it there." Now (`SKILL.md:168-169`) it reads "Not every round creates one, and `remove` fails on a tag that was never started, so skip it there." That clause named when to skip, and it appears nowhere else in `skills/merge-change/` (grep for "their checkout" finds nothing), so "there" has no antecedent. The line break after "`remove`" is also stray. Minor: "exit 2 … from the pre-flight or a tool it runs" lost "or a tool it runs" (`SKILL.md:101-102`).
disposition: "a human reviewer uses their checkout" and "or a tool it runs" are restored and pinned by existing tests (`579e678`).

**finding-19**: code, low — The D5 test (`tests/skills.bats:1749-1812`) only greps prose. It never runs step 7's two lines against a repository, so none of the git-behaviour claims it pins (the three outcomes, three-way exit 0, `git reset --merge` clearing a conflicted squash) is checked against git. The D4 snippets are executed (round 1, finding 4). The D5 test's comment at `tests/skills.bats:1752-1754` still states the claim round 3 finding 12 corrected in the rationale: "exits 0 and stacks its files onto the first when it fast-forwards". With a shared file and a fast-forward, git refuses (reproduced: "would be overwritten … f.txt", rc=1).
disposition: the D5 test runs step 7's two lines in scratch repositories for a clean squash, the own leftover squash, another change's squash, an untracked file in the way, and a moved base, and the stale comment is corrected; with the text checks removed, it still fails with `&&` replaced by `;`, with the comparison against `HEAD`, and with the index check dropped (`579e678`).

**finding-20**: record — `docs/plans/2026-10-07-parallel-changes.md:59-63` (T2 step 3) states as a measurement that a second squash "exits 0 and stacks its files onto the first when it fast-forwards, and fails … when it does not". Reproduced: with a shared file and a fast-forward it fails. With different files and no fast-forward it fails, naming the other change's file (b.txt). T2 also describes only the index check. It does not record the round-3 additions to step 7 (the `git diff --cached --quiet <branch>` comparison and the `git reset --merge` remedy), which go beyond the plan and beyond D5.
disposition: the plan's T2 step 3 states the corrected measurement (`f3d7966`), and its "Review rounds" section records step 7's comparison and `git reset --merge` (`f3d7966`, `871c9e0`).

### Round 5

Reviewed at `b1a52f3`. Reviewer's suite: 1..1107, 1107 ok, 0 not ok, exit 0. Verdict: changes requested — one medium requirement finding.

**finding-21**: requirement, medium — The `shared:` line appears only on the step 1 run that performs the merge. Step 1's own bullet sends every failure back to step 1 ("Halt on any failure … Then rerun from step 1"), so the maintainer's file-overlap ruling can be skipped in normal use. The failing path is the very case the ruling targets. After an all-low last round, step 1 merges a base that edited a file the change edited, and it prints `shared: shared.txt`. The step 2 gate then fails, which is likely when two changes edit one test file. A fix is dispatched and the sequence reruns from step 1. That rerun prints nothing: the merge base now includes the base, and git says "Already up to date". So no reviewer is dispatched ("the rerun ends at 6b", skills/merge-change/SKILL.md:161), and the shared-file merge is signed without review. I reproduced this in a scratch repo: first run `shared: shared.txt`, then after a fix commit the rerun printed only "Already up to date." Nothing tells the agent to carry the obligation across reruns or to write it down before 6b: skills/merge-change/SKILL.md:54-57, skills/merge-change/references/rationale.md:21-27 and :172, templates/verification.md:67-68. The obligation needs to persist until a reviewer has seen a tree at or after that merge. For example: record the `shared:` files in the plan or record when they print, or compute the overlap against the commit the last reviewer saw rather than against the last base merge.
disposition: 6a first makes an empty `git -c commit.gpgsign=false commit --allow-empty -m 'review dispatched'`; step 1 finds the latest such commit and lists the files the base edited since its merge-base that the change also edits, so a rerun after a failed gate prints the `shared:` line again until a new reviewer is marked. Reproduced in a scratch repository: the old commands printed only "Already up to date." on the rerun, the new ones `shared: shared.txt` (fix commit `07ff7de`). The shared-file test was red with the overlap taken against the last base merge.

**finding-22**: requirement, low — Step 1's overlap test misses a file the base renamed. `git diff --name-only` detects renames by default and prints only the new name. Scratch repo: the change edits line 2 of `tests.bats`; the base renames it to `moved.bats` and edits line 19. Step 1 printed no `shared:` line, yet the merge combined both edits in `moved.bats`. This is one shared file under the ruling, and it got the gate only (skills/merge-change/SKILL.md:43-44). `--no-renames` on both diffs would list the old path on both sides. Separately, mutating `grep -Fx` to `grep -F` (substring match) survives every test.
disposition: both diffs take `--no-renames`, so a file the base renamed is listed under its old path; the shared-file test fails with either `--no-renames` removed or `grep -Fx` cut to `grep -F` (`07ff7de`).

**finding-23**: requirement, low — skills/worktree-discipline/references/before-opening.md:17-19 says "Run bare in zsh, the checks fail". Only (b) fails. Check (a)'s body run bare under zsh printed the correct status lines and exited 0, because its variable is `worktree_path`, not `path`. (b) bare under zsh does print nothing, as stated. The sentence should name (b) only.
disposition: `before-opening.md` says only (b) fails when run bare under zsh; checked under zsh: (a) printed its lines, (b) nothing (`07ff7de`).

**finding-24**: record — The comment at tests/skills.bats:507-508 says "(b) sets item_ids in a fence of its own before the check". (b) is now one fence with `item_ids` on its first line (before-opening.md:61). The comment is stale; the helper's behaviour is still correct.
disposition: the comment in `tests/skills.bats` describes (b) as one fence with `item_ids` on its first line (`07ff7de`).

### Round 6

Reviewed at `86017fa`, the first `review dispatched` marker. Reviewer's suite: 1..1107, 1107 ok, 0 not ok. Verdict: converged — two low requirement findings and one record finding; with nothing above low, this is the last review round. The reviewer ran the marker mechanism in scratch repositories across nine cases, found no path by which two parallel changes interfere other than the simultaneous step 7 race the rationale accepts, and checked that the empty marker commits do not trip the squash, `finish-merge.sh` or `check-review.sh`. No shared file entered at step 1 after any round: `main` stayed at `2d0bbba`.

**finding-25**: requirement, low — `skills/worktree-discipline/references/before-opening.md:73-76` says a `CLAIMED` line "means another change claims the item". The check also prints `CLAIMED` for a branch that only mentions the ID, for example as evidence in a plan. I ran check (b) under /bin/sh and zsh against this repository with BASE=main and `item_ids='PR-s8dcmp PR-h3wujj'`. It printed `CLAIMED  PR-s8dcmp  by parallel-changes` and the same line for `parallel-changes-review`. This change does not resolve PR-s8dcmp; it only cites it as evidence in its plan. The limits paragraph at :85-92 states the false negatives (a status-only edit, an uncommitted claim) but not this false positive. The user is asked, and the line names the branch, so nothing is lost.
disposition: `before-opening.md` says a `CLAIMED` line means the named branch's diff adds or removes a line naming the ID, which a branch that only cites the ID also does; the agent reads those lines with `git diff "$BASE...<branch>" | grep -e "^[-+].*<id>"` and asks the user before opening a second change. The limits paragraph states the false positive (fix commit `c5a9962`).

**finding-26**: requirement, low — `before-opening.md:12-14,24,61`: when base detection fails, both checks still run with BASE empty if the block is pasted whole. Check (a) then prints `ahead 0` for every worktree, which looks like valid data, and (b) prints `fatal: malformed object name` and no `CLAIMED`. This happened in this repository: there is no `.guardrails/scripts/lib.sh` on `main` or in the worktree, and the run printed `.guardrails/scripts/lib.sh: No such file or directory`. That error names the cause, so this is low. merge-change's precondition uses the same detection line, so the gap predates this change; the new snippets just don't guard against it.
disposition: the first line of each snippet is `[ -n "$BASE" ] || { echo 'BASE is empty: detect the base branch first' >&2; exit 1; }`, and the prose says why. The D4 run test runs each snippet with `BASE=` under `sh` and zsh and requires a non-zero exit, the message, and no status or `CLAIMED` line; it was red before the guard, (a) exiting 0 with `ahead 0` for every worktree (`c5a9962`).

**finding-27**: record — `docs/plans/2026-10-07-parallel-changes.md:143-160`: "Review rounds" says it lists what the rounds added "so the plan describes the tree". It does not mention round 5's addition (finding-21): the empty `review dispatched` commit at 6a and step 1 comparing against that commit's merge-base. It also does not mention the template line that asks the record to name the shared files and the review round (`templates/verification.md:67-68`).
disposition: the plan's "Review rounds" has a bullet for round 5's marker commit and the template line, and one for round 6's fixes (`c5a9962`).

## Gaps

- `tests/evidence.sh` cannot show these tests red: it swaps in `main`'s `scripts/`, `tests/` and `templates/` only, and every D-test reads `AGENTS.md`, `README.md`, `skills/` or `docs/`, so against `main` they fail on missing files, not on the old text. Its round 1 count (5 of 5 red) is not evidence; the red runs above rest on the dispatch reports.
- The claim check sees committed lines that name an ID. It misses a branch whose only edit is an item's `status:` line, and a claim not yet committed; it flags a branch that only cites the ID (finding-25). `before-opening.md` states all three, and each is answered by asking the user.
- Two sessions running step 7 at the same instant can both pass the index check. The second's comparison catches the stacked tree, and its `git reset --merge` clears the first session's squash too; if the user signed the first in that window, the signed commit holds both changes, and `finish-merge.sh` guard 2 catches it only after it has landed. The rationale states and accepts this.
- `review dispatched` is found by `git rev-list --grep`, which would also match a commit body line reading exactly that.
- A test that dates a fixture with `days_ago` and is checked after midnight fails: the first gate run on the final tree crossed midnight and failed `check-trace: trailing whitespace on a field is not part of its value`. It is outside this change and is not yet a problem item.
- `main` did not move during this change, so the `shared:` path and step 7's base-moved path were exercised in scratch repositories and tests only, never on this change's own merge.
- `merge-preflight.sh` does not run in this repository, which has no `.guardrails/config.yaml`. `check-review.sh --branch parallel-changes` ran on a scratch copy of the commit that added this record: exit 0, 27 findings for `parallel-changes`.
