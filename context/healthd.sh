#!/bin/sh
## SPDX-License-Identifier: MIT
##
## Minimal TCP/HTTP responder so Azure Container Apps' default ingress
## startup probe succeeds. This image ships no real HTTP service --
## nettools is a debug/exec toolbox -- so this exists purely to answer
## the probe, not to serve real traffic. Also keeps the container
## running: a bare `/bin/bash` CMD exits immediately (no TTY at
## container start), which causes a CrashLoopBackOff.
##
## This project's source code and documentation were generated with
## the assistance of Artificial Intelligence (AI). For more
## information, please refer to the `AI_DISCLAIMER.md` document
## located in the project's root directory.

set -u

port="${HTTP_PORT:-8080}"
response_file="$(mktemp)"
trap 'rm -f "${response_file}"' EXIT

# Written to a file rather than inlined in the socat command below:
# socat interprets backslash escapes (\r, \n) in its OWN address-string
# parsing before ever handing the command to a shell, so an inline
# `\r\n` arrives at the inner shell as a REAL newline and breaks the
# command into unrelated, failing lines. A plain `cat` of a file with
# real CRLF bytes already in it has no escapes for socat to mangle.
printf 'HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n' \
  > "${response_file}"

# One connection at a time, in the foreground of this loop -- no
# `fork`/background socat, so the shell reaps every child itself and
# nothing accumulates as a zombie under continual probe traffic.
while true; do
  socat -T 5 TCP-LISTEN:"${port}",reuseaddr SYSTEM:"cat ${response_file}" \
    || true
done
