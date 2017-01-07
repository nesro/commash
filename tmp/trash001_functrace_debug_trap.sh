#!/usr/bin/env bash

# bash --norc
# source ~/.commash/tmp/trash001_functrace_debug_trap.sh


#csfunc_debug_trap() {
#	cmd=$(HISTTIMEFORMAT='' history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//")
#	>&2 printf "DEBUGTRAP BASH_COMMAND=\"%30s\" cmd=\"%s\"\n" "$BASH_COMMAND" "$cmd"
#	return 1
#}
#trap 'csfunc_debug_trap' DEBUG

#

#t() {
#	:;
#}
#trap 't' DEBUG




t() {
	if (( $1 > last_lineno )); then
		cmd=$(HISTTIMEFORMAT='' history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//")
		>&2 echo "debug: $cmd"

		eval "$cmd"

		>&2 echo "\$?=$?"

		last_lineno=$1
	fi
	return 1
}
#set -o functrace
shopt -s extdebug
trap '{ t $LINENO ; }' DEBUG
