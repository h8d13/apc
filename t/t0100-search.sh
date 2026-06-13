#!/bin/sh

test_description='search'

. ./test-lib.sh

test_expect_success 'search sync repos (-Ss)' '
	reset_calls &&
	aptac --no-color search firefox >out &&
	grep_call "pacman -Ss firefox"
'

test_expect_success 'search installed (-Qs) via --local' '
	reset_calls &&
	aptac --no-color search firefox --local >out &&
	grep_call "pacman -Qs firefox"
'

test_expect_success '-l is an alias for --local' '
	reset_calls &&
	aptac --no-color search firefox -l >out &&
	grep_call "pacman -Qs firefox"
'

test_expect_success 'search is the default command' '
	reset_calls &&
	aptac --no-color firefox >out &&
	grep_call "pacman -Ss firefox"
'

test_expect_success 'search with no package errors' '
	test_must_fail aptac search
'

test_done
