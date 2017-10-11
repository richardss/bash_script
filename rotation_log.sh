#/bin/bash
######Path:########
loghome=/var/log/name_app
logarch=/var/log/rotate
##################
app=$1
date=`date +'%Y-%m-%d'`
applist=`find $loghome/* -type d | awk -F "/" '{ print " " $NF }'`

if [ -z "$1" ]
        then
        echo
        echo "Enter app name"
        echo "Usage: ./archive_logs.sh <app name>"
        echo "$applist"
        echo
        exit
fi

case "$app" in
app1|app2)
echo
echo "App name correct"
echo
sleep 2
;;
*)
echo
echo "App name wrong!"
echo "Usage:"
echo "$applist"
echo
exit
;;
esac

echo "Archiving $1 $date logs..."
echo
sleep 2

if [ -d $logarch/$app ]
        then
        echo "Destination path OK"
        echo
        sleep 2
        else
        echo "Destination path missing"
        echo "Creating..."
        echo
        sleep 2
        mkdir $logarch/$app
fi

#for log in $(ls -1 $loghome/*.zip && find $loghome/$app/ -type f -name "*.zip"); do ##the list of log from root and folder apps
for log in $(ls -1 $loghome/$app/*.zip)
do
        mv $log $logarch/$app/
done

cd $logarch/$app/
tar -czvf "$date".tgz *.zip > /dev/null
rm -f *.zip

finalfile=`ls -lh $logarch/$app/$date.tgz | awk '{ print $9 " " $5 }'`
echo "Archived $finalfile"
echo "DONE!!"
