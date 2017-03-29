#!/usr/bin/env bash
# https://github.com/nesro/commash

# we can save a command before bash expands its parameters
# I originaly wanted this for ,rm wrapper, but aliases do not trigger hooks

cshook_save_args_before() {
	local timestamp="$1"
	local cmd="$2"

	cs_CMD="$cmd"
}

csfunc_hook_add_before 1000 'cshook_save_args_before'
