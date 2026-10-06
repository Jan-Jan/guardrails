# Upgrade notes name find-items.sh Implementation Plan

**Goal:** `skills/ratchet/references/upgrade-notes.md` states that the skills call `.guardrails/scripts/find-items.sh`, and that a project whose scripts predate it gets exit 127 from those calls until it upgrades.
**Implements:** none. Documentation only; no item is claimed or amended.
**Safety class:** unclassified (the toolkit has no `.guardrails/config.yaml`).
**Verification:** `sh tests/run-tests.sh`; `check-ids.sh` and `check-trace.sh` against scratch copies of `main` and of the change, criterion no finding that `main` lacks.

Opened at the user's request of 2026-10-06 while `pr-s8dcmp` and
`ratchet-upgrade-mode` were open, by the user's decision of 2026-10-06
overriding AGENTS.md non-negotiable 4. `pr-s8dcmp` also edits
`upgrade-notes.md`, in its "Order of work" list; this change adds a section
elsewhere in the file and does not edit that list.

## Decisions

- D1. A section of its own, placed before "Why the prose files are refreshed
  with the scripts", rather than an item in "Order of work": the upgrade's
  copy of `scripts/*.sh` already adds the script, so there is no step to add,
  and the order-of-work list is the part `pr-s8dcmp` rewrites.
- D2. The section names the six skills that call the script
  (`grep -l find-items skills/*/SKILL.md`), the failure (exit 127, `No such
  file or directory`, measured with `sh -c` in a tree with no `.guardrails/`),
  that no gate reads the script (`grep -rl find-items scripts/` names only
  `find-items.sh` itself), and that it exits 2 on a config error
  (`gr_check_config` at `scripts/find-items.sh:58`; measured: an unknown key
  gives `guardrails: unknown config key(s): bogus_key`, exit 2).

### T1 — the section

**Files touched:** `skills/ratchet/references/upgrade-notes.md`
**Parallel:** no

1. Insert the section "The skills call `find-items.sh`" before
   "## Why the prose files are refreshed with the scripts".
2. Run `tests/.bats-core/bin/bats tests/skills.bats`; expected all ok.

## Progress

- T1 done by the dispatcher on 2026-10-06; documentation only, no test.
- Review round 1 (2026-10-06): REJECT on one medium finding. The section
  said the script exits 2 on every config error in both Exit 2 sections.
  Measured in a scratch project with the round 1 scripts: `list` and `show`
  exit 2 on a `doc_*` directory that is missing or holds no `*.md`, while
  `refs` exits 0 in both cases; all three exit 0 on an untracked ledger file;
  and the multi-unit message is at `scripts/lib.sh:1451`. Fixed: the section
  says where the script exits 2 and where it does not, says `install.sh`
  links by default, names the managed-block line and `GR_CONFIG` under a unit
  manifest, and the preamble covers a section about the skills.
- Review round 2 (2026-10-06): ACCEPT on three low findings, the last round
  under the low-severity rule. Fixed: the exit-2 paragraph names every config
  row of "Exit 2: config and layout" (measured on `dea6588`'s scripts: a
  column-zero list item, an orphaned list item and an empty `test_paths` each
  exit 2), and exit 127 is stated for every call with the message for the path
  form only. T1 was done by the dispatcher, not a task subagent: a one-file
  documentation edit with no test, as in earlier documentation-only plans.
