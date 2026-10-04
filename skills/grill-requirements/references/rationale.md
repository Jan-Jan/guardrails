# Why grill-requirements' rules are what they are

Read this when a rule in `grill-requirements` seems wrong for your case, or
before proposing to change one. Each heading names the section of the skill it
explains.

## The interview

- One question per message: several questions in one message are confusing
  to answer.
- A stress-test scenario names a concrete failure and asks for the guarantee.
  Example: "The pump loses power mid-bolus — what must the software guarantee
  on restart?"
- Class B and C: the answers to "what must happen when this fails?" are the
  requirements a happy-path interview omits.

## Probe before you write

- The probes are subagent dispatches so that the requirements ledger and the
  SAD do not enter the interview's context. The subagent returns IDs,
  summaries and `file:line` citations, which is all the interview needs.
- This skill never edits the SAD. The split between REQ items and LLRs keeps
  design decisions inside `design-architecture`, the skill that has the
  segregation and SOUP rules. ADRs offered here stay on the three-part test.

## Declaring a dependency

- A gap in the provider is a requirement of the consumer, so it gets
  requirement machinery. While the expectation is unmet, the provider's run
  reports the count of open expectations against it, so the team that owes
  the work sees it in its own gate.
- The gap is never a problem report in the provider's ledger: a problem report
  records an anomaly in existing behavior, and a need is not an anomaly.

## The glossary

- Two units that use one term with different meanings internally are not in
  conflict. "Dose" in an infusion unit and "dose" in a reporting unit are
  different concepts, and each unit's glossary defines its own. A conflict
  exists only where a unit glossary and the root glossary define one term
  differently, because the root glossary defines the terms the units share.
