create_project risc_soc_m7_sim [file normalize "./vivado_m7_sim"] -part xc7a12ticsg325-1L -force
add_files [glob -nocomplain [file normalize "./rtl/common/*.sv"]]
add_files [glob -nocomplain [file normalize "./rtl/core/*.sv"]]
add_files [file normalize "./rtl/memory/reference_memory.sv"]
add_files -fileset sim_1 [file normalize "./tb/soc_tb.sv"]
set_property top soc_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation -mode behavioral
