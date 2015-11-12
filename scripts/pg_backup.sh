#!/bin/bash

### config
SSH_USER="postgres"
PG_USER="postgres"

BACKUP_BASE_DIR="/backup/postgresql"
GCS_BACKET_NAME="example_bucket_name"
SPLIT_FILE_SIZE="1G"

# download speed of pg_dump (KB/s)
D_SPEED="4096"
# upload speed to Google Cloud Storage (KB/s)
U_SPEED="1024"

### require tools
# - Google Cloud SDK (gsutil) and setup (ex. gcloud init)
# - Bandwidth shaper tool (trickle)
# - Split a file (split)
hash gsutil && hash trickle && hash split

if [ $? -ne 0 ]; then
  echo "ERROR: require tools are not installed." 1>&2
  exit 1
fi

### check argument
usage() {
  echo "Usage: $ ${0} -h [HOST_ADDDRESS] -d [DATABASE_NAME] -g [GENERATION]"
  exit 1
}

while getopts ':d:g:h:' OPT
do
  case ${OPT} in
    d)  DATABASE=${OPTARG}
        ;;
    g)  GENERATION=${OPTARG}
        ;;
    h)  HOST_ADDRESS=${OPTARG}
        ;;
    :|\?) usage
        ;;
  esac
done
shift $((${OPTIND} - 1))

([ -z "${DATABASE}" ] || [ -z "${GENERATION}" ] || [ -z "${HOST_ADDRESS}" ]) && usage

### exec
exit_check() {
  if [ $? -ne 0 ]; then
    echo "[`date +"%Y/%m/%d %k:%M:%S"`] ERROR: abort." 1>&2
    exit 1
  fi
}

# make backup directory
DATE=`date +"%Y%m%d_%k%M%S"`
BACKUP_DIR="${BACKUP_BASE_DIR}/${HOST_ADDRESS}/${DATABASE}/${DATE}"
DUMP_FILE="${BACKUP_DIR}/${DATE}_${DATABASE}.dump"

if [ -e ${BACKUP_DIR} ]; then
  echo "ERROR: ${BACKUP_DIR} already exists." 1>&2
  exit 1
fi

mkdir -p ${BACKUP_DIR}
exit_check

# backup database
echo "[`date +"%Y/%m/%d %k:%M:%S"`] INFO: start pg_dump."
trickle -s -d ${D_SPEED} ssh ${SSH_USER}@${HOST_ADDRESS} "pg_dumpall -g" > "${BACKUP_DIR}/${DATE}_cluster.dump"
trickle -s -d ${D_SPEED} ssh ${SSH_USER}@${HOST_ADDRESS} "pg_dump -Fc -U ${PG_USER} ${DATABASE}" > ${DUMP_FILE}
exit_check
echo "[`date +"%Y/%m/%d %k:%M:%S"`] INFO: finished pg_dump."

# split dump file
split -b ${SPLIT_FILE_SIZE} -a 4 -d ${DUMP_FILE} ${DUMP_FILE}.
exit_check
rm -f ${DUMP_FILE}

# upload backup file
echo "[`date +"%Y/%m/%d %k:%M:%S"`] INFO: start uploading."
trickle -s -u ${U_SPEED} gsutil -m rsync -r  ${BACKUP_DIR} gs://${GCS_BACKET_NAME}/i${HOST_ADDRESS}/${DATABASE}/${DATE}/
exit_check
echo "[`date +"%Y/%m/%d %k:%M:%S"`] INFO: finished uploading."

# delete backup directory
rm -rf ${BACKUP_DIR}

# manage backup generation
BACKUP_PATHS=`gsutil ls gs://${GCS_BACKET_NAME}/${HOST_ADDRESS}/${DATABASE}/ | sort -k5 -r`
COUNT=1

for BACKUP_PATH in ${BACKUP_PATHS}; do
  if [ ${COUNT} -le ${GENERATION} ]; then
    # N/A
    echo "[`date +"%Y/%m/%d %k:%M:%S"`] INFO: keeping - ${BACKUP_PATH}"
  else
    # delete
    gsutil -m rm -r ${BACKUP_PATH}
    exit_check
    echo "[`date +"%Y/%m/%d %k:%M:%S"`] INFO: deleting - ${BACKUP_PATH}"
  fi
  COUNT=`expr ${COUNT} + 1`
done

