#!/bin/bash
# Version: 1.0.1
# Date: 2018-04-25

source ../config/lab_env.cfg
source ../config/include/colors.sh
source ../config/include/global_vars.sh
source ../config/include/common_functions.sh
source ../config/include/helper_functions.sh

create_virtual_bmc() {
  local DEFAULT_BMC_ADDR=127.0.0.1
  local DEFAULT_BMC_PORT=623
  local DEFAULT_BMC_USERNAME=admin
  local DEFAULT_BMC_PASSWORD=password

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

    run virtualbmc_control create ${VM_NAME} ${BMC_ADDR} ${BMC_PORT} ${VIRTUAL_BMC_NETWORK} ${BMC_USERNAME} ${BMC_PASSWORD}
  done
}

create_virtual_bmc

