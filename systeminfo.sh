#!/bin/bash
#########################################################
#Filename:   systeminfo.sh
#  Author:   LiangDong
#   Email:   395539184@qq.com
#    Date:   2021-04-04
#     URL:   https://github.com/ledrsnet
#    Desc:   display current system info     
#     
#########################################################

# 主机名，ip地址，系统版本，内核版本信息，cpu，内存信息，磁盘信息
set -ue
BLACK="\033[1;30m"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
PURPLE="\033[1;35m"
PINK="\033[1;36m"
END="\e[0;0m"

echo "#####################################"
echo
echo -e "HOSTNAME: ${RED}`hostname`"$END
echo -e "IP-ADDRESS: ${RED}`ifconfig |sed -En '2s#.*inet ([0-9.]+) .*$#\1#p' `"$END
echo -e "OS-RELEASES: ${RED}` cat /etc/centos-release 2>/dev/null|| lsb_release -a 2>/dev/null|sed -En '2p'|awk '{print $2,$3}' `" $END
echo -e "KERNEL-RELEASES: ${RED}`uname -r`"$END
echo -e "CPU-INFO: ${RED}`lscpu |sed -En '/^Model name/s/.* (Intel.*)$/\1/p'`"$END
echo -e "MEM-INFO: ${RED}`free -h |sed -n '2p' | tr -s ' '|cut -d' ' -f2`"$END
echo -e "DISK-INFO: ${RED}`lsblk |grep -E '^sd'|tr -s ' '|cut -d ' ' -f1,4`"$END
echo
echo "#####################################"
