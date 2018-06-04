#!/bin/bash

#set -x
export env='~/MyDocuments/scripts/test/launcher/'
#source nc-func.bash
#source testloc.bash
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

check_files=` ls -la $CSVFILES|grep -i -E 'ZINDG01|ZIRAP01|ZICOL01|ZISPC01'`

launcher_check(){
$env'check.sh' -s ${elab} -s ${code} -g ${client}
} 
if [ "$elab" == "local"];
  if [ -f $env/ZIASC01.csv ]; then
   printf "$(date '+%Y-%m-%d %H:%M:%S') | elaborazione del processo..\n"  > $LOGFILE
   ./DODComAssetClass.sh $DT_REF $LOGFILE >>  $LOGFILE  2>&1&
    PID1=$!
   wait $PID1
   es_script=$?
   if [ $res_script == 0 ]; then
   res=0
   echo " processo completato correttamente  - ${client}  ">>$LOGFILE
   else
   res=200
   echo " elaborazione COM.ASC in ERRORE - ${client} ">>$LOGFILE
   fi
   else
   echo " attenzione file non presente"
   fi
if [ "$elab" == "asset"];then
  if [[ "${check_files[@]}" != "ZINDG01" ]]; then
    echo " manca il file ZINDG01.csv"
    sleep 30
    else
      if[[ "${check_files[@]}" != "ZIRAP01" ]]; then
      echo " manca il file ZIRAP01.csv"
      sleep 30
      else
      if [[ "${check_files[@]}" != "ZICOL01" ]]; then
      echo " manca il file ZICOL01.csv"
      sleep 30
      else   if [[ "${check_files[@]}" != "ZISPC01" ]]; then
      echo " manca il file ZISPC01.csv"
      sleep 30
      else
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
   fi  
   else
   echo "files non presente"
   fi
   fi
   fi   
   fi       
