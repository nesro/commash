#-------------------------------------------------------------------------------
# BASH 4.4 pre-post cmd
csfunc_ps0() {
	csfunc_inside=1
	trap '' DEBUG
	#>&2 echo "[PS0]"

	csfunc_run_user_cmd

	trap 'csfunc_debug_trap44' DEBUG
	csfunc_inside=0
}
PS0='$(csfunc_ps0)\n'
csfunc_debug_trap44() {
	#>&2 echo "BASH_COMMAND=\"$BASH_COMMAND\" csfunc_inside=\"$csfunc_inside\""
	if [[ $BASH_COMMAND =~ ^csfunc_ ]] || [[ $csfunc_inside == 1 ]]; then
		return 0
	fi
	return 1
}
csfunc_debug_trap_enable44() {
	shopt -s extdebug
	trap 'csfunc_debug_trap44' DEBUG
}

cstest=XXX
csfunc_run_user_cmd() {
	cmd=$(HISTTIMEFORMAT='' history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//")
	cs_timestamp=$(date +%Y-%m-%d-%H-%M-%S-%N)

	if csfunc_hook_iterate_before "$cs_timestamp" "$cmd"; then



		>&2 echo "going to eval=\"$cmd\" rc=\"$cs_rc\" last=\"$cs_last\" test=$cstest"
csfunc_restore_internals $cs_rc \"$cs_last\"
		eval "
csfunc_restore_internals $cs_rc \"$cs_last\"

$cmd



cs_bash_internals=\"\${_}CSDELIMETER\${?}\"
"
		cs_rc=$(echo "$cs_bash_internals" | awk -F "CSDELIMETER" '{ print $2 }')
		export cs_rc
		cs_last=$(echo "$cs_bash_internals" | awk -F "CSDELIMETER" '{ print $1 }')
		export cs_last

		>&2 echo "cs_bash_internals=\"$cs_bash_internals\" cs_rc=\"$cs_rc\" cs_last=\"$cs_last\""

		csfunc_hook_iterate_after "$cs_timestamp" "$cmd"
	else
		>&2 echo ",: prevented execution of $cmd"
	fi


	>&2 echo "finished to eval=\"$cmd\" rc=\"$cs_rc\" last=\"$cs_last\""


}
