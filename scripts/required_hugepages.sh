#!/bin/bash

# ==============================================================================
# TUNING & DYNAMIC HUGEPAGE ALLOCATION
# ==============================================================================

usage() {
  echo
  echo "USAGE: ${0} get|set <space_delimited_list_of_comma_delimited_vm_sets>"
  echo
  echo "Description:"
  echo "    -If the 'get' option is provided the max number of hugepages required will"
  echo "     be determined and displayed."
  echo "    -If the 'set' option is provided the max number of hugepages required will"
  echo "     be determined, displayed and set both in the live system and persistently."
  echo
  echo "Examples:"
  echo "    ${0} get \"node01,node02,node03 node04,node05,node06\""
  echo "    ${0} set \"node01,node02,node03 node04,node05,node06\""
  echo
  exit
}

# --- CONFIGURATION ---
if [ -z ${1} ]
then
  usage
else
  case ${1} in
    get|set)
      if [ -z ${2} ]
      then
        echo
        echo "ERROR: You must specify one or more sets of VMs. Exiting."
        usage
      else
        VM_SET_LIST="${2}"
      fi
    ;;
    *)
      echo
      echo "ERROR: You must speciify either 'get' or 'set' before the set lists. Exiting."
      echo
      usage
    ;;
  esac
fi


if sudo -V > /dev/null
then
  if [ "$(whoami)" = root ]
  then
    SUDO_CMD=
  else
    SUDO_CMD="sudo"
  fi
else
  if [ "$(whoami)" = root ]
  then
    SUDO_CMD=
  else
    echo
    echo -e "${LTRED}ERROR: You must be root (or have sudo installed) to run this command. Exiting ${NC}"
    echo
    exit 1
  fi
fi

get_required_hugepages() {
  MAX_TOTAL_HUGEPAGES=0
  SET_INDEX=1

  # Calculate the maximum HugePages needed by any single mutually-exclusive set
  for SET in ${VM_SET_LIST}; do

    echo   
    echo "SET ${SET_INDEX} VMs: ${SET}"
    SET_PAGES_NEEDED=0

    for VM in $(echo ${SET} | tr ',' ' '); do
      echo "  VM: ${VM}"
      # Determine if the VM uses hugepages
      if virsh dumpxml ${VM} | grep -q "hugepages"
      then
        if ! virsh dominfo "${VM}" >/dev/null 2>&1; then continue; fi
        VM_MEM_KIB=$(virsh dumpxml "${VM}" | xmlstarlet sel -t -v "string(/domain/memory)")
        echo "    VM Memory: ${VM_MEM_KIB}"
        
        # Calculate: (KiB / 2048) = Number of 2MB pages + 512 buffer
        VM_PAGES=$(( (VM_MEM_KIB / 2048) + 512 ))
        echo "    (Add 512K buffer)"
        echo "    VM Pages Needed: ${VM_PAGES}"
        SET_PAGES_NEEDED=$(( SET_PAGES_NEEDED + VM_PAGES ))
      else
        echo -e "${LTCYAN}    (no hugepages needed)${NC}"
      fi
    done
    
    echo "[ Set ${SET_INDEX} requires ${SET_PAGES_NEEDED} HugePages. ]"
    if [ "${SET_PAGES_NEEDED}" -gt "${MAX_TOTAL_HUGEPAGES}" ]; then
      MAX_TOTAL_HUGEPAGES=${SET_PAGES_NEEDED}
    fi
    ((SET_INDEX++))
  done

  echo
  echo "[ Maximum HugePages required across all sets: ${MAX_TOTAL_HUGEPAGES} ]"
}

set_required_hugepages() {
  # Write to persistent config and apply live
  echo "vm.nr_hugepages=${MAX_TOTAL_HUGEPAGES}" | ${SUDO_CMD} tee /etc/sysctl.d/99-hugepages.conf

  echo "COMMAND: ${SUDO_CMD} sysctl -p /etc/sysctl.d/99-hugepages.conf"
  ${SUDO_CMD} sysctl -p /etc/sysctl.d/99-hugepages.conf

  echo
  echo "[SUCCESS] HugePages are now persistent in /etc/sysctl.d/99-hugepages.conf"
}

main() {
  echo "==============================================="
  echo " 1. DYNAMIC HUGEPAGE CALCULATION & PERSISTENCE"
  echo "==============================================="

  case ${1} in
    get)
      get_required_hugepages
    ;;
    set)
      get_required_hugepages
      set_required_hugepages
    ;;
  esac
}

main
