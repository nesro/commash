#!/usr/bin/expect
source "~/.commash/tests/src_init.tcl"

#-------------------------------------------------------------------------------

if { $basharg == "norc"} {
	puts "SKIP"
	return 0
}

#-------------------------------------------------------------------------------

send "var=content\n"
send "echo itis\$var\n"

expect {
	timeout {
			puts "CS_EXPECT_TIMEOUT test_underscore.tcl"
			exp_continue
	}
	",: ShellCheck:" {
		puts "\nPASS 1"
	}
}

send "r"

expect {
	timeout {
			puts "CS_EXPECT_TIMEOUT test_underscore.tcl"
			exp_continue
	}
	"itiscontent" {
		puts "\nPASS 2"
		exit 0
	}
}

#-------------------------------------------------------------------------------

source "~/.commash/tests/src_fail.tcl"
