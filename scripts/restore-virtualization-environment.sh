#!/bin/bash
# Version: 1.0.1
# Date: 2016-07-07

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
else
  CONFIG="${DEFAULT_CONFIG}"
fi
 
if ! [ -e "${CONFIG}" ]
then
  echo
  echo -e "${RED}ERROR:  The configuration file $CONFIG doesn't exist.${NC}"
  echo
  exit 1
else
  #echo -e ${LTBLUE}CONFIG=${NC}${CONFIG}
  source ${CONFIG}
fi

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

VNET_CONFIG_DIR="${CONFIG_SRC_DIR}/libvirt.cfg"
LOCAL_VNET_CONFIG_DIR="${SCRIPTS_DEST_DIR}/config/libvirt.cfg"
#-- TODO: reserved for upcoming update --DO NOT UNCOMMENT--
#LOCAL_VNET_CONFIG_DIR="${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/libvirt.cfg"

RPM_DIR="./rpms"
  
VMWARE_INSTALLER_DIR="./vmware"

##############################################################################
#                          Functions
##############################################################################

activate_libvirt_virtual_networks() {
  #local LIBVIRT_VNET_LIST=$(cd ~/${LOCAL_VNET_CONFIG_DIR} ; ls *.xml | sed 's/.xml//g')
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
      echo -e "${LTGREEN}COMMAND: ${GRAY}sudo virsh net-define ${LOCAL_VNET_CONFIG_DIR}/${VNET}.xml${NC}"
      sudo virsh net-define ${LOCAL_VNET_CONFIG_DIR}/${VNET}.xml
      echo -e "${LTGREEN}COMMAND: ${GRAY}sudo virsh net-autostart ${VNET}${NC}"
      sudo virsh net-autostart ${VNET}
      echo -e "${LTGREEN}COMMAND: ${GRAY}sudo virsh net-start ${VNET}${NC}"
      sudo virsh net-start ${VNET}
    elif [ "$(sudo virsh net-list | grep  ${VNET} | awk '{ print $2 }')" != active ]
    then
      echo -e "${LTGREEN}COMMAND: ${GRAY}sudo virsh net-autostart ${VNET}${NC}"
      sudo virsh net-autostart ${VNET}
      if [ "$(sudo virsh net-list | grep  ${VNET} | awk '{ print $3 }')" != yes ]
      then
        echo -e "${LTGREEN}COMMAND: ${GRAY}sudo virsh net-start ${VNET}${NC}"
        sudo virsh net-start ${VNET}
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
        echo -e "${LTGREEN}COMMAND: ${GRAY} sudo virsh define ${VM_DEST_DIR}/${VM}/${VM}-${MULTI_LM_EXT}.xml${NC}"
        sudo virsh define ${VM_DEST_DIR}/${VM}/${VM}-${MULTI_LM_EXT}.xml
      ;;
      *)
        echo -e "${LTGREEN}COMMAND: ${GRAY} sudo virsh define ${VM_DEST_DIR}/${VM}/${VM}.xml${NC}"
        sudo virsh define ${VM_DEST_DIR}/${VM}/${VM}.xml
      ;;
    esac
  done
  echo
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

echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
echo -e "${LTCYAN}                                  Finished"
echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
