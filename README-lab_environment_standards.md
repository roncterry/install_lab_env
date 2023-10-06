# Introduction to the Lab Environment Standards

This guide describes the lab environment standards used by the SUSE Training organization. The reasons for these standards are many but essentially boil down to making sure we have a consistent way of doing things so that it will be easier to consume by the end user and easier to develop by the course developers. An added benefit to following these standards is that there are a number of tools that have and will be created that make developing and working with lab environments much quicker and easier. A list of these tools will be maintained at the end of this document and there may be additional documents that provide greater detail on using these tools.

# Usernames and Passwords

The usernames and passwords that exist in the lab VMs are at the discretion of the course developer based on the requirements for the courses. However, it is strongly recommended that the following two accounts exist in the VMs using the usernames and passwords provided (though the use of ‘geeko’ is starting to be discouraged).

**root user account:**

| Username | Password |
| -------- | -------- |
| root     | linux    |

**Regular user account:**

| Username | Password | UID  |
| -------- | -------- | ---- |
| tux      | linux    | 1000 |

# Networking

## Subnets and Network Names

The configuration of the networking in a lab environment is left to the discretion of the course developer based on the requirements for the course. The virtual network IP addresses should rcome from the network address blocks reserved for private addresses (i.e. `192.168.0.0-192.168.255.255/24`,`172.16.0.0-172.31.255.255/16`, `10.0.0.0-10.255.255.0/8`). However, it is strongly recommended that commonly used private subnets (i.e. `192.168.1.0/24`, `10.0.0.0/24`, etc.) be avoided as they will collide with addresses on physical networks, causing the virtual networks to not function correctly. It is also recommended that the default Libvirt network (named `default` with a subnet of `192.168.100.0/24`) be avoided. The name of the virtual network should be something that is descriptively relative to the course. 

(*Example*: The **main** network in the SLE201 cloud course could be named **sle201-net**)

## Virtual Bridge Names

Because it is possible that multiple lab environments can be installed on a single lab machine at a time, there is a possibility of naming collisions between the virtual networks. It is strongly recommended that the network XML definition be edited so that the virtual bridge created by Libvirt, when the network is created, be named using a more descriptive name. The recommendation is to use the name of the virtual network as the name of the bridge.

**_Example_**: 

```
<name>sle201-net</name>
...
  <ip address=’192.168.124.1’, netmask=’255.255.255.0’> 
  <bridge name=’sle201-net‘ … />
...
```

For things like SUSECON sessions, because you can’t really know what the other sessions’ virtual networks are, it is suggested that you use a naming convention that includes your session ID (Example: **HO77572**). In the case where your session requires multiple networks, append the network number to the session ID separated by a **_** (Example: **HO77572_1** for the first network, **HO77572_2** for the second network, etc.).

Note: There is a character number limit for the names of these bridge names (16 characters max?) so they should be abbreviated if possible.

## Network Definition XML File

The Libvirt virtual network definition XML file should be provided. 

If you wish to manually create these networks, example network definition XML files are provided in the Templates directory.

If you use Virt-Manager to create the virtual networks, this XML file can be created from these virtual networks using the following command:

```
virsh net-dumpxml <NETWORK_NAME> > <NETWORK_NAME>.xml
```

The name of the file should be the name of the `<NETWORK_NAME>.xml` where `<NETWORK_NAME>` = the name of the virtual network (i.e. **sle201-net**).

The name of the **network** should match the name of the **bridge** and the name of the **domain** in the config file.

If the virtual networks are created using Virt-Manager they will not adhere to the naming standard and, at minimum, the bridge name must be changed. Unfortunately, this is difficult to do on an existing virtual network. It is often easiest to dump out the XML definition to a file, edit the file, stop and delete the existing virtual network then redefine and enable the network from the edited XML definition file.

The following is an example of one of these network definition XML files:

**_File name_**: **sle201-net.xml**

```
<network>
  <name>sle201-net</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='sle201-net' stp='on' delay='0'/>
  <mac address='52:54:00:20:52:73'/>
  <domain name='sle201-net'/>
  <ip address='192.168.124.1' netmask='255.255.255.0'>
  </ip>
</network>
```

## Multi Lab Machine Environments

It is possible to spread a lab environment for a single student across multiple lab machines. When doing this it will typically require a different networking configuration to allow the VMs to communicate with each other when they are running on different lab machines. This different networking environment typically consists of a secondary network connection between the lab machines with separate VLANs with corresponding Linux bridges attached to them running across this secondary network. These Linux bridges take the place of the Libvirt virtual networks that the VMs are typically connected to.

When providing for this multi lab machine environment, each VM will require an addition XML definition file that specifies these bridges instead of Libvirt networks. Both XML definition files are required (single lab machine and multi lab machine versions) and should reside in the VM specific directory in `/home/VMs/<COURSE_ID>/` (i.e. `/home/VMs/<COURSE_ID>/<NAME_OF_VM>/`).

(Where **<COURSE_ID>** is the course ID number).

To have the VM connect to these Linux bridges on the VLANs rather than the Libvirt networks, you edit the VM’s secondary multi lab machine specific XML definition (typically named `<NAME_OF_VM>-multi_lm.xml`). In the network interface descriptions, change "network" to ‘bridge”. See the following example configuration snippets for the configuration changes. The values that need to be modified are bolded.

Example with Libvirt networks (original VM definition file):

```
...
    <interface type=network>
      <mac address='52:54:00:fd:d9:3a'/>
      <source network='cloud-admin'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>
...
```

Example with Linux bridges (secondary multi lab machine VM definition file):

```
...
    <interface type=bridge>
      <mac address='52:54:00:fd:d9:3a'/>
      <source bridge='cloud-admin'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>
...
```

The VLANs and Linux bridges attached to them that are used for these cross lab machine virtual networks can be created with YaST or can be automatically created using the lab environment installation framework.

# Virtual Machines

When creating virtual machines, the following guidelines should be followed:

## Virtual Machine Names

Because it is possible (common?) to have VMs for different courses on a lab (development) machine at the same time the VMs must be named in a way that will both eliminate the possibility of name collisions and identify which course the VM is related to. For this purpose, the names of the VMs should be: `<COURSE_ID>-<VM_NAME>`

(In this document this is referenced as **<NAME_OF_VM>**)

Example: **SLE201-server01** 

(For SUSECON session the `<COURSE_ID>` is the SUSECON Session ID.)

For consistency and so that tools such as the [Installer Framework](https://github.com/roncterry/install_lab_env) can be used, the name of the VM, the name of the VM's directory, the name of the VM's main configuration file along with the names of any other VM specific configuration files must match. This is described in more detail in the **Virtual Machine Directory** section.

## Virtual Machine Directory

The base directory for all VMs is: **/home/VMs/** 

In that directory a subdirectory will be created for a specific course which will be named: `<COURSE_ID>`

Example: `/home/VMs/<COURSE_ID>/`

All files related to a virtual machine must exist in a subdirectory of the <COURSE_ID> directory and the name of the VM's directory must be as described in the Virtual Machine Names section above. 

Example: `/home/VMs/<COURSE_ID>/<NAME_OF_VM>/` 

The files in the individual virtual machine's directory should include at least the following:

* Virtual machine XML definition file(s)
* Disk image files used by the VM

Example Virtual Machine Directory Structure:

```
/home/VMs/<COURSE_ID>/<NAME_OF_VM>/
                                  |-<NAME_OF_VM>.xml
                                  |-<NAME_OF_VM>-multi_lm.xml
                                  |-disk01.qcow2
                                  |-<NAME_OF_VM>.pool.xml
                                  |-<NAME_OF_VM>.vbmc 
```

Note: If you use Virt-Manager to create the new VM, it is easiest to manually create the VM directory and the disk image files in the directory first and then specify the disk image file during the installation. How to do this will be covered below.

## Virtual Machine XML Definition Files

The virtual machine’s XML definition file should be named `<NAME_OF_VM>.xml` (where `<NAME_OF_VM>` is the name of the virtual machine as defined in the **Virtual Machine Names** section).

When creating new virtual machines from scratch, without using Virt-Manager, templates are available in the Templates directory.

If you use Virt-Manager to create the new VMs it is best if you create them with their required named (`<COURSE_ID>-<VM_NAME>`) and create their disk images in the required directory (i.e. `/home/VMs/<COURSE_ID>/<NAME_OF_VM>`). The virtual machine’s XML definition file can then be exported using the following command:

```
virsh dumpxml <NAME_OF_VM> > /home/VMs/<COURSE_ID>/<NAME_OF_VM>/<NAME_OF_VM>.xml
```

After creating the VM’s XML definition file from an existing VM, you must edit the file and remove the `<uuid>` section. Other sections such as the `<cpu>` section, `<disk>`, sections, `<interface>` sections, etc. must be updated following the standards specified in the **Libvirt_Requirements_and_Best_Practices** document.

## Virtual Machine Disks

Virtual machine disks should be of format QCOW2 when at all possible. The size of the disks should be as small as possible to meet the requirements of the course. (This helps keep the overall size of the student media smaller).

The disk image files must reside in the VM’s directory (`/home/VMs/<COURSE_ID>/<NAME_OF_VM>/`). It is important to note that if you are creating the VM using Virt-Manager, there is no intuitive way to create the images without an already existing storage pool. (You must enter the full path including the name of the disk image in the field next to the Manage button.)  It is often easier to first manually create the disk image(s) in that directory using the **qemu-img** command and then, in Virt-Manager, select it as an existing disk image when creating the VM.

Example **qemu-img** command: 

```
qemu-img create -f qcow2 /home/VMs/<COURSE_ID>/<NAME_OF_VM>/disk01.qcow2 20G
```

Regarding virtual machine disk image naming. As disk images will only be used by a single VM, and because they will always reside in the VM's directory, the names of the disk images do not need to contain the VM name. In fact, it can make things easier if you use simple named like `disk01.qcow2` or descriptive named like `repos.qcow2`. Doing this will also enable the use of some of the lab environment creation and management tools and scripts.

Regarding the file permission/ownership of the virtual machine disk images. When using Virt-Manager to create a VM and its disk images, the default behavior is for the disk image file(s) to be owned by root and the permissions to be 600. This will cause problems later on when archiving the VMs for distribution.  It is best to change the files to be owned by your user and primary group and the permission to be 644.

# Storage Pools

## Virtual Machine Storage Pools (Optional)

Defining storage pools for each VM's directory can make working with the VMs easier, particularly if you are running different VMs on different lab machines and accessing them remotely using Virt-Manager. The name of these VM directory specific pool definition file should be `<NAME_OF_VM>.pool.xml`. The structure of a VM directory specific storage pool XML file is as follows:

```
<pool type='dir'>
  <name>NAME_OF_VM</name>
  <capacity unit='bytes'>0</capacity>
  <allocation unit='bytes'>0</allocation>
  <available unit='bytes'>0</available>
  <source>
  </source>
  <target>
    <path>/home/VMs/COURSE_ID/NAME_OF_VM</path>
  </target>
</pool>
```

## Common Directory Storage Pools (Optional)

If you are using a common directory for files used by multiple VMs such as ISO images, it is best to define storage pools for these common directories as well. The name of the pool definition files for these common directories must be `<COURSE_ID>-<POOL_NAME>.pool.xml`. The following is an example for a common ISO directory for a course:

```
<pool type='dir'>
  <name>COURSE_ID-iso</name>
  <capacity unit='bytes'>0</capacity>
  <allocation unit='bytes'>0</allocation>
  <available unit='bytes'>0</available>
  <source>
  </source>
  <target>
    <path>/home/iso/COURSE_ID</path>
    <permissions>
      <mode>0755</mode>
      <owner>1000</owner>
      <group>100</group>
    </permissions>
  </target>
</pool>
```

If you are using the [Installer Framework](https://github.com/roncterry/install_lab_env) to install the VMs in your lab environment there are specific directories that you must place these pool definition files in:

* For VM directory specific pools you must place the pools definition files in the VM/s directly along with its other configuration and disk images. It must be named following the standard listed above. The pools will be created and activated when the VM is installed and they will be removed when the VM is removed.

* For the common directory pools the files must be placed in the libvirt.cfg directory of the installer package (i.e. `<COURSE_ID>/config/libvirt.cfg/` - see the [Installer Framework](https://github.com/roncterry/install_lab_env) for more details). These pools will be created and activated when the lab environment is installed and removed when it the lab environment is removed.

# ISO Images

If your virtual machines require ISO images or if you want to provide ISO images to your students, the following guidelines should be followed:

## ISO Image Directory

If an ISO image will only be used by a single VM, the ISO image must reside in the VM’s directory along with the other disks belonging to that VM (see Virtual Machine Directory above).

If an ISO image will be used by multiple VMs it must be placed in a common directory so that duplication of data can be reduced. The directory defined for this is:  `/home/iso/<COURSE_ID>` 

*Example*: `/home/iso/<COURSE_ID>/my-iso.iso`

# Virtual BMC Devices (Optional)

Virtual BMC devices can be useful if you need to emulate a base machine controller (BMC, DRAC, ILO, etc.) for  VM. The VirtualBMC project maintains software that does this for Libvirt VMs. In openSUSE this is installed using the **python3-virtualbmc** package.

## Virtual Machine Virtual BMC Devices

If you are using the [Installer Framework](https://github.com/roncterry/install_lab_env) to install your the VMs in your lab environment, and you wish to have virtual BMC devices created for your VM when it is registered with Libvirt, then create a file in the VM's directory named <NAME_OF_VM>.vbmc that contains the virtual BMC device description. An example of this file can be found in the [vbmcctl](https://github.com/roncterry/vbmcctl) project (vbmcctl.cfg.example). The **vbmcctl** command must be installed on the host machine for this functionality to work. 

# Cloud Images (---obsolete---)

If your lab environment requires cloud images to be used or if you want to provide cloud images to your students, the following guidelines should be followed:

## Cloud Image Directory

All cloud images related to a course should reside in a single directory named: `/home/images/<COURSE_ID>` 

*Example*: `/home/images/<COURSE_ID>/my-cloud-image.qcow2` 

# Lab Environment Related Tools

## Lab Machine Image

A standard lab machine image based on openSUSE is provided for developing and running lab environments. This lab machine image is preconfigured for Libvirt/KVM to be run as a regular user. It also has a number of other extras preconfigured such as additional GNOME Shell extensions and additional scripts for lab machine, lab environment and VM management. GNOME is the default desktop environment.

A page containing the instructions for installing this standard image can be found here: https://github.com/roncterry/configure-as-labmachine

## Lab Environment Installer Framework

There is a lab environment installer framework that can be used to create installer packages for lab environments. These installer packages make installing, and equally important, removing lab environments much easier. Using the Installer Framework also allows for lab environments to be compartmentalized theoretically enabling multiple lab environments to be installed simultaneously and have them not step on each other.

There is a document named [Lab_Environment_Installer_Framework - README.md](https://github.com/roncterry/install_lab_env/(README.md) that covers how to use the Lab Environment Installer Framework in greater detail.

## Scripts

There are a number of additional scripts that have been developed that can help make developing, modifying or otherwise working with lab environments easier. These scripts are typically included in the lab machine image (in `/usr/local/bin/`). These scripts are outlined here:

### backup_lab_env.sh

**Intro**:

This script is part of the Lab Environment Installer Framework but is also provided as part of the standard lab machine scripts because it is usable and useful outside of the Framework as well.

This script can be used to back up the current state of a currently installed entire lab environment. For the backup, it creates an installer package (using the Lab Environment Installer Framework) for the lab environment that includes archives of the current state of the VMs, ISO images, cloud images, course files, scripts, etc. These backups are created in `/install/courses/` and the directories that map to the backup/installer package are named using the following format: 

`<COURSE_ID>-backup-<DATE_STAMP>.<UNIX_TIME_STAMP>` 

**Usage**:

```
backup_lab_env.sh <course_id> [<archive_format>] 
```

**Detailed Description**:

When the individual VMs are backed up they are backed up in the same manner as the `backup_vm.sh` script (listed below) except the md5sums file is not created.

By default, VM archives are created using p7zip with the compression format of LZMA2. This can be overridden at the command line supplying the `<archive_format>` as the last argument. 

The supported archive formats are:

| Archive Format | Description                                                |
| -------------- | ---------------------------------------------------------- |
| **7zma2**      | p7zip with LZMA2 compression split into 2G files (default) |
| **7z**         | p7zip with LZMA compression split into 2G files            |
| **7zcopy**     | p7zip with no compression split into 2G files              |
| **tar**        | tar archive with no compression and not split              |
| **tgz**        | gzip compressed tar archive and not split                  |
| **tbz**        | bzip2 compressed tar archive and not split                 |
| **txz**        | xz compressed tar archive and not split                    |

The p7zip formats are **strongly recommended** because they split the archive into smaller chunks that can reside on a FAT filesystem that is used by default when creating student media flash drives.

Because this script creates, as its backup, an installer package using the Lab Environment Installer Framework you can also use the script to create the initial installer package for a lab environment. As long as the VMs and ISO image (and cloud images) are in the appropriate directory structure as described earlier all you need to do is create a directory `~/scripts/<COURSE_ID>/` that contains the following files from the Installer Framework in the following directory structure (this matches the installed directory structure created when installing a course):

```
~/scripts/<COURSE_ID>/
                     |-install_lab_env.sh
                     |-remove_lab_env.sh
                     |-backup_lab_env.sh
                     |-restore-virtualization-environment.sh
                     |-config/
                             |-lab_env.cfg
                             |-custom-functions.sh
                             |-custom-install-functions.sh
                             |-custom-remove-functions.sh
                             |-libvirt.cfg/
                                          |-(your libvirt network XML definition files)
```

Once this directory structure is created, simply running the command:

```
 backup_lab_env.sh <COURSE_ID> 
```

will create a usable installer package in the `/install/courses/` directory.

To (re)install the course the `install_lab_env.sh` script in the lab environment installer package must be run. 

### install_lab_env.sh

**Intro**:

This script is part of the Lab Environment Installer Framework. It is not provided as part of the standard lab machine scripts as it is specific to a lab environment installer package. It is discussed here because it directly applies to the output created by the `backup_lab_env.sh` script and it performs operations included in the `restore_vm.sh` script.

This script is used to install a lab environment from a lab environment installer package. During the installation the VMs will be restored in the same manner that the `restore_vm.sh` script restores them.

The script is run from within the course lab environment installer directory.

**Usage**:

```
install_lab_env.sh 
```

## backup_vm.sh

**Intro**:

This script is part of the Lab Environment Installer Framework but is also provided as part of the standard lab machine scripts because it is usable and useful outside of the Framework as well.

This script can be used to backup the current state of a currently installed individual virtual machine. 

The VM you are backing up must be in your current working directory.

**Usage**:

```
backup_vm.sh <NAME_OF_VM> [<archive_format>] 
```

**Detailed Description**:

Before the backup archive is created the following will be done:

- If the VM has snapshots, the snapshot definition files will be moved into a `snapshots` subdirectory of the VM's directory and the VMs definition file in the VM's directory will be updated to point to the snapshot definition files in their new location.

- If the VM uses UEFI booting, the EFI variables file will be moved into an `nvram` subdirectory of the VM's directory and the VM's definition file in the VM's directory will be updated to point to the new location of this file.
  
  (IMPORTANT: The current registered version of the VM will NOT be updated to point to these files (snapshots and EFI variables) an must either be manually updated using `virsh edit` or the VM must be unregistered (`virsh delete`) and reregistered (`virsh define <path_to_vm_definition_file>`) for those files to be used.)

- If the VM has a TPM device, the TMP file will be copied into a `tpm/<tpm_version>/` subdirectory of the VM's directory. As TMP uses an external application (`swtpm`) to provide the TPM device and this location is not specified in the VM's definition file this cannot be updated in the VM's definition file. When restoring the VM this file must be coped back into the location where the `swtpm` application can access it (i.e. `/var/lib/libvirt/swtpm/<VM_UUID>/`). (Note: If you use the `restore_vm.sh` or `install_lab_env.sh` script to restore/install the VM they will ensure the TPM file gets copied there for you.()

The backup archive of the VM will then contain these snapshot definition, EFI variable and TMP files along with the other VM config files and disk images.

By default, VM archives are created using p7zip with the compression format of LZMA2. This can be overridden at the command line supplying the `<archive_format>` as the last argument.

The supported archive formats are:

| Archive Format | Description                                                |
| -------------- | ---------------------------------------------------------- |
| **7zma2**      | p7zip with LZMA2 compression split into 2G files (default) |
| **7z**         | p7zip with LZMA compression split into 2G files            |
| **7zcopy**     | p7zip with no compression split into 2G files              |
| **tar**        | tar archive with no compression and not split              |
| **tgz**        | gzip compressed tar archive and not split                  |
| **tbz**        | bzip2 compressed tar archive and not split                 |
| **txz**        | xz compressed tar archive and not split                    |

The p7zip formats are **strongly recommended** because they split the archive into smaller chunks that can reside on a FAT filesystem that is used by default when creating student media flash drives.

The output of the script will be an archive set and an md5sums file for all the files in the set.

## restore_vm.sh

**Intro**:

This script is part of the Lab Environment Installer Framework but is also provided as part of the standard lab machine scripts because it is usable and useful outside of the Framework as well.

This script can be used to restore a backup of a virtual machine created with the `backup_vm.sh` script.

You must be in the course directory (i.e.` /home/VMs/<COURSE_ID>/`) of the course that the VM belongs to when restoring the VM.

**Usage**:

```
restore_vm.sh <VM_ARCHIVE> [extract_only] 
```

**Detailed Description**:

When the restoring the VM the script extracts the backup archive of the VM in the current working directory (which should be the course directory that the VM belongs to (i.e. `/home/VMs/<COURSE_ID>/`) and then does the following:

- Registers the VM with Libvirt (`virsh define <VM_DEFINITION_FILE>`).

- Updates the snapshot definition(s) with the VM's new UUID and defines the snapshots (`virsh snapshot-create <SNAPSHOT_DEFINITION_FILE> --recreate`).

- Copies the TMP file into the location that `swtmp` expects it to be (`/var/lib/libvirt/swtpm/<VM_UUID>/`)

If you run the script with the `extract_only` argument the backup archive will be extracted and only the configuration updates that don't require the VM to be registered with Libvirt will be applied (Note: Operations that are NOT performed include snapshot defining and TPM restore). You will then need to run the following command for the skipped operations to be performed: `restore_vm.sh <VM_DIRECTORY>`

### create-archive.sh

**Intro**:

This scripts create an archive of a specified directory or archives of a comma delimited list of specified directories (one archive per directory in the list). A file containing md5sums of the files corresponding to the archive(s) will also be created (one md5sums file per archive). This should be run from the parent directory that contains the directories that you want to archive. 

This can be particularly useful if you need to create a new archive for a VM that was just updated and insert that VM’s archive file(s) into an already existing installer package without having to rebuild the entire installer package. 

**IMPORTANT**: The `create_archive.sh` script **WILL NOT** backup snapshot definition files, the EFI variables file or the TMP file.

**Usage**:

```
create-archive.sh <directory>[,<directory>,...] [<archive_format>] 
```

**Detailed Description**:

By default archives are created using p7zip with the compression format of LZMA2. This can be overridden at the command line using the `<archive_format>`. The supported archive formats are:

| Archive Format | Description                                                |
| -------------- | ---------------------------------------------------------- |
| **7zma2**      | p7zip with LZMA2 compression split into 2G files (default) |
| **7z**         | p7zip with LZMA compression split into 2G files            |
| **7zcopy**     | p7zip with no compression split into 2G files              |
| **tar**        | tar archive with no compression and not split              |
| **tgz**        | gzip compressed tar archive and not split                  |
| **tbz**        | bzip2 compressed tar archive and not split                 |
| **txz**        | xz compressed tar archive and not split                    |

### create-vm-archives.sh

**Intro**:

This scripts create archives of all VM directories inside a course directory. This should be run from inside the course VM directory (i.e. `/home/VMs/SLE201/` for a course named SLE201). 

**IMPORTANT**: Like with the `create_archive.sh` script, the `create-vm-archives.sh` script **WILL NOT** backup snapshot definition files, the EFI variables file or the TMP file.

**Usage**:

```
create-vm-archives.sh [<archive_format>] 
```

**Detailed Description**:

By default VM archives are created using p7zip with the compression format of LZMA2. This can be overridden at the command line using the `<archive_format>`. The supported archive formats are:

| Archive Format | Description                                                |
| -------------- | ---------------------------------------------------------- |
| **7zma2**      | p7zip with LZMA2 compression split into 2G files (default) |
| **7z**         | p7zip with LZMA compression split into 2G files            |
| **7zcopy**     | p7zip with no compression split into 2G files              |
| **tar**        | tar archive with no compression and not split              |
| **tgz**        | gzip compressed tar archive and not split                  |
| **tbz**        | bzip2 compressed tar archive and not split                 |
| **txz**        | xz compressed tar archive and not split                    |

### change-vm-disk-path.sh

**Intro**:

This script allows you to change the paths to the disks in the Libvirt XML VM definition files for all VMs in a course directory. This is particularly useful if you have changed the name of the course directory, the name of the VM directory or have copied VMs from existing course into a new course.

**Usage**:

```
change-vm-disk-path.sh <course_vm_directory> <new_vm_directory_path>
```

**Detailed Description**:

For example, if I have a course named SLE201, according to the standards specified previously, all the VMs for that course should exist in a `/home/VMs/SLE201/` directory. Each of the VMs should be in their own directory (i.e. `/home/VMs/SLE201/SLE201-server1/`, `/home/VMs/SLE201/SLE201-server2`, etc.) and those VM directories should contain the disk image for that MV as well as a Libvirt XML VM definition file. The VM definition files should be named the same as the VM directory (i.e. `/home/VMs/SLE201/SLE201-server1/SLE201-server1.xml`, etc.). This script updates the path for the disk images in these VM definition files.

### host-sshfs-dirs.sh

**Intro**:

This script uses sshfs to mount the standard course related directories from the host machine into a VM running on the host.

Usage:

```
host-sshfs.dirs.sh mount|umount|list
```

**Detailed Description**:

This script uses sshfs to mount the following directories on the host onto the same directories inside a VM running on the host:

*/home/VMs
/home/iso
/home/images
/home/tux/scripts
/home/tux/course_files
/home/tux/pdf*

The idea is that you can run a VM for use as the "management workstation" and in the VM you will have access to all of the files that were installed onto the host machine as part of the lab environment.

The command **host-sshfs-dirs.sh mount** must be run each time you reboot the VM as the mounts are not persistent.

The command **host-sshfs-dirs.sh umount** will manually unmount the directories mounted with the mount option.

The command **host-sshfs-dirs.sh list** will display a list of directories currently mounted by the **host-sshfs-dirs.sh** command.

### reset-vm-disk-image.sh

**Intro**:

This script resets a VMs disk image in one of two ways: 

- First, if the disk image has snapshots, it reverts the disk back to the first snapshot and removes all other snapshots. 

- Second, if the disk doesn’t have snapshots, it deletes the disk image file and creates a new empty disk image file of the same type and size in the original file’s place.

Usage:

```
reset-vm-disk-image.sh <vm_dir> 
```

**Detailed Description**:

**WARNING** - This can be dangerous. It was designed to quickly reset empty VMs so that they can be reinstalled.

### sparsify-vm-disks.sh

**Intro**:

This script uses the virt-sparsify command to sparsify all of the disks for a VM. You must run this script from within a VM's directory (where the VM's disk image reside). It first renames the original disk image file and then created a sparse copy of that disk using the disk image file's original file name.

**WARNING** - You must have enough space on the host systems filesystem to hold the full size of the VM's disk while it is being sparsified. (It operates on only one of the VM's disks at a time so you don't have to have enough free space for all of the VM's disk at once).

Usage:

```
sparsify-vm-disks.sh 
```

**Detailed Description**:

**WARNING** - This can be dangerous. It was designed to quickly reset empty VMs so that they can be reinstalled.

### backup-homedirs.sh

**Info**:

This script backups up the home directories of either all users on a machine or a specified user or a list of users. The backups are created in the `/home/backups/` directory as .tgz files.

It is particularly useful to run this command right after a machine has been installed to get clean backups of users’ home directories before the machine gets used.

**Usage**:

```
backup-homedirs.sh [<username> [<username> …]]*
```

### restore-homedirs.sh

**Info**:

This script restores backed up the home directories created by the **backup-homedir.sh** script. The script expects the backups to be .tgz files in the `/home/backups/` directory.

It is particularly useful to run this command right after a machine has been used by someone that has made significant changes to user’s environment such and keyboard layout, language, etc. It can also be useful when you want a known clean version of a home directory quickly..

**Usage**:

```
restore-homedirs.sh [<username> [<username> …]]
```

### remove-all-vnets.sh

**Info**:

This script removes **all** Libvirt virtual networks that have been defined. This can be useful if you want to clean up a lab machine that has had lab environments installed on it that were not cleanly removed.

**Usage**:

```
remove-all-vnets.sh
```

### remove-all-vms.sh

**Info**:

This script removes **all** Libvirt virtual machines that have been defined. This can be useful if you want to clean up a lab machine that has had lab environments installed on it that were not cleanly removed.

**Usage**:

```
remove-all-vms.sh
```

### cleanup-libvirt.sh

**Info**:

This script removes **all** Libvirt virtual machines and virtual networks that have been defined. This can be useful if you want to clean up a lab machine that has had lab environments installed on it that were not cleanly removed.

**Usage**:

```
cleanup-libvirt.sh
```

### remove-all-courses.sh

**Info**:

This script attempts to remove all courses that are currently installed that were installed using the Lab Environment Installer Framework. It does this by running all **remove_lab_env.sh** scripts for all courses found in `~/scripts/`.

**Usage**:

```
remove-all-courses.sh
```

### reset-lab-machine.sh

**Info**:

This script, as the name suggests, attempts to reset a lab machine by running the following scripts:

```
remove-all-courses.sh
remove-all-vms.sh
remove-all-vnets.sh
restore-homedirs.sh ${LAB_USER}
```

It should clean off all installed courses as well as any Libvirt VMs and Libvirt virtual networks that were manually created or not cleaned up by course removal scripts. When that is done, if a backup was made of the **${LAB_USER}** (by default **tux**) home directory, it restores the backup.

**Usage**:

```
reset-lab-machine.sh
```

### create-live-usb.sh (obsolete)

**Info**:

This script creates bootable student media flash drives from a lab machine image ISO and course student media directories. Multiple Live ISO image can be specified and multiple source student media directories (or other files/directories) can be specified.

The following are the steps you follow to create a bootable student media flash drive:

1. Install standard lab image to disk or boot into live lab image
2. If the lab image was installed to disk, copy the lab image live ISO to your home directory 

**_Note_**: If you booted into the live lab image, the lab image live ISO can be found here: 
`/isofrom/` (for version 5.x of the lab machine image) or `/run/initramfs/isoscan/` (for version 6.x of the lab machine image).
Look for the file that ends in .iso

3. If the lab image was installed to disk, create the directory: `~/student_media`
4. Copy the student media files into: `~/student_media`

**_Note_**: If you booted into the live lab image from a flash drive that already contains the student media (i.e. the lab envionment installer and possibly other files), that student media will be located in the same directory as the live image ISO.
The student media files include the directory(s) named with a course number (i.e. the lab environment installer), the directories named *utilities* and *videos* (if they exist) and the README files.
It is easier if you can copy these files to another directory as is described above even if the student medial consists of only the lab environment installer (i.e. the directory named with the course ID).

5. Open a terminal window 
6. Plug a blank flash drive into the machine
7. Determine the block device that corresponds to the flash drive
8. Run the **create-live-useb.sh** command to create a student flash drive

**Usage**:

Create a live USB with student media (lab environment installer):

```
sudo create-live-usb.sh  <block_device>  <path_to_live_ISO>  <path_to_student_media>
```

Create a live USB without student media (lab environment installer):

```
sudo create-live-usb.sh  <block_device>  <path_to_live_ISO>
```

# Video Guides

[Back Up a Lab Environment](https://s3-us-west-2.amazonaws.com/training-howtos/backup_a_lab_environment.mp4)

[Create a Live USB](https://s3-us-west-2.amazonaws.com/training-howtos/create_a_live_usb.mp4)
