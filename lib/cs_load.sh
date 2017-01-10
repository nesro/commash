#!/usr/bin/env bash

csfunc_main() {
	csfunc_lib_hooks_load
	csfunc_lib_safe_load
	csfunc_lib_tips_load
	#csfunc_lib_debugger_load
	csfunc_run_install_if_needed


	case $BASH_VERSION in
	4.4*)
		echo "You have bash 4.4. Nice!"
		;;
	4.3*)
		echo "You have bash 4.3."
		;;
	*)
		echo "Either you're not using bash, or you use some older version. " \
			"Commash might not work."
		;;
	esac

  csfunc_debug_trap_enable

	csfunc_welcome
}

csfunc_unload() {
	# this function also recover PROMPT_COMMAND and PS1 from backup
	csfunc_debug_trap_disable
	csfunc_lib_safe_unload

	# we have to remove csfunc_ps4 from PS4, because we will unset this function
	PS4="$cs_PS4_BACKUP"

	# unload aliases
	for a in $(alias | grep ",.*" | awk '{ print $2 }' | awk -F= '{ print $1 }'); do
		unalias "$a"
	done

	# unload functions
	for f in $(declare -F | grep csfunc_ | awk '{ print $3 }'); do
		unset -f $f
	done

	# unload variables
	for v in $( (set -o posix; set) | grep ^cs_ | awk -F= '{ print $1 }'); do

		# and I wondered why this variable doesn't survive reload :))
		if [[ $v == cs_XTRACE ]]; then
			continue
		fi

		unset $v
	done
}

csfunc_reload() {
	# things we need to save before uloading
	local reload_comma_sh_path="$cs_COMMA_SH"

	csfunc_unload

	# shellcheck source=/dev/null
	cs_XTRACE=$cs_XTRACE source "$reload_comma_sh_path"
}
alias ,reload="csfunc_reload"
alias ,r="csfunc_reload"
