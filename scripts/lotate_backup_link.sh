#!/bin/bash
set -e

BACKUP_DIR="/data/backup"
FILTER="[0-9]\{4\}[0-9]\{2\}[0-9]\{2\}_[0-9]\{2\}[0-9]\{2\}[0-9]\{2\}"

link_list=(`find /data/backup/qnap -maxdepth 1 -type l | grep -e "${FILTER}" | sort`)
target_path=`readlink ${link_list[0]}`

rm ${link_list[0]}
ln -s ${target_path} ${BACKUP_DIR}/`date +"%Y%m%d_%H%M%S"`

rm ${BACKUP_DIR}/latest
ln -s ${target_path} ${BACKUP_DIR}/latest

