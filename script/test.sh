#!/bin/bash

# for with do on another line
for i in 1 2
do
	echo "another $i"
	uname
done

echo "lone echo..."

i=3

if (( i == 3 )); then
	echo yes
else
	echo no
fi

echo "grep me" | grep "grep"

# for with do on the first line
for i in 3 4; do
	echo "first: $i"
	echo "again: $i"
done
