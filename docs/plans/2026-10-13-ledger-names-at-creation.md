# Ledger names at creation Implementation Plan

**Goal:** A change names each ledger file it creates
`docs/<area>/<YYYY-MM-DD>-<slug>.md`, dated the day it creates it, and nothing
renames it: `finalize-docs.sh` and `merge-change`'s finalize step are removed.
**Implements:** ADR-cy7ahd (minted for this plan with `new-id.sh ADR`, written
by T1) and D1–D8 and D10 below; guardrails keeps no REQ ledger of its own.
D9 is ledger bookkeeping, checked by review, not by a test. Each test
cites `verifies: D<n> (docs/plans/2026-10-13-ledger-names-at-creation.md)`,
or `verifies: PR-pc6byk` for T7.
**Resolves:** PR-umtm9b; PR-pc6byk (minted for this plan with `new-id.sh PR`,
opened and resolved by T7)
**Safety class:** not configured in this repository; worked as class B (normal
and abnormal cases for each changed gate)
**Verification:** `tests/run-tests.sh`, every test passing;
`tests/mutate.sh`, every mutation applied or declared retired, none unusable
**Base:** local `main` at `9eeb8b6`, per AGENTS.md non-negotiable 4.

The user ruled on 2026-10-13: name ledger files at creation and never rename
them. Today a change writes `docs/<area>/DRAFT-<branch>-<slug>.md`, and
`merge-change` step 3 runs `finalize-docs.sh`, which renames it to
`<finalize-date>-<slug>.md` and rewrites references across the ledger
directories and the SOUP file. The rename finalizes no ID: `new-id.sh` mints
each ID when the item is written. The script's own header says the filename
"is a handle for finding the file, not a record of when it merged". The
rename is a late commit that rewrites shared ledger files, and its `-2`
collision check sees only the local disk. Plans are already named this way:
`docs/plans/YYYY-MM-DD-<topic>.md`.

## Investigation

`git grep -n -E 'DRAFT|finalize-docs|finalize-date|DRAFT-FILE|DRAFT-ID'`
outside `.worktrees`, `docs/plans` and `docs/verification`, at `9eeb8b6`:

- **Scripts.** `finalize-docs.sh` (the rename). `check-ids.sh`: `DRAFT-FILE`,
  its `--allow-draft-files` flag, its remedy naming step 3, and `DRAFT-ID`.
  `check-trace.sh`: `DANGLING-FILE`, a scan of the `doc_*` files for a
  `DRAFT-*.md` reference that resolves to no file. `check-units.sh`:
  `DISCLAIMED-DRAFT`, draft tokens and draft-named files under `not_a_unit:`.
  `lib.sh`: `GR_DRAFT_TOKEN_RE` and `GR_DRAFT_FILE_RE`, plus comments.
  `prune-plans.sh` and `merge-preflight.sh`: comments only.
  `prune-plans.sh` has no `DRAFT` exclusion.
- **Skills.** `merge-change` (step 3, step 5's `DRAFT-FILE` ruling, step 6's
  "where step 3 renamed something", the frontmatter's "ID finalization",
  `references/rationale.md` and `references/multi-unit.md`).
  `worktree-discipline` step 6. `grill-requirements`, `analyze-risks`,
  `design-architecture` and `resolve-problem` (where new items go).
  `verify-before-merge` check 3 and its red flags. `check-traceability`
  step 1 and its red flags, and `references/config.md`. `ratchet` step 3's
  ledger paragraph, upgrade step 2, and `references/upgrade-notes.md`.
- **Templates and docs.** `templates/srs.md`, `rmf.md`, `sad.md`,
  `problems.md` and this repository's copy, `docs/problems/README.md`.
  `templates/config.yaml` comments. `templates/AGENTS-block.md` (the ledger
  rule and the tool list). `templates/verification.md` (the "Measured on"
  paragraph). `README.md` (the flow diagram and the script table).
- **Tests.** `finalize-docs.bats` (the whole file). `check-ids.bats` (the flag
  tests, the per-script pins, and the stock-install test's finalize half).
  `remedies.bats`, `merge-preflight.bats` and `adr-ids.bats` (the flag and the
  remedy). `portability.bats` (the awk sweep). `skills.bats` (the step 3 tests,
  the multi-unit finalize test, the rationale grep). `check-trace.bats`
  (`DANGLING-FILE`; it asserts only the parts of each message that stay).
  `check-units.bats` (`DISCLAIMED-DRAFT`, unchanged).
- **Problem items.** `PR-umtm9b` (open): `finalize-docs.sh` adopts another
  change's draft. `PR-8ucezf` (open): `DRAFT-FILE` reads the whole tree and
  names no change. `PR-2jr4pj` (open) lists `finalize-docs.sh`'s header among
  its sites.

**Step citations.** 30 files cite `merge-change` steps 6a–6d, and about 40
lines cite steps 7 and 8: AGENTS.md non-negotiable 2, `finish-merge.sh`,
`check-review.sh`, `templates/verification.md`, `develop-change` and
`tests/skills.bats`, which locates steps by their `^6a\. ` headings. Steps 4
and 5 are cited in about 10 places, among them `merge-preflight.sh`,
`README.md`, AGENTS.md non-negotiable 4 and ADR-y8jmes. Step 3 is cited only
for finalizing. Step 6 is cited only as the tree-hash rerun, in
`multi-unit.md`, `rationale.md`, `prune-plans.sh`, `templates/verification.md`
and `tests/skills.bats`.

**Mutation anchors.** These `docs/verification/*.mutations/M*.sh` quote a line
this plan edits or deletes:

- `2026-08-22-id-tokens.mutations/M22.sh`, `M23.sh` and `M25.sh` quote the
  `check-ids.sh` flag lines. M23 anchors on
  `(--allow-draft-files) allow_draft_files=1 ;;`, and M25 on
  `if [ "$allow_draft_files" -eq 0 ]; then`.
- `M37`–`M41` and `M53` mutate `finalize-docs.sh`.

`grep -rlE 'DANGLING-FILE|found neither|found in none|Write the dated name|names a draft ledger|check/finalize|merge-preflight|prune-plans|check-units' docs/verification/*.mutations/`
prints only M22, M23 and M25. So no anchor quotes a `check-trace.sh`,
`lib.sh`, `prune-plans.sh` or `merge-preflight.sh` line this plan edits. The
retirement pin in `tests/mutations.bats` is 17.

**Open parallel work.** `.worktrees/base-premise-lapsed` adds the problems
ledger file `DRAFT-base-premise-lapsed-adr-scope.md` (commit `110ad02`,
2026-10-13). Nothing in that branch cites the name
(`git grep -n 'DRAFT-base-premise'` is empty). The branch also edits
`scripts/check-trace.sh` (header lines 17–35 and 124–150, the out-of-force
scan), `tests/check-trace.bats` (after line 39 and later),
`tests/helpers.bash` (lines 1–8), `tests/portability.bats` (the case-pattern
test), `skills/analyze-risks/SKILL.md` (a bullet after line 67) and
`skills/ratchet/references/upgrade-notes.md` (a section after line 109). None
of those hunks touches a region this plan edits. `.worktrees/code-guidelines`
has only its plan.

## Decisions

- **D1: ledger files are named at creation and never renamed.** A change
  creates `docs/<area>/<YYYY-MM-DD>-<slug>.md`, dated the day it creates the
  file. Every skill, template and README that says where new items go says
  so, and none mentions a rename. ADR-cy7ahd records the decision. Reasons:
  the user's ruling and the five facts above it.
- **D2: `finalize-docs.sh` is deleted outright, with
  `tests/finalize-docs.bats`.** It is not kept as a migration tool.
  - Kept, it would still perform the rename this change removes, and its
    collision check would still read only the local disk.
  - A draft in flight migrates with one `git mv` per file. `DRAFT-FILE` names
    each file (D3), and `DANGLING-FILE` names each reference the move leaves
    behind (D4).
  - This repository has no `.guardrails/` on `main` at `9eeb8b6`
    (`ls .guardrails` fails), so no pinned copy calls the script. When the
    self-hosting install lands, it copies a `scripts/` without it.
  - A target project's `/ratchet` upgrade copies new scripts over old ones and
    leaves a removed one behind. The upgrade note says to delete it, as it
    already says for `finalize-ids.sh` (D7).
  - `base-premise-lapsed` lands whichever change merges first. If it merges
    first, it runs `main`'s current step 3 and its draft is renamed as today.
    If this change merges first, its step 1 merges the deletion in, and
    `DRAFT-FILE` fails its pre-flight with the `git mv` remedy:
    `git mv docs/problems/DRAFT-base-premise-lapsed-adr-scope.md docs/problems/2026-10-13-adr-scope.md`,
    one fix dispatch, rerun from step 1. The file is dated the day it was
    added, and nothing cites it.
  - The merge-change skill an agent reads is the installed copy under
    `~/.agents/skills/` (`~/.claude/skills/merge-change` links there).
    Refreshing that copy after this merge is the user's.
- **D3: `DRAFT-FILE` stays, as a legacy-name error under every flag, and
  `--allow-draft-files` is retired.**
  - The scan is unchanged: any draft-named file in the tree, or in the unit
    when scoped.
  - The scan fails closed: a `git ls-files` or grep that fails exits 2,
    naming the failure, rather than reading as a tree with no draft-named
    ledger file (CODE_GUIDELINES review, round 1, finding-1).
  - The remedy becomes the rename:
    `git mv it to <YYYY-MM-DD>-<slug>.md, dated the day its change created it: no merge step renames a ledger file. Then fix each reference check-trace.sh reports as DANGLING-FILE.`
    It is under the 200-byte limit `tests/remedies.bats` enforces.
  - `--allow-draft-files` exits 2 as an unknown argument. That is the
    precedent of `--allow-drafts` and `--base`: a flag accepted in silence is
    a check the caller believes they ran.
  - Not removed: a change written under an old installed skill would merge a
    `DRAFT-<branch>-` name into the base for good, contradicting the dated
    names the READMEs promise. The repair costs one `git mv`.
  - Not renamed to a new token: CI greps, the remedy tables and
    `merge-change` step 5 cite `DRAFT-FILE`.
  - Not scoped to the files the branch adds
    (`git diff --diff-filter=A <base>...HEAD`). That is `PR-8ucezf`'s fix, and
    it introduces a base-branch dependency `check-ids.sh` has never had. It
    stays open, amended (D9).
- **D4: `DANGLING-FILE` stays with its scan and scope; only its words
  change.**
  - The `git mv` of a legacy draft leaves references to the old name behind,
    in this tree or in another worktree. That is exactly the class the scan
    convicts, and it never fires for a file named at creation.
  - The messages end `— write the name the file has now`, and the remedy
    reads
    `Write the name the file has now: the dated name a draft-named ledger file was renamed to. Never delete the reference to pass the gate — see the script header.`
  - Nothing else keys on the `DRAFT` prefix. `DRAFT-ID` convicts draft ID
    tokens, an older and separate legacy. `DISCLAIMED-DRAFT`,
    `GR_DRAFT_TOKEN_RE` and `GR_DRAFT_FILE_RE` are unchanged, and
    `check-units.sh` is not edited. `prune-plans.sh` has no `DRAFT`
    exclusion; only its comment changes.
  - No check needs to know which change owns a ledger file. Where one would,
    `git diff --diff-filter=A <base>...HEAD` derives it.
- **D5: `merge-change` keeps steps 4, 5, 6a–6d, 7 and 8 under their
  numbers.**
  - Step 3 (finalize) is removed. The tree check that was step 6 becomes
    step 3, run when the step 2 summary arrives. Step 6 becomes a one-line
    heading over 6a–6d.
  - Renumbering 6a–8 would touch 30 files and about 40 lines, AGENTS.md
    among them, and every record and target-project habit that names "step
    6c" or "step 7". It would also conflict with both open worktrees:
    `base-premise-lapsed` edits `review-checklist.md`, which cites 6a, and
    `code-guidelines` will rewrite `develop-change`, which cites 6a and 6b.
  - The tree check loses nothing by moving to step 3. Steps 4 and 5 only
    read, and every fix reruns from step 1. At step 3 it also catches a
    worktree changed while the suite ran in the background.
  - The skill drops from 2,000 words to about 1,900.
- **D6: a same-name collision is an add/add conflict at step 1.** Step 1
  gains one bullet: move this change's version to a new slug
  (`git show :2:<path> > <new path>`), keep the base's
  (`git checkout --theirs -- <path>`), and write the new name wherever this
  change cites it. This replaces the `-2` suffix, which saw only the local
  disk. A fixture test proves git reports the conflict and that the
  documented commands keep both files.
- **D7: the upgrade note.**
  - A new section, `## Ledger files are named at creation`, after
    `## \`DANGLING-FILE\``. That section and the "Item IDs are random tokens"
    bullets are rewritten so that no current sentence promises a rename.
  - Order-of-work item 1 gains a sentence. It is not a new item, because
    `tests/skills.bats` pins that list's numbering.
  - `ratchet` upgrade step 2 deletes `finalize-docs.sh` with
    `finalize-ids.sh`.
- **D8: mutation evidence.**
  - M22 is retired: it re-adds suppression of `DRAFT-ID` by a flag that no
    longer exists, and the test that killed it goes with the flag.
  - M23 is re-cut onto the `(*) gr_die "unknown argument: $1" ;;` line, and
    M25 onto the `# --- DRAFT-FILE:` header. Each is re-proven to apply and
    to kill a test.
  - M37–M41 and M53 are retired with the script they mutate.
  - The retirement pin rises 17 → 18 in T2 and 18 → 24 in T6, each in the
    commit that retires.
- **D9: problem items.**
  - `PR-umtm9b` is resolved by D2: nothing renames a ledger file at merge, so
    nothing can adopt another change's file.
  - `PR-8ucezf` stays open with an amendment. The adoption that made a
    discriminator unreachable is gone, and the presence-on-base discriminator
    remains the candidate.
  - `PR-2jr4pj` gains a line that its `finalize-docs.sh` site no longer
    exists.
  - `PR-pc6byk` is opened and resolved by T7.
  - No prose added to a ledger file names a draft file by a token that
    matches `DRAFT-[A-Za-z0-9_.-]+\.md`: `DANGLING-FILE` reads ledger prose.
- **D10: the clock flake is fixed by pinning "today" for the whole of
  `tests/check-trace.bats`.**
  - `pin_today` in `tests/helpers.bash` puts a `date` stub first on `PATH`.
    The stub answers `date +%Y-%m-%d` with the pinned day and passes any
    other call to the real `date`. `days_ago` counts back from the pinned
    day.
  - `check-trace.bats` calls it first in `setup()`. That covers the 14 tests
    asserting an exact age, and the limit-boundary tests such as
    `problem_age_days passes an item exactly at the limit`, which crossing
    midnight would flip just the same.
  - A test that stubs `date` itself puts its stub ahead of the pin, as it did
    before.
  - No other suite asserts an exact age (`grep -n 'days_ago' tests/*.bats`
    and the age assertions in `remedies.bats`, `merge-preflight.bats` and
    `units-chain.bats` were checked).
- **Not changed:**
  - ADR-bh4xgr: a record of a decision; its step 3 sentence describes the
    sequence it was decided in.
  - `docs/risk/2026-09-03-units-architecture-derived.md`: its "finalized"
    means finished and stays true.
  - `docs/plans/`, `docs/verification/` and the resolved problem items.
  - `check-units.sh` and `DRAFT-ID`.

## Tasks

| Task | Files touched | Depends on |
| --- | --- | --- |
| T1 | `docs/adr/ADR-cy7ahd-ledger-files-named-at-creation.md`, `tests/skills.bats` | — |
| T2 | `scripts/check-ids.sh`, `scripts/merge-preflight.sh`, `tests/check-ids.bats`, `tests/remedies.bats`, `tests/merge-preflight.bats`, `tests/adr-ids.bats`, `tests/portability.bats`, `tests/mutations.bats`, three `id-tokens` mutations | — |
| T3 | `scripts/check-trace.sh`, `tests/remedies.bats` | T2 |
| T4 | 20 skill, template and doc files, `tests/skills.bats` | T1 |
| T5 | `skills/ratchet/SKILL.md`, `skills/ratchet/references/upgrade-notes.md`, `tests/skills.bats` | T4 |
| T6 | the deletion, `scripts/lib.sh`, `scripts/prune-plans.sh`, two problem files, five tests, six mutations | T2, T3, T5 |
| T7 | `tests/helpers.bash`, `tests/check-trace.bats`, `docs/problems/2026-10-13-age-tests-cross-midnight.md` | — |

Each task is dispatched to a subagent working in
`.worktrees/ledger-names-at-creation-t<N>`, created with
`sh scripts/task-worktree.sh start t<N>` and merged with
`sh scripts/task-worktree.sh merge t<N>` from the change worktree. Run single
suites with `tests/run-tests.sh tests/<file>.bats`; the full gate is
dispatched by `verify-before-merge`, never run in the dispatcher's context.

### T1 — ADR-cy7ahd records the decision

**Files touched:** `docs/adr/ADR-cy7ahd-ledger-files-named-at-creation.md`,
`tests/skills.bats`
**Parallel:** yes (with T2, T3 and T7)

1. RED: in `tests/skills.bats`, after `ADRs: the pruning decision is recorded
   and accepted`, add:

   *(Code pruned at merge: 15 lines. Files touched: `docs/adr/ADR-cy7ahd-ledger-files-named-at-creation.md`, `tests/skills.bats`.)*

   Run `tests/run-tests.sh tests/skills.bats` and watch it fail with
   `no .../ADR-cy7ahd-ledger-files-named-at-creation.md`.
2. GREEN: write the ADR in the shape of ADR-bh4xgr: item line on line 1,
   `Date: 2026-10-13`, `Status: accepted`, then `## Context`, `## Decision`,
   `## Consequences`, `## Alternatives considered`. Line 1:

   *(Code pruned at merge: 1 line. Files touched: `docs/adr/ADR-cy7ahd-ledger-files-named-at-creation.md`, `tests/skills.bats`.)*

   - **Context:** the five facts in this plan's preamble, the `PR-umtm9b`
     adoption, and that plans already follow the convention.
   - **Decision:**
     - the rule;
     - the script deleted;
     - `DRAFT-FILE` kept as a legacy-name error whose remedy is the `git mv`,
       and `--allow-draft-files` rejected;
     - `DANGLING-FILE` kept for the references such a move leaves;
     - step 3 of `merge-change` now the tree check, steps 4–8 numbered as
       before;
     - ruled by the maintainer on 2026-10-13.
   - **Consequences:**
     - a same-name collision is an add/add conflict at step 1, resolved by a
       new slug for this change's file;
     - the date is the creation day, so `ls` reads in creation order and the
       merge day is in git;
     - no reference is rewritten, because nothing renames;
     - a target project renames each draft in flight by hand once;
     - `PR-8ucezf` stays open: `DRAFT-FILE` still reads the whole tree.
   - **Alternatives considered:**
     - keep `finalize-docs.sh` as a migration tool (D2);
     - remove `DRAFT-FILE` (D3);
     - renumber the whole sequence (D5).

   Name the gates in backticks, `` `DRAFT-FILE` `` and `` `DANGLING-FILE` ``,
   as the test matches them. Write no token matching
   `DRAFT-[A-Za-z0-9_.-]+\.md`; the placeholder `DRAFT-<branch>-<slug>.md`
   does not match.
3. Run `tests/run-tests.sh tests/skills.bats`: all pass. Commit.

**Done** (aa48084).
red -> green: `skills.bats: ADRs: the ledger-naming decision is recorded and accepted` — red at `[ -f "$adr_file" ]`, no ADR file.

### T2 — `DRAFT-FILE` is a legacy name, and `--allow-draft-files` is retired

**Files touched:** `scripts/check-ids.sh`, `scripts/merge-preflight.sh`,
`tests/check-ids.bats`, `tests/remedies.bats`, `tests/merge-preflight.bats`,
`tests/adr-ids.bats`, `tests/portability.bats`, `tests/mutations.bats`,
`docs/verification/2026-08-22-id-tokens.mutations/M22.sh`,
`docs/verification/2026-08-22-id-tokens.mutations/M23.sh`,
`docs/verification/2026-08-22-id-tokens.mutations/M25.sh`
**Parallel:** yes (with T1 and T7)

1. RED, in `tests/check-ids.bats`:
   - Replace `check-ids: a draft ID fails even with --allow-draft-files` with:

     *(Code pruned at merge: 12 lines. Files touched: `scripts/check-ids.sh`, `scripts/merge-preflight.sh`, `tests/check-ids.bats`, `tests/remedies.bats`, `tests/merge-preflight.bats`, `tests/adr-ids.bats`, `tests/portability.bats`, `tests/mutations.bats`, `docs/verification/2026-08-22-id-tokens.mutations/M22.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M23.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M25.sh`.)*

   - Delete `check-ids: --allow-draft-files tolerates a draft ledger filename`.
   - Rename `check-ids: a draft ledger filename still fails without the flag`
     to `check-ids: a draft ledger filename fails` and add
     `# verifies: D3 (docs/plans/2026-10-13-ledger-names-at-creation.md)`.
   - Add a positive control after it:

     *(Code pruned at merge: 8 lines. Files touched: `scripts/check-ids.sh`, `scripts/merge-preflight.sh`, `tests/check-ids.bats`, `tests/remedies.bats`, `tests/merge-preflight.bats`, `tests/adr-ids.bats`, `tests/portability.bats`, `tests/mutations.bats`, `docs/verification/2026-08-22-id-tokens.mutations/M22.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M23.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M25.sh`.)*

2. RED, in `tests/remedies.bats`:
   - Delete `check-ids: --allow-draft-files prints no fix line for a draft
     file`.
   - Replace the test `check-ids: the DRAFT-FILE fix line names both the
     mid-change flag and the merge step that renames the file` with
     `check-ids: the DRAFT-FILE fix line is the git mv to a dated name`,
     annotated `verifies: D8 (docs/plans/2026-09-28-agent-first-skills.md),
     D3 (docs/plans/2026-10-13-ledger-names-at-creation.md)`. Same fixture,
     and its assertions are:

     *(Code pruned at merge: 3 lines. Files touched: `scripts/check-ids.sh`, `scripts/merge-preflight.sh`, `tests/check-ids.bats`, `tests/remedies.bats`, `tests/merge-preflight.bats`, `tests/adr-ids.bats`, `tests/portability.bats`, `tests/mutations.bats`, `docs/verification/2026-08-22-id-tokens.mutations/M22.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M23.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M25.sh`.)*

3. RED, in `tests/merge-preflight.bats`:
   - Rename `merge-preflight: IDS fails on a draft-named ledger file, because
     check-ids.sh runs without --allow-draft-files` to `merge-preflight: IDS
     fails on a draft-named ledger file, and its fix line renames it`, and
     add D3 to its `verifies:` line.
   - Replace the step 3 comment and assertion with:

     *(Code pruned at merge: 3 lines. Files touched: `scripts/check-ids.sh`, `scripts/merge-preflight.sh`, `tests/check-ids.bats`, `tests/remedies.bats`, `tests/merge-preflight.bats`, `tests/adr-ids.bats`, `tests/portability.bats`, `tests/mutations.bats`, `docs/verification/2026-08-22-id-tokens.mutations/M22.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M23.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M25.sh`.)*

4. RED, in `tests/adr-ids.bats`: rename `ADR IDs: an ADR draft token is
   DRAFT-ID, with and without --allow-draft-files` to `ADR IDs: an ADR draft
   token is DRAFT-ID`, and delete its last three lines (the run with the flag
   and its two assertions).
5. RED, in `tests/portability.bats`, in the awk sweep:
   - The fixture's ledger file becomes
     `docs/requirements/2026-01-02-dose-logging.md`.
   - The sweep line `check-ids.sh|--allow-draft-files` becomes
     `check-ids.sh|`.
   - The comment "check-ids must tolerate the draft filename that is still a
     draft, and" becomes "check-ids reads a ledger file named at creation,
     and".
6. Run `tests/run-tests.sh` on each of the five files. The new rejection test,
   the remedy test and the pre-flight test fail for the right reason: exit 0
   where 2 is expected, and the old fix line. The positive control and the
   renamed tests pass.
7. GREEN, in `scripts/check-ids.sh`:
   - The usage line `# check-ids.sh [--allow-draft-files]` becomes
     `# check-ids.sh`.
   - The `DRAFT-FILE` header entry reads:

     *(Code pruned at merge: 4 lines. Files touched: `scripts/check-ids.sh`, `scripts/merge-preflight.sh`, `tests/check-ids.bats`, `tests/remedies.bats`, `tests/merge-preflight.bats`, `tests/adr-ids.bats`, `tests/portability.bats`, `tests/mutations.bats`, `docs/verification/2026-08-22-id-tokens.mutations/M22.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M23.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M25.sh`.)*

   - The remedy arm is
     `(DRAFT-FILE) echo 'git mv it to <YYYY-MM-DD>-<slug>.md, dated the day its change created it: no merge step renames a ledger file. Then fix each reference check-trace.sh reports as DANGLING-FILE.' ;;`.
   - Delete `allow_draft_files=0` and the `(--allow-draft-files)` case arm.
     The comment above `(*)` becomes "--allow-drafts, --base and
     --allow-draft-files are rejected, not ignored. Each named a gate or a
     tolerance that no longer exists …", the rest unchanged.
   - Keep the `# --- DRAFT-FILE: no draft-named ledger files may reach the
     base branch ------` header line byte for byte (M25 anchors on its
     prefix). Unwrap the block below it from the
     `if [ "$allow_draft_files" -eq 0 ]; then … fi`, dedented one level. Its
     comment reads: "Scoped, the same narrowing as DRAFT-ID above: a sibling
     unit's draft name is that unit's to rename. "." when unscoped is the
     whole tree from the root this script already cd'd to."
   - In `scripts/merge-preflight.sh` line 18, `check-ids.sh, with no
     --allow-draft-files.` becomes `check-ids.sh.`
8. Mutations:
   - `M22.sh`: insert after its `# describes:` line:

     *(Code pruned at merge: 5 lines. Files touched: `scripts/check-ids.sh`, `scripts/merge-preflight.sh`, `tests/check-ids.bats`, `tests/remedies.bats`, `tests/merge-preflight.bats`, `tests/adr-ids.bats`, `tests/portability.bats`, `tests/mutations.bats`, `docs/verification/2026-08-22-id-tokens.mutations/M22.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M23.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M25.sh`.)*

   - `M23.sh`, re-cut (the old anchor, the flag's case arm, is gone):

     *(Code pruned at merge: 11 lines. Files touched: `scripts/check-ids.sh`, `scripts/merge-preflight.sh`, `tests/check-ids.bats`, `tests/remedies.bats`, `tests/merge-preflight.bats`, `tests/adr-ids.bats`, `tests/portability.bats`, `tests/mutations.bats`, `docs/verification/2026-08-22-id-tokens.mutations/M22.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M23.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M25.sh`.)*

   - `M25.sh`, re-cut:

     *(Code pruned at merge: 11 lines. Files touched: `scripts/check-ids.sh`, `scripts/merge-preflight.sh`, `tests/check-ids.bats`, `tests/remedies.bats`, `tests/merge-preflight.bats`, `tests/adr-ids.bats`, `tests/portability.bats`, `tests/mutations.bats`, `docs/verification/2026-08-22-id-tokens.mutations/M22.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M23.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M25.sh`.)*

   - In `tests/mutations.bats`, the pin goes from 17 to 18, both numbers in
     the test. The test `mutations: the retirement count is pinned, so one
     more is a visible edit` gains, as its first line,
     `# verifies: D8 (docs/plans/2026-10-13-ledger-names-at-creation.md)`.
9. Prove each re-cut mutation still kills. In the task worktree, run
   `sh docs/verification/2026-08-22-id-tokens.mutations/M23.sh`, then
   `tests/run-tests.sh tests/check-ids.bats`. Expected: `--allow-drafts is
   gone` and `--base is gone` fail. Then `git checkout -- scripts/check-ids.sh`.
   Do the same for M25. Expected: `draft-named file fails with DRAFT-FILE`
   and `a draft ledger filename fails` fail. Record both in the Done note.
10. Run `tests/mutate.sh docs/verification/2026-08-22-id-tokens.mutations`.
    Expected: `mutations: 53 applied, 1 retired, 0 unusable`. Then run
    `tests/run-tests.sh` on `check-ids.bats`, `remedies.bats`,
    `merge-preflight.bats`, `adr-ids.bats`, `portability.bats` and
    `mutations.bats`: all pass. Commit.

**Done** (166107f).
red -> green: `check-ids.bats: check-ids: --allow-draft-files is gone, and is rejected rather than ignored` — red: exit 0, the flag was accepted.
red -> green: `remedies.bats: check-ids: the DRAFT-FILE fix line is the git mv to a dated name` — red: the old `--allow-draft-files` / finalize-docs.sh fix line.
red -> green: `merge-preflight.bats: merge-preflight: IDS fails on a draft-named ledger file, and its fix line renames it` — red: `expected in output: git mv it to <YYYY-MM-DD>-<slug>.md`.
M23 re-proven: applied, `check-ids.bats` failed "--allow-drafts is gone, and is rejected rather than ignored" and "--base is gone, and is rejected rather than ignored". M25 re-proven: applied, `check-ids.bats` failed "draft-named file fails with DRAFT-FILE", "a draft ledger filename fails" and "a sibling's draft file and draft token are not this unit's finding". `tests/mutate.sh docs/verification/2026-08-22-id-tokens.mutations`: `53 applied, 1 retired, 0 unusable`.

### T3 — `DANGLING-FILE` says to write the name the file has now

**Files touched:** `scripts/check-trace.sh`, `tests/remedies.bats`
**Parallel:** no (serial, after T2: both touch `tests/remedies.bats`)

1. RED: in `tests/remedies.bats`, rename `check-trace: the DANGLING-FILE
   remedy names the dated file` to `check-trace: the DANGLING-FILE remedy and
   message name the file's current name`, add
   `D4 (docs/plans/2026-10-13-ledger-names-at-creation.md)` to its
   `verifies:` line, and replace its two `grep -q` assertions with:

   *(Code pruned at merge: 5 lines. Files touched: `scripts/check-trace.sh`, `tests/remedies.bats`.)*

   Add a second test, `check-trace: a bare DANGLING-FILE name says to write
   the name the file has now, or the path across units`. It cites D4, appends
   `\nSee DRAFT-other-alarms.md.\n` to
   `docs/requirements/0001-01-01-base.md`, commits, runs `check-trace.sh`,
   expects exit 1, and asserts that the output contains
   `found in none of this config's ledger directories — write the name the file has now; across units, write the path)`.
   Watch both fail on the old wording.
2. GREEN, in `scripts/check-trace.sh`:
   - Header entry for `DANGLING-FILE`, lines 38–48:

     *(Code pruned at merge: 11 lines. Files touched: `scripts/check-trace.sh`, `tests/remedies.bats`.)*

   - The remedy arm is
     `(DANGLING-FILE) echo 'Write the name the file has now: the dated name a draft-named ledger file was renamed to. Never delete the reference to pass the gate — see the script header.' ;;`.
   - The two `_why=` strings end `— write the name the file has now` and
     `— write the name the file has now; across units, write the path`.
   - The section comment above the scan:
     - Its first paragraph reads: "Nothing renames a ledger file at merge any
       more (ADR-cy7ahd). A draft-named file is a legacy name that DRAFT-FILE
       in check-ids.sh tells its author to `git mv` to its dated name, and
       that rename leaves every reference to the old name behind, in this
       tree or in another worktree: those are convicted here. Resolve, never
       ban — a reference to a draft that EXISTS is a change not yet renamed,
       and a gate on the prefix alone is DRAFT-FILE's job, not this one's."
     - "Scope is the rewrite's scope and not strict_paths" becomes "Scope is
       the doc_* files and the SOUP file, not strict_paths", and "narrate
       the rename" becomes "narrate history".
     - "finalize renames any DRAFT-*.md, so this is narrower than the
       rename" becomes "DRAFT-FILE convicts any DRAFT- name, so this is
       narrower than that gate".
     - The rest is unchanged.
   - Confirm that no anchor quotes an edited line:
     `grep -rn 'after a merge, write the dated name\|Write the dated name' docs/verification/*.mutations/`
     prints nothing.
3. Run `tests/run-tests.sh tests/remedies.bats` and
   `tests/run-tests.sh tests/check-trace.bats`: all pass (the
   `check-trace.bats` `DANGLING-FILE` tests assert only the unchanged middle
   of each message). Commit.

**Done** (b826357).
red -> green: `remedies.bats: check-trace: the DANGLING-FILE remedy and message name the file's current name` — red: `Write the dated name the draft file was merged under`.
red -> green: `remedies.bats: check-trace: a bare DANGLING-FILE name says to write the name the file has now, or the path across units` — red: `after a merge, write the dated name; across units, write the path`.

### T4 — the skills, templates and READMEs name a ledger file at creation

**Files touched:** `skills/merge-change/SKILL.md`,
`skills/merge-change/references/rationale.md`,
`skills/merge-change/references/multi-unit.md`,
`skills/merge-change/references/review-checklist.md`,
`skills/worktree-discipline/SKILL.md`,
`skills/worktree-discipline/references/rationale.md`, `skills/grill-requirements/SKILL.md`,
`skills/analyze-risks/SKILL.md`, `skills/design-architecture/SKILL.md`,
`skills/resolve-problem/SKILL.md`, `skills/verify-before-merge/SKILL.md`,
`skills/check-traceability/SKILL.md`,
`skills/check-traceability/references/config.md`, `templates/srs.md`,
`templates/rmf.md`, `templates/sad.md`, `templates/problems.md`,
`templates/config.yaml`, `templates/AGENTS-block.md`,
`templates/verification.md`, `README.md`, `docs/problems/README.md`,
`tests/skills.bats`
**Parallel:** no (serial, after T1: both touch `tests/skills.bats`)

1. RED: add three tests to `tests/skills.bats`, next to the merge-change
   tests:

   *(Code pruned at merge: 84 lines. Files touched: `skills/merge-change/SKILL.md`, `skills/merge-change/references/rationale.md`, `skills/merge-change/references/multi-unit.md`, `skills/worktree-discipline/SKILL.md`, `skills/grill-requirements/SKILL.md`, `skills/analyze-risks/SKILL.md`, `skills/design-architecture/SKILL.md`, `skills/resolve-problem/SKILL.md`, `skills/verify-before-merge/SKILL.md`, `skills/check-traceability/SKILL.md`, `skills/check-traceability/references/config.md`, `templates/srs.md`, `templates/rmf.md`, `templates/sad.md`, `templates/problems.md`, `templates/config.yaml`, `templates/AGENTS-block.md`, `templates/verification.md`, `README.md`, `docs/problems/README.md`, `tests/skills.bats`.)*

   Edit the existing tests:
   - Delete `merge-finalizes-touched-units-only: the finalize loop is
     scoped`, `merge-step-3-reports-rewrites: merge-change expects finalize
     to print what it rewrote`, `merge-change: step 3 commits only when it
     renamed something` and `merge-change: step 3 tells the author to read
     the unrewritten lines`. Each pins behavior this change removes. The
     problem items they verify (`PR-58zsvf`, `PR-9zvb36`, `PR-dkm5tq`) stay
     resolved as history, and `PR-dkm5tq` keeps the two tree-record tests.
   - In `merge-change: step 6 stands on step 2 where the tree is unchanged`,
     rename to `merge-change: step 3 stands on step 2 where the tree is
     unchanged`, and make the comment "Steps 4 and 5 only read, and every fix
     reruns from step 1, so a second dispatch on an unchanged tree measures
     what the first already measured."
   - In `merge-change: step 2 records the tree its gate summary describes`,
     the comment's "Step 6 compares" becomes "Step 3 compares".
   - In `merge-change: step 1 prunes the plans after the base merge and
     commits what changed`, the comment's second sentence becomes "run after
     the step 2 gate, it would change the tree after the gate on nearly every
     merge, and step 3 would dispatch a second suite run". The rationale grep
     `'and not with the draft renames at step 3'` becomes
     `'Run after the step 2 gate, it would fail step 3'`, with the message
     `"the rationale does not say why not after the gate"`.

   Watch the three new tests and the edited rationale grep fail.
2. GREEN, `skills/merge-change/SKILL.md`:
   - Frontmatter: `via ID finalization, full checks, and a verified signed
     squash merge` becomes `via full checks and a verified signed squash
     merge`.
   - Step 1, after the bullet "Run this step every round. …", add:
     "- An add/add conflict on a ledger file means the base merged a file of
     the same name. Keep the base's file, `git checkout --theirs -- <path>`,
     after saving this change's version under a new slug,
     `git show :2:<path> > <new path>`. Then `git add` both, and write the new
     name wherever this change cites it."
   - Delete step 3 (finalize) whole.
   - The old step 6's body moves up to become step 3. Its heading is
     `3. **Confirm the step 2 summary describes this tree**, when it
     arrives:`, followed by the same fence (`git status --porcelain`, `git
     rev-parse HEAD^{tree}` "compare with the hash recorded at step 2") and
     "Same hash and a clean worktree: **the step 2 summary stands**.
     Otherwise dispatch the suite again."
   - Step 5's second bullet: "`DRAFT-FILE` on a path this change did not add
     is a draft name another change left behind, renamed by a separate
     change."
   - In place of the old step 6, add the line
     `6. **Review the change and record it**, in steps 6a to 6d.`
   - Nothing else moves. Check `wc -w skills/merge-change/SKILL.md`: at most
     2,000 (expected about 1,900).
3. GREEN, `skills/merge-change/references/rationale.md`:
   - Section `## Step 1: plans are pruned after the base merge`:
     - The second paragraph reads: "Pruning runs at step 1, after the base
       merge, because it changes the tree on nearly every merge. Run after
       the step 2 gate, it would fail step 3's hash comparison and dispatch a
       second full suite run. Run at step 1, the change is in the tree the
       step 2 gate measures. The maintainer ruled this on 2026-10-08, and
       `ADR-bh4xgr` records it."
     - The third paragraph opens "The commit is conditional: on a rerun the
       plans are already pruned, …", the rest unchanged.
   - New section after it, `## Step 1: two ledger files with one name`:
     - A change names its ledger file when it creates it (`ADR-cy7ahd`), so
       two changes can choose one name.
     - Git reports that as an add/add conflict at the base merge, which is
       where every conflict is resolved.
     - The renamed file is this change's, because the base's is already
       merged and other changes may cite it.
     - No gate checks a reference to a dated name, so the author finds this
       change's citations with `git grep`.
     - The rename it replaces suffixed `-2` against the local disk only.
   - `## Step 2: recording the tree`: "step 6 compares" becomes "step 3
     compares".
   - Delete `## Step 3: the conditional commit and the unrewritten report` and
     `## Step 3: the finalize date`.
   - `## Steps 3 and 5: a draft another change left behind` becomes
     `## Step 5: a draft name another change left behind`:
     - Its first paragraph, on adoption by step 3, is deleted.
     - The remainder reads: "A `DRAFT-FILE` report names no change. A draft
       name a change merged before ledger files were named at creation fails
       step 4 for every later change. A `DRAFT-FILE` on a path this change
       did not add, ruled on at step 5, is that case."
     - Its last paragraph (the branch-prefix gap and the problem item) is
       unchanged.
   - `## Step 6: the tree hash decides re-verification` becomes `## Step 3:
     the tree hash decides re-verification`, moved to follow `## Step 2`,
     and reads: "The suite runs in the background for minutes, and anything
     that changes the worktree meanwhile leaves a summary describing a tree
     that is no longer there; a fresh summary is what shows nothing broke.
     Where the tree is unchanged, a second run would reproduce an answer
     already in hand. Steps 4 and 5 only read, and every fix reruns from step
     1, so the check is needed once per round. The hash makes it a mechanical
     test rather than a judgment about what the round touched."
4. GREEN, `skills/merge-change/references/multi-unit.md`: "(steps 2 and 6)"
   becomes "(steps 2 and 3)", and the bullet "run `finalize-docs.sh` (step 3)
   once per touched unit, … A dependent has no drafts to rename." is
   deleted.
5. GREEN, where new items go:
   - `worktree-discipline` step 6 becomes "6. **Ledger files.** On
     ledger-layout projects (doc config keys point at directories), new items
     go into this change's own file, `docs/<area>/<YYYY-MM-DD>-<slug>.md`,
     dated the day you create it. Nothing renames it. Edit an amendment to an
     existing item in the dated file that defines it; never move a
     definition between files."
   - `grill-requirements`: "Write new items in this change's own file,
     `docs/requirements/<YYYY-MM-DD>-<slug>.md`, dated the day you create
     it; nothing renames it."
   - `analyze-risks`: "New HAZ and RC items and new derived assessments go
     into this change's own file, `docs/risk/<YYYY-MM-DD>-<slug>.md`, dated
     the day you create it."
   - `design-architecture`: "Write new SDD and LLR items into this change's
     own file, `docs/architecture/<YYYY-MM-DD>-<slug>.md`, dated the day you
     create it."
   - `resolve-problem`: "add the problem to this change's own file in the
     problems ledger, `docs/problems/<YYYY-MM-DD>-<slug>.md`, dated the day
     you create it (directory from `doc_problems` in
     `.guardrails/config.yaml`)."
6. GREEN, the check skills:
   - `verify-before-merge` check 3: "`.guardrails/scripts/check-ids.sh`: no
     draft ID, no draft-named file, no duplicate and no malformed ID. A
     `DRAFT-FILE` is answered by the rename its fix line gives, never passed."
   - Delete "`--allow-draft-files` beyond check 3, " from the "Never weaken a
     check" bullet.
   - Delete the red-flag row "Add `--allow-draft-files` to the other checks
     too".
   - `check-traceability` step 1: the second command is
     `.guardrails/scripts/check-ids.sh                # ID sanity`, and the
     paragraph "At the merge, run `check-ids.sh` without
     `--allow-draft-files`: …" is deleted, as is the red-flag row
     "`--allow-draft-files` at the merge too".
   - `check-traceability/references/config.md`, in its not-validated
     paragraph: drop ", and `finalize-docs.sh` renames a draft ledger there as
     it would anywhere else" and ", and on whether the ledger still has its
     `DRAFT-` name".
7. GREEN, templates and READMEs:
   - In `templates/rmf.md`, `templates/sad.md`, `templates/problems.md` and
     `docs/problems/README.md`, the opening sentence becomes: "This directory
     is a per-change ledger: each change contributes one dated file,
     `YYYY-MM-DD-<slug>.md`, dated the day the change creates it and never
     renamed." Each file's following sentence is unchanged.
     `docs/problems/README.md`'s first paragraph stays identical to the
     template's.
   - In `templates/srs.md`: "This directory is a per-change ledger: each
     change contributes one dated file, `YYYY-MM-DD-<slug>.md`, dated the day
     the change creates it and never renamed, so `ls` reads in order of
     creation. **Edit existing items in the file that defines them** —
     definitions never move."
   - `templates/AGENTS-block.md`:
     - In the IDs paragraph, "Document FILES are still finalized at merge: new
       items go into `docs/<area>/DRAFT-<branch>-<slug>.md`, renamed to
       `<finalize-date>-<slug>.md` by `finalize-docs.sh`; existing items are
       edited in the dated file that defines them." becomes "A change names
       each ledger file it creates `docs/<area>/<YYYY-MM-DD>-<slug>.md`, dated
       the day it creates it, and nothing renames it; existing items are
       edited in the dated file that defines them."
     - The tool list's `check-ids.sh [--allow-draft-files]` line becomes
       `` `.guardrails/scripts/check-ids.sh` — draft IDs, draft-named files,
       duplicate and malformed IDs ``.
     - Its `finalize-docs.sh [--dry-run]` line is deleted.
   - `templates/config.yaml`:
     - In the not-validated comment, "and finalize-docs.sh renames a draft
       ledger there just as it would anywhere else" and "and on whether the
       ledger still contains its DRAFT- name", with "that the rename removes",
       are dropped.
     - "ID prefixes managed by the check/finalize scripts." becomes "ID
       prefixes managed by the check scripts."
   - `templates/verification.md`, the "Measured on" paragraph: "Where
     `merge-change` step 3 renamed nothing, this is the tree step 2 measured"
     becomes "Where `merge-change` step 3 found the tree unchanged, this is
     the tree step 2 measured".
   - `README.md`:
     - The diagram node becomes `M[merge-change<br/>independent review,<br/>verification record + check-review.sh,<br/>signed squash merge, cleanup worktree]`.
     - The `finalize-docs.sh` table row is deleted.
     - The `check-ids.sh` row reads "Draft IDs, draft-named files, duplicate
       and malformed IDs."
8. Run `tests/run-tests.sh tests/skills.bats`. All pass, including `skill
   shape: every SKILL.md is at most 2,000 words`; `worktree-discipline` was
   at 1,996 and must stay at or under 2,000. `the skills and templates name
   the finalize date, not the merge date` must still pass: no new text says
   "merge date". Commit.

**Done** (5542502).
red -> green: `skills.bats: ledger files: the skills and templates name a ledger file at creation, and nothing renames it` — red: `DRAFT-<branch>-<slug>` still taught in analyze-risks, verify-before-merge and others.
red -> green: `skills.bats: merge-change: no step renames a ledger file, and step 3 confirms the tree the summary describes` — red: `finaliz` in the frontmatter and step 3.
red -> green: `skills.bats: merge-change: two changes that name a ledger file alike meet at step 1, and the documented resolution keeps both` — red: step 1 had no add/add bullet.
red -> green: `skills.bats: merge-change: step 1 prunes the plans after the base merge and commits what changed` — red: the rationale did not say why not after the gate.

### T5 — the upgrade note and the ratchet skill

**Files touched:** `skills/ratchet/SKILL.md`,
`skills/ratchet/references/upgrade-notes.md`, `tests/skills.bats`
**Parallel:** no (serial, after T4: both touch `tests/skills.bats`)

1. RED: add to `tests/skills.bats`:

   *(Code pruned at merge: 24 lines. Files touched: `skills/ratchet/SKILL.md`, `skills/ratchet/references/upgrade-notes.md`, `tests/skills.bats`.)*

   Watch it fail.
2. GREEN, `skills/ratchet/SKILL.md`:
   - Step 3's ledger paragraph: "each merged change adds one file,
     `DRAFT-<branch>-<slug>.md` until `merge-change` renames it
     `YYYY-MM-DD-<slug>.md`." becomes "each change adds one file,
     `YYYY-MM-DD-<slug>.md`, dated the day the change creates it."
   - Upgrade step 2: "Delete `.guardrails/scripts/finalize-ids.sh` if
     present." becomes "Delete `.guardrails/scripts/finalize-ids.sh` and
     `finalize-docs.sh` if present."
   - The skill was at 1,997 words and must stay at or under 2,000.
3. GREEN, `skills/ratchet/references/upgrade-notes.md`:
   - Order of work, item 1, appends: "A change in flight with a `DRAFT-`
     ledger file renames it after the upgrade ("Ledger files are named at
     creation" below)."
   - "Item IDs are random tokens", first bullet: drop the sentences
     "`finalize-docs.sh` replaces it; it renames the change's draft ledger
     file and does nothing to IDs." and "`merge-change` step 3 would find a
     script that still tries to mint." Keep the deletion and the CI
     sentence.
   - The `--allow-drafts` bullet: "The first is now `--allow-draft-files`,
     and it covers only ledger files with a draft name." becomes "So is
     `--allow-draft-files` ("Ledger files are named at creation" below)."
   - `## \`DANGLING-FILE\`` reads: "`check-trace.sh` reports `DANGLING-FILE`
     for a `DRAFT-*.md` reference in the ledger directories and the SOUP file
     that names no existing file. Links left dangling by earlier merges go
     red at the first run; fix each by writing the name the file has now.
     Plans and verification records are not scanned."
   - New section after it, `## Ledger files are named at creation`, with four
     bullets:
     1. A change creates `docs/<area>/<YYYY-MM-DD>-<slug>.md`, dated the day
        it creates the file, and nothing renames it. `finalize-docs.sh` and
        the finalize step of `merge-change` are gone. Delete
        `.guardrails/scripts/finalize-docs.sh` (copying in the new scripts
        leaves it behind), and update any CI line that calls it.
     2. `check-ids.sh` rejects `--allow-draft-files` with exit 2, as it
        rejects `--allow-drafts`. Remove the flag from CI lines and
        `verify_commands`.
     3. `DRAFT-FILE` still fails a draft-named file, now at every run. For a
        change begun before the upgrade:
        `git mv <dir>/DRAFT-<branch>-<slug>.md <dir>/<YYYY-MM-DD>-<slug>.md`,
        dated the day the change created it
        (`git log --diff-filter=A --format=%ad --date=short -- <file>`).
        Then write the new name wherever a ledger cites it: `DANGLING-FILE`
        names each such reference.
     4. Two changes that pick one name meet as an add/add conflict at
        `merge-change` step 1; give this change's file a new slug.
4. Run `tests/run-tests.sh tests/skills.bats`: all pass. Commit.

**Done** (8fe848f).
red -> green: `skills.bats: ratchet: the upgrade notes say ledger files are named at creation, and how to rename a draft in flight` — red: no section.

### T6 — delete `finalize-docs.sh`

**Files touched:** `scripts/finalize-docs.sh` (deleted),
`tests/finalize-docs.bats` (deleted), `scripts/lib.sh`,
`scripts/prune-plans.sh`, `tests/check-ids.bats`, `tests/portability.bats`,
`tests/mutations.bats`, `tests/skills.bats`, `tests/lib.bats` (its script
count, missed by T6 and fixed in review round 1),
`docs/verification/2026-08-22-id-tokens.mutations/M37.sh`,
`docs/verification/2026-08-22-id-tokens.mutations/M38.sh`,
`docs/verification/2026-08-22-id-tokens.mutations/M39.sh`,
`docs/verification/2026-08-22-id-tokens.mutations/M40.sh`,
`docs/verification/2026-08-22-id-tokens.mutations/M41.sh`,
`docs/verification/2026-08-22-id-tokens.mutations/M53.sh`,
`docs/problems/2026-09-15-field-report-two.md`,
`docs/problems/2026-09-29-id-allocation-claim.md`
**Parallel:** no (serial, after T2, T3 and T5. T2 shares `tests/check-ids.bats`,
`tests/portability.bats` and `tests/mutations.bats`. T5 is the last task on
`tests/skills.bats`. T3 removes the last `finalize-docs` mention from
`check-trace.sh`, which this task's test requires.)

1. RED: in `tests/skills.bats`, extend `ledger files: the skills and
   templates name a ledger file at creation, and nothing renames it`:
   - Its `verifies:` line gains D2.
   - Append:

     *(Code pruned at merge: 3 lines. Files touched: `scripts/finalize-docs.sh` (deleted), `tests/finalize-docs.bats` (deleted), `scripts/lib.sh`, `scripts/prune-plans.sh`, `tests/check-ids.bats`, `tests/portability.bats`, `tests/mutations.bats`, `tests/skills.bats`, `docs/verification/2026-08-22-id-tokens.mutations/M37.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M38.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M39.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M40.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M41.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M53.sh`, `docs/problems/2026-09-15-field-report-two.md`, `docs/problems/2026-09-29-id-allocation-claim.md`.)*

   - In `tests/mutations.bats`, the pin goes from 18 to 24.

   Watch both fail.
2. GREEN:
   - `git rm scripts/finalize-docs.sh tests/finalize-docs.bats`.
   - `tests/check-ids.bats`:
     - In `every gr_def_re call site is still a call site, and no copy joins
       them`, delete the eight `*_finalize_docs=0` pins.
     - In `check-ids: a stock install does not report its own tooling`,
       delete the `finalize-docs.sh --dry-run` run and its two assertions.
   - `tests/portability.bats`, the awk sweep:
     - Delete the `finalize-docs.sh|--dry-run` line.
     - The expected count goes from 6 to 5, in both the check and its
       message.
     - The `Covered:` comment drops `finalize-docs.sh`.
     - The fixture comment's "and finalize-docs must not actually rename it
       out from under the sweep" is dropped.
   - `scripts/lib.sh` line 4: "sourced by the check/finalize scripts"
     becomes "sourced by the scripts in this directory".
   - `scripts/prune-plans.sh`:
     - Lines 70–73 read: "Why merge-change step 1: pruning changes the tree
       on nearly every merge. Run after the step 2 gate, it would fail step
       3's tree-hash check and dispatch a second full suite run. Run after
       the base merge, the step 2 gate measures the pruned tree."
     - Line 80's "(finalize-docs.sh gives the dash `cd ""` reason)" becomes
       "(under dash, `cd ""` returns 0 and stays put)".
   - Retire M37, M38, M39, M40, M41 and M53. Insert after each `# describes:`
     line:

     *(Code pruned at merge: 3 lines. Files touched: `scripts/finalize-docs.sh` (deleted), `tests/finalize-docs.bats` (deleted), `scripts/lib.sh`, `scripts/prune-plans.sh`, `tests/check-ids.bats`, `tests/portability.bats`, `tests/mutations.bats`, `tests/skills.bats`, `docs/verification/2026-08-22-id-tokens.mutations/M37.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M38.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M39.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M40.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M41.sh`, `docs/verification/2026-08-22-id-tokens.mutations/M53.sh`, `docs/problems/2026-09-15-field-report-two.md`, `docs/problems/2026-09-29-id-allocation-claim.md`.)*

   - `docs/problems/2026-09-15-field-report-two.md`:
     - `PR-umtm9b`: `status: open` becomes `status: resolved`, followed by:
       "Resolved: `finalize-docs.sh` is deleted and nothing renames a ledger
       file at merge (ADR-cy7ahd), so no change can adopt another's file. The
       behavior is removed, not repaired, so no test reproduces it; what
       meets a leftover draft name now is `DRAFT-FILE`, whose fix line is the
       `git mv`, pinned by `check-ids: the DRAFT-FILE fix line is the git mv
       to a dated name` in `tests/remedies.bats`."
     - `PR-8ucezf` stays open and gains a closing paragraph: "Amended
       2026-10-13 by ledger-names-at-creation (ADR-cy7ahd). The script that
       adopted every draft before step 4 could convict it is deleted, and
       nothing creates a draft name any more, so a leftover draft name
       reaches the base only through a change that skips the gate. The
       verdict still reads the whole tree and names no change. The
       discriminator this item wants is still presence on the base branch:
       a file this branch adds, `git diff --diff-filter=A <base>...HEAD`."
     - Neither text names a draft file by a token matching
       `DRAFT-[A-Za-z0-9_.-]+\.md`.
   - `docs/problems/2026-09-29-id-allocation-claim.md`, under `PR-2jr4pj`'s
     body: "2026-10-13: `scripts/finalize-docs.sh` was deleted by
     ledger-names-at-creation (ADR-cy7ahd); its header is no longer a site."
3. Run `tests/mutate.sh`. Expected: `mutations: 190 applied, 24 retired, 0
   unusable`. Then run `tests/run-tests.sh` on `skills.bats`,
   `check-ids.bats`, `portability.bats`, `mutations.bats` and
   `prune-plans.bats`: all pass. Then confirm nothing outside history names
   the script:
   `git grep -n 'finalize-docs' -- . ':!docs/plans' ':!docs/verification' ':!docs/problems' ':!docs/adr' ':!skills/ratchet' ':!tests'`
   prints nothing. Under `tests/`, only the T4/T6 test's own patterns and
   history comments name it: `git grep -n 'finalize-docs' -- tests` lists
   no `run` of the script. Commit.

**Done** (aaae741).
red -> green: `skills.bats: ledger files: the skills and templates name a ledger file at creation, and nothing renames it` (its D2 assertions) — red: `finalize-docs.sh still ships`.
red -> green: `mutations.bats: mutations: the retirement count is pinned, so one more is a visible edit` — red: `the corpus declares 18 retired mutations, expected 24`.
`tests/mutate.sh` over the corpus: `190 applied, 24 retired, 0 unusable`.

### T7 — an age is counted from one pinned day

**Files touched:** `tests/helpers.bash`, `tests/check-trace.bats`,
`docs/problems/2026-10-13-age-tests-cross-midnight.md`
**Parallel:** yes (with T1–T6: no other task touches these files)

1. Record the problem first (`resolve-problem`). Create
   `docs/problems/2026-10-13-age-tests-cross-midnight.md`. Under D1 it takes
   the day it is created. If T7 runs on a later day, use that day's date in
   the name, and give the path in the Done note. Contents:

   *(Code pruned at merge: 10 lines. Files touched: `tests/helpers.bash`, `tests/check-trace.bats`, `docs/problems/2026-10-13-age-tests-cross-midnight.md`.)*

2. RED: in `tests/check-trace.bats`, before `check-trace: trailing
   whitespace on a field is not part of its value`, add:

   *(Code pruned at merge: 14 lines. Files touched: `tests/helpers.bash`, `tests/check-trace.bats`, `docs/problems/2026-10-13-age-tests-cross-midnight.md`.)*

   Run `tests/run-tests.sh tests/check-trace.bats`. It fails:
   `pin_today: command not found`.
3. Add `pin_today` to `tests/helpers.bash`, after `days_ago`, with the stub
   only. `days_ago` is not yet changed:

   *(Code pruned at merge: 21 lines. Files touched: `tests/helpers.bash`, `tests/check-trace.bats`, `docs/problems/2026-10-13-age-tests-cross-midnight.md`.)*

   Run again. It fails for the reason the item states: `days_ago 1:` prints
   the real yesterday, because `days_ago` still counts from the clock. This
   is the reproduction.
4. GREEN: `days_ago` counts from the pinned day when there is one:

   *(Code pruned at merge: 18 lines. Files touched: `tests/helpers.bash`, `tests/check-trace.bats`, `docs/problems/2026-10-13-age-tests-cross-midnight.md`.)*

   The comment above `days_ago` gains: "With a pinned day (pin_today) it
   counts back from that day: GNU `-d "<day> N days ago"`, BSD
   `-j -f %Y-%m-%d -v±Nd <day>`." Checked on BSD date 2026-10-13:
   `date -j -v-4d -f %Y-%m-%d 2026-10-13 +%Y-%m-%d` prints `2026-10-09`.
   The new test passes.
5. GREEN: `setup()` in `tests/check-trace.bats` calls `pin_today` as its
   first line, so every test in the file reads one day.
6. Run `tests/run-tests.sh tests/check-trace.bats` and
   `tests/run-tests.sh tests/portability.bats`: all pass. The
   `days_ago produces a date in the future as well as one in the past` test
   runs without a pin, so the unpinned path is still measured under the BSD
   stub.
7. In the problem file, set `status: resolved` and add: "Resolved: the
   fixture and the script read the clock separately. `pin_today` in
   `tests/helpers.bash` puts a `date` stub on PATH and `days_ago` counts from
   the same pinned day; `tests/check-trace.bats` pins in `setup()`, and
   "check-trace: an age is counted from the pinned day on both sides"
   reproduces the split." Commit.

**Done** (f4aafe9). The problem file is `docs/problems/2026-10-13-age-tests-cross-midnight.md`.
red -> green: `check-trace.bats: check-trace: an age is counted from the pinned day on both sides` — red: `pin_today: command not found`, then `days_ago 1: 2026-10-12` with the stub only.
A `date` stub that changes day after its first call reproduced the flake before the fix (`UNRESOLVED-PR PR-001 (open 5 days)` for an item four days back) and passed under `pin_today`; it was a scratch file, not committed.

## Guideline reviews

`guidelines-file.sh TEST` names `docs/TEST_GUIDELINES.md` for every test path
in this change, and since `main`'s fdc58a6 `guidelines-file.sh CODE` names
`docs/CODE_GUIDELINES.md` for its code paths. A `review-conformance` subagent
(named `review-guidelines` before fdc58a6) reviews the change against each
file, as `develop-change` states. Its findings
and dispositions are written here as each round arrives. Clauses expected to
apply:

- Seams 1: every new test runs a script's command line or a skill's text,
  except the add/add fixture, which runs git as step 1 does.
- Doubles 2: the `date` stub is a boundary fake for the clock.
- Existing suites 1: tests edited in place stay at their seam.

### docs/TEST_GUIDELINES.md

Governs: tests/

One review over every task's test paths, after the tasks merged (range
`main...HEAD` at f855333), not one per task.

### Round 1

**finding-1**: guideline, medium — Doubles 3, "Every fake has a contract test" — tests/helpers.bash:262
`pin_today`'s `date` stub answers `date +%Y-%m-%d` with a fixed day, which `scripts/check-trace.sh` reads and validates; no assertion ran against both the stub and the real `date`.
disposition: fixed in ae33874 — tests/portability.bats runs one shared
assertion against each: "pinned date stub: answers today as one YYYY-MM-DD
line check-trace accepts" and "pinned date contract: the real date answers
today the same way".

**finding-2**: guideline, medium — Seams 1 and the floor's "every test carries `verifies:`" — tests/check-ids.bats:109, 397, 456
Three existing tests the change edits carry no `verifies:` line.
disposition: fixed in 3cf57aa — tests/check-ids.bats now cites AC5
(docs/plans/2026-08-19-id-consistency.md), PR-xyu6en and AC9
(docs/plans/2026-08-20-scan-pathspec.md) on the three tests.

**finding-3**: guideline, low — Existing suites 1, a test that breaks the rules moves to the seam — tests/check-ids.bats:109
"every gr_def_re call site is still a call site" greps script source rather than running a command line, and is repaired in place.
disposition: no change — a structural rule over the scripts' source has no
command-line seam to move to, and the edit is the count the deletion requires;
docs/plans/2026-10-08-check-review-cite.md gave the same test the same ruling.

red -> green: `portability.bats: pinned date stub: answers today as one YYYY-MM-DD line check-trace accepts` — red with the stub printing `%s 00:00`: `not YYYY-MM-DD: 2026-03-01 00:00`.
red -> green: `portability.bats: days_ago counts back from a pinned day whose local midnight does not exist` — red before the noon anchor: `no usable date(1) for relative dates`.
red -> green: `portability.bats: days_ago counts back from a pinned day whose local midnight does not exist`, extended to counts -1 and -2 — red with the time after the day: `gnu date: days_ago 1, -1, -2 = '2026-09-05 2026-09-05 2026-09-05'`.

### Round 2

Range `main...HEAD` at 174c1cc, after `main`'s fdc58a6 merged in.

**finding-1**: guideline, medium — Seams 1 with Existing suites 1 — tests/lib.bats:725
"every script stops outside a git repository, at gr_root", whose script count this change edits, has no `verifies:` line.
disposition: fixed in 1f18d23 — tests/lib.bats cites the fail-closed gr_root
guard in docs/verification/2026-08-27-config-schema.md, the only surviving
statement of that behavior (its plan was pruned).

**finding-2**: guideline, low — Existing suites 1 — tests/check-ids.bats:109
The source-scanning call-site test is repaired in place, not moved to the seam.
disposition: no change — round 1's finding-3 ruling stands: a structural rule
over the scripts' source has no command-line seam (tests/check-ids.bats).

The review also noted that the real-date contract test in
tests/portability.bats read the clock twice and asserted `open 0 days`, so a
run crossing midnight would fail it. Fixed in 1f18d23: a third read after the
run accepts `open 1 days` only when the day changed.

red -> green: `check-ids.bats: check-ids: a file listing that fails is an error, not a tree with no draft-named ledger file` — red: `failed listing read as a clean tree: 0`.
red -> green: `portability.bats: pinned date contract: the real date answers today the same way` (midnight tolerance) — red under a stub that changes day after its first call: `UNRESOLVED-PR PR-001 (open 1 days)`.

### docs/CODE_GUIDELINES.md

Governs: scripts/ tests/ (the code paths `guidelines-file.sh CODE` names).

### Round 1

Range `main...HEAD` at 174c1cc. Every finding is low; each is fixed in
fb2c2e7 unless its disposition says otherwise.

**finding-1**: guideline, low — Errors 2 — scripts/check-ids.sh:137
A failing `git ls-files` was discarded by `2>/dev/null` and `|| true`.
disposition: fixed in fb2c2e7 — scripts/check-ids.sh exits 2 naming the git
failure; the test is "check-ids: a file listing that fails is an error, not a
tree with no draft-named ledger file" in tests/check-ids.bats.

**finding-2**: guideline, low — Errors 2 — tests/skills.bats:1328, 1354
`|| true` after grep absorbed exit 2 as well as no-match.
disposition: fixed in fb2c2e7 — tests/skills.bats keeps grep's status and
passes only 0 or 1.

**finding-3**: guideline, low — Errors 1 — tests/helpers.bash:280
`pin_today` failed with a bare `return 1`.
disposition: fixed in fb2c2e7 — tests/helpers.bash prints what failed.

**finding-4**: guideline, low — Names 2 — tests/helpers.bash:253
An `&&` chain stood in for an `if`.
disposition: fixed in fb2c2e7 — tests/helpers.bash uses `if`.

**finding-5**: guideline, low — Comments 2 — scripts/check-ids.sh:10
The DRAFT-FILE header narrated the change.
disposition: fixed in fb2c2e7 — scripts/check-ids.sh states the rule.

**finding-6**: guideline, low — Comments 2 — scripts/check-trace.sh:1370
disposition: fixed in fb2c2e7 — scripts/check-trace.sh.

**finding-7**: guideline, low — Comments 2 — tests/merge-preflight.bats:247
disposition: fixed in fb2c2e7 — tests/merge-preflight.bats.

**finding-8**: guideline, low — Comments 2 — tests/remedies.bats:160
disposition: fixed in fb2c2e7 — tests/remedies.bats.

**finding-9**: guideline, low — Comments 2 — tests/check-ids.bats:460, 621, 625
disposition: fixed in fb2c2e7 — tests/check-ids.bats.

**finding-10**: guideline, low — Comments 2 — tests/skills.bats:1447
disposition: fixed in fb2c2e7 — tests/skills.bats.

**finding-11**: guideline, low — Names 4 — scripts/check-trace.sh:261
One concept had three names.
disposition: fixed in fb2c2e7 — scripts/check-ids.sh and scripts/check-trace.sh
say "draft-named ledger file"; tests/remedies.bats pins the remedy.

Generic name `result` in tests/portability.bats, raised by review round 3:
renamed `counted_days` in 1f18d23.

### docs/TEST_GUIDELINES.md, round 3

Range `174c1cc..9e45db5`. Nothing above low; the review converged.

**finding-1**: guideline, low — Seams 1 — tests/check-ids.bats:50
"check-ids: a file listing that fails is an error, not a tree with no draft-named ledger file" cites D3, which did not state the fail-closed scan.
disposition: fixed — D3 in docs/plans/2026-10-13-ledger-names-at-creation.md
now states that a failing `git ls-files` or grep exits 2.

**finding-2**: guideline, low — Seams 1 — tests/remedies.bats:263
D4 quoted the remedy as "a draft file", while the test pins "a draft-named ledger file".
disposition: fixed — D4 in docs/plans/2026-10-13-ledger-names-at-creation.md
quotes the remedy scripts/check-trace.sh prints.

**finding-3**: guideline, low — Seams 1 — tests/lib.bats:727
The `verifies:` line cites a verification record, not a problem report or plan decision.
disposition: no change — no problem item or surviving plan decision states the
fail-closed gr_root guard; docs/verification/2026-08-27-config-schema.md is the
only statement of it, and the round-4 independent review accepted the citation.

## After the tasks

- Run `develop-change`'s conformance reviews as `main` states them.
- Dispatch `verify-before-merge`: `tests/run-tests.sh` and `tests/mutate.sh`.
  Read the pass and fail counts, not the exit status.
- Then `merge-change`, from this change's own `SKILL.md`. It has no finalize
  step, and this change's one new ledger file (T7's) is already dated.
- The record states "base merged from local `main` at `<commit>`, per
  AGENTS.md non-negotiable 4". Its Gaps state:
  - `PR-8ucezf` stays open (D3);
  - a target project's in-flight drafts are renamed by hand (D7);
  - the installed skill copies under `~/.agents/skills/` are the user's to
    refresh (D2).
