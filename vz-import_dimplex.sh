#!/bin/bash
#
# This is a simple bash script to read Dimplex heat pump logs
# log their values to the volkszaehler project.
#
# call it similiar like this:
#
# vz-import_dimplex.sh [-] < logfile
#
# vz-import_dimplex.sh logfile [logfile2] [...]
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


##
#  cronjob example:
#
# 1 1 * * *	root	/bin/zcat /path/to/dimplex/log/$(date +\%Y_\%m/\%d.csv.gz -d yesterday) | /usr/local/bin/vz-import_dimplex.sh 2>/dev/null
#
##

## configuration
#
# middleware url
URL="https://127.0.0.1/vz/middleware.php"

# dimplex sensor id => volkszaehler.org uuid
# Values to UUIDs
declare -A UUID

UUID["State"]="9bfd5e50-6220-11e5-837b-83d7246a1998"
UUID["Tout"]="fde6f2a0-6386-11e5-bbe4-0b329b2bb1f5"
UUID["Htemp"]="5ba750d0-9621-11e5-b97a-0d39d686d5cb"
UUID["WWtemp"]="e6d6db10-6220-11e5-82c9-2babe3269b96"
UUID["BrineIn"]="4fe5c2b0-62a4-11e5-ae08-07d37ebb8661"
UUID["BrineOut"]="6a0d6ca0-62a4-11e5-a73a-83c499f9edda"

declare -A DEPEND
DEPEND["BrineIn"]="State"
DEPEND["BrineOut"]="State"


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
INDEX["State"]=41
INDEX["Tout"]=1
INDEX["Htemp"]=2
INDEX["WWtemp"]=3
INDEX["BrineIn"]=6
INDEX["BrineOut"]=7

[ $# -eq 0 ] && set - "/dev/stdin"

if [ $DEBUG ]
then
    echo "enabling debugging output"
    echo -e "reading logs from:\t${1/#-*//dev/stdin}"
fi

O_IFS="$IFS"
IFS=","

while [ $# -gt 0 ]
do

    unset COLUMN
    declare -A COLUMN

    if [ "$1" = "${1#-}" ]
    then
	if [ -r "$1" ]
	then
	    exec 3< "$1"
	    echo -e "\nworking on $1"
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

    if [ "${LINE[0]}" != "Type" ]
    then
	echo "${1/#-*//dev/stdin} is not in dimplex log format. Skipping!"
    else

	read -a LINE -u 3
	if [ "${LINE[0]}" != "Index" ]
	then
	    echo "${1/#-*//dev/stdin} is not in dimplex log format. Skipping!"
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

	    read -a LINE -u 3
	    if [ "${LINE[0]}" != "Name" ]
	    then
		echo "${1/#-*//dev/stdin} is not in dimplex log format. Skipping!"
	    else

		read -a LINE -u 3
		if [ "${LINE[0]}" != "Description" ]
		then
		    echo "${1/#-*//dev/stdin} is not in dimplex log format. Skipping!"
		else
		    while read -a LINE -u 3
		    do

			TS=`$DATE +%s000 -d "${LINE[0]//\//-}"`

			for I in "${!COLUMN[@]}"
			do
			    if [ -z "${UUID[$I]}" ]
			    then
				[ -n "$DEBUG_ONCE" ] && \
				echo "value $I is not mapped to an uuid! Add the mapping to the array." >&2
				continue
			    fi

			    if [ -n "${DEPEND[$I]}" ]
			    then
				[ "${LINE[${COLUMN[${DEPEND[$I]}]}]}" = "0" ] && continue
			    fi

			    REQUEST_URL="${URL}/data/${UUID[$I]}.json?value=${LINE[${COLUMN[$I]}]}&ts=${TS}${URL_PARAMS}${DEBUG:+&debug=1}"
			    if [ -n "$DEBUG" ]
			    then
				echo -e "logging sensor:\t\t$I}"
				echo -e "with value:\t\t${LINE[${COLUMN[$I]}]}"
				echo -e "at:\t\t\t${LINE[0]}"
				echo -e "with request:\t\t${REQUEST_URL}"
			    fi

			    $CURL ${CURL_OPTS} --data "" "${REQUEST_URL}" >&2
			done

			echo -en "\r${LINE[0]}"
			DEBUG_ONCE=""

		    done
		fi
	    fi
	fi
    fi

    exec 3<&-
    shift

done

IFS="$O_IFS"
