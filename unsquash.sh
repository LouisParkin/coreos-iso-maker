#!/bin/bash

export PROJROOT=$PWD
export RUNMODE=$1
export VERSION=$2

NEEDHELP=0

if [ "$RUNMODE" == "help" ]; then
  NEEDHELP=1
fi

if [ "$RUNMODE" == "--help" ]; then
  NEEDHELP=1
fi

if [ "$RUNMODE" == "-h" ]; then
  NEEDHELP=1
fi

if [ $NEEDHELP == 1 ]; then
  echo "Usage: ./unsquash.sh [OPTIONS]"
  echo "Options:"
  echo "  runmode  - should be \"jenkins\" or \"normal\" "
  echo "  version  - should be the docker image tag needed for images baked into the iso"
  echo " "
  echo "Example commandline:"
  echo "./unsquash.sh jenkins latest"
  echo "./unsquash.sh normal release"
  exit 0
fi


# If the first parameter was empty, assume no parameters were given
if [ "$RUNMODE" == "" ]; then
  export RUNMODE="normal"
  echo "RUNMODE WAS BLANK"
else
  if [ "$RUNMODE" != "normal" ]; then #runmode is not normal
    if [ "$RUNMODE" != "jenkins" ]; then #runmode is also not jenkins
      # hardcode runmode to normal, take what was passed in as the version
      export RUNMODE="normal"
      export VERSION=$1
    else
      #runmode is jenkins
      echo "RUNMODE = $RUNMODE"
      echo "VERSION = $VERSION"
    fi
  else
    #runmode is normal
    echo "RUNMODE = $RUNMODE"
    echo "VERSION = $VERSION"
  fi
fi

if [ "$VERSION" == "" ]; then
  export VERSION="latest"
fi

# From proj root to root/dev-channel
cd dev-channel

# Kill previous config, if there was one
if [ -d iso ]; then
  rm -rf iso
fi

mkdir iso

# https://alpha.release.core-os.net/amd64-usr/current/
# Check if iso and images exist.
LASTDIR=${PWD}
if  [ ! -d ${PROJROOT}/CoreOsProdIso ]; then
  mkdir ${PROJROOT}/CoreOsProdIso
fi

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

cd ${LASTDIR}

# From root/dev-channel to root/dev-channel/iso
cd iso
7z x ${PROJROOT}/CoreOsProdIso/coreos_production_iso_image.iso
rm -rf \[BOOT\]/

# From root/dev-channel/iso to root/dev-channel/iso/coreos
cd coreos

# Make oem-data folder.
sudo mkdir oem-data
cd oem-data

# Copy installation image used to install to non-vmware hosts
sudo cp ${PROJROOT}/CoreOsProdIso/coreos_production_image.bin.bz2 coreos_production_image.bin.bz2
sudo chown ${USER}:${USER} coreos_production_image.bin.bz2

# Copy installation image used to install to vmware hosts
sudo cp ${PROJROOT}/CoreOsProdIso/coreos_production_vmware_raw_image.bin.bz2 coreos_production_vmware_raw_image.bin.bz2
sudo chown ${USER}:${USER} coreos_production_vmware_raw_image.bin.bz2

# Copy deployment script
sudo cp ${PROJROOT}/install-tasks.sh install-tasks.sh
sudo chown ${USER}:${USER} install-tasks.sh

# Copy configuration script
sudo cp ${PROJROOT}/post-install-tasks.sh post-install-tasks.sh
sudo chown ${USER}:${USER} post-install-tasks.sh

# Copy kernel.printk configuration
sudo cp ${PROJROOT}/kp.conf kp.conf

#Generate OS Installation ignition script
if [ -f ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json ]; then
  rm ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
fi

cp ${PROJROOT}/WebConf/conf-template.json ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json

echo "        \"contents\": \"[Unit]\nDescription=A configuration unit used for deployment\nType=idle\n\n[Service]\nExecStart=/usr/bin/script -c \\\"/home/core/post-install-tasks.sh $RUNMODE $VERSION\\\" /var/log/platform/install-configure.log\n\n[Install]\nWantedBy=multi-user.target\"" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "      }" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "    ]" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "  }," >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "  \"storage\": {" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "    \"files\": [" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "      {" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "        \"filesystem\": \"root\"," >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "        \"path\": \"/etc/coreos/update.conf\"," >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "        \"contents\": {" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "          \"source\": \"data:,%0AREBOOT_STRATEGY%3D%22off%22\"," >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "          \"verification\": {}" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "        }," >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "        \"mode\": 420," >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "        \"user\": {}," >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "        \"group\": {}" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "      }" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "    ]" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "  }," >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "  \"passwd\": {" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "    \"users\": [" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "      {" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "        \"passwordHash\": \"\$6\$rounds=4096\$jloe.6ymkfMoG24\$OooyTioGGuOv21KpV2uOzsHoSpZK6e3Vdq/vyXGDWAGeT7.6wWq3rlMW5Nk0PyiCmAs6iryYzUiNTnYVEeP.l.\"," >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "        \"name\": \"coreuser\"," >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "        \"create\": {" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "          \"groups\": [" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "            \"sudo\"," >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "            \"docker\"" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "          ]" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "        }" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "      }" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "    ]" >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json
echo "  }," >> ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json

# Copy installed OS boot ignition script
sudo cp ${PROJROOT}/WebConf/conf-$RUNMODE-$VERSION.json conf-$RUNMODE-$VERSION.json
sudo chown ${USER}:${USER} conf-$RUNMODE-$VERSION.json

# One dir up.
cd ..

# Extract ramdisk
sudo gunzip cpio.gz; sudo chown ${USER}:${USER} cpio
sudo mkdir tmp;

# Decompress ramdisk into tmp folder
cd tmp/; sudo cpio -id < ../cpio
sudo chown -R ${USER}:${USER} ../tmp/

# Unsquash ramdisk file system
sudo mkdir unsquashed
sudo unsquashfs -f -d unsquashed usr.squashfs

# Backing up old squashfs
sudo mv usr.squashfs usr.squashfs.old

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
