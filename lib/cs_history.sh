#!/usr/bin/env bash

# Commash history library

CSLOG=/tmp/cslog

cs_ts() {
	while IFS='' read -r line; do
    		echo "$(date +%Y-%m-%d-%H-%M-%S-%N)|$1|$line" >> $CSLOG
    		echo "$line"
	done
}


