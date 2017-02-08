#!/usr/bin/env bash
# https://github.com/nesro/commash

# TODO: there is a bug. when the command is: "\rm a", the \r get expanded

# ShellCheck
sc_check=1 # check every command with ShellCheck before executing
sc_path=~/.cabal/bin/shellcheck
sc_debug=0

cssc_disable_list_file="$cs_ROOTDIR/settings/cs_shellcheck_blacklist.txt"
cssc_disable=""

cssc_load_disable_list() {
	# TODO: this has been refactored, so it can be improved now
	if [[ ! -f $cssc_disable_list_file ]]; then
		>&2 echo ",: ShellCheck: disable list file \"$cssc_disable_list_file\" not found"
		return
	fi

	csfunc_load_settings $cssc_disable_list_file cssc_disable ,

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
		csfunc_dbg_echo ", cssc: loading disable list begin"
		cssc_disable=$(cssc_load_disable_list)
		csfunc_dbg_echo ", cssc: loading disable list end"
	fi

	sc_out=$($sc_path <(echo -e "#!/bin/bash\n# shellcheck disable=$cssc_disable\n$cmd") 2>&1)
	sc_rc=$?
	sc_out=$(echo "$sc_out" | tail -n +3)

	[[ $sc_debug == 1 ]] && set +xv

	if (( sc_rc > 0 )); then
		>&2 echo -e ",: ShellCheck: \n$sc_out"

		>&2 echo -n ",: Now what? [r]un, [s]top, [i]gnore: "
		while :; do
			read -rn1 key

			if [[ $key == r ]]; then
				>&2 echo -e "\n,: Running this command: \"$cmd\""
				return 0
			fi

			if [[ $key == s ]]; then
				>&2 echo -e "\n,: Stopping the command."
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

csfunc_hook_add_before 1000 'cshook_shellcheck_before'
