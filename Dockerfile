FROM debian:stable-slim

# ---------- >>> PACKAGES <<< -------------------------------------------------

# Install core troubleshooting utilities. Versions are deliberately
# unpinned: this image tracks the latest tool builds, not a reproducible
# pin, so DL3008 is intentional here.
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # Networking \
        apache2-utils \
        dnsutils \
        curl \
        iperf3 \
        iproute2 \
        iputils-ping \
        iputils-tracepath \
        mtr-tiny \
        net-tools \
        netcat-openbsd \
        nmap \
        openssh-client \
        openssl \
        socat \
        tcpdump \
        telnet \
        traceroute \
        wget \
        # System & Process Monitoring \
        bash-completion \
        bsdextrautils \
        coreutils \
        gawk \
        htop \
        less \
        lsof \
        ncurses-bin \
        procps \
        strace \
        tree \
        util-linux \
        vim \
        # Parsers and Storage
        gzip \
        jq \
        yq \
        tar \
        # Miscellaneous
        bash \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Deliberately NOT a real version number. This feeds the motd and the OCI
# label below, and a plausible-looking default would silently drift from the
# VERSION file on every release. Pass --build-arg APP_VERSION="$(cat VERSION)"
# to set it -- named APP_VERSION, not VERSION, to match what the
# publish-acr-image reusable CI action (azure-workflows) passes. Declared
# here, after the apt-get layer, so a version bump does not invalidate that
# layer's build cache.
ARG APP_VERSION=0.0.0

# copy OS environment files
COPY context/motd /etc/motd
RUN sed -i "s/{{VERSION}}/${APP_VERSION}/" /etc/motd

# ---------- >>> LABEL <<< ----------------------------------------------------

LABEL org.opencontainers.image.title="azure-nettools" \
      org.opencontainers.image.description="Linux tools to troubleshoot Azure ACAs" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.source="https://github.com/rubensgomes-org/azure-nettools" \
      org.opencontainers.image.url="https://github.com/rubensgomes-org/azure-nettools" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.authors="Rubens Gomes <rubens.s.gomes@gmail.com>"

# ---------- >>> USER <<< -----------------------------------------------------

# root user home directory on Debian
WORKDIR /root

# copy user environment files
COPY context/bashrc .bashrc
COPY context/bash_aliases .bash_aliases
COPY context/bash_profile .bash_profile
COPY context/inputrc .inputrc
COPY context/vimrc .vimrc

# ---------- >>> HEALTH RESPONDER <<< -----------------------------------------

# Answers Azure Container Apps' default ingress startup probe on 80
# (see healthd.sh) and keeps the container running for `az
# containerapp exec`. 80 matches module 11's default `target_port` --
# nettools has no real HTTP app, so there's no reason to diverge from
# it and add a TF_VAR_target_port repository variable just for this.
COPY context/healthd.sh /usr/local/bin/healthd.sh
ENV HTTP_PORT=80
EXPOSE 80

CMD ["/usr/local/bin/healthd.sh"]
