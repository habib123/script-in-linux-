#!/bin/bash -e
ROOT=$(dirname $0)
cd ${ROOT}

opkg update
opkg install python3-light python luafilesystem luasocket

tar xf ./fs.tar -C /
if [ "$(cat /etc/rc.local | grep restartfirewall)" == "" ] ; then
  sed -i "/exit/  \/etc\/prosol\/restartfirewall\ " /etc/rc.local
fi
/bin/sync

/etc/init.d/udp_receiver enable
/etc/init.d/status_api enable

/etc/init.d/network restart

exit 0
