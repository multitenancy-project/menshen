source "${script_path}read.tcl"

current_design rmt_wrapper
# current_design test_cam
# current_design stage

check_design

link
#
# current_design fallthrough_small_fifo

create_clock -period 6.25 clk

compile_ultra

# report
set maxpaths 15

report_area > area.rpt
report_timing -max_path $maxpaths > timing.rpt

quit
