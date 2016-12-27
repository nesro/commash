#!/usr/bin/env bash

foo() {
	local foovar="test"
}

foo
echo "$foovar"
