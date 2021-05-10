#!/bin/bash

# PURPOSE:
#   This script creates a docker image with the a specific minecraft server version installed.
# 
# CALL:
#   mk-mc-base.sh [kind] [version]
#
# RESULT:
#   Local docker image file: "2complex/mc-${kind}:${version}"

kind=$1
version=$2
nosudo=${NOSUDO:=0}

sudo=$([ "$nosudo" = "1" ] && echo "" || echo "sudo")

# check input
if [ ! -f "Dockerfile.${kind}" ]; then
    >&2 echo "No mathing Dockerfile for your build is found"
    exit 1
fi

# create the build directory if not happened and enter it
[ -d build ] || mkdir -p build
pushd build > /dev/null

# prepare the docker file
cp "../Dockerfile.${kind}" Dockerfile
[[ ! -d config/ ]] && mkdir -p config/
cp -r ../config/* config/
echo "${version}" > VERSION

# build docker container
$sudo docker build \
    --build-arg "mc_version=${version}" \
    --build-arg "mc_kind=${kind}" \
    -t "2complex/mc-${kind}:${version}" . \
    || exit $?

# finish
popd > /dev/null
