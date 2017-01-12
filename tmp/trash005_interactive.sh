#/usr/bin/env bash

# ah.. this was a test that resulted in that we will not use files such
# as ~/.commash/safe/rm to run our commands. these files would be executed
# even if scripts and we don't want that

pwd
cd /tmp
pwd

if [[ -t 1 ]]; then
	echo a
else
	echo b
fi

alias cd="echo a"
alias

echo "$PATH"

rm /tmp/a
