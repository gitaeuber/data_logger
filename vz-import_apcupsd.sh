#!/bin/bash
#
# This is a simple bash script to read Dimplex heat pump logs
# log their values to the volkszaehler project.
#
# call it similiar like this:
#
# vz-import_apcupsd.sh [-] < logfile [ 2>/dev/null ]
#
# vz-import_apcupsd.sh logfile [logfile2] [...] [ 2>/dev/null ]
#
# @copyright Copyright (c) 2011, The volkszaehler.org project
# @package controller
# @license http://www.gnu.org/licenses/gpl.txt GNU Public License
# @author Lars Täuber
# adaptation from file vz-import_hist2300.sh
#
#
# This file is part of volkzaehler.org
#
# volkzaehler.org is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# volkzaehler.org is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with volkszaehler.org. If not, see <http://www.gnu.org/licenses/>.
##


## configuration
#
# middleware url
URL="https://127.0.0.1/vz/middleware.php"

# apcupsd sensor id => volkszaehler.org uuid
# Values to UUIDs
declare -A UUID

UUID["Load"]="2ae31350-6627-11e5-ab1d-b376d13f71ec"
UUID["Temp"]="edf45420-6626-11e5-a762-8bbd1e8e1c8b"
UUID["TimeLeft"]=""
UUID["BattCharge"]="70604890-6627-11e5-83bc-7f8c7ddfecaf"
UUID["BattVolt"]="3fb84450-6627-11e5-88a3-d51bc1dd91b8"
UUID["LineVolt"]=""
UUID["LineFreq"]=""


DATE=/bin/date
CURL=/usr/bin/curl
# additional options for curl
# specify credentials, proxy etc here
CURL_OPTS="-k"

# uncomment this for a more verbose output
#DEBUG=1
DEBUG_ONCE=$DEBUG+1

# ========= do not change anything under this line ==============

declare -A INDEX
INDEX["Load"]="LOADPCT"
INDEX["Temp"]="ITEMP"
INDEX["TimeLeft"]="TIMELEFT"
INDEX["BattCharge"]="BCHARGE"
INDEX["BattVolt"]="BATTV"
INDEX["LineVolt"]="LINEV"
INDEX["LineFreq"]="LINEFREQ"
INDEX["Date"]="END APC"

declare -A CALC
CALC["Load"]='awk "{print \$1*450/100}"'	# 450 Watts max power of USV
CALC["Temp"]='sed "s/ .*//"'
CALC["TimeLeft"]='sed "s/ .*//"'
CALC["BattCharge"]='sed "s/ .*//"'
CALC["BattVolt"]='sed "s/ .*//"'
CALC["LineVolt"]='sed "s/ .*//"'
CALC["LineFreq"]='sed "s/ .*//"'

[ $# -eq 0 ] && set - "/dev/stdin"

if [ $DEBUG ]
then
    echo "enabling debugging output"
    echo -e "reading logs from:\t${1/#-*//dev/stdin}"
fi

O_IFS="$IFS"
IFS=";"

while [ $# -gt 0 ]
do

    unset COLUMN
    declare -A COLUMN

    if [ "$1" = "${1#-}" ]
    then
	if [ -r "$1" ]
	then
	    exec 3< "$1"
	    echo "working on $1"
	else
	    echo "$1 not readable"
	    shift
	    continue
	fi
    else
	exec 3<&1
	echo "working on stdin"
    fi

    read -a LINE -u 3

    if [ "${LINE[0]}" != "APC" ]
    then
	echo "${1/#-*//dev/stdin} is not in apcupsd log format. Skipping!"
    else
	for I in "${!INDEX[@]}"
	do
	    for J in "${!LINE[@]}"
	    do
		if [ "${INDEX[$I]}" = "${LINE[$J]}" ]
		then
		    COLUMN[$I]="$J"
		fi
	    done
	done

	while read -a LINE -u 3
	do
	
	    TS=`$DATE +%s000 -d "${LINE[${COLUMN["Date"]}]% *}"`

	    for I in "${!COLUMN[@]}"
	    do
		test "$I" = "Date" && continue	# we use it only for TS calculation

		if [ -z "${UUID[$I]}" ]
		then
		    [ -n "$DEBUG_ONCE" ] && \
		    echo "value $I is not mapped to an uuid! Add the mapping to the array." >&2
		    continue
		fi

		VALUE=$(echo ${LINE[${COLUMN[$I]}]} | eval ${CALC[$I]})

		REQUEST_URL="${URL}/data/${UUID[$I]}.json?value=$VALUE&ts=${TS}${URL_PARAMS}${DEBUG:+&debug=1}"
		if [ -n "$DEBUG" ]
		then
		    echo -e "logging sensor:\t\t$I}"
		    echo -e "with value:\t\t${LINE[${COLUMN[$I]}]}"
		    echo -e "at:\t\t\t${LINE[0]}"
		    echo -e "with request:\t\t${REQUEST_URL}"
		fi

		$CURL ${CURL_OPTS} --data "" "${REQUEST_URL}" >&2
	    done

	    echo -en "\r${LINE[${COLUMN["Date"]}]% *}"
	    DEBUG_ONCE=""

	done
    fi

    exec 3<&-
    shift

done

IFS="$O_IFS"
