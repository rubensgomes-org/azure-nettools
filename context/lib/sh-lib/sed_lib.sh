#!/usr/bin/env bash
################################################################################
##
## Shell script library of sed utility functions.
##
## Requirements:
##   - GNU Bash 3.2 or higher.

# only source it once
[[ -n "${SED_LIB_SOURCED:-}" ]] && return
readonly SED_LIB_SOURCED=0

# -------------------- >>> Import libraries <<< --------------------------------

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/msg_lib.sh"

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/os_lib.sh"

## CONSTANTS ###################################################################
# boolean
[[ -z "${TRUE:-}" ]] && readonly TRUE=0
[[ -z "${FALSE:-}" ]] && readonly FALSE=1

################################################################################
## Checks if sed found on the PATH is a MacOS OSX.
## Globals:
##   PIPESTATUS : Bash array to store pipeline command exit status.
## Arguments:
##   None
## Returns:
##   0 if yes;  1 if no; 2 if sed not found.
################################################################################
sed::is_mac() {
  os::is_installed "sed" || return 2
  # are we on a MacOS
  os::is_macos || return
  # MacOS sed does not support "--version"
  local version
  version="$(sed --version 2>/dev/null)" && return

  # version should be empty at this point since the MacOS sed does not have
  # --version, and the above sed command should fail on MacOS.

  # for sanity and to be absolutely sure this is NOT a GNU sed, the
  # GNU grep command should fail below.
  ! ( grep -q "GNU" <<< "${version}" )
}

################################################################################
## Checks if sed found on the PATH is a GNU sed.
## Globals:
##   PIPESTATUS : Bash array to store pipeline command exit status.
## Arguments:
##   None
## Returns:
##   0 if yes;  1 if no; 2 if sed not found.
################################################################################
sed::is_gnu() {
  os::is_installed "sed" || return 2
  # BNU supports the "--version" option.
  local version
  version="$(sed --version 2>/dev/null)" || return

  # to be absolutelly sure we do have a GNU sed, we need to check version.
  ( grep -q "GNU" <<< "${version}" )
}

################################################################################
## It does inplace "sed" replacement in the given file. I appropriately uses
## the correct "sed" syntax when running using the MacOS sed vs GNU sed.
## It runs a sed command like: "s|<regexp>|<replacement>|g".
## ATTENTION:
## 1) The character | CANNOT appear in the <regexp> at this time.
## 2) You should escape any special regex metacharecter in the <regexp>
## 3) It is using the extended regular expression syntax.
## Arguments:
##   1 [required}: path to text file
##   2 [required]: regexp for the command (e.g., s|<regexp>|<replacement>|g)
##   3 [required]: replacement text (e.g., s|<regexp>|<replacement>|g)
## Returns:
##   0 if okay; something else if fails.
################################################################################
sed::replace() {
  [[ ${#} -ne 3 ]] &&
    msg::arg_error "invalid number of argument(s)." &&
    return 2

  [[ -z "${1:-}" || -z "${1//[[:space:]]/}" ]] &&
    msg::arg_error "missing [%s].\n" "text file" &&
    return 2

  local -r txt_file="${1}"

  [[ -z "${2:-}" || -z "${2//[[:space:]]/}" ]] &&
    msg::arg_error "missing [%s].\n" "regexp" &&
    return 2

  local -r regexp="${2}"

  [[ -z "${3:-}" || -z "${3//[[:space:]]/}" ]] &&
    msg::arg_error "missing [%s].\n" "replacement" &&
    return 2

  # escape any "|" found in ${3}
  local -r replacement="${3//|/\|}"

  [[ ! -w "${txt_file}" ]] &&
    msg::error "[%s] not found or not writeable.\n" "${txt_file}" &&
    return 1

  msg::debug "checking [%s].\n" "${regexp}"

  [[ "${regexp}" =~ \| ]] &&
    msg::error "character | CANNPT be in the regexp [%s].\n" "${regexp}" &&
    msg::error "sorry, this is not supported at this time." &&
    return 1

  local -i retval
  sed::is_gnu
  retval=${?}

  local which_sed
  which_sed="$(which sed)"

  msg::debug "sed=[%s].\n" "${which_sed}"

  local -a args=()
  case "${retval}" in
  0) # GNU sed
    msg::info "running GNU sed."
    args+=("--regexp-extended")
    args+=("--in-place=.original")
    # "-e" MUST be the very last argument
    args+=("-e")
    ;;
  1) # MacOS UNIX sed
    msg::info "running MacOS sed."
    args+=("-E")
    args+=("-i")
    args+=(".original")
    # "-e" MUST be the very last argument
    args+=("-e")
    ;;
  *) # error
    msg::arg_error "[%s] not found or not supported." "sed" &&
      return 2
    ;;
  esac

  args+=("s#${regexp}#${replacement}#g")
  args+=("${txt_file}")
  msg::debug "running [%s %s].\n" "sed" "${args[*]}"
  sed "${args[@]}"
}
