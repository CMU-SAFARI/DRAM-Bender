if {$argv == "debug"} {
	set dir [string trim $argv0 "source.tcl"]

	set path [format "%sVU095.sim/sim_1/behav/xsim" $dir]
	cd $path

	set path [format "%sdebug.tcl" $dir]
	xsim sim_tb_top_behav -key {Behavioral:sim_1:Functional:tb} -tclbatch "$path"
} elseif {$argv == "update"} {
	launch_simulation
} elseif {$argv == "first"} {
	launch_simulation

	set dir [string trim $argv0 "source.tcl"]

	set path [format "%sVU095.sim/sim_1/behav/xsim" $dir]
	cd $path

	set path [format "%sdebug.tcl" $dir]
	xsim sim_tb_top_behav -key {Behavioral:sim_1:Functional:tb} -tclbatch "$path"
}
exit

