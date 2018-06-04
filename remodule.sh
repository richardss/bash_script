#!/bin/bash
read file
IN="$(cat $file)"
IFS=':' read -ra ADDR <<< "$IN"
i=${ADDR[0]}
j=${ADDR[1]}
sed "s/var1/${i}/;s/var2/${j}/" template1.txt >>ready.txt
