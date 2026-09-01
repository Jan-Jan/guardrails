# ADR: a provider meets its consumers' safety class, or the consumer records segregation

Date: 2026-08-31
Status: accepted

## Context

Nothing compared unit classes across a dependency edge; IEC 62304 §5.3.5
permits a lower-classed item only when segregation is demonstrated.

## Decision

A provider classed below its highest consumer is exit 1
(`MISCLASSED-DEPENDENCY`) unless the consumer's config declares
`segregated_from:` naming the risk control or ADR that argues it.
`safety_class: TBD` on either end of an edge is exit 2.

## Why

An absolute floor pushes Class C rigor onto a logging library and drives it
out of the repo, losing the evidence; an advisory becomes something to scroll
past. The standard's own escape, recorded per edge, is the narrow gap between.
