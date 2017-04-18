#!/usr/bin/expect
source "~/.commash/tests/src_init.tcl"

#-------------------------------------------------------------------------------

send "echo param1 param2 param3\n"
send "echo \"underscore\$_\"\n"

expect {
	timeout {
			puts "CS_EXPECT_TIMEOUT test_underscore.tcl"
			exp_continue
	}
	"underscoreparam3" {
		puts "PASS"
		exit 0
	}
}

#-------------------------------------------------------------------------------

source "~/.commash/tests/src_fail.tcl"
