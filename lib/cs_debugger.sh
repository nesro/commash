#!/usr/bin/env bash
# https://github.com/nesro/commash







# TODO: this is just a copy-pasta of the bashlex pre-hook. this just allows
# us to debug the last command instead of starting the debugger for every command
csfunc_debugger() {

	local cmd=$(csfunc_lasthist 2)

	# debugger is on for only 1 cmd
	# if [[ $cs_debugger_on != 1 ]]; then
	# 	return
	# fi

	echo -e ",: commash debugger:\n"

	local bashlex_out=$(~/.commash/debugger/cs_bashlex.py "$cmd")

	OLDIFS=$IFS
	IFS=$'\n' lines=($bashlex_out)
	IFS=$OLDIFS

	>&2 echo -ne "\n,: Select your option or [q]uit or [r]un normally "
	while :; do
		read -rn1 key

		echo

		if [[ $key == r ]]; then
			echo ",: Continuing to run:"
			echo ",: $cmd"

			# XXX there is no debug trap that could run our code. we need to run
			# it here. TODO: all the checks from debug trap needs to be here as well
			eval "$cmd"

			return 0
		fi

		if [[ $key == q ]]; then
			echo ",: Nothing is going to be executed."
			return 1
		fi

		# we are counting the choices from 1. seems more natural
		key=$(( key - 1))

		# TODO: check the range, XXX: this is obviously not right
		if (( $key < 9 )); then
			echo ",: Executing: \"${lines[$key]}\""
			eval "${lines[$key]}"

			# do not execute the command after we evaled it
			return 1
		fi
	done

}


#-------------------------------------------------------------------------------

# XXX XXX
# this is the old and dirty version of the debugger.
# it somehow works, but we don't have much control over what is happening
# XXX XXX

# Commash debugger library

csfunc_inside_debugger() {
	echo ",: this debugger is obsolete. do not use it."
	return

	cmd=$(csfunc_lasthist)

	echo ",dbg cmd: \"$cmd\""

	echo -n ",: Now what? show [a]st, e[x]it debugger, execute some [p]ipelines, do [n]othing: "
	while :; do
		read -rn1 key

		if [[ $key == p ]]; then

			echo -e "\n,dbg: Showing simple commands saved from bash:"
			if (( cspc_command_cnt > 0 )); then
				for (( cspc_i=0 ; cspc_i < cspc_command_cnt ; cspc_i++ )); do
					echo "$cspc_i=\"${cs_command_arr[$cspc_i]}\""
				done
			fi

			echo -n ",dbg: How many pipelines you want to run: "
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

csfunc_lib_debugger_load() {
	:
}

csfunc_lib_debugger_unload() {
	:
}
