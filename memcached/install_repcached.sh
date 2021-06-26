#!/bin/bash
#
#####################################################################
#
#Author:                LiangDong
#Email:                 395539184@qq.com
#Date:                  2021-06-26
#FileName：             install_repmemcached.sh
#URL:                   https://github.com/ledrsnet
#Description：          
#Copyright (C):         2021 All rights reserved
#
#####################################################################
. /etc/init.d/functions
URL=https://jaist.dl.sourceforge.net/project/repcached/repcached/2.2.1-1.2.8/
fileName=memcached-1.2.8-repcached-2.2.1
suffix=.tar.gz
srcDir=/usr/local/src
appPath=/apps/repcached
peerAddress=10.0.0.7

cd $srcDir || exit 2;
yum install -y gcc libevent libevent-devel
wget $URL$fileName$suffix
tar xvf $fileName$suffix
cd $fileName || exit 2;
./configure --prefix=$appPath --enable-replication

sed -i.bak -e '57d' -e '59d' memcached.c

make && make install

echo PATH=$appPath/bin:'$PATH' > /etc/profile.d/repcached.sh
source /etc/profile.d/repcached.sh

useradd -r -s /sbin/nologin memcached

$appPath/bin/memcached -d -m 2048 -p 11211 -u memcached -c 2048 -x $peerAddress

if [ $? -eq 0 ];then
    action "repcached编译安装并启动成功!"
else
    action "repcached编译安装启动失败!" false
fi
