# Requirements ledger

This directory is a per-change ledger: each merged change contributes one
dated file, `YYYY-MM-DD-<slug>.md`, named at merge time (the date is the
merge date, so `ls` reads chronologically). In a worktree, create
`DRAFT-<branch>-<slug>.md`; `merge-change` renames it. **Edit existing items
in the file that defines them** — definitions never move.

<!--
Item grammar (enforced by .guardrails/scripts/check-trace.sh):

  **REQ-NNNNNN**: The software shall <single, testable behavior>. (implements: RC-NNNNNN)

- REQ items are high-level requirements: system-observable behavior. The
  per-item "how" belongs to LLRs in the architecture ledger.
- One requirement per item; write it verifiable.
- `(implements: RC-...)` is required when the requirement realizes a risk
  control from the risk management file.
- A requirement with no parent in system needs is marked `satisfies: derived`
  and must be assessed in the risk ledger.
- Mint the ID when you write the item: run
  `.guardrails/scripts/new-id.sh <PREFIX>` and paste what it prints. The token
  is random and is allocated against nothing, so two worktrees and two GitHub
  PRs never contend for it. Never invent one by hand — the digit rule and the
  alphabet are what keep an ID from matching ordinary English.
- Every requirement must be verified by at least one test carrying a
  `verifies:` annotation (directly, or transitively via a tested LLR).
- IDs in the examples above use `NNNNNN` as a placeholder, and the examples
  are indented. Both matter. A real ID here would be a reference to an item
  that does not exist, reported as `DANGLING-REF` on every run; and a
  definition form at COLUMN ONE is judged whatever its body, so an example
  written flush left is reported as `MALFORMED-ID` — inside a fenced code
  block too, because no gate in the toolkit parses fences. Indent illustrative
  forms, or keep them inline in backticks. A real ID is six characters of
  `23456789abcdefghjkmnpqrstuvwxyz` with at least one digit; `new-id.sh` draws
  it for you.
-->
