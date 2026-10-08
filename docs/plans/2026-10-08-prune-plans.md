# Phase 4: plans are pruned at merge

**Roadmap:** `docs/plans/2026-10-06-salvage-churn-and-parallel.md`, phase 4
(D11).
**Resolves, opens:** no problem items. Each test cites the decision it
verifies, `verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)`.
**Records:** `ADR-bh4xgr` (minted for T2).
**Base:** `main` at `646fa1f`. Baseline: phase 3's gate, 1109 of 1109 on tree
`6889ca3`; `main` differs from that tree only by
`docs/verification/2026-10-08-record-narrates-once.md`.

## One deviation from D11, ruled 2026-10-08

D11 says `finalize-docs.sh` prunes the plan. `finalize-docs.sh` runs at
`merge-change` step 3, after the step 2 gate, and pruning changes the tree on
nearly every merge, so step 6's tree-hash rule would dispatch a second full
suite run each time. The maintainer ruled: pruning is its own script,
`scripts/prune-plans.sh`, run at the end of `merge-change` step 1, after the
base merge, so the step 2 gate measures the pruned tree. `finalize-docs.sh` is
unchanged. The script needs no `.guardrails/config.yaml`, so this repository,
which has none, runs it as an adopter does. `ADR-bh4xgr` records the decision
and this deviation.

## The behavior

`scripts/prune-plans.sh [--dry-run] [--all] [--base <ref>]`, POSIX sh, from anywhere in the
repository (it changes to `gr_root`).

- **Which plans.** By default, the `docs/plans/*.md` files this change adds or
  modifies: `git diff --name-only --no-renames --diff-filter=AM <merge-base
  of BASE and HEAD>` limited to `docs/plans/` (a renamed plan counts as
  added; review round 2, finding 3), where BASE is `--base <ref>`, else
  `gr_base_branch`. `merge-change` step 1 passes the ref it merged,
  `origin/<base>` where a remote exists, since local `<base>` may lag it
  (review round 1, finding 5). That covers committed and uncommitted tracked
  edits. `--all` takes every
  `docs/plans/*.md` instead; it is for pruning the plans already on a base
  branch. The plans directory is `docs/plans/`, as `plan-change` and
  AGENTS.md name it; there is no key for it.
- **The key.** `prune_plans` in `.guardrails/config.yaml`, a scalar, `on` or
  `off`. Absent, or no config file at all, means `on`. `off` prints
  `prune_plans: off, nothing pruned` and exits 0. Any other value exits 2
  naming the key and the value: a key the reader cannot parse must not
  disable what it configures. The key is read with `cfg_get`, without
  `gr_check_config`, so a project without a config file runs it.
- **A task section** starts at a heading line, outside any fence, matching
  `^#{1,6} (T[0-9]+|Task [A-Z]?[0-9]+)`, and ends at the next heading,
  outside any fence, of the same or a higher level (fewer or equal `#`).
  Lower-level headings inside it (`### 1.1 Failing tests`) stay in the
  section.
- **A fence** opens on a line of up to any indentation followed by three or
  more backticks or three or more tildes (two, as in ``` ``x`` ```, is inline
  code), and closes on a line of that
  character, at least as long, with nothing after it but spaces and tabs.
  Lines inside a fence are never headings and never open another fence:
  `~~~~markdown` blocks in `2026-09-28-agent-first-skills-change-1.md` hold
  nested backtick fences and `## Steps` lines.
- **What is pruned.** Each fence inside a task section, opening line through
  closing line, is replaced by one line, at the opening line's indentation:
  `*(Code pruned at merge: <N> lines. Files touched: <value>.)*`, where `<N>`
  counts the lines between the fence markers and `<value>` is the task's
  `**Files touched:**` value (the text after the colon, trimmed), or
  `*(Code pruned at merge: <N> lines.)*` where the task has none. The pointer
  quotes the value and does not call the fence merged code, since a fence may
  hold a reproduction command (review round 2, finding 5). A wrapped value runs on over the following lines and ends at a blank
  line, a heading, a fence, or a line that opens, after optional indentation,
  with a bold label (`**Parallel:**`, `**Trace**:`): plans write the next
  field on the next line with no blank line between. A count of one is
  singular, in the pointer (`1 line`) and in the output (`1 block, 1 line`).
- **What is kept.** Every heading, every line outside a fence, every fence
  outside a task section, and a fence with a line that opens with
  `red -> green`, after optional indentation, a `-`, `*` or `+` list marker
  and `**`: `merge-change` step 6b copies those attestations from the plan
  into the record after the review. The line may come anywhere in the fence,
  since `develop-change`'s dispatch report opens with `task:` (review round 2,
  finding 1). A fence that names `red -> green` only mid-line is pruned:
  review round 1, finding 4, narrowed the rule from "any line contains", which
  kept a 390-line `SKILL.md` draft in
  `2026-09-28-agent-first-skills-change-1.md`.
- **A cited plan is left whole.** Before pruning a plan, scan every tracked
  `*.md` in the repository (`git grep`), records, other plans and the plan
  itself alike, for the plan's basename followed by `:<digits>` or
  `` line <digits>`` (a closing backtick may come between). A basename after
  `/` counts only under a `plans/` directory, since a record often shares its
  plan's basename. If any cited line number is at or after the plan's first
  pruned fence's opening line, leave the plan whole and print
  `left whole <plan>: cited at <file>:<line> as <basename>:<N>` (or
  `<basename> line <N>`), once per plan, for the first such citation. A
  citation before the first pruned fence stays true after pruning. A range
  `<basename>:<A>-<B>` counts by its end line `<B>` (review round 3,
  finding 4). Review
  round 1, finding 2, widened this from the verification directory: plans cite
  plans (`2026-09-16-scan-scope.md` cites `2026-09-04-units-implementation.md`
  by line). A citation counts only if its citing line is still there after
  the run: one inside a fence the run prunes is ignored. Every plan in the run
  starts as a prune; a plan named by a counted citation is left whole, which
  keeps its fences and so makes the citations in them count; this repeats
  until nothing changes, before any plan is rewritten (review round 2,
  finding 2: a citation inside a fence pruned later in the same run had left
  its plan whole on run 1 and pruned on run 2).
- **Output.** `pruned <plan>: <K> blocks, <L> lines` per plan changed
  (`would prune` under `--dry-run`, which writes nothing). A plan with nothing
  to prune prints nothing. Idempotent: a second run prunes nothing, since a
  pointer line is not a fence, and repeats only its `left whole` lines.
- **Writes.** Rewrites each pruned file in place through a temporary file in
  the same directory; it does not stage or commit. Exit 0 on success, 2 on a
  usage or environment error.
- **awk.** Every value passed to awk goes through ENVIRON or `-v` without a
  newline (AGENTS.md); runs on BWK awk.

## Tasks

| Task | Files touched | Depends on |
|---|---|---|
| T1 — `prune-plans.sh` and the `prune_plans` key | `scripts/prune-plans.sh`, `scripts/lib.sh`, `templates/config.yaml`, `tests/prune-plans.bats` | — |
| T2 — the skills, the ADR and the upgrade note | `skills/merge-change/SKILL.md`, `skills/merge-change/references/review-checklist.md`, `skills/merge-change/references/rationale.md`, `skills/plan-change/SKILL.md`, `skills/ratchet/references/upgrade-notes.md`, `docs/adr/ADR-bh4xgr-plans-are-pruned-at-merge.md`, `templates/AGENTS-block.md`, `tests/skills.bats` | T1 |
| T3 — prune the plans already on `main` | `docs/plans/*.md` (the files the script changes) | T1, T2 |

### T1 — `prune-plans.sh` and the `prune_plans` key

**Done** (`937db94`). red -> green: all 20 tests in `tests/prune-plans.bats`
failed with the script absent (exit 127); 20 of 20 pass, with
`tests/portability.bats`, `tests/lib.bats` and `tests/check-ids.bats` 189 of
189. Deviations: a wrapped `**Files touched:**` value is read to the end of its
paragraph; an unclosed fence is kept; the script-count pins in `tests/lib.bats`
and `tests/check-ids.bats` moved and `README.md`'s script table gained a row,
because a script was added; default mode in a detached primary checkout exits 2
and names `--all`. Dry run with `--all`: 29 plans, 334 blocks, 6,600 lines;
two left whole (`2026-09-29-agent-first-skills-change-2.md`,
`2026-10-04-adr-ids.md`).

**Files touched:** `scripts/prune-plans.sh`, `scripts/lib.sh`,
`templates/config.yaml`, `tests/prune-plans.bats`

1. Write `tests/prune-plans.bats`, using `tests/helpers.bash`
   (`make_fixture_repo`, `commit_all`, `output_has`, `output_lacks`). Each
   test carries `# verifies: D11 (docs/plans/2026-10-06-salvage-churn-and-parallel.md)`.
   Fixture: a repository on `main` with a plan committed, then a branch
   `feature` that adds or edits `docs/plans/2026-01-01-x.md`. Tests:
   - a backtick fence in a `### T1 —` section is replaced by the pointer line
     naming its line count and the task's `**Files touched:**` value; the
     heading and the prose around it are byte-identical;
   - a fence indented 3 spaces inside a numbered step keeps its indentation on
     the pointer line;
   - a task without `**Files touched:**` gets `this change's squash commit`
     (superseded by review round 2, finding 5: the pointer names only the
     count);
   - `## Task 2 —` and `### Task L1:` sections are pruned; a `### T10`
     section is a task, `### Tests` is not;
   - a fence outside any task section (a `## Design` section) is kept;
   - a fence containing `red -> green` inside a task section is kept;
   - a `~~~~markdown` fence holding a nested backtick fence and a `## Steps`
     line is pruned as one block, and the section does not end at its
     `## Steps` line;
   - a task section ends at the next heading of the same level, so a fence
     under a following `## Notes` (same level as `## Task 1`) is kept;
   - by default only plans the branch adds or modifies are pruned; a plan
     only on `main` is untouched; `--all` prunes it too;
   - `--dry-run` prints `would prune` and leaves every file unchanged;
   - a second run prints nothing and changes nothing (superseded, see review
     round 3: a second run changes nothing and repeats its `left whole`
     lines);
   - a record in `docs/verification/` citing `2026-01-01-x.md:<N>` at or after
     the first pruned fence leaves the plan whole and prints `left whole`
     with the record path and line; a citation before the first fence does
     not;
   - with `doc_verification` set in the config, records are read there;
   - `prune_plans: off` prints `prune_plans: off, nothing pruned`, changes
     nothing, exits 0; `prune_plans: maybe` exits 2 naming the key and value;
     no config file at all prunes;
   - an unknown argument exits 2.
   Run `tests/run-tests.sh tests/prune-plans.bats`; watch each fail.
2. Add `prune_plans` to `GR_KNOWN_KEYS` in `scripts/lib.sh` (a scalar), and to
   `templates/config.yaml` as `prune_plans: on`, with a comment saying what
   it prunes, when (`merge-change` step 1), what is kept, that `off` opts out
   and that the merged code stays in the squash commit. Run
   `tests/run-tests.sh tests/lib.bats` (the template-names-only-known-keys
   tests).
3. Write `scripts/prune-plans.sh` to the behavior above, with a header comment
   in the style of `scripts/finalize-docs.sh` (usage, what it prints, exit
   codes, why it runs at step 1). Run `tests/run-tests.sh
   tests/prune-plans.bats tests/portability.bats tests/lib.bats`: green.

### T2 — the skills, the ADR and the upgrade note

**Done** (`8f75cab`). red -> green: the five new `tests/skills.bats` tests each
failed on the unedited text (no `prune-plans.sh` line in step 1, no pointer
check, no pruning paragraph in `plan-change`, no `prune_plans` upgrade
section, no `ADR-bh4xgr` file); `tests/skills.bats` 115 of 115.
`merge-change` `SKILL.md` is at 1995 words. Deviations: step 1 stages with
`git add -u`, because `git add -A docs/plans` exits 128 in a project with no
`docs/plans`; the rationale names the step 3 draft renames, not the script,
because the rationale may describe no script. Room was made by cutting two
pre-flight descriptions its header already gives, and moving the ways to make
a fix tag unique and step 7's `Resolves:` reason into the rationale.

**Files touched:** `skills/merge-change/SKILL.md`,
`skills/merge-change/references/review-checklist.md`,
`skills/merge-change/references/rationale.md`, `skills/plan-change/SKILL.md`,
`skills/ratchet/references/upgrade-notes.md`,
`docs/adr/ADR-bh4xgr-plans-are-pruned-at-merge.md`,
`templates/AGENTS-block.md`, `tests/skills.bats`

`templates/AGENTS-block.md` lists the scripts beside `finalize-docs.sh`; it
gains a `prune-plans.sh [--dry-run] [--all]` line.

1. Add tests to `tests/skills.bats`, each with the `verifies: D11` comment,
   and watch them fail:
   - `merge-change` step 1 runs `.guardrails/scripts/prune-plans.sh` after
     `git merge`, and commits what it changed;
   - `review-checklist.md` tells the reviewer to check the pruned plan's
     pointers and prose against the diff;
   - `plan-change`'s `SKILL.md` says code in task steps is pruned at merge and
     that `red -> green` fences are kept;
   - `upgrade-notes.md` names `prune_plans`, its default `on` and `off`;
   - `ADR-bh4xgr` exists, is `Status: accepted`, and names `prune-plans.sh`
     and `merge-change` step 1.
2. `merge-change` step 1: after the base merge, run
   `sh .guardrails/scripts/prune-plans.sh`, read its `left whole` lines, and
   commit what it changed (`git add -A docs/plans` then the conditional
   unsigned commit, `chore: prune plans`). `SKILL.md` is at 1994 words and
   must stay at or under 2,000: move existing explanation into
   `references/rationale.md` to make room, losing no rule, and say in the
   rationale why pruning runs at step 1 and not with `finalize-docs.sh`.
3. `review-checklist.md`: a checklist line: each pointer stands where the
   task's code was, the prose of each task matches the diff, and a plan left
   whole is listed in the record.
4. `plan-change` `SKILL.md`: one short paragraph: fenced code inside task
   sections is replaced by a pointer at merge (`prune-plans.sh`, `merge-change`
   step 1); the merged code is in the squash commit, so the prose carries each
   step's intent and each deviation's reason belongs in the record; fences
   containing `red -> green` are kept.
5. `upgrade-notes.md`: a section for `prune_plans`: on by default when absent,
   what it does, how to opt out, and that `prune-plans.sh --all` prunes the
   plans already merged, leaving whole those a record cites by line.
6. `docs/adr/ADR-bh4xgr-plans-are-pruned-at-merge.md`, in the form of
   `docs/adr/ADR-y8jmes-local-main-is-the-base.md`: Context (6,518 of 25,148
   plan lines in code fences on 2026-10-06; plans duplicate the merged code
   and drift from it), Decision (D11 as built, with step 1 and the
   deviation), Consequences (pre-review code exists only on the change branch
   and is lost when `finish-merge.sh` deletes it; the maintainer accepted it;
   line citations after a pruned fence would shift, so those plans stay
   whole).
7. Run `tests/run-tests.sh tests/skills.bats`: green, including the word cap.

### T3 — prune the plans already on `main`

**First run discarded.** It pulled the bold field after `**Files touched:**`
(`**Parallel:**`, `**Trace:**`) into 266 of 334 pointers, and counted one as
`1 lines`. Fixed by dispatch `pointer-fix` (`550aea4`, `0d855fa`): the value
ends at a bold label, a count of one is singular, and a value starting on the
next line has no leading space. red -> green: four new tests in
`tests/prune-plans.bats`, each red on the unfixed script; 24 of 24.

**Done** (`f1e1443`), then **redone** after review round 1, whose findings 2
and 4 changed what is kept, and again after review round 2 (`9917a78`), whose
findings 1, 2 and 5 changed what is kept, how citations are decided and the
pointer: each time the plans were restored to `646fa1f` and pruned again.
Round 2's run: 27 plans pruned, 259 blocks, 4,360 lines, the same as round
1's, since no plan at `646fa1f` holds a fence whose `red -> green` line comes
after its first line and no pruned fence cites a plan; plan lines
26,101 -> 21,482.
Left whole, each cited by line after its first fence:
`2026-09-04-units-implementation.md` (by
`docs/plans/2026-09-16-scan-scope.md:190`), `2026-09-10-field-report-fixes.md`
(by `docs/plans/2026-09-16-scan-scope.md:199`),
`2026-09-29-agent-first-skills-change-2.md` (by
`docs/verification/2026-09-30-agent-first-scripts.md:557`; since review
round 3, finding 4, first by the range at line 517 of that record) and
`2026-10-04-adr-ids.md` (by `docs/verification/2026-10-05-adr-ids.md:176`).
The 390-line `~~~~markdown` draft in
`2026-09-28-agent-first-skills-change-1.md` T2 is now pruned; the 14
attestation fences in `2026-09-04-units-implementation.md` and
`2026-09-04-units-skills.md` are kept. Headings outside fences identical in
all 27; both citations of a pruned plan in tracked Markdown show the same line
text before and after; a second run prints only the four `left whole` lines.
In `2026-09-18-close-crcee5.md`, the pointer that replaced the reproduction
fence now reads `Files touched: none in the repository (scratch only).`

**Files touched:** the `docs/plans/*.md` files the script changes.

1. In the task worktree, run `sh scripts/prune-plans.sh --all --dry-run`, then
   `sh scripts/prune-plans.sh --all`. Report every `pruned` and `left whole`
   line, and the total lines before and after
   (`cat docs/plans/*.md | wc -l`).
2. Check that every heading outside a fence is unchanged: extract them with
   the script's own fence rule from `git show main:<plan>` and from the
   pruned file, for every changed plan, and compare. A `#` line inside a
   pruned fence is a shell comment, not a heading.
3. Run `tests/run-tests.sh tests/skills.bats tests/prune-plans.bats`: green.
4. Commit.

## Review round 1

Five findings, fixed by dispatch `fix-r1`:

1. `merge-change` step 1 chains the base merge, the prune and its commit with
   `&&`, and the commit takes only `docs/plans`: a conflicted merge had been
   concluded as `chore: prune plans` with its markers staged, and `git add -u`
   took every tracked edit. This supersedes T2's `git add -u` deviation.
2. The citation scan reads every tracked `*.md`, not the verification
   directory; T1's `doc_verification` test is replaced.
3. Four tests pin the fence-length, closing-line, unclosed-fence and
   first-`**Files touched:**` rules, each red under its mutation.
4. A fence is kept only when its first non-blank line opens with
   `red -> green`; T1's attestation fixture now opens that way.
5. `--base <ref>` names the ref the change's plans are diffed against;
   step 1 passes the ref it merged.

## Review round 2

Five findings, fixed by dispatch `fix-r2`:

1. A fence is kept when any of its lines opens with `red -> green`, after
   optional indentation, a list marker and `**`, so `develop-change`'s
   dispatch report, which opens with `task:`, survives for step 6b. A
   mention mid-line is still pruned; at `646fa1f` the rule keeps the same 14
   attestation fences and prunes the 390-line draft. This supersedes round 1's
   first-line rule.
2. A run is idempotent: every plan's fences and citations are read before
   any is rewritten, a citation inside a fence the run prunes is ignored, and
   a plan left whole keeps its fences, so their citations count; decided to a
   fixed point.
3. `git diff --no-renames`, so a plan the change renames is pruned as added.
4. Eleven tests pin the citation floor (at and after the first fence), the
   Markdown-only scan, one `left whole` line per plan, the subdirectory
   exclusion, the Files touched breaks at a heading and a fence, the trailing
   period, the `**Files touched**:` form, an indented `red -> green` line and
   the heading rule; each was red under its mutation. The dead task-heading
   digit check is removed.
5. The pointer reads `Files touched: <value>.`, or names only the count where
   the task has no such line: it no longer calls a fence merged code. This
   supersedes T1's `this change's squash commit` step.

## Review round 3

Six findings, fixed by dispatch `fix-r3`:

1. The ADR summary, `templates/AGENTS-block.md` and the `merge-change`
   rationale described the pointer as a pointer to the merged code; they now
   say it names the line count and the task's `**Files touched:**` value, as
   the script header does.
2. A test pins the three-marker minimum: a line opening with ``` ``x`` ``` is
   inline code, not a fence; red under `run < 2`.
3. Three tests pin an empty `prune_plans:` (exit 2, as the script already
   did), a Files touched value ending at an indented bold label, and a
   citation under `myplans/` or `old-plans/`; each red under its mutation.
4. A range citation counts by its end line, so `<plan>:<A>-<B>` whose `<B>`
   is at or after the first pruned fence leaves the plan whole. At the tip the
   same four plans are left whole;
   `2026-09-29-agent-first-skills-change-2.md` is now named first by the range
   at line 517 of its record. No range citation of a pruned plan ends at or
   after its first fence.
5. This plan no longer cites a pruned plan's line after its first fence, so
   restoring the 27 plans to `646fa1f` and running `--all` again prunes 27
   plans, 259 blocks, 4,360 lines, byte-identical to the tree.
6. T1's `this change's squash commit` and `a second run prints nothing` steps
   are marked superseded.

## After the base merge

`main` moved to `b4484b8` (test seams) after round 3; it edits
`skills/merge-change/references/review-checklist.md` and `tests/skills.bats`,
as this change does. Both conflicted, and each kept both sides (`8cb15f4`):
the checklist keeps this change's pruned-plan line and gains main's test
checklist; `tests/skills.bats` has the 110 tests of the merge base, the 6 of
each side, 122 in all. `docs/plans/2026-10-07-test-seams.md` came in with the
merge, and step 1's `--base main` does not take it, since this change does not
modify it; `--all` pruned it as T3 pruned the other merged plans (`33fc82d`):
14 blocks, 443 lines. That makes 28 plans pruned, and a second `--all` changes
nothing. Review round 4 reviewed the whole change again, as the shared files
require.
