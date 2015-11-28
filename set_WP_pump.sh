#!/bin/bash
#
#
# example conjob:
#
# * * * * *	root	/usr/local/bin/set_WP_pump.sh
#


LOG_FILE="/srv/wilo/$(date "+%Y-%m").log"
URL_BRINE="http://dimplex/http/index/j_sole.html"
CURL="/usr/bin/curl"
MBRTU="/usr/local/bin/mbrtu"
TTY="/dev/ttyUSB-wilo"
SED="/bin/sed"
BC="/usr/bin/bc"

#DEBUG=YES

### optimal temp of brine out [degrees Celsius x 10]
OPT_TEMP=45
### maximum speed [2x %]
MAX_SPEED=185
### minimum speed [2x %]
MIN_SPEED=32


DIMPLEX=($($CURL -s "$URL_BRINE"))
IN=${DIMPLEX[1]}
OUT=${DIMPLEX[2]}
DATE=$(date +%F\ %T)
WILO=($($MBRTU -Qd $TTY -a21 -tint -n10 -fi -r1))
RET=$?; test $RET -ne 0 && exit $RET
SPEED=($($MBRTU -PQd $TTY -a21 -tint -n1 -fi -r400))
#SPEED=($($MBRTU -PQd $TTY -a21 -tint -n1 -fh -r1))
RET=$?; test $RET -ne 0 && exit $RET


test "$DEBUG" && echo ${SPEED[2]}\ $OUT

#
#
### log data
#
#
echo "$DATE ${WILO[*]} ${SPEED[2]} $IN $OUT" >> "$LOG_FILE"

SPEED=($($MBRTU -PQd $TTY -a21 -tint -n1 -fh -r1))

### let OUT*=10
OUT=${OUT/.}


#
#
### set new speed
#
#
if [ $OUT -lt $OPT_TEMP -a ${SPEED[2]} -le $MAX_SPEED ]
then
    $MBRTU -Qd $TTY -a21 -tint -n$((${SPEED[2]}+10)) -f6 -r1
elif [ $OUT -gt $OPT_TEMP -a ${SPEED[2]} -ge $MIN_SPEED ]
then
    $MBRTU -Qd $TTY -a21 -tint -n$((${SPEED[2]}-10)) -f6 -r1
fi


#
#
### debug
#
#
if [ "$DEBUG" ]
then
    echo ${SPEED[2]}
    test "$DEBUG" && $MBRTU -d $TTY -a21 -tint -n1 -fh -r1
fi
