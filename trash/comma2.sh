#!/bin/bash


csfunc_excl=$!

cs_ENABLED=0

csfunc_debug_trap() {

	#---------------------------------------------------------------------------
	if [[ $cs_ENABLED == 0 ]]; then
		return 0 # commash is disabled
	fi
	if [[ $BASH_COMMAND == "cs_LOGOUT=1" ]]; then
		cs_ENABLED=0
		return 0
	fi
	if [[ $BASH_COMMAND =~ ^csfunc_ ]] || [[ $csfunc_inside == 1 ]]; then
		return 0
	fi
	#---------------------------------------------------------------------------

	echo "$(date +%Y-%m-%d-%H-%M-%S-%N) BC  \"$BASH_COMMAND\"" >> ~/.commash/log

	if [[ ! -f ~/.commash/lock ]]; then
		touch ~/.commash/lock
		
		
		cmd=$(HISTTIMEFORMAT='' history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//")		
		echo "$(date +%Y-%m-%d-%H-%M-%S-%N) CMD \"$cmd\"" >> ~/.commash/log
		
		# check for backgroud processes
		if false && [[ $cmd =~ \&$ ]]; then
		
			#echo "jobs:"
			#set -xv
			#jobs -l
			#set +xv
		
			echo "\$!=$!"
		
			echo "yes we have & at end. continue?"			
			while :; do
				read -rn1 key
				if [[ $key == y ]]; then
					echo "YES"
					break
				fi
				if [[ $key == n ]]; then
					echo "NO"
					return 1
				fi
			done
		fi
		
		eval "$cmd"

		#if [[ $csfunc_excl != $! ]]; then
		#	echo "\$! changed to $!"
		#	while :; do sleep 1; done
		#fi
			
	fi
		
	return 1
}

csfunc_prompt() {
	csfunc_inside=1
	cs_ENABLED=1
	rm -f ~/.commash/lock
	csfunc_inside=0
}

#-------------------------------------------------------------------------------
# These comments are excerpts from man bash

set -m # Monitor mode.  Job control is enabled.  This option is on by default for interactive shells on systems that support it (see JOB CONTROL above).  All  processes  run in a separate process group.  When a background job completes, the shell prints a line containing its exit status.
echo $?

set -b #  Report the status of terminated background jobs immediately, rather than before the next primary prompt.  This is effective only when job control is enabled.
echo $?

set -o functrace # If  set,  any  traps  on  DEBUG  and RETURN are inherited by shell functions, command substitutions, and commands executed in a subshell environment.  The DEBUG and RETURN traps are normally not inherited in such cases.
echo $?

shopt -s extdebug
echo $?
# If set, behavior intended for use by debuggers is enabled:
#  1.     The -F option to the declare builtin displays the source file name and line number corresponding to each function name supplied as an argument.
#  2.     If the command run by the DEBUG trap returns a non-zero value, the next command is skipped and not executed.
#  3.     If  the  command run by the DEBUG trap returns a value of 2, and the shell is executing in a subroutine (a shell function or a shell script executed by the . or source builtins), a call to return is simulated.
#  4.     BASH_ARGC and BASH_ARGV are updated as described in their descriptions above.
#  5.     Function tracing is enabled:  command substitution, shell functions, and subshells invoked with ( command ) inherit the DEBUG and RETURN traps.
#  6.     Error tracing is enabled:  command substitution, shell functions, and subshells invoked with ( command ) inherit the ERR trap.


set -T # If  set,  any  traps  on  DEBUG  and RETURN are inherited by shell functions, command substitutions, and commands executed in a subshell environment.  The DEBUG and RETURN traps are normally not inherited in such cases.
echo $?

#-------------------------------------------------------------------------------

PROMPT_COMMAND="csfunc_prompt"
trap 'csfunc_debug_trap' DEBUG

#-------------------------------------------------------------------------------



echo "commash2"




