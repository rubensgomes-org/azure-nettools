# Azure NetTools

I created this `azure-nettools` project to create a "Swiss Army knife"
containerized image of Linux tools to help troubleshoot other Azure Container 
Apps running in the same Container Apps Environment (CAE) VNet.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/rubensgomes-org/azure-nettools/blob/main/LICENSE)
[![AI Assisted](https://img.shields.io/badge/AI--Assisted-Development-007ACC)](https://github.com/rubensgomes-org/azure-nettools/blob/main/AI_DISCLAIMER.md)


## Features

Among others, I am including the following tools:

1. Networking

- bind-tools
- curl
- iperf3
- iproute2
- iptables
- iputils
- liboping
- mtr
- net-tools
- nmap
- openssh-client
- socat
- tcpdump
- wget

2. System & Process Monitoring

- coreutils
- gawk
- htop
- lsof
- procps
- strace
- util-linux
- vim

3. Parsers and Storage

- gzip
- jq
- yq
- tar

4. Miscellaneous

- bash
- ca-certificates
- uuidgen

## AI Disclaimer

This project includes code and documentation created with the assistance of AI
tools. For details on usage, limits, and review practices, please see the
[AI Disclaimer](https://github.com/rubensgomes-org/azure-nettools/blob/main/AI_DISCLAIMER.md).

## Prerequisites

- UNIX OS (e.g., macOS, Linux)
- Docker 29.8+

## Installation and Usage

- **Build the image:**

    ```bash
    VERSION="$(cat VERSION)"
    docker build --debug \
      --build-arg APP_VERSION="${VERSION}" \
      -t "nettools:${VERSION}" \
      -t "nettools:latest" .
    ```

- **Run the container:**
    ```bash
    docker run -it --rm --name nettools nettools:latest
    ```

## Testing a calculator-mcp Server

The image includes `testcalcmcp.sh` (`/root/bin/testcalcmcp.sh`), which
exercises a `calculator-mcp` server running the Modern Era (2026-07-28
spec) MCP protocol over HTTP in stateless mode: `/health`, `tools/list`,
one `tools/call` per tool, and `server/discover`.

```bash
testcalcmcp.sh --host <host> --port <port>
```

- Defaults to `127.0.0.1:8080` when `--host`/`--port` are omitted.
- Requires a `calculator-mcp` server reachable over clear HTTP with
  `server.stateless: true` in its `config.yaml`.
- Run `testcalcmcp.sh --help` for all options.

## License

The project is licensed under
[MIT License](https://github.com/rubensgomes-org/azure-nettools/blob/main/LICENSE).

---
Author: [Rubens Gomes](https://rubensgomes.com/)
