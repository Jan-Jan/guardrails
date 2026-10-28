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

The pre-flight (steps 2 and 6c) runs the gates per unit:
`check-units.sh` with no flag once, then `check-ids.sh` and `check-trace.sh`
with `GR_CONFIG=<unit>/.guardrails/config.yaml` for **every unit in the
impact set**. Its `UNITS` output names the unit that failed or warned; fix it
there.

The rest is yours, per unit:

- dispatch each unit's `verify_commands` with its `GR_CONFIG` (steps 6a and 6b),
  for every unit in the impact set;
- write one `Tests:` trailer per `verify_commands` entry of each unit in
  the impact set at step 6b,
  `Tests: <unit>: <verify_commands entry> <passed>/<total>`, and one
  `Coverage:` per `coverage_command` of those units. A unit outside the
  impact set owes none; any count other than the one owed is refused
  (`TESTS`, `COVERAGE`). The one `Gate-tree:` trailer names the tree every
  unit's gate measured.

At step 5, the message's body also names the units touched and the impact
set. One branch, one squash, one message, however many units were gated.
