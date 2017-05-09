#!/usr/bin/env bash
# https://github.com/nesro/commash

# TODO: zsh handles this better. look at how they does it

# TODO: make some logic before suggesting. f.ex.: suggest cd only if there
# is only one arg and it's a dir, gcc only if there are come .c files and so on
# maybe something like this already exists?

# TODO: user probably wants to remove the bad command from history and
# fix/run it?

# use "help history" to read about the hisory command

# TODO: look how shopt -o cdspell works

#-------------------------------------------------------------------------------

# instead of using commash hook, you can use command_not_found_handle.
# look into man bash and search for "not_found_handle".
#
# this solution will work even with custom command_not_found_handle function
# until its return code is 127
#
# EDIT: if we make all the handling better than the default, maybe it's ok
# to "delete" the command_not_found_handle:
#
# the original not_found_handle is here:
# #http://bazaar.launchpad.net/~ubuntu-branches/ubuntu/vivid/command-not-found/vivid/view/head:/bash_command_not_found
# this mechanism is available in our handler too
command_not_found_handle() { return 127; }

#-------------------------------------------------------------------------------

cs_NOTFOUND_NOHISTORY_LASTCMD=""

# TODO: this is too slow. reduce commans to some basic ones?
# XXX: or we can write a faster python searcher?
# cs_NOTFOUND_NOHISTORY_FIXLIST="$(ls /bin)$(ls /usr/bin)"
cs_NOTFOUND_NOHISTORY_FIXLIST="source alias cd declare typeset dirs disown echo
eval exec exit export fc fg hash help history jobs kill let local printf popd
printf pushd pwd read readonly set test type umask unalias unset wait base64
basename cat chcon chgrp chmod chown chroot cksum comm cp csplit cut date dd
df dirname du env false head hostid id install join kill link ln ls md5sum
mkdir mkfifo mknod mktemp mv nice nl nohup nproc od paste readlink realpath rm
rmdir seq sleep sort split stat sum sync tail tee test touch tr true uname
uniq unlink uptime users wc who whoami yes git gcc gedit nano vim vi"

csfunc_nofound_nohistory_revert() {
	echo ",notfound_nohistory: adding: $cs_NOTFOUND_NOHISTORY_LASTCMD"
	history -s $cs_NOTFOUND_NOHISTORY_LASTCMD
}
alias ,notfound="csfunc_nofound_nohistory_revert"
alias ,n="csfunc_nofound_nohistory_revert"

csfunc_remove_from_history() {
	local cmd="$1"
	local lastcmd

	# we don't need to remove commands from this file, because we will
	# delete the files even before the history is written there
	#local hist=${HISTFILE:-~/.bash_history}

	# if the user makes f.ex. history -w or -a after every command, this hook
	# will not work

	lastcmd=$(history | tail -1)

	if [[ ! $lastcmd =~ $cmd ]]; then
		echo ",notfound_nohistory: something went wrong. lastcmd !=~ cmd."
		return
	fi

	cs_NOTFOUND_NOHISTORY_LASTCMD="$(echo "$lastcmd" | awk '{ $1=""; print $0 }')"
	echo ",notfound_nohistory: removing notfound command:$cs_NOTFOUND_NOHISTORY_LASTCMD"
	history -d "$(echo "$lastcmd" | awk '{ print $1 }')"

	echo ",notfound_nohistory: run ,notfound (or ,n) to inject the command back to history"
}

cshook_nofound_nohistory_after() {
	local timestamp="$1"
	local cmd="$2"

	if (( cs_rc == 127 )); then

		echo ",notfound: Command not found."

		local cmdcmd
		# counter of suggestions
		local cmdcnt=1
		declare -a cmds
		local choice=1
		local anyhint=0
		local newcmd

		cmdcmd="$(echo "$cmd" | awk '{ print $1 }')"

		for i in $cs_NOTFOUND_NOHISTORY_FIXLIST; do
			if (( $(csfunc_levenshtein "$i" "$cmdcmd") == 1 )); then
				newcmd="$i$(echo "$cmd" | awk '{ $1=""; print $0 }')"
				echo ",notfound: [$cmdcnt] choose: \"$newcmd\""
				cmds[$cmdcnt]="$newcmd"
				cmdcnt=$(( cmdcnt + 1 ))
				anyhint=1
				# return
				# break
			fi
		done

		echo ",notfound: [a]bort executing"
		echo ",notfound: [e]dit the wrong command"
		# TODO: search all /bin /usr/bin and suggest it?
		# echo ",notfound: suggest [m]ore commands"
		if [[ $anyhint == 1 ]]; then
			echo ",notfound: [p]re-type edited"
		fi
		echo ",notfound: [s]uggest package for \"$cmdcmd\""
		echo ",notfound: [r]emove command from history"
		while read -rn1 k; do
			echo
			case "$k" in
				[1-9])
					echo ",notfound: choosing: ${cmds[$k]}"
					choice=$k
					continue
					;;
				a) #abort
					return 1
					;;
				e) #edit
					csfunc_pretype "$cmd"
					return 1
					;;
				p) #print edited
					csfunc_pretype "${cmds[$choice]}"
					return 1
					;;
				R)
					return 0
					;;
				r)
					csfunc_remove_from_history "$cmd"
					return 1
					;;
				s)
					if [[ -x /usr/lib/command-not-found ]]; then
						echo ",notfound: executing: /usr/lib/command-not-found -- \"$cmdcmd\""
						/usr/lib/command-not-found -- "$cmdcmd"
					else
						echo ",notfound: script /usr/lib/command-not-found not found"
					fi
					return 1
					;;
				q)
					echo ",notfound: quit?"
					return 1
					;;
				*)
					echo ",notfound: [aepst] or ctrl-c"
					;;
			esac
		done

		# [nyae]
		# [1-9]aer
		#  ^-- 1-9 execute command
		#      ^-- a = abort
		# csfunc_remove_from_history "$cmd"
	fi
}

csfunc_hook_add_after 1000 'cshook_nofound_nohistory_after'
cs_HOOK_NOTFOUND_ACTIVE=1
