

csfunc_ch_cswrapp() {
	local cmd="$1"
	shift
	local save_opts=("$@")
	local logfile ts

	#-----------------------------------------------------------------------------

	dest="${@: -1}"

	if [[ $cmd == "chmod" ]]; then

		ts=$(date +%Y-%m-%d-%H-%M-%S-%N)



		echo ",chmod: Do to want to run: [y/n]"
		echo ",chmod:    /bin/chmod "${save_opts[@]}""
		if csfunc_yesno; then

			if getfacl -R $dest > ~/.commash/logs/getfacl-$ts; then
				echo ",chmod: saved facls with getfacl"
			fi

			if /bin/chmod "${save_opts[@]}"; then
				logfile=~/.commash/logs/chmod-"$ts"
				touch "$logfile"
				echo "$(csfunc_lasthist)" > "$logfile"
				echo $PWD >> "$logfile"
			else
				echo ",chmod: it failed"
			fi
		else
			return
		fi
	fi


	#-----------------------------------------------------------------------------

}
