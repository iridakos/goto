# goto

A shell utility allowing users to navigate to aliased directories supporting auto-completion :feet:

![Generic badge](https://img.shields.io/badge/version-1.2.4.1-green.svg)

## How does it work?

User registers directory aliases, for example:
```bash
goto -r dev /home/iridakos/development
```
and then `cd`s to that directory with:
```bash
goto dev
```

![goto demo gif](https://github.com/iridakos/goto/raw/master/doc/goto.gif)

## goto completion

`goto` comes with a nice auto-completion script so that whenever you press the `tab` key after the `goto` command, bash or zsh prompts with suggestions of the available aliases:

```bash
$ goto <tab>
bc /etc/bash_completion.d                     
dev /home/iridakos/development
rubies /home/iridakos/.rvm/rubies
```

## Installation

### Via script
Clone the repository and run the install script as super user or root:
```bash
git clone https://github.com/iridakos/goto.git
cd goto
sudo ./install
```

### Manually
Copy the file `goto.sh` somewhere in your filesystem and add a line in your `.zshrc` or `.bashrc` to source it.

For example, if you placed the file in your home folder, all you have to do is add the following line to your `.zshrc` or `.bashrc` file:

```bash
source ~/goto.sh
```

### macOS - Homebrew

A formula named `goto` is available for the bash shell in macOS.
```bash
brew install goto
```

### Add colored <tab> output

```bash
echo -e "\$include /etc/inputrc\nset colored-completion-prefix on" >> ~/.inputrc
```

**Note:**
- you need to restart your shell after installation
- you need to have the bash completion feature enabled for bash in macOS (see this [issue](https://github.com/iridakos/goto/issues/36)):
  - you can install it with `brew install bash-completion` in case you don't have it already

## Usage

* [Change to an aliased directory](#change-to-an-aliased-directory)
* [Register an alias](#register-an-alias)
* [Unregister an alias](#unregister-an-alias)
* [List aliases](#list-aliases)
* [Expand an alias](#expand-an-alias)
* [Cleanup](#cleanup)
* [Help](#help)
* [Version](#version)
* [Extras](#extras)
  * [Push before changing directories](#push-before-changing-directories)
  * [Revert to a pushed directory](#revert-to-a-pushed-directory)
* [Troubleshooting](#troubleshooting)
  * [zsh](#zsh)
    * [command not found compdef](#command-not-found-compdef)

### Change to an aliased directory
To change to an aliased directory, type:
```bash
goto <alias>
```

#### Example:
```bash
goto dev
```

### Register an alias
To register a directory alias, type:
```bash
goto -r <alias> <directory>
```
or
```bash
goto --register <alias> <directory>
```

#### Example:
```bash
goto -r blog /mnt/external/projects/html/blog
```
or
```bash
goto --register blog /mnt/external/projects/html/blog
```

#### Notes

* `goto` **expands** the directories hence you can easily alias your current directory with:
```bash
goto -r last_release .
```
and it will automatically be aliased to the whole path.
* Pressing the `tab` key after the alias name, you have the default directory suggestions by the shell.

### Unregister an alias

To unregister an alias, use:
```bash
goto -u <alias>
```
or
```bash
goto --unregister <alias>
```
#### Example
```
goto -u last_release
```
or
```
goto --unregister last_release
```

#### Notes

Pressing the `tab` key after the command (`-u` or `--unregister`), the completion script will prompt you with the list of registered aliases for your convenience.

### List aliases

To get the list of your currently registered aliases, use:
```bash
goto -l
```
or
```bash
goto --list
```

### Expand an alias

To expand an alias to its value, use:
```bash
goto -x <alias>
```
or
```bash
goto --expand <alias>
```

#### Example
```bash
goto -x last_release
```
or
```bash
goto --expand last_release
```

### Cleanup

To cleanup the aliases from directories that are no longer accessible in your filesystem, use:

```bash
goto -c
```
or
```bash
goto --cleanup
```

### Help

To view the tool's help information, use:
```bash
goto -h
```
or
```bash
goto --help
```

### Version

To view the tool's version, use:
```bash
goto -v
```
or
```bash
goto --version
```

## Extras

### Push before changing directories

To first push the current directory onto the directory stack before changing directories, type:
```bash
goto -p <alias>
```
or
```bash
goto --push <alias>
```

### Revert to a pushed directory
To return to a pushed directory, type:
```bash
goto -o
```
or
```bash
goto --pop
```

#### Notes

This command is equivalent to `popd`, but within the `goto` command.

## Troubleshooting

### zsh

#### command not found: compdef

In case you get such an error, you need to load the `bashcompinit`. Append this to your `.zshrc` file:
```bash
autoload bashcompinit
bashcompinit
```

## TODO

* ~~Test on macOS~~ extensively
* Write [tests](https://github.com/iridakos/goto/issues/2)

## Contributing

1. Fork it ( https://github.com/iridakos/goto/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Make sure that the script does not have errors or warning on [ShellCheck](https://www.shellcheck.net/)
6. Create a new Pull Request

## License

This tool is open source under the [MIT License](https://opensource.org/licenses/MIT) terms.

[[Back To Top]](#goto)
