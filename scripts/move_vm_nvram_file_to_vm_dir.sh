#!/bin/bash
# Version: 1.0.0
# Date: 2020-01-23

source ../config/include/colors.sh
source ../config/include/common_functions.sh

usage() {
  echo
  echo -e "${GRAY}USAGE: ${0} <course_id> <vm_name> [--with-restore] [--restore-only]${NC}"
  echo 
  echo -e "${GRAY}-Do not use either of the \"restore\" options if your snapshots${NC}"
  echo -e "${GRAY} have spaces in thier names and follow the instructions at the end${NC}"
  echo 
  echo -e "${GRAY}-Use the \"--with-restore\" option if you _know_ your snapshots${NC}"
  echo -e "${GRAY} _do_not_ have spaces in thier names${NC}"
  echo 
  echo -e "${GRAY}-Use the \"--restore-only\" option if you: ${NC}"
  echo -e "${GRAY} *previously ran the command without any of the \"restore\" options${NC}"
  echo -e "${GRAY} *and have edied your snapshot names to not have spaces in them${NC}"
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
  case ${3} in
    with-restore|--with-restore)
      RESTORE_SNAPSHOTS=with-restore
    ;;
    restore-only|--restore-only)
      RESTORE_SNAPSHOTS=restore-only
    ;;
  esac
fi

source ../config/include/global_vars.sh
source ../config/include/helper_functions.sh

print_what_to_do_next() {
  echo -e "${ORANGE} +---------------------------------------------------------------------------${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | The NVRAM file for the VM was moved into the VM's directory and the VM's${NC}"
  echo -e "${ORANGE} | XML config file was updated. You will need to use the command:${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | ${GRAY}virsh edit ${VM_NAME}${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | To update the path to the NVRAM file in the VM's current XML config${NC}"
  echo -e "${ORANGE} | in Libvirt${NC}"
  echo -e "${ORANGE} | ${LTPURPLE}${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots/${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} +---------------------------------------------------------------------------${NC}"
}

main() {
  echo -e "${LTBLUE}################################################################${NC}"
  echo -e "${LTBLUE}Moving NVRAM file for VM: ${LTPURPLE}${VM_NAME}${LTBLUE}${NC}"
  echo -e "${LTBLUE}into: ${GRAY}${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram/${NC}"
  echo -e "${LTBLUE}################################################################${NC}"
  echo

  if ! [ -d ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME} ]
  then
    move_vm_nvram_file ${VM_NAME}
    print_what_to_do_next
  else
    echo
    echo -e "${LTRED}ERROR: The specified VM does not exist in ${GRAY}${VM_DEST_DIR}/${COURSE_NUM}/${LTRED} ...  Exiting.${NC}"
    echo
    exit 1
  fi

#  echo
#  echo -e "${LTBLUE}########################### Done ###############################${NC}"
#  echo
}

#############################################################################
#                Main Code Body
#############################################################################

main $*
