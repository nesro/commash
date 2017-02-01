#!/usr/bin/env bash

# Commash hook library

#-------------------------------------------------------------------------------
# Hooks.
# We want to make things modular. Some basic and checking functionality should
# be easily added.


#-------------------------------------------------------------------------------
csfunc_hooks_info() {
	echo ",: Hooks are located in the ~/.commash/hooks directory."
	echo ",: Every hook has a pritority. The lower the number, the higher the priority."
	echo ",: If a loading hook has a priority that is already taken, it has"

	echo ",hooks before:"
	for i in "${!cs_HOOKS_BEFORE[@]}"; do
		echo ",: priority=$i function=${cs_HOOKS_BEFORE[$i]}"
	done
	echo ",hooks after:"
	for i in "${!cs_HOOKS_AFTER[@]}"; do
		echo ",: priority=$i function=${cs_HOOKS_AFTER[$i]}"
	done
}
alias ,hooks="csfunc_hooks_info"
#-------------------------------------------------------------------------------

# $1 == priority. the lower, the higher priority
# $2 == hook function
csfunc_hook_add_before() {
	local priority="$1"

	while [[ -n "${cs_HOOKS_BEFORE[$priority]}" ]]; do
		csfunc_dbg_echo "before hook $2 has the same priority as ${cs_HOOKS_BEFORE[$priority]}, increasing priority"
		priority=$(( priority + 1 ))
	done

	cs_HOOKS_BEFORE[$priority]=$2
}
csfunc_hook_add_after() {
	local priority="$1"

	while [[ -n "${cs_HOOKS_AFTER[$priority]}" ]]; do
		csfunc_dbg_echo "after hook $2 has the same priority as ${cs_HOOKS_AFTER[$priority]}, increasing priority"
		priority=$(( priority + 1 ))
	done

	cs_HOOKS_AFTER[$priority]=$2
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

# XXX: this is unused atm
csfunc_add_timestamp() {
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

	declare -ag cs_HOOKS_BEFORE
	declare -ag cs_HOOKS_AFTER

	cs_HOOKS_DIR=$cs_ROOTDIR/hooks

	# TODO: add a comment what is this and why we need that
	cspc_first=1
	cspc_command_cnt=0

	for hookfile in $cs_HOOKS_DIR/cshook_*.sh; do
		source "$hookfile"
	done
}

csfunc_lib_hooks_unload() {
	:
	# TODO?
}

csfunc_safe_hooks_after() {
	# TODO: list of hooks after safe commands?
	cshook_explain_rc_after
}
