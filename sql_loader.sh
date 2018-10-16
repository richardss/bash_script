#!/bin/bash
export ORACLE_HOME="/opt/oracle/product/11.2.0.3_cl"
DATE=$(date +%Y%m%d%H%M%S)
app=$1
FILE="/$app/var.txt"

if [ -z $FILE ];then
echo "missing file!"
exit 1

else
echo "Loading...." 
{/swlocal/oracle/bin/sqlldr USERID=user/password@example.com:1521/example DATA=$FILE CONTROL=load_example.ctl} &> /dev/null

cp $FILE /repoloader/var_"$CLIENT"_"$DATE".txt

fi 
