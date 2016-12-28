#!/usr/bin/expect

set timeout 1

spawn bash
send "echo param1 param2 param3\n"
send "echo \"underscore\$_\"\n"

expect "underscoreparam3" {
	puts "PASS"
	exit 0
}

puts "FAIL"
exit 1
