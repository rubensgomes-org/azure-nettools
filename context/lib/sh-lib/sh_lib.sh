#!/usr/bin/env bash
################################################################################
##
## Shell script library of shell utility functions.
##
## Requirements:
##   - GNU Bash 3.2 or higher.

# only source it once
[[ -n "${SH_LIB_SOURCED:-}" ]] && return
readonly SH_LIB_SOURCED=0

# -------------------- >>> Import libraries <<< --------------------------------

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/msg_lib.sh"

## CONSTANTS ###################################################################
# default timezone
[[ -z "${DEFAULT_TZ:-}" ]] && readonly DEFAULT_TZ="America/Chicago"

# minimum required Bash release version is 3.2.X
[[ -z "${BASH_MAJOR_VERSION:-}" ]] && readonly BASH_MAJOR_VERSION="3"
[[ -z "${BASH_MINOR_VERSION:-}" ]] && readonly BASH_MINOR_VERSION="2"

# VERY BASIC TOOLS
declare -a BASIC_TOOLS=(
  "awk"
  "date"
  "grep"
  "sed"
)

## GLOBAL VARIABLES ############################################################

# global variable changed inside the "sh::set_g_split_by_arr" function to hold the
# splitted list of delimiter separated trimmed words
declare -a g_split_by_arr=()

################################################################################
## Checks if Bash shell version is supported.
## Globals:
##   None
## Arguments:
##   None
## Returns
##  0 if okay; something else if failed
################################################################################
sh::check_version() {
  [[ -z "${BASH_VERSINFO:-}" ]] && {
    msg::error "Not a BASH shell. Cannot find [%s].\n" "BASH_VERSION"
    return 2
  }

  local version=
  version="$(sh::version)" || msg::die "Not a Bash shell."

  msg::debug "checking Bash version [%s].\n" "${version}"

  local -i major=${BASH_VERSINFO[0]}
  local -i minor=${BASH_VERSINFO[1]}

  if [[ ${major} -lt ${BASH_MAJOR_VERSION} ]]; then
    msg::error "Bash version [%s] at [%s] NOT supported.\n" \
      "${version}" "${BASH}"
    msg::warn "Bash major version must be at least [%s].\n" \
      "${BASH_MAJOR_VERSION}"
    msg::warn "Bash minimum version required must be [%s.%s].\n" \
      "${BASH_MAJOR_VERSION}" "${BASH_MINOR_VERSION}"
    return 1
  elif [[ ${major} == "${BASH_MAJOR_VERSION}" ]]; then

    if [[ ${minor} -lt ${BASH_MINOR_VERSION} ]]; then
      msg::error "Bash version [%s] at [%s] NOT supported.\n" \
        "${version}" "${BASH}"
      msg::warn "Bash minor version must be at least [%s].\n" \
        "${BASH_MINOR_VERSION}"
      msg::warn "Bash minimum version required must be [%s.%s].\n" \
        "${BASH_MAJOR_VERSION}" "${BASH_MINOR_VERSION}"
      return 1
    fi

  fi

  msg::debug "Bash version [%s] supported.\n" "${version}"
}
# protect this function from being overridden
readonly -f sh::check_version

################################################################################
## Performs function translation (known as currying in Math) of a function
## with multiple arguments to multiple functions of single argument. This is
## required to support passing interrupted signal to the trap command function.
## Globals:
##   None
## Arguments:
##   1 [required] : trap command function name found in current scope
##   2.[required] : list of signals from sigspec to handle
## Returns
##  0 if okay; something else if failed
################################################################################
sh::curry_trap_command() {
  [[ ${#} -ne 2 ]] && {
    msg::arg_error "invalid number of argument(s)."
    return 2
  }

  [[ -z "${1:-}" || -z "${1//[[:space:]]/}" ]] && {
    msg::arg_error "missing [%s].\n" "trap command function"
    return 2
  }

  local -r trap_cmd="${1}"

  [[ -z "${2:-}" || -z "${2//[[:space:]]/}" ]] && {
    msg::arg_error "missing [%s].\n" "signal(s) to trap"
    return 2
  }

  local -a signal_arr=()
  IFS=' ' read -r -a signal_arr <<<"${2}"

  local signal
  for signal in "${signal_arr[@]}"; do

    # except for EXIT all other signals must be checked for validility
    if [[ "${signal}" != EXIT && "${signal}" != ERR ]]; then
      (
        trap -l | grep "${signal}"
        [[ ${PIPESTATUS[0]} == 0 && ${PIPESTATUS[1]} == 0 ]]
      ) >/dev/null || {
        msg::error "trap signal [%s] NOT supported.\n" "${signal}"
        return 1
      }
    fi

    msg::debug "trapping signal [%s] using trap handler cmd [%s]\n" \
      "${signal}" "${trap_cmd}"

    # shellcheck disable=SC2064
    if ! trap "${trap_cmd} ${signal}" "${signal}"; then
      msg::error "failed to use function [%s] to trap signal [%s].\n" \
        "${trap_cmd}" "${signal}"
      return 1
    fi

  done

  msg::debug "done currying trap signal handler function"
}
# protect this function from being overridden
readonly -f sh::curry_trap_command

################################################################################
## Calculates elapsed time rounded to lowest minutes from the initial
## timestamp (date +%s) value of start_time. It is assumed that start_time is
## initialized at start of the script.
## Globals:
##  None
## Arguments:
##   1 [required] : start_time timestamp (e.g., date +%s).
## Returns:
##   0 if okay; something else if it fails
## Outputs:
##  elapsed time in minutes.
################################################################################
sh::elapsed_time_min() {
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # ATTENTION: This function writes its result to the stdout. Therefore,
  # any code in this function should be carefully examined to not write to
  # stdout, which corrupts the result and breaks any dependent code.
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  [[ ${#} -ne 1 ]] && {
    msg::arg_error "invalid number of argument(s)."
    return 2
  }

  [[ -z "${1:-}" || -z "${1//[[:space:]]/}" ]] && {
    msg::error "missing start_time timestamp."
    return 2
  }

  [[ "${1}" =~ ^[0-9]+$ ]] || {
    msg::error "start_time timestamp [%s] not valid.\n" "${1}"
    return 2
  }

  local -ir start_time="${1}"
  local -ir time_now="$(date +%s)"
  local -i time_min=0
  ((time_min = (time_now - start_time) / 60))

  msg::debug "time_min=%s\n" "${time_min}"
  echo "${time_min}"
}
# protect this function from being overridden
readonly -f sh::elapsed_time_min

################################################################################
## Configures shell options, unset aliases and other initialization.
## Globals:
##   DEFAULT_TZ : default timezone.
##   TZ         : environment variable used by time/date utilities.
## Arguments:
##   None.
## Returns:
##   0 always.
################################################################################
sh::init() {

  (sh::check_version) || msg::die "Unsupported Bash!"

  # ensure no aliases are used during the execution of script
  \unalias -a

  set -o errexit  # abort on nonzero exitstatus
  set -o nounset  # abort on unbound variable
  set -o pipefail # don't hide errors within pipes

  # needs to have TZ to avoid issues with zip/unzip commands
  [[ -z "${TZ:-}" ]] && export TZ="${DEFAULT_TZ}"

  # check basic tools: awk, date, grep, sed
  local cmd=
  for cmd in "${BASIC_TOOLS[@]}" ; do
    msg::debug "checking if basic cmd [%s] is installed.\n" "${cmd}"

    if ! (command -v "${cmd}" >/dev/null); then
      msg::error "basic command [%s] not found in your PATH [%s].\n" \
        "${cmd}" "${PATH}"
      return 1
    fi

  done

  return 0
}
# protect this function from being overridden
readonly -f sh::init

################################################################################
## Checks if given parameter is a valid URL
## !!! ATTENTION THIS IS A VERY BASIC CHECK !!!
## Globals:
##  None
## Arguments:
##   1 [require] URL to check.
## Returns:
##   0 if okay; something else if fails.
################################################################################
sh::is_valid_url() {
  [[ ${#} -ne 1 ]] && {
    msg::arg_error "invalid number of arguments"
    return 2
  }

  [[ -z "${1:-}" || -z "${1//[[:space:]]/}" ]] && {
    msg::arg_error "missing [%s].\n" "URL"
    return 2
  }

  local -r regex='^(https?|s3):\/\/[-a-zA-Z0-9._]+(:[0-9]+)?(/.*)?'
  [[ ! "${1}" =~ ${regex} ]] && {
    msg::warn "invalid URL [%s].\n" "${1}"
    return 2
  }

  msg::debug "url [%s] is valid.\n" "${1}"
}
# protect this function from being overridden
readonly -f sh::is_valid_url

################################################################################
## Prints the maximum number of characters allowed to be used in the current
## shell script parameters or arguments to commands.
## Globals
##   ARG_MAX
## Argumentss
##  None.
## Returns:
##   0 if okay; something else if fails.
## Outputs:
##   Maximum number of characters allowed in shell command arguments.
################################################################################
sh::max_arg_length() {
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # ATTENTION: This function writes its result to the stdout. Therefore,
  # any code in this function should be carefully examined to not write to
  # stdout, which corrupts the result and breaks any dependent code.
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  local max_arg_length=

  if ! max_arg_length="$(
    getconf -a | grep "^ARG_MAX" | awk '{print $2}'
    [[ ${PIPESTATUS[0]} == 0 &&
      ${PIPESTATUS[1]} == 0 &&
      ${PIPESTATUS[2]} == 0 ]]
  )"; then
    msg::error "failed to determine max shell command parameter length."
    return 1
  fi

  echo "${max_arg_length}"
}
# protect this function from being overridden
readonly -f sh::max_arg_length

################################################################################
## Given a delimiter separator character and a list of words, splits the list
## of delimited separated blank space trimmed words. It stores the result in
## a global "g_split_by_arr"
##
## ATTENTION DUE TO CONSTRAINT OF WRITING ARRAY CONTAINING SPACES TO STDOUT,
##           A GLOBAL VARIABLE "g_split_by_arr" IS USED TO STORE THE RESULT.
## Globals:
##  g_split_by_arr
## Arguments:
##   1 [required] : delimiter character (must not be letter or digit)
##   2 [required] : list of words separated by that delimiter
# # Returns:
##   0 if okay; something else if it fails
################################################################################
sh::set_g_split_by_arr() {
  [[ ${#} -lt 2 ]] && {
    msg::arg_error "invalid number of argument(s)."
    return 2
  }

  [[ -z "${1:-}" || -z "${1//[[:space:]]/}" ]] && {
    msg::error "missing delimiter."
    return 2
  }

  [[ ${#1} -ne 1 ]] && {
    msg::error "delimiter [%s] must be a single character.\n" "${1}"
    return 2
  }

  [[ "${1}" =~ [0-9a-zA-Z] ]] && {
    msg::error "delimiter [%s] not valid.\n" "${1}"
    return 2
  }

  local -r delimiter="${1}"

  # shift one position to treat the rest of arguments as an array.
  shift

  [[ ${#@} -eq 0 ]] && {
    msg::error "missing list of delimiter separated words."
    return 2
  }

  local -r list="${*}"

 local -a arr=()
  IFS="${delimiter}" read -ra arr <<< "${list}"
  g_split_by_arr=()

  local word item

  for word in "${arr[@]}"; do
    item="$(sh::trim_space "${word}")" || return

    if [[ -z "${item:-}" || -z "${item//[[:blank:]]/:-}" ]]; then
      g_split_by_arr+=("")
    elif [[ -n "${item:-}" ]]; then
      g_split_by_arr+=("${item}")
    else
      msg::error "unexpected item [%s].\n" "${item}"
      return 1
    fi

  done

  msg::debug "splitted delimiter separated words: %s\n" "${g_split_by_arr[*]}"
}
# protect this function from being overridden
readonly -f sh::set_g_split_by_arr

################################################################################
## Remove any blank space from the beginning and ending of given argument.  For
## example, if given "   abc    def   ", the output is "abc    def"
##
## ATTENTION: Newline (\n) character is removed from the given input argument.
##
## Arguments:
##   1 [optional]: argument to remove spaces.
## Returns:
##   0 if okay; something else if it fails.
## Outputs:
##   Writes to stdout the removed blank argument.
################################################################################
sh::trim_space() {
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # ATTENTION: This function writes its result to the stdout. Therefore,
  # any code in this function should be carefully examined to not write to
  # stdout, which corrupts the result and breaks any dependent code.
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  [[ ${#} -eq 0 || -z "${1:-}" ]] && return 0

  [[ ${#} -ne 1 ]] && {
    msg::arg_error "invalid number of argument(s)."
    return 2
  }

  # code pulled from google search: author could not be identified.
  local arg="${1}"

  local out1 out2
  out1="$(printf "%s" "${arg}" | tr -d '\n' | sed -e 's/^[[:blank:]]*//')"
  out2="$(printf "%s" "${out1}" | sed -e 's/[[:space:]]*$//')"

  printf "%s" "${out2}"
}
# protect this function from being overridden
readonly -f sh::trim_space

################################################################################
## Prints Bash version: major.feature.patch
## Arguments:
##  none
## Returns:
##   0 if okay; something else if it fails.
## Outputs:
##   Writes to stdout the Bash version
################################################################################
sh::version() {
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # ATTENTION: This function writes its result to the stdout. Therefore,
  # any code in this function should be carefully examined to not write to
  # stdout, which corrupts the result and breaks any dependent code.
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  [[ -z "${BASH_VERSINFO:-}" ]] && {
    msg::error "Not a BASH shell. Cannot find [%s].\n" "BASH_VERSION"
    return 1
  }

  echo "${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}.${BASH_VERSINFO[2]}"
}
# protect this function from being overridden
readonly -f sh::version
