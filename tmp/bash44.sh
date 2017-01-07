#!/usr/bin/env bash

# I'll test it sideways before putting it into ,sh
# http://stromberg.dnsalias.org/~strombrg/PS0-prompt/


# XXX XXX XXX
# There is a major problem with this approach. If we run the "main code"
# from: PS0='$(csfunc_ps0)\n'
# all happens in a subshell and we cannot easily modify global variables
# like _ and ?

#-------------------------------------------------------------------------------

CS_BASH_VERSION=
csfunc_bash_version() {
	case $BASH_VERSION in
	4.4*)
		echo "You have BASH 4.4. Nice!"
		CS_BASH_VERSION=44
		;;
	4.3*)
		echo "You have BASH 4.3. That's ok, but you're old. :P"
		CS_BASH_VERSION=43
		;;
	*)
		echo "either you're not using bash, or you use some really old version"
		;;
	esac
}

#-------------------------------------------------------------------------------

# XXX this will work only for bash 4.4+

ps0cnt=0

# and here we're gonna run our commands!
csfunc_ps0() {
	csfunc_inside=1

	cmd="$(HISTTIMEFORMAT='' history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//")"

	ps0cnt=$(( ps0cnt + 1 ))

	>&2 echo ",: cmd=\"$cmd\" ps0cnt=$ps0cnt"

	eval "$cmd"

	csfunc_inside=0
}
PS0='$(csfunc_ps0)\n'

# Only internal commands will work
csfunc_debug_trap() {
	if [[ $BASH_COMMAND =~ ^csfunc_ ]] || [[ $csfunc_inside == 1 ]]; then
		return 0
	fi
	return 1
}

#-------------------------------------------------------------------------------

main() {
	csfunc_bash_version

	if [[ $CS_BASH_VERSION == 44 ]]; then
		shopt -s extdebug
		trap 'csfunc_debug_trap' DEBUG
	else
		>&2 echo "this is bash 4.4 test..."
	fi
}

main

# trash from main  source that don't work how I want
if false; then

	# BASH 4.4 pre-post cmd
	csfunc_ps0() {
		csfunc_inside=1
		trap '' DEBUG
		#>&2 echo "[PS0]"

		csfunc_run_user_cmd

		trap 'csfunc_debug_trap44' DEBUG
		csfunc_inside=0
	}
	PS0='$(csfunc_ps0)\n'
	csfunc_debug_trap44() {
		#>&2 echo "BASH_COMMAND=\"$BASH_COMMAND\" csfunc_inside=\"$csfunc_inside\""
		if [[ $BASH_COMMAND =~ ^csfunc_ ]] || [[ $csfunc_inside == 1 ]]; then
			return 0
		fi
		return 1
	}
	csfunc_debug_trap_enable44() {
		shopt -s extdebug
		trap 'csfunc_debug_trap44' DEBUG
	}

fi
