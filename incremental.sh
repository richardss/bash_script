#!/bin/bash

cd /home/riccardo/incremental/log/archives/
n=$(cat /home/riccardo/incremental/lotti.txt)
d=$((n+1))
for file in REPO_CRE_TGET_I.*;
do  mv  "${file}" /home/riccardo/incremental/log/archives1/REPO_CRE_TGET_I."${d}".txt
d=$((d+1));
done

