if { $argc != 2 } {
    puts "Incorrect number of arguments. Expected BIT_FILE and PROBES_FILE."
    exit 0
}

set BIT_FILE [lindex $argv 0]
set PROBES_FILE [lindex $argv 1]

open_hw
connect_hw_server -url localhost:3121
current_hw_target [get_hw_targets *]
set_property PARAM.FREQUENCY 15000000 [get_hw_targets *]
open_hw_target

set script_path [ file dirname [ file normalize [ info script ] ] ]
puts $script_path

set_property PROGRAM.FILE "${BIT_FILE}" [get_hw_devices *]
set_property PROBES.FILE "${PROBES_FILE}" [get_hw_devices *]

program_hw_devices [lindex [get_hw_devices] 0]
#get_property REGISTER.IR.BIT5_DONE [lindex [get_hw_devices] 0]

refresh_hw_device -update_hw_probes false [lindex [get_hw_devices *] 0]
refresh_hw_mig [lindex [get_hw_migs]]
report_hw_mig [lindex [get_hw_migs]]

close_hw_target
disconnect_hw_server
close_hw
exit
