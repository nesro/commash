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

# TODO: check if the user is doing: cd -, cd $_
csfunc_cd()  {
		if (( $# == 0 )); then
				echo ",: cd to ~, which is $HOME"
				cd
				return
		fi

		if (( $# > 1 )); then
			echo ",: cd was run with more than argument. this extended " \
			"functionality is not supported yet. so we will just execute your command"
			echo ", executing: cd $@"
			cd "$@"
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
