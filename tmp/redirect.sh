if false; then
if [[ -z $COMMASH_REDIRECT ]]; then
	#rm -f $CSLOG

	# XXX: this doesn't work well (output is messed) if we prepend a command,
	# f.ex: ts | tee -a ...
	# find out why this happen and how to fix this
	# an easy soulution would be write a program that mix up functionality of
	# 'ts' and 'tee'
	# another problem are the special characters in PS1. the logging program
	# could filter these problematic characters
	# the biggest problem atm is that program like 'less' and 'more' doesn't
	# scroll as supposed
	# there is also a problem with buffering.

	# the best solution is to write our version of the "script" program
	# or just use the standard version and write our timestamps to the output
	# file

	#exec > >(cs_ts "out")
	#exec > >(cs_ts "err" >&2)

	# script capture all keyboard activity including deleting characters
	script -q -c "COMMASH_REDIRECT=1 bash -il" -a $CSLOG
	exit $?
else
	echo "commash already redirected"
fi
fi

if false; then

		# eval the commmand and color the output
		echo -en "\033[31m"  ## red
		#eval "$cmd" | while read -r line; do
		while read -r line; do
    		echo -en "\033[36m"  ## blue
    		echo "$line"
   			echo -en "\033[31m"  ## red
		done < <(eval "$cmd")
		cs_rc=${PIPESTATUS[0]}
		echo -en "\033[0m"  ## reset color

		echo ",: mid pwd=$(pwd)"

fi #false
