#!/bin/bash
# https://github.com/nesro/commash

# poor man's multiline bash comment
if false; then
cat <<EOF

TODO:
	- add arguments to ShellCheck (f.ex: disable=SC2164 for enabling cd without
		|| exit)
		
	- save commands into a history file. store pid of shell, return code of
		the executed command, timestamp
		
	- add ,info command that tells informations about a file
	
	- add ,cd command that allows quickly cd directory (from actual dir or
		backwards in current path)
		
	- save stdout and stderr for every command executed
	
	- use /tmp to store .commash/lock (/tmp is tmpfs and should be faster)
	
	- add more layers of safe mode
		- layer 1) don't make any changes, just inform what's happening
		- layer 2) make changes, but backup everything and allow easy
			restoration
			- this resotration space could be in /tmp
			- restoration space will be limited
			- question the user what to do before making a big change
				that would eat up a lot of disk space
			- the ultimate goal is to provide layer 2 without user interaction
				and bothering him while still providing usefull things
	
	- don't run absolute paths in safe mode (then it wouldn't be safe)
	
	- add more commands into safe mode (chmod, rm, mv, cp, ln, ...)
	
	- make some kind of persistent storage of internal variables
		(f.ex.: cs_AUTOENABLE)
	
	- make some fancy PS1 as an option (time, hostname, path, rc, shlvl)
	
	- add ,d <command> (debugging of a particular command)
	
	- inspect commands when rc != 0 and write human-readable info what happened
		(for example "man asdf" returns 16, even if the man write what happend
		 it would be nice if we could do it too)
	
	- if we want to exit the shell now, the bind is: ctrl-x because ctrl-d
	
	- the current code rewrites previous PROMPT_COMMAND (which is wrong)
	
	- refactor function names and variables to be consistent
	
	- detect things like:
		- $ cd /a
		- $ cd /b
		- $ cd /a
		- and then suggest: cd -
	
	- refactor debugger (to be more modular) and add more functionality
	
	- add support for coloring output: white for stdout, red for stderr
		(I can do it, but I cannot change directory while doing that)
		
	- is the lock file really necessary? maybe a variable would be sufficient
		right now, this commands works fine:
		false || true && ((echo a; (echo b; echo c); echo $(echo d)) && echo "$(echo $(echo $(echo e)))"; echo f) && echo g
EOF
fi

#-------------------------------------------------------------------------------
# Prevent multiple sourcing

if [[ -n $cs_SOURCED ]]; then
	return
else
	cs_SOURCED=1
fi

#-------------------------------------------------------------------------------
# These variables 


# auto enable commash with .bashrc
cs_AUTOENABLE=1



#-------------------------------------------------------------------------------
# usage

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
# save paths to commands so we can use them even in the safe mode
RM=$(which rm)
TOUCH=$(which touch)
SED=$(which sed)
TAIL=$(which tail)


#-------------------------------------------------------------------------------
# Variables from environment
# These variables are loaded from the ~/.commash/variables.txt

# commash debug mode. in this mode, commash will not be executing commands
# by default and allows to users some sort of debugging
cs_DEBUG=${cs_DEBUG:-0}

# debug commash internals
# list of things that this setting go:
# - show internals of eval, so you can see what is really executing
cs_INTERNAL_DEBUG=${cs_INTERNAL_DEBUG:-"none"}


#-------------------------------------------------------------------------------
# Common functions

[[ $cs_INTERNAL_DEBUG =~ functions|all ]] && set -xv

escape_sed() {
	# http://wiki.bash-hackers.org/syntax/quoting
	sed -e 's/\//\\\//g' -e 's/\&/\\\&/g'
}

[[ $cs_INTERNAL_DEBUG =~ functions|all ]] && set +xv

#-------------------------------------------------------------------------------
# Global variables

[[ $cs_INTERNAL_DEBUG =~ vars|all ]] && set -xv

# Commash
cs_ENABLED=0
cs_ROOTDIR=~/.commash
cs_COMMA_SH=$cs_ROOTDIR/comma.sh
cs_LOCKFILE=$cs_ROOTDIR/lock
cs_SAFEDIR=$cs_ROOTDIR/safe
cs_SAFEDIR_SED=$(echo "$cs_SAFEDIR" | escape_sed)
cs_RC_HOOK="if [[ -f $cs_COMMA_SH ]]; then source $cs_COMMA_SH; fi"
cs_RC_HOOK_GREP="if \[\[ -f $cs_COMMA_SH \]\]\; then source $cs_COMMA_SH\; fi"
cs_RC_HOOK_SED=$(echo "$cs_RC_HOOK_GREP" | escape_sed)
cs_LOGOUT_HOOK="cs_LOGOUT=1"

# ShellCheck
sc_check=1 # check every command with ShellCheck before executing
sc_path=~/.cabal/bin/shellcheck
sc_debug=0
#sc_args="disable=SC2164"

[[ $cs_INTERNAL_DEBUG =~ globvars|all ]] && set +xv


#-------------------------------------------------------------------------------
# Install
#
# We check at the beginning of this script if installation is needed.

cs_install_commash() {
	[[ $cs_INTERNAL_DEBUG =~ install|all ]] && set -xv
	
	if [[ ! -d $cs_ROOTDIR ]]; then
		echo "The directory \"$cs_ROOTDIR\" doesn't exists. Please clone the "
			"repository here."
		exit 1
	fi
	
	if [[ ! -f $cs_COMMA_SH ]]; then
		echo "The file \"$cs_COMMA_SH\" doesn't exists. It should be this file."
			"Please clone the repository here."
		exit 1
	fi
	
	if [[ ! -x $sc_path ]]; then
		cat <<EOF
Please install shellcheck into: $sc_path
You can do it on Ubuntu like this:
sudo add-apt-repository universe
sudo apt-get install cabal-install
cabal update
cabal install shellcheck
EOF
		exit 1
	fi
	
	if echo "$cs_RC_HOOK" >> ~/.bashrc; then
		echo ",: Commash hook was added into your ~/.bashrc"
	else
		echo ",: There is a problem writing into your ~/.bashrc"
		exit 1
	fi
	
	# TODO: add check if .bash_logout exists
	if sed -i "1i$cs_LOGOUT_HOOK" ~/.bash_logout; then
		echo ",: Commash logout hook was added into your ~/.bash_logout"
	else
		echo ",: There is a problem writing into your ~/.bash_logout"
		exit 1
	fi
}

cs_run_install_if_needed() {
	if [[ -z $BASH_VERSION ]]; then
		echo ",: Only Bash shell is supported."
		exit 1
	fi

	# If there is no CS hook in .bashrc, run install.
	if ! grep "$cs_RC_HOOK_GREP" ~/.bashrc >/dev/null 2>&1; then
		cs_install_commash
	fi
}

#-------------------------------------------------------------------------------
# Uninstall

cs_run_uninstall() {
	[[ $cs_INTERNAL_DEBUG =~ install|all ]] && set -xv
	
	if sed -i "/$cs_RC_HOOK_SED/d" ~/.bashrc; then
		echo ",: Removed commash hook from .bashrc"
	else
		echo ",: Tried to remove commash hook from .bashrc, but it failed."
	fi
	
	if sed -i "/$cs_LOGOUT_HOOK/d" ~/.bash_logout; then
		echo ",: Removed commash hook from ~/.bash_logout"
	else
		echo ",: Tried to remove commash hook from ~/.bash_logout, but it failed."
	fi
	
	echo ",: If you want to delete the commash directory, run:"
	echo ",: rm -fr $cs_ROOTDIR"
}

#-------------------------------------------------------------------------------
# Entry functions


cs_ENABLED=0
cs_DEBUGGER=0


# handle the ctrl-x bind
csfunc_exit() {
	cs_ENABLED=0
	logout
}
alias ,exit="csfunc_exit"
alias ,x=",exit"



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
		PATH=$(echo $PATH | $SED "s/$cs_SAFEDIR_SED://")
		echo ",: safe mode disabled. PATH is \"$PATH\""
	fi
	csfunc_inside=0
}
alias ,safe="csfunc_safe 1"
alias ,s=",safe"
alias ,nsafe="csfunc_safe 0"
alias ,ns=",nsafe"






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
# doesn't like it. And it would be shame if this script wouldn't be shellcheck
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
# commash debug trap and prompt_command wrappers
#-------------------------------------------------------------------------------

sc_check_wrapper() {
	local cmd="$1"

	if [[ $sc_check == 1 ]]; then
		# ShellCheck check
		[[ $sc_debug == 1 ]] && set -xv
		# ShellCheck needs to get a script. So we create one with shebang,
		# variables and the actual command
		#sc_out=$($sc_path <(echo '#!/bin/bash'; echo "$(set -o posix ; set)"; echo "$cmd") 2>&1)
	
		sc_out=$($sc_path <(echo '#!/bin/bash'; echo "$cmd") 2>&1)
		sc_rc=$?
		sc_out=$(echo "$sc_out" | tail -n +3)
		[[ $sc_debug == 1 ]] && set +xv

		if (( sc_rc > 0 )); then
			echo -e ",: ShellCheck: \n$sc_out"
		
			echo -n ",: Now what? [r]un, [s]top: "
			while :; do
				read -rn1 key
				
				if [[ $key == r ]]; then
					echo -e "\n,: Running this command: \"$cmd\""
					return 0
				fi
				
				if [[ $key == s ]]; then
					echo -e "\n,: Stopping the command."
					return 1
				fi
				
			done
		fi
	fi
}

#
#  TODO: see todo at top. add rc of command, time of execution
#cs_savecommand() {
#	local cmd="$1"
#	local histd="$cs_ROOTDIR/history/$(date +%Y/%m/%d/)"
#	mkdir -p $histd
#	
#	#TODO: save return code? save partial commands?"
#	echo "$(date +%Y%m%d%H%M%S)\t$(hostname)\t$cmd" >> $histd/$(hostname).txt
#}

#
#
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
	*)
		echo "(no explanation)"
		;;
	esac
}

csfunc_rc() {
	local rc=$1
	
	echo ",: return code warning: \$? == $rc $(cs_explain_rc $rc)"
}


csfunc_inside_debugger() {
	cmd=$(HISTTIMEFORMAT='' history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//")
	
	echo ",dbg cmd: \"$cmd\""
	
	
	
	
	echo -n ",: Now what? show [a]st, e[x]it debugger, execute some [p]ipelines, do [n]othing: "
	while :; do
		read -rn1 key
		
		if [[ $key == p ]]; then
			
			echo ",dmg: Showing simple commands saved from bash:"
			if (( cspc_command_cnt > 0 )); then
				for (( cspc_i=0 ; cspc_i < cspc_command_cnt ; cspc_i++ )); do
					echo "$cspc_i=\"${cs_command_arr[$cspc_i]}\""
				done
			fi
		
			echo -n ",dmg: How many pipelines you want to run: "
			read -r pipelines
			
			pipcmd="${cs_command_arr[0]}"
			for (( i=1 ; i < pipelines ; i++ )); do
				pipcmd="$pipcmd | ${cs_command_arr[i]}"
			done
			
			echo -e "\n,dbg: executing: \"$pipcmd\""
			eval "$pipcmd"
			
			# TODO: catch rc
			break
		fi
		
		if [[ $key == x ]]; then
			echo -e "\n,: Exit from the debugger."
			cs_DEBUGGER=0
			break
		fi
		
		if [[ $key == n ]]; then
			echo -e "\n,: Do nothing. You're still in debugger."
			break
		fi
		
		if [[ $key == a ]]; then
			echo -e "\n,: Showing ast (output from python script):"
			~/.commash/ast.py "$cmd"
			break
		fi
	done
}

cspc_first=1

cspc_command_cnt=0

# This function is executed by BASH every time the prompt is about to print.
# We use cspc_
csfunc_prompt() {
	csfunc_rc=$? # This must be the first command. Even before the debug.
	csfunc_inside=1

	if [[ $cs_AUTOENABLE == 1 ]] && [[ $cspc_first == 1 ]]; then
		cspc_first=0
		
		echo ",: Autoenabling commash in the first PROMPT_COMMAND"
		
		cs_ENABLED=1
	fi

	if (( csfunc_rc != 130 )); then
		cs_debug_trap_rc_ctrlc=0
	fi


	$RM -f ~/.commash/lock

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


csfunc_debug_trap() {
	cs_debug_trap_rc=$?

	if [[ $cs_ENABLED == 0 ]]; then
		return 0 # commash is disabled
	fi

	if [[ $BASH_COMMAND == "cs_LOGOUT=1" ]]; then
		cs_ENABLED=0
		return 0
	fi

	# TODO: this one is really usefull, make some flag to turn it on easily
	#echo ",: $BASH_COMMAND" 
	
	# If we control-c a command, we jump again into the debug trap
	# this is the right place to explain what happened
	if (( cs_debug_trap_rc == 130 )) && (( cs_debug_trap_rc_ctrlc == 0 )); then
		cs_debug_trap_rc_ctrlc=1
		csfunc_rc $cs_debug_trap_rc
	fi	
	
	if [[ -n $COMP_LINE ]]; then
		return 0 # bash is completing
	fi
	
	# If we're executing internal commash functions, don't track them.
	if [[ $BASH_COMMAND =~ ^csfunc_ ]] || [[ $csfunc_inside == 1 ]]; then
		return 0
	fi
	
	# Save BASH_COMMAND for allow debuger partial execution
	cs_command_arr[$cspc_command_cnt]="$BASH_COMMAND"
	(( cspc_command_cnt++ ))
		
		

	# bash is executing prompt command
	# XXX: see below
	if [[ $BASH_COMMAND == "$PROMPT_COMMAND" ]]; then
		csfunc_catch_command=0
		return 0
	elif [[ $csfunc_catch_command == 1 ]]; then # Run this code only once per interactive command
		csfunc_catch_command=0


		# If we ctrlc this command, show is the warning
		cs_debug_trap_rc_ctrlc=0

		# This lock guarantee that we will eval only once per promp.
		# It may be very tricky to handle subshells well
		if [[ -f ~/.commash/lock ]]; then
			return 1
		else
			$TOUCH ~/.commash/lock
		fi
		
		
	
		cmd=$(HISTTIMEFORMAT='' history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//")
		
		
		# ShellCheck
		if ! sc_check_wrapper "$cmd"; then
			return 1
		fi
		
		
		#shopt -s lastpipe
		#set +m

		# if debug mode is off, run the command
		if [[ $cs_DEBUG == 0 ]]; then

			
			# XXX: we may wrap eval with in_eval variables and disable debug
			# trap for them?

			
			#csfunc_in_eval=1					
			eval "$cmd"
			cs_rc=$?
			#csfunc_in_eval=0
		
			if (( cs_rc > 0 )); then
				echo ",debug trap: return code warning: \$? == $cs_rc $(cs_explain_rc $cs_rc)"
			fi
			
		else
			echo ",: commash prevented execution of: \"$cmd\""
			echo ",: going to the debugger mode"
			
			cs_DEBUGGER=1
		fi # cs_DEBUG == 0
		
		# don't run the program again
		return 1
	else
		# these are the rest of the piplenies:
		# if the command is:
		# cmd1 | cmd2 | cmd3
		# this will be executed for cmd2 and cmd3		
		return 1
	fi
}

#-------------------------------------------------------------------------------

cs_main() {
	cs_run_install_if_needed

	# This is needed if we want to prevent executing any command without sending
	# CtrlC signal.
	shopt -s extdebug
	
	# This is not really necessary at the moment.
	# But I want to have it working even with this turned on
	set -o functrace


	# This issue is fixed now by writing:
	# cs_LOGOUT=1
	# to .bash_logout We can detect it and turn commash off.
	#
	# FIXME: if we control-d from bash, it triggers debug trap and executes
	# the last command. use control-x instead
	#
	# Ultimately, we could use "stty eof undef", but that would change other
	# things too (like python shell) and we don't want that	
	#set -o ignoreeof
	#bind '"\C-x":"\C-u\C-k,exit\n"'
	
	# FIXME: I had something already in there and it was broken.
	#PROMPT_COMMAND="${PROMPT_COMMAND};cs_prompt_command"
	PROMPT_COMMAND="csfunc_prompt"
	trap 'csfunc_debug_trap' DEBUG

	
	
	cat <<EOF
,: Commash has been loaded. But it's disabled by default.
,: You can enable it by running: ", enable" (or just ", e" )
EOF

}

#-------------------------------------------------------------------------------

cs_main

if false; then

		# eval the commmand and color the output
		echo -en "\033[31m"  ## red		
		#eval "$cmd" | while read -r line; do
		while read -r line; do
    		echo -en "\033[36m"  ## blue
    		echo "$line"
   			echo -en "\033[31m"  ## red
		done < <(eval "$cmd")
		cs_rc=${PIPESTATUS[0]}
		echo -en "\033[0m"  ## reset color
		
		echo ",: mid pwd=$(pwd)"
				
fi #false
