# Introduction to the Lab Environment Standards

This guide describes the lab environment standards used by the **Installation Framework** framework. 


# Networking

## Subnets and Network Names

The configuration of the networking in a lab environment is left to the discretion of the course developer based on the requirements for the course. It is strongly recommended that commonly used private subnets (i.e. 192.168.1.0/24, 10.0.0.0/24, etc.) be avoided. It is also recommended that the default Libvirt network (named default with a subnet of 192.168.100.0/24) be avoided. The name of the virtual network should be something that is descriptively relative to the course. 

(*Example*: The **admin** network in the OpenStack cloud course could be named **cloud-admin**)

## Virtual Bridge Names

Because it is possible that multiple lab environments can installed on a single lab machine at a time, there is a possibility of naming collisions between the virtual networks. It is strongly recommended that the network XML definition be edited so that the virtual bridge created by Libvirt, when the network is created, be named using a more descriptive name. The recommendation is to use the name of the virtual network as the name of the bridge.

**_Example_**: 
```
<name>cloud-admin</name>
...
  <ip address=’192.168.124.1’, netmask=’255.255.255.0’> 
  <bridge name=’cloud-admin‘ … />
...
```

For things like SUSECON sessions, because you can’t really know what the other sessions’ virtual networks are, it is suggested that you use a naming convention that includes your session ID (Example: **virbr-HO77572**). In the case where your session requires multiple networks, append the network number to the session ID separated by a **_** (Example: **virbr-HO77572_1** for the first network, **virbr-HO77572_2** for the second network, etc.).

## Network Definition XML File

The Libvirt virtual network definition XML file should be provided as part of the student media. This XML file can be created using the following command:

```
virsh net-dumpxml <NETWORK_NAME> > <NETWORK_NAME>.xml
```

The name of the file should be the name of the `<NETWORK_NAME>.xml` where `<NETWORK_NAME>` = the name of the virtual network (i.e. cloud-admin).

The following is an example of one of these network definition XML files:

**_File name_**: **cloud-admin.xml**

```
<network>
  <name>cloud-admin</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='cloud-admin' stp='on' delay='0'/>
  <mac address='52:54:00:20:52:73'/>
  <domain name='cloud-admin'/>
  <ip address='192.168.124.1' netmask='255.255.255.0'>
  </ip>
</network>
```

## Multi Lab Machine Environments

It is possible to spread a lab environment for a single student across multiple lab machines. When doing this it will typically require a different networking configuration to allow the VMs to communicate with each other when they are running on different lab machines. This different networking environment typically consists of a secondary network connection between the lab machines with separate VLANs with corresponding Linux bridges attached to them running across this secondary network. These Linux bridges take the place of the Libvirt virtual networks that the VMs are typically connected to.

When providing for this multi lab machine environment, each VM will require an addition XML definition file that specifies these bridges instead of Libvirt networks. Both XML definition files are required (single lab machine and multi lab machine versions) and should reside in the VM specific directory in `/home/VMs/<COURSE_ID>/` (i.e. `/home/VMs/<COURSE_ID>/<NAME_OF_VM>/`).

(Where `<COURSE_ID>` is the course ID number).

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

## Virtual Machine Directory

All files related to a virtual machine should exist in a single directory and the name of the directory should be the name of the virtual machine (as defined in the virtual machine’s Libvirt XML file). These individual virtual machine specific directories should all be subdirectories of: `/home/VMs/<COURSE_ID>` 

Example: `/home/VMs/<COURSE_ID>/<NAME_OF_VM>/` 

(Where `<COURSE_ID>` is the course ID number or SUSECON session ID and  `<NAME_OF_VM>` is the name of the virtual machine as defined in the VM’s XML definition file).

The files in the individual virtual machine directory should include at least the following:

* Virtual machine XML definition file(s)
* Disk image files used by the VM

Example Virtual Machine Directory Structure:
```
/home/VMs/<COURSE_ID>/<NAME_OF_VM>/
                                  |-<NAME_OF_VM>.xml
                                  |-<NAME_OF_VM>-multi_lm.xml
                                  |-<NAME_OF_VM>-disk01.qcow2
                                  |-<NAME_OF_VM>.pool.xml
                                  |-<NAME_OF_VM>.vbmc 
```
If you use Virt-Manager to create the new VM, it is easiest to manually create the VM directory and the disk image files in the directory first and then specify the disk image file during the installation. How to do this will be covered below.

## Virtual Machine XML Description

The virtual machine’s XML definition file should be named `<NAME_OF_VM>.xml` (where `<NAME_OF_VM>` is the name of the virtual machine as defined in the VM’s XML definition file).

The virtual machine’s XML definition file can be created using the following command:
```
virsh dumpxml <NAME_OF_VM> > /home/VMs/<COURSE_ID>/<NAME_OF_VM>/<NAME_OF_VM>.xml
```
After creating the VM’s XML definition file, you need to edit the file and remove the **<uuid>** and **<cpu>** sections as these will be auto-generated when the VM is registered with Libvirt on the lab machine. If the VM wasn’t originally created in the required directory (`/home/VMs/<COURSE_ID>/<NAME_OF_VM>/`), you will also need to edit the path to the disk images in the XML definition file to reside in this path.

## Virtual Machine Disks

Virtual machine disks should be of format QCOW2 when at all possible. The size of the disks should be as small as possible to meet the requirements of the course. (This helps keep the overall size of the student media smaller).

The disk image files should reside in the VM’s directory (`/home/VMs/<COURSE_ID>/<NAME_OF_VM>/`). It is important to note that if you are creating the VM using Virt-Manager, there is no option to create the images here.  You must first manually create the disk image in that directory using the **qemu-img** command and then, in Virt-Manager, select it as an existing disk image when creating the VM.

Example **qemu-img** command: 
```
qemu-img create -f qcow2 /home/VMs/<COURSE_ID>/<NAME_OF_VM>/disk01.qcow2 20G
```

## Virtual Machine Storage Pools (Optional)

If you wish to have a storage pool automatically created for the VM's directory (`/home/VMs/<COURSE_ID>/<NAME_OF_VM>`) when the VM is registered with Libvirt, then create a file in the VM's directory named `<NAME_OF_VM>.pool.xml` that contains the pool description. 

## Virtual Machine Virtual BMC Devices (Optional)

If you wish to have virtual BMC devices created for your VM when it is registered with Libvirt, then create a file in the VM's directory named `<NAME_OF_VM>.vbmc` that contains the virtual BMC device description. An example of this file can be found in the [vbmcctl](https://github.com/roncterry/vbmcctl) project (`vbmcctl.cfg.example`). The **vbmcctl** command must be installed on the host machine for this functionality to work. 

# ISO Images

If your virtual machines require ISO images or if you want to provide ISO images to your students, the following guidelines should be followed:

## ISO Image Directory

All ISO images related to a course should reside in a single directory named: `/home/iso/<COURSE_ID>` 

*Example*: **/home/iso/<COURSE_ID>/my-iso.iso**

Or, if the ISO image will <u>only</u> be used by a single VM, the ISO image can reside in the VM’s directory (see Virtual Machine Directory above).

# Cloud Images

If your lab environment requires cloud images to be used or if you want to provide cloud images to your students, the following guidelines should be followed:

## Cloud Image Directory

All cloud images related to a course should reside in a single directory named: **/home/images/<COURSE_ID>** 

*Example*: **/home/images/<COURSE_ID>/my-cloud-image.qcow2** 





# Video Guides
[Lab Environment Standards](https://s3-us-west-2.amazonaws.com/training-howtos/lab_environment_standards.mp4)


