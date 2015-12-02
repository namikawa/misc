#!/bin/bash

### config
SSH_USER="postgres"
PG_USER="postgres"

BACKUP_BASE_DIR="/backup/postgresql"
GCS_BACKET_NAME="example_bucket_name"
SPLIT_FILE_SIZE="1073741824"

### common
log_info() {
  echo "[`date +"%Y/%m/%d %H:%M:%S"`] INFO: $1"
}

log_err() {
  echo "[`date +"%Y/%m/%d %H:%M:%S"`] ERROR: $1" 1>&2
}

### require tools
# - Google Cloud SDK (gsutil) and setup (ex. gcloud init)
# - Bandwidth shaper tool (trickle)
# - Split a file (split)
hash gsutil && hash trickle && hash split

if [ $? -ne 0 ]; then
  log_err "require tools are not installed."
  exit 1
fi

### check argument
usage() {
cat << EOS
Usage: $ ${0} -h [HOST_ADDDRESS] -d [DATABASE_NAME] -g [GENERATION] -D (DOWNLOAD_SPEED) -U (UPLOAD_SPEED)"

  * -h    [require] Target database host address."
  * -d    [require] Target database schema name."
  * -g    [require] Backup generation count."
  * -D    Download speed of pg_dump. (KB/s) - Default: 1GB/s"
  * -U    Upload speed to Google Cloud Storage. (KB/s) - Default: 1GB/s"
EOS
}

while getopts ':d:g:h:D:U:' OPT
do
  case ${OPT} in
    d)  DATABASE=${OPTARG}
        ;;
    g)  GENERATION=${OPTARG}
        ;;
    h)  HOST_ADDRESS=${OPTARG}
        ;;
    D)  D_SPEED=${OPTARG}
        ;;
    U)  U_SPEED=${OPTARG}
        ;;
    :|\?) usage && exit 0
        ;;
  esac
done
shift $((${OPTIND} - 1))

([ -z "${DATABASE}" ] || [ -z "${GENERATION}" ] || [ -z "${HOST_ADDRESS}" ]) && usage && exit 1

# default parameters
if [ -z ${D_SPEED} ]; then
  D_SPEED="1048576"
fi
if [ -z ${U_SPEED} ]; then
  U_SPEED="1048576"
fi

### exec
exit_check() {
  if [ $? -ne 0 ]; then
    log_err "abort."
    exit 1
  fi
}

log_info "Start backup for ${DATABASE} DB."

# make backup directory
DATE=`date +"%Y%m%d_%H%M%S"`
BACKUP_DIR="${BACKUP_BASE_DIR}/${HOST_ADDRESS}/${DATABASE}/${DATE}"
DUMP_FILE="${BACKUP_DIR}/${DATE}_${DATABASE}.dump"

if [ -e ${BACKUP_DIR} ]; then
  log_err "${BACKUP_DIR} already exists."
  exit 1
fi

mkdir -p ${BACKUP_DIR}
exit_check

# backup database
log_info "start pg_dump."
trickle -s -t 1 -d ${D_SPEED} ssh ${SSH_USER}@${HOST_ADDRESS} "pg_dumpall -g" > "${BACKUP_DIR}/${DATE}_cluster.dump"
trickle -s -t 1 -d ${D_SPEED} ssh ${SSH_USER}@${HOST_ADDRESS} "pg_dump -Fc -U ${PG_USER} ${DATABASE}" > ${DUMP_FILE}
exit_check
log_info "finished pg_dump."

# split dump file
if [ `wc -c ${DUMP_FILE} | awk '{print $1}'` -gt ${SPLIT_FILE_SIZE} ]; then
  split -b ${SPLIT_FILE_SIZE} -a 4 -d ${DUMP_FILE} ${DUMP_FILE}.
  exit_check
  rm -f ${DUMP_FILE}
fi

# upload backup file
log_info "start uploading."
trickle -s -t 1 -u ${U_SPEED} gsutil rsync -r  ${BACKUP_DIR} gs://${GCS_BACKET_NAME}/${HOST_ADDRESS}/${DATABASE}/${DATE}/
exit_check
log_info "finished uploading."

# delete backup directory
rm -rf ${BACKUP_DIR}

# manage backup generation
BACKUP_PATHS=`gsutil ls gs://${GCS_BACKET_NAME}/${HOST_ADDRESS}/${DATABASE}/ | sort -k5 -r`
COUNT=1

for BACKUP_PATH in ${BACKUP_PATHS}; do
  if [ ${COUNT} -le ${GENERATION} ]; then
    # N/A
    log_info "keeping - ${BACKUP_PATH}"
  else
    # delete
    gsutil -m rm -r ${BACKUP_PATH}
    exit_check
    log_info "deleting - ${BACKUP_PATH}"
  fi
  COUNT=`expr ${COUNT} + 1`
done

log_info "Finished."

