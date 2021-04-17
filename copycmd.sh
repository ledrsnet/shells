#!/bin/bash
# 
#####################################################################
#
#Author:                LiangDong
#Email:                 395539184@qq.com
#Date:                  2021-04-17
#FileName：             copycmd.sh
#URL:                   https://github.com/ledrsnet
#Description：          
#Copyright (C):         2021 All rights reserved
#
#####################################################################
. printok.sh

ROOT_PATH="/mnt/sysroot"
TEMP_PATH=""
FULL_NAME=""
while read -p "Please input one command:" cmd;do
    [ "$cmd" = "quit" ] && exit 0
    `which $cmd &>/dev/null`  || { echo "输入命令非法.";exit 2; }
    FULL_NAME=`which $cmd`
    TEMP_PATH=$ROOT_PATH$(dirname $FULL_NAME)
    if [ -d $TEMP_PATH ];then
        cp -a $FULL_NAME $TEMP_PATH/
    else
        mkdir -p $TEMP_PATH || exit 2;
        cp -a $FULL_NAME $TEMP_PATH/
    fi
    getOkFailed "$cmd command copy finished." ok
    ldd $FULL_NAME | sed -rn "s#.*(/lib[0-9]+.*[0-9]) .*#\1#p" > temp.txt || exit 2;

    while read file;do
        TEMP_PATH=$ROOT_PATH$(dirname $file)
        if [ -d $TEMP_PATH ];then
            cp -a $file $TEMP_PATH/
        else
            mkdir -p $TEMP_PATH ||exit 2;
            cp -a $file $TEMP_PATH/
        fi
    done  < temp.txt
    rm -rf temp.txt
    getOkFailed "$cmd dependency copy finished." ok
done
