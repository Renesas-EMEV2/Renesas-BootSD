#!/bin/bash
############################################
# Script to create a bootable sd card for
# the Renesas EMEV tablet
#
# Assuming these partitions exist:
# (Use part_sd.sh to create them)
#
# p1 500MB	: 	boot files
# p2 256KB	:	uboot environment
# p3 400MB	:	android-fs
# p4		:	EXTENDED
# p5 750MB	:	data-fs / cache
# p6 the rest	:	nand-fs
#
############################################

set +x -e

SDCARD=$1

#UBOOT="/media/u01/RenesasEV2/bootloader/u-boot"
UBOOTDIR="."
AOSPDIR=$2
KERNELDIR=$2

UIMAGE="${KERNELDIR}/uImage4"
UIMAGENAME="uImage4"
SDBOOT="${UBOOTDIR}/sdboot.bin"
SDBOOTNAME="sdboot.bin"
PATCHED_UBOOT="${UBOOTDIR}/uboot-sd.bin-PATCHED"
UBOOTSDNAME="uboot-sd.bin"
ANDROIDFS="${AOSPDIR}/android-fs4.tar.gz"
INITRC="init.rc"
VOLDSTAB="vold.fstab"
VOLDCONF="vold.conf"

echo "(1) Checking file availabilities ..."
ls -oh $SDBOOT
ls -oh $PATCHED_UBOOT
ls -oh $INITRC
ls -oh $VOLDSTAB
ls -oh $VOLDCONF
ls -oh $UIMAGE
ls -oh $ANDROIDFS

mkdir -p _tmp_/p1
mkdir -p _tmp_/p3
mount -t vfat  ${SDCARD}1 ./_tmp_/p1/
mount -t ext3   ${SDCARD}3 ./_tmp_/p3/

echo "(2) Copying boot files"
cp -vf $SDBOOT ./_tmp_/p1/$SDBOOTNAME
cp -vf $UIMAGE ./_tmp_/p1/$UIMAGENAME
# Swapping SD u-boot with the one patched for root fs to SD partition 3
cp -vf $PATCHED_UBOOT  ./_tmp_/p1/$UBOOTSDNAME

echo "(3) Extracting Android fs"
tar zxf $ANDROIDFS -C ./_tmp_/p3/
#cp -vpf ../$INITRC ./_tmp_/p3/
#cp -vpf ../$VOLDSTAB ../$VOLDCONF ./_tmp_/p3/system/etc/

echo "(4) Cleaning up"
set +e
dd if=/dev/zero of=${SDCARD}2 >/dev/null 2>&1
set -e
sleep 3
umount -f ./_tmp_/p1/
umount -f ./_tmp_/p3/
rm -rf _tmp_

echo "(5) Syncing up ..."
sync
echo "DONE."
