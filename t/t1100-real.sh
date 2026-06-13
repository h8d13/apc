#!/bin/sh

test_description='real pacman integration for time-based listing

These run against the actual /var/lib/pacman/local and really install/remove a
package, so they are gated behind the REAL prereq: only with APTAC_REAL_TESTS=1
and root (CI). A plain run on a dev host SKIPs every test here.'

want_real=1
. ./test-lib.sh

test_expect_success REAL 'sync the package database' '
	pacman -Sy --noconfirm
'

test_expect_success REAL '--first 1 returns a real installed package line' '
	aptac --no-color list --first 1 >out &&
	tail -n 1 out >name &&
	test -s name &&
	grep -q -- - name
'

# The headline claim: installing a package bumps its local-db mtime, so it must
# surface as the single newest entry. Remove-then-install guarantees a fresh
# timestamp even if the runner already had it.
test_expect_success REAL 'a freshly installed package tops --last 1' '
	pacman -Rns --noconfirm tree 2>/dev/null || true &&
	test_when_finished "pacman -Rns --noconfirm tree 2>/dev/null || true" &&
	pacman -S --noconfirm tree &&
	aptac --no-color list --last 1 >out &&
	tail -n 1 out >name &&
	grep -q "^tree-" name
'

test_done
