#!/bin/bash

set +x -e
############################################
# Script to create a bootable sd card for
# the Renesas EMEV tablet
############################################

#Partitions
#-----------------
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
PBOOT="1"
PENV="2"
PANDROID="3"
PDATA="5"
PNAND="6"

# After formatting the SD card on Windows "MiniTool Partition Wizard"
# /dev/sdd6 on /media/ubootenv type ext3 (rw,nosuid,nodev,uhelper=udisks)
# /dev/sdd9 on /media/nand type ext3 (rw,nosuid,nodev,uhelper=udisks)
# /dev/sdd8 on /media/data type ext3 (rw,nosuid,nodev,uhelper=udisks)
# /dev/sdd7 on /media/androidfs type ext3 (rw,nosuid,nodev,uhelper=udisks)
# /dev/sdd5 on /media/BOOTFS type vfat (rw,nosuid,nodev,uid=1000,gid=1000,
#                                       shortname=mixed,dmask=0077,utf8=1,
#                                       showexec,flush,uhelper=udisks)
#PBOOT="5"
#PENV="6"
#PANDROID="7"
#PDATA="8"
#PNAND="9"

SDCARD=$1

#UBOOT="/media/u01/RenesasEV2/bootloader/u-boot"
UBOOTDIR="."
AOSPDIR=$2
KERNELDIR=$2

UIMAGE="${KERNELDIR}/uImage"
UIMAGENAME="uImage"
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

mkdir -p _tmp_/pboot
mkdir -p _tmp_/pandroid
mkdir -p ./_tmp_/pdata/
mount -t vfat  ${SDCARD}${PBOOT} ./_tmp_/pboot/
mount -t ext3   ${SDCARD}${PANDROID} ./_tmp_/pandroid/
mount -t ext3   ${SDCARD}${PDATA} ./_tmp_/pdata/

echo "(2) Copying boot files"
rm -rf ./_tmp_/pboot/*
cp -vf $SDBOOT ./_tmp_/pboot/$SDBOOTNAME
cp -vf $UIMAGE ./_tmp_/pboot/$UIMAGENAME
# Swapping SD u-boot with the one patched for root fs to SD partition 3
cp -vf $PATCHED_UBOOT  ./_tmp_/pboot/$UBOOTSDNAME

echo "(3) Extracting Android fs"
rm -rf ./_tmp_/pandroid/*
tar zxf $ANDROIDFS -C ./_tmp_/pandroid/
#cp -vpf ../$INITRC ./_tmp_/pandroid/
#cp -vpf ../$VOLDSTAB ../$VOLDCONF ./_tmp_/pandroid/system/etc/

echo "(3) Cleaning up /data partition"
rm -rf ./_tmp_/pdata/*

echo "(4) Cleaning up env"
set +e
dd if=/dev/zero of=${SDCARD}${PENV} >/dev/null 2>&1
set -e

echo "(5) Sync ..."
sync

sleep 1
umount -f ./_tmp_/pboot/
umount -f ./_tmp_/pandroid/
umount -f ./_tmp_/pdata/
rm -rf _tmp_

echo "DONE."
