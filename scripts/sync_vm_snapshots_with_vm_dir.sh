#!/bin/bash
# Version: 1.0.0
# Date: 2020-01-23

source ../config/include/colors.sh
source ../config/include/common_functions.sh

usage() {
  echo
  echo -e "${GRAY}USAGE: ${0} <course_id> <vm_name> ${NC}"
  echo
}

if [ -z ${1} ]
then
  echo -e "${RED}ERROR: You must supply a Course ID.${NC}"
  echo 
  usage
  exit
if [ -z ${2} ]
then
  echo -e "${RED}ERROR: You must supply a VM name.${NC}"
  echo 
  usage
  exit
else
  local COURSE_NUM=${1}
  local VM_NAME=${2}
fi

source ../config/include/global_vars.sh
source ../config/include/helper_functions.sh

main() {
  echo -e "${LTBLUE}################################################################${NC}"
  echo -e "${LTBLUE}Syncing snapshots for VM: ${LTPURPLE}${VM_NAME}${LTBLUE}${NC}"
  echo -e "${LTBLUE}into: ${GRAY}${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots/${NC}"
  echo -e "${LTBLUE}################################################################${NC}"
  echo

  if ! [ -d ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME} ]
  then
    local SNAPSHOT_LIST=$(virsh snapshot-list ${VM_NAME} | grep -v "^---" | grep -v "^ Name" | grep -v "^$" | awk '{ print $1 }')
    if ! [ -z "${SNAPSHOT_LIST}" ]
    then
      echo -e "${LTCYAN}Syncing snapshots for VM ${LTPURPLE}${VM} ${LTCYAN}...${NC}"
      if [ -e ${VM_DIR}/${COURSE_ID}/${VM_NAME}/snapshots ]
      then
        run rm -rf ${VM_DIR}/${COURSE_ID}/${VM_NAME}/snapshots
      fi
      run mkdir ${VM_DIR}/${COURSE_ID}/${VM_NAME}/snapshots

      dump_vm_snapshots ${VM_NAME}
      update_snapshot_uuid ${VM_NAME}
      update_snapshot_disk_paths ${VM_NAME}
    else
      echo -e "${LTCYAN}Removing stale snapshots for VM ${LTPURPLE}${VM} ${LTCYAN}...${NC}"
      if [ -e ${VM_DIR}/${COURSE_ID}/${VM_NAME}/snapshots ]
      then
        run rm -rf ${VM_DIR}/${COURSE_ID}/${VM_NAME}/snapshots
      fi
    fi
  else
    echo
    echo -e "${LTRED}ERROR: The specified VM does not exist in ${GRAY}${VM_DEST_DIR}/${COURSE_NUM}/${LTRED} ...  Exiting.${NC}"
    echo
    exit 1
  fi

  echo
  echo -e "${LTBLUE}########################### Done ###############################${NC}"
  echo
}

#############################################################################
#                Main Code Body
#############################################################################

main $*
