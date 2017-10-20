# ISO Maker

A series of bash scripts that are used to generate a usable self-installing CoreOs iso with.

# Installation

## GIT
Clone the git repository, and that's it, you're done.

## Runtime
There are a few requirements for creating an ISO, install the following items:
* 7zip
* gzip / gunzip
* tar
* squashfs-tools
* syslinux-utils
* mkisofs

# Running

## Setup
Check out the project source, and move to Execution

## Execution

### With default settings, normal RUNMODE, latest VERSION tags for docker:
```
./execute-build.sh
```
OR
```
./unsquash.sh; ./resquash.sh; ./build-iso.sh
```

### With custom settings, jenkins RUNMODE, release VERSION tags for docker:
```
./execute-build.sh jenkins release
```
OR
```
./unsquash jenkins release; ./resquash.sh; ./build-iso.sh
```

Assuming the build succeeded, in the root directory of the project there will be a file named "coreos.alpha.iso"

# Usage

## What is done and why

### CoreOS ISO is downloaded, along with two rootfs images (vmware and generic)

```bash
cd ${PROJROOT}/CoreOsProdIso/

ISOIMAGE="${PROJROOT}/CoreOsProdIso/coreos_production_iso_image.iso"
if [ ! -f $ISOIMAGE ]; then
  wget --no-check-certificate https://alpha.release.core-os.net/amd64-usr/current/coreos_production_iso_image.iso
fi

GENERICIMAGE="${PROJROOT}/CoreOsProdIso/coreos_production_image.bin.bz2"
if [ ! -f $GENERICIMAGE ]; then
  wget --no-check-certificate https://alpha.release.core-os.net/amd64-usr/current/coreos_production_image.bin.bz2
fi

VMWAREIMAGE="${PROJROOT}/CoreOsProdIso/coreos_production_vmware_raw_image.bin.bz2"
if [ ! -f $VMWAREIMAGE ]; then
  wget --no-check-certificate https://alpha.release.core-os.net/amd64-usr/current/coreos_production_vmware_raw_image.bin.bz2
fi
```
##### This is done to be able to bake these images into the ISO, meaning your deployment doesn't require an Internet connection.  Also, it is useful to be able to choose to install the vmware image from the CoreOs ISO.

### The CoreOS ISO is ripped apart, and the initramfs is decompressed.

```bash
# Unsquash ramdisk file system
sudo mkdir unsquashed
sudo unsquashfs -f -d unsquashed usr.squashfs

# Backing up old squashfs
sudo mv usr.squashfs usr.squashfs.old
```

### A custom .bash_profile file is injected into the ramdisk before recompressing the ramdisk.

```bash
# generate .bash_profile from template
if [ -f ${PROJROOT}/.bash_profile ]; then
  rm ${PROJROOT}/.bash_profile
fi

cp ${PROJROOT}/.bash_profile_template ${PROJROOT}/.bash_profile

echo " " >> ${PROJROOT}/.bash_profile

echo "script -c \"install-tasks.sh $RUNMODE $VERSION\" install.log" >> ${PROJROOT}/.bash_profile

echo "sudo mkdir /mnt/rtfs/var/log/platform" >> ${PROJROOT}/.bash_profile
echo "sudo mv /home/core/install.log /mnt/rtfs/var/log/platform/install.log" >> ${PROJROOT}/.bash_profile

if [ "$RUNMODE" == "jenkins" ]; then
  echo "reboot" >> ${PROJROOT}/.bash_profile
else
  echo "poweroff" >> ${PROJROOT}/.bash_profile
fi

# copy .bash_profile that has been modified to run installer script when core user logs in automatically
cd ${PROJROOT}/dev-channel/iso/coreos/tmp/unsquashed/share/skel
sudo cp ${PROJROOT}/.bash_profile .bash_profile
```
##### This .bash_profile is used by the ramdisk when booting, as it automatically logs the 'core' user in.  From here I can make the ISO boot do anything that is within my grasp via bash, including prompting the user whether they would like to install a vmware variant.

```bash
# /etc/skel/.bash_profile

# This file is sourced by bash for login shells.  The following line
# runs your .bashrc and is recommended by the bash info pages.
if [[ -f ~/.bashrc ]] ; then
	. ~/.bashrc
fi

cd

sudo mkdir /mnt/cdrom
sudo mount /dev/cdrom /mnt/cdrom

if [ ! -d /mnt/cdrom/coreos ]; then
	# there is no cdrom.  Potentially looking for a USB disk.
	sudo mount /dev/disk/by-label/CDROM /mnt/cdrom
	if [ ! -d /mnt/cdrom/coreos ]; then
		# we're boned.
		echo "Cannot reliably determine location of installation files."
		exit 1
	fi
fi

sudo cp /mnt/cdrom/coreos/oem-data/install-tasks.sh /home/core/install-tasks.sh
sudo chown core:core /home/core/install-tasks.sh
sudo chmod a+x /home/core/install-tasks.sh
sudo chmod a+w /home/core/install-tasks.sh
cd /home/core

export PATH=$PATH:/home/core

script -c "install-tasks.sh normal latest" install.log
sudo mkdir /mnt/rtfs/var/log/platform
sudo mv /home/core/install.log /mnt/rtfs/var/log/platform/install.log
poweroff
```

##### As can be seen from the above .bash_profile, the install-tasks.sh file will be executed automatically when the ISO boots.

### Any files that will be required by the install-tasks script are copied to the oem-data directory in cdrom/coreos/ before rebuilding the iso.
##### This is done to allow as much customization as possible without relying on a network connection or access to the Internet.
