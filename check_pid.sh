#!/bin/bash

proc="$(ps uax|grep PROCESS|grep -v 'grep'|awk '{print $2}'|head -n1)"
pid="$(ps aux|grep PROCESS|grep -v 'grep'|awk '{print $2}'|wc -l)"
pid2=$(($pid - 1))
lastlog=$(ls -lt /dir/log_*|head -n1|awk '{print $9}')
check="$(cat $lastlog|grep -w '###ERROR'|wc -l)"
if (( $pid2 > 1 ))

then

lastlog1=$(ls -lt dir/log_*|head -n1|awk '{print $9}')

echo "the process already active : $lastlog " >> $LOGFILE

tail --pid=$proc -f /dev/null

lastlog=$(ls -lt dir/log_*|head -n1|awk '{print $9}')

if [ -z $lastlog1 ]; then

touch $LOGFILE

fi

check="$(cat $lastlog|grep -w '###ERROR'|wc -l)"

if [ $check == 0 ]; then

   res1=0
   echo "OK"
   exit $res1
   else
   res1=200
   echo "ERROR"
   exit $res1
fi

fi






