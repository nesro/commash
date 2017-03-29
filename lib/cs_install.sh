#!/bin/bash
# https://github.com/nesro/commash

# git clone https://github.com/nesro/commash ~/.commash
# bash ~/.commash/comma.sh

# list of things we need to take care of:
# commash: extract it into ~/.commash and source the main file from .bashrc

# - install:
# -- commash
# -- packages:
# ----- xdotool (typing commands for us)
# ----- trash-cli (rm trashing ability)
# ----- shellcheck (syntax check pre hook)
# ----- bashlex (command debugger)

csfunc_install_xdotools() {
	if ! type xdotool >/dev/null 2>&1; then
		echo ",install: xdotool is not installed"
		return 1
	fi
	return 0
}

csfunc_install_shellcheck() {
	csfunc_var cs_SHELLCHECK

	#TODO: include some general shellcheck file that have the path as a variable
	if [[ ! -x $cs_SHELLCHECK ]]; then
		echo ",install: installing ShellCheck"

		echo ",install: running command: \"cabal update\""
		if ! cabal update; then
			echo ",install: command \"cabal update\" failed"
			return 1
		fi

		echo ",install: running command: \"cabal install regex-tdfa\""
		if ! cabal install regex-tdfa; then
			echo ",install: command \"cabal install regex-tdfa\" failed"
			return 1
		fi

		echo ",install: running command: \"cabal install shellcheck\""
		if ! cabal install shellcheck; then
			echo ",install: command \"cabal install shellcheck\" failed"
			return 1
		fi
	fi

	return 0
}

csfunc_install_bashlex() {
	if ! ~/.commash/debugger/cs_bashlex_check.py >/dev/null 2>&1; then
		echo ",install: it seems that bashlex is broken. script ~/.commash/debugger/cs_bashlex_check.py has failed"
		return 1
		# echo ",install: installing bashlex, https://github.com/idank/bashlex"
		# echo ",install: running command: \"pip install bashlex\""
		# if ! pip install bashlex; then
		# 	echo ",install: command \"pip install bashlex\" failed"
		# 	return 1
		# fi
	fi
	return 0
}

csfunc_install_trashcli() {
	if ! type trash-restore >/dev/null 2>&1 && ! [[ -x ./trash-cli/trash-restore ]]; then
		echo ",install: installing trash-cli, https://github.com/nesro/trash-cli"

		echo ",install: running command: \"git clone https://github.com/nesro/trash-cli\""
		if ! git clone https://github.com/nesro/trash-cli; then
			echo ",install: command \"git clone https://github.com/nesro/trash-cli\" failed"
			return 1
		fi

		echo ",install: running command: \"cd trash-cli\""
		if ! cd trash-cli; then
			echo ",install: command \"cd trash-cli\" failed"
			return 1
		fi

		echo ",install: running command: \"python setup.py install --user\""
		if ! python setup.py install --user; then
			echo ",install: command \"python setup.py install --user\" failed"
			return 1
		fi

		echo ",install: running command: \"cd ..\""
		if ! cd ..; then
			echo ",install: command \"cd ..\" failed"
			return 1
		fi
	fi
	return 0
}

csfunc_install_commash() {
	# commash alredy installed TODO: add more checks?
	if grep "$cs_RC_HOOK_GREP" ~/.bashrc >/dev/null 2>&1; then
		return 0
	fi

	# if ! grep "$cs_LOGOUT_HOOK" ~/.bash_logout >/dev/null 2>&1; then
	# 	>&2 echo ",install: there is a hook in .bashrc but no logout hook in .bash_logout"
	# 	return 1
	# fi

	if [[ ! -d $cs_ROOTDIR ]]; then
		echo "The directory \"$cs_ROOTDIR\" doesn't exists. Please clone the "
			"repository here."
		return 1
	fi

	if [[ ! -f $cs_COMMA_SH ]]; then
		echo "The file \"$cs_COMMA_SH\" doesn't exists. It should be this file."
			"Please clone the repository here."
		return 1
	fi

	echo ",install: running command: \"echo \"$cs_RC_HOOK\" >> ~/.bashrc\""
	if ! echo "$cs_RC_HOOK" >> ~/.bashrc; then
		echo ",install: There is a problem writing into your ~/.bashrc"
		return 1
	fi

	# TODO: add check if .bash_logout exists
	echo ",install: running command: \"sed -i \"1i$cs_LOGOUT_HOOK\" ~/.bash_logout\""
	if ! sed -i "1i$cs_LOGOUT_HOOK" ~/.bash_logout; then
		echo ",: There is a problem writing into your ~/.bash_logout"
		return 1
	fi

	return 0
}

#-------------------------------------------------------------------------------

csfunc_run_install_if_needed() {
	if [[ -z "$BASH_VERSION" ]]; then
		echo ",install: only BASH is supported."
		return 1
	fi

	for p in commash xdotools shellcheck bashlex trashcli; do
		if ! csfunc_install_$p; then
			>&2 echo ",install: commash is not installed properly."
			return 1
		fi
	done

	return 0
}

#-------------------------------------------------------------------------------
# Uninstall

csfunc_run_uninstall_commash() {
	if sed -i "/$cs_RC_HOOK_SED/d" ~/.bashrc; then
		echo ",uninstall: Removed commash hook from .bashrc"
	else
		echo ",uninstall: Tried to remove commash hook from .bashrc, but it failed."
	fi

	if sed -i "/$cs_LOGOUT_HOOK/d" ~/.bash_logout; then
		echo ",uninstall: Removed commash hook from ~/.bash_logout"
	else
		echo ",uninstall: Tried to remove commash hook from ~/.bash_logout, but it failed."
	fi

	echo ",uninstall: If you want to delete the commash directory, run:"
	echo ",uninstall: rm -fr $cs_ROOTDIR"
}
