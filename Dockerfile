FROM lsiobase/alpine:3.11 as buildstage
############## build stage ##############

ARG DAAPD_RELEASE
ARG ARCHBITS
ENV ENABLE64BIT="disable"

COPY source/ /tmp/source/
COPY patch/ /tmp/source/
RUN \
 echo "**** install build packages ****" && \
 apk add --no-cache \
	alsa-lib-dev \
	autoconf \
	automake \
	avahi-dev \
	bash \
	bsd-compat-headers \
	confuse-dev \
	curl \
	curl-dev \
	ffmpeg-dev \
	file \
	flac-dev \
	g++ \
	gcc \
	gettext-dev \
	gnutls-dev \
	gperf \
	json-c-dev \
	libcurl \
	libevent-dev \
	libgcrypt-dev \
	libogg-dev \
	libplist-dev \
	libressl-dev \
	libsodium-dev \
	libtool \
	libunistring-dev \
	libwebsockets-dev \
	make \
	openjdk8-jre-base \
	protobuf-c-dev \
	sqlite-dev \
	taglib-dev \
	tar && \
 apk add --no-cache \
	--repository http://nl.alpinelinux.org/alpine/edge/testing \
	mxml-dev && \
 \
 mkdir -p \
	/tmp/source/forked-daapd \
	/tmp/source/libantlr3c && \
 export PATH="/tmp/source:$PATH" && \
 ARCHBITS=${ARCHBITS:-$(getconf LONG_BIT 2>/dev/null)} && \
 DAAPD_RELEASE=${DAAPD_RELEASE:-$(curl -sX GET "https://api.github.com/repos/ejurgensen/forked-daapd/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]')} && \
 if [ "${ARCHBITS}" = "64" ]; then \
	ENABLE64BIT="enable"; \
 fi && \
 \
 echo "**** make antlr wrapper ****" && \
 echo \
	"#!/bin/bash" > /tmp/source/antlr3 && \
 echo \
	"exec java -cp /tmp/source/antlr-3.4-complete.jar org.antlr.Tool \"\$@\"" >> /tmp/source/antlr3 && \
 chmod a+x /tmp/source/antlr3 && \
 if [ ! -f /tmp/source/antlr-3.4-complete.jar ]; then \
	curl -o \
	/tmp/source/antlr-3.4-complete.jar -L \
		"https://www.antlr3.org/download/antlr-3.4-complete.jar"; \
 fi && \
 \
 echo "**** compile and install antlr3c ${ARCHBITS}bit ****" && \
 if [ ! -f /tmp/source/libantlr3c.tar.gz ]; then \
	curl -o \
	/tmp/source/libantlr3c.tar.gz -L \
		"https://github.com/antlr/website-antlr3/raw/gh-pages/download/C/libantlr3c-3.4.tar.gz"; \
 fi && \
 tar xf /tmp/source/libantlr3c.tar.gz  -C \
	/tmp/source/libantlr3c --strip-components=1 && \
 curl -o \
 /tmp/source/libantlr3c/config.guess -L \
	'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' && \
 chmod a+x /tmp/source/libantlr3c/config.guess && \
 curl -o \
 /tmp/source/libantlr3c/config.sub -L \
	'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD' && \
 chmod a+x /tmp/source/libantlr3c/config.sub && \
 cd /tmp/source/libantlr3c && \
 ./configure \
	--build=$CBUILD \
	--${ENABLE64BIT}-64bit \
	--disable-abiflags \
	--prefix=/usr && \
 make && \
 make install && \
 \
 echo "**** compile and install forked-daapd ${DAAPD_RELEASE} ****" && \
 curl -o \
 /tmp/source/forked.tar.gz -L \
	"https://github.com/ejurgensen/forked-daapd/archive/${DAAPD_RELEASE}.tar.gz" && \
 tar xf /tmp/source/forked.tar.gz -C \
	/tmp/source/forked-daapd --strip-components=1 && \
 cd /tmp/source/forked-daapd && \
 find /tmp/source -maxdepth 1 -name "*.patch" -exec /bin/sh -c 'patch -p1 < {}' \; && \
 autoreconf -i -v && \
 ./configure \
	--build=$CBUILD \
	--enable-chromecast \
	--enable-itunes \
	--enable-lastfm \
	--enable-mpd \
	--host=$CHOST \
	--infodir=/usr/share/info \
	--localstatedir=/var \
	--mandir=/usr/share/man \
	--prefix=/usr \
	--sysconfdir=/etc && \
 make && \
 make DESTDIR=/tmp/daapd-build install && \
 mv /tmp/daapd-build/etc/forked-daapd.conf /tmp/daapd-build/etc/forked-daapd.conf.orig
############## runtime stage ##############
FROM lsiobase/alpine:3.11

# set version label
ARG BUILD_DATE
ARG VERSION="1.0"
LABEL build_version="docker-daapd-patcher version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="taku0220"

RUN \
 echo "**** install runtime packages ****" && \
 apk add --no-cache \
	avahi \
	confuse \
	dbus \
	ffmpeg \
	json-c \
	libcurl \
	libevent \
	libgcrypt \
	libplist \
	libressl \
	libsodium \
	libunistring \
	libwebsockets \
	protobuf-c \
	sqlite \
	sqlite-libs && \
 apk add --no-cache \
	--repository http://nl.alpinelinux.org/alpine/edge/testing \
	mxml && \
 \
 echo "**** configuration changes avahi-daemon ****" && \
 sed -i -e "s/^use-ipv6=yes/use-ipv6=no/" /etc/avahi/avahi-daemon.conf && \
 sed -i -e "s/^#deny-interfaces=eth1/deny-interfaces=docker0, lxcbr0/" /etc/avahi/avahi-daemon.conf && \
 \
 echo "**** remove avahi service files ****" && \
 rm /etc/avahi/services/*.service

# copy buildstage and local files
COPY --from=buildstage /tmp/daapd-build/ /
COPY --from=buildstage /usr/lib/libantlr3c.so /usr/lib/libantlr3c.so
COPY root/ /

# ports and volumes
EXPOSE 3689
VOLUME /config /music
