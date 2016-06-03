#!/bin/bash

# ShellCheck
sc_check=1 # check every command with ShellCheck before executing
sc_path=~/.cabal/bin/shellcheck
sc_debug=0
#sc_args="disable=SC2164"

# TODO: call this hook on commash install
cshook_shellcheck_install() {
	:
}

cshook_shellcheck_before() {
	[[ $sc_debug == 1 ]] && set -xv
	
	# ShellCheck needs to get a script. So we create one with shebang,
	# variables and the actual command
	#sc_out=$($sc_path <(echo '#!/bin/bash'; echo "$(set -o posix ; set)"; echo "$cmd") 2>&1)
	
	#TODO: create an external list of things to disable
	sc_out=$($sc_path <(echo -e "#!/bin/bash\n# shellcheck disable=2043,2164,2154,2034\n$cmd") 2>&1)
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
}

csfunc_hook_add_before 'cshook_shellcheck_before'
