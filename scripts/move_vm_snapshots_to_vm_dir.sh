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

print_what_to_do_next_1() {
  echo -e "${ORANGE} +---------------------------------------------------------------------------${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | In the installation framework snapshots cannot have spaces in their names.${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | Please open the snpashot XML files in: ${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | ${LTPURPLE}${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots/${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | -edit the first instance of the <name> tag to be a name without spaces ${NC}"
  echo -e "${ORANGE} |  (If the name does not contain spaces then leave it unedited)${NC}"
  echo -e "${ORANGE} | -delete the comment section at the top of the file beginning with <!-- ${NC}"
  echo -e "${ORANGE} |  and ending with --> ${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | -save the files after editing.${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | The rename all files using the following format: ${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} |  ${LTPURPLE}<creation_time>.<snapshot_name>.xml ${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | Where:${NC}"
  echo -e "${ORANGE} |   <creation_time> is the value in the <creationTime> tag in the file ${NC}"
  echo -e "${ORANGE} |   <snapshot_name>  is the  name of the snapshot (with no spaces in the name)${NC}"
  echo -e "${ORANGE} |   (i.e. value in the <name>> tag in the file) ${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | Rerun this command with the --restore-only option ${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} +---------------------------------------------------------------------------${NC}"
}

print_what_to_do_next_2() {
  echo -e "${ORANGE} +---------------------------------------------------------------------------${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | Please open the snpashot XML files in: ${NC}"
  echo -e "${ORANGE} | ${GRAY}${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots/${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | -delete the comment section at the top of the file beginning with <!-- ${NC}"
  echo -e "${ORANGE} |  and ending with --> ${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | -save the files after editing.${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | The rename all files using the folllwing format: ${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} |  <creation_time>.<snapshot_name>.xml ${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | Where:${NC}"
  echo -e "${ORANGE} |   <creation_time> is the value in the <creationTime> tag in the file ${NC}"
  echo -e "${ORANGE} |   <snapshot_name>  is the  name of the snapshot (with no spaces in the name)${NC}"
  echo -e "${ORANGE} |   (i.e. value in the <name>> tag in the file) ${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} +---------------------------------------------------------------------------${NC}"
}

main() {
  echo -e "${LTBLUE}################################################################${NC}"
  echo -e "${LTBLUE}Moving snapshots for VM: ${LTPURPLE}${VM_NAME}${LTBLUE}${NC}"
  echo -e "${LTBLUE}into: ${GRAY}${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots/${NC}"
  echo -e "${LTBLUE}################################################################${NC}"
  echo

  if ! [ -d ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME} ]
  then
    case ${RESTORE_SNAPSHOTS} in
      with-restore)
        dump_vm_snapshots ${VM_NAME}
        update_snapshot_uuid ${VM_NAME}
        update_snapshot_disk_paths ${VM_NAME}
        restore_vm_snapshots ${VM_NAME}
      ;;
      restore-only)
        restore_vm_snapshots ${VM_NAME}
      ;;
      *)
        #dump_vm_snapshots ${VM_NAME}
        copy_vm_snapshot_files ${VM_NAME}
        update_snapshot_uuid ${VM_NAME}
        update_snapshot_disk_paths ${VM_NAME}
        print_what_to_do_next_1
      ;;
    esac
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
