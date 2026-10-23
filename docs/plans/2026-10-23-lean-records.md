# Lean records

The code and the signed history are the record of what is built. Documents on
`main` hold only what code cannot state: intent and constraints.

## Measured

`organisational-data-sovereignty` at 117 commits: ~1.2M words of Markdown
against ~387k words of code and tests. ~848k of it is history (plans 366k,
superpowers 219k, verification 204k, problems 46k, phase-1d 13k). 405 ledger
items (191 REQ/LLR, 77 SDD, 63 HAZ, 74 RC) carry ~305k words, 300-700 per
item. This repository: plans 247k, verification 286k, problems 35k, against
235k of tracked scripts and tests.

## Decisions

- **D1.** Kept on the base branch: glossary, guidelines, REQ/LLR, SDD, SOUP,
  HAZ/RC, ADRs, and open problem reports. Everything else is history, and git
  holds it.
- **D2.** A plan never reaches the base branch. It lives on the change branch;
  its substance goes into the squash message.
- **D3.** The verification record is the squash commit message, not a file.
  The message is written so it can serve as a pull request body.
- **D4.** Mutation evidence moves into the squash message as trailers; the
  `.mutations/` directories go.
- **D5.** A resolved problem report is deleted outright when the fixing change
  merges. The squash message records cause and fix; the regression test
  verifies the REQ the defect broke, and the change adds that REQ if none
  covered it.
- **D6.** Ledger items are terse. No hard length limit. Item length is
  reviewed, and a long item is shortened or a shortening is proposed.
- **D7.** ADRs shrink to the decision, its context and its consequences, and
  are rewritten rather than amended with history.
- **D8.** `ratchet` upgrade reworks an existing codebase to this shape.
- **D10.** A superseded or retired item is deleted, not annotated. Same
  behavior reworded: edit in place, keep the ID. Behavior changed: new ID, old
  item deleted, the squash message records `old → new`. Behavior gone: item
  deleted, the squash message gives the reason. A test still naming a deleted
  ID is a dangling reference and fails the gate until deleted or re-pointed.
  The `superseded-by:`/`supersedes:`/`retired:` syntax and the out-of-force
  findings go.
- **D11.** Terseness is judged in `merge-change`'s step 4 review, on the
  items the change adds or edits. An item stating more than one testable
  behavior, or carrying rationale, history or implementation detail, is a
  finding with a proposed shorter wording; its disposition goes in the squash
  message. No script checks length. Existing items are `ratchet`'s (D8).
- **D12.** The squash message shape. Body, for people, checked by the step 4
  reviewer: a one-line subject; what and why in a few sentences (the future
  PR body); `Items:` (added, reworded, `old → new`, removed with reason);
  `Problems:` (`PR-x — cause → fix`); `Findings:`, one numbered line each
  opening with its disposition. Trailers, for scripts: `Gate-tree:`,
  `Tests:`, `Mutation:` (one per mutant: anchor, mutant, killing test),
  `Resolves:`, `Base:`. No `Co-Authored-By:`. `check-review` checks the
  message file before hand-over and `finish-merge.sh` checks the signed
  commit: exactly one `Gate-tree:` naming the commit's tree; `Tests:` with
  zero failed; a `Mutation:` per required mutant; `Resolves:` naming exactly
  the PR items the diff deletes; each finding line numbered with a
  disposition. `Items:` and `Problems:` are prose only.
- **D13.** The plan is committed on the change branch at
  `docs/plans/<date>-<slug>.md`, where task worktrees and the step 4 reviewer
  read it. `merge-change` deletes it in a commit before the step 6a gate; the
  gate fails if the diff against the base adds anything under `docs/plans/`.
  The step 4 reviewer checks that the message's what-and-why carries the
  plan's decisions. `prune-plans.sh` and ADR-bh4xgr are retired.
- **D14.** A comment states its reason inline and tersely, or cites an ADR by
  ID for a recorded trade-off. It never cites a plan, a verification record
  or a problem report, and never narrates history. The gate fails on a tracked
  file, other than the change's own plan, that references `docs/plans/` or
  `docs/verification/`; a deleted PR ID is already a dangling reference. The
  deletion change rewrites existing citations: drop the citation where the
  comment already states the reason, write a one-line reason where the reason
  lived only in the plan, cite the ADR for a trade-off.
- **D15.** The `ratchet` upgrade (D8), one commit per step in one change:
  (1) delete guardrails' own history unasked: plans, verification records,
  `.mutations/`, resolved PR items, out-of-force items with their tests
  re-pointed or deleted per D10; (2) list directories guardrails did not
  create, with word counts, and ask before deleting each; (3) shorten items
  itself where only non-normative text goes (rationale, history, examples,
  implementation detail), the shall-clause kept verbatim and any rationale
  worth keeping moved to an ADR or LLR; (4) propose, one diff per unit, every
  change to a shall-clause, splitting an item that states two behaviors, for
  the user to approve; (5) rewrite code comments and ADRs per D14 and D7.
  Steps 3 and 4 pass the D11 review.
- **D16.** No report-rendering script now. ADR-k3nkv3 names the signed squash
  messages as the IEC 62304 verification and problem-resolution records and
  gives the `git log --first-parent` command that lists them.
- **D9.** Sequence: ADR; skills, templates and AGENTS.md (its rules put plans
  and incident history in `docs/plans/`) stop generating the text; scripts
  and tests move to the new record shape; one deletion change, which retires
  ADR-bh4xgr and rewrites ADR-f6ytg7.
