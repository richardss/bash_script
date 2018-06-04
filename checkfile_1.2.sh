#!/bin/bash
#
#
################################
### script di controllo file ### 
################################
source enviroment.env
while true
do
for i in "${#list[@]}"; do
if [ ${#check_files[@]} != $i ] && [ $TIME -le 18 ] ; then
     echo "attenzione sono presenti solo:" "${check_files[@]}"
     sleep 30 
     else
     echo "eseguo COM.DQ"
     fi
     done   
     done

    
