# Verification — class B field-report fixes (2026-09-10)

branch: field-report-items
reviewer: PENDING
verdict: PENDING
reproduced: Partly, and the split is the point. Of the 43 tests this change
adds, **33 were watched failing for the right reason** before their fix existed,
each with its observed error text in the red → green table below. The other ten
are recorded as what they are rather than attested, in three kinds:

**Seven passed on first run** — three covering `--check` paths that already
worked (`--check refuses a failing git worktree list`, `--check refuses a
failing awk`, `-n is --check`), one pinning supersession accumulation (`two
supersedes: lines in one block are both judged`), and three guarding the
boundary of the malformed-supersession rule — and every one was then proved
killable by deliberately breaking its path and watching it redden. That step is the only thing separating coverage from
decoration, and it is why these are listed rather than quietly counted as
green.

**Two assert an ABSENCE** (`a reciprocal supersession pair is silent`, `an
affects: line naming a superseded ID is not a finding`) and cannot distinguish
the fix from its absence at all. The independent reviewer ran them against the
reverted script and confirmed they pass there — so they are scope controls,
not evidence.

**One** (`--check reports two nested worktrees in the plural`) passes vacuously
against the code it was written for; its evidence sits in the sibling test that
was watched failing.

Independently corroborated: round 2's reviewer reverted `scripts/` and
`skills/` to `51f01b7` and ran this change's tests against them, and exactly
the attested set failed. Nothing recorded here as watched-red could have passed
against the unfixed code. The field conditions
themselves — a guard-4 refusal after a hardware-key touch, four items ruled on
and left aging, a supersession half-applied across six sites — were measured by
the reporting project, not re-staged here; each is quoted with its measurement
in the ledger items.

Change: **four** items resolved and **three** left open, in a ledger of seven.
Three of the four are the defects the class B field report named; the fourth
(`PR-dr7k7k`) and two of the three open (`PR-crcee5`, `PR-z6uaa8`) were found
while fixing them. Counts derived from the ledger, not from this sentence's
previous draft, which said "three defects … two more recorded open" and was the
THIRD copy of the miscount round 6 raised as finding-27 — caught here while
staging the squash, after the finding's own disposition observed that a
correction which does not ask where else the number appears is half a
correction. Branched from `main` at `51f01b7`.
Plan: `docs/plans/2026-09-10-field-report-fixes.md`.

## The gate

Every figure derived from the tree under test, not carried forward.

**A gate table can never name the commit that contains it** — writing the row
changes the tree the row describes. The rows below name `798790d`, the last
commit before this paragraph; the commits after it touch only this file, which
no test reads. That is checked rather than assumed: the three bats files
mentioning `docs/verification` all build fixtures under their own tmpdir, and
the single reader of the real path is `portability.bats`, which scans
`*.mutations/` for `sed -i` spellings and is unaffected by an edit to a record.
The regress terminates there, on a fact about the test suite rather than on an
assurance.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` (**at `798790d`, the tree under merge**) | `1..677`, 677 ok, 0 not ok, exit 0 — run against the exact tree being squashed, after the last commit, not carried from an earlier one |
| `sh tests/run-tests.sh` (round 6, at `146f590`, superseded — reviewer's independent re-run agreed) | `1..677`, 677 ok, 0 not ok, exit 0 |
| `sh tests/run-tests.sh` (round 5, at `0a3725b`, superseded — reviewer's independent re-run agreed) | `1..677`, 677 ok, 0 not ok, exit 0 |
| `sh tests/run-tests.sh` (round 4, at `b009a5f`, superseded) | `1..677`, 677 ok, 0 not ok, exit 0 |
| `sh tests/run-tests.sh` (round 3, at `3fba8fd`, superseded — reviewer's independent re-run agreed) | `1..673`, 673 ok, 0 not ok, exit 0 |
| `sh tests/run-tests.sh` (round 2, at `dee4ee4`, superseded — reviewer's independent re-run agreed) | `1..666`, 666 ok, 0 not ok, exit 0 |
| `sh tests/run-tests.sh` (round 1, at `8ced23f`, superseded) | `1..655`, 655 ok, 0 not ok, exit 0 |
| `check-ids.sh` | re-derived at `798790d`: exit 1, **52 findings over 55 output lines** (51 `DRAFT-ID`, 1 `DUPLICATE-ID`, plus a 3-line advisory), under the config quoted in Gaps — **identical to the base commit**, verified by running the same gate in a probe worktree at `51f01b7` and diffing: the only difference is line numbers shifted by exactly +8 in `tests/check-ids.bats` from comments this change added. The figures move with the config; the comparison does not. See Gaps. |
| `check-trace.sh` | re-derived at `798790d`: exit 1, **25 findings** under the same config: 13 `DANGLING-REF`, 7 `UNRESOLVED-PR`, 4 `MISSING-TEST`, 1 `MISPLACED-ITEM`; summary `problems: open 7, accepted 0`. Re-derived at `0a3725b`+ — an earlier draft said 24/6, written before `PR-z6uaa8` was added and never re-run, which round 5 caught as the same carry-forward finding-9 rejected round 2 on. The three resolved items have left the roll-call. Of the 13 dangling refs, 8 are new and every one is a fixture ID inside a `printf` string in `tests/check-trace.bats`, the same class as pre-existing `PR-b4m8p3` (line 1869). See Gaps. |
| Coverage, against the class target | Not configured; guardrails is a development tool, not class-rated software. |
| Working tree | clean at `798790d` |
| `finish-merge.sh --check` (step 6d, the preflight this change adds) | exit 0, `nothing is registered inside <change worktree>` — guard 4 proved before the squash and before the key touch, which is the round trip `PR-k77dzn` exists to remove |
| `check-review.sh --branch field-report-items` (step 6c) | exit 0, `findings 33`, one record for this branch |

The base was merged from local `main` at `51f01b7`, per **AGENTS.md
non-negotiable 5**, which this change adds: the local repository is the whole
world and `origin` is never consulted. `git merge main` reported `Already up to
date`, so the merge was a proven no-op.

That rule replaces a caveat this record carried through four review rounds. The
merge began by attempting `merge-change` step 1's fetch, which failed on the
hardware key (`sign_and_send_pubkey: signing failed for RSA
"cardno:23_406_477" from agent: agent refused operation`) against a clone whose
last successful fetch was 2026-09-03; the base was merged from the local ref as
step 1's own fallback allows, and "whether `origin/main` advanced since
2026-09-03" stood as an open gap. The new rule dissolves that gap rather than
answering it: the remote is out of scope by policy, so there is no unverified
remote state to disclose, and the fetch is not attempted at all. The user has
since pushed `main` to `origin` themselves, which is where that responsibility
now sits — an agent fetching on their behalf blocks on a key only they can
touch, which is the failure this rule removes from the sequence.

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| `PR-k77dzn` | `finish-merge: --check reports a nested worktree and removes nothing` | yes — `expected exit 1, got 2: guardrails: unknown argument: --check` |
| `PR-k77dzn` | `finish-merge: --check exits 0 when nothing is nested` | yes — `expected exit 0, got 2: guardrails: unknown argument: --check` |
| `PR-k77dzn` | `finish-merge: --check runs from the change worktree, before any squash` | yes — `expected exit 0, got 2: guardrails: unknown argument: --check` |
| `PR-k77dzn` | `finish-merge: --check refuses the base branch` | yes, on the SECOND writing. As first written it asserted only `status -eq 2`, which `unknown argument` already satisfied — it passed vacuously before the feature existed. Strengthened to assert the refusal text, then watched fail: `expected the base-branch refusal, got: guardrails: unknown argument: --check`. |
| `PR-k77dzn` | `finish-merge: --check never removes, even with everything green` | yes — `expected exit 0, got 2: guardrails: unknown argument: --check` |
| `PR-k77dzn` | `finish-merge: --check reports two nested worktrees in the plural, naming both` | Partly, and stated rather than dressed: this test passes vacuously against the unconditionally-plural code it was written for, so the evidence sits in its sibling — with the fix reverted, `--check reports a nested worktree and removes nothing` failed with `expected the SINGULAR nesting verdict, got: guardrails: registered worktrees lie inside …`. |
| `PR-4fwfjp` | `check-trace: an accepted problem with a disposition: is not stale and not counted open` | yes — `MALFORMED-STATUS PR-a4c7k2 (status: accepted — expected open or resolved)` |
| `PR-4fwfjp` | `check-trace: an accepted problem with no disposition: is INCOMPLETE-PROBLEM` | yes — `MALFORMED-STATUS PR-b3f8m5 (status: accepted — expected open or resolved)` |
| `PR-4fwfjp` | `check-trace: an accepted problem with no opened: is INCOMPLETE-PROBLEM` | yes — `MALFORMED-STATUS PR-g8m4r2 (status: accepted — expected open or resolved)` |
| `PR-4fwfjp` | `check-trace: an accepted problem does not count toward problem_open_max` | yes — `UNRESOLVED-PR PR-d5h9n4 (open 1 days)` with `MALFORMED-STATUS PR-e6j2p7` |
| `PR-4fwfjp` | `check-trace: an unrecognised status still names the three it accepts` | yes — `MALFORMED-STATUS PR-f7k3q8 (status: wontfix — expected open or resolved)` |
| `PR-4fwfjp` | `check-trace: an orphaned disposition: in a problem ledger is reported` | yes — exit 0 with no `ORPHAN-ANNOTATION` at all: the keyword was read by nobody |
| `PR-zt5c2v` | `check-trace: supersedes: with no matching superseded-by: is reported` | yes — exit 0, output only the `checked:`/`problems:`/`sources:` summary |
| `PR-zt5c2v` | `check-trace: superseded-by: with no matching supersedes: is reported` | yes — exit 0, same |
| `PR-zt5c2v` | `check-trace: supersession is read across ledgers, not only the SRS` | yes — exit 0, `PR 2` counted and nothing said |
| `PR-zt5c2v` | `check-trace: an orphaned supersedes: is reported` | yes — exit 0 |
| `PR-zt5c2v` | `check-trace: an orphaned superseded-by: is reported` | yes — exit 0 |
| `PR-zt5c2v` | `check-trace: supersedes: naming two predecessors is judged per predecessor` | yes — exit 0, `REQ 4` counted; re-witnessed by restoring `HEAD~1`'s `check-trace.sh` |
| `PR-zt5c2v` | `check-trace: a reciprocal supersession pair is silent` | **NO — asserts an absence and was green before the gate existed.** A scope control, not red → green evidence. |
| `PR-zt5c2v` | `check-trace: an affects: line naming a superseded ID is not a finding` | **NO — asserts an absence and was green before the gate existed.** A scope control on the boundary this change deliberately did not cross. |
| `PR-dr7k7k` | `skills.bats: develop-change: the loop greps the mutation anchors for a changed line` | yes — `grep -q 'mutations' "$skill"` failed against the unedited skill |
| `PR-4fwfjp` | `check-trace: an accepted problem's opened: is judged as a date` | yes — exit 0 with `opened: 2020-13-45`, printing `ACCEPTED-PR PR-a4c7k2 (accepted: …)` |
| `PR-4fwfjp` | `check-trace: an accepted problem's opened: cannot be in the future` | yes — exit 0 with a date two days ahead |
| `PR-4fwfjp` | `check-trace: the ACCEPTED-PR roll-call line carries the date` | yes — the roll-call assertion failed against a line with no date |
| `PR-zt5c2v` | `check-trace: a supersedes: value carrying no ID is reported, not dropped` | yes — exit 0 and total silence, only the `checked:` summary |
| `PR-zt5c2v` | `check-trace: a supersedes: with no value at all is reported` | yes — exit 0 and total silence |
| `PR-zt5c2v` | `check-trace: a superseded-by: value carrying no ID is reported too` | yes — exit 0 and total silence |
| `PR-zt5c2v` | `check-trace: a supersedes: list mixing a valid ID with an over-long one is reported` | yes — exit 0 and total silence, only the clean `checked:` summary |
| `PR-zt5c2v` | `check-trace: a supersedes: list mixing a valid ID with a too-short one is reported` | yes — exit 0 and total silence |
| `PR-zt5c2v` | `check-trace: a superseded-by: list mixing a valid ID with an over-long one is reported` | yes — exit 0 and total silence |
| `PR-zt5c2v` | `check-trace: a superseded-by: list mixing a valid ID with a too-short one is reported` | yes — exit 0 and total silence |
| `PR-zt5c2v` | `check-trace: prose after a supersedes: ID is not a malformed ID` | **NO — passed on first run**, a boundary guard on the new rule. Proved killable: widening the loose token to `^[ \t,]*[^ \t,]+` reddened it with `MALFORMED-SUPERSESSION … (supersedes: the — not an item ID)` and one line per prose word. |
| `PR-zt5c2v` | `check-trace: a parenthetical after a supersedes: ID is not a malformed ID` | **NO — passed on first run.** Proved killable the same way: `(supersedes: (was — not an item ID)`. |
| `PR-zt5c2v` | `check-trace: prose after a superseded-by: ID is not a malformed ID` | **NO — passed on first run.** Proved killable the same way. |
| `PR-zt5c2v` | `check-trace: a supersedes: list mixing a valid ID with a truncated prefix is reported` | yes — exit 0 in total silence, the valid ID recorded and the truncated entry gone |
| `PR-zt5c2v` | `check-trace: a superseded-by: list mixing a valid ID with a truncated prefix is reported` | yes — exit 0 in total silence, same shape |
| `PR-zt5c2v` | `check-trace: a truncated prefix at the head of a supersedes: list is reported` | yes, but NOT silently — it failed on the message: the all-empty backstop fired and echoed the whole value, `MALFORMED-SUPERSESSION REQ-s4pr2k (supersedes: REQ-, REQ-m7dq3v — no item ID in it)`, dropping the valid ID behind it. Caught imprecisely, not missed. |
| `PR-zt5c2v` | `check-trace: a lone truncated prefix is reported exactly once` | yes — reported once, but as `(supersedes: REQ- — no item ID in it)`; the test pins the count at one so the new walk path cannot double-report alongside the backstop it supersedes |
| `PR-zt5c2v` | `check-trace: two supersedes: lines in one block are both judged` | **NO — passed on first run; accumulation already worked.** A regression pin, proved killable: mutating the scan to `!sup_seen` reddened it while the existing one-line test stayed green. |
| `PR-k77dzn` | `finish-merge: --check with no registered worktree says nothing was inspected` | yes — `the verdict did not say nothing was inspected: … so guard 4 has nothing to refuse` |
| `PR-k77dzn` | `finish-merge: --check refuses a failing git worktree list, it does not report a clean tree` | **NO — passed on first run** (coverage of a working path). Proved killable: with `\|\| gr_die` deleted from the registry read, `expected a refusal, got 0` and the mode printed a clean verdict about a worktree it never read. |
| `PR-k77dzn` | `finish-merge: --check refuses a failing awk, it does not report a clean tree` | **NO — passed on first run.** Proved killable the same way, on the awk derivation. |
| `PR-k77dzn` | `finish-merge: -n is --check` | **NO — passed on first run.** Proved killable: `(--check\|-n)` → `(--check)` gives `unknown argument: -n`. |

## What was wrong, and what was built

A class B adopter running `0.5.1` at `5bc6495` reported eight points. Four named
a defect in this toolkit and are recorded in
`docs/problems/2026-09-15-class-b-report.md`; the other four are assessed in
that file's header and are not defects — fence scanning is settled doctrine and
the `MALFORMED-ID` the report's probe produced is `check-ids.sh` working as
documented, item-length guidance is guidance, an `--explain` mode is a
diagnostic downstream of a message problem, and citation checking had already
shipped as `DANGLING-FILE` in `51f01b7`, eleven commits after the report's
baseline.

**`PR-k77dzn` — guard 4 fired after the one step a human must perform.**
`finish-merge.sh` runs as the chained tail of `git commit -S`, so its
nested-worktree guard was first asked *after* the hardware-key touch, on a
condition knowable minutes earlier. The review protocol creates that condition
by construction: each round runs in a nested worktree. `--check` now proves
guard 4 alone, from anywhere including the change worktree — which the rest of
the script refuses — and removes nothing. Guards 1 and 2 read the squash commit
and cannot be preflighted at all; guard 3 *is* the removal. The report asked for
all four; only one is available, and the mode says so rather than inventing two
verdicts. The scan is factored into `gr_nested_worktrees` so the one guard whose
wrong answer loses work has a single definition, keeping every constraint of its
original site: no awk near a path, `(`-led case patterns for bash 3.2, a quoted
variable half, the load-bearing trailing `/`.

**`PR-4fwfjp` — a problem the project ruled on had nowhere to go.**
`check-trace.sh` admitted `open` and `resolved` and nothing else, so a decision
had no shape to take and kept aging toward `STALE-PROBLEM`. This ledger already
carried the defect three times over, in three separate items, in the phrase
"accepted gap". `status: accepted` now exists, requiring `disposition:` — that
requirement is what makes the status safe rather than a one-word escape from
both limits, reachable by an author staring at a red `PROBLEM-BACKLOG` — exempt
from `STALE-PROBLEM` and `problem_open_max`, and still reported as `ACCEPTED-PR`
and counted in the summary. An accepted item that stopped being reported is how
"decided" decays back into "forgotten".

**`PR-zt5c2v` — `supersedes:` was prescribed by a skill and read by no script.**
`grep -rn supersede scripts/` matched nothing. Reciprocity is the half a gate can
prove and would have caught five of the six sites the adopter measured, in one
pass. The tree-wide sweep for stale references is deliberately NOT implemented —
an `affects:` line may legitimately name an old ID as history, so it has no
unambiguous verdict — and `merge-change` now says so plainly, so the next
adopter budgets for it.

Three items are recorded **open**. `PR-h3wujj` (the `traces:`/`satisfies:` block
asymmetry) is the only one of the four that goes red on ledgers already written,
and needs `templates/problems.md` fixed and a ratchet migration note first;
bundling a hard cut with three additive fixes is how a change becomes
unmergeable. `PR-z6uaa8` was found last and by the user rather than by any gate: the skills
an agent executes are installed copies that have drifted from `skills/`, seven
of eleven of them, and nothing reports it. `PR-crcee5` was found while fixing
the others: 38 of this
repository's 184 mutation scripts can no longer apply, so a fifth of its
mutation evidence is unreproducible and no gate reports it. That count is the
figure this change is responsible for leaving behind, not the one it found
mid-flight — an earlier draft of this paragraph said 41 and 22%, which was a
measurement taken before three of the five anchors this change itself broke had
been re-cut. Round 4 found it still standing here after rounds 2 and 3 had
corrected the same numbers in the ledger and in the findings; the item and the
narrative now agree, and both were re-measured against the merged tree.

**Five** mutation anchors were re-cut here, each proven live rather than merely
re-quoted — M21 applies and kills 11 tests, M22 kills 2, M31 kills 2, M03 kills
2, M38 kills 1. Three were found by hand while writing the change; M03 and M38
survived into the independent review, which is how the count reached five. M31
and M38 are the instructive pair: both staled by **duplication** rather than by
an edit, because a new awk block came to contain their anchored line verbatim,
taking `s.count(old)` to 2. Reading the diff would not have shown either — only
the grep does. That is why `develop-change` step 6 now
tells the author to grep the mutation directories for any changed output line,
and to prove a re-cut anchor still kills tests — an anchor that matches again
and kills nothing means the tests never covered it.

## Review

Round 1 returned **REJECT** with seven findings, every one of which was
confirmed in the source before it was acted on. The reviewer also ran the suite
itself in its own nested worktree and reported `1..655`, 655 ok, 0 not ok,
counted from the TAP lines — it did not rest on the step 6 summary, because the
diff touches `scripts/`.

Two things the reviewer did that are worth recording. It reverted each script to
`51f01b7` in a throwaway worktree and re-ran the new tests, so its verification
of verification is a measurement rather than a reading — 14 of `check-trace.bats`
went red, all six `--check` tests went red. And it independently reached the same
conclusion this record already stated about the two absence-asserting
supersession tests: it watched them pass against the unfixed script and
explicitly declined to file it, because the ledger discloses it. A disclosure
that survives an independent attempt to falsify it is worth more than the
disclosure alone.

**finding-1**: The change stales two mutation anchors it did not re-cut, so it breaks the rule it introduces in the same commit range. `M03.sh` anchors `if (st != "open" && st != "resolved") {` — the exact line the `accepted` branch rewrote — and now fails `mutation did not apply: 0 matches`; `M38.sh` anchors `if (!opd_seen || opd == "")` and now fails with 2 matches, because the accepted branch added a second occurrence. 38 dead at `51f01b7`, 40 dead at `8ced23f`: the change re-cut three and broke two, leaving the corpus worse than it found it, and `PR-crcee5`'s recorded arithmetic no longer describes the tree.
disposition: Confirmed directly — M03 matched 0, M38 matched 2. Both re-cut, M03 to the three-value condition and message, M38 widened with the open branch's `printf` to restore uniqueness (probed 2 → 1). Each proved live rather than merely re-quoted: M03 applies and kills 2 tests (`a status: value outside the closed set is malformed`, `an unrecognised status still names the three it accepts`), M38 applies and kills 1 (`an empty opened: is an omission, not a date`). The corpus is back to the 38 that predate this change. `PR-crcee5` rewritten to 38 with an AMENDED paragraph stating that its own first figure of 41 was a mid-flight measurement recorded as final. The reviewer's arithmetic and two independent audits reconcile exactly: 38 + 5 broken − 3 re-cut = 40 at `8ced23f`, and 38 now. Reddens without the fix: running `M03.sh` or `M38.sh` exits non-zero on its own assertion.

**finding-2**: `tests/skills.bats:701` carries `# verifies: PR-4fwfjp`, an item about a third problem status in `check-trace.sh`. The test asserts nothing about `status: accepted`; it pins the mutation-anchor obligation. No gate catches this — `MISSING-TEST` does not apply to `PR` and `DANGLING-REF` resolves the ID — so the false trace survives into the merged record, and `develop-change`'s new mandatory step 6 is left with no item requiring it.
disposition: Both halves accepted. `PR-dr7k7k` minted and written for the real defect — the obligation lived in no skill, only in a reviewer's habit and in three ad-hoc dispatch prompts, in a repository whose thesis is that prose loses to executed code — and resolved by the `develop-change` step, with that test as its reproduction. The annotation is re-pointed to `PR-dr7k7k` with a comment saying what it used to claim and why that was wrong. Reddens without the fix: `check-trace.sh` would report `PR-dr7k7k` as `DANGLING-REF` were the item absent, and the test itself reddens against the unedited skill.

**finding-3**: `templates/problems.md` gained the whole `accepted`/`disposition:` grammar and `docs/problems/README.md` did not. The two files were byte-identical apart from the README's header before this change; the README still reads `status: open|resolved`. Precedent: `860dce4` updated both files in one change. Consequence: the reference implementation's own ledger grammar contradicts its own gate, and an author of this repository's next problem item is told `accepted` is a `MALFORMED-STATUS`.
disposition: Accepted; the precedent is exact. `docs/problems/README.md` now carries the third status, the `disposition:` requirement and its reason, the roll-call and summary behaviour, and the orphan rule — matching `templates/problems.md`. Both files also gained the date rule finding-5 produced, so the two stay in step rather than being reconciled twice. Reddens without the fix: nothing, and that is the finding's point — no gate compares the two files, which is why it took a reader.

**finding-4**: The `--check` preflight duplicates three code paths from the removal mode and none of the three has a test. A branch with no registered worktree exits 0 printing `no worktree is registered for <branch>, so guard 4 has nothing to refuse` — a green that means "nothing was inspected". The failing-`git worktree list` and failing-`awk` refusals are duplicated too, and the removal mode has a dedicated test for each because they are false-green risks; the preflight's copies are untested. The `-n` alias is untested.
disposition: Accepted in full. Four tests added, `finish-merge.bats` 26 → 30. **Three** of them cover paths that already worked, so they passed on first run and proved nothing until each was mutated to prove it can fail; the fourth, `--check with no registered worktree says nothing was inspected`, was watched red, because the wording changed with it — at `8ced23f` the script printed `so guard 4 has nothing to refuse`. The three were mutated as follows — deleting `|| gr_die` from the registry read produced exactly the false green the finding names (`expected a refusal, got 0`, the mode printing a clean verdict about a worktree it never read), the same for the awk derivation, and `(--check|-n)` → `(--check)` produced `unknown argument: -n`. The wording was also wrong, not merely untested: it sat beside `nothing is registered inside <path>` and read as the same family when no path had been scanned. Now `no worktree is registered for <branch>, so nothing was inspected`, with the likely cause named. Exit 0 kept deliberately — guard 4 genuinely has nothing to refuse, and exit 1 would be a lie in a mode where 1 means "guard 4 would refuse". `merge-change` step 6d now documents all three outcomes.

**finding-5**: `opened:` is required on an `accepted` item but is never validated and never reported, so the field is enforced as present and ignored as data. `gr_prflush()` returns from the `accepted` branch before reaching `gr_date_ok()`, so `status: accepted` with `opened: 2020-13-45` — or a date years in the future — passes at exit 0, while the identical value on an open item is `MALFORMED-DATE`. The roll-call line carries no date at all, contradicting the code's own justification for requiring the field.
disposition: Accepted; confirmed by reading the branch, which returns at the `ACCEPTED-PR` printf without ever reaching `gr_date_ok`. The accepted branch now validates the date exactly as the open branch does and rejects one more than a day ahead, and `ACCEPTED-PR` prints `(opened: <date>, accepted: <ruling>)`. The one-day tolerance is kept, for a different reason than the open branch's and stated in the code: nothing ages here, so there is no false-green age to clamp — what `opened:` records is when the problem was RAISED, and a date after today falsifies that on a ruled item as much as on an open one; the day of slack survives only because two local dates can disagree by a day. Three tests, all watched red first: `an accepted problem's opened: is judged as a date`, `… cannot be in the future`, `the ACCEPTED-PR roll-call line carries the date`. The `STALE-PROBLEM` and `problem_open_max` exemptions are untouched and still pinned, one of them re-asserted with a 400-day-old accepted item against `problem_age_days: 30`.

**finding-6**: A `supersedes:` or `superseded-by:` at column one inside an item block whose value contains no readable ID is dropped in total silence. `supersedes: the old requirement` and a bare `supersedes:` both yield the empty string, so no key is recorded, `NON-RECIPROCAL-SUPERSESSION` cannot fire, and `ORPHAN-ANNOTATION` cannot either — the backstop only sees lines outside a block. A supersession annotated with a typo, a prose value, or an empty one reads as no supersession at all: a half-applied supersession passing green, which is the case the gate was built to remove.
disposition: Accepted; the most serious of the seven, because it is the false-green class this gate exists to close, reintroduced by the gate. Confirmed by reading the collector: `split()` on an empty run yields one empty field and the `if (a[i] != "")` guard drops it. Now `MALFORMED-SUPERSESSION <ID> (supersedes: <value> — no item ID in it)` and `(supersedes: has no value)`, for both keywords, via a shared `sup_run()`. Three tests, all watched red first — each previously exited 0 with nothing but the summary. Named in `merge-change` step 6a and in the `ratchet` upgrade note, the latter flagging it as the one that may surprise a ledger written in good faith. **This check then immediately caught a defect in this change's own ledger**: a line wrap had put `supersedes:` at column one inside `PR-zt5c2v`'s resolution prose, so a sentence about the annotation was read as the annotation. Reflowed, and the incident recorded in the item — it is also the field report's own D1 complaint, occurring in the change that assessed D1 as documented behaviour rather than a defect.

**finding-7**: The scan deliberately accumulates rather than first-occurrence-wins, and nothing tests it. `supersedes: naming two predecessors is judged per predecessor` puts both IDs on one line, which `gr_id_run` returns whole under either policy, so it cannot distinguish accumulation from first-wins. A future edit restoring the `!seen` guard used by every other keyword in that awk would silently drop the second annotation with the suite still green.
disposition: Accepted. `two supersedes: lines in one block are both judged` added, with the two annotations on separate lines. It passed on first run — accumulation already worked — so it is a regression pin rather than a bug fix, and was proved killable: mutating the scan to `!sup_seen` reddened it while the existing one-line test stayed green, confirming the finding's claim exactly. Recorded as a pin, not attested as red-to-green.

### Round 2

Round 2 returned **REJECT**. It re-verified all seven round-1 dispositions —
every one HOLDS, and none could be falsified — and measured, rather than read,
the claims this record makes about itself: the mutation corpus at **38 dead at
both `51f01b7` and `dee4ee4`, the two dead sets byte-identical**; M03 and M38
applying and killing 2 and 1; each "proved killable" test broken by hand; the
`STALE-PROBLEM` and `problem_open_max` exemptions holding for a 400-day-old
accepted item against `problem_age_days: 1` and `problem_open_max: 0`. It also
reverted `scripts/` and `skills/` to `51f01b7` and ran this change's tests
against them: **exactly 30 of the 32 failed, the only two passing being the two
this record labels absence-asserting.** Nothing attested as "watched red" could
have passed against the unfixed code.

The rejection rests entirely on new findings. One is a residual false green of
the class finding-6 named; **three are defects in this record itself**, which is
the part worth stating plainly — the artefact whose purpose is to let a later
reader re-run the evidence had three figures or names that did not describe the
tree it documents.

**finding-8**: `MALFORMED-SUPERSESSION` only fires when the annotation's value yields *no* readable ID, so a `supersedes:` or `superseded-by:` carrying one valid ID and one malformed ID-shaped token is still dropped in total silence. `supersedes: REQ-m7dq3v, REQ-a3k9z2x` (over-long body) and `supersedes: REQ-m7dq3v, REQ-nope` (short body) both leave `gr_id_run` non-empty, so `sup_run()` never reports, `gr_id_run` discards the bad token by design, and the run exits 0 — `check-ids.sh` exits 0 on it too, so no backstop catches it. The consequence is the exact case finding-6 was accepted to close: an author who mistypes one ID of a multi-ID supersession list has half a supersession recorded and half silently absent, passing green.
disposition: Accepted; the most serious of round 2, because it is the false green finding-6 closed, surviving inside the fix for it. `sup_malformed()` now draws `MALFORMED-ID`'s own line at the reference instead of the definition — loose-minus-strict over the DECLARED prefixes — rather than inventing a second opinion: a token in list position matching the loose form but not the strict one is reported, and the walk stops at the first position that opens no such token, which is where the list ends and commentary begins. Deliberately not caught, and stated in the code: prose after the list, a parenthetical (`verifies: REQ-001 (was REQ-042)` credits `REQ-001` alone toolkit-wide), an undeclared prefix, and a mistyped ID after prose has begun. Four tests watched red — each previously exit 0 with only the clean summary — and three absence guards holding the rule's boundary, proved killable by widening the loose token so all three reddened. The task also separated two paths the finding treated as one: an over-long body is matched by `gr_id_run` and then discarded, while a too-short one never matches and simply ends the run — a fix keyed only on "what `gr_id_run` discarded" would have closed the first and left the second silent.

**finding-9**: The verification record's gate table states `1..655`, 655 ok at both step 6 and step 2, and Gaps closes with "green at 655" — but the tree at `dee4ee4` has 666 tests. The figure was carried forward from `8ced23f`, in a record whose gate table is headed "Every figure derived from the tree under test, not carried forward." The consequence is that the record's only real gate for this repository is attested against a tree that no longer exists.
disposition: Accepted without reservation; the table's own heading condemns it. The gate table now carries the round-2 count for the tree under merge, the independent reviewer's separate re-run of the same tree beside it, and round 1's 655 kept but labelled superseded — a superseded figure is evidence of what was run when, and deleting it would leave the record silent about the round-1 gate. Gaps corrected to 666. This is the failure the heading exists to prevent, committed under the heading.

**finding-10**: `PR-crcee5`'s headline and AMENDED paragraph were corrected to 38, but its `affects:` line still carries the superseded 41-era breakdown: `2026-08-25-problem-triage.mutations (12 of 53)` where the measured figure is 9 of 53, and its five numerators sum to 41, not 38. The consequence is that the one open item whose entire content is a measurement contradicts itself inside a single block, in the field a reader would use to locate the dead anchors.
disposition: Accepted. All five directories re-measured against the merged tree rather than patching the single wrong number — 6/18, 10/54, 1/33, 9/53, 12/26, summing to the 38 the item claims — and the line now says when it was re-measured and why. The item's own AMENDED paragraph was written to stop a mid-flight figure being read as final, and it left that figure standing two lines above; the correction is recorded in the same block so the sequence of measurements is legible rather than tidied away.

**finding-11**: Three rows of the red → green table name tests that do not exist. The table attests `a supersedes: value carrying no ID is MALFORMED-SUPERSESSION`, `a supersedes: with no value at all is MALFORMED-SUPERSESSION` and `a superseded-by: value carrying no ID is MALFORMED-SUPERSESSION`; the tests are actually named `…is reported, not dropped`, `…is reported` and `…is reported too`. The other 29 rows match exactly. The consequence is that three of the change's red-attestations cannot be checked against the suite by the name they are recorded under — the same species of false trace as finding-2, in the artefact whose purpose is to let a later reader re-run the evidence.
disposition: Accepted, and it is the same mistake as finding-2 committed twice in one change: I wrote plausible names from memory instead of copying them out of the suite. Corrected to the three names the tests actually carry, taken from `grep` rather than recollection. Worth recording as a pattern rather than three separate slips — every name and figure in this record that was typed rather than copied has been re-derived from the tree since, which is how finding-9 and finding-10 were also caught.

### Round 3

Round 3 returned **REJECT**, and re-verified all four round-2 dispositions —
every one HOLDS. It reproduced the mutation corpus measurement independently and
got the same 38 of 184 with the same per-directory split (6/18, 10/54, 1/33,
9/53, 12/26), confirmed all 39 red → green rows name a `@test` byte-for-byte,
re-proved each of the seven killable tests with the error text this record
quotes, and probed the new malformed-supersession rule at 18 inputs.

Its three new findings are one residual code hole and **two more defects in this
record** — which, with findings 9, 10 and 11, makes five record defects across
three rounds, every one of the same kind: a figure or a label asserted from
memory rather than derived from the tree. That pattern is recorded in the Gaps
section as a finding about the process, not just about this document.

**finding-12**: `sup_malformed()` requires at least one body character (`(REQ|HAZ|RC|SDD|LLR|PR)-[0-9A-Za-z]+`), so a prefix truncated to its hyphen in list position is invisible. `supersedes: REQ-m7dq3v, REQ-` exits 0 in total silence with `REQ-m7dq3v` recorded and the second entry gone — likewise `PR-` and the `superseded-by:` spelling. The same token alone IS reported, by the all-empty path, so the gate calls one truncation a defect and the identical truncation beside a good ID nothing at all. This is finding-8's own stated consequence — "half a supersession recorded and half silently absent, passing green" — and it is not in the code's enumerated list of deliberate non-catches, so a reader of that comment would conclude it is covered. It is also outside the "loose minus strict" claim the fix rests on: `gr_def_re_loose` uses `[^*]*` and would convict `**REQ-**:` at the definition.
disposition: Accepted; the reference rule must match the definition rule, and `gr_def_re_loose` is the definition rule. Fixed by `+` → `*` in the loose form, so an empty body is loose-but-not-strict exactly as `**REQ-**:` is at a definition. The widening was checked against the three boundary guards rather than assumed safe: every guard stops at a position opening no declared-prefix-plus-hyphen at all (`—`, `(`, `FOO`), which an empty body never reaches, and termination holds because prefix-plus-hyphen is at least three characters (`RC-`, `PR-`) so the walk always advances. Four tests, two watched red in total silence (the two list-tail cases the finding measured), one watched red on an imprecise message, one pinning that the lone case still reports exactly ONCE — the walk path returns before the all-empty backstop, which is load-bearing and now carries a comment saying so. **The finding was wrong in one particular and the fix task said so**: the head-position case (`supersedes: REQ-, REQ-m7dq3v`) was never silent. A truncation at the head defeats `gr_id_run` entirely, so the run came back empty and the all-empty backstop fired, echoing the whole value while dropping the valid ID behind it. It was caught, imprecisely; the silent-and-green failure is specific to a truncation FOLLOWING a readable ID. The test now pins the precise message.

**finding-13**: The `check-ids.sh` gate row's "55 findings" is not reproducible, and the only synthesized-config recipe this repository records produces a different number — 67 findings using `2026-08-22-ratchet-gap-analysis.md`'s recipe (all six prefixes, `safety_class: A`). The same config cannot reach the `check-trace.sh` row's figures at all, since `doc_srs: docs/requirements` does not exist in this tree, so that script exits 2 before any gate. The record states the config was synthesized but never states what it was, so two of the six gate rows are figures a later reader cannot re-derive — the re-runnability axis round 2 rejected on.
disposition: Accepted, and it exposed a second error the finding did not name: **55 was the OUTPUT LINE count, not the finding count.** The run emits 51 `DRAFT-ID`, 1 `DUPLICATE-ID` and a 3-line advisory — 52 findings over 55 lines. Both rows now carry their full breakdown by verdict type, and the config that produces them is quoted verbatim in Gaps with the command to re-run it. The reviewer's 67 and this record's 52 are both correct and answer different questions: a config declaring all six prefixes reports on documents this change never edited, while the one used here declares `PR` alone because the problem ledger is the only ledger this change touches. Recording the config is what makes that difference legible instead of looking like a contradiction. The row's comparative half — identical to base but for a +8 line shift — was independently re-confirmed by this reviewer and needed no correction.

**finding-14**: The record's breakdown of the seven passed-first-run tests is wrong in two places. The header says "four covering `--check` paths that already worked, three guarding the boundary"; only three cover `--check` paths, the fourth being `two supersedes: lines in one block are both judged`, the supersession accumulation pin, which has nothing to do with `finish-merge`. finding-4's disposition repeats the error in the opposite direction — "Four tests added … each passed on first run and so proved nothing" — then lists only three mutations, while its own next paragraph explains the fourth went red because the wording changed, which the table row correctly attests. A reader reconciling the header against the table finds one `--check` row short, and the test this record insists must be filed as a regression pin is silently reclassified as coverage of a working path.
disposition: Accepted; both places corrected. The header now names the three `--check` tests explicitly and lists the accumulation pin separately, and finding-4's disposition says three were mutated and the fourth watched red, naming the message that changed under it. The error came from carrying round 2's "four" forward into a sentence describing a different set — the same transcription failure as findings 9, 10 and 11, and the reason the Gaps section now records it as a pattern rather than as three unrelated slips.

### Round 4

Round 4 was deliberately narrow — the delta only — and returned **REJECT** with
four findings, **none of them in the code**. The code delta (one regex character,
four tests) was corroborated hard: 33 hostile inputs driven through the real
script with a timeout, nothing hung, every boundary guard held, and all four new
tests reddened against the reverted script with the error text this record
quotes. **No finding was a defect in executable code.** Three were defects in
this document; finding-16's other half was a false termination proof written in
a comment inside `scripts/check-trace.sh`, which is prose that happens to live
in a script — the code it describes was correct throughout.

**finding-15**: The Gaps section states "Five of the eleven review findings were defects in THIS RECORD" and, twelve lines later, "the honest reading of eleven findings" — but the record carries fourteen (7 + 4 + 3 across three rounds), and the same sentence cites findings 13 and 14, numbers larger than its own denominator. Both occurrences are new in this delta, and they sit in the paragraph whose entire subject is figures asserted from memory rather than derived from the tree. Consequence: the record's summary of its own review history is arithmetically impossible on its face, in the one paragraph a later reader would use to judge how much its figures can be trusted.
disposition: Accepted. Corrected to nine of eighteen across four rounds, and the enumeration made explicit. Round 5 then found the corrected sentence still pointed at finding blocks that did not exist — see finding-20, which is the same defect one layer down and the reason this section exists at all.

**finding-16**: The termination argument for the widened walk is false as written. `scripts/check-trace.sh` says "the prefix plus hyphen is four characters, so the walk still advances and still terminates", but two of the six declared prefixes are two letters: `RC-` and `PR-` are three characters. The invariant survives — three still bounds `RLENGTH` above zero — so this is not a behavioural defect; the stated proof is. Consequence: the only recorded justification that the gate cannot hang is wrong about the shortest token it must handle, so a maintainer re-checking termination after adding or shortening a prefix is checking against a false lower bound.
disposition: Accepted and corrected in both places — the code comment and finding-12's disposition — with the two shortest prefixes named so the bound can be checked rather than trusted. Round 5 re-verified the corrected bound against the hard-coded regex: `RLENGTH >= 3`, the walk always advances, it terminates.

**finding-17**: The date disclosure's stated cost of re-renaming is contradicted by the tree it describes. It says "the rename also rewrote every reference to that file across the ledgers", but the finalize commit `8ced23f` is a pure rename — `1 file changed, 0 insertions(+), 0 deletions(-)` — and `git grep class-b-report` returns four hits, not one in a ledger. Consequence: a disclosed deviation from `merge-change` step 3 is justified by a cost the commit history shows does not exist, which is the record's own indicted error class committed inside the paragraph added to disclose it.
disposition: Accepted without argument, and the deviation removed rather than re-justified: the ledger was renamed to the merge date and the false cost claim deleted. Round 5 confirmed the rename is mechanically clean — no live reference to the old name, `finalize-docs.sh --dry-run` silent, no `DANGLING-FILE` — and that the "plans are never rewritten" half of the argument is true of the script itself, whose `rewrite_scope` is built from the five `doc_*` keys only. It also found the replacement paragraph had expired again; see finding-24.

**finding-18**: The narrative section still carries the superseded 41-era measurement — "41 of this repository's 184 mutation scripts can no longer apply, so 22%" and "Three mutation anchors were re-cut here" — while the record's own dispositions, and `PR-crcee5` itself, say 38, a fifth, and five. Consequence: the figure round 2 rejected on is still readable as current in the same document that claims to have corrected it, and three rounds of review passed over it.
disposition: Accepted. Both figures corrected in the narrative, which now states the five anchors individually with their kill counts and says which three were found by hand and which two by review. Round 5 re-derived the arithmetic independently — 184 scripts, five denominators matching the `affects:` line, numerators summing to 38, 38/184 = 20.7% so "a fifth" is right and 22% was the 41-era figure — and confirmed all five re-cut anchors match exactly once against the tree.

### Round 5

Round 5 returned **REJECT** with eight findings, again **none in the code**. It
verified the suite at 677 independently, re-derived the red → green table
(43 rows, the added-test set identical to the table set under `comm` both ways),
re-measured the mutation corpus, and confirmed **two** of round 4's four
dispositions outright — 16 and 18. The other two it reopened: finding-15's
correction still pointed at blocks that did not exist (finding-20), and
finding-17's replacement paragraph had already expired again (finding-24). A
disposition can be right about its arithmetic and wrong about its referent, and
both of those were. Its findings fall in two groups: three where this record
or its ledger asserted a figure that measurement contradicts, and the rest
where a correction had itself gone stale or was never written down.

**finding-19**: `AGENTS.md` non-negotiable 5 claims "Nothing downstream weakens" on the ground that "`check-ids.sh`'s duplicate scan reads the tree after that merge, and a tree is a tree whatever ref filled it." That reasons about the scan's mechanism, not its coverage: the `DUPLICATE-ID` scan's ID set IS the set in the merged tree, which is strictly smaller when the base merged is local and `origin` is ahead — so the gate does prove less. `merge-change` step 1 says so in terms and is left unamended: "Skip the fetch and that stops being true." Consequence: two normative documents in the reference implementation now state opposite conclusions about whether step 4 still proves what it claims, and an agent that reads the skill is told the override it has just been handed is unsafe.
disposition: Accepted; the claim was false and the rule is rewritten to say what the override costs instead of denying it has a cost. Step 4 does prove less, and non-negotiable 5 now says so. What makes it acceptable here is the ID scheme rather than the scan — `check-ids.sh`'s own header records that IDs are minted against nothing, so two branches cannot collide by construction and the base merge covered only "the vanishing case where random draws collide" — plus the fact that the same rule forbids agent pushes, so nothing reaches a shared history unreviewed. `merge-change` step 1 is amended to match: it now records that a project MAY put the remote out of scope, names this repository as the one that does, and says plainly that the trade is unavailable to a project with sequential IDs or several people merging to a shared remote. Neither document now contradicts the other.

**finding-20**: The record contains no Round 4 section and no findings 15–18. `grep '^\*\*finding-'` returns 14 and `grep '^disposition:'` returns 14, yet the record says "eighteen findings" and "across all four rounds", and Gaps cites findings 15, 16, 17 and 18 by number. `merge-change` step 6b requires "Each finding from 6a gets a block with its disposition." Commit `b009a5f` applied all four round-4 fixes and added no finding block. Consequence: four of the eighteen findings, and every change in `b009a5f`, are undocumented — a later reader cannot check one round-4 disposition, and the Gaps paragraph makes its central claim by pointing at four blocks that do not exist. `check-review.sh` cannot catch this: it requires a disposition per PRESENT block, and all 14 present blocks have one.
disposition: Accepted, and the most serious finding of the round — the fix for finding-15 was to correct a count that pointed at nothing, which made the arithmetic right and the reference still broken. The Round 4 section above now carries all four findings verbatim with their dispositions, as does this Round 5 section, bringing the record to 26 blocks and 26 dispositions. The gap existed because round 4's fixes were applied in one commit with the findings summarised only in its message: a commit message is not the record, and `check-review.sh` is structurally unable to notice the difference. Also corrected: the Gaps line reading "it took three rounds to stop being wrong", which contradicted "across all four rounds" in the same section and is now five.

**finding-21**: The gate table's `check-trace.sh` row is carried forward, not derived — "24 findings: 13 `DANGLING-REF`, 6 `UNRESOLVED-PR`, 4 `MISSING-TEST`, 1 `MISPLACED-ITEM`". Re-run at `0a3725b` under the config quoted in Gaps: 25 findings, 13/7/4/1, the seventh `UNRESOLVED-PR` being `PR-z6uaa8`, with summary `problems: open 7`. The row was written at `a726d4c` and never re-derived after `0a3725b` added a new open item. Consequence: a figure carried forward under the heading "Every figure derived from the tree under test, not carried forward" — the same defect finding-9 rejected round 2 on, committed under the same heading, by the same commit that created the item it fails to count.
disposition: Accepted; re-derived and corrected to 25 findings, 13/7/4/1, with the summary line quoted and a note saying what the earlier figure was and why it was wrong. This is the third time a figure in this table has gone stale between commits, which is the case for the process note in Gaps: the table is re-derived at the last commit before the squash, not when a row is first written.

**finding-22**: `PR-z6uaa8` states "Two of the seven (`merge-change`, `ratchet`) had already diverged from `main` before this change." Measured — each installed skill diffed against `main` — five had: `analyze-risks`, `check-traceability`, `grill-requirements`, `merge-change`, `ratchet`. The branch edits exactly four skills and seven differ, so three of the seven could not have been this change's doing. Consequence: the one item in this change whose entire content is a measurement understates its own headline scope by more than half, in the field a reader would use to size the fix.
disposition: Accepted; re-measured and corrected to five, with all five named and the four skills this change edits named beside them so the arithmetic is checkable. The item now carries an AMENDED paragraph rather than a silent correction, because an item recording that nobody was measuring the drift should not hide that its own first measurement was wrong.

**finding-23**: `PR-z6uaa8` states the seven carry "edits from `e2eac86` and `51f01b7` that never reached the install, so the drift is two generations deep rather than one." The installed `merge-change` and `ratchet` are byte-identical to `e2eac86`'s versions, and the install directories are dated 2026-09-05 10:13 against `e2eac86`'s commit time of 10:11:58. `e2eac86` reached the install; the drift is exactly one generation, `51f01b7`. Consequence: the item's most quotable claim is false, and it was falsifiable from the same two files the item says it compared.
disposition: Accepted; corrected to one generation, with the timestamps and the byte-identity recorded so the claim can be re-checked rather than believed. I confirmed it independently across all five pre-diverged skills, not just the two the reviewer named: every one is byte-identical to `e2eac86`.

**finding-24**: The merge-date rename has expired again and the paragraph defending it is false in two places. The ledger is named `2026-09-11` on the ground that "the squash is staged on 2026-09-11"; today is 2026-09-15, and `PR-z6uaa8` inside that file carries `opened: 2026-09-15`, so the earliest possible squash is four days past the filename. In the same passage, "The items inside carry `opened: 2026-09-10`" is false, and the stated bound "one day is its whole size" is falsified by the file it describes. Consequence: the deviation round 4 closed is reopened four times wider, by the commit that added the disclaimer saying it is closed.
disposition: Accepted. The file is renamed to `2026-09-15-class-b-report.md` and the paragraph rewritten to describe the MECHANISM rather than assert a date, because any claim about the squash date expires the moment signing waits — which is exactly how the first two versions of this paragraph became false. It now states the general property: a file named for an event that has not happened yet is correct only if the event happens that day, and a change taking five review rounds will not. The underlying convention is step 3's, not this change's, and is left stated rather than filed as an item.

**finding-25**: The ledger's title and header describe five items; the file holds seven. Title: "four items from a class B adopter's field report, and one found fixing them"; the header accounts only for `PR-crcee5` as found-while-fixing, while `grep '^\*\*PR-'` returns seven. Consequence: a reader counting the file against its own title finds two items the header never introduces, and the header's assessment of which reported points are NOT defects does not cover them.
disposition: Accepted. Title corrected to "three found fixing them", and the header now introduces all three non-report items — `PR-crcee5`, `PR-dr7k7k`, `PR-z6uaa8` — each with one line on how it was found, and states that its assessment paragraph covers the four reported points only. The count drifted because each of the three was added in a different round without anyone re-reading the title, which is the same failure mode as finding-21 in a different artefact.

**finding-26**: `PR-z6uaa8` attributes the drift to `install.sh --copy`, but the observed layout is produced by neither of that script's modes at its default destination: the default writes a symlink INTO the repo at `~/.claude/skills/<n>`, and `--copy` writes a real directory there. What is on disk is a symlink at `~/.claude/skills/<n>` pointing at `../../.agents/skills/<n>`, a real directory in a store holding non-guardrails skills (`solidity`, `find-skills`, `eli5`). That is consistent with `--copy` under `CLAUDE_SKILLS_DIR` plus a link farm, or with a third-party skills manager. Consequence: the cause is inferred from reading `install.sh` rather than measured, so the item's proposed scope may be aimed at a mechanism that was never involved.
disposition: Accepted, and the item rewritten to separate what was measured from what was inferred. The drift is measured; the cause is not, and the item now says so and lists identifying the installing tool as the FIRST question its own change must answer. The defect does not depend on the answer — no mode of any tool here reports that an installed skill has stopped matching its source, whichever tool installed it — so the finding narrows the scope without dissolving the item. The claim that re-running `install.sh` would close the instance is removed for resting on the same unmeasured premise.

### Round 6

Round 6 returned **REJECT** with seven findings and, for the third round
running, **none in executable code**. It re-derived every gate row
independently — the suite at 677, `check-ids.sh` at 52 findings over 55 lines
with the base diff exactly eight shifted lines, `check-trace.sh` at 25 findings
13/7/4/1, and the whole mutation corpus at 38 dead of 184 with the per-directory
split matching `PR-crcee5` numerator for numerator — and confirmed all three of
`PR-z6uaa8`'s re-measured claims. It also found the `AGENTS.md` argument sound
and, notably, over-generous: non-negotiable 4 forbids concurrent changes and
non-negotiable 5 forbids agent pushes, so `origin` cannot get ahead of local
`main` here at all, which makes the conceded cost smaller than conceded.

All seven findings are in prose written by the author of this record, and three
of them — 28, 29 and 31 — are defects inside the round-5 corrections, in the
sections written to record that round-5 corrections were needed.

**finding-27**: The narrative states "Two items are recorded open" and enumerates only `PR-h3wujj` and `PR-crcee5`; the ledger holds three open items — `PR-z6uaa8` is `status: open`, and the Gaps section fifteen lines later names all three. The count has been wrong since `0a3725b` added the item, and round 5's finding-25 fixed exactly this failure in the ledger's title while leaving the record's own copy of it standing. Consequence: the record contradicts itself about what the change leaves unfixed, and the item it calls "the most uncomfortable" is absent from the paragraph a reader uses to size the residue.
disposition: Accepted; corrected to three, with `PR-z6uaa8` introduced in that paragraph alongside the other two and its provenance stated — found by the user rather than by any gate. The failure is exact: finding-25 taught that adding an item in a later round leaves every count of that set stale, and the fix was applied to the ledger's title and to no other count of the same set. A correction that does not ask where else the number appears is half a correction.

**finding-28**: The record still points at the renamed-away ledger: line 128 reads "recorded in `docs/problems/2026-09-11-class-b-report.md`" while the file is now `2026-09-15-class-b-report.md`. The defect is created by this delta — at `0a3725b` line 128 correctly named `2026-09-11`. Worse, the Gaps paragraph in the same commit asserts the rename "costs one `git mv` plus the references in this record … and has been repeated", and finding-17's disposition asserts "no live reference to the old name". Nothing will catch it: `DANGLING-FILE` convicts only `DRAFT-<name>.md`, and `finalize-docs.sh` builds `rewrite_scope` from the five ledger keys, excluding `doc_verification`. Consequence: a reader following the record's single pointer to the ledger reaches nothing, in the round whose stated subject was that very rename.
disposition: Accepted, and it is the sharpest finding of the round because the same commit asserted the work had been done. I renamed the file and updated the Gaps paragraph and left the one navigable pointer untouched, then wrote that the references had been updated. Corrected to `2026-09-15-class-b-report.md`. The finding's mechanical half is also worth keeping: no gate can catch a stale path in a verification record, because `DANGLING-FILE` is scoped to draft ledger names and `finalize-docs.sh` never rewrites this directory — so this class is caught by a reader or not at all, which is the same conclusion the Gaps section reaches about every figure in this file.

**finding-29**: finding-26's disposition describes a fix that was not applied. It states the claim about re-running `install.sh` "is removed for resting on the same unmeasured premise". It is not removed — `PR-z6uaa8` still reads "Re-running `install.sh` here would close this instance", reworded from "on this machine" but identical in substance. Consequence: a disposition asserting a deletion the tree contradicts, in the block whose finding was about a claim resting on an unmeasured premise — the same shape as finding-20's "the arithmetic right and the reference still broken", one round later.
disposition: Accepted; the claim is now actually removed. The item says instead that what would close the instance is re-installing by whatever means put the copies there, which is the first open question rather than an assumption to act on. I reworded the sentence and recorded it as a deletion, which is the failure this finding names precisely: a disposition is a claim about the tree, and it has to be checked against the tree like any other.

**finding-30**: `AGENTS.md` non-negotiable 5 justifies the trade with "six characters from a 30-character alphabet". `GR_ID_ANY` is `[abcdefghjkmnpqrstuvwxyz23456789]` — 23 letters plus 8 digits = 31, and `new-id.sh`'s own comment names "the shipped 31-symbol alphabet" four lines from the code that derives it. Consequence: the one derived figure in the rewritten rule is a figure asserted from memory, and it contradicts the script the same paragraph cites three times verbatim — in the paragraph whose whole purpose is to price a safety trade-off so a later reader can re-check it.
disposition: Accepted. Corrected to 31 and the composition spelled out — 23 letters with the confusable ones dropped, plus 8 digits — so the figure can be counted from `GR_ID_ANY` rather than trusted. The paragraph quotes `check-ids.sh` correctly three times and then miscounts a set it could have counted; that is the whole pattern of this change's prose in one sentence, committed in the round that documented the pattern.

**finding-31**: The Round 5 preamble states round 5 "confirmed three of round 4's four dispositions outright". Two of the four were reopened by round 5's own findings, as the record's own text says: finding-15's disposition records that round 5 found the corrected sentence still pointing at blocks that did not exist, and finding-17's records that the replacement paragraph had expired again. Only 16 and 18 were confirmed outright. Consequence: the record overstates how much of round 4 survived round 5 by half, in the sentence a reader uses to judge whether the earlier round's fixes can be trusted.
disposition: Accepted; corrected to two, naming which two survived and which two were reopened and by which finding. The number was written in the same pass as the dispositions that contradict it, four paragraphs apart — the summary sentence was composed from memory of the round rather than counted from the blocks immediately below it.

**finding-32**: The record classifies findings 16 and 19 two incompatible ways in one commit. The Round 4 preamble says "All four findings were defects in this document", but finding-16's own disposition says it was corrected in "the code comment and finding-12's disposition", and the Gaps enumeration counts only "the record half of 16". Separately, the Gaps sentence is headed "defects in THIS RECORD or its ledger" yet counts "the argument half of 19", whose locus is `AGENTS.md`. Consequence: the seventeen-of-twenty-six figure that anchors the record's self-assessment cannot be reproduced from its own stated category.
disposition: Accepted; the category was too narrow for its own enumeration and is now **prose rather than executable code**, which is the honest line and is wider than this file: most of the seventeen are here or in the ledger, 16's half is a false termination proof in a code comment, and 19's is an argument in `AGENTS.md`. What unites them is stated instead of implied — no test could have caught any of them, because they are claims, and a claim is checked by re-deriving it or not at all. The Round 4 preamble is corrected to match: no finding was a defect in executable code, three were defects in this document, and 16's other half was prose that happens to live in a script.

**finding-33**: The gate table's only live suite row is unattributable. Rounds 1, 2 and 3 each name their commit; the round-4 row names none and asserts it is "the tree under merge", which has moved twice since — to `0a3725b` and then `146f590`, the latter editing `AGENTS.md` and `skills/merge-change/SKILL.md`, both read by `tests/skills.bats`. Round 5's own independent 677 is cited in the preamble but never recorded as a row, though rounds 2 and 3 record theirs. Consequence: the record's single real gate for this repository is the one row a later reader cannot tie to a tree.
disposition: Accepted. The suite now has a row per round, each naming its commit, with round 6's marked as the tree under merge and noting the reviewer's independent re-run at the same commit; rounds 4 and 5 are recorded and labelled superseded. The figure was right at every point and that is exactly why it slipped — a row that never changes looks maintained when it is merely unchanged, which is the failure mode the two script rows avoid by carrying their re-derivation note.

## Gaps

**This repository does not self-host its own ID and traceability gates**
(`docs/plans/2026-08-22-ratchet-gap-analysis.md`). It carries no
`.guardrails/config.yaml`, so the two script rows above were produced against a
config synthesized for this run. **Every figure in them moves with that
config**, and an earlier draft of this record gave the numbers without it, which
made them unreproducible — the review measured 67 findings using the recipe in
`2026-08-22-ratchet-gap-analysis.md` (all six prefixes, `safety_class: A`)
against the 52 recorded here. Neither is wrong; they are different questions.
The config used, in full, so the rows can be re-derived:

```yaml
guardrails_version: 0.5.1
safety_class: B
id_prefixes: PR
doc_problems: docs/problems
doc_verification: docs/verification
strict_paths:
  - scripts
test_paths:
  - tests
verify_commands:
  - sh tests/run-tests.sh
problem_age_days: 90
problem_open_max: 60
```

It declares `PR` alone because the problem ledger is the only ledger this change
touches; a config declaring all six prefixes reports far more, all of it about
documents this change never edited. Run as
`GR_CONFIG=<path to the above> sh scripts/check-ids.sh`. Both scripts exit 1 on
the guardrails tree by construction — its test fixtures, plans and script comments are full of
illustrative draft tokens and definition forms. `check-ids.sh` was proved
unchanged against the base commit — output identical but for a +8 line shift,
independently re-confirmed by the round-3 reviewer; `check-trace.sh` gained 8
`DANGLING-REF`s, every one a fixture ID inside a `printf` string in
`tests/check-trace.bats`, of the same class as the pre-existing five. The real gate for this repository is
`tests/run-tests.sh` (`AGENTS.md`, non-negotiable 3), which is green at 677.

**The remote was not consulted, and from now on never is.** AGENTS.md
non-negotiable 5, added by this change, puts `origin` out of scope for this
repository: local `main` is the base branch and an agent neither fetches nor
pushes. This is no longer a gap in the evidence — it is the policy the evidence
was gathered under, and the note under The gate says so.

**`PR-h3wujj`, `PR-crcee5` and `PR-z6uaa8` are recorded, not fixed.** None is
addressed here and all three remain open in the ledger with their scope stated.
`PR-z6uaa8` is the newest and the most uncomfortable: the skills this change
edits are not the skills the agent executing it was running, and it was found
by the user asking where a fix gets reported, not by any gate.

**The supersession sweep is not implemented.** Only reciprocity is checked. A
superseded ID still referenced where its replacement is not will not be
reported.

**Twenty-four of the thirty-three review findings were defects in PROSE, not in
executable code** — findings 9, 10, 11, 13, 14, 15, 17, 18, 20, 21, 22, 23, 24,
25, 26, 27, 28, 29, 30, 31, 32, 33, the record half of 16, and the argument half
of 19, across all six rounds. "Prose" is the honest category and it is wider than this file: most sit
here or in the ledger, 16's half is a false termination proof in a code comment,
and 19's is an argument in `AGENTS.md`. What unites them is that no test could
have caught any of them — they are claims, and a claim is checked by
re-deriving it or not at all. Rounds 4, 5 and 6 found **no defect in executable code at all**. They share one
cause: a figure or a name asserted from memory instead of derived from the tree.
A test-count carried forward from a superseded run under a heading forbidding
exactly that; a breakdown summing to 41 in an item claiming 38 twice; three test
names written plausibly rather than copied; an output-LINE count labelled as a
finding count, under a config the record never named; and a category breakdown
carried forward into a sentence describing a different set.

None of them was caught by a gate, because no gate reads this file's prose —
`check-review.sh` checks that four fields and a disposition per finding are
PRESENT, never whether any figure in them is true. They were caught by a
reviewer re-deriving each number, which is the only thing that catches them.
The code fixes in this change survived adversarial review; the bookkeeping about
those fixes did not, and it took six rounds to stop being wrong — if it has.

Two things follow for anyone reading this record as a model. Every figure here
is now the quoted output of a named command, and the config that produces the
script rows is in this document rather than in the author's shell. And the
honest reading of thirty-three findings is not "the review worked" alone — it is that
a verification record is exactly as trustworthy as the last person to re-run its
numbers, and that person should not be its author.

**The ledger file is named for the day `finalize-docs.sh` last ran, and that
has now been wrong twice.** `merge-change` step 3 names a ledger file for the
merge date, but finalization runs before review, and review can take days: this
change was finalized 2026-09-10, renamed to 2026-09-11 when round 4 caught the
gap, and renamed again to **2026-09-15** when round 5 caught it a second time,
four days wider. An earlier draft of this paragraph asserted "one day is its
whole size", which the file it described falsified.

No claim is made here about the squash date, because any such claim expires the
moment signing waits. What can be said is the mechanism: **a file named for an
event that has not happened yet is correct only if the event happens that day**,
and a change that takes five review rounds will not. The rename costs one
`git mv` plus the references in this record — round 4 established that when it
disproved the opposite claim — so it is cheap to repeat and has been repeated.

That is a property of step 3's convention rather than of this change, and it is
not this change's to fix; it is left stated rather than filed, because the two
items this change already absorbed from its own margins (`PR-crcee5`,
`PR-z6uaa8`) are what a change looks like when it adopts every problem it trips
over. A project merging same-day never sees it.

**Per-task targeted test runs are a filter, not a gate.** Two reuse pins in
`tests/check-ids.bats` constrain `scripts/check-trace.sh` and are invisible to
`check-trace.bats`, `portability.bats` and `skills.bats` — the three files each
task was told to run. They reddened only in the full suite, which is where
`verify-before-merge` puts the verdict. No task could have caught them.
