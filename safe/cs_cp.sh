#!/usr/bin/env bash
# https://github.com/nesro/commash

# http://lingrok.org/xref/coreutils/src/cp.c
# http://lingrok.org/xref/coreutils/tests/cp/

# commash wrapper for the cp command
# 1. warn and handle before overwriting files
# 2. log cp commands and to revert them, just delete the copies

# tests:
#  touch a
#  cp a b
#  ,revert_cp

#-------------------------------------------------------------------------------

csfunc_cp() {
	if grep -q "cp" ~/.commash/settings/cs_safe_overwrite.txt; then
		csfunc_cp_cswrapp "$@"
	else
		echo ",: Use ,cp for commash wrapper or /bin/cp for original cp."
		echo ",: If you want to overwrite this command, run:"
		echo ',:     echo "cp" > ~/.commash/settings/cs_safe_overwrite.txt'
	fi
}

#-------------------------------------------------------------------------------

csfunc_cp_cswrapp() {

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
					a)
						echo ",cp: a flag: archive"
						;;
					b)
						echo ",cp: b flag: create backup"
						;;
					f)
						echo ",cp: f flag: force"
						;;
					i)
						echo ",cp: i flag: interactive"
						;;
					H)
						echo ",cp: H flag: follow command-line symlinks"
						;;
					l)
						echo ",cp: l flag: hard link files instead of copying"
						;;
					L)
						echo ",cp: L flag: follow symlinks"
						;;
					n)
						echo ",cp: n flag: don't overwrite existing files"
						;;
					P)
						echo ",cp: P flag: don't follow symlinks in so"
						;;
					r|R)
						echo ",cp: r flag: copy directories recursively"
						opt_r=1
						;;
					s)
						echo ",cp: s flag: make symlinks instead of copying"
						;;
					S)
						echo ",cp: S flag: override suffix for backups"
						;;
					t)
						opt_t=1
						echo ",cp: t flag: copy into a directory, that is \"$OPTARG\""
						dest="$OPTARG"
						;;
					T)
						opt_T=1
						echo ",cp: T flag: dest is a regular file"
						# TODO
						;;
					u)
						echo ",cp: u flag: update destination"
						;;
					v)
						echo ",cp: v flag: verbose"
						;;
					x)
						echo ",cp: x flag: stay on this filesystem"
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

# f f f f -> d
# d -> d

	if (( opt_t == 0 )); then
		dest="${@: -1}"
	fi

	# if the destination is a directory, look if there is the source name also
	if [[ -d "$dest" ]]; then
		local for_i
		for (( for_i=1; for_i < $# ; for_i++ )); do
			local arg="${!for_i}"
			if [[ -f "$dest/$arg" ]]; then
				echo ",cp: file $dest/$arg already exists"
				echo ",cp: you can run: /bin/cp -b to make a backup"
			fi
		done
	elif [[ -f "$dest" ]]; then
		# the destination is not a directory, it makes sense now if we only have 2 arguments
		if (( $# != 2 )); then
			echo ",cp: the destination is not a directory and you're copying more than 1 file"
		fi

		if [[ -f "$dest" ]]; then
			echo ",cp: the destination $dest already exists."
			echo ",cp: you can run: /bin/cp -b to make a backup"
		fi
	else # file doesn't exist
		echo ",cp: destionation doesn't exit yet"

		if (( $# != 2 )); then
			echo ",cp: you cannot copy more than one file if the destination doesn't exists"
		fi
	fi

	echo -e ",cp: Do you want to run: \n/bin/cp "${save_opts[@]}" [y/n]"
	if csfunc_yesno; then
		if /bin/cp "${save_opts[@]}"; then
			ts=$(date +%Y-%m-%d-%H-%M-%S-%N)
			logfile=~/.commash/logs/cp-"$ts"
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

csfunc_revert_cp() {
	echo ",cp: Choose the command to revert:"

	if ! csfunc_safe_list_logs "cp"; then
		echo ",cp: No files in log."
		return
	fi

	while read -rsn1 action; do
		case $action in
			[1-9])
				if (( action > csfunc_list_items )); then
					echo ",cp: action out of range ($csfunc_list_items)"
					continue
				fi

				break
				;;
			q)
				return
				;;
			*)
				echo ",cp: press 1-9 or q to quit"
				;;
		esac
	done

	local logfile=~/.commash/logs/${csfunc_list_logs[$action]}

	if [[ -z "${csfunc_list_logs[$action]}" ]]; then
		echo ",cp fatal error: csfunc_list_logs $action is empty? logfile=$logfile"
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
				echo ",cp: Do you want to revert the change by removing $dest/$s? [y/n]"
				echo ",cp:    /bin/rm -f $dest/$s"
				if csfunc_yesno; then
					/bin/rm -f $dest/$s
				else
					return
				fi
		done
	fi
	if [[ -f $dest ]]; then
		echo ",cp: Do you want to revert the change by removing $dest? [y/n]"
		echo ",cp:    /bin/rm $dest"
		if csfunc_yesno; then
			/bin/rm $dest
		else
			return
		fi
	fi
	/bin/mv $logfile ~/.commash/logs/.reverted-${csfunc_list_logs[$action]}
}
alias ,revert_cp="csfunc_revert_cp"
