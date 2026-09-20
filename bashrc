#!/usr/bin/env bash
######################################################################
# File: .bashrc
#
# Description: The single source of truth for this Bash environment.
#
#   Bash reads this file for interactive NON-login shells. Login
#   shells read ~/.bash_profile instead, which does nothing but
#   source this file -- so in practice every Bash session, login or
#   not, ends up here. Put settings here, not in ~/.bash_profile.
#
# Platform: Linux Debian
# See also: .bash_profile, .bash_aliases, .inputrc
#
# Author: Rubens Gomes
######################################################################

######################################################################
## MOTD
# /etc/motd is normally shown by PAM on login, but `docker run -it
# ... bash` execs bash directly and skips PAM, so print it here.
[[ -r /etc/motd ]] && cat /etc/motd


######################################################################
## HISTORY
# Increase history size
# HISTSIZE  = commands kept in memory for this session.
# HISTFILESIZE = lines kept in ~/.bash_history on disk.
export HISTSIZE=50000
export HISTFILESIZE=100000
# ignoreboth = ignorespace + ignoredups: skip commands typed with a
# leading space (handy for one-off commands holding a token) and skip
# a command identical to the one before it. erasedups additionally
# purges older copies of a repeated command from the in-memory list.
export HISTCONTROL=ignoreboth:erasedups
# Save each command immediately, import new commands from other shells,
# then rewrite the file from the deduplicated in-memory list.
# history -a appends this session's new lines to the history file;
# history -n reads back lines other sessions have appended. Together
# they approximate history shared live across concurrent terminals.
# history -w then overwrites the file with the in-memory list, which
# HISTCONTROL=erasedups has already purged of older duplicates. This
# is what keeps ~/.bash_history itself free of duplicates: -a alone
# only ever appends, so without -w repeated commands accumulate on
# disk forever even though the in-memory list looks clean.
# Cost: rewrites the whole file (HISTSIZE lines) at every prompt, and
# two shells writing at the same instant means one wins -- the
# history -n immediately above makes that largely self-correcting.
PROMPT_COMMAND='history -a; history -n; history -w'
# Append to the history file on exit rather than overwriting it.
# With the `history -a` above this is effectively a no-op today --
# every command is already written at its own prompt, so the exit
# write has nothing left to flush. It is kept as a safety net: if
# PROMPT_COMMAND is ever simplified, this is what stops the last
# shell to exit from clobbering the history of concurrent shells.
shopt -s histappend


######################################################################
## LINES / COLUMNS
# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
# Without this, resizing the terminal leaves programs that read
# $LINES/$COLUMNS wrapping text at the old width.
shopt -s checkwinsize


#####################################################################
## PROMPT PS1
# Prompt layout: green username, blue working directory, then $.
#   \u = username, \W = basename of cwd, \$ = "#" for root else "$".
# The \[ \] wrappers mark the escape sequences as zero-width so Bash
# computes the prompt length correctly and line editing does not
# smear on long command lines.
if [[ -x /usr/bin/tput ]] && tput setaf >&/dev/null; then
  # We have color support; assume it's compliant with Ecma-48
  # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
  # a case would tend to support setf rather than setaf.)
  #PS1='\[\033[01;32m\]\u \W \[\033[01;34m\]\[\033[00m\]\$ '
  PS1='\[\033[01;32m\]\u \[\033[01;34m\]\W \[\033[01;34m\]\[\033[00m\]\$ '
else
  printf "missing %s\n" "/usr/bin/tput" >&2
  PS1='\u \W \$ '
fi


#####################################################################
## PATH
# Safely add your personal local bins to the standard system paths.
# Prepended, so a personal script shadows a system command of the
# same name.
PATH="${HOME}/bin:${PATH}"
export PATH


#####################################################################
## BASH COMPLETION
BASH_COMPLETION="/etc/profile.d/bash_completion.sh"

if [[ -r "${BASH_COMPLETION}" ]]; then
  # shellcheck source=/etc/profile.d/bash_completion.sh
  source "${BASH_COMPLETION}"
else
  printf "missing %s\n" "${BASH_COMPLETION}" >&2
fi


#####################################################################
## ALIASES
# Kept in a separate file so alias changes do not require touching
# this one.
[[ -r "${HOME}/.bash_aliases" ]] && source "${HOME}/.bash_aliases" || \
  printf "missing %s\n" "${HOME}/.bash_aliases" >&2
