# Problem reports — the report catalogue fell behind its script, and two gaps it exposed

Three items. The first was found on 2026-09-15 while reviewing this
change's own edits to
`skills/check-traceability/SKILL.md`. It is not this change's defect: it
shipped in `d8502d1` the day before, and this change merely opened the file
that shows it.

**PR-6d2jvt**: `skills/check-traceability/SKILL.md` contains the reference
catalogue of every report `check-trace.sh` can print, and three reports the
script emits have no row in it at all, while a fourth row tells the reader to
reject a value the script accepts.
affects: skills/check-traceability/SKILL.md, whose report table is the only
place an author is told what a gate finding means and how to answer it;
scripts/check-trace.sh, which emits `ACCEPTED-PR`, `MALFORMED-SUPERSESSION`
and `NON-RECIPROCAL-SUPERSESSION` — all three added by `d8502d1` — and whose
`MALFORMED-STATUS` message reads `expected open, accepted or resolved` while
the skill's row for it states `neither open nor resolved` and instructs the
reader to "Pick one of the two"; docs/problems/2026-09-15-class-b-report.md,
where `PR-4fwfjp` records the change that introduced `accepted` and names
`skills/resolve-problem` and the templates as what it had to update, but not
this catalogue.
opened: 2026-09-15
status: resolved

Measured, not inferred. Extracting the script's own report roster — the
`#   TOKEN …` lines of its header block — and the first cell of every
catalogue row gives 19 reports a default (single-unit) run prints against 20
documented rows, and exactly three of the 19 have no row: `ACCEPTED-PR`,
`MALFORMED-SUPERSESSION` and `NON-RECIPROCAL-SUPERSESSION`, the three
`d8502d1` added. (An earlier draft of this paragraph read "seven in the script
and four in the skill", which is the count of the problem-report family alone,
not of every report; the three named are the same either way.) The word
`accepted` appears nowhere in the skill at all.

The `MALFORMED-STATUS` row is the one that does harm rather than merely
omitting. An author who hits that report and consults the catalogue is told
their `accepted` is not a valid status and to pick `open` or `resolved` —
which is the ledger's only means of recording a ruling, removed by the
document that exists to explain it. The three missing rows leave an author
with a red gate and no entry to look up; this row sends them to fix a correct
item.

Root cause: `d8502d1` added three reports to `check-trace.sh` and changed a
fourth's accepted values, updating `skills/ratchet` (which contains the
upgrade note) and `skills/resolve-problem` and the templates, but not the
report catalogue in `skills/check-traceability`. Nothing gates the
correspondence between the reports a script can emit and the rows that
document them, so the omission was silent — the same shape as `PR-zt5c2v`,
where a form was prescribed by a skill and read by no script, running the
other way.

Resolved. `skills/check-traceability/SKILL.md` gained three rows —
`ACCEPTED-PR` (the roll-call line for a ruled item, why `disposition:` is
required on it, and why it is exempt from the two limits but not from the
roll-call), `NON-RECIPROCAL-SUPERSESSION` (the half-applied pair, with "add
the missing half, never delete the half that is present" as the remedy) and
`MALFORMED-SUPERSESSION` (a supersession annotation with no usable ID in it,
the reference-side twin of `MALFORMED-ID`) — and its `MALFORMED-STATUS` row
now states the script's three values and tells the author how to choose among
them instead of telling them to reject `accepted`.

The gate is `check-traceability: every report a single-unit check-trace.sh run
prints has a catalogue row` in `tests/skills.bats`. Both sides are extracted,
not listed: the script side is its header roster up to the
`# Scoped (multi-unit) runs add:` heading the script itself uses to separate a
default run's reports from a scoped run's, and the skill side is the first
cell of each catalogue row, so a report documented only by a passing mention
in another row's prose still reports as missing. A second scan asserts that
every report printed at an `echo`/`printf` site appears in that header roster,
so the roster the first comparison trusts cannot drift away from the script
while staying green, and floors on both set sizes rule out a vacuous pass from
an extraction that matched nothing. Before the fix it failed with
`reports check-trace.sh prints with no row in skills/check-traceability/SKILL.md:
ACCEPTED-PR MALFORMED-SUPERSESSION NON-RECIPROCAL-SUPERSESSION`.

One finding this item did not predict: the six reports only a scoped
(multi-unit) run prints — `NON-EXPORTED-REF`, `UNDECLARED-DEPENDENCY`,
`UNMET-EXPECTATION`, `INCOMPLETE-EXPECTATION`, `MISEXPORTED-ITEM` and
`EXPECTATION-BACKLOG` — have no catalogue row either. That is a second gap of
the same shape, from the units work rather than from `d8502d1`, and the test
above stops at the script's own scoped heading rather than pretending to cover
it. It is now `PR-judqb7`.

AMENDED 2026-09-16, because the paragraph above made a second claim that
was wrong, under a heading reading "Measured, not inferred". It stated the six
"are documented in no skill (only in `README.md` and the units plans)". Two of
them are documented in a skill — `skills/grill-requirements/SKILL.md` names
`UNMET-EXPECTATION` and `INCOMPLETE-EXPECTATION` — and three of them
(`INCOMPLETE-EXPECTATION`, `MISEXPORTED-ITEM`, `EXPECTATION-BACKLOG`) appear
nowhere in `README.md` at all. Found by the independent review, which grepped
for each of the six rather than for the set. The "no catalogue row" half is
correct and is what `PR-judqb7` records; the rest was an assertion about six
tokens made after checking some of them.

**PR-44ww7q**: `implements:` is read line-wise by `check-trace.sh` and
block-scoped by `gr_req_scan`, so the same keyword has two readers that
disagree about where it may appear, and only the line-wise one is documented as
unorphanable.
affects: scripts/check-trace.sh, whose comment at the orphan scan rules that
`mitigates:`, `implements:`, `verifies:` and `assesses:` "are read line-wise
by ids_matching, never against a block, so they cannot be orphaned" — true of
that script and not of the library; scripts/lib.sh, where `gr_req_scan` reads
`implements:` under a `cur != ""` guard, which is block scope, with no
`check_orphans` call covering it in either mode.
opened: 2026-09-16
status: open
Unit mode only: `gr_req_scan` is reached through the units machinery, so a
single-unit project cannot meet this. The consequence is bounded and is not a
false green in the default configuration, which is why it is recorded rather
than fixed inside a change about a different keyword. What it needs first is a
measurement nobody has made: whether an out-of-block `implements:` in a
unit SRS is counted by one reader and not the other, and which answer is
right. Named in the plan of `close-kw-asymmetry` as "a separate item, not this
one", and minted here because the independent review observed that a separate
item nobody mints is a sentence, not a record.

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
