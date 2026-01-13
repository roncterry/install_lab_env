#!/bin/bash
# version: 1.4.5
# date: 2026-01-13

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
  echo -e "${LTGREEN}COMMAND: ${NC}$*${NC}"
  "$@"
}

usage() {
  echo
  echo -e "${LTGREEN}USAGE:${NC} $0 [<course_id>] [<archive_format>]${NC}"
  echo
  echo -e "${LTPURPLE}  Archive Formats:${NC}"
  echo -e "${NC}    7z        ${LTPURPLE}-7zip with LZMA compression split into 2G files${NC}"
  echo -e "${NC}    7zma2     ${LTPURPLE}-7zip with LZMA2 compression split into 2G files (this is default)${NC}"
  echo -e "${NC}    7zcopy    ${LTPURPLE}-7zip with no compression split into 2G files${NC}"
  echo -e "${NC}    tar       ${LTPURPLE}-tar archive with no compression${NC}"
  echo -e "${NC}    tgz       ${LTPURPLE}-gzip  compressed tar archive${NC}"
  echo -e "${NC}    tbz       ${LTPURPLE}-bzip2 compressed tar archive${NC}"
  echo -e "${NC}    txz       ${LTPURPLE}-xz compressed tar archive${NC}"
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
    test -e ${COURSE_BACKUP_DIR}/scripts/scripts && run mv ${COURSE_BACKUP_DIR}/scripts/scripts/* ${COURSE_BACKUP_DIR}/scripts/ && run rm -rf ${COURSE_BACKUP_DIR}/scripts/scripts
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

export_vm_config() {
  local VM_PATH=${1}
  local VM_PARENT_DIR=$(pwd ${VM_PATH})
  local VM_NAME=$(basename ${VM_PATH})

  if ! [ -e ${VM_PATH}/${VM_NAME}.xml ]
  then
    echo -e "${LTCYAN}Exporting VM XML config to VM Directory ...${NC}"
    echo -e "${LTGREEN}COMMAND: ${NC}virsh dumpxml ${VM_NAME} > ${VM_PATH}/${VM_NAME}.xml"
    virsh dumpxml ${VM_NAME} > ${VM_PATH}/${VM_NAME}.xml
    run sed -i '/<uuid.*>/ d' ${VM_PATH}/${VM_NAME}.xml

    ### This changes the CPU to model='host-passthrough'
    #run sed -i -e "s/\( *\)<cpu.*/\1<cpu mode='host-passthrough' check='none' migratable='on'\/>/" ${VM_PATH}/${VM_NAME}.xml

    ### This changes the CPU line to model='host-model' and adds the feature name='pcid' [ONLY WORKS ON INTEL CPUS]
    #run sed -i -e "s/\( *\)<cpu.*/\1<cpu mode='host-model' check='partial'>/" ${VM_PATH}/${VM_NAME}.xml
    #if ! grep -q "^ *<feature policy=*require* name=*pcid*" ${VM_PATH}/${VM_NAME}.xml
    #then
    #  run sed -i "/^ .*<cpu/a \ \ \ \ <feature policy='require' name='pcid'\/>" ${VM_PATH}/${VM_NAME}.xml
    #fi
    #if ! grep -q "^ *<\/cpu>" ${VM_PATH}/${VM_NAME}.xml
    #then
    #  run sed -i "/^ .*<feature policy='require' name='pcid'/a \ \ <\/cpu>" ${VM_PATH}/${VM_NAME}.xml
    #fi

    run sed -i "s/lsilogic/virtio-scsi/" ${VM_PATH}/${VM_NAME}.xml
  fi
  echo
}

mv_vm_nvram_file() {
  if [ -z ${1} ]
  then
    echo -e "${RED}ERROR: You must supply a VM name.${NC}"
    echo 
    echo "  USAGE: mv_vm_nvram_file <vm_name>"
  else
    local VM_NAME=${1}
  fi

  # Check the live config not the on-disk config
  local NVRAM_FILE=$(virsh dumpxml ${VM_NAME} | grep nvram | cut -d \> -f 2 | cut -d \< -f 1)
  local OVMF_BIN=$(virsh dumpxml ${VM_NAME} | grep loader | cut -d \> -f 2 | cut -d \< -f 1)

  echo -e "${LTCYAN}Moving NVRAM/OVMF files to VM Directory ...${NC}"

  if ! [ -z "${NVRAM_FILE}" ]
  then
    local NVRAM_FILE_NAME=$(basename ${NVRAM_FILE})
    local OVMF_BIN_NAME=$(basename ${OVMF_BIN})

    echo -e "${LTCYAN}(NVRAM: ${NC}${NVRAM_FILE}${LTBLUE})${NC}"
    # Does nvram in the live config already point to the VM's directory?
    if echo ${NVRAM_FILE} | grep -q "${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram"
    then
      local DO_CHOWN=Y
      # Look for NVRAM file
      if [ -e "${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram/${NVRAM_FILE_NAME}" ]
      then
        echo -e "${LTCYAN}(NVRAM file already in VM's directory ... Skipping)${NC}"
      else
        run sudo mv ${NVRAM_FILE} ${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram/
      fi
    else
      echo -e "${LTCYAN}(Will need to copy the NVRAM file and update the config ...)${NC}"
    fi

    echo -e "${LTCYAN}(OVMF: ${NC}${OVMF_BIN}${LTBLUE})${NC}"
    # Does ovmf in the live config already point to the VM's directory?
    if echo ${OVMF_BIN} | grep -q "${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram"
    then
      local DO_CHOWN=Y
      # Look for OVMF bin
      if [ -e "${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram/${OVMF_BIN_NAME}" ]
      then
        echo -e "${LTCYAN}(OVMF binary already in VM's directory ... Skipping)${NC}"
      else
        run sudo cp ${OVMF_BIN} ${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram/
      fi
    else
      echo -e "${LTCYAN}(Will need to copy the OVMF binary and update the config ...)${NC}"
    fi

    # Does nvram in the live config point to the default NVRAM location?
    if echo ${NVRAM_FILE} | grep -q "/var/lib/libvirt/qemu/nvram"
    then
      echo -e "${LTCYAN}(Moving NVRAM file from default location to VM Directory ...)${NC}"
      run mkdir -p ${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram
      run sudo mv ${NVRAM_FILE} ${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram/
      run sudo chmod -R u+rwx,g+rws,o+r ${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram
      run sudo chown -R ${USER}:${GROUPS} ${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram
      run sed -i "s+\(^ *\)<nvram>.*+\1<nvram>${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram/${NVRAM_FILE_NAME}</nvram>+" ${VM_DIR}/${COURSE_ID}/${VM_NAME}/${VM_NAME}.xml
    fi

    # Does ovmf in the live config point to the default ovmf location?
    if echo ${OVMF_BIN} | grep -q "/usr/share/qemu"
    then
      echo -e "${LTCYAN}(Copying the OVMF binary from default location into VM Directory ...)${NC}"
      run mkdir -p ${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram
      run sudo cp ${OVMF_BIN} ${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram/
      run sudo chmod -R u+rwx,g+rws,o+r ${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram
      run sudo chown -R ${USER}:${GROUPS} ${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram
      #run sed -i "s+\(^ *\)<loader.*+\1<loader readonly=\"yes\" type=\"pflash\">${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram/${OVMF_BIN_NAME}</loader>+" ${VM_DIR}/${COURSE_ID}/${VM_NAME}/${VM_NAME}.xml
    fi

    case ${DO_CHOWN}
    in
      Y)
        run sudo chmod -R u+rwx,g+rws,o+r ${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram
        run sudo chown -R ${USER}:${GROUPS} ${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram
      ;;
    esac
  elif [ -e ${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram ]
  then
    # In case the nvram dir exist in the VM's dir but not in the live config?
    echo -e "${LTCYAN}(NVRAM not defined in VM config but file is in VM Directory ...)${NC}"
    run sudo chmod -R u+rwx,g+rws,o+r ${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram
    run sudo chown -R ${USER}:${GROUPS} ${VM_DIR}/${COURSE_ID}/${VM_NAME}/nvram
  else
    echo -e "${LTCYAN}(NVRAM not defined in VM ... Skipping)${NC}"
  fi
  echo
}

backup_vm_tpm() {
  if [ -z ${1} ]
  then
    echo -e "${RED}ERROR: You must supply a VM name.${NC}"
    echo 
    echo "  USAGE: backup_vm_tpm <vm_name>"
  else
    local VM_NAME=${1}
  fi

  #local TPM_DIR="/var/lib/libvirt/swtpm/$(virsh dumpxml ${VM_NAME} | grep uuid | cut -d \> -f 2 | cut -d \< -f 1)"
  local VM_UUID="$(virsh dumpxml ${VM_NAME} | grep uuid | cut -d \> -f 2 | cut -d \< -f 1)"
  local TPM_DIR="/var/lib/libvirt/swtpm/${VM_UUID}"

  echo -e "${LTCYAN}Backing up TPM file to VM Directory ...${NC}"


  if [ -e ${TPM_DIR} ]
  then
    echo -e "${LTCYAN}(TPM: ${NC}${TPM_DIR}${LTBLUE})${NC}"
    run mkdir -p ${VM_DIR}/${COURSE_ID}/${VM_NAME}/tpm
    if [ -e ${TPM_DIR}/tpm1.2 ]
    then
      echo -e "${LTCYAN}(TPM v1.2 found)${NC}"
      run sudo cp -R ${TPM_DIR}/tpm1.2 ${VM_DIR}/${COURSE_ID}/${VM_NAME}/tpm/
    fi
    if [ -e ${TPM_DIR}/tpm2 ]
    then
      echo -e "${LTCYAN}(TPM v2 found)${NC}"
      run sudo cp -R ${TPM_DIR}/tpm2 ${VM_DIR}/${COURSE_ID}/${VM_NAME}/tpm/
    fi
    run sudo chown -R ${USER}:${GROUPS} ${VM_NAME}/tpm
  else
    echo -e "${LTCYAN}(No TPM files for the VM ... Skipping)${NC}"
  fi
  echo
}

dump_vm_snapshots() {
  if [ -z ${1} ]
  then
    echo -e "${RED}ERROR: You must supply a VM name.${NC}"
    echo 
    echo "  USAGE: dump_vm_snapshots <vm_name>"
  else
    local VM_NAME=${1}
  fi

  local SNAPSHOT_LIST=$(virsh snapshot-list ${VM_NAME} | grep -v "^---" | grep -v "^ Name" | grep -v "^$" | awk '{ print $1 }')

  if ! [ -z "${SNAPSHOT_LIST}" ]
  then
    echo -e "${LTCYAN}Dumping out snapshots for VM ${LTPURPLE}${VM} ${LTCYAN}...${NC}"
    if [ -e "${VM_DIR}/${COURSE_ID}/${VM_NAME}"/snapshots ]
    then
      run rm -rf ${VM_DIR}/${COURSE_ID}/${VM_NAME}/snapshots
      run mkdir ${VM_DIR}/${COURSE_ID}/${VM_NAME}/snapshots
    else
      run mkdir ${VM_DIR}/${COURSE_ID}/${VM_NAME}/snapshots
    fi
 
    for SNAPSHOT in ${SNAPSHOT_LIST}
    do
      echo -e "${LTGREEN}COMMAND:${NC} virsh snapshot-dumpxml ${VM_NAME} ${SNAPSHOT} > ${VM_DIR}/${COURSE_ID}/${VM_NAME}/snapshots/${SNAPSHOT}.xml${NC}"
      virsh snapshot-dumpxml ${VM_NAME} ${SNAPSHOT} > ${VM_DIR}/${COURSE_ID}/${VM_NAME}/snapshots/${SNAPSHOT}.xml
 
      local VM_UUID=$(virsh dumpxml ${VM_NAME} | grep uuid | head -1 | cut -d ">" -f 2 | cut -d "<" -f 1)
      local SNAPSHOT_CREATION_TIME=$(grep "<creationTime>.*" ${VM_DIR}/${COURSE_ID}/${VM_NAME}/snapshots/${SNAPSHOT}.xml | cut -d ">" -f 2 | cut -d "<" -f 1)
 
      run mv ${VM_DIR}/${COURSE_ID}/${VM_NAME}/snapshots/${SNAPSHOT}.xml ${VM_DIR}/${COURSE_ID}/${VM_NAME}/snapshots/${SNAPSHOT_CREATION_TIME}.${SNAPSHOT}.xml
 
      unset VM_UUID
      unset SNAPSHOT_CREATION_TIME
    done
  else
    if [ -e "${VM_DIR}/${COURSE_ID}/${VM_NAME}"/snapshots ]
    then
      echo -e "${LTCYAN}Removing stale snapshots from VM ${LTPURPLE}${VM} ${LTCYAN}...${NC}"
      run rm -rf ${VM_DIR}/${COURSE_ID}/${VM_NAME}/snapshots
    fi
  fi
  echo
}

back_up_vms() {
  echo -e "${LTBLUE}Backing up VMs ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  run mkdir -p ${COURSE_BACKUP_DIR}/VMs
  cd ${COURSE_VM_DIR}

  for VM in $(ls)
  do
    echo -e "${LTCYAN}--------------------------------------------------${NC}"
    echo -e "${LTCYAN}Gathering files for VM: ${LTPURPLE}${VM}${NC}"
    export_vm_config ${VM}
    mv_vm_nvram_file ${VM}
    backup_vm_tpm ${VM}
    dump_vm_snapshots ${VM}

    echo -e "${LTCYAN}Backing up VM: ${LTPURPLE}${VM}${NC}"
    run ${ARCHIVE_CMD} ${VM}.${ARCHIVE_EXT} ${VM}
    echo
    if ls ${VM_DIR_NAME}.${ARCHIVE_EXT}* 2> /dev/null | grep -q "001"
    then
      echo -e "${LTCYAN}Creating MD5 sums for VM ${LTPURPLE}${VM} ${LTCYAN}...${NC}"
      echo -e "${LTGREEN}COMMAND: ${NC}md5sum ${VM}.${ARCHIVE_EXT}* > ${VM}.${ARCHIVE_EXT}.md5sums${NC}"
      md5sum ${VM}.${ARCHIVE_EXT}* > ${VM}.${ARCHIVE_EXT}.md5sums
    fi
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
