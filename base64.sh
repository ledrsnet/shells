#!/bin/bash
#
#####################################################################
#
#Author:                LiangDong
#Email:                 395539184@qq.com
#Date:                  2021-04-23
#FileName：             base64.sh
#URL:                   https://github.com/ledrsnet
#Description：          base64加解码，暂不支持中文
#Copyright (C):         2021 All rights reserved
#
#####################################################################

#初始化base64编码表和索引表(解码使用)
baseCode=(`echo {A..Z} {a..z} {0..9} + /`)
declare -A baseIndexCode
for i in ${!baseCode[@]};do
    baseIndexCode[${baseCode[$i]}]=$i
done


#错误码
ERR_NULLPARM=2


#base64编码
baseEncode(){
for((i=0;i<${#binaryStr};i+=24));do
    buffers=${binaryStr:$i:24}

    [ ${#buffers} -lt 24 ] && eqFlag=true

    buffers+=`echo 000000000000000000000000|head -c $[24-${#buffers}]`
    for((j=0;j<${#buffers};j+=6));do
        tempBin=${buffers:$j:6}
        #echo $tempBin
        if [ $eqFlag = true ] && [ `echo "ibase=2;$tempBin"|bc` -eq 0 ];then
            dataStr+="="
        else
            dataStr+=${baseCode[`echo "ibase=2;$tempBin"|bc`]}

        fi
    done
done
}
#base64解码
baseDecode(){
for((i=0;i<${#binaryStr};i+=8));do
    buffers=${binaryStr:$i:8}

    [ ${#buffers} -lt 8 ] && break;
    dataStr+=`echo "ibase=2;$buffers"|bc|awk '{printf("%c"),$buffers}'`

done
}


#临时变量
binaryStr=""
dataStr=""
eqFlag=false

[ $# -lt 2 ] && { echo "Usage: `basename $0` str encode|decode ";exit $ERR_NULLPARM; }

#展开二进制位
for((i=0;i<${#1};i++));do
    if [ "$2" = "encode" ];then
        binaryStr+=$(echo "obase=2;`printf "%d" "'${1:$i:1}"`"|bc|xargs printf "%08d")
    elif [ "$2" = "decode" ];then
        [ ${1:$i:1} = "=" ] && continue
        binaryStr+=$(echo "obase=2;${baseIndexCode[${1:$i:1}]}"|bc|xargs printf "%06d")
        #echo ${baseIndexCode[${1:$i:1}]}
        #echo $binaryStr
    fi
done

#echo $binaryStr
#echo ${#binaryStr}


case "$2" in
"encode")
    baseEncode
    ;;
"decode")
    baseDecode
    ;;
*)
    ;;
esac

echo $dataStr
