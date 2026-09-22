# Azure NetTools Container App

`azure-nettools` is an Azure Container App that provides a terminal with several
Linux networking tools to help troubleshoot and test other container apps
running in the same Azure Container Apps environment VNet.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/rubensgomes-org/azure-nettools/blob/main/LICENSE)
[![AI Assisted](https://img.shields.io/badge/AI--Assisted-Development-007ACC)](https://github.com/rubensgomes-org/azure-nettools/blob/main/AI_DISCLAIMER.md)

## Features

Among others, I am including the following tools:

1. Networking

- `apache2-utils`, `dnsutils`, `curl`, `iperf3`, `iproute2`, `iputils-ping`,
  `iputils-tracepath`, `mtr-tiny`, `net-tools`, `netcat-openbsd`, `nmap`,
  `openssh-client`, `openssl`, `socat`, `tcpdump`, `telnet`, `traceroute`,
  `wget`

2. System & Process Monitoring

- `bash-completion`, `bsdextrautils`, `coreutils`, `gawk`, `htop`, `less`,
  `lsof`, `ncurses-bin`, `procps`, `strace`, `tree`, `util-linux`, `vim`

3. Parsers and Storage

- `gzip`, `jq`, `yq`, `tar`

4. Miscellaneous

- `bash`, `ca-certificates`

## AI Disclaimer

This project includes code and documentation created with the assistance of AI
tools. For details on usage, limits, and review practices, please see the
[AI Disclaimer](https://github.com/rubensgomes-org/azure-nettools/blob/main/AI_DISCLAIMER.md).

## Prerequisites

- Environment Setup: Azure + GitHub

## Installation

- Build and verify the image:

  ```text
  # run GitHub Action:
  .github/workflows/build-verify.yml
  ```

- Create container app:

  ```text
  # run GitHub Action:
  .github/workflows/aca-create.yml
  ```

- Build and deploy image:

  ```text
  # run GitHub Action:
  .github/workflows/build-deploy.yml
  ```

## Usage

- Sign in to Azure (**requires environment setup**)

  ```bash
  az login --service-principal \
    --username "${AZURE_CLIENT_ID}" \
    --password "${AZURE_CLIENT_SECRET}" \
    --tenant "${AZURE_TENANT_ID}"
  ```

- Ensure at least 1 (one) replica running:

  ```bash
  az containerapp update \
    -n "ca-nettools-dev" \
    -g "rg-rgomesapp-dev" \
    --min-replicas 1
  ```

- Shell into the terminal:

  ```bash
  az containerapp exec \
    --name "ca-nettools-dev" \
    --resource-group "rg-rgomesapp-dev" \
    --command /bin/bash
  ```

## Testing the calculator-mcp Server

The image includes `testcalcmcp.sh` (`/root/bin/testcalcmcp.sh`), which
exercises a `calculator-mcp` server running the Modern Era (2026-07-28
spec) MCP protocol over HTTP in stateless mode: `/health`, `tools/list`,
one `tools/call` per tool, and `server/discover`.

```bash
testcalcmcp.sh --host <host> --port <port>
```

- Requires a `calculator-mcp` server reachable over clear HTTP with
  `server.stateless: true` in its `config.yaml`.
- Run `testcalcmcp.sh --help` for all options.

## License

The project is licensed under
[MIT License](https://github.com/rubensgomes-org/azure-nettools/blob/main/LICENSE).

---
Author: [Rubens Gomes](https://rubensgomes.com/)
