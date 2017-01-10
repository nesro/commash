#!/usr/bin/env bash
# https://github.com/nesro/commash

# if you want to disable commash for a new bash instance:
# env cs_DISABLED=1 bash
if [[ -n "$cs_DISABLED" ]]; then
	return 0
fi

if [[ -n "$cs_XTRACE" ]]; then
	set -x
else
	echo "NO DEBUGGING"
	set +x
fi

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

cs_VERSION=0.0.0
cs_VERSION_LONG="Commash - version $cs_VERSION"

#-------------------------------------------------------------------------------

for f in ~/.commash/lib/cs_*.sh; do
	# shellcheck source=/home/n/.commash/lib/cs_commands.sh
	# shellcheck source=/home/n/.commash/lib/cs_debugger.sh
	# shellcheck source=/home/n/.commash/lib/cs_debug_trap.sh
	# shellcheck source=/home/n/.commash/lib/cs_history.sh
	# shellcheck source=/home/n/.commash/lib/cs_hooks.sh
	# shellcheck source=/home/n/.commash/lib/cs_install.sh
	# shellcheck source=/home/n/.commash/lib/cs_load.sh
	# shellcheck source=/home/n/.commash/lib/cs_safe.sh
	# shellcheck source=/home/n/.commash/lib/cs_settings.sh
	source "$f"
done

#-------------------------------------------------------------------------------

if [[ -n "$cs_XTRACE" ]]; then
	set -x
fi

#-------------------------------------------------------------------------------

csfunc_main || >&2 echo -e "\n!!! commash is broken :( \
TODO: auto unload things, navigate user how to safely uninstall?\n"
