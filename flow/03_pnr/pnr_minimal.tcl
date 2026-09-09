
################################
# PnR minimal script
################################

#################################
# Variables setup globales
################################
source $env(DESIGN_PATH)/config/conf_ihp130.lib
source $env(DESIGN_PATH)/dut/design.lib


################################
# Variables locales
################################
set design    $TOP_MODULE
set netlist $env(DESIGN_PATH)/flow/02_synthesis_genus/01_syn_minimal/workdir/outputs/${TOP_MODULE}_netlist.v
set mmmc_file $PNR_MMMC
set PNR_SDC $env(DESIGN_PATH)/flow/02_synthesis_genus/01_syn_minimal/workdir/outputs/${TOP_MODULE}_sdc.sdc

set site $STDCELL_SITE
set bottom_routing_layer $SIGNAL_BOTTOM_LAYER
set top_routing_layer $SIGNAL_TOP_LAYER
set aspect_ratio $PNR_ASPECT_RATIO
set core_utilization $PNR_CORE_UTILIZATION
set core_margin $PNR_CORE_MARGIN

# Custom name for oa export
set oaLibDir RIPPLE_CARRY_4_OA
set oaLibName ripple_carry


################################
# Create output folder
################################
# set DATE [clock format [clock seconds] -format "%b%d-%T"]
set run_dir "./"

if {![file exists ${run_dir}]} {
        file mkdir ${run_dir}
        puts "Creating directory ${run_dir}"
}


if {![file exists ${run_dir}/outputs]} {
        file mkdir ${run_dir}/outputs
        puts "Creating directory ${run_dir}/outputs"
}


if {![file exists ${run_dir}/reports]} {
        file mkdir ${run_dir}/reports
        puts "Creating directory ${run_dir}/reports"
}


if {![file exists ${run_dir}/checkpoints]} {
        file mkdir ${run_dir}/checkpoints
        puts "Creating directory ${run_dir}/checkpoints"
}


set output_dir \
    [file join $run_dir outputs]

set report_dir \
    [file join $run_dir reports]

set checkpoint_dir \
    [file join $run_dir checkpoints]


################################
# Read MMMC
################################
read_mmmc $mmmc_file


################################
# Read physical
################################
read_physical -oa_ref_libs { \
    ixc013_stdcell \
    ixc013ng_stdcell \
}


# # Si on veut rester en LEF :
# # Pointer vers les bons fichiers LEF du pdk
# set lef_files [list $INNOVUS_TECH_LEF $INNOVUS_STDCELL_LEF]

# # Lire les fichiers du pdk
# read_physical \
#     -lef $lef_files

# # Puis pour enregistrer
# write_db \
#     [file join $checkpoint_dir imported]


################################
# Read Netlist
################################
read_netlist \
    $netlist \
    -top $design


################################
# Power nets definition
################################


################################
# Init_design
################################
set_db init_power_nets [list $PNR_POWER_NET]
set_db init_ground_nets [list $PNR_GROUND_NET]
set_db delaycal_input_transition_delay {0.1ps}
set_db init_oa_layout_views {layout}
set_db init_oa_abstract_views {abstract}


init_design
 
################################
# Global power connections
################################

connect_global_net $PNR_POWER_NET \
    -type pg_pin \
    -pin_base_name $PNR_POWER_NET \
    -inst_base_name *

connect_global_net $PNR_GROUND_NET \
    -type pg_pin \
    -pin_base_name $PNR_GROUND_NET \
    -inst_base_name *

# Report imported files
write_db -oa_lib_cell_view "$oaLibDir $oaLibName imported"


################################
# Create floorplan
################################
set_db design_bottom_routing_layer \
    $bottom_routing_layer

set_db design_top_routing_layer \
    $top_routing_layer

create_floorplan \
    -site $site \
    -core_density_size \
        $aspect_ratio \
        $core_utilization \
        $core_margin \
        $core_margin \
        $core_margin \
        $core_margin


# **************************** #
# Place IO pins                #
# **************************** #
# automaticaly
assign_io_pins


# **************************** #
# Power routing and connection #
# **************************** #
# ------------------------------
# 1. Core power ring
# ------------------------------
add_rings \
    -type core_rings \
    -follow core \
    -nets [list $PNR_POWER_NET $PNR_GROUND_NET] \
    -layer [list \
        bottom $POWER_RING_H_LAYER \
        top    $POWER_RING_H_LAYER \
        right  $POWER_RING_V_LAYER \
        left   $POWER_RING_V_LAYER] \
    -width   $POWER_RING_WIDTH \
    -spacing $POWER_RING_SPACING \
    -offset  $POWER_RING_OFFSET


# ------------------------------
# 2. Stripes
# ------------------------------
add_stripes \
    -nets [list $PNR_POWER_NET $PNR_GROUND_NET] \
    -layer $POWER_STRIPE_LAYER \
    -direction vertical \
    -width $POWER_STRIPE_WIDTH \
    -spacing $POWER_STRIPE_SPACING \
    -number_of_sets 1 \
    -start_from left \
    -start_offset $POWER_STRIPE_OFFSET


# ------------------------------
# 3. Connexion des rails des cellules au réseau VDD/VSS
# ------------------------------
route_special \
    -nets [list $PNR_POWER_NET $PNR_GROUND_NET] \
    -connect {core_pin} \
    -core_pin_target {first_after_row_end} \
    -allow_layer_change 1 \
    -allow_jogging 1

# ------------------------------
# 4. Save database
# ------------------------------

# write_def \
#     [file join $output_dir floorplan.def]

write_db -oa_lib_cell_view "$oaLibDir $oaLibName floorplan"

# ------------------------------
check_legacy_design -all


################################
# Placement
################################
place_design

write_db -oa_lib_cell_view "$oaLibDir $oaLibName placed"


################################
# Clock tree Synthesis
################################
create_clock_tree_spec
ccopt_design

# ------------------------------
# Generate reports and db
# ------------------------------
time_design \
    -post_cts \
    -report_dir [file join $report_dir post_cts]
 
time_design \
    -post_cts \
    -hold \
    -report_dir [file join $report_dir post_cts_hold]

#write_db \
 #   [file join $checkpoint_dir after_CTS]


################################
# Route design
################################
route_design -global_detail

check_connectivity

write_db -oa_lib_cell_view "$oaLibDir $oaLibName routed"


# ------------------------------
# Check DRC
# ------------------------------
delete_drc_markers
check_drc -out_file $checkpoint_dir/drc_post_route_opti.rpt

# ------------------------------
# Extract parasitics
# ------------------------------
set_db extract_rc_engine post_route
reset_parasitics
extract_rc
# Fait l'extraction de parasites interne

#wrtite sdf pour extract paasitics pour xrun --> format .sdf
# xrun va pouvoir simuler en prenant ce sdf en + pour les parasites

write_sdf  \
        -edges check_edge         \
        -min_view      VIEW_BC    \
        -max_view      VIEW_WC    \
        -typical_view  VIEW_TC    \
        ${output_dir}/${design}_routed.sdf

# ------------------------------
# Timing report
# ------------------------------
set_db timing_analysis_type ocv

time_design \
    -post_route \
    -report_dir [file join $report_dir post_route]

time_design \
    -post_route \
    -hold \
    -report_dir [file join $report_dir post_route_hold]


# ------------------------------
# Power report
# ------------------------------
# TODO


# ------------------------------
# Area report
# ------------------------------
# TODO


################################
# Export final files
################################
write_def \
    [file join $output_dir routed.def]

write_netlist \
    [file join $output_dir ${design}.routed.v]

gui_show
gui_fit
