#!/bin/bash

source ~/.commash/commash_lib.sh

[[ $cs_INTERNAL_DEBUG == 1 ]] && set -xv

sed -i "/$(echo $cs_RC_HOOK_GREP | escape_sed)/d" ~/.bashrc

if [[ ! $cs_ROOTDIR =~ .commash ]]; then
	echo "cs_ROOTDIR=\"$cs_ROOTDIR\" and that's weird. exiting."
	exit 1
fi

# TODO: read only one character
read -r -p "Do you want to delete the $cs_ROOTDIR direcotry? All saved history will be lost. Forever. [y/n]" response

if [[ $response =~ [yY] ]]; then
	rm -fr $cs_ROOTDIR
	echo "The $cs_ROOTDIR has been deleted."
fi

[[ $cs_INTERNAL_DEBUG == 1 ]] && set +xv

