#!/bin/bash

set -x
set -e

if [ $# -eq 0 ]; then
  echo "Needs at least 2 args : bash g5k2CC [ubuntu|debian] [source image] (optional)[output name]"
  exit 1
fi
if [ $1 != "ubuntu" ] && [ $1 != "debian" ]; then
  echo "First arg must be either ubuntu or debian"
  exit 1
else
  SOURCE_OS=$1
fi
if [ -z $2 ]; then
  echo "Needs g5k input image in argument"
  exit 1
else
  SOURCE_IMG=$2
fi

OUTPUT_IMG=${3:-out.qcow2}

cp $SOURCE_IMG $OUTPUT_IMG
# Preparing image for OpenStack deployment
virt-sysprep -a $OUTPUT_IMG
virt-customize -a $OUTPUT_IMG --install cloud-init
virt-customize -a $OUTPUT_IMG --install cloud-guest-utils

# Fetch Chameleon Cloud configuration
if [ $SOURCE_OS = "ubuntu" ]; then
  git clone https://github.com/ChameleonCloud/CC-Ubuntu14.04.git /tmp/CC_git
  SCRIPTS_PATH="/tmp/CC_git/elements/chameleon-common/install.d"

elif [ $SOURCE_OS = "debian" ]; then
  SCRIPTS_PATH="debian_conf/elements/chameleon-common/install.d"
fi

# Apply Chameleon Cloud configuration
sed -i 's/^set -o pipefail/#set -o pipefail/g' $SCRIPTS_PATH/*
virt-customize -a $OUTPUT_IMG --run $SCRIPTS_PATH/03-ntp
virt-customize -a $OUTPUT_IMG --run $SCRIPTS_PATH/07-cloud-cfg

rm -rf /tmp/CC_git
