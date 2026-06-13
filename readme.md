# aptac

> mirror apt style commands for pacman

notably my favorite detail:

`./aptac install fastfetch-`

which uninstalls note the `-`.

---

only rule is to modify syntax, not modify pacman behavior (too much).

i'm also hoping reading src code could teach some things
this means every arg passes through to the next tool:

```
./aptac --help

./aptac search --help
```

this second example will just get the pacman help.

all dependencies are: `pacman`, `pacman-contrib`, `reflector`

---

## some details:

all your pacman settings are found in `/etc/pacman.conf`

> originally made this for my friend @ModelCitizenPS3, who hates pacman syntax.

## install:

```shell
git clone <url> <dest>
cd <dest>
```

can be installed to `~/.local/bin`:
```
cp aptac ~/.local/bin
```
make sure that is in `$PATH` or install globally with `sudo` to `/usr/bin`

---

## usage:

```
NAME
  aptac - Wrapper for common pacman operations

SYNOPSIS
  aptac [GLOBAL_OPTIONS] <COMMAND> [OPTIONS]

DESCRIPTION
  aptac wraps common pacman operations for system package management.
  Mirrors concepts from Debian (install/uninstall) with pacman syntax.
  Options not listed below are passed through to the underlying tool.
  This means thin syntax shim, not modifying existing behaviors.
  Requires pacman, pacman-contrib, reflector, and elevation (sudo/doas/run0/su).

GLOBAL OPTIONS
  --no-color          Disable colored output

COMMANDS
  search PACKAGE [OPTIONS]        Search for packages (default command)
      --local, -l                 Search installed packages

  install PACKAGE [OPTIONS]       Install a package from sync repos
                                  Use "package-" to uninstall
  uninstall PACKAGE [OPTIONS]     Uninstall a package
      --no-deps                   Don't remove orphaned dependencies

  list [OPTIONS]                  List packages (-Sl)
      --local, -l                 List installed packages (-Q)

  info PACKAGE [OPTIONS]          Show detailed package information (-Si)
      --local, -l                 Query installed package (-Qi)

  deps PACKAGE [OPTIONS]          Show dependency tree (pactree)

  repos [CONF]                    List repos from pacman.conf (enabled/disabled)

  update [OPTIONS]                Force-sync package databases (-Syy)
  upgrade [OPTIONS]               Full system upgrade (-Syu)

  check [OPTIONS]                 Check for available updates (checkupdates)
  clean, sif [OPTIONS]            Clean old packages from cache (paccache -r)

  mirrors [OPTIONS]               Update mirrorlist using reflector, then -Syy
      --dry-run                   Print mirrors without saving or syncing

AUTHOR
  (O) Eihdran L. <hadean-eon-dev@proton.me>

SPDX-FileCopyrightText: 2026
SPDX-License-Identifier: 0BSD
```
