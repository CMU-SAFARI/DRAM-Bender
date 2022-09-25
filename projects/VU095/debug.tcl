
set f2 [open /tmp/fifo_2 w]
set fin 0
set prenum 0
set actnum -2
set wrtnum 0
set rdnum 0
set refnum 0
add_condition -name pre -radix dec "/sim_tb_top/cmdName == 5263941 " { incr prenum; }
add_condition -name act -radix dec "/sim_tb_top/cmdName == 4277076 " { incr actnum; }
add_condition -name wrt -radix dec "/sim_tb_top/cmdName == 22354 " { incr wrtnum; }
add_condition -name rd -radix dec "/sim_tb_top/cmdName == 21060 " { incr rdnum; }
add_condition -name ref -radix dec "/sim_tb_top/cmdName == 5391686 " { incr refnum; }


while { 1 } {
  set f1 [open /tmp/fifo_1 r]
  gets $f1 inc

  set opt [split $inc "_"]
  set com [lindex $opt 0]
  set param [lindex $opt 1]
  set param2 [lindex $opt 2]

  if {$com == "reg"} {
    puts $f2 [get_value -radix dec "/sim_tb_top/u_example_top/pipeline/rf/reg_file[$param]"]
    flush $f2
  } elseif {$com == "mem"} {
    puts $f2 [get_value -radix dec "/sim_tb_top/u_example_top/pipeline/es/data_mem/mem[$param]"]
    flush $f2
  } elseif {$com == "time"} {
    puts $f2 [current_time]
    flush $f2
  } elseif {$com == "step"} {
    set cur_pc [get_value -radix dec "/sim_tb_top/u_example_top/pipeline/es/ep/s2_pc"]
    set con 0
    add_condition -name step -radix dec "/sim_tb_top/u_example_top/pipeline/es/ep/s2_pc != [expr $cur_pc] " { stop; set con 1; }
    run -all
    while { 1 } {
      if { $con == 1 } {
        run 0ns
        puts $f2 "done"
        flush $f2
        remove_conditions step
        break
      }
      after 100
    }
  } elseif {$com == "run"} {
    run $param
    puts $f2 "done"
    flush $f2
  } elseif {$com == "until"} {
    set con 0
    add_condition -name cond -radix dec "/sim_tb_top/u_example_top/pipeline/es/ep/s2_pc == [expr $param] " { stop; set con 1; }
    run -all
    while { 1 } {
      if { $con == 1 } {
        run 0ns
        puts $f2 "done"
        flush $f2
        remove_conditions cond
        break
      }
      after 100
    }
  } elseif {$com == "btwn"} {
    set con 0
    add_condition -name cond1 -radix dec "/sim_tb_top/u_example_top/pipeline/es/ep/s2_pc == [expr $param] " { remove_conditions cond1;set start [current_time]; }
    add_condition -name cond2 -radix dec "/sim_tb_top/u_example_top/pipeline/es/ep/s2_pc == [expr $param2] " { stop; set con 1; }
    run -all
    while { 1 } {
      if { $con == 1 } {
        run 0ns
        set end [current_time]
        set start [expr [string trim $start " ns"]]
        set end [expr [string trim $end " ns"]]
        puts $f2 [expr ($end - $start)/6]
        flush $f2
        remove_conditions cond2
        break
      }
      after 100
    }
  } elseif {$com == "stat"} {
    puts $f2 "PRE:$prenum, ACT:$actnum, WRT:$wrtnum, RD:$rdnum, REF:$refnum"
    flush $f2
  } elseif {$com == "exit"} {
    puts $f2 "done"
    flush $f2
    close $f1
    close $f2
    close_sim
    after 1000
    exit  
  } 
  close $f1
  after 1000
}
