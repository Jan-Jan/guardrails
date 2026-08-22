#!/bin/sh
# describes: lib.sh: GR_SCAN_EXCLUDE widened back to .guardrails (pre-change value)
sed -i "s|GR_SCAN_EXCLUDE=':(exclude).guardrails/scripts'|GR_SCAN_EXCLUDE=':(exclude).guardrails'|" scripts/lib.sh
