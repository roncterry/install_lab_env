#!/bin/bash
# Version: 1.3.0
# Date: 2017-10-01

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
#                          Functions
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

activate_libvirt_virtual_networks
define_virtual_machines
activate_libvirt_storage_pools
#activate_libvirt_storage_volumes
create_new_vlans
create_new_bridges

echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
echo -e "${LTCYAN}                                  Finished"
echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
