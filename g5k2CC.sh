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

## Preparing image for OpenStack deployment ##
cp $SOURCE_IMG $OUTPUT_IMG
virt-sysprep -a $OUTPUT_IMG
virt-customize -a $OUTPUT_IMG --install cloud-init
virt-customize -a $OUTPUT_IMG --install cloud-guest-utils
virt-customize -a $OUTPUT_IMG --run-command 'echo "datasource_list: [  Ec2, None ]" > /etc/cloud/cloud.cfg.d/91-set-datasources.cfg'

## Remove blocking g5k configurations ##
virt-customize -a $OUTPUT_IMG --run 'rm_g5k_conf.sh'

## Fetch Chameleon Cloud configuration ##
if [ $SOURCE_OS = "ubuntu" ]; then
  git clone https://github.com/ChameleonCloud/CC-Ubuntu14.04.git /tmp/CC_git
  CC_SCRIPTS_PATH="/tmp/CC_git/elements/chameleon-common"
elif [ $SOURCE_OS = "debian" ]; then
  #TODO Create an image CC-Debian8 from cloud image
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
