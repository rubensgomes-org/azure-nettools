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

# copy OS environment files
COPY motd /etc/motd

# ---------- >>> LABEL <<< ----------------------------------------------------

# Deliberately NOT a real version number. This only feeds the OCI label below,
# and a plausible-looking default would silently drift from the VERSION file
# on every release. Pass --build-arg VERSION="$(cat VERSION)" to set it.
ARG VERSION=0.0.0

LABEL org.opencontainers.image.title="azure-nettools" \
      org.opencontainers.image.description="Linux tools to troubleshoot Azure ACAs" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.source="https://github.com/rubensgomes-org/azure-nettools" \
      org.opencontainers.image.url="https://github.com/rubensgomes-org/azure-nettools" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.authors="Rubens Gomes <rubens.s.gomes@gmail.com>"

# ---------- >>> USER <<< -----------------------------------------------------

# root user home directory on Debian
WORKDIR /root

# copy user environment files
COPY bashrc .bashrc
COPY bash_aliases .bash_aliases
COPY bash_profile .bash_profile
COPY inputrc .inputrc
COPY vimrc .vimrc

# bash rules!
CMD ["/bin/bash"]
