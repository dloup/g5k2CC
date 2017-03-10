#!/bin/bash

#rm DHCP hook
DHCP_HOOK="/etc/dhcp/dhclient-exit-hooks.d/g5k-update-host-name"
if [ -f $DHCP_HOOK ]; then
  rm $DHCP_HOOK
fi
