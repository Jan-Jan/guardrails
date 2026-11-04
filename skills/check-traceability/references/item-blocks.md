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

`ORPHAN-ANNOTATION` steps over a run of leads before it tests the keyword: a
bullet (`-`, `*` or `+`) or an ordered marker (a run of digits closed by `.`
or `)`), each followed by whitespace; a task-list box (`[ ]` or `[x]`)
followed by whitespace; and a blockquote marker (`>`), indented or not. So a
list-item, task-list or quoted annotation outside every block is reported,
and so is a `satisfies:`, `traces:`, `implements:` or `mitigates:` after such
a lead inside its item's block, where no reader takes it.

No column-one reader steps over a list marker. The fields read at column one
(`status:`, `opened:`, `disposition:`, `expects:`, `exported:`) are never
taken from a list item,
which is why a bulleted one inside a block is reported as a missing field
(`INCOMPLETE-PROBLEM`). The ID-list keywords `satisfies:`,
`traces:`, `implements:` and `mitigates:` are not taken from a list item
either, and the backstop reports one written that way inside the block (see
"Where an ID-list annotation starts" below).

- Bare indentation declares nothing. With no marker present the line is tested
  unchanged, which keeps the indented item grammar in the ledger templates
  inert.
- A bare number is not a marker; the `.` or `)` is required. `1 status: of the
  bus` is prose.

## The containment rule

The backstop must see at least what every reader sees. Do not widen a reader
to accept a form the backstop accepts. Every scalar reader takes the FIRST
occurrence in the block, so a reader that accepts the bullet form lets a quoted
annotation outrank the real one. A problem item that quotes
`- status: accepted` above its own `status: open` would read as accepted, and
its age would stop counting against the limits while the problem is still
open.

A backstop wider than the readers can only over-report. A reader wider than
intended answers with confidence and is wrong.

## Where an ID-list annotation starts

`satisfies:`, `traces:`, `implements:` and `mitigates:` start an annotation in
two places inside the owner's block: at column one, or anywhere on the item's
definition line, the inline form the templates ship
(`**LLR-…**: <behavior>. satisfies: REQ-…`). One rule, `gr_annotation` in
`lib.sh`, decides it for every reader. Nowhere else credits: not a list item,
a task-list item (`- [x] satisfies: REQ-…`), a blockquote, a table cell, an
indented line or a mention inside a sentence. Those forms are not listed by
the rule; they are outside it.

The owner's block is a REQ block for `satisfies: derived` and `implements:` in
`doc_srs`, an LLR block for `satisfies:` and an SDD block for `traces:` in
`doc_sad`, and an RC block for `mitigates:` in `doc_rmf`. A line outside every
block credits nothing. The backstop reports it at column one or after the
leads above; a table cell, emphasis or a mid-sentence mention outside a block
is read by nothing and reported by nothing.

Inside the owner's block, the backstop reports the keyword after any of the
leads above as `ORPHAN-ANNOTATION` (`<keyword> inside <ID> is not at column
one; no gate reads it`). That covers `satisfies: derived` on a REQ, which no
other gate requires: written as `- satisfies: derived` it would otherwise
leave the REQ an ordinary one, owed a test but never assessed as derived.
Where the item needs the annotation it also fails loudly at its own gate:
`UNSATISFIED-LLR`, `UNTRACED-DESIGN`, `UNIMPLEMENTED-CONTROL`,
`UNMITIGATED-HAZARD` or an unmet expectation. A table cell, emphasis or a
mid-sentence mention inside a block is reported by neither. Write every
annotation at column one or on the definition line.

## Supersession keywords

`supersedes:`, `superseded-by:` and `retired:` are read by no gate as a
field. Each, at column one or after the leads above, in or out of an item block,
is `SUPERSESSION-ANNOTATION`: delete the item it marks (ADR-k3nkv3).
