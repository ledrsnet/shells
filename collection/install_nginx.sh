#!/bin/bash
#
#********************************************************************
#Author:			wangxiaochun
#QQ: 				29308620
#Date: 				2020-12-01
#FileName：			install_nginx.sh
#URL: 				http://www.wangxiaochun.com
#Description：		The test script
#Copyright (C): 	2021 All rights reserved
#********************************************************************
SRC_DIR=/usr/local/src
NGINX_URL=http://nginx.org/download/
NGINX_FILE=nginx-1.18.0
TAR=.tar.gz
NGINX_INSTALL_DIR=/apps/nginx
CPUS=`lscpu |awk '/^CPU\(s\)/{print $2}'`

color () {
    RES_COL=60
    MOVE_TO_COL="echo -en \\033[${RES_COL}G"
    SETCOLOR_SUCCESS="echo -en \\033[1;32m"
    SETCOLOR_FAILURE="echo -en \\033[1;31m"
    SETCOLOR_WARNING="echo -en \\033[1;33m"
    SETCOLOR_NORMAL="echo -en \E[0m"
    echo -n "$1" && $MOVE_TO_COL
    echo -n "["
    if [ $2 = "success" -o $2 = "0" ] ;then
        ${SETCOLOR_SUCCESS}
        echo -n $"  OK  "    
    elif [ $2 = "failure" -o $2 = "1"  ] ;then 
        ${SETCOLOR_FAILURE}
        echo -n $"FAILED"
    else
        ${SETCOLOR_WARNING}
        echo -n $"WARNING"
    fi
    ${SETCOLOR_NORMAL}
    echo -n "]"
    echo 
}

os_type () {
   awk -F'[ "]' '/^NAME/{print $2}' /etc/os-release
}

os_version () {
   awk -F'"' '/^VERSION_ID/{print $2}' /etc/os-release
}

check () {
    [ -e ${NGINX_INSTALL_DIR} ] && { color "nginx 已安装,请卸载后再安装" 1; exit; }
    cd  ${SRC_DIR}
    if [  -e ${NGINX_FILE}${TAR} ];then
        color "相关文件已准备好" 0
    else
        color '开始下载 nginx 源码包' 0
        wget ${NGINX_URL}${NGINX_FILE}${TAR} 
        [ $? -ne 0 ] && { color "下载 ${NGINX_FILE}${TAR}文件失败" 1; exit; } 
    fi
} 

install () {
    color "开始安装 nginx" 0
    if id nginx  &> /dev/null;then
        color "nginx 用户已存在" 1 
    else
        useradd -s /sbin/nologin -r  nginx
        color "创建 nginx 用户" 0 
    fi
    color "开始安装 nginx 依赖包" 0
    if [ `os_type` == "CentOS" -a `os_version` == '8' ] ;then
        yum -y -q install make gcc-c++ libtool pcre pcre-devel zlib zlib-devel openssl openssl-devel perl-ExtUtils-Embed 
    elif [ `os_type` == "CentOS" -a `os_version` == '7' ];then
        yum -y -q  install make gcc pcre-devel openssl-devel zlib-devel perl-ExtUtils-Embed
    else
        apt update &> /dev/null
        apt -y install make gcc libpcre3 libpcre3-dev openssl libssl-dev zlib1g-dev &> /dev/null
    fi
    cd $SRC_DIR
    tar xf ${NGINX_FILE}${TAR}
    NGINX_DIR=`echo ${NGINX_FILE}${TAR}| sed -nr 's/^(.*[0-9]).*/\1/p'`
    cd ${NGINX_DIR}
    ./configure --prefix=${NGINX_INSTALL_DIR} --user=nginx --group=nginx --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_stub_status_module --with-http_gzip_static_module --with-pcre --with-stream --with-stream_ssl_module --with-stream_realip_module 
    make -j $CPUS && make install 
    [ $? -eq 0 ] && color "nginx 编译安装成功" 0 ||  { color "nginx 编译安装失败,退出!" 1 ;exit; }
    echo "PATH=${NGINX_INSTALL_DIR}/sbin:${PATH}" > /etc/profile.d/nginx.sh
    cat > /lib/systemd/system/nginx.service <<EOF
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=${NGINX_INSTALL_DIR}/logs/nginx.pid
ExecStartPre=/bin/rm -f ${NGINX_INSTALL_DIR}/logs/nginx.pid
ExecStartPre=${NGINX_INSTALL_DIR}/sbin/nginx -t
ExecStart=${NGINX_INSTALL_DIR}/sbin/nginx
ExecReload=/bin/kill -s HUP \$MAINPID
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=process
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now nginx &> /dev/null 
    systemctl is-active nginx &> /dev/null ||  { color "nginx 启动失败,退出!" 1 ; exit; }
    color "nginx 安装完成" 0
}

check
install
