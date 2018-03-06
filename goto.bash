#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2018 Lazarus Lazaridis
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Changes to the given alias directory
# or executes a command based on the arguments.
function goto()
{
  local target

  if [ -z "$1" ]; then
    # display usage and exit when no args
    _goto_usage
    return
  fi

  subcommand="$1"
  shift
  case "$subcommand" in
    -c|--cleanup)
      _goto_cleanup "$@"
      ;;
    -r|--register) # Register an alias
      _goto_register_alias "$@"
      ;;
    -u|--unregister) # Unregister an alias
      _goto_unregister_alias "$@"
      ;;
    -l|--list)
      _goto_list_aliases
      ;;
    -h|--help)
      _goto_usage
      ;;
    *)
      _goto_directory "$subcommand"
      ;;
  esac
}

function _goto_usage()
{
  cat <<\USAGE
usage: goto [<option>] <alias> [<directory>]

default usage:
  goto <alias> - changes to the directory registered for the given alias

OPTIONS:
  -r, --register: registers an alias
    goto -r|--register <alias> <directory>
  -u, --unregister: unregisters an alias
    goto -u|--unregister <alias>
  -l, --list: lists aliases
    goto -l|--list
  -c, --cleanup: cleans up non existent directory aliases
    goto -c|--cleanup
  -h, --help: prints this help
    goto -h|--help
USAGE
}

# Expands directory.
# Helpful for ~, ., .. paths
function _goto_expand_directory()
{
  printf "$(cd $1 2>/dev/null && pwd)"
}

# Lists regstered aliases.
function _goto_list_aliases()
{
  local IFS=$'\n'
  if [ -f ~/.goto ]; then
    echo "$(sed '/^\s*$/d' ~/.goto 2>/dev/null)"
  else
    echo "You haven't configured any directory aliases yet."
  fi
}

# Registers and alias.
function _goto_register_alias()
{
  if [ "$#" -ne "2" ]; then
    _goto_error "usage: goto -r|--register <alias> <directory>"
    return
  fi

  if ! [[ $1 =~ ^[[:alnum:]]*[[:alpha:]][[:alnum:]]*$ ]]; then
    _goto_error "invalid alias - only alphabetic with numbers"
    return
  fi

  local resolved=$(_goto_find_alias_directory $1)
  if [ -n "$resolved" ]; then
    _goto_error "alias '$1' exists"
    return
  fi

  local directory="$(_goto_expand_directory $2)"
  if [ -z "$directory" ]; then
    _goto_error "failed to register $1 to $2 - can't cd to directory"
    return
  fi

  # Append entry to file.
  echo "$1 $directory" >> ~/.goto
  echo "Alias '$1' registered successfully."
}

# Unregisters the given alias.
function _goto_unregister_alias
{
  if [ "$#" -ne "1" ]; then
    _goto_error "usage: goto -u|--unregister <alias>"
    return
  fi

  local resolved=$(_goto_find_alias_directory $1)
  if [ -z "$resolved" ]; then
    _goto_error "alias '$1' does not exist"
    return
  fi

  # Delete entry from file.
  echo "$(sed "/^$1 /d" ~/.goto)" > ~/.goto
  echo "Alias '$1' unregistered successfully."
}

# Unregisters aliases whose directories no longer exist.
function _goto_cleanup()
{
  while IFS='' read -r entry || [[ -n "$entry" ]]; do
    al=$(echo $entry | sed 's/ .*//')
    dir=$(echo $entry | sed 's/[^ ]* //')

    if [ -n "$al" ] && [ ! -d "$dir" ]; then
      echo "Cleaning up: $al - $dir"
      _goto_unregister_alias $al
    fi
  done <<< "$(cat ~/.goto 2>/dev/null)"
}

# Changes to the given alias' directory
function _goto_directory()
{
  local target=$(_goto_resolve_alias "$1")

  if [ -n "$target" ]; then
    cd "$target"
  fi
}

# Fetches the alias directory.
function _goto_find_alias_directory()
{
  local resolved=$(sed -n "/^$1 /p" ~/.goto 2>/dev/null | sed 's/[^ ]* //')
  echo "$resolved"
}

# Displays the given error.
# Used for common error output.
function _goto_error()
{
  (>&2 echo "goto error: $1")
}

# Fetches alias directory, errors if it doesn't exist.
function _goto_resolve_alias()
{
  local resolved=$(_goto_find_alias_directory "$1")
  if [ -z "$resolved" ]; then
    _goto_error "unregistered alias $1"
    echo ""
  else
    echo "${resolved}"
  fi
}

# Completes the goto function with the available commands
function _complete_goto_commands()
{
  COMPREPLY=($(compgen -W "-r --register -u --unregister -l --list -c --cleanup" -- "$1"))
}

# Completes the goto function with the available aliases
function _complete_goto_aliases()
{
  local IFS=$'\n' expr

  local matches=($(sed -n "/^$1/p" ~/.goto 2>/dev/null))

  if [ "${#matches[@]}" -eq "1" ]; then
    # remove the filenames attribute from the completion method
    compopt +o filenames 2>/dev/null

    # if you find only one alias don't append the directory
    COMPREPLY=$(printf ${matches[0]} | sed 's/ .*//')
  else
    for i in "${!matches[@]}"; do
      # remove the filenames attribute from the completion method
      compopt +o filenames 2>/dev/null

      if ! [[ $(uname -s) =~ Darwin* ]]; then
        matches[$i]=$(printf '%*s' "-$COLUMNS" "${matches[$i]}")

        COMPREPLY+=($(compgen -W "${matches[$i]}"))
      else
        al=$(echo ${matches[$i]} | sed 's/ .*//')

        COMPREPLY+=($(compgen -W "$al"))
      fi
    done
  fi
}

# Bash programmable completion for the goto function
function _complete_goto()
{
  local cur="${COMP_WORDS[$COMP_CWORD]}"

  if [ "$COMP_CWORD" -eq "1" ]; then
    # if we are on the first argument
    if [[ $cur == -* ]]; then
      # and starts like a command, prompt commands
      _complete_goto_commands "$cur"
    else
      # and doesn't start as a command, prompt aliases
      _complete_goto_aliases "$cur"
    fi
  elif [ "$COMP_CWORD" -eq "2" ]; then
    # if we are on the second argument
    local prev="${COMP_WORDS[1]}"

    if [[ $prev = "-u" ]] || [[ $prev = "--unregister" ]]; then
      # prompt with aliases only if user tries to unregister one
      _complete_goto_aliases "$cur"
    fi
  elif [ "$COMP_CWORD" -eq "3" ]; then
    # if we are on the third argument
    local prev="${COMP_WORDS[1]}"

    if [[ $prev = "-r" ]] || [[ $prev = "--register" ]]; then
      # prompt with directories only if user tries to register an alias
      COMPREPLY=($(compgen -d -- "$cur"))
    fi
  fi
}

# Register the goto compspec
if ! [[ $(uname -s) =~ Darwin* ]]; then
  complete -o filenames -F _complete_goto goto
else
  complete -F _complete_goto goto
fi
