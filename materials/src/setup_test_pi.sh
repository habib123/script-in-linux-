#!/bin/ash -e
ROOT=$(dirname $0)
cd ${ROOT}

echo "opkg update"
echo "opkg install python3-light python luafilesystem luasocket"

tar xf ./fs.tar -C $(mktemp -d)
#if [ "$(cat /etc/rc.local | grep restartfirewall)" == "" ] ; then
#  sed -i "/exit/ { N; s/^exit/\/etc\/prosol\/restartfirewall\n&/ }" /etc/rc.local
#fi
#/bin/sync

echo "/etc/init.d/udp_receiver enable"
echo "/etc/init.d/status_api enable"

echo "/etc/init.d/network restart"

exit 0
