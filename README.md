# Introduction

The lab environment installer framework is a set of scripts and script libraries that can be used to install and remove everything pertaining to al lab environment to and from a lab machine. This framework can dramatically simplify the deployment and then cleanup of lab environments used during training courses or hands-on sessions at conferences. The things related to the installer frameworks and the corresponding course and lab environment files are commonly referred to as the **student media** for a course.

The installer framework comprises the following:

* Installation and removal scripts and their corresponding include files

* A standardized directory structure for the course, its lab environment and related files

# Directory Structure

The installation and removal scripts in the installer framework rely on the files for the course and its lab environment to be organized in a specific directory structure.

## Directory Structure Example

The directory structure is as follows:

```
<COURSE_DIRECTORY>/
    |-config/
    |	    |-include/
    |	    |
    |	    |-libvirt.cfg/
    |    	|
    |	    |-ssh/
    |	    |
    |	    |-lab_env.cfg**
    |
    |-course_files/
    |
    |-images/
    |
    |-iso/
    |
    |-pdf/
    |
    |-scripts/
    |
    |-VMs/
    |
    |-install_lab_env.sh
    |-remove_lab_env.sh
    |-backup_lab_env.sh
```
## File and Directory Descriptions


**COURSE_DIRECTORY** 

This is the main directory that contains all files belonging to the course (or hands-on session). In the case of training courses, this directory should be named the course ID of the course. In the case of hands-on sessions (i.e. SUSECon) this directory should be named the session ID of the session.

_**Example 1 (course)**_: A course with a course ID of **SOC201**, would have a directory name of **SOC201**.

_**Example 2 (conference session)**_: A conerence session with a session ID of **HO77572**, would have a directory name of **HO77572**.

**config/**

This directory contains all configuration files for both the installer framework and the lab environment. Common files that will reside in this directory are the installation/removal script configuration file (**lab_env.cfg**) and custom include files for the installation/removal script (**custom-\*.sh**). This directory will also have some standard subdirectories.

**config/include**

This subdirectory of the **config/** directory contains the function libraries that are included by the installation and removal scripts. These files should not be modified as they are part of the installer framework.

**config/libvirt.cfg/**

This subdirectory of the **config/** directory contains the Libvirt configuration files used by the lab environment such as the network definition XML files. These files are related to the lab environment and are not part of the installer framework.

**config/ssh/**

This subdirectory of the **config/** directory contains ssh related files such as ssh keys and authorized_keys files. These files are related to the lab environment and are not part of the installer framework.

**config/lab_env.cfg**

This file is the configuration file for the installer framework. It should be edited to reference the specific files that are part of the course/session lab environment. 

*NOTE: THIS IS THE FILE THAT YOU EDIT*

**course_files/**

This directory contains any miscellaneous files that are related to the course such as example configuration files and such.

**images/**

This directory contains any virtual machine images such as cloud disk image files that are used in the lab environment. These DO NOT include the virtual machines that comprise the lab environment. These get copied to the **/home/images/** directory when the lab environment is installed.

**iso/**

This directory contains any ISO images that are used in the lab environment. These get copied to the **/home/iso/** directory when the lab environment is installed.

**pdf/**

This directory contains the PDF manuals and any other PDF files related to the lab environment or the course, for example the lecture and lab manuals. These get copied to the **~/pdf/** directory when the lab environment is installed.

**scripts/**

This directory contains any scripts that are used in the course/session or lab environment such as lab automations scripts or automated VM creation scripts. These get copied to the **~/scripts/** directory when the lab environment is installed.

**VMs/**

This directory contains the VMs that comprise the lab environment. These files should be archive files of each of the VM directories with one set of archive files per VM. It is recommended that these archives be created with the p7zip utility (7z command) as it supports both high compression ratios and split archives and free and open source software. 

**WARNING**: If you are reading this in PDF format, DO NOT copy and paste these commands from the pdf into the shell. It will cause problems due to invisible special characters being put into the file names.

Example archive creation commands: 

```bash
7z a -t7z -m0=LZMA2 -mmt=on -v2g <VM_NAME>.7z <VM_DIRECTORY>
```
(This creates an archive in 7z format, compressed with LZMA2 and split into files no larger than 2GB. The file names will be VM_NAME.7z.00# - where # is the number of the file that is part of the archive. This is good for creating a smaller student media package but takes longer to unpack when installing the lab environment.)

```bash
7z a -t7z -m0=0 -mmt=on -v2g <VM_NAME>.7z <VM_DIRECTORY>
```

(This creates an archive in 7z format, uncompressed and split into files no larger than 2GB. The file names will be VM_NAME.7z.00# - where # is the number of the file that is part of the archive. This unpacks quicker and is good for situations where you need to install the lab environment quicker but it creates a larger student media package.)

These archives are extracted into **/home/VMs/****_COURSE_NUM_****/** when the lab environment is installed and each VM is registered with Libvirt.

**install_lab_env.sh**

This is the script that is run to install the lab environment. To execute this script you must have as your current working directory the **_COURSE_DIRECTORY_****/** as it looks file files relative to its current working directory. 
(NOTE- DO NOT EDIT THIS FILE)

**remove_lab_env.sh**  

This is the script that is run to remove an installed lab environment. It is copied to the **~/scripts/** directory when the lab environment is installed so that the original student media is not required to remove an installed lab environment. (
NOTE- DO NOT EDIT THIS FILE)



**backup_lab_env.sh**

This script can be used to back up the current state of an installed lab environment creating a new installer package from the backed up files. The installer package that is created will be located in **/install/courses/** and will be named "**_COURSE_NUM_****-backup_****_TIMESTAMP_**". 
(NOTE- DO NOT EDIT THIS FILE)

# The lab_env.cfg Configuration File

The **lab_env.cfg** file is key to how the lab environment is installed. Because of this, the file must be edited to contain the files that are specific to the lab environment. The file is heavily documented but to help understand what needs to be edited, the most important configuration options will be covered here. Please refer to the actual configuration file for any configuration options not covered here.

The configuration options are set as variable=value pairs. The following are the configuration options that must be set:

**COURSE_NAME**

This variable contains the friendly or short descriptive name of the course or hands-on session. It is only used for display in the output of the installation/removal scripts. It is also useful for keeping track of which course/session the file belongs to.

**COURSE_NUM**

This variable contains the course number or session ID of the course/session. It is use to create the subdirectory in **/home/VMs/** that contains the course/session specific VMS as well as other in other places where things need to be kept separate from other courses/sessions. It is critical that this be unique to the course or session and not contain spaces.

**REQUIRE_VT_ENABLED**

**REQUIRE_MIN_MEMORY**

**REQUIRE_MIN_DISKSPACE**

**REQUIRE_SUDO_NOPASSWD**

**REQUIRE_P7ZIP**

**REQUIRE_KVM_VIRT**

**REQUIRE_KVM_NESTED**

**REQUIRE_LIBVIRT**

These variables specify which tests to run on the lab machine before attempting to install the lab environment onto the lab machine. The default behaviour is to run all tests unless specifically told not to. This behaviour allows additional tests to be added to the installation script yet still have older configuration files still work. If you are not sure which tests you need for your lab environment, just allow all tests to run.

To disable a test, set the variable's value to **N**.

Refer to the comments in the configuration file for more details on what each variable/test does.

**MIN_DISK_FREE**

This variable allows you to specify the minimum amount of free disk space that is required to install and run the lab environment. This value is in GB though you should not append "GB" to the value. It should also be an integer.

When checking for this free disk space, different parts of the filesystem are checked in the following order depending on how the disks are partitioned.

If **/home/VMs** is on its own partition then the free disk space refers to that volume,

Else, if **/home** is on its own partition then the free disk space refers to this volume,

Else, the free disk space refers to the volume mounted on **/**.

**MIN_MEMORY**

This variable allows you to specify the amount of RAM that is required to run the lab environment. This value is in GB though you should not append "GB" to the value. It should also be an integer and it should be rounded up to the next highest full GB in the case that the RAM requirement do not total up to a whole gigabyte. 

If you wish to specify as machine with a specific amount of RAM rather than use the amount of RAM that the lab environment requires (i.e. you want to require a 16GB machine or a 32GB machine) you should use a value that 1GB less that the total you want in the system. For example, if you want to specify that a 16GB machine is required you would use 15 as the value. This helps account for memory that could be use by hardware components.

When creating a lab environment, it is important to remember to allow for the host system to have enough memory to run in addition the the amount of memory required by for the VMs. It is recommended that you allow at least 1GB for the host system though 2GB would be better (especially when the host system will be running a GUI). The amount of memory reserved for the host system does not need to be included in the value you set here.

**ISO_LIST**

This variable allows you to specify a list of ISO images that you want to provide to your students. These ISO image can either be used directly by the VMs in the lab environment or just be ISO images that you want your students to have. These ISO images must exist in the **/home/iso/****_COURSE_NUM_** directory. The only exception to this rule is that if an ISO image is only used by a single VM then it can reside in that VM’s directory and will them be treated as just another one of the VM’s disks.

**CLOUD_IMAGE_LIST**

This variable allows you to specify a list of cloud images that you want to provide to your students. These ISO images must exist in the **/home/iso/****_COURSE_NUM_** directory.

**LIBVIRT_VM_LIST**

This is a space delimited list of VMs that make up the lab environment. 

The values in this list will be the names of the VMs which should correspond to the names of the VMs archive files minus the archive extension (i.e. .7z.001, etc.). The names of the archive files should correspond to the names of the VMs’ directories which in turn should correspond to the names of the VMs’ XML configuration files (minus the .xml) in those directories. This name should correspond to the names of the VMs as specified in their XML configuration files. This naming is critical because it is how the installation and removal scripts know how to manage the VMs for things such as registering them with Libvirt.

**LIBVIRT_VNET_LIST**

This is a space delimited list of Libvirt virtual networks that need to be defined and started when the lab environment is installed.

The values in this list are the names of the XML network definition files (minus the .xml) that reside in the **config/libvirt.cfg/** directory. The names of these files should correspond to the names of the virtual networks as specified in their XML configuration files. This naming is critical because it is how the installation and removal scripts know how to manage the virtual networks for such things as registering and starting the networks.

# Multi Lab Machine Environment

The installation framework supports the ability to spread a single lab environment across multiple lab machines in cases where the lab environment is too large to fit on a single lab machine. To do this there are some specific things that need to to be done.

## Interconnecting the Lab Machines

To spread the lab environment across multiple lab machines, the lab machines must be connected to each other on a network. Typically this will be done by adding a second NIC to each lab machine and then connecting these NICs to a separate network from the one connected to the first NICs. It is important to understand that each student’s lab environment is identical to every other student. For this reason the network that the second NICs in the group of lab machines that correspond to single student’s lab environment are connected to is isolated from the other student’s secondary networks*.

Gigabit Ethernet is required for the interconnecting links between the lab machines. These can be USB3 gigabit Ethernet adapters however.

*Because of how the VLANs and Bridges can be defined, it is possible to use only a single network that all students are connected to. To do this, each student’s **lab_env.cfg** file would need to be edited separately to specify a unique set of VLAN IDs for each student. This will not be covered in this document but the description of how to do it for **VLAN_LIST** and **BRIDGE_LIST** variable is in the comments for those variable in the **lab_env.cfg** file.

## Multi Lab Machine Configuration Files

To support both installation of the lab environment on a single lab machine as well as multiple lab machines, you will need to have a basic **lab_env.cfg** file for the single machine deployment and then separate individual **lab_env.cfg** files for each of the lab machines (referred to as nodes) in the lab environment. In this case, you should name the multi lab machine versions of the **lab_env.cfg** files in a way that is easy for the user to recognize which config file corresponds to which lab machine. For example, if you want to spread the lab environment across two different lab machines, you might name the config files: **lab_env-node1.cfg** and **lab_env-node2.cfg**. All of these config files should reside in the **config/** directory.

## Multi Lab Machine Configuration File Options

There are some additional configuration values that need to be set in the multi lab machine versions of the **lab_env.cfg** files for it them support multiple lab machines.

**MULTI_LAB_MACHINE**

This variable specified if the configuration file is for a multi lab machine environment.

**Y** = Is a multi lab machine environment

**N** = Is a single lab machine environment

**MULTI_LM_EXT**

This variable is used in the case of multi lab machine environments to specify the extension to look for in the names of the virtual machines’ XML definitions when registering them with Libvirt. The default value for this is **multi_lm**. If unsure, use the default value.

Because multi lab machine environments require a different networking configuration than single lab machine environment, VMs will need to have a different XML definition file that will be used when registering them with Libvirt. This additional file will contain the extension specified in this variable in their file names.

***Example:***

For a VM named **admin**, 

the regular XML definition file should = **admin.xml** 

If **MULTI_LM_EXT**=**multi_lm** 

then the multi lab environment version fo the file will = **admin-multi_lm.xml** 

Both XML definition files should reside in the VM’s directory (i.e. **/home/VMs/****_NAME_OF_VM_****/**)

**INSTALL_SSH_KEYS**

This variable is used to determine if SSH keys should be installed in the user’s **~/.ssh/** directory when the lab environment is installed.

**Y** = Install SSH keys

**N** = Do not install SSH keys

**SSH_FILE_LIST**

This variable works in conjunction with the **INSTALL_SSH_KEYS** variable. It is a space delimited list of files that reside in config/ssh/ that should be copied into **~/.ssh/** when the lab environment is installed.

**IMPORTANT**

It is important to note that if there are files that already exist in the **~/.ssh/** directory that have the same names as the files in this list, the existing files will be overwritten by the files listed in this configuration file. This is why it is a best practice to install lab environments as a dedicated lab user rather than the user you may use as your everyday user.

**VLAN_LIST**

This variable is used to have the installation script create VLANs when the lab environment is installed. It is a space delimited list of VLAN definitions which are in turn comma delimited lists. The YaST LAN module is used to create these VLANs. The description of the fields in the VLAN definition are described in the comments in the **lab_env.cfg** file.

The most common use of this feature is to create VLANs on the network that interconnects the lab machines in the multi lab machine environment. Bridges will then be created on these VLANs which will be used as the virtual networks the VMs are connected to.

**BRIDGE_LIST**

This variable is used to have the installation script create Linux bridges when the lab environment is installed. It is a space delimited list of Linux bridge definitions which are in turn comma delimited lists. The YaST LAN module is used to create these Linux bridges. The description of the fields in the Linux bridge definition are described in the comments in the **lab_env.cfg** file.

The most common use of this feature is to create Linux bridges on the VLANs. These bridges will be used as the virtual networks the VMs are connected to.


