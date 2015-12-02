#!/bin/bash

LOG="/var/log/nginx/access.log"
TIME="01/Dec/2015:22"

for i in `seq -w 0 59`; do
  COUNT=`grep -c "${TIME}:${i}" ${LOG}`
  echo "[${TIME}:${i}] : ${COUNT}"
done

