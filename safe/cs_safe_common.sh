

# result arr with files is set in: csfunc_list_logs
csfunc_safe_list_logs() {
	local arg_cmd="$1" # cp

	csfunc_list_logs=""
	csfunc_list_items=0

	local i=1
	for f in ~/.commash/logs/"$arg_cmd"-*; do

		if [[ $f =~ ".commash/logs/"$arg_cmd"-*" ]]; then
			return 1
		fi

		t=${f##*/}

		# echo "$f, $t"

		if [[ ! $t =~ "$arg_cmd"-[0-9]* ]]; then
			echo ","$arg_cmd": invalid file in trash: $t"
			return
		fi

		echo -n "    [$i] "
		csfunc_list_logs[$i]=$t
		((csfunc_list_items++))

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

		((i++))

		if (( i >= 10 )); then
			break
		fi
	done

	return 0
}
