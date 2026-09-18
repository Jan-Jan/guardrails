#!/bin/sh
# describes: check-ids.sh: call site #6 holds its own literal instead of the constant
# retired: c672c9f consolidated check-ids.sh from eight GR_SCAN_EXCLUDE call
# sites to three, so call site #6 does not exist
awk -v n=6 '{ if ($0 ~ /"[$]GR_SCAN_EXCLUDE"/) { c++; if (c == n) gsub(/"[$]GR_SCAN_EXCLUDE"/, "\":(exclude).guardrails/scripts\"") } print }' scripts/check-ids.sh > t && mv t scripts/check-ids.sh
