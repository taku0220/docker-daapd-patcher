#!/bin/bash

SOURCE_DIR=$(pwd)
RET_DL=""
RET_SHA=""
RET_COMP=""

if [ -n "$1" ] && [ -d "$1" ]; then SOURCE_DIR=$1 ;fi
echo "Downlode pass: $SOURCE_DIR"


## Download exec ##

curl -o ${SOURCE_DIR}/alsaequal.tar.bz2 \
 -L "https://thedigitalmachine.net/tools/alsaequal-0.6.tar.bz2"
[ $? -eq 0 ] && RET_DL="OK" || RET_DL="NG"
echo -e "alsaequal download : $RET_DL\n"

curl -o ${SOURCE_DIR}/amixer-webui.tar.gz \
 -L "https://github.com/JiriSko/amixer-webui/archive/master.tar.gz"
[ $? -eq 0 ] && RET_DL="OK" || RET_DL="NG"
echo -e "amixer-webui download : $RET_DL\n"

curl -o ${SOURCE_DIR}/antlr-3.4-complete.jar \
 -L "https://www.antlr3.org/download/antlr-3.4-complete.jar"
[ $? -eq 0 ] && RET_DL="OK" || RET_DL="NG"
echo -e "antlr-3.4-complete.jar download : $RET_DL\n"

curl -o ${SOURCE_DIR}/caps.tar.bz2 \
 -L "http://quitte.de/dsp/caps_0.9.26.tar.bz2"
[ $? -eq 0 ] && RET_DL="OK" || RET_DL="NG"
echo -e "caps download : $RET_DL\n"

curl -o ${SOURCE_DIR}/libantlr3c.tar.gz \
 -L "https://github.com/antlr/website-antlr3/raw/gh-pages/download/C/libantlr3c-3.4.tar.gz"
[ $? -eq 0 ] && RET_DL="OK" || RET_DL="NG"
echo -e "libantlr3c download : $RET_DL\n"


## Check archive ##

echo -e "== File sha256 hash check ==\n"

RET_SHA=$(openssl dgst -sha256 $SOURCE_DIR/alsaequal.tar.bz2 | awk '{print $2}')
[ "$RET_SHA" = "916e7d152added24617efc350142438a46099efe062bd8781d36dbf10b4e6ff0" ] && RET_COMP="OK" || RET_COMP="NG"
echo "alsaequal SHA256 check : $RET_COMP"

RET_SHA=$(openssl dgst -sha256 $SOURCE_DIR/amixer-webui.tar.gz | awk '{print $2}')
[ "$RET_SHA" = "0dd4fa3025a4324fee1c6599e5fb90ea08da5d78fa0187c000dff551c527b779" ] && RET_COMP="OK" || RET_COMP="NG"
echo "amixer-webui SHA256 check : $RET_COMP"

RET_SHA=$(openssl dgst -sha256 $SOURCE_DIR/antlr-3.4-complete.jar | awk '{print $2}')
[ "$RET_SHA" = "9d3e866b610460664522520f73b81777b5626fb0a282a5952b9800b751550bf7" ] && RET_COMP="OK" || RET_COMP="NG"
echo "antlr-3.4-complete.jar SHA256 check : $RET_COMP"

RET_SHA=$(openssl dgst -sha256 $SOURCE_DIR/caps.tar.bz2 | awk '{print $2}')
[ "$RET_SHA" = "e7496c5bce05abebe3dcb635926153bbb58a9337a6e423f048d3b61d8a4f98c9" ] && RET_COMP="OK" || RET_COMP="NG"
echo "caps SHA256 check : $RET_COMP"

RET_SHA=$(openssl dgst -sha256 $SOURCE_DIR/libantlr3c.tar.gz | awk '{print $2}')
[ "$RET_SHA" = "ca914a97f1a2d2f2c8e1fca12d3df65310ff0286d35c48b7ae5f11dcc8b2eb52" ] && RET_COMP="OK" || RET_COMP="NG"
echo "libantlr3c SHA256 check : $RET_COMP"

echo -e "== Check complete ==\n"
