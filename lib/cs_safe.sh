#!/usr/bin/env bash
# https://github.com/nesro/commash

# Commash safe-commands library

#-------------------------------------------------------------------------------


# was: save paths to commands so we can use them even in the safe mode
# we don't need to save paths, because we're going to use aliases
# cs_RM=$(which rm)
# cs_TOUCH=$(which touch)
# cs_SED=$(which sed)
# cs_TAIL=$(which tail)

cs_SAFE_COMMANDS="cd rm cp mv chmod chown chgrp"

csfunc_lib_safe_load() {
	# XXX: we will not modify the PATH variable.
	#cs_PATH_BACKUP="$PATH"
	#PATH="$cs_ROOTDIR/safe:$PATH"
	# chmod +x /home/n/.commash/safe/*

	source ~/.commash/safe/cs_safe_common.sh
	source ~/.commash/safe/cs_ch_common.sh
	mkdir -p ~/.commash/logs

	for a in $cs_SAFE_COMMANDS; do
		if [[ -f $cs_ROOTDIR/safe/cs_$a.sh ]]; then
			# shellcheck source=/dev/null
			source "$cs_ROOTDIR/safe/cs_$a.sh"
			eval "alias \$a=\"csfunc_\$a\""
			eval "alias ,\$a=\"csfunc_\$a\"_cswrapp"
		else
			>&2 echo ",error: no file for alias $a"
		fi
	done
}

csfunc_lib_safe_unload() {
	#PATH="$cs_PATH_BACKUP"

	for a in $cs_SAFE_COMMANDS; do
		unalias "$a"
	done
}

#-------------------------------------------------------------------------------
# bash builtins - they are not stored in a file
# we can override their names with aliases

# OK. I think aliases are better for everything (even commands from coreutils)
# because we don't want to run these safe commands from shell scripts

# builtins: source, alias, bg, bind, break, builtin, caller, cd, command,
# compgen, complete, compopt, continue, declare, typeset, dirs, disown, echo,
# enable, eval, exec, exit, export, fc, fg, getopts, hash, help, history, jobs,
# kill, let, local, mapfile, readarray, popd, printf, pushd, pwd, read,
# readonly, return, set, shift, shopt, suspend, test, times, trap, type, ulimit,
# umask, unalias, unset, wait
