#!/bin/bash

# ShellCheck
sc_check=1 # check every command with ShellCheck before executing
sc_path=~/.cabal/bin/shellcheck
sc_debug=0

cssc_disable_list_file="$cs_ROOTDIR/hooks/cshook_shellcheck_disable_list.txt"
cssc_disable=""

cssc_load_disable_list() {
	if [[ ! -f $cssc_disable_list_file ]]; then
		>&2 echo ",: ShellCheck: disable list file \"$cssc_disable_list_file\" not found"
		return
	fi

	cssc_disable=""
	while IFS='' read -r line || [[ -n "$line" ]]; do
		line=$(echo "$line" | awk -F'#' '{ print $1 }' | tr -d ' ')
		if [[ -z "$line" ]]; then
			continue
		fi
		if [[ -z "$cssc_disable" ]]; then
			cssc_disable="$line"
		else
			cssc_disable="$cssc_disable,$line"
		fi
	done < "$cssc_disable_list_file"

	echo -n "$cssc_disable"
}

# TODO: call this hook on commash install
cshook_shellcheck_install() {
	:
}

cshook_shellcheck_before() {
	[[ $sc_debug == 1 ]] && set -xv
	
	# ShellCheck needs to get a script. So we create one with shebang,
	# variables and the actual command
	#sc_out=$($sc_path <(echo '#!/bin/bash'; echo "$(set -o posix ; set)"; echo "$cmd") 2>&1)
	
	if [[ -z "$cssc_disable" ]]; then
		cssc_disable=$(cssc_load_disable_list)
	fi

	sc_out=$($sc_path <(echo -e "#!/bin/bash\n# shellcheck disable=$cssc_disable\n$cmd") 2>&1)
	sc_rc=$?
	sc_out=$(echo "$sc_out" | tail -n +3)
	
	[[ $sc_debug == 1 ]] && set +xv

	if (( sc_rc > 0 )); then
		echo -e ",: ShellCheck: \n$sc_out"
		
		echo -n ",: Now what? [r]un, [s]top, [i]gnore: "
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

			if [[ $key == i ]]; then
				cat <<-EOF


,: Ignoring warnings from ShellCheck is easy, but not automatic.
,: Please look into the detail of the check. If you want to ignore this check
,: in the future, add the number to the disable list file. You can use the
,: prepared command.
,: (XXX: The changes takes place in the new session.)

				EOF

				for warn in $(echo "$sc_out" | grep -o 'SC[0-9]*' | tr -d SC ); do
					echo "https://github.com/koalaman/shellcheck/wiki/SC$warn"
					echo "echo $warn >> $cssc_disable_list_file"
					echo
				done

				return 1
			fi
				
		done
	fi
}

csfunc_hook_add_before 'cshook_shellcheck_before'
