# Azure NetTools Container App

[![GitHub](https://img.shields.io/badge/GitHub-Actions-0969da?logo=github+actions)](https://github.com/features/actions)
[![Microsoft](https://img.shields.io/badge/Microsoft-Azure-0969da)](https://azure.microsoft.com/en-us)
[![AI](https://img.shields.io/badge/AI-Assisted-d29922?logo=claude+code)](https://github.com/rubensgomes-org/azure-nettools/blob/main/AI_DISCLAIMER.md)
[![license](https://img.shields.io/badge/license-MIT-1a7f37)](https://github.com/rubensgomes-org/azure-nettools/blob/main/LICENSE)

`azure-nettools` is an Azure Container App that provides a terminal with several
Linux networking tools to help troubleshoot and test other container apps
running in the same Azure Container Apps environment VNet.

---

## Features

The image includes the following tools, among others (see
[TOOLS.md](docs/TOOLS.md) for descriptions):

1. Networking

- `apache2-utils`, `curl`, `dnsutils`, `iperf3`, `iproute2`, `iputils-ping`,
  `iputils-tracepath`, `mtr-tiny`, `net-tools`, `netcat-openbsd`, `nmap`,
  `openssh-client`, `openssl`, `socat`, `tcpdump`, `telnet`, `traceroute`,
  `wget`

2. System & Process Monitoring

- `bash-completion`, `bsdextrautils`, `coreutils`, `gawk`, `htop`, `less`,
  `lsof`, `ncurses-bin`, `procps`, `strace`, `tmux`, `tree`, `util-linux`, `vim`

3. Parsers and Storage

- `bzip2`, `gzip`, `jq`, `tar`, `yq`

4. Databases

- `postgresql-client`, `redis-tools`, `sqlcmd` (go-sqlcmd)

5. Service Clients

- `grpcurl`, `kcat`, `smbclient`

6. Miscellaneous

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

- Create the container app:

  ```text
  # run GitHub Action:
  .github/workflows/aca-create.yml
  ```

- Build and deploy the image:

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

- Ensure at least one replica is running:

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

- Requires a `calculator-mcp` server reachable over plain HTTP with
  `server.stateless: true` in its `config.yaml`.
- Run `testcalcmcp.sh --help` for all options.

## License

The project is licensed under the
[MIT License](https://github.com/rubensgomes-org/azure-nettools/blob/main/LICENSE).

## Links

- [GitHub Project](https://github.com/rubensgomes-org/azure-nettools)
- [Azure Commands](https://github.com/rubensgomes-org/azure-nettools/blob/main/docs/AZ_CMD.md)
- [Tools](https://github.com/rubensgomes-org/azure-nettools/blob/main/docs/TOOLS.md)

---
Author: [Rubens Gomes](https://rubensgomes.com/)
