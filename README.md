# minecraft-server-docker
This repo contains the tools we use to dynamicly create and manage our minecraft server.

## Build

First you need to make the script executable

```bash
chmod +x mk-mc-base.sh
```

After that you can build the container

```bash
./mk-mc-base.sh $kind $version
```

The following kinds are supported:
- `vanilla` - The official minecraft server

Example

```bash
./mk-mc-base.sh vanilla 1.16.4
```

## Run

Run the container with
```bash
sudo docker run -v "$(pwd)/data:/data" -p 25565:25565 -t "2complex/mc-$kind:$version"
```

You can mount the contents in the data directory separately by doing so:
- `-v $data:/data` - normal mount for the whole data directory
- `-v $logs:/data/logs` - mount logs to your special log directory
- `-v $world:/data/world` - mount the world data to your world directory

You dont need to provide any `eula.txt`. This is done automaticly for you.

If you need to increase the JVM maximum memory you can do this by one of the following:
- add `2048M` (or whatever you need) to the end of the command. Example:
    ```bash
    sudo docker run -v "$(pwd)/data:/data" -p 25565:25565 -t "2complex/mc-$kind:$version" 2048M
    ```
- set the environment variable `MAX_RAM`. This can be done inline by adding `MAX_RAM=2048M` (or whatever value you need) to start of the command. Example:
    ```bash
    MAX_RAM=2048M sudo docker run -v "$(pwd)/data:/data" -p 25565:25565 -t "2complex/mc-$kind:$version"
    ```