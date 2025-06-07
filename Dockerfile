FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive
# Install dependencies for the smartmontools Linux and WIN32 builds
RUN apt-get update -qy && \
    apt-get install -y automake g\+\+ make jq curl subversion pkg-config \
    g++-mingw-w64-x86-64 g++-mingw-w64-i686 dos2unix man2html-base groff \
    clang cpio libxml2-dev libssl-dev libbz2-dev unzip wget xorriso cmake \
    man g++-multilib libc6-dev-i386 clang-tools git xz-utils zlib1g-dev \
    scons binutils-mingw-w64-i686 zlib1g-dev libcppunit-dev bzip2

# NSIS 3.08-3 from Debian 12 generates bogus relocation information (regression).
RUN mkdir /tmp/nsis && cd /tmp/nsis && \
    wget 'https://downloads.sourceforge.net/project/libpng/zlib/1.2.8/zlib128-dll.zip' && \
    unzip -d zlib zlib128-dll.zip && \
    wget 'https://prdownloads.sourceforge.net/nsis/nsis-3.10-src.tar.bz2' && \
    tar -xf nsis-3.10-src.tar.bz2 && \
    cd nsis-3.10-src && scons -j `nproc` ZLIB_W32=$HOME/zlib SKIPUTILS="NSIS Menu" NSIS_CONFIG_LOG=yes build install && \
    cd $HOME && rm -rf /tmp/nsis

# Installing OSX cross-tools to make Darwin builds

#Build arguments
ARG osxcross_repo="tpoechtrager/osxcross"
ARG osxcross_revision="564e2b9aa8e7a40da663d890c0e853a1259ff8b1"
ARG darwin_sdk_version="11.3"
ARG darwin_osx_version_min="10.6"

ARG darwin_version="14"
# ARG darwin_sdk_url="https://www.dropbox.com/s/yfbesd249w10lpc/MacOSX${darwin_sdk_version}.sdk.tar.xz"
ARG darwin_sdk_url="https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX${darwin_sdk_version}.sdk.tar.xz"

# ENV available in docker image
ENV OSXCROSS_REPO="${osxcross_repo}"                   \
    OSXCROSS_REVISION="${osxcross_revision}"           \
    DARWIN_SDK_VERSION="${darwin_sdk_version}"         \
    DARWIN_VERSION="${darwin_version}"                 \
    DARWIN_OSX_VERSION_MIN="${darwin_osx_version_min}" \
    DARWIN_SDK_URL="${darwin_sdk_url}"

RUN mkdir -p "/tmp/osxcross"                                                                                   \
 && cd "/tmp/osxcross"                                                                                         \
 && curl -sLo osxcross.tar.gz "https://codeload.github.com/${OSXCROSS_REPO}/tar.gz/${OSXCROSS_REVISION}"  \
 && tar --strip=1 -xzf osxcross.tar.gz                                                                         \
 && rm -f osxcross.tar.gz                                                                                      \
 && curl  -sLo tarballs/MacOSX${DARWIN_SDK_VERSION}.sdk.tar.xz                                                 \
             "${DARWIN_SDK_URL}"                \
 && yes "" | SDK_VERSION="${DARWIN_SDK_VERSION}" OSX_VERSION_MIN="${DARWIN_OSX_VERSION_MIN}" ./build.sh                               \
 && mv target /usr/osxcross                                                                                    \
 && mv tools /usr/osxcross/                                                                                    \
 && ln -sf ../tools/osxcross-macports /usr/osxcross/bin/omp                                                    \
 && ln -sf ../tools/osxcross-macports /usr/osxcross/bin/osxcross-macports                                      \
 && ln -sf ../tools/osxcross-macports /usr/osxcross/bin/osxcross-mp                                            \
 && rm -rf /tmp/osxcross                                                                                       \
 && rm -rf "/usr/osxcross/SDK/MacOSX${DARWIN_SDK_VERSION}.sdk/usr/share/man"

# Installing bomutils to make Darwin packages
# CXXFLAGS='-std=gnu++11' fixes "reference is ambiguous" error in lsbom.cpp
ARG bomutils_version="0.2"
ENV BOMUTILS_VERSION="${bomutils_version}"
RUN cd /tmp && wget https://github.com/hogliux/bomutils/archive/${bomutils_version}.tar.gz \
    && tar -xvzf ${bomutils_version}.tar.gz \
    && cd bomutils-${bomutils_version}/ \
    && make CXXFLAGS='-std=gnu++11 -Wall' && make install \
    && cd / && rm -rf /tmp/${bomutils_version}.tar.gz /tmp/bomutils-${bomutils_version}

# Installing libdmg-hfsplus to build Darwin dmg images
# 'C_DEFINES=' removes libssl1.0 dependency
RUN cd /tmp && wget https://github.com/planetbeing/libdmg-hfsplus/archive/master.zip \
    && unzip master.zip \
    && mkdir libdmg-hfsplus-master/build && cd libdmg-hfsplus-master/build \
    && cmake ../ && make C_DEFINES= && make install \
    && cd / && rm -rf /tmp/libdmg-hfsplus-master /tmp/master.zip


# Get FreeBSD 13 libs/headers, extract and fix broken links
RUN cd /tmp && wget http://ftp.plusline.de/FreeBSD/releases/amd64/13.5-RELEASE/base.txz \
    && mkdir -p /opt/cross-freebsd-13 \
    && cd /opt/cross-freebsd-13 \
    && tar -xf /tmp/base.txz ./lib/ ./usr/lib/ ./usr/include/ \
    && cd /opt/cross-freebsd-13/usr/lib \
    && find . -xtype l|xargs ls -l|grep ' /lib/' \
        | awk '{print "ln -sf /opt/cross-freebsd-13"$11 " " $9}' \
        | /bin/sh \
    && ln -s libc++.a /opt/cross-freebsd-13/usr/lib/libstdc++.a \
    && ln -s libc++.so /opt/cross-freebsd-13/usr/lib/libstdc++.so \
    && rm -f /tmp/base.txz

# Get FreeBSD 14 libs/headers, extract and fix broken links
RUN cd /tmp && wget http://ftp.plusline.de/FreeBSD/releases/amd64/14.2-RELEASE/base.txz \
    && mkdir -p /opt/cross-freebsd-14 \
    && cd /opt/cross-freebsd-14 \
    && tar -xf /tmp/base.txz ./lib/ ./usr/lib/ ./usr/include/ \
    && cd /opt/cross-freebsd-14/usr/lib \
    && find . -xtype l|xargs ls -l|grep ' /lib/' \
        | awk '{print "ln -sf /opt/cross-freebsd-14"$11 " " $9}' \
        | /bin/sh \
    && ln -s libc++.a /opt/cross-freebsd-14/usr/lib/libstdc++.a \
    && ln -s libc++.so /opt/cross-freebsd-14/usr/lib/libstdc++.so \
    && rm -f /tmp/base.txz

# Install cppcheck
RUN v=2.17.1 \
    && cd /tmp \
    && wget -O cppcheck-$v.tar.gz https://github.com/danmar/cppcheck/archive/$v.tar.gz \
    && tar -xf cppcheck-$v.tar.gz \
    && cd cppcheck-$v \
    && make="make MATCHCOMPILER=yes FILESDIR=/usr/local/share/cppcheck PREFIX=/usr/local" \
    && $make && $make install \
    && cd / && rm -rf /tmp/cppcheck-$v.tar.gz /tmp/cppcheck-$v

