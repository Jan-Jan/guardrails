# Requirements ledger

This directory is a per-change ledger: each merged change contributes one
dated file, `YYYY-MM-DD-<slug>.md`, named at merge time (the date is the
merge date, so `ls` reads chronologically). In a worktree, create
`DRAFT-<branch>-<slug>.md`; `merge-change` renames it. **Edit existing items
in the file that defines them** — definitions never move.

<!--
Item grammar (enforced by .guardrails/scripts/check-trace.sh):

  **REQ-NNN**: The software shall <single, testable behavior>. (implements: RC-NNN)

- REQ items are high-level requirements: system-observable behavior. The
  per-item "how" belongs to LLRs in the architecture ledger.
- One requirement per item; write it verifiable.
- `(implements: RC-NNN)` is required when the requirement realizes a risk
  control from the risk management file.
- A requirement with no parent in system needs is marked `satisfies: derived`
  and must be assessed in the risk ledger.
- In a worktree, mint new items as **<PREFIX>-DRAFT-<branch>-<n>** — final
  numbers are assigned by finalize-ids.sh at merge time. Never hand-pick a
  final number.
- Every requirement must be verified by at least one test carrying a
  `verifies:` annotation (directly, or transitively via a tested LLR).
-->
