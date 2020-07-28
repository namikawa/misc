#!/bin/bash

# Usage:
# ./tcpping.sh {HOST} {PORT}

###
INTERVAL=1
###

seq=1

while true
do
  res=`(time nc -vz -G ${INTERVAL} $@) 2>&1 | egrep ' port |real '`
  res=`echo ${res} | sed -e "s/[\r\n]\+//g"`

  if [ "`echo ${res} | grep 'Operation timed out'`" ] ;
  then
    : # N/A
  else
    sleep ${INTERVAL}
  fi

  echo "seq[${seq}]: ${res}"
  seq=$((seq+1))
done

