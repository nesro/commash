#!/usr/bin/env bash
# https://github.com/nesro/commash

# http://lingrok.org/xref/coreutils/src/cp.c
# http://lingrok.org/xref/coreutils/tests/cp/

# commash wrapper for the cp command
# 1. warn and handle before overwriting files

# 2. log cp commands and to revert them, just delete the copies

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
						;;
					s)
						echo ",cp: s flag: make symlinks instead of copying"
						;;
					S)
						echo ",cp: S flag: override suffix for backups"
						;;
					t)
						echo ",cp: t flag: copy into a directory"
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

	local dest="${@: -1}"

	# if the destination is a directory, look if there is the source name also
	if [[ -d "$dest" ]]; then
		local for_i
		for (( for_i=1; for_i < $# ; for_i++ )); do
			local arg="${!for_i}"
			if [[ -f "$dest/$arg" ]]; then
				echo ",cp: file $dest/$arg already exists"
				echo ",cp: you can run: /bin/cp --backup=simple --suffix=.b to make a backup"
			fi
		done
	else
		# the destination is not a directory, it makes sense now if we only have 2 arguments
		if (( $# != 2 )); then
			echo ",cp: the destination is not a directory and you're copying more than 2 files"
		fi

		if [[ -f "$dest" ]]; then
			echo ",cp: the destination $dest already exists."
			echo ",cp: you can run: /bin/cp -b to make a backup"
		fi
	fi

	echo -e ",cp: Do you want to run: \n/bin/cp "${save_opts[@]}""
	read -rsn1

	ts=$(date +%Y-%m-%d-%H-%M-%S-%N)
	logfile=~/.commash/logs/cp-"$ts"
	touch "$logfile"
	echo "$(csfunc_lasthist)" > "$logfile"
	echo $PWD >> "$logfile"
	for (( for_i=1; for_i <= $# ; for_i++ )); do
		local arg="${!for_i}"

		# last arg is destination
		echo "arg=$arg"

		local lsout=$(ls -ld $(realpath "$arg"))
		echo "$lsout" >> "$logfile"
	done

	/bin/cp "${save_opts[@]}"


	#-----------------------------------------------------------------------------

# /bin/cp --backup=simple --suffix=".SUF" a b
}

csfunc_revert_cp() {

	local i=1
	for f in ~/.commash/logs/cp-*; do
		t=${f##*/}

		if [[ ! $t =~ cp-[0-9]* ]]; then
			echo ",cp: invalid file in trash: $t"
			return
		fi

		echo -n "    [$i] "
		rms[$i]=$t

		ry=$(echo "$t" | awk -F'-' '{ print $2 }')
		rm=$(echo "$t" | awk -F'-' '{ print $3 }')
		rd=$(echo "$t" | awk -F'-' '{ print $4 }')
		rH=$(echo "$t" | awk -F'-' '{ print $5 }')
		rM=$(echo "$t" | awk -F'-' '{ print $6 }')
		rS=$(echo "$t" | awk -F'-' '{ print $7 }')
		timestamp=$(date --date="$ry-$rm-$rd $rH:$rM:$rS" +"%s")

		local cnt=0
		while IFS='' read -r line || [[ -n "$line" ]]; do
			if (( cnt == 0 )); then
					echo -n "\"$line\" "
			fi
			if (( cnt == 1 )); then
				echo -n "from: $line "
			fi
			cnt=$(( cnt + 1 ))
		done < "$f"
		echo -n "at $ry.$rm.$rd $rH:$rM:$rS"
		echo ""
	done

	read -rsn1 action
	#echo "choosen: $action ${rms[$action]}"
	local total_lines="$(wc -l ~/.commash/logs/${rms[$action]} | awk '{ print $1 }')"


	local dest=""
	local src=""
	cnt=0
	while IFS='' read -r line || [[ -n "$line" ]]; do
		if (( cnt == total_lines - 1 )); then
			local dest="$(echo $line | awk '{print $NF}')"
			#echo "destination: $dest"
		elif (( cnt > 1 )); then
			src="$src $(echo $line | awk '{print $NF}')"
			#echo "source: $(echo $line | awk '{print $NF}') "
		fi
		cnt=$(( cnt + 1 ))
	done < "$f"

	if [[ -d $dest ]]; then
		for s in $src; do
				echo ",: Do you want to revert the change by removing $dest/$src?"
				echo ",:    /bin/rm -f $dest/$s"
				if csfunc_yesno; then
					/bin/rm -f $dest/$s
				fi
		done
	fi
	if [[ -f $dest ]]; then
		for s in $src; do
			echo ",: Do you want to revert the change by removing $dest?"
			echo ",:    /bin/rm -f $dest/$s"
			if csfunc_yesno; then
				/bin/rm -fr $dest/$s
			fi
		done
	fi
}
alias ,revert_cp="csfunc_revert_cp"
