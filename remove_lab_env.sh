#!/bin/bash
# Version: 2.4.0
# Date: 2017-05-12

source config/include/colors.sh

DEFAULT_CONFIG="config/lab_env.cfg"

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

#== Source Global Variables ==

source config/include/global_vars.sh


##############################################################################
#                          Functions
##############################################################################

#== Source Common Functions ==

source config/include/common_functions.sh

#== Source Custom Functions ==

source config/include/remove_functions.sh

#== Source Custom Functions ==

if ! [ -z "${CUSTOM_FUNCTIONS_FILE}" ]
then
  if [ -e ${CUSTOM_FUNCTIONS_FILE} ]
  then
    echo -e "${LTBLUE}Loading Custom Functions File ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    source ${CUSTOM_FUNCTIONS_FILE}
  fi
fi

##############################################################################
#                          Main Code Body
##############################################################################

if [ -z ${INST_FILES_DIR} ]
then
  INST_FILES_DIR=$(dirname ${0})
fi
  
cd ${INST_FILES_DIR}


echo -e "${LTCYAN}===========================================================================${NC}"
echo -e "${LTCYAN}  ${COURSE_NAME} - Lab Environment Removal"
echo -e "${LTCYAN}===========================================================================${NC}"
echo
echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
echo -e "${LTCYAN}                      Removing Lab Environment Files"
echo -e "${LTCYAN}---------------------------------------------------------------------------${NC}"
echo

remove_libvirt_vms

remove_libvirt_networks

remove_new_bridges

remove_new_vlans

remove_new_nics

remove_vmware_vms

remove_vmware_networks

remove_iso_images

remove_cloud_images

remove_pdfs

remove_course_files

remove_ssh_keys

case ${UNINSTALL_VMWARE_ON_REMOVE}
in
  y|Y|yes|Yes)
    remove_vmware
  ;;
esac

#== Source Custom Commands ==

if ! [ -z "${CUSTOM_REMOVE_COMMANDS_FILE}" ]
then
  if [ -e ${CUSTOM_REMOVE_COMMANDS_FILE} ]
  then
    echo -e "${LTBLUE}Running Custom Remove Commands ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    source ${CUSTOM_REMOVE_COMMANDS_FILE}
  fi
fi

remove_lab_scripts

remove_removal_scripts

echo -e "${LTCYAN}===========================  Removal Complete  ===========================${NC}"
echo
exit 0
