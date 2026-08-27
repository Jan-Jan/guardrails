# Developing guardrails

Guardrails is developed under its own rules. No exceptions — this repo is the
reference implementation of its own process.

## Non-negotiables

1. **All work happens in a git worktree.** Documentation and code alike. Never
   commit directly to `main`.
2. **Integration is a signed squash merge.** `main` receives exactly one signed
   commit per change. Intermediate worktree commits may be unsigned
   (`git -c commit.gpgsign=false commit`); the squash commit must be signed
   (`git commit -S`) and verified before the worktree is cleaned up.
3. **Run `tests/run-tests.sh` before any merge.** All bats tests must pass.

## Rules

- Scripts in `scripts/` are POSIX sh only: no bash-isms, no dependencies beyond
  git, grep, awk, sed. Use `sed -i.bak` (then remove `.bak`) for portability —
  BSD sed takes the suffix as a separate mandatory argument, so the bare
  `sed -i` eats the next word. `tests/portability.bats` enforces this.
- **Supported awk implementations: gawk, mawk, busybox awk, and BWK awk** (the
  `/usr/bin/awk` that ships with macOS, `awk version 20200816`). BWK awk is the
  strictest of the four and is the default on a stock macOS box, so a change
  measured only on gawk is not measured. Specifically: **a value carrying a
  literal newline must never reach `awk -v`** — BWK awk exits 2 before the
  program runs (`awk: newline in string ... at source line 1`), which is a gate
  that does not run rather than a gate that answers wrong. Flatten at the point
  of use. `tests/portability.bats` runs every script under a stub awk that
  reproduces this on any platform.
- The same caution applies to `date`: BSD `date` has no `-d`, and its `-v`
  adjustment carries its own sign, so a relative date needs both spellings
  (`tests/helpers.bash:days_ago`).
- Every behavior change to a script requires a bats test in `tests/`.
- Skills live at `skills/<name>/SKILL.md` with `name` and `description`
  frontmatter. Skills are self-contained — they must not reference superpowers
  or other external skill suites.
- `scripts/` is the source of truth for the check scripts; `/ratchet` copies
  them into target projects. Never fork script logic into `templates/`.
- Plans and design docs live in `docs/plans/`, named `YYYY-MM-DD-<topic>.md`.
