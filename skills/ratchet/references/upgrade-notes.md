# Upgrading the scripts in an existing project

Read this when `ratchet` updates `.guardrails/scripts/` in a project that
already has them, before the new scripts are copied in.

Each section below is a change in what the scripts accept. Most are shapes the
older scripts passed while a gate read less than it was configured to. None is
a new requirement, and there is **no compatibility flag**: an opt-out would be
a supported way to keep a false green. The one exception is an unrecognised
key: a project-local annotation was harmless before and is now rejected,
because a typo and an extension cannot be told apart.

## Order of work

1. Finish or discard drafts in flight. Run the old `finalize-ids.sh` one last
   time, or replace each `REQ-DRAFT-<branch>-<n>` token by hand with an ID from
   `new-id.sh`, and update any CI line that calls `finalize-ids.sh`. Do this
   before the new `scripts/` are copied and `finalize-ids.sh` is deleted
   ("Item IDs are random tokens" below states why).
2. Before copying the new `scripts/`, run `check-trace.sh` once and work
   through what it reports.
3. Run the sizing grep in "List-item annotations" below. What it prints is the
   whole migration for that rule.
4. After copying, run `check-trace.sh` again and work from the top. Config
   errors are reported before any gate runs, so each fix reveals the next.
5. Work through the sections below that report on the existing ledger:
   problem reports, derived assessments, supersession, `DANGLING-FILE` and
   list-item annotations.

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

## Item IDs are random tokens

An item gets its ID when it is written — `.guardrails/scripts/new-id.sh REQ`
prints `REQ-a3k9z2` — instead of a sequential number assigned at merge.
Existing sequential IDs keep working without conversion: every pattern in the
toolkit accepts both forms, and nothing renumbers an SRS.

* **Delete `.guardrails/scripts/finalize-ids.sh`.** `finalize-docs.sh`
  replaces it; it renames the change's draft ledger file and does nothing to
  IDs. Copying in the new `scripts/` leaves the old file behind, and
  `merge-change` step 3 would find a script that still tries to mint. Update
  any CI line that calls it.
* **Finish or discard drafts in flight before upgrading.** A
  `REQ-DRAFT-<branch>-<n>` token is a hard failure in `check-ids.sh` under
  every flag, because nothing will turn it into a real ID. Run the old
  `finalize-ids.sh` one last time, or replace each token by hand with an ID
  from `new-id.sh`.
* **`check-ids.sh --allow-drafts` and `--base` are rejected, not ignored.**
  The first is now `--allow-draft-files`, and it covers only ledger files with
  a draft name. The second referred to a gate that no longer exists: IDs are
  allocated against nothing, and the in-tree duplicate scan sees everything
  once `merge-change` step 1 has merged the base branch in. `UNANCHORED-DEF`
  and `SKIPPED-DUPLICATE-BASE` are gone with it.
* **`MALFORMED-ID` is new, and is exit 1.** It reports a line opening with a
  definition form whose body is not a valid ID, including a legacy
  `**REQ-01**:`, too short to have matched `[0-9]{3,}`. Such an item was
  invisible to every gate under the old scripts too. Give it a real ID.

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

`finalize-docs.sh` rewrites references to the files it renames, across the
ledger directories and the SOUP file, and prints each rewrite. `check-trace.sh`
reports `DANGLING-FILE` for a `DRAFT-*.md` reference in those files that names
no existing file. Links left dangling by earlier merges go red at the first
run; fix each by writing the merged file's dated name. Plans and verification
records are neither rewritten nor scanned.

## Writing rules in the managed block

The managed block contains a section, `## Writing: prose, names and messages`:
a list of words to replace, no metaphor, no anthropomorphism, active voice,
and the instruction not to match existing style where it disagrees. No check
script reads it and none is planned, so nothing goes red. A project that
upgrades the scripts and skips the block refresh never receives the rules.
Existing prose is not swept; the rules apply to what is written next.

## Why the prose files are refreshed with the scripts

The ledger READMEs, `.guardrails/templates/verification.md` and the AGENTS.md
managed block teach the grammar the scripts enforce, and nothing mechanical
reports when they drift apart. A skipped refresh produces a commit whose
AGENTS.md and `docs/problems/README.md` contradict each other about a required
field.
