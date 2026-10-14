# Architecture guidelines

This file states the project's architecture preferences. An agent reads this
file and no other guidelines file. The compliance floor the skills state wins
any conflict, and a clause that contradicts it is a finding against the
clause. A project that changes a clause rewrites its reason and examples with
it.

## Domain

1. **A public interface speaks the glossary.** The names in a unit's or a
   software item's public interface are the terms `docs/CONTEXT.md` defines,
   never a synonym it lists under `_Avoid_`: exported functions and types,
   endpoints, events and messages, configuration keys, and the words the user
   reads. Names inside an item are not bound by this clause. Why: the
   glossary is where the project agreed what a word means, and an interface
   is where another unit, another team or the user reads it. Example: where
   the glossary defines "dose" and lists "amount" under `_Avoid_`,
   `schedule_dose(patient, dose)`, not `schedule_amount(patient, amount)`.

2. **A new public term enters the glossary in the same change.** A term a
   change adds to a public interface that `docs/CONTEXT.md` does not define
   is defined there by that change. Why: a term used before it is defined
   gets a meaning from its first caller, and the second caller may guess a
   different one. Example: a change that adds a `Titration` event adds the
   definition of "titration" to the glossary beside it.

3. **One term, one meaning, within a unit.** Inside one unit a term means one
   thing. Where two parts of the domain need the same word for different
   things, they are separate units or software items, each with its own
   definition. Two units may define a word differently. Why: a word with two
   meanings in one place is read with the wrong one, and the error passes
   every type check. Example: "order" as a purchase order in billing and as a
   prescriber's order in dosing lives in two units, not as one `Order` type
   with a `kind` field.

## Core and edges

1. **Rules live in a core that performs no I/O.** Decisions, calculations,
   validation and state transitions are in code that reads and writes no
   file, network, database, device, environment variable, clock or random
   source. The core takes what it needs as arguments and returns its result.
   Why: core code is tested with plain values and no test double, and its
   behavior cannot depend on the machine it runs on. Example:
   `next_dose_time(last_dose, schedule, now)` takes `now` as an argument
   instead of reading the clock.

2. **I/O lives in adapters at the edge.** Each access to a file, network,
   database, device, environment variable, clock or random source is in an
   adapter the project owns, and the core reaches it through an interface
   the core defines.
   The test fake at the boundary counts as the interface's second
   implementation. In a language with duck or structural typing, the
   interface is the parameter the core takes, with no declared type.
   Why: the edge is thin and the decisions are in the core, so most of the
   code is tested without I/O, and a change of storage or transport changes
   one adapter. Example: the core defines a `DoseLog` interface with
   `append(entry)`; a `SqliteDoseLog` adapter implements it.

3. **Dependencies point inward.** The core imports no adapter, framework or
   infrastructure module; adapters import the core. A framework's entry
   point, such as a request handler, is an adapter that calls the core.
   Why: a core that imports infrastructure cannot be built, tested or reused
   without it, and a framework upgrade then reaches every rule. Example: the
   core's `DoseLog` interface is imported by `SqliteDoseLog`; the core never
   imports the database driver.

4. **One adapter per third-party dependency.** A library, service or SDK
   outside the language's standard library is called from one adapter the
   project owns, not from the core and not from many places. Why: the
   dependency's failure modes, known anomalies and upgrades are handled in
   one place, and replacing it changes one file. Example: the HTTP client is
   used only in `PumpGateway`; the rest of the code calls `PumpGateway`.

## Boundaries

1. **An item is entered only through its interface.** Code outside a
   software item calls only what the item's interface exposes: no import of
   its internal modules, no access to its private state, no reliance on its
   storage layout or file format. Why: the interface is what the design
   describes and the tests verify, so a way around it bypasses both, and a
   change behind the interface breaks the caller. Example: billing calls
   `inventory.reserve(sku, count)`, not `inventory.store.rows[sku]`.

2. **An error crosses a boundary as the interface's own error.** An
   interface reports a failure in its own terms and keeps the error it
   received as the cause; it does not pass a dependency's error type
   through to its caller. Why: a caller that handles a dependency's error
   depends on that dependency, and a replacement then breaks it. Example:
   `PumpGateway` raises `PumpUnavailable` with the connection error as its
   cause, not the HTTP client's `ConnectionError`.

3. **One responsibility per item.** A software item has one responsibility,
   stated in one sentence without "and". Why: an item with two
   responsibilities changes for two reasons, and its requirements and tests
   mix concerns that belong apart. Example: `DoseScheduler` decides when a
   dose is due and `PumpDriver` delivers it, not one `PumpManager` that does
   both.

## Constraints

1. **A rule a tool can decide is an LLR with a test.** A structural rule that
   a tool can check, such as "this item performs no I/O" or "the core imports
   no adapter", is written as an LLR on the software item it binds and
   verified by an architecture test the project writes with its own tooling
   (an import linter or an architecture test library), annotated with that
   LLR. A rule that needs judgment stays a clause in this file. Why: a
   reviewer misses what a tool does not, and an LLR with no test fails the
   trace check. Example: "LLR: the dosing core imports no module that
   performs I/O", verified by an import linter's rule run in the test
   suite.

## Existing code

1. **These rules bind the structure a change writes.** Code a change adds or
   moves follows them. Existing code that breaks them is restructured only
   where a change edits it for its own reason, and only as far as that edit
   reaches; code that breaks them and is not edited is left alone. No change
   restructures a codebase wholesale for compliance. Why: a wholesale
   restructuring is a change of its own, with its own design and review, and
   mixing it into an unrelated change hides both. Example: a change that
   adds a clock read to a core function passes `now` in instead; the core
   function beside it that already reads the clock is left until a change
   edits it.
