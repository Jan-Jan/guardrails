# ADR: guardrails runs per declared unit, not per directory

Date: 2026-08-31
Status: accepted

## Context

Every check script resolves the git toplevel and one config, so per-directory
use in a monorepo looks like it should work and does not — and the minimal fix
(per-unit configs plus unit-scoped scans) is indistinguishable from the first
tooth of a manifest design.

## Decision

A multi-unit repository declares its units in a root manifest
(`.guardrails/units.yaml`); every tracked path is a unit's or explicitly
disclaimed. Per-unit scoping is mandatory; the coupling gates (dependencies,
exports, class floor, impact set, expectations) are adopted per declared edge.

## Why

Discovery by convention cannot tell "not a unit" from "not yet ratcheted", and
a permanently unchecked per-directory mode is a per-gate off-switch in
disguise — while an empty `depends_on:` gives the same autonomy visibly.
