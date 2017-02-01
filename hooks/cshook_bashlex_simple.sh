#!/usr/bin/env bash

# echo "(the year is $(date +%Y)" | grep 2017
# cs_debugger_on=1

cshook_bashlex_simple_before() {
	local timestamp="$1"
	local cmd="$2"

	# TODO: dont show anything if there is nothing to show?

	# XXX: is the term debugger right? we are only running parts of the command
	# now
	if [[ $cs_debugger_on != 1 ]]; then
		return
	fi

	echo -e ",: commash debugger:\n"

	local bashlex_out=$(~/.commash/debugger/cs_bashlex.py "$cmd")

	OLDIFS=$IFS
	IFS=$'\n' lines=($bashlex_out)
	IFS=$OLDIFS

	>&2 echo -ne "\n,: Select your option or [q]uit or [r]un normally "
	while :; do
		read -rn1 key

		echo

		if [[ $key == r ]]; then
			echo ",: Continuing to run:"
			echo ",: $cmd"
			return 0
		fi

		if [[ $key == q ]]; then
			echo ",: Nothing is going to be executed."
			return 1
		fi

		# we are counting the choices from 1. seems more natural
		key=$(( key - 1))

		# TODO: check the range, XXX: this is obviously not right
		if (( $key < 9 )); then
			echo ",: Executing: \"${lines[$key]}\""
			eval "${lines[$key]}"

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
