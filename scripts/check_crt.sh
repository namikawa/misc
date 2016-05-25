#!/bin/bash

DIR=~/tmp/cert

ok=0
ng=0
for file in `find ${DIR} -type f -name "*.crt"`; do
  res=`openssl x509 -in ${file} -text | grep "Subject: "`
  if [ ${res#*CN=} = `basename ${file%.crt}` ]; then
    echo "OK: `basename ${file%.crt}`"
    ok=$(( ok + 1 ))
  else
    echo "NG: `basename ${file%.crt}`"
    ng=$(( ng + 1 ))
  fi
done

echo "------------------------------"
echo "OK: ${ok}, NG: ${ng}"

