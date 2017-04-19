#!/bin/bash

set -x
set -e

## Get arguments ##
if [ $# -eq 0 ]; then
  echo "Needs at least 2 args : g5k2CC (ubuntu|debian) source_image [output name]"
  exit 1
fi
if [ $1 != "ubuntu" ] && [ $1 != "debian" ]; then
  echo "First arg is the source OS : It must be either ubuntu or debian"
  exit 1
else
  SOURCE_OS=$1
fi
if [ -z $2 ]; then
  echo "Needs g5k input image in 2nd argument"
  exit 1
else
  SOURCE_IMG=$2
fi

OUTPUT_IMG=${3:-out.qcow2}

## Convert from tgz to qcow2 if needed
if [[ $SOURCE_IMG =~ \.tgz$ || $SOURCE_IMG =~ \.tar\.gz$ ]]; then
  echo "Input is a tarball, converting to qcow2..."
  # tgz to qcow2
  virt-make-fs --size=+170M --partition --format=qcow2 --type=ext4 $SOURCE_IMG $OUTPUT_IMG

  # Get UUID to setup fstab and syslinux.cfg
  VM_UUID=$(guestfish -a $OUTPUT_IMG -i blkid /dev/sda1 | grep ^UUID: | awk '{print $2}')
  guestfish -a $OUTPUT_IMG -i sh "echo \"UUID=$VM_UUID\\t/\\text4\\tdefaults\\t0\\t1\\n\" > /etc/fstab;
  sed -i \"s@^APPEND ro root=UUID.*@APPEND ro root=UUID=$VM_UUID quiet net.ifnames=0 biosdevname=0@\" /boot/syslinux.cfg"

  # Setup bootloader
  guestfish -a $OUTPUT_IMG -i <<EOF
  copy-file-to-device /boot/mbr.bin /dev/sda size:440
  extlinux /boot
  part-set-bootable /dev/sda 1 true
EOF
else
  # We'll work on a copy of the source image if it's already a qcow2
  echo "Source image is a qcow2"
  cp $SOURCE_IMG $OUTPUT_IMG
fi

## Preparing image for OpenStack deployment ##
virt-sysprep -a $OUTPUT_IMG
virt-customize -a $OUTPUT_IMG --install cloud-init
virt-customize -a $OUTPUT_IMG --install cloud-guest-utils
virt-customize -a $OUTPUT_IMG --install python-pkg-resources
virt-customize -a $OUTPUT_IMG --run-command 'echo "datasource_list: [  Ec2, None ]" > /etc/cloud/cloud.cfg.d/91-set-datasources.cfg'

## Remove blocking g5k configurations ##
virt-customize -a $OUTPUT_IMG --run 'rm_g5k_conf.sh'

## Fetch Chameleon Cloud configuration ##
if [ $SOURCE_OS = "ubuntu" ]; then
  git clone https://github.com/ChameleonCloud/CC-Ubuntu14.04.git /tmp/CC_git
  CC_SCRIPTS_PATH="/tmp/CC_git/elements/chameleon-common"
elif [ $SOURCE_OS = "debian" ]; then
  #TODO Create an image CC-Debian8 from cloud image to have 'chameleon-common' on github instead of local
  CC_SCRIPTS_PATH="debian_conf/elements/chameleon-common"
fi

## Apply most importants Chameleon Cloud install.d scripts ##
sed -i 's/^set -o pipefail/#set -o pipefail/g' $CC_SCRIPTS_PATH/install.d/*
SCRIPT_LIST="03-ntp 07-cloud-cfg"
for s in $SCRIPT_LIST
do
  virt-customize -a $OUTPUT_IMG --run $CC_SCRIPTS_PATH/install.d/$s
done

## Apply most importants Chameleon Cloud post-install.d scripts ##
sed -i 's/^set -o pipefail/#set -o pipefail/g' $CC_SCRIPTS_PATH/post-install.d/*
SCRIPT_LIST="03-autologin"
for s in $SCRIPT_LIST
do
  virt-customize -a $OUTPUT_IMG --run $CC_SCRIPTS_PATH/post-install.d/$s
done

rm -rf /tmp/CC_git
