# Testing a user interface at its seams

Read this when the change has a user interface. It applies `SKILL.md` "Where
a test attaches" and `references/test-seams.md` to one, and adds rules of its
own on markup snapshots and visual regression.

## The interface

The REQ interface of a UI is what the user perceives and does, plus what the
application sends to the outside world. Components, props, hooks, store shape
and CSS classes are implementation: a test that names them breaks on a
refactor that keeps every behavior.

## Keep the UI layer thin

Put state, rules and transitions in a core that does not depend on the UI
framework: reducers, state machines, view models. That core has an interface
as well defined as a library's, and it is tested like one, with its
permutations and properties. Most of what makes a UI hard to test is logic
inside components.

## Feature tests through the DOM

- Find elements the way a user does: by accessible role, label and visible
  text, not by test identifier or class name.
- Render real child components, the real store and the real router.
- Fake only what is outside the codebase, plus the clock and randomness. A
  fake at the HTTP layer, by network interception, is a boundary fake under
  the same contract test as any fake.
  A service the project owns runs for real on the normal path
  (`references/test-seams.md`, "Services the project owns").

## Enumerate the states

List the states each screen can be in and test each: loading, empty, error,
partial, stale, offline, permission denied. A core written as a state machine
makes the list explicit, and the paths through it can be generated rather than
written by hand.

## What only a real browser shows

Keep a small suite in a real browser for what a simulated DOM cannot do: the
service worker lifecycle and its update flow, offline behavior, caching,
IndexedDB, storage quota, installation. For a progressive web app, offline is
the main error route, and a full storage quota is the robustness rule's
resource exhaustion.

## Snapshots and appearance

- **A markup snapshot carries no `verifies:` annotation.** It records markup,
  not behavior: it fails on a refactor that changes nothing a user sees, and
  passes a regression that the markup does not show.
- Visual regression verifies a REQ only where the REQ is about appearance
  itself, such as the color of an alarm.
