#!/usr/bin/env bash

# Commash safe-commands library

#-------------------------------------------------------------------------------
# save paths to commands so we can use them even in the safe mode
cs_RM=$(which rm)
cs_TOUCH=$(which touch)
cs_SED=$(which sed)
cs_TAIL=$(which tail)

csfunc_lib_safe_load() {
	cs_PATH_BACKUP="$PATH"
	PATH="$cs_ROOTDIR/safe:$PATH"

	# TODO: check if everything is executable and which $cmd is working
	# chmod +x /home/n/.commash/safe/*

	alias cd="csfunc_cd"
}

csfunc_lib_safe_unload() {
	PATH="$cs_PATH_BACKUP"

	unalias cd
}

#-------------------------------------------------------------------------------
# bash builtins - they are not stored in a file
# we can override their names with aliases

# builtins: source, alias, bg, bind, break, builtin, caller, cd, command,
# compgen, complete, compopt, continue, declare, typeset, dirs, disown, echo,
# enable, eval, exec, exit, export, fc, fg, getopts, hash, help, history, jobs,
# kill, let, local, mapfile, readarray, popd, printf, pushd, pwd, read,
# readonly, return, set, shift, shopt, suspend, test, times, trap, type, ulimit,
# umask, unalias, unset, wait

# TODO: check if the user is doing: cd -, cd $_
csfunc_cd()  {
		if (( $# == 0 )); then
				echo ",: cd to ~, which is $HOME"
				builtin cd
				return
		fi

		if (( $# == 1 )) && [[ "$1" == $HOME ]]; then
			csfunc_tip cdhome "You don't need to specify your home directory. Just " \
				"run cd without arguments."
			builtin cd
			return
		fi

		if (( $# == 1 )) && [[ "$1" == "-" ]]; then
			csfunc_tip cddash "todo: print OLD/PWD"
			builtin cd -
			return
		fi

		if (( $# > 1 )); then
			echo ",: cd was run with more than argument. this extended " \
			"functionality is not supported yet. so we will just execute your command"
			echo ", executing: cd $@"
			builtin cd "$@"
			return
		fi

		if [[ ! -d "$1" ]]; then
			echo ",: The directory \"$PWD/$1\" doesn't exists. Do you want to create it? [y]es/[n]o"
			while :; do
				read -rn1 yn
				case $yn in
					y)
						mkdir -p "$1"
						break
						;;
					n)
						echo -e "\n,: No action has been perfomed. PWD=$PWD"
						return
						;;
					*)
						echo "Please press \"y\" or \"n\""
						;;
				esac
			done
			echo # newline afer y or n
		fi

		echo ",: OLDPWD: $OLDPWD"
		echo ",:    PWD: $PWD"
		echo -n ",: NEWPWD: "
    cd "$1"
		pwd
}
