# Verification — upgrade-notes-find-items (2026-10-06)

branch: upgrade-notes-find-items
reviewer: rounds 1 and 2, each a fresh subagent with the diff, the plan and AGENTS.md, and no implementation narrative
verdict: round 1 REJECT on one medium code finding; round 2 ACCEPT on three low findings, the last round under the low-severity convergence rule (ruled by the user 2026-10-04)
reproduced: no defect is repaired; the ratchet upgrade notes state that the skills call `find-items.sh`, at the user's request of 2026-10-06. The exit codes the section states were measured in scratch projects, by the author and by both reviewers.

Change: `skills/ratchet/references/upgrade-notes.md` gains the section "The skills call `find-items.sh`": six skills call `.guardrails/scripts/find-items.sh`, a project whose scripts predate it gets exit 127 from each call until it upgrades, the upgrade adds it, no gate reads it, and where it exits 2. The preamble now covers a section about how the skills use the scripts. Documentation only. Branched from `main` at `f50c055` while `pr-s8dcmp` and `ratchet-upgrade-mode` were open, by the user's decision of 2026-10-06 overriding AGENTS.md non-negotiable 4; `pr-s8dcmp` also edits `upgrade-notes.md`, in "Order of work", which this change does not touch. Base merged from local `main` at `f50c055` before each gate, per AGENTS.md non-negotiable 5 (`Already up to date` each time).
Plan: `docs/plans/2026-10-06-upgrade-notes-find-items.md`.

## The gate

Guardrails has no `.guardrails/config.yaml`. `check-ids.sh` and
`check-trace.sh` were run against scratch copies of `main` at `f50c055` and
of the change at `c4b7224`, built by the recipe in
`docs/verification/2026-10-03-accept-2scmvn.md`. Both are red on `main`
already, so the criterion is no finding on the change that `main` lacks.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..1069`: 1069 ok, 0 not ok, 0 skipped, no `bats warning:` line, on `c4b7224`, tree `f63060625fe6ebce97a05dd3f6b43194c04329ad`, 17:23:15 to 17:53:43 CEST, clean before and after |
| `check-ids.sh` | exit 1 on `main` and on the change, 79 lines each, no difference |
| `check-trace.sh` | exit 1 on `main` and on the change, 152 lines each, no difference |
| `tests/skills.bats`, after each fix | `1..96`: 96 ok, 0 not ok |
| `check-review.sh` | run on the commit that adds this record (merge-change step 6c); its result is reported with the hand-over |
| Coverage | not configured; the toolkit is unclassified |
| Working tree | clean before and after every run |

The diff is documentation only, so neither reviewer ran the suite; the gate
above is substituted for it. Gates dispatched on `197e8c3` and `dea6588` were
stopped before they reported, because the review fixes changed the tree;
their figures are not used. This record is committed after the gate and
changes no file the suite reads.

`tests/evidence.sh` is not run: the change adds no test and touches no
script.

## Red → green

Not applicable: documentation only, no `verifies:` test.

## Deslop

No separate pass was dispatched. The author's own reading after each round
reflowed the preamble and removed a doubled "Most" introduced in the round 1
fix.

## Findings

**finding-1**: code, medium — round 1. The section said `find-items.sh` "exits 2 on the config errors in "Exit 2: config and layout" and "Exit 2: the config schema's fatal rules"". Measured: on a ledger directory that is missing or holds no `*.md`, `refs` exits 0; on an untracked ledger file, all three subcommands exit 0, where `check-trace.sh` exits 2.
disposition: fixed in `dea6588`: the section says which errors make `list` and `show` exit 2, that `refs` does not exit 2 on them, and that none of the three checks that a ledger file is committed.

**finding-2**: requirement, low — round 1. "`install.sh` links the skills" is the default only; `--copy` installs a static copy.
disposition: fixed in `dea6588`: "By default `install.sh` links".

**finding-3**: requirement, low — round 1. Under `.guardrails/units.yaml` a call with no `GR_CONFIG` exits 2 (`scripts/lib.sh:1451`); the section did not say so.
disposition: fixed in `dea6588`: the section says it, and to set `GR_CONFIG` to the unit's config.

**finding-4**: requirement, low — round 1. The managed-block refresh brings the AGENTS.md line that names the script (`templates/AGENTS-block.md:76`); the section did not say so.
disposition: fixed in `dea6588`.

**finding-5**: record, low — round 1. The preamble said every section is a change in what the scripts accept; this one is not.
disposition: fixed in `dea6588`: "a change in what the scripts accept, or in how the skills use them".

**finding-6**: code, low — round 2. The exit-2 list named an unknown key and a no-gated `id_prefixes` but dropped the other config rows of "Exit 2: config and layout", so it read as complete when it was not.
disposition: fixed in `c4b7224`: the section says every row about the config file exits 2. Measured on the scripts of `dea6588`: a column-zero list item, an orphaned list item and an empty `test_paths` each exit 2; round 2 measured a BOM, a key not at column one, `REQ` with no `doc_srs` and an invalid prefix.

**finding-7**: code, low — round 2. The skills also write the bare form `find-items.sh show ID`, which run literally gives `command not found`, exit 127, not `No such file or directory`.
disposition: fixed in `c4b7224`: every call exits 127, and the message is stated for the path form only.

**finding-8**: requirement, low — round 2. T1 was committed by the dispatcher onto the change branch, not by a task subagent in a nested task worktree (AGENTS.md non-negotiable 1), and the plan gave no reason.
disposition: recorded, not repaired: the plan's Progress states the reason, a one-file documentation edit with no test, as in earlier documentation-only plans.

## Gaps

- No reviewer read the round 2 fixes; under the low-severity rule there is no round 3.
- The bare form `find-items.sh show ID` in the skills relies on the agent reading it as the path form named earlier in the same skill; this change does not alter the skills.
