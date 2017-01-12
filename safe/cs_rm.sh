#!/usr/bin/env bash
# https://github.com/nesro/commash

# command rm

# man page: man rm
# source code: http://lingrok.org/xref/coreutils/src/rm.c

csfunc_rm()  {
	echo ",running: rm $@"
	rm "$@"
}
