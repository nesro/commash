#!/usr/bin/env bash
# https://github.com/nesro/commash

csfunc_main() {

	if ! csfunc_run_install_if_needed; then
		>&2 echo ",: commash won't load because it's not installed properly"
		return 1
	fi

	csfunc_lib_hooks_load
	csfunc_lib_safe_load
	csfunc_lib_tips_load
	#csfunc_lib_debugger_load


	# XXX: since we're not using new things from 4.4, this is not needed atm
	# case $BASH_VERSION in
	# 4.4*)
	# 	echo "You have bash 4.4. Nice!"
	# 	;;
	# 4.3*)
	# 	echo "You have bash 4.3."
	# 	;;
	# *)
	# 	echo "Either you're not using bash, or you use some older version. " \
	# 		"Commash might not work."
	# 	;;
	# esac

  csfunc_debug_trap_enable

	csfunc_welcome

	# see: csfunc_while
	alias while="csfunc_while; while csfunc_while_false_guard && "

	return 0
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
		unset -f "$f"
	done

	# unload variables
	for v in $( (set -o posix; set) | grep ^cs_ | awk -F= '{ print $1 }'); do

		# and I wondered why this variable doesn't survive reload :))
		if [[ $v == cs_XTRACE ]]; then
			continue
		fi

		unset "$v"
	done

	# see: csfunc_while
	unalias while
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
