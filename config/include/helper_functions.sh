##############  Helper Functions #############################################
# version: 3.11.2
# date: 2021-11-11
#

configure_nic() {
  if [ -z "$1" ]
  then
    echo
    echo -e "${LTRED}ERROR: Missing NIC name.${NC}"
    echo
    echo -e "${NC}USAGE: $0 <nic_name> <node_number> <nic_network> <boot_protocol> <start_mode>${NC}"
    echo
    return 1
  elif [ -z "$2" ]
  then
    echo
    echo -e "${LTRED}ERROR: Missing node number.${NC}"
    echo -e "${LTRED}       The node number must be a number between 1 and 9.${NC}"
    echo
    echo -e "${NC}USAGE: $0 <nic_name> <node_number> <nic_network> <boot_protocol> <start_mode>${NC}"
    echo
    return 1
  elif ! echo $2 | grep -q [1-9]
  then
    echo
    echo -e "${LTRED}ERROR: The node number must be a number between 1 and 9.${NC}"
    echo
    return 1
  elif [ -z "$3" ]
  then
    echo
    echo -e "${LTRED}ERROR: The NIC network must be the network ID of the bridge with CIDR mask.${NC}"
    echo -e "${NC}       Example: 192.168.124.0/24${NC}"
    echo
    echo -e "${NC}USAGE: $0 <nic_name> <node_number> <nic_network> <boot_protocol> <start_mode>${NC}"
    echo
    return 1
  elif [ -z "$4" ]
  then
    echo
    echo -e "${LTRED}ERROR: The boot protocol must be one of the following:${NC}"
    echo -e "${NC}         static${NC}"
    echo -e "${NC}         dhcp${NC}"
    echo -e "${NC}         none${NC}"
    echo
    echo -e "${NC}USAGE: $0 <nic_name> <node_number> <nic_network> <boot_protocol> <start_mode>${NC}"
    echo
    return 1
  elif [ -z "$5" ]
  then
    echo
    echo -e "${LTRED}ERROR: The start mode must be one of the following:${NC}"
    echo -e "${NC}         auto${NC}"
    echo -e "${NC}         hotplug${NC}"
    echo -e "${NC}         off${NC}"
    echo
    echo -e "${NC}USAGE: $0 <nic_name> <node_number> <nic_network> <boot_protocol> <start_mode>${NC}"
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
  if ! [ -z "${IP_NETWORK}" ]
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
    echo -e "${LTRED}ERROR: An ifcfg- file with that name already exists:${NC} $(basename ${IFCFG_FILE})${NC}"
    echo
    return 1
  else
    echo
    echo -e "${LTPURPLE}NIC name:${NC}        ${NIC_NAME}${NC}"
    echo -e "${LTPURPLE}IP address:${NC}      ${CIDR_IP_ADDR}${NC}"
    echo -e "${LTPURPLE}Writing out:${NC}     ${IFCFG_FILE}${NC}"
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

configure_new_veth_interfaces() {
  if [ -z "$1" ]
  then
    echo
    echo -e "${LTRED}ERROR: Missing virtual ethernet interface name.${NC}"
    echo
    echo -e "${NC}USAGE: $0 <veth_name> <node_number> <veth_network>${NC}"
    echo
    return 1
  elif [ -z "$2" ]
  then
    echo
    echo -e "${LTRED}ERROR: Missing node number.${NC}"
    echo -e "${LTRED}       The node number must be a number between 1 and 9.${NC}"
    echo
    echo -e "${NC}USAGE: $0 <veth_name> <node_number> <veth_network>${NC}"
    echo
    return 1
  elif ! echo $2 | grep -q [1-9]
  then
    echo
    echo -e "${LTRED}ERROR: The node number must be a number between 1 and 9.${NC}"
    echo
    return 1
  elif [ -z "$3" ]
  then
    echo
    echo -e "${LTRED}ERROR: The veth network must be the network ID of the virtusl ethernet device with CIDR mask.${NC}"
    echo -e "${LTRED}       If not used then use - rather than leaving it empty.${NC}"
    echo -e "${NC}       Example: 192.168.124.0/24${NC}"
    echo -e "${NC}       Example: -${NC}"
    echo
    echo -e "${NC}USAGE: $0 <veth_name> <node_number> <veth_network>${NC}"
    echo
    return 1
  else
    local VETH_NAME_A=$1-nic
    local VETH_NAME_B=$1
    local NODE_NUM=$2
    local VETH_IP=$3
  fi

  #-----------------------------------------------------------------------------

  case ${VETH_IP}
  in
    -)
      VETH_NETWORK=""
    ;;
    *)
      local IP_NETWORK="$(echo ${VETH_NETWORK} | cut -d / -f 1 | cut -d . -f 1,2,3)"
      if ! [ -z "${IP_NETWORK}" ]
      then
        local IP_ADDR="${IP_NETWORK}.${NODE_NUM}"
        local CIDRMASK="/$(echo ${VETH_NETWORK} | cut -d / -f 2)"
        local CIDR_IP_ADDR="${IP_ADDR}${CIDRMASK}"
      else
        local CIDR_IP_ADDR=""
      fi
    ;;
  esac

  #-----------------------------------------------------------------------------

  if ! [ -z ${VETH_NAME_A} ]
  then
    if ! ip addr show | grep -q ${VETH_NAME_B}
    then
      echo -e "${LTBLUE}Creating veth pair:${LTGRAY} ${VETH_NAME_A}->${VETH_NAME_B}${NC}"
      # Create the veth pair
      #echo sudo ip link add dev ${VETH_NAME_A} type veth peer name ${VETH_NAME_B}
      run sudo ip link add dev ${VETH_NAME_A} type veth peer name ${VETH_NAME_B}
  
      #echo sudo ip link set dev ${VETH_NAME_A} up
      run sudo ip link set dev ${VETH_NAME_A} up
    fi
  fi

  if ! [ -z ${VETH_NETWORK} ]
  then
    #echo sudo ip addr add ${CIDR_IP_ADDR} dev ${VETH_NAME_B}
    run sudo ip addr add ${CIDR_IP_ADDR} dev ${VETH_NAME_B}
 
    #echo sudo ip link set ${VETH_NAME_B} up
    run sudo ip link set ${VETH_NAME_B} up
  fi
}

configure_new_ovs_bridge() {
  if [ -z $1 ]
  then
    echo
    echo -e "${LTRED}ERROR: Missing bridge name.${NC}"
    echo
    echo -e "${NC}USAGE: $0 <bridge_name> <node_number> <bridge_network> <physical_device> <parent_bridge> <vlan_tag>${NC}"
    echo
    return 1
  elif [ -z $2 ]
  then
    echo
    echo -e "${LTRED}ERROR: Missing node number.${NC}"
    echo -e "${LTRED}       The node number must be a number between 1 and 9.${NC}"
    echo
    echo -e "${NC}USAGE: $0 <bridge_name> <node_number> <bridge_network> <physical_device> <parent_bridge> <vlan_tag>${NC}"
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
    echo -e "${LTRED}       If not used then use - rather than leaving it empty.${NC}"
    echo -e "${NC}       Example 1: 192.168.124.0/24${NC}"
    echo -e "${NC}       Example 2: -${NC}"
    echo
    echo -e "${NC}USAGE: $0 <bridge_name> <node_number> <bridge_network> <physical_device> <parent_bridge> <vlan_tag>${NC}"
    echo
    return 1
  elif [ -z $4 ]
  then
    echo
    echo -e "${LTRED}ERROR: The Physical Device is the physical network device to attach to the bridge.${NC}"
    echo -e "${LTRED}       If not used then use - rather than leaving it empty.${NC}"
    echo -e "${NC}       Example 1: eth1${NC}"
    echo -e "${NC}       Example 2: -${NC}"
    echo
    echo -e "${NC}USAGE: $0 <bridge_name> <node_number> <bridge_network> <physical_device> <parent_bridge> <vlan_tag>${NC}"
    echo
    return 1
  elif [ -z $5 ]
  then
    echo
    echo -e "${LTRED}ERROR: The Parent Bridge is the bridge to create the VLAN port/bridge on.${NC}"
    echo -e "${LTRED}       If not used then use - rather than leaving it empty.${NC}"
    echo -e "${NC}       Example 1: eth1${NC}"
    echo -e "${NC}       Example 2: -${NC}"
    echo
    echo -e "${NC}USAGE: $0 <bridge_name> <node_number> <bridge_network> <physical_device> <parent_bridge> <vlan_tag>${NC}"
    echo
    return 1
  elif [ -z $6 ]
  then
    echo
    echo -e "${LTRED}ERROR: The VLAN Tag is the VLAN tag number to use for the VLAN.${NC}"
    echo -e "${LTRED}       If not used then use - rather than leaving it empty.${NC}"
    echo -e "${NC}       Example 1: eth1${NC}"
    echo -e "${NC}       Example 2: -${NC}"
    echo
    echo -e "${NC}USAGE: $0 <bridge_name> <node_number> <bridge_network> <physical_device> <parent_bridge> <vlan_tag>${NC}"
    echo
    return 1
  else
    local OVS_BRIDGE_NAME=$1
    local NODE_NUM=$2
    local OVS_BRIDGE_NETWORK=$3
    local OVS_BRIDGE_PHYSDEV=$4
    local OVS_BRIDGE_PARENT_BRIDGE=$5
    local OVS_BRIDGE_VLAN_TAG=$6
  fi

  #-----------------------------------------------------------------------------

  case ${OVS_BRIDGE_NETWORK}
  in
    -)
      OVS_BRIDGE_NETWORK=""
    ;;
    *)
      local IP_NETWORK="$(echo ${OVS_BRIDGE_NETWORK} | cut -d / -f 1 | cut -d . -f 1,2,3)"
      if ! [ -z ${IP_NETWORK} ]
      then
        local IP_ADDR="${IP_NETWORK}.${NODE_NUM}"
        local CIDRMASK="/$(echo ${OVS_BRIDGE_NETWORK} | cut -d / -f 2)"
        local CIDR_IP_ADDR="${IP_ADDR}${CIDRMASK}"
      else
        local CIDR_IP_ADDR=""
      fi
    ;;
  esac

  case ${OVS_BRIDGE_PHYSDEV}
  in
    -)
      OVS_BRIDGE_PHYSDEV=""
    ;;
  esac

  case ${OVS_BRIDGE_PARENT_BRIDGE}
  in
    -)
      OVS_BRIDGE_PARENT_BRIDGE=""
    ;;
  esac

  case ${OVS_BRIDGE_VLAN_TAG}
  in
    -)
      OVS_BRIDGE_VLAN_TAG=""
    ;;
  esac

  #-----------------------------------------------------------------------------

  if ! [ -z ${OVS_BRIDGE_PARENT_BRIDGE} ]
  then
    echo -e "${LTBLUE}Starting:${LTGRAY} ${OVS_BRIDGE_NAME}${NC}"
    run sudo ovs-vsctl --may-exist add-br ${OVS_BRIDGE_NAME}
  else
    echo -e "${LTBLUE}Starting:${LTGRAY} ${OVS_BRIDGE_NAME}${NC}"
    run sudo ovs-vsctl --may-exist add-br ${OVS_BRIDGE_NAME} ${OVS_BRIDGE_PARENT_BRIDGE} ${OVS_BRIDGE_VLAN_TAG}
  fi

  if ! [ -z ${OVS_BRIDGE_PHYSDEV} ]
  then
    # check to see if phys dev exists
    if ip addr show | grep -q ${OVS_BRIDGE_PHYSDEV}
    then
      # if so then check if its a veth pair
      if ip addr show | grep -q ${OVS_BRIDGE_PHYSDEV}-nic
      then
        # if so then add veth pair -nic to bridge
        run sudo ovs-vsctl add-port ${OVS_BRIDGE_NAME} ${OVS_BRIDGE_PHYSDEV}-nic
      else
        # if not then add phys dev to bridge
        run sudo ovs-vsctl add-port ${OVS_BRIDGE_NAME} ${OVS_BRIDGE_PHYSDEV}
      fi
    else
      # if not exist then create a veth pair
      configure_new_veth_interfaces ${OVS_BRIDGE_PHYSDEV} ${NODE_NUM} ${OVS_BRIDGE_NETWORK}
      # and add it to the bridge
      run sudo ovs-vsctl add-port ${OVS_BRIDGE_NAME} ${OVS_BRIDGE_PHYSDEV}-nic
    fi
  fi
  
  if ! [ -z ${OVS_BRIDGE_NETWORK} ]
  then
    run sudo ip addr add ${CIDR_IP_ADDR} dev ${OVS_BRIDGE_PHYSDEV}
  fi
}

configure_new_vlan() {
  if [ -z $1 ]
  then
    echo
    echo -e "${LTRED}ERROR: Missing vlan name.${NC}"
    echo
    echo -e "${NC}USAGE: $0 <vlan_name> <node_number> <vlan_network> <eth_dev> <vlan_id>${NC}"
    echo
    return 1
  elif [ -z $2 ]
  then
    echo
    echo -e "${LTRED}ERROR: Missing node number.${NC}"
    echo -e "${LTRED}       The node number must be a number between 1 and 9.${NC}"
    echo
    echo -e "${NC}USAGE: $0 <vlan_name> <node_number> <vlan_network> <eth_dev> <vlan_id>${NC}"
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
    echo -e "${NC}       Example: 192.168.124.0/24${NC}"
    echo
    echo -e "${NC}USAGE: $0 <vlan_name> <node_number> <vlan_network> <eth_dev> <vlan_id>${NC}"
    echo
    return 1
  elif [ -z $4 ]
  then
    echo
    echo -e "${LTRED}ERROR: The VLAN ethernet device must be the name of an existing network interface.${NC}"
    echo -e "${NC}       Example: eth1${NC}"
    echo
    echo -e "${NC}USAGE: $0 <vlan_name> <node_number> <vlan_network> <eth_dev> <vlan_id>${NC}"
    echo
    return 1
  elif [ -z $5 ]
  then
    echo
    echo -e "${LTRED}ERROR: The VLAN ID must be an integer number between 1-2000.${NC}"
    echo -e "${NC}       Example: 124${NC}"
    echo
    echo -e "${NC}USAGE: $0 <vlan_name> <node_number> <vlan_network> <eth_dev> <vlan_id>${NC}"
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
    echo -e "${LTRED}ERROR: An ifcfg- file with that name already exists:${NC} $(basename ${IFCFG_FILE})${NC}"
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
    echo -e "${LTPURPLE}VLAN name:${NC}       ${VLAN_NAME}${NC}"
    echo -e "${LTPURPLE}VLAN ID:${NC}         ${VLAN_ID}${NC}"
    echo -e "${LTPURPLE}Ethernet Device:${NC} ${VLAN_ETHERDEV}${NC}"
    echo -e "${LTPURPLE}IP address:${NC}      ${CIDR_IP_ADDR}${NC}"
    echo -e "${LTPURPLE}Writing out:${NC}     ${IFCFG_FILE}${NC}"
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
    echo -e "${NC}USAGE: $0 <bridge_name> <node_number> <bridge_network> <ethernet_device>${NC}"
    echo
    return 1
  elif [ -z $2 ]
  then
    echo
    echo -e "${LTRED}ERROR: Missing node number.${NC}"
    echo -e "${LTRED}       The node number must be a number between 1 and 9.${NC}"
    echo
    echo -e "${NC}USAGE: $0 <bridge_name> <node_number> <bridge_network> <ethernet_device>${NC}"
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
    echo -e "${NC}       Example: 192.168.124.0/24${NC}"
    echo
    echo -e "${NC}USAGE: $0 <bridge_name> <node_number> <bridge_network> <ethernet_device>${NC}"
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
    echo -e "${LTRED}ERROR: An ifcfg- file with that name already exists:${NC} $(basename ${IFCFG_FILE})${NC}"
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
    echo -e "${LTPURPLE}Bridge name:${NC}  ${BRIDGE_NAME}${NC}"
    echo -e "${LTPURPLE}Using device:${NC} ${BRIDGE_ETHERDEV}${NC}"
    echo -e "${LTPURPLE}IP address:${NC}   ${CIDR_IP_ADDR}${NC}"
    echo -e "${LTPURPLE}Writing out:${NC}  ${IFCFG_FILE}${NC}"
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
    echo -e "${LTRED}ERROR: An ifcfg- file with that name already exists:${NC} $(basename ${IFCFG_FILE})${NC}"
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

    if [ -e "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}" ]
    then
      echo -e "${LTBLUE}Updating VM configuration file ...${NC}"

      #--- cpu ---
      case ${LIBVIRT_SET_CPU_TO_HYPERVISOR_DEFUALT} in
        y|Y|yes|Yes)
          echo -e "  ${LTCYAN}Changing CPU to Hypervisor Default ...${NC}"
          #run sed -i -e '/<cpu/,/cpu>/ d' "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}"
          run sed -i -e "s/\( *\)<cpu.*/\1<cpu mode='host-model' check='partial'>/" "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}"
          if ! grep -q "^ *<feature policy=*require* name=*cpuid*" "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}"
          then
            run sed -i "/^ .*<cpu/a \ \ \ \ <feature policy='require' name='cpuid'\/>" "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}"
          fi
          if ! grep -q "^ *<\/cpu>" "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}"
          then
            run sed -i "/^ .*<feature policy='require' name='cpuid'/a \ \ <\/cpu>" "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}"
          fi
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
          echo -e "  ${LTCYAN}QEMU version ${NC}${QEMUKVM_VER}${LTCYAN} supports vmport parameter, not removing it.${NC}"
          echo
        ;;
        N)
          echo -e "  ${LTCYAN}Removing vmport parameter ...${NC}"
          run sed -i "/vmport/d"  "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}"
          echo
        ;;
      esac
 
      #--- machine type ---
      local MACHINE_TYPE_STRING=$(grep "machine=" "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}" | awk '{ print $3 }' | cut -d \> -f 1 | cut -d \' -f 2)
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
              run sed -i "s/pc-i440fx-.../pc-i440fx-${HIGHEST_440FX_VER}/"  "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}"
            ;;
            q35)
              echo -e "  ${LTCYAN}Changing machine type to highest supported version ...${NC}"
              run sed -i "s/pc-q35-.../pc-q35-${HIGHEST_Q35_VER}/"  "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}"
            ;;
          esac
        ;;
        *) 
          case ${MACHINE_TYPE} in
            i440fx)
              if ! echo ${AVAILABLE_440FX_VERS} | grep -q ${MACHINE_TYPE_VER}
              then
                echo -e "  ${LTCYAN}Changing machine type to highest supported version ...${NC}"
                run sed -i "s/pc-i440fx-.../pc-i440fx-${HIGHEST_440FX_VER}/"  "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}"
                echo
              else
                echo -e "  ${LTCYAN}Machine type is a supported version: ${NC}${MACHINE_TYPE_VER} ${NC}"
                echo
              fi
            ;;
            q35)
              if ! echo ${AVAILABLE_Q35_VERS} | grep -q ${MACHINE_TYPE_VER}
              then
                echo -e "  ${LTCYAN}Changing machine type to highest supported version ...${NC}"
                run sed -i "s/pc-q35-.../pc-q35-${HIGHEST_Q35_VER}/"  "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}"
                echo
              else
                echo -e "  ${LTCYAN}Machine type is a supported version: ${NC}${MACHINE_TYPE_VER} ${NC}"
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
        if grep -q "network=${BRIDGE_NAME}" "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}"
        then
          echo -e "  ${LTCYAN}Changing network= to bridge= ...${NC}"
          run sed -i "s/network=${BRIDGE_NAME}/bridge=${BRIDGE_NAME}/g" "${VM_DEST_DIR}"/"${COURSE_NUM}"/"${VM}"/"${VM_CONFIG}"
          echo
        fi
      done
 
      echo
    fi
}

move_vm_nvram_file() {
# Pass in:
#  - Name of VM that is currently registered with Libvirt
# and
#  - The NVRAM file will be moved into the VM's directory
#  - The OVMF bin file will be copied into the VM's directory
#  - The VM's on-disk config will be updated to point to these new files

  if [ -z "${1}" ]
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

  echo -e "${LTCYAN}Moving NVRAM file to VM Directory ...${NC}"

  if ! [ -z "${NVRAM_FILE}" ]
  then
    local NVRAM_FILE_NAME=$(basename ${NVRAM_FILE})
    local OVMF_BIN_NAME=$(basename ${OVMF_BIN})
    echo -e "${LTCYAN}(NVRAM: ${NC}${NVRAM_FILE}${LTBLUE})${NC}"

    # Does the live config already point to the VM's directory?
    if echo ${NVRAM_FILE} | grep -q "${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram"
    then
      local DO_CHOWN=Y
      # Look for NVRAM file
      if [ -e "${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram/${NVRAM_FILE_NAME}" ]
      then
        echo -e "${LTCYAN}(NVRAM file already in VM's directory ... Skipping)${NC}"
      else
        run sudo mv ${NVRAM_FILE} ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram/
      fi
    fi

    if echo ${OVMF_BIN} | grep -q "${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram"
    then
      local DO_CHOWN=Y
      # Look for OVMF bin
      if [ -e "${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram/${OVMF_BIN_NAME}" ]
      then
        echo -e "${LTCYAN}(OVMF binary already in VM's directory ... Skipping)${NC}"
      else
        run sudo cp ${OVMF_BIN} ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram/
      fi
    fi

    # Does the live config point to the default NVRAM location?
    if echo ${NVRAM_FILE} | grep -q "/var/lib/libvirt/qemu/nvram"
    then
      echo -e "${LTCYAN}(Moving NVRAM file from default location to VM Directory ...)${NC}"
      run mkdir -p ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram
      run sudo mv ${NVRAM_FILE} ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram/
      run sudo cp ${OVMF_BIN} ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram/
      run sudo chmod -R u+rwx,g+rws,o+r ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram
      run sudo chown -R ${USER}.${GROUPS} ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram
      run sed -i "s+\(^ *\)<nvram>.*+\1<nvram>${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram/${NVRAM_FILE_NAME}</nvram>+" ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml
      run sed -i "s+\(^ *\)<loader.*+\1<loader readonly=\"yes\" type=\"pflash\">${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram/${OVMF_BIN_NAME}</loader>+" ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml
    fi

    case ${DO_CHOWN}
    in
      Y)
        run sudo chmod -R u+rwx,g+rws,o+r ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram
        run sudo chown -R ${USER}.${GROUPS} ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram
      ;;
    esac
  elif [ -e ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram ]
  then
    # In case the nvram dir exist in the VM's dir but not in the live config?
    echo -e "${LTCYAN}(NVRAM not defined in VM config but file is in VM Directory ...)${NC}"
    run sudo chmod -R u+rwx,g+rws,o+r ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram
    run sudo chown -R ${USER}.${GROUPS} ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/nvram
  else
    echo -e "${LTCYAN}(NVRAM not defined in VM ... Skipping)${NC}"
  fi
  echo
}

backup_vm_tpm() {
# Pass in:
#  - Name of VM that is currently registered with Libvirt
# and
#  - The TPM files will be copied into the VM's directory

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
    run mkdir -p ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/tpm
    if [ -e ${TPM_DIR}/tpm1.2 ]
    then
      echo -e "${LTCYAN}(TPM v1.2 found)${NC}"
      run sudo cp -R ${TPM_DIR}/tpm1.2 ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/tpm/
    fi
    if [ -e ${TPM_DIR}/tpm2 ]
    then
      echo -e "${LTCYAN}(TPM v2 found)${NC}"
      run sudo cp -R ${TPM_DIR}/tpm2 ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/tpm/
    fi
    run sudo chown -R ${USER}.${GROUPS} ${VM_NAME}/tpm
  else
    echo -e "${LTCYAN}(No TPM files for the VM ... Skipping)${NC}"
  fi
  echo
}

restore_vm_tpm() {
# Pass in:
#  - Name of VM that is currently registered with Libvirt
# and
#  - The TPM files in the VM's directory will be copied to the 
#    default Libvirt location

  if [ -z ${1} ]
  then
    echo -e "${RED}ERROR: You must supply a VM name.${NC}"
    echo 
    echo "  USAGE: restore_vm_tpm <vm_name>"
  else
    local VM_NAME=${1}
  fi

  local VM_UUID="$(virsh dumpxml ${VM_NAME} | grep uuid | cut -d \> -f 2 | cut -d \< -f 1)"
  local TPM_DIR="/var/lib/libvirt/swtpm/${VM_UUID}"

  echo -e "${LTBLUE}Restoring TPM ...${NC}"

  run sudo mkdir -p ${TPM_DIR}
  run sudo chmod 711 ${TPM_DIR}

  if [ -e ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/tpm/tpm1.2 ]
  then
    echo -e "${LTCYAN}(TPM version 1.2 found${NC}"
    run sudo cp -R ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/tpm/tpm1.2 ${TPM_DIR}/
    run sudo chmod 600 ${TPM_DIR}/tpm1.2/tpm-00.permall
    run sudo chmod 700 ${TPM_DIR}/tpm1.2
    run sudo chown -R tss.tss ${TPM_DIR}/tpm1.2
  fi
  if [ -e ${VM_DEST_DIR}/${COURSE_ID}/${VM_NAME}/tpm/tpm2 ]
  then
    echo -e "${LTCYAN}(TPM version 2 found${NC}"
    run sudo cp -R ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/tpm/tpm2 ${TPM_DIR}/
    run sudo chmod 600 ${TPM_DIR}/tpm2/tpm2-00.permall
    run sudo chmod 700 ${TPM_DIR}/tpm2
    run sudo chown -R tss.tss ${TPM_DIR}/tpm2
  fi
}

dump_vm_snapshots() {
# Pass in:
#  - Name of VM that is currently registered with Libvirt
# and
#  - The VM's XML snapshot definitions will be dumped out to files in the 
#    VM's directory

  if [ -z "${1}" ]
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
    echo -e "${LTCYAN}Dumping out VM snapshots ...${NC}"
    if ! [ -e "${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}"/snapshots ]
    then
      run mkdir ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots
    fi
 
    for SNAPSHOT in ${SNAPSHOT_LIST}
    do
      run virsh snapshot-dumpxml ${VM_NAME} ${SNAPSHOT} > ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots/${SNAPSHOT}.xml
 
      local VM_UUID=$(virsh dumpxml ${VM_NAME} | grep uuid | head -1 | cut -d ">" -f 2 | cut -d "<" -f 1)
      local SNAPSHOT_CREATION_TIME=$(grep "<creationTime>.*" ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots/${SNAPSHOT}.xml | cut -d ">" -f 2 | cut -d "<" -f 1)
 
      run mv ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots/${SNAPSHOT}.xml ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots/${SNAPSHOT_CREATION_TIME}.${SNAPSHOT}.xml
 
      unset VM_UUID
      unset SNAPSHOT_CREATION_TIME
    done
  fi
  echo
}

copy_vm_snapshot_files() {
# Pass in:
#  - Name of VM that is currently registered with Libvirt
# and
#  - The VM's snapshot files will be copied to VM's directory

  if [ -z "${1}" ]
  then
    echo -e "${RED}ERROR: You must supply a VM name.${NC}"
    echo 
    echo "  USAGE: copy_vm_snapshot_files <vm_name>"
  else
    local VM_NAME=${1}
  fi

  local VM_SNAPSHOTS="$(virsh snapshot-list ${EXISTING_VM} | grep -v "^----" | grep -v "^ Name")"
  if ! [ -z "${VM_SNAPSHOTS}" ]
  then
    echo -e "${LTCYAN}(VM snapshot XML configs)${NC}"
    mkdir ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}/snapshots
    run sudo cp /var/lib/libvirt/qemu/snapshots/${EXISTING_VM}/*.xml ${VM_DEST_DIR}/${COURSE_NUM}/${EXISTING_VM}/snapshots/
  fi
  unset VM_SNAPSHOTS
  echo
}

update_vm_snapshot_uuid() {
# Pass in:
#  - Name of VM that is currently registered with Libvirt
# and
#  - The UUID of the VM will be updated in the XML shapshot definition files 
#    in the VM's directory

  if [ -z "${1}" ]
  then
    echo -e "${RED}ERROR: You must supply a VM name.${NC}"
    echo 
    echo "  USAGE: update_snapshot_uuid <vm_name>"
  else
    local VM_NAME=${1}
  fi

  if [ -e ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots/ ]
  then
    echo -e "${LTBLUE}Updating VM UUID in snapshot XML files ...${NC}"
    for SNAPSHOT_FILE in $(ls ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots/) 
    do 
      VM_UUID=$(virsh dumpxml ${VM_NAME} | grep uuid | head -1 | cut -d ">" -f 2 | cut -d "<" -f 1)
      run sed -i "s+\( .\)<uuid>.*+\1<uuid>${VM_UUID}</uuid>+g" ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots/${SNAPSHOT_FILE}
    done
  #else
  #  echo
  #  echo -e "${LTCYAN} (No snapshot files to update)"
  fi
  echo
}

update_vm_snapshot_disk_paths() {
# Pass in:
#  - Name of VM that is currently registered with Libvirt
# and
#  - The disk paths of the VM will be updated in the XML shapshot definition
#    files in the VM's directory

  if [ -z "${1}" ]
  then
    echo -e "${RED}ERROR: You must supply a VM name.${NC}"
    echo 
    echo "  USAGE: update_snapshot_disk_paths <vm_name>"
  else
    local VM_NAME=${1}
  fi

  for SNAPSHOT_FILE in $(ls ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshotsls/*.xml)
  do
    local SNAPSHOT_DISK_LIST=$(grep "<source file=.*" ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots/${SNAPSHOT_FILE} | cut -d \' -f 2)
    for SNAPSHOT_DISK in ${SNAPSHOT_DISK_LIST}
    do
      run sed -i "s+\(.*<source file=\)'.*${SNAPSHOT_DISK}'\(.*\)+\1'${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/$(basename ${SNAPSHOT_DISK})'\2+" ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots/${SNAPSHOT_FILE}
    done
  done
  echo
}

restore_vm_snapshots() {
# Pass in:
#  - Name of VM that is currently registered with Libvirt
# and
#  - Snapshots of a VM will be restored using the the XML shapshot definition
#    files in the VM's directory

  if [ -z "${1}" ]
  then
    echo -e "${RED}ERROR: You must supply a VM name.${NC}"
    echo 
    echo "  USAGE: restore_vm_snapshots <vm_name>"
  else
    local VM_NAME=${1}
  fi

  if [ -e ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots/ ]
  then
    echo -e "${LTBLUE}Restoring snapshots for VM ...${NC}"
    for SNAP_FILE in $(ls ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots/)
    do
      run virsh snapshot-create ${VM_NAME} ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/snapshots/${SNAP_FILE} --redefine
    done
  fi
  echo
}

create_vm_snapshot() {
# Pass in:
#  - Name of VM that is currently registered with Libvirt
# and
#  - A snapshot will be ceated for the VM

  if [ -z "${1}" ]
  then
    echo -e "${RED}ERROR: You must supply a VM name.${NC}"
    echo 
    echo "  USAGE: create_vm_snapshot <vm_name> [<snapshot_name>]"
  else
    local VM_NAME=${1}
  fi

  if [ -z "${2}" ]
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
  echo -e "${LTCYAN}Creating snapshot of VM: ${NC}$VM_NAME${NC}"
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

  if ls "${ARCHIVE_FILE}".tgz > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=tgz
  elif ls "${ARCHIVE_FILE}".tar.gz > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=targz
  elif ls "${ARCHIVE_FILE}".tar.bz2 > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=tarbz2
  elif ls "${ARCHIVE_FILE}".tbz > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=tbz
  elif ls "${ARCHIVE_FILE}".tar.xz > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=tarxz
  elif ls "${ARCHIVE_FILE}".txz > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=txz
  elif ls "${ARCHIVE_FILE}".7z* > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=7z
  elif ls "${ARCHIVE_FILE}".tar.7z* > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=tar7z
  elif ls "${ARCHIVE_FILE}".zip > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=zip
  else
    case $(file -b "${ARCHIVE_FILE}" | cut -d \  -f 1) in
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
      run tar xzvf "${ARCHIVE_FILE}".tgz -C ${ARCHIVE_DEST_DIR}
    ;;
    targz)
      run tar xzvf "${ARCHIVE_FILE}".tar.gz -C ${ARCHIVE_DEST_DIR}
    ;;
    tbz)
      run tar xjvf "${ARCHIVE_FILE}".tbz -C ${ARCHIVE_DEST_DIR}
    ;;
    tarbz2)
      run tar xjvf "${ARCHIVE_FILE}".tar.bz2 -C ${ARCHIVE_DEST_DIR}
    ;;
    txz)
      run tar xJvf "${ARCHIVE_FILE}".txz -C ${ARCHIVE_DEST_DIR}
    ;;
    tarxz)
      run tar xJvf "${ARCHIVE_FILE}".tar.xz -C ${ARCHIVE_DEST_DIR}
    ;;
    7z)
      if [ -e "${ARCHIVE_FILE}".7z ]
      then
        local OLD_PWD="${PWD}"
        run cd "${ARCHIVE_DEST_DIR}"

        run 7z x -mmt=on "${OLD_PWD}/${ARCHIVE_FILE}".7z

        run cd -
      elif [ -e "${ARCHIVE_FILE}".7z.001 ]
      then
        local OLD_PWD="${PWD}"
        run cd "${ARCHIVE_DEST_DIR}"

        run 7z x -mmt=on "${OLD_PWD}/${ARCHIVE_FILE}".7z.001

        run cd -
      fi
    ;;
    tar7z)
      if [ -e "${ARCHIVE_FILE}".tar.7z ]
      then
        local OLD_PWD="${PWD}"
        run cd "${ARCHIVE_DEST_DIR}"

        run 7z x -mmt=on -so "${OLD_PWD}/${ARCHIVE_FILE}".tar.7z | tar xf -

        run cd -
      elif [ -e "${ARCHIVE_FILE}".tar.7z.001 ]
      then
        local OLD_PWD="${PWD}"
        run cd "${ARCHIVE_DEST_DIR}"

        run 7z x -mmt=on -so "${OLD_PWD}/${ARCHIVE_FILE}".tar.7z.001 | tar xf -

        run cd -
      fi
    ;;
    zip)
      local OLD_PWD="${PWD}"
      run cd "${ARCHIVE_DEST_DIR}"

      run unzip "${OLD_PWD}/${ARCHIVE_FILE}".zip

      run cd -
    ;;
    GZIP)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.gz$" || echo "${ARCHIVE_FILE}" | grep -q ".tgz$"
      then
        run tar xzvf "${ARCHIVE_FILE}" -C "${ARCHIVE_DEST_DIR}"
      fi
    ;;
    BZIP2)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.bz2$" || echo "${ARCHIVE_FILE}" | grep -q ".tbz$"
      then
        run tar xjvf "${ARCHIVE_FILE}" -C "${ARCHIVE_DEST_DIR}"
      fi
    ;;
    7ZIP)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.7z.001$" || echo "${ARCHIVE_FILE}" | grep -q ".tar.7z$"
      then
        local OLD_PWD="${PWD}"
        run cd "${ARCHIVE_DEST_DIR}"

        run 7z x -mmt=on -so "${OLD_PWD}/${ARCHIVE_FILE}" | tar xf -

        run cd -
      elif  echo "${ARCHIVE_FILE}" | grep -q ".7z.001$" || echo "${ARCHIVE_FILE}" | grep -q ".7z?"
      then
        local OLD_PWD="${PWD}"
        run cd "${ARCHIVE_DEST_DIR}"

        run 7z x -mmt=on "${OLD_PWD}/${ARCHIVE_FILE}"

        run cd -
      fi
    ;;
    ZIP)
      local OLD_PWD="${PWD}"
      run cd "${ARCHIVE_DEST_DIR}"

      run unzip "${OLD_PWD}/${ARCHIVE_FILE}"

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
      run sudo tar xzvf "${ARCHIVE_FILE}" -C ${ARCHIVE_DEST_DIR}
    ;;
    targz)
      run sudo tar xzvf "${ARCHIVE_FILE}".tar.gz -C ${ARCHIVE_DEST_DIR}
    ;;
    tbz)
      run sudo tar xjvf "${ARCHIVE_FILE}" -C ${ARCHIVE_DEST_DIR}
    ;;
    tarbz2)
      run sudo tar xjvf "${ARCHIVE_FILE}".tar.bz2 -C ${ARCHIVE_DEST_DIR}
    ;;
    7z)
      if [ -e "${ARCHIVE_FILE}".7z ]
      then
        local OLD_PWD="${PWD}"
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x "${OLD_PWD}/${ARCHIVE_FILE}".7z

        run sudo cd -
      elif [ -e "${ARCHIVE_FILE}".7z.001 ]
      then
        local OLD_PWD="${PWD}"
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x "${OLD_PWD}/${ARCHIVE_FILE}".7z.001

        run sudo cd -
      fi
    ;;
    tar7z)
      if [ -e "${ARCHIVE_FILE}".tar.7z ]
      then
        local OLD_PWD="${PWD}"
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x -so "${OLD_PWD}/${ARCHIVE_FILE}".tar.7z | tar xf -

        run sudo cd -
      elif [ -e "${ARCHIVE_FILE}".tar.7z.001 ]
      then
        local OLD_PWD="${PWD}"
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x -so "${OLD_PWD}/${ARCHIVE_FILE}".tar.7z.001 | tar xf -

        run sudo cd -
      fi
    ;;
    zip)
      local OLD_PWD="${PWD}"
      run sudo cd ${ARCHIVE_DEST_DIR}

      run sudo unzip "${OLD_PWD}/${ARCHIVE_FILE}".zip

      run sudo cd -
    ;;
    GZIP)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.gz$" || echo "${ARCHIVE_FILE}" | grep -q ".tgz$"
      then
        run sudo tar xzvf "${ARCHIVE_FILE}" -C ${ARCHIVE_DEST_DIR}
      fi
    ;;
    BZIP2)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.bz2$" || echo "${ARCHIVE_FILE}" | grep -q ".tbz$"
      then
        run sudo tar xjvf "${ARCHIVE_FILE}" -C ${ARCHIVE_DEST_DIR}
      fi
    ;;
    7ZIP)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.7z.001$" || echo "${ARCHIVE_FILE}" | grep -q ".tar.7z$"
      then
        local OLD_PWD="${PWD}"
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x -so "${OLD_PWD}/${ARCHIVE_FILE}" | tar xf -

        run sudo cd -
      elif  echo "${ARCHIVE_FILE}" | grep -q ".7z.001$" || echo "${ARCHIVE_FILE}" | grep -q ".7z?"
      then
        local OLD_PWD="${PWD}"
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x "${OLD_PWD}/${ARCHIVE_FILE}"

        run sudo cd -
      fi
    ;;
    ZIP)
      local OLD_PWD="${PWD}"
      run sudo cd ${ARCHIVE_DEST_DIR}

      run sudo unzip "${OLD_PWD}/${ARCHIVE_FILE}"

      run sudo cd -
    ;;
  esac
}

list_archive() {
# Pass in:
#  - an archive file with or without file extenstion
#  - [optionally] the archive type (as determinted by the function: get_archive_type)
# and the contents of the archive will be returned

  local ARCHIVE_FILE=$1
  local ARCHIVE_TYPE=$2

  case ${ARCHIVE_TYPE} in
    tgz)
      tar -tvf "${ARCHIVE_FILE}".tgz  | awk '{ print $6 }'
    ;;
    targz)
      tar -tvf "${ARCHIVE_FILE}".tar.gz  | awk '{ print $6 }'
    ;;
    tbz)
      tar -tvf "${ARCHIVE_FILE}".tbz  | awk '{ print $6 }'
    ;;
    tarbz2)
      tar -tvf "${ARCHIVE_FILE}".tar.bz2  | awk '{ print $6 }'
    ;;
    txz)
      tar -tvf "${ARCHIVE_FILE}".txz  | awk '{ print $6 }'
    ;;
    tarxz)
      tar -tvf "${ARCHIVE_FILE}".tar.xz  | awk '{ print $6 }'
    ;;
    7z)
      if [ -e "${ARCHIVE_FILE}".7z ]
      then
        #7z l "${ARCHIVE_FILE}".7z | awk '/--------/{f=0} f; /--------/{f=1}' | grep -v "^ ." | awk '{ print $6 }' | sort
        #7z l "${ARCHIVE_FILE}".7z | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "${ARCHIVE_FILE}/.*" | sort
        7z l "${ARCHIVE_FILE}".7z | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "$(basename "${ARCHIVE_FILE}" | sed 's/.7z//g')/.*" | sort
      elif [ -e "${ARCHIVE_FILE}".7z.001 ]
      then
        #7z l "${ARCHIVE_FILE}".7z.001 | awk '/--------/{f=0} f; /--------/{f=1}' | grep -v "^ ." | awk '{ print $6 }' | sort
        #7z l "${ARCHIVE_FILE}".7z.001 | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "${ARCHIVE_FILE}/.*" | sort
        7z l "${ARCHIVE_FILE}".7z.001 | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "$(basename "${ARCHIVE_FILE}" | sed 's/.7z.001//g')/.*" | sort
      fi
    ;;
    #tar7z)
    #  if [ -e "${ARCHIVE_FILE}".tar.7z ]
    #  then
    #    local OLD_PWD="${PWD}"
    #    run cd ${ARCHIVE_DEST_DIR}

    #    run 7z x -mmt=on -so "${OLD_PWD}/${ARCHIVE_FILE}".tar.7z | tar xf -

    #    run cd -
    #  elif [ -e "${ARCHIVE_FILE}".tar.7z.001 ]
    #  then
    #    local OLD_PWD="${PWD}"
    #    run cd ${ARCHIVE_DEST_DIR}

    #    run 7z x -mmt=on -so "${OLD_PWD}/${ARCHIVE_FILE}".tar.7z.001 | tar xf -

    #    run cd -
    #  fi
    #;;
    zip)
      unzip -l "${ARCHIVE_FILE}".zip | awk '/---------/{f=0} f; /---------/{f=1}' | awk '{ print $4 }'
    ;;
    GZIP)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.gz$" || echo "${ARCHIVE_FILE}" | grep -q ".tgz$"
      then
        tar -tvf "${ARCHIVE_FILE}"  | awk '{ print $6 }'
      fi
    ;;
    BZIP2)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.bz2$" || echo "${ARCHIVE_FILE}" | grep -q ".tbz$"
      then
        tar -tvf "${ARCHIVE_FILE}"  | awk '{ print $6 }'
      fi
    ;;
    7ZIP)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.7z$"
      then
        7z l "${ARCHIVE_FILE}".tar.7z | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "$(basename "${ARCHIVE_FILE}" | sed 's/.tar.7z//g')/.*" | sort
      elif echo "${ARCHIVE_FILE}" | grep -q ".tar.7z.001$" 
      then
        7z l "${ARCHIVE_FILE}".tar.7z.001 | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "$(basename "${ARCHIVE_FILE}" | sed 's/.tar.7z.001//g')/.*" | sort
      elif  echo "${ARCHIVE_FILE}" | grep -q ".7z?"
      then
        7z l "${ARCHIVE_FILE}".7z | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "$(basename "${ARCHIVE_FILE}" | sed 's/.7z//g')/.*" | sort
      elif  echo "${ARCHIVE_FILE}" | grep -q ".7z.001$" 
      then
        7z l "${ARCHIVE_FILE}".7z.001 | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "$(basename "${ARCHIVE_FILE}" | sed 's/.7z.001//g')/.*" | sort
      fi
    ;;
    ZIP)
      unzip -l "${ARCHIVE_FILE}" | awk '/---------/{f=0} f; /---------/{f=1}' | awk '{ print $4 }'
    ;;
  esac
}

virtualbmc_control() {
  local USAGE_STRING="USAGE: ${0} <action> <vm_name> <bmc_addr> <bnc_port> <bmc_network_name> <bmc_username> <bmc_password> <libvirt_uri>"

  if [ -z "${1}" ]
  then
    echo
    echo "ERROR: You must provide the action: create | remove"
    echo
    echo ${USAGE_STRING}
    echo
    return 1
  elif [ -z "${2}" ]
  then
    echo
    echo "ERROR: You must provide the name of the VM"
    echo
    echo ${USAGE_STRING}
    echo
    return 1
  elif [ -z "${3}" ]
  then
    echo
    echo "ERROR: You must provide the address of the BMC"
    echo
    echo ${USAGE_STRING}
    echo
    return 1
  elif [ -z "${4}" ]
  then
    echo
    echo "ERROR: You must provide the port of the BMC"
    echo
    echo ${USAGE_STRING}
    echo
    return 1
  elif [ -z "${5}" ]
  then
    echo
    echo "ERROR: You must provide the name of the BMC network"
    echo
    echo ${USAGE_STRING}
    echo
    return 1
  elif [ -z "${6}" ]
  then
    echo
    echo "ERROR: You must provide the username for the BMC"
    echo
    echo ${USAGE_STRING}
    echo
    return 1
  elif [ -z "${7}" ]
  then
    echo
    echo "ERROR: You must provide the password for the BMC"
    echo
    echo ${USAGE_STRING}
    echo
    return 1
  fi

  local ACTION=${1}
  local VM_NAME=${2}
  local BMC_ADDR=${3}
  local BMC_PORT=${4}
  local BMC_NETWORK_NAME=${5}
  local BMC_USERNAME=${6}
  local BMC_PASSWORD=${7}
  local BMC_URI=${8}
  local BMC_NETWORK_CIDR=$(ip addr show dev ${BMC_NETWORK_NAME} | grep " .inet " | awk '{ print $2 }' | cut -d "/" -f 2)

  #echo
  #echo "########################################################"
  #echo ACTION=${ACTION}
  #echo VM_NAME=${VM_NAME}
  #echo BMC_ADDR=${BMC_ADDR}
  #echo BMC_PORT=${BMC_PORT}
  #echo BMC_NETWORK_NAME=${BMC_NETWORK_NAME}
  #echo BMC_USERNAME=${BMC_USERNAME}
  #echo BMC_PASSWORD=${BMC_PASSWORD}
  #echo BMC_URI=${BMC_URI}
  #echo BMC_NETWORK_CIDR=${BMC_NETWORK_CIDR}
  #echo "########################################################"
  #echo;read

  if echo ${VM_NAME} | grep -q "-"
  then
    local VM_SHORT_NAME=$(echo ${VM_NAME} | cut -d "-" -f 2)
  else
    local VM_SHORT_NAME=${VM_NAME}
  fi

  local VM_SHORT_NAME_LEN=$(echo ${VM_SHORT_NAME} | wc -m)
  ((VM_SHORT_NAME_LEN--))

  if [ "${VM_SHORT_NAME_LEN}" -le 7 ]
  then
    local PREF=${VM_SHORT_NAME}
  else
    local NUM=$(echo ${VM_SHORT_NAME} | grep -o [0-9]*$)
    if [ -z "${NUM}" ]
    then
      local PREF=$(echo ${VM_SHORT_NAME} | cut -c 1,2,3,4,5,6,7)
    else
      local PREF=$(echo ${VM_SHORT_NAME} | cut -c 1,2,3,4)
    fi
  fi

  local VETH_NAME_A=${PREF}${NUM}-bmc-nic
  local VETH_NAME_B=${PREF}${NUM}-bmc

  #echo "--------------------------------------"
  #echo VM_SHORT_NAME=${VM_SHORT_NAME}
  #echo VM_SHORT_NAME_LEN=${VM_SHORT_NAME_LEN}
  #echo
  #echo NUM=${NUM}
  #echo PREF=${PREF}
  #echo
  #echo VETH_NAME_A=${VETH_NAME_A}
  #echo VETH_NAME_B=${VETH_NAME_B}
  #echo "--------------------------------------"
  #echo

  case ${ACTION}
  in
    create)
      if ! ip addr show | grep -q ${VETH_NAME_B}
      then
        # Create the veth pair for the BMC
        #echo sudo ip link add dev ${VETH_NAME_A} type veth peer name ${VETH_NAME_B}
        run sudo ip link add dev ${VETH_NAME_A} type veth peer name ${VETH_NAME_B}
    
        #echo sudo ip link set dev ${VETH_NAME_A} up
        run sudo ip link set dev ${VETH_NAME_A} up
    
        #echo sudo ip link set ${VETH_NAME_A} master ${BMC_NETWORK_NAME}
        run sudo ip link set ${VETH_NAME_A} master ${BMC_NETWORK_NAME}
    
        #echo sudo ip addr add ${BMC_ADDR} dev ${VETH_NAME_B}
        run sudo ip addr add ${BMC_ADDR}/${BMC_NETWORK_CIDR} dev ${VETH_NAME_B}
    
        #echo sudo ip link set ${VETH_NAME_B} up
        run sudo ip link set ${VETH_NAME_B} up
 
      fi
      if ! sudo vbmc list | grep -q ${VM_NAME}
      then
        # Create and start the BMC
        run sudo vbmc add ${VM_NAME} --address ${BMC_ADDR} --port ${BMC_PORT} --username ${BMC_USERNAME} --password ${BMC_PASSWORD} --libvirt-uri ${BMC_URI}
        sleep 2
        run sudo vbmc start ${VM_NAME}
        run sudo vbmc show ${VM_NAME}

        echo
      fi
    ;;
    remove)
      # Stop and remove the BMC
      run sudo vbmc stop ${VM_NAME}
      run sudo vbmc delete ${VM_NAME}

      # Remove the veth pair for the BMC
      #echo sudo ip link set ${VETH_NAME_B} down
      run sudo ip link set ${VETH_NAME_B} down
  
      #echo sudo ip addr del ${BMC_ADDR} dev ${VETH_NAME_B}
      run sudo ip addr del ${BMC_ADDR}/${BMC_NETWORK_CIDR} dev ${VETH_NAME_B}
  
      #echo sudo ip link set dev ${VETH_NAME_A} down
      run sudo ip link set dev ${VETH_NAME_A} down
  
      #echo sudo ip link del dev ${VETH_NAME_A} type veth
      run sudo ip link del dev ${VETH_NAME_A} type veth
      
      echo
    ;;
    test)
      sudo vbmc list | grep -q "${VM_NAME}"
      return $?
    ;;
  esac
}

