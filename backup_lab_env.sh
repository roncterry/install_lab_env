#!/bin/bash
# version: 1.1.1
# date: 2017-09-05

### Colors ###
RED='\e[0;31m'
LTRED='\e[1;31m'
BLUE='\e[0;34m'
LTBLUE='\e[1;34m'
GREEN='\e[0;32m'
LTGREEN='\e[1;32m'
ORANGE='\e[0;33m'
YELLOW='\e[1;33m'
CYAN='\e[0;36m'
LTCYAN='\e[1;36m'
PURPLE='\e[0;35m'
LTPURPLE='\e[1;35m'
GRAY='\e[1;30m'
LTGRAY='\e[0;37m'
WHITE='\e[1;37m'
NC='\e[0m'
##############

SCRIPTS_DIR="${HOME}/scripts"
COURSE_FILES_DIR="${HOME}/course_files"
PDF_DIR="${HOME}/pdf"
VM_DIR="/home/VMs"
ISO_DIR="/home/iso"
IMAGES_DIR="/home/images"

run () {
  echo -e "${LTGREEN}COMMAND: ${GRAY}$*${NC}"
  "$@"
}

usage() {
  echo
  echo -e "${LTGREEN}USAGE:${GRAY} $0 [<course_id>] [<archive_format>]${NC}"
  echo
  echo -e "${LTPURPLE}  Archive Formats:${NC}"
  echo -e "${GRAY}    7z        ${LTPURPLE}-7zip with LZMA compression split into 2G files${NC}"
  echo -e "${GRAY}    7zma2     ${LTPURPLE}-7zip with LZMA2 compression split into 2G files (this is default)${NC}"
  echo -e "${GRAY}    7zcopy    ${LTPURPLE}-7zip with no compression split into 2G files${NC}"
  echo -e "${GRAY}    tar       ${LTPURPLE}-tar archive with no compression${NC}"
  echo -e "${GRAY}    tgz       ${LTPURPLE}-gzip  compressed tar archive${NC}"
  echo -e "${GRAY}    tbz       ${LTPURPLE}-bzip2 compressed tar archive${NC}"
  echo -e "${GRAY}    txz       ${LTPURPLE}-xz compressed tar archive${NC}"
  echo
}

##############################################################################
#                          Global Variables
##############################################################################

if [ -z ${1} ]
then
  if ! [ -e ./config/lab_env.cfg ]
  then
    echo
    echo -e "${LTRED}ERROR: You must provide the course ID of the lab environment to backup.${NC}"
    echo -e "${LTRED}       or run this command from an installed lab environment's"
    echo -e "${LTRED}       ${SCRIPTS_DIR}/<course_num>/ directory.${NC}"
    echo
    usage
    exit
    exit
  else
    source ./config/lab_env.cfg
    COURSE_ID=${COURSE_NUM}
  fi
else
  if echo $* | grep -q "help"
  then
    echo
    usage
    echo
    exit
  else
    COURSE_ID=${1}
  fi
fi

if ! [ -e ${VM_DIR}/${COURSE_ID} ]
then
  echo
  echo -e "${LTRED}ERROR: The provided course (COURSE_ID=${LTGREEN}${COURSE_ID}${LTRED}) doesn't exist.${NC}"
  echo
  echo -e "${LTRED}Exiting ...${NC}"
  echo
  exit 1
fi

case ${2}
in
  7z)
    ARCHIVE_CMD="7z a -t7z -m0=LZMA -mmt=on -v2g"
    ARCHIVE_EXT="7z"
  ;;
  7zma2)
    ARCHIVE_CMD="7z a -t7z -m0=LZMA2 -mmt=on -v2g"
    ARCHIVE_EXT="7z"
  ;;
  7zcopy)
    ARCHIVE_CMD="7z a -t7z -mx=0 -v2g"
    ARCHIVE_EXT="7z"
  ;;
  tar)
    ARCHIVE_CMD="tar cvf"
    ARCHIVE_EXT="tar"
  ;;
  tar.gz|tgz)
    ARCHIVE_CMD="tar czvf"
    ARCHIVE_EXT="tgz"
  ;;
  tar.bz2|tbz)
    ARCHIVE_CMD="tar cjvf"
    ARCHIVE_EXT="tbz"
  ;;
  tar.xz|txz)
    ARCHIVE_CMD="tar cJvf"
    ARCHIVE_EXT="txz"
  ;;
  *)
    ARCHIVE_CMD="7z a -t7z -m0=LZMA2 -mmt=on -v2g"
    ARCHIVE_EXT="7z"
  ;;
esac

COURSE_BACKUP_BASE_DIR="/install/courses"
COURSE_BACKUP_DIR="${COURSE_BACKUP_BASE_DIR}/${COURSE_ID}-backup_$(date +%Y%m%d.%H%M%S)"
COURSE_VM_DIR="${VM_DIR}/${COURSE_ID}"

#echo
#echo COURSE_ID=${COURSE_ID}
#echo ARCHIVE_CMD=${ARCHIVE_CMD}
#echo ARCHIVE_EXT=${ARCHIVE_EXT}
#echo COURSE_BACKUP_BASE_DIR=${COURSE_BACKUP_BASE_DIR}
#echo COURSE_BACKUP_DIR=${COURSE_BACKUP_DIR}
#echo COURSE_VM_DIR=${COURSE_VM_DIR}
#echo "---------------------------------"
#echo Source scripts dir=${SCRIPTS_DIR}/${COURSE_ID}/
#echo Source course_files dir=${COURSE_FILES_DIR}/${COURSE_ID}/
#echo Source PDF dir=${PDF_DIR}/${COURSE_ID}/
#echo Source ISO dir=${ISO_DIR}/${COURSE_ID}/
#echo Source Images dir=${IMAGES_DIR}/${COURSE_ID}/
#echo
#read

##############################################################################
#                          Functions
##############################################################################

create_course_backup_dir() {
  if ! [ -e ${COURSE_BACKUP_BASE_DIR} ]
  then
    echo -e "${LTBLUE}Creating: ${ORANGE}${COURSE_BACKUP_BASE_DIR}${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    run sudo mkdir -p ${COURSE_BACKUP_BASE_DIR} 
    run sudo chmod 777 ${COURSE_BACKUP_BASE_DIR} 
    echo
  fi
  if ! [ -e ${COURSE_BACKUP_DIR} ]
  then
    echo -e "${LTBLUE}Creating: ${ORANGE}${COURSE_BACKUP_DIR}${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    run mkdir -p ${COURSE_BACKUP_DIR} 
    echo
  fi
}

back_up_config() {
  echo -e "${LTBLUE}Backing up config ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"

  if [ -e ${SCRIPTS_DIR}/${COURSE_ID}/config ]
  then
    run mkdir -p ${COURSE_BACKUP_DIR}/config
    test -e ${SCRIPTS_DIR}/${COURSE_ID}/config && run cp -R ${SCRIPTS_DIR}/${COURSE_ID}/config/* ${COURSE_BACKUP_DIR}/config/
    test -e ${SCRIPTS_DIR}/${COURSE_ID}/install_lab_env.sh && run cp -R ${SCRIPTS_DIR}/${COURSE_ID}/install_lab_env.sh ${COURSE_BACKUP_DIR}/
    test -e ${SCRIPTS_DIR}/${COURSE_ID}/remove_lab_env.sh && run cp -R ${SCRIPTS_DIR}/${COURSE_ID}/remove_lab_env.sh ${COURSE_BACKUP_DIR}/
    test -e ${SCRIPTS_DIR}/${COURSE_ID}/backup_lab_env.sh && run cp -R ${SCRIPTS_DIR}/${COURSE_ID}/backup_lab_env.sh ${COURSE_BACKUP_DIR}/
    echo
  else
    echo -e  "(nothing to back up)"
    echo
  fi
}

back_up_course_files() {
  echo -e "${LTBLUE}Backing up course_files ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"

  if [ -e ${COURSE_FILES_DIR}/${COURSE_ID} ]
  then
    run mkdir -p ${COURSE_BACKUP_DIR}/course_files
    run cp -R ${COURSE_FILES_DIR}/${COURSE_ID}/* ${COURSE_BACKUP_DIR}/course_files/
    echo
  else
    echo -e  "(nothing to back up)"
    echo
  fi
}

back_up_scripts() {
  echo -e "${LTBLUE}Backing up scripts ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"

  if [ -e ${SCRIPTS_DIR}/${COURSE_ID} ]
  then
    run mkdir -p ${COURSE_BACKUP_DIR}/scripts
    run cp -R ${SCRIPTS_DIR}/${COURSE_ID}/* ${COURSE_BACKUP_DIR}/scripts/
    echo -e "${LTCYAN}(removing install/remove scripts and config ...)${NC}"
    test -e ${COURSE_BACKUP_DIR}/scripts/config && run rm -rf ${COURSE_BACKUP_DIR}/scripts/config
    test -e ${COURSE_BACKUP_DIR}/scripts/install_lab_env.sh && run rm -rf ${COURSE_BACKUP_DIR}/scripts/install_lab_env.sh
    test -e ${COURSE_BACKUP_DIR}/scripts/remove_lab_env.sh && run rm -rf ${COURSE_BACKUP_DIR}/scripts/remove_lab_env.sh
    test -e ${COURSE_BACKUP_DIR}/scripts/backup_lab_env.sh && run rm -rf ${COURSE_BACKUP_DIR}/scripts/backup_lab_env.sh
    echo
  else
    echo -e  "(nothing to back up)"
    echo
  fi
}

back_up_pdfs() {
  echo -e "${LTBLUE}Backing up PDFs ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"

  if [ -e ${PDF_DIR}/${COURSE_ID} ]
  then
    run mkdir -p ${COURSE_BACKUP_DIR}/pdf
    run cp -R ${PDF_DIR}/${COURSE_ID}/* ${COURSE_BACKUP_DIR}/pdf/
    echo
  else
    echo -e  "(nothing to back up)"
    echo
  fi
}

back_up_isos() {
  echo -e "${LTBLUE}Backing up ISOs ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"

  if [ -e ${ISO_DIR}/${COURSE_ID} ]
  then
    run mkdir -p ${COURSE_BACKUP_DIR}/iso
    run cp -R ${ISO_DIR}/${COURSE_ID}/* ${COURSE_BACKUP_DIR}/iso/
    echo
  else
    echo -e  "(nothing to back up)"
    echo
  fi
}

back_up_images() {
  echo -e "${LTBLUE}Backing up images ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"

  if [ -e ${IMAGES_DIR}/${COURSE_ID} ]
  then
    run mkdir -p ${COURSE_BACKUP_DIR}/images
    run cp -R ${IMAGES_DIR}/${COURSE_ID}/* ${COURSE_BACKUP_DIR}/images/
    echo
  else
    echo -e  "(nothing to back up)"
    echo
  fi
}

back_up_vms() {
  echo -e "${LTBLUE}Backing up VMs ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  run mkdir -p ${COURSE_BACKUP_DIR}/VMs
  cd ${COURSE_VM_DIR}

  for VM in $(ls)
  do
    echo
    echo -e "${LTCYAN}Backing up VM: ${LTPURPLE}${VM}${NC}"
    run ${ARCHIVE_CMD} ${VM}.${ARCHIVE_EXT} ${VM}
    echo
    echo -e "${LTCYAN}Creating MD5 sums for VM ${LTPURPLE}${VM} ${LTCYAN}...${NC}"
    echo -e "${LTGREEN}COMMAND: ${GRAY}md5sum ${VM}.${ARCHIVE_EXT}* > ${VM}.${ARCHIVE_EXT}.md5sums${NC}"
    md5sum ${VM}.${ARCHIVE_EXT}* > ${VM}.${ARCHIVE_EXT}.md5sums
    echo
    echo -e "${LTCYAN}Copying VM archives for VM ${LTPURPLE}${VM} ${LTCYAN}...${NC}"
    run mv *${ARCHIVE_EXT}* ${COURSE_BACKUP_DIR}/VMs/
    echo
  done
  
  cd - > /dev/null 2>&1
}

##############################################################################
#                          Main Code Body
##############################################################################
echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
echo -e "${LTCYAN}                      Backing Up Lab Environment Files"
echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
echo


create_course_backup_dir
back_up_config
back_up_course_files
back_up_scripts
back_up_pdfs
back_up_isos
back_up_images
back_up_vms

echo -e "${LTCYAN}=========================  Backup Complete  =========================${NC}"
echo
exit 0
