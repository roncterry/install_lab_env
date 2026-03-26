#!/bin/bash

DEF_LIBVIRT_VM_LIST="$(virsh list --all | grep -v Id | grep -v "^-----" | awk '{ print $2 }')"
DEF_LIBVIRT_SERVICE_IP=""
DEF_LIBVIRT_SERVICE_CHECK_STRING="Found"

WAIT_TIME="120"

if [ -e ./config/lab_env.cfg ]
then
  source ./config/lab_env.cfg
elif [ -e ../config/lab_env.cfg ]
then
  source ../config/lab_env.cfg
else
  LIBVIRT_VM_LIST="${DEF_LIBVIRT_VM_LIST}"
  LIBVIRT_SERVICE_IP="${DEF_LIBVIRT_SERVICE_IP}"
  LIBVIRT_SERVICE_CHECK_STRING="${DEF_LIBVIRT_SERVICE_CHECK_STRING}"
fi

########################################################################
#   Functions
########################################################################

start_libvirt_vms() {
  for LIBVIRT_VM in ${LIBVIRT_VM_LIST}
  do
    echo "---------------------------------------------------------------------"
    echo "Starting VM: ${LIBVIRT_VM}"
    echo "COMMAND: virsh start ${LIBVIRT_VM}"
    virsh start ${LIBVIRT_VM}
    echo -n "(waiting ${WAIT_TIME} seconds) ."
    COUNT=1
    while [ "${COUNT}" -lt "${WAIT_TIME}" ]
    do
      echo -n "."
      ((++COUNT))
      sleep 1
    done
    echo "."
    unset COUNT
    echo
  done
  echo
}

show_libvirt_vm_status() {
  echo "COMMAND: virsh list"
  virsh list
  echo
}

wait_for_service() {
  echo "Waiting for service to become available:"
  until curl ${LIBVIRT_SERVICE_IP} 2> /dev/null | grep -q "${LIBVIRT_SERVICE_CHECK_STRING}"
  do
    echo -n "."
    sleep 1
  done
  echo "."
  echo

  echo "The VMs are ready for use"
  echo
}

main() {
  echo
  echo "Starting VMs ..."
  echo
  start_libvirt_vms

  show_libvirt_vm_status

  if ! [ -z ${LIBVIRT_SERVICE_IP} ]
  then
    wait_for_service
  fi
}

########################################################################

main $*
