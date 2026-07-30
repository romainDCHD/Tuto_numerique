# Etape 1 : construction MMMC, import du handoff Genus et controles initiaux.

proc ::digi_pnr::write_mmmc {} {
    set view [require_env VIEW]
    set sdc [require_file sdc [require_env PNR_SDC]]
    set path [generated_path "${view}.mmmc.tcl"]
    set fh [open $path w]
    puts $fh "# Fichier genere; ne pas editer dans work/."
    puts $fh [list create_constraint_mode -name FUNC -sdc_files [list $sdc]]

    set tc_libs [env_list LIB_TC]
    set tc_qrc [require_file qrc_tc [require_env QRC_TECH_FILE_TC]]
    puts $fh [list create_library_set -name LIBSET_TC -timing $tc_libs]
    puts $fh [list create_rc_corner -name RC_TC -temperature [env_or TEMP_TC 25] -qx_tech_file $tc_qrc]
    puts $fh [list create_delay_corner -name CORNER_TC -library_set LIBSET_TC -rc_corner RC_TC]
    puts $fh [list create_analysis_view -name TC -constraint_mode FUNC -delay_corner CORNER_TC]

    if {$view eq "mmmc"} {
        set bc_libs [env_list LIB_BC]
        set wc_libs [env_list LIB_WC]
        set bc_qrc [require_file qrc_bc [require_env QRC_TECH_FILE_BC]]
        set wc_qrc [require_file qrc_wc [require_env QRC_TECH_FILE_WC]]
        puts $fh [list create_library_set -name LIBSET_BC -timing $bc_libs]
        puts $fh [list create_library_set -name LIBSET_WC -timing $wc_libs]
        puts $fh [list create_rc_corner -name RC_BC -temperature [env_or TEMP_BC -40] -qx_tech_file $bc_qrc]
        puts $fh [list create_rc_corner -name RC_WC -temperature [env_or TEMP_WC 125] -qx_tech_file $wc_qrc]
        puts $fh [list create_delay_corner -name CORNER_BC -library_set LIBSET_BC -rc_corner RC_BC]
        puts $fh [list create_delay_corner -name CORNER_WC -library_set LIBSET_WC -rc_corner RC_WC]
        puts $fh [list create_analysis_view -name BC_HOLD -constraint_mode FUNC -delay_corner CORNER_BC]
        puts $fh [list create_analysis_view -name WC_SETUP -constraint_mode FUNC -delay_corner CORNER_WC]
        # TC reste actif comme point de comparaison pédagogique.
        puts $fh [list set_analysis_view -setup [list WC_SETUP TC] -hold [list BC_HOLD TC]]
    } elseif {$view eq "tc"} {
        puts $fh [list set_analysis_view -setup [list TC] -hold [list TC]]
    } else {
        close $fh
        error "PNR_VIEW_INCONNUE: $view (attendu: tc ou mmmc)"
    }
    close $fh
    return $path
}

proc ::digi_pnr::require_clean_import_report {path} {
    set text [read_text $path]
    set bad [list]
    foreach line [split $text "\n"] {
        if {[regexp -nocase {unresolved[[:space:]]+(reference|module)|black[[:space:]_-]*box|^[[:space:]]*\*?(ERROR|FATAL)} $line] &&
            ![regexp -nocase {(^|[^0-9])0[[:space:]]+(unresolved|black)} $line]} {
            lappend bad [string trim $line]
            if {[llength $bad] == 5} { break }
        }
    }
    if {[llength $bad] > 0} {
        error "PNR_IMPORT_NON_PROPRE: report=$path evidence=$bad"
    }
}

proc ::digi_pnr::require_clean_timing_intent {path} {
    set text [read_text $path]
    set bad [list]
    foreach line [split $text "\n"] {
        set trimmed [string trim $line]
        if {[regexp -nocase {(^|[[:space:]*])(ERROR|FATAL|VIOLATED)([[:space:]:]|$)} $trimmed]} {
            lappend bad $trimmed
        }
        if {[regexp -nocase \
                {(unconstrained|not[[:space:]]+constrained|missing[[:space:]]+clock)[^0-9]*([0-9]+)} \
                $trimmed -> category count] && $count > 0} {
            lappend bad $trimmed
        }
        if {[regexp -nocase \
                {([0-9]+)[^[:alnum:]]+(unconstrained|not[[:space:]]+constrained|missing[[:space:]]+clock)} \
                $trimmed -> count category] && $count > 0} {
            lappend bad $trimmed
        }
        if {[llength $bad] == 5} { break }
    }
    if {[llength $bad] > 0} {
        set_status SDC_COVERAGE_STATUS FAIL $path
        error "PNR_SDC_NON_COUVERT: report=$path evidence=$bad"
    }
    set_status SDC_COVERAGE_STATUS PASS $path
}

proc ::digi_pnr::import_design {} {
    global init_top_cell init_verilog init_lef_file init_mmmc_file
    global init_pwr_net init_gnd_net init_design_uniquify DESIGN_CFG

    set netlist [require_file netlist [require_env PNR_NETLIST]]
    set init_top_cell $DESIGN_CFG(top)
    set init_verilog $netlist
    set init_lef_file [env_list ALL_LEFS]
    set init_mmmc_file [write_mmmc]
    set init_pwr_net [env_or POWER_NET VDD]
    set init_gnd_net [env_or GROUND_NET VSS]
    set init_design_uniquify 1

    init_design

    set power_pin [env_or STDCELL_POWER_PIN vddi]
    set ground_pin [env_or STDCELL_GROUND_PIN gndi]
    globalNetConnect $init_pwr_net -type pgpin -pin $power_pin -inst * -verbose
    globalNetConnect $init_gnd_net -type pgpin -pin $ground_pin -inst * -verbose
    globalNetConnect $init_pwr_net -type tiehi -inst * -verbose
    globalNetConnect $init_gnd_net -type tielo -inst * -verbose
    applyGlobalNets

    set check_design [report_path check_design_import.rpt]
    capture $check_design {checkDesign -all}
    require_clean_import_report $check_design
    set timing_intent [report_path check_timing_import.rpt]
    capture $timing_intent {check_timing -verbose}
    require_clean_timing_intent $timing_intent
    capture [report_path clocks_import.rpt] {report_clocks}
    save_checkpoint 00_import

    set tool_version INCONNUE
    if {[llength [info commands getVersion]] > 0} {
        catch {set tool_version [getVersion]}
    }
    append_manifest INNOVUS_VERSION $tool_version
    append_manifest MMMC_FILE $init_mmmc_file
    append_manifest NETLIST $netlist
    append_manifest SDC [require_env PNR_SDC]
    set_status IMPORT_STATUS PASS $check_design
}
