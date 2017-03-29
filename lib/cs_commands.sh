#!/usr/bin/env bash
# https://github.com/nesro/commash

# Commash command library
#
# Create a set of commands allowing to control/set commash environment.

#-------------------------------------------------------------------------------


csfunc_help() {
	cat <<EOF
Comma-shell (commash) - an interactive shell debugger and helper

1) debugger
,don - debug every command
,doff - turn off debugging of every command
,dnext - debug just the next command
,d - debug the last command

(i will add more later)

EOF

}
alias ,h=csfunc_help
alias ,help=csfunc_help



# this is a little obsolete now
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
# cs_SAFE=0
csfunc_safe() {
	csfunc_inside=1
	# cs_SAFE=$1

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
# alias ,d=", d"

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
	>&2 echo ",: commash is enabled, run ,h or ,help for help"
}

#-------------------------------------------------------------------------------

# FIXME: add normal paths..
csfunc_shellcheck_selftest() {

	csfunc_var cs_ROOTDIR
	csfunc_var cs_SHELLCHECK

	# it seems that shellcheck isn't good in resolving paths (f.ex. unused
	# variables). so we just pre-create a single file
	# ~/.cabal/bin/shellcheck -x ~/.commash/comma.sh ~/.commash/lib/cs_*.sh

	# this is useless because we want to know in what files are the errors in
	# ~/.cabal/bin/shellcheck <(cat $(find $cs_ROOTDIR -iname '*.sh' -not -path './tmp/*'))

	local a="$cs_ROOTDIR/tmp/cs_all_in_one.sh"
	echo "#!/usr/bin/env bash" > $a
	find $cs_ROOTDIR -iname "*.sh" -not -path "$cs_ROOTDIR/tmp/*" -exec sh -c '
		echo ",selftest: adding $1 into '$a'"
		echo "# file: $1" >> '$a'
		cat $1 >> '$a'
	' sh {} \;
	if ~/.cabal/bin/shellcheck $a; then
		echo ",selftest: All good. :)"
	else
		echo ",selftest: ShellCheck found some issues. Look into $a and find the "
		 "file where the error is. Or just search through all project."
	fi
}
alias ,selftest="csfunc_shellcheck_selftest"
alias ,st="csfunc_shellcheck_selftest"

#-------------------------------------------------------------------------------

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
# debugger commands

csfunc_debugger_on() {
	cs_debugger_on=1
	echo ",: turning debugger on"
}
alias ,don="csfunc_debugger_on"

csfunc_debugger_off() {
	cs_debugger_on=0
	echo ",: turning debugger off"
}
alias ,doff="csfunc_debugger_off"

csfunc_debugger_next() {
	cs_debugger_on=1
	cs_debugger_disable_after=1
	echo ",: turning debugger on for the next command"
}
alias ,dnext="csfunc_debugger_next"

csfunc_debugger_last() {
	echo "debuggin last"
	csfunc_debugger
}
alias ,d="csfunc_debugger_last"

#-------------------------------------------------------------------------------

# Commash wrapper for screen recording and saving it as a gif
#
# until https://github.com/icholy/ttygif/ gets better CLI options
# we want to have a nice wrapper
csfunc_ttyrec() {
	if ! type ttyrec >/dev/null 2>&1; then
		echo ",ttyrec: ttyrec is not installed, you can install it by typing:" \
			" sudo apt install ttyrec"
		return
	fi

	if ! type ttygif >/dev/null 2>&1; then
		echo ",ttyrec: ttygif is not installed, you can install it from: " \
			"https://github.com/marcioAlmada/ttygif"
	fi

	echo ",ttyrec: Commash wrapper for ttyrec and ttygif. Press any key to " \
		"start a new shell. Exit with Ctrl-D and then wait to animation to finish."
	csfunc_anykey

	if ! ttyrec /tmp/rec; then
		echo ",ttyrec: ttyrec /tmp/rec failed"
		return
	fi
	if ! ttygif /tmp/rec; then
		echo ",ttyrec: ttygif /tmp/rec failed"
		return
	fi

	if [[ -n $1 ]]; then
		echo ",ttyrec: Moving tty.gif to $1"
		mv tty.gif "$1"
	fi
}
alias ,ttyrec="csfunc_ttyrec"
