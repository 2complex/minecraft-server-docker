#!/bin/bash

max_ram=$1
max_ram=${max_ram:=$MAX_RAM}

cp /home/minecraft/eula.txt /data/

if [[ -f /home/minecraft/spigot.yml ]]; then
    if [[ ! -f /data/spigot.yml ]]; then
        cp /home/minecraft/spigot.yml /data/
    fi
    if [[ ! -z "${bungeecord}" ]]; then
        cp /data/spigot.yml /data/spigot.yml.bak
        cat /data/spigot.yml.bak \
            | sed "s/bungeecord: .*$/bungeecord: ${bungeecord}/" \
            > /data/spigot.yml
    fi
fi

if [[ ! -z "${motd}" ]] && [[ -f /data/server.properties ]]; then
    cp /data/server.properties /data/server.properties.bak
    cat /data/server.properties.bak \
        | sed "s/motd=.*$/motd=${motd}/" \
        > /data/server.properties
fi

java -Xms256M "-Xmx${max_ram:=1024M}" \
    -Dlog4j2.formatMsgNoLookups=true \
    -jar /home/minecraft/server.jar
