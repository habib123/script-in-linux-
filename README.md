
1.run setup for serialnumber on the VPN Server (login with admin, run  setup_linksys "SERIAL") (the server script is located on the VPN server under /srv/vera/setup_linksys)
2.install the python light package    opkg update          opkg install python3-light
3.update the cronjob list (firewall)
4.Update /etc/prosol/ftpsync with the attached script (rename the script to ftpsync)
5.Set Network bridge to 192.168.81.1 (in UI)
6.Update /etc/rc.local with the attached script
7.copy the restartfirewall script under /etc/prosol/ 
8.Update the /etc/prosol/config script with the attached one

Please note the attached file contains all data in the correct folder structure.
9.copy script "status_api" to /etc/init.d/status_api
10.copy script "status_api" to /etc/prosol/status_api
11.copy lua-file "StatusAPI.lua" to /etc/cmh-ludl/lua/StatusAPI.lua
12.copy script "udp_receiver" to /etc/init.d/udp_receiver
13.copy script "udp_receiver" to /etc/prosol/udp_receiver
14.copy pyhton script "udp_receiver_py" /etc/cmh-ludl/udp_receiver_py
15.make all scripts executable with chmod 755 SCRIPTNAME 
16.copy lua file "JsonDataProvider.lua" to /etc/cmh-ludl/lua/JsonDataProvider.lua
17.install python         opkg update          opkg install python
18.install lua filesystem     opkg update           opkg install luafilesystem
19.install luasocket     opkg update           opkg install luasocket
20.execute /etc/init.d/udp_receiver enable
21.execute /etc/init.d/status_api enable
22.Set up RestAPI to use the status data in the rest-api:  copy lua-file "RestAPI.lua" to /etc/cmh-ludl/lua/RestAPI.lua (please note this functionality is still under development)
