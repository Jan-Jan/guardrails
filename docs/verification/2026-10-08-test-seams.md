# Verification — test-seams (2026-10-08)

branch: test-seams
reviewer: independent Claude subagents with fresh context, given the diff, the plan, AGENTS.md, the review checklist and the items the change adds only (merge-change step 6a): round 1 at `423debc`, round 2 at `1b87ed6` (a first round 2 reviewer died on an authentication error before reporting and was replaced), round 3 at `2b43cc8`
verdict: converged at round 3 — every finding low or record; each was mechanical and is fixed, so no further reviewer was dispatched
reproduced: no problem item is resolved; the change implements decisions D1 to D15 of its plan and opens PR-ttg99p, PR-dfndh4 and PR-qf5tkd. Every new test was watched red before its text or code existed, and every review round's surviving mutants were re-run red after the fix (red → green below)

Change: `develop-change` states where a test attaches and which test doubles it may use, `merge-change`'s review checklist checks it, and this repository's two platform stubs share their assertions with contract tests against the real tools. Branched from `main` at `2d0bbba`; base merged from local `main` at `646fa1f`, per AGENTS.md non-negotiable 4.
Plan: `docs/plans/2026-10-07-test-seams.md`.

## The gate

Measured on: `3893bb3` — `git rev-parse HEAD` — tree `a3fe1be9c4ca3127d59bbb1a98534e99831e2546`, clean worktree, `main` at `646fa1f`. Step 3 renamed nothing in the final round (its one rename, the draft problems file, was committed before the first gate), so this is the tree that merges, apart from this record.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` (parallel) | 1..1119, 1119 ok, 0 not ok, 0 skipped, exit 0, 2026-10-08 11:48 to 12:02 |
| `check-ids.sh --allow-draft-files` (scratch copies, base and change) | exit 1 on both, as on `main`; sorted output identical |
| `check-trace.sh` (scratch copies, base and change) | exit 1 on both, as on `main`; the sorted outputs differ only by this change's own items: PR-ttg99p, PR-dfndh4 and PR-qf5tkd enter the roll-call open, and ADR-8ft3hb and ADR-4xh6cf are added |
| `check-review.sh --branch test-seams` (scratch copy of the change with this record) | exit 0; this record found, every finding dispositioned |
| Coverage | not configured |
| Working tree | clean |

The repository has no `.guardrails/config.yaml`, so `check-ids.sh` and `check-trace.sh` ran on scratch copies built from `main` and from the change with `templates/config.yaml` (its `strict_paths` entry set to `scripts`, and one-line placeholder `doc_srs`/`doc_sad` files so the trace gate runs), and `merge-preflight.sh` was not run, as in `docs/verification/2026-10-07-parallel-changes.md`. The change's item IDs were minted with `new-id.sh` under a scratch `GR_CONFIG` declaring `PR` and `ADR`, for the same reason.

An earlier full run, on tree `a1e56eb` with the host at load 17 to 21 on 12 cores from other sessions, took 04:01 to 05:59 and failed `new-id: the give-up message distinguishes no randomness from no free token` and `new-id: a FIFO is rejected rather than read` on their wall-clock `timeout` bounds. This change touches neither `tests/new-id.bats` nor `scripts/new-id.sh`; the file alone then passed 28 of 28 three times under load, and the cause is recorded as PR-qf5tkd. No figure in the table comes from that run.

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| D1, D2, D3 | `develop-change: a test attaches only to an interface a REQ or LLR describes` | failed at its first grep on the unedited SKILL.md (T1); after finding-1 and finding-13/-17, failed on the journey sentence made "always a REQ", on "only" dropped from the D3 criteria sentence, and on each of the round 3 gap mutants G2, G4, G6, G7, G13 |
| D4, D8, D9, D14 | `develop-change: doubles fake only at the codebase boundary, each with a contract test` | failed at its first grep (T1); after finding-2, -4, -8 and -16, failed on "Never assert an", on point 4 deleted, on "with no contract test", on "Fake wherever convenient", on the D9 condition deleted, and on G5, G8, G9 |
| D5, D6 | `develop-change: property tests repeat and pin, and a survivor never goes below the seam` | failed at its first grep (T1); after finding-2, -8 and -20, failed on "Prefer a property test" replaced, on the dead-code branch deleted, on "after the fix", and on "unless one of the three criteria" deleted |
| D7 | `develop-change: a UI's interface is what the user perceives, and a markup snapshot verifies nothing` | failed at its first grep (T1); after finding-2, -8, -9 and -14, failed on each ui-seams.md section deleted, on "or may be faked" appended, on the HTTP-layer contract clause deleted, and on G1, G11 |
| D10 | `develop-change: the seam rules bind new and edited tests, not the existing suite` | failed at its first grep (T1); after finding-2, -8 and -15, failed on "is left alone" for "moves to the seam", on "repairs it in place", and on G3, G10 |
| D12, D14 | `merge-change: the review checklist asks where each new test attaches and which doubles it uses` | failed at its first grep on the unedited checklist (T2); after finding-3, -8 and -18, failed on "one of three kinds" removed, on the owned-service clause replaced, on the two deleted qualifiers, and on G12 |
| D11 | the four `strict awk contract:` and `bsd date contract:` tests in `tests/portability.bats` | with the detector renamed: `not ok`, `failed with status 127`; with `real_bsd_date_dir` forced to status 1 on macOS: `not ok`, `found no BSD date on macOS, where it ships`; against a permissive awk and date: `expected exit 2, got 0` and `-d was accepted` (T3, re-dispatched) |

D13 is the two ADR files and carries no test. D15 is how the text tests' strength is judged: the plan's "## Pinned clauses (D15)" lists 96 pins, every one of which turned its test red under a per-pin mutation in fix round 3, and which matches the greps the tests run, 96 to 96.

## What was wrong, and what was built

`develop-change` said where a test sits only for class C ("every SDD item the change touches gets tests at its own interface") and said nothing about test doubles. An adopter's suite could pin every private function, mock the code it owns, and pass every gate, and such a suite holds an implementation in place: a refactor that keeps every behavior breaks every test pinned to a function it moved. The robustness rule asked for dependency-failure tests without saying how to build the double that produces the failure.

`develop-change` now has a "Where a test attaches" section. A test calls only an interface a REQ or LLR describes. A deeper interface gets a direct test only once it earns an LLR, by being unreachable, combinatorial or intrinsically complex. Code the project owns is never mocked. Fakes sit at the codebase boundary, each with a contract test. A service the project owns runs for real on the normal path, and its failures may be faked. A double that imitates content the code interprets is a fake, and a transport- or OS-level failure is a fault injector. Property tests are preferred for combinatorial and intrinsic cases, with a repeatable seed and pinned counterexamples. A surviving mutant calls for a test at the seam, or for deleting dead code. A markup snapshot verifies nothing. The rules bind the tests a change writes or edits. `references/test-seams.md` and `references/ui-seams.md` carry the reasons and the application to a UI, ADR-8ft3hb and ADR-4xh6cf record the two decisions that are hard to reverse, and the step 6a review checklist has a test section.

This repository had to follow the rule it ships. Its `make_strict_awk` and `make_bsd_date` stubs were checked only against their own specification. They now share each assertion with a contract test that runs against the real BWK awk and BSD `date`, skips where a tool is absent, and fails on a broken detector or on a macOS host missing either tool. Classifying the repository's other doubles under D14 found fakes of `parallel`, `getconf` and `sysctl` with no contract test (PR-dfndh4).

## Review

### Round 1

Reviewed at `423debc`. Reviewer's suite: 1..1119, 1119 ok, 0 not ok, 0 skipped. Verdict: D1–D13 delivered and the contract tests sound; a fix round is needed for a test that claims D2 but checks none of it and a test checklist that contradicts D8/D9.

**finding-1**: code, medium — `tests/skills.bats:627-638` (`develop-change: a test attaches only to an interface a REQ or LLR describes`) says `verifies: D1, D2, D3`, but none of its seven greps touches the journey rule. Changing `SKILL.md:79` to "A user journey is always a REQ, and it…" gave 0 `not ok`; deleting the whole `## User journeys` section of `references/test-seams.md` gave 0 `not ok`. Plan self-review item 1 says "D2's journey rule … tested through the text that states them", which is false.
disposition: the test greps the journey sentence in SKILL.md and in `references/test-seams.md`, and was red on both mutations (`d79892d`).

**finding-2**: code, low — The other grep tests check only their headline sentences, so several parts of the decisions they cite can be inverted with the suite still green: D4 point 4, D3's criteria sentence ("whenever convenient"), D5 point 1 ("Never write a property test"), D6's dead-code branch, D7 points 2–4 in `ui-seams.md` (the thin-UI section, "not by test identifier or class name", the visual-regression line, the owned-service line), and D10's "moves to the seam". The annotations `verifies: D4…`, `D5, D6` and `D7` therefore claim more than the tests check.
disposition: each named clause is grepped by the test whose `verifies:` names its decision; each of the fourteen mutations turned exactly that test red (`d79892d`).

**finding-3**: requirement, medium — `skills/merge-change/references/review-checklist.md:53-55`: "Every test double is a fake at the codebase boundary with a contract test, or a fault injector." D8 lets a failure test fake a service the project owns, and D9 lets it fake the successes before the failure, so a reviewer applying the checklist literally raises a finding against a test those rules allow. The conflict sits between D12 and D8/D9.
disposition: the bullet names three kinds of double: a boundary fake with a contract test, a fake of an owned service in a failure case only under its contract test, and a fault injector as D14 defines it; the D12 test pins it and was red with the owned-service clause replaced (`b6a968e`).

**finding-4**: requirement, low — The fault-injector category is derived work with no decision behind it: `test-seams.md:72-73` allows a fault injector "at any boundary" without saying whether it needs a contract test, and an adopter cannot tell whether a fake that returns timeouts from an owned service is a fault injector or a fake.
disposition: ruled by the maintainer as D14 (2026-10-08): a double that imitates service-specific content the code interprets is a fake and has a contract test; a transport- or OS-level failure imitating nothing service-specific is a fault injector and needs none. `references/test-seams.md` states it with examples, the D4/D8/D9/D14 test pins it, and the plan's T3 note classifies this repository's six doubles under it (`b6a968e`); the fakes it found are PR-dfndh4.

**finding-5**: code, low — `tests/portability.bats:41` (`-v k=plain 'BEGIN { print k }'`) and `:35` (`n = split(kws, K)`) keep single-character names in lines this change moved into new functions, against AGENTS.md "Code: names".
disposition: renamed `assigned`, `count` and `keywords`, asserted output unchanged; `tests/portability.bats` passes 17 of 17 (`d79892d`).

**finding-6**: record — Plan T1 steps 3 and 4 say "exactly this content", but the deslop commit `43f9217` rewrote the journey sentence in SKILL.md and the property-test sentence in `test-seams.md`, and the plan says "1989 as built" where the file has 1990 words.
disposition: a dated note under T1's Done block quotes both rewordings and records 1990 words; the step text is unchanged (`d79892d`).

**finding-7**: record — The Cost section of ADR-4xh6cf says "`testing-strategy`, the change after this one, asks each project how it provides them." No decision gives `testing-strategy` that scope.
disposition: the sentence reads "How a project provides them is its own test-environment decision." (`d79892d`).

### Round 2

Reviewed at `1b87ed6`. Reviewer's suite: 1..1119, 1119 ok, 0 not ok, 0 skipped. Verdict: D1–D14 delivered and consistent in substance; one medium finding, the decision tests miss most of the operative clauses they claim to cover.

**finding-8**: code, medium — The skills.bats tests do not verify what their `verifies:` annotations claim. Of 16 single-clause mutants, 15 survived: among them SKILL.md "Fake only at the codebase boundary" → "Fake wherever convenient", deleting "behind an adapter the project owns", deleting D9's condition that each faked success is verified against the real service, "under the same contract test as any fake" → "with no contract test needed", "example test before the fix" → "after the fix", "moves it to the seam instead of repairing it in place" → "repairs it in place", deleting ui-seams.md's "What only a real browser shows" and "Enumerate the states", and deleting the checklist's "unless the interaction is the requirement". Each test greps a headline or a neighbouring line, not the clause that states the rule.
disposition: ruled by the maintainer as D15 (2026-10-08), after review returned test-strength findings twice: the text tests pin each decision's operative clauses, listed in the plan's "## Pinned clauses (D15)", and wording beyond that list is the review's to judge. The listed clauses are grepped, and the reviewer's 16 mutants, rebuilt from this finding, plus three for finding-9's text, were each killed by the test that owns them (`4ffdc2a`).

**finding-9**: requirement, low — `ui-seams.md:27` "Fake only what is outside the codebase, at the HTTP layer, plus the clock." conflicts with `test-seams.md` D4 point 2, where the fake implements the adapter's interface; an HTTP-layer fake sits below the adapter. The ui-seams line also leaves out randomness and the contract test.
disposition: both files say a fake at the HTTP layer of a service outside the codebase is a boundary fake under the same contract test, with the adapter above it running for real, and that the clock and randomness are fakeable; both lines are pinned (`4ffdc2a`).

**finding-10**: requirement, low — D12 says "Two reviewer questions join the existing 'would they fail if the behavior broke?'", but the change adds a "## The test checklist" section to `review-checklist.md` instead, and step 6a's question list is unchanged. Step 6a hands the reviewer the checklist, so the behavior is delivered, but D12's text does not describe what was built.
disposition: D12 amended, dated, to describe the checklist section that step 6a hands every reviewer (`4ffdc2a`).

**finding-11**: record — The plan header says "Delivers D1 to D13 below; records PR-ttg99p (open)", but the plan has D14 and the change also records PR-dfndh4; self-review item 1 does not mention D14 or its tests.
disposition: the header names D1 to D15 and PR-ttg99p, PR-dfndh4 and PR-qf5tkd; self-review item 1 names D14's and D15's tests (`4ffdc2a`).

**finding-12**: record — `docs/problems/2026-10-08-mutation-anchor-step.md` is named for PR-ttg99p only but defines items that are not about mutation anchors.
disposition: renamed `docs/problems/2026-10-08-test-seams-gaps.md`, a file not yet on `main`, so no definition moves on the base; nothing referenced the old name (`4ffdc2a`).

### Round 3

Reviewed at `2b43cc8`. Reviewer's suite: 1..1119, 1119 ok, 0 not ok, 0 skipped. Verdict: D1–D15 delivered; all 77 listed pins hold under mutation; the pin list misses several operative clauses and a few text points are inconsistent; every finding is low, so this is the last review round.

**finding-13**: requirement, low — The pinned list leaves out the content of D3 criteria 2 and 3: only their headlines are pinned. G7 ("3. **Intrinsic.** Any helper the author finds hard to reach"), G6 ("has more than one case") and G2 (SKILL.md "or when it is hard to reach from above") survived.
disposition: the criteria's content lines and SKILL.md's maths line are pinned whole-line and listed; G2, G6 and G7 each turned the D1/D2/D3 test red (`fe4b0c8`).

**finding-14**: requirement, low — D7 point 1, the SKILL.md UI line, is not pinned: G1 ("…is the component tree and its props") and G11 (ui-seams.md "application renders.") survived.
disposition: both lines are pinned whole-line and listed; G1 and G11 turned the D7 test red (`fe4b0c8`).

**finding-15**: requirement, low — D10's clause that a violating test that still passes is left alone is not pinned in either file: G3 ("deleted.") and G10 ("still passes is deleted") survived.
disposition: the clause is pinned with its verb in both files and listed; G3 and G10 turned the D10 test red (`fe4b0c8`).

**finding-16**: requirement, low — Parts of D4 points 2 and 3 are not on the list: G8 ("the third-party interface directly where convenient"), G5 ("dependency once, at adoption.") and G9 ("fake alone") survived.
disposition: the three lines are pinned whole-line and listed; G5, G8 and G9 turned the doubles test red (`fe4b0c8`).

**finding-17**: requirement, low — D1's operative clauses beyond its headline are not pinned: G4 ("helper also gets a direct test of its own") and G13 ("Without LLRs, any function is") survived.
disposition: both lines are pinned whole-line and listed; G4 and G13 turned the D1/D2/D3 test red (`fe4b0c8`).

**finding-18**: requirement, low — The condition that a fake of an owned service sits "under its contract test" is not pinned in the checklist: G12 ("with or without a contract test") survived.
disposition: the line is pinned whole-line and listed; G12 turned the checklist test red (`fe4b0c8`).

**finding-19**: requirement, low — The checklist defines a fault injector more narrowly than D14 and `test-seams.md`: it says "makes a transport or OS operation fail", while D14 also counts "an exit status with no output the code reads", so an adopter's reviewer could classify a failing-subprocess stub as a fake that needs a contract test.
disposition: the bullet reads "makes a transport or OS operation fail, or a command exit with no output the code reads, and imitates nothing service-specific"; pinned (`fe4b0c8`).

**finding-20**: requirement, low — `SKILL.md:95-96` drops D5 point 1's scope: it prefers a property test only "where cases are combinatorial", while D5 and `test-seams.md` name criteria 2 and 3.
disposition: SKILL.md reads "Prefer a property test where cases are combinatorial or the code is maths, parsing or encoding"; pinned; SKILL.md is 1998 words (`fe4b0c8`).

**finding-21**: requirement, low — The opening of `ui-seams.md` says the file "adds one rule of its own, on markup snapshots", but the snapshot rule is already in SKILL.md and the file adds the visual-regression limit too.
disposition: the opening says the file applies the seam rules to a UI and adds rules of its own on markup snapshots and visual regression (`fe4b0c8`).

**finding-22**: requirement, low — `ui-seams.md:55-56`, "An automated accessibility check is a cheap assertion worth running on every screen.", is rule text with no decision behind it.
disposition: the line is deleted; the list ends on the visual-regression bullet (`fe4b0c8`).

**finding-23**: record — D12 attributes "whether an owned service runs for real on the normal path" to D9, where the rule is D7 point 4 and D8; D11 says the fault injectors "fall under D8", where D14 classifies them.
disposition: both decisions carry a dated inline amendment naming the right decision (`fe4b0c8`).

## Gaps

- The text tests pin the clauses listed in the plan's "## Pinned clauses (D15)", by the maintainer's ruling: wording beyond that list is the review's to judge. A rewording of an unlisted clause passes the suite. The pins match single lines, so rewrapping a pinned paragraph fails the tests even where the wording is unchanged.
- No script checks the rules in adopter projects. The step 6a review checks them through the test checklist (D12), and a scan for mocks and seam violations is change 3 (`check-test-doubles`).
- The round 2 fix rebuilt the reviewer's mutants from the finding's descriptions; the reviewer had not saved them, and the one it reported killed (M16) was guessed. Round 3's reviewer saved its harness, and its mutants were re-run as saved.
- The contract tests' skip branch, for a host without BWK awk or BSD `date`, was exercised only by the round 1 reviewer forcing `uname` to report a non-Darwin host. It has not run on a Linux machine.
- Open: PR-ttg99p (`develop-change` step 6 greps a directory only this repository has), PR-dfndh4 (`tests/run-tests.bats` fakes without contract tests), PR-qf5tkd (`tests/new-id.bats` wall-clock bounds fail a slow but correct run on a loaded host).
- Ruled on 2026-10-08 and not built here: change 2 moves D1 to D10 out of `develop-change` into a shipped default `templates/TEST_GUIDELINES.md` that each project copies to `docs/TEST_GUIDELINES.md` and tailors through a `/ratchet` interview. `develop-change` reads the file at RED and the step 6a reviewer is handed it, and the compliance floor (`verifies:`, red → green, the B/C robustness rule, the class C interface rule) stays in the skills.
