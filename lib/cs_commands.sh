#!/usr/bin/env bash

# Commash command library
#
# Create a set of commands allowing to control/set commash environment.

#-------------------------------------------------------------------------------

cs_usage() {
	bold=$(tput bold)
	normal=$(tput sgr0)

	cat <<EOF
${bold}Comma-shell, an interactive shell debugger${normal}
https://github.com/nesro/commash

Usage:
	,debug
	,d
		debug mode

	,ndebug
	,nd
		turn off debug mode

	,safe
	,s
		turn on safe mode

	,nsafe
	,ns
		turn off safe mode

	, <command>
		debug only this command

	,usage
	,u
		show this usage

	,exit
	,x
	ctrl + x
		cleanup and logout from shell

EOF
}
alias ,usage="cs_usage"
alias ,u=",usage"

#-------------------------------------------------------------------------------

# handle the ctrl-x bind
csfunc_exit() {
	cs_ENABLED=0
	logout
}
alias ,exit="csfunc_exit"
alias ,x=",exit"

#-------------------------------------------------------------------------------

# enable/disable safe mode
# TODO: add more levels of safe mode
cs_SAFE=0
csfunc_safe() {
	csfunc_inside=1
	cs_SAFE=$1

	if [[ $1 == 1 ]]; then
		PATH="$cs_SAFEDIR:$PATH"
		echo ",: safe mode enabled. PATH is \"$PATH\""
	else
		PATH=$(echo "$PATH" | $SED "s/$cs_SAFEDIR_SED://")
		echo ",: safe mode disabled. PATH is \"$PATH\""
	fi
	csfunc_inside=0
}
alias ,safe="csfunc_safe 1"
alias ,s=",safe"
alias ,nsafe="csfunc_safe 0"
alias ,ns=",nsafe"

#-------------------------------------------------------------------------------

# This will be used in the debug trap
# TODO: maybe turn off the debug trap at all?
cs_enable() {
	cs_ENABLED=1
	echo ",: Automatic hooks has been enabled."
}

cs_disable() {
	cs_ENABLED=0
	echo ",: Automatic hooks has been disabled."
}

cs() {
	[[ $cs_INTERNAL_DEBUG =~ comma|all ]] && set -xv

	local arg="$1"

	case $arg in
	e|enable)
		cs_enable "$@"
		;;
	d|disable)
		cs_disable "$@"
		;;
	D|DEBUG)
		#FIXME
		if [[ -z "$2" ]]; then
			set +xv
		fi
		cs_INTERNAL_DEBUG="$2"
		;;
	i|info)
		echo "enabled: $cs_ENABLED"
		;;
	u|uninstall)
		cs_run_uninstall
		;;
	*)
		echo ",:  usage: , [edi]"
		echo ",: cs_DEBUG=$cs_DEBUG"
		;;
	esac
}

# BASH allows us to name our functions with , in their name, but shellcheck
# does not like it. And it would be shame if this script would not be shellcheck
# nice.
alias ,="cs"
alias ,e=", e"
alias ,d=", d"

csfunc_debug() {
	csfunc_inside=1

	cs_DEBUG="$1"
	echo ",: commash debug has been set to: \"$1\""

	csfunc_inside=0
}
alias ,debug="csfunc_debug 1"
alias ,d=",debug"
alias ,ndebug="csfunc_debug 0"
alias ,nd=",ndebug"
alias ,n=",nd"

#-------------------------------------------------------------------------------

csfunc_welcome() {
	cat <<EOF
	,: Commash has been loaded. But it's disabled by default.
	,: You can enable it by running: ", enable" (or just ", e" )
EOF
}

#-------------------------------------------------------------------------------

# FIXME: add normal paths..
csfunc_shellcheck_selftest() {
	~/.cabal/bin/shellcheck -x ~/.commash/comma.sh ~/.commash/lib/cs_*.sh
}
alias ,selftest="csfunc_shellcheck_selftest"

csfunc_expect_test() {
	echo ",: running expect tests from: $cs_ROOTDIR/tests/run.sh"
	"$cs_ROOTDIR/tests/run.sh"
}
alias ,expect="csfunc_expect_test"

#-------------------------------------------------------------------------------

#csfunc_load_lib() {
#}

#-------------------------------------------------------------------------------
export cs_XTRACE=
csfunc_xtrace_on() {
	export cs_XTRACE=1
	echo ",: Turning debugging on! If you want to debug commash initialization \
reload commash with the command: ,r"
	set -x
}
alias ,xon="csfunc_xtrace_on"

csfunc_xtrace_off() {
	{ set +x; } 2>/dev/null
	cs_XTRACE=
}
alias ,xoff="csfunc_xtrace_off"

#-------------------------------------------------------------------------------
