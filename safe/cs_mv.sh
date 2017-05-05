#!/usr/bin/env bash
# https://github.com/nesro/commash

# http://lingrok.org/xref/coreutils/src/mv.c
# http://lingrok.org/xref/coreutils/tests/mv/

# commash wrapper for the mv command
# 1. warn and handle before overwriting files
# 2. log mv commands and to revert them, just move/rename them back

# tests:
#  touch a
#  mv a b
#  ,revert_mv

#-------------------------------------------------------------------------------

csfunc_mv() {
	if grep -q "mv" ~/.commash/settings/cs_safe_overwrite.txt; then
		csfunc_mv_cswrapp "$@"
	else
		echo ",: Use ,mv for commash wrapper or /bin/mv for original mv."
		echo ",: If you want to overwrite this command, run:"
		echo ',:     echo "mv" > ~/.commash/settings/cs_safe_overwrite.txt'
	fi
}

#-------------------------------------------------------------------------------

csfunc_mv_cswrapp() {

	local save_opts=("$@")
	local opt_r=0
	local opt_t=0
	local opt_T=0
	local dest=""

	OPTIND=1
	optspec=":abdfHilLnprst:uvxPRS:TZ-:"
	while getopts "$optspec" optchar; do
			#echo ",:optchar: $optchar"
			case "$optchar" in
					-)
							case "$OPTARG" in
									loglevel)
											val="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
											echo "Parsing option: '--${OPTARG}', value: '${val}'" >&2;
											;;
									loglevel=*)
											val=${OPTARG#*=}
											opt=${OPTARG%=$val}
											echo "Parsing option: '--${opt}', value: '${val}'" >&2
											;;
									*)
											if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
													echo "Unknown option --${OPTARG}" >&2
											fi
											;;
							esac;;
					b)
						echo ",mv: b flag: create backup"
						;;
					f)
						echo ",mv: f flag: force"
						;;
					i)
						echo ",mv i flag: interactive"
						;;
					S)
						echo ",mv: S flag: override suffix for backups"
						;;
					t)
						echo ",mv: t flag: move into a directory"
						dest="$OPTARG"
						;;
					T)
						opt_T=1
						echo ",mv: T flag: dest is a regular file"
						# TODO
						;;
					u)
						echo ",mv: u flag: update destination"
						;;
					v)
						echo ",mv: v flag: verbose"
						;;
					*)
							if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
									echo "Non-option argument: '-${OPTARG}'" >&2
							fi
							;;
			esac
	done

	shift $((OPTIND-1))

	if [ "$1" = "--" ]; then
		shift
	fi

	#-----------------------------------------------------------------------------

	if (( opt_t == 0 )); then
		dest="${@: -1}"
	fi

	# if the destination is a directory, look if there is the source name also
	if [[ -d "$dest" ]]; then
		local for_i
		for (( for_i=1; for_i < $# ; for_i++ )); do
			local arg="${!for_i}"
			if [[ -f "$dest/$arg" ]]; then
				echo ",mv: file $dest/$arg already exists"
				echo ",mv: you can run: /bin/mv -b to make a backup"
			fi
		done
	elif [[ -f "$dest" ]]; then
		# the destination is not a directory, it makes sense now if we only have 2 arguments
		if (( $# != 2 )); then
			echo ",mv: the destination is not a directory and you're moving more than 1 file"
		fi

		if [[ -f "$dest" ]]; then
			echo ",mv: the destination $dest already exists."
			echo ",mv: you can run: /bin/mv -b to make a backup"
		fi
	else # file doesn't exist
		echo ",mv: destionation doesn't exit yet"

		if (( $# != 2 )); then
			echo ",mv: you cannot copy more than one file if the destination doesn't exists"
		fi
	fi

	echo -e ",mv: Do you want to run: \n/bin/mv "${save_opts[@]}" [y/n]"
	if csfunc_yesno; then
		if /bin/mv "${save_opts[@]}"; then
			ts=$(date +%Y-%m-%d-%H-%M-%S-%N)
			logfile=~/.commash/logs/mv-"$ts"
			touch "$logfile"
			echo "$(csfunc_lasthist)" > "$logfile"
			echo $PWD >> "$logfile"
			for (( for_i=1; for_i <= $# ; for_i++ )); do
				local arg="${!for_i}"

				# last arg is destination
				# echo "arg=$arg"

				local lsout

				if ls -ld "$arg" > /dev/null 2>&1; then
					lsout=$(ls -ld $(realpath "$arg"))
				else
					lsout="CS_NEW $arg"
				fi
				echo "$lsout" >> "$logfile"
			done
		fi
	fi
}

csfunc_revert_mv() {
	echo ",mv: Choose the command to revert:"

	if ! csfunc_safe_list_logs "mv"; then
		echo ",mv: No files in log."
		return
	fi

	while read -rsn1 action; do
		case $action in
			[1-9])
				if (( action > csfunc_list_items )); then
					echo ",mv: action out of range ($csfunc_list_items)"
					continue
				fi

				break
				;;
			q)
				return
				;;
			*)
				echo ",mv: press 1-9 or q to quit"
				;;
		esac
	done

	local logfile=~/.commash/logs/${csfunc_list_logs[$action]}

	if [[ -z "${csfunc_list_logs[$action]}" ]]; then
		echo ",mv fatal error: csfunc_list_logs $action is empty? logfile=$logfile"
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

			#echo "destination: $dest"

		elif (( cnt > 1 )); then
			src="$src $(echo $line | awk '{print $NF}')"

			#echo "source: $(echo $line | awk '{print $NF}') "

		fi
		cnt=$(( cnt + 1 ))
	done < "$logfile"

	if [[ -d $dest ]]; then
		for s in $src; do
				echo ",mv: Do you want to revert the change by moving $dest/$s to $s? [y/n]"
				echo ",mv:    (builtin cd $from && /bin/mv $dest/$s $s)"
				if csfunc_yesno; then
					(builtin cd $from && /bin/mv $dest/$s $s)
				else
					return
				fi
		done
	fi
	if [[ -f $dest ]]; then
		echo ",mv: Do you want to revert the change by moving $dest to $src? [y/n]"
		echo ",mv:    (builtin cd $from && /bin/mv $dest $src)"
		if csfunc_yesno; then
			(builtin cd $from && /bin/mv $dest $src)
		else
			return
		fi
	fi
	/bin/mv $logfile ~/.commash/logs/.reverted-${csfunc_list_logs[$action]}
}
alias ,revert_mv="csfunc_revert_mv"
