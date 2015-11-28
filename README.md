# data_logger
scripts to log data from individual sources to logfile

and scripts to import this log file data into volkszähler

and scripts that might be useful when using volkszaehler



## APCUPSD

### log_apcupsd.sh
bash script to log apcupsd data to logfile

some values are ignored, because thay appear only under certain circumstances
* XONBATT only appear when power outage happened
* LASTSTEST appears after first selftest of apcupsd run time


### vz-import_apcupsd.sh
bash script to import data from log file created by log_apcupsd.sh



## Heat Pump Data

### vz-import_dimplex.sh
bash script to import log files created by network extension card of heat pump manager 
(e.g. Dimplex NWPM)



## Power Meter

### log_sdm630.sh
bash script to log data from (B+G E-Tech | Eastron) SDM630 modbus power meter


### vz-import_sdm630.sh
bash script to import data from log file created by log_sdm630.sh


## Weather data from Open2300 project
http://www.lavrsen.dk/foswiki/bin/view/Open2300/WebHome

### vz-import_hist2300.sh
bash script to import data from log file created by histlog2300 from open2300 project



## Various helpful scripts for volkszaehler

### vz-add2group.sh
add a channel to a group


### vz-del2group.sh
delete a channel from a group


### vz-del-from.sh
delete data values from a channel at a time stamp or a period of time

