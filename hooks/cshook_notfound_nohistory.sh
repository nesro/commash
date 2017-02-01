#!/usr/bin/env bash

# use "help history" to read about the hisory command

#-------------------------------------------------------------------------------

# instead of using commash hook, you can use command_not_found_handle
# look into man bash and search for "not_found_handle".
#
# this soulution will work even with custom command_not_found_handle function
# until its return code is 127

# command_not_found_handle() {
# 	return 127
# }

#-------------------------------------------------------------------------------

cs_NOTFOUND_NOHISTORY_LASTCMD=""

csfunc_nofound_nohistory_revert() {
	echo ",notfound_nohistory: adding: $cs_NOTFOUND_NOHISTORY_LASTCMD"
	history -s $cs_NOTFOUND_NOHISTORY_LASTCMD
}
alias ,notfound="csfunc_nofound_nohistory_revert"

csfunc_remove_from_history() {
	local cmd="$1"

	# we don't need to remove commands from this file, because we will
	# delete the files even before the history is written there
	#local hist=${HISTFILE:-~/.bash_history}

	# if the user makes f.ex. history -w or -a after every command, this hook
	# will not work

	local lastcmd=$(history | tail -1)

	if [[ ! $lastcmd =~ $cmd ]]; then
		echo ",notfound_nohistory: something went wrong. lastcmd !=~ cmd."
		return
	fi

	echo ",notfound_nohistory: removing notfound command: $lastcmd"

	cs_NOTFOUND_NOHISTORY_LASTCMD="$(echo $lastcmd | awk '{ print $2 }')"
	history -d $(echo $lastcmd | awk '{ print $1 }')

	echo ",notfound_nohistory: run ,notfound to inject the command back to history"
}

cshook_nofound_nohistory_after() {
	local timestamp="$1"
	local cmd="$2"

	if (( cs_rc == 127 )); then
		csfunc_remove_from_history "$cmd"
	fi
}

csfunc_hook_add_after 1000 'cshook_nofound_nohistory_after'
