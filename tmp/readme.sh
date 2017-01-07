
# poor man's multiline bash comment
if false; then
cat <<EOF

TODO:
	- add arguments to ShellCheck (f.ex: disable=SC2164 for enabling cd without
		|| exit)

	- save commands into a history file. store pid of shell, return code of
		the executed command, timestamp

	- add ,info command that tells informations about a file

	- add ,cd command that allows quickly cd directory (from actual dir or
		backwards in current path)

	- save stdout and stderr for every command executed

	- use /tmp to store .commash/lock (/tmp is tmpfs and should be faster)

	- add more layers of safe mode
		- layer 1) don't make any changes, just inform what's happening
		- layer 2) make changes, but backup everything and allow easy
			restoration
			- this resotration space could be in /tmp
			- restoration space will be limited
			- question the user what to do before making a big change
				that would eat up a lot of disk space
			- the ultimate goal is to provide layer 2 without user interaction
				and bothering him while still providing usefull things

	- don't run absolute paths in safe mode (then it wouldn't be safe)

	- add more commands into safe mode (chmod, rm, mv, cp, ln, ...)

	- make some kind of persistent storage of internal variables
		(f.ex.: cs_AUTOENABLE)

	- make some fancy PS1 as an option (time, hostname, path, rc, shlvl)

	- add ,d <command> (debugging of a particular command)

	- inspect commands when rc != 0 and write human-readable info what happened
		(for example "man asdf" returns 16, even if the man write what happend
		 it would be nice if we could do it too)

	- if we want to exit the shell now, the bind is: ctrl-x because ctrl-d

	- the current code rewrites previous PROMPT_COMMAND (which is wrong)

	- refactor function names and variables to be consistent

	- DONE detect things like:
		- $ cd /a
		- $ cd /b
		- $ cd /a
		- and then suggest: cd -

	- refactor debugger (to be more modular) and add more functionality

	- add support for coloring output: white for stdout, red for stderr
		(I can do it, but I cannot change directory while doing that)

	- is the lock file really necessary? maybe a variable would be sufficient
		right now, this commands works fine:
		false || true && ((echo a; (echo b; echo c); echo $(echo d)) && echo "$(echo $(echo $(echo e)))"; echo f) && echo g

	- fix: bash: return: can only `return' from a function or sourced script

	- support more languages (english and czech)

	- todo: make an option to suppress/disable hooks/tips

	- add time in UTC. saving history while operating on servers around the
		world would be easier

	- run safe/unsafe versions of commands by prepending , before them:
		,rm <file>

	- safe version of rm should just move the file to .$origname.csrm

	- add a post-hook that inform you about the command end of execution.
		via email, sound, change of title/screen title

	- save all terminal history with timestamps and return codes?
		https://stackoverflow.com/questions/3173131/redirect-copy-of-stdout-to-log-file-from-within-bash-script-itself


	- check "sudo bash" (?? add check: if [ -O "$HOME" ] for situations when user run bash with sudo and root doesn't have home?)

	- explain this magical code (it just ends the bash): set -T;trap : DEBUG;:&&:&
EOF
fi
