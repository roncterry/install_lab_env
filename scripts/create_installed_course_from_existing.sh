#!/bin/bash
# Version: 1.1.1
# Date: 2019-10-16

source ../config/include/colors.sh
source ../config/include/common_functions.sh

usage() {
  echo
  echo -e "${GRAY}USAGE: ${0} <course_id> vms=<comma delimited list of VM names> [networks=<comma delimited list of networks>] [isos=<comma delimited list of ISO images>] [course_files=<comma delimited list of course files>] [cloud_images=<comma delimited list of cloud images>]${NC}"
  echo
}

if [ -z ${1} ]
then
  echo
  echo -e "${LTRED}ERROR: You must provide a Course ID.${NC}"
  usage
  exit 1
else
  export COURSE_NUM=${1}
fi

if ! echo $* | grep -q "vms=.*"
then
  echo
  echo -e "${LTRED}ERROR: You must provide a list of VMs for the course.${NC}"
  usage
  exit 1
fi

source ../config/include/global_vars.sh

#############################################################################
#          Functions
#############################################################################

get_existing_objects() {
 export EXISTING_VM_LIST="$(echo $* | grep -o "vms=.*" | cut -d " " -f 1 | cut -d \  -f 1 | cut -d = -f 2 | sed 's/,/ /g')"
 export EXISTING_NETWORK_LIST="$(echo $* | grep -o "networks=.*" | cut -d " " -f 1 | cut -d \  -f 1 | cut -d = -f 2 | sed 's/,/ /g')"
 export EXISTING_ISO_LIST="$(echo $* | grep -o "isos=.*" | cut -d " " -f 1 | cut -d \  -f 1 | cut -d = -f 2 | sed 's/,/ /g')"
 export EXISTING_CLOUD_IMAGE_LIST="$(echo $* | grep -o "cloud_images=.*" | cut -d " " -f 1 | cut -d \  -f 1 | cut -d = -f 2 | sed 's/,/ /g')"
 export EXISTING_COURSE_FILES_LIST="$(echo $* | grep -o "course_files=.*" | cut -d " " -f 1 | cut -d \  -f 1 | cut -d = -f 2 | sed 's/,/ /g')"
}

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
    echo
    run sudo mkdir -p ${VM_DEST_DIR}/${COURSE_NUM}
    run sudo chown ${USER}.users ${VM_DEST_DIR}/${COURSE_NUM}
    run sudo chmod g+rws,o+rwx ${VM_DEST_DIR}/${COURSE_NUM}
  fi

  if ! [ -d ${ISO_DEST_DIR}/${COURSE_NUM} ]
  then
    echo
    run mkdir -p ${ISO_DEST_DIR}/${COURSE_NUM}
    run sudo chown ${USER}.users ${ISO_DEST_DIR}
    run sudo chmod g+rws,o+rwx ${ISO_DEST_DIR}
  fi

  if ! [ -d ${IMAGE_DEST_DIR}/${COURSE_NUM} ]
  then
    echo
    run mkdir -p ${IMAGE_DEST_DIR}/${COURSE_NUM}
    run sudo chown ${USER}.users ${IMAGE_DEST_DIR}
    run sudo chmod g+rws,o+rwx ${IMAGE_DEST_DIR}
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
    echo
  fi

  if [ -d ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
  then
    run cp -R ../scripts/* ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/
    echo
  fi

  if [ -d ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
  then
    run cp -R ../install_lab_env.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/
    echo
  fi

  if [ -d ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
  then
    run cp -R ../remove_lab_env.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/
    echo
  fi

  if [ -d ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
  then
    run cp -R ../backup_lab_env.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/
    echo
  fi

  run mv ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/lab_env.cfg.example ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/lab_env.cfg

  echo
}

copy_existing_vms() {
  echo -e "${LTCYAN}Copying specified existing VMs ...${NC}"
  echo -e "${LTCYAN}-----------------------------------------${NC}"

  for EXISTING_VM in ${EXISTING_VM_LIST}
  do
    if virsh list --all | grep -q ${EXISTING_VM}
    then
      echo -e "${LTBLUE}VM: ${GRAY}${EXISTING_VM}${NC}"
      run mkdir -p ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}

      echo -e "${LTGREEN}COMMAND: ${GRAY}virsh dumpxml ${EXISTING_VM} > ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}/${EXISTING_VM}.xml${NC}"
      virsh dumpxml ${EXISTING_VM} > ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}/${EXISTING_VM}.xml

      local EXISTING_VM_DISK_LIST=$(virsh dumpxml ${EXISTING_VM} | grep "<source file=.*" | cut -d \' -f 2)
 
      for EXISTING_VM_DISK in ${EXISTING_VM_DISK_LIST}
      do
        echo -e "${LTCYAN}(Disk: ${GRAY}${EXISTING_VM_DISK}${LTBLUE})${NC}"
        run sudo mv ${EXISTING_VM_DISK} ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}/
        #run sudo cp ${EXISTING_VM_DISK} ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}/
        run sudo chown -R ${USER}.users ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}
        run sudo chmod u+rwx,g+rw,o+r ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}/*
        run sed -i "s+\(.*<source file=\)'.*${EXISTING_VM_DISK}'\(.*\)+\1'${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}/$(basename ${EXISTING_VM_DISK})'\2+" ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}/${EXISTING_VM}.xml
      done

      local NVRAM_FILE=$(virsh dumpxml ${EXISTING_VM} | grep nvram | cut -d \> -f 2 | cut -d \< -f 1)
      if ! [ -z ${NVRAM_FILE} ]
      then
        local NVRAM_FILE_NAME=$(basename ${NVRAM_FILE})
        echo -e "${LTCYAN}(NVRAM: ${GRAY}${NVRAM_FILE}${LTBLUE})${NC}"
        run mkdir -p ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}/nvram
        run sudo mv ${NVRAM_FILE} ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}/nvram/
        run sudo chmod -R u+rwx,g+rws,o+r ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}/nvram
        #run sudo cp ${NVRAM_FILE} ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}/nvram/
        run sed -i "s+\(^ *\)<nvram>.*+\1<nvram>${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}/nvram/${NVRAM_FILE_NAME}</nvram>+" ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}/${EXISTING_VM}.xml
      fi

      echo -e "${LTCYAN}(Cleanup XML${LTBLUE})${NC}"
      run sed -i '/^ *<uuid.*/d' ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}/${EXISTING_VM}.xml

      export VM_NETWORKS="${VM_NETWORKS} $(virsh dumpxml ${EXISTING_VM} | grep "<source network=.*" | cut -d \' -f 2)"
      export VM_ISOS="${VM_ISOS} $(virsh dumpxml ${EXISTING_VM} | grep "<source file=.*" | cut -d \' -f 2 | grep ".iso")"

      echo -e "${LTCYAN}(Redefine VM)${NC}"
      run sudo chown -R ${USER}.users ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}
      run sudo chmod u+rwx,g+rws,o+r ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}
      run virsh undefine --nvram --remove-all-storage --managed-save --delete-snapshots ${EXISTING_VM}
      run virsh define ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}/${EXISTING_VM}.xml

      echo
    else
      echo "${LTBLUE} (VM ${LTGRAY}${EXISTING_VM}${LTBLUE} not found. Skipping.)"
    fi
  done
  echo
}

copy_existing_networks() {
  echo -e "${LTCYAN}Copying specified existing networks ...${NC}"
  echo -e "${LTCYAN}-----------------------------------------${NC}"

  run mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/libvirt.cfg

  if [ -z ${EXISTING_NETWORK_LIST} ]
  then
    for NETWORK in ${VM_NETWORKS}
    do
      if ! echo ${EXISTING_NETWORK_LIST} | grep -q ${NETWORK} 
      then
        EXISTING_NETWORK_LIST="${EXISTING_NETWORK_LIST} ${NETWORK}"
      fi
    done
  fi

  for EXISTING_NETWORK in ${EXISTING_NETWORK_LIST}
  do
    if virsh net-list --all | grep -q ${EXISTING_NETWORK}
    then
      echo -e "${LTBLUE}Network: ${GRAY}${EXISTING_VM}${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY}virsh net-dumpxml ${EXISTING_NETWORK} > ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/libvirt.cfg/${EXISTING_NETWORK}.xml${NC}"
      virsh net-dumpxml ${EXISTING_NETWORK} > ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/libvirt.cfg/${EXISTING_NETWORK}.xml

      echo -e "${LTCYAN}(Cleanup XML${LTBLUE})${NC}"
      run sed -i '/^ *<uuid.*/d' ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/libvirt.cfg/${EXISTING_NETWORK}.xml
      run sed -i "s/name='.*'/name='${EXISTING_NETWORK}'/" ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/libvirt.cfg/${EXISTING_NETWORK}.xml

      echo -e "${LTCYAN}(Redefine Network)${NC}"
      run virsh net-destroy ${EXISTING_NETWORK}
      run virsh net-undefine ${EXISTING_NETWORK}
      run virsh net-define ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/libvirt.cfg/${EXISTING_NETWORK}.xml
      run virsh net-start ${EXISTING_NETWORK}
      run virsh net-autostart ${EXISTING_NETWORK}
    else
      echo "${LTBLUE} (Network ${LTGRAY}${EXISTING_NETWORK}${LTBLUE} not found. Skipping.)"
    fi
  done
  echo
}

copy_existing_isos() {
  echo -e "${LTCYAN}Copying specified ISO images ...${NC}"
  echo -e "${LTCYAN}-----------------------------------------${NC}"

  run mkdir -p ${ISO_DEST_DIR}/${COURSE_NUM}

  if [ -z ${EXISTING_ISO_LIST} ]
  then
    echo -e "${LTBLUE}(no ISOs specified)${NC}"
  else
    for EXISTING_ISO in ${EXISTING_ISO_LIST}
    do
      if [ -e ${EXISTING_ISO} ]
      then
        run cp ${EXISTING_ISO} ${ISO_DEST_DIR}/${COURSE_NUM}/
      fi
    done
  fi
  echo
}

copy_existing_cloud_images() {
  echo -e "${LTCYAN}Copying specified cloud images ...${NC}"
  echo -e "${LTCYAN}-----------------------------------------${NC}"

  run mkdir -p ${IMAGE_DEST_DIR}/${COURSE_NUM}

  if [ -z ${EXISTING_CLOUD_IMAGE_LIST} ]
  then
    echo -e "${LTBLUE}(no ISOs specified)${NC}"
  else
    for EXISTING_CLOUD_IMAGE in ${EXISTING_CLOUD_IMAGE_LIST}
    do
      if [ -e ${EXISTING_CLOUD_IMAGE} ]
      then
        run cp ${EXISTING_CLOUD_IMAGE} ${IMAGE_DEST_DIR}/${COURSE_NUM}/
      fi
    done
  fi
  echo
}

copy_existing_course_files() {
  echo -e "${LTCYAN}Copying specified existing course_files ...${NC}"
  echo -e "${LTCYAN}-----------------------------------------${NC}"

  run mkdir -p ${COURSE_FILES_DEST_DIR}/${COURSE_NUM}
  for EXISTING_COURSE_FILE in ${EXISTING_COURSE_FILE_LIST}
  do
    if [ -e ${EXISTING_COURSE_FILE} ]
    then
      run cp -R ${EXISTING_COURSE_FILE} > ${COURSE_FILES_DEST_DIR}/${COURSE_NUM}/
    else
      echo "${LTBLUE} (File/directory ${LTGRAY}${EXISTING_COURSE_FILE}${LTBLUE} not found. Skipping.)"
    fi
  done
  echo
}

update_config() {
  run sed -i "s+^COURSE_NAME=.*+COURSE_NAME=\"${COURSE_NUM}: \"+g" ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/lab_env.cfg
  run sed -i "s+^COURSE_NUM=.*+COURSE_NUM=\"${COURSE_NUM}\"+g" ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/lab_env.cfg
  run sed -i "s+^LIBVIRT_VM_LIST=.*+LIBVIRT_VM_LIST=\"${EXISTING_VM_LIST}\"+g" ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/lab_env.cfg
  run sed -i "s+^LIBVIRT_VNET_LIST=.*+LIBVIRT_VNET_LIST=\"${EXISTING_NETWORK_LIST}\"+g" ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/lab_env.cfg
  run sed -i "s+^ISO_LIST=.*+ISO_LIST=\"${EXISTING_ISO_LIST}\"+g" ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/lab_env.cfg
  run sed -i "s+^CLOUD_IMAGE_LIST=.*+CLOUD_IMAGE_LIST=\"${EXISTING_CLOUD_IMAGE_LIST}\"+g" ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/lab_env.cfg
}

print_what_to_do_next() {
  echo -e "${ORANGE} +---------------------------------------------------------------------------${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | An installed course has been created for: ${LTPURPLE}${COURSE_NUM}${NC}"
  echo -e "${ORANGE} | The VMs, networks, files, ISOs, cloud images, etc you specified have been copied into it.${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | What's next?${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | Next you need to:${NC}"
  echo -e "${ORANGE} |  - Verify your VMs in: ${LTPURPLE}${VM_DEST_DIR}/${COURSE_NUM}${NC}"
  echo -e "${ORANGE} |  - Verify the disk paths were updated to the new location of the VM's disks.${NC}"
  echo -e "${ORANGE} |    If you have multiple VMs sharing the same ISO, please move that ISO image into${NC}"
  echo -e "${ORANGE} |    ${LTPURPLE}${ISO_DEST_DIR}/${COURSE_NUM}${ORANGE} and update the VMs to point to it instead.${NC}"
  echo -e "${ORANGE} |    (delete the copies of the ISO image that were copied into the individual VM directroies)${NC}"
  echo -e "${ORANGE} |    Please ensure that VM names follow the standards, updating them if needed.${NC}"
  echo -e "${ORANGE} |  - Verify your Libvirt configs (network definitions, storage pool definitions, etc) in:${NC}"
  echo -e "${ORANGE} |   ${LTPURPLE}${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/libvirt.cfg${NC}"
  echo -e "${ORANGE} |    Please ensure that network and bridge names follow the standards, updating${NC}"
  echo -e "${ORANGE} |    them if needed.${NC}"
  echo -e "${ORANGE} |  - Edit the ${LTPURPLE}lab_env.cfg${ORANGE} file in: ${LTPURPLE}${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | When your lab environment is ready, to create a lab environment installer,${NC}"
  echo -e "${ORANGE} | run the following command: ${GRAY}backup_lab_env.sh ${COURSE_NUM}${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | A course installer will be created in:${NC}"
  echo -e "${ORANGE} |  ${LTPURPLE}/install/courses/${COURSE_NUM}_backup-<some_time/date_stamp>${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} | Test installing/removing the course using the installer that was created.${NC}"
  echo -e "${ORANGE} | (Please test on a different machine than it was originally created on)${NC}"
  echo -e "${ORANGE} |${NC}"
  echo -e "${ORANGE} +---------------------------------------------------------------------------${NC}"
  echo
}

main() {
  get_existing_objects $*

  echo -e "${LTBLUE}################################################################${NC}"
  echo -e "${LTBLUE}      Creating an Installed Course from Existing Files${NC}"
  echo -e "${LTBLUE}################################################################${NC}"
  echo
  echo -e "${LTPURPLE}Course ID:               ${COURSE_NUM}${NC}"
  echo -e "${LTPURPLE}VM Directory:            ${VM_DEST_DIR}${NC}"
  echo -e "${LTPURPLE}ISO Directory:           ${ISO_DEST_DIR}/${COURSE_NUM}${NC}"
  echo -e "${LTPURPLE}course_files Directory:  ${COURSE_FILES_DEST_DIR}/${COURSE_NUM}${NC}"
  echo -e "${LTPURPLE}scripts Directory:       ${SCRIPTS_DEST_DIR}/${COURSE_NUM}${NC}"
  echo -e "${LTPURPLE}pdf Directory:           ${PDF_DEST_DIR}/${COURSE_NUM}${NC}"
  echo
  echo -e "${LTPURPLE}Existing VMs:            ${EXISTING_VM_LIST}${NC}"
  if [ -z ${EXISTING_NETWORK_LIST} ]
  then
    echo -e "${LTPURPLE}Existing Networks:       (probed from VMs)${NC}"
  else
    echo -e "${LTPURPLE}Existing Networks:       ${EXISTING_NETWORK_LIST}${NC}"
  fi
  echo -e "${LTPURPLE}Existing ISOs:           ${EXISTING_ISO_LIST}${NC}"
  echo -e "${LTPURPLE}Existing Course Files:   ${EXISTING_COURSE_FILES_LIST}${NC}"
  echo

  echo -e "${ORANGE}Presss Enter to continue ${NC}";read
  echo

  if ! [ -d ${VM_DEST_DIR}/${COURSE_NUM} ]
  then
    create_directories
    copy_files
    copy_existing_vms
    copy_existing_networks
    copy_existing_isos
    copy_existing_course_files
    update_config
  else
    echo
    echo -e "${LTRED}ERROR: The specified course already exists. Exiting."
    echo
    exit 1
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
