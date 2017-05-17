##############################################################################
#                          Global Variables
# version: 1.1.0
# date: 2016-10-12
##############################################################################

CONFIG_SRC_DIR="./config"

PDF_SRC_DIR="./pdf"
PDF_DEST_DIR="${HOME}/pdf"

SCRIPTS_SRC_DIR="./scripts"
SCRIPTS_DEST_DIR="${HOME}/scripts"

VM_AUTOBUILD_SCRIPT_DIR="create-vms"
VM_AUTOBUILD_CONFIG_DIR="${CONFIG_SRC_DIR}/create-vms.cfg"

LAB_SCRIPT_DIR="lab-automation"
DEPLOY_CLOUD_SCRIPT_DIR="deploy-cloud"

VM_SRC_DIR="./VMs"
VM_DEST_DIR="/home/VMs/${COURSE_NUM}"

ISO_SRC_DIR="./iso"
ISO_DEST_DIR="/home/iso"

IMAGE_SRC_DIR="./images"
IMAGE_DEST_DIR="/home/images"

VNET_CONFIG_DIR="${CONFIG_SRC_DIR}/libvirt.cfg"
LOCAL_VNET_CONFIG_DIR="${SCRIPTS_DEST_DIR}/${COURSE_NUM}/config/libvirt.cfg"

RPM_DIR="./rpms"
  
VMWARE_INSTALLER_DIR="./vmware"
