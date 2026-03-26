#!/bin/bash

DEF_LIBVIRT_VM_LIST="$(virsh list --all | grep -v Id | grep -v "^-----" | awk '{ print $2 }')"

if [ -e ./config/lab_env.cfg ]
then
  source ./config/lab_env.cfg
elif [ -e ../config/lab_env.cfg ]
then
  source ../config/lab_env.cfg
else
  LIBVIRT_VM_LIST="${DEF_LIBVIRT_VM_LIST}"
fi

########################################################################
#   Functions
########################################################################

stop_libvirt_vms() {
  for LIBVIRT_VM in ${LIBVIRT_VM_LIST}
  do
    echo "---------------------------------------------------------------------"
    echo "Stopping VM: ${LIBVIRT_VM}"
    echo "COMMAND: virsh shutdown ${LIBVIRT_VM}"
    virsh shutdown ${LIBVIRT_VM}
    echo -n "(waiting for VM to stop) ."

    while virsh list | grep -q ${LIBVIRT_VM}
    do
      echo -n "."
      ((++COUNT))
      sleep 1
    done
    echo "."
    echo
  done
}

show_libvirt_vm_status_all() {
  echo
  echo "COMMAND: virsh list" --all
  virsh list --all
  echo
}

main() {
  echo
  echo "Stopping VMs ..."
  echo
  stop_libvirt_vms
  show_libvirt_vm_status_all
}

########################################################################

main $*
