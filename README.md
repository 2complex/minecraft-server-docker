# minecraft-server-docker
This repo contains the tools we use to dynamicly create and manage our minecraft server.

## Build

To build your container just run

```bash
chmod +x mk-mc-base.sh
./mk-mc-base.sh vanilla 1.16.4
```

## Run

1. You need to create the `eula.txt` file in your data directory
2. Run the container with
    ```bash
    sudo docker run -v "$(pwd)/data:/data" -p 25565:25565 -t "2complex/mc-:1.16.4"
    ```

You can mount the contents in the data directory separately by so:
- `--mount type=bind,src=$data/banned-ips.json,dst=/data/banned-ips.json`
- `--mount type=bind,src=$data/banned-players.json,dst=/data/banned-players.json`
- `-v $data/logs:/data/logs`
- `--mount type=bind,src=$data/ops.json,dst=/data/ops.json`
- `--mount type=bind,src=$data/server.properties,dst=/data/server.properties`
- `--mount type=bind,src=$data/usercache.json,dst=/data/usercache.json`
- `--mount type=bind,src=$data/whitelist.json,dst=/data/whitelist.json`
- `-v $data/world:/data/world`
