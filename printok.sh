#!/bin/bash
RED="\e[1;31m"
GREEN="\e[1;32m"
END="\e[0m"
WEIGHT=80
ALIGN="-" # - align left; "" align right
RES_COL=80


action(){
local tempvar=`echo $2|tr 'A-Z' 'a-z'`
local length=${#1}
case $tempvar in
*true)
    if [ $length -ge 100 ]; then
    ¦   echo "$1"
    ¦   #printf "%${ALIGN}${WEIGHT}s" && printf "[$GREEN  OK  $END]"
    ¦   echo -en \\033[${RES_COL}G
    ¦   printf "[$GREEN  OK  $END]"
    else
    ¦   #printf "%${ALIGN}${WEIGHT}s" "$1" && printf "[$GREEN  OK  $END]"
    ¦   echo -n "$1"
    ¦   echo -en \\033[${RES_COL}G
    ¦   printf "[$GREEN  OK  $END]"
    fi
    echo
    ;;

*false)
    if [ $length -ge 100 ]; then
    ¦   echo "$1"
    ¦   #printf "%${ALIGN}${WEIGHT}s" && printf "[${RED}FAILED$END]"
    ¦   echo -en \\033[${RES_COL}G
    ¦   printf "[${RED}FAILED$END]"
    else
    ¦   #printf "%${ALIGN}${WEIGHT}s" "$1" && printf "[${RED}FAILED$END]"
    ¦   echo -n "$1"
    ¦   echo -en \\033[${RES_COL}G
    ¦   printf "[${RED}FAILED$END]"
    fi

    echo
    ;;
*)
    echo "Usage: `basename $0` String true|false,return string with color."
    ;;
esac
}
