#!/bin/bash

CUSTOM_CONFIG_DIR=custom-config
CUSTOM_CONFIG_ISO=config.iso

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
    echo "ERROR: You must specify cloud-init, ignition or combustion."
    echo
    echo "       Usage: ${0} cloud-init|ignition|combustion"
    echo
    exit
  ;;
esac

if ! [ -e "${CUSTOM_CONFIG_DIR}" ]
then
  echo
  echo "ERROR: You must run this from inside a directory that contains a ${CUSTOM_CONFIG_DIR} subdirectory (e.g. the VM's directory). Exiting."
  echo
  exit
else
  echo
  echo "Rebuilding custom config ISO [format:${CUSTOM_CONFIG_ISO_FORMAT}] ..."
  echo "COMMAND: sudo chown ${USER}: ${CUSTOM_CONFIG_ISO}"
  sudo chown ${USER}: ${CUSTOM_CONFIG_ISO}
  case ${CUSTOM_CONFIG_ISO_FORMAT} in
    cloud-init)
      echo "COMMAND: mkisofs -o ${CUSTOM_CONFIG_ISO} -V cidata -J -rational-rock ${CUSTOM_CONFIG_DIR}"
      mkisofs -o ${CUSTOM_CONFIG_ISO} -V cidata -J -rational-rock ${CUSTOM_CONFIG_DIR}
    ;;
    ignition)
      echo "COMMAND: mkisofs -o ${CUSTOM_CONFIG_ISO} -V ignition -J -rational-rock ${CUSTOM_CONFIG_DIR}"
      mkisofs -o ${CUSTOM_CONFIG_ISO} -V ignition -J -rational-rock ${CUSTOM_CONFIG_DIR}
    ;;
    combustion)
      echo "COMMAND: mkisofs -o ${CUSTOM_CONFIG_ISO} -V combustion -J -rational-rock ${CUSTOM_CONFIG_DIR}"
      mkisofs -o ${CUSTOM_CONFIG_ISO} -V combustion -J -rational-rock ${CUSTOM_CONFIG_DIR}
    ;;
  esac
fi
echo
