#!/bin/bash

### config
FILTER="Registrant Email: "

source ./domains.sh

### Exec

for domain in ${DOMAINS[@]}; do
  result=`whois ${domain} | grep "${FILTER}"`
  echo "${domain} : ${result#${FILTER}}"
done

