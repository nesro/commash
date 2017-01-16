#!/usr/bin/env bash

# XXX: I don't know if this entire hook is a good idea. It can cause more
# problems than benefits.
# If it should work good, it must fire just in the right situations.

# TODO: parse all arguments, not just the last

cshook_last_argument_tip_before() {
	local timestamp="$1"
	local cmd="$2"

	cshook_last_argument_tip_last=$cs_last
}

cshook_last_argument_tip_after() {
	local timestamp="$1"
	local cmd="$2"

	# TODO: don't fire on arguments too, like: ls -l
	# TODO: show this tip only once
	if (( $(IFS=' '; set -f -- $cmd; echo $#) > 1 )) && [[ $cshook_last_argument_tip_last == "$cs_last" ]]; then
		echo ",tip: Your last argument was the same as in the previous command. You can use the \$_ variable for it."
	fi
}

#csfunc_hook_add_before 'cshook_last_argument_tip_before'
#csfunc_hook_add_after 'cshook_last_argument_tip_after'
