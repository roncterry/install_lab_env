#!/bin/bash
# Version: 1.1.0
# Date: 2018-07-10

if [ -d ./config ]
then
  CONFIG_DIR="./config"
else
  CONFIG_DIR="../config"
fi
source ${CONFIG_DIR}/lab_env.cfg
source ${CONFIG_DIR}/include/colors.sh
source ${CONFIG_DIR}/include/global_vars.sh
source ${CONFIG_DIR}/include/common_functions.sh
source ${CONFIG_DIR}/include/helper_functions.sh

create_virtual_bmc() {
  local DEFAULT_BMC_ADDR=127.0.0.1
  local DEFAULT_BMC_PORT=623
  local DEFAULT_BMC_USERNAME=admin
  local DEFAULT_BMC_PASSWORD=password
  local DEFAULT_BMC_URI=qemu:///system

  if [ -z "${VIRTUAL_BMC_LIST}" ]
  then
    return
  fi

  if ! which vbmc > /dev/null
  then
    echo -e "${LTBLUE}The vbmc command does not seem to be available. Skipping virtual BMC creation ...${NC}"
    echo
    return
  else
    echo -e "${LTBLUE}Creating virtual BMC(s) ...${NC}"
    echo -e "${LTBLUE}---------------------------------------------------------${NC}"
  fi

  for BMC in ${VIRTUAL_BMC_LIST}
  do
    local VM_NAME=$(echo ${BMC} | cut -d , -f 1)
    local BMC_ADDR=$(echo ${BMC} | cut -d , -f 2)

    if [ -z ${BMC_ADDR} ]
    then
      BMC_ADDR=${DEFAULT_BMC_ADDR}
    fi

    local BMC_PORT=$(echo ${BMC} | cut -d , -f 3)
    if [ -z ${BMC_PORT} ]
    then
      BMC_PORT=${DEFAULT_BMC_PORT}
    fi

    local BMC_USERNAME=$(echo ${BMC} | cut -d , -f 4)
    if [ -z ${BMC_USERNAME} ]
    then
      BMC_USERNAME=${DEFAULT_BMC_USERNAME}
    fi

    local BMC_PASSWORD=$(echo ${BMC} | cut -d , -f 5)
    if [ -z ${BMC_PASSWORD} ]
    then
      BMC_PASSWORD=${DEFAULT_BMC_PASSWORD}
    fi

    local BMC_URI=$(echo ${BMC} | cut -d , -f 6)
    if [ -z ${BMC_URI} ]
    then
      BMC_URI=${DEFAULT_BMC_URI}
    fi

    run virtualbmc_control remove ${VM_NAME} ${BMC_ADDR} ${BMC_PORT} ${VIRTUAL_BMC_NETWORK} ${BMC_USERNAME} ${BMC_PASSWORD} ${BMC_URI}
    run virtualbmc_control create ${VM_NAME} ${BMC_ADDR} ${BMC_PORT} ${VIRTUAL_BMC_NETWORK} ${BMC_USERNAME} ${BMC_PASSWORD} ${BMC_URI}
    echo "====================================================================="
  done
}

create_virtual_bmc

