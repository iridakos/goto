# shellcheck shell=bash
# shellcheck disable=SC2039
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
goto()
{
  local target
  _goto_resolve_db

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
    -p|--push) # Push the current directory onto the pushd stack, then goto
      _goto_directory_push "$@"
      ;;
    -o|--pop) # Pop the top directory off of the pushd stack, then change that directory
      _goto_directory_pop
      ;;
    -l|--list)
      _goto_list_aliases
      ;;
    -x|--expand) # Expand an alias
      _goto_expand_alias "$@"
      ;;
    -h|--help)
      _goto_usage
      ;;
    -v|--version)
      _goto_version
      ;;
    *)
      _goto_directory "$subcommand"
      ;;
  esac
  return $?
}

_goto_resolve_db()
{
  GOTO_DB="${GOTO_DB:-$HOME/.goto}"
  touch -a "$GOTO_DB"
}

_goto_usage()
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
  -p, --push: pushes the current directory onto the stack, then performs goto
    goto -p|--push <alias>
  -o, --pop: pops the top directory from the stack, then changes to that directory
    goto -o|--pop
  -l, --list: lists aliases
    goto -l|--list
  -x, --expand: expands an alias
    goto -x|--expand <alias>
  -c, --cleanup: cleans up non existent directory aliases
    goto -c|--cleanup
  -h, --help: prints this help
    goto -h|--help
  -v, --version: displays the version of the goto script
    goto -v|--version
USAGE
}

# Displays version
_goto_version()
{
  echo "goto version 1.2.3"
}

# Expands directory.
# Helpful for ~, ., .. paths
_goto_expand_directory()
{
  cd "$1" 2>/dev/null && pwd
}

# Lists registered aliases.
_goto_list_aliases()
{
  local IFS=$' '
  if [ -f "$GOTO_DB" ]; then
    while read -r name directory; do
      printf '\e[1;36m%20s  \e[0m%s\n' "$name" "$directory"
    done < "$GOTO_DB"
  else
    echo "You haven't configured any directory aliases yet."
  fi
}

# Expands a registered alias.
_goto_expand_alias()
{
  if [ "$#" -ne "1" ]; then
    _goto_error "usage: goto -x|--expand <alias>"
    return
  fi

  local resolved

  resolved=$(_goto_find_alias_directory "$1")
  if [ -z "$resolved" ]; then
    _goto_error "alias '$1' does not exist"
    return
  fi

  echo "$resolved"
}

# Lists duplicate directory aliases
_goto_find_duplicate()
{
  local duplicates=

  duplicates=$(sed -n 's:[^ ]* '"$1"'$:&:p' "$GOTO_DB" 2>/dev/null)
  echo "$duplicates"
}

# Registers and alias.
_goto_register_alias()
{
  if [ "$#" -ne "2" ]; then
    _goto_error "usage: goto -r|--register <alias> <directory>"
    return 1
  fi

  if ! [[ $1 =~ ^[[:alnum:]]+[a-zA-Z0-9_-]*$ ]]; then
    _goto_error "invalid alias - can start with letters or digits followed by letters, digits, hyphens or underscores"
    return 1
  fi

  local resolved
  resolved=$(_goto_find_alias_directory "$1")

  if [ -n "$resolved" ]; then
    _goto_error "alias '$1' exists"
    return 1
  fi

  local directory
  directory=$(_goto_expand_directory "$2")
  if [ -z "$directory" ]; then
    _goto_error "failed to register '$1' to '$2' - can't cd to directory"
    return 1
  fi

  local duplicate
  duplicate=$(_goto_find_duplicate "$directory")
  if [ -n "$duplicate" ]; then
    _goto_warning "duplicate alias(es) found: \\n$duplicate"
  fi

  # Append entry to file.
  echo "$1 $directory" >> "$GOTO_DB"
  echo "Alias '$1' registered successfully."
}

# Unregisters the given alias.
_goto_unregister_alias()
{
  if [ "$#" -ne "1" ]; then
    _goto_error "usage: goto -u|--unregister <alias>"
    return 1
  fi

  local resolved
  resolved=$(_goto_find_alias_directory "$1")
  if [ -z "$resolved" ]; then
    _goto_error "alias '$1' does not exist"
    return 1
  fi

  # shellcheck disable=SC2034
  local readonly GOTO_DB_TMP="$HOME/.goto_"
  # Delete entry from file.
  sed "/^$1 /d" "$GOTO_DB" > "$GOTO_DB_TMP" && mv "$GOTO_DB_TMP" "$GOTO_DB"
  echo "Alias '$1' unregistered successfully."
}

# Pushes the current directory onto the stack, then goto
_goto_directory_push()
{
  if [ "$#" -ne "1" ]; then
    _goto_error "usage: goto -p|--push <alias>"
    return
  fi

  { pushd . || return; } 1>/dev/null 2>&1

  _goto_directory "$@"
}

# Pops the top directory from the stack, then goto
_goto_directory_pop()
{
  { popd || return; } 1>/dev/null 2>&1
}

# Unregisters aliases whose directories no longer exist.
_goto_cleanup()
{
  if ! [ -f "$GOTO_DB" ]; then
    return
  fi

  while IFS= read -r i && [ -n "$i" ]; do
    echo "Cleaning up: $i"
    _goto_unregister_alias "$i"
  done <<< "$(awk '{al=$1; $1=""; dir=substr($0,2);
                    system("[ ! -d \"" dir "\" ] && echo " al)}' "$GOTO_DB")"
}

# Changes to the given alias' directory
_goto_directory()
{
  local target

  target=$(_goto_resolve_alias "$1") || return 1

  cd "$target" 2> /dev/null || \
    { _goto_error "Failed to goto '$target'" && return 1; }
}

# Fetches the alias directory.
_goto_find_alias_directory()
{
  local resolved

  resolved=$(sed -n "s/^$1 \\(.*\\)/\\1/p" "$GOTO_DB" 2>/dev/null)
  echo "$resolved"
}

# Displays the given error.
# Used for common error output.
_goto_error()
{
  (>&2 echo -e "goto error: $1")
}

# Displays the given warning.
# Used for common warning output.
_goto_warning()
{
  (>&2 echo -e "goto warning: $1")
}

# Displays entries with aliases starting as the given one.
_goto_print_similar()
{
  local similar

  similar=$(sed -n "/^$1[^ ]* .*/p" "$GOTO_DB" 2>/dev/null)
  if [ -n "$similar" ]; then
    (>&2 echo "Did you mean:")
    (>&2 column -t <<< "$similar")
  fi
}

# Fetches alias directory, errors if it doesn't exist.
_goto_resolve_alias()
{
  local resolved

  resolved=$(_goto_find_alias_directory "$1")

  if [ -z "$resolved" ]; then
    _goto_error "unregistered alias $1"
    _goto_print_similar "$1"
    return 1
  else
    echo "${resolved}"
  fi
}

# Completes the goto function with the available commands
_complete_goto_commands()
{
  local IFS=$' \t\n'

  # shellcheck disable=SC2207
  COMPREPLY=($(compgen -W "-r --register -u --unregister -p --push -o --pop -l --list -x --expand -c --cleanup -v --version" -- "$1"))
}

# Completes the goto function with the available aliases
_complete_goto_aliases()
{
  local IFS=$'\n' matches
  _goto_resolve_db

  # shellcheck disable=SC2207
  matches=($(sed -n "/^$1/p" "$GOTO_DB" 2>/dev/null))

  if [ "${#matches[@]}" -eq "1" ]; then
    # remove the filenames attribute from the completion method
    compopt +o filenames 2>/dev/null

    # if you find only one alias don't append the directory
    COMPREPLY=("${matches[0]// *}")
  else
    for i in "${!matches[@]}"; do
      # remove the filenames attribute from the completion method
      compopt +o filenames 2>/dev/null

      if ! [[ $(uname -s) =~ Darwin* ]]; then
        matches[$i]=$(printf '%*s' "-$COLUMNS" "${matches[$i]}")

        COMPREPLY+=("$(compgen -W "${matches[$i]}")")
      else
        COMPREPLY+=("${matches[$i]// */}")
      fi
    done
  fi
}

# Bash programmable completion for the goto function
_complete_goto_bash()
{
  local cur="${COMP_WORDS[$COMP_CWORD]}" prev

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
    prev="${COMP_WORDS[1]}"

    if [[ $prev = "-u" ]] || [[ $prev = "--unregister" ]]; then
      # prompt with aliases if user tries to unregister one
      _complete_goto_aliases "$cur"
    elif [[ $prev = "-x" ]] || [[ $prev = "--expand" ]]; then
      # prompt with aliases if user tries to expand one
      _complete_goto_aliases "$cur"
    elif [[ $prev = "-p" ]] || [[ $prev = "--push" ]]; then
      # prompt with aliases only if user tries to push
      _complete_goto_aliases "$cur"
    fi
  elif [ "$COMP_CWORD" -eq "3" ]; then
    # if we are on the third argument
    prev="${COMP_WORDS[1]}"

    if [[ $prev = "-r" ]] || [[ $prev = "--register" ]]; then
      # prompt with directories only if user tries to register an alias
      local IFS=$' \t\n'

      # shellcheck disable=SC2207
      COMPREPLY=($(compgen -d -- "$cur"))
    fi
  fi
}

# Zsh programmable completion for the goto function
_complete_goto_zsh()
{
  local all_aliases=()
  while IFS= read -r line; do
    all_aliases+=("$line")
  done <<< "$(sed -e 's/ /:/g' ~/.goto 2>/dev/null)"

  local state
  local -a options=(
    '(1)'{-r,--register}'[registers an alias]:register:->register'
    '(- 1 2)'{-u,--unregister}'[unregisters an alias]:unregister:->unregister'
    '(: -)'{-l,--list}'[lists aliases]'
    '(*)'{-c,--cleanup}'[cleans up non existent directory aliases]'
    '(1 2)'{-x,--expand}'[expands an alias]:expand:->aliases'
    '(1 2)'{-p,--push}'[pushes the current directory onto the stack, then performs goto]:push:->aliases'
    '(*)'{-o,--pop}'[pops the top directory from stack, then changes to that directory]'
    '(: -)'{-h,--help}'[prints this help]'
    '(* -)'{-v,--version}'[displays the version of the goto script]'
  )

  _arguments -C \
    "${options[@]}" \
    '1:alias:->aliases' \
    '2:dir:_files' \
  && ret=0

  case ${state} in
    (aliases)
      _describe -t aliases 'goto aliases:' all_aliases && ret=0
    ;;
    (unregister)
      _describe -t aliases 'unregister alias:' all_aliases && ret=0
    ;;
  esac
  return $ret
}

# Register the goto completions.
if [ -n "${BASH_VERSION}" ]; then
  if ! [[ $(uname -s) =~ Darwin* ]]; then
    complete -o filenames -F _complete_goto_bash goto
  else
    complete -F _complete_goto_bash goto
  fi
elif [ -n "${ZSH_VERSION}" ]; then
  compdef _complete_goto_zsh goto
else
  echo "Unsupported shell."
  exit 1
fi
