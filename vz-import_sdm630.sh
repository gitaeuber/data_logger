#!/bin/bash
#
# This is a simple bash script to read register dump logs
# from B+G E-Tech / Eastron SDM630Modbus powermeter to the volkszaehler project.
#
# call it similiar like this:
#
# vz-import_sdm630.sh [-] < logfile
#
# vz-import_sdm630.sh logfile [logfile2] [...]
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
#
# log file format is fix
# log file should be created with /this reads only the first 36 values):
# echo "$(date +%F\ %T) $(mbrtu -d$TTY -fi -r0 -n72 -tf32_dcba -a$ADDR)" >> "$LOG_FILE"
# 
# resulting line in log file looks like this:
# 2015-11-14 11:28:24 ADDR=11 REG=0 DATA=236.14:234.28:238.66:4.84:8.40:0.67:1142.66:1967.68:143.78:1143.47:1968.25:160.58:-43.18:-47.70:-71.51:1.00:1.00:0.90:-2.16:-1.39:-26.45:236.36:0.00:4.70:14.10:0.00:3254.11:0.00:3272.31:0.00:-162.39:1.00:0.00:-2.86:0.00:49.98
#
# the SDM630Modbus supports only 40 values (80 registers) to be read at once
# my SDM630Modbus supports 50 values (100 registers) to be read at once
# this script supports lines in the log file to contain all values (registers)
# to create such log file please use the log_powermeter.sh script
#
#
# the registers are documented here:
# http://bg-etech.de/download/manual/SDM630Register.pdf
#



## configuration
#
# middleware url
URL="https://127.0.0.1/vz/middleware.php"

# sdm630 register number => volkszaehler.org uuid
# Values to UUIDs
declare -A UUID

#UUID["Voltage L1"]=""
#UUID["Voltage L2"]=""
#UUID["Voltage L3"]=""
#UUID["Current L1"]=""
#UUID["Current L2"]=""
#UUID["Current L3"]=""
#UUID["Power L1"]=""
#UUID["Power L2"]=""
#UUID["Power L3"]=""
UUID["VA L1"]="f8c68ce0-8be8-11e5-b841-dde8adba2ad2"
UUID["VA L2"]="15f08280-8be9-11e5-bb59-bbbc9e4dc0f2"
UUID["VA L3"]="22641800-8be9-11e5-a7f7-c710fba73ebc"
#UUID["total Power"]=""
UUID["VA total"]="42a32a10-8be9-11e5-98bb-39ce85200261"


DATE=/bin/date
CURL=/usr/bin/curl
# additional options for curl
# specify credentials, proxy etc here
CURL_OPTS="-k"

# uncomment this for a more verbose output
#DEBUG=1
DEBUG_ONCE=$DEBUG+1

# ========= do not change anything under this line ==============
#
# register number = parameter number -1  (of documentation)
#
declare -A REGISTER
REGISTER["Voltage L1"]=0
REGISTER["Voltage L2"]=1
REGISTER["Voltage L3"]=2
REGISTER["Current L1"]=3
REGISTER["Current L2"]=4
REGISTER["Current L3"]=5
REGISTER["Power L1"]=6
REGISTER["Power L2"]=7
REGISTER["Power L3"]=8
REGISTER["VA L1"]=9
REGISTER["VA L2"]=10
REGISTER["VA L3"]=11
REGISTER["VA re L1"]=12
REGISTER["VA re L2"]=13
REGISTER["VA re L3"]=14
REGISTER["Power factor L1"]=15
REGISTER["Power factor L2"]=16
REGISTER["Power factor L3"]=17
REGISTER["Phase angle L1"]=18
REGISTER["Phase angle L2"]=19
REGISTER["Phase angle L3"]=20
REGISTER["Voltage avg"]=21
REGISTER["Current avg"]=23
REGISTER["Current sum"]=24
REGISTER["Power total"]=26
REGISTER["VA total"]=28
REGISTER["VA re total"]=30
REGISTER["Power factor total"]=31
REGISTER["Phase angle total"]=
REGISTER["Frequency"]=35
REGISTER["Energy import"]=36
REGISTER["Energy export"]=37
REGISTER["Voltage L1L2"]=100
REGISTER["Voltage L2L3"]=101
REGISTER["Voltage L3L1"]=102
REGISTER["Voltage LL avg"]=103
REGISTER["Current neutral"]=112
REGISTER["Energy import L1"]=173
REGISTER["Energy import L2"]=174
REGISTER["Energy import L3"]=175
REGISTER["Energy export L1"]=176
REGISTER["Energy export L2"]=177
REGISTER["Energy export L3"]=178
REGISTER["kVArh import L1"]=182
REGISTER["kVArh import L2"]=183
REGISTER["kVArh import L3"]=184
REGISTER["kVArh export L1"]=185
REGISTER["kVArh export L2"]=186
REGISTER["kVArh export L3"]=187

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

	if [ "${#COLUMNS[*]}" -ne 5 ]
	then
	    echo "${1//-*//dev/stdin} is not in power log format. Skipping!"
	    echo "${COLUMNS[0]} ${COLUMNS[1]} ${COLUMNS[2]} ${COLUMNS[3]}"
	    continue
	fi

	TS=`$DATE +%s000 -d "${COLUMNS[0]} ${COLUMNS[1]}"`

	for I in "${!UUID[@]}"
	do
	    if [ -z "${UUID[$I]}" -o -z "${REGISTER[$I]}" ]
	    then
		[ -n "$DEBUG_ONCE" ] && \
		echo "sensor $I is not mapped to an uuid! Add the mapping to the array." >&2
		continue
	    else

		DATA=${COLUMNS[4]#DATA=}
		DATA=( ${DATA//:/ } )
		REQUEST_URL="${URL}/data/${UUID[$I]}.json?value=${DATA[${REGISTER[$I]}]}&ts=${TS}${URL_PARAMS}${DEBUG:+&debug=1}"
		if [ -n "$DEBUG" ]
		then
		    echo -e "logging sensor:\t\t$I}"
		    echo -e "with value:\t\t${COLUMNS[${REGISTER[$I]}]}"
		    echo -e "at:\t\t\t${COLUMNS[1]} ${COLUMNS[2]}"
		    echo -e "with request:\t\t${REQUEST_URL}"
		fi

		$CURL ${CURL_OPTS} --data "" "${REQUEST_URL}" >&2
#		echo $CURL ${CURL_OPTS} --data "" "${REQUEST_URL}"
	    fi
	done

	echo -en "\r${COLUMNS[0]} ${COLUMNS[1]}"
	DEBUG_ONCE=""

    done < "${1/#-*//dev/stdin}"

    shift
    echo
done
