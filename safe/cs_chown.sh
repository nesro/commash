#!/usr/bin/env bash
# https://github.com/nesro/commash

# http://lingrok.org/xref/coreutils/src/chown.c

csfunc_chown() {
	if grep -q "chown" ~/.commash/settings/cs_safe_overwrite.txt; then
		csfunc_ch_cswrapp "chown" "$@"
	else
		echo ",: Use ,chown for commash wrapper or /bin/chown for original chmod."
		echo ",: If you want to overwrite this command, run:"
		echo ',:     echo "chown" > ~/.commash/settings/cs_safe_overwrite.txt'
	fi
}

csfunc_chown_cswrapp() {
	csfunc_ch_cswrapp "chown" "$@"
}

csfunc_revert_chown() {
	echo ",chown: Choose the command to revert:"

	if ! csfunc_safe_list_logs "chown"; then
		echo ",chown: No files in log."
		return
	fi

	while read -rsn1 action; do
		case $action in
			[1-9])
				if (( action > csfunc_list_items )); then
					echo ",chown: action out of range ($csfunc_list_items)"
					continue
				fi

				break
				;;
			q)
				return
				;;
			*)
				echo ",chown: press 1-9 or q to quit"
				;;
		esac
	done

	local logfile=~/.commash/logs/${csfunc_list_logs[$action]}

	if [[ -z "${csfunc_list_logs[$action]}" ]]; then
		echo ",chown fatal error: csfunc_list_logs $action is empty? logfile=$logfile"
		return
	fi

	#echo "logfile=$logfile"
	#echo "choosen: $action ${rms[$action]}"

	local total_lines="$(wc -l $logfile | awk '{ print $1 }')"

	local dest=""
	local src=""
	local from=""
	cnt=0
	while IFS='' read -r line || [[ -n "$line" ]]; do
		if (( cnt == 1 )); then
			from="$line"
		fi
		if (( cnt == total_lines - 1 )); then
			local dest="$(echo $line | awk '{print $NF}')"
		fi
		cnt=$(( cnt + 1 ))
	done < "$logfile"

	echo ",chown: do you want to restore the chown? [y/n]"
	echo ",chown:    restoring from perm file"
	if csfunc_yesno; then
		local perm_log="$(echo $logfile | sed 's/chown/perm/')"
		csfunc_restore_perm "$from" "$perm_log"
		/bin/mv $logfile ~/.commash/logs/.reverted-${csfunc_list_logs[$action]}
	else
		return
	fi
}
alias ,revert_chown="csfunc_revert_chown"
