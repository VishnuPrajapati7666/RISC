set project_name risc_soc_m7
set project_dir [file normalize "./vivado_m7"]
create_project $project_name $project_dir -part xc7a12ticsg325-1L -force
add_files [glob -nocomplain [file normalize "./rtl/common/*.sv"]]
add_files [glob -nocomplain [file normalize "./rtl/core/*.sv"]]
add_files [file normalize "./rtl/memory/reference_memory.sv"]
set_property top risc_soc_top [current_fileset]
update_compile_order -fileset sources_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
report_utilization -file [file normalize "./vivado_m7/milestone7_utilization.rpt"]
report_timing_summary -file [file normalize "./vivado_m7/milestone7_timing.rpt"]
