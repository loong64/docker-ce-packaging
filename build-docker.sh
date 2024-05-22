#!/bin/bash
#
DOCKER_VERSION=v26.1.3

################################################################
# REF: v26.1.3
# VERSION: 26.1.3
# PACKAGE_VERSION: 26.1
#
REF=${DOCKER_VERSION}
VERSION=${REF#v}
PACKAGE_VERSION=${VERSION%.*}

TMPDIR=$(mktemp -d)

git clone --depth=1 https://github.com/docker/docker-ce-packaging "${TMPDIR}"
cp -R debian-trixie "${TMPDIR}/deb/"

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

sed -i 's@DEBIAN_VERSIONS ?= debian-buster@DEBIAN_VERSIONS ?= debian-trixie debian-buster@g' deb/Makefile
sed -i 's@docker build @docker buildx build --platform linux/loong64 --load @g' deb/Makefile

make ARCH=loongarch64 ARCHES=loong64 REF=${REF} VERSION=${VERSION} GO_VERSION=${GO_VERSION} GO_IMAGE=${GO_IMAGE} debian-trixie

popd || exit 1

mkdir -p dist
mv ${TMPDIR}/deb/debbuild/debian-trixie/* dist/

rm -rf "${TMPDIR:?}"