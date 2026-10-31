# arkserver
ARK: Survival Evolved dedicated server image, for single instances and clusters.

<!-- sf:project:start -->
[![GitHub](https://img.shields.io/badge/GitHub-mirror-181717?logo=github)](https://github.com/HomeLabHD/ark-se-server) [![GitLab](https://img.shields.io/badge/GitLab-source-FC6D26?logo=gitlab)](https://gitlab.prplanit.com/HomeLabHD/ark-se-server) [![license](https://raw.githubusercontent.com/HomeLabHD/ark-se-server/main/.stagefreight/scribe/license.svg)](https://github.com/HomeLabHD/ark-se-server/blob/main/LICENSE) [![Open Issues](https://img.shields.io/github/issues/HomeLabHD/ark-se-server)](https://github.com/HomeLabHD/ark-se-server/issues) [![Open PRs](https://img.shields.io/github/issues-pr/HomeLabHD/ark-se-server)](https://github.com/HomeLabHD/ark-se-server/pulls) [![Contributors](https://img.shields.io/github/contributors/HomeLabHD/ark-se-server)](https://github.com/HomeLabHD/ark-se-server/graphs/contributors) [![donate](https://img.shields.io/badge/donate-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/T6T41IT163) [![sponsor](https://img.shields.io/badge/sponsor-EA4AAA?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/HomeLabHD)
<!-- sf:project:end -->
<!-- sf:badges:start -->
[![release](https://raw.githubusercontent.com/HomeLabHD/ark-se-server/main/.stagefreight/scribe/release.svg)](https://github.com/HomeLabHD/ark-se-server/releases) [![build](https://raw.githubusercontent.com/HomeLabHD/ark-se-server/main/.stagefreight/scribe/build.svg)](https://gitlab.prplanit.com/HomeLabHD/ark-se-server/-/pipelines) [![Last Commit](https://img.shields.io/github/last-commit/HomeLabHD/ark-se-server)](https://github.com/HomeLabHD/ark-se-server/commits) [![StageFreight](https://img.shields.io/badge/StageFreight-0.14.0--dev+58dc841-310937?logo=readthedocs&logoColor=white)](https://stagefreight.prplanit.com)
<!-- sf:badges:end -->
<!-- sf:image:start -->
[![GHCR](https://img.shields.io/badge/GHCR-homelabhd%2Fark--se--server-181717?logo=github&logoColor=white)](https://github.com/HomeLabHD/ark-se-server/pkgs/container/ark-se-server) [![Docker](https://img.shields.io/badge/Docker-hlhd%2Fark--se--server-2496ED?logo=docker&logoColor=white)](https://hub.docker.com/r/hlhd/ark-se-server) [![pulls](https://img.shields.io/docker/pulls/hlhd/ark-se-server?color=1d63ed&logo=docker&logoColor=white)](https://hub.docker.com/r/hlhd/ark-se-server) [![Harbor](https://img.shields.io/badge/Harbor-hlhd%2Fark--se--server-60b932)](https://cr.pcfae.com/harbor/projects)

[![latest](https://raw.githubusercontent.com/HomeLabHD/ark-se-server/main/.stagefreight/scribe/release-latest.svg)](https://github.com/HomeLabHD/ark-se-server/pkgs/container/ark-se-server) ![updated](https://raw.githubusercontent.com/HomeLabHD/ark-se-server/main/.stagefreight/scribe/release-updated.svg) [![size](https://raw.githubusercontent.com/HomeLabHD/ark-se-server/main/.stagefreight/scribe/release-size.svg)](https://github.com/HomeLabHD/ark-se-server/pkgs/container/ark-se-server) [![latest-dev](https://raw.githubusercontent.com/HomeLabHD/ark-se-server/main/.stagefreight/scribe/dev-latest.svg)](https://github.com/HomeLabHD/ark-se-server/pkgs/container/ark-se-server) ![updated](https://raw.githubusercontent.com/HomeLabHD/ark-se-server/main/.stagefreight/scribe/dev-updated.svg) [![size](https://raw.githubusercontent.com/HomeLabHD/ark-se-server/main/.stagefreight/scribe/dev-size.svg)](https://github.com/HomeLabHD/ark-se-server/pkgs/container/ark-se-server)
<!-- sf:image:end -->

[![GitHub](https://img.shields.io/badge/GitHub-upstream-181717?logo=github)](https://github.com/SickHub/arkserver) [![GitHub issues](https://img.shields.io/github/issues/SickHub/arkserver.svg)](https://github.com/SickHub/arkserver/issues) [![GitHub pull requests](https://img.shields.io/github/issues-pr/SickHub/arkserver.svg)](https://github.com/SickHub/arkserver/pulls) [![Contributors](https://img.shields.io/github/contributors/SickHub/arkserver.svg)](https://github.com/SickHub/arkserver/graphs/contributors) [![Paypal](https://img.shields.io/badge/donate-paypal-00457c.svg?logo=paypal)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=FTXDN7LCDWUEA&source=url) [![GitHub Sponsor](https://img.shields.io/badge/github-sponsor-blue?logo=github)](https://github.com/sponsors/DrPsychick)

### Features
* Automated install (pull the image and run, no additional commands necessary)
* A fork of [SickHub/arkserver](https://github.com/SickHub/arkserver), built on [drpsychick/steamcmd](https://github.com/drpsychick/steamcmd) with the latest `steamcmd`
* Configuration via Environment Variables
* Easy crontab manipulation for automated backups, updates, daily restarts, weekly dino wipes, etc
* Simple volume structure for server files, config, logs, backups, etc
* Inherently includes all features present in `arkmanager`
* Optional [RCON health server](docs/HealthServer.md) for application-level readiness checks

### Documentation

|                     |                                                     |
| ------------------- | --------------------------------------------------- |
| Install             | [Docker, Compose & Kubernetes](docs/Install.md)     |
| Configuration       | [Environment Variables & Volumes](docs/Configuration.md) |
| arkmanager          | [arkmanager/ark-server-tools](https://github.com/arkmanager/ark-server-tools) |
| Clustering          | [Multi-Map Cluster Setup](docs/Clustering.md)       |
| Health Server       | [RCON Health Endpoint](docs/HealthServer.md)        |
| Helm Chart          | [ark-server-charts](https://github.com/SickHub/ark-server-charts)             |

## Quick Start

```bash
docker run -d \
    -v steam:/home/steam/.steam/steamapps \
    -v ark:/ark \
    -p 27015:27015 -p 27015:27015/udp \
    -p 7778:7778 -p 7778:7778/udp \
    -p 7777:7777 -p 7777:7777/udp \
    hlhd/ark-se-server
```

See [Install](docs/Install.md) for Docker Compose and Kubernetes examples.

## Credits

* Heavily based on [TuRz4m/Ark-docker](https://github.com/TuRz4m/Ark-docker)
* Uses [FezVrasta](https://github.com/FezVrasta)'s [arkmanager/ark-server-tools](https://github.com/arkmanager/ark-server-tools) for server management
* Forked from [thmhoag/arkserver](https://github.com/thmhoag/arkserver) (August 2022 — split after unaccepted PR)
