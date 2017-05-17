#!/bin/bash
# version: 1.0.0
# date: 2017-05-12

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

run () {
  echo -e "${LTGREEN}COMMAND: ${GRAY}$*${NC}"
  "$@"
}

usage() {
  echo
  echo "USAGE: $0 [<course_id>] [<archive_format>]"
  echo
  echo "  Archive Formats:"
  echo "    7z        -7zip with LZMA compression split into 2G files"
  echo "    7zma2     -7zip with LZMA2 compression split into 2G files"
  echo "    7zcopy    -7zip with no compression split into 2G files"
  echo "    tar       -tar archive with no compression"
  echo "    tgz       -gzip  compressed tar archive"
  echo "    tbz       -bzip2 compressed tar archive"
  echo "    txz       -xz compressed tar archive"
  echo
}

##############################################################################
#                          Global Variables
##############################################################################

if [ -z ${1} ]
then
  if ! [ -e ./config ]
  then
    echo
    echo -e "${LT_RED}ERROR: You must provide the course ID of the lab environment to backup.${NC}"
    echo -e "${LT_RED}       or run this command from an installed lab environment's"
    echo -e "${LT_RED}       ~/config/<course_num>/ directory.${NC}"
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
COURSE_VM_DIR="/home/VMs/${COURSE_ID}"

#echo
#echo COURSE_ID=${COURSE_ID}
#echo ARCHIVE_CMD=${ARCHIVE_CMD}
#echo ARCHIVE_EXT=${ARCHIVE_EXT}
#echo COURSE_BACKUP_BASE_DIR=${COURSE_BACKUP_BASE_DIR}
#echo COURSE_BACKUP_DIR=${COURSE_BACKUP_DIR}
#echo COURSE_VM_DIR=${COURSE_VM_DIR}
#echo
#read

##############################################################################
#                          Functions
##############################################################################

create_course_backup_dir() {
  if ! [ -e ${COURSE_BACKUP_BASE_DIR} ]
  then
    echo -e "${LTBLUE}Creating ${COURSE_BACKUP_BASE_DIR} ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    run sudo mkdir -p ${COURSE_BACKUP_BASE_DIR} 
    run sudo chmod 777 ${COURSE_BACKUP_BASE_DIR} 
    echo
  fi
  if ! [ -e ${COURSE_BACKUP_DIR} ]
  then
    echo -e "${LTBLUE}Creating ${COURSE_BACKUP_DIR} ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    run mkdir -p ${COURSE_BACKUP_DIR} 
    echo
  fi
}

back_up_config() {
  echo -e "${LTBLUE}Backing up config ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"

  if [ -e ~/scripts/${COURSE_ID}/config ]
  then
    run mkdir -p ${COURSE_BACKUP_DIR}/config
    test -e ~/scripts/${COURSE_ID}/config && run cp -R ~/scripts/${COURSE_ID}/config/* ${COURSE_BACKUP_DIR}/config/
    test -e ~/scripts/${COURSE_ID}/install_lab_env.sh && run cp -R ~/scripts/${COURSE_ID}/install_lab_env.sh ${COURSE_BACKUP_DIR}/
    test -e ~/scripts/${COURSE_ID}/remove_lab_env.sh && run cp -R ~/scripts/${COURSE_ID}/remove_lab_env.sh ${COURSE_BACKUP_DIR}/
    test -e ~/scripts/${COURSE_ID}/backup_lab_env.sh && run cp -R ~/scripts/${COURSE_ID}/backup_lab_env.sh ${COURSE_BACKUP_DIR}/
    echo
  else
    echo -e  "(nothing to back up)"
    echo
  fi
}

back_up_course_files() {
  echo -e "${LTBLUE}Backing up course_files ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"

  if [ -e ~/course_files/${COURSE_ID} ]
  then
    run mkdir -p ${COURSE_BACKUP_DIR}/course_files
    run cp -R ~/course_files/${COURSE_ID}/* ${COURSE_BACKUP_DIR}/course_files/
    echo
  else
    echo -e  "(nothing to back up)"
    echo
  fi
}

back_up_scripts() {
  echo -e "${LTBLUE}Backing up scripts ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"

  if [ -e ~/scripts/${COURSE_ID} ]
  then
    run mkdir -p ${COURSE_BACKUP_DIR}/scripts
    run cp -R ~/scripts/${COURSE_ID}/* ${COURSE_BACKUP_DIR}/scripts/
    echo -e "${LTBLUE}(removing install/remove scripts and config ...)${NC}"
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

  if [ -e ~/pdf/${COURSE_ID} ]
  then
    run mkdir -p ${COURSE_BACKUP_DIR}/pdf
    run cp -R ~/pdf/${COURSE_ID}/* ${COURSE_BACKUP_DIR}/pdf/
    echo
  else
    echo -e  "(nothing to back up)"
    echo
  fi
}

back_up_isos() {
  echo -e "${LTBLUE}Backing up ISOs ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"

  if [ -e /home/iso/${COURSE_ID} ]
  then
    run mkdir -p ${COURSE_BACKUP_DIR}/iso
    run cp -R /home/iso/${COURSE_ID}/* ${COURSE_BACKUP_DIR}/iso/
    echo
  else
    echo -e  "(nothing to back up)"
    echo
  fi
}

back_up_images() {
  echo -e "${LTBLUE}Backing up images ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"

  if [ -e /home/images/${COURSE_ID} ]
  then
    run mkdir -p ${COURSE_BACKUP_DIR}/images
    run cp -R /home/images/${COURSE_ID}/* ${COURSE_BACKUP_DIR}/images/
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
    echo -e "${LTBLUE} Backing up VM: ${VM} ...${NC}"
    run ${ARCHIVE_CMD} ${VM}.${ARCHIVE_EXT} ${VM}
    echo
    echo -e "${LTBLUE} Creating MD5 sums ...${NC}"
    run md5sum ${VM}.${ARCHIVE_EXT}* > ${VM}.${ARCHIVE_EXT}.md5sums
    echo
    echo -e "${LTBLUE} Copying VM archives ...${NC}"
    run mv *${ARCHIVE_EXT}* ${COURSE_BACKUP_DIR}/VMs/
    echo
  done
  
  cd -
}

##############################################################################
#                          Main Code Body
##############################################################################

create_course_backup_dir
back_up_config
back_up_course_files
back_up_scripts
back_up_pdfs
back_up_isos
back_up_images
back_up_vms

