#!/usr/bin/env bash

cs_explain_rc() {
	local rc=$1

	case $rc in
	1)
		echo "(General error)"
		;;
	2)
		# FIXME: this is not working properly, because command with this rc
		# is not in the history
		echo "(Misuse of shell builtins)"
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
		echo "(no explanation)"
		;;
	esac
}

csfunc_rc() {
	local rc=$1

	# Don't print about command not found when there is an active hook for it
	if (( rc == 127 )) && [[ -n "$cs_HOOK_NOTFOUND_ACTIVE" ]]; then
		return
	fi

	echo ",: return code warning: \$? == $rc $(cs_explain_rc "$rc")"
}

cshook_explain_rc_after() {
	if (( cs_rc > 0 )); then
		csfunc_rc "$cs_rc"
	fi
}

csfunc_hook_add_after 1000 'cshook_explain_rc_after'
