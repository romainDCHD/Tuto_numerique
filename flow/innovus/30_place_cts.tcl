# Etape 3 : placement, raccordement des rails et CTS du design sequentiel.

proc ::digi_pnr::insert_ties_if_configured {} {
    set tie_hi [env_or TIEHI_CELL ""]
    set tie_lo [env_or TIELO_CELL ""]
    if {$tie_hi eq "" && $tie_lo eq ""} { return }
    if {$tie_hi eq "" || $tie_lo eq ""} {
        error "PNR_TIE_POLICY_INCOMPLETE: TIEHI_CELL et TIELO_CELL doivent etre fournis ensemble"
    }
    setTieHiLoMode -reset
    setTieHiLoMode -maxFanout 8 -maxDistance 100 -cell [list $tie_hi $tie_lo]
    addTieHiLo
    applyGlobalNets
}

proc ::digi_pnr::connect_stdcell_rails {} {
    set nets [list [env_or POWER_NET VDD] [env_or GROUND_NET VSS]]
    set command [list sroute -connect [list corePin] -nets $nets \
        -corePinTarget [list ring] -allowJogging 1 -allowLayerChange 1]
    uplevel #0 $command

    set report [report_path verify_connectivity_special_postplace.rpt]
    capture $report [list verifyConnectivity -type special -nets $nets]
    require_zero_verification special_postplace $report SPECIAL_CONNECTIVITY_STATUS
    set_status PG_GRID_STATUS PASS $report
}

proc ::digi_pnr::place_design_and_optimize {} {
    setPlaceMode -place_global_place_io_pins false
    insert_ties_if_configured
    placeDesign
    optDesign -preCTS
    set check_report [report_path check_place_prects.rpt]
    capture $check_report {checkPlace}
    require_clean_checkplace $check_report
    capture [report_path timing_prects_setup.rpt] {timeDesign -preCTS}
    connect_stdcell_rails
    save_checkpoint 02_place_prects
    set_status PLACEMENT_STATUS PASS $check_report
}

proc ::digi_pnr::run_cts_if_applicable {} {
    global DESIGN_CFG
    if {!$DESIGN_CFG(has_clock)} {
        set report [report_path cts_not_applicable.rpt]
        set fh [open $report w]
        puts $fh "CTS_STATUS=NOT_APPLICABLE"
        puts $fh "REASON=design_is_purely_combinational_and_uses_a_virtual_timing_clock"
        puts $fh "CCOPT_EXECUTED=0"
        close $fh
        set_status CTS_STATUS NOT_APPLICABLE $report
        set_status HOLD_STATUS NOT_APPLICABLE $report
        return
    }

    set buffers [split [require_env CTS_BUFFER_CELLS]]
    set inverters [split [require_env CTS_INVERTER_CELLS]]
    set_ccopt_property buffer_cells $buffers
    set_ccopt_property inverter_cells $inverters
    set_ccopt_property target_skew [env_or CTS_TARGET_SKEW_NS 0.20]
    set_ccopt_property target_max_trans [env_or CTS_MAX_TRANSITION_NS 0.35]

    set spec [generated_path cts.spec]
    create_ccopt_clock_tree_spec -file $spec
    source $spec
    ccopt_design
    optDesign -postCTS

    set setup_report [report_path timing_postcts_setup.rpt]
    set hold_report [report_path timing_postcts_hold.rpt]
    set tree_report [report_path clock_tree_summary.rpt]
    capture $setup_report {timeDesign -postCTS}
    capture $hold_report {timeDesign -postCTS -hold}
    capture $tree_report {report_ccopt_clock_trees -summary}
    require_no_negative_slack postcts_setup $setup_report SETUP_STATUS
    require_no_negative_slack postcts_hold $hold_report HOLD_STATUS

    set tree_text [read_text $tree_report]
    if {![regexp $DESIGN_CFG(clock_port) $tree_text] ||
        ![regexp -nocase {skew} $tree_text] ||
        ![regexp -nocase {sinks?} $tree_text] ||
        [regexp -nocase {(^|[[:space:]])(ERROR|FAIL)([[:space:]:]|$)} $tree_text]} {
        set_status CTS_STATUS FAIL $tree_report
        error "PNR_CTS_NON_PROUVE: clock=$DESIGN_CFG(clock_port) report=$tree_report"
    }
    save_checkpoint 03_postcts
    set_status CTS_STATUS PASS $tree_report
}
