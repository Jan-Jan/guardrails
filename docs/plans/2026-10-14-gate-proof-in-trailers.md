# Gate proof in trailers Implementation Plan

**Goal:** The signed squash commit certifies the tree its gate measured, in
`Gate-tree:`, `Gate:` and `Base:` trailers that `finish-merge.sh` checks, and
the verification record names no commit, tree or gate figure, so it no longer
changes the tree it certifies.
**Implements:** ADR-f6ytg7 (minted for this plan with `new-id.sh ADR`,
written by T1) and D1–D7, D9 and D11 below; guardrails keeps no REQ ledger of its
own. D8 is mutation evidence, which `tests/mutations.bats` applies through
`tests/mutate.sh` and each task's Done note records as kills; D10 is ledger
bookkeeping, checked by review. Neither has a test of its own. Each test cites
`verifies: D<n> (docs/plans/2026-10-14-gate-proof-in-trailers.md)`, or a PR
ID.
**Resolves:** PR-k4y59t and PR-nyw3ww, both minted for this plan with
`new-id.sh PR`. T2 opens and resolves PR-nyw3ww; T3 opens PR-k4y59t and T5
resolves it.
**Safety class:** not configured in this repository; worked as class B (normal
and abnormal cases for each changed gate)
**Verification:** `tests/run-tests.sh`, every test passing. Its
`tests/mutations.bats` runs `tests/mutate.sh` over the whole corpus, this
change's seven new mutations included.
**Base:** local `main` at `93ff657`, per AGENTS.md non-negotiable 4.

This repository has no `.guardrails/config.yaml`, so the IDs were minted with
`GR_CONFIG=templates/config.yaml sh scripts/new-id.sh ADR` and `… PR` (twice):
that config declares both prefixes, and `new-id.sh` still checks this tree for
a collision. `git grep` over every local branch and worktree found neither
token.

The user ruled on 2026-10-14: the verification record must stop certifying a
commit it is itself part of, and local signed squash merges stay (the user
signs locally before pushing to open a PR). Today the record
(`templates/verification.md`) names "Branched from `<base>` at `<commit>`",
"Measured on: `<commit>` … tree `<tree hash>`", the gate's totals and, in this
repository, "base merged from local `main` at `<commit>`". Every base update,
and every rebase after a shared remote moves, makes those lines stale. The
record is then rewritten and committed again, which changes the tree it names:
a loop, and a late commit on the review evidence. The design moves everything
measured from the tree into the squash commit's trailers, which the commit can
carry without changing its tree, and has `finish-merge.sh` prove the
`Gate-tree:` value is the commit's own tree.

## Investigation

**Sites.**
`git grep -n -e 'Measured on' -e 'HEAD^{tree}' -e 'non-negotiable 4' -e 'Branched from' -e 'gate summary' -e 'totals'`
outside `docs/plans`, `docs/verification` and `.worktrees`, at `93ff657`:

- `templates/verification.md`: line 12 (`Branched from`), lines 15–43 (the
  `## The gate` section: the "Measured on" paragraph, the repository-figure
  paragraph and the five-row gate table), lines 3–5 (the header that calls
  the record "the evidence that travels with the change").
- `skills/merge-change/SKILL.md`: step 1's bullets "or record the local ref
  and commit the base was merged from" and "and the record states it too";
  step 2's tree fence (kept); step 3's comparison (kept); 6b's "the gate
  summary's totals and the tree they describe, coverage if configured, each
  check's result"; step 7's message template and "proves four things".
- `skills/merge-change/references/rationale.md`: line 76 ("A base merged from
  a local ref is recorded with its commit"), line 122 (`## Step 2: recording
  the tree`), line 360 ("No script parses the message"), and line 244 (the
  delta, kept).
- `skills/merge-change/references/multi-unit.md`: the per-unit dispatch
  bullet (steps 2 and 3); its 6b sentence (units and impact set) stays.
- `skills/verify-before-merge/SKILL.md` lines 139–141 ("Anything that record
  needs from the gate (totals, per-command results, coverage summary,
  verdict)"), and `references/rationale.md` lines 74–78 (`## The log is not
  kept`). Check 5's "record the acceptance in the verification record" stays:
  an accepted gap is a decision, not a figure.
- `AGENTS.md` line 56 (non-negotiable 4's "State it in the verification
  record"); `docs/adr/ADR-y8jmes-local-main-is-the-base.md` line 25 (the same
  sentence) and line 68 (the reconciliation permission, kept: see D3).
- `templates/AGENTS-block.md` item 2 and `README.md` rule 2 (the squash
  "is verified with `check-signing.sh`"; neither names the tree).
- `skills/develop-change` cites 6b only for the `red -> green:` lines: no
  change. `skills/merge-change/references/review-checklist.md` asks nothing
  of the gate figures: no change.
- History, not edited: `docs/adr/ADR-bh4xgr-plans-are-pruned-at-merge.md`
  ("Measured on" is prose there), `docs/problems/*` and every merged record.

**Tests that read these sites** (`tests/skills.bats` unless named):
- `verification template: the gate table names the tree the figures describe`
  (line 1309, PR-dkm5tq) asserts `Measured on:`, `rev-parse HEAD^{tree}` and
  `copied forward from an earlier round` in the template. Re-aimed by T5.
- `verification template: a repository figure does not belong in the gate
  table` (line 1256, PR-hkc376) asserts `describes the repository rather than
  this change`; the phrase stays, the name changes (T5). Both old names
  survive only in `docs/plans/2026-09-15-field-report-two.md`,
  `docs/verification/2026-09-15-field-report-two.md` and
  `docs/problems/2026-09-15-field-report-two.md`, which are history.
- `merge-change: step 8 maps guard 4's rejection to a remedy` (line 736)
  asserts `proves four things` and the absence of `proves three things`.
- `merge-change: text the first rewrite lost is stated again` (line 1863)
  asserts `No script parses the message` and `what the duplicate scan at step
  4 was compared against` in the rationale, each on one line.
- `merge-change: the commit template states the Resolves and Opens trailers`
  (line 1247): its comment says no script parses the message.
- `merge-change: step 7 checks for a staged squash before staging its own`
  (line 2068) runs the **first** `sh` fence of step 7 and requires it to be
  exactly two lines; a new fence placed after it leaves that test alone.
- `merge-change: Done when names finish-merge.sh as the verifier` (line 795)
  greps one line for ``verified by `finish-merge.sh` ``.
- `merge-change: the rationale file describes no script` (line 2206) rejects
  any `scripts/` path or `.sh` word in the rationale, so the new rationale
  text says "the cleanup", never the script's name.
- `skill shape: every SKILL.md is at most 2,000 words` (line 1724) measures
  `wc -w < SKILL.md`.
- `check-review.bats` and `merge-preflight.bats` never read
  `templates/verification.md`.

**`scripts/check-review.sh`** parses the four fields, the finding blocks and
the dispositions only. `grep -n -i -e 'Measured' -e 'Branched' -e '## The gate'`
over it prints nothing, so removing the gate section changes no verdict. It is
not edited.

**`scripts/merge-preflight.sh`** runs in the change worktree before the squash
exists. It has no message to read, and the step 2 hash lives in the
dispatcher's notes, not in a file, so it has nothing to compare. Step 3
already compares the worktree's tree with that hash, and step 7 compares the
staged tree with it. It is not edited.

**`finish-merge.sh --check`** answers guard 4 only, before the squash exists.
The new guard reads the squash message, so it joins guards 1 and 2 as a guard
`--check` cannot preflight; only the comments that count those guards change.

**`tests/finish-merge.bats`.** Every squash is written by one helper,
`make_squashed_change` (34 call sites in 38 tests): `git merge --squash`, then
`git commit -qS -m "squash my-change"` (or unsigned). Signing uses a throwaway
ssh key, `setup_ssh_signing`. The helper gains the trailer, its value
`git write-tree` after the squash, and every existing test then passes the new
guard. The guard 5 tests replace the message with `git commit --amend -S -F -`,
which keeps the tree and signs again with the same key.

**git's trailer parser, measured with git 2.55.0 in a scratch repository:**

- `git log -1 --format='%(trailers:key=Gate-tree,valueonly)'` prints one value
  per line. Two trailers print two lines; an empty `Gate-tree:` prints an empty
  line; `gate-tree:` matches too (the key is case-insensitive).
- Only the message's last paragraph is read. A `Gate-tree:` line followed by a
  blank line and `Co-Authored-By:` prints nothing. So does a block in which a
  wrapped value continues on a line that does not open with whitespace: that
  line makes the whole paragraph not a trailer block.
- This repository's own squash commits put `Co-Authored-By:` after a blank line
  (`93ff657`, `fdc58a6`), so their `Implements:` … `Verified:` lines are body
  text to git today. Nothing parsed them, so nothing noticed.
- `key=` and `valueonly` arrived in git 2.22.0
  (`RelNotes/2.22.0.adoc`: "optionally pick trailers selectively by keyword,
  show only values"). Before 2.22 the `(trailers:` option parser knew only
  `only` and `unfold`, and an unknown option leaves the placeholder
  unexpanded.
- With `log.showSignature` set to true, `git log --format=…` prints the
  verifier's output ("Good "git" signature for …") above the formatted value
  on stdout. `--no-show-signature` suppresses it.

**A latent defect found on the way.** The same `log.showSignature` breaks
`check-signing.sh`: `git log -1 --format='%G?'` (line 173) reads back two
lines, and a good signature is reported
`UNVERIFIED <sha> (signature present but did not verify)`, exit 1, in a
scratch repository signed with ssh; with the setting false it exits 0. Guard 1
of `finish-merge.sh` runs `check-signing.sh --strict`, so a guard 5 test under
`log.showSignature` cannot reach guard 5 until this is fixed. No problem item
records it (`grep -rn showSignature` over every branch is empty): PR-nyw3ww.

**Problem items.** No open item covers the record certifying its own tree. The
open items were listed from `docs/problems/*.md` (`find-items.sh` needs a
config this repository lacks). The nearest are `PR-dkm5tq` (resolved: it keyed
the gate figures to a tree, inside the record) and `PR-sc5qy5` (open: a
sentence about an unmerged branch), neither this defect. PR-k4y59t records it.

**Mutation anchors.** `grep -rln 'finish-merge' docs/verification/*.mutations/`
prints nothing: no mutation quotes `finish-merge.sh`. `check-signing.sh` is
quoted only by `2026-08-27-config-schema.mutations/M81.sh`, on the `gr_root`
and `cd` lines, which this plan does not touch. No skill, template, README or
AGENTS file is quoted by any mutation. So nothing is re-cut or retired, and
the retirement pin in `tests/mutations.bats` stays at 24. The seven new
mutations of D8, `M06` and `M07` added at review round 2, each redden the
tests named in D8:
`sh tests/mutate.sh docs/verification/2026-10-14-gate-proof-in-trailers.mutations`
prints `mutations: 7 applied, 0 retired, 0 unusable`.

**Word count.** `wc -w < skills/merge-change/SKILL.md`, the measure
`gr_skill_words` uses, is 1,933 at `93ff657`. The T4 edits, drafted in full
on a scratch copy, measure **1,991**. Two cuts pay for the additions: 6b's
list of gate figures goes (the record holds none), and 6b's parenthesis
"(never the open count or oldest age)" goes, because the template's
repository-figure paragraph, which the dispatcher fills at 6b, states the
same rule and `## Step 6b: the delta, never the total` gives its reason.
Every reason added goes to `references/rationale.md`.

**Open parallel work.** `.worktrees/derailment-conformance` (branch at
`2b53658`) edits `skills/develop-change/SKILL.md`, its
`references/rationale.md`, `docs/problems/2026-10-14-code-guidelines.md` and
`tests/skills.bats` (one test added after line 1153). None of those regions
is one this plan edits, and this plan does not touch `develop-change`.

## Decisions

- **D1: the squash commit certifies its own tree.** `merge-change` step 7's
  message ends in one trailer paragraph:

  ```
  Implements: <final REQ/RC/SDD/LLR IDs>
  Resolves: <PR IDs this change closes>
  Opens: <PR IDs this change raises>
  Plan: docs/plans/<plan file>
  Verified: docs/verification/<record file>
  Base: <base ref> at <its commit>
  Gate-tree: <step 2 tree>
  Gate: <verify_commands entry> <passed>/<total>
  ```

  - `Gate-tree:` is the hash step 2 recorded (`git rev-parse HEAD^{tree}` on a
    clean worktree, confirmed by step 3), never a tree computed at step 7: a
    tree computed at step 7 describes what is staged, which is the thing the
    check questions.
  - `Base:` is the ref step 1 merged and its commit, `git rev-parse <ref>` at
    that merge. In this repository it reads
    `Base: local main at <commit>, per AGENTS.md non-negotiable 4` (D3). It
    can differ from the squash's parent: with a fetched `origin/<base>`, the
    squash lands on local `<base>`, which may be behind it.
  - Every trailer, `Co-Authored-By:` included, is in that one last paragraph,
    with no blank line inside it, because git reads trailers nowhere else.
- **D2: which figures get a `Gate:` trailer.**
  - One per `verify_commands` entry, as the gate summary reports it:
    `Gate: tests/run-tests.sh 1400/1400`.
  - One for `coverage_command` where it is configured,
    `Gate: <coverage_command> <figure>`. Coverage is a measured figure, and the
    record's gate table, its only home, is gone. An accepted shortfall is a
    decision, not a figure, and stays in the record under Gaps.
  - In a multi-unit repository, one per unit and command:
    `Gate: <unit>: <verify_commands entry> <passed>/<total>`, under the one
    `Gate-tree:` every unit's gate measured.
  - **None for the pre-flight**, nor for `check-ids.sh`, `check-trace.sh` or
    the working-tree check that were rows of the old table. The sequence halts
    when any of them fails, so a squash exists only after they passed, and
    the ID and trace checks can be rerun on the tree `Gate-tree:` names. A
    trailer that can only ever say "pass" adds a line
    and no information.
  - No script checks a `Gate:` value: checking a total means running the gate
    again. What is checked is the tree they describe (D5).
- **D3: the base statement moves to the `Base:` trailer.** AGENTS.md
  non-negotiable 4's last paragraph reads "State it in the squash commit's
  `Base:` trailer (`merge-change` step 7):
  `Base: local main at <commit>, per AGENTS.md non-negotiable 4`."
  ADR-y8jmes's Decision sentence says the same and names ADR-f6ytg7 as the
  decision that moved it. ADR-y8jmes is amended in place: that sentence is a
  rule in force, and AGENTS.md points readers to the ADR for it; `25e723f`
  amended its Scope the same way. Not changed: the Scope's permission that an
  agent merges an already-fetched `origin/<branch>` only "as the subject of a
  change whose verification record names whose decision it was and which
  commit was merged", in the ADR and in AGENTS.md. Who decided is not
  measured from the tree, and the merged commit is the change's subject: it
  does not move when the base does.
- **D4: step 7 compares the staged tree with the step 2 tree before the
  hand-over.** After the message is written:

  ```sh
  [ "$(git write-tree)" = <step 2 tree> ]
  ```

  A mismatch means the branch changed after the gate (a record committed at
  6b, say): `git reset --merge`, then rerun from step 1, which gates again.
  It costs no key touch; guard 5 (D5) would refuse the same squash after one.
  It sits in its own fence, after the message and before the hand-over
  command, so step 7's first fence stays the two lines its test runs.
- **D5: `finish-merge.sh` guard 5.**
  - It refuses (exit 1, nothing removed, nothing deleted) unless HEAD's
    message has exactly one `Gate-tree:` trailer with a value, and that value
    equals `git rev-parse HEAD^{tree}`. Three messages: no trailer with a
    value, more than one, and a value naming another tree (both hashes
    printed).
  - It counts the trailers with
    `git log -1 --no-show-signature --format='%(trailers:key=Gate-tree,unfold)' HEAD`,
    one line per trailer, key included, so an empty value is still a line,
    and refuses unless the count is exactly one; only then does it read the
    value with
    `git log -1 --no-show-signature --format='%(trailers:key=Gate-tree,valueonly,unfold)' HEAD`.
    That is git's own parser, so a trailer counts exactly where git counts
    one, and each read is one command with no pipe whose status would be
    lost. `unfold` makes a trailer continued on a line that opens with
    whitespace one line, not two (D11).
    `git interpret-trailers --parse` would need the message piped in and a
    `grep` after it. It needs **git 2.22** or later; an older git prints the
    placeholder unexpanded, which equals no tree, so the guard fails closed.
    `--no-show-signature` keeps `log.showSignature` out of the value.
  - A failing `git log` or `git rev-parse` exits 2 (`gr_die`), naming the
    command, before anything is removed.
  - It is guard 5, numbered last because it was added last, as guard 4 was.
    It is proved after guard 2 and before the worktree list is read, so before
    any removal. The header's "Four guards" becomes "Five guards", and the two
    `--check` comments that name the guards reading the squash say "Guards 1,
    2 and 5". `merge-change` step 7 says "proves five things".
  - Its remedies go in `skills/merge-change/references/cleanup-rejections.md`:
    the signed commit stays on the base; a missing or unreadable trailer is
    fixed by correcting the message and having the user amend and sign again
    (`git commit --amend -S -F <msgfile>`, which keeps the tree); a wrong tree
    is fixed by gating the change worktree, still in place and holding HEAD's
    tree (guard 2), then amending with that tree. A red gate there means the
    base holds a failing tree, and undoing it is the user's call, as is
    amending a commit already pushed.
  - `--check` and `merge-preflight.sh` do not change (Investigation).
- **D6: the record keeps only what the commit cannot prove.** It keeps the four
  fields, the change sentence and plan, the IDs resolved, accepted or opened,
  red → green, what was wrong and what was built, the review and guideline
  reviews, and the Gaps. It names no commit or tree the gate measured, no base
  commit and no gate figure: the `Branched from` clause and the gate table go, and
  `## The gate` becomes a short statement that the figures are in the squash
  commit's trailers. With nothing in it measured from the tree, a rerun does
  not change it, so the tree the gate measured is the tree squashed.
  - To pay for that rerun once, not twice, 6a's last-round paragraph says to
    write the record before the rerun that follows the last review. The rerun's
    gate then measures the record too, its 6b changes nothing, and step 7's
    comparison passes. A change that first reaches 6b with no record (class A,
    no review) costs one extra gate run, caught by step 7's comparison.
  - `verify-before-merge`'s "Anything that record needs from the gate" becomes
    what step 7's trailers need. `templates/AGENTS-block.md` item 2 and
    `README.md` rule 2 state the trailer.
- **D7: ADR-f6ytg7 records the decision.** "The squash commit, not the record,
  certifies the gate" is an architecture decision for every adopter: it
  changes a guard of a shipped script, the record template and the merge
  sequence. It takes the shape of ADR-cy7ahd: item line on line 1,
  `Date: 2026-10-14`, `Status: accepted`, Context, Decision, Consequences,
  Alternatives considered.
- **D8: mutation evidence.** No existing anchor is affected (Investigation).
  Seven new mutations, in
  `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/`, each a
  `python3` replace that asserts one match, as `M81.sh` is written:
  - `M01` (T2): `check-signing.sh` reads `%G?` without `--no-show-signature`.
    Killed by `check-signing: a good signature passes --strict with
    log.showSignature set` and `finish-merge: guard 5 reads the trailer when
    log.showSignature is set`.
  - `M02` (T3): the more-than-one arm never matches. Killed by
    `finish-merge: two Gate-tree trailers are refused, even when both name
    HEAD's tree`.
  - `M03` (T3): the equality test becomes `[ -n "$head_tree" ]`. Killed by
    `finish-merge: a Gate-tree trailer naming another tree is refused, naming
    both trees` and `finish-merge: a record committed after the gate leaves a
    squash its Gate-tree does not name`.
  - `M04` (T3): the emptiness test becomes `[ -n "$head_tree" ]`. Killed by
    the three no-trailer tests.
  - `M05` (T3): guard 5 reads the trailer without `--no-show-signature`.
    Killed by `finish-merge: guard 5 reads the trailer when log.showSignature
    is set`.
  - `M06` (D11): guard 5 counts the trailers without `--no-show-signature`.
    Killed by `finish-merge: guard 5 reads the trailer when log.showSignature
    is set`.
  - `M07` (D11): guard 5 counts the values, `valueonly`, not the trailers.
    Killed by `finish-merge: an empty Gate-tree trailer after one naming
    HEAD's tree is a second trailer, and refused`.
- **D9: the upgrade note.** A new last section of
  `skills/ratchet/references/upgrade-notes.md`,
  `## The squash commit certifies the gate`. An adopter's `finish-merge.sh`
  refuses a squash written by an older copy of the skill, so the note says to
  refresh the installed skills with the scripts, states git 2.22, the
  last-paragraph rule, the amend-and-sign repair, the template change, and the
  `check-signing.sh` fix. The order of work is not renumbered:
  `tests/skills.bats` pins its numbering. `skills/ratchet/SKILL.md` (1,972
  words) is not edited.
- **D10: problem items.** One new ledger file,
  `docs/problems/2026-10-14-gate-proof-in-trailers.md`, named the day T2
  creates it (ADR-cy7ahd). PR-nyw3ww is opened and resolved by T2. PR-k4y59t
  is opened by T3, whose test reproduces it, and resolved by T5, when the
  template no longer names a tree. PR-yd4pug, found by independent review
  round 1 and predating this change, is opened in the same file and stays
  open. PR-m7gcuq, the forge flow D11 cuts, is opened in the same file at
  review round 3 and stays open. No prose names a draft file by a token
  matching `DRAFT-[A-Za-z0-9_.-]+\.md`.
- **D11: after the signing.** Added at review round 2.
  - Guard 5 reads the trailers unfolded and counts them exactly, key
    included, so an empty `Gate-tree:` counts in either order (D5).
  - The forge flow is cut from this change by the user's ruling of
    2026-10-14: a squash a forge rebases or squash-merges after the push is
    not re-checked, and no CI recipe or procedure for it ships. PR-m7gcuq
    records it as open, to be decided with how pull requests land on GitHub;
    ADR-f6ytg7's Consequences name it.
- **Not changed:** `scripts/check-review.sh`, `scripts/merge-preflight.sh`,
  `finish-merge.sh --check`'s behavior, `merge-change` steps 2 and 3 (they
  already record and confirm the hash), `skills/develop-change`,
  `skills/ratchet/SKILL.md`, ADR-bh4xgr, and every merged record, plan and
  problem item.

## Tasks

| Task | Files touched | Depends on |
| --- | --- | --- |
| T1 | `docs/adr/ADR-f6ytg7-squash-commit-certifies-the-gate.md`, `docs/adr/ADR-y8jmes-local-main-is-the-base.md`, `AGENTS.md`, `tests/skills.bats` | — |
| T2 | `docs/problems/2026-10-14-gate-proof-in-trailers.md`, `scripts/check-signing.sh`, `tests/check-signing.bats`, mutation `M01` | — |
| T3 | `scripts/finish-merge.sh`, `tests/finish-merge.bats`, the problem file, mutations `M02`–`M05` | T2 |
| T4 | four `skills/merge-change` files, `tests/skills.bats`, `tests/finish-merge.bats` | T1, T3 |
| T5 | the template, two `verify-before-merge` files, `templates/AGENTS-block.md`, `README.md`, `tests/skills.bats`, the problem file | T4 |
| T6 | `skills/ratchet/references/upgrade-notes.md`, `tests/skills.bats` | T5 |

Each task is dispatched to a subagent working in
`.worktrees/gate-proof-in-trailers-t<N>`, created with
`sh scripts/task-worktree.sh start t<N>` and merged with
`sh scripts/task-worktree.sh merge t<N>` from the change worktree. Run single
suites with `tests/run-tests.sh tests/<file>.bats`; the full gate is
dispatched by `verify-before-merge`, never run in the dispatcher's context.

### T1 — ADR-f6ytg7 records the decision, and the base statement moves

**Files touched:** `docs/adr/ADR-f6ytg7-squash-commit-certifies-the-gate.md`,
`docs/adr/ADR-y8jmes-local-main-is-the-base.md`, `AGENTS.md`,
`tests/skills.bats`
**Parallel:** yes (with T2 and T3: no shared file)

1. RED: in `tests/skills.bats`, after `ADRs: the ledger-naming decision is
   recorded and accepted`, add:

   *(Code pruned at merge: 26 lines. Files touched: `docs/adr/ADR-f6ytg7-squash-commit-certifies-the-gate.md`, `docs/adr/ADR-y8jmes-local-main-is-the-base.md`, `AGENTS.md`, `tests/skills.bats`.)*

   Run `tests/run-tests.sh tests/skills.bats` and watch it fail with
   `no …/ADR-f6ytg7-squash-commit-certifies-the-gate.md`.
2. GREEN: write the ADR. Line 1:

   *(Code pruned at merge: 1 line. Files touched: `docs/adr/ADR-f6ytg7-squash-commit-certifies-the-gate.md`, `docs/adr/ADR-y8jmes-local-main-is-the-base.md`, `AGENTS.md`, `tests/skills.bats`.)*

   Then `Date: 2026-10-14`, `Status: accepted`, and:
   - **Context:** the record named the commit, tree, base commit and totals of
     the change it is committed in (PR-k4y59t), so every base update or rebase
     made them stale and the rewrite changed the tree it named. The user ruled
     on 2026-10-14 to fix that and to keep local signed squash merges.
   - **Decision:** D1–D6 of this plan, briefly: the trailers and their
     values; `Gate-tree:` is the step 2 hash, not `git write-tree` at step 7;
     step 7's comparison before the hand-over; guard 5 and its git 2.22
     floor; the record names no commit, tree or gate figure; the base
     statement is the `Base:` trailer, which amends ADR-y8jmes's Decision
     sentence. Ruled by the maintainer on 2026-10-14.
   - **Consequences:** the record is a fixed point of the sequence; the first
     record written after the last gate costs one more gate run unless it is
     written before that rerun; an adopter's `finish-merge.sh` refuses a
     squash from an older skill copy until the skills are refreshed; a
     `Gate:` total is copied, not checked; a forge rebase or squash merge
     after the push replaces the signed squash, and nothing in guardrails
     re-checks `Gate-tree:` after that (PR-m7gcuq, open); merged records keep
     their gate sections.
   - **Alternatives considered:** keep the figures in the record and accept
     the rewrite loop (the defect); commit the record after the squash, as a
     second commit (breaks one signed commit per change, non-negotiable 2);
     `git notes` on the squash (not pushed or fetched by default, and not
     covered by the signature); compute `Gate-tree:` at step 7 with
     `git write-tree` (it would compare a value with itself); merge on the
     forge and drop local signing (ruled out by the user); check the `Gate:`
     totals mechanically (that is running the gate again).
3. GREEN: in `docs/adr/ADR-y8jmes-local-main-is-the-base.md`, the Decision's
   second paragraph reads: "This overrides `merge-change` step 1's fetch. The
   squash commit's `Base:` trailer states
   `Base: local main at <commit>, per AGENTS.md non-negotiable 4`, so a later
   reader knows the remote was out of scope by policy. The verification record
   stated it until ADR-f6ytg7 (2026-10-14) moved the base commit it named
   into the `Base:` trailer." Nothing else in the ADR changes.
4. GREEN: in `AGENTS.md`, non-negotiable 4's last paragraph reads:

   *(Code pruned at merge: 2 lines. Files touched: `docs/adr/ADR-f6ytg7-squash-commit-certifies-the-gate.md`, `docs/adr/ADR-y8jmes-local-main-is-the-base.md`, `AGENTS.md`, `tests/skills.bats`.)*

5. Run `tests/run-tests.sh tests/skills.bats`: all pass, including
   `AGENTS.md: non-negotiable 4 states the rule and points to its ADR`.
   Commit.

**Done** (be010b7).
red -> green: `skills.bats: ADRs: the gate-proof decision is recorded, and the base statement is the Base: trailer` — red: no ADR-f6ytg7 file.

### T2 — `check-signing.sh` reads its verdict under `log.showSignature` (PR-nyw3ww)

**Files touched:** `docs/problems/2026-10-14-gate-proof-in-trailers.md`,
`scripts/check-signing.sh`, `tests/check-signing.bats`,
`docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M01.sh`
**Parallel:** yes (with T1)

1. Record the problem first (`resolve-problem`). Create
   `docs/problems/2026-10-14-gate-proof-in-trailers.md`; if T2 runs on a later
   day, use that day's date and give the path in the Done note (T3 and T5 use
   it):

   *(Code pruned at merge: 15 lines. Files touched: `docs/problems/2026-10-14-gate-proof-in-trailers.md`, `scripts/check-signing.sh`, `tests/check-signing.bats`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M01.sh`.)*

2. RED: in `tests/check-signing.bats`, before `check-signing: signed but
   unverifiable warns and passes`, add:

   *(Code pruned at merge: 11 lines. Files touched: `docs/problems/2026-10-14-gate-proof-in-trailers.md`, `scripts/check-signing.sh`, `tests/check-signing.bats`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M01.sh`.)*

   Run `tests/run-tests.sh tests/check-signing.bats`: it fails,
   `expected exit 0, got 1: UNVERIFIED …`.
3. GREEN: in `scripts/check-signing.sh`, the verdict line becomes
   `if ! gstat=$(git log -1 --no-show-signature --format='%G?' "$c" 2>/dev/null) &&`,
   and the comment above it opens with: "--no-show-signature: with
   log.showSignature set, git log prints the verifier's output above the
   letter, and a good signature would read as no verdict (PR-nyw3ww)." followed
   by a `#` line and the existing comment. Confirm no anchor quotes the edited
   line: `grep -rn "format='%G?'" docs/verification/*.mutations/` prints
   nothing.
4. Mutation `M01.sh` (mode 755):

   *(Code pruned at merge: 10 lines. Files touched: `docs/problems/2026-10-14-gate-proof-in-trailers.md`, `scripts/check-signing.sh`, `tests/check-signing.bats`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M01.sh`.)*

   Run `sh docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M01.sh`,
   then `tests/run-tests.sh tests/check-signing.bats`: the new test fails.
   `git checkout -- scripts/check-signing.sh`.
5. In the problem file, set `status: resolved` and add: "Resolved: the verdict
   is read with `git log --no-show-signature`, so the setting no longer
   reaches the letter. Reproduced by "check-signing: a good signature passes
   --strict with log.showSignature set" in `tests/check-signing.bats`; mutation
   `M01` of `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/`
   removes the flag and reddens it."
6. Run `tests/run-tests.sh tests/check-signing.bats` and
   `tests/run-tests.sh tests/portability.bats`: all pass. Run
   `sh tests/mutate.sh docs/verification/2026-10-14-gate-proof-in-trailers.mutations`:
   `mutations: 1 applied, 0 retired, 0 unusable`. Commit.

**Done** (fe72ce5).
red -> green: `check-signing.bats: check-signing: a good signature passes --strict with log.showSignature set` — red: `expected exit 0, got 1: UNVERIFIED <sha> (signature present but did not verify)`.
M01: applied and killed by that test; `tests/mutate.sh` on this change's directory: `1 applied, 0 retired, 0 unusable`.

### T3 — `finish-merge.sh` guard 5: the squash certifies its own tree

**Files touched:** `scripts/finish-merge.sh`, `tests/finish-merge.bats`,
`docs/problems/2026-10-14-gate-proof-in-trailers.md`,
`docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M02.sh`,
`docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M03.sh`,
`docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M04.sh`,
`docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M05.sh`
**Parallel:** no (serial, after T2: the problem file and the mutations
directory, and its `log.showSignature` test passes guard 1 only with T2's fix)

1. Record the problem first. Append to the problem file:

   *(Code pruned at merge: 4 lines. Files touched: `scripts/finish-merge.sh`, `tests/finish-merge.bats`, `docs/problems/2026-10-14-gate-proof-in-trailers.md`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M02.sh`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M03.sh`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M04.sh`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M05.sh`.)*

2. RED: in `tests/finish-merge.bats`:
   - `make_squashed_change` writes the trailer. Replace its `git merge
     --squash` … `fi` lines with:

     *(Code pruned at merge: 16 lines. Files touched: `scripts/finish-merge.sh`, `tests/finish-merge.bats`, `docs/problems/2026-10-14-gate-proof-in-trailers.md`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M02.sh`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M03.sh`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M04.sh`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M05.sh`.)*

   - Before the comment `# Guard 4 is fully knowable before the squash commit
     exists`, add:

     *(Code pruned at merge: 101 lines. Files touched: `scripts/finish-merge.sh`, `tests/finish-merge.bats`, `docs/problems/2026-10-14-gate-proof-in-trailers.md`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M02.sh`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M03.sh`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M04.sh`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M05.sh`.)*

   Run `tests/run-tests.sh tests/finish-merge.bats`. The five refusal tests
   and the PR-k4y59t test fail with exit 0 and the three `finish-merge:`
   success lines (measured on a scratch copy: `expected exit 1, got 0:
   finish-merge: HEAD verified as a signed squash of my-change`). The
   `log.showSignature` test and every existing test pass, the helper's
   trailer included. That test guards the guard against a regression, so its
   red is watched under mutation `M05` (step 5), the way the red of a
   pre-existing behavior is watched, and the Done note says so.
3. GREEN: in `scripts/finish-merge.sh`, after guard 2's `gr_refuse` (the
   message ending "then redo the squash and run this script again on its
   own.") and before the comment that opens "git's own registry, read ONCE",
   insert:

   *(Code pruned at merge: 36 lines. Files touched: `scripts/finish-merge.sh`, `tests/finish-merge.bats`, `docs/problems/2026-10-14-gate-proof-in-trailers.md`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M02.sh`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M03.sh`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M04.sh`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M05.sh`.)*

   Header and comments, so the count is stated once and consistently:
   - "Four guards, all proved before anything is removed:" becomes "Five
     guards, all proved before anything is removed:", and after guard 4's
     entry add:

     *(Code pruned at merge: 5 lines. Files touched: `scripts/finish-merge.sh`, `tests/finish-merge.bats`, `docs/problems/2026-10-14-gate-proof-in-trailers.md`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M02.sh`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M03.sh`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M04.sh`, `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/M05.sh`.)*

   - In the `--check` paragraph of the header, "Guards 1 and 2 both read the
     squash commit, so neither can be preflighted at all;" becomes "Guards 1,
     2 and 5 all read the squash commit, so none of them can be preflighted
     at all;".
   - In the comment above `if [ "$check_only" -eq 1 ]; then`, "Guards 1 and 2
     both read the squash commit; at the point this mode is for that commit
     does not exist, so a mode claiming all four guards would have to invent
     two verdicts." becomes "Guards 1, 2 and 5 all read the squash commit; at
     the point this mode is for that commit does not exist, so a mode claiming
     all five guards would have to invent three verdicts."
   - The three success `echo` lines are unchanged (`merge-change: step 7
     tells the user what success looks like` counts them).
4. Mutations `M02.sh`–`M05.sh` (mode 755), each in the shape of `M01.sh`
   with these `old`/`new` pairs (Python string literals as written):
   - `M02`, "# describes: finish-merge: guard 5 accepts a message with more
     than one Gate-tree trailer":
     `old = '    (*"$gr_nl"*) gr_refuse \\\n"HEAD\'s message has more than one Gate-tree: trailer'`,
     `new = '    (*"$gr_nl-unmatched"*) gr_refuse \\\n"HEAD\'s message has more than one Gate-tree: trailer'`.
   - `M03`, "# describes: finish-merge: guard 5 accepts a Gate-tree trailer
     that names another tree":
     `old = '[ "$gate_tree" = "$head_tree" ] || gr_refuse'`,
     `new = '[ -n "$head_tree" ] || gr_refuse'`.
   - `M04`, "# describes: finish-merge: guard 5 does not single out a message
     with no Gate-tree trailer":
     `old = '[ -n "$gate_tree" ] || gr_refuse'`,
     `new = '[ -n "$head_tree" ] || gr_refuse'`.
   - `M05`, "# describes: finish-merge: guard 5 reads the trailer with
     log.showSignature in force" (the value read back is then the verifier's
     "Good" line and the hash, two lines, so the guard refuses as it does for
     two trailers):
     `old = "git log -1 --no-show-signature --format='%(trailers:key=Gate-tree,valueonly)' HEAD"`,
     `new = "git log -1 --format='%(trailers:key=Gate-tree,valueonly)' HEAD"`.
5. Prove each kills. For each of `M02`–`M05`: run it, run
   `tests/run-tests.sh tests/finish-merge.bats`, then
   `git checkout -- scripts/finish-merge.sh`. Expected (measured on a scratch
   copy): `M02` fails "two Gate-tree trailers are refused, even when both name
   HEAD's tree"; `M03` fails "a Gate-tree trailer naming another tree is
   refused, naming both trees" and "a record committed after the gate leaves a
   squash its Gate-tree does not name"; `M04` fails the three no-trailer
   tests; `M05` fails "guard 5 reads the trailer when log.showSignature is
   set". Record each in the Done note.
6. Run `tests/run-tests.sh tests/finish-merge.bats`,
   `tests/run-tests.sh tests/portability.bats` (case patterns, `awk -v`, the
   bare-negation scan) and
   `sh tests/mutate.sh docs/verification/2026-10-14-gate-proof-in-trailers.mutations`:
   all pass, `mutations: 5 applied, 0 retired, 0 unusable`. PR-k4y59t stays
   open (T5 resolves it). Commit.

**Done** (b2dcb4b).
red -> green: `finish-merge.bats: finish-merge: a squash whose message has no Gate-tree trailer is refused with everything intact` — red: `expected exit 1, got 0`, cleaned up.
red -> green: `finish-merge.bats: finish-merge: a Gate-tree trailer with no value is refused` — red: exit 0.
red -> green: `finish-merge.bats: finish-merge: a Gate-tree line outside the message's last paragraph is not read` — red: exit 0.
red -> green: `finish-merge.bats: finish-merge: two Gate-tree trailers are refused, even when both name HEAD's tree` — red: exit 0.
red -> green: `finish-merge.bats: finish-merge: a Gate-tree trailer naming another tree is refused, naming both trees` — red: exit 0.
red -> green: `finish-merge.bats: finish-merge: a record committed after the gate leaves a squash its Gate-tree does not name` — red: exit 0, worktree and branch removed.
`finish-merge: guard 5 reads the trailer when log.showSignature is set` is a regression guard, green before guard 5; red under M05 and under M01.
M02–M05 each applied and killed as planned; `5 applied, 0 retired, 0 unusable`. The guard 5 tests sit before the `--check` section header, so the header comment above them is not split.

### T4 — `merge-change` writes the trailers and checks the staged tree

**Files touched:** `skills/merge-change/SKILL.md`,
`skills/merge-change/references/rationale.md`,
`skills/merge-change/references/cleanup-rejections.md`,
`skills/merge-change/references/multi-unit.md`, `tests/skills.bats`,
`tests/finish-merge.bats`
**Parallel:** no (serial, after T1, which also edits `tests/skills.bats`, and
T3, which also edits `tests/finish-merge.bats`)

1. RED, `tests/skills.bats`:
   - After `merge-change: step 7 checks for a staged squash before staging its
     own`, add:

     *(Code pruned at merge: 77 lines. Files touched: `skills/merge-change/SKILL.md`, `skills/merge-change/references/rationale.md`, `skills/merge-change/references/cleanup-rejections.md`, `skills/merge-change/references/multi-unit.md`, `tests/skills.bats`, `tests/finish-merge.bats`.)*

   - `merge-change: step 8 maps guard 4's rejection to a remedy`: gains
     `# verifies: D5 (docs/plans/2026-10-14-gate-proof-in-trailers.md)`;
     `grep -q 'proves four things' "$skill"` becomes
     `grep -q 'proves five things' "$skill"`; after the
     `a registered worktree lies inside` grep, add three greps of
     `cleanup-rejections.md` for `carries no Gate-tree: trailer with a value`,
     `more than one Gate-tree: trailer` and
     `Gate-tree: trailer names <tree>, but HEAD's tree is <tree>` (the last in
     double quotes); and the final negative becomes
     `run grep -rq -e 'proves three things' -e 'proves four things' "$(dirname "$skill")"`.
   - `merge-change: text the first rewrite lost is stated again`:
     `grep -q 'No script parses the message' "$rationale"` becomes
     `grep -q 'No script parses these two lines' "$rationale"`.
   - `merge-change: the commit template states the Resolves and Opens
     trailers`: its comment's second line becomes "these two lines, so they
     cost nothing; only `Gate-tree:` is read (finish-merge.sh guard 5)."
2. RED, `tests/finish-merge.bats`, after the guard 5 tests:

   *(Code pruned at merge: 24 lines. Files touched: `skills/merge-change/SKILL.md`, `skills/merge-change/references/rationale.md`, `skills/merge-change/references/cleanup-rejections.md`, `skills/merge-change/references/multi-unit.md`, `tests/skills.bats`, `tests/finish-merge.bats`.)*

   Run both suites: the two new skills tests, the re-aimed step 8 and
   rationale tests, and the template test fail (`no Gate-tree line in the
   template`).
3. GREEN, `skills/merge-change/SKILL.md` (drafted in full on a scratch copy;
   1,991 words after):
   - Step 1's first two bullets read: "A failed fetch is a **stop**. Fetch
     from a session that can, or merge the local ref and name it in step 7's
     `Base:` trailer." and "A project may put the remote out of scope only if
     its own AGENTS.md states why, and the `Base:` trailer states it too.
     Never adopt that by analogy."
   - 6a's last-round paragraph: after "and the rerun ends at 6b." add the line
     "Write the record (6b) before that rerun."
   - 6b's list opens "commit it unsigned: the IDs this change resolves,
     accepts or opens, `red -> green:` and any `inherited:` lines …": the
     words "the gate summary's totals and the tree they describe, coverage if
     configured, each check's result," and "(never the open count or oldest
     age)" are deleted. Nothing else in 6b changes.
   - Step 7's message fence gains three lines after `Verified:`:
     `Base: <base ref> at <its commit>`, `Gate-tree: <step 2 tree>` and
     `Gate: <verify_commands entry> <passed>/<total>`.
   - "Omit an empty `Resolves:` or `Opens:` line." continues: "Write one
     `Gate:` line per `verify_commands` entry, and one for `coverage_command`
     where configured. Keep every trailer, `Co-Authored-By:` included, in this
     last paragraph."
   - Then, before "Hand the user exactly one command":

     *(Code pruned at merge: 7 lines. Files touched: `skills/merge-change/SKILL.md`, `skills/merge-change/references/rationale.md`, `skills/merge-change/references/cleanup-rejections.md`, `skills/merge-change/references/multi-unit.md`, `tests/skills.bats`, `tests/finish-merge.bats`.)*

   - "`finish-merge.sh` proves four things" becomes "proves five things".
   - Done when's first bullet reads as below, with its last clause on a line
     of its own (`Done when names finish-merge.sh as the verifier` greps one
     line):

     *(Code pruned at merge: 3 lines. Files touched: `skills/merge-change/SKILL.md`, `skills/merge-change/references/rationale.md`, `skills/merge-change/references/cleanup-rejections.md`, `skills/merge-change/references/multi-unit.md`, `tests/skills.bats`, `tests/finish-merge.bats`.)*
   - Check `wc -w < skills/merge-change/SKILL.md`: 1,991, and at most 2,000.
4. GREEN, `skills/merge-change/references/rationale.md`. No new text names a
   script (`the rationale file describes no script`): it says "the cleanup".
   - `## Step 1: the fetch, …`: "A base merged from a local ref is recorded
     with its commit so that a later reader knows what the duplicate scan at
     step 4 was compared against." becomes "A base merged from a local ref is
     named with its commit in step 7's `Base:` / trailer, so that a later
     reader knows / what the duplicate scan at step 4 was compared against."
     with the last clause on one line (a test greps it whole).
   - `## Step 2: recording the tree` appends: "Step 7 writes the same hash as
     the `Gate-tree:` trailer: the tree the gate measured, not one computed
     again at step 7."
   - After `## Step 6a: a review worktree with scratch in it`, add
     `## Step 6a: the record is written before the last rerun`: "A record
     committed after the step 2 gate changes the tree, so step 7's comparison
     finds a mismatch and the sequence reruns from step 1 for one more gate
     run. Written once the last review's fixes are merged and before that
     rerun, the record is in the tree the gate measures, and the rerun's 6b
     leaves it as it is. Where 6b is first reached with no record, as for a
     class A change with no review, the first step 7 costs that one rerun."
   - After `## Step 6b: the record is committed in the worktree`, add
     `## Step 6b: the record names no tree`: "A record that names the commit,
     the tree, the base commit or the gate totals of its change is part of the
     tree it names. Every base update, and every rebase after a shared remote
     moves, made those lines stale, so the record was rewritten and committed
     again, which changed the tree it named: a loop, and a late commit on the
     review evidence. The commit can carry what the record could not, because
     nothing it carries changes its tree. So the record holds only what the
     commit cannot prove, and nothing in it is measured from the tree. It does
     not change when the sequence reruns, and the tree the gate measured is
     the tree squashed. `ADR-f6ytg7` records the decision."
   - `## Step 7: \`Resolves:\` and \`Opens:\``: "No script parses the
     message, so each costs one line" becomes "No script parses these two
     lines, so each costs one line".
   - After it, add `## Step 7: the trailers certify the gate`, three
     paragraphs:
     - "`Gate-tree:` is the hash step 2 recorded, not `git write-tree` at step
       7: a tree computed at step 7 describes what is staged, which is what
       the check questions. The comparison before the hand-over catches a
       branch that changed after the gate, such as a record committed at 6b,
       before the key touch; the cleanup would refuse the same squash after
       it."
     - "git reads trailers only in a message's last paragraph. A blank line
       before `Co-Authored-By:`, or a wrapped trailer line that does not open
       with whitespace, leaves `Gate-tree:` in the body, and the cleanup is
       refused."
     - "The `Gate:` lines are copied from the step 2 summary. No script checks
       them: checking a total means running the gate again. What is checked
       is the tree they describe. Coverage gets a `Gate:` line because it is a
       measured figure and the record no longer holds one. The pre-flight has
       no trailer: the sequence halts when it fails, so a squash exists only
       after it passed. Not all of it reads the tree, but its ID and trace
       checks do, and can be rerun on the tree `Gate-tree:` names."
5. GREEN, `skills/merge-change/references/cleanup-rejections.md`: two rows,
   inserted before the `git worktree remove` rejected it row:
   - `` `HEAD's message carries no Gate-tree: trailer with a value`, or `has
     more than one Gate-tree: trailer` `` | "The squash message lacks the step
     7 trailer, or git does not read it as one: git reads trailers only in a
     message's last paragraph, so a blank line before `Co-Authored-By:`, or a
     wrapped trailer line that does not open with whitespace, hides them." |
     "The tree is right if step 7's comparison passed. Correct the message
     file to one `Gate-tree:` line, the tree step 2 recorded, in the last
     paragraph. The user amends and signs again,
     `git commit --amend -S -F /tmp/merge-<branch>.msg`, which keeps the
     tree. Then re-run the script. If the commit was already pushed, amending
     it is the user's call."
   - `` `HEAD's Gate-tree: trailer names <tree>, but HEAD's tree is <tree>` ``
     | "The signed commit holds a tree no gate measured: the branch changed
     after the step 2 gate, or a wrong hash was copied. A value that reads
     `%(trailers:…)` means git is older than 2.22." | "Dispatch the gate in
     the change worktree, still in place: its tree is HEAD's, as guard 2
     proved. If it is green, write its tree and totals into the message file;
     the user amends and signs again as above, then re-runs the script. If it
     is red, the base branch holds a failing tree: stop and tell the user,
     whose call undoing it is."
6. GREEN, `skills/merge-change/references/multi-unit.md`: the bullet
   "dispatch each unit's `verify_commands` … for every unit in the impact
   set." ends with ";" and is followed by: "- write one `Gate:` trailer per
   unit and command at step 7, `Gate: <unit>: <verify_commands entry>
   <passed>/<total>`. The one `Gate-tree:` trailer names the tree every
   unit's gate measured."
7. Run `tests/run-tests.sh tests/skills.bats` and
   `tests/run-tests.sh tests/finish-merge.bats`: all pass, including `skill
   shape: every SKILL.md is at most 2,000 words`, `merge-change: the rationale
   file describes no script`, `skill references: no blank line separates two
   rows of one table` and `merge-change: step 7 checks for a staged squash
   before staging its own` (step 7's first fence is unchanged). Commit.

**Done** (f4a0ca6).
red -> green: `skills.bats: merge-change: step 7 writes the gate's trailers and compares the staged tree with the step 2 tree before the hand-over` — red: `the message template lacks: Base: <base ref> at <its commit>`.
red -> green: `skills.bats: merge-change: the record is written before the last rerun and holds no gate figure` — red: no `Write the record (6b) before that rerun.`
red -> green: `finish-merge.bats: finish-merge: the message merge-change step 7 documents passes guard 5` — red: `no Gate-tree line in the template`.
merge-change `SKILL.md`: 1,991 words.

### T5 — the record keeps only what the commit cannot prove

**Files touched:** `templates/verification.md`,
`skills/verify-before-merge/SKILL.md`,
`skills/verify-before-merge/references/rationale.md`,
`templates/AGENTS-block.md`, `README.md`, `tests/skills.bats`,
`docs/problems/2026-10-14-gate-proof-in-trailers.md`
**Parallel:** no (serial, after T4: both edit `tests/skills.bats`, and T3
before it on the problem file)

1. RED, `tests/skills.bats`:
   - Rename `verification template: a repository figure does not belong in
     the gate table` to `verification template: a repository figure does not
     belong in the record`; its body is unchanged.
   - Replace `verification template: the gate table names the tree the
     figures describe` with:

     *(Code pruned at merge: 20 lines. Files touched: `templates/verification.md`, `skills/verify-before-merge/SKILL.md`, `skills/verify-before-merge/references/rationale.md`, `templates/AGENTS-block.md`, `README.md`, `tests/skills.bats`, `docs/problems/2026-10-14-gate-proof-in-trailers.md`.)*

   - Before `verification template: a record does not count itself, and
     narrates once`, add:

     *(Code pruned at merge: 16 lines. Files touched: `templates/verification.md`, `skills/verify-before-merge/SKILL.md`, `skills/verify-before-merge/references/rationale.md`, `templates/AGENTS-block.md`, `README.md`, `tests/skills.bats`, `docs/problems/2026-10-14-gate-proof-in-trailers.md`.)*

   Run `tests/run-tests.sh tests/skills.bats`: the two new or replaced tests
   fail (`the template lacks: …`, `verify-before-merge still feeds the gate
   figures to the record`); the renamed one passes.
2. GREEN, `templates/verification.md` (drafted on a scratch copy; every other
   template test passes against it):
   - The header's last sentence: "The squash commit references it on its
     `Verified:` line and carries the gate's figures in its own trailers; this
     file is the rest of the evidence that travels with the change."
   - `Change: <one sentence>. Branched from \`<base>\` at \`<commit>\`.`
     becomes `Change: <one sentence>.`
   - `## The gate`, from its heading to `## Red → green`, is replaced by four
     paragraphs:
     - "The gate's figures are not in this record. The squash commit carries
       them as trailers (`merge-change` step 7): `Gate-tree:` names the tree
       the step 2 gate measured, a `Gate:` line gives each command's totals,
       and `Base:` names the base and the commit step 1 merged.
       `finish-merge.sh` refuses the cleanup unless `Gate-tree:` is the
       commit's own tree."
     - "So this record names no commit, no tree and no figure measured from
       one. A record that did would be part of the tree it names, and every
       rerun after a base update would rewrite it. Written this way it does
       not change when the sequence reruns, and the tree the gate measured is
       the tree squashed."
     - "A figure that describes the repository rather than this change does
       not belong in this record either: the open-problem count, the roll-call
       total, the age of the oldest item. Each is true of one instant of a
       ledger every other change edits, and a record outlives that instant.
       Name which of **this change's own** IDs it resolves, accepts or opens."
     - "A coverage gap the user accepted (`verify-before-merge` check 5) is a
       decision, not a figure: state it under Gaps."
   - No line of the new text opens with a `word:` at column one, so
     `check-review.sh` reads nothing new from it.
3. GREEN, `skills/verify-before-merge/SKILL.md`, "After the gate" item 4:
   "4. Anything `merge-change` step 7's trailers need from the gate must be in
   the gate summary: each command's totals and, where configured, the
   coverage figure. If a figure is missing, ask the subagent for it rather
   than running the command again."
4. GREEN, `skills/verify-before-merge/references/rationale.md`,
   `## The log is not kept`: "The log is deleted with the change worktree. The
   durable evidence of the gate is the squash commit's `Gate:` trailers,
   beside the `Gate-tree:` they describe, which `merge-change` step 7 writes.
   That is why each command's totals must be in the gate summary."
5. GREEN, `templates/AGENTS-block.md` item 2, its third sentence: "Intermediate
   worktree commits may be unsigned; the squash commit must be signed and
   carry a `Gate-tree:` trailer naming the tree the gate measured, and
   `finish-merge.sh` verifies both before the worktree is cleaned up." The
   last sentence, "There is no unsigned fallback.", stays.
6. GREEN, `README.md` rule 2: "**Integration is a signed squash merge.** The
   base branch receives one signed, verified commit per change, whose
   `Gate-tree:` trailer names the tree its gate measured; the user signs it,
   and `finish-merge.sh` cleans up only after its guards pass."
7. In the problem file, PR-k4y59t: `status: resolved`, and: "Resolved: the
   squash commit carries the gate's tree, totals and base as `Gate-tree:`,
   `Gate:` and `Base:` trailers (ADR-f6ytg7), `finish-merge.sh` guard 5
   refuses a squash whose `Gate-tree:` is not its own tree, and the record
   names no commit, tree or gate figure, so a rerun no longer rewrites it.
   Reproduced by "finish-merge: a record committed after the gate leaves a
   squash its Gate-tree does not name" in `tests/finish-merge.bats`; the
   template is pinned by "verification template: the gate's figures and their
   tree are in the squash commit, not the record" in `tests/skills.bats`."
8. Run `tests/run-tests.sh tests/skills.bats`: all pass, every
   `verification template:` test among them. Commit.

**Done** (7f3049b).
red -> green: `skills.bats: verification template: the gate's figures and their tree are in the squash commit, not the record` — red: the template lacked the `Gate-tree:` pointer.
red -> green: `skills.bats: verify-before-merge: the gate summary holds what step 7's trailers need` — red: `verify-before-merge still feeds the gate figures to the record`.

### T6 — the upgrade note

**Files touched:** `skills/ratchet/references/upgrade-notes.md`,
`tests/skills.bats`
**Parallel:** no (serial, after T5: both edit `tests/skills.bats`)

1. RED: after `ratchet: the upgrade notes say ledger files are named at
   creation, and how to rename a draft in flight`, add:

   *(Code pruned at merge: 12 lines. Files touched: `skills/ratchet/references/upgrade-notes.md`, `tests/skills.bats`.)*

   Watch it fail: `no section`.
2. GREEN: append to `skills/ratchet/references/upgrade-notes.md`, after
   `## Code guidelines are a project file`:

   *(Code pruned at merge: 27 lines. Files touched: `skills/ratchet/references/upgrade-notes.md`, `tests/skills.bats`.)*

3. Run `tests/run-tests.sh tests/skills.bats`: all pass, including the
   upgrade-note tests that pin the order of work. Commit.

**Done** (3a2bb1e).
red -> green: `skills.bats: ratchet: the upgrade notes say the squash commit certifies the gate, and how to repair a squash without its trailer` — red: no section.

## After the tasks

- Run `develop-change`'s conformance reviews against `docs/TEST_GUIDELINES.md`
  and `docs/CODE_GUIDELINES.md`, and write their findings and dispositions
  under `## Guideline reviews` here.
- Dispatch `verify-before-merge`: `tests/run-tests.sh`. Read the pass and fail
  counts, not the exit status.
- Then `merge-change`, from **this change's own** `SKILL.md`: the installed
  copy under `~/.agents/skills/` still has the old step 7, and refreshing it
  is the user's. This change is the first to merge under its own rules:
  - Write the record from the new template before the rerun that follows the
    last review (6a). It names no commit or tree the gate measured, no base
    commit and no gate figure; the
    sentence "base merged from local `main` at …" is not written there.
  - The squash message ends in one trailer paragraph: `Implements:
    ADR-f6ytg7`, `Resolves: PR-k4y59t, PR-nyw3ww`,
    `Opens: PR-yd4pug, PR-m7gcuq`, `Plan:`, `Verified:`,
    `Base: local main at <commit>, per AGENTS.md non-negotiable 4`,
    `Gate-tree: <step 2 tree>`, `Gate: tests/run-tests.sh <passed>/<total>`
    and the `Co-Authored-By:` line, with no blank line before it.
  - Compare `git write-tree` with the step 2 tree before handing over the
    command. The user's `sh scripts/finish-merge.sh gate-proof-in-trailers`
    runs the new script from the primary checkout, so guard 5 checks this
    change's own squash.
- The record's Gaps state:
  - nothing re-checks `Gate-tree:` after the push: a forge rebase or squash
    merge replaces the signed squash, and how pull requests land is
    undecided (PR-m7gcuq, open; ADR-f6ytg7, Consequences);
  - the `Gate:` totals are copied from the gate summary, not checked;
  - the installed skill copies are the user's to refresh, and until they are,
    a squash written from them is refused by guard 5.

## Guideline reviews

`guidelines-file.sh` assigned every path of the diff to both files. The
findings and their dispositions are in the verification record,
`docs/verification/2026-10-14-gate-proof-in-trailers.md`.

- `docs/TEST_GUIDELINES.md`, round 1: two low findings (the M01 and M02
  anchors did not quote their script line verbatim), fixed in 8ac254c.
  Nothing above low, so no second round.
- `docs/CODE_GUIDELINES.md`, round 1: six medium findings and one low (names
  and history comments), fixed in 8ac254c; the guard 4 header's "numbered
  last" sentence, made false by guard 5, fixed in a6ff264.
- `docs/CODE_GUIDELINES.md`, round 2: five low findings, fixed in ff545ce
  (`step_of` in `tests/helpers.bash` replaces four copies of the step 7
  extraction). Nothing above low, so the reviews end.
