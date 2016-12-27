#!/usr/bin/env bash

# Commash hook library

#-------------------------------------------------------------------------------
# commash debug trap and prompt_command wrappers
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# locking
# TODO: add $$ to the lockfile for multple instances of bash running
# XXX is locking mandatory?

# XXX: make a different approach for SSD and/or RO mounted filesystem
csfunc_locked() {
	if [[ -f $cs_LOCKFILE ]]; then
		return 0 # true, not locked
	else
		return 1
	fi
}

csfunc_lock() {
	$TOUCH $cs_LOCKFILE
}

csfunc_unlock() {
	$RM -f $cs_LOCKFILE
}


#-------------------------------------------------------------------------------
# These functions are executed with every prompt. They are two because we
# execute previous PROMPT_COMMANDs between them:
# csfunc_preprompt; <old PROMPT_COMMAND>; csfunc_prompt

csfunc_preprompt() {
	csfunc_inside=1
}

# This function is executed by BASH every time the prompt is about to print.
# We use cspc_
csfunc_prompt() {
	csfunc_rc=$? # This must be the first command. Even before the debug.


	if [[ $cs_AUTOENABLE == 1 ]] && [[ $cspc_first == 1 ]]; then
		cspc_first=0

		echo ",: Autoenabling commash in the first PROMPT_COMMAND"

		cs_ENABLED=1
	fi

	# XXX: lock
	#csfunc_unlock


	if [[ $cs_DEBUGGER == 1 ]]; then
		csfunc_inside_debugger
	fi
	cspc_command_cnt=0



	# This will help us indicate the first run of the DEBUG trap.
	# The debug trap is called more than once per command.
	# This must be the last command
    csfunc_catch_command=1


    csfunc_inside=0
}
#-------------------------------------------------------------------------------

csfunc_ps1() {
	echo -n "[,]"
}

#-------------------------------------------------------------------------------
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
#-------------------------------------------------------------------------------



csfunc_debug_trap_enable() {
	PROMPT_COMMAND_BACKUP="$PROMPT_COMMAND"
	PROMPT_COMMAND=${PROMPT_COMMAND:-:}
	PROMPT_COMMAND="csfunc_preprompt;$PROMPT_COMMAND;csfunc_prompt"

	cs_PS1_BACKUP="$PS1"
	PS1="$(csfunc_ps1)$PS1"

	trap 'csfunc_debug_trap $LINENO' DEBUG

	# is there any scenaio we need this?
	#set -o functrace

	shopt -s extdebug

	# XXX lock
	#$RM -f $cs_LOCKFILE
}
csfunc_debug_trap_disable() {
	PROMPT_COMMAND="$PROMPT_COMMAND_BACKUP"
	PS1="$cs_PS1_BACKUP"
	trap - DEBUG
	shopt -u extdebug

	# XXX lock
	#$RM -f $cs_LOCKFILE
}

#-------------------------------------------------------------------------------
# Hooks.
# We want to make things modular. Some basic and checking functionality should
# be easily added.

csfunc_hook_add_before() {
	cs_HOOKS_BEFORE+=("$1")
}
csfunc_hook_add_after() {
	cs_HOOKS_AFTER+=("$1")
}

# The hook functions are called like this:
# <hook> <command timestamp> <command>
csfunc_hook_iterate_before() {
	local ret=0
	for i in "${!cs_HOOKS_BEFORE[@]}"; do
		if ! ${cs_HOOKS_BEFORE[$i]} "$1" "$2"; then
			ret=1
		fi
	done

	return $ret
}
csfunc_hook_iterate_after() {
	for i in "${!cs_HOOKS_AFTER[@]}"; do
		${cs_HOOKS_AFTER[$i]} "$1" "$2"
	done
}

#csfunc_hook_init() {
#	csfuncs_hook_source
#}

#-------------------------------------------------------------------------------

csfunc_restore_internals() {
	return $1
}

cs_add_timestamp() {
	while read -r line; do
    		echo "$(date +%Y-%m-%d-%H-%M-%S-%N)|$1|$line" >> /tmp/.cslog
    		echo "$line"
	done
}

cstest=XXX
csfunc_run_user_cmd() {
	cmd=$(HISTTIMEFORMAT='' history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//")
	cs_timestamp=$(date +%Y-%m-%d-%H-%M-%S-%N)

	if csfunc_hook_iterate_before "$cs_timestamp" "$cmd"; then



		>&2 echo "going to eval=\"$cmd\" rc=\"$cs_rc\" last=\"$cs_last\" test=$cstest"
csfunc_restore_internals $cs_rc \"$cs_last\"
		eval "
csfunc_restore_internals $cs_rc \"$cs_last\"

$cmd



cs_bash_internals=\"\${_}CSDELIMETER\${?}\"
"
		cs_rc=$(echo "$cs_bash_internals" | awk -F "CSDELIMETER" '{ print $2 }')
		export cs_rc
		cs_last=$(echo "$cs_bash_internals" | awk -F "CSDELIMETER" '{ print $1 }')
		export cs_last

		>&2 echo "cs_bash_internals=\"$cs_bash_internals\" cs_rc=\"$cs_rc\" cs_last=\"$cs_last\""

		csfunc_hook_iterate_after "$cs_timestamp" "$cmd"
	else
		>&2 echo ",: prevented execution of $cmd"
	fi


	>&2 echo "finished to eval=\"$cmd\" rc=\"$cs_rc\" last=\"$cs_last\""


}


csfunc_debug_trap() {
	cs_debug_trap_rc=$?

	# This seems to be a lineno of the shell like it is a script.
	# We mayme could(?) add another layer of protection against running a command
	# multiple times (i.e. the bug with scrot).
	cs_last_lineno=$cs_lineno
	cs_lineno=$1

	#---------------------------------------------------------------------------

	# If we control-c a command, we jump again into the debug trap
	# this is the right place to explain what happened.
	if (( cs_debug_trap_rc == 130 )) && (( cs_debug_trap_rc_ctrlc == 0 )); then
		cs_debug_trap_rc_ctrlc=1
		if type csfunc_rc >/dev/null 2>&1; then
			csfunc_rc $cs_debug_trap_rc
		fi

		# XXX lock
		# csfunc_unlock
		csfunc_inside=0
		return 1
	fi

	#---------------------------------------------------------------------------
	# These are cases where we execute the command.

	# Just execute the command if commash is not enabled
	if [[ $cs_ENABLED == 0 ]]; then
		return 0 # commash is disabled
	fi

	# bash executes ~/.bash_logout when login shell exits. We have a command
	# here to know that we're going to exit.
	if [[ $BASH_COMMAND == "cs_LOGOUT=1" ]]; then
		cs_ENABLED=0
		return 0
	fi

	# If we're executing internal commash functions, don't track them.
	if [[ $BASH_COMMAND =~ ^csfunc_ ]] || [[ $csfunc_inside == 1 ]]; then
		return 0
	fi

	# This is the case when you press the <tab> key and bash is trying to
	# autocomplete.
	if [[ -n $COMP_LINE ]]; then
		return 0
	fi

	if [[ $BASH_COMMAND == ":" ]]; then
		return 0
	fi

	# XXX
	if (( cs_last_lineno == cs_lineno )); then
		>&2 echo "XXX cs_last_lineno == cs_lineno == $cs_last_lineno == $cs_lineno"
		return 1
	fi

	#---------------------------------------------------------------------------

	# >&2 printf "DEBUGTRAP [line: %s] command: \"%s\"\n" "$1" "$BASH_COMMAND"

	#---------------------------------------------------------------------------

	# We will get error from set -u if we do not assign default values here.
	cs_rc=${cs_rc:-0}
	cs_last=${cs_last:-''}

	# These are some env variables that makes troubles too. Posible TODO:
	# is to set them all, and add a custom list of course. + TODO: make
	# the -u option optional
	# another approach I can imagine is to  hold a list of variables that
	# were set and set them again before every command so shellcheck
	# knows about them
	COMP_LINE=${COMP_LINE:-''}
	OLDPWD=${OLDPWD:-''}

	#---------------------------------------------------------------------------

	# Save BASH_COMMAND for allow debuger partial execution
	cs_command_arr[$cspc_command_cnt]="$BASH_COMMAND"
	(( cspc_command_cnt++ ))

	#---------------------------------------------------------------------------

	# XXX lock
	#if (( csfunc_catch_command == 1 )) && [[ ! -f $cs_LOCKFILE ]]; then
	if (( csfunc_catch_command == 1 )); then
		csfunc_catch_command=0

		# XXX lock
		#csfunc_lock

		# If we ctrlc this command, show the warning
		cs_debug_trap_rc_ctrlc=0

		# Get last command from history without its number
		cmd=$(HISTTIMEFORMAT='' history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//")

		# if debug mode is off, run the command
		if [[ $cs_DEBUG == 0 ]]; then

			# generate timestamp and use it as command identifier (for hooks)
			cs_timestamp=$(date +%Y-%m-%d-%H-%M-%S-%N)

			# Any _before hook can prevent command execution
			if csfunc_hook_iterate_before "$cs_timestamp" "$cmd"; then

				echo "[CSLOG|$cs_timestamp|cmd|\"$cmd\"]" >> $CSLOG

				#-------------------------------------------------------------------
				# This is where the commands are executed.
				# First, we want to exetuce a "blank" command to set the $_ variable.
				# Second, the actual command is executed.
				# Third, we want to save both $_ and $? variables.
				eval "

	if [[ -n \$COMP_LINE ]]; then
		echo \"COMP_LINE is empty\"
	fi

	set -u

	csfunc_restore_internals $cs_rc \"$cs_last\"

	$cmd

	cs_bash_internals=\"\${_}CSDELIMETER\${?}\"

	set +u

				"

		#>(cs_add_timestamp "out") 2>(cs_add_timestamp "err" >&2)

				cs_rc=$(echo "$cs_bash_internals" | awk -F "CSDELIMETER" '{ print $2 }')
				cs_last=$(echo "$cs_bash_internals" | awk -F "CSDELIMETER" '{ print $1 }')

				echo "[CSLOG|$cs_timestamp|rc|$cs_rc]" >> $CSLOG

				# FIXME: multiline commands?
				#echo "$cs_timestamp \"$cmd\" $cs_rc $(pwd)" >> $cs_LOGFILE

				csfunc_hook_iterate_after "$cs_timestamp" "$cmd"
			fi
		else
			echo ",: commash prevented execution of: \"$cmd\""
			echo ",: going to the debugger mode"

			cs_DEBUGGER=1
		fi # cs_DEBUG == 0

	fi

	#---------------------------------------------------------------------------

	return 1
}


#-------------------------------------------------------------------------------

csfunc_check_var() {
	eval "v=\$$1"
	if [[ -z "$v" ]]; then
		echo "commash: VAR $1 is not loaded. $cs_ROOTDIR"
	fi
}

csfunc_lib_hooks_load() {
	csfunc_check_var cs_ROOTDIR

	cs_HOOKS_BEFORE=()
	cs_HOOKS_AFTER=()
	cs_HOOKS_DIR=$cs_ROOTDIR/hooks


	# TODO: add a comment what is this and why we need that
	cspc_first=1
	cspc_command_cnt=0

	for hookfile in $cs_HOOKS_DIR/cshook_*.sh; do
		source $hookfile
	done

}

csfunc_lib_hooks_unload() {
	:
}








