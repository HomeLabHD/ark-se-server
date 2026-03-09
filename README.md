# arkserver
Docker image for a dedicated ARK Survival Evolved server in a Docker container.

[![CircleCI](https://img.shields.io/circleci/build/github/SickHub/arkserver)](https://app.circleci.com/pipelines/github/SickHub/arkserver) [![Docker image](https://img.shields.io/docker/image-size/drpsychick/arkserver?sort=date)](https://hub.docker.com/r/drpsychick/arkserver/tags) [![Docker Pulls](https://img.shields.io/docker/pulls/drpsychick/arkserver.svg?style=flat-square)](https://hub.docker.com/r/drpsychick/arkserver/) [![License](https://img.shields.io/dub/l/vibe-d.svg?style=flat-square)](https://github.com/drpsychick/arkserver/blob/master/LICENSE)

[![GitHub issues](https://img.shields.io/github/issues/SickHub/arkserver.svg)](https://github.com/SickHub/arkserver/issues) [![GitHub closed issues](https://img.shields.io/github/issues-closed/SickHub/arkserver.svg)](https://github.com/SickHub/arkserver/issues?q=is%3Aissue+is%3Aclosed) [![GitHub pull requests](https://img.shields.io/github/issues-pr/SickHub/arkserver.svg)](https://github.com/SickHub/arkserver/pulls) [![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed/SickHub/arkserver.svg)](https://github.com/SickHub/arkserver/pulls?q=is%3Apr+is%3Aclosed) [![Contributors](https://img.shields.io/github/contributors/SickHub/arkserver.svg)](https://github.com/SickHub/arkserver/graphs/contributors)

[![Paypal](https://img.shields.io/badge/donate-paypal-00457c.svg?logo=paypal)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=FTXDN7LCDWUEA&source=url) [![GitHub Sponsor](https://img.shields.io/badge/github-sponsor-blue?logo=github)](https://github.com/sponsors/DrPsychick)

### Features
* Automated install (pull the image and run, no additional commands necessary)
* Built on [drpsychick/steamcmd](https://github.com/drpsychick/steamcmd) with the latest `steamcmd`
* Configuration via Environment Variables
* Easy crontab manipulation for automated backups, updates, daily restarts, weekly dino wipes, etc
* Simple volume structure for server files, config, logs, backups, etc
* Inherently includes all features present in `arkmanager`
* Optional [RCON health server](docs/HealthServer.md) for application-level readiness checks

### Docker Image: [`drpsychick/arkserver`](https://hub.docker.com/r/drpsychick/arkserver)
| Tag | Description |
|-----|-------------|
| [`latest`](https://hub.docker.com/layers/drpsychick/arkserver/latest/images/sha256-59e6f0d445fa00b26111346854b561d6b1f9b1853e34808a9f1ebffdf32cc703) | most recent build from the master branch |
| [`x.x.x`](https://hub.docker.com/layers/drpsychick/arkserver/latest-v1.6.62/images/sha256-82d8b119c03f04033e399b33cd6a997ab61b88d5e692caf6339349f7ff4495b3) | release builds |

### Documentation

|                     |                                                     |
| ------------------- | --------------------------------------------------- |
| Configuration       | [Environment Variables & Volumes](docs/Configuration.md) |
| arkmanager          | [arkmanager/ark-server-tools](https://github.com/arkmanager/ark-server-tools) |
| Health Server       | [RCON Health Endpoint](docs/HealthServer.md)        |
| Clustering          | [Multi-Map Cluster Setup](docs/Clustering.md)       |

## Quick Start

Pull the latest (or any other desired version):
```bash
docker pull drpsychick/arkserver:latest
```

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

## Credits

* Heavily based on [TuRz4m/Ark-docker](https://github.com/TuRz4m/Ark-docker)
* Uses [FezVrasta](https://github.com/FezVrasta)'s [arkmanager/ark-server-tools](https://github.com/arkmanager/ark-server-tools) for server management
* Forked from [thmhoag/arkserver](https://github.com/thmhoag/arkserver) (August 2022 — split after unaccepted PR)
