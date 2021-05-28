#!/bin/bash
# 
#####################################################################
#
#Author:                LiangDong
#Email:                 395539184@qq.com
#Date:                  2021-04-17
#FileName：             printok.sh
#URL:                   https://github.com/ledrsnet
#Description：          
#Copyright (C):         2021 All rights reserved
#
#####################################################################
RED="\e[1;31m"
GREEN="\e[1;32m"
END="\e[0m"
WEIGHT=100
ALIGN="-" # - align left; "" align right


action(){
local tempvar=`echo $2|tr 'A-Z' 'a-z'`
local length=${#1}
case $tempvar in
true)
    if [ $length -ge 100 ]; then
        echo "$1"
        printf "%${ALIGN}${WEIGHT}s" && printf "[$GREEN  OK  $END]"
    else
        printf "%${ALIGN}${WEIGHT}s" "$1" && printf "[$GREEN  OK  $END]"
    fi
    echo
    ;;

false)
    if [ $length -ge 100 ]; then
        echo "$1"
        printf "%${ALIGN}${WEIGHT}s" && printf "[${RED}FAILED$END]"
    else
        printf "%${ALIGN}${WEIGHT}s" "$1" && printf "[${RED}FAILED$END]"
    fi
    echo
    ;;
*)
    echo "Usage: `basename $0` String true|false,return string with color."
    ;;
esac
}
