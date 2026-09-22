#!/usr/bin/env bash
## SPDX-License-Identifier: MIT
##
## Exercises a calculator-mcp server running in Modern Era
## (2026-07-28 spec) HTTP stateless mode: health, tools/list, a
## tools/call sample request for every tool, and server/discover.
##
## Requirements:
##  1) Bash functions libraries installed at "${HOME}/lib/sh-lib".
##  2) GNU bash version 4.2 or higher, required by associative
##     arrays.
##  3) curl 8.7.1 or higher.
##  4) getopt from util-linux 2.30.2 or higher.
##  5) A calculator-mcp server reachable over clear HTTP with
##     server.stateless: true in its config.yaml.
##
## Author: Rubens Gomes
## NOTE:   Initial implementation was generated with AI assistance
##         and subsequently reviewed and approved by the author.
##
## This project's source code and documentation were generated with
## the assistance of Artificial Intelligence (AI). For more
## information, please refer to the `AI_DISCLAIMER.md` document
## located in the project's root directory.


#####################################################################
## GLOBAL CONSTANTS #################################################

# shell script program name
declare PRG
PRG="$(
  basename -- "${0}" || {
    printf "failed to determine the program basename." >&2
    exit 1
  }
)"

# minimum Bash major / minor version required
# shellcheck disable=SC2034
readonly BASH_MAJOR_VERSION="4"
# shellcheck disable=SC2034
readonly BASH_MINOR_VERSION="2"

# Set to TRUE when debugging code using bassupport-pro. This is
# required to bypass trap handlers which crashes code when running
# from debugger
readonly IS_DEBUGGER=FALSE

# extra tools required by this script to run.
[[ ! -v REQUIRED_TOOLS ]] && readonly -a REQUIRED_TOOLS=(
  "curl"
  "getopt"
)

# MCP server host and port used when not overridden by CLI options
readonly DEFAULT_MCP_HOST="127.0.0.1"
readonly DEFAULT_MCP_PORT="8080"

# well-known paths on the calculator-mcp server
readonly HEALTH_ENDPOINT_PATH="/health"
readonly MCP_ENDPOINT_PATH="/mcp"

# Modern Era (2026-07-28 spec) protocol version and the two
# params._meta envelope keys every stateless request must carry
readonly MCP_PROTOCOL_VERSION="2026-07-28"
readonly META_PROTOCOL_VERSION_KEY=\
"io.modelcontextprotocol/protocolVersion"
readonly META_CLIENT_CAPABILITIES_KEY=\
"io.modelcontextprotocol/clientCapabilities"

# every tool the calculator-mcp server exposes, in tools/list order
readonly -a TOOL_NAMES=(
  "add" "subtract" "multiply" "divide" "power" "nth_root"
  "modulo" "floor_divide" "sqrt" "absolute" "floor" "ceil"
  "log10" "ln" "exp" "round_number"
)

#####################################################################
## INCLUDES #########################################################

[[ -d "${HOME}/lib/sh-lib" ]] || {
  printf "missing %s\n" "${HOME}/lib/sh-lib" >&2
  exit 1
}

# logging message library
# shellcheck source=/dev/null
source "${HOME}/lib/sh-lib/msg_lib.sh" || exit

# operating system library
# shellcheck source=/dev/null
source "${HOME}/lib/sh-lib/os_lib.sh" || exit

# bash library
# shellcheck source=/dev/null
source "${HOME}/lib/sh-lib/sh_lib.sh" || exit


#####################################################################
## GLOBAL VARIABLES #################################################

# MCP server host to exercise
declare g_host=

# MCP server TCP port to exercise
declare g_port=


#####################################################################
## FUNCTIONS ########################################################

#####################################################################
## Prints help to stdout.
## Globals:
##  DEFAULT_MCP_HOST
##  DEFAULT_MCP_PORT
##  PRG
## Arguments:
##  none.
## Returns:
##   0 always
#####################################################################
help() {
  cat <<EOF

"${PRG}" exercises a calculator-mcp server running in HTTP
stateless mode: health, tools/list, a tools/call sample request
for every tool, and server/discover.

Usage:
  ${PRG} [options]

General Non Argument Options:

  -d, --debug                  prints debug messages
  -h, --help                   prints this help
  -q, --quiet                  prints only error|fatal messages
  -v, --verbose                adds extra details to messages
  -x, --trace                  traces commands

Argument Options:

  -H, --host <host>            MCP server IP or hostname
                                (default: ${DEFAULT_MCP_HOST})
  -p, --port <port>            MCP server TCP port
                                (default: ${DEFAULT_MCP_PORT})

Example:
  ${PRG} --host 192.168.1.50 --port 9999

EOF
}

#####################################################################
## Prints usage to stderr.
## Globals:
##  PRG
## Arguments:
##  none.
## Exits:
##   2 always
#####################################################################
usage() {
  cat <<EOF
Usage:  ${PRG} [options]
More information with: "${PRG} -h"
EOF

  # return an error status
  return 2
} >&2

#####################################################################
## Initializes global variables to their initial state.
## Globals:
##  DEFAULT_MCP_HOST
##  DEFAULT_MCP_PORT
##  g_host
##  g_port
## Arguments:
##  None
## Returns:
##   0 if okay; something else if fails.
#####################################################################
reset_globals() {
  g_host="${DEFAULT_MCP_HOST}"
  g_port="${DEFAULT_MCP_PORT}"
}

#####################################################################
## Parses user's command line input option arguments.
## Globals:
##  g_host
##  g_port
## Arguments:
##  Bash shell CLI input arguments.
## Returns:
##   0 if okay; something else if fails.
#####################################################################
parse_options() {

  # reset globals so that I can call this function multiple times
  # from within same unit test function stack frame, and not have
  # previous global values impact the next tests within the same
  # stack function frame.
  reset_globals

  local temp

  if ! temp=$(
    getopt \
      --o 'dhH:p:qvx' \
      --long 'debug,help,host:,port:,quiet,trace,verbose' \
      --name "${PRG}" \
      -- "${@}"
  ); then
    msg::error "failed to parse CLI input arguments."
    usage
    return 2
  fi

  eval set -- "${temp}"

  while true; do

    case "${1}" in

      ########## --debug ############################################
      '-d' | '--debug')
        msg::enable_debug
        shift
        continue
        ;;

      ########## --help #############################################
      '-h' | '--help')
        help
        exit 0
        ;;

      ########## --host #############################################
      '-H' | '--host')
        if [[ -z "${2:-}" || -z "${2//[[:space:]]/}" ]]; then
          msg::error "host is missing or blank.\n"
          usage
          return 2
        fi
        g_host="$(sh::trim_space "${2}")" || return
        msg::debug "host=%s\n" "${g_host}"
        shift 2
        continue
        ;;

      ########## --port #############################################
      '-p' | '--port')
        if [[ -z "${2:-}" || -z "${2//[[:space:]]/}" ]]; then
          msg::error "port is missing or blank.\n"
          usage
          return 2
        fi
        local tmp_port
        tmp_port="$(sh::trim_space "${2}")" || return
        if [[ ! "${tmp_port}" =~ ^[0-9]+$ ]] \
          || ((tmp_port < 1 || tmp_port > 65535)); then
          msg::error "port [%s] is not a valid TCP port.\n" \
            "${tmp_port}"
          usage
          return 2
        fi
        g_port="${tmp_port}"
        msg::debug "port=%s\n" "${g_port}"
        shift 2
        continue
        ;;

      ########## --quiet ############################################
      '-q' | '--quiet')
        msg::enable_quiet
        shift
        continue
        ;;

      ########## --verbose ##########################################
      '-v' | '--verbose')
        msg::enable_verbose
        shift
        continue
        ;;

      ########## --trace ############################################
      '-x' | '--trace')
        msg::enable_tracing
        shift
        continue
        ;;

      ########## -- #################################################
      '--')
        shift
        break
        ;;

      ########## * ##################################################
      *)
        msg::arg_error "invalid option [%s].\n" "${1}"
        usage
        return 2
        ;;

    esac
  done

  msg::debug "%s completed successfully.\n" "${FUNCNAME[0]}"
}

#####################################################################
## Checks required tool.
## Globals:
##  REQUIRED_TOOLS
## Arguments:
##  None
## Returns:
##   0 if okay, something else if fails.
#####################################################################
check_required_tool() {
  msg::debug "entering %s:%s\n" "${FUNCNAME[0]}" "${LINENO}"

  local tool
  for tool in "${REQUIRED_TOOLS[@]}"; do

    if ! os::is_installed "${tool}"; then
      msg::warn "Missing a required tool [%s].\n" "${tool}"
      return 127
    fi

  done

}

#####################################################################
## Builds the params._meta envelope required by every Modern Era
## (2026-07-28 spec) stateless request.
## Globals:
##  MCP_PROTOCOL_VERSION
##  META_CLIENT_CAPABILITIES_KEY
##  META_PROTOCOL_VERSION_KEY
## Arguments:
##  None
## Outputs:
##  The `"_meta":{...}` JSON fragment on stdout.
#####################################################################
meta_json() {
  printf '"_meta":{"%s":"%s","%s":{}}' \
    "${META_PROTOCOL_VERSION_KEY}" \
    "${MCP_PROTOCOL_VERSION}" \
    "${META_CLIENT_CAPABILITIES_KEY}"
}

#####################################################################
## Builds the JSON-RPC request body for a `tools/list` call.
## Arguments:
##  None
## Outputs:
##  The JSON request body on stdout.
#####################################################################
tools_list_body() {
  local meta
  meta="$(meta_json)" || return
  printf '{"jsonrpc":"2.0","id":1,"method":"tools/list",'
  printf '"params":{%s}}' "${meta}"
}

#####################################################################
## Returns the sample arguments used to demonstrate a tool.
## Arguments:
##  1: tool name
## Outputs:
##  The JSON arguments object on stdout.
## Returns:
##   0 if the tool is known; something else if not.
#####################################################################
tool_sample_args() {
  local name="${1}"

  case "${name}" in
    add) printf '{"a":2,"b":3}' ;;
    subtract) printf '{"a":10,"b":4}' ;;
    multiply) printf '{"a":3,"b":7}' ;;
    divide) printf '{"a":15,"b":4}' ;;
    power) printf '{"a":2,"b":8}' ;;
    nth_root) printf '{"a":27,"b":3}' ;;
    modulo) printf '{"a":17,"b":5}' ;;
    floor_divide) printf '{"a":17,"b":5}' ;;
    sqrt) printf '{"a":16}' ;;
    absolute) printf '{"a":-42}' ;;
    floor) printf '{"a":3.7}' ;;
    ceil) printf '{"a":3.2}' ;;
    log10) printf '{"a":1000}' ;;
    ln) printf '{"a":2.718281828}' ;;
    exp) printf '{"a":1}' ;;
    round_number) printf '{"a":3.14159,"decimals":2}' ;;
    *)
      msg::error "no sample arguments defined for tool [%s].\n" \
        "${name}"
      return 1
      ;;
  esac
}

#####################################################################
## Builds the JSON-RPC request body for a `tools/call` call.
## Arguments:
##  1: JSON-RPC request id
##  2: tool name
##  3: JSON arguments object
## Outputs:
##  The JSON request body on stdout.
#####################################################################
tool_call_body() {
  local id="${1}"
  local name="${2}"
  local args="${3}"
  local meta
  meta="$(meta_json)" || return
  printf '{"jsonrpc":"2.0","id":%s,"method":"tools/call",' "${id}"
  printf '"params":{"name":"%s","arguments":%s,%s}}' \
    "${name}" "${args}" "${meta}"
}

#####################################################################
## Builds the JSON-RPC request body for a `server/discover` call.
## Arguments:
##  None
## Outputs:
##  The JSON request body on stdout.
#####################################################################
discover_body() {
  local meta
  meta="$(meta_json)" || return
  printf '{"jsonrpc":"2.0","id":3,"method":"server/discover",'
  printf '"params":{%s}}' "${meta}"
}

#####################################################################
## Builds the health-check URL for a host and port.
## Globals:
##  HEALTH_ENDPOINT_PATH
## Arguments:
##  1: host
##  2: port
## Outputs:
##  The health-check URL on stdout.
#####################################################################
health_url() {
  printf 'http://%s:%s%s' "${1}" "${2}" "${HEALTH_ENDPOINT_PATH}"
}

#####################################################################
## Builds the MCP endpoint URL for a host and port.
## Globals:
##  MCP_ENDPOINT_PATH
## Arguments:
##  1: host
##  2: port
## Outputs:
##  The MCP endpoint URL on stdout.
#####################################################################
mcp_url() {
  printf 'http://%s:%s%s' "${1}" "${2}" "${MCP_ENDPOINT_PATH}"
}

#####################################################################
## Sends a health-check GET request and prints the response.
## Arguments:
##  1: host
##  2: port
## Returns:
##   0 if the request was sent; something else if curl failed.
#####################################################################
check_health() {
  local host="${1}"
  local port="${2}"
  local url
  url="$(health_url "${host}" "${port}")" || return

  local -a opts=(-i -sS)
  if msg::is_verbose; then
    opts+=(-v)
  fi

  msg::info "GET %s\n" "${url}"

  if ! curl "${opts[@]}" "${url}"; then
    msg::error "health check request failed.\n"
    return 1
  fi
  printf "\n\n"
}

#####################################################################
## Sends a JSON-RPC POST request to the MCP endpoint and prints the
## response. In verbose mode, curl also traces the request/response
## headers, and the request body is printed since curl's own trace
## never includes the outgoing body.
## Arguments:
##  1: host
##  2: port
##  3: JSON request body
##  4+: extra curl arguments, such as extra "-H" headers
## Returns:
##   0 if the request was sent; something else if curl failed.
#####################################################################
post_mcp_request() {
  local host="${1}"
  local port="${2}"
  local body="${3}"
  shift 3
  local url
  url="$(mcp_url "${host}" "${port}")" || return

  local -a opts=(-i -sS -X POST)
  if msg::is_verbose; then
    opts+=(-v)
    msg::info "Request body:\n%s\n" "${body}"
  fi

  curl "${opts[@]}" "${url}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    "${@}" \
    -d "${body}"
}

#####################################################################
## Sends a `tools/list` request and prints the response.
## Globals:
##  MCP_ENDPOINT_PATH
## Arguments:
##  1: host
##  2: port
## Returns:
##   0 if the request was sent; something else if curl failed.
#####################################################################
list_tools() {
  local host="${1}"
  local port="${2}"
  local body
  body="$(tools_list_body)" || return

  msg::info "POST tools/list -> %s:%s%s\n" \
    "${host}" "${port}" "${MCP_ENDPOINT_PATH}"

  if ! post_mcp_request "${host}" "${port}" "${body}"; then
    msg::error "tools/list request failed.\n"
    return 1
  fi
  printf "\n\n"
}

#####################################################################
## Sends a `tools/call` request for one tool and prints the
## response.
## Globals:
##  MCP_ENDPOINT_PATH
## Arguments:
##  1: host
##  2: port
##  3: JSON-RPC request id
##  4: tool name
## Returns:
##   0 if the request was sent; something else if curl failed.
#####################################################################
call_tool() {
  local host="${1}"
  local port="${2}"
  local id="${3}"
  local name="${4}"
  local args
  args="$(tool_sample_args "${name}")" || return
  local body
  body="$(tool_call_body "${id}" "${name}" "${args}")" || return

  msg::info "POST tools/call (%s) -> %s:%s%s\n" \
    "${name}" "${host}" "${port}" "${MCP_ENDPOINT_PATH}"

  if ! post_mcp_request "${host}" "${port}" "${body}"; then
    msg::error "tools/call request for [%s] failed.\n" "${name}"
    return 1
  fi
  printf "\n\n"
}

#####################################################################
## Sends a `server/discover` request and prints the response. The
## server requires the "mcp-method" header to match the request
## body's method, alongside "mcp-protocol-version".
## Globals:
##  MCP_ENDPOINT_PATH
##  MCP_PROTOCOL_VERSION
## Arguments:
##  1: host
##  2: port
## Returns:
##   0 if the request was sent; something else if curl failed.
#####################################################################
discover_server() {
  local host="${1}"
  local port="${2}"
  local body
  body="$(discover_body)" || return

  msg::info "POST server/discover -> %s:%s%s\n" \
    "${host}" "${port}" "${MCP_ENDPOINT_PATH}"

  if ! post_mcp_request "${host}" "${port}" "${body}" \
    -H "mcp-protocol-version: ${MCP_PROTOCOL_VERSION}" \
    -H "mcp-method: server/discover"; then
    msg::error "server/discover request failed.\n"
    return 1
  fi
  printf "\n\n"
}

#####################################################################
## Catches and handles signals defined in the "trap" command.
## Globals:
##  FUNCNAME
##  LINENO
##  FUNCNAME : Bash array for function names in the stack.
##  ERR  : trap any non-zero exit status
##  EXIT : trap sigspec for signal   (0) On exit from shell
##  HUP  : trap sigspec for SIGHUP   (1) Clean tidyup
##  INT  : trap sigspec for SIGINT   (2) Interrupt (CTRL-C)
##  QUIT : trap sigspec for SIGQUIT  (3) Quit
##  TERM : trap sigspec for SIGTERM (15) Terminate
## Arguments:
##  None.
## Exits:
##   exit status code based on signal being handled.
#####################################################################
signal_handler() {
  local -r rc=$?
  msg::debug "entering %s:%s\n" "${FUNCNAME[0]}" "${LINENO}"

  local -r signal="${1:-}"
  msg::debug "handling signal [%s].\n" "${signal}"

  # disables following signals to avoid looping
  trap - ERR
  trap - EXIT
  trap - HUP  # signal 1
  trap - INT  # signal 2
  trap - QUIT # signal 3
  trap - TERM # signal 15

  local exit_code

  case "${signal}" in
    HUP)
      msg::warn \
        "the shell controlling terminal was hung: %s\n" \
       "SIGHUP"
      exit_code=129 # 1+128
      ;;
    INT)
      msg::warn \
        "execution interrupted by the user (control-c): %s\n" \
        "SIGINT"
      exit_code=130 # 2+128
      ;;
    QUIT)
      msg::warn \
        "execution interrupted due to unexpected event: %s\n" \
        "SIGQUIT"
      exit_code=131 # 3+128
      ;;
    TERM)
      msg::warn "someone asked the current execution to stop: %s\n" \
        "SIGTERM"
      exit_code=143 # 15+128
      ;;
    ERR)
      msg::warn "execution interrupted by Bash ERR signal: %s\n" \
        "SIGERR"
      exit_code=${rc}
      ;;
    EXIT)
      msg::debug "handling %s event\n" "SIGEXIT"
      ;;
    *)
      msg::warn "unexpected signal: %s\n" "${signal}"
      ;;
  esac

  if [[ -n "${exit_code:-}" ]]; then
    exit "${exit_code}"
  fi

  exit
}

#####################################################################
## Main function.
## Globals:
##  IS_DEBUGGER
##  PRG
##  REQUIRED_TOOLS
##  TOOL_NAMES
##  g_host
##  g_port
## Arguments:
##  Bash shell CLI input arguments.
## Returns:
##   0 if all requests were sent; something else if any failed.
#####################################################################
main() {
  # sanity: start main function stack with a clean global state.
  reset_globals

  # --------------- >>> Check Required Tools <<< --------------------

  check_required_tool || return

  # --------------- >>> Parse CLI Input Arguments <<< ---------------

  parse_options "$@" || return

  msg::debug "Bash version: %s\n" "${BASH_VERSION}"
  msg::info "Running %s\n" "${PRG}"

  # --------------- >>>  Basic Shell Init / Trap Handlers <<< -------

  # bassupport-pro debugger crashes if following code is run
  if [[ "${IS_DEBUGGER}" != TRUE ]]; then
    sh::init || return
    local -ar signals=("ERR" "HUP" "INT" "TERM" "QUIT" "EXIT")
    sh::curry_trap_command "signal_handler" "${signals[*]}" || return
  fi

  # --------------- >>> Print Script State  <<<  --------------------

  msg::debug "[%s]: %s\n" "IS_DEBUGGER" "${IS_DEBUGGER}"
  msg::debug "[%s]: %s\n" "PRG" "${PRG}"
  msg::debug "[%s]: %s\n" "g_host" "${g_host}"
  msg::debug "[%s]: %s\n" "g_port" "${g_port}"

  # --------------- >>> Exercise the MCP Server  <<< -----------------

  local -i failures=0
  local -i request_id=10
  local -i total=$((${#TOOL_NAMES[@]} + 3))

  check_health "${g_host}" "${g_port}" \
    || failures=$((failures + 1))
  list_tools "${g_host}" "${g_port}" \
    || failures=$((failures + 1))

  local tool_name
  for tool_name in "${TOOL_NAMES[@]}"; do
    request_id=$((request_id + 1))
    call_tool "${g_host}" "${g_port}" "${request_id}" \
      "${tool_name}" \
      || failures=$((failures + 1))
  done

  discover_server "${g_host}" "${g_port}" \
    || failures=$((failures + 1))

  if ((failures > 0)); then
    msg::error "%d of %d MCP requests failed.\n" \
      "${failures}" "${total}"
    return 1
  fi

  msg::info "all %d MCP requests completed successfully.\n" \
    "${total}"
}

#####################################################################
## ------------------------------------------------------------------
## -------------------- >>> Main Program Body <<< -------------------
## ------------------------------------------------------------------

if ! main "$@"; then
  printf "\n%s failed!\n" "${PRG}" >&2
  exit 1
fi

printf "done\n"
