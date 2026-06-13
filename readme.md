# aptac

mirror apt style commands for pacman

notably my favorite detail:

`./aptac install fastfetch-`

which uninstalls note the `-`.

=======

only rule is to modify syntax, not modify pacman behavior (too much).

i'm also hoping reading src code could teach some things
this means every arg passes through to the next tool:

```
./aptac --help

./aptac search --help
```

this second example will just get the pacman help.

all dependencies are: `pacman-contrib, reflector`

=======

some details:

all your pacman settings are found in `/etc/pacman.conf`
