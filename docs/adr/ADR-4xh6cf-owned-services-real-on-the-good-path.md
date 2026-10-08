**ADR-4xh6cf**: A service the project owns runs for real in a REQ-level test of the normal case; only its failures may be faked.

Date: 2026-10-08
Status: accepted

## Context

A fake of a service drifts from the service it stands in for. When the project
owns that service (a backend, database or sync service the codebase contains
or the app configuration declares), a fake on the normal path means the
system's main behavior is verified against something the project never
ships. The robustness rule still needs dependency failures, which a real
service does not produce on demand.

## Decision

Test doubles stand in for a boundary of the codebase, not of the process. A
service outside the codebase may be faked behind an adapter the project owns,
and every fake has a contract test against the real adapter wherever the real
dependency is reachable. A service the project owns runs for real on the
normal path. Its failure cases may come from fault injection on the real
connection or from a fake, under the same contract test. A failure test may
fake the successes that precede its failure, where each of those successes is
verified against the real service by a normal-case test in the suite.

Decisions D4, D7 point 4, D8 and D9 of `docs/plans/2026-10-07-test-seams.md`.

## Cost

A project's REQ-level suite needs its owned services running in the test
environment: containers or the equivalent. How a project provides them is
its own test-environment decision.
