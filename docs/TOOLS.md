# Tools

Tools installed by the `Dockerfile`, grouped as in the `README.md`.

This project's source code and documentation were generated with the
assistance of Artificial Intelligence (AI). For more information, please
refer to the `AI_DISCLAIMER.md` document located in the project's root
directory.

## Networking

| Tool                | Description                                          |
|---------------------|------------------------------------------------------|
| `apache2-utils`     | `ab` for HTTP load tests and `htpasswd`.             |
| `dnsutils`          | `dig` and `nslookup` for DNS queries.                |
| `curl`              | HTTP(S) requests with verbose TLS and header output. |
| `iperf3`            | Network throughput tests between two hosts.          |
| `iproute2`          | `ip` and `ss` for interfaces, routes, and sockets.   |
| `iputils-ping`      | `ping` for ICMP reachability checks.                 |
| `iputils-tracepath` | `tracepath` for path and MTU discovery.              |
| `mtr-tiny`          | Combined `ping` and `traceroute`, with TCP mode.     |
| `net-tools`         | Legacy `netstat`, `ifconfig`, and `route`.           |
| `netcat-openbsd`    | `nc` for TCP/UDP port checks and raw connections.    |
| `nmap`              | Port scans and service detection.                    |
| `openssh-client`    | `ssh` and `scp` to remote hosts.                     |
| `openssl`           | TLS handshake and certificate inspection.            |
| `socat`             | Bidirectional relays between sockets and streams.    |
| `tcpdump`           | Packet capture and filtering.                        |
| `telnet`            | Plain-text TCP connections to a port.                |
| `traceroute`        | Route tracing over ICMP, UDP, or TCP.                |
| `wget`              | Non-interactive HTTP(S) downloads.                   |

## System & Process Monitoring

| Tool              | Description                                         |
|-------------------|-----------------------------------------------------|
| `bash-completion` | Tab completion for common commands.                 |
| `bsdextrautils`   | `column`, `hexdump`, and other text utilities.      |
| `coreutils`       | Core file, text, and shell utilities.               |
| `gawk`            | GNU `awk` for text processing.                      |
| `htop`            | Interactive process and resource viewer.            |
| `less`            | Pager for viewing files and command output.         |
| `lsof`            | Lists open files and network sockets per process.   |
| `ncurses-bin`     | `clear`, `tput`, and other terminal utilities.      |
| `procps`          | `ps`, `top`, `free`, and `watch`.                   |
| `strace`          | Traces system calls of a process.                   |
| `tmux`            | Terminal multiplexer for multiple panes in a shell. |
| `tree`            | Directory listing as a tree.                        |
| `util-linux`      | Assorted system utilities, such as `lsblk`.         |
| `vim`             | Text editor.                                        |

## Parsers and Storage

| Tool    | Description                        |
|---------|------------------------------------|
| `bzip2` | `.bz2` compression and extraction. |
| `gzip`  | `.gz` compression and extraction.  |
| `jq`    | JSON query and transformation.     |
| `yq`    | YAML query and transformation.     |
| `tar`   | Archive creation and extraction.   |

## Databases

| Tool                 | Description                                        |
| -------------------- | -------------------------------------------------- |
| `postgresql-client`  | `psql`, `pg_isready`, `pg_dump`, and `pg_restore`. |
| `redis-tools`        | `redis-cli` for Azure Cache for Redis.             |
| `sqlcmd` (go-sqlcmd) | Microsoft SQL Server and Azure SQL client.         |

## Service Clients

| Tool        | Description                                  |
| ----------- | -------------------------------------------- |
| `grpcurl`   | Calls gRPC services from the command line.   |
| `kcat`      | Kafka client for Event Hubs' Kafka endpoint. |
| `smbclient` | SMB client for Azure Files shares.           |

## Miscellaneous

| Tool              | Description                                  |
|-------------------|----------------------------------------------|
| `bash`            | Default shell.                               |
| `ca-certificates` | Trusted CA certificates for TLS connections. |
