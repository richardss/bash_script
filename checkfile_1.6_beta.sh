#!/bin/bash
#
#
#########
### RR ## 
################################
### script di controllo file ### 
################################
source enviroment.env
bash -n "$0" || exit 255
function usage {
    printf "Usage: $(basename $0) -p asset -s code -g group \n"
    exit 1
    }
    while getopts :p:s:g: opts; do
    case "$opts" in
    p)asset=$OPTARG ;;
    s)code=$OPTARG ;;
    g)group=$OPTARG ;;
    *)printf "ERR | Missing mandatory parameters\n"
    usage ;;
    esac
					  
while true
do
for i in "${#list[@]}"; do
if [ ${#check_files[@]} != $i ] && [ $TIME -le 18 ] ; then
     echo "attenzione sono presenti solo:" "${check_files[@]}"
     sleep 30 
     else
###############     
#eseguo COM.DQ#
###############
printf "$(date '+%Y-%m-%d %H:%M:%S') |file presenti inizio elaborazione del processo..\n"  > $LOGFILE
./DODComDataQuality.sh $client $DT_REF $LOGFILE >>  $LOGFILE  2>&1&
PID1=$!
wait $PID1
res_script=$?
if [ $res_script == 0 ]; then
res=0
echo " DODComDataQuality COMPLETATO CORRETTAMENTE - $client  ">>$LOGFILE
else
res=200
echo " DODComDataQuality IN ERRORE - $client ">>$LOGFILE
exit 1
fi
fi
done
done
