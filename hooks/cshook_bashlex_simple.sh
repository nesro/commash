#!/usr/bin/env bash
# https://github.com/nesro/commash

# echo "(the year is $(date +%Y)" | grep 2017
# cs_debugger_on=1

cshook_bashlex_simple_before() {
	local timestamp="$1"
	local cmd="$2"
	local bashlex_out

	# TODO: dont show anything if there is nothing to show?
	# XXX: this is still a problem ^

	if [[ $cs_debugger_on != 1 ]]; then
		return
	fi
	if [[ $cs_debugger_disable_after == 1 ]]; then
		cs_debugger_disable_after=0
		cs_debugger_on=0
	fi

	echo -e ",: commash debugger:\n"

	bashlex_out=$(~/.commash/debugger/cs_bashlex.py "$cmd")

	OLDIFS=$IFS
	IFS=$'\n' lines=($bashlex_out)
	IFS=$OLDIFS

	>&2 echo -ne "\n,: Select your option, [0] debug whole cmd, [q]uit, [r]un normally "
	while :; do
		read -rn1 key
		echo

		if [[ $key == r ]]; then
			echo ",: Continuing to run: \"$cmd\""
			return 0
		fi

		if [[ $key == q ]]; then
			echo ",: Nothing is going to be executed."
			return 1
		fi

		# we are counting the choices from 1. seems more natural
		key=$(( key - 1))

		# TODO: check the range, XXX: this is obviously not right
		if (( key < 9 )); then

			if (( key == -1 )); then
				echo ",: Executing: \"$cmd\""
				eval "$cmd"
			else
				echo ",: Executing: \"${lines[$key]}\""
				echo "XXX"
				#eval "${lines[$key]}"
			fi

			#
			echo
			echo ",: What now? [q]uit, [p]retype and debug just the next command"
			while read -rsn1 n; do
				case "$n" in
					q)
						break
						;;
					p)
						cs_debugger_on=1
						cs_debugger_disable_after=1

						echo

						# we need to make things async (&) to be sure the prompt is written
						# before the pretyped text
						( csfunc_pretype "$cmd" & ) >/dev/null 2>&1
						return 1

						# cs_pretype_and_exit=1
						# break
						;;
					*)
						echo "[q]uit or [p]retype"
						;;
				esac
			done


			# # XXX: bash is slow?
			# if [[ $cs_pretype_and_exit == 1 ]]; then
			# 	csfunc_pretype "$cmd" &
			# 	return 1
			# fi

			# do not execute the command after we evaled it
			return 1
		fi
	done

	# while IFS= read ; do
	#     echo "line: $REPLY"
	# done <<< "$bashlex_out"

	# echo "$bashlex_out"
	# OLDIFS=$IFS
	# IFS=CSDELIMETER
	# set "$bashlex_out"
	# IFS=$OLDIFS
	# local expld="$1"
	# local anoth="$2"
	# echo "!!EXPLD: $expld :EXPLD!!"
	# echo "--ANOTH: $anoth :ANOTH--"

}

# OUT="<actual output>"
# CHOICES="[1] adfasddfasdfsaddf CSDELIMETER [2] "

csfunc_hook_add_before 1000 'cshook_bashlex_simple_before'
