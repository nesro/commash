#!/usr/bin/env bash
# https://github.com/nesro/commash

# http://lingrok.org/xref/coreutils/src/chown.c

csfunc_chgrp() {
	if grep -q "csfunc_chgrp" ~/.commash/settings/cs_safe_overwrite.txt; then
		csfunc_ch_cswrapp "csfunc_chgrp" "$@"
	else
		echo ",: Use ,csfunc_chgrp for commash wrapper or /bin/csfunc_chgrp for original csfunc_chgrp."
		echo ",: If you want to overwrite this command, run:"
		echo ',:     echo "csfunc_chgrp" > ~/.commash/settings/cs_safe_overwrite.txt'
	fi
}

csfunc_chgrp_cswrapp() {
	csfunc_ch_cswrapp "chgrp" "$@"
}

csfunc_revert_chgrp() {
	echo ",chgrp: Choose the command to revert:"

	if ! csfunc_safe_list_logs "chgrp"; then
		echo ",chgrp: No files in log."
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
				echo ",chgrp: press 1-9 or q to quit"
				;;
		esac
	done

	local logfile=~/.commash/logs/${csfunc_list_logs[$action]}

	if [[ -z "${csfunc_list_logs[$action]}" ]]; then
		echo ",chgrp fatal error: csfunc_list_logs $action is empty? logfile=$logfile"
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

	echo ",chgrp: do you want to restore the chown? [y/n]"
	echo ",chgrp:    restoring from perm file"
	if csfunc_yesno; then
		local perm_log="$(echo $logfile | sed 's/chgrp/perm/')"
		csfunc_restore_perm "$from" "$perm_log"
		/bin/mv $logfile ~/.commash/logs/.reverted-${csfunc_list_logs[$action]}
	else
		return
	fi
}
alias ,revert_chgrp="csfunc_revert_chgrp"
