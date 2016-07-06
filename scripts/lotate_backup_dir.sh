#!/bin/bash -ue

BACKUP_DIR="/data/backup"
GENERATION=3

dirs=(`ls -X ${BACKUP_DIR}`)

if [ ${#dirs[@]} -ge ${GENERATION} ]; then
  rm -rf ${BACKUP_DIR}/${dirs[0]}
  echo "delete ${dirs[0]}"
else
  echo "N/A"
fi

