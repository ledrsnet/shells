#!/bin/bash
#########################################################
#Filename:   calIpRange.sh
#  Author:   LiangDong
#   Email:   395539184@qq.com
#    Date:   2021-04-04
#     URL:   https://github.com/ledrsnet
#    Desc:    输入IP网段，输出可用地址范围
#	      1.ip与掩码拆分，健壮性判断
#             2.按位与，求出网络号
#             3.计算该网段可用地址范围。
#     
#########################################################

set -eu

# 1.ip掩码拆分并进行健壮性判断
IP_MASK=$1
IP=`echo $IP_MASK |sed -En 's/^(.*)\/([0-9]{1,2})/\1/p'`
NET_MASK=`echo $IP_MASK |sed -En 's/^(.*)\/([0-9]{1,2})/\2/p'`
#echo IP_MASK=$IP_MASK
#echo IP=$IP
#echo NET_MASK=$NET_MASK
if [[ ! $IP =~ ^((1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])$ ]];then
   echo  "Ip address $IP is invalid . Useage: ip/mask" 
   exit 2
elif [ $NET_MASK -gt 32 -o $NET_MASK -lt 0 ];then
   echo "netmask should be in 0-32,your input netmask is $NET_MASK; Useage: ip/mask"
   exit 3
elif [ $NET_MASK -eq 32 ];then
	echo "主机位是32位，可用地址为$IP"
	exit 4
fi


# 2.求出ip第几段前几位作运算
IP_SUB1=`echo $IP |cut -d. -f1`
IP_SUB2=`echo $IP |cut -d. -f2`
IP_SUB3=`echo $IP |cut -d. -f3`

#IP_SUB4=`echo $IP |cut -d. -f4`
#IP_INDEX=`[ $[$NET_MASK/8+1] -ge 5 ] && echo 4 || echo $[$NET_MASK/8+1]`
#echo IP_INDEX=$IP_INDEX
#eval echo \$IP_SUB$IP_INDEX

IP_INDEX=`echo $[$NET_MASK/8+1]`
IP_SUB=`echo $IP |cut -d. -f$IP_INDEX`
IP_SUB_BINARY=`echo "obase=2;$IP_SUB" |bc |xargs printf "%08d"`
#echo IP_INDEX=$IP_INDEX
#echo IP_SUB=$IP_SUB
#echo IP_SUB_BINARY=$IP_SUB_BINARY
IP_SUB_NET_BIT=$[$NET_MASK%8]
IP_SUB_HOST_BIT=$[8-$NET_MASK%8]

#echo IP_SUB_NET_BIT=$IP_SUB_NET_BIT
#echo IP_SUB_HOST_BIT=$IP_SUB_HOST_BIT

# 3.网络位不变，主机位全为0
AVAILABLE_MIN_IP=$(echo $IP_SUB_BINARY|head -c${IP_SUB_NET_BIT} |xargs printf "ibase=2;%s`echo 00000000 |head -c${IP_SUB_HOST_BIT}`\n"|bc)
#echo AVAILABLE_MIN_IP=$AVAILABLE_MIN_IP

# 与操作 生成连续重复的字符串有什么好办法没?
#R_NET_MASK=
#R_HOST_MASK=
#R_MASK=
#for i in `seq ${IP_SUB_NET_BIT}`;do
#	R_NET_MASK+=1
#done
#for i in `seq ${IP_SUB_HOST_BIT}`;do
#	R_HOST_MASK+=0
#done
#R_MASK=`echo "ibase=2;$R_NET_MASK$R_HOST_MASK"|bc`
#echo R_MASK=$R_MASK
#A_MIN_IP=$[$IP_SUB&$R_MASK]
#echo A_MIN_IP=$A_MIN_IP


# 网络位不变，主机位全为1
AVAILABLE_MAX_IP=$(echo $IP_SUB_BINARY|head -c${IP_SUB_NET_BIT} |xargs printf "ibase=2;%s`echo 11111111 |head -c${IP_SUB_HOST_BIT}`\n"|bc)
#echo AVAILABLE_MAX_IP=$AVAILABLE_MAX_IP

# 4.输出可用地址范围
case $IP_INDEX in
1)
	echo "$IP_MASK该网段网络号为${AVAILABLE_MIN_IP}.0.0.0"
	echo "$IP_MASK该网段最小可用地址为${AVAILABLE_MIN_IP}.0.0.1"
	echo "$IP_MASK该网段最大可用地址为${AVAILABLE_MAX_IP}.255.255.254"
	echo "$IP_MASK该网段广播地址为${AVAILABLE_MAX_IP}.255.255.255"
	;;
2)
	echo "$IP_MASK该网段网络号为${IP_SUB1}.${AVAILABLE_MIN_IP}.0.0"
	echo "$IP_MASK该网段最小可用地址为${IP_SUB1}.${AVAILABLE_MIN_IP}.0.1"
	echo "$IP_MASK该网段最大可用地址为${IP_SUB1}.${AVAILABLE_MAX_IP}.255.254"
	echo "$IP_MASK该网段广播地址为${IP_SUB1}.${AVAILABLE_MAX_IP}.255.255"
	;;
3)
	echo "$IP_MASK该网段网络号为${IP_SUB1}.${IP_SUB2}.${AVAILABLE_MIN_IP}.0"
	echo "$IP_MASK该网段最小可用地址为${IP_SUB1}.${IP_SUB2}.${AVAILABLE_MIN_IP}.1"
	echo "$IP_MASK该网段最大可用地址为${IP_SUB1}.${IP_SUB2}.${AVAILABLE_MAX_IP}.254"
	echo "$IP_MASK该网段广播地址为${IP_SUB1}.${IP_SUB2}.${AVAILABLE_MAX_IP}.255"
	;;
4)
	echo "$IP_MASK该网段网络号为${IP_SUB1}.${IP_SUB2}.${IP_SUB3}.${AVAILABLE_MIN_IP}"
	echo "$IP_MASK该网段最小可用地址为${IP_SUB1}.${IP_SUB2}.${IP_SUB3}.$[${AVAILABLE_MIN_IP}+1]"
	echo "$IP_MASK该网段最大可用地址为${IP_SUB1}.${IP_SUB2}.${IP_SUB3}.$[${AVAILABLE_MAX_IP}-1]"
	echo "$IP_MASK该网段广播地址为${IP_SUB1}.${IP_SUB2}.${IP_SUB3}.${AVAILABLE_MAX_IP}"
	;;
*)
	echo "Calculator Error Exception!"
esac


