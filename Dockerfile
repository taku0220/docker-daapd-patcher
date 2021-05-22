FROM ghcr.io/linuxserver/baseimage-alpine:3.13 as buildstage
############## build stage ##############

ARG DAAPD_RELEASE
ARG ARCHBITS
ENV ENABLE64BIT="disable"

COPY patch/ /tmp/source/
RUN \
 echo "**** install build packages ****" && \
 apk add --no-cache \
	alsa-lib-dev \
	autoconf \
	automake \
	avahi-dev \
	bash \
	build-base \
	bsd-compat-headers \
	confuse-dev \
	curl \
	curl-dev \
	ffmpeg-dev \
	flac-dev \
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
	mxml-dev \
	openjdk8-jre-base \
	protobuf-c-dev \
	sqlite-dev \
	taglib-dev \
	tar && \
\
 mkdir -p \
	/tmp/source/owntone \
	/tmp/source/libantlr3c && \
 export PATH="/tmp/source:$PATH" && \
 ARCHBITS=${ARCHBITS:-$(getconf LONG_BIT 2>/dev/null)} && \
 DAAPD_RELEASE=${DAAPD_RELEASE:-$(curl -sX GET "https://api.github.com/repos/owntone/owntone-server/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]')} && \
 if [ "${ARCHBITS}" = "64" ]; then \
	ENABLE64BIT="enable"; \
 fi && \
\
 echo -e "\n**** make antlr wrapper ****" && \
 echo \
	"#!/bin/bash" > /tmp/source/antlr3 && \
 echo \
	"exec java -cp /tmp/source/antlr-3.4-complete.jar org.antlr.Tool \"\$@\"" >> /tmp/source/antlr3 && \
 chmod a+x /tmp/source/antlr3 && \
 curl -o \
 /tmp/source/antlr-3.4-complete.jar -L \
	http://www.antlr3.org/download/antlr-3.4-complete.jar && \
\
 echo -e "\n**** compile and install antlr3c ${ARCHBITS}bit ****" && \
 curl -o \
 /tmp/source/libantlr3c.tar.gz -L \
	https://github.com/antlr/website-antlr3/raw/gh-pages/download/C/libantlr3c-3.4.tar.gz && \
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
 echo -e "\n**** compile and install owntone-server ${DAAPD_RELEASE} ****" && \
 curl -o \
 /tmp/source/owntone.tar.gz -L \
	"https://github.com/owntone/owntone-server/archive/${DAAPD_RELEASE}.tar.gz" && \
 tar xf /tmp/source/owntone.tar.gz -C \
	/tmp/source/owntone --strip-components=1 && \
 cd /tmp/source/owntone && \
 find /tmp/source -maxdepth 1 -name "*.patch" -exec /bin/sh -c 'patch --verbose -p1 < {}' \; && \
 autoreconf -i -v && \
 ./configure \
	--build=$CBUILD \
	--enable-chromecast \
	--enable-lastfm \
	--enable-mpd \
	--host=$CHOST \
	--infodir=/usr/share/info \
	--localstatedir=/var \
	--mandir=/usr/share/man \
	--prefix=/usr \
	--sysconfdir=/etc && \
 make && \
 make DESTDIR=/tmp/owntone-build install && \
 mv /tmp/owntone-build/etc/owntone.conf /tmp/owntone-build/etc/owntone.conf.orig
############## runtime stage ##############
FROM ghcr.io/linuxserver/baseimage-alpine:3.13

# set version label
ARG BUILD_DATE
ARG VERSION="1.0"
LABEL build_version="docker-daapd-patcher version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="taku0220"

RUN \
 echo -e "\n**** install runtime packages ****" && \
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
	mxml \
	protobuf-c \
	sqlite \
	sqlite-libs && \
\
 echo -e "\n**** remove avahi service files ****" && \
 rm /etc/avahi/services/*.service && \
\
 echo -e "\n"

# copy buildstage and local files
COPY --from=buildstage /tmp/owntone-build/ /
COPY --from=buildstage /usr/lib/libantlr3c.so /usr/lib/libantlr3c.so
COPY root/ /

# ports and volumes
EXPOSE 3689
VOLUME /config /music
