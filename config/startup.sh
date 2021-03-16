#!/bin/bash

max_ram=$1
max_ram=${max_ram:=$MAX_RAM}

cp /home/minecraft/eula.txt /data/
java -Xms256M "-Xmx${max_ram:=1024M}" \
    -jar /home/minecraft/server.jar
