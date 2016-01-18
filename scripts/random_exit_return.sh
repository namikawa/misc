#!/bin/bash
i=`echo $(( $RANDOM % 5 ))`

if [ $i -eq 0 ]; then
  echo "OK"
  exit 0
else
  echo "NG"
  exit 1
fi

