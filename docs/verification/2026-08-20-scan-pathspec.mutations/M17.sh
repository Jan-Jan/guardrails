#!/bin/sh
# describes: check-trace.sh: call site #1 holds its own literal instead of the constant
awk -v n=1 '{ if ($0 ~ /"[$]GR_SCAN_EXCLUDE"/) { c++; if (c == n) gsub(/"[$]GR_SCAN_EXCLUDE"/, "\":(exclude).guardrails/scripts\"") } print }' scripts/check-trace.sh > t && mv t scripts/check-trace.sh
