#!/bin/bash
#
#********************************************************************
#Author: wangxiaochun
#QQ: 29308620
#Date: 2020-02-12
#FileName： install_online_mysql5.7or8.0_for_centos
#URL: http://www.wangxiaochun.com
#Description： The test script
#Copyright (C): 2020 All rights reserved
#********************************************************************
#MySQL Download URL: https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.29-linux-glibc2.12-x86_64.tar.gz
#http://mirrors.163.com/mysql/Downloads/MySQL-5.7/mysql-5.7.31-linux-glibc2.12-x86_64.tar.gz
#http://mirrors.163.com/mysql/Downloads/MySQL-8.0/mysql-8.0.23-linux-glibc2.12-x86_64.tar.xz
. /etc/init.d/functions
SRC_DIR=`pwd`
MYSQL='mysql-5.7.33-linux-glibc2.12-x86_64.tar.gz'
URL=http://mirrors.163.com/mysql/Downloads/MySQL-5.7
#MYSQL='mysql-8.0.23-linux-glibc2.12-x86_64.tar.xz'
#URL=http://mirrors.163.com/mysql/Downloads/MySQL-8.0
COLOR='echo -e \E[01;31m'
END='\E[0m'
MYSQL_ROOT_PASSWORD=magedu
check (){
if [ $UID -ne 0 ]; then
action "当前用户不是root,安装失败" false
 exit 1
fi
cd  $SRC_DIR
rpm -q wget || yum -y -q install wget
wget  $URL/$MYSQL
if [ !  -e $MYSQL ];then
    $COLOR"缺少${MYSQL}文件"$END
$COLOR"请将相关软件放在${SRC_DIR}目录下"$END
    exit
elif [ -e /usr/local/mysql ];then
   action "数据库已存在，安装失败" false
    exit
else
return
fi
}
install_mysql(){
  $COLOR"开始安装MySQL数据库..."$END
yum  -y -q install libaio numactl-libs ncurses-compat-libs
  cd $SRC_DIR
 tar xf $MYSQL -C /usr/local/
  MYSQL_DIR=`echo $MYSQL| sed -nr 's/^(.*[0-9]).*/\1/p'`
  ln -s /usr/local/$MYSQL_DIR /usr/local/mysql
  chown -R root.root /usr/local/mysql/
 id mysql &> /dev/null || { useradd -s /sbin/nologin -r mysql ; action "创建mysql用户" true; }
   
  echo 'PATH=/usr/local/mysql/bin/:$PATH' > /etc/profile.d/mysql.sh
 . /etc/profile.d/mysql.sh
ln -s /usr/local/mysql/bin/* /usr/bin/
  cat > /etc/my.cnf <<-EOF
[mysqld]
server-id=`hostname -I|cut -d. -f4`
log-bin
datadir=/data/mysql
socket=/data/mysql/mysql.sock                         
                       
log-error=/data/mysql/mysql.log
pid-file=/data/mysql/mysql.pid
[client]
socket=/data/mysql/mysql.sock
EOF
 [ -d /data ] || mkdir /data
 mysqld --initialize --user=mysql --datadir=/data/mysql
  cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
 chkconfig --add mysqld
 chkconfig mysqld on
  service mysqld start
 [ $? -ne 0 ] && { $COLOR"数据库启动失败，退出!"$END;exit; }
  MYSQL_OLDPASSWORD=`awk '/A temporary password/{print $NF}' /data/mysql/mysql.log`
 mysqladmin  -uroot -p$MYSQL_OLDPASSWORD password $MYSQL_ROOT_PASSWORD&>/dev/null
 action "数据库安装完成" true
}
check
install_mysql
