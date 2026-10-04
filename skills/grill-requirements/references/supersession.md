# Why supersession is recorded the way it is

Read this when a new item supersedes or retires an existing one, or before
proposing to change the supersession rules in `grill-requirements`.

## The superseded item stays where it is

A new requirement may supersede an old one; that is normal. Performing the
supersession by deletion is not. The superseded item keeps its place in the
file that defines it, so `check-trace.sh` still resolves every reference to
it, and the ledger still reads as a history.

## The annotations are not exemptions

`superseded-by:` and `supersedes:` are annotations, and no gate exempts an
item because of them. The superseded item keeps its definition, so it still
requires a test: the MISSING-TEST gate walks every defined item and does not
read `superseded-by:`.

One test satisfies both items. The test that verified the superseded item
gains the new ID alongside the old, `verifies: <old ID>, <new ID>`. MISSING-TEST
is then clean for both, the history remains, and no gate has to change.

## Superseding is not retiring

Supersede when the behavior still exists in some form (a rewording, a
narrowing, a replacement), so that one test verifies both IDs truthfully.

Behavior that is gone is a retirement, a different operation. `check-trace.sh`
has no `superseded-by:` exemption, so a retired item still requires a test for
behavior that no longer exists. Adding that exemption to the gate is a
separate change with its own tests. Until that change is merged, a retirement
goes to the user as its own decision and is not recorded as a supersession.
