# smartmontools/docker-build

Docker file to build smartmontools images with all required dependencies. It generates docker image used in [smartmontools CircleCI](https://circleci.com/gh/smartmontools/smartmontools) to provide automated builds.

## About

Docker container based on Ubtuntu LTS, with all dependencies to generate smartmontools packages for the different operating systems and architectures.

## Supported builds

- Linux: x86_64, i686 using GCC
- Darwin x86_64, i386 using clang/[osxcross](https://github.com/tpoechtrager/osxcross)
- Windows: 64 and 32 bits
- FreeBSD 11.2, FreeBSD 12.0 (clang crossbuild)

## Related links

- Smartmontools [Circle CI Build recipes](https://www.smartmontools.org/browser/trunk/.circleci/config.yml)
- Docker HUB [Automated Build](https://hub.docker.com/r/sammcz/docker-build/)
