#!/bin/bash
#
#
# log a register of one or more modbus devices to file
#
# example conjob:
#
# * * * * *	root	/usr/local/bin/log_powermeter.sh
#


LOG_FILE="/srv/power/$(date "+%Y-%m").log"
MBRTU="/usr/local/bin/mbrtu"
TTY="/dev/ttyUSB-power"
ADDR=11
DATA=( $($MBRTU -d$TTY -a$ADDR -fi -tf32_dcba -n100 -r0 -r100 -r200 -n82 -r300) )

echo "$(date +%F\ %T) ${DATA[0]} ${DATA[1]} ${DATA[2]}:${DATA[5]#DATA=}:${DATA[8]#DATA=}:${DATA[11]#DATA=}" >> "$LOG_FILE"
