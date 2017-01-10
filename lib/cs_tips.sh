#!/usr/bin/env bash

# we want to show some tips or useful information
# but we also want to turn off the tips users already know

cs_TIPS_BLACKLIST_FILE="$cs_ROOTDIR/settings/cs_tips_blacklist.txt"
cs_TIPS_BLACKLIST=
cs_TIPS_VERBOSE=

csfunc_tip() {
  local tip_name="$1"
  local tip_content="$2"

	if [[ $cs_TIPS_BLACKLIST =~ $tip_name ]]; then
		return
	fi

	echo ",tip: $tip_content (#$tip_name)"
}

csfunc_tip_load_blacklist() {
	csfunc_load_settings $cs_TIPS_BLACKLIST_FILE cs_TIPS_BLACKLIST ,
}

csfunc_lib_tips_load() {
	csfunc_tip_load_blacklist
}

csfunc_lib_tips_unload() {
  :
}
