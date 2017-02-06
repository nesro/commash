#!/usr/bin/env bash

# example usage: csfunc_load_settings a.txt cs_VAR ,
csfunc_load_settings() {
	local file="$1"
	local variable="$2"
	local spacer="$3"
	local tmp

	tmp=$(grep -o '^[^#]*' "$file" | tr -d ' ' | paste -s -d "$spacer")
	eval "$variable=\$tmp"

  ## this was probably too much pointlessly useless
	# cssc_disable=""
	# while IFS='' read -r line || [[ -n "$line" ]]; do
	# 	line=$(echo "$line" | awk -F'#' '{ print $1 }' | tr -d ' ')
	# 	if [[ -z "$line" ]]; then
	# 		continue
	# 	fi
	# 	if [[ -z "$cssc_disable" ]]; then
	# 		cssc_disable="$line"
	# 	else
	# 		cssc_disable="$cssc_disable,$line"
	# 	fi
	# done < "$cssc_disable_list_file"
}

csfunc_yesno() {
	while read -rn1 k; do
		case "$k" in
			y)
				return 0
				;;
			n)
				return 1
				;;
			*)
				echo ",yn: press [y]es or [n]o"
				;;
		esac
	done
}

csfunc_run_cmd_ask() {
	echo ",: Please confirm runnnig: \"$@\"? [y]es [n]o"
	if csfunc_yesno; then
		eval "$@"
	else
		echo ",: command \"$@\" was NOT run"
	fi
}

csfunc_plural_s() {
	if (( $1 > 1 )); then
		echo "s"
	fi
}


#-------------------------------------------------------------------------------

# https://en.wikipedia.org/wiki/Levenshtein_distance
# bash source based on:
# https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance#Bash
# but refactored a bit and replaced /usr/bin/seq, sort and head calls with builtins
csfunc_levenshtein() {
	if [ "${#1}" -lt "${#2}" ]; then
		csfunc_levenshtein "$2" "$1"
	else

		# if (( (${#1} - ${#2}) < 2 )); then
		# 	echo "$1 a $2 rovnou ne?"
		# fi

		local str1len=$((${#1}))
		local str2len=$((${#2}))
		local d i j
		for (( i=0 ; i <= $(((str1len+1)*(str2len+1))) ; i++ )); do
		# for i in $(seq 0 $(((str1len+1)*(str2len+1)))); do
			d[i]=0
		done
		for (( i=0 ; i <= str1len; i++ )); do
		# for i in $(seq 0 $((str1len)));	do
			d[$((i+0*str1len))]=$i
		done
		for (( j=0 ; j <= str2len; j++ )); do
		# for j in $(seq 0 $((str2len)));	do
			d[$((0+j*(str1len+1)))]=$j
		done

		for (( j=1 ; j <= str2len; j++ )); do
		# for j in $(seq 1 $((str2len))); do
			for (( i=1 ; i <= str1len; i++ )); do
			# for i in $(seq 1 $((str1len))); do
				[ "${1:i-1:1}" = "${2:j-1:1}" ] && local cost=0 || local cost=1
				local del=$((d[(i-1)+str1len*j]+1))
				local ins=$((d[i+str1len*(j-1)]+1))
				local alt=$((d[(i-1)+str1len*(j-1)]+cost))

				# ok. I think I should keep this line..
				# d[i+str1len*j]=$(echo -e "$del\n$ins\n$alt" | sort -n | head -1)
				if (( alt < del )); then
					if (( alt < ins )); then
						d[i+str1len*j]=$alt
					else
						d[i+str1len*j]=$ins
					fi
				else
					if (( del < ins )); then
						d[i+str1len*j]=$del
					else
						d[i+str1len*j]=$ins
					fi
				fi
			done
		done
		# >&2 echo lev ${d[str1len+str1len*(str2len)]} $1 $2
		echo ${d[str1len+str1len*(str2len)]}
	fi
}

#-------------------------------------------------------------------------------

# I bet this is not the best way how pre-type a command. but it works :)
# TODO: find a real way how to do it
csfunc_pretype() {
	# sleep is needed for giving bash time to show next prompt
	# both commands needs to be run on background bash can show next prompt
	# output about process end is redirected to /dev/null
	( sleep 0.1; xdotool type "$1" & ) >/dev/null 2>&1
}













# EOF
