#!/bin/bash
#
#
# log most output of the UPS to a log file
#
# example conjob:
#
# * * * * *	root	/usr/local/bin/log_apcupsd.sh
#


LOG_FILE="/srv/apcupsd/$(date "+%Y-%m").log"
APCACCESS=/sbin/apcaccess

# the changing number of values disturb the log file format!
# XONBATT only appears when power was lost
# LASTSTEST only appears when selftest was run
APC_IGNORE=( "XONBATT" "LASTSTEST" )



APC_IGNORE=("${APC_IGNORE[@]/%/\/d}")
APC_IGNORE=("${APC_IGNORE[@]/#/-e\/}")

if [ ! -e "$LOG_FILE" ] # first log - write logfile index
then
    LINE=$($APCACCESS | sed "${APC_IGNORE[@]}" -e 's/ *: .*//' | tr '\n' \;)
    echo "${LINE%;}" >> "$LOG_FILE"
fi

LINE=$($APCACCESS | sed "${APC_IGNORE[@]}" -e 's/[^:]*: *//' -e 's/ *$//' | tr '\n' \; )
echo "${LINE%;}" >> "$LOG_FILE"
