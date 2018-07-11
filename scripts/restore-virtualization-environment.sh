#!/bin/bash
# Version: 1.6.0
# Date: 2018-07-10

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

cd $(dirname $0)

DEFAULT_CONFIG="./config/lab_env.cfg"

if echo $* | grep -q "config="
then
  CONFIG=$(echo $* | grep -o "config=.*" | cut -d = -f 2 | cut -d \  -f 1)
  if ! [ -e "${CONFIG}" ]
  then
    echo
    echo -e "${RED}ERROR:  The configuration file $CONFIG doesn't exist.${NC}"
    echo
    exit 1
  fi
else
  CONFIG="${DEFAULT_CONFIG}"
fi
 
source ${CONFIG}

# From common_functions.sh
run () {
  echo -e "${LTGREEN}COMMAND: ${GRAY}$*${NC}"
  "$@"
}

##############################################################################
#                          Global Variables
##############################################################################

CONFIG_SRC_DIR="./config"

PDF_SRC_DIR="./pdf"
PDF_DEST_DIR="${HOME}/pdf"

SCRIPTS_SRC_DIR="./scripts"
SCRIPTS_DEST_DIR="${HOME}/scripts"

VM_AUTOBUILD_SCRIPT_DIR="create-vms"
VM_AUTOBUILD_CONFIG_DIR="${CONFIG_SRC_DIR}/create-vms.cfg"

LAB_SCRIPT_DIR="lab-automation"
DEPLOY_CLOUD_SCRIPT_DIR="lab-automation"

VM_SRC_DIR="./VMs"
VM_DEST_DIR="/home/VMs/${COURSE_NUM}"

ISO_SRC_DIR="./iso"
ISO_DEST_DIR="/home/iso"

IMAGE_SRC_DIR="./images"
IMAGE_DEST_DIR="/home/images"

LIBVIRT_CONFIG_DIR="${CONFIG_SRC_DIR}/${COURSE_NUM}/libvirt.cfg"
LOCAL_LIBVIRT_CONFIG_DIR="${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/libvirt.cfg"

RPM_DIR="./rpms"
  
VMWARE_INSTALLER_DIR="./vmware"

##############################################################################
#                          Helper Functions
##############################################################################

virtualbmc_control() {
  local USAGE_STRING="USAGE: ${0} <action> <vm_name> <bmc_addr> <bnc_port> <bmc_network_name> <bmc_username> <bmc_password> <libvirt_uri>"

  if [ -z ${1} ]
  then
    echo
    echo "ERROR: You must provide the action: create | remove"
    echo
    echo ${USAGE_STRING}
    echo
    return 1
  elif [ -z ${2} ]
  then
    echo
    echo "ERROR: You must provide the name of the VM"
    echo
    echo ${USAGE_STRING}
    echo
    return 1
  elif [ -z ${3} ]
  then
    echo
    echo "ERROR: You must provide the address of the BMC"
    echo
    echo ${USAGE_STRING}
    echo
    return 1
  elif [ -z ${4} ]
  then
    echo
    echo "ERROR: You must provide the port of the BMC"
    echo
    echo ${USAGE_STRING}
    echo
    return 1
  elif [ -z ${5} ]
  then
    echo
    echo "ERROR: You must provide the name of the BMC network"
    echo
    echo ${USAGE_STRING}
    echo
    return 1
  elif [ -z ${6} ]
  then
    echo
    echo "ERROR: You must provide the username for the BMC"
    echo
    echo ${USAGE_STRING}
    echo
    return 1
  elif [ -z ${7} ]
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
    if [ -z ${NUM} ]
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

##############################################################################
#                          Script Functions
##############################################################################

activate_libvirt_virtual_networks() {
  #local LIBVIRT_VNET_LIST=$(cd ~/${LOCAL_LIBVIRT_CONFIG_DIR} ; ls *.xml | sed 's/.xml//g')
  if [ -z "${LIBVIRT_VNET_LIST}" ]
  then
    return
  fi
  echo -e "${LTBLUE}Activating Libvirt virtual network(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VNET in ${LIBVIRT_VNET_LIST}
  do
    if ! sudo virsh net-list | grep -q ${VNET}
    then
      run sudo virsh net-define ${LOCAL_LIBVIRT_CONFIG_DIR}/${VNET}.xml
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
  done
  echo
}

define_virtual_machines() {
  echo -e "${LTBLUE}Defining Libvirt virtual machine(s) ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  for VM in $(cd ${VM_DEST_DIR} ; ls)
  do
    case ${MULTI_LAB_MACHINE} in
      y|Y|Yes|Yes|YES)
        run sudo virsh define ${VM_DEST_DIR}/${VM}/${VM}-${MULTI_LM_EXT}.xml
      ;;
      *)
        run sudo virsh define ${VM_DEST_DIR}/${VM}/${VM}.xml
      ;;
    esac
  done
  echo
}

activate_libvirt_storage_pools() {
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
      run sudo virsh pool-define ${LOCAL_LIBVIRT_CONFIG_DIR}/${POOL}.xml
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
  done
  echo
}

activate_libvirt_storage_volumes() {
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
        run sudo virsh vol-create ${POOL_NAME} ${LOCAL_LIBVIRT_CONFIG_DIR}/${VOLUME}.xml
      fi
    fi
  done
  echo
}

create_virtual_bmcs() {
  local DEFAULT_BMC_ADDR=127.0.0.1
  local DEFAULT_BMC_PORT=623
  local DEFAULT_BMC_USERNAME=admin
  local DEFAULT_BMC_PASSWORD=password

  if [ -z "${VIRTUAL_BMC_LIST}" ]
  then
    return
  fi

  if ! which vbmc > /dev/null
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

    if [ -z ${BMC_ADDR} ]
    then
      BMC_ADDR=${DEFAULT_BMC_ADDR}
    fi

    local BMC_PORT=$(echo ${BMC} | cut -d , -f 3)
    if [ -z ${BMC_PORT} ]
    then
      BMC_PORT=${DEFAULT_BMC_PORT}
    fi

    local BMC_USERNAME=$(echo ${BMC} | cut -d , -f 4)
    if [ -z ${BMC_USERNAME} ]
    then
      BMC_USERNAME=${DEFAULT_BMC_USERNAME}
    fi

    local BMC_PASSWORD=$(echo ${BMC} | cut -d , -f 5)
    if [ -z ${BMC_PASSWORD} ]
    then
      BMC_PASSWORD=${DEFAULT_BMC_PASSWORD}
    fi

    # --create the bmc---------------------------------------

    #>Option 1: use virtualbmc directly
    #if ! sudo vbmc list | grep -q ${VM_NAME}
    #then
    #  run sudo vbmc add ${VM_NAME} --address ${BMC_ADDR} --port ${BMC_PORT} --username ${BMC_USERNAME} --password ${BMC_PASSWORD}
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
    virtualbmc_control create ${VM_NAME} ${BMC_ADDR} ${BMC_PORT} ${VIRTUAL_BMC_NETWORK} ${BMC_USERNAME} ${BMC_PASSWORD}

    #--test--------------------------------------------------
    if ! virtualbmc_control test ${VM_NAME} ${BMC_ADDR} ${BMC_PORT} ${VIRTUAL_BMC_NETWORK} ${BMC_USERNAME} ${BMC_PASSWORD}
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
    echo
  done
}



##############################################################################
#                          Main Code Body
##############################################################################

echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
echo -e "${LTCYAN}                      Restoring Virtualiztion Environment "
echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
echo

create_new_veth_interfaces
create_new_ovs_bridges
activate_libvirt_virtual_networks
define_virtual_machines
activate_libvirt_storage_pools
#activate_libvirt_storage_volumes
create_virtual_bmcs
create_new_vlans
create_new_bridges

echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
echo -e "${LTCYAN}                                  Finished"
echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
