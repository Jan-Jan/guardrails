# Scaffolding a multi-unit repository

Read this when `ratchet` step 1b found more than one unit, before step 2.3
or step 3.3 installs any file.

- `.guardrails/units.yaml` is at the repository root, copied from
  `templates/units.yaml` and filled in from the units interview.
- Each unit has `<unit>/.guardrails/config.yaml`, copied from
  `templates/config.yaml`, with its `doc_*` paths and `verify_commands`
  adjusted to that unit.
- There is no root `.guardrails/config.yaml`. A root config and a manifest are
  two authorities over one tree, and every gate exits 2.
- The scripts are at the root: `.guardrails/scripts/` serves every unit.
- The ledger skeletons (`docs/requirements/`, `docs/risk/`,
  `docs/architecture/` with `soup.md`, `docs/problems/`) are copied per unit,
  into `<unit>/docs/...`.
- `docs/verification/`, `docs/plans/`, `docs/adr/` and the interface glossary
  `docs/CONTEXT.md` are at the repository root.
- The step 4 safety-class interview runs once per unit, and each answer goes
  to `safety_class:` in that unit's config. The per-unit class is the input to
  the class floor (D5), and it is the interview most likely to be skipped.
- After the files are written, `.guardrails/scripts/check-units.sh` validates
  the manifest and every unit's config in one pass.
