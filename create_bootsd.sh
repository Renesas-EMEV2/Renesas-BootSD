#!/bin/bash
############################################
# Script to create a bootable sd card for  ~
# the Renesas tablet with                  ~
#                                          ~
#        999 < kernel version < 10.000     ~
#                                          ~
# v20110819                                ~
#### sd partitions #########################
#
# p1 500MB	: 	boot files
# p2 256KB	:	uboot environment
# p3 400MB	:	android-fs
# p4		:	EXTENDED
# p5 750MB	:	data-fs / cache
# p6 the rest	:	nand-fs
#
# 
############################################
# tosan                                    ~ 
############################################

set +x -e

SDCARD=$1

SDBOOT="sdboot.bin"
UBOOTSD="uboot-sd.bin"
PATCHED_UBOOT="uboot-sd.bin-PATCHED"
INITRC="init.rc"
VOLDSTAB="vold.fstab"
VOLDCONF="vold.conf"
UIMAGE="../uImage4"
ANDROIDFS="../android-fs4.tar.gz"

echo .
echo "(1) Checking file availabilities ..."
echo .
ls -oh $SDBOOT
ls -oh $PATCHED_UBOOT
ls -oh $INITRC
ls -oh $VOLDSTAB
ls -oh $VOLDCONF
ls -oh $UIMAGE
ls -oh $ANDROIDFS


if [ ! -b "$SDCARD" ]
then
    echo .
    echo "'${SDCARD}' is not a block device!"
    echo .
    exit -1
fi

echo .
echo "(2) You're about to erase all data on '${SDCARD}/' !"
read -p "If you're really sure about that, then please hit <ENTER> or abort operation by <CTRL>-C ." 
echo .

set +e
for n in "${SDCARD}*" ;
do umount -f $n >/dev/null 2>&1 ;
done
set -e

echo .
echo "(3) Partioning sd card ..."
fdisk ${SDCARD} <<_EOF_ >/dev/null 2>&1
o
n
p
1

+500M
n
p
2

+256K
n
p
3

+400M
n
e


n

+750M
n


a
1
t
1
6
w
_EOF_
echo .
sleep 3
sync;sync;sync


echo .
echo "(4) Creating file systems ... will take a while!"
mkfs.msdos       -n bootfs4    ${SDCARD}1 >/dev/null 2>&1
mke2fs -t ext3   -L androidfs4 ${SDCARD}3 >/dev/null 2>&1
mke2fs -t ext3   -L datafs4    ${SDCARD}5 >/dev/null 2>&1
mke2fs -t ext3   -L nandfs4    ${SDCARD}6 >/dev/null 2>&1
echo .

mkdir -p _tmp_dir_zyx_
cd _tmp_dir_zyx_
mkdir -p p1
mkdir -p p3

mount -t vfat  ${SDCARD}1 ./p1/
mount -t ext3   ${SDCARD}3 ./p3/
echo .
echo "(5) Copying files ..."
cp -vf ../$SDBOOT ../$UIMAGE ./p1/

# Swapping SD u-boot with main u-boot (uboot4, patched for root fs to SD partition 3)
cp -vf ../$PATCHED_UBOOT  ./p1/$UBOOTSD

echo "... extracting ${ANDROIDFS} to ${SDCARD}3. This may take some time. Be patient ..."
tar zxf ../$ANDROIDFS -C ./p3/
cp -vpf ../$INITRC ./p3/
cp -vpf ../$VOLDSTAB ../$VOLDCONF ./p3/system/etc/
echo .

echo .
echo "(6) Cleaning up ..."
set +e
dd if=/dev/zero of=${SDCARD}2 >/dev/null 2>&1
set -e
sleep 10
umount -f ./p1/
umount -f ./p3/
echo .
sync;sync;sync

cd ..
rm -rf _tmp_dir_zyx_

echo .
echo "DONE."
echo "Put the card into the tab and boot it by pressing Vol+ && Power (recovery mode)."
echo "Have fun! :D"
echo .
