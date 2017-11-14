##############  Remove Lab Env Functions ##################################
# version: 4.1.5
# date: 2017-11-14
#

remove_libvirt_networks() {
  if [ -z "${LIBVIRT_VNET_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Removing Libvirt virtual network(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VNET in ${LIBVIRT_VNET_LIST}
  do
      run sudo virsh net-destroy ${VNET}
      run sudo virsh net-undefine ${VNET}
  done
  echo
}

remove_new_bridges() {
  if [ -z "${BRIDGE_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Removing New Bridge(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for BRIDGE in ${BRIDGE_LIST}
  do
    local BRIDGE_NAME=$(echo ${BRIDGE} | cut -d , -f 1)
    local NODE_NUM=$(echo ${BRIDGE} | cut -d , -f 2)
    local BRIDGE_NET=$(echo ${BRIDGE} | cut -d , -f 3)
    local IFCFG_FILE="/etc/sysconfig/network/ifcfg-${BRIDGE_NAME}"
    echo 

    echo -e "${LTCYAN}Bridge: ${BRIDGE_NAME} ...${NC}"
    run sudo /sbin/ifdown ${BRIDGE_NAME}
    run sudo rm -rf ${IFCFG_FILE}
    echo
  done
}

remove_new_vlans() {
  if [ -z "${VLAN_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Removing New VLAN(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VLAN in ${VLAN_LIST}
  do
    local VLAN_NAME=$(echo ${VLAN} | cut -d , -f 1)
    local NODE_NUM=$(echo ${VLAN} | cut -d , -f 2)
    local VLAN_NET=$(echo ${VLAN} | cut -d , -f 3)
    local IFCFG_FILE="/etc/sysconfig/network/ifcfg-${VLAN_NAME}"
    echo 

    echo -e "${LTCYAN}VLAN: ${VLAN_NAME} ...${NC}"
    run sudo /sbin/ifdown ${VLAN_NAME}
    run sudo rm -rf ${IFCFG_FILE}
    echo
  done
}

remove_new_nics() {
  echo -e "${LTBLUE}Removing New NIC(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for IFCFG_FILE in $(ls /etc/sysconfig/network/ifcfg-*)
  do
    if sudo grep -q "created by install_lab_env" ${IFCFG_FILE}
    then
      local NIC_NAME=$(basename ${IFCFG_FILE} | sed 's/ifcfg-//g')
      run sudo /sbin/ifdown ${NIC_NAME}
      run sudo rm -rf ${IFCFG_FILE}
    fi
  done
}

remove_libvirt_volumes() {
  if [ -z "${LIBVIRT_VOLUME_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Removing Libvirt storage volume(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VOLUME in ${LIBVIRT_VOLUME_LIST}
  do
    local POOL_NAME=$(echo ${VOLUME} | cut -d + -f 1)
    local VOLUME_NAME=$(echo ${VOLUME} | cut -d + -f 2)
      run sudo virsh vol-delete --pool ${POOL_NAME} --vol ${VOLUME_NAME}
  done
  echo
}

remove_libvirt_pools() {
  if [ -z "${LIBVIRT_POOL_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Removing Libvirt storage pools(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for POOL in ${LIBVIRT_POOL_LIST}
  do
      run sudo virsh pool-destroy ${POOL}
      #run sudo virsh pool-delete ${POOL}
      run sudo virsh pool-undefine ${POOL}
  done
  echo
}

remove_iso_images() {
  #if ! [ -e ${ISO_SRC_DIR} ]
  #then
  #  return
  #fi
  echo -e "${LTBLUE}Removing ISO images ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  run rm -rf ${ISO_DEST_DIR}/${COURSE_NUM}
  echo
}

remove_cloud_images() {
  if ! [ -e ${IMAGE_SRC_DIR} ]
  then
    return
  fi
  echo -e "${LTBLUE}Remove Cloud images ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  run rm -rf ${IMAGE_DEST_DIR}/${COURSE_NUM}
  echo
}

remove_course_files() {
  if [ -e ${HOME}/course_files ]
  then
    echo -e "${LTBLUE}Remove course files ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    run rm -rf ${HOME}/course_files/${COURSE_NUM}
    echo
  fi
}

remove_lab_scripts() {
  if [ -d ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
  then
    echo -e "${LTBLUE}Removing lab scripts ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    if [ -e ${SCRIPTS_DEST_DIR}/${VM_AUTOBUILD_SCRIPT_DIR} ]
    then
      echo -e "${LTCYAN}VM autobuild scripts ...${NC}"
      run rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${VM_AUTOBUILD_SCRIPT_DIR}
      echo
    fi
    
    if [ -e ${SCRIPTS_DEST_DIR}/${LAB_SCRIPT_DIR} ]
    then
      echo -e "${LTCYAN}Lab automation scripts ...${NC}"
      run rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${LAB_SCRIPT_DIR}
      echo
    fi
    
    if [ -e ${SCRIPTS_DEST_DIR}/${DEPLOY_CLOUD_SCRIPT_DIR} ]
    then
      echo -e "${LTCYAN}Deploy cloud scripts ...${NC}"
      run rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${DEPLOY_CLOUD_SCRIPT_DIR}
      echo
    fi
    
    if [ -e ${LOCAL_LIBVIRT_CONFIG_DIR} ]
    then
      echo -e "${LTCYAN}Libvirt configs ...${NC}"
      run rm -rf ${LOCAL_LIBVIRT_CONFIG_DIR}
      echo
    fi
    
    if [ -e ${SCRIPTS_DEST_DIR}/restore-virtualization-environment.sh ]
    then
      echo -e "${LTCYAN}restore-virtualization-environment.sh  script ...${NC}"
      run rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/restore-virtualization-environment.sh
      echo
    fi
    
    echo -e "${LTCYAN}${COURSE_NUM} scripts ...${NC}"
    run rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}
    echo

  else
    echo "No lab scripts seem to have been installed."
  fi
}
    
remove_removal_scripts() {
  if [ -d ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
  then
    echo -e "${LTBLUE}Removing removal scripts ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    if [ -e ${SCRIPTS_DEST_DIR}/config ]
    then
      echo -e "${LTCYAN}Lab environment config ...${NC}"

      run rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config
      echo
    fi
    
    if [ -e ${SCRIPTS_DEST_DIR}/remove_lab_env.sh ]
    then
      echo -e "${LTCYAN}Lab environment removal script ...${NC}"

      run rm -rf ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/remove_lab_env.sh
      echo
    fi
  fi
}

remove_pdfs() {
  if ! [ -e ${PDF_DEST_DIR}/${COURSE_NUM} ]
  then
    return
  fi
  echo -e "${LTBLUE}Removing PDF manuals and docs ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  run rm -rf ${PDF_DEST_DIR}/${COURSE_NUM}
  echo
}

remove_libvirt_vms() {
  if [ -z "${LIBVIRT_VM_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Removing Libvirt virtual machines ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VM in ${LIBVIRT_VM_LIST}
  do
    echo -e "${LTCYAN}---------------------------------------------------------------${NC}"
    echo -e "${LTCYAN}VM Name:${GREEN} ${VM}${NC}"
    echo -e "${LTCYAN}---------------------------------------------------------------${NC}"
    run sudo virsh destroy ${VM}
    run sudo virsh undefine --remove-all-storage --snapshots-metadata --wipe-storage ${VM}
    echo
    echo -e "${LTCYAN}Deleting:${GREEN} ${VM_DEST_DIR}/${VM}${NC}"
    echo -e "${LTCYAN}-------------------------------------${NC}"
    run sudo rm -rf ${VM_DEST_DIR}/${VM}
  done

  run rm -rf ${VM_DEST_DIR}

  if ! [ -z ${LIBVIRT_AUTOBUILD_VM_CONFIG} ]
  then
    if [ -e ${LIBVIRT_AUTOBUILD_VM_CONFIG} ]
    then
      cd ${SCRIPTS_DEST_DIR}/${VM_AUTOBUILD_SCRIPT_DIR}/
      ./destroy-vms.sh config=${LIBVIRT_AUTOBUILD_VM_CONFIG}
    fi
  fi
  echo
}

remove_vmware_vms() {
  if [ -z "${VMWARE_VM_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Removing VMware virtual machines ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VM in $(vmrun list | grep -iv "Total running VMs.*")
  do
    echo -e "${LTCYAN}VM Name:${GREEN} ${VM}${NC}"
    echo -e "${LTCYAN}---------------------${NC}"
    run vmrun stop ${VM}
    echo
    echo -e "${LTCYAN}Deleting: ${VM_DEST_DIR}/${VM}${NC}"
    echo -e "${LTCYAN}---------------------------------${NC}"
    run rm -rf ${VM_DEST_DIR}/${VM}
  done

  run rm -rf ${VM_DEST_DIR}
  echo
}

remove_vmware_networks() {
  if [ -z "${VMWARE_VNET_LIST}" ]
  then
    return
  fi

  echo -e "${LTBLUE}Removing VMware networks ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"

  run sudo vmware-networks --stop
  echo

  for VMNET_NAME in ${VMWARE_VNET_LIST}
  do
    echo -e "${LTCYAN}Remove Network: ${VMNET_NAME}${NC}"
    echo -e "${LTCYAN}----------------------${NC}"

    run sudo rm -rf /etc/vmware/${VMNET_NAME}
  done

  run sudo mv /etc/vmware/networking.orig /etc/vmware/networking
  echo

  run sudo chown root.root /etc/vmware/networking
  run sudo chmod 644 /etc/vmware/networking
  echo

  run sudo vmware-networks --start
  echo
}

remove_vmware() {
  if ! [ -e /usr/bin/vmware-installer ]
  then
    return
  fi

  VMWARE_PROD="$(sudo /usr/bin/vmware-installer --console -l | tac | head -n 1 | awk '{ print $1 }')"

  echo -e "${LTBLUE}Removing VMware ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  echo
  run sudo /usr/bin/vmware-installer --console -u ${VMWARE_PROD} -I --required
  echo
  run sudo rm -f /etc/vmware/license-ws*
  echo
}

remove_ssh_keys() {
  case ${INSTALL_SSH_KEYS} in
    y|Y|yes|Yes|YES)
      if ! [ -z "${SSH_FILE_LIST}" ]
      then
        echo -e "${LTBLUE}Removing SSH keys ...${NC}"
        echo -e "${LTBLUE}---------------------------------------------------------${NC}"
        for FILE in $(cat ~/.ssh/.${COURSE_NUM}-installed_files)
        do
          run rm -f ~/.ssh/${FILE}
        done
          run rm -f ~/.ssh/${COURSE_NUM}-installed_files
        echo
      fi
    ;;
    *)
      return
    ;;
  esac
}
