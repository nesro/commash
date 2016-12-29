#!/usr/bin/expect

set timeout 1
set basharg [lindex $argv 0]

if { $basharg == "norc"} {
	puts "BASH ARG IS: $basharg"
	spawn bash --norc
} elseif { $basharg == "default" } {
	puts "no bash arg!"
	spawn bash
	send "echo \"\$cs_ENABLED\$cs_VERSION_LONG\"\n"
	expect {
		"1Commash" {
			puts "\nCommash is running!"
		}
		default {
			puts "\nCommash is not running. Tests will don't test at all."
			exit 1
		}
	}
} else {
	puts "Use norc or default as argument to this script."
	exit 1
}

#-------------------------------------------------------------------------------

send "echo param1 param2 param3\n"
send "echo \"underscore\$_\"\n"

expect "underscoreparam3" {
	puts "PASS"
	exit 0
}

#-------------------------------------------------------------------------------

puts "FAIL"
exit 1

