# Multi-unit repositories

Read this when `.guardrails/units.yaml` exists. The `merge-change` sequence
then runs **per unit over the impact set**, and the impact set is computed,
not judged:

```sh
.guardrails/scripts/check-units.sh --impact "refs/heads/$BASE..HEAD"
```

It prints one `<unit>\t<touched|dependent>` line per unit. Consume it
mechanically, and never hand-pick the unit list.

- It exits 2 on a changed path that no unit claims. Fix default mode's
  `UNCLAIMED-PATH` first; a partial impact set would read as complete.
- It maps a change under the root `.guardrails/` to every unit.

The pre-flight (steps 4 and 6c) runs the gates per unit:
`check-units.sh` with no flag once, then `check-ids.sh` and `check-trace.sh`
with `GR_CONFIG=<unit>/.guardrails/config.yaml` for **every unit in the
impact set**. Its `UNITS` output names the unit that failed or warned; fix it
there.

The rest is yours, per unit:

- dispatch each unit's `verify_commands` with its `GR_CONFIG` (steps 2 and 6),
  for every unit in the impact set;
- run `finalize-docs.sh` (step 3) once per touched unit, with `GR_CONFIG`
  pointing at each. A dependent has no drafts to rename.

At step 6b, the record also names the units touched, and the impact set,
beside its `branch:` line. One branch, one squash, one record, however many units were
gated.
