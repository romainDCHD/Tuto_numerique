# Implémentation Innovus minimale du full adder.
# Ce niveau montre import, floorplan, placement, routage et export logique.

proc require_env {name} {
    if {![info exists ::env($name)] || [string trim $::env($name)] eq ""} {
        error "variable obligatoire absente: $name"
    }
    return $::env($name)
}

proc env_list {name} {
    set result [list]
    foreach item [split [require_env $name] ":"] {
        if {[string trim $item] ne ""} {
            lappend result [file normalize $item]
        }
    }
    return $result
}

set run_dir [file normalize [require_env PNR_RUN_DIR]]
set design [require_env DESIGN]
set reports [file join $run_dir reports]
set outputs [file join $run_dir outputs]
set generated [file join $run_dir generated]
set checkpoints [file join $run_dir checkpoints]
foreach dir [list $reports $outputs $generated $checkpoints] {
    file mkdir $dir
}

set mmmc_file [file join $generated basic_tc.mmmc.tcl]
set fh [open $mmmc_file w]
puts $fh [list create_constraint_mode -name FUNC -sdc_files [list [require_env PNR_SDC]]]
puts $fh [list create_library_set -name LIBSET_TC -timing [env_list LIB_TC]]
puts $fh [list create_rc_corner -name RC_TC -temperature [require_env TEMP_TC] \
    -qx_tech_file [require_env QRC_TECH_FILE_TC]]
puts $fh [list create_delay_corner -name CORNER_TC \
    -library_set LIBSET_TC -rc_corner RC_TC]
puts $fh [list create_analysis_view -name TC \
    -constraint_mode FUNC -delay_corner CORNER_TC]
puts $fh [list set_analysis_view -setup [list TC] -hold [list TC]]
close $fh

global init_top_cell init_verilog init_lef_file init_mmmc_file
global init_pwr_net init_gnd_net
set init_top_cell $design
set init_verilog [require_env PNR_NETLIST]
set init_lef_file [env_list ALL_LEFS]
set init_mmmc_file $mmmc_file
set init_pwr_net [require_env POWER_NET]
set init_gnd_net [require_env GROUND_NET]

init_design
globalNetConnect $init_pwr_net -type pgpin \
    -pin [require_env STDCELL_POWER_PIN] -inst * -verbose
globalNetConnect $init_gnd_net -type pgpin \
    -pin [require_env STDCELL_GROUND_PIN] -inst * -verbose
applyGlobalNets
redirect -file [file join $reports check_design_import.rpt] {checkDesign -all}

floorPlan -site [require_env STDCELL_SITE] -r \
    [require_env CORE_ASPECT_RATIO] [require_env CORE_UTILIZATION] \
    [require_env CORE_MARGIN_UM] [require_env CORE_MARGIN_UM] \
    [require_env CORE_MARGIN_UM] [require_env CORE_MARGIN_UM]
defOut -floorplan [file join $outputs ${design}.floorplan.def]

placeDesign
redirect -file [file join $reports check_place.rpt] {checkPlace}

setDesignMode -bottomRoutingLayer MET1 -topRoutingLayer MET3
routeDesign -placementCheck
saveDesign [file join $checkpoints basic_routed.enc]

set def_path [file join $outputs ${design}.routed.def]
set netlist_path [file join $outputs ${design}.routed.v]
defOut $def_path
saveNetlist $netlist_path

foreach path [list $def_path $netlist_path] {
    if {![file exists $path] || [file size $path] == 0} {
        error "sortie absente ou vide: $path"
    }
}

set status [open [file join $reports final_status.rpt] w]
puts $status "PREFLIGHT_STATUS=PASS"
puts $status "IMPORT_STATUS=PASS"
puts $status "FLOORPLAN_STATUS=PASS"
puts $status "PLACEMENT_STATUS=PASS"
puts $status "ROUTE_STATUS=PASS"
puts $status "EXPORT_STATUS=PASS"
puts $status "SIGNOFF_STATUS=NOT_ACHIEVED"
close $status

puts "DIGI_PNR_STATUS=BASIC_FLOW_COMPLETED"
exit 0
