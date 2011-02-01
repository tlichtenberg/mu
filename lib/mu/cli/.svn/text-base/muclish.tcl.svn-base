#!/usr/bin/expect --
set prompt "MU>"		;# default prompt
set host [lindex $argv 0]
set password [lindex $argv 1]
set prompt [lindex $argv 2]

# aux port? use mrtwig
if {$host == "192.168.2.1"} {
  eval spawn ssh root@10.10.3.60
  expect "password:"  
  send "happy1\r" 
  expect "#"
  send "ssh admin@192.168.2.1\r"
} else {
  eval spawn ssh admin@$host
}
expect "password:" 
send "$password\r" 
expect $prompt
interact
