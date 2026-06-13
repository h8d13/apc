#!/bin/sh

test_description='help, version, and default-command dispatch'

. ./test-lib.sh

# Read the version from the script instead of hardcoding it, so a bump doesn't
# break the suite.
ver=$(sed -n 's/^VER_STRING="\(.*\)"/\1/p' "$APTAC")

test_expect_success 'no args prints the help block' '
	aptac >out &&
	grep -q "aptac - Wrapper for common pacman" out
'

test_expect_success 'help renders the synopsis and commands' '
	aptac help >out &&
	grep -q "SYNOPSIS" out &&
	grep -q "COMMANDS" out
'

test_expect_success '--version prints version and runs pacman -V' '
	reset_calls &&
	aptac --version >out &&
	grep -q "aptac $ver" out &&
	grep_call "pacman -V"
'

test_expect_success '-h and -v / version are aliases for help and version' '
	aptac -h >out && grep -q "SYNOPSIS" out &&
	aptac version >out && grep -q "aptac $ver" out &&
	aptac -v >out && grep -q "aptac $ver" out
'

test_expect_success 'unknown command falls back to search' '
	reset_calls &&
	aptac --no-color bash >out &&
	grep_call "pacman -Ss bash"
'

test_expect_success '--no-color strips ANSI from op lines' '
	aptac --no-color list --local >out &&
	! grep -q "$(printf "\033")" out
'

test_done
