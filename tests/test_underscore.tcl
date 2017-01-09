#!/usr/bin/expect
source "~/.commash/tests/src_init.tcl"

#-------------------------------------------------------------------------------

send "echo param1 param2 param3\n"
send "echo \"underscore\$_\"\n"

expect "underscoreparam3" {
	puts "PASS"
	exit 0
}

#-------------------------------------------------------------------------------

source "~/.commash/tests/src_fail.tcl"
