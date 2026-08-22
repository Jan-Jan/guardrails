#!/bin/sh
# describes: finalize-ids.sh: call site #4 holds its own literal instead of the constant
awk -v n=4 '{ if ($0 ~ /"[$]GR_SCAN_EXCLUDE"/) { c++; if (c == n) gsub(/"[$]GR_SCAN_EXCLUDE"/, "\":(exclude).guardrails/scripts\"") } print }' scripts/finalize-ids.sh > t && mv t scripts/finalize-ids.sh
