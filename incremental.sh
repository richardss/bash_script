#!/bin/bash
function usage {
        printf "Usage: $(basename $0) -p PARAMETER \n"
        exit 1
}
REPO=(REPO_CRE_TGET_I REPO_CRE_TGET_C)
DIR='$(/prod/dati/public/B3/T7/"$AZ"/"$DATA"/"${REPO[@]}"/"${REPO[@]}".*)'
#DATA=20${PARAMETER:0:6}
#AZ=${PARAMETER:6:5}
VAR_START=50
VAR_OPS=51

while getopts :p: opts; do
case "$opts" in
   p)
        PARAMETER=$OPTARG ;;
   *)
        printf "ERR | Missing mandatory parameters\n"
        usage ;;
esac
done
if [ -z $PARAMETER ] ; then
    usage
fi

DATA=20${PARAMETER:0:6}
AZ=${PARAMETER:6:5}

if [[ $AZ == D1166 && ${REPO[1]} == REPO_CRE_TGET_C ]]; then
PROG=$((VAR_START+1))
else
VAR_START=$VAR_OPS
PROG=$((VAR_START+1))
fi
for file in $DIR;
do  mv "${file}" /prod/dati/public/B3/$AZ/$DATA/_B3/"${REPO[@]}"/"${REPO[@]}"."${PROG}".txt
PROG=$((VAR_START+1))
done
