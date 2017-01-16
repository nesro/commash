#!/usr/bin/env bash

cshook_bashlex_simple_before() {
	local timestamp="$1"
	local cmd="$2"

	~/.commash/debugger/cs_bashlex.py "$cmd"
}

csfunc_hook_add_before 'cshook_bashlex_simple_before'
