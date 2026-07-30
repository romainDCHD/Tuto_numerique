# Etape 4 : route MET1-MET3, controles finaux, extraction et exports.

proc ::digi_pnr::configure_signal_routing {} {
    setDesignMode -bottomRoutingLayer MET1 -topRoutingLayer MET3
    setNanoRouteMode -routeBottomRoutingLayer 1
    setNanoRouteMode -routeTopRoutingLayer 3
    setNanoRouteMode -routeWithTimingDriven true
    setNanoRouteMode -routeWithSiDriven true

    set antenna [env_or ANTENNA_CELL ""]
    if {$antenna ne ""} {
        setNanoRouteMode -routeInsertAntennaDiode true
        setNanoRouteMode -routeAntennaCellName $antenna
    }

    set report [report_path route_layer_policy.rpt]
    set fh [open $report w]
    puts $fh "SIGNAL_BOTTOM_ROUTING_LAYER=MET1"
    puts $fh "SIGNAL_TOP_ROUTING_LAYER=MET3"
    puts $fh "METTP_SIGNAL_USE=FORBIDDEN_BY_ROUTER_LIMIT"
    puts $fh "ANTENNA_CELL=$antenna"
    close $fh
}

proc ::digi_pnr::insert_fillers {} {
    set fillers [split [require_env FILLER_CELLS]]
    setFillerMode -reset
    setFillerMode -corePrefix FILL
    addFiller -cell $fillers -prefix FILL
    applyGlobalNets
}

proc ::digi_pnr::route_and_optimize {} {
    global DESIGN_CFG
    configure_signal_routing
    routeDesign -placementCheck
    optDesign -postRoute
    if {$DESIGN_CFG(has_clock)} {
        optDesign -postRoute -hold
    }
    insert_fillers
    save_checkpoint 04_postroute
    set_status ROUTE_STATUS PASS [report_path route_layer_policy.rpt]
}

proc ::digi_pnr::verify_physical_database {} {
    set power [env_or POWER_NET VDD]
    set ground [env_or GROUND_NET VSS]
    set drc_report [report_path verify_drc_final.rpt]
    set regular_report [report_path verify_connectivity_regular_final.rpt]
    set special_report [report_path verify_connectivity_special_final.rpt]
    set antenna_report [report_path verify_antenna_final.rpt]

    capture $drc_report {verify_drc}
    capture $regular_report {verifyConnectivity -type regular}
    capture $special_report [list verifyConnectivity -type special -nets [list $power $ground]]
    capture $antenna_report {verifyProcessAntenna}

    require_zero_verification drc $drc_report DRC_STATUS
    require_zero_verification regular_connectivity $regular_report REGULAR_CONNECTIVITY_STATUS
    require_zero_verification special_connectivity $special_report SPECIAL_CONNECTIVITY_STATUS
    require_zero_verification antenna $antenna_report ANTENNA_STATUS
    set_status PG_GRID_STATUS PASS $special_report
}

proc ::digi_pnr::extract_and_time {} {
    global DESIGN_CFG
    extractRC
    set_status EXTRACTION_STATUS PASS [report_path extraction_policy.rpt]
    set extraction_report [report_path extraction_policy.rpt]
    set fh [open $extraction_report w]
    puts $fh "EXTRACTION_COMMAND=extractRC"
    puts $fh "ANALYSIS_VIEW_POLICY=[require_env VIEW]"
    close $fh

    set setup_report [report_path timing_postroute_setup.rpt]
    capture $setup_report {timeDesign -postRoute}
    require_no_negative_slack postroute_setup $setup_report SETUP_STATUS
    if {$DESIGN_CFG(has_clock)} {
        set hold_report [report_path timing_postroute_hold.rpt]
        capture $hold_report {timeDesign -postRoute -hold}
        require_no_negative_slack postroute_hold $hold_report HOLD_STATUS
    } else {
        set_status HOLD_STATUS NOT_APPLICABLE [report_path cts_not_applicable.rpt]
    }
}

proc ::digi_pnr::export_results {} {
    set design [require_env DESIGN]
    set def_path [output_path "${design}.routed.def"]
    set netlist_path [output_path "${design}.routed.v"]
    set pg_netlist_path [output_path "${design}.routed.pg.v"]
    set sdc_path [output_path "${design}.routed.sdc"]
    set spef_path [output_path "${design}.spef"]
    set lef_path [output_path "${design}.abstract.lef"]
    set gds_path [output_path "${design}.gds"]

    defOut $def_path
    saveNetlist $netlist_path
    saveNetlist -includePowerGround $pg_netlist_path
    file copy -force [require_env PNR_SDC] $sdc_path
    rcOut -spef $spef_path

    if {[catch {write_lef_abstract $lef_path} lef_error]} {
        if {[catch {lefOut $lef_path} fallback_error]} {
            error "PNR_EXPORT_LEF_ECHOUE: primary=$lef_error fallback=$fallback_error"
        }
    }

    set stream_command [list streamOut $gds_path -libName DesignLib -units 1000 -mode ALL \
        -mapFile [require_env STREAM_MAP] -merge [list [require_env STDCELL_GDS]]]
    uplevel #0 $stream_command

    require_outputs [list $def_path $netlist_path $pg_netlist_path $sdc_path \
        $spef_path $lef_path $gds_path]
    save_checkpoint 05_final_export
    set_status EXPORT_STATUS PASS $gds_path
    set_status DELIVERABLE_STATUS PASS $gds_path
    set_status GDS_STATUS IMPLEMENTATION_CANDIDATE $gds_path
    append_manifest OUTPUT_GDS $gds_path
    append_manifest OUTPUT_DEF $def_path
    append_manifest OUTPUT_NETLIST $netlist_path
    append_manifest OUTPUT_SPEF $spef_path
    append_manifest GDS_CLASSIFICATION IMPLEMENTATION_CANDIDATE
    append_manifest SIGNOFF_STATUS NOT_ACHIEVED
}

proc ::digi_pnr::run_route_verify_export {} {
    route_and_optimize
    verify_physical_database
    extract_and_time
    export_results
}
