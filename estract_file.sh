#!/usr/bin/env bash

NDG=$(cat var.txt)
FILE="example.txt"
TEST="output.txt"
STAT1=$(ps uax|grep fgrep|wc -l)

if [ -z $FILE ];then
exit 0
fi
> $TEST
head -5 $FILE >> $TEST

for i in $NDG
do
STAT=$(echo $[100-$(vmstat 1 2|tail -1|awk '{print $15}')])
fgrep $i $FILE >> $TEST &

if [ "$STAT" -eq "80" ]; then
sleep 1

fi
done

while [ "$STAT1" -gt "1" ]; do
STAT1=$(ps uax|grep fgrep|wc -l)
sleep 3

done
tail -1 $FILE >> $TEST

exit 0


