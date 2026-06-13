#!/bin/sh

test_description='clean and orphs'

. ./test-lib.sh

test_expect_success 'clean runs paccache -r' '
	reset_calls &&
	aptac --no-color clean >out &&
	grep_call "paccache -r"
'

test_expect_success 'clean passes flags through' '
	reset_calls &&
	aptac --no-color clean -k2 >out &&
	grep_call "paccache -r -k2"
'

test_expect_success 'orphs with none reports nothing and skips removal' '
	reset_calls &&
	aptac --no-color orphs >out &&
	grep -q "no orphans" out &&
	! grep_call "pacman -Rns"
'

test_expect_success 'orphs removes the found orphans (-Qdtq, then -Rns)' '
	reset_calls &&
	( export STUB_ORPHANS="foo bar" && aptac --no-color orphs >out ) &&
	grep_call "pacman -Qdtq" &&
	grep_call "pacman -Rns foo bar"
'

test_done
