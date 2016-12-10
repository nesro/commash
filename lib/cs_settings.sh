#!/usr/bin/env bash

# Commash settings

#-------------------------------------------------------------------------------

# auto enable commash with .bashrc
cs_AUTOENABLE=1

#-------------------------------------------------------------------------------
# Variables from environment
# These variables are loaded from the ~/.commash/variables.txt

# commash debug mode. in this mode, commash will not be executing commands
# by default and allows to users some sort of debugging
cs_DEBUG=${cs_DEBUG:-0}

# debug commash internals
# list of things that this setting go:
# - show internals of eval, so you can see what is really executing
cs_INTERNAL_DEBUG=${cs_INTERNAL_DEBUG:-"none"}


#-------------------------------------------------------------------------------
# Common functions

[[ $cs_INTERNAL_DEBUG =~ functions|all ]] && set -xv

escape_sed() {
	# http://wiki.bash-hackers.org/syntax/quoting
	sed -e 's/\//\\\//g' -e 's/\&/\\\&/g'
}

[[ $cs_INTERNAL_DEBUG =~ functions|all ]] && set +xv

#-------------------------------------------------------------------------------
# Global variables

[[ $cs_INTERNAL_DEBUG =~ vars|all ]] && set -xv

# Commash
cs_ENABLED=0
cs_ROOTDIR=~/.commash
cs_COMMA_SH=$cs_ROOTDIR/comma.sh
cs_LIBDIR=$cs_ROOTDIR/lib
cs_SAFEDIR=$cs_ROOTDIR/safe
cs_SAFEDIR_SED=$(echo "$cs_SAFEDIR" | escape_sed)
cs_RC_HOOK="if [[ -f $cs_COMMA_SH ]]; then source $cs_COMMA_SH; fi"
cs_RC_HOOK_GREP="if \[\[ -f $cs_COMMA_SH \]\]\; then source $cs_COMMA_SH\; fi"
cs_RC_HOOK_SED=$(echo "$cs_RC_HOOK_GREP" | escape_sed)
cs_LOGOUT_HOOK="cs_LOGOUT=1"

cs_LOCKFILE=$cs_ROOTDIR/lock.commash
cs_LOGFILE=$cs_ROOTDIR/log.commash

cs_ERROR=0

cs_ENABLED=0
cs_DEBUGGER=0

[[ $cs_INTERNAL_DEBUG =~ globvars|all ]] && set +xv

