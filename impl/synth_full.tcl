set_part xc7s50csga324-1

#read_ip ip/dram_mig/dram_mig.xci
set mig_rtl ip/dram_mig/dram_mig/user_design/rtl
set mig_xdc ip/dram_mig/dram_mig/user_design/constraints
read_verilog top_fpga.v \
    [glob ../rtl/src/*.v] \
    [glob ../rtl/src/*.vh] \
    [glob ../rtl/build/*.v] \
    [glob ../rtl/lib/*.v] \
    [glob $mig_rtl/clocking/*.v] \
    [glob $mig_rtl/controller/*.v] \
    [glob $mig_rtl/ecc/*.v] \
    [glob $mig_rtl/ip_top/*.v] \
    [glob $mig_rtl/phy/*.v]
read_xdc constraints.xdc
read_xdc $mig_xdc/dram_mig.xdc
#read_mem rom.mif

synth_design -top top_fpga -verilog_define XILINX
source preopt.tcl
opt_design
place_design
phys_opt_design
route_design

report_timing -sort_by group -max_paths 10 -path_type full -unique_pins -file ../rtl/build/timing_postroute.txt
report_utilization -hierarchical -file ../rtl/build/utilization_postroute.txt

write_bitstream -force top.bit
