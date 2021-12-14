##############  Lab Env Install and Configure Functions ######################
# version: 5.9.1
# date: 2021-11-02
#

create_directories() {
  if ! [ -d ${ISO_DEST_DIR} ]
  then
    echo -e "${LTBLUE}Creating directory for ISO images ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    run sudo mkdir -p ${ISO_DEST_DIR}
    run sudo chmod -R 2777 ${ISO_DEST_DIR}
    echo
  fi
  #--test--------------------------------------------------
  if ! [ -d ${ISO_DEST_DIR} ]
  then
    IS_ERROR=Y
    FAILED_TASKS="${FAILED_TASKS},install_functions.create_directories:${ISO_DEST_DIR}"
  fi
  #--------------------------------------------------------

  if ! [ -d ${IMAGE_DEST_DIR} ]
  then
    echo -e "${LTBLUE}Creating directory for Cloud images ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    run sudo mkdir -p ${IMAGE_DEST_DIR}
    run sudo chmod -R 2777 ${IMAGE_DEST_DIR}
    echo
  fi
  #--test--------------------------------------------------
  if ! [ -d ${IMAGE_DEST_DIR} ]
  then
    IS_ERROR=Y
    FAILED_TASKS="${FAILED_TASKS},install_functions.create_directories:${IMAGE_DEST_DIR}"
  fi 
  #--------------------------------------------------------

  if ! [ -d "${VM_DEST_DIR}/${COURSE_NUM}" ]
  then
    echo -e "${LTBLUE}Creating directory for virtual machines ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    run sudo mkdir -p ${VM_DEST_DIR}/${COURSE_NUM}
    run sudo chmod -R 2777 ${VM_DEST_DIR}/${COURSE_NUM}
    echo
  fi
  #--test--------------------------------------------------
  if ! [ -d "${VM_DEST_DIR}/${COURSE_NUM}" ]
  then
    IS_ERROR=Y
    FAILED_TASKS="${FAILED_TASKS},install_functions.create_directories:${VM_DEST_DIR}/${COURSE_NUM}"
  fi
  #--------------------------------------------------------

  if ! [ -d ${SCRIPTS_DEST_DIR} ]
  then
    echo -e "${LTBLUE}Creating directory for lab automation scripts ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    run mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}
    run chmod -R 2777 ${SCRIPTS_DEST_DIR}/${COURSE_NUM}
    echo
  fi
  #--test--------------------------------------------------
  if ! [ -d ${SCRIPTS_DEST_DIR} ]
  then
    IS_ERROR=Y
    FAILED_TASKS="${FAILED_TASKS},install_functions.create_directories:${SCRIPTS_DEST_DIR}"
  fi
  #--------------------------------------------------------

  if ! [ -d ${PDF_DEST_DIR} ]
  then
    echo -e "${LTBLUE}Creating directory for PDF manuals and docs ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    run mkdir -p ${PDF_DEST_DIR}/${COURSE_NUM}
    run chmod -R g+s ${PDF_DEST_DIR}/${COURSE_NUM}
    echo
  fi
  #--test--------------------------------------------------
  if ! [ -d ${PDF_DEST_DIR} ]
  then
    IS_ERROR=Y
    FAILED_TASKS="${FAILED_TASKS},install_functions.create_directories:${PDF_DEST_DIR}"
  fi
  #--------------------------------------------------------
}

create_libvirt_virtual_networks() {
  if [ -z "${LIBVIRT_VNET_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Creating Libvirt virtual network(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VNET in ${LIBVIRT_VNET_LIST}
  do
    if ! sudo virsh net-list | grep -q "${VNET}$"
    then
      run sudo virsh net-define ${LIBVIRT_CONFIG_DIR}/${VNET}.xml
      run sudo virsh net-autostart ${VNET}
      run sudo virsh net-start ${VNET}
    elif [ "$(sudo virsh net-list | grep  ${VNET} | awk '{ print $2 }')" != active ]
    then
      run sudo virsh net-autostart ${VNET}
      if [ "$(sudo virsh net-list | grep  ${VNET} | awk '{ print $3 }')" != yes ]
      then
        run sudo virsh net-start ${VNET}
      fi
    fi

    #--test--------------------------------------------------
    if ! sudo virsh net-list | grep -q "${VNET}"
    then
      IS_ERROR=Y
      FAILED_TASKS="${FAILED_TASKS},install_functions.create_libvirt_virtual_networks:${VNET}"
    fi
    #--------------------------------------------------------
  done
  echo
}

create_new_veth_interfaces() {
  if [ -z "${VETH_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Creating New veth interfaces(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VETH in ${VETH_LIST}
  do
    local VETH_NAME=$(echo ${VETH} | cut -d , -f 1)
    local NODE_NUM=$(echo ${VETH} | cut -d , -f 2)
    local VETH_NET=$(echo ${VETH} | cut -d , -f 3)
    local VETH_NAME_A=${VETH_NAME}-nic
    local VETH_NAME_B=${VETH_NAME}

    configure_new_veth_interfaces ${VETH_NAME} ${NODE_NUM} ${VETH_NET}

    #--test--------------------------------------------------
    if ! ip addr show | grep -q ${VETH_NAME_A}
    then
      IS_ERROR=Y
      FAILED_TASKS="${FAILED_TASKS},install_functions.create_new_ovs_bridges:${VETH_NAME}"
    fi
    #--------------------------------------------------------

    echo
  done
}

create_new_ovs_bridges() {
  if [ -z "${OVS_BRIDGE_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Creating New Open vSwitch Bridge(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for OVS_BRIDGE in ${OVS_BRIDGE_LIST}
  do
    local OVS_BRIDGE_NAME=$(echo ${OVS_BRIDGE} | cut -d , -f 1)
    local NODE_NUM=$(echo ${OVS_BRIDGE} | cut -d , -f 2)
    local OVS_BRIDGE_NET=$(echo ${OVS_BRIDGE} | cut -d , -f 3)
    local OVS_BRIDGE_PHYSDEV=$(echo ${OVS_BRIDGE} | cut -d , -f 4)
    local OVS_BRIDGE_PARENT_BRIDGE=$(echo ${OVS_BRIDGE} | cut -d , -f 5)
    local OVS_BRIDGE_VLAN_TAG=$(echo ${OVS_BRIDGE} | cut -d , -f 6)

    configure_new_ovs_bridge ${OVS_BRIDGE_NAME} ${NODE_NUM} ${OVS_BRIDGE_NET} ${OVS_BRIDGE_PHYSDEV} ${OVS_BRIDGE_PARENT_BRIDGE} ${OVS_BRIDGE_VLAN_TAG}

    #--test--------------------------------------------------
    if ! sudo ovs-vsctl show | grep -q ${OVS_BRIDGE_NAME}
    then
      IS_ERROR=Y
      FAILED_TASKS="${FAILED_TASKS},install_functions.create_new_ovs_bridges:${OVS_BRIDGE_NAME}"
    fi
    #--------------------------------------------------------

    echo
  done
}

create_new_vlans() {
  if [ -z "${VLAN_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Creating New VLAN(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VLAN in ${VLAN_LIST}
  do
    local VLAN_NAME=$(echo ${VLAN} | cut -d , -f 1)
    local NODE_NUM=$(echo ${VLAN} | cut -d , -f 2)
    local VLAN_NET=$(echo ${VLAN} | cut -d , -f 3)
    local VLAN_ETHERDEV=$(echo ${VLAN} | cut -d , -f 4)
    local VLAN_ID=$(echo ${VLAN} | cut -d , -f 5)

    configure_new_vlan ${VLAN_NAME} ${NODE_NUM} ${VLAN_NET} ${VLAN_ETHERDEV} ${VLAN_ID}

    #--test--------------------------------------------------
    if ! [ -e /proc/net/vlan/${VLAN_NAME} ]
    then
      IS_ERROR=Y
      FAILED_TASKS="${FAILED_TASKS},install_functions.create_new_vlans:${VLAN_NAME}"
    fi
    #--------------------------------------------------------

    echo
  done
}

create_new_bridges() {
  if [ -z "${BRIDGE_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Creating New Bridge(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for BRIDGE in ${BRIDGE_LIST}
  do
    local BRIDGE_NAME=$(echo ${BRIDGE} | cut -d , -f 1)
    local NODE_NUM=$(echo ${BRIDGE} | cut -d , -f 2)
    local BRIDGE_NET=$(echo ${BRIDGE} | cut -d , -f 3)
    local BRIDGE_ETHERDEV=$(echo ${BRIDGE} | cut -d , -f 4)

    configure_new_bridge ${BRIDGE_NAME} ${NODE_NUM} ${BRIDGE_NET} ${BRIDGE_ETHERDEV}

    #--test--------------------------------------------------
    if ! sudo /usr/sbin/brctl show | grep -q ${BRIDGE_NAME}
    then
      IS_ERROR=Y
      FAILED_TASKS="${FAILED_TASKS},install_functions.create_new_bridges:${BRIDGE_NAME}"
    fi
    #--------------------------------------------------------

    echo
  done
}

create_vmware_networks() {
  if [ -e /usr/bin/vmware ]
  then
    if [ -z "${VMWARE_VNET_LIST}" ]
    then
      return
    fi
    echo -e "${LTBLUE}Creating VMware networks ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
     
    run sudo vmware-networks --stop
    echo

    run sudo cp /etc/vmware/networking /etc/vmware/networking.orig
    echo
     
    for VMNET_NAME in ${VMWARE_VNET_LIST}
    do
      if [ -e ${VMWARE_INSTALLER_DIR}/${VMNET_NAME}.tgz ] || [ -e ${VMWARE_INSTALLER_DIR}/${VMNET_NAME}.tbz ] || [ -e ${VMWARE_INSTALLER_DIR}/${VMNET_NAME}.tar.gz ] || [ -e ${VMWARE_INSTALLER_DIR}/${VMNET_NAME}.tar.bz2 ] || [ -e ${VMWARE_INSTALLER_DIR}/${VMNET_NAME}.7z ] || [ -e ${VMWARE_INSTALLER_DIR}/${VMNET_NAME}.7z.001 ] || [ -e ${VMWARE_INSTALLER_DIR}/${VMNET_NAME}.zip ]
      then
     
        echo
        echo -e "${LTCYAN}Create Network: ${GREEN}${VMNET_NAME}${NC}"
        echo -e "${LTCYAN}----------------------${NC}"

        local ARCHIVE_TYPE=$(get_archive_type ${VMWARE_INSTALLER_DIR}/${VMNET_NAME})
        extract_archive_sudo "${VMWARE_INSTALLER_DIR}/${VMNET_NAME}" /etc/vmware ${ARCHIVE_TYPE}
        echo
     
        run sudo chown -R root.root /etc/vmware/${VMNET_NAME}
        echo
     
        if [ -e /etc/vmware/${VMNET_NAME}/nat.mac ]
        then
          run sudo chmod 666 /etc/vmware/${VMNET_NAME}/nat.mac
          echo
        fi
     
        if [ -e /etc/vmware/${VMNET_NAME}/nat/nat.conf ]
        then
          run sudo chmod 665 /etc/vmware/${VMNET_NAME}/nat/nat.conf
          echo
        fi
     
        #run cd -
        echo
     
        run cp /etc/vmware/networking /tmp/
        run cat ${VMWARE_INSTALLER_DIR}/networking.${VMNET_NAME} >> /tmp/networking
        run sudo mv /tmp/networking /etc/vmware/
        echo
     
        run sudo chown root.root /etc/vmware/networking
        run sudo chmod 644 /etc/vmware/networking
        echo
      fi
    done
    
    run sudo vmware-networks --start
    echo
  fi
}

copy_libvirt_configs() {
  if [ -z "${LIBVIRT_VNET_LIST}" ]
  then
    if [ -z "${LIBVIRT_POOL_LIST}" ]
    then
      return
    fi
  fi
  if ! [ -d ${LOCAL_LIBVIRT_CONFIG_DIR} ]
  then
    echo -e "${LTBLUE}Creating directory for Libvirt configs ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    run mkdir -p ${LOCAL_LIBVIRT_CONFIG_DIR}
  fi
  run cp ${LIBVIRT_CONFIG_DIR}/*.xml ${LOCAL_LIBVIRT_CONFIG_DIR}/

  #--test--------------------------------------------------
  if ! [ -d ${LOCAL_LIBVIRT_CONFIG_DIR} ]
  then
    IS_ERROR=Y
    FAILED_TASKS="${FAILED_TASKS},install_functions.copy_libvirt_configs.create_dir:${LOCAL_LIBVIRT_CONFIG_DIR}"
  fi
  local SRC_LIBVIRT_CONFIGS=$(cd ${LIBVIRT_CONFIG_DIR};ls *.xml)
  local DST_LIBVIRT_CONFIGS=$(cd ${LOCAL_LIBVIRT_CONFIG_DIR};ls *.xml)
  for SRC_CONFIG in ${SRC_LIBVIRT_CONFIG}
  do
    if ! echo ${DST_LIBVIRT_CONFIGS} | grep -q ${SRC_CONFIG}
    then
      IS_ERROR=Y
      FAILED_TASKS="${FAILED_TASKS},install_functions.copy_libvirt_configs.copy_config:${SRC_CONFIG}"
    fi 
  done
  #--------------------------------------------------------
  
  echo
}

create_libvirt_storage_pools() {
  if [ -z "${LIBVIRT_POOL_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Creating Libvirt storage pool(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for POOL in ${LIBVIRT_POOL_LIST}
  do
    if ! sudo virsh pool-list | grep -q "${POOL}$"
    then
      run sudo virsh pool-define ${LIBVIRT_CONFIG_DIR}/${POOL}.xml
      run sudo virsh pool-build ${POOL}
      run sudo virsh pool-autostart ${POOL}
      run sudo virsh pool-start ${POOL}
    elif [ "$(sudo virsh pool-list | grep  ${POOL} | awk '{ print $2 }')" != active ]
    then
      run sudo virsh pool-autostart ${POOL}
      if [ "$(sudo virsh pool-list | grep  ${POOL} | awk '{ print $3 }')" != yes ]
      then
        run sudo virsh pool-start ${POOL}
      fi
    fi

    #--test--------------------------------------------------
    if ! sudo virsh pool-list | grep -q "${POOL}"
    then
      IS_ERROR=Y
      FAILED_TASKS="${FAILED_TASKS},install_functions.create_libvirt_storage_pools:${POOL}"
    fi
    #--------------------------------------------------------
  done
  echo
}

create_libvirt_storage_volumes() {
  if [ -z "${LIBVIRT_VOLUME_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Creating Libvirt storage volume(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VOLUME in ${LIBVIRT_VOLUME_LIST}
  do
    local POOL_NAME=$(echo ${VOLUME} | cut -d + -f 1)
    local VOLUME_NAME=$(echo ${VOLUME} | cut -d + -f 2)
    if sudo virsh pool-list | grep -q ${POOL_NAME}
    then
      if ! sudo virsh vol-list --pool ${POOL_NAME} | awk '{ print $1 }' | grep -q "^${VOLUME}"
      then
        run sudo virsh vol-create ${POOL_NAME} ${LIBVIRT_CONFIG_DIR}/${VOLUME}.xml
      fi
    fi

    #--test--------------------------------------------------
    if ! sudo virsh vol-list ${POOL_NAME} | grep -q "${VOLUME_NAME}"
    then
      IS_ERROR=Y
      FAILED_TASKS="${FAILED_TASKS},install_functions.create_libvirt_storage_volumes:${VOLUME_NAME}"
    fi
    #--------------------------------------------------------
  done
  echo
}

create_virtual_bmcs() {
  local DEFAULT_BMC_ADDR=127.0.0.1
  local DEFAULT_BMC_PORT=623
  local DEFAULT_BMC_USERNAME=admin
  local DEFAULT_BMC_PASSWORD=password
  local DEFAULT_BMC_URI=qemu:///system

  if [ -z "${VIRTUAL_BMC_LIST}" ]
  then
    return
  fi

  if ! which vbmc > /dev/null 2>&1
  then
    echo -e "${LTBLUE}The vbmc command does not seem to be available. Skipping virtual BMC creation ...${NC}"
    echo
    return
  else
    echo -e "${LTBLUE}Creating virtual BMC(s) ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  fi

  for BMC in ${VIRTUAL_BMC_LIST}
  do
    local VM_NAME=$(echo ${BMC} | cut -d , -f 1)
    local BMC_ADDR=$(echo ${BMC} | cut -d , -f 2)

    if [ -z "${BMC_ADDR}" ]
    then
      BMC_ADDR=${DEFAULT_BMC_ADDR}
    fi

    local BMC_PORT=$(echo ${BMC} | cut -d , -f 3)
    if [ -z "${BMC_PORT}" ]
    then
      BMC_PORT=${DEFAULT_BMC_PORT}
    fi

    local BMC_USERNAME=$(echo ${BMC} | cut -d , -f 4)
    if [ -z "${BMC_USERNAME}" ]
    then
      BMC_USERNAME=${DEFAULT_BMC_USERNAME}
    fi

    local BMC_PASSWORD=$(echo ${BMC} | cut -d , -f 5)
    if [ -z "${BMC_PASSWORD}" ]
    then
      BMC_PASSWORD=${DEFAULT_BMC_PASSWORD}
    fi

    local BMC_URI=$(echo ${BMC} | cut -d , -f 6)
    if [ -z "${BMC_URI}" ]
    then
      BMC_URI=${DEFAULT_BMC_URI}
    fi

    # --create the bmc---------------------------------------

    #>Option 1: use virtualbmc directly
    #if ! sudo vbmc list | grep -q ${VM_NAME}
    #then
    #  run sudo vbmc add ${VM_NAME} --address ${BMC_ADDR} --port ${BMC_PORT} --username ${BMC_USERNAME} --password ${BMC_PASSWORD} --libvirt-uri ${BMC_URI}
    #  run sudo vbmc start ${VM_NAME}
    #  run sudo vbmc show ${VM_NAME}
    #fi
    #
    ##--test--------------------------------------------------
    #if ! sudo vbmc list | grep -q "${VM_NAME}"
    #then
    #  IS_ERROR=Y
    #  FAILED_TASKS="${FAILED_TASKS},install_functions.create_virtual_bmcs:${VM_NAME}"
    #fi
    ##--------------------------------------------------------

    #>Option 2: use a function that uses virtualbmc
    virtualbmc_control create ${VM_NAME} ${BMC_ADDR} ${BMC_PORT} ${VIRTUAL_BMC_NETWORK} ${BMC_USERNAME} ${BMC_PASSWORD} ${BMC_URI}

    #--test--------------------------------------------------
    if ! virtualbmc_control test ${VM_NAME} ${BMC_ADDR} ${BMC_PORT} ${VIRTUAL_BMC_NETWORK} ${BMC_USERNAME} ${BMC_PASSWORD} ${BMC_URI}
    then
      IS_ERROR=Y
      FAILED_TASKS="${FAILED_TASKS},install_functions.create_virtual_bmcs:${VM_NAME}"
    fi
    #--------------------------------------------------------

    #>Option 3: Use a function that uses some other method
    #
    #
    ##--test--------------------------------------------------
    #if ???
    #then
    #  IS_ERROR=Y
    #  FAILED_TASKS="${FAILED_TASKS},install_functions.create_virtual_bmcs:${VM_NAME}"
    #fi
    ##--------------------------------------------------------
  done
  echo
}

copy_iso_images() {
  if [ -e ${ISO_SRC_DIR} ]
  then
    echo -e "${LTBLUE}Copying ISO images ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    if ! [ -e ${ISO_DEST_DIR}/${COURSE_NUM} ]
    then
      echo -e "${LTCYAN}(creating iso directory ...)${NC}"
      run mkdir ${ISO_DEST_DIR}/${COURSE_NUM}
      echo
    fi
    echo -e "${LTCYAN}(copying isos ...)${NC}"
    for ISO in ${ISO_LIST}
    do
      #-- Use cp instead of rsync 
      run cp -R ${ISO_SRC_DIR}/${ISO} ${ISO_DEST_DIR}/${COURSE_NUM}/
      #-- Use rsync instead of cp 
      #run rsync -a ${ISO_SRC_DIR}/${ISO} ${ISO_DEST_DIR}/${COURSE_NUM}
 
      #--test--------------------------------------------------
      #rm -rf ${ISO_DEST_DIR}/${COURSE_NUM}/*
      if ! [ -d ${ISO_DEST_DIR}/${COURSE_NUM} ]
      then
        IS_ERROR=Y
        FAILED_TASKS="${FAILED_TASKS},install_functions.copy_iso_images.create_dir:${ISO_DEST_DIR}/${COURSE_NUM}"
      fi
      #--------------------------------------------------------
    done
 
      #--test--------------------------------------------------
    if [ -d ${ISO_SRC_DIR} ]
    then
      local SRC_ISOS="$(cd ${ISO_SRC_DIR};ls | grep .iso)"
      local DST_ISOS="$(cd ${ISO_DEST_DIR}/${COURSE_NUM}/;ls | grep .iso)"
  
      #echo SRC_ISOS="${SRC_ISOS}"
      #echo
      #echo DST_ISOS="${DST_ISOS}"
      #echo
 
      for SRC_ISO in ${SRC_ISOS}
      do
        if ! echo "${DST_ISOS}" | grep -q ${SRC_ISO}
        then
          IS_ERROR=Y
          FAILED_TASKS="${FAILED_TASKS},install_functions.copy_iso_images.copy_iso:${SRC_ISO}"
        fi 
      done
    fi
    #--------------------------------------------------------
  else
    echo
    echo -e "${LTCYAN}(No ISOs to copy. Skipping ...)${NC}"
  fi

  echo
}

copy_cloud_images() {
#  if ! [ -e ${IMAGE_SRC_DIR}/${COURSE_NUM} ]
#  then
#    return
#  fi
  echo -e "${LTBLUE}Copying Cloud images ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  if [ -e ${IMAGE_SRC_DIR} ]
  then
    if ! [ -e ${IMAGE_DEST_DIR}/${COURSE_NUM} ]
    then
      echo -e "${LTCYAN}(creating images directory ...)${NC}"
      run mkdir ${IMAGE_DEST_DIR}/${COURSE_NUM}
      echo
    fi
    echo -e "${LTCYAN}(copying images ...)${NC}"
    for IMAGE in ${CLOUD_IMAGE_LIST}
    do
      #-- Use cp instead of rsync 
      #run cp -R ${IMAGE_SRC_DIR}/${COURSE_NUM}/${IMAGE} ${IMAGE_DEST_DIR}/${COURSE_NUM}/
      #-- Use rsync instead of cp 
      run rsync -a ${IMAGE_SRC_DIR}/${IMAGE} ${IMAGE_DEST_DIR}/${COURSE_NUM}/
 
      #--test--------------------------------------------------
      #rm -rf ${IMAGE_DEST_DIR}/${COURSE_NUM}/*
      if ! [ -d ${IMAGE_DEST_DIR}/${COURSE_NUM} ]
      then
        IS_ERROR=Y
        FAILED_TASKS="${FAILED_TASKS},install_functions.copy_cloud_images.create_dir:${IMAGE_DEST_DIR}/${COURSE_NUM}"
      fi
      #--------------------------------------------------------
    done
 
    #--test--------------------------------------------------
    if [ -d ${IMAGE_SRC_DIR} ]
    then
      local SRC_IMAGES=$(cd ${IMAGE_SRC_DIR};ls)
      local DST_IMAGES=$(cd ${IMAGE_DEST_DIR}/${COURSE_NUM}/;ls)
  
      #echo SRC_IMAGES="${SRC_IMAGES}"
      #echo
      #echo DST_IMAGES="${DST_IMAGES}"
      #echo
 
      for SRC_IMAGE in ${SRC_IMAGES}
      do
        if echo ${CLOUD_IMAGE_LIST} | grep -q $(basename ${SRC_IMAGE})
        then
          if ! echo ${DST_IMAGES} | grep -q ${SRC_IMAGE}
          then
            IS_ERROR=Y
            FAILED_TASKS="${FAILED_TASKS},install_functions.copy_cloud_images.copy_image:${SRC_IMAGE}"
          fi 
        fi
      done
    fi
    #--------------------------------------------------------
  else
    echo
    echo -e "${LTCYAN}(No images to copy. Skipping ...)${NC}"
  fi
  echo
}

copy_install_remove_scripts() {
  echo -e "${LTBLUE}Copying install/remove scripts ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  echo -e "${LTCYAN}Lab environment config ...${NC}"
  run mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/
  run cp -R config/lab_env*.cfg ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/
  echo

  echo -e "${LTCYAN}Lab environment install/remove scripts ...${NC}"
  run cp -R install_lab_env.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/
  run cp -R remove_lab_env.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/
  run cp -R backup_lab_env.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/
  run cp -R config/include ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/
  if [ -e config/custom-functions.sh ]
  then
    run cp -R config/custom-functions.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/
  fi
  if [ -e config/custom-install-commands.sh ]
  then
    run cp -R config/custom-install-commands.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/
  fi
  if [ -e config/custom-remove-commands.sh ]
  then
    run cp -R config/custom-remove-commands.sh ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/
  fi

  #NO_TESTS
  echo
}

copy_lab_environment_restore_scripts() {
  if [ -e ${SCRIPTS_SRC_DIR} ]
  then
    echo -e "${LTBLUE}Copying lab environment restore scripts ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"

    if ! [ -e ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
    then
      echo -e "${LTCYAN}(creating scripts directory ...)${NC}"
      run mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}
      echo
    fi
 
    local LAB_ENV_REST_SCRIPTS="$(cd ${SCRIPTS_SRC_DIR};ls)"

    for LAB_ENV_REST_SCRIPT in ${LAB_ENV_REST_SCRIPTS}
    do
      if [ -e ${SCRIPTS_SRC_DIR}/${LAB_ENV_REST_SCRIPT} ]
      then
        echo -e "${LTCYAN}${LAB_ENV_REST_SCRIPT} script ...${NC}"
 
        run cp -R ${SCRIPTS_SRC_DIR}/${LAB_ENV_REST_SCRIPT} ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/
        run chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${LAB_ENV_REST_SCRIPT}
 
        #--test--------------------------------------------------
        if ! [ -e ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${LAB_ENV_REST_SCRIPT} ]
        then
          IS_ERROR=Y
          FAILED_TASKS="${FAILED_TASKS},install_functions.copy_lab_scripts:${LAB_ENV_REST_SCRIPT}"
        fi
        #--------------------------------------------------------
 
        echo
      fi
    done
  fi
}

copy_autobuild_scripts() {
  if [ -e ${SCRIPTS_SRC_DIR} ]
  then
    echo -e "${LTBLUE}Copying autobuild scripts ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"

    if [ -e ${SCRIPTS_SRC_DIR}/${VM_AUTOBUILD_SCRIPT_DIR} ]
    then
      echo -e "${LTCYAN}VM autobuild scripts ...${NC}"

      if ! [ -e ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
      then
        echo -e "${LTCYAN}(creating scripts directory ...)${NC}"
        run mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}
        echo
      fi
      
      echo -e "${LTCYAN}VM autobuild scripts ...${NC}"
      run cp -R ${SCRIPTS_SRC_DIR}/${VM_AUTOBUILD_SCRIPT_DIR} ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/ > /dev/null 2>&1
      
      run chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${VM_AUTOBUILD_SCRIPT_DIR}/*.sh > /dev/null 2>&1
      
      run cp -R ${VM_AUTOBUILD_CONFIG_DIR}/*.cfg ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${VM_AUTOBUILD_SCRIPT_DIR}/ > /dev/null 2>&1

      #--test--------------------------------------------------
      if ! [ -d ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${VM_AUTOBUILD_SCRIPT_DIR} ]
      then
        IS_ERROR=Y
        FAILED_TASKS="${FAILED_TASKS},install_functions.copy_lab_scripts.create_dir:${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${VM_AUTOBUILD_SCRIPT_DIR}"
      fi
      local SRC_VM_AUTOBUILD_SCRIPTS=$(cd ${SCRIPT_SRC_DIR}/${VM_AUTOBUILD_SCRIPT_DIR};ls)
      local DST_VM_AUTOBUILD_SCRIPTS=$(cd ${SCRIPT_DEST_DIR}/${COURSE_NUM}/${VM_AUTOBUILD_SCRIPT_DIR}/;ls)
      for SRC_VM_AUTOBUILD_SCRIPT in ${SRC_VM_AUTOBUILD_SCRIPTS}
      do
        if ! echo ${DST_VM_AUTOBUILD_SCRIPTS} | grep -q ${SRC_VM_AUTOBUILD_SCRIPT}
        then
          IS_ERROR=Y
          FAILED_TASKS="${FAILED_TASKS},install_functions.copy_lab_scripts.copy_vm_autobuild_scripts:${SRC_VM_AUTOBUILD_SCRIPT}"
        fi 
      done
      #--------------------------------------------------------

      echo
    fi
  fi
}

copy_lab_automation_scripts() {
  if [ -e ${SCRIPTS_SRC_DIR} ]
  then
    echo -e "${LTBLUE}Copying lab automation scripts ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    if [ -e ${SCRIPTS_SRC_DIR}/${LAB_SCRIPT_DIR} ]
    then
      echo -e "${LTCYAN}Lab automation scripts ...${NC}"

      if ! [ -e ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
      then
        echo -e "${LTCYAN}(creating scripts directory ...)${NC}"
        run mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}
        echo
      fi
      
      echo -e "${LTCYAN}Lab automation scripts ...${NC}"
      run cp -R ${SCRIPTS_SRC_DIR}/${LAB_SCRIPT_DIR} ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/ > /dev/null 2>&1
      
      run chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${LAB_SCRIPT_DIR}/*.sh > /dev/null 2>&1
      
      run chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${LAB_SCRIPT_DIR}/*/*.sh > /dev/null 2>&1

      #--test--------------------------------------------------
      if ! [ -d ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${LAB_SCRIPT_DIR} ]
      then
        IS_ERROR=Y
        FAILED_TASKS="${FAILED_TASKS},install_functions.copy_lab_scripts.create_dir:${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${LAB_SCRIPT_DIR}"
      fi
      local SRC_LAB_SCRIPTS=$(cd ${SCRIPT_SRC_DIR}/${LAB_SCRIPT_DIR};ls)
      local DST_LAB_SCRIPTS=$(cd ${SCRIPT_DEST_DIR}/${COURSE_NUM}/${LAB_SCRIPT_DIR}/;ls)
      for SRC_LAB_SCRIPT in ${SRC_LAB_SCRIPTS}
      do
        if ! echo ${DST_LAB_SCRIPTS} | grep -q ${SRC_LAB_SCRIPT}
        then
          IS_ERROR=Y
          FAILED_TASKS="${FAILED_TASKS},install_functions.copy_lab_scripts.copy_lab_scripts:${SRC_LAB_SCRIPT}"
        fi 
      done
      #--------------------------------------------------------

      echo
    fi

  fi
}

copy_cloud_deploy_scripts() {
  if [ -e ${SCRIPTS_SRC_DIR} ]
  then
    echo -e "${LTBLUE}Copying cloud deploy scripts ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    if [ -e ${SCRIPTS_SRC_DIR}/${DEPLOY_CLOUD_SCRIPT_DIR} ]
    then
      echo -e "${LTCYAN}Deploy cloud scripts ...${NC}"

      if ! [ -e ${SCRIPTS_DEST_DIR}/${COURSE_NUM} ]
      then
        echo -e "${LTCYAN}(creating scripts directory ...)${NC}"
        run mkdir -p ${SCRIPTS_DEST_DIR}/${COURSE_NUM}
        echo
      fi
      
      run cp -R ${SCRIPTS_SRC_DIR}/${DEPLOY_CLOUD_SCRIPT_DIR} ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/ > /dev/null 2>&1
      
      run chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${DEPLOY_CLOUD_SCRIPT_DIR}/*.sh > /dev/null 2>&1
       
      run chmod +x ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${DEPLOY_CLOUD_SCRIPT_DIR}/*/*.sh > /dev/null 2>&1

      #--test--------------------------------------------------
      if ! [ -d ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${DEPLOY_CLOUD_SCRIPT_DIR} ]
      then
        IS_ERROR=Y
        FAILED_TASKS="${FAILED_TASKS},install_functions.copy_lab_scripts.create_dir:${SCRIPTS_DEST_DIR}/${COURSE_NUM}/${DEPLOY_CLOUD_SCRIPT_DIR}"
      fi
      local SRC_DEPLOY_CLOUD_SCRIPTS=$(cd ${SCRIPT_SRC_DIR}/${DEPLOY_CLOUD_SCRIPT_DIR};ls)
      local DST_DEPLOY_CLOUD_SCRIPTS=$(cd ${SCRIPT_DEST_DIR}/${COURSE_NUM}/${DEPLOY_CLOUD_SCRIPT_DIR}/;ls)
      for SRC_DEPLOY_CLOUD_SCRIPT in ${SRC_DEPLOY_CLOUD_SCRIPTS}
      do
        if ! echo ${DST_DEPLOY_CLOUD_SCRIPTS} | grep -q ${SRC_DEPLOY_CLOUD_SCRIPT}
        then
          IS_ERROR=Y
          FAILED_TASKS="${FAILED_TASKS},install_functions.copy_lab_scripts.copy_deploy_cloud_scripts:${SRC_DEPLOY_CLOUD_SCRIPT}"
        fi 
      done
      #--------------------------------------------------------

      echo
    fi
  fi
}

copy_pdfs() {
  if ! [ -e ${PDF_SRC_DIR} ]
  then
    return
  fi
  echo -e "${LTBLUE}Copying PDF manuals and docs ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  echo -e "${LTCYAN}(creating pdf directory ...)${NC}"
  run mkdir -p ${PDF_DEST_DIR}/${COURSE_NUM}
  echo
  if ls ${PDF_SRC_DIR}/* > /dev/null 2>&1
  then
    run cp -R ${PDF_SRC_DIR}/* ${PDF_DEST_DIR}/${COURSE_NUM}/

    #--test--------------------------------------------------
    if ! [ -d ${PDF_DEST_DIR}/${COURSE_NUM} ]
    then
      IS_ERROR=Y
      FAILED_TASKS="${FAILED_TASKS},install_functions.copy_pdfs.create_dir:${PDF_DEST_DIR}/${COURSE_NUM}"
    fi
    local SRC_PDFS=$(cd ${PDF_SRC_DIR};ls)
    local DST_PDFS=$(cd ${PDF_DEST_DIR}/${COURSE_NUM}/;ls)
    for SRC_PDF in ${SRC_PDFS}
    do
      if ! echo ${DST_PDFS} | grep -q ${SRC_PDF}
      then
        IS_ERROR=Y
        FAILED_TASKS="${FAILED_TASKS},install_functions.copy_pdfs:${SRC_PDF}"
      fi 
    done
    #--------------------------------------------------------

    echo
  else
    echo
    return
  fi
}

copy_course_files() {
  if [ -e ./course_files ]
  then
    echo -e "${LTBLUE}Copying course files ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    if ls ./course_files/* > /dev/null 2>&1
    then
      echo -e "${LTCYAN}(creating course_files directory ...)${NC}"
      run mkdir -p ${HOME}/course_files/${COURSE_NUM}
      echo
      echo -e "${LTCYAN}(copying course_files ...)${NC}"
      run cp -R course_files/* ${HOME}/course_files/${COURSE_NUM}/

      #--test--------------------------------------------------
      if ! [ -d ${HOME}/course_files/${COURSE_NUM} ]
      then
        IS_ERROR=Y
        FAILED_TASKS="${FAILED_TASKS},install_functions.copy_course_files.create_dir:${HOME}/course_files/${COURSE_NUM}"
      fi
      #--------------------------------------------------------

      echo
    else
      return
    fi
  fi
}

install_ssh_keys() {
  local DOIT

  if [ -e ${CONFIG_SRC_DIR}/ssh ]
  then
    echo -e "${LTBLUE}Copying ssh files ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    echo
    run cp -R ${CONFIG_SRC_DIR}/ssh  ${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/
    echo
  fi

  case ${INSTALL_SSH_KEYS} in
    y|Y|yes|Yes|YES)
      if ! [ -z "${SSH_FILE_LIST}" ]
      then
        echo -e "${LTBLUE}Installing SSH keys ...${NC}"
        echo -e "${LTBLUE}---------------------------------------------------------${NC}"
        if ! [ -e ~/.ssh ]
        then
          run mkdir -p ~/.ssh/
        fi

        for FILE in ${SSH_FILE_LIST}
        do
          if [ -e ~/.ssh/${FILE} ]
          then
            echo
            echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
            echo -e "${RED}  WARNING! The existing ~/.ssh/${FILE} file is to be replaced by${NC}"
            echo -e "${RED}           following file from the installer package:${NC}"
            echo
            echo -e "${RED}           ${CONFIG_SRC_DIR}/ssh/${FILE}${NC}"
            echo
            echo -e "${RED}           Press Y to continue or N to skip${NC}"
            echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
            echo -ne "${RED}Continue? [Y/n]: ${NC}"

            case ${FORCE} in
              y|Y)
                echo
                run cp ${CONFIG_SRC_DIR}/ssh/${FILE} ~/.ssh/
                echo  "${FILE}" >> ~/.ssh/.${COURSE_NUM}-installed_files
              ;;
              *)
                read DOIT
                case ${DOIT} in
                  N|n)
                    echo -e "${RED}  -skipping ...${NC}"
                  ;;
                  *)
                    echo
                    run cp ${CONFIG_SRC_DIR}/ssh/${FILE} ~/.ssh/
                    echo  "${FILE}" >> ~/.ssh/.${COURSE_NUM}-installed_files
                  ;;
                esac
              ;;
            esac

          else
            run cp ${CONFIG_SRC_DIR}/ssh/${FILE} ~/.ssh/
            echo  "${FILE}" >> ~/.ssh/.${COURSE_NUM}-installed_files
          fi
        done
        echo

        test -e ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/id_*
        test -e ~/.ssh/known_hosts && chmod 644 ~/.ssh/known_hosts
        chmod 644 ~/.ssh/*.pub
        test -e ~/.ssh/.${COURSE_NUM}-installed_files && chmod 644 ~/.ssh/.${COURSE_NUM}-installed_files

        #NO_TESTS
      fi
    ;;
    *)
      return
    ;;
  esac
}

extract_register_libvirt_vms() {
  if [ -z "${LIBVIRT_VM_LIST}" ]
  then
    return
  fi

  echo -e "${LTBLUE}Extracting and registering Libvirt virtual machines ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VM in ${LIBVIRT_VM_LIST}
  do
    echo -e "${LTCYAN}---------------------------------------------------------------${NC}"
    echo -e "${LTCYAN}VM Name:${GREEN} ${VM}${NC}"
    echo -e "${LTCYAN}---------------------------------------------------------------${NC}"

    local ARCHIVE_TYPE=$(get_archive_type "${VM_SRC_DIR}/${VM}")

    echo -e "${LTBLUE}Extracting VM ...${NC}"
    extract_archive "${VM_SRC_DIR}/${VM}" "${VM_DEST_DIR}/${COURSE_NUM}" ${ARCHIVE_TYPE}


    #--test--------------------------------------------------
    if ! [ -d "${VM_DEST_DIR}/${COURSE_NUM}" ]
    then
      IS_ERROR=Y
      FAILED_TASKS="${FAILED_TASKS},install_functions.extract_register_libvirt_vms.create_dir:${VM_DEST_DIR}/${COURSE_NUM}"
    fi

    local SRC_VMFILES=$(list_archive "${VM_SRC_DIR}/${VM}" ${ARCHIVE_TYPE})
    local DST_VMFILES=$(cd "${VM_DEST_DIR}/${COURSE_NUM}/";ls ${VM})

    local COUNT=1
    for SRC_VMFILE in ${SRC_VMFILES}
    do
      ((COUNT++))
      if ! echo ${DST_VMFILES} | grep -q $(echo ${SRC_VMFILE} | cut -d \/ -f 2)
      then
        IS_ERROR=Y
        FAILED_TASKS="${FAILED_TASKS},install_functions.extract_register_libvirt_vms.extract_vm:${VM}:${SRC_VMFILE}"
      fi 
    done
    unset COUNT
    #--------------------------------------------------------

    echo

    edit_libvirt_domxml

    case ${MULTI_LAB_MACHINE}
    in
      y|Y|yes|Yes|YES|t|T|true|True|TRUE)
        local VM_CONFIG="${VM}-${MULTI_LM_EXT}.xml"
      ;;
      *)
        local VM_CONFIG="${VM}.xml"
      ;;
    esac

    #case ${MULTI_LAB_MACHINE}
    #in
    #  y|Y|yes|Yes|YES|t|T|true|True|TRUE)
    #    if [ -e "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}" ]
    #    then
    #      echo -e "${LTBLUE}Registering VM with Libvirt ...${NC}"
    #      run sudo virsh define "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}"
    #    fi
    #    echo
    #  ;;
    #  *)
    #    if [ -e "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}" ]
    #    then
    #      echo -e "${LTBLUE}Registering VM with Libvirt ...${NC}"
    #      run sudo virsh define "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}"
    #    fi
    #    echo
    #  ;;
    #esac

    if [ -e "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}" ]
    then
      echo -e "${LTBLUE}Registering VM with Libvirt ...${NC}"
      run sudo virsh define "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}"

      #--test--------------------------------------------------
      if ! virsh list --all | grep -q ${VM}
      then
        if [ -e "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}" ]
        then
          IS_ERROR=Y
          FAILED_TASKS="${FAILED_TASKS},install_functions.extract_register_libvirt_vms.register_vm:${VM}"
        fi
      fi
      #--------------------------------------------------------
    fi
    echo

    if [ -e "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/tpm ]
    then
      restore_vm_tpm ${VM}
    fi

    if [ -e "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/snapshots ]
    then
      update_vm_snapshot_uuid ${VM}
      #update_vm_snapshot_disk_paths ${VM}
      restore_vm_snapshots ${VM}
    fi
    echo

    local VM_POOL_CONFIG=${VM}.pool.xml
    if [ -e "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_POOL_CONFIG}" ]
    then
      if ! sudo virsh pool-list | grep -q "${VM}$"
      then
      echo -e "${LTBLUE}Creating storage pool for VM ...${NC}"
        run sudo virsh pool-define "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_POOL_CONFIG}"
        run sudo virsh pool-build ${VM}
        run sudo virsh pool-autostart ${VM}
        run sudo virsh pool-start ${VM}
      elif [ "$(sudo virsh pool-list | grep  ${VM} | awk '{ print $2 }')" != active ]
      then
        run sudo virsh pool-autostart ${VM}
        if [ "$(sudo virsh pool-list | grep  ${VM} | awk '{ print $3 }')" != yes ]
        then
          run sudo virsh pool-start ${VM}
        fi
      fi

      #--test--------------------------------------------------
      if ! virsh pool-list --all | grep -q ${VM}
      then
        if [ -e "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_POOL_CONFIG}" ]
        then
          IS_ERROR=Y
          FAILED_TASKS="${FAILED_TASKS},install_functions.extract_register_libvirt_vms.create_pool_for_vm:${VM}"
        fi
      fi
      #--------------------------------------------------------
    fi
    echo

    if which vbmcctl > /dev/null
    then
      local VM_VBMC_CONFIG=${VM}.vbmc
      if [ -e "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_VBMC_CONFIG}" ]
      then
        if ! sudo vbmc list | grep -q "${VM}"
        then
        echo -e "${LTBLUE}Creating virtual BMC device for VM ...${NC}"
          run vbmcctl create config="${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_VBMC_CONFIG}"
        elif ! sudo vbmc list | grep "${VM}" | grep -q running
        then
          run vbmcctl delete config="${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_VBMC_CONFIG}"
          run vbmcctl create config="${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_VBMC_CONFIG}"
        fi
      
        #--test--------------------------------------------------
        if ! sudo vbmc list | grep -q ${VM}
        then
          if [ -e "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_VBMC_CONFIG}" ]
          then
            IS_ERROR=Y
            FAILED_TASKS="${FAILED_TASKS},install_functions.extract_register_libvirt_vms.create_vbmc_for_vm:${VM}"
          fi
        fi
        #--------------------------------------------------------
      fi
    fi
    echo
  done
  echo
}

create_initial_vm_snapshots() {
  case ${LIBVIRT_CREATE_INITIAL_SNAPSHOT} in
    Y|y|yes|Yes)
      echo -e "${LTBLUE}Creating initial Libvirt virtual machine snapshots ...${NC}"
      echo -e "${LTBLUE}---------------------------------------------------------${NC}"
      for VM in ${LIBVIRT_VM_LIST}
      do
        create_vm_snapshot ${VM} ${LIBVIRT_INITIAL_SNAPSHOT_NAME}
      done
    ;;
    *)
      return
    ;;
  esac

  #NO_TESTS
}

start_libvirt_vms() {
  if [ -z "${LIBVIRT_START_VM_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Starting Libvirt virtual machines ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VM in ${LIBVIRT_START_VM_LIST}
  do
    echo -e "${LTCYAN}VM Name:${GREEN}${VM}${NC}"
    echo -e "${LTCYAN}---------------------${NC}"
    run sudo virsh start ${VM}
    echo
  done

  #NO_TESTS
  echo
}

autobuild_libvirt_vms() {
  if [ -z "${LIBVIRT_AUTOBUILD_VM_CONFIG}" ]
  then
    return
  fi

  if [ -e ${LIBVIRT_AUTOBUILD_VM_CONFIG} ]
  then
    echo -e "${LTBLUE}Autobuilding Libvirt virtual machines ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    cd ${SCRIPTS_DEST_DIR}/${VM_AUTOBUILD_SCRIPT_DIR}/
    ./create-vms.sh config=${LIBVIRT_AUTOBUILD_VM_CONFIG}
  fi

  #NO_TESTS
}

print_multiple_machine_message() {
  if ! [ -z "${BRIDGE_LIST}" ]
  then
    local NODE_NUM="$(echo ${BRIDGE_LIST} | awk '{ print $1 }' | cut -d , -f 2)"

    echo -e "${ORANGE}---------------------------------------------------------------- ${NC}"
    echo
    echo -e "${ORANGE} It appears that you are using multiple lab machines in your ${NC}"
    echo -e "${ORANGE} lab environment with this being lab machine #${NODE_NUM}${NC}"
    echo
    echo -e "${ORANGE} Ensure that you run the install_lab_env.sh script on the other${NC}"
    echo -e "${ORANGE} lab machine(s) using the config file that corresponds to each machine${NC}"
    echo
    echo -e "${ORANGE} Example: ${NC}bash ./install_lab_env.sh config=${GREEN}<node_specific_config_file>${NC}"
    #echo
    #echo -e "${ORANGE} Enter the following command(s) on the other lab machine(s):${NC}"
    #echo
    #for BRIDGE in ${BRIDGE_LIST}
    #do
    #  local BRIDGE_NAME="$(echo ${BRIDGE} | cut -d , -f 1)"
    #  local NODE_NUM=""
    #  local BRIDGE_NET="$(echo ${BRIDGE} | cut -d , -f 3)"
    #  echo -e "${NC}  configure-new-bridge ${BRIDGE_NAME} <node number> ${BRIDGE_NET}${NC}"
    #done
    #echo
    #echo -e "${ORANGE} Where <node number> is the number of the lab machine ${NC}"
    #echo -e "${ORANGE}  (i.e. 2 for the second lab machine, 3 for the third, ...).${NC}"
    #echo -e "${ORANGE} ${NC}"
    #echo -e "${ORANGE} Make sure you use the multinode specific create-vms.cfg files${NC}"
    #echo -e "${ORANGE} when auto building your additional lab VMs.${NC}"
    #echo
    #echo -e "${ORANGE} IMPORTANT:${NC}"
    #echo -e "${ORANGE}   If you are using the autobuild-libvirt-vms feature of this${NC}"
    #echo -e "${ORANGE}   script, this should have been done before running this script${NC}"
    #echo -e "${ORANGE}   on lab machine #${NODE_NUM} If it wasn't, you may need to manually run${NC}"
    #echo -e "${ORANGE}   the create-vms.sh script again.${NC}"
    echo
    echo -e "${ORANGE}---------------------------------------------------------------- ${NC}"
    echo
  fi
}

extract_vmware_vms() {
  if [ -z "${VMWARE_VM_LIST}" ]
  then
    return
  fi

  echo -e "${LTBLUE}Extracting VMware virtual machines ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VM in ${VMWARE_VM_LIST}
  do
    echo -e "${LTCYAN}VM Name:${GREEN}${VM}${NC}"
    echo -e "${LTCYAN}---------------------${NC}"

    local ARCHIVE_TYPE=$(get_archive_type ${VM_SRC_DIR}/)

    extract_archive "${VM_SRC_DIR}/${VM}" "${VM_DEST_DIR}/${COURSE_NUM}" ${ARCHIVE_TYPE}

    echo

    #NO_TESTS
  done
}

start_vmware_vms() {
  if [ -z "${VMWARE_START_VM_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Starting VMware virtual machines ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VM in ${VMWARE_START_VM_LIST}
  do
    echo -e "${LTCYAN}VM Name:${GREEN}${VM}${NC}"
    echo -e "${LTCYAN}---------------------${NC}"
    run vmrun start "${VM_DEST_DIR}/${COURSE_NUM}/${VM}"
    echo
  done

  #NO_TESTS
  echo
}
