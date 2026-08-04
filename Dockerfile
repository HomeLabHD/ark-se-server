ARG STEAMCMD_VERSION=latest
ARG AMG_BUILD=latest
# github-releases:arkmanager/ark-server-tools
ARG AMG_VERSION=v1.6.69
FROM drpsychick/steamcmd:$STEAMCMD_VERSION AS base

LABEL maintainer="HomeLabHD <homelabhelp@gmail.com>" \
    org.opencontainers.image.title="ark-se-server" \
    org.opencontainers.image.description="ARK: Survival Evolved dedicated server with arkmanager, RCON health endpoint, and cron-based automation." \
    org.opencontainers.image.source="https://github.com/HomeLabHD/ark-se-server" \
    org.opencontainers.image.url="https://hub.docker.com/r/hlhd/ark-se-server" \
    org.opencontainers.image.documentation="https://github.com/HomeLabHD/ark-se-server#readme" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.vendor="HomeLabHD"

USER root

RUN apt-get update \
    && apt-get install -y \
    curl \
    cron \
    bzip2 \
    perl-modules \
    lsof \
    libc6-i386 \
#    libsdl2-2.0.0:i386 \
    sudo \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

FROM base AS arkmanager-latest
# -f: fail the build on an HTTP error instead of piping a 404 body into bash.
# test -x: netinstall.sh's die() does a bare `exit` (== exit 0), so a failed
# install returns success and installs nothing — verify the binary landed.
RUN curl -fsSL "https://git.io/arkmanager" | bash -s steam \
 && test -x /usr/local/bin/arkmanager

FROM base AS arkmanager-versioned
ARG AMG_VERSION
# Install the EXACT pinned tag from its release tarball + install.sh. We do NOT
# use netinstall.sh here: its only modes are "latest release" or a branch, and
# with --unstable it silently installs master HEAD — so AMG_VERSION never pinned
# the tool, only the bootstrapper. This path installs $AMG_VERSION verbatim,
# stamps arkstTag, and the final grep FAILS THE BUILD if the pin didn't take
# (no silent master-fallback). -f fails on HTTP errors; test -x catches a no-op.
RUN cd /tmp \
 && curl -fsSL "https://github.com/arkmanager/ark-server-tools/archive/refs/tags/${AMG_VERSION}.tar.gz" | tar -xz \
 && ( cd "ark-server-tools-${AMG_VERSION#v}/tools" \
      && sed -i "s|^arkstTag='.*'|arkstTag='${AMG_VERSION}'|" arkmanager \
      && bash install.sh steam ) \
 && rm -rf "/tmp/ark-server-tools-${AMG_VERSION#v}" \
 && test -x /usr/local/bin/arkmanager \
 && grep -q "^arkstTag='${AMG_VERSION}'" /usr/local/bin/arkmanager

ARG AMG_BUILD
FROM arkmanager-$AMG_BUILD
# Never symlink a target that isn't there (that was the exit-127 crashloop).
RUN test -x /usr/local/bin/arkmanager \
 && ln -s /usr/local/bin/arkmanager /usr/bin/arkmanager

COPY arkmanager/arkmanager.cfg /etc/arkmanager/arkmanager.cfg
COPY arkmanager/instance.cfg /etc/arkmanager/instances/main.cfg
COPY scripts/run.sh /home/steam/run.sh
COPY scripts/log.sh /home/steam/log.sh
COPY scripts/health-server.py /home/steam/health-server.py

RUN echo "%sudo   ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers \
    && usermod -a -G sudo steam \
    && mkdir /ark /arkserver \
    && chown -R steam:steam /ark /arkserver

WORKDIR /home/steam
USER steam

ENV am_ark_SessionName=Ark\ Server \
    am_serverMap=TheIsland \
    am_ark_ServerAdminPassword=k3yb04rdc4t \
    am_ark_MaxPlayers=70 \
    am_ark_QueryPort=27015 \
    am_ark_Port=7778 \
    am_ark_RCONPort=32330 \
    am_ark_AltSaveDirectoryName=SavedArks \
    am_arkwarnminutes=15 \
    am_arkAutoUpdateOnStart=false

ENV VALIDATE_SAVE_EXISTS=false \
    BACKUP_ONSTART=false \
    LOG_RCONCHAT=0 \
    ARKCLUSTER=false \
    HEALTH_SERVER=false \
    HEALTH_SERVER_PORT=8080

# only mount the steamapps directory
# mount /home/steam/.steam/steamapps if you want to share storage for steam mod staging
VOLUME /ark
# optionally shared volumes between servers in a cluster
VOLUME /arkserver
# mount /arkserver/ShooterGame/Saved seperate for each server
# mount /arkserver/ShooterGame/Saved/clusters shared for all servers

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=15s --start-period=120s --retries=3 \
    CMD arkmanager rconcmd "ListPlayers" || exit 1

CMD [ "./run.sh" ]
