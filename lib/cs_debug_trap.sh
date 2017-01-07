#!/usr/bin/env bash

# Workaround over a DEBUG trap so that we can trigger our code for every command
# run from a command line

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

  # this is redundat if there was some PROMPT_COMMAND before. but this
  # just simplyfies everything
  csfunc_inside=1

	if [[ $cs_AUTOENABLE == 1 ]] && [[ $cspc_first == 1 ]]; then
		cspc_first=0

		echo ",: Autoenabling commash in the first PROMPT_COMMAND"

		cs_ENABLED=1
	fi

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

# This function is used to restore the $? and $_ variables just before executing
# a command. It's second argument, which will not be used will be treated
# as the $_ variable.
csfunc_restore_internals() {
	return $1
}

#-------------------------------------------------------------------------------

csfunc_debug_trap() {
	cs_debug_trap_rc=$?

  # cs_RUN == 1 : the command will be executed normally
  # cs_RUN == 0 : no command will be executed
  cs_RUN=0

#cmd=$(HISTTIMEFORMAT='' history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//")
#>&2 printf "DEBUGTRAP BASH_COMMAND=\"%30s\" cmd=\"%s\"\n" "$BASH_COMMAND" "$cmd"

	# This seems to be a lineno of the shell like it is a script.
	# We mayme could(?) add another layer of protection against running a command
	# multiple times (i.e. the bug with scrot).
	#cs_last_lineno=$cs_lineno
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
		cs_RUN=1
    csfunc_dbg_echo ",dt: not enabled"
	fi

  # If we're executing internal commash functions, don't track them.
  if [[ $BASH_COMMAND =~ ^csfunc_ ]] || [[ $csfunc_inside == 1 ]]; then
    cs_RUN=1
    csfunc_dbg_echo ",dt internal cmd: $BASH_COMMAND"
    return 0
  fi

	# bash executes ~/.bash_logout when login shell exits. We have a command
	# here to know that we're going to exit.
	if [[ $BASH_COMMAND == "cs_LOGOUT=1" ]]; then
		cs_ENABLED=0
		cs_RUN=1
    csfunc_dbg_echo ",dt: running logout"
	fi

	# # If we're executing internal commash functions, don't track them.
	# if [[ $BASH_COMMAND =~ ^csfunc_ ]] || [[ $csfunc_inside == 1 ]]; then
	# 	cs_RUN=1
  #   csfunc_dbg_echo ",dt internal cmd: $BASH_COMMAND"
  #   return 0
	# fi

	# This is the case when you press the <tab> key and bash is trying to
	# autocomplete.
	if [[ -n $COMP_LINE ]]; then
		cs_RUN=1
    csfunc_dbg_echo ",dt: COMP_LINE=\"$COMP_LINE\" $BASH_COMMAND"
	fi

	# this catches commands like:
	# echo a; echo b
	# which we want to execute in one run
	if (( cs_last_lineno == cs_lineno )) && ! [[ $BASH_COMMAND =~ prompt ]]; then
		csfunc_dbg_echo ",dt: cs_last_lineno == cs_lineno == $cs_last_lineno == " \
      "$cs_lineno, BASH_COMMAND=$BASH_COMMAND"
		#return 1
	fi

  #---------------------------------------------------------------------------
  # return from the DEBUG trap with 0 so that the command will be executed

  if [[ "$cs_RUN" == 1 ]]; then
    csfunc_dbg_echo ",dt: running $BASH_COMMAND"
    return 0
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

    csfunc_dbg_echo ",dt: cmd to run: $cmd (from $BASH_COMMAND)"

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

		cs_last_lineno=$cs_lineno
	fi

  csfunc_dbg_echo ",dt: not executed (with cs DBG trap): $BASH_COMMAND"

	return 1
}

#-------------------------------------------------------------------------------

# We can add some logic into writing PS1, but we cannot modify the outside
# world, because we're in a subshell
csfunc_ps1() {
	echo -n ""
}

#-------------------------------------------------------------------------------

csfunc_debug_trap_enable() {
  if [[ -n "$PROMPT_COMMAND" ]]; then
    	PROMPT_COMMAND_BACKUP="$PROMPT_COMMAND"
      PROMPT_COMMAND="csfunc_preprompt;$PROMPT_COMMAND;csfunc_prompt"
  else
    PROMPT_COMMAND="csfunc_prompt"
  fi

	cs_PS1_BACKUP="$PS1"
	PS1="$(csfunc_ps1)$PS1"

	trap 'csfunc_debug_trap $LINENO' DEBUG

	#set -o functrace # XXX
	shopt -s extdebug
}

csfunc_debug_trap_disable() {
	PROMPT_COMMAND="$PROMPT_COMMAND_BACKUP"
	PS1="$cs_PS1_BACKUP"
	trap - DEBUG
	shopt -u extdebug
}
