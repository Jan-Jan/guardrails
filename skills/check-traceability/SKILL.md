---
name: check-traceability
description: Run and interpret the guardrails traceability checker - orphaned requirements, unmitigated hazards, unimplemented controls, untraced design, dangling references. Use after documentation or code changes and always before merging.
---

# Check Traceability

**Announce at start:** "Using the check-traceability skill."

```sh
.guardrails/scripts/check-trace.sh              # traceability gates
.guardrails/scripts/check-ids.sh --allow-draft-files  # ID sanity while developing
```

Run from the repo root. Each violation is one line: `<RULE> <ID> (<detail>)`.
Fix the artifact, never the checker.

Every run ends with two summary lines — what it found, and what it read:

```
checked: REQ 90, HAZ 4, RC 7, SDD 20, LLR 23, PR 63
sources: srs 18, rmf 6, sad 4, soup 1, problems 35; strict 5, tests 3
```

*(Illustrative figures — your project's will differ.)*

(The document figures are file counts; `strict` and `tests` count configured
path entries, since one entry may be a directory or a pathspec.)

**Read both lines before believing the verdict.** Exit 0 with only these two
lines above it is clean. `REQ 0` on a project that has requirements, or
`rmf 0` on a project that has an RMF, means the checker found nothing and
proved nothing — a config or layout problem, not a pass. `checked:` alone is
not enough on its own: it counts items found anywhere in the tree, while
`sources:` counts the files the gate for those items actually opened.

**Where an item ends.** An item block **opens** at its definition form and
**closes** at the next markdown heading or the next **bold line containing a
colon**. That is the whole rule. `**ADR-0007**:`, `**Decision 7**:`,
`**LLR-overflow:**`, `**Rationale**:` and `**Note **bold** here**:` all close a
block, whether or not they are valid items and whatever their prefix.
`**21 of 35 inverted, 14 not.**` contains no colon and closes nothing.

The practical rule when writing an item body: a bold label with a colon starts
a new block, so put your annotations *above* it. The one limit: a bold line
with no **ASCII colon** never closes, because nothing distinguishes it from
the emphasised sentence that caused the original defect. (A full-width colon,
U+FF1A, is not an ASCII colon.) The close is byte-wise, so it behaves the same
under every awk and every locale.

Closing is deliberately broader than opening, and getting there took three
review rounds. Until 2026-08-22 any line starting `**` closed the block, which
made two gates reject correct documents (`UNTRACED-DESIGN` and
`UNSATISFIED-LLR` fire when they do *not* find their annotation) and two pass
over real violations in silence (`UNANALYZED-DERIVED` and `UNRESOLVED-PR` fire
when they *do*). Narrowing the close to valid item IDs fixed that and broke
something worse: a line a reader takes for a header became body text, so the
annotations under it were credited to the item *above* — a wrong answer where
the old rule merely dropped them. Narrowing it to *header-shaped* lines was the
same mistake in a narrower form. The rule that works is the one stated as a
subtraction: everything the old rule closed, minus the colon-free shape that
caused the defect. `check-ids.sh` separately reports `**REQ-abcdef**:` as
`MALFORMED-ID`.

`ORPHAN-ANNOTATION` covers what falls outside every block. It fires three ways:
before the first item in a file, under a heading with no item since, and —
the one most likely to reach a real ledger — **inside a block opened by a
prefix whose gate does not read that keyword**, such as a `traces:` line inside
an `**LLR-…**` block.

Its known limit was that it matched a keyword only at column one while the
gates matched one anywhere on the line, so a bulleted `- satisfies: REQ-…`
was credited inside a block but was not backstopped outside one. **A gate that
reads a keyword where the backstop does not is the case the backstop exists to
catch**, and on a bullet-style ledger it meant exit 0 with a derived item no
gate ever checked, or an open problem report absent from the known-problem
list.

That limit is **narrowed, not closed**, and what narrowed is the backstop
alone.
The backstop steps over one or more leading list markers — a bullet (`-`, `*`
or `+`) or an ordered marker (a run of digits closed by `.` or `)`), each
followed by whitespace, indented or not — before it tests the keyword. **Every
reader stays at column one.** So a list-item annotation is never taken as a
value, and is reported `ORPHAN-ANNOTATION` where it belongs to no item. **Bare
indentation still declares nothing**: with no marker present the line is tested
unchanged, which is what keeps the indented item grammar shipped in the ledger
templates inert. A bare number is not a marker either — the `.` or `)` is
required, so `1 status: of the bus` is prose and stays prose.

**What is still open, stated plainly**, because this rule was published as a
full closure three times and was not one. Two forms are stepped over — bullets
and ordered markers, in runs. **Every other form is unenumerated and presumed
live**: a GFM task-list item `- [x] satisfies:` was measured credited inside a
block and unreported outside one, after the second closure claim. The problem
item `PR-h3wujj` stays open for that reason, and the list below is what has
been found rather than what exists. It knew bullets alone, so an
ordered-list item reproduced the defect verbatim — `1. satisfies: REQ-…`
silent outside every block, credited inside one — and independent review
measured it and sent the change back. The backstop steps over list markers and
nothing else, while the gates match a keyword anywhere on its line. So a
blockquoted `> satisfies: REQ-…`, a table cell, or a mention inside a sentence
is still credited inside a block and still unreported outside one. That residue
is deliberate: `templates/sad.md` ships the annotation on the definition line,
so narrowing the gates to column one would reject the documented primary form
and every SAD written to it.

**The invariant is a containment, not an equality**: the backstop must see at
least what every reader sees. Widening in the other direction — the readers up
to the backstop — is unsafe, and was tried and rejected. Every scalar reader
here takes the FIRST occurrence in the block, so a reader that accepted the
bullet form let a quoted one outrank the real one: a problem item quoting
`- status: resolved` above its own `status: open` dropped out of the
known-problem list at exit 0, and a verification record declaring
`branch: other-change` that quoted `- branch: my-change` became the record for
`my-change` — a pass reported over a review that never happened. A backstop
wider than the readers can only over-report; a reader wider than it intends can
answer confidently and wrongly.

So a bulleted annotation INSIDE a block is a missing field, not a silent one:
the item is `INCOMPLETE-PROBLEM`, the record `MISSING-RECORD`, and the fix is
to drop the marker.

**`traces:` and `satisfies:` are still read anywhere on their line** by
`gr_id_run`, and that is deliberate rather than the remainder of the old
asymmetry: `templates/sad.md` ships the annotation ON the definition line, so
requiring column one of the reader would reject the documented primary form
and every SAD written against it. What changed is that the backstop now sees
the bullet form at all. The narrower residue is stated in `lib.sh` and is not
closed here: a `satisfies:` elsewhere on its line — mid-sentence, or indented
with no marker — still satisfies an LLR while this backstop never reads it.

**`MISPLACED-ITEM` is what connects the two.** Each of the six gated
prefixes is checked against the one document it may be defined in
(`REQ`→`doc_srs`, `HAZ`/`RC`→`doc_rmf`, `SDD`/`LLR`→`doc_sad`,
`PR`→`doc_problems`), so while that gate is green every item in `checked:`
is in a document some gate opened. It covers those six only — an item of an
extra declared prefix is still counted without being examined.

A misspelled or misplaced config key no longer belongs on that list: the
config is validated, and the shapes below are exit 2. Three things it still
does not catch, worth knowing rather than assuming:

- `doc_soup` is required by no prefix, so omitting it quietly narrows what
  `DANGLING-REF` scans — a zero in `sources:` is where that shows.
  (`strict_paths` was in this list until it was made mandatory: omitting it
  left the source scan walking nothing at exit 0.);
- `verify_commands` absent means the merge gate runs no commands and reports
  that nothing failed. The schema does not require it, because nothing in
  these scripts reads it;
- dropping a prefix from `id_prefixes` does **not** switch its gates off —
  `MISSING-TEST` is keyed on `test_paths` and the rest on the document lists,
  so all of them keep firing. What it removes is that prefix from `checked:`
  and from `DANGLING-REF`'s scope, so references to it stop being checked
  while its other gates continue to run.

`sources:` remains worth reading: a zero there for a document the project does
have means the key is absent, since a configured-but-empty ledger directory is
itself exit 2.

**Exit 2 is an environment error and always fatal**, because each of these
would otherwise let a gate pass without running:

| Message | Cause |
|---|---|
| `doc_rmf is configured as 'docs/risk', which does not exist` | A configured path that is absent. |
| `doc_rmf is configured as directory 'docs/risk', which contains no *.md files` | A ledger directory with nothing in it — including the case where the `*.md` files are in a **subdirectory**, since `doc_*` directories are read one level deep only. |
| `id_prefixes entry is not a bare identifier: PR[` | A prefix is interpolated into every scan pattern; a metacharacter makes the pattern invalid, and a scan that errors finds nothing — indistinguishable from a clean tree. |
| `unknown config key(s): doc_rmff` | A typo'd key. Nothing reads it, so the gate it was meant to configure silently never runs. |
| `config line(s) that are neither a comment, a top-level key, nor a '  - item' belonging to one` | A key that is not `identifier:` at column one (`strict-paths:`, ` strict_paths:`, `strict_paths :`); a list item at column zero; or a list item **orphaned** from its key by a column-one comment or a `---` separator above it. An orphan is ambiguous — it either vanishes with its list or is adopted by the block above — so it is rejected rather than guessed at. Commenting a list key out means commenting its items out too. |
| `config begins with a UTF-8 BOM` | The BOM makes the first key unreadable, i.e. silently absent. |
| `config has carriage returns inside a line` | A `\r`-only file is one single record to every reader here, so every key but the first is invisible. Save it with LF or CRLF endings. |
| `cannot read <config> — it exists but this user cannot open it` | Every scan below this would print nothing and pass vacuously, and the verdict would come from an unrelated check naming the wrong cause. |
| `config key(s) set more than once` | Every reader takes the FIRST occurrence and stops, while YAML takes the last — so one of the two is read by nobody. Appending a second `verify_commands:` below the first means the real suite never runs. |
| `config key(s) set to nothing` | A key with no value and no items reads as absent to the gate that uses it, and that gate then passes having examined nothing. Give it a value — deleting it is not the remedy, since absent is the same gate-off. |
| `config key(s) written in the wrong form` | A list key set to a scalar (`strict_paths: src`), or a scalar key set to `  - items` (`doc_soup:`). Read by nobody in either direction. |
| `config key(s) with a commented-out item` | `  - # make test` remains an item whose value starts with `#` — the `#` is stripped from a value only when whitespace precedes it, and the dash strip removed that. For a command key the shell reads it as a comment, so the step runs nothing and reports success. |
| `config key(s) with an item that has no value after its '-'` | Dropped by every reader, so the list that takes effect is shorter than the one written. |
| `strict_paths names no path` | It is the entire scope of the source scan. With none, a reference to an ID nobody defined is never looked for and the run exits 0 having examined no code. |
| `id_prefixes names no prefix with a traceability gate` | At least one of REQ, HAZ, RC, SDD, LLR, PR must appear. Extra prefixes alongside them are fine — `DANGLING-REF`, `DUPLICATE-ID` and ID finalization are keyed on the whole prefix list, so they are checked, just not by a gate of their own. Without any of the six the only checks left are those, and a config that also omits the document keys runs nothing at all. |
| `id_prefixes declares RC but doc_srs is not configured` | A declared prefix needs the documents its gates READ, which is not always where it is defined: `UNIMPLEMENTED-CONTROL` looks for a REQ that implements each RC, so RC needs `doc_srs`. |
| `id_prefixes declares RC but doc_rmf is not configured` | A prefix also needs the one document it may be DEFINED in, because `MISPLACED-ITEM` reads it. A control lives in the RMF, so `RC` needs `doc_rmf` as well — unconfigured, every control in the project would be misplaced. |
| `id_prefixes declares REQ/LLR but test_paths is empty` | Nothing would be searched for `verifies:`. |
| `strict_paths entry matches no file present in the working tree: src/*.rs` | A `strict_paths`/`test_paths` entry matching nothing. These are **git pathspecs** — a plain path, or a pattern like `*_test.sh` that git matches recursively. An entry matching nothing scans nothing, and an empty directory matches no file. |

Fix the config; never work around it by removing the prefix.

## Reading a finding

A run of `check-trace.sh` or `check-ids.sh` that completes prints one line per
rule that fired, after the violation lines and before the summary lines
(`check-ids.sh` prints no summary lines). A run that exits 2 part-way prints
none:

```
fix <RULE>: <what to do>
```

Follow that line. Where it ends `— see the script header`, the finding has
more than one cause, and the header of the script that printed it documents
each rule in full: `.guardrails/scripts/check-trace.sh` for the traceability
and problem-report rules, `.guardrails/scripts/check-ids.sh` for `DRAFT-ID`,
`DRAFT-FILE`, `DUPLICATE-ID` and `MALFORMED-ID`.

## When to run

- After any edit to SRS/RMF/SAD/SOUP or to tests.
- Always inside `verify-before-merge` and `merge-change` (without
  `--allow-draft-files` at the merge — no ledger file with a draft name may
  reach the base branch).
- In CI on every merge.
