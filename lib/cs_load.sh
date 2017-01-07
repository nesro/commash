#!/usr/bin/env bash

csfunc_main() {
	csfunc_lib_hooks_load
	csfunc_lib_safe_load
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

	for f in $(declare -F | grep csfunc | awk '{ print $3 }'); do
		unset -f $f
	done

	for v in $((set -o posix; set) | grep ^cs_ | awk -F= '{ print  $1 }'); do
		unset $v
	done
}

csfunc_reload() {
	# things we need to save before uloading
	local reload_comma_sh_path="$cs_COMMA_SH"
	local reload_cs_XTRACE="$cs_XTRACE"

	csfunc_unload

	cs_XTRACE="$reaload_cs_XTRACE"

	# shellcheck source=/dev/null
	source "$reload_comma_sh_path"
}
alias ,reload="csfunc_reload"
alias ,r="csfunc_reload"
