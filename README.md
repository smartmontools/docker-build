# smartmontools/docker-build
Docker file to build smartmontools images with all required dependencies


## About

Docker container based on Ubtuntu LTS, with all dependencies to generate smartmontools packages for the different operating systems and architectures. 

## Supported builds

- Linux: x86_64, i686 using GCC
- Darwin x86_64, i386 using clang/[osxcross](https://github.com/tpoechtrager/osxcross)
- Windows: 64 and 32 bits

## Build recipes

See https://www.smartmontools.org/browser/trunk/.circleci/config.yml
