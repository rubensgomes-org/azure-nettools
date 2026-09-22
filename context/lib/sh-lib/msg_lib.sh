#!/usr/bin/env bash
################################################################################
##
## Shell script library of functions for printing messages to stderr.
##
## ATTENTION: logging messages are ptinted to stderr, and NOT stdout because
##            the stdout is sometimes used to print a function result.
##
## Requirements:
##   - GNU Bash 3.2 or higher.

# only source it once
[[ -n "${MSG_LIB_SOURCED:-}" ]] && return
readonly MSG_LIB_SOURCED=0

## CONSTANTS ###################################################################
# boolean
[[ -z "${TRUE:-}" ]] && readonly TRUE=0
[[ -z "${FALSE:-}" ]] && readonly FALSE=1

# standard text
# constant heading for debug messages
readonly MSG_DEBUG_TXT="DEBUG "
# constant heading for error messages
readonly MSG_ERROR_TXT="ERROR "
# constant heading for fatal messages
readonly MSG_FATAL_TXT="FATAL "
# constant heading for info messages
readonly MSG_WARN_TXT="WARN  "
# constant heading for info messages
readonly MSG_INFO_TXT="INFO  "
# constant heading for invalid argument.
readonly MSG_INV_ARG_ERR="invalid argument(s): "
# constant heading for missing required argument.
readonly MSG_MISSING_ARG_ERR="missing required argument(s)"

## PRIVATE (ONLY THIS FILE) GLOBAL VARIABLES ###################################
# flag to print debug messages. Based on "-d" CLI option.
declare _DEBUG=FALSE
# flag to print commands tracing. Based on "-x" CLI option.
declare _TRACING=FALSE

# flag to disable all messages except errors
declare _QUIET=FALSE
## flag to add extra details in the messages.
declare _VERBOSE=FALSE

################################################################################
## Prints warn message.
## Globals:
##   BASH_LINENO  : Bash variable for current line number.
##   FUNCNAME     : Bash array for function names in the stack.
##   MSG_INFO_TXT : constant heading for info messages
## Arguments:
##   1 [optional] : message to print using "echo"
##   [or]
##   1 [optional] : format used by "printf" format
##   2 [optional] : arguments used by "printf" arguments
## Returns:
##   0 if okay; something else if fails.
## Output:
##  warn messages
################################################################################
msg::warn() {
  ( msg::is_quiet ) && return 0

  # nothing to print simply return
  [[ -z "${1:-}" ]] && return 0

  # Since the first element of the input array may contain a "printf" format
  # parameter, we must preserve that array's first element.  Therefore, we
  # need merge to merge by prefixing the constant below with the current
  # array first element.  Then, pass in the merged array.
  local -r timestamp="$(msg::_timestamp)"
  local heading

  if (msg::is_verbose); then
    heading="${timestamp} ${MSG_WARN_TXT} [${FUNCNAME[1]}:${BASH_LINENO[0]}]"
  else
    heading="${timestamp} ${MSG_WARN_TXT} "
  fi

  local -a merged_arr=("${heading} ${@}")
  msg::_msg "${merged_arr[@]}"
}
# protect this function from being overridden
readonly -f msg::warn

################################################################################
## Prints info message.
## Globals:
##   BASH_LINENO  : Bash variable for current line number.
##   FUNCNAME     : Bash array for function names in the stack.
##   MSG_INFO_TXT : constant heading for info messages
## Arguments:
##   1 [optional] : message to print using "echo"
##   [or]
##   1 [optional] : format used by "printf" format
##   2 [optional] : arguments used by "printf" arguments
## Returns:
##   0 if okay; something else if fails.
## Output:
##  info meessage.
################################################################################
msg::info() {
  ( msg::is_quiet ) && return 0

  # nothing to print simply return
  [[ -z "${1:-}" ]] && return 0

  # Since the first element of the input array may contain a "printf" format
  # parameter, we must preserve that array's first element.  Therefore, we
  # need merge to merge by prefixing the constant below with the current
  # array first element.  Then, pass in the merged array.
  local -r timestamp="$(msg::_timestamp)"
  local heading

  if (msg::is_verbose); then
    heading="${timestamp} ${MSG_INFO_TXT} [${FUNCNAME[1]}:${BASH_LINENO[0]}]"
  else
    heading="${timestamp} ${MSG_INFO_TXT} "
  fi

  local -a merged_arr=("${heading} ${@}")
  msg::_msg "${merged_arr[@]}"
}
# protect this function from being overridden
readonly -f msg::info

################################################################################
## Prints debug message.
## Globals:
##   BASH_LINENO    : Bash variable for current line number.
##   FUNCNAME       : Bash array for function names in the stack.
##    MSG_DEBUG_TXT : constant heading for debug messages.
## Arguments:
##   1 [optional] : message to print using "echo"
##   [or]
##   1 [optional] : format used by "printf" format
##   2 [optional] : arguments used by "printf" arguments
## Returns:
##   0 if okay; something else if fails.
## Output:
##  debug meessage.
################################################################################
msg::debug() {
  ( msg::is_quiet || ! msg::is_debug ) && return 0

  # nothing to print simply return
  [[ -z "${1:-}" ]] && return 0

  # Since the first element of the input array may contain a "printf" format
  # parameter, we must preserve that array's first element.  Therefore, we
  # need merge to merge by prefixing the constant below with the current
  # array first element.  Then, pass in the merged array.
  local -r timestamp="$(msg::_timestamp)"
  local heading

  if (msg::is_verbose); then
    heading="${timestamp} ${MSG_DEBUG_TXT} [${FUNCNAME[1]}:${BASH_LINENO[0]}]"
  else
    heading="${timestamp} ${MSG_DEBUG_TXT} "
  fi

  local -a merged_arr=("${heading} ${@}")
  msg::_msg "${merged_arr[@]}"
}
# protect this function from being overridden
readonly -f msg::debug

################################################################################
## Prints error message.
## Globals:
##   BASH_LINENO   : Bash variable for current line number.
##   FUNCNAME      : Bash array for function names in the stack.
##   MSG_ERROR_TXT : constant heading for error messages.
## Arguments:
##   1 [optional] : message to print using "echo"
##   [or]
##   1 [optional] : format used by "printf" format
##   2 [optional] : arguments used by "printf" arguments
## Returns:
##   0 if okay; something else if fails.
## Output:
##  error meessage.
################################################################################
msg::error() {
  # nothing to print simply return
  [[ -z "${1:-}" ]] && return 0

  # Since the first element of the input array may contain a "printf" format
  # parameter, we must preserve that array's first element.  Therefore, we
  # need to merge by prefixing the constant below with the current
  # array first element.  Then, pass in the merged array.
  local -r timestamp="$(msg::_timestamp)"
  local heading

  if (msg::is_verbose); then
    heading="${timestamp} ${MSG_ERROR_TXT} [${FUNCNAME[1]}:${BASH_LINENO[0]}]"
  else
    heading="${timestamp} ${MSG_ERROR_TXT} "
  fi

  local -a merged_arr=("${heading} ${@}")
  msg::_msg "${merged_arr[@]}"
}
# protect this function from being overridden
readonly -f msg::error

################################################################################
## Same as msg::error(), except it requires an argument.
## Globals:
##   BASH_LINENO         : Bash variable for current line number.
##   FUNCNAME            : Bash array for function names in the stack.
##   MSG_ERROR_TXT       : constant heading for error messages
##   MSG_INV_ARG_ERR     : constant heading for invalid argument.
##   MSG_MISSING_ARG_ERR : constant heading for missing required argument.
## Arguments:
##   1 [required] : message to print to stderr.
##   [or]
##   1 [required] : format used by "printf" format
##   2 [optional] : arguments used by "printf" arguments
## Returns:
##   0 if okay; something else if fails.
## Output:
##  argument error meessage.
################################################################################
msg::arg_error() {
  [[ ${#} -eq 0 || -z "${1:-}" ]] &&
    msg::error "${MSG_MISSING_ARG_ERR} [${FUNCNAME[1]}:${BASH_LINENO[0]}]" &&
    return 2

  # Since the first element of the input array may contain a "printf" format
  # parameter, we must preserve that array's first element.  Therefore, we
  # need to merge by prefixing the constant below with the current
  # array first element.  Then, pass in the merged array.
  local -r timestamp="$(msg::_timestamp)"
  local heading

  if (msg::is_verbose); then
    heading="${timestamp} ${MSG_ERROR_TXT} [${FUNCNAME[1]}:${BASH_LINENO[0]}] ${MSG_INV_ARG_ERR}"
  else
    heading="${timestamp} ${MSG_ERROR_TXT}  ${MSG_INV_ARG_ERR}"
  fi

  local -a merged_arr=("${heading} ${@}")
  msg::_msg "${merged_arr[@]}"
}
# protect this function from being overridden
readonly -f msg::arg_error

################################################################################
## Prints fatal message. Uusually done prior to dying.
## Globals:
##   BASH_LINENO   : Bash variable for current line number.
##   FUNCNAME      : Bash array for function names in the stack.
##   MSG_FATAL_TXT : constant heading for error messages.
## Arguments:
##   1 [optional] : message to print using "echo"
##   [or]
##   1 [optional] : format used by "printf" format
##   2 [optional] : arguments used by "printf" arguments
## Returns:
##   0 if okay; something else if fails.
## Output:
##  error meessage.
################################################################################
msg::fatal() {
  # nothing to print simply return
  [[ -z "${1:-}" ]] && return 0

  # Since the first element of the input array may contain a "printf" format
  # parameter, we must preserve that array's first element.  Therefore, we
  # need to merge by prefixing the constant below with the current
  # array first element.  Then, pass in the merged array.
  local -r timestamp="$(msg::_timestamp)"
  local heading

  if (msg::is_verbose); then
    heading="${timestamp} ${MSG_FATAL_TXT} [${FUNCNAME[1]}:${BASH_LINENO[0]}]"
  else
    heading="${timestamp} ${MSG_FATAL_TXT} "
  fi

  local -a merged_arr=("${heading} ${@}")
  msg::_msg "${merged_arr[@]}"
}
# protect this function from being overridden
readonly -f msg::fatal

################################################################################
## Enables debug mode.
## Globals:
##   _DEBUG : flag to print debug messages.
## Arguments:
##   None
## Returns:
##   0 always.
################################################################################
msg::enable_debug() {
  _DEBUG=TRUE
}
# protect this function from being overridden
readonly -f msg::enable_debug

################################################################################
## Disables debug mode.
## Globals:
##   _DEBUG : flag to print debug messages.
## Arguments:
##   None
## Returns:
##   0 always.
################################################################################
msg::disable_debug() {
  _DEBUG=FALSE
}
# protect this function from being overridden
readonly -f msg::disable_debug

################################################################################
## Checks if debug is enabled.
## Globals:
##   _DEBUG : flag to print debug messages.
## Arguments:
##   None
## Returns:
##   0 if debug mode is enabled; 1, otherwise.
################################################################################
msg::is_debug() {
  [[ "${_DEBUG}" == TRUE ]]
}
# protect this function from being overridden
readonly -f msg::is_debug

################################################################################
## Enables quiet mode.
## Globals:
##  _QUIET : flag to disable all messages except errors
## Arguments:
##   None
## Returns:
##   0 always.
################################################################################
msg::enable_quiet() {
  _QUIET=TRUE
}
# protect this function from being overridden
readonly -f msg::enable_quiet

################################################################################
## Disables quiet mode.
## Globals:
##  _QUIET : flag to disable all messages except errors
## Arguments:
##   None
## Returns:
##   0 always.
################################################################################
msg::disable_quiet() {
  _QUIET=FALSE
}
# protect this function from being overridden
readonly -f msg::disable_quiet

################################################################################
## Checks if quiet is enabled.
## Globals:
##  _QUIET : flag to disable all messages except errors
## Arguments:
##   None
## Returns:
##   0 if quiet mode is enabled; 1, otherwise.
################################################################################
msg::is_quiet() {
  [[ "${_QUIET}" == TRUE ]]
}
# protect this function from being overridden
readonly -f msg::is_quiet

################################################################################
## Same as msg::error() except that it exits with an error code.
## Arguments:
##   1 [optional]: message(s) to be printed to stderr.
## Exits:
##   1 always.
################################################################################
msg::die() {
  # delegate to msg::fatal and exits with error false status.
  msg::fatal "${@}" && exit 1
} >&2 # function writes to stderr
# protect this function from being overridden
readonly -f msg::die

################################################################################
## Enable extra details in the messages.
## Globals:
##  _VERBOSE : flag to add extra details in the messages.
## Arguments:
##   None
## Returns:
##   0 always.
################################################################################
msg::enable_verbose() {
  _VERBOSE=TRUE
}
# protect this function from being overridden
readonly -f msg::enable_verbose

################################################################################
## Disables verbose printing
## Globals:
##  _VERBOSE : flag to add extra details in the messages.
## Arguments:
##   None
## Returns:
##   0 always.
################################################################################
msg::disable_verbose() {
  _VERBOSE=FALSE
}
# protect this function from being overridden
readonly -f msg::disable_verbose

################################################################################
## Checks if verbose is enabled.
## Globals:
##  _VERBOSE : flag to add extra details in the messages.
## Arguments:
##   None
## Returns:
##   0 if verbose is enabled; 1, otherwise.
################################################################################
msg::is_verbose() {
  [[ "${_VERBOSE}" == TRUE ]]
}
# protect this function from being overridden
readonly -f msg::is_verbose

################################################################################
## Enables command tracing (set -x).
## Globals:
##   _TRACING : flag to print commands tracing.
## Arguments:
##   None
## Returns:
##   0 always
################################################################################
msg::enable_tracing() {
  set -vx
  _TRACING=TRUE
}
# protect this function from being overridden
readonly -f msg::enable_tracing

################################################################################
## Disables tracing (set +x)
## Globals:
##   _TRACING : flag to print commands tracing.
## Arguments:
##   None
## Returns:
##   0 always
################################################################################
msg::disable_tracing() {
  set +vx
  _TRACING=FALSE
}
# protect this function from being overridden
readonly -f msg::disable_tracing

################################################################################
## Checks if command tracing is enabled.
## Globals:
##   _TRACING : flag to print commands tracing.
## Arguments:
##   None
## Returns:
##   0 if tracing is enabled; 1, otherwise.
################################################################################
msg::is_tracing() {
  [[ "${_TRACING}" == TRUE ]]
}
# protect this function from being overridden
readonly -f msg::is_tracing

################################################################################
## Prompts user with Y/yes or N/no question.
## Arguments:
##   None
## Returns:
##   TRUE or 0 if Y/yes; FALSE or 1 if N/no.
################################################################################
msg::yes_no() {
  local answer
  local -i retval=

  # set nocasematch option
  shopt -s nocasematch

  # forever while loop until user responds y or n
  while true; do
    echo "Do you want to continue? [y/n] "
    read -r answer
    [[ "${answer}" =~ ^y$|^yes$ ]] && retval=0 && break
    [[ "${answer}" =~ ^n$|^no$ ]] && retval=1 && break
    msg::error "invalid response [%s].\n" "${answer}"
  done

  msg::debug "response [%s].\n" "${answer}"

  # unset nocasematch option
  shopt -u nocasematch

  return ${retval}
}
# protect this function from being overridden
readonly -f msg::yes_no

################################################################################
## Supporting private function
################################################################################
msg::_msg() {
  [[ ${#} -eq 1 ]] &&
    # replace any \n by equivalent end of line break
    echo "${1//'\n'/$'\n'}" &&
    return 0

  # shellcheck disable=SC2059
  printf "${1}" "${@:2}"
} >&2 # all logs are printed to stderr
# protect this function from being overridden
readonly -f msg::_msg

################################################################################
## Supporting private function
################################################################################
msg::_timestamp() {

  if ! (command -v "date" >/dev/null); then
    # at a minimum date must be in the path
    PATH="${PATH}:/bin:/usr/bin"
  fi

  date +"%F %T"
}
# protect this function from being overridden
readonly -f msg::_timestamp
