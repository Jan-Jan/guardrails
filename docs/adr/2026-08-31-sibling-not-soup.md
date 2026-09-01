# ADR: a consumed sibling unit is a supplied component, not SOUP

Date: 2026-08-31
Status: accepted

## Context

Units in one repository are only partially independent — one consumes
another's API. Recording the provider in the consumer's `soup.md` would have
shipped with zero new machinery.

## Decision

A consumer declares `depends_on:` and may trace only to the provider's
exported REQ items; the provider keeps its own SRS, class and tests.

## Why

SOUP treatment discards the requirement and test evidence the provider already
produces in the same tree, and no gate would notice a Class A library under a
Class C device. The evidence exists; incorporation by reference uses it.
