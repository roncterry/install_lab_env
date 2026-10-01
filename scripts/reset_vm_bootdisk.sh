#!/bin/bash

IMAGE_BASE_DIR=/home/images

usage() {
  echo
  echo " USAGE: ${0} <vm_directory>"
  echo
}

if [ -z "${1}" ]
then
  echo
  echo "ERROR: You must supply a VM directory to operate on. Exiting."
  echo
  usage
  exit
else
  VM=${1}

  if ! [ -e "${VM}" ]
  then
    echo
    echo "ERROR: The supplied VM directory ${VM} does not appear to exist. Exiting."
    echo
    exit
  fi
fi

cd ${VM}

if [ -e "${VM}.cfg" ]
then
  source ${VM}.cfg
fi

COURSE_NUM="$(basename $(dirname $(dirname $(grep "\.qcow2" ${VM}.xml | cut -d \' -f 2 | head -n 1))))"

if ! [ -z "${BOOTDISK_IMAGE}" ]
then
  VM_BOOTDISK_IMAGE=${IMAGE_BASE_DIR}/${COURSE_NUM}/${BOOTDISK_IMAGE}

  if ! [ -e "${VM_BOOTDISK_IMAGE}" ]
  then
    echo
    echo "ERROR: The bootdisk defined in the ${VM}.cfg file does not appear to exist. Exiting."
    echo
    exit
  fi
else
  echo
  echo "No bootdisk specified. Resetting the existing disk."
  echo
fi

if ! [ -z "${BOOTDISK}" ]
then
  VM_BOOTDISK=${BOOTDISK}
else
  VM_BOOTDISK="$(basename $(grep "\.qcow2" ${VM}.xml | cut -d \' -f 2 | head -n 1))"
fi

if ! [ -z "${BOOTDISK_SIZE}" ]
then
  VM_BOOTDISK_SIZE=${BOOTDISK_SIZE}
else
 VM_BOOTDISK_SIZE_NUM=$(qemu-img info ${VM_BOOTDISK} | grep "virtual size" | head -n 1 | awk '{ print $3 }')
 VM_BOOTDISK_SIZE_UNIT=$(qemu-img info ${VM_BOOTDISK} | grep "virtual size" | head -n 1 | awk '{ print $4 }')
 VM_BOOTDISK_SIZE="${VM_BOOTDISK_SIZE_NUM}${VM_BOOTDISK_SIZE_UNIT:0:1}"
fi

echo
echo "-------------------------------------------------------------------------"
echo "      Resetting the bootdisk for VM: ${VM}"
echo "-------------------------------------------------------------------------"
echo
echo "COMMAND: sudo chown ${USER}: ${VM_BOOTDISK}"
sudo chown ${USER}: ${VM_BOOTDISK}
echo

if ! [ -z "${VM_BOOTDISK_IMAGE}" ]
then
  echo "COMMAND: cp ${VM_BOOTDISK_IMAGE} ${VM_BOOTDISK}"
  cp ${VM_BOOTDISK_IMAGE} ${VM_BOOTDISK}
  echo
fi

if ! [ -z "${VM_BOOTDISK_IMAGE}" ]
then
  echo "COMMAND: qemu-img resize ${VM_BOOTDISK} ${VM_BOOTDISK_SIZE}"
  qemu-img resize ${VM_BOOTDISK} ${VM_BOOTDISK_SIZE}
else
  echo "COMMAND: qemu-img create -f qcow2 ${VM_BOOTDISK} ${VM_BOOTDISK_SIZE}"
  qemu-img create -f qcow2 ${VM_BOOTDISK} ${VM_BOOTDISK_SIZE}
fi
echo

cd - > /dev/null 2>&1

