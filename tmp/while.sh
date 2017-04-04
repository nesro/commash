#!/bin/bash

cat <<EOF
Hi bash-bug,

I think I've found a bug in bash.

I'm working on a project that skips** all commands that are going to be
executed. I achieved this by a combination of a debug trap and extdebug. Once,
for the entire list of commands to be executed, I'm going to execute it via eval
from the debug trap. It works suprisingly well and it opens a possibility of
really cool things.

**Excerpt from man bash extdebug: "If the command run by the DEBUG trap returns
a nonzero value, the next command is skipped and not executed."

I found out that the while cycle is not working, but the for cycle is. Which
made me think that I found a bug in bash.

There are the instructions to reproduce the bug:


# create a new shell
bash --norc


# set up xtrace to see what's happening (not mandatory for reproduction)
set -x


# set up the debug trap with extdebug so that every command is not executed
# (be sure to close and reopen the shell, because trying to set it differnetly
# will not work)
t() { return 1; }
trap t DEBUG
shopt -s extdebug


# run an empty for cycle. we can see from the output that bash ran :, then
# false and stopped to it. which is the right behaviour
for (( :; false; )); do :; done


# now run this while cycle. it just cycle the debug trap forever
while false; do :; done



I've tried it on two versions of bash under lubuntu gnu/linux:
- 4.3.46(1)-release
- 4.4.0(1)-release


Please let me know if I overlooked something, or if this really looks like
a bug.

Thank you,
Tomas Nesrovnal


EOF



# t() { echo $BASH_COMMAND; return 1; }


echo $BASH_VERSION
t() { return 1; }
trap t DEBUG
shopt -s extdebug

for (( ; false ; )); do :; done

while false; do :; done
