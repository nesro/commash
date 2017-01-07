#!/usr/bin/env bash

# Commash hook library

#-------------------------------------------------------------------------------
# Hooks.
# We want to make things modular. Some basic and checking functionality should
# be easily added.

csfunc_hook_add_before() {
	cs_HOOKS_BEFORE+=("$1")
}
csfunc_hook_add_after() {
	cs_HOOKS_AFTER+=("$1")
}

# The hook functions are called like this:
# <hook> <command timestamp> <command>
csfunc_hook_iterate_before() {
	local ret=0
	for i in "${!cs_HOOKS_BEFORE[@]}"; do
		if ! ${cs_HOOKS_BEFORE[$i]} "$1" "$2"; then
			ret=1
		fi
	done

	return $ret
}
csfunc_hook_iterate_after() {
	for i in "${!cs_HOOKS_AFTER[@]}"; do
		${cs_HOOKS_AFTER[$i]} "$1" "$2"
	done
}

#csfunc_hook_init() {
#	csfuncs_hook_source
#}

#-------------------------------------------------------------------------------

cs_add_timestamp() {
	while read -r line; do
    		echo "$(date +%Y-%m-%d-%H-%M-%S-%N)|$1|$line" >> /tmp/.cslog
    		echo "$line"
	done
}

#-------------------------------------------------------------------------------

csfunc_check_var() {
	eval "v=\$$1"
	if [[ -z "$v" ]]; then
		>&2 echo ", FATAL: var $1 is not loaded."
	fi
}

csfunc_lib_hooks_load() {
	csfunc_check_var cs_ROOTDIR

	cs_HOOKS_BEFORE=()
	cs_HOOKS_AFTER=()
	cs_HOOKS_DIR=$cs_ROOTDIR/hooks


	# TODO: add a comment what is this and why we need that
	cspc_first=1
	cspc_command_cnt=0

	for hookfile in $cs_HOOKS_DIR/cshook_*.sh; do
		source $hookfile
	done

}

csfunc_lib_hooks_unload() {
	:
	# TODO?
}
