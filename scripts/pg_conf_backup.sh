#!/bin/bash -u

### config
SSH_USER="postgres"
BACKUP_BASE_DIR="/backup/postgresql-conf"
GCS_BACKET_NAME="example_bucket_name"

TARGET_DIRS=(
/etc/postgresql
/var/lib/postgresql/bin
)

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
hash gsutil && hash trickle

if [ $? -ne 0 ]; then
  log_err "require tools are not installed."
  exit 1
fi

### check argument
usage() {
cat << EOS
Usage: $ ${0} -h [HOST_ADDDRESS] -g [GENERATION] -D (DOWNLOAD_SPEED) -U (UPLOAD_SPEED)

  * -h    [require] Target database host address.
  * -g    [require] Backup generation count.
  * -D    Download speed of pg_dump. (KB/s) - Default: 1GB/s
  * -U    Upload speed to Google Cloud Storage. (KB/s) - Default: 1GB/s
EOS
}

while getopts ':g:h:D:U:' OPT
do
  case ${OPT} in
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

([ -z "${GENERATION}" ] || [ -z "${HOST_ADDRESS}" ]) && usage && exit 1

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

log_info "Start file backup."

# make backup directory
DATE=`date +"%Y%m%d_%H%M%S"`
BACKUP_DIR="${BACKUP_BASE_DIR}/${HOST_ADDRESS}/${DATE}"

if [ -e ${BACKUP_DIR} ]; then
  log_err "${BACKUP_DIR} already exists."
  exit 1
fi

mkdir -p ${BACKUP_DIR}
exit_check

# collect & compress config files
log_info "start to collect config files."

for dir in ${TARGET_DIRS[@]}; do
  temp=`echo ${dir#*/}`
  file=`echo ${temp//\//_}`

  ssh ${SSH_USER}@${HOST_ADDRESS} "test -d ${dir}"
  if [ $? -ne 0 ]; then
    log_info "${dir} is not exist."
    touch ${BACKUP_DIR}/${file}.none
  else
    log_info "${dir} is exists. make tar-file..."
    trickle -s -t 1 -d ${D_SPEED} scp -r ${SSH_USER}@${HOST_ADDRESS}:${dir} ${BACKUP_DIR}/
    exit_check

    cd ${BACKUP_DIR}
    tar czf ${BACKUP_DIR}/${file}.tar.gz `basename ${dir}`
    exit_check
    cd - > /dev/null

    rm -rf ${BACKUP_DIR}/`basename ${dir}`
  fi
done

log_info "finished to collect config files."

# upload backup file
log_info "start uploading."
trickle -s -t 1 -u ${U_SPEED} gsutil rsync -r  ${BACKUP_DIR} gs://${GCS_BACKET_NAME}/${HOST_ADDRESS}/_configuration_files/${DATE}/
exit_check
log_info "finished uploading."

# delete backup directory
rm -rf ${BACKUP_DIR}

# manage backup generation
BACKUP_PATHS=`gsutil ls gs://${GCS_BACKET_NAME}/${HOST_ADDRESS}/_configuration_files/ | sort -k5 -r`
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

