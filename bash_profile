#!/usr/bin/env bash
######################################################################
# File: .bash_profile
#
# Description: Bash *login* shell configuration.
#
#   Bash reads this file only for login shells: `bash -l`, `su -`,
#   an interactive SSH session, and every new macOS Terminal.app /
#   iTerm2 window (both start login shells by default). A plain
#   interactive sub-shell reads ~/.bashrc instead, and neither file
#   is read by non-interactive shells such as `bash script.sh`.
#
#   Bash sources only the FIRST of ~/.bash_profile, ~/.bash_login,
#   ~/.profile that it finds, so while this file exists the other
#   two are ignored entirely.
#
#   To keep a single, unified configuration, every real setting
#   (PATH, prompt, history, aliases) lives in ~/.bashrc and this file
#   does nothing but source it. Put a setting here only if it is
#   genuinely login-only -- for example, starting ssh-agent -- so it
#   is not re-run by every sub-shell.
#
# See also: .bashrc, .bash_aliases
#
# Author: Rubens Gomes
######################################################################

# -r (readable) rather than -f (exists), since `source` needs read
# permission; warn on stderr when missing, as .bashrc does for the
# files it pulls in.
if [[ -r "${HOME}/.bashrc" ]]; then
  source "${HOME}/.bashrc"
else
  printf "missing %s\n" "${HOME}/.bashrc" >&2
fi
