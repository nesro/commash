#!/usr/bin/env bash

# Commash debugger library


#-------------------------------------------------------------------------------
# script debugging - mainly for internal testing. subject for moving this
# to another file

csfunc_inside_debugger() {
	cmd=$(HISTTIMEFORMAT='' history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//")

	echo ",dbg cmd: \"$cmd\""

	echo -n ",: Now what? show [a]st, e[x]it debugger, execute some [p]ipelines, do [n]othing: "
	while :; do
		read -rn1 key

		if [[ $key == p ]]; then

			echo "\n,dbg: Showing simple commands saved from bash:"
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


