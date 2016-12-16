#!/usr/bin/env bash

# Commash internal debugging

# TODO I'd love to debug only _some_ functions. Not just all/nothing.
# I tried I really did, but nothing worked as intended.
# This works well and I can do some other things finally.
# XXX: well actually, there is a weird bug with negative line numbers.

set +x

cs_ps4() {
	retcode=$?
	# The \r character is important here. It seems that bash print some
	# mess before printing PS4 so we need to get rid of this.
	echo -en "\r\e[31mDEBUG: \e[0m"
	printf "[%s][%40s]" $retcode $1
	for (( i=0; i < ${#FUNCNAME[@]} ; i++ )); do echo -n "|---"; done
}

export PS4='$(cs_ps4 "${BASH_SOURCE##*/}:${FUNCNAME[0]}:${LINENO}")'

