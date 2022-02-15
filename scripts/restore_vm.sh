#!/bin/bash

# version: 1.0.2
# date: 2022-02-15

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

run () {
  echo -e "${LTGREEN}COMMAND: ${NC}$*${NC}"
  "$@"
}

usage() {
  echo
  echo -e "${LTGREEN}USAGE:${NC} $(basename "${0}") <vm_archive> [extract_only]${NC}"
  echo -e "${LTGREEN}    or${NC} $(basename "${0}") <vm_dir>${NC}"
  echo
  echo -e "${LTGREEN}DESCRIPTION:${NC}"
  echo "If a VM archive is specificed, the archive will be extracted and"
  echo "the VM will be registered with Libvirt with all configuration"
  echo "updates applied."
  echo "If the \"extract_only\" option is supplied it will not be registerd with"
  echo "Libvirt and only the configuration updates will be applied that don't"
  echo "require the VM to be registered with Libvirt."
  echo
  echo "If a VM directory is specified, the VM will just be registered with"
  echo "Libvirt and only the configuration updates that require being registered"
  echo "with Libvirt will be applied."
  echo
}

##############################################################################
#                          Global Variables
##############################################################################

if [ -z ${1} ]
then
    echo
    echo -e "${LTRED}ERROR: You must provide the VM to restore.${NC}"
    echo
    usage
    exit
    exit
else
  if echo $* | grep -q "help"
  then
    echo
    usage
    echo
    exit
  else
    VM_TO_RESTORE=${1}
  fi
fi

if echo $* | grep -q "extract_only"
then
  EXTRACT_ONLY=Y
else
  EXTRACT_ONLY=N
fi

##############################################################################
#                          Functions
##############################################################################

get_archive_type() {
# Pass in:
#  - an archive file with or without file extenstion
# and 
#  - the type of archive will be determined by either extension or use of the command: file
#  - the type of archive will be returned via echo

  local ARCHIVE_FILE=${1}

  if ls "${ARCHIVE_FILE}".tgz > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=tgz
  elif ls "${ARCHIVE_FILE}".tar.gz > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=targz
  elif ls "${ARCHIVE_FILE}".tar.bz2 > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=tarbz2
  elif ls "${ARCHIVE_FILE}".tbz > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=tbz
  elif ls "${ARCHIVE_FILE}".tar.xz > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=tarxz
  elif ls "${ARCHIVE_FILE}".txz > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=txz
  elif ls "${ARCHIVE_FILE}".7z* > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=7z
  elif ls "${ARCHIVE_FILE}".tar.7z* > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=tar7z
  elif ls "${ARCHIVE_FILE}".zip > /dev/null 2>&1
  then
    local ARCHIVE_TYPE=zip
  else
    case $(file -b "${ARCHIVE_FILE}" | cut -d \  -f 1) in
      gzip)
        local ARCHIVE_TYPE=GZIP
      ;;
      bzip2)
        local ARCHIVE_TYPE=BZIP2
      ;;
      7-zip)
        local ARCHIVE_TYPE=7ZIP
      ;;
      Zip)
        local ARCHIVE_TYPE=ZIP
      ;;
    esac
  fi
  
  echo ${ARCHIVE_TYPE}
}

extract_archive() {
# Pass in:
#  - an archive file with or without file extenstion
#  - the directory to extract it into
#  - [optionally] the archive type (as determinted by the function: get_archive_type)
# and the archive will be extracted into the directory

  local ARCHIVE_FILE=$1
  local ARCHIVE_DEST_DIR=$2
  local ARCHIVE_TYPE=$3

  case ${ARCHIVE_TYPE} in
    tgz)
      run tar xzvf "${ARCHIVE_FILE}".tgz -C ${ARCHIVE_DEST_DIR}
    ;;
    targz)
      run tar xzvf "${ARCHIVE_FILE}".tar.gz -C ${ARCHIVE_DEST_DIR}
    ;;
    tbz)
      run tar xjvf "${ARCHIVE_FILE}".tbz -C ${ARCHIVE_DEST_DIR}
    ;;
    tarbz2)
      run tar xjvf "${ARCHIVE_FILE}".tar.bz2 -C ${ARCHIVE_DEST_DIR}
    ;;
    txz)
      run tar xJvf "${ARCHIVE_FILE}".txz -C ${ARCHIVE_DEST_DIR}
    ;;
    tarxz)
      run tar xJvf "${ARCHIVE_FILE}".tar.xz -C ${ARCHIVE_DEST_DIR}
    ;;
    7z)
      if [ -e "${ARCHIVE_FILE}".7z ]
      then
        local OLD_PWD="${PWD}"
        run cd "${ARCHIVE_DEST_DIR}"

        run 7z x -mmt=on "${OLD_PWD}/${ARCHIVE_FILE}".7z

        run cd -
      elif [ -e "${ARCHIVE_FILE}".7z.001 ]
      then
        local OLD_PWD="${PWD}"
        run cd "${ARCHIVE_DEST_DIR}"

        run 7z x -mmt=on "${OLD_PWD}/${ARCHIVE_FILE}".7z.001

        run cd -
      fi
    ;;
    tar7z)
      if [ -e "${ARCHIVE_FILE}".tar.7z ]
      then
        local OLD_PWD="${PWD}"
        run cd "${ARCHIVE_DEST_DIR}"

        run 7z x -mmt=on -so "${OLD_PWD}/${ARCHIVE_FILE}".tar.7z | tar xf -

        run cd -
      elif [ -e "${ARCHIVE_FILE}".tar.7z.001 ]
      then
        local OLD_PWD="${PWD}"
        run cd "${ARCHIVE_DEST_DIR}"

        run 7z x -mmt=on -so "${OLD_PWD}/${ARCHIVE_FILE}".tar.7z.001 | tar xf -

        run cd -
      fi
    ;;
    zip)
      local OLD_PWD="${PWD}"
      run cd "${ARCHIVE_DEST_DIR}"

      run unzip "${OLD_PWD}/${ARCHIVE_FILE}".zip

      run cd -
    ;;
    GZIP)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.gz$" || echo "${ARCHIVE_FILE}" | grep -q ".tgz$"
      then
        run tar xzvf "${ARCHIVE_FILE}" -C "${ARCHIVE_DEST_DIR}"
      fi
    ;;
    BZIP2)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.bz2$" || echo "${ARCHIVE_FILE}" | grep -q ".tbz$"
      then
        run tar xjvf "${ARCHIVE_FILE}" -C "${ARCHIVE_DEST_DIR}"
      fi
    ;;
    7ZIP)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.7z.001$" || echo "${ARCHIVE_FILE}" | grep -q ".tar.7z$"
      then
        local OLD_PWD="${PWD}"
        run cd "${ARCHIVE_DEST_DIR}"

        run 7z x -mmt=on -so "${OLD_PWD}/${ARCHIVE_FILE}" | tar xf -

        run cd -
      elif  echo "${ARCHIVE_FILE}" | grep -q ".7z.001$" || echo "${ARCHIVE_FILE}" | grep -q ".7z?"
      then
        local OLD_PWD="${PWD}"
        run cd "${ARCHIVE_DEST_DIR}"

        run 7z x -mmt=on "${OLD_PWD}/${ARCHIVE_FILE}"

        run cd -
      fi
    ;;
    ZIP)
      local OLD_PWD="${PWD}"
      run cd "${ARCHIVE_DEST_DIR}"

      run unzip "${OLD_PWD}/${ARCHIVE_FILE}"

      run cd -
    ;;
  esac
}

extract_archive_sudo() {
# Pass in:
#  - an archive file with or without file extenstion
#  - the directory to extract it into
#  - [optionally] the archive type (as determinted by the function: get_archive_type)
# and the archive will be extracted into the directory using the command: sudo

  local ARCHIVE_FILE=$1
  local ARCHIVE_DEST_DIR=$2
  local ARCHIVE_TYPE=$3

  case ${ARCHIVE_TYPE} in
    tgz)
      run sudo tar xzvf "${ARCHIVE_FILE}" -C ${ARCHIVE_DEST_DIR}
    ;;
    targz)
      run sudo tar xzvf "${ARCHIVE_FILE}".tar.gz -C ${ARCHIVE_DEST_DIR}
    ;;
    tbz)
      run sudo tar xjvf "${ARCHIVE_FILE}" -C ${ARCHIVE_DEST_DIR}
    ;;
    tarbz2)
      run sudo tar xjvf "${ARCHIVE_FILE}".tar.bz2 -C ${ARCHIVE_DEST_DIR}
    ;;
    7z)
      if [ -e "${ARCHIVE_FILE}".7z ]
      then
        local OLD_PWD="${PWD}"
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x "${OLD_PWD}/${ARCHIVE_FILE}".7z

        run sudo cd -
      elif [ -e "${ARCHIVE_FILE}".7z.001 ]
      then
        local OLD_PWD="${PWD}"
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x "${OLD_PWD}/${ARCHIVE_FILE}".7z.001

        run sudo cd -
      fi
    ;;
    tar7z)
      if [ -e "${ARCHIVE_FILE}".tar.7z ]
      then
        local OLD_PWD="${PWD}"
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x -so "${OLD_PWD}/${ARCHIVE_FILE}".tar.7z | tar xf -

        run sudo cd -
      elif [ -e "${ARCHIVE_FILE}".tar.7z.001 ]
      then
        local OLD_PWD="${PWD}"
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x -so "${OLD_PWD}/${ARCHIVE_FILE}".tar.7z.001 | tar xf -

        run sudo cd -
      fi
    ;;
    zip)
      local OLD_PWD="${PWD}"
      run sudo cd ${ARCHIVE_DEST_DIR}

      run sudo unzip "${OLD_PWD}/${ARCHIVE_FILE}".zip

      run sudo cd -
    ;;
    GZIP)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.gz$" || echo "${ARCHIVE_FILE}" | grep -q ".tgz$"
      then
        run sudo tar xzvf "${ARCHIVE_FILE}" -C ${ARCHIVE_DEST_DIR}
      fi
    ;;
    BZIP2)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.bz2$" || echo "${ARCHIVE_FILE}" | grep -q ".tbz$"
      then
        run sudo tar xjvf "${ARCHIVE_FILE}" -C ${ARCHIVE_DEST_DIR}
      fi
    ;;
    7ZIP)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.7z.001$" || echo "${ARCHIVE_FILE}" | grep -q ".tar.7z$"
      then
        local OLD_PWD="${PWD}"
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x -so "${OLD_PWD}/${ARCHIVE_FILE}" | tar xf -

        run sudo cd -
      elif  echo "${ARCHIVE_FILE}" | grep -q ".7z.001$" || echo "${ARCHIVE_FILE}" | grep -q ".7z?"
      then
        local OLD_PWD="${PWD}"
        run sudo cd ${ARCHIVE_DEST_DIR}

        run sudo 7z x "${OLD_PWD}/${ARCHIVE_FILE}"

        run sudo cd -
      fi
    ;;
    ZIP)
      local OLD_PWD="${PWD}"
      run sudo cd ${ARCHIVE_DEST_DIR}

      run sudo unzip "${OLD_PWD}/${ARCHIVE_FILE}"

      run sudo cd -
    ;;
  esac
}

list_archive() {
# Pass in:
#  - an archive file with or without file extenstion
#  - [optionally] the archive type (as determinted by the function: get_archive_type)
# and the contents of the archive will be returned

  local ARCHIVE_FILE=$1
  local ARCHIVE_TYPE=$2

  case ${ARCHIVE_TYPE} in
    tgz)
      tar -tvf "${ARCHIVE_FILE}".tgz  | awk '{ print $6 }'
    ;;
    targz)
      tar -tvf "${ARCHIVE_FILE}".tar.gz  | awk '{ print $6 }'
    ;;
    tbz)
      tar -tvf "${ARCHIVE_FILE}".tbz  | awk '{ print $6 }'
    ;;
    tarbz2)
      tar -tvf "${ARCHIVE_FILE}".tar.bz2  | awk '{ print $6 }'
    ;;
    txz)
      tar -tvf "${ARCHIVE_FILE}".txz  | awk '{ print $6 }'
    ;;
    tarxz)
      tar -tvf "${ARCHIVE_FILE}".tar.xz  | awk '{ print $6 }'
    ;;
    7z)
      if [ -e "${ARCHIVE_FILE}" ]
      then
        #7z l "${ARCHIVE_FILE}" | awk '/--------/{f=0} f; /--------/{f=1}' | grep -v "^ ." | awk '{ print $6 }' | sort
        #7z l "${ARCHIVE_FILE}" | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "${ARCHIVE_FILE}/.*" | sort
        7z l "${ARCHIVE_FILE}" | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "$(basename "${ARCHIVE_FILE}" | sed 's/.7z//g')/.*" | sort
      elif [ -e "${ARCHIVE_FILE}" ]
      then
        #7z l "${ARCHIVE_FILE}".7z | awk '/--------/{f=0} f; /--------/{f=1}' | grep -v "^ ." | awk '{ print $6 }' | sort
        #7z l "${ARCHIVE_FILE}".7z | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "${ARCHIVE_FILE}/.*" | sort
        7z l "${ARCHIVE_FILE}".7z | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "$(basename "${ARCHIVE_FILE}" | sed 's/.7z//g')/.*" | sort
      elif [ -e "${ARCHIVE_FILE}".7z.001 ]
      then
        #7z l "${ARCHIVE_FILE}".7z.001 | awk '/--------/{f=0} f; /--------/{f=1}' | grep -v "^ ." | awk '{ print $6 }' | sort
        #7z l "${ARCHIVE_FILE}".7z.001 | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "${ARCHIVE_FILE}/.*" | sort
        7z l "${ARCHIVE_FILE}".7z.001 | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "$(basename "${ARCHIVE_FILE}" | sed 's/.7z.001//g')/.*" | sort
      fi
    ;;
    #tar7z)
    #  if [ -e "${ARCHIVE_FILE}".tar.7z ]
    #  then
    #    local OLD_PWD="${PWD}"
    #    run cd ${ARCHIVE_DEST_DIR}

    #    run 7z x -mmt=on -so "${OLD_PWD}/${ARCHIVE_FILE}".tar.7z | tar xf -

    #    run cd -
    #  elif [ -e "${ARCHIVE_FILE}".tar.7z.001 ]
    #  then
    #    local OLD_PWD="${PWD}"
    #    run cd ${ARCHIVE_DEST_DIR}

    #    run 7z x -mmt=on -so "${OLD_PWD}/${ARCHIVE_FILE}".tar.7z.001 | tar xf -

    #    run cd -
    #  fi
    #;;
    zip)
      unzip -l "${ARCHIVE_FILE}".zip | awk '/---------/{f=0} f; /---------/{f=1}' | awk '{ print $4 }'
    ;;
    GZIP)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.gz$" || echo "${ARCHIVE_FILE}" | grep -q ".tgz$"
      then
        tar -tvf "${ARCHIVE_FILE}"  | awk '{ print $6 }'
      fi
    ;;
    BZIP2)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.bz2$" || echo "${ARCHIVE_FILE}" | grep -q ".tbz$"
      then
        tar -tvf "${ARCHIVE_FILE}"  | awk '{ print $6 }'
      fi
    ;;
    7ZIP)
      if echo "${ARCHIVE_FILE}" | grep -q ".tar.7z$"
      then
        7z l "${ARCHIVE_FILE}" | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "$(basename "${ARCHIVE_FILE}" | sed 's/.tar.7z//g')/.*" | sort
      elif echo "${ARCHIVE_FILE}" | grep -q ".tar.7z.001$" 
      then
        7z l "${ARCHIVE_FILE}" | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "$(basename "${ARCHIVE_FILE}" | sed 's/.tar.7z.001//g')/.*" | sort
      elif  echo "${ARCHIVE_FILE}" | grep -q ".7z?"
      then
        7z l "${ARCHIVE_FILE}" | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "$(basename "${ARCHIVE_FILE}" | sed 's/.7z//g')/.*" | sort
      elif  echo "${ARCHIVE_FILE}" | grep -q ".7z.001$" 
      then
        7z l "${ARCHIVE_FILE}" | awk '/--------/{f=0} f; /--------/{f=1}' | grep -o "$(basename "${ARCHIVE_FILE}" | sed 's/.7z.001//g')/.*" | sort
      fi
    ;;
    ZIP)
      unzip -l "${ARCHIVE_FILE}" | awk '/---------/{f=0} f; /---------/{f=1}' | awk '{ print $4 }'
    ;;
  esac
}

get_libvirt_capabilities() {
  AVAILABLE_440FX_VERS=$(virsh capabilities | grep -Eo "pc-i440fx-[0-9]+\.[0-9]+" | cut -d - -f 3 | sort | uniq)
  HIGHEST_440FX_VER=$(echo ${AVAILABLE_440FX_VERS} | cut -d " " -f $(echo ${AVAILABLE_440FX_VERS} | wc -w))
  AVAILABLE_Q35_VERS=$(virsh capabilities | grep -Eo "pc-q35-[0-9]+\.[0-9]+" | cut -d - -f 3 | sort | uniq)
  HIGHEST_Q35_VER=$(echo ${AVAILABLE_Q35_VERS} | cut -d " " -f $(echo ${AVAILABLE_Q35_VERS} | wc -w))
  AVAILABLE_PC_VERS=$(virsh capabilities | grep -Eo "pc-[0-9]+\.[0-9]+" | cut -d - -f 2 | sort | uniq)
  HIGHEST_PC_VER=$(echo ${AVAILABLE_PC_VERS} | cut -d " " -f $(echo ${AVAILABLE_PC_VERS} | wc -w))
  ##echo "AVAILABLE_440FX_VERS=${AVAILABLE_440FX_VERS}"
  #echo "HIGHEST_440FX_VER=${HIGHEST_440FX_VER}"
  ##echo "AVAILABLE_Q35_VERS=${AVAILABLE_Q35_VERS}"
  #echo "HIGHEST_Q35_VER=${HIGHEST_Q35_VER}"
  ##echo "AVAILABLE_PC_VERS=${AVAILABLE_PC_VERS}"
  #echo "HIGHEST_PC_VER=${HIGHEST_PC_VER}"
  #read
}

edit_libvirt_domxml() {
    get_libvirt_capabilities

    case ${MULTI_LAB_MACHINE}
    in
      y|Y|yes|Yes|YES|t|T|true|True|TRUE)
        local VM_CONFIG="${VM}-${MULTI_LM_EXT}.xml"
      ;;
      *)
        local VM_CONFIG="${VM}.xml"
      ;;
    esac

    if [ -e "${VM}"/"${VM_CONFIG}" ]
    then
      echo -e "${LTBLUE}Updating VM configuration file ...${NC}"

      #--- cpu ---
      case ${LIBVIRT_SET_CPU_TO_HYPERVISOR_DEFUALT} in
        y|Y|yes|Yes)
          echo -e "  ${LTCYAN}Changing CPU to Hypervisor Default ...${NC}"

          ### This deletes the <cpu> line
          run sed -i -e '/<cpu/,/cpu>/ d' "${VM}"/"${VM_CONFIG}"

          ### This changes the CPU to model='host-passthrough'
          #run sed -i -e "s/\( *\)<cpu.*/\1<cpu mode='host-passthrough' check='none' migratable='on' \/>/" "${VM}"/"${VM_CONFIG}"

          ### This changes the CPU line to model='host-model' and adds the feature name='pcid' [ONLY WORKS ON INTEL CPUS]
          #run sed -i -e "s/\( *\)<cpu.*/\1<cpu mode='host-model' check='partial'>/" "${VM}"/"${VM_CONFIG}"
          #if ! grep -q "^ *<feature policy=.*require.* name=.*pcid.*" "${VM}"/"${VM_CONFIG}"
          #then
          #  run sed -i "/^ .*<cpu/a \ \ \ \ <feature policy='require' name='pcid'\/>" "${VM}"/"${VM_CONFIG}"
          #fi
          #if ! grep -q "^ *<\/cpu>" "${VM}"/"${VM_CONFIG}"
          #then
          #  run sed -i "/^ .*<feature policy='require' name='pcid'/a \ \ <\/cpu>" "${VM}"/"${VM_CONFIG}"
          #fi
          echo
        ;;
        *)
          echo -e "  ${LTCYAN}Keeping existing CPU type.${NC}"
          echo
        ;;
      esac
 
      #--- features ---
      QEMUKVM_VER=$(qemu-kvm -version | cut -d ' ' -f 4 | sed 's/,//g')
      QEMUKVM_VER_MAJ=$(echo ${QEMUKVM_VER} | cut -d . -f 1)
      QEMUKVM_VER_MIN=$(echo ${QEMUKVM_VER} | cut -d . -f 2)
      QEMUKVM_VER_REL=$(echo ${QEMUKVM_VER} | cut -d . -f 3)

      # check for vmport support
      if [ "${QEMUKVM_VER_MAJ}" -gt 2 ]
      then
        local VMPORT=Y
      elif [ "${QEMUKVM_VER_MAJ}" -eq 2 ]
      then
        if [ "${QEMUKVM_VER_MIN}" -gt 3 ]
        then
          local VMPORT=Y
        elif [ "${QEMUKVM_VER_MIN}" -eq 3 ]
        then
          if [ "${QEMUKVM_VER_REL}" -ge 0 ]
          then
            local VMPORT=Y
          else
            local VMPORT=N
          fi
        else
          local VMPORT=N
        fi
      else
        local VMPORT=N
      fi
 
      case ${VMPORT} in
        Y)
          echo -e "  ${LTCYAN}QEMU version ${NC}${QEMUKVM_VER}${LTCYAN} supports vmport parameter, not removing it.${NC}"
          echo
        ;;
        N)
          echo -e "  ${LTCYAN}Removing vmport parameter ...${NC}"
          run sed -i "/vmport/d"  "${VM}"/"${VM_CONFIG}"
          echo
        ;;
      esac
 
      #--- machine type ---
      local MACHINE_TYPE_STRING=$(grep "machine=" "${VM}"/"${VM_CONFIG}" | awk '{ print $3 }' | cut -d \> -f 1 | cut -d \' -f 2)
      local MACHINE_TYPE=$(echo ${MACHINE_TYPE_STRING} | cut -d \- -f 2)
      local MACHINE_TYPE_VER=$(echo ${MACHINE_TYPE_STRING} | cut -d \- -f 3)
      
      #echo "KVM_SET_MACHINE_TYPE_TO_HIGHEST_SUPPORTED=${KVM_SET_MACHINE_TYPE_TO_HIGHEST_SUPPORTED}"
      #echo "MACHINE_TYPE_STRING=${MACHINE_TYPE_STRING}"
      #echo "MACHINE_TYPE=${MACHINE_TYPE}"
      #echo "MACHINE_TYPE_VER=${MACHINE_TYPE_VER}"
      #read;

      case ${KVM_SET_MACHINE_TYPE_TO_HIGHEST_SUPPORTED} in
        Y|y)
          case ${MACHINE_TYPE} in
            i440fx)
              echo -e "  ${LTCYAN}Changing machine type to highest supported version ...${NC}"
              run sed -i "s/pc-i440fx-.../pc-i440fx-${HIGHEST_440FX_VER}/"  "${VM}"/"${VM_CONFIG}"
            ;;
            q35)
              echo -e "  ${LTCYAN}Changing machine type to highest supported version ...${NC}"
              run sed -i "s/pc-q35-.../pc-q35-${HIGHEST_Q35_VER}/"  "${VM}"/"${VM_CONFIG}"
            ;;
          esac
        ;;
        *) 
          case ${MACHINE_TYPE} in
            i440fx)
              if ! echo ${AVAILABLE_440FX_VERS} | grep -q ${MACHINE_TYPE_VER}
              then
                echo -e "  ${LTCYAN}Changing machine type to highest supported version ...${NC}"
                run sed -i "s/pc-i440fx-.../pc-i440fx-${HIGHEST_440FX_VER}/"  "${VM}"/"${VM_CONFIG}"
                echo
              else
                echo -e "  ${LTCYAN}Machine type is a supported version: ${NC}${MACHINE_TYPE_VER} ${NC}"
                echo
              fi
            ;;
            q35)
              if ! echo ${AVAILABLE_Q35_VERS} | grep -q ${MACHINE_TYPE_VER}
              then
                echo -e "  ${LTCYAN}Changing machine type to highest supported version ...${NC}"
                run sed -i "s/pc-q35-.../pc-q35-${HIGHEST_Q35_VER}/"  "${VM}"/"${VM_CONFIG}"
                echo
              else
                echo -e "  ${LTCYAN}Machine type is a supported version: ${NC}${MACHINE_TYPE_VER} ${NC}"
                echo
              fi
            ;;
          esac
        ;;
      esac
 
      #--- network to bridge ---
      for BRIDGE in ${BRIDGE_LIST}
      do
        local BRIDGE_NAME="$(echo ${BRIDGE} | cut -d , -f 1)"
        if grep -q "network=${BRIDGE_NAME}" "${VM}"/"${VM_CONFIG}"
        then
          echo -e "  ${LTCYAN}Changing network= to bridge= ...${NC}"
          run sed -i "s/network=${BRIDGE_NAME}/bridge=${BRIDGE_NAME}/g" "${VM}"/"${VM_CONFIG}"
          echo
        fi
      done
 
      echo
    fi
}

restore_vm_tpm() {
# Pass in:
#  - Name of VM that is currently registered with Libvirt
# and
#  - The TPM files in the VM's directory will be copied to the 
#    default Libvirt location

  if [ -z ${1} ]
  then
    echo -e "${RED}ERROR: You must supply a VM name.${NC}"
    echo 
    echo "  USAGE: restore_vm_tpm <vm_name>"
  else
    local VM_NAME=${1}
  fi

  local VM_UUID="$(virsh dumpxml ${VM_NAME} | grep uuid | cut -d \> -f 2 | cut -d \< -f 1)"
  local TPM_DIR="/var/lib/libvirt/swtpm/${VM_UUID}"

  echo -e "${LTBLUE}Restoring TPM ...${NC}"

  run sudo mkdir -p ${TPM_DIR}
  run sudo chmod 711 ${TPM_DIR}

  if [ -e ${VM_NAME}/tpm/tpm1.2 ]
  then
    echo -e "${LTCYAN}(TPM version 1.2 found${NC}"
    run sudo cp -R ${VM_NAME}/tpm/tpm1.2 ${TPM_DIR}/
    run sudo chmod 600 ${TPM_DIR}/tpm1.2/tpm-00.permall
    run sudo chmod 700 ${TPM_DIR}/tpm1.2
    run sudo chown -R tss.tss ${TPM_DIR}/tpm1.2
  fi
  if [ -e ${VM_NAME}/tpm/tpm2 ]
  then
    echo -e "${LTCYAN}(TPM version 2 found${NC}"
    run sudo cp -R ${VM_NAME}/tpm/tpm2 ${TPM_DIR}/
    run sudo chmod 600 ${TPM_DIR}/tpm2/tpm2-00.permall
    run sudo chmod 700 ${TPM_DIR}/tpm2
    run sudo chown -R tss.tss ${TPM_DIR}/tpm2
  fi
}

update_vm_snapshot_uuid() {
# Pass in:
#  - Name of VM that is currently registered with Libvirt
# and
#  - The UUID of the VM will be updated in the XML shapshot definition files 
#    in the VM's directory

  if [ -z "${1}" ]
  then
    echo -e "${RED}ERROR: You must supply a VM name.${NC}"
    echo 
    echo "  USAGE: update_snapshot_uuid <vm_name>"
  else
    local VM_NAME=${1}
  fi

  if [ -e ${VM_NAME}/snapshots/ ]
  then
    echo -e "${LTBLUE}Updating VM UUID in snapshot XML files ...${NC}"
    for SNAPSHOT_FILE in $(ls ${VM_NAME}/snapshots/) 
    do 
      VM_UUID=$(virsh dumpxml ${VM_NAME} | grep uuid | head -1 | cut -d ">" -f 2 | cut -d "<" -f 1)
      run sed -i "s+\( .\)<uuid>.*+\1<uuid>${VM_UUID}</uuid>+g" ${VM_NAME}/snapshots/${SNAPSHOT_FILE}
    done
  #else
  #  echo
  #  echo -e "${LTCYAN} (No snapshot files to update)"
  fi
  echo
}

update_vm_snapshot_disk_paths() {
# Pass in:
#  - Name of VM that is currently registered with Libvirt
# and
#  - The disk paths of the VM will be updated in the XML shapshot definition
#    files in the VM's directory

  if [ -z "${1}" ]
  then
    echo -e "${RED}ERROR: You must supply a VM name.${NC}"
    echo 
    echo "  USAGE: update_snapshot_disk_paths <vm_name>"
  else
    local VM_NAME=${1}
  fi

  for SNAPSHOT_FILE in $(ls ${VM_NAME}/snapshotsls/*.xml)
  do
    local SNAPSHOT_DISK_LIST=$(grep "<source file=.*" ${VM_NAME}/snapshots/${SNAPSHOT_FILE} | cut -d \' -f 2)
    for SNAPSHOT_DISK in ${SNAPSHOT_DISK_LIST}
    do
      run sed -i "s+\(.*<source file=\)'.*${SNAPSHOT_DISK}'\(.*\)+\1'${VM_NAME}/$(basename ${SNAPSHOT_DISK})'\2+" ${VM_NAME}/snapshots/${SNAPSHOT_FILE}
    done
  done
  echo
}

restore_vm_snapshots() {
# Pass in:
#  - Name of VM that is currently registered with Libvirt
# and
#  - Snapshots of a VM will be restored using the the XML shapshot definition
#    files in the VM's directory

  if [ -z "${1}" ]
  then
    echo -e "${RED}ERROR: You must supply a VM name.${NC}"
    echo 
    echo "  USAGE: restore_vm_snapshots <vm_name>"
  else
    local VM_NAME=${1}
  fi

  if [ -e ${VM_NAME}/snapshots/ ]
  then
    echo -e "${LTBLUE}Restoring snapshots for VM ...${NC}"
    for SNAP_FILE in $(ls ${VM_NAME}/snapshots/)
    do
      run virsh snapshot-create ${VM_NAME} ${VM_NAME}/snapshots/${SNAP_FILE} --redefine
    done
  fi
  echo
}

check_type_of_provided_vm() {
  echo -e "${LTBLUE}Checking type of VM provided ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  if ! [ -e ${VM_ARCHIVE} ]
  then
    echo
    echo -e "${LTRED}ERROR: The provided VM (${LTGREEN}${VM_ARCHIVE}${LTRED}) doesn't exist.${NC}"
    echo
    echo -e "${LTRED}Exiting ...${NC}"
    echo
    exit 1
  else
    if [ -f ${VM_TO_RESTORE} ]
    then
      VM_TYPE=archive
      VM_ARCHIVE=${VM_TO_RESTORE}
      ARCHIVE_TYPE=$(get_archive_type ${VM_ARCHIVE})
      #local VM_FILE=$(list_archive "${VM_ARCHIVE}" ${ARCHIVE_TYPE} | head -n 1)
      #VM=$(dirname ${VM_FILE})
      VM=$(dirname $(list_archive "${VM_ARCHIVE}" ${ARCHIVE_TYPE} | head -n 1))
    fi
    if [ -d ${VM_TO_RESTORE} ]
    then
      VM_TYPE=directory
      VM=${VM_TO_RESTORE} 
    fi
  fi
  echo -e "${LTCYAN}  VM_TYPE=${VM_TYPE}${NC}"
  case ${VM_TYPE} in
    archive)
      echo -e "${LTCYAN}  VM_ARCHIVE=${VM_ARCHIVE}${NC}"
    ;;
  esac
  echo -e "${LTCYAN}  VM=${VM}${NC}"
  echo
}

extract_update_libvirt_vm() {
  echo -e "${LTBLUE}Extracting VM: ${GREEN} ${VM} ...${NC}"
  echo -e "${LTBLUE}---------------------------------------------------------${NC}"

  local ARCHIVE_TYPE=$(get_archive_type "${VM_ARCHIVE}")
  local VM=$(dirname $(list_archive "${VM_ARCHIVE}" ${ARCHIVE_TYPE} | head -n 1))

  extract_archive "${VM_ARCHIVE}" ./ ${ARCHIVE_TYPE}

  #--test--------------------------------------------------
  local SRC_VMFILES=$(list_archive "${VM_ARCHIVE}" ${ARCHIVE_TYPE})
  local DST_VMFILES=$(ls ${VM})

  local COUNT=1
  for SRC_VMFILE in ${SRC_VMFILES}
  do
    ((COUNT++))
    if ! echo ${DST_VMFILES} | grep -q $(echo ${SRC_VMFILE} | cut -d \/ -f 2)
    then
      IS_ERROR=Y
      FAILED_TASKS="${FAILED_TASKS},install_functions.extract_register_libvirt_vms.extract_vm:${VM}:${SRC_VMFILE}"
    fi 
  done
  unset COUNT
  #--------------------------------------------------------

  edit_libvirt_domxml

  if [ -e "${VM}"/tpm ]
  then
    restore_vm_tpm ${VM}
  fi
}

register_libvirt_vm() {
  local ARCHIVE_TYPE=$(get_archive_type "${VM_ARCHIVE}")
  #local VM=$(dirname $(list_archive "${VM_ARCHIVE}" ${ARCHIVE_TYPE} | head -n 1))

  case ${MULTI_LAB_MACHINE}
  in
    y|Y|yes|Yes|YES|t|T|true|True|TRUE)
      local VM_CONFIG="${VM}-${MULTI_LM_EXT}.xml"
    ;;
    *)
      local VM_CONFIG="${VM}.xml"
    ;;
  esac

  if [ -e "${VM}"/"${VM_CONFIG}" ]
  then
    echo -e "${LTBLUE}Registering VM with Libvirt ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
    run sudo virsh define "${VM}"/"${VM_CONFIG}"

    #--test--------------------------------------------------
    if ! virsh list --all | grep -q ${VM}
    then
      if [ -e "${VM}"/"${VM_CONFIG}" ]
      then
        IS_ERROR=Y
        FAILED_TASKS="${FAILED_TASKS},install_functions.extract_register_libvirt_vms.register_vm:${VM}"
      fi
    fi
    #--------------------------------------------------------
  fi
  echo

  if [ -e "${VM}"/snapshots ]
  then
    update_vm_snapshot_uuid ${VM}
    #update_vm_snapshot_disk_paths ${VM}
    restore_vm_snapshots ${VM}
  fi
  echo

  local VM_POOL_CONFIG=${VM}.pool.xml
  if [ -e "${VM}"/"${VM_POOL_CONFIG}" ]
  then
    if ! sudo virsh pool-list | grep -q "${VM}$"
    then
    echo -e "${LTBLUE}Creating storage pool for VM ...${NC}"
      run sudo virsh pool-define "${VM}"/"${VM_POOL_CONFIG}"
      run sudo virsh pool-build ${VM}
      run sudo virsh pool-autostart ${VM}
      run sudo virsh pool-start ${VM}
    elif [ "$(sudo virsh pool-list | grep  ${VM} | awk '{ print $2 }')" != active ]
    then
      run sudo virsh pool-autostart ${VM}
      if [ "$(sudo virsh pool-list | grep  ${VM} | awk '{ print $3 }')" != yes ]
      then
        run sudo virsh pool-start ${VM}
      fi
    fi

    #--test--------------------------------------------------
    if ! virsh pool-list --all | grep -q ${VM}
    then
      if [ -e "${VM}"/"${VM_POOL_CONFIG}" ]
      then
        IS_ERROR=Y
        FAILED_TASKS="${FAILED_TASKS},install_functions.extract_register_libvirt_vms.create_pool_for_vm:${VM}"
      fi
    fi
    #--------------------------------------------------------
  fi
  echo

  if which vbmcctl > /dev/null 2>&1
  then
    local VM_VBMC_CONFIG=${VM}.vbmc
    if [ -e "${VM}"/"${VM_VBMC_CONFIG}" ]
    then
      if ! sudo vbmc list | grep -q "${VM}"
      then
      echo -e "${LTBLUE}Creating virtual BMC device for VM ...${NC}"
        run vbmcctl create config="${VM}"/"${VM_VBMC_CONFIG}"
      elif ! sudo vbmc list | grep "${VM}" | grep -q running
      then
        run vbmcctl delete config="${VM}"/"${VM_VBMC_CONFIG}"
        run vbmcctl create config="${VM}"/"${VM_VBMC_CONFIG}"
      fi
    
      #--test--------------------------------------------------
      if ! sudo vbmc list | grep -q ${VM}
      then
        if [ -e "${VM}"/"${VM_VBMC_CONFIG}" ]
        then
          IS_ERROR=Y
          FAILED_TASKS="${FAILED_TASKS},install_functions.extract_register_libvirt_vms.create_vbmc_for_vm:${VM}"
        fi
      fi
      #--------------------------------------------------------
    fi
  fi
  echo
}

##############################################################################

main() {
  check_type_of_provided_vm

  case ${VM_TYPE} in
    archive)
      extract_update_libvirt_vm
  
      case ${EXTRACT_ONLY} in
        N)
          register_libvirt_vm
        ;;
      esac
    ;;
    directory)
      register_libvirt_vm
    ;;
  esac
}

##############################################################################
#                          Main Code Body
##############################################################################

main ${*}

exit 0

