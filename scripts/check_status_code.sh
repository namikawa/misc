#!/bin/bash

DOMAINS=(
twitter.com
apple.com
google.com
)

for domain in ${DOMAINS[@]}; do
  #result=`curl -sI -o /dev/null -w '%{http_code}\n' ${domain}`
  result=`curl -sIL -o /dev/null -w '%{http_code}\n' ${domain}`
  echo "${domain} : ${result}"
done

