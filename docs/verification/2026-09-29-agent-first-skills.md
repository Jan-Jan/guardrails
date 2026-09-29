# Verification — agent-first-skills (2026-09-29)

branch: agent-first-skills
reviewer: rounds 1 to 7, each a fresh subagent with the diff, both plans and the earlier findings, and no implementation narrative
verdict: round 1 REJECT; round 2 REJECT; round 3 REJECT; round 4 REJECT; round 5 REJECT; round 6 REJECT; round 7 REJECT on record findings only, the last review round
reproduced: not applicable as a defect reproduction. The change adds the tested skill shape and rewrites `merge-change` into it. The measurement behind it is the word count of each SKILL.md, stated in the proposal. Round 1 finding 7 was reproduced directly, as its disposition states.

Change: the SKILL.md shape (D5, D9) and its first application, to `merge-change` (D4, D6). Branched from `main` at `fc88138`; `main` at `70cd996` merged in. The base was merged from local `main`, per AGENTS.md non-negotiable 5.
Plan: `docs/plans/2026-09-28-agent-first-skills-change-1.md`, under the proposal `docs/plans/2026-09-28-agent-first-skills.md`.

## The gate

The final pass of the sequence, after round 7, the last review round. The
toolkit has no `.guardrails/config.yaml`, so the check scripts ran under a
synthesized config: `id_prefixes: PR`, `doc_problems: docs/problems`,
`doc_verification: docs/verification`, `strict_paths: scripts`,
`test_paths: tests`. `check-ids.sh` and `check-trace.sh` are red on `main`
already, so the criterion is no finding on the branch that `main` lacks.

Measured on: `2752d07` — tree `a075b6d5d5a545461d045538716e6a2dce409fd6`,
clean worktree, against `main` at `70cd996`. Step 3 renamed nothing on this
pass, so this is the tree step 2 measured.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..749`: 749 ok, 0 not ok, 0 skipped, counted from TAP lines |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on branch and `main`; sorted findings identical |
| `check-trace.sh` | exit 1 on branch and `main`; the branch adds `UNRESOLVED-PR` for `PR-zmzav3`, `PR-sa5y4k` and `PR-2jr4pj`, and nothing else |
| `check-review.sh` | exit 0, every finding dispositioned |
| `finish-merge.sh --check agent-first-skills` | exit 0, nothing registered inside the change worktree |
| Coverage, against the class target | not configured; the toolkit is unclassified |
| Working tree | clean at start and end |

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| D9 | skill shape: every SKILL.md has the D9 sections in order | failed on merge-change's old headings before T2 |
| D9 | skill shape: every shape exemption names a skill still out of order | failed with `nonexistent` added to the exemptions |
| D5 | skill shape: every SKILL.md is at most 2,000 words | failed with `ratchet` removed from the exemptions |
| D5 | skill shape: every ceiling exemption names a skill still over it | failed with `plan-change` added to the exemptions |
| D6, D9 | skill shape: the References section lists exactly the reference files | failed with a stray reference file present |
| D4 | the retargeted tests of T2: the fix-dispatch tag test, the step 8 guard 4 test, and the three multi-unit tests | each failed while its reference file did not exist |
| D6 | merge-change: text the first rewrite lost is stated again | failed on the pre-fix skill |
| D4 | merge-change: the tag does not shorten the sequence, three assertions made live | each failed with its phrase appended to the rationale file |
| D6, D9 | skill shape: the References section lists exactly the reference files, round 3 heading assertion | failed with an empty `## References` in a skill with no reference file |
| D6, D9 | the same test, round 3 entry-form assertion | failed with an entry lacking `— read when` |
| D6, D9 | the same test, round 4 entry-form and heading assertions | failed with the section as one prose line, with a `* ` bullet with no condition, and with a trailing-space heading |
| D6 | merge-change: text the first rewrite lost is stated again, round 4 pointer assertions | failed against the pre-change rationale file, and with the cited phrase removed from three scripts |
| D6 | the same test, round 5 absence assertions | each failed with its removed pointer appended back |
| D6 | merge-change: the rationale file describes no script | failed on the pre-fix rationale file |
| D6, D9 | skill shape: the References section lists exactly the reference files, round 6 entry-line check | failed with a file named only on a continuation line |

Problem ledger: opens `PR-zmzav3`, `PR-sa5y4k` and `PR-2jr4pj`; resolves and accepts none.

## What was wrong, and what was built

The shipped skills total about thirty thousand words, and `merge-change` alone
was 7,322. Most of that text was reasons, incident history and conditional
material, loaded on every use. This change adds five gates to
`tests/skills.bats`: a fixed section order, a 2,000-word ceiling, exemption
lists that fail when an exemption is no longer needed, and a check that the
`References` section and the `references/` directory agree. It then rewrites
`merge-change` into that shape. The normal path stays in `SKILL.md`. The
multi-unit sequence, the cleanup rejection table and the reasons move to three
reference files. Incident history is dropped. `merge-change` remains over the
ceiling and exempt until change 2 scripts its procedure.

## Review

### Round 1

**finding-1**: code — Three retargeted assertions in "merge-change: the tag does not shorten the sequence" (verifies PR-3s74u3) are inert: `! grep -rq 'finding-free round'`, `! grep -rq 'runs only on the last round'` and `! grep -rq 'never reaches a later step…'` at tests/skills.bats:1471-1473. Each is a bare `! grep` that is not the test's last command, and bash suppresses errexit for a negated command. The reviewer appended each phrase to references/rationale.md or references/multi-unit.md, and the test stayed green; appended to SKILL.md, 'finding-free round' stayed green there too, so the defect exists on main.
disposition: Fixed. Each is now `run grep -rq … ` followed by `[ "$status" -ne 0 ]`. Each was watched failing with its phrase appended and passing once removed. The same defect class on other lines is `PR-7za3at`, recorded by the `audit-inert-assertions` change; the other lines it names are unchanged here.

**finding-2**: requirement — A normative instruction was lost: "The reviewer still reads the record, and still raises what is wrong with it. What changes is the price of a finding against it." (main SKILL.md:379-380). It is in neither the new SKILL.md nor references/, and the plan's "What was dropped" section does not list it.
disposition: Restored in step 6a after the convergence rule. The test "merge-change: text the first rewrite lost is stated again" reddens without it.

**finding-3**: requirement — A normative instruction was lost: "If the harness offers a compaction step (e.g. a `/compact` command), name it so the user can run it." (main SKILL.md:650-651). New step 8 keeps only "recommend compacting".
disposition: Restored in step 8. The same test reddens without it.

**finding-4**: requirement — A rule changed in meaning. Main states class C gets "a thorough review (consider two independent reviewers for critical items)", which is advisory. The new SKILL.md states "C a thorough review, with two independent reviewers for critical items", which is mandatory. No decision covers the change.
disposition: Restored as advisory: "For class C, consider two independent reviewers for critical items." The same test reddens on the mandatory wording and without the advisory one.

**finding-5**: requirement — Step 6c no longer states that `check-review.sh` checks the four required fields. The new code list omits `INCOMPLETE-RECORD`, which scripts/check-review.sh:372 emits and which is the rejection for a missing field. The red flags cite "(step 6c)" for rejecting a record with no verdict, but step 6c no longer states that.
disposition: Step 6c states what the gate checks, including "contains all four fields with values", and lists `INCOMPLETE-RECORD`. The same test reddens without either.

**finding-6**: requirement — SKILL.md states "If the harness tool already left or removed the worktree, the script skips the removal and still deletes the branch." scripts/finish-merge.sh skips the removal only when no worktree is registered for the branch; a worktree the harness only left is still registered, so the script removes it. The new text also drops the instruction to leave or remove a harness-created worktree with the harness tool.
disposition: Step 7 states the condition, a worktree no longer registered for the branch, and restores the harness-tool instruction. The same test reddens without either.

**finding-7**: requirement — references/cleanup-rejections.md states re-running the whole compound "does nothing". Main and the scripts/finish-merge.sh header both state it wastes a key touch. The new text contradicts the script's own statement, and removes the reason behind "re-run the script alone, never the whole compound".
disposition: The contradiction is fixed on the other side. In a scratch repository with `gpg.program` set to a logging script, `git commit -S` with nothing staged printed `nothing to commit` and exited 1 without calling the signer; the control, the same command with a file staged, called it (git 2.55.0). So no key touch is spent, and the header comment of `scripts/finish-merge.sh` that stated otherwise is corrected. It is a comment, not behaviour; no mutation script quotes it. The reason for re-running the script alone is restored: the compound reads as though the merge needs redoing, and it does not.

**finding-8**: record — The plan's "What was dropped" section lists only incident history. D6 says reasons move to reference files, but several reasons and gate descriptions were dropped entirely: the race reason behind "one change at a time"; why step 2 records the tree; why the step 3 commit is conditional; why nothing downstream repeats the `unrewritten` line; that `superseded-by:` exempts nothing; the supersession gate detail; that `branch:` is matched and the filename is not; "their shell has none of your variables".
disposition: Each is restored. The three instructions are in SKILL.md: `superseded-by:` exempts nothing, the gate finds the record by `branch:` and not by filename, and the user's shell has none of your variables. The reasons and the supersession gate detail are in `references/rationale.md`. The test "merge-change: text the first rewrite lost is stated again" reddens without them.

**finding-9**: record — The plan's T1 and T2 blocks no longer match the tree. The plan shows helper `gr_skill_shaped` and stale-status `:shaped`, and its self-review names `gr_skill_shaped`. The tree has `gr_skill_has_d9_order` and `:in-order`. The SKILL.md, rationale.md and cleanup-rejections.md text in the plan's T2 block also differs from the tree. Commit 9991a60 made these edits, and the plan records nothing about that commit.
disposition: The plan gains a section "After T2: the tree is authoritative", naming `9991a60` and the round 1 fix as the two commits that changed the text, and its self-review names the current helper.

**finding-10**: requirement — D9 states that material that applies only under a condition goes to a reference file. SKILL.md 6b's sentence "In a multi-unit repository, the record also names the units touched, and the impact set" stays in SKILL.md and repeats references/multi-unit.md.
disposition: Moved into `references/multi-unit.md`, and the test "merge-record-names-units" now reads that file.

**finding-11**: record — The proposal breaks the AGENTS.md replace list: "the tests that hold it", "when change 1 lands", "already hold them", "holds for change 1 only", "holds the interview rules".
disposition: Replaced with "enforce it", "is merged", "contain them", "is true for change 1 only" and "contains the interview rules".

### Round 2

The round 2 gate, on tree `1295f18a`, also failed check 4 of
`verify-before-merge`: the plan claims D4, and no `verifies:` line names it.
It is fixed with the findings below.

**finding-12**: requirement — finding-8's defect class is fixed only for the instances it named. D6 says reasons move to reference files. These reasons from main's SKILL.md are neither in `skills/merge-change/references/` nor in the plan's "What was dropped" list: why a local-ref base merge is recorded with its commit (main:102-107); why step 1 makes parallel changes safe in either order (main:203-206); what `MALFORMED-ID` means and that its item is invisible to every other gate (main:212-214); why step 6 dispatches again after renames (main:226-228); why the review worktree is nested (main:274-276); why the removal is skipped for a path never created (main:404-405); why `Resolves:` and `Opens:` go in the message (main:584-588); why the agent never runs the signing itself (main:597-599); why the script is never given a path (main:624-625); why step 8's `--strict` re-check costs only one re-read (main:641-644); the rejection-table reasons (main:660-662); the red-flag reason "A deleted finding and a finding that never existed read identically" (main:694).
disposition: The class was swept, not the list. The plan's section "Sweep of the old merge-change" maps each paragraph of `main`'s SKILL.md to where its content now is, or to `dropped: history`. All twelve named items and eleven further reasons the sweep found now have a heading in `references/rationale.md`. No instruction was missing from SKILL.md. The test "merge-change: text the first rewrite lost is stated again" gained one assertion per added reason, and reddens without them.

**finding-13**: requirement — skills/merge-change/references/rationale.md:4 states "Each heading names the step or rule it explains". The leaked-draft paragraph (rationale.md:63-67) is under "## Step 3: the finalize date", a heading about a different rule. The rules it explains, a rename you do not recognise (SKILL.md:94-95) and a `DRAFT-FILE` this change did not create (SKILL.md:118-119), have no heading.
disposition: The paragraph moved to its own section, "Steps 3 and 4: a draft another change left behind", with the step 4 `DRAFT-FILE` detail. The rationale file's headings now follow step order, and each names the step it explains.

**finding-14**: record — The plan header is stale after the round 1 fix. docs/plans/2026-09-28-agent-first-skills-change-1.md:10-11 states "81 of them in `tests/skills.bats` (76 before this change, plus 5)"; the tree has 82. Line 8 states the change touches skill text, tests and `AGENTS.md`, but the round 1 fix also edits `scripts/finish-merge.sh` (a comment) and the proposal.
disposition: The plan header now states 76 tests on `main` and 82 after the round 1 fix, and lists every file class the change touches.

**finding-15**: record — The record states "`merge-change` is 2,966 words before round 1". 2,966 is the count at the T2 commit 316722d. Before round 1 it was 2,960, and the current tree is 3,075, which the record does not state.
disposition: The Gaps line no longer states a count. A figure about a file this change keeps editing is false after the next edit; `wc -w skills/merge-change/SKILL.md` gives the current one.

### Round 3

**finding-16**: requirement — skills/merge-change/SKILL.md:285-286 states "This check answers guard 4 of step 7 only; guards 1 to 3 cannot be checked before the squash exists." Step 7 never numbers the guards, and its list puts the nested-worktree check third and the clean-worktree check fourth, so a reader of SKILL.md alone takes "guard 4" to be the clean check. The stated reason is also wrong for guard 3: scripts/finish-merge.sh:50-52 and references/rationale.md:241-243 state that guard 3 cannot be preflighted because it is the removal itself.
disposition: Step 7 lists the four guards with the script's own numbers, in the order it proves them: 1, 2, 4, 3. Step 6d states that its check answers guard 4 only, that guards 1 and 2 read the squash commit, and that guard 3 is the removal itself.

**finding-17**: code — tests/skills.bats:1692-1717, "the References section lists exactly the reference files" (verifies D6, D9), passes when a skill has an empty `## References` section and no references/ directory. D9 states that `References` is omitted when the skill has no reference file. No test checks D9's "each entry names the file and the condition for reading it".
disposition: Fixed. The test now also fails on a `## References` heading in a skill with no reference file, and on a References entry without the form `` `references/<name>.md` — read when ``. Each was watched failing in a scratch copy, and the tree passes.

**finding-18**: requirement — skills/merge-change/references/rationale.md:91-92 states "Widening a pattern to accept the token keeps the item invisible and removes the report." This is false: check-ids.sh and check-trace.sh share `gr_def_re` and `GR_ID_BODY` (scripts/lib.sh:740-742), so widening the pattern makes the item visible to every gate and admits an ID that `new-id.sh` did not mint. The round 2 sweep added this sentence.
disposition: The sentence now states the true cost: `check-ids.sh` and `check-trace.sh` share one ID pattern, so widening it admits everywhere an ID that `new-id.sh` did not mint. The class was swept: every sentence the round 2 sweep added was re-checked against the script it describes, and two more were corrected. One claimed IDs are allocated against nothing, when `new-id.sh` discards a candidate already in the tree. The other claimed a nested worktree is invisible to `git status`, when that is true only because `.worktrees/` is gitignored.

**finding-19**: code — Finding 7's defect class was fixed only at the named instance. scripts/finish-merge.sh:345-347 still states that one nested worktree per run costs "a hardware key touch apiece", and tests/finish-merge.bats:489-490 states "a hardware key touch per hidden worktree". A re-run of the script alone only verifies a signature, which needs no private key. These lines predate the change.
disposition: Booked, by the maintainer's decision of 2026-09-29, as `PR-zmzav3`, opened by this change. The defect predates it, and change 2 rewrites that procedure.

**finding-20**: requirement — SKILL.md:347-348 states that if `finish-merge.sh` exited non-zero "nothing was removed", and references/cleanup-rejections.md:4 states "Every rejection exits having removed nothing and deleted nothing." scripts/finish-merge.sh:385-386 exits 1 after `git worktree remove` has succeeded, when `git branch -D` fails. The table has no row for that case. Inherited from main:653-655.
disposition: Booked, by the maintainer's decision of 2026-09-29, as `PR-sa5y4k`, opened by this change. The defect predates it, and change 2 rewrites that procedure.

**finding-21**: record — The plan's section "After T2: the tree is authoritative" names `9991a60` and the round 1 fix as the commits that changed the embedded text. The round 2 fix, `0dabaf3`, also rewrote references/rationale.md, and the section does not name it. Finding 9's class again.
disposition: The section now lists every commit after T2 that changed embedded text, by SHA, and states no count.

**finding-22**: record — Under "## The gate" the record reads "Pending the round 2 measurement." The round 2 gate was measured, as the Round 2 section states. The pending measurement is round 3's.
disposition: The gate section now states that it is filled from the final round's gate, and it was.

### Round 4

The round 4 gate, on tree `128ff00a`, is green: 748 ok, 0 not ok, 0 skipped; `check-ids.sh` with and without `--allow-draft-files` identical to `main`; `check-trace.sh` identical to `main` apart from `PR-zmzav3` and `PR-sa5y4k` and the summary lines that count them; every Implements ID verified.

**finding-23**: requirement — skills/merge-change/references/rationale.md:42-43 states "IDs are random and minted against nothing, so two branches cannot collide by construction". scripts/new-id.sh:14-20 states "Collisions are DETECTED, not prevented", with DUPLICATE-ID as the detector, and rationale.md:69-72 states the same. The rewrite also dropped main's hedge "the scan was covering a vanishing case", which scripts/check-ids.sh:25 keeps. The sentence came from the round 2 sweep, so finding-18's disposition, that every sentence the sweep added was re-checked, is not accurate.
disposition: The sentence now states that the trade is sound only where one person merges, because the local base then contains every merged ID, and points to the `scripts/new-id.sh` header, which states that collisions are detected, not prevented. The class was addressed structurally: where a rationale paragraph restated a script's behaviour and the script's own comment states it, the paragraph now points to that comment. Paragraphs the scripts do not state were kept and each verified against the code, and a second false one was corrected, "greps the whole tree", which excludes the installed scripts. The test "text the first rewrite lost is stated again" asserts 15 of the pointer lines and, for each of those, that the cited comment exists in the script; an absence assertion fails on "cannot collide by construction" (corrected by finding 31).

**finding-24**: code — tests/skills.bats:1715-1720, the References test, checks the entry form only on lines starting with `- `. A References section rewritten as one prose line naming all three files, or an entry written as a `* ` bullet with no condition, both stay green. The heading check uses `grep -qx '## References'`, so `## References ` with a trailing space in a skill with no reference file also passes.
disposition: Fixed. The entry-form check reads every non-blank line of the section, and the heading check accepts trailing whitespace. Each of the three breaks was watched failing in a scratch copy, and the tree passes.

**finding-25**: requirement — AGENTS.md:139-142 states tests/skills.bats enforces the shape "with the exemptions that D5 and D9 of docs/plans/2026-09-28-agent-first-skills.md state". D9 states no exemptions. The section-order exemptions come from D3 item 3, which the comment on gr_shape_exempt_skills cites.
disposition: `AGENTS.md` names D5 for the ceiling exemptions and D3 item 3 for the section-order exemptions.

**finding-26**: record — The PR-sa5y4k report states the message printed on the `git branch -D` failure path, `the worktree was removed but <branch> could not be deleted`, "is accurate". scripts/finish-merge.sh:383-388 prints it also when no worktree was registered, where it is false.
disposition: `PR-sa5y4k` states that the message is accurate only on the path that removed a worktree, and names the other path in `affects:`. Edited in place.

**finding-27**: record — finding-22's disposition states the gate section "is filled from the final round's gate, and it was". The section contains no figures.
disposition: The gate section is filled from the final pass after the last review round, and names the tree it describes. It was not filled before, because every fix round changed the tree.

**finding-28**: record — The plan's round 3 "Files touched" lists `skills/merge-change/references/cleanup-rejections.md`, which none of the round 3 commits touch. The round 3 bullet of "After T2: the tree is authoritative" names no SHA, though finding-21's disposition states the section lists every commit by SHA.
disposition: The round 3 "Files touched" line no longer lists `cleanup-rejections.md`. "After T2" names the round 3 commits by SHA and adds the round 4 fix; a plan commit cannot name its own SHA, so the round 4 bullet names the two commits before it.

**finding-29**: record — The red → green table has no row for either round 3 attestation: the References heading assertion and the entry-form assertion.
disposition: The red → green table gains rows for the round 3 and round 4 attestations.

### Round 5

The round 5 gate, on tree `9a805f28`, is green on the same terms as round 4's.

**finding-30**: requirement — Finding 23's class is still open through two pointers. skills/merge-change/references/rationale.md:48-49 points to the `scripts/check-ids.sh` header, which states "IDs are minted ... and allocated against nothing, so two branches cannot mint the same one by construction" (scripts/check-ids.sh:23-26). rationale.md:83 points to scripts/finalize-docs.sh:26-28, whose reason is "that ID is allocated against nothing". Each comment states the narrower thing its pointer names, but a reader who follows either reads a statement two earlier rounds judged false, and which contradicts scripts/new-id.sh:14-18.
disposition: The claim is in nine files and predates this change, so it is booked as `PR-2jr4pj`, opened by this change, under the maintainer's round 3 rule. This change's text no longer points into it: the step 1 pointer to the `scripts/check-ids.sh` header is now a sentence verified against the code, and the two pointers that duplicated the `scripts/new-id.sh` pointer beside them are removed. Two absence assertions in "text the first rewrite lost is stated again" fail if either pointer returns; each was watched failing.

**finding-31**: record — The finding-23 disposition states that the test "checks each pointer and, for three of them, that the cited script comment exists". The test asserts 15 of the 27 pointer lines, and checks the cited comment for those 15, not three.
disposition: Corrected here: the test asserts 15 of the pointer lines and, for each of those 15, that the cited comment exists in the script. The other pointers are unasserted; neither D6 nor D9 requires a test per pointer.

**finding-32**: record — The plan header lists the file classes the change touches and leaves out the problem ledger file that round 3 added. Finding 14's class again.
disposition: The header now also names the two problem ledger files. It lists file classes rather than a count, so a later file of an existing class does not falsify it.

### Round 6

The round 6 gate, on tree `91a40f42`, failed `check-ids.sh` on one finding present only on the branch, `DUPLICATE-ID PR-2jr4pj`. The plan's round 5 section quotes the item's definition line at column one inside the embedded script, and the scan reads it as a second definition: the class of `PR-4hyuud`. The suite (748 ok, 0 not ok, 0 skipped), `check-trace.sh` apart from the three opened items, `check-review.sh` and the Implements map are green.
The quoted line in the plan is indented by the round 6 fix, and `check-ids.sh` no longer reports `DUPLICATE-ID PR-2jr4pj`.

**finding-33**: requirement — Finding 30's class is still open. Two other pointers send the reader to the `scripts/finalize-docs.sh` header: skills/merge-change/references/rationale.md:56 and rationale.md:71. The text rationale.md:71 cites, scripts/finalize-docs.sh:29-33, is in the paragraph that opens at :26-28 with "that ID is allocated against nothing". So the finding-30 disposition, "This change's text no longer points into it", and docs/problems/2026-09-29-id-allocation-claim.md:15-17, "points only to `scripts/new-id.sh`", are false.
disposition: The class is removed at its source, by the maintainer's decision of 2026-09-29: the rationale file no longer describes any script and contains no pointer to one. It keeps only the reasons for the agent's process rules, naming a gate's report where a reason needs it. The finding-30 disposition and the `PR-2jr4pj` report both stated that the file pointed only to `scripts/new-id.sh`; the report now states that it names no script.

**finding-34**: code — The round 5 absence assertions at tests/skills.bats:1808-1813 match only the exact wording of the two removed pointers, not the rule their comment states. The rule is broken in the tree (finding-33) and the test passes; an appended "`scripts/finalize-docs.sh`, header: why no ID is assigned at merge." stays green.
disposition: The two wording-specific absence assertions are replaced by the test "merge-change: the rationale file describes no script", which fails on any `scripts/` path or `.sh` name in the file. It was watched failing on the pre-fix file.

**finding-35**: code — The D9 entry-form check can be satisfied with an entry missing. names_in_section (tests/skills.bats:1699) collects file names from every line of the section, and malformed_entries (:1719) accepts any indented line after a valid entry. Deleting the `references/rationale.md` entry and naming the file on the continuation line of another entry stays green.
disposition: Fixed. The References test collects listed names only from entry lines, those opening with a `references/` entry. The copy with a file named only on a continuation line was watched failing, and the tree passes.

**finding-36**: record — The plan section "After T2: the tree is authoritative" leaves out the round 5 task commit `c4256df`, which changed rationale.md and tests/skills.bats. Finding 21 and 28's class again.
disposition: "After T2" names the round 5 task commit `c4256df` and adds the round 6 fix.

### Round 7

The round 7 gate, on tree `a00f7882` against `main` at `70cd996`, is green: 749 ok, 0 not ok, 0 skipped; `check-ids.sh` identical to `main`; `check-trace.sh` identical apart from the three opened items and their summary lines; `check-review.sh` clean; every Implements ID verified.

Round 7 raised no `code` and no `requirement` finding, so it is the last review round. Its findings are answered here, and the sequence reran from step 1 to this record with no further reviewer.

**finding-37**: record — The `PR-2jr4pj` report states "Nine files" make the claim and lists them in `affects:`. A tenth is missing: README.md:100-103 states an ID "is allocated against nothing, so two worktrees, or two GitHub PRs, can never contend for one".
disposition: `README.md` is added to `affects:`. The report no longer states a count: it names the `git grep` that found the sites and the date it was run, so the list can be re-derived instead of trusted.

**finding-38**: record — The plan's section "Sweep of the old merge-change" still maps old text to six rationale headings the round 6 fix deleted, and its closing claim that every reason is under a rationale heading with a `grep -q` on it is no longer true. Nothing marks the sweep as superseded, and the finding-12 disposition is stale in the same way.
disposition: The sweep section opens with a note that the round 6 fix superseded it in part, states what that fix removed, and names the tree as authoritative. The finding-12 disposition describes the round 2 fix as made; this disposition and finding 33's record what replaced it.

## Gaps

- Nothing measures agent behaviour. The suite proves which rules are present in
  the text, not that an agent follows the slimmer skill as well as the old one.
  The proposal states this limit.
- `merge-change` remains over the ceiling, exempt by name, until change 2.
- The `scripts/finalize-docs.sh` header states that it renames this change's
  draft ledger files; the loop renames every draft. `merge-change` step 3
  states the loop's behaviour. The header is outside this change, and the gap
  it belongs to is recorded in `docs/problems/2026-09-15-field-report-two.md`.
- `PR-7za3at` is defined on `main` since `70cd996`, merged here. This change
  makes three of the lines it names live, in "merge-change: the tag does not
  shorten the sequence", and does not resolve it: the other lines it names
  are unchanged.
