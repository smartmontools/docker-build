# smartmontools/docker-build

Docker file to cross-build smartmontools images on Linux host for the
FreeBSD and Darwin targets. Used in the GHA builds for the smartmontools/smartmontools project.

## About

Docker container based on Ubtuntu LTS, with all dependencies to generate smartmontools packages for the macOS and FreeBSD systems.

## Supported builds

- Darwin x86_64, i386 using clang/[osxcross](https://github.com/tpoechtrager/osxcross)
- FreeBSD (clang crossbuild)
- MinGW cross-builds

## Related links

- Smartmontools [CI builds](https://github.com/smartmontools/smartmontools-builds/releases)
- Github [action](https://github.com/smartmontools/smartmontools/blob/main/.github/workflows/build.yml)
