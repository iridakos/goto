# SOURCE: https://github.com/iridakos/goto
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
#
# This is a thin fish-shell wrapper around goto.sh. It is intentionally NOT a
# reimplementation: goto.sh remains the single source of truth and is executed
# via bash for every subcommand. Fish only handles what genuinely has to run in
# the current shell - changing the working directory (cd / pushd / popd) - since
# that cannot be done from a subprocess.

# Locate the bash implementation. goto.sh is installed next to this file, but a
# custom location can be forced through $GOTO_SH.
if not set -q GOTO_SH
    set -g GOTO_SH (dirname (status filename))/goto.sh
end

# Runs goto.sh in bash, forwarding all arguments. Used for every subcommand that
# does not need to change the current shell's directory.
function __goto_run
    command bash -c 'src="$1"; shift; . "$src"; goto "$@"' -- $GOTO_SH $argv
end

# Resolves an alias to its absolute directory through goto.sh (the resolution
# logic - database lookup, format, errors - lives there, not here).
function __goto_resolve --argument-names name
    __goto_run -x $name 2>/dev/null
end

function goto --description 'Changes to the directory registered for an alias'
    if test (count $argv) -eq 0
        __goto_run
        return
    end

    switch $argv[1]
        case -o --pop
            popd >/dev/null 2>&1

        case -p --push
            if test (count $argv) -ne 2
                __goto_run $argv # let goto.sh print the usage error
                return
            end
            set -l name $argv[2]
            set -l target (__goto_resolve $name)
            if test -z "$target"; and test -d "$name"
                set target $name
            end
            if test -z "$target"
                __goto_run $argv # let goto.sh print the proper error
                return 1
            end
            pushd $target >/dev/null

        case -r --register -u --unregister -l --list -x --expand -c --cleanup -h --help -v --version
            # Pure database/printing commands: delegate entirely to goto.sh.
            __goto_run $argv

        case '*'
            # Plain `goto <alias>` (or a literal path / special name like ..).
            set -l name $argv[1]
            set -l target (__goto_resolve $name)
            if test -n "$target"
                cd $target
            else if test -d "$name"
                cd $name
            else
                __goto_run $name # reuse goto.sh's "unregistered / did you mean" output
                return 1
            end
    end
end

# --- Completions (the only unavoidably shell-specific part) --------------
# Even the completion data is sourced from goto.sh so the database location and
# format stay defined in one place.
function __goto_alias_names
    command bash -c '. "$1"; _goto_resolve_db; cut -d" " -f1 -- "$GOTO_DB" 2>/dev/null' -- $GOTO_SH 2>/dev/null
end

complete -c goto -f
complete -c goto -n __fish_use_subcommand -a '(__goto_alias_names)' -d alias
complete -c goto -n __fish_use_subcommand -s r -l register -d 'registers an alias'
complete -c goto -n __fish_use_subcommand -s u -l unregister -d 'unregisters an alias'
complete -c goto -n __fish_use_subcommand -s p -l push -d 'pushes the current directory, then goto'
complete -c goto -n __fish_use_subcommand -s o -l pop -d 'pops the top directory, then changes to it'
complete -c goto -n __fish_use_subcommand -s l -l list -d 'lists aliases'
complete -c goto -n __fish_use_subcommand -s x -l expand -d 'expands an alias'
complete -c goto -n __fish_use_subcommand -s c -l cleanup -d 'cleans up non existent directory aliases'
complete -c goto -n __fish_use_subcommand -s h -l help -d 'prints help'
complete -c goto -n __fish_use_subcommand -s v -l version -d 'displays the version'
complete -c goto -n '__fish_seen_subcommand_from -u --unregister -x --expand -p --push' -a '(__goto_alias_names)' -d alias
complete -c goto -n '__fish_seen_subcommand_from -r --register' -a '(__fish_complete_directories)'
