#!/bin/bash

n=${1:-0}

if (( $n > 3.5 )); then
	echo a
fi

if [[ $1 == $n ]]; then
	echo b
fi


