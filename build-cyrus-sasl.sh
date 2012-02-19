#!/bin/sh

#  Automatic build script for cyrus-sasl 
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Felix Schulze on 18.02.12.
#  Copyright 2012 Felix Schulze. All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################
#  Change values here													  #
#																		  #
VERSION="2.1.25"													      #
SDKVERSION="5.0"														  #
#																		  #
###########################################################################
#																		  #
# Don't change anything under this line!								  #
#																		  #
###########################################################################


CURRENTPATH=`pwd`
ARCHS="i386 armv6 armv7"

set -e
if [ ! -e cyrus-sasl-${VERSION}.tar.gz ]; then
	echo "Downloading cyrus-sasl-${VERSION}.tar.gz"
    curl -O http://ftp.andrew.cmu.edu/pub/cyrus-mail/cyrus-sasl-${VERSION}.tar.gz
else
	echo "Using cyrus-sasl-${VERSION}.tar.gz"
fi

mkdir -p "${CURRENTPATH}/src"
mkdir -p "${CURRENTPATH}/bin"
mkdir -p "${CURRENTPATH}/lib"

for ARCH in ${ARCHS}
do
	tar zxf cyrus-sasl-${VERSION}.tar.gz -C "${CURRENTPATH}/src"
	cd "${CURRENTPATH}/src/cyrus-sasl-${VERSION}"

	if [ "${ARCH}" == "i386" ];
	then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
	fi
		
	CC="/Developer/Platforms/${PLATFORM}.platform/Developer/usr/bin/gcc"
	CFLAGS="-isysroot /Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk -arch ${ARCH} -pipe -Os -gdwarf-2"
	LDFLAGS="-isysroot /Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk -arch ${ARCH}"		
	
	echo "Building cyrus-sasl-${VERSION} for ${PLATFORM} ${SDKVERSION} ${ARCH}"
	echo "Please stand by..."
	export CC=${CC}
	export CFLAGS=${CFLAGS}
	export LDFLAGS=${LDFLAGS}

	mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
	LOG="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/build-cyrus-sasl-${VERSION}.log"

	if [ "${VERSION}" == "2.1.23" ];
	then
		patch -p0 < ../../patch-2.1.23.diff >> "${LOG}" 2>&1
	fi

	./configure --prefix="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" --host="${ARCH}-apple-darwin" --disable-shared --enable-static --with-openssl="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" > "${LOG}" 2>&1
	(cd lib && make) >> "${LOG}" 2>&1
	(cd include && make saslinclude_HEADERS="hmac-md5.h md5.h sasl.h saslplug.h saslutil.h prop.h" install) >> "${LOG}" 2>&1
	(cd lib && make install) >> "${LOG}" 2>&1
	cd "${CURRENTPATH}"
	rm -rf "${CURRENTPATH}/src/cyrus-sasl-${VERSION}"
done

echo "Build library..."
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/lib/libsasl2.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv6.sdk/lib/libsasl2.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/lib/libsasl2.a -output ${CURRENTPATH}/lib/libsasl2.a
mkdir -p ${CURRENTPATH}/include
echo "Building done."
echo "Done."