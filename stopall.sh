#!/usr/bin/env bash
for i in $(ps -ef|grep -i webase-collect-bee|grep -v grep| awk '{print $2}')
do
    kill -9 $i
done
echo "Stop succeed!"