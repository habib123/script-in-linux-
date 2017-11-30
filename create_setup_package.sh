#!/bin/bash -e
BUILD_DIR=./build
rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}

unzip ./materials/1.1_linksys_StatusAPI_0_3.zip -d ${BUILD_DIR}/materials 
cp ./materials/src/* ${BUILD_DIR}/materials
cp ./materials/config ${BUILD_DIR}/materials

cd ${BUILD_DIR}

PKG_DIR=./package
mkdir -p ${PKG_DIR}

SETUP=./materials/setup.sh
#SETUP=./materials/setup_test_pi.sh
chmod 755 ${SETUP}
cp ${SETUP} ${PKG_DIR}/setup.sh

FS_DIR=./fs
mkdir -p ${FS_DIR}/etc

chmod 600 ./materials/1.1_linksys_StatusAPI/linksys_cronjobs.txt
mkdir -p ${FS_DIR}/etc/crontabs
cp -a ./materials/1.1_linksys_StatusAPI/linksys_cronjobs.txt ${FS_DIR}/etc/crontabs/root

chmod 755 ./materials/1.1_linksys_StatusAPI/linksys_ftp_sync.txt
mkdir -p ${FS_DIR}/etc/prosol
cp -a ./materials/1.1_linksys_StatusAPI/linksys_ftp_sync.txt ${FS_DIR}/etc/prosol/ftpsync

chmod 755 ./materials/1.1_linksys_StatusAPI/restartfirewall
cp -a ./materials/1.1_linksys_StatusAPI/restartfirewall ${FS_DIR}/etc/prosol

chmod 644 ./materials/network
mkdir -p ${FS_DIR}/etc/config
cp -a ./materials/network ${FS_DIR}/etc/config

chmod 755 ./materials/config
mkdir -p ${FS_DIR}/etc/prosol
cp -a ./materials/config ${FS_DIR}/etc/prosol

chmod 755 ./materials/1.1_linksys_StatusAPI/etc/init.d/status_api
mkdir -p ${FS_DIR}/etc/init.d
cp -a ./materials/1.1_linksys_StatusAPI/etc/init.d/status_api ${FS_DIR}/etc/init.d

chmod 755 ./materials/1.1_linksys_StatusAPI/etc/prosol/status_api
mkdir -p ${FS_DIR}/etc/prosol
cp -a ./materials/1.1_linksys_StatusAPI/etc/prosol/status_api ${FS_DIR}/etc/prosol

chmod 755 ./materials/1.1_linksys_StatusAPI/etc/cmh-ludl/lua/StatusAPI.lua
mkdir -p ${FS_DIR}/etc/cmh-ludl/lua
cp -a ./materials/1.1_linksys_StatusAPI/etc/cmh-ludl/lua/StatusAPI.lua ${FS_DIR}/etc/cmh-ludl/lua

chmod 755 ./materials/1.1_linksys_StatusAPI/etc/init.d/udp_receiver
mkdir -p ${FS_DIR}/etc/init.d
cp -a ./materials/1.1_linksys_StatusAPI/etc/init.d/udp_receiver ${FS_DIR}/etc/init.d

chmod 755 ./materials/1.1_linksys_StatusAPI/etc/prosol/udp_receiver
mkdir -p ${FS_DIR}/etc/prosol
cp -a ./materials/1.1_linksys_StatusAPI/etc/prosol/udp_receiver ${FS_DIR}/etc/prosol

chmod 755 ./materials/1.1_linksys_StatusAPI/etc/cmh-ludl/udp_receiver_py
mkdir -p ${FS_DIR}/etc/cmh-ludl
cp -a ./materials/1.1_linksys_StatusAPI/etc/cmh-ludl/udp_receiver_py ${FS_DIR}/etc/cmh-ludl

chmod 755 ./materials/1.1_linksys_StatusAPI/etc/cmh-ludl/lua/JsonDataProvider.lua
mkdir -p ${FS_DIR}/etc/cmh-ludl/lua
cp -a ./materials/1.1_linksys_StatusAPI/etc/cmh-ludl/lua/JsonDataProvider.lua ${FS_DIR}/etc/cmh-ludl/lua

chmod 755 ./materials/1.1_linksys_StatusAPI/etc/cmh-ludl/lua/RestAPI.lua
mkdir -p ${FS_DIR}/etc/cmh-ludl/lua
cp -a ./materials/1.1_linksys_StatusAPI/etc/cmh-ludl/lua/RestAPI.lua ${FS_DIR}/etc/cmh-ludl/lua/RestAPI.lua

cd ${FS_DIR}
tar cvf ../package/fs.tar .

cd ..
cd ${PKG_DIR}
tar cvf ../../setup.tar .

