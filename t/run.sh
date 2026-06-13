#!/bin/sh
# Run every t[0-9]*.sh, stream a per-script result with pass/skip counts, and
# exit non-zero if any script failed. Full TAP for each script is kept in
# t/<script>.log. Output is TAP, so `(cd t && prove ./t[0-9]*.sh)` also works.
# Pass -v to surface each test body's output live.

cd "$(dirname "$0")" || exit 1
ret=0
for t in t[0-9]*.sh; do
	test -f "$t" || continue
	if sh "$t" "$@" >"$t.log" 2>&1; then
		status=PASS
	else
		status=FAIL
		ret=1
	fi

	# ^ok counts both real passes and skips (skips are "ok N # SKIP").
	ok=$(grep -c '^ok ' "$t.log")
	skip=$(grep -c '# SKIP' "$t.log")
	fail=$(grep -c '^not ok' "$t.log")
	passed=$((ok - skip))

	summary="$passed passed"
	test "$skip" -gt 0 && summary="$summary, $skip skipped"
	test "$fail" -gt 0 && summary="$summary, $fail failed"
	echo "$status $t ($summary)"

	# On failure, surface the offending lines inline; full TAP is in $t.log.
	if test "$status" = FAIL; then
		grep -E '^(not ok|Bail out!|# )' "$t.log" | sed 's/^/    /'
	fi
done
exit $ret
