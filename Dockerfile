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
        tmux \
        tree \
        util-linux \
        vim \
        # Parsers and Storage
        bzip2 \
        gzip \
        jq \
        yq \
        tar \
        # Databases
        postgresql-client \
        redis-tools \
        # Service Clients
        kcat \
        smbclient \
        # Miscellaneous
        bash \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Microsoft SQL Server client (go-sqlcmd). Not in Debian's repos, so the
# release binary is pinned and checksum-verified. The architecture comes
# from dpkg, not TARGETARCH, since ACR Tasks builds without BuildKit.
ARG SQLCMD_VERSION=1.10.0
ARG SQLCMD_SHA256_AMD64=92516d98c63d99b0994de5b61350c91f6915f9b76f139a59039fbcb225c2e987
ARG SQLCMD_SHA256_ARM64=9faaa981f9c374f319ac796dedb4678499b8596c87d5b6c512e9b0e7a3b74f8e
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN arch="$(dpkg --print-architecture)" && \
    case "${arch}" in \
        amd64) sqlcmd_sha256="${SQLCMD_SHA256_AMD64}" ;; \
        arm64) sqlcmd_sha256="${SQLCMD_SHA256_ARM64}" ;; \
        *) echo "go-sqlcmd: unsupported arch '${arch}'" >&2; exit 1 ;; \
    esac && \
    curl -fsSL -o /tmp/sqlcmd.tar.bz2 \
        "https://github.com/microsoft/go-sqlcmd/releases/download/v${SQLCMD_VERSION}/sqlcmd-linux-${arch}.tar.bz2" && \
    echo "${sqlcmd_sha256}  /tmp/sqlcmd.tar.bz2" | sha256sum -c - && \
    tar -xjf /tmp/sqlcmd.tar.bz2 -C /usr/local/bin sqlcmd && \
    rm /tmp/sqlcmd.tar.bz2 && \
    sqlcmd --version

# gRPC client (grpcurl). Not in Debian's repos, so the release binary is
# pinned and checksum-verified. Its assets name amd64 as x86_64.
ARG GRPCURL_VERSION=1.9.4
ARG GRPCURL_SHA256_AMD64=97e13d58d2733a0e62cd2571d1d5f0c02823f0d25282f08bddedf1ad9c5d1736
ARG GRPCURL_SHA256_ARM64=ad66227d90631da5428b4a5ccf28d63846f0f15649d8b2367df044a59edbb617
RUN arch="$(dpkg --print-architecture)" && \
    case "${arch}" in \
        amd64) grpcurl_arch=x86_64; grpcurl_sha256="${GRPCURL_SHA256_AMD64}" ;; \
        arm64) grpcurl_arch=arm64; grpcurl_sha256="${GRPCURL_SHA256_ARM64}" ;; \
        *) echo "grpcurl: unsupported arch '${arch}'" >&2; exit 1 ;; \
    esac && \
    curl -fsSL -o /tmp/grpcurl.tar.gz \
        "https://github.com/fullstorydev/grpcurl/releases/download/v${GRPCURL_VERSION}/grpcurl_${GRPCURL_VERSION}_linux_${grpcurl_arch}.tar.gz" && \
    echo "${grpcurl_sha256}  /tmp/grpcurl.tar.gz" | sha256sum -c - && \
    tar -xzf /tmp/grpcurl.tar.gz -C /usr/local/bin grpcurl && \
    rm /tmp/grpcurl.tar.gz && \
    grpcurl --version

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

# root user home directory on Debian. HOME is set explicitly since
# testcalcmcp.sh resolves its "${HOME}/lib/sh-lib" dependency at
# runtime and cannot rely on a shell inferring it from /etc/passwd.
WORKDIR /root
ENV HOME=/root

# copy user environment files
COPY context/bashrc .bashrc
COPY context/bash_aliases .bash_aliases
COPY context/bash_profile .bash_profile
COPY context/inputrc .inputrc
COPY context/vimrc .vimrc
COPY context/lib lib
COPY context/testcalcmcp.sh bin/testcalcmcp.sh
RUN chmod 750 bin/testcalcmcp.sh

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
