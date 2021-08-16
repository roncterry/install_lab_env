#!/bin/bash
# Version: 1.2.1
# Date: 2021-08-16

source ../config/include/global_vars.sh
source ../config/include/colors.sh
source ../config/include/common_functions.sh

usage() {
  echo
  echo -e "${GRAY}USAGE: ${0} <course_id>${NC}"
  echo
}

if [ -z ${1} ]
then
  echo
  echo -e "${LTRED}ERROR: You must provide a Course ID.${NC}"
  usage
  exit 1
else
  COURSE_NUM=${1}
fi

#############################################################################
#          Functions
#############################################################################

create_directories() {
  echo -e "${LTCYAN}Creating required directories ...${NC}"
  echo -e "${LTCYAN}-----------------------------------------${NC}"

  if ! [ -d ${COURSE_FILES_DEST_DIR}/${COURSE_NUM} ]
  then
    run mkdir -p ${COURSE_FILES_DEST_DIR}/${COURSE_NUM}
  fi

  if ! [ -d ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
  then
    run mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}
  fi

  if ! [ -d ${PDF_DEST_DIR}/${COURSE_NUM} ]
  then
    run mkdir -p ${PDF_DEST_DIR}/${COURSE_NUM}
  fi

  if ! [ -d ${VM_DEST_DIR}/${COURSE_NUM} ]
  then
    run mkdir -p ${VM_DEST_DIR}/${COURSE_NUM}
  fi

  if ! [ -d ${ISO_DEST_DIR}/${COURSE_NUM} ]
  then
    run mkdir -p ${ISO_DEST_DIR}/${COURSE_NUM}
  fi

  echo
}

copy_files() {
  echo -e "${LTCYAN}Copying required files ...${NC}"
  echo -e "${LTCYAN}-----------------------------------------${NC}"

  if [ -d ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
  then
    run cp -R ../config ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/
    run mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/libvirt.cfg
    run mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/ssh
  fi

  if [ -d ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
  then
    run cp -R ../scripts/* ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/
  fi

  if [ -d ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
  then
    run cp -R ../install_lab_env.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/
  fi

  if [ -d ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
  then
    run cp -R ../remove_lab_env.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/
  fi

  if [ -d ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
  then
    run cp -R ../backup_lab_env.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/
  fi

  run mv ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/lab_env.cfg.example ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/lab_env.cfg

  echo
}

update_config() {
  run sed -i "s+^COURSE_NAME=.*+COURSE_NAME=\"${COURSE_NUM}: \"+g" ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/lab_env.cfg
  run sed -i "s+^COURSE_NUM=.*+COURSE_NUM=\"${COURSE_NUM}\"+g" ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/lab_env.cfg
}

print_what_to_do_next() {
  echo -e "${ORANGE} +---------------------------------------------------------------------------${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | A skeleton installed course has been created for: ${LTPURPLE}${COURSE_NUM}${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | What's next?${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | Next you need to:${NC}"
  echo -e "${ORANGE} |  - create (or copy) your VMs in: ${LTPURPLE}${VM_DEST_DIR}/${COURSE_NUM}${NC}"
  echo -e "${ORANGE} |  - create (or copy) your Libvirt configs (virtual network definitions,${NC}"
  echo -e "${ORANGE} |    storage pool definitions, etc) in:${NC}"
  echo -e "${ORANGE} |   ${LTPURPLE}${LOCAL_LIBVIRT_CONFIG_DIR}${NC}"
  echo -e "${ORANGE} |  - Edit the lab_env.cfg file in: ${LTPURPLE}${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | When your lab environment is ready, to create a lab environment installer,${NC}"
  echo -e "${ORANGE} | Run the following command: ${GRAY}backup_lab_env.sh ${COURSE_NUM}${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | A course installer will be created in:${NC}"
  echo -e "${ORANGE} |  ${LTPURPLE}/install/courses/${COURSE_NUM}_backup-<some_time/date_stamp>${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} +---------------------------------------------------------------------------${NC}"
  echo
}

main() {
  echo -e "${LTBLUE}################################################################${NC}"
  echo -e "${LTBLUE}           Creating a Skeleton Installed Course${NC}"
  echo -e "${LTBLUE}################################################################${NC}"
  echo
  echo -e "${LTPURPLE}Course ID:               ${COURSE_NUM}${NC}"
  echo -e "${LTPURPLE}VM Directory:            ${VM_DEST_DIR}/${COURSE_NUM}${NC}"
  echo -e "${LTPURPLE}ISO Directory:           ${ISO_DEST_DIR}/${COURSE_NUM}${NC}"
  echo -e "${LTPURPLE}course_files Directory:  ${COURSE_FILES_DEST_DIR}/${COURSE_NUM}${NC}"
  echo -e "${LTPURPLE}scripts Directory:       ${SCRIPTS_DEST_DIR}/${COURSE_NUM}${NC}"
  echo -e "${LTPURPLE}pdf Directory:           ${PDF_DEST_DIR}/${COURSE_NUM}${NC}"
  echo

  if ! [ -d ${VM_DEST_DIR}${COURSE_NUM} ]
  then
    create_directories
    copy_files
    update_config
  fi

  echo
  echo -e "${LTBLUE}########################### Done ###############################${NC}"
  echo

  print_what_to_do_next
}
#############################################################################
#                Main Code Body
#############################################################################

main $*
