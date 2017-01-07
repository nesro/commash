#-------------------------------------------------------------------------------
# DEBUG TRAP2

# $1 == command to execute
csfunc_debug_trap_command() {
	cmd=$(HISTTIMEFORMAT='' history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//")
	>&2 echo "debug: $cmd"

	eval "$cmd"
}

# $1 == $LINENO
csfunc_debug_trap2() {
	cs_debug_trap_rc=$?

	if [[ $cs_trap_on == 1 ]]; then

		>&2 echo "t. 1=$1 lln=$last_lineno bc=$BASH_COMMAND"

		if (( cs_debug_trap_rc == 130 )); then
			>&2 echo "ctrl-c!"
		fi

		if (( $1 > last_lineno )); then
			csfunc_debug_trap_command
			last_lineno=$1
		fi
		return 1
	else
		return 0
	fi
}
