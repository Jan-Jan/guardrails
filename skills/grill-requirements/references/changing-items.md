# Why a changed or dropped item is deleted

Read this when an item is reworded, replaced or dropped, or before proposing
to change these rules in `grill-requirements`. ADR-k3nkv3 states the decision.

## Every item in a ledger is in force

The ledger states what the software does now. An item kept beside its
replacement is text an agent may take for the current rule. The signed squash
message that changed the item is the record of the change: `Items:` names
`old → new`, or the deleted ID and the reason.

So `check-trace.sh` reads no supersession. A `supersedes:`, `superseded-by:`
or `retired:` at column one, or after list markers, in any ledger file is
`SUPERSESSION-ANNOTATION`, and the run fails.

## Reworded, changed or gone

- **Reworded:** the behavior is the same, so the tests still verify it. Edit
  in place and keep the ID.
- **Changed:** a rewording that narrows, widens, replaces or reverses the
  behavior is a new behavior. It gets a new ID from `new-id.sh`; the old item
  is deleted. A test of the old behavior verifies something the software no
  longer promises.
- **Gone:** delete the item and give the reason under `Items:`.

The test is the behavior, not the wording: ask whether a test of the old item
still verifies the new one unchanged.

## Tests of a deleted item

A `verifies:` naming a deleted ID is `DANGLING-REF`. Delete the test, or point
it at the new ID. A test pointed at the new ID was green before the task, so
it carries no red-first evidence for the new behavior: list it as
`inherited: <test> — from <old ID>` in the dispatch report and the squash
message. The new item still owes its own red-first test (`verify-before-merge`
check 4).

## What depends on a deleted item

Deleting an item removes what it discharged. A REQ covered only through a
deleted LLR's `satisfies:` reports `MISSING-TEST`; an RC implemented only by a
deleted REQ reports `UNIMPLEMENTED-CONTROL`; a HAZ mitigated only by a deleted
RC reports `UNMITIGATED-HAZARD`; a consumer's `expects:` met only by a deleted
exported REQ reports `UNMET-EXPECTATION`. Change the items that depend on it
in the same change: a narrowed RC and the REQ that implements it each get a
new ID, and the new REQ names the new RC.

Any other reference to the deleted ID in a `doc_*` file or a strict path is
`DANGLING-REF` too: rewrite it to name the item in force, or remove it.
