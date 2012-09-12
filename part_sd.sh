#!/bin/bash
############################################
# Script to create the partitions
# for a bootable sd card for 
# the Renesas EMEV tablet
#### sd partitions #########################
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

if [ ! -b "$SDCARD" ]
then
    echo "'${SDCARD}' is not a block device!"
    exit -1
fi

echo "You're about to erase all data on '${SDCARD}/' !"
read -p "If you're really sure about that hit <ENTER>, or abort with <CTRL>-C" 

set +e
for n in "${SDCARD}*" ;
do umount -f $n >/dev/null 2>&1 ;
done
set -e

echo "(1) Partioning sd card ..."
fdisk ${SDCARD} <<_EOF_ >/dev/null 2>&1
o
n
p
1

+256M
n
p
2

+256K
n
p
3

+512M
n
e


n

+512M
n


t
1
6
w
_EOF_
echo .
sleep 3
sync;sync;sync

echo "(2) Creating file systems ... will take a while!"
mkfs.msdos -F 32 -n bootfs4    ${SDCARD}1 >/dev/null 2>&1
mke2fs -t ext3   -L androidfs4 ${SDCARD}3 >/dev/null 2>&1
mke2fs -t ext3   -L datafs4    ${SDCARD}5 >/dev/null 2>&1
mke2fs -t ext3   -L nandfs4    ${SDCARD}6 >/dev/null 2>&1

echo "DONE."
