#!/bin/bash

# This script just checks if the version is available.
# If the version is found and supported the exit code is 0. Otherwise 1.

kind=$1
version=$2

case $kind in
    vanilla)
        curl --head "https://mcversions.net/download/$version" 2> /dev/null \
            | grep -P "HTTP.* 200" > /dev/null \
            && exit 0 \
            || exit 1
        ;;
    spigot)
        header=$(curl --head "https://cdn.getbukkit.org/spigot/spigot-${version}.jar" 2> /dev/null)
        echo "$header" | grep -P "HTTP.* 200" > /dev/null \
            && echo "$header" | grep -P "content-type: application/java-archive" > /dev/null \
            && exit 0 \
            || exit 1
        ;;
esac

exit 1