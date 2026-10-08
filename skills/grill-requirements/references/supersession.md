# Why supersession and retirement are recorded the way they are

Read this when a new item supersedes or retires an existing one, or before
proposing to change the supersession rules in `grill-requirements`.

## The old item stays where it is

A new requirement may supersede an old one, and a behavior may be dropped;
both are normal. Performing either by deletion is not. The old item keeps its
place in the file that defines it, so `check-trace.sh` still resolves every
reference to it, and the ledger still reads as a history.

## An out-of-force item owes no test

A REQ or LLR is out of force when its block contains a column-one
`superseded-by:` naming a REQ or LLR whose own block names it back with
`supersedes:` (the reciprocal pair), or a well-formed column-one `retired:`
(a date and a reason, below). `MISSING-TEST` skips it. A one-sided
`superseded-by:` or a malformed `retired:` exempts nothing. Its successor is
an ordinary item and owes its own test, written red-first like any other.

The old rule was the opposite. The superseded item kept its test, and that
test gained the new ID: `verifies:` with the old ID and the new ID on one
line. It was written when no script read `supersedes:` or `superseded-by:`,
so a one-line `superseded-by:` would have been an exemption anyone could
write. Keeping the test meant no gate had to change.

It contradicted `verify-before-merge` check 4. Adding the new ID to a test
that was already green re-annotates a test that was green from the start, and
that test has no `red -> green:` attestation for the new ID. A change could
satisfy one rule only by breaking the other, or by writing a duplicate test
to carry the ID. And when the meaning changed, the old test verified behavior
the software no longer has.

The pair is checked now, so it can carry the exemption. One half alone does
not earn it:

- a `superseded-by:` with no reciprocal `supersedes:` is
  `NON-RECIPROCAL-SUPERSESSION`, and the item still owes its test;
- a successor that is not defined is `DANGLING-REF`;
- a value with no readable item ID is `MALFORMED-SUPERSESSION`;
- a `retired:` needs a date and a reason, or it is `MALFORMED-RETIREMENT`;
- the chain must terminate. The successor must be a different item that is
  in force, validly retired, or itself out of force by a chain that
  terminates. An item that supersedes itself, or two items that supersede
  each other, are reciprocal on every edge, yet nothing is in force at the
  end: each stays in force, owes its test, and is `MALFORMED-SUPERSESSION`
  (`supersedes itself`, or `supersession cycle with no successor in force or
  retired`).

## A test of an out-of-force item fails

A `verifies:` line that names only out-of-force items is
`OUT-OF-FORCE-VERIFIES`: it verifies behavior the software no longer
promises. Delete the test, or point it at the item in force. A test pointed at
a successor is inherited: list it as `inherited: <test name> — from <old ID>`
in the dispatch report and the verification record. It is coverage, never
red-first evidence; the successor still needs a test watched failing.

A `verifies:` line that names an in-force item beside an out-of-force one is
history and stays silent, so a tree that followed the old rule stays green.

## Supersede or retire

Supersede when a successor states what the behavior became: a rewording, a
narrowing, a replacement. A reversal is a supersession too. An item that
says the software shall accept a message from any sender, replaced by one
that says it shall accept a message only from listed senders, is superseded:
the successor states the new behavior, and the successor's red-first test is
a message from an unlisted sender being refused. The old item's test, which
sent from an arbitrary sender and expected acceptance, now verifies the
opposite of the requirement. Delete it.

Retire when the behavior is gone and nothing states what it became. The form
is one column-one line in the REQ or LLR block:

    retired: 2026-10-08 — the export format is no longer offered

The date is a real calendar date at most one day ahead. The reason is any
non-blank text after the date and its separator (`—`, `-`, `:` or
whitespace). An item is retired or superseded, never both: an item with both
lines is `MALFORMED-RETIREMENT`. In the SRS and SAD files, a `retired:`
outside any REQ or LLR block is `ORPHAN-ANNOTATION`. A `retired:` in any other
ledger, on an RC, HAZ or PR, retires nothing and is not reported.

## An out-of-force item discharges nothing

An out-of-force item stops counting for the items that depend on it, not only
for its own test:

- a tested LLR that is out of force does not cover the REQs its
  `satisfies:` names;
- an `implements:` inside an out-of-force REQ's block does not implement the
  RC it names;
- an out-of-force exported REQ meets no `expects:`. The consumer's
  expectation stays `UNMET-EXPECTATION`, and the provider's
  `expectations against this unit` count keeps it open, until an exported
  REQ in force satisfies it.

Without this, retiring the only REQ that implements a risk control would leave
`UNIMPLEMENTED-CONTROL` green on a control no test verifies any longer. Before
the exemption the retired REQ still owed a test; after it, nothing does. So
retiring or superseding such an item makes the control or the parent REQ
report until a successor in force covers it.

`traces:` on an SDD and `mitigates:` on an RC are unchanged. Neither is a test
obligation. Another reference that names an old ID as history, in an
`affects:`, a `traces:` or a table row, stays a review job (`merge-change`
review checklist).
