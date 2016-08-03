#!/bin/bash
#
# generate symlinks for ...
# ex.)
# ./develop.example.com => ./example.com
# ./develop.example.com/develop.example.com.key => ./example.com/example.com.key

### config
SSL_DIR="/etc/nginx/ssl"
SUBDOMAIN="develop"

### exec

cd ${SSL_DIR}
for target_dir in `find . -name "??*" -type d`; do
  # create symlinks for top directory
  if [ ! -e ./${SUBDOMAIN}.${target_dir#./*} ]; then
    ln -s ./${target_dir} ./${SUBDOMAIN}.${target_dir#./*}
    echo "create ${SUBDOMAIN}.${target_dir#./*}"
  fi

  # create symlinks for file
  cd ${target_dir}
  for target_file in `find . -type f`; do
    if [ ! -e ./${SUBDOMAIN}.${target_file#./*} ]; then
      ln -s ./${target_file} ./${SUBDOMAIN}.${target_file#./*}
      echo "create ${target_dir}/${SUBDOMAIN}.${target_file#./*}"
    fi
  done
  cd - > /dev/null
done

