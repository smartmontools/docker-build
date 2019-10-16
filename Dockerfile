# UBUNTU LTS
FROM ubuntu:latest

# Install dependencies for the smartmontools Linux and WIN32 builds
RUN apt-get update -qy && \
    apt-get install -y automake g\+\+ make jq curl subversion pkg-config \
    g++-mingw-w64-x86-64 g++-mingw-w64-i686 dos2unix nsis man2html-base groff \
    clang cpio libxml2-dev libssl1.0-dev libbz2-dev unzip wget genisoimage cmake \
    man g++-multilib libc6-dev-i386 clang-tools

# Installing OSX cross-tools to make Darwin builds

#Build arguments
ARG osxcross_repo="tpoechtrager/osxcross"
ARG osxcross_revision="a845375e028d29b447439b0c65dea4a9b4d2b2f6"
ARG darwin_sdk_version="10.10"
ARG darwin_osx_version_min="10.6"
ARG darwin_version="14"
ARG darwin_sdk_url="https://www.dropbox.com/s/yfbesd249w10lpc/MacOSX${darwin_sdk_version}.sdk.tar.xz"

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
 && curl -sLo tarballs/MacOSX${DARWIN_SDK_VERSION}.sdk.tar.xz                                                  \
             "${DARWIN_SDK_URL}"                \
 && yes "" | SDK_VERSION="${DARWIN_SDK_VERSION}" OSX_VERSION_MIN="${DARWIN_OSX_VERSION_MIN}" ./build.sh                               \
 && mv target /usr/osxcross                                                                                    \
 && mv tools /usr/osxcross/                                                                                    \
 && ln -sf ../tools/osxcross-macports /usr/osxcross/bin/omp                                                    \
 && ln -sf ../tools/osxcross-macports /usr/osxcross/bin/osxcross-macports                                      \
 && ln -sf ../tools/osxcross-macports /usr/osxcross/bin/osxcross-mp                                            \
 && rm -rf /tmp/osxcross                                                                                       \
 && rm -rf "/usr/osxcross/SDK/MacOSX${DARWIN_SDK_VERSION}.sdk/usr/share/man"

# Installing xar to make Darwin packages
ARG xar_version="1.6.1"
ENV XAR_VERSION="${xar_version}"
RUN cd /tmp \
    && wget https://github.com/mackyle/xar/archive/xar-${XAR_VERSION}.tar.gz \
    && tar -xvzf xar-${XAR_VERSION}.tar.gz \
    && cd xar-xar-${XAR_VERSION}/xar \
    && ./autogen.sh && ./configure && make && make install \
    && cd / && rm -rf /tmp/xar-xar-${XAR_VERSION} /tmp/xar-${XAR_VERSION}.tar.gz

# Installing bomutils to make Darwin packages
ARG bomutils_version="0.2"
ENV BOMUTILS_VERSION="${bomutils_version}"
RUN cd /tmp && wget https://github.com/hogliux/bomutils/archive/${bomutils_version}.tar.gz \
    && tar -xvzf ${bomutils_version}.tar.gz \
    && cd bomutils-${bomutils_version}/ \
    && make && make install \
    && cd / && rm -rf /tmp/${bomutils_version}.tar.gz /tmp/bomutils-${bomutils_version}

# Installing libdmg-hfsplus to build Darwin dmg images
RUN cd /tmp && wget https://github.com/planetbeing/libdmg-hfsplus/archive/master.zip \
    && wget https://github.com/planetbeing/libdmg-hfsplus/archive/master.zip \
    && unzip master.zip \
    && mkdir libdmg-hfsplus-master/build && cd libdmg-hfsplus-master/build \
    && cmake ../ && make && make install \
    && cd / && rm -rf /tmp/libdmg-hfsplus-master /tmp/master.zip

# Get FreeBSD 11 libs/headers, extract and fix broken links
RUN cd /tmp && wget http://ftp.plusline.de/FreeBSD/releases/amd64/11.3-RELEASE/base.txz \
    && mkdir -p /opt/cross-freebsd-11 \
    && cd /opt/cross-freebsd-11 \
    && tar -xf /tmp/base.txz ./lib/ ./usr/lib/ ./usr/include/ \
    && cd /opt/cross-freebsd-11/usr/lib \
    && find . -xtype l|xargs ls -l|grep ' /lib/' \
        | awk '{print "ln -sf /opt/cross-freebsd-11"$11 " " $9}' \
        | /bin/sh && \
    rm -f /tmp/base.txz

# Get FreeBSD 12 libs/headers, extract and fix broken links
RUN cd /tmp && wget http://ftp.plusline.de/FreeBSD/releases/amd64/12.0-RELEASE/base.txz \
    && mkdir -p /opt/cross-freebsd-12 \
    && cd /opt/cross-freebsd-12 \
    && tar -xf /tmp/base.txz ./lib/ ./usr/lib/ ./usr/include/ \
    && cd /opt/cross-freebsd-12/usr/lib \
    && find . -xtype l|xargs ls -l|grep ' /lib/' \
        | awk '{print "ln -sf /opt/cross-freebsd-12"$11 " " $9}' \
        | /bin/sh && \
    rm -f /tmp/base.txz

# Install cppcheck
RUN v=1.85 \
    && cd /tmp \
    && wget -O cppcheck-$v.tar.gz https://github.com/danmar/cppcheck/archive/$v.tar.gz \
    && tar -xf cppcheck-$v.tar.gz \
    && cd cppcheck-$v \
    && make="make PREFIX=/usr/local CFGDIR=/usr/local/share/cppcheck/cfg" \
    && $make && $make install \
    && cd / && rm -rf /tmp/cppcheck-$v.tar.gz /tmp/cppcheck-$v
