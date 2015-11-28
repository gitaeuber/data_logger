#!/bin/sh
#
# delete channel from group
#

URL="https://127.0.0.1/vz/middleware.php"

# additional options for curl
# specify credentials, proxy etc here
CURL_OPTS="-k"

if [ $# -lt 2 ]
then
    echo
    echo "usage: $0 groupID channelID [channelID] [...]"
    echo
    exit
fi


GROUP=$1

while [ $# -gt 0 ]
do
    curl ${CURL_OPTS} -X DELETE "${URL}/group/$GROUP.json?uuid=$1"
    echo
    shift
done
