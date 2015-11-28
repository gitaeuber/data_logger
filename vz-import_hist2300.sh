#!/bin/bash
#
# This is a simple bash script to read Ws2300 weatherstation history logs
# from open2300 and log their values to the volkszaehler project.
#
# call it similiar like this:
#
# vz-import_hist2300.sh [-] < logfile
#
# vz-import_hist2300.sh logfile [logfile2] [...]
#
# @copyright Copyright (c) 2011, The volkszaehler.org project
# @package controller
# @license http://www.gnu.org/licenses/gpl.txt GNU Public License
# @author Lars Täuber
# modifications from the original file log_open2300.sh
# @author Steffen Vogel
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


##
#  cronjob example
#
#  10 1 * * *	root	/usr/local/bin/vz-import_hist2300.sh /path/to/open2300/$(date +\%Y\%m\%d -d yesterday)-open2300.log 2>/dev/null && gzip -9 /path/to/open2300/$(date +\%Y\%m\%d -d yesterday)-open2300.log
#
##


## configuration
#
# middleware url
URL="https://127.0.0.1/vz/middleware.php"

# open2300 sensor id => volkszaehler.org uuid
# Values to UUIDs
declare -A UUID

#UUID["Tout"]=""
UUID["WindSpeed"]="b8c7bdc0-6286-11e5-b930-1f712530310b"


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
INDEX["DateTime"]=0
INDEX["Date"]=1
INDEX["Time"]=2
INDEX["Tin"]=3
INDEX["Tout"]=4
INDEX["DewPoint"]=5
INDEX["relHumIn"]=6
INDEX["relHumOut"]=7
INDEX["WindSpeed"]=8
INDEX["WindDir"]=9
INDEX["WDText"]=10
INDEX["WindChillTemp"]=11
INDEX["Rain"]=12
INDEX["AirPress"]=13

[ $# -eq 0 ] && set - "/dev/stdin"

if [ $DEBUG ]
then
    echo "enabling debugging output"
fi

while [ $# -gt 0 ]
do

    if [ ! -r "${1/#-*//dev/stdin}" ]
    then
	echo "$1 not readable"
	shift
	continue
    fi

    echo -e "reading logs from:\t${1/#-*//dev/stdin}"

    while read -a COLUMNS
    do

	DAY=${COLUMNS[1]}
	DAY=${DAY/Jan/01}
	DAY=${DAY/Feb/02}
	DAY=${DAY/Mar/03}
	DAY=${DAY/Apr/04}
	DAY=${DAY/May/05}
	DAY=${DAY/Jun/06}
	DAY=${DAY/Jul/07}
	DAY=${DAY/Aug/08}
	DAY=${DAY/Sep/09}
	DAY=${DAY/Oct/10}
	DAY=${DAY/Nov/11}
	DAY=${DAY/Dec/12}

	if [ "${COLUMNS[0]}" != "${DAY//-}${COLUMNS[2]//:}" ]
	then
	    echo "${1//-*//dev/stdin} is not in open2300 histlog format. Skipping!"
	    echo "${COLUMNS[@]}"
	    break
	fi


	TS=`$DATE +%s000 -d "$DAY ${COLUMNS[2]}"`

	for I in "${!UUID[@]}"
	do
	    if [ -z "${UUID[$I]}" -o -z "${INDEX[$I]}" ]
	    then
		[ -n "$DEBUG_ONCE" ] && \
		echo "sensor $I is not mapped to an uuid! Add the mapping to the array." >&2
		continue
	    else

		REQUEST_URL="${URL}/data/${UUID[$I]}.json?value=${COLUMNS[${INDEX[$I]}]}&ts=${TS}${URL_PARAMS}${DEBUG:+&debug=1}"
		if [ -n "$DEBUG" ]
		then
		    echo -e "logging sensor:\t\t$I}"
		    echo -e "with value:\t\t${COLUMNS[${INDEX[$I]}]}"
		    echo -e "at:\t\t\t${COLUMNS[1]} ${COLUMNS[2]}"
		    echo -e "with request:\t\t${REQUEST_URL}"
		fi

		$CURL ${CURL_OPTS} --data "" "${REQUEST_URL}" >&2
	    fi
	done

	echo -en "\r${COLUMNS[0]}"
	DEBUG_ONCE=""

    done < "${1/#-*//dev/stdin}"

    shift
    echo
done
