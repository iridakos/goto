# goto

`goto` is a bash utility allowing users to change faster to aliased directories supporting auto-completion :feet:

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

`goto` comes with a nice auto-completion script so that whenever you press the `tab` key after the `goto` command, bash prompts with suggestions of the available aliases:

```bash
bc /etc/bash_completion.d                     
dev /home/iridakos/development
rubies /home/iridakos/.rvm/rubies
```

## Installation

Copy the file `goto.bash` somewhere in your filesystem and add a line in your `.bashrc` to source it.

For example, if you placed the file in your home folder, all you have to do is add the following line to your `.bashrc` file:

```bash
source ~/goto.bash
```

## Usage

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
* Pressing the `tab` key after the alias name, you have the default directory suggestions by bash.

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

## TODO

* ~~Test on macOS~~ extensively
* Write [tests](https://github.com/iridakos/goto/issues/2)

## Contributing

1. Fork it ( https://github.com/iridakos/goto/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

This tool is open source under the [MIT License](https://opensource.org/licenses/MIT) terms.
