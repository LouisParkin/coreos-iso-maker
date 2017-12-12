#!/bin/bash
export PROJROOT=$PWD

export ISONAME=$1

if [ "$ISONAME" == "" ]; then
  export ISONAME="coreos.stable.iso"
fi

if  [ ! -d dev-channel ]; then
  echo "Required directory dev-channel missing. Cannot continue."
  exit 1
fi

cd dev-channel

if  [ ! -d iso ]; then
  echo "Required directory iso missing. Cannot continue."
  exit 1
fi

cd iso

if [ -f ../../$ISONAME ]; then
  sudo rm ../../$ISONAME
fi

sudo mkisofs -v -l -r -J -o ../../$ISONAME -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table .
sudo isohybrid ../../coreos.stable.iso
cd ../../

cd ${PROJROOT}
cd dev-channel

sudo rm -rf iso
mkdir iso
