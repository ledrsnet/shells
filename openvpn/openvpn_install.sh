#!/bin/bash
# 
#####################################################################
#
#Author:                LiangDong
#Email:                 395539184@qq.com
#Date:                  2021-05-11
#FileName：             openvpn_install.sh
#URL:                   https://github.com/ledrsnet
#Description：          
#Copyright (C):         2021 All rights reserved
#
#####################################################################
set -eu
. printok.sh

ERR_INSTALL=60
ERR_COPY=61
ERR_PARAM=62
ERR_XCD=63
ERR_OTHER=64

DEFAULT_CA_EXPIRE_DAYS=3650
DEFAULT_SERVER_EXPIRE_DAYS=825
DEFAULT_CLIENT_EXPIRE_DAYS=$DEFAULT_SERVER_EXPIRE_DAYS
OS_VERSION=`sed -En '3s#.*="?([[:alnum:]]+)["]?$#\1#p' /etc/os-release`
OS_VERSION_NO=`awk -F "=" 'NR==2{print $2}' /etc/os-release |tr -d "\""`
SERVER_RSA_SERVER_DIR="/etc/openvpn/easy-rsa-server"
CLIENT_RSA_SERVER_DIR="/etc/openvpn/easy-rsa-client"




read -p "请输入CA证书的有效期，默认${DEFAULT_CA_EXPIRE_DAYS}天:"  CA_EXPIRE_DAYS
read -p "请输入服务器证书的有效期，默认${DEFAULT_SERVER_EXPIRE_DAYS}天：" SERVER_EXPIRE_DAYS


# 初始化服务配置参数
case "$CA_EXPIRE_DAYS" in
"")
	CA_EXPIRE_DAYS=$DEFAULT_CA_EXPIRE_DAYS
	;;
*[!0-9]*)
	echo "param error,please input Integer"
	exit $ERR_PARAM
	;;
*)
	;;
esac

case "$SERVER_EXPIRE_DAYS" in
"")
	SERVER_EXPIRE_DAYS=$DEFAULT_SERVER_EXPIRE_DAYS
	;;
*[!0-9]*)
	echo "param error,please input Integer"
	exit $ERR_PARAM
	;;
*)
	;;
esac




####################准备环境####################
# install package
if [ "$OS_VERSION" = "ubunutu" ];then
	apt -y install openvpn easy-rsa && getOkFailed "Installe OPENVPN EASY-RSA Package" ok || { getOkFailed "Installe OPENVPN EASY-RSA Package" failed;exit $ERR_INSTALL; }
elif [ "$OS_VERSION" = "centos" ];then
	yum install -y openvpn easy-rsa && getOkFailed "Installe OPENVPN EASY-RSA Package" ok || { getOkFailed "Installe OPENVPN EASY-RSA Package" failed;exit $ERR_INSTALL; }
fi

# Generate the server configuration file
cp /usr/share/doc/openvpn/sample/sample-config-files/server.conf /etc/openvpn/ && getOkFailed "Generate the server configuration file" ok || { getOkFailed "Generate the server configuration file" failed;exit $ERR_COPY; }

#准备证书签发相关文件
cp -r /usr/share/easy-rsa/ "$SERVER_RSA_SERVER_DIR" && getOkFailed "Prepare documents related to certificate issuance" ok || { getOkFailed "Prepare documents related to certificate issuance" failed;exit $ERR_COPY; }
cd ${SERVER_RSA_SERVER_DIR}/3 || { getOkFailed "Cannot change to necessary directory." failed; exit $ERR_XCD; }

#准备签发证书相关变量的配置文件
cp /usr/share/doc/easy-rsa/vars.example ${SERVER_RSA_SERVER_DIR}/3/vars  && getOkFailed "Prepare configuration files for variables related to the issuance of certificates" ok || { getOkFailed "Prepare configuration files for variables related to the issuance of certificates" failed;exit $ERR_COPY; }

#修改CA和服务器证书有效期
sed -Ei.bak -e '/set_var EASYRSA_CA_EXPIRE/c\set_var EASYRSA_CA_EXPIRE '${CA_EXPIRE_DAYS} -e '/set_var EASYRSA_CERT_EXPIRE/c\set_var EASYRSA_CERT_EXPIRE '${SERVER_EXPIRE_DAYS} ${SERVER_RSA_SERVER_DIR}/3/vars   && getOkFailed "Modify the CA and server certificate validity periods" ok || { getOkFailed "Modify the CA and server certificate validity periods" failed;exit $ERR_OTHER; }


####################准备环境END...####################

####################初始化PKI和CA签发机构环境及颁发openvpn服务器证书####################

#初始化PKI
./easyrsa init-pki || { getOkFailed "init-pki failed." failed; exit $ERR_OTHER; }

#自建CA
./easyrsa build-ca nopass <<EOF

EOF

[ $? -eq 0 ] || { getOkFailed "build-ca failed." failed; exit $ERR_OTHER; }

#创建服务器证书请求
./easyrsa gen-req openvpn-server nopass<<EOF

EOF
[ $? -eq 0 ] || { getOkFailed "gen-req failed." failed; exit $ERR_OTHER; }

#颁发服务端证书
./easyrsa sign server openvpn-server<<EOF
yes
EOF

[ $? -eq 0 ] || { getOkFailed "sign-server-crt failed." failed; exit $ERR_OTHER; }

#创建DH密钥进行加密
./easyrsa gen-dh || { getOkFailed "generate dh.pem failed." failed; exit $ERR_OTHER; }

####################初始化PKI和CA签发机构环境及颁发openvpn服务器证书END...####################

####################客户端证书环境####################
#准备客户端证书签发相关文件
cp -r /usr/share/easy-rsa/ ${CLIENT_RSA_SERVER_DIR} && getOkFailed "Prepare documents related to client certificate issuance" ok || { getOkFailed "Prepare documents related to client certificate issuance" failed;exit $ERR_COPY; }
#准备证书签发相关文件
cp /usr/share/doc/easy-rsa/vars.example ${CLIENT_RSA_SERVER_DIR}/3/vars  && getOkFailed "Prepare configuration files for variables related to the client issuance of certificates" ok || { getOkFailed "Prepare configuration files for variables related to the client issuance of certificates" failed;exit $ERR_COPY; }
cd ${CLIENT_RSA_SERVER_DIR}/3 || { getOkFailed "Cannot change to necessary directory." failed; exit $ERR_XCD; }


#生成证书申请所需目录pki和文件
./easyrsa init-pki || { getOkFailed "init-pki failed." failed; exit $ERR_OTHER; }

####################客户端证书环境END...####################


#################### 将CA和服务器证书相关文件复制到服务器相应的目录...####################
mkdir /etc/openvpn/certs || { getOkFailed "mkdir certs directory error." failed; exit $ERR_OTHER; }
cp ${SERVER_RSA_SERVER_DIR}/3/pki/ca.crt /etc/openvpn/certs/ &&\
cp ${SERVER_RSA_SERVER_DIR}/3/pki/issued/openvpn-server.crt /etc/openvpn/certs/ &&\
cp ${SERVER_RSA_SERVER_DIR}/3/pki/private/openvpn-server.key /etc/openvpn/certs/ &&\
cp ${SERVER_RSA_SERVER_DIR}/3/pki/dh.pem /etc/openvpn/certs/ ||   { getOkFailed "cp related file to certs directory error." failed; exit $ERR_COPY; }
####################将CA和服务器证书相关文件复制到服务器相应的目录END...####################


####################修改OPENVPN配置文件####################
cat > /etc/openvpn/server.conf<<EOF
port 1194
proto tcp
dev tun
ca /etc/openvpn/certs/ca.crt
cert /etc/openvpn/certs/openvpn-server.crt
key /etc/openvpn/certs/openvpn-server.key  # This file should be kept secret
dh /etc/openvpn/certs/dh.pem
server 10.8.0.0 255.255.255.0
push "route 172.30.0.0 255.255.255.0"
keepalive 10 120
cipher AES-256-CBC
compress lz4-v2
push "compress lz4-v2"
max-clients 2048
user openvpn
group openvpn
status /var/log/openvpn/openvpn-status.log
log-append /var/log/openvpn/openvpn.log
verb 3
mute 20
EOF
####################修改OPENVPN配置文件END..####################
[ $? -eq 0 ]  || { getOkFailed "modify /etc/openvpn/server.conf falied " falied;exit $ERR_OTHER; }
mkdir /var/log/openvpn && chown openvpn.openvpn /var/log/openvpn || { getOkFailed "创建日志目录失败" failed;exit $ERR_OTHER; }


####################开启转发和修改IPTABLES规则####################
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf && sysctl -p && getOkFailed "open ip_forward" ok || { getOkFailed "open ip_forward" failed; exit $ERR_OTHER; }
echo 'iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j MASQUERADE' >> /etc/rc.d/rc.local && chmod +x /etc/rc.d/rc.local &&\
/etc/rc.d/rc.local && getOkFailed "Add iptables rule susscessfully." ok|| { getOkFailed "Add iptables rule susscessfully." failed; exit $ERR_OTHER; }
####################开启转发和修改IPTABLES规则END...####################

#启动 OpenVPN 服务
if [ "$OS_VERSION" = "centos" ] && [ "$OS_VERSION_NO" = 8 ];then

cat > /usr/lib/systemd/system/openvpn@.service<<EOF
[Unit]
Description=OpenVPN Robust And Highly Flexible Tunneling Application On %I
After=network.target
[Service]
Type=notify
PrivateTmp=true
ExecStart=/usr/sbin/openvpn --cd /etc/openvpn/ --config %i.conf
[Install]
WantedBy=multi-user.target
EOF

	[ $? -eq 0 ] || { getOkFailed "Create openvpn@service failed.." failed;exit $ERR_OTHER; }
	systemctl daemon-reload && systemctl enable --now openvpn@server && getOkFailed "OpenVPN start Successfully." ok || { getOkFailed "OpenVPN start Failed" failed;exit $ERR_OTHER; }
else
	systemctl enable --now openvpn@server && getOkFailed "OpenVPN start Successfully." ok || { getOkFailed "OpenVPN start Failed" failed;exit $ERR_OTHER; }
fi

getOkFailed "CA和OPENVPN部署完成.." ok
#至此，服务器部署完毕，后期客户端证书申请使用另一个脚本

