#/bin/bash
domainlists=(
www.google.com
www.yahoo.com
www.apple.com
)

num=1
for domain in ${domainlists[@]}; do
  echo "---------- ${num} : ${domain} ----------"
  openssl s_client -connect ${domain}:443 < /dev/null 2> /dev/null | openssl x509 -noout -dates
  num=`expr ${num} + 1`
done

