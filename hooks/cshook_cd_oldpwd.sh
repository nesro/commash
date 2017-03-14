#!/usr/bin/env bash
# https://github.com/nesro/commash

# TODO: this is obsolete, because we can handle this in commash_cd function

cshook_cd_oldpwd_before() {
	local timestamp="$1"
	local cmd="$2"

	if [[ -n "$OLDPWD" ]] && [[ $cmd =~ cd\ $OLDPWD ]]; then
		echo ",tip: You can use \"cd -\" to go back to the old pwd. This is stored in the \$OLDPWD variable."
	fi
}

# csfunc_hook_add_before 1000 'cshook_cd_oldpwd_before'
