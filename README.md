[![CircleCI](https://img.shields.io/circleci/build/github/SickHub/arkserver)](https://app.circleci.com/pipelines/github/SickHub/arkserver)
[![Docker image](https://img.shields.io/docker/image-size/drpsychick/arkserver?sort=date)](https://hub.docker.com/r/drpsychick/arkserver/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/drpsychick/arkserver.svg?style=flat-square)](https://hub.docker.com/r/drpsychick/arkserver/)
[![License](https://img.shields.io/dub/l/vibe-d.svg?style=flat-square)](https://github.com/drpsychick/arkserver/blob/master/LICENSE)

[![GitHub issues](https://img.shields.io/github/issues/SickHub/arkserver.svg)](https://github.com/SickHub/arkserver/issues)
[![GitHub closed issues](https://img.shields.io/github/issues-closed/SickHub/arkserver.svg)](https://github.com/SickHub/arkserver/issues?q=is%3Aissue+is%3Aclosed)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/SickHub/arkserver.svg)](https://github.com/SickHub/arkserver/pulls)
[![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed/SickHub/arkserver.svg)](https://github.com/SickHub/arkserver/pulls?q=is%3Apr+is%3Aclosed)
[![Contributors](https://img.shields.io/github/contributors/SickHub/arkserver.svg)](https://github.com/SickHub/arkserver/graphs/contributors)
[![Paypal](https://img.shields.io/badge/donate-paypal-00457c.svg?logo=paypal)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=FTXDN7LCDWUEA&source=url)
[![GitHub Sponsor](https://img.shields.io/badge/github-sponsor-blue?logo=github)](https://github.com/sponsors/DrPsychick)

# Docker image `drpsychick/arkserver`
Docker image for a dedicated ARK Survival Evolved server with arkmanager.

**UPDATE August 2022**: I cloned this repo and split from the original, because my PR was never accepted.
The original is here: [thmhoag/arkserver](https://github.com/thmhoag/arkserver).

## Overview

This is an image for running an ARK: Survival Evolved server in a Docker container.
It is heavily based off of [TuRz4m](https://github.com/TuRz4m)'s work located here: [TuRz4m/Ark-docker](https://github.com/TuRz4m/Ark-docker).
It uses [FezVrasta](https://github.com/FezVrasta)'s [arkmanager/ark-server-tools](https://github.com/arkmanager/ark-server-tools)
to manage single-instances or a cluster of ARK: Survival Evolved server inside a docker containers.

This image builds on the [drpsychick/steamcmd](https://github.com/drpsychick/steamcmd) image to include the latest version of `steamcmd`.

For more information on `arkmanager`, see the repo here: [arkmanager/ark-server-tools](https://github.com/arkmanager/ark-server-tools).

### Features
* Automated install (pull the image and run, no additional commands necessary)
* Configuration via Environment Variables
* Easy crontab manipulation for automated backups, updates, daily restarts, weekly dino wipes, etc
* Simple volume structure for server files, config, logs, backups, etc
* Inherently includes all features present in `arkmanager`
* Optional [RCON health server](docs/HealthServer.md) for application-level readiness checks

### Tags
| Tag               | Description                                        |
|-------------------|----------------------------------------------------|
| latest            | most recent build from the master branch            |
| latest-v1.6.x     | pinned to a specific arkmanager version             |
| latest-master     | built from the latest arkmanager master branch      |
| jammy             | Ubuntu 22.04 (Jammy) base                           |
| focal             | Ubuntu 20.04 (Focal) base                           |

### Documentation

|                     |                                                     |
| ------------------- | --------------------------------------------------- |
| Configuration       | [Environment Variables & Volumes](docs/Configuration.md) |
| Health Server       | [RCON Health Endpoint](docs/HealthServer.md)        |
| Clustering          | [Multi-Map Cluster Setup](docs/Clustering.md)       |

## Usage

### Installing the image

Pull the latest (or any other desired version):
```bash
docker pull drpsychick/arkserver:latest
```

### Running the server

To run a generic server with no configuration modifications:
```bash
$ docker run -d \
    -v steam:/home/steam/.steam/steamapps \  # mounted so that workshop (mod) downloads are persisted
    -v ark:/ark \  # mounted as the directory to contain the server/backup/log/config files
    -p 27015:27015 -p 27015:27015/udp \  # steam query port
    -p 7778:7778 -p 7778:7778/udp \  # gameserver port
    -p 7777:7777 -p 7777:7777/udp \ # gameserver port
    drpsychick/arkserver
```

If the exposed ports are modified (in the case of multiple containers/servers on the same host) the `arkmanager` config will need to be modified to reflect the change as well. This is required so that `arkmanager` can properly check the server status and so that the ARK server itself can properly publish its IP address and query port to steam.

## Environment Variables

A set of required environment variables have default values provided as part of the image:

| Variable                   | Value         | Description                                                                  |
|----------------------------|---------------|------------------------------------------------------------------------------|
| am_ark_SessionName         | `Ark Server`  | Server name as it will show on the steam server list                         |
| am_serverMap               | `TheIsland`   | Game map to load                                                             |
| am_ark_ServerAdminPassword | `k3yb04rdc4t` | Admin password to be used via ingame console or RCON                         |
| am_ark_MaxPlayers          | `70`          | Max concurrent players in the game                                           |
| am_ark_QueryPort           | `27015`       | Steam query port (allows the server to show up on the steam list)            |
| am_ark_Port                | `7778`        | Game server port (allows clients to connect to the server)                   |
| am_ark_RCONPort            | `32330`       | RCON port                                                                    |
| am_arkwarnminutes          | `15`          | Number of minutes to wait/warn players before updating/restarting            |
| am_arkflag_crossplay       | `false`       | Allow crossyplay with Players on Epic                                        |
| ARKCLUSTER                 | `false`       | If true, requires `ShooterGame/Saved/clusters` to be mounted                 |
| ARKSERVER_SHARED           |               | To optionally share server binary files, use `/arkserver` volume, see below  |
| LOG_RCONCHAT               | `0`           | Fetch chat commands every X seconds and log them to stdout, `0` = disabled   |
| AM_INSTALL_ARGS            |               | Optional arguments to `arkmanager install`, for example `--beta=preaquatica` |
| AM_UPDATE_ARGS             |               | Optional arguments to `arkmanager update`                                    |
| HEALTH_SERVER              | `false`       | Enable the optional [RCON health server](docs/HealthServer.md)               |
| HEALTH_SERVER_PORT         | `8080`        | Port the health server listens on                                            |

### Adding Additional Variables

Any configuration value that is available via `arkmanager` can be set using an environment variable. This works by taking any environment variable on the container that is prefixed with `am_` and mapping it to the corresponding environment variable in the `arkmanager.cfg` file.

For a complete list of configuration values available, please see [FezVrasta](https://github.com/arkmanager)'s great documentation here: [arkmanager Configuration Files](https://github.com/arkmanager/ark-server-tools#configuration-files)

Some examples:
```shell script
am_ark_ServerPassword=s3cr3t
am_ark_GameModIds=889745138,731604991
am_arkopt_clusterid=mycluster
am_arkflag_NoTransferFromFiltering=
am_arkflag_servergamelog=
am_arkflag_ForceAllowCaveFlyers=
```

## Volumes

This image has two main volumes that should be mounted as named volumes or host directories for the persistence of the server install and all related configuration files. More information on Docker volumes here: [Docker: Use Volumes](https://docs.docker.com/storage/volumes/)
The optional volumes can be used to share the server binary files or `clusters` files required to run an ARK cluster and be able to jump from one map to another.

> [!IMPORTANT]
> The `steam` user in the image has UID/GID 1001/1001. All files on the host must give read/write access to this UID/GID.

| Path                                  | Description                                                                                                                                               |
|---------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| /home/steam/.steam/steamapps          | Directory of steamapps and workshop files. Should be mounted so that mod installs are persisted between container runs/restarts                           |
| /ark                                  | Directory that will contain the server files, config files, logs and backups. More information below                                                      |
| /arkserver                            | (optional, $ARKSERVER_SHARED) Directory that contains the server binary files from steam, shared for multiple instances                                   |
| /arkserver/ShooterGame/Saved          | (depends) Directory that contains the game save files - must be mounted if using shared server files                                                      |
| /arkserver/ShooterGame/Saved/clusters | (depends) Directory that contains the shared cluster files required to jump from one ARK server to another - must be mounted if using shared server files |

### Subdirectories of /ark

Inside the `/ark` volume there are several directories containing server related files:

| Path         | Description                                                                                                                              |
|--------------|------------------------------------------------------------------------------------------------------------------------------------------|
| /ark/backup  | Location of the zipped backups genereated from the `arkmaanger backup` command. Compressed using bz2.                                    |
| /ark/config  | Location of server config files. More information:                                                                                       |
| /ark/log     | Location of the arkmanager and arkserver log files                                                                                       |
| /ark/server  | Location of the server installation performed by `steamcmd`. This will contain the ShooterGame directory and the actual server binaries. |
| /ark/staging | Default directory for staging game and mod updates. Can be changed using in `arkmanager.cfg`                                             |

## Running a cluster

See [Clustering](docs/Clustering.md) for full documentation on running a multi-map ARK cluster.

## Health Server

An optional HTTP health server that validates RCON connectivity. Enable with `HEALTH_SERVER=true`.

See [Health Server](docs/HealthServer.md) for full documentation, Kubernetes examples, and endpoint details.
