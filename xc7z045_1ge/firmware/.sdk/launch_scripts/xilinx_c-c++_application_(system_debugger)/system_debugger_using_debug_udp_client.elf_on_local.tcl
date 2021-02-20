connect -url tcp:127.0.0.1:3121
source /media/shimko/2E0A00DD0A00A445/workspace_vivado_2018_3/xc7z045_1ge/firmware/xc7z045_1ge_bd_wrapper_hw_platform_0/ps7_init.tcl
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent JTAG-SMT2 210251A1E9EA"} -index 0
loadhw -hw /media/shimko/2E0A00DD0A00A445/workspace_vivado_2018_3/xc7z045_1ge/firmware/xc7z045_1ge_bd_wrapper_hw_platform_0/system.hdf -mem-ranges [list {0x40000000 0xbfffffff}]
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent JTAG-SMT2 210251A1E9EA"} -index 0
stop
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent JTAG-SMT2 210251A1E9EA"} -index 0
rst -processor
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent JTAG-SMT2 210251A1E9EA"} -index 0
dow /media/shimko/2E0A00DD0A00A445/workspace_vivado_2018_3/xc7z045_1ge/firmware/udp_client/Debug/udp_client.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent JTAG-SMT2 210251A1E9EA"} -index 0
con
