#!/bin/sh


function usage {
        printf "valore non valido"
        exit 1
}


echo " Cosa vuoi fare?: (C)opia (D)eploy"
read opts

case "$opts" in

C)

echo " Inserisci la sorgente:(T)est (Q)su (P)roduzione "
read opts

case "$opts" in
   T)
        HOST="usqkbpll02n08" ;;
   Q)
        HOST="usqkbpll02n06" ;;
   P)
        HOST="usqkbpll01n01" ;;

   *)   usage ;;
esac


echo " Inserisci la data:"
read DATE

re='^[0-9]+$'

if ! [[ $DATE =~ $re ]];then
usage

fi

echo "inserisci la destinazione (T)est (Q)su (P)roduzione "
read opts

case "$opts" in
   T)
        DEST="usqkbpll02n08" ;;
   Q)
        DEST="usqkbpll02n06";;
   P)
        DEST="usqkbpll01n01";;

   *)   usage ;;
esac
if  [ $HOST == "usqkbpll01n01" ];then

ITA="/prod/dati/test/dati/meta/b3/UUD01/${DATE}/"
EST="/prod/dati/test/dati/meta/b3/UUD02/${DATE}/"
UCL="/prod/dati/test/dati/meta/b3/01187/${DATE}/"
UCF="/prod/dati/test/dati/meta/b3/01194/${DATE}/"
SW="/prod/dati/test/sw/prod/b3"

else

ITA="/prod/dati/meta/b3/UUD01/${DATE}/"
EST="/prod/dati/meta/b3/UUD02/${DATE}/"
UCL="/prod/dati/meta/b3/01187/${DATE}/"
UCF="/prod/dati/meta/b3/01194/${DATE}/"
SW="/prod/sw/prod/b3"
fi

if  [ $DEST == "usqkbpll01n01" ];then

ITA_DEST="/prod/dati/test/dati/meta/b3/UUD01/"
EST_DEST="/prod/dati/test/dati/meta/b3/UUD02/"
SW_DEST="/prod/dati/test/sw/prod/"
UCL_DEST="/prod/dati/test/dati/meta/b3/01187/"
UCF_DEST="/prod/dati/test/dati/meta/b3/01194/"

else

ITA_DEST="/prod/dati/meta/b3/UUD01/"
EST_DEST="/prod/dati/meta/b3/UUD02/"
UCL_DEST="/prod/dati/meta/b3/01187/"
UCF_DEST="/prod/dati/meta/b3/01194/"
SW_DEST="/prod/sw/prod/"

fi


echo " Cosa vuoi copiare?: (M)eta (S)oftware (A)ll "
read opts

case "$opts" in
   

	M)
	
	/usr/bin/ssh -T ${HOST} << EOSSH
	echo ${HOST}	
	scp -pr ${ITA} tusb3999@${DEST}:${ITA_DEST}
	scp -pr ${EST} tusb3999@${DEST}:${EST_DEST}
	scp -pr ${UCL} tusb3999@${DEST}:${UCL_DEST}
	scp -pr ${UCF} tusb3999@${DEST}:${UCF_DEST}
EOSSH
	 ;;
	

   S)	
	
	/usr/bin/ssh -T ${HOST} << EOSSH	
	echo ${HOST}
	scp -pr ${SW} tusb3999@${DEST}:${SW_DEST}
EOSSH
        ;;

   A)	

	/usr/bin/ssh -T ${HOST} << EOSSH
	echo ${HOST}
	scp -pr ${ITA} tusb3999@${DEST}:${ITA_DEST}
	scp -pr ${EST} tusb3999@${DEST}:${EST_DEST}
        scp -pr ${UCL} tusb3999@${DEST}:${UCL_DEST}
        scp -pr ${UCF} tusb3999@${DEST}:${UCF_DEST}
	scp -pr ${SW} tusb3999@${DEST}:${SW_DEST}
EOSSH
	;;

   *)   usage ;;
	esac
	;;

   D)	
	
	check="$(hostname)"
	if [ ${check} == "usqkbpll01n01" ];then
	
	DEPLOY="/prod/dati/test/dati/meta/b3/"
	DEPLOY_SW="/prod/dati/test/sw/prod/"
	else
	DEPLOY="/prod/dati/meta/b3/"
	DEPLOY_SW="/prod/sw/prod/"
	fi
	AZ="$(ls -lhart ${DEPLOY}|awk '{print $9}'|sed 's/[..]//g'|sed 's/ /""/g'|awk 'BEGIN { ORS = " " } { print }'|xargs -n1|tr "\n" " ")"	
	release=($(ls -lhart "${DEPLOY}"UUD01/|awk '{print $9}'|sed 's/[a-z,A-Z_,..]//g'|sed 's/ /""/g'|awk 'BEGIN { ORS = " " } { print }'|xargs -n1|tr "\n" " "))	     
	for i in ${release[@]};
	do
	(( $i > UPDATE || UPDATE == 0)) && UPDATE=$i

	done
 	echo "cosa vuoi deployare? (F)TMETA (S)w "
 	read opts

	case "$opts" in
F)
        for i in ${release[@]};
        do
        (( $i > UPDATE || UPDATE == 0)) && UPDATE=$i
	done
	echo "deploy FTMeta in corso.."
	
	for i in ${AZ[@]};
	do
	DEPLOY_1="${DEPLOY}$i/${UPDATE}"
        cp -f /tmp/deploy/dati/meta/b3/FT*-COMX.txt ${DEPLOY_1}
	done	
	;;
S)	
	echo "deploy Software in corso.."
	cp -rf /tmp/deploy/sw/prod/b3  ${DEPLOY_SW}
	esac
	;;
	esac
