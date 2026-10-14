# Upgrading the scripts in an existing project

Read this when `ratchet` updates `.guardrails/scripts/` in a project that
already has them, before the new scripts are copied in.

Each section below is a change in what the scripts accept, or in how the
skills use them. Most are shapes the older scripts passed while a gate read
less than it was configured to. None is a new requirement, and there is
**no compatibility flag**: an opt-out would be a supported way to keep a false
green. The one exception is an unrecognised key: a project-local annotation
was harmless before and is now rejected, because a typo and an extension
cannot be told apart.

## Order of work

1. Finish or discard drafts in flight. Run the old `finalize-ids.sh` one last
   time, or replace each `REQ-DRAFT-<branch>-<n>` token by hand with an ID from
   `new-id.sh`, and update any CI line that calls `finalize-ids.sh`. Do this
   before the new `scripts/` are copied and `finalize-ids.sh` is deleted
   ("Item IDs are random tokens" below states why). A change in flight with a
   `DRAFT-` ledger file renames it after the upgrade ("Ledger files are named
   at creation" below).
2. Before copying the new `scripts/`, run `check-trace.sh` once,
   keep its output for item 7, and work through what it reports.
3. Run the sizing grep in "List-item annotations" below. What it prints is the
   whole migration for that rule.
4. After copying, run `check-trace.sh` again and work from the top. Config
   errors are reported before any gate runs, so each fix reveals the next.
5. Work through the sections below that report on the existing ledger:
   problem reports, derived assessments, supersession, out-of-force items,
   `DANGLING-FILE`, list-item annotations and coverage credits read by block.
   Read "`ADR` is a declared prefix" before adding
   `ADR` to `id_prefixes`.
6. If `/ratchet` was ever run on macOS, run `check-review.sh --branch <name>`
   once per existing verification record ("On macOS, older versions of
   `check-review.sh` never executed" below).
7. Fix each failure, and list each new warning in a plan in `docs/plans/`;
   an upgrade is complete only then (`ratchet` Done when). A failure cannot
   be listed instead: the upgrade change merges through `merge-change`, whose
   gate needs `check-trace.sh` to pass. A warning is a finding printed without
   failing the run: `UNRESOLVED-PR`, `ACCEPTED-PR`, and an `UNMET-EXPECTATION`
   inside its age budget that implements no risk control (the header of
   `check-trace.sh` lists them). A new warning is one the run in item 2,
   with the old scripts, did not print;
   an older one is already recorded in its ledger.

## Exit 2: config and layout

| Exit-2 cause | Why it was never safe |
|---|---|
| A ledger directory with no `*.md`, or a configured path that was never committed | The gates reading it did nothing and the run still passed |
| A configured directory that is empty | It exists, but matches no file, so the gate reading it scanned nothing |
| An unrecognised key (`doc_rmff:`) | Nothing read it, so the gate it configured was never run |
| A key that is not `identifier:` at column one (`strict-paths:`, ` strict_paths:`, `strict_paths :`) | The config reader never saw it, so its value read as absent |
| A list item at column zero (`- src` unindented) | `cfg_list` never read those entries either |
| A list item orphaned from its key by a column-one comment or a `---` above it | Ambiguous: it either vanished with its list or was adopted by the block above, so `- src` under a commented-out `strict_paths:` could become a test path. **Commenting a list key out means commenting its items out too.** |
| A config saved with a UTF-8 BOM | The BOM made the first key unreadable, that is, absent |
| `id_prefixes` naming none of REQ/HAZ/RC/SDD/LLR/PR | No traceability gate of its own would run for any prefix. Extra prefixes alongside the six stay valid and stay covered by DANGLING-REF, DUPLICATE-ID and MALFORMED-ID — do **not** remove them |
| A declared `id_prefixes` entry whose document is unconfigured — `REQ`/`RC` without `doc_srs`, `HAZ`/`RC` without `doc_rmf`, `SDD`/`LLR` without `doc_sad`, `PR` without `doc_problems`, or `REQ`/`LLR` with an empty `test_paths` | Without it the gate for that prefix was skipped and the run still passed. `RC` needs both: `UNIMPLEMENTED-CONTROL` reads `doc_srs`, where the *requirements* are, and `MISPLACED-ITEM` reads `doc_rmf`, the only document a control may be defined in |
| An `id_prefixes` entry that is not a bare identifier | It is interpolated into every scan pattern; an invalid pattern matches nothing, which looks like a clean tree |

## Exit 2: the config schema's fatal rules

These are in `gr_check_config`, which runs before any gate, so each applies in
every gate. Each is a shape in which a key does not take effect as written:

| shape | example |
|---|---|
| a key set to nothing | `strict_paths:` with its items commented out — every scan then walks no path |
| a key in the wrong form | `strict_paths: src` (a list key as a scalar), or `doc_soup:` with `  - path` under it (a scalar key as a list) — read by nobody |
| a key set twice | a second `verify_commands:` appended below the first, which is what editing by appending produces: the real suite never runs |
| a list item with nothing after its `-` | dropped by every reader, so the list that takes effect is shorter than the one written |
| bare-CR line endings | a `\r`-only file is one single line to every reader here |

A CRLF file is now read correctly rather than truncated at its first blank
line. That is a fix, not a new rule: before it, every item below that line was
read by nobody. The diagnosis names the key and the shape.

## Exit 1 changes

These are easy to miss because they are not exit 2.

**`MISPLACED-ITEM`.** An item defined outside the document configured for its
prefix now reports. Before, it was counted in `checked:` while the gate keyed
on its own document never parsed its block. Move the definition into the
configured document; adding the stray file to `strict_paths` does **not** fix
it, because that widens reference scanning, not the document a gate opens. A
`doc_*` directory resolves to its `*.md` files one level deep, so a `.md` in a
subdirectory of one reports, and so does a `.txt` directly in it. A `doc_*`
configured as a single file resolves to that file whatever its extension.
Where the ID is illustrative text — an example in a plan, changelog or README
at column one — indent it or keep it inline; at the start of a line,
`MALFORMED-ID` reports a definition form whose ID is not valid. A project that
already keeps its items in the configured ledgers gets no report from this
gate.

**Pathspecs.** `strict_paths` and `test_paths` entries are handed to
`git grep` as pathspecs, not expanded by the shell first. Git's `*` crosses
`/` where a shell glob does not, so `src/*.c` now reaches into
subdirectories, and files there can raise failures. The entry is behaving as
written; narrow it if the wider scope is not what you want.

**SDD block end.** An SDD block ends at the next definition line or markdown
heading, as an LLR block already did. A `**Bold:**` aside or a fenced block
between an `**SDD-nnn**:` header and its `traces:` line reports
`UNTRACED-DESIGN`. Move the annotation onto the header line or directly
beneath it.

**Annotations are lists.** Only the IDs immediately after the keyword count.
`verifies: LLR-001 and REQ-002` credits `LLR-001` alone, so prose-joined lists
raise new `MISSING-TEST` / `UNMITIGATED-HAZARD` failures. Rewrite them as
`verifies: LLR-001, REQ-002`.

## `check-signing.sh` verdicts

Two verdicts that an older `check-signing.sh` could pass in default mode now
fail. Neither needs a project change; each removes a false green.

* **A signature git could not compute a verdict for fails** (PR-8zcc72).
  When `git log --format=%G?` fails for a commit that carries a signature,
  the commit now reads `UNVERIFIED ... (git could not compute a verdict for
  this signature)`, exit 1, in both modes. In default mode an older script
  printed `WARN-UNVERIFIED` with exit 0 for it (under `--strict` it already
  gave `UNVERIFIED`, exit 1), and only under load: a verifier that
  exits without reading its input makes `git log` die of SIGPIPE when it
  wins the race, while on an idle machine the same commit already failed. A
  merge gate that passed intermittently on such a verifier now fails every
  time; fix the verifier (`check-signing.sh --setup`).
* **A `gpgsig` line in a commit message is not a signature** (PR-qm5gfy).
  Only the commit header is read for one. An older script searched the whole
  commit object, so an unsigned commit whose message had a line starting with
  `gpgsig` read as signed: `WARN-UNVERIFIED`, exit 0, in default mode, and
  `UNVERIFIED`, exit 1, under `--strict`. Such a commit now reads `UNSIGNED`,
  exit 1, in both modes: under `--strict` the exit code is unchanged and
  only the verdict word changes.

## Item IDs are random tokens

An item gets its ID when it is written — `.guardrails/scripts/new-id.sh REQ`
prints `REQ-a3k9z2` — instead of a sequential number assigned at merge.
Existing sequential IDs keep working without conversion: every pattern in the
toolkit accepts both forms, and nothing renumbers an SRS.

* **Delete `.guardrails/scripts/finalize-ids.sh`.** Copying in the new
  `scripts/` leaves the old file behind. Update any CI line that calls it.
* **Finish or discard drafts in flight before upgrading.** A
  `REQ-DRAFT-<branch>-<n>` token is a hard failure in `check-ids.sh` under
  every flag, because nothing will turn it into a real ID. Run the old
  `finalize-ids.sh` one last time, or replace each token by hand with an ID
  from `new-id.sh`.
* **`check-ids.sh --allow-drafts` and `--base` are rejected, not ignored.**
  So is `--allow-draft-files` ("Ledger files are named at creation" below).
  `--base` referred to a gate that no longer exists: IDs are
  allocated against nothing, and the in-tree duplicate scan sees everything
  once `merge-change` step 1 has merged the base branch in. `UNANCHORED-DEF`
  and `SKIPPED-DUPLICATE-BASE` are gone with it.
* **`MALFORMED-ID` is new, and is exit 1.** It reports a line opening with a
  definition form whose body is not a valid ID, including a legacy
  `**REQ-01**:`, too short to have matched `[0-9]{3,}`. Such an item was
  invisible to every gate under the old scripts too. Give it a real ID.

## `ADR` is a declared prefix

The shipped `config.yaml` lists `ADR` in `id_prefixes`. An ADR is now an item:
its ID is minted with `.guardrails/scripts/new-id.sh ADR`, its file is
`docs/adr/ADR-<token>-<slug>.md`, and the file opens with the item line
`**ADR-<token>**: <the decision in one sentence>` (`grill-requirements`,
"ADRs"). Existing ADR files need no rename. `new-id.sh ADR` exits 2 until
`ADR` is in the project's `id_prefixes`. Before adding it, list the numbered
ADR headers and references:

```sh
git grep -nE 'ADR-[0-9]+'
```

What adding `ADR` changes, measured against the shipped scripts:

| Existing form | Report with `ADR` declared |
|---|---|
| A dated or numbered ADR file with a heading and no item line | Nothing; it is not an item |
| A header `**ADR-0007**:` (three or more digits) | A valid ID; references to it resolve |
| A header `**ADR-07**:` (fewer than three digits) | `MALFORMED-ID` from `check-ids.sh` |
| A reference `ADR-0007` with no item line that defines it | `DANGLING-REF` from `check-trace.sh` |
| A reference `ADR-07` | Nothing; the reference pattern does not match it |

For each `DANGLING-REF`, add the item line to the ADR file the number names,
which keeps the number as a valid ID, or mint a new ID and update each
citation. Give a `MALFORMED-ID` header an ID from `new-id.sh ADR`. The
`checked:` line of `check-trace.sh` gains an `ADR` field.

In a multi-unit repository, a decision that a unit cites by ID is in that
unit's `docs/adr/`, and the unit's config declares `ADR`. A root ADR is outside
every unit's scope, so a unit that cites it by ID gets `DANGLING-REF`. A
decision that spans units remains in the root `docs/adr/` and is cited by
path. A `segregated_from:` entry may cite it by ID, `(ADR-<token>)`, because
`check-units.sh` resolves it. Move each root ADR that one unit cites by ID into that unit.

`DANGLING-REF` does not scan `docs/adr/`, so an undefined ADR ID cited only
from another ADR is not reported. `check-ids.sh` and `check-trace.sh` do not
compare an ADR file name with the ID its item line defines. `check-units.sh`
compares them for a `segregated_from:` citation `(ADR-<token>)` only: the first
line of `docs/adr/ADR-<token>-*.md`, at the root or in the consumer unit, must
be `**ADR-<token>**:`, or it reports `INCOMPLETE-SEGREGATION`.

## The review record is checked

`check-review.sh` reads the verification record for the change under merge
and reports `MISSING-RECORD` when there is none, `INCOMPLETE-RECORD` when it
omits `reviewer:`, `verdict:` or `reproduced:`, and `UNDISPOSED-FINDING` when a
`**finding-N**:` block contains no `disposition:`.

* **Records already written are left alone.** Only the record for the branch
  under merge is read, so the schema applies from the next change on.
* **`reproduced:` is required and its value is never judged.** `reproduced:
  no — the root cause was measured directly, the end-to-end failure never
  reproduced` is a passing record. The field makes an absence of evidence a
  visible omission.
* **It is not a CI gate on the base branch.** There is no change under review
  there, so it exits 2. Run it at `merge-change` step 6c from the worktree, or
  in pull-request CI as `check-review.sh --branch <head>`.

**On macOS, older versions of `check-review.sh` never executed.** Their record scan
passed `awk -v` a value containing literal newlines, and the macOS awk (BWK,
`awk version 20200816`) rejects that with `awk: newline in string ... at source
line 1`, exit 2, before the program runs. Exit 2 reads as a setup error, so the
gate read no record and reported nothing about one. In a project where
`/ratchet` was run on macOS, `merge-change` step 6c has never executed. After
upgrading, run `check-review.sh --branch <name>` once over each record the
ledger contains. Do not assume they were fine.

## Problem reports: `status:` and `opened:`

This touches the existing ledger. `check-trace.sh` requires a column-one
`status:` on every problem report, and an `opened: YYYY-MM-DD` on every open
one. Work in this order, because the first finds items the other two do not:

1. `INCOMPLETE-PROBLEM … (no status: line in its block)` — an item whose state
   no gate could read. It counted as resolved and was absent from every
   merge's known-problem list. **Read it before you label it**; it may still be
   open.
2. `MALFORMED-STATUS` — `closed`, `wontfix`, `Open`. Pick `open` or
   `resolved`; an unrecognised status counted as resolved too.
3. `INCOMPLETE-PROBLEM … (open, no opened:)` — the backfill. Only open items
   need it. Where the real date is not recorded, use the date in the defining
   file's name (`docs/problems/YYYY-MM-DD-slug.md`).

The limits `problem_age_days` and `problem_open_max` ship set in
`templates/config.yaml`, but an existing config does not gain them from the
upgrade. Add them with the numbers your team will act on. Until then both print
as `none` in the `problems:` summary line on every run, so the unset limit
stays visible.

## The `accepted` status

Additive: no ledger uses `accepted` yet, because it used to be a
`MALFORMED-STATUS`. Nothing goes red and there is no backfill.

* **`accepted` means investigated and ruled on**: the project has decided the
  software is not changing. `check-trace.sh` prints it as `ACCEPTED-PR` with
  the ruling on the line, counts it in the `problems:` summary as
  `accepted N`, and exempts it from `problem_age_days` and `problem_open_max`.
  It is not exempt from the roll-call, so the decision is printed on every
  run.
* **`disposition:` is required on it.** Without it, `accepted` would be a
  one-word exemption from both limits for anyone looking at a red
  `PROBLEM-BACKLOG`. `accepted` with no `disposition:` or no `opened:` is
  `INCOMPLETE-PROBLEM`. `disposition:` is read at column one inside the item's
  block, first occurrence winning, like `status:` and `opened:`; an orphaned
  one is `ORPHAN-ANNOTATION`. The `opened:` on an accepted item is judged as a
  date as an open item's is: malformed or more than a day ahead is
  `MALFORMED-DATE`. It records when the problem was raised, which the
  roll-call prints.
* **It is not a way to clear a backlog.** If the count is red, write a ruling
  with a date you can defend, or resolve the item. `resolve-problem` §4 has
  the form.

The `problems:` summary line gained a field:
`problems: open N, accepted N, oldest …`. A CI step or record that greps for
`problems: open N, oldest` needs the new spelling.

## Supersession reciprocity

This can go red on an existing ledger. `merge-change` step 6a prescribes the
pair — `supersedes: <old ID>` on the replacement, `superseded-by: <new ID>` on
the replaced item — and older scripts read neither word.

* `NON-RECIPROCAL-SUPERSESSION <ID> (supersedes: …, which contains no
  superseded-by: …)`, and the mirror form. **Add the missing half**, at column
  one inside the named item's block. Never delete the half that is present: it
  is the only record that the replacement happened. Both annotations are
  lists, so one item may replace several predecessors.
* An orphaned `supersedes:` or `superseded-by:`, at column one in no item
  block, is `ORPHAN-ANNOTATION`.
* `MALFORMED-SUPERSESSION <ID> (supersedes: <value> — no item ID in it)`, or
  `(supersedes: has no value)`. `supersedes: the original dosing requirement`
  is prose, not a reference; give it the ID.
* `MALFORMED-SUPERSESSION <ID> (supersedes: <token> — not an item ID)` for one
  mistyped entry in a list that also contains good ones:
  `supersedes: REQ-m7dq3v, REQ-nope`. Prose and a parenthetical after the list
  end it and are never reported: `supersedes: REQ-m7dq3v (was REQ-001)` is
  clean.

The check covers reciprocity only. It does not sweep the tree for other
references to a superseded ID, because an `affects:` or `traces:` line may name
an old ID as history. That sweep stays a review job (`merge-change` step 6a).
`DANGLING-REF` already answers existence.

## Out-of-force items

A REQ or LLR whose block contains a column-one `superseded-by:` naming a REQ
or LLR whose own block names it back with `supersedes:` (the reciprocal pair),
or a well-formed column-one `retired:`, is out of force. It owes no test:
`MISSING-TEST` skips it. A one-sided `superseded-by:` or a malformed
`retired:` exempts nothing, and so does a supersession whose chain never
reaches a successor in force. The skills used to tell you to add the new ID to
the old item's test (`verifies:` naming both); they now say the successor
owes its own red-first test. This can go red on an existing ledger.

* `OUT-OF-FORCE-VERIFIES <file>:<line> (verifies: names only out-of-force
  items: <IDs>)`. The test verifies only behavior the software no longer
  promises. **Delete the test, or point it at the item in force** and list it
  as `inherited: <test name> — from <old ID>` in that change's verification
  record. A line that names an in-force item beside an out-of-force one is
  silent, so a ledger that followed the old dual-ID rule stays green; leave
  those lines alone.
* `MALFORMED-SUPERSESSION <ID> (supersedes itself)` and
  `MALFORMED-SUPERSESSION <ID> (supersession cycle with no successor in force
  or retired: <IDs>)`. Every edge of the chain is reciprocal, but it ends in no item in
  force or validly retired, so the item stays in force and also reports
  `MISSING-TEST` if untested. Point the chain at the item that states the
  behavior now, and remove the lines that make it loop.
* `MALFORMED-RETIREMENT <ID> (retired: <value> — needs a YYYY-MM-DD date and a
  reason)`. Write `retired: YYYY-MM-DD — <reason>` at column one in the item's
  block: a real date at most one day ahead, then any non-blank reason.
* `MALFORMED-RETIREMENT <ID> (retired: and superseded-by: <IDs> — an item is
  retired or superseded, not both)`. Keep the one that is true: the
  supersession if a successor states what the behavior became, the retirement
  otherwise, and delete the other line. Removing `superseded-by:` means
  removing the successor's `supersedes:` too, or the pair reports
  `NON-RECIPROCAL-SUPERSESSION`.
* In the SRS and SAD files, a `retired:` at column one outside every REQ or
  LLR block, an SDD block included, is `ORPHAN-ANNOTATION`. Move it into the
  item it retires; an SDD is not retired this way. A `retired:` in any other
  ledger, on an RC, HAZ or PR, retires nothing and is not reported.
* **An out-of-force item discharges nothing.** A tested LLR that is out of
  force no longer covers the REQs its `satisfies:` names, and an
  `implements:` in an out-of-force REQ no longer implements its RC. A REQ
  covered only through such an LLR now reports `MISSING-TEST`, and an RC
  implemented only by such a REQ reports `UNIMPLEMENTED-CONTROL`. Give the
  parent a successor in force that covers it, or test it directly. Where the
  RC itself was replaced when its REQ was, supersede the RC as well (next
  item). Never remove the `superseded-by:` to make the finding go away; that
  is the deletion the pair exists to prevent.
* **An RC is out of force by a reciprocal pair with another RC** (PR-x63ejd).
  Before this entry no script took an RC out of force. That had no effect
  until `dd411a1`'s D3 stopped an out-of-force REQ implementing its RC: from
  then, an RC superseded together with its only implementing REQ reported
  `UNIMPLEMENTED-CONTROL` with no honest remedy. Such an RC now owes no
  implementing REQ; its successor does. A pair between an RC and a REQ takes
  nothing out of force, and a `retired:` on an RC still retires nothing. An
  RC supersession that loops is `MALFORMED-SUPERSESSION`, as for a REQ.
* **An out-of-force RC mitigates nothing.** A HAZ named only by a superseded
  RC's `mitigates:` now reports `UNMITIGATED-HAZARD`. The successor dropped
  the hazard: name it in the successor's `mitigates:` if the successor
  controls it, or run `analyze-risks` for it.
* **A HAZ is out of force by a reciprocal pair with another HAZ**
  (PR-x63ejd). Such a HAZ owes no `mitigates:`; its successor does. Before
  this entry, a hazard reworded together with its control, the old RC naming
  the old HAZ and the new RC the new HAZ, reported `UNMITIGATED-HAZARD` on
  the old HAZ. A pair between a HAZ and an RC or a REQ takes nothing out of
  force, a `retired:` on a HAZ retires nothing, and a HAZ supersession that
  loops is `MALFORMED-SUPERSESSION`.
* **An out-of-force exported REQ meets no `expects:`.** In a monorepo, a
  consumer's expectation that only a retired or superseded exported REQ
  satisfies reports `UNMET-EXPECTATION` again, and the provider's
  `expectations against this unit` count includes it. Export a REQ in force
  that satisfies it.

A ledger that never wrote `retired:` gets neither `MALFORMED-RETIREMENT` form
and no orphaned `retired:`. `OUT-OF-FORCE-VERIFIES` appears on the first run
wherever a test still names only a superseded item, and the discharge
findings wherever coverage ran only through one.

## List-item annotations

Outside every item block, an annotation written as a list item is now
`ORPHAN-ANNOTATION`, as a column-one one already was. The keywords: `status:`,
`opened:`, `disposition:`, `traces:`, `satisfies:`, `supersedes:`,
`superseded-by:`, and under a unit manifest `exported:` and `expects:`.
`check-review.sh` reports an orphaned `disposition:` in a verification record
the same way.

* A marker is a bullet (`-`, `*`, `+`) or an ordered marker (digits closed by
  `.` or `)`), and a run of markers is stepped over, so `- 1. status:` reports
  as `- status:` does. A bare number is not a marker: `1 status: of the bus`
  is prose. Bare indentation declares nothing: `  status: open` is inert at any
  position.
* **Inside a block, nothing changes.** A list-item annotation was not read
  before and is not read now. An item whose only `status:` is a list item was
  `INCOMPLETE-PROBLEM` and stays so; a record whose only `branch:` is a list
  item is not that branch's record. No item changes state on upgrade day.
* **The fix:** move the line inside the block it belongs to and drop the
  marker, or, if it is prose about the form, put the form inline in backticks.
  The ledger templates already state that convention, and the shipped
  `templates/problems.md` follows it in one of its own sentences, so a project
  that copied that file into `docs/problems/README.md` must fix the same line
  in place.
* **The readers stay at column one by design.** The backstop must see at
  least what every reader sees. A reader wider than that takes the first
  matching line, so a quoted `- status: resolved` above an item's own
  `status: open` would drop the item from the known-problem list at exit 0.
* `traces:` and `satisfies:` are still read anywhere on their line, because
  `templates/sad.md` ships the annotation on the definition line —
  `**LLR-a3k9z2**: <behavior>. satisfies: REQ-m7dq3v`.

**Size it with one grep before you upgrade.** The pattern is the `gr_kw_lead`
rule written out, so what it prints is what the gate steps over:

    grep -rnE '^[[:space:]]*(([-*+]|[0-9]+[.)])[[:space:]]+)+(status|opened|disposition|traces|satisfies|supersedes|superseded-by|exported|expects):' docs/ templates/

`docs/` covers the verification records, where `disposition:` is the one
keyword this backstop reads.

**What remains unreported.** GFM task-list items are not covered:
`- [x] satisfies: REQ-…` is stepped over as far as the `-` only, so it is
credited inside a block and reported by nothing outside one. Every other
position `gr_id_run` accepts — task-list items, blockquote prefixes, table
cells, emphasis, a mid-sentence mention — is not enumerated and should be
presumed unreported. If your ledgers use a list form beyond the two named, the
gate stays silent on it as before.

## Coverage credits are read by block

`implements: RC-…` now credits the control only on a line inside a REQ block
in `doc_srs`, and `mitigates: HAZ-…` credits the hazard only on a line inside
an RC block in `doc_rmf`. The keyword may sit anywhere on that line; the
inline `(implements: RC-…)` and `mitigates: HAZ-…` on the definition line, as
the templates ship them, are unchanged. A block opens at the item's definition
line and closes at the next markdown heading, the next bold line that contains
an ASCII colon, or the end of the file. The older `check-trace.sh` read both
keywords line-wise, from any line of the document, credited to no item: a
control or hazard counted as covered by a line that belonged to no REQ or RC
(PR-44ww7q for `implements:`, PR-z7w5bf for `mitigates:`). This can go red on
an existing ledger.

* **Where it goes red.** An `implements:` or `mitigates:` line that sits:
  under a sub-heading or a bold line with a colon inside an item, such as
  `**Note:**` or `### Rationale`; before the first item of a file; under a
  heading after the item it was meant for; or in front matter. Each now
  credits nothing.
* **What you see.** `UNIMPLEMENTED-CONTROL <ID>` for an RC no REQ block now
  implements, and `UNMITIGATED-HAZARD <ID>` for a HAZ no RC block now
  mitigates. A line at column one, after any list markers, also reports
  `ORPHAN-ANNOTATION <file>:<line>`, which names the line to move. A
  mid-sentence mention or a front-matter line is reported by the coverage
  gate alone.
* **Under a unit manifest**, the `UNMET-EXPECTATION` severity reads the same
  records as `UNIMPLEMENTED-CONTROL`: an expecting REQ implements a risk
  control only through an `implements:` inside its own block, in a `doc_srs`
  file git does not ignore. The severity already read the block, so a stray
  line leaves it as it was. It changes in one case: an expecting
  REQ whose block lies in a git-ignored file, or in a ledger file outside
  `doc_srs`, is no longer risk-linked by the `implements:` in that block, so
  its `UNMET-EXPECTATION` no longer exits 1 on that ground. What the stray
  line adds is `UNIMPLEMENTED-CONTROL` when no REQ block implements that RC,
  and `ORPHAN-ANNOTATION` when it sits at column one.
* **The fix:** move the line into the block of the item that makes the claim,
  above any heading or bold-colon label in its body, or onto its definition
  line. If the line is prose about the form, put the form inline in backticks.
  Never add a REQ or RC only to hold a stray line: the finding is a control or
  hazard that no item claims.

**Size it before you upgrade.** This lists every line that names the keyword;
read each against the block rule:

    grep -rnE '(implements|mitigates):' <doc_srs> <doc_rmf>

## Derived assessments

This touches the existing ledger. `UNANALYZED-DERIVED` no longer passes a
derived REQ/LLR whose ID merely appears in the RMF; it requires a line
containing `assesses: <IDs>` in the RMF files. Every derived item goes red at
the first run until the passage that assesses it contains the annotation. The
cost is bounded by the count of derived items, one assessment can cover a
group, and the gate's line names the remedy. Put `assesses:` on the
assessment, never on a table row or a passing mention: that is the failure the
gate exists to detect.

## `DANGLING-FILE`

`check-trace.sh` reports `DANGLING-FILE` for a `DRAFT-*.md` reference in the
ledger directories and the SOUP file that names no existing file. Links left
dangling by earlier merges go red at the first run; fix each by writing the
name the file has now. Plans and verification records are not scanned.

## Ledger files are named at creation

* A change creates `docs/<area>/<YYYY-MM-DD>-<slug>.md`, dated the day it
  creates the file, and nothing renames it. `finalize-docs.sh` and the
  finalize step of `merge-change` are gone. Delete
  `.guardrails/scripts/finalize-docs.sh` (copying in the new scripts leaves it
  behind), and update any CI line that calls it.
* `check-ids.sh` rejects `--allow-draft-files` with exit 2, as it rejects
  `--allow-drafts`. Remove the flag from CI lines and `verify_commands`.
* `DRAFT-FILE` still fails a draft-named file, now at every run. For a change
  begun before the upgrade:
  `git mv <dir>/DRAFT-<branch>-<slug>.md <dir>/<YYYY-MM-DD>-<slug>.md`, dated
  the day the change created it
  (`git log --diff-filter=A --format=%ad --date=short -- <file>`). Then write
  the new name wherever a ledger cites it: `DANGLING-FILE` names each such
  reference.
* Two changes that pick one name meet as an add/add conflict at
  `merge-change` step 1; give this change's file a new slug.

## Prose rules removed from the managed block

The managed block no longer contains the prose rules: the word list, the
rules on metaphor, anthropomorphism and voice, and the instruction not to
match existing style. The code rules remain, as the section `## Code: names`:
no single-character names, no code golf, name in concrete terms. The naming
rule against the past participle (`write_timestamp`, not `written_at`) is
removed with the prose rules. No check script reads either section, so
nothing goes red. A project that wants the prose rules keeps them in
AGENTS.md outside the managed markers, because a block refresh replaces
everything between them.

## The skills call `find-items.sh`

`grill-requirements`, `design-architecture`, `analyze-risks`, `plan-change`,
`resolve-problem` and `merge-change` read ledger items with
`.guardrails/scripts/find-items.sh list`, `show` and `refs` instead of reading
ledger files whole. By default `install.sh` links the skills into
`~/.claude/skills`, so they change when guardrails is pulled, while a
project's `.guardrails/scripts/` changes only when it is upgraded. In a
project whose scripts predate `find-items.sh`, each of those calls exits
127, and the path form prints `No such file or directory`. The upgrade's copy
of `scripts/*.sh` adds the script, and the managed-block refresh adds the
AGENTS.md line that names it. No gate reads it, so nothing goes red.

`find-items.sh` runs the config check the gates run first, so it exits 2 on
every shape in "Exit 2: the config schema's fatal rules" and on every row of
"Exit 2: config and layout" that is about the config file. Of the rows about
ledger paths, `list` and `show` exit 2 on a `doc_*` path that does not exist
or contains no `*.md`, and `refs`, which reads no ledger file, does not. None
of the three checks that a ledger file is committed. Under
`.guardrails/units.yaml` a call with no `GR_CONFIG` exits 2, because there is
no root config to read; set `GR_CONFIG` to the unit's config, as for the
gates.

## Plans are pruned at merge: `prune_plans`

`merge-change` step 1 runs `.guardrails/scripts/prune-plans.sh` after the base
merge and commits what it changed. In each `docs/plans/*.md` file the change
adds or modifies, it replaces every fenced code block inside a task section (a
heading such as `### T1 —` or `## Task 2 —`) with one pointer line that names
the block's line count and quotes the task's `**Files touched:**` value where
it has one. The merged code is in the change's squash commit. Headings, prose,
fences outside task sections and a fence with a line that opens with
`red -> green` or `inherited:` are kept. No gate reads the plans' code, so nothing goes red.

An absent `prune_plans` is `on`, and so is a project with no config file.
`prune_plans: off` in `.guardrails/config.yaml` opts out: the script prints
`prune_plans: off, nothing pruned` and changes nothing. Any other value exits
2. This opt-out is not the compatibility flag ruled out above: pruning checks
nothing, so turning it off hides no failure.

The plans merged before the upgrade are pruned only when asked. In a change
worktree, run `sh .guardrails/scripts/prune-plans.sh --all --dry-run`, then
again without `--dry-run`, and merge the result as a change. A plan that a
tracked Markdown file cites as `<plan>:<line>`, at or after its first pruned
block, is left whole and named in a `left whole` line, because pruning would
move the cited line.

## Dispositions cite what they changed: `review_cite`

`check-review.sh` can check that each finding's disposition in the
verification record cites something the tree resolves. The check is off by
default: an absent `review_cite` is `off`, so an upgrade changes no result.
`review_cite: on` in `.guardrails/config.yaml` turns it on for every run,
including `merge-change` step 6c; `--cite` turns it on for one run. Any other
value of the key exits 2.

With the check on, a disposition must cite at least one of: a regular file,
not a directory or a symlink, that git tracks or lists as untracked and not
ignored, with or without `:<line>`; a test's whole name in backticks or double
quotes, as the test declares it in a file a `test_paths` pathspec matches (a
span some test file merely quotes is not one); or an item ID that
`find-items.sh show` finds. A citation on a wrapped line of the disposition
counts; one after a blank line does not. A disposition that opens with
`no change — ` (em dash) and gives a reason needs no citation, and
`no change needed.` is not that form. Any other disposition is
`UNRESOLVABLE-DISPOSITION <file>:<line>`, and the exit is 1. A `record`
finding cites the record's own path; for a `code`, `requirement` or
`guideline` finding the record being checked is not a citation.

A repository with `.guardrails/units.yaml` cannot use it yet, because the
record belongs to the repository while test paths and ID ledgers belong to
units. The key is read from the root `.guardrails/config.yaml` only, and a
manifest repository has none: `review_cite: on` in a unit's config is accepted
by the config check but never read, and `--cite` exits 2.

## Why the prose files are refreshed with the scripts

The ledger READMEs, `.guardrails/templates/verification.md` and the AGENTS.md
managed block teach the grammar the scripts enforce, and nothing mechanical
reports when they drift apart. A skipped refresh produces a commit whose
AGENTS.md and `docs/problems/README.md` contradict each other about a required
field.

## Test guidelines are a project file

The test rules `develop-change` stated are now preferences in a guidelines
file, apart from the floor the skills keep. An upgraded project with no
`docs/TEST_GUIDELINES.md` follows the installed default, which states the
rules `develop-change` stated before, so its behavior does not change and
nothing goes red. The default reaches `.guardrails/templates/` with the
scripts. Run `tailor-guidelines` for `TEST` to make the file the project's
own; on later upgrades, its upgrade mode walks each changed clause of the new
default before it is copied.

## Code guidelines are a project file

The managed block no longer has a `## Code: names` section. Its rules are
the Names clauses of the code guidelines default,
`.guardrails/templates/CODE_GUIDELINES.md`, which reaches the project with
the scripts, and the block refresh removes the section. An upgraded project
with no `docs/CODE_GUIDELINES.md` follows the installed default, which also
states Simplicity, Errors and Comments clauses. Run `tailor-guidelines` for
`CODE` to make the file the project's own. A project that kept naming rules
in AGENTS.md outside the managed markers moves them into
`docs/CODE_GUIDELINES.md`, so they have one home.

`develop-change` now dispatches each plan task under `develop-tdd`. The
deslop pass is gone: once every task branch is merged, one
`review-conformance` review runs per file `guidelines-file.sh TEST` and
`guidelines-file.sh CODE` print, all at once, and their findings are fixed
under `develop-refactor` (`CODE`) or `develop-tdd` (`TEST`).
`review-guidelines` is renamed `review-conformance`. `install.sh` links each
skill directory by name, so a pull neither adds the new skills nor removes
the old link: rerun `install.sh`, and delete the dangling `review-guidelines`
link it leaves. With `install.sh --copy`, a rerun skips every skill directory
that already exists (`SKIP`), so it adds the new skills and leaves every old
copy as it was: delete each guardrails skill directory it copied from the
skills directory (`~/.claude/skills`, or `CLAUDE_SKILLS_DIR`),
`review-guidelines` included, then rerun `install.sh --copy`. Until the
upgrade copies the scripts and templates,
`guidelines-file.sh CODE` exits 2 and the conformance reviews stop there. No
gate reads either guidelines file, so nothing goes red.

## The squash commit certifies the gate

* `finish-merge.sh` has a fifth guard. It refuses the cleanup, exit 1 with
  nothing removed and nothing deleted, unless the signed squash's message
  has exactly one `Gate-tree:` trailer and its value is the commit's own
  tree. `merge-change` step 7 writes it, the tree the step 2 gate measured,
  with a `Gate:` trailer per verify command and a `Base:` trailer. A squash
  written from an older copy of the skill has none: refresh the installed
  skills when the scripts are copied.
* git reads trailers only in a message's last paragraph. A
  `Co-Authored-By:` line after a blank line, or a wrapped trailer line that
  does not open with whitespace, leaves `Gate-tree:` in the body.
* The guard reads the trailer with
  `%(trailers:key=Gate-tree,valueonly,unfold)`, which needs git 2.22 or
  later; an older git leaves the placeholder unexpanded, and the guard
  refuses.
* A squash signed without the trailer stays on the base branch. Correct the
  message file: its `Gate-tree:` is the tree a gate measured. If no gate
  measured HEAD's tree, dispatch the gate on it first, as the guard 5 remedy
  of `merge-change`'s `references/cleanup-rejections.md` says. Then have the
  user run `git commit --amend -S -F <message file>`, which keeps the tree,
  and run `finish-merge.sh <branch>` alone; that file gives each rejection's
  remedy.
* `templates/verification.md` drops the gate table, the `Measured on:` line
  and the `Branched from` clause: a record names no commit or tree the gate
  measured, no base commit and no gate figure. Records already merged are left as they are. Remove any CI line
  that reads a record for `Measured on:`.
* `check-signing.sh` reads its verdict with `--no-show-signature`, so
  `log.showSignature` set to true no longer turns a good signature into
  `UNVERIFIED`.
