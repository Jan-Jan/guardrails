# Problem report — "clean" in verify-before-merge excludes the warnings that merge-preflight passes

Found by review round 2 of `pr-s8dcmp` (finding-8). `affects:` names files,
because guardrails keeps no REQ/SDD/LLR ledger of its own.

**PR-furm2z**: `verify-before-merge` check 2 requires `check-trace.sh` to be "clean", which `check-traceability` step 3 defines as exit 0 "with only these two lines", but every run prints a third summary line, `problems:`, and may print warnings (`UNRESOLVED-PR`, `ACCEPTED-PR`, an `UNMET-EXPECTATION` inside its budget), so read literally no run is clean, while `merge-preflight.sh` passes TRACE on exit status alone.
affects: skills/verify-before-merge/SKILL.md (check 2), skills/check-traceability/SKILL.md (step 3), and ADR-3h4dky, whose upgrade completion check lets warnings stay listed in a plan.
opened: 2026-10-06
status: open
In practice every change in a project with an open problem item merges with
`UNRESOLVED-PR` lines printed, so the gates are read by exit status; the
skill text says otherwise. One definition of a passing `check-trace.sh` run,
covering the `problems:` line and the warnings and used by both skills, would
close it.
