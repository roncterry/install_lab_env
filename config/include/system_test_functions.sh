##############  System Test Functions #####################################
# version: 3.1.2
# date: 2017-09-24

#=========  Hardware Test Functions  =============

get_cpu_type() {
  if grep -qi "GenuineIntel" /proc/cpuinfo
  then
    CPU_TYPE="intel"
  elif grep -qi "AuthenticAMD" /proc/cpuinfo 
  then
    CPU_TYPE="amd"
  else
    CPU_TYPE="unknown"
  fi
}

test_memory() {
    if [ "$(free -g | grep ^Mem | awk '{ print $2}')" -ge "${MIN_MEMORY}" ]
    then
      ENOUGH_MEMORY=Y
    else
      ENOUGH_MEMORY=N
    fi
}

test_disk_space() {
  if df -h | grep -q "/home/VMs"
  then
    #if [ "$(df -h | grep /home/VMs | awk '{ print $4 }' | sed 's/[A-Z]//' | cut -d . -f 1 | head -1)" -ge "${MIN_DISK_FREE}" ]
    if [ "$(df -BG | grep /home/VMs | awk '{ print $4 }' | sed 's/[A-Z]//' | cut -d . -f 1 | head -1)" -ge "${MIN_DISK_FREE}" ]
    then
      ENOUGH_DISKSPACE=Y
    else
      ENOUGH_DISKSPACE=N
    fi
  elif df -h | grep -q "/home"
  then
    #if [ "$(df -h | grep /home | awk '{ print $4 }' | sed 's/[A-Z]//' | cut -d . -f 1 | head -1)" -ge "${MIN_DISK_FREE}" ]
    if [ "$(df -BG | grep /home | awk '{ print $4 }' | sed 's/[A-Z]//' | cut -d . -f 1 | head -1)" -ge "${MIN_DISK_FREE}" ]
    then
      ENOUGH_DISKSPACE=Y
    else
      ENOUGH_DISKSPACE=N
    fi
  else
    #if [ "$(df -h | grep '/$' | awk '{ print $4 }' | sed 's/[A-Z]//' | cut -d . -f 1 | head -1)" -ge "${MIN_DISK_FREE}" ]
    if [ "$(df -BG | grep '/$' | awk '{ print $4 }' | sed 's/[A-Z]//' | cut -d . -f 1 | head -1)" -ge "${MIN_DISK_FREE}" ]
    then
      ENOUGH_DISKSPACE=Y
    else
      ENOUGH_DISKSPACE=N
    fi
  fi
}

test_for_vt_enabled() {
  get_cpu_type
  case ${CPU_TYPE} in
    intel)
      grep -q vmx /proc/cpuinfo && VT_ENABLED=Y
    ;;
    amd)
      grep -q svm /proc/cpuinfo && VT_ENABLED=Y
    ;;
  esac
}

#=========  Software/Utility Test Functions  =============

test_for_sudo() {
  if which sudo > /dev/null
  then
    SUDO_INSTALLED=Y
  else
    SUDO_INSTALLED=N
  fi

  case ${SUDO_INSTALLED}
  in
    Y)
      SUDO_TEST=$(sudo -n id 2>&1)
      if echo ${SUDO_TEST} | grep -q "a password is required"
      then
        SUDO_NOPASSWD=N
      elif echo ${SUDO_TEST} | grep -q "uid=0(root)"
      then
        SUDO_NOPASSWD=Y
      fi
    ;;
  esac
}

test_for_p7zip() {
  if which 7z > /dev/null 2>&1
  then
    P7ZIP_INSTALLED=Y
  else
    P7ZIP_INSTALLED=N
  fi
}

#=========  Hypervisor Test Functions  =============

#== KVM ==

test_for_kvm_virt() {
  get_cpu_type
  case ${CPU_TYPE} in
    intel)
      if lsmod | grep -q kvm_intel
      then
        KVM_LOADED=Y
      else
        KVM_LOADED=N
      fi
    ;;
    amd)
      if lsmod | grep -q kvm_amd
      then
        KVM_LOADED=Y
      else
        KVM_LOADED=N
      fi
    ;;
  esac
}

test_for_kvm_nested_virt() {
  get_cpu_type
  case ${CPU_TYPE} in
    intel)
      if lsmod | grep -q kvm_intel
      then
        KVM_LOADED=Y
        if [ -e /sys/module/kvm_intel/parameters/nested ]
        then
          if cat /sys/module/kvm_intel/parameters/nested | grep -q Y
          then
            NESTED_VIRT=Y
          else
            NESTED_VIRT=N
          fi
        else
          NESTED_VIRT=U
        fi
      else
        KVM_LOADED=N
      fi
    ;;
    amd)
      if lsmod | grep -q kvm_amd
      then
        KVM_LOADED=Y
        if [ -e /sys/module/kvm_amd/parameters/nested ]
        then
          if cat /sys/module/kvm_amd/parameters/nested | grep -q 1
          then
            NESTED_VIRT=Y
          else
            NESTED_VIRT=N
          fi
        else
          NESTED_VIRT=U
        fi
      else
        KVM_LOADED=N
      fi
    ;;
  esac
}

#== Libvirt ==

test_for_libvirt_default_uri() {
  if env | grep -q "LIBVIRT_DEFAULT_URI=qemu:///system"
  then
    LIBVIRT_DEFAULT_URI_SET=Y
  else
    LIBVIRT_DEFAULT_URI_SET=N
  fi
}

test_libvirt_config() {
  LIBVIRT_CFG=/etc/libvirt/libvirtd.conf
  test -e /etc/libvirt && LIBVIRT_INSTALLED=Y

  if sudo grep -q "^unix_sock_group = .*" ${LIBVIRT_CFG}
  then
    LIBVIRT_SOCK_GROUP_SET=Y
  else
    EDIT_LIBVIRTD_CONFIG=Y
  fi

  if sudo grep -q "^unix_sock_ro_perms = \"0777\"" ${LIBVIRT_CFG}
  then
    LIBVIRT_SOCK_RO_PERMS_SET=Y
  else
    EDIT_LIBVIRTD_CONFIG=Y
  fi

  if sudo grep -q "^unix_sock_rw_perms = \"0770\"" ${LIBVIRT_CFG}
  then
    LIBVIRT_SOCK_RW_PERMS_SET=Y
  else
    EDIT_LIBVIRTD_CONFIG=Y
  fi

  if sudo grep -q "^unix_sock_dir = .*" ${LIBVIRT_CFG}
  then
    LIBVIRT_SOCK_DIR_SET=Y
  else
    EDIT_LIBVIRTD_CONFIG=Y
  fi

  if sudo grep -q "^auth_unix_ro = \"none\"" ${LIBVIRT_CFG}
  then
    AUTH_UNIX_RO_SET=Y
  else
    EDIT_LIBVIRTD_CONFIG=Y
  fi

  if sudo grep -q "^auth_unix_rw = \"none\"" ${LIBVIRT_CFG}
  then
    AUTH_UNIX_RW_SET=Y
  else
    EDIT_LIBVIRTD_CONFIG=Y
  fi
}

test_for_libvirt_tcp_listen() {
  LIBVIRT_CFG=/etc/libvirt/libvirtd.conf
  if sudo grep -q "^listen_tcp = 1" ${LIBVIRT_CFG}
  then
    LISTEN_TCP_SET=Y
  else
    EDIT_LIBVIRTD_CONFIG=Y
  fi

  if sudo grep -q "^auth_tcp = \"none\"" ${LIBVIRT_CFG}
  then
    AUTH_TCP_NONE_SET=Y
  else
    EDIT_LIBVIRTD_CONFIG_TCP_LISTEN=Y
  fi
}

test_for_vnc_spice_listen() {
  LIBVIRT_QEMU_CFG=/etc/libvirt/qemu.conf
  if sudo grep -q "^vnc_listen = \"0.0.0.0\"" ${LIBVIRT_QEMU_CFG}
  then
    VNC_LISTEN_ALL_SET=Y
  else
    EDIT_QEMUD_CONFIG=Y
  fi

  if sudo grep -q "^spice_listen = \"0.0.0.0\"" ${LIBVIRT_QEMU_CFG}
  then
    SPICE_LISTEN_ALL_SET=Y
  else
    EDIT_QEMUD_CONFIG_VNC_SPICE_LISTEN=Y
  fi
}

test_for_libvirt_group() {
  LIBVIRT_CFG=/etc/libvirt/libvirtd.conf
  #LIBVIRT_GROUP=$(sudo grep "^unix_sock_group" ${LIBVIRT_CFG} | cut -d \" -f 2)
  #LIBVIRT_GROUP=$(sudo grep ".*unix_sock_group" ${LIBVIRT_CFG} | cut -d \" -f 2)
  LIBVIRT_GROUP=$(sudo grep '^[^#]*unix_sock_group' ${LIBVIRT_CFG} | cut -d \" -f 2)
  if groups | grep -q ${LIBVIRT_GROUP}
  then
    MEMBER_OF_LIBVIRT_GROUP=Y
  else
    MEMBER_OF_LIBVIRT_GROUP=N
  fi
}

test_for_libvirt_running() {
  if systemctl status libvirtd | grep -qo "active (running)"
  then
    LIBVIRT_RUNNING=Y
  else
    LIBVIRT_RUNNING=N
  fi
}

##############  Run Test Functions #####################################

run_test_for_vt_enabled() {
  echo -e "${LTBLUE}Checking if VT is enalbed in the BIOS ...${NC}"
  echo -e "${LTBLUE}-------------------------------------------------------------------${NC}"
  echo
  test_for_vt_enabled
  case ${VT_ENABLED} in
    Y)
      echo -e "  ${LTCYAN}  VT_ENABLED=${GREEN}Y${NC}"
      echo
      echo -e "  ${LTCYAN}    Continuing ...${NC}"
      echo
    ;;
    *)
      echo -e "  ${LTCYAN}  VT_ENABLED=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}VT must be enabled in the BIOS.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      echo -e "  ${ORANGE}Please Enable VT extensions in the BIOS and then rerun this script.${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
      TEST_FAIL=y
      #exit 1
    ;;
  esac
}

run_test_memory() {
  echo -e "${LTBLUE}Checking for enough memory ...${NC}"
  echo -e "${LTBLUE}-------------------------------------------------------------------${NC}"
  echo -e "${LTCYAN}Minimum memory: ${GREEN}${MIN_MEMORY}GB${NC}"
  echo
  test_memory
  case ${ENOUGH_MEMORY} in
    Y)
      echo -e "  ${LTCYAN}  ENOUGH_MEMORY=${GREEN}Y${NC}"
      echo
      echo -e "  ${LTCYAN}    Continuing ...${NC}"
      echo
    ;;
    N)
      echo -e "  ${LTCYAN}  ENOUGH_MEMORY=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}There is not enough memory.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      echo -e "  ${ORANGE}There must be ${MIN_MEMORY}GB memory to run the lab environment.${NC}"
      echo -e "  ${ORANGE}Add ememory and then rerun this script.${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
      TEST_FAIL=y
      #exit 2
    ;;
  esac
}

run_test_disk_space() {
  echo -e "${LTBLUE}Checking for enough disk space ...${NC}"
  echo -e "${LTBLUE}-------------------------------------------------------------------${NC}"
  echo -e "${LTCYAN}Minimum free disk space: ${GREEN}${MIN_DISK_FREE}GB${NC}"
  echo
  test_disk_space
  case ${ENOUGH_DISKSPACE} in
    Y)
      echo -e "  ${LTCYAN}  ENOUGH_DISKSPACE=${GREEN}Y${NC}"
      echo
      echo -e "  ${LTCYAN}    Continuing ...${NC}"
      echo
    ;;
    N)
      echo -e "  ${LTCYAN}  ENOUGH_DISKSPACE=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}There is not enough free disk space in /home.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      echo -e "  ${ORANGE}There must be ${MIN_DISK_FREE}GB free space in /home/VMs.${NC}"
      echo -e "  ${ORANGE}Free up some space or mount a disk with the required ${NC}"
      echo -e "  ${ORANGE}space on /home/VMs and then rerun this script.${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
      TEST_FAIL=y
      #exit 3
    ;;
  esac
}

run_test_for_sudo() {
  echo -e "${LTBLUE}Checking for sudo ...${NC}"
  echo -e "${LTBLUE}-------------------------------------------------------------------${NC}"
  echo
  test_for_sudo
  case ${SUDO_INSTALLED} in
    Y)
      echo -e "  ${LTCYAN}  SUDO_INSTALLED=${GREEN}Y${NC}"
      echo
      echo -e "  ${LTCYAN}    Continuing ...${NC}"
      echo
      case ${SUDO_NOPASSWD} in
        Y)
          echo -e "  ${LTCYAN}  SUDO_NOPASSWD=${GREEN}Y${NC}"
          echo
          echo -e "  ${LTCYAN}    Continuing ...${NC}"
          echo
        ;;
        N)
          echo -e "  ${LTCYAN}  SUDO_NOPASSWD=${LTRED}N${NC}"
          echo
          echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
          echo -e "  ${RED}[Warning]${NC}"
          echo
          echo -e "  ${ORANGE}  User or group not allowed to sudo or NOPASSWD: option not set.${NC}"
          echo
          echo -e "  ${RED}TIP:${NC}"
          echo -e "  ${ORANGE}  It is recommended that the NOPASSWD: option be set for your user or group.${NC}"
          echo -e "  ${ORANGE}  Without that option you may be asked for a password multiple times durring${NC}"
          echo -e "  ${ORANGE}  the installation.${NC}"
          echo
          echo -e "  ${ORANGE}  Add one of the following lines at the end of the /etc/sudoers file:${NC}"
          echo -e "  ${BLUE}    $(id -un) ALL=(ALL) NOPASSWD: ALL${NC}"
          echo -e "  ${ORANGE}  or${NC}"
          echo -e "  ${BLUE}    %$(id -gn) ALL=(ALL) NOPASSWD: ALL${NC}"
          echo
          echo -e "  ${ORANGE}  You should use the following command as the root user to do this:${NC}"
          echo -e "  ${LTGREEN}    visudo${NC}"
          echo
          echo -e "  ${ORANGE}  Press ${LTGREEN}Enter${LTCYAN} to continue without the NOPASSWD: option${NC}"
          echo -e "  ${ORANGE}  or${NC}"
          echo -e "  ${ORANGE}  Press ${LTGREEN}Ctrl+c${LTCYAN} to exit and make the change and then rerun this script${NC}"
          echo
          echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
          echo
          read
          echo -e "  ${LTCYAN}    Continuing ...${NC}"
          echo
        ;;
      esac
    ;;
    N)
      echo -e "  ${LTCYAN}  SUDO_INSTALLED=${LTRED}N${NC}"
      echo
      echo -e "  ${LTRED}The sudo utility is not installed.${NC}"
      echo
      echo -e "  ${ORANGE}The sudo utility must be installed to continue.${NC}"
      echo -e "  ${ORANGE}Please install the sudo and then rerun this script.${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "  ${LTRED}TIP:${NC}"
      echo -e "  ${ORANGE}  It is recommended that the NOPASSWD: option be set for your user or group.${NC}"
      echo -e "  ${ORANGE}  Without that option you may be asked for a password multiple times durring${NC}"
      echo -e "  ${ORANGE}  the installation.${NC}"
      echo
      echo -e "  ${ORANGE}  Add one of the following lines at the end of the /etc/sudoers file:${NC}"
      echo -e "  ${LTPURPLE}    $(id -un) ALL=(ALL) NOPASSWD: ALL${NC}"
      echo -e "  ${ORANGE}  or${NC}"
      echo -e "  ${LTPURPLE}    %$(id -gn) ALL=(ALL) NOPASSWD: ALL${NC}"
      echo
      echo -e "  ${ORANGE}  You should use the following command as the root user to do this:${NC}"
      echo -e "  ${LTGREEN}    visudo${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
      TEST_FAIL=y
      #exit 4
    ;;
  esac
}

run_test_for_p7zip() {
  echo -e "${LTBLUE}Checking for p7zip ...${NC}"
  echo -e "${LTBLUE}-------------------------------------------------------------------${NC}"
  echo
  test_for_p7zip
  case ${P7ZIP_INSTALLED} in
    Y)
      echo -e "  ${LTCYAN}  P7ZIP_INSTALLED=${GREEN}Y${NC}"
      echo
      echo -e "  ${LTCYAN}    Continuing ...${NC}"
      echo
    ;;
    N)
      echo -e "  ${LTCYAN}  P7ZIP_INSTALLED=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}The p7zip utility (7z command) is not installed.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      echo -e "  ${ORANGE}Install the package: ${BLUE}p7zip${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
      TEST_FAIL=y
      #exit 5
    ;;
  esac
}

run_test_for_kvm_virt() {
  echo -e "${LTBLUE}Checking for KVM virtualization ...${NC}"
  echo -e "${LTBLUE}-------------------------------------------------------------------${NC}"
  echo
  test_for_kvm_virt
  case ${KVM_LOADED} in
    Y)
      echo -e "  ${LTCYAN}  KVM_LOADED=${GREEN}Y${NC}"
      echo
      echo -e "  ${LTCYAN}    Continuing ...${NC}"
      echo

      case ${REQUIRE_KVM_NESTED} in
        N)
          NESTED_VIRT=NA
        ;;
        *)
          test_for_kvm_nested_virt
          case ${NESTED_VIRT} in
            Y)
              echo -e "${LTBLUE}Checking for nested virtualization in KVM ...${NC}"
              echo -e "${LTBLUE}-------------------------------------------------------------------${NC}"
              echo
              echo -e "  ${LTCYAN}  NESTED_VIRT=${GREEN}Y${NC}"
              echo
              echo -e "  ${LTCNAN}    Continuing ...${NC}"
              echo
            ;;
            N)
              echo -e "  ${LTCYAN}  NESTED_VIRT=${LTRED}N${NC}"
              echo
              echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
              echo -e "${RED}[Problem]${NC}"
              echo -e "  ${LTRED}Nested virtualization is not enabled for KVM.${NC}"
              echo
              echo -e "${RED}[Remediation Required]${NC}"
              echo -e "${RED}        |     |     |${NC}"
              echo -e "${RED}        V     V     V${NC}"
              echo -e "  ${ORANGE}Create the file: ${BLUE}/etc/modprobe.d/50-kvm.conf${NC}"
              echo
              echo -e "  ${ORANGE}Add the following to the file:${NC}"
              echo -e "  ${LTPURPLE}    options kvm-amd nested=1${NC}"
              echo -e "  ${LTPURPLE}    options kvm-intel nested=Y${NC}"
              echo
              echo -e "  ${ORANGE}Then reboot your machine and rerun this script.${NC}"
              echo
              echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
              echo
              TEST_FAIL=y
              #exit 6
            ;;
          esac
        ;;
      esac
    ;;
    *)
      echo -e "  ${LTCYAN}  KVM_LOADED=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}The KVM kernel modules are not loaded.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      echo -e "  ${ORANGE}Make sure that the kvm and kvm_intel (or kvm_amd)${NC}"
      echo -e "  ${ORANGE}kernel modules are available and can be loaded and${NC}"
      echo -e "  ${ORANGE}then rerun this script.${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
      TEST_FAIL=y
      #exit 5
    ;;
  esac
}

run_test_libvirt_config() {
  echo -e "${LTBLUE}Checking for proper Libvirt configuration ...${NC}"
  echo -e "${LTBLUE}-------------------------------------------------------------------${NC}"
  echo
  test_libvirt_config
  case ${LIBVIRT_INSTALLED} in
    Y)
      echo -e "  ${LTCYAN}  LIBVIRT_INSTALLED=${GREEN}Y${NC}"
      echo
    ;;
    *)
      echo -e "  ${LTCYAN}  LIBVIRT_INSTALLED=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}Libvirt is not installed.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      case ${EDIT_LIBVIRTD_CONFIG} in
        Y)
          echo -e "  ${ORANGE}As the root user, edit ${BLUE}/etc/libvirt/libvirtd.conf${NC}"
          echo
        ;;
      esac
      echo -e "  ${ORANGE}Install: ${NC}"
      echo -e "  ${ORANGE}  -Libvirt${NC}"
      echo -e "  ${ORANGE}  -the required libvirtd packages for KVM${NC}"
      echo -e "  ${ORANGE}  -virt-manager${NC}"
      echo -e "  ${ORANGE}  -virt-install${NC}"
      echo -e "  ${ORANGE}  -virt-viewer${NC}"
      echo
      echo -e "  ${ORANGE}Reboot and rerun this script.${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
      TEST_FAIL=y
      #exit 7
    ;;
  esac

  case ${LIBVIRT_SOCK_GROUP_SET} in
    Y)
      LIBVIRT_SOCK_GROUP_SET=Y
      echo -e "  ${LTCYAN}  LIBVIRT_SOCK_GROUP_SET=${GREEN}Y${NC}"
    ;;
    *)
      echo -e "  ${LTCYAN}  LIBVIRT_SOCK_GROUP_SET=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}Libvirt is not configured to use a UNIX socket.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      case ${EDIT_LIBVIRTD_CONFIG} in
        Y)
          echo -e "  ${ORANGE}As the root user, edit ${BLUE}/etc/libvirt/libvirtd.conf${NC}"
          echo
        ;;
      esac
      echo -e "  ${ORANGE}Locate and uncomment/edit the following line to match:${NC}"
      echo -e "  ${LTPURPLE}  unix_sock_group = libvirt${NC}" 
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
    ;;
  esac
  case ${LIBVIRT_SOCK_RO_PERMS_SET} in
    Y)
      LIBVIRT_SOCK_RO_PERMS_SET=Y
      echo -e "  ${LTCYAN}  LIBVIRT_SOCK_RO_PERMS_SET=${GREEN}Y${NC}"
    ;;
    *)
      echo -e "  ${LTCYAN}  LIBVIRT_SOCK_RO_PERMS_SET=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}Libvirt is not configured to use the correct UNIX socket ro permissions.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      case ${EDIT_LIBVIRTD_CONFIG} in
        Y)
          echo -e "  ${ORANGE}As the root user, edit ${BLUE}/etc/libvirt/libvirtd.conf${NC}"
          echo
        ;;
      esac
      echo -e "  ${ORANGE}Locate and uncomment/edit the following line to match:${NC}"
      echo -e "  ${LTPURPLE}  unix_sock_ro_perms = \"0777\"${NC}" 
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
    ;;
  esac
  case ${LIBVIRT_SOCK_RW_PERMS_SET} in
    Y)
      LIBVIRT_SOCK_RW_PERMS_SET=Y
      echo -e "  ${LTCYAN}  LIBVIRT_SOCK_RW_PERMS_SET=${GREEN}Y${NC}"
    ;;
    *)
      echo -e "  ${LTCYAN}  LIBVIRT_SOCK_RW_PERMS_SET=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}Libvirt is not configured to use the correct UNIX socket rw permissions.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      case ${EDIT_LIBVIRTD_CONFIG} in
        Y)
          echo -e "  ${ORANGE}As the root user, edit ${BLUE}/etc/libvirt/libvirtd.conf${NC}"
          echo
        ;;
      esac
      echo -e "  ${ORANGE}Locate and uncomment/edit the following line to match:${NC}"
      echo -e "  ${LTPURPLE}  unix_sock_rw_perms = \"0770\"${NC}" 
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
    ;;
  esac
  case ${LIBVIRT_SOCK_DIR_SET} in
    Y)
      LIBVIRT_SOCK_DIR_SET=Y
      echo -e "  ${LTCYAN}  LIBVIRT_SOCK_DIR_SET=${GREEN}Y${NC}"
    ;;
    *)
      echo -e "  ${LTCYAN}  LIBVIRT_SOCK_DIR_SET=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}Libvirt Unix socket directory is not set.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      case ${EDIT_LIBVIRTD_CONFIG} in
        Y)
          echo -e "  ${ORANGE}As the root user, edit ${BLUE}/etc/libvirt/libvirtd.conf${NC}"
          echo
        ;;
      esac
      echo -e "  ${ORANGE}Locate and uncomment/edit the following line to match:${NC}"
      echo -e "  ${LTPURPLE}  unix_sock_dir = \"/var/run/libvirt\"${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
    ;;
  esac
  case ${AUTH_UNIX_RO_SET} in
    Y)
      AUTH_UNIX_RO_SET=Y
      echo -e "  ${LTCYAN}  AUTH_UNIX_RO_SET=${GREEN}Y${NC}"
    ;;
    *)
      echo -e "  ${LTCYAN}  AUTH_UNIX_RO_SET=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}Libvirt is not configured to use UNIX socket ro group authorization.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      case ${EDIT_LIBVIRTD_CONFIG} in
        Y)
          echo -e "  ${ORANGE}As the root user, edit ${BLUE}/etc/libvirt/libvirtd.conf${NC}"
          echo
        ;;
      esac
      echo -e "  ${ORANGE}Locate and uncomment/edit the following line to match:${NC}"
      echo -e "  ${LTPURPLE}  auth_unix_ro = \"none\"${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
    ;;
  esac
  case ${AUTH_UNIX_RW_SET} in
    Y)
      AUTH_UNIX_RW_SET=Y
      echo -e "  ${LTCYAN}  AUTH_UNIX_RW_SET=${GREEN}Y${NC}"
    ;;
    *)
      echo -e "  ${LTCYAN}  AUTH_UNIX_RW_SET=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}Libvirt is not configured to use UNIX socket rw group authorization.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      case ${EDIT_LIBVIRTD_CONFIG} in
        Y)
          echo -e "  ${ORANGE}As the root user, edit ${BLUE}/etc/libvirt/libvirtd.conf${NC}"
          echo
        ;;
      esac
      echo -e "  ${ORANGE}Locate and uncomment/edit the following line to match:${NC}"
      echo -e "  ${LTPURPLE}  auth_unix_rw = \"none\"${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
    ;;
  esac
  case ${EDIT_LIBVIRTD_CONFIG} in
    Y)
      echo
      echo -e "  ${ORANGE}After editing the file, reboot and rerun this script.${NC}"
      echo
      TEST_FAIL=y
      #exit 8
    ;;
  esac
  
  test_for_libvirt_default_uri
  case ${LIBVIRT_DEFAULT_URI_SET} in
    Y)
      LIBVIRT_DEFAULT_URI_SET=Y
      echo -e "  ${LTCYAN}  LIBVIRT_DEFAULT_URI_SET=${GREEN}Y${NC}"
    ;;
    *)
      echo -e "  ${LTCYAN}  LIBVIRT_DEFAULT_URI_SET=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}The LIBVIRT_DEFAULT_URI environment variable is not set.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      echo -e "  ${ORANGE}As the root user, create and edit ${BLUE}/etc/profile.d/libvirt.sh:${NC}"
      echo
      echo -e "  ${ORANGE}Add the following line to the end of the file:${NC}"
      echo -e "  ${LTPURPLE}  export LIBVIRT_DEFAULT_URI=\"qemu:///system\"${NC}"
      echo
      echo -e "  ${ORANGE}After editing the file, log out and then back in again and rerun this script.${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
      TEST_FAIL=y
      #exit 9
    ;;
  esac
  
  test_for_libvirt_group
  echo -e "  ${LTCYAN}  LIBVIRT_GROUP=${GREEN}${LIBVIRT_GROUP}${NC}"
  case ${MEMBER_OF_LIBVIRT_GROUP} in
    Y)
      MEMBER_OF_LIBVIRT_GROUP=Y
      echo -e "  ${LTCYAN}  MEMBER_OF_LIBVIRT_GROUP=${GREEN}Y${NC}"
      echo
      echo -e "  ${LTCYAN}    Continuing ...${NC}"
    ;;
    *)
      echo -e "  ${LTCYAN}  MEMBER_OF_LIBVIRT_GROUP=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}You are not a member of the Libvirt group.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      echo -e "  ${ORANGE}As the root user, enter the following command:${NC}"
      echo
      echo -e "  ${LTGREEN}  usermod -aG libvirt $(id -un)${NC}"
      echo
      echo -e "  ${ORANGE}After entering the command, log out and then back in again and rerun this script.${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
      TEST_FAIL=y
      #exit 10
    ;;
  esac

  echo
  echo -e "${LTBLUE}Checking if Libvirt is running/enabled ...${NC}"
  echo -e "${LTBLUE}-------------------------------------------------------------------${NC}"
  echo
  test_for_libvirt_running
  case ${LIBVIRT_RUNNING} in
    Y)
      LIBVIRT_RUNNING=Y
      echo -e "  ${LTCYAN}  LIBVIRT_RUNNING=${GREEN}Y${NC}"
      echo
      echo -e "  ${LTCYAN}    Continuing ...${NC}"
    ;;
    *)
      echo -e "  ${LTCYAN}  LIBVIRT_RUNNING=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}The Libvirt daemon is not running and may not be enabled.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      echo -e "  ${ORANGE}As the root user, enter the following commands:${NC}"
      echo
      echo -e "  ${LTGREEN}  systemctl enable libvirtd${NC}"
      echo -e "  ${LTGREEN}  systemctl start libvirtd${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
      TEST_FAIL=y
      #exit 10
    ;;
  esac
}

run_test_libvirt_tcp_listen() {
  echo
  echo -e "${LTBLUE}Checking if Libvirt/QEMU is listening for TCP witn no auth ...${NC}"
  echo -e "${LTBLUE}-------------------------------------------------------------------${NC}"
  echo
  test_for_libvirt_tcp_listen
  case ${LISTEN_TCP_SET} in
    Y)
      LISTEN_TCP_SET=Y
      echo -e "  ${LTCYAN}  LISTEN_TCP_SET=${GREEN}Y${NC}"
    ;;
    *)
      echo -e "  ${LTCYAN}  LISTEN_TCP_SET=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}Libvirt is not configured to listen via TCP.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      case ${EDIT_LIBVIRTD_CONFIG} in
        Y)
          echo -e "  ${ORANGE}As the root user, edit ${BLUE}/etc/libvirt/libvirtd.conf${NC}"
          echo
        ;;
      esac
      echo -e "  ${ORANGE}Locate and uncomment/edit the following line to match:${NC}"
      echo -e "  ${LTPURPLE}  listen_tcp = 1${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
    ;;
  esac
  case ${AUTH_TCP_NONE_SET} in
    Y)
      AUTH_TCP_NONE_SET=Y
      echo -e "  ${LTCYAN}  AUTH_TCP_NONE_SET=${GREEN}Y${NC}"
      echo
      echo -e "  ${LTCYAN}    Continuing ...${NC}"
    ;;
    *)
      echo -e "  ${LTCYAN}  AUTH_TCP_NONE_SET=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}Libvirt is not configured to allow access via TCP without authentication.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      case ${EDIT_LIBVIRTD_CONFIG} in
        Y)
          echo -e "  ${ORANGE}As the root user, edit ${BLUE}/etc/libvirt/libvirtd.conf${NC}"
          echo
        ;;
      esac
      echo -e "  ${ORANGE}Locate and uncomment/edit the following line to match:${NC}"
      echo -e "  ${LTPURPLE}  auth_tcp = \"none\"${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
    ;;
  esac
  case ${EDIT_LIBVIRTD_CONFIG_TCP_LISTEN} in
    Y)
      echo
      echo -e "  ${ORANGE}After editing the file, reboot and rerun this script.${NC}"
      echo
      TEST_FAIL=y
      #exit 8
    ;;
  esac
}

run_test_vnc_spice_listen() {
  echo
  echo -e "${LTBLUE}Checking if Libvirt/QEMU is listening for VNC and Spice ...${NC}"
  echo -e "${LTBLUE}-------------------------------------------------------------------${NC}"
  echo
  test_for_vnc_spice_listen
  case ${VNC_LISTEN_ALL_SET} in
    Y)
      VNC_LISTEN_ALL_SET=Y
      echo -e "  ${LTCYAN}  VNC_LISTEN_ALL_SET=${GREEN}Y${NC}"
    ;;
    *)
      echo -e "  ${LTCYAN}  VNC_LISTEN_ALL_SET=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}The QEMU Libvirt driver is not configured to allow VNC access from${NC}"
      echo -e "  ${LTRED}all public interfaces.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      case ${EDIT_LIBVIRTD_CONFIG} in
        Y)
          echo -e "  ${ORANGE}As the root user, edit ${BLUE}/etc/libvirt/qemu.conf${NC}"
          echo
        ;;
      esac
      echo -e "  ${ORANGE}Locate and uncomment/edit the following line to match:${NC}"
      echo -e "  ${LTPURPLE}  vnc_listen = \"0.0.0.0\"${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
    ;;
  esac
  case ${SPICE_LISTEN_ALL_SET} in
    Y)
      SPICE_LISTEN_ALL_SET=Y
      echo -e "  ${LTCYAN}  SPICE_LISTEN_ALL_SET=${GREEN}Y${NC}"
      echo
      echo -e "  ${LTCYAN}    Continuing ...${NC}"
    ;;
    *)
      echo -e "  ${LTCYAN}  SPICE_LISTEN_ALL_SET=${LTRED}N${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo -e "${RED}[Problem]${NC}"
      echo -e "  ${LTRED}The QEMU Libvirt driver is not configured to allow spice access from${NC}"
      echo -e "  ${LTRED}all public interfaces.${NC}"
      echo
      echo -e "${RED}[Remediation Required]${NC}"
      echo -e "${RED}        |     |     |${NC}"
      echo -e "${RED}        V     V     V${NC}"
      case ${EDIT_LIBVIRTD_CONFIG} in
        Y)
          echo -e "  ${ORANGE}As the root user, edit ${BLUE}/etc/libvirt/qemu.conf${NC}"
          echo
        ;;
      esac
      echo -e "  ${ORANGE}Locate and uncomment/edit the following line to match:${NC}"
      echo -e "  ${LTPURPLE}  spice_listen = \"0.0.0.0\"${NC}"
      echo
      echo -e "${ORANGE}------------------------------------------------------------------------${NC}"
      echo
    ;;
  esac
  case ${EDIT_QEMUD_CONFIG_VNC_SPICE_LISTEN} in
    Y)
      echo
      echo -e "  ${ORANGE}After editing the file, reboot and rerun this script.${NC}"
      echo
      TEST_FAIL=y
      #exit 8
    ;;
  esac
  
}
  
##############  Run Tests #####################################

run_tests() {
  #### Test Hardware ####

  #-VT Enabled in BIOS
  case ${REQUIRE_VT_ENABLED} in
    N|n)
      VT_ENABLED=NA
    ;;
    *)
      run_test_for_vt_enabled
    ;;
  esac

  #-Minimum Memory
  case ${REQUIRE_MIN_MEMORY} in
    N|n)
      ENOUGH_MEMORY=NA
    ;;
    *)
      run_test_memory
    ;;
  esac

  #-Minimum Disk Space
  case ${REQUIRE_MIN_DISKSPACE} in
    N|n)
      ENOUGH_DISKSPACE=NA
    ;;
    *)
      run_test_disk_space
    ;;
  esac

  #### Test Software ####

  #-sudo
  case ${REQUIRE_SUDO_NOPASSWD} in
    N|n)
      SUDO_NOPASSWD=NA
    ;;
    *)
      run_test_for_sudo
    ;;
  esac

  #-p7zip
  case ${REQUIRE_P7ZIP} in
    N|n)
      P7ZIP_INSTALLED=NA
    ;;
    *)
      run_test_for_p7zip
    ;;
  esac

  #### Test Hypervisor ####

  #-KVM
  case ${REQUIRE_KVM_VIRT} in
    N|n)
      KVM_LOADED=NA
    ;;
    *)
      run_test_for_kvm_virt
    ;;
  esac

  #-Libvirt
  case ${REQUIRE_LIBVIRT} in
    N|n)
      LIBVIRT_INSTALLED=NA
    ;;
    *)
      run_test_libvirt_config
    ;;
  esac

  #-Libvirt (TCP listen)
  case ${REQUIRE_LIBVIRT_TCP_LISTEN} in
    N|n)
      LIBVIRT_TCP_LISTEN=NA
    ;;
    *)
      run_test_libvirt_tcp_listen
    ;;
  esac

  #-Libvirt-QEMU (VNC/Spice listen)
  case ${REQUIRE_LIBVIRT_QEMU_VNC_SPICE_LISTEN} in
    N|n)
      VNC_SPICE_LISTEN=NA
    ;;
    *)
      run_test_vnc_spice_listen
    ;;
  esac

  #========================================================

  case ${TEST_FAIL} 
  in
    y|Y|yes|Yes|1)
      echo 
      echo -e "${LTRED}---------------------------------------------------------------------------${NC}"
      echo -e ${LTRED}"                Some tests failed to complete successfully"${NC}
      echo
      echo -e ${LTRED}"        Please view the errors and the suggested remediations above."${NC}
      echo -e "${LTRED}---------------------------------------------------------------------------${NC}"
      echo
      exit 1
    ;;
    *)
      echo 
      echo -e "${GREEN}---------------------------------------------------------------------------${NC}"
      echo -e ${GREEN}"                     All tests complete and successfull"${NC}
      echo -e "${GREEN}---------------------------------------------------------------------------${NC}"
      echo
    ;;
  esac
}
