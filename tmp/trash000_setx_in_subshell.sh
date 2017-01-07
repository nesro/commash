#!/usr/bin/env bash

# so I think that:
# we can try to set -x and set +x in a special command, that could be
# handled in a functrace DEBUG trap. but this would be too complicated and
# totally not worth it

# http://stackoverflow.com/questions/13195655/bash-set-x-without-it-being-printed
# http://superuser.com/questions/806599/suppress-execution-trace-for-echo-command


r() {
	return $1
}

asdfxoff() {
	{ rc=$1 ; }
	{ set +x; } 2>/dev/null
	r $rc
}

main()  {
	set -x

	echo "foo"

	false

	asdfxoff $?
}

main
echo "ret: $?"

