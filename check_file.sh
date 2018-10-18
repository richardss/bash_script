#!/bin/bash
echo "please insert url address:"
read url
echo "please insert the name of file:"
read file

check_file_online=$(curl -s $url/$file|wc -l)
check_file_offline=$(cat ${file}|wc -l)

if [ "$check_file_online" != "$check_file_offline" ];then
echo "updating file please wait...."
curl -O $url/$file
else
echo "no update necessary, bye.."
exit 0
fi





