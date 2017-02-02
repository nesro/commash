#!/usr/bin/env bash
# https://github.com/nesro/commash

# Commash internal debugging

# TODO I'd love to debug only _some_ functions. Not just all/nothing.
# I tried I really did, but nothing worked as intended.
# This works well and I can do some other things finally.
# XXX: well actually, there is a weird bug with negative line numbers.

csfunc_dbg_echo() {
	# just save 2 lines in debug output
	# { set +x; } 2>/dev/null # what if xtrace is on but cs_XTRACE is not?
	cs_XTRACE=${cs_XTRACE:-}
	if [[ -n "$cs_XTRACE" ]]; then
		>&2 echo ",DBG: $1"
		set -x
	fi
}

csfunc_ps4() {
	local retcode=$?
	# local fromfile="$1" # we have nice function names, no need for files rn
	local fromfunction="$2"

# I tried some magic with deleting output of xtrace but it failed for the output
# over multiple lines. I'm not going to waste my time anymore for now.
#echo -en "$(tput cuu1)\r"

	# The \r character is important here. It seems that bash print some
	# mess before printing PS4 so we need to get rid of this.
	>&2 echo -en "\r\e[31mDEBUG: \e[0m"

	>&2 printf "[%s][%20s]" "$retcode" "${fromfunction:4:24}"
	for (( i=0; i < ${#FUNCNAME[@]} ; i++ )); do
			>&2 echo -n "|---";
	done
	>&2 echo -n ": "

	# >&2 echo -n "(BC $BASH_COMMAND) "
	# >&2 printf '(FN %s) ' "${FUNCNAME[@]}"
}

# LINENO is not working as intended because we run pretty much everything
# from DEBUG trap.
#export PS4='$(cs_ps4 "${BASH_SOURCE##*/}:${FUNCNAME[0]}:${LINENO}:${BASH_LINENO[*]}")'
export PS4='$(csfunc_ps4 "${BASH_SOURCE##*/}" "${FUNCNAME[0]}")'
