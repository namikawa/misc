#!/bin/bash

DOMAINS=(
)

for domain in ${DOMAINS[@]}; do
  result=`curl -sI -o /dev/null -w '%{http_code}\n' ${domain}`
  #result=`curl -sIL -o /dev/null -w '%{http_code}\n' ${domain}`
  echo "${domain} : ${result}"
done

