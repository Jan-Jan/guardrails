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
  git, grep, awk, sed. Use `sed -i.bak` (then remove `.bak`) for portability.
- Every behavior change to a script requires a bats test in `tests/`.
- Skills live at `skills/<name>/SKILL.md` with `name` and `description`
  frontmatter. Skills are self-contained — they must not reference superpowers
  or other external skill suites.
- `scripts/` is the source of truth for the check scripts; `/ratchet` copies
  them into target projects. Never fork script logic into `templates/`.
- Plans and design docs live in `docs/plans/`, named `YYYY-MM-DD-<topic>.md`.
