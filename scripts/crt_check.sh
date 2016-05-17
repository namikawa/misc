#!/bin/bash

DIR=~/tmp/cert

for file in `find ${DIR} -type f -name "*.crt"`; do
  res=`openssl x509 -in ${file} -text | grep "Subject: "`
  if [ ${res#*CN=} = `basename ${file%.crt}` ]; then
    echo "OK: `basename ${file%.crt}`"
  else
    echo "NG: `basename ${file%.crt}`"
  fi
done

