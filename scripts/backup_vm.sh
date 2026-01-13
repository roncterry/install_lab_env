#!/bin/bash

# version: 1.0.7
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

run () {
  echo -e "${LTGREEN}COMMAND: ${NC}$*${NC}"
  "$@"
}

usage() {
  echo
  echo -e "${LTGREEN}USAGE:${NC} $(basename "${0}") <vm_dir> [<archive_format>]${NC}"
  echo
  echo -e "${NC}     (The archive file(s) will be created in the directory that contains <vm_dir>)${NC}"
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
    echo
    echo -e "${LTRED}ERROR: You must provide the VM directory to backup.${NC}"
    echo
    usage
    exit
    exit
else
  if echo $* | grep -q "help"
  then
    echo
    usage
    echo
    exit
  else
    VM_PATH=${1}
  fi
fi

if ! [ -e ${VM_PATH} ]
then
  echo
  echo -e "${LTRED}ERROR: The provided VM (${LTGREEN}${VM_PATH}${LTRED}) doesn't exist.${NC}"
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

##############################################################################
#                          Functions
##############################################################################

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
    echo "  USAGE: mv_vm_nvram_file <vm_path>"
  else
    local VM_PATH=${1}
    local VM_NAME=$(basename ${VM_PATH})
    local VM_PARENT_DIR=$(pwd ${VM_PATH})
    local VM_ABSOLUTE_PATH=${VM_PARENT_DIR}/${VM_PATH}
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
    if echo ${NVRAM_FILE} | grep -q "${VM_PATH}/nvram"
    then
      local DO_CHOWN=Y
      # Look for NVRAM file
      if [ -e "${VM_PATH}/nvram/${NVRAM_FILE_NAME}" ]
      then
        echo -e "${LTCYAN}(NVRAM file already in VM's directory ... Skipping)${NC}"
      else
        run sudo mv ${NVRAM_FILE} ${VM_PATH}/nvram/
      fi
    else
      echo -e "${LTCYAN}(Will need to copy the NVRAM file and update the config ...)${NC}"
    fi

    echo -e "${LTCYAN}(OVMF: ${NC}${OVMF_BIN}${LTBLUE})${NC}"
    # Does ovmf in the live config already point to the VM's directory?
    if echo ${OVMF_BIN} | grep -q "${VM_PATH}/nvram"
    then
      local DO_CHOWN=Y
      # Look for OVMF bin
      if [ -e "${VM_PATH}/nvram/${OVMF_BIN_NAME}" ]
      then
        echo -e "${LTCYAN}(OVMF binary already in VM's directory ... Skipping)${NC}"
      else
        run sudo cp ${OVMF_BIN} ${VM_PATH}/nvram/
      fi
    else
      echo -e "${LTCYAN}(Will need to copy the OVMF binary and update the config ...)${NC}"
    fi

    # Does nvram in the live config point to the default NVRAM location?
    if echo ${NVRAM_FILE} | grep -q "/var/lib/libvirt/qemu/nvram"
    then
      echo -e "${LTCYAN}(Moving NVRAM file from default location to VM Directory ...)${NC}"
      run mkdir -p ${VM_PATH}/nvram
      run sudo mv ${NVRAM_FILE} ${VM_PATH}/nvram/
      run sudo chmod -R u+rwx,g+rws,o+r ${VM_PATH}/nvram
      run sudo chown -R ${USER}:${GROUPS} ${VM_PATH}/nvram
      run sed -i "s+\(^ *\)<nvram>.*+\1<nvram>${VM_ABSOLUTE_PATH}/nvram/${NVRAM_FILE_NAME}</nvram>+" ${VM_PATH}/${VM_NAME}.xml
    fi

    # Does ovmf in the live config point to the default ovmf location?
    if echo ${OVMF_BIN} | grep -q "/usr/share/qemu"
    then
      echo -e "${LTCYAN}(Copying OVMF binary from default location into VM Directory ...)${NC}"
      run mkdir -p ${VM_PATH}/nvram
      run sudo cp ${OVMF_BIN} ${VM_PATH}/nvram/
      run sudo chmod -R u+rwx,g+rws,o+r ${VM_PATH}/nvram
      run sudo chown -R ${USER}:${GROUPS} ${VM_PATH}/nvram
      #run sed -i "s+\(^ *\)<loader.*+\1<loader readonly=\"yes\" type=\"pflash\">${VM_ABSOLUTE_PATH}/nvram/${OVMF_BIN_NAME}</loader>+" ${VM_PATH}/${VM_NAME}.xml
    fi

    case ${DO_CHOWN}
    in
      Y)
        run sudo chmod -R u+rwx,g+rws,o+r ${VM_PARENT_DIR}/${VM_NAME}/nvram
        run sudo chown -R ${USER}:${GROUPS} ${VM_PARENT_DIR}/${VM_NAME}/nvram
      ;;
    esac
  elif [ -e ${VM_PARENT_DIR}/${VM_NAME}/nvram ]
  then
    echo -e "${LTCYAN}(NVRAM not defined in VM config but file is in VM Directory ...)${NC}"
    # In case the nvram dir exist in the VM's dir but not in the live config?
    run sudo chmod -R u+rwx,g+rws,o+r ${VM_PARENT_DIR}/${VM_NAME}/nvram
    run sudo chown -R ${USER}:${GROUPS} ${VM_PARENT_DIR}/${VM_NAME}/nvram
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
    local VM_PATH=${1}
    local VM_PARENT_DIR=$(pwd ${VM_PATH})
    local VM_NAME=$(basename ${VM_PATH})
  fi

  #local TPM_DIR="/var/lib/libvirt/swtpm/$(virsh dumpxml ${VM_NAME} | grep uuid | cut -d \> -f 2 | cut -d \< -f 1)"
  local VM_UUID="$(virsh dumpxml ${VM_NAME} | grep uuid | cut -d \> -f 2 | cut -d \< -f 1)"
  local TPM_DIR="/var/lib/libvirt/swtpm/${VM_UUID}"

  echo -e "${LTCYAN}Backing up TPM file to VM Directory ...${NC}"

  if [ -e ${TPM_DIR} ]
  then
    echo -e "${LTCYAN}(TPM: ${NC}${TPM_DIR}${LTBLUE})${NC}"
    run mkdir -p ${VM_PATH}/tpm
    if [ -e ${TPM_DIR}/tpm1.2 ]
    then
      echo -e "${LTCYAN}(TPM v1.2 found)${NC}"
      run sudo cp -R ${TPM_DIR}/tpm1.2 ${VM_PATH}/tpm/
    fi
    if [ -e ${TPM_DIR}/tpm2 ]
    then
      echo -e "${LTCYAN}(TPM v2 found)${NC}"
      run sudo cp -R ${TPM_DIR}/tpm2 ${VM_PATH}/tpm/
    fi
    run sudo chown -R ${USER}:${GROUPS} ${VM_PATH}/tpm
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
    local VM_PATH=${1}
    local VM_PARENT_DIR=$(pwd ${VM_PATH})
    local VM_NAME=$(basename ${VM_PATH})
  fi

  echo -e "${LTCYAN}Moving VM snapshots to VM Directory ...${NC}"

  local SNAPSHOT_LIST=$(virsh snapshot-list ${VM_NAME} | grep -v "^---" | grep -v "^ Name" | grep -v "^$" | awk '{ print $1 }')

  if ! [ -z "${SNAPSHOT_LIST}" ]
  then
    echo -e "${LTCYAN}-Dumping out snapshots for VM ${LTPURPLE}${VM} ${LTCYAN}...${NC}"
    if [ -e "${VM_PATH}"/snapshots ]
    then
      run rm -rf ${VM_PATH}/snapshots
      run mkdir ${VM_PATH}/snapshots
    else
      run mkdir ${VM_PATH}/snapshots
    fi
 
    for SNAPSHOT in ${SNAPSHOT_LIST}
    do
      echo -e "${LTGREEN}COMMAND:${NC} virsh snapshot-dumpxml ${VM_NAME} ${SNAPSHOT} > ${VM_PATH}/snapshots/${SNAPSHOT}.xml${NC}"
      virsh snapshot-dumpxml ${VM_NAME} ${SNAPSHOT} > ${VM_PATH}/snapshots/${SNAPSHOT}.xml
 
      local VM_UUID=$(virsh dumpxml ${VM_NAME} | grep uuid | head -1 | cut -d ">" -f 2 | cut -d "<" -f 1)
      local SNAPSHOT_CREATION_TIME=$(grep "<creationTime>.*" ${VM_PATH}/snapshots/${SNAPSHOT}.xml | cut -d ">" -f 2 | cut -d "<" -f 1)
 
      run mv ${VM_PATH}/snapshots/${SNAPSHOT}.xml ${VM_PATH}/snapshots/${SNAPSHOT_CREATION_TIME}.${SNAPSHOT}.xml
 
      unset VM_UUID
      unset SNAPSHOT_CREATION_TIME
    done
  else
    echo -e "${LTCYAN}(No snapshots for VM)${NC}"
    if [ -e "${VM_PATH}"/snapshots ]
    then
      echo -e "${LTCYAN}-Removing stale snapshots from VM directory...${NC}"
      run rm -rf ${VM_PATH}/snapshots
    fi
  fi
  echo
}

main() {
  VM_PARENT_DIR=$(pwd ${VM_PATH})
  VM_BASE_DIR=$(dirname $(pwd ${VM_PARENT_DIR}))
  VM_DIR_NAME=$(basename ${VM_PATH})

  echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
  echo -e "${LTCYAN}               Backing Up VM: ${LTPURPLE}${VM_DIR_NAME}${NC}"
  echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
  echo
  echo -e "${LTCYAN}Gathering files for VM: ${LTPURPLE}${VM}${NC}"
  echo
  export_vm_config ${VM_PATH}
  mv_vm_nvram_file ${VM_PATH}
  backup_vm_tpm ${VM_PATH}
  dump_vm_snapshots ${VM_PATH}

  echo -e "${LTCYAN}Backing up VM: ${LTPURPLE}${VM_DIR_NAME}${NC}"
  run cd ${VM_PARENT_DIR}
  run ${ARCHIVE_CMD} ${VM_DIR_NAME}.${ARCHIVE_EXT} ${VM_DIR_NAME}
  echo
  if ls ${VM_DIR_NAME}.${ARCHIVE_EXT}* 2> /dev/null | grep -q "001"
  then
    echo -e "${LTCYAN}Creating MD5 sums for VM ${LTPURPLE}${VM_DIR_NAME} ${LTCYAN}...${NC}"
    echo -e "${LTGREEN}COMMAND: ${NC}md5sum ${VM_DIR_NAME}.${ARCHIVE_EXT}* > ${VM_DIR_NAME}.${ARCHIVE_EXT}.md5sums${NC}"
    md5sum ${VM_DIR_NAME}.${ARCHIVE_EXT}* > ${VM_DIR_NAME}.${ARCHIVE_EXT}.md5sums
  fi
  echo

  echo -e "${LTCYAN}=========================  Backup Complete  =========================${NC}"
  echo
}

##############################################################################
#                          Main Code Body
##############################################################################

main ${*}

exit 0
