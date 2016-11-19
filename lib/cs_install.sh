#!/bin/bash

#-------------------------------------------------------------------------------
# Install
#
# We check at the beginning of this script if installation is needed.

cs_install_commash() {
	[[ $cs_INTERNAL_DEBUG =~ install|all ]] && set -xv
	
	if [[ ! -d $cs_ROOTDIR ]]; then
		echo "The directory \"$cs_ROOTDIR\" doesn't exists. Please clone the "
			"repository here."
		exit 1
	fi
	
	if [[ ! -f $cs_COMMA_SH ]]; then
		echo "The file \"$cs_COMMA_SH\" doesn't exists. It should be this file."
			"Please clone the repository here."
		exit 1
	fi
	
	#TODO: include some general shellcheck file that have the path as a variable
	if [[ ! -x ~/.cabal/bin/shellcheck ]]; then
		cat <<EOF
It seems you don't have shellcheck. You need that in this version.
Rerun this script after you have it.

Please install shellcheck into: ~/.cabal/bin/shellcheck

You can do it on Ubuntu like this:
sudo add-apt-repository universe
sudo apt-get install cabal-install
cabal update
cabal install shellcheck
EOF
		exit 1
	fi
	
	if echo "$cs_RC_HOOK" >> ~/.bashrc; then
		echo ",: Commash hook was added into your ~/.bashrc"
	else
		echo ",: There is a problem writing into your ~/.bashrc"
		exit 1
	fi
	
	# TODO: add check if .bash_logout exists
	if sed -i "1i$cs_LOGOUT_HOOK" ~/.bash_logout; then
		echo ",: Commash logout hook was added into your ~/.bash_logout"
	else
		echo ",: There is a problem writing into your ~/.bash_logout"
		exit 1
	fi
}

cs_run_install_if_needed() {
	if [[ -z $BASH_VERSION ]]; then
		echo ",: Only Bash shell is supported."
		exit 1
	fi

	# If there is no CS hook in .bashrc, run install.
	if ! grep "$cs_RC_HOOK_GREP" ~/.bashrc >/dev/null 2>&1; then
		cs_install_commash
	fi
}

#-------------------------------------------------------------------------------
# Uninstall

cs_run_uninstall() {
	[[ $cs_INTERNAL_DEBUG =~ install|all ]] && set -xv
	
	if sed -i "/$cs_RC_HOOK_SED/d" ~/.bashrc; then
		echo ",: Removed commash hook from .bashrc"
	else
		echo ",: Tried to remove commash hook from .bashrc, but it failed."
	fi
	
	if sed -i "/$cs_LOGOUT_HOOK/d" ~/.bash_logout; then
		echo ",: Removed commash hook from ~/.bash_logout"
	else
		echo ",: Tried to remove commash hook from ~/.bash_logout, but it failed."
	fi
	
	echo ",: If you want to delete the commash directory, run:"
	echo ",: rm -fr $cs_ROOTDIR"
}

