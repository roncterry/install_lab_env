##############  Helper Functions #############################################
# version: 3.4.2
# date: 2017-09-18
#

configure_nic() {
  if [ -z $1 ]
  then
    echo
    echo -e "${LTRED}ERROR: Missing NIC name.${NC}"
    echo
    echo -e "${GRAY}USAGE: $0 <nic_name> <node_number> <nic_network> <boot_protocol> <start_mode>${NC}"
    echo
    return 1
  elif [ -z $2 ]
  then
    echo
    echo -e "${LTRED}ERROR: Missing node number.${NC}"
    echo -e "${LTRED}       The node number must be a number between 1 and 9.${NC}"
    echo
    echo -e "${GRAY}USAGE: $0 <nic_name> <node_number> <nic_network> <boot_protocol> <start_mode>${GRAY}"
    echo
    return 1
  elif ! echo $2 | grep -q [1-9]
  then
    echo
    echo -e "${LTRED}ERROR: The node number must be a number between 1 and 9.${NC}"
    echo
    return 1
  elif [ -z $3 ]
  then
    echo
    echo -e "${LTRED}ERROR: The NIC network must be the network ID of the bridge with CIDR mask.${NC}"
    echo -e "${GRAY}       Example: 192.168.124.0/24${NC}"
    echo
    echo -e "${GRAY}USAGE: $0 <nic_name> <node_number> <nic_network> <boot_protocol> <start_mode>${NC}"
    echo
    return 1
  elif [ -z $4 ]
  then
    echo
    echo -e "${LTRED}ERROR: The boot protocol must be one of the following:${NC}"
    echo -e "${GRAY}         static${NC}"
    echo -e "${GRAY}         dhcp${NC}"
    echo -e "${GRAY}         none${NC}"
    echo
    echo -e "${GRAY}USAGE: $0 <nic_name> <node_number> <nic_network> <boot_protocol> <start_mode>${NC}"
    echo
    return 1
  elif [ -z $5 ]
  then
    echo
    echo -e "${LTRED}ERROR: The start mode must be one of the following:${NC}"
    echo -e "${GRAY}         auto${NC}"
    echo -e "${GRAY}         hotplug${NC}"
    echo -e "${GRAY}         off${NC}"
    echo
    echo -e "${GRAY}USAGE: $0 <nic_name> <node_number> <nic_network> <boot_protocol> <start_mode>${NC}"
    echo
    return 1
  else
    local NIC_NAME=$1
    local NODE_NUM=$2
    case ${3} in
      -)
        local NIC_NETWORK=""
      ;;
      *)
        local NIC_NETWORK=$3
      ;;
    esac
    local NIC_BOOTPROTO=$4
    local NIC_START_MODE=$5
  fi

  #-----------------------------------------------------------------------------

  local TMP_FILE="/tmp/ifcfg-${NIC_NAME}"
  local IFCFG_FILE="/etc/sysconfig/network/ifcfg-${NIC_NAME}"
  case ${IP_NETWORK} in
    -)
      local IP_NETWORK=""
    ;;
    *)
      local IP_NETWORK="$(echo ${NIC_NETWORK} | cut -d / -f 1 | cut -d . -f 1,2,3)"
    ;;
  esac
  if ! [ -z ${IP_NETWORK} ]
  then
    local IP_ADDR="${IP_NETWORK}.${NODE_NUM}"
    local CIDRMASK="/$(echo ${NIC_NETWORK} | cut -d / -f 2)"
    local CIDR_IP_ADDR="${IP_ADDR}${CIDRMASK}"
  else
    local CIDR_IP_ADDR=""
  fi
  local BOOTPROTO="${NIC_BOOTPROTO}"

  #-----------------------------------------------------------------------------

  if [ -e ${IFCFG_FILE} ]
  then
    echo
    echo -e "${LTRED}ERROR: An ifcfg- file with that name already exists:${GRAY} $(basename ${IFCFG_FILE})${NC}"
    echo
    return 1
  else
    echo
    echo -e "${LTPURPLE}NIC name:${GRAY}        ${NIC_NAME}${NC}"
    echo -e "${LTPURPLE}IP address:${GRAY}      ${CIDR_IP_ADDR}${NC}"
    echo -e "${LTPURPLE}Writing out:${GRAY}     ${IFCFG_FILE}${NC}"
    echo

    echo "#created by install_lab_env" >> ${TMP_FILE}
    echo "BOOTPROTO='${BOOTPROTO}'" >> ${TMP_FILE}
    echo "BROADCAST=''" >> ${TMP_FILE}
    echo "ETHTOOL_OPTIONS=''" >> ${TMP_FILE}
    echo "IPADDR='${CIDR_IP_ADDR}'" >> ${TMP_FILE}
    echo "MTU=''" >> ${TMP_FILE}
    echo "NAME=''" >> ${TMP_FILE}
    echo "NETMASK=''" >> ${TMP_FILE}
    echo "NETWORK=''" >> ${TMP_FILE}
    echo "REMOTE_IPADDR=''" >> ${TMP_FILE}
    echo "STARTMODE='${NIC_START_MODE}'" >> ${TMP_FILE}

    sudo mv ${TMP_FILE} ${IFCFG_FILE}
  fi

  echo -e "${LTBLUE}Starting:${LTGRAY} ${NIC_NAME}${NC}"
  sudo /sbin/ifdown ${NIC_NAME}
  sudo /sbin/ifup ${NIC_NAME}
}

configure_new_vlan() {
  if [ -z $1 ]
  then
    echo
    echo -e "${LTRED}ERROR: Missing vlan name.${NC}"
    echo
    echo -e "${GRAY}USAGE: $0 <vlan_name> <node_number> <vlan_network> <eth_dev> <vlan_id>${NC}"
    echo
    return 1
  elif [ -z $2 ]
  then
    echo
    echo -e "${LTRED}ERROR: Missing node number.${NC}"
    echo -e "${LTRED}       The node number must be a number between 1 and 9.${NC}"
    echo
    echo -e "${GRAY}USAGE: $0 <vlan_name> <node_number> <vlan_network> <eth_dev> <vlan_id>${GRAY}"
    echo
    return 1
  elif ! echo $2 | grep -q [1-9]
  then
    echo
    echo -e "${LTRED}ERROR: The node number must be a number between 1 and 9.${NC}"
    echo
    return 1
  elif [ -z $3 ]
  then
    echo
    echo -e "${LTRED}ERROR: The VLAN network must be the network ID of the bridge with CIDR mask.${NC}"
    echo -e "${GRAY}       Example: 192.168.124.0/24${NC}"
    echo
    echo -e "${GRAY}USAGE: $0 <vlan_name> <node_number> <vlan_network> <eth_dev> <vlan_id>${NC}"
    echo
    return 1
  elif [ -z $4 ]
  then
    echo
    echo -e "${LTRED}ERROR: The VLAN ethernet device must be the name of an existing network interface.${NC}"
    echo -e "${GRAY}       Example: eth1${NC}"
    echo
    echo -e "${GRAY}USAGE: $0 <vlan_name> <node_number> <vlan_network> <eth_dev> <vlan_id>${NC}"
    echo
    return 1
  elif [ -z $5 ]
  then
    echo
    echo -e "${LTRED}ERROR: The VLAN ID must be an integer number between 1-2000.${NC}"
    echo -e "${GRAY}       Example: 124${NC}"
    echo
    echo -e "${GRAY}USAGE: $0 <vlan_name> <node_number> <vlan_network> <eth_dev> <vlan_id>${NC}"
    echo
    return 1
  else
    local VLAN_NAME=$1
    local NODE_NUM=$2
    case ${3} in
      -)
        local VLAN_NETWORK=""
      ;;
      *)
        local VLAN_NETWORK=$3
      ;;
    esac
    local VLAN_ETHERDEV=$4
    local VLAN_ID=$5
  fi

  #-----------------------------------------------------------------------------

  local TMP_FILE="/tmp/ifcfg-${VLAN_NAME}"
  local IFCFG_FILE="/etc/sysconfig/network/ifcfg-${VLAN_NAME}"
  local IP_NETWORK="$(echo ${VLAN_NETWORK} | cut -d / -f 1 | cut -d . -f 1,2,3)"
  if ! [ -z ${IP_NETWORK} ]
  then
    local IP_ADDR="${IP_NETWORK}.${NODE_NUM}"
    local CIDRMASK="/$(echo ${VLAN_NETWORK} | cut -d / -f 2)"
    local CIDR_IP_ADDR="${IP_ADDR}${CIDRMASK}"
  else
    local CIDR_IP_ADDR=""
  fi
  local BOOTPROTO="static"
  local NET_DEV_LIST="$(for IFACE in $(sudo yast lan list 2>&1 > /dev/null | grep "^[0-9]" | awk '{ print $1 }');do sudo yast lan show id=$IFACE 2>&1 >/dev/null | grep "Device Name" | awk '{ print $3 }';done)"

  #-----------------------------------------------------------------------------

  if ! [ -e /etc/sysconfig/network/ifcfg-${VLAN_ETHERDEV} ]
  then
    echo -e "${LTBLUE}Creating new NIC (${VLAN_ETHERDEV}) for VLAN:${LTGRAY}${NC}"
    configure_nic ${VLAN_ETHERDEV} 1 - none hotplug
  fi

  if [ -e ${IFCFG_FILE} ]
  then
    echo
    echo -e "${LTRED}ERROR: An ifcfg- file with that name already exists:${GRAY} $(basename ${IFCFG_FILE})${NC}"
    echo
    return 1
  elif ! echo ${NET_DEV_LIST} | grep -q ${VLAN_ETHERDEV}
  then
    echo
    echo -e "${LTRED}ERROR: The specified ethernet device (${VLAN_ETHERDEV}) is not available.${NC}"
    echo
    return 1
  else
    echo
    echo -e "${LTPURPLE}VLAN name:${GRAY}       ${VLAN_NAME}${NC}"
    echo -e "${LTPURPLE}VLAN ID:${GRAY}         ${VLAN_ID}${NC}"
    echo -e "${LTPURPLE}Ethernet Device:${GRAY} ${VLAN_ETHERDEV}${NC}"
    echo -e "${LTPURPLE}IP address:${GRAY}      ${CIDR_IP_ADDR}${NC}"
    echo -e "${LTPURPLE}Writing out:${GRAY}     ${IFCFG_FILE}${NC}"
    echo

    echo "#created by install_lab_env" >> ${TMP_FILE}
    echo "BOOTPROTO='${BOOTPROTO}'" >> ${TMP_FILE}
    echo "BROADCAST=''" >> ${TMP_FILE}
    echo "ETHERDEVICE='${VLAN_ETHERDEV}'" >> ${TMP_FILE}
    echo "ETHTOOL_OPTIONS=''" >> ${TMP_FILE}
    echo "IPADDR='${CIDR_IP_ADDR}'" >> ${TMP_FILE}
    echo "MTU=''" >> ${TMP_FILE}
    echo "NAME=''" >> ${TMP_FILE}
    echo "NETMASK=''" >> ${TMP_FILE}
    echo "NETWORK=''" >> ${TMP_FILE}
    echo "REMOTE_IPADDR=''" >> ${TMP_FILE}
    echo "STARTMODE='auto'" >> ${TMP_FILE}
    echo "VLAN_ID='${VLAN_ID}'" >> ${TMP_FILE}

    sudo mv ${TMP_FILE} ${IFCFG_FILE}
  fi

  echo -e "${LTBLUE}Starting:${LTGRAY} ${VLAN_NAME}${NC}"
  sudo /sbin/ifup ${VLAN_NAME}
}

configure_new_bridge() {
  if [ -z $1 ]
  then
    echo
    echo -e "${LTRED}ERROR: Missing bridge name.${NC}"
    echo
    echo -e "${GRAY}USAGE: $0 <bridge_name> <node_number> <bridge_network> <ethernet_device>${NC}"
    echo
    return 1
  elif [ -z $2 ]
  then
    echo
    echo -e "${LTRED}ERROR: Missing node number.${NC}"
    echo -e "${LTRED}       The node number must be a number between 1 and 9.${NC}"
    echo
    echo -e "${GRAY}USAGE: $0 <bridge_name> <node_number> <bridge_network> <ethernet_device>${GRAY}"
    echo
    return 1
  elif ! echo $2 | grep -q [1-9]
  then
    echo
    echo -e "${LTRED}ERROR: The node number must be a number between 1 and 9.${NC}"
    echo
    return 1
  elif [ -z $3 ]
  then
    echo
    echo -e "${LTRED}ERROR: The Bridge network must be the network ID of the bridge with CIDR mask.${NC}"
    echo -e "${GRAY}       Example: 192.168.124.0/24${NC}"
    echo
    echo -e "${GRAY}USAGE: $0 <bridge_name> <node_number> <bridge_network> <ethernet_device>${NC}"
    echo
    return 1
  else
    local BRIDGE_NAME=$1
    local NODE_NUM=$2
    local BRIDGE_NETWORK=$3
    local BRIDGE_ETHERDEV=$4
  fi

  #-----------------------------------------------------------------------------

  local TMP_FILE="/tmp/ifcfg-${BRIDGE_NAME}"
  local IFCFG_FILE="/etc/sysconfig/network/ifcfg-${BRIDGE_NAME}"
  local IP_NETWORK="$(echo ${BRIDGE_NETWORK} | cut -d / -f 1 | cut -d . -f 1,2,3)"
  if ! [ -z ${IP_NETWORK} ]
  then
    local IP_ADDR="${IP_NETWORK}.${NODE_NUM}"
    local CIDRMASK="/$(echo ${BRIDGE_NETWORK} | cut -d / -f 2)"
    local CIDR_IP_ADDR="${IP_ADDR}${CIDRMASK}"
  else
    local CIDR_IP_ADDR=""
  fi
  if [ -z ${BRIDGE_ETHERDEV} ]
  then
    local BRIDGE_ETHERDEV=$(sudo yast lan show id=$(sudo yast lan list 2>&1 > /dev/null | grep "^[0-9]" | grep -i "not configured" | grep -i ethernet | awk '{ print $1 }' | head -n 1 ) 2>&1 > /dev/null | grep "Device Name" | awk '{ print $3 }')
    #local BRIDGE_ETHERDEV=$(sudo yast lan show id=$(sudo yast lan list 2>&1 > /dev/null | grep "^[0-9]" | grep -i ethernet | awk '{ print $1 }' | head -n 2 | tail -n 1) 2>&1 > /dev/null | grep "Device Name" | awk '{ print $3 }')
  fi
  local BOOTPROTO="static"

  #-----------------------------------------------------------------------------

  if [ -e ${IFCFG_FILE} ]
  then
    echo
    echo -e "${LTRED}ERROR: An ifcfg- file with that name already exists:${GRAY} $(basename ${IFCFG_FILE})${NC}"
    echo
    return 1
  elif [ -z ${BRIDGE_ETHERDEV} ]
  then
    echo
    echo -e "${LTRED}ERROR: Supplied or unconfigured ethernet device not available.${NC}"
    echo
    return 1
  else
    echo
    echo -e "${LTPURPLE}Bridge name:${GRAY}  ${BRIDGE_NAME}${NC}"
    echo -e "${LTPURPLE}Using device:${GRAY} ${BRIDGE_ETHERDEV}${NC}"
    echo -e "${LTPURPLE}IP address:${GRAY}   ${CIDR_IP_ADDR}${NC}"
    echo -e "${LTPURPLE}Writing out:${GRAY}  ${IFCFG_FILE}${NC}"
    echo

    echo "#created by install_lab_env" >> ${TMP_FILE}
    echo "BOOTPROTO='${BOOTPROTO}'" >> ${TMP_FILE}
    echo "BRIDGE='yes'" >> ${TMP_FILE}
    echo "BRIDGE_FORWARDDELAY='0'" >> ${TMP_FILE}
    echo "BRIDGE_PORTS='${BRIDGE_ETHERDEV}'" >> ${TMP_FILE}
    echo "BRIDGE_STP='off'" >> ${TMP_FILE}
    echo "BROADCAST=''" >> ${TMP_FILE}
    echo "ETHTOOL_OPTIONS=''" >> ${TMP_FILE}
    echo "IPADDR='${CIDR_IP_ADDR}'" >> ${TMP_FILE}
    echo "MTU=''" >> ${TMP_FILE}
    echo "REMOTE_IPADDR=''" >> ${TMP_FILE}
    echo "STARTMODE='auto'" >> ${TMP_FILE}

    sudo mv ${TMP_FILE} ${IFCFG_FILE}
  fi

  echo -e "${LTBLUE}Starting:${LTGRAY} ${BRIDGE_NAME}${NC}"
  sudo /sbin/ifup ${BRIDGE_NAME}
}

convert_eth_to_br() {
  if ! [ -z $1 ]
  then
    local DEV_NAME=$1
  else
    local DEV_NAME=$(sudo yast lan show id=$(sudo yast lan list 2>&1 > /dev/null | grep "^[0-9]" | grep -iv "not configured" | grep -i ethernet | awk '{ print $1 }' | head -n 1) 2>&1 > /dev/null | grep "Device Name" | awk '{ print $3 }')
  fi

  if ! [ -z $2 ]
  then
    local BRIDGE_NAME=$2
  else
    local BRIDGE_NAME="br0"
  fi
  #-----------------------------------------------------------------------------

  local TMP_FILE="/tmp/ifcfg-${BRIDGE_NAME}"
  local IFCFG_FILE="/etc/sysconfig/network/ifcfg-${BRIDGE_NAME}"

  local BOOTPROTO=$(grep BOOTPROTO /etc/sysconfig/network/ifcfg-${DEV_NAME} | cut -d = -f 2 | sed "s/'//g")
  local IP_ADDR=$(grep IPADDR /etc/sysconfig/network/ifcfg-${DEV_NAME} | cut -d = -f 2 | sed "s/'//g")
  local NET_MASK=$(grep NETMASK /etc/sysconfig/network/ifcfg-${DEV_NAME} | cut -d = -f 2 | sed "s/'//g")

  #-----------------------------------------------------------------------------

  if [ -e ${IFCFG_FILE} ]
  then
    echo -e "${LTRED}ERROR: An ifcfg- file with that name already exists:${GRAY} $(basename ${IFCFG_FILE})${NC}"
    return 1
  else
    echo -e "${LTBLUE}Converting:${LTGRAY} ${DEV_NAME} -> ${BRIDGE_NAME}${NC}"
    cd /etc/sysconfig/network
    cp ifcfg-${DEV_NAME} ${TMP_FILE}
    echo "BRIDGE='yes'" >> ${TMP_FILE}
    echo "BRIDGE_FORWARDDELAY='0'" >> ${TMP_FILE}
    echo "BRIDGE_PORTS='${DEV_NAME}'" >> ${TMP_FILE}
    echo "BRIDGE_STP='off'" >> ${TMP_FILE}
    sed -i '/^NAME.*/d' ${TMP_FILE}
    sudo cp ${TMP_FILE} ${IFCFG_FILE}

    echo -e "${LTBLUE}Stopping:${LTGRAY} ${DEV_NAME}${NC}"
    sudo /sbin/ifdown ${DEV_NAME}

    sudo mv ifcfg-${DEV_NAME} orig.ifcfg-${DEV_NAME}
 
    echo -e "${LTBLUE}Starting:${LTGRAY} ${BRIDGE_NAME}${NC}"
    sudo /sbin/ifup ${BRIDGE_NAME}
  fi
}

convert_br_to_eth() {
  #-----------------------------------------------------------------------------
  if ! [ -z $1 ]
  then
    BRIDGE_NAME=$1
  else
    local BRIDGE_NAME=$(sudo yast lan show id=$(sudo yast lan list 2>&1 > /dev/null | grep "^[0-9]" | grep -iv "not configured" | grep -i "network bridge" | awk '{ print $1 }' | head -n 1) 2>&1 > /dev/null | grep -i "network bridgedevice name" | awk '{ print $4 }')
  fi

  if ! [ -z $2 ]
  then
    DEV_NAME=$2
  else
    local DEV_NAME=$(grep BRIDGE_PORTS /etc/sysconfig/network/ifcfg-${BRIDGE_NAME} | cut -d = -f 2 | sed "s/'//g")
  fi

  local BOOTPROTO=$(grep BOOTPROTO /etc/sysconfig/network/ifcfg-${BRIDGE_NAME} | cut -d = -f 2 | sed "s/'//g")
  local IP_ADDR=$(grep IPADDR /etc/sysconfig/network/ifcfg-${BRIDGE_NAME} | cut -d = -f 2 | sed "s/'//g")
  local NET_MASK=$(grep NETMASK /etc/sysconfig/network/ifcfg-${BRIDGE_NAME} | cut -d = -f 2 | sed "s/'//g")
  local TMP_FILE="/tmp/ifcfg-${DEV_NAME}"
  local IFCFG_FILE="/etc/sysconfig/network/ifcfg-${DEV_NAME}"

  #-----------------------------------------------------------------------------

  if [ -e ${IFCFG_FILE} ]
  then
    echo -e "${LTRED}WARNING: An ifcfg- file with that name already exists: $(basename ${IFCFG_FILE})${NC}"
    echo -e "${LTRED}         It will be overwritten.${NC}"
  fi

  echo -e "${LTBLUE}Converting:${LTGRAY} ${BRIDGE_NAME} -> ${DEV_NAME}${NC}"
  cd /etc/sysconfig/network
  cp ifcfg-${BRIDGE_NAME} ${TMP_FILE}
  sed -i "s/^BRIDGE.*//g" ${TMP_FILE}
  sudo mv ${TMP_FILE} ${IFCFG_FILE}

  echo -e "${LTBLUE}Stopping:${LTGRAY} ${BRIDGE_NAME}${NC}"
  sudo /sbin/ifdown ${BRIDGE_NAME}

  sudo mv ifcfg-${BRIDGE_NAME} orig.ifcfg-${BRIDGE_NAME}
 
  echo -e "${LTBLUE}Starting:${LTGRAY} ${DEV_NAME}${NC}"
  sudo /sbin/ifup ${DEV_NAME}
}

install_rpms() {
  if [ -e ${RPM_DIR}/*.rpm ]
  then
    echo -e "${LTBLUE}Installing RPMs ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    run cd ${RPM_DIR}
    echo

    run sudo zypper -n --no-gpg-checks install *.rpm
    echo

    run cd -
    echo
  fi
}

install_vmware() {
  if [ -e /usr/bin/vmware ]
  then
    return
  fi

  if [ -e ${VMWARE_INSTALLER_DIR}/VMware-*.bundle ]
  then
    echo -e "${LTBLUE}Installing VMware ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    if [ -e ${VMWARE_INSTALLER_DIR}/license-ws-* ]
    then
      run TERM=dumb sudo sh ${VMWARE_INSTALLER_DIR}/VMware-*.x86_64.bundle --ignore-errors --eulas-agreed --console --required 
      echo
      
      run sudo mkdir -p /etc/vmware
      echo

      run sudo cp ${VMWARE_INSTALLER_DIR}/license-ws-* /etc/vmware
      echo

      run sudo chmod 644 /etc/vmware/license-ws-*
    elif [ -e ${VMWARE_INSTALLER_DIR}/vmware-license-key ]
    then
      echo
      run TERM=dumb sudo sh ${VMWARE_INSTALLER_DIR}/VMware-*.x86_64.bundle --ignore-errors --eulas-agreed --console --required --set-setting=vmware-workstation serialNumber $(cat ${VMWARE_INSTALLER_DIR}/vmware-license-key)
      echo
    else
      run TERM=dumb sudo sh ${VMWARE_INSTALLER_DIR}/VMware-*.x86_64.bundle --ignore-errors --eulas-agreed --console --required 
      echo
    fi
  fi
}

get_libvirt_capabilities() {
  AVAILABLE_440FX_VERS=$(virsh capabilities | grep -Eo "pc-i440fx-[0-9]+\.[0-9]+" | cut -d - -f 3 | sort | uniq)
  HIGHEST_440FX_VER=$(echo ${AVAILABLE_440FX_VERS} | cut -d " " -f $(echo ${AVAILABLE_440FX_VERS} | wc -w))
  AVAILABLE_Q35_VERS=$(virsh capabilities | grep -Eo "pc-q35-[0-9]+\.[0-9]+" | cut -d - -f 3 | sort | uniq)
  HIGHEST_Q35_VER=$(echo ${AVAILABLE_Q35_VERS} | cut -d " " -f $(echo ${AVAILABLE_Q35_VERS} | wc -w))
  AVAILABLE_PC_VERS=$(virsh capabilities | grep -Eo "pc-[0-9]+\.[0-9]+" | cut -d - -f 2 | sort | uniq)
  HIGHEST_PC_VER=$(echo ${AVAILABLE_PC_VERS} | cut -d " " -f $(echo ${AVAILABLE_PC_VERS} | wc -w))
  ##echo "AVAILABLE_440FX_VERS=${AVAILABLE_440FX_VERS}"
  #echo "HIGHEST_440FX_VER=${HIGHEST_440FX_VER}"
  ##echo "AVAILABLE_Q35_VERS=${AVAILABLE_Q35_VERS}"
  #echo "HIGHEST_Q35_VER=${HIGHEST_Q35_VER}"
  ##echo "AVAILABLE_PC_VERS=${AVAILABLE_PC_VERS}"
  #echo "HIGHEST_PC_VER=${HIGHEST_PC_VER}"
  #read
}

edit_libvirt_domxml() {
    get_libvirt_capabilities

    case ${MULTI_LAB_MACHINE}
    in
      y|Y|yes|Yes|YES|t|T|true|True|TRUE)
        local VM_CONFIG="${VM}-${MULTI_LM_EXT}.xml"
      ;;
      *)
        local VM_CONFIG="${VM}.xml"
      ;;
    esac

    if [ -e ${VM_DEST_DIR}/"${VM}"/"${VM_CONFIG}" ]
    then
      echo -e "${LTBLUE}Updating VM configuration file ...${NC}"

      #--- cpu ---
      case ${LIBVIRT_SET_CPU_TO_HYPERVISOR_DEFUALT} in
        y|Y|yes|Yes)
          echo -e "  ${LTCYAN}Changing CPU to Hypervisor Default ...${NC}"
          run sed -i -e '/<cpu/,/cpu>/ d' ${VM_DEST_DIR}/"${VM}"/"${VM_CONFIG}"
          echo
        ;;
        *)
          echo -e "  ${LTCYAN}Keeping existing CPU type.${NC}"
          echo
        ;;
      esac
 
      #--- features ---
      QEMUKVM_VER=$(qemu-kvm -version | cut -d ' ' -f 4 | sed 's/,//g')
      QEMUKVM_VER_MAJ=$(echo ${QEMUKVM_VER} | cut -d . -f 1)
      QEMUKVM_VER_MIN=$(echo ${QEMUKVM_VER} | cut -d . -f 2)
      QEMUKVM_VER_REL=$(echo ${QEMUKVM_VER} | cut -d . -f 3)

      # check for vmport support
      if [ "${QEMUKVM_VER_MAJ}" -gt 2 ]
      then
        local VMPORT=Y
      elif [ "${QEMUKVM_VER_MAJ}" -eq 2 ]
      then
        if [ "${QEMUKVM_VER_MIN}" -gt 3 ]
        then
          local VMPORT=Y
        elif [ "${QEMUKVM_VER_MIN}" -eq 3 ]
        then
          if [ "${QEMUKVM_VER_REL}" -ge 0 ]
          then
            local VMPORT=Y
          else
            local VMPORT=N
          fi
        else
          local VMPORT=N
        fi
      else
        local VMPORT=N
      fi
 
      case ${VMPORT} in
        Y)
          echo -e "  ${LTCYAN}QEMU version ${GRAY}${QEMUKVM_VER}${LTCYAN} supports vmport parameter, not removing it.${NC}"
          echo
        ;;
        N)
          echo -e "  ${LTCYAN}Removing vmport parameter ...${NC}"
          run sed -i "/vmport/d"  ${VM_DEST_DIR}/"${VM}"/"${VM_CONFIG}"
          echo
        ;;
      esac
 
      #--- machine type ---
      local MACHINE_TYPE_STRING=$(grep "machine=" ${VM_DEST_DIR}/"${VM}"/"${VM_CONFIG}" | awk '{ print $3 }' | cut -d \> -f 1 | cut -d \' -f 2)
      local MACHINE_TYPE=$(echo ${MACHINE_TYPE_STRING} | cut -d \- -f 2)
      local MACHINE_TYPE_VER=$(echo ${MACHINE_TYPE_STRING} | cut -d \- -f 3)
      
      #echo "KVM_SET_MACHINE_TYPE_TO_HIGHEST_SUPPORTED=${KVM_SET_MACHINE_TYPE_TO_HIGHEST_SUPPORTED}"
      #echo "MACHINE_TYPE_STRING=${MACHINE_TYPE_STRING}"
      #echo "MACHINE_TYPE=${MACHINE_TYPE}"
      #echo "MACHINE_TYPE_VER=${MACHINE_TYPE_VER}"
      #read;

      case ${KVM_SET_MACHINE_TYPE_TO_HIGHEST_SUPPORTED} in
        Y|y)
          case ${MACHINE_TYPE} in
            i440fx)
              echo -e "  ${LTCYAN}Changing machine type to highest supported version ...${NC}"
              run sed -i "s/pc-i440fx-.../pc-i440fx-${HIGHEST_440FX_VER}/"  ${VM_DEST_DIR}/"${VM}"/"${VM_CONFIG}"
            ;;
            q35)
              echo -e "  ${LTCYAN}Changing machine type to highest supported version ...${NC}"
              run sed -i "s/pc-q35-.../pc-q35-${HIGHEST_Q35_VER}/"  ${VM_DEST_DIR}/"${VM}"/"${VM_CONFIG}"
            ;;
          esac
        ;;
        *) 
          case ${MACHINE_TYPE} in
            i440fx)
              if ! echo ${AVAILABLE_440FX_VERS} | grep -q ${MACHINE_TYPE_VER}
              then
                echo -e "  ${LTCYAN}Changing machine type to highest supported version ...${NC}"
                run sed -i "s/pc-i440fx-.../pc-i440fx-${HIGHEST_440FX_VER}/"  ${VM_DEST_DIR}/"${VM}"/"${VM_CONFIG}"
                echo
              else
                echo -e "  ${LTCYAN}Machine type is a supported version: ${GRAY}${MACHINE_TYPE_VER} ${NC}"
                echo
              fi
            ;;
            q35)
              if ! echo ${AVAILABLE_Q35_VERS} | grep -q ${MACHINE_TYPE_VER}
              then
                echo -e "  ${LTCYAN}Changing machine type to highest supported version ...${NC}"
                run sed -i "s/pc-q35-.../pc-q35-${HIGHEST_Q35_VER}/"  ${VM_DEST_DIR}/"${VM}"/"${VM_CONFIG}"
                echo
              else
                echo -e "  ${LTCYAN}Machine type is a supported version: ${GRAY}${MACHINE_TYPE_VER} ${NC}"
                echo
              fi
            ;;
          esac
        ;;
      esac
 
      #--- network to bridge ---
      for BRIDGE in ${BRIDGE_LIST}
      do
        local BRIDGE_NAME="$(echo ${BRIDGE} | cut -d , -f 1)"
        if grep -q "network=${BRIDGE_NAME}" ${VM_DEST_DIR}/"${VM}"/"${VM_CONFIG}"
        then
          echo -e "  ${LTCYAN}Changing network= to bridge= ...${NC}"
          run sed -i "s/network=${BRIDGE_NAME}/bridge=${BRIDGE_NAME}/g" ${VM_DEST_DIR}/"${VM}"/"${VM_CONFIG}"
          echo
        fi
      done
 
      echo
    fi
}

create_vm_snapshot() {
  if [ -z ${1} ]
  then
    echo -e "${RED}ERROR: You must supply a VM name.${NC}"
    echo 
    echo "  USAGE: create_vm_snapshot <vm_name> [<snapshot_name>]"
  else
    local VM_NAME=${1}
  fi

  if [ -z ${2} ]
  then
    local SNAP_NAME=$(date --iso8601=seconds)
  else
    local SNAP_NAME=${2}
  fi

  local SNAP_DESC="${SNAP_NAME} snapshot"

  local DISK_LIST="$(virsh dumpxml ${VM_NAME} | sed -n -e '/<disk type.*device=.disk/,/<\/disk>/ p' | grep "target dev" | cut -d \' -f 2)"

  for DISK in ${DISK_LIST}
  do
    local DISK_SPEC_LIST="${DISK_SPEC_LIST} --diskspec ${DISK},snapshot=internal"
  done

  echo
  echo -e "${LTCYAN}Creating snapshot of VM: ${GRAY}$VM_NAME${NC}"
  echo
  echo -n "  ";run virsh snapshot-create-as ${VM_NAME} ${SNAP_NAME} "${SNAP_DESC}" ${DISK_SPEC_LIST}
  #virsh snapshot-create-as ${VM_NAME} ${SNAP_NAME} "${SNAP_DESC}" --diskspec vda,snapshot=internal
  #echo
  #virsh snapshot-list ${VM_NAME}
  echo
}

get_archive_type() {
# Pass in:
#  - an archive file with or without file extenstion
# and 
#  - the type of archive will be determined by either extension or use of the command: file
#  - the type of archive will be returned via echo

  local ARCHIVE_FILE=${1}

  if ls ${ARCHIVE_FILE}.tgz > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=tgz
  elif ls ${ARCHIVE_FILE}.tar.gz > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=targz
  elif ls ${ARCHIVE_FILE}.tar.bz2 > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=tarbz2
  elif ls ${ARCHIVE_FILE}.tbz > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=tbz
  elif ls ${ARCHIVE_FILE}.tar.xz > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=tarxz
  elif ls ${ARCHIVE_FILE}.txz > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=txz
  elif ls ${ARCHIVE_FILE}.7z* > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=7z
  elif ls ${ARCHIVE_FILE}.tar.7z* > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=tar7z
  elif ls ${ARCHIVE_FILE}.zip > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=zip
  else
    case $(file -b ${ARCHIVE_FILE} | cut -d \  -f 1) in
      gzip)
        local ARCHIVE_TYPE=GZIP
      ;;
      bzip2)
        local ARCHIVE_TYPE=BZIP2
      ;;
      7-zip)
        local ARCHIVE_TYPE=7ZIP
      ;;
      Zip)
        local ARCHIVE_TYPE=ZIP
      ;;
    esac
  fi
  
  echo ${ARCHIVE_TYPE}
}

extract_archive() {
# Pass in:
#  - an archive file with or without file extenstion
#  - the directory to extract it into
#  - [optionally] the archive type (as determinted by the function: get_archive_type)
# and the archive will be extracted into the directory

  local ARCHIVE_FILE=$1
  local ARCHIVE_DEST_DIR=$2
  local ARCHIVE_TYPE=$3

  case ${ARCHIVE_TYPE} in
    tgz)
      run tar xzvf ${ARCHIVE_FILE}.tgz -C ${ARCHIVE_DEST_DIR}
    ;;
    targz)
      run tar xzvf ${ARCHIVE_FILE}.tar.gz -C ${ARCHIVE_DEST_DIR}
    ;;
    tbz)
      run tar xjvf ${ARCHIVE_FILE}.tbz -C ${ARCHIVE_DEST_DIR}
    ;;
    tarbz2)
      run tar xjvf ${ARCHIVE_FILE}.tar.bz2 -C ${ARCHIVE_DEST_DIR}
    ;;
    txz)
      run tar xJvf ${ARCHIVE_FILE}.txz -C ${ARCHIVE_DEST_DIR}
    ;;
    tarxz)
      run tar xJvf ${ARCHIVE_FILE}.tar.xz -C ${ARCHIVE_DEST_DIR}
    ;;
    7z)
      if [ -e ${ARCHIVE_FILE}.7z ]
      then
        local OLD_PWD=${PWD}
        run cd ${ARCHIVE_DEST_DIR}

        run 7z x -mmt=on ${OLD_PWD}/${ARCHIVE_FILE}.7z

        run cd -
      elif [ -e ${ARCHIVE_FILE}.7z.001 ]
      then
        local OLD_PWD=${PWD}
        run cd ${ARCHIVE_DEST_DIR}

        run 7z x -mmt=on ${OLD_PWD}/${ARCHIVE_FILE}.7z.001

        run cd -
      fi
    ;;
    tar7z)
      if [ -e ${ARCHIVE_FILE}.tar.7z ]
      then
        local OLD_PWD=${PWD}
        run cd ${ARCHIVE_DEST_DIR}

        run 7z x -mmt=on -so ${OLD_PWD}/${ARCHIVE_FILE}.tar.7z | tar xf -

        run cd -
      elif [ -e ${ARCHIVE_FILE}.tar.7z.001 ]
      then
        local OLD_PWD=${PWD}
        run cd ${ARCHIVE_DEST_DIR}

        run 7z x -mmt=on -so ${OLD_PWD}/${ARCHIVE_FILE}.tar.7z.001 | tar xf -

        run cd -
      fi
    ;;
    zip)
      local OLD_PWD=${PWD}
      run cd ${ARCHIVE_DEST_DIR}

      run unzip ${OLD_PWD}/${ARCHIVE_FILE}.zip

      run cd -
    ;;
    GZIP)
      if echo ${ARCHIVE_FILE} | grep -q ".tar.gz$" || echo ${ARCHIVE_FILE} | grep -q ".tgz$"
      then
        run tar xzvf ${ARCHIVE_FILE} -C ${ARCHIVE_DEST_DIR}
      fi
    ;;
    BZIP2)
      if echo ${ARCHIVE_FILE} | grep -q ".tar.bz2$" || echo ${ARCHIVE_FILE} | grep -q ".tbz$"
      then
        run tar xjvf ${ARCHIVE_FILE} -C ${ARCHIVE_DEST_DIR}
      fi
    ;;
    7ZIP)
      if echo ${ARCHIVE_FILE} | grep -q ".tar.7z.001$" || echo ${ARCHIVE_FILE} | grep -q ".tar.7z$"
      then
        local OLD_PWD=${PWD}
        run cd ${ARCHIVE_DEST_DIR}

        run 7z x -mmt=on -so ${OLD_PWD}/${ARCHIVE_FILE} | tar xf -

        run cd -
      elif  echo ${ARCHIVE_FILE} | grep -q ".7z.001$" || echo ${ARCHIVE_FILE} | grep -q ".7z?"
      then
        local OLD_PWD=${PWD}
        run cd ${ARCHIVE_DEST_DIR}

        run 7z x -mmt=on ${OLD_PWD}/${ARCHIVE_FILE}

        run cd -
      fi
    ;;
    ZIP)
      local OLD_PWD=${PWD}
      run cd ${ARCHIVE_DEST_DIR}

      run unzip ${OLD_PWD}/${ARCHIVE_FILE}

      run cd -
    ;;
  esac
}

extract_archive_sudo() {
# Pass in:
#  - an archive file with or without file extenstion
#  - the directory to extract it into
#  - [optionally] the archive type (as determinted by the function: get_archive_type)
# and the archive will be extracted into the directory using the command: sudo

  local ARCHIVE_FILE=$1
  local ARCHIVE_DEST_DIR=$2
  local ARCHIVE_TYPE=$3

  case ${ARCHIVE_TYPE} in
    tgz)
      run sudo tar xzvf ${ARCHIVE_FILE} -C ${ARCHIVE_DEST_DIR}
    ;;
    targz)
      run sudo tar xzvf ${ARCHIVE_FILE}.tar.gz -C ${ARCHIVE_DEST_DIR}
    ;;
    tbz)
      run sudo tar xjvf ${ARCHIVE_FILE} -C ${ARCHIVE_DEST_DIR}
    ;;
    tarbz2)
      run sudo tar xjvf ${ARCHIVE_FILE}.tar.bz2 -C ${ARCHIVE_DEST_DIR}
    ;;
    7z)
      if [ -e ${ARCHIVE_FILE}.7z ]
      then
        local OLD_PWD=${PWD}
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x ${OLD_PWD}/${ARCHIVE_FILE}.7z

        run sudo cd -
      elif [ -e ${ARCHIVE_FILE}.7z.001 ]
      then
        local OLD_PWD=${PWD}
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x ${OLD_PWD}/${ARCHIVE_FILE}.7z.001

        run sudo cd -
      fi
    ;;
    tar7z)
      if [ -e ${ARCHIVE_FILE}.tar.7z ]
      then
        local OLD_PWD=${PWD}
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x -so ${OLD_PWD}/${ARCHIVE_FILE}.tar.7z | tar xf -

        run sudo cd -
      elif [ -e ${ARCHIVE_FILE}.tar.7z.001 ]
      then
        local OLD_PWD=${PWD}
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x -so ${OLD_PWD}/${ARCHIVE_FILE}.tar.7z.001 | tar xf -

        run sudo cd -
      fi
    ;;
    zip)
      local OLD_PWD=${PWD}
      run sudo cd ${ARCHIVE_DEST_DIR}

      run sudo unzip ${OLD_PWD}/${ARCHIVE_FILE}.zip

      run sudo cd -
    ;;
    GZIP)
      if echo ${ARCHIVE_FILE} | grep -q ".tar.gz$" || echo ${ARCHIVE_FILE} | grep -q ".tgz$"
      then
        run sudo tar xzvf ${ARCHIVE_FILE} -C ${ARCHIVE_DEST_DIR}
      fi
    ;;
    BZIP2)
      if echo ${ARCHIVE_FILE} | grep -q ".tar.bz2$" || echo ${ARCHIVE_FILE} | grep -q ".tbz$"
      then
        run sudo tar xjvf ${ARCHIVE_FILE} -C ${ARCHIVE_DEST_DIR}
      fi
    ;;
    7ZIP)
      if echo ${ARCHIVE_FILE} | grep -q ".tar.7z.001$" || echo ${ARCHIVE_FILE} | grep -q ".tar.7z$"
      then
        local OLD_PWD=${PWD}
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x -so ${OLD_PWD}/${ARCHIVE_FILE} | tar xf -

        run sudo cd -
      elif  echo ${ARCHIVE_FILE} | grep -q ".7z.001$" || echo ${ARCHIVE_FILE} | grep -q ".7z?"
      then
        local OLD_PWD=${PWD}
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x ${OLD_PWD}/${ARCHIVE_FILE}

        run sudo cd -
      fi
    ;;
    ZIP)
      local OLD_PWD=${PWD}
      run sudo cd ${ARCHIVE_DEST_DIR}

      run sudo unzip ${OLD_PWD}/${ARCHIVE_FILE}

      run sudo cd -
    ;;
  esac
}
