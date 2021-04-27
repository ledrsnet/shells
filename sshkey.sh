#!/bin/bash
# 
#####################################################################
#
#Author:                LiangDong
#Email:                 395539184@qq.com
#Date:                  2021-04-27
#FileName：             expect_ssh.sh
#URL:                   https://github.com/ledrsnet
#Description：          
#Copyright (C):         2021 All rights reserved
#
#####################################################################

COLOR="\e[1;32m"
END="\e[0m"
PASSWORD=Root2021
IP_LIST="
10.0.0.151
10.0.0.152
10.0.0.153
"

[ ! -f ~/.ssh/id_rsa ] && ssh-keygen -P "" -f ~/.ssh/id_rsa &> /dev/null
rpm -q expect &> /dev/null || yum install -y -q expect &> /dev/null

for ip in $IP_LIST;do
{
sshpass -p $PASSWORD ssh-copy-id $ip -o StrictHostKeyChecking=no &> /dev/null
echo -e $COLOR"$ip is ready"$END
}&
done
wait

echo -e $COLOR"Push ssh key is finished!"$END
