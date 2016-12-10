#!/usr/bin/env bash

cs_dbg="set -xv"
cs_dbg_end="echo -n \"cs_dbg_end\"; set +xv"

cs_dbg() {
	echo "func: $1"
	set -xv
}

cs_dbg_end() {
	set +xv
}

cs_ndbg="set +xv"

foo() {
	eval "cs_dbg $FUNCNAME"


	i=5
	echo "in foo, i=$i"




	eval "cs_dbg_end"
}


bar() {

	echo "in bar"
}

foo


bar




