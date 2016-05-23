#!/bin/bash

# TODO: parse all arguments, not just the last

cshook_last_argument_tip_before() {
	local timestamp="$1"
	cshook_last_argument_tip_last=$cs_last
}

cshook_last_argument_tip_after() {
	local timestamp="$1"

	if [[ $cshook_last_argument_tip_last == "$cs_last" ]]; then		
		echo ",tip: Your last argument was the same as in the previous command. You can use the \$_ variable for it."
	fi
}

csfunc_hook_add_before 'cshook_last_argument_tip_before'
csfunc_hook_add_after 'cshook_last_argument_tip_after'

