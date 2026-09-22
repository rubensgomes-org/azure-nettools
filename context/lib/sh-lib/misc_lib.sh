#!/usr/bin/env bash
################################################################################
##
## Shell script library of miscellanous functions that do not fit in any of
## the other specialized libraries.
##
## Requirements:
##   - GNU Bash 3.2 or higher.

# only source it once
[[ -n "${MISC_LIB_SOURCED:-}" ]] && return
readonly MISC_LIB_SOURCED=0

# -------------------- >>> Import libraries <<< --------------------------------

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/msg_lib.sh"

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/os_lib.sh"

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/sh_lib.sh"

## CONSTANTS ###################################################################
# boolean
[[ -z "${TRUE:-}" ]] && readonly TRUE=0
[[ -z "${FALSE:-}" ]] && readonly FALSE=1

# TZ required by "unzip"
[[ -z "${DEFAULT_TZ:-}" ]] && readonly DEFAULT_TZ="America/Chicago"

################################################################################
## Writes to stdout the current Git project root folder.  You must be inside
## a Git project folder for this function to work.
## Arguments:
##  None
## Returns:
##   0 if okay; something else if fails.
## Output:
##  Writes to stdout the Git project root folder.
################################################################################
misc::git_proj_root() {
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # ATTENTION: This function writes its result to the stdout. Therefore,
  # any code in this function should be carefully examined to not write to
  # stdout, which corrupts the result and breaks any dependent code.
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  os::is_installed "git" >/dev/null || return 1

  local proj_root
  ! proj_root="$(git rev-parse --show-toplevel)" &&
    msg::error "Git project root not found in [%s].\n" "${PWD}" &&
    return 1

  echo "${proj_root}"
}

################################################################################
## A quick test to see if the given TGZ tarball file is valid.
## Arguments:
##  1 [required}: TGZ archive file
## Returns:
##   0 if okay; something else if fails.
################################################################################
misc::tgz_test() {
  [[ ${#} -ne 1 ]] &&
    msg::arg_error "invalid number of argument(s)." &&
    return 2

  [[ -z "${1:-}" || -z "${1//[[:space:]]/}" ]] &&
    msg::arg_error "missing [%s].\n" "archive" &&
    return 2

  local archive="${1}"

  [[ ! -r "${archive}" ]] &&
    msg::arg_error "[%s] not found or not readable.\n" "${archive}" &&
    return 2

  os::is_installed "tar" || return 1

  ! tar -tzf "${archive}" > /dev/null &&
    msg::error "failed to test [%s].\n" "${archive}" &&
    return 1

  return 0
}

################################################################################
## Unzips the given file to the given destination folder
## Arguments:
##  1 [required}: path of directory to unzip file to
##  2 [required}: archive file to unzip
## Returns:
##   0 if okay; something else if fails.
################################################################################
misc::unzip_file() {
  [[ ${#} -ne 2 ]] &&
    msg::arg_error "invalid number of argument(s)." &&
    return 2

  [[ -z "${1:-}" || -z "${1//[[:space:]]/}" ]] &&
    msg::arg_error "missing [%s].\n" "directory to unzipo files" &&
    return 2

  [[ -z "${2:-}" || -z "${2//[[:space:]]/}" ]] &&
    msg::arg_error "missing [%s].\n" "archive" &&
    return 2

  local folder="${1}"
  local archive="${2}"

  [[ ! -d "${folder}" ]] &&
    msg::arg_error "[%s] not a valid directory.\n" "${folder}" &&
    return 2

  [[ ! -r "${archive}" ]] &&
    msg::arg_error "[%s] not found or not readable.\n" "${archive}" &&
    return 2

  local mode
  msg::is_debug && mode="" || mode="qq"

  # ensure TZ is defined in the environment
  misc::_set_tz

  os::is_installed "unzip" || return 1

  ! unzip -u"${mode:-}" "${archive}" -d "${folder}" &&
    msg::error "failed to unzip [%s] to [%s].\n" "${archive}" "${folder}" &&
    return 1

  return 0
}

################################################################################
## Lists the given zip archive.
## Arguments:
##  1 [required}: path to zip archive file.
## Returns:
##   0 if okay; something else if fails.
################################################################################
misc::unzip_list() {
  [[ ${#} -ne 1 ]] &&
    msg::arg_error "invalid number of argument(s)." &&
    return 2

  [[ -z "${1:-}" || -z "${1//[[:space:]]/}" ]] &&
    msg::arg_error "missing [%s].\n" "archive" &&
    return 2

  local archive="${1}"

  [[ ! -r "${archive}" ]] &&
    msg::arg_error "[%s] not found or not readable.\n" "${archive}" &&
    return 2

  local mode
  msg::is_debug && mode="v" || mode="q"

  # ensure TZ is defined in the environment
  misc::_set_tz

  os::is_installed "unzip" || return 1

  ! unzip -l"${mode}" "${archive}" &&
    msg::error "failed to list [%s].\n" "${archive}" &&
    return 1

  return 0
}

################################################################################
## Tests the given zip archive.
## Arguments:
##  1 [required}: zip archive file
## Returns:
##   0 if okay; something else if fails.
################################################################################
misc::unzip_test() {
  [[ ${#} -ne 1 ]] &&
    msg::arg_error "invalid number of argument(s)." &&
    return 2

  [[ -z "${1:-}" || -z "${1//[[:space:]]/}" ]] &&
    msg::arg_error "missing [%s].\n" "archive" &&
    return 2

  local archive="${1}"

  [[ ! -r "${archive}" ]] &&
    msg::arg_error "[%s] not found or not readable.\n" "${archive}" &&
    return 2

  local mode
  msg::is_debug && mode="" || mode="qq"

  # ensure TZ is defined in the environment
  misc::_set_tz

  os::is_installed "unzip" || return 1

  ! unzip -t"${mode}" "${archive}" &&
    msg::error "failed to test [%s].\n" "${archive}" &&
    return 1

  return 0
}

################################################################################
## Supporting private function.
## Ensures that TZ is found and set in the environment.  Because unzip is
## sensitive to file created time which requires TZ to be set.
## This function ensures TZ is found and properly set in the environment.
## Globals:
## DEFAULT_TZ : TZ required by "unzip"
################################################################################
misc::_set_tz() {
  [[ -z "${TZ:-}" ]] && export TZ="${DEFAULT_TZ}"
}

################################################################################
## Parses and returns corresponding property value from properties file.  It
## assumes that at MOST ONLY 1 (ONE) property exists in the file.  If more than
## one property is found it returns an error status.
##
## Globals:
## Arguments:
##  1 [required}: fully qualified path to properties file.
##  2 [required]: property name.
## Returns:
##   0 if okay; something else if fails.
## Outputs:
##   The value of the property.
################################################################################
misc::property_value() {
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # ATTENTION: This function writes its result to the stdout. Therefore,
  # any code in this function should be carefully examined to not write to
  # stdout, which corrupts the result and breaks any dependent code.
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  [[ ${#} != 2 ]] &&
    msg::arg_error "invalid number of arguments" &&
    return 2

  [[ -z "${1:-}" || -z "${1//[[:space:]]/}" ]] &&
    msg::arg_error "missing [%s].\n" "property file" &&
    return 2

  local -r property_file="${1}"

  if [[ ! -r "${property_file}" ]]; then
    msg::error "cannot find or read file [%s].\n" "${property_file}"
    return 1
  fi

  [[ -z "${2:-}" || -z "${2//[[:space:]]/}" ]] &&
    msg::arg_error "missing [%s].\n" "property name" &&
    return 2

  local -r property_name="${2}"
  local -i nr_of_matches=

  if ! nr_of_matches="$(
    < "${property_file}" grep -c "^\s*${property_name}\s*="
  )"; then
    msg::debug "did not find property [%s] in file [%s].\n" \
      "${property_name}" "${property_file}"
    return 1
  fi

  if [[ "${nr_of_matches}" -eq 0 ]]; then
    msg::info "property [%s] not found in [%s].\n" "${property_name}" \
      "${property_file}"
    return 1
  elif [[ "${nr_of_matches}" -gt 1 ]]; then
    msg::error "multiple occurrences [%s] of property [%s] found in [%s].\n" \
      "${nr_of_matches}" "${property_name}" "${property_file}"
    return 1
  fi

  local property_value=

  if ! property_value="$(
    < "${property_file}" grep "^\s*${property_name}\s*=" | awk -F= '{print $2}'
    [[ ${PIPESTATUS[0]} == 0 && ${PIPESTATUS[1]} == 0  ]]
  )"; then
    msg::info "failed to find property [%s] in file [%s].\n" \
      "${property_name}" "${property_file}"
    return 1
  fi

  msg::debug "property [%s] value [%s] found for in file [%s].\n" \
    "${property_name}" "${property_value}" "${property_file}"
  sh::trim_space "${property_value}"
}
