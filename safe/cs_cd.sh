#!/usr/bin/env bash
# https://github.com/nesro/commash

# builtin cd

# man page: help cd
# source code: http://git.savannah.gnu.org/cgit/bash.git/tree/builtins/cd.def

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
			# TODO: check only valid arguments (from "help cd"), oterwise raise an
			# error
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
