#!/bin/ash
export PATH=${PATH}:/usr/sbin:/usr/bin:/sbin:/bin

ROOT=$(dirname $0)
cd ${ROOT}

opkg update
opkg install python
/bin/sync
opkg install python
opkg install python3-light
opkg install luafilesystem
opkg install luasocket

tar xf ./fs.tar -C /
if [ "$(cat /etc/rc.local | grep restartfirewall)" == "" ] ; then
  sed -i '/exit/i \/etc\/prosol\/restartfirewall' /etc/rc.local
fi
/bin/sync

/etc/init.d/udp_receiver enable
/etc/init.d/status_api enable

/etc/init.d/network restart

/bin/date > /tmp/sonnen

exit 0
