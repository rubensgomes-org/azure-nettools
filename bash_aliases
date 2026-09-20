#!/usr/bin/env bash
######################################################################
# File: .bash_aliases
#
# Description: Shell aliases, kept separate from ~/.bashrc so alias
#   edits do not require touching the main configuration.
#
#   Sourced near the end of ~/.bashrc.
#
#   Aliases are expanded only in interactive shells. Scripts run with
#   `bash script.sh` or `bash -c` are unaffected by everything here,
#   which is why the safety aliases at the bottom never interfere
#   with automation.
#
# See also: .bashrc, .bash_profile
#
# Author: Rubens Gomes
######################################################################

# enable color support of ls and also add handy aliases
#
# The test asks whether GNU coreutils is installed, using dircolors
# as the marker (/usr/bin/dircolors).
#
# NOTE: nothing here actually calls dircolors or reads LS_COLORS --
# the check is inherited from the stock Debian/Ubuntu .bashrc, where
# it gates a `eval "$(dircolors -b)"` that this file does not have.
if [[ -x "/usr/bin/dircolors" ]]
then
  # Bash re-expands the first word of an alias, so `ls` inside the
  # definitions below resolves to this alias in turn. `ll` really
  # runs `ls --color=auto -alF --color=auto`; the repeated flag is
  # harmless, and the color survives even if these three are used on
  # their own.
  alias ls='ls --color=auto'
  # ll: long listing, all entries including dotfiles, with a type
  #     suffix (/ for directories, * for executables, @ for symlinks)
  alias ll='ls -alF --color=auto'
  # la: all entries except . and .. (-A, unlike -a)
  alias la='ls -A --color=auto'
  # l:  compact multi-column listing with type suffixes
  alias l='ls -CF --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
else
  # No coreutils: fall back to uncolored listings. Note that plain
  # `ls` and the grep family are intentionally left unaliased here,
  # so they keep whatever defaults the system provides.
  printf "missing dircolors\n" >&2
  alias ll='ls -alF'
  alias la='ls -A'
  alias l='ls -CF'
fi

# Safety net: prompt before clobbering or deleting an existing file.
# These protect interactive typos only -- scripts do not expand
# aliases, so they are not a substitute for careful scripting. Bypass
# a prompt for a single command by prefixing it with a backslash,
# e.g. `\rm -r build`, or by passing -f.
alias cp="cp -i"
alias rm="rm -i"
alias mv="mv -i"
