# Introduction

This documents outlines both the configuration requirments for KVM/Libvirt VMs as well as additional best practices. It is broken down into the following sections:

- Required in ALL VMs to Support Our Live Labs

- Required When Using SCSI disks

- Best Practices and Optional Config

- Known Issues

-------------------------------------------------------------------------------------------------------

# Required in ALL VMs to Support Our Live Labs

## Nested Virtualization Requirements:

For our VMs to run with the best possible performance the following is required.

- Specify `mode=host-model` and `feature pcid=optional` in `<cpu>` definition 
  (**PREFERED OPTION - USE THIS ONE** (unless you absolutly know you need to use one of the other least preferred options))

Example:

```xml
  <cpu mode="host-model" check="partial">
    <feature policy="optional" name="pcid"/>
  </cpu>
```

(**LEAST PREFERED OPTIONS - DO NOT USE** (unless you absolutly know you need one of these))
A more generalized solution would be to use the following (**WARNING**: This can cause problems with VM live migration - **DO NOT** use unless you absolutly have to):

***Examples***: 

```xml
<cpu mode="host-passthrough" check="none" migratable="on"/>
```

or

```xml
<cpu mode="maximum" check="none"/>
```

There is functionality that can be used, if desired, in the `install_lab_env.sh` script to automatically update the `<cpu>` block of the VM's config XML file when the lab environment is installed. Read the documentation in the `lab_env.cfg` file for more details. However, it is strongly recommneded that you have the `<cpu>` block correctly configured in the VM's config XML rather than relying on the `install_lab_env.sh` script to fix it.

## Network Configuration Requirements:

Always use network interface `model type='virtio'` as it provides the best network performance.

***Example***:

```xml
  <interface type="network">
    <mac address="52:54:00:ff:02:01"/>
    <source network="demo101-net"/>
    <model type="virtio"/>
    <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
  </interface>
```

  **Note**: 
    The pci domain, bus, slot and function may be different than this example in your VM.

## Block Device Types/Configuration Requirements:

- For high I/O disks always use either VirtIO (preferred) or VirtIO-SCSI (SCSI with a VirtIO-SCSI controller).
  - SCSI disks are useful when you need to show the disk block device as `/dev/sdX`. If you don't need this then just use VirtIO disks.
- For disks (not CDROMs) always use `cache="writeback"` for the disk caching mode.
- CD/DVD drives can still be SATA especially if they aren't used beyond just performing an install during the exercises.
- **DO NOT** use IDE drives at all. Use SATA where you think you need IDE (i.e. CD/DVD drives). Or better yet use SCSI or VirtIO disks.

VirtIO Disk Example:

```xml
  <disk type="file" device="disk">
    <driver name="qemu" type="qcow2" cache="writeback"/>
    <source file="ome/VMs/DEMO101/DEMO101-vm01/disk01.qcow2"/>
    <target dev="vda: bus="virtio"/>
    <address type="pci" domain="0x0000" bus="0x05" slot="0x00" function="0x0"/>
  </disk>
```

  **Notes - VirtIO Dsks**:
    - The pci domain, bus, slot and function may be different than this example in your VM.
    - If using multiple VirtIO disk each disk will have its own pci domain, bus, slot and function.

***SCSI Disk Example***:

```xml
  <disk type="file" device="disk">
    <driver name="qemu" type="qcow2" cache="writeback"/>
    <source file="/home/VMs/DEMO101/DEMO101-vm01/disk01.qcow2"/>
    <target dev="sda" bus="scsi"/>
    <address type="drive" controller="0" bus="0" target="0" unit="0"/>
  </disk>
```

  **Notes - SCSI Disks**:
    - The controller, bus, target and unit may be different than this example in your VM.
    - When using mutiple SCSI disks/CDROMs see persistent ordering of SCSI disks addressed below.
    - Due to how SCSI disk are enumerated by the OS, if you will be using multiple SCSI disks and you want to ensure that your first disk (`/dev/sda`) is where your OS is installed it is best to install the VM with a single SCSI disk and then add the other disks to the VM after install. If you need multiple disks and don't explicitly need SCSI disks it is best to just use VirtIO disks.

***SATA CDROM Example***:

```xml
  <disk type="file" device="cdrom">
    <driver name="qemu" type="raw"/>
    <target dev="sda" bus="sata"/>
    <readonly/>
    <shareable/>
    <address type="drive" controller="0" bus="0" target="0" unit="0"/>
  </disk>
```

**Notes - SATA CDROM**:
    - The controller, bus, target and unit may be different than this example in your VM. 
    - If using a SCSI disk along with a SATA CDROM it is OK for both the disk and CDROM to use `controller="0" bus="0" target="0" unit="0"` as one is on the SATA controller and the other is on the SCSI controller.

***SCSI CDROM Example***:

```xml
  <disk type="file" device="cdrom">
    <driver name="qemu" type="raw" cache="writeback"/>
    <target dev="sda" bus="scsi"/>
    <readonly/>
    <shareable/>
    <address type="drive" controller="0" bus="0" target="0" unit="0"/>
  </disk>
```

  **Notes - SCSI CDROM**:
    - The controller, bus, target and unit may be different than this example in your VM.
    - When using a SCSI CDROM with SCSI disks it is not uncommon for the SCSI CDROM to use `controller="0" bus="0" target="0" unit="0"` and be `/dev/sda` and the first SCSI disk to use `controller="0" bus="0" target="0" unit="1"` and be `/dev/sdb`. This configuration is OK to use.
    - When using mutiple SCSI disks/CDROMs see persistent ordering of SCSI disks addressed below.

# Required When Using SCSI disks

## Storage Controller Configuration Requirements:

To provide the best SCSI disk performance VirtIO-SCSI needs to be manually added as the SCSI controller type (LSILogic is the default).

  ***Example***:

```xml
    <controller type="scsi" index="0" model="virtio-scsi">
      <address type="pci" domain="0x0000" bus="0x08" slot="0x00" function="0x0"/>
    </controller>
```

  **Note**:
    The pci domain, bus, slot and function may be different than this example in your VM.

## SCSI Device Persistent Ordering:

Due to how SCSI disks are enumerated it is not uncommon for the order of the disks to change. To preserve a persistent ordering of the disks the disk definitions must be modified. 

- The required modifications entail setting the `target=` to a different number in the `<address>` line of the device definition (You may also need to change `bus=` as well, incrementing it for each disk).

- If you are starting with a manually created VM XML definition you can make these modifications directly to the XML file before VM installation. 

- When creating the VM using Virt-Manager these modifications can only be made after the VM has been installed. 
  
  - You can initially install the VM with only a single SCSI disk and then add the additional disks and the modifications after install.

- If you need multiple disks and don't explicitly need SCSI disks, for example to have your disk block devices be `/dev/sdX`, then use VirtIO disks rather than SCSI disks.
  
  ***Example***:

```xml
  <disk type="file" device="disk">
    <driver name="qemu" type="qcow2" cache="writeback"/>
    <source file="/home/VMs/DEMO101/DEMO101-vm01/disk01.qcow2"/>
    <target dev="sdb" bus="scsi"/>
    <address type="drive" controller="0" bus="0" target="0" unit="1"/>
  </disk>
  <disk type="file" device="disk">
    <driver name="qemu" type="qcow2" cache="writeback"/>
    <source file="/home/VMs/DEMO101/DEMO101-vm01/disk02.qcow2"/>
    <target dev="sdc" bus="scsi"/>
    <address type="drive" controller="0" bus="0" target="1" unit="2"/>
  </disk>
  <disk type="file" device="disk">
    <driver name="qemu" type="qcow2" cache="writeback"/>
    <source file="/home/VMs/DEMO101/DEMO101-vm01/disk03.qcow2"/>
    <target dev="sdd" bus="scsi"/>
    <address type="drive" controller="0" bus="0" target="2" unit="3"/>
  </disk>
```

# Best Practices and Optional Config

## Machine Type and Version:

The machine type specifies the type of virtualized hardware platform that will be presented to the VM. At it's core a machine type is based on a specific chipset type (i440fx, q35, xenfv, etc.). Each updated version of Libvirt/Qemu will add and potentially remove supported machine type versions (and potentially remove machine types themselves - machine type pc was removed and xenfv was added not to long ago). The current default machine type is pc-q35 but a couple of openSUSE Leap release ago the default was pc-i440fx. The machine types can be displayed using the command: virsh capabilities

Best practice is to use the machine type: **pc-q35-X.Y** (where X.Y is a supported version)

***Example***:

```xml
  <os>
    <type arch='x86_64' machine='pc-q35-5.2'>hvm</type>
  </os>
```

(Note that the `<os>` tag will be a bit different than this when using UEFI booting. This is covered below in the UEFI booting section.)

Older VMs created on previous versions of openSUSE Leap, when pc-i440fx was still the default, will probably have that machine type specified. When updating a course's lab environment it is best to update from pc-i440fx to pc-q35. It is also best to update the machine type version to at least the maximum supported by the standard image n-2. Here are a list of maximum and minimum machine type version supported since openSUSE Leap 15.3.

**openSUSE Leap 15.3:** 

| Supported | i440fx        | q35        |
| --------- | ------------- | ---------- |
| Lowest    | pc-i440fx-1.4 | pc-q35-2.4 |
| Highest   | pc-i440fx-5.2 | pc-q35-5.2 |

**openSUSE Leap 15.4:** 

| Supported | i440fx        | q35        |
| --------- | ------------- | ---------- |
| Lowest    | pc-i440fx-1.4 | pc-q35-2.4 |
| Highest   | pc-i440fx-6.2 | pc-q35-6.2 |

**openSUSE Leap 15.5:** 

| Supported | i440fx        | q35        |
| --------- | ------------- | ---------- |
| Lowest    | pc-i440fx-2.0 | pc-q35-2.4 |
| Highest   | pc-i440fx-7.1 | pc-q35-7.1 |

There is functionality that can be used, if desired, in the `install_lab_env.sh` script to automatically update the machine type and version specified in the VM's config file to the maximum supported version on the vhost the VM is being installed on when the lab environment is installed. Read the documentation in the `lab_env.cfg` file for more details. It is strongly recommnede that you have the machine type and version set correctly in the VM's config XML file rather than rely on the `install_lab_env.sh` script to update it.

## CPU Optimizations:

Pinning of VCPUs is suggested to improve performance of VMs when running nested and especially nested on cloud platforms. This is most effective in VMs that will be running Kubernetes and containerized workoads. This is especially true when running our lab environments on cloud platforms like Azure.

- You can use the `<cputune>` configuration block to do this using the following as an example for a VM with 8 VCPUs.
  
  ***Example***:

```xml
  <cputune>
    <vcpupin vcpu="0" cpuset="0"/>
    <vcpupin vcpu="1" cpuset="1"/>
    <vcpupin vcpu="2" cpuset="2"/>
    <vcpupin vcpu="3" cpuset="3"/>
    <vcpupin vcpu="4" cpuset="4"/>
    <vcpupin vcpu="5" cpuset="5"/>
    <vcpupin vcpu="6" cpuset="6"/>
    <vcpupin vcpu="7" cpuset="7"/>
  </cputune>
```

- If possible, pinning different VM's VCPUs to different cpusets/physical CPUs can potentially (--need to test this--) provide better performance. However pinning all VM's VCPUs to the same cpusets/physical CPUs will still increase perfromance as it helps with caching issues. 
  
  ***Example for VM #1***:

```xml
  <cputune>
      <vcpupin vcpu="0" cpuset="0"/>
      <vcpupin vcpu="1" cpuset="1"/>
      <vcpupin vcpu="2" cpuset="2"/>
      <vcpupin vcpu="3" cpuset="3"/>
    </cputune>
```

  ***Example for VM #2***:

```xml
  <cputune>
      <vcpupin vcpu="0" cpuset="4"/>
      <vcpupin vcpu="1" cpuset="5"/>
      <vcpupin vcpu="2" cpuset="6"/>
      <vcpupin vcpu="3" cpuset="7"/>
    </cputune>
```

## UEFI Booting (OVMF):

The installer framework supports portability of VMs configured for UEFI booting both using basic UEFI booting and UEFI booting with secure boot. 

Note: UEFI booting without using secure boot seems to work with the fewest potential problems. If you need UEFI but you don't specifically need secure boot just use basic UEFI booting.

The following `<os>` block shows how to enable (U)EFI booting. The important bit is `firmware="efi"` in the opening `<os>` tag. It is strongly recommended that when using UEFI booting you use `machine="pc-q35-X.Y"` (X.Y matches a supported version of the pc-q35 hardware platform which can be found by running: `virsh capabilities| grep pc-q35` (see the Machine Type and Version section covered earlier for more details)).

Example (UEFI only, no specified NVRAM file and no secure boot):

```xml
  <os firmware="efi">
    <type arch="x86_64" machine="pc-q35-6.2">hvm</type>
  </os>
```

In the case above, when the VM is first booted, an NVRAM file storing any custom EFI variables will be created in the `/var/lib/libvirt/qemu/nvram/` directory with the file name being `<vm_name>_VARS.fd`. If you want to preserve that NVRAM file you will need to update the `<os>` block in the VM's config XML to point to the file in one of two ways: 
  A)  Add a `<loader/>` and an `<nvram>` block pointing to the file in the portable location in the VM's directory (i.e. `/home/VMs/DEMO101/DEMO101-vm01/nvram/...`), manually create that new directory and move the NVRAM file into it. 
  or 
  B)  Add a `<loader/>` tag and an `<nvram>` block pointing to the file in the default location (`/var/lib/libvirt/qemu/nvram/...`) and let the backup scripts do the work of moving and updating the VM's config at backup time.

With basic UEFI booting, IF YOU DON'T SPECIFY THE NVRAM FILE IN THE VM'S CONFIG XML THE BACKUP SCRIPTS WILL NOT BACK IT UP!

Remember that if the VM has already been defined with Libvirt (virsh define) you will need to update both the portable copy of the VM's config XML and the live version (using `virsh edit` or XML view in Virt-Manager).

Example with NVRAM file in the VM's directory (with the assumtion that you used option "A" above ):

```xml
  <os firmware="efi">
    <type arch="x86_64" machine="pc-q35-6.2">hvm</type>
    <loader/>
    <nvram>/home/VMs/DEMO101/DEMO101-vm01/nvram/DEMO101-vm01_VARS.fd</nvram>
  </os>
```

If the NVRAM file is referenced in the VM's config XML, when the VM is backed up using either the `backup_lab_env.sh` or `backup_vm.sh` script, the backup scripts will check if the NVRAM file is in the VM's nvram subdirectry and if not will moved it from its default location into that subdirectory and update the VM's XML config file to point to the new portable location of the nvram file. 

TIP: If you are manually creating the VM's config XML file, before launching the VM, you can manually create the nvram subdirectory of the VM's directory and add the `<loader/>` tag and `<nvram><nvram/>` tag block to the VM's XML config before the VM is powered on and the nvram file will be created there initially. If you use Virt-Manager to create the VM, you will need to manually move the nvram file and update the VM's config XML (unless you want that to happen later when the VM is backed up using either `backup_lab_env.sh` or `backup_vm.sh` script).

If secure boot is required, when creating the VM's config XML, for the firmware/loader, select one of the `ovmf-x86_64-*suse*-code.bin` files. There are 3 files available and the following is a brief explatination for each file:

| File                            | Description                                                        |
| ------------------------------- | ------------------------------------------------------------------ |
| `ovmf-x86_64-suse-code.bin`     | Firmware with SUSE certificates (if in doubt, use this one)        |
| `ovmf-x86_64-suse-4m-code.bin`  | Firmware with SUSE certificates and more space for EFI variables   |
| `ovmf-x86_64-smm-suse-code.bin` | Firmware with SUSE certificates and System Management Mode support |

  The `*ms*-code.bin` files contain the Microsoft certificates and the `*opensuse*-code.bin` files contain the openSUSE certificates. 
  The `code.bin` files without any OS name in them don't contain any certificates and they may need to be added when the VM first boots (unless you are doing an install where they may be added for you). 

Note that when using secure boot the `firmware="efi"` is not in the opening `<os>` tag, rather a separate `<loader></loader>` section is added to the `<os>` block containing the bootcode (`ovmf*code.bin`) that will be used.

Example for secure boot with the OVMF binary in the default location and the NVRAM file copied to the VM's directory:

```xml
  <os>
    <type arch='x86_64' machine='pc-q35-6.2'>hvm</type>
    <loader readonly='yes' type='pflash'>/usr/share/qemu/ovmf-x86_64-suse-code.bin</loader>
    <nvram>/home/VMs/DEMO101/DEMO101-vm01/nvram/DEMO101-vm01_VARS.fd</nvram>
  </os>
```

When using secure boot, to maintain maximum portabilty, when the VM is backed up using either the `backup_lab_env.sh` or `backup_vm.sh` script, the OVMF binary will be copied into the VM's `nvram` subdirectory next to the NVRAM file and the `<loader><loader/>` tag block in the VM's config XML file will be updated to point to that copy of the binary. If you are manually creating that VM and its configuration you can manually copy the OVMF binary into the VM's nvram subdirectroy and create the `<loader><loader/>` tag block with it pointing to this file from the get go.

Example for secure boot with both the OVMF binary and the NVRAM file copied to the VM's directory:

```xml
  <os>
    <type arch='x86_64' machine='pc-q35-6.2'>hvm</type>
    <loader readonly='yes' type='pflash'>/home/VMs/DEMO101/DEMO101-vm01/nvram/ovmf-x86_64-suse-code.bin</loader>
    <nvram>/home/VMs/DEMO101/DEMO101-vm01/nvram/DEMO101-vm01_VARS.fd</nvram>
  </os>
```

## TPM Device:

The installer framework supports portability of VMs using a TPM device.

- To use TPM devices in Libvirt the **swtpm** RPM package must be installed in the host.
- When possible use TMP version 2.0 (TIS or CRB) (TPM 2.0 requires UEFI booting).

Example:

```xml
  <tpm model="tpm-tis">
    <backend type="emulator" version="2.0"/>
  </tpm>
```

When the VM is backed up using either the `backup_lab_env.sh` or `backup_vm.sh` script the TPM file for the VM will be copied from its default location (`/var/lib/libvirt/swtpm/VM_UUID/`) into a `tpm` subdirectory of the VM's directory. When the VM is restored or installed from the installer package the TPM file is copied back to the default location. (Unfortunatly it is not possible to edit the VM's XML config to tell Libvirt to look for the file in a different location than the default like you can with the UEFI nvram file.)

## Add Additional Unique Identifier to Disks:

An additional identifier can be added to disks in the VM's config xml file. As these identifiers are visible to the OS running in the VM they can be used to refer to disks in a persistent, consistent and predictable manner. The method for adding the additional unique identifiers differs between virtio and SCSI/ATA disks. 

**Disk Serial Numbers**:

Virtio disks can be assigned a serial number that will be discovered/presented by the OS in the same manner that the serial numbers of actual physical disks are discovered by the OS (`/dev/disk/by-id/<CONNECTION_PROTOCOL-SERIAL_NUMBER` - i.e. `/dev/disk/by-id/virtio-myserialnumber`). Serial numbers are freeform text up to 20 characters in length.

***Example***:

```xml
  <disk type="file" device="disk">
    <driver name="qemu" type="qcow2"/>
    <source file="/home/VMs/DEMO101/DEMO101-vm01/disk01.qcow2"/>
    <target dev="vda" bus="virtio"/>
    <serial>1234567890abcdef</serial>
    <address type="pci" domain="0x0000" bus="0x04" slot="0x00" function="0x0"/>
  </disk>
```

**World Wide Names (WWN)**:

SCSI/ATA disks can be assigned a WWN that will be discovered/presented by the OS in the same manner that the WWNs of actual physical disks/luns are discovered by the OS (`/dev/disk/wwn-WWIN` - i.e. `/dev/disk/by-id/wwn-0xfe00525400ef0101`). WWNs are a 16 digit hexadecemial number preceeded by 0x.

***Example***:

```xml
  <disk type="file" device="disk">
    <driver name="qemu" type="qcow2" cache="writeback"/>
    <source file="/home/VMs/DEMO101/DEMO101-vm01/disk03.qcow2"/>
    <target dev="sdb" bus="scsi"/>
    <wwn>0xfe00525400ef0101</wwn>
    <address type="drive" controller="0" bus="0" target="0" unit="1"/>
  </disk>
```

## Disk Image File Types:

For the main disks in a VM it is best to use the qcow2 disk image file type. Qcow2 disk image files can be created as sparse files or can be created non-sparse. To manually create a 100GB sparse qcow2 disk image file use the following command:

```bash
> qemu-img create -f qcow2 disk01.qcow2 100G
```

- Raw disk image files are discouraged as they are not sparse by nature meaining they will take up more disk space unnecessarily. They also cannot be snapshoted.
  - ISO images are by nature raw disk image files. These are OK to use though as they are readonly.

## Sparsifying Disk Images:

Before creating the lab environment installer package it is recommended that you sparsify the disks in your VMs so the installer package will be smaller. This can be done using the `sparsify-vm-disks.sh` tool in `/usr/local/bin/`. (This is part of our standard image but can also be downloaded from the [lab_env_tools](https://github.com/roncterry/lab_env_tools) Github repository. 

- This will sparsify each of the disks in a VM's directory.
- The original disk will be renamed and a new sparsified version will be created using the disks original file name. 
  - You will need enough free space for the new sparse disk to be created. This could mean as much free space as the size of the original disk.
- You must manually delete the renamed copies of the original disks once you have verified that the VM boots successfully.
- **DO NOT** sparsify disk with snapshots! Sparsifying a disk with snapshots will break the snapshots!

Example commands:

```bash
> cd /home/VMs/DEMO101/DEMO101-vm01 
> sparsify-vm-disks.sh 
```

## Snapshots:

The installer framework supports making VM snapshots portable. 

However, as many of our partners take our lab environments and convert them for different virtualization platforms we should be cautious when creating VMs that have pre-created snapshots. If a beginning snapshot is desired for roleback or other reasons it is probably best to instruct the student to create these snapshots as part of the initial exercise.

- Always snapshot VMs in the powered off state. Creating snapshots when VMs are running causes problems when the physical CPU of the host is different than the host the snapshot was created on.

- Sparsifying a disk when it has snapshots **will break** the snapshots! Always remove any snapshots before sparsifying a disk.

When the VM is backed up using either the `backup_lab_env.sh` or `backup_vm.sh` script the snapshot XML definition files are copied to a snapshots subdirectory of the VM's directory. When the VM is restored or installed using the installer framework the snapshot XML files are updated with the VM's new UUID and are restored.

## Virtual Networks:

Generally speaking NATed virtual networks will work for most lab environments. If you don't want Libvirt to provide DHCP addresses to the VMs on your virtual network (i.e. you will be using your own DHCP server in a VM) you will need to define the network without a DHCP range.

- Virtual network definition files are placed in the install package's `config/libvirt.cfg/` directory.
- The naming convention for virtual network definition files is: `<virtual_network_name>.xml`

***Example without DHCP range*** (filename: `demo101-net.xml`):

```xml
  <network>
    <name>demo101-net</name>
    <forward mode='nat'>
      <nat>
        <port start='1024' end='65535'/>
      </nat>
    </forward>
    <bridge name='demo101-net' stp='on' delay='0'/>
    <mac address='52:54:00:ff:ff:00'/>
    <domain name='demo101-net'/>
    <ip address='10.255.255.1' netmask='255.255.255.0'>
    </ip>
  </network>
```

***Example with DHCP range*** (filename: `demo101-net.xml`):

```xml
  <network>
    <name>demo101-net</name>
    <forward mode='nat'>
      <nat>
        <port start='1024' end='65535'/>
      </nat>
    </forward>
    <bridge name='demo101-net' stp='on' delay='0'/>
    <mac address='52:54:00:ff:ff:00'/>
    <domain name='demo101-net'/>
    <ip address='10.255.255.1' netmask='255.255.255.0'>
      <dhcp>
        <range start='10.255.255.101' end='10.255.255.249'/>
      </dhcp>
    </ip>
  </network>
```

It is a best practice to set the `bridge name=` and `domain name=` to be the same as the network name (see examples above). This will need to be done manually if you create the virtual network using Virt-Manager. (Note: You can use the XML view in Virt-Manager to make these changes if you first stop the virtual network.)

## VM Virtual Network Interfaces:

If desired the MAC address of the VMs' network interfaces can be manually specified. This can be helpfull when trying to identify VMs or statically set VM's IP addresses via DHCP reservations. A standard MAC address convention can be followed for all VMs in a course's lab environment.

***Example addressing convention***:

```
    |-Range assigned to Libvirt by the IEEE (52:54:00)
    |
    |     |-Manually assigned - Corresponds to the course. All VMs in the course will have the same (i.e. course DEMO101=ff)
    |     |
    |     |  |-Manually assigned - Corresponds to the VM in the course (i.e. VM #1=01, VM #2=01, VM #3=03, etc.)
    |     |  |  
    |     |  |  |-Manually assigned - Corresponds to the interface number in the VM (i.e. eth0=01, eth1=02, eth2=03, etc.)

--------|--|--|--
52:54:00:ff:01:01
```

***Example*** - **DEMO101-vm01** eth0:

```xml
<mac address='52:54:00:ff:01:01'/>
```

***Example*** - **DEMO101-vm01** eth1:

```xml
<mac address='52:54:00:ff:01:02'/>
```

***Example*** - **DEMO101-vm02** eth0:

```xml
<mac address='52:54:00:ff:02:01'/>
```

The MAC address of the virtual network(s) used in a course lab environment can follow this same convention. The network would use the same course address (`ff` in the examples above) and would use a unique address for the second to last field and use `00` for the last field. (See the virtual network examples in the **Virtual Networks** section.)

## Storage Pools:

The installer framework supports the automatic creation of storage pools. Both general purpose pools and VM specific pools can be defined.

Libvirt uses storage pools to find block devices used as VM disks. 

- General purpose storage pools can be useful. For example, if an ISO needs to be attached to a VM during the course of the lab exercises a predefined storage pool for the directory containing the ISO image can make it easier for the learner to find and attach the ISO to a VM. 
- The storage pool definition is placed in the installer package's `config/libvirt.cfg/` directory along with the virtual network definintion XML files. 
- The name naming convention for storage pool definition files is: `<pool_name>.pool.xml`

The following is an example of a predefined storage pool for the ISOs for a course:

***Example*** (filename: `DEMO101-iso.pool.xml`):

```xml
 <pool type='dir'>
    <name>DEMO101-iso</name>
    <capacity unit='bytes'>0</capacity>
    <allocation unit='bytes'>0</allocation>
    <available unit='bytes'>0</available>
    <source>
    </source>
    <target>
      <path>/home/iso/DEMO101</path>
    </target>
  </pool>
```

A storage pool can be defined for a VM's directory and that storage pool definition can be placed in the VM's directory along with its VM XML definition. 

- The naming convention for a VM specific storage pool definition file is: `<vm_name>.pool.xml`

The following is an example for a VM named **DEMO101-vm01**:

***Example*** (file name: `DEMO101-vm01.pool.xml`):

```xml
 <pool type="dir">
    <name>DEMO101-vm01</name>
    <capacity unit="bytes">0</capacity>
    <allocation unit="bytes">0</allocation>
    <available unit="bytes">0</available>
    <source>
    </source>
    <target>
      <path>/home/VMs/DEMO101/DEMO101-vm01</path>
    </target>
  </pool>
```

# Known Issues:

When creating a VM from scratch using Virt-Manager an `<audio>` tag (i.e. `<audio id="1" type="spice"/>`) is being added that causes the VM to not be able to be defined or run on older versions of the standard image. This tag is not requored and must be removed from the VM's config XML file. When removing the tag ensure that this `<audio>` tag is not being references in the `<sound>` section. If it is then also remove the reference from there. The `<sound>` section should only specify the model and a PCI device address.
