#!/bin/sh
# describes: check-ids.sh: the gr_check_config call is removed
awk 'BEGIN{d=0} /^gr_check_config$/ && d==0 {d=1; next} {print}' scripts/check-ids.sh > t && mv t scripts/check-ids.sh
