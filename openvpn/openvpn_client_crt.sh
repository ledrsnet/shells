#!/bin/bash
#
#####################################################################
#
#Author:                LiangDong
#Email:                 395539184@qq.com
#Date:                  2021-05-11
#FileName：             openvpn_client_crt.sh
#URL:                   https://github.com/ledrsnet
#Description：          
#Copyright (C):         2021 All rights reserved
#
#####################################################################

read -p "请输入要创建的客户端证书用户名: " CLIENT_NAME
read -p "请输入客户端证书的有效期：days" CLIENT_CRT_EXPIRE
read -p "是否设置私钥密码，y/n。" IS_SET_KEY

[ -z "$CLIENT_NAME" ] && { echo "client_name is empty.";exit 3; }
case "$CLIENT_CRT_EXPIRE" in
*[!0-9]*)
	echo "param error,please input Integer";
	exit 3;
	;;
*)
	;;
esac


CLIENT_RSA_SERVER_DIR="/etc/openvpn/easy-rsa-client"
SERVER_RSA_SERVER_DIR="/etc/openvpn/easy-rsa-server"
CLIENTS_HOME="/etc/openvpn/client"
GW_IP=10.0.0.150

# 生成客户端证书请求文件
cd ${CLIENT_RSA_SERVER_DIR}/3|| { echo "Cannot change to necessary directory."; exit 2; }

count=`ls $CLIENTS_HOME| sed -En "/${CLIENT_NAME}([0-9]{0,})/p"|wc -l`
index=0
repeatFlag="false"
if [  "$count" -ge 1 ];then
	index=`ls $CLIENTS_HOME| sed -En "s/${CLIENT_NAME}([0-9]{0,})/\1/p"|sort -nr|head -n 1`
	let index++
	repeatFlag="true"
	CLIENT_NAME+=$index
fi

case "$IS_SET_KEY" in
y|Y)
./easyrsa gen-req ${CLIENT_NAME} nopass<<EOF

EOF
;;
*)
	./easyrsa gen-req ${CLIENT_NAME}
	;;
esac

# 服务端签发证书
cd ${SERVER_RSA_SERVER_DIR}/3|| { echo "Cannot change to necessary directory."; exit 2; }
./easyrsa import-req ${CLIENT_RSA_SERVER_DIR}/3/pki/reqs/${CLIENT_NAME}.req ${CLIENT_NAME} || { echo "import-req error.";exit 2; }

#修改客户端证书有效期
sed -E '/set_var EASYRSA_CERT_EXPIRE/c\set_var EASYRSA_CERT_EXPIRE '${CLIENT_EXPIRE_DAYS} ${CLIENT_RSA_SERVER_DIR}/3/vars || { echo "Modify the Client certificate validity periods";exit 2; }

#签发客户端证书
./easyrsa sign client ${CLIENT_NAME}<<EOF
yes
EOF

[ ! $? -eq 0 ] && { echo "sign client crt error."; exit 2; }

mkdir /etc/openvpn/client/${CLIENT_NAME}/
find /etc/openvpn/ \( -name "${CLIENT_NAME}.key" -o -name "${CLIENT_NAME}.crt" -o -name ca.crt \) -exec cp {} /etc/openvpn/client/${CLIENT_NAME} \;
cat > /etc/openvpn/client/${CLIENT_NAME}/client.ovpn <<EOF
client
dev tun
proto tcp
remote  ${GW_IP}  1194        #生产中为OpenVPN公网IP
resolv-retry infinite
nobind
#persist-key
#persist-tun
ca ca.crt
cert ${CLIENT_NAME}.crt
key ${CLIENT_NAME}.key
remote-cert-tls server
#tls-auth ta.key 1
cipher AES-256-CBC
verb 3 #此值不能随意指定,否则无法通信
compress lz4-v2 #此项在OpenVPN2.4.X版本使用,需要和服务器端保持一致,如不指定,默认使用comp-lz压缩
EOF
[ $? -eq 0 ] && echo "configuration file finished." || echo "configuration file error."

cd /etc/openvpn/client/${CLIENT_NAME}/ && zip /data/${CLIENT_NAME}.zip ./* && echo "compress file is /data/${CLIENT_NAME}.zip" || { echo "compress file failed.";exit 2; }
[ repeatFlag = "true" ] && echo "因为客户端用户重名，您的账号改为${CLIENT_NAME},生成证书相关目录为/etc/openvpn/client/${CLIENT_NAME}" ||echo "您的账号为${CLIENT_NAME},生成证书相关目录为/etc/openvpn/client/${CLIENT_NAME}" 

