#!/usr/bin/env bash

main() {
	local passed=0
	local failed=0

	if ! [[ -d ~/.commash/tests/ ]]; then
		>&2 echo ",: except tests are not in ~/.commash/tests/ ?"
		return 1
	fi

	for m in norc default; do
		for t in ~/.commash/tests/test_*.tcl ; do
			>&2 echo -n "running test $t with mode $m - "
			if $t $m >/dev/null 2>&1; then
				>&2 echo "passed!"
				(( passed++ ))
			else
				>&2 echo "failed!"
				(( failed++ ))
			fi
			sleep 1
		done
	done

	echo "tests: passed=$passed failed=$failed"
}

main
