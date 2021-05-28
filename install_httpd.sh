#!/bin/bash
#
#####################################################################
#
#Author:                LiangDong
#Email:                 395539184@qq.com
#Date:                  2021-05-28
#FileName：             install_httpd.sh
#URL:                   https://github.com/ledrsnet
#Description：          
#Copyright (C):         2021 All rights reserved
#
#####################################################################

declare -A packages=([APR_URL]=https://downloads.apache.org/apr/apr-1.7.0.tar.bz2 \
[APR_UTIL_URL]=https://downloads.apache.org//apr/apr-util-1.6.1.tar.bz2 \
[HTTPD_URL]=https://downloads.apache.org//httpd/httpd-2.4.46.tar.bz2 )

APR_DIR=`echo ${packages[APR_URL]}|sed -nE 's#^.*/(.*).tar.*#\1#p'`
APR_UTIL_DIR=`echo ${packages[APR_UTIL_URL]}|sed -nE 's#^.*/(.*).tar.*#\1#p'`
HTTPD_URL_DIR=`echo ${packages[HTTPD_URL]}|sed -nE 's#^.*/(.*).tar.*#\1#p'`
CPUS=`lscpu |awk '/^CPU\(s\)/{print $2}'`

#echo ${APR_DIR}
#echo ${APR_UTIL_DIR}
#echo ${HTTPD_URL_DIR}
#echo ${#packages[*]}

preCompile(){
echo 安装相关编译环境包..
yum -y install gcc make pcre-devel openssl-devel expat-devel
for i in ${packages[*]};do
    wget $i
    tar xf ${i##*/}
done
mv ${APR_DIR} ${HTTPD_URL_DIR}/srclib/apr
mv ${APR_UTIL_DIR} ${HTTPD_URL_DIR}/srclib/apr-util
echo 准备完成..
}
compile(){
echo 开始编译....
cd ${HTTPD_URL_DIR}
./configure \
--prefix=/apps/httpd24 \
--enable-so \
--enable-ssl \
--enable-cgi \
--enable-rewrite \
--with-zlib \
--with-pcre \
--with-included-apr \
--enable-modules=most \
--enable-mpms-shared=all \
--with-mpm=prefork

make -j $CPUS && make install
echo 编译完成..
}

postCompile(){
# 创建apache账户
id apache &> /dev/null || useradd -r -s /sbin/nologin apache
# 修改配置文件
sed -i 's/^User.*/User apache/' /apps/httpd24/conf/httpd.conf
sed -i 's/^Group.*/Group apache/' /apps/httpd24/conf/httpd.conf
# 配置环境变量
echo 'PATH="/apps/httpd24/bin:$PATH"' > /etc/profile.d/httpd.sh
. /etc/profile.d/httpd.sh
# 配置man帮助
echo 'MANDATORY_MANPATH  /apps/httpd/man' >> /etc/man_db.conf
# 创建service unit文件，设置开机启动
cat > /lib/systemd/system/httpd.service << EOF
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)
[Service]
Type=forking
ExecStart=/apps/httpd24/bin/apachectl start
ExecReload=/apps/httpd24/bin/apachectl graceful
ExecStop=/apps/httpd24/bin/apachectl stop
# We want systemd to give httpd some time to finish gracefully, but still want
# it to kill httpd after TimeoutStopSec if something went wrong during the
# graceful stop. Normally, Systemd sends SIGTERM signal right after the
# ExecStop, which would kill httpd. We are sending useless SIGCONT here to give
# httpd time to finish.
KillSignal=SIGCONT
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now httpd.service
}



preCompile
compile
postCompile
