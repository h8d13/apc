#!/bin/sh
# Minimal test harness for aptac, modeled on git's t/test-lib.sh (a small
# subset). A test script sets test_description, sources this file, runs
# test_expect_success blocks, and ends with test_done. Run from within t/.
#
# It puts fake pacman/sudo/checkupdates/... on PATH that only LOG their argv
# (to $APTAC_CALLS). aptac is a thin wrapper, so the unit under test is "did
# aptac invoke the right underlying command", which the call log captures
# without ever touching the real system.

# Resolve paths (TEST_DIRECTORY = the t/ dir, APTAC = binary under test).
TEST_DIRECTORY=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
APTAC="${APTAC:-$TEST_DIRECTORY/../aptac}"
if ! test -f "$APTAC"; then
	echo "Bail out! aptac not found at $APTAC"
	exit 1
fi

# Options
verbose= immediate=
for opt in "$@"; do
	case "$opt" in
	-v | --verbose) verbose=t ;;
	-i | --immediate) immediate=t ;;
	-h | --help)
		echo "usage: $0 [-v] [-i]"
		exit 0
		;;
	*)
		echo "unknown option: $opt" >&2
		exit 1
		;;
	esac
done

# TAP counters
test_count=0 test_success=0 test_failure=0

# Body stdout/stderr go to fd3/4: shown only under -v, so TAP on fd1 stays clean.
if test -n "$verbose"; then
	exec 3>&1 4>&2
else
	exec 3>/dev/null 4>/dev/null
fi

# Prereqs: a test may carry an optional PREREQ (or !PREREQ) as its first arg.
satisfied_prereq=" "
test_set_prereq() { satisfied_prereq="$satisfied_prereq$1 "; }
test_have_prereq() {
	p=$1
	test -z "$p" && return 0
	neg=
	case "$p" in !*)
		neg=t
		p=${p#!}
		;;
	esac
	case "$satisfied_prereq" in
	*" $p "*) test -z "$neg" ;;
	*) test -n "$neg" ;;
	esac
}
test "$(id -u)" = 0 && test_set_prereq ROOT

# Per-test cleanup, run whether the body passed or failed (like git's).
test_cleanup=:
test_when_finished() { test_cleanup="{ $*; }; $test_cleanup"; }

test_expect_success() {
	if test $# -eq 3; then
		prereq=$1
		shift
	else
		prereq=
	fi
	test_count=$((test_count + 1))
	if ! test_have_prereq "$prereq"; then
		echo "ok $test_count - $1 # SKIP (prereq $prereq)"
		return
	fi
	test_cleanup=:
	if eval >&3 2>&4 "$2" && eval >&3 2>&4 "$test_cleanup"; then
		test_success=$((test_success + 1))
		echo "ok $test_count - $1"
	else
		eval >&3 2>&4 "$test_cleanup" || :
		test_failure=$((test_failure + 1))
		echo "not ok $test_count - $1"
		test -n "$immediate" && {
			echo "Bail out! failed: $1"
			exit 1
		}
	fi
}

# Inverted expectation: succeeds only if the command FAILS (non-zero).
test_must_fail() {
	"$@"
	ret=$?
	if test $ret -eq 0; then
		echo "test_must_fail: command unexpectedly succeeded: $*" >&4
		return 1
	fi
	return 0
}

test_cmp() { diff -u "$@"; }

test_done() {
	echo "1..$test_count"
	if test "$test_failure" -gt 0; then
		echo "# failed $test_failure of $test_count tests" >&2
		exit 1
	fi
	exit 0
}

# --- sandbox: trash dir + fake tools on PATH -------------------------------
# Space in the name is deliberate: it catches quoting bugs, same as git's suite.
TRASH_DIRECTORY="$TEST_DIRECTORY/trash directory.$(basename "$0" .sh)"
rm -rf "$TRASH_DIRECTORY"
mkdir -p "$TRASH_DIRECTORY/bin"
APTAC_CALLS="$TRASH_DIRECTORY/calls"
: >"$APTAC_CALLS"
export APTAC_CALLS

# A script that sets want_real=1 before sourcing runs against the REAL system
# tools (no stubs). Those tests carry the REAL prereq, which only fires with an
# explicit CI opt-in (APTAC_REAL_TESTS) AND root, since they mutate package
# state. So a plain `sh run.sh` on a dev host SKIPs them.
if test -n "$want_real"; then
	if test -n "$APTAC_REAL_TESTS" && command -v pacman >/dev/null 2>&1 && test "$(id -u)" = 0; then
		test_set_prereq REAL
	fi
	aptac() { "$APTAC" "$@"; }
	reset_calls() { : >"$APTAC_CALLS"; }
	grep_call() { grep -F -- "$1" "$APTAC_CALLS"; }
	cd "$TRASH_DIRECTORY" || exit 1
	return 0 2>/dev/null || true
fi

# Fake pacman: log argv; only the cases aptac READS back produce real output.
#   STUB_ORPHANS    space-list returned for -Qdtq (empty => exit 1, like real)
#   STUB_PACMAN_RC  exit code for everything else (default 0)
cat >"$TRASH_DIRECTORY/bin/pacman" <<'STUB'
#!/bin/sh
echo "pacman $*" >>"$APTAC_CALLS"
case " $* " in
*" -Qdtq "*)
	test -n "$STUB_ORPHANS" || exit 1
	printf '%s\n' $STUB_ORPHANS
	;;
*" -V "*) echo "Pacman v0.0-fake" ;;
esac
exit "${STUB_PACMAN_RC:-0}"
STUB

# Fake checkupdates: rc 0 => updates (STUB_UPDATES printed), 2 => up to date,
# 1 => real error. Mirrors the exit-code contract aptac relies on.
cat >"$TRASH_DIRECTORY/bin/checkupdates" <<'STUB'
#!/bin/sh
echo "checkupdates $*" >>"$APTAC_CALLS"
test -n "$STUB_UPDATES" && printf '%s\n' "$STUB_UPDATES"
exit "${STUB_CHECK_RC:-0}"
STUB

# Log-only stubs.
for t in paccache pactree reflector; do
	cat >"$TRASH_DIRECTORY/bin/$t" <<STUB
#!/bin/sh
echo "$t \$*" >>"\$APTAC_CALLS"
exit 0
STUB
done

# Elevation tools: transparent, so the wrapped command still hits its stub and
# the logged line is identical whether or not the suite runs as root.
for t in sudo doas run0; do
	cat >"$TRASH_DIRECTORY/bin/$t" <<'STUB'
#!/bin/sh
exec "$@"
STUB
done

chmod +x "$TRASH_DIRECTORY/bin/"*
PATH="$TRASH_DIRECTORY/bin:$PATH"
export PATH

# Test-facing helpers.
aptac() { "$APTAC" "$@"; }
reset_calls() { : >"$APTAC_CALLS"; }
grep_call() { grep -F -- "$1" "$APTAC_CALLS"; }

cd "$TRASH_DIRECTORY" || exit 1
