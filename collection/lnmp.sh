#!/bin/bash
#
#********************************************************************
#Author:		wangxiaochun
#FileName：		lnmp.sh
#URL: 			http://www.wangxiacohun.com
#Description：		LNMP wordpress 博客系统 
#Copyright (C): 	2020 All rights reserved
#********************************************************************
SRC_DIR=/usr/local/src
NGINX='nginx-1.16.1.tar.gz'
MYSQL='mysql-5.7.29-el7-x86_64.tar.gz'
PHP='php-7.4.1.tar.xz'
APP='wordpress-5.3.2-zh_CN.tar.gz'
COLOR="echo -e \\033[01;31m"
END='\033[0m'
MYSQL_ROOT_PASSWORD=magedu
MYSQL_WORDPRESS_PASSWORD=magedu
CPU=`lscpu| awk '/^CPU\(s\):/{print $NF}'`

${COLOR}'开始安装基于LNMP的wordpress'$END
sleep 3

check_file (){
cd  $SRC_DIR
$COLOR"请将相关软件放在${SRC_DIR}目录下"$END
if [ ! -e $NGINX ];then
	$COLOR"缺少${NGINX}文件"$END
        exit
elif [ !  -e $MYSQL ];then
        $COLOR"缺少${MYSQL}文件"$END
        exit
elif [ ! -e $PHP ];then
        $COLOR"缺少${PHP}文件"$END
        exit
elif [ ! -e $APP ];then
        $COLOR"缺少${APP}文件"$END
        exit
else
	$COLOR"相关文件已准备好"$END
fi
} 
install_mysql(){
    $COLOR"开始安装MySQL数据库"$END
    cd $SRC_DIR
    tar xf $MYSQL -C /usr/local/
    if [ -e /usr/local/mysql ];then
        $COLOR"数据库已存在，安装失败"$END
        exit
    fi
    MYSQL_DIR=`echo $MYSQL| sed -nr 's/^(.*[0-9]).*/\1/p'`
    ln -s  /usr/local/$MYSQL_DIR /usr/local/mysql
    chown -R  root.root /usr/local/mysql/
    id mysql &> /dev/null || { useradd -s /sbin/nologin -r  mysql ; $COLOR"创建mysql用户"$END; }
    yum  -y -q install numactl-libs   libaio &> /dev/null
    
    echo 'PATH=/usr/local/mysql/bin/:$PATH' > /etc/profile.d/lamp.sh
    .  /etc/profile.d/lamp.sh
    cat > /etc/my.cnf <<-EOF
[mysqld]
server-id=1
log-bin
datadir=/data/mysql
socket=/data/mysql/mysql.sock                                                                                                   
log-error=/data/mysql/mysql.log
pid-file=/data/mysql/mysql.pid
[client]
socket=/data/mysql/mysql.sock
EOF
	[ -d /data/ ] || mkdir /data 
    mysqld --initialize --user=mysql --datadir=/data/mysql 
    cp /usr/local/mysql/support-files/mysql.server  /etc/init.d/mysqld
    chkconfig --add mysqld
    chkconfig mysqld on
    service mysqld start
    [ $? -ne 0 ] && { $COLOR"数据库启动失败，退出!"$END;exit; }
    MYSQL_OLDPASSWORD=`awk '/A temporary password/{print $NF}' /data/mysql/mysql.log`
    mysqladmin  -uroot -p$MYSQL_OLDPASSWORD password $MYSQL_ROOT_PASSWORD &>/dev/null
    $COLOR"数据库安装完成"$END
}


install_nginx(){
   ${COLOR}"开始安装NGINX"$END
   id nginx  &> /dev/null || { useradd -s /sbin/nologin -r  nginx; $COLOR"创建nginx用户"$END; }
   $COLOR"安装nginx相关包"$END
   yum -q -y install gcc pcre-devel openssl-devel zlib-devel perl-ExtUtils-Embed git &> /dev/null
   cd $SRC_DIR
   tar xf $NGINX 
   git clone https://github.com/openresty/echo-nginx-module.git || { $COLOR"下载NGINX第三方模块失败,退出!"$END;exit; }
   NGINX_DIR=`echo $NGINX| sed -nr 's/^(.*[0-9]).*/\1/p'`
   cd $NGINX_DIR
   ./configure --prefix=/apps/nginx --user=nginx --group=nginx --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_stub_status_module --with-http_gzip_static_module --with-http_perl_module --with-pcre --with-stream --with-stream_ssl_module --with-stream_realip_module --add-module=/usr/local/src/echo-nginx-module
   make -j $CPU && make install 
   [ $? -eq 0 ] && $COLOR"NGINX编译安装成功"$END ||  { $COLOR"NGINX编译安装失败,退出!"$END;exit; }
   [ -d /data/www ] || mkdir -pv /data/www/
   cat > /apps/nginx/conf/nginx.conf <<EOF
worker_processes  auto;
events {
    worker_connections  10240;
}
http {
    gzip on;
    gzip_comp_level 9;
    gzip_min_length 64;
    #gzip_vary on;
    gzip_types text/xml text/css  application/javascript;
    include       mime.types;
    default_type  application/octet-stream;
    server_tokens off;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
    sendfile        on;
	client_max_body_size 100m;
    keepalive_timeout  65;
    server {
        listen       80 default_server;
        server_name  localhost ; 
	    root /data/www ;
        access_log  logs/nginx.access.log  main;
        location / {
            root   /data/www/;
            index  index.php index.html index.htm;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
        location ~ \.php$ {
            root           /data/www;
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  /data/www\$fastcgi_script_name;
            include        fastcgi_params;
        }
    }
}
EOF
    echo  'PATH=/apps/nginx/sbin:$PATH' >> /etc/profile.d/lamp.sh
    cat > /usr/lib/systemd/system/nginx.service <<EOF
[Unit]
After=network.target remote-fs.target nss-lookup.target 

[Service]
Type=forking 

ExecStart=/apps/nginx/sbin/nginx

ExecReload=/apps/nginx/sbin/nginx -s reload

ExecStop=/apps/nginx/sbin/nginx -s stop

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl start nginx 
    systemctl is-active nginx &> /dev/null ||  { $COLOR"NGINX 启动失败,退出!"$END ; exit; }
    $COLOR"NGINX安装完成"
}
install_php (){
    ${COLOR}"开始安装PHP"$END
    yum -y -q  install gcc make libxml2-devel bzip2-devel libmcrypt-devel libsqlite3x-devel oniguruma-devel &>/dev/null
    cd $SRC_DIR
    tar xf $PHP
    PHP_DIR=`echo $PHP| sed -nr 's/^(.*[0-9]).*/\1/p'`
    cd $PHP_DIR
     ./configure --prefix=/apps/php74 --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-openssl    --with-zlib  --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d --enable-mbstring --enable-xml --enable-sockets --enable-fpm --enable-maintainer-zts --disable-fileinfo
    make -j $CPU && make install 
    [ $? -eq 0 ] && $COLOR"PHP编译安装成功"$END ||  { $COLOR"PHP编译安装失败,退出!"$END;exit; }
    cp php.ini-production  /etc/php.ini
	sed -i 's/^expose_php = On/expose_php = Off/' /etc/php.ini
	mkdir /etc/php.d/
    cat > /etc/php.d/opcache.ini <<EOF
[opcache]
zend_extension=opcache.so               
opcache.enable=1
EOF

    cp  sapi/fpm/php-fpm.service /usr/lib/systemd/system/
    cd /apps/php74/etc
    cp  php-fpm.conf.default  php-fpm.conf
    cd  php-fpm.d/
    cp www.conf.default www.conf
    id nginx  &> /dev/null || { useradd -s /sbin/nologin -r  nginx; $COLOR"创建nginx用户"$END; }
    sed -i.bak  -e  's/^user.*/user = nginx/' -e 's/^group.*/group = nginx/' /apps/php74/etc/php-fpm.d/www.conf
    systemctl daemon-reload
    systemctl start php-fpm 
    systemctl is-active  php-fpm &> /dev/null ||  { $COLOR"PHP-FPM 启动失败,退出!"$END ; exit; }
    $COLOR"PHP安装完成"

}
install_wordpress(){
    cd $SRC_DIR
    tar xf $APP  
    [ -d /data/www ] || mkdir -pv /data/www
    mv wordpress/* /data/www/
    chown -R nginx.nginx /data/www/wp-content/
    cd /data/www/
    mv wp-config-sample.php wp-config.php
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "create database wordpress;grant all on wordpress.* to wordpress@'127.0.0.1' identified by '$MYSQL_WORDPRESS_PASSWORD'" &>/dev/null
    sed -i.bak -e 's/database_name_here/wordpress/' -e 's/username_here/wordpress/' -e 's/password_here/'''$MYSQL_WORDPRESS_PASSWORD'''/' -e 's/localhost/127.0.0.1/'  wp-config.php
    $COLOR"WORDPRESS安装完成"
}

check_file

install_mysql

install_nginx

install_php

install_wordpress
