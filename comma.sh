#!/usr/bin/env bash
# https://github.com/nesro/commash
#
# feeling brave? try to run:
# set -T;trap : DEBUG;:&&:&

# welcome
echo ",:"
echo ",: Welcome to Comma-shell! Please note that there may be bugs. " \
	"Don't hesitate to contact me at: nesro@nesro.cz"
echo ",:"

# if you want to disable commash for a new bash instance:
# env cs_DISABLED=1 bash
cs_DISABLED=${cs_DISABLED:-}
if [[ -n "${cs_DISABLED}" ]]; then
	>&2 echo ",: commash is disabled"
	return 0
fi


# version checking
cs_VERSION="$(cat ~/.commash/VERSION)"
if ! type wget >/dev/null 2>&1; then
	echo ",version: version was not checked, because wget is missing"
	sleep 1
fi
if ! cs_VERSION_tmp="$(wget https://raw.githubusercontent.com/nesro/commash/master/VERSION -q -O -)"; then
	echo ",: !!!"
	echo ",version: version was not checked, cannot wget https://raw.githubusercontent.com/nesro/commash/master/VERSION"
	echo ",: !!!"
	sleep 3
else
	if [[ "$cs_VERSION_tmp" != "$cs_VERSION" ]]; then
		echo ",version: You use old version of Comma-shell!"
		echo ",version: Your version: $cs_VERSION"
		echo ",version: Latest version: $cs_VERSION_tmp"
		echo ",version: Please download latest version:"
		echo "    git pull"
		echo ""
		sleep 1
	fi
fi

if [[ -n "$cs_XTRACE" ]]; then
	set -x
else
	set +x
fi

# for ultimate and quick debugging, just uncomment this line
# set -xv

#-------------------------------------------------------------------------------

# TODO: add some nice text since this is the first file people will open
# if they want to look how commash works

#-------------------------------------------------------------------------------

if [[ -n "$cs_SOURCED" ]]; then
	>&2 echo -e "\n!!! commash has been already sourced."
	return 1
else
	cs_SOURCED=1
fi

#-------------------------------------------------------------------------------

# shellcheck disable=SC2034
cs_VERSION_LONG="Commash - version $cs_VERSION"

#-------------------------------------------------------------------------------

for f in ~/.commash/lib/cs_*.sh; do
	# shellcheck source=/dev/null
	source "$f"
done

#-------------------------------------------------------------------------------

if [[ -n "$cs_XTRACE" ]]; then
	set -x
fi

#-------------------------------------------------------------------------------

# main function is in lib/cs_load.sh
csfunc_main || >&2 echo "Commash seems to be broken. :("
