#!/usr/bin/env bash

# TODO: more modular explanation for particular commands

csfunc_explain_rc_none() {
	echo "(no explanation)"
}

cs_explain_rc() {
	local rc=$1
	local cmd="$2"

	case $rc in
	1)
		echo "(General error)"
		;;
	2)
		# FIXME: this is not working properly, because command with this rc
		# is not in the history
		echo "(Misuse of shell builtins)"
		;;
	16)
		if [[ $cmd =~ ^man ]]; then
			echo "(At least one of the pages/files/keywords didn't exist or wasn't matched.)"
		else
			csfunc_explain_rc_none
		fi
		;;
	126)
		echo "(Command invoked cannot execute)"
		;;
	127)
		echo "(Command not found)"
		;;
	# TODO: Parse and show all signals
	# 12[8-9]|13[0-9])
	#	echo "(Fatal error signal: 0)"
	#	;;
	130)
		echo "(Script terminated by Control-C)"
		;;
	148)
		echo "(Control-Z)"
		;;
	*)
		csfunc_explain_rc_none
		;;
	esac
}

csfunc_rc() {
	local rc=$1
	local cmd="$2"

	# Don't print about command not found when there is an active hook for it
	if (( rc == 127 )) && [[ -n "$cs_HOOK_NOTFOUND_ACTIVE" ]]; then
		return
	fi

	echo ",: return code warning: \$? == $rc $(cs_explain_rc "$rc" "$cmd")"
}

cshook_explain_rc_after() {
	local timestamp="$1"
	local cmd="$2"

	if (( cs_rc > 0 )); then
		csfunc_rc "$cs_rc" "$cmd"
	fi
}

csfunc_hook_add_after 1000 'cshook_explain_rc_after'
