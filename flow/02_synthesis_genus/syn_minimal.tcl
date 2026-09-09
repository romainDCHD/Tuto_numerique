#################################
# Variable setup
################################
include $env(DESIGN_PATH)/config/conf_ihp130.lib
include $env(DESIGN_PATH)/dut/design.lib
# set DATE [clock format [clock seconds] -format "%b%d-%T"]
set run_dir "./"


################################
# Create output folder
################################
if {![file exists ${run_dir}]} {
        file mkdir ${run_dir}
        puts "Creating directory ${run_dir}"
}


if {![file exists ${run_dir}/outputs]} {
        file mkdir ${run_dir}/outputs
        puts "Creating directory ${run_dir}/output"
}

if {![file exists ${run_dir}/reports]} {
        file mkdir ${run_dir}/reports
        puts "Creating directory ${run_dir}/report"
}

################################
# Configure Genus
################################
set_db hdl_language sv
# Dire ou chercher les rtl (se rajoute devant les PATHS de la filelist
#set_db init_hdl_search_path $env(DESIGN_PATH)/

set_db library $GENUS_LIBERTY_TC
# UTILE ? set_db init_lib_search_path ../lib/
# UTILE ? read_libs slow_vdd1v0_basicCells.lib

read_hdl -f $GENUS_FILELIST
elaborate $TOP_MODULE
read_sdc $GENUS_SDC

set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium


################################
# Run Genus
################################

syn_generic
syn_map
syn_opt


################################
# Generate reports
################################
report_timing > $run_dir/reports/report_timing.rpt
report_power  > $run_dir/reports/report_power.rpt
report_area   > $run_dir/reports/report_area.rpt
report_qor    > $run_dir/reports/report_qor.rpt


################################
# Generate outputs
################################
write_hdl > $run_dir/outputs/${TOP_MODULE}_netlist.v
write_sdc > $run_dir/outputs/${TOP_MODULE}_sdc.sdc

# Possibilité de rajouter les sdf mais pas forcément pertinent
# write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge  -setuphold split > $run_dir/outputs/${TOP_MODULE}_delays.sdf
