#!/bin/bash
# su - core

export RUNMODE=$1
export VERSION=$2

sudo sysctl -w kernel.printk="2 4 1 7" > /dev/null

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
      echo "RUNMODE = $RUNMODE" > /dev/null
      echo "VERSION = $VERSION" > /dev/null
    fi
  else
    #runmode is normal
    echo "RUNMODE = $RUNMODE" > /dev/null
    echo "VERSION = $VERSION" > /dev/null
  fi
fi

if [ "$VERSION" == "" ]; then
  export VERSION="latest"
fi

# echo "RUNMODE = $RUNMODE"
# echo "VERSION = $VERSION"

trap '' INT TSTP

cd /home/core

sudo mkdir /mnt/rtfs
# sudo mkdir /mnt/cdrom

# sudo mount /dev/cdrom /mnt/cdrom
sudo cp /mnt/cdrom/coreos/oem-data/conf-$RUNMODE-$VERSION.json /home/core/conftemplate.json
sudo chown core:core /home/core/conftemplate.json

cont=0
isvmware=0


echo "Your CoreOs deployment is about to begin."

echo "{" > /home/core/conf.json
echo "  \"ignition\": { \"version\": \"2.1.0\" }," >> /home/core/conf.json
echo "  \"systemd\": {" >> /home/core/conf.json
echo "    \"units\": [" >> /home/core/conf.json
echo "      {" >> /home/core/conf.json
echo "        \"name\": \"update-engine.service\"," >> /home/core/conf.json
echo "        \"mask\": true" >> /home/core/conf.json
echo "      }," >> /home/core/conf.json
echo "      {" >> /home/core/conf.json
echo "        \"name\": \"locksmithd.service\"," >> /home/core/conf.json
echo "        \"mask\": true" >> /home/core/conf.json
echo "      }," >> /home/core/conf.json
echo "      {" >> /home/core/conf.json
echo "        \"name\": \"configure.service\"," >> /home/core/conf.json
echo "        \"enable\": true," >> /home/core/conf.json
echo "        \"contents\": \"[Unit]\nDescription=A configuration unit used for deployment\nType=idle\n\n[Service]\nExecStart=/usr/bin/script -c \\\"/home/core/post-install-tasks.sh normal release\\\" /var/log/platform/install-configure.log\n\n[Install]\nWantedBy=multi-user.target\"" >> /home/core/conf.json
echo "      }" >> /home/core/conf.json
echo "    ]" >> /home/core/conf.json
echo "  }," >> /home/core/conf.json
echo "  \"storage\": {" >> /home/core/conf.json
echo "    \"files\": [" >> /home/core/conf.json
echo "      {" >> /home/core/conf.json
echo "        \"filesystem\": \"root\"," >> /home/core/conf.json
echo "        \"path\": \"/etc/coreos/update.conf\"," >> /home/core/conf.json
echo "        \"contents\": {" >> /home/core/conf.json
echo "          \"source\": \"data:,%0AREBOOT_STRATEGY%3D%22off%22\"," >> /home/core/conf.json
echo "          \"verification\": {}" >> /home/core/conf.json
echo "        }," >> /home/core/conf.json
echo "        \"mode\": 420," >> /home/core/conf.json
echo "        \"user\": {}," >> /home/core/conf.json
echo "        \"group\": {}" >> /home/core/conf.json
echo "      }" >> /home/core/conf.json
echo "    ]" >> /home/core/conf.json
echo "  }," >> /home/core/conf.json
echo "  \"passwd\": {" >> /home/core/conf.json
echo "    \"users\": [" >> /home/core/conf.json
echo "      {" >> /home/core/conf.json
echo "        \"passwordHash\": \"\$6\$rounds=4096\$jloe.6ymkfMoG24\$OooyTioGGuOv21KpV2uOzsHoSpZK6e3Vdq/vyXGDWAGeT7.6wWq3rlMW5Nk0PyiCmAs6iryYzUiNTnYVEeP.l.\"," >> /home/core/conf.json
echo "        \"name\": \"coreuser\"," >> /home/core/conf.json
echo "        \"create\": {" >> /home/core/conf.json
echo "          \"groups\": [" >> /home/core/conf.json
echo "            \"sudo\"," >> /home/core/conf.json
echo "            \"docker\"" >> /home/core/conf.json
echo "          ]" >> /home/core/conf.json
echo "        }" >> /home/core/conf.json
echo "      }" >> /home/core/conf.json
echo "    ]" >> /home/core/conf.json
echo "  }" >> /home/core/conf.json
echo "}" >> /home/core/conf.json


cont=0
isvmware=0
if [ "$RUNMODE" == "jenkins" ]; then
  sudo coreos-install -d /dev/sda -i /home/core/conf.json -o vmware_raw -f /mnt/cdrom/coreos/oem-data/coreos_production_vmware_raw_image.bin.bz2 -b http://dockerhub.entersect.co.za:8000/v1/update/
  cont=1
  isvmware=1
else
  echo "   Is this product deploying to a VMWare environment?  (yes/no)"

  while (( cont == 0 ))
  do
    read input
    if [ "$input" == "yes" ]
    then
       sudo coreos-install -d /dev/sda -i /home/core/conf.json -o vmware_raw -f /mnt/cdrom/coreos/oem-data/coreos_production_vmware_raw_image.bin.bz2 -b http://dockerhub.entersect.co.za:8000/v1/update/
       cont=1
       isvmware=1
    else
      if [ "$input" == "no" ]
      then
         sudo coreos-install -d /dev/sda -i /home/core/conf.json -f /mnt/cdrom/coreos/oem-data/coreos_production_image.bin.bz2 -b http://dockerhub.entersect.co.za:8000/v1/update/
         cont=1
         isvmware=0
      else
         cont=0
         echo "Could not interpret answer : " $input ". Please only input yes or no."
         echo "   Is this product deploying to a VMWare environment?  (yes/no)"
      fi
    fi
  done
fi
# After install, mount rootfs and copy container and service files
sudo mount /dev/sda9 /mnt/rtfs
sudo cp /mnt/cdrom/coreos/oem-data/kp.conf /mnt/rtfs/etc/sysctl.d/kp.conf

cd /mnt/rtfs/home/core

sudo cp /mnt/cdrom/coreos/oem-data/post-install-tasks.sh post-install-tasks.sh
sudo chown core:core post-install-tasks.sh

if [ $isvmware == 1 ]
then
  echo "Rebooting"
  echo "5"
  sleep 1
  echo "4"
  sleep 1
  echo "3"
  sleep 1
  echo "2"
  sleep 1
  echo "1"
  sleep 1
else
  echo "Powering Down"
  echo "5"
  sleep 1
  echo "4"
  sleep 1
  echo "3"
  sleep 1
  echo "2"
  sleep 1
  echo "1"
  sleep 1
fi
