# Changelog

All notable changes to `goto` will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [1.2.4.1] - 2019-06-02

### Fixed
- fix completion for zsh

## [1.2.4] - 2019-05-30

### Added
- support bash completion for aliases of `goto`

## [1.2.3] - 2018-03-14

### Added
- align columns when displaying the list of aliases or similar results

### Changed
- removed shebang since the script is sourced
- updated README with valid information on supported shells

## [1.2.2] - 2018-03-13

### Added
- zsh completion for -x, -p, -o

## [1.2.1] - 2018-03-13

### Added

- Users can set the `GOTO_DB` environment variable to override the default database file which is `$HOME/.goto`
- Introduced the `CHANGELOG.md`
