#!/bin/bash

echo one

echo two

i=3

if (( i == 3 )); then
	echo yes
else
	echo no
fi
echo three

for i in 1 2 3
do
	echo $i
done

# comment
echo one | grep two
