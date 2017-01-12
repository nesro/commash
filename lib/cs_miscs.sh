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
