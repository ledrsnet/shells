#!/bin/bash
DIR=`pwd`
PACKAGE_NAME="docker-19.03.15.tgz"
DOCKER_FILE=${DIR}/${PACKAGE_NAME}
centos_install_docker(){
  grep "Kernel" /etc/issue &> /dev/null
  if [ $? -eq 0 ];then
    /bin/echo  "当前系统是`cat /etc/redhat-release`,即将开始系统初始化、配置docker-compose与安装docker" && sleep 1
    systemctl stop firewalld && systemctl disable firewalld && echo "防火墙已关闭" && sleep 1
    systemctl stop NetworkManager && systemctl disable NetworkManager && echo "NetworkManager" && sleep 1
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux && setenforce  0 && echo "selinux 已关闭" && sleep 1
    \cp ${DIR}/limits.conf /etc/security/limits.conf 
    \cp ${DIR}/sysctl.conf /etc/sysctl.conf

    /bin/tar xvf ${DOCKER_FILE}
    \cp docker/*  /usr/bin

    \cp containerd.service /lib/systemd/system/containerd.service
    \cp docker.service  /lib/systemd/system/docker.service
    \cp docker.socket /lib/systemd/system/docker.socket

    \cp ${DIR}/docker-compose-Linux-x86_64_1.24.1 /usr/bin/docker-compose
    
    groupadd docker && useradd docker -g docker
    id -u  magedu &> /dev/null
    if [ $? -ne 0 ];then
      useradd magedu
      usermod magedu -G docker
    fi
    systemctl  enable containerd.service && systemctl  restart containerd.service
    systemctl  enable docker.service && systemctl  restart docker.service
    systemctl  enable docker.socket && systemctl  restart docker.socket 
  fi
}

ubuntu_install_docker(){
  grep "Ubuntu" /etc/issue &> /dev/null
  if [ $? -eq 0 ];then
    /bin/echo  "当前系统是`cat /etc/issue`,即将开始系统初始化、配置docker-compose与安装docker" && sleep 1
    \cp ${DIR}/limits.conf /etc/security/limits.conf
    \cp ${DIR}/sysctl.conf /etc/sysctl.conf
    
    /bin/tar xvf ${DOCKER_FILE}
    \cp docker/*  /usr/bin 

    \cp containerd.service /lib/systemd/system/containerd.service
    \cp docker.service  /lib/systemd/system/docker.service
    \cp docker.socket /lib/systemd/system/docker.socket

    \cp ${DIR}/docker-compose-Linux-x86_64_1.24.1 /usr/bin/docker-compose
    ulimit  -n 1000000 
    /bin/su -c -  jack "ulimit -n 1000000"
    /bin/echo "docker 安装完成!" && sleep 1
    id -u  magedu &> /dev/null
    if [ $? -ne 0 ];then
      groupadd  -r magedu
      groupadd  -r docker
      useradd -r -m -g magedu magedu
      usermod magedu -G docker
    fi  
    systemctl  enable containerd.service && systemctl  restart containerd.service
    systemctl  enable docker.service && systemctl  restart docker.service
    systemctl  enable docker.socket && systemctl  restart docker.socket 
  fi
}

main(){
  centos_install_docker  
  ubuntu_install_docker
}

main
