#!/bin/bash

# Version: 1.0.0
# Date: 2026-11-10

##############################################################################
#  Global Variables and Usage
##############################################################################

TEMPLATES_DIR="../templates"
VM_DEST_DIR="/home/VMs"
ISO_DEST_DIR="/home/iso"
IMAGE_DEST_DIR="/home/images"

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

usage() {
  echo
  echo "USAGE: ${0} <lab_env_dir> <vm_name> <vm_config_template> [<vm_instance_num>]"
  echo
  echo "    Where:"
  echo "       <lab_env_dir>        Is the path to the directory containing the lab"
  echo "                            environment VM directories"
  echo "       <vm_name>            Is the name of the new VM"
  echo "       <vm_config_template> Is the name of the VM config template to use when"
  echo "                            creating the new VM. This mut be a directory in"
  echo "                            ${TEMPALTE_DIE} that contains both a"
  echo "                            .cfg.template and .xml.template file with"
  echo "                            filenames that match the template directory name"
  echo "       <vm_instance_num>    Is a decimal number between 1-99 that is the"
  echo "                            instance number of the VM that value will be"
  echo "                            used for the 5th field of the VMs MAC address."
  echo "                            It will also commonly be the last octet of the"
  echo "                            VM's IP address."
  echo "                            Example:" 
  echo "                              If the VM's name (<vm_name>) is node11 then"
  echo "                              <vm_instance_num> would commonly be 11."
  echo "                            If not specified a random number will be used" 
  echo "                            between 2-99. You will need to ensure that this"
  echo "                            doesn't confilict with any other VM."
  echo
}

if [ -z ${1} ]
then
  echo
  echo -e"${RED}ERROR: You must supply a lab environment directory. Exiting.${NC}"
  echo
  usage
  exit
else
  COURSE_NUM=${1}
fi

if [ -z ${2} ]
then
  echo
  echo -e "${RED}ERROR: You must supply a VM name. Exiting.${NC}"
  echo
  usage
  exit
else
  VM_NAME=${2}
fi

if [ -z ${3} ]
then
  echo
  echo -e "${RED}ERROR: You must supply the name of a VM template config file in the ${TEMPLATES_DIR}/libvirt/vm/ directory. Exiting.${NC}"
  echo
  usage
  exit
else
  VM_CONFIG_TEMPLATE=${3}
  if ! [ -e ${TEMPLATES_DIR}/libvirt/vm/${VM_CONFIG_TEMPLATE} ]
  then
    echo
    echo -e "${RED}ERROR: The specified VM config template directory doesn't exist in ${TEMPLATES_DIR}/libvirt/vm/. Exiting.${NC}"
    echo
    exit
  fi
fi

##############################################################################
#  Script Functions
##############################################################################

wwn_gen() {
  #=================================================================
  # Generate a Libvirt compatible WWN for a SCSI Disk
  #=================================================================

  local PREFIX="0x"
  local WWN_UUID=$(uuidgen)
  local WWN="${PREFIX}$(echo ${WWN_UUID} | tr -d '-' | cut -c 1-16)"
  echo ${WWN}
}

serial_gen() {
  #=================================================================
  # Generate a serial number for a VirtIO Disk
  #=================================================================

  local PREFIX="VIO-"
  local SERIAL_UUID=$(uuidgen)
  local SERIAL="${PREFIX}$(echo ${SERIAL_UUID} | tr -d '-' | cut -c 1-16)"
  echo ${SERIAL}
}

update_libvirt_vm_machine_type() {
  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"
  echo -e "${LTBLUE}Updating Libvirt VM machine type ...${NC}"
  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"
  
  AVAILABLE_440FX_VERS=$(virsh capabilities | grep -Eo "pc-i440fx-[0-9]+\.[0-9]+" | cut -d - -f 3 | sort | uniq)
  if [ -z "${AVAILABLE_440FX_VERS}" ]
  then
    local HIGHEST_440FX_VER=0
  else
    local HIGHEST_440FX_VER=$(echo ${AVAILABLE_440FX_VERS} | cut -d " " -f $(echo ${AVAILABLE_440FX_VERS} | wc -w))
  fi

  AVAILABLE_Q35_VERS=$(virsh capabilities | grep -Eo "pc-q35-[0-9]+\.[0-9]+" | cut -d - -f 3 | sort | uniq)
  if [ -z "${AVAILABLE_Q35_VERS}" ]
  then
    local HIGHEST_Q35_VER=0
  else
    local HIGHEST_Q35_VER=$(echo ${AVAILABLE_Q35_VERS} | cut -d " " -f $(echo ${AVAILABLE_Q35_VERS} | wc -w))
  fi

  AVAILABLE_XENFV_VERS=$(virsh capabilities | grep -Eo "xenfv-[0-9]+\.[0-9]+" | cut -d - -f 2 | sort | uniq)
  if [ -z "${AVAILABLE_XENFV_VERS}" ]
  then
    local HIGHEST_XENFV_VER=0
  else
    local HIGHEST_XENFV_VER=$(echo ${AVAILABLE_XENFV_VERS} | cut -d " " -f $(echo ${AVAILABLE_XENFV_VERS} | wc -w))
  fi

  AVAILABLE_PC_VERS=$(virsh capabilities | grep -Eo "pc-[0-9]+\.[0-9]+" | cut -d - -f 2 | sort | uniq)
  if [ -z "${AVAILABLE_PC_VERS}" ]
  then
    local HIGHEST_PC_VER=0
  else
    local HIGHEST_PC_VER=$(echo ${AVAILABLE_PC_VERS} | cut -d " " -f $(echo ${AVAILABLE_PC_VERS} | wc -w))
  fi

  local MACHINE_TYPE_STRING=$(grep "machine=" ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml | awk '{ print $3 }' | cut -d \> -f 1 | cut -d \' -f 2)
  local MACHINE_TYPE=$(echo ${MACHINE_TYPE_STRING} | cut -d \- -f 2)
  local MACHINE_TYPE_VER=$(echo ${MACHINE_TYPE_STRING} | cut -d \- -f 3)

  case ${MACHINE_TYPE} in
    i440fx)
      echo -e "  ${LTCYAN}Changing machine type to highest supported version ...${NC}"
      sed -i "s/${MACHINE_TYPE_STRING}/pc-i440fx-${HIGHEST_440FX_VER}/"  ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml
    ;;
    q35)
      echo -e "  ${LTCYAN}Changing machine type to highest supported version ...${NC}"
      sed -i "s/${MACHINE_TYPE_STRING}/pc-q35-${HIGHEST_Q35_VER}/"  ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml
    ;;
  esac
  echo
}


##############################################################################

create_new_vm_dirs() {
  #=================================================================
  # Create the default directories inside the VM directory
  #=================================================================

  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"
  echo -e "${LTBLUE}Creating the VM's directory structure ...${NC}"
  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"

  VM_SUBDIR_LIST="custom-config/cloud-init custom-config/ignition custom-config/combustion nvram tpm"

  echo -e "${LTGREEN}COMMAND:${NC} mkdir -p ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}${NC}"
  mkdir -p ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}
  
  for VM_SUBDIR in ${VM_SUBDIR_LIST}
  do
    echo -e "${LTGREEN}COMMAND:${NC} mkdir -p ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_SUBDIR}${NC}"
    mkdir -p ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_SUBDIR}
  done

  echo
}

copy_template_config_files() {
  #=================================================================
  # Copy the template VM config files into the VM directory and update them with the VM's info
  #=================================================================

  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"
  echo -e "${LTBLUE}Copying template config files into the new VM ...${NC}"
  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"

  echo -e "${LTGREEN}COMMAND:${NC} cp ${TEMPLATES_DIR}/libvirt/vm/${VM_CONFIG_TEMPLATE}/${VM_CONFIG_TEMPLATE}.cfg.template ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.cfg${NC}"
  cp ${TEMPLATES_DIR}/libvirt/vm/${VM_CONFIG_TEMPLATE}/${VM_CONFIG_TEMPLATE}.cfg.template ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.cfg

  echo -e "${LTGREEN}COMMAND:${NC} cp ${TEMPLATES_DIR}/libvirt/vm/${VM_CONFIG_TEMPLATE}/${VM_CONFIG_TEMPLATE}.xml.template ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml${NC}"
  cp ${TEMPLATES_DIR}/libvirt/vm/${VM_CONFIG_TEMPLATE}/${VM_CONFIG_TEMPLATE}.xml.template ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml

  echo -e "${LTGREEN}COMMAND:${NC} cp ${TEMPLATES_DIR}/cloud-init/meta-data.template ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/custom-config/cloud-init/meta-data${NC}"
  cp ${TEMPLATES_DIR}/cloud-init/meta-data.template ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/custom-config/cloud-init/meta-data

  echo -e "${LTGREEN}COMMAND:${NC} cp ${TEMPLATES_DIR}/cloud-init/user-data.generic.template ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/custom-config/cloud-init/user-data${NC}"
  cp ${TEMPLATES_DIR}/cloud-init/user-data.generic.template ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/custom-config/cloud-init/user-data

  echo
}

update_vm_config_files() {
  #=================================================================
  # Source in the VM's .cfg config file
  #=================================================================

  source ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.cfg

  #=================================================================
  # Update the the VM's config file with the VM's info
  #=================================================================

  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"
  echo -e "${LTBLUE}Updating the VM's config files ...${NC}"
  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"

  if [ -z ${VM_INSTANCE_NUMBER} ]
  then
    if [ -z ${4} ]
    then
      VM_INSTANCE_NUM=$(shuf -i 2-99 -n 1)
    else
      VM_INSTANCE_NUM=${4}
    fi

    sed -i "s/^VM_INSTANCE_NUMBER*/VM_INSTANCE_NUMBER=${VM_INSTANCE_NUM}/g" ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.cfg

    VM_INSTANCE_NUM_HEX=$(printf '%02x\n' ${VM_INSTANCE_NUM})
  fi

  echo -e "  ${LTCYAN}-Course Number (${COURSE_NUM})${NC}"
  sed -i "s/_COURSE_NUM_/${COURSE_NUM}/g" ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml

  echo -e "  ${LTCYAN}-VM Name (${VM_NAME})${NC}"
  sed -i "s/_VM_NAME_/${VM_NAME}/g" ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml

  echo -e "  ${LTCYAN}-MAC Addr Prefix (${MAC_ADDR_PREFIX})${NC}"
  sed -i "s/_MAC_ADDR_PREFIX_/${MAC_ADDR_PREFIX}/g" ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml

  echo -e "  ${LTCYAN}-VM Instance Number (${VM_INSTANCE_NUM})${NC}"
  sed -i "s/_VM_INSTANCE_NUM_/${VM_INSTANCE_NUM}/g" ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml

  echo -e "  ${LTCYAN}(Creating VM's storage pool)${NC}"
  echo "<pool type=\"dir\">
  <name>${VM_NAME}</name>
  <capacity unit=\"bytes\">0</capacity>
  <allocation unit=\"bytes\">0</allocation>
  <available unit=\"bytes\">0</available>
  <source>
  </source>
  <target>
    <path>${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}</path>
  </target>
</pool>" > ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.pool.xml
  echo

  #=================================================================
  # Generate new virtual disk WWNs and Serial Numbers
  #=================================================================

  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"
  echo -e "${LTBLUE}Generating new WWNs and Serial Numbers for virtual disks ...${NC}"
  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"

  echo -e "  ${LTCYAN}-WWNs${NC}"
  for WWN_DISK in $(grep _WWN_ ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml | cut -d \> -f 2 | cut -d \< -f 1)
  do
    local DISK_WWN=$(wwn_gen)

    sed -i "s/${WWN_DISK}/${DISK_WWN}/g" ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml

    unset DISK_WWN
  done

  echo -e "  ${LTCYAN}-Serial Numbers${NC}"
  for SERIAL_DISK in $(grep _SERIAL_ ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml | cut -d \> -f 2 | cut -d \< -f 1)
  do
    local DISK_SERIAL=$(serial_gen)

    sed -i "s/${SERIAL_DISK}/${DISK_SERIAL}/g" ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml

    unset DISK_SERIAL
  done
  echo
}

update_custom_config() {
  #=================================================================
  # Update cloud-init config files
  #=================================================================

  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"
  echo -e "${LTBLUE}Updating the custom-config files ...${NC}"
  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"

  echo -e "  ${LTCYAN}cloud-init:meta-data (VM Name)${NC}"
  sed -i "s/_VM_NAME_/${VM_NAME}/g" ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/custom-config/cloud-init/meta-data
  echo
}

create_vm_disk_image_files() {
  #=================================================================
  # Create the VM's bootdisk image
  #=================================================================

  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"
  echo -e "${LTBLUE}Creating the bootdisk image file ...${NC}"
  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"

  if ! [ -z ${BOOTDISK_IMAGE} ]
  then
    if [ -e ${IMAGE_DEST_DIR}/${COURSE_NUM}/${BOOTDISK_IMAGE} ]
    then
      echo -e "${LTGREEN}COMMAND:${NC} cp ${IMAGE_DEST_DIR}/${COURSE_NUM}/${BOOTDISK_IMAGE} ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${BOOTDISK}${NC}"
      cp ${IMAGE_DEST_DIR}/${COURSE_NUM}/${BOOTDISK_IMAGE} ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${BOOTDISK}

      echo -e "${LTGREEN}COMMAND:${NC} qemu-img resize ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${BOOTDISK} ${BOOTDISK_SIZE}${NC}"
      qemu-img resize ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${BOOTDISK} ${BOOTDISK_SIZE}
      echo
    fi
  else
    echo -e "${LTGREEN}COMMAND:${NC} qemu-img create -f ${BOOTDISK_FORMAT} ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${BOOTDISK} ${BOOTDISK_SIZE}${NC}"
    qemu-img create -f ${BOOTDISK_FORMAT} ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${BOOTDISK} ${BOOTDISK_SIZE}
    echo
  fi

  #=================================================================
  # Create the VM's additional disk image files
  #=================================================================

  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"
  echo -e "${LTBLUE}Creating the additional disk image files ...${NC}"
  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"

  for ADDITIONAL_DISK in ${ADDITIONAL_DISK_LIST}
  do
    ADDITIONAL_DISK_NAME=$(echo ${ADDITIONAL_DISK} | cut -d , -f 1)
    ADDITIONAL_DISK_SIZE=$(echo ${ADDITIONAL_DISK} | cut -d , -f 2)
    ADDITIONAL_DISK_FORMAT=$(echo ${ADDITIONAL_DISK} | cut -d , -f 3)

    echo -e "${LTGREEN}COMMAND:${NC} qemu-img create -f ${ADDITIONAL_DISK_FORMAT} ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${ADDITIONAL_DISK_NAME} ${ADDITIONAL_DISK_SIZE}${NC}"
    qemu-img create -f ${ADDITIONAL_DISK_FORMAT} ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${ADDITIONAL_DISK_NAME} ${ADDITIONAL_DISK_SIZE}

    unset ADDITIONAL_DISK_NAME
    unset ADDITIONAL_DISK_SIZE
    unset ADDITIONAL_DISK_FORMAT
    echo
  done

  echo
}

create_config_iso() {
  if [ -e rebuild_config_iso.sh ]
  then
    echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"
    echo -e "${LTBLUE}Creating the config iso image file ...${NC}"
    echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"
    
    local SCRIPT_DIR=${PWD}
    cd ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}
    source ${VM_NAME}.cfg
    ${SCRIPT_DIR}/rebuild_config_iso.sh ${CUSTOM_CONFIG_ISO_FORMAT}
 
    cd ${SCRIPT_DIR}
    echo
  fi
}

define_vm_and_storage_pool() {

  update_libvirt_vm_machine_type

  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"
  echo -e "${LTBLUE}Define VM and VM's Storage Pool ...${NC}"
  echo -e "${LTBLUE}----------------------------------------------------------------------${NC}"
  
  echo -e "${LTGREEN}COMMAND:${NC} virsh define ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml${NC}"
  virsh define ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml

  echo -e "${LTGREEN}COMMAND:${NC} virsh define ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml${NC}"
  virsh define ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.xml

  echo -e "${LTGREEN}COMMAND:${NC} virsh pool-define ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.pool.xml${NC}"
  virsh pool-define ${VM_DEST_DIR}/${COURSE_NUM}/${VM_NAME}/${VM_NAME}.pool.xml 

  echo -e "${LTGREEN}COMMAND:${NC} virsh pool-autostart ${VM_NAME}${NC}"
  virsh pool-autostart ${VM_NAME}

  echo -e "${LTGREEN}COMMAND:${NC} virsh pool-start ${VM_NAME}${NC}"
  virsh pool-start ${VM_NAME}

  echo
}

main() {
  case ${1} in
    -h|-H|--help|help)
      usage
      exit
    ;;
  esac

  echo
  echo -e "${LTCYAN}###############################################################################${NC}"
  echo -e "${LTCYAN} Creating new VM named ${NC}${VM_NAME}${LTCYAN} in the lab environment ${NC}${COURSE_NUM}${LTCYAN} ...${NC}"
  echo -e "${LTCYAN}###############################################################################${NC}"
  echo

  create_new_vm_dirs ${*}
  copy_template_config_files ${*}
  update_vm_config_files ${*}
  update_custom_config ${*}
  create_vm_disk_image_files ${*}
  create_config_iso ${*}
  define_vm_and_storage_pool ${*}

  echo
  echo -e "${ORANGE}+----------------------------------------------------------------+${NC}"
  echo -e "${ORANGE}| NOTE: Remember to add this VM to the ${NC}LIBVIRT_VM_LIST${ORANGE} variable  |${NC}"
  echo -e "${ORANGE}|       in the ${NC}config/lab_env.cfg${ORANGE} file.                          |${NC}"
  echo -e "${ORANGE}+----------------------------------------------------------------+${NC}"
  echo
  echo -e "${LTCYAN}###############################################################################${NC}"
  echo
}

##############################################################################

main ${*}

