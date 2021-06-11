#!/bin/bash
#
#********************************************************************
#Author:		wangxiaochun
#QQ: 			29308620
#Date: 			2020-02-07
#FileName：		certificate.sh
#URL: 			http://www.liwenliang.org
#Description：		本脚本纪念武汉疫情鸣笛人李文亮医生
#Copyright (C): 	2020 All rights reserved
#********************************************************************
CA_SUBJECT="/O=heaven/CN=ca.god.com"
SUBJECT="/C=CN/ST=hubei/L=wuhan/O=Central.Hospital/CN=*.liwenliang.org"
SERIAL=34
EXPIRE=202002
FILE=app

openssl req  -x509 -newkey rsa:2048 -subj $CA_SUBJECT -keyout ca.key -nodes -days 202002 -out ca.crt

openssl req -newkey rsa:2048 -nodes -keyout ${FILE}.key  -subj $SUBJECT -out ${FILE}.csr

openssl x509 -req -in ${FILE}.csr  -CA ca.crt -CAkey ca.key -set_serial $SERIAL  -days $EXPIRE -out ${FILE}.crt

chmod 600 ${FILE}.key ca.key
