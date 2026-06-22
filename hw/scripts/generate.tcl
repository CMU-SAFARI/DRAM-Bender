# Returns all directory names in a given directory (non-recursive)
proc get_dir_names {path} {
	set dirs [glob -directory "$path" -type d *]
	set dir_names {}
	foreach project $dirs {
		lappend dir_names [string map "$path/ \"\"" $project]
	}
	return $dir_names
}

# Version safe wait procedure for a single run. wait_on_run changed to wait_on_runs after Vivado 2021.2
proc safe_wait { run } {
	if { [catch wait_on_runs $run] } {
		wait_on_run $run
	}
}

# Version safe wait procedure for multiple runs. wait_on_run changed to wait_on_runs after Vivado 2021.2
proc safe_wait_multiple { run_list } {
	if { [catch wait_on_runs $run_list] } {
		foreach run $run_list { wait_on_run $run }
	}
}

# Check required args
if { $argc != 1 } {
	puts "Please provide <number_of_threads> to script."
	puts "For example, vivado -mode batch generate.tcl -tclargs 12"
	exit 0
}

# Set path variables
set PROJECT_PATH [pwd]
set PROJECT_NAME [string map ".xpr \"\" $PROJECT_PATH/ \"\"" [glob -directory $PROJECT_PATH *.xpr]]
set PROJECT_IP_PATH "$PROJECT_PATH/$PROJECT_NAME.srcs/sources_1/ip"
set NUM_JOBS [lindex $argv 0]

# Check if project exists
if { ![file exist $PROJECT_PATH] } {
	puts "Project not found on $PROJECT_PATH."
	exit 0
}

# Open the project
open_project "$PROJECT_PATH/$PROJECT_NAME.xpr"

update_compile_order -fileset sources_1

# Reset previous runs
reset_project

# IP run variables
set ip_list [get_ips]
set ip_runs {}
set phy_list {}
foreach ip $ip_list {
	if {[string first "phy_" $ip] != -1} {
		lappend phy_list "$ip"
	}
	lappend ip_runs "${ip}_synth_1"
}


# Reset ourput products of all IPs
reset_target all $ip_list

# Set fileset to main sources
update_compile_order -fileset sources_1

# Re-generate all output products
generate_target all $ip_list

foreach ip $ip_list {
	create_ip_run [get_ips $ip]
}

launch_runs $ip_runs -verbose -jobs $NUM_JOBS
safe_wait_multiple $ip_runs

# Lock PHY and Apply patches
foreach phy_ip $phy_list {
	set_property IS_LOCKED true [get_files "${phy_ip}.xci"]
}

if { [catch {exec "${PROJECT_PATH}/apply_patches.sh"} result] != 0 } {
    puts "Script 'apply_patches.sh' has no return value, assumed exit value 0 (TCL_OK). Check first incase any errors."
}

# Reset and relaunch PHY runs
foreach phy_ip $phy_list {
	reset_run [get_runs "${phy_ip}_synth_1"]
}

foreach phy_ip $phy_list {
	launch_run [get_runs "${phy_ip}_synth_1"]
}

foreach phy_ip $phy_list {
	safe_wait "${phy_ip}_synth_1"
}

# Synthesis
launch_runs synth_1 -verbose -jobs $NUM_JOBS
safe_wait "synth_1"

# Implementation and Bitstream generation
launch_runs impl_1 -to_step write_bitstream -verbose -jobs $NUM_JOBS
safe_wait "impl_1"

# Done
puts "Bitstream generated successfully. Exitting."
