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
