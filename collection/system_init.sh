#!/bin/bash
#
#******************************************************************************
#Author:        zhanghui
#QQ:            19661891
#Date:          2021-05-20
#FileName:      reset.sh
#URL:           www.neteagles.cn
#Description:   reset for centos 6/7/8 & ubuntu 18.04/20.04
#Copyright (C): 2021 All rights reserved
#******************************************************************************
COLOR="echo -e \\033[01;31m"
END='\033[0m'

os(){
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release;then
        rpm -q redhat-lsb-core &> /dev/null || { ${COLOR}"安装lsb_release工具"${END};yum -y install  redhat-lsb-core &> /dev/null; }
    fi
    OS_ID=`lsb_release -is`
    OS_RELEASE=`lsb_release -rs`
    OS_RELEASE_VERSION=`lsb_release -rs |awk -F'.' '{print $1}'`
    OS_CODENAME=`lsb_release -cs`
}

disable_selinux(){
    if [ ${OS_ID} == "CentOS" ] &> /dev/null;then
        sed -ri.bak 's/^(SELINUX=).*/\1disabled/' /etc/selinux/config
        ${COLOR}"${OS_ID} ${OS_RELEASE} SELinux已禁用,请重新启动系统后才能生效!"${END}
    else
        ${COLOR}"${OS_ID} ${OS_RELEASE} SELinux默认没有安装,不用设置!"${END}
    fi
}

disable_firewall(){
    if [ ${OS_ID} == "CentOS" ] &> /dev/null;then
        rpm -q firewalld &> /dev/null && { systemctl disable --now firewalld &> /dev/null; ${COLOR}"${OS_ID} ${OS_RELEASE} Firewall防火墙已关闭!"${END}; } || ${COLOR}"${OS_ID} ${OS_RELEASE} 没有firewall防火墙服务,不用关闭！"${END}
    else
        dpkg -s ufw &> /dev/null && { systemctl disable --now ufw &> /dev/null; ${COLOR}"${OS_ID} ${OS_RELEASE} ufw防火墙已关闭!"${END}; } || ${COLOR}"${OS_ID} ${OS_RELEASE}  没有ufw防火墙服务,不用关闭！"${END}
    fi
}

optimization_sshd(){
    sed -i.bak -e 's/#UseDNS no/UseDNS no/' -e 's/GSSAPIAuthentication yes/GSSAPIAuthentication no/' /etc/ssh/sshd_config
    if [ ${OS_RELEASE_VERSION} == "6" ] &> /dev/null;then
        service sshd restart
    else
        systemctl restart sshd
    fi
    ${COLOR}"${OS_ID} ${OS_RELEASE} SSH已优化完成!"${END}
}

set_centos_alias(){
    cat >>~/.bashrc <<-EOF
alias cdnet="cd /etc/sysconfig/network-scripts"
alias vie0="vim /etc/sysconfig/network-scripts/ifcfg-eth0"
alias vie1="vim /etc/sysconfig/network-scripts/ifcfg-eth1"
alias scandisk="echo '- - -' > /sys/class/scsi_host/host0/scan;echo '- - -' > /sys/class/scsi_host/host1/scan;echo '- - -' > /sys/class/scsi_host/host2/scan"
EOF
    ${COLOR}"${OS_ID} ${OS_RELEASE} 系统别名已设置成功,请重新登陆后生效!"${END}
}

set_ubuntu_alias(){
    cat >>~/.bashrc <<-EOF
alias cdnet="cd /etc/netplan"
alias scandisk="echo '- - -' > /sys/class/scsi_host/host0/scan;echo '- - -' > /sys/class/scsi_host/host1/scan;echo '- - -' > /sys/class/scsi_host/host2/scan"
EOF
    ${COLOR}"${OS_ID} ${OS_RELEASE} 系统别名已设置成功,请重新登陆后生效!\e[0m"${END}
}

set_alias(){
    if [ ${OS_ID} == "CentOS" ] &> /dev/null;then
        set_centos_alias
    else
        set_ubuntu_alias
    fi
}

set_vimrc(){
    cat >~/.vimrc <<-EOF  
set ts=4
set expandtab
set ignorecase
set cursorline
set autoindent
autocmd BufNewFile *.sh exec ":call SetTitle()"
func SetTitle()
    if expand("%:e") == 'sh'
    call setline(1,"#!/bin/bash")
    call setline(2,"#")
    call setline(3,"#**********************************************************************************************")
    call setline(4,"#Author:        zhanghui")
    call setline(5,"#QQ:            19661891")
    call setline(6,"#Date:          ".strftime("%Y-%m-%d"))
    call setline(7,"#FileName:      ".expand("%"))
    call setline(8,"#URL:           www.cnblogs.com/neteagles")
    call setline(9,"#Description:   The test script")
    call setline(10,"#Copyright (C):".strftime("%Y")." All rights reserved")
    call setline(11,"#*********************************************************************************************")
    call setline(12,"")
    endif
endfunc
autocmd BufNewFile * normal G
EOF
    ${COLOR}"${OS_ID} ${OS_RELEASE} vimrc设置完成,请重新系统启动才能生效!"${END}
}

set_yum_centos8(){
    mkdir /etc/yum.repos.d/backup
    mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup
    cat > /etc/yum.repos.d/base.repo <<-EOF
[BaseOS]
name=BaseOS
baseurl=https://${ALIYUN}/centos/\$releasever/BaseOS/\$basearch/os/
        https://${HUAWEI}/centos/\$releasever/BaseOS/\$basearch/os/
        https://${TENTENT}/centos/\$releasever/BaseOS/\$basearch/os/
        https://${TUNA}/centos/\$releasever/BaseOS/\$basearch/os/
        http://${NETEASE}/centos/\$releasever/BaseOS/\$basearch/os/
        http://${SOHU}/centos/\$releasever/BaseOS/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[AppStream]
name=AppStream
baseurl=https://${ALIYUN}/centos/\$releasever/AppStream/\$basearch/os/
        https://${HUAWEI}/centos/\$releasever/AppStream/\$basearch/os/
        https://${TENTENT}/centos/\$releasever/AppStream/\$basearch/os/
        https://${TUNA}/centos/\$releasever/AppStream/\$basearch/os/
        http://${NETEASE}/centos/\$releasever/AppStream/\$basearch/os/
        http://${SOHU}/centos/\$releasever/AppStream/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[EPEL]
name=EPEL
baseurl=https://${ALIYUN}/epel/\$releasever/Everything/\$basearch/
        https://${HUAWEI}/epel/\$releasever/Everything/\$basearch/
        https://${TENTENT}/epel/\$releasever/Everything/\$basearch/
        https://${TUNA}/epel/\$releasever/Everything/\$basearch/
        https://${SOHU}/fedora-epel/\$releasever/Everything/\$basearch/
gpgcheck=1
gpgkey=https://${ALIYUN}/epel/RPM-GPG-KEY-EPEL-\$releasever

[extras]
name=extras
baseurl=https://${ALIYUN}/centos/\$releasever/extras/\$basearch/os/
        https://${HUAWEI}/centos/\$releasever/extras/\$basearch/os/
        https://${TENTENT}/centos/\$releasever/extras/\$basearch/os/
        https://${TUNA}/centos/\$releasever/extras/\$basearch/os/
        http://${NETEASE}/centos/\$releasever/extras/\$basearch/os/
        http://${SOHU}/centos/\$releasever/extras/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
enabled=1

[centosplus]
name=centosplus
baseurl=https://${ALIYUN}/centos/\$releasever/centosplus/\$basearch/os/
        https://${HUAWEI}/centos/\$releasever/centosplus/\$basearch/os/
        https://${TENTENT}/centos/\$releasever/centosplus/\$basearch/os/
        https://${TUNA}/centos/\$releasever/centosplus/\$basearch/os/
        http://${NETEASE}/centos/\$releasever/centosplus/\$basearch/os/
        http://${SOHU}/centos/\$releasever/centosplus/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[PowerTools]
name=PowerTools
baseurl=https://${ALIYUN}/centos/8/PowerTools/x86_64/os/
        https://${HUAWEI}/centos/8/PowerTools/x86_64/os/
        https://${TENTENT}/centos/8/PowerTools/x86_64/os/
        https://${TUNA}/centos/8/PowerTools/x86_64/os/
        http://${NETEASE}/centos/8/PowerTools/x86_64/os/
        http://${SOHU}/centos/8/PowerTools/x86_64/os/
gpgcheck=1
etpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
    dnf clean all &> /dev/null
    dnf repolist &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} YUM源设置完成!"${END}
}

set_yum_centos7(){
    mkdir /etc/yum.repos.d/backup
    mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup
    cat > /etc/yum.repos.d/base.repo <<-EOF
[base]
name=base
baseurl=https://${ALIYUN}/centos/\$releasever/os/\$basearch/
        https://${HUAWEI}/centos/\$releasever/os/\$basearch/
        https://${TENTENT}/centos/\$releasever/os/\$basearch/
        https://${TUNA}/centos/\$releasever/os/\$basearch/
        http://${NETEASE}/centos/\$releasever/os/\$basearch/
        http://${SOHU}/centos/\$releasever/os/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-\$releasever

[epel]
name=epel
baseurl=https://${ALIYUN}/epel/\$releasever/\$basearch/
        https://${HUAWEI}/epel/\$releasever/\$basearch/
        https://${TENTENT}/epel/\$releasever/\$basearch/
        https://${TUNA}/epel/\$releasever/\$basearch/
        https://${SOHU}/fedora-epel/\$releasever/\$basearch/
gpgcheck=1
gpgkey=https://${ALIYUN}/epel/RPM-GPG-KEY-EPEL-\$releasever

[extras]
name=extras
baseurl=https://${ALIYUN}/centos/\$releasever/extras/\$basearch/
        https://${HUAWEI}/centos/\$releasever/extras/\$basearch/
        https://${TENTENT}/centos/\$releasever/extras/\$basearch/
        https://${TUNA}/centos/\$releasever/extras/\$basearch/
        http://${NETEASE}/centos/\$releasever/extras/\$basearch/
        http://${SOHU}/centos/\$releasever/extras/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-\$releasever

[updates]
name=updates
baseurl=https://${ALIYUN}/centos/\$releasever/updates/\$basearch/
        https://${HUAWEI}/centos/\$releasever/updates/\$basearch/
        https://${TENTENT}centos/\$releasever/updates/\$basearch/
        https://${TUNA}/centos/\$releasever/updates/\$basearch/
        http://${NETEASE}/centos/\$releasever/updates/\$basearch/
        http://${SOHU}/centos/\$releasever/updates/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-\$releasever

[centosplus]
name=centosplus
baseurl=https://${ALIYUN}/centos/\$releasever/centosplus/\$basearch/
        https://${HUAWEI}/centos/\$releasever/centosplus/\$basearch/
        https://${TENTENT}/centos/\$releasever/centosplus/\$basearch/
        https://${TUNA}/centos/\$releasever/centosplus/\$basearch/
        http://${NETEASE}/centos/\$releasever/centosplus/\$basearch/
        http://${SOHU}/centos/\$releasever/centosplus/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-\$releasever
EOF
    yum clean all &> /dev/null
    yum repolist &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} YUM源设置完成!"${END}
}

set_yum_centos6(){
    mkdir /etc/yum.repos.d/backup
    mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup
    cat > /etc/yum.repos.d/base.repo <<-EOF
[base]
name=base
baseurl=https://${TENTENT}/centos/\$releasever/os/\$basearch/
        http://${SOHU}/centos/\$releasever/os/\$basearch/
        https://${ALIYUN}/centos-vault/\$releasever.10/os/\$basearch/
        https://${TUNA}/centos-vault/\$releasever.10/os/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-\$releasever

[epel]
name=epel
baseurl=https://${TENTENT}/epel/\$releasever/\$basearch/
        https://${FEDORA}/pub/archive/epel/\$releasever/\$basearch/
gpgcheck=1
gpgkey=https://${TENTENT}/epel/RPM-GPG-KEY-EPEL-\$releasever

[extras]
name=extras
baseurl=https://${TENTENT}/centos/\$releasever/os/\$basearch/
        http://${SOHU}/centos/\$releasever/extras/\$basearch/
        https://${ALIYUN}/centos-vault/\$releasever.10/extras/\$basearch/
        https://${TUNA}/centos-vault/\$releasever.10/extras/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-\$releasever

[updates]
name=updates
baseurl=https://${TENTENT}/centos/\$releasever/os/\$basearch/
        http://${SOHU}/centos/\$releasever/updates/\$basearch/
        https://${ALIYUN}/centos-vault/\$releasever.10/updates/\$basearch/
        https://${TUNA}/centos-vault/\$releasever.10/updates/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-\$releasever

[centosplus]
name=centosplus
baseurl=https://${TENTENT}/centos/\$releasever/os/\$basearch/
        http://${SOHU}/centos/\$releasever/centosplus/\$basearch/
        https://${ALIYUN}/centos-vault/\$releasever.10/centosplus/\$basearch/
        https://${TUNA}/centos-vault/\$releasever.10/centosplus/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-\$releasever
EOF
    yum clean all &> /dev/null
    yum repolist  &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} YUM源设置完成!"${END}
}

apt_aliyun(){
    URL=${ALIYUN}
}

apt_huawei(){
    URL=${HUAWEI}
}

apt_tencent(){
    URL=${TENTENT}
}

apt_tuna(){
    URL=${TUNA}
}

apt_netease(){
    URL=${NETEASE}
}

set_apt(){
    mv /etc/apt/sources.list /etc/apt/sources.list.bak
    cat > /etc/apt/sources.list <<-EOF
deb http://${URL}/ubuntu/ ${OS_CODENAME} main restricted universe multiverse
deb-src http://${URL}/ubuntu/ ${OS_CODENAME} main restricted universe multiverse

deb http://${URL}/ubuntu/ ${OS_CODENAME}-security main restricted universe multiverse
deb-src http://${URL}/ubuntu/ ${OS_CODENAME}-security main restricted universe multiverse

deb http://${URL}/ubuntu/ ${OS_CODENAME}-updates main restricted universe multiverse
deb-src http://${URL}/ubuntu/ ${OS_CODENAME}-updates main restricted universe multiverse

deb http://${URL}/ubuntu/ ${OS_CODENAME}-proposed main restricted universe multiverse
deb-src http://${URL}/ubuntu/ ${OS_CODENAME}-proposed main restricted universe multiverse

deb http://${URL}/ubuntu/ ${OS_CODENAME}-backports main restricted universe multiverse
deb-src http://${URL}/ubuntu/ ${OS_CODENAME}-backports main restricted universe multiverse
EOF
    apt update
    ${COLOR}"${OS_ID} ${OS_RELEASE} APT源设置完成!"${END}
}

apt_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)华为镜像源
3)腾讯镜像源
4)清华镜像源
5)网易镜像源
6)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-6)" NUM
        case ${NUM} in
        1)
            apt_aliyun
            set_apt
            ;;
        2)
            apt_huawei
            set_apt
            ;;
        3)
            apt_tencent
            set_apt
            ;;
        4)
            apt_tuna
            set_apt
            ;;
        5)
            apt_netease
            set_apt
            ;;
        6)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-6)!"${END}
            ;;
        esac
    done
}

set_package_repository(){
    ALIYUN=mirrors.aliyun.com
	TUNA=mirrors.tuna.tsinghua.edu.cn
	TENTENT=mirrors.cloud.tencent.com
	HUAWEI=repo.huaweicloud.com
	NETEASE=mirrors.163.com
	SOHU=mirrors.sohu.com
	FEDORA=archives.fedoraproject.org
    if [ ${OS_ID} == "CentOS" ] &> /dev/null;then
        if [ ${OS_RELEASE_VERSION} == "8" ] &> /dev/null;then
            set_yum_centos8
        elif [ ${OS_RELEASE_VERSION} == "7" ] &> /dev/null;then
            set_yum_centos7
        else
            set_yum_centos6
        fi
    else
        apt_menu
    fi
}

centos_minimal_install(){
    ${COLOR}'开始安装“Minimal安装建议安装软件包”,请稍等......'${END}
    yum -y install gcc make autoconf gcc-c++ glibc glibc-devel pcre pcre-devel openssl openssl-devel systemd-devel zlib-devel vim lrzsz tree tmux lsof tcpdump wget net-tools iotop bc bzip2 zip unzip nfs-utils man-pages &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} Minimal安装建议安装软件包已安装完成!"${END}
}

ubuntu_minimal_install(){
    ${COLOR}'开始安装“Minimal安装建议安装软件包”,请稍等......'${END}
    apt -y install iproute2 ntpdate tcpdump telnet traceroute nfs-kernel-server nfs-common lrzsz tree openssl libssl-dev libpcre3 libpcre3-dev zlib1g-dev gcc openssh-server iotop unzip zip
    ${COLOR}"${OS_ID} ${OS_RELEASE} Minimal安装建议安装软件包已安装完成!"${END}
}

minimal_install(){
    if [ ${OS_ID} == "CentOS" ] &> /dev/null;then
        centos_minimal_install
    else
        ubuntu_minimal_install
    fi
}

set_mail(){                                                                                                 
    if [ ${OS_ID} == "CentOS" ] &> /dev/null;then
        rpm -q mailx &> /dev/null || yum -y install mailx &> /dev/null
        cat >~/.mailrc <<-EOF
set from=19661891@qq.com
set smtp=smtp.qq.com
set smtp-auth-user=19661891@qq.com
set smtp-auth-password=hrlnpctmxkpqbjdd
set smtp-auth=login
set ssl-verify=ignore
EOF
    else
        dpkg -s mailutils &> /dev/null || apt -y install mailutils
    fi
    ${COLOR}"${OS_ID} ${OS_RELEASE} 邮件设置完成,请重新登录后才能生效!"${END}
}

set_sshd_port(){
    disable_selinux
    disable_firewall
    read -p "请输入端口号:" PORT
    sed -i 's/#Port 22/Port '${PORT}'/' /etc/ssh/sshd_config
    ${COLOR}"${OS_ID} ${OS_RELEASE} 更改SSH端口号已完成，请重启系统后生效!"${END}
}

set_centos_eth(){
    ETHNAME=`ip addr | awk -F"[ :]" '/^2/{print $3}'`
    #修改网卡名称配置文件
    sed -ri.bak '/^GRUB_CMDLINE_LINUX=/s@"$@ net.ifnames=0"@' /etc/default/grub
    grub2-mkconfig -o /boot/grub2/grub.cfg >& /dev/null

    #修改网卡文件名
    mv /etc/sysconfig/network-scripts/ifcfg-${ETHNAME} /etc/sysconfig/network-scripts/ifcfg-eth0
    ${COLOR}"${OS_ID} ${OS_RELEASE} 网卡名已修改成功，请重新启动系统后才能生效!"${END}
}

set_ubuntu_eth(){
    #修改网卡名称配置文件
    sed -ri.bak '/^GRUB_CMDLINE_LINUX=/s@"$@ net.ifnames=0"@' /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg >& /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} 网卡名已修改成功，请重新启动系统后才能生效!"${END}
}

set_eth(){
    if [ ${OS_ID} == "CentOS" ] &> /dev/null;then
        if [ ${OS_RELEASE_VERSION} == 6 ];then
            ${COLOR}"${OS_ID} ${OS_RELEASE} 不用修改网卡名"${END}
        else
            set_centos_eth
        fi
    else
        set_ubuntu_eth
    fi
}

check_ip(){
    local IP=$1
    VALID_CHECK=$(echo ${IP}|awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
    if echo ${IP}|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" >/dev/null; then
        if [ ${VALID_CHECK} == "yes" ]; then
            echo "IP ${IP}  available!"
            return 0
        else
            echo "IP ${IP} not available!"
            return 1
        fi
    else
        echo "IP format error!"
        return 1
    fi
}

set_centos_ip(){
    while true; do
        read -p "请输入IP地址:"  IP
        check_ip ${IP}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入网关地址:"  GATEWAY
        check_ip ${GATEWAY}
        [ $? -eq 0 ] && break
    done
    cat > /etc/sysconfig/network-scripts/ifcfg-eth0 <<-EOF
DEVICE=eth0
NAME=eth0
BOOTPROTO=none
ONBOOT=yes
IPADDR=${IP}
PREFIX=24
GATEWAY=${GATEWAY}
DNS1=223.5.5.5
DNS2=180.76.76.76
EOF
    ${COLOR}"${OS_ID} ${OS_RELEASE} IP地址和网关地址已修改成功,请重新启动系统后生效!"${END}
}

set_ubuntu_ip(){
    while true; do
        read -p "请输入IP地址:"  IP
        check_ip ${IP}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入网关地址:"  GATEWAY
        check_ip ${GATEWAY}
        [ $? -eq 0 ] && break
    done
    cat > /etc/netplan/01-netcfg.yaml <<-EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses: [${IP}/24] 
      gateway4: ${GATEWAY}
      nameservers:
        search: [neteagles.cn, neteagles.com]
        addresses: [223.5.5.5, 180.76.76.76]
EOF
    ${COLOR}"${OS_ID} ${OS_RELEASE} IP地址和网关地址已修改成功,请重新启动系统后生效!"${END}
}

set_ip(){
    if [ ${OS_ID} == "CentOS" ] &> /dev/null;then
        set_centos_ip
    else
        set_ubuntu_ip
    fi
}

set_hostname_all(){
    read -p "请输入主机名:"  HOST
    hostnamectl set-hostname ${HOST}
    ${COLOR}"${OS_ID} ${OS_RELEASE} 主机名设置成功，请重新登录生效!"${END}
}

set_hostname6(){
    read -p "请输入主机名:"  HOST
    sed -i.bak -r '/^HOSTNAME/s#^(HOSTNAME=).*#\1'${HOST}'#' /etc/sysconfig/network
    ${COLOR}"${OS_ID} ${OS_RELEASE} 主机名设置成功，请重新登录生效!"${END}
}

set_hostname(){
    if [ ${OS_RELEASE_VERSION} == 6 ] &> /dev/null;then
        set_hostname6
    else
        set_hostname_all
    fi
}

set_centos_ps1(){
    TIPS="${COLOR}${OS_ID} ${OS_RELEASE} PS1已设置完成,请重新登录生效!${END}"
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)31 红色
2)32 绿色
3)33 黄色
4)34 蓝色
5)35 紫色
6)36 青色
7)随机颜色
8)退出
EOF
        echo -e '\E[0m'

        read -p "请输入颜色编号(1-8)" NUM
        case ${NUM} in
        1)
            echo "PS1='\[\e[1;31m\][\u@\h \W]\\$ \[\e[0m\]'" > /etc/profile.d/env.sh
            ${TIPS}
            ;;
        2)
            echo "PS1='\[\e[1;32m\][\u@\h \W]\\$ \[\e[0m\]'" > /etc/profile.d/env.sh
            ${TIPS}
            ;;
        3)
            echo "PS1='\[\e[1;33m\][\u@\h \W]\\$ \[\e[0m\]'" > /etc/profile.d/env.sh
            ${TIPS}
            ;;
        4)
            echo "PS1='\[\e[1;34m\][\u@\h \W]\\$ \[\e[0m\]'" > /etc/profile.d/env.sh
            ${TIPS}
            ;;
        5)
            echo "PS1='\[\e[1;35m\][\u@\h \W]\\$ \[\e[0m\]'" > /etc/profile.d/env.sh
            ${TIPS}
            ;;
        6)
            echo "PS1='\[\e[1;36m\][\u@\h \W]\\$ \[\e[0m\]'" > /etc/profile.d/env.sh
            ${TIPS}
            ;;
        7)
            echo "PS1='\[\e[1;"$[RANDOM%7+31]"m\][\u@\h \W]\\$ \[\e[0m\]'" > /etc/profile.d/env.sh
            ${TIPS}
            ;;
        8)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-9)!"${END}
            ;;
        esac
    done
}

unsetps1(){
    CURRENTPS1SET=`awk -F"=" '/^PS1/{print $1}' ~/.bashrc | head -1`
    if [ ${CURRENTPS1SET} == "PS1" ] &> /dev/null;then
        sed -i "/^PS1.*/d" ~/.bashrc
        ${COLOR}已清空PS1设置,请重新设置!${END}
    else
        ${COLOR}没有设置PS1,请直接设置!${END}
    fi
}

set_ubuntu_ps1(){
    TIPS="${COLOR}${OS_ID} ${OS_RELEASE} PS1已设置完成,请重新登录生效!${END}"
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)31 红色
2)32 绿色
3)33 黄色
4)34 蓝色
5)35 紫色
6)36 青色
7)随机颜色
8)清空PS1设置
9)退出
EOF
        echo -e '\E[0m'

        read -p "请输入颜色编号(1-9)" NUM
        case ${NUM} in
        1)
            echo 'PS1="\[\e[1;31m\]${debian_chroot:+($debian_chroot)}\u@\h:\w\\$ \[\e[0m\]"' >> ~/.bashrc
            ${TIPS}
            ;;
        2)
            echo 'PS1="\[\e[1;32m\]${debian_chroot:+($debian_chroot)}\u@\h:\w\\$ \[\e[0m\]"' >> ~/.bashrc
            ${TIPS}
            ;;
        3)
            echo 'PS1="\[\e[1;33m\]${debian_chroot:+($debian_chroot)}\u@\h:\w\\$ \[\e[0m\]"' >> ~/.bashrc
            ${TIPS}
            ;;
        4)
            echo 'PS1="\[\e[1;34m\]${debian_chroot:+($debian_chroot)}\u@\h:\w\\$ \[\e[0m\]"' >> ~/.bashrc
            ${TIPS}
            ;;
        5)
            echo 'PS1="\[\e[1;35m\]${debian_chroot:+($debian_chroot)}\u@\h:\w\\$ \[\e[0m\]"' >> ~/.bashrc
            ${TIPS}
            ;;
        6)
            echo 'PS1="\[\e[1;36m\]${debian_chroot:+($debian_chroot)}\u@\h:\w\\$ \[\e[0m\]"' >> ~/.bashrc
            ${TIPS}
            ;;
        7)
            echo 'PS1="\[\e[1;'$[RANDOM%7+31]'m\]${debian_chroot:+($debian_chroot)}\u@\h:\w\\$ \[\e[0m\]"' >> ~/.bashrc
            ${TIPS}
            ;;
        8)
            unsetps1 
            ;;
        9)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-9)!"${END}
            ;;
        esac
    done
}

set_ps1(){
    if [ ${OS_ID} == "CentOS" ] &> /dev/null;then
        set_centos_ps1
    else
        set_ubuntu_ps1
    fi
}

set_swap(){
    sed -ri 's/.*swap.*/#&/' /etc/fstab
    swapoff -a
    ${COLOR}"${OS_ID} ${OS_RELEASE} 禁用swap成功!"${END}
}

set_kernel(){
    cat > /etc/sysctl.conf <<-EOF
# Controls source route verification
net.ipv4.conf.default.rp_filter = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 1

# Do not accept source routing
net.ipv4.conf.default.accept_source_route = 0

# Controls the System Request debugging functionality of the kernel
kernel.sysrq = 0

# Controls whether core dumps will append the PID to the core filename.
# Useful for debugging multi-threaded applications.
kernel.core_uses_pid = 1

# Controls the use of TCP syncookies
net.ipv4.tcp_syncookies = 1

# Disable netfilter on bridges.
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
net.bridge.bridge-nf-call-arptables = 0

# Controls the default maxmimum size of a mesage queue
kernel.msgmnb = 65536

# # Controls the maximum size of a message, in bytes
kernel.msgmax = 65536

# Controls the maximum shared segment size, in bytes
kernel.shmmax = 68719476736

# # Controls the maximum number of shared memory segments, in pages
kernel.shmall = 4294967296

# TCP kernel paramater
net.ipv4.tcp_mem = 786432 1048576 1572864
net.ipv4.tcp_rmem = 4096        87380   4194304
net.ipv4.tcp_wmem = 4096        16384   4194304
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_sack = 1

# socket buffer
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 20480
net.core.optmem_max = 81920


# TCP conn
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 15

# tcp conn reuse
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_timestamps = 0

net.ipv4.tcp_max_tw_buckets = 20000
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syncookies = 1

# keepalive conn
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.ip_local_port_range = 10001    65000

# swap
vm.overcommit_memory = 0
vm.swappiness = 10

#net.ipv4.conf.eth1.rp_filter = 0
#net.ipv4.conf.lo.arp_ignore = 1
#net.ipv4.conf.lo.arp_announce = 2
#net.ipv4.conf.all.arp_ignore = 1
#net.ipv4.conf.all.arp_announce = 2
EOF
    sysctl -p &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} 优化内核参数成功!"${END}
}

set_limits(){
    cat >> /etc/security/limits.conf <<-EOF
root     soft   core     unlimited
root     hard   core     unlimited
root     soft   nproc    1000000
root     hard   nproc    1000000
root     soft   nofile   1000000
root     hard   nofile   1000000
root     soft   memlock  32000
root     hard   memlock  32000
root     soft   msgqueue 8192000
root     hard   msgqueue 8192000
EOF
    ${COLOR}"${OS_ID} ${OS_RELEASE} 优化资源限制参数成功!"${END}
}

set_root_login(){
    PASSWORD=123456
    echo ${PASSWORD} |sudo -S sed -ri 's@#(PermitRootLogin )prohibit-password@\1yes@' /etc/ssh/sshd_config
    sudo systemctl restart sshd
    sudo -S passwd root <<-EOF
${PASSWORD}
${PASSWORD}
EOF
    ${COLOR}"${OS_ID} ${OS_RELEASE} root用户登录已设置完成,请重新登录后生效!"${END}
}

ubuntu_remove(){
    apt purge ufw lxd lxd-client lxcfs liblxc-common
    ${COLOR}"${OS_ID} ${OS_RELEASE} 无用软件包卸载完成!"${END}
}

os

PS3="请选择相应的编号(1-21):"
MENU="
禁用SELinux
关闭防火墙
优化SSH
设置系统别名
设置vimrc配置文件
1-5全执行
设置软件包仓库
Minimal安装建议安装软件
安装邮件服务并配置邮件
更改SSH端口号
修改网卡名
修改IP地址和网关地址
设置主机名
设置PS1(请进入选择颜色)
禁用SWAP
优化内核参数
优化资源限制参数
Ubuntu设置root用户登录
Ubuntu卸载无用软件包
重启系统
退出
"

select menu in ${MENU};do
    case ${REPLY} in
    1)
        disable_selinux
        ;;
    2)
        disable_firewall
        ;;
    3)
        optimization_sshd
        ;;
    4)
        set_alias
        ;;
    5)
        set_vimrc
        ;;
    6)
        disable_selinux
        disable_firewall
        optimization_sshd
        set_alias
        set_vimrc
        ;;
    7)
        set_package_repository
        ;;
    8)
        minimal_install
        ;;
    9)
        set_mail
        ;;
    10)
        set_sshd_port
        ;;
    11)
        set_eth
        ;;
    12)
        set_ip
        ;;
    13)
        set_hostname
        ;;
    14)
        set_ps1
        ;;
    15)
        set_swap
        ;;
    16)
        set_kernel
        ;;
    17)
        set_limits
        ;;
    18)
        set_root_login
        ;;
    19)
        ubuntu_remove
        ;;
    20)
        reboot
        ;;
    21)
        break
        ;;
    *)
        ${COLOR}"输入错误,请输入正确的数字(1-21)!"${END}
        ;;
    esac
done
