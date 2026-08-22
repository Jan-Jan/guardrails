#!/bin/sh
# describes: check-ids.sh: call site #2 holds its own literal instead of the constant
awk -v n=2 '{ if ($0 ~ /"[$]GR_SCAN_EXCLUDE"/) { c++; if (c == n) gsub(/"[$]GR_SCAN_EXCLUDE"/, "\":(exclude).guardrails/scripts\"") } print }' scripts/check-ids.sh > t && mv t scripts/check-ids.sh
