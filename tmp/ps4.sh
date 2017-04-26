#!/bin/bash

u() {
	echo bar
}

t() {
	echo foo
	u
}


PS4='[${FUNCNAME[0]}:${LINENO}	] '
set -x

t
