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
SED_IGNORE=( "XONBATT" "LASTSTEST" )



SED_IGNORE=("${SED_IGNORE[@]/%/\/d\'}")
SED_IGNORE=("${SED_IGNORE[@]/#/-e\'\/}")

if [ ! -e "$LOG_FILE" ] # first log - write logfile index
then
echo    LINE=$($APCACCESS | sed "${IGNORE[@]}" -e 's/ *: .*//' | tr '\n' \;)
    echo "${LINE%;}" >> "$LOG_FILE"
fi

exit
# XONBATT only appears when power was lost. it disturbs the log file format!
LINE=$($APCACCESS | sed -e '/XONBATT/d' -e 's/[^:]*: *//' -e 's/ *$//' | tr '\n' \; )
echo "${LINE%;}" >> "$LOG_FILE"
