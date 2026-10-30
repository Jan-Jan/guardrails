# Problem reports — the report catalogue fell behind its script, and two gaps it exposed

Three items. The first was found on 2026-09-15 while reviewing this
change's own edits to
`skills/check-traceability/SKILL.md`. It is not this change's defect: it
shipped in `d8502d1` the day before, and this change merely opened the file
that shows it.

**PR-judqb7**: The six reports only a scoped (multi-unit) `check-trace.sh` run
prints have no row in the report catalogue, so a project running under a unit
manifest can hit a red gate whose finding is documented nowhere it would look.
affects: skills/check-traceability/SKILL.md, whose catalogue is the reference
for every report that script prints and which stops at the single-unit set;
scripts/check-trace.sh, which prints `NON-EXPORTED-REF`,
`UNDECLARED-DEPENDENCY`, `UNMET-EXPECTATION`, `INCOMPLETE-EXPECTATION`,
`MISEXPORTED-ITEM` and `EXPECTATION-BACKLOG` under a manifest; tests/skills.bats,
whose new catalogue gate deliberately stops at the script's own
`# Scoped (multi-unit) runs add:` heading, so this gap is outside a test that
would otherwise report it.
opened: 2026-09-16
status: open
Two of the six are documented in `skills/grill-requirements/SKILL.md`
(`UNMET-EXPECTATION`, `INCOMPLETE-EXPECTATION`) and three appear nowhere in
`README.md` — measured 2026-09-16 by grepping for each token rather than for
the set, after a first draft asserted all six were absent from every skill.
Writing the six rows is the work, and it is not a mechanical copy: a remedy
column has to say what the author should DO, and inventing that from the
script alone is how a catalogue row becomes worse than no row. Widening the
catalogue gate to the full 25-token roster is the same change and belongs
with it.

Deliberately NOT to be fixed here: the same correspondence is unchecked for
`check-ids.sh`, `check-review.sh` and `check-units.sh`, whose reports are
documented in their own skills. The test added here covers `check-trace.sh`
alone, because that is the pair this item measured; widening it is a change
of its own and wants its own measurement of what is already out of step.
