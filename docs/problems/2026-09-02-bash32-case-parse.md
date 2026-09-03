# Problem report — finish-merge.sh does not parse on macOS /bin/sh

`affects:` names files rather than item IDs for the reason
`docs/problems/2026-08-27-macos-awk.md` gives: guardrails keeps no
REQ/SDD/LLR ledger of its own yet.

**PR-vh6cud**: `scripts/finish-merge.sh` fails to parse under macOS /bin/sh
(bash 3.2) — `syntax error near unexpected token ';;'` at the nested-worktree
guard — so every invocation exits 2 before any guard runs, and 11 tests fail
on macOS (`every script parses as POSIX sh` plus ten finish-merge tests),
while the same tree is green on a shell whose parser handles a case pattern's
unbalanced `)` inside `$(...)`.
affects: scripts/finish-merge.sh (the nested-worktree guard's case patterns
inside the command substitution), tests/portability.bats (the gate this adds)
— no item ID exists to name, see the note above.
opened: 2026-09-02
status: resolved
Root cause: bash 3.2's `$(...)` parser cannot carry a case pattern's
unbalanced `)`, and the nested-worktree guard put one there; the POSIX-optional
leading `(` is the documented escape. Fix: every case pattern in executable
shell now opens with `(` — a mechanical 78-line sweep — gated permanently by
`tests/portability.bats` "every case pattern in executable shell opens with a
parenthesis" (verifies: PR-vh6cud), which was watched red before the sweep;
the independent review then found that scan blind to one-line `case`
statements, so it was reworked into a segment scanner and the five surviving
one-liners swept.
Collision, recorded at integration: the same defect was independently found
and resolved as **PR-xyu6en** (docs/problems/2026-09-02-hardware-key-retrofit.md)
in the retrofit change that reached the base branch first — its fix carries
the three guard-4 parens with an explanatory comment, kept verbatim on the
merge. What this report resolves beyond it is the class, not the instance:
the tree-wide sweep and the segment-scanner gate that stop the next parenless
pattern from compiling into a `$(...)` anywhere.
