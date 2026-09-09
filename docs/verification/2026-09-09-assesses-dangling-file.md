# Verification — assesses and DANGLING-FILE (2026-09-09)

One record per change, written at `merge-change` step 6b. The squash commit
references it on its `Verified:` line, so this file is the evidence that
travels with the change.

branch: assesses-dangling-file
reviewer: four independent subagents, one per round (DO-178C independence: none was the author; each received the diff, the plan with its dispatch bookkeeping expressly excluded, the problem reports and the repository, and no chat history). Rounds 1-3 reviewed the whole change; round 4's scope was narrowed to the round-3 fixes. Each ran the bats suite itself in its own nested review worktree and probed on throwaway fixtures; rounds 1-3 also sabotaged the mechanisms they were checking. Class A makes this step optional (docs/adr/2026-08-22-safety-class.md); it was run anyway, four times, and found 23 findings
verdict: approve-with-findings, converging across four rounds — 1 IMPORTANT + 7 MINOR, then 2 IMPORTANT + 5 MINOR, then 6 MINOR all non-blocking, then 2 MINOR both non-blocking. All 23 findings are dispositioned below: 21 fixed, 2 accepted without change (finding 7's fenced-text reading, finding 18's token class, both recorded under Gaps). No finding was reworded by the author, and none was closed by deleting it. The final tree carries the round-4 fixes, which no reviewer saw — stated at the end of the Review section
reproduced: yes, both defects, as failing bats tests watched red against the unchanged scripts before either fix existed. PR-n274s7: a derived REQ named only in a scope note, and a derived LLR named only in a verification-table row, both exited 0 on the old `UNANALYZED-DERIVED`, as did an assessment of one item whose parenthetical named a second. PR-58zsvf: a path reference and a bare-basename reference to a renamed draft both survived the old `finalize-docs.sh` untouched, and a dangling draft reference in a ledger passed the old `check-trace.sh` with only the summary lines printed. The downstream measurements that prompted the change (26 derived items, one credited on a parenthetical; 13 dangling links growing to 25 in eighteen days) are the report's, not re-measured here.

Change: `UNANALYZED-DERIVED` reads an `assesses:` declaration instead of
grepping for a mention; `finalize-docs.sh` rewrites references to the ledger
files it renames and prints each; `check-trace.sh` gains `DANGLING-FILE`,
which resolves a draft reference over the rewrite's scope and bans nothing.
Branched from `main` at `e2eac86`.
Plan: `docs/plans/2026-09-08-assesses-and-dangling-file.md`.
Resolves: PR-n274s7, PR-58zsvf
(docs/problems/2026-09-08-assesses-and-dangling-file.md).

## Scope

Two items brought upstream from a downstream guardrails project's report of
2026-09-08, assessed against the toolkit's own rules in a requirements
interview before anything was written. The interview departed from the report
in three places, all recorded as D1–D5 in the plan: a hard cut rather than a
transition for the stricter derived gate; both halves of the rename fix, the
rewrite and the gate, because a reference held in another worktree or another
unit's ledger is unreachable by any rewrite; and the gate's scope fixed to the
rewrite's scope rather than `strict_paths`, so that plans and verification
records that narrate a rename stay true. Two constraints the report did not
have: an ambiguous bare basename is left for the gate, and `assesses:` is
line-wise like `mitigates:` and joins no orphan list.

No REQ/SDD/HAZ/RC items are minted — the repository is not self-hosted
(docs/plans/2026-08-22-ratchet-gap-analysis.md) — so the binding contract is
the two problem reports and the plan's five decisions, each verified by named
bats tests (the Implements map below).

## Base

Merged **from the remote** at the first two step-1 passes: `git fetch origin`
succeeded on 2026-09-08 before the first gate and again after review round 1,
and `origin/main` = `main` = `e2eac86` both times; `git merge origin/main`
reported already up to date. At the third pass, after review round 2, the
fetch was refused by the hardware-key agent (`sign_and_send_pubkey: signing
failed … agent refused operation`), so that pass, and the fourth after review
round 3 on 2026-09-09, merged **from the local ref** `origin/main` =
`e2eac86`, last confirmed against the remote on 2026-09-08. The base has not
moved since the branch was cut, so the duplicate scan the gate would run has
seen every ID the base defines.

## The gate

Every figure derived from the tree under test, not carried forward.
`sh tests/run-tests.sh` is the repository's `verify_commands` (AGENTS.md
rule 3); TAP counts, never exit codes.

| Gate | Result |
| --- | --- |
| baseline, before any task, at `e2eac86` | 602 declared / 602 ok / 0 not ok, exit 0 (scratchpad baseline.log) |
| after all five tasks merged, at `5260119`, author's own run | 624 / 624 / 0, exit 0 (full-run-1.log) |
| pre-finalize gate (verify-before-merge), dispatched, at `5260119` | 624 / 624 / 0, exit 0; Implements map complete; `git status` clean; `.worktrees/` empty (assesses-dangling-file-gate.log) |
| post-finalize gate (step 6), dispatched, at `0915776` | 624 / 624 / 0, exit 0; Implements map complete (7 tests carry PR-n274s7, 15 carry PR-58zsvf); no `DRAFT-*` file in the tree; both PR IDs defined once at column one with `status: resolved`; `git status` clean (assesses-dangling-file-gate2.log) |
| round-1 review's own run, in its nested review worktree at `0915776` | 624 / 624 / 0, exit 0, BWK awk 20200816 |
| after the round-1 fixes (T6), steps 2 and 6 as one run since no draft remained, dispatched, at `d2d1687` | 628 / 628 / 0, exit 0; Implements map complete (7 tests carry PR-n274s7, 20 carry PR-58zsvf, all via `# verifies:`); no `DRAFT-*` file; both PR IDs defined once, `status: resolved`; `git status` clean before and after (assesses-dangling-file-gate3.log) |
| round-2 review's own run at `d2d1687` | 628 / 628 / 0, exit 0, BWK awk |
| after the round-2 fixes (T7), steps 2 and 6 as one run, dispatched, at `808684d` | 633 / 633 / 0, exit 0; Implements map complete (7 tests carry PR-n274s7, 24 carry PR-58zsvf); no `DRAFT-*` file; both PR IDs defined once, `status: resolved`; `git status` clean before and after (assesses-dangling-file-gate4.log) |
| round-3 review's own run at `808684d` | 633 / 633 / 0, exit 0, BWK awk |
| after the round-3 fixes (T8), steps 2 and 6 as one run, dispatched, at `5e8b93c` | 634 / 634 / 0, exit 0; Implements map complete (7 tests carry PR-n274s7, 25 carry PR-58zsvf); no `DRAFT-*` file; both PR IDs defined once, `status: resolved`; `git status` clean before and after (assesses-dangling-file-gate5.log) |
| round-4 review's own run at `5e8b93c` | 634 / 634 / 0, exit 0 |
| **definitive gate**, after the round-4 fixes (T9), at `328f966` 634 / 634 / 0 not ok, 0 skipped, exit 0; Implements map complete (7 tests carry PR-n274s7, 25 carry PR-58zsvf, none without one); no `DRAFT-*` file tracked or untracked; both PR IDs defined once at column one and `status: resolved`; `git status` clean; nothing registered under the change worktree's `.worktrees/` (assesses-dangling-file-gate6.log). Only this record's own commit follows |
| `check-ids.sh` | does not run against this repository (not self-hosted), consistent with every prior record. Performed by hand: the two PR IDs are defined exactly once each at column one and every other occurrence is a reference; no `DRAFT-` named file remains after the rename; no draft ID token exists |
| `check-trace.sh` | does not run against this repository. Performed by hand: both items carry `status: resolved` at column one; no reference to the draft basename remains outside docs/plans, and the one inside the plan is the narration D3 protects |
| `finalize-docs.sh` | does not run here; the rename `DRAFT-assesses-dangling-file-assesses-and-dangling-file.md -> 2026-09-08-assesses-and-dangling-file.md` was performed by hand at step 3 (`git mv`, commit `0915776`), with the plan's pointer to it updated |
| Coverage, against the class target | no `coverage_command`; the toolkit itself is unclassified (docs/adr/2026-08-22-safety-class.md: class A) |
| Working tree | clean at both gates |

## Red → green

One row per problem report this change resolves, copied from the `red ->
green:` lines of the dispatch reports parked beside each task in the plan.
The task subagent that ran the loop is the only party that saw the test fail.

| Item | Test | Watched red |
| --- | --- | --- |
| `PR-n274s7` | `check-trace: a derived REQ named only in passing in the RMF is unassessed` | yes — old gate exited 0 with only the `checked:` line; the scope-note mention was credited |
| `PR-n274s7` | `check-trace: a derived LLR named only in a verification-table row is unassessed` | yes — old gate exited 0; the table row was credited |
| `PR-n274s7` | `check-trace: an assesses: run for one item does not clear a second it mentions` | yes — old gate exited 0; the parenthetical LLR-002 was credited |
| `PR-n274s7` | `check-trace: an assesses: line accepts a derived REQ and a derived LLR` | boundary pin, green on the old script as the plan predicted; it exists so a later tightening cannot pass by rejecting everything |
| `PR-n274s7` | `check-trace: an assesses: line outside the RMF files counts for nothing` | boundary pin, green on the old script — the plan predicted red and was wrong: the old grep was already scoped to `$rmf_files`. Kept because it pins the new reader's scope |
| `PR-n274s7` | `assesses-is-the-remedy`, `upgrade-notes-announce-the-hard-cut` (tests/skills.bats) | yes — each watched fail on the first absent string before the documentation edits existed |
| `PR-58zsvf` | `finalize: a path reference to a renamed draft is rewritten in another ledger` | yes — grep for the dated name in docs/risk/README.md failed; nothing rewritten |
| `PR-58zsvf` | `finalize: a bare basename reference is rewritten` | yes — soup.md still held the DRAFT name |
| `PR-58zsvf` | `finalize: a draft referencing its sibling draft is rewritten after both are renamed` | yes — the renamed file still referenced docs/risk/DRAFT-… |
| `PR-58zsvf` | `finalize: --dry-run prints the rewrites it would make and writes nothing` | yes — output held only the rename line |
| `PR-58zsvf` | `finalize: an ambiguous bare basename is left for the gate, the path form still rewrites` | yes — path form not rewritten to the `-2` name |
| `PR-58zsvf` | `finalize: a rewrite that fails aborts instead of reporting a clean finalize` | yes — exit 0, no rewrite pass existed to abort (the plan had predicted this one green and was wrong in the safe direction) |
| `PR-58zsvf` | `finalize: a reference to another change's draft is left alone`, `finalize: a plan narrating the rename is left exactly as written`, `finalize: the no-drafts case is still a silent no-op after the rewrite pass` | boundary pins, green on the old script as predicted |
| `PR-58zsvf` | `check-trace: a ledger reference to a draft file that does not exist is DANGLING-FILE` | yes — exit 0 with only the summary lines; nothing convicted docs/risk/DRAFT-other-alarms.md |
| `PR-58zsvf` | `check-trace: a reference to a draft file that exists is the in-flight state and passes`, `…a bare draft basename resolves against every ledger directory`, `…a dangling draft reference outside the ledgers is prose`, `…the grammar placeholder DRAFT-<branch>-<slug>.md is not a reference` | boundary pins, green on the old script as predicted (no gate existed to fire), green after |
| `PR-58zsvf` | `merge-step-3-reports-rewrites` (tests/skills.bats) | yes — `rewrote` absent from skills/merge-change/SKILL.md before the edit; its `reported as left` assertion (review finding 8) watched fail before the README edit |
| `PR-58zsvf` | `finalize: a path to another file that shares the draft's basename is not rewritten` (review finding 1) | yes — the `Foreign:` path was rewritten by the bare pass before the fix |
| `PR-58zsvf` | `finalize: --dry-run previews exactly the rewrites the real run makes` (finding 2) | yes — two `would rewrite` lines for one file before the fix |
| `PR-58zsvf` | `finalize: an ambiguous basename is reported left once per file, and only where a bare form stands` (finding 3) | yes — two identical `left` lines before the fix |
| `PR-58zsvf` | `check-trace: a relative link to a draft that exists resolves from the referencing file` (finding 4) | yes — `DANGLING-FILE ../risk/DRAFT-feature-a.md` before the fix |
| `PR-58zsvf` | `finalize: two sibling drafts sharing a basename preview and rewrite the same lines once` (finding 10) | yes — two `would rewrite` lines for soup.md before the fix |
| `PR-58zsvf` | `finalize: a glob-shaped ledger name is scanned as itself, not as what it matches` (finding 13) | yes — the rewrite absent from `docs/risk/[x].md` before `set -f` |
| `PR-58zsvf` | `finalize: a token glued to a longer word is not the file's name` (finding 14) | yes — the glued tokens were rewritten before the word-boundary rule |
| `PR-58zsvf` | `merge-step-3-reports-rewrites`, `root-relative` / `relative link` assertions (finding 9) | yes — `root-relative` absent from README.md before the edits |
| `PR-58zsvf` | `finalize: a reference scan that fails aborts instead of reporting a clean finalize` (finding 11) | green on arrival — the round-1 guard already existed; the test pins it, which is what the finding asked for. Round-2 review had shown the mutant (guard removed) passes every other test, so this one is the kill |
| `PR-58zsvf` | dry-run assertions added to `an ambiguous basename is reported left once per file…` (finding 12); `check-trace: a glued prefix is not a path, so the bare name resolves` (finding 14) | boundary pins, green on arrival as predicted — each catches the mutant round 2 named |
| `PR-58zsvf` | `check-trace: a bare draft name found in no ledger directory says where it looked` (finding 19) | yes — exit 1 with the old `does not exist` message before the message split |
| `PR-58zsvf` | dry-run assertion added to `finalize: a glob-shaped ledger name is scanned as itself…` (finding 16) | green on arrival as predicted; the dispatch neutralised the first `set -f` and watched this assertion fail while the real-run assertion stayed green, then restored the script — it kills the mutant round 3 named |
| `PR-58zsvf` | `check-trace: a ledger reference to a draft file that does not exist is DANGLING-FILE`, assertion strengthened to pin the path arm's wording (findings 22, 23) | yes — the run printed the old `does not exist` wording, so the required substring was absent, before the `_why` change existed |

Five existing fixtures that assessed a derived item by bare mention were
changed to carry `assesses:`; two of them are the longer-ID boundary tests,
which now test that boundary against the new reader.

## What was wrong, and what was built

**PR-n274s7.** The `UNANALYZED-DERIVED` gate was one free-text `git grep`
per derived ID over `$rmf_files`. The normative text said "assessed" in six
places and the implementation enforced "mentioned"; the weakness was stated
as a caveat in the script, the README and the check-traceability skill, and
measured as review finding 17 of docs/verification/2026-08-19-item-placement.md,
but no problem report existed. A downstream project arming the stricter rule
found one of 26 derived items credited on a parenthetical inside a blockquote.
Built: `assesses:` is read by `ids_matching` through `GR_AWK_ID_RUN`, so the
run ends at the first non-ID character and an assessment of one item cannot
clear a second it names. Hard cut (D1): the ratchet upgrade notes announce
that every derived item goes red at the first run until its assessment
carries the annotation, and the check-traceability remedy row says what to
add. Templates, README, AGENTS block and four skills now say "an `assesses:`
line names it" where they said "mentioned" or "assessed".

**PR-58zsvf.** `finalize-docs.sh` held both names of every file it renamed
and discarded the mapping; nothing read a file reference. Built, in two
halves (D2): the script rewrites path-shaped references for every rename and
bare basenames for the unambiguous ones (D4), literally via `index`/`substr`
with the names passed through `ENVIRON` so awk cannot interpret them, over
the four ledger directories and the SOUP file only (D3), printing `rewrote
FILE: old -> new` for each and `would rewrite` under `--dry-run`, and
treating awk's exit 3 (no occurrence) and any other non-zero exit (failure)
as the different answers they are. `check-trace.sh` gains `DANGLING-FILE`:
a real-looking `DRAFT-*.md` token in those same files must name a file that
exists, resolved from the repository root when path-shaped and against every
ledger directory when bare; a draft that exists passes, because that is the
in-flight state of every unmerged change.

## Review

Round 1 (2026-09-08), one independent subagent: received the diff against
`e2eac86`, the plan with its dispatch bookkeeping expressly excluded, the
problem reports and the repository; no chat history. It ran the suite itself
in its own nested review worktree (`1..624`, 624 ok, 0 not ok, exit 0, under
BWK awk 20200816), ran nine sabotages (each mechanism broken, the named
tests watched red, restored) and live probes on throwaway fixtures, and
returned `approve-with-findings`: 1 IMPORTANT, 7 MINOR. Findings are copied
in the shape they arrived; each disposition names the test that reddens
without the fix. The fixes are plan task T6.

**finding-1**: IMPORTANT — the bare-basename pass is a plain substring replace and rewrites a path-shaped reference to a *different*, un-renamed file that happens to share the basename. Probe F8: draft `docs/requirements/DRAFT-feature-x.md`, foreign file `docs/other/DRAFT-feature-x.md` untouched, ledger line `Foreign: docs/other/DRAFT-feature-x.md.` became `docs/other/2026-09-08-x.md` — a dangling reference to a dated name, which the `DRAFT-` regex of DANGLING-FILE can no longer see, printed as an ordinary `rewrote` line. Cause: scripts/finalize-docs.sh `run_rewrites` rewrites the bare name wherever `git grep -F` finds it, with no check that the occurrence is not preceded by `/`. D4's premise ("a path-shaped reference rewrites exactly in every case") does not hold for a same-basename file outside this run's rename set — the realistic shape is one change branch touching two units, which produces identical `DRAFT-<branch>-<slug>.md` basenames in both. No test covers it.
disposition: fixed. The bare pass (`rewrite_file` with BARE=1) skips any occurrence preceded by `/`, so the tail of a path to another file is never this rename's to change. Reddens without it: `finalize: a path to another file that shares the draft's basename is not rewritten`.

**finding-2**: MINOR — `--dry-run` previews work the real run does not do. Because nothing is rewritten under dry-run, the bare pass still hits every file the path pass would have consumed. Probe F6 (file holding only `docs/requirements/DRAFT-feature-x.md`): dry-run printed both a path-form and a bare-form `would rewrite` line; the real run printed the first only. Probe F7 (ambiguous basename, file holding only the path form): dry-run printed two `left …` lines for a file whose only reference already *is* the path and which the real run rewrote cleanly. merge-change step 3 tells the operator to preview and read these lines.
disposition: fixed by the same rule as finding 1 — the bare pass skips `/`-preceded occurrences in both modes, so the preview and the real run see the same set, and `left` is decided by a probe for a bare form. Reddens without it: `finalize: --dry-run previews exactly the rewrites the real run makes`.

**finding-3**: MINOR — `left` is printed once per rename sharing the basename, not once per file: probe M3 (two renames, one file with both forms) printed the identical `left` line twice; M4 (three ledgers sharing a basename) printed it three times. The test matches a substring so the duplication passes.
disposition: fixed. `run_rewrites` iterates the unique ambiguous basenames and prints `left` once per file, and only for a file in which a bare form actually stands. Reddens without it: `finalize: an ambiguous basename is reported left once per file, and only where a bare form stands`.

**finding-4**: MINOR — DANGLING-FILE convicts a relative markdown link to a draft that exists. Probe G3: `../docs/risk/DRAFT-feature-a.md` with the draft present was reported, since the gate resolves any slash-bearing token from the repository root only, and the remedy text is wrong for this case. D3 does say "resolves from the repository root", so this is a stated boundary, but "resolve, never ban" is violated for the one link form a markdown renderer actually follows. Related: a glued token `xDRAFT-feature-a.md` is convicted because the prefix class absorbs letters; contrived, noted for completeness.
disposition: fixed. A path-shaped reference now resolves from the repository root and then from the referencing file's own directory; the scan pattern requires every path component to end in `/`, so a glued prefix yields the bare name, which resolves against the ledger directories. Reddens without it: `check-trace: a relative link to a draft that exists resolves from the referencing file`.

**finding-5**: MINOR — the justification for leaving pathname expansion on is now stale. The comment argues no input reaches the unquoted splits because every `renames` field is a whitespace-rejected draft name under one directory; the change added unquoted `$rewrite_scope` and the scan hits, which are arbitrary ledger filenames listed by `gr_doc_files` and never checked for glob characters. Harmless on any real ledger, but the comment says "no input reaches it" and that is no longer what the code does.
disposition: comment rewritten to state the new inputs and why each outcome of expansion over them loses nothing: the words are names of files that exist, so a pattern either matches nothing and stays literal, or matches a sibling ledger file that is then scanned too. No test — a comment.

**finding-6**: MINOR — `rewrite_refs` swallows `git grep` failure: it discards stderr and ignores the exit status, so a `git grep` exit 2 reads as "no occurrences" and the run exits 0 having rewritten nothing. check-trace.sh treats the same condition as fatal. The plan's "distinguish failure from no-occurrence" is honoured for awk but not for the scan that decides which files awk sees.
disposition: fixed. `scan_refs` dies on any `git grep` exit above 1, mirroring check-trace.sh's reference scan. No test: forcing `git grep` to fail on a scope of existing files needs a contrivance the suite does not have; the fix is three lines in the shape the sibling gate already uses.

**finding-7**: MINOR — both the gate and the rewrite read fenced code blocks and HTML comments as live text. Probes G1/F9: a `DRAFT-…md` inside a fence in a ledger is convicted and is rewritten; probe G2: `assesses: REQ-002` inside a fence, an HTML-commented `assesses:`, and the English word `reassesses: REQ-004` all credited their items. The `reassesses:`/comment behaviour is `index()` in the shared `gr_id_run` and applies equally to `satisfies:`/`mitigates:`, so it is inherited rather than introduced; the fence behaviour is at least self-consistent (gate and rewrite agree, so no dangling reference is manufactured). No plan decision states either.
disposition: accepted without change. No gate in this toolkit parses fences or comments, every ledger template says so and tells authors to indent or inline illustrative forms, and gate and rewrite agree. The `index()` reading of a keyword inside a longer word is a property of the one-definition rule shared by every annotation and is recorded under Gaps as an inherited residual, not opened here.

**finding-8**: MINOR — README.md's `finalize-docs.sh` row promises it "rewrites every reference to a renamed file across the ledger directories and the SOUP file"; the `left` outcome (an ambiguous bare name is deliberately not rewritten) is documented only in skills/merge-change/SKILL.md. The problem-report resolution line says "path and unambiguous bare references", which is accurate; the README row is the one place the qualifier is missing.
disposition: fixed. The README row now says every path-shaped reference and every bare name only one rename maps are rewritten, and a bare name two renames share is reported as left. Reddens without it: the `reported as left` assertion added to `merge-step-3-reports-rewrites` (tests/skills.bats).

Round 2 (2026-09-08), a fresh independent subagent with the same inputs at
`d2d1687`: ran the suite itself (`1..628`, 628 ok, 0 not ok, exit 0, BWK
awk), five sabotages and probes on every round-1 fix, and returned
`approve-with-findings`: findings 1–6 and 8 confirmed closed (2 partly), 2
IMPORTANT and 5 MINOR new. Fixes are plan task T7. The author judged this
not the stuck-twice case develop-change stops for — every round-1 finding
closed, and each new finding carried its own fix — and ran a third round
rather than halting on the user.

**finding-9**: IMPORTANT — the relative link forms the gate now accepts are the forms finalize cannot carry, and three documents promise otherwise. Fixture: `[h](../risk/DRAFT-feature-x.md)` in docs/requirements/0001-01-01-base.md and `[h](./DRAFT-feature-x.md)` in docs/risk/README.md with the draft present: check-trace exits 0 on them in flight (finding 4's fix); `finalize-docs.sh` leaves both untouched (the path pass matches only the root-relative `docs/risk/DRAFT-…`, the bare pass skips any `/`-preceded occurrence); check-trace at merge step 5 then reports `DANGLING-FILE ../risk/DRAFT-feature-x.md` and `DANGLING-FILE ./DRAFT-feature-x.md`. Not silent, but README.md ("rewrites every path-shaped reference"), skills/merge-change/SKILL.md ("rewrites every reference to a renamed file across the ledger directories") and scripts/finalize-docs.sh's header ("rewrites every reference") over-promise, and skills/check-traceability/SKILL.md does not list "a relative link finalize could not carry" among the causes. Either resolve `<dir>/<basename>` against the referencing file's directory in the bare pass and rewrite when it points at the renamed draft, or say "root-relative path or bare name" in all three places and name this cause in the remedy row.
disposition: documented, not rewritten. Resolving `..` against a referencing file's directory inside awk is a path normaliser, and every ledger in this toolkit cites files root-relative or bare. The three sentences now say "root-relative path and bare name", the merge-change step says a relative link is reported by step 5 and written by hand, and the remedy row names the cause. Reddens without it: the `root-relative` / `relative link` assertions added to `merge-step-3-reports-rewrites` (tests/skills.bats).

**finding-10**: MINOR — finding 2 is only partly closed: two renames sharing an unambiguous basename (D4's own "common shape") produce duplicate preview lines, because the bare pass iterates `$renames`, so both pairs run with the same OLD/NEW; the real run consumes the occurrence on the first pair, dry-run cannot. Fixture (sibling drafts): dry-run printed four `would rewrite` lines, real printed three. The test covers a single draft only.
disposition: fixed. The bare pass iterates one `old new` pair per distinct basename. Reddens without it: `finalize: two sibling drafts sharing a basename preview and rewrite the same lines once`.

**finding-11**: IMPORTANT — finding 6's fix has no test. AGENTS.md: "Every behavior change to a script requires a bats test." Replacing the `scan_refs` guard with `:` leaves all 27 finalize-docs tests green. A test is feasible without a race: a `git` wrapper on PATH that removes a scope file when invoked with `grep -l` — with it, the real script exits 2 printing `reference scan failed (git grep exit 128)`, the mutant exits 0. Note also what the die leaves behind: the `git mv` is already staged and no reference was rewritten; a re-run is the documented silent no-op — worth one sentence in the header.
disposition: fixed. Reddens without it: `finalize: a reference scan that fails aborts instead of reporting a clean finalize`, built exactly as the reviewer described. The header states what a die leaves behind and that DANGLING-FILE names each reference to fix by hand.

**finding-12**: MINOR — the finding-3 test does not exercise the per-file probe it exists for. Replacing the probe with `true` keeps all tests green, because in the real run the path pass has already consumed the path-only file; the probe is load-bearing only under `--dry-run`, where the mutant adds a spurious `left docs/architecture/soup.md`.
disposition: fixed. The test now runs `--dry-run` first and asserts no `left` for the path-only file and exactly one for the file with a bare form.

**finding-13**: MINOR — the finding-5 disposition rests on a false claim: an unquoted glob-shaped scope name that matches a sibling is replaced by the match, not "scanned too". Fixture: `docs/risk/[x].md` holding a draft reference beside `docs/risk/x.md` — finalize printed no rewrite for `[x].md`, the file kept the draft name, and check-trace then convicted it. The name is unrealistic, but the argument is wrong and `set -f` costs one line already standard in the sibling script.
disposition: fixed. `set -f` after planning, with the comment corrected to say what was wrong. Reddens without it: `finalize: a glob-shaped ledger name is scanned as itself, not as what it matches`.

**finding-14**: MINOR — glued tokens are rewritten and the glued-prefix rule is untested in both scripts. Fixture line `Glued: xDRAFT-feature-x.md and _DRAFT-feature-x.md.` became `Glued: x2026-09-08-x.md and _2026-09-08-x.md.` — the bare pass guards only a preceding `/`. Separately, T6's pattern change in check-trace.sh has no test: restoring the round-1 pattern leaves all check-trace tests green.
disposition: fixed. A bare occurrence must begin the line or follow a character that cannot be part of a file name. Reddens without it: `finalize: a token glued to a longer word is not the file's name`; the pattern is pinned by `check-trace: a glued prefix is not a path, so the bare name resolves`.

**finding-15**: MINOR — a failed `rewrite_file` probe is reported as `reference scan failed`, which is not the scan; `scan_refs` already reports its own failure. Say "reference probe failed" so the two exits are distinguishable in a merge log.
disposition: fixed; message reads `reference probe failed`. No test — a message on a path no fixture reaches.

Round 3 (2026-09-09), a fresh independent subagent with the same inputs at
`808684d` (a first attempt at this round was cut off by a session limit
before reporting; its worktree was clean and was removed, and the round was
re-run from nothing): ran the suite itself (`1..633`, 633 ok, 0 not ok,
exit 0, BWK awk), probed every round-2 fix on throwaway fixtures with
sabotage, confirmed findings 9–15 closed or defensibly dispositioned, and
returned `approve-with-findings`: six MINOR, each stated by the reviewer as
one it would not block a merge on. The author fixed all six anyway (plan
task T8) — each is a sentence, a comment or a test assertion, and the
repository's precedent is to close MINOR findings rather than record them.

**finding-16**: MINOR (would not block) — the `set -f` before the dry-run preview, the one T7 adds "with a test", is unkillable by the suite: deleting it alone leaves all 31 finalize tests green (deleting the second one, or both, reddens `a glob-shaped ledger name is scanned as itself`). The test runs only the real path, which the second `set -f` re-protects; under `--dry-run` with `docs/risk/[x].md` beside `x.md` and the first one gone, the preview silently omits `[x].md`. Add a `--dry-run` assertion to that test.
disposition: fixed; the glob-name test now runs `--dry-run` first and asserts the `would rewrite docs/risk/[x].md` line. Reddens without the first `set -f`.

**finding-17**: MINOR (would not block) — rewrite and gate disagree on a left-glued token. The bare pass skips an occurrence preceded by a name character; the gate extracts the bare name from the same token and, once the draft is renamed, convicts it. Measured after finalize: `aDRAFT-…`, `9DRAFT-…`, `_DRAFT-…`, `.DRAFT-…`, `-DRAFT-…` and the markdown emphasis `_DRAFT-feature-x.md_` are each `DANGLING-FILE`; right-glued `DRAFT-feature-x.md.bak` is rewritten by both, consistently. Loud not silent — same class as finding 9 — but `_DRAFT-x.md_` is a plausible spelling and none of the three documents lists a glued or emphasised name among the hand-fix cases.
disposition: documented in the finalize header, the README row, merge-change step 3 and the check-traceability row, as the same class as a relative link: not rewritten, reported after the merge, written by hand. The rewrite is not widened: a token that is not the file's name is not the rewrite's to change.

**finding-18**: MINOR (would not block) — the gate's token class is narrower than what finalize renames. finalize plans any `DRAFT-*.md` (whitespace aside) and rewrote `DRAFT-feature-a+b.md` correctly; the gate's `DRAFT-[A-Za-z0-9_.-]+\.md` matches nothing for a `+`/`@` slug, so such a reference with no such file produced no `DANGLING-FILE` while a plain control on the same line was convicted. A silent miss, but only for names the shipped grammar never produces; the header and the gate comment should state the class.
disposition: the header names the class and the comment states why it is narrower than the rename — widening it to any non-space character makes prose match. Not widened. Recorded under Gaps.

**finding-19**: MINOR (would not block) — in a manifest repository a bare cross-unit reference to a draft that EXISTS is convicted while in flight: a bare name resolves against this unit's `doc_*` directories only, and the message says the file does not exist. The verdict is defensible (a bare name across units is ambiguous; the path form resolved), but the message is false there and the check-traceability row's "A reference to a draft that exists is fine: that is every change in flight" over-promises for it.
disposition: fixed. The bare arm's message now says `found in none of this config's ledger directories — after a merge, write the dated name; across units, write the path`; the row states the edge. Reddens without it: `check-trace: a bare draft name found in no ledger directory says where it looked`.

**finding-20**: MINOR (would not block) — the header's "A die during the rewrite pass leaves the renames staged and the references as they were" overstates: with two files holding the reference and the second's directory read-only, the run rewrote the first, died on the second, and `git status` showed the first rewritten and unstaged beside the staged rename. The recovery advice holds. Say "references rewritten before the die stay rewritten"; and "staged" holds only for tracked drafts.
disposition: header corrected to say exactly that.

**finding-21**: MINOR, informational (would not block) — dry-run and real output differ only in the FILE column when the reference sits inside a renamed draft (`would rewrite docs/risk/DRAFT-feature-x.md: …` vs `rewrote docs/risk/2026-09-09-x.md: …`). Inherent to previewing before the rename and not a defect; one clause in the header would spare the reader the diff.
disposition: one sentence added to the header.

Round 4 (2026-09-09), a fresh independent subagent, scope narrowed to T8 —
does it close findings 16–21 and introduce nothing new? It ran the suite
itself (`1..634`, 634 ok, 0 not ok, exit 0), proved the finding-16 mutant
(with the first `set -f` neutralised the new dry-run assertion goes red
while the real-run assertion stays green, so the assertion is the only
kill), and verified each other disposition on fixtures: the two DANGLING-FILE
arms print their own messages and both exit 1; a bare name for an existing
sibling draft passes and the relative link still resolves; a die mid-rewrite
leaves the tracked draft staged-renamed, the untracked one plain-moved, the
earlier rewrite kept, no temp file, and the re-run silent; the dry-run's
FILE column and the glued/emphasised cases behave as the new sentences say;
the header's token class matches the pattern the gate runs. `/bin/sh -n`
clean on both scripts, every `case` pattern parenthesised, nothing new
through `awk -v`, `_why` set in both arms and read once. Verdict
`approve-with-findings`: two MINOR, both stated non-blocking, both fixed as
plan task T9.

**finding-22**: MINOR, and I would not block a merge on it — the path arm gives the message `names a draft ledger file that does not exist`, but the arm has just probed exactly two locations (the repository root and the referencing file's own directory) and neither is named, while the sibling bare arm was split precisely so that it says where it looked. In a manifest repository a path-shaped reference written relative to another unit's root — `docs/risk/DRAFT-x.md` from a consumer unit whose provider holds that file — is convicted with a sentence that flatly asserts non-existence, the same over-promise finding 19 fixed on the other arm. The asymmetry is cosmetic (the path form is the one the fix tells authors to use, and it does resolve from either of the two roots the gate tries), so it is a wording gap, not a wrong verdict.
disposition: fixed. The path arm now reads `found neither at the repository root nor beside the file naming it`, and the gate's comment states that each arm names the places it looked rather than asserting the file exists nowhere.

**finding-23**: MINOR, and I would not block a merge on it — the finding-19 regression test pins the new bare-arm sentence but no test pins the path arm's sentence: the older assertion stops at the site prefix. So a future edit that gave the path arm the bare arm's wording — or dropped `_why` from that arm entirely — would keep all 634 tests green. That the split survives is currently carried by one arm's test only. Test-coverage depth on a message string, not a defect in shipped behaviour.
disposition: fixed. The path-arm test now asserts the arm's own wording alongside the site, so each arm is pinned by its own test. Reddens without the finding-22 fix, and vice versa.

**No fifth review round was run, and that is a decision.** This repository is
class A (docs/adr/2026-08-22-safety-class.md), whose ADR records independent
review as optional and kept as practice rather than imposed. Four rounds ran
on this change and their findings converged strictly: 1 IMPORTANT + 7 MINOR,
then 2 IMPORTANT + 5 MINOR, then 6 MINOR all non-blocking, then 2 MINOR both
non-blocking. T9's diff is one message string and one test assertion, both
named by the round-4 reviewer with the wording to use. The gate re-ran in
full afterwards (the last row of the gate table); no independent reviewer saw
that final tree, and this paragraph is the record of it.

## Gaps

- Nothing judges an assessment's quality; `assesses:` requires the author to
  declare which items a passage covers, the same standard every other
  annotation holds. The message text promises no more.
- `assesses:` inherits the line-wise asymmetry lib.sh states for `traces:`
  and `satisfies:` — it is found anywhere on the line and cannot be orphaned.
  Stated in the script; accepted (D5).
- The rewrite's directory-based scope limit is a heuristic: a ledger sentence
  that itself narrates a rename would be rewritten into a false statement.
  Every rewrite is printed so the merging agent reads it; `merge-change`
  step 3 says so.
- `DANGLING-FILE` resolves `DRAFT-*.md` tokens only, and only names in the
  ledger grammar's character class (review finding 18): a slug carrying `+`
  or `@` is renamed by finalize but never looked for by the gate. A mistyped
  dated name dangles just the same and is not looked for; that is a
  different class, not created by construction, and is left open here.
- A relative link (`../risk/DRAFT-x.md`), a name glued to a longer token, or
  one wrapped in emphasis underscores is not rewritten by finalize and is
  reported by `DANGLING-FILE` after the merge, to be written by hand
  (findings 9 and 17). Loud, not silent; documented in three places.
- In a manifest repository a bare name resolves against the running config's
  ledger directories only, so a bare cross-unit reference to a draft that
  exists is reported while in flight, with a message that says where it
  looked (finding 19). The path form resolves. After the provider's finalize
  the consumer's path reference correctly dangles — D2's unreachable case,
  demonstrated by the round-3 reviewer on a two-unit fixture.
- A bare basename shared by two drafts that diverge only by a collision
  suffix is left unrewritten and reported as `left …`; the gate convicts it
  if it does not resolve. Real projects name sibling drafts alike, so this
  path will be exercised.
- Inherited, surfaced by review finding 7: `gr_id_run` finds its keyword with
  `index()`, so `reassesses: REQ-…` credits the item, as `dissatisfies:`
  would for `satisfies:`. Toolkit-wide, one definition, not opened here.
  Fenced code blocks and HTML comments are live text to every gate and to
  the rewrite, as the templates state.
- The check scripts still do not run against this repository; every gate
  figure above is the bats suite, and the ledger checks were performed by
  hand.
