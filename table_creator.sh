#!/bin/bash

val=3
val1=1
cons="$(cat file.txt|awk '{ print substr($0,66,10)}'|sed 's/ //'|awk -F '[.]' '{print $1}'|wc -l)"

while [ $val -lt ${cons} ]
do
cons1="$(cat file.txt|awk 'NR == '$val'{ print substr($0,66,10)}'|sed 's/ //'|awk -F '[.]' '{print $1}')"
control="$(cat file.txt|awk 'NR == '$val' { print substr($0,66,10)";"substr($0,81,4)";"substr($0,90,4)";"substr($0,45,17)";   ;"substr($0,131,3)}')"
control1="$(cat file.txt|awk 'NR == '$val' { print substr($0,66,10)";"substr($0,81,4)";"substr($0,90,4)";"substr($0,45,17)";"substr($0,150,3)";"substr($0,131,3)}')"
echo $val
control2="$(cat file.txt|awk 'NR == '$val' { print substr($0,66,10)";"substr($0,81,4)";"substr($0,90,4)";"substr($0,45,17)";       ;"substr($0,150,3)}')"
let "val = $val + 1"
echo $val
if [ "${cons1}" == "C08" ];then
echo -e "${control1}" >> estract.txt
#let 'val++'
#sleep 2
elif [ "${cons1}" == "C09" ] || [ "${cons1}" == "C33" ] || [ "${cons1}" == "C15" ];then
echo -e "${control2}" >> estract.txt
else
echo -e "${control}" >> estract.txt
fi

done

