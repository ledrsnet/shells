#!/bin/bash
#
#*********************************************
#Author:            C3t4m
#Blog:              75j.xyz
#Description：      基于key验证多主机ssh访问
#Date:              2021-03-31
#*********************************************

PASS=123456
#设置网段最后的地址，4-255之间，越小扫描越快
END=254

IP=`ip a s eth0 | awk -F'[ /]+' 'NR==3{print $3}'`
NET=${IP%.*}.

rm -f /root/.ssh/id_rsa
[ -e ./SCANIP.log ] && rm -f SCANIP.log
for((i=3;i<="$END";i++));do
ping -c 1 -w 1  ${NET}$i &> /dev/null  && echo "${NET}$i" >> SCANIP.log &
done
wait

ssh-keygen -P "" -f /root/.ssh/id_rsa
rpm -q sshpass || yum -y install sshpass
sshpass -p $PASS ssh-copy-id -o StrictHostKeyChecking=no $IP 

AliveIP=(`cat SCANIP.log`)
for n in ${AliveIP[*]};do
sshpass -p $PASS scp -o StrictHostKeyChecking=no -r /root/.ssh root@${n}:
done

#把.ssh/known_hosts拷贝到所有主机，使它们第一次互相访问时不需要输入回车
for n in ${AliveIP[*]};do
scp /root/.ssh/known_hosts ${n}:.ssh/
done
