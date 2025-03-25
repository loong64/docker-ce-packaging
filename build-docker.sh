#!/bin/bash
#
DOCKER_VERSION=v28.0.4

BUILD_DEB=0
BUILD_RPM=0

while [[ $# > 0 ]]; do
    lowerI="$(echo $1 | awk '{print tolower($0)}')"
    case $lowerI in
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Global Options:"
            echo -e "  -h, --help  \t Show this help message and exit"
            echo -e "  --deb  \t Build Debian-trixie deb package"
            echo -e "  --rpm  \t Build OpenCloudOS-23 rpm package"
            exit 0
            ;;
        --deb)
            BUILD_DEB=1
            shift
            ;;
        --rpm)
            BUILD_RPM=1
            shift
            ;;
        *)
            echo "install: Unknown option $1"
            echo "eg: $0 --deb --rpm"
            exit 1
            ;;
    esac
    shift
done

################################################################
# REF: v27.0.1
# VERSION: 27.0.1
# PACKAGE_VERSION: 27.0
#
REF=${DOCKER_VERSION}
VERSION=${REF#v}
PACKAGE_VERSION=${VERSION%.*}

TMPDIR=$(mktemp -d)

git clone --depth=1 https://github.com/docker/docker-ce-packaging "${TMPDIR}"
cp -R debian-trixie "${TMPDIR}/deb/"
cp -f opencloudos-23/Dockerfile "${TMPDIR}/rpm/fedora-41/Dockerfile"

pushd "${TMPDIR}" || exit 1

################################################################
# GO_VERSION: 1.21.10
# GO_IMAGE: golang:1.21.10-trixie
#
GO_VERSION=$(grep '^GO_VERSION' common.mk | awk -F ":=" '{print $2}')
GO_IMAGE=golang:${GO_VERSION}-trixie

################################################################
# See. https://hub.docker.com/r/docker/dockerfile/tags
# docker.io/docker/dockerfile not support linux/loong64
#
# Debian 13 (trixie) support loong64
#

sed -i 's@DEBIAN_VERSIONS ?= debian-bullseye@DEBIAN_VERSIONS ?= debian-trixie debian-bullseye@g' deb/Makefile
sed -i 's@docker build @docker buildx build --load @g' deb/Makefile

if [ "${BUILD_DEB}" = '1' ]; then
    make ARCH=loong64 ARCHES=loong64 REF=${REF} VERSION=${VERSION} GO_VERSION=${GO_VERSION} GO_IMAGE=${GO_IMAGE} debian-trixie
fi
if [ "${BUILD_RPM}" = '1' ]; then
    make ARCH=loong64 ARCHES=loong64 REF=${REF} VERSION=${VERSION} GO_VERSION=${GO_VERSION} GO_IMAGE=${GO_IMAGE} fedora-41
fi

popd || exit 1

mkdir -p dist

if [ "${BUILD_DEB}" = '1' ]; then
    mv ${TMPDIR}/deb/debbuild/debian-trixie/* dist/
fi
if [ "${BUILD_RPM}" = '1' ]; then
    mv ${TMPDIR}/rpm/rpmbuild/fedora-41/* dist/
fi

rm -rf "${TMPDIR:?}"