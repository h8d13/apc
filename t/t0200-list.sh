#!/bin/sh

test_description='list and its query modes'

. ./test-lib.sh

test_expect_success 'list sync packages (-Sl)' '
	reset_calls &&
	aptac --no-color list >out &&
	grep_call "pacman -Sl"
'

test_expect_success '--local lists installed (-Q)' '
	reset_calls &&
	aptac --no-color list --local >out &&
	grep_call "pacman -Q"
'

test_expect_success '--explicit (-Qe)' '
	reset_calls &&
	aptac --no-color list --explicit >out &&
	grep_call "pacman -Qe"
'

test_expect_success '--files PKG lists owned files (-Ql)' '
	reset_calls &&
	aptac --no-color list --files bash >out &&
	grep_call "pacman -Ql bash"
'

test_expect_success '--why PATH finds owner (-Qo)' '
	reset_calls &&
	aptac --no-color list --why /bin/sh >out &&
	grep_call "pacman -Qo /bin/sh"
'

test_expect_success 'short aliases -l/-e/-f/-w match their long forms' '
	reset_calls && aptac --no-color list -l >out && grep_call "pacman -Q" &&
	reset_calls && aptac --no-color list -e >out && grep_call "pacman -Qe" &&
	reset_calls && aptac --no-color list -f bash >out && grep_call "pacman -Ql bash" &&
	reset_calls && aptac --no-color list -w /bin/sh >out && grep_call "pacman -Qo /bin/sh"
'

# --first/--last read local-db dir mtimes, not pacman. Build a fake db ordered
# in time and point PACMAN_LOCAL at it. ALPM_DB_VERSION must be filtered out.
test_expect_success 'set up a fake local db ordered by mtime' '
	mkdir -p db &&
	: >db/ALPM_DB_VERSION &&
	mkdir db/old-1.0-1 db/mid-1.0-1 db/new-1.0-1 &&
	touch -d "2020-01-01" db/old-1.0-1 &&
	touch -d "2021-01-01" db/mid-1.0-1 &&
	touch -d "2022-01-01" db/new-1.0-1
'

test_expect_success '--last shows newest first, drops ALPM_DB_VERSION' '
	cat >expect <<-EOF &&
	==> listing newest installed packages...
	new-1.0-1
	mid-1.0-1
	EOF
	PACMAN_LOCAL="$PWD/db" aptac --no-color list --last 2 >out &&
	test_cmp expect out
'

test_expect_success '--first shows oldest first' '
	cat >expect <<-EOF &&
	==> listing oldest installed packages...
	old-1.0-1
	mid-1.0-1
	EOF
	PACMAN_LOCAL="$PWD/db" aptac --no-color list --first 2 >out &&
	test_cmp expect out
'

test_done
