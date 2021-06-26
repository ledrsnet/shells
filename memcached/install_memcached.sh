#!/bin/bash
#
#####################################################################
#
#Author:                LiangDong
#Email:                 395539184@qq.com
#Date:                  2021-06-26
#FileName：             install_memcached.sh
#URL:                   https://github.com/ledrsnet
#Description：          
#Copyright (C):         2021 All rights reserved
#
#####################################################################
. /etc/init.d/functions
URL=http://memcached.org/files/
fileName=memcached-1.6.6
suffix=.tar.gz
srcDir=/usr/local/src
appPath=/apps/memcached

cd $srcDir || exit 2;
yum install -y gcc libevent-devel
wget $URL$fileName$suffix
tar xvf $fileName$suffix
cd $fileName || exit 2;
./configure --prefix=$appPath
make && make install
echo PATH=$appPath/bin:'$PATH' > /etc/profile.d/memcached.sh

useradd -r -s /sbin/nologin memcached
cat > /etc/sysconfig/memcached <<EOF
PORT="11211"
USER="memcached"
MAXCONN="1024"
CACHESIZE="64"
OPTIONS=""
EOF

cat > /lib/systemd/system/memcached.service <<EOF
[Unit]
Description=memcached daemon
Before=httpd.service
After=network.target
[Service]
EnvironmentFile=/etc/sysconfig/memcached
ExecStart=$appPath/bin/memcached -p \${PORT} -u \${USER} -m \${CACHESIZE} -c \${MAXCONN} \
$OPTIONS
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now memcached.service && action "Memcached编译安装成功"
