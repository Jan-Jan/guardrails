#!/bin/sh
# describes: lib.sh: GR_SCAN_EXCLUDE narrowed so the tooling is no longer excluded
sed -i "s|GR_SCAN_EXCLUDE=':(exclude).guardrails/scripts'|GR_SCAN_EXCLUDE=':(exclude).guardrails/scripts/nothing'|" scripts/lib.sh
