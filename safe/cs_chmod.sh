#!/usr/bin/env bash
# https://github.com/nesro/commash

# http://lingrok.org/xref/coreutils/src/chmod.c

csfunc_chmod() {
	if grep -q "chmod" ~/.commash/settings/cs_safe_overwrite.txt; then
		csfunc_ch_cswrapp "chmod" "$@"
	else
		echo ",: Use ,chmod for commash wrapper or /bin/chmod for original chmod."
		echo ",: If you want to overwrite this command, run:"
		echo ',:     echo "chmod" > ~/.commash/settings/cs_safe_overwrite.txt'
	fi
}

csfunc_chmod_cswrapp() {
	csfunc_ch_cswrapp "chmod" "$@"
}

csfunc_revert_chmod() {
	echo ",chmod: Choose the command to revert:"

	if ! csfunc_safe_list_logs "chmod"; then
		echo ",chmod: No files in log."
		return
	fi

	while read -rsn1 action; do
		case $action in
			[1-9])
				if (( action > csfunc_list_items )); then
					echo ",chmod: action out of range ($csfunc_list_items)"
					continue
				fi

				break
				;;
			q)
				return
				;;
			*)
				echo ",chmod: press 1-9 or q to quit"
				;;
		esac
	done

	local logfile=~/.commash/logs/${csfunc_list_logs[$action]}

	if [[ -z "${csfunc_list_logs[$action]}" ]]; then
		echo ",chmod fatal error: csfunc_list_logs $action is empty? logfile=$logfile"
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

	getfacl_file="$(echo "$logfile" | sed 's/chmod/getfacl/')"

	echo ",chmod: do you want to restore the chmod? [y/n]"
	echo ",chmod:    setfacl --restore=$getfacl_file"
	if csfunc_yesno; then
		setfacl --restore=$getfacl_file
	else
		return
	fi
}
alias ,revert_chmod="csfunc_revert_chmod"
