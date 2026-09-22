#!/usr/bin/env bash
################################################################################
##
## Shell script library of OS related utilities.  This shell function library
## target the MacOS OS X UNIX, but should also work on other UNIX variabnes
## (e.g., Linux)
##
## Requirements:
##   - GNU Bash 3.2 or higher.

# only source it once
[[ -n "${OS_LIB_SOURCED:-}" ]] && return
readonly OS_LIB_SOURCED=0

# -------------------- >>> Import libraries <<< --------------------------------

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/msg_lib.sh"

## CONSTANTS ###################################################################
# boolean
[[ -z "${TRUE:-}" ]] && readonly TRUE=0
[[ -z "${FALSE:-}" ]] && readonly FALSE=1

################################################################################
## Display operating system information where Bash is running.
## Globals:
##   BASH_VERSION : Bash variable containing the bash version.
##   EUID         : Bash variable containing the effective user id.
##   HOME         : Bash variable containing the current user home directory.
##   HOSTNAME     : Bash variable containing the hostname.
##   HOSTTYPE     : Bash variable containing the type of machine.
##   MACHTYPE     : Bash variable containing the full machine type
##   OSTYPE       : Bash variable containing the operating system type.
##   PWD          : Bash variable containing the current working directory.
##   UID          : Bash variable containing the user ID of current user.
## Returns:
##   0 always.
################################################################################
os::info() {
  msg::info "Bash version [%s].\n" "${BASH_VERSION}"
  msg::info "Hostname [%s].\n" "${HOSTNAME}"
  msg::info "Host type [%s].\n" "${HOSTTYPE}"
  msg::info "Machine type [%s].\n" "${MACHTYPE}"
  msg::info "Operating system type [%s].\n" "${OSTYPE}"
  msg::info "Current working directory [%s].\n" "${PWD}"
  msg::info "Current user ID [%s].\n" "${UID}"
  msg::info "Current effective user ID [%s].\n" "${EUID}"
  msg::info "Current user home directory [%s].\n" "${HOME:-}"

  local user_id

  if ! user_id="$(id)"; then
    msg::error "failed to run [id] to gather user id information."
  else
    msg::info "user id:\n%s\n" "${user_id}"
  fi

  return 0
}

################################################################################
## Checks if the given GNU command is installed in PATH.
## Globals:
##   PIPESTATUS
## Arguments:
##   1 [required]: GNU command
## Returns:
##   0 if okay; something else if fails.
################################################################################
os::is_gnu_cmd() {
  [[ ${#} -ne 1 ]] \
    && msg::arg_error "invalid number of argument(s)." \
    && return 2

  [[ -z "${1:-}" || -z "${1//[[:space:]]/}" ]] \
    && msg::arg_error "missing [%s].\n" "command" \
    && return 2

  local -r gnu_cmd="${1}"
  msg::debug "checking if GNU version of cmd [%s] is installed.\n" "${gnu_cmd}"

  local cmd=
  ! cmd="$(command -v "${gnu_cmd}")" \
    && msg::arg_error "[%s] not found in the PATH.\n" "${gnu_cmd}" \
    && return 127

  [[ -z "${cmd:-}" || ! -x "${cmd}" ]] \
    && msg::arg_error "[%s] is not an executable.\n" "${cmd}" \
    && return 2

  case "${gnu_cmd}" in

    getopt)
      # GNU getopt supports --test or -T with an exit status of 4.
      "${cmd}" --test >>/dev/null
      if [[ ${?} -ne 4 ]]; then
        msg::error "[%s] at [%s] is NOT the enhanced GNU getopt version.\n" \
          "${gnu_cmd}" "${cmd}"
        msg::warn "You must use [%s] from the util-linux package.\n" \
          "${gnu_cmd}"
        return 1
      fi
      ;;

    sed)
      # GNU sed supports the --version option.
      if ! (
        "${cmd}" --version | grep "GNU"
        [[ ${PIPESTATUS[0]} == 0 && ${PIPESTATUS[1]} == 0 ]]
      ) >/dev/null; then
        msg::error "The cmd [%s] installed at [%s] is not a GNU command.\n" \
          "${gnu_cmd}" "${cmd}"
        return 1
      fi
      ;;

    *)
      msg::arg_error "checking GNU cmd [%s] is NOT supported.\n" "${gnu_cmd}"
      return 2
      ;;
  esac

  msg::debug "%s is an installed GNU command.\n" "${gnu_cmd}"
}

################################################################################
## Checks if the given command(s) is installed in PATH.
## NOTE:  If the command starts with "gnu-<command>" (e.g., gnu-sed), it is
## assumed that we want to check for the existence of a GNU command.
## Globals:
##  None.
## Arguments:
##   1 [required]: list of command(s) (e.g., "docker java unzip zip")
## Returns:
##   0 if okay; something else if fails.
################################################################################
os::is_installed() {
  [[ ${#} -ne 1 ]] \
    && msg::arg_error "invalid number of argument(s)." \
    && return 2

  [[ -z "${1:-}" || -z "${1//[[:space:]]/}" ]] \
    && msg::arg_error "missing [%s].\n" "command(s)" \
    && return 2

  # shellcheck disable=SC2206
  local -a cmd_args_arr=(${1})
  # do not use IFS because we could have single command with no spaces.
  #  IFS=' ' read -ra arr <<<"${1}"
  msg::debug "cmd_args_arr=%s\n" "${cmd_args_arr[*]}"

  local cmd_arg cmd gnu_cmd

  for cmd_arg in "${cmd_args_arr[@]}"; do
    gnu_cmd=
    cmd=

    # getopt must be the GNU enhanced version from the util-linux
    # package. The MacOS getopt will NOT work !!!
    if [[ "${cmd_arg:-}" == "getopt" ]]; then
      gnu_cmd="${cmd_arg}"
      msg::debug "checking for GNU util-linux package command: %s\n" \
        "${gnu_cmd}"
      os::is_gnu_cmd "${gnu_cmd}" || return
      continue
    elif [[ "${cmd_arg}" =~ ^gnu-.+$ ]]; then
      # Rubens left this condition to cover any scenarios where the code may
      # still prefix gnu commands with "gnu-"<command>
      gnu_cmd="${cmd_arg/#gnu-/}"
      msg::debug "checking for a GNU command: %s\n" "${gnu_cmd}"
      os::is_gnu_cmd "${gnu_cmd}" || return
      continue
    fi

    if ! cmd="$(command -v "${cmd_arg}")"; then
      msg::arg_error "[%s] not found in the PATH.\n" "${cmd_arg}"
      return 127
    fi

    if [[ -z "${cmd:-}" || ! -x "${cmd}" ]]; then
      msg::arg_error "[%s] is not an executable.\n" "${cmd_arg}"
      return 2
    fi

  done

  return 0
}

################################################################################
## Checks if we are on a MacOS
## Globals:
##   OSTYPE     : Bash variable to describe operating system.
##   PIPESTATUS : Bash array to store pipeline command exit status.
## Arguments:
##   None
## Returns:
##   TRUE or 0 if yes; FALSE or 1, otherwise
################################################################################
os::is_macos() {
  ( grep -q -i "darwin" <<< "${OSTYPE}" )
}

################################################################################
## Merges ":" separated paths into a new path.  It removes any duplicates
## from the merged path.
## Argumentss
##   1 [required]: first path to merge with next one.
##   2 [required]: sedond path to merge with first path.
## Returns:
##   0 if okay; something else if fails.
## Outputs:
##   Writes to stdout the merged path.
################################################################################
os::merge_paths() {
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # ATTENTION: This function writes its result to the stdout. Therefore,
  # any code in this function should be carefully examined to not write to
  # stdout, which corrupts the result and breaks any dependent code.
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  [[ ${#} -ne 2 ]] \
    && msg::arg_error "invalid number of argument(s)." \
    && return 2

  [[ -z "${1:-}" || -z "${1//[[:space:]]/}" ]] \
    && msg::arg_error "missing [%s].\n" "first path" \
    && return 2

  local -r first_path="${1}"

  [[ -z "${2:-}" || -z "${2//[[:space:]]/}" ]] \
    && msg::arg_error "missing [%s].\n" "second path" \
    && return 2

  local -r second_path="${2}"

  local new_path=

  # code under MIT License at GitHub at:
  # https://github.com/ralish/bash-script-template/blob/main/source.sh#L295

  local temp_path="${first_path}:${second_path}:"
  local path_entry

  # remove redundant duplicates from temp_path
  while [[ -n "${temp_path}" ]]; do
    # split temp_path using the ":" as the field separator.  For example,
    # if temp_path="/bin:/sbin:", then path_entry becomes "/bin" and "/sbin"
    path_entry="${temp_path%%:*}"

    case "${new_path:-}:" in
      *:"${path_entry}":*)
        # do nothing.
        ;;
      *)
        new_path="${new_path}:${path_entry}"
        ;;
    esac

    # removes the first part of temp_path up to and including ":"
    # e.g., if temp_path is "vasco:da:gama:", the result is "da:gama:"
    # e.g., if temp_path is "gama:", the result is "gama"
    temp_path="${temp_path#*:}"
  done

  # rempve any ":" found at end of new_path
  echo "${new_path#:}"
}

################################################################################
## Deletes files that are owned by the current shell ${UID} with given name
## patterns found in the given parent and its children subdirectories.
## Globals:
##   UID : Bash shell variable containing the effective shell's UID.
## Arguments:
##   1 [required]: parent directory from where files should be deleted.
##   2 [required]: one or more name(s) patterns (e.g., "*build local *.out").
## Returns:
##   0 if okay; something else if fails.
################################################################################
os::rm_files() {
  os::_check_rm_files_args "${@:-}" || return 2
  local -r parent_dir="${1}"
  # shellcheck disable=SC2206
  local -a patterns_arr=(${2})

  local pattern
  for pattern in "${patterns_arr[@]}"; do
    msg::info "removing files with pattern [%s] in [%s] subdirectories.\n" \
      "${pattern}" "${parent_dir}"

    local files
    files="$(
      find "${parent_dir}" -type f -name "${pattern}" -user "${UID}"
    )"

    if [[ -z "${files}" ]]; then
      msg::warn "no files owned by [%s] w/pattern [%s] found under [%s].\n" \
        "${UID}" "${pattern}" "${parent_dir}"
      continue
    fi

    # shellcheck disable=SC2206
    local -a files_arr=(${files})
    local file

    for file in "${files_arr[@]}"; do
      msg::info "removing file [%s].\n" "${file}"
      rm -f "${file}"
    done

  done
}

################################################################################
## Prompts user to eeletes files with the gvien extension found in the given
## directory and its corresponding children subdirectories.
## Arguments:
##   1 [required]: parent directory from where files should be deleted.
##   2 [required]: one or more name(s) patterns (e.g., "*build local *.out").
## Returns:
##   0 if okay; something else if fails.
## Outputs:
##   Message prompting the user to respond with Y or N.
################################################################################
os::rm_files_prompt_user() {
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # ATTENTION: This function writes its result to the stdout. Therefore,
  # any code in this function should be carefully examined to not write to
  # stdout, which corrupts the result and breaks any dependent code.
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  os::_check_rm_files_args "${@:-}" || return 2
  local -r parent_dir="${1}"
  # shellcheck disable=SC2206
  local -a patterns_arr=(${2})

  cat <<EOF

WARNING! This will remove:

  - all file(s) with name(s) having pattern(s):

EOF

  local pattern
  for pattern in "${patterns_arr[@]}"; do
    echo "    ${pattern}"
  done

  cat <<EOF

    found under the directory and its children subdirectories:

    ${parent_dir}

EOF

  msg::yes_no
}

################################################################################
## Deletes subdirectories that are owned by the current shell ${UID} with
## given name pattern found in the given parent and its children subdirectories.
## Globals:
##   UID : Bash shell variable containing the effective shell's UID.
## Arguments:
##   1 [required]: parent directory of subdirectories to remove.
##   2 [required]: one or more name(s) patterns (e.g., "*build* .local* out").
## Returns:
##   0 if okay; something else if fails.
################################################################################
os::rm_subdirs() {
  [[ ${#} -ne 2 ]] \
    && msg::arg_error "invalid number of argument(s)." \
    && return 2

  [[ -z "${1:-}" || -z "${1//[[:space:]]/}" ]] \
    && msg::arg_error "missing [%s].\n" "parent directory" \
    && return 2

  local -r parent_dir="${1}"

  [[ -z "${2:-}" || -z "${2//[[:space:]]/}" ]] \
    && msg::arg_error "missing [%s].\n" "subdirectory name(s)" \
    && return 2

  # shellcheck disable=SC2206
  local -a patterns_arr=(${2})

  [[ ! -d "${parent_dir}" ]] \
    && msg::arg_error "[%s] is not a valid directory.\n" "${parent_dir}" \
    && return 1

  local pattern
  for pattern in "${patterns_arr[@]}"; do
    msg::info "finding folders with pattern [%s] within [%s].\n" \
      "${pattern}" "${parent_dir}"

    local folders

    if ! folders="$(
      find "${parent_dir}" -type d -name "${pattern}" -user "${UID}"
    )"; then
      msg::error "failed to find [%s] in [%s] with UID [%s].\n" "${pattern}" \
        "${parent_dir}" "${UID}"
      return 1
    fi

    if [[ -z "${folders}" ]]; then
      msg::warn "no folders owned by [%s] w/pattern [%s] found under [%s].\n" \
        "${UID}" "${pattern}" "${parent_dir}"
      continue
    fi

    msg::debug "folders found: [%s].\n" "${folders}"
    # shellcheck disable=SC2206
    local -a folders_arr=(${folders})
    msg::debug "folders array: [%s].\n" "${folders_arr[*]}"

    local folder
    for folder in "${folders_arr[@]}"; do
      msg::info "removing folder [%s].\n" "${folder}"
      rm -fr "${folder}"
    done

  done
}

################################################################################
## Prompts Y/N question about removing subdirectories in given parent directory.
## directory.
## Arguments:
##   1 [required]: parent directory of subdirectories to remove.
##   2 [required]: one or more name(s) patterns (e.g., "*build* .local* out").
## Returns:
##   0 if yes, 1 if no, something else if fails.
## Outputs:
##   Message prompting the user to respond with Y or N.
################################################################################
os::rm_subdirs_prompt_user() {
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # ATTENTION: This function writes its result to the stdout. Therefore,
  # any code in this function should be carefully examined to not write to
  # stdout, which corrupts the result and breaks any dependent code.
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  os::_check_rm_subdirs_args "${@:-}" || return 2
  local -r parent_dir="${1}"
  # shellcheck disable=SC2206
  local -a patterns_arr=(${2})

  cat <<EOF

WARNING! This will remove:

  - all subdirectory(ies) with name(s) havving pattern(s):

EOF

  local pattern
  for pattern in "${patterns_arr[@]}"; do
    echo "    ${pattern}"
  done

  cat <<EOF

    found under the directory and its children subdirectories:

    ${parent_dir}

EOF

  msg::yes_no
}

################################################################################
## Checks and set the given path as the new JAVA_HOME and adds it to the
## head of the PATH.
## Globals:
##   JAVA_HOME : environment variable for the installed path of Java.
##   PATH      : Bash environment variable used to search commands.
## Arguments:
##   1 [required]: path to new JAVA_HOME.
## Returns:
##   0 if yes, 1 if no, something else if fails.
################################################################################
os::set_java_home() {
  [[ ${#} -ne 1 ]] \
    && msg::arg_error "invalid number of argument(s)." \
    && return 2

  [[ -z "${1:-}" || -z "${1//[[:space:]]/}" ]] \
    && msg::arg_error "missing [%s].\n" "path to new JAVA_HOME" \
    && return 2

  local -r java_home="${1}"

  # check folder exists
  [[ ! -d "${java_home}" ]] \
    && msg::error "given directorory path [%s] not found.\n" "${java_home}" \
    && return 1

  local -r java_binary="${java_home}/bin/java"

  # check for java binary
  [[ ! -x "${java_binary}" ]] \
    && msg::error "java binary not found at [%s].\n" "${java_binary}" \
    && return 1

  local version=
  # check that binary prints a version to stderr
  if ! version="$("${java_binary}" -version 2>&1)"; then
    msg::error "[%s] could not print version to stder.\n" \
      "${java_binary} -version"
    return 1
  fi

  msg::info "java version found at [%s] is\n%s\n" "${java_home}" "${version}"

  export JAVA_HOME="${java_home}"
  msg::debug "new JAVA_HOME [%s].\n" "${JAVA_HOME}"
  export PATH="${JAVA_HOME}/bin:${PATH}"
  msg::debug "new PATH:\n%s\n" "${PATH}"
}

################################################################################
## Supporting private function
################################################################################
os::_check_rm_files_args() {
  [[ ${#} -ne 2 ]] \
    && msg::arg_error "invalid number of argument(s)." \
    && return 2

  [[ -z "${1:-}" || -z "${1//[[:space:]]/}" ]] \
    && msg::arg_error "missing [%s].\n" "parent directory" \
    && return 2

  [[ ! -d "${1}" ]] \
    && msg::arg_error "[%s] is not a valid directory.\n" "${1}" \
    && return 2

  [[ -z "${2:-}" || -z "${2//[[:space:]]/}" ]] \
    && msg::arg_error "missing [%s].\n" "file extension(s)" \
    && return 2

  return 0
}

################################################################################
## Supporting private function
################################################################################
os::_check_rm_subdirs_args() {
  [[ ${#} -ne 2 ]] \
    && msg::arg_error "invalid number of argument(s)." \
    && return 2

  [[ -z "${1:-}" || -z "${1//[[:space:]]/}" ]] \
    && msg::arg_error "missing [%s].\n" "parent directory" \
    && return 2

  [[ ! -d "${1}" ]] \
    && msg::arg_error "[%s] is not a valid directory.\n" "${1}" \
    && return 2

  [[ -z "${2:-}" || -z "${2//[[:space:]]/}" ]] \
    && msg::arg_error "missing [%s].\n" "subdirectory name(s)" \
    && return 2

  return 0
}
