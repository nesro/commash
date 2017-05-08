

csfunc_ch_cswrapp() {
	local cmd="$1"
	shift
	local save_opts=("$@")
	local logfile ts

	#-----------------------------------------------------------------------------

	dest="${@: -1}"
	ts=$(date +%Y-%m-%d-%H-%M-%S-%N)

	echo ",$cmd: dest=$dest"

	if ! csfunc_save_perm "$dest" ~/.commash/logs/perm-"$ts"; then
		echo ",$cmd: cannot save perms?"
	fi

	if [[ $cmd == "chmod" ]]; then
		echo ",chmod: Do to want to run: [y/n]"
		echo ",chmod:    /bin/chmod ${save_opts[@]}"
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

	if [[ $cmd == "chown" ]]; then
		echo ",chown: Do to want to run: [y/n]"
		echo ",chown:    /bin/chown ${save_opts[@]}"
		if csfunc_yesno; then
			if /bin/chown "${save_opts[@]}"; then
				logfile=~/.commash/logs/chown-"$ts"
				touch "$logfile"
				echo "$(csfunc_lasthist)" > "$logfile"
				echo $PWD >> "$logfile"
			else
				echo ",chown: it failed"
			fi
		else
			return
		fi
	fi

	if [[ $cmd == "chgrp" ]]; then
		echo ",chgrp: Do to want to run: [y/n]"
		echo ",chgrp:    /bin/chgrp ${save_opts[@]}"
		if csfunc_yesno; then
			if /bin/chgrp "${save_opts[@]}"; then
				logfile=~/.commash/logs/chgrp-"$ts"
				touch "$logfile"
				echo "$(csfunc_lasthist)" > "$logfile"
				echo $PWD >> "$logfile"
			else
				echo ",chgrp: it failed"
			fi
		else
			return
		fi
	fi
}

#-------------------------------------------------------------------------------

# http://stackoverflow.com/questions/3450250/is-it-possible-to-create-a-script-to-save-and-restore-permissions

# $1 = from what
# $2 = from where
csfunc_save_perm() {
	local file="$1"
	local log="$2"
	if find "$file" -depth -printf '%m:%u:%g:%p\0' >"$log"; then
		return 0
	else
		return 1
	fi
}

csfunc_restore_perm() {
	local from="$1"
	local log="$2"
	( builtin cd $from &&
	while IFS=: read -r -d '' mod user group file; do
		echo ",: $file: mod=$mod user=$user group=$group"
		chmod "$mod" "$file"
		chown -- "$user:$group" "$file"
	done <"$log" )
}
#-------------------------------------------------------------------------------
