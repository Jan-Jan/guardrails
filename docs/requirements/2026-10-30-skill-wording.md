# Requirements: skill wording

**REQ-6p7jz3**: The software's check-traceability skill shall define a passing `check-trace.sh` run as exit 0 with no violation line, its `checked:`, `problems:` and `sources:` summary lines, warning lines and their `fix <RULE>:` lines allowed, and the verify-before-merge skill shall cite that definition at check 2.

**REQ-8kag74**: The software's develop-refactor skill shall state that a duplication fix leaves each test asserting what its name and `verifies:` claim.
