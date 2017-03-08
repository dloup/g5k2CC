#!/bin/bash

set -x
set -e

SOURCE_OS=${SOURCE_OS:-"ubuntu"}
OUTPUT_IMG=${2:-out.qcow2}

if [ -z $1 ]; then
  echo "Needs g5k input image in argument"
  exit 1
else
  SOURCE_IMG=$1
fi

### UBUNTU CONVERTION SCRIPT ###
if [ $SOURCE_OS = "ubuntu" ]; then
 cp $SOURCE_IMG $OUTPUT_IMG
 # Preparing image for OpenStack deployment
 virt-sysprep -a $OUTPUT_IMG
 virt-customize -a $OUTPUT_IMG --install cloud-init
 virt-customize -a $OUTPUT_IMG --install cloud-guest-utils

 # Fetch Chameleon Cloud configuration
 SCRIPTS_PATH="chameleon-common/install.d"
 sed -i 's/^set -o pipefail/#set -o pipefail/g' $SCRIPTS_PATH/*

 # Apply Chameleon Cloud configuration
 virt-customize -a $OUTPUT_IMG --run $SCRIPTS_PATH/03-ntp
 virt-customize -a $OUTPUT_IMG --run $SCRIPTS_PATH/07-cloud-cfg

### DEBIAN CONVERTION SCRIPT ###
elif [ $SOURCE_OS = "debian" ]; then
  #TODO
  echo "Todo"
else
  echo "Source OS \"$SOURCE_OS\" not supported yet"
  exit 1
fi
