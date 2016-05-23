#!/bin/bash

cshook_cd_oldpwd_before() {
	local timestamp="$1"
	local cmd="$2"
	
	if [[ -n "$OLDPWD" ]] && [[ $cmd =~ "cd $OLDPWD" ]]; then
		echo ",tip: You can use \"cd -\" to go back to the old pwd. This is stored in the \$OLDPWD variable."
	fi
}

csfunc_hook_add_before 'cshook_cd_oldpwd_before'

