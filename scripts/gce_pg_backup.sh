#!/bin/bash

### config
PG_USER="postgres"
PROJECT=`hostname -f | cut -d '.' -f 3 -`
GCS_BACKET_NAME="pg-backup_${PROJECT}"
HOSTNAME=`hostname`

### common
log_info() {
  echo "[`date +"%Y/%m/%d %H:%M:%S"`] INFO: $1"
}

log_err() {
  echo "[`date +"%Y/%m/%d %H:%M:%S"`] ERROR: $1" 1>&2
}

### require tools
# - Google Cloud SDK (gsutil) and setup (ex. gcloud init)
hash gsutil

if [ $? -ne 0 ]; then
  log_err "require tools are not installed."
  exit 1
fi

### check argument
usage() {
cat << EOS
Usage: $ ${0} -d [DATABASE_NAME] -g [GENERATION]

  * -d    [require] Target database schema name.
  * -g    [require] Backup generation count.
EOS
}

while getopts ':d:g:' OPT
do
  case ${OPT} in
    d)  DATABASE=${OPTARG}
        ;;
    g)  GENERATION=${OPTARG}
        ;;
    :|\?) usage && exit 0
        ;;
  esac
done
shift $((${OPTIND} - 1))

([ -z "${DATABASE}" ] || [ -z "${GENERATION}" ]) && usage && exit 1


### exec
exit_check() {
  if [ $? -ne 0 ]; then
    log_err "abort."
    exit 1
  fi
}

log_info "Start backup for ${DATABASE} DB."

# backup database
set -u

DATE=`date +"%Y%m%d_%H%M%S"`
BASE_DIR="gs://${GCS_BACKET_NAME}/${HOSTNAME}/${DATABASE}/${DATE}"

log_info "start pg_dump."
pg_dumpall -g | gsutil cp - ${BASE_DIR}/${DATE}_cluster.dump
exit_check
pg_dump -Fc -U ${PG_USER} ${DATABASE} | gsutil cp - ${BASE_DIR}/${DATE}_${DATABASE}.dump
exit_check
log_info "finished pg_dump."

# manage backup generation
BACKUP_PATHS=`gsutil ls gs://${GCS_BACKET_NAME}/${HOSTNAME}/${DATABASE}/ | sort -k5 -r`
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

