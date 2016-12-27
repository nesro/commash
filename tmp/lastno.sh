#!/usr/bin/env bash

PS4='^MDEBUG: $((LASTNO=$LINENO)) : '; set -x
archieve_it () {
    trap 'clean_a $LASTNO $LINENO "$BASH_COMMAND"' \
        SIGHUP SIGINT SIGTERM SIGQUIT
    while :; do sleep 1; done
} 2>/dev/null
clean_a () { : "$@" ; } 2>&1
