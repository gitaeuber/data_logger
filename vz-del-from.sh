#!/bin/sh
#
# delete data from time stamp [to time stamp]
#

URL="https://127.0.0.1/vz/middleware.php"

# additional options for curl
# specify credentials, proxy etc here
CURL_OPTS="-k"
DATE=/bin/date

if [ $# -lt 2 ]
then
    echo
    echo "usage: $0 channelID time-stamp-from [time-stamp-to]"
    echo "          time stamp format for 'date'"
    echo "          e.g. 2015-11-12 23:50:12"
    echo
    exit
fi



if [ $# -ge 2 ]
then
    FROM=$($DATE +%s000 -d "$2")
    TO=$($DATE +%s000 -d "$3")
    curl -X DELETE ${CURL_OPTS} "${URL}/data/$1.json?from=$FROM${3:+?to=$TO}"
fi
