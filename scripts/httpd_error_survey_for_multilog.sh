#!/bin/bash

TARGET="/var/log/nginx/*-access.log"

###
declare -a code
for s in ${!status_desc[@]}; do
  code[${s}]=0
done

declare -a err400
declare -a err500
for file in ${TARGET}; do
  echo "Read... ${file}"
  while read line
  do
    status=`echo ${line} | awk '{print $2}'`
    count=`echo ${line} | awk '{print $1}'`

    # validation check for status code
    expr ${status} + 1 >/dev/null 2>&1
    if [ $? -lt 2 ]; then
      code[${status}]=`expr ${code[${status}]} + ${count}`
    else
      err400+=(${file})
    fi

    # extract erroe(500) file
    if [ ${status} = "500" ]; then
      err500+=(${file})
    fi
  done < <(awk '{print $9}' ${file} 2> /dev/null | sort | uniq -c)
done

# 400 (Bad request)
for file in ${err400[@]}; do
  count=`grep -c " 400 " ${file}`
  code[400]=`expr ${code[400]} + ${count}`
done
echo ""

# output
echo "---------- Status Code Count ----------"
for s in ${!code[@]}; do
  echo -e "${s}: ${code[${s}]}"
done
echo ""

echo "---------- 500 Error Log ----------"
for file in ${err500[@]}; do
  echo -e "\033[44m${file}:\033[0;39m"
  echo " `grep " 500 " ${file}`"
  echo ""
done

