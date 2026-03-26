#!/bin/bash

DEF_LIBVIRT_REVERT_SNAPSHOT_NAME="snapshot1"
DEF_LIBVIRT_VM_LIST="$(virsh list --all | grep -v Id | grep -v "^-----" | awk '{ print $2 }')"

WAIT_TIME=5

if [ -e ./config/lab_env.cfg ]
then
  source ./config/lab_env.cfg
elif [ -e ../config/lab_env.cfg ]
then
  source ../config/lab_env.cfg
else
  LIBVIRT_VM_LIST="${DEF_LIBVIRT_VM_LIST}"
  LIBVIRT_REVERT_SNAPSHOT_NAME="${DEF_LIBVIRT_REVERT_SNAPSHOT_NAME}"
fi

########################################################################
#   Functions
########################################################################

revert_libvirt_vms() {
  for LIBVIRT_VM in ${LIBVIRT_VM_LIST}
  do
    echo "---------------------------------------------------------------------"
    echo "Reverting VM: ${LIBVIRT_VM}"
    echo "COMMAND: virsh snapshot-revert ${LIBVIRT_VM} ${LIBVIRT_REVERT_SNAPSHOT_NAME}"
    virsh snapshot-revert ${LIBVIRT_VM} ${SNAPSHOT_NAME}
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
}

show_libvirt_vm_status_all() {
  echo
  echo "COMMAND: virsh list --all"
  virsh list --all
  echo
}

main() {
  echo
  echo "Reverting VMs ..."
  echo
  revert_libvirt_vms
  show_libvirt_vm_status_all
}

########################################################################

main $*
