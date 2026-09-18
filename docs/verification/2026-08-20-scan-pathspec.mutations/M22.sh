#!/bin/sh
# describes: finalize-ids.sh: call site #5 holds its own literal instead of the constant
# retired: scripts/finalize-ids.sh was deleted at c672c9f, so this call site
# has no file. Minting moved to new-id.sh and finalize-docs.sh; finalize-docs.sh
# contains no GR_SCAN_EXCLUDE call site, and new-id.sh's one surviving call site
# (new-id.sh:195, the collision scan) is mutated by id-tokens M36 and M10, so no
# coverage is lost by retiring this.
awk -v n=5 '{ if ($0 ~ /"[$]GR_SCAN_EXCLUDE"/) { c++; if (c == n) gsub(/"[$]GR_SCAN_EXCLUDE"/, "\":(exclude).guardrails/scripts\"") } print }' scripts/finalize-ids.sh > t && mv t scripts/finalize-ids.sh
