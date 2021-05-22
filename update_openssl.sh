#!/bin/bash
#
#####################################################################
#
#Author:                LiangDong
#Email:                 395539184@qq.com
#Date:                  2021-05-22
#FileName：             update_openssl.sh
#URL:                   https://github.com/ledrsnet
#Description：          
#Copyright (C):         2021 All rights reserved
#
#####################################################################

host=(
10.0.0.17
10.0.0.27
10.0.0.37
)

echo ${host[*]}

for i in ${host[*]};do
    ssh $i -o StrictHostKeyChecking=no 'mkdir /opt/{packages,software}'
    scp -o StrictHostKeyChecking=no /opt/packages/openssl-OpenSSL_1_0_2u.tar.gz $i:/opt/packages/
    echo $i' send packages finished.'
ssh -o StrictHostKeyChecking=no $i <<EOF
tar -zxvf /opt/packages/openssl-OpenSSL_1_0_2u.tar.gz -C /opt/software
cd /opt/software/openssl-OpenSSL_1_0_2u
./config --prefix=/usr/local/openssl shared zlib
make depend
make & make install
mv /usr/bin/openssl /usr/bin/openssl.bak
mv /usr/include/openssl /usr/include/openssl.bak
ln -s /usr/local/openssl/bin/openssl /usr/bin/openssl
ln -s /usr/local/openssl/include/openssl /usr/include/openssl
echo "/usr/local/openssl/lib" >> /etc/ld.so.conf
ldconfig -v
openssl version -a
EOF
echo $i'update successfully'
done
