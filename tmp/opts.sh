#!/usr/bin/env bash

set -xv

save_opts2() {

	echo "opts2: $@"

}

save_opts() {

	local o=("$@")



	save_opts2 "${o[@]}"

}

save_opts "$@"

