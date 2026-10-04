# Item blocks, list markers and annotations no gate reads

Read this when an annotation is credited to the wrong item or reported where
you did not expect it, or before writing an annotation in a list, quote or
table.

## Why the block close is broader than the block open

A block opens only at a valid item definition but closes at any bold line with
an ASCII colon. Closing at fewer lines makes a line a reader takes for a header
into body text, so the annotations under it are credited to the item above: a
wrong answer, where a broader close only drops them. Four gates depend on the
close. `UNTRACED-DESIGN` and `UNSATISFIED-LLR` fire when they do *not* find
their annotation, so a close that is too early rejects correct documents.
`UNANALYZED-DERIVED` and `UNRESOLVED-PR` fire when they *do* find one, so a
close that is too late passes real violations.

A bold line with no ASCII colon never closes, because nothing distinguishes it
from an emphasised sentence inside an item body. The close is byte-wise, so it
behaves the same under every awk and every locale.

## List markers

`ORPHAN-ANNOTATION` steps over one or more leading list markers before it tests
the keyword: a bullet (`-`, `*` or `+`) or an ordered marker (a run of digits
closed by `.` or `)`), each followed by whitespace, indented or not. So a
list-item annotation outside every block is reported.

No reader steps over a list marker. A list-item annotation is never taken as a
value, which is why a bulleted annotation inside a block is reported
as a missing field (`INCOMPLETE-PROBLEM`, `MISSING-RECORD`).

- Bare indentation declares nothing. With no marker present the line is tested
  unchanged, which keeps the indented item grammar in the ledger templates
  inert.
- A bare number is not a marker; the `.` or `)` is required. `1 status: of the
  bus` is prose.

## The containment rule

The backstop must see at least what every reader sees. Do not widen a reader
to accept a form the backstop accepts. Every scalar reader takes the FIRST
occurrence in the block, so a reader that accepts the bullet form lets a quoted
annotation outrank the real one:

- a problem item that quotes `- status: resolved` above its own `status: open`
  drops out of the known-problem list at exit 0;
- a verification record declaring `branch: other-change` that quotes
  `- branch: my-change` becomes the record for `my-change`, a pass reported
  over a review that did not happen.

A backstop wider than the readers can only over-report. A reader wider than
intended answers with confidence and is wrong.

## `traces:` and `satisfies:` anywhere on the line

`gr_id_run` reads `traces:` and `satisfies:` anywhere on their line.
`templates/sad.md` puts the annotation on the definition line, so requiring
column one of this reader would reject the documented primary form and every
SAD written to it.

## Forms still not covered

The backstop steps over bullets and ordered markers, in runs, and nothing else,
while the gates match a keyword anywhere on its line. Every other form is
presumed live until measured. The forms known to be credited inside a block and
unreported outside one:

- a GFM task-list item, `- [x] satisfies: REQ-…`;
- a blockquote, `> satisfies: REQ-…`;
- a table cell;
- a mention inside a sentence;
- a `satisfies:` indented with no marker, which satisfies an LLR while the
  backstop does not read it.

`PR-h3wujj` is open for these. Until it is resolved, write every annotation
with no list marker, quote marker or indentation: at column one, or on the
item's definition line in the inline form the templates ship.
