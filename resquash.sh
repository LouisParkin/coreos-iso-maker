export PROJROOT=$PWD
cd dev-channel
cd iso
cd coreos
cd tmp

echo "At " $PWD
echo ""
ls -la
echo ""
#produce usr.squashfs
echo "Making new squash..."
sudo mksquashfs unsquashed/ usr.squashfs -b 131072

echo "At " $PWD
echo ""
ls -la
echo ""

echo "Resquashing completed.  Cleaning up..."
sudo rm usr.squashfs.old

echo "At " $PWD
echo ""
ls -la
echo ""
echo "Remove Unsquashed dir..."
sudo rm -rf unsquashed

echo "At " $PWD
echo ""
ls -la
echo ""
# produce cpio in tmp, which includes etc and usr.squashfs
echo "Create new cpio..."
# sudo ./make-cpio.sh
sudo ./../../../../make-cpio.sh

echo "At " $PWD
echo ""
ls -la
echo ""

# move one dir up, remove old cpio
echo "Going up one dir..."
cd .. ;
echo "Killing old cpio..."
sudo rm cpio

echo "At " $PWD
echo ""
ls -la
echo ""

# relocate new cpio
echo "mv newcpio cpio..."
sudo mv newcpio cpio

echo "At " $PWD
echo ""
ls -la
echo ""

echo "Killing tmp dir"
sudo rm -rf tmp

echo "At " $PWD
echo ""
ls -la
echo ""

sudo gzip cpio
sudo chown ${USER}:${USER} cpio.gz

echo "Done"
