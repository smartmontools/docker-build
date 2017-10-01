# UBUNTU LTS
FROM ubuntu:latest
RUN apt-get update -qy && \
    apt-get install -y automake g\+\+ make jq curl subversion pkg-config \
    g++-mingw-w64-x86-64 g++-mingw-w64-i686 dos2unix nsis man2html-base groff

