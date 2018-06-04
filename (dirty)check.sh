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
check_files(){
i=` ls -la $CSVFILES|grep -i -E 'ZINDG01|ZIRAP01|ZICOL01|ZISPC01'`
count=` $i|wc -l ` 
  if [[ "${i[@]}" != "ZINDG01" ]]; then
  echo " manca il file ZINDG01.csv"
  sleep 30
    else
      if[[ "${i[@]}" != "ZIRAP01" ]]; then
      echo " manca il file ZIRAP01.csv"
      sleep 30
        else
	 if [[ "${i[@]}" != "ZICOL01" ]]; then
	 echo " manca il file ZICOL01.csv"
	 sleep 30
	  else
	    if [[ "${i[@]}" != "ZISPC01" ]]; then
	     echo " manca il file ZISPC01.csv"
	     sleep 30
	       else
	       echo "check effettuato, tutti i file sono presenti"
	       fi
	       fi
	       fi
}
  
  
launcher_check(){
$env'check.sh' -s ${elab} -s ${code} -g ${client}
} 
if [ "$elab" == "local"];
  if [ -f $env/ZIASC01.csv ]; then
   printf "$(date '+%Y-%m-%d %H:%M:%S') | elaborazione del processo..\n"  > $LOGFILE
   ./DODComAssetClass.sh $DT_REF $LOGFILE >>  $LOGFILE  2>&1&
    PID1=$!
   wait $PID1
   res_script=$?
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
if [ "$elab" == "asset"];    
  if [ i  
   echo "files presenti, step successivo" && exit
   fi   
            
