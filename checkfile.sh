#!/bin/bash

check_files=` ls -la /home/mobaxterm|grep -i -E 'ZINDG01|ZIRAP01|ZICOL01|ZISPC01'|awk '{print $9}'|tr '\n' ' '`

if [[ ${check_files[@]} != *"ZINDG01"* ]]; then
    echo " manca il file ZINDG01.csv"
    else
    if [[ ${check_files[@]} != *"ZIRAP01"* ]]; then
    echo "manca il file ZIRAP01.csv"
    else
    if [[ ${check_files[@]} != *"ZICOL01"* ]]; then
    echo " manca il file ZICOL01.csv"
    else   
    if [[ ${check_files[@]} != *"ZISPC01"* ]]; then
    echo " manca il file ZISPC01.csv"
    else
    echo "ci sono tutti"
    fi
    fi
    fi
    fi
    
