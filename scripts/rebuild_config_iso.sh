#!/bin/bash

CUSTOM_CONFIG_DIR=custom-config
CUSTOM_CONFIG_ISO=config.iso

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

case ${1} in
  cloud-init)
    CUSTOM_CONFIG_ISO_FORMAT=cloud-init
  ;;
  ignition)
    CUSTOM_CONFIG_ISO_FORMAT=ignition
  ;;
  combustion)
    CUSTOM_CONFIG_ISO_FORMAT=combustion
  ;;
  *)
    echo
    echo -e "${RED}ERROR: You must specify cloud-init, ignition or combustion.${NC}"
    echo
    echo "       Usage: ${0} cloud-init|ignition|combustion"
    echo
    exit
  ;;
esac

if ! [ -e "${CUSTOM_CONFIG_DIR}" ]
then
  echo
  echo -e "${RED}ERROR: You must run this from inside a directory that contains a ${CUSTOM_CONFIG_DIR} subdirectory (e.g. the VM's directory). Exiting.${NC}"
  echo
  exit
else
  echo
  echo -e "${LTCYAN}Rebuilding custom config ISO [${LTPURPLE}format:${ORANGE}${CUSTOM_CONFIG_ISO_FORMAT}${LTCYAN}] ...${NC}"
  echo
  echo -e "${LTGREEN}COMMAND:${NC} sudo chown ${USER}: ${CUSTOM_CONFIG_ISO}${NC}"
  sudo chown ${USER}: ${CUSTOM_CONFIG_ISO}
  echo

  case ${CUSTOM_CONFIG_ISO_FORMAT} in
    cloud-init)
      echo -e "${LTGREEN}COMMAND:${NC} mkisofs -o ${CUSTOM_CONFIG_ISO} -V cidata -J -rational-rock ${CUSTOM_CONFIG_DIR}${NC}"
      mkisofs -o ${CUSTOM_CONFIG_ISO} -V cidata -J -rational-rock ${CUSTOM_CONFIG_DIR}
    ;;
    ignition)
      echo -e "${LTGREEN}COMMAND:${NC} mkisofs -o ${CUSTOM_CONFIG_ISO} -V ignition -J -rational-rock ${CUSTOM_CONFIG_DIR}${NC}"
      mkisofs -o ${CUSTOM_CONFIG_ISO} -V ignition -J -rational-rock ${CUSTOM_CONFIG_DIR}
    ;;
    combustion)
      echo -e "${LTGREEN}COMMAND:${NC} mkisofs -o ${CUSTOM_CONFIG_ISO} -V combustion -J -rational-rock ${CUSTOM_CONFIG_DIR}${NC}"
      mkisofs -o ${CUSTOM_CONFIG_ISO} -V combustion -J -rational-rock ${CUSTOM_CONFIG_DIR}
    ;;
  esac
fi
echo
