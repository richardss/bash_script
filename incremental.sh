#!/bin/bash

cd /home/dir
n=$(cat /home/dir/file.txt)
d=$((n+1))
for file in name.*;
do  mv  "${file}" /home/dir/incremental/log/archives/name."${d}".txt
d=$((d+1));
done

