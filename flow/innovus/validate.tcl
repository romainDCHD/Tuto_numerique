# Validation de la technologie effectivement chargee par Innovus.

proc ::digi_pnr::validate_loaded_technology {} {
    global DESIGN_CFG
    set report [report_path technology_validation.rpt]
    set fh [open $report w]
    puts $fh "VALIDATION=TECHNOLOGY_AND_CELL_POLICY"

    set missing_layers [list]
    foreach layer {MET1 MET2 MET3 METTP} {
        set found [dbGet head.layers.name $layer]
        set present [expr {$found ne "" && $found ne "0x0"}]
        puts $fh "LAYER_${layer}=[expr {$present ? {PRESENT} : {MISSING}}]"
        if {!$present} { lappend missing_layers $layer }
    }

    set site [require_env STDCELL_SITE]
    set site_found [dbGet head.sites.name $site]
    set site_present [expr {$site_found ne "" && $site_found ne "0x0"}]
    puts $fh "STDCELL_SITE=$site"
    puts $fh "STDCELL_SITE_STATUS=[expr {$site_present ? {PRESENT} : {MISSING}}]"
    close $fh

    if {[llength $missing_layers] > 0 || !$site_present} {
        error "PNR_TECHNOLOGIE_INCOMPLETE: layers=$missing_layers site=$site report=$report"
    }

    set fillers [split [require_env FILLER_CELLS]]
    set ::env(FILLER_CELLS) [filter_available_cells FILLER $fillers 1]

    if {$DESIGN_CFG(has_clock)} {
        set ::env(CTS_BUFFER_CELLS) [filter_available_cells CTS_BUFFER \
            [split [require_env CTS_BUFFER_CELLS]] 1]
        set ::env(CTS_INVERTER_CELLS) [filter_available_cells CTS_INVERTER \
            [split [require_env CTS_INVERTER_CELLS]] 1]
    }

    set tie_hi_candidates [split [env_or TIEHI_CELLS ""]]
    set tie_lo_candidates [split [env_or TIELO_CELLS ""]]
    if {([llength $tie_hi_candidates] == 0) != ([llength $tie_lo_candidates] == 0)} {
        error "PNR_TIE_POLICY_INCOMPLETE: listes high et low requises ensemble"
    }
    if {[llength $tie_hi_candidates] > 0} {
        set ::env(TIEHI_CELL) [select_available_cell TIE_HIGH $tie_hi_candidates 1]
        set ::env(TIELO_CELL) [select_available_cell TIE_LOW $tie_lo_candidates 1]
    }

    set antenna_candidates [split [env_or ANTENNA_CELLS ""]]
    if {[llength $antenna_candidates] > 0} {
        set ::env(ANTENNA_CELL) [select_available_cell ANTENNA $antenna_candidates 1]
    }
    set_status PREFLIGHT_STATUS PASS $report
}
