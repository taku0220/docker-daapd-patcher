#!/bin/bash

DOCKER_BUILD_PATH=/tmp/amixer-webui-build
INSTALL_PATH=${DOCKER_BUILD_PATH}/usr/share/amixer-webui
CONF_PATH=${DOCKER_BUILD_PATH}/etc

mkdir -p ${INSTALL_PATH}
sed -i -e "1s/python/python3/" alsamixer_webui.py

cp -r htdocs ${INSTALL_PATH}/
cp alsamixer_webui.py ${INSTALL_PATH}/
cp logo.svg ${INSTALL_PATH}/


mkdir -p ${CONF_PATH}
sed -i -e "s/^port =/port = 39000/" amixer-webui.conf

cp amixer-webui.conf ${CONF_PATH}/amixer-webui.conf.orig
